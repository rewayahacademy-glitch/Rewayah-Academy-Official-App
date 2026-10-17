// EA-ROLE-1 / contrat C-24 : la capacite « eleve autonome » est servie par le
// port, jamais deduite du role. Le routeur la lit pour l'accueil adulte
// (`/eleve/adulte`) et jamais pour `/eleve` ni `/tc/classe`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

import '../../support/harnais.dart';

SessionState _session(AppRole role, {bool autonome = false}) => SessionState(
  resolue: true,
  profileId: 'p-${role.valeurSql}',
  householdId: 'h1',
  role: role,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  eleveAutonome: autonome,
);

class _PortQuiEchoue implements PortCapaciteEleve {
  @override
  Future<CapaciteEleve> lire(String profileId) =>
      Future<CapaciteEleve>.error(StateError('serveur'));
}

Future<ProviderContainer> _ouvrir(
  SessionState etat,
  PortCapaciteEleve port,
) async {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      sourceSessionProvider.overrideWithValue(FausseSourceSession(etat)),
      portCapaciteEleveProvider.overrideWithValue(port),
    ],
  );
  addTearDown(c.dispose);
  c.listen(sessionProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return c;
}

void main() {
  final DateTime maintenant = DateTime.utc(2026, 10, 10, 10);

  group('SessionControleur remplit eleveAutonome depuis le port', () {
    test(
      'port factice : le profil autonome est servi, les autres non',
      () async {
        final ProviderContainer c = await _ouvrir(
          _session(AppRole.guardian),
          const PortCapaciteEleveFactice(autonomes: <String>{'p-guardian'}),
        );
        expect(c.read(sessionProvider).eleveAutonome, isTrue);

        final ProviderContainer autre = await _ouvrir(
          _session(AppRole.guardian),
          const PortCapaciteEleveFactice(),
        );
        expect(autre.read(sessionProvider).eleveAutonome, isFalse);
      },
    );

    test('production (port neutre) : capacite inconnue, donc fausse', () async {
      final ProviderContainer c = await _ouvrir(
        _session(AppRole.guardian),
        const PortCapaciteEleveInconnu(),
      );
      expect(c.read(sessionProvider).eleveAutonome, isFalse);
    });

    test('un echec du port laisse la capacite fausse', () async {
      final ProviderContainer c = await _ouvrir(
        _session(AppRole.guardian),
        _PortQuiEchoue(),
      );
      expect(c.read(sessionProvider).eleveAutonome, isFalse);
    });

    test('le port ne repond pas : rien n\'est suppose', () async {
      final ProviderContainer c = await _ouvrir(
        _session(AppRole.guardian),
        _PortSansReponse(),
      );
      expect(c.read(sessionProvider).eleveAutonome, isFalse);
    });
  });

  group('redirection : la capacite ouvre /eleve/adulte, rien d\'autre', () {
    String? decider(SessionState s, String chemin) => deciderRedirection(
      session: s,
      cheminDemande: chemin,
      maintenant: maintenant,
    );

    test('tuteur + autonome : /eleve/adulte s\'ouvre', () {
      final SessionState s = _session(AppRole.guardian, autonome: true);
      expect(decider(s, Routes.eleveAdulte), isNull);
      expect(decider(s, Routes.eleveAdulteSeances), isNull);
    });

    test('tuteur seul : /eleve/adulte est refuse', () {
      expect(
        decider(_session(AppRole.guardian), Routes.eleveAdulte),
        Routes.accesRefuse,
      );
    });

    test('tuteur + autonome : /eleve ramene a l\'accueil adulte, '
        '/tc/classe reste refuse, /eleve/coran s\'ouvre', () {
      final SessionState s = _session(AppRole.guardian, autonome: true);
      expect(decider(s, Routes.eleve), Routes.eleveAdulte);
      expect(decider(s, Routes.eleveCoran), isNull);
      expect(decider(s, '/tc/classe'), Routes.accesRefuse);
      expect(
        decider(_session(AppRole.guardian), Routes.eleve),
        Routes.accesRefuse,
      );
    });

    test('la capacite n\'ouvre rien a un autre role', () {
      expect(
        decider(_session(AppRole.teacher, autonome: true), Routes.eleveAdulte),
        isNot(isNull),
      );
    });
  });
}

class _PortSansReponse implements PortCapaciteEleve {
  @override
  Future<CapaciteEleve> lire(String profileId) =>
      Completer<CapaciteEleve>().future;
}
