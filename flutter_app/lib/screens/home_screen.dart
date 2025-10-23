import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'Category'; // default text

  void _pickCategory() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final items = ['Math', 'Physical', 'Language'];
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (_, i) => ListTile(
              title: Text(
                items[i],
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () => Navigator.pop(context, items[i]),
            ),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: items.length,
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _category = picked);
  }

  Widget _chip(String text) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('SKILL WALLET KOOL'),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.pink,             // แถบล่างสีชมพูตาม Figma
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Clips'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============== Search bar (มุมโค้ง, ไอคอนซ้าย-ขวา) ==============
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 4)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: const [
                    Icon(Icons.menu, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search...',
                        style: TextStyle(color: Colors.black45, fontSize: 16),
                      ),
                    ),
                    Icon(Icons.search, size: 20, color: Colors.black54),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============== Section header: SWK + Category pill ==============
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SWK',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(color: AppTheme.blue),
                  ),

                  // ปุ่ม Category แบบ pill + ลูกศรลง
                  GestureDetector(
                    onTap: _pickCategory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.sky,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _category.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ============== CLIP VDO card ==============
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.blue, width: 2), // เส้นขอบฟ้าเหมือนใน Figma ขวา
                ),
                alignment: Alignment.center,
                child: const Text('CLIP VDO', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              ),

              const SizedBox(height: 20),

              // ============== Popular Activities ==============
              Text(
                'POPULAR ACTIVITIES',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: AppTheme.yellow),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _chip('CLIP'),
                  _chip('CLIP'),
                  _chip('CLIP'),
                ],
              ),

              const SizedBox(height: 16),
              Text('NEW', style: Theme.of(context).textTheme.titleSmall!.copyWith(color: AppTheme.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
