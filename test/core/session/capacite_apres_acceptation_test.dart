// FN-112 (prod du 01/11/2026) : l'eleve adulte inscrit « pour moi », connecte
// pendant l'attente puis accepte, restait sur l'accueil du tuteur (« Aucun
// profil eleve pour l'instant »). Le serveur rend faux tant que le compte
// n'est pas actif : cette reponse ne doit pas rester en memoire.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';

SessionState _adulte(AccountStatus statut) => SessionState(
  resolue: true,
  profileId: 'p-adulte',
  householdId: 'h1',
  role: AppRole.guardian,
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

class _Source implements SourceSession {
  // ignore: close_sinks, ferme par addTearDown dans le test.
  final StreamController<SessionState> flux =
      StreamController<SessionState>.broadcast();

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

/// Comme `ma_capacite_eleve` : faux tant que le compte n'est pas actif.
class _Serveur implements PortCapaciteEleve {
  bool actif = false;
  int lectures = 0;

  @override
  Future<CapaciteEleve> lire(String profileId) async {
    lectures++;
    return actif ? const EleveAutonome() : const PasEleve();
  }
}

Future<void> _attendre() async {
  for (int i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('lue pendant l\'attente, relue a l\'acceptation : l\'adulte devient '
      'eleve autonome', () async {
    final _Source source = _Source();
    addTearDown(source.flux.close);
    final _Serveur serveur = _Serveur();
    final ProviderContainer c = ProviderContainer(
      overrides: [
        sourceSessionProvider.overrideWithValue(source),
        portCapaciteEleveProvider.overrideWithValue(serveur),
      ],
    );
    addTearDown(c.dispose);
    c.listen(sessionProvider, (_, _) {});
    await _attendre();

    source.flux.add(_adulte(AccountStatus.pendingKyc));
    await _attendre();
    expect(c.read(sessionProvider).eleveAutonome, isFalse);
    expect(serveur.lectures, 1);

    // La direction accepte : le compte devient actif.
    serveur.actif = true;
    source.flux.add(_adulte(AccountStatus.active));
    await _attendre();
    expect(c.read(sessionProvider).eleveAutonome, isTrue);
    expect(serveur.lectures, 2);

    // Une fois lue avec un compte actif, la reponse est gardee.
    source.flux.add(_adulte(AccountStatus.active));
    await _attendre();
    expect(serveur.lectures, 2);
  });
}
