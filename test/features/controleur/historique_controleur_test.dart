// CT-7 : CTR-05 Historique et CTR-06 Detail, depuis la VRAIE route de
// demonstration. Historique -> ouvrir un rapport -> lien vers le fil de la
// mission ; « A terminer » -> compte rendu ; « Ajouter un complement » ouvre
// le parcours CTR-03B (CT-8) : envoi, echec honnete, parent intact ; le port
// par defaut n'invente aucun rapport.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/controleur/complement_rapport_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1000, 1000),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesDemoControleur('dev'),
  );
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

Future<void> _attendre(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await _attendre(tester);
}

final RapportControle _parent = RapportControle(
  id: 'demo-rapport-parent',
  missionId: 'demo-mission',
  classe: 'Al-Badr',
  enseignant: 'Sayyid Karim',
  debut: DateTime(2026, 9, 24, 17),
  dureeObservee: const Duration(minutes: 20),
  statut: StatutRapport.envoye,
  faits: FaitsVisite(
    debutPrevu: DateTime(2026, 9, 24, 17),
    finPrevue: DateTime(2026, 9, 24, 17, 45),
    debutReel: DateTime(2026, 9, 24, 17),
    finReelle: DateTime(2026, 9, 24, 17, 45),
    participantsAttendus: 3,
    participantsPresents: 3,
    reconnexions: 0,
  ),
  observation: const ObservationControle(
    important: false,
    nature: NatureObservation.aSuivre,
    domaine: DomaineObservation.climat,
    personne: PersonneConcernee.classeEntiere,
    texte: 'Texte d’origine.',
  ),
  complements: <ComplementRapport>[
    ComplementRapport(date: DateTime(2026, 9, 24, 18), texte: 'Premier.'),
  ],
);

/// Un rapport envoye d'aujourd'hui, dans le filtre Periode par defaut.
class _PortDuJour implements PortHistorique {
  @override
  Future<List<RapportControle>> rapports() async => <RapportControle>[
    RapportControle(
      id: 'rapport-du-jour',
      missionId: 'mission-du-jour',
      classe: 'Al-Badr',
      enseignant: 'Sayyid Karim',
      debut: DateTime.now().subtract(const Duration(hours: 1)),
      dureeObservee: const Duration(minutes: 20),
      statut: StatutRapport.envoye,
      choix: ChoixCompteRendu.rienASignaler,
    ),
  ];

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async => ComplementRapport(date: DateTime.now(), texte: texte);
}

/// Un port temoin : il note ce qui part et confirme.
class _PortTemoin implements PortHistorique {
  final List<String> appels = <String>[];

  @override
  Future<List<RapportControle>> rapports() async => <RapportControle>[];

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async {
    appels.add('$rapportId|$texte|$motif');
    return ComplementRapport(date: DateTime(2026, 9, 25, 9), texte: texte);
  }
}

Future<void> _monterComplement(
  WidgetTester tester,
  PortHistorique port, {
  ValueChanged<RapportControle>? onTermine,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [portHistoriqueProvider.overrideWithValue(port)],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ComplementRapportPage(
            rapport: _parent,
            onRetour: () {},
            onTermine: onTermine ?? (RapportControle _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _versHistorique(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.railKey),
      matching: find.text(t.nav.controleur.historique),
    ),
  );
  await _attendre(tester);
}

void main() {
  testWidgets('Historique -> rapport -> detail -> fil de la mission', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.controle),
    );
    await _versHistorique(tester);
    expect(routeur.state.uri.queryParameters['ecran'], 'historique');
    expect(find.text('Cet écran est en préparation.'), findsNothing);

    // Trois rapports, statut ecrit, plus recent d'abord.
    expect(find.text(h.envoye), findsOneWidget);
    expect(find.text(h.complementAjoute), findsOneWidget);
    expect(find.text(h.aTerminer), findsOneWidget);
    final double yIkhlas = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0926')),
        )
        .dy;
    final double yBadr = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
        )
        .dy;
    final double yNour = tester
        .getTopLeft(
          find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
        )
        .dy;
    expect(yIkhlas < yBadr && yBadr < yNour, isTrue);

    // Detail en lecture : sections, observation, complement, presents.
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
    );
    await tester.pumpAndSettle();
    expect(find.text(h.sectionMission), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.faits), findsOneWidget);
    expect(find.text(h.sectionObservation), findsOneWidget);
    expect(find.text(h.sectionComplements), findsOneWidget);
    expect(find.text(h.sectionEchanges), findsOneWidget);
    expect(find.textContaining('huit minutes de retard'), findsOneWidget);
    expect(find.textContaining('coupure de connexion'), findsOneWidget);
    expect(find.textContaining('Bilal K.'), findsOneWidget);
    // Aucune edition : aucun champ de saisie.
    expect(find.byType(TextField), findsNothing);

    // « Ajouter un complement » ouvre le parcours (CT-8), plus de page
    // provisoire ; le retour de la premiere etape rend le detail.
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.complementKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.complementKey));
    await tester.pumpAndSettle();
    expect(find.text(h.provisoire), findsNothing);
    expect(find.byKey(ComplementRapportPage.bandeauKey), findsOneWidget);
    await tester.tap(find.byType(DisqueRetour).last);
    await tester.pumpAndSettle();
    expect(find.text(h.sectionMission), findsOneWidget);

    // Le lien vers le fil d'echanges de la mission.
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.ecrireAdminKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.ecrireAdminKey));
    await _attendre(tester);
    expect(routeur.state.uri.queryParameters['ecran'], 'echanges');
    expect(
      routeur.state.uri.queryParameters['fil'],
      'demo-mission-al-badr-0924',
    );
    expect(find.byType(EchangesControleurPage), findsOneWidget);
    expect(find.textContaining('huit minutes de retard'), findsOneWidget);
  });

  testWidgets('un rapport sans fil ouvre un fil neuf de sa mission', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.compteRendu.rienASignaler), findsOneWidget);
    expect(find.text(t.controleur.historique.sansComplement), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(HistoriqueControleurPage.ecrireAdminKey),
    );
    await tester.tap(find.byKey(HistoriqueControleurPage.ecrireAdminKey));
    await _attendre(tester);
    expect(
      routeur.state.uri.queryParameters['fil'],
      'demo-mission-an-nour-0921',
    );
    expect(find.text(t.controleur.echanges.contexte), findsOneWidget);
  });

  testWidgets('« A terminer » reprend le compte rendu', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
    );
    await _attendre(tester);
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0926')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CompteRenduControlePage), findsOneWidget);
    // La transmission de demonstration repond en 400 ms.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('le filtre Etat ne garde que les rapports choisis', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
    );
    await _attendre(tester);
    await tester.tap(find.text(h.filtreEtat));
    await tester.pumpAndSettle();
    await tester.tap(find.text(h.envoye).last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
      findsOneWidget,
    );
    expect(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
      findsNothing,
    );
    expect(find.text(h.resultats(n: 1)), findsOneWidget);
  });

  testWidgets('retour systeme : complement, puis detail, puis liste (m3)', (
    WidgetTester tester,
  ) async {
    final c = t.controleur.complement;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    final Finder ligne = find.byKey(
      HistoriqueControleurPage.ligneKey('demo-rapport-0921'),
    );
    await _toucher(tester, ligne);
    await _toucher(tester, find.byKey(HistoriqueControleurPage.complementKey));
    expect(find.text(c.bandeau), findsOneWidget);

    // Retour systeme : le complement se ferme, le detail revient.
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    expect(find.text(c.bandeau), findsNothing);
    expect(find.byKey(HistoriqueControleurPage.complementKey), findsOneWidget);

    // Deuxieme retour : le detail se ferme, la liste revient.
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    expect(find.byKey(HistoriqueControleurPage.complementKey), findsNothing);
    expect(ligne, findsOneWidget);
  });

  // CTRL-RETOUR-1 : aux etapes 2 et 3, le retour systeme recule d'une etape,
  // comme « Retour » a l'ecran, et le texte saisi reste.
  testWidgets('retour systeme aux etapes 2 et 3 : une etape, texte garde', (
    WidgetTester tester,
  ) async {
    final c = t.controleur.complement;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    await _toucher(
      tester,
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
    );
    await _toucher(tester, find.byKey(HistoriqueControleurPage.complementKey));
    await _toucher(
      tester,
      find.byKey(ComplementRapportPage.cleMotif(MotifComplement.precision)),
    );
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text(c.questionTexte), findsOneWidget);
    await tester.enterText(
      find.byKey(ComplementRapportPage.texteKey),
      'Texte à ne pas perdre.',
    );
    await tester.pump();
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text(c.questionRecap), findsOneWidget);

    // Etape 3 -> etape 2 : le texte est toujours dans le champ.
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    expect(find.text(c.bandeau), findsOneWidget);
    expect(find.text(c.questionTexte), findsOneWidget);
    expect(find.text('Texte à ne pas perdre.'), findsOneWidget);

    // Etape 2 -> etape 1 : le motif choisi reste, le complement aussi.
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    expect(find.text(c.questionMotif), findsOneWidget);
    expect(find.text(c.bandeau), findsOneWidget);

    // On revient en avant : la saisie n'a pas ete effacee.
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text('Texte à ne pas perdre.'), findsOneWidget);

    // Etape 2 -> 1, puis etape 1 -> detail : le complement se ferme.
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    await tester.binding.handlePopRoute();
    await _attendre(tester);
    expect(find.text(c.bandeau), findsNothing);
    expect(find.byKey(HistoriqueControleurPage.complementKey), findsOneWidget);
  });

  testWidgets('retour systeme apres l envoi : le detail a jour', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    final c = t.controleur.complement;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    await _toucher(
      tester,
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
    );
    await _toucher(tester, find.byKey(HistoriqueControleurPage.complementKey));
    await _toucher(tester, find.text(t.commun.continuer).last);
    await tester.enterText(
      find.byKey(ComplementRapportPage.texteKey),
      'Un ajout envoyé.',
    );
    await tester.pump();
    await _toucher(tester, find.text(t.commun.continuer).last);
    await _toucher(tester, find.text(c.envoyer).last);
    expect(find.text(c.envoyeTitre), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _attendre(tester);
    // Le detail (et non l'ecran de resultat), avec le complement et le
    // nouveau statut.
    expect(find.text(c.envoyePhrase), findsNothing);
    expect(find.text(h.sectionMission), findsOneWidget);
    expect(find.textContaining('Un ajout envoyé.'), findsOneWidget);
    expect(find.text(h.complementAjoute), findsOneWidget);
    expect(find.text(h.sansComplement), findsNothing);
  });

  testWidgets('CTR-03B : complement envoye, visible dans le detail', (
    WidgetTester tester,
  ) async {
    final h = t.controleur.historique;
    final c = t.controleur.complement;
    await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.historique),
      taille: const Size(390, 844),
    );
    await _attendre(tester);
    await tester.tap(
      find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0921')),
    );
    await tester.pumpAndSettle();
    expect(find.text(h.envoye), findsOneWidget);
    expect(find.text(h.sansComplement), findsOneWidget);

    await _toucher(tester, find.byKey(HistoriqueControleurPage.complementKey));
    // Bandeau permanent, a chaque etape.
    expect(find.text(c.bandeau), findsOneWidget);
    await _toucher(
      tester,
      find.byKey(ComplementRapportPage.cleMotif(MotifComplement.correction)),
    );
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text(c.bandeau), findsOneWidget);
    // Texte obligatoire : erreur a la validation, jamais envoye vide.
    await _toucher(tester, find.text(t.commun.continuer).last);
    expect(find.text(c.texteRequis), findsOneWidget);
    await tester.enterText(
      find.byKey(ComplementRapportPage.texteKey),
      'Une élève est arrivée avec dix minutes de retard.',
    );
    await tester.pump();
    await _toucher(tester, find.text(t.commun.continuer).last);
    // Recapitulatif : le parent est rappele, inchange ; le motif choisi.
    expect(find.text(c.bandeau), findsOneWidget);
    expect(find.textContaining('inchangé'), findsOneWidget);
    expect(find.text(c.correction), findsOneWidget);
    await _toucher(tester, find.text(c.envoyer).last);
    expect(find.text(c.envoyeTitre), findsOneWidget);
    await _toucher(tester, find.text(c.revenir).last);

    // Le detail : complement visible, statut « Complement ajoute ».
    expect(find.text(h.sectionComplements), findsOneWidget);
    expect(find.textContaining('dix minutes de retard'), findsOneWidget);
    expect(find.text(h.motif(motif: c.correction)), findsOneWidget);
    expect(find.text(h.complementAjoute), findsOneWidget);
    expect(find.text(h.sansComplement), findsNothing);
    // Revue CT-R m4 : l'auteur suit la date ; sans nom du serveur, « Vous ».
    expect(
      find.textContaining(' · ${t.controleur.echanges.auteurVous}'),
      findsOneWidget,
    );
    // La liste porte aussi le nouveau statut.
    await tester.tap(find.byType(DisqueRetour));
    await tester.pumpAndSettle();
    expect(find.text(h.complementAjoute), findsNWidgets(2));
  });

  testWidgets('CTR-03B : echec non confirme, la saisie reste', (
    WidgetTester tester,
  ) async {
    final c = t.controleur.complement;
    await _monterComplement(tester, const HistoriqueIndisponible());
    await _toucher(tester, find.text(t.commun.continuer).last);
    await tester.enterText(
      find.byKey(ComplementRapportPage.texteKey),
      'Texte à garder.',
    );
    await tester.pump();
    await _toucher(tester, find.text(t.commun.continuer).last);
    await _toucher(tester, find.text(c.envoyer).last);
    // D5 : « non confirme », jamais « n'a pas ete envoye » ; rien de simule.
    expect(find.text(c.echec), findsOneWidget);
    expect(find.textContaining("n'a pas été envoyé"), findsNothing);
    expect(find.text(c.envoyeTitre), findsNothing);
    expect(find.text('Texte à garder.'), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsOneWidget);
    // Retour au texte : la saisie est intacte.
    await tester.tap(find.byType(DisqueRetour).last);
    await tester.pumpAndSettle();
    expect(find.text('Texte à garder.'), findsOneWidget);
  });

  testWidgets('CTR-03B : le rapport parent reste intact', (
    WidgetTester tester,
  ) async {
    final _PortTemoin port = _PortTemoin();
    RapportControle? rendu;
    await _monterComplement(
      tester,
      port,
      onTermine: (RapportControle r) => rendu = r,
    );
    await _toucher(tester, find.text(t.commun.continuer).last);
    await tester.enterText(
      find.byKey(ComplementRapportPage.texteKey),
      'Un ajout.',
    );
    await tester.pump();
    await _toucher(tester, find.text(t.commun.continuer).last);
    await _toucher(tester, find.text(t.controleur.complement.envoyer).last);
    await _toucher(tester, find.text(t.controleur.complement.revenir).last);

    // Seuls l'identifiant, le texte et le motif partent.
    expect(port.appels, <String>['demo-rapport-parent|Un ajout.|null']);
    // Le parent n'a pas bouge.
    expect(_parent.statut, StatutRapport.envoye);
    expect(_parent.complements, hasLength(1));
    expect(_parent.observation!.texte, 'Texte d’origine.');
    // La nouvelle vue garde tout le parent et ajoute le complement a la fin.
    final RapportControle n = rendu!;
    expect(identical(n, _parent), isFalse);
    expect(n.statut, StatutRapport.complementAjoute);
    expect(n.observation, same(_parent.observation));
    expect(n.faits, same(_parent.faits));
    expect(n.complements.first, same(_parent.complements.first));
    expect(n.complements.last.texte, 'Un ajout.');
    expect(n.complements, hasLength(2));
  });

  testWidgets('le port par defaut n\'invente aucun rapport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const HistoriqueControleurPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.historique.vide), findsNothing);
    expect(find.text(t.controleur.historique.envoye), findsNothing);
  });

  // Revue CT-R M2 : par la VRAIE route (sans surcharge, comme
  // `app_router.dart`), « Ecrire a l'administration » ouvre le fil de la
  // mission (`?mission=`), jamais la liste seule.
  testWidgets('route reelle : Ecrire a l administration ouvre le fil', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GoRouter routeur = GoRouter(
      initialLocation: Routes.controleurHistorique,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.controleurHistorique,
          builder: (BuildContext _, GoRouterState _) =>
              const HistoriqueControleurPage(),
        ),
        GoRoute(
          path: Routes.controleurEchanges,
          builder: (BuildContext _, GoRouterState etat) =>
              Text('fil:${etat.uri.queryParameters['mission']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [portHistoriqueProvider.overrideWithValue(_PortDuJour())],
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
    final Finder ligne = find.byKey(
      HistoriqueControleurPage.ligneKey('rapport-du-jour'),
    );
    await tester.ensureVisible(ligne);
    await tester.pumpAndSettle();
    await tester.tap(ligne);
    await tester.pumpAndSettle();
    final Finder ecrire = find.byKey(HistoriqueControleurPage.ecrireAdminKey);
    await tester.ensureVisible(ecrire);
    await tester.pumpAndSettle();
    await tester.tap(ecrire);
    await tester.pumpAndSettle();
    expect(find.text('fil:mission-du-jour'), findsOneWidget);
  });
}
