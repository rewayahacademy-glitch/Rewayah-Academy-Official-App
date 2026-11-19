// ACCES-AGENTS-LISTE : la page « Accès des agents IA » avec AU MOINS UN jeton.
//
// Le défaut prouvé ici : avec un jeton, la liste est une collection de données.
// Posée dans le défilement de la page sans `defileAvecLaPage`, elle rendait un
// défilement non borné dans un défilement : erreur de mise en page, et tout ce
// qui suit le titre « Accès des agents IA » (la liste des jetons et la section
// Praxis) restait blanc en production. Avec zéro jeton, la page montre un état
// vide : aucun test ne voyait donc le défaut.
//
// Ce que le cas prouve : la liste ET la section Praxis sont rendues, sans
// exception, à 1440 et à 360 px ; et il n'y a qu'un seul défilement : celui de
// la page (DECISION-DEFILEMENT-2026-11-01).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/questions_praxis.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/agent/service_praxis.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_acces_agents/acces_agents_page.dart';
import 'package:rewayah_academy/features/admin_acces_agents/section_praxis.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_service_autorisation_praxis.dart';
import '../../support/faux_service_praxis.dart';
import '../../support/faux_service_questions_praxis.dart';
import '../../support/harnais.dart';

/// Un service d'agents fictif qui rend UN jeton actif.
class _AgentsUnJeton implements ServiceAgent {
  @override
  Future<List<JetonAgent>> lister() async => <JetonAgent>[
    JetonAgent(
      id: 'j1',
      libelle: 'Jeton de test fictif',
      prefixe: 'obs_1a2b3c',
      parcours: AppRole.student,
      observeIdentifiant: 'ELV-TEST-001',
      observePrenom: 'Compte',
      identiteMasquee: true,
      expireLe: DateTime(2026, 12, 1, 18),
      creeLe: DateTime(2026, 11, 17, 9),
      remises: 3,
      etat: EtatJeton.actif,
    ),
  ];

  @override
  Future<List<PersonneObservable>> personnes() async =>
      const <PersonneObservable>[];

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) => throw UnimplementedError();

  @override
  Future<bool> revoquer(String id) async => true;
}

Future<void> _monter(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const AccesAgentsPage(),
      surcharges: <Override>[
        serviceAgentProvider.overrideWithValue(_AgentsUnJeton()),
        servicePraxisProvider.overrideWithValue(FauxServicePraxis()),
        serviceAutorisationPraxisProvider.overrideWithValue(
          FauxServiceAutorisationPraxis(),
        ),
        serviceQuestionsPraxisProvider.overrideWithValue(
          const QuestionsPraxisVides(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Hauteur assez grande pour que la page entière soit construite d'un coup :
  // un défilement paresseux ne bâtit pas ce qui est hors écran, et le défaut
  // ne se verrait pas.
  for (final Size taille in <Size>[
    const Size(1440, 4000),
    const Size(360, 4000),
  ]) {
    testWidgets('un jeton : la liste ET la section Praxis sont rendues, '
        'sans exception, à ${taille.width.toInt()} px', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille);
      expect(tester.takeException(), isNull);
      // La liste : le jeton est rendu (ligne ou carte).
      expect(find.text('Jeton de test fictif'), findsWidgets);
      // La section Praxis : on défile la page jusqu'à elle, elle est rendue.
      await tester.dragUntilVisible(
        find.byType(SectionPraxis),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SectionPraxis), findsOneWidget);
      expect(find.text(t.admin.praxis.titre), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  // R3 : la page avec un jeton, à 1440 px, en français ; la liste et la section
  // Praxis sont visibles. Sautée sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).
  group('ACCES-AGENTS-LISTE : capture', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    testWidgets('1440 fr, un jeton', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
      await _monter(tester, const Size(1440, 2600));
      expect(tester.takeException(), isNull);
      await capturerVue(
        tester,
        'ACCES-AGENTS-LISTE/acces_agents_fr_1440_un_jeton',
      );
    });
  });
}
