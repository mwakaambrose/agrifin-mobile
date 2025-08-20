import 'package:agrifinity/core/config_repository.dart';
import 'package:agrifinity/core/navigation/navigation_service.dart';
import 'package:agrifinity/core/offline/offline_queue.dart';
import 'package:agrifinity/core/session/session_manager.dart';
import 'package:agrifinity/features/auth/data/auth_repository.dart';
import 'package:agrifinity/features/fines/presentation/fines_screen.dart';
import 'package:agrifinity/features/loans/presentation/loans_screen.dart';
import 'package:agrifinity/features/meetings/presentation/meetings_screen.dart';
import 'package:agrifinity/features/savings/presentation/savings_screen.dart';
import 'package:agrifinity/features/social/presentation/social_screen.dart';
import 'package:agrifinity/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/home_screen.dart';
import 'core/config.dart';
import 'core/session/user_session.dart';

// Additional feature screens
import 'features/accounts/presentation/accounts_overview_screen.dart';
import 'features/member/presentation/member_list_screen.dart';
import 'features/member/presentation/member_profile_screen.dart';
import 'features/group/presentation/group_profile_screen.dart';
import 'features/cycle/presentation/cycle_list_screen.dart';
import 'features/constitution/presentation/constitution_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/transactions/presentation/transactions_screen.dart';
import 'core/context/current_context.dart';
import 'features/attendance/presentation/attendance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Initialize auth state
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'auth_token');
  SessionManager.instance.setAuthenticated(token != null && token.isNotEmpty);
  // Optionally warm up offline queue
  await OfflineQueueService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<ConfigRepository>(create: (_) => ConfigRepository()),
        Provider<OfflineQueueService>.value(
          value: OfflineQueueService.instance,
        ),
        ChangeNotifierProvider<CurrentContext>(
          create: (_) => CurrentContext()..refresh(),
        ),
        ChangeNotifierProvider<UserSession>(
          create: (_) => UserSession()..loadFromCache(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final _router = GoRouter(
  navigatorKey: NavigationService.rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: SessionManager.instance,
  redirect: (ctx, state) {
    final loggedIn = SessionManager.instance.isAuthenticated;
    final loggingIn = state.fullPath == '/login';
    if (state.fullPath == '/') return null; // Splash handles bootstrapping
    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (ctx, st) => const SplashScreen()),
    GoRoute(path: '/login', builder: (ctx, st) => const LoginScreen()),
    GoRoute(path: '/home', builder: (ctx, st) => const HomeScreen()),
    GoRoute(path: '/savings', builder: (ctx, st) => const SavingsScreen()),
    GoRoute(path: '/loans', builder: (ctx, st) => const LoansScreen()),
    GoRoute(path: '/fines', builder: (ctx, st) => const FinesScreen()),
    GoRoute(path: '/social', builder: (ctx, st) => const SocialScreen()),
    GoRoute(
      path: '/attendance',
      builder: (ctx, st) {
        final idParam = st.uri.queryParameters['meetingId'];
        final meetingId = int.tryParse(idParam ?? '') ?? 0;
        return AttendanceScreen(meetingId: meetingId);
      },
    ),
    GoRoute(path: '/meetings', builder: (ctx, st) => const MeetingsScreen()),
    GoRoute(path: '/accounts', builder: (ctx, st) => AccountsOverviewScreen()),
    GoRoute(path: '/members', builder: (ctx, st) => MemberListScreen()),
    GoRoute(
      path: '/member-profile',
      builder: (ctx, st) => MemberProfileScreen(),
    ),
    GoRoute(path: '/group', builder: (ctx, st) => GroupProfileScreen()),
    GoRoute(path: '/cycles', builder: (ctx, st) => CycleListScreen()),
    GoRoute(path: '/constitution', builder: (ctx, st) => ConstitutionScreen()),
    GoRoute(path: '/reports', builder: (ctx, st) => ReportsScreen()),
    GoRoute(
      path: '/notifications',
      builder: (ctx, st) => NotificationsScreen(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (ctx, st) => const TransactionsScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
