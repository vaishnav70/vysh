# VYSH — Flutter app (starter)

Flutter starter for the VYSH unisex fashion brand, connected to the same
Supabase backend as the website. This is a starting point, not a finished
store: it has the shop (4 collections), product detail, a bag, and an Owner
tab to post new designs. Checkout, social login, customisation studio and
payments are not in this starter yet.

## Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
   (3.4 or newer).
2. Copy your Supabase anon key into `lib/supabase_config.dart`:
   Supabase Dashboard → Settings → API → Project API keys → `anon` `public`.
   Never paste the `service_role` key into this app.
3. Make sure the Supabase tables exist (run the `products` / `orders` /
   `queries` SQL in the Supabase SQL Editor first).
4. Run it:

```sh
cd flutter-app
flutter pub get
flutter run
```

## iOS

1. Open `ios/Runner.xcworkspace` in Xcode on a Mac.
2. Sign in with an Apple Developer account and set the signing team.
3. Run on a simulator or device. For the App Store, archive the app in
   Xcode and submit it for review — that step needs the Apple Developer
   account ($99/year) and cannot be done from a web-only environment.

## What is inside

- `lib/main.dart` — shop home (collections, product grid, detail sheet),
  bag, and the Owner panel with the post-a-design form.
- `lib/supabase_config.dart` — Supabase project URL + anon key placeholder.
- `pubspec.yaml` — dependencies (`supabase_flutter`).

## Notes

- The starter was written by hand and has not been compiled in this
  environment. Run `flutter analyze` after `flutter pub get` to check it.
- Products come from the `products` table (`status = 'live'`); the Owner
  tab inserts into the same table, so posted designs show up in the shop.
