import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../models/language_flow.dart';

class LanguageListScreen extends StatelessWidget {
  const LanguageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as LangListArgs;
    final items = List.generate(7, (i) => 'ITEM ${i + 1}');

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('LISTENING AND SPEAKING (${args.level})'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ListTile(
          tileColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(items[i], style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.check_circle_outline),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.itemIntro,
              arguments: LangItemArgs(i + 1, args.topic, args.level),
            );
          },
        ),
      ),
    );
  }
}
