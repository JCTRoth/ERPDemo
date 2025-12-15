# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY SalesManagement/*.csproj ./SalesManagement/
RUN dotnet restore SalesManagement/SalesManagement.csproj

# Copy source code and build
COPY SalesManagement/. ./SalesManagement/
WORKDIR /src/SalesManagement
RUN dotnet build -c Release -o /app/build --no-restore

# Publish stage
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app
EXPOSE 8080

# Copy published output
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Create a non-root user and ensure /app is owned by that user.
# Portable approach for both Alpine and Debian-based runtime images.
RUN set -eux; \
  if command -v addgroup >/dev/null 2>&1; then addgroup -S app || true; fi; \
  if command -v adduser >/dev/null 2>&1; then adduser -S -G app app || true; elif command -v useradd >/dev/null 2>&1; then useradd -r -g app -s /sbin/nologin app || true; fi; \
  chown -R app:app /app || true

USER app

ENTRYPOINT ["dotnet", "SalesManagement.dll"]
