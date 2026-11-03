// Test casse expres (03/11/2026) : prouve que la CI en quatre lots passe au
// rouge. Branche jetable, PR fermee sans fusion.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preuve du rouge : ce test doit echouer', () {
    expect(1, 2);
  });
}
