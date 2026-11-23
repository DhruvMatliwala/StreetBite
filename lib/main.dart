import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/stall_provider.dart';
import 'package:streetbite/providers/vendor_provider.dart';
import 'package:streetbite/screens/discover_screen.dart';
import 'package:streetbite/screens/profile_screen.dart';
import 'package:streetbite/screens/vendor_dashboard_screen.dart';
import 'package:streetbite/services/firestore_stall_service.dart';
import 'package:streetbite/services/location_service.dart';
import 'package:streetbite/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var isDemoMode = false;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    isDemoMode = true;
    debugPrint(
      'Firebase initialization skipped ($e). Launching StreetBite in Demo Mode.',
    );
  }

  runApp(StreetBiteApp(isDemoMode: isDemoMode));
}

/// Root application widget wiring providers, Material 3 themes, and Demo Mode.
class StreetBiteApp extends StatelessWidget {
  const StreetBiteApp({super.key, required this.isDemoMode});

  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    final stallService = FirestoreStallService(isDemoMode: isDemoMode);
    final locationService = LocationService();
    final storageService = StorageService(isDemoMode: isDemoMode);

    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(isDemoMode: isDemoMode),
        ),
        ChangeNotifierProvider<StallProvider>(
          create: (_) => StallProvider(
            stallService: stallService,
            locationService: locationService,
          )..initialize(),
        ),
        ChangeNotifierProvider<VendorProvider>(
          create: (_) => VendorProvider(
            stallService: stallService,
            storageService: storageService,
            locationService: locationService,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'StreetBite',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: auth.themeMode,
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

/// Adaptive shell providing Bottom NavigationBar on phones and NavigationRail on tablets.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0 || index == 1) {
      context.read<StallProvider>().setMapView(index == 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBody = switch (_selectedIndex) {
      0 || 1 => DiscoverScreen(
          onMapModeChanged: (isMap) {
            setState(() => _selectedIndex = isMap ? 1 : 0);
          },
        ),
      2 => const VendorDashboardScreen(),
      _ => const ProfileScreen(),
    };

    const destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore_rounded),
        label: 'Discover',
      ),
      NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map_rounded),
        label: 'Map',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: 'Vendor Mode',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: activeBody),
              ],
            ),
          );
        }

        return Scaffold(
          body: activeBody,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: destinations,
          ),
        );
      },
    );
  }
}
