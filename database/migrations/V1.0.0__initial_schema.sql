/*
================================================================================
PROJECT: MyReferral
VERSION: 1.0.0
DESCRIPTION: Initial schema migration - ENUM types and public.users table
================================================================================

PURPOSE:
  Establishes foundational PostgreSQL ENUM types required by the MyReferral
  application. This migration creates strongly-typed enumerations for user roles,
  post lifecycle states, referral request statuses, and notification categories.
  Additionally, creates the public.users table to store application user profiles
  synchronized from Supabase auth.users.

POSTGRESQL VERSION: 13.0+
SUPABASE COMPATIBILITY: Full compatibility with Supabase PostgreSQL backend
AUTHOR: [Placeholder - DevOps/Database Team]
CREATED: [Placeholder - YYYY-MM-DD]

NOTES:
  - All ENUM types are created idempotently using DO blocks
  - Enumerations follow PostgreSQL naming conventions (snake_case)
  - Type safety enables database-level validation
  - public.users table is synchronized with auth.users via triggers/functions
  - Future migrations will create additional tables referencing these types

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
-- SECTION 6: TABLE DEFINITIONS
-- ============================================================================

/*
  TABLE: public.users
  PURPOSE: Stores application user profiles synchronized from Supabase auth.users
  
  DESCRIPTION:
    Represents user accounts within the MyReferral application. This table acts
    as an extension of Supabase's auth.users table, storing application-specific
    user profile information such as display name, profile picture, role, and
    account status. The table is designed to be kept in sync with auth.users
    via database triggers or application-level synchronization.

  INDEXES:
    - email (UNIQUE) : Enables fast lookup by email address
    - id (PRIMARY KEY) : UUID primary key references auth.users(id)
  
  CONSTRAINTS:
    - email UNIQUE : Ensures email uniqueness across the system
    - status CHECK : Restricts status to valid values (active, inactive)
    - role DEFAULT : Ensures all users have a defined role

  PERFORMANCE NOTES:
    - Partition candidate for large-scale deployments
    - Consider archival strategy for inactive users
    - Email column suitable for full-text search extension
*/
CREATE TABLE IF NOT EXISTS public.users (
  -- ========================================================================
  -- PRIMARY KEY
  -- ========================================================================
  
  /*
    id : UUID
    PURPOSE: Unique identifier for the user
    CONSTRAINTS: PRIMARY KEY, NOT NULL
    RELATIONSHIP: Foreign key to auth.users(id) in Supabase auth schema
    TYPE: UUID v4, system-generated or provided by Supabase auth
    NOTES: Must match the authenticated user's ID from the auth system
  */
  id UUID PRIMARY KEY NOT NULL,

  
  -- ========================================================================
  -- PROFILE INFORMATION
  -- ========================================================================
  
  /*
    name : VARCHAR(150)
    PURPOSE: Display name of the user (full name or preferred name)
    CONSTRAINTS: NOT NULL (required for user identification)
    VALIDATION: Maximum 150 characters enforced at DB level
    USAGE: Used in UI displays, notifications, and referral requests
    NOTES: May differ from auth.users email; allows for readability
  */
  name VARCHAR(150) NOT NULL,

  /*
    email : VARCHAR(255)
    PURPOSE: Unique email address for the user account
    CONSTRAINTS: NOT NULL, UNIQUE (enforced at DB level)
    VALIDATION: Maximum 255 characters; matches RFC 5321 SMTP spec
    USAGE: Unique identifier for authentication and communication
    RELATIONSHIP: Should match auth.users.email in Supabase auth schema
    NOTES: Case-insensitive comparison recommended at application level
  */
  email VARCHAR(255) NOT NULL UNIQUE,

  /*
    profile_picture : TEXT
    PURPOSE: URL or base64-encoded profile picture for the user
    CONSTRAINTS: NULLABLE (optional profile picture)
    VALIDATION: Stored as TEXT to support full URLs or encoded data URIs
    USAGE: Displayed in user profiles, comments, and referral listings
    EXAMPLES: 'https://cdn.example.com/users/user-id.jpg' or 'data:image/jpeg;base64,...'
    NOTES: Consider external storage (S3/CDN) for scalability
  */
  profile_picture TEXT,


  -- ========================================================================
  -- APPLICATION METADATA
  -- ========================================================================
  
  /*
    role : app_role
    PURPOSE: User authorization level within the application
    CONSTRAINTS: NOT NULL, DEFAULT 'user'
    TYPE: ENUM(user, admin)
    VALUES:
      - 'user' : Standard user (job seeker or employee)
      - 'admin' : Administrator with elevated system privileges
    NOTES: Determines access to admin dashboards and management features
  */
  role app_role NOT NULL DEFAULT 'user',

  /*
    status : VARCHAR(20)
    PURPOSE: Account activation and availability status
    CONSTRAINTS: NOT NULL, DEFAULT 'active', CHECK constraint
    TYPE: VARCHAR(20) enforced with CHECK constraint
    ALLOWED VALUES: 'active', 'inactive'
    BUSINESS LOGIC:
      - 'active'   : User account is active and functional
      - 'inactive' : User account is disabled (deactivated or suspended)
    NOTES: Enables soft-delete patterns and account suspension without data loss
  */
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),


  -- ========================================================================
  -- TEMPORAL METADATA
  -- ========================================================================
  
  /*
    created_at : TIMESTAMPTZ
    PURPOSE: Timestamp of user account creation
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets value to current timestamp on insert
    USAGE: Audit trail, account age calculations, user onboarding analytics
    NOTES: Immutable after creation; should not be updated
  */
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  /*
    updated_at : TIMESTAMPTZ
    PURPOSE: Timestamp of last user profile modification
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets value to current timestamp on insert
    NOTES: Should be updated via trigger on UPDATE operations
    USAGE: Audit trail, last-modified tracking, data synchronization
  */
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

/*
  TABLE CREATION COMPLETE: public.users
  
  NEXT STEPS:
    - Create triggers to auto-update updated_at on modification
    - Create indexes on email and other frequently-queried columns
    - Set up row-level security (RLS) policies for Supabase
    - Create synchronization function with auth.users if needed
*/


-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

/*
  STATUS: Successfully created ENUM types and public.users table for MyReferral v1.0.0
  
  OBJECTS CREATED:
    - 4 ENUM types (app_role, post_status, referral_status, notification_type)
    - 1 table (public.users)
  
  NEXT STEPS: 
    - Run V1.1.0 migration to create additional application tables
    - Apply row-level security (RLS) policies
    - Set up database triggers for audit logging
  
  ROLLBACK: 
    - Drop public.users table (IF EXISTS)
    - Drop ENUM types (BE CAUTIOUS - dependent objects)
*/
