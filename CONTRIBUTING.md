# Contributing to MyReferral

## 1. Welcome

Thank you for your interest in contributing to **MyReferral**! This document defines the engineering standards, workflows, and expectations for anyone contributing code, documentation, or reviews to this project. Whether you're fixing a bug, shipping a feature, or improving our docs, please read this guide carefully before opening a Pull Request.

MyReferral is built on the following stack:

| Layer | Technology |
|---|---|
| Frontend | Next.js, TypeScript, Tailwind CSS |
| Backend / Auth | Supabase, Google OAuth |
| Database | PostgreSQL |
| Hosting / CI-CD | Vercel |

By contributing, you agree to follow the conventions in this document to keep the codebase consistent, reviewable, and production-safe.

---

## 2. Repository Structure

```
MyReferral/
├── frontend/     # Next.js application (TypeScript, Tailwind CSS, UI components)
├── backend/      # Supabase functions, server-side logic, API integrations
├── database/     # PostgreSQL schema, migrations, seed data
├── docs/         # Architecture docs, ADRs, onboarding guides, API references
└── scripts/      # Automation, tooling, CI helpers, one-off maintenance scripts
```

**Guidelines:**

- Keep changes scoped to the relevant directory. Cross-cutting changes (e.g., a feature touching `frontend/` and `database/`) should be clearly explained in the PR description.
- New top-level directories require prior discussion with maintainers via an issue or RFC in `docs/`.
- Each top-level directory should maintain its own `README.md` describing local setup and conventions specific to that layer.

---

## 3. Branch Strategy

We use a **trunk-based release flow** with the following long-lived and ephemeral branches:

| Branch | Purpose | Lifetime |
|---|---|---|
| `main` | Production-ready code. Always deployable via Vercel. | Permanent |
| `develop` | Integration branch for the next release. | Permanent |
| `feature/*` | New features, branched from `develop`. | Ephemeral |
| `bugfix/*` | Non-critical bug fixes, branched from `develop`. | Ephemeral |
| `release/*` | Release stabilization, branched from `develop`. | Ephemeral |
| `hotfix/*` | Urgent production fixes, branched from `main`. | Ephemeral |

**Naming convention:**

```
feature/<ticket-id>-short-description
bugfix/<ticket-id>-short-description
release/vX.Y.Z
hotfix/<ticket-id>-short-description
```

**Examples:**

```
feature/MR-142-referral-dashboard
bugfix/MR-201-fix-oauth-redirect
release/v1.4.0
hotfix/MR-305-fix-payout-calculation
```

---

## 4. Git Workflow

1. **Sync `develop`**
   ```bash
   git checkout develop
   git pull origin develop
   ```
2. **Create your branch**
   ```bash
   git checkout -b feature/MR-142-referral-dashboard
   ```
3. **Commit early, commit often**, using [Conventional Commits](#5-conventional-commit-messages).
4. **Rebase before opening a PR** to keep history linear:
   ```bash
   git fetch origin
   git rebase origin/develop
   ```
5. **Push and open a PR** targeting `develop` (or `main` for `hotfix/*`):
   ```bash
   git push origin feature/MR-142-referral-dashboard
   ```
6. **Squash-merge** on approval. The squashed commit message must follow the Conventional Commits format and summarize the full change.
7. **Delete the branch** after merge (local and remote).

**Release flow:**

- `release/*` branches are cut from `develop` for QA stabilization, then merged into both `main` and `develop`.
- `hotfix/*` branches are cut from `main`, merged into both `main` and `develop`, and tagged immediately after merge.

**Tagging:** All merges to `main` must be tagged using semantic versioning (e.g., `v1.4.0`), triggering a Vercel production deployment.

---
## 5. Conventional Commit Messages

All commits **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer(s)]
```

**Allowed types:**

| Type | Use for |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `chore` | Tooling, dependencies, build config |
| `perf` | Performance improvements |
| `style` | Formatting, whitespace, no logic change |

**Examples:**

```
feat(auth): add Google OAuth sign-in flow
fix(search): correct pagination offset in referral search
docs(database): document migration rollback procedure
refactor(api): extract referral scoring into a service module
test(auth): add unit tests for session refresh logic
```

**Rules:**

- Scope should map to a module/domain (`auth`, `search`, `database`, `api`, `dashboard`, `payouts`, etc.), not a file name.
- Summary is written in the imperative mood ("add", not "added"/"adds").
- Breaking changes must include a `BREAKING CHANGE:` footer describing the impact and migration path.
- Reference the ticket ID in the footer where applicable: `Refs: MR-142`.

---

## 6. Coding Standards

### TypeScript

- **Strict mode is mandatory.** `tsconfig.json` must keep `"strict": true`.
- No `any` unless explicitly justified with a `// eslint-disable-next-line` comment explaining why.
- Prefer explicit return types on exported functions and public APIs.
- Use `type` for unions/utility shapes and `interface` for extendable object contracts — be consistent within a module.
- Avoid default exports for utilities/services; use named exports. Default exports are acceptable for Next.js pages/components where required by convention.
- All shared types live in a dedicated `types/` directory per app layer; do not duplicate domain types across `frontend/` and `backend/`.

### React (Next.js)

- Functional components with Hooks only — no class components.
- One component per file; file name matches the component name (`ReferralCard.tsx`).
- Co-locate component-specific styles, tests, and stories with the component.
- Server Components by default; use `"use client"` only when interactivity, state, or browser APIs are required.
- Data fetching in Server Components or Route Handlers — avoid client-side fetching for data available at request time.
- All Tailwind class lists should be readable; extract to `cva`/`clsx` variants when a component has more than ~4 conditional classes.
- No inline styles unless dynamically computed (e.g., chart dimensions).
- Accessibility is non-negotiable: semantic HTML, proper `aria-*` attributes, keyboard navigability.

### SQL

- Keywords in `UPPER_CASE`, identifiers in `snake_case`.
- Every table requires a primary key, `created_at`, and `updated_at` columns.
- Foreign keys must be explicitly named: `fk_<table>_<referenced_table>`.
- No `SELECT *` in application code or migrations — always list columns explicitly.
- All queries touching user-scoped data must respect Supabase Row Level Security (RLS) policies; do not bypass with the service role key outside of trusted backend contexts.

### Markdown

- One `H1` per document, used as the title.
- Use fenced code blocks with language hints (` ```ts `, ` ```sql `, ` ```bash `).
- Wrap lines at a reasonable length for readability in diffs (~100–120 characters).
- Use tables for structured comparisons, not ASCII art.

---

## 7. Database Migration Standards

All schema changes live in `database/migrations/` and are **immutable once merged** — never edit a merged migration; create a new one.

### Naming Convention

```
V<MAJOR>.<MINOR>.<PATCH>__<description>.sql
```

**Examples:**

```
V1.0.0__initial_schema.sql
V1.1.0__add_referrals_table.sql
V1.1.1__fix_referral_status_default.sql
V1.2.0__add_payout_history_indexes.sql
```

### Versioning Rules

- **MAJOR**: Breaking schema changes (dropped columns/tables, incompatible type changes).
- **MINOR**: Additive, backward-compatible changes (new tables, new nullable columns, new indexes).
- **PATCH**: Data fixes, constraint corrections, non-structural adjustments.
- Version numbers must be sequential and unique — no gaps skipped intentionally, no reused numbers.
- Each migration file must include a header comment block:
  ```sql
  -- Migration: V1.1.0__add_referrals_table.sql
  -- Author: <name>
  -- Date: YYYY-MM-DD
  -- Description: Adds referrals table to track user invitations.
  ```

### Rollback

- Every migration must have a corresponding rollback script in `database/migrations/rollback/`, named identically with a `_rollback` suffix:
  ```
  V1.1.0__add_referrals_table_rollback.sql
  ```
- Rollback scripts must fully reverse the forward migration and be tested in a staging environment before the forward migration is merged.
- Destructive rollbacks (data loss) must be explicitly flagged in the PR description with `⚠️ DESTRUCTIVE ROLLBACK`.

### Validation

- Migrations must run cleanly against a fresh database (`V1.0.0` → latest) as part of CI.
- Migrations must be idempotent-safe in staging: re-running the pipeline should not error on already-applied versions.
- RLS policies affected by a migration must be re-verified and included in the same migration file.
- No migration is merged without a successful dry run against a staging Supabase project.

---

## 8. Pull Request Checklist

Before requesting review, confirm:

- [ ] Branch is up to date with `develop` (or `main` for hotfixes) and rebased cleanly.
- [ ] Commits follow Conventional Commit format.
- [ ] Code builds locally (`npm run build`) with no TypeScript errors.
- [ ] Linting passes (`npm run lint`) with no new warnings.
- [ ] All new and existing tests pass (`npm run test`).
- [ ] New/changed database migrations include a rollback script and have been validated in staging.
- [ ] No secrets, API keys, or `.env` values are committed.
- [ ] Relevant documentation (`docs/`, `README.md`, inline comments) is updated.
- [ ] PR description clearly explains **what**, **why**, and **how to test**.
- [ ] PR is linked to its tracking ticket/issue.
- [ ] Screenshots or recordings are attached for UI-affecting changes.
- [ ] PR is scoped to a single logical change (no bundled unrelated fixes).

---

## 9. Code Review Checklist

Reviewers must verify:

- [ ] **Correctness** — the change does what the PR description claims, with no regressions.
- [ ] **Architecture fit** — logic lives in the right layer (`frontend/`, `backend/`, `database/`) and follows existing patterns.
- [ ] **Security** — no exposed secrets, proper auth checks, RLS respected, no SQL injection vectors, OAuth scopes unchanged unless intended.
- [ ] **Type safety** — no unjustified `any`, types are precise and reused where appropriate.
- [ ] **Readability** — naming is clear, functions are single-purpose, complex logic is commented.
- [ ] **Performance** — no obvious N+1 queries, unnecessary re-renders, or unbounded loops.
- [ ] **Test coverage** — new logic has corresponding tests; edge cases are considered.
- [ ] **Migration safety** — schema changes are backward-compatible or clearly flagged as breaking.
- [ ] **Consistency** — coding standards in Section 6 are followed.
- [ ] At least **one approval** is required before merge; two approvals for changes touching `database/` or authentication flows.

Reviewers should leave actionable, specific comments and distinguish between **blocking** issues and **non-blocking suggestions** (prefix nits with `nit:`).

---

## 10. Testing Expectations

| Layer | Tooling | Expectation |
|---|---|---|
| Frontend unit/component | Jest + React Testing Library | Required for all new components with logic (not pure presentational) |
| Backend/API | Jest / Vitest | Required for all Supabase functions and API route handlers |
| Database | SQL test scripts / staging validation | Required for all migrations |
| End-to-end | Playwright (or equivalent) | Required for critical user flows (auth, referral creation, payout) |
| Type checking | `tsc --noEmit` | Enforced in CI on every PR |

**Minimum expectations:**

- New features require tests covering the happy path and at least one edge/error case.
- Bug fixes must include a regression test that fails without the fix and passes with it.
- Authentication and payment/payout-related code require end-to-end coverage, not just unit tests.
- CI must pass fully (lint, type-check, unit, integration) before merge is permitted.

---
## 11. Definition of Done

A task/PR is considered **Done** only when:

1. Code is merged into `develop` (or `main` for hotfixes) via an approved, squash-merged PR.
2. All CI checks (lint, type-check, tests, build) pass.
3. Any related database migrations are applied and validated in staging, with rollback verified.
4. Documentation (`docs/`, READMEs, inline comments, API references) is updated to reflect the change.
5. The feature/fix has been manually verified in a preview deployment (Vercel Preview URL) or staging environment.
6. No new console errors, warnings, or accessibility violations are introduced.
7. The related ticket/issue is updated with a summary and linked PR, then closed.
8. Stakeholders (design/product, where applicable) have confirmed the change meets acceptance criteria.

---

## 12. Documentation Standards

- All new features must include or update relevant documentation in `docs/` before the PR is merged — not as a follow-up task.
- **Architecture Decision Records (ADRs)** are required for significant technical decisions (new dependencies, schema redesigns, auth changes) and stored in `docs/adr/` using sequential numbering (`0001-use-supabase-for-auth.md`).
- **API documentation** for backend routes/functions must describe request/response shapes, auth requirements, and error codes.
- **README files** in each top-level directory must stay current with setup instructions, environment variables, and local run commands.
- Code comments should explain **why**, not **what** — the code itself should be readable enough to convey what it does.
- All documentation is written in professional, concise Markdown, following the formatting rules in [Section 6](#markdown).
- Diagrams (architecture, data flow) should be stored as source files (e.g., Mermaid, `.drawio`) alongside a rendered export in `docs/diagrams/`.

---

Thank you for helping build MyReferral. If anything in this guide is unclear or you believe a convention should evolve, open a discussion in `docs/` or raise it with the maintainers before submitting a large change.

