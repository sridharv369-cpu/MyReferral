/*
================================================================================
PROJECT: MyReferral
VERSION: 1.0.0
DESCRIPTION: Initial schema migration - ENUM types for job referral platform
================================================================================

PURPOSE:
  Establishes foundational PostgreSQL ENUM types required by the MyReferral
  application. This migration creates strongly-typed enumerations for user roles,
  post lifecycle states, referral request statuses, and notification categories.

POSTGRESQL VERSION: 13.0+
SUPABASE COMPATIBILITY: Full compatibility with Supabase PostgreSQL backend
AUTHOR: [Placeholder - DevOps/Database Team]
CREATED: [Placeholder - YYYY-MM-DD]

NOTES:
  - All ENUM types are created idempotently using DO blocks
  - Enumerations follow PostgreSQL naming conventions (snake_case)
  - Type safety enables database-level validation
  - Future migrations will create tables referencing these types

================================================================================
*/


-- ============================================================================
-- SECTION 1: EXTENSION MANAGEMENT
-- ============================================================================

/*
  Enable UUID generation support for primary key management.
  Required for distributed systems and Supabase row-level security.
*/
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

/*
  Enable pgcrypto for cryptographic functions.
  Supports password hashing and secure token generation.
*/
CREATE EXTENSION IF NOT EXISTS pgcrypto;

/*
  Enable pgTrgm for trigram-based text search optimization.
  Improves full-text search performance on job titles and descriptions.
*/
CREATE EXTENSION IF NOT EXISTS pg_trgm;


-- ============================================================================
-- SECTION 2: ENUM TYPES (User Roles)
-- ============================================================================

/*
  TYPE: app_role
  PURPOSE: Defines user authorization levels within the application
  VALUES:
    - user   : Standard user account (job seeker or employee)
    - admin  : Administrator with elevated system privileges

  IDEMPOTENCY: Uses DO block to check type existence before creation
  CONSTRAINTS: Cannot be dropped if tables depend on it
*/
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE app_role AS ENUM (
      'user',
      'admin'
    );
  END IF;
END
$$;


-- ============================================================================
-- SECTION 3: ENUM TYPES (Referral Post Lifecycle)
-- ============================================================================

/*
  TYPE: post_status
  PURPOSE: Represents the lifecycle state of a referral job posting
  VALUES:
    - active   : Post is currently visible and accepting applications
    - draft    : Post in progress, not yet published
    - closed   : Referral position has been filled or closed manually
    - expired  : Post automatically expired after retention period

  IDEMPOTENCY: Uses DO block to prevent duplicate type creation
  BUSINESS LOGIC: Determines visibility in job search and application workflows
*/
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_status') THEN
    CREATE TYPE post_status AS ENUM (
      'active',
      'draft',
      'closed',
      'expired'
    );
  END IF;
END
$$;


-- ============================================================================
-- SECTION 4: ENUM TYPES (Referral Request States)
-- ============================================================================

/*
  TYPE: referral_status
  PURPOSE: Tracks the lifecycle state of individual referral requests
  VALUES:
    - Pending    : Request submitted, awaiting referrer response
    - Accepted   : Referrer has approved the referral request
    - Rejected   : Referrer has declined the referral request
    - Cancelled  : Requester or admin cancelled the request

  IDEMPOTENCY: Uses DO block to ensure single creation
  BUSINESS LOGIC: Drives notification generation and workflow automation
  CASE SENSITIVITY: Values use PascalCase per original specifications
*/
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'referral_status') THEN
    CREATE TYPE referral_status AS ENUM (
      'Pending',
      'Accepted',
      'Rejected',
      'Cancelled'
    );
  END IF;
END
$$;


-- ============================================================================
-- SECTION 5: ENUM TYPES (Notification Categories)
-- ============================================================================

/*
  TYPE: notification_type
  PURPOSE: Categorizes notification events within the application
  VALUES:
    - REFERRAL_REQUEST     : New referral request submitted
    - COMMENT             : New comment on a post or referral
    - LIKE                : User liked a referral post
    - REFERRAL_ACCEPTED   : Referrer accepted a referral request
    - REFERRAL_REJECTED   : Referrer rejected a referral request
    - SYSTEM              : Administrative or automated system notifications

  IDEMPOTENCY: Uses DO block for safe creation in all environments
  BUSINESS LOGIC: Used for notification routing, filtering, and user preferences
  CASE SENSITIVITY: Values use UPPER_SNAKE_CASE per notifications standards
*/
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
    CREATE TYPE notification_type AS ENUM (
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


-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

/*
  STATUS: Successfully created all ENUM types for MyReferral v1.0.0
  NEXT STEPS: Run V1.1.0 migration to create application tables
  ROLLBACK: Drop ENUM types manually if required (BE CAUTIOUS - dependent objects)
*/
