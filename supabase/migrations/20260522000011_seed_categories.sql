insert into public.categories (slug, display_name, sort_order) values
  ('electrician', 'Electrician', 1),
  ('plumber',     'Plumber',     2),
  ('ac_repair',   'AC Repair',   3),
  ('cleaning',    'Cleaning',    4),
  ('gardening',   'Gardening',   5),
  ('carpenter',   'Carpenter',   6),
  ('painter',     'Painter',     7),
  ('mechanic',    'Mechanic',    8)
on conflict (slug) do nothing;
