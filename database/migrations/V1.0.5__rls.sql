-- =============================================================================
-- Project:            MyReferral
-- Migration:          V1.0.5__rls.sql
-- Version:            V1.0.5
-- Description:        Enable Row Level Security (RLS) for all application
--                      tables.
-- =============================================================================
-- Target Platform:    PostgreSQL 17+
-- Compatibility:      Supabase (auth.uid(), auth.role(), storage, realtime)
-- =============================================================================
-- Execution Order:    Must be applied AFTER V1.0.4__auth_sync.sql
-- Dependencies:        V1.0.4__auth_sync.sql (auth schema synchronization)
-- Idempotency:        Safe to re-run; guarded via IF EXISTS / IF NOT EXISTS
--                      checks where applicable
-- Rollback Strategy:  Refer to corresponding down-migration
--                      (V1.0.5__rls.down.sql), if present
-- =============================================================================
-- Author:             Database Engineering Team
-- Reviewed By:        Senior PostgreSQL Security Architect
-- Change Control:      Subject to standard migration review & approval process
-- =============================================================================
-- Notes:
--   - This migration enforces Row Level Security (RLS) across all
--     application-owned tables within the public schema.
--   - Policies defined herein assume Supabase-managed auth.uid() context
--     for authenticated request scoping.
--   - No destructive operations (DROP/TRUNCATE/ALTER DATA) are included
--     in this migration; DDL is limited to security enablement/policy
--     definitions only.
-- =============================================================================
-- =============================================================================
-- Section:            Row Level Security Activation
-- Purpose:            Enable RLS enforcement on all application-owned tables.
--                      No access policies are defined in this section; until
--                      corresponding CREATE POLICY statements are applied in
--                      a subsequent migration, these tables will default-deny
--                      all access to non-owner/non-superuser roles.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: public.users
-- Enforce row-level access control on user account records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.referral_posts
-- Enforce row-level access control on referral post records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.referral_posts ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.comments
-- Enforce row-level access control on comment records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.likes
-- Enforce row-level access control on like/reaction records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.referral_requests
-- Enforce row-level access control on referral request records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.referral_requests ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.notifications
-- Enforce row-level access control on notification records.
-- -----------------------------------------------------------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- End of Row Level Security Activation section.
-- Next Step:          Define granular access policies (SELECT/INSERT/UPDATE/
--                      DELETE) per table in a subsequent migration
--                      (e.g., V1.0.6__rls_policies.sql).
-- =============================================================================
-- =============================================================================
-- Section:            Row Level Security Enforcement (Table Owner Inclusion)
-- Purpose:            Force RLS evaluation for table owners and roles with
--                      BYPASSRLS-exempt privileges under normal operation.
--                      By default, PostgreSQL exempts table owners from RLS
--                      policy checks; FORCE ROW LEVEL SECURITY removes this
--                      exemption, ensuring policies are applied uniformly
--                      regardless of the executing role's ownership status.
-- Note:               Roles with the BYPASSRLS attribute (e.g., superusers)
--                      remain unaffected by FORCE and will continue to
--                      bypass RLS entirely.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: public.users
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.users FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.referral_posts
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.referral_posts FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.comments
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.comments FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.likes
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.likes FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.referral_requests
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.referral_requests FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Table: public.notifications
-- Force row-level security enforcement, including for the table owner.
-- -----------------------------------------------------------------------------
ALTER TABLE public.notifications FORCE ROW LEVEL SECURITY;

-- =============================================================================
-- End of Row Level Security Enforcement section.
-- Next Step:          Define granular access policies (SELECT/INSERT/UPDATE/
--                      DELETE) per table in a subsequent migration
--                      (e.g., V1.0.6__rls_policies.sql).
-- =============================================================================
-- =============================================================================
-- Section:            Post-Migration Validation (Read-Only)
-- Purpose:            Verify that RLS activation and enforcement were applied
--                      correctly to all in-scope application tables. These
--                      queries perform no data mutation and are safe to run
--                      in any environment, including production, as part of
--                      migration verification / CI checks.
-- Scope:               public.users, public.referral_posts, public.comments,
--                      public.likes, public.referral_requests,
--                      public.notifications
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Validation 1: Confirm Row Level Security (RLS) is ENABLED per table.
-- Expected:     rowsecurity = true for all six in-scope tables.
-- -----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM
    pg_tables
WHERE
    schemaname = 'public'
    AND tablename IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
    )
ORDER BY
    tablename;

-- -----------------------------------------------------------------------------
-- Validation 2: Confirm RLS is FORCED for table owners.
-- Expected:     relforcerowsecurity = true for all six in-scope tables.
-- -----------------------------------------------------------------------------
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'public'
    AND c.relname IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
    )
    AND c.relkind = 'r'
ORDER BY
    c.relname;

-- -----------------------------------------------------------------------------
-- Validation 3: Confirm expected table names exist in the target schema.
-- Expected:     Six rows returned, one per in-scope table.
-- -----------------------------------------------------------------------------
SELECT
    table_schema,
    table_name
FROM
    information_schema.tables
WHERE
    table_schema = 'public'
    AND table_name IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
    )
ORDER BY
    table_name;

-- -----------------------------------------------------------------------------
-- Validation 4: Confirm NO policies have been created yet on these tables.
-- Expected:     Zero rows returned. Policy definitions are deferred to a
--               subsequent migration (e.g., V1.0.6__rls_policies.sql).
-- -----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    policyname
FROM
    pg_policies
WHERE
    schemaname = 'public'
    AND tablename IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
    );

-- -----------------------------------------------------------------------------
-- Validation 5: Count total number of in-scope tables protected by RLS.
-- Expected:     Count = 6 (rowsecurity = true AND relforcerowsecurity = true).
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*) AS rls_protected_table_count
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'public'
    AND c.relname IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
    )
    AND c.relkind = 'r'
    AND c.relrowsecurity = true
    AND c.relforcerowsecurity = true;

-- =============================================================================
-- End of Post-Migration Validation section.
-- Outcome:            All checks above should confirm RLS is enabled and
--                      forced on all six in-scope tables, with zero policies
--                      currently defined, prior to proceeding with
--                      V1.0.6__rls_policies.sql.
-- =============================================================================
