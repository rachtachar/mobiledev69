import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // Base URL: In Android Emulator use 10.0.2.2, for Windows / Web use 127.0.0.1
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static const String oidcClientId = 'flutter-mobile-client';

  // Category Information
  static const Map<String, ExpenseCategoryInfo> categories = {
    'food': ExpenseCategoryInfo(
      id: 'food',
      label: 'อาหารและเครื่องดื่ม',
      icon: Icons.restaurant,
      color: Color(0xFFF97316), // Orange
    ),
    'transport': ExpenseCategoryInfo(
      id: 'transport',
      label: 'การเดินทาง',
      icon: Icons.directions_car,
      color: Color(0xFF06B6D4), // Cyan
    ),
    'housing': ExpenseCategoryInfo(
      id: 'housing',
      label: 'ที่พักและโรงแรม',
      icon: Icons.hotel,
      color: Color(0xFF8B5CF6), // Purple
    ),
    'entertainment': ExpenseCategoryInfo(
      id: 'entertainment',
      label: 'บันเทิงและกิจกรรม',
      icon: Icons.sports_esports,
      color: Color(0xFFEC4899), // Pink
    ),
    'shopping': ExpenseCategoryInfo(
      id: 'shopping',
      label: 'ซื้อของและของใช้',
      icon: Icons.shopping_bag,
      color: Color(0xFF10B981), // Emerald
    ),
    'other': ExpenseCategoryInfo(
      id: 'other',
      label: 'อื่นๆ',
      icon: Icons.receipt_long,
      color: Color(0xFF64748B), // Slate
    ),
  };
}

class ExpenseCategoryInfo {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategoryInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}
