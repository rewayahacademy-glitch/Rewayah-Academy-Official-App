import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/carte_groupe.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';

import 'support/hote_tc_a.dart';

Future<void> _liste(WidgetTester tester) async {
  await tester.pumpWidget(
    hoteTcA(const MesGroupesPage(), surcharges: surchargesDemonstration()),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _espace(WidgetTester tester) async {
  await tester.pumpWidget(
    hoteTcA(
      const EspaceGroupePage(
        groupeId: GroupesDemonstration.alFatiha,
        role: RoleEspaceGroupe.enseignant,
      ),
      surcharges: surchargesDemonstration(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Mes groupes', () {
    testWidgets('mobile : une seule colonne', (WidgetTester tester) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _liste(tester);
        final List<CarteGroupe> cartes = tester
            .widgetList<CarteGroupe>(find.byType(CarteGroupe))
            .toList();
        expect(cartes, hasLength(7));
        // Deux cartes consecutives sont l'une sous l'autre, jamais cote a cote.
        final Offset premiere = tester.getTopLeft(
          find.byType(CarteGroupe).at(0),
        );
        final Offset seconde = tester.getTopLeft(
          find.byType(CarteGroupe).at(1),
        );
        expect(seconde.dy, greaterThan(premiere.dy));
        expect(seconde.dx, premiere.dx);
      });
    });

    testWidgets('tablette : deux colonnes', (WidgetTester tester) async {
      await avecLargeur(tester, largeurTablette, () async {
        await _liste(tester);
        final Offset premiere = tester.getTopLeft(
          find.byType(CarteGroupe).at(0),
        );
        final Offset seconde = tester.getTopLeft(
          find.byType(CarteGroupe).at(1),
        );
        expect(seconde.dy, premiere.dy);
        expect(seconde.dx, greaterThan(premiere.dx));
      });
    });

    testWidgets('desktop : le contenu est centre, jamais etire', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurDesktop, () async {
        await _liste(tester);
        // `PageShell` borne la colonne a 1200 et la centre : sur 1440, il reste
        // donc une marge de chaque cote, et la carte ne traverse pas l'ecran.
        final Rect carte = tester.getRect(find.byType(CarteGroupe).at(0));
        expect(carte.left, greaterThan(0));
        expect(carte.right, lessThan(largeurDesktop));
        expect(carte.width, lessThan(AppPage.largeurMaxContenu));
      });
    });
  });

  group('Espace Groupe', () {
    testWidgets('mobile : la sequence de lecture reste verticale', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _espace(tester);
        final double session = tester.getTopLeft(find.byType(CarteSession)).dy;
        final double bibliotheque = tester
            .getTopLeft(find.text(LibellesGroupe.bibliotheque))
            .dy;
        expect(session, lessThan(bibliotheque));
      });
    });

    testWidgets('tablette : deux colonnes, ordre de lecture conserve', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurTablette, () async {
        await _espace(tester);
        final Offset session = tester.getTopLeft(find.byType(CarteSession));
        final Offset bibliotheque = tester.getTopLeft(
          find.text(LibellesGroupe.bibliotheque),
        );
        // La Bibliotheque passe a droite, et reste donc lue apres la Session.
        expect(bibliotheque.dx, greaterThan(session.dx));
      });
    });

    testWidgets('desktop : rien ne deborde et le contenu reste borne', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurDesktop, () async {
        await _espace(tester);
        final Rect session = tester.getRect(find.byType(CarteSession));
        expect(session.left, greaterThan(0));
        expect(session.right, lessThan(largeurDesktop));
      });
    });

    testWidgets('les trois largeurs rendent la meme information', (
      WidgetTester tester,
    ) async {
      for (final double largeur in <double>[
        largeurMobile,
        largeurTablette,
        largeurDesktop,
      ]) {
        await avecLargeur(tester, largeur, () async {
          await _espace(tester);
          expect(
            find.text('Groupe Al-Fatiha'),
            findsOneWidget,
            reason: '$largeur',
          );
          expect(
            find.text(LibellesGroupe.conseilAppareil),
            findsOneWidget,
            reason: '$largeur',
          );
          expect(
            find.text(LibellesGroupe.avantProchainCours),
            findsOneWidget,
            reason: '$largeur',
          );
          expect(
            find.text(LibellesGroupe.roster),
            findsOneWidget,
            reason: '$largeur',
          );
        });
      }
    });
  });
}
