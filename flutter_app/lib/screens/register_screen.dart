import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final List<String> children = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('REGISTER', style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('ADDITIONAL INFORMATION', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              SWKTextField(hint: 'Name & Surname (Children)', controller: nameCtrl),
              const SizedBox(height: 12),
              SWKTextField(hint: 'Birthday : DD/MM/YYYY', controller: dobCtrl, keyboardType: TextInputType.datetime),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: children.map((c) => Chip(label: Text(c))).toList()),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() => children.add(nameCtrl.text));
                      nameCtrl.clear();
                      dobCtrl.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 36),
                ),
              ),
              const Spacer(),
              PrimaryButton(label: 'OK', onPressed: () {/* TODO: submit */}, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}