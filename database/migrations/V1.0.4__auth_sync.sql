-- =============================================================================
-- Project:           MyReferral
-- Migration:         V1.0.4__auth_sync.sql
-- Version:           V1.0.4
-- Description:       Synchronize Supabase auth.users with public.users
-- -----------------------------------------------------------------------------
-- Database Engine:   PostgreSQL 17+
-- Platform:          Supabase Compatible
-- -----------------------------------------------------------------------------
-- Execution Order:   Run after V1.0.3__triggers.sql
-- Dependencies:       V1.0.3__triggers.sql
-- -----------------------------------------------------------------------------
-- Author:            Senior Supabase Database Architect
-- Created:           2026-07-05
-- -----------------------------------------------------------------------------
-- Notes:
--   * This migration is part of the MyReferral schema versioning sequence.
--   * Ensure all prior migrations (V1.0.0 - V1.0.3) have been applied
--     successfully before executing this script.
--   * Review and test in a staging environment prior to production rollout.
-- =============================================================================
-- =============================================================================
-- Function:          handle_new_user()
-- Purpose:           Automatically create a corresponding profile record in
--                     public.users whenever a new user signs up through
--                     Supabase Authentication (auth.users).
-- -----------------------------------------------------------------------------
-- Trigger Context:   Intended to be invoked by an AFTER INSERT trigger on
--                     auth.users (defined separately in this migration).
-- -----------------------------------------------------------------------------
-- Behavior:
--   * Reads identity and metadata values from the newly inserted auth.users
--     record (NEW).
--   * Extracts display name and avatar URL from raw_user_meta_data JSONB.
--   * Inserts a corresponding row into public.users with default role
--     ('user') and default status ('active').
--   * Gracefully handles duplicate insertions (e.g. re-sync, race conditions,
--     or repeated invocation) via ON CONFLICT (id) DO NOTHING/UPDATE.
--   * Timestamps (created_at, updated_at) are set to the current transaction
--     time at insertion.
-- -----------------------------------------------------------------------------
-- Security:
--   * SECURITY DEFINER — executes with the privileges of the function owner,
--     allowing insertion into public.users regardless of the invoking role's
--     direct table permissions (required since this runs in the auth schema
--     trigger context).
--   * search_path is explicitly locked down to prevent search_path hijacking
--     attacks against SECURITY DEFINER functions.
-- -----------------------------------------------------------------------------
-- Returns:           NEW (required for AFTER INSERT trigger compatibility)
-- Language:          PL/pgSQL
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- -------------------------------------------------------------------
    -- Insert a new profile record into public.users, deriving values
    -- from the newly created auth.users row and its metadata payload.
    -- -------------------------------------------------------------------
    INSERT INTO public.users (
        id,
        email,
        name,
        profile_picture,
        role,
        status,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data ->> 'full_name',
        NEW.raw_user_meta_data ->> 'avatar_url',
        'user',
        'active',
        NOW(),
        NOW()
    )
    -- ---------------------------------------------------------------
    -- Gracefully handle duplicate sign-up events / re-triggers without
    -- raising a unique-violation exception.
    -- ---------------------------------------------------------------
    ON CONFLICT (id) DO NOTHING;

    -- Required return value for AFTER INSERT triggers.
    RETURN NEW;
END;
$$;
-- =============================================================================
-- Function:          handle_updated_user()
-- Purpose:           Synchronize profile changes from auth.users to
--                     public.users whenever an existing user record is
--                     updated through Supabase Authentication.
-- -----------------------------------------------------------------------------
-- Trigger Context:   Intended to be invoked by an AFTER UPDATE trigger on
--                     auth.users (defined separately in this migration).
-- -----------------------------------------------------------------------------
-- Behavior:
--   * Reads updated identity and metadata values from the modified
--     auth.users record (NEW).
--   * Re-extracts display name and avatar URL from raw_user_meta_data JSONB,
--     ensuring public.users reflects the latest authentication metadata.
--   * Updates the matching public.users row (matched by id) with the
--     refreshed email, name, profile_picture, and updated_at values.
--   * Does not alter role or status, preserving application-managed
--     authorization state independent of authentication metadata changes.
-- -----------------------------------------------------------------------------
-- Security:
--   * SECURITY DEFINER — executes with the privileges of the function owner,
--     allowing updates to public.users regardless of the invoking role's
--     direct table permissions (required since this runs in the auth schema
--     trigger context).
--   * search_path is explicitly locked down to prevent search_path hijacking
--     attacks against SECURITY DEFINER functions.
-- -----------------------------------------------------------------------------
-- Returns:           NEW (required for AFTER UPDATE trigger compatibility)
-- Language:          PL/pgSQL
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_updated_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- -------------------------------------------------------------------
    -- Propagate updated auth.users values into the corresponding
    -- public.users profile record.
    -- -------------------------------------------------------------------
    UPDATE public.users
    SET
        email           = NEW.email,
        name            = NEW.raw_user_meta_data ->> 'full_name',
        profile_picture = NEW.raw_user_meta_data ->> 'avatar_url',
        updated_at      = NOW()
    WHERE id = NEW.id;

    -- Required return value for AFTER UPDATE triggers.
    RETURN NEW;
END;
$$;
-- =============================================================================
-- Trigger:           on_auth_user_created
-- Table:             auth.users
-- Timing:            AFTER INSERT
-- Function:          public.handle_new_user()
-- -----------------------------------------------------------------------------
-- Purpose:           Automatically provisions a corresponding public.users
--                     profile record immediately after a new user is created
--                     in Supabase Authentication.
-- -----------------------------------------------------------------------------
-- Notes:
--   * Dropped and recreated idempotently to support safe re-execution of
--     this migration across environments.
--   * Fires once per row for every new authentication record inserted.
-- =============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- =============================================================================
-- Trigger:           on_auth_user_updated
-- Table:             auth.users
-- Timing:            AFTER UPDATE
-- Function:          public.handle_updated_user()
-- -----------------------------------------------------------------------------
-- Purpose:           Synchronizes profile changes into public.users whenever
--                     an existing Supabase Authentication user record is
--                     updated (e.g. metadata, email changes).
-- -----------------------------------------------------------------------------
-- Notes:
--   * Dropped and recreated idempotently to support safe re-execution of
--     this migration across environments.
--   * Fires once per row for every updated authentication record.
-- =============================================================================

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_user();
-- =============================================================================
-- Section:           Post-Migration Validation
-- Purpose:           Read-only verification queries to confirm that all
--                     objects defined in this migration (V1.0.4__auth_sync.sql)
--                     were created successfully and are correctly attached.
-- -----------------------------------------------------------------------------
-- Notes:
--   * These queries perform no data modification (SELECT only).
--   * Intended for manual review or automated CI/CD post-migration checks.
--   * Safe to execute repeatedly in any environment.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Validation 1: Confirm handle_new_user() function exists
-- -----------------------------------------------------------------------------
SELECT
    n.nspname   AS schema_name,
    p.proname   AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    p.prosecdef AS is_security_definer
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'handle_new_user';


-- -----------------------------------------------------------------------------
-- Validation 2: Confirm handle_updated_user() function exists
-- -----------------------------------------------------------------------------
SELECT
    n.nspname   AS schema_name,
    p.proname   AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    p.prosecdef AS is_security_definer
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'handle_updated_user';


-- -----------------------------------------------------------------------------
-- Validation 3: Confirm authentication triggers exist
--               (on_auth_user_created, on_auth_user_updated)
-- -----------------------------------------------------------------------------
SELECT
    t.tgname        AS trigger_name,
    c.relname       AS table_name,
    n.nspname       AS schema_name,
    CASE t.tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
        ELSE t.tgenabled::text
    END             AS trigger_status
FROM pg_trigger t
JOIN pg_class c  ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'auth'
  AND c.relname = 'users'
  AND t.tgname IN ('on_auth_user_created', 'on_auth_user_updated')
  AND NOT t.tgisinternal;


-- -----------------------------------------------------------------------------
-- Validation 4: Confirm trigger functions are correctly attached
--               to auth.users (trigger -> function mapping)
-- -----------------------------------------------------------------------------
SELECT
    t.tgname                          AS trigger_name,
    c.relname                         AS table_name,
    p.proname                         AS attached_function,
    pn.nspname                        AS function_schema
FROM pg_trigger t
JOIN pg_class c      ON c.oid = t.tgrelid
JOIN pg_namespace n  ON n.oid = c.relnamespace
JOIN pg_proc p       ON p.oid = t.tgfoid
JOIN pg_namespace pn ON pn.oid = p.pronamespace
WHERE n.nspname = 'auth'
  AND c.relname = 'users'
  AND t.tgname IN ('on_auth_user_created', 'on_auth_user_updated')
  AND NOT t.tgisinternal;


-- -----------------------------------------------------------------------------
-- Validation 5: Total count of non-internal triggers on auth.users
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_auth_triggers
FROM pg_trigger t
JOIN pg_class c     ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'auth'
  AND c.relname = 'users'
  AND NOT t.tgisinternal;
-- =============================================================================

