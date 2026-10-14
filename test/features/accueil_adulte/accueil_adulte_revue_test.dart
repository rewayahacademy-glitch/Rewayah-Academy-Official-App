// DASH-EA-PROD-b : les defauts de la revue DASH-EA-PROD-R et de sa
// contre-revue, chacun avec un test qui echoue sur l'ancien code.
//
// 1. (majeur, contre-revue) le routeur se reveille quand la capacite
//    « accueil adulte » est servie APRES la premiere navigation : le vrai
//    parcours de connexion, ou l'eleve arrive sur /eleve avant la lecture ;
// 2. (mineur 1) une relecture en echec rend la capacite fausse, meme apres
//    une premiere lecture reussie ;
// 3. (mineur, contre-revue) les deux « Voir tout » voisins (dernieres
//    seances, ressources) sont places de la meme facon sur mobile ;
// 4. (mineur 2) les hauteurs du squelette sont composees de jetons.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';

import '../../router/support_routeur.dart' show lieu;
import 'accueil_adulte_route_test.dart' show stabiliserTest;
import 'support_accueil_adulte_route.dart';

void main() {
  testWidgets('capacite servie apres la premiere navigation : le routeur se '
      'reveille et /eleve ouvre l\'Accueil adulte', (
    WidgetTester tester,
  ) async {
    final Completer<AccueilAdulteVM> lecture = Completer<AccueilAdulteVM>();
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      surcharges: <Override>[
        ...surchargesAccueilAdulte(
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
        accueilAdulteProvider.overrideWith((Ref _) => lecture.future),
      ],
      depart: Routes.eleve,
    );
    // EA-ROLE-1 : la capacite « eleve autonome » est servie avec la session,
    // `/eleve` mene d'emblee a l'accueil adulte, qui attend sa lecture.
    expect(lieu(routeur), Routes.eleveAdulte);
    expect(find.byType(AccueilElevePage), findsNothing);

    // Le serveur repond ensuite, sans nouvelle navigation.
    lecture.complete(accueilDemo());
    await stabiliserTest(tester);

    expect(lieu(routeur), Routes.eleveAdulte);
    expect(find.byType(AccueilAdultePage), findsOneWidget);
    expect(find.byType(AccueilElevePage), findsNothing);
  });

  testWidgets('relecture en echec : la capacite redevient fausse et /eleve '
      'garde l\'accueil de l\'eleve', (WidgetTester tester) async {
    bool echouer = false;
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      surcharges: <Override>[
        ...surchargesAccueilAdulte(
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
        accueilAdulteProvider.overrideWith(
          (Ref _) => echouer
              ? Future<AccueilAdulteVM>.error(StateError('lecture (test)'))
              : Future<AccueilAdulteVM>.value(accueilDemo()),
        ),
      ],
      depart: Routes.eleve,
    );
    expect(lieu(routeur), Routes.eleveAdulte);
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(AccueilAdultePage)),
    );
    expect(conteneur.read(capaciteAccueilAdulteProvider), isTrue);

    // « Reessayer » (ou toute relecture) echoue : la valeur precedente reste
    // dans l'AsyncValue, la capacite ne doit plus la croire servie.
    echouer = true;
    conteneur.invalidate(accueilAdulteProvider);
    await stabiliserTest(tester);
    expect(conteneur.read(accueilAdulteProvider).hasValue, isTrue);
    expect(conteneur.read(capaciteAccueilAdulteProvider), isFalse);

    // La lecture de l'accueil en echec ne retire pas la capacite servie :
    // `/eleve` ramene toujours a l'accueil adulte, jamais a celui de l'eleve.
    routeur.go(Routes.eleve);
    await stabiliserTest(tester);
    expect(lieu(routeur), Routes.eleveAdulte);
    expect(find.byType(AccueilElevePage), findsNothing);
  });

  testWidgets('mobile 390 : les deux « Voir tout » voisins sont sur la ligne '
      'de leur titre, au bord de fin', (WidgetTester tester) async {
    await monterAccueilAdulteReel(
      tester,
      taille: const Size(390, 2400),
      surcharges: surchargesAccueilAdulte(
        accueil: Valeur(accueilDemo()),
        historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
      ),
      depart: Routes.eleveAdulte,
    );
    final Finder titreSeances = find.text(t.adulte.accueil.dernieresSeances);
    final Finder titreRessources = find.text(t.adulte.accueil.ressources);
    // Les deux liens portent le meme libelle ; celui des dernieres seances
    // est au-dessus (ordre de §3.7).
    final Finder liens = find.widgetWithText(
      ActionPrincipale,
      LibellesGroupe.bibliothequeVoirTout,
    );
    expect(t.tuteur.accueil.voirTout, LibellesGroupe.bibliothequeVoirTout);
    expect(liens, findsNWidgets(2));
    final List<Finder> parOrdre = <Finder>[liens.at(0), liens.at(1)]
      ..sort(
        (Finder a, Finder b) =>
            tester.getTopLeft(a).dy.compareTo(tester.getTopLeft(b).dy),
      );
    final Finder lienSeances = parOrdre[0];
    final Finder lienRessources = parOrdre[1];

    // Chaque lien est sur la ligne de son titre, apres lui.
    expect(
      tester.getCenter(lienSeances).dy,
      moreOrLessEquals(tester.getCenter(titreSeances).dy, epsilon: 1),
    );
    expect(
      tester.getTopLeft(lienSeances).dx,
      greaterThan(tester.getTopRight(titreSeances).dx),
    );
    expect(
      tester.getCenter(lienRessources).dy,
      moreOrLessEquals(tester.getCenter(titreRessources).dy, epsilon: 1),
    );
    // Et les deux finissent au meme bord.
    expect(
      tester.getTopRight(lienSeances).dx,
      moreOrLessEquals(tester.getTopRight(lienRessources).dx, epsilon: 1),
    );
  });

  test('squelette : hauteurs composees des jetons, pas de nombre en dur', () {
    expect(
      SqueletteAccueilAdulte.hauteurGrande,
      AppSpacing.xxxl +
          AppSpacing.md +
          AccueilAdultePage.limite * AppPage.hauteurReglage +
          AppSpacing.xxl,
    );
    expect(
      SqueletteAccueilAdulte.hauteurLarge,
      AppSpacing.xxxl + AppSpacing.md + AppPage.hauteurReglage,
    );
  });
}
