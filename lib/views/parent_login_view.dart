import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';
import 'parent_dashboard_view.dart';

class ParentLoginView extends StatefulWidget {
  const ParentLoginView({Key? key}) : super(key: key);

  @override
  State<ParentLoginView> createState() => _ParentLoginViewState();
}

class _ParentLoginViewState extends State<ParentLoginView> {
  final _parentIdController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    final parents = HiveStorage.loadList(HiveStorage.appStateBox, 'parents');
    final parent = parents.firstWhere(
      (p) => p['parentId'] == _parentIdController.text &&
             p['studentId'] == _studentIdController.text &&
             p['password'] == _passwordController.text,
      orElse: () => {},
    );

    if (parent.isNotEmpty) {
      // Clear any existing student/warden session first
      HiveStorage.save(HiveStorage.appStateBox, 'userId', null);
      HiveStorage.save(HiveStorage.appStateBox, 'userRole', null);
      
      // Save parent session
      HiveStorage.save(HiveStorage.appStateBox, 'current_user_role', 'parent');
      HiveStorage.save(HiveStorage.appStateBox, 'current_parent_id', _parentIdController.text);
      HiveStorage.save(HiveStorage.appStateBox, 'current_student_id', _studentIdController.text);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentDashboardView(
            parentId: _parentIdController.text,
            studentId: _studentIdController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            TextField(
              controller: _parentIdController,
              decoration: const InputDecoration(
                labelText: 'Parent ID',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
