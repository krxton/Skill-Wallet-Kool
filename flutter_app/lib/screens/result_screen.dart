import 'package:flutter/material.dart';
import '../theme/palette.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)!.settings.arguments as Map?) ?? {};
    final Duration time = (args['time'] as Duration?) ?? Duration.zero;

    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(time.inMinutes % 60), ss = two(time.inSeconds % 60);

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        leading: const BackButton(color: Colors.black87),
        elevation: 0,
        title: const Text('RESULT'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Palette.greyCard,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_fill, size: 72),
            ),
            const SizedBox(height: 18),
            const Text('TIME SPEND', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('$mm:$ss', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              iconSize: 64,
              color: Palette.green,
              onPressed: () => Navigator.pop(context, {'ok': true}),
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
    );
  }
}
