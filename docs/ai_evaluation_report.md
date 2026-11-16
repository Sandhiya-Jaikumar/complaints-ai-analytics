# AI Theme Classification: Evaluation Report

**Goal:** classify consumer complaint stories into 11 business themes, so the Head of CX can see what customers *actually* complain about (Exec Q3), and measure honestly how far the AI labels can be trusted.

## Setup

| Item | Choice |
|---|---|
| Model | Gemini 3.6 Flash (Google AI Studio, **free tier**), pinned for the whole project |
| Settings | temperature 0, structured JSON output with a fixed enum of 11 themes, stories truncated to 4,000 characters |
| Themes | 11 themes with written definitions and tie-break rules ([theme_definitions.md](theme_definitions.md)) |
| Prompt versions | v1 (original rules) and v2 (sharper rules + ID check), saved in [data/theme_prompt_v2.txt](../data/theme_prompt_v2.txt) |
| Budget | 20 requests per day on the free tier; a request counter in code stops at 18, and the run stops immediately on a 429 error |

## 1. Human answer key (ground truth)

- **102 stories:** 17 per product, drawn with a reproducible hash-based random sample. Copy-paste template stories were excluded.
- Labeled by hand, **blind**: the CFPB issue category and company name were hidden, to avoid anchoring on the existing labels.

## 2. Run 1: 46.1% agreement

The AI agreed with the human label on **47 of 102** stories. The confusion matrix showed **three different causes** for the 55 disagreements:

| Cause | Stories | Type |
|---|---|---|
| Human chose "Customer service failure"; the AI never chose it | 24 | Definition problem |
| AI returned no answer (batching / ID mismatch) | 10 | Technical problem |
| Overlapping themes (e.g. disputed purchase vs fraud, fees vs loan servicing) | 21 | Genuine gray areas |

## 3. Blind review of the disagreements

For each of the 45 disagreements where the AI answered, the reviewer saw the story with the two candidate themes as **"Option A / Option B" in random order**, without knowing which was the AI's, and picked the better fit. The results were scored afterwards.

| Outcome | Count |
|---|---|
| Sided with the AI's label | 23 |
| Sided with the original human label | 21 |
| Left unresolved (original label kept, the conservative choice) | 1 |

**Reviewed agreement: 70 of 102 = 68.6%.** About half of the "AI errors" were actually inconsistencies in the human labels, mostly over-use of "Customer service failure". **Both numbers are reported.**

## 4. Prompt improvement with a dev/test split

The reviewed answer key was split **before** any tuning, stratified by product:
- **Dev:** 48 stories. Mistakes were studied here and the rules sharpened.
- **Test:** 54 stories. These were **never looked at**, and the final prompt was run on them **once**.

| | Run 1 (prompt v1) | Prompt v2 |
|---|---|---|
| Dev half | 66.7% | **72.9%** |
| **Test half (held out)** | 70.4% | **68.5%** |
| All 102 | 68.6% | 70.6% |
| Missing answers | 10 | **0** |

**Conclusion:**
- The sharper rules **did not improve judgment on unseen stories**. The difference is 1 story, well within noise: the 95% margin on 54 stories is about ±12 points.
- The +6 points on the dev half was overfitting, which is **exactly why the test half was held out**.
- v2's real gain is **reliability**: every story now gets an answer. The code checks the returned IDs and re-asks any missing ones.

## 5. Accuracy by theme (prompt v2, all 102 stories)

| Reliable (74–100%) | Medium (57–76%) | Weak |
|---|---|---|
| Frozen/closed account 12/12 · Credit report 5/5 · Payment/transfer 5/5 · Loan servicing 17/23 | Fraud 16/21 · Disputed purchase 8/12 · Fees 4/7 | **Customer service failure 4/13** |

**Known bias:** the AI chose "Customer service failure" 5 times, vs 13 times in the reviewed key. **Customer service is under-counted about 2.5x**, so dashboards and the memo state it as a caveat.

## 6. Production run

- **900 stories** (150 per product, no templates, the 102 answer-key stories excluded), in batches of 30.
- **30 requests over 3 days**, all within the free tier. Progress was saved after every batch, so a stop never lost work.
- Results are stored in BigQuery with **model, prompt version and date** on every row (`raw.ai_complaint_themes`), then modeled in dbt as `fct_complaint_themes`.
- **Weighting:** each product's 150 stories are weighted up to that product's real number of individual stories. The weights sum to **308,826**, which matches the population exactly.

## 7. How to read the results

- Treat theme shares as **estimates**: big themes (fraud ~26%, loan servicing ~13%) are solid, while themes with fewer than ~60 sampled stories have wide margins (about ±10 points on rates).
- Per-year theme shares are **direction only**, because of small yearly samples.

## Lessons

1. **Measure the human labels too.** A blind review turned a "46% accurate AI" into a clearer picture: ~69% agreement, one vague category, and one technical bug.
2. **Hold out a test set before tuning prompts.** Without it, a +6-point improvement that didn't exist would have been reported.
3. **Design categories for the model.** "Customer service" overlaps with almost every other theme. A better design is a separate yes/no "service failure" flag next to the main theme.
4. **Free-tier engineering matters:** batch sizing, request counting, stop-on-429 and checkpointing made a 900-story run possible at $0.
