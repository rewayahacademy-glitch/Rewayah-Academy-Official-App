// CT-5 : CTR-03A Observation structuree, depuis la VRAIE route de
// demonstration. « Commencer le controle » -> « Quitter » -> « Ajouter une
// observation » -> nature, domaine, personne (roster), texte, recapitulatif
// -> « Envoyer le compte rendu » -> resultat. « Intervention Admin
// souhaitee » sans texte ne part pas ; le retour garde les reponses ; sans
// serveur, l'envoi echoue et la saisie reste.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<void> _monter(
  WidgetTester tester,
  GoRouter routeur, {
  Size taille = const Size(1280, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Finder _bouton(String libelle) => find.text(libelle).last;

/// De la carte de mission jusqu'a la premiere etape de CTR-03A.
Future<void> _jusquALObservation(
  WidgetTester tester,
  ChoixCompteRendu choix,
) async {
  await _monter(
    tester,
    GoRouter(
      initialLocation: adresseDemoControleur(EcranDemoControleur.controle),
      routes: routesDemoControleur('dev'),
    ),
  );
  await tester.tap(find.byKey(ControleControleurPage.commencerKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.salle.quitter));
  await tester.pumpAndSettle();
  await _toucher(tester, find.byKey(CompteRenduControlePage.cleChoix(choix)));
  await _toucher(tester, find.byKey(CompteRenduControlePage.actionKey));
  expect(find.byType(ObservationControlePage), findsOneWidget);
}

void main() {
  final o = t.controleur.observation;

  testWidgets('Parcours complet : cinq etapes, envoi, resultat', (
    WidgetTester tester,
  ) async {
    await _jusquALObservation(tester, ChoixCompteRendu.ajouterObservation);
    expect(find.text(t.inscription.etapeSur(n: 1, total: 5)), findsOneWidget);
    expect(find.text(o.questionNature), findsOneWidget);
    // Aucune preselection, aucune liste deroulante, aucun interrupteur.
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await _toucher(
      tester,
      find.byKey(ObservationControlePage.cleNature(NatureObservation.aSuivre)),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.questionDomaine), findsOneWidget);
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));

    // Personne : « Eleve precis » ouvre le roster, prenoms seuls, sans
    // champ de recherche.
    expect(find.text(o.questionPersonne), findsOneWidget);
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
      ),
    );
    expect(find.text(o.questionEleve), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final String prenom = DonneesControleurDemo.roster.first;
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.cleEleve('demo-eleve-0')),
    );
    await _toucher(tester, _bouton(t.commun.continuer));

    // Texte facultatif pour « A suivre » : on passe sans rien ecrire.
    expect(find.text(o.texteFacultatif), findsOneWidget);
    await _toucher(tester, _bouton(t.commun.continuer));

    // Recapitulatif, notice au-dessus du bouton.
    expect(find.text(o.questionRecap), findsOneWidget);
    expect(find.text(o.aSuivre), findsOneWidget);
    expect(find.text(o.pedagogie), findsOneWidget);
    expect(find.textContaining(prenom), findsOneWidget);
    expect(find.text(o.sansTexte), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.notice), findsOneWidget);

    // Le retour garde les reponses.
    await _toucher(tester, find.text(t.commun.retour));
    await _toucher(tester, find.text(t.commun.retour));
    expect(find.text(o.questionPersonne), findsOneWidget);
    expect(find.text(o.questionEleve), findsOneWidget);
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(tester, _bouton(t.commun.continuer));

    final Finder envoyer = _bouton(t.controleur.compteRendu.envoyer);
    await tester.ensureVisible(envoyer);
    await tester.pumpAndSettle();
    await tester.tap(envoyer);
    await tester.pump();
    // Aucun succes avant la reponse.
    expect(find.text(t.controleur.compteRendu.envoyeTitre), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.compteRendu.envoyeTitre), findsOneWidget);

    // Plus rien a terminer sur le Controle.
    await _toucher(tester, find.text(t.controleur.compteRendu.revenir));
    expect(find.byType(ControleControleurPage), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.aTerminer), findsNothing);
  });

  testWidgets('Intervention Admin souhaitee sans texte ne part pas', (
    WidgetTester tester,
  ) async {
    await _jusquALObservation(tester, ChoixCompteRendu.ajouterObservation);
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.interventionAdmin),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.cleDomaine(DomaineObservation.climat)),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.clePersonne(PersonneConcernee.aucun)),
    );
    await _toucher(tester, _bouton(t.commun.continuer));

    expect(find.text(o.texteObligatoire), findsOneWidget);
    // Pas d'erreur avant la validation de l'etape.
    expect(find.text(o.texteRequis), findsNothing);
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.texteRequis), findsOneWidget);
    expect(find.text(o.questionRecap), findsNothing);
    expect(find.text(t.controleur.compteRendu.envoyer), findsNothing);

    // L'erreur disparait des la saisie ; on peut alors avancer.
    await tester.enterText(
      find.byKey(ObservationControlePage.texteKey),
      'Deux eleves ont ete deconnectes sans reponse.',
    );
    await tester.pumpAndSettle();
    expect(find.text(o.texteRequis), findsNothing);
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.questionRecap), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('Point important : texte obligatoire, sans nature choisie', (
    WidgetTester tester,
  ) async {
    await _jusquALObservation(tester, ChoixCompteRendu.pointImportant);
    expect(find.text(o.important), findsOneWidget);
    // Aucune nature preselectionnee.
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.cleNature(NatureObservation.aSuivre)),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.cleDomaine(DomaineObservation.autre)),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.enseignant),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.texteObligatoire), findsOneWidget);
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.texteRequis), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('Liste des eleves non recue : le dire, puis Reessayer', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
      seanceId: 'seance-A',
      classe: 'Classe Al-Fajr',
      debut: DateTime(2026, 9, 28, 16),
    );
    int appels = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          visitesObserveesProvider.overrideWith(
            () => VisitesObservees(<String, CompteRenduEnSuspens>{
              visite.seanceId: visite,
            }),
          ),
          rosterControleProvider.overrideWith((Ref _) async {
            appels++;
            if (appels == 1) throw StateError('connexion coupee');
            return const <EleveRoster>[EleveRoster(id: 'e1', prenom: 'Amina')];
          }),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ObservationControlePage(seanceId: visite.seanceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.pointPositif),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleDomaine(DomaineObservation.interaction),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
      ),
    );
    expect(find.text(o.rosterIndisponible), findsOneWidget);
    expect(find.text(o.rosterVide), findsNothing);
    await _toucher(
      tester,
      find.byKey(ObservationControlePage.reessayerRosterKey),
    );
    expect(appels, 2);
    expect(find.text(o.rosterIndisponible), findsNothing);
    expect(find.text(o.questionEleve), findsOneWidget);
    expect(find.byKey(ObservationControlePage.cleEleve('e1')), findsOneWidget);
  });

  testWidgets('Sans serveur, l envoi echoue et la saisie reste', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
      seanceId: 'seance-A',
      classe: 'Classe Al-Fajr',
      debut: DateTime(2026, 9, 28, 16),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          visitesObserveesProvider.overrideWith(
            () => VisitesObservees(<String, CompteRenduEnSuspens>{
              visite.seanceId: visite,
            }),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ObservationControlePage(seanceId: visite.seanceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.pointPositif),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleDomaine(DomaineObservation.interaction),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    // Sans roster, « Eleve precis » le dit et ne laisse pas avancer.
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
      ),
    );
    // Liste recue mais vide : un etat distinct de l'erreur (revue CT-R m2).
    expect(find.text(o.rosterVide), findsOneWidget);
    expect(find.text(o.rosterIndisponible), findsNothing);
    expect(
      find.byKey(ObservationControlePage.reessayerRosterKey),
      findsNothing,
    );
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.classeEntiere),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await tester.enterText(
      find.byKey(ObservationControlePage.texteKey),
      'Accueil chaleureux des eleves.',
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(tester, _bouton(t.controleur.compteRendu.envoyer));
    expect(find.text(t.controleur.compteRendu.envoyeTitre), findsNothing);
    expect(find.text(o.echec), findsOneWidget);
    expect(find.text('Accueil chaleureux des eleves.'), findsOneWidget);
    expect(find.text(t.controleur.compteRendu.envoyer), findsOneWidget);
  });

  // CTRL-MSG-1 : un texte facultatif laisse vide n'est pas « garde ».
  testWidgets('Sans serveur ni texte : l echec ne parle pas d un texte garde', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
      seanceId: 'seance-A',
      classe: 'Classe Al-Fajr',
      debut: DateTime(2026, 9, 28, 16),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          visitesObserveesProvider.overrideWith(
            () => VisitesObservees(<String, CompteRenduEnSuspens>{
              visite.seanceId: visite,
            }),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ObservationControlePage(seanceId: visite.seanceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.pointPositif),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleDomaine(DomaineObservation.interaction),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.classeEntiere),
      ),
    );
    await _toucher(tester, _bouton(t.commun.continuer));
    // Texte facultatif : on passe sans rien ecrire.
    expect(find.text(o.texteFacultatif), findsOneWidget);
    await _toucher(tester, _bouton(t.commun.continuer));
    expect(find.text(o.sansTexte), findsOneWidget);
    await _toucher(tester, _bouton(t.controleur.compteRendu.envoyer));
    expect(find.text(t.controleur.compteRendu.envoyeTitre), findsNothing);
    expect(find.text(o.echecSansTexte), findsOneWidget);
    expect(find.text(o.echec), findsNothing);
    expect(find.textContaining('texte est gardé'), findsNothing);
    expect(o.echecSansTexte, contains("n'est pas confirmé"));
    expect(find.text(t.controleur.compteRendu.envoyer), findsOneWidget);
  });

  // CTRL-MSG-1 : seance inconnue (rechargement de la PWA) par la route reelle.
  testWidgets('Seance inconnue : visite plus en memoire, cause vraie', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GoRouter routeur = GoRouter(
      initialLocation: adresseObservation(
        Routes.controleurObservation,
        ChoixCompteRendu.pointImportant,
        seanceId: 'seance-inconnue',
      ),
      routes: <RouteBase>[
        // Le meme constructeur que `app_router.dart`.
        GoRoute(
          path: Routes.controleurObservation,
          builder: (BuildContext _, GoRouterState etat) =>
              ObservationControlePage(
                seanceId: etat.uri.queryParameters['seance'],
                choix: choixObservationDepuis(
                  etat.uri.queryParameters,
                  etat.extra,
                ),
              ),
        ),
      ],
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
    expect(find.text(t.controleur.compteRendu.visiteInconnue), findsOneWidget);
    expect(
      find.text(t.controleur.compteRendu.visiteInconnueAide),
      findsOneWidget,
    );
    expect(find.text(t.controleur.controle.indisponible), findsNothing);
    expect(find.textContaining('autre contrôleur'), findsNothing);
  });
  // Revue CT-5 : le choix est porte par l'adresse, un rechargement de la PWA
  // ou un lien direct (sans `extra`) garde le « point important ».
  test('le choix se lit dans l adresse, puis dans extra', () {
    for (final ChoixCompteRendu c in ChoixCompteRendu.values) {
      final Uri u = Uri.parse(adresseObservation('/x', c));
      expect(choixObservationDepuis(u.queryParameters, null), c);
    }
    expect(
      choixObservationDepuis(const <String, String>{}, null),
      ChoixCompteRendu.ajouterObservation,
    );
    expect(
      choixObservationDepuis(
        const <String, String>{},
        ChoixCompteRendu.pointImportant,
      ),
      ChoixCompteRendu.pointImportant,
    );
    expect(
      choixObservationDepuis(const <String, String>{'choix': 'inconnu'}, null),
      ChoixCompteRendu.ajouterObservation,
    );
  });

  testWidgets('Point important par un lien direct, sans extra', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      GoRouter(
        initialLocation: adresseObservation(
          cheminDemoObservationControleur,
          ChoixCompteRendu.pointImportant,
        ),
        routes: routesDemoControleur('dev'),
      ),
    );
    final ObservationControlePage page = tester.widget(
      find.byType(ObservationControlePage),
    );
    expect(page.choix, ChoixCompteRendu.pointImportant);
    expect(find.text(o.important), findsOneWidget);
  });

  testWidgets('depuis le compte rendu, l adresse porte le choix', (
    WidgetTester tester,
  ) async {
    await _jusquALObservation(tester, ChoixCompteRendu.pointImportant);
    final GoRouter routeur = GoRouter.of(
      tester.element(find.byType(ObservationControlePage)),
    );
    expect(
      routeur.state.uri.queryParameters['choix'],
      ChoixCompteRendu.pointImportant.name,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}
