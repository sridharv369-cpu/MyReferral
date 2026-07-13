# Security Policy — MyReferral

## 1. Security Policy

MyReferral is committed to protecting the confidentiality, integrity, and availability of user data, including referral records, personal information, and authentication credentials. This document defines how security is implemented across the application stack (Next.js/TypeScript frontend, Supabase backend, PostgreSQL database, and Vercel hosting), how vulnerabilities should be reported, and the standards engineers must follow when contributing code.

This policy applies to:
- The MyReferral web application (Next.js/TypeScript/Tailwind CSS)
- The Supabase backend (Auth, Database, Storage, Edge Functions if applicable)
- Associated infrastructure, CI/CD pipelines, and deployment configuration on Vercel

All contributors, maintainers, and integrators are expected to read and adhere to this policy.

---

## 2. Supported Versions

MyReferral is deployed as a continuously updated web application rather than a versioned distributable package. Security support follows the deployment model below:

| Environment          | Supported | Notes                                      |
|-----------------------|:---------:|---------------------------------------------|
| `main` (Production)   | ✅        | Actively monitored and patched              |
| `staging`              | ✅        | Receives fixes prior to production rollout  |
| Feature branches       | ⚠️        | Best-effort only, not production-facing     |
| Archived / deprecated  | ❌        | No longer maintained                        |

If MyReferral is distributed as a self-hosted template or open-source starter kit, only the latest tagged release receives security patches. Users of older forks are strongly encouraged to rebase onto the latest `main`.

---

## 3. Reporting Vulnerabilities

We take all security reports seriously and appreciate responsible disclosure.

**Please do NOT open a public GitHub issue for security vulnerabilities.**

### How to report

- **Email:** `security@myreferral.app` *(replace with your actual security contact)*
- **Encrypted reports:** PGP key available upon request
- **Alternative:** GitHub private vulnerability reporting (Security → Advisories → "Report a vulnerability"), if enabled on this repository

### What to include

To help us triage quickly, please provide:
1. A clear description of the vulnerability and its potential impact
2. Steps to reproduce (proof-of-concept code, requests, or screenshots)
3. Affected component (frontend route, Supabase policy, API endpoint, etc.)
4. Any suggested remediation, if known

### Scope

**In scope:**
- Authentication/authorization bypass (Google OAuth, Supabase Auth, RLS policies)
- Data exposure via Supabase Storage, Database Views, or API routes
- Injection vulnerabilities (SQL, XSS, SSRF, etc.)
- Business logic flaws in referral tracking/rewards
- Secrets or credential leakage

**Out of scope:**
- Denial of Service via volumetric traffic (report to Vercel/Supabase directly)
- Social engineering or physical attacks against staff
- Vulnerabilities requiring physical access to a user's device
- Third-party services outside our direct control (report upstream)

We ask that researchers avoid accessing, modifying, or exfiltrating other users' data beyond what is minimally necessary to demonstrate a vulnerability.

---

## 4. Security Response Timeline

We aim to meet the following service levels for reported vulnerabilities:

| Stage                          | Target Timeframe        |
|---------------------------------|--------------------------|
| Acknowledgment of report        | Within 48 hours          |
| Initial triage & severity rating| Within 5 business days   |
| Critical/High severity fix      | Within 7 days            |
| Medium severity fix             | Within 30 days           |
| Low severity fix                | Next scheduled release   |
| Public disclosure (coordinated) | 90 days or upon fix release, whichever is sooner |

Severity is assessed using **CVSS v3.1**. We will keep reporters informed of progress and credit them (with permission) in release notes or a security acknowledgments page.

---

## 5. Authentication Security

MyReferral uses **Supabase Auth** with **Google OAuth** as the primary identity provider.

### Controls in place
- OAuth 2.0 / OIDC flow via Google, avoiding password storage/management by the application entirely
- Supabase-issued **JWTs** (short-lived access tokens + refresh tokens) for session management
- Secure, `HttpOnly`, `SameSite=Lax` (or `Strict` where feasible) cookies for session persistence via `@supabase/ssr`
- Automatic token refresh handled server-side to avoid exposing long-lived credentials to client JavaScript
- PKCE (Proof Key for Code Exchange) flow enforced for OAuth exchanges to prevent authorization code interception
- Redirect URL allow-listing configured in both Google Cloud Console and Supabase Auth settings to prevent open-redirect abuse

### Requirements for contributors
- Never implement custom password-based authentication alongside OAuth without explicit security review
- Never read or log raw JWTs or refresh tokens
- All session validation must occur server-side (Next.js Server Components / Route Handlers / Middleware) using `supabase.auth.getUser()`, **not** `getSession()`, for any request that authorizes access to protected data (`getUser()` revalidates against Supabase's auth server; `getSession()` trusts the local cookie).
- Enforce email verification status from the Google-verified identity before granting elevated actions (e.g., payout requests)

---

## 6. Authorization Model

MyReferral enforces authorization primarily at the **database layer**, not just in application code, following a defense-in-depth model.

### Principles
- **Row Level Security (RLS)** is enabled on every table containing user-scoped data. No table is left with RLS disabled in production.
- **Default-deny posture:** tables have no permissive policies until an explicit `USING` / `WITH CHECK` policy is defined.
- **Database Policies** map directly to business roles (e.g., `referrer`, `referred_user`, `admin`) using `auth.uid()` and custom claims/roles rather than client-supplied identifiers.
- **PostgreSQL Views** are used to expose only sanitized, minimal-column projections of underlying tables to the client (e.g., hiding internal referral scoring, admin notes, or PII from non-privileged roles), reducing the API's data surface area.
- Role checks use `auth.jwt() ->> 'role'` or a dedicated `profiles`/`user_roles` table rather than trusting client-side role claims.

### Requirements for contributors
- Any new table **must** ship with RLS enabled and policies reviewed before merge — RLS-less tables must be explicitly justified and approved.
- Never rely solely on frontend route guards (e.g., hiding a button) as an authorization control — always assume the API/database can be called directly.
- Service-role keys (which bypass RLS) must **never** be used in client-reachable code paths — only within trusted server-side contexts (Edge Functions, server actions) with tightly scoped logic.
- Test RLS policies with representative negative cases (a user attempting to read/write another user's row) as part of code review.

---

## 7. Database Security

MyReferral's PostgreSQL database (managed via Supabase) is the primary trust boundary for data access.

### Controls in place
- **UUID primary keys** across all tables, preventing sequential ID enumeration attacks and reducing information leakage about record volume/growth
- Row Level Security enforced on all user-facing tables
- Views used to create a controlled read surface, decoupling internal schema evolution from the public API contract
- Foreign key constraints and `CHECK` constraints to enforce data integrity at the database level, not just application level
- Automated backups and point-in-time recovery (PITR) via Supabase, tested periodically
- Least-privilege database roles: application traffic uses the `anon`/`authenticated` roles subject to RLS; only trusted server contexts use `service_role`

### Requirements for contributors
- All schema changes go through migrations (tracked in version control), never ad-hoc changes via the Supabase dashboard in production
- Avoid `SELECT *` in application queries against tables with sensitive columns — query through views or explicit column lists
- Parameterized queries only — the Supabase client library handles this by default; raw SQL (via RPC/`pg` functions) must use parameter binding, never string concatenation
- Sensitive columns (e.g., payout details) should be additionally access-controlled via column-level privileges or separate tables with stricter RLS

---

## 8. Storage Security

File uploads (e.g., profile images, referral documents) are handled via **Supabase Storage**.

### Controls in place
- **Storage Policies** (RLS-equivalent for buckets) restrict object access based on the authenticated user's ownership (typically matching `auth.uid()` against a path prefix, e.g., `user-uploads/{uid}/...`)
- Public buckets are used only for genuinely public assets (e.g., static branding); all user-generated content lives in private buckets accessed via signed URLs with short expiry
- File type and size validation enforced both client-side (UX) and server-side (authoritative), before upload acceptance
- Filenames are sanitized/normalized and stored with generated UUIDs to prevent path traversal and collision-based overwrites

### Requirements for contributors
- Never construct storage paths from unsanitized user input
- Signed URL expiry should be as short as practically usable (minutes, not days) for sensitive documents
- Virus/malware scanning should be considered for any user-uploaded file type that could be executed or rendered (evaluate integration with a scanning service for document uploads)
- Storage bucket policies must be reviewed alongside database RLS changes — they are a separate policy surface and are easy to forget

---

## 9. API Security

MyReferral's API surface consists of Next.js Route Handlers/Server Actions and Supabase's auto-generated REST/RPC layer.

### Controls in place
- All mutating operations validate the authenticated session server-side before touching the database
- Input validation/schema enforcement (e.g., via `zod`) on all Route Handlers and Server Actions, rejecting malformed or unexpected payloads
- CORS configured restrictively on any exposed API routes — no wildcard `*` origins for authenticated endpoints
- Rate limiting applied to sensitive endpoints (auth callbacks, referral submission, payout requests) to mitigate abuse and brute-force/enumeration attempts
- Supabase Row Level Security acts as a secondary enforcement layer even if an API route has a logic flaw (defense in depth)

### Requirements for contributors
- Treat every API route as a public, untrusted entry point — do not assume the frontend is the only caller
- Never trust client-supplied user IDs, roles, or referral ownership claims in request bodies; always derive identity from the verified session
- Return generic error messages to clients; log detailed errors server-side only (avoid leaking stack traces, SQL errors, or internal identifiers)
- Apply the principle of least response — only return the fields the client actually needs

---

## 10. Secure Coding Guidelines

- **TypeScript strict mode** is enabled project-wide; `any` usage requires justification in code review.
- **XSS prevention:** rely on React/Next.js's default output escaping; avoid `dangerouslySetInnerHTML` unless content is sanitized (e.g., via `DOMPurify`) and the need is documented.
- **CSRF:** Server Actions and Route Handlers rely on `SameSite` cookies and Supabase's token-based auth; state-changing GET requests are prohibited.
- **Content Security Policy (CSP):** a restrictive CSP header is configured via `next.config.js`/middleware, limiting script/style/img sources and disabling `unsafe-inline` where possible.
- **Security headers:** `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or CSP `frame-ancestors`), and `Referrer-Policy: strict-origin-when-cross-origin` are set on all responses (via Vercel/Next.js middleware).
- **Dependency hygiene:** third-party UI libraries and Tailwind plugins are reviewed before adoption; unmaintained packages are avoided.
- **Code review:** all changes touching auth, RLS policies, storage policies, or payment/referral-reward logic require review from at least one other engineer with security context, prior to merge.
- **Environment parity:** staging mirrors production configuration (RLS policies, headers, auth settings) to catch misconfigurations before release.

---

## 11. Secrets Management

- All secrets (Supabase service role key, Google OAuth client secret, API keys) are stored as **environment variables** in Vercel's encrypted environment variable store — never committed to source control.
- `.env.local` and equivalent files are covered by `.gitignore`; `.env.example` contains only placeholder keys/names for onboarding.
- The **Supabase service role key** is used exclusively in server-side contexts (Server Actions, Route Handlers, Edge Functions) and is never bundled into client JavaScript (verified via `NEXT_PUBLIC_` prefix discipline — only the anon key and public URL are exposed to the client).
- Secrets are scoped per environment (Development / Preview / Production) in Vercel, preventing production credentials from leaking into preview deployments.
- Secret rotation is performed:
  - Immediately upon suspected compromise
  - On team member offboarding (for shared credentials)
  - Periodically (recommended: every 90 days) for high-privilege keys
- Git history is periodically scanned (e.g., via `gitleaks` or GitHub Secret Scanning) for accidentally committed credentials.

---

## 12. Dependency Management

- **Automated scanning:** GitHub Dependabot (or equivalent) is enabled for `npm` dependencies, opening PRs for security patches automatically.
- **Lockfile enforcement:** `package-lock.json`/`pnpm-lock.yaml` is committed and CI installs are run with `--frozen-lockfile` to prevent unreviewed transitive updates.
- **Audit checks:** `npm audit` (or `pnpm audit`) is run in CI; builds fail on newly introduced high/critical severity advisories.
- **Minimal footprint:** dependencies are added deliberately; unused packages are removed during regular maintenance passes.
- **Supabase/Next.js/Vercel platform updates** are tracked via release notes and applied on a regular cadence, with breaking changes tested in staging first.
- **Third-party scripts** (analytics, widgets) are reviewed for necessity and loaded with Subresource Integrity (SRI) or via trusted CDNs where possible, and reflected in the CSP.

---

## 13. Logging & Monitoring

- **Application logs:** Vercel's built-in logging captures server-side errors and function invocations; sensitive data (tokens, passwords, full PII) is explicitly excluded from log statements.
- **Database logs:** Supabase's Postgres logs and the built-in query performance/log explorer are used to monitor for anomalous query patterns (e.g., repeated policy-denied attempts, which may indicate probing).
- **Auth events:** Supabase Auth logs (sign-ins, OAuth callback failures, token refresh failures) are reviewed for patterns indicating credential stuffing or OAuth misconfiguration abuse.
- **Alerting:** Critical error rates, spikes in 4xx/5xx responses, and unusual database RLS denial rates should be wired to an alerting channel (e.g., Slack/email via Vercel/Supabase integrations or a third-party APM).
- **Audit trail:** Sensitive business actions (referral approval, reward payout, role changes) are recorded in an application-level `audit_log` table with actor, timestamp, and action metadata, distinct from raw system logs.
- **Retention:** Logs are retained in accordance with applicable data protection requirements and are purged/anonymized on a defined schedule.

> Logging should never capture full JWTs, OAuth tokens, passwords, or complete payment/PII payloads. Redact or hash identifiers where feasible.

---

## 14. OWASP Top 10 Mapping (2021)

| OWASP Category | MyReferral Mitigation |
|---|---|
| **A01 – Broken Access Control** | RLS on every table, Storage Policies, server-side session verification via `getUser()`, default-deny policies |
| **A02 – Cryptographic Failures** | TLS enforced end-to-end (Vercel/Supabase), no custom crypto, secrets never stored in plaintext, HSTS enabled |
| **A03 – Injection** | Parameterized queries via Supabase client, `zod` input validation, React's default output escaping (XSS) |
| **A04 – Insecure Design** | Defense-in-depth (app-layer checks + DB-layer RLS), least-privilege role model, threat modeling on new features touching payouts/PII |
| **A05 – Security Misconfiguration** | Environment parity between staging/production, restrictive CSP and security headers, no default/service-role keys in client bundles |
| **A06 – Vulnerable & Outdated Components** | Dependabot, `npm audit` in CI, lockfile enforcement, regular platform updates |
| **A07 – Identification & Authentication Failures** | OAuth 2.0/OIDC via Google, PKCE flow, short-lived JWTs with refresh rotation, no custom password storage |
| **A08 – Software & Data Integrity Failures** | Lockfile-pinned dependencies, CI/CD via Vercel with protected branches and required reviews, signed commits encouraged |
| **A09 – Security Logging & Monitoring Failures** | Structured logging, auth event monitoring, audit log for sensitive actions, alerting on anomalies |
| **A10 – Server-Side Request Forgery (SSRF)** | No user-controlled outbound URL fetching in server code; any future webhook/URL-fetch features require an allow-list and network egress restrictions |

---

## 15. Incident Response

### Process
1. **Detection** — via monitoring/alerting, user report, or security researcher disclosure.
2. **Triage** — on-call engineer/security lead assesses severity and scope within hours of detection.
3. **Containment** — revoke/rotate affected credentials, disable affected feature flags or routes, tighten RLS/storage policies if the issue is data exposure.
4. **Eradication** — deploy a fix, verified in staging, then promoted to production via standard CI/CD.
5. **Recovery** — confirm restored functionality, monitor for recurrence, restore from backups/PITR if data integrity was affected.
6. **Post-incident review** — a blameless retrospective is conducted within 5 business days, documenting root cause, timeline, and follow-up actions.

### Communication
- Affected users are notified in accordance with applicable data breach notification laws (e.g., GDPR's 72-hour requirement, where applicable) if personal data confidentiality was impacted.
- A summary of the incident (without exposing exploit details prematurely) may be published post-remediation for transparency.

### Roles
- **Security contact / triage owner:** responsible for acknowledging and coordinating reports (see Section 3)
- **Engineering lead:** responsible for authorizing and deploying fixes
- **Communications owner:** responsible for user/stakeholder notifications, if required

---

## 16. Future Security Enhancements

The following items are tracked as planned improvements to strengthen MyReferral's security posture:

- [ ] Formal **penetration test** / third-party security audit prior to major public launch
- [ ] **Multi-factor authentication (MFA)** support as an additional layer beyond Google OAuth for admin/privileged accounts
- [ ] **Web Application Firewall (WAF)** rules at the edge (Vercel Firewall / Cloudflare) for common attack pattern filtering
- [ ] Automated **RLS policy test suite** run in CI against representative user roles to catch regressions
- [ ] **Anomaly detection** on referral/reward flows to catch fraud patterns (e.g., self-referral abuse, bot-driven sign-ups)
- [ ] **Bug bounty program** once the application reaches sufficient scale/maturity
- [ ] **SOC 2 / data processing agreement (DPA)** readiness review if MyReferral processes data on behalf of enterprise customers
- [ ] **Field-level encryption** for highly sensitive PII (e.g., payout bank details) beyond RLS
- [ ] Formal **data retention and deletion policy**, including automated PII purging for inactive/deleted accounts
- [ ] **Structured Security Champions** rotation within the engineering team to keep this document current each quarter

---

*This SECURITY.md is a living document and should be reviewed at least quarterly or whenever significant architectural changes are made to authentication, authorization, database schema, or infrastructure.*

**Last updated:** July 13, 2026
