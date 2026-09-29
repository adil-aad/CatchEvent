import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/registration_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organizer/organizer_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey == AppConstants.unconfiguredFirebaseApiKey) {
      startupError = 'notConfigured';
    } else {
      await Firebase.initializeApp(options: options);
    }
  } on Object catch (e) {
    startupError = e.toString();
  }

  runApp(CatchEventApp(startupError: startupError));
}

class CatchEventApp extends StatelessWidget {
  /// Non-null when Firebase could not be initialised. `'notConfigured'` means
  /// `flutterfire configure` has not been run yet.
  final String? startupError;

  const CatchEventApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: _buildTheme(),
        debugShowCheckedModeBanner: false,
        home: _FirebaseSetupScreen(error: startupError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // The event and registration providers follow whoever is signed in:
        // `bind` starts their Firestore subscriptions on login and tears them
        // down on logout.
        ChangeNotifierProxyProvider<AuthProvider, EventProvider>(
          create: (_) => EventProvider(),
          update: (_, auth, events) => events!..bind(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RegistrationProvider>(
          create: (_) => RegistrationProvider(),
          update: (_, auth, registrations) =>
              registrations!..bind(auth.user?.uid),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: _buildTheme(),
        debugShowCheckedModeBanner: false,
        home: const _AuthGate(),
      ),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      inputDecorationTheme: const InputDecorationTheme(filled: true),
      cardTheme: const CardThemeData(elevation: 0),
    );
  }
}

/// Routes on auth state and role: splash → login, or student / organizer home.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return auth.isOrganizer
            ? const OrganizerHomeScreen()
            : const StudentHomeScreen();
    }
  }
}

/// Shown while the previous session is being restored on launch.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Replaces the app when Firebase is missing or misconfigured, so the failure
/// is self-explanatory instead of an opaque platform exception.
class _FirebaseSetupScreen extends StatelessWidget {
  final String error;

  const _FirebaseSetupScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notConfigured = error == 'notConfigured';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  notConfigured
                      ? 'Firebase is not configured yet'
                      : 'Firebase failed to start',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  notConfigured
                      ? 'Run these commands in the project folder, then restart '
                          'the app:'
                      : 'Firebase returned an error while starting up:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notConfigured
                        ? 'dart pub global activate flutterfire_cli\n'
                            'flutterfire configure'
                        : error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Full instructions are in FIREBASE_SETUP.md.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
