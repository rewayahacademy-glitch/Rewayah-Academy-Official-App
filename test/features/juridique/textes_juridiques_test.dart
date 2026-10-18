// Textes juridiques (lot « levee des blocages », 18/10/2026) : les six textes
// se lisent sans erreur a 320 et 1440, texte 100 et 200 %, en francais et en
// arabe (sens droite a gauche), avec leur version et leur date ; rien n'est
// invente (les manques sont des reperes), aucun montant, aucun mot interdit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/dossier/politique_controle.dart'
    show SectionPolitique, textePlatBloc;
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

String _tout(TexteJuridique x) =>
    sectionsJuridiques(x)
        .expand((SectionPolitique s) => <String>[s.titre, ...s.blocs])
        .join('\n');

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Le contenu', () {
    for (final AppLocale langue in AppLocale.values) {
      test(
        '${langue.languageCode} : six textes, ni montant ni mot interdit',
        () {
          LocaleSettings.setLocaleSync(langue);
          final RegExp interdit = RegExp(
            r'garanti|certifi|100\s?%|\$|\bgroupes?\b|ضمان|مضمون',
          );
          for (final TexteJuridique x in TexteJuridique.values) {
            final String texte = _tout(x);
            expect(x.titre, isNotEmpty);
            expect(sectionsJuridiques(x), isNotEmpty);
            expect(
              interdit.hasMatch(texte),
              isFalse,
              reason: '${x.slug} : ${interdit.firstMatch(texte)?.group(0)}',
            );
            // Aucun chiffre de prix : pas de montant ecrit.
            expect(
              RegExp(r'\d+[,.]\d{2}').hasMatch(texte),
              isFalse,
              reason: x.slug,
            );
          }
        },
      );
    }

    test('les manques sont des reperes, listes une fois', () {
      final String enfants = _tout(TexteJuridique.enfants);
      expect(enfants, contains('[à compléter par la direction'));
      expect(enfants, contains('responsable de la protection des enfants'));
      expect(CoordonneesJuridiques.aCompleter(), ChampJuridique.values);
    });

    test('un champ renseigne remplace son repere', () {
      final String texte = sectionsJuridiques(
        TexteJuridique.mentions,
        renseignes: const <ChampJuridique, String>{
          ChampJuridique.hebergeur: 'Hebergeur Exemple',
        },
      ).expand((SectionPolitique s) => s.blocs).map(textePlatBloc).join('\n');
      expect(texte, contains('Hebergeur Exemple'));
      expect(texte, isNot(contains('hébergeur légal et ses coordonnées]')));
    });

    test('la societe vient de JUR-APP-1 et le contact de la constante', () {
      final String m = _tout(TexteJuridique.mentions);
      expect(m, contains('16624644'));
      expect(m, contains('support@rewayahacademy.com'));
    });

    test('adresses et version', () {
      expect(TexteJuridique.depuisSlug('cookies'), TexteJuridique.cookies);
      expect(TexteJuridique.depuisSlug('inconnu'), isNull);
      expect(
        TexteJuridique.annulation.chemin,
        '/juridique/annulation-remboursement',
      );
      expect(ligneVersionJuridique(), contains(VersionsJuridiques.version));
      expect(ligneVersionJuridique(), contains('18 octobre 2026'));
    });
  });

  group('Le rendu', () {
    for (final (AppLocale langue, Size taille, double echelle)
        in <(AppLocale, Size, double)>[
          (AppLocale.fr, const Size(320, 690), 1),
          (AppLocale.fr, const Size(320, 690), 2),
          (AppLocale.fr, const Size(1440, 900), 1),
          (AppLocale.ar, const Size(320, 690), 1),
          (AppLocale.ar, const Size(320, 690), 2),
          (AppLocale.ar, const Size(1440, 900), 1),
        ]) {
      testWidgets('${langue.languageCode} ${taille.width.toInt()} x$echelle : '
          'les six textes et la liste, sans erreur ni mot coupe', (
        WidgetTester tester,
      ) async {
        LocaleSettings.setLocaleSync(langue);
        fixerVueCapture(tester, taille, 1);
        final List<Widget> pages = <Widget>[
          const JuridiquePage(),
          for (final TexteJuridique x in TexteJuridique.values)
            TexteJuridiquePage(texte: x),
        ];
        for (final Widget page in pages) {
          await tester.pumpWidget(hoteCapture(page, echelleTexte: echelle));
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining(VersionsJuridiques.version),
            findsOneWidget,
          );
          final TextDirection sens = Directionality.of(
            tester.element(find.byType(Scaffold).first),
          );
          expect(
            sens,
            langue == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
          );
          // Un mot compose peut passer a la ligne apres son trait d'union
          // (« écrivez-nous ») ; aucune autre coupure.
          expect(
            motsCoupes(tester, find.byWidget(page), traitDUnionPermis: true),
            isEmpty,
            reason: 'Un mot coupe ou tronque',
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -100000),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('la liste montre les six textes', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(hoteCapture(const JuridiquePage()));
      await stabiliser(tester);
      for (final TexteJuridique x in TexteJuridique.values) {
        expect(find.text(x.titre), findsOneWidget);
      }
    });
  });
}
