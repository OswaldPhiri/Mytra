import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand seed color
  static const Color seedColor = Color(0xFF1B5E8C); // Deep ocean blue

  // Income / Expense
  static const Color income = Color(0xFF26C165);
  static const Color expense = Color(0xFFE84F4F);
  static const Color neutral = Color(0xFF8B9DC3);

  // Category colors
  static const Color food = Color(0xFFF59E0B);
  static const Color transport = Color(0xFF3B82F6);
  static const Color utilities = Color(0xFF8B5CF6);
  static const Color rent = Color(0xFFEF4444);
  static const Color entertainment = Color(0xFFEC4899);
  static const Color shopping = Color(0xFF10B981);
  static const Color salary = Color(0xFF26C165);
  static const Color transfers = Color(0xFF06B6D4);
  static const Color savings = Color(0xFFF59E0B);
  static const Color other = Color(0xFF6B7280);

  // Chart colors (ordered)
  static const List<Color> chartColors = [
    Color(0xFF1B5E8C),
    Color(0xFF26C165),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF6B7280),
  ];

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return food;
      case 'transport':
        return transport;
      case 'utilities':
        return utilities;
      case 'rent':
        return rent;
      case 'entertainment':
        return entertainment;
      case 'shopping':
        return shopping;
      case 'salary':
        return salary;
      case 'transfers':
        return transfers;
      case 'savings':
        return savings;
      default:
        return other;
    }
  }
}
