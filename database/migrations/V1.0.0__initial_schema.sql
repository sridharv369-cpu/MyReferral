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
                 and public.likes tables (synchronized from auth and application sources respectively).
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
  employee_email VARCHAR(255) NOT NULL CHECK (employee_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),

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


-- End of migration V1.0.0__initial_schema.sql
-- This file intentionally does not create additional indexes, functions,
-- triggers, or RLS policies. Subsequent migrations should add operational
-- constraints such as indexes and maintenance triggers as needed.
