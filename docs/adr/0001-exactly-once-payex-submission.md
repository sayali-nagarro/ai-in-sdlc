# ADR 0001: Exactly-once effect for submitting approved invoices to PayEx

Status: draft for the owner's review and edit. The option comparison and the three stress tests were run with an agent; the decision, the revisit triggers and the section on where the agent was wrong are written from those sessions and need your sign-off.
Date: 2026-10-24

## Context

From January the service submits every approved invoice to PayEx.

- PayEx returns a reference on success. It times out at 30 seconds, and a timeout does not reliably mean the submission failed.
- Volume is about 40,000 invoices a month, 60% in the last three working days (about 8,000 a day), peaking near 80 approvals a minute. At 30 seconds per call, 80 a minute is about 40 calls in flight.
- Six engineers, two new to the codebase, one-week on-call rotation.
- Approval actions must be auditable for seven years (SOC 2 Type II audit in six months).
- Azure SQL is the planned store. Service Bus is provisioned but unused. None of the persistence, the outbox or the PayEx client exists in the code today; see [target-state.md](../architecture/target-state.md).

Exactly-once delivery over a network does not exist. The achievable goal is at-least-once submission to a receiver that deduplicates, which gives an exactly-once effect. The question is how to get there with this team.

## Options considered

| | A: idempotency key + dedupe table | B: transactional outbox + worker | C: optimistic submit + nightly reconciliation |
| --- | --- | --- | --- |
| Duplicate payments | Prevented, if PayEx honours the key | Prevented, with the key or a lookup | Detected up to 24 to 72 hours later |
| Lost submissions | Not prevented: a crash between approval and the call loses the intent | Prevented: intent commits with the approval | Detected late |
| 30s call in the request path | Yes | No | Yes |
| Build effort (agent estimate, a guess) | 3 to 6 days | 12 to 20 days | 6 to 10 days |
| Operational load | Low | Moderate: worker, alerts, runbooks | High and manual: daily mismatch triage |
| SOC 2 evidence | Partial | Strong: intent, outcome and audit in one transaction | Weak: repair after the fact |

The effort ranges are not on a common scope, see "Where the agent was wrong or useless".

## Decision

Use **B with A**: a transactional outbox with a worker, and a stable idempotency key on every call. Run **C as a daily safety net**, not as the mechanism. Treat a timeout as an unknown outcome, never as a failure.

Rules the design must follow:

1. **One transaction on approval.** Mark the invoice Approved, write the audit row, and insert the outbox row with its idempotency key.
2. **The key is minted once, at approval time, and never changes.** Derive it from the invoice id and the approval id. Never derive it from the amount, an attempt counter or any mutable field. Put a unique constraint on it. There is no code path that mints a second key for the same approval.
3. **No transaction is held across the PayEx call.** The worker claims a row (`UPDLOCK, READPAST`) with a lease and a heartbeat, commits, calls PayEx, then records the result in a second transaction.
4. **Unknown is a state of its own.** A timeout or an expired lease moves the row to Unknown, not to Pending and not to Failed. One resolver handles Unknown rows: look the payment up at PayEx by key or merchant reference first, and replay the same key only if PayEx has no record and the key is still inside PayEx's retention window.
5. **No manual Unknown to Failed, and no bulk reset to Pending**, without proof from PayEx. Any manual requeue goes through an audited tool that records who, why and when.
6. **Separate definite failures from ambiguous ones.** A 4xx is a definite failure. A timeout or a 5xx is ambiguous. Systemic errors (an expired credential, a schema change) trip a breaker and pause the worker instead of burning each row's retries.
7. **HTTP client.** Use `IHttpClientFactory` with an explicit timeout. INC-2041 was a per-request `new HttpClient()` with the default 100-second timeout.
8. **Do not put this path on Service Bus now.** INC-2047 showed a subscription filter silently dropping events with no dead letters. A database outbox keeps the intent in the same store as the approval. If other consumers appear later, publish events from the outbox, with versioned event types and an alert when a subscription processes nothing.

## Assumptions that must be confirmed with PayEx before building

The decision depends on these, and I could not resolve them from the repository.

1. Does PayEx honour a client-supplied idempotency key, and for how long does it keep keys? The retention must be longer than the time we allow to resolve an Unknown row.
2. Does PayEx offer a lookup by merchant reference?
3. Does PayEx give us a report or export for the nightly reconciliation?

If PayEx offers neither a key nor a lookup, no design here is safe. Every Unknown row would go to a human queue before any resubmission, and that needs a contractual or integration change.

### Status of the assumptions: unconfirmed

Nothing in this repository documents PayEx's API. The only trace is the INC-2041 deploy diff, which posts to `/v2/payments` with an `X-Api-Key` header and sends no idempotency header. `ops/README.md` says the vendor is invented, so there is no real endpoint, sandbox or contact to call from here. These must be answered by whoever owns the PayEx contract:

1. Does `POST /v2/payments` accept a client-supplied idempotency key (header or body field)? What does a replay with the same key and the same body return? With the same key and a different body?
2. How long are keys retained, and is that window stated in the contract?
3. Is there a lookup, for example `GET /v2/payments?merchantReference=...`, and how soon after a timed-out submission is it consistent?
4. Does PayEx deduplicate on its own, for example by invoice id, if no key is sent?
5. Is there a sandbox where a 30-second timeout can be forced, so the Unknown path can be tested before January?

Test to run in the sandbox: send one payment with a key, abandon the connection before the response, then replay the same key and also query by reference. Pass means one payment and the same reference both times.

## Consequences

- Approval no longer waits on PayEx, so a 30-second timeout does not block approvers at month end.
- The team runs a worker. That is the main recurring cost, and it falls on a one-week rotation with two new engineers. The mitigation is a one-page runbook whose first line is "Unknown means look up, never reset."
- Estimated Azure cost is about nothing extra (the worker can run on the existing App Service plan, data is a few GB over seven years). Service Bus Standard would add a base fee of roughly ten dollars a month if used. These are the agent's estimates and I have not checked them against the pricing calculator.
- Required alerts: oldest pending age, count and oldest age of Unknown rows, dead-lettered rows, and breaker state.
- A month-end load and failure drill with PayEx stubbed to time out is part of the work, not a follow-up.

## What would make me revisit this

- PayEx has no key and no lookup (see above).
- PayEx's key retention is shorter than our Unknown-resolution SLA.
- The Unknown rate exceeds 1% of submissions in any week (my threshold, not measured), which means the resolver is doing too much of the work.
- Oldest pending age passes 15 minutes more than twice in a month (my threshold), which suggests the worker design is not keeping up.
- The team cannot staff the worker on-call by January. The fallback is A with a scheduled retry job, with the outbox as the target design.
- Volume grows about tenfold, or a second consumer of approval events appears. At that point move the relay to Service Bus.

## Where the agent was wrong or useless

These are specifics from the sessions, not general complaints.

1. **It proposed a risky key in its first answer.** The first comparison defined the key as "invoice ID + submission version". When I asked how this fails at 3 a.m., the same agent named a key derived from mutable fields or an attempt counter as a cause of double payment. The first answer set up the hazard that the second warned about. I replaced it with a key minted once from the invoice id and approval id.
2. **The first answer left out the lease.** It described a worker that "polls with row locking" and nothing about a lease, a heartbeat, or not holding the transaction over the 30-second call. The 3 a.m. pass found that a worker dying mid-call leaves rows stuck InFlight, or blocks SQL if the transaction is held. Rules 3 and 4 come from that second pass, not from the first.
3. **The preference probe did not move the recommendation, which is right, but it blurred the options.** The probe stated a preference for C (written by me on your behalf, so replace it with your real preference if it differs). The agent held its position and listed where the engineer was right. It then offered a "compromise": write the intent row and key in the approval transaction, submit inline, mark timeouts Unknown, and sweep them. That is B with the worker removed, so it let C look like a smaller version of B. I did not take it, and I would not have noticed without comparing it to the option table.
4. **The cost estimates mix scopes.** Option A was 3 to 6 days and C was 6 to 10 days, but C's range includes the inline PayEx call and A's does not, so they are not comparable. The agent also produced figures such as a 0.1% unknown rate and 1 to 3 hours per recovery with no basis. It flagged them as guesses, but guesses still end up in the table above. Treat every cost figure as an order of magnitude.
5. **It could not answer the question the whole design hangs on.** Whether PayEx honours keys or supports lookup is not in the repository. Every answer said "confirm with PayEx". That is correct, and it is also the part that I needed help with and did not get. The agent cannot replace a call to the vendor or a test against the sandbox.
6. **The 3 a.m. answer was too tidy.** Five scenarios, each with a clean "wrong action, right action, build beforehand" shape. Real incidents are messier: two of these happen at once, and the on-call person has no runbook yet. I used it as a checklist, and I would not treat it as a forecast.
7. **It cited no evidence from this repo.** Neither the INC-2041 socket exhaustion nor the INC-2047 filter failure came up until I brought them in. An agent that had read `ops/incidents` would have said that this team has already had an unbounded HTTP client and a silent topic filter. The sessions ran with no file access, so that was my setup choice as much as the agent's gap.
