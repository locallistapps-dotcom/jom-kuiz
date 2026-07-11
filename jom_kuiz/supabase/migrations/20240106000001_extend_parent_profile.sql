-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Extend parents table with profile fields + ensure auth trigger
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The Flutter ParentProfileModel expects fields beyond what the initial
-- parents table contained.  This migration adds them idempotently.
--
-- Also re-creates the auth.users trigger in case it was not deployed with
-- the initial migration (Supabase restricts DDL on auth schema in some
-- environments; this uses security-definer + service role to ensure it runs).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Add missing profile columns to public.parents ─────────────────────────────

alter table public.parents
  add column if not exists email_verified       boolean     not null default false,
  add column if not exists account_status       text        not null default 'active'
                           check (account_status in ('active','suspended','deleted')),
  add column if not exists notification_enabled boolean     not null default true,
  add column if not exists country              text,
  add column if not exists state                text,
  add column if not exists city                 text,
  add column if not exists gender               text,
  add column if not exists date_of_birth        date,
  add column if not exists language             text        not null default 'en',
  add column if not exists timezone             text,
  add column if not exists bio                  text;

-- ── Re-create the auto-create-parent trigger (idempotent) ────────────────────
--
-- create or replace is used for the function so this migration is safe to
-- re-apply.  The trigger is dropped-and-recreated because CREATE OR REPLACE
-- is not available for triggers in PostgreSQL.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider text;
begin
  v_provider := coalesce(
    new.raw_app_meta_data->>'provider',
    'email'
  );
  insert into public.parents (
    user_id, full_name, email, auth_provider
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      split_part(new.email, '@', 1)
    ),
    new.email,
    case
      when v_provider in ('google','apple','microsoft') then v_provider
      else 'email'
    end
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();

-- ── Grant service_role access to run the function ─────────────────────────────

grant execute on function public.handle_new_auth_user to service_role;
