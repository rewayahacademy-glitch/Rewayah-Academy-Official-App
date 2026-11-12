// GOUTTE-COUPEE (11/11/2026) : la goutte ne peint plus rien ; seule la
// planche « coupee » est produite. Ancien en-tete :
// Captures de la GOUTTE D'HUILE DES PROFILS (directeur, 11/11/2026, relayee par
// le garde-cap) : planches en plusieurs temps.
//   - aller : d'un profil a l'autre, le cou entre les deux ronds ;
//   - retour : le detachement part du profil qu'on quitte ;
//   - contenu : le nouveau contenu est la tout de suite (jamais retarde), et la
//     goutte tombe du nouveau rond sur lui.
// Clair, sombre et arabe (miroir), 390 de large, rangee de profils et cartes de
// contenu fictives.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/goutte_profils.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

import 'outil_capture.dart';

const Size _vue = Size(390, 520);
const double _densite = 3;

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'a', prenom: 'Amina', etat: 'Dans 3 h'),
  ProfilSelectionnable(id: 'b', prenom: 'Bilal', etat: 'Aucune séance'),
  ProfilSelectionnable(id: 'c', prenom: 'Chaima', etat: 'Salle ouverte'),
];

class _Hote {
  final ValueNotifier<String> selection = ValueNotifier<String>('a');
  final ValueNotifier<String> affiche = ValueNotifier<String>('a');
  BuildContext? contexte;

  Widget ecran() => ListenableBuilder(
    listenable: Listenable.merge(<Listenable>[selection, affiche]),
    builder: (BuildContext context, Widget? _) {
      final AppPalette palette = AppPalette.of(context);
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GoutteProfils(
              selectionId: selection.value,
              matiere: palette.inkAccent.asBorderSide().color,
              matiereContenu: palette.surfaceRaised.background,
              rayonContenu: AppRadius.lg,
              child: Builder(
                builder: (BuildContext ctx) {
                  contexte = ctx;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SelecteurProfils(
                        profils: _profils,
                        selectionId: selection.value,
                        onSelection: (String id) => selection.value = id,
                      ),
                      const SizedBox(height: 24),
                      ContenuGoutte(
                        profilId: affiche.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AppCard(
                              child: SizedBox(
                                height: 120,
                                child: Center(
                                  child: Text(
                                    'Contenu de ${_nom(affiche.value)}',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const AppCard(child: SizedBox(height: 60)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  static String _nom(String id) =>
      _profils.firstWhere((ProfilSelectionnable p) => p.id == id).prenom;

  ({double avancement, bool rompu, String de, String vers})? get goutte =>
      GoutteProfils.goutteDe(contexte!);
  ({double avancement})? get chute => GoutteProfils.chuteDe(contexte!);
}

/// La planche : le haut de chaque capture (la rangee des profils et le haut du
/// contenu), une rangee par variante, une colonne par temps.
Future<String> _planche(
  WidgetTester tester,
  String nom,
  List<List<String>> rangees,
) async {
  const double marge = 24;
  const double hBande = 400 * _densite;
  final String chemin = cheminSortie(nom);
  await tester.runAsync(() async {
    Future<ui.Image> lire(String c) async {
      final ui.Codec codec = await ui.instantiateImageCodec(
        await File(c).readAsBytes(),
      );
      return (await codec.getNextFrame()).image;
    }

    final List<List<ui.Image>> images = <List<ui.Image>>[
      for (final List<String> r in rangees)
        <ui.Image>[for (final String c in r) await lire(c)],
    ];
    final double l = images.first.first.width.toDouble();
    final int colonnes = images
        .map((List<ui.Image> r) => r.length)
        .reduce((int a, int b) => a > b ? a : b);
    final double largeur = marge + colonnes * (l + marge);
    final double hauteur = marge + images.length * (hBande + marge);
    final ui.PictureRecorder enregistreur = ui.PictureRecorder();
    final Canvas toile = Canvas(enregistreur);
    toile.drawRect(
      Rect.fromLTWH(0, 0, largeur, hauteur),
      Paint()..color = const Color(0xFF7A7A7A),
    );
    for (int r = 0; r < images.length; r++) {
      for (int c = 0; c < images[r].length; c++) {
        final ui.Image i = images[r][c];
        toile.drawImageRect(
          i,
          Rect.fromLTWH(0, 0, l, hBande),
          Rect.fromLTWH(
            marge + c * (l + marge),
            marge + r * (hBande + marge),
            l,
            hBande,
          ),
          Paint(),
        );
      }
    }
    final ui.Image planche = await enregistreur.endRecording().toImage(
      largeur.ceil(),
      hauteur.ceil(),
    );
    final ByteData? png = await planche.toByteData(
      format: ui.ImageByteFormat.png,
    );
    for (final List<ui.Image> r in images) {
      for (final ui.Image i in r) {
        i.dispose();
      }
    }
    planche.dispose();
    await File(chemin).writeAsBytes(png!.buffer.asUint8List());
  });
  return chemin;
}

void main() {
  // GOUTTE-COUPEE (directeur, 11/11/2026) : la goutte ne peint plus rien. La
  // planche montre le changement de profil propre : avant, a l'image du
  // toucher (selection et contenu deja changes), puis 300 ms apres.
  group('Capture : goutte coupee', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    final List<List<String>> rangees = <List<String>>[];

    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, _vue, _densite);
        final _Hote h = _Hote();
        await tester.pumpWidget(hoteCapture(h.ecran(), themeMode: theme));
        await stabiliser(tester);
        await tester.pump(const Duration(seconds: 1));
        final List<String> rangee = <String>[];
        rangee.add(await capturer(tester, 'goutte_coupee_${nom}_1_avant'));
        h.selection.value = 'c';
        h.affiche.value = 'c';
        await tester.pump();
        expect(h.goutte, isNull);
        expect(h.chute, isNull);
        rangee.add(await capturer(tester, 'goutte_coupee_${nom}_2_toucher'));
        await tester.pump(const Duration(milliseconds: 300));
        rangee.add(await capturer(tester, 'goutte_coupee_${nom}_3_apres'));
        rangees.add(rangee);
      });
    }

    testWidgets('planche', (WidgetTester tester) async {
      final String c = await _planche(tester, 'goutte_planche_coupee', rangees);
      debugPrint('PLANCHE $c');
    });
  });
}
