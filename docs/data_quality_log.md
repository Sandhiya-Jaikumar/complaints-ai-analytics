# Data Quality Log: Complaint Intelligence

*CFPB Consumer Complaint Database, Jan 2024 – Jun 2026*

**Status:** Final (Nov 16, 2026)  
**Principle:** flag, don't delete. Every exclusion is a visible, reversible flag in dbt staging.  

## Summary

| Check | Result |
|---|---|
| Rows in source files | 13,495,502 (17 files) |
| Rows loaded (non-credit-reporting) | 1,532,691, with 0 duplicate complaint IDs |
| Analysis rows (6 products, Jan 2024 – Jun 2026) | 643,704 |
| With written story / individual stories | 346,734 / 308,826 |
| Copy-paste template stories | 37,908 (10.9% of in-scope stories) |
| Date errors | 0 |
| States matched to population | 51 of 51 (50 states + DC), 331,893,745 people |
| dbt data tests | All passing (25 data tests; 5 more on the AI themes model) |
| Metric validation | MetricFlow results = hand-written SQL (exact match) |

## A. Data issues

| # | Date | Issue found | Evidence | Impact | Decision / fix | Status |
|---|---|---|---|---|---|---|
| 1 | Nov 8 | Written stories disappear in recent months | Bank stories ~11.6k–24.5k/month through Jun 2026, 9,539 in Jul 2026, 0 in Aug 2026; credit reporting stories collapse after Jan 2026 | Recent months can't be analyzed for themes | Analysis period ends **Jun 30, 2026**; Jul–Aug 2026 kept in raw but flagged out | Resolved |
| 2 | Nov 8 | Archive page says data runs "through Aug 14, 2026", but the Aug file covers Aug 1–31 | File dates inspected | Possible confusion about coverage | Trust the file contents; document the difference | Documented |
| 3 | Nov 8 | Credit reporting dominates the data | 11,962,811 of 13,495,502 rows (88.6%); 86.5% → 90.2% of all complaints (2024 → 2026) | Would exceed free 10 GB storage and drown out bank products | Not loaded; kept as a monthly summary table only | Resolved |
| 4 | Nov 8 | Possible duplicate complaints across files | 0 repeated IDs in 12.5M rows; 0 in BigQuery (1,532,691 unique) | None | No action | Closed |
| 5 | Nov 8 | First archive file starts Apr 2024 | File inventory | Jan–Mar 2024 missing | Added the Sep 2023 – Mar 2024 file | Resolved |
| 6 | Nov 8 | **January 2025 spike** | 82,063 in-scope complaints vs ~17–21k in the months around it; Block, Zelle's operator, Navy Federal and Capital One all jump Jan 14–21, 2025, right after CFPB enforcement news | Distorts year-over-year growth (H1 2026 looks −18%) | Traced to copy-paste template campaigns; `is_copied_story` flag; trends shown with and without copies; Q1 uses run rates excluding January | Resolved |
| 7 | Nov 8 | **Copy-paste template stories** | Top templates: Cash App ~10,235 copies, Zelle 3,751, Navy Federal 2,419, a credit card "FCRA 605B" template 2,255; 37,908 in scope | Inflate volume; 0.1% money back; would bias AI sampling | Counted in volume, flagged, and excluded from AI samples | Resolved |
| 8 | Nov 8 | Response categories need a definition of "closed" | "Untimely response" 17,124 (company never answered); 686 in progress; 3 blank | Wrong relief-rate denominators | Closed = response starts with "Closed"; "Untimely response" = never answered = not closed; relief rates divide by closed | Resolved |
| 9 | Nov 8 | Optional fields mostly empty | tags 89% empty, public response 65%, sub_issue 11.9% | Can't rely on them for core metrics | Tags turned into `is_older_american` / `is_servicemember` flags; other fields not used in core metrics | Documented |
| 10 | Nov 8 | Story text redactions | "XX" redactions in 70.8% of stories | Noise for AI | The AI prompt says "XXXX = removed private details; ignore" | Resolved |
| 11 | Nov 8 | Company name spelling variants | 1 in-period case (First Technology Federal Credit Union, 760 complaints) | Split company counts | company_key = UPPER(TRIM(company)); display name = most common spelling | Resolved |
| 12 | Nov 8 | Product scope | 10 non-credit-reporting products; 4 are not bank products (debt collection, student loans, payday/title/personal, debt management) | Mixing third-party collectors with banks | Scope = 6 bank & payments products (643,704 complaints); the other 4 flagged | Resolved |
| 13 | Nov 10 | Non-state locations | 7,603 complaints outside the 50 states + DC (territories, military, blank); 121 odd state values | Breaks per-resident rates | `is_state_or_dc` flag; excluded from per-100k only | Resolved |
| 14 | Nov 10 | **State FIPS codes with leading zeros** ("06" vs "6") | First join matched only 44 states / 267M people | 7 states (~65M people) missing population | Compared as integers (SAFE_CAST to INT64): 51 states, 331.9M people; dbt test `assert_dim_state_complete` | Resolved |
| 15 | Nov 10 | Population is 2021 | Newest ACS 1-year data in BigQuery public data | Per-100k is slightly off for fast-growing states | Documented as a caveat | Documented |
| 16 | Nov 10 | **Credit bureaus filed under bank products** | 48,472 complaints (7.5%); 46,228 under credit card (21.5% of card complaints), ~0% purchase disputes | Distort bank rankings and relief rates | `is_credit_bureau` flag; dashboard "Company Type" filter | Resolved |
| 17 | Nov 8 | Date quality | 0 failed dates; 0 "sent before received"; days to company median 0, p95 6, max 446 | None | No action | Closed |
| 18 | Nov 15 | Story sample is equal per product, but products differ in size | 150 stories per product vs ~8,800–96,000 individual stories per product | Unweighted totals over-represent small products | `sample_weight` = product's individual stories ÷ sampled; weights sum to 308,826 (reconciles) | Resolved |

## B. AI labeling issues

| # | Date | Issue | Evidence | Decision / fix | Status |
|---|---|---|---|---|---|
| 19 | Nov 12 | Low first agreement | AI run 1: 47/102 = 46.1% | Confusion matrix → 3 causes (definitions, technical, gray areas) | Investigated |
| 20 | Nov 13 | Human answer key inconsistency | Blind review: the AI was right in 23 of 45 disagreements; "Customer service failure" was over-used | Reviewed key saved separately (original kept); agreement 68.6%; both numbers reported | Resolved |
| 21 | Nov 13 | AI skipped stories in batches | 10 of 102 had no answer | Code checks every returned ID and re-asks missing ones; prompt states the count → 0 missing | Resolved |
| 22 | Nov 13 | Risk of overfitting the prompt | Dev +6 points, test −2 points | Dev/test split before tuning; test half run once; prompt v2 frozen | Resolved |
| 23 | Nov 13 | Customer service under-counted by the AI | AI chose it 5 times vs 13 in the reviewed key | Stated as a caveat in the dashboard, memo and README; future fix = separate yes/no flag | Documented |
| 24 | Nov 12–15 | Free-tier rate limits (20 requests/day) | 429 errors on day 1 | Batches of 30, request counter (stop at 18), stop on 429, checkpoint after every batch; 900 stories in 30 requests over 3 days at $0 | Resolved |

## C. Processing and tooling issues

| # | Issue | Fix |
|---|---|---|
| 25 | pip couldn't build `cryptography` on an Intel Mac | `pip install --prefer-binary` |
| 26 | Indented YAML pasted from chat broke dbt config files | Always paste YAML with no leading spaces |
| 27 | BigQuery ROLLUP total row label showed null / alias error | Use a new alias (`product_group`) with `IF(GROUPING(product)=1, …)` |
| 28 | MetricFlow: population measure had no time dimension | Added `population_date` (2021-07-01) to dim_state |
| 29 | MetricFlow CLI couldn't find the dbt profile | `DBT_PROFILES_DIR` and `GOOGLE_CLOUD_PROJECT` set in the conda environment |
| 30 | dbt ratio metric referenced measures instead of metrics | `create_metric: true` on the numerator and denominator measures |
| 31 | Tableau read Population as text | `FLOAT([Population])` in the per-100k calculation |
| 32 | Tableau single-value filters silently picked one value | "Show All value" + default (All); KPIs re-checked against dbt |
| 33 | BigQuery sandbox tables expire after 60 days (raw ~Jan 7, 2027) | Fully reproducible from the notebooks + `dbt build` |
