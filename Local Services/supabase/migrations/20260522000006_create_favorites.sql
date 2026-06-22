create table public.favorites (
  user_id     uuid        not null references auth.users (id) on delete cascade,
  provider_id uuid        not null references public.providers (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, provider_id)
);

create index favorites_user_id_idx     on public.favorites (user_id);
create index favorites_provider_id_idx on public.favorites (provider_id);
