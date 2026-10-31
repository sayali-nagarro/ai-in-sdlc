# ADR 0001: Conditional exactly-once payment effect for approved invoices to PayEx

Status: recommendation recorded for the assignment; not approved for implementation. PayEx's duplicate-detection contract is unconfirmed, so production go-live remains blocked until the stated dependency and tests pass. The option comparison and three stress tests were run with an agent. The preference challenge below was hypothetical, not a preference stated by the decision owner. Review and approve this decision before implementation.
Date: 2026-10-24

**Production-readiness gate:** Sandbox verification and fault/load tests are
still required before this design can be treated as production-ready.

## Context

From January the service submits every approved invoice to PayEx.

- PayEx returns a reference on success. It times out at 30 seconds, and a timeout does not reliably mean the submission failed.
- Scenario planning assumes about 40,000 invoices a month, 60% in the last three working days (about 8,000 a day), peaking near 80 approvals a minute. At 30 seconds per call, 80 a minute is about 40 calls in flight. These are not measured production volumes; validate the forecast before capacity planning.
- Six engineers, two new to the codebase, one-week on-call rotation.
- Approval actions must be auditable for seven years (SOC 2 Type II audit in six months).
- Azure SQL is the planned store. Service Bus is provisioned but unused. None of the persistence, the outbox or the PayEx client exists in the code today; see [target-state.md](../architecture/target-state.md).

Exactly-once delivery across this application and an external payment system cannot be guaranteed by this application alone. The achievable goal is durable at-least-once submission with an exactly-once payment effect, and only if PayEx atomically deduplicates a stable key (or provides an equivalent reliable duplicate-detection contract). The outbox prevents loss of local intent; it cannot by itself prevent PayEx from accepting the same payment twice.

## Options considered

| | A: idempotency key + dedupe table | B: transactional outbox + worker | C: optimistic submit + nightly reconciliation |
| --- | --- | --- | --- |
| Duplicate payments | Prevented only if PayEx atomically honours the key | Prevented only if PayEx provides atomic deduplication; lookup alone is not sufficient | May be detected later; prevention is not guaranteed |
| Lost submissions | Not prevented: a crash between approval and the call loses the intent | Prevented: intent commits with the approval | Detected late |
| 30s call in the request path | Yes | No | Yes |
| Build effort (agent estimate, a guess) | 3 to 6 days | 12 to 20 days | 6 to 10 days |
| Operational load | Low | Moderate: worker, alerts, runbooks | High and manual: daily mismatch triage |
| Incremental run cost (unpriced planning estimate) | Existing SQL plus a small dedupe table; synchronous API capacity remains necessary | SQL outbox plus worker compute; potentially no added compute if the existing App Service plan has capacity | Scheduled reconciliation and existing SQL/API; ongoing manual mismatch investigation |
| SOC 2 evidence | Partial | Strong: intent, outcome and audit in one transaction | Weak: repair after the fact |

The effort ranges are not on a common scope, and the run-cost row is qualitative rather than a priced estimate. See "Where the agent was wrong or useless". Price all options against confirmed Azure sizing and include engineering and on-call labor before implementation approval.

## Decision

For this assignment, record **B with A** as the selected recommendation: a transactional outbox with a worker, and a stable idempotency key on every call. Run **C as a daily safety net**, not as the mechanism. Treat a timeout as an unknown outcome, never as a failure. This design provides an exactly-once effect only if the PayEx contract satisfies the dependency below; neither the outbox nor this application guarantees exactly-once delivery to PayEx. This is a documented recommendation, not production approval.

Rules the design must follow:

1. **One transaction on approval.** Atomically transition the invoice to Approved, create one durable approval ID, write the audit row, and insert one outbox row with its stable idempotency key. Enforce uniqueness for the logical approval/payment intent in the database, not just in process memory.
2. **Deduplicate approval commands and events.** Persist the caller's idempotency/request ID, a payload hash, and the result. A repeated request ID with the same payload returns the recorded result; reuse with a different payload is rejected. A concurrent or later approval command for an already-approved invoice must not create another approval or outbox row. Enforce the state transition with a database concurrency condition and unique constraint so duplicate events, multiple app instances, and races cannot create a second logical payment.
3. **The PayEx key is minted once and never changes.** Derive it from the durable approval ID; never derive it from amount, attempt count, or another mutable field. Persist it before any external call and use exactly that key and payload on every attempt. A retry or restart must never mint a replacement key.
4. **No transaction is held across the PayEx call.** The worker claims a row under a short transaction with a lease, lease token/fencing value, and heartbeat; it commits before calling PayEx and records the result in a second transaction. State updates must be conditional on the current lease token so a stale worker cannot overwrite a newer resolution.
5. **Worker crashes are recoverable from durable state.** Unclaimed outbox rows remain available after an application/worker restart. An expired lease becomes Unknown, not Pending or Failed. The replacement worker resolves the outcome through lookup or a contract-safe replay before deciding the result. A crash after PayEx accepts but before local success is committed follows the same Unknown-resolution path.
6. **Unknown is a durable state, not an instruction to make a new payment.** A timeout, ambiguous 5xx, or expired lease moves the row to Unknown. When PayEx's verified atomic-idempotency contract is in force and the key remains valid, replaying the identical key and payload is safe and must return the original payment/reference; use that response to resolve the row. Otherwise, use a reliable lookup and replay only when the vendor contract guarantees duplicate prevention and the result/retention conditions permit it. If neither safe path establishes the outcome, keep it Unknown and escalate; do not automatically submit with a new key. Do not manually change Unknown to Failed or bulk-reset it to Pending without PayEx evidence. Any authorized manual requeue must record who, why, when, and the supporting evidence.
7. **Separate definite failures from ambiguous ones.** A response explicitly documented by PayEx as a rejection is a definite failure. A timeout, connection loss, or undocumented/ambiguous 5xx is Unknown. Systemic errors (expired credentials, schema changes, vendor outage) trip a breaker and pause attempts instead of burning retries. Retry definite transient failures with bounded exponential backoff and jitter; preserve the outbox row and alert on exhaustion.
8. **Survive application restarts and duplicate client submissions.** The database is the source of truth for request IDs, approval IDs, outbox state, and PayEx keys. No correctness decision may depend on in-memory caches or a process-local lock. Retrying the same client request after restart returns the persisted approval result without creating a second payment intent.
9. **Month-end capacity and failure handling.** After validating the scenario forecast, the worker must sustain the confirmed peak and safely drain a backlog after a PayEx or worker outage. The transactional outbox is durable backpressure; do not drop or bulk-reset pending rows. Before go-live, run a month-end load/failure test at the confirmed peak, including 30-second timeouts, worker termination/restart, PayEx throttling/outage, and recovery while new approvals continue. Alert on oldest pending age, backlog growth, Unknown count/age, breaker state, and reconciliation mismatches; establish and verify capacity and recovery objectives.
10. **Reconcile accepted payments.** Run daily reconciliation against a PayEx lookup or report keyed by the stable idempotency key/merchant reference. If PayEx accepted a payment but the application did not record the response, reconciliation records the existing PayEx reference and marks that same outbox item accepted; it must not create a new payment. Unmatched, conflicting, or not-yet-visible records remain exceptions for investigation, not automatic resubmissions.
11. **HTTP client.** Use `IHttpClientFactory` with an explicit timeout. INC-2041 was a per-request `new HttpClient()` with the default 100-second timeout.
12. **Do not put this path on Service Bus now.** INC-2047 showed a subscription filter silently dropping events with no dead letters. A database outbox keeps the intent in the same store as the approval. If other consumers appear later, publish events from the outbox, with versioned event types and an alert when a subscription processes nothing.

## Failure-mode coverage and release gate

| Failure mode | Required behavior in this design | Status / verification |
| --- | --- | --- |
| Duplicate approval events or concurrent approval commands | Database-guarded state transition plus one unique approval/payment intent; duplicate request IDs return the persisted result. | Design requirement; verify with concurrent/replayed-command integration tests. |
| Worker crash before or during a PayEx call | Durable outbox survives restart; lease expires to Unknown; a stale worker is fenced from changing current state. | Design requirement; fault-inject process termination before call, during call, and after acceptance/before local commit. |
| PayEx timeout | Persist Unknown; do not assume failure or immediately retry. | Design requirement; test an accepted request whose response is dropped. |
| Retry after unknown outcome | Replay only through a verified atomic-idempotency contract using the identical key/payload, or follow a vendor-documented equivalent duplicate-detection and lookup contract. A query returning no result without atomic duplicate prevention is insufficient. Otherwise hold for human resolution. | **Blocked on PayEx contract and sandbox verification.** |
| Duplicate request after API/application restart | Persist request ID and approval/payment identity in SQL; enforce uniqueness and return prior outcome. | Design requirement; test restart between commit and client response, then replay request. |
| Month-end outage, throttling, or worker capacity shortfall | Durable backlog, bounded retries/backoff, breaker, monitoring, and tested catch-up capacity at expected peak. | **Not demonstrated.** Month-end load and failure drill is a go-live gate. |
| PayEx accepted payment but local state is missing/stale | Reconciliation matches by stable key/reference and records the existing PayEx reference without resubmitting. | **Blocked on PayEx lookup/report contract and reconciliation test.** |

**Go-live dependency:** do not enable automatic submission or automatic retry of Unknown outcomes until PayEx contract and sandbox evidence establish either (a) an idempotency key that atomically deduplicates requests, returns the original payment/reference for repeats, rejects key reuse with a different payload, and remains valid longer than the maximum retry/reconciliation window; or (b) an equivalent vendor-enforced unique merchant reference with reliable lookup and the same duplicate-prevention and retention guarantees. A lookup that is merely eventually consistent, without atomic duplicate prevention, is not sufficient to make concurrent/retried submissions safe. If neither contract is available, this design cannot promise an exactly-once payment effect: keep ambiguous outcomes out of automatic retry and block production go-live until the vendor contract or integration design changes.

## Assumptions that must be confirmed with PayEx before building

The decision depends on these, and I could not resolve them from the repository. This is a hard dependency, not an implementation detail or a claim that the application can guarantee exactly-once delivery.

1. Does PayEx atomically deduplicate on a client-supplied idempotency key? Do identical replays return the original payment/reference without creating another payment, and does reusing a key with a different payload fail?
2. What is the key/merchant-reference uniqueness scope and retention period? It must exceed the maximum time to resolve Unknown outcomes, including outages and reconciliation delay.
3. Is lookup by key/reference sufficiently consistent to establish whether a timed-out request was accepted? What is the maximum visibility delay?
4. Does PayEx provide a report/export or API suitable for daily reconciliation, including accepted payments and stable references?

If PayEx offers neither atomic key/merchant-reference deduplication nor an equivalent reliable contract, no design here can guarantee a single payment effect. Every Unknown row must remain out of automatic retry and go to a human/vendor resolution path; production submission is blocked until a safe contract or integration change exists. Lookup alone is not enough if two concurrent requests can both observe absence and then both be accepted.

### Status of the assumptions: unconfirmed

Nothing in this repository documents PayEx's API. The only trace is the INC-2041 deploy diff, which posts to `/v2/payments` with an `X-Api-Key` header and sends no idempotency header. `ops/README.md` says the vendor is invented, so there is no real endpoint, sandbox or contact to call from here. These must be answered by whoever owns the PayEx contract:

1. Does `POST /v2/payments` atomically enforce a client-supplied key or unique merchant reference? What does a replay with the same key and same body return, and can it safely resolve an Unknown outcome without a preceding lookup? Does the same key with a different body fail?
2. How long are keys/references retained, and is that window stated in the contract?
3. Is lookup by key/reference complete and sufficiently consistent after a timed-out submission? What is the maximum visibility delay?
4. Is there a reconciliation report/API that includes the stable key/reference and accepted payment status?
5. Is there a sandbox where a 30-second timeout and worker crash after acceptance can be forced, so the Unknown and reconciliation paths can be tested before January?

Required sandbox test: submit one payment with a key, abandon the connection after PayEx accepts it but before the response reaches the worker, then replay the same key and query/reconcile by reference. Also issue concurrent identical submissions and a same-key/different-payload submission. Pass requires exactly one accepted payment, the same reference returned or discoverable on replay, and rejection of the changed payload. Repeat with a worker restart and verify the agreed key-retention/lookup window. No sandbox result or contract confirmation is present in this repository.

## Consequences

- Approval no longer waits on PayEx, so a 30-second timeout does not block approvers at month end.
- The team runs a worker. That is the main recurring cost, and it falls on a one-week rotation with two new engineers. The mitigation is a one-page runbook whose first line is "Unknown means look up, never reset."
- Estimated Azure cost is about nothing extra (the worker can run on the existing App Service plan, data is a few GB over seven years). Service Bus Standard would add a base fee of roughly ten dollars a month if used. These are the agent's estimates and I have not checked them against the pricing calculator.
- Required alerts: oldest pending age, count and oldest age of Unknown rows, dead-lettered rows, and breaker state.
- A month-end load and failure drill with PayEx stubbed to time out is part of the work, not a follow-up.

## What would make me revisit this

- PayEx does not provide verified atomic idempotency or an equivalent duplicate-detection contract (see the go-live gate above).
- PayEx's key retention is shorter than our Unknown-resolution SLA.
- The Unknown rate exceeds 1% of submissions in any week (my threshold, not measured), which means the resolver is doing too much of the work.
- Oldest pending age passes 15 minutes more than twice in a month (my threshold), which suggests the worker design is not keeping up.
- The team cannot staff the worker on-call by January. Option A with a scheduled retry job is a fallback only if it preserves the same verified PayEx duplicate-detection guarantee; otherwise block production submissions until a safe contract and operating model exist.
- Volume grows about tenfold, or a second consumer of approval events appears. At that point move the relay to Service Bus.

## Where the agent was wrong or useless

These are specifics from the sessions, not general complaints.

1. **It proposed a risky key in its first answer.** The first comparison defined the key as "invoice ID + submission version". When I asked how this fails at 3 a.m., the same agent named a key derived from mutable fields or an attempt counter as a cause of double payment. The first answer set up the hazard that the second warned about. I replaced it with a key minted once from the invoice id and approval id.
2. **The first answer left out the lease.** It described a worker that "polls with row locking" and nothing about a lease, a heartbeat, or not holding the transaction over the 30-second call. The 3 a.m. pass found that a worker dying mid-call leaves rows stuck InFlight, or blocks SQL if the transaction is held. Rules 3 and 4 come from that second pass, not from the first.
3. **The preference probe was hypothetical, not the decision owner's preference.** For the stress test, the prompt asked the agent to assume a preference for C. The recommendation did not move from B with A; the agent explained the trade-offs and then offered a "compromise": write the intent row and key in the approval transaction, submit inline, mark timeouts Unknown, and sweep them. That is B with the worker removed, so it blurred the distinction between B and C. The challenge tests whether the recommendation survives pushback; it must not be presented as evidence that the decision owner prefers C.
4. **The cost estimates mix scopes.** Option A was 3 to 6 days and C was 6 to 10 days, but C's range includes the inline PayEx call and A's does not, so they are not comparable. The agent also produced figures such as a 0.1% unknown rate and 1 to 3 hours per recovery with no basis. It flagged them as guesses, but guesses still end up in the table above. Treat every cost figure as an order of magnitude.
5. **It could not answer the question the whole design hangs on.** Whether PayEx honours keys or supports lookup is not in the repository. Every answer said "confirm with PayEx". That is correct, and it is also the part that I needed help with and did not get. The agent cannot replace a call to the vendor or a test against the sandbox.
6. **The 3 a.m. answer was too tidy.** Five scenarios, each with a clean "wrong action, right action, build beforehand" shape. Real incidents are messier: two of these happen at once, and the on-call person has no runbook yet. I used it as a checklist, and I would not treat it as a forecast.
7. **It cited no evidence from this repo.** Neither the INC-2041 socket exhaustion nor the INC-2047 filter failure came up until I brought them in. An agent that had read `ops/incidents` would have said that this team has already had an unbounded HTTP client and a silent topic filter. The sessions ran with no file access, so that was my setup choice as much as the agent's gap.
