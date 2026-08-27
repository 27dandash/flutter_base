import 'package:flutter/material.dart';

class BadgeIconWidget extends StatelessWidget {
  final Widget child;
  final int badgeCount;
  final Color badgeColor;
  final Color textColor;

  const BadgeIconWidget({
    super.key,
    required this.child,
    required this.badgeCount,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              badgeCount > 99 ? '99+' : badgeCount.toString(),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
