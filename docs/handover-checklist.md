# Handover checklist

Status as of 2026-10-31. “Covered” means an artifact exists; it does not imply external approval, production verification, or independent validation.

| # | Deliverable | Status | Evidence / remaining action |
| --- | --- | --- | --- |
| 1 | Mermaid source for as-built and target diagrams, citation list, inferred-items list | Covered | Sources and evidence lists: [as-built architecture](architecture/as-built.md) and [target state](architecture/target-state.md). PNGs exist; render provenance is not recorded. |
| 2 | One architecture test and command | Covered; fresh run passed | Test: [ArchitectureTests.cs](../backend/tests/InvoiceApp.Tests/ArchitectureTests.cs). Command: `dotnet test backend/InvoiceApp.sln --filter ArchitectureTests`. Fresh run on 2026-10-31 passed 1/1; the result summary is recorded in [the JSONL session log](ai-augmentation-log.jsonl), but no separate `.trx` report was saved. |
| 3 | Exactly-once decision record, including where the agent was wrong or useless | Covered; owner/vendor review pending | [Decision record](adr/0001-exactly-once-payex-submission.md). Confirm owner sign-off and PayEx idempotency/lookup assumptions. |
| 4 | One-page autonomy policy with day-one level | Content covered; page count not verified | [Autonomy policy](policy/incident-first-response-autonomy.md) explicitly sets day one to L1 for summaries and L0 for everything else. Verify rendered page count. |
| 5 | Two added evaluation cases and results for three runs plus changed-variable run | Covered; provenance caveat | Owner-supplied cases 11 and 12 are included in [eval cases](../ops/evals/cases/). [Results](../ops/evals/results.csv) contains three v1 baseline runs and three v2 changed-prompt runs. The selected three-plus-one comparison and outcomes are summarized in [review-eval.md](eval/review-eval.md). Exact per-review model identity and timestamps were not captured; labels were owner-scored, not independently validated. |
| 6 | Risk audit with a recorded decision | Decision covered; control not verified | [Risk audit](security/risk-audit.md) records the decision. Browser egress isolation is not demonstrated in the active MCP launch setup; do not describe it as enforced. |
| 7 | Measurement plan with two captured numbers | Covered with explicit scope caveats | [Measurement baseline](measurement/baseline.md) reports the 31.3-minute median and at-most-33% change-failure estimate. Scenario operations figures are invented/planned data, not production measurements; the one real 31-second CI observation is separate. |
| 8 | 8–10-minute demo video, uploaded and linked | **Outstanding — handover blocker** | [Demo script](demo-script.md) and [README](../README.md) still have TODO link placeholders. Record, upload, verify duration, and replace both placeholders. |
| 9 | AI augmentation logs | Partial | [Readable retrospective](ai-augmentation-log.md) and [JSONL session trace](ai-augmentation-log.jsonl) are available. Historical transcripts, per-review prompts/outputs, some model identities, skills, and exact timestamps were not captured in the repository. The JSONL entry must not be interpreted as a complete backfill of earlier sessions. |

## Final release checks

- Obtain owner review of the decision record and PayEx assumptions.
- Confirm the autonomy policy fits one page when rendered.
- Demonstrate or explicitly leave the browser-egress control outstanding.
- Run the architecture test and retain the output.
- Upload the demo video and add its URL here, in the README, and in the demo script.
- Preserve the measurement and evaluation caveats when presenting results.
