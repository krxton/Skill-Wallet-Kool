import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool isRecording = false;
  Duration elapsed = Duration.zero;

  void _toggleRecord() {
    setState(() => isRecording = !isRecording);
  }

  void _finish() {
    Navigator.pushNamed(context, AppRoutes.result, arguments: {
      'timeSpent': elapsed.inSeconds,
      'passed': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('VIDEO PREVIEW'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  onPressed: _toggleRecord,
                  icon: Icon(isRecording ? Icons.stop_circle_outlined : Icons.mic_outlined),
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 48,
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_outline),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finish,
                child: const Text('FINISH'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
