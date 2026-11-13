// SUIVI-ATTENTE : les quatre roles sur le VRAI routeur de l'application
// (`app_router.dart`), jamais une page montee seule.
//
// - le tuteur : la carte de son accueil ouvre l'ecran complet (un seul ecran
//   de suivi) et le retour le ramene a l'accueil ;
// - l'eleve adulte : la meme carte sur son accueil, sa propre route ;
// - l'eleve de moins de 10 ans : la carte au tutoiement, sa propre route ;
// - l'enseignant : « Me presenter » depuis Mes classes, et « Ce que les
//   familles voient de vous » depuis son Compte.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/attente_classe/frise_attente.dart';
import 'package:rewayah_academy/features/attente_classe/libelles_attente.dart';
import 'package:rewayah_academy/features/attente_classe/me_presenter_page.dart';
import 'package:rewayah_academy/features/attente_classe/presentation_familles_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/suivi_famille/suivi_famille_page.dart'
    show FriseDemandePage;

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';
import '../../support/attente_donnees.dart';
import '../../support/demo/classe_demo.dart';
import '../../support/demo/demo_classe_page.dart' show surchargesEleveDemo;
import '../../support/harnais.dart';
import '../accueil_adulte/support_accueil_adulte_route.dart';
import '../com_messages/support_messages.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

List<Override> _suivi(List<SuiviAttente> suivis) => <Override>[
  portSuiviAttenteProvider.overrideWithValue(PortSuiviAttenteFaux(suivis)),
];

/// Le vrai routeur, un tuteur dont le foyer a un profil eleve (sans lui,
/// l'accueil propose d'en ajouter un et n'a rien a suivre). `monterRouteur`
/// ne laisse pas passer un second faux de l'appairage.
Future<GoRouter> _monterTuteur(
  WidgetTester tester, {
  required List<Override> surcharges,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()
            ..elevesRendus = const <EleveDuFoyer>[
              EleveDuFoyer(
                id: 'e-d1',
                prenom: 'Yusuf',
                identifiantImmuable: 'RA-26-4817',
                mode: InterfaceMode.enfant,
                camera: CameraPolicy.forbidden,
              ),
            ],
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
  return routeur;
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  group('le tuteur', () {
    testWidgets(
      'la carte de l\'accueil ouvre l\'ecran complet, le retour revient',
      (WidgetTester tester) async {
        final SuiviAttente s = suiviDeTest(delai: delaiDeTest());
        final GoRouter routeur = await _monterTuteur(
          tester,
          surcharges: _suivi(<SuiviAttente>[s]),
        );
        expect(lieu(routeur), Routes.tuteurAccueil);
        expect(_cle('carte-attente-d1'), findsOneWidget);
        expect(find.text(ligneCarte(s)), findsOneWidget);

        await tester.ensureVisible(_cle('carte-attente-voir-d1'));
        await tester.tap(_cle('carte-attente-voir-d1'));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurAttenteDemande('d1'));
        expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
        expect(find.text(t.suiviAttente.titre), findsWidgets);
      },
    );

    testWidgets(
      'les notifications (/tuteur/demandes) ouvrent le suivi quand il n\'y en a qu\'un',
      (WidgetTester tester) async {
        final GoRouter routeur = await _monterTuteur(
          tester,
          surcharges: _suivi(<SuiviAttente>[suiviDeTest(delai: delaiDeTest())]),
        );
        routeur.go(Routes.tuteurDemandes);
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurAttenteDemande('d1'));
        expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
      },
    );

    testWidgets('avec deux suivis, la liste reste la liste de raccourcis', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterTuteur(
        tester,
        surcharges: _suivi(<SuiviAttente>[
          suiviDeTest(id: 'd1'),
          suiviDeTest(id: 'd2', prenom: 'Maryam'),
        ]),
      );
      routeur.go(Routes.tuteurDemandes);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurDemandes);
    });

    testWidgets('un suivi clos : la liste, pas le suivi', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterTuteur(
        tester,
        surcharges: _suivi(<SuiviAttente>[
          suiviDeTest(
            cas: CasAttente.refusee,
            motif: MotifCloture.refusDirection,
          ),
        ]),
      );
      routeur.go(Routes.tuteurDemandes);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.tuteurDemandes);
    });

    testWidgets('l\'adresse du suivi se recharge : la demande se relit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurAttenteDemande('d1'),
        surcharges: _suivi(<SuiviAttente>[suiviToutEstPret()]),
      );
      expect(lieu(routeur), Routes.tuteurAttenteDemande('d1'));
      expect(_cle('attente-carte-enseignant'), findsOneWidget);
    });

    testWidgets(
      'l\'adresse historique d\'une demande ouvre le meme ecran de suivi',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.tuteurDemande('d1'),
          surcharges: _suivi(<SuiviAttente>[suiviDeTest(delai: delaiDeTest())]),
        );
        expect(lieu(routeur), Routes.tuteurDemande('d1'));
        expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
        expect(find.byType(FriseDemandePage), findsNothing);
      },
    );

    testWidgets(
      'sans port : l\'ancienne frise reste le detail (production avant branchement)',
      (WidgetTester tester) async {
        await monterRouteur(tester, Routes.tuteurDemande('d1'));
        expect(find.byType(FriseDemandePage), findsOneWidget);
        expect(find.byKey(FriseAttente.cleEtape(5)), findsNothing);
      },
    );

    testWidgets('une demande inconnue : on le dit, jamais un suivi devine', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.tuteurAttenteDemande('inconnue'),
        surcharges: _suivi(<SuiviAttente>[suiviDeTest()]),
      );
      expect(find.text(t.suiviAttente.introuvable), findsOneWidget);
    });

    testWidgets(
      'sans port (production avant branchement) : l\'accueil est inchange',
      (WidgetTester tester) async {
        await monterRouteur(tester, Routes.tuteurAccueil);
        expect(_cle('carte-attente'), findsNothing);
        expect(_cle('carte-attente-erreur'), findsNothing);
      },
    );
  });

  group('l\'eleve adulte', () {
    testWidgets('la carte de son accueil ouvre sa propre route', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: <Override>[
          ...surchargesAccueilAdulte(),
          ..._suivi(<SuiviAttente>[suiviDeTest(typePublic: 'adulte')]),
        ],
        depart: Routes.eleve,
      );
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byKey(AccueilAdultePage.financesKey), findsOneWidget);
      expect(_cle('carte-attente-d1'), findsOneWidget);
      await tester.ensureVisible(_cle('carte-attente-voir-d1'));
      await tester.tap(_cle('carte-attente-voir-d1'));
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAdulteAttenteDemande('d1'));
      expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
    });
  });

  group('l\'eleve adulte et l\'adresse des notifications (/tuteur/demandes)', () {
    // L'ancien chemin des demandes (tc_notification_etape_adulte_autonome) ecrit
    // pour un adulte une notification dont la destination est
    // `/tuteur/demandes` (contrainte du serveur) : ce lien doit mener l'adulte
    // a SON ecran de suivi.
    testWidgets('mene l\'adulte a son propre suivi', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: <Override>[
          ...surchargesAccueilAdulte(),
          ..._suivi(<SuiviAttente>[suiviDeTest(typePublic: 'adulte')]),
        ],
        depart: Routes.tuteurDemandes,
      );
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAdulteAttenteDemande('d1'));
      expect(find.byKey(FriseAttente.cleEtape(5)), findsOneWidget);
      // Les mots de l'adulte, jamais ceux d'un enfant.
      expect(find.text(t.suiviAttente.titre), findsWidgets);
    });
  });

  group('l\'eleve de moins de 10 ans', () {
    testWidgets(
      'la carte au tutoiement ouvre sa propre route, version simple',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.eleve,
          source: FausseSourceSession(sessionActive(AppRole.student)),
          surcharges: <Override>[
            ...surchargesEleveDemo(EtatDemoClasse.aVenir),
            ..._suivi(<SuiviAttente>[
              suiviDeTest(versionSimple: true, delai: delaiDeTest()),
            ]),
          ],
        );
        expect(lieu(routeur), Routes.eleve);
        expect(_cle('carte-attente-d1'), findsOneWidget);
        expect(find.text(t.suiviAttente.carte.titreSimple), findsOneWidget);
        await tester.ensureVisible(_cle('carte-attente-voir-d1'));
        await tester.tap(_cle('carte-attente-voir-d1'));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.eleveAttenteDemande('d1'));
        expect(find.text(t.suiviAttente.titreSimple), findsOneWidget);
        expect(_cle('attente-delai-0'), findsNothing);
      },
    );
  });

  group('l\'enseignant', () {
    final SessionState session = sessionActive(AppRole.teacher);

    GroupeEnseignant classe() => GroupeEnseignant(
      id: 'g1',
      libelle: 'Classe Al-Fatiha',
      type: TypePublicGroupe.enfant,
      seuilMax: 5,
      creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
      nbMembres: 3,
      creeLe: DateTime.now(),
    );

    List<Override> surcharges(FauxMessagesMetier messages) => <Override>[
      groupesEnseignantProvider.overrideWith(
        (Ref _) async => <GroupeEnseignant>[classe()],
      ),
      profilEnseignantProvider.overrideWith(
        (Ref _) async => const ProfilEnseignant(
          prenom: 'Ibrahim',
          identifiant: 'RA-ENS-1',
          titre: 'sayyid',
        ),
      ),
      portMessagesMetierProvider.overrideWithValue(messages),
      portPresentationEnseignantProvider.overrideWithValue(
        _PortPresentationFixe(),
      ),
    ];

    FauxMessagesMetier messages() {
      final ConversationPossible c = ConversationPossible(
        interlocuteur: const Participant(id: 'f1', nomAffiche: 'Famille'),
        nature: NatureInterlocuteur.famille,
        objet: ObjetLie(
          type: TypeObjetLie.classe,
          id: 'g1',
          libelle: 'Classe Al-Fatiha',
        ),
      );
      return FauxMessagesMetier(
        fils: <FilMetier>[filSimple(id: 'fil-1')],
        conversations: <String, List<ConversationPossible>>{
          cleObjet(TypeObjetLie.classe, 'g1'): <ConversationPossible>[c],
        },
        filsParConversation: <String, String>{c.cle: 'fil-1'},
      );
    }

    testWidgets('Mes classes : « Me presenter » ouvre l\'ecran et envoie', (
      WidgetTester tester,
    ) async {
      final FauxMessagesMetier port = messages();
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.enseignantClasses,
        source: FausseSourceSession(session),
        surcharges: surcharges(port),
      );
      expect(lieu(routeur), Routes.enseignantClasses);
      expect(_cle('presenter-ligne-g1'), findsOneWidget);
      await tester.ensureVisible(_cle('presenter-ligne-g1'));
      await tester.tap(_cle('presenter-ligne-g1'));
      await stabiliser(tester);
      expect(
        routeur.state.matchedLocation,
        Routes.enseignantPresentationClasse('g1'),
      );
      expect(find.byType(MePresenterPage), findsOneWidget);
      await tester.tap(_cle('presenter-envoyer'));
      await stabiliser(tester);
      expect(port.envois, hasLength(1));
      expect(
        find.text(t.suiviAttente.mePresenter.envoye(n: 1)),
        findsOneWidget,
      );
    });

    testWidgets(
      'son Compte : la ligne ouvre « Ce que les familles voient de vous »',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.enseignantProfil,
          source: FausseSourceSession(session),
          surcharges: surcharges(messages()),
        );
        expect(lieu(routeur), Routes.enseignantProfil);
        final Finder ligne = find.byKey(ProfilEnseignantPage.presentationKey);
        expect(ligne, findsOneWidget);
        await tester.ensureVisible(ligne);
        await tester.tap(ligne);
        await stabiliser(tester);
        expect(
          routeur.state.matchedLocation,
          Routes.enseignantPresentationFamilles,
        );
        expect(find.byType(PresentationFamillesPage), findsOneWidget);
      },
    );
  });
}

class _PortPresentationFixe implements PortPresentationEnseignant {
  @override
  Future<PresentationAuxFamilles> lire() async =>
      const PresentationAuxFamilles(montre: false, confirme: false);

  @override
  Future<void> regler({
    required bool montre,
    String? paysOrigine,
    String? paysResidence,
    String? mot,
  }) async {}
}
