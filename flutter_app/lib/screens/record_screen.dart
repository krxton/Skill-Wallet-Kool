import 'dart:async';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/palette.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool recording = false;
  Duration elapsed = Duration.zero;
  Timer? _t;

  void _toggle() {
    if (recording) {
      _t?.cancel();
      setState(() => recording = false);
    } else {
      setState(() => recording = true);
      _t = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => elapsed += const Duration(seconds: 1));
      });
    }
  }

  Future<void> _finish() async {
    _t?.cancel();
    // รอหน้าผลลัพธ์เสร็จ แล้วค่อย pop กลับหน้าก่อนหน้า
    await Navigator.pushNamed(context, AppRoutes.result, arguments: {
      'time': elapsed,
      'index': 1,
    });
    if (!mounted) return;
    Navigator.pop(context, {'ok': true});
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(elapsed.inMinutes % 60), ss = two(elapsed.inSeconds % 60);

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        leading: const BackButton(color: Colors.black87),
        elevation: 0,
        title: const Text('RECORD'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: Palette.greyCard,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('VIDEO PREVIEW'),
            ),
            const SizedBox(height: 24),
            Text('$mm:$ss', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 56,
                  color: recording ? Palette.red : Colors.black87,
                  onPressed: _toggle,
                  icon: Icon(recording ? Icons.stop_circle_outlined : Icons.mic_rounded),
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 56,
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_outline),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Palette.green),
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
