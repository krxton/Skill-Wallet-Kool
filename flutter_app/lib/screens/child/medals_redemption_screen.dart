import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/palette.dart';
import '../../../widgets/ui.dart';

class MedalsRedemptionScreen extends StatefulWidget {
  final int score;

  const MedalsRedemptionScreen({
    super.key,
    required this.score,
  });

  @override
  State<MedalsRedemptionScreen> createState() => _MedalsRedemptionScreenState();
}

class _MedalsRedemptionScreenState extends State<MedalsRedemptionScreen> {
  int _selectedIndex = 0;
  late int _currentScore;

  // ข้อมูล Rewards
  List<Map<String, dynamic>> _rewards = [
    {'name': 'ICE CREAM', 'cost': 100, 'icon': Icons.icecream_rounded},
    {'name': '1 HR PLAYTIME', 'cost': 500, 'icon': Icons.videogame_asset_rounded},
    {'name': 'NEW TOY', 'cost': 2000, 'icon': Icons.toys_rounded},
    {'name': 'STICKERS', 'cost': 150, 'icon': Icons.star_rounded},
  ];
  
  // ข้อมูล History
  List<Map<String, dynamic>> history = [
    {'action': 'Played Ping Pong', 'point': '+50', 'isGain': true, 'date': 'Today'},
    {'action': 'Redeemed Ice Cream', 'point': '-100', 'isGain': false, 'date': 'Yesterday'},
  ];

  @override
  void initState() {
    super.initState();
    _currentScore = widget.score;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // ฟังก์ชันแสดง Dialog เพิ่มของรางวัลใหม่
  void _showAddRewardDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ADD REWARD', textAlign: TextAlign.center, style: luckiestH(22, color: Palette.sky)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Reward Name',
                hintStyle: GoogleFonts.luckiestGuy(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Cost (Points)',
                hintStyle: GoogleFonts.luckiestGuy(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: luckiestH(18, color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty && costController.text.isNotEmpty) {
                setState(() {
                  _rewards.add({
                    'name': nameController.text.toUpperCase(),
                    'cost': int.tryParse(costController.text) ?? 0,
                    'icon': Icons.card_giftcard_rounded,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('ADD', style: luckiestH(18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _redeemItem(String name, int cost) {
    if (_currentScore >= cost) {
      setState(() {
        _currentScore -= cost;
        history.insert(0, {
          'action': 'Redeemed $name',
          'point': '-$cost',
          'isGain': false,
          'date': 'Just Now'
        });
      });
      _showSuccessDialog(name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points! You need ${cost - _currentScore} more.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Palette.green, size: 60),
        content: Text(
          'Successfully Redeemed\n$itemName',
          textAlign: TextAlign.center,
          style: luckiestH(20, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: luckiestH(18, color: Palette.sky)),
          )
        ],
      ),
    );
  }

  // --- 1. หน้ากิจกรรม ---
  Widget _buildActivitiesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACTIVITIES', style: luckiestH(24, color: Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.sky.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('ALL', style: luckiestH(18, color: Palette.sky)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: Palette.sky, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            children: [
              _buildActivityRow('PING PONG GAME'),
              _buildActivityRow('DICTATION GAME'),
              _buildActivityRow('PICTURE MEMORY GAME'),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. หน้าแลกของรางวัล ---
  Widget _buildRedemptionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REWARDS SHOP', style: luckiestH(24, color: Colors.black)),
              
              // ปุ่ม ADD Reward (คงไว้)
              GestureDetector(
                onTap: _showAddRewardDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Palette.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 5),
                      Text('ADD', style: luckiestH(16, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: _rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _rewards[index];
              final int cost = item['cost'] as int;
              final bool canAfford = _currentScore >= cost;

              return OutlineCard(
                onTap: () => _redeemItem(item['name'] as String, cost),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: Colors.orange, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        style: luckiestH(18, color: canAfford ? Colors.black87 : Colors.grey),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: canAfford ? Palette.yellow : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '$cost P',
                        style: luckiestH(16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. หน้าประวัติ ---
  Widget _buildHistoryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text('HISTORY LOG', style: luckiestH(24, color: Colors.black)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = history[index];
              final isGain = log['isGain'] as bool;
              return OutlineCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['action'] as String, style: luckiestH(16, color: Colors.black87)),
                        Text(log['date'] as String, style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Text(
                      log['point'] as String,
                      style: luckiestH(18, color: isGain ? Palette.green : Palette.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          _selectedIndex == 0 ? 'MEDALS' : (_selectedIndex == 1 ? 'REDEMPTION' : 'HISTORY'),
          style: luckiestH(32, color: Palette.sky),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // --- SCORE SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMedalIcon(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CURRENT SCORE',
                      style: luckiestH(18, color: Colors.black),
                    ),
                    Text(
                      '${_formatNumber(_currentScore)} P',
                      style: luckiestH(24, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Content ---
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildActivitiesPage(),
                _buildRedemptionPage(),
                _buildHistoryPage(),
              ],
            ),
          ),

          // --- Bottom Navigation ---
          Container(
            height: 85,
            decoration: const BoxDecoration(
              color: Color(0xFFF2C46F),
              border: Border(top: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomBtn('assets/icons/coin.png', 0),
                _buildBottomBtn('assets/icons/ticket.png', 1),
                _buildBottomBtn('assets/icons/history-book.png', 2),
              ],
            ),
          ),
        ],
      ),
      // ❌ ลบ floatingActionButton ออกแล้ว
    );
  }

  Widget _buildBottomBtn(String assetPath, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            assetPath,
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildMedalIcon() {
    return Image.asset(
      'assets/icons/medal.png',
      width: 100,
      height: 110,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 85, height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD45E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: const Center(child: Icon(Icons.star, color: Colors.white, size: 50)),
        );
      },
    );
  }

  Widget _buildActivityRow(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: OutlineCard(
        onTap: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: luckiestH(18, color: Colors.black),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PLAY',
                style: luckiestH(16, color: Palette.sky),
              ),
            ),
          ],
        ),
      ),
    );
  }
}