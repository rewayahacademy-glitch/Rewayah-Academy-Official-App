import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';

void main() {
  test('les durées R1 restent brèves', () {
    expect(AppMouvement.retourTactile.inMilliseconds, 100);
    expect(AppMouvement.micro.inMilliseconds, 120);
    expect(AppMouvement.apparition.inMilliseconds, 180);
    expect(AppMouvement.navigation.inMilliseconds, 220);
    expect(AppMouvement.plafond.inMilliseconds, 400);
  });
}
