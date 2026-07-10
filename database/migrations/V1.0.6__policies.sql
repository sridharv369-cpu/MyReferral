-- =============================================================================
-- Project:          MyReferral
-- Migration:         V1.0.6__policies.sql
-- Version:           V1.0.6
-- Description:       Row Level Security (RLS) policies for all application
--                     tables.
-- =============================================================================
-- Execution Order:   Run AFTER V1.0.5__rls.sql
--                     (RLS must be enabled on target tables prior to policy
--                     definition; this migration assumes ALTER TABLE ...
--                     ENABLE ROW LEVEL SECURITY has already been applied).
-- =============================================================================
-- Target Engine:     PostgreSQL 17+
-- Compatibility:     Supabase (auth.uid(), auth.role(), auth.jwt())
-- =============================================================================
-- Author:            Database Engineering Team
-- Reviewed By:        Senior PostgreSQL Security Architect
-- =============================================================================
-- Notes:
--   * This migration is idempotent-safe where applicable (CREATE POLICY IF
--     NOT EXISTS patterns / DROP POLICY IF EXISTS guards to be applied per
--     policy block).
--   * Policies defined herein govern SELECT / INSERT / UPDATE / DELETE
--     access at the row level for all application tables within the public
--     schema.
--   * No schema, table, or RLS enablement changes are made in this
--     migration; only policy objects are created.
--   * Rollback strategy: corresponding DOWN migration (if applicable) must
--     DROP POLICY for each object created here.
-- =============================================================================
-- =============================================================================
-- Table:  public.users
-- Policies: SELECT (own row), UPDATE (own row), DELETE (blocked),
--           INSERT (restricted to trigger-based provisioning only)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: users_select_own
-- Purpose: Authenticated users may SELECT only their own profile record.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS users_select_own ON public.users;

CREATE POLICY users_select_own
    ON public.users
    FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: users_update_own
-- Purpose: Authenticated users may UPDATE only their own profile record.
--          USING clause restricts which rows are targetable; WITH CHECK
--          clause prevents re-pointing the row to another identity.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS users_update_own ON public.users;

CREATE POLICY users_update_own
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: users_delete_blocked
-- Purpose: Explicitly deny DELETE for all authenticated users. No row ever
--          satisfies the USING predicate, ensuring deletions are blocked
--          regardless of ownership.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS users_delete_blocked ON public.users;

CREATE POLICY users_delete_blocked
    ON public.users
    FOR DELETE
    TO authenticated
    USING (false);

-- -----------------------------------------------------------------------------
-- Policy: users_insert_blocked
-- Purpose: Direct INSERT by authenticated users is explicitly denied.
--          Row provisioning is performed exclusively via the
--          authentication trigger (SECURITY DEFINER context), which
--          bypasses RLS and is not subject to this policy.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS users_insert_blocked ON public.users;

CREATE POLICY users_insert_blocked
    ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (false);
-- =============================================================================
-- Table:  public.referral_posts
-- Policies: SELECT (active posts, public), INSERT (own), UPDATE (own),
--           DELETE (own)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: referral_posts_select_active
-- Purpose: Both anonymous and authenticated roles may SELECT only referral
--          posts flagged as active. Inactive/archived posts remain hidden
--          from public read access.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_posts_select_active ON public.referral_posts;

CREATE POLICY referral_posts_select_active
    ON public.referral_posts
    FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

-- -----------------------------------------------------------------------------
-- Policy: referral_posts_insert_own
-- Purpose: Authenticated users may INSERT referral posts only when the
--          post's owning user_id matches their own identity.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_posts_insert_own ON public.referral_posts;

CREATE POLICY referral_posts_insert_own
    ON public.referral_posts
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: referral_posts_update_own
-- Purpose: Authenticated users may UPDATE only referral posts they own.
--          USING restricts targetable rows; WITH CHECK prevents
--          reassigning ownership to another user during the update.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_posts_update_own ON public.referral_posts;

CREATE POLICY referral_posts_update_own
    ON public.referral_posts
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: referral_posts_delete_own
-- Purpose: Authenticated users may DELETE only referral posts they own.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_posts_delete_own ON public.referral_posts;

CREATE POLICY referral_posts_delete_own
    ON public.referral_posts
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());
-- =============================================================================
-- Table:  public.comments
-- Policies: SELECT (public), INSERT (authenticated), UPDATE (own),
--           DELETE (own)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: comments_select_all
-- Purpose: Both anonymous and authenticated roles may SELECT all comments.
--          Comments are considered public content within the application.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS comments_select_all ON public.comments;

CREATE POLICY comments_select_all
    ON public.comments
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- -----------------------------------------------------------------------------
-- Policy: comments_insert_authenticated
-- Purpose: Authenticated users may INSERT comments, provided the comment's
--          owning user_id matches their own identity.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS comments_insert_authenticated ON public.comments;

CREATE POLICY comments_insert_authenticated
    ON public.comments
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: comments_update_own
-- Purpose: Authenticated users may UPDATE only comments they own. USING
--          restricts targetable rows; WITH CHECK prevents reassigning
--          ownership to another user during the update.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS comments_update_own ON public.comments;

CREATE POLICY comments_update_own
    ON public.comments
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: comments_delete_own
-- Purpose: Authenticated users may DELETE only comments they own.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS comments_delete_own ON public.comments;

CREATE POLICY comments_delete_own
    ON public.comments
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());
-- =============================================================================
-- Table:  public.likes
-- Policies: SELECT (public), INSERT (authenticated), UPDATE (blocked),
--           DELETE (own)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: likes_select_all
-- Purpose: Both anonymous and authenticated roles may SELECT all likes.
--          Like counts/records are considered public content.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS likes_select_all ON public.likes;

CREATE POLICY likes_select_all
    ON public.likes
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- -----------------------------------------------------------------------------
-- Policy: likes_insert_authenticated
-- Purpose: Authenticated users may INSERT likes, provided the like's
--          owning user_id matches their own identity.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS likes_insert_authenticated ON public.likes;

CREATE POLICY likes_insert_authenticated
    ON public.likes
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: likes_update_blocked
-- Purpose: Explicitly deny UPDATE for all authenticated users. Likes are
--          immutable records; no row ever satisfies the USING predicate.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS likes_update_blocked ON public.likes;

CREATE POLICY likes_update_blocked
    ON public.likes
    FOR UPDATE
    TO authenticated
    USING (false);

-- -----------------------------------------------------------------------------
-- Policy: likes_delete_own
-- Purpose: Authenticated users may DELETE only likes they own.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS likes_delete_own ON public.likes;

CREATE POLICY likes_delete_own
    ON public.likes
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());
-- =============================================================================
-- Table:  public.referral_requests
-- Policies: SELECT (requester own / employee for their posts),
--           INSERT (requester), UPDATE (employee - status),
--           DELETE (requester - pending only)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: referral_requests_select_requester
-- Purpose: Authenticated users may SELECT referral requests they themselves
--          submitted as the requester.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_requests_select_requester ON public.referral_requests;

CREATE POLICY referral_requests_select_requester
    ON public.referral_requests
    FOR SELECT
    TO authenticated
    USING (requester_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: referral_requests_select_employee
-- Purpose: Authenticated users may SELECT referral requests submitted
--          against referral posts they own (i.e. the employee who
--          created the referral post). Ownership is verified via an
--          EXISTS subquery against public.referral_posts.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_requests_select_employee ON public.referral_requests;

CREATE POLICY referral_requests_select_employee
    ON public.referral_requests
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.referral_posts rp
            WHERE rp.id = referral_requests.referral_post_id
              AND rp.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------------------------------
-- Policy: referral_requests_insert_requester
-- Purpose: Authenticated users may INSERT referral requests only as the
--          requester themselves; requester_id must match auth.uid().
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_requests_insert_requester ON public.referral_requests;

CREATE POLICY referral_requests_insert_requester
    ON public.referral_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (requester_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: referral_requests_update_employee
-- Purpose: Authenticated users may UPDATE (e.g. status transitions) only
--          on referral requests submitted against referral posts they
--          own as the employee. USING restricts targetable rows; WITH
--          CHECK enforces the same ownership constraint post-update to
--          prevent reassignment to an unrelated post.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_requests_update_employee ON public.referral_requests;

CREATE POLICY referral_requests_update_employee
    ON public.referral_requests
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.referral_posts rp
            WHERE rp.id = referral_requests.referral_post_id
              AND rp.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.referral_posts rp
            WHERE rp.id = referral_requests.referral_post_id
              AND rp.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------------------------------
-- Policy: referral_requests_delete_requester_pending
-- Purpose: Authenticated users may DELETE only their own referral requests,
--          and only while the request remains in a 'pending' status.
--          Requests already processed (accepted/rejected) are immutable
--          from the requester's perspective.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS referral_requests_delete_requester_pending ON public.referral_requests;

CREATE POLICY referral_requests_delete_requester_pending
    ON public.referral_requests
    FOR DELETE
    TO authenticated
    USING (
        requester_id = auth.uid()
        AND status = 'pending'
    );
-- =============================================================================
-- Table:  public.notifications
-- Policies: SELECT (own), UPDATE (own - is_read only), INSERT (blocked for
--           authenticated; system-level insertion only), DELETE (blocked)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Policy: notifications_select_own
-- Purpose: Authenticated users may SELECT only notifications addressed to
--          themselves.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notifications_select_own ON public.notifications;

CREATE POLICY notifications_select_own
    ON public.notifications
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: notifications_update_own
-- Purpose: Authenticated users may UPDATE only their own notification
--          records. Row-level ownership is enforced here via USING /
--          WITH CHECK; restriction to the is_read column specifically
--          must be enforced at the column-privilege level (e.g. via
--          GRANT UPDATE (is_read) ON public.notifications TO authenticated,
--          combined with a protective BEFORE UPDATE trigger) since RLS
--          policies operate at row granularity, not column granularity.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notifications_update_own ON public.notifications;

CREATE POLICY notifications_update_own
    ON public.notifications
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Policy: notifications_insert_blocked
-- Purpose: Explicitly deny direct INSERT by authenticated users. Notification
--          records are provisioned exclusively by trusted system functions
--          (e.g. SECURITY DEFINER triggers/functions on referral_requests,
--          comments, likes), which bypass RLS and are not subject to this
--          policy.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notifications_insert_blocked ON public.notifications;

CREATE POLICY notifications_insert_blocked
    ON public.notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (false);

-- -----------------------------------------------------------------------------
-- Policy: notifications_delete_blocked
-- Purpose: Explicitly deny DELETE for all authenticated users. No row ever
--          satisfies the USING predicate, ensuring notification history
--          remains intact and is managed exclusively via system-level
--          retention/cleanup routines.
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS notifications_delete_blocked ON public.notifications;

CREATE POLICY notifications_delete_blocked
    ON public.notifications
    FOR DELETE
    TO authenticated
    USING (false);
-- =============================================================================
-- Validation Section
-- Purpose: Read-only verification queries to confirm that all RLS policies
--          defined in this migration were created successfully. These
--          queries perform no data mutation and are safe to run in any
--          environment (development, staging, production) post-migration.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Validation 1: Confirm existence of all expected RLS policies
-- Purpose: Lists every policy currently registered against application
--          tables within the public schema, confirming successful
--          creation by this migration.
-- -----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    policyname,
    cmd
FROM
    pg_policies
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    cmd,
    policyname;

-- -----------------------------------------------------------------------------
-- Validation 2: Policy names per table
-- Purpose: Enumerates policy names grouped by their owning table for quick
--          cross-reference against this migration's defined policy set.
-- -----------------------------------------------------------------------------
SELECT
    tablename,
    policyname
FROM
    pg_policies
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    policyname;

-- -----------------------------------------------------------------------------
-- Validation 3: Distinct table names covered by RLS policies
-- Purpose: Confirms that policies exist across all expected application
--          tables (users, referral_posts, comments, likes,
--          referral_requests, notifications).
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    tablename
FROM
    pg_policies
WHERE
    schemaname = 'public'
ORDER BY
    tablename;

-- -----------------------------------------------------------------------------
-- Validation 4: Policy commands per table
-- Purpose: Confirms which command types (SELECT, INSERT, UPDATE, DELETE)
--          are governed by policies on each table, cross-referenced
--          against this migration's requirements.
-- -----------------------------------------------------------------------------
SELECT
    tablename,
    cmd AS policy_command,
    policyname
FROM
    pg_policies
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    cmd;

-- -----------------------------------------------------------------------------
-- Validation 5: Number of policies per table
-- Purpose: Aggregates policy counts per table to confirm expected policy
--          density (e.g. users = 4, referral_posts = 4, comments = 4,
--          likes = 4, referral_requests = 5, notifications = 4).
-- -----------------------------------------------------------------------------
SELECT
    tablename,
    COUNT(*) AS policy_count
FROM
    pg_policies
WHERE
    schemaname = 'public'
GROUP BY
    tablename
ORDER BY
    tablename;

-- -----------------------------------------------------------------------------
-- Validation 6: Total policy count across all application tables
-- Purpose: Provides a single aggregate figure representing the total
--          number of RLS policies established by this migration, for
--          reconciliation against the expected total.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_policy_count
FROM
    pg_policies
WHERE
    schemaname = 'public';
-- ======================================================================
