using InvoiceApp.Domain;
using Xunit;

namespace InvoiceApp.Tests;

// Rule from AGENTS.md: business rules live in Domain, with no web or storage code.
public class ArchitectureTests
{
    private static readonly string[] ForbiddenAssemblyPrefixes =
    {
        "InvoiceApp.Api",
        "Microsoft.AspNetCore",
        "Microsoft.EntityFrameworkCore",
        "Microsoft.Data.SqlClient",
        "System.Data.SqlClient",
        "Azure.Messaging.ServiceBus",
    };

    [Fact]
    public void Domain_DoesNotReferenceWebOrStorageAssemblies()
    {
        var domainAssembly = typeof(ApprovalService).Assembly;

        var violations = domainAssembly.GetReferencedAssemblies()
            .Select(reference => reference.Name ?? string.Empty)
            .Where(name => ForbiddenAssemblyPrefixes.Any(prefix => name.StartsWith(prefix, StringComparison.Ordinal)))
            .ToList();

        Assert.True(
            violations.Count == 0,
            $"InvoiceApp.Domain must not reference: {string.Join(", ", violations)}");
    }
}
