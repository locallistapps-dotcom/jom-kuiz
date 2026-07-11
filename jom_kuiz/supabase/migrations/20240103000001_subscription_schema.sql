-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: Subscription, Package & Subject Access Schema
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Tables:
--   subscription_packages  — packages an admin creates and parents buy
--   parent_subscriptions   — one active subscription per parent
--   parent_subject_access  — per-subject access records (parent-scoped;
--                            children inherit automatically via service layer)
--
-- RLS summary:
--   subscription_packages  — authenticated users read active; admin write
--   parent_subscriptions   — parent reads own; admin reads all
--   parent_subject_access  — parent reads own; admin reads all; service writes
--
-- No payment logic is included — activation is driven by the future Payment
-- module calling the `activate_subscription` RPC below.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── subscription_packages ─────────────────────────────────────────────────────

create table if not exists public.subscription_packages (
  id                   uuid        primary key default gen_random_uuid(),
  name                 text        not null unique,
  description          text,
  max_children         int         not null default 5 check (max_children > 0),
  -- Array of subject UUIDs included in this package.
  -- PostgREST serialises uuid[] as a JSON array of strings.
  included_subject_ids uuid[]      not null default '{}',
  price_cents          int         not null default 0 check (price_cents >= 0),
  duration_days        int         not null default 30 check (duration_days > 0),
  is_active            boolean     not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create or replace function public.subscription_packages_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists subscription_packages_updated_at on public.subscription_packages;
create trigger subscription_packages_updated_at
  before update on public.subscription_packages
  for each row execute procedure public.subscription_packages_set_updated_at();

-- ── parent_subscriptions ──────────────────────────────────────────────────────

create table if not exists public.parent_subscriptions (
  id           uuid        primary key default gen_random_uuid(),
  parent_id    uuid        not null references public.parents(id) on delete cascade,
  package_id   uuid        not null references public.subscription_packages(id),
  start_date   date        not null,
  expiry_date  date        not null,
  status       text        not null default 'pending'
                           check (status in ('active','expired','cancelled','pending')),
  auto_renew   boolean     not null default false, -- reserved for future use
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists parent_subscriptions_parent_id_idx
  on public.parent_subscriptions (parent_id);
create index if not exists parent_subscriptions_status_idx
  on public.parent_subscriptions (status);

create or replace function public.parent_subscriptions_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists parent_subscriptions_updated_at on public.parent_subscriptions;
create trigger parent_subscriptions_updated_at
  before update on public.parent_subscriptions
  for each row execute procedure public.parent_subscriptions_set_updated_at();

-- ── parent_subject_access ─────────────────────────────────────────────────────

create table if not exists public.parent_subject_access (
  id          uuid        primary key default gen_random_uuid(),
  parent_id   uuid        not null references public.parents(id) on delete cascade,
  subject_id  uuid        not null references public.subjects(id) on delete cascade,
  granted_at  timestamptz not null default now(),
  source      text        not null default 'subscription'
                          check (source in ('subscription','manual','trial')),
  expires_at  timestamptz,          -- null = never expires
  unique (parent_id, subject_id)    -- no duplicate access records
);

create index if not exists parent_subject_access_parent_id_idx
  on public.parent_subject_access (parent_id);
create index if not exists parent_subject_access_subject_id_idx
  on public.parent_subject_access (subject_id);

-- ── RLS ───────────────────────────────────────────────────────────────────────

alter table public.subscription_packages  enable row level security;
alter table public.parent_subscriptions   enable row level security;
alter table public.parent_subject_access  enable row level security;

-- subscription_packages: anyone authenticated can read active packages;
-- admin mutations go via service_role or the RPC below.
create policy "Authenticated users read active packages"
  on public.subscription_packages for select
  to authenticated
  using (is_active = true);

create policy "Service role full access packages"
  on public.subscription_packages for all
  to service_role
  using (true)
  with check (true);

-- parent_subscriptions: parent sees only their own record.
create policy "Parents read own subscription"
  on public.parent_subscriptions for select
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

create policy "Service role full access subscriptions"
  on public.parent_subscriptions for all
  to service_role
  using (true)
  with check (true);

-- parent_subject_access: parent sees only their own access records.
create policy "Parents read own subject access"
  on public.parent_subject_access for select
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- Parent can insert their own rows (used by grant RPC / direct PostgREST).
create policy "Parents insert own subject access"
  on public.parent_subject_access for insert
  with check (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- Parent can delete their own rows (used by revoke).
create policy "Parents delete own subject access"
  on public.parent_subject_access for delete
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

create policy "Service role full access subject access"
  on public.parent_subject_access for all
  to service_role
  using (true)
  with check (true);

-- ── Admin: read all ───────────────────────────────────────────────────────────
-- Admin users (identified via admin_users table) may read all rows.

create policy "Admin reads all subscriptions"
  on public.parent_subscriptions for select
  using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid()
    )
  );

create policy "Admin reads all subject access"
  on public.parent_subject_access for select
  using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid()
    )
  );

create policy "Admin full access packages"
  on public.subscription_packages for all
  using (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.admin_users
      where user_id = auth.uid()
    )
  );

-- ── RPC: activate_subscription ───────────────────────────────────────────────
--
-- Called by: POST /rpc/activate_subscription
-- Creates or replaces the parent's active subscription and grants subject
-- access for every included subject in the chosen package.
--
-- This RPC is the single entry point for the Payment module to call after
-- a successful charge. Until Payment is implemented, the admin may call it
-- directly via service_role.

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

-- ── Seed data (optional — remove in production before running) ───────────────
-- Uncomment to seed one starter package for testing:
--
-- insert into public.subscription_packages (name, description, max_children, price_cents, duration_days)
-- values ('Starter Pack', 'Access to 2 subjects for 1 child', 1, 999, 30)
-- on conflict (name) do nothing;
