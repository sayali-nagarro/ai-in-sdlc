# Risk audit: the agent setup against the lethal trifecta

The lethal trifecta is an agent that has all three of: (1) access to private data, (2) exposure to untrusted content, and (3) a way to send data out. With all three, an instruction hidden in untrusted content can make the agent read something private and send it out.

## Decision

Date: 2026-10-24. Owner: the service owner. Status: partly implemented; isolation not demonstrated.

1. **Target design: remove legs 1 and 3 from the browser session.** It must use a throwaway checkout with no credentials or private data and network egress limited to the app. This isolation is not currently demonstrated.
2. **The coding/incident-session risk acceptance is conditional, not verified.** It assumes no browser tool and no shell egress except the model endpoint, with developer approval for shell commands. Repository files do not establish that each developer's local tool settings enforce these conditions. The triggers that reopen this decision are listed under "Accepted risk, in writing".
3. **Implemented as defense-in-depth only:** `.mcp.json` pins `@playwright/mcp@0.0.83` and adds `--isolated` and `--allowed-origins=http://localhost:5000`. The upstream documentation says the origin allow-list is not a security boundary.
4. **Not demonstrated:** the actual Playwright MCP command launches `npx` on the host. `tools/browser-sandbox/compose.yaml` defines an internal network for the app service only; it does not launch or attach the MCP server to that network. On 2026-10-31, `docker network inspect invoice-browser-sandbox` could not connect to the local Docker daemon, so no egress probe was completed. The egress script is not a successful verification result. Until the MCP browser is actually isolated and tested, it retains an outbound path and must not be used in a session that can see secrets. This must be in place before production go-live (revisit trigger 6).

## What was audited

`ops/README.md` has no agent-setup section (it ends at "No answers here"). With your agreement I audited the agent configuration that is actually in the repository:

- [.mcp.json](../../.mcp.json): the Playwright MCP server, which controls a browser.
- [tools/browser-sandbox/compose.yaml](../../tools/browser-sandbox/compose.yaml): an internal Docker network containing the app service only; it is not wired to the MCP server launch.
- [AGENTS.md](../../AGENTS.md) and [CLAUDE.md](../../CLAUDE.md): instructions the agent reads. They are advice, not enforcement.
- There is no permissions file in the repository (no `.claude/`, no `.vscode/`), so the shell, file and network permissions are whatever each developer's tool defaults to.
- The configured remote is `git@github.com:sayali-nagarro/ai-in-sdlc.git`; a developer machine with the corresponding SSH key can usually push.

## The three legs

| Leg | Present? | Evidence |
| --- | --- | --- |
| 1. Private data | **Yes, and growing** | The agent runs as the developer. It can reach the developer's environment variables, SSH key for the Git remote, and any cloud login on that machine. Today the repository holds only demo credentials (`appsettings.json:9-12`). From January it will hold or touch a PayEx key, a SQL connection string, and incident logs with customer data |
| 2. Untrusted content | **Yes** | The browser tool can open any page. The web UI also shows `CustomerName`, which any user who can create an invoice controls (`InvoicesController.cs:48-66`), so an agent driving the UI reads attacker-written text. Pull request text and incident logs are also written by others |
| 3. Outbound path | **Yes** | The browser can navigate to origins and submit forms; the host-launched MCP process is not attached to the internal Docker network. The shell can run `curl` and `git push`. The origin allow-list is not a network boundary |

All three legs are present in one session. That is the finding.

## One thing I checked that changes the design

I expected to remove the outbound leg with the Playwright origin allow-list. The upstream README says otherwise: `--allowed-origins` "does not serve as a security boundary and does not affect redirects", and "Playwright MCP is not a security boundary" (github.com/microsoft/playwright-mcp, Configuration and Security sections). So the allow-list is a seatbelt, not a wall. The wall has to be somewhere else.

## Redesign: remove legs by splitting the sessions

The target rule: no single session gets more than two legs. The table describes the intended design, not a verified property of the current setup.

| Session | Leg 1 private data | Leg 2 untrusted content | Leg 3 outbound |
| --- | --- | --- | --- |
| **Browser / e2e session** (target) | To be removed: throwaway checkout, no SSH agent, no cloud login, no secrets in the environment | Present: pages and invoice text | To be removed at the network layer: MCP must run in a container or VM restricted to the app. No shell tool and no `git push` in this session. Not yet wired or verified |
| **Coding / incident session** (target) | Present | Present: reads PRs and logs | Intended to be removed for browsing; local tool permissions and shell egress are not verified by repository artifacts |

Done now in this repository:

- [.mcp.json](../../.mcp.json) pins `@playwright/mcp@0.0.83` (the version the registry reported as latest today, checked with `npm view`), adds `--isolated` so no profile is kept on disk, and adds `--allowed-origins=http://localhost:5000` as a second layer.

Not done or demonstrated:

- The container or VM egress rule wired to the actual Playwright MCP process, making it unable to reach anything but the app. The existing Compose file only defines the app service. Without this wiring and a recorded verification, the browser session still has leg 3 and the redesign is incomplete. This is the item that matters most.
- Per-developer tool settings that disable auto-approval of shell and network commands.

## Accepted risk, in writing

The coding and incident session is intended to keep legs 1 and 2: it must read untrusted text (pull requests, logs) while able to see private data. This risk acceptance is conditional on leg 3 being removed by local tool controls and developer approval for shell commands. Those controls have not been verified from repository evidence, so this audit does not claim the outbound path is currently removed.

I will revisit this when **any** of these happens:

1. A real secret (PayEx key, SQL connection string, a production token) is present in a developer environment or the repository where an agent session can read it.
2. An agent session is given read access to production logs or customer data. The [autonomy policy](../policy/incident-first-response-autonomy.md) requires redaction first.
3. Auto-approval of shell or network commands is turned on for any agent.
4. Any new MCP server or tool is added to `.mcp.json`, or the Playwright MCP version changes.
5. A security advisory is published for the Playwright MCP server or the agent tool in use.
6. The egress rule for the browser session is not in place by the production date in January.

Accountable owner: the service owner (individual not named in this repository). Review date: before production go-live and whenever a listed trigger occurs.

## What this audit did not do

- It did not test the setup with a real injection attempt. Doing so would be the strongest evidence that the split holds.
- It did not inspect any developer's local tool settings.
- An internal Docker network and egress-check script exist, but the MCP process is not attached to that network and no successful verification output is recorded. Egress isolation is therefore not enforced/demonstrated by the current repository setup.
