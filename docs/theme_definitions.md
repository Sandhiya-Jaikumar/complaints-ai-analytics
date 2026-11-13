# Complaint themes

Each written complaint gets ONE theme: the main problem the consumer wants fixed.
These definitions are used by both the human labeler (answer key) and the AI model, so results can be compared fairly.

| # | Theme | Use when the consumer's main problem is… | Examples |
|---|---|---|---|
| 1 | Fraud or unauthorized transaction | Money taken without permission, a scam, account takeover, identity theft | "Someone used my card", "I was scammed on Zelle", "a charge I never made" |
| 2 | Disputed purchase or merchant problem | A purchase they made went wrong and the company won't fix it | Item never arrived, refund not credited, chargeback denied |
| 3 | Fees, interest or overdraft | Charges they think are unfair or wrong | Overdraft fees, late fees, interest charges, annual fee |
| 4 | Frozen, closed or held account / funds | They can't access their money or account | Account frozen or closed without warning, funds on hold |
| 5 | Payment or transfer problem | A payment or transfer didn't go through or wasn't applied correctly | Payment not credited, transfer delayed or failed, autopay error |
| 6 | Loan servicing, collections or repossession | Problems managing a loan, mortgage or car loan | Escrow, loan modification, repossession, payment plans, collection calls |
| 7 | Credit report or credit-repair dispute | Wrong information on a credit report, or a credit-repair style dispute letter | "Remove this account from my report", FCRA 605B, hard inquiry |
| 8 | Account opening, verification or access | Trouble opening an account, proving identity, or logging in | Application denied, ID verification loops, locked out of the app |
| 9 | Misleading terms, rewards or marketing | They were misled about terms, rewards, promotions or disclosures | Promised bonus not paid, rewards points lost, terms changed |
| 10 | Customer service failure | The main complaint is how they were treated: no answer, runaround, rude staff | "No one returns my calls", "transferred 10 times" |
| 11 | Other | None of the above fits | — |

## Labeling rules
1. Pick the ONE theme that matches what the consumer most wants fixed.
2. Bad customer service is often mentioned. Choose "Customer service failure" only when it is the MAIN complaint, not a side comment.
3. Fraud beats Disputed purchase: if the consumer says they did not make the purchase, it is Fraud.
4. Use "Other" only when nothing fits.