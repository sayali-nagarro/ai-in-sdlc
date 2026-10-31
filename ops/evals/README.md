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
3. Record what it reported in `results.csv`, using `results-template.csv` as
   the 12-case, three-run starter for one prompt condition. Duplicate and
   update `prompt_version` for a changed-variable condition.
4. Repeat the whole set three times. Output varies between runs, so a single
   pass gives you an anecdote rather than a rate.
5. To meet the handover comparison, first complete three runs of the baseline
   prompt, then run the full set once with exactly one changed variable. Record
   that changed-variable run separately. Further repetitions are useful but
   do not replace labeling the designated comparison. The completed dataset
   contains three runs for each of v1 and v2; see the handover table in
   `../../docs/eval/review-eval.md`.

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
