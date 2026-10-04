// COM-COMU-1 : l'entree reelle de la Communaute (Q2, raccourci sur
// Aujourd'hui, jamais un cinquieme bloc, K-42) et la demonstration de la
// voie, dans la vraie coquille Enseignant (jamais « Foyer »), hors
// production.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_communaute/composer_publication.dart';
import 'package:rewayah_academy/features/com_communaute/entree_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/garde_promotion.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import 'banc_communaute.dart';

Future<GoRouter> _monterDemo(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(390, 844),
}) async {
  fixerTaille(tester, taille);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesDemoCommunications('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

void main() {
  group('entree : la ligne « Communaute enseignants » d Aujourd hui', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : la ligne est dans « Ma journee », '
          'quatre blocs au plus, et elle ouvre la Communaute', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monterDemo(
          tester,
          adresseDemoCommunaute(SituationDemoCommunaute.aujourdhui),
          taille: taille,
        );
        expect(find.byType(JourneePage), findsOneWidget);
        expect(find.byType(NavShell), findsOneWidget);
        expect(find.text('Foyer'), findsNothing);

        final Finder lien = find.byKey(EntreeCommunaute.cleLien);
        expect(lien, findsOneWidget);
        expect(find.text(t.com.socle.lexique.communaute), findsOneWidget);
        // K-42 : l'entree n'ajoute pas de bloc, elle vit dans « Ma journee ».
        final GrilleBento grille = tester.widget(find.byType(GrilleBento));
        expect(grille.tuiles.length, lessThanOrEqualTo(4));
        expect(
          find.ancestor(
            of: lien,
            matching: find.byWidgetPredicate(
              (Widget w) => w.runtimeType.toString() == '_MaJournee',
            ),
          ),
          findsOneWidget,
        );

        await taper(tester, lien);
        expect(find.byType(CommunautePage), findsOneWidget);
        expect(
          routeur
              .routerDelegate
              .currentConfiguration
              .uri
              .queryParameters['etat'],
          SituationDemoCommunaute.nominal.name,
        );
        // Le retour de la Communaute ramene a Aujourd'hui.
        expect(find.byType(JourneePage), findsNothing);
      });
    }

    test('en production, le raccourci mene a la route de l enseignant', () {
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      expect(
        conteneur.read(destinationCommunauteProvider),
        Routes.enseignantCommunaute,
      );
    });
  });

  group('demonstration de la voie', () {
    testWidgets('l index propose chaque situation', (
      WidgetTester tester,
    ) async {
      await _monterDemo(
        tester,
        adresseDemoCommunications(VoieDemoCommunications.communaute),
      );
      for (final SituationDemoCommunaute s in SituationDemoCommunaute.values) {
        expect(
          find.byKey(ValueKey<String>('lien-communaute-${s.name}')),
          findsOneWidget,
        );
      }
    });

    for (final SituationDemoCommunaute s in SituationDemoCommunaute.values) {
      testWidgets('${s.name} : la coquille Enseignant, sans erreur', (
        WidgetTester tester,
      ) async {
        await _monterDemo(tester, adresseDemoCommunaute(s));
        expect(find.byType(NavShell), findsOneWidget);
        expect(find.text('Foyer'), findsNothing);
        expect(tester.takeException(), isNull);
        switch (s) {
          case SituationDemoCommunaute.aujourdhui:
            expect(find.byType(JourneePage), findsOneWidget);
          case SituationDemoCommunaute.publication:
            expect(find.byType(PublicationDetail), findsOneWidget);
          case SituationDemoCommunaute.nominal ||
              SituationDemoCommunaute.horsLigne ||
              SituationDemoCommunaute.envoiNonConfirme ||
              SituationDemoCommunaute.moderationIndisponible ||
              SituationDemoCommunaute.signalementNonConfirme ||
              SituationDemoCommunaute.lecteurSeul:
            expect(
              find.byKey(FluxPublications.cleCarte('pub-memorisation')),
              findsOneWidget,
            );
          case SituationDemoCommunaute.avertissementPromotion ||
              SituationDemoCommunaute.lienAffilie ||
              SituationDemoCommunaute.vente:
            // COM-COMU-2 : la nouvelle publication s'ouvre sur le brouillon
            // marque, restaure ; aucun verdict avant « Publier ».
            expect(find.byType(ComposerPublication), findsOneWidget);
            expect(find.text(s.brouillon!.titre), findsOneWidget);
            expect(find.byKey(GardePromotion.cleAide), findsOneWidget);
            expect(find.byKey(ComposerPublication.cleVerdict), findsNothing);
          case SituationDemoCommunaute.vide:
            expect(find.text(t.com.communaute.videToutes), findsOneWidget);
          case SituationDemoCommunaute.erreur:
            expect(
              find.text(t.com.socle.composants.etats.erreurTitre),
              findsOneWidget,
            );
          case SituationDemoCommunaute.indisponible:
            expect(
              find.text(t.com.socle.composants.etats.indisponibleTitre),
              findsOneWidget,
            );
        }
        await demonter(tester);
      });
    }

    test('six publications de demonstration, trois categories', () {
      expect(DonneesCommunauteDemo.publications(), hasLength(6));
      expect(DonneesCommunauteDemo.categories, hasLength(3));
      // Les six publications couvrent les trois categories.
      expect(
        DonneesCommunauteDemo.publications().map((p) => p.categorie.id).toSet(),
        hasLength(3),
      );
    });

    test('aucune route de demonstration en production', () {
      expect(routesDemoCommunications('production'), isEmpty);
    });
  });
}
