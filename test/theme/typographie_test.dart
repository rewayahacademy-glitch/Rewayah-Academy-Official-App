import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';

void main() {
  test('l échelle UI R1 emploie une famille cohérente', () {
    final theme = AppTypography.standard;
    expect(theme.headlineSmall!.fontFamily, AppFontFamily.corps);
    expect(theme.titleLarge!.fontSize, 22);
    expect(theme.bodyLarge!.fontSize, 16);
    expect(theme.bodyMedium!.fontSize, 14);
    expect(theme.labelMedium!.fontSize, 12);
  });

  test('la variante enfant est explicite et le document Coran reste isolé', () {
    expect(AppTypography.enfant.titleLarge!.fontSize, 32);
    expect(AppTypography.enfant.bodyLarge!.fontSize, 20);
    expect(AppTypography.document().fontFamily, AppFontFamily.arabeDocument);
    expect(AppTypography.document().height, 2);
  });
}
