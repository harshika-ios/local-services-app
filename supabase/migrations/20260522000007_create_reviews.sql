create table public.reviews (
  id            uuid        primary key default gen_random_uuid(),
  provider_id   uuid        not null references public.providers (id) on delete cascade,
  user_id       uuid        not null references auth.users (id) on delete cascade,
  reviewer_name text        not null default 'Anonymous',
  rating        integer     not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now()
);

create index reviews_provider_id_idx on public.reviews (provider_id);
create index reviews_created_at_idx  on public.reviews (created_at desc);
