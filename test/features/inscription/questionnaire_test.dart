// Admission, lot B (fiche onboarding du 29/10/2026, validee le 29/10) : le
// questionnaire avant le compte, une question par ecran. L'ordre et le
// nombre des ecrans (Q5 : neuf au plus pour une famille d'un enfant, cinq
// pour « pour moi », langue du cours comprise, 29/10), le parcours
// complet jusqu'a la creation du compte, la limite de 18 ans, le retour, et
// une adresse ouverte trop tot.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart'
    show serviceAuthProvider;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart'
    show languesCoursProvider;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart'
    show sourceSessionProvider;
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/connexion/connexion_page.dart'
    show parametreModeCreation;
import 'package:rewayah_academy/features/connexion/ordre_entree.dart'
    show parametreModeConnexion;
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart'
    show UsageInscription;
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/acces_questionnaire.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const EnfantQuestionnaire _yasmine = EnfantQuestionnaire(
  prenom: 'Yasmine',
  age: 9,
  genre: Genre.femme,
  niveau: NiveauDeclare.debutLettres,
);

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  FauxServiceAuth? auth,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
        // La liste publique des langues (lue sans compte).
        languesCoursProvider.overrideWith(
          (_) async => const <LangueCours>[
            LangueCours(code: 'francais', nom: 'Français'),
            LangueCours(code: 'poular', nom: 'Poular'),
          ],
        ),
      ],
      routes: <RouteBase>[
        GoRoute(
          path: Routes.commencer,
          builder: (BuildContext contexte, GoRouterState etat) {
            routeur = GoRouter.of(contexte);
            return QuestionnairePage(code: etat.uri.queryParameters['etape']);
          },
        ),
        GoRoute(
          path: Routes.connexion,
          builder: (BuildContext contexte, GoRouterState etat) {
            routeur = GoRouter.of(contexte);
            return Scaffold(body: Text('CONNEXION ${etat.uri.query}'));
          },
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.byKey(const Key('questionnaire-continuer')));

void main() {
  setUp(() => effacerMemoireAppareil(clefQuestionnaire));

  group('les ecrans, dans l ordre (Q5)', () {
    test('pour moi : cinq ecrans avant la connexion', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        usage: UsageInscription.moi,
      );
      expect(q.etapes.map((EtapeQuestionnaire e) => e.code), <String>[
        'pourQui',
        'langue',
        'niveauTitulaire',
        'objectif',
        'moments',
      ]);
    });

    test('une famille d un enfant : neuf ecrans, dix si le parent apprend', () {
      const QuestionnaireInscription sans = QuestionnaireInscription(
        usage: UsageInscription.famille,
        enfants: <EnfantQuestionnaire>[_yasmine],
        parentSuitDesCours: false,
      );
      expect(sans.etapes.map((EtapeQuestionnaire e) => e.code), <String>[
        'pourQui',
        'prenom-0',
        'age-0',
        'genre-0',
        'niveau-0',
        'parent',
        'langue',
        'objectif',
        'moments',
      ]);
      expect(sans.copier(parentSuitDesCours: true).etapes, hasLength(10));
    });

    test('le total du compteur ne grandit jamais apres une reponse '
        '(FINITION 22 b)', () {
      // Avant toute reponse : le plus long parcours d'un enfant.
      expect(const QuestionnaireInscription().etapesAuPlus, 10);
      // « J'inscris mon enfant » : le meme total, rien ne s'ajoute.
      const QuestionnaireInscription famille = QuestionnaireInscription(
        usage: UsageInscription.famille,
        enfants: <EnfantQuestionnaire>[_yasmine],
      );
      expect(famille.etapesAuPlus, 10);
      // Le parent ne suit pas de cours : une question de moins.
      expect(famille.copier(parentSuitDesCours: false).etapesAuPlus, 9);
      // « Pour moi » : le total baisse, il ne monte pas.
      expect(
        const QuestionnaireInscription(usage: UsageInscription.moi)
            .etapesAuPlus,
        5,
      );
      // Le total au plus n'est jamais plus court que le parcours reel.
      for (final QuestionnaireInscription q in <QuestionnaireInscription>[
        const QuestionnaireInscription(),
        famille,
        famille.copier(parentSuitDesCours: true),
      ]) {
        expect(q.etapesAuPlus, greaterThanOrEqualTo(q.etapes.length));
      }
    });

    test('chaque enfant de plus ajoute quatre ecrans', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        usage: UsageInscription.famille,
        enfants: <EnfantQuestionnaire>[_yasmine, EnfantQuestionnaire()],
        parentSuitDesCours: false,
      );
      expect(q.etapes, hasLength(13));
      expect(
        q.premiereManquante,
        const EtapeQuestionnaire(SorteEtape.prenom, 1),
      );
    });

    test('les reponses survivent a la relecture, et partent au serveur', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        usage: UsageInscription.famille,
        enfants: <EnfantQuestionnaire>[_yasmine],
        parentSuitDesCours: true,
        niveauTitulaire: NiveauDeclare.lectureCourante,
        objectif: ObjectifApprentissage.memoriser,
        moments: <MomentJournee>{MomentJournee.soir, MomentJournee.matin},
        langue: 'poular',
      );
      final QuestionnaireInscription relu =
          QuestionnaireInscription.depuisTexte(q.versTexte());
      expect(relu.complet, isTrue);
      expect(relu.enfants.single.prenom, 'Yasmine');
      expect(relu.apprenantsPourServeur(), <Object?>[
        <String, Object?>{
          'prenom': 'Yasmine',
          'age': 9,
          'genre': 'female',
          'niveau': 'debut_lettres',
          'objectif': 'memoriser',
          'moments': <String>['matin', 'soir'],
          'langue': 'poular',
        },
        <String, Object?>{
          'est_titulaire': true,
          'niveau': 'lecture_courante',
          'objectif': 'memoriser',
          'moments': <String>['matin', 'soir'],
          'langue': 'poular',
        },
      ]);
      expect(
        QuestionnaireInscription.depuisTexte('{pas du json').usage,
        isNull,
      );
    });

    test('creer un compte passe par le questionnaire, sauf avec un code', () {
      Uri creer([Map<String, String> plus = const <String, String>{}]) => Uri(
        path: Routes.connexion,
        queryParameters: <String, String>{
          'mode': parametreModeCreation,
          ...plus,
        },
      );
      expect(
        redirectionCreationCompte(creer(), questionnaireComplet: false),
        Routes.commencer,
      );
      expect(
        redirectionCreationCompte(creer(), questionnaireComplet: true),
        isNull,
      );
      expect(
        redirectionCreationCompte(
          creer(<String, String>{parametreInvitation: '1'}),
          questionnaireComplet: false,
        ),
        isNull,
      );
      // CAND-04 : le lien direct du candidat enseignant.
      expect(
        redirectionCreationCompte(
          creer(<String, String>{parametreCandidature: '1'}),
          questionnaireComplet: false,
        ),
        isNull,
      );
      // INVITATION-SECOND-ADULTE (07/11/2026) : l'adulte invite a rejoindre
      // un foyer cree son compte sans le questionnaire des familles.
      expect(
        redirectionCreationCompte(
          creer(<String, String>{
            parametreFoyer: '1',
            'code': 'ABCD-EFGH-JKMN',
          }),
          questionnaireComplet: false,
        ),
        isNull,
      );
      expect(
        redirectionCreationCompte(
          Uri(path: Routes.connexion),
          questionnaireComplet: false,
        ),
        isNull,
      );
    });
  });

  group('l ecran', () {
    testWidgets('une famille d un enfant va jusqu au dernier ecran, l acces, '
        'dans le questionnaire (QUESTIONNAIRE-FIN)', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      final GoRouter routeur = await _monter(
        tester,
        Routes.commencer,
        auth: auth,
      );
      expect(find.text(t.inscription.usage.question), findsOneWidget);
      // Le dernier ecran, l'acces, compte dans la barre. Le total est celui
      // du plus long parcours : il ne grandit jamais apres une reponse
      // (FINITION 22 b ; avant : « 1 sur 6 », puis « 2 sur 10 »).
      expect(find.text('1 sur 11'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      // Jamais grise : sans reponse, « Continuer » le dit et reste ici.
      await _continuer(tester);
      expect(
        find.byKey(const Key('questionnaire-reponse-requise')),
        findsOneWidget,
      );
      expect(find.text(t.inscription.usage.question), findsOneWidget);

      await _taper(tester, find.text(t.inscription.usage.familleTitre));
      await _continuer(tester);
      expect(
        find.text(t.inscription.questionnaire.prenomQuestion),
        findsOneWidget,
      );
      expect(find.text('2 sur 11'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('questionnaire-prenom')),
        'Yasmine',
      );
      await tester.pump();
      await _continuer(tester);

      expect(
        find.text(t.inscription.questionnaire.ageQuestion(prenom: 'Yasmine')),
        findsOneWidget,
      );
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-age-9')),
      );
      await _continuer(tester);

      expect(
        find.text(t.inscription.questionnaire.genreQuestion(prenom: 'Yasmine')),
        findsOneWidget,
      );
      await _taper(tester, find.text(t.inscription.questionnaire.fille));
      await _continuer(tester);

      expect(
        find.text(t.parcours.niveauQuestion(prenom: 'Yasmine')),
        findsOneWidget,
      );
      await _taper(tester, find.text(t.parcours.niveauDebutLettres));
      await _continuer(tester);

      expect(find.text(t.inscription.usage.coursQuestion), findsOneWidget);
      await _taper(tester, find.text(t.inscription.usage.coursNon));
      await _continuer(tester);

      // La langue du cours, avant le compte (directeur, 29/10).
      expect(find.text(t.parcours.langueQuestion), findsOneWidget);
      await _taper(tester, find.text('Poular'));
      await _continuer(tester);

      expect(find.text(t.parcours.objectifQuestion), findsOneWidget);
      await _taper(tester, find.text(t.parcours.objectifApprendreALire));
      await _continuer(tester);

      expect(find.text(t.parcours.momentsQuestion), findsOneWidget);
      expect(find.text('9 sur 10'), findsOneWidget);
      await _taper(tester, find.text(t.parcours.momentSoir));
      await _continuer(tester);

      // Avant : la page passait a la connexion (`/connexion?mode=creer`).
      // Le dernier ecran reste dans le questionnaire, la barre au bout.
      expect(routeur.state.uri.path, Routes.commencer);
      expect(routeur.state.uri.queryParameters['etape'], codeEtapeAcces);
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsOneWidget);
      expect(find.text('10 sur 10'), findsOneWidget);
      final a = t.inscription.questionnaire.acces;
      expect(find.text('${a.reponsesGardees} ${a.resteAcces}'), findsOneWidget);
      expect(find.text(t.connexion.avecGoogle), findsOneWidget);
      // Ni onglets ni bouton eleve : seulement l'acces.
      expect(find.text(t.connexion.modeCreation), findsNothing);
      expect(find.text(t.connexion.modeConnexion), findsNothing);
      expect(find.text(t.connexion.appareilEleve), findsNothing);
      verifierUnSeulBoutonPlein(tester);
      // Les reponses attendent la connexion sur l'appareil.
      final QuestionnaireInscription garde =
          QuestionnaireInscription.depuisTexte(
            lireMemoireAppareil(clefQuestionnaire),
          );
      expect(garde.complet, isTrue);
      expect(garde.enfants.single.genre, Genre.femme);
      expect(garde.langue, 'poular');
      expect(garde.moments, <MomentJournee>{MomentJournee.soir});

      // Le lien envoye reste dans le meme habillage.
      await tester.enterText(
        find.byKey(const Key('questionnaire-acces-courriel')),
        'famille@exemple.com',
      );
      await tester.pump();
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-acces-envoyer')),
      );
      expect(auth.liensEnvoyes, <String>['famille@exemple.com']);
      expect(find.text(t.connexion.lienEnvoye), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('questionnaire-acces-envoye')),
        findsOneWidget,
      );
      // Le lien parti : seulement « Vos reponses sont gardees. ».
      expect(find.text(a.reponsesGardees), findsOneWidget);
      expect(find.textContaining(a.resteAcces), findsNothing);
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsOneWidget);
      expect(routeur.state.uri.queryParameters['etape'], codeEtapeAcces);
    });

    // DECISION-FLUIDITE (07/11/2026) : se connecter est sensible ; pendant
    // la connexion avec Google, le bouton attend (ActionPrincipale.enCours).
    testWidgets('connexion avec Google : le bouton attend pendant la '
        'connexion', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.famille,
          enfants: <EnfantQuestionnaire>[_yasmine],
          parentSuitDesCours: false,
          objectif: ObjectifApprentissage.apprendreALire,
          moments: <MomentJournee>{MomentJournee.soir},
          langue: 'poular',
        ).versTexte(),
      );
      final _AuthGoogleLente auth = _AuthGoogleLente();
      await _monter(
        tester,
        '${Routes.commencer}?etape=$codeEtapeAcces',
        auth: auth,
      );
      const ValueKey<String> cle = ValueKey<String>(
        'questionnaire-acces-google',
      );
      await tester.ensureVisible(find.byKey(cle));
      await tester.tap(find.byKey(cle));
      await tester.pump();
      expect(tester.widget<ActionPrincipale>(find.byKey(cle)).enCours, isTrue);
      // Un second appui pendant l'attente ne relance rien.
      await tester.tap(find.byKey(cle), warnIfMissed: false);
      await tester.pump();
      expect(auth.google, 1);
      auth.reponse.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<ActionPrincipale>(find.byKey(cle)).enCours, isFalse);
    });

    testWidgets('ALIGN-RENVOI : a l ordinateur, « Renvoyer le lien » prend la '
        'largeur du champ', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.famille,
          enfants: <EnfantQuestionnaire>[_yasmine],
          parentSuitDesCours: false,
          objectif: ObjectifApprentissage.apprendreALire,
          moments: <MomentJournee>{MomentJournee.soir},
          langue: 'poular',
        ).versTexte(),
      );
      await _monter(
        tester,
        '${Routes.commencer}?etape=$codeEtapeAcces',
        taille: const Size(1280, 800),
      );
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('questionnaire-acces-courriel')),
        'famille@exemple.com',
      );
      await tester.pump();
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-acces-envoyer')),
      );
      final Rect texte = tester.getRect(
        find.byKey(const ValueKey<String>('questionnaire-acces-envoye')),
      );
      final Rect bouton = tester.getRect(
        find.byKey(const ValueKey<String>('questionnaire-acces-renvoyer')),
      );
      // Avant : compact au bord de fin (`BoutonEntree`, largeur du libelle).
      expect(bouton.left, texte.left);
      expect(bouton.right, texte.right);
    });

    testWidgets('QUESTIONNAIRE-FIN : l acces ouvert trop tot ramene a la '
        'premiere question manquante', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        '${Routes.commencer}?etape=$codeEtapeAcces',
      );
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsNothing);
      expect(routeur.state.uri.queryParameters['etape'], 'pourQui');
    });

    testWidgets('INSCRIPTION-3 : un toucher sur « Pour qui » choisit la carte '
        'et reste ; seul « Continuer » avance', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, Routes.commencer);
      // L'ecran ouvert sans `?etape=` fixe son adresse des l'ouverture.
      expect(routeur.state.uri.queryParameters['etape'], 'pourQui');
      final Finder famille = find.text(t.inscription.usage.familleTitre);
      await _taper(tester, famille);
      // Avant : la page passait aussitot au prenom, sans etat choisi.
      expect(find.text(t.inscription.usage.question), findsOneWidget);
      expect(
        find.text(t.inscription.questionnaire.prenomQuestion),
        findsNothing,
      );
      expect(routeur.state.uri.queryParameters['etape'], 'pourQui');
      // La carte choisie est annoncee comme telle.
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('^${t.inscription.usage.familleTitre}')),
        ),
        isSemantics(isChecked: true),
      );
      // Un second toucher ne saute rien.
      await _taper(tester, famille);
      expect(find.text(t.inscription.usage.question), findsOneWidget);
      await _continuer(tester);
      expect(
        find.text(t.inscription.questionnaire.prenomQuestion),
        findsOneWidget,
      );
      expect(routeur.state.uri.queryParameters['etape'], 'prenom-0');
    });

    testWidgets('18 ans ou plus : la phrase dit de s inscrire soi-meme, '
        'aucune avance', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.famille,
          enfants: <EnfantQuestionnaire>[EnfantQuestionnaire(prenom: 'Omar')],
        ).versTexte(),
      );
      await _monter(tester, '${Routes.commencer}?etape=age-0');
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-age-adulte')),
      );
      expect(
        find.text(t.inscription.questionnaire.adulteDetail),
        findsOneWidget,
      );
      await _continuer(tester);
      expect(
        find.text(t.inscription.questionnaire.ageQuestion(prenom: 'Omar')),
        findsOneWidget,
      );
    });

    testWidgets('UX-032 : l age commence a 6 ans, comme l ajout d un profil, '
        'et la regle se dit au moment du choix', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.famille,
          enfants: <EnfantQuestionnaire>[EnfantQuestionnaire(prenom: 'Omar')],
        ).versTexte(),
      );
      await _monter(tester, '${Routes.commencer}?etape=age-0');
      // Une seule source avec l'ajout d'un profil eleve, jamais une valeur
      // ecrite deux fois.
      expect(ageMinimum, BornesAge.clientActuelle.min);
      expect(ageMinimum, 6);
      expect(
        find.byKey(const ValueKey<String>('questionnaire-age-5')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('questionnaire-age-6')),
        findsOneWidget,
      );
      expect(
        find.text(t.inscription.questionnaire.ageMinimum(min: 6)),
        findsOneWidget,
      );
    });

    testWidgets('une adresse ouverte trop tot ramene au premier ecran sans '
        'reponse', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        '${Routes.commencer}?etape=moments',
      );
      expect(routeur.state.uri.queryParameters['etape'], 'pourQui');
      expect(find.text(t.inscription.usage.question), findsOneWidget);
    });

    testWidgets('revenir du prenom d un enfant ajoute, sans le saisir, le '
        'retire', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          usage: UsageInscription.famille,
          enfants: <EnfantQuestionnaire>[_yasmine, EnfantQuestionnaire()],
          parentSuitDesCours: false,
          objectif: ObjectifApprentissage.indecis,
          moments: <MomentJournee>{MomentJournee.matin},
          langue: 'francais',
        ).versTexte(),
      );
      await _monter(tester, '${Routes.commencer}?etape=prenom-1');
      await _taper(tester, find.byType(DisqueRetour));
      final QuestionnaireInscription garde =
          QuestionnaireInscription.depuisTexte(
            lireMemoireAppareil(clefQuestionnaire),
          );
      expect(garde.enfants, hasLength(1));
      expect(garde.complet, isTrue);
    });

    testWidgets('« J ai deja un compte » mene a la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, Routes.commencer);
      await _taper(
        tester,
        find.byKey(const Key('questionnaire-deja-un-compte')),
      );
      expect(routeur.state.uri.path, Routes.connexion);
      // ENTREE-ORDRE : la connexion demandee expressement, qui reste meme sur
      // un appareil qui n'a jamais connu de compte.
      expect(routeur.state.uri.queryParameters['mode'], parametreModeConnexion);
    });
  });
}

/// La connexion avec Google qui ne repond qu'a la demande du test.
class _AuthGoogleLente extends FauxServiceAuth {
  final Completer<void> reponse = Completer<void>();

  @override
  Future<void> connexionGoogle() async {
    google++;
    await reponse.future;
  }
}
