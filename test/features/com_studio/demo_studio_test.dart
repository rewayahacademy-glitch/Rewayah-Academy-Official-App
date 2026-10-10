// COM-STU-1 et COM-STU-2 : la demonstration du Studio (hors production, spec
// section 26) : l'index des Communications mene au Studio, chaque situation
// s'ouvre (Aujourd'hui avec activite et vide compris), et les ports de
// demonstration se comportent comme le serveur attendu (jamais un canal
// absent, R-COM-08).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/elements_enregistres_studio.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';
import 'package:rewayah_academy/features/com_studio/panneau_partages.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/harnais.dart';
import 'support_studio.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[...routesDemoCommunications('staging')],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

void main() {
  group('La demonstration du Studio', () {
    testWidgets('l index mene au Studio, qui propose ses situations', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoCommunications(VoieDemoCommunications.studio),
      );
      expect(find.byType(ComStudioDemo), findsOneWidget);
      expect(find.text(t.com.socle.navigation.bientot), findsNothing);
      expect(find.text(t.com.studio.demo.choisir), findsOneWidget);
      for (final SituationDemoStudio s in SituationDemoStudio.values) {
        expect(
          find.byKey(ValueKey<String>('demo-studio-situation-${s.name}')),
          findsOneWidget,
          reason: s.name,
        );
      }
    });

    testWidgets('situation normale : canaux, canal, panneau ; Enregistrer '
        'puis Elements enregistres, qui rouvre le canal', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresseDemoStudio());
      expect(find.byType(CoquilleStudio), findsOneWidget);
      // Le Studio s'ouvre sur son accueil, Aujourd'hui.
      expect(find.byType(TableauAujourdhui), findsOneWidget);
      await tester.tap(find.text(t.com.studio.navigation.canaux).first);
      await tester.pumpAndSettle();
      expect(find.byType(ListeCanaux), findsOneWidget);
      await tester.tap(find.text('Suivi qualité'));
      await tester.pumpAndSettle();
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(find.byType(PanneauPartages), findsOneWidget);

      final Finder enregistrer = find.byKey(
        PanneauPartages.cleEnregistrer(
          ObjetLie(type: TypeObjetLie.canal, id: 'qualite', libelle: ''),
        ),
      );
      await tester.tap(enregistrer);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.com.studio.navigation.enregistres).first);
      await tester.pumpAndSettle();
      expect(find.byType(VueElementsEnregistres), findsOneWidget);
      await tester.tap(find.text('Suivi qualité'));
      await tester.pumpAndSettle();
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(find.byKey(EnteteCanal.cle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("Aujourd'hui de la demonstration : une mention ouvre son "
        'canal ici ; un module hors du Studio est nomme, la demonstration '
        'reste', (WidgetTester tester) async {
      await _monter(tester, adresseDemoStudio());
      expect(find.byType(TableauAujourdhui), findsOneWidget);
      expect(find.byKey(cleAvisHorsDemoStudio), findsNothing);
      final Finder dossier = find.text(
        'Dossier de la famille Karim prêt pour une décision',
      );
      await tester.ensureVisible(dossier);
      await tester.pumpAndSettle();
      await tester.tap(dossier);
      await tester.pumpAndSettle();
      expect(
        find.text(
          t.com.studio.demo.horsDemo(
            module: t.com.studio.aujourdhui.modules.dossiers,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byType(TableauAujourdhui), findsOneWidget);
      final Finder mention = find.text('Samira vous a mentionnée');
      await tester.ensureVisible(mention);
      await tester.pumpAndSettle();
      await tester.tap(mention);
      await tester.pumpAndSettle();
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(find.byKey(cleAvisHorsDemoStudio), findsNothing);
      // Le brouillon de la demonstration est remis dans le canal Admissions.
      expect(find.byKey(CanalStudio.cleBrouillonRestaure), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('l acces rapide « Demandes » nomme Demandes, pas Classes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresseDemoStudio());
      final Finder demandes = find.descendant(
        of: find.byKey(TableauAujourdhui.cleAcces),
        matching: find.text(t.com.studio.aujourdhui.acces.demandes),
      );
      await tester.ensureVisible(demandes);
      await tester.pumpAndSettle();
      await tester.tap(demandes);
      await tester.pumpAndSettle();
      final m = t.com.studio.aujourdhui.modules;
      expect(
        find.text(t.com.studio.demo.horsDemo(module: m.demandes)),
        findsOneWidget,
      );
      expect(
        find.text(t.com.studio.demo.horsDemo(module: m.classes)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("Aujourd'hui sans activite : l etat vide de la spec", (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoStudio(situation: SituationDemoStudio.aujourdhuiVide),
      );
      expect(find.text(t.com.studio.vide), findsOneWidget);
      expect(find.text(t.com.studio.brouillons.vide), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('canal prive demande par l adresse : non rendu (R-COM-08)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoStudio(situation: SituationDemoStudio.canalPrive),
      );
      expect(find.byKey(EspaceStudio.cleCanalIndisponible), findsOneWidget);
      expect(find.text('Direction stratégique'), findsNothing);
    });

    testWidgets('aucun canal : l etat vide', (WidgetTester tester) async {
      await _monter(
        tester,
        adresseDemoStudio(situation: SituationDemoStudio.sansCanaux),
      );
      await tester.tap(find.text(t.com.studio.navigation.canaux).first);
      await tester.pumpAndSettle();
      expect(find.text(t.com.studio.aucunCanalTitre), findsOneWidget);
    });

    testWidgets('390 : le disque retour du canal ramene a la liste, puis a '
        'l index de la demonstration', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        adresseDemoStudio(),
        taille: const Size(390, 844),
      );
      await tester.tap(find.text(t.com.studio.navigation.canaux).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Organisation générale'));
      await tester.pumpAndSettle();
      expect(find.byType(FilDiscussion), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(find.byType(ListeCanaux), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(
        routeur.routerDelegate.currentConfiguration.uri.toString(),
        adresseDemoCommunications(VoieDemoCommunications.studio),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Le port de demonstration', () {
    test('cinq canaux autorises, dont un restreint et un prive autorise ; '
        'le canal prive absent ne sort jamais', () async {
      final StudioDemo port = portDemo();
      final List<ResumeCanal> canaux = await port.canaux();
      expect(canaux, hasLength(5));
      expect(
        canaux.where(
          (ResumeCanal c) => c.visibilite == VisibiliteCanal.restreint,
        ),
        hasLength(1),
      );
      expect(
        canaux.where(
          (ResumeCanal c) => c.visibilite == VisibiliteCanal.priveAutorise,
        ),
        hasLength(1),
      );
      expect(
        canaux.any((ResumeCanal c) => c.id == canalPriveAbsentDemo),
        isFalse,
      );
      expect(await port.canal(canalPriveAbsentDemo), isNull);
      expect((await port.partages(canalPriveAbsentDemo)).estVide, isTrue);
      final ResultatsStudio r = await port.rechercher('budget');
      expect(r.total, 0);
      expect(
        () => port.envoyer(canalPriveAbsentDemo, 'x', 'k'),
        throwsA(isA<StateError>()),
      );
    });

    test('la taxonomie de la demonstration suit la spec section 9.1', () async {
      final List<ResumeCanal> canaux = await portDemo().canaux();
      expect(
        canauxParSection(canaux)
            .map(((SectionStudio, List<ResumeCanal>) s) => s.$1),
        <SectionStudio>[
          SectionStudio.organisation,
          SectionStudio.admissionsFamilles,
          SectionStudio.pedagogieQualite,
          SectionStudio.planningRemplacements,
          SectionStudio.finance,
        ],
      );
    });

    test('marquer lu fait tomber les non-lus du canal', () async {
      final StudioDemo port = portDemo();
      ResumeCanal org() => port.canalEnMemoire('organisation')!.resume;
      expect(org().attention.estVisible, isTrue);
      await port.marquerLu('organisation');
      expect(org().attention.estVisible, isFalse);
    });

    test('le chemin d un canal se relit, un autre chemin non', () {
      expect(canalDuChemin(Routes.canalStudioPour('qualite')), 'qualite');
      expect(canalDuChemin(Routes.admin), isNull);
      expect(canalDuChemin('${Routes.adminStudioCanaux}/a/b'), isNull);
    });
  });
}
