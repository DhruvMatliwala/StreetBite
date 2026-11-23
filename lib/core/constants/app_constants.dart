/// Centralized layout spacing, radii, breakpoints, and domain defaults.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

abstract final class AppRadii {
  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double pill = 999.0;
}

abstract final class AppBreakpoints {
  static const double tablet = 600.0;
  static const double desktop = 960.0;
}

abstract final class AppGeoDefaults {
  static const double minRadiusKm = 1.0;
  static const double maxRadiusKm = 25.0;
  static const double defaultRadiusKm = 25.0;
  static const double defaultLatitude = 21.1702;
  static const double defaultLongitude = 72.8311;
  static const String defaultLocationLabel = 'Surat Food Corridor (Demo)';
}

abstract final class AppSearchConfig {
  static const Duration debounceDuration = Duration(milliseconds: 380);

  static const List<String> cravingTags = <String>[
    'Momos',
    'Chaat',
    'Pav Bhaji',
    'Vada Pav',
    'Rolls',
    'Locho',
    'Maggi',
    'Late-Night',
  ];

  static const List<String> crowdTagSuggestions = <String>[
    'Late-night spot',
    'Pocket friendly',
    'Hygiene star',
    'Spicy favorite',
    'Student hangout',
    'Family friendly',
    'Pure veg',
    'Quick bite',
  ];
}
