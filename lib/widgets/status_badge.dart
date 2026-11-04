import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case AppConstants.statusInProgress:
        backgroundColor = AppConstants.inProgressBg;
        textColor = AppConstants.inProgressText;
        break;
      case AppConstants.statusResolved:
        backgroundColor = AppConstants.resolvedBg;
        textColor = AppConstants.resolvedText;
        break;
      case AppConstants.statusSubmitted:
      default:
        backgroundColor = AppConstants.submittedBg;
        textColor = AppConstants.submittedText;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 10.0,
        vertical: isCompact ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: isCompact ? 11.0 : 12.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}