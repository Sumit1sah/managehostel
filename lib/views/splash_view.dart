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

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize app state provider
    await context.read<AppStateProvider>().init();
    
    // Check for parent session first
    final userRole = HiveStorage.load<String>(HiveStorage.appStateBox, 'current_user_role');
    
    if (userRole == 'parent') {
      final parentId = HiveStorage.load<String>(HiveStorage.appStateBox, 'current_parent_id');
      final studentId = HiveStorage.load<String>(HiveStorage.appStateBox, 'current_student_id');
      
      if (parentId != null && studentId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ParentDashboardView(
              parentId: parentId,
              studentId: studentId,
            ),
          ),
        );
        return;
      }
    }
    
    // Check authentication for student/warden
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    // Navigate after state restoration
    if (mounted) {
      Widget destination;
      if (isLoggedIn) {
        final isWarden = await authService.isWarden();
        destination = isWarden ? const WardenDashboardView() : const HomeView();
      } else {
        destination = const LoginView();
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, const Color(0xFF1A1A1A)]
                : [const Color(0xFFF5F5F5), const Color(0xFFE8F5E8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apartment,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Hostel Management',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}