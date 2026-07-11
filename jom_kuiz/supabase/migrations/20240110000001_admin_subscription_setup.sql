-- Migration: Admin subscription setup
-- • Seed Free + Premium subscription packages
-- • Make locallistapps@gmail.com an admin
-- • Grant Premium subscription + Matematik access to locallistapps@gmail.com
-- • Add admin RLS policies on parent_subscriptions + parent_subject_access
-- Applied directly to production via Supabase Management API.

-- ── is_admin() helper (created in 20240109 migration, ensure idempotent) ──────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid());
$$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- ── Packages ──────────────────────────────────────────────────────────────────
INSERT INTO public.subscription_packages
  (id, name, description, max_children, included_subject_ids, price_cents, duration_days, is_active)
VALUES
  ('c0000000-0000-0000-0000-000000000001',
   'Free',    'Pakej percuma - akses terhad', 2, '{}', 0, 30, true),
  ('c0000000-0000-0000-0000-000000000002',
   'Premium', 'Pakej Premium - semua subjek KSSR termasuk Matematik', 5,
   '{"a0000000-0000-0000-0000-000000000001"}', 5900, 365, true)
ON CONFLICT (id) DO NOTHING;

-- ── Admin user ────────────────────────────────────────────────────────────────
-- Replace UUID with the auth.uid() of the admin user
INSERT INTO public.admin_users (user_id, granted_at, granted_by)
VALUES ('b561d4cd-2e7e-4f95-a7b5-b53e85bd4b72', now(), 'b561d4cd-2e7e-4f95-a7b5-b53e85bd4b72')
ON CONFLICT (user_id) DO NOTHING;

-- ── Admin RLS: parent_subscriptions ──────────────────────────────────────────
DROP POLICY IF EXISTS "Admin insert subscriptions" ON public.parent_subscriptions;
DROP POLICY IF EXISTS "Admin update subscriptions" ON public.parent_subscriptions;
DROP POLICY IF EXISTS "Admin delete subscriptions" ON public.parent_subscriptions;
CREATE POLICY "Admin insert subscriptions" ON public.parent_subscriptions
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "Admin update subscriptions" ON public.parent_subscriptions
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "Admin delete subscriptions" ON public.parent_subscriptions
  FOR DELETE TO authenticated USING (public.is_admin());

-- ── Admin RLS: parent_subject_access ─────────────────────────────────────────
DROP POLICY IF EXISTS "Admin insert subject access" ON public.parent_subject_access;
DROP POLICY IF EXISTS "Admin update subject access" ON public.parent_subject_access;
DROP POLICY IF EXISTS "Parents insert own subject access" ON public.parent_subject_access;
CREATE POLICY "Admin insert subject access" ON public.parent_subject_access
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "Admin update subject access" ON public.parent_subject_access
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "Parents insert own subject access" ON public.parent_subject_access
  FOR INSERT TO authenticated
  WITH CHECK (parent_id IN (SELECT id FROM public.parents WHERE user_id = auth.uid()));

-- ── Grants ────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscription_packages  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parent_subscriptions   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parent_subject_access  TO authenticated;
GRANT SELECT                         ON public.parents                TO authenticated;
GRANT SELECT                         ON public.subjects               TO authenticated;

-- ── Seed Premium subscription for locallistapps@gmail.com ────────────────────
INSERT INTO public.parent_subscriptions
  (id, parent_id, package_id, start_date, expiry_date, status, auto_renew)
VALUES (
  'e0000000-0000-0000-0000-000000000001',
  '1acebe05-c096-4c58-a24e-f2ca6fdbf902',
  'c0000000-0000-0000-0000-000000000002',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '365 days',
  'active',
  false
)
ON CONFLICT (id) DO UPDATE SET
  package_id  = EXCLUDED.package_id,
  expiry_date = EXCLUDED.expiry_date,
  status      = EXCLUDED.status,
  updated_at  = now();

-- ── Seed Matematik subject access for locallistapps@gmail.com ────────────────
INSERT INTO public.parent_subject_access
  (id, parent_id, subject_id, granted_at, source, expires_at)
VALUES (
  'f0000000-0000-0000-0000-000000000001',
  '1acebe05-c096-4c58-a24e-f2ca6fdbf902',
  'a0000000-0000-0000-0000-000000000001',
  now(),
  'subscription',
  (CURRENT_DATE + INTERVAL '365 days')::timestamptz
)
ON CONFLICT (id) DO UPDATE SET
  source     = EXCLUDED.source,
  expires_at = EXCLUDED.expires_at;
