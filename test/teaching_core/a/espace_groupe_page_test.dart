import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import 'faux/faux_groupes.dart';
import 'faux/faux_reseau.dart';
import 'support/hote_tc_a.dart';

Future<void> _poser(
  WidgetTester tester, {
  String groupeId = GroupesDemonstration.alFatiha,
  RoleEspaceGroupe role = RoleEspaceGroupe.eleve,
  List<Override>? surcharges,
  void Function(dynamic groupe)? onReprendre,
}) async {
  await tester.pumpWidget(
    hoteTcA(
      EspaceGroupePage(
        groupeId: groupeId,
        role: role,
        onReprendreLeCours: onReprendre == null
            ? null
            : (_) => onReprendre(null),
      ),
      surcharges: surcharges ?? surchargesDemonstration(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Un port **branche** qui n'a reellement rien a rendre.
///
/// Il n'existe que pour prouver la seconde moitie de la regle semantique : la
/// liste vide d'un port branche autorise l'interface a dire qu'il n'y a rien a
/// preparer, ce que `null` ne permettra jamais.
class _TravailBrancheEtVide implements PortTravailAVenir {
  const _TravailBrancheEtVide();

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => const <SlotAction>[];
}

void main() {
  group('La page verticale', () {
    testWidgets('elle n a ni barre laterale interne ni systeme d onglets', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.byType(TabBar), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(BottomNavigationBar), findsNothing);
      });
    });

    testWidgets('l ordre est stable : Session, Avant, Bibliotheque', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);

        final double session = tester.getTopLeft(find.byType(CarteSession)).dy;
        final double avant = tester
            .getTopLeft(find.text(LibellesGroupe.avantProchainCours))
            .dy;
        final double bibliotheque = tester
            .getTopLeft(find.text(LibellesGroupe.bibliotheque))
            .dy;
        expect(session, lessThan(avant));
        expect(avant, lessThan(bibliotheque));
      });
    });

    testWidgets('l identite du groupe est la meme que sur la carte', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.text('Groupe Al-Fatiha'), findsOneWidget);
        expect(find.text('Sayyid Youssouf'), findsWidgets);
        expect(find.text('Lecture du Coran · Niveau 2'), findsOneWidget);
        // La capacite reelle, en toutes lettres dans la pastille.
        expect(find.text('4 élèves sur 5 places'), findsOneWidget);
      });
    });
  });

  group('La Session Card', () {
    testWidgets('elle montre les deux horloges quand elles different', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.text(LibellesGroupe.votreHeure), findsOneWidget);
        expect(find.text('18:00 Riyad'), findsOneWidget);
        expect(find.text('Chez Sayyid Youssouf'), findsOneWidget);
        expect(find.text('15:00 Conakry'), findsOneWidget);
        // Jamais un offset numerique a l'ecran.
        expect(find.textContaining('UTC+'), findsNothing);
      });
    });

    testWidgets('un seul fuseau ne montre qu une horloge', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.anNour);
        expect(find.text(LibellesGroupe.votreHeure), findsOneWidget);
        expect(find.text('13:45 Paris'), findsOneWidget);
        expect(find.textContaining('Chez '), findsNothing);
        expect(find.text(LibellesGroupe.heureGroupe), findsNothing);
      });
    });

    testWidgets('cote enseignant, la contrepartie est l heure du groupe', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, role: RoleEspaceGroupe.enseignant);
        expect(find.text(LibellesGroupe.heureGroupe), findsOneWidget);
        expect(find.textContaining('Chez '), findsNothing);
      });
    });

    testWidgets('elle porte le conseil d appareil, sans popup ni blocage', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.text(LibellesGroupe.conseilAppareil), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    testWidgets('la duree se lit, et elle vient de l occurrence', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.text(LibellesGroupe.dureeLibelle), findsOneWidget);
        expect(find.text('1 h 30'), findsOneWidget);
      });
    });

    testWidgets('avant la fenetre, aucun bouton Rejoindre', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.text(LibellesGroupe.rejoindre), findsNothing);
      });
    });

    testWidgets('a T-20, le bouton Rejoindre apparait', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.anNour);
        expect(find.text(LibellesGroupe.rejoindre), findsOneWidget);
      });
    });

    testWidgets('a T-20, le tuteur n a pas de bouton Rejoindre', (
      WidgetTester tester,
    ) async {
      // Revue phase 0 (routes D8) : le tuteur ne rejoint pas la classe de son
      // enfant, il l'observe par la porte d'observation.
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(
          tester,
          groupeId: GroupesDemonstration.anNour,
          role: RoleEspaceGroupe.tuteur,
        );
        expect(find.text(LibellesGroupe.rejoindre), findsNothing);
      });
    });

    testWidgets('connecte avant T0, l attente est dite et expliquee', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.alIhsan);
        // CL-4.3 : la phrase vient de l'emplacement d'entree unique (R4).
        expect(
          find.textContaining(t.classe.entree.annonce.attente),
          findsOneWidget,
        );
        expect(
          find.text(LibellesGroupe.attenteAvantDebutDetail),
          findsOneWidget,
        );
      });
    });

    testWidgets('en depassement, aucun nombre negatif', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.alHikma);
        // R6 : « Temps prevu ecoule », jamais un nombre negatif.
        expect(
          find.textContaining(t.classe.entree.tempsEcoule),
          findsOneWidget,
        );
        expect(find.textContaining('Reste -'), findsNothing);
      });
    });

    testWidgets('sans occurrence, la Session Card le dit', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.sabil);
        expect(find.text(LibellesGroupe.aucuneSeance), findsOneWidget);
        expect(find.text(LibellesGroupe.rejoindre), findsNothing);
      });
    });
  });

  group('Le changement d heure', () {
    testWidgets('la notice vient de l horloge, pas du widget', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.alBaqara);
        expect(find.byType(NoticeChangementHeure), findsOneWidget);
        // CL-4.3 : l'avis, sous les heures, vient d'EmplacementEntree.
        expect(
          find.text(t.classe.entree.dst(avant: '13:00', apres: '12:00')),
          findsOneWidget,
        );
      });
    });

    testWidgets('aucune notice quand il n y en a pas', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.byType(NoticeChangementHeure), findsNothing);
      });
    });
  });

  group('Les emplacements', () {
    testWidgets('la bibliotheque n est jamais implementee ici', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.byType(BlocBibliotheque), findsOneWidget);
        // Port non branche : on le dit, on n'invente pas une etagere.
        expect(find.text(LibellesGroupe.emplacementNonBranche), findsWidgets);
      });
    });

    testWidgets('le roster n apparait que du cote pedagogique', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.byType(BlocRoster), findsNothing);
      });
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, role: RoleEspaceGroupe.enseignant);
        expect(find.byType(BlocRoster), findsOneWidget);
        expect(find.text(LibellesGroupe.roster), findsOneWidget);
      });
    });

    testWidgets('le bloc avant le prochain cours ne fabrique aucune tache', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(find.byType(EmplacementAvantProchainCours), findsOneWidget);
        final EmplacementAvantProchainCours bloc = tester
            .widget<EmplacementAvantProchainCours>(
              find.byType(EmplacementAvantProchainCours),
            );
        expect(bloc.portBranche, isFalse);
        expect(bloc.actions, isEmpty);
      });
    });

    // La regle semantique arbitree sur `portTravailAVenirProvider` : `null` dit
    // « non branche », un port branche qui rend une liste vide dit « rien a
    // preparer ». Les deux etats doivent produire DEUX rendus differents, et le
    // second seul a le droit d'annoncer qu'il n'y a rien a faire.
    testWidgets('port non branche : il dit « non branche », jamais « rien »', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester);
        expect(
          find.descendant(
            of: find.byType(EmplacementAvantProchainCours),
            matching: find.text(LibellesGroupe.emplacementNonBranche),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(EmplacementAvantProchainCours),
            matching: find.text(LibellesGroupe.aucuneAction),
          ),
          findsNothing,
        );
      });
    });

    testWidgets('port branche et liste vide : il dit « rien a preparer »', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(
          tester,
          surcharges: <Override>[
            ...surchargesDemonstration(),
            portTravailAVenirProvider.overrideWithValue(
              const _TravailBrancheEtVide(),
            ),
          ],
        );

        final EmplacementAvantProchainCours bloc = tester
            .widget<EmplacementAvantProchainCours>(
              find.byType(EmplacementAvantProchainCours),
            );
        expect(bloc.portBranche, isTrue);
        expect(bloc.actions, isEmpty);

        expect(
          find.descendant(
            of: find.byType(EmplacementAvantProchainCours),
            matching: find.text(LibellesGroupe.aucuneAction),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(EmplacementAvantProchainCours),
            matching: find.text(LibellesGroupe.emplacementNonBranche),
          ),
          findsNothing,
        );
      });
    });
  });

  group('Reprendre le cours', () {
    testWidgets('absent pour l eleve, meme pendant le cours', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, groupeId: GroupesDemonstration.alBaqara);
        expect(find.text(LibellesGroupe.reprendreLeCours), findsNothing);
      });
    });

    testWidgets('absent pour l enseignant hors seance', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(tester, role: RoleEspaceGroupe.enseignant);
        expect(find.text(LibellesGroupe.reprendreLeCours), findsNothing);
      });
    });

    testWidgets('present pour l enseignant pendant le cours', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(
          tester,
          groupeId: GroupesDemonstration.alBaqara,
          role: RoleEspaceGroupe.enseignant,
        );
        expect(find.text(LibellesGroupe.reprendreLeCours), findsOneWidget);
        // Une action, jamais une section permanente.
        final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
          find.widgetWithText(
            ActionPrincipale,
            LibellesGroupe.reprendreLeCours,
          ),
        );
        expect(bouton.pleineLargeur, isFalse);
      });
    });
  });

  group('Les etats subis', () {
    testWidgets('un groupe qui n est pas le votre est dit, sans bouton', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(
          tester,
          groupeId: 'inexistant',
          surcharges: <Override>[...surchargesDemonstration()],
        );
        expect(find.text(LibellesGroupe.groupeIntrouvable), findsOneWidget);
      });
    });

    testWidgets('la page s affiche sans attendre un tic d horloge', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _poser(
          tester,
          surcharges: <Override>[
            portHorlogeSeanceProvider.overrideWithValue(
              const PortHorlogeMuet(),
            ),
            portGroupesProvider.overrideWithValue(
              const FauxPortGroupes(groupes: <Never>[]),
            ),
            serviceReseauProvider.overrideWithValue(const FauxServiceReseau()),
          ],
        );
        // Le port des groupes est vide : la page dit que le groupe n'est pas
        // ouvert, elle ne reste pas bloquee sur un squelette.
        expect(find.text(LibellesGroupe.groupeIntrouvable), findsOneWidget);
      });
    });
  });
}
