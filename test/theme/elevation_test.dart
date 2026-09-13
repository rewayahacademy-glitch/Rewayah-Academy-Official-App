import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_elevation.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';

void main() {
  test('E0 is flat and E1/E2 follow the R1 shadow budget', () {
    final ombre = AppPalette.claire().ombre;
    expect(AppElevation.niveau0, isEmpty);
    expect(AppElevation.niveau1(ombre), hasLength(2));
    expect(AppElevation.niveau1(ombre).first.offset.dy, 2);
    expect(AppElevation.niveau1(ombre).last.blurRadius, 24);
    expect(AppElevation.niveau2(ombre), hasLength(2));
    expect(AppElevation.niveau2(ombre).last.offset.dy, 16);
    expect(AppElevation.niveau2(ombre).last.blurRadius, 40);
  });

  test('le thème sombre ne dessine pas d ombre de dialogue', () {
    expect(AppElevation.dialogue(AppPalette.sombre()), isEmpty);
  });
}
