// SALLE-ROBUSTE : la memoire de la salle ne survit pas a la personne.
//
// L'etat partage d'une seance, la position du dock, l'etat des outils, la file
// de recitation, la page de lecture et la cadence des rappels vivent en memoire
// du processus. Sur un poste partage, sans rechargement, le compte suivant ne
// doit rien en relire : chacun de ces providers est lie au profil connecte et
// se reconstruit a la deconnexion comme au changement de compte.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/tc_classe/controleur_recitation.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/rappel_discret.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/core/tc_etat_partage/port_etat_partage_persistant.dart';
import 'package:rewayah_academy/core/tc_etat_partage/providers_tc_etat_partage.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';

import 'f/support/fabriques.dart';

class _SourcePilotee implements SourceSession {
  _SourcePilotee(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

void main() {
  late StreamController<SessionState> flux;
  late ProviderContainer conteneur;

  Future<void> connecter(String? profil) async {
    flux.add(
      profil == null
          ? const SessionState.deconnecte()
          : SessionState(resolue: true, profileId: profil),
    );
    await pumpEventQueue();
  }

  setUp(() {
    flux = StreamController<SessionState>.broadcast();
    conteneur = ProviderContainer(
      overrides: [
        sourceSessionProvider.overrideWithValue(_SourcePilotee(flux)),
      ],
    );
    // Les providers sont gardes vivants, comme dans l'application.
    conteneur.listen(sessionProvider, (_, _) {});
    conteneur.listen(portEtatPartagePersistantProvider, (_, _) {});
    conteneur.listen(portPositionDockProvider, (_, _) {});
    conteneur.listen(etatOutilsProvider, (_, _) {});
    conteneur.listen(recitationProvider, (_, _) {});
    conteneur.listen(portRappelDiscretProvider, (_, _) {});
  });

  tearDown(() async {
    conteneur.dispose();
    await flux.close();
  });

  test('l etat partage de A n est pas relu par B apres deconnexion', () async {
    await connecter('compte-a');
    final PortEtatPartagePersistant a = conteneur.read(
      portEtatPartagePersistantProvider,
    );
    await a.enregistrer(etatPartage(revision: 3, sessionId: 'seance-1'));
    expect((await a.lire('seance-1'))?.revision, 3);

    await connecter(null);
    await connecter('compte-b');

    final PortEtatPartagePersistant b = conteneur.read(
      portEtatPartagePersistantProvider,
    );
    expect(identical(a, b), isFalse);
    expect(
      await b.lire('seance-1'),
      isNull,
      reason: 'B relit le meme identifiant de seance : rien',
    );
  });

  test('un changement de compte direct vide aussi l etat partage', () async {
    await connecter('compte-a');
    final PortEtatPartagePersistant a = conteneur.read(
      portEtatPartagePersistantProvider,
    );
    await a.enregistrer(etatPartage(revision: 1, sessionId: 'seance-1'));

    await connecter('compte-b');

    expect(
      await conteneur.read(portEtatPartagePersistantProvider).lire('seance-1'),
      isNull,
    );
  });

  test('le meme compte garde son etat partage', () async {
    await connecter('compte-a');
    final PortEtatPartagePersistant a = conteneur.read(
      portEtatPartagePersistantProvider,
    );
    await a.enregistrer(etatPartage(revision: 1, sessionId: 'seance-1'));

    // Un rafraichissement du meme profil ne change pas l'identite.
    flux.add(const SessionState(resolue: true, profileId: 'compte-a'));
    await pumpEventQueue();

    expect(
      identical(a, conteneur.read(portEtatPartagePersistantProvider)),
      isTrue,
    );
    expect((await a.lire('seance-1'))?.revision, 1);
  });

  test('la position du dock de A n est pas celle de B', () async {
    await connecter('compte-a');
    conteneur.read(portPositionDockProvider).ecrire(PositionDock.gauche);
    expect(
      conteneur.read(portPositionDockProvider).lire(),
      PositionDock.gauche,
    );

    await connecter(null);
    await connecter('compte-b');

    expect(conteneur.read(portPositionDockProvider).lire(), isNull);
  });

  test('l etat des outils de A repart neuf pour B', () async {
    await connecter('compte-a');
    conteneur.read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
    expect(conteneur.read(etatOutilsProvider).outilActif, OutilDock.stylet);

    await connecter('compte-b');

    expect(conteneur.read(etatOutilsProvider).outilActif, isNull);
  });

  test('la file de recitation de A n est pas relue par B', () async {
    await connecter('compte-a');
    conteneur.read(recitationProvider.notifier).donnerLaParoleA('RA-AB0012');
    expect(conteneur.read(recitationProvider).actif, 'RA-AB0012');

    await connecter(null);
    await connecter('compte-b');

    expect(conteneur.read(recitationProvider).actif, isNull);
  });

  test(
    'la page de lecture et la cadence des rappels repartent neuves',
    () async {
      await connecter('compte-a');
      conteneur
          .read(lectureCoranProvider.notifier)
          .allerA(42, origine: OrigineNavigation.personnelle);
      expect(conteneur.read(lectureCoranProvider).page, 42);
      final PortRappelDiscret rappelA = conteneur.read(
        portRappelDiscretProvider,
      );

      await connecter('compte-b');

      expect(
        conteneur.read(lectureCoranProvider).page,
        const EtatLectureCoran.ouverture().page,
      );
      expect(
        identical(rappelA, conteneur.read(portRappelDiscretProvider)),
        isFalse,
      );
    },
  );
}
