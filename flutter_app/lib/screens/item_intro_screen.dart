import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ItemIntroScreen extends StatelessWidget {
  const ItemIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('Tale of Peter Rabbit & Benjamin Bunny'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.record),
                child: const Text('START'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
