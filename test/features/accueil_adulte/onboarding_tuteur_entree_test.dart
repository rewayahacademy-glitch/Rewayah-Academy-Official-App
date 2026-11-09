// ONBOARDING-TUTEUR (directeur, 09/11/2026) : la question « Suivez-vous aussi
// des cours ? » est gardee, donc branchee. Le parent « Famille + Oui » (eleve
// autonome) trouve sur l'Accueil famille une entree vers son espace d'eleve,
// avec le meme compte, et un retour depuis cet espace. Un compte sans la
// capacite n'a aucune entree ; un compte « Moi » n'a pas de retour (le routeur
// l'y renverrait : une boucle).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/atterrissage_adulte.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/retour_accueil_famille.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../router/support_routeur.dart' show lieu;
import '../../support/demo/adulte_demo.dart';
import 'support_accueil_adulte_route.dart';

List<Override> _surcharges(UsageTitulaire usage) => <Override>[
  ...surchargesAccueilAdulte(
    accueil: Valeur(accueilDemo()),
    historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
  ),
  usageTitulaireProvider.overrideWith((Ref _, String _) async => usage),
];

void main() {
  group('Famille + Oui : l entree et le retour', () {
    testWidgets('l Accueil famille mene a l espace d eleve, et le retour '
        'ramene a l Accueil famille', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: _surcharges(UsageTitulaire.famille),
      );
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.tuteurAccueil);
      expect(find.byKey(AccueilFamillePage.espaceEleveKey), findsOneWidget);
      expect(find.text(t.tuteur.accueil.espaceEleveTitre), findsOneWidget);
      // Pas de retour sur l'Accueil famille lui-meme.
      expect(find.byKey(retourAccueilFamilleKey), findsNothing);

      await tester.tap(find.byKey(AccueilFamillePage.espaceEleveKey));
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      // Pas d'entree sur l'espace d'eleve lui-meme.
      expect(find.byKey(AccueilFamillePage.espaceEleveKey), findsNothing);

      final Finder retour = find.byKey(retourAccueilFamilleKey);
      await tester.ensureVisible(retour);
      await tester.pumpAndSettle();
      expect(retour, findsOneWidget);
      expect(find.text(t.adulte.accueil.retourFoyerTitre), findsOneWidget);
      await tester.tap(retour);
      await tester.pumpAndSettle();
      // Le routeur ne le renvoie pas a l'espace d'eleve : « Famille ».
      expect(lieu(routeur), Routes.tuteurAccueil);
      expect(find.byType(AccueilFamillePage), findsOneWidget);
    });

    testWidgets('un tuteur sans la capacite n a aucune entree', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        autonome: false,
        surcharges: _surcharges(UsageTitulaire.famille),
      );
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.tuteurAccueil);
      expect(find.byKey(AccueilFamillePage.espaceEleveKey), findsNothing);
      expect(find.text(t.tuteur.accueil.espaceEleveTitre), findsNothing);
    });

    testWidgets('« Moi » : l espace d eleve, sans retour vers un Accueil '
        'famille que le routeur refermerait', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: _surcharges(UsageTitulaire.moi),
      );
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byKey(retourAccueilFamilleKey), findsNothing);
    });

    for (final ({TextDirection sens, double echelle}) cas
        in <({TextDirection sens, double echelle})>[
          (sens: TextDirection.ltr, echelle: 2),
          (sens: TextDirection.rtl, echelle: 1),
          (sens: TextDirection.rtl, echelle: 2),
        ]) {
      testWidgets('l entree tient dans l ecran : ${cas.sens.name}, texte a '
          '${(cas.echelle * 100).round()} %', (WidgetTester tester) async {
        await monterAccueilAdulteReel(
          tester,
          taille: const Size(360, 780),
          echelle: cas.echelle,
          direction: cas.sens,
          surcharges: _surcharges(UsageTitulaire.famille),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Rect r = tester.getRect(
          find.byKey(AccueilFamillePage.espaceEleveKey),
        );
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(360));
        // Aucun mot coupe ni ellipse : le texte de la carte est entier.
        final Text titre = tester.widget<Text>(
          find.descendant(
            of: find.byKey(AccueilFamillePage.espaceEleveKey),
            matching: find.text(t.tuteur.accueil.espaceEleveTitre),
          ),
        );
        expect(titre.overflow, isNot(TextOverflow.ellipsis));
      });
    }
  });

  group('Capture R3 ONBOARDING-TUTEUR', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    testWidgets('(1) l Accueil famille : l entree vers l espace d eleve', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        taille: const Size(1280, 900),
        surcharges: _surcharges(UsageTitulaire.famille),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(AccueilFamillePage.espaceEleveKey), findsOneWidget);
      await capturerVue(tester, '1-accueil-famille-entree');
    });

    testWidgets('(2) l espace d eleve : le retour a l Accueil famille', (
      WidgetTester tester,
    ) async {
      await monterAccueilAdulteReel(
        tester,
        taille: const Size(1280, 1500),
        depart: Routes.eleveAdulte,
        surcharges: _surcharges(UsageTitulaire.famille),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(retourAccueilFamilleKey), findsOneWidget);
      await capturerVue(tester, '2-espace-eleve-retour');
    });
  }, skip: sautSansCapture);
}
