# AI augmentation log

A record of where AI was used to produce the assignment deliverables, what it was given, what was kept, and how it was checked. Complete raw transcripts are not retained here; availability in original VS Code sessions or debug folders was not independently verified. Historical and verification machine-readable entries are in [ai-augmentation-log.jsonl](ai-augmentation-log.jsonl) and [ai-augmentation-verification.jsonl](ai-augmentation-verification.jsonl). The JSONL records are human-curated from available conversation and tool evidence, not automatically captured telemetry; missing details are marked as unavailable rather than reconstructed.

## Tools and models

- Main agent: GitHub Copilot in VS Code. Earlier handwritten notes name Claude Sonnet 5.5, but retained evidence does not independently verify that model identity. The exact model for this verification session was not exposed.
- Sub-agents: Earlier notes report 79 stateless sessions (3 exploration, 72 review-eval, 4 decision-record). Transcripts and per-agent model identifiers are not retained, so those counts and identities are not independently verifiable.
- Not used in this verification: the Mermaid MCP. The .NET 8.0.427 SDK was installed temporarily under `/tmp/dotnet` to run the architecture test.
- Automatic prompt/tool telemetry: not available through the interfaces exposed for this task. The current-turn entry records the user request and available actions, but is not a complete IDE event trace.

## Log

| # | Task | AI use | Input given | Kept | How it was checked | Result |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Understand the repo and evidence | 3 exploration sub-agents (incident packs; pipeline, evals, use cases and e2e; backend code gaps) | Read-only access to the repo | Overall picture, incident timelines, list of production gaps | I re-read the code and several evidence files myself | Several claims were wrong (see "Errors found") |
| 2 | As-built diagrams | I read `Program.cs`, controllers, `Auth/`, `ApprovalService`, repository and wrote the Mermaid and citations | The source files | Both diagrams, citation table, "Inferred" list | Line numbers re-checked; the prior visual-only check was superseded by a fresh Mermaid CLI 11.4.2 render on 2026-10-31. Exact commands are in the final verification report | All three canonical sources rendered successfully and their PNGs were refreshed; the initial syntax check by eye was not a render validation |
| 3 | Target-state diagram | Drafted by me from the brief and `ops/` | Brief, `servicebus-status.txt`, INC-2041 diff | Diagram, citations, "Inferred or proposed" list | Topic and subscription names confirmed with a search | Table and class names are my proposals |
| 4 | Architecture test | Written by me | `AGENTS.md` rule, test project layout | `ArchitectureTests.cs` | Editor reports no errors; later run with the documented command | **Ran and passed** (1 test; full suite 8 of 8). Failure case demonstrated by temporarily adding an ASP.NET Core reference to Domain: the test failed, then the change was reverted and the suite passed again |
| 5 | Review eval: truth key | Written by me; the sub-agent's earlier labels were not trusted | The 10 case diffs, repo conventions | Key for 12 cases, scoring rules fixed before the runs | Re-derived each case | Case 09 left as ambiguous |
| 6 | Review eval: 2 added cases | I first wrote `case-11.diff` and `case-12.diff` from the INC-2041 evidence; the owner then replaced both with real changes (a clean `Reject` validation with tests, and a defective `Approve` that calls PayEx after committing) | INC-2041 diff and repo rules, then the owner's diffs | The owner's two cases | The 12 affected review runs were repeated on the new cases | My earlier cases are discarded. New labels (11 clean, 12 defect) were assigned by me |
| 7 | Review eval: runs | Earlier notes report 72 sub-agent reviews (12 cases x 3 runs x 2 prompts), diff passed inline, no tools allowed; raw transcripts are not retained | Diff plus the prompt | Recorded verdict rows in `results.csv`, scored against the key | Scored against the key; no run-by-run transcripts or metadata for independent audit | The CSV records 24/24 defects caught under both prompts and no false alarms on labeled clean cases; historical execution is not independently verifiable |
| 8 | Decision record | 4 sub-agent sessions: option trade-offs, then three stress tests | A written brief of the scenario | Option table, failure scenarios, cost ranges (flagged as guesses) | Cross-checked arithmetic (40 calls in flight, 24,000 invoices in the last three days) | Draft; the owner must review it |
| 9 | Decision record: "Where the agent was wrong or useless" | Written by me from what the sessions actually produced | The four outputs | Seven specific items | Each tied to text in an output | The "prefer C" probe was written by me, not the owner |
| 10 | Autonomy policy | Written by me | INC-2041 and INC-2047 README constraints | Levels, tasks, controls, promotion evidence, day-one level | Constraints quoted from the packs | No replay has been run |
| 11 | Risk audit | Written by me; web fetch of the Playwright MCP README; registry query for the version | `.mcp.json`, `AGENTS.md`, upstream docs | Legs table, decision, accepted risk | Confirmed upstream says the allow-list is not a security boundary | `.mcp.json` edited (pinned version, `--isolated`, `--allowed-origins`) |
| 12 | Measurement baseline | Python script over the CI timings; `git log`; `gh auth status` | `run-timings.csv`, git history | CI duration figures, release and incident count | Script output read directly | `gh` token invalid, so review turnaround and real lead time not captured |
| 13 | Handover documentation close-out | Read repository handover files, corrected stale claims, and added a checklist and JSONL session record | Existing assignment artifacts and the handover requirements | Evaluation three-plus-one comparison, updated case guidance, evidence caveats, risk-status correction, and checklist | Searched for stale wording; parsed JSONL; reviewed relevant files; fresh focused architecture test output retained at `architecture/architecture-test-output.txt` | Focused architecture test passed 1/1 in the current verification; historical evaluation provenance remains incomplete. The demo video remains outstanding; no transcript or video URL was supplied |
| 14 | Final evidence verification | Read and updated existing deliverables; ran the focused architecture test; rendered all three Mermaid sources; audited citation IDs | Continuation request and repository evidence | Corrected citation anchors; refreshed PNGs; retained test output; added the final verification report | `dotnet test ... --filter FullyQualifiedName~ArchitectureTests`; Mermaid CLI 11.4.2 rendering; Python source-ID audit; Swift/AppKit Markdown layout | Test passed 1/1; all diagram IDs had register coverage, all diagrams rendered, and all policy Markdown glyphs fit in the measured content area. Evaluation runs were not repeated; model identity for this session was not exposed. The JSONL addendum records commands and limits |
| 15 | Improve AI-use traceability | Built-in Copilot assistant updated the structured and readable logs in response to the owner's requested fields | Owner requested tool/model, agent/mode, prompts, skills/sub-agents, integrations, actions, human review, execution evidence, outcome, and more automation | Added a per-interaction JSONL record with the request, known session and timestamp context, tools, changed files, human oversight, verification and explicit unknowns; linked it from README and checklist | Parsed JSONL, checked required provenance fields and local links, and ran `git diff --check`; details/results are in the JSONL entry | Log-format improvements applied. Tool-provided automatic telemetry and exact model/mode identity are unavailable; no historical prompts, outputs, or model identities were backfilled |
| 16 | Clarify exactly-once decision record | Copilot assistant revised the ADR after the owner asked to make the necessary changes | Owner asked whether the assignment requirement was done, then requested the required changes | Clarified that the option-C preference was a hypothetical stress-test prompt, not the owner's stated preference; recorded B with A as the assignment recommendation, added a comparative qualitative run-cost row, and aligned the handover checklist | Re-read the ADR and checklist, then reviewed the resulting documentation diff | The record now transparently covers the requested comparison, challenge, failure scenario, build/run costs, revisit triggers, and agent shortcomings. PayEx contract verification and production approval remain outstanding; no vendor or sandbox evidence was invented |
| 16 | Render autonomy policy page artifact | Built-in Copilot assistant converted the policy Markdown to a temporary HTML layout and PDF | Owner asked for a retained PDF/page-count artifact rather than relying only on Markdown layout fit | [One-page policy PDF](policy/incident-first-response-autonomy.pdf); links in the Markdown policy, README, handover checklist and final verification report | PDFKit reported exactly one page; extracted text contained the Day one section and new-engineer rationale; Quick Look thumbnail was visually inspected | Complete; PDF retained. Rendering used a temporary HTML file and inline conversion script, which were not retained as source tooling |

## Errors found in AI output

Corrections I made after checking against the code or the evidence files:

- The exploration pass put `FakeInvoiceRepository` under `backend/src`. It is under `backend/tests`.
- It cited `Program.cs:10` for the demo users. It is line 12.
- It called `MidpointRounding.ToZero` banker's rounding. It truncates.
- It said the repository used `ConcurrentDictionary`. That comes from the eval diffs, and the real repository is a `List<Invoice>` with a `lock`.
- It said the CI pipeline takes 35 to 42 minutes. The 31.3-minute figure in the `ops/` timings file is invented scenario data, not this repository's CI measurement; the actual small-sample GitHub Actions observations are recorded in [the measurement baseline](measurement/baseline.md).
- It labelled INC-2041's cause as definite. I re-read the deploy diff and the log lines, and the per-request `HttpClient` and the 100-second timeout are confirmed.
- INC-2047's cause (an event-type rename dropped by a subscription filter) rests on the sub-agent summary, the release notes in `recent-changes.md`, and the subscription message counts. I did not re-read the filter rule text myself.
- My own mistakes: seven citation line numbers were off by one; a release date in the baseline was wrong (2026-01-13 instead of 2026-01-14); and the decision record first wrote the probe as if the owner had stated it.

## Things the AI did not do

- The prior assignment sessions did not render the Mermaid diagrams; this verification rendered all three.
- It did not call PayEx or confirm whether PayEx supports idempotency keys or lookup.
- It did not replay the incident packs under the autonomy policy.
- It did not build the browser-session egress restriction in the risk audit.
- It did not run the GitHub commands listed in the baseline.
- It did not rerun or independently reproduce the historical model evaluations.
- Earlier notes name GPT-6 Luna and Claude Sonnet 5.5, but neither identity is independently verified by retained runtime evidence.

## What the owner must still do

- Review and edit the decision record, and replace the probe and sessions with your own if you ran them.
- Confirm the PayEx assumptions with the vendor.
- Record the 8–10-minute demo video, upload it, and replace the TODO link in the README and demo script.
- Review the handover checklist and provide the outstanding owner approvals and verification evidence.
- The current verification's session ID and test-start timestamp are retained in [the verification JSONL addendum](ai-augmentation-verification.jsonl). The current model identity and verbatim prompt/output transcript were not exposed or captured.
- The PDF is a generated presentation artifact from the policy Markdown; make future policy edits in Markdown, then regenerate and recheck the PDF.
