# AI augmentation log

A record of where AI was used to produce the assignment deliverables, what it was given, what was kept, and how it was checked. Written from the working session. The raw transcripts are in the VS Code chat session and its debug log folder, and are not copied here. A machine-readable session entry is maintained in [ai-augmentation-log.jsonl](ai-augmentation-log.jsonl); it records only evidence available for that session and labels missing historical details as not captured.

## Tools and models

- Main agent: GitHub Copilot in VS Code (Claude Sonnet 5.5), with file, terminal, web-fetch and sub-agent tools.
- Sub-agents: 79 stateless sessions launched by the main agent, using the session's default model (not recorded separately). 3 for exploration, 72 for the review eval, 4 for the decision record.
- Not used: the Mermaid MCP (not available in this session). The .NET SDK was installed user-local (`~/.dotnet`) part-way through, so the architecture test could be run.

## Log

| # | Task | AI use | Input given | Kept | How it was checked | Result |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Understand the repo and evidence | 3 exploration sub-agents (incident packs; pipeline, evals, use cases and e2e; backend code gaps) | Read-only access to the repo | Overall picture, incident timelines, list of production gaps | I re-read the code and several evidence files myself | Several claims were wrong (see "Errors found") |
| 2 | As-built diagrams | I read `Program.cs`, controllers, `Auth/`, `ApprovalService`, repository and wrote the Mermaid and citations | The source files | Both diagrams, citation table, "Inferred" list | Line numbers re-checked with a search; 7 were off by one and were fixed | Initial log says diagrams were not rendered and syntax was checked by eye. PNGs are now present in `docs/architecture/diagrams/`, but their render date and command provenance were not recorded; do not claim the initial check itself was a render validation |
| 3 | Target-state diagram | Drafted by me from the brief and `ops/` | Brief, `servicebus-status.txt`, INC-2041 diff | Diagram, citations, "Inferred or proposed" list | Topic and subscription names confirmed with a search | Table and class names are my proposals |
| 4 | Architecture test | Written by me | `AGENTS.md` rule, test project layout | `ArchitectureTests.cs` | Editor reports no errors; later run with the documented command | **Ran and passed** (1 test; full suite 8 of 8). Failure case demonstrated by temporarily adding an ASP.NET Core reference to Domain: the test failed, then the change was reverted and the suite passed again |
| 5 | Review eval: truth key | Written by me; the sub-agent's earlier labels were not trusted | The 10 case diffs, repo conventions | Key for 12 cases, scoring rules fixed before the runs | Re-derived each case | Case 09 left as ambiguous |
| 6 | Review eval: 2 added cases | I first wrote `case-11.diff` and `case-12.diff` from the INC-2041 evidence; the owner then replaced both with real changes (a clean `Reject` validation with tests, and a defective `Approve` that calls PayEx after committing) | INC-2041 diff and repo rules, then the owner's diffs | The owner's two cases | The 12 affected review runs were repeated on the new cases | My earlier cases are discarded. New labels (11 clean, 12 defect) were assigned by me |
| 7 | Review eval: runs | 72 sub-agent reviews (12 cases x 3 runs x 2 prompts), diff passed inline, no tools allowed | Diff plus the prompt | All outputs, scored by me | Scored against the key | 24/24 defects caught under both prompts; no false alarms under either (9/9 clean cases correct each) |
| 8 | Decision record | 4 sub-agent sessions: option trade-offs, then three stress tests | A written brief of the scenario | Option table, failure scenarios, cost ranges (flagged as guesses) | Cross-checked arithmetic (40 calls in flight, 24,000 invoices in the last three days) | Draft; the owner must review it |
| 9 | Decision record: "Where the agent was wrong or useless" | Written by me from what the sessions actually produced | The four outputs | Seven specific items | Each tied to text in an output | The "prefer C" probe was written by me, not the owner |
| 10 | Autonomy policy | Written by me | INC-2041 and INC-2047 README constraints | Levels, tasks, controls, promotion evidence, day-one level | Constraints quoted from the packs | No replay has been run |
| 11 | Risk audit | Written by me; web fetch of the Playwright MCP README; registry query for the version | `.mcp.json`, `AGENTS.md`, upstream docs | Legs table, decision, accepted risk | Confirmed upstream says the allow-list is not a security boundary | `.mcp.json` edited (pinned version, `--isolated`, `--allowed-origins`) |
| 12 | Measurement baseline | Python script over the CI timings; `git log`; `gh auth status` | `run-timings.csv`, git history | CI duration figures, release and incident count | Script output read directly | `gh` token invalid, so review turnaround and real lead time not captured |
| 13 | Handover documentation close-out | Read repository handover files, corrected stale claims, and added a checklist and JSONL session record | Existing assignment artifacts and the handover requirements | Evaluation three-plus-one comparison, updated case guidance, evidence caveats, risk-status correction, and checklist | Searched for stale wording; parsed JSONL; reviewed the relevant paths; architecture test run recorded in `ai-augmentation-log.jsonl` | Architecture test passed 1/1 on 2026-10-31. The demo video remains outstanding; no transcript or video URL was supplied |

## Errors found in AI output

Corrections I made after checking against the code or the evidence files:

- The exploration pass put `FakeInvoiceRepository` under `backend/src`. It is under `backend/tests`.
- It cited `Program.cs:10` for the demo users. It is line 12.
- It called `MidpointRounding.ToZero` banker's rounding. It truncates.
- It said the repository used `ConcurrentDictionary`. That comes from the eval diffs, and the real repository is a `List<Invoice>` with a `lock`.
- It said the CI pipeline takes 35 to 42 minutes. The timings file gives a mean of 31.3 minutes.
- It labelled INC-2041's cause as definite. I re-read the deploy diff and the log lines, and the per-request `HttpClient` and the 100-second timeout are confirmed.
- INC-2047's cause (an event-type rename dropped by a subscription filter) rests on the sub-agent summary, the release notes in `recent-changes.md`, and the subscription message counts. I did not re-read the filter rule text myself.
- My own mistakes: seven citation line numbers were off by one; a release date in the baseline was wrong (2026-01-13 instead of 2026-01-14); and the decision record first wrote the probe as if the owner had stated it.

## Things the AI did not do

- It did not render the Mermaid diagrams.
- It did not call PayEx or confirm whether PayEx supports idempotency keys or lookup.
- It did not replay the incident packs under the autonomy policy.
- It did not build the browser-session egress restriction in the risk audit.
- It did not run the GitHub commands listed in the baseline.

## What the owner must still do

- Review and edit the decision record, and replace the probe and sessions with your own if you ran them.
- Confirm the PayEx assumptions with the vendor.
- Record the 8–10-minute demo video, upload it, and replace the TODO link in the README and demo script.
- Review the handover checklist and provide the outstanding owner approvals and verification evidence.
