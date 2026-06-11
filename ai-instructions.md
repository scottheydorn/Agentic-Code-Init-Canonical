# AI Coding Assistant Instructions

> **Scope:** Global defaults for all projects. Override per-project with a local `.ai-instructions.md` or equivalent tool-specific config.

---

## Identity & Communication

- Be concise. Prefer short explanations with working code over long prose.
- When in doubt, ask one focused clarifying question rather than assuming.
- Show your reasoning briefly before executing complex multi-step changes.
- Never commit secrets, tokens, or credentials into source code.

---

## Code Style & Conventions

### General

- **Language preference order:** TypeScript > Python > Bash > C#/X++
- **Formatting:** Use project-configured formatters (Prettier, Black, etc.). Do not override.
- **Naming:** camelCase for variables/functions, PascalCase for types/classes/components, SCREAMING_SNAKE for constants, kebab-case for file names.
- **Comments:** Only where "why" is non-obvious. No restating of code logic. No commented-out code in commits.
- **Imports:** Group by external → internal → relative. Prefer named exports over default exports.
- **Magic values:** Extract to named constants or config. Zero magic strings/numbers in logic.

### TypeScript

- Strict mode always (`"strict": true` in tsconfig).
- Prefer `interface` over `type` for object shapes (unless union/intersection needed).
- Use `const` by default, `let` only when reassignment is required. Never `var`.
- Prefer early returns over deeply nested conditionals.
- Use discriminated unions for state management patterns.
- Explicit return types on exported functions; inferred is fine for internal/private.
- Avoid `any`. Use `unknown` + type guards when type is genuinely unknown.

### Python

- Target Python 3.11+ unless project specifies otherwise.
- Type hints on all function signatures (use `typing` module or 3.10+ syntax).
- Use `dataclasses` or `pydantic` for structured data, not raw dicts.
- Prefer `pathlib.Path` over `os.path`.
- Use `f-strings` for interpolation, never `%` or `.format()`.
- Follow PEP 8, enforced by project linter (ruff, flake8, or black).

---

## Architecture & Design Patterns

### Application Architecture

- **Separation of concerns:** UI → API/Routes → Services → Data Access. No database queries in route handlers or components.
- **Colocation:** Keep related files together (component + styles + tests in same directory).
- **Feature-based organization** over type-based (e.g., `src/features/auth/` not `src/controllers/auth.ts` + `src/models/auth.ts`).
- **Configuration:** All environment-specific values in env vars or config files. Never hardcode URLs, connection strings, or feature flags.

### Next.js Specific

- Use App Router (not Pages Router) for new projects.
- Server Components by default; use `'use client'` only when interactivity is required.
- Route handlers for API endpoints (`app/api/*/route.ts`).
- Use `loading.tsx` and `error.tsx` for UX states.
- Dynamic route params must be awaited in Next.js 14+.
- Use server actions for form mutations when appropriate.

### Database & ORM

- **Preferred ORM:** Drizzle ORM with PostgreSQL.
- Define schemas in a dedicated schema file (`src/lib/db/schema.ts` or similar).
- Use migrations for all schema changes (never manual DDL in production).
- Index columns used in WHERE clauses and JOINs.
- Use transactions for multi-table writes.
- Prefer parameterized queries; never concatenate user input into SQL.

### State Management

- Server state: React Query / SWR or Next.js server components with revalidation.
- Client state: React useState/useReducer for local, Zustand for shared client state.
- Avoid Redux unless project already uses it.
- URL state (search params) for filterable/shareable views.

---

## API Design Patterns

### RESTful Design

- Use proper HTTP methods: GET (read), POST (create), PUT/PATCH (update), DELETE (remove).
- Return appropriate status codes: 200 (success), 201 (created), 204 (no content), 400 (client error), 401 (unauthorized), 403 (forbidden), 404 (not found), 409 (conflict), 500 (server error).
- Consistent response shape:
  ```json
  { "data": {...}, "meta": { "count": 100, "page": 1 } }
  ```
  or for errors:
  ```json
  { "error": { "code": "VALIDATION_FAILED", "message": "...", "details": [...] } }
  ```

### Performance & Reliability

- **Pagination:** Always paginate list endpoints. Use cursor-based for large/real-time datasets, offset-based for smaller admin views.
- **Timeouts:** Set explicit timeouts on all external calls (default 30s, configurable).
- **Retry with backoff:** Exponential backoff (1s, 2s, 4s) with jitter for transient failures. Max 3 retries.
- **Circuit breaker:** For critical external dependencies, fail fast after N consecutive failures.
- **Idempotency:** POST/PUT endpoints should support idempotency keys for safe retries.
- **Rate limiting:** Apply per-user/per-IP rate limits on public endpoints.
- **Caching:** Use HTTP cache headers (ETag, Cache-Control) for GET endpoints. Cache expensive computations with TTL.
- **Bulk operations:** Provide batch endpoints instead of requiring N individual calls.
- **Graceful degradation:** If a non-critical dependency is down, return partial results with a warning rather than a full 500.

### Validation & Input Handling

- Validate all input at the API boundary (use Zod, Joi, or Pydantic).
- Sanitize HTML input to prevent XSS.
- Reject oversized payloads early (Content-Length check).
- Return all validation errors at once, not one at a time.

---

## Error Handling

- **Never swallow exceptions.** At minimum, log them. Prefer structured error handling.
- Use custom error classes/types for domain-specific errors.
- Log errors with context: timestamp, request ID, user ID (if available), stack trace.
- User-facing error messages should be helpful but not expose internals.
- In TypeScript: prefer `Result<T, E>` pattern or try/catch with typed errors over unchecked throws.
- In Python: use specific exception types; avoid bare `except:`.

---

## Testing & Quality

### Testing Strategy

- **Unit tests:** For pure logic, utilities, and data transformations.
- **Integration tests:** For API routes, database queries, and external service interactions.
- **E2E tests:** For critical user flows only (login, core business processes).
- **Test naming:** `describe('ModuleName', () => { it('should [expected behavior] when [condition]') })`.

### Testing Principles

- Tests should be independent and order-agnostic.
- Use factories/fixtures for test data, not hardcoded values.
- Mock external dependencies at the boundary, not deep internals.
- Prefer testing behavior over implementation details.
- Aim for meaningful coverage of business logic; 100% line coverage is not a goal.

### Quality Gates

- Zero TypeScript errors (`tsc --noEmit`).
- Linting must pass before commit.
- No `console.log` in production code (use structured logger).
- No disabled tests (`skip`, `xit`) merged to main without a tracking issue.

---

## Security

- **Authentication:** Azure Entra ID (OIDC/OAuth 2.0) for enterprise apps. JWT with short-lived access + refresh tokens.
- **Authorization:** Role-based access control (RBAC). Check permissions at the API layer, not just the UI.
- **Secrets:** Azure Key Vault or equivalent. Never in code, env files committed to repo, or client bundles.
- **CORS:** Whitelist specific origins. Never `*` in production.
- **Dependencies:** Keep dependencies updated. Audit regularly (`npm audit`, `pip audit`).
- **Input validation:** Treat all input as untrusted. Validate server-side even if validated client-side.

---

## Infrastructure & Deployment (Azure)

- **Target cloud:** Microsoft Azure.
- **Identity:** Entra ID for authentication. Managed Identities for service-to-service auth.
- **Compute:** Azure App Service (Linux) for web apps, Azure Functions for event-driven workloads.
- **Database:** Azure Database for PostgreSQL Flexible Server.
- **Secrets:** Azure Key Vault with RBAC access policies.
- **CI/CD:** Azure DevOps Pipelines or GitHub Actions.
- **Networking:** VNet integration for production workloads. Private endpoints for databases.
- **Monitoring:** Application Insights for APM, Log Analytics for centralized logging.
- **IaC:** Bicep or Terraform for infrastructure provisioning.

---

## UI & Styling

- **Framework:** Tailwind CSS for styling. Utility-first approach.
- **Components:** Prefer composition over inheritance. Small, focused components.
- **Accessibility:** Semantic HTML, ARIA labels where needed, keyboard navigation support.
- **Responsive:** Mobile-first design. Use Tailwind breakpoints (`sm:`, `md:`, `lg:`).
- **Loading states:** Always show loading indicators for async operations.
- **Error states:** Show actionable error messages with retry options where applicable.
- **Dark mode:** Support if project requires it; use CSS variables or Tailwind's `dark:` variant.

---

## Git & Version Control

- **Commits:** Conventional commits format: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- **Branches:** Short-lived feature branches. Merge to `main` via PR.
- **PRs:** Small, focused PRs. One concern per PR. Include description of what and why.
- **No force pushes** to `main` or shared branches.
- **Clean history:** Squash merge feature branches to main.

---

## MCP Interfaces (Model Context Protocol)

When available, load and utilize the following MCP servers to enhance capabilities:

### Required MCP Servers

| Server | Purpose | Auth Method |
|--------|---------|-------------|
| **azure-devops** | Work items, pipelines, repos, wikis, code search | Azure CLI (`az login`) |
| **d365fo** | D365 F&O entity queries, metadata, reports, actions | Azure Default Credentials |
| **devops-bridge** | Unified ADO + Jira + Confluence access | PAT / API Tokens |
| **spira** | SpiraPlan project management, incidents, requirements | API Key |

### MCP Usage Guidelines

- **Load at init:** If the agent supports MCP, connect to all configured servers at session start.
- **Prefer MCP over manual API calls:** When an MCP tool exists for the operation, use it rather than crafting raw HTTP requests.
- **Credential safety:** MCP credentials are managed externally (env vars, Key Vault, or config files). Never log, display, or commit credentials surfaced by MCP connections.
- **Graceful degradation:** If an MCP server is unavailable, inform the user and continue with available capabilities.
- **Server definitions:** See `mcp-servers/` directory for detailed capability descriptions and setup instructions for each server.

### Configuration Location

MCP server configuration is typically stored at:
- **GitHub Copilot CLI:** `~/.copilot/mcp-config.json`
- **Claude Code:** Project-level `.mcp.json` or `~/.claude/mcp.json`
- **VS Code Copilot:** `.vscode/mcp.json` in workspace
- **Cursor:** `.cursor/mcp.json` in workspace

A ready-to-use template is provided in `mcp-servers/mcp-config.template.json`.

---

## Override Policy

These instructions are defaults. Override them when:

1. A project has its own established conventions (follow the project's style).
2. A specific technology constraint requires a different approach.
3. Performance profiling shows a pattern is a bottleneck.
4. The user explicitly requests a different approach for the current task.

When overriding, state briefly why the override is appropriate.

---

*Last updated: 2025-06-11*
