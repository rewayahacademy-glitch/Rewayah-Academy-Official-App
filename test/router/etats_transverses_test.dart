import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/marque_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';

import '../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';
import 'support_routeur.dart';

/// Les etats transverses du routeur, sur le **vrai** routeur (mandat Tuteur
/// V1 section 8 ; mapping des routes, ligne 42) : page introuvable, lien
/// profond inconnu, identifiant inconnu, acces refuse, session expiree et
/// retour, hors ligne au demarrage, ecran de demarrage.
void main() {
  Finder etat(NatureEtat nature) => find.byWidgetPredicate(
    (Widget w) => w is EtatSysteme && w.nature == nature,
  );

  group('Page introuvable (errorBuilder)', () {
    testWidgets('un chemin inconnu du tuteur : page d etat, retour accueil', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(tester, '/tuteur/inconnue');
      expect(find.byType(PageIntrouvable), findsOneWidget);
      expect(etat(NatureEtat.introuvable), findsOneWidget);
      expect(find.text(t.commun.etats.introuvable.titre), findsOneWidget);
      // Jamais l'ecran anglais de go_router, ni l'exception brute.
      expect(find.textContaining('Page Not Found'), findsNothing);
      expect(find.textContaining('GoException'), findsNothing);

      await tester.tap(find.text(t.commun.etats.actions.retourAccueil));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un lien profond inconnu ne fait pas planter', (
      WidgetTester tester,
    ) async {
      for (final String chemin in <String>[
        '/tuteur/foyer/e1/inconnue/encore',
        '/tuteur/classes',
        '/tuteur/seances',
        '/nimporte/quoi?x=1',
        '/compte/inconnue',
      ]) {
        await monterRouteur(tester, chemin);
        expect(find.byType(PageIntrouvable), findsOneWidget, reason: chemin);
        expect(tester.takeException(), isNull, reason: chemin);
      }
    });

    testWidgets('sans session : page introuvable, action se connecter', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        '/nimporte/quoi',
        source: FausseSourceSession(),
      );
      expect(find.byType(PageIntrouvable), findsOneWidget);
      await tester.tap(find.text(t.commun.etats.actions.seConnecter));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.connexion);
    });
  });

  group('Identifiant inconnu : l ecran le dit, sans planter', () {
    testWidgets('une classe inconnue du foyer', (WidgetTester tester) async {
      await monterRouteur(tester, Routes.classePour('inconnue'));
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      // Introuvable ou pas encore relie selon le foyer : l'ecran le dit par un\n      // etat systeme, jamais par un plantage (demande C-9).\n      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un eleve inconnu du foyer', (WidgetTester tester) async {
      await monterRouteur(tester, Routes.ficheElevePour('inconnu'));
      expect(find.byType(FicheElevePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Acces refuse : une page, et le retour a la racine du role', () {
    testWidgets('un tuteur sur une page d administration', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.adminSecuriteAuditObservations,
      );
      expect(lieu(routeur), Routes.accesRefuse);
      expect(find.byType(PageAccesRefuse), findsOneWidget);
      expect(etat(NatureEtat.accesRefuse), findsOneWidget);

      await tester.tap(find.text(t.commun.etats.actions.retourAccueil));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('un enseignant sur le foyer d un tuteur repart chez lui', (
      WidgetTester tester,
    ) async {
      // Les autres roles gardent le renvoi d'avant le chantier Tuteur V1,
      // sans page intermediaire (revue phase 0, routes D3).
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurFoyer,
        source: FausseSourceSession(sessionActive(AppRole.teacher)),
      );
      expect(lieu(routeur), Routes.enseignantJournee);
      expect(find.byType(PageAccesRefuse), findsNothing);
    });
  });

  group('Session expiree : la connexion garde la destination validee', () {
    testWidgets('sans session, puis connecte : retour a la destination', (
      WidgetTester tester,
    ) async {
      final SourcePilotee source = SourcePilotee(
        const SessionState.deconnecte(),
      );
      addTearDown(source.fermer);
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.ficheEleveSousPage('e1', 'camera'),
        source: source,
      );
      final Uri adresse = Uri.parse(lieu(routeur));
      expect(adresse.path, Routes.connexion);
      expect(
        adresse.queryParameters['retour'],
        Routes.ficheEleveSousPage('e1', 'camera'),
      );

      source.emettre(sessionActive(AppRole.guardian));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.ficheEleveSousPage('e1', 'camera'));
    });

    testWidgets('un retour vers un autre espace ramene a la racine du role', (
      WidgetTester tester,
    ) async {
      final SourcePilotee source = SourcePilotee(
        const SessionState.deconnecte(),
      );
      addTearDown(source.fermer);
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.enseignantJournee,
        source: source,
      );
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      source.emettre(sessionActive(AppRole.guardian));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('un retour externe dans l URL est ignore', (
      WidgetTester tester,
    ) async {
      final SourcePilotee source = SourcePilotee(
        const SessionState.deconnecte(),
      );
      addTearDown(source.fermer);
      final GoRouter routeur = await monterRouteur(
        tester,
        '${Routes.connexion}?retour=https%3A%2F%2Fexemple.test',
        source: source,
      );
      source.emettre(sessionActive(AppRole.guardian));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
    });
  });

  group('Hors ligne au demarrage : un etat, jamais un acces', () {
    const SessionState injoignable = SessionState(
      resolue: true,
      profileId: 'p1',
      role: AppRole.guardian,
      householdId: 'h1',
      lectureProfil: LectureProfil.injoignable,
    );

    testWidgets('toute adresse mene a la page hors ligne', (
      WidgetTester tester,
    ) async {
      final SourcePilotee source = SourcePilotee(injoignable);
      addTearDown(source.fermer);
      for (final String chemin in <String>[
        Routes.tuteurAccueil,
        Routes.attente,
        Routes.ficheElevePour('e1'),
      ]) {
        final GoRouter routeur = await monterRouteur(
          tester,
          chemin,
          source: source,
        );
        expect(lieu(routeur), Routes.horsLigne, reason: chemin);
        expect(find.byType(PageHorsLigne), findsOneWidget);
        // Ni le portail d'un dossier, ni une page du tuteur.
        expect(find.text(t.commun.etats.horsLigneDemarrage), findsOneWidget);
        // EA-HL-DOUBLE-1 : le titre dit ce qui manque ; seul le bandeau, quand
        // il est la, dit « hors ligne ».
        expect(
          find.text(t.commun.etats.horsLigneDemarrageTitre),
          findsOneWidget,
        );
        expect(signauxHorsLigne().evaluate().length, lessThanOrEqualTo(1));
        // Reprise : le « wifi barre » n'est pas repose par la page.
        expect(
          iconesHorsLigne().evaluate().length,
          signauxHorsLigne().evaluate().length,
        );
      }
    });

    testWidgets('appareil hors ligne : le bandeau seul dit « hors ligne », '
        'en mots et en icone (EA-HL-DOUBLE-1)', (WidgetTester tester) async {
      final SourcePilotee source = SourcePilotee(injoignable);
      addTearDown(source.fermer);
      await monterRouteur(
        tester,
        Routes.tuteurAccueil,
        source: source,
        surcharges: <Override>[
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ],
      );
      expect(find.byType(PageHorsLigne), findsOneWidget);
      expectHorsLigneUneFois();
    });

    group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);
      for (final (String, Size) cas in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('320', const Size(320, 900)),
        ('1440', const Size(1440, 900)),
      ]) {
        testWidgets(cas.$1, (WidgetTester tester) async {
          final SourcePilotee source = SourcePilotee(injoignable);
          addTearDown(source.fermer);
          await monterRouteur(
            tester,
            Routes.tuteurAccueil,
            source: source,
            taille: cas.$2,
            surcharges: <Override>[
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(true),
              ),
            ],
          );
          expect(tester.takeException(), isNull);
          expectHorsLigneUneFois();
          debugPrint(
            'PNG ${await capturerVue(tester, 'ea_hl_double1_demarrage_${cas.$1}_clair')}',
          );
        });
      }
    });

    // EA-HL-DOUBLE-1d : sombre, Interface guidee et 320 texte x2 en LTR et
    // RTL du demarrage hors ligne (revue EA-HL-DOUBLE-1c-R, mineur 2).
    // Sautees sans CAPTURE_DIR.
    group('Capture EA-HL-DOUBLE-1d', skip: sautSansCapture, () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);
      for (final (String, Size, ThemeMode, InterfaceMode, TextDirection, double)
          cas
          in <(String, Size, ThemeMode, InterfaceMode, TextDirection, double)>[
            (
              '390_sombre',
              const Size(390, 844),
              ThemeMode.dark,
              InterfaceMode.standard,
              TextDirection.ltr,
              1,
            ),
            (
              '390_guidee',
              const Size(390, 844),
              ThemeMode.light,
              InterfaceMode.enfant,
              TextDirection.ltr,
              1,
            ),
            (
              '320x2_clair',
              const Size(320, 1800),
              ThemeMode.light,
              InterfaceMode.standard,
              TextDirection.ltr,
              2,
            ),
            (
              '320x2_rtl_clair',
              const Size(320, 1800),
              ThemeMode.light,
              InterfaceMode.standard,
              TextDirection.rtl,
              2,
            ),
          ]) {
        testWidgets(cas.$1, (WidgetTester tester) async {
          final SourcePilotee source = SourcePilotee(injoignable);
          addTearDown(source.fermer);
          await monterRouteur(
            tester,
            Routes.tuteurAccueil,
            source: source,
            taille: cas.$2,
            themeMode: cas.$3,
            interface: cas.$4,
            direction: cas.$5,
            echelle: cas.$6,
            surcharges: <Override>[
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(true),
              ),
            ],
          );
          expect(tester.takeException(), isNull);
          expect(
            find.text(t.commun.etats.horsLigneDemarrageTitre),
            findsOneWidget,
          );
          expectHorsLigneUneFois();
          verifierAucunMotCoupe(tester, find.byType(MaterialApp));
          debugPrint(
            'PNG ${await capturerVue(tester, 'ea_hl_double1d_demarrage_${cas.$1}')}',
          );
        });
      }
    });

    testWidgets('reessayer relance la lecture ; le retour du reseau ouvre', (
      WidgetTester tester,
    ) async {
      final SourcePilotee source = SourcePilotee(injoignable);
      addTearDown(source.fermer);
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurAccueil,
        source: source,
      );
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(source.rafraichissements, 1);

      // La lecture aboutit : la session devient active, la page s'efface.
      source.emettre(sessionActive(AppRole.guardian));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurAccueil);
    });
  });

  group('Ecran de demarrage', () {
    testWidgets('neutre, puis chargement prolonge ; plus de chantier', (
      WidgetTester tester,
    ) async {
      // Une session qui ne se resout jamais : l'ecran de `/` reste.
      final SourcePilotee source = SourcePilotee();
      addTearDown(source.fermer);
      await monterRouteur(tester, null, source: source);

      expect(find.byType(EcranDemarrage), findsOneWidget);
      expect(find.byType(MarquePage), findsOneWidget);
      expect(
        find.bySemanticsLabel(t.commun.demarrage.ouverture),
        findsOneWidget,
      );
      expect(find.text(t.aConstruire.titre), findsNothing);
      expect(etat(NatureEtat.chargementProlonge), findsNothing);

      await tester.pump(AppDelais.chargementProlonge);
      await tester.pump();
      expect(etat(NatureEtat.chargementProlonge), findsOneWidget);
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pump();
      expect(source.rafraichissements, 1);
    });
  });
}
