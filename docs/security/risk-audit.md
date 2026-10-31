# Risk audit: the agent setup against the lethal trifecta

The lethal trifecta is an agent that has all three of: (1) access to private data, (2) exposure to untrusted content, and (3) a way to send data out. With all three, an instruction hidden in untrusted content can make the agent read something private and send it out.

## Decision

Date: 2026-10-24. Owner: the service owner. Status: partly implemented.

1. **Redesign the browser session to remove legs 1 and 3.** The Playwright MCP session runs with no credentials and no private data, and with network egress limited to the app on `localhost:5000`. No other session gets a browser tool.
2. **Accept legs 1 and 2 in the coding and incident session**, in writing, because leg 3 is removed there (no browser, shell network off except the model endpoint) and each shell command is approved by the developer. The triggers that reopen this decision are listed under "Accepted risk, in writing".
3. **Done now:** `.mcp.json` pins `@playwright/mcp@0.0.83`, adds `--isolated` and `--allowed-origins=http://localhost:5000`.
4. **Not done:** the container or VM egress rule. Until it exists, the browser session still has leg 3, so the redesign is incomplete and the browser tool should not be used in a session that can see secrets. This must be in place before the January go-live (revisit trigger 6).

## What was audited

`ops/README.md` has no agent-setup section (it ends at "No answers here"). With your agreement I audited the agent configuration that is actually in the repository:

- [.mcp.json](../../.mcp.json): the Playwright MCP server, which controls a browser.
- [AGENTS.md](../../AGENTS.md) and [CLAUDE.md](../../CLAUDE.md): instructions the agent reads. They are advice, not enforcement.
- There is no permissions file in the repository (no `.claude/`, no `.vscode/`), so the shell, file and network permissions are whatever each developer's tool defaults to.
- The remote is `git@github.com:NITIN1670/ai-in-sdlc-assignment.git`, so a developer machine that can pull can usually push.

## The three legs

| Leg | Present? | Evidence |
| --- | --- | --- |
| 1. Private data | **Yes, and growing** | The agent runs as the developer. It can reach the developer's environment variables, SSH key for the Git remote, and any cloud login on that machine. Today the repository holds only demo credentials (`appsettings.json:9-12`). From January it will hold or touch a PayEx key, a SQL connection string, and incident logs with customer data |
| 2. Untrusted content | **Yes** | The browser tool can open any page. The web UI also shows `CustomerName`, which any user who can create an invoice controls (`InvoicesController.cs:48-66`), so an agent driving the UI reads attacker-written text. Pull request text and incident logs are also written by others |
| 3. Outbound path | **Yes** | The browser can navigate to any origin and submit forms. The shell can run `curl` and `git push`. `@playwright/mcp@latest` was also unpinned, so a new release would run on the next start with no review |

All three legs are present in one session. That is the finding.

## One thing I checked that changes the design

I expected to remove the outbound leg with the Playwright origin allow-list. The upstream README says otherwise: `--allowed-origins` "does not serve as a security boundary and does not affect redirects", and "Playwright MCP is not a security boundary" (github.com/microsoft/playwright-mcp, Configuration and Security sections). So the allow-list is a seatbelt, not a wall. The wall has to be somewhere else.

## Redesign: remove legs by splitting the sessions

The rule: no single session gets more than two legs.

| Session | Leg 1 private data | Leg 2 untrusted content | Leg 3 outbound |
| --- | --- | --- | --- |
| **Browser / e2e session** (Playwright MCP) | **Removed**: throwaway checkout, no SSH agent, no cloud login, no secrets in the environment | Present: pages and invoice text | **Removed at the network layer**: runs in a container or VM whose only reachable address is the app on `localhost:5000`. No shell tool and no `git push` in this session |
| **Coding / incident session** | Present | Present: reads PRs and logs | Removed for the browser (no browser tool). Shell network is off except the model endpoint |

Done now in this repository:

- [.mcp.json](../../.mcp.json) pins `@playwright/mcp@0.0.83` (the version the registry reported as latest today, checked with `npm view`), adds `--isolated` so no profile is kept on disk, and adds `--allowed-origins=http://localhost:5000` as a second layer.

Not done, because it lives outside the repository and needs your decision:

- The container or VM egress rule that makes the browser session unable to reach anything but the app. Without it, the browser session still has leg 3 and the redesign is incomplete. This is the item that matters most.
- Per-developer tool settings that disable auto-approval of shell and network commands.

## Accepted risk, in writing

The coding and incident session keeps legs 1 and 2: it must read untrusted text (pull requests, logs) while able to see private data. I accept this, because the agent cannot send data out (leg 3 removed) and every shell command is approved by the developer.

I will revisit this when **any** of these happens:

1. A real secret (PayEx key, SQL connection string, a production token) is present in a developer environment or the repository where an agent session can read it.
2. An agent session is given read access to production logs or customer data. The [autonomy policy](../policy/incident-first-response-autonomy.md) requires redaction first.
3. Auto-approval of shell or network commands is turned on for any agent.
4. Any new MCP server or tool is added to `.mcp.json`, or the Playwright MCP version changes.
5. A security advisory is published for the Playwright MCP server or the agent tool in use.
6. The egress rule for the browser session is not in place by the production date in January.

Owner: the service owner. Review date: before the January go-live.

## What this audit did not do

- It did not test the setup with a real injection attempt. Doing so would be the strongest evidence that the split holds.
- It did not inspect any developer's local tool settings.
- The container egress rule is described, not built.
