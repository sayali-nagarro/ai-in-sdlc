# Invoice Approval Demo App

A small invoice approval app used for live AI-in-SDLC demos. It is deliberately simple: a .NET 8 API, a plain web UI, and an in-memory store, so it runs with one command and no database.

## Run it

```
dotnet run --project backend/src/InvoiceApp.Api
```

Open http://localhost:5000 and sign in:

| User | Password | Role |
| --- | --- | --- |
| `demo.approver` | `ChangeMe123!` | Approver |
| `demo.admin` | `ChangeMe123!` | Admin |

These are demo accounts for a local, in-memory app. They are not real credentials.

## What it does

1. Create an invoice (it starts as a draft).
2. Submit it for approval.
3. An approver approves it, or rejects it with a reason.

Invoices move through Draft, Pending Approval, then Approved or Rejected.

## Tests

```
dotnet test backend/InvoiceApp.sln
```

## Project layout

```
backend/
  src/InvoiceApp.Domain   business rules
  src/InvoiceApp.Api      controllers, sign-in, web UI (wwwroot)
  tests/InvoiceApp.Tests  xUnit tests
docs/use-cases            short feature briefs
AGENTS.md                 conventions for AI coding agents
```

## Production-readiness assignment

- Demo video (8 to 10 minutes): **TODO: add link after upload** (script: [docs/demo-script.md](docs/demo-script.md))
- [As-built architecture](docs/architecture/as-built.md) and [target state](docs/architecture/target-state.md)
- [Decision record: exactly-once PayEx submission](docs/adr/0001-exactly-once-payex-submission.md)
- [Autonomy policy](docs/policy/incident-first-response-autonomy.md) ([one-page PDF](docs/policy/incident-first-response-autonomy.pdf))
- [Review eval](docs/eval/review-eval.md) and [raw results](ops/evals/results.csv)
- [Risk audit](docs/security/risk-audit.md)
- [Baseline measurement plan](docs/measurement/baseline.md)
- [AI augmentation log](docs/ai-augmentation-log.md), [historical structured log](docs/ai-augmentation-log.jsonl), and [verification/session entries](docs/ai-augmentation-verification.jsonl)
- [Handover checklist](docs/handover-checklist.md)
- [Final verification report](docs/final-verification-report.md)

## Use cases

- [UC-1 Bulk invoice approval](docs/use-cases/UC-1-bulk-approval.md)
- [UC-2 Partial approval](docs/use-cases/UC-2-partial-approval.md)
