import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  // สี Theme
  static const cream = Color(0xFFFFF5CD);
  static const blueTitle = Color(0xFF4DA9FF);
  static const pinkSwitch = Color(0xFFFF8E8E);
  static const greySwitch = Color(0xFFD9D9D9);
  static const textGrey = Color(0xFF8E8E8E);

  // สถานะของปุ่มต่างๆ
  bool _allNotifications = true;
  bool _likeNotification = true;
  bool _commentNotification = true;

  @override
  Widget build(BuildContext context) {
    final bool isSubOptionsEnabled = _allNotifications;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Header ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                    ),
                  ),
                  Text(
                    'NOTIFICATIONS',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
                      color: blueTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- 2. ALL NOTIFICATIONS Toggle ---
              _buildToggleRow(
                title: 'ALL NOTIFICATIONS',
                value: _allNotifications,
                onChanged: (val) {
                  setState(() {
                    _allNotifications = val;
                    // สั่งให้ตัวลูก (Like/Comment) มีค่าเท่ากับตัวแม่เสมอ
                    _likeNotification = val;
                    _commentNotification = val;
                  });
                },
                isMainToggle: true,
              ),

              const SizedBox(height: 24),

              // --- 3. POST Category ---
              Text(
                'POST',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 16),

              // --- 4. Sub Toggles ---
              _buildToggleRow(
                title: 'LIKE',
                value: _likeNotification,
                onChanged: isSubOptionsEnabled
                    ? (val) {
                        setState(() {
                          _likeNotification = val;
                        });
                      }
                    : null,
                isEnabled: isSubOptionsEnabled,
              ),

              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'COMMENT',
                value: _commentNotification,
                onChanged: isSubOptionsEnabled
                    ? (val) {
                        setState(() {
                          _commentNotification = val;
                        });
                      }
                    : null,
                isEnabled: isSubOptionsEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required Function(bool)? onChanged,
    bool isMainToggle = false,
    bool isEnabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: isEnabled ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
        
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            // ✅ แก้ไข: ใช้ activeThumbColor แทน activeColor
            activeThumbColor: Colors.white, 
            activeTrackColor: pinkSwitch,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: greySwitch,
            // ✅ แก้ไข: ใช้ WidgetStateProperty แทน MaterialStateProperty
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }
}