import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

// 🎨 Mock Palette Class เพื่อให้โค้ดทำงานได้โดยไม่ต้อง Import ไฟล์อื่น
class Palette {
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF5AB2FF);
  static const green = Color(0xFF88C273);
  static const yellow = Color(0xFFFFC107);
  static const red = Color(0xFFFF6B6B);
}

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

  // ข้อมูล Rewards และ History
  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> history = [];
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.score;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      // โหลดข้อมูลเริ่มต้นโดยใช้ภาษาจาก AppLocalizations
      final loc = AppLocalizations.of(context)!;

      _rewards = [
        {
          'name': loc.redemption_rewardIceCream,
          'cost': 100,
          'icon': Icons.icecream_rounded
        },
        {
          'name': loc.redemption_rewardPlaytime,
          'cost': 500,
          'icon': Icons.videogame_asset_rounded
        },
        {
          'name': loc.redemption_rewardToy,
          'cost': 2000,
          'icon': Icons.toys_rounded
        },
        {
          'name': loc.redemption_rewardStickers,
          'cost': 150,
          'icon': Icons.star_rounded
        },
      ];

      history = [
        {
          'action': loc.redemption_historyPlayedDefault,
          'point': '+50',
          'isGain': true,
          'date': 'Today'
        },
        {
          'action': loc.redemption_historyRedeemedDefault,
          'point': '-100',
          'isGain': false,
          'date': 'Yesterday'
        },
      ];

      _isDataInitialized = true;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // ฟังก์ชัน Helper สำหรับ TextStyle
  TextStyle _getTextStyle(double size, Color color) {
    return TextStyle(
      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
      fontSize: size,
      color: color,
    );
  }

  // ฟังก์ชันแสดง Dialog เพิ่มของรางวัลใหม่
  void _showAddRewardDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.medalredemption_addrewardBtn,
            textAlign: TextAlign.center, style: _getTextStyle(22, Palette.sky)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: loc.medalredemption_rewardnameBtn,
                hintStyle: _getTextStyle(16, Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: loc.medalredemption_costBtn,
                hintStyle: _getTextStyle(16, Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.medalredemption_cancelBtn,
                style: _getTextStyle(18, Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  costController.text.isNotEmpty) {
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
            child: Text(loc.medalredemption_addBtn,
                style: _getTextStyle(18, Colors.white)),
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
          content:
              Text('Not enough points! You need ${cost - _currentScore} more.'),
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
          style: _getTextStyle(20, Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.addchild_okBtn,
                style: _getTextStyle(18, Palette.sky)),
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
              // ✅ ใช้ Key: medalredemption_activitiesBtn
              Text(AppLocalizations.of(context)!.medalredemption_activitiesBtn,
                  style: _getTextStyle(24, Colors.black)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.sky.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('ALL', style: _getTextStyle(18, Palette.sky)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        color: Palette.sky, size: 20),
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
              // ✅ ใช้ Key: medalredemption_rewardshopBtn
              Text(AppLocalizations.of(context)!.medalredemption_rewardshopBtn,
                  style: _getTextStyle(24, Colors.black)),

              // ปุ่ม ADD Reward
              GestureDetector(
                onTap: _showAddRewardDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Palette.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 5),
                      Text(AppLocalizations.of(context)!.medalredemption_addBtn,
                          style: _getTextStyle(16, Colors.white)),
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

              return _OutlineCard(
                onTap: () => _redeemItem(item['name'] as String, cost),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: Colors.orange, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        style: _getTextStyle(
                            18, canAfford ? Colors.black87 : Colors.grey),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            canAfford ? Palette.yellow : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '$cost P',
                        style: _getTextStyle(16, Colors.white),
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
          child: Text(
              AppLocalizations.of(context)!.dairyactivity_playhistoryBtn,
              style: _getTextStyle(24, Colors.black)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = history[index];
              final isGain = log['isGain'] as bool;
              return _OutlineCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['action'] as String,
                            style: _getTextStyle(16, Colors.black87)),
                        Text(log['date'] as String,
                            style: GoogleFonts.openSans(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Text(
                      log['point'] as String,
                      style: _getTextStyle(
                          18, isGain ? Palette.green : Palette.red),
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
    // ชื่อ Title ตาม Tab
    String title = '';
    if (_selectedIndex == 0) {
      title =
          AppLocalizations.of(context)!.dairyactivity_medalsBtn.toUpperCase();
    } else if (_selectedIndex == 1) {
      // ✅ ใช้ Key: medalredemption_redemptionBtn
      title = AppLocalizations.of(context)!.medalredemption_redemptionBtn;
    } else {
      title = AppLocalizations.of(context)!.dairyactivity_playhistoryBtn;
    }

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
          title,
          style: _getTextStyle(26, Palette.sky),
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
                    // ✅ ใช้ Key: medalredemption_currentscoreBtn
                    Text(
                      AppLocalizations.of(context)!
                          .medalredemption_currentscoreBtn,
                      style: _getTextStyle(18, Colors.black),
                    ),
                    Text(
                      '${_formatNumber(_currentScore)} P',
                      style: _getTextStyle(24, Colors.black),
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
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD45E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: const Center(
              child: Icon(Icons.star, color: Colors.white, size: 50)),
        );
      },
    );
  }

  Widget _buildActivityRow(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      // แก้ไข 1: เปลี่ยน OutlineCard เป็น _OutlineCard
      child: _OutlineCard(
        onTap: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                // แก้ไข 2: เปลี่ยน luckiestH เป็น _getTextStyle
                style: _getTextStyle(18, Colors.black),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.redemption_playBtn,
                // แก้ไข 3: เปลี่ยน luckiestH เป็น _getTextStyle
                style: _getTextStyle(16, Palette.sky),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 📦 Internal Widget: OutlineCard (Mocking the one from ui.dart)
class _OutlineCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _OutlineCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black26, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: child,
        ),
      ),
    );
  }
}
