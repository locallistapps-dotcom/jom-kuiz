-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Grant admin write permissions on content tables
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Context
-- -------
-- Migration 20240107000001_grant_table_permissions.sql gave the
-- `authenticated` role SELECT-only on the content tables (questions,
-- chapters, subjects, topics, years) and INSERT only on admin_users.
-- INSERT, UPDATE, and DELETE were intentionally omitted there because no
-- non-admin user should ever write to those tables.
--
-- The Admin CMS feature (locallistapps@gmail.com) requires that admins
-- can INSERT, UPDATE, and DELETE rows in those tables.  The is_admin()
-- RLS policy already gates every write to users whose auth.uid() is
-- present in admin_users, but PostgreSQL evaluates table-level GRANTs
-- BEFORE it evaluates RLS.  Without these grants the server raises:
--
--   ERROR 403: permission denied for table questions
--
-- regardless of how correct the RLS policies are, because the engine
-- rejects the operation before it even calls is_admin().
--
-- What this migration adds
-- ------------------------
-- GRANT INSERT, UPDATE, DELETE on each admin-managed content table to
-- the `authenticated` role.  The existing RLS policies remain the sole
-- enforcement mechanism for *who* may exercise those privileges:
--
--   "Admin full access questions"  USING (is_admin()) WITH CHECK (is_admin())
--   "Admin full access chapters"   USING (is_admin()) WITH CHECK (is_admin())
--   "Admin full access subjects"   USING (is_admin()) WITH CHECK (is_admin())
--   "Admin full access topics"     USING (is_admin()) WITH CHECK (is_admin())
--   "Admin full access years"      USING (is_admin()) WITH CHECK (is_admin())
--
-- is_admin() := EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
--
-- A regular authenticated parent/student will pass the GRANT check but
-- will be blocked immediately by the RLS USING clause, so the effective
-- security is unchanged for non-admin users.
--
-- Applied directly to production via Supabase Management API on 2026-07-11
-- before this file was created.  Re-running this file is safe (GRANTs are
-- idempotent — granting an already-held privilege is a no-op in PostgreSQL).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Content tables managed by Admin CMS ──────────────────────────────────

GRANT INSERT, UPDATE, DELETE ON public.questions TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.chapters  TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.subjects  TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.topics    TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.years     TO authenticated;

-- ── admin_users ───────────────────────────────────────────────────────────
-- Only INSERT is policy-gated ("Super-admin can insert admin_users").
-- No UPDATE or DELETE RLS policy exists on this table, so those are not
-- granted here — they remain exclusive to the postgres / service_role.

GRANT INSERT ON public.admin_users TO authenticated;
