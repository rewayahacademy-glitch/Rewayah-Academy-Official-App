// EN-12 (micro), decision du directeur du 27/09 : quand l'enseignant coupe
// ou rallume son micro en salle (bouton du dock ou touche M), l'icone
// change ET une annonce breve dit l'etat obtenu (« Micro ouvert » ou
// « Micro coupe »), visible et lue par le lecteur d'ecran.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// S0.2 (pilote, 24/10/2026) : l'etat du micro ne s'affiche plus en bulle sur
// la page ; seule l'infobulle du bouton rond le dit (standard des commandes
// d'appel : icone seule, aucun mot sous le bouton), et l'annonce reste.
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

/// Un hote qui tient l'etat du micro, comme la demonstration.
class _Hote extends StatefulWidget {
  const _Hote();

  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  bool micro = false;

  @override
  Widget build(BuildContext context) => SalleSeance(
    vue: DonneesSeanceDemo.vue(RoleSeance.enseignant, EtatDemoSalle.repos),
    local: EtatLocalSeance(microOuvert: micro),
    raccourcisClavier: true,
    actions: ActionsSeance(onMicro: () => setState(() => micro = !micro)),
  );
}

Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(const _Hote()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

AppIcon _iconeMicro(WidgetTester tester) => tester
    .widget<BoutonAppel>(find.byKey(const ValueKey<String>('bouton-micro')))
    .icone;

/// L'infobulle d'etat du bouton Micro du dock (standard des commandes
/// d'appel : aucun mot sous l'icone), distincte du bandeau bref qui dit le
/// meme texte.
Finder _motDuBouton(String texte) => find.descendant(
  of: find.byKey(const ValueKey<String>('bouton-micro')),
  matching: find.byTooltip(texte),
);

List<String> _annonces(WidgetTester tester) => tester
    .takeAnnouncements()
    .map((CapturedAccessibilityAnnouncement a) => a.message)
    .toList();

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('EN-12 retour du micro', () {
    for (final Size taille in const <Size>[Size(1440, 900), Size(390, 844)]) {
      testWidgets('dock ${taille.width.toInt()} : icone et annonce', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        expect(_iconeMicro(tester), AppIcons.microCoupe);
        expect(find.text(t.salle.microOuvert), findsNothing);
        // L'infobulle du bouton dit « Micro coupe » avant toute annonce.
        expect(_motDuBouton(t.salle.microCoupe), findsOneWidget);
        tester.takeAnnouncements();

        await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
        await _attendre(tester);
        expect(_iconeMicro(tester), AppIcons.micro);
        // Aucun mot a l'ecran : ni sous le bouton, ni en bandeau ; l'etat est
        // dans l'infobulle et l'annonce.
        expect(find.text(t.salle.microOuvert), findsNothing);
        expect(_motDuBouton(t.salle.microOuvert), findsOneWidget);
        expect(_annonces(tester), <String>[t.salle.microOuvert]);

        await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
        await _attendre(tester);
        expect(_iconeMicro(tester), AppIcons.microCoupe);
        expect(find.text(t.salle.microCoupe), findsNothing);
        expect(_motDuBouton(t.salle.microCoupe), findsOneWidget);
        expect(find.text(t.salle.microOuvert), findsNothing);
        expect(_annonces(tester), <String>[t.salle.microCoupe]);

        // Breve : le bandeau se retire de lui-meme, apres le maintien d'un
        // retour local puis une sortie tenue dans le plafond des transitions.
        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pump();
        await tester.pump(AppMouvement.plafond);
        // Toujours aucun mot ; l'infobulle du bouton reste.
        expect(find.text(t.salle.microCoupe), findsNothing);
        expect(_motDuBouton(t.salle.microCoupe), findsOneWidget);
      });
    }

    testWidgets('touche M : meme annonce, une seule fois', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(1440, 900));
      tester.takeAnnouncements();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await _attendre(tester);
      expect(_iconeMicro(tester), AppIcons.micro);
      expect(find.text(t.salle.microOuvert), findsNothing);
      expect(_annonces(tester), <String>[t.salle.microOuvert]);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await _attendre(tester);
      expect(find.text(t.salle.microCoupe), findsNothing);
      expect(_annonces(tester), <String>[t.salle.microCoupe]);
      await tester.pump(AppMouvement.retourLocalMaintien);
    });
  });

  group('Capture : EN-12 micro', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String theme = mode == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('en12 micro $nom $theme', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(hoteCapture(const _Hote(), themeMode: mode));
          await stabiliser(tester);
          await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          debugPrint(
            'PNG ${await capturer(tester, 'en12_micro_ouvert_${nom}_$theme')}',
          );
          await tester.pump(AppMouvement.retourLocalMaintien);
        });
      }
    }
  });
}
