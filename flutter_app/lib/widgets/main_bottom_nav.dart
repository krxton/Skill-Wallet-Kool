import 'package:flutter/material.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const salmon = Color.fromARGB(255, 45, 163, 248); // แถบชมพู
  static const yolk = Color.fromARGB(255, 249, 216, 98); // สีเหลืองปุ่มเลือก

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: salmon,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(
            index: 0,
            icon: Icons.home_rounded,
          ),
          _buildCenterPlus(),
          _buildIconButton(
            index: 2,
            icon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required int index, required IconData icon}) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? yolk : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterPlus() {
    return GestureDetector(
      onTap: () => onTabSelected(1),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
