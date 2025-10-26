import 'package:flutter/material.dart';

class LanguageHubScreen extends StatelessWidget {
  const LanguageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF5CD);
    const blue = Color(0xFF0D92F4);

    final items = List.generate(7, (i) => 'ITEM ${i + 1}');

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LISTENING AND SPEAKING',
          style: TextStyle(fontFamily: 'Luckiest Guy', color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: blue, width: 2),
              color: Colors.white,
            ),
            child: ListTile(
              title: Text(
                items[i],
                style: const TextStyle(fontFamily: 'Luckiest Guy', fontSize: 18),
              ),
              trailing: const Icon(Icons.check_circle_outline, color: blue),
              onTap: () {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Open ${items[i]} (mock)')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
