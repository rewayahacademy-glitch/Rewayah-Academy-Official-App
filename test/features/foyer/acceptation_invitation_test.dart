// EA-7 : l'invitation recue par le second adulte, atteinte depuis la VRAIE
// coquille adulte (K-07) : on tape la VRAIE destination « Accueil », la VRAIE
// cloche, puis la VRAIE ligne de notification. Puis le texte T1
// d'UX_REVIEW_07, les deux reponses de meme poids (derogation Q5), et les
// etats cote invite : acceptee, refusee, remplacement en attente de
// validation (T2), deja dans un autre foyer et inéligible (forme neutre, F4),
// perimee, reponse tardive apres annulation, erreur reseau (D5), double
// envoi, hors ligne, chargement, echec de lecture, indisponible ; sans
// compte, le renvoi vers la connexion existante.

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
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/page_etape.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show dateLongue;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

/// Un serveur qui rend [etat], avec sa date, a toute reponse.
class _ReponseDatee implements PortReponseInvitation {
  const _ReponseDatee(this.etat);

  final EtatInvitationRecue etat;

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) async =>
      ReponseRecue(etat);

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) async =>
      ReponseRecue(etat);
}

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app({required GoRouter routeur}) => ProviderScope(
    child: TranslationProvider(
      child: MaterialApp.router(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        locale: AppLocale.fr.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: routeur,
      ),
    ),
  );

  // La connexion existante, telle quelle : la demonstration y renvoie.
  final GoRoute connexion = GoRoute(
    path: Routes.connexion,
    builder: (BuildContext _, GoRouterState _) =>
        const Text('connexion-existante'),
  );

  Future<GoRouter> monterCoquille(WidgetTester tester, String depart) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: <RouteBase>[...routesDemoAdulte('dev'), connexion],
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(app(routeur: routeur));
    await tester.pumpAndSettle();
    return routeur;
  }

  // La page seule, avec ses fournisseurs surcharges (etats hors demonstration).
  Future<void> monterPage(
    WidgetTester tester, {
    required List<Override> surcharges,
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
            home: InvitationRecuePage(
              onRetour: () {},
              onMonEspace: (EtatInvitationRecue _) {},
            ),
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

  // Depuis l'Accueil : la cloche, puis la notification de l'invitation.
  Future<void> ouvrirInvitation(WidgetTester tester) async {
    await taper(tester, find.byType(ClocheNotifications).first);
    expect(find.byType(NotificationsPage), findsOneWidget);
    await taper(
      tester,
      find.byKey(
        const ValueKey<String>('notification-demo-invitation-forfait'),
      ),
    );
    expect(find.byType(InvitationRecuePage), findsOneWidget);
  }

  String adresse(
    EtatDemoAdulte etat, {
    EcranDemoAdulte ecran = EcranDemoAdulte.monEspace,
    GenreTitulaireDemo genre = GenreTitulaireDemo.homme,
  }) => adresseDemoAdulte(
    ecran,
    etat: etat,
    genre: genre,
    vue: VueDemoAdulte.secondAdulte,
  );

  ActionPrincipale bouton(WidgetTester tester, Key cle) =>
      tester.widget<ActionPrincipale>(find.byKey(cle));

  // Aucun texte visible ne dit « admin » (K-53.6).
  void sansAdmin(WidgetTester tester) {
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      expect(
        RegExp(
          r'admin(?!istrati)',
          caseSensitive: false,
        ).hasMatch(w.data ?? ''),
        isFalse,
        reason: w.data,
      );
    }
  }

  testWidgets('Mon espace > Accueil > cloche > notification, tapes : le texte '
      'T1, deux reponses de meme poids, puis « Vous avez rejoint » et Forfait '
      'famille dans Mon espace', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(tester, adresse(EtatDemoAdulte.invitationEnAttente));

    // La VRAIE destination « Accueil » de la coquille adulte.
    await taper(tester, find.text(t.adulte.nav.accueil).first);
    await ouvrirInvitation(tester);

    // Une page d'etape a une etape (UX_REVIEW_07 ligne 10 a).
    expect(find.byType(PageEtape), findsOneWidget);
    expect(find.text(t.commun.etape.sur(n: 1, total: 1)), findsOneWidget);
    final a = t.adulte.acceptation;
    expect(find.text(a.titre(prenom: 'Mamadou')), findsOneWidget);
    for (final String texte in <String>[
      a.verraTitre(prenom: 'Mamadou'),
      a.verraLui,
      a.verraPasTitre(prenom: 'Mamadou'),
      a.verraPas,
      a.pourquoiLui(prenom: 'Mamadou'),
      a.vous(prenom: 'Mamadou'),
      a.autres,
      a.duree(prenom: 'Mamadou'),
      a.partir,
      a.refus,
    ]) {
      expect(find.text(texte), findsOneWidget, reason: texte);
    }
    // Aucune duree inventee : la conservation n'est pas rendue.
    expect(find.textContaining('Nous gardons la trace'), findsNothing);
    // Pas de remplacement : pas de T2.
    expect(find.text(a.validation), findsNothing);
    // Aucune case « J'ai lu » (ligne 10 e).
    expect(find.byType(Checkbox), findsNothing);
    sansAdmin(tester);

    // Meme niveau, meme largeur (charte 09 section 3) ; l'une sous l'autre
    // sur telephone, refus d'abord.
    final ActionPrincipale refuser = bouton(
      tester,
      InvitationRecuePage.refuserKey,
    );
    final ActionPrincipale accepter = bouton(
      tester,
      InvitationRecuePage.accepterKey,
    );
    expect(refuser.niveau, accepter.niveau);
    expect(refuser.libelle, a.refuser);
    expect(accepter.libelle, a.accepter);
    final Size tRefus = tester.getSize(
      find.byKey(InvitationRecuePage.refuserKey),
    );
    final Size tAccord = tester.getSize(
      find.byKey(InvitationRecuePage.accepterKey),
    );
    expect(tRefus.width, tAccord.width);
    expect(
      tester.getTopLeft(find.byKey(InvitationRecuePage.refuserKey)).dy,
      lessThan(
        tester.getTopLeft(find.byKey(InvitationRecuePage.accepterKey)).dy,
      ),
    );

    await taper(tester, find.byKey(InvitationRecuePage.accepterKey));
    expect(find.text(a.rejoint(prenom: 'Mamadou')), findsOneWidget);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
    // La demonstration ne rend aucune date : aucun recu date invente.
    expect(find.byKey(InvitationRecuePage.recuKey), findsNothing);

    await taper(tester, find.byKey(InvitationRecuePage.monEspaceKey));
    expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.forfaitFamille),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a 1440, les deux reponses sont cote a cote, refus au bord de '
      'debut, meme largeur', (WidgetTester tester) async {
    taille(tester, const Size(1440, 900));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationEnAttente,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    final Rect refus = tester.getRect(
      find.byKey(InvitationRecuePage.refuserKey),
    );
    final Rect accord = tester.getRect(
      find.byKey(InvitationRecuePage.accepterKey),
    );
    expect(refus.top, accord.top);
    expect(refus.left, lessThan(accord.left));
    expect(refus.width, accord.width);
  });

  testWidgets('titulaire femme : « elle doit voir », « Elle saura aussi »', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationEnAttente,
        ecran: EcranDemoAdulte.invitationRecue,
        genre: GenreTitulaireDemo.femme,
      ),
    );
    final a = t.adulte.acceptation;
    expect(find.text(a.titre(prenom: 'Mariama')), findsOneWidget);
    expect(find.text(a.pourquoiElle(prenom: 'Mariama')), findsOneWidget);
    expect(find.text(a.verraElle), findsOneWidget);
    expect(find.text(a.verraLui), findsNothing);
  });

  testWidgets('refuser : « Invitation refusee », rien ne change', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationEnAttente,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    await taper(tester, find.byKey(InvitationRecuePage.refuserKey));
    expect(find.text(t.adulte.acceptation.refuseeTitre), findsOneWidget);
    expect(find.text(t.adulte.acceptation.refus), findsOneWidget);
    expect(find.textContaining('rejoint'), findsNothing);
  });

  testWidgets('remplacement : le texte T2, puis « En attente de validation '
      'administrative », jamais un rattachement', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.nouvelleDemande,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    expect(find.text(t.adulte.acceptation.validation), findsOneWidget);
    // T2 au moins a la taille du corps de T1, sans annonce a l'ouverture.
    final double corps = tester
        .widget<Text>(find.text(t.adulte.acceptation.refus))
        .style!
        .fontSize!;
    expect(
      tester
          .widget<Text>(find.text(t.adulte.acceptation.validation))
          .style!
          .fontSize,
      greaterThanOrEqualTo(corps),
    );
    expect(
      find.ancestor(
        of: find.text(t.adulte.acceptation.validation),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
      ),
      findsNothing,
    );
    await taper(tester, find.byKey(InvitationRecuePage.accepterKey));
    expect(
      find.text(t.adulte.famille.place.validationEnAttente),
      findsOneWidget,
    );
    expect(find.textContaining('rejoint'), findsNothing);
    sansAdmin(tester);
  });

  testWidgets('validation deja en attente : l\'etat seul, sans reponse', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.validationEnAttente,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    expect(
      find.text(t.adulte.famille.place.validationEnAttente),
      findsOneWidget,
    );
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
    expect(find.byKey(InvitationRecuePage.refuserKey), findsNothing);
  });

  testWidgets('deja dans un autre foyer : la seule phrase neutre (F4), aucun '
      'bouton de reponse', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.dejaDansUnAutreFoyer,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    expect(find.text(t.adulte.acceptation.impossible), findsOneWidget);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
    expect(find.textContaining('autre foyer'), findsNothing);
  });

  testWidgets('inéligible : la meme forme neutre, sans motif', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      surcharges: <Override>[
        invitationRecueProvider.overrideWith(
          (Ref _) async => const InvitationNonAcceptable(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.acceptation.impossible), findsOneWidget);
    expect(find.textContaining('genre'), findsNothing);
  });

  testWidgets('expiree : « Cette invitation n\'est plus valable »', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationExpiree,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    expect(find.text(t.adulte.acceptation.perimee), findsOneWidget);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
  });

  testWidgets('reponse tardive apres annulation : l\'acceptation ne rattache '
      'personne, Mon espace ne montre pas Forfait famille', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationAnnulee,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    await taper(tester, find.byKey(InvitationRecuePage.accepterKey));
    expect(find.text(t.adulte.acceptation.perimee), findsOneWidget);
    expect(find.textContaining('rejoint'), findsNothing);
    await taper(tester, find.byKey(InvitationRecuePage.monEspaceKey));
    expect(
      find.descendant(
        of: find.byKey(MonEspaceAdultePage.ligneFamilleKey),
        matching: find.text(t.adulte.famille.forfaitFamille),
      ),
      findsNothing,
    );
  });

  testWidgets('erreur reseau : D5, rien de change, la reponse reste possible', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.erreurReseau,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    await taper(tester, find.byKey(InvitationRecuePage.accepterKey));
    expect(
      find.text(t.adulte.acceptation.acceptationEchecTitre),
      findsOneWidget,
    );
    expect(find.text(t.adulte.acceptation.echecPhrase), findsOneWidget);
    expect(find.textContaining("n'a pas été envoy"), findsNothing);
    expect(find.textContaining('rejoint'), findsNothing);
    expect(bouton(tester, InvitationRecuePage.accepterKey).onPress, isNotNull);

    await taper(tester, find.byKey(InvitationRecuePage.refuserKey));
    expect(find.text(t.adulte.acceptation.refusEchecTitre), findsOneWidget);
    expect(find.text(t.adulte.acceptation.acceptationEchecTitre), findsNothing);
  });

  testWidgets('double envoi : un seul appui compte, l\'autre reponse attend', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.doubleSoumission,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    final Finder accord = find.byKey(InvitationRecuePage.accepterKey);
    await tester.ensureVisible(accord);
    await tester.tap(accord);
    await tester.pump();
    expect(bouton(tester, InvitationRecuePage.accepterKey).enCours, isTrue);
    expect(bouton(tester, InvitationRecuePage.refuserKey).onPress, isNull);
    await tester.tap(accord, warnIfMissed: false);
    await tester.pump(latenceSimulee);
    await tester.pumpAndSettle();
    expect(
      find.text(t.adulte.acceptation.rejoint(prenom: 'Mamadou')),
      findsOneWidget,
    );
  });

  testWidgets('hors ligne : les deux reponses inactives, rien ne part', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        invitationRecueProvider.overrideWith(
          (Ref _) async => const InvitationARepondre(
            prenomTitulaire: 'Mamadou',
            titulaireFeminin: false,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.acceptation.horsLigne), findsOneWidget);
    expect(bouton(tester, InvitationRecuePage.accepterKey).onPress, isNull);
    expect(bouton(tester, InvitationRecuePage.refuserKey).onPress, isNull);
  });

  testWidgets('chargement : un squelette, aucun faux prenom', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final Completer<EtatInvitationRecue> jamais =
        Completer<EtatInvitationRecue>();
    await monterPage(
      tester,
      surcharges: <Override>[
        invitationRecueProvider.overrideWith((Ref _) => jamais.future),
      ],
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
  });

  testWidgets('echec de lecture : un etat recuperable, avec Reessayer', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterPage(
      tester,
      surcharges: <Override>[
        invitationRecueProvider.overrideWith(
          (Ref _) => Future<EtatInvitationRecue>.error(StateError('coupure')),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(EtatSysteme), findsOneWidget);
    expect(
      tester.widget<EtatSysteme>(find.byType(EtatSysteme)).onAction,
      isNotNull,
    );
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
  });

  testWidgets('sans source serveur : indisponible (EA-BR-20), jamais un faux '
      'etat', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    await monterPage(tester, surcharges: const <Override>[]);
    await tester.pumpAndSettle();
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.indisponible);
    expect(etat.dependance, 'EA-BR-20');
  });

  // Revue EA-7 : apres une reponse, le retour ne ramene jamais a
  // l'invitation « a repondre » ; ni la cloche ni l'adresse ne la rouvrent.
  for (final (String nom, Key cle, EtatDemoAdulte apres)
      in <(String, Key, EtatDemoAdulte)>[
        (
          'accepter',
          InvitationRecuePage.accepterKey,
          EtatDemoAdulte.conjointActif,
        ),
        (
          'refuser',
          InvitationRecuePage.refuserKey,
          EtatDemoAdulte.titulaireSansConjoint,
        ),
      ]) {
    testWidgets('$nom, revenir, rouvrir : aucun bouton de reponse', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 844));
      final GoRouter routeur = await monterCoquille(
        tester,
        adresse(
          EtatDemoAdulte.invitationEnAttente,
          ecran: EcranDemoAdulte.invitationRecue,
        ),
      );
      await taper(tester, find.byKey(cle));
      expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);

      await taper(tester, find.byType(DisqueRetour).first);
      expect(find.byType(MonEspaceAdultePage), findsOneWidget);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.queryParameters['etat'],
        apres.name,
      );

      // Par la cloche : plus de notification d'invitation a rouvrir.
      await taper(tester, find.text(t.adulte.nav.accueil).first);
      await taper(tester, find.byType(ClocheNotifications).first);
      expect(
        find.byKey(
          const ValueKey<String>('notification-demo-invitation-forfait'),
        ),
        findsNothing,
      );

      // Par l'adresse : l'invitation de cette situation n'a plus de reponse.
      routeur.go(adresse(apres, ecran: EcranDemoAdulte.invitationRecue));
      await tester.pumpAndSettle();
      expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
      expect(find.byKey(InvitationRecuePage.refuserKey), findsNothing);
    });
  }

  testWidgets('reponse tardive, revenir, rouvrir : « plus valable », sans '
      'reponse', (WidgetTester tester) async {
    taille(tester, const Size(390, 844));
    final GoRouter routeur = await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationAnnulee,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    await taper(tester, find.byKey(InvitationRecuePage.accepterKey));
    await taper(tester, find.byType(DisqueRetour).first);
    final String etat = routeur
        .routerDelegate
        .currentConfiguration
        .uri
        .queryParameters['etat']!;
    routeur.go(
      adresse(
        EtatDemoAdulte.values.byName(etat),
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adulte.acceptation.perimee), findsOneWidget);
    expect(find.byKey(InvitationRecuePage.accepterKey), findsNothing);
  });

  testWidgets('recu date : montre seulement la date rendue par le serveur', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    final DateTime le = DateTime(2026, 9, 27, 10);
    await monterPage(
      tester,
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        invitationRecueProvider.overrideWith(
          (Ref _) async => const InvitationARepondre(
            prenomTitulaire: 'Mamadou',
            titulaireFeminin: false,
          ),
        ),
        portReponseInvitationProvider.overrideWithValue(
          _ReponseDatee(InvitationRefuseeParVous(enregistreeLe: le)),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await taper(tester, find.byKey(InvitationRecuePage.refuserKey));
    expect(find.text(t.adulte.acceptation.refuseeTitre), findsOneWidget);
    expect(
      find.text(t.adulte.acceptation.recu(date: dateLongue(le))),
      findsOneWidget,
    );
  });

  testWidgets('a 1440, 32 entre les sections du texte T1 (contrat A)', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(1440, 900));
    await monterCoquille(
      tester,
      adresse(
        EtatDemoAdulte.invitationEnAttente,
        ecran: EcranDemoAdulte.invitationRecue,
      ),
    );
    final a = t.adulte.acceptation;
    final double basTexte = tester.getBottomLeft(find.text(a.partir)).dy;
    final double hautTitre = tester.getTopLeft(find.text(a.refusTitre)).dy;
    expect(hautTitre - basTexte, 32);
  });

  testWidgets('le titulaire n\'ouvre jamais l\'invitation recue', (
    WidgetTester tester,
  ) async {
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.invitationRecue,
        EtatDemoAdulte.invitationEnAttente,
        VueDemoAdulte.titulaire,
      ),
      EcranDemoAdulte.monEspace,
    );
    expect(
      ecranPermisDemoAdulte(
        EcranDemoAdulte.invitationRecue,
        EtatDemoAdulte.conjointActif,
        VueDemoAdulte.secondAdulte,
      ),
      EcranDemoAdulte.monEspace,
    );
  });

  testWidgets('sans compte : le renvoi vers la connexion existante', (
    WidgetTester tester,
  ) async {
    taille(tester, const Size(390, 844));
    await monterCoquille(
      tester,
      adresseDemoAdulte(EcranDemoAdulte.invitationSansCompte),
    );
    expect(find.text(t.adulte.acceptation.sansCompte), findsOneWidget);
    // Sans session, rien n'est lu : ni prenom, ni etat.
    expect(find.textContaining('Mamadou'), findsNothing);
    await taper(tester, find.byKey(InvitationSansComptePage.continuerKey));
    expect(find.text('connexion-existante'), findsOneWidget);
  });
}
