// Admission, lot B (fiche onboarding du 29/10/2026, validee le 29/10) : le
// questionnaire avant le compte, une question par ecran. L'ordre et le
// nombre des ecrans (Q5 : neuf au plus pour une famille d'un enfant, cinq
// pour « pour moi », la langue venant apres la connexion), le parcours
// complet jusqu'a la creation du compte, la limite de 18 ans, le retour, et
// une adresse ouverte trop tot.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart'
    show sourceSessionProvider;
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/connexion/connexion_page.dart'
    show parametreModeCreation;
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart'
    show UsageInscription;
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

Future<GoRouter> _monter(WidgetTester tester, String depart) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
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
    test('pour moi : quatre ecrans avant la connexion', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        usage: UsageInscription.moi,
      );
      expect(q.etapes.map((EtapeQuestionnaire e) => e.code), <String>[
        'pourQui',
        'niveauTitulaire',
        'objectif',
        'moments',
      ]);
    });

    test(
      'une famille d un enfant : huit ecrans, neuf si le parent apprend',
      () {
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
          'objectif',
          'moments',
        ]);
        expect(sans.copier(parentSuitDesCours: true).etapes, hasLength(9));
      },
    );

    test('chaque enfant de plus ajoute quatre ecrans', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        usage: UsageInscription.famille,
        enfants: <EnfantQuestionnaire>[_yasmine, EnfantQuestionnaire()],
        parentSuitDesCours: false,
      );
      expect(q.etapes, hasLength(12));
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
      );
      final QuestionnaireInscription relu =
          QuestionnaireInscription.depuisTexte(q.versTexte());
      expect(relu.complet, isTrue);
      expect(relu.enfants.single.prenom, 'Yasmine');
      expect(relu.apprenantsPourServeur(langue: 'poular'), <Object?>[
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
    testWidgets('une famille d un enfant va jusqu a la creation du compte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, Routes.commencer);
      expect(find.text(t.inscription.usage.question), findsOneWidget);
      expect(find.text('1 sur 4'), findsOneWidget);
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
      expect(find.text('2 sur 8'), findsOneWidget);
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

      expect(find.text(t.parcours.objectifQuestion), findsOneWidget);
      await _taper(tester, find.text(t.parcours.objectifApprendreALire));
      await _continuer(tester);

      expect(find.text(t.parcours.momentsQuestion), findsOneWidget);
      expect(find.text('8 sur 8'), findsOneWidget);
      await _taper(tester, find.text(t.parcours.momentSoir));
      await _continuer(tester);

      expect(routeur.state.uri.path, Routes.connexion);
      expect(routeur.state.uri.queryParameters['mode'], parametreModeCreation);
      // Les reponses attendent la connexion sur l'appareil.
      final QuestionnaireInscription garde =
          QuestionnaireInscription.depuisTexte(
            lireMemoireAppareil(clefQuestionnaire),
          );
      expect(garde.complet, isTrue);
      expect(garde.enfants.single.genre, Genre.femme);
      expect(garde.moments, <MomentJournee>{MomentJournee.soir});
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
      expect(routeur.state.uri.queryParameters['mode'], isNull);
    });
  });
}
