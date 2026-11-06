// ENTREE-ORDRE (PLAN-LOTS rang 22 0, constat du directeur du 05/11/2026) :
// pour un nouveau profil, le questionnaire passe avant l'e-mail et la
// connexion ; quelqu'un qui revient garde la connexion. Sur le vrai routeur.

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/ordre_entree.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart'
    show clefQuestionnaire;
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';

import 'support_routeur.dart';

Future<GoRouter> _visiteur(
  WidgetTester tester,
  String depart, {
  List<Override> surcharges = const <Override>[],
}) async {
  final SourcePilotee source = SourcePilotee(const SessionState.deconnecte());
  addTearDown(source.fermer);
  return monterRouteur(tester, depart, source: source, surcharges: surcharges);
}

void main() {
  setUp(() {
    effacerMemoireAppareil(clefCompteConnu);
    effacerMemoireAppareil(clefQuestionnaire);
  });

  group('Un appareil qui ne connait aucun compte : le questionnaire', () {
    testWidgets('la racine mene au questionnaire', (WidgetTester tester) async {
      final GoRouter routeur = await _visiteur(tester, Routes.racine);
      expect(Uri.parse(lieu(routeur)).path, Routes.commencer);
      expect(find.byType(QuestionnairePage), findsOneWidget);
      expect(find.byType(ConnexionPage), findsNothing);
    });

    testWidgets('/connexion nue (boutons du site) mene au questionnaire', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _visiteur(tester, Routes.connexion);
      expect(Uri.parse(lieu(routeur)).path, Routes.commencer);
      expect(find.byType(QuestionnairePage), findsOneWidget);
    });

    testWidgets('« J ai deja un compte » garde la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _visiteur(
        tester,
        adresseConnexionDemandee,
      );
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });

    testWidgets('un lien de connexion recu garde la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _visiteur(
        tester,
        Routes.connexion,
        surcharges: <Override>[lienRecuProvider.overrideWithValue(true)],
      );
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });

    testWidgets('un lien profond sans session garde la connexion et sa '
        'destination', (WidgetTester tester) async {
      final GoRouter routeur = await _visiteur(tester, Routes.tuteurAccueil);
      final Uri adresse = Uri.parse(lieu(routeur));
      expect(adresse.path, Routes.connexion);
      expect(adresse.queryParameters['retour'], Routes.tuteurAccueil);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });

    testWidgets('le lien d invitation d un enseignant garde la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _visiteur(
        tester,
        '${Routes.connexion}?mode=creer&invitation=1',
      );
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });
  });

  group('Quelqu un qui revient : la connexion', () {
    testWidgets('/connexion tapee sur un appareil qui a connu un compte', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(clefCompteConnu, '1');
      final GoRouter routeur = await _visiteur(tester, Routes.connexion);
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });

    testWidgets('la racine aussi', (WidgetTester tester) async {
      ecrireMemoireAppareil(clefCompteConnu, '1');
      final GoRouter routeur = await _visiteur(tester, Routes.racine);
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
    });

    testWidgets('une session ouverte pose le repere : apres la sortie, la '
        'connexion', (WidgetTester tester) async {
      final SourcePilotee source = SourcePilotee(
        const SessionState.chargement(),
      );
      addTearDown(source.fermer);
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: source,
      );
      source.emettre(sessionActive(AppRole.guardian));
      await stabiliser(tester);
      expect(lireMemoireAppareil(clefCompteConnu), isNotNull);
      source.emettre(const SessionState.deconnecte());
      await stabiliser(tester);
      routeur.go(Routes.connexion);
      await stabiliser(tester);
      expect(Uri.parse(lieu(routeur)).path, Routes.connexion);
      expect(find.byType(ConnexionPage), findsOneWidget);
    });
  });

  group('Regles pures', () {
    test('un lien recu se lit dans la requete ou le fragment', () {
      expect(
        lienDeConnexionDansAdresse(Uri.parse('https://app.test/?code=abc')),
        isTrue,
      );
      expect(
        lienDeConnexionDansAdresse(
          Uri.parse('https://app.test/#access_token=x&type=magiclink'),
        ),
        isTrue,
      );
      expect(
        lienDeConnexionDansAdresse(
          Uri.parse('https://app.test/?error=access_denied'),
        ),
        isTrue,
      );
      expect(
        lienDeConnexionDansAdresse(Uri.parse('https://app.test/#/connexion')),
        isFalse,
      );
      expect(
        lienDeConnexionDansAdresse(Uri.parse('https://app.test/#/commencer')),
        isFalse,
      );
    });

    test('seule une /connexion nue, sans compte ni lien, part au '
        'questionnaire', () {
      final Uri nue = Uri.parse(Routes.connexion);
      expect(
        redirectionVisiteurNouveau(nue, compteConnu: false, lienRecu: false),
        Routes.commencer,
      );
      expect(
        redirectionVisiteurNouveau(nue, compteConnu: true, lienRecu: false),
        isNull,
      );
      expect(
        redirectionVisiteurNouveau(nue, compteConnu: false, lienRecu: true),
        isNull,
      );
      expect(
        redirectionVisiteurNouveau(
          Uri.parse(adresseConnexionDemandee),
          compteConnu: false,
          lienRecu: false,
        ),
        isNull,
      );
      expect(
        redirectionVisiteurNouveau(
          Uri.parse('${Routes.connexion}?retour=%2Ftuteur'),
          compteConnu: false,
          lienRecu: false,
        ),
        isNull,
      );
    });
  });
}
