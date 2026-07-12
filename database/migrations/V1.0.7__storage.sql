-- ============================================================================
-- Project:            MyReferral
-- Migration:           V1.0.7__storage.sql
-- Version:             V1.0.7
-- Description:         Supabase Storage buckets and storage security.
-- Platform:            Supabase
-- Database Engine:     PostgreSQL 17+
-- Execution Order:     Run AFTER V1.0.6__policies.sql
-- ============================================================================
-- Change Log:
--   V1.0.7  - Initial creation of Supabase Storage buckets and associated
--             storage security policies for the MyReferral platform.
-- ============================================================================
-- Notes:
--   - This migration depends on schema and role definitions established in
--     prior migrations, including V1.0.6__policies.sql.
--   - Intended for execution within a Supabase-managed PostgreSQL 17+
--     environment with the `storage` extension/schema enabled.
--   - Review bucket-level access policies against organizational data
--     classification and compliance requirements prior to deployment.
-- ============================================================================
-- ============================================================================
-- Section:             Storage Bucket Definitions
-- Description:         Creation of Supabase Storage buckets used by the
--                       MyReferral platform, including public/private
--                       visibility, file size limits, and allowed MIME types.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Bucket:              profile-pictures
-- Purpose:             Stores user profile picture assets.
-- Visibility:          Public
-- Max File Size:       5 MB (5242880 bytes)
-- Allowed MIME Types:  image/jpeg, image/png, image/webp
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'profile-pictures',
    'profile-pictures',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Bucket:              resumes
-- Purpose:             Stores candidate resume/CV documents.
-- Visibility:          Private
-- Max File Size:       10 MB (10485760 bytes)
-- Allowed MIME Types:  application/pdf, application/msword,
--                      application/vnd.openxmlformats-officedocument.wordprocessingml.document
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'resumes',
    'resumes',
    FALSE,
    10485760,
    ARRAY[
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- Bucket:              company-logos
-- Purpose:             Stores company/organization logo assets.
-- Visibility:          Public
-- Max File Size:       2 MB (2097152 bytes)
-- Allowed MIME Types:  image/jpeg, image/png, image/webp
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'company-logos',
    'company-logos',
    TRUE,
    2097152,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;
-- ============================================================================
-- Section:             Storage Row-Level Security (RLS) Policies
-- Description:         Access control policies enforced on storage.objects
--                       for the MyReferral platform storage buckets.
-- Notes:
--   - storage.objects has RLS enabled by default in Supabase.
--   - (storage.foldername(name))[1] is used to extract the first path
--     segment of the object key, which is expected to be the owner's
--     auth.uid() for user-scoped buckets.
--   - owner column is set automatically by Supabase Storage to the
--     uploading user's auth.uid() and is used as an additional ownership
--     check where applicable.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Bucket:              profile-pictures
-- Policy:              Allow authenticated users to upload only within
--                      their own folder: profile-pictures/{auth.uid()}/
-- ----------------------------------------------------------------------------
CREATE POLICY "profile_pictures_insert_own_folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              profile-pictures
-- Policy:              Allow authenticated users to update only their own
--                      images within profile-pictures/{auth.uid()}/
-- ----------------------------------------------------------------------------
CREATE POLICY "profile_pictures_update_own"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              profile-pictures
-- Policy:              Allow authenticated users to delete only their own
--                      images within profile-pictures/{auth.uid()}/
-- ----------------------------------------------------------------------------
CREATE POLICY "profile_pictures_delete_own"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              profile-pictures
-- Policy:              Allow public (anonymous and authenticated) read
--                      access to all profile pictures.
-- ----------------------------------------------------------------------------
CREATE POLICY "profile_pictures_select_public"
ON storage.objects
FOR SELECT
TO public
USING (
    bucket_id = 'profile-pictures'
);

-- ----------------------------------------------------------------------------
-- Bucket:              resumes
-- Policy:              Allow authenticated users to upload only within
--                      their own folder: resumes/{auth.uid()}/
-- ----------------------------------------------------------------------------
CREATE POLICY "resumes_insert_own_folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'resumes'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              resumes
-- Policy:              Allow authenticated users to view only their own
--                      resumes. No anonymous access is granted.
-- ----------------------------------------------------------------------------
CREATE POLICY "resumes_select_own"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'resumes'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              resumes
-- Policy:              Allow authenticated users to delete only their own
--                      resumes.
-- ----------------------------------------------------------------------------
CREATE POLICY "resumes_delete_own"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'resumes'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ----------------------------------------------------------------------------
-- Bucket:              company-logos
-- Policy:              Allow any authenticated user to upload company logo
--                      assets.
-- ----------------------------------------------------------------------------
CREATE POLICY "company_logos_insert_authenticated"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'company-logos'
);

-- ----------------------------------------------------------------------------
-- Bucket:              company-logos
-- Policy:              Allow public (anonymous and authenticated) read
--                      access to all company logos.
-- ----------------------------------------------------------------------------
CREATE POLICY "company_logos_select_public"
ON storage.objects
FOR SELECT
TO public
USING (
    bucket_id = 'company-logos'
);

-- ----------------------------------------------------------------------------
-- Bucket:              company-logos
-- Policy:              Allow deletion only by the original uploader, as
--                      identified by the storage-managed owner column.
-- ----------------------------------------------------------------------------
CREATE POLICY "company_logos_delete_owner_only"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'company-logos'
    AND owner = auth.uid()
);
-- ============================================================================
-- Section:             Storage Path Ownership Helper Functions
-- Description:         Reusable SQL functions that validate whether the
--                       currently authenticated user owns the folder path
--                       (first path segment) of a given storage object key.
--                       Intended for use within storage.objects RLS policies
--                       and application-layer validation logic.
-- Notes:
--   - (storage.foldername(path))[1] extracts the first path segment of the
--     object key, which is expected to correspond to auth.uid() for
--     user-scoped buckets.
--   - Functions are defined as STABLE since their result depends only on
--     the current session's auth.uid() and the input path, not on any
--     data mutation.
--   - SECURITY INVOKER is used so that the functions execute with the
--     privileges and auth context of the calling user.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function:            is_profile_picture_owner(path text)
-- Purpose:             Returns TRUE only if the first path segment of the
--                      given storage object path matches the currently
--                      authenticated user's auth.uid(), for use with the
--                      profile-pictures bucket.
-- Parameters:
--   path  - Full storage object key (e.g. '{uid}/avatar.png').
-- Returns:             BOOLEAN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_profile_picture_owner(path text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT (storage.foldername(path))[1] = auth.uid()::text;
$$;

-- ----------------------------------------------------------------------------
-- Function:            is_resume_owner(path text)
-- Purpose:             Returns TRUE only if the first path segment of the
--                      given storage object path matches the currently
--                      authenticated user's auth.uid(), for use with the
--                      resumes bucket.
-- Parameters:
--   path  - Full storage object key (e.g. '{uid}/resume.pdf').
-- Returns:             BOOLEAN
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_resume_owner(path text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
    SELECT (storage.foldername(path))[1] = auth.uid()::text;
$$;
-- ============================================================================
-- Section:             Post-Migration Validation Queries
-- Description:         Read-only verification queries confirming successful
--                       application of storage bucket definitions and
--                       storage RLS policies introduced in this migration.
--                       Intended for manual review or automated migration
--                       verification tooling. No data is modified.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Validation 1:        Confirm that all expected storage buckets exist.
-- ----------------------------------------------------------------------------
SELECT
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets
WHERE id IN ('profile-pictures', 'resumes', 'company-logos')
ORDER BY id;

-- ----------------------------------------------------------------------------
-- Validation 2:        Confirm bucket visibility (public/private) matches
--                      expected configuration.
--                        profile-pictures -> TRUE
--                        resumes          -> FALSE
--                        company-logos    -> TRUE
-- ----------------------------------------------------------------------------
SELECT
    id AS bucket_id,
    public AS is_public,
    CASE
        WHEN id = 'profile-pictures' AND public = TRUE  THEN 'OK'
        WHEN id = 'resumes'          AND public = FALSE THEN 'OK'
        WHEN id = 'company-logos'    AND public = TRUE  THEN 'OK'
        ELSE 'MISMATCH'
    END AS visibility_check
FROM storage.buckets
WHERE id IN ('profile-pictures', 'resumes', 'company-logos')
ORDER BY id;

-- ----------------------------------------------------------------------------
-- Validation 3:        Confirm file size limits match expected configuration.
--                        profile-pictures -> 5242880  (5 MB)
--                        resumes          -> 10485760 (10 MB)
--                        company-logos    -> 2097152  (2 MB)
-- ----------------------------------------------------------------------------
SELECT
    id AS bucket_id,
    file_size_limit,
    CASE
        WHEN id = 'profile-pictures' AND file_size_limit = 5242880  THEN 'OK'
        WHEN id = 'resumes'          AND file_size_limit = 10485760 THEN 'OK'
        WHEN id = 'company-logos'    AND file_size_limit = 2097152  THEN 'OK'
        ELSE 'MISMATCH'
    END AS file_size_check
FROM storage.buckets
WHERE id IN ('profile-pictures', 'resumes', 'company-logos')
ORDER BY id;

-- ----------------------------------------------------------------------------
-- Validation 4:        Confirm allowed MIME types match expected
--                      configuration for each bucket.
-- ----------------------------------------------------------------------------
SELECT
    id AS bucket_id,
    allowed_mime_types,
    CASE
        WHEN id = 'profile-pictures'
             AND allowed_mime_types @> ARRAY['image/jpeg', 'image/png', 'image/webp']
             AND allowed_mime_types <@ ARRAY['image/jpeg', 'image/png', 'image/webp']
             THEN 'OK'
        WHEN id = 'resumes'
             AND allowed_mime_types @> ARRAY[
                    'application/pdf',
                    'application/msword',
                    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                 ]
             AND allowed_mime_types <@ ARRAY[
                    'application/pdf',
                    'application/msword',
                    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                 ]
             THEN 'OK'
        WHEN id = 'company-logos'
             AND allowed_mime_types @> ARRAY['image/jpeg', 'image/png', 'image/webp']
             AND allowed_mime_types <@ ARRAY['image/jpeg', 'image/png', 'image/webp']
             THEN 'OK'
        ELSE 'MISMATCH'
    END AS mime_type_check
FROM storage.buckets
WHERE id IN ('profile-pictures', 'resumes', 'company-logos')
ORDER BY id;

-- ----------------------------------------------------------------------------
-- Validation 5:        Confirm that all expected storage RLS policies exist
--                      on storage.objects.
-- ----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    policyname,
    cmd AS command_type,
    roles
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname IN (
        'profile_pictures_insert_own_folder',
        'profile_pictures_update_own',
        'profile_pictures_delete_own',
        'profile_pictures_select_public',
        'resumes_insert_own_folder',
        'resumes_select_own',
        'resumes_delete_own',
        'company_logos_insert_authenticated',
        'company_logos_select_public',
        'company_logos_delete_owner_only'
  )
ORDER BY policyname;

-- ----------------------------------------------------------------------------
-- Validation 6:        Count total buckets created by this migration.
--                      Expected result: 3
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS bucket_count
FROM storage.buckets
WHERE id IN ('profile-pictures', 'resumes', 'company-logos');

-- ----------------------------------------------------------------------------
-- Validation 7:        Count total storage RLS policies created by this
--                      migration. Expected result: 10
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) AS storage_policy_count
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname IN (
        'profile_pictures_insert_own_folder',
        'profile_pictures_update_own',
        'profile_pictures_delete_own',
        'profile_pictures_select_public',
        'resumes_insert_own_folder',
        'resumes_select_own',
        'resumes_delete_own',
        'company_logos_insert_authenticated',
        'company_logos_select_public',
        'company_logos_delete_owner_only'
  );
-- =============================================================================
