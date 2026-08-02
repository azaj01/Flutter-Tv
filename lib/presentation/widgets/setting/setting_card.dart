import 'package:flutter/material.dart';

import 'package:tiwee/core/theme/app_colors.dart';

class SettingCard extends StatelessWidget {
  const SettingCard({
    required this.onTap,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}
