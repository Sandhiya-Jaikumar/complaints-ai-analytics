"""MCP server for the Complaint Intelligence project.

Gives an AI assistant two ways to answer questions about CFPB complaints:
1. Governed metrics from the dbt semantic layer (MetricFlow) - preferred.
2. Read-only SQL on the BigQuery analytics tables - fallback.
"""
import csv
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from mcp.server.fastmcp import FastMCP
except ImportError:  # newer MCP SDK versions renamed FastMCP
    from mcp.server.mcpserver import MCPServer as FastMCP

REPO = Path(__file__).resolve().parent.parent
DBT_DIR = REPO / "dbt"
MANIFEST = DBT_DIR / "target" / "semantic_manifest.json"
MF = str(Path(sys.executable).parent / "mf")
os.environ.setdefault("DBT_PROFILES_DIR", str(Path.home() / ".dbt"))
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", "complaints-ai-analytics")
PROJECT = os.environ["GOOGLE_CLOUD_PROJECT"]
DATASET = "dbt_sandhiya"
MAX_ROWS = 200
MAX_BYTES = 2 * 10**9  # stop any single SQL query that would scan more than 2 GB

INSTRUCTIONS = """You are an analyst assistant for the Complaint Intelligence project:
CFPB consumer complaints, Jan 2024 to Jun 2026, six products (Credit card, Checking or savings
account, Money transfer/virtual currency/money service, Mortgage, Vehicle loan or lease,
Prepaid card). Credit reporting complaints are out of scope.

Rules:
1. For any number, prefer the governed metrics: call list_metrics and list_dimensions, then
   query_metrics. Use describe_tables and run_sql only when no metric can answer, and say so.
2. In every answer, name the metric(s), filters and time period you used.
3. complaints_per_100k_residents only makes sense grouped by state. Never report it overall,
   by product or by company.
4. 2026 has only six months of data (Jan-Jun). Never compare full-year 2026 with full-year 2025;
   compare the same months instead.
5. January 2025 contains large copy-paste template campaigns. For trends, also check
   complaints_excl_copies.
6. Credit bureaus (Equifax, TransUnion, Experian) still appear under these six products; they are
   flagged by is_credit_bureau. Mention this when ranking companies.
7. If the data cannot answer a question, say so instead of guessing."""

mcp = FastMCP("complaints-analytics", instructions=INSTRUCTIONS)


def _manifest():
    if not MANIFEST.exists():
        raise FileNotFoundError("semantic_manifest.json not found. Run `dbt parse` in the dbt folder.")
    with open(MANIFEST) as f:
        return json.load(f)


def _table(header, rows):
    lines = [" | ".join(str(h) for h in header)]
    lines += [" | ".join("" if v is None else str(v) for v in r) for r in rows]
    return "\n".join(lines)


def list_metrics() -> str:
    """List every governed metric in the semantic layer, with its type and description."""
    m = _manifest()
    lines = []
    for x in sorted(m["metrics"], key=lambda x: x["name"]):
        desc = (x.get("description") or "").strip().replace("\n", " ")
        lines.append(f"- {x['name']} ({x.get('type', '')}): {desc}")
    return "\n".join(lines)


def list_dimensions() -> str:
    """List the dimensions you can group or filter metrics by, with the prefix to use."""
    m = _manifest()
    out = []
    for sm in m["semantic_models"]:
        entity = next((e["name"] for e in sm.get("entities", []) if e.get("type") == "primary"), sm["name"])
        dims = [d["name"] for d in sm.get("dimensions", [])]
        if dims:
            out.append(f"{sm['name']}: use '{entity}__<name>' -> " + ", ".join(dims))
    out.append("Time: metric_time__day, metric_time__month, metric_time__quarter, metric_time__year.")
    out.append("Filter example: {{ Dimension('complaint__product') }} = 'Mortgage'")
    return "\n".join(out)


def query_metrics(
    metrics: list[str],
    group_by: list[str] | None = None,
    where: str | None = None,
    order_by: list[str] | None = None,
    start_time: str | None = None,
    end_time: str | None = None,
    limit: int = 50,
    show_sql: bool = False,
) -> str:
    """Query governed metrics through the dbt semantic layer (MetricFlow).

    metrics: metric names from list_metrics, e.g. ["complaints", "timely_response_rate"].
    group_by: e.g. ["metric_time__year", "complaint__product"].
    where: MetricFlow filter, e.g. "{{ Dimension('complaint__product') }} = 'Mortgage'".
    order_by: e.g. ["-complaints"] (minus sign = descending).
    start_time / end_time: e.g. "2025-01-01" and "2025-12-31".
    show_sql: also return the SQL that MetricFlow generated.
    """
    cmd = [MF, "query", "--metrics", ",".join(metrics)]
    if group_by:
        cmd += ["--group-by", ",".join(group_by)]
    if where:
        cmd += ["--where", where]
    if order_by:
        cmd += ["--order", ",".join(order_by)]
    if start_time:
        cmd += ["--start-time", start_time]
    if end_time:
        cmd += ["--end-time", end_time]
    cmd += ["--limit", str(max(1, min(int(limit), MAX_ROWS)))]

    with tempfile.TemporaryDirectory() as tmp:
        out_csv = os.path.join(tmp, "result.csv")
        p = subprocess.run(cmd + ["--csv", out_csv], cwd=DBT_DIR, capture_output=True, text=True, timeout=300)
        if p.returncode != 0 or not os.path.exists(out_csv):
            return "MetricFlow error:\n" + (p.stderr or p.stdout)[-3000:]
        with open(out_csv, newline="") as f:
            rows = list(csv.reader(f))
    result = _table(rows[0], rows[1:]) if rows else "No rows."

    if show_sql:
        e = subprocess.run(cmd + ["--explain"], cwd=DBT_DIR, capture_output=True, text=True, timeout=300)
        result += "\n\nSQL generated by MetricFlow:\n" + (e.stdout or e.stderr)[-4000:]
    return result


def describe_tables() -> str:
    """List the BigQuery analytics tables (dataset dbt_sandhiya) and their columns, for run_sql."""
    from google.cloud import bigquery

    client = bigquery.Client(project=PROJECT)
    sql = (
        f"SELECT table_name, column_name, data_type "
        f"FROM `{PROJECT}.{DATASET}.INFORMATION_SCHEMA.COLUMNS` "
        f"ORDER BY table_name, ordinal_position"
    )
    tables = {}
    for r in client.query(sql).result():
        tables.setdefault(r["table_name"], []).append(f"{r['column_name']} {r['data_type']}")
    return "\n".join(f"{t}: " + ", ".join(cols) for t, cols in tables.items())


def run_sql(sql: str) -> str:
    """Run ONE read-only BigQuery SELECT on the dbt_sandhiya tables (max 200 rows returned).

    Use only when the governed metrics cannot answer the question. Table names can be written
    without the project and dataset, e.g. SELECT COUNT(*) FROM fct_complaints.
    """
    s = sql.strip().rstrip(";").strip()
    first = s.split(None, 1)[0].upper() if s else ""
    if first not in ("SELECT", "WITH") or ";" in s:
        return "Refused: only a single SELECT (or WITH ... SELECT) statement is allowed."
    from google.cloud import bigquery

    client = bigquery.Client(project=PROJECT)
    cfg = bigquery.QueryJobConfig(
        maximum_bytes_billed=MAX_BYTES,
        default_dataset=f"{PROJECT}.{DATASET}",
    )
    try:
        rows = list(client.query(s, job_config=cfg).result(max_results=MAX_ROWS))
    except Exception as e:
        return f"BigQuery error: {str(e)[:2000]}"
    if not rows:
        return "No rows."
    header = list(rows[0].keys())
    return _table(header, [list(r.values()) for r in rows])


for _fn in (list_metrics, list_dimensions, query_metrics, describe_tables, run_sql):
    mcp.tool()(_fn)

if __name__ == "__main__":
    mcp.run()