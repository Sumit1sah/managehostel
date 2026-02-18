import 'package:flutter/material.dart';
import '../core/storage/hive_storage.dart';

class HolidayListView extends StatefulWidget {
  const HolidayListView({Key? key}) : super(key: key);

  @override
  State<HolidayListView> createState() => _HolidayListViewState();
}

class _HolidayListViewState extends State<HolidayListView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _holidays = [];
  List<Map<String, dynamic>> _todayHolidays = [];
  List<Map<String, dynamic>> _upcomingHolidays = [];
  List<Map<String, dynamic>> _recentHolidays = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _loadHolidays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadHolidays() {
    // Force update to latest holiday list
    _holidays = [
      {'name': 'Basanta Panchami', 'date': '2026-01-23', 'type': 'Festival'},
      {'name': 'Republic Day', 'date': '2026-01-26', 'type': 'National'},
      {'name': 'Holi', 'date': '2026-03-04', 'type': 'Festival'},
      {'name': 'Id-Ul-Fitr', 'date': '2026-03-21', 'type': 'Religious'},
      {'name': 'Ram Navami', 'date': '2026-03-27', 'type': 'Religious'},
      {'name': 'Utkal Divas', 'date': '2026-04-01', 'type': 'Regional'},
      {'name': 'Good Friday', 'date': '2026-04-03', 'type': 'Religious'},
      {'name': 'Maha Vishubha Sankranti', 'date': '2026-04-14', 'type': 'Festival'},
      {'name': 'Id-Ul-Juha', 'date': '2026-05-27', 'type': 'Religious'},
      {'name': 'Raja Sankranti', 'date': '2026-06-15', 'type': 'Festival'},
      {'name': 'Muharram', 'date': '2026-06-26', 'type': 'Religious'},
      {'name': 'Rath Yatra', 'date': '2026-07-16', 'type': 'Festival'},
      {'name': 'Independence Day', 'date': '2026-08-15', 'type': 'National'},
      {'name': 'Birthday of Prophet Mohammad', 'date': '2026-08-26', 'type': 'Religious'},
      {'name': 'Janmashtami', 'date': '2026-09-04', 'type': 'Religious'},
      {'name': 'Ganesh Puja', 'date': '2026-09-14', 'type': 'Festival'},
      {'name': 'Nuakhai', 'date': '2026-09-15', 'type': 'Festival'},
      {'name': 'Gandhi Jayanti', 'date': '2026-10-02', 'type': 'National'},
      {'name': 'Durga Puja', 'date': '2026-10-17', 'type': 'Festival'},
      {'name': 'Kumar Purnima', 'date': '2026-10-25', 'type': 'Festival'},
      {'name': 'Kalipuja', 'date': '2026-11-07', 'type': 'Festival'},
      {'name': 'Kartika Purnima', 'date': '2026-11-24', 'type': 'Festival'},
      {'name': 'Guru Nanak Birthday', 'date': '2026-11-24', 'type': 'Religious'},
      {'name': 'Christmas', 'date': '2026-12-25', 'type': 'Religious'},
    ];
    HiveStorage.saveList(HiveStorage.appStateBox, 'holidays', _holidays);
    _categorizeHolidays();
  }

  void _categorizeHolidays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _todayHolidays = [];
    _upcomingHolidays = [];
    _recentHolidays = [];
    
    for (var holiday in _holidays) {
      final date = DateTime.parse(holiday['date']);
      final holidayDate = DateTime(date.year, date.month, date.day);
      
      if (holidayDate.isAtSameMomentAs(today)) {
        _todayHolidays.add(holiday);
      } else if (holidayDate.isAfter(today)) {
        _upcomingHolidays.add(holiday);
      } else {
        _recentHolidays.add(holiday);
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday List'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Recent (${_recentHolidays.length})'),
            Tab(text: 'Upcoming (${_upcomingHolidays.length})'),
            Tab(text: 'Today (${_todayHolidays.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHolidayList(_recentHolidays, Colors.grey),
          _buildHolidayList(_upcomingHolidays, Colors.green),
          _buildHolidayList(_todayHolidays, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHolidayList(List<Map<String, dynamic>> holidays, Color color) {
    if (holidays.isEmpty) {
      return Center(
        child: Text(
          'No holidays',
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: holidays.length,
      itemBuilder: (context, index) => _buildHolidayCard(holidays[index], color),
    );
  }

  Widget _buildHolidayCard(Map<String, dynamic> holiday, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            holiday['type'] == 'National' ? Icons.flag : 
            holiday['type'] == 'Festival' ? Icons.celebration : Icons.church,
            color: Colors.white,
          ),
        ),
        title: Text(holiday['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_formatDate(holiday['date'])} • ${holiday['type']}'),
      ),
    );
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    return '${d.day}/${d.month}/${d.year}';
  }
}
