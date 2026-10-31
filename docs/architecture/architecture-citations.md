# Architecture diagram citation register

This register records the evidence for every node and relationship in the three diagrams. Line numbers refer to the checked-in files as reviewed on 2026-10-31. The target-state ADR is explicitly a draft; planned elements below are not claims about running code.

## As-built container diagram

Diagram: [as-built-container.mmd](./as-built-container.mmd)

### Nodes

| ID | Element | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| N01 | Approver or Admin in browser | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), class-level `RequireRole`; [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `renderPending` | 9, 68-73 | Approval actions require the Approver or Admin role; the UI presents approve/reject actions. |
| N02 | ASP.NET Core application process | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), top-level app setup | 6-24 | One web application is built, configured and run by this entry point. It does not establish a production host or replica count. |
| N03 | Static UI assets | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), `UseDefaultFiles` / `UseStaticFiles`; [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js) | 19-20; 1-19 | The same API application serves static files; the browser JavaScript calls `/api` endpoints. |
| N04 | SessionAuthMiddleware | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs) | 16-37; 21 | The middleware checks API sessions and is registered in the request pipeline. |
| N05 | AuthController | [AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs), `Login` / `Logout` | 9, 24-45 | Sign-in validates configured demo users and creates a session; sign-out removes its bearer token. |
| N06 | DemoUsersOptions | [UserSession.cs](../../backend/src/InvoiceApp.Api/Auth/UserSession.cs), `DemoUsersOptions`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs) | 12-17; 12 | The app binds configuration to the options type used by `AuthController`. |
| N07 | SessionStore | [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs), `SessionStore`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs) | 7-21; 13 | Session tokens are held in a concurrent in-memory dictionary; the store is singleton-registered. |
| N08 | InvoicesController | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), resource actions | 9-74 | The controller implements invoice reads, create, submit and Admin-only delete. |
| N09 | ApprovalsController | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Approve` / `Reject` | 9-27 | The controller exposes approve/reject POST endpoints and requires Approver or Admin. |
| N10 | RequireRoleAttribute | [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs), `OnActionExecuting` | 8-26 | The action filter returns 403 when the session role is not in the allowed roles. |
| N11 | ApiControllerBase.Handle | [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle` | 9-25 | Service results return 200; KeyNotFound, InvalidOperation and Argument exceptions map to 404, 409 and 400. |
| N12 | ApprovalService | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit` / `Approve` / `Reject` | 7-66 | Domain lifecycle transitions and their validation are implemented in this service. |
| N13 | IInvoiceRepository | [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs), interface | 3-10 | The Domain declares the invoice persistence boundary as an interface. |
| N14 | InMemoryInvoiceRepository | [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), repository | 6-65 | The only backend implementation stores invoices in a `List<Invoice>` and locks individual operations. |

### Relationships

| ID | Relationship | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| E01 | Browser requests static UI | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), static-file middleware | 19-20 | The app serves its default and static files. |
| E02 | Browser sends `/api` calls with a bearer session | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `api`; [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync` | 16-19; 19-26 | The UI uses `fetch` for `/api` calls and sends an Authorization header when signed in; middleware reads the bearer token. |
| E03 | Middleware looks up session | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync`; [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs), `Get` | 25; 18-19 | The presented token is looked up in the in-memory session store. |
| E04 | Middleware forwards login without a session | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), login exemption and `_next` | 19, 36 | `/api/auth/login` is exempt from the session requirement and the pipeline continues. |
| E05 | Middleware forwards authenticated invoice calls | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), `MapControllers` | 29-36; 22 | A valid session is attached to request context before controller execution. |
| E06 | Middleware forwards authenticated approval calls | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), `MapControllers` | 29-36; 22 | A valid session is attached to request context before controller execution. |
| E07 | AuthController checks demo-user configuration | [AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs), `Login`; [UserSession.cs](../../backend/src/InvoiceApp.Api/Auth/UserSession.cs), `DemoUsersOptions` | 24-35; 12-17 | Login matches the submitted username/password against configured demo users. |
| E08 | AuthController creates/removes sessions | [AuthController.cs](../../backend/src/InvoiceApp.Api/Controllers/AuthController.cs), `Login` / `Logout`; [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs), `Create` / `Remove` | 34, 39-45; 11-21 | Login creates a token-backed session and logout removes it. |
| E09 | InvoicesController has an Admin-only Delete action | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Delete`; [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs), filter | 72-74; 17-26 | The role filter applies to the destructive action and can reject unauthorized roles. |
| E10 | ApprovalsController uses role filter | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), class-level attribute; [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs) | 9; 17-26 | MVC applies the role filter to approval actions. |
| E11 | InvoicesController delegates submit through Handle | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle` | 69-70; 9-25 | The submit route invokes `ApprovalService.Submit` through the common result/error mapper. |
| E12 | ApprovalsController delegates approve/reject through Handle | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Approve` / `Reject`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle` | 21-27; 9-25 | Both decision endpoints call the service through the common result/error mapper. |
| E13 | Handle executes the service delegate | [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle` | 9-25 | The action delegate is executed and selected service exceptions are mapped to HTTP errors. |
| E14 | InvoicesController uses repository directly | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `GetAll`, `GetById`, `Create`, `Delete`; [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs) | 19-78; 3-10 | Invoice queries/create/delete go directly through the repository abstraction. |
| E15 | ApprovalService uses repository | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit` / `Approve` / `Reject` / `Find`; [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs) | 16-65; 3-10 | Lifecycle methods read by ID and call `Update` after transitions. |
| E16 | DI binds repository interface to in-memory implementation | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), service registration; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), class declaration | 14; 6 | Runtime dependency injection resolves `IInvoiceRepository` to `InMemoryInvoiceRepository`. |

## As-built approval sequence diagram

Diagram: [as-built-approval-sequence.mmd](./as-built-approval-sequence.mmd)

### Participants

| ID | Participant | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| S-N01 | Signed-in browser user | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), UI actions | 46-73 | A user can submit a Draft and request approve/reject actions from the browser UI. |
| S-N02 | Browser UI | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `api`, submit/decision handlers | 16-19, 46-86 | The UI invokes the API and refreshes the list after successful submit/decision actions. |
| S-N03 | ASP.NET Core API pipeline | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), middleware and controller registration | 19-22 | Static files, session middleware and controller routes are hosted by the app. |
| S-N04 | SessionAuthMiddleware | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync` | 16-37 | API requests except login require a valid session. |
| S-N05 | SessionStore | [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs), `Get` | 18-19 | Middleware resolves the token to a `UserSession` or null. |
| S-N06 | InvoicesController | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit` | 69-70 | The submit endpoint invokes `ApprovalService.Submit`. |
| S-N07 | ApprovalsController | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Approve` / `Reject` | 9, 21-27 | The decision endpoints obtain the approver name from the session and call service methods. |
| S-N08 | RequireRoleAttribute | [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs), `OnActionExecuting` | 17-26 | Approval actions return 403 for an unallowed role. |
| S-N09 | ApiControllerBase.Handle | [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle` | 9-25 | The helper maps service results/errors to HTTP responses. |
| S-N10 | ApprovalService | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), lifecycle methods | 16-66 | Draft submission and PendingApproval decisions perform the shown state transitions. |
| S-N11 | IInvoiceRepository | [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs), interface | 3-10 | Service/controller persistence calls use this interface. |
| S-N12 | InMemoryInvoiceRepository | [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `GetById` / `Update` | 25-28, 50-58 | The implementation reads and replaces matching entries in its process-local list. |

### Interactions and branches

| ID | Interaction or branch | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| S01 | Click Submit for approval | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `renderInvoices` | 46-52 | A Draft row exposes a submit button whose click handler posts to the submit endpoint. |
| S02 | POST submit with bearer token | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `api`; [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit` | 16-19, 52; 69-70 | The browser sends the request to `/api/invoices/{id}/submit`. |
| S03 | API request enters middleware | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), middleware registration | 21-22 | Session middleware runs in the configured API request pipeline before mapped controllers. |
| S04 | Middleware calls SessionStore.Get | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync` | 21-29 | Middleware reads the bearer token and looks up its session. |
| S05 | Missing session returns 401 | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), unauthorized branch | 27-30 | A missing session ends the request with HTTP 401. |
| S06 | Valid session is attached to request | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync` | 32-36 | The session is put in `HttpContext.Items` before the next component runs. |
| S07 | Submit endpoint invoked | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit` | 69-70 | POST submit calls the service via `Handle`. |
| S08 | Controller calls Handle with Submit delegate | [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs) | 70; 9-13 | The service call is wrapped by the base helper. |
| S09 | Handle invokes ApprovalService.Submit | [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle`; [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit` | 9-13; 16-27 | The delegate calls the domain submit operation. |
| S10 | Submit reads repository by ID | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit` / `Find` | 18, 61-62 | The service resolves the invoice through `GetById`. |
| S11 | Interface resolves to in-memory lookup | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), DI registration; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `GetById` | 14; 25-28 | The current repository implementation reads from the in-memory list. |
| S12 | Repository returns invoice or null | [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `GetById` | 25-28 | Missing IDs return null; found IDs return the matching invoice. |
| S13 | Repository result reaches service | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Find` | 61-62 | `Find` returns the invoice or throws `KeyNotFoundException`. |
| S14-S15 | Missing invoice maps to 404 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Find`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 61-62; 15-17 | `KeyNotFoundException` from a missing invoice becomes HTTP 404. |
| S16-S17 | Non-Draft submit maps to 409 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 20-24; 19-21 | A non-Draft invoice causes `InvalidOperationException`, mapped to HTTP 409. |
| S18 | Draft transitions to PendingApproval | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit` | 20-27 | Only Draft can be submitted; success changes status to PendingApproval. |
| S19-S20 | Submit updates in-memory repository | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Submit`; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `Update` | 26-27; 50-58 | The service calls `Update`, which replaces the matching list item. |
| S21-S23 | Submit returns 200 and UI refreshes | [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), `Handle`; [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), submit handler | 13; 52 | Successful service result returns 200; the UI refreshes the invoice list. |
| S24-S25 | User selects and sends a decision | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `renderPending` / `decide` | 68-86 | UI offers Approve and Reject and posts to the corresponding endpoint. |
| S26-S29 | Decision request authenticates | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), middleware registration; [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), `InvokeAsync` | 21; 19-36 | Every `/api` request except login requires a valid session, which is attached to the request. |
| S30-S31 | Role filter permits Approver/Admin or returns 403 | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), class attribute; [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs), filter | 9; 17-26 | Approval actions are restricted to Approver/Admin and unauthorized roles receive 403. |
| S32-S34 | Approve endpoint calls ApprovalService.Approve | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Approve`; [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Approve` | 21-23; 31-39 | The controller passes invoice ID and session username to the domain method. |
| S35-S38 | Approve reads repository result | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Approve` / `Find`; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `GetById` | 33, 61-62; 25-28 | Approve fetches the invoice from the current in-memory repository. |
| S39-S40 | Missing invoice during approval maps to 404 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Find`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 61-62; 15-17 | Missing invoice throws `KeyNotFoundException`, mapped to 404. |
| S41-S43 | Non-pending invoice during approval maps to 409 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `EnsurePending`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 65-70; 19-21 | Only PendingApproval may be decided; invalid state becomes HTTP 409. |
| S44-S48 | Approve transition and result | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Approve`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs) | 31-40; 9-13 | Success sets Approved, records approver and UTC decision time, updates the repository and returns 200. |
| S49-S51 | Reject endpoint passes reason to service | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Reject`; [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Reject` | 25-27; 43-50 | The request reason and session username are passed to the domain reject method. |
| S52-S53 | Blank reject reason maps to 400 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Reject`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 43-48; 23-25 | A blank reason throws `ArgumentException`, mapped to HTTP 400 before invoice lookup. |
| S54-S57 | Reject reads repository result | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Reject` / `Find`; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), `GetById` | 50, 61-62; 25-28 | A nonblank rejection reason is followed by invoice lookup. |
| S58-S59 | Missing invoice during rejection maps to 404 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Find`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 61-62; 15-17 | Missing invoice becomes HTTP 404. |
| S60-S62 | Non-pending invoice during rejection maps to 409 | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `EnsurePending`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs), catch block | 51, 65-70; 19-21 | Only PendingApproval may be rejected; invalid state becomes HTTP 409. |
| S63-S67 | Reject transition and result | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), `Reject`; [ApiControllerBase.cs](../../backend/src/InvoiceApp.Api/Controllers/ApiControllerBase.cs) | 43-58; 9-13 | Success sets Rejected, records user/time/reason, updates the repository and returns 200. |

## Target-state container diagram

Diagram: [target-state-container.mmd](./target-state-container.mmd)

Every diagram node is tagged `TNxx` and every relationship is tagged `TExx`.

### Nodes

| ID | Element | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| TN01 | Existing browser actor | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), browser UI | 16-19, 68-86 | The browser UI sends authenticated API requests and presents approval actions. |
| TN02 | Existing static UI assets | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), `UseDefaultFiles` / `UseStaticFiles`; [index.html](../../backend/src/InvoiceApp.Api/wwwroot/index.html) | 19-20; 1 | The API application serves the static UI. |
| TN03 | Existing API controllers and session authentication | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), middleware and controller registration; [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs) | 21-22; 16-37 | Controllers and session authentication are in the current request pipeline. |
| TN04 | Existing ApprovalService | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), lifecycle methods; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), DI registration | 7, 16-58; 15 | The service is implemented and registered today. |
| TN05 | Existing IInvoiceRepository seam | [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs), interface | 3-10 | Domain defines the repository boundary. |
| TN06 | Existing InMemoryInvoiceRepository | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), DI registration; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), class | 14; 6-65 | The current runtime implementation uses an in-memory list. |
| TN07 | Planned SQL repository, name/deployment unspecified | [target-state.md](./target-state.md), planned persistence and inferred names | 22, 30-31 | A SQL repository is planned; the class name is illustrative, not source-defined. |
| TN08 | Planned Azure SQL | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context; [target-state.md](./target-state.md), planned component | 14; 20 | Azure SQL is the planned store, not a current application dependency. |
| TN09 | Planned invoice state data | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), approval transaction | 37 | The invoice state is to be updated in the approval transaction; physical schema is unspecified. |
| TN10 | Planned append-only approval audit data | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context and rule 1; [target-state.md](./target-state.md) | 13, 37; 21 | The requirement is seven-year approval audit retention; no physical schema is defined. |
| TN11 | Planned outbox and stable idempotency key | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), decision and rules 1-3 | 33, 37-39 | The draft recommends a transactional outbox and one stable unique key per approval. |
| TN12 | Planned PayEx submission worker | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rules 4-7 | 40-43 | A worker claims outbox rows and calls PayEx; where it runs is not decided. |
| TN13 | Planned PayEx external service; contract unconfirmed | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context and assumptions | 10, 64-85 | January submission is planned, but atomic idempotency, lookup consistency/retention and reconciliation capabilities are unconfirmed. |
| TN14 | Planned Unknown-outcome resolver behavior | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 6 and release gate | 42, 50-62 | Ambiguous outcomes are resolved through a verified atomic-idempotency replay or an equivalent vendor duplicate-detection/lookup contract. |
| TN15 | Planned daily reconciliation safety net | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 10 and assumptions | 46, 64-85 | Daily reconciliation is recommended; the PayEx report/export is unresolved. |
| TN16 | Planned worker lease, heartbeat and breaker controls | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rules 4 and 7 | 40, 43 | The draft specifies leases/heartbeats and pausing for systemic errors. |
| TN17 | Planned operational alert conditions | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), consequences | 92 | Required alerts include pending age, Unknown count/age, dead letters and breaker state. |
| TN18 | Planned on-call engineer/runbook | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context and consequences | 12, 90 | The target includes an on-call rotation and Unknown-handling runbook; alert transport is unspecified. |
| TN19 | Planned audited manual requeue tool behavior | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 6 | 42 | Manual requeue must be supported by evidence and audited; implementation details are not specified. |
| TN20 | Proposal-only rowversion | [target-state.md](./target-state.md), planned component table and inference note | 26, 32 | Rowversion is not built and is explicitly identified as a proposal, not a settled design choice. |
| TN21 | Service Bus topic in ops scenario evidence | [target-state.md](./target-state.md), component table and inference note; [servicebus-status.txt](../../ops/incidents/INC-2047/servicebus-status.txt) | 25, 35-36; 5-7 | Scenario material names `invoice-events`; target documentation says it is scenario evidence, not used by application code. |
| TN22 | `notification-worker` subscription in ops scenario | [servicebus-status.txt](../../ops/incidents/INC-2047/servicebus-status.txt), subscription list | 12-17 | Scenario evidence lists this subscription; it is not confirmed as part of the January app design. |
| TN23 | `audit-archive` subscription in ops scenario | [servicebus-status.txt](../../ops/incidents/INC-2047/servicebus-status.txt), subscription list | 12-17 | Scenario evidence lists this subscription; it is not confirmed as part of the January app design. |

### Relationships

| ID | Relationship | Source file and symbol | Lines | What the evidence establishes |
|---|---|---|---|---|
| TE01 | Browser user loads static UI | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), static-file middleware | 19-20 | The current application serves the browser assets. |
| TE02 | Browser UI calls API | [app.js](../../backend/src/InvoiceApp.Api/wwwroot/app.js), `api`; [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), `MapControllers` | 16-19; 22 | Browser JavaScript calls `/api` endpoints exposed by the app. |
| TE03 | API controller calls ApprovalService | [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), `Approve` / `Reject`; [InvoicesController.cs](../../backend/src/InvoiceApp.Api/Controllers/InvoicesController.cs), `Submit` | 21-27; 69-70 | Existing routes delegate lifecycle operations to the service. |
| TE04 | ApprovalService uses repository interface | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), constructor and lifecycle methods; [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs) | 9-12, 16-58; 3-10 | Domain service depends on the repository abstraction. |
| TE05 | Existing interface binds to in-memory implementation | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), DI registration; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), class declaration | 14; 6 | The current DI binding resolves the interface to the in-memory repository. |
| TE06 | Existing seam could bind to future SQL repository | [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs); [target-state.md](./target-state.md), target persistence and inference | 3-10; 20, 30-31 | The interface exists and is the planned extension point; the implementation is not present. |
| TE07 | Planned SQL repository uses Azure SQL transaction | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 1; [target-state.md](./target-state.md), planned transaction | 37; 20-22 | The draft requires approval, audit and outbox writes to commit together in one transaction. |
| TE08-TE10 | Azure SQL contains invoice, audit and outbox data | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 1; [target-state.md](./target-state.md), planned components | 37; 20-22 | The planned transaction persists those three logical records; schema and table names are unspecified. |
| TE11 | Outbox work is claimed before PayEx call | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 4 | 40 | Worker claims a row with a lease/fencing token and commits before making the external call. |
| TE12 | Worker submits using stable idempotency key | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rules 2-3 and release gate | 38-39, 62 | The design requires the same stable key on calls; PayEx atomic deduplication remains an unverified go-live dependency. |
| TE13 | PayEx returns reference or ambiguous timeout | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context and rules 6-7 | 10, 42-43 | A success has a reference; timeout means Unknown, not confirmed failure. |
| TE14 | Worker records result in second transaction | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 4 | 40 | The post-call outcome is recorded separately from the transaction that claims work. |
| TE15 | Worker controls govern worker calls | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rules 4 and 7 | 40, 43 | Lease/fencing and breaker behaviors are specified as design requirements. |
| TE16 | Unknown rows go to resolver behavior | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 6 | 42 | The resolver handles Unknown outcomes. |
| TE17 | Resolver uses contract-safe lookup or idempotent replay | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 6 and release gate | 42, 62 | Replay is conditional on verified atomic duplicate detection, stable payload/key and key-retention validity; lookup-only recovery without duplicate prevention is insufficient. |
| TE18 | Reconciliation compares with PayEx information; mechanism unresolved | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), decision, rule 10 and assumptions | 31, 46, 64-85 | The diagram marks the conceptual external comparison as planned; no specific report/API is asserted. |
| TE19 | Worker state informs required alerts | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 9 and required alerts | 45, 92 | Alert conditions are required, but the telemetry implementation is unspecified. |
| TE20 | Alerts reach on-call | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), context and consequences | 12, 90, 92 | The operational relationship is required; alert channel and escalation tooling are unspecified. |
| TE21 | Audited manual requeue affects outbox work | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 6 | 42 | Manual requeue requires evidence and an audit record. |
| TE22 | Proposal adds concurrency token to invoice state | [target-state.md](./target-state.md), rowversion entry and inference note | 26, 32 | This is proposal-only and not a confirmed design relationship. |
| TE23-TE24 | Ops-scenario topic has named subscriptions | [servicebus-status.txt](../../ops/incidents/INC-2047/servicebus-status.txt), topic/subscription listing | 5-17 | The scenario associates the two subscriptions with `invoice-events`; this does not establish a current app publisher. |
| TE25 | Conditional future outbox event publishing | [0001-exactly-once-payex-submission.md](../adr/0001-exactly-once-payex-submission.md), rule 12; [target-state.md](./target-state.md), inference note | 48; 33-34 | The PayEx path is not to use Service Bus now; publishing from an outbox is conditional on later consumers. |

## Structural architecture test

The existing structural rule is implemented by `Domain_DoesNotReferenceWebOrStorageAssemblies` in [ArchitectureTests.cs](../../backend/tests/InvoiceApp.Tests/ArchitectureTests.cs#L7). It prevents the Domain assembly from directly referencing API, web, ORM, SQL-client, or Service Bus assemblies.

Run only this architecture test with:

```sh
dotnet test backend/tests/InvoiceApp.Tests/InvoiceApp.Tests.csproj --filter FullyQualifiedName~ArchitectureTests
```

The command is written down here; execution status is reported separately and is not inferred from historical CI or documentation.
