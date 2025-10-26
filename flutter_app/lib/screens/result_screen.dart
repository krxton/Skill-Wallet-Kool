import 'package:flutter/material.dart';
import '../models/language_flow.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as LangResultArgs;

    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(args.time.inMinutes % 60);
    final ss = two(args.time.inSeconds % 60);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('ITEM ${args.index}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_fill, size: 72),
            ),
            const SizedBox(height: 18),
            const Icon(Icons.play_circle_outline, size: 28),
            const SizedBox(height: 12),
            const Text('TIME SPEND', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('$mm:$ss', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              iconSize: 64,
              color: Colors.green,
              onPressed: () {
                Navigator.pop(context, LangResultPayload(true, args.time));
              },
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
    );
  }
}
