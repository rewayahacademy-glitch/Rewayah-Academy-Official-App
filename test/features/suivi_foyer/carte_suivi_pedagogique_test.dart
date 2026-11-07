// SUIVI-ELEVE (07/11/2026) : « Où j'en suis » / « Où en est `prénom` ».
// Lecture de la ligne serveur, lignes cachees quand la donnee manque, et les
// etats : chargement, contenu, vide, erreur, hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/carte_suivi_pedagogique.dart';

import '../../support/harnais.dart';

class _FauxPort implements PortSuiviPedagogique {
  _FauxPort({this.rendu, this.erreur, this.attente});

  SuiviPedagogique? rendu;
  Error? erreur;
  Completer<void>? attente;
  final List<String> lus = <String>[];

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async {
    lus.add(eleveId);
    if (attente case final Completer<void> c) await c.future;
    if (erreur case final Error e) throw e;
    return rendu;
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
        portSuiviPedagogiqueProvider.overrideWithValue(port),
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

    test('les trois rythmes du serveur ont leur libelle', () {
      expect(
        libelleRythme(_complet),
        t.suiviPedagogique.dansLesTemps(ecoulees: '5', prevue: '14'),
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
        t.suiviPedagogique.auDelaDuPrevu(ecoulees: '16', prevue: '14'),
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
        find.text(t.suiviPedagogique.dansLesTemps(ecoulees: '5', prevue: '14')),
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
        find.text(t.suiviPedagogique.dansLesTemps(ecoulees: '5', prevue: '14')),
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
          portSuiviPedagogiqueProvider.overrideWithValue(port),
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
