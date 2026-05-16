// lib/utils/constants.dart
// Configuration et constantes de l'application AgriSmart

import 'package:flutter/material.dart';

class AppConstants {
  // ── API Configuration ──────────────────────────────────────────────────────
  // Pour le web local : http://127.0.0.1:8000/api
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String googleMapsApiKey =
      'AIzaSyCtL4ITV-mDPnoLbSGpEKupt_ztNZJSEio';
  static const String geminiApiKey = 'AIzaSyBfdPuRqYjYBnSjV92pj_-_Kj_zJZ2tZ_M';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Storage Keys ───────────────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'AgriSmart';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Prix agricoles en temps réel';
}

class AppColors {
  // ── Premium Emerald Palette ────────────────────────────────────────────────
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF065F46); // Emerald 800
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryContainer = Color(0xFFECFDF5);

  // ── Secondary Palette (Warm Gold) ──────────────────────────────────────────
  static const Color secondary = Color(0xFFF59E0B); // Amber 500
  static const Color secondaryDark = Color(0xFF92400E); // Amber 800
  static const Color secondaryLight = Color(0xFFFEF3C7); // Amber 100

  // ── Accent (Electric Indigo for modern feel) ───────────────────────────────
  static const Color accent = Color(0xFF6366F1); // Indigo 500
  static const Color accentContainer = Color(0xFFEEF2FF);

  // ── Surface & Neutral ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB); // Gray 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Gray 100
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color divider = Color(0xFFF3F4F6);

  // ── Text (Deep Graphite) ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827); // Gray 900
  static const Color textSecondary = Color(0xFF4B5563); // Gray 600
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status (Vibrant) ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoBg = Color(0xFFDBEAFE);

  // ── Trend Colors (Farmer-focused: up = favorable/green, down = unfavorable/red)
  static const Color trendUp =
      Color(0xFF10B981); // Green for price increase (favorable for farmers)
  static const Color trendDown =
      Color(0xFFEF4444); // Red for price decrease (unfavorable for farmers)
  static const Color trendStable = Color(0xFF6B7280);

  // ── Special Premium Gradients ─────────────────────────────────────────────
  static const Gradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const Gradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const Gradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white70, Colors.white38],
  );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
          onPrimary: AppColors.textOnPrimary,
        ),
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: AppColors.background,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),

        // Bottom Navigation
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 10,
          indicatorColor: AppColors.primary.withAlpha(25),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),

        // Text
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          headlineMedium: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          headlineSmall: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          titleSmall: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
          bodyLarge: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          bodyMedium: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          bodySmall: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary),
          labelLarge: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      );
}

// ── Formatters & Helpers ───────────────────────────────────────────────────────
class AppFormatters {
  static String formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}k FCFA';
    }
    return '${price.toStringAsFixed(0)} FCFA';
  }

  static String formatPriceShort(double price) {
    return '${price.toStringAsFixed(0)} F';
  }

  static String formatPercent(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  static Color trendColor(String trend) {
    switch (trend) {
      case 'up':
        return AppColors.trendUp;
      case 'down':
        return AppColors.trendDown;
      default:
        return AppColors.trendStable;
    }
  }

  static IconData trendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up_rounded;
      case 'down':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  static String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  static String availabilityLabel(String avail) {
    switch (avail) {
      case 'abundant':
        return 'Abondant';
      case 'normal':
        return 'Normal';
      case 'scarce':
        return 'Rare';
      case 'unavailable':
        return 'Indisponible';
      default:
        return avail;
    }
  }

  static Color availabilityColor(String avail) {
    switch (avail) {
      case 'abundant':
        return AppColors.success;
      case 'normal':
        return AppColors.primary;
      case 'scarce':
        return AppColors.warning;
      case 'unavailable':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
