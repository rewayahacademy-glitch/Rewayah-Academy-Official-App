// ADM-15 : Configuration > Regles, avec la ligne « Classes au plus par
// enseignant » (decision du directeur du 22/10/2026). Les etats de la page :
// chargement, contenu, erreur ; la ligne propre a un serveur a jour ; l'ecriture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_configuration_regles/regles_page.dart';

import '../../support/harnais.dart';

/// Un service de configuration en memoire : ce que `app_config` rendrait.
class _Config implements ServiceConfiguration {
  _Config(this.valeurs);

  final Map<String, Object?> valeurs;
  final List<(String, Object)> ecritures = <(String, Object)>[];
  Object? erreurLecture;
  Object? erreurEcriture;
  Completer<void>? attente;

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async {
    await attente?.future;
    final Object? e = erreurLecture;
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
    return <ValeurConfig>[
      for (final String c in cles) ValeurConfig(cle: c, valeur: valeurs[c]),
    ];
  }

  @override
  Future<void> ecrire(String cle, Object valeur) async {
    final Object? e = erreurEcriture;
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
    ecritures.add((cle, valeur));
    valeurs[cle] = valeur;
  }
}

Map<String, Object?> _toutesLesCles({
  int? classesMax = 3,
  Map<String, Object?>? remplacement = _a3,
}) => <String, Object?>{
  'absence_threshold_minutes': 5,
  'session_duration_minutes': 60,
  'session_paid_minimum_minutes': 45,
  'break_minutes_between_sessions': 30,
  'max_students_per_teacher': 5,
  'matching_horizon_weeks': 4,
  'camera_auto_allow_min_age': 11,
  'child_ui_mode_max_age': 8,
  'max_devices_per_student': 2,
  'max_concurrent_sessions_per_profile': 1,
  'enseignant.classes_max': ?classesMax,
  ...?remplacement,
};

const Map<String, Object?> _a3 = <String, Object?>{
  'remplacement.avertissement_minutes': 3,
  'remplacement.perte_acces_minutes': 8,
  'remplacement.debut_remplacant_minutes': 11,
};

Future<void> _monter(
  WidgetTester tester,
  _Config config, {
  Size taille = const Size(390, 1200),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const ReglesPage(),
      surcharges: <Override>[
        serviceConfigurationProvider.overrideWithValue(config),
        peutReglerPolitiqueKycProvider.overrideWithValue(false),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('chargement : un squelette, aucune ligne', (
    WidgetTester tester,
  ) async {
    final _Config config = _Config(_toutesLesCles())
      ..attente = Completer<void>();
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        const ReglesPage(),
        surcharges: <Override>[
          serviceConfigurationProvider.overrideWithValue(config),
          peutReglerPolitiqueKycProvider.overrideWithValue(false),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text(t.admin.regles.classesParEnseignant), findsNothing);
    config.attente!.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.admin.regles.classesParEnseignant), findsOneWidget);
  });

  testWidgets('la ligne « Classes au plus par enseignant » dit son nombre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Config(_toutesLesCles()));
    final Finder titre = find.text(t.admin.regles.classesParEnseignant);
    await tester.ensureVisible(titre);
    await tester.pump();
    expect(titre, findsOneWidget);
    // Le detail dit ce que le reglage change et ce qu'il ne change pas.
    expect(
      find.text(t.admin.regles.classesParEnseignantDetail),
      findsOneWidget,
    );
    expect(t.admin.regles.classesParEnseignantDetail, contains('baisse'));
    expect(
      t.admin.regles.classesParEnseignantDetail,
      contains('ne retire aucune Classe'),
    );
    // Les autres reglages sont toujours la.
    expect(find.text(t.admin.regles.dureeSeance), findsOneWidget);
    expect(find.text(t.admin.regles.seancesSimultanees), findsOneWidget);
  });

  testWidgets(
    'un serveur sans le reglage : la ligne n est pas montree, les autres oui',
    (WidgetTester tester) async {
      await _monter(tester, _Config(_toutesLesCles(classesMax: null)));
      expect(find.text(t.admin.regles.classesParEnseignant), findsNothing);
      expect(find.text(t.admin.regles.dureeSeance), findsOneWidget);
    },
  );

  testWidgets('modifier le nombre l ecrit sous sa cle, puis relit', (
    WidgetTester tester,
  ) async {
    final _Config config = _Config(_toutesLesCles());
    await _monter(tester, config);
    final Finder titre = find.text(t.admin.regles.classesParEnseignant);
    await tester.ensureVisible(titre);
    await tester.pump();
    await tester.tap(titre);
    await tester.pumpAndSettle();
    // Des valeurs proposees, dont 3 (le defaut) et 5.
    expect(find.text('5'), findsWidgets);
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.regles.envoyer));
    await tester.pumpAndSettle();
    expect(config.ecritures, <(String, Object)>[(cleClassesParEnseignant, 5)]);
    expect(cleClassesParEnseignant, 'enseignant.classes_max');
  });

  testWidgets('un refus du serveur se dit, rien ne change', (
    WidgetTester tester,
  ) async {
    final _Config config = _Config(_toutesLesCles())
      ..erreurEcriture = Exception('entier de 1 a 80');
    await _monter(tester, config);
    final Finder titre = find.text(t.admin.regles.classesParEnseignant);
    await tester.ensureVisible(titre);
    await tester.pump();
    await tester.tap(titre);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.regles.envoyer));
    await tester.pumpAndSettle();
    expect(find.textContaining('entier de 1 a 80'), findsOneWidget);
    expect(config.ecritures, isEmpty);
  });

  testWidgets('erreur de lecture : la phrase et « Reessayer »', (
    WidgetTester tester,
  ) async {
    final _Config config = _Config(_toutesLesCles())
      ..erreurLecture = Exception('boum');
    await _monter(tester, config);
    expect(find.text(t.admin.regles.erreur), findsOneWidget);
    config.erreurLecture = null;
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pumpAndSettle();
    expect(find.text(t.admin.regles.classesParEnseignant), findsOneWidget);
  });

  testWidgets('en arabe, la ligne a ses textes, sans « أجر »', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _monter(tester, _Config(_toutesLesCles()));
    final Finder titre = find.text(t.admin.regles.classesParEnseignant);
    expect(t.admin.regles.classesParEnseignant, isNot(contains('أجر')));
    await tester.ensureVisible(titre);
    await tester.pump();
    expect(titre, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('A3 : quand l enseignant n a pas rejoint la salle', () {
    Future<void> ouvrir(WidgetTester tester, String titre) async {
      final Finder f = find.text(titre);
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('la section montre les trois delais, en minutes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _Config(_toutesLesCles()));
      final Finder section = find.text(t.admin.regles.remplacementSection);
      await tester.ensureVisible(section);
      await tester.pump();
      expect(section, findsOneWidget);
      expect(find.text(t.admin.regles.remplacementIntro), findsOneWidget);
      expect(
        find.text(t.admin.regles.remplacementAvertissement),
        findsOneWidget,
      );
      expect(find.text(t.admin.regles.remplacementPerte), findsOneWidget);
      expect(find.text(t.admin.regles.remplacementObjectif), findsOneWidget);
      expect(find.textContaining('8'), findsWidgets);
      expect(clesRemplacement, <String>[
        'remplacement.avertissement_minutes',
        'remplacement.perte_acces_minutes',
        'remplacement.debut_remplacant_minutes',
      ]);
    });

    testWidgets('un serveur sans A3 : la section n est pas montree', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _Config(_toutesLesCles(remplacement: null)));
      expect(find.text(t.admin.regles.remplacementSection), findsNothing);
      expect(find.text(t.admin.regles.classesParEnseignant), findsOneWidget);
    });

    testWidgets(
      'la perte de la seance ne se choisit qu entre les deux autres delais',
      (WidgetTester tester) async {
        final _Config config = _Config(_toutesLesCles());
        await _monter(tester, config);
        await ouvrir(tester, t.admin.regles.remplacementPerte);
        // La feuille dit les bornes et comment aller au-dela, sans detour :
        // relever d'abord l'objectif (11), baisser d'abord l'avertissement (3).
        expect(
          find.textContaining('relevez d\'abord l\'objectif'),
          findsOneWidget,
        );
        expect(
          find.textContaining('baissez d\'abord l\'avertissement'),
          findsOneWidget,
        );
        // Monter jusqu'a la borne : le « + » disparait a 10, jamais 11.
        for (int i = 0; i < 2; i++) {
          await tester.tap(find.byKey(ChoixNombre.clePlus));
          await tester.pump();
        }
        expect(find.byKey(ChoixNombre.clePlus), findsNothing);
        // Descendre jusqu'a la borne basse : le « - » disparait a 4.
        for (int i = 0; i < 6; i++) {
          await tester.tap(find.byKey(ChoixNombre.cleMoins));
          await tester.pump();
        }
        expect(find.byKey(ChoixNombre.cleMoins), findsNothing);
        await tester.tap(find.byKey(ChoixNombre.clePlus));
        await tester.pump();
        await tester.tap(find.text(t.admin.regles.envoyer));
        await tester.pumpAndSettle();
        expect(config.ecritures, <(String, Object)>[
          ('remplacement.perte_acces_minutes', 5),
        ]);
      },
    );

    testWidgets('un refus du serveur sur l ordre se dit, rien ne change', (
      WidgetTester tester,
    ) async {
      final _Config config = _Config(_toutesLesCles())
        ..erreurEcriture = Exception(
          'delais de remplacement : la perte de la seance doit venir avant '
          'le remplacant dans la salle (perte 12 min, objectif 11 min)',
        );
      await _monter(tester, config);
      await ouvrir(tester, t.admin.regles.remplacementObjectif);
      await tester.tap(find.byKey(ChoixNombre.clePlus));
      await tester.pump();
      await tester.tap(find.text(t.admin.regles.envoyer));
      await tester.pumpAndSettle();
      // Le refus d'ordre se dit en mots simples, jamais le message brut.
      expect(find.text(t.admin.regles.remplacementOrdreRefuse), findsOneWidget);
      expect(find.textContaining('doit venir avant'), findsNothing);
      expect(config.ecritures, isEmpty);
    });
  });
}
