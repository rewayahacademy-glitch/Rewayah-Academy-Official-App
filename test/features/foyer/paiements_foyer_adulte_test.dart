// EA-9 : Paiements du foyer du titulaire, atteints depuis la VRAIE coquille
// adulte (K-07) : on tape la VRAIE destination « Mon espace », la VRAIE ligne
// « Ma famille », puis la VRAIE ligne « Paiements du foyer ». Depuis la revue
// FI-VAGUE-R R1-06 (E-11), ses soldes ne sont plus repetes : un seul
// « Recharger », raccourci vers la recharge du foyer, puis l'historique.
// Ma famille a la composition du Foyer du tuteur, avec une source de
// finances, a 1440 et 390 (synthese, cartes, un seul bouton plein). Puis la
// vue du second adulte (historique seul, E3, F7) et les etats de la section
// des soldes, qui reste un composant (chargement, erreur, hors ligne, vide,
// indisponible).

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
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/resume_soldes.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/soldes_foyer.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart'
    show RechargeFoyerPage;
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

  testWidgets('Mon espace > Ma famille > Paiements du foyer, tapes : aucune '
      'section de soldes, un seul « Recharger », l\'historique rendu (R1-06)', (
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

    // Les soldes ne sont plus repetes ici (E-11, revue FI-VAGUE-R R1-06) :
    // la synthese et les cartes de Ma famille les portent.
    expect(find.byKey(SoldesFoyerSection.cle), findsNothing);
    expect(find.byType(ResumeSoldes), findsNothing);
    // Un seul bouton : « Recharger », raccourci vers LA recharge (FI-7).
    expect(find.byType(ActionPrincipale), findsOneWidget);
    final Finder recharger = find.byKey(PaiementsComptePage.rechargerKey);
    expect(
      find.descendant(of: recharger, matching: find.text('Recharger')),
      findsOneWidget,
    );
    // L'historique : le paiement qui a recharge le foyer, avec son
    // justificatif, sous « Recharger ».
    final Finder paiement = find.textContaining(
      t.compte.tuteur.pagePaiements.paiementDu(date: ''),
    );
    expect(paiement, findsOneWidget);
    expect(find.text(t.compte.tuteur.pagePaiements.justificatif), findsOne);
    expect(haut(tester, paiement), greaterThan(haut(tester, recharger)));
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

  testWidgets('les finances du foyer du titulaire : lui, le second adulte '
      'seulement s\'il est rattache, puis les enfants ; titulaire femme : '
      'Mariama titulaire, Mamadou rattache', (WidgetTester tester) async {
    List<String> prenoms(
      EtatDemoAdulte etat,
      GenreTitulaireDemo genre,
    ) => <String>[
      for (final FinancesProfil p in DonneesAdulteDemo.finances(etat, genre))
        p.prenom,
    ];
    expect(
      prenoms(EtatDemoAdulte.conjointActif, GenreTitulaireDemo.homme),
      <String>['Mamadou', 'Mariama', 'Aïcha', 'Oumar'],
    );
    expect(
      prenoms(EtatDemoAdulte.titulaireSansConjoint, GenreTitulaireDemo.homme),
      <String>['Mamadou', 'Aïcha', 'Oumar'],
    );
    expect(
      prenoms(EtatDemoAdulte.conjointActif, GenreTitulaireDemo.femme),
      <String>['Mariama', 'Mamadou', 'Aïcha', 'Oumar'],
    );
    // Le foyer que l'adulte seul vient d'ouvrir : lui seul.
    expect(
      <String>[
        for (final FinancesProfil p in DonneesAdulteDemo.finances(
          EtatDemoAdulte.conjointActif,
          GenreTitulaireDemo.homme,
          foyerNouveau: true,
        ))
          p.prenom,
      ],
      <String>['Mamadou'],
    );
    // Les enfants portent les identifiants de Ma famille : leur carte lit
    // leur finance.
    final List<FinancesProfil> f = DonneesAdulteDemo.finances(
      EtatDemoAdulte.conjointActif,
      GenreTitulaireDemo.homme,
    );
    expect(f[2].profilId, DonneesAdulteDemo.aichaId);
    expect(f[3].profilId, DonneesAdulteDemo.oumarId);
    expect(f.take(2).every((FinancesProfil p) => p.estAdulte), isTrue);
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

  for (final Size ecran in const <Size>[Size(1440, 1000), Size(390, 844)]) {
    testWidgets('Ma famille a ${ecran.width.toInt()} : la composition du Foyer '
        'du tuteur avec une source de finances (E-11, FI-5b, R1-06) : '
        'synthese, cartes, un seul bouton plein, aucune section de soldes', (
      WidgetTester tester,
    ) async {
      taille(tester, ecran);
      await monterCoquille(
        tester,
        adresseDemoAdulte(EcranDemoAdulte.maFamille),
      );
      final bool bureau = ecran.width >= 1200;

      // Aucune section de soldes repetee : la synthese les porte.
      expect(find.byKey(SoldesFoyerSection.cle), findsNothing);
      expect(find.byKey(SoldesFoyerSection.rechargerKey), findsNothing);
      // « Soldes et paiements » en sous-titre (R1-09), la synthese en tete
      // des profils.
      expect(find.text(t.foyer.finances.titre), findsOneWidget);
      final Finder synthese = find.byKey(SyntheseSoldesFoyer.cle);
      expect(synthese, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(FoyerPage.membresKey),
          matching: synthese,
        ),
        findsOneWidget,
      );
      expect(
        haut(tester, find.byKey(FoyerPage.titulaireKey)),
        lessThan(haut(tester, synthese)),
      );
      // La finance de chaque enfant sur sa carte : « Voir le détail ».
      for (final String id in <String>[
        DonneesAdulteDemo.aichaId,
        DonneesAdulteDemo.oumarId,
      ]) {
        expect(find.byKey(FoyerPage.voirDetailKey(id)), findsOneWidget);
      }
      // Un seul bouton plein : « Recharger plusieurs profils » (Q-FI-2,
      // E-17, R1-01) ; « Ajouter un profil eleve » en secondaire.
      final List<ActionPrincipale> pleins = tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
          .where((ActionPrincipale a) => a.niveau == NiveauAction.principale)
          .toList();
      expect(pleins, hasLength(1));
      expect(pleins.single.key, SyntheseSoldesFoyer.rechargerKey);
      expect(
        tester
            .widget<ActionPrincipale>(find.byKey(FoyerPage.ajouterKey))
            .niveau,
        NiveauAction.secondaire,
      );
      // Bureau : les cartes cote a cote, la vue financiere du mois sous la
      // grille ; telephone : les cartes l'une sous l'autre.
      final Rect aicha = tester.getRect(
        find.byKey(FoyerPage.voirDetailKey(DonneesAdulteDemo.aichaId)),
      );
      final Rect oumar = tester.getRect(
        find.byKey(FoyerPage.voirDetailKey(DonneesAdulteDemo.oumarId)),
      );
      if (bureau) {
        expect(aicha.top, moreOrLessEquals(oumar.top, epsilon: 0.5));
        expect(oumar.left, greaterThan(aicha.right));
        expect(find.byKey(VueFinanciereFoyer.cle), findsOneWidget);
      } else {
        expect(oumar.top, greaterThan(aicha.bottom));
      }
      rienDInvente();
      expect(tester.takeException(), isNull);

      // « Paiements du foyer » mene a l'historique et a « Recharger ».
      final Finder ligne = find.descendant(
        of: find.byKey(paiementsFoyerKey),
        matching: find.text(t.adulte.famille.paiementsFoyer),
      );
      await tester.ensureVisible(ligne);
      await tester.tap(ligne);
      await tester.pumpAndSettle();
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      final Finder recharger = find.byKey(PaiementsComptePage.rechargerKey);
      await tester.ensureVisible(recharger);
      await tester.tap(recharger);
      await tester.pumpAndSettle();
      expect(find.byType(RechargeFoyerPage), findsOneWidget);
    });
  }

  testWidgets('Ma famille : « Recharger plusieurs profils » ouvre la recharge '
      'de la demonstration, jamais une fiche', (WidgetTester tester) async {
    taille(tester, const Size(1440, 1000));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.maFamille));
    final Finder recharger = find.byKey(SyntheseSoldesFoyer.rechargerKey);
    await tester.ensureVisible(recharger);
    await tester.tap(recharger);
    await tester.pumpAndSettle();
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.byType(FicheElevePage), findsNothing);
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

    // Revue EA-HL-DOUBLE-1 (m1) : des soldes deja lus, relus en echec hors
    // ligne, restent affiches, sans bloc ni echec.
    testWidgets('hors ligne, soldes deja lus puis relus en echec : ils '
        'restent', (WidgetTester tester) async {
      int lectures = 0;
      await monter(
        tester,
        () => ++lectures == 1
            ? Future<SoldesFoyer>.value(exemple)
            : Future<SoldesFoyer>.error(StateError('coupure')),
        horsLigne: true,
      );
      await tester.pumpAndSettle();
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(SoldesFoyerSection)),
      )..invalidate(soldesFoyerProvider);
      await tester.pumpAndSettle();
      final AsyncValue<SoldesFoyer> lus = conteneur.read(soldesFoyerProvider);
      expect(lus.hasError && lus.hasValue, isTrue);
      expect(find.text('valeur rendue'), findsOneWidget);
      expect(etat(tester), isNull);
      expectHorsLigneUneFois(bandeau: false);
    });

    testWidgets('indisponible : la dependance FI-BR-03, sans « Reessayer »', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        () => Future<SoldesFoyer>.error(const CapaciteIndisponible('FI-BR-03')),
      );
      await tester.pumpAndSettle();
      final EtatSysteme? e = etat(tester);
      expect(e?.nature, NatureEtat.indisponible);
      expect(e?.dependance, 'FI-BR-03');
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
