// MESSAGERIE-PLEIN-ECRAN (directeur, 15/11/2026) : une conversation ouverte
// est une page a elle. Source : docs/current/UX_REVIEW_MESSAGERIE-PLEIN-ECRAN.md.
// Telephone : une seule barre compacte (56), le fil sur toute la hauteur
// restante, la saisie fixe au-dessus du clavier, aucune phrase d'aide.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/com_messages/barre_conversation.dart';
import 'package:rewayah_academy/features/com_messages/panneau_contexte_fil.dart';

import '../../support/demo/communications/demo_communications_page.dart';
import 'support_messages.dart';

const Size _mobile = Size(390, 844);

/// Simule un clavier logiciel de 300 points (ratio 1).
void _clavier(WidgetTester tester, double hauteur) {
  tester.view.viewInsets = FakeViewPadding(bottom: hauteur);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('telephone 390 x 844, ${langue.languageCode}', () {
      testWidgets('une seule barre compacte, ni titre de page ni onglets', (
        WidgetTester tester,
      ) async {
        await monterMessages(
          tester,
          port: portDemo(RoleDemoCommunications.enseignant),
          depart: cheminFilTest('fil-adam'),
          taille: _mobile,
          langue: langue,
        );
        expect(find.byType(PageShell), findsNothing);
        final Finder barre = find.byKey(BarreConversation.cle);
        expect(barre, findsOneWidget);
        expect(tester.getSize(barre).height, lessThanOrEqualTo(64));
        expect(
          find.byKey(EspaceTravailAdaptatif.cleRetourListe),
          findsOneWidget,
        );
        expect(
          find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
          findsOneWidget,
        );
        expect(find.byType(FilDiscussion), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'clavier ouvert : le fil garde plus de la moitie de ce qui reste, '
        'sans phrase d aide, le champ est colle au clavier',
        (WidgetTester tester) async {
          _clavier(tester, 300);
          await monterMessages(
            tester,
            port: portDemo(RoleDemoCommunications.enseignant),
            depart: cheminFilTest('fil-adam'),
            taille: _mobile,
            langue: langue,
          );
          final double haut = tester
              .getSize(find.byKey(FilDiscussion.cleMessages))
              .height;
          final double visible = _mobile.height - 300;
          // Clavier ouvert : une barre minimale de 48 (retour et nom), sans (i).
          expect(
            tester.getSize(find.byKey(BarreConversation.cle)).height,
            lessThanOrEqualTo(49),
          );
          expect(
            find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
            findsNothing,
          );
          // ignore: avoid_print
          print(
            'MESURE ${langue.languageCode} ${haut / _mobile.height} ${haut / visible}',
          );
          // Le fil prend l'essentiel de l'ecran visible (barre 56 + champ).
          expect(haut / visible, greaterThan(0.75));
          expect(
            find.text(t.com.socle.composants.composer.champVide),
            findsNothing,
          );
          final Rect champ = tester.getRect(
            find.byKey(FilDiscussion.cleSaisie),
          );
          expect(champ.bottom, lessThanOrEqualTo(visible + 0.5));
          expect(champ.bottom, greaterThan(visible - 40));
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '(i) ouvre le dossier en feuille, le retour mene a la liste',
        (WidgetTester tester) async {
          final GoRouter routeur = await monterMessages(
            tester,
            port: portDemo(RoleDemoCommunications.enseignant),
            depart: cheminFilTest('fil-adam'),
            taille: _mobile,
            langue: langue,
          );
          await tester.tap(
            find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
          );
          await tester.pumpAndSettle();
          expect(find.byType(PanneauContexteFil), findsOneWidget);
          tester.state<NavigatorState>(find.byType(Navigator).last).pop();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(EspaceTravailAdaptatif.cleRetourListe));
          await tester.pumpAndSettle();
          expect(cheminCourant(routeur), cheminListeTest);
        },
      );
    });
  }

  testWidgets('ordinateur 1440 : la liste et le fil cote a cote, titre garde', (
    WidgetTester tester,
  ) async {
    await monterMessages(
      tester,
      port: portDemo(RoleDemoCommunications.enseignant),
      depart: cheminFilTest('fil-adam'),
    );
    expect(find.byType(PageShell), findsOneWidget);
    expect(find.byKey(EspaceTravailAdaptatif.cleListe), findsOneWidget);
    expect(find.byType(FilDiscussion), findsOneWidget);
    expect(find.byKey(BarreConversation.cle), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
