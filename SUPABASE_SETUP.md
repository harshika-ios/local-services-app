# Supabase Setup — Local Services App (Phase 1)

This guide walks you through setting up Supabase for the Phase 1 build: a `providers` table that the Flutter app reads from.

---

## 1. Create a Supabase Project

1. Go to <https://supabase.com> and sign in.
2. Click **New Project**.
3. Fill in:
   - **Name**: `local-services-app`
   - **Database Password**: pick a strong one and save it
   - **Region**: choose the one closest to your users
4. Click **Create new project** and wait ~1–2 minutes for provisioning.

---

## 2. Get Your API Credentials

1. In your project dashboard go to **Project Settings → API**.
2. Copy these two values — you'll need them in the Flutter app:
   - **Project URL** → `https://YOUR-PROJECT-REF.supabase.co`
   - **anon public key** → `eyJhbGciOi...` (long JWT string)

> Never commit the `service_role` key into the app. Only the `anon` key is safe for client use.

---

## 3. Create the `providers` Table

Open **SQL Editor → New query** and run:

```sql
create extension if not exists "pgcrypto";

create table public.providers (
  id           uuid        primary key default gen_random_uuid(),
  name         text        not null,
  phone        text        not null,
  service_type text        not null,
  latitude     double precision,
  longitude    double precision,
  address      text,
  created_at   timestamptz not null default now()
);

create index providers_service_type_idx on public.providers (service_type);
create index providers_created_at_idx   on public.providers (created_at desc);
```

Or, via the **Table Editor** UI, create a table named `providers` with the same columns.

---

## 4. Enable Row Level Security & Add a Read Policy

Phase 1 has no auth, so we allow public read access only.

```sql
alter table public.providers enable row level security;

create policy "Public can read providers"
  on public.providers
  for select
  to anon
  using (true);
```

> No `insert/update/delete` policies are added — writes are blocked from the app and must be done via the Supabase dashboard or service role.

---

## 5. Seed Some Sample Data

```sql
insert into public.providers (name, phone, service_type, latitude, longitude, address) values
  ('Ramesh Electric Works',  '+919812345678', 'electrician', 28.6139, 77.2090, 'Connaught Place, New Delhi'),
  ('Quick Fix Plumbing',     '+919823456789', 'plumber',     28.5355, 77.3910, 'Sector 18, Noida'),
  ('CoolBreeze AC Service',  '+919834567890', 'ac_repair',   28.4595, 77.0266, 'Cyber Hub, Gurugram'),
  ('Sparkle Home Cleaning',  '+919845678901', 'cleaning',    28.7041, 77.1025, 'Model Town, Delhi'),
  ('GreenThumb Gardener',    '+919856789012', 'gardening',   28.6304, 77.2177, 'Karol Bagh, Delhi');
```

---

## 6. Wire the Credentials Into the Flutter App

The app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from a `.env` file using the `flutter_dotenv` package.

1. Copy `.env.example` to `.env` at the project root:

   ```bash
   cp .env.example .env
   ```

2. Open `.env` and paste your real values:

   ```dotenv
   SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
   SUPABASE_ANON_KEY=YOUR-ANON-KEY
   ```

3. The `.env` file is already:
   - registered as a Flutter asset in `pubspec.yaml` (under `flutter > assets`)
   - listed in `.gitignore` (so it never gets committed)
   - loaded in `lib/main.dart` via `dotenv.load(fileName: '.env')`

> Only `.env.example` (a template with placeholders) is checked into git.

---

## 7. Install Dependencies & Run

```bash
flutter pub get
flutter run
```

You should see the seeded providers in a card list, each with **Call** and **WhatsApp** buttons.

---

## 8. Platform Permissions (Already Handled)

- **Android** — `ACCESS_FINE_LOCATION` is in `android/app/src/main/AndroidManifest.xml`. `tel:` and `https:` schemes work out of the box for `url_launcher`.
- **iOS** — `LSApplicationQueriesSchemes` (`tel`, `https`, `whatsapp`) is already in `ios/Runner/Info.plist`.

---

## 10. Google Maps API Key

The Map tab uses `google_maps_flutter`. Without a key, the map renders blank tiles.

1. In Google Cloud Console, enable **Maps SDK for Android** and **Maps SDK for iOS**, then create an API key. Restrict it to those two SDKs and to your bundle/package IDs.

2. **Android** — open `android/local.properties` (already gitignored) and add:

   ```properties
   MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
   ```

   The value is read by `android/app/build.gradle.kts` and injected into `AndroidManifest.xml` as a `manifestPlaceholder`. No commit needed.

3. **iOS** — open `ios/Runner/Info.plist` and replace the placeholder:

   ```xml
   <key>GMSApiKey</key>
   <string>YOUR_IOS_MAPS_API_KEY</string>
   ```

   `AppDelegate.swift` reads this and calls `GMSServices.provideAPIKey` at launch. **Do not commit** the real value — either keep it out of source control via your own `.gitignore` rule, or use an xcconfig.

---

## 9. Verify in the Supabase Dashboard

- **Table Editor** → `providers` should show your seeded rows.
- **Logs → API** will show the `GET /rest/v1/providers` call when the app loads.

You're done with Phase 1.
