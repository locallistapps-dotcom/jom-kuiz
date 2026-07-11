-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: admin_content + admin_users tables + Storage buckets
-- ─────────────────────────────────────────────────────────────────────────────

-- ── admin_content ─────────────────────────────────────────────────────────────

create table if not exists public.admin_content (
  id           uuid        primary key default gen_random_uuid(),
  type         text        not null check (type in ('announcement','banner','lesson','faq')),
  title        text        not null,
  body         text        not null default '',
  image_url    text,
  is_published boolean     not null default false,
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists admin_content_type_idx
  on public.admin_content (type);

create index if not exists admin_content_published_idx
  on public.admin_content (is_published, created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists admin_content_updated_at on public.admin_content;
create trigger admin_content_updated_at
  before update on public.admin_content
  for each row execute procedure public.set_updated_at();

alter table public.admin_content enable row level security;

-- Admins: full access.
create policy "Admins can manage content"
  on public.admin_content for all
  using  (exists (select 1 from public.admin_users where user_id = auth.uid()))
  with check (exists (select 1 from public.admin_users where user_id = auth.uid()));

-- Authenticated users: read published content only.
create policy "Authenticated users read published content"
  on public.admin_content for select
  using (is_published = true and auth.role() = 'authenticated');

-- ── admin_users ───────────────────────────────────────────────────────────────

create table if not exists public.admin_users (
  user_id    uuid        primary key references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by uuid        references auth.users(id) on delete set null
);

alter table public.admin_users enable row level security;

create policy "Admins can read admin_users"
  on public.admin_users for select
  using (
    auth.uid() = user_id
    or exists (select 1 from public.admin_users au where au.user_id = auth.uid())
  );

create policy "Super-admin can insert admin_users"
  on public.admin_users for insert
  with check (
    exists (select 1 from public.admin_users au where au.user_id = auth.uid())
  );

-- ── Storage: question-media ───────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'question-media', 'question-media', true, 10485760,
  array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']
)
on conflict (id) do nothing;

create policy "Admins upload question media"
  on storage.objects for insert
  with check (
    bucket_id = 'question-media'
    and exists (select 1 from public.admin_users where user_id = auth.uid())
  );

create policy "Admins delete question media"
  on storage.objects for delete
  using (
    bucket_id = 'question-media'
    and exists (select 1 from public.admin_users where user_id = auth.uid())
  );

create policy "Public read question media"
  on storage.objects for select
  using (bucket_id = 'question-media');

-- ── Storage: content-media ────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'content-media', 'content-media', true, 5242880,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do nothing;

create policy "Admins upload content media"
  on storage.objects for insert
  with check (
    bucket_id = 'content-media'
    and exists (select 1 from public.admin_users where user_id = auth.uid())
  );

create policy "Admins delete content media"
  on storage.objects for delete
  using (
    bucket_id = 'content-media'
    and exists (select 1 from public.admin_users where user_id = auth.uid())
  );

create policy "Public read content media"
  on storage.objects for select
  using (bucket_id = 'content-media');
