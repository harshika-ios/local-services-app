create table public.categories (
  slug         text    primary key,
  display_name text    not null,
  sort_order   integer not null default 0
);
