-- ═══════════════════════════════════════════════════════════════════════════
-- Migration: ToyyibPay Payment Transactions Schema
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Table: payment_transactions
--   Stores one row per ToyyibPay bill. Status is updated server-side by the
--   `toyyibpay-callback` and `verify-toyyibpay-payment` Edge Functions.
--   NEVER updated directly from the Flutter client.
--
-- Security model:
--   • Parents read their own rows only.
--   • Admin reads all rows (via admin_users check).
--   • All writes go through service_role (Edge Functions).
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.payment_transactions (
  id                uuid        primary key default gen_random_uuid(),
  parent_id         uuid        not null references public.parents(id) on delete restrict,
  package_id        uuid        not null references public.subscription_packages(id),
  bill_code         text        not null unique,
  transaction_id    text,
  amount            int         not null check (amount > 0),      -- in sen
  status            text        not null default 'pending'
                                check (status in ('pending','success','failed','expired')),
  payment_method    text,
  paid_at           timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists payment_transactions_parent_id_idx
  on public.payment_transactions (parent_id);
create index if not exists payment_transactions_bill_code_idx
  on public.payment_transactions (bill_code);
create index if not exists payment_transactions_status_idx
  on public.payment_transactions (status);

-- updated_at trigger
create or replace function public.payment_transactions_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists payment_transactions_updated_at on public.payment_transactions;
create trigger payment_transactions_updated_at
  before update on public.payment_transactions
  for each row execute procedure public.payment_transactions_set_updated_at();

-- ── RLS ───────────────────────────────────────────────────────────────────────

alter table public.payment_transactions enable row level security;

-- Parents can read their own records (for polling and history).
create policy "Parents read own payment transactions"
  on public.payment_transactions for select
  using (
    parent_id in (
      select id from public.parents where user_id = auth.uid()
    )
  );

-- Admin reads all.
create policy "Admin reads all payment transactions"
  on public.payment_transactions for select
  using (
    exists (
      select 1 from public.admin_users where user_id = auth.uid()
    )
  );

-- All writes are performed via service_role (Edge Functions only).
-- The Flutter client never inserts or updates payment_transactions directly.
create policy "Service role full access payment transactions"
  on public.payment_transactions for all
  to service_role
  using (true)
  with check (true);

-- ── View: admin payment summary ───────────────────────────────────────────────
--
-- Convenience view joining payment_transactions with parent email for the
-- admin screen. Uses security_invoker so RLS on the base tables still applies.

create or replace view public.admin_payment_summary
  with (security_invoker = true)
as
select
  pt.id,
  pt.parent_id,
  p.email           as parent_email,
  pt.package_id,
  sp.name           as package_name,
  pt.bill_code,
  pt.transaction_id,
  pt.amount,
  pt.status,
  pt.payment_method,
  pt.paid_at,
  pt.created_at
from  public.payment_transactions pt
join  public.parents              p  on p.id = pt.parent_id
join  public.subscription_packages sp on sp.id = pt.package_id;

-- ── Indexes for admin view ────────────────────────────────────────────────────

create index if not exists payment_transactions_paid_at_idx
  on public.payment_transactions (paid_at desc nulls last)
  where status = 'success';
