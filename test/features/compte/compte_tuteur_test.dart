// Compte du tuteur (lot E, sous-paquet 1) : chaque rubrique est TOUCHEE
// depuis la navigation, sur le vrai routeur (definition de « fait », registre
// section 5 bis) ; composition telephone et bureau ; etats ; aucune impasse.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/identite/port_matricule.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/version/ligne_version.dart';
import 'package:rewayah_academy/core/widgets/entete_compte.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart'
    show FeuilleLangueCompte;
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/consentements/consentement_observation_page.dart';
import 'package:rewayah_academy/features/demo/identite/matricule_demo.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';

import '../../fixtures/tuteur/faux_capacites.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import 'support_compte.dart';

/// Une authentification dont la deconnexion echoue.
class _AuthEnEchec implements ServiceAuth {
  int tentatives = 0;

  @override
  Future<void> connexionGoogle() async {}

  @override
  Future<void> connexionMotDePasse(
    String courriel,
    String motDePasse, {
    String? jetonControle,
  }) async {}

  @override
  Future<void> deconnexion() async {
    tentatives++;
    throw Exception('reseau coupe');
  }

  @override
  Future<void> envoyerLienCourriel(
    String courriel, {
    String? jetonControle,
  }) async {}
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

Finder _texte(String s) => find.text(s);

void main() {
  group('Mon compte : atteint depuis la barre, composition de la maquette', () {
    testWidgets('la destination Compte de la barre ouvre Mon compte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(
        tester,
        depart: Routes.tuteurAccueil,
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(NavShell.barreBasseKey),
          matching: find.bySemanticsLabel(t.nav.tuteur.compte),
        ),
      );
      await stabiliser(tester);

      expect(lieu(routeur), Routes.tuteurCompte);
      expect(find.byType(CompteTuteurPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
      // L'identite reelle du titulaire (double du port K6), jamais le role
      // seul ni un identifiant technique.
      expect(_texte('Titulaire A Foyer A'), findsOneWidget);
      expect(_texte(t.compte.roles.guardian), findsOneWidget);
      expect(_texte(t.compte.tuteur.identite.statutValide), findsOneWidget);
      expect(_texte('p-guardian'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('les sections suivent l ordre fixe du Compte sur telephone', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      // PROFILS P2 : l'ordre fixe des sections, puis la sortie.
      final List<String> titres = <String>[
        t.compte.page.sections.monEspace,
        t.compte.page.sections.paiements,
        t.compte.page.sections.preferences,
        t.compte.page.sections.compteSecurite,
        t.compte.page.sections.aide,
        t.compte.deconnexion,
      ];
      double precedent = tester.getTopLeft(_texte('Titulaire A Foyer A')).dy;
      for (final String titre in titres) {
        final double y = tester.getTopLeft(_texte(titre)).dy;
        expect(y, greaterThan(precedent), reason: titre);
        precedent = y;
      }
    });

    testWidgets('aucune fonction sans service n est rendue ni doublee', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, taille: const Size(1440, 900));
      for (final String absent in <String>[
        t.compte.tuteur.acces.paiements,
        'Modifier',
        'Gérer les paiements',
        'Historique et reçus',
        'Moyen de paiement',
        'Appareils connectés',
        'Compte vérifié',
        'Abonnement et accès',
      ]) {
        expect(find.textContaining(absent), findsNothing, reason: absent);
      }
      // Une seule entree par destination : chaque libelle n'apparait qu'une
      // fois.
      for (final String unique in <String>[
        t.compte.tuteur.acces.ligne,
        t.compte.tuteur.securite.methode,
        t.compte.tuteur.informations.titre,
        t.compte.profils,
        t.compte.tuteur.foyer.creerMonProfil,
        t.compte.tuteur.aide.legal,
      ]) {
        expect(_texte(unique), findsOneWidget, reason: unique);
      }
      // Plus d'engrenage : les preferences sont dans la page.
      expect(find.byIcon(AppIcons.reglages.repos), findsNothing);
    });
  });

  group('Chaque rubrique se touche et revient au Compte', () {
    final List<(String, String, Type)> rubriques = <(String, String, Type)>[
      (
        t.compte.tuteur.acces.ligne,
        Routes.compteTuteurSousPage('acces'),
        AccesComptePage,
      ),
      (
        t.compte.tuteur.securite.methode,
        Routes.compteTuteurSousPage('securite'),
        SecuriteComptePage,
      ),
      (
        t.compte.tuteur.informations.titre,
        Routes.compteTuteurSousPage('informations'),
        InformationsComptePage,
      ),
    ];

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final (String libelle, String chemin, Type ecran) in rubriques) {
        testWidgets('${taille.width.toInt()} : « $libelle » ouvre $ecran', (
          WidgetTester tester,
        ) async {
          final GoRouter routeur = await monterCompte(tester, taille: taille);
          await toucher(tester, _texte(libelle));

          expect(lieu(routeur), chemin);
          expect(find.byType(ecran), findsOneWidget);
          // Niveau 2 : la destination Compte reste active, un disque retour
          // est visible, la navigation aussi (aucune impasse).
          expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
          expect(find.byType(DisqueRetour), findsOneWidget);

          await tester.tap(find.byType(DisqueRetour));
          await stabiliser(tester);
          expect(lieu(routeur), Routes.tuteurCompte);
          expect(find.byType(CompteTuteurPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    // A-3 : le consentement aux visites se revoit depuis le Compte.
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()} : la ligne Consentements ouvre '
          'le consentement aux visites', (WidgetTester tester) async {
        final GoRouter routeur = await monterCompte(tester, taille: taille);
        await toucher(tester, _texte(t.compte.tuteur.securite.consentements));

        expect(lieu(routeur), Routes.tuteurCompteConsentements);
        expect(find.byType(ConsentementObservationPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('« Informations légales » ouvre les textes juridiques', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(tester);
      await toucher(tester, _texte(t.compte.tuteur.aide.legal));
      expect(find.byType(JuridiquePage), findsOneWidget);
      expect(routeur, isNotNull);
    });

    testWidgets('« Gérer mon foyer » allume la destination Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(tester);
      await toucher(tester, _texte(t.compte.profils));

      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
    });

    testWidgets('« Créer mon profil élève » ouvre le meme flux que le Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(tester);
      await toucher(tester, _texte(t.compte.tuteur.foyer.creerMonProfil));

      expect(lieu(routeur), Routes.tuteurAjouterPourMoi);
      expect(find.byType(CreerMonProfilPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Créer mon profil élève » disparait quand le profil existe', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        surcharges: <Override>[
          portProfilEleveTitulaireProvider.overrideWithValue(
            FauxProfilEleveTitulaire()..present = true,
          ),
        ],
      );
      expect(_texte(t.compte.tuteur.foyer.creerMonProfil), findsNothing);
      expect(_texte(t.compte.profils), findsOneWidget);
    });
  });

  group('Preferences dans la page (PROFILS P2)', () {
    testWidgets('le theme se choisit en un geste, sans autre page', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterCompte(tester);
      expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
      await toucher(tester, _texte(t.compte.themeSombre));
      expect(
        _conteneur(tester).read(preferencesLocalesProvider).theme,
        PreferenceTheme.sombre,
      );
      expect(lieu(routeur), Routes.tuteurCompte);
    });

    testWidgets('la langue et l accessibilite sont des lignes de la page', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      expect(_texte(t.compte.langue), findsOneWidget);
    });

    testWidgets('la langue s ouvre en un geste depuis la page', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      await toucher(tester, _texte(t.compte.langue));
      expect(find.byKey(FeuilleLangueCompte.choixKey), findsOneWidget);
    });
  });

  group('En-tete et pied du Compte : matricule avec Copier, version', () {
    testWidgets('le matricule s affiche avec « Copier », la version en bas, '
        'quand la donnee existe', (WidgetTester tester) async {
      String? copie;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await monterCompte(
        tester,
        surcharges: <Override>[
          portMatriculeProvider.overrideWithValue(
            const MatriculeDemo(<String, Matricule>{
              'p-guardian': Matricule(
                valeur: 'RA-26-4817',
                role: RoleAffiche.tuteur,
              ),
            }),
          ),
          versionAppliProvider.overrideWith(
            (Ref _) async => (version: '1.0.0', build: '423'),
          ),
        ],
      );
      expect(_texte('RA-26-4817'), findsOneWidget);
      await tester.tap(find.byKey(EnteteCompte.copierKey));
      await stabiliser(tester);
      expect(copie, 'RA-26-4817');
      final Finder version = find.byKey(PageCompte.versionKey);
      await tester.ensureVisible(version);
      expect(
        find.descendant(
          of: version,
          matching: _texte(t.compte.version(version: '1.0.0', build: '423')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans matricule servi : aucune ligne, jamais un faux', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      expect(find.byKey(EnteteCompte.copierKey), findsNothing);
    });
  });

  group('Se deconnecter', () {
    testWidgets('Annuler ne deconnecte pas ; confirmer deconnecte', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      final FauxServiceAuth auth =
          _conteneur(tester).read(serviceAuthProvider) as FauxServiceAuth;

      await toucher(tester, find.bySemanticsLabel(t.compte.deconnexion));
      expect(_texte(t.compte.tuteur.deconnexion.question), findsWidgets);
      await tester.tap(_texte(t.commun.annuler));
      await stabiliser(tester);
      expect(auth.deconnexions, 0);

      await toucher(tester, find.bySemanticsLabel(t.compte.deconnexion));
      await tester.tap(_texte(t.compte.tuteur.deconnexion.confirmer));
      await stabiliser(tester);
      expect(auth.deconnexions, 1);
    });

    testWidgets('sur bureau aussi, la deconnexion est atteignable', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, taille: const Size(1440, 900));
      final FauxServiceAuth auth =
          _conteneur(tester).read(serviceAuthProvider) as FauxServiceAuth;
      await toucher(tester, find.bySemanticsLabel(t.compte.deconnexion));
      await tester.tap(_texte(t.compte.tuteur.deconnexion.confirmer));
      await stabiliser(tester);
      expect(auth.deconnexions, 1);
    });

    testWidgets('un echec de deconnexion est dit, rien n est pretendu', (
      WidgetTester tester,
    ) async {
      final _AuthEnEchec auth = _AuthEnEchec();
      await monterEcran(
        tester,
        const CompteTuteurPage(),
        surcharges: <Override>[
          ...surchargesCompte(),
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
          serviceAuthProvider.overrideWithValue(auth),
          serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      );
      await toucher(tester, find.bySemanticsLabel(t.compte.deconnexion));
      await tester.tap(_texte(t.compte.tuteur.deconnexion.confirmer));
      await stabiliser(tester);
      expect(auth.tentatives, 1);
      expect(_texte(t.compte.tuteur.deconnexion.echec), findsOneWidget);
    });
  });

  group('Etats du Compte', () {
    testWidgets(
      'identite sans adaptateur : etat indisponible, pas de faux nom',
      (WidgetTester tester) async {
        // Le provider de production du port (implementation « indisponible »),
        // tel qu'il est tant que le coordinateur n'a pas branche l'adaptateur.
        await monterCompte(
          tester,
          identite: const IdentiteTitulaireIndisponible(),
        );
        expect(_texte(t.commun.etats.indisponible.titre), findsOneWidget);
        expect(_texte('Titulaire A Foyer A'), findsNothing);
        // Le reste du Compte reste utilisable, deconnexion comprise.
        expect(find.bySemanticsLabel(t.compte.deconnexion), findsOneWidget);
      },
    );

    testWidgets('identite en echec : Reessayer relance la lecture', (
      WidgetTester tester,
    ) async {
      final IdentiteEnEchec identite = IdentiteEnEchec();
      await monterCompte(tester, identite: identite);
      expect(_texte(t.compte.page.identiteEchec), findsOneWidget);
      final int avant = identite.lectures;
      await tester.tap(_texte(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(identite.lectures, greaterThan(avant));
    });

    testWidgets('identite en chargement : squelette a la place de la carte', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, identite: IdentiteEnAttente());
      expect(find.byType(Skeleton), findsWidgets);
      expect(_texte(t.compte.page.sections.paiements), findsOneWidget);
    });

    testWidgets('hors ligne : le bandeau le dit sur Mon compte', (
      WidgetTester tester,
    ) async {
      await monterEcran(
        tester,
        const CompteTuteurPage(),
        surcharges: <Override>[
          ...surchargesCompte(),
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
          serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
          serviceReseauProvider.overrideWithValue(
            FauxServiceReseau(horsLigneRendu: true),
          ),
        ],
      );
      expect(_texte(t.reseau.horsLigne), findsOneWidget);
    });
  });

  group('Sous-pages : contenu reel et etats honnetes', () {
    testWidgets('Acces : sans echeance, ouvert jusqu au, termine', (
      WidgetTester tester,
    ) async {
      final List<EleveDuFoyer> eleves = <EleveDuFoyer>[
        FoyersFictifs.a1,
        EleveDuFoyer(
          id: 'foyer-a-eleve-3',
          prenom: 'Élève A3',
          identifiantImmuable: 'STUD-FA-000003',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
          finAcces: DateTime.utc(2026, 10, 30, 12),
        ),
        EleveDuFoyer(
          id: 'foyer-a-eleve-4',
          prenom: 'Élève A4',
          identifiantImmuable: 'STUD-FA-000004',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
          finAcces: DateTime.utc(2026, 9, 1, 12),
        ),
      ];
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('acces'),
        eleves: eleves,
      );
      expect(_texte(t.compte.tuteur.pageAcces.sansEcheance), findsOneWidget);
      expect(_texte('Ouvert jusqu\'au 30 octobre 2026'), findsOneWidget);
      expect(_texte('Terminé le 1er septembre 2026'), findsOneWidget);
      expect(_texte(t.compte.tuteur.pageAcces.titulaire), findsOneWidget);
      expect(find.textContaining('bonnement'), findsNothing);
    });

    testWidgets('Acces : foyer sans profil', (WidgetTester tester) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('acces'),
        eleves: FoyersFictifs.foyerVide,
      );
      expect(_texte(t.compte.tuteur.pageAcces.aucunTitre), findsOneWidget);
    });

    for (final String ancienne in <String>['informations-legales']) {
      testWidgets(
        'PAIEMENTS-RECUS-TUTEUR : plus de ligne dans le Compte ; la page '
        'reste routee et dit la verite',
        (WidgetTester tester) async {
          await monterCompte(
            tester,
            depart: Routes.compteTuteurSousPage('paiements'),
          );
          expect(find.byType(PaiementsComptePage), findsOneWidget);
          expect(
            _texte(t.compte.tuteur.pagePaiements.indisponibleTitre),
            findsOneWidget,
          );
          expect(_texte(t.commun.etats.actions.reessayer), findsNothing);
        },
      );

      testWidgets('PROFILS P2 : /tuteur/compte/$ancienne revient au Compte '
          '(page supprimee)', (WidgetTester tester) async {
        final GoRouter routeur = await monterCompte(
          tester,
          depart: Routes.compteTuteurSousPage(ancienne),
        );
        expect(lieu(routeur), Routes.tuteurCompte);
        expect(find.byType(CompteTuteurPage), findsOneWidget);
      });
    }

    testWidgets('Aide : indisponible, aucun faux contact', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, depart: Routes.compteTuteurSousPage('aide'));
      expect(find.byType(AideComptePage), findsOneWidget);
      expect(
        _texte(t.compte.tuteur.pageAide.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('Informations : lecture seule, fuseau du profil', (
      WidgetTester tester,
    ) async {
      // COMPTE-ENSEIGNANT-IDENTITE (garde-cap, 12/11/2026) : le fuseau vient
      // de `mon_horloge` (fuseau du profil, sans repli sur Paris), plus de
      // `mon_fuseau`.
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
        surcharges: <Override>[
          monHorlogeProvider.overrideWith(
            (Ref _) async => MonHorloge(
              maintenantServeur: DateTime.utc(2026, 11, 12, 9),
              moi: const FuseauVu(
                fuseau: 'Europe/Paris',
                decalage: Duration(hours: 1),
              ),
            ),
          ),
        ],
      );
      expect(_texte('Titulaire A'), findsOneWidget);
      expect(_texte('Foyer A'), findsOneWidget);
      expect(_texte('Paris'), findsOneWidget);
      expect(_texte(t.compte.tuteur.pageInformations.note), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Securite : la methode reelle, aucun mot de passe', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('securite'),
      );
      expect(_texte(t.compte.tuteur.identite.connexionLien), findsOneWidget);
      expect(find.textContaining('mot de passe'), findsNothing);
      expect(_texte(t.compte.tuteur.pageSecurite.appareils), findsOneWidget);
    });
  });
}
