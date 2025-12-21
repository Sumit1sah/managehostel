import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../core/storage/hive_storage.dart';

class DataCenterView extends StatefulWidget {
  const DataCenterView({Key? key}) : super(key: key);

  @override
  State<DataCenterView> createState() => _DataCenterViewState();
}

class _DataCenterViewState extends State<DataCenterView> {
  List<Map<String, dynamic>> cleaningData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scheduleAutoReset();
  }

  void _scheduleAutoReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);
    
    Timer(timeUntilMidnight, () {
      _resetDailyData();
      Timer.periodic(const Duration(days: 1), (timer) => _resetDailyData());
    });
  }

  void _resetDailyData() async {
    final cleaningsData = HiveStorage.loadList(HiveStorage.cleaningsBox, 'cleanings_data');
    if (cleaningsData.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String csvContent = 'Room,Status,Date,Time\n';
      for (var item in cleaningsData) {
        csvContent += '${item['roomNumber']},${item['status']},${item['scheduledDate']},${item['scheduledTime'] ?? 'N/A'}\n';
      }
      await HiveStorage.save(HiveStorage.appStateBox, 'daily_backup_$timestamp', csvContent);
    }
    
    await HiveStorage.clearBox(HiveStorage.cleaningsBox);
    _loadData();
  }

  void _loadData() {
    final data = HiveStorage.loadList(HiveStorage.cleaningsBox, 'cleanings_data');
    setState(() => cleaningData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('Data Center', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C2033),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F111A), Color(0xFF161A2B)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildDownloadSection(),
            Expanded(child: _buildDataList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: Color(0xFF64FFDA), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Room Cleaning Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${cleaningData.length} entries', style: const TextStyle(color: Color(0xFFC9CED6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2033).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _downloadExcel,
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text('Download Excel', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA).withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadExcel() async {
    if (cleaningData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // Group data by room and date
    Map<String, List<Map<String, dynamic>>> roomData = {};
    for (var item in cleaningData) {
      String room = item['roomNumber'].toString();
      if (!roomData.containsKey(room)) {
        roomData[room] = [];
      }
      roomData[room]!.add(item);
    }

    // Create Excel content (CSV format)
    String csvContent = 'Room Number,Date,Status,Scheduled Time,Completed Time,Notes\n';
    
    for (String room in roomData.keys) {
      // Sort by date for each room
      roomData[room]!.sort((a, b) => DateTime.parse(a['scheduledDate']).compareTo(DateTime.parse(b['scheduledDate'])));
      
      for (var cleaning in roomData[room]!) {
        csvContent += '${cleaning['roomNumber']},';
        csvContent += '${cleaning['scheduledDate']},';
        csvContent += '${cleaning['status']},';
        csvContent += '${cleaning['scheduledTime'] ?? 'N/A'},';
        csvContent += '${cleaning['completedDate'] ?? 'N/A'},';
        csvContent += '${cleaning['notes'] ?? 'N/A'}\n';
      }
    }

    try {
      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory!.path}/room_cleaning_$timestamp.csv');
      
      // Write CSV content to file
      await file.writeAsString(csvContent);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel downloaded: ${file.path}')),
      );
    } catch (e) {
      // Fallback to internal storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await HiveStorage.save(HiveStorage.appStateBox, 'cleaning_export_$timestamp', csvContent);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel saved to app storage (${roomData.keys.length} rooms)')),
      );
    }
  }

  Widget _buildDataList() {
    if (cleaningData.isEmpty) {
      return const Center(
        child: Text('No cleaning data available', style: TextStyle(color: Color(0xFFC9CED6))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cleaningData.length,
      itemBuilder: (context, index) {
        final item = cleaningData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2033).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item['status'] == 'completed' ? const Color(0xFF64FFDA) : const Color(0xFFFFE082),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room ${item['roomNumber']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Status: ${item['status']}', style: const TextStyle(color: Color(0xFFC9CED6), fontSize: 12)),
                    Text('Date: ${item['scheduledDate']}', style: const TextStyle(color: Color(0xFFC9CED6), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}