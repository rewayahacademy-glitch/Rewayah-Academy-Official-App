// EA-8 : la sortie du forfait famille et le delai, atteints depuis la VRAIE
// coquille adulte (K-07) : on tape la VRAIE destination « Mon espace », la
// VRAIE ligne famille, puis la VRAIE ligne de la place (titulaire) ou la page
// Forfait famille (second adulte). Confirmation destructive qui dit ce qui
// ne change pas (F14, F15), resultat sans « succes » (E7), notification de
// l'autre adulte dans le centre existant (F16), delai a la date rendue
// (F17), etats erreur reseau (D5), double envoi, hors ligne, chargement,
// echec de lecture, indisponible.

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
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
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
  final String date = dateEcheance(DonneesAdulteDemo.finDelai);

  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

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

  // Une page seule, avec ses fournisseurs surcharges (etats hors
  // demonstration).
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

  // Le bouton de confirmation de la feuille : le dernier bouton qui porte ce
  // libelle (la feuille est au-dessus de la page).
  Finder confirmer(String libelle) =>
      find.widgetWithText(ActionPrincipale, libelle).last;

  ActionPrincipale bouton(WidgetTester tester, Key cle) =>
      tester.widget<ActionPrincipale>(find.byKey(cle));

  // Aucun texte visible ne dit « admin » ni « succes » (K-53.6, E7).
  void sansAdminNiSucces(WidgetTester tester) {
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String texte = w.data ?? '';
      expect(
        RegExp(r'admin(?!istrati)', caseSensitive: false).hasMatch(texte),
        isFalse,
        reason: texte,
      );
      expect(texte.toLowerCase().contains('succès'), isFalse, reason: texte);
    }
  }

  final Finder ligneConjointe = find.descendant(
    of: find.byKey(lignePlaceAdulteKey),
    matching: find.text(t.adulte.famille.place.maConjointe(prenom: 'Mariama')),
  );

  testWidgets('titulaire, Mon espace > Ma famille > Mariama, tapes : '
      'confirmation du doc section 19, resultat sans succes avec la date '
      'rendue, puis Ma famille dit le delai et son detail', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresseDemoAdulte(EcranDemoAdulte.accueil));
    final s = t.adulte.sortie;

    // La VRAIE destination « Mon espace », puis la VRAIE ligne famille.
    await taper(tester, find.text(t.adulte.nav.monEspace).first);
    await taper(
      tester,
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.maFamille),
      ),
    );
    expect(find.byType(FoyerPage), findsOneWidget);
    await taper(tester, ligneConjointe);
    expect(find.byType(PlaceConjointPage), findsOneWidget);
    expect(find.text(s.placePhrase(prenom: 'Mariama')), findsOneWidget);

    // Le bouton destructif, jamais plein (contrat B).
    final ActionPrincipale retirer = bouton(
      tester,
      PlaceConjointPage.retirerKey,
    );
    expect(retirer.libelle, s.retirerElle);
    expect(retirer.niveau, NiveauAction.destructive);

    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    expect(find.text(s.retirerQuestionElle), findsWidgets);
    expect(find.text(s.retirerConsequence), findsOneWidget);
    expect(find.text(t.commun.annuler), findsOneWidget);
    await taper(tester, confirmer(s.retirerElle));

    // Le resultat : rendu par la reponse, sans coche ni « succes ».
    expect(find.byKey(sortieResultatKey), findsOneWidget);
    expect(find.byType(EcranResultat), findsOneWidget);
    expect(find.text(s.resultatTitre), findsOneWidget);
    expect(find.text(s.resultatTitulaire), findsOneWidget);
    expect(find.text(s.delaiPhrase(date: date)), findsOneWidget);
    expect(find.textContaining('mois et'), findsNothing);
    sansAdminNiSucces(tester);

    await taper(tester, find.text(s.compris));
    expect(find.byType(FoyerPage), findsOneWidget);
    final Finder ligneDelai = find.descendant(
      of: find.byKey(lignePlaceAdulteKey),
      matching: find.text(
        t.adulte.famille.place.nouvelleInvitation(date: date),
      ),
    );
    expect(ligneDelai, findsOneWidget);

    // Le detail du delai (planche 3.3) : la date rendue, aucune invitation.
    await taper(tester, ligneDelai);
    expect(find.byType(DelaiPlacePage), findsOneWidget);
    expect(find.text(s.delaiTitre), findsWidgets);
    expect(find.text(s.delaiPhrase(date: date)), findsOneWidget);
    expect(find.text(t.adulte.invitation.envoyer), findsNothing);
    expect(find.textContaining('Inviter'), findsNothing);
    sansAdminNiSucces(tester);
    await taper(tester, find.byKey(DelaiPlacePage.pourquoiKey));
    expect(find.text(s.pourquoiPhrase), findsOneWidget);
  });

  testWidgets('renoncer : « Annuler » ne retire personne', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(EcranDemoAdulte.placeAdulte),
    );
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    await taper(tester, find.text(t.commun.annuler));
    expect(find.byKey(sortieResultatKey), findsNothing);
    expect(find.byType(PlaceConjointPage), findsOneWidget);
  });

  testWidgets('titulaire femme : « Retirer mon conjoint ? »', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.placeAdulte,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    final s = t.adulte.sortie;
    expect(bouton(tester, PlaceConjointPage.retirerKey).libelle, s.retirerLui);
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    expect(find.text(s.retirerQuestionLui), findsWidgets);
    expect(find.text(s.retirerQuestionElle), findsNothing);
  });

  testWidgets('second adulte, Mon espace > Forfait famille, tapes : « Quitter '
      'le forfait famille », resultat sans date, puis « Ajouter ma famille »', (
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
    final s = t.adulte.sortie;
    await taper(tester, find.text(t.adulte.nav.monEspace).first);
    await taper(
      tester,
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.forfaitFamille),
      ),
    );
    expect(find.byType(ForfaitFamillePage), findsOneWidget);
    expect(find.text(s.forfaitPhrase(prenom: 'Mamadou')), findsOneWidget);
    // Rien du foyer ni des enfants (F6, F7).
    expect(find.text('Aïcha'), findsNothing);

    final ActionPrincipale quitter = bouton(
      tester,
      ForfaitFamillePage.quitterKey,
    );
    expect(quitter.libelle, s.quitter);
    expect(quitter.niveau, NiveauAction.destructive);
    await taper(tester, find.byKey(ForfaitFamillePage.quitterKey));
    expect(find.text(s.quitterQuestion), findsWidgets);
    expect(find.text(s.quitterConsequence), findsOneWidget);
    await taper(tester, confirmer(s.quitterConfirmer));

    expect(find.text(s.resultatTitre), findsOneWidget);
    expect(find.text(s.resultatSecondAdulte), findsOneWidget);
    // Le delai porte sur le foyer du titulaire : aucune date ici.
    expect(find.textContaining(date), findsNothing);
    sansAdminNiSucces(tester);

    await taper(tester, find.text(s.compris));
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.ajouter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le titulaire informe du depart : la cloche de l\'Accueil ouvre '
      'le centre existant, la notification ouvre Ma famille et son delai', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.monEspace,
        etat: EtatDemoAdulte.conjointQuitte,
      ),
    );
    await taper(tester, find.text(t.adulte.nav.accueil).first);
    await taper(tester, find.byType(ClocheNotifications).first);
    expect(find.byType(NotificationsPage), findsOneWidget);
    final String titre = t.adulte.sortie.notificationQuitte(prenom: 'Mariama');
    expect(find.text(titre), findsOneWidget);
    await taper(
      tester,
      find.byKey(const ValueKey<String>('notification-demo-depart-forfait')),
    );
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(
      find.text(t.adulte.famille.place.nouvelleInvitation(date: date)),
      findsOneWidget,
    );
  });

  for (final (GenreTitulaireDemo genre, String attendu)
      in <(GenreTitulaireDemo, String)>[
        (
          GenreTitulaireDemo.homme,
          t.adulte.sortie.notificationRetiree(prenom: 'Mamadou'),
        ),
        (
          GenreTitulaireDemo.femme,
          t.adulte.sortie.notificationRetire(prenom: 'Mariama'),
        ),
      ]) {
    testWidgets('le second adulte retire en est informe (${genre.name})', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.accueil,
          etat: EtatDemoAdulte.conjointRetire,
          genre: genre,
          vue: VueDemoAdulte.secondAdulte,
        ),
      );
      await taper(tester, find.byType(ClocheNotifications).first);
      expect(find.text(attendu), findsOneWidget);
    });
  }

  testWidgets('celui qui agit ne recoit pas de notification de son geste', (
    WidgetTester tester,
  ) async {
    expect(
      DonneesAdulteDemo.notificationDepart(
        EtatDemoAdulte.conjointRetire,
        GenreTitulaireDemo.homme,
        VueDemoAdulte.titulaire,
      ),
      isNull,
    );
    expect(
      DonneesAdulteDemo.notificationDepart(
        EtatDemoAdulte.conjointQuitte,
        GenreTitulaireDemo.homme,
        VueDemoAdulte.secondAdulte,
      ),
      isNull,
    );
  });

  testWidgets('erreur reseau : D5, rien de change, le retrait reste possible', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.placeAdulte,
        etat: EtatDemoAdulte.erreurReseau,
      ),
    );
    final s = t.adulte.sortie;
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    await taper(tester, confirmer(s.retirerElle));
    expect(find.text(s.retraitEchecTitre), findsOneWidget);
    expect(find.text(s.echecPhrase), findsOneWidget);
    expect(find.textContaining("n'a pas été retir"), findsNothing);
    expect(find.byKey(sortieResultatKey), findsNothing);
    expect(bouton(tester, PlaceConjointPage.retirerKey).onPress, isNotNull);
  });

  testWidgets('erreur reseau, second adulte : « Le depart n\'a pas ete '
      'confirme »', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.forfaitFamille,
        etat: EtatDemoAdulte.erreurReseau,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    final s = t.adulte.sortie;
    await taper(tester, find.byKey(ForfaitFamillePage.quitterKey));
    await taper(tester, confirmer(s.quitterConfirmer));
    expect(find.text(s.departEchecTitre), findsOneWidget);
    expect(find.byKey(sortieResultatKey), findsNothing);
  });

  testWidgets('double envoi : le bouton attend, un seul resultat', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.placeAdulte,
        etat: EtatDemoAdulte.doubleSoumission,
      ),
    );
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    await tester.tap(confirmer(t.adulte.sortie.retirerElle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(bouton(tester, PlaceConjointPage.retirerKey).enCours, isTrue);
    await tester.tap(
      find.byKey(PlaceConjointPage.retirerKey),
      warnIfMissed: false,
    );
    await tester.pump(latenceSimulee);
    await tester.pumpAndSettle();
    expect(find.byKey(sortieResultatKey), findsOneWidget);
  });

  Widget forfait() => ForfaitFamillePage(onRetour: () {}, onCompris: () {});

  // Revue EA-R m13 : « Retirer » (titulaire) et « Quitter le forfait »
  // (second adulte), chacun avec un port espion sur SON appel.
  final List<(String, Widget Function(), Key, String, List<Override>)> sorties =
      <(String, Widget Function(), Key, String, List<Override>)>[
        (
          'retirer',
          () => PlaceConjointPage(
            placeFeminine: true,
            prenom: 'Mariama',
            onRetour: () {},
            onCompris: () {},
          ),
          PlaceConjointPage.retirerKey,
          t.adulte.sortie.retirerElle,
          const <Override>[],
        ),
        (
          'quitter le forfait',
          forfait,
          ForfaitFamillePage.quitterKey,
          t.adulte.sortie.quitterConfirmer,
          <Override>[
            forfaitFamilleProvider.overrideWith(
              (Ref _) async =>
                  const ForfaitFamilleVM(prenomTitulaire: 'Mamadou'),
            ),
          ],
        ),
      ];
  for (final (
        String nom,
        Widget Function() page,
        Key cle,
        String libelleConfirmer,
        List<Override> lecture,
      )
      in sorties) {
    testWidgets('hors ligne ($nom) : le bouton inactif, rien ne part', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      final _PortEspion port = _PortEspion();
      await monterPage(
        tester,
        page(),
        surcharges: <Override>[
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
          portSortieForfaitProvider.overrideWithValue(port),
          ...lecture,
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(t.adulte.sortie.horsLigne), findsOneWidget);
      expect(bouton(tester, cle).onPress, isNull);
      await tester.ensureVisible(find.byKey(cle));
      await tester.tap(find.byKey(cle), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(port.retraits + port.departs, 0);
    });

    testWidgets('le reseau coupe pendant la confirmation ($nom) : rien ne '
        'part', (WidgetTester tester) async {
      taille(tester, const Size(390, 844));
      final _PortEspion port = _PortEspion();
      final StreamController<bool> reseau = StreamController<bool>();
      addTearDown(reseau.close);
      reseau.add(false);
      await monterPage(
        tester,
        page(),
        surcharges: <Override>[
          horsLigneProvider.overrideWith((Ref _) => reseau.stream),
          portSortieForfaitProvider.overrideWithValue(port),
          ...lecture,
        ],
      );
      await tester.pumpAndSettle();
      // En ligne : le bouton ouvre la confirmation.
      expect(bouton(tester, cle).onPress, isNotNull);
      await taper(tester, find.byKey(cle));
      expect(confirmer(libelleConfirmer), findsOneWidget);
      // Le reseau coupe avant la confirmation : l'appel ne part pas.
      reseau.add(true);
      await tester.pumpAndSettle();
      await taper(tester, confirmer(libelleConfirmer));
      expect(port.retraits + port.departs, 0);
      expect(find.byKey(sortieResultatKey), findsNothing);
    });
  }

  testWidgets('en ligne, la confirmation appelle le bon port (le compteur '
      'de l\'espion est vivant)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final _PortEspion port = _PortEspion();
    await monterPage(
      tester,
      forfait(),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portSortieForfaitProvider.overrideWithValue(port),
        forfaitFamilleProvider.overrideWith(
          (Ref _) async => const ForfaitFamilleVM(prenomTitulaire: 'Mamadou'),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(ForfaitFamillePage.quitterKey));
    await taper(tester, confirmer(t.adulte.sortie.quitterConfirmer));
    expect(port.departs, 1);
    expect(port.retraits, 0);
  });

  testWidgets('sans source serveur : la sortie dit « indisponible » '
      '(EA-BR-21) et ne se relance pas', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      PlaceConjointPage(
        placeFeminine: true,
        prenom: 'Mariama',
        onRetour: () {},
        onCompris: () {},
      ),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
    );
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    await taper(tester, confirmer(t.adulte.sortie.retirerElle));
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.indisponible);
    expect(etat.dependance, 'EA-BR-21');
    expect(bouton(tester, PlaceConjointPage.retirerKey).onPress, isNull);
    expect(find.byKey(sortieResultatKey), findsNothing);
  });

  testWidgets('Forfait famille sans source : indisponible (EA-BR-22)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(tester, forfait());
    await tester.pumpAndSettle();
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.indisponible);
    expect(etat.dependance, 'EA-BR-22');
    expect(find.byKey(ForfaitFamillePage.quitterKey), findsNothing);
  });

  testWidgets('Forfait famille en chargement : un squelette, aucun faux '
      'prenom', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final Completer<ForfaitFamilleVM> jamais = Completer<ForfaitFamilleVM>();
    await monterPage(
      tester,
      forfait(),
      surcharges: <Override>[
        forfaitFamilleProvider.overrideWith((Ref _) => jamais.future),
      ],
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byKey(ForfaitFamillePage.quitterKey), findsNothing);
  });

  testWidgets('Forfait famille en echec de lecture : recuperable', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      forfait(),
      surcharges: <Override>[
        forfaitFamilleProvider.overrideWith(
          (Ref _) => Future<ForfaitFamilleVM>.error(StateError('coupure')),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<EtatSysteme>(find.byType(EtatSysteme)).onAction,
      isNotNull,
    );
    expect(find.byKey(ForfaitFamillePage.quitterKey), findsNothing);
  });

  testWidgets('validation en attente ou refusee : l\'etat sur la ligne, '
      'jamais la page de la place', (WidgetTester tester) async {
    for (final EtatDemoAdulte etat in <EtatDemoAdulte>[
      EtatDemoAdulte.validationEnAttente,
      EtatDemoAdulte.validationRefusee,
      EtatDemoAdulte.titulaireSansConjoint,
    ]) {
      expect(
        ecranPermisDemoAdulte(
          EcranDemoAdulte.placeAdulte,
          etat,
          VueDemoAdulte.titulaire,
        ),
        EcranDemoAdulte.maFamille,
        reason: etat.name,
      );
    }
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.validationEnAttente,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(lignePlaceAdulteKey),
        matching: find.text(t.adulte.famille.place.validationEnAttente),
      ),
      findsOneWidget,
    );
    sansAdminNiSucces(tester);
  });

  testWidgets('Forfait famille n\'est qu\'au second adulte rattache', (
    WidgetTester tester,
  ) async {
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.forfaitFamille,
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.titulaire,
      ),
      EcranDemoAdulte.monEspace,
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.forfaitFamille,
        EtatDemoAdulte.conjointQuitte,
        VueDemoAdulte.secondAdulte,
      ),
      EcranDemoAdulte.monEspace,
    );
  });

  testWidgets('a 1440 : le retrait en boite de dialogue, meme ordre', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 900));
    await monterCoquille(
      tester,
      adresseDemoAdulte(EcranDemoAdulte.placeAdulte),
    );
    await taper(tester, find.byKey(PlaceConjointPage.retirerKey));
    expect(find.text(t.adulte.sortie.retirerConsequence), findsOneWidget);
    await taper(tester, confirmer(t.adulte.sortie.retirerElle));
    expect(find.byKey(sortieResultatKey), findsOneWidget);
  });
}

/// Un serveur espion : il compte les sorties qui partent.
class _PortEspion implements PortSortieForfait {
  /// Les retraits du second adulte (titulaire).
  int retraits = 0;

  /// Les departs du forfait (second adulte).
  int departs = 0;

  @override
  Future<ResultatSortie> retirerSecondAdulte({required String cle}) async {
    retraits++;
    return const SortieFaite();
  }

  @override
  Future<ResultatSortie> quitterForfait({required String cle}) async {
    departs++;
    return const SortieFaite();
  }
}
