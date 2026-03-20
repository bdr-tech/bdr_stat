import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('color constants', () {
      test('should have correct primary colors', () {
        expect(AppTheme.primaryColor, const Color(0xFF1565C0));
        expect(AppTheme.secondaryColor, const Color(0xFFFF6F00));
        expect(AppTheme.errorColor, const Color(0xFFD32F2F));
        expect(AppTheme.successColor, const Color(0xFF388E3C));
        expect(AppTheme.warningColor, const Color(0xFFFFA000));
      });

      test('should have correct background colors', () {
        expect(AppTheme.backgroundColor, const Color(0xFF121212));
        expect(AppTheme.surfaceColor, const Color(0xFF1E1E1E));
        expect(AppTheme.cardColor, const Color(0xFF2C2C2C));
      });

      test('should have correct text colors', () {
        expect(AppTheme.textPrimary, const Color(0xFFFFFFFF));
        expect(AppTheme.textSecondary, const Color(0xFFB3B3B3));
        expect(AppTheme.textHint, const Color(0xFF757575));
      });

      test('should have correct team colors', () {
        expect(AppTheme.homeTeamColor, const Color(0xFFE53935));
        expect(AppTheme.awayTeamColor, const Color(0xFF1E88E5));
      });

      test('should have correct shot chart colors', () {
        expect(AppTheme.shotMadeColor, const Color(0xFF4CAF50));
        expect(AppTheme.shotMissedColor, const Color(0xFFEF5350));
        expect(AppTheme.madeColor, AppTheme.shotMadeColor);
        expect(AppTheme.missedColor, AppTheme.shotMissedColor);
      });

      test('should have correct divider and border colors', () {
        expect(AppTheme.dividerColor, const Color(0xFF424242));
        expect(AppTheme.borderColor, const Color(0xFF424242));
      });

      test('should have correct foul colors', () {
        expect(AppTheme.foulWarningColor, const Color(0xFFFFEB3B));
        expect(AppTheme.foulOutColor, const Color(0xFFFF5252));
      });

      test('should have correct court colors', () {
        expect(AppTheme.courtColor, const Color(0xFFCD853F));
        expect(AppTheme.courtLineColor, const Color(0xFFFFFFFF));
        expect(AppTheme.threePointLineColor, const Color(0xFFFFFFFF));
      });
    });

    group('darkTheme', () {
      test('should return ThemeData', () {
        final theme = AppTheme.darkTheme;
        expect(theme, isA<ThemeData>());
      });

      test('should use Material 3', () {
        final theme = AppTheme.darkTheme;
        expect(theme.useMaterial3, true);
      });

      test('should be dark theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.brightness, Brightness.dark);
      });

      test('should have correct color scheme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.colorScheme.primary, AppTheme.primaryColor);
        expect(theme.colorScheme.secondary, AppTheme.secondaryColor);
        expect(theme.colorScheme.error, AppTheme.errorColor);
        expect(theme.colorScheme.surface, AppTheme.surfaceColor);
      });

      test('should have correct scaffold background color', () {
        final theme = AppTheme.darkTheme;
        expect(theme.scaffoldBackgroundColor, AppTheme.backgroundColor);
      });

      test('should have correct app bar theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.appBarTheme.backgroundColor, AppTheme.surfaceColor);
        expect(theme.appBarTheme.foregroundColor, AppTheme.textPrimary);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.appBarTheme.centerTitle, true);
      });

      test('should have correct card theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.cardTheme.color, AppTheme.cardColor);
        expect(theme.cardTheme.elevation, 2);
      });

      test('should have correct dialog theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.dialogTheme.backgroundColor, AppTheme.surfaceColor);
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('should have correct snack bar theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.snackBarTheme.backgroundColor, AppTheme.cardColor);
        expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      });

      test('should have correct divider theme', () {
        final theme = AppTheme.darkTheme;
        expect(theme.dividerTheme.thickness, 1);
      });

      test('should have complete text theme', () {
        final theme = AppTheme.darkTheme;
        final textTheme = theme.textTheme;

        expect(textTheme.displayLarge, isNotNull);
        expect(textTheme.displayMedium, isNotNull);
        expect(textTheme.displaySmall, isNotNull);
        expect(textTheme.headlineLarge, isNotNull);
        expect(textTheme.headlineMedium, isNotNull);
        expect(textTheme.headlineSmall, isNotNull);
        expect(textTheme.titleLarge, isNotNull);
        expect(textTheme.titleMedium, isNotNull);
        expect(textTheme.titleSmall, isNotNull);
        expect(textTheme.bodyLarge, isNotNull);
        expect(textTheme.bodyMedium, isNotNull);
        expect(textTheme.bodySmall, isNotNull);
        expect(textTheme.labelLarge, isNotNull);
        expect(textTheme.labelMedium, isNotNull);
        expect(textTheme.labelSmall, isNotNull);
      });
    });
  });

  group('PlayerCardStyle', () {
    test('should have correct dimensions', () {
      expect(PlayerCardStyle.minWidth, 100);
      expect(PlayerCardStyle.minHeight, 120);
      expect(PlayerCardStyle.spacing, 8);
    });

    test('should have correct jersey number style', () {
      expect(PlayerCardStyle.jerseyNumberStyle.fontSize, 28);
      expect(PlayerCardStyle.jerseyNumberStyle.fontWeight, FontWeight.bold);
      expect(PlayerCardStyle.jerseyNumberStyle.color, AppTheme.textPrimary);
    });

    test('should have correct name style', () {
      expect(PlayerCardStyle.nameStyle.fontSize, 14);
      expect(PlayerCardStyle.nameStyle.fontWeight, FontWeight.w500);
      expect(PlayerCardStyle.nameStyle.color, AppTheme.textPrimary);
    });

    test('should have correct points style', () {
      expect(PlayerCardStyle.pointsStyle.fontSize, 16);
      expect(PlayerCardStyle.pointsStyle.fontWeight, FontWeight.bold);
      expect(PlayerCardStyle.pointsStyle.color, AppTheme.secondaryColor);
    });
  });

  group('CourtStyle', () {
    test('should have correct aspect ratio', () {
      expect(CourtStyle.aspectRatio, 94 / 50);
    });

    test('should have correct shot marker dimensions', () {
      expect(CourtStyle.shotMarkerSize, 16);
      expect(CourtStyle.shotMarkerBorderWidth, 2);
    });
  });
}
