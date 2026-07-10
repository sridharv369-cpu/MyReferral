-- =============================================================================
-- Project:            MyReferral
-- Migration Version:  V1.0.2
-- File:               database/migrations/V1.0.2__functions.sql
-- Description:        Database reusable functions
-- =============================================================================
-- Author:             Database Architecture Team
-- Created:            2026-07-04
-- =============================================================================
-- Target Platform:    PostgreSQL 17+
-- Compatibility:      Supabase (Postgres-as-a-Service)
-- =============================================================================
-- Execution Order:
--   This migration MUST be executed AFTER:
--     -> V1.0.1__indexes.sql
--
--   Rationale:
--     Reusable functions defined in this migration may reference tables,
--     columns, and/or indexes established in prior migrations. Indexes
--     from V1.0.1 are assumed to exist prior to function creation to
--     ensure query planner behavior and function performance
--     characteristics (e.g., index-backed lookups within PL/pgSQL logic)
--     are consistent and validated at deployment time.
-- =============================================================================
-- Notes:
--   - This file is idempotent-safe where applicable (CREATE OR REPLACE).
--   - Functions defined here are intended for reuse across triggers,
--     RPC calls (Supabase), views, and application-layer queries.
--   - Adheres to principle of least privilege; execution grants, if any,
--     should be scoped explicitly and are NOT assumed by default.
--   - No DDL for tables/indexes/constraints should be introduced in this
--     file; scope is strictly limited to function/procedure definitions.
-- =============================================================================
-- Rollback Strategy:
--   Corresponding DROP FUNCTION statements should be maintained in the
--   associated rollback script (e.g., U1.0.2__functions.sql) to support
--   safe migration reversal.
-- =============================================================================
-- =============================================================================
-- Function:            update_updated_at_column()
-- Purpose:             Automatically maintains the "updated_at" timestamp
--                       column on any table that includes it, by setting it
--                       to the current transaction timestamp whenever a row
--                       is modified via an UPDATE operation.
-- =============================================================================
-- Usage:
--   Intended to be invoked from a BEFORE UPDATE row-level trigger on any
--   table containing an "updated_at" column of type TIMESTAMPTZ.
--
-- Behavior:
--   - Sets NEW.updated_at to the current statement/transaction timestamp
--     (clock_timestamp() is intentionally avoided to preserve consistent
--     timestamps within the same transaction; now() is used instead).
--   - Leaves all other columns of NEW unmodified.
--   - Has no effect on INSERT operations (trigger scope responsibility).
--
-- Return Type:
--   TRIGGER — required for use within trigger execution context.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, consistent with least-privilege principles.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_updated_at_column() IS
    'Utility trigger function: automatically sets updated_at = now() on row UPDATE. Attach via BEFORE UPDATE trigger to any table with an updated_at TIMESTAMPTZ column.';


-- =============================================================================
-- Function:            update_search_vector()
-- Purpose:             Automatically populates a full-text search vector
--                       column ("search_vector") by aggregating and
--                       weighting content from the following source
--                       columns:
--                         - company_name  (Weight A - highest relevance)
--                         - role          (Weight A - highest relevance)
--                         - key_skills    (Weight B - medium relevance)
--                         - location      (Weight C - lower relevance)
-- =============================================================================
-- Usage:
--   Intended to be invoked from a BEFORE INSERT OR UPDATE row-level
--   trigger on any table containing a "search_vector" column of type
--   TSVECTOR, along with the source columns listed above.
--
-- Behavior:
--   - Uses to_tsvector() with the 'english' text search configuration.
--   - Applies setweight() to prioritize company_name and role over
--     key_skills, and key_skills over location, optimizing relevance
--     ranking for downstream full-text search queries (e.g., ts_rank).
--   - Handles NULL source columns gracefully via COALESCE to prevent
--     NULL propagation into the concatenated tsvector expression.
--   - key_skills is assumed to be of type TEXT or TEXT[]; array inputs
--     are flattened via array_to_string() prior to vectorization.
--
-- Return Type:
--   TRIGGER — required for use within trigger execution context.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, consistent with least-privilege principles.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Maintenance Note:
--   If additional searchable columns are introduced in future schema
--   revisions, this function must be updated accordingly and the
--   search_vector column repopulated for existing rows.
-- =============================================================================
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.company_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.role, '')), 'A') ||
        setweight(
            to_tsvector(
                'english',
                COALESCE(
                    CASE
                        WHEN pg_typeof(NEW.key_skills) = 'text[]'::regtype
                            THEN array_to_string(NEW.key_skills, ' ')
                        ELSE NEW.key_skills::text
                    END,
                    ''
                )
            ),
            'B'
        ) ||
        setweight(to_tsvector('english', COALESCE(NEW.location, '')), 'C');

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_search_vector() IS
    'Utility trigger function: builds a weighted tsvector into search_vector from 
  company_name, role, key_skills, and location. Attach via BEFORE INSERT OR UPDATE trigger to enable full-text search.';
-- =============================================================================
-- Function:            create_notification()
-- Purpose:             Provides a centralized, reusable interface for
--                       inserting new notification records into the
--                       "notifications" table on behalf of application
--                       logic, triggers, or RPC calls (Supabase).
-- =============================================================================
-- Parameters:
--   p_user_id            UUID              - Target recipient of the
--                                             notification. Must reference
--                                             an existing user record.
--   p_title              TEXT              - Short, human-readable
--                                             notification title.
--   p_message            TEXT              - Full notification body/detail
--                                             text presented to the user.
--   p_notification_type  notification_type - Enumerated classification of
--                                             the notification (e.g.,
--                                             system-defined ENUM type)
--                                             used for filtering, routing,
--                                             and client-side rendering.
--   p_reference_id       UUID  DEFAULT NULL - Optional foreign reference
--                                             (e.g., related record ID)
--                                             providing contextual linkage
--                                             for the notification. Safe
--                                             to omit when no reference
--                                             entity applies.
--
-- Return Type:
--   UUID — the primary key (id) of the newly inserted notification row,
--   enabling immediate downstream use (e.g., real-time push, logging,
--   client response payloads) without requiring a subsequent lookup.
--
-- Behavior:
--   - Performs a single-row INSERT into the "notifications" table.
--   - p_reference_id is handled gracefully via explicit NULL-safe
--     assignment; no additional validation/coercion is required since
--     the reference_id column is expected to be NULLABLE.
--   - created_at (if present on the table) is expected to be populated
--     via column DEFAULT (e.g., now()) rather than explicitly set here,
--     keeping this function decoupled from schema-level defaults.
--   - Does not perform existence validation on p_user_id or
--     p_reference_id; referential integrity is enforced at the
--     foreign key constraint level.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role. Callers must hold INSERT privileges on the
--   "notifications" table, or this function should be wrapped/granted
--   accordingly per RLS policy design.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--   Note: each invocation creates a new notification row; this function
--   is NOT idempotent with respect to duplicate notification prevention.
-- =============================================================================
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id           UUID,
    p_title              TEXT,
    p_message            TEXT,
    p_notification_type  notification_type,
    p_reference_id       UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        reference_id
    )
    VALUES (
        p_user_id,
        p_title,
        p_message,
        p_notification_type,
        p_reference_id
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$;

COMMENT ON FUNCTION create_notification(UUID, TEXT, TEXT, notification_type, UUID) IS
    'Utility function: inserts a new notification record for a given user and returns the generated notification UUID. 
     reference_id is optional (NULL-safe) and used for contextual linkage to related entities.';
-- =============================================================================
-- Function:            search_referrals(search_term TEXT)
-- Purpose:             Performs Full Text Search (FTS) against active
--                       referral posts using the precomputed "search_vector"
--                       column, returning a lightweight result set optimized
--                       for search-results listing consumption.
-- =============================================================================
-- Parameters:
--   p_search_term   TEXT - Raw user-supplied search term(s). Converted
--                           internally into a tsquery via plainto_tsquery(),
--                           which safely tokenizes and normalizes free-form
--                           input (no special tsquery syntax required from
--                           the caller).
--
-- Return Type:
--   TABLE (
--     id            UUID,
--     company_name  TEXT,
--     role          TEXT,
--     location      TEXT,
--     work_mode     work_mode,
--     created_at    TIMESTAMPTZ
--   )
--
-- Behavior:
--   - Matches rows where "search_vector" satisfies the tsquery derived
--     from p_search_term, leveraging the weighted tsvector populated by
--     update_search_vector().
--   - Restricts results to active referral posts only (status = 'active'),
--     ensuring closed/expired/draft postings are excluded from search
--     results.
--   - Orders results by created_at DESC (newest first) to surface the
--     most recent opportunities at the top of the result set.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining by
--     the query planner, enabling more efficient execution plans and
--     potential index usage on "search_vector".
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "referral_posts" are respected. STABLE volatility is declared since
--   the function performs read-only operations with no side effects and
--   its result depends only on its input and table state within a
--   single statement.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires a GIN index on "search_vector" (to be
--   defined separately in the indexing migration; not included here per
--   scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION search_referrals(p_search_term TEXT)
RETURNS TABLE (
    id            UUID,
    company_name  TEXT,
    role          TEXT,
    location      TEXT,
    work_mode     work_mode,
    created_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        rp.id,
        rp.company_name,
        rp.role,
        rp.location,
        rp.work_mode,
        rp.created_at
    FROM referral_posts rp
    WHERE rp.status = 'active'
      AND rp.search_vector @@ plainto_tsquery('english', p_search_term)
    ORDER BY rp.created_at DESC;
$$;

COMMENT ON FUNCTION search_referrals(TEXT) IS
    'Utility function: performs full-text search over active referral posts using the search_vector 
   column, returning id, company_name, role, location, work_mode, and created_at ordered by newest first.';
-- =============================================================================
-- Function:            get_post_like_count(post_uuid UUID)
-- Purpose:             Returns the total number of "like" records associated
--                       with a given referral post, providing a fast,
--                       reusable aggregate accessor for use in views,
--                       RPC calls (Supabase), and application-layer queries.
-- =============================================================================
-- Parameters:
--   p_post_uuid   UUID - Identifier of the referral post whose like count
--                         is being requested.
--
-- Return Type:
--   INTEGER — total count of matching rows in the "post_likes" table.
--
-- Behavior:
--   - Performs a single COUNT(*) aggregate scoped to the given post_id.
--   - Returns 0 (not NULL) when no matching rows exist, via COUNT(*)
--     semantics.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining by
--     the query planner and minimize function-call overhead.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "post_likes" are respected. STABLE volatility is declared since the
--   result depends only on table state and input, with no side effects,
--   allowing safe reuse within a single statement execution.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires an index on post_likes(post_id) (to be
--   defined separately in the indexing migration; not included here per
--   scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION get_post_like_count(p_post_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM post_likes pl
    WHERE pl.post_id = p_post_uuid;
$$;

COMMENT ON FUNCTION get_post_like_count(UUID) IS
    'Utility function: returns the total number of likes recorded against a given referral post via fast COUNT(*) aggregation on post_likes.';


-- =============================================================================
-- Function:            get_post_comment_count(post_uuid UUID)
-- Purpose:             Returns the total number of comment records
--                       associated with a given referral post, providing a
--                       fast, reusable aggregate accessor for use in views,
--                       RPC calls (Supabase), and application-layer queries.
-- =============================================================================
-- Parameters:
--   p_post_uuid   UUID - Identifier of the referral post whose comment
--                         count is being requested.
--
-- Return Type:
--   INTEGER — total count of matching rows in the "post_comments" table.
--
-- Behavior:
--   - Performs a single COUNT(*) aggregate scoped to the given post_id.
--   - Returns 0 (not NULL) when no matching rows exist, via COUNT(*)
--     semantics.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining by
--     the query planner and minimize function-call overhead.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "post_comments" are respected. STABLE volatility is declared since
--   the result depends only on table state and input, with no side
--   effects, allowing safe reuse within a single statement execution.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires an index on post_comments(post_id) (to
--   be defined separately in the indexing migration; not included here
--   per scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION get_post_comment_count(p_post_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM post_comments pc
    WHERE pc.post_id = p_post_uuid;
$$;

COMMENT ON FUNCTION get_post_comment_count(UUID) IS
    'Utility function: returns the total number of comments recorded against a given referral post via 
     fast COUNT(*) aggregation on post_comments.';
-- =============================================================================
-- Function:            get_my_posts(user_uuid UUID)
-- Purpose:             Retrieves all referral posts authored by a specific
--                       user, providing a reusable accessor for personal
--                       dashboard views, profile pages, and RPC calls
--                       (Supabase) without exposing unrelated columns.
-- =============================================================================
-- Parameters:
--   p_user_uuid   UUID - Identifier of the user whose authored referral
--                         posts are being requested.
--
-- Return Type:
--   TABLE (
--     company_name  TEXT,
--     role          TEXT,
--     status        post_status,
--     created_at    TIMESTAMPTZ,
--     updated_at    TIMESTAMPTZ
--   )
--
-- Behavior:
--   - Returns all referral posts where the authenticated/owning user_id
--     matches p_user_uuid, regardless of post status (active, closed,
--     draft, expired, etc.), enabling the user to manage their full
--     posting history.
--   - Orders results by created_at DESC (newest first) to surface the
--     most recently created posts at the top.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining by
--     the query planner and minimize function-call overhead.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "referral_posts" are respected (e.g., a user should only be able to
--   invoke this for their own user_id under RLS enforcement).
--   STABLE volatility is declared since the result depends only on
--   table state and input, with no side effects.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires an index on referral_posts(user_id)
--   (to be defined separately in the indexing migration; not included
--   here per scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION get_my_posts(p_user_uuid UUID)
RETURNS TABLE (
    company_name  TEXT,
    role          TEXT,
    status        post_status,
    created_at    TIMESTAMPTZ,
    updated_at    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        rp.company_name,
        rp.role,
        rp.status,
        rp.created_at,
        rp.updated_at
    FROM referral_posts rp
    WHERE rp.user_id = p_user_uuid
    ORDER BY rp.created_at DESC;
$$;

COMMENT ON FUNCTION get_my_posts(UUID) IS
    'Utility function: returns all referral posts authored by a given user, 
  including company_name, role, status, created_at, and updated_at, ordered by newest first.';
-- =============================================================================
-- Function:            get_dashboard_metrics(user_uuid UUID)
-- Purpose:             Aggregates key performance metrics for a user's
--                       referral activity into a single row, optimized for
--                       dashboard/summary views without requiring multiple
--                       round-trip queries from the application layer.
-- =============================================================================
-- Parameters:
--   p_user_uuid   UUID - Identifier of the user whose dashboard metrics
--                         are being requested (post owner).
--
-- Return Type:
--   TABLE (
--     total_posts               INTEGER,
--     active_posts               INTEGER,
--     closed_posts               INTEGER,
--     total_comments             INTEGER,
--     total_likes                INTEGER,
--     total_referral_requests    INTEGER
--   )
--
-- Behavior:
--   - total_posts / active_posts / closed_posts:
--       Derived from a single scan of "referral_posts" scoped to
--       p_user_uuid, using FILTER clauses to compute all three counts
--       in one aggregation pass (avoids repeated table scans or
--       subqueries per status).
--   - total_comments / total_likes:
--       Derived via COUNT(*) over "post_comments" / "post_likes" joined
--       to the user's own posts (post_id IN subquery), reflecting
--       engagement received on the user's referral posts.
--   - total_referral_requests:
--       Derived via COUNT(*) over "referral_requests" joined to the
--       user's own posts, reflecting the number of referral requests
--       submitted against the user's postings.
--   - All sub-aggregates are computed independently via CTEs and
--     combined in a single final SELECT, minimizing redundant joins
--     and enabling the planner to execute each aggregate scan
--     efficiently and, where applicable, in parallel.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining
--     and planner optimization.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "referral_posts", "post_comments", "post_likes", and
--   "referral_requests" are respected. STABLE volatility is declared
--   since the result depends only on table state and input, with no
--   side effects.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires indexes on:
--     - referral_posts(user_id, status)
--     - post_comments(post_id)
--     - post_likes(post_id)
--     - referral_requests(post_id)
--   (to be defined separately in the indexing migration; not included
--   here per scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION get_dashboard_metrics(p_user_uuid UUID)
RETURNS TABLE (
    total_posts             INTEGER,
    active_posts            INTEGER,
    closed_posts            INTEGER,
    total_comments          INTEGER,
    total_likes             INTEGER,
    total_referral_requests INTEGER
)
LANGUAGE sql
STABLE
AS $$
    WITH user_posts AS (
        SELECT rp.id, rp.status
        FROM referral_posts rp
        WHERE rp.user_id = p_user_uuid
    ),
    post_metrics AS (
        SELECT
            COUNT(*)::INTEGER                                   AS total_posts,
            COUNT(*) FILTER (WHERE up.status = 'active')::INTEGER AS active_posts,
            COUNT(*) FILTER (WHERE up.status = 'closed')::INTEGER AS closed_posts
        FROM user_posts up
    ),
    comment_metrics AS (
        SELECT COUNT(*)::INTEGER AS total_comments
        FROM post_comments pc
        WHERE pc.post_id IN (SELECT id FROM user_posts)
    ),
    like_metrics AS (
        SELECT COUNT(*)::INTEGER AS total_likes
        FROM post_likes pl
        WHERE pl.post_id IN (SELECT id FROM user_posts)
    ),
    request_metrics AS (
        SELECT COUNT(*)::INTEGER AS total_referral_requests
        FROM referral_requests rr
        WHERE rr.post_id IN (SELECT id FROM user_posts)
    )
    SELECT
        pm.total_posts,
        pm.active_posts,
        pm.closed_posts,
        cm.total_comments,
        lm.total_likes,
        rm.total_referral_requests
    FROM post_metrics pm
    CROSS JOIN comment_metrics cm
    CROSS JOIN like_metrics lm
    CROSS JOIN request_metrics rm;
$$;

COMMENT ON FUNCTION get_dashboard_metrics(UUID) IS
    'Utility function: returns aggregated dashboard metrics 
  (total_posts, active_posts, closed_posts, total_comments, total_likes, total_referral_requests) for a 
  given user in a single optimized query.';
-- =============================================================================
-- Function:            is_post_liked(post_uuid UUID, user_uuid UUID)
-- Purpose:             Determines whether a given user has already liked a
--                       given referral post, providing a fast, reusable
--                       existence check for UI state rendering (e.g.,
--                       toggling like/unlike button state) and application
--                       logic guarding duplicate like insertion.
-- =============================================================================
-- Parameters:
--   p_post_uuid   UUID - Identifier of the referral post being checked.
--   p_user_uuid   UUID - Identifier of the user whose like status is being
--                         checked.
--
-- Return Type:
--   BOOLEAN — TRUE if a matching row exists in "post_likes" for the given
--   post/user pair, FALSE otherwise.
--
-- Behavior:
--   - Uses EXISTS() for a short-circuiting existence check rather than a
--     COUNT(*) comparison, avoiding unnecessary full match counting and
--     minimizing I/O for large tables.
--   - Always returns a non-NULL BOOLEAN (TRUE/FALSE), never NULL.
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining by
--     the query planner and minimize function-call overhead.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "post_likes" are respected. STABLE volatility is declared since the
--   result depends only on table state and input, with no side effects.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires a composite (unique) index on
--   post_likes(post_id, user_id) (to be defined separately in the
--   indexing migration; not included here per scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION is_post_liked(
    p_post_uuid UUID,
    p_user_uuid UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM post_likes pl
        WHERE pl.post_id = p_post_uuid
          AND pl.user_id = p_user_uuid
    );
$$;

COMMENT ON FUNCTION is_post_liked(UUID, UUID) IS
    'Utility function: returns TRUE if the given user has already liked the given referral post, 
     FALSE otherwise, via a fast EXISTS() lookup on post_likes.';
-- =============================================================================
-- Function:            get_post_details(post_uuid UUID)
-- Purpose:             Retrieves a full, denormalized view of a single
--                       referral post — combining core post information,
--                       engagement metrics (likes, comments, referral
--                       requests), and authoring employee profile details —
--                       in a single optimized query for post detail page
--                       rendering.
-- =============================================================================
-- Parameters:
--   p_post_uuid   UUID - Identifier of the referral post whose full
--                         details are being requested.
--
-- Return Type:
--   TABLE (
--     post_id                  UUID,
--     company_name             TEXT,
--     role                     TEXT,
--     location                 TEXT,
--     work_mode                work_mode,
--     status                   post_status,
--     description              TEXT,
--     created_at               TIMESTAMPTZ,
--     updated_at               TIMESTAMPTZ,
--     like_count               INTEGER,
--     comment_count            INTEGER,
--     referral_request_count   INTEGER,
--     employee_id              UUID,
--     employee_name            TEXT,
--     employee_profile_picture TEXT
--   )
--
-- Behavior:
--   - Joins "referral_posts" to "users" (aliased as employee) via
--     user_id to surface the authoring employee's display name and
--     profile picture URL alongside the post record.
--   - Engagement counts (likes, comments, referral requests) are
--     computed via correlated LATERAL subqueries scoped to a single
--     post_id, rather than joining full child tables directly, which
--     avoids row multiplication (fan-out) and redundant aggregation
--     that would otherwise occur from multiple one-to-many joins in
--     the same query.
--   - Restricts the outer query to a single post via WHERE rp.id =
--     p_post_uuid, so each LATERAL subquery executes exactly once per
--     engagement type — an efficient access pattern for single-row
--     detail lookups (as opposed to bulk listing queries).
--   - Implemented as a SQL (not PL/pgSQL) function to allow inlining
--     by the query planner and minimize function-call overhead.
--
-- Security:
--   SECURITY INVOKER (default) — executes with the privileges of the
--   invoking role, ensuring Row-Level Security (RLS) policies on
--   "referral_posts", "users", "post_likes", "post_comments", and
--   "referral_requests" are respected. STABLE volatility is declared
--   since the result depends only on table state and input, with no
--   side effects.
--
-- Idempotency:
--   CREATE OR REPLACE ensures safe re-execution during migration replays.
--
-- Performance Note:
--   Optimal performance requires:
--     - Primary key index on referral_posts(id) (implicit via PK)
--     - Primary key index on users(id) (implicit via PK)
--     - Indexes on post_likes(post_id), post_comments(post_id), and
--       referral_requests(post_id)
--   (to be defined separately in the indexing migration; not included
--   here per scope).
-- =============================================================================
CREATE OR REPLACE FUNCTION get_post_details(p_post_uuid UUID)
RETURNS TABLE (
    post_id                  UUID,
    company_name             TEXT,
    role                     TEXT,
    location                 TEXT,
    work_mode                work_mode,
    status                   post_status,
    description              TEXT,
    created_at               TIMESTAMPTZ,
    updated_at               TIMESTAMPTZ,
    like_count               INTEGER,
    comment_count            INTEGER,
    referral_request_count   INTEGER,
    employee_id              UUID,
    employee_name            TEXT,
    employee_profile_picture TEXT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        rp.id                       AS post_id,
        rp.company_name,
        rp.role,
        rp.location,
        rp.work_mode,
        rp.status,
        rp.description,
        rp.created_at,
        rp.updated_at,
        lc.like_count,
        cc.comment_count,
        rc.referral_request_count,
        u.id                        AS employee_id,
        u.full_name                 AS employee_name,
        u.profile_picture_url       AS employee_profile_picture
    FROM referral_posts rp
    JOIN users u
        ON u.id = rp.user_id
    LEFT JOIN LATERAL (
        SELECT COUNT(*)::INTEGER AS like_count
        FROM post_likes pl
        WHERE pl.post_id = rp.id
    ) lc ON TRUE
    LEFT JOIN LATERAL (
        SELECT COUNT(*)::INTEGER AS comment_count
        FROM post_comments pc
        WHERE pc.post_id = rp.id
    ) cc ON TRUE
    LEFT JOIN LATERAL (
        SELECT COUNT(*)::INTEGER AS referral_request_count
        FROM referral_requests rr
        WHERE rr.post_id = rp.id
    ) rc ON TRUE
    WHERE rp.id = p_post_uuid;
$$;

COMMENT ON FUNCTION get_post_details(UUID) IS
    'Utility function: returns full referral post details including like_count, comment_count, referral_request_count, 
    and authoring employee profile information (name, picture) for a single post_id.';
-- =============================================================================
-- Section:             Post-Migration Validation
-- Purpose:             Provides a suite of read-only verification queries to
--                       confirm successful and correct deployment of all
--                       functions defined in this migration
--                       (V1.0.2__functions.sql). Intended for execution
--                       immediately after migration apply, as part of CI/CD
--                       verification, manual DBA review, or automated smoke
--                       testing.
-- =============================================================================
-- Scope:
--   These queries are strictly READ-ONLY (SELECT statements against system
--   catalogs / information_schema views) and perform no DDL/DML. They are
--   safe to execute in any environment, including production, without side
--   effects.
--
-- Functions Validated:
--   1. update_updated_at_column()
--   2. update_search_vector()
--   3. create_notification(UUID, TEXT, TEXT, notification_type, UUID)
--   4. search_referrals(TEXT)
--   5. get_post_like_count(UUID)
--   6. get_post_comment_count(UUID)
--   7. get_my_posts(UUID)
--   8. get_dashboard_metrics(UUID)
--   9. is_post_liked(UUID, UUID)
--  10. get_post_details(UUID)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. VERIFY: All expected functions exist in the current schema
-- -----------------------------------------------------------------------------
-- Confirms that every function introduced by this migration is present in
-- pg_proc for the active search_path schema (typically "public"). A missing
-- row for any expected function name indicates a failed or partial
-- migration apply.
-- -----------------------------------------------------------------------------
SELECT
    p.proname                              AS function_name,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS argument_signature,
    n.nspname                              AS schema_name
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
        'update_updated_at_column',
        'update_search_vector',
        'create_notification',
        'search_referrals',
        'get_post_like_count',
        'get_post_comment_count',
        'get_my_posts',
        'get_dashboard_metrics',
        'is_post_liked',
        'get_post_details'
  )
ORDER BY p.proname;


-- -----------------------------------------------------------------------------
-- 2. VERIFY: Function implementation language for each function
-- -----------------------------------------------------------------------------
-- Confirms that each function was created with its intended procedural
-- language (e.g., "plpgsql" for trigger/procedural functions, "sql" for
-- pure SQL functions), ensuring implementation matches architectural
-- design intent (e.g., inlining eligibility for SQL-language functions).
-- -----------------------------------------------------------------------------
SELECT
    p.proname                  AS function_name,
    l.lanname                  AS function_language,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS argument_signature
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n
    ON n.oid = p.pronamespace
JOIN pg_catalog.pg_language l
    ON l.oid = p.prolang
WHERE n.nspname = 'public'
  AND p.proname IN (
        'update_updated_at_column',
        'update_search_vector',
        'create_notification',
        'search_referrals',
        'get_post_like_count',
        'get_post_comment_count',
        'get_my_posts',
        'get_dashboard_metrics',
        'is_post_liked',
        'get_post_details'
  )
ORDER BY p.proname;


-- -----------------------------------------------------------------------------
-- 3. VERIFY: Function ownership
-- -----------------------------------------------------------------------------
-- Confirms the owning role of each function, supporting security review
-- and ensuring ownership aligns with expected migration-execution role
-- (e.g., a dedicated migration/service role rather than an individual
-- superuser account).
-- -----------------------------------------------------------------------------
SELECT
    p.proname                  AS function_name,
    pg_catalog.pg_get_userbyid(p.proowner) AS function_owner,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS argument_signature
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
        'update_updated_at_column',
        'update_search_vector',
        'create_notification',
        'search_referrals',
        'get_post_like_count',
        'get_post_comment_count',
        'get_my_posts',
        'get_dashboard_metrics',
        'is_post_liked',
        'get_post_details'
  )
ORDER BY p.proname;


-- -----------------------------------------------------------------------------
-- 4. VERIFY: Full function definitions (source review)
-- -----------------------------------------------------------------------------
-- Returns the complete, reconstructed DDL source for each function via
-- pg_get_functiondef(), enabling direct visual diffing against the
-- migration source file to detect drift, unintended manual edits, or
-- deployment discrepancies across environments.
-- -----------------------------------------------------------------------------
SELECT
    p.proname                                  AS function_name,
    pg_catalog.pg_get_functiondef(p.oid)       AS function_definition
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
        'update_updated_at_column',
        'update_search_vector',
        'create_notification',
        'search_referrals',
        'get_post_like_count',
        'get_post_comment_count',
        'get_my_posts',
        'get_dashboard_metrics',
        'is_post_liked',
        'get_post_details'
  )
ORDER BY p.proname;


-- -----------------------------------------------------------------------------
-- 5. VERIFY: Total function count matches expected migration scope
-- -----------------------------------------------------------------------------
-- Returns a single aggregate count of matched functions. Expected result
-- for this migration is exactly 10. A count lower than 10 indicates one
-- or more functions failed to deploy; a count higher than expected may
-- indicate naming collisions with pre-existing objects in the schema.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*) AS total_functions_found,
    10       AS expected_function_count,
    (COUNT(*) = 10) AS validation_passed
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
        'update_updated_at_column',
        'update_search_vector',
        'create_notification',
        'search_referrals',
        'get_post_like_count',
        'get_post_comment_count',
        'get_my_posts',
        'get_dashboard_metrics',
        'is_post_liked',
        'get_post_details'
  );
-- ===================================================================================
