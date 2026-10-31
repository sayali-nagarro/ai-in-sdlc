# Target architecture (proposed, not built)

Canonical Mermaid source: [target-state-container.mmd](./target-state-container.mmd).
Rendered image: [target-state container](./diagrams/target-state.png).
Every node (`TNxx`) and relationship (`TExx`) is mapped to evidence in the
[architecture citation register](./architecture-citations.md). The diagram
distinguishes existing application code from planned services and scenario-only
infrastructure; it does not assert these components are deployed by this app.
It rendered successfully with Mermaid CLI 11.4.2 on 2026-10-31; the exact
command is recorded in the [final verification report](../final-verification-report.md).

The PayEx path is not a guarantee of exactly-once delivery. A single payment
effect depends on PayEx atomically deduplicating the stable key or enforcing an
equivalent unique merchant reference. The contract, recovery behavior, and
reconciliation must be verified before go-live; see the ADR's
[release gate](../adr/0001-exactly-once-payex-submission.md#L50).

## Planned components and status

| Component | Status in this checkout | Evidence / condition |
|---|---|---|
| Azure SQL persistence | Not built; current repository is in-memory. | [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs) is the only implementation. |
| Append-only approval audit, seven-year retention | Not built; `Invoice` has only current decision fields. | Requirement comes from the brief; physical schema and retention control are unspecified. |
| Transactional payment outbox and worker | Not built; proposed by the draft ADR, not owner-approved. | Requires atomic invoice/audit/outbox transaction; worker host remains undecided. |
| PayEx client | Not built; scenario only. | Vendor contract is invented in `ops/`; idempotency/duplicate-detection and reconciliation assumptions remain unconfirmed. |
| Unknown-outcome resolver and reconciliation | Not built. | Depends on verified PayEx key/lookup/report behavior; unresolved outcomes must not trigger unsafe resubmission. |
| Service Bus topic and subscriptions | Not used by application code; shown as scenario evidence only. | Names come from `ops/incidents/INC-2047`; payment path is not designed to depend on it. |
| Optimistic concurrency (`rowversion`) | Proposal only; not a settled design or implementation. | Proposed to close the current check-then-act gap; confirm requirements and conflict behavior. |

## Inferred or proposed items

- `SqlInvoiceRepository`, `ApprovalAudit`, and `PayExOutbox` are illustrative
  names, not source-defined classes or tables.
- `rowversion`/optimistic concurrency is a proposal, not an approved schema.
- A future outbox-to-Service-Bus publisher is conditional on approved
  additional consumers; it is not part of the current PayEx path.
- The notification and archive subscriptions are present only in scenario
  evidence; their production relationship to this app is unverified.
- The worker's deployment location, schema, API/report integration, alert
  transport, and ownership require decisions before implementation.

See the separate [inference register](./architecture-inferences.md) for
assumptions, missing evidence, verification steps, and impact.
