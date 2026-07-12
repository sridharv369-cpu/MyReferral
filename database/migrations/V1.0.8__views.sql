-- ============================================================================
-- Project:           MyReferral
-- Migration:         V1.0.8__views.sql
-- Version:           V1.0.8
-- Description:       Application database views for frontend consumption.
-- ============================================================================
-- Execution Order:   Run after V1.0.7__storage.sql
-- Database Engine:   PostgreSQL 17+
-- Platform:          Supabase
-- ============================================================================
-- Change Log:
--   V1.0.8  -  Initial creation of application-facing database views.
-- ============================================================================
-- Notes:
--   - This migration MUST be applied after V1.0.7__storage.sql has been
--     successfully executed, as views defined herein may depend on storage
--     configuration, schemas, tables, or functions established previously.
--   - Views in this migration are intended strictly for frontend/application
--     consumption and should encapsulate business logic where applicable to
--     minimize client-side query complexity.
--   - Ensure appropriate Row Level Security (RLS) policies and grants are
--     reviewed for any views exposing sensitive or restricted data.
-- ============================================================================
-- ============================================================================
-- View:              vw_referral_feed
-- Purpose:            Homepage referral feed. Provides a consolidated,
--                     read-optimized dataset combining referral post details
--                     with the posting employee's profile information for
--                     frontend consumption on the homepage feed.
-- Base Tables:        referral_posts, users
-- Filter Criteria:    Only active referral posts are returned.
-- Sort Order:         Newest posts first (created_at DESC).
-- ============================================================================
CREATE OR REPLACE VIEW vw_referral_feed AS
SELECT
    rp.id                       AS post_id,
    rp.company_name             AS company_name,
    rp.company_url              AS company_url,
    rp.job_id                   AS job_id,
    rp.role_title               AS role,
    rp.key_skills                AS key_skills,
    rp.location                  AS location,
    rp.country                   AS country,
    rp.work_mode                 AS work_mode,
    rp.job_description           AS job_description,
    u.full_name                  AS employee_name,
    u.profile_picture_url        AS employee_profile_picture,
    rp.like_count                 AS like_count,
    rp.comment_count               AS comment_count,
    rp.referral_request_count       AS referral_request_count,
    rp.created_at                    AS created_date
FROM
    referral_posts rp
INNER JOIN
    users u
    ON u.id = rp.employee_id
WHERE
    rp.is_active = TRUE
ORDER BY
    rp.created_at DESC;
-- ============================================================================
-- View:              vw_my_posts
-- Purpose:            Displays the logged-in user's own referral posts,
--                     including engagement metrics, for use on the
--                     "My Posts" / profile dashboard section of the
--                     frontend application.
-- Base Tables:        referral_posts, users
-- Scope:              Restricted to the currently authenticated user via
--                     Supabase auth.uid(), matched against the post's
--                     owning employee_id.
-- Join Strategy:      LEFT JOIN used to ensure posts are still returned
--                     even if the associated user record is missing or
--                     incomplete, preventing silent data loss.
-- Performance Notes:  Assumes indexes exist on referral_posts.employee_id
--                     and referral_posts.created_at to support efficient
--                     filtering and sort operations.
-- ============================================================================
CREATE OR REPLACE VIEW vw_my_posts AS
SELECT
    rp.company_name                 AS company,
    rp.role_title                   AS role,
    rp.status                       AS status,
    rp.created_at                   AS created_date,
    rp.like_count                   AS like_count,
    rp.comment_count                AS comment_count,
    rp.referral_request_count       AS referral_request_count
FROM
    referral_posts rp
LEFT JOIN
    users u
    ON u.id = rp.employee_id
WHERE
    rp.employee_id = auth.uid()
ORDER BY
    rp.created_at DESC;
-- ============================================================================
-- View:              vw_dashboard
-- Purpose:            Provides an aggregated summary of the logged-in
--                     user's referral activity for display on the
--                     application dashboard landing page.
-- Base Tables:        referral_posts
-- Scope:              Restricted to the currently authenticated user via
--                     Supabase auth.uid(), matched against the post's
--                     owning employee_id.
-- Aggregation Notes:  - Total Posts reflects all posts regardless of status.
--                     - Active/Closed Posts are derived via conditional
--                       aggregation (FILTER clause) for single-pass scan
--                       efficiency.
--                     - Engagement totals (likes, comments, referral
--                       requests) are summed across all owned posts.
--                     - Newest Referral surfaces the most recently created
--                       post's company name for quick reference.
-- Performance Notes:  Assumes indexes exist on referral_posts.employee_id,
--                     referral_posts.status, and referral_posts.created_at
--                     to support efficient filtering and aggregation.
-- ============================================================================
CREATE OR REPLACE VIEW vw_dashboard AS
SELECT
    COUNT(rp.id)                                                  AS total_posts,
    COUNT(rp.id) FILTER (WHERE rp.status = 'active')              AS active_posts,
    COUNT(rp.id) FILTER (WHERE rp.status = 'closed')               AS closed_posts,
    COALESCE(SUM(rp.like_count), 0)                                AS total_likes,
    COALESCE(SUM(rp.comment_count), 0)                             AS total_comments,
    COALESCE(SUM(rp.referral_request_count), 0)                    AS total_referral_requests,
    (
        SELECT rp2.company_name
        FROM referral_posts rp2
        WHERE rp2.employee_id = auth.uid()
        ORDER BY rp2.created_at DESC
        LIMIT 1
    )                                                               AS newest_referral
FROM
    referral_posts rp
WHERE
    rp.employee_id = auth.uid();
-- ============================================================================
-- View:              vw_notifications
-- Purpose:            Displays the logged-in user's notifications for
--                     rendering in the frontend notification center /
--                     bell dropdown component.
-- Base Tables:        notifications
-- Scope:              Restricted to the currently authenticated user via
--                     Supabase auth.uid(), matched against the
--                     notification's owning user_id.
-- Sort Order:         Newest notifications first (created_at DESC).
-- Performance Notes:  Assumes indexes exist on notifications.user_id and
--                     notifications.created_at to support efficient
--                     filtering and sort operations.
-- ============================================================================
CREATE OR REPLACE VIEW vw_notifications AS
SELECT
    n.title              AS notification_title,
    n.message             AS message,
    n.notification_type    AS notification_type,
    n.is_read               AS is_read,
    n.reference_id            AS reference_id,
    n.created_at                AS created_date
FROM
    notifications n
WHERE
    n.user_id = auth.uid()
ORDER BY
    n.created_at DESC;
-- ============================================================================
-- View:              vw_referral_requests
-- Purpose:            Tracks referral requests submitted against referral
--                     posts, consolidating requester identity, employee
--                     (post owner) identity, and job context for use in
--                     request management and tracking screens.
-- Base Tables:        referral_requests, users, referral_posts
-- Join Strategy:      - referral_requests INNER JOIN referral_posts to
--                       resolve company/role context for the requested job.
--                     - referral_requests INNER JOIN users (requester)
--                       to resolve the identity of the requesting user.
--                     - referral_posts INNER JOIN users (employee) to
--                       resolve the identity of the referring employee.
-- Sort Order:         Newest requests first (created_at DESC).
-- Performance Notes:  Assumes indexes exist on referral_requests.post_id,
--                     referral_requests.requester_id, referral_posts.
--                     employee_id, and referral_requests.created_at to
--                     support efficient join and sort operations.
-- ============================================================================
CREATE OR REPLACE VIEW vw_referral_requests AS
SELECT
    requester.full_name        AS requester_name,
    employee.full_name         AS employee_name,
    rp.company_name             AS company,
    rp.role_title                AS role,
    rr.status                     AS status,
    rr.message                     AS message,
    rr.created_at                    AS created_date
FROM
    referral_requests rr
INNER JOIN
    referral_posts rp
    ON rp.id = rr.post_id
INNER JOIN
    users requester
    ON requester.id = rr.requester_id
INNER JOIN
    users employee
    ON employee.id = rp.employee_id
ORDER BY
    rr.created_at DESC;
-- ============================================================================
-- View:              vw_user_profile
-- Purpose:            Provides a consolidated profile summary for the
--                     logged-in user, combining core account details with
--                     aggregated engagement statistics for display on the
--                     frontend profile page.
-- Base Tables:        users, referral_posts
-- Scope:              Restricted to the currently authenticated user via
--                     Supabase auth.uid().
-- Join Strategy:      LEFT JOIN used against referral_posts to ensure the
--                     profile is still returned even if the user has not
--                     yet created any referral posts.
-- Aggregation Notes:  Total Posts, Total Likes Received, and Total
--                     Comments are derived via aggregate functions over
--                     the user's associated referral posts.
-- Performance Notes:  Assumes indexes exist on referral_posts.employee_id
--                     and users.id to support efficient join and
--                     aggregation operations.
-- ============================================================================
CREATE OR REPLACE VIEW vw_user_profile AS
SELECT
    u.full_name                                     AS user_name,
    u.email                                          AS email,
    u.profile_picture_url                             AS profile_picture,
    u.role                                              AS role,
    u.status                                             AS status,
    COUNT(rp.id)                                          AS total_posts,
    COALESCE(SUM(rp.like_count), 0)                        AS total_likes_received,
    COALESCE(SUM(rp.comment_count), 0)                       AS total_comments,
    u.created_at                                              AS joined_date
FROM
    users u
LEFT JOIN
    referral_posts rp
    ON rp.employee_id = u.id
WHERE
    u.id = auth.uid()
GROUP BY
    u.id,
    u.full_name,
    u.email,
    u.profile_picture_url,
    u.role,
    u.status,
    u.created_at;
-- ============================================================================
-- View:              vw_admin_statistics
-- Purpose:            Provides platform-wide aggregated statistics for the
--                     administrative dashboard, offering a single-row
--                     summary of key operational metrics across users,
--                     posts, engagement, and notifications.
-- Base Tables:        users, referral_posts, referral_requests,
--                     notifications
-- Access Scope:       Intended for administrative roles only. Access
--                     control should be enforced via RLS policies or
--                     application-layer authorization checks, as this
--                     view exposes platform-wide aggregate data.
-- Aggregation Notes:  Independent scalar subqueries are used per metric
--                     to avoid cartesian product inflation that would
--                     otherwise occur from joining multiple one-to-many
--                     tables in a single FROM clause.
-- Performance Notes:  Assumes indexes exist on users.status,
--                     referral_posts.status, referral_requests.id, and
--                     notifications.id to support efficient aggregate
--                     scans.
-- ============================================================================
CREATE OR REPLACE VIEW vw_admin_statistics AS
SELECT
    (SELECT COUNT(*) FROM users)                                          AS total_users,
    (SELECT COUNT(*) FROM users WHERE status = 'active')                  AS total_active_users,
    (SELECT COUNT(*) FROM referral_posts)                                 AS total_posts,
    (SELECT COUNT(*) FROM referral_posts WHERE is_active = TRUE)          AS total_active_posts,
    (SELECT COALESCE(SUM(comment_count), 0) FROM referral_posts)         AS total_comments,
    (SELECT COALESCE(SUM(like_count), 0) FROM referral_posts)             AS total_likes,
    (SELECT COUNT(*) FROM referral_requests)                               AS total_referral_requests,
    (SELECT COUNT(*) FROM notifications)                                    AS total_notifications;
-- ============================================================================
-- Section:           Post-Deployment Validation
-- Purpose:            Read-only verification queries to confirm that all
--                     views defined in this migration have been created
--                     successfully, are structurally sound, and are
--                     queryable prior to promoting this migration through
--                     downstream environments.
-- Execution Notes:    These statements perform NO data mutation (DDL or
--                     DML). They are safe to execute in any environment,
--                     including production, for verification purposes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Validation 1: Confirm all expected views exist in the current schema.
-- ----------------------------------------------------------------------------
SELECT
    table_schema,
    table_name AS view_name,
    table_type
FROM
    information_schema.tables
WHERE
    table_schema = 'public'
    AND table_type = 'VIEW'
    AND table_name IN (
        'vw_referral_feed',
        'vw_my_posts',
        'vw_dashboard',
        'vw_notifications',
        'vw_referral_requests',
        'vw_user_profile',
        'vw_admin_statistics'
    )
ORDER BY
    table_name;

-- ----------------------------------------------------------------------------
-- Validation 2: Retrieve full view definitions for review and audit.
-- ----------------------------------------------------------------------------
SELECT
    schemaname,
    viewname,
    definition
FROM
    pg_views
WHERE
    schemaname = 'public'
    AND viewname IN (
        'vw_referral_feed',
        'vw_my_posts',
        'vw_dashboard',
        'vw_notifications',
        'vw_referral_requests',
        'vw_user_profile',
        'vw_admin_statistics'
    )
ORDER BY
    viewname;

-- ----------------------------------------------------------------------------
-- Validation 3: Identify view dependencies on base tables/columns to
--               confirm referential integrity and catch any orphaned or
--               broken view references.
-- ----------------------------------------------------------------------------
SELECT
    dependent_view.relname             AS view_name,
    source_table.relname               AS depends_on_table,
    pg_attribute.attname               AS depends_on_column
FROM
    pg_depend
JOIN
    pg_rewrite
    ON pg_depend.objid = pg_rewrite.oid
JOIN
    pg_class AS dependent_view
    ON pg_rewrite.ev_class = dependent_view.oid
JOIN
    pg_class AS source_table
    ON pg_depend.refobjid = source_table.oid
JOIN
    pg_attribute
    ON pg_attribute.attrelid = source_table.oid
    AND pg_attribute.attnum = pg_depend.refobjsubid
WHERE
    dependent_view.relkind = 'v'
    AND source_table.relkind IN ('r', 'v')
    AND dependent_view.relname IN (
        'vw_referral_feed',
        'vw_my_posts',
        'vw_dashboard',
        'vw_notifications',
        'vw_referral_requests',
        'vw_user_profile',
        'vw_admin_statistics'
    )
ORDER BY
    dependent_view.relname,
    source_table.relname;

-- ----------------------------------------------------------------------------
-- Validation 4: Confirm the total number of views created by this
--               migration matches the expected count (7).
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_views_created
FROM
    information_schema.tables
WHERE
    table_schema = 'public'
    AND table_type = 'VIEW'
    AND table_name IN (
        'vw_referral_feed',
        'vw_my_posts',
        'vw_dashboard',
        'vw_notifications',
        'vw_referral_requests',
        'vw_user_profile',
        'vw_admin_statistics'
    );

-- ----------------------------------------------------------------------------
-- Validation 5: Execute a lightweight test SELECT against every view to
--               confirm each is queryable without runtime errors.
-- ----------------------------------------------------------------------------
SELECT * FROM vw_referral_feed        LIMIT 1;
SELECT * FROM vw_my_posts             LIMIT 1;
SELECT * FROM vw_dashboard            LIMIT 1;
SELECT * FROM vw_notifications        LIMIT 1;
SELECT * FROM vw_referral_requests    LIMIT 1;
SELECT * FROM vw_user_profile         LIMIT 1;
SELECT * FROM vw_admin_statistics     LIMIT 1;
-- ===========================================================================
