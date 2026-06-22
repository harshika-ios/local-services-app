# Local Services App

A Flutter marketplace app that connects users with nearby local service providers such as electricians, plumbers, cleaners, AC repair technicians, gardeners, carpenters, painters, and mechanics.

## Features

- Email sign in and sign up with Supabase Auth
- Role-based onboarding for users and service providers
- Browse local providers with category filters and search
- Sort providers by nearest, most saved, or newest
- Location-aware provider distance calculation
- Google Maps view for nearby providers
- Provider detail pages with phone, WhatsApp, reviews, favorites, and booking actions
- User bookings and favorite provider list
- Provider dashboard with views, favorites, upcoming bookings, availability, and service area tools
- Provider profile editing and avatar uploads
- Supabase Row Level Security policies for user-owned data

## Tech Stack

- Flutter / Dart
- Supabase Auth
- Supabase Postgres
- Supabase Storage
- Google Maps Flutter
- Geolocator and Geocoding
- url_launcher
- image_picker
- flutter_dotenv

## Project Structure

```text
.
+-- README.md
`-- local-services-app/
    +-- lib/
    |   +-- main.dart
    |   +-- models/
    |   +-- screens/
    |   +-- services/
    |   +-- utils/
    |   `-- widgets/
    +-- supabase/
    |   `-- migrations/
    +-- android/
    +-- ios/
    +-- web/
    +-- assets/
    +-- pubspec.yaml
    +-- .env.example
    `-- SUPABASE_SETUP.md
```

## Main App Flow

1. The app loads environment variables from `.env`.
2. Supabase is initialized in `lib/main.dart`.
3. A splash screen is shown.
4. The auth gate checks the current Supabase session.
5. Signed-out users are sent to the login screen.
6. Signed-in users are routed by profile role:
   - `user` goes to the customer home screen.
   - `provider` goes to provider onboarding if no provider listing exists.
   - `provider` with a listing goes to the provider dashboard.

## Supabase Data Model

The project includes SQL migrations under `local-services-app/supabase/migrations`.

Main tables:

- `profiles` - user profile, role, phone, avatar, and last seen timestamp
- `providers` - service listings, location, avatar, active status, owner, and view count
- `categories` - service categories
- `bookings` - customer bookings with providers
- `favorites` - saved providers per user
- `reviews` - ratings and comments for providers

Other backend pieces:

- `avatars` public Supabase Storage bucket
- `increment_provider_view` RPC function
- Row Level Security policies for profiles, providers, bookings, favorites, reviews, and storage objects

## Getting Started

### 1. Install Flutter dependencies

```bash
cd local-services-app
flutter pub get
```

### 2. Configure Supabase

Create a Supabase project, then run the SQL migrations from:

```text
local-services-app/supabase/migrations
```

More detailed setup instructions are available in:

```text
local-services-app/SUPABASE_SETUP.md
```

### 3. Add environment variables

Copy the example file:

```bash
cp .env.example .env
```

Fill in your Supabase credentials:

```dotenv
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

The `.env` file is intentionally ignored by git.

### 4. Configure Google Maps

For Android, add your key to `android/local.properties`:

```properties
MAPS_API_KEY=YOUR_ANDROID_MAPS_API_KEY
```

For iOS, update the `GMSApiKey` value in `ios/Runner/Info.plist` or move the value into your own private config workflow before release.

### 5. Run the app

```bash
flutter run
```

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Notes

- The repository root README is for GitHub.
- The actual Flutter app is inside `local-services-app`.
- Do not commit `.env`, API keys, signing keys, or service role credentials.
- Seed data for categories and sample providers is included in the Supabase migrations.
