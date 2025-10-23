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
  final _dobRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$'); // DD/MM/YYYY

  // controllers ต่อคน: index เดียวกันคือชุดเดียวกัน
  final List<TextEditingController> _nameCtrls = [];
  final List<TextEditingController> _dobCtrls = [];

  @override
  void initState() {
    super.initState();
    _addRow(); // มีอย่างน้อย 1 ชุดให้กรอก
  }

  void _addRow() {
    setState(() {
      _nameCtrls.add(TextEditingController());
      _dobCtrls.add(TextEditingController());
    });
  }

  void _removeRow(int i) {
    if (_nameCtrls.length == 1) return; // อย่างน้อย 1 แถว
    setState(() {
      _nameCtrls[i].dispose();
      _dobCtrls[i].dispose();
      _nameCtrls.removeAt(i);
      _dobCtrls.removeAt(i);
    });
  }

  Future<void> _submit() async {
    // รวบรวมรายการที่กรอกครบ
    final entries = <String>[];
    for (var i = 0; i < _nameCtrls.length; i++) {
      final n = _nameCtrls[i].text.trim();
      final d = _dobCtrls[i].text.trim();
      if (n.isNotEmpty && _dobRegex.hasMatch(d)) {
        entries.add('$n|$d');
      }
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกชื่อและวันเกิดอย่างน้อย 1 คน (รูปแบบ DD/MM/YYYY)')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('swk_children', entries);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login); // หรือ AppRoutes.home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('REGISTER',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('ADDITIONAL INFORMATION', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                // ====== รายการแถว (ชื่อ+วันเกิด) ต่อคน ======
                Column(
                  children: List.generate(_nameCtrls.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChildRow(
                        index: i,
                        nameCtrl: _nameCtrls[i],
                        dobCtrl: _dobCtrls[i],
                        onRemove: _nameCtrls.length > 1 ? () => _removeRow(i) : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),

                // ปุ่ม +
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add_circle_outline, size: 36),
                  ),
                ),

                const SizedBox(height: 20),

                PrimaryButton(label: 'OK', onPressed: _submit, color: const Color(0xFF72BF78)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// การ์ดเล็ก ๆ สำหรับ 1 คน: ชื่อ + วันเกิด + ปุ่มลบ
class _ChildRow extends StatelessWidget {
  final int index;
  final TextEditingController nameCtrl;
  final TextEditingController dobCtrl;
  final VoidCallback? onRemove;

  const _ChildRow({
    required this.index,
    required this.nameCtrl,
    required this.dobCtrl,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ช่องกรอก 2 อันซ้อนกัน
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SWKTextField(
              hint: 'NAME & SURNAME (CHILDREN) #${index + 1}',
              controller: nameCtrl,
            ),
            const SizedBox(height: 8),
            SWKTextField(
              hint: 'BIRTHDAY : DD/MM/YYYY',
              controller: dobCtrl,
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        if (onRemove != null)
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
      ],
    );
  }
}
