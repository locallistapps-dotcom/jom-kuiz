-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Fix + Question Bank
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Resolves four issues left by the initial migration run:
--
--   FIX 1  — Create `private` schema + `private.generate_student_id()`.
--            Migration 02 created the function body but the `private` schema
--            didn't exist, so every create_child() call would fail at runtime.
--
--   FIX 2  — Re-apply the "Admins can manage content" policy on admin_content.
--            Migration 01 tried to create it before admin_users existed; the
--            statement errored and was silently skipped.
--
--   FIX 3  — Create the question-bank tables (subjects → years → chapters →
--            topics → questions) that migration 03 expected but were never
--            declared in any migration file.
--
--   FIX 4  — Create parent_subject_access (failed in migration 03 because
--            public.subjects didn't exist yet) and re-apply its RLS policies
--            and the activate_subscription RPC which depends on it.
-- ═══════════════════════════════════════════════════════════════════════════


-- ── FIX 1: private schema + generate_student_id ───────────────────────────────

create schema if not exists private;

create or replace function private.generate_student_id()
returns text
language plpgsql
as $$
declare
  v_id      text;
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


-- ── FIX 2: admin_content admin policy ────────────────────────────────────────
-- Drop first in case a partial version was somehow created.

drop policy if exists "Admins can manage content" on public.admin_content;

create policy "Admins can manage content"
  on public.admin_content for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));


-- ── FIX 3: Question bank tables ───────────────────────────────────────────────
--
-- Hierarchy: subjects → (years cross-ref via chapters) → chapters → topics → questions
-- subjects and years are independent lookup tables.
-- chapters belong to one subject and one year.
-- topics belong to one chapter.
-- questions belong to one topic.

-- ── subjects ──────────────────────────────────────────────────────────────────

create table if not exists public.subjects (
  id            uuid        primary key default gen_random_uuid(),
  subject_name  text        not null unique,
  description   text,
  icon          text,
  display_order int         not null default 0,
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists subjects_is_active_idx
  on public.subjects (is_active, display_order);

create or replace function public.subjects_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists subjects_updated_at on public.subjects;
create trigger subjects_updated_at
  before update on public.subjects
  for each row execute procedure public.subjects_set_updated_at();

alter table public.subjects enable row level security;

create policy "Authenticated users read active subjects"
  on public.subjects for select
  to authenticated
  using (is_active = true);

create policy "Admin full access subjects"
  on public.subjects for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

create policy "Service role full access subjects"
  on public.subjects for all to service_role
  using (true) with check (true);

-- ── years ─────────────────────────────────────────────────────────────────────

create table if not exists public.years (
  id            uuid        primary key default gen_random_uuid(),
  year_name     text        not null unique,
  display_order int         not null default 0,
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists years_is_active_idx
  on public.years (is_active, display_order);

create or replace function public.years_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists years_updated_at on public.years;
create trigger years_updated_at
  before update on public.years
  for each row execute procedure public.years_set_updated_at();

alter table public.years enable row level security;

create policy "Authenticated users read active years"
  on public.years for select
  to authenticated
  using (is_active = true);

create policy "Admin full access years"
  on public.years for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

create policy "Service role full access years"
  on public.years for all to service_role
  using (true) with check (true);

-- ── chapters ──────────────────────────────────────────────────────────────────

create table if not exists public.chapters (
  id            uuid        primary key default gen_random_uuid(),
  subject_id    uuid        not null references public.subjects(id) on delete cascade,
  year_id       uuid        not null references public.years(id) on delete cascade,
  chapter_name  text        not null,
  description   text,
  display_order int         not null default 0,
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (subject_id, year_id, chapter_name)
);

create index if not exists chapters_subject_year_idx
  on public.chapters (subject_id, year_id, display_order);
create index if not exists chapters_is_active_idx
  on public.chapters (is_active);

create or replace function public.chapters_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists chapters_updated_at on public.chapters;
create trigger chapters_updated_at
  before update on public.chapters
  for each row execute procedure public.chapters_set_updated_at();

alter table public.chapters enable row level security;

create policy "Authenticated users read active chapters"
  on public.chapters for select
  to authenticated
  using (is_active = true);

create policy "Admin full access chapters"
  on public.chapters for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

create policy "Service role full access chapters"
  on public.chapters for all to service_role
  using (true) with check (true);

-- ── topics ────────────────────────────────────────────────────────────────────

create table if not exists public.topics (
  id            uuid        primary key default gen_random_uuid(),
  chapter_id    uuid        not null references public.chapters(id) on delete cascade,
  topic_name    text        not null,
  description   text,
  display_order int         not null default 0,
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists topics_chapter_id_idx
  on public.topics (chapter_id, display_order);
create index if not exists topics_is_active_idx
  on public.topics (is_active);

create or replace function public.topics_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists topics_updated_at on public.topics;
create trigger topics_updated_at
  before update on public.topics
  for each row execute procedure public.topics_set_updated_at();

alter table public.topics enable row level security;

create policy "Authenticated users read active topics"
  on public.topics for select
  to authenticated
  using (is_active = true);

create policy "Admin full access topics"
  on public.topics for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

create policy "Service role full access topics"
  on public.topics for all to service_role
  using (true) with check (true);

-- ── questions ─────────────────────────────────────────────────────────────────

create table if not exists public.questions (
  id                    uuid        primary key default gen_random_uuid(),
  topic_id              uuid        not null references public.topics(id) on delete cascade,
  question_text         text        not null,
  question_type         text        not null default 'multiple_choice'
                                    check (question_type in ('multiple_choice','true_false','short_answer')),
  difficulty            text        not null default 'medium'
                                    check (difficulty in ('easy','medium','hard')),
  option_a              text,
  option_b              text,
  option_c              text,
  option_d              text,
  correct_answer        text        not null,
  explanation           text,
  explanation_image_url text,
  explanation_video_url text,
  question_image_url    text,
  reference             text,
  is_active             boolean     not null default true,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index if not exists questions_topic_id_idx
  on public.questions (topic_id, is_active);
create index if not exists questions_difficulty_idx
  on public.questions (difficulty) where is_active = true;

create or replace function public.questions_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists questions_updated_at on public.questions;
create trigger questions_updated_at
  before update on public.questions
  for each row execute procedure public.questions_set_updated_at();

alter table public.questions enable row level security;

create policy "Authenticated users read active questions"
  on public.questions for select
  to authenticated
  using (is_active = true);

create policy "Admin full access questions"
  on public.questions for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

create policy "Service role full access questions"
  on public.questions for all to service_role
  using (true) with check (true);


-- ── FIX 4: parent_subject_access + activate_subscription ─────────────────────
-- subjects now exists, so the FK constraint will resolve.

create table if not exists public.parent_subject_access (
  id          uuid        primary key default gen_random_uuid(),
  parent_id   uuid        not null references public.parents(id) on delete cascade,
  subject_id  uuid        not null references public.subjects(id) on delete cascade,
  granted_at  timestamptz not null default now(),
  source      text        not null default 'subscription'
                          check (source in ('subscription','manual','trial')),
  expires_at  timestamptz,
  unique (parent_id, subject_id)
);

create index if not exists parent_subject_access_parent_id_idx
  on public.parent_subject_access (parent_id);
create index if not exists parent_subject_access_subject_id_idx
  on public.parent_subject_access (subject_id);

alter table public.parent_subject_access enable row level security;

-- Drop any partial policies that may have been created before the table error.
drop policy if exists "Parents read own subject access"   on public.parent_subject_access;
drop policy if exists "Parents insert own subject access" on public.parent_subject_access;
drop policy if exists "Parents delete own subject access" on public.parent_subject_access;
drop policy if exists "Service role full access subject access" on public.parent_subject_access;
drop policy if exists "Admin reads all subject access"   on public.parent_subject_access;

create policy "Parents read own subject access"
  on public.parent_subject_access for select
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

create policy "Parents insert own subject access"
  on public.parent_subject_access for insert
  with check (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

create policy "Parents delete own subject access"
  on public.parent_subject_access for delete
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

create policy "Admin reads all subject access"
  on public.parent_subject_access for select
  using (
    exists (select 1 from public.admin_users where user_id = auth.uid())
  );

create policy "Service role full access subject access"
  on public.parent_subject_access for all
  to service_role
  using (true) with check (true);

-- Re-create activate_subscription now that parent_subject_access exists.

create or replace function public.activate_subscription(
  p_parent_id   uuid,
  p_package_id  uuid,
  p_start_date  date default current_date
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pkg    public.subscription_packages;
  v_expiry date;
  v_sub    public.parent_subscriptions;
begin
  -- Fetch package.
  select * into v_pkg
  from public.subscription_packages
  where id = p_package_id and is_active = true;
  if not found then
    raise exception 'Package not found or inactive' using errcode = 'P0001';
  end if;

  v_expiry := p_start_date + (v_pkg.duration_days || ' days')::interval;

  -- Cancel any existing active subscription.
  update public.parent_subscriptions
  set status = 'cancelled', updated_at = now()
  where parent_id = p_parent_id and status = 'active';

  -- Insert new subscription.
  insert into public.parent_subscriptions
    (parent_id, package_id, start_date, expiry_date, status)
  values
    (p_parent_id, p_package_id, p_start_date, v_expiry, 'active')
  returning * into v_sub;

  -- Grant subject access for every included subject.
  insert into public.parent_subject_access (parent_id, subject_id, source)
  select p_parent_id, unnest(v_pkg.included_subject_ids), 'subscription'
  on conflict (parent_id, subject_id) do nothing;

  return row_to_json(v_sub);
end;
$$;

grant execute on function public.activate_subscription to authenticated, service_role;
