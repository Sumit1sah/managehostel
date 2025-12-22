import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'core/app_lifecycle_observer.dart';
import 'views/washing_queue_view.dart';
import 'views/queue_tracking_view.dart';
import 'views/room_cleaning_view.dart';
import 'views/settings_view.dart';
import 'views/login_view.dart';
import 'views/announcement_view.dart';
import 'views/splash_view.dart';
import 'views/issue_view.dart';
import 'views/dashboard_view.dart';
import 'views/room_availability_view.dart';
import 'views/mess_menu_view.dart';
import 'services/auth_service.dart';
import 'core/storage/hive_storage.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/app_state_provider.dart';
import 'core/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  await HiveStorage.migrate();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLifecycleObserver? _lifecycleObserver;

  @override
  void dispose() {
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Builder(
        builder: (context) {
          if (_lifecycleObserver == null) {
            _lifecycleObserver = AppLifecycleObserver(context.read<AppStateProvider>());
            WidgetsBinding.instance.addObserver(_lifecycleObserver!);
          }
          
          return Consumer2<ThemeProvider, LocaleProvider>(
            builder: (context, themeProvider, localeProvider, _) {
              return MaterialApp(
                title: 'Hostel Management',
                debugShowCheckedModeBanner: false,
                theme: ThemeProvider.lightTheme,
                darkTheme: ThemeProvider.darkTheme,
                themeMode: themeProvider.themeMode,
                locale: localeProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('hi'),
                  Locale('es'),
                  Locale('fr'),
                  Locale('de'),
                  Locale('zh'),
                  Locale('ja'),
                  Locale('ar'),
                  Locale('pt'),
                  Locale('ru'),
                ],
                home: const SplashView(),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const HomeView() : const LoginView();
      },
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  void _loadProfileImage() async {
    final userId = await AuthService().getUserId();
    if (userId != null) {
      final path = HiveStorage.load<String>(HiveStorage.appStateBox, 'profile_image_$userId');
      setState(() => _profileImagePath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [Colors.black, const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)]
              : [const Color(0xFFF5F5F5), const Color(0xFFE8F5E8), const Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profile Avatar
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const SettingsView(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                            _loadProfileImage();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: theme.colorScheme.surface,
                              backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                              child: _profileImagePath == null ? Icon(Icons.person, color: theme.colorScheme.onSurface, size: 36) : null,
                            ),
                          ),
                        ),
                        // Settings Button
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const SettingsView(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                                      ),
                                      child: child
                                    )
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            );
                            _loadProfileImage();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(Icons.settings, color: theme.colorScheme.onSurface, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Welcome Message
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.secondary.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment, color: theme.colorScheme.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Welcome to Your Digital Hostel',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Feature Cards
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(28),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                    children: [
                      _buildModernCard(
                          context,
                          'Room\nCleaning',
                          Icons.cleaning_services_outlined,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RoomCleaningView()))),
                      _buildModernCard(
                          context,
                          'Room\nAvailability',
                          Icons.hotel_outlined,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RoomAvailabilityView()))),
                      _buildModernCard(
                          context,
                          'Mess Menu',
                          Icons.restaurant_outlined,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MessMenuView()))),
                      _buildModernCard(
                          context,
                          'Announcements',
                          Icons.notifications_active_outlined,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AnnouncementView()))),
                      _buildModernCard(
                          context,
                          'Issue',
                          Icons.bug_report_outlined,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const IssueView()))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Icon(icon, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}