import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_fields.dart';
import '../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final List<Map<String, String>> children = []; // [{name:'', dob:''}, ...]

  final _dobRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$'); // DD/MM/YYYY

  void _addChild() {
    final name = nameCtrl.text.trim();
    final dob = dobCtrl.text.trim();

    if (name.isEmpty || !_dobRegex.hasMatch(dob)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกชื่อ และวันเกิดรูปแบบ DD/MM/YYYY')),
      );
      return;
    }

    setState(() {
      children.add({'name': name, 'dob': dob});
      nameCtrl.clear();
      dobCtrl.clear();
    });
  }

  Future<void> _submit() async {
    // ถ้า user ยังไม่ได้กด + แต่กรอกอยู่ ให้เพิ่มให้ด้วย
    if (nameCtrl.text.trim().isNotEmpty && _dobRegex.hasMatch(dobCtrl.text.trim())) {
      _addChild();
    }

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มข้อมูลเด็กอย่างน้อย 1 คน')),
      );
      return;
    }

    // บันทึกลงเครื่อง
    final prefs = await SharedPreferences.getInstance();
    // เก็บเป็น list ของ string "name|dob"
    await prefs.setStringList(
      'swk_children',
      children.map((c) => '${c['name']}|${c['dob']}').toList(),
    );

    // ไปหน้า Login (หรือจะไป Home ก็เปลี่ยนเป็น AppRoutes.home)
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

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
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  onPressed: _addChild,
                  icon: const Icon(Icons.add_circle_outline, size: 36),
                ),
              ),

              // แสดงรายการเด็กที่เพิ่มแล้ว
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: children
                    .asMap()
                    .entries
                    .map((e) => Chip(
                          label: Text('${e.value['name']} (${e.value['dob']})'),
                          onDeleted: () => setState(() => children.removeAt(e.key)),
                        ))
                    .toList(),
              ),

              const Spacer(),
              PrimaryButton(
                label: 'OK',
                onPressed: _submit, 
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
