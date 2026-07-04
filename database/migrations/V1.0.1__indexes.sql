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
