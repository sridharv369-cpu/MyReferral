-- ============================================================================
-- Project Name:      MyReferral
-- Migration Version: V1.0.1
-- File:              database/migrations/V1.0.1__indexes.sql
-- ============================================================================
-- Description:
--     Performance indexes for all database tables.
-- ============================================================================
-- Database:          PostgreSQL 17+
-- Platform:          Supabase
-- ============================================================================
-- Author:            <PLACEHOLDER_AUTHOR>
-- Created Date:      <PLACEHOLDER_DATE>
-- ============================================================================
-- Execution Order:
--     Run only after V1.0.0 has been successfully applied.
--     Do not execute this migration out of sequence.
-- ============================================================================
-- ============================================================================
-- Table: users
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_users_email
    ON public.users (email);

CREATE INDEX IF NOT EXISTS idx_users_role
    ON public.users (role);

CREATE INDEX IF NOT EXISTS idx_users_status
    ON public.users (status);

CREATE INDEX IF NOT EXISTS idx_users_created_at
    ON public.users (created_at);
-- ============================================================================
-- Table: referral_posts
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_referral_posts_user_id
    ON public.referral_posts (user_id);

CREATE INDEX IF NOT EXISTS idx_referral_posts_company_name
    ON public.referral_posts (company_name);

CREATE INDEX IF NOT EXISTS idx_referral_posts_job_id
    ON public.referral_posts (job_id);

CREATE INDEX IF NOT EXISTS idx_referral_posts_location
    ON public.referral_posts (location);

CREATE INDEX IF NOT EXISTS idx_referral_posts_country
    ON public.referral_posts (country);

CREATE INDEX IF NOT EXISTS idx_referral_posts_work_mode
    ON public.referral_posts (work_mode);

CREATE INDEX IF NOT EXISTS idx_referral_posts_status
    ON public.referral_posts (status);

CREATE INDEX IF NOT EXISTS idx_referral_posts_created_at
    ON public.referral_posts (created_at);

CREATE INDEX IF NOT EXISTS idx_referral_posts_updated_at
    ON public.referral_posts (updated_at);

CREATE INDEX IF NOT EXISTS idx_referral_posts_search
    ON public.referral_posts
    USING GIN (search_vector);
-- ============================================================================
-- Table: comments
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_comments_post_id
    ON public.comments (post_id);

CREATE INDEX IF NOT EXISTS idx_comments_user_id
    ON public.comments (user_id);

CREATE INDEX IF NOT EXISTS idx_comments_created_at
    ON public.comments (created_at);
-- ============================================================================
-- Table: likes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_likes_post_id
    ON public.likes (post_id);

CREATE INDEX IF NOT EXISTS idx_likes_user_id
    ON public.likes (user_id);

CREATE INDEX IF NOT EXISTS idx_likes_created_at
    ON public.likes (created_at);
-- ============================================================================
-- Table: referral_requests
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_referral_requests_post_id
    ON public.referral_requests (post_id);

CREATE INDEX IF NOT EXISTS idx_referral_requests_requester_id
    ON public.referral_requests (requester_id);

CREATE INDEX IF NOT EXISTS idx_referral_requests_employee_id
    ON public.referral_requests (employee_id);

CREATE INDEX IF NOT EXISTS idx_referral_requests_status
    ON public.referral_requests (status);

CREATE INDEX IF NOT EXISTS idx_referral_requests_created_at
    ON public.referral_requests (created_at);

CREATE INDEX IF NOT EXISTS idx_referral_requests_updated_at
    ON public.referral_requests (updated_at);
-- ============================================================================
-- Table: notifications
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_notifications_user_id
    ON public.notifications (user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_notification_type
    ON public.notifications (notification_type);

CREATE INDEX IF NOT EXISTS idx_notifications_is_read
    ON public.notifications (is_read);

CREATE INDEX IF NOT EXISTS idx_notifications_created_at
    ON public.notifications (created_at);
-- ============================================================================
-- VALIDATION SECTION
-- ============================================================================
-- Purpose:
--     Read-only verification queries to confirm successful and consistent
--     application of this migration. These queries perform no data or
--     schema modifications and are safe to run in any environment.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Total Indexes Created
-- ----------------------------------------------------------------------------
-- Purpose: Returns the total count of indexes prefixed with 'idx_' in the
--          public schema, confirming overall migration coverage.
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_indexes_created
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    AND indexname LIKE 'idx_%';

-- ----------------------------------------------------------------------------
-- 2. Index Names
-- ----------------------------------------------------------------------------
-- Purpose: Lists all index names, their parent tables, and definitions for
--          manual review and audit purposes.
-- ----------------------------------------------------------------------------
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    AND indexname LIKE 'idx_%'
ORDER BY
    tablename,
    indexname;

-- ----------------------------------------------------------------------------
-- 3. GIN Index Verification on referral_posts.search_vector
-- ----------------------------------------------------------------------------
-- Purpose: Confirms that idx_referral_posts_search exists and uses the GIN
--          access method as required for full-text search performance.
-- ----------------------------------------------------------------------------
SELECT
    i.relname  AS index_name,
    t.relname  AS table_name,
    am.amname  AS index_type
FROM
    pg_class i
    JOIN pg_index ix ON i.oid = ix.indexrelid
    JOIN pg_class t ON t.oid = ix.indrelid
    JOIN pg_am am ON i.relam = am.oid
    JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE
    n.nspname = 'public'
    AND t.relname = 'referral_posts'
    AND i.relname = 'idx_referral_posts_search'
    AND am.amname = 'gin';

-- ----------------------------------------------------------------------------
-- 4. Duplicate Index Detection
-- ----------------------------------------------------------------------------
-- Purpose: Identifies indexes on the same table with identical underlying
--          column definitions, which may indicate redundant or duplicate
--          index creation.
-- ----------------------------------------------------------------------------
SELECT
    tablename,
    indexdef,
    COUNT(*) AS duplicate_count
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    AND indexname LIKE 'idx_%'
GROUP BY
    tablename,
    indexdef
HAVING
    COUNT(*) > 1;

-- ----------------------------------------------------------------------------
-- 5. Table-wise Index Count
-- ----------------------------------------------------------------------------
-- Purpose: Provides a per-table summary of index counts to validate that
--          each table received its expected set of performance indexes.
-- ----------------------------------------------------------------------------
SELECT
    tablename,
    COUNT(*) AS index_count
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    AND indexname LIKE 'idx_%'
GROUP BY
    tablename
ORDER BY
    tablename;
