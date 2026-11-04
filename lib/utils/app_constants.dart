import 'package:flutter/material.dart';

class AppConstants {
  // Prevent this class from being instantiated
  AppConstants._();

  
  // Light blue and white color paletter
  static const Color primaryBlue = Color(0xFF0288D1); 
  static const Color lightBlueAccent = Color(0xFF29B6F6); 
  static const Color lightBlueSurface = Color(0xFFE1F5FE); 
  static const Color scaffoldBackground = Color(0xFFF8FAFC); 
  static const Color cardWhite = Color(0xFFFFFFFF); 

  // Text & Border Colors
  static const Color textDark = Color(0xFF0F172A); 
  static const Color textSecondary = Color(0xFF64748B); 
  static const Color borderColor = Color(0xFFE2E8F0); 


  // STATUS STRINGS & STATUS BADGE COLORS
  
  static const String statusSubmitted = 'Submitted';
  static const String statusInProgress = 'In Progress';
  static const String statusResolved = 'Resolved';

  static const List<String> allStatuses = [
    statusSubmitted,
    statusInProgress,
    statusResolved,
  ];

  // Submitted Amber/Orange pill badge
  static const Color submittedText = Color(0xFFD97706);
  static const Color submittedBg = Color(0xFFFEF3C7);

  // In Progress (Light Blue pill badge)
  static const Color inProgressText = Color(0xFF0284C7);
  static const Color inProgressBg = Color(0xFFE0F2FE);

  // Resolved (Green pill badge)
  static const Color resolvedText = Color(0xFF16A34A);
  static const Color resolvedBg = Color(0xFFDCFCE7);

  
  // INCIDENT CATEGORIES & ICONS
  
  static const List<String> categories = [
    'Facilities',
    'Water',
    'Electricity',
    'Safety',
    'Sanitation',
  ];

  // Returns the matching icon for each category on the "Report an Incident" screen
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Facilities':
        return Icons.apartment_rounded;
      case 'Water':
        return Icons.water_drop_outlined;
      case 'Electricity':
        return Icons.bolt_rounded;
      case 'Safety':
        return Icons.shield_outlined;
      case 'Sanitation':
        return Icons.delete_outline_rounded;
      default:
        return Icons.report_problem_outlined;
    }
  }

  
  // PRESET CAMPUS LOCATIONS (DROPDOWN LIST)
  
  static const List<String> campusLocations = [
    'Block A — Ground Floor',
    'Block B — Room 204',
    'Leadership Center — 2nd Floor',
    'Student Residence',
    'Campus Library / Learning Commons',
    'Cafeteria',
    'Main Courtyard & Parking',
  ];

  
  // FIREBASE COLLECTION & STORAGE NAMES
  static const String usersCollection = 'users';
  static const String authorizedStaffCollection = 'authorized_staff';
  static const String incidentsCollection = 'incidents';
  static const String storageFolder = 'incident_images';
}