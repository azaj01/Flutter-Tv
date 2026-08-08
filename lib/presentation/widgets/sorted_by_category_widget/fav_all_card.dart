import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bottom bar shortcut on the live TV screen.
///
/// Sized by its parent rather than a hard-coded 150pt: at five-digit counts, or
/// with a larger system font scale, the fixed width overflowed its own row.
class FavAllCard extends StatelessWidget {
  const FavAllCard({
    required this.text,
    required this.count,
    required this.icon,
    super.key,
    this.onTap,
  });

  final String text;
  final int count;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                NumberFormat.decimalPattern().format(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
