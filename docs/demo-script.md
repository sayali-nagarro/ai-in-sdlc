# Demo video script (8 to 10 minutes)

Link: **TODO: record, upload, and paste the URL here and in the README.**

Record the screen with your voice. Keep every claim tied to a file on screen. Timings are targets.

| Time | Show | Say |
| --- | --- | --- |
| 0:00 to 0:45 | `ops/README.md`, then the repo tree | The scenario: tier-2 service in January, PayEx integration, six engineers. The rule: `ops/` describes a planned system, not the code |
| 0:45 to 2:15 | `docs/architecture/as-built.md`: both diagrams, the citation table, the "Inferred" list, then the "Corrections" list | What exists today. Show one citation opened in the source. Show two corrections the agent got wrong |
| 2:15 to 3:00 | `docs/architecture/target-state.md` | Green exists, red does not. Point at the inferred-items list |
| 3:00 to 4:00 | Terminal: `dotnet test backend/InvoiceApp.sln --filter ArchitectureTests`, then `ArchitectureTests.cs` | The rule, the command, the pass. Then show the failure: add the ASP.NET Core reference and the `HttpContext` property described in `as-built.md`, rerun to show the red result, and revert. Run `export PATH="$HOME/.dotnet:$PATH"` first |
| 4:00 to 6:00 | `docs/adr/0001-exactly-once-payex-submission.md`: options table, decision, rules, revisit triggers, then "Where the agent was wrong or useless" | Why outbox plus key, why a timeout is Unknown, and the PayEx assumption that decides everything. Read two of the seven agent errors aloud |
| 6:00 to 7:15 | `docs/eval/review-eval.md` and `ops/evals/results.csv` | Show the selected three-run baseline plus the separate changed-prompt run, then note that the full dataset has 72 rows. Both full prompt conditions caught 24/24 defects with zero false alarms; v2 suppressed the ambiguous case-09 README finding in one run. Explain why the result is "not demonstrably better", the ceiling, and the context leak |
| 7:15 to 8:15 | `docs/policy/incident-first-response-autonomy.md` | Levels, the forbidden list, the evidence to move up, and the day-one level: L1, because two engineers are new |
| 8:15 to 9:15 | `docs/security/risk-audit.md` and `docs/measurement/baseline.md` | Explain the risk decision and that browser egress isolation is not yet demonstrated: the MCP server launches on the host, while the internal Compose network currently defines only the app. Then the two captured numbers: median 31.3 minutes, at most 33% |
| 9:15 to 10:00 | `docs/ai-augmentation-log.md` | What the AI did, what it got wrong, what is still open |

## Things to say plainly in the video

- The incident, CI and release figures are the scenario's invented data.
- `case-11` (clean) and `case-12` (defect) are real changes you supplied. The labels are mine, and nothing independent confirms them.
- The decision record was drafted with an agent. Say which parts you changed.
- The Mermaid MCP was not used. Diagram PNGs are present in `docs/architecture/diagrams/`; the render date and command provenance were not recorded.
- The final evaluation reports zero false alarms; the ambiguous case-09 finding was withheld once by v2 and is not counted as a false alarm.
- Scenario pipeline and release figures are invented/planned data, not production measurements. The separate real CI observation is one 31-second run.
