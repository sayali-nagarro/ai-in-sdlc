# Build stage has network access (NuGet restore); the run stage is started on an internal-only network.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY backend/ backend/
RUN dotnet publish backend/src/InvoiceApp.Api/InvoiceApp.Api.csproj -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
USER app
ENTRYPOINT ["dotnet", "InvoiceApp.Api.dll"]
