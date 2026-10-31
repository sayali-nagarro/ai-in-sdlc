# Review eval

Twelve review cases for measuring how well a review prompt performs on this
codebase. Cases 01–10 are the original fixed set; cases 11 and 12 were supplied
by the repository owner. Each case is a diff in `cases/`. Some contain a defect
and some do not; the scoring key is documented separately in
`../../docs/eval/review-eval.md`.

## Why run it

A review that finds something on one pull request has told you nothing about
how it behaves in general. This set gives you three numbers you can compare
over time, across models and across prompt versions:

- **Caught** — the case has a defect and the review named it.
- **Missed** — the case has a defect and the review did not.
- **False alarm** — the case is clean and the review reported a defect anyway.

The false alarm rate is the one people forget to measure, and it is the one
that decides whether anyone keeps using the reviewer.

## How to run it

1. Start a fresh session for each case. Context from a previous case will
   change the answer.
2. Give the agent the case diff and the review prompt below. Nothing else.
3. Use `evidence-template.csv` to record provenance for every case: exact UTC
   time, fresh session ID, provider/model/version, configuration/context/tools,
   prompt and diff hashes, exact prompt/output references, and scorer. Keep
   unmodified raw outputs; `results.csv` is a verdict-summary file, not a
   transcript archive.
4. Run all 12 cases in fresh sessions three times with the baseline prompt.
   Then run all 12 once more with exactly one predeclared variable changed.
   Keep model, version, context, tools, scoring rules, and case diffs fixed.
   Label this as run 4 only after timestamped evidence establishes the order.
5. Score before aggregation. Record caught/missed on the eight defect cases
   and false alarms on the three clean cases; report case 09 separately as
   ambiguous.

The existing `results-template.csv` predates the provenance fields and the
existing `results.csv` lacks per-call timestamps, session IDs, exact model
identity/configuration, and raw outputs. See the audit in
`../../docs/eval/review-eval.md`; do not fill missing historical fields from
memory or infer them from the `session-default` label.

## The review prompt

> Review this diff for defects. For each finding give the file, the line, what
> goes wrong, and how confident you are. If you find nothing, say so
> explicitly rather than listing general observations.

## Scoring

Score one case per row. A finding counts as caught only if it names the actual
defect; a vague note that something "could be improved" near the right line
does not count, and neither does a correct finding reached for the wrong
reason. Be strict about this, because a generous score here is a score you
cannot act on later.

For the clean cases, style suggestions are not false alarms. A false alarm is
the review asserting a defect that is not there.
