# Project Brief: Complaint Intelligence

*AI-Ready Analytics for Financial Services*

**Status:** Complete (Nov 8 – Nov 16, 2026)  
**Owner:** Sandhiya Jaikumar, Data Analyst  
**Dashboard:** https://public.tableau.com/app/profile/sandhiya3216/viz/ComplaintIntelligence-CFPBComplaints2024-2026/Dashboard1

## 1. Background

The stakeholder is the **Head of Customer Experience (CX) at a large US bank**. They want an outside-in view of what bank and payments customers complain about across the market, how well companies respond, and whether an AI assistant can be trusted to answer these questions for the team. The data source is the public **CFPB Consumer Complaint Database**.

## 2. Business questions

| # | Question | Answered with |
|---|---|---|
| Q1 | Are bank and payments complaints growing, and where? | dbt marts + SQL (sql/04) |
| Q2 | Are companies responding well, and is it getting better or worse? | dbt marts + SQL (sql/05) |
| Q3 | What are customers *actually* complaining about, beyond CFPB categories? | AI themes on a weighted sample (sql/07) |
| Q4 | Can an AI assistant answer these questions reliably? What makes it reliable? | MCP server + 20-question test |

## 3. Scope

| Item | Decision |
|---|---|
| Source | CFPB complaint archive: 17 files, 13,495,502 rows |
| Loaded to BigQuery | 1,532,691 complaints, all products except credit reporting, Sep 2023 – Aug 2026 |
| Credit reporting | 11,962,811 rows (88.6%), **not loaded**, to stay within free storage; kept as a monthly summary only |
| Analysis period | **Jan 1, 2024 – Jun 30, 2026** (30 months); analysis date Jun 30, 2026 |
| Products in scope | Credit card · Checking or savings account · Money transfer, virtual currency, or money service · Mortgage · Vehicle loan or lease · Prepaid card |
| Analysis rows | **643,704 complaints**; 346,734 with a written story; 308,826 individual (non-copied) stories |
| Out of scope (flagged, not deleted) | Debt collection, student loans, payday/title/personal loans, debt or credit management, and rows outside the period |

## 4. Deliverables

| Deliverable | Location |
|---|---|
| Data audit and loading notebooks | notebooks/01, 02 · sql/01 |
| dbt project: staging view, 5 mart tables, 25 data tests, lineage | dbt/ · images/dbt_lineage.png |
| Semantic layer: 24 governed metrics (MetricFlow) | dbt/models/semantic |
| Exec Q1–Q3 analysis SQL | sql/04, 05, 07 |
| AI theme classification + evaluation | notebooks/03 · docs/theme_definitions.md · docs/ai_evaluation_report.md |
| MCP server + 20-question test | mcp_server/ · docs/mcp_test_questions.csv, mcp_test_results.csv |
| Tableau Public dashboard | link above · images/tableau_dashboard.png |
| Executive memo | docs/executive_memo.md / .pdf |
| README | repo front page |

## 5. Metric definitions (governed in the semantic layer)

| Metric | Definition |
|---|---|
| complaints | Number of complaints |
| complaints_excl_copies | Complaints, leaving out copy-paste template stories |
| closed_complaints | Company response starts with "Closed" |
| timely_response_rate | Complaints answered within the CFPB time limit ÷ all complaints |
| never_answered_complaints / _rate | Response = "Untimely response" (company never answered); ÷ all complaints |
| monetary_relief_rate | Closed with monetary relief ÷ **closed** complaints |
| any_relief_rate | Closed with monetary or non-monetary relief ÷ **closed** complaints |
| narrative_share | Complaints with a written story ÷ all complaints |
| copied_story_share | Complaints whose story is an exact copy of another ÷ all complaints |
| avg_days_to_company | Average days from CFPB receipt to the company |
| complaints_yoy_growth | Complaints vs the same period one year earlier (derived, 1-year offset) |
| complaints_per_100k_residents | Complaints ÷ 2021 state population × 100,000, **by state only** |
| population | 2021 population (US Census ACS 1-year) |
| sampled_stories | Stories labeled by the AI (sample size) |
| estimated_stories | Sample weighted up to all individual stories |
| theme_monetary_relief_rate | Weighted money back ÷ weighted closed, from the AI theme sample |

The semantic layer also holds the supporting counts behind these rates (timely, closed, monetary relief, any relief, with story, copied story, estimated closed, estimated money back), for **24 metrics** in total.

## 6. Rules and assumptions

1. **Flag, don't delete.** Period, product scope, copies, credit bureaus and non-state rows are flags in staging.
2. **"Untimely response" = never answered = not closed.** Relief rates use closed complaints as the denominator.
3. **Copy-paste templates** (exact repeated story text) are counted in volume, shown with and without in trends, and excluded from AI sampling.
4. **Credit bureaus** (Equifax, TransUnion, Experian) filed under bank products are flagged with `is_credit_bureau`.
5. **Company names:** company_key = UPPER(TRIM(company)); the display name is the most common spelling.
6. **Per-100k** is valid by state only (50 states + DC); territories, military addresses and blanks are excluded from it but kept elsewhere.
7. **Population is 2021**, the newest ACS 1-year data in BigQuery public data, while complaints are 2024–2026.
8. **2026 is a half year:** never compare full-year 2026 with 2025; compare the same months.
9. **AI themes are estimates:** a 900-story stratified sample (150 per product), weighted by product; ~69% agreement with a blind-reviewed human answer key; customer service is under-counted.
10. **Correlation, not cause:** the timing of the Jan 2025 campaigns matches CFPB enforcement news, but cause is not proven.
11. **Complaint volume is not wrongdoing.** It reflects customer base size, product mix and campaigns.

## 7. Method

1. **Download and inspect** the CFPB archive files (Colab, pandas) and **load** the in-scope products to BigQuery: all columns as text, plus the source file name.
2. **Audit** the data: dates, missing values, response categories, the Jan 2025 spike, copy-paste stories, company spellings, states.
3. **dbt:** a staging view (typed fields + flags) → marts (fct_complaints, dim_company, dim_date, dim_state with Census population) → 25 data tests, including row-count reconciliation and 51-state completeness.
4. **Exec Q1/Q2 analysis** in BigQuery SQL.
5. **Semantic layer** (MetricFlow): semantic models, 24 metrics, results validated against SQL.
6. **AI themes:**
   - A 102-story human answer key, labeled blind.
   - Gemini run 1, then a blind review of the disagreements.
   - A dev/test split, then prompt v2, then a single held-out test.
   - A 900-story production run, loaded to BigQuery and modeled in dbt with sample weights.
7. **MCP server:** 5 tools (metrics + read-only SQL) and 7 rules for the assistant, plus a 20-question test (governed metrics vs AI-written SQL).
8. **Tableau Public dashboard:** calculated fields mirror the dbt metric definitions, and the numbers were reconciled.

## 8. Findings

**Q1: Growing, steadily.**
- The run rate went from ~15,600/month (2024) to ~20,800 (2025, excluding January) to ~24,400 (H1 2026).
- H1 2026 looks −18% vs H1 2025 only because January 2025 (82,063 complaints, including 26,779 template copies) was inflated by campaigns. Excluding January, the run rate is +26% (Q2 2026 YoY: +25.6%).
- Fastest growth (H1 2026 vs H1 2025): mortgage +50%, vehicle loans +37%, credit card purchase disputes +90%.
- The top 15 companies have 62% of complaints. Per 100k residents (2025, excluding copies): DC 176 vs South Dakota 28, about 6x.

**Q2: Fast, but outcomes slipping.**
- 98.9% answered on time. Never answered: 1,421 in total, rising from 92 (Q2 2025) to 478 (Q2 2026).
- Money back 9.7%, any relief 19.4%. Any relief fell from ~26% (2024) to ~18% (2026).
- Within credit cards, money back differs about 3x between large issuers with a similar complaint mix (36% vs 11%).
- Templates get 0.1% money back, vs 11.0% for individual stories.
- 48,472 complaints (7.5%) are about credit bureaus filed under bank products (21.5% of credit card complaints).

**Q3: Fraud is #1, and hidden.**
- Fraud is ~26% of individual stories and the #1 theme in checking, credit cards, prepaid and money transfer (50% of money-transfer stories).
- Only ~1 in 5 fraud stories is filed under a CFPB category that says fraud or unauthorized.
- Money back by theme: fees 41%, misleading terms 28%, payment problems 19%, fraud 15%, loan servicing 3%, credit report disputes 1%.
- Disputed purchases are rising: 6% → 9% → 16% (2024 → H1 2026), consistent with Q1.

**Q4: Governance lives in the modeling.**
- Governed metrics answered 20/20 test questions; AI-written SQL on the dbt marts answered 19/20 (it missed the January 2025 caveat on the half-year comparison).
- Clean, tested marts with shared definitions made AI-written SQL accurate. The semantic layer added consistency and context.

## 9. Recommendations

1. Make fraud handling the #1 CX priority, tracked with a dedicated fraud theme rather than CFPB categories.
2. Investigate rising never-answered complaints and falling relief; target zero never-answered.
3. Benchmark purchase-dispute handling against the best-performing card issuers.
4. Remove campaign noise (templates, credit bureau disputes) before reporting trends.
5. Build AI assistants on governed metrics, and keep testing them with a fixed question set.

## 10. Limitations

- AI themes come from a sample (900 stories); small themes and per-year shares have wide margins.
- Customer service is under-counted by the AI (~2.5x).
- Written stories exist only with consumer consent (~54% of complaints).
- 2021 population; BigQuery sandbox tables expire after 60 days (all steps are reproducible from the notebooks and dbt).
- The 20-question test is small and was run on clean marts, not raw tables.

## 11. Next steps

- Repeat the MCP test against the raw source table.
- Replace the "customer service" theme with a separate yes/no service-failure flag.
- Grow the answer key to 300+ stories, and track themes quarterly.
- Rebuild the dashboard in Power BI / Microsoft Fabric using the same metric definitions.

## 12. Timeline

| Dates | Work |
|---|---|
| Nov 8 | Brief, data download and inspection, BigQuery load, data audit, scope decision |
| Nov 10 | GitHub setup, dbt staging and marts, Census join, tests, Exec Q1 and Q2 analysis, credit bureau flag, semantic layer |
| Nov 12 | Theme definitions, 102-story human answer key, AI run 1 |
| Nov 13 | Blind review, dev/test split, prompt v2, held-out test, big run day 1 |
| Nov 14 | Big run day 2, MCP server, Claude Desktop connection, 20-question test |
| Nov 15 | Big run complete, themes in dbt and the semantic layer, Exec Q3, Tableau dashboard |
| Nov 16 | README, AI evaluation report, executive memo, final brief and data quality log |
