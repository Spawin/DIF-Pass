// test/core/theme/app_theme_test.dart
import 'package:dif_pass/core/theme/app_colors.dart';
import 'package:dif_pass/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAppTheme uses the DIF Pass indigo accent as primary color', () {
    final theme = buildAppTheme();

    expect(theme.colorScheme.primary, AppColors.indigo);
    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.useMaterial3, isTrue);
  });
}
