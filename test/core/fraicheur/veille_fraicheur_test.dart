// Fiche « Fraicheur et notifications » (27/10/2026), lignes 1, 2, 4, 5, 6,
// 8, 9 : la veille de fraicheur suit la personne connectee, et chaque signal
// du serveur fait relire la famille concernee, sans geste. Au retour du
// reseau, elle se reabonne et relit tout.
//
// Le port est un faux canal pilote par le test : aucun Supabase. Les lectures
// observees sont deux ports reels de l'application, remplaces par des faux
// qui comptent leurs appels.

import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/fraicheur/port_veille.dart';
import 'package:rewayah_academy/core/fraicheur/veille_fraicheur.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart'
    show classesMembreProvider;

class _SourcePilotee implements SourceSession {
  _SourcePilotee(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

/// Un canal pilote : le test y pousse les signaux et compte les ecoutes.
class _VeillePilotee implements PortVeille {
  final List<StreamController<SignalVeille>> ecoutes =
      <StreamController<SignalVeille>>[];

  /// Le nombre d'ecoutes fermees par l'application.
  int fermees = 0;

  @override
  Stream<SignalVeille> ecouter() {
    // Ferme par l'application a l'annulation (compte dans [fermees]).
    // ignore: close_sinks
    final StreamController<SignalVeille> c = StreamController<SignalVeille>();
    c.onCancel = () {
      fermees++;
    };
    ecoutes.add(c);
    return c.stream;
  }

  /// Emet un signal sur la derniere ecoute ouverte.
  void signaler(SignalVeille signal) => ecoutes.last.add(signal);
}

class _ReseauPilote implements ServiceReseau {
  // Ferme dans `tearDown`.
  // ignore: close_sinks
  final StreamController<bool> flux = StreamController<bool>.broadcast();

  @override
  Stream<bool> horsLigne() => flux.stream;
}

/// Compte les lectures des classes.
class _ClassesComptees implements PortClassesFoyer {
  int lectures = 0;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    lectures++;
    return const <ClasseFoyer>[];
  }

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async => null;
}

/// Compte les lectures des seances.
class _SeancesComptees implements PortSeancesFamille {
  int lectures = 0;

  @override
  Future<SeanceFamille?> prochaine(String eleveId) async {
    lectures++;
    return null;
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) async => null;

  @override
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  }) async => const <SeanceFamille>[];

  @override
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId}) async =>
      null;

  @override
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  }) async => const <SeanceFamille>[];

  @override
  Future<DateTime> maintenantServeurUtc() async => DateTime.utc(2026, 10, 27);

  @override
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId}) =>
      const Stream<SeanceFamille>.empty();
}

/// L'accueil de l'eleve en Interface guidee, qui compte ses lectures.
class _AccueilCompte implements PortAccueilAccessibilite {
  int lectures = 0;

  @override
  Future<DonneesAccueilAccessibilite> lire() async {
    lectures++;
    return const DonneesAccueilAccessibilite(
      prenom: 'Fixture',
      tutoiement: true,
      espace: null,
    );
  }
}

void main() {
  late StreamController<SessionState> session;
  late _VeillePilotee veille;
  late _ReseauPilote reseau;
  late _ClassesComptees classes;
  late _SeancesComptees seances;
  late _AccueilCompte accueil;
  late ProviderContainer conteneur;

  Future<void> connecter(String? profil) async {
    session.add(
      profil == null
          ? const SessionState.deconnecte()
          : SessionState(resolue: true, profileId: profil),
    );
    await pumpEventQueue();
  }

  Future<void> signaler(SignalVeille signal) async {
    veille.signaler(signal);
    await pumpEventQueue();
  }

  setUp(() {
    session = StreamController<SessionState>.broadcast();
    veille = _VeillePilotee();
    reseau = _ReseauPilote();
    classes = _ClassesComptees();
    seances = _SeancesComptees();
    accueil = _AccueilCompte();
    conteneur = ProviderContainer(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(_SourcePilotee(session)),
        portVeilleProvider.overrideWithValue(veille),
        serviceReseauProvider.overrideWithValue(reseau),
        portClassesFoyerProvider.overrideWithValue(classes),
        portSeancesFamilleProvider.overrideWithValue(seances),
        portAccueilAccessibiliteProvider.overrideWithValue(accueil),
      ],
    );
    // Comme dans l'application : la session, la veille et les lectures des
    // ecrans sont gardees vivantes.
    conteneur
      ..listen(sessionProvider, (_, _) {})
      ..listen(veilleFraicheurProvider, (_, _) {})
      ..listen(classesMembreProvider('e1'), (_, _) {})
      ..listen(prochaineSeanceProvider('e1'), (_, _) {})
      ..listen(donneesAccueilAccessibiliteProvider, (_, _) {});
  });

  tearDown(() async {
    conteneur.dispose();
    await session.close();
    await reseau.flux.close();
  });

  test('aucune veille sans personne connectee', () async {
    await pumpEventQueue();
    expect(veille.ecoutes, isEmpty);
  });

  test(
    'la veille s ouvre a la connexion et se ferme a la deconnexion',
    () async {
      await connecter('p1');
      expect(veille.ecoutes, hasLength(1));
      expect(veille.fermees, 0);

      await connecter(null);
      expect(veille.fermees, 1);
      expect(veille.ecoutes, hasLength(1));
    },
  );

  test('lignes 4, 5, 6, 8 : un changement des classes fait relire les classes seulement', () async {
    await connecter('p1');
    final int classesAvant = classes.lectures;
    final int seancesAvant = seances.lectures;

    for (final String table in <String>[
      'groupes',
      'groupe_membres',
      'groupe_creneaux',
    ]) {
      final int c = classes.lectures;
      await signaler(ChangementTable(table));
      expect(classes.lectures, c + 1, reason: table);
    }
    expect(classes.lectures, classesAvant + 3);
    expect(seances.lectures, seancesAvant);
  });

  test(
    'ligne 9 : un changement des seances fait relire les seances seulement',
    () async {
      await connecter('p1');
      final int classesAvant = classes.lectures;
      final int seancesAvant = seances.lectures;

      await signaler(const ChangementTable('sessions'));

      expect(seances.lectures, seancesAvant + 1);
      expect(classes.lectures, classesAvant);
    },
  );

  // Appareil appaire (29/10/2026) : l'accueil de l'eleve en Interface guidee
  // suit lui aussi les classes et les seances.
  test(
    'un changement des seances ou des classes relit l accueil guide',
    () async {
      await connecter('p1');
      final int avant = accueil.lectures;
      await signaler(const ChangementTable('sessions'));
      expect(accueil.lectures, avant + 1);
      await signaler(const ChangementTable('groupe_membres'));
      expect(accueil.lectures, avant + 2);
    },
  );

  test('une table inconnue ne fait rien relire', () async {
    await connecter('p1');
    final int classesAvant = classes.lectures;
    final int seancesAvant = seances.lectures;

    await signaler(const ChangementTable('audit_logs'));

    expect(classes.lectures, classesAvant);
    expect(seances.lectures, seancesAvant);
  });

  test('ligne 1 : le canal (re)joint fait tout relire', () async {
    await connecter('p1');
    final int classesAvant = classes.lectures;
    final int seancesAvant = seances.lectures;

    await signaler(const CanalRejoint());

    expect(classes.lectures, classesAvant + 1);
    expect(seances.lectures, seancesAvant + 1);
  });

  test(
    'ligne 2 : au retour du reseau, nouvelle ecoute et tout est relu',
    () async {
      await connecter('p1');
      reseau.flux.add(true);
      await pumpEventQueue();
      final int classesAvant = classes.lectures;
      final int seancesAvant = seances.lectures;
      expect(veille.ecoutes, hasLength(1));

      reseau.flux.add(false);
      await pumpEventQueue();

      expect(veille.ecoutes, hasLength(2));
      expect(veille.fermees, 1);
      expect(classes.lectures, classesAvant + 1);
      expect(seances.lectures, seancesAvant + 1);
    },
  );

  test('le passage en ligne sans coupure ne relit rien', () async {
    await connecter('p1');
    reseau.flux.add(false);
    await pumpEventQueue();
    final int classesAvant = classes.lectures;

    reseau.flux.add(false);
    await pumpEventQueue();

    expect(veille.ecoutes, hasLength(1));
    expect(classes.lectures, classesAvant);
  });

  test('famillesPourSignal est pure et complete', () {
    expect(
      famillesPourSignal(const ChangementTable('groupes')),
      <FamilleLecture>{FamilleLecture.classes},
    );
    expect(
      famillesPourSignal(const ChangementTable('sessions')),
      <FamilleLecture>{FamilleLecture.seances},
    );
    expect(famillesPourSignal(const ChangementTable('x')), isEmpty);
    expect(
      famillesPourSignal(const CanalRejoint()),
      FamilleLecture.values.toSet(),
    );
    for (final String table in tablesVeillees) {
      expect(familleDeLaTable(table), isNotNull, reason: table);
    }
    for (final FamilleLecture famille in FamilleLecture.values) {
      expect(lecturesVeillees[famille], isNotEmpty, reason: famille.name);
    }
  });
}
