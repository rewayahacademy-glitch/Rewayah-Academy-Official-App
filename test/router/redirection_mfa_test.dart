// L1-10 : la seconde etape de connexion du controleur ferme la navigation.
// La redirection lit la capacite `mfaRequise`, jamais le role.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

SessionState _session(AppRole role, {bool mfaRequise = false}) => SessionState(
  resolue: true,
  profileId: 'p1',
  role: role,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  mfaRequise: mfaRequise,
);

String? _va(SessionState s, String chemin, {bool connue = true}) =>
    deciderRedirection(
      session: s,
      cheminDemande: chemin,
      maintenant: DateTime.utc(2026, 10, 17, 10),
      routeConnue: connue,
    );

void main() {
  final SessionState exige = _session(AppRole.controller, mfaRequise: true);

  test('mfaRequise : toute route est renvoyee a la seconde etape', () {
    for (final String chemin in <String>[
      Routes.controleur,
      Routes.controleurHistorique,
      Routes.controleurEchanges,
      Routes.controleurCompteRendu,
      Routes.compte,
      Routes.recherche,
      Routes.racine,
      Routes.connexion,
      Routes.accesRefuse,
      Routes.admin,
    ]) {
      expect(_va(exige, chemin), Routes.mfaControleur, reason: chemin);
    }
    expect(_va(exige, '/introuvable', connue: false), Routes.mfaControleur);
  });

  test('mfaRequise : la seconde etape elle-meme reste atteignable', () {
    expect(_va(exige, Routes.mfaControleur), isNull);
  });

  test(
    'sans mfaRequise : le controleur navigue, la page le renvoie chez lui',
    () {
      final SessionState libre = _session(AppRole.controller);
      expect(_va(libre, Routes.controleur), isNull);
      expect(_va(libre, Routes.controleurEchanges), isNull);
      expect(_va(libre, Routes.mfaControleur), Routes.controleur);
    },
  );

  test('la capacite decide, pas le role : un autre role sans capacite passe', () {
    for (final AppRole role in AppRole.values) {
      final SessionState s = _session(role);
      expect(
        _va(s, Routes.mfaControleur),
        Routes.racinePour(role),
        reason: role.name,
      );
    }
    // Un administrateur n'est jamais renvoye a la seconde etape du controleur.
    expect(_va(_session(AppRole.admin), Routes.admin), isNull);
  });

  test('une session d attente ou hors ligne n est pas concernee', () {
    const SessionState attente = SessionState(
      resolue: true,
      profileId: 'p1',
      role: AppRole.controller,
      accountStatus: AccountStatus.pendingKyc,
      lectureProfil: LectureProfil.presente,
      mfaRequise: true,
    );
    expect(_va(attente, Routes.controleur), Routes.attente);
  });
}
