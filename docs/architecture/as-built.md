# As-built architecture (application source)

This view describes only `backend/src`; it does not use the planned production
scenario in `ops/`. The canonical diagram sources are:

- [Container diagram](./as-built-container.mmd) — [rendered image](./diagrams/as-built-container.png)
- [Approval sequence](./as-built-approval-sequence.mmd) — [rendered image](./diagrams/as-built-sequence.png)

Every diagram node and interaction has a citation ID mapped to a source file,
symbol, and line in the [architecture citation register](./architecture-citations.md).
Items not directly evidenced are listed in
[architecture-inferences.md](./architecture-inferences.md).
Both sources rendered successfully with Mermaid CLI 11.4.2 on 2026-10-31;
the exact render commands are recorded in the
[final verification report](../final-verification-report.md).

## Verified implementation summary

| Area | Source evidence | What exists |
|---|---|---|
| Web/API process | [Program.cs](../../backend/src/InvoiceApp.Api/Program.cs), lines 6-24 | ASP.NET Core app serves static files and maps controllers. Deployment topology is not established by this source. |
| Sign-in and sessions | [SessionAuthMiddleware.cs](../../backend/src/InvoiceApp.Api/Auth/SessionAuthMiddleware.cs), lines 16-37; [SessionStore.cs](../../backend/src/InvoiceApp.Api/Auth/SessionStore.cs), lines 7-21 | Bearer-token sessions are held in a concurrent in-memory dictionary. |
| Authorization | [RequireRoleAttribute.cs](../../backend/src/InvoiceApp.Api/Auth/RequireRoleAttribute.cs), lines 8-26; [ApprovalsController.cs](../../backend/src/InvoiceApp.Api/Controllers/ApprovalsController.cs), lines 9-27 | Approval endpoints require Approver or Admin; role filter rejects disallowed roles. |
| Invoice lifecycle | [ApprovalService.cs](../../backend/src/InvoiceApp.Domain/ApprovalService.cs), lines 16-58 | Submit, approve, and reject transitions and validation are in Domain. |
| Persistence | [IInvoiceRepository.cs](../../backend/src/InvoiceApp.Domain/IInvoiceRepository.cs), lines 3-10; [InMemoryInvoiceRepository.cs](../../backend/src/InvoiceApp.Api/InMemoryInvoiceRepository.cs), lines 6-65 | Domain defines a repository interface; the only current implementation is a process-local list guarded per operation by a lock. |
| Payment/persistence infrastructure | Backend source search; see [target state](./target-state.md) | No SQL persistence, PayEx client, payment worker, or outbox is implemented in this checkout. |

## Corrections to earlier agent claims

| Earlier claim | Verified correction |
|---|---|
| `FakeInvoiceRepository` is under `backend/src` | It is under `backend/tests/InvoiceApp.Tests`; its `Update` is a no-op. |
| Demo users are read at `Program.cs:10` | Binding is at `Program.cs:12`. |
| Evaluation cases 03 and 08 describe the current calculator/repository | They are standalone diffs. The current calculator is an instance class with `ApplyDiscount`; the repository uses `List<Invoice>` and a lock. |
| `MidpointRounding.ToZero` is banker's rounding | It truncates; banker's rounding is `ToEven`. |
| The incident packs prove current app integrations | PayEx, Service Bus publishing, and notification workers are absent from backend source. `ops/` is scenario evidence. |
| CI takes 35–42 minutes | `ops/pipeline/run-timings.csv` is invented scenario data, not this repository's CI timing. See [measured evidence](../measurement/baseline.md). |

## Architecture test

The test [ArchitectureTests.cs](../../backend/tests/InvoiceApp.Tests/ArchitectureTests.cs)
asserts that the Domain assembly does not reference API, web, ORM, SQL-client,
or Service Bus assemblies.

Command:

```sh
dotnet test backend/tests/InvoiceApp.Tests/InvoiceApp.Tests.csproj --filter FullyQualifiedName~ArchitectureTests
```

The focused command was run during this verification with .NET SDK 8.0.427;
it passed 1/1. The raw console output is retained in
[architecture-test-output.txt](./architecture-test-output.txt). The public GitHub Actions run
[41197817586](https://github.com/sayali-nagarro/ai-in-sdlc/actions/runs/41197817586)
passed the full solution at commit `8301b2280b12e55202df93a91a5ce72b119ad25a`;
the workflow test was not filtered to this test. In the current verification
environment the SDK was installed temporarily under `/tmp/dotnet` to run the
focused test; the temporary installation is not part of the repository.

Earlier documentation says a deliberately introduced ASP.NET Core reference
made the test fail and was then reverted. That historical demonstration is
recorded but was not reproduced during this verification.
