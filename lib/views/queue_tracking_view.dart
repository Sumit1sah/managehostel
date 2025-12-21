import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/washing_controller.dart';

class QueueTrackingView extends StatelessWidget {
  final String studentId = 'S001';

  const QueueTrackingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Queue Status')),
      body: ChangeNotifierProvider(
        create: (_) => WashingController(),
        child: Consumer<WashingController>(
          builder: (context, controller, _) {
            final myQueue = controller.getStudentQueue(studentId);
            if (myQueue == null) {
              return const Center(child: Text('You are not in any queue'));
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Machine: ${myQueue.machineId}', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  Text('Position: ${myQueue.position}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('Estimated Wait: ${myQueue.estimatedWaitMinutes} min', style: const TextStyle(fontSize: 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
