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
                 types. It is idempotent and safe to run multiple times.
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


-- End of migration V1.0.0__initial_schema.sql
-- This file intentionally does not create tables, indexes, functions, triggers, or RLS.
-- Subsequent migrations should reference these types as needed.
