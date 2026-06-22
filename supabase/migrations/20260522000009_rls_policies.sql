-- ============================================================
-- providers
-- ============================================================
alter table public.providers enable row level security;

-- Anon/authenticated can read active listings; owners can always read their own
create policy "Anyone can read active providers"
  on public.providers for select
  using (is_active = true or user_id = auth.uid());

create policy "Providers can insert their own listing"
  on public.providers for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Providers can update their own listing"
  on public.providers for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Providers can delete their own listing"
  on public.providers for delete
  to authenticated
  using (user_id = auth.uid());

-- ============================================================
-- categories
-- ============================================================
alter table public.categories enable row level security;

create policy "Anyone can read categories"
  on public.categories for select
  using (true);

-- ============================================================
-- profiles
-- ============================================================
alter table public.profiles enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- bookings
-- ============================================================
alter table public.bookings enable row level security;

-- Customers see their bookings; providers see bookings for their listing
create policy "Users and providers can read relevant bookings"
  on public.bookings for select
  to authenticated
  using (
    user_id = auth.uid()
    or provider_id in (
      select id from public.providers where user_id = auth.uid()
    )
  );

create policy "Authenticated users can create bookings"
  on public.bookings for insert
  to authenticated
  with check (user_id = auth.uid());

-- Customers can cancel their own upcoming bookings
create policy "Users can update their own bookings"
  on public.bookings for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- favorites
-- ============================================================
alter table public.favorites enable row level security;

create policy "Users can read their own favorites"
  on public.favorites for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can add favorites"
  on public.favorites for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can remove favorites"
  on public.favorites for delete
  to authenticated
  using (user_id = auth.uid());

-- ============================================================
-- reviews
-- ============================================================
alter table public.reviews enable row level security;

create policy "Anyone can read reviews"
  on public.reviews for select
  using (true);

create policy "Authenticated users can submit reviews"
  on public.reviews for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can delete their own reviews"
  on public.reviews for delete
  to authenticated
  using (user_id = auth.uid());
