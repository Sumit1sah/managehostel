import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactView extends StatelessWidget {
  const ContactView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContactCard('Warden', 'Mr. Sharma', '+91 9876543210', Icons.person),
          _buildContactCard('Security', '24/7 Help Desk', '+91 9876543211', Icons.security),
          _buildContactCard('Maintenance', 'Repair Services', '+91 9876543212', Icons.build),
          _buildContactCard('Mess Manager', 'Food Services', '+91 9876543213', Icons.restaurant),
          _buildContactCard('Medical', 'Emergency', '+91 9876543214', Icons.local_hospital),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String name, String phone, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$name\n$phone'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.green),
          onPressed: () => _makeCall(phone),
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
