# Invoice Approval Service — Repository Investigation

**Review date:** 2026-10-31
**Scope:** Repository source, project configuration, tests, CI files, architecture documents, and the complete tracked `ops/` tree.
**Change boundary:** Investigation only. No application source or dependency manifests were changed.

## Evidence conventions

- **AS-BUILT** means directly supported by the checked-in application source.
- **TARGET STATE** means a proposal or deployment scenario described in `ops/` or architecture documents. It is not evidence that the feature runs in this application.
- **INFERRED** marks a conclusion from source structure or missing evidence, not a directly specified runtime guarantee.
- `ops/README.md` says its names, hosts, and figures are invented and that the deployment scenario's database, message topic, and PayEx integration are not in the code ([ops README](../../ops/README.md#L17), [ops README](../../ops/README.md#L22)).

## A. Executive summary

The checked-in application is a .NET 8 ASP.NET Core Web API with a small static browser UI. It has a Domain project containing invoice lifecycle rules, an API project with controllers and sign-in, and an in-memory invoice repository. The API registers that repository and the session store as singletons and serves the static UI from the same web process ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L6), [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L14)).

**No current source implementation was found** for a database, PayEx, Service Bus, notification publisher/worker, append-only audit store, or payment outbox. The target-state document also marks these components as planned/not built ([target-state.md](./target-state.md#L20), [target-state.md](./target-state.md#L22), [target-state.md](./target-state.md#L23)).

The repository describes a larger January deployment scenario, including a 24x7 rotation, database, message topic, and PayEx. That is planning/evidence material, not proof of current functionality ([ops README](../../ops/README.md#L17)). The repository does not specify a measurable published SLO.

The documented backend test command was attempted, but could not execute: `dotnet` is not on PATH and no executable was present at `~/.dotnet/dotnet`. Therefore, this investigation does **not** claim tests pass. No application source was modified.

## B. Existing architecture (AS-BUILT)

| Component | Evidence and what it proves |
|---|---|
| Application entry point | Top-level `Program.cs` creates the ASP.NET Core builder, registers controllers, configures services, builds the app, and calls `Run` ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L6), [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L24)). |
| API and static UI | Controllers are mapped, default files and static files are enabled, and `SessionAuthMiddleware` is registered in the same process ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L19)). Browser files are under `InvoiceApp.Api/wwwroot`; the frontend calls `/api` endpoints ([app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js#L19), [index.html](../../backend/src/InvoiceApp.Api/wwwroot/index.html#L1)). |
| API modules | `InvoicesController` owns invoice list/read/create/submit/delete routes; `ApprovalsController` owns approve/reject routes; `AuthController` owns login/logout ([InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs#L9), [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs#L10), [AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs#L9)). |
| Domain | `Invoice`, `InvoiceStatus`, `IInvoiceRepository`, and `ApprovalService` live in `InvoiceApp.Domain`; the service owns submit/approve/reject rules ([Invoice.cs](../../backend/src/InvoiceApp.Domain/Invoice.cs#L3), [InvoiceStatus.cs](../../backend/src/InvoiceApp.Domain/InvoiceStatus.cs#L3), [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs#L3), [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L7)). |
| Repository boundary | `IInvoiceRepository` is declared in Domain, implemented by `InMemoryInvoiceRepository` in Api, and injected into `ApprovalService` ([IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs#L3), [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L6), [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L9)). |
| Dependency direction | Api references Domain; Domain has no project reference to Api. An architecture test checks that Domain does not reference API/web/storage assemblies ([InvoiceApp.Api.csproj](../../backend/src/InvoiceApp.Api/InvoiceApp.Api.csproj#L8), [ArchitectureTests.cs](../../backend/tests/InvoiceApp.Tests/ArchitectureTests.cs#L7)). |

`DiscountCalculator` is also present in Domain, but it is separate from the approval lifecycle and no caller or DI registration for it was found in the backend source ([DiscountCalculator.cs](../../backend/src/InvoiceApp.Domain/DiscountCalculator.cs#L4), [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L12)).

## C. Approval workflow

The implemented lifecycle is **Draft → PendingApproval → Approved or Rejected** ([InvoiceStatus.cs](../../backend/src/InvoiceApp.Domain/InvoiceStatus.cs#L5), [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L4)).

1. **Create:** `InvoicesController.Create` validates nonblank customer name and amount greater than zero, then adds a new `Invoice`; `Invoice.Status` defaults to `Draft` ([InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs#L48), [Invoice.cs](../../backend/src/InvoiceApp.Domain/Invoice.cs#L8)).
2. **Submit:** `ApprovalService.Submit` only accepts Draft, sets PendingApproval, and calls repository `Update` ([ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L16)).
3. **Approve:** `ApprovalService.Approve` requires PendingApproval, sets Approved, records `DecidedBy` and UTC `DecidedAt`, and calls `Update` ([ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L31)).
4. **Reject:** `ApprovalService.Reject` requires a nonblank reason and PendingApproval, sets Rejected, records decision metadata and `DecisionNote`, and calls `Update` ([ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L43)).

`ApprovalsController` is restricted to Approver or Admin; `InvoicesController.Delete` is restricted to Admin. The middleware requires a valid bearer session for `/api` routes except login, returning 401 without one; the role filter returns 403 when the role does not match ([ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs#L9), [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs#L72), [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs#L19), [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs#L17)).

`ApiControllerBase.Handle` maps `KeyNotFoundException` to 404, `InvalidOperationException` to 409, and `ArgumentException` to 400. It has no general exception catch; other failures are not converted by this helper ([ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs#L9)).

## D. Existing technology and dependencies

- Both application projects target `net8.0`; the API uses `Microsoft.NET.Sdk.Web` and references Domain ([InvoiceApp.Api.csproj](../../backend/src/InvoiceApp.Api/InvoiceApp.Api.csproj#L3), [InvoiceApp.Domain.csproj](../../backend/src/InvoiceApp.Domain/InvoiceApp.Domain.csproj#L3)).
- Neither application project declares a `PackageReference`. The test project references Microsoft.NET.Test.Sdk 17.11.1, xUnit 2.9.2, xunit.runner.visualstudio 2.8.2, and coverlet.collector 6.0.2 ([InvoiceApp.Tests.csproj](../../backend/tests/InvoiceApp.Tests/InvoiceApp.Tests.csproj#L9)).
- The static UI is plain HTML, CSS, and JavaScript. The E2E package declares Playwright Test and Node types ([package.json](../../e2e/package.json#L1)).
- No database driver/ORM, PayEx SDK/client, Service Bus SDK, resilience/retry package, or background-worker package is declared in the application projects.

### Coding conventions

The repository instructions call for one resource controller per `api/[controller]` route, request records inside controllers, use of `ApiControllerBase.Handle`, Domain-owned business rules, `FakeInvoiceRepository` tests, and page-object E2E tests using role/label locators ([AGENTS.md](../../AGENTS.md#L16), [AGENTS.md](../../AGENTS.md#L21), [AGENTS.md](../../AGENTS.md#L23)). `InvoicesController` and `ApprovalsController` follow the `ApiControllerBase` pattern; `AuthController` instead inherits directly from `ControllerBase` ([InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs#L9), [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs#L10), [AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs#L9)).

## E. Existing persistence and integrations

### Persistence

`InMemoryInvoiceRepository` stores invoices in a `List<Invoice>`, protects individual repository operations with a process-local `lock`, seeds five sample invoices, and allocates new invoice IDs in memory ([InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L6), [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L11)). It is the only `IInvoiceRepository` implementation found in `backend/src`, and is registered as a singleton ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L14)).

There are no database contexts, migrations, SQL queries, or database project dependencies in the checked-in application source. `InvoiceApp.Domain` exposes only the repository interface; the current implementation is in-memory.

### Authentication state

Credentials are matched against configured `DemoUsersOptions`; successful sign-in creates an opaque random token held in a `ConcurrentDictionary`-backed `SessionStore`; logout removes the token ([AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs#L24), [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs#L7), [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs#L13)). The session store is registered as a singleton ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L13)). `appsettings.json` contains the demo user records, and the repository documentation labels those as non-real demo credentials ([appsettings.json](../../backend/src/InvoiceApp.Api/appsettings.json#L9), [AGENTS.md](../../AGENTS.md#L31)).

### External integrations and workers

No external HTTP client, PayEx code, messaging publisher/subscriber, hosted service, or worker exists in `backend/src`. `Program.cs` registers the session store, invoice repository, and approval service, then maps the web app and controllers ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L12)).

The incident packs describe those integrations in their planned-deployment scenario. For example, INC-2041's patch describes a PayEx client and its logs show socket/timeout errors; neither establishes that such code is in this checkout ([INC-2041 deploy diff](../../ops/incidents/INC-2041/deploy-diff.patch#L5), [INC-2041 app logs](../../ops/incidents/INC-2041/app-logs.txt#L157)). INC-2047's sample publisher logs switch from `InvoiceApproved` to `invoice.approved`, while the notification subscription rule shown in the pack filters for `InvoiceApproved`; this is an apparent mismatch in scenario evidence, not proof of current application behavior or a definitive incident root cause ([publisher logs](../../ops/incidents/INC-2047/publisher-logs.txt#L6), [publisher logs](../../ops/incidents/INC-2047/publisher-logs.txt#L15), [Service Bus status](../../ops/incidents/INC-2047/servicebus-status.txt#L26), [Service Bus status](../../ops/incidents/INC-2047/servicebus-status.txt#L59)).

## F. Existing testing and CI setup

### Tests

- `ApprovalServiceTests` contains seven xUnit tests for valid transitions, invalid transitions, missing invoices, and rejection reasons ([ApprovalServiceTests.cs](../../backend/tests/InvoiceApp.Tests/ApprovalServiceTests.cs#L6)).
- `ArchitectureTests` contains one test enforcing the Domain dependency boundary ([ArchitectureTests.cs](../../backend/tests/InvoiceApp.Tests/ArchitectureTests.cs#L7)).
- `FakeInvoiceRepository` is the test double; its `Update` method is a no-op ([FakeInvoiceRepository.cs](../../backend/tests/InvoiceApp.Tests/FakeInvoiceRepository.cs#L5)).
- `e2e/tests` and `e2e/pages` contain only `.gitkeep` files in this checkout; there are no checked-in Playwright tests or page objects.

### CI and command status

The checked-in GitHub Actions workflow runs on pushes and pull requests to `main`, sets up .NET 8, then runs Release build and test commands ([ci.yml](../../.github/workflows/ci.yml#L3), [ci.yml](../../.github/workflows/ci.yml#L17)). It does not define deployment, database, external-service, or E2E stages.

`ops/pipeline/ci-pipeline.yml` describes a fuller pipeline with Node/Playwright, scans, container build, and E2E steps; `ops/README.md` says ops material is not part of the application or its tests ([ops CI pipeline](../../ops/pipeline/ci-pipeline.yml#L45), [ops CI pipeline](../../ops/pipeline/ci-pipeline.yml#L84), [ops README](../../ops/README.md#L4)). It must not be presented as the workflow executed by this repository.

**Validation performed for this investigation:** `dotnet test backend/InvoiceApp.sln` returned `dotnet: command not found`. The documented `~/.dotnet/dotnet` fallback was also absent. Tests therefore remain **not run in this environment**. The As-built architecture document records a successful run on 2026-10-24, but that is historical documentation, not a test run performed here ([as-built.md](./as-built.md#L136)).

## G. Planned January architecture (TARGET STATE)

The scenario describes a move to a 24x7 on-call service with a database, message topic, and PayEx integration; the scope note explicitly says these do not yet exist in the code ([ops README](../../ops/README.md#L17)).

The architecture target document depicts:

- Azure SQL and a SQL-backed repository replacing the in-memory implementation.
- Invoice rowversion/optimistic concurrency.
- An append-only approval audit store with seven-year retention.
- A PayEx outbox and a submission worker using idempotency keys.
- Service Bus events with notification-worker and audit-archive subscriptions.

These are identified as planned/not built in the target document, not AS-BUILT features ([target-state.md](./target-state.md#L16), [target-state.md](./target-state.md#L22), [target-state.md](./target-state.md#L23)).

The ADR is explicitly a draft. It recommends a transactional outbox plus a stable idempotency key and daily reconciliation, while stating that exactly-once effect depends on PayEx atomically deduplicating the key (or providing an equivalent contract). It also defines duplicate/restart/crash recovery and a month-end fault-test gate; vendor support and test results remain unconfirmed ([PayEx ADR](../adr/0001-exactly-once-payex-submission.md#L3), [decision and rules](../adr/0001-exactly-once-payex-submission.md#L33), [failure-mode coverage and release gate](../adr/0001-exactly-once-payex-submission.md#L50), [PayEx assumptions](../adr/0001-exactly-once-payex-submission.md#L64)).

No numeric SLO, SLI definition, measurement window, or error-budget policy was found in the inspected repository material. The request describes a published SLO as a target, but the value and policy need to be supplied before they can guide an architecture.

## H. Differences between AS-BUILT and TARGET STATE

| Area | AS-BUILT evidence | TARGET STATE / ops evidence | Difference |
|---|---|---|---|
| Persistence | Singleton in-memory list repository ([InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L6)) | Azure SQL is planned; no repository implementation yet ([target-state.md](./target-state.md#L20)) | Restart/process loss and multi-instance durability are not addressed by current storage. |
| Approval audit | `Invoice` stores current decision user/time and note ([Invoice.cs](../../backend/src/InvoiceApp.Domain/Invoice.cs#L10)) | Separate append-only, seven-year audit table is planned ([target-state.md](./target-state.md#L21)) | No append-only history or retention mechanism is implemented. |
| PayEx | `ApprovalService.Approve` only applies invoice state and repository update ([ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L31)) | PayEx client/worker/outbox are proposed in target docs ([target-state.md](./target-state.md#L23), [PayEx ADR](../adr/0001-exactly-once-payex-submission.md#L33)) | No payment submission behavior exists in current source. |
| Messaging/notifications | No publisher, topic client, or worker in backend source ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L12)) | Ops scenario describes `invoice-events`, notification-worker, and audit-archive ([Service Bus status](../../ops/incidents/INC-2047/servicebus-status.txt#L12)) | Operational evidence cannot be treated as application capability. |
| Concurrency | Approval service reads, checks, changes, and updates without a version token ([ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L31)) | Rowversion is proposed in target-state docs ([target-state.md](./target-state.md#L26)) | There is no persisted optimistic-concurrency control. |
| Logging/monitoring | `appsettings.json` sets logging levels; no explicit application `ILogger` calls, custom metrics, tracing, health endpoint, or retry policy was found in backend source ([appsettings.json](../../backend/src/InvoiceApp.Api/appsettings.json#L3)) | User brief calls for 24x7 and a published SLO; ADR proposes outbox-worker alerts and recovery controls ([PayEx ADR](../adr/0001-exactly-once-payex-submission.md#L87)) | SLO and operational guarantees are not implemented or quantitatively specified in the repository. |
| CI/CD | `.github/workflows/ci.yml` runs only .NET build and test ([ci.yml](../../.github/workflows/ci.yml#L17)) | Ops CI file includes scans, container and E2E steps ([ops CI pipeline](../../ops/pipeline/ci-pipeline.yml#L65)) | The fuller pipeline is scenario documentation, not this repo's active CI workflow. |
| Outbox decision | No outbox code exists ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L12)) | Target-state table says the outbox/worker is not built and the ADR recommendation awaits approval and vendor contract verification ([target-state.md](./target-state.md#L22), [PayEx ADR](../adr/0001-exactly-once-payex-submission.md#L3)) | The intended design is not yet a signed-off implementation specification. |

Additional ops evidence is internally inconsistent in its inventory: `ops/README.md` and `ops/evals/README.md` say there are ten fixed cases, while the directory contains cases 01–12 and `results.csv` includes cases 11 and 12 ([eval README](../../ops/evals/README.md#L3), [case 11](../../ops/evals/cases/case-11.diff#L1), [case 12](../../ops/evals/cases/case-12.diff#L1), [results.csv](../../ops/evals/results.csv#L12)). Some evals are also intentionally stand-alone diffs that do not match this checkout: case 03 refers to `DiscountCalculator.Apply`, while source exposes `ApplyDiscount`; case 08 replaces the repository with a `Dictionary`, while source uses a locked `List<Invoice>` ([case 03](../../ops/evals/cases/case-03.diff#L1), [DiscountCalculator.cs](../../backend/src/InvoiceApp.Domain/DiscountCalculator.cs#L31), [case 08](../../ops/evals/cases/case-08.diff#L1), [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L11)).

## I. Inferred items and assumptions

These statements are deductions, not explicit runtime guarantees:

- **INFERRED — process-local state:** singleton registrations plus in-memory repositories imply state is local to the running process; no scale-out/shared-state behavior is specified ([Program.cs](../../backend/src/InvoiceApp.Api/Program.cs#L13), [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L11)).
- **INFERRED — session lifetime:** `UserSession` has no expiry field and `SessionStore` retains tokens until removal; automatic expiration is not shown ([UserSession.cs](../../backend/src/InvoiceApp.Api/Auth/UserSession.cs#L3), [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs#L7)).
- **INFERRED — cross-operation atomicity:** repository methods lock separately; the full approval read/check/update operation is not one transaction. Concurrency behavior under simultaneous requests has not been tested ([InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs#L20), [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs#L31)).
- **INFERRED — no production deployment guarantees:** source and `.github` CI do not establish hosting topology, replicas, backup, failover, or production rollback behavior. The ops pack's three instances are scenario details, not source proof ([INC-2041 README](../../ops/incidents/INC-2041/README.md#L30)).

### AI-use traceability in the repository

`docs/ai-augmentation-log.md` is a manually written record of prior assignment work. It records a named Copilot/model, tools, sub-agent counts, task inputs, outputs, checks, and some human corrections; it says raw transcripts are not copied into the repository ([AI augmentation log](../ai-augmentation-log.md#L3), [AI augmentation log](../ai-augmentation-log.md#L7), [AI augmentation log](../ai-augmentation-log.md#L13)). It is not runtime application telemetry and does not provide complete per-interaction prompts/follow-ups or a reproducible event log for this investigation. No AI agent integration or AI-use instrumentation exists in the backend source.

## J. Missing evidence and questions requiring investigation

1. **SLO:** What availability/latency objective, measurement window, exclusions, error budget, and reporting source will be published?
2. **Hosting:** What is the target hosting topology, instance count, health/readiness contract, deployment strategy, and rollback mechanism? The ops incident scenario's topology does not prove the target topology.
3. **Persistence/recovery:** Confirm database engine, schema ownership, migration strategy, transaction boundaries, backup/restore objectives, RPO/RTO, and data-retention requirements.
4. **Approval concurrency:** What should happen when two approvers decide the same invoice concurrently? Is rowversion/optimistic concurrency required, and what is the conflict UX?
5. **Audit:** Which actions/fields must be retained, immutable, searchable, and auditable, and how should retention/deletion/legal hold work?
6. **PayEx contract:** Confirm atomic idempotency or equivalent duplicate-detection guarantees, retention, lookup consistency, timeout semantics, reconciliation export, and sandbox failure testing. The ADR makes this a go-live dependency and labels the assumptions unconfirmed ([PayEx ADR](../adr/0001-exactly-once-payex-submission.md#L62), [PayEx assumptions](../adr/0001-exactly-once-payex-submission.md#L64)).
7. **Payment lifecycle:** Define how approval and payment outcomes are represented, retry classification, unknown outcomes, manual intervention, idempotency, and reconciliation ownership.
8. **Messaging/notifications:** Confirm whether Service Bus is actually part of the approved target, event schema/versioning, subscription filters, ownership, replay/dead-letter procedures, and notification recovery policy. INC-2047 is scenario evidence, not a contract.
9. **Authentication/authorization:** Confirm production identity provider, credential handling, token lifetime/revocation, role matrix, and whether invoice creation/read access should be role-restricted.
10. **Operations and telemetry:** Define required structured logs, metrics, traces, alert thresholds, dashboards, runbooks, escalation, and the human approval boundary for incident actions.
11. **Testing and delivery:** Confirm required integration/E2E/security/performance tests, CI gates, deployment promotion, secret handling, and whether the fuller ops pipeline is an intended replacement for the checked-in workflow.
12. **Business scope:** Decide the open questions in bulk approval and partial approval briefs, including batch failure behavior, second approver rules, limits, and partial-approval audit/status semantics ([UC-1](../use-cases/UC-1-bulk-approval.md#L10), [UC-2](../use-cases/UC-2-partial-approval.md#L8)).

## K. Repository commands available for testing and CI

| Purpose | Command | Repository evidence / status |
|---|---|---|
| Run API | `dotnet run --project backend/src/InvoiceApp.Api` | Documented in [AGENTS.md](../../AGENTS.md#L27); launch profile uses `http://localhost:5000` ([launchSettings.json](../../backend/src/InvoiceApp.Api/Properties/launchSettings.json#L4)). |
| Backend tests | `dotnet test backend/InvoiceApp.sln` | Documented in [AGENTS.md](../../AGENTS.md#L28); attempted here but not run because .NET CLI is unavailable. |
| E2E tests | `cd e2e && npm install && npx playwright install chromium && npm test` | Documented in [AGENTS.md](../../AGENTS.md#L29); no E2E test files are checked in. |
| Checked-in CI build | `dotnet build backend/InvoiceApp.sln --configuration Release` | [ci.yml](../../.github/workflows/ci.yml#L17). |
| Checked-in CI test | `dotnet test backend/InvoiceApp.sln --configuration Release --no-build` | [ci.yml](../../.github/workflows/ci.yml#L18). |
| Scenario CI pipeline | See `ops/pipeline/ci-pipeline.yml` | Includes restore, Node/Playwright, scans, container, and E2E; it is not the checked-in `.github` workflow ([ops CI pipeline](../../ops/pipeline/ci-pipeline.yml#L45)). |

## Proceeding checklist

The following information is sufficient to move from investigation into architecture deliverables:

- [ ] Approved target scope, service boundaries, hosting topology, and January milestones.
- [ ] Published SLO/SLIs, measurement window, error budget, and availability/latency targets.
- [ ] Persistence, migration, transaction, audit, retention, backup, RPO, and RTO decisions.
- [ ] Approval concurrency rules and the expected conflict behavior.
- [ ] Confirmed PayEx contract details, sandbox access, idempotency and reconciliation behavior.
- [ ] Decision on Service Bus/event consumers, event schema, notification recovery, and ownership.
- [ ] Production identity, authorization, token, secrets, and security requirements.
- [ ] Observability, alerting, on-call, runbook, escalation, and human-approval requirements.
- [ ] Required CI/CD gates and test coverage, including integration, E2E, load, and failure testing.
- [ ] Resolved business questions for bulk approval and partial approval.
