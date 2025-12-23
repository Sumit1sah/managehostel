import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../core/storage/hive_storage.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/locale_provider.dart';
import 'login_view.dart';
import 'data_center_view.dart';
import 'complaint_management_view.dart';
import 'issue_management_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String? _profileImagePath;
  String _name = 'John Doe';
  String _email = 'john.doe@hostel.com';
  String _phone = '+91 9876543210';
  String _studentId = 'S001';
  String _roomNumber = '101';
  int _roomsPerFloor = 10;
  int _floors = 2;
  bool _isWarden = false;

  @override
  void initState() {
    super.initState();
    _checkWardenStatus();
    _loadProfileData();
    _autoCleanupOldData();
  }

  void _checkWardenStatus() async {
    final isWarden = await AuthService().isWarden();
    setState(() {
      _isWarden = isWarden;
    });
  }

  Future<void> _loadUserBasedProfile() async {
    final userId = await AuthService().getUserId();
    if (userId != null) {
      // First check if user exists in authorized_users (created by warden)
      final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
      final userData = users.firstWhere(
        (user) => user['userId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      
      setState(() {
        if (userData.isNotEmpty) {
          // Use data from warden-created account
          _name = userData['name'] ?? userId.toUpperCase();
          _phone = userData['phone'] ?? '+91 9876543210';
          _studentId = userData['userId'] ?? userId.toUpperCase();
          _roomNumber = userData['room'] ?? '101';
          _email = '$userId@kiit.ac.in';
        } else {
          // Fallback to stored profile data
          _name = HiveStorage.load<String>(HiveStorage.appStateBox, 'profile_name_$userId') ?? userId.toUpperCase();
          _email = HiveStorage.load<String>(HiveStorage.appStateBox, 'profile_email_$userId') ?? '$userId@kiit.ac.in';
          _phone = HiveStorage.load<String>(HiveStorage.appStateBox, 'profile_phone_$userId') ?? '+91 9876543210';
          _studentId = HiveStorage.load<String>(HiveStorage.appStateBox, 'student_id_$userId') ?? userId.toUpperCase();
          _roomNumber = HiveStorage.load<String>(HiveStorage.appStateBox, 'room_number_$userId') ?? '101';
        }
        _profileImagePath = HiveStorage.load<String>(HiveStorage.appStateBox, 'profile_image_$userId');
      });
    }
  }

  void _autoCleanupOldData() {
    Future.delayed(const Duration(seconds: 2), () async {
      await HiveStorage.clearOldCleaningData();
    });
  }

  Future<void> _loadProfileData() async {
    await HiveStorage.clearOldCleaningData();
    await _loadUserBasedProfile();
    final roomsPerFloor = HiveStorage.load<int>(HiveStorage.appStateBox, 'rooms_per_floor');
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors');
    setState(() {
      _roomsPerFloor = roomsPerFloor ?? 10;
      _floors = floors ?? 2;
    });
  }

  Future<void> _clearOldData() async {
    // Export to Excel before clearing
    await _exportToExcel();
    
    // Clear data older than 24 hours
    final cleaningsData = HiveStorage.loadList(HiveStorage.cleaningsBox, 'cleanings_data');
    final now = DateTime.now();
    
    final recentData = cleaningsData.where((cleaning) {
      final scheduledDate = DateTime.parse(cleaning['scheduledDate']);
      return now.difference(scheduledDate).inHours < 24;
    }).toList();
    
    await HiveStorage.saveList(HiveStorage.cleaningsBox, 'cleanings_data', recentData);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data exported and ${cleaningsData.length - recentData.length} old records cleared')),
    );
  }
  
  Future<void> _exportToExcel() async {
    final cleaningsData = HiveStorage.loadList(HiveStorage.cleaningsBox, 'cleanings_data');
    if (cleaningsData.isEmpty) return;
    
    // Create CSV content
    String csvContent = 'Room,Status,Scheduled Date,Completed Date\n';
    for (var cleaning in cleaningsData) {
      csvContent += '${cleaning['roomNumber']},${cleaning['status']},${cleaning['scheduledDate']},${cleaning['completedDate'] ?? 'N/A'}\n';
    }
    
    // Save to device storage (simplified - in real app would use file picker)
    await HiveStorage.save(HiveStorage.appStateBox, 'exported_csv_${DateTime.now().millisecondsSinceEpoch}', csvContent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.background, theme.colorScheme.surface],
          ),
        ),
        child: ListView(
        children: [
          _buildProfileHeader(),
          const Divider(thickness: 2),
          _buildSection('Account', [
            _buildTile(Icons.badge, 'Student ID', '$_studentId - Room $_roomNumber', () {}),
            if (!_isWarden) _buildTile(Icons.report_problem, 'Submit Issue', 'Report issues or problems', _showIssueForm),
            _buildTile(Icons.lock, 'Change Password', 'Update password', _showChangePassword),
          ]),
          if (_isWarden) _buildSection('Data Management', [
            _buildTile(Icons.data_usage, 'Data Center', 'View cleaning records', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataCenterView()))),
            _buildTile(Icons.storage, 'Clear Old Data', 'Remove 24+ hour old records', _clearOldData),
            _buildTile(Icons.feedback, 'Student Issues', 'View student issues', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueManagementView()))),
          ]),
          _buildSection('Preferences', [
            _buildThemeTile(),
            if (_isWarden) _buildTile(Icons.meeting_room, 'Rooms Per Floor', '$_roomsPerFloor rooms', _showRoomsPerFloorDialog),
            if (_isWarden) _buildTile(Icons.layers, 'Number of Floors', '$_floors floors', _showFloorsDialog),
          ]),
          _buildSection('App', [
            _buildTile(Icons.logout, 'Logout', 'Sign out', () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            }),
          ]),
        ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                  child: _profileImagePath == null 
                      ? Text(
                          _getInitials(_name),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$_studentId • Room $_roomNumber', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(_email, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      onTap: onTap,
    );
  }

  Widget _buildThemeTile() {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    String subtitle;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        subtitle = 'Light mode';
        break;
      case ThemeMode.dark:
        subtitle = 'Dark mode';
        break;
      default:
        subtitle = 'System default';
    }
    
    return ListTile(
      leading: Icon(Icons.dark_mode, color: theme.colorScheme.primary),
      title: const Text('Theme'),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      onTap: _showThemeDialog,
    );
  }

  void _showThemeDialog() {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Follow device theme'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final userId = await AuthService().getUserId();
      if (userId != null) {
        await HiveStorage.save(HiveStorage.appStateBox, 'profile_image_$userId', pickedFile.path);
        setState(() => _profileImagePath = pickedFile.path);
      }
    }
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final studentIdController = TextEditingController(text: _studentId);
    final roomController = TextEditingController(text: _roomNumber);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.room)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final userId = await AuthService().getUserId();
              if (userId != null) {
                await HiveStorage.save(HiveStorage.appStateBox, 'profile_name_$userId', nameController.text);
                await HiveStorage.save(HiveStorage.appStateBox, 'profile_email_$userId', emailController.text);
                await HiveStorage.save(HiveStorage.appStateBox, 'profile_phone_$userId', phoneController.text);
                await HiveStorage.save(HiveStorage.appStateBox, 'student_id_$userId', studentIdController.text);
                await HiveStorage.save(HiveStorage.appStateBox, 'room_number_$userId', roomController.text);
              }
              
              setState(() {
                _name = nameController.text;
                _email = emailController.text;
                _phone = phoneController.text;
                _studentId = studentIdController.text;
                _roomNumber = roomController.text;
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeUserId() {
    final newUserIdController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newUserIdController,
              decoration: const InputDecoration(labelText: 'New User ID', prefixIcon: Icon(Icons.account_circle)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newUserIdController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter new User ID')),
                );
                return;
              }
              
              // Logout and require re-login with new credentials
              await AuthService().logout();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login with your new User ID')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old Password', prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              if (newPasswordController.text.length < 6) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              
              final success = await AuthService().changePassword(oldPasswordController.text, newPasswordController.text);
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update password')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    final packageName = 'com.hostel.managehostel';
    final playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    final appStoreUrl = Uri.parse('https://apps.apple.com/app/id123456789');
    
    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(playStoreUrl)) {
          await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(appStoreUrl)) {
          await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store')),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    await Share.share('Check out Hostel Management app: https://play.google.com/store/apps/details?id=com.hostel.managehostel');
  }

  void _showRoomsPerFloorDialog() {
    final controller = TextEditingController(text: _roomsPerFloor.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rooms Per Floor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of rooms',
                hintText: 'Enter 1-50',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Warning: Changing room count will update all room allocations in the system.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0 && value <= 50) {
                await HiveStorage.save(HiveStorage.appStateBox, 'rooms_per_floor', value);
                await _updateRoomAllocations(value);
                setState(() => _roomsPerFloor = value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rooms per floor updated to $value and allocations recalculated')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number (1-50)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoomAllocations(int newRoomsPerFloor) async {
    final users = HiveStorage.loadList(HiveStorage.appStateBox, 'authorized_users');
    final Map<String, List<String>> newRoomStatus = {};
    
    // Update room numbers for all students based on new room count
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final floor = int.parse(user['floor'] ?? '0');
      final oldRoom = int.parse(user['room'] ?? '01');
      
      // Calculate new room number based on sequential system
      final startRoom = floor == 0 ? 1 : (floor * newRoomsPerFloor) + 1;
      final maxRoom = floor == 0 ? newRoomsPerFloor : ((floor + 1) * newRoomsPerFloor);
      
      // Reassign room within new range
      int newRoom = startRoom + (oldRoom - 1) % newRoomsPerFloor;
      if (newRoom > maxRoom) newRoom = startRoom;
      
      users[i]['room'] = newRoom.toString().padLeft(2, '0');
      
      // Update room bed status
      final roomNumber = '${floor}A-${newRoom.toString().padLeft(2, '0')}';
      if (!newRoomStatus.containsKey(roomNumber)) {
        newRoomStatus[roomNumber] = ['available', 'available'];
      }
      
      // Occupy first available bed
      for (int j = 0; j < newRoomStatus[roomNumber]!.length; j++) {
        if (newRoomStatus[roomNumber]![j] == 'available') {
          newRoomStatus[roomNumber]![j] = 'occupied';
          break;
        }
      }
    }
    
    // Save updated users and room status
    HiveStorage.saveList(HiveStorage.appStateBox, 'authorized_users', users);
    HiveStorage.save(HiveStorage.appStateBox, 'global_room_bed_status', newRoomStatus);
  }

  void _showRoomSwapRequest() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    final floors = HiveStorage.load<int>(HiveStorage.appStateBox, 'floors', defaultValue: 2) ?? 2;
    final floorOptions = List.generate(floors, (index) => index.toString());
    
    String? selectedFloor;
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Room Swap Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Room: Floor ${_roomNumber.split('-')[0]} - Room ${_roomNumber.split('-')[1]}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                decoration: const InputDecoration(
                  labelText: 'Preferred Floor',
                  prefixIcon: Icon(Icons.layers),
                ),
                items: floorOptions.map((floor) => DropdownMenuItem(
                  value: floor,
                  child: Text('Floor $floor'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedFloor = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for swap',
                  hintText: 'Please explain why you need a room change...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedFloor != null && reasonController.text.isNotEmpty) {
                  _submitRoomSwapRequest(userId, selectedFloor!, reasonController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRoomSwapRequest(String userId, String preferredFloor, String reason) {
    final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    final request = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': userId,
      'studentName': _name,
      'currentFloor': _roomNumber.split('-')[0],
      'currentRoom': _roomNumber.split('-')[1],
      'preferredFloor': preferredFloor,
      'reason': reason,
      'status': 'pending',
      'requestDate': DateTime.now().toIso8601String(),
    };
    
    requests.add(request);
    HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', requests);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room swap request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRoomSwapRequests() {
    final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    final pendingRequests = requests.where((req) => req['status'] == 'pending').toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room Swap Requests (${pendingRequests.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: pendingRequests.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['studentName'] ?? request['studentId'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('ID: ${request['studentId']}'),
                            Text('Current: Floor ${request['currentFloor']} - Room ${request['currentRoom']}'),
                            Text('Wants: Floor ${request['preferredFloor']}'),
                            const SizedBox(height: 8),
                            Text('Reason: ${request['reason']}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _handleSwapRequest(request['id'], 'rejected'),
                                  child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _handleSwapRequest(request['id'], 'approved'),
                                  child: const Text('Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleSwapRequest(String requestId, String status) {
    final requests = HiveStorage.loadList(HiveStorage.appStateBox, 'room_swap_requests');
    
    for (int i = 0; i < requests.length; i++) {
      if (requests[i]['id'] == requestId) {
        requests[i]['status'] = status;
        requests[i]['processedDate'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    HiveStorage.saveList(HiveStorage.appStateBox, 'room_swap_requests', requests);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $status successfully!'),
        backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showFloorsDialog() {
    final controller = TextEditingController(text: _floors.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Number of Floors'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of floors',
            hintText: 'Enter 1-10',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0 && value <= 10) {
                await HiveStorage.save(HiveStorage.appStateBox, 'floors', value);
                setState(() => _floors = value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Number of floors set to $value')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number (1-10)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showIssueForm() async {
    final userId = await AuthService().getUserId();
    if (userId == null) return;
    
    String? selectedCategory;
    final categories = ['Maintenance', 'Cleanliness', 'Noise', 'Security', 'Facilities', 'Other'];
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please describe the issue in detail...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategory != null && descriptionController.text.isNotEmpty) {
                  _submitIssue(userId, selectedCategory!, descriptionController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitIssue(String userId, String category, String description) {
    final issues = HiveStorage.loadList(HiveStorage.appStateBox, 'issues');
    
    final issue = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'studentId': userId,
      'studentName': _name,
      'room': '$_studentId - Room $_roomNumber',
      'category': category,
      'description': description,
      'status': 'pending',
      'submitDate': DateTime.now().toIso8601String(),
    };
    
    issues.add(issue);
    HiveStorage.saveList(HiveStorage.appStateBox, 'issues', issues);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showComplaints() {
    final complaints = HiveStorage.loadList(HiveStorage.appStateBox, 'complaints');
    final pendingComplaints = complaints.where((comp) => comp['status'] == 'pending').toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Student Complaints (${pendingComplaints.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: pendingComplaints.isEmpty
              ? const Center(child: Text('No pending complaints'))
              : ListView.builder(
                  itemCount: pendingComplaints.length,
                  itemBuilder: (context, index) {
                    final complaint = pendingComplaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                complaint['category'],
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              complaint['studentName'] ?? complaint['studentId'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Room: ${complaint['room']}'),
                            const SizedBox(height: 8),
                            Text(complaint['description']),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _resolveComplaint(complaint['id']),
                                  child: const Text('Mark Resolved'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resolveComplaint(String complaintId) {
    final complaints = HiveStorage.loadList(HiveStorage.appStateBox, 'complaints');
    
    for (int i = 0; i < complaints.length; i++) {
      if (complaints[i]['id'] == complaintId) {
        complaints[i]['status'] = 'resolved';
        complaints[i]['resolvedDate'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    HiveStorage.saveList(HiveStorage.appStateBox, 'complaints', complaints);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint marked as resolved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }
}