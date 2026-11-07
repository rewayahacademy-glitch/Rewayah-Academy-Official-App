// Le Foyer du tuteur (lot B, sous-paquet 1), sur le VRAI routeur.
//
// Chaque parcours part de la navigation et TOUCHE les boutons (onglet Foyer,
// ligne d'un membre, « Ajouter un profil eleve », « Appareils du foyer »,
// « Creer mon profil eleve », disque retour) : un `routeur.go` seul ne
// prouve pas qu'un ecran est atteignable (registre, section 5 bis).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/appareils/ajouter_enfant_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart'
    show CarteIdentiteCompte;
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_second_adulte.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/foyer/role_foyer.dart';
import 'package:rewayah_academy/features/foyer/routes_n2_foyer_adulte.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../../fixtures/tuteur/faux_capacites.dart';
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../parcours/faux_service_offres.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';

/// L'instant fixe des tests : le 24 septembre 2026 a midi.
final DateTime _maintenant = DateTime(2026, 9, 24, 12);

/// Un service d'appairage dont la lecture des eleves se pilote.
class _AppairagePilote extends FauxServiceAppairage {
  /// Vrai pour faire echouer la prochaine lecture des eleves.
  bool echoue = false;

  /// Si non nul, la lecture ne rend la main qu'a la fin de ce futur.
  Completer<void>? attente;

  /// Le nombre de lectures des eleves.
  int lectures = 0;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    lectures++;
    final Completer<void>? a = attente;
    if (a != null) {
      await a.future;
    }
    if (echoue) {
      throw Exception('lecture refusee');
    }
    return elevesRendus;
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required ServiceAppairage appairage,
  String depart = Routes.tuteurAccueil,
  List<Override> autres = const <Override>[],
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        ...autres,
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
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche l'onglet Foyer de la barre basse (telephone).
Future<void> _ouvrirFoyerParLaBarre(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.foyer),
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

List<String> _textesVisibles(WidgetTester tester) => <String>[
  for (final Text texte in tester.widgetList<Text>(find.byType(Text)))
    if (texte.data != null) texte.data!,
];

_AppairagePilote _foyerA() =>
    _AppairagePilote()..elevesRendus = FoyersFictifs.foyerA;

/// Un port des classes dont la lecture echoue tant que [echoue] est vrai
/// (service present : ce n'est pas `CapaciteIndisponible`).
class _ClassesEnEchec extends FauxClassesFoyer {
  _ClassesEnEchec({super.classes});

  bool echoue = true;
  int lectures = 0;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    lectures++;
    if (echoue) {
      throw Exception('lecture des classes refusee');
    }
    return super.classesDe(eleveId);
  }
}

void main() {
  group('Foyer : atteint depuis la navigation', () {
    testWidgets('l onglet Foyer ouvre le Foyer, membres tries par prenom', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFoyerParLaBarre(tester);

      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(find.text(t.foyer.titre), findsWidgets);
      expect(find.text(t.foyer.membres), findsOneWidget);

      // Le foyer fictif arrive dans l'ordre inverse : l'ecran les range par
      // prenom (A1 avant A2), sans dependre de l'ordre de la vue.
      final double yA1 = tester.getTopLeft(find.text('Élève A1')).dy;
      final double yA2 = tester.getTopLeft(find.text('Élève A2')).dy;
      expect(yA1, lessThan(yA2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('toucher un membre ouvre sa fiche, onglet Foyer actif', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFoyerParLaBarre(tester);

      await _toucher(tester, find.text('Élève A1'));

      expect(lieu(routeur), Routes.ficheElevePour(FoyersFictifs.a1.id));
      expect(find.byType(FicheElevePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Ajouter un profil eleve » ouvre le formulaire d ajout', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFoyerParLaBarre(tester);

      await _toucher(tester, find.byKey(FoyerPage.ajouterKey));

      expect(lieu(routeur), Routes.tuteurAjouterEnfant);
      expect(find.byType(AjouterEnfantPage), findsOneWidget);
    });

    testWidgets('« Appareils du foyer » ouvre l ecran des appareils', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, appairage: _foyerA());
      await _ouvrirFoyerParLaBarre(tester);

      await _toucher(tester, find.text(t.foyer.appareilsFoyer));

      expect(lieu(routeur), Routes.tuteurFoyerAppareils);
      expect(find.byType(AppareilsPage), findsOneWidget);
    });

    testWidgets(
      '« Creer mon profil eleve » (N2, FA5 ; PROFIL-TITULAIRE 07/11) : la '
      'confirmation cree le profil, puis ouvre directement le parcours de ce '
      'profil, sans question d age (adulte, tranche connue du serveur)',
      (WidgetTester tester) async {
        final FauxProfilEleveTitulaire port = FauxProfilEleveTitulaire();
        final GoRouter routeur = await _monter(
          tester,
          appairage: _foyerA(),
          autres: <Override>[
            portProfilEleveTitulaireProvider.overrideWithValue(port),
          ],
        );
        // Le serveur pose la tranche adulte a la creation (0052) : le
        // parcours la lit dans `v_parcours_onboarding`.
        (ProviderScope.containerOf(
              tester.element(find.byType(MaterialApp)),
            ).read(serviceOffresProvider) as FauxServiceOffres).parcoursRendu =
            <ParcoursApprenant>[
              const ParcoursApprenant(
                eleveId: 'p-guardian',
                prenom: 'Dyna',
                diagnostic: StatutDiagnostic.nonRequis,
                cohorteCode: 'adulte_18_plus',
                cohorteNom: '18 ans et plus',
              ),
            ];
        await _ouvrirFoyerParLaBarre(tester);

        await _toucher(tester, find.byKey(FoyerPage.monProfilKey));

        expect(lieu(routeur), Routes.tuteurAjouterPourMoi);
        expect(find.byType(CreerMonProfilPage), findsOneWidget);
        expect(find.text(t.foyer.monProfil.intro), findsOneWidget);
        expect(find.text(t.foyer.monProfil.consequence), findsOneWidget);
        // Aucun code technique a l'ecran.
        expect(find.textContaining('DB-FOY'), findsNothing);

        await _toucher(tester, find.byKey(CreerMonProfilPage.creerKey));

        expect(port.present, isTrue);
        // Directement au parcours du profil cree (identifiant du titulaire).
        expect(lieu(routeur), Routes.parcoursPour('p-guardian'));
        expect(find.byType(ParcoursOffresPage), findsOneWidget);
        // Aucune question d'age : la premiere question est la langue.
        expect(find.byKey(ParcoursOffresPage.ageKey), findsNothing);
        expect(find.text(t.parcours.langueQuestion), findsOneWidget);
      },
    );

    testWidgets('PROFIL-TITULAIRE : le profil eleve du titulaire est dans '
        '« Profils eleves », une seule fois, avec « Vous », et ouvre sa '
        'fiche eleve', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _AppairagePilote()
          ..elevesRendus = <EleveDuFoyer>[
            ...FoyersFictifs.foyerA,
            const EleveDuFoyer(
              id: 'p-guardian',
              prenom: 'Dyna',
              identifiantImmuable: 'RA-26-4817',
              mode: InterfaceMode.standard,
              camera: CameraPolicy.forbidden,
            ),
          ],
        autres: <Override>[
          portProfilEleveTitulaireProvider.overrideWithValue(
            FauxProfilEleveTitulaire()..present = true,
          ),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);

      expect(find.text('Dyna'), findsOneWidget);
      // « Vous » sur sa seule carte, sur aucune autre.
      expect(find.textContaining('${t.foyer.membre.vous} · '), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Dyna'),
            matching: find.byType(CarteMembre),
          ),
          matching: find.textContaining('${t.foyer.membre.vous} · '),
        ),
        findsOneWidget,
      );
      // Le profil existe : plus de lien « Creer mon profil eleve ».
      expect(find.byKey(FoyerPage.monProfilKey), findsNothing);

      await _toucher(tester, find.text('Dyna'));
      expect(lieu(routeur), Routes.ficheElevePour('p-guardian'));
    });

    group('PROFIL-TITULAIRE : une seule carte par personne (garde-cap, '
        '07/11/2026)', () {
      const EleveDuFoyer dyna = EleveDuFoyer(
        id: 'p-guardian',
        prenom: 'Dyna',
        identifiantImmuable: 'RA-26-4817',
        mode: InterfaceMode.standard,
        camera: CameraPolicy.forbidden,
      );
      // Le Foyer du titulaire adulte (carte d'adulte titulaire en tete),
      // monte sur le vrai routeur, session du titulaire `p-guardian`.
      List<Override> titulaireAdulte() => <Override>[
        foyerTitulaireProvider.overrideWith(
          (Ref _) async => DonneesAdulteDemo.foyerTitulaire(
            EtatDemoAdulte.values[1],
            GenreTitulaireDemo.femme,
          ),
        ),
        identiteTitulaireProvider.overrideWith(
          (Ref _) async => const IdentiteTitulaire(
            prenom: 'Dyna',
            nom: 'Diallo',
            methodeConnexion: MethodeConnexion.lienCourriel,
            statut: AccountStatus.active,
          ),
        ),
        portProfilEleveTitulaireProvider.overrideWithValue(
          FauxProfilEleveTitulaire()..present = true,
        ),
      ];

      testWidgets('le titulaire figure dans « Profils eleves » : sa carte '
          'd adulte se retire, il reste UNE carte « Vous »', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          appairage: _AppairagePilote()
            ..elevesRendus = <EleveDuFoyer>[...FoyersFictifs.foyerA, dyna],
          depart: Routes.tuteurFoyer,
          autres: titulaireAdulte(),
        );

        expect(find.byType(FoyerPage), findsOneWidget);
        expect(find.byKey(FoyerPage.titulaireKey), findsNothing);
        expect(find.byType(CarteIdentiteCompte), findsNothing);
        expect(find.text('Dyna'), findsOneWidget);
        expect(
          find.textContaining('${t.foyer.membre.vous} · '),
          findsOneWidget,
        );
        // Rien ne devient inaccessible : la place adulte reste.
        expect(find.byKey(lignePlaceAdulteKey), findsOneWidget);
      });

      testWidgets('controle : sans son profil dans la liste, la carte d '
          'adulte titulaire reste, et aucune carte « Vous »', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          appairage: _foyerA(),
          depart: Routes.tuteurFoyer,
          autres: titulaireAdulte(),
        );

        expect(find.byKey(FoyerPage.titulaireKey), findsOneWidget);
        expect(find.textContaining('${t.foyer.membre.vous} · '), findsNothing);
      });
    });

    testWidgets('profil deja present : la page le dit, rien n est cree, le '
        'disque retour ramene au Foyer', (WidgetTester tester) async {
      final FauxProfilEleveTitulaire port = FauxProfilEleveTitulaire()
        ..present = true;
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          portProfilEleveTitulaireProvider.overrideWithValue(port),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);
      // UX-023 : le Foyer ne propose plus de creer un profil qui existe ;
      // la page reste juste quand on y arrive par son adresse.
      expect(find.byKey(FoyerPage.monProfilKey), findsNothing);
      routeur.go(Routes.tuteurAjouterPourMoi);
      await stabiliser(tester);

      expect(find.byKey(CreerMonProfilPage.dejaKey), findsOneWidget);
      expect(find.byKey(CreerMonProfilPage.creerKey), findsNothing);

      await _toucher(tester, find.byType(DisqueRetour));

      expect(lieu(routeur), Routes.tuteurFoyer);
    });

    testWidgets('creation non confirmee : la phrase dit quoi faire, '
        '« Reessayer » cree au second essai', (WidgetTester tester) async {
      final _ProfilQuiEchoueUneFois port = _ProfilQuiEchoueUneFois();
      await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          portProfilEleveTitulaireProvider.overrideWithValue(port),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);
      await _toucher(tester, find.byKey(FoyerPage.monProfilKey));
      await _toucher(tester, find.byKey(CreerMonProfilPage.creerKey));

      expect(find.byKey(CreerMonProfilPage.nonConfirmeKey), findsOneWidget);
      expect(find.text(t.foyer.monProfil.reessayer), findsOneWidget);

      final GoRouter routeur = GoRouter.of(
        tester.element(find.byType(CreerMonProfilPage)),
      );
      await _toucher(tester, find.byKey(CreerMonProfilPage.creerKey));

      // Cree au second essai : directement au parcours (PROFIL-TITULAIRE).
      expect(port.essais, 2);
      expect(lieu(routeur), Routes.parcoursPour('p-guardian'));
    });
  });

  group('N2 : le second adulte du foyer', () {
    Override role(RoleFoyer r, {bool? femme}) => roleFoyerProvider.overrideWith(
      (Ref _) async => RoleFoyerLu(role: r, femme: femme),
    );

    testWidgets('titulaire homme : « Inviter ma conjointe », la page en forme '
        'feminine', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[role(RoleFoyer.titulaire, femme: false)],
      );
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.byKey(LignesSecondAdulte.inviterKey), findsOneWidget);
      expect(find.text(t.adulte.invitation.titreElle), findsOneWidget);
      expect(find.byKey(LignesSecondAdulte.repriseKey), findsNothing);

      await _toucher(tester, find.text(t.adulte.invitation.titreElle));

      expect(lieu(routeur), RoutesN2.foyerInviter);
      expect(find.byType(InviterConjointPage), findsOneWidget);
      expect(
        tester
            .widget<InviterConjointPage>(find.byType(InviterConjointPage))
            .placeFeminine,
        isTrue,
      );
    });

    testWidgets('genre non enregistre : « Inviter un second adulte », forme '
        'neutre, jamais devinee', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[role(RoleFoyer.titulaire)],
      );
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.text(t.adulte.invitation.titreNeutre), findsOneWidget);
      expect(find.text(t.adulte.invitation.titreElle), findsNothing);
      expect(find.text(t.adulte.invitation.titreLui), findsNothing);

      await _toucher(tester, find.text(t.adulte.invitation.titreNeutre));

      expect(lieu(routeur), RoutesN2.foyerInviter);
      expect(find.text(t.adulte.invitation.phraseNeutre), findsOneWidget);
    });

    testWidgets('second adulte : « Demander la reprise du foyer » ouvre la '
        'demande', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          role(RoleFoyer.secondAdulte, femme: true),
          repriseFoyerProvider.overrideWith(
            (Ref _) async => const RepriseAucune(),
          ),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.byKey(LignesSecondAdulte.repriseKey), findsOneWidget);
      expect(find.byKey(LignesSecondAdulte.inviterKey), findsNothing);

      await _toucher(tester, find.text(t.foyer.n2.demanderReprise));

      expect(lieu(routeur), RoutesN2.foyerReprise);
      expect(find.byType(RepriseFoyerPage), findsOneWidget);
    });

    testWidgets('sans role lu : aucune ligne', (WidgetTester tester) async {
      await _monter(tester, appairage: _foyerA());
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.byKey(LignesSecondAdulte.inviterKey), findsNothing);
      expect(find.byKey(LignesSecondAdulte.repriseKey), findsNothing);
      expect(find.byKey(AlertesSecondAdulte.invitationKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invitation a repondre : la carte en tete du Foyer ouvre '
        'l invitation', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          invitationRecueProvider.overrideWith(
            (Ref _) async => const InvitationARepondre(
              prenomTitulaire: 'Amina',
              titulaireFeminin: true,
            ),
          ),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.byKey(AlertesSecondAdulte.invitationKey), findsOneWidget);
      expect(
        find.text(t.adulte.acceptation.notification(prenom: 'Amina')),
        findsOneWidget,
      );
      // En tete : au-dessus des profils eleves.
      expect(
        tester.getTopLeft(find.byKey(AlertesSecondAdulte.invitationKey)).dy,
        lessThan(tester.getTopLeft(find.byKey(FoyerPage.membresKey)).dy),
      );

      await _toucher(tester, find.text(t.foyer.n2.invitationRecueVoir));

      expect(lieu(routeur), RoutesN2.foyerInvitation);
      expect(find.byType(InvitationRecuePage), findsOneWidget);
    });

    testWidgets('invitation a repondre : la carte en tete de l accueil, meme '
        'foyer vide', (WidgetTester tester) async {
      await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          invitationRecueProvider.overrideWith(
            (Ref _) async => const InvitationARepondre(
              prenomTitulaire: 'Amina',
              titulaireFeminin: true,
            ),
          ),
          demandeRepriseRecueProvider.overrideWith(
            (Ref _) async => const RepriseARefuser(),
          ),
        ],
      );
      expect(find.byKey(AlertesSecondAdulte.invitationKey), findsOneWidget);
      // La reprise se lit au Foyer seulement (Q3).
      expect(find.byKey(AlertesSecondAdulte.repriseKey), findsNothing);
    });

    testWidgets('demande de reprise a refuser : la carte du titulaire ouvre la '
        'decision', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        autres: <Override>[
          role(RoleFoyer.titulaire, femme: true),
          demandeRepriseRecueProvider.overrideWith(
            (Ref _) async => const RepriseARefuser(),
          ),
        ],
      );
      await _ouvrirFoyerParLaBarre(tester);
      expect(find.byKey(AlertesSecondAdulte.repriseKey), findsOneWidget);
      expect(find.text(t.adulte.reprise.titulaire.ligne), findsOneWidget);

      await _toucher(tester, find.text(t.foyer.n2.repriseATraiterVoir));

      expect(lieu(routeur), RoutesN2.foyerRepriseTitulaire);
      expect(find.byType(RepriseTitulairePage), findsOneWidget);
    });
  });

  group('Foyer : etats', () {
    testWidgets('chargement : squelette, aucun etat ni membre', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()..attente = Completer<void>();
      await _monter(tester, appairage: appairage, depart: Routes.tuteurFoyer);

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text('Élève A1'), findsNothing);
      // L'action d'en-tete reste accessible pendant le chargement.
      expect(find.byKey(FoyerPage.ajouterKey), findsOneWidget);

      appairage.attente!.complete();
      await stabiliser(tester);
      expect(find.text('Élève A1'), findsOneWidget);
    });

    testWidgets('vide : phrase honnete, aucune fausse ligne', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _AppairagePilote()
        ..elevesRendus = FoyersFictifs.foyerVide;
      await _monter(tester, appairage: appairage, depart: Routes.tuteurFoyer);

      expect(_etat(NatureEtat.aucunResultat), findsOneWidget);
      expect(find.text(t.foyer.vide.titre), findsOneWidget);
      expect(find.text(t.foyer.membres), findsNothing);
      // L'ajout reste a sa place unique : l'en-tete.
      expect(find.byKey(FoyerPage.ajouterKey), findsOneWidget);
      expect(find.text(t.foyer.appareilsFoyer), findsOneWidget);
    });

    testWidgets('UX-023 : vide, l adulte qui suit les cours lit « Vous '
        'suivez les cours », pas « Aucun profil élève »', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _AppairagePilote()
        ..elevesRendus = FoyersFictifs.foyerVide;
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.tuteurFoyer,
        autres: <Override>[
          portProfilEleveTitulaireProvider.overrideWithValue(
            FauxProfilEleveTitulaire()..present = true,
          ),
        ],
      );

      expect(find.byKey(FoyerPage.videMoiKey), findsOneWidget);
      expect(find.text(t.foyer.vide.moiTitre), findsOneWidget);
      expect(find.text(t.foyer.vide.titre), findsNothing);
      expect(find.byKey(FoyerPage.monProfilKey), findsNothing);
      // Ajouter un autre membre de la famille reste possible.
      expect(find.byKey(FoyerPage.ajouterKey), findsOneWidget);
    });

    testWidgets('erreur : echec du bloc, « Reessayer » relit le foyer', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()..echoue = true;
      await _monter(tester, appairage: appairage, depart: Routes.tuteurFoyer);

      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      expect(find.text('Élève A1'), findsNothing);
      final int lecturesAvant = appairage.lectures;

      // Aucune pompe entre la remise en etat et le geste : les nouvelles
      // tentatives automatiques de Riverpod ne peuvent pas passer avant.
      appairage.echoue = false;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pump();
      expect(appairage.lectures, greaterThan(lecturesAvant));
      await stabiliser(tester);

      expect(find.text('Élève A1'), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
    });

    testWidgets('hors ligne : dit hors ligne, pas echec du serveur', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _foyerA()..echoue = true;
      await _monter(
        tester,
        appairage: appairage,
        depart: Routes.tuteurFoyer,
        autres: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      );

      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
      // EA-HL-DOUBLE-1 : le bandeau dit le reseau, le bloc dit ce qui manque.
      expectSansDonnees(t.foyer.profilsSansDonnees);

      final int lecturesAvant = appairage.lectures;
      appairage.echoue = false;
      await tester.tap(
        find.descendant(
          of: _etat(NatureEtat.horsLigne),
          matching: find.text(t.commun.etats.actions.reessayer),
        ),
      );
      await tester.pump();
      expect(appairage.lectures, greaterThan(lecturesAvant));
      await stabiliser(tester);
      expect(find.text('Élève A1'), findsOneWidget);
    });
  });

  group('Foyer : contenu des lignes', () {
    testWidgets(
      'classes sans service : aucune classe inventee, une phrase sous le '
      'groupe',
      (WidgetTester tester) async {
        await _monter(tester, appairage: _foyerA(), depart: Routes.tuteurFoyer);

        // Le port de production rend `CapaciteIndisponible` (DB-TRV-07).
        expect(find.text(t.foyer.classesIndisponibles), findsOneWidget);
        expect(find.text(t.foyer.membre.sansClasse), findsNothing);
        expect(find.text(t.foyer.membre.accesSansEcheance), findsNWidgets(2));
      },
    );

    testWidgets(
      'classes connues : nom de classe, ou « Pas encore de classe »',
      (WidgetTester tester) async {
        await _monter(
          tester,
          appairage: _foyerA(),
          depart: Routes.tuteurFoyer,
          autres: <Override>[
            portClassesFoyerProvider.overrideWithValue(
              FauxClassesFoyer(
                classes: <ClasseFoyer>[
                  ClasseFoyer(
                    eleveId: FoyersFictifs.a1.id,
                    classe: classeFictive(),
                  ),
                ],
              ),
            ),
          ],
        );

        expect(
          find.text('Classe fictive A · ${t.foyer.membre.accesSansEcheance}'),
          findsOneWidget,
        );
        expect(
          find.text(
            '${t.foyer.membre.sansClasse} · '
            '${t.foyer.membre.accesSansEcheance}',
          ),
          findsOneWidget,
        );
        expect(find.text(t.foyer.classesIndisponibles), findsNothing);
      },
    );

    testWidgets('sans classe : l inscription en cours est dite a la place de '
        '« Pas encore de classe »', (WidgetTester tester) async {
      await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.tuteurFoyer,
        autres: <Override>[
          portClassesFoyerProvider.overrideWithValue(
            FauxClassesFoyer(
              classes: <ClasseFoyer>[
                ClasseFoyer(
                  eleveId: FoyersFictifs.a1.id,
                  classe: classeFictive(),
                ),
              ],
            ),
          ),
        ],
      );
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      (conteneur.read(
        serviceOffresProvider,
      ) as FauxServiceOffres).parcoursRendu = <ParcoursApprenant>[
        for (final EleveDuFoyer e in FoyersFictifs.foyerA)
          ParcoursApprenant(
            eleveId: e.id,
            prenom: e.prenom,
            diagnostic: StatutDiagnostic.nonRequis,
          ),
      ];
      conteneur.invalidate(parcoursFoyerProvider);
      await stabiliser(tester);

      // La classe connue reste la classe ; les autres disent leur etape.
      expect(
        find.text('Classe fictive A · ${t.foyer.membre.accesSansEcheance}'),
        findsOneWidget,
      );
      expect(
        find.textContaining(t.ficheEleve.inscription.aRemplir),
        findsWidgets,
      );
      expect(find.textContaining(t.foyer.membre.sansClasse), findsNothing);
      expect(find.byKey(FoyerPage.inscriptionIllisibleKey), findsNothing);
    });

    testWidgets('inscription illisible (0043 absente) : une phrase, aucune '
        'etape inventee', (WidgetTester tester) async {
      await _monter(tester, appairage: _foyerA(), depart: Routes.tuteurFoyer);
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      (conteneur.read(
        serviceOffresProvider,
      ) as FauxServiceOffres).erreurParcours = Exception(
        '0043 absente',
      );
      conteneur.invalidate(parcoursFoyerProvider);
      await stabiliser(tester);

      expect(find.byKey(FoyerPage.inscriptionIllisibleKey), findsOneWidget);
      expect(
        find.textContaining(t.ficheEleve.inscription.aRemplir),
        findsNothing,
      );
    });

    testWidgets('classes en echec (service present) : « Classe non lue », '
        '« Relire les classes » relit', (WidgetTester tester) async {
      final _ClassesEnEchec classes = _ClassesEnEchec(
        classes: <ClasseFoyer>[
          ClasseFoyer(eleveId: FoyersFictifs.a1.id, classe: classeFictive()),
        ],
      );
      await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.tuteurFoyer,
        autres: <Override>[portClassesFoyerProvider.overrideWithValue(classes)],
      );

      expect(
        find.textContaining(t.foyer.membre.classeEchec),
        findsNWidgets(FoyersFictifs.foyerA.length),
      );
      expect(find.text(t.foyer.classesEchec), findsOneWidget);
      // Ce n'est pas une fonction absente.
      expect(find.text(t.foyer.classesIndisponibles), findsNothing);

      // Le lien relit : une nouvelle lecture part a chaque geste.
      final int avant = classes.lectures;
      await _toucher(tester, find.byKey(FoyerPage.relireClassesKey));
      expect(classes.lectures, greaterThan(avant));
      expect(find.byKey(FoyerPage.relireClassesKey), findsOneWidget);

      // Le service repond de nouveau : le geste suivant rend la classe.
      classes.echoue = false;
      await tester.tap(find.byKey(FoyerPage.relireClassesKey));
      await stabiliser(tester);
      expect(
        find.text('Classe fictive A · ${t.foyer.membre.accesSansEcheance}'),
        findsOneWidget,
      );
      expect(find.byKey(FoyerPage.relireClassesKey), findsNothing);
    });

    testWidgets('« Ajouter un profil eleve » : CTA dominant libelle + fleche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, appairage: _foyerA(), depart: Routes.tuteurFoyer);
      expect(
        tester
            .widget<ActionPrincipale>(find.byKey(FoyerPage.ajouterKey))
            .fleche,
        isTrue,
      );
    });

    testWidgets('acces : echeance a venir et echeance passee, en texte', (
      WidgetTester tester,
    ) async {
      final _AppairagePilote appairage = _AppairagePilote()
        ..elevesRendus = <EleveDuFoyer>[
          EleveDuFoyer(
            id: 'foyer-c-eleve-1',
            prenom: 'Élève C1',
            identifiantImmuable: 'STUD-FC-000001',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.forbidden,
            finAcces: DateTime(2026, 10, 30, 12),
          ),
          EleveDuFoyer(
            id: 'foyer-c-eleve-2',
            prenom: 'Élève C2',
            identifiantImmuable: 'STUD-FC-000002',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.forbidden,
            finAcces: DateTime(2026, 9, 1, 12),
          ),
        ];
      await _monter(tester, appairage: appairage, depart: Routes.tuteurFoyer);

      expect(
        find.text(t.foyer.membre.accesJusquau(date: '30 octobre 2026')),
        findsOneWidget,
      );
      expect(
        find.text(t.foyer.membre.accesExpire(date: '1er septembre 2026')),
        findsOneWidget,
      );
    });

    testWidgets('vocabulaire : aucun libelle interdit a l ecran', (
      WidgetTester tester,
    ) async {
      await _monter(tester, appairage: _foyerA(), depart: Routes.tuteurFoyer);

      final List<String> textes = _textesVisibles(tester);
      expect(textes, isNotEmpty);
      for (final String texte in textes) {
        final String bas = texte.toLowerCase();
        for (final String interdit in <String>[
          'session',
          'cours en cours',
          'ajouter enfant',
          'ajouter un enfant',
          'mode enfant',
          'groupe',
          'stud-',
        ]) {
          expect(bas.contains(interdit), isFalse, reason: '« $texte »');
        }
      }
      // Pas de compteur decoratif (« 3 enfants », « 2 alertes »).
      expect(find.textContaining(RegExp(r'^\d+ ')), findsNothing);
    });
  });

  group('Foyer : bureau', () {
    // FI-5b (guide V4 §5.1 « Desktop », maquette 05) : les membres occupent
    // toute la largeur utile ; les appareils passent dessous, dans la
    // rangee des annexes, a leur largeur de colonne.
    testWidgets('1440 : membres sur toute la largeur, appareils dessous, '
        'onglet par la barre laterale', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        appairage: _foyerA(),
        taille: const Size(1440, 900),
      );
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);

      await _toucher(tester, find.text(t.nav.tuteur.foyer).first);
      expect(lieu(routeur), Routes.tuteurFoyer);

      final Rect membres = tester.getRect(find.byKey(FoyerPage.membresKey));
      final Rect appareils = tester.getRect(find.byKey(FoyerPage.appareilsKey));
      expect(appareils.top, greaterThan(membres.bottom));
      expect(appareils.width, lessThan(membres.width * 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('600 a 1199 : une colonne sous le rail', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: _foyerA(),
        depart: Routes.tuteurFoyer,
        taille: const Size(1024, 768),
      );
      final Rect membres = tester.getRect(find.byKey(FoyerPage.membresKey));
      final Rect appareils = tester.getRect(find.byKey(FoyerPage.appareilsKey));
      expect(appareils.top, greaterThan(membres.bottom));
      expect(tester.takeException(), isNull);
    });
  });
}

/// Un port dont la premiere creation perd sa reponse (D5), la seconde aboutit.
class _ProfilQuiEchoueUneFois implements PortProfilEleveTitulaire {
  int essais = 0;

  @override
  Future<bool> existe() async => false;

  @override
  Future<void> creer() async {
    essais++;
    if (essais == 1) throw Exception('reponse perdue');
  }

  @override
  Future<void> ouvrirEspaceEleve() async {}
}
