// EA-11 : la reprise du foyer (succession), atteinte depuis la VRAIE coquille
// adulte (K-07) : on tape la VRAIE destination « Mon espace », la VRAIE ligne
// famille « Forfait famille », puis le VRAI lien « Demande de reprise du
// foyer » (second adulte) ; la VRAIE cloche de l'Accueil et la VRAIE ligne de
// la place de Ma famille (titulaire). Texte du doc section 19, listes des
// sections 12.6 et 12.7, confirmation, etats rendus (deposee, refusee par le
// titulaire, attente de l'administration, validee, refusee), date rendue
// jamais calculee (F17), une seule demande active, D5, double envoi, hors
// ligne, chargement, echec de lecture, indisponible (EA-BR-27, EA-BR-28).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show dateLongue;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart'
    show dateEcheance;
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

void main() {
  final r = t.adulte.reprise;

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> monterCoquille(WidgetTester tester, String depart) async {
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
  }

  Future<void> monterPage(
    WidgetTester tester,
    Widget page, {
    List<Override> surcharges = const <Override>[],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: surcharges,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: page,
          ),
        ),
      ),
    );
  }

  Future<void> taper(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  Finder confirmer(String libelle) =>
      find.widgetWithText(ActionPrincipale, libelle).last;

  ActionPrincipale bouton(WidgetTester tester, Key cle) =>
      tester.widget<ActionPrincipale>(find.byKey(cle));

  // Aucun texte visible ne dit « admin », « succes », ni un compte a rebours
  // (K-53.6, E7, F17), ni une formule de condoleances (Q10).
  void sansMotsInterdits(WidgetTester tester) {
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String texte = (w.data ?? '').toLowerCase();
      expect(
        RegExp('admin(?!istrati)').hasMatch(texte),
        isFalse,
        reason: texte,
      );
      expect(texte.contains('succès'), isFalse, reason: texte);
      expect(texte.contains('30 jours'), isFalse, reason: texte);
      expect(texte.contains('jours restants'), isFalse, reason: texte);
      expect(texte.contains('condoléances'), isFalse, reason: texte);
      expect(texte.contains('héritage'), isFalse, reason: texte);
    }
  }

  testWidgets('second adulte, Mon espace > Forfait famille > Demande de '
      'reprise du foyer, tapes : texte du doc section 19, listes 12.6 et '
      '12.7, confirmation, puis l\'etat « Deposee » et la date rendue', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );

    // La VRAIE destination, la VRAIE ligne famille, le VRAI lien.
    await taper(tester, find.text(t.adulte.nav.monEspace).first);
    await taper(
      tester,
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.forfaitFamille),
      ),
    );
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
    await taper(tester, find.byKey(ForfaitFamillePage.repriseKey));
    expect(find.byType(RepriseFoyerPage), findsOneWidget);

    // Doc section 19, puis sections 12.6 et 12.7.
    expect(find.text(r.explication), findsOneWidget);
    expect(find.text(r.reprisTitre), findsOneWidget);
    expect(find.text(r.repris.profils), findsOneWidget);
    expect(find.text(r.repris.parcours), findsOneWidget);
    expect(find.text(r.jamaisTitre), findsOneWidget);
    expect(find.text(r.jamais.identifiants), findsOneWidget);
    expect(find.text(r.jamais.donnees), findsOneWidget);
    expect(find.text(r.succession), findsOneWidget);
    // Rien du foyer ni des enfants (F6, F7), aucune piece demandee.
    expect(find.text('Aïcha'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    sansMotsInterdits(tester);

    // Un seul bouton dominant, « Annuler » avant lui.
    final ActionPrincipale deposer = bouton(
      tester,
      RepriseFoyerPage.deposerKey,
    );
    expect(deposer.libelle, r.deposer);
    expect(deposer.niveau, NiveauAction.principale);
    expect(
      bouton(tester, RepriseFoyerPage.annulerKey).niveau,
      NiveauAction.secondaire,
    );

    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    expect(find.text(r.deposerQuestion), findsWidgets);
    expect(find.text(r.deposerConsequence), findsOneWidget);
    await taper(tester, confirmer(r.deposer));

    // L'etat rendu, relu : motif, depot, etat, et la date d'examen telle
    // que le serveur la rend.
    expect(find.byKey(RepriseFoyerPage.etatKey), findsOneWidget);
    expect(find.text(r.motifDeces), findsOneWidget);
    expect(
      find.text(dateLongue(DonneesAdulteDemo.dateDepotReprise)),
      findsOneWidget,
    );
    expect(find.text(r.etats.deposee), findsOneWidget);
    expect(find.text(r.phrases.deposee), findsOneWidget);
    expect(
      find.text(
        r.phrases.examenLe(
          date: dateEcheance(DonneesAdulteDemo.examenRepriseLe),
        ),
      ),
      findsOneWidget,
    );
    // Une seule demande active : plus rien a deposer.
    expect(find.byKey(RepriseFoyerPage.deposerKey), findsNothing);
    sansMotsInterdits(tester);
  });

  testWidgets('« Annuler » revient au forfait famille, rien ne part', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await taper(tester, find.byKey(RepriseFoyerPage.annulerKey));
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
  });

  testWidgets('renoncer a la confirmation : rien n\'est depose', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    await taper(tester, find.text(t.commun.annuler).last);
    expect(find.byKey(RepriseFoyerPage.etatKey), findsNothing);
    expect(find.byKey(RepriseFoyerPage.deposerKey), findsOneWidget);
  });

  for (final (EtatDemoAdulte etat, String libelle, String phrase)
      in <(EtatDemoAdulte, String, String)>[
        (
          EtatDemoAdulte.repriseRefuseeParTitulaire,
          t.adulte.reprise.etats.refuseeParTitulaire,
          t.adulte.reprise.phrases.refuseeParTitulaire,
        ),
        (
          EtatDemoAdulte.repriseSansReponse,
          t.adulte.reprise.etats.attenteAdministration,
          t.adulte.reprise.phrases.attenteAdministration,
        ),
        (
          EtatDemoAdulte.repriseRefusee,
          t.adulte.reprise.etats.refusee,
          t.adulte.reprise.phrases.refusee,
        ),
        (
          EtatDemoAdulte.repriseValidee,
          t.adulte.reprise.etats.validee,
          t.adulte.reprise.phrases.validee,
        ),
      ]) {
    testWidgets('second adulte, ${etat.name} : la cloche ouvre le centre '
        'existant, la notification ouvre l\'etat rendu, sans action', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.accueil,
          etat: etat,
          vue: VueDemoAdulte.secondAdulte,
        ),
      );
      await taper(tester, find.byType(ClocheNotifications).first);
      expect(find.byType(NotificationsPage), findsOneWidget);
      await taper(
        tester,
        find.byKey(const ValueKey<String>('notification-demo-reprise-foyer')),
      );
      expect(find.byType(RepriseFoyerPage), findsOneWidget);
      expect(find.text(libelle), findsOneWidget);
      expect(find.text(phrase), findsOneWidget);
      // Le compte a rebours n'existe pas : la date d'examen n'est dite que
      // pour une demande deposee (F17).
      expect(find.textContaining('à partir du'), findsNothing);
      expect(find.byKey(RepriseFoyerPage.deposerKey), findsNothing);
      sansMotsInterdits(tester);
    });
  }

  testWidgets('titulaire : la cloche, la notification du doc section 12.2, '
      'puis « Refuser la demande » sans confirmation ; l\'etat rendu', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        etat: EtatDemoAdulte.repriseDemandee,
      ),
    );
    await taper(tester, find.byType(ClocheNotifications).first);
    expect(find.text(r.titulaire.notification), findsOneWidget);
    await taper(
      tester,
      find.byKey(const ValueKey<String>('notification-demo-reprise-foyer')),
    );
    expect(find.byType(RepriseTitulairePage), findsOneWidget);
    expect(find.text(r.titulaire.notification), findsOneWidget);
    expect(find.text(r.titulaire.consigne), findsOneWidget);
    // Rien sur le demandeur (Q11).
    expect(find.textContaining('Mariama'), findsNothing);
    final ActionPrincipale refuser = bouton(
      tester,
      RepriseTitulairePage.refuserKey,
    );
    expect(refuser.libelle, r.titulaire.refuser);
    expect(refuser.niveau, NiveauAction.principale);
    sansMotsInterdits(tester);

    await taper(tester, find.byKey(RepriseTitulairePage.refuserKey));
    // Aucune confirmation : la page relue dit le refus.
    expect(find.text(r.deposerQuestion), findsNothing);
    expect(find.byKey(RepriseTitulairePage.refuseeKey), findsOneWidget);
    expect(find.text(r.titulaire.refusee), findsOneWidget);
    expect(find.byKey(RepriseTitulairePage.refuserKey), findsNothing);
    sansMotsInterdits(tester);
  });

  testWidgets('titulaire : la ligne de la place de Ma famille dit la demande '
      'et ouvre la decision', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.repriseDemandee,
      ),
    );
    expect(find.byType(FoyerPage), findsOneWidget);
    final Finder legende = find.descendant(
      of: find.byKey(lignePlaceAdulteKey),
      matching: find.text(r.titulaire.ligne),
    );
    expect(legende, findsOneWidget);
    await taper(tester, legende);
    expect(find.byType(RepriseTitulairePage), findsOneWidget);
    expect(find.byKey(RepriseTitulairePage.refuserKey), findsOneWidget);
  });

  testWidgets('sans demande, la ligne de la place reste celle du retrait', (
    WidgetTester tester,
  ) async {
    expect(
      DonneesAdulteDemo.place(
        EtatDemoAdulte.conjointActif,
        GenreTitulaireDemo.homme,
      ),
      isA<PlaceOccupee>().having(
        (PlaceOccupee p) => p.repriseARepondre,
        'reprise',
        isFalse,
      ),
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.repriseTitulaire,
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.titulaire,
      ),
      EcranDemoAdulte.maFamille,
    );
  });

  testWidgets('permissions : la demande n\'est qu\'au second adulte, la '
      'decision qu\'au titulaire (matrice du doc section 16)', (
    WidgetTester tester,
  ) async {
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.titulaire,
      ),
      EcranDemoAdulte.monEspace,
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        EtatDemoAdulte.conjointQuitte,
        VueDemoAdulte.secondAdulte,
      ),
      EcranDemoAdulte.monEspace,
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.repriseTitulaire,
        EtatDemoAdulte.repriseDemandee,
        VueDemoAdulte.secondAdulte,
      ),
      EcranDemoAdulte.forfaitFamille,
    );
    // Celui qui agit ne recoit pas la notification de son propre geste.
    expect(
      DonneesAdulteDemo.notificationReprise(
        EtatDemoAdulte.repriseDemandee,
        VueDemoAdulte.secondAdulte,
      ),
      isNull,
    );
  });

  testWidgets('erreur reseau au depot : D5, rien de change, le depot reste '
      'possible', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        etat: EtatDemoAdulte.erreurReseau,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    await taper(tester, confirmer(r.deposer));
    expect(find.text(r.depotEchecTitre), findsOneWidget);
    expect(find.text(r.echecPhrase), findsOneWidget);
    expect(find.textContaining("n'a pas été envoy"), findsNothing);
    expect(find.textContaining("n'a pas été déposée"), findsNothing);
    expect(find.byKey(RepriseFoyerPage.etatKey), findsNothing);
    expect(bouton(tester, RepriseFoyerPage.deposerKey).onPress, isNotNull);
  });

  testWidgets('erreur reseau au refus : « Le refus n\'a pas ete confirme »', (
    WidgetTester tester,
  ) async {
    await monterPage(
      tester,
      RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        demandeRepriseRecueProvider.overrideWith(
          (Ref _) async => const RepriseARefuser(),
        ),
        portRepriseFoyerProvider.overrideWithValue(const _PortCoupe()),
      ],
    );
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(RepriseTitulairePage.refuserKey));
    expect(find.text(r.titulaire.refusEchecTitre), findsOneWidget);
    expect(find.byKey(RepriseTitulairePage.refuseeKey), findsNothing);
    expect(bouton(tester, RepriseTitulairePage.refuserKey).onPress, isNotNull);
  });

  testWidgets('double envoi : le bouton attend, un seul etat rendu', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        etat: EtatDemoAdulte.doubleSoumission,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    await tester.tap(confirmer(r.deposer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(bouton(tester, RepriseFoyerPage.deposerKey).enCours, isTrue);
    await tester.tap(
      find.byKey(RepriseFoyerPage.deposerKey),
      warnIfMissed: false,
    );
    await tester.pump(latenceSimulee);
    await tester.pumpAndSettle();
    expect(find.byKey(RepriseFoyerPage.etatKey), findsOneWidget);
    expect(find.text(r.deposerQuestion), findsNothing);
  });

  testWidgets('hors ligne, second adulte : le depot inactif, rien ne part', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final List<Override> horsLigne = <Override>[
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
    ];
    await monterPage(
      tester,
      RepriseFoyerPage(onRetour: () {}, onDeposee: () {}),
      surcharges: <Override>[
        ...horsLigne,
        repriseFoyerProvider.overrideWith(
          (Ref _) async => const RepriseAucune(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(r.horsLigne), findsOneWidget);
    expect(bouton(tester, RepriseFoyerPage.deposerKey).onPress, isNull);
  });

  testWidgets('hors ligne, titulaire : le refus inactif, rien ne part', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final List<Override> horsLigne = <Override>[
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
    ];
    await monterPage(
      tester,
      RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
      surcharges: <Override>[
        ...horsLigne,
        demandeRepriseRecueProvider.overrideWith(
          (Ref _) async => const RepriseARefuser(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(r.titulaire.horsLigne), findsOneWidget);
    expect(bouton(tester, RepriseTitulairePage.refuserKey).onPress, isNull);
  });

  testWidgets('sans source serveur : indisponible (EA-BR-27, EA-BR-28)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      RepriseFoyerPage(onRetour: () {}, onDeposee: () {}),
    );
    await tester.pumpAndSettle();
    EtatSysteme etat = tester.widget<EtatSysteme>(find.byType(EtatSysteme));
    expect(etat.nature, NatureEtat.indisponible);
    expect(etat.dependance, 'EA-BR-27');
    expect(find.byKey(RepriseFoyerPage.deposerKey), findsNothing);

    await monterPage(
      tester,
      RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
    );
    await tester.pumpAndSettle();
    etat = tester.widget<EtatSysteme>(find.byType(EtatSysteme));
    expect(etat.dependance, 'EA-BR-28');
    expect(find.byKey(RepriseTitulairePage.refuserKey), findsNothing);
  });

  testWidgets('lecture rendue mais depot sans source : indisponible, le '
      'depot ne se relance pas', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      RepriseFoyerPage(onRetour: () {}, onDeposee: () {}),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        repriseFoyerProvider.overrideWith(
          (Ref _) async => const RepriseAucune(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    await taper(tester, confirmer(r.deposer));
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.dependance, 'EA-BR-27');
    expect(bouton(tester, RepriseFoyerPage.deposerKey).onPress, isNull);
  });

  testWidgets('chargement : un squelette, aucun faux etat', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final Completer<EtatReprise> jamais = Completer<EtatReprise>();
    await monterPage(
      tester,
      RepriseFoyerPage(onRetour: () {}, onDeposee: () {}),
      surcharges: <Override>[
        repriseFoyerProvider.overrideWith((Ref _) => jamais.future),
      ],
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byKey(RepriseFoyerPage.deposerKey), findsNothing);
    expect(find.byKey(RepriseFoyerPage.etatKey), findsNothing);
  });

  testWidgets('chargement, titulaire : un squelette, aucun faux etat', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final Completer<DemandeRepriseRecue> jamais =
        Completer<DemandeRepriseRecue>();
    await monterPage(
      tester,
      RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
      surcharges: <Override>[
        demandeRepriseRecueProvider.overrideWith((Ref _) => jamais.future),
      ],
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byKey(RepriseTitulairePage.refuserKey), findsNothing);
    expect(find.byKey(RepriseTitulairePage.refuseeKey), findsNothing);
  });

  testWidgets('echec de lecture : recuperable, aucune action', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      RepriseTitulairePage(onRetour: () {}, onRefusee: () {}),
      surcharges: <Override>[
        demandeRepriseRecueProvider.overrideWith(
          (Ref _) => Future<DemandeRepriseRecue>.error(StateError('coupure')),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<EtatSysteme>(find.byType(EtatSysteme)).onAction,
      isNotNull,
    );
    expect(find.byKey(RepriseTitulairePage.refuserKey), findsNothing);
  });

  testWidgets('a 1440 : la confirmation en boite de dialogue, meme ordre', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 900));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.repriseFoyer,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await taper(tester, find.byKey(RepriseFoyerPage.deposerKey));
    expect(find.text(r.deposerConsequence), findsOneWidget);
    await taper(tester, confirmer(r.deposer));
    expect(find.byKey(RepriseFoyerPage.etatKey), findsOneWidget);
  });
}

/// Un port dont la reponse se perd (D5).
class _PortCoupe implements PortRepriseFoyer {
  const _PortCoupe();

  @override
  Future<ResultatReprise> deposer({required String cle}) async =>
      const RepriseEchecReseau();

  @override
  Future<ResultatReprise> refuser({required String cle}) async =>
      const RepriseEchecReseau();
}
