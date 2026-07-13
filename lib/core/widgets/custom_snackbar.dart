import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    SnackBarAction? action,
  }) {
    // Clear any existing SnackBars to prevent queuing
    ScaffoldMessenger.of(context).clearSnackBars();

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.3);
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case SnackBarType.error:
        bgColor = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFF43F5E).withValues(alpha: 0.3);
        textColor = const Color(0xFF9F1239);
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFF43F5E);
        break;
      case SnackBarType.warning:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFBBD03).withValues(alpha: 0.3);
        textColor = const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFBBD03);
        break;
      case SnackBarType.info:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF3B82F6);
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  action.onPressed();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: textColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(
                Icons.close_rounded,
                color: textColor.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
