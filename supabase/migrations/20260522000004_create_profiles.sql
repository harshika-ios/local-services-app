create table public.profiles (
  user_id      uuid        primary key references auth.users (id) on delete cascade,
  display_name text,
  phone        text,
  avatar_url   text,
  role         text        check (role in ('user', 'provider')),
  last_seen_at timestamptz
);

-- Auto-create a profile row with role 'user' whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, role)
  values (new.id, 'user')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
