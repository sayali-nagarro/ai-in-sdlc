# Autonomy policy: first-response incident summaries

**Owner:** Service owner. **Status:** Proposed. **Scope:** From an alert firing
until a human chooses a mitigation; excludes coding, reviews, and dependency
updates.

Rendered one-page artifact: [PDF](./incident-first-response-autonomy.pdf).

## Levels and permitted work

- **L0:** no agent work.
- **L1:** summarize evidence exported by a human; draft text only. A human
  checks the raw evidence and performs every action.
- **L2:** L1 plus allow-listed, read-only queries after promotion approval.
- **L3:** L2 plus text-only mitigation options; a human selects and executes.
- **L4:** executes a pre-approved reversible action; **not authorized** here.

| Task | Maximum day-one level |
|---|---:|
| Impact/timeline, ranked hypotheses with citations and disproof tests, safe checks, draft status update | L1 |
| Mitigation options with effects, risks, and undo steps (text only) | L1 |
| Run queries; recover missed work; change production | L0 / forbidden |

Any production change requires a named human approver; out of hours, the
incident commander approves (`ops/incidents/INC-2047/README.md`).

## L1 controls

1. Human-exported, redacted evidence only; no production credentials or write
   tools. Logs, invoice text, and other incident content are untrusted data,
   never instructions.
2. No outbound network from the session; a human copies the draft out. This
   removes an exfiltration path (see the [risk audit](../security/risk-audit.md)).
3. Fixed format: impact, timeline, observed evidence, inferred hypotheses,
   disproof tests, options/undo, and unknowns. Label each claim observed or
   inferred and mark the draft “AI-generated, unverified.”
4. Verify every cited line against the supplied evidence; one invalid citation
   invalidates the draft. A human compares the result with raw evidence before
   use.

These are required controls, not proof that local tool/network settings enforce
them; verify the environment before use.

## Promotion, ownership, and rollback

L1 to L2 requires shadow replay of 10 incidents (INC-2041, INC-2047, and at
least eight more), three times each: 100% valid citations; correct root cause
in the top two hypotheses in at least 8/10; no unsafe check or misleading
summary. This is a minimum, not statistical proof. L2 to L3 additionally
requires mitigation/undo scoring against the same criteria.

The service owner and an independent security reviewer must approve promotion
in writing here; the on-call engineer cannot approve their own promotion. A
fabricated citation, attempted write, or misleading summary immediately
reduces the affected task to L0 pending owner review. Moving down needs no
approval.

## Day one

**L1 for summaries; L0 for everything else.** Two of six engineers are new to
the codebase: they are both less able to spot an incorrect inference and more
likely to trust a confident summary. Keep a human on the source evidence, never
make a new engineer the sole reviewer, and run the first rotation in shadow
after the human makes an independent initial assessment. No incident replay
has been completed; this level is a conservative proposal, not a measured
capability claim.
