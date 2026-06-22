create table public.providers (
  id           uuid             primary key default gen_random_uuid(),
  name         text             not null,
  phone        text             not null,
  service_type text             not null,
  latitude     double precision,
  longitude    double precision,
  address      text,
  description  text,
  avatar_url   text,
  is_active    boolean          not null default true,
  user_id      uuid             references auth.users (id) on delete set null,
  view_count   integer          not null default 0,
  created_at   timestamptz      not null default now()
);

create index providers_service_type_idx on public.providers (service_type);
create index providers_created_at_idx   on public.providers (created_at desc);
create index providers_user_id_idx      on public.providers (user_id);
