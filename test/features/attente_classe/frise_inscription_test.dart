// PARCOURS-BOUT-EN-BOUT (directeur, 22/11/2026) : la frise complete de
// l'inscription, de la demande envoyee a l'enseignant affecte.
//
// Ce que le test prouve :
// - les sept etapes, dans l'ordre, et seulement des etats du serveur : rien
//   n'est franchi que le serveur n'ait dit (les etapes de la classe restent
//   « a venir » avant l'acceptation) ;
// - « a completer » remplace « acceptee » quand la direction demande une
//   precision, et l'etape « lue » est alors faite ;
// - une demande refusee n'a pas de frise ;
// - les cinq etats : chargement, contenu, vide, erreur, hors ligne ;
// - 390, 1280 et 1440 ; clair et sombre ; francais et arabe ; aucun mot
//   coupe ; aucune barre de progression.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/attente_classe/frise_inscription.dart';
import 'package:rewayah_academy/features/dossier/apprenants_demande.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/monter_recrutement.dart';

Future<void> _monter(
  WidgetTester tester, {
  required Future<DemandeFamille?> Function() demande,
  Future<DatesAdmission?> Function()? dates,
  bool horsLigne = false,
  double largeur = 390,
  ThemeMode theme = ThemeMode.light,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/attente',
  ecran: (_) => const Scaffold(
    body: SingleChildScrollView(child: BlocFriseInscription()),
  ),
  surcharges: <Override>[
    lectureDemandeFamilleProvider.overrideWithValue(demande),
    lectureDatesAdmissionProvider.overrideWithValue(
      dates ?? () async => (recueLe: null, decisionLe: null),
    ),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  themeMode: theme,
  direction: direction,
);

Future<DemandeFamille?> _enCours() async =>
    (issue: IssueDemandeFamille.enCours, precisions: null);

Future<DemandeFamille?> _aCompleter() async =>
    (issue: IssueDemandeFamille.aCompleter, precisions: 'Quel niveau ?');

EtatEtapeAttente _etat(WidgetTester tester, CleEtapeInscription c) {
  final Finder f = find.byKey(FriseInscription.cleEtape(c));
  expect(f, findsOneWidget, reason: c.name);
  final String lib = tester.getSemantics(f).label;
  final i = t.suiviAttente.etats;
  return lib.contains(i.fait)
      ? EtatEtapeAttente.fait
      : lib.contains(i.enCours)
      ? EtatEtapeAttente.enCours
      : EtatEtapeAttente.aVenir;
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });
  setUp(() => poserMonHorlogePourTest(null));
  tearDown(() => poserMonHorlogePourTest(null));

  group('etapesInscription : ce que le serveur dit, rien de plus', () {
    test('en cours : envoyee faite, lue en cours, tout le reste a venir', () {
      final List<EtapeInscription> e = etapesInscription(
        issue: IssueDemandeFamille.enCours,
        dates: (recueLe: DateTime.utc(2026, 11, 20, 9), decisionLe: null),
      );
      expect(e, hasLength(nombreEtapesInscription));
      expect(e.map((EtapeInscription x) => x.etat), <EtatEtapeAttente>[
        EtatEtapeAttente.fait,
        EtatEtapeAttente.enCours,
        EtatEtapeAttente.aVenir,
        EtatEtapeAttente.aVenir,
        EtatEtapeAttente.aVenir,
        EtatEtapeAttente.aVenir,
        EtatEtapeAttente.aVenir,
      ]);
      expect(e.first.quand, DateTime.utc(2026, 11, 20, 9));
      expect(e[2].precision, isFalse);
    });

    test('a completer : lue faite, la decision demande une precision', () {
      final List<EtapeInscription> e = etapesInscription(
        issue: IssueDemandeFamille.aCompleter,
        dates: (
          recueLe: DateTime.utc(2026, 11, 20, 9),
          decisionLe: DateTime.utc(2026, 11, 21, 7),
        ),
      );
      expect(e[1].etat, EtatEtapeAttente.fait);
      expect(e[1].quand, DateTime.utc(2026, 11, 21, 7));
      expect(e[2].etat, EtatEtapeAttente.enCours);
      expect(e[2].precision, isTrue);
      expect(
        e
            .skip(3)
            .every((EtapeInscription x) => x.etat == EtatEtapeAttente.aVenir),
        isTrue,
      );
    });

    test('sans date du serveur, aucune date', () {
      final List<EtapeInscription> e = etapesInscription(
        issue: IssueDemandeFamille.enCours,
      );
      expect(e.every((EtapeInscription x) => x.quand == null), isTrue);
    });
  });

  group('la frise rendue', () {
    testWidgets('en cours : sept etapes dans l\'ordre, aucune barre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, demande: _enCours);
      final f = t.friseInscription.etapes;
      for (final String mot in <String>[
        f.envoyee,
        f.lue,
        f.acceptee,
        f.formation,
        f.confirmee,
        f.enseignant,
        f.pret,
      ]) {
        expect(find.text(mot), findsOneWidget, reason: mot);
      }
      double y(CleEtapeInscription c) =>
          tester.getTopLeft(find.byKey(FriseInscription.cleEtape(c))).dy;
      final List<double> ys = <double>[
        for (final CleEtapeInscription c in CleEtapeInscription.values) y(c),
      ];
      for (int i = 1; i < ys.length; i++) {
        expect(ys[i - 1], lessThan(ys[i]));
      }
      expect(_etat(tester, CleEtapeInscription.envoyee), EtatEtapeAttente.fait);
      expect(_etat(tester, CleEtapeInscription.lue), EtatEtapeAttente.enCours);
      expect(
        _etat(tester, CleEtapeInscription.enseignant),
        EtatEtapeAttente.aVenir,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a completer : le mot change, jamais « acceptee »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, demande: _aCompleter);
      expect(find.text(t.friseInscription.etapes.aCompleter), findsOneWidget);
      expect(find.text(t.friseInscription.etapes.acceptee), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('inscription-dit-decision')),
        findsOneWidget,
      );
    });

    testWidgets('la date de l\'envoi dit son fuseau', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        demande: _enCours,
        dates: () async =>
            (recueLe: DateTime.utc(2026, 11, 20, 9), decisionLe: null),
      );
      final Finder date = find.byKey(
        const ValueKey<String>('inscription-date-envoyee'),
      );
      expect(date, findsOneWidget);
      // Sans ville choisie : l'heure de l'appareil, dite comme telle.
      expect(
        (tester.widget<Text>(date).data ?? '').toLowerCase(),
        contains(t.lieu.heureAppareil.toLowerCase()),
      );
    });

    testWidgets('refusee : pas de frise', (WidgetTester tester) async {
      await _monter(
        tester,
        demande: () async =>
            (issue: IssueDemandeFamille.refusee, precisions: null),
      );
      expect(
        find.byKey(const ValueKey<String>('inscription-frise')),
        findsNothing,
      );
    });
  });

  group('les cinq etats', () {
    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      final Completer<DemandeFamille?> jamais = Completer<DemandeFamille?>();
      await _monter(tester, demande: () => jamais.future);
      expect(find.byType(Skeleton), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('inscription-frise')),
        findsNothing,
      );
    });

    testWidgets('vide : aucune demande lue', (WidgetTester tester) async {
      await _monter(tester, demande: () async => null);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.friseInscription.vide), findsOneWidget);
    });

    testWidgets('erreur : une phrase et Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        demande: () async => throw const FormatException('x'),
      );
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(t.friseInscription.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('hors ligne : ce qui manque, avec Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        demande: () async => throw const FormatException('x'),
        horsLigne: true,
      );
      expect(find.text(t.friseInscription.sansDonnees), findsOneWidget);
    });
  });

  group('tailles, themes, langues', () {
    for (final (String nom, double largeur, ThemeMode theme)
        in <(String, double, ThemeMode)>[
          ('390 clair', 390, ThemeMode.light),
          ('390 sombre', 390, ThemeMode.dark),
          ('1280 clair', 1280, ThemeMode.light),
          ('1440 sombre', 1440, ThemeMode.dark),
        ]) {
      testWidgets('$nom : rien ne deborde, les sept etapes sont la', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          demande: _aCompleter,
          largeur: largeur,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        for (final CleEtapeInscription c in CleEtapeInscription.values) {
          expect(find.byKey(FriseInscription.cleEtape(c)), findsOneWidget);
        }
        final Rect frise = tester.getRect(
          find.byKey(const ValueKey<String>('inscription-frise')),
        );
        expect(frise.right, lessThanOrEqualTo(largeur));
        expect(frise.left, greaterThanOrEqualTo(0));
      });
    }
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.ar, AppLocale.en]) {
    group('en ${langue.languageCode}', () {
      setUp(() async {
        await LocaleSettings.setLocale(langue);
      });
      tearDown(() async {
        await LocaleSettings.setLocale(AppLocale.fr);
      });

      testWidgets('mots traduits, sept etapes', (WidgetTester tester) async {
        await _monter(
          tester,
          demande: _enCours,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.friseInscription.etapes.envoyee), findsOneWidget);
        expect(t.friseInscription.etapes.envoyee, isNot('Demande envoyée'));
        expect(
          find.byKey(FriseInscription.cleEtape(CleEtapeInscription.pret)),
          findsOneWidget,
        );
      });
    });
  }
}
