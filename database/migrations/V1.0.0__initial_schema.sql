/********************************************************************************
 Project:        MyReferral
 Migration:      V1.0.0__initial_schema.sql
 Description:    Initial schema primitives — create required ENUM types and enable
                 recommended PostgreSQL extensions for Supabase compatibility.
 PostgreSQL:     >= 13.0  -- replace with actual target PG version if different
 Supabase:       Compatible (recommended extensions enabled)
 Author:         <AUTHOR_NAME_PLACEHOLDER>
 Created:        <CREATED_DATE_PLACEHOLDER>
 Notes:          This migration intentionally creates only extensions and ENUM
                 types. It is idempotent and safe to run multiple times. This
                 revision adds the public.users, public.referral_posts, public.comments,
                 public.likes, public.referral_requests, and public.notifications tables
                 (synchronized from auth and application sources respectively).
********************************************************************************/

-- =========================
-- Extensions (idempotent)
-- =========================
-- pgcrypto:   recommended on Supabase for gen_random_uuid() and cryptographic helpers
-- citext:     case-insensitive text type (useful at application layer)
-- uuid-ossp:  legacy UUID generation functions (optional; pgcrypto is preferred)
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- =============================================================================
-- ENUM: app_role
-- Purpose: canonical application-level roles used for authorization checks.
-- Values:  'user', 'admin'
-- Idempotency: guarded by existence check against pg_type for enum type.
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'app_role' AND t.typtype = 'e' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.app_role AS ENUM ('user', 'admin');
    COMMENT ON TYPE public.app_role IS
      'Application role enumeration. Values: user, admin. Used for RBAC and access control.';
  END IF;
END$$;


-- =============================================================================
-- ENUM: post_status
-- Purpose: lifecycle status of a referral post/opportunity.
-- Values:  'active', 'draft', 'closed', 'expired'
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'post_status' AND t.typtype = 'e' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.post_status AS ENUM ('active', 'draft', 'closed', 'expired');
    COMMENT ON TYPE public.post_status IS
      'Status for referral posts: active, draft, closed, expired. Controls visibility and workflow.';
  END IF;
END$$;


-- =============================================================================
-- ENUM: referral_status
-- Purpose: status of a referral request between a seeker and an employee/referrer.
-- Values:  'Pending', 'Accepted', 'Rejected', 'Cancelled'
-- Note: values are capitalized to preserve business-domain terminology.
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'referral_status' AND t.typtype = 'e' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.referral_status AS ENUM ('Pending', 'Accepted', 'Rejected', 'Cancelled');
    COMMENT ON TYPE public.referral_status IS
      'Referral request lifecycle statuses. Values: Pending, Accepted, Rejected, Cancelled.';
  END IF;
END$$;


-- =============================================================================
-- ENUM: notification_type
-- Purpose: categorizes notification events emitted by the platform.
-- Values:
--   REFERRAL_REQUEST,
--   COMMENT,
--   LIKE,
--   REFERRAL_ACCEPTED,
--   REFERRAL_REJECTED,
--   SYSTEM
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE t.typname = 'notification_type' AND t.typtype = 'e' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.notification_type AS ENUM (
      'REFERRAL_REQUEST',
      'COMMENT',
      'LIKE',
      'REFERRAL_ACCEPTED',
      'REFERRAL_REJECTED',
      'SYSTEM'
    );
    COMMENT ON TYPE public.notification_type IS
      'Types of notifications produced by the system. Used to route and render notifications.';
  END IF;
END$$;


-- =============================================================================
-- TABLE: public.users
-- Purpose: Application user profiles. This table is synchronized from auth.users
--          (Supabase / external auth provider). It stores profile metadata used
--          across the MyReferral application while the authoritative auth state
--          remains in auth.users. This migration creates the table only if it
--          does not already exist to preserve idempotency.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  -- Primary identifier. Mirrors auth.users.id; do not set a default to ensure
  -- synchronization keeps identifiers consistent.
  id UUID PRIMARY KEY,

  -- Display name for the user. Kept reasonably sized for UI storage.
  name VARCHAR(150),

  -- Email address used for communication and uniqueness within the application.
  email VARCHAR(255) NOT NULL UNIQUE,

  -- Link or blob reference to profile image; stored as text to support URLs or
  -- base64/JSON references as the product evolves.
  profile_picture TEXT,

  -- Application role; constrained to values defined by app_role ENUM. Default
  -- to 'user' for newly provisioned profiles.
  role public.app_role NOT NULL DEFAULT 'user',

  -- Simple status flag for the profile's operational state within the
  -- application domain. Constrained to accepted values via CHECK.
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),

  -- Timestamps for auditing and synchronization logic.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.users
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.users IS
  'User profile metadata synchronized from auth.users. Used by application UX and business logic.';

COMMENT ON COLUMN public.users.id IS
  'Primary key (UUID). Mirrors auth.users.id; used to join application data to auth records.';

COMMENT ON COLUMN public.users.name IS
  'Human-readable display name for the user; max length 150 characters.';

COMMENT ON COLUMN public.users.email IS
  'Primary contact email for the user. Enforced UNIQUE in the application schema.';

COMMENT ON COLUMN public.users.profile_picture IS
  'URI or serialized reference to the user''s profile picture (nullable).';

COMMENT ON COLUMN public.users.role IS
  'Application role for RBAC. Type: app_role ENUM. Default: ''user''. Not nullable.';

COMMENT ON COLUMN public.users.status IS
  'Operational profile status within the application. Allowed values: active, inactive.';

COMMENT ON COLUMN public.users.created_at IS
  'Record creation timestamp (UTC). Default: now() at insertion time.';

COMMENT ON COLUMN public.users.updated_at IS
  'Record last-updated timestamp (UTC). Application should update this when profile changes.';


-- =============================================================================
-- TABLE: public.referral_posts
-- Purpose: Stores referral opportunities posted by employees. These records are
--          authored by users and reference public.users(id). The table captures
--          job metadata, application links, location, work mode, and a search
--          vector for full-text search. Created idempotently.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.referral_posts (
  -- Primary key for the referral post. UUID to align with distributed ID strategy.
  id UUID PRIMARY KEY,

  -- Reference to the posting user (author). Cascades on user deletion to keep
  -- data consistent with application-level expectations.
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Employer / company information
  company_name VARCHAR(255) NOT NULL,
  company_url TEXT NOT NULL CHECK (company_url ~* '^https?://'),

  -- Optional external job identifier provided by the company or ATS.
  job_id VARCHAR(128) NOT NULL CHECK (char_length(job_id) > 0),

  -- Role/title being referred to (e.g., Software Engineer II).
  role VARCHAR(150) NOT NULL,

  -- Comma- or space-separated skills or structured JSON-as-text. Kept as TEXT
  -- to allow flexible representations but required for searchability.
  key_skills TEXT NOT NULL CHECK (char_length(key_skills) > 0),

  -- Full job description / responsibilities / qualifications.
  job_description TEXT NOT NULL CHECK (char_length(job_description) > 0),

  -- Contact email of the internal employee posting the referral.
  employee_email VARCHAR(255) NOT NULL CHECK (employee_email ~* '^[^@\\s]+@[^@\\s]+\.[^@\\s]+$'),

  -- Canonical URL where applicants can apply for the role.
  job_apply_url TEXT NOT NULL CHECK (job_apply_url ~* '^https?://'),

  -- Location details
  location VARCHAR(150) NOT NULL,
  country VARCHAR(100) NOT NULL,

  -- Work mode (e.g., remote, onsite, hybrid). Kept as VARCHAR to allow
  -- future extensibility; enforce non-empty value here.
  work_mode VARCHAR(50) NOT NULL CHECK (char_length(work_mode) > 0),

  -- Status of the post (uses post_status ENUM defined earlier).
  status public.post_status NOT NULL DEFAULT 'active',

  -- Pre-populated tsvector for full-text search. Default empty vector to
  -- maintain NOT NULL requirement; application is expected to maintain its
  -- semantics (recompute on updates if desired).
  search_vector tsvector NOT NULL DEFAULT to_tsvector('english', ''),

  -- Auditing timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.referral_posts
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.referral_posts IS
  'Referral opportunities posted by users. Contains job metadata, application links, and search vector.';

COMMENT ON COLUMN public.referral_posts.id IS
  'Primary key (UUID) for the referral post.';

COMMENT ON COLUMN public.referral_posts.user_id IS
  'Foreign key to public.users(id). The user who created the referral post.';

COMMENT ON COLUMN public.referral_posts.company_name IS
  'Official company name for the referral opportunity.';

COMMENT ON COLUMN public.referral_posts.company_url IS
  'Public URL for the company; must be an HTTP(S) URI.';

COMMENT ON COLUMN public.referral_posts.job_id IS
  'Vendor or internal job identifier. Useful for deduplication with ATS feeds.';

COMMENT ON COLUMN public.referral_posts.role IS
  'Job title or role name for the referral.';

COMMENT ON COLUMN public.referral_posts.key_skills IS
  'Skills or keywords relevant to the role; free-text for flexibility.';

COMMENT ON COLUMN public.referral_posts.job_description IS
  'Full job description text used for display and search.';

COMMENT ON COLUMN public.referral_posts.employee_email IS
  'Email address of the posting employee; used as contact metadata.';

COMMENT ON COLUMN public.referral_posts.job_apply_url IS
  'Canonical application URL where candidates can apply; must be HTTP(S).';

COMMENT ON COLUMN public.referral_posts.location IS
  'Human-readable location string (city, state/province) for the role.';

COMMENT ON COLUMN public.referral_posts.country IS
  'ISO country name or code for the role location.';

COMMENT ON COLUMN public.referral_posts.work_mode IS
  'Work mode such as remote, onsite, or hybrid.';

COMMENT ON COLUMN public.referral_posts.status IS
  'Post lifecycle status. Type: post_status ENUM. Default: active.';

COMMENT ON COLUMN public.referral_posts.search_vector IS
  'TSVECTOR used for full-text search over job_description, company_name, role, and key_skills.';

COMMENT ON COLUMN public.referral_posts.created_at IS
  'Record creation timestamp (UTC). Default: now().' ;

COMMENT ON COLUMN public.referral_posts.updated_at IS
  'Record last-updated timestamp (UTC). Application should update this when the post changes.';


-- =============================================================================
-- TABLE: public.comments
-- Purpose: Stores user comments on referral posts. Each comment is associated
--          with a referral_post and authored by a user. Cascade deletes are in
--          place to remove comments if the parent post or user is deleted.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.comments (
  -- Primary identifier for the comment.
  id UUID PRIMARY KEY,

  -- Reference to the referral post this comment belongs to.
  post_id UUID NOT NULL REFERENCES public.referral_posts(id) ON DELETE CASCADE,

  -- Reference to the user who authored the comment.
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- The textual content of the comment.
  comment_text TEXT NOT NULL CHECK (char_length(comment_text) > 0),

  -- Auditing timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.comments
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.comments IS
  'Comments left by users on referral_posts. Used for discussion and clarification.';

COMMENT ON COLUMN public.comments.id IS
  'Primary key (UUID) for the comment record.';

COMMENT ON COLUMN public.comments.post_id IS
  'Foreign key to public.referral_posts(id). The post this comment pertains to.';

COMMENT ON COLUMN public.comments.user_id IS
  'Foreign key to public.users(id). The user who authored the comment.';

COMMENT ON COLUMN public.comments.comment_text IS
  'Text body of the comment. Non-empty.';

COMMENT ON COLUMN public.comments.created_at IS
  'Timestamp when the comment was created (UTC). Default: now().' ;

COMMENT ON COLUMN public.comments.updated_at IS
  'Timestamp when the comment was last updated (UTC). Application should update on edits.';


-- =============================================================================
-- TABLE: public.likes
-- Purpose: Records user "likes" (upvotes) for referral posts. Each record
--          represents a single user expressing interest in a referral post.
--          Enforces uniqueness on (post_id, user_id) to prevent duplicate likes.
-- Idempotency: created only if the table does not already exist.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.likes (
  -- Primary identifier for the like record. Uses UUIDs consistent with other tables.
  id UUID PRIMARY KEY,

  -- Reference to the referral post that received the like. Cascades on post
  -- deletion to remove associated likes automatically.
  post_id UUID NOT NULL REFERENCES public.referral_posts(id) ON DELETE CASCADE,

  -- Reference to the user who liked the post. Cascades on user deletion to
  -- remove associated likes automatically.
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Ensure a given user can like a specific post only once.
  CONSTRAINT likes_post_user_unique UNIQUE (post_id, user_id),

  -- Timestamp when the like was created.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.likes
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.likes IS
  'Like/upvote records for referral_posts. Each row denotes that a user liked a post. Unique per (post_id,user_id).';

COMMENT ON COLUMN public.likes.id IS
  'Primary key (UUID) for the like record. Use application logic to generate or supply UUIDs.';

COMMENT ON COLUMN public.likes.post_id IS
  'Foreign key to public.referral_posts(id). The post that received the like; cascades on post deletion.';

COMMENT ON COLUMN public.likes.user_id IS
  'Foreign key to public.users(id). The user who performed the like; cascades on user deletion.';

COMMENT ON COLUMN public.likes.created_at IS
  'Creation timestamp (UTC) for the like record. Defaults to now().' ;


-- =============================================================================
-- TABLE: public.referral_requests
-- Purpose: Tracks requests from job seekers (requester) to employees (referrer)
--          to provide a referral for a specific referral_post. The table
--          contains optional message/resume metadata and a status using the
--          referral_status ENUM. Enforces uniqueness to prevent duplicate
--          requests for the same post by the same requester.
-- Idempotency: created only if the table does not already exist.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.referral_requests (
  -- Primary identifier for the referral request.
  id UUID PRIMARY KEY,

  -- The post that the requester is asking to be referred to.
  post_id UUID NOT NULL REFERENCES public.referral_posts(id) ON DELETE CASCADE,

  -- The user requesting the referral (job seeker).
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- The internal employee expected to provide the referral.
  employee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Current status of the referral request. Default to 'Pending' at creation.
  status public.referral_status NOT NULL DEFAULT 'Pending',

  -- Message from the requester to the employee; required and non-empty.
  message TEXT NOT NULL CHECK (char_length(message) > 0),

  -- URL to the requester's resume (HTTP/HTTPS expected).
  resume_url TEXT NOT NULL CHECK (resume_url ~* '^https?://'),

  -- Auditing timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Prevent duplicate requests for the same post by the same requester.
  CONSTRAINT referral_requests_post_requester_unique UNIQUE (post_id, requester_id)
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.referral_requests
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.referral_requests IS
  'Referral requests created by job seekers asking employees to refer them for a referral_post.';

COMMENT ON COLUMN public.referral_requests.id IS
  'Primary key (UUID) for the referral request record.';

COMMENT ON COLUMN public.referral_requests.post_id IS
  'Foreign key to public.referral_posts(id). The post the requester is applying for.';

COMMENT ON COLUMN public.referral_requests.requester_id IS
  'Foreign key to public.users(id). The user who requested the referral (job seeker).';

COMMENT ON COLUMN public.referral_requests.employee_id IS
  'Foreign key to public.users(id). The employee intended to provide the referral.';

COMMENT ON COLUMN public.referral_requests.status IS
  'Lifecycle status of the referral request. Type: referral_status ENUM. Default: Pending.';

COMMENT ON COLUMN public.referral_requests.message IS
  'Message from the requester to the employee explaining interest and fit; non-empty.';

COMMENT ON COLUMN public.referral_requests.resume_url IS
  'HTTP(S) URL to the requester\'s resume or CV.';

COMMENT ON COLUMN public.referral_requests.created_at IS
  'Timestamp when the referral request was created (UTC). Default: now().' ;

COMMENT ON COLUMN public.referral_requests.updated_at IS
  'Timestamp when the referral request was last updated (UTC). Application should update on status changes.';


-- =============================================================================
-- TABLE: public.notifications
-- Purpose: Stores user-facing notifications generated by the system. Each
--          notification belongs to a user and may reference an application
--          entity via reference_id. Notifications can be marked read/unread.
-- Idempotency: created only if the table does not already exist.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  -- Primary identifier for the notification record. UUID recommended.
  id UUID PRIMARY KEY,

  -- The recipient user for the notification.
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Short, display-friendly title for the notification.
  title VARCHAR(255) NOT NULL,

  -- Longer message/body of the notification.
  message TEXT NOT NULL,

  -- Notification category/type driven by the notification_type ENUM.
  notification_type public.notification_type NOT NULL,

  -- Optional reference to an application entity (e.g., post, request, comment).
  reference_id UUID,

  -- Read-state of the notification for the recipient.
  is_read BOOLEAN NOT NULL DEFAULT FALSE,

  -- When the notification was created.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Column-level comments for public.notifications
-- -----------------------------------------------------------------------------
COMMENT ON TABLE public.notifications IS
  'User notifications produced by the system. Each row belongs to a user and may reference another entity via reference_id.';

COMMENT ON COLUMN public.notifications.id IS
  'Primary key (UUID) for the notification record.';

COMMENT ON COLUMN public.notifications.user_id IS
  'Foreign key to public.users(id). The user who receives the notification; cascades on user deletion.';

COMMENT ON COLUMN public.notifications.title IS
  'Short title used in notification UI.';

COMMENT ON COLUMN public.notifications.message IS
  'Full notification message/body.';

COMMENT ON COLUMN public.notifications.notification_type IS
  'Categorizes the notification. Type: notification_type ENUM.';

COMMENT ON COLUMN public.notifications.reference_id IS
  'Optional UUID referencing an application entity related to the notification (e.g., post id, request id, comment id).';

COMMENT ON COLUMN public.notifications.is_read IS
  'Boolean flag indicating whether the user has read the notification. Default: false.';

COMMENT ON COLUMN public.notifications.created_at IS
  'Timestamp when the notification was created (UTC). Default: now().' ;


-- =============================================================================
-- Validation queries (READ-ONLY)
-- Purpose: Run these SELECT statements to validate that the migration
--          created the expected types, tables, and constraints. These queries
--          are intentionally read-only and safe for production environments.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Verify ENUM types exist in public schema
-- -----------------------------------------------------------------------------
SELECT n.nspname AS schema_name,
       t.typname  AS enum_type
FROM pg_type t
JOIN pg_namespace n ON t.typnamespace = n.oid
WHERE t.typtype = 'e'
  AND n.nspname = 'public'
  AND t.typname IN ('app_role', 'post_status', 'referral_status', 'notification_type')
ORDER BY t.typname;

-- -----------------------------------------------------------------------------
-- 2) Verify required tables exist in public schema
-- -----------------------------------------------------------------------------
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'referral_posts', 'comments', 'likes', 'referral_requests', 'notifications')
ORDER BY table_name;

-- -----------------------------------------------------------------------------
-- 3) List FOREIGN KEY constraints in public schema with referencing and referenced
--    table/column detail. Useful to confirm ON DELETE behaviors.
-- -----------------------------------------------------------------------------
SELECT
  tc.constraint_name,
  tc.table_schema,
  tc.table_name,
  kcu.column_name AS referencing_column,
  ccu.table_schema AS referenced_table_schema,
  ccu.table_name   AS referenced_table,
  ccu.column_name  AS referenced_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name AND ccu.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position;

-- -----------------------------------------------------------------------------
-- 4) List PRIMARY KEY constraints and their columns for the target tables
-- -----------------------------------------------------------------------------
SELECT tc.table_schema,
       tc.table_name,
       tc.constraint_name,
       string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS pk_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('users', 'referral_posts', 'comments', 'likes', 'referral_requests', 'notifications')
GROUP BY tc.table_schema, tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- -----------------------------------------------------------------------------
-- 5) List UNIQUE constraints for public schema (to verify email uniqueness and
--    likes/referral_requests uniqueness)
-- -----------------------------------------------------------------------------
SELECT tc.table_schema,
       tc.table_name,
       tc.constraint_name,
       string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS unique_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('users', 'likes', 'referral_requests')
GROUP BY tc.table_schema, tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- -----------------------------------------------------------------------------
-- 6) List CHECK constraints defined on the public tables (status, non-empty text,
--    URL/email regex checks, etc.)
-- -----------------------------------------------------------------------------
SELECT tc.table_schema,
       tc.table_name,
       cc.constraint_name,
       cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
  ON cc.constraint_name = tc.constraint_name AND cc.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'CHECK'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('users', 'referral_posts', 'comments', 'referral_requests')
ORDER BY tc.table_name, cc.constraint_name;

-- -----------------------------------------------------------------------------
-- End of validation queries
-- Review the results above to confirm the migration applied the expected schema
-- objects. These SELECT statements are read-only and safe to run against any
-- environment (dev/staging/production).
-- -----------------------------------------------------------------------------
