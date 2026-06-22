import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profile_model.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/provider_home_screen.dart';
import 'screens/provider_onboarding_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const LocalServicesApp());
}

class LocalServicesApp extends StatelessWidget {
  const LocalServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Services',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6BFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        useMaterial3: true,
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFFD6E4FF),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0,
            );
          }),
        ),
      ),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _splashDone
          ? const _AuthGate(key: ValueKey('auth'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onGetStarted: () => setState(() => _splashDone = true),
            ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final session = auth.currentSession;
        if (session == null) {
          FavoritesService.instance.clear();
          return const LoginScreen();
        }
        return _RoleRouter(key: ValueKey(session.user.id));
      },
    );
  }
}

enum _Destination { roleSelection, home, providerOnboarding, providerDashboard }

class _RoleRouter extends StatefulWidget {
  const _RoleRouter({super.key});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  late Future<_Destination> _destination;

  @override
  void initState() {
    super.initState();
    _destination = _resolve();
  }

  Future<_Destination> _resolve() async {
    unawaited(ProfileService.instance.updateLastSeen());
    final profile = await ProfileService.instance.fetchMyProfile();
    if (profile?.role == null) return _Destination.roleSelection;
    if (profile!.role == UserRole.user) return _Destination.home;
    final providerRow = await ProfileService.instance.fetchMyProvider();
    return providerRow == null
        ? _Destination.providerOnboarding
        : _Destination.providerDashboard;
  }

  void _refresh() {
    setState(() {
      _destination = _resolve();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Destination>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        switch (snapshot.data!) {
          case _Destination.roleSelection:
            return RoleSelectionScreen(onChosen: _refresh);
          case _Destination.home:
            return const HomeScreen();
          case _Destination.providerOnboarding:
            return ProviderOnboardingScreen(onSubmitted: _refresh);
          case _Destination.providerDashboard:
            return const ProviderHomeScreen();
        }
      },
    );
  }
}
