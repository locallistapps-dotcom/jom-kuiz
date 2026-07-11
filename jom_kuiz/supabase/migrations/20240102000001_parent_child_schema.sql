-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Parent & Child Management Schema
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Tables:  parents, children
-- RPCs:    create_child, update_child, reset_child_password, delete_child,
--          child_login (documented — called via Edge Function)
-- Trigger: auto-create parent row when a new auth user registers
-- RLS:     parents see only their own row; parents see only their children
--
-- Google / OAuth architecture:
--   auth_provider + provider_id columns on `parents` support multi-provider
--   login with NO changes to existing email/password users.
--   To link a Google account: set auth_provider = 'google', provider_id = uid
--   and optionally update user_id to point to the Supabase OAuth user.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Extensions ───────────────────────────────────────────────────────────────

-- pgcrypto provides crypt() for bcrypt password hashing.
create extension if not exists pgcrypto with schema extensions;

-- ── parents ──────────────────────────────────────────────────────────────────

create table if not exists public.parents (
  id              uuid        primary key default gen_random_uuid(),
  -- Supabase auth user; nullable so admin-created parents can be seeded.
  user_id         uuid        unique references auth.users(id) on delete cascade,
  full_name       text        not null,
  email           text        not null,
  phone_number    text,
  profile_photo   text,                              -- avatar URL
  referral_code   text        unique,                -- reserved for Referral module
  -- ── Multi-provider OAuth architecture ────────────────────────────────────
  -- Existing email/password users have auth_provider = 'email' and
  -- provider_id IS NULL. Never break these rows.
  -- To add Google Sign-In: set auth_provider = 'google' + provider_id = sub
  -- and call `link_oauth_account` RPC (to be created in a future migration).
  auth_provider   text        not null default 'email'
                              check (auth_provider in ('email','google','apple','microsoft')),
  provider_id     text,       -- OAuth subject / sub claim from the identity token
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Composite unique index: one provider_id per provider (enables future
-- "link if same email" logic without duplicate parent records).
create unique index if not exists parents_provider_unique_idx
  on public.parents (auth_provider, provider_id)
  where provider_id is not null;

-- updated_at auto-maintenance.
create or replace function public.parents_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists parents_updated_at on public.parents;
create trigger parents_updated_at
  before update on public.parents
  for each row execute procedure public.parents_set_updated_at();

-- ── children ─────────────────────────────────────────────────────────────────

create table if not exists public.children (
  id              uuid        primary key default gen_random_uuid(),
  parent_id       uuid        not null references public.parents(id) on delete cascade,
  -- 8-digit immutable student ID, auto-generated.  Used by child login flow.
  student_id      text        not null unique,
  full_name       text        not null,
  username        text        not null unique,
  password_hash   text        not null,             -- bcrypt via pgcrypto
  education_level text        not null default 'primary'
                              check (education_level in
                                ('preschool','primary','secondary','matriculation')),
  year_grade      text        not null default 'Year 1',
  account_status  text        not null default 'active'
                              check (account_status in ('active','disabled')),
  profile_photo   text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists children_parent_id_idx on public.children (parent_id);
create index if not exists children_username_idx  on public.children (username);
create index if not exists children_student_id_idx on public.children (student_id);

create or replace function public.children_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists children_updated_at on public.children;
create trigger children_updated_at
  before update on public.children
  for each row execute procedure public.children_set_updated_at();

-- ── Auto-create parent row on Supabase Auth sign-up ─────────────────────────
--
-- Fired for every new auth.users row so that:
--  • Email/password registration → auth_provider = 'email'
--  • Future Google Sign-In       → auth_provider = 'google' (set by metadata)
--
-- If a parent row already exists for this email (e.g. manually seeded or
-- linked OAuth), the INSERT is skipped — no duplicate parent records.

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

-- Bind the trigger to the auth schema (must be in a separate migration if
-- using managed Supabase; kept here for documentation / local dev).
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();

-- ── RLS ──────────────────────────────────────────────────────────────────────

alter table public.parents  enable row level security;
alter table public.children enable row level security;

-- parents: each parent sees only their own row.
create policy "Parents read own row"
  on public.parents for select
  using (user_id = auth.uid());

create policy "Parents update own row"
  on public.parents for update
  using (user_id = auth.uid());

-- children: parent sees only their linked children.
create policy "Parents read own children"
  on public.children for select
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- Direct PATCH used by setChildStatus (account_management_remote_data_source).
create policy "Parents update own children status"
  on public.children for update
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- Direct DELETE used by deleteChild (account_management_remote_data_source).
create policy "Parents delete own children"
  on public.children for delete
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- ── Helper: generate unique 8-digit student ID ───────────────────────────────

create or replace function private.generate_student_id()
returns text
language plpgsql
as $$
declare
  v_id text;
  v_attempts int := 0;
begin
  loop
    v_attempts := v_attempts + 1;
    if v_attempts > 100 then
      raise exception 'Could not generate unique student ID after 100 attempts';
    end if;
    v_id := lpad((floor(random() * 90000000) + 10000000)::bigint::text, 8, '0');
    exit when not exists (select 1 from public.children where student_id = v_id);
  end loop;
  return v_id;
end;
$$;

-- ── RPC: create_child ─────────────────────────────────────────────────────────
--
-- Called by: POST /rpc/create_child (Supabase PostgREST)
-- Auth:      JWT of the authenticated parent; looks up parent.id via auth.uid()
-- Returns:   the new children row as a JSON object.

create or replace function public.create_child(
  p_full_name       text,
  p_username        text,
  p_password        text,
  p_education_level text default 'primary',
  p_year_grade      text default 'Year 1'
)
returns json
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_parent_id uuid;
  v_student_id text;
  v_row        public.children;
begin
  -- Resolve authenticated parent.
  select id into v_parent_id
  from   public.parents
  where  user_id = auth.uid();
  if not found then
    raise exception 'Parent profile not found' using errcode = 'P0001';
  end if;

  -- Username uniqueness.
  if exists (select 1 from public.children where username = lower(trim(p_username))) then
    raise exception 'Username already taken' using errcode = '23505';
  end if;

  -- Generate unique student ID.
  v_student_id := private.generate_student_id();

  -- Insert and return the new row.
  insert into public.children (
    parent_id, student_id, full_name, username, password_hash,
    education_level, year_grade
  )
  values (
    v_parent_id,
    v_student_id,
    trim(p_full_name),
    lower(trim(p_username)),
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    p_education_level,
    p_year_grade
  )
  returning * into v_row;

  return row_to_json(v_row);
end;
$$;

-- ── RPC: update_child ─────────────────────────────────────────────────────────
--
-- Called by: POST /rpc/update_child (Supabase PostgREST)
-- p_password = NULL → leave existing password unchanged.

create or replace function public.update_child(
  p_child_id        uuid,
  p_full_name       text,
  p_username        text,
  p_education_level text,
  p_year_grade      text,
  p_password        text default null
)
returns json
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_parent_id uuid;
  v_row        public.children;
begin
  -- Resolve authenticated parent.
  select id into v_parent_id
  from   public.parents
  where  user_id = auth.uid();
  if not found then
    raise exception 'Parent profile not found' using errcode = 'P0001';
  end if;

  -- Ownership check.
  if not exists (
    select 1 from public.children
    where  id = p_child_id and parent_id = v_parent_id
  ) then
    raise exception 'Child not found' using errcode = 'P0002';
  end if;

  -- Username uniqueness (skip if unchanged).
  if exists (
    select 1 from public.children
    where  username = lower(trim(p_username)) and id != p_child_id
  ) then
    raise exception 'Username already taken' using errcode = '23505';
  end if;

  -- Update with optional password change.
  if p_password is not null and length(p_password) > 0 then
    update public.children set
      full_name       = trim(p_full_name),
      username        = lower(trim(p_username)),
      password_hash   = crypt(p_password, gen_salt('bf')),
      education_level = p_education_level,
      year_grade      = p_year_grade
    where id = p_child_id
    returning * into v_row;
  else
    update public.children set
      full_name       = trim(p_full_name),
      username        = lower(trim(p_username)),
      education_level = p_education_level,
      year_grade      = p_year_grade
    where id = p_child_id
    returning * into v_row;
  end if;

  return row_to_json(v_row);
end;
$$;

-- ── RPC: reset_child_password ─────────────────────────────────────────────────
--
-- Called by: POST /rpc/reset_child_password (Supabase PostgREST)
-- Only the child's linked parent may call this.

create or replace function public.reset_child_password(
  p_child_id    uuid,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_parent_id uuid;
begin
  select id into v_parent_id
  from   public.parents
  where  user_id = auth.uid();
  if not found then
    raise exception 'Parent profile not found' using errcode = 'P0001';
  end if;

  update public.children
  set    password_hash = crypt(p_new_password, gen_salt('bf'))
  where  id = p_child_id
  and    parent_id = v_parent_id;

  if not found then
    raise exception 'Child not found or not owned by this parent'
    using errcode = 'P0002';
  end if;
end;
$$;

-- ── RPC: delete_child ─────────────────────────────────────────────────────────
--
-- Called by: POST /rpc/delete_child (Supabase PostgREST)
-- Hard-deletes a child record. The parent's ownership is verified server-side.
-- Quiz history and performance data will cascade-delete if FK constraints
-- reference children.id; add ON DELETE SET NULL / RESTRICT on those tables
-- when implementing those modules.
--
-- NOTE: The Flutter client also supports direct DELETE /children?id=eq.{id}
-- via the RLS policy "Parents delete own children" — either pathway is safe.

create or replace function public.delete_child(
  p_child_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_parent_id uuid;
begin
  select id into v_parent_id
  from   public.parents
  where  user_id = auth.uid();
  if not found then
    raise exception 'Parent profile not found' using errcode = 'P0001';
  end if;

  delete from public.children
  where  id = p_child_id
  and    parent_id = v_parent_id;

  if not found then
    raise exception 'Child not found or not owned by this parent'
    using errcode = 'P0002';
  end if;
end;
$$;

-- ── Child login (documented architecture) ─────────────────────────────────────
--
-- Child login uses Student ID + username + password (NOT Google/OAuth).
-- The POST /auth/child/login endpoint is implemented as a Supabase Edge
-- Function that:
--   1. Queries public.children WHERE student_id = $1 AND username = $2.
--   2. Verifies: crypt($3, password_hash) = password_hash  (pgcrypto).
--   3. Checks account_status = 'active'.
--   4. Issues a short-lived JWT (or uses supabaseAdmin.auth.signInWithPassword
--      on a service-role account) and returns {access_token, refresh_token,
--      expires_in, child_id}.
--
-- This SQL function is the database layer the Edge Function calls:

create or replace function public.verify_child_credentials(
  p_student_id text,
  p_username   text,
  p_password   text
)
returns table (
  child_id       uuid,
  is_valid       boolean,
  account_status text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  return query
  select
    c.id                                                          as child_id,
    (crypt(p_password, c.password_hash) = c.password_hash)       as is_valid,
    c.account_status
  from public.children c
  where c.student_id = p_student_id
  and   c.username   = lower(trim(p_username));
end;
$$;

-- Grant execute on all RPCs to authenticated role.
grant execute on function public.create_child         to authenticated;
grant execute on function public.update_child         to authenticated;
grant execute on function public.reset_child_password to authenticated;
grant execute on function public.delete_child         to authenticated;
grant execute on function public.verify_child_credentials to service_role;
