/*
 ******************************************************************************
 * Project       : MyReferral
 * Migration     : V1.0.1__indexes.sql
 * MigrationVersion: V1.0.1
 * Description   : Performance indexes for all database tables.
 *
 * Database      : PostgreSQL 17+
 * Platform      : Supabase
 *
 * Author        : Placeholder
 * Created Date  : Placeholder
 *
 * Execution Order:
 *   - This migration MUST be executed only after migration V1.0.0 has completed successfully.
 *
 * Enterprise Notes:
 *   - This file is intended to contain INDEX creation DDL only (no data migrations).
 *   - Perform index builds during a scheduled maintenance window to limit write-impact.
 *   - Prefer CONCURRENTLY for large indexes in production to reduce locking (use with caution).
 *   - Validate index usage via EXPLAIN ANALYZE after deployment; remove unused indexes.
 *   - Ensure backups and rollback/plan are in place before applying to production.
 *   - Monitor replication lag on Supabase when running index builds.
 *
 * Change Management:
 *   - Record timing, operator, and observed system impact in the change log.
 *   - Include a tested rollback plan (index DROP statements) in change documentation.
 *
 ******************************************************************************
 */

-- Indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users (status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at DESC);

-- Indexes for referral_posts table
CREATE INDEX IF NOT EXISTS idx_referral_posts_user_id ON referral_posts (user_id);
CREATE INDEX IF NOT EXISTS idx_referral_posts_company_name ON referral_posts (company_name);
CREATE INDEX IF NOT EXISTS idx_referral_posts_job_id ON referral_posts (job_id);
CREATE INDEX IF NOT EXISTS idx_referral_posts_location ON referral_posts (location);
CREATE INDEX IF NOT EXISTS idx_referral_posts_country ON referral_posts (country);
CREATE INDEX IF NOT EXISTS idx_referral_posts_work_mode ON referral_posts (work_mode);
CREATE INDEX IF NOT EXISTS idx_referral_posts_status ON referral_posts (status);
CREATE INDEX IF NOT EXISTS idx_referral_posts_created_at ON referral_posts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_referral_posts_updated_at ON referral_posts (updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_referral_posts_search ON referral_posts USING GIN (search_vector);

-- Indexes for comments table
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments (post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments (created_at DESC);
