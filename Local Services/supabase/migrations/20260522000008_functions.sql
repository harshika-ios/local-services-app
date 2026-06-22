-- Increments view_count on a provider via RPC.
-- Security definer so it can bypass RLS; skips the call when the viewer owns the listing.
create or replace function public.increment_provider_view(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.providers
    where id = p_id and user_id = auth.uid()
  ) then
    return;
  end if;

  update public.providers
  set view_count = view_count + 1
  where id = p_id;
end;
$$;
