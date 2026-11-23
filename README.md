<p align="center">
  <img src="assets/logo/streetbite_logo.svg" width="110" alt="StreetBite Logo" />
</p>

# StreetBite 🍢🗺️

**StreetBite** is a hyper-local street food discovery and live vendor portal mobile application built with **Flutter** and **Firebase**. It helps foodies discover unlisted street food carts and stalls within a 1–25 km radius, search directly by dish cravings, check real-time open/closed status, and launch 1-tap turn-by-turn navigation—while giving street food vendors a zero-friction portal to toggle availability, manage menus, upload photos, and pin their GPS coordinates.

---

## ✨ Key Features

1. **Hyper-Local Geo-Radius Discovery (1 km – 25 km)**
   - Configurable distance radius slider (default `25 km`) powered by **Base32 Geohash prefix range queries** in Cloud Firestore combined with exact **Haversine distance filtering** (`lib/utils/geohash_util.dart`).
   - Toggle between **List / Responsive Grid View** and an **Interactive Clutter-Free Map View** powered by **CartoDB / OpenStreetMap (`flutter_map`)**—100% free with zero API keys or POI icon clutter—featuring status-colored markers (Green = Open Now, Grey = Closed) and a live radius circle.
   - Sort results by **Nearest Distance** or **Highest Rating**.

2. **Item-Based Craving Search (380 ms Debounced)**
   - Search directly by dish cravings (e.g., *momos*, *chaat*, *vada pav*, *locho*, *maggi*) rather than only stall names.
   - Uses a custom **380 ms Debouncer** (`lib/utils/debouncer.dart`) to coalesce keystrokes before querying.
   - Quick-tap craving chips (`Momos`, `Chaat`, `Pav Bhaji`, `Vada Pav`, `Rolls`, `Locho`, `Maggi`, `Late-Night`) + `"Open Now Only"` filter chip.

3. **Zero-Friction Vendor Portal (`Vendor Mode`)**
   - Real-time **Open / Closed live switch** updating Firestore immediately.
   - Add and edit **menu items** with dish name, price (`₹`), category, availability, and Veg / Non-Veg indicator.
   - Upload **stall photos** via `image_picker` + `firebase_storage` (rendered with `cached_network_image`).
   - **Pin Current GPS Location** button automatically captures latitude, longitude, and computes the Base32 geohash.

4. **Stall Details & 1-Tap Turn-by-Turn Navigation**
   - Hero banner image, live status pill, operating hours, crowd tags (e.g., *Late-night spot*, *Pocket friendly*), and split **Taste** & **Hygiene** community ratings.
   - **1-Tap Navigate** deep-links straight into Google Maps turn-by-turn directions (`url_launcher`) using exact coordinates (100% free, no API key required).
   - Interactive community review submission.

5. **Graceful Demo / Fallback Mode**
   - `Firebase.initializeApp()` is guarded in `main.dart` with `try/catch`, and empty live Firestore queries automatically display curated sample stalls so anyone testing the APK can explore every feature right away.

---

## 🏗️ Architecture

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # Spacing, radii, breakpoints, cravings, defaults
│   └── theme/
│       └── app_theme.dart            # Material 3 warm amber/orange Light & Dark themes
├── models/
│   ├── menu_item.dart                # MenuItem model with JSON serialization
│   ├── review.dart                   # Community taste & hygiene Review model
│   └── stall.dart                    # Stall & StallWithDistance models
├── utils/
│   ├── debouncer.dart                # 380ms search debouncer
│   └── geohash_util.dart             # Pure-Dart geohash encoder, 9-cell bounds & Haversine
├── services/
│   ├── firestore_stall_service.dart  # Dual-mode (Firestore + Demo) data service
│   ├── location_service.dart         # Geolocator wrapper with permission fallback
│   ├── mock_stall_data.dart          # Realistic sample stalls & reviews for Demo Mode
│   ├── navigation_service.dart       # Google Maps deep-link launcher
│   └── storage_service.dart          # Image picker + Firebase Storage upload wrapper
├── providers/
│   ├── auth_provider.dart            # Auth state (Firebase Auth / Demo user) + ThemeMode
│   ├── stall_provider.dart           # Discovery state, radius, craving search, sorting
│   └── vendor_provider.dart          # Vendor stall CRUD & instant open/closed toggles
├── widgets/
│   ├── craving_filter_chips.dart     # Dish craving chips & Open Now filter
│   ├── distance_radius_slider.dart   # 1-25 km radius slider
│   ├── menu_item_editor.dart         # Add/edit/remove menu items widget
│   ├── stall_card.dart               # Material 3 stall summary card
│   ├── stall_map_view.dart           # Clean CartoDB/OSM flutter_map view + preview card
│   ├── stall_shimmer_list.dart       # Shimmer loading placeholders
│   ├── status_pill.dart              # Open / Closed live badge
│   └── streetbite_logo.dart          # Custom vector brand logo widget
├── screens/
│   ├── add_edit_stall_screen.dart    # Vendor stall registration & editing form
│   ├── discover_screen.dart          # List/Map discovery hub
│   ├── profile_screen.dart           # Account, Demo/Live indicator & theme switcher
│   ├── stall_detail_screen.dart      # Banner, menu, reviews & 1-Tap Navigate
│   └── vendor_dashboard_screen.dart  # Vendor stall management & live status switch
├── firebase_options.dart             # FirebaseOptions for project streetbite-c4058
└── main.dart                         # App entry point, guarded Firebase init & HomeShell
```

---

## 📐 Geohash + Haversine Query Design

Because Cloud Firestore supports range queries on only one field at a time, `GeohashUtil` enables accurate geo-radius queries without external geo-libraries:

1. **Precision Selection**: Maps the selected radius (`1–25 km`) to an optimal geohash prefix precision (`precision 4` for 10–25 km, `precision 5` for 2–10 km, `precision 6` for < 2 km).
2. **9-Cell Neighbor Bounds**: Encodes the user's location and computes the center cell plus all 8 adjacent cells (`N, NE, E, SE, S, SW, W, NW`) to prevent edge-boundary misses.
3. **Prefix Range Queries**: Executes parallel Firestore queries `where('geohash', isGreaterThanOrEqualTo: start).where('geohash', isLessThanOrEqualTo: '$end~')` across merged ranges.
4. **Exact Haversine Pruning**: Deduplicates documents and computes exact great-circle distance in kilometers via `haversineDistanceKm()`, filtering strictly within the user's chosen radius and sorting by distance or rating.

---

## 📱 Direct APK Download & CI/CD

Every push to `main` triggers [`.github/workflows/build.yml`](.github/workflows/build.yml), which runs `flutter analyze`, `flutter test`, builds `StreetBite.apk`, and publishes it directly to GitHub Releases:

- **Direct Phone APK Installer:** `https://github.com/DhruvMatliwala/StreetBite/releases/download/v1.0.0/StreetBite.apk`
