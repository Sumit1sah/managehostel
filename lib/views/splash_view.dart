import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/app_state_provider.dart';
import '../core/storage/hive_storage.dart';
import '../services/auth_service.dart';
import 'login_view.dart';
import 'warden_dashboard_view.dart';
import 'parent_dashboard_view.dart';
import '../main.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      context.read<AppStateProvider>().init(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    final userRole = HiveStorage.load<String>(
        HiveStorage.appStateBox, 'current_user_role');

    if (userRole == 'parent') {
      final parentId = HiveStorage.load<String>(
          HiveStorage.appStateBox, 'current_parent_id');
      final studentId = HiveStorage.load<String>(
          HiveStorage.appStateBox, 'current_student_id');
      if (parentId != null && studentId != null && mounted) {
        _navigate(ParentDashboardView(
            parentId: parentId, studentId: studentId));
        return;
      }
    }

    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      final isWarden = await authService.isWarden();
      _navigate(isWarden ? const WardenDashboardView() : const HomeView());
    } else {
      _navigate(const LoginView());
    }
  }

  void _navigate(Widget dest) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => dest,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF1E2A3A), const Color(0xFF1A1A1A)]
                : [const Color(0xFF1565C0), const Color(0xFF1976D2), const Color(0xFF42A5F5)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // icon card — same style as HomeView cards
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.apartment,
                      size: 72,
                      color: isDark ? primary : Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // app name
                  Text(
                    'KIIT-HOSTEL',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      fontSize: 30,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // subtitle
                  Text(
                    'Smart Hostel Management',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 56),

                  // loader — same primary color as rest of app
                  CircularProgressIndicator(
                    color: isDark ? primary : Colors.white,
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
