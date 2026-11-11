// Captures de la GOUTTE D'HUILE DES PROFILS (directeur, 11/11/2026, relayee par
// le garde-cap) : planches en plusieurs temps.
//   - aller : d'un profil a l'autre, le cou entre les deux ronds ;
//   - retour : le detachement part du profil qu'on quitte ;
//   - contenu : l'ancien contenu aspire vers son rond, puis le nouveau qui
//     tombe du nouveau rond.
// Clair, sombre et arabe (miroir), 390 de large, rangee de profils et cartes de
// contenu fictives.
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
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
  ({double avancement, bool aspiration})? get chute =>
      GoutteProfils.chuteDe(contexte!);
}

/// Avance le temps, 2 ms a la fois, jusqu'a ce que [arret] soit vrai.
Future<void> _jusqua(WidgetTester tester, bool Function() arret) async {
  for (int i = 0; i < 1000; i++) {
    if (arret()) return;
    await tester.pump(const Duration(milliseconds: 2));
  }
  fail('etat de la goutte jamais atteint');
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
  group('Capture : goutte des profils', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    final Map<String, List<List<String>>> planches =
        <String, List<List<String>>>{
          'aller': <List<String>>[],
          'retour': <List<String>>[],
          'contenu': <List<String>>[],
        };

    for (final (
          String nom,
          AppLocale langue,
          ThemeMode theme,
          double echelle,
          InterfaceMode mode,
        )
        in <(String, AppLocale, ThemeMode, double, InterfaceMode)>[
          ('clair', AppLocale.fr, ThemeMode.light, 1, InterfaceMode.standard),
          ('sombre', AppLocale.fr, ThemeMode.dark, 1, InterfaceMode.standard),
          ('arabe', AppLocale.ar, ThemeMode.light, 1, InterfaceMode.standard),
          // Garde-cap (11/11/2026) : texte x2 et Interface guidee.
          (
            'texte_x2',
            AppLocale.fr,
            ThemeMode.light,
            2,
            InterfaceMode.standard,
          ),
          ('guidee', AppLocale.fr, ThemeMode.light, 1, InterfaceMode.enfant),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, _vue, _densite);
        final _Hote h = _Hote();
        await tester.pumpWidget(
          hoteCapture(
            h.ecran(),
            themeMode: theme,
            echelleTexte: echelle,
            interfaceMode: mode,
          ),
        );
        await stabiliser(tester);
        await tester.pump(const Duration(seconds: 1));

        Future<List<String>> rangeeAller({
          required String vers,
          required String suffixe,
        }) async {
          final List<String> rangee = <String>[];
          Future<void> prendre(String temps) async {
            final String c = await capturer(
              tester,
              'goutte_${suffixe}_${nom}_$temps',
            );
            rangee.add(c);
          }

          await prendre('1_repos');
          h.selection.value = vers;
          await tester.pump();
          await tester.pump();
          await _jusqua(tester, () => (h.goutte?.avancement ?? 0) >= 0.12);
          await prendre('2_depart');
          await _jusqua(tester, () => (h.goutte?.avancement ?? 0) >= 0.4);
          await prendre('3_vers_le_rond_choisi');
          await _jusqua(tester, () => (h.goutte?.avancement ?? 0) >= 0.7);
          await prendre('4_cou_aminci');
          await _jusqua(tester, () => h.goutte?.rompu ?? true);
          await prendre('5_rupture');
          await tester.pump(const Duration(milliseconds: 60));
          await prendre('6_rebond');
          await tester.pump(const Duration(seconds: 1));
          return rangee;
        }

        planches['aller']!.add(await rangeeAller(vers: 'c', suffixe: 'aller'));
        // Le retour : le detachement part du profil qu'on quitte (c).
        planches['retour']!.add(
          await rangeeAller(vers: 'a', suffixe: 'retour'),
        );

        // Le contenu : l'ancien aspire, puis le nouveau qui tombe.
        final List<String> contenu = <String>[];
        Future<void> prendreContenu(String temps) async {
          contenu.add(await capturer(tester, 'goutte_contenu_${nom}_$temps'));
        }

        await prendreContenu('1_repos');
        h.selection.value = 'b';
        h.affiche.value = 'b';
        await tester.pump();
        await tester.pump();
        await _jusqua(
          tester,
          () => (h.chute?.aspiration ?? false) && h.chute!.avancement >= 0.5,
        );
        await prendreContenu('2_aspire');
        await _jusqua(
          tester,
          () =>
              (h.chute != null && !h.chute!.aspiration) &&
              h.chute!.avancement >= 0.08,
        );
        await prendreContenu('3_tombe_debut');
        await _jusqua(tester, () => (h.chute?.avancement ?? 1) >= 0.3);
        await prendreContenu('4_tombe_cou');
        await _jusqua(tester, () => (h.chute?.avancement ?? 1) >= 0.6);
        await prendreContenu('5_s_etale');
        await tester.pump(const Duration(seconds: 1));
        await prendreContenu('6_fin');
        planches['contenu']!.add(contenu);
      });
    }

    testWidgets('planches', (WidgetTester tester) async {
      for (final MapEntry<String, List<List<String>>> e in planches.entries) {
        final String c = await _planche(
          tester,
          'goutte_planche_${e.key}',
          e.value,
        );
        debugPrint('PLANCHE $c');
      }
    });
  });
}
