import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../services/child_service.dart';

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
  List<Map<String, dynamic>> _activityHistory = [];
  bool _isLoading = true;

  final ChildService _childService = ChildService();

  @override
  void initState() {
    super.initState();
    _currentScore = widget.score;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final parentId = userProvider.currentParentId;
    final childId = userProvider.currentChildId;

    if (parentId != null && childId != null) {
      try {
        // ดึงข้อมูลของรางวัล
        final rewards = await _childService.getRewards(parentId);

        // ดึงประวัติกิจกรรม
        final activityHistory = await _childService.getActivityHistory(childId);

        // ดึงประวัติคะแนน (ได้+ใช้)
        final pointHistory = await _childService.getPointHistory(childId);

        // ดึงคะแนนปัจจุบัน
        final stats = await _childService.getChildStats(childId);

        if (mounted) {
          setState(() {
            // ถ้ามีของรางวัลจาก DB ให้ใช้ ไม่งั้นใช้ mock
            // rewards มาจาก parent_and_medals พร้อม nested medals object
            if (rewards.isNotEmpty) {
              _rewards = rewards.map((r) {
                final medal = r['medals'] as Map<String, dynamic>?;
                // point_medals อาจเป็น Decimal
                final pointValue = medal?['point_medals'];
                int cost = 0;
                if (pointValue is int) {
                  cost = pointValue;
                } else if (pointValue is double) {
                  cost = pointValue.toInt();
                } else if (pointValue != null) {
                  cost = int.tryParse(pointValue.toString()) ?? 0;
                }

                return {
                  'id': medal?['id']?.toString() ?? '',
                  'name': medal?['name_medals']?.toString() ?? '',
                  'cost': cost,
                  'icon': Icons.card_giftcard_rounded, // Default icon
                };
              }).toList();
            } else {
              // ไม่แสดง mock rewards - แสดง empty state แทน
              _rewards = [];
            }

            // ถ้ามีประวัติจาก DB ให้ใช้
            if (pointHistory.isNotEmpty) {
              history = pointHistory;
            } else {
              // ไม่แสดง mock history - แสดง empty state แทน
              history = [];
            }

            _activityHistory = activityHistory;
            _currentScore = stats['wallet'] as int? ?? widget.score;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading data: $e');
        _loadMockData();
      }
    } else {
      _loadMockData();
    }
  }

  void _loadMockData() {
    // ไม่โหลด mock data - แสดง empty state แทน
    _rewards = [];
    history = [];
    if (mounted) {
      setState(() => _isLoading = false);
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.medalredemption_cancelBtn,
                style: _getTextStyle(18, Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  costController.text.isNotEmpty) {
                // Get parentId before closing dialog
                final userProvider = context.read<UserProvider>();
                final parentId = userProvider.currentParentId;

                Navigator.pop(dialogContext);

                if (parentId != null) {
                  // บันทึกลง database
                  final result = await _childService.addReward(
                    parentId: parentId,
                    name: nameController.text.toUpperCase(),
                    cost: int.tryParse(costController.text) ?? 0,
                  );

                  if (result != null && mounted) {
                    // Refresh ข้อมูล
                    await _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เพิ่มของรางวัลสำเร็จ!'),
                        backgroundColor: Palette.green,
                      ),
                    );
                  }
                } else {
                  // ถ้าไม่มี parentId ให้เพิ่มใน local state
                  setState(() {
                    _rewards.add({
                      'id': DateTime.now().toString(),
                      'name': nameController.text.toUpperCase(),
                      'cost': int.tryParse(costController.text) ?? 0,
                      'icon': Icons.card_giftcard_rounded,
                    });
                  });
                }
              }
            },
            child: Text(loc.medalredemption_addBtn,
                style: _getTextStyle(18, Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemItem(String rewardId, String name, int cost) async {
    if (_currentScore >= cost) {
      final userProvider = context.read<UserProvider>();
      final childId = userProvider.currentChildId;
      final parentId = userProvider.currentParentId;

      if (childId != null) {
        // แลกผ่าน database (ใช้ตาราง redemption)
        final result = await _childService.redeemReward(
          childId: childId,
          rewardId: rewardId,
          rewardName: name,
          cost: cost,
          parentId: parentId,
        );

        if (!mounted) return;

        if (result['success'] == true) {
          setState(() {
            _currentScore = result['newWallet'] as int? ?? (_currentScore - cost);
            history.insert(0, {
              'action': 'แลก $name',
              'point': '-$cost',
              'isGain': false,
              'date': 'Just Now'
            });
          });
          _showSuccessDialog(name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']?.toString() ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // ถ้าไม่มี childId ให้แลกใน local state
        setState(() {
          _currentScore -= cost;
          history.insert(0, {
            'action': 'แลก $name',
            'point': '-$cost',
            'isGain': false,
            'date': 'Just Now'
          });
        });
        _showSuccessDialog(name);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คะแนนไม่เพียงพอ! ต้องการอีก ${cost - _currentScore} คะแนน'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Palette.sky));
    }

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
                  color: Palette.sky.withValues(alpha: 0.15),
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
          child: _activityHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีประวัติกิจกรรม',
                        style: _getTextStyle(16, Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: _activityHistory.length,
                  itemBuilder: (context, index) {
                    final activity = _activityHistory[index];
                    final activityName = activity['activity']?['name_activity'] ?? 'กิจกรรม';
                    // point อาจเป็น Decimal จาก Supabase
                    final pointValue = activity['point'];
                    int scoreEarned = 0;
                    if (pointValue is int) {
                      scoreEarned = pointValue;
                    } else if (pointValue is double) {
                      scoreEarned = pointValue.toInt();
                    } else if (pointValue != null) {
                      scoreEarned = int.tryParse(pointValue.toString()) ?? 0;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: _OutlineCard(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activityName.toString().toUpperCase(),
                                    style: _getTextStyle(16, Colors.black),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '+$scoreEarned คะแนน',
                                    style: _getTextStyle(14, Palette.green),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1E9FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DONE',
                                style: _getTextStyle(14, Palette.sky),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
          child: _rewards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีของรางวัล',
                        style: _getTextStyle(16, Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กด + เพื่อเพิ่มของรางวัลใหม่',
                        style: _getTextStyle(14, Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: _rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _rewards[index];
              final int cost = item['cost'] as int;
              final bool canAfford = _currentScore >= cost;
              final String rewardId = item['id']?.toString() ?? '';
              final String rewardName = item['name'] as String;

              return _OutlineCard(
                onTap: () => _redeemItem(rewardId, rewardName, cost),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
          child: history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีประวัติ',
                        style: _getTextStyle(16, Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['action'] as String,
                            style: _getTextStyle(16, Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(log['date'] as String,
                              style: GoogleFonts.openSans(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
