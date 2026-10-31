# Review evaluation: recorded results and provenance audit

Recorded rows: [ops/evals/results.csv](../../ops/evals/results.csv) (72 rows:
12 cases x 3 labeled runs x 2 prompt versions). These are verdicts and finding
summaries, not the complete model outputs or session transcripts. I checked the
CSV rows and case diffs during this handover; I did **not** rerun the model
evaluation.

## Handover run set

The dataset contains the three baseline-labeled v1 runs and a candidate fourth
comparison (v2 run 1), plus two further v2 runs. That four-run subset has the
intended single prompt-text change, but the CSV has no timestamps or session
IDs. Therefore it cannot establish that v2 run 1 was chronologically the
fourth run, or verify that the same model/configuration was used.

| Selected run | Rows | Recorded outcome |
|---|---|---|
| Baseline 1 | v1 run 1, 12 cases | 8/8 defects caught; 0 missed; 3/3 clean cases correct; 0 false alarms; case 09 doc finding recorded separately |
| Baseline 2 | v1 run 2, 12 cases | Same rates; case 09 doc finding recorded separately |
| Baseline 3 | v1 run 3, 12 cases | Same rates; case 09 doc finding recorded separately |
| Changed-variable comparison | v2 run 1, 12 cases | 8/8 defects caught; 0 missed; 3/3 clean cases correct; 0 false alarms; case 09 doc finding withheld |

The raw file also contains v2 runs 2 and 3. Rates recomputed across all three
runs per condition are 24/24 defect catches and 0/9 false alarms for each
prompt; case 09 was named in 3/3 v1 runs and 2/3 v2 runs. Repeated reviews of
identical diffs are not independent samples.

## Setup

- The ten original cases in `ops/evals/cases` plus two owner-provided cases (`case-11`, `case-12`).
- Earlier session notes say each review used a fresh sub-agent session with only the diff and prompt and no tools. The CSV has no session IDs, outputs, or per-run configuration, so this setup cannot now be independently verified.
- The `model` column contains only `session-default`; this is not an exact model identifier. No individual review timestamps, model version, configuration, or raw output reference is present in the CSV.
- **v1** is the exact prompt from `ops/evals/README.md`.
- **v2** is v1 plus one sentence: "For each finding also give a concrete input or sequence of events that triggers the failure; if you cannot name one, do not report it."
- The v2 prompt differs from v1 by that one sentence. Prior notes say the hypothesis was written before v2, but the timestamped preregistration is not in this repository.

## Case-set validation

I inspected all 12 diffs against the recorded truth key. Cases 01–10 are the
original set; 11–12 are the owner-provided additions. This validates the
case content and whether the recorded labels are plausible; it does not
independently validate historical model responses or authorship of the key.

| Case | Review of diff and label |
|---|---|
| 01 | Defect: nullable `Ids` is dereferenced and earlier approvals can persist if a later item fails. |
| 02 | Defect: customer/status values are interpolated into SQL. |
| 03 | Defect: `ToZero` truncation changes monetary calculations; the diff is a standalone snippet and does not match the current `DiscountCalculator` implementation. |
| 04 | Clean: consistent repository-field rename. |
| 05 | Defect: destructive `Delete` endpoint lacks the Admin role restriction. |
| 06 | Clean against current implementation: added tests exercise existing reason validation and approval metadata behavior. |
| 07 | Defect: logs serialize invoice and session/user objects. |
| 08 | Defect: replacing a concurrent collection with unsynchronized `Dictionary` and check-then-add creates races; this snippet does not match the current list-and-lock implementation. |
| 09 | Ambiguous/documentation issue: code diff is clean, but README claims sign-out/sign-in resets singleton in-memory data. Kept separate from code defect/clean rates. |
| 10 | Defect: catch-all returns success-shaped HTTP 200 on failure. |
| 11 | Clean: test-only whitespace-reason cases match validation already present in the current `ApprovalService`. |
| 12 | Defect: approval commits before external payment succeeds, and the controller bypasses common error mapping. |

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

## Recorded results and rates

| Metric across recorded three runs | v1 baseline | v2 changed prompt |
|---|---:|---:|
| Defect catches (8 cases x 3) | 24/24 (100%) | 24/24 (100%) |
| Misses among labeled defect cases | 0/24 | 0/24 |
| Clean cases correctly clean (3 cases x 3) | 9/9 | 9/9 |
| False alarms on labeled clean cases | 0/9 (0%) | 0/9 (0%) |
| Ambiguous case 09 README finding named | 3/3 | 2/3 |
| Noise items on cases 06/11, approximate historical score | ~21/6 reviews | 0/6 reviews |

The recorded 95% Wilson intervals are 86–100% for 24/24 catches and 0–30% for
0/9 false alarms. These are descriptive of this small, repeated case set, not
evidence of production review performance.

For transparency: before `case-11` and `case-12` were replaced, my own earlier `case-12` (a length limit) produced one borderline false alarm under v2 (a UTF-16 code-unit nit stated as a finding). That case is no longer in the data, so the table above does not include it. Replacing the cases changed that result from 1/9 to 0/9, which shows how much a single case can move these rates.

## Did the change help?

**Not demonstrably.** My confidence that v2 is better than v1 on the metrics that matter is low.

- Both prompts caught every defect and neither produced a false alarm, so on every rate the two are identical. The caught rate is at its ceiling and the false-alarm rate is at its floor, so this set cannot show an improvement or a regression.
- The three runs of one case are not independent: each run saw the same diff and mostly produced the same answer. The effective sample is closer to 12 cases than to 36 runs, so the real uncertainty is wider than the intervals above.
- What did change is secondary. v2 produced no hedged speculative items on the clean cases (about 21 down to 0). It also made every finding carry a concrete input, which is useful to whoever has to verify it.
- v2 has a cost. In run 1 of case 09 it considered the README defect and withheld it because it could not name a trigger. A true finding was suppressed by the rule.

Decision: keep v1 as the baseline for recall. v2 looks promising for reducing noise, and it did not lose recall on the defect cases, but the evidence is one suppressed true finding against about 21 fewer speculative items on a set this easy. Do not adopt it on this evidence alone.

## Evidence limits and remaining work

1. The logged results satisfy a selectable three-baseline-plus-one-prompt-change comparison, but missing timestamps/session IDs prevent proving chronological run order or actual control of model/configuration. Do not claim a verified fourth sequential run.
2. The required per-review timestamps, exact model identifiers, configuration, prompts/outputs, and session references are not in the raw CSV. They cannot be recreated from verdict summaries without fabricating evidence.
3. Prior notes report automatic workspace instructions (`AGENTS.md`) were present, so the review context was not isolated to just the diff/prompt.
4. The two added cases were supplied by the repository owner; the truth key was scored by the same author and was not independently adjudicated.
5. Approximate noise counts are human estimates, not tool-computed measurements.
6. Prior notes say four original cases were previously shown in a session; which cases is not recorded.
7. A new fully auditable evaluation remains outstanding. For any rerun, save each exact prompt and output, UTC timestamp, exact model/version, session ID, tool/context configuration, and scoring decision before aggregating rates.

## Case diffs do not match the code

`case-03` and `case-08` change code that differs from this tree: `DiscountCalculator` has no static `Apply` (it has `ApplyDiscount`), and the real repository is a `List<Invoice>` with a `lock`. The reviewers judged each diff on its own text, which is what the eval asks for.
