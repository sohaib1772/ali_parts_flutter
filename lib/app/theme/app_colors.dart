import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background & Surfaces (Light Body Theme with Navy Header)
  static const Color background = Color(0xFFF8F9FA);      // Soft White Page Background
  static const Color cardWhite = Color(0xFFFFFFFF);       // White Cards
  static const Color imageBg = Color(0xFFEDF2F7);         // Light Blue-Gray Image Background

  // Luxury Navy Palette (AppBar & Primary Buttons)
  static const Color navyDark = Color(0xFF0A192F);        // Deep Navy AppBar & Buttons
  static const Color navyHeader = Color(0xFF0B1B36);      // Header Background
  static const Color navyMedium = Color(0xFF102A43);      // Navy Medium Cards / Containers
  static const Color navyPill = Color(0xFF132B45);        // Filter Pills
  static const Color navyLight = Color(0xFF1E3A5F);

  // Luxury Gold Palette
  static const Color gold = Color(0xFFC9A227);            // Brand Primary Gold
  static const Color goldBright = Color(0xFFD4AF37);      // Accent Gold
  static const Color goldLight = Color(0xFFE5C04B);       // Light Gold
  static const Color goldDark = Color(0xFFA68018);        // Deep Gold

  // Typography & Text
  static const Color textDark = Color(0xFF0F172A);        // Main Headings & Titles (Black/Dark Slate)
  static const Color textBody = Color(0xFF334155);        // Body text
  static const Color textSecondary = Color(0xFF64748B);   // Subtitles & Muted text
  static const Color textMuted = Color(0xFF94A3B8);       // Placeholders & Borders

  // Status & Badges
  static const Color inStock = Color(0xFF059669);         // Emerald Green (متوفر)
  static const Color outOfStock = Color(0xFFEF4444);      // Red
  static const Color remainingBadge = Color(0xFFDC2626);  // Red Badge (متبقي 1)
  static const Color usedBadge = Color(0xFFF59E0B);       // Amber Badge (مستعمل)
  static const Color newBadge = Color(0xFF059669);        // Emerald Badge (جديد)
  static const Color whatsApp = Color(0xFF25D366);        // WhatsApp Green
  
  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);     // 1px Border for Cards
  static const Color divider = Color(0xFFE2E8F0);         // Divider line
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A192F), Color(0xFF112240)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5C04B), Color(0xFFC9A227)],
  );
}
