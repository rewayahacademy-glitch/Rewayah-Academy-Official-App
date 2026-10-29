import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/marque/logo_google.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart'
    show UsageInscription;
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart'
    show MomentJournee;

import '../support/harnais.dart';

Future<FauxServiceAuth> _monter(
  WidgetTester tester, {
  ModeConnexion mode = ModeConnexion.connexion,
}) async {
  final FauxServiceAuth auth = FauxServiceAuth();
  await tester.pumpWidget(
    hote(
      ConnexionPage(mode: mode),
      surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
    ),
  );
  return auth;
}

void main() {
  group('acces demo fictif', () {
    test('chaque adresse de role produit l interface attendue', () {
      final Map<String, ({AppRole role, InterfaceMode mode})> attendus = {
        'admin@demo.test': (role: AppRole.admin, mode: InterfaceMode.standard),
        'comptable@demo.test': (
          role: AppRole.accountant,
          mode: InterfaceMode.standard,
        ),
        'controleur@demo.test': (
          role: AppRole.controller,
          mode: InterfaceMode.standard,
        ),
        'enseignant@demo.test': (
          role: AppRole.teacher,
          mode: InterfaceMode.standard,
        ),
        'tuteur@demo.test': (
          role: AppRole.guardian,
          mode: InterfaceMode.standard,
        ),
        'eleve@demo.test': (
          role: AppRole.student,
          mode: InterfaceMode.standard,
        ),
        'enfant@demo.test': (role: AppRole.student, mode: InterfaceMode.enfant),
      };

      for (final MapEntry<String, ({AppRole role, InterfaceMode mode})> entree
          in attendus.entries) {
        expect(accesDemoDepuisCourriel(entree.key), entree.value);
      }
      expect(accesDemoDepuisCourriel('inconnu@demo.test'), isNull);
    });

    testWidgets('le mode demo ouvre le role sans appeler Supabase', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      final FausseSourceSession source = FausseSourceSession();
      await tester.pumpWidget(
        hote(
          const ConnexionPage(),
          surcharges: <Override>[
            demoAuthActiveProvider.overrideWithValue(true),
            sourceSessionProvider.overrideWithValue(source),
            serviceAuthProvider.overrideWithValue(auth),
          ],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        'admin@demo.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        'nimporte-quoi',
      );
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
      );
      bouton.onPress!();
      await tester.pumpAndSettle();

      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(ConnexionPage)),
      );
      expect(auth.connexionsMotDePasse, isEmpty);
      expect(
        conteneur.read(sessionProvider),
        const SessionState(
          resolue: true,
          role: AppRole.admin,
          profileId: 'demo-admin',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      );
    });
  });

  group('courrielPlausible', () {
    // Volontairement permissif : le seul verdict qui compte est celui du
    // serveur de courriel. Ce controle sert a ne pas envoyer une requete pour
    // une saisie manifestement incomplete.
    test('accepte des adresses ordinaires', () {
      for (final String valide in <String>[
        'a@b.co',
        'fatou.diallo@example.test',
        'moussa+cours@sous.domaine.fr',
      ]) {
        expect(courrielPlausible(valide), isTrue, reason: valide);
      }
    });

    test('refuse ce qui ne peut pas etre une adresse', () {
      for (final String invalide in <String>[
        '',
        'sans-arobase.fr',
        'deux@@arobases.fr',
        'espace dans@adresse.fr',
        'sanspoint@domaine',
        'point.final@domaine.',
      ]) {
        expect(courrielPlausible(invalide), isFalse, reason: invalide);
      }
    });
  });

  group('TUT-00 : la connexion', () {
    testWidgets('une adresse incomplete n envoie rien et le dit', (
      WidgetTester tester,
    ) async {
      // Le bouton n'est plus inerte au repos : il l'etait sans jamais dire
      // pourquoi, et son filet d'inertie -- le plus epais de l'ecran -- ecrasait
      // la hierarchie des trois actions. Ce qui compte n'a pas change : une
      // adresse incomplete ne part pas. La raison, elle, s'affiche desormais.
      final FauxServiceAuth auth = await _monter(tester);

      await tester.enterText(find.byType(TextField), 'fatou');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, isEmpty);
      expect(find.text(t.connexion.erreurCourriel), findsOneWidget);
    });

    testWidgets('une adresse valide declenche l envoi et change d etat', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await _monter(tester);

      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, <String>['fatou@example.test']);
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
    });

    testWidgets('L4 : deux chemins distincts, choisis en tete de carte', (
      WidgetTester tester,
    ) async {
      // Admission, lot B : la creation suit le questionnaire, deja repondu
      // ici (sans lui, « Creer un compte » ouvre `/commencer`).
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.moi,
          niveauTitulaire: NiveauDeclare.lectureLente,
          objectif: ObjectifApprentissage.indecis,
          moments: <MomentJournee>{MomentJournee.soir},
          langue: 'francais',
        ).versTexte(),
      );
      addTearDown(() => effacerMemoireAppareil(clefQuestionnaire));
      final FauxServiceAuth auth = await _monter(tester);
      expect(find.text(t.connexion.modeConnexion), findsOneWidget);
      expect(find.text(t.connexion.modeCreation), findsOneWidget);
      expect(find.text(t.connexion.titre), findsOneWidget);
      expect(find.text(t.connexion.appareilEleve), findsOneWidget);

      await tester.ensureVisible(find.text(t.connexion.modeCreation));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.modeCreation));
      await tester.pumpAndSettle();
      expect(find.text(t.connexion.titreCreation), findsOneWidget);
      expect(find.text(t.connexion.introCreation), findsOneWidget);
      // En creation, les sorties des comptes existants s'effacent.
      expect(find.text(t.connexion.appareilEleve), findsNothing);
      expect(find.text(t.connexion.probleme), findsNothing);
      expect(find.text(t.connexion.avecGoogle), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nour@example.test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.connexion.envoyerLienCreation));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLienCreation));
      await tester.pumpAndSettle();
      // Le meme lien cree le compte : c'est le serveur qui decide.
      expect(auth.liensEnvoyes, <String>['nour@example.test']);
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
    });

    testWidgets('L4 : ?mode=creer ouvre directement la creation', (
      WidgetTester tester,
    ) async {
      expect(
        modeDepuisAdresse(Uri.parse('/connexion?mode=creer')),
        ModeConnexion.creation,
      );
      expect(
        modeDepuisAdresse(Uri.parse('/connexion')),
        ModeConnexion.connexion,
      );
      await _monter(tester, mode: ModeConnexion.creation);
      expect(find.text(t.connexion.titreCreation), findsOneWidget);
      expect(find.text(t.connexion.envoyerLienCreation), findsOneWidget);
    });

    testWidgets('l ecran de confirmation ne se ferme pas tout seul', (
      WidgetTester tester,
    ) async {
      // Rien ne se ferme sur minuterie dans ce produit : l'utilisateur va
      // chercher son courriel et revient quand il veut.
      await _monter(tester);
      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 5));
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
    });

    testWidgets('un echec d envoi se dit, et laisse reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = await _monter(tester);
      auth.erreurAJeter = StateError('reseau');

      await tester.enterText(find.byType(TextField), 'fatou@example.test');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.connexion.envoyerLien));
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurEnvoi), findsOneWidget);
      expect(find.text(t.connexion.lienEnvoye), findsNothing);
    });

    testWidgets('aucun champ de mot de passe n existe sur cet ecran', (
      WidgetTester tester,
    ) async {
      // La compilation de production reste sans mot de passe. Le parcours de
      // demonstration est couvert explicitement par les tests ci-dessous.
      await _monter(tester);
      final Iterable<TextField> champs = tester.widgetList<TextField>(
        find.byType(TextField),
      );
      expect(champs, hasLength(1));
      expect(champs.single.obscureText, isFalse);
    });

    testWidgets('un bouton plein, un filet, puis des liens avec fleche', (
      WidgetTester tester,
    ) async {
      // Le defaut rapporte par l'operateur : « il y a des bordures sur chaque
      // bouton ». Les moyens d'entrer se lisent en trois rangs : l'aplat pour
      // le lien, le filet pour Google -- le seul de l'ecran -- puis les
      // sorties en liens avec fleche (parcours d'entree, 25/10/2026, §3 C).
      await _monter(tester);

      final List<NiveauAction> rangs = tester
          .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
          .map((ActionPrincipale a) => a.niveau)
          .toList();
      expect(rangs, <NiveauAction>[
        NiveauAction.principale,
        NiveauAction.secondaire,
      ]);
      expect(
        find.byKey(const ValueKey<String>('connexion-appareil-eleve')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('connexion-probleme')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(LienFleche, t.juridique.titre),
        findsOneWidget,
      );
    });

    testWidgets('le bouton Google porte le logo Google', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      final ActionPrincipale google = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.avecGoogle),
      );
      expect(google.prefixe, isA<LogoGoogle>());
      expect(find.byType(LogoGoogle), findsOneWidget);
    });

    testWidgets('l entree eleve dit a qui elle s adresse avant de naviguer', (
      WidgetTester tester,
    ) async {
      // « J'ai un code » ne disait ni pour qui ni ou trouver ce code. La
      // feuille porte l'explication, adressee au tuteur -- l'ecran de saisie
      // qui suit, lui, tutoie l'enfant.
      await _monter(tester);

      final Finder entree = find.text(t.connexion.appareilEleve);
      await tester.ensureVisible(entree);
      await tester.pumpAndSettle();
      await tester.tap(entree);
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.feuilleAppareil.pourQui), findsOneWidget);
      expect(find.text(t.connexion.feuilleAppareil.etape2), findsOneWidget);
      expect(find.text(t.connexion.feuilleAppareil.plafond), findsOneWidget);
      expect(find.text(t.connexion.feuilleAppareil.saisir), findsOneWidget);
    });

    testWidgets('la feuille ne promet jamais de scanner un code', (
      WidgetTester tester,
    ) async {
      // Aucun lecteur de code n'existe dans cette version (report assume,
      // ADR-016). Une feuille qui proposerait de scanner echouerait apres le
      // geste, ce qui coute plus cher qu'une fonction absente.
      await _monter(tester);

      final Finder entree = find.text(t.connexion.appareilEleve);
      await tester.ensureVisible(entree);
      await tester.pumpAndSettle();
      await tester.tap(entree);
      await tester.pumpAndSettle();

      expect(find.text(t.eleveConnexion.scanner), findsNothing);
    });

    testWidgets('le mode demo ne propose aucun parcours Supabase', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[
            serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Aucune carte : le formulaire est pose sur la page (25/10/2026).
      expect(find.byType(AppCard), findsNothing);

      final ActionPrincipale connexion = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.envoyerLien),
      );
      expect(connexion.niveau, NiveauAction.principale);

      // Cette ligne demandait auparavant `findsNothing` sur le libelle du
      // bouton qu'elle venait de trouver trois lignes plus haut : les deux
      // assertions ne pouvaient pas etre vraies ensemble, et le test echouait
      // par construction. Ce qu'elle voulait dire est ce qui suit -- le mode de
      // demonstration n'ouvre aucun chemin vers un vrai compte.
      expect(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        findsOneWidget,
      );
      expect(find.text(t.connexion.avecGoogle), findsNothing);
      expect(find.text(t.connexion.appareilEleve), findsNothing);
      expect(find.text(t.eleveConnexion.entrerCode), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le mode demonstration accepte email et mot de passe', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        ' fatou@example.test ',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        'essai-local',
      );
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
      );
      expect(bouton.onPress, isNotNull);
      bouton.onPress!();
      await tester.pumpAndSettle();

      expect(
        auth.connexionsMotDePasse,
        <({String courriel, String motDePasse})>[
          (courriel: 'fatou@example.test', motDePasse: 'essai-local'),
        ],
      );
    });

    testWidgets('le mode demonstration affiche une erreur recuperable', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth()
        ..erreurAJeter = StateError('refuse');
      await tester.pumpWidget(
        hote(
          const ConnexionPage(demoAuth: true),
          surcharges: <Override>[serviceAuthProvider.overrideWithValue(auth)],
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        'fatou@example.test',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-mot-de-passe')),
        'essai-local',
      );
      await tester.pump();
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
      );
      expect(bouton.onPress, isNotNull);
      bouton.onPress!();
      await tester.pumpAndSettle();

      expect(find.text(t.connexion.erreurEnvoi), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        findsOneWidget,
      );
    });
  });
}
