// PROFILS P3 (11/11/2026) : la capacite d'ouvrir la Bibliotheque suit le
// routeur (CAP29-F : eleve, tuteur, enseignant), et la Bibliotheque se range
// dans la page des Classes pour l'eleve et l'enseignant, dans le Compte pour
// le tuteur. Aucun autre role ne l'ouvre.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

SessionState _actif(AppRole role) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  householdId: role == AppRole.guardian || role == AppRole.student
      ? 'f1'
      : null,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

void main() {
  for (final AppRole role in AppRole.values) {
    test('${role.name} : la capacite suit le routeur', () {
      final SessionState session = _actif(role);
      final String? decision = deciderRedirection(
        session: session,
        cheminDemande: Routes.tcBibliotheque,
        maintenant: DateTime.utc(2026, 11, 11, 12),
      );
      // ESPACE-APPRENDRE (lot 5) : l'eleve a une seule Bibliotheque, celle
      // d'Apprendre ; le routeur l'y conduit, il ne la lui refuse pas.
      final bool routeurOuvre =
          decision == null ||
          (role == AppRole.student && decision == Routes.eleveApprendre);
      expect(session.peutOuvrirBibliotheque, routeurOuvre, reason: role.name);
    });
  }

  test('la Bibliotheque se range dans les Classes pour l eleve et '
      'l enseignant, dans le Compte pour le tuteur', () {
    expect(_actif(AppRole.student).bibliothequeDansMaClasse, isTrue);
    expect(_actif(AppRole.teacher).bibliothequeDansMaClasse, isTrue);
    expect(_actif(AppRole.guardian).bibliothequeDansMaClasse, isFalse);
    expect(_actif(AppRole.guardian).peutOuvrirBibliotheque, isTrue);
    for (final AppRole role in <AppRole>[
      AppRole.admin,
      AppRole.accountant,
      AppRole.controller,
    ]) {
      expect(_actif(role).peutOuvrirBibliotheque, isFalse, reason: role.name);
      expect(_actif(role).bibliothequeDansMaClasse, isFalse, reason: role.name);
    }
  });
}
