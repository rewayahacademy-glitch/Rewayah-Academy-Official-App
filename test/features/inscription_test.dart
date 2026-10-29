import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart'
    show languesCoursProvider;
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart'
    show UsageInscription;
import 'package:rewayah_academy/features/inscription/code_comptable_retenu.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/langue_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/recapitulatif_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart';

import '../support/harnais.dart';

/// Admission, lot B : le questionnaire deja repondu avant le compte.
class _QuestionnaireRepondu extends QuestionnaireControleur {
  _QuestionnaireRepondu(this._q);
  final QuestionnaireInscription _q;
  @override
  QuestionnaireInscription build() => _q;
}

/// « Pour moi », toutes les questions repondues.
const QuestionnaireInscription _qMoi = QuestionnaireInscription(
  usage: UsageInscription.moi,
  niveauTitulaire: NiveauDeclare.lectureLente,
  objectif: ObjectifApprentissage.memoriser,
  moments: <MomentJournee>{MomentJournee.soir},
);

/// « Mon enfant », un enfant, et le parent qui suit ou non des cours.
QuestionnaireInscription _qFamille({required bool parent}) =>
    QuestionnaireInscription(
      usage: UsageInscription.famille,
      enfants: const <EnfantQuestionnaire>[
        EnfantQuestionnaire(
          prenom: 'Yasmine',
          age: 9,
          genre: Genre.femme,
          niveau: NiveauDeclare.debutLettres,
        ),
      ],
      parentSuitDesCours: parent,
      niveauTitulaire: parent ? NiveauDeclare.lectureCourante : null,
      objectif: ObjectifApprentissage.apprendreALire,
      moments: const <MomentJournee>{MomentJournee.matin},
    );

/// Une source dont le rafraichissement echoue tant qu'on le demande.
class _SourceCapricieuse extends FausseSourceSession {
  bool echoue = true;

  @override
  Future<void> rafraichir() async {
    rafraichissements++;
    if (echoue) {
      throw StateError('jeton');
    }
  }
}

/// Un dossier dont la creation reste en attente jusqu'a ce qu'on la libere,
/// pour surprendre un second appui pendant que le premier est encore en vol.
class _DossierLent extends FauxServiceDossier {
  final Completer<void> _porte = Completer<void>();

  void libere() => _porte.complete();

  @override
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
    String? codeInvitation,
    UsageTitulaire? usage,
    bool suitDesCours = false,
    List<Map<String, Object?>>? apprenants,
  }) async {
    await _porte.future;
    await super.creerProfil(
      role: role,
      prenom: prenom,
      nom: nom,
      genre: genre,
      codeInvitation: codeInvitation,
      usage: usage,
      suitDesCours: suitDesCours,
    );
  }
}

/// Monte le parcours sur un routeur minimal portant les cinq routes du lot
/// et une page d'arrivee `/attente`. Mesure sur 390 x 844.
Future<(FauxServiceDossier, FausseSourceSession)> _monter(
  WidgetTester tester, {
  FausseSourceSession? source,
  FauxServiceDossier? dossierFourni,
  FauxServiceAuth? auth,
  String? codeRetenu,
  PortVerificationInvitation? verificationComptable,
  PortInscriptionComptable? inscriptionComptable,
  String? codeComptable,
  QuestionnaireInscription questionnaire = const QuestionnaireInscription(),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final FauxServiceDossier dossier = dossierFourni ?? FauxServiceDossier();
  final FausseSourceSession session = source ?? FausseSourceSession();

  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.inscription,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.inscription,
          builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
        ),
        GoRoute(
          path: Routes.inscriptionUsage,
          builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionLangue,
          builder: (BuildContext _, GoRouterState _) => const LangueEtape(),
        ),
        GoRoute(
          path: Routes.commencer,
          builder: (BuildContext _, GoRouterState etat) =>
              QuestionnairePage(code: etat.uri.queryParameters['etape']),
        ),
        GoRoute(
          path: Routes.inscriptionIdentite,
          builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionGenre,
          builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionRecapitulatif,
          builder: (BuildContext _, GoRouterState _) =>
              const RecapitulatifEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionInvitation,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('CODE-INVITATION')),
        ),
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ATTENTE')),
        ),
        GoRoute(
          path: Routes.inscriptionInvitationComptable,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('CODE-COMPTABLE')),
        ),
        GoRoute(
          path: Routes.comptable,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ESPACE-COMPTABLE')),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
        sourceSessionProvider.overrideWithValue(session),
        serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
        baseLocaleEnMemoire(),
        questionnaireInscriptionProvider.overrideWith(
          () => _QuestionnaireRepondu(questionnaire),
        ),
        languesCoursProvider.overrideWith(
          (_) async => const <LangueCours>[
            LangueCours(code: 'francais', nom: 'Français'),
          ],
        ),
        if (codeRetenu != null)
          codeInvitationRetenuProvider.overrideWith(
            () => _CodeDejaRetenu(codeRetenu),
          ),
        portVerificationInvitationComptableProvider.overrideWithValue(
          verificationComptable,
        ),
        portInscriptionComptableProvider.overrideWithValue(
          inscriptionComptable,
        ),
        if (codeComptable != null)
          codeComptableRetenuProvider.overrideWith(
            () => _CodeDejaRetenu(codeComptable),
          ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (dossier, session);
}

/// Un code d'invitation deja verifie et retenu (RECRUT-ECRANS, C-14).
class _CodeDejaRetenu extends CodeInvitationRetenu {
  _CodeDejaRetenu(this._code);
  final String _code;
  @override
  String? build() => _code;
}

/// Une inscription de comptable qui note ses appels (lot F2).
class _InscriptionComptable implements PortInscriptionComptable {
  _InscriptionComptable([
    this.resultat = ResultatInscriptionComptable.consommee,
  ]);
  final ResultatInscriptionComptable resultat;
  final List<Map<String, String?>> appels = <Map<String, String?>>[];

  @override
  Future<ResultatInscriptionComptable> inscrire({
    required String code,
    required String prenom,
    required String nom,
    String? genre,
  }) async {
    appels.add(<String, String?>{
      'code': code,
      'prenom': prenom,
      'nom': nom,
      'genre': genre,
    });
    return resultat;
  }
}

/// Le parcours comptable jusqu'a la creation.
Future<void> _comptableJusquALaCreation(WidgetTester tester) async {
  await _taper(tester, find.byKey(const Key('inscription-lien-comptable')));
  await tester.enterText(find.byKey(const Key('inscription-prenom')), 'Sara');
  await tester.enterText(find.byKey(const Key('inscription-nom')), 'Kane');
  await _continuer(tester);
  await _taper(tester, find.text(t.inscription.genreFemme));
  await _continuer(tester);
  expect(find.text(t.inscription.recap.comptable), findsOneWidget);
  await _taper(tester, find.text(t.inscription.creer));
}

/// Le parcours enseignant jusqu'au recapitulatif.
Future<void> _enseignantJusquAuRecap(WidgetTester tester) async {
  await _taper(tester, find.byKey(const Key('inscription-lien-enseignant')));
  await tester.enterText(find.byKey(const Key('inscription-prenom')), 'Ali');
  await tester.enterText(find.byKey(const Key('inscription-nom')), 'Bah');
  await _continuer(tester);
  await _taper(tester, find.text(t.inscription.genreHomme));
  await _continuer(tester);
}

/// Le parcours enseignant jusqu'a la creation.
Future<void> _enseignantJusquALaCreation(WidgetTester tester) async {
  await _enseignantJusquAuRecap(tester);
  await _taper(tester, find.text(t.inscription.creer));
}

/// Le CTA en pilule de la page courante.
ActionPrincipale _cta(WidgetTester tester) => tester
    .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
    .firstWhere((ActionPrincipale a) => a.pilule);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _continuer(WidgetTester tester) =>
    _taper(tester, find.text(t.commun.continuer));

/// Le titulaire, questionnaire repondu, de la langue au recapitulatif.
Future<void> _jusquAuRecap(WidgetTester tester) async {
  expect(find.text('1 sur 4'), findsOneWidget);
  await _taper(tester, find.text('Français'));
  await _continuer(tester);
  await tester.enterText(find.byKey(const Key('inscription-prenom')), 'Amina');
  await tester.enterText(find.byKey(const Key('inscription-nom')), 'Diallo');
  await _continuer(tester);
  // Demande du directeur (25/09) : symbole femme et symbole homme, plus la
  // silhouette neutre du profil.
  expect(find.byIcon(AppIcons.femme.repos), findsOneWidget);
  expect(find.byIcon(AppIcons.homme.repos), findsOneWidget);
  expect(find.byIcon(AppIcons.profil.repos), findsNothing);
  await _taper(tester, find.text(t.inscription.genreFemme));
  await _continuer(tester);
}

void main() {
  group('LA-2 : inscription par etapes', () {
    testWidgets('usage : deux cartes aux textes du mandat, sans « Autre », '
        'sans preselection', (WidgetTester tester) async {
      await _monter(tester);

      expect(find.text(t.inscription.usage.question), findsOneWidget);
      // Admission, lot B (directeur, 29/10/2026) : les deux choix du mandat.
      expect(find.text('Je m\'inscris pour moi'), findsOneWidget);
      expect(
        find.text(
          'Vous suivez les cours vous-même. Votre profil élève est créé avec '
          'votre compte.',
        ),
        findsOneWidget,
      );
      expect(find.text('J\'inscris mon enfant'), findsOneWidget);
      // Le texte est pose sans coupure de mots (espaces insecables) : on le
      // cherche par sa clef.
      expect(
        find.textContaining(
          t.inscription.usage.familleDescription.substring(0, 40),
        ),
        findsOneWidget,
      );
      // La disposition (deux choix egaux) : inscription_choix_egaux_test.dart.
      expect(find.text('J\'ai un code d\'invitation'), findsOneWidget);
      expect(
        find.text(
          'Vous êtes enseignant\u00a0? L\'académie vous invite par courriel.',
        ),
        findsOneWidget,
      );
      expect(find.text('Je suis enseignant'), findsNothing);
      expect(find.text('Autre'), findsNothing);
      expect(find.text('1 sur 4'), findsOneWidget);
      expect(_cta(tester).onPress, isNull);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
    });

    testWidgets('le parcours complet cree le profil et part vers /attente', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, FausseSourceSession source) =
          await _monter(tester, questionnaire: _qMoi);
      await _jusquAuRecap(tester);

      expect(find.text('4 sur 4'), findsOneWidget);
      expect(find.text('Amina Diallo'), findsOneWidget);
      expect(find.text(t.inscription.questionnaire.recapTitre), findsOneWidget);
      // Usage, vous, langue, identite, genre.
      expect(find.text(t.inscription.modifier), findsNWidgets(5));

      await _taper(tester, find.text(t.inscription.questionnaire.envoyer));

      expect(dossier.profilsCrees, hasLength(1));
      expect(dossier.profilsCrees.single.role, AppRole.guardian);
      expect(dossier.profilsCrees.single.genre, Genre.femme);
      // L5-01 : « Moi » part avec le profil, et ouvre la fiche d'eleve.
      expect(dossier.usages.single.usage, UsageTitulaire.moi);
      expect(dossier.usages.single.suitDesCours, isTrue);
      // Admission, lot B : l'apprenant du questionnaire part avec la demande.
      expect(dossier.apprenantsEnvoyes.single, <Map<String, Object?>>[
        <String, Object?>{
          'est_titulaire': true,
          'niveau': 'lecture_lente',
          'objectif': 'memoriser',
          'moments': <String>['soir'],
          'langue': 'francais',
        },
      ]);
      expect(source.rafraichissements, 1);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('le lien enseignant sans code ouvre le champ du code', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(tester);
      await _taper(
        tester,
        find.byKey(const Key('inscription-lien-enseignant')),
      );
      expect(find.text('CODE-INVITATION'), findsOneWidget);
      expect(dossier.profilsCrees, isEmpty);
    });

    test('libelles de la fiche L1-11 en arabe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      expect(
        t.inscription.usage.enseignantInvite,
        'هل أنت معلّم؟ تدعوك الأكاديمية عبر البريد الإلكتروني.',
      );
      expect(t.inscription.usage.enseignant, 'لدي رمز دعوة');
    });

    // RACCORDEMENT-1016 (D) : le code verifie part avec la creation du
    // profil enseignant, et un refus du serveur se dit sans avancer.
    testWidgets('le code d invitation retenu part avec le profil enseignant', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        codeRetenu: 'ABCD-EFGH-JKMN',
      );
      await _enseignantJusquALaCreation(tester);
      expect(dossier.profilsCrees.single.role, AppRole.teacher);
      expect(dossier.codesInvitation.single, 'ABCD-EFGH-JKMN');
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('profil enseignant sans code : aucun appel, retour au code', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        codeRetenu: 'ABCD-EFGH-JKMN',
      );
      await _enseignantJusquAuRecap(tester);
      // Le code est perdu entre-temps : le recapitulatif ne tente rien.
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(RecapitulatifEtape)),
      );
      conteneur.read(codeInvitationRetenuProvider.notifier).oublier();
      await _taper(tester, find.text(t.inscription.creer));
      expect(dossier.profilsCrees, isEmpty);
      expect(find.text('CODE-INVITATION'), findsOneWidget);
    });

    testWidgets('code refuse par le serveur : message K-59, aucune avance', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        codeRetenu: 'ABCD-EFGH-JKMN',
      );
      dossier.erreurAJeter = const InvitationNonConsommee('expiree');
      await _enseignantJusquALaCreation(tester);
      expect(find.text(t.inscription.erreurInvitation), findsOneWidget);
      expect(find.text('ATTENTE'), findsNothing);
      expect(find.text('4 sur 4'), findsOneWidget);
    });

    // Lot F2 : le comptable invite, par son propre code et sa propre RPC.
    testWidgets('sans verification servie, aucun lien comptable', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.byKey(const Key('inscription-lien-comptable')), findsNothing);
    });

    testWidgets('le lien comptable sans code ouvre le champ du code', (
      WidgetTester tester,
    ) async {
      await _monter(tester, verificationComptable: InvitationsDemo());
      await _taper(tester, find.byKey(const Key('inscription-lien-comptable')));
      expect(find.text('CODE-COMPTABLE'), findsOneWidget);
    });

    testWidgets(
      'le code comptable retenu inscrit le comptable, puis /comptable',
      (WidgetTester tester) async {
        final _InscriptionComptable port = _InscriptionComptable();
        final (
          FauxServiceDossier dossier,
          FausseSourceSession source,
        ) = await _monter(
          tester,
          verificationComptable: InvitationsDemo(),
          inscriptionComptable: port,
          codeComptable: 'CPTA-0001',
        );
        await _comptableJusquALaCreation(tester);
        expect(dossier.profilsCrees, isEmpty);
        expect(port.appels.single, <String, String?>{
          'code': 'CPTA-0001',
          'prenom': 'Sara',
          'nom': 'Kane',
          'genre': 'female',
        });
        expect(source.rafraichissements, 1);
        expect(find.text('ESPACE-COMPTABLE'), findsOneWidget);
      },
    );

    testWidgets('code comptable refuse : message K-59, aucune avance', (
      WidgetTester tester,
    ) async {
      final _InscriptionComptable port = _InscriptionComptable(
        ResultatInscriptionComptable.expiree,
      );
      await _monter(
        tester,
        verificationComptable: InvitationsDemo(),
        inscriptionComptable: port,
        codeComptable: 'CPTA-0001',
      );
      await _comptableJusquALaCreation(tester);
      expect(find.text(t.inscription.erreurInvitation), findsOneWidget);
      expect(find.text('ESPACE-COMPTABLE'), findsNothing);
      expect(find.text('4 sur 4'), findsOneWidget);
    });

    test('libelles du comptable en arabe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      expect(t.inscription.usage.comptable, 'لدي رمز محاسب');
      expect(t.inscription.recap.comptable, 'محاسب');
      expect(t.ficheEleve.mouvements.nature.remboursement, 'استرداد');
    });

    testWidgets('« J\'inscris mon enfant » apres la connexion, sans '
        'questionnaire : les questions s ouvrent', (WidgetTester tester) async {
      await _monter(tester);
      await _taper(tester, find.text(t.inscription.usage.familleTitre));
      await _continuer(tester);
      expect(find.byType(QuestionnairePage), findsOneWidget);
      expect(
        find.text(t.inscription.questionnaire.prenomQuestion),
        findsOneWidget,
      );
    });

    for (final bool suit in <bool>[true, false]) {
      testWidgets('L5-01 : « Famille », cours $suit : la reponse et l enfant '
          'sont montres au recapitulatif et partent avec la demande', (
        WidgetTester tester,
      ) async {
        final (FauxServiceDossier dossier, _) = await _monter(
          tester,
          questionnaire: _qFamille(parent: suit),
        );
        await _taper(tester, find.text('Français'));
        await _continuer(tester);
        await tester.enterText(
          find.byKey(const Key('inscription-prenom')),
          'Karim',
        );
        await tester.enterText(find.byKey(const Key('inscription-nom')), 'Bah');
        await _continuer(tester);
        await _taper(tester, find.text(t.inscription.genreHomme));
        await _continuer(tester);
        expect(
          find.text(
            suit ? t.inscription.recap.coursOui : t.inscription.recap.coursNon,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            t.inscription.questionnaire.ligneEnfant(prenom: 'Yasmine', age: 9),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('inscription-ajouter-profil')),
          findsOneWidget,
        );
        await _taper(tester, find.text(t.inscription.questionnaire.envoyer));
        expect(dossier.usages.single.usage, UsageTitulaire.famille);
        expect(dossier.usages.single.suitDesCours, suit);
        final List<Map<String, Object?>> apprenants =
            dossier.apprenantsEnvoyes.single!;
        expect(apprenants, hasLength(suit ? 2 : 1));
        expect(apprenants.first, <String, Object?>{
          'prenom': 'Yasmine',
          'age': 9,
          'genre': 'female',
          'niveau': 'debut_lettres',
          'objectif': 'apprendre_a_lire',
          'moments': <String>['matin'],
          'langue': 'francais',
        });
        if (suit) {
          expect(apprenants.last['est_titulaire'], isTrue);
        }
      });
    }

    testWidgets('identite : les erreurs se disent sous les champs', (
      WidgetTester tester,
    ) async {
      await _monter(tester, questionnaire: _qMoi);
      await _taper(tester, find.text('Français'));
      await _continuer(tester);
      await _continuer(tester);
      expect(find.text(t.inscription.champRequis), findsNWidgets(2));
      expect(find.text('2 sur 4'), findsOneWidget);
    });

    testWidgets('retour 48 dp et « Modifier » ramenent au bon endroit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, questionnaire: _qMoi);
      await _jusquAuRecap(tester);

      await _taper(
        tester,
        find.byKey(const Key('inscription-modifier-identite')),
      );
      expect(find.text('2 sur 4'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inscription-prenom')),
        'Awa',
      );
      await _continuer(tester);
      expect(find.text('4 sur 4'), findsOneWidget);
      expect(find.text('Awa Diallo'), findsOneWidget);

      await _taper(tester, find.byType(DisqueRetour));
      expect(find.text('3 sur 4'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DisqueRetour)).width,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('actualisation en echec : aucune impasse, aucun doublon', (
      WidgetTester tester,
    ) async {
      final _SourceCapricieuse source = _SourceCapricieuse();
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        source: source,
        questionnaire: _qMoi,
      );
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.questionnaire.envoyer));

      expect(find.text(t.inscription.erreurActualisation), findsOneWidget);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);

      source.echoue = false;
      await _taper(tester, find.text(t.inscription.reessayer));
      expect(dossier.profilsCrees, hasLength(1));
      expect(source.rafraichissements, 2);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('un echec de creation se dit, et ne fait pas avancer', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _) = await _monter(
        tester,
        questionnaire: _qMoi,
      );
      dossier.erreurAJeter = StateError('reseau');
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.questionnaire.envoyer));
      expect(find.text(t.inscription.erreur), findsOneWidget);
      expect(find.text('4 sur 4'), findsOneWidget);
    });

    testWidgets('double soumission bloquee : un second appui pendant '
        'l-envoi ne cree pas de second profil', (WidgetTester tester) async {
      final _DossierLent dossier = _DossierLent();
      final (_, FausseSourceSession source) = await _monter(
        tester,
        dossierFourni: dossier,
        questionnaire: _qMoi,
      );
      await _jusquAuRecap(tester);

      final Finder cta = find.text(t.inscription.questionnaire.envoyer);
      await tester.tap(cta);
      await tester.pump();
      // Le premier envoi est toujours en vol (la porte n'est pas liberee) :
      // le CTA doit deja etre desactive, et un second appui ne rien faire.
      expect(_cta(tester).onPress, isNull);
      await tester.tap(cta, warnIfMissed: false);
      await tester.pump();

      dossier.libere();
      await tester.pumpAndSettle();

      expect(dossier.profilsCrees, hasLength(1));
      expect(source.rafraichissements, 1);
      expect(find.text('ATTENTE'), findsOneWidget);
    });

    testWidgets('le « Modifier » de l-usage et du genre ramenent au bon '
        'endroit', (WidgetTester tester) async {
      await _monter(tester, questionnaire: _qMoi);
      await _jusquAuRecap(tester);

      await _taper(tester, find.byKey(const Key('inscription-modifier-genre')));
      expect(find.text('3 sur 4'), findsOneWidget);
      await _taper(tester, find.text(t.inscription.genreHomme));
      await _continuer(tester);
      expect(find.text('4 sur 4'), findsOneWidget);

      // Admission, lot B : « Pour qui » se modifie dans le questionnaire.
      await _taper(tester, find.byKey(const Key('inscription-modifier-usage')));
      expect(find.byType(QuestionnairePage), findsOneWidget);
      expect(find.text(t.inscription.usage.question), findsOneWidget);
    });

    testWidgets('une fois le profil cree, « Modifier » et le retour '
        'disparaissent : aucune impasse mais aucun doublon', (
      WidgetTester tester,
    ) async {
      final _SourceCapricieuse source = _SourceCapricieuse();
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(tester, source: source, auth: auth, questionnaire: _qMoi);
      await _jusquAuRecap(tester);
      await _taper(tester, find.text(t.inscription.questionnaire.envoyer));

      expect(find.text(t.inscription.erreurActualisation), findsOneWidget);
      // Jamais grise (BOUTONS-GRISES-1) : « Modifier » n'est plus rendu.
      for (final String cle in <String>[
        'inscription-modifier-usage',
        'inscription-modifier-identite',
        'inscription-modifier-genre',
      ]) {
        expect(find.byKey(Key(cle)), findsNothing);
      }
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
      // Plus d'etape precedente : la rangee reste, sans disque (demande
      // A-5.1) ; la seule sortie est « Se deconnecter », sans doublon.
      expect(find.byType(DisqueRetour), findsNothing);
      await _taper(tester, find.byKey(const Key('inscription-deconnexion')));
      expect(auth.deconnexions, 1);
      expect(find.text('3 sur 4'), findsNothing);
    });

    testWidgets('la premiere etape n a pas de disque retour, la rangee reste '
        '(A-5.1)', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.byType(DisqueRetour), findsNothing);
      expect(find.text('1 sur 4'), findsOneWidget);
      expect(find.byKey(const Key('inscription-deconnexion')), findsOneWidget);
    });
  });
}
