// EA-9 : Paiements du foyer du titulaire, atteints depuis la VRAIE coquille
// adulte (K-07) : on tape la VRAIE destination « Mon espace », la VRAIE ligne
// « Ma famille », puis la VRAIE ligne « Paiements du foyer ». Une ligne par
// beneficiaire autorise avec son solde tel que rendu, une pastille pour la
// seule exception rendue, un seul bouton « Recharger » au bord de fin, 16
// sous la liste, le recapitulatif discret et l'historique (F9, F10, F12).
// Puis la colonne droite de Ma famille sur bureau (planche 6), la vue du
// second adulte (historique seul, E3, F7) et les etats de la section
// (chargement, erreur, hors ligne, vide, indisponible).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_foyer.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart'
    show RechargeFoyerPage;
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../../support/hors_ligne_une_fois.dart';

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app({required Widget home, List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(body: SingleChildScrollView(child: home)),
          ),
        ),
      );

  Future<GoRouter> monterCoquille(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
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

  Finder dansSoldes(Finder f) =>
      find.descendant(of: find.byKey(SoldesFoyerSection.cle), matching: f);

  /// Aucun chiffre economique ajoute par Flutter (F12), jamais « admin »
  /// (K-53.6), jamais l'etat normal en pastille (E12), jamais un « budget »
  /// (F9).
  void rienDInvente() {
    for (final Pattern interdit in <Pattern>[
      '€',
      '%',
      RegExp('admin', caseSensitive: false),
      RegExp('budget', caseSensitive: false),
      'Actif',
      DonneesAdulteDemo.classeTitulaire,
    ]) {
      expect(find.textContaining(interdit), findsNothing, reason: '$interdit');
    }
  }

  testWidgets('Mon espace > Ma famille > Paiements du foyer, tapes : un solde '
      'par beneficiaire, une seule pastille, un seul « Recharger »', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));

    await tester.tap(find.text(t.adulte.nav.monEspace).first);
    await tester.pumpAndSettle();
    final Finder famille = find.descendant(
      of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
      matching: find.text(t.adulte.famille.maFamille),
    );
    await tester.ensureVisible(famille);
    await tester.tap(famille);
    await tester.pumpAndSettle();
    final Finder ligne = find.descendant(
      of: find.byKey(paiementsFoyerKey),
      matching: find.text(t.adulte.famille.paiementsFoyer),
    );
    await tester.ensureVisible(ligne);
    await tester.tap(ligne);
    await tester.pumpAndSettle();

    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byType(FoyerPage), findsNothing);
    // En-tete sobre : le nom de la ligne tapee.
    expect(find.text(t.adulte.famille.paiementsFoyer), findsOneWidget);

    // Une ligne par beneficiaire autorise, dans l'ordre rendu, avec son
    // solde TEL QUE RENDU, un libelle de demonstration sans unite (E2 = c,
    // revue EA-R m3 et m17).
    final d = t.adulte.demo.donnees;
    for (final (String prenom, String solde) in <(String, String)>[
      ('Mamadou', d.soldeTitulaire),
      ('Mariama', d.soldeSecondAdulte),
      ('Aïcha', d.soldeAicha),
      ('Oumar', d.soldeOumar),
    ]) {
      expect(dansSoldes(find.text(prenom)), findsOneWidget, reason: prenom);
      expect(dansSoldes(find.text(solde)), findsOneWidget, reason: solde);
    }
    double haut(Finder f) => tester.getTopLeft(f).dy;
    expect(
      haut(dansSoldes(find.text('Mamadou'))),
      lessThan(haut(dansSoldes(find.text('Mariama')))),
    );
    // La photo ou les initiales de chaque beneficiaire nomme (K-44).
    expect(dansSoldes(find.byType(PhotoEleve)), findsNWidgets(4));
    // Une seule pastille : l'exception rendue, avec son mot.
    final List<StatusPill> pastilles = tester
        .widgetList<StatusPill>(dansSoldes(find.byType(StatusPill)))
        .toList();
    expect(pastilles, hasLength(1));
    expect(pastilles.single.libelle, t.adulte.paiements.bientotEpuise);
    expect(pastilles.single.ton, TonEtat.avertissement);
    // La pastille est sur la ligne d'Aicha, pas ailleurs.
    final double pastille = haut(dansSoldes(find.byType(StatusPill)));
    expect(pastille, greaterThan(haut(dansSoldes(find.text('Aïcha')))));
    expect(pastille, lessThan(haut(dansSoldes(find.text('Oumar')))));

    // Un seul bouton dominant : « Recharger », au bord de fin, 16 sous la
    // liste des beneficiaires.
    expect(find.byType(ActionPrincipale), findsOneWidget);
    final Finder recharger = find.byKey(SoldesFoyerSection.rechargerKey);
    expect(
      find.descendant(of: recharger, matching: find.text('Recharger')),
      findsOneWidget,
    );
    final Finder groupe = dansSoldes(find.byType(GroupeReglages)).first;
    expect(
      tester.getTopLeft(recharger).dy - tester.getBottomLeft(groupe).dy,
      AppSpacing.lg,
    );
    expect(
      tester.getTopRight(recharger).dx,
      moreOrLessEquals(tester.getTopRight(groupe).dx, epsilon: 0.5),
    );
    // Le recapitulatif, discret, sous le bouton ; puis l'historique.
    expect(
      find.text(
        t.adulte.paiements.recapitulatif(valeur: d.totalAvecSecondAdulte),
      ),
      findsOneWidget,
    );
    expect(
      haut(find.byKey(SoldesFoyerSection.recapitulatifKey)),
      greaterThan(haut(recharger)),
    );
    expect(find.byKey(PaiementsComptePage.historiqueKey), findsOneWidget);
    expect(
      haut(find.byKey(PaiementsComptePage.historiqueKey)),
      greaterThan(haut(find.byKey(SoldesFoyerSection.recapitulatifKey))),
    );
    // L'historique garde sa source reelle, indisponible (DB-CPT-03).
    expect(
      find.text(t.compte.tuteur.pagePaiements.indisponibleTitre),
      findsOneWidget,
    );
    rienDInvente();

    // « Recharger » ouvre la recharge (EA-10), retour aux paiements du foyer.
    await tester.ensureVisible(recharger);
    await tester.tap(recharger);
    await tester.pumpAndSettle();
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    // Retour a Ma famille.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
  });

  testWidgets('sans second adulte rattache, aucune ligne pour lui ; '
      'titulaire femme : Mariama titulaire, Mamadou rattache', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.paiementsFoyer,
        etat: EtatDemoAdulte.titulaireSansConjoint,
      ),
    );
    expect(dansSoldes(find.text('Mariama')), findsNothing);
    expect(dansSoldes(find.text('Mamadou')), findsOneWidget);
    expect(
      find.text(
        t.adulte.paiements.recapitulatif(
          valeur: t.adulte.demo.donnees.totalSansSecondAdulte,
        ),
      ),
      findsOneWidget,
    );

    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.paiementsFoyer,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    await tester.pumpAndSettle();
    expect(dansSoldes(find.text('Mariama')), findsOneWidget);
    expect(dansSoldes(find.text('Mamadou')), findsOneWidget);
    expect(
      haut(tester, dansSoldes(find.text('Mariama'))),
      lessThan(haut(tester, dansSoldes(find.text('Mamadou')))),
    );
  });

  testWidgets('le second adulte rattache : l\'historique seul, ni soldes, ni '
      '« Recharger », ni les enfants (E3, F7)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.paiementsFoyer,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byKey(SoldesFoyerSection.cle), findsNothing);
    expect(find.text(t.adulte.paiements.recharger), findsNothing);
    expect(find.text('Aïcha'), findsNothing);
    expect(find.text('Oumar'), findsNothing);
    // La recharge n'existe pas pour lui : Forfait famille.
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.recharge,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    expect(find.byType(RechargeFoyerPage), findsNothing);
  });

  testWidgets('bureau : la colonne droite de Ma famille porte les soldes et '
      'son seul « Recharger », puis l\'historique en une ligne (planche 6)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));

    final Finder section = find.byKey(SoldesFoyerSection.cle);
    expect(section, findsOneWidget);
    expect(
      find.descendant(
        of: section,
        matching: find.text(t.adulte.famille.paiementsFoyer),
      ),
      findsOneWidget,
    );
    // A droite des membres.
    expect(
      tester.getTopLeft(section).dx,
      greaterThan(tester.getTopRight(find.byKey(FoyerPage.membresKey)).dx),
    );
    // Un bouton dominant par colonne : « Ajouter un profil eleve » et
    // « Recharger » (UX_REVIEW_07 ligne 7 a).
    expect(find.byType(ActionPrincipale), findsNWidgets(2));
    expect(
      find.descendant(
        of: section,
        matching: find.byKey(SoldesFoyerSection.rechargerKey),
      ),
      findsOneWidget,
    );
    final Finder historique = find.descendant(
      of: find.byKey(paiementsFoyerKey),
      matching: find.text(t.adulte.paiements.historique),
    );
    expect(historique, findsOneWidget);
    rienDInvente();

    await tester.tap(find.byKey(SoldesFoyerSection.rechargerKey));
    await tester.pumpAndSettle();
    expect(find.byType(RechargeFoyerPage), findsOneWidget);

    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    await tester.tap(find.text(t.adulte.paiements.historique));
    await tester.pumpAndSettle();
    expect(find.byType(PaiementsComptePage), findsOneWidget);
    expect(find.byKey(PaiementsComptePage.historiqueKey), findsOneWidget);
  });

  group('etats de la section des soldes', () {
    const SoldesFoyer exemple = SoldesFoyer(
      beneficiaires: <SoldeBeneficiaire>[
        SoldeBeneficiaire(
          id: 'b1',
          prenom: 'Yusuf',
          soldeRendu: 'valeur rendue',
          exception: ExceptionSolde.inactif,
        ),
      ],
    );

    Future<void> monter(
      WidgetTester tester,
      Future<SoldesFoyer> Function() lecture, {
      bool horsLigne = false,
      VoidCallback? onRecharger,
    }) async {
      taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        app(
          overrides: <Override>[
            soldesFoyerProvider.overrideWith((Ref _) => lecture()),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(horsLigne),
            ),
          ],
          home: SoldesFoyerSection(onRecharger: onRecharger),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    EtatSysteme? etat(WidgetTester tester) {
      final Iterable<EtatSysteme> e = tester.widgetList<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      return e.isEmpty ? null : e.first;
    }

    testWidgets('chargement : le squelette, sans faux nom ni faux solde', (
      WidgetTester tester,
    ) async {
      final Completer<SoldesFoyer> jamais = Completer<SoldesFoyer>();
      await monter(tester, () => jamais.future);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.adulte.paiements.beneficiaires), findsOneWidget);
      expect(find.byType(StatusPill), findsNothing);
      expect(find.byKey(SoldesFoyerSection.rechargerKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('erreur : dite, avec « Reessayer », sans bouton de recharge', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () => Future<SoldesFoyer>.error(StateError('panne')),
        onRecharger: () {},
      );
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.echecServeur);
      expect(find.byKey(SoldesFoyerSection.rechargerKey), findsNothing);
    });

    testWidgets('hors ligne : dit comme tel', (WidgetTester tester) async {
      await monter(
        tester,
        () => Future<SoldesFoyer>.error(StateError('coupure')),
        horsLigne: true,
      );
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.horsLigne);
      // EA-HL-DOUBLE-1 : le bloc dit ce qui manque, sans redire le reseau.
      expectSansDonnees(t.adulte.paiements.soldesSansDonnees, bandeau: false);
    });

    testWidgets('indisponible : la dependance EA-BR-23, sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () => Future<SoldesFoyer>.error(const CapaciteIndisponible('EA-BR-23')),
      );
      await tester.pumpAndSettle();
      final EtatSysteme? e = etat(tester);
      expect(e?.nature, NatureEtat.indisponible);
      expect(e?.dependance, 'EA-BR-23');
      expect(e?.titre, t.adulte.paiements.soldesIndisponiblesTitre);
    });

    testWidgets('vide : aucun beneficiaire, aucun bouton', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () async => const SoldesFoyer(beneficiaires: <SoldeBeneficiaire>[]),
        onRecharger: () {},
      );
      await tester.pumpAndSettle();
      expect(etat(tester)?.nature, NatureEtat.aucunResultat);
      expect(find.byKey(SoldesFoyerSection.rechargerKey), findsNothing);
    });

    testWidgets('contenu : le solde tel que rendu, l\'exception « Inactif » '
        'en pastille neutre, sans recapitulatif quand il n\'est pas rendu', (
      WidgetTester tester,
    ) async {
      await monter(tester, () async => exemple, onRecharger: () {});
      await tester.pumpAndSettle();
      expect(find.text('valeur rendue'), findsOneWidget);
      final StatusPill p = tester.widget<StatusPill>(find.byType(StatusPill));
      expect(p.libelle, t.adulte.paiements.inactif);
      expect(p.ton, TonEtat.neutre);
      expect(find.byKey(SoldesFoyerSection.recapitulatifKey), findsNothing);
      expect(find.byKey(SoldesFoyerSection.rechargerKey), findsOneWidget);
    });
  });
}

double haut(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;
