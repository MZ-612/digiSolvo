create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  company text not null default '' check (char_length(company) <= 160),
  email text not null default '' check (char_length(email) <= 254),
  service text not null,
  status text not null default 'Lead' check (status in ('Lead', 'Active', 'Completed')),
  created_at timestamptz not null default now(),
  unique (user_id, id)
);

create table if not exists public.client_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  client_id uuid not null,
  note text not null check (char_length(note) between 1 and 500),
  happened_at timestamptz not null default now(),
  foreign key (user_id, client_id) references public.clients (user_id, id) on delete cascade
);

create table if not exists public.client_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  client_id uuid not null,
  transaction_date date not null,
  sale_amount numeric(12, 2) not null check (sale_amount >= 0),
  cost_amount numeric(12, 2) not null check (cost_amount >= 0),
  note text not null default '' check (char_length(note) <= 240),
  created_at timestamptz not null default now(),
  foreign key (user_id, client_id) references public.clients (user_id, id) on delete cascade
);

create table if not exists public.monthly_targets (
  user_id uuid not null references auth.users (id) on delete cascade,
  target_month date not null check (extract(day from target_month) = 1),
  sales_target numeric(12, 2) not null default 0 check (sales_target >= 0),
  profit_target numeric(12, 2) not null default 0 check (profit_target >= 0),
  primary key (user_id, target_month)
);

create index if not exists client_activities_client_date_idx on public.client_activities (user_id, client_id, happened_at desc);
create index if not exists client_transactions_month_idx on public.client_transactions (user_id, transaction_date desc);

alter table public.clients enable row level security;
alter table public.client_activities enable row level security;
alter table public.client_transactions enable row level security;
alter table public.monthly_targets enable row level security;

drop policy if exists "Users manage their own clients" on public.clients;
create policy "Users manage their own clients" on public.clients
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users manage their own client activities" on public.client_activities;
create policy "Users manage their own client activities" on public.client_activities
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users manage their own client transactions" on public.client_transactions;
create policy "Users manage their own client transactions" on public.client_transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users manage their own monthly targets" on public.monthly_targets;
create policy "Users manage their own monthly targets" on public.monthly_targets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);