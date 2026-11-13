// SUIVI-ELEVE (07/11/2026) : « Où j'en suis » / « Où en est `prénom` ».
// Lecture de la ligne serveur, lignes cachees quand la donnee manque, et les
// etats : chargement, contenu, vide, erreur, hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/capacites/progression_famille_supabase.dart'
    show dateDernierJalon;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/carte_suivi_pedagogique.dart';

import '../../support/harnais.dart';

class _FauxPort implements PortMaProgression {
  _FauxPort({
    this.rendu,
    this.erreur,
    this.attente,
    this.cycle = const <EtapeDuCycle>[],
    this.sourates,
    this.reglage,
  });

  SuiviPedagogique? rendu;
  List<EtapeDuCycle> cycle;
  SouratesValidees? sourates;
  ReglageEtape? reglage;
  Error? erreur;
  Completer<void>? attente;
  final List<String> lus = <String>[];

  @override
  Future<MaProgression?> pourEleve(String eleveId) async {
    lus.add(eleveId);
    if (attente case final Completer<void> c) await c.future;
    if (erreur case final Error e) throw e;
    if (rendu == null && sourates == null) return null;
    return MaProgression(
      suivi: rendu,
      cycle: cycle,
      sourates: sourates,
      reglage: reglage,
    );
  }
}

class _FauxFamille implements PortProgressionFamille {
  const _FauxFamille({this.rendu, this.refus = false});

  final ProgressionEleve? rendu;
  final bool refus;

  @override
  Future<ProgressionEleve> progression(String eleveId) async {
    if (refus) throw StateError('progression indisponible');
    return rendu!;
  }
}

const SuiviPedagogique _complet = SuiviPedagogique(
  etapeNom: 'Lire avec les voyelles',
  etapeOrdre: 2,
  objectifs: <String>['Lit les voyelles courtes', 'Enchaine deux syllabes'],
  dureePrevueSemaines: 14,
  dateLimite: null,
  semainesEcoulees: 5,
  rythme: Rythme.dansLesTemps,
  pageReprise: 42,
);

Future<void> _monter(
  WidgetTester tester,
  _FauxPort port, {
  String? eleveId = 'eleve-1',
  String? prenom,
  bool horsLigne = false,
  InterfaceMode mode = InterfaceMode.standard,
  List<Override> autres = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: CarteSuiviPedagogique(eleveId: eleveId, prenom: prenom),
        ),
      ),
      surcharges: <Override>[
        portMaProgressionProvider.overrideWithValue(port),
        ...autres,
        horsLigneProvider.overrideWith(
          (Ref ref) => Stream<bool>.value(horsLigne),
        ),
      ],
      mode: mode,
    ),
  );
}

SuiviPedagogique _toutRenseigne() => SuiviPedagogique(
  etapeNom: _complet.etapeNom,
  etapeOrdre: 2,
  objectifs: _complet.objectifs,
  dureePrevueSemaines: 14,
  dateLimite: DateTime(2027, 3),
  semainesEcoulees: 5,
  rythme: Rythme.dansLesTemps,
  pageReprise: 42,
);

void main() {
  group('Lecture de la ligne serveur', () {
    test('une ligne complete', () {
      final SuiviPedagogique? s = SuiviPedagogique.depuisJson(<Object?>[
        <String, Object?>{
          'etape_nom': ' Lire avec les voyelles ',
          'etape_ordre': 2,
          'objectifs': <Object?>['a', '', null, 'b'],
          'duree_prevue_semaines': 14,
          'date_limite': '2027-03-01',
          'semaines_ecoulees': 16,
          'rythme': 'au_dela_du_prevu',
          'page_reprise': 42,
        },
      ]);
      expect(s, isNotNull);
      expect(s!.etapeNom, 'Lire avec les voyelles');
      expect(s.objectifs, <String>['a', 'b']);
      expect(s.dateLimite, DateTime(2027, 3));
      expect(s.rythme, Rythme.auDelaDuPrevu);
      expect(s.pageReprise, 42);
    });

    test('aucune ligne, ou sans etape : rien', () {
      expect(SuiviPedagogique.depuisJson(<Object?>[]), isNull);
      expect(SuiviPedagogique.depuisJson(null), isNull);
      expect(
        SuiviPedagogique.depuisJson(<String, Object?>{'etape_nom': ' '}),
        isNull,
      );
    });

    test('rythme inconnu ou page hors du Mushaf : jamais suppose', () {
      final SuiviPedagogique? s = SuiviPedagogique.depuisJson(<String, Object?>{
        'etape_nom': 'Les lettres',
        'rythme': 'en_avance',
        'page_reprise': 900,
      });
      expect(s!.rythme, Rythme.inconnu);
      expect(s.pageReprise, isNull);
      expect(libelleRythme(s), isNull);
    });

    test('une semaine ecoulee : au singulier', () {
      expect(
        libelleRythme(
          const SuiviPedagogique(
            etapeNom: 'x',
            etapeOrdre: 1,
            dureePrevueSemaines: 3,
            semainesEcoulees: 1,
            rythme: Rythme.dansLesTemps,
          ),
        ),
        'Dans la durée prévue\u00a0: 1 semaine sur 3',
      );
    });

    test('les trois rythmes du serveur ont leur libelle', () {
      expect(
        libelleRythme(_complet),
        t.suiviPedagogique.dansLesTemps(ecoulees: 5, prevue: '14'),
      );
      expect(
        libelleRythme(
          const SuiviPedagogique(
            etapeNom: 'x',
            etapeOrdre: 1,
            dureePrevueSemaines: 14,
            semainesEcoulees: 16,
            rythme: Rythme.auDelaDuPrevu,
          ),
        ),
        t.suiviPedagogique.auDelaDuPrevu(ecoulees: 16, prevue: '14'),
      );
      expect(
        libelleRythme(
          const SuiviPedagogique(
            etapeNom: 'x',
            etapeOrdre: 1,
            rythme: Rythme.dateLimiteDepassee,
          ),
        ),
        t.suiviPedagogique.dateLimiteDepassee,
      );
    });
  });

  group('Le bloc', () {
    testWidgets('contenu : etape, page, objectifs, date limite, rythme', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(
        rendu: SuiviPedagogique(
          etapeNom: _complet.etapeNom,
          etapeOrdre: 2,
          objectifs: _complet.objectifs,
          dureePrevueSemaines: 14,
          dateLimite: DateTime(2027, 3),
          semainesEcoulees: 5,
          rythme: Rythme.dansLesTemps,
          pageReprise: 42,
        ),
      );
      await _monter(tester, port, prenom: 'Sofia');
      await tester.pumpAndSettle();

      expect(port.lus, <String>['eleve-1']);
      expect(find.text(t.suiviPedagogique.titre(prenom: 'Sofia')), findsOne);
      expect(find.text('Lire avec les voyelles'), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.reprisePage(page: '42')),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.aFinirAvant), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.dansLesTemps(ecoulees: 5, prevue: '14')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('interface normale (eleve adulte) : tout, rythme et date '
        'limite compris', (WidgetTester tester) async {
      await _monter(tester, _FauxPort(rendu: _toutRenseigne()));
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.titreSoi), findsOneWidget);
      expect(find.text(_complet.etapeNom), findsOneWidget);
      expect(find.text(t.suiviPedagogique.objectifs), findsOneWidget);
      expect(find.text(t.suiviPedagogique.reprise), findsOneWidget);
      expect(find.text(t.suiviPedagogique.aFinirAvant), findsOneWidget);
      expect(find.text(t.suiviPedagogique.rythme), findsOneWidget);
    });

    testWidgets('Interface guidee (eleve mineur) : etape, objectifs, reprise ; '
        'ni rythme ni date limite', (WidgetTester tester) async {
      await _monter(
        tester,
        _FauxPort(rendu: _toutRenseigne()),
        mode: InterfaceMode.enfant,
      );
      await tester.pumpAndSettle();
      expect(find.text(_complet.etapeNom), findsOneWidget);
      expect(find.text(t.suiviPedagogique.objectifs), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.reprisePage(page: '42')),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.aFinirAvant), findsNothing);
      expect(find.text(t.suiviPedagogique.rythme), findsNothing);
      expect(
        find.text(t.suiviPedagogique.dansLesTemps(ecoulees: 5, prevue: '14')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans page, sans date, rythme inconnu : lignes cachees', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(
          rendu: const SuiviPedagogique(etapeNom: 'Les lettres', etapeOrdre: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Les lettres'), findsOneWidget);
      expect(find.text(t.suiviPedagogique.titreSoi), findsOneWidget);
      expect(find.text(t.suiviPedagogique.reprise), findsNothing);
      expect(find.text(t.suiviPedagogique.aFinirAvant), findsNothing);
      expect(find.text(t.suiviPedagogique.rythme), findsNothing);
    });

    testWidgets('vide : sans Classe ni etape, rien n est pose', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _FauxPort());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsNothing,
      );
      expect(find.byType(EtatSysteme), findsNothing);
    });

    testWidgets('chargement : un squelette tient la place', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(
        rendu: _complet,
        attente: Completer<void>(),
      );
      await _monter(tester, port);
      await tester.pump();
      expect(find.byType(Skeleton), findsOneWidget);
      port.attente!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
      expect(find.text(_complet.etapeNom), findsOneWidget);
    });

    testWidgets('erreur : la phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(erreur: StateError('reseau'));
      await _monter(tester, port);
      await tester.pumpAndSettle();

      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.text(t.suiviPedagogique.erreur), findsOneWidget);

      port
        ..erreur = null
        ..rendu = _complet;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(find.text(_complet.etapeNom), findsOneWidget);
    });

    testWidgets('hors ligne : l etat hors ligne', (WidgetTester tester) async {
      await _monter(
        tester,
        _FauxPort(erreur: StateError('reseau')),
        horsLigne: true,
      );
      await tester.pumpAndSettle();
      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.nature, NatureEtat.horsLigne);
    });
  });

  group('MA-PROGRESSION-ECRAN : etapes, sourates, reglage', () {
    final List<EtapeDuCycle> cycle = <EtapeDuCycle>[
      EtapeDuCycle(
        ordre: 1,
        nom: 'Les lettres',
        statut: StatutEtape.franchie,
        atteinteLe: DateTime(2026, 9, 7),
      ),
      const EtapeDuCycle(
        ordre: 2,
        nom: 'Lire avec les voyelles',
        statut: StatutEtape.enCours,
      ),
      const EtapeDuCycle(
        ordre: 3,
        nom: 'Lire sans voyelles',
        statut: StatutEtape.aVenir,
      ),
    ];
    const ValueKey<String> etape1 = ValueKey<String>(
      'suivi-pedagogique-etape-1',
    );

    test('la reponse de ma_progression se lit en entier', () {
      final MaProgression? p = MaProgression.depuisJson(<String, Object?>{
        'etape': <String, Object?>{
          'nom': 'Lire avec les voyelles',
          'ordre': 2,
          'objectifs': <Object?>['a'],
          'duree_prevue_semaines': 14,
          'date_limite': '2027-03-01',
          'semaines_ecoulees': 5,
          'rythme': 'dans_les_temps',
          'page_reprise': 24,
        },
        'etapes_du_cycle': <Object?>[
          <String, Object?>{
            'ordre': 1,
            'nom': 'Les lettres',
            'statut': 'franchie',
            'atteinte_le': '2026-09-07T10:00:00Z',
          },
          <String, Object?>{'ordre': 2, 'nom': 'Lire', 'statut': 'en_cours'},
          <String, Object?>{'ordre': 3, 'nom': 'x', 'statut': 'inconnu'},
          'illisible',
        ],
        'sourates': <String, Object?>{
          'sourates_validees': 3,
          'sourates_total': 17,
        },
        'reglage': <String, Object?>{
          'heures_revision_semaine': 2.5,
          'repetitions_estimees': 40,
        },
      });
      expect(p!.suivi!.etapeNom, 'Lire avec les voyelles');
      expect(p.suivi!.pageReprise, 24);
      expect(p.cycle.map((EtapeDuCycle e) => e.statut), <StatutEtape>[
        StatutEtape.franchie,
        StatutEtape.enCours,
      ]);
      expect(p.cycle.first.atteinteLe, isNotNull);
      expect(p.sourates!.validees, 3);
      expect(p.reglage!.heuresRevisionSemaine, 2.5);
      expect(p.reglage!.repetitionsEstimees, 40);
    });

    test('sans Classe : les sourates seules ; rien du tout : rien', () {
      final MaProgression? seules = MaProgression.depuisJson(<String, Object?>{
        'etape': null,
        'etapes_du_cycle': <Object?>[],
        'sourates': <String, Object?>{
          'sourates_validees': 2,
          'sourates_total': 17,
        },
        'reglage': null,
      });
      expect(seules!.suivi, isNull);
      expect(seules.cycle, isEmpty);
      expect(seules.sourates!.validees, 2);
      expect(
        MaProgression.depuisJson(<String, Object?>{
          'etape': null,
          'etapes_du_cycle': <Object?>[],
          'sourates': null,
          'reglage': null,
        }),
        isNull,
      );
      expect(MaProgression.depuisJson(null), isNull);
    });

    test('un reglage vide ou nul n est jamais montre', () {
      final MaProgression? p = MaProgression.depuisJson(<String, Object?>{
        'etape': <String, Object?>{'nom': 'x', 'ordre': 1},
        'reglage': <String, Object?>{
          'heures_revision_semaine': 0,
          'repetitions_estimees': null,
        },
      });
      expect(p!.reglage, isNull);
    });

    testWidgets('les etapes dans l ordre : franchie avec sa date, en cours, '
        'a venir', (WidgetTester tester) async {
      await _monter(tester, _FauxPort(rendu: _complet, cycle: cycle));
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.etapesTitre), findsOneWidget);
      expect(find.byKey(etape1), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(etape1),
          matching: find.text('Les lettres'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.suiviPedagogique.etapeFranchieLe(
            numero: '7',
            mois: t.commun.dates.mois[8],
            annee: '2026',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.etapeEnCours), findsOneWidget);
      expect(find.text(t.suiviPedagogique.etapeAVenir), findsOneWidget);
      final double haut = tester.getTopLeft(find.text('Les lettres')).dy;
      final double bas = tester.getTopLeft(find.text('Lire sans voyelles')).dy;
      expect(haut, lessThan(bas));
    });

    testWidgets('les sourates : « n sur 17 » ; cachees quand le serveur ne '
        'les rend pas', (WidgetTester tester) async {
      await _monter(
        tester,
        _FauxPort(
          rendu: _complet,
          sourates: const SouratesValidees(validees: 3, total: 17),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.sourates), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.souratesDe(validees: 3, total: 17)),
        findsOneWidget,
      );
      await _monter(tester, _FauxPort(rendu: _complet));
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.sourates), findsNothing);
    });

    testWidgets('sans Classe, les sourates validees restent montrees', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(sourates: const SouratesValidees(validees: 2, total: 17)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.titreSoi), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.souratesDe(validees: 2, total: 17)),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.etape), findsNothing);
      expect(find.text(t.suiviPedagogique.etapesTitre), findsNothing);
    });

    testWidgets('le reglage de la direction : montre quand rempli, rien '
        'sinon, jamais a l enfant en Interface guidee', (
      WidgetTester tester,
    ) async {
      const ReglageEtape regle = ReglageEtape(
        heuresRevisionSemaine: 2.5,
        repetitionsEstimees: 40,
      );
      await _monter(tester, _FauxPort(rendu: _complet, reglage: regle));
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.revision), findsOneWidget);
      expect(find.text(t.suiviPedagogique.repetitions), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.repetitionsNombre(n: 40)),
        findsOneWidget,
      );
      await _monter(tester, _FauxPort(rendu: _complet));
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.revision), findsNothing);
      expect(find.text(t.suiviPedagogique.repetitions), findsNothing);
      await _monter(
        tester,
        _FauxPort(rendu: _complet, reglage: regle),
        mode: InterfaceMode.enfant,
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.revision), findsNothing);
    });

    final ProgressionEleve niveauEtJalon = ProgressionEleve(
      eleveId: 'eleve-1',
      niveauHumain: 'Les bases',
      jalons: const <String>['Les lettres', 'Les voyelles'],
      dernierJalonLe: DateTime(2026, 10, 14),
    );
    List<Override> famille(PortProgressionFamille p) => <Override>[
      portProgressionFamilleProvider.overrideWithValue(p),
    ];

    testWidgets('l ancien cas : adulte sans Classe ni etape, avec un niveau '
        'et un jalon : les deux se lisent', (WidgetTester tester) async {
      await _monter(
        tester,
        _FauxPort(),
        autres: famille(_FauxFamille(rendu: niveauEtJalon)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.titreSoi), findsOneWidget);
      expect(find.text(t.suiviPedagogique.niveauDeclare), findsOneWidget);
      expect(find.text('Les bases'), findsOneWidget);
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(
        find.text('Les lettres · 14 ${t.commun.dates.mois[9]} 2026'),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.etape), findsNothing);
    });

    testWidgets('avec une etape : le dernier jalon, pas le niveau declare', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(rendu: _complet),
        autres: famille(_FauxFamille(rendu: niveauEtJalon)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(find.text(t.suiviPedagogique.niveauDeclare), findsNothing);
      expect(find.text(_complet.etapeNom), findsOneWidget);
    });

    testWidgets('lecture refusee (eleve mineur) ou en echec : ni niveau ni '
        'jalon, le bloc reste', (WidgetTester tester) async {
      await _monter(
        tester,
        _FauxPort(rendu: _complet),
        autres: famille(const _FauxFamille(refus: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.suiviPedagogique.dernierJalon), findsNothing);
      expect(find.text(t.suiviPedagogique.niveauDeclare), findsNothing);
      expect(find.text(_complet.etapeNom), findsOneWidget);
      // Sans etape et refuse : rien du tout.
      await _monter(
        tester,
        _FauxPort(),
        autres: famille(const _FauxFamille(refus: true)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsNothing,
      );
    });

    test('la date du dernier jalon : la premiere seance qui en porte un', () {
      expect(
        dateDernierJalon(<Object?>[
          <String, Object?>{'publie_le': '2026-11-01T10:00:00Z'},
          <String, Object?>{
            'jalon_humain': 'Les lettres',
            'publie_le': '2026-10-14T10:00:00Z',
          },
          <String, Object?>{
            'jalon_humain': 'Avant',
            'publie_le': '2026-09-01T10:00:00Z',
          },
        ]),
        DateTime.parse('2026-10-14T10:00:00Z'),
      );
      expect(dateDernierJalon(<Object?>[]), isNull);
      expect(dateDernierJalon(null), isNull);
    });

    testWidgets('au moins ce que l ancienne ligne de Ma classe montrait : le '
        'niveau (etape en cours) et le dernier jalon (derniere etape '
        'franchie)', (WidgetTester tester) async {
      await _monter(tester, _FauxPort(rendu: _complet, cycle: cycle));
      await tester.pumpAndSettle();
      // Le niveau : l'etape en cours, en toutes lettres.
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      // Le dernier jalon : la derniere etape franchie, avec sa date.
      expect(
        find.descendant(
          of: find.byKey(etape1),
          matching: find.text(
            t.suiviPedagogique.etapeFranchieLe(
              numero: '7',
              mois: t.commun.dates.mois[8],
              annee: '2026',
            ),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('Suivi de l eleve : le bloc en tete, pour l eleve connecte, '
      'meme sans seance passee', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _FauxPort port = _FauxPort(rendu: _complet);
    await tester.pumpWidget(
      hote(
        SuiviElevePage(horloge: () => DateTime(2026, 11, 7, 10)),
        surcharges: <Override>[
          serviceSuiviProvider.overrideWithValue(
            FauxServiceSuivi(seancesRendues: const <Seance>[]),
          ),
          portMaProgressionProvider.overrideWithValue(port),
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(
              const SessionState(
                resolue: true,
                role: AppRole.student,
                profileId: 'eleve-moi',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(port.lus, <String>['eleve-moi']);
    expect(find.text(t.suiviPedagogique.titreSoi), findsOneWidget);
    expect(find.text(_complet.etapeNom), findsOneWidget);
    expect(find.text(t.eleve.suivi.vide), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
