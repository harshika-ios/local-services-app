create table public.bookings (
  id            uuid        primary key default gen_random_uuid(),
  user_id       uuid        not null references auth.users (id) on delete cascade,
  provider_id   uuid        not null references public.providers (id) on delete cascade,
  scheduled_for timestamptz not null,
  status        text        not null default 'upcoming'
                            check (status in ('upcoming', 'completed', 'cancelled')),
  notes         text,
  customer_name text,
  created_at    timestamptz not null default now()
);

create index bookings_user_id_idx      on public.bookings (user_id);
create index bookings_provider_id_idx  on public.bookings (provider_id);
create index bookings_scheduled_for_idx on public.bookings (scheduled_for desc);
create index bookings_status_idx       on public.bookings (status);
