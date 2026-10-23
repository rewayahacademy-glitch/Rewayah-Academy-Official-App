// RECETTE-A-CORR : un widget lit une capacite de la session, jamais le role.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

SessionState _de(AppRole? role) => SessionState(resolue: true, role: role);

void main() {
  test('le foyer et les appareils : le tuteur a un foyer, le controle '
      "n'a pas d'appareil", () {
    for (final AppRole? role in <AppRole?>[...AppRole.values, null]) {
      final SessionState s = _de(role);
      expect(s.aUnFoyer, role == AppRole.guardian, reason: '$role');
      expect(s.peutGererAppareils, role != AppRole.controller, reason: '$role');
    }
  });

  test(
    "l'observation d'une seance : tuteur, direction, controle seulement",
    () {
      for (final AppRole? role in <AppRole?>[...AppRole.values, null]) {
        final SessionState s = _de(role);
        expect(s.observeEnFamille, role == AppRole.guardian, reason: '$role');
        expect(s.observeEnDirection, role == AppRole.admin, reason: '$role');
        expect(
          s.observeEnControle,
          role == AppRole.controller,
          reason: '$role',
        );
      }
    },
  );
}
