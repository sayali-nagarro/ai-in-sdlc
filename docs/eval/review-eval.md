# Review evaluation: three runs per condition

Raw rows: [ops/evals/results.csv](../../ops/evals/results.csv) (72 rows: 12 cases x 3 runs x 2 prompts; the 12 rows for case-11 and case-12 are from the re-run after those cases were replaced).

## Setup

- The ten fixed cases in `ops/evals/cases` plus two supplied by the repository owner (`case-11`, `case-12`). Both were re-run after replacing earlier cases that I had written myself.
- Every case was reviewed in a fresh sub-agent session that was given only the diff and the prompt, with an instruction not to use tools.
- Same model for every call (the session default). The model was not varied.
- **v1** is the exact prompt from `ops/evals/README.md`.
- **v2** is v1 plus one sentence: "For each finding also give a concrete input or sequence of events that triggers the failure; if you cannot name one, do not report it."
- I wrote the v2 sentence and the hypothesis before running v2: false alarms should fall and the caught rate should not. I chose it because it does not name any defect class, so it cannot be tuned to these cases.

## Truth key (written before scoring, kept outside the workspace until the runs finished)

| Case | Truth | What the defect is |
| --- | --- | --- |
| 01 | Defect | `Ids` is declared nullable and dereferenced (500); a mid-batch failure leaves earlier invoices approved |
| 02 | Defect | String-built SQL (injection) |
| 03 | Defect | `ToZero` truncation of the discount and the total changes money by up to a cent |
| 04 | Clean | Complete rename |
| 05 | Defect | `Delete` has no `[RequireRole("Admin")]` |
| 06 | Clean | Added tests |
| 07 | Defect | Logs the whole invoice and session object |
| 08 | Defect | Non-thread-safe `Dictionary` in a shared repository; `Add` is check-then-act |
| 09 | Ambiguous | Code change is clean. The README line "sign out and sign in again resets the sample data" is wrong: `Logout` only removes the token (`AuthController.cs:39`) and the repository is a singleton |
| 10 | Defect | `catch (Exception)` returns 200 "completed" |
| 11 (owner) | Clean | Blank-reason validation in `Reject` with a `[Theory]` test for `""` and `"   "`. Correct and tested |
| 12 (owner) | Defect | `Approve` commits, then awaits `_payEx.SubmitAsync`: a payment failure or timeout leaves the invoice Approved but unpaid and a retry gets a conflict; the `Handle(...)` wrapper was also removed, so 404/409/400 mapping is lost |

Scoring rules, fixed before the runs:
- A defect case is **caught** only if the review names the actual defect. For case 12, naming either the approve-then-submit inconsistency or the dropped `Handle(...)` mapping counts (decided before the re-run).
- A clean case is a **false alarm** only if the review asserts a code defect at medium confidence or higher. Items it hedges as assumptions it cannot check do not count. I record them separately as "noise items".
- Case 09 is reported separately. It is not counted as caught or as a false alarm, because I am not certain the case author intended the README line to be a defect.

## Results

| | v1 (baseline) | v2 (trigger required) |
| --- | --- | --- |
| Defect cases caught (8 cases x 3 runs) | 24 / 24 | 24 / 24 |
| Missed | 0 | 0 |
| Clean cases, correctly clean (3 cases x 3 runs: 04, 06, 11) | 9 / 9 | 9 / 9 |
| False alarms | 0 / 9 | 0 / 9 |
| Case 09, README defect named | 3 / 3 | 2 / 3 |
| Noise items on cases 06 and 11 (my count, approximate) | about 21 over 6 reviews | 0 over 6 reviews |

95% Wilson intervals: caught 24/24 is 86% to 100% for both prompts. False alarms are 0/9 (0% to 30%) for both.

For transparency: before `case-11` and `case-12` were replaced, my own earlier `case-12` (a length limit) produced one borderline false alarm under v2 (a UTF-16 code-unit nit stated as a finding). That case is no longer in the data, so the table above does not include it. Replacing the cases changed that result from 1/9 to 0/9, which shows how much a single case can move these rates.

## Did the change help?

**Not demonstrably.** My confidence that v2 is better than v1 on the metrics that matter is low.

- Both prompts caught every defect and neither produced a false alarm, so on every rate the two are identical. The caught rate is at its ceiling and the false-alarm rate is at its floor, so this set cannot show an improvement or a regression.
- The three runs of one case are not independent: each run saw the same diff and mostly produced the same answer. The effective sample is closer to 12 cases than to 36 runs, so the real uncertainty is wider than the intervals above.
- What did change is secondary. v2 produced no hedged speculative items on the clean cases (about 21 down to 0). It also made every finding carry a concrete input, which is useful to whoever has to verify it.
- v2 has a cost. In run 1 of case 09 it considered the README defect and withheld it because it could not name a trigger. A true finding was suppressed by the rule.

Decision: keep v1 as the baseline for recall. v2 looks promising for reducing noise, and it did not lose recall on the defect cases, but the evidence is one suppressed true finding against about 21 fewer speculative items on a set this easy. Do not adopt it on this evidence alone.

## Limitations

1. **The set is too easy for this model.** 100% recall and zero false alarms mean this set cannot rank prompts or models. The next step is harder, subtler cases: a defect that needs knowledge of code outside the diff, an off-by-one, or a state-machine bug.
2. **Context leak.** The sub-agents have the workspace instructions (`AGENTS.md`) attached automatically, and several findings cite its conventions (for example, "destructive actions are Admin only" for case 05). So the context file was effectively on for both prompts. A true no-context run would need a clean workspace.
3. **Case 11 and 12 come from the repository owner,** and are real changes. Case 11 is a clean change that the current code already contains (`ApprovalService.cs:43-48`). I labelled both myself, and nothing independent confirms the labels.
4. **I scored my own cases and the truth key.** The sub-agent labels from my first exploration pass were partly wrong (for example, it called `ToZero` banker's rounding), so I re-derived the key. A second scorer would make the key more trustworthy.
5. Noise-item counts are my approximate reading of the outputs, not a tool-computed number.
6. Four of the ten original cases were "shown in the session". I did not know which, so all ten were run.

## Case diffs do not match the code

`case-03` and `case-08` change code that differs from this tree: `DiscountCalculator` has no static `Apply` (it has `ApplyDiscount`), and the real repository is a `List<Invoice>` with a `lock`. The reviewers judged each diff on its own text, which is what the eval asks for.
