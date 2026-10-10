// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import '../../support/annonces.dart';
import 'faux/faux_groupes.dart';
import 'faux/faux_reseau.dart';
import 'support/hote_tc_a.dart';

Future<void> _poser(
  WidgetTester tester, {
  List<Override> surcharges = const <Override>[],
}) async {
  await tester.pumpWidget(
    hoteTcA(const MesGroupesPage(), surcharges: surcharges),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('la liste montre les groupes du jeu de demonstration', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, surcharges: surchargesDemonstration());

      expect(find.text(LibellesGroupe.mesGroupesTitre), findsOneWidget);
      expect(find.byType(CarteGroupe), findsNWidgets(7));
      expect(find.text('Classe Al-Fatiha'), findsOneWidget);
      // La capacite de chaque groupe vient de sa donnee : deux seuils
      // differents cohabitent dans la meme liste.
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.text('3 / 4'), findsOneWidget);
    });
  });

  testWidgets('aucun groupe donne un etat subi, sans bouton', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        surcharges: <Override>[
          portGroupesProvider.overrideWithValue(const FauxPortGroupes()),
          serviceReseauProvider.overrideWithValue(const FauxServiceReseau()),
        ],
      );

      expect(find.text(LibellesGroupe.aucunGroupe), findsOneWidget);
      expect(find.byType(CarteGroupe), findsNothing);
      final EmptyState vide = tester.widget<EmptyState>(
        find.byType(EmptyState),
      );
      expect(vide.registre, RegistreVide.subi);
      expect(vide.onAction, isNull);
    });
  });

  testWidgets('un echec de lecture propose de reessayer', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        surcharges: <Override>[
          portGroupesProvider.overrideWithValue(
            const FauxPortGroupes(echoue: true),
          ),
          serviceReseauProvider.overrideWithValue(const FauxServiceReseau()),
        ],
      );

      expect(find.text(LibellesGroupe.erreur), findsOneWidget);
      expect(find.text(LibellesGroupe.reessayer), findsOneWidget);
    });
  });

  testWidgets('le chargement prend la forme de ce qui arrive', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await tester.pumpWidget(
        hoteTcA(
          const MesGroupesPage(),
          surcharges: <Override>[
            portGroupesProvider.overrideWithValue(
              const FauxPortGroupes(jamaisPret: true),
            ),
            serviceReseauProvider.overrideWithValue(const FauxServiceReseau()),
          ],
        ),
      );
      // Le squelette ne s'affiche qu'apres 200 ms : un squelette qui clignote
      // coute plus cher qu'il ne rassure.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CarteGroupe), findsNothing);
    });
  });

  testWidgets('hors ligne, les cartes restent lisibles et Rejoindre, jamais '
      'grise, dit quand entrer sans entrer (BOUTONS-GRISES-1)', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final List<String> annonces = ecouterAnnonces(tester);
      int appels = 0;
      await tester.pumpWidget(
        hoteTcA(
          MesGroupesPage(onRejoindre: (_) => appels++),
          surcharges: surchargesDemonstration(horsLigne: true),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Une seule source d'etat reseau, celle du bandeau partage.
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byType(CarteGroupe), findsNWidgets(7));
      final Finder rejoindre = find.widgetWithText(
        ActionPrincipale,
        LibellesGroupe.rejoindre,
      );
      final Iterable<ActionPrincipale> boutons = tester
          .widgetList<ActionPrincipale>(rejoindre);
      expect(boutons, isNotEmpty);
      for (final ActionPrincipale bouton in boutons) {
        expect(bouton.onPress, isNotNull);
      }
      expect(find.text(t.tc.groupe.carte.entreeAttendReseau), findsNothing);

      await tester.ensureVisible(rejoindre.first);
      await tester.tap(rejoindre.first);
      await tester.pump();
      expect(appels, 0);
      expect(find.text(t.tc.groupe.carte.entreeAttendReseau), findsOneWidget);
      expect(annonces, <String>[t.tc.groupe.carte.entreeAttendReseau]);
      // La phrase ne redit pas « hors ligne » : seul le bandeau le dit.
      expect(
        t.tc.groupe.carte.entreeAttendReseau.toLowerCase(),
        isNot(contains('hors ligne')),
      );
    });
  });

  testWidgets('sans rappel branche, aucun Rejoindre (jamais grise)', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, surcharges: surchargesDemonstration());
      expect(find.byType(CarteGroupe), findsNWidgets(7));
      expect(
        find.widgetWithText(ActionPrincipale, LibellesGroupe.rejoindre),
        findsNothing,
      );
    });
  });

  testWidgets('en ligne, Rejoindre appelle le rappel de l hote', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      String? ouvert;
      await tester.pumpWidget(
        hoteTcA(
          MesGroupesPage(onRejoindre: (_) => ouvert = 'appele'),
          surcharges: surchargesDemonstration(),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ActionPrincipale, LibellesGroupe.rejoindre).first,
      );
      await tester.pump();
      expect(ouvert, 'appele');
    });
  });

  testWidgets('un groupe sans occurrence figure quand meme dans la liste', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(tester, surcharges: surchargesDemonstration());
      // Le Groupe est permanent : il existe avant d'avoir une seance.
      expect(find.text('Classe Sabil'), findsOneWidget);
      expect(find.text(LibellesGroupe.aucuneSeance), findsOneWidget);
    });
  });

  testWidgets('le jeu de demonstration couvre les six etats du temps', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _poser(
        tester,
        surcharges: surchargesDemonstration(maintenant: ancreDemonstration),
      );

      expect(
        find.textContaining('Cours dans 3\u00A0h\u00A028'),
        findsOneWidget,
      );
      expect(
        find.textContaining(LibellesGroupe.salleOuverteCourt),
        findsWidgets,
      );
      expect(
        find.textContaining(LibellesGroupe.attenteAvantDebut),
        findsOneWidget,
      );
      expect(find.textContaining('Reste 28\u00A0min'), findsOneWidget);
      expect(find.textContaining(LibellesGroupe.prolongee), findsOneWidget);
      expect(find.textContaining(LibellesGroupe.terminee), findsOneWidget);
      expect(find.text(LibellesGroupe.aucuneSeance), findsOneWidget);
    });
  });
}
