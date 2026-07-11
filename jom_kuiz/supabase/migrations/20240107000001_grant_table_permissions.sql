-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Grant table-level DML permissions to authenticated + anon roles
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Root cause: every table in this project had ONLY REFERENCES, TRIGGER, and
-- TRUNCATE granted to both the `authenticated` and `anon` roles.  SELECT,
-- INSERT, UPDATE, and DELETE were never granted.
--
-- PostgreSQL evaluates table-level grants BEFORE Row Level Security policies.
-- Without these grants the database raises:
--   ERROR: permission denied for table <tablename>
-- regardless of how correct the RLS policies are.
--
-- Applied directly to production via Supabase Management API on 2026-07-11.
-- This file documents what was applied and ensures the same grants are
-- present in any fresh environment (local dev, staging, CI preview).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── authenticated role ────────────────────────────────────────────────────────

-- Parent profile — full CRUD (RLS: user_id = auth.uid())
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.parents TO authenticated;

-- Children — full CRUD (RLS: parent_id in own parents)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.children TO authenticated;

-- Subscriptions — read + create/update (activate_subscription RPC does inserts)
GRANT SELECT, INSERT, UPDATE ON TABLE public.parent_subscriptions  TO authenticated;
GRANT SELECT, INSERT          ON TABLE public.parent_subject_access TO authenticated;

-- Payments — read + create own transactions
GRANT SELECT, INSERT ON TABLE public.payment_transactions TO authenticated;

-- Catalog tables — read-only for parents
GRANT SELECT ON TABLE public.subscription_packages TO authenticated;
GRANT SELECT ON TABLE public.admin_content         TO authenticated;
GRANT SELECT ON TABLE public.admin_users           TO authenticated;  -- needed by admin RLS checks
GRANT SELECT ON TABLE public.subjects              TO authenticated;
GRANT SELECT ON TABLE public.years                 TO authenticated;
GRANT SELECT ON TABLE public.chapters              TO authenticated;
GRANT SELECT ON TABLE public.topics                TO authenticated;
GRANT SELECT ON TABLE public.questions             TO authenticated;

-- ── anon role ─────────────────────────────────────────────────────────────────

-- Public catalog: unauthenticated browsing (landing page, package listing)
GRANT SELECT ON TABLE public.subscription_packages TO anon;
GRANT SELECT ON TABLE public.admin_content         TO anon;
GRANT SELECT ON TABLE public.subjects              TO anon;
GRANT SELECT ON TABLE public.years                 TO anon;
GRANT SELECT ON TABLE public.chapters              TO anon;
GRANT SELECT ON TABLE public.topics                TO anon;
GRANT SELECT ON TABLE public.questions             TO anon;

-- ── RLS: INSERT policy on parents ─────────────────────────────────────────────
-- The handle_new_auth_user trigger (SECURITY DEFINER) creates the parent row
-- on signup and bypasses RLS.  This policy is a safety net that allows an
-- authenticated user to self-insert their own row if the trigger misfired.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'parents'
      AND policyname = 'Parents insert own row'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Parents insert own row"
        ON public.parents FOR INSERT
        TO authenticated
        WITH CHECK (user_id = auth.uid())
    $policy$;
  END IF;
END
$$;
