-- =============================================================================
-- Project:            MyReferral
-- Migration:          V1.0.3__triggers.sql
-- Version:            V1.0.3
-- Description:        Database triggers for audit fields and search vector
--                      maintenance.
-- =============================================================================
-- Target Platform:    PostgreSQL 17+
-- Compatibility:       Supabase
-- =============================================================================
-- Execution Order:
--   This migration MUST be executed after V1.0.2__functions.sql
--   Dependency:  V1.0.2__functions.sql (trigger functions must exist prior
--                to trigger attachment defined in this migration)
-- =============================================================================
-- Change Control:
--   Author:            Database Architecture Team
--   Review Status:     Pending Review
--   Rollback Strategy: Refer to corresponding down-migration script
--                      (V1.0.3__triggers_rollback.sql), if applicable
-- =============================================================================
-- =============================================================================
-- Trigger:            trg_users_updated_at
-- Table:              public.users
-- Purpose:            Automatically maintain the updated_at audit column by
--                      setting it to the current timestamp before every row
--                      update, ensuring accurate change-tracking metadata
--                      without relying on application-layer logic.
-- Timing:             BEFORE UPDATE
-- Scope:              FOR EACH ROW
-- Executes Function:  update_updated_at_column()
-- Dependency:         Requires update_updated_at_column() to be defined in
--                      V1.0.2__functions.sql prior to execution.
-- =============================================================================

-- Drop existing trigger (if any) to allow safe re-deployment / idempotent runs
DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;

-- Create trigger to auto-update the updated_at column on row modification
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Trigger:            trg_referral_posts_updated_at
-- Table:              public.referral_posts
-- Purpose:            Automatically maintain the updated_at audit column by
--                      setting it to the current timestamp before every row
--                      update, ensuring accurate change-tracking metadata
--                      without relying on application-layer logic.
-- Timing:             BEFORE UPDATE
-- Scope:              FOR EACH ROW
-- Executes Function:  update_updated_at_column()
-- Dependency:         Requires update_updated_at_column() to be defined in
--                      V1.0.2__functions.sql prior to execution.
-- =============================================================================

-- Drop existing trigger (if any) to allow safe re-deployment / idempotent runs
DROP TRIGGER IF EXISTS trg_referral_posts_updated_at ON public.referral_posts;

-- Create trigger to auto-update the updated_at column on row modification
CREATE TRIGGER trg_referral_posts_updated_at
    BEFORE UPDATE ON public.referral_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Trigger:            trg_referral_posts_search_vector
-- Table:              public.referral_posts
-- Purpose:            Automatically maintain the search_vector column,
--                      recomputing full-text search indexing data on both
--                      insertion of new records and modification of existing
--                      records, ensuring search indexes remain synchronized
--                      with source content at all times.
-- Timing:             BEFORE INSERT OR UPDATE
-- Scope:              FOR EACH ROW
-- Executes Function:  update_search_vector()
-- Dependency:         Requires update_search_vector() to be defined in
--                      V1.0.2__functions.sql prior to execution.
-- =============================================================================

-- Drop existing trigger (if any) to allow safe re-deployment / idempotent runs
DROP TRIGGER IF EXISTS trg_referral_posts_search_vector ON public.referral_posts;

-- Create trigger to auto-maintain the search_vector column
CREATE TRIGGER trg_referral_posts_search_vector
    BEFORE INSERT OR UPDATE ON public.referral_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_search_vector();
-- =============================================================================
-- Trigger:            trg_comments_updated_at
-- Table:              public.comments
-- Purpose:            Automatically maintain the updated_at audit column by
--                      setting it to the current timestamp before every row
--                      update, ensuring accurate change-tracking metadata
--                      without relying on application-layer logic.
-- Timing:             BEFORE UPDATE
-- Scope:              FOR EACH ROW
-- Executes Function:  update_updated_at_column()
-- Dependency:         Requires update_updated_at_column() to be defined in
--                      V1.0.2__functions.sql prior to execution.
-- =============================================================================

-- Drop existing trigger (if any) to allow safe re-deployment / idempotent runs
DROP TRIGGER IF EXISTS trg_comments_updated_at ON public.comments;

-- Create trigger to auto-update the updated_at column on row modification
CREATE TRIGGER trg_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
-- =============================================================================
-- Trigger:            trg_referral_requests_updated_at
-- Table:              public.referral_requests
-- Purpose:            Automatically maintain the updated_at audit column by
--                      setting it to the current timestamp before every row
--                      update, ensuring accurate change-tracking metadata
--                      without relying on application-layer logic.
-- Timing:             BEFORE UPDATE
-- Scope:              FOR EACH ROW
-- Executes Function:  update_updated_at_column()
-- Dependency:         Requires update_updated_at_column() to be defined in
--                      V1.0.2__functions.sql prior to execution.
-- =============================================================================

-- Drop existing trigger (if any) to allow safe re-deployment / idempotent runs
DROP TRIGGER IF EXISTS trg_referral_requests_updated_at ON public.referral_requests;

-- Create trigger to auto-update the updated_at column on row modification
CREATE TRIGGER trg_referral_requests_updated_at
    BEFORE UPDATE ON public.referral_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
-- =============================================================================
-- Validation Section
-- Purpose:            Post-deployment verification queries to confirm that
--                      all triggers defined in this migration have been
--                      created successfully, with correct naming, timing,
--                      event scope, associated function bindings, and target
--                      tables. These queries are strictly READ-ONLY and
--                      perform no data or schema modifications.
-- Usage:              Execute manually or as part of CI/CD post-migration
--                      verification steps.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Verify all expected triggers exist
-- -----------------------------------------------------------------------------
SELECT
    trigger_name,
    event_object_table AS table_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
        'trg_users_updated_at',
        'trg_referral_posts_updated_at',
        'trg_referral_posts_search_vector',
        'trg_comments_updated_at',
        'trg_referral_requests_updated_at'
  )
ORDER BY event_object_table, trigger_name;

-- -----------------------------------------------------------------------------
-- 2. Verify trigger names (distinct listing for cross-check)
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN (
        'users',
        'referral_posts',
        'comments',
        'referral_requests'
  )
ORDER BY trigger_name;

-- -----------------------------------------------------------------------------
-- 3. Verify trigger timing (e.g., BEFORE, AFTER)
-- -----------------------------------------------------------------------------
SELECT
    trigger_name,
    event_object_table AS table_name,
    action_timing AS trigger_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN (
        'users',
        'referral_posts',
        'comments',
        'referral_requests'
  )
ORDER BY event_object_table, trigger_name;

-- -----------------------------------------------------------------------------
-- 4. Verify trigger events (e.g., INSERT, UPDATE)
-- -----------------------------------------------------------------------------
SELECT
    trigger_name,
    event_object_table AS table_name,
    event_manipulation AS trigger_event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN (
        'users',
        'referral_posts',
        'comments',
        'referral_requests'
  )
ORDER BY event_object_table, trigger_name, event_manipulation;

-- -----------------------------------------------------------------------------
-- 5. Verify trigger-to-function bindings
-- -----------------------------------------------------------------------------
SELECT
    t.tgname AS trigger_name,
    c.relname AS table_name,
    p.proname AS function_name
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_proc p ON p.oid = t.tgfoid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
  AND c.relname IN (
        'users',
        'referral_posts',
        'comments',
        'referral_requests'
  )
ORDER BY c.relname, t.tgname;

-- -----------------------------------------------------------------------------
-- 6. Verify target table names associated with each trigger
-- -----------------------------------------------------------------------------
SELECT
    event_object_table AS table_name,
    COUNT(*) AS trigger_count
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND event_object_table IN (
        'users',
        'referral_posts',
        'comments',
        'referral_requests'
  )
GROUP BY event_object_table
ORDER BY event_object_table;
-- ================================================================================
