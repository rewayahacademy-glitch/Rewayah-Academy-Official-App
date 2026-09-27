// Compte du tuteur (lot E, sous-paquet 1) : chaque rubrique est TOUCHEE
// depuis la navigation, sur le vrai routeur (definition de « fait », registre
// section 5 bis) ; composition telephone et bureau ; etats ; aucune impasse.

import 'package:flutter/material.dart';
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
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/apparence_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/informations_legales_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/preferences_page.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/consentements/consentement_observation_page.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_indisponible.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

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
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {}

  @override
  Future<void> deconnexion() async {
    tentatives++;
    throw Exception('reseau coupe');
  }

  @override
  Future<void> envoyerLienCourriel(String courriel) async {}
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
          matching: find.text(t.nav.tuteur.compte),
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
      expect(_texte('titulaire.a@exemple.test'), findsOneWidget);
      expect(_texte(t.compte.tuteur.identite.connexionLien), findsOneWidget);
      expect(_texte('p-guardian'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('les cartes suivent l ordre de la maquette sur telephone', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester);
      final List<String> titres = <String>[
        t.compte.tuteur.acces.titre,
        t.compte.tuteur.securite.titre,
        t.compte.tuteur.informations.titre,
        t.compte.tuteur.foyer.titre,
        t.compte.tuteur.aide.titre,
        t.compte.deconnexion,
      ];
      double precedent = tester.getTopLeft(_texte('Titulaire A Foyer A')).dy;
      for (final String titre in titres) {
        final double y = tester.getTopLeft(_texte(titre)).dy;
        expect(y, greaterThan(precedent), reason: titre);
        precedent = y;
      }
    });

    testWidgets('sur bureau, deux colonnes comme la maquette 1440', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, taille: const Size(1440, 900));
      final Offset acces = tester.getTopLeft(
        _texte(t.compte.tuteur.acces.titre),
      );
      final Offset securite = tester.getTopLeft(
        _texte(t.compte.tuteur.securite.titre),
      );
      final Offset informations = tester.getTopLeft(
        _texte(t.compte.tuteur.informations.titre),
      );
      final Offset foyer = tester.getTopLeft(
        _texte(t.compte.tuteur.foyer.titre),
      );
      // Colonne gauche : Acces puis Securite ; colonne droite : Informations,
      // Foyer, Aide, a la meme hauteur de depart que la gauche.
      expect(informations.dx, greaterThan(acces.dx + 200));
      expect((informations.dy - acces.dy).abs(), lessThan(1));
      expect(securite.dx, acces.dx);
      expect(securite.dy, greaterThan(acces.dy));
      expect(foyer.dx, informations.dx);
      // La deconnexion reste une bande pleine largeur, sous les colonnes.
      expect(
        tester.getSize(find.bySemanticsLabel(t.compte.deconnexion)).width,
        greaterThan(1000),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune fonction sans service n est rendue ni doublee', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, taille: const Size(1440, 900));
      for (final String absent in <String>[
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
        t.compte.tuteur.acces.paiements,
        t.compte.tuteur.securite.methode,
        t.compte.tuteur.informations.consulter,
        t.compte.profils,
        t.compte.tuteur.foyer.creerMonProfil,
        t.compte.tuteur.aide.ligne,
        t.compte.tuteur.aide.legal,
      ]) {
        expect(_texte(unique), findsOneWidget, reason: unique);
      }
      expect(
        find.bySemanticsLabel(t.compte.tuteur.preferences),
        findsOneWidget,
      );
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
        t.compte.tuteur.acces.paiements,
        Routes.compteTuteurSousPage('paiements'),
        PaiementsComptePage,
      ),
      (
        t.compte.tuteur.securite.methode,
        Routes.compteTuteurSousPage('securite'),
        SecuriteComptePage,
      ),
      (
        t.compte.tuteur.informations.consulter,
        Routes.compteTuteurSousPage('informations'),
        InformationsComptePage,
      ),
      (
        t.compte.tuteur.aide.ligne,
        Routes.compteTuteurSousPage('aide'),
        AideComptePage,
      ),
      (
        t.compte.tuteur.aide.legal,
        Routes.compteTuteurSousPage('informations-legales'),
        InformationsLegalesComptePage,
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
        await toucher(tester, _texte(t.consentement.titre));

        expect(lieu(routeur), Routes.tuteurCompteConsentements);
        expect(find.byType(ConsentementObservationPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

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
      expect(find.byType(CreerMonProfilIndisponible), findsOneWidget);
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

  group('Preferences et Apparence', () {
    testWidgets(
      'engrenage, Apparence, Sombre : le theme change, retours en chaine',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterCompte(tester);
        await toucher(
          tester,
          find.bySemanticsLabel(t.compte.tuteur.preferences),
        );
        expect(lieu(routeur), Routes.tuteurComptePreferences);
        expect(find.byType(PreferencesComptePage), findsOneWidget);
        // Tache focalisee : pas de barre basse sur telephone, un disque retour.
        expect(find.byKey(NavShell.barreBasseKey), findsNothing);
        expect(find.byType(DisqueRetour), findsOneWidget);
        expect(
          _texte(t.compte.tuteur.pagePreferences.notificationsDetail),
          findsOneWidget,
        );

        await toucher(
          tester,
          _texte(t.compte.tuteur.pagePreferences.apparence),
        );
        expect(lieu(routeur), Routes.tuteurCompteApparence);
        expect(find.byType(ApparenceComptePage), findsOneWidget);
        // Aucun interrupteur sans effet (C08 section 2.3).
        expect(find.byType(Switch), findsNothing);

        await toucher(tester, _texte(t.compte.themeSombre));
        expect(
          _conteneur(tester).read(preferencesLocalesProvider).theme,
          PreferenceTheme.sombre,
        );

        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurComptePreferences);
        // Le choix survit au retour : c'est la preference de l'application.
        expect(
          _conteneur(tester).read(preferencesLocalesProvider).theme,
          PreferenceTheme.sombre,
        );

        await tester.tap(find.byType(DisqueRetour));
        await stabiliser(tester);
        expect(lieu(routeur), Routes.tuteurCompte);
        expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'sur bureau, les preferences gardent la colonne de navigation',
      (WidgetTester tester) async {
        final GoRouter routeur = await monterCompte(
          tester,
          taille: const Size(1440, 900),
        );
        await toucher(
          tester,
          find.bySemanticsLabel(t.compte.tuteur.preferences),
        );
        expect(lieu(routeur), Routes.tuteurComptePreferences);
        expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
      },
    );
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
      expect(_texte(t.commun.etats.echecServeur.titre), findsOneWidget);
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
      expect(_texte(t.compte.tuteur.acces.titre), findsOneWidget);
    });

    testWidgets('foyer vide : aucun profil, aucun compteur invente', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, eleves: FoyersFictifs.foyerVide);
      expect(_texte(t.compte.tuteur.foyer.aucun), findsOneWidget);
      expect(_texte(t.compte.tuteur.acces.pastilleActif), findsNothing);
    });

    testWidgets('hors ligne : le bandeau le dit sur Mon compte', (
      WidgetTester tester,
    ) async {
      await monterEcran(
        tester,
        const CompteTuteurPage(),
        surcharges: <Override>[
          ...surchargesCompte(),
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
          prenom: 'Eleve A3',
          identifiantImmuable: 'STUD-FA-000003',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
          finAcces: DateTime.utc(2026, 10, 30, 12),
        ),
        EleveDuFoyer(
          id: 'foyer-a-eleve-4',
          prenom: 'Eleve A4',
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
      expect(_texte('Terminé le 1 septembre 2026'), findsOneWidget);
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

    testWidgets('Paiements : indisponible, sans aucune action', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('paiements'),
      );
      expect(
        _texte(t.compte.tuteur.pagePaiements.indisponibleTitre),
        findsOneWidget,
      );
      expect(_texte(t.commun.etats.actions.reessayer), findsNothing);
    });

    testWidgets('Aide : indisponible, aucun faux contact', (
      WidgetTester tester,
    ) async {
      await monterCompte(tester, depart: Routes.compteTuteurSousPage('aide'));
      expect(
        _texte(t.compte.tuteur.pageAide.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('Informations legales : documents acceptes, textes absents', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations-legales'),
        acceptations: FauxServiceAcceptations(
          rendues: <Acceptation>[
            Acceptation(
              sorte: SorteContrat.conditionsTuteur,
              version: '2026-09',
              accepteeLe: DateTime(2026, 9, 12, 10),
            ),
          ],
        ),
      );
      expect(
        _texte(t.compte.tuteur.pageLegal.conditionsTuteur),
        findsOneWidget,
      );
      expect(
        _texte('Version 2026-09, acceptée le 12 septembre 2026'),
        findsOneWidget,
      );
      expect(_texte(t.compte.tuteur.pageLegal.textes), findsOneWidget);
    });

    testWidgets('Informations : lecture seule, fuseau des seances', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        depart: Routes.compteTuteurSousPage('informations'),
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
