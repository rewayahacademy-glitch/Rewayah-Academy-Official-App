// CT-6 : CTR-04 Echanges, depuis la VRAIE route de demonstration.
// Destination Echanges -> un fil -> ecrire -> envoyer -> message affiche,
// en cours puis envoye sur reponse seulement ; echec honnete avec
// « Reessayer » ; depuis le resultat du compte rendu, « Ecrire a
// l'administration » ouvre le fil de la mission.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(1280, 900),
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

/// Laisse repondre le port de demonstration (400 ms), puis stabilise.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _ecrireEtEnvoyer(WidgetTester tester, String texte) async {
  final e = t.controleur.echanges;
  // Champ vide : le bouton est inactif, la raison est ecrite.
  expect(find.text(e.champVide), findsOneWidget);
  final IconButton inactif = tester.widget<IconButton>(
    find.byKey(FilDiscussion.envoyerKey),
  );
  expect(inactif.onPressed, isNull);

  await tester.enterText(find.byKey(FilDiscussion.champKey), texte);
  await tester.pump();
  expect(find.text(e.champVide), findsNothing);
  await tester.tap(find.byKey(FilDiscussion.envoyerKey));
  await tester.pump();
  // Le message est affiche, en cours : jamais de succes avant la reponse.
  expect(find.text(texte), findsOneWidget);
  expect(find.text(e.enCours), findsOneWidget);
  expect(find.text(e.envoye), findsNothing);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  expect(find.text(texte), findsOneWidget);
  expect(find.text(e.envoye), findsOneWidget);
  expect(find.text(e.enCours), findsNothing);
}

/// Un port qui echoue au premier envoi, puis reussit.
class _EchecPuisSucces implements PortEchanges {
  int essais = 0;

  static final FilEchange _fil = FilEchange(
    id: 'fil-test',
    missionId: 'mission-test',
    classe: 'Classe Test',
    debutMission: DateTime(2026, 9, 24, 17),
    etat: EtatFilEchange.enAttente,
    messages: const <MessageEchange>[],
  );

  @override
  Future<List<FilEchange>> fils() async => <FilEchange>[_fil];

  @override
  Future<FilEchange> filDeMission(String missionId) async => _fil;

  @override
  Future<void> envoyer(String filId, String texte) async {
    essais++;
    if (essais == 1) throw StateError('pas de reponse');
  }
}

void main() {
  testWidgets('Echanges -> un fil -> ecrire -> envoyer -> message affiche', (
    WidgetTester tester,
  ) async {
    final e = t.controleur.echanges;
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.controle),
      taille: const Size(1000, 1000),
    );
    // Depuis la VRAIE coquille : la destination Echanges.
    await tester.tap(
      find.descendant(
        of: find.byKey(NavShell.railKey),
        matching: find.text(t.nav.controleur.echanges),
      ),
    );
    await _attendre(tester);
    expect(routeur.state.uri.queryParameters['ecran'], 'echanges');
    expect(find.text('Cet écran est en préparation.'), findsNothing);

    // Deux fils, titres « Classe · date », etat ecrit en mots.
    expect(find.text('Classe Al-Ikhlas · Samedi 26 septembre'), findsOneWidget);
    expect(find.text('Classe Al-Badr · Jeudi 24 septembre'), findsOneWidget);
    expect(find.text(e.reponseRecue), findsOneWidget);
    expect(find.text(e.enAttente), findsOneWidget);
    // Aucun nom d'enseignant dans les titres (question 7).
    expect(find.textContaining('Ibrahim'), findsNothing);

    await tester.tap(find.text('Classe Al-Badr · Jeudi 24 septembre'));
    await _attendre(tester);
    // Contexte epingle, messages connus.
    expect(find.text(e.contexte), findsOneWidget);
    expect(find.text('Classe Al-Badr'), findsOneWidget);
    expect(find.text('17:00'), findsOneWidget);
    expect(find.textContaining('huit minutes de retard'), findsOneWidget);
    expect(find.text(e.auteurAdmin), findsOneWidget);

    await _ecrireEtEnvoyer(tester, 'Merci pour votre retour.');

    // Retour a la liste : le fil repasse « En attente ».
    await tester.tap(find.byType(DisqueRetour));
    await _attendre(tester);
    expect(find.text(e.enAttente), findsNWidgets(2));
  });

  testWidgets('resultat du compte rendu : Ecrire a l\'administration ouvre '
      'le fil de la mission', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      adresseDemoControleur(EcranDemoControleur.controle),
    );
    await tester.tap(find.byKey(ControleControleurPage.commencerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.salle.quitter));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.controleur.compteRendu.ecrireAdmin));
    await _attendre(tester);
    final String mission = DonneesControleurDemo.mission(
      EtatDemoControleur.enDirect,
    )!.id;
    expect(routeur.state.uri.queryParameters['ecran'], 'echanges');
    expect(routeur.state.uri.queryParameters['fil'], mission);
    expect(find.byType(EchangesControleurPage), findsOneWidget);
    // Le fil de la mission An-Nour, contexte joint, sans recopie.
    expect(find.text('Classe An-Nour · Lundi 28 septembre'), findsOneWidget);
    expect(find.text(t.controleur.echanges.contexte), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);

    await _ecrireEtEnvoyer(tester, 'Une question sur cette visite.');
  });

  testWidgets('sans serveur, l\'envoi echoue honnetement et se reessaie', (
    WidgetTester tester,
  ) async {
    final e = t.controleur.echanges;
    final _EchecPuisSucces port = _EchecPuisSucces();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [portEchangesProvider.overrideWithValue(port)],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const EchangesControleurPage(missionOuverte: 'mission-test'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FilDiscussion.champKey), 'Bonjour.');
    await tester.pump();
    await tester.tap(find.byKey(FilDiscussion.envoyerKey));
    await tester.pumpAndSettle();
    expect(find.text(e.echec), findsOneWidget);
    expect(find.text(e.envoye), findsNothing);
    // La saisie est gardee dans le message.
    expect(find.text('Bonjour.'), findsOneWidget);
    await tester.tap(find.text(e.reessayer));
    await tester.pumpAndSettle();
    expect(find.text(e.envoye), findsOneWidget);
    expect(find.text(e.echec), findsNothing);
    expect(port.essais, 2);
  });

  testWidgets('le port par defaut n\'invente aucun fil', (
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
            home: const EchangesControleurPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.echanges.vide), findsNothing);
    expect(find.text(t.controleur.echanges.reponseRecue), findsNothing);
  });
}
