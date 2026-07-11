-- Migration: add get_child_profile RPC
-- Applied directly to production via Supabase Management API.
-- This file documents the change for version control.
--
-- Purpose: allow the child session (anon key, no JWT) to fetch its own
-- profile by calling a SECURITY DEFINER function instead of a direct
-- table SELECT (which would require granting SELECT on children to anon).

CREATE OR REPLACE FUNCTION public.get_child_profile(p_child_id uuid)
RETURNS TABLE (
  child_id        uuid,
  parent_id       uuid,
  student_id      text,
  full_name       text,
  username        text,
  education_level text,
  year_grade      text,
  account_status  text,
  profile_photo   text,
  created_at      timestamptz,
  updated_at      timestamptz,
  parent_full_name text,
  parent_email    text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id              AS child_id,
    c.parent_id,
    c.student_id,
    c.full_name,
    c.username,
    c.education_level,
    c.year_grade,
    c.account_status,
    c.profile_photo,
    c.created_at,
    c.updated_at,
    p.full_name       AS parent_full_name,
    p.email           AS parent_email
  FROM public.children c
  LEFT JOIN public.parents p ON p.id = c.parent_id
  WHERE c.id = p_child_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_child_profile(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_child_profile(uuid) TO authenticated;
