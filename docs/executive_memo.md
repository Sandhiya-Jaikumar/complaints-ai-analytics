# Memo: What US bank & payments customers complain about

**To:** Head of Customer Experience  
**From:** Sandhiya Jaikumar, Data Analyst  
**Data:** CFPB Consumer Complaint Database, Jan 2024 – Jun 2026; 643,704 complaints across 6 bank and payments products (credit reporting excluded)  
**Dashboard:** [Complaint Intelligence on Tableau Public](https://public.tableau.com/app/profile/sandhiya3216/viz/ComplaintIntelligence-CFPBComplaints2024-2026/Dashboard1)

---

## Bottom line
Complaints are **rising about 26% a year** once a one-off campaign spike is removed. Companies answer quickly, but **fewer complaints end with relief**, and **unanswered complaints are climbing**. **Fraud is the single biggest problem** (about 1 in 4 stories), yet it is mostly hidden inside generic CFPB categories, and only about 1 in 7 fraud complaints ends with money back.

## 1. Are complaints growing? Yes, steadily.
- The monthly run rate went from **~15,600 (2024)** to **~20,800 (2025, excluding January)** to **~24,400 (H1 2026)**.
- **Watch out for the headline:** H1 2026 looks **18% lower** than H1 2025. That's only because **January 2025 (82,063 complaints)** was inflated by copy-paste campaigns that followed CFPB enforcement actions. Excluding January, the run rate is **+26%**.
- **Fastest growth:** mortgage **+50%**, vehicle loans **+37%**, credit card purchase disputes **+90%**.

## 2. Are companies responding well? Fast, but outcomes are slipping.
- **98.9%** answered on time. However, **never-answered complaints rose about 5x** (92 in Q2 2025 → 478 in Q2 2026).
- **Any relief fell from ~26% to ~18%** of closed complaints (2024 → 2026). Money back is **9.7%**.
- Within credit cards, money-back rates differ **about 3x** between large issuers with a similar complaint mix (36% vs 11%). This is a handling choice, not a product-mix effect.

## 3. What are customers actually complaining about? (AI themes, 900-story weighted sample)
| Theme | Share of stories | Money back |
|---|---|---|
| **Fraud or unauthorized transaction** | **26%** | 15% |
| Loan servicing, collections, repossession | 13% | 3% |
| Frozen, closed or held account / funds | 13% | 14% |
| Disputed purchase | 9% (and **rising**: 6% → 16%) | 11% |
| Fees, interest or overdraft | 9% | **41%** |

- **Only about 1 in 5 fraud stories** is filed under a CFPB category that says fraud. Reading the stories reveals what the official labels miss.
- **Caveat:** the AI agrees with a blind-reviewed human answer key about 69% of the time, and it under-counts "customer service" complaints.

## 4. Can an AI assistant answer these questions reliably? Yes, if the metrics are governed.
- An AI assistant connected to our **governed metric definitions** answered **20 of 20** test questions correctly. Writing its own SQL, it got **19 of 20**.
- Its accuracy came from **clean, tested data models** with shared definitions (for example, "money back ÷ *closed* complaints"). Governance has to be built **before** the AI is added.

## Recommendations
1. **Make fraud handling the #1 CX priority.** It's the largest problem with low recovery. Track it with a dedicated fraud theme rather than relying on CFPB categories.
2. **Investigate rising unanswered complaints and falling relief.** Set an internal target: zero never-answered complaints.
3. **Benchmark dispute handling against the best-performing card issuers.** Purchase disputes are the fastest-growing problem.
4. **Filter out campaign noise** (template complaints, credit bureau disputes filed under bank products) before reporting trends to leadership.
5. **Put an AI assistant on top of governed metrics, not raw tables**, and keep testing it with a fixed question set.
