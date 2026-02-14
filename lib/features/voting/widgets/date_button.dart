import 'package:flutter/material.dart';
import 'package:pagella_sanremo/config/theme/app_theme.dart';

class DateButton extends StatelessWidget {
  final String date;
  final bool isSelected;
  final VoidCallback? onTap;

  const DateButton({
    super.key,
    required this.date,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.blueDark : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          date,
          style: TextStyle(
            color: isSelected ? AppColors.blueDark : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
      ),
    );
  }
}
