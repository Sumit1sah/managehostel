import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/washing_controller.dart';
import '../models/washing_machine.dart';

class WashingQueueView extends StatelessWidget {
  final String studentId = 'S001';
  final String studentName = 'John Doe';

  const WashingQueueView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Washing Machine Queue')),
      body: ChangeNotifierProvider(
        create: (_) => WashingController(),
        child: Consumer<WashingController>(
          builder: (context, controller, _) {
            final machines = controller.machines;
            return ListView.builder(
              itemCount: machines.length,
              itemBuilder: (context, index) {
                final machine = machines[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('${machine.id} - ${machine.location}'),
                    subtitle: Text(_getStatusText(machine)),
                    trailing: _buildActionButton(context, controller, machine),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getStatusText(WashingMachine machine) {
    switch (machine.status) {
      case MachineStatus.available:
        return 'Available';
      case MachineStatus.inUse:
        final remaining = 45 - DateTime.now().difference(machine.currentStartTime!).inMinutes;
        return 'In Use - $remaining min left';
      case MachineStatus.maintenance:
        return 'Under Maintenance';
    }
  }

  Widget _buildActionButton(BuildContext context, WashingController controller, WashingMachine machine) {
    final queue = controller.getQueueForMachine(machine.id);
    if (machine.status == MachineStatus.available && queue.isEmpty) {
      return ElevatedButton(
        onPressed: () => controller.joinQueue(studentId, studentName, machine.id),
        child: const Text('Start'),
      );
    }
    return Text('Queue: ${queue.length}');
  }
}
