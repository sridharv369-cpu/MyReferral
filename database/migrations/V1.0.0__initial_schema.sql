-- =============================================================================
-- Project Name     : MyReferral
-- Migration Version: V1.0.0
-- Description      : Initial schema migration. Establishes required PostgreSQL
--                     extensions and core ENUM types used across the
--                     MyReferral job referral platform (roles, post lifecycle,
--                     referral request lifecycle, and notification types).
--                     No tables, indexes, functions, triggers, or RLS
--                     policies are created in this migration.
-- PostgreSQL Version : 15.x (Supabase managed Postgres)
-- Supabase Compatibility : Fully compatible. Uses extensions pre-bundled
--                     with Supabase (pgcrypto, uuid-ossp, pg_trgm) and
--                     idempotent DDL patterns safe for Supabase's migration
--                     tooling and CLI-based deployments.
-- Author           : <AUTHOR_NAME_PLACEHOLDER>
-- Created Date     : <YYYY-MM-DD_PLACEHOLDER>
-- =============================================================================
-- Change Log:
--   V1.0.0 - Initial creation of extensions and enumerated types.
-- =============================================================================


-- =============================================================================
-- SECTION 1: EXTENSIONS
-- -----------------------------------------------------------------------------
-- Purpose: Enable PostgreSQL extensions required by subsequent migrations
--          (e.g., UUID generation for primary keys, cryptographic functions
--          for secure token/hash generation, and trigram indexing to support
--          future full-text / fuzzy search on job posts).
-- Note   : Extensions are created in the "extensions" schema where applicable
--          to align with Supabase's recommended security practices, falling
--          back to the default schema resolution when unavailable.
-- =============================================================================

-- UUID generation support (legacy uuid_generate_v4(), retained for compatibility)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions (gen_random_uuid(), digest hashing, secure tokens)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Trigram-based text similarity, to support future fuzzy/full-text search
-- on job post titles, descriptions, and company names.
CREATE EXTENSION IF NOT EXISTS "pg_trgm";


-- =============================================================================
-- SECTION 2: ENUMERATED TYPES
-- -----------------------------------------------------------------------------
-- Purpose: Define strongly-typed, database-enforced enumerations for core
--          domain concepts within the MyReferral platform. Using native
--          PostgreSQL ENUM types (rather than free-text columns) guarantees
--          referential integrity of state values at the database layer,
--          improves query performance, and provides self-documenting schema
--          semantics for downstream table definitions.
--
-- Idempotency Strategy:
--          PostgreSQL does not support "CREATE TYPE IF NOT EXISTS" natively.
--          Each ENUM is therefore guarded by a DO $$ ... $$ block that checks
--          pg_type via to_regtype() before creation, making this migration
--          safely re-runnable without raising duplicate_object errors.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ENUM: app_role
-- Description : Represents the authorization role assigned to a platform
--               user account, used for role-based access control (RBAC)
--               and future RLS policy definitions.
-- Values      :
--   'user'  - Standard platform user (employee / job seeker).
--   'admin' - Platform administrator with elevated privileges.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regtype('public.app_role') IS NULL THEN
        CREATE TYPE public.app_role AS ENUM (
            'user',
            'admin'
        );
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- ENUM: post_status
-- Description : Represents the lifecycle state of a referral job post
--               created by an employee.
-- Values      :
--   'active'  - Post is live and visible for referral requests.
--   'draft'   - Post is saved but not yet published.
--   'closed'  - Post has been manually closed by the author.
--   'expired' - Post has passed its validity window and is no longer active.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regtype('public.post_status') IS NULL THEN
        CREATE TYPE public.post_status AS ENUM (
            'active',
            'draft',
            'closed',
            'expired'
        );
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- ENUM: referral_status
-- Description : Represents the lifecycle state of a referral request
--               submitted by a job seeker against a referral post.
-- Values      :
--   'Pending'   - Request submitted, awaiting action from the referrer.
--   'Accepted'  - Referrer has accepted and agreed to refer the candidate.
--   'Rejected'  - Referrer has declined the referral request.
--   'Cancelled' - Request withdrawn by the requester prior to resolution.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regtype('public.referral_status') IS NULL THEN
        CREATE TYPE public.referral_status AS ENUM (
            'Pending',
            'Accepted',
            'Rejected',
            'Cancelled'
        );
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- ENUM: notification_type
-- Description : Classifies the category of an in-app or push notification
--               dispatched to platform users, enabling type-specific
--               rendering, routing, and filtering logic at the application
--               layer.
-- Values      :
--   'REFERRAL_REQUEST'   - A job seeker has requested a referral.
--   'COMMENT'            - A comment was made on a post the user follows.
--   'LIKE'               - A user's post or content received a like.
--   'REFERRAL_ACCEPTED'  - A referral request was accepted.
--   'REFERRAL_REJECTED'  - A referral request was rejected.
--   'SYSTEM'             - Platform-generated system or administrative alert.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regtype('public.notification_type') IS NULL THEN
        CREATE TYPE public.notification_type AS ENUM (
            'REFERRAL_REQUEST',
            'COMMENT',
            'LIKE',
            'REFERRAL_ACCEPTED',
            'REFERRAL_REJECTED',
            'SYSTEM'
        );
    END IF;
END
$$;

-- =============================================================================
-- END OF MIGRATION V1.0.0
-- =============================================================================
-- =============================================================================
-- SECTION 3: TABLES
-- -----------------------------------------------------------------------------
-- Purpose: Define core relational tables for the MyReferral platform.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TABLE: public.users
-- Description : Stores application-level user profile data, synchronized
--               with Supabase's built-in auth.users table. The primary key
--               (id) mirrors auth.users.id (1:1 relationship), allowing this
--               table to hold platform-specific profile attributes (name,
--               avatar, role, status) without duplicating authentication
--               credentials or sensitive auth data.
-- Sync Note   : Population/synchronization of this table from auth.users is
--               expected to be handled by a trigger or Edge Function defined
--               in a later migration. No triggers are created here.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (

    -- Primary key. Mirrors the corresponding auth.users.id (Supabase Auth
    -- managed UUID). Not generated locally; value is supplied at sync time
    -- from the authentication provider.
    id                  UUID PRIMARY KEY,

    -- Full display name of the user, shown across posts, comments, and
    -- referral requests. Nullable to accommodate initial sync before the
    -- user completes their profile.
    name                VARCHAR(150),

    -- User's email address, mirrored from auth.users for convenient
    -- application-level querying and display. Must be unique across all
    -- platform users. Nullable at row-creation time to tolerate partial
    -- sync states, but enforced unique when present.
    email               VARCHAR(255)
                            UNIQUE,

    -- URL pointing to the user's profile picture / avatar, typically
    -- stored in Supabase Storage. Nullable, as not all users upload one.
    profile_picture     TEXT,

    -- Authorization role assigned to the user (standard user vs. platform
    -- administrator). Enforced via the app_role ENUM. Defaults to the
    -- least-privileged role ('user') for security-by-default.
    role                app_role
                            NOT NULL
                            DEFAULT 'user',

    -- Current account status. Restricted to 'active' or 'inactive' via
    -- CHECK constraint. Defaults to 'active' upon creation.
    status              VARCHAR(20)
                            DEFAULT 'active'
                            CHECK (status IN ('active', 'inactive')),

    -- Timestamp indicating when the user profile record was first created
    -- in this table. Defaults to the current transaction timestamp.
    created_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Timestamp indicating when the user profile record was last updated.
    -- Defaults to the current transaction timestamp at insertion; expected
    -- to be maintained by an update trigger defined in a later migration.
    updated_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.users table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.users IS
    'Application user profiles, synchronized 1:1 with auth.users. Holds platform-specific attributes such as display name, avatar, role, and account status.';

COMMENT ON COLUMN public.users.id IS
    'Primary key. Mirrors auth.users.id from Supabase Auth to establish a 1:1 relationship between authentication identity and application profile.';

COMMENT ON COLUMN public.users.name IS
    'Full display name of the user, shown across job posts, comments, and referral requests.';

COMMENT ON COLUMN public.users.email IS
    'User email address, mirrored from auth.users. Must be unique across the platform; used for display and lookup purposes at the application layer.';

COMMENT ON COLUMN public.users.profile_picture IS
    'URL reference to the user profile picture / avatar, typically hosted in Supabase Storage.';

COMMENT ON COLUMN public.users.role IS
    'Authorization role of the user (user or admin), governing access control and future RLS policy enforcement. Defaults to the least-privileged role.';

COMMENT ON COLUMN public.users.status IS
    'Current account status, restricted to active or inactive via CHECK constraint. Used to enable/disable platform access without deleting user data.';

COMMENT ON COLUMN public.users.created_at IS
    'Timestamp marking when the user profile record was created in this table.';

COMMENT ON COLUMN public.users.updated_at IS
    'Timestamp marking the most recent update to the user profile record. Intended to be maintained automatically by an update trigger in a future migration.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.users table)
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TABLE: public.referral_posts
-- Description : Represents an internal job referral opportunity posted by an
--               employee (public.users). Job seekers browse and search these
--               posts to identify roles for which they can request a
--               referral. Includes a denormalized full-text search vector
--               column to support future search functionality.
-- Relationships:
--   - user_id -> public.users(id) : The employee who authored the post.
--     ON DELETE CASCADE ensures that if the authoring user account is
--     removed, their associated referral posts are removed as well,
--     preventing orphaned job postings.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.referral_posts (

    -- Primary key. Uniquely identifies each referral post record.
    id                  UUID PRIMARY KEY,

    -- Foreign key referencing the employee (public.users) who created this
    -- referral post. Cascades on delete so that removing a user account
    -- automatically removes their posted referral opportunities.
    user_id             UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Name of the hiring company offering the role. Required for display
    -- and search purposes.
    company_name        VARCHAR(200)
                            NOT NULL
                            CHECK (btrim(company_name) <> ''),

    -- URL pointing to the hiring company's official website or careers
    -- page. Optional, but must be a well-formed http(s) URL when present.
    company_url         TEXT
                            CHECK (company_url IS NULL OR company_url ~* '^https?://'),

    -- External job requisition / job posting identifier from the
    -- company's Applicant Tracking System (ATS), used for cross-reference
    -- and de-duplication purposes.
    job_id              VARCHAR(100),

    -- Title of the open role being referred (e.g., "Senior Backend
    -- Engineer"). Required for display, search, and filtering.
    role                VARCHAR(150)
                            NOT NULL
                            CHECK (btrim(role) <> ''),

    -- Comma/CSV-style or free-text summary of key skills and technologies
    -- relevant to the role, used to support keyword search and matching.
    key_skills           TEXT,

    -- Full description of the job role, responsibilities, and
    -- requirements. Required, as it forms the primary content of the post.
    job_description      TEXT
                            NOT NULL
                            CHECK (btrim(job_description) <> ''),

    -- Email address of the referring employee, used by job seekers or the
    -- system to route referral requests and notifications. Validated
    -- against a basic email format pattern.
    employee_email       VARCHAR(255)
                            NOT NULL
                            CHECK (employee_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),

    -- Direct URL to the official job application page (company career
    -- site or ATS listing). Required so job seekers can formally apply.
    job_apply_url        TEXT
                            NOT NULL
                            CHECK (job_apply_url ~* '^https?://'),

    -- City/region of the job location as displayed to job seekers.
    location             VARCHAR(150),

    -- Country in which the role is based. Used for filtering and search.
    country              VARCHAR(100),

    -- Work arrangement for the role. Restricted to a known set of values
    -- via CHECK constraint to ensure consistent filtering options.
    work_mode            VARCHAR(20)
                            NOT NULL
                            CHECK (work_mode IN ('onsite', 'remote', 'hybrid')),

    -- Current lifecycle status of the referral post (active, draft,
    -- closed, expired). Enforced via the post_status ENUM type. Defaults
    -- to 'active' so newly created posts are immediately discoverable.
    status               post_status
                            NOT NULL
                            DEFAULT 'active',

    -- Precomputed full-text search vector derived from searchable columns
    -- (e.g., role, company_name, key_skills, job_description). Intended to
    -- be populated and maintained via a trigger defined in a later
    -- migration; no index or trigger is created in this migration.
    search_vector        TSVECTOR,

    -- Timestamp marking when the referral post was created.
    created_at           TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Timestamp marking the most recent update to the referral post.
    -- Expected to be maintained automatically by an update trigger
    -- defined in a later migration.
    updated_at           TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.referral_posts table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.referral_posts IS
    'Internal job referral opportunities posted by employees. Job seekers browse and search these posts to request referrals for open roles.';

COMMENT ON COLUMN public.referral_posts.id IS
    'Primary key. Uniquely identifies each referral post.';

COMMENT ON COLUMN public.referral_posts.user_id IS
    'Foreign key referencing the employee (public.users) who authored this referral post. Cascades on delete of the referencing user.';

COMMENT ON COLUMN public.referral_posts.company_name IS
    'Name of the hiring company offering the referred role. Required and must be non-blank.';

COMMENT ON COLUMN public.referral_posts.company_url IS
    'Optional URL to the hiring company''s website or careers page. Must be a well-formed http(s) URL when provided.';

COMMENT ON COLUMN public.referral_posts.job_id IS
    'External job requisition identifier from the company''s Applicant Tracking System (ATS), used for cross-referencing and de-duplication.';

COMMENT ON COLUMN public.referral_posts.role IS
    'Title of the open role being referred. Required and must be non-blank.';

COMMENT ON COLUMN public.referral_posts.key_skills IS
    'Free-text or CSV-style list of key skills and technologies relevant to the role, used to support keyword search and matching.';

COMMENT ON COLUMN public.referral_posts.job_description IS
    'Full description of the job role, responsibilities, and requirements. Required, as it forms the primary content of the post.';

COMMENT ON COLUMN public.referral_posts.employee_email IS
    'Email address of the referring employee, used to route referral requests and notifications. Validated against a basic email format pattern.';

COMMENT ON COLUMN public.referral_posts.job_apply_url IS
    'Direct URL to the official job application page. Required and must be a well-formed http(s) URL.';

COMMENT ON COLUMN public.referral_posts.location IS
    'City or regional location of the job, as displayed to job seekers.';

COMMENT ON COLUMN public.referral_posts.country IS
    'Country in which the referred role is based. Used for filtering and search.';

COMMENT ON COLUMN public.referral_posts.work_mode IS
    'Work arrangement for the role. Restricted to onsite, remote, or hybrid via CHECK constraint.';

COMMENT ON COLUMN public.referral_posts.status IS
    'Current lifecycle status of the referral post (active, draft, closed, expired), enforced via the post_status ENUM. Defaults to active.';

COMMENT ON COLUMN public.referral_posts.search_vector IS
    'Precomputed full-text search vector derived from searchable post fields. Populated/maintained by a trigger defined in a later migration.';

COMMENT ON COLUMN public.referral_posts.created_at IS
    'Timestamp marking when the referral post was created.';

COMMENT ON COLUMN public.referral_posts.updated_at IS
    'Timestamp marking the most recent update to the referral post. Intended to be maintained automatically by an update trigger in a future migration.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.referral_posts table)
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TABLE: public.comments
-- Description : Stores user-authored comments made on referral posts,
--               enabling discussion and engagement between job seekers and
--               the employees who posted the referral opportunity.
-- Relationships:
--   - post_id -> public.referral_posts(id) : The referral post being
--     commented on. ON DELETE CASCADE ensures comments are removed when
--     their parent post is deleted.
--   - user_id -> public.users(id) : The user who authored the comment.
--     ON DELETE CASCADE ensures comments are removed when the authoring
--     user account is deleted.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.comments (

    -- Primary key. Uniquely identifies each comment record.
    id                  UUID PRIMARY KEY,

    -- Foreign key referencing the referral post this comment belongs to.
    -- Cascades on delete so comments are removed alongside their parent
    -- post.
    post_id             UUID
                            NOT NULL
                            REFERENCES public.referral_posts(id)
                            ON DELETE CASCADE,

    -- Foreign key referencing the user who authored this comment.
    -- Cascades on delete so a user's comments are removed alongside their
    -- account.
    user_id             UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Textual content of the comment. Required and must be non-blank.
    comment_text        TEXT
                            NOT NULL
                            CHECK (btrim(comment_text) <> ''),

    -- Timestamp marking when the comment was created.
    created_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Timestamp marking the most recent update to the comment. Expected
    -- to be maintained automatically by an update trigger defined in a
    -- later migration.
    updated_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.comments table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.comments IS
    'User-authored comments made on referral posts, enabling discussion and engagement between job seekers and employees.';

COMMENT ON COLUMN public.comments.id IS
    'Primary key. Uniquely identifies each comment.';

COMMENT ON COLUMN public.comments.post_id IS
    'Foreign key referencing the referral post this comment belongs to. Cascades on delete of the referenced post.';

COMMENT ON COLUMN public.comments.user_id IS
    'Foreign key referencing the user who authored this comment. Cascades on delete of the referenced user.';

COMMENT ON COLUMN public.comments.comment_text IS
    'Textual content of the comment. Required and must be non-blank.';

COMMENT ON COLUMN public.comments.created_at IS
    'Timestamp marking when the comment was created.';

COMMENT ON COLUMN public.comments.updated_at IS
    'Timestamp marking the most recent update to the comment. Intended to be maintained automatically by an update trigger in a future migration.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.comments table)
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TABLE: public.likes
-- Description : Records "like" interactions from users on referral posts,
--               supporting engagement metrics and social proof signals
--               within the MyReferral platform.
-- Relationships:
--   - post_id -> public.referral_posts(id) : The referral post being liked.
--     ON DELETE CASCADE ensures likes are removed when their parent post
--     is deleted.
--   - user_id -> public.users(id) : The user who performed the like.
--     ON DELETE CASCADE ensures likes are removed when the liking user
--     account is deleted.
-- Integrity   : A composite UNIQUE constraint on (post_id, user_id)
--               enforces that a given user may like a given referral post
--               at most once, preventing duplicate like records.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.likes (

    -- Primary key. Uniquely identifies each like record.
    id                  UUID PRIMARY KEY,

    -- Foreign key referencing the referral post being liked. Cascades on
    -- delete so likes are removed alongside their parent post.
    post_id             UUID
                            NOT NULL
                            REFERENCES public.referral_posts(id)
                            ON DELETE CASCADE,

    -- Foreign key referencing the user who performed the like. Cascades
    -- on delete so a user's likes are removed alongside their account.
    user_id             UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Timestamp marking when the like was created.
    created_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Composite uniqueness constraint ensuring a user can like a given
    -- referral post only once.
    CONSTRAINT uq_likes_post_user UNIQUE (post_id, user_id)
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.likes table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.likes IS
    'Records like interactions from users on referral posts, supporting engagement metrics and social proof within the platform.';

COMMENT ON COLUMN public.likes.id IS
    'Primary key. Uniquely identifies each like record.';

COMMENT ON COLUMN public.likes.post_id IS
    'Foreign key referencing the referral post being liked. Cascades on delete of the referenced post.';

COMMENT ON COLUMN public.likes.user_id IS
    'Foreign key referencing the user who performed the like. Cascades on delete of the referenced user.';

COMMENT ON COLUMN public.likes.created_at IS
    'Timestamp marking when the like was created.';

COMMENT ON CONSTRAINT uq_likes_post_user ON public.likes IS
    'Ensures a given user can like a given referral post at most once, preventing duplicate like records.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.likes table)
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TABLE: public.referral_requests
-- Description : Represents a job seeker's request for a referral against a
--               specific referral post. Tracks the lifecycle of the request
--               (pending, accepted, rejected, cancelled) and captures the
--               supporting information (message, resume) submitted by the
--               requester, as well as the employee responsible for acting
--               on the request.
-- Relationships:
--   - post_id -> public.referral_posts(id) : The referral post being
--     requested against. ON DELETE CASCADE ensures referral requests are
--     removed when their parent post is deleted.
--   - requester_id -> public.users(id) : The job seeker submitting the
--     referral request. ON DELETE CASCADE ensures requests are removed
--     when the requesting user account is deleted.
--   - employee_id -> public.users(id) : The employee responsible for
--     reviewing and acting on the referral request (typically the post
--     author). ON DELETE CASCADE ensures requests are removed when the
--     referring employee's account is deleted.
-- Integrity   : A composite UNIQUE constraint on (post_id, requester_id)
--               enforces that a given job seeker may submit only one
--               referral request per referral post.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.referral_requests (

    -- Primary key. Uniquely identifies each referral request record.
    id                  UUID PRIMARY KEY,

    -- Foreign key referencing the referral post this request pertains to.
    -- Cascades on delete so requests are removed alongside their parent
    -- post.
    post_id             UUID
                            NOT NULL
                            REFERENCES public.referral_posts(id)
                            ON DELETE CASCADE,

    -- Foreign key referencing the job seeker who submitted this referral
    -- request. Cascades on delete so a user's requests are removed
    -- alongside their account.
    requester_id        UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Foreign key referencing the employee responsible for reviewing and
    -- acting on this referral request (typically the referral post
    -- author). Cascades on delete so requests are removed alongside the
    -- referring employee's account.
    employee_id         UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Current lifecycle status of the referral request. Enforced via the
    -- referral_status ENUM type. Defaults to 'Pending' upon submission.
    status              referral_status
                            NOT NULL
                            DEFAULT 'Pending',

    -- Optional message from the requester to the referring employee,
    -- typically explaining fit for the role or providing context.
    message             TEXT,

    -- URL pointing to the requester's resume/CV, typically stored in
    -- Supabase Storage. Required to support the employee's referral
    -- decision.
    resume_url          TEXT
                            NOT NULL
                            CHECK (resume_url ~* '^https?://'),

    -- Timestamp marking when the referral request was created.
    created_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Timestamp marking the most recent update to the referral request
    -- (e.g., status change). Expected to be maintained automatically by
    -- an update trigger defined in a later migration.
    updated_at          TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW(),

    -- Composite uniqueness constraint ensuring a job seeker can submit
    -- only one referral request per referral post.
    CONSTRAINT uq_referral_requests_post_requester UNIQUE (post_id, requester_id),

    -- Ensures a requester cannot submit a referral request naming
    -- themselves as the reviewing employee.
    CONSTRAINT chk_referral_requests_distinct_parties CHECK (requester_id <> employee_id)
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.referral_requests table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.referral_requests IS
    'Job seeker requests for referrals against specific referral posts, tracking status, supporting message, and resume submission.';

COMMENT ON COLUMN public.referral_requests.id IS
    'Primary key. Uniquely identifies each referral request.';

COMMENT ON COLUMN public.referral_requests.post_id IS
    'Foreign key referencing the referral post this request pertains to. Cascades on delete of the referenced post.';

COMMENT ON COLUMN public.referral_requests.requester_id IS
    'Foreign key referencing the job seeker who submitted this referral request. Cascades on delete of the referenced user.';

COMMENT ON COLUMN public.referral_requests.employee_id IS
    'Foreign key referencing the employee responsible for reviewing this referral request. Cascades on delete of the referenced user.';

COMMENT ON COLUMN public.referral_requests.status IS
    'Current lifecycle status of the referral request (Pending, Accepted, Rejected, Cancelled), enforced via the referral_status ENUM. Defaults to Pending.';

COMMENT ON COLUMN public.referral_requests.message IS
    'Optional message from the requester to the referring employee, providing context or justification for the referral request.';

COMMENT ON COLUMN public.referral_requests.resume_url IS
    'URL to the requester''s resume/CV, typically stored in Supabase Storage. Required and must be a well-formed http(s) URL.';

COMMENT ON COLUMN public.referral_requests.created_at IS
    'Timestamp marking when the referral request was created.';

COMMENT ON COLUMN public.referral_requests.updated_at IS
    'Timestamp marking the most recent update to the referral request. Intended to be maintained automatically by an update trigger in a future migration.';

COMMENT ON CONSTRAINT uq_referral_requests_post_requester ON public.referral_requests IS
    'Ensures a given job seeker can submit only one referral request per referral post.';

COMMENT ON CONSTRAINT chk_referral_requests_distinct_parties ON public.referral_requests IS
    'Ensures the requester and reviewing employee are distinct users.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.referral_requests table)
-- =============================================================================
-- -----------------------------------------------------------------------------
-- TABLE: public.notifications
-- Description : Stores in-app notifications delivered to platform users,
--               covering events such as new referral requests, comments,
--               likes, referral decisions, and system-level alerts. Each
--               notification optionally references a related entity (e.g.,
--               a referral post, comment, or referral request) via a
--               generic reference_id column.
-- Relationships:
--   - user_id -> public.users(id) : The recipient of the notification.
--     ON DELETE CASCADE ensures notifications are removed when the
--     recipient user account is deleted.
-- Note        : reference_id is intentionally left as a generic UUID
--               without a foreign key constraint, since it may point to
--               different source tables (referral_posts, comments,
--               referral_requests) depending on notification_type. This
--               polymorphic association is resolved at the application
--               layer.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (

    -- Primary key. Uniquely identifies each notification record.
    id                  UUID PRIMARY KEY,

    -- Foreign key referencing the user who is the recipient of this
    -- notification. Cascades on delete so a user's notifications are
    -- removed alongside their account.
    user_id             UUID
                            NOT NULL
                            REFERENCES public.users(id)
                            ON DELETE CASCADE,

    -- Short, human-readable title summarizing the notification, displayed
    -- prominently in notification lists/UI. Required and must be
    -- non-blank.
    title               VARCHAR(200)
                            NOT NULL
                            CHECK (btrim(title) <> ''),

    -- Full body text of the notification, providing additional context
    -- or detail beyond the title. Required and must be non-blank.
    message             TEXT
                            NOT NULL
                            CHECK (btrim(message) <> ''),

    -- Classification of the notification event. Enforced via the
    -- notification_type ENUM (REFERRAL_REQUEST, COMMENT, LIKE,
    -- REFERRAL_ACCEPTED, REFERRAL_REJECTED, SYSTEM), enabling
    -- type-specific rendering and routing at the application layer.
    notification_type   notification_type
                            NOT NULL,

    -- Generic identifier pointing to the entity associated with this
    -- notification (e.g., a referral post, comment, or referral request
    -- ID), the specific meaning of which depends on notification_type.
    -- Intentionally not enforced via foreign key due to its polymorphic
    -- nature across multiple source tables. Nullable for notifications
    -- of type SYSTEM that may not reference a specific entity.
    reference_id         UUID,

    -- Flag indicating whether the recipient has read this notification.
    -- Defaults to FALSE (unread) upon creation.
    is_read              BOOLEAN
                            NOT NULL
                            DEFAULT FALSE,

    -- Timestamp marking when the notification was created/dispatched.
    created_at           TIMESTAMPTZ
                            NOT NULL
                            DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- COLUMN & TABLE COMMENTS
-- Purpose: Provide enterprise-grade, self-documenting metadata directly in
--          the database catalog for the public.notifications table.
-- -----------------------------------------------------------------------------

COMMENT ON TABLE  public.notifications IS
    'In-app notifications delivered to platform users for events such as referral requests, comments, likes, referral decisions, and system alerts.';

COMMENT ON COLUMN public.notifications.id IS
    'Primary key. Uniquely identifies each notification.';

COMMENT ON COLUMN public.notifications.user_id IS
    'Foreign key referencing the recipient user of this notification. Cascades on delete of the referenced user.';

COMMENT ON COLUMN public.notifications.title IS
    'Short, human-readable title summarizing the notification. Required and must be non-blank.';

COMMENT ON COLUMN public.notifications.message IS
    'Full body text of the notification, providing additional context or detail. Required and must be non-blank.';

COMMENT ON COLUMN public.notifications.notification_type IS
    'Classification of the notification event, enforced via the notification_type ENUM, enabling type-specific rendering and routing.';

COMMENT ON COLUMN public.notifications.reference_id IS
    'Generic identifier of the entity associated with this notification (e.g., referral post, comment, or referral request), interpreted according to notification_type. Not foreign-key constrained due to its polymorphic nature.';

COMMENT ON COLUMN public.notifications.is_read IS
    'Flag indicating whether the recipient has read this notification. Defaults to FALSE (unread).';

COMMENT ON COLUMN public.notifications.created_at IS
    'Timestamp marking when the notification was created and dispatched.';

-- =============================================================================
-- END OF MIGRATION V1.0.0 (public.notifications table)
-- =============================================================================
-- =============================================================================
-- SECTION 4: POST-MIGRATION VALIDATION
-- -----------------------------------------------------------------------------
-- Purpose: Provide a suite of read-only verification queries to confirm
--          that all schema objects defined in this migration (ENUM types,
--          tables, primary keys, foreign keys, unique constraints, and
--          check constraints) were created successfully.
-- Usage  : These queries are diagnostic only. They perform no DDL/DML and
--          are safe to run repeatedly against any environment (local,
--          staging, or production) without side effects. Intended to be
--          run manually or as part of an automated post-deployment
--          smoke-test step in CI/CD pipelines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1 VALIDATION: ENUM TYPES
-- Purpose: Confirm that all four required ENUM types have been created in
--          the public schema.
-- Expected Result: 4 rows (app_role, post_status, referral_status,
--                  notification_type).
-- -----------------------------------------------------------------------------
SELECT
    t.typname                                          AS enum_name,
    n.nspname                                          AS schema_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS enum_values
FROM pg_type t
JOIN pg_namespace n
    ON n.oid = t.typnamespace
JOIN pg_enum e
    ON e.enumtypid = t.oid
WHERE n.nspname = 'public'
  AND t.typname IN (
        'app_role',
        'post_status',
        'referral_status',
        'notification_type'
      )
GROUP BY t.typname, n.nspname
ORDER BY t.typname;


-- -----------------------------------------------------------------------------
-- 4.2 VALIDATION: TABLE EXISTENCE
-- Purpose: Confirm that all six core tables have been created in the
--          public schema.
-- Expected Result: 6 rows (users, referral_posts, comments, likes,
--                  referral_requests, notifications).
-- -----------------------------------------------------------------------------
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
      )
ORDER BY table_name;


-- -----------------------------------------------------------------------------
-- 4.3 VALIDATION: FOREIGN KEY CONSTRAINTS
-- Purpose: Confirm that all expected foreign key relationships exist
--          across the referral_posts, comments, likes, referral_requests,
--          and notifications tables, and that ON DELETE CASCADE is
--          correctly configured.
-- Expected Result: One row per foreign key defined in this migration
--                  (referral_posts.user_id, comments.post_id,
--                  comments.user_id, likes.post_id, likes.user_id,
--                  referral_requests.post_id, referral_requests.requester_id,
--                  referral_requests.employee_id, notifications.user_id).
-- -----------------------------------------------------------------------------
SELECT
    tc.table_name              AS child_table,
    kcu.column_name            AS child_column,
    ccu.table_name             AS referenced_table,
    ccu.column_name            AS referenced_column,
    tc.constraint_name,
    rc.delete_rule              AS on_delete_action
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
   AND tc.table_schema = ccu.table_schema
JOIN information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
   AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
      )
ORDER BY tc.table_name, kcu.column_name;


-- -----------------------------------------------------------------------------
-- 4.4 VALIDATION: PRIMARY KEY CONSTRAINTS
-- Purpose: Confirm that each of the six core tables has a defined primary
--          key on its "id" column.
-- Expected Result: 6 rows, one per table, each showing "id" as the
--                  primary key column.
-- -----------------------------------------------------------------------------
SELECT
    tc.table_name,
    kcu.column_name             AS primary_key_column,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
      )
ORDER BY tc.table_name;


-- -----------------------------------------------------------------------------
-- 4.5 VALIDATION: UNIQUE CONSTRAINTS
-- Purpose: Confirm that all expected UNIQUE constraints exist, including
--          the single-column email uniqueness on users, and the
--          composite uniqueness constraints on likes and
--          referral_requests.
-- Expected Result: Rows for users.email, likes(post_id, user_id), and
--                  referral_requests(post_id, requester_id).
-- -----------------------------------------------------------------------------
SELECT
    tc.table_name,
    tc.constraint_name,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS unique_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
  AND tc.table_name IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
      )
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;


-- -----------------------------------------------------------------------------
-- 4.6 VALIDATION: CHECK CONSTRAINTS
-- Purpose: Confirm that all expected CHECK constraints exist across the
--          schema, including status value restrictions, non-blank text
--          validations, URL/email format validations, and cross-column
--          business rules (e.g., distinct requester/employee parties).
-- Expected Result: One row per CHECK constraint defined in this
--                  migration, excluding system-generated NOT NULL checks.
-- -----------------------------------------------------------------------------
SELECT
    tc.table_name,
    cc.constraint_name,
    cc.check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
    ON cc.constraint_name = tc.constraint_name
   AND cc.constraint_schema = tc.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
        'users',
        'referral_posts',
        'comments',
        'likes',
        'referral_requests',
        'notifications'
      )
  -- Exclude implicit NOT NULL check constraints auto-generated by
  -- PostgreSQL for NOT NULL column definitions, to surface only
  -- explicit business-rule CHECK constraints.
  AND cc.constraint_name NOT LIKE '%_not_null'
ORDER BY tc.table_name, cc.constraint_name;

-- =============================================================================
-- END OF MIGRATION V1.0.0 (VALIDATION SECTION)
-- =============================================================================

