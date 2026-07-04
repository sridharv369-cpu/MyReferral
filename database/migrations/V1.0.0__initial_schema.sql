/*
================================================================================
PROJECT: MyReferral
VERSION: 1.0.0
DESCRIPTION: Initial schema migration - ENUM types, users, referral_posts, comments, and likes
================================================================================

PURPOSE:
  Establishes foundational PostgreSQL ENUM types required by the MyReferral
  application. This migration creates strongly-typed enumerations for user roles,
  post lifecycle states, referral request statuses, and notification categories.
  Additionally, creates the public.users table to store application user profiles
  synchronized from Supabase auth.users, the referral_posts table containing
  job referral opportunities posted by employees, the comments table for
  discussion on referral posts, and the likes table for user engagement tracking.

POSTGRESQL VERSION: 13.0+
SUPABASE COMPATIBILITY: Full compatibility with Supabase PostgreSQL backend
AUTHOR: [Placeholder - DevOps/Database Team]
CREATED: [Placeholder - YYYY-MM-DD]

NOTES:
  - All ENUM types are created idempotently using DO blocks
  - Enumerations follow PostgreSQL naming conventions (snake_case)
  - Type safety enables database-level validation
  - public.users table is synchronized with auth.users via triggers/functions
  - referral_posts table contains job opportunities with full-text search support
  - comments table stores threaded discussions on referral posts
  - likes table tracks user engagement with referral posts
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
-- TABLE: public.referral_posts
-- ============================================================================

/*
  TABLE: public.referral_posts
  PURPOSE: Stores job referral opportunities posted by employees
  
  DESCRIPTION:
    Represents internal job referral opportunities within organizations.
    Employees post these referrals to help connect job seekers with open
    positions. Each post contains comprehensive job details, company
    information, and the employee's contact information for coordination.
    The table supports full-text search via tsvector for efficient
    job discovery.

  RELATIONSHIPS:
    - user_id : Foreign key to public.users(id)
      Represents the employee who posted the referral opportunity

  SEARCH CAPABILITIES:
    - search_vector : TSVECTOR column for PostgreSQL full-text search
      Indexes job title, description, and skills for fast discovery

  CONSTRAINTS:
    - ON DELETE CASCADE : When user is deleted, all their referral posts are removed
    - Status : Limited to valid post_status ENUM values
    - URL validation : job_apply_url should be valid HTTP(S) URL
    - Email validation : employee_email should be valid email format

  PERFORMANCE NOTES:
    - search_vector enables GiST/GIN indexing for full-text queries
    - consider partitioning by created_at for very large deployments
    - status and user_id are excellent filter candidates

  AUDIT & LIFECYCLE:
    - created_at : Immutable timestamp of post creation
    - updated_at : Timestamp updated on any post modification
    - status : Controls post visibility (active/draft/closed/expired)
*/
CREATE TABLE IF NOT EXISTS public.referral_posts (
  -- ========================================================================
  -- PRIMARY KEY
  -- ========================================================================
  
  /*
    id : UUID
    PURPOSE: Unique identifier for each referral post
    CONSTRAINTS: PRIMARY KEY, NOT NULL
    GENERATION: UUID v4 generated by uuid_generate_v4()
    USAGE: Unique reference across the application
  */
  id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),

  
  -- ========================================================================
  -- FOREIGN KEY RELATIONSHIPS
  -- ========================================================================
  
  /*
    user_id : UUID
    PURPOSE: Employee who posted the referral opportunity
    CONSTRAINTS: NOT NULL, FOREIGN KEY with ON DELETE CASCADE
    RELATIONSHIP: References public.users(id)
    CASCADE BEHAVIOR: When the user is deleted, all their posts are deleted
    NOTES: Enables easy cleanup when employee leaves or account is closed
  */
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,


  -- ========================================================================
  -- COMPANY INFORMATION
  -- ========================================================================
  
  /*
    company_name : VARCHAR(255)
    PURPOSE: Name of the company hiring
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 255 characters
    USAGE: Display in job listings and referral details
    EXAMPLES: 'Google', 'Meta', 'Microsoft'
  */
  company_name VARCHAR(255) NOT NULL,

  /*
    company_url : TEXT
    PURPOSE: Official website URL of the hiring company
    CONSTRAINTS: NOT NULL
    TYPE: TEXT to accommodate full URLs with protocols and query params
    VALIDATION: Should be valid HTTP(S) URL format
    USAGE: Links job seekers to company website for research
    EXAMPLES: 'https://www.google.com', 'https://careers.meta.com'
  */
  company_url TEXT NOT NULL,


  -- ========================================================================
  -- JOB POSTING DETAILS
  -- ========================================================================
  
  /*
    job_id : VARCHAR(100)
    PURPOSE: Unique identifier for the job at the company's system
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 100 characters
    USAGE: Track and reference the specific opening with recruiter
    EXAMPLES: 'JOB_ID_12345', 'GOOGLE-ENG-2024-001'
    NOTES: Typically provided by company's ATS or job board
  */
  job_id VARCHAR(100) NOT NULL,

  /*
    role : VARCHAR(255)
    PURPOSE: Job title or position name
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 255 characters
    USAGE: Displayed in search results and job listings
    EXAMPLES: 'Senior Software Engineer', 'Product Manager', 'UX Designer'
  */
  role VARCHAR(255) NOT NULL,

  /*
    key_skills : TEXT
    PURPOSE: Comma-separated or JSON-formatted list of required/preferred skills
    CONSTRAINTS: NOT NULL
    TYPE: TEXT for flexibility in formatting (CSV or JSON)
    USAGE: Skills-based filtering and search
    EXAMPLES: 'Python, PostgreSQL, React', 'JavaScript, Node.js, AWS'
    NOTES: Consider structured format (JSON) for future migration
  */
  key_skills TEXT NOT NULL,

  /*
    job_description : TEXT
    PURPOSE: Comprehensive job description and responsibilities
    CONSTRAINTS: NOT NULL
    TYPE: TEXT for lengthy content
    CONTENT: Full job posting text, requirements, and benefits
    USAGE: Full-text search, detailed job display
    NOTES: Indexed in search_vector for discovery
  */
  job_description TEXT NOT NULL,


  -- ========================================================================
  -- REFERRER CONTACT INFORMATION
  -- ========================================================================
  
  /*
    employee_email : VARCHAR(255)
    PURPOSE: Contact email of the employee making the referral
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 255 characters, should be valid email format
    USAGE: Job seekers contact referrer about the opportunity
    EXAMPLES: 'john.doe@company.com', 'referrer@mycompany.com'
    NOTES: Application should validate email format before insert
  */
  employee_email VARCHAR(255) NOT NULL,

  /*
    job_apply_url : TEXT
    PURPOSE: URL to apply for the job position
    CONSTRAINTS: NOT NULL
    TYPE: TEXT to accommodate full application URLs
    VALIDATION: Should be valid HTTP(S) URL
    USAGE: Direct link for applicants to submit resume/application
    EXAMPLES: 'https://careers.google.com/job/123', 'https://company.com/apply?id=456'
    NOTES: Can redirect to application portal or ATS system
  */
  job_apply_url TEXT NOT NULL,


  -- ========================================================================
  -- JOB LOCATION & WORK ARRANGEMENT
  -- ========================================================================
  
  /*
    location : VARCHAR(255)
    PURPOSE: City and/or office location for the job
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 255 characters
    USAGE: Filter and display job location in listings
    EXAMPLES: 'San Francisco, CA', 'New York', 'Seattle, WA'
  */
  location VARCHAR(255) NOT NULL,

  /*
    country : VARCHAR(100)
    PURPOSE: Country where the job is located
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 100 characters (ISO country names)
    USAGE: Geographic filtering and job market analysis
    EXAMPLES: 'United States', 'Canada', 'India', 'Germany'
  */
  country VARCHAR(100) NOT NULL,

  /*
    work_mode : VARCHAR(50)
    PURPOSE: Work arrangement type
    CONSTRAINTS: NOT NULL
    VALIDATION: Maximum 50 characters
    ALLOWED VALUES: 'remote', 'on-site', 'hybrid' (application-level validation)
    USAGE: Filter jobs by work arrangement preference
    EXAMPLES: 'remote', 'on-site', 'hybrid'
    NOTES: Consider converting to ENUM type in future migrations
  */
  work_mode VARCHAR(50) NOT NULL,


  -- ========================================================================
  -- POST STATUS & LIFECYCLE
  -- ========================================================================
  
  /*
    status : post_status
    PURPOSE: Current lifecycle state of the referral post
    CONSTRAINTS: NOT NULL, DEFAULT 'active'
    TYPE: ENUM(active, draft, closed, expired)
    VALUES:
      - 'active'  : Post is visible and accepting applications
      - 'draft'   : Post saved but not yet published
      - 'closed'  : Position filled or post manually closed
      - 'expired' : Post automatically expired (old postings)
    BUSINESS_LOGIC: Controls visibility in search and filtering
    NOTES: Expired posts can be archived or hidden from searches
  */
  status post_status NOT NULL DEFAULT 'active',


  -- ========================================================================
  -- FULL-TEXT SEARCH SUPPORT
  -- ========================================================================
  
  /*
    search_vector : TSVECTOR
    PURPOSE: PostgreSQL full-text search vector for efficient job discovery
    CONSTRAINTS: NULLABLE (populated by trigger/application logic)
    TYPE: TSVECTOR (PostgreSQL's native full-text search type)
    INDEXED: Can be indexed with GiST or GIN for fast queries
    CONTAINS: Searchable text from job title, description, skills, company
    USAGE: Enables fast full-text queries like: plainto_tsquery('python AND aws')
    NOTES: Typically updated by trigger when role/job_description/key_skills change
    EXAMPLE_QUERY: 
      SELECT * FROM public.referral_posts 
      WHERE search_vector @@ plainto_tsquery('Senior Engineer Python');
  */
  search_vector TSVECTOR,


  -- ========================================================================
  -- TEMPORAL METADATA
  -- ========================================================================
  
  /*
    created_at : TIMESTAMPTZ
    PURPOSE: Timestamp of post creation
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets to current timestamp on insert
    USAGE: Audit trail, post age, sorting by newest/oldest
    NOTES: Immutable; should never be updated after creation
  */
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  /*
    updated_at : TIMESTAMPTZ
    PURPOSE: Timestamp of last post modification
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets to current timestamp on insert
    NOTES: Should be updated by trigger on any UPDATE operation
    USAGE: Track when post was last modified (status change, details update)
  */
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

/*
  TABLE CREATION COMPLETE: public.referral_posts
  
  CONSTRAINTS SUMMARY:
    ✓ Primary Key: id (UUID)
    ✓ Foreign Key: user_id → public.users(id) ON DELETE CASCADE
    ✓ NOT NULL: All columns except search_vector are NOT NULL
    ✓ Status: Limited to post_status ENUM values
    ✓ Timestamps: created_at and updated_at for audit trail
  
  NEXT STEPS:
    - Create GIN index on search_vector for full-text search
    - Create trigger to auto-populate search_vector on INSERT/UPDATE
    - Create trigger to auto-update updated_at on UPDATE
    - Create indexes on user_id, status, country for query optimization
    - Set up row-level security (RLS) policies
*/


-- ============================================================================
-- TABLE: public.comments
-- ============================================================================

/*
  TABLE: public.comments
  PURPOSE: Stores user comments and discussions on referral posts
  
  DESCRIPTION:
    Represents comments made by users on referral job posts. This table enables
    discussions around individual referrals, allowing job seekers to ask
    questions about positions and referrers to provide additional context.
    Comments are threaded to each referral post and associated with the
    commenting user.

  RELATIONSHIPS:
    - user_id : Foreign key to public.users(id)
      Represents the user who created the comment
    - post_id : Foreign key to public.referral_posts(id)
      Represents the referral post being commented on

  CASCADE BEHAVIOR:
    - user_id : ON DELETE CASCADE
      When a user is deleted, their comments are removed
    - post_id : ON DELETE CASCADE
      When a referral post is deleted, all comments on it are removed

  CONSTRAINTS:
    - All columns are NOT NULL except comment_text length limits
    - comment_text cannot be empty (enforced at application level)
    - Timestamps are immutable after creation

  PERFORMANCE NOTES:
    - Excellent query candidate: SELECT by post_id for comment feeds
    - Consider indexing post_id and user_id for filtering/sorting
    - comment_text can be indexed with GIN for full-text search

  AUDIT & LIFECYCLE:
    - created_at : Immutable timestamp of comment creation
    - updated_at : Timestamp updated when comment is edited
    - No explicit status field; deletions are hard-deletes or soft-deletes via update
*/
CREATE TABLE IF NOT EXISTS public.comments (
  -- ========================================================================
  -- PRIMARY KEY
  -- ========================================================================
  
  /*
    id : UUID
    PURPOSE: Unique identifier for each comment
    CONSTRAINTS: PRIMARY KEY, NOT NULL
    GENERATION: UUID v4 generated by uuid_generate_v4()
    USAGE: Unique reference for comment retrieval, updates, and deletions
  */
  id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),

  
  -- ========================================================================
  -- FOREIGN KEY RELATIONSHIPS
  -- ========================================================================
  
  /*
    post_id : UUID
    PURPOSE: References the referral post being commented on
    CONSTRAINTS: NOT NULL, FOREIGN KEY with ON DELETE CASCADE
    RELATIONSHIP: References public.referral_posts(id)
    CASCADE BEHAVIOR: When referral post is deleted, all its comments are deleted
    NOTES: Enables efficient querying of all comments for a specific post
  */
  post_id UUID NOT NULL REFERENCES public.referral_posts(id) ON DELETE CASCADE,

  /*
    user_id : UUID
    PURPOSE: User who created the comment
    CONSTRAINTS: NOT NULL, FOREIGN KEY with ON DELETE CASCADE
    RELATIONSHIP: References public.users(id)
    CASCADE BEHAVIOR: When a user is deleted, all their comments are removed
    NOTES: Tracks author of each comment for display and notifications
  */
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,


  -- ========================================================================
  -- COMMENT CONTENT
  -- ========================================================================
  
  /*
    comment_text : TEXT
    PURPOSE: The actual comment content written by the user
    CONSTRAINTS: NOT NULL
    TYPE: TEXT for unlimited length comments
    VALIDATION: Application should validate non-empty before insert
    USAGE: Displayed in comment threads on referral posts
    CONTENT: Can contain questions, answers, updates, or general discussion
    EXAMPLES:
      'Does this role require AWS experience?'
      'Great opportunity! This is a fantastic team to work with.'
      'I can provide internal referral information if you need it.'
    NOTES: Consider adding markdown support or sanitization at application level
  */
  comment_text TEXT NOT NULL,


  -- ========================================================================
  -- TEMPORAL METADATA
  -- ========================================================================
  
  /*
    created_at : TIMESTAMPTZ
    PURPOSE: Timestamp of comment creation
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets value to current timestamp on insert
    USAGE: Display order for comment threads, audit trail
    NOTES: Immutable after creation; should never be updated
  */
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  /*
    updated_at : TIMESTAMPTZ
    PURPOSE: Timestamp of last comment modification (for edits)
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets value to current timestamp on insert
    NOTES: Should be updated via trigger when comment_text is modified
    USAGE: Track comment edit history, display "edited" indicators
  */
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

/*
  TABLE CREATION COMPLETE: public.comments
  
  CONSTRAINTS SUMMARY:
    ✓ Primary Key: id (UUID)
    ✓ Foreign Keys: 
      - post_id → public.referral_posts(id) ON DELETE CASCADE
      - user_id → public.users(id) ON DELETE CASCADE
    ✓ NOT NULL: All columns are NOT NULL
    ✓ Timestamps: created_at and updated_at for audit trail
  
  EXAMPLE QUERIES:
    -- Get all comments for a specific post (ordered by creation)
    SELECT * FROM public.comments 
    WHERE post_id = 'uuid-here' 
    ORDER BY created_at DESC;
    
    -- Get all comments by a user
    SELECT * FROM public.comments 
    WHERE user_id = 'uuid-here' 
    ORDER BY created_at DESC;
  
  NEXT STEPS:
    - Create trigger to auto-update updated_at on modification
    - Create indexes on post_id and user_id for query performance
    - Create GIN index on comment_text for full-text search
    - Set up row-level security (RLS) policies
*/


-- ============================================================================
-- TABLE: public.likes
-- ============================================================================

/*
  TABLE: public.likes
  PURPOSE: Tracks user engagement with referral posts through "likes"
  
  DESCRIPTION:
    Represents user likes/upvotes on referral job posts. This table enables
    engagement tracking, allowing users to express interest in job opportunities.
    The combination of post_id and user_id ensures each user can like a post
    only once, preventing duplicate likes and simplifying toggle operations.
    The created_at timestamp allows for temporal analysis of engagement patterns.

  RELATIONSHIPS:
    - user_id : Foreign key to public.users(id)
      Represents the user who liked the post
    - post_id : Foreign key to public.referral_posts(id)
      Represents the referral post being liked

  CASCADE BEHAVIOR:
    - user_id : ON DELETE CASCADE
      When a user is deleted, all their likes are removed
    - post_id : ON DELETE CASCADE
      When a referral post is deleted, all likes on it are removed

  CONSTRAINTS:
    - UNIQUE(post_id, user_id) : Prevents duplicate likes
      Ensures each user can like each post at most once
      Simplifies like/unlike toggle operations

  PERFORMANCE NOTES:
    - UNIQUE constraint on (post_id, user_id) is efficient for duplicate checks
    - Excellent candidate for indexing on post_id for like count queries
    - Consider indexing user_id for user's liked posts queries
    - Partition candidate for high-volume engagement scenarios

  USE CASES:
    - Get like count for a post: COUNT(*) WHERE post_id = 'uuid'
    - Check if user liked a post: EXISTS WHERE post_id = 'uuid' AND user_id = 'uuid'
    - Get all posts liked by user: SELECT DISTINCT post_id WHERE user_id = 'uuid'
    - Timeline of engagement: ORDER BY created_at DESC for trend analysis

  AUDIT & LIFECYCLE:
    - created_at : Immutable timestamp of when the like was created
    - No updated_at needed (likes are immutable after creation)
*/
CREATE TABLE IF NOT EXISTS public.likes (
  -- ========================================================================
  -- PRIMARY KEY
  -- ========================================================================
  
  /*
    id : UUID
    PURPOSE: Unique identifier for each like record
    CONSTRAINTS: PRIMARY KEY, NOT NULL
    GENERATION: UUID v4 generated by uuid_generate_v4()
    USAGE: Unique reference for like retrieval and potential soft-delete
  */
  id UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),

  
  -- ========================================================================
  -- FOREIGN KEY RELATIONSHIPS
  -- ========================================================================
  
  /*
    post_id : UUID
    PURPOSE: References the referral post being liked
    CONSTRAINTS: NOT NULL, FOREIGN KEY with ON DELETE CASCADE
    RELATIONSHIP: References public.referral_posts(id)
    CASCADE BEHAVIOR: When referral post is deleted, all likes on it are deleted
    NOTES: Part of UNIQUE constraint (post_id, user_id) to prevent duplicate likes
  */
  post_id UUID NOT NULL REFERENCES public.referral_posts(id) ON DELETE CASCADE,

  /*
    user_id : UUID
    PURPOSE: User who liked the referral post
    CONSTRAINTS: NOT NULL, FOREIGN KEY with ON DELETE CASCADE
    RELATIONSHIP: References public.users(id)
    CASCADE BEHAVIOR: When a user is deleted, all their likes are removed
    NOTES: Part of UNIQUE constraint (post_id, user_id) to prevent duplicate likes
  */
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,


  -- ========================================================================
  -- TEMPORAL METADATA
  -- ========================================================================
  
  /*
    created_at : TIMESTAMPTZ
    PURPOSE: Timestamp of when the like was created
    CONSTRAINTS: NOT NULL, DEFAULT NOW()
    TYPE: TIMESTAMPTZ (timestamp with time zone)
    AUTO-SET: Database sets value to current timestamp on insert
    USAGE: Audit trail, engagement timeline, sorting by newest/oldest
    NOTES: Immutable after creation; like creation time is permanent record
  */
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  
  -- ========================================================================
  -- UNIQUENESS CONSTRAINT
  -- ========================================================================
  
  /*
    UNIQUE CONSTRAINT: (post_id, user_id)
    PURPOSE: Ensures each user can like each post at most once
    BUSINESS LOGIC: Prevents duplicate likes and data redundancy
    USAGE: Enables efficient like/unlike toggle operations
    BENEFITS:
      - Database-level prevention of duplicate likes
      - Simplifies application logic (no double-insert checks needed)
      - Supports efficient INSERT ... ON CONFLICT DO UPDATE for toggle
    EXAMPLE UPSERT (toggle-like):
      INSERT INTO public.likes (post_id, user_id) VALUES ('post-uuid', 'user-uuid')
      ON CONFLICT (post_id, user_id) DO DELETE;
  */
  UNIQUE(post_id, user_id)
);

/*
  TABLE CREATION COMPLETE: public.likes
  
  CONSTRAINTS SUMMARY:
    ✓ Primary Key: id (UUID)
    ✓ Foreign Keys: 
      - post_id → public.referral_posts(id) ON DELETE CASCADE
      - user_id → public.users(id) ON DELETE CASCADE
    ✓ Unique Constraint: (post_id, user_id)
    ✓ NOT NULL: All columns are NOT NULL
    ✓ Timestamps: created_at for audit trail
  
  EXAMPLE QUERIES:
    -- Get like count for a post
    SELECT COUNT(*) FROM public.likes WHERE post_id = 'post-uuid';
    
    -- Check if user liked a post
    SELECT EXISTS(SELECT 1 FROM public.likes 
                  WHERE post_id = 'post-uuid' AND user_id = 'user-uuid');
    
    -- Get all posts liked by user
    SELECT DISTINCT post_id FROM public.likes WHERE user_id = 'user-uuid';
    
    -- Toggle like (like if not liked, unlike if liked)
    INSERT INTO public.likes (post_id, user_id) VALUES ('post-uuid', 'user-uuid')
    ON CONFLICT (post_id, user_id) DO DELETE;
  
  NEXT STEPS:
    - Create indexes on post_id for like count queries
    - Create indexes on user_id for user's liked posts queries
    - Create indexes on (post_id, user_id) if UNIQUE constraint is insufficient
    - Set up row-level security (RLS) policies
*/


-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

/*
  STATUS: Successfully created ENUM types and application tables for MyReferral v1.0.0
  
  OBJECTS CREATED:
    - 4 ENUM types (app_role, post_status, referral_status, notification_type)
    - 4 tables (public.users, public.referral_posts, public.comments, public.likes)
  
  RELATIONSHIPS:
    - public.referral_posts.user_id → public.users(id) [ON DELETE CASCADE]
    - public.comments.post_id → public.referral_posts(id) [ON DELETE CASCADE]
    - public.comments.user_id → public.users(id) [ON DELETE CASCADE]
    - public.likes.post_id → public.referral_posts(id) [ON DELETE CASCADE]
    - public.likes.user_id → public.users(id) [ON DELETE CASCADE]
  
  CONSTRAINTS:
    - public.likes has UNIQUE(post_id, user_id) for duplicate prevention
  
  NEXT STEPS: 
    - Run V1.1.0 migration to create referral_requests table
    - Run V1.2.0 migration to create notifications table
    - Apply database triggers for audit logging and timestamp updates
    - Apply row-level security (RLS) policies for Supabase
  
  ROLLBACK: 
    - Drop public.likes table (IF EXISTS)
    - Drop public.comments table (IF EXISTS)
    - Drop public.referral_posts table (IF EXISTS)
    - Drop public.users table (IF EXISTS)
    - Drop ENUM types (BE CAUTIOUS - dependent objects may exist)
*/
