// ONBOARDING-PRAXIS (directeur, 22/11/2026 ; maquette validee
// docs/current/maquettes/onboarding-praxis/prototype.html) : le questionnaire
// avant le compte, guide par Praxis. Le plan des ecrans et ses branches
// (lecture, memorise, detail), les prenoms en lettres, ce qui part au
// serveur, la garde « Enseigner » (la candidature sans invitation, sans
// compte eleve), « Pour plusieurs enfants », l'acces, et les captures R3.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart'
    show serviceAuthProvider;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart'
    show sourceSessionProvider;
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart'
    show parametreModeCreation;
import 'package:rewayah_academy/features/connexion/ordre_entree.dart'
    show parametreModeConnexion;
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/acces_questionnaire.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/coquille_onboarding.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/onboarding_donnees.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Un adulte debutant, tout repondu.
const QuestionnaireInscription _moiComplet = QuestionnaireInscription(
  commence: true,
  apprendre: true,
  pourQui: PourQui.moi,
  apprenants: <ApprenantQuestionnaire>[
    ApprenantQuestionnaire(
      prenom: 'Amina',
      genre: Genre.femme,
      niveau: NiveauDeclare.debutLettres,
      objectif: ObjectifOnboarding.lire,
      titulaire: true,
    ),
  ],
  langue: 'francais',
);

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  FauxServiceAuth? auth,
  Size taille = const Size(390, 844),
  List<Override> enPlus = const <Override>[],
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
        ...enPlus,
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

Future<void> _carte(WidgetTester tester, String cle, String valeur) =>
    _taper(tester, find.byKey(ValueKey<String>('questionnaire-$cle-$valeur')));

String? _etape(GoRouter r) => r.state.uri.queryParameters['etape'];

/// Le titre de l'ecran courant.
String _titre(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('onboarding-titre')),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// La phrase que Praxis dit.
String _bulle(WidgetTester tester) => tester
    .widget<Semantics>(
      find
          .descendant(
            of: find.byKey(CoquilleOnboarding.cleBulle),
            matching: find.byType(Semantics),
          )
          .first,
    )
    .properties
    .label!;

void main() {
  setUp(() => effacerMemoireAppareil(clefQuestionnaire));
  tearDown(oublierInvitationEnCours);

  group('le plan des ecrans et ses branches', () {
    test('un adulte debutant : ni age, ni lecture, ni memorise', () {
      expect(_moiComplet.etapes.map((EtapeQuestionnaire e) => e.code), <String>[
        'accueil',
        'garde',
        'pourQui',
        'prenom-0',
        'genre-0',
        'famille',
        'niveau-0',
        'objectif-0',
        'depart',
        'langue',
        'langueSecours',
        'chemin',
        'recap',
      ]);
      expect(_moiComplet.complet, isTrue);
      // Aucune question « enseignante obligatoire » (directeur, 22/11).
      expect(
        SorteEtape.values.map((SorteEtape s) => s.name),
        isNot(contains('enseignante')),
      );
    });

    test('« lit deja le Coran » ouvre la lecture ; « a memorise » ouvre la '
        'lecture, la quantite et le detail ; « tout le Coran » n a pas de '
        'detail', () {
      QuestionnaireInscription avec(ApprenantQuestionnaire a) =>
          _moiComplet.copier(apprenants: <ApprenantQuestionnaire>[a]);
      final ApprenantQuestionnaire base = _moiComplet.apprenants.single;
      List<String> codes(QuestionnaireInscription q) => <String>[
        for (final EtapeQuestionnaire e in q.etapes)
          if (e.chapitre == Chapitre.niveau) e.code,
      ];
      expect(
        codes(avec(base.copier(niveau: NiveauDeclare.lectureCourante))),
        <String>['niveau-0', 'lecture-0', 'objectif-0', 'depart'],
      );
      expect(
        codes(avec(base.copier(niveau: NiveauDeclare.lectureLente))),
        <String>['niveau-0', 'objectif-0', 'depart'],
      );
      final ApprenantQuestionnaire memo = base.copier(
        niveau: NiveauDeclare.memorisationPartielle,
        quantite: QuantiteMemorisee.unACinqJuz,
      );
      expect(codes(avec(memo)), <String>[
        'niveau-0',
        'lecture-0',
        'memorise-0',
        'detail-0',
        'objectif-0',
        'depart',
      ]);
      expect(
        codes(avec(memo.copier(quantite: QuantiteMemorisee.coranEntier))),
        <String>['niveau-0', 'lecture-0', 'memorise-0', 'objectif-0', 'depart'],
      );
    });

    test('un enfant a son age ; le parent ajoute n en a pas', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        commence: true,
        apprendre: true,
        pourQui: PourQui.unEnfant,
        apprenants: <ApprenantQuestionnaire>[
          ApprenantQuestionnaire(prenom: 'Yasmine'),
          ApprenantQuestionnaire(prenom: 'Fatou', titulaire: true),
        ],
      );
      final List<String> codes = <String>[
        for (final EtapeQuestionnaire e in q.etapes)
          if (e.chapitre == Chapitre.quiApprend) e.code,
      ];
      expect(codes, <String>[
        'garde',
        'pourQui',
        'prenom-0',
        'age-0',
        'genre-0',
        'prenom-1',
        'genre-1',
        'famille',
      ]);
    });

    test('« Pour plusieurs enfants » : l interlude famille attend le '
        'deuxieme enfant', () {
      const QuestionnaireInscription un = QuestionnaireInscription(
        pourQui: PourQui.plusieurs,
        apprenants: <ApprenantQuestionnaire>[ApprenantQuestionnaire()],
      );
      expect(un.encoreUnEnfant, isTrue);
      expect(
        un.repondue(const EtapeQuestionnaire(SorteEtape.famille)),
        isFalse,
      );
      final QuestionnaireInscription deux = un.copier(
        apprenants: const <ApprenantQuestionnaire>[
          ApprenantQuestionnaire(),
          ApprenantQuestionnaire(),
        ],
      );
      expect(deux.encoreUnEnfant, isFalse);
    });

    test('le remplissage de la barre suit les quatre chapitres', () {
      final List<EtapeQuestionnaire> plan = _moiComplet.etapes;
      expect(
        remplissageOnboarding(
          plan,
          plan.indexOf(const EtapeQuestionnaire(SorteEtape.langue)),
        ),
        <double>[1, 1, 0, 0],
      );
      expect(remplissageOnboarding(plan, 0, rangDemande: 3), <double>[
        1,
        1,
        1,
        3 / 5,
      ]);
    });
  });

  group('les reponses', () {
    test('un prenom : des lettres de toute ecriture, 2 a 30 signes', () {
      for (final String bon in <String>[
        'Yasmine',
        'Jean-Luc',
        "N'Diaye",
        'ياسمين',
        'Aïcha',
        'Mamadou Lamine',
      ]) {
        expect(prenomValide(bon), isTrue, reason: bon);
      }
      for (final String mauvais in <String>[
        'Y',
        'Bah2',
        '٠١',
        'Yasmine 😀',
        '-Ali',
        'A' * 31,
        '   ',
      ]) {
        expect(prenomValide(mauvais), isFalse, reason: mauvais);
      }
    });

    test('ce qui part au serveur : lecture, memorise, priere, langues', () {
      const QuestionnaireInscription q = QuestionnaireInscription(
        commence: true,
        apprendre: true,
        pourQui: PourQui.unEnfant,
        apprenants: <ApprenantQuestionnaire>[
          ApprenantQuestionnaire(
            prenom: 'Yasmine',
            age: 8,
            genre: Genre.femme,
            niveau: NiveauDeclare.debutLettres,
            objectif: ObjectifOnboarding.priere,
          ),
          ApprenantQuestionnaire(
            prenom: 'Bilal',
            age: 12,
            genre: Genre.homme,
            niveau: NiveauDeclare.memorisationPartielle,
            lecture: LectureCoran.autre,
            lectureAutre: 'Qalun',
            quantite: QuantiteMemorisee.unACinqJuz,
            juz: <int>[30, 29],
            sourates: <String>['fatiha'],
            objectif: ObjectifOnboarding.memoriser,
          ),
        ],
        langue: 'ha',
        langueSecours: 'francais',
        langueAutre: ' Tamoul ',
        source: SourceConnaissance.reseaux,
      );
      expect(q.apprenantsPourServeur(), <Map<String, Object?>>[
        <String, Object?>{
          'prenom': 'Yasmine',
          'age': 8,
          'genre': 'female',
          'niveau': 'debut_lettres',
          'objectif': 'priere_invocations',
          'moments': <String>[],
          'langue': 'ha',
          'langue_secours': 'francais',
          'langue_autre': 'Tamoul',
        },
        <String, Object?>{
          'prenom': 'Bilal',
          'age': 12,
          'genre': 'male',
          'niveau': 'memorisation_partielle',
          'objectif': 'memoriser',
          'moments': <String>[],
          'langue': 'ha',
          'langue_secours': 'francais',
          'langue_autre': 'Tamoul',
          'riwaya': 'autre',
          'riwaya_autre': 'Qalun',
          'memorise': '1_5_juz',
          'juz': <int>[29, 30],
        },
      ]);
      expect(q.sourcePourServeur, 'reseaux');
      // « Lire » se dit « apprendre a lire » pour un debutant, « devenir
      // fluide » pour un lecteur.
      expect(
        const ApprenantQuestionnaire(
          niveau: NiveauDeclare.lectureLente,
          objectif: ObjectifOnboarding.lire,
        ).objectifSql,
        'devenir_fluide',
      );
      expect(
        const ApprenantQuestionnaire(
          niveau: NiveauDeclare.lettresAvecAide,
          objectif: ObjectifOnboarding.lire,
        ).objectifSql,
        'apprendre_a_lire',
      );
      // Relu depuis l'appareil, a l'identique.
      final QuestionnaireInscription relu =
          QuestionnaireInscription.depuisTexte(q.versTexte());
      expect(relu.apprenantsPourServeur(), q.apprenantsPourServeur());
      expect(relu.source, SourceConnaissance.reseaux);
      // Un texte d'avant ce questionnaire repart de zero.
      expect(
        QuestionnaireInscription.depuisTexte('{"usage":"moi"}').pourQui,
        isNull,
      );
    });

    test('la duree des bases suit la tranche d age du programme', () {
      expect(const ApprenantQuestionnaire(age: 7).tranche.semainesPrevues, 37);
      expect(const ApprenantQuestionnaire(age: 12).tranche.semainesLimite, 36);
      expect(const ApprenantQuestionnaire(age: 15).tranche.semainesPrevues, 24);
      expect(
        const ApprenantQuestionnaire(titulaire: true).tranche.semainesLimite,
        20,
      );
    });

    test('creer un compte passe par le questionnaire, sauf candidat, code '
        'ou foyer', () {
      Uri u(String q) => Uri.parse('/connexion?mode=$parametreModeCreation$q');
      expect(
        redirectionCreationCompte(u(''), questionnaireComplet: false),
        Routes.commencer,
      );
      expect(
        redirectionCreationCompte(u(''), questionnaireComplet: true),
        isNull,
      );
      for (final String p in <String>[
        '&$parametreCandidature=1',
        '&$parametreInvitation=1',
        '&$parametreFoyer=1',
      ]) {
        expect(
          redirectionCreationCompte(u(p), questionnaireComplet: false),
          isNull,
        );
      }
    });
  });

  group('l ecran', () {
    testWidgets('un adulte debutant, de l accueil a l acces, avec Praxis', (
      WidgetTester tester,
    ) async {
      final GoRouter r = await _monter(tester, Routes.commencer);
      expect(_etape(r), 'accueil');
      expect(_titre(tester), t.onboarding.accueil.titre);
      expect(_bulle(tester), t.onboarding.accueil.dit);
      expect(find.byKey(PraxisGuide.cle), findsOneWidget);
      expect(find.text(t.onboarding.praxisIa), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await _continuer(tester);

      expect(_etape(r), 'garde');
      await _carte(tester, 'garde', 'apprendre');
      expect(_bulle(tester), t.onboarding.garde.reponse);
      await _continuer(tester);

      expect(_etape(r), 'pourQui');
      await _carte(tester, 'pour-qui', 'moi');
      expect(_bulle(tester), t.onboarding.pourQui.reponseMoi);
      await _continuer(tester);

      expect(_etape(r), 'prenom-0');
      expect(_titre(tester), t.onboarding.prenom.titreMoi);
      await tester.enterText(
        find.byKey(const Key('questionnaire-prenom')),
        'Amina',
      );
      await _continuer(tester);
      // Un adulte : jamais son age.
      expect(_etape(r), 'genre-0');
      await _carte(tester, 'genre', 'femme');
      await _continuer(tester);

      expect(_etape(r), 'famille');
      expect(_titre(tester), t.onboarding.famille.titreSeul);
      expect(_bulle(tester), t.onboarding.famille.ditSeul(prenom: 'Amina'));
      await _continuer(tester);

      expect(_etape(r), 'niveau-0');
      await _carte(tester, 'niveau', 'debut_lettres');
      await _continuer(tester);
      // Un debutant : ni lecture ni memorise.
      expect(_etape(r), 'objectif-0');
      // Un adulte n a pas la carte « priere ».
      expect(
        find.byKey(const ValueKey<String>('questionnaire-objectif-priere')),
        findsNothing,
      );
      await _carte(tester, 'objectif', 'lire');
      await _continuer(tester);

      expect(_etape(r), 'depart');
      expect(find.text(t.onboarding.depart.probable), findsOneWidget);
      expect(find.text(t.onboarding.depart.etapes.examen), findsOneWidget);
      await _continuer(tester);

      expect(_etape(r), 'langue');
      await _carte(tester, 'langue-afrique', 'ha');
      expect(
        _bulle(tester),
        t.onboarding.langue.reponse(langue: t.onboarding.langues.ha),
      );
      await _continuer(tester);
      expect(_etape(r), 'langueSecours');
      // La langue choisie n'est pas proposee en secours.
      expect(
        find.byKey(const ValueKey<String>('questionnaire-langue-secours-ha')),
        findsNothing,
      );
      await _carte(tester, 'langue-secours', 'francais');
      await _continuer(tester);

      expect(_etape(r), 'chemin');
      // La courbe du debutant adulte : 15 semaines prevues.
      expect(
        find.text(LibellesGroupe.insecable(t.onboarding.chemin.prevues(n: 15))),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          t.onboarding.chemin.rigueurTitre,
          findRichText: true,
        ),
        findsOneWidget,
      );
      await _continuer(tester);

      expect(_etape(r), 'recap');
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-source-mosquee')),
      );
      expect(find.text(t.onboarding.recap.rembourse), findsOneWidget);
      await _continuer(tester);
      expect(_etape(r), codeEtapeAcces);
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsOneWidget);
      expect(_titre(tester), t.onboarding.acces.titre);

      final QuestionnaireInscription q = QuestionnaireInscription.depuisTexte(
        lireMemoireAppareil(clefQuestionnaire),
      );
      expect(q.complet, isTrue);
      expect(q.langue, 'ha');
      expect(q.langueSecours, 'francais');
      expect(q.source, SourceConnaissance.mosquee);
    });

    testWidgets('un enfant qui a memorise : lecture (Hafs preselectionnee), '
        'quantite, sourates, objectif « memoriser » preselectionne', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          commence: true,
          apprendre: true,
          pourQui: PourQui.unEnfant,
          apprenants: <ApprenantQuestionnaire>[
            ApprenantQuestionnaire(
              prenom: 'Yasmine',
              age: 9,
              genre: Genre.femme,
            ),
          ],
        ).versTexte(),
      );
      final GoRouter r = await _monter(
        tester,
        '${Routes.commencer}?etape=niveau-0',
      );
      expect(_titre(tester), t.onboarding.niveau.titre(prenom: 'Yasmine'));
      // Le niveau se dit au feminin pour une fille.
      expect(find.text(t.onboarding.niveau.elle.memo), findsOneWidget);
      await _carte(tester, 'niveau', 'memorisation_partielle');
      await _continuer(tester);

      expect(_etape(r), 'lecture-0');
      expect(_titre(tester), t.onboarding.lecture.titreElle(prenom: 'Yasmine'));
      await _carte(tester, 'lecture', 'autre');
      await tester.enterText(
        find.byKey(const Key('questionnaire-lecture-autre')),
        'Qalun',
      );
      await _continuer(tester);

      expect(_etape(r), 'memorise-0');
      await _carte(tester, 'memorise', 'quelques_sourates');
      expect(_bulle(tester), t.onboarding.memorise.reponse);
      await _continuer(tester);

      expect(_etape(r), 'detail-0');
      expect(_titre(tester), t.onboarding.detail.titreSourates);
      await _carte(tester, 'sourates', 'fatiha');
      await _carte(tester, 'sourates', 'nas');
      expect(_bulle(tester), t.onboarding.detail.plusieurs(n: 2));
      await _continuer(tester);

      expect(_etape(r), 'objectif-0');
      expect(find.text(t.onboarding.objectif.sousMemo), findsOneWidget);
      // Un enfant a la carte « priere ».
      expect(
        find.byKey(const ValueKey<String>('questionnaire-objectif-priere')),
        findsOneWidget,
      );
      await _continuer(tester);
      expect(_etape(r), 'depart');

      final ApprenantQuestionnaire a = QuestionnaireInscription.depuisTexte(
        lireMemoireAppareil(clefQuestionnaire),
      ).apprenants.single;
      expect(a.lecture, LectureCoran.autre);
      expect(a.lectureAutre, 'Qalun');
      expect(a.sourates, <String>['fatiha', 'nas']);
      expect(a.objectif, ObjectifOnboarding.memoriser);
    });

    testWidgets('« Pour plusieurs enfants » : « Ajouter l enfant suivant », '
        'puis l interlude de la famille', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          commence: true,
          apprendre: true,
          pourQui: PourQui.plusieurs,
          apprenants: <ApprenantQuestionnaire>[
            ApprenantQuestionnaire(
              prenom: 'Yasmine',
              age: 9,
              genre: Genre.femme,
            ),
          ],
        ).versTexte(),
      );
      final GoRouter r = await _monter(
        tester,
        '${Routes.commencer}?etape=famille',
      );
      expect(find.text(t.onboarding.famille.suivant), findsOneWidget);
      expect(_bulle(tester), t.onboarding.famille.ditEncore(prenom: 'Yasmine'));
      await _continuer(tester);
      expect(_etape(r), 'prenom-1');
      expect(_titre(tester), t.onboarding.prenom.titreSuivant);
      await tester.enterText(
        find.byKey(const Key('questionnaire-prenom')),
        'Bilal',
      );
      await _continuer(tester);
      await _carte(tester, 'age', '12');
      await _continuer(tester);
      await _carte(tester, 'genre', 'homme');
      await _continuer(tester);
      expect(_etape(r), 'famille');
      expect(_titre(tester), t.onboarding.famille.titre);
      expect(find.text(t.commun.continuer), findsOneWidget);
      expect(find.text('Yasmine'), findsOneWidget);
      expect(find.text('Bilal'), findsOneWidget);
    });

    testWidgets('revenir du prenom d un eleve ajoute, sans le saisir, le '
        'retire', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          commence: true,
          apprendre: true,
          pourQui: PourQui.unEnfant,
          apprenants: <ApprenantQuestionnaire>[
            ApprenantQuestionnaire(
              prenom: 'Yasmine',
              age: 9,
              genre: Genre.femme,
            ),
          ],
        ).versTexte(),
      );
      final GoRouter r = await _monter(
        tester,
        '${Routes.commencer}?etape=famille',
      );
      await _taper(
        tester,
        find.byKey(const Key('questionnaire-famille-aussi')),
      );
      expect(_etape(r), 'prenom-1');
      expect(_titre(tester), t.onboarding.prenom.titreMoi);
      await _taper(tester, find.byType(DisqueRetour));
      expect(_etape(r), 'famille');
      expect(
        QuestionnaireInscription.depuisTexte(
          lireMemoireAppareil(clefQuestionnaire),
        ).apprenants,
        hasLength(1),
      );
    });

    testWidgets('un prenom en chiffres : Praxis explique, rien n avance', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          commence: true,
          apprendre: true,
          pourQui: PourQui.unEnfant,
          apprenants: <ApprenantQuestionnaire>[ApprenantQuestionnaire()],
        ).versTexte(),
      );
      final GoRouter r = await _monter(
        tester,
        '${Routes.commencer}?etape=prenom-0',
      );
      await tester.enterText(
        find.byKey(const Key('questionnaire-prenom')),
        'Yas2',
      );
      await tester.pump();
      expect(_bulle(tester), t.onboarding.prenom.refus);
      await _continuer(tester);
      expect(_etape(r), 'prenom-0');
      expect(find.text(t.onboarding.prenom.refus), findsWidgets);
    });

    testWidgets('« Continuer » sans reponse n est jamais grise : il le dit', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(commence: true).versTexte(),
      );
      final GoRouter r = await _monter(tester, Routes.commencer);
      expect(_etape(r), 'garde');
      expect(
        tester
            .widget<ActionPrincipale>(
              find.byKey(const Key('questionnaire-continuer')),
            )
            .onPress,
        isNotNull,
      );
      await _continuer(tester);
      expect(
        find.byKey(const Key('questionnaire-reponse-requise')),
        findsOneWidget,
      );
      expect(_etape(r), 'garde');
    });

    testWidgets('18 ans ou plus, moins de 18 ans seul : Praxis oriente', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(
          commence: true,
          apprendre: true,
        ).versTexte(),
      );
      await _monter(tester, '${Routes.commencer}?etape=pourQui');
      await _taper(tester, find.byKey(const Key('questionnaire-mineur')));
      expect(_bulle(tester), t.onboarding.pourQui.mineurReponse);
    });

    // La garde « Enseigner » (directeur, 22/11/2026) : la candidature
    // commence ici, sans invitation ; aucun apprenant, aucun compte eleve.
    testWidgets('« Enseigner » : la candidature sans invitation, par le lien '
        'du candidat, sans rien du questionnaire', (WidgetTester tester) async {
      ecrireMemoireAppareil(
        clefQuestionnaire,
        const QuestionnaireInscription(commence: true).versTexte(),
      );
      final GoRouter r = await _monter(tester, Routes.commencer);
      await _carte(tester, 'garde', 'enseigner');
      expect(_etape(r), 'enseigner');
      expect(_titre(tester), t.onboarding.enseigner.titre);
      expect(
        find.byKey(const ValueKey<String>('onboarding-chapitre')),
        findsNothing,
      );

      // « Je me suis trompe » ramene a la garde.
      await _taper(
        tester,
        find.byKey(const Key('questionnaire-enseigner-trompe')),
      );
      expect(_etape(r), 'garde');
      await _carte(tester, 'garde', 'enseigner');

      await _taper(tester, find.text(t.onboarding.enseigner.commencer));
      expect(r.state.uri.path, Routes.connexion);
      expect(r.state.uri.queryParameters['mode'], parametreModeCreation);
      expect(r.state.uri.queryParameters[parametreCandidature], '1');
      expect(lireInvitationEnCours()?.candidature, isTrue);
      // Aucun apprenant, aucune reponse d'eleve.
      final QuestionnaireInscription q = QuestionnaireInscription.depuisTexte(
        lireMemoireAppareil(clefQuestionnaire),
      );
      expect(q.apprendre, isFalse);
      expect(q.apprenants, isEmpty);
    });

    testWidgets('« J ai deja un compte » mene a la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter r = await _monter(tester, Routes.commencer);
      await _taper(
        tester,
        find.byKey(const Key('questionnaire-deja-un-compte')),
      );
      expect(r.state.uri.path, Routes.connexion);
      expect(r.state.uri.queryParameters['mode'], parametreModeConnexion);
    });

    testWidgets('une adresse ouverte trop tot ramene au premier ecran sans '
        'reponse ; l acces aussi', (WidgetTester tester) async {
      final GoRouter r = await _monter(
        tester,
        '${Routes.commencer}?etape=$codeEtapeAcces',
      );
      expect(find.byKey(EcranAccesQuestionnaire.cle), findsNothing);
      expect(_etape(r), 'accueil');
      r.go('${Routes.commencer}?etape=langue');
      await tester.pumpAndSettle();
      expect(_etape(r), 'accueil');
    });

    testWidgets('ONBOARDING-BOUCLE : session arrivee sans reponses, le '
        'bandeau le dit', (WidgetTester tester) async {
      await _monter(
        tester,
        Routes.commencer,
        enPlus: <Override>[
          reponsesResteesAilleursProvider.overrideWith(
            _ResteesAilleursVrai.new,
          ),
        ],
      );
      expect(
        find.text(t.inscription.questionnaire.acces.absentesTitre),
        findsOneWidget,
      );
    });

    testWidgets('acces : l adresse porte la marque des champs obligatoires, '
        'Google attend pendant la connexion', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      ecrireMemoireAppareil(clefQuestionnaire, _moiComplet.versTexte());
      final _AuthGoogleLente auth = _AuthGoogleLente();
      await _monter(
        tester,
        '${Routes.commencer}?etape=$codeEtapeAcces',
        auth: auth,
      );
      expect(find.byType(PointRappel), findsOneWidget);
      expect(find.text(t.onboarding.acces.indice), findsOneWidget);
      const ValueKey<String> cle = ValueKey<String>(
        'questionnaire-acces-google',
      );
      await tester.ensureVisible(find.byKey(cle));
      await tester.tap(find.byKey(cle));
      await tester.pump();
      expect(tester.widget<ActionPrincipale>(find.byKey(cle)).enCours, isTrue);
      await tester.tap(find.byKey(cle), warnIfMissed: false);
      await tester.pump();
      expect(auth.google, 1);
      auth.reponse.complete();
      await tester.pumpAndSettle();
      semantique.dispose();
    });

    testWidgets('acces : le lien parti, « Regardez votre boite »', (
      WidgetTester tester,
    ) async {
      ecrireMemoireAppareil(clefQuestionnaire, _moiComplet.versTexte());
      await _monter(tester, '${Routes.commencer}?etape=$codeEtapeAcces');
      await tester.enterText(
        find.byKey(const Key('questionnaire-acces-courriel')),
        'famille@exemple.com',
      );
      await tester.pump();
      await _taper(
        tester,
        find.byKey(const ValueKey<String>('questionnaire-acces-envoyer')),
      );
      expect(_titre(tester), t.onboarding.envoye.titre);
      expect(
        find.text(t.onboarding.envoye.ecrit(courriel: 'famille@exemple.com')),
        findsOneWidget,
      );
    });

    // Sur ordinateur, jamais une carte de telephone etiree : deux colonnes
    // bornees (directeur, regle repetee le 21/11/2026).
    for (final Size taille in <Size>[
      const Size(320, 640),
      const Size(1280, 800),
      const Size(1440, 900),
    ]) {
      testWidgets('a ${taille.width.toInt()} : rien ne deborde, la colonne '
          'des reponses est bornee', (WidgetTester tester) async {
        ecrireMemoireAppareil(
          clefQuestionnaire,
          const QuestionnaireInscription(
            commence: true,
            apprendre: true,
          ).versTexte(),
        );
        await _monter(
          tester,
          '${Routes.commencer}?etape=pourQui',
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        final double largeur = tester
            .getSize(
              find.byKey(const ValueKey<String>('questionnaire-pour-qui')),
            )
            .width;
        if (taille.width >= 840) {
          expect(largeur, lessThanOrEqualTo(640));
        } else {
          expect(largeur, lessThanOrEqualTo(taille.width));
        }
        verifierUnSeulBoutonPlein(tester);
      });
    }
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

class _ResteesAilleursVrai extends ReponsesResteesAilleurs {
  @override
  bool build() => true;
}
