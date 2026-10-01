// EA-6 : inviter la conjointe ou le conjoint, atteint depuis la VRAIE
// coquille adulte (K-07) : on tape la VRAIE destination « Mon espace », la
// VRAIE ligne « Ma famille », puis la VRAIE ligne de la place. Puis les deux
// etapes (retour avec la saisie gardee), l'envoi neutre (F4), les libelles
// selon le genre (F3), l'annulation confirmee, et les etats du doc section
// 5.2 cote titulaire : envoyee, expiree, annulee, erreur reseau, double
// envoi, reponse tardive apres annulation, hors ligne, indisponible.

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
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/page_etape.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

void main() {
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

  bool placeDit(WidgetTester tester, String texte) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(lignePlaceAdulteKey),
          matching: find.byType(Text),
        ),
      )
      .any((Text w) => w.data == texte);

  Future<void> taperPlace(WidgetTester tester, String libelle) async {
    final Finder ligne = find.descendant(
      of: find.byKey(lignePlaceAdulteKey),
      matching: find.text(libelle),
    );
    await tester.ensureVisible(ligne);
    await tester.tap(ligne);
    await tester.pumpAndSettle();
  }

  // Le destructif de la feuille de confirmation, pose au-dessus de la page.
  Finder confirmerAnnulation() => find
      .byWidgetPredicate(
        (Widget w) =>
            w is ActionPrincipale &&
            w.niveau == NiveauAction.destructive &&
            w.libelle == t.adulte.invitation.annuler &&
            w.key != InvitationEnvoyeePage.annulerKey,
      )
      .last;

  Future<void> saisir(
    WidgetTester tester, {
    String prenom = 'Mariama',
    String nom = '',
    String courriel = 'mariama@example.com',
  }) async {
    await tester.enterText(find.byKey(InviterConjointPage.prenomKey), prenom);
    await tester.enterText(find.byKey(InviterConjointPage.nomKey), nom);
    await tester.enterText(
      find.byKey(InviterConjointPage.courrielKey),
      courriel,
    );
    await tester.pump();
  }

  // Vrai quand le noeud pose sous [cle] a le focus (EA-6c).
  bool aLeFocus(WidgetTester tester, Key cle) => tester
      .widget<Focus>(
        find
            .descendant(of: find.byKey(cle), matching: find.byType(Focus))
            .first,
      )
      .focusNode!
      .hasFocus;

  Future<void> taper(WidgetTester tester, Key cle) async {
    await tester.ensureVisible(find.byKey(cle));
    await tester.tap(find.byKey(cle));
    await tester.pumpAndSettle();
  }

  testWidgets('Mon espace > Ma famille > Ajouter une conjointe, tapes : deux '
      'etapes, retour avec la saisie, envoi, puis « Invitation envoyee » sur '
      'la ligne', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        etat: EtatDemoAdulte.titulaireSansConjoint,
      ),
    );

    await tester.tap(find.text(t.adulte.nav.monEspace).first);
    await tester.pumpAndSettle();
    final Finder famille = find.descendant(
      of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
      matching: find.text(t.adulte.famille.maFamille),
    );
    await tester.ensureVisible(famille);
    await tester.tap(famille);
    await tester.pumpAndSettle();
    await taperPlace(tester, t.adulte.famille.place.ajouterConjointe);

    // Etape 1 : titre (E4) et en-tete selon le genre (F3), texte du doc
    // section 19, aide de l'adresse de la planche 2.2 accordee au genre.
    expect(find.byType(InviterConjointPage), findsOneWidget);
    expect(find.byType(FoyerPage), findsNothing);
    expect(find.text(t.adulte.invitation.titreElle), findsOneWidget);
    expect(find.text(t.adulte.invitation.enteteElle), findsOneWidget);
    expect(find.text(t.adulte.invitation.phraseElle), findsOneWidget);
    expect(find.text(t.adulte.invitation.courrielAideElle), findsOneWidget);
    // E4 : « Continuer » a l'etape 1.
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(InviterConjointPage.verifierKey))
          .libelle,
      'Continuer',
    );
    expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);
    // Aucune notice « Une seule conjointe peut etre lie(e) » (F21).
    expect(find.textContaining('lié(e)'), findsNothing);
    // Un seul bouton dominant.
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is ActionPrincipale && w.niveau == NiveauAction.principale,
      ),
      findsOneWidget,
    );

    // Champs vides : les erreurs de saisie, pas d'etape 2.
    await taper(tester, InviterConjointPage.verifierKey);
    expect(find.text(t.adulte.invitation.prenomRequis), findsOneWidget);
    expect(find.text(t.adulte.invitation.courrielRequis), findsOneWidget);
    expect(find.byKey(InviterConjointPage.recapitulatifKey), findsNothing);

    await saisir(tester, nom: 'Diallo');
    await taper(tester, InviterConjointPage.verifierKey);

    // Etape 2 : « Verifier et envoyer », le recapitulatif ; son titre prend
    // le focus ; E4 : « Envoyer l'invitation ».
    expect(find.text(t.adulte.invitation.verifierTitre), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 2, total: 2)), findsOneWidget);
    expect(aLeFocus(tester, InviterConjointPage.focusEtape2Key), isTrue);
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(InviterConjointPage.envoyerKey))
          .libelle,
      "Envoyer l'invitation",
    );
    final Finder recap = find.byKey(InviterConjointPage.recapitulatifKey);
    for (final String valeur in <String>[
      'Mariama',
      'Diallo',
      'mariama@example.com',
    ]) {
      expect(
        find.descendant(of: recap, matching: find.text(valeur)),
        findsOneWidget,
      );
    }

    // « Modifier » revient a l'etape 1 avec les champs preremplis (W-337).
    await taper(tester, InviterConjointPage.modifierKey);
    expect(find.text(t.commun.etape.sur(n: 1, total: 2)), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(InviterConjointPage.courrielKey))
          .controller!
          .text,
      'mariama@example.com',
    );
    await taper(tester, InviterConjointPage.verifierKey);

    // Envoi : le resultat suit la reponse (E7), jamais un rattachement.
    await taper(tester, InviterConjointPage.envoyerKey);
    expect(find.byKey(InviterConjointPage.envoyeeKey), findsOneWidget);
    expect(find.text(t.adulte.invitation.envoyeeTitre), findsWidgets);
    expect(
      find.text(
        t.adulte.invitation.envoyeePhrase(courriel: 'mariama@example.com'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('rejoint'), findsNothing);
    expect(aLeFocus(tester, InviterConjointPage.focusResultatKey), isTrue);

    // Retour a Ma famille : la ligne dit « Invitation envoyee ».
    await taper(tester, InviterConjointPage.revenirKey);
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(placeDit(tester, t.adulte.famille.place.invitationEnvoyee), isTrue);
    expect(
      placeDit(tester, t.adulte.famille.place.maConjointe(prenom: 'Mariama')),
      isFalse,
    );
  });

  testWidgets('titulaire femme : « Ajouter un conjoint », « pour lui » (F3)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.titulaireSansConjoint,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    await taperPlace(tester, t.adulte.famille.place.ajouterConjoint);
    expect(find.text(t.adulte.invitation.titreLui), findsOneWidget);
    expect(find.text(t.adulte.invitation.enteteLui), findsOneWidget);
    expect(find.text(t.adulte.invitation.phraseLui), findsOneWidget);
    expect(find.text(t.adulte.invitation.courrielAideLui), findsOneWidget);
    expect(find.text(t.adulte.invitation.enteteElle), findsNothing);
    expect(find.text(t.adulte.invitation.courrielAideElle), findsNothing);
  });

  testWidgets('adresse mal formee : erreur de format seulement, a la sortie '
      'du champ (F4)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.inviterConjoint,
        etat: EtatDemoAdulte.titulaireSansConjoint,
      ),
    );
    await tester.tap(find.byKey(InviterConjointPage.courrielKey));
    await tester.enterText(
      find.byKey(InviterConjointPage.courrielKey),
      'mariama',
    );
    await tester.pump();
    // Pendant la saisie : rien.
    expect(find.text(t.adulte.invitation.courrielInvalide), findsNothing);
    // Sortie du champ : l'erreur de format.
    await tester.tap(find.byKey(InviterConjointPage.prenomKey));
    await tester.pump();
    expect(find.text(t.adulte.invitation.courrielInvalide), findsOneWidget);
    expect(courrielBienForme('mariama@example.com'), isTrue);
    expect(courrielBienForme('mariama@example'), isFalse);
  });

  testWidgets('erreur reseau : dite, saisie gardee, « Envoyer » reste la '
      'reprise', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.inviterConjoint,
        etat: EtatDemoAdulte.erreurReseau,
      ),
    );
    await saisir(tester);
    await taper(tester, InviterConjointPage.verifierKey);
    await taper(tester, InviterConjointPage.envoyerKey);
    // D5 mot pour mot : jamais « pas partie », « pas envoyee ».
    expect(find.text("L'envoi n'a pas été confirmé."), findsOneWidget);
    expect(
      find.text(
        'Vérifiez avant de réessayer. Vos informations sont '
        'conservées.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('pas partie'), findsNothing);
    expect(find.textContaining('pas été envoy'), findsNothing);
    expect(aLeFocus(tester, InviterConjointPage.focusEchecKey), isTrue);
    expect(find.byKey(InviterConjointPage.envoyeeKey), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(InviterConjointPage.recapitulatifKey),
        matching: find.text('mariama@example.com'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(InviterConjointPage.envoyerKey))
          .onPress,
      isNotNull,
    );
  });

  testWidgets('double envoi : le bouton attend, un seul appel part', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final _PortCompteur port = _PortCompteur();
    await tester.pumpWidget(
      _page(
        overrides: <Override>[
          portInvitationConjointProvider.overrideWithValue(port),
        ],
        child: InviterConjointPage(
          placeFeminine: true,
          onAbandon: () {},
          onTerminee: () {},
        ),
      ),
    );
    await tester.pump();
    await saisir(tester);
    await taper(tester, InviterConjointPage.verifierKey);
    await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
    await tester.pump();
    await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
    await tester.pump();
    expect(port.envois, 1);
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(InviterConjointPage.envoyerKey))
          .enCours,
      isTrue,
    );
    port.reponse.complete(const InvitationPartie());
    await tester.pumpAndSettle();
    expect(find.byKey(InviterConjointPage.envoyeeKey), findsOneWidget);
    expect(port.envois, 1);
  });

  testWidgets('double soumission de la demonstration : attente, puis envoyee', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.inviterConjoint,
        etat: EtatDemoAdulte.doubleSoumission,
      ),
    );
    await saisir(tester);
    await taper(tester, InviterConjointPage.verifierKey);
    await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
    await tester.pump();
    await tester.tap(find.byKey(InviterConjointPage.envoyerKey));
    await tester.pump();
    expect(
      tester
          .widget<ActionPrincipale>(find.byKey(InviterConjointPage.envoyerKey))
          .enCours,
      isTrue,
    );
    await tester.pump(latenceSimulee);
    await tester.pumpAndSettle();
    expect(find.byKey(InviterConjointPage.envoyeeKey), findsOneWidget);
  });

  testWidgets('invitation envoyee : sa ligne ouvre le detail ; annuler est '
      'confirme, puis la ligne dit « annulee » sans rattachement', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.invitationEnAttente,
      ),
    );
    expect(
      placeDit(
        tester,
        t.adulte.famille.place.envoyeeA(courriel: 'mariama.diallo@example.com'),
      ),
      isTrue,
    );
    await taperPlace(tester, t.adulte.famille.place.invitationEnvoyee);
    expect(find.byType(InvitationEnvoyeePage), findsOneWidget);
    expect(find.text('mariama.diallo@example.com'), findsOneWidget);
    // Destructif : jamais un bouton plein.
    expect(
      tester
          .widget<ActionPrincipale>(
            find.byKey(InvitationEnvoyeePage.annulerKey),
          )
          .niveau,
      NiveauAction.destructive,
    );

    // Renoncer : rien ne change.
    await taper(tester, InvitationEnvoyeePage.annulerKey);
    expect(
      find.text(t.adulte.invitation.annulerQuestion(prenom: 'Mariama')),
      findsOneWidget,
    );
    await tester.tap(find.text(t.adulte.invitation.garder));
    await tester.pumpAndSettle();
    expect(find.byType(InvitationEnvoyeePage), findsOneWidget);

    // Confirmer : retour a Ma famille, place libre « annulee ».
    await taper(tester, InvitationEnvoyeePage.annulerKey);
    await tester.tap(confirmerAnnulation());
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(placeDit(tester, t.adulte.famille.place.ajouterConjointe), isTrue);
    expect(placeDit(tester, t.adulte.famille.place.annulee), isTrue);
  });

  testWidgets('reponse tardive apres annulation : l\'acceptation de Mariama '
      'arrive apres l\'annulation, personne n\'est rattache', (
    WidgetTester tester,
  ) async {
    // Le serveur de demonstration rattache bien sur une invitation encore
    // envoyee : la simulation PEUT rattacher, le cas tardif est reel.
    expect(
      DonneesAdulteDemo.acceptationRecue(
        DonneesAdulteDemo.invitationEnvoyee(GenreTitulaireDemo.homme),
        'Mariama',
      ),
      isA<PlaceOccupee>(),
    );
    // Apres l'annulation, la meme acceptation ne rattache personne.
    final EtatPlaceAdulte apres = DonneesAdulteDemo.place(
      EtatDemoAdulte.invitationAnnulee,
      GenreTitulaireDemo.homme,
    );
    expect(apres, isA<PlaceDisponible>());
    expect((apres as PlaceDisponible).precedente, FinInvitation.annulee);

    // Parcours complet : annuler, puis Ma famille lit la place rendue apres
    // l'acceptation tardive. Echoue des que quelqu'un est rattache.
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.invitationEnvoyee,
        etat: EtatDemoAdulte.invitationEnAttente,
      ),
    );
    await taper(tester, InvitationEnvoyeePage.annulerKey);
    await tester.tap(confirmerAnnulation());
    await tester.pumpAndSettle();
    expect(find.byType(FoyerPage), findsOneWidget);
    expect(placeDit(tester, t.adulte.famille.place.annulee), isTrue);
    expect(placeDit(tester, t.adulte.famille.place.ajouterConjointe), isTrue);
    expect(
      placeDit(tester, t.adulte.famille.place.maConjointe(prenom: 'Mariama')),
      isFalse,
    );
    expect(
      find.descendant(
        of: find.byKey(lignePlaceAdulteKey),
        matching: find.byType(AvatarTile),
      ),
      findsNothing,
    );
  });

  testWidgets('annulation en erreur reseau : dite, l\'invitation reste', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.invitationEnvoyee,
        etat: EtatDemoAdulte.erreurReseau,
      ),
    );
    await taper(tester, InvitationEnvoyeePage.annulerKey);
    await tester.tap(confirmerAnnulation());
    await tester.pumpAndSettle();
    expect(find.byType(InvitationEnvoyeePage), findsOneWidget);
    // D5 mot pour mot : jamais « pas annulee », « toujours envoyee ».
    expect(find.text("L'annulation n'a pas été confirmée."), findsOneWidget);
    expect(find.text('Vérifiez avant de réessayer.'), findsOneWidget);
    expect(find.textContaining('pas été annul'), findsNothing);
    expect(find.textContaining('toujours envoy'), findsNothing);
    expect(aLeFocus(tester, InviterConjointPage.focusEchecKey), isTrue);
  });

  testWidgets('detail a 1440 : le contenu part du bord de la tete de page', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 900));
    await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.invitationEnvoyee,
        etat: EtatDemoAdulte.invitationEnAttente,
      ),
    );
    final double tete = tester.getTopLeft(find.byType(DisqueRetour)).dx;
    final double contenu = tester
        .getTopLeft(find.text(t.adulte.invitation.detailPhrase))
        .dx;
    expect((contenu - tete).abs(), lessThanOrEqualTo(1));
  });

  testWidgets('expiree et annulee : place libre, sans delai, fin dite sur la '
      'ligne (F5, F21)', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.invitationExpiree,
      ),
    );
    expect(placeDit(tester, t.adulte.famille.place.ajouterConjointe), isTrue);
    expect(placeDit(tester, t.adulte.famille.place.expiree), isTrue);
    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: EtatDemoAdulte.invitationAnnulee,
      ),
    );
    await tester.pumpAndSettle();
    expect(placeDit(tester, t.adulte.famille.place.annulee), isTrue);
    // La place libre rouvre l'invitation.
    await taperPlace(tester, t.adulte.famille.place.ajouterConjointe);
    expect(find.byType(InviterConjointPage), findsOneWidget);
  });

  testWidgets('jamais d\'invitation sur une place occupee ou en delai, meme '
      'par l\'adresse', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresseDemoAdulte(
        EcranDemoAdulte.inviterConjoint,
        etat: EtatDemoAdulte.conjointActif,
      ),
    );
    expect(find.byType(InviterConjointPage), findsNothing);
    expect(find.byType(FoyerPage), findsOneWidget);
    for (final (EcranDemoAdulte ecran, EtatDemoAdulte etat)
        in <(EcranDemoAdulte, EtatDemoAdulte)>[
          (EcranDemoAdulte.inviterConjoint, EtatDemoAdulte.delai60),
          (EcranDemoAdulte.inviterConjoint, EtatDemoAdulte.validationEnAttente),
          (
            EcranDemoAdulte.invitationEnvoyee,
            EtatDemoAdulte.titulaireSansConjoint,
          ),
        ]) {
      routeur.go(adresseDemoAdulte(ecran, etat: etat));
      await tester.pumpAndSettle();
      expect(find.byType(FoyerPage), findsOneWidget, reason: etat.name);
    }
    // Le second adulte n'invite personne (F6).
    routeur.go(
      adresseDemoAdulte(
        EcranDemoAdulte.inviterConjoint,
        etat: EtatDemoAdulte.titulaireSansConjoint,
        vue: VueDemoAdulte.secondAdulte,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InviterConjointPage), findsNothing);
    expect(find.byType(FoyerPage), findsNothing);
  });

  group('etats de la page', () {
    testWidgets('hors ligne : « Envoyer » attend, dit pourquoi', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _page(
          horsLigne: true,
          child: InviterConjointPage(
            placeFeminine: true,
            onAbandon: () {},
            onTerminee: () {},
          ),
        ),
      );
      await tester.pump();
      await saisir(tester);
      await taper(tester, InviterConjointPage.verifierKey);
      expect(find.text(t.adulte.invitation.horsLigne), findsOneWidget);
      // Rien ne part tout seul au retour de la connexion.
      expect(find.textContaining('pourra partir'), findsNothing);
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(InviterConjointPage.envoyerKey),
            )
            .onPress,
        isNull,
      );
    });

    testWidgets('sans source serveur (EA-BR-15) : indisponible, jamais '
        '« envoyee »', (WidgetTester tester) async {
      taille(tester, const Size(390, 844));
      await tester.pumpWidget(
        _page(
          child: InviterConjointPage(
            placeFeminine: false,
            onAbandon: () {},
            onTerminee: () {},
          ),
        ),
      );
      await tester.pump();
      await saisir(tester, prenom: 'Mamadou', courriel: 'mamadou@example.com');
      await taper(tester, InviterConjointPage.verifierKey);
      await taper(tester, InviterConjointPage.envoyerKey);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.indisponible,
        ),
        findsOneWidget,
      );
      expect(find.byKey(InviterConjointPage.envoyeeKey), findsNothing);
    });

    testWidgets('refus neutre du serveur (F4) : rien sur l\'adresse', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      final _PortCompteur port = _PortCompteur()
        ..reponse.complete(const InvitationRefusee());
      bool quitte = false;
      await tester.pumpWidget(
        _page(
          overrides: <Override>[
            portInvitationConjointProvider.overrideWithValue(port),
          ],
          child: InviterConjointPage(
            placeFeminine: true,
            onAbandon: () => quitte = true,
            onTerminee: () {},
          ),
        ),
      );
      await tester.pump();
      await saisir(tester);
      await taper(tester, InviterConjointPage.verifierKey);
      await taper(tester, InviterConjointPage.envoyerKey);
      expect(find.text(t.adulte.invitation.refusTitre), findsOneWidget);
      expect(find.textContaining('compte'), findsNothing);
      expect(aLeFocus(tester, InviterConjointPage.focusEchecKey), isTrue);
      // « Envoyer » n'est plus actif ; l'action est de revenir a Ma famille.
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(InviterConjointPage.envoyerKey),
            )
            .onPress,
        isNull,
      );
      final Finder revenir = find.descendant(
        of: find.byType(EtatSysteme),
        matching: find.text(t.adulte.invitation.revenirMaFamille),
      );
      expect(revenir, findsOneWidget);
      await tester.ensureVisible(revenir);
      await tester.tap(revenir);
      await tester.pump();
      expect(quitte, isTrue);
    });

    testWidgets('retour de l\'etape 1 : quitte ; bureau : colonne bornee', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(1440, 900));
      bool quitte = false;
      await tester.pumpWidget(
        _page(
          child: InviterConjointPage(
            placeFeminine: true,
            onAbandon: () => quitte = true,
            onTerminee: () {},
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byKey(InviterConjointPage.prenomKey)).width,
        lessThanOrEqualTo(560),
      );
      expect(find.byType(RangeeEtape), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pump();
      expect(quitte, isTrue);
    });
  });
}

/// Un port qui compte les envois et repond quand le test le decide.
class _PortCompteur implements PortInvitationConjoint {
  int envois = 0;
  final Completer<ResultatInvitation> reponse = Completer<ResultatInvitation>();

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint _) {
    envois++;
    return reponse.future;
  }

  @override
  Future<ResultatAnnulation> annuler() async => const AnnulationFaite();
}

Widget _page({
  required Widget child,
  List<Override> overrides = const <Override>[],
  bool horsLigne = false,
}) => ProviderScope(
  overrides: <Override>[
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
    ...overrides,
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    ),
  ),
);
