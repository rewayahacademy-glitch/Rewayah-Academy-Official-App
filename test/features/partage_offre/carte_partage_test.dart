// CAND-06 : la carte a partager. Elle parle de l'interet de l'eleve d'abord
// (consigne du directeur du 22/10/2026, apres coup). Ce qu'elle porte (un titre
// sur ce que l'eleve y gagne, trois lignes vraies tirees des encarts decides,
// l'appel « Decouvrir l'offre » avec le QR et le lien, le logo, le hadith en
// petit, en bas), ce qu'elle ne porte pas (aucun prix, aucune promesse, jamais
// l'academie comme motif), sa lisibilite (contraste mesure) et son
// independance du theme, de la taille de texte et de l'interface guidee.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../theme/support/contraste.dart';
import 'hote_partage.dart';

/// Le hadith, tel que le directeur l'ecrit (22/10/2026).
const String _hadith = 'الدال على الخير كفاعله';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Monte la carte seule, a sa taille, dans un theme et une echelle de texte.
Future<void> _monter(
  WidgetTester tester, {
  Uri? lien,
  Brightness luminosite = Brightness.light,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(800, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(mode, luminosite),
      builder: (BuildContext contexte, Widget? app) => MediaQuery(
        data: MediaQuery.of(contexte)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Center(child: CartePartage(lien: lien ?? lienDeTest)),
    ),
  );
  await tester.pump();
}

/// Les textes de la carte, sans l'adresse du lien (une adresse n'est pas un
/// motif : elle porte le nom du site).
List<String> _textesSansLien(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(
    find.descendant(of: find.byType(CartePartage), matching: find.byType(Text)),
  ))
    if (w.data != null && w.key != CartePartage.lienKey) w.data!,
];

/// Les textes de la carte.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(
    find.descendant(of: find.byType(CartePartage), matching: find.byType(Text)),
  ))
    if (w.data != null) w.data!,
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('ce que la carte porte', () {
    testWidgets('360 x 640 : le format story 9:16, 1080 x 1920 a l\'export', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(
        tester.getSize(find.byType(CartePartage)),
        const Size(CartePartage.largeur, CartePartage.hauteur),
      );
      expect(
        CartePartage.largeur / CartePartage.hauteur,
        closeTo(9 / 16, 1e-9),
      );
      expect(CartePartage.largeur * CartePartage.echelleExport, 1080);
      expect(CartePartage.hauteur * CartePartage.echelleExport, 1920);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'un seul hadith, en arabe, de droite a gauche, avec sa traduction '
      'francaise et sa reference',
      (WidgetTester tester) async {
        await _monter(tester);
        final Text hadith = tester.widget<Text>(_cle('carte-hadith'));
        expect(hadith.data, _hadith);
        expect(hadith.textDirection, TextDirection.rtl);
        expect(
          tester.widget<Text>(_cle('carte-traduction')).data,
          '«\u00a0Celui qui indique le bien est comme celui qui l\'accomplit.'
          '\u00a0»',
        );
        expect(
          tester.widget<Text>(_cle('carte-reference')).data,
          'Rapporté par at-Tirmidhi',
        );
        // Un seul texte en arabe sur toute la carte.
        final RegExp arabe = RegExp('[؀-ۿ]');
        expect(_textes(tester).where(arabe.hasMatch), <String>[_hadith]);
      },
    );

    testWidgets(
      'le titre dit ce que l\'eleve y gagne : apprendre le Coran en ligne, en '
      'petite classe',
      (WidgetTester tester) async {
        await _monter(tester);
        final String titre = tester.widget<Text>(_cle('carte-titre')).data!;
        expect(titre, contains('Apprendre le Coran'));
        expect(titre, contains('en ligne'));
        expect(titre, contains('petite\u00a0classe'));
        expect(titre, isNot(contains('groupe')));
      },
    );

    testWidgets(
      'trois lignes vraies, tirees des encarts decides : le meme enseignant, '
      'trois seances par semaine a heure fixe ; les enfants des 6 ans et les '
      'adultes ; les langues',
      (WidgetTester tester) async {
        await _monter(tester);
        final String enseignant = tester
            .widget<Text>(_cle('carte-enseignant'))
            .data!;
        final String publics = tester.widget<Text>(_cle('carte-publics')).data!;
        final String langues = tester.widget<Text>(_cle('carte-langues')).data!;
        final Map<String, dynamic> tarifs = jsonDecode(
          File('docs/current/tarifs-2026-10-18.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final Map<String, dynamic> site =
            tarifs['site_public'] as Map<String, dynamic>;
        final String enfant = site['encart_enfant']! as String;
        final String adulte = site['encart_adulte']! as String;
        // Chaque fragment de la carte est dans les deux encarts decides.
        for (final String commun in <String>[
          'Trois séances',
          'par semaine',
          'à heure fixe',
          'avec le même enseignant',
          'selon la disponibilité des enseignants',
          'poular',
          'français',
          'anglais',
        ]) {
          expect(enfant, contains(commun), reason: commun);
          expect(adulte, contains(commun), reason: commun);
        }
        expect(enfant, contains('Cours de Coran pour enfants'));
        expect(enfant, contains('6 à 17 ans'));
        expect(adulte, contains('Cours de Coran pour adultes'));
        expect(adulte, contains('18 ans'));
        // La ligne de l'enseignant et des seances.
        expect(enseignant, contains('même enseignant'));
        expect(enseignant, contains('trois séances par semaine'));
        expect(enseignant, contains('à heure fixe'));
        // La ligne des publics.
        expect(publics, contains('enfants'));
        expect(publics, contains('6\u00a0ans'));
        expect(publics, contains('adultes'));
        // La ligne des langues garde la condition des encarts : la carte ne
        // promet pas une langue, et l'arabe n'est pas une langue de cours
        // (decision du directeur, 22/10/2026).
        expect(langues, contains('poular'));
        expect(langues, contains('français'));
        expect(langues, contains('anglais'));
        expect(langues, contains('selon les enseignants disponibles'));
        expect(langues.toLowerCase(), isNot(contains('arabe')));
        // La carte parle de classe (mots-rewayah), jamais de groupe.
        for (final String ligne in <String>[enseignant, publics, langues]) {
          expect(ligne, isNot(contains('groupe')));
        }
      },
    );

    testWidgets('l\'appel est « Decouvrir l\'offre », avec le QR et le lien', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(
        tester.widget<Text>(_cle('carte-decouvrir')).data,
        'Découvrir l\'offre',
      );
      // L'appel, le QR et le lien se lisent ensemble, au-dessus du hadith.
      final double appel = tester.getTopLeft(_cle('carte-decouvrir')).dy;
      expect(tester.getTopLeft(_cle('carte-qr')).dy, lessThanOrEqualTo(appel));
      expect(
        tester.getTopLeft(_cle('carte-hadith')).dy,
        greaterThan(tester.getBottomLeft(_cle('carte-qr')).dy),
      );
    });

    testWidgets(
      'l\'ordre de lecture : le titre, les trois lignes, l\'appel, puis le '
      'hadith, en petit, en bas',
      (WidgetTester tester) async {
        await _monter(tester);
        double haut(String cle) => tester.getTopLeft(_cle(cle)).dy;
        final List<String> ordre = <String>[
          'carte-titre',
          'carte-enseignant',
          'carte-publics',
          'carte-langues',
          'carte-decouvrir',
          'carte-hadith',
          'carte-traduction',
          'carte-reference',
        ];
        for (int i = 1; i < ordre.length; i++) {
          expect(
            haut(ordre[i]),
            greaterThan(haut(ordre[i - 1])),
            reason: '${ordre[i - 1]} avant ${ordre[i]}',
          );
        }
        // Le hadith est un rappel : plus petit que le titre, et dans la moitie
        // basse de la carte.
        double taille(String cle) =>
            tester.widget<Text>(_cle(cle)).style!.fontSize!;
        expect(taille('carte-hadith'), lessThan(taille('carte-titre')));
        expect(
          haut('carte-hadith'),
          greaterThan(
            tester.getTopLeft(find.byType(CartePartage)).dy +
                CartePartage.hauteur * 0.75,
          ),
        );
      },
    );

    testWidgets(
      'jamais l\'academie comme motif : aucun texte de la carte ne la nomme ni '
      'ne demande d\'agir pour elle',
      (WidgetTester tester) async {
        await _monter(tester);
        final String tout = _textesSansLien(tester).join('\n').toLowerCase();
        for (final String mot in motsQuiNommentLAcademie) {
          expect(tout, isNot(contains(mot.toLowerCase())), reason: mot);
        }
      },
    );

    testWidgets('aucun prix, aucune promesse, aucun montant', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final String tout = _textes(tester).join('\n');
      expect(
        RegExp(
          r'\d+\s*(\$|€|usd|dollars?|euros?)|\d+\s*%',
          caseSensitive: false,
        ).hasMatch(tout),
        isFalse,
        reason: tout,
      );
      for (final String mot in <String>[
        'prix',
        'tarif',
        'gratuit',
        'garanti',
        'rembours',
        'remise',
        'bourse',
        'essai',
        'par mois',
        'mensuel',
      ]) {
        expect(tout.toLowerCase(), isNot(contains(mot)), reason: mot);
      }
    });

    testWidgets('le logo blanc sur la bande violette, une seule fois', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Finder logo = find.byType(BrandLogo);
      expect(logo, findsOneWidget);
      expect(tester.widget<BrandLogo>(logo).fond, FondLogo.violet);
      expect(tester.widget<BrandLogo>(logo).variante, VarianteLogo.horizontal);
    });

    testWidgets('le QR et le lien lisible portent l\'adresse de l\'offre', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(tester.widget<Text>(_cle('carte-lien')).data, 'rewayah.test/fr/');
      // Le QR fait au moins 76 points, marge blanche comprise en plus.
      expect(
        tester.getSize(_cle('carte-qr')).width,
        greaterThanOrEqualTo(CartePartage.coteQr),
      );
    });

    testWidgets('un lien long se reduit, il ne deborde pas', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        lien: Uri.parse(
          'https://un-sous-domaine-vraiment-tres-long.exemple-de-site-public.test:8443/fr/',
        ),
      );
      expect(tester.takeException(), isNull);
      final Rect carte = tester.getRect(find.byType(CartePartage));
      final Rect lien = tester.getRect(_cle('carte-lien'));
      expect(lien.right, lessThanOrEqualTo(carte.right));
      expect(lien.left, greaterThanOrEqualTo(carte.left));
    });
  });

  group('la lisibilite', () {
    test('le contraste de chaque texte de la carte, mesure', () {
      final AppPalette p = AppPalette.claire();
      // Blanc sur le violet de marque : l'appel, le lien, le hadith et sa source.
      expect(
        contraste(p.surfacePrimary.onBackground, p.surfacePrimary.background),
        greaterThanOrEqualTo(seuilTexte),
      );
      // L'encre de l'arche sur son fond : le titre et les trois lignes.
      expect(
        contraste(p.washAccent.onBackground, p.washAccent.background),
        greaterThanOrEqualTo(seuilTexte),
      );
      // Le QR : noir sur blanc, et la plaque blanche sur le violet (3:1).
      expect(
        contraste(p.contenuQr.onBackground, p.contenuQr.background),
        greaterThanOrEqualTo(seuilTexte),
      );
      expect(
        contraste(p.contenuQr.background, p.surfacePrimary.background),
        greaterThanOrEqualTo(seuilComposant),
      );
      // L'arche se detache de la bande violette (3:1, element graphique).
      expect(
        contraste(p.washAccent.background, p.surfacePrimary.background),
        greaterThanOrEqualTo(seuilComposant),
      );
    });

    testWidgets('les tailles de texte sont lisibles sur une story', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      double taille(String cle) =>
          tester.widget<Text>(_cle(cle)).style!.fontSize!;
      // 360 points affichent 1080 pixels : 16 points font 48 pixels.
      expect(taille('carte-titre'), greaterThanOrEqualTo(28));
      for (final String ligne in <String>[
        'carte-enseignant',
        'carte-publics',
        'carte-langues',
      ]) {
        expect(taille(ligne), greaterThanOrEqualTo(16), reason: ligne);
      }
      expect(taille('carte-decouvrir'), greaterThanOrEqualTo(18));
      expect(taille('carte-lien'), greaterThanOrEqualTo(14));
      // Le hadith est en petit, mais lisible : 24 points (72 pixels) pour
      // l'arabe, 12 points (36 pixels) pour la traduction et la reference.
      expect(taille('carte-hadith'), greaterThanOrEqualTo(24));
      expect(taille('carte-traduction'), greaterThanOrEqualTo(12));
      expect(taille('carte-reference'), greaterThanOrEqualTo(12));
    });
  });

  group('une image ne suit ni le theme ni le texte de l\'appareil', () {
    testWidgets(
      'sombre, texte x2, interface guidee : memes tailles, memes couleurs',
      (WidgetTester tester) async {
        await _monter(tester);
        final Size reference = tester.getSize(_cle('carte-titre'));
        final double taille = tester
            .widget<Text>(_cle('carte-titre'))
            .style!
            .fontSize!;
        final Color? couleur = tester
            .widget<Text>(_cle('carte-titre'))
            .style!
            .color;
        final Rect qr = tester.getRect(_cle('carte-qr'));
        for (final (Brightness, double, InterfaceMode) variante
            in <(Brightness, double, InterfaceMode)>[
              (Brightness.dark, 1, InterfaceMode.standard),
              (Brightness.light, 2, InterfaceMode.standard),
              (Brightness.dark, 2, InterfaceMode.enfant),
            ]) {
          await _monter(
            tester,
            luminosite: variante.$1,
            echelle: variante.$2,
            mode: variante.$3,
          );
          expect(
            tester.getSize(_cle('carte-titre')),
            reference,
            reason: '$variante',
          );
          final TextStyle style = tester
              .widget<Text>(_cle('carte-titre'))
              .style!;
          expect(style.fontSize, taille, reason: '$variante');
          expect(style.color, couleur, reason: '$variante');
          expect(tester.getRect(_cle('carte-qr')), qr, reason: '$variante');
          expect(tester.takeException(), isNull);
        }
      },
    );
  });

  group('l\'arabe', () {
    testWidgets('la carte arabe : le meme hadith, sa reference arabe, aucune '
        'traduction francaise, le logo et le QR au meme endroit', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Rect qrFrancais = tester.getRect(_cle('carte-qr'));
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, direction: TextDirection.rtl);
      expect(tester.widget<Text>(_cle('carte-hadith')).data, _hadith);
      expect(_cle('carte-traduction'), findsNothing);
      expect(tester.widget<Text>(_cle('carte-reference')).data, 'رواه الترمذي');
      expect(
        tester.widget<Text>(_cle('carte-titre')).data,
        t.recrutement.partage.carte.titre,
      );
      expect(
        tester.widget<Text>(_cle('carte-enseignant')).data,
        t.recrutement.partage.carte.enseignant,
      );
      expect(tester.takeException(), isNull);
      // Le QR passe au debut de la ligne, a droite (la carte se miroite).
      final Rect qrArabe = tester.getRect(_cle('carte-qr'));
      expect(qrArabe.center.dx, greaterThan(qrFrancais.center.dx));
      // L'adresse reste lue de gauche a droite.
      expect(tester.widget<Text>(_cle('carte-lien')).data, 'rewayah.test/fr/');
      // Un seul hadith, et rien de francais ne reste sur la carte.
      final String tout = _textes(tester).join('\n');
      expect(tout, isNot(contains('Celui qui')));
      expect(tout, isNot(contains('Rapporté')));
      expect(tout, isNot(contains('Découvrir')));
    });

    testWidgets(
      'la carte arabe ne parle ni de prix, ni de groupe, ni de l\'academie',
      (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        await _monter(tester, direction: TextDirection.rtl);
        final String tout = _textesSansLien(tester).join('\n');
        expect(
          RegExp(r'[0-9٠-٩]+\s*(\$|€|دولار|يورو|%)').hasMatch(tout),
          isFalse,
        );
        for (final String mot in <String>[
          'سعر',
          'أسعار',
          'مجان',
          'خصم',
          'استرداد',
          ...motsQuiNommentLAcademie,
        ]) {
          expect(tout, isNot(contains(mot)), reason: mot);
        }
        // L'arabe n'est pas une langue de cours (decision du 22/10/2026).
        expect(
          tester.widget<Text>(_cle('carte-langues')).data,
          isNot(contains('العربية')),
        );
      },
    );
  });
}
