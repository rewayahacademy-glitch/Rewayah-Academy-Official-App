// Captures de la correction LIQUIDE-MATIERE (directeur, 11/11/2026, relayee
// par le garde-cap) : le cercle Compte est TIRE hors de la pilule, comme une
// goutte d'huile qui se detache : une seule forme, un cou concave qui
// s'amincit, la rupture, puis le rebond des deux bords ; aucun contour, la
// couleur de selection jamais dans le cou. Cinq temps (repos, cou forme, cou
// aminci, rupture, rebond), clair, sombre et arabe, 390 ; puis le retour
// vers un onglet (le cercle absorbe). Sans personne connectee (aucune donnee
// reelle).
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/indicateur_liquide.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

const Size _vue = Size(390, 700);
const double _densite = 3;

Widget _barre(ThemeMode theme) {
  int actif = 0;
  final List<Destination> d = destinationsPour(
    role: AppRole.guardian,
    mode: InterfaceMode.standard,
  );
  return hoteCapture(
    StatefulBuilder(
      builder: (BuildContext _, StateSetter majeur) => NavShell(
        destinations: d,
        indexActif: actif,
        onAller: (String c) => majeur(
          () => actif = d.indexWhere((Destination x) => x.chemin == c),
        ),
        child: PageShell(
          titre: d[actif].libelle,
          child: const SizedBox(height: 200),
        ),
      ),
    ),
    surcharges: <Override>[sansPersonneConnectee()],
    themeMode: theme,
  );
}

({double ecart, double cou})? _etat(WidgetTester tester) =>
    IndicateurLiquide.detachementDe(tester.element(find.byType(CoucheLiquide)));

/// Avance le temps, 2 ms a la fois, jusqu'a ce que [arret] soit vrai.
Future<void> _jusqua(
  WidgetTester tester,
  bool Function(({double ecart, double cou}) d) arret,
) async {
  for (int i = 0; i < 400; i++) {
    final ({double ecart, double cou})? d = _etat(tester);
    if (d != null && arret(d)) return;
    await tester.pump(const Duration(milliseconds: 2));
  }
  fail('etat du detachement jamais atteint');
}

/// La planche : la bande de la barre de chaque capture, une rangee par
/// variante, une colonne par temps.
Future<String> _planche(
  WidgetTester tester,
  String nom,
  List<List<String>> rangees,
) async {
  const double marge = 24;
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
    // La bande du bas : la barre flottante et son ombre.
    const double hBande = 104 * _densite;
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
          Rect.fromLTWH(0, i.height - hBande, l, hBande),
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
  group('Capture : liquide de matiere', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    final List<List<String>> rangees = <List<String>>[];

    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe_clair', AppLocale.ar, ThemeMode.light),
          ('arabe_sombre', AppLocale.ar, ThemeMode.dark),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, _vue, _densite);
        await tester.pumpWidget(_barre(theme));
        await stabiliser(tester);
        final List<String> rangee = <String>[];
        Future<void> prendre(String temps) async {
          final String c = await capturer(tester, 'matiere_${nom}_$temps');
          debugPrint('PNG $c ${_etat(tester)}');
          rangee.add(c);
        }

        await prendre('1_repos');
        await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
        await tester.pump();
        await tester.pump();
        // Une seule forme, puis le cercle est tire : le cou se forme.
        await _jusqua(tester, (d) => d.ecart < 0);
        await _jusqua(tester, (d) => d.ecart > 1 && d.cou > 0);
        await prendre('2_cou_forme');
        await _jusqua(tester, (d) => d.cou > 0 && d.cou < 0.15);
        await prendre('3_cou_aminci');
        await _jusqua(tester, (d) => d.cou == 0);
        await prendre('4_rupture');
        await tester.pump(const Duration(milliseconds: 40));
        await prendre('5_rebond');
        await tester.pumpAndSettle();
        rangees.add(rangee);
        if (nom == 'clair') {
          // Le retour vers un onglet : le cercle s'approche, un cou se
          // forme, il est absorbe.
          final List<String> retour = <String>[];
          Future<void> prendreRetour(String temps) async {
            final String c = await capturer(
              tester,
              'matiere_retour_${nom}_$temps',
            );
            debugPrint('PNG $c ${_etat(tester)}');
            retour.add(c);
          }

          await prendreRetour('1_repos');
          await tester.tap(find.bySemanticsLabel(t.nav.tuteur.accueil));
          await tester.pump();
          await tester.pump();
          await _jusqua(tester, (d) => d.ecart > 0 && d.cou > 0.15);
          await prendreRetour('2_cou_forme');
          await _jusqua(tester, (d) => d.ecart < -6);
          await prendreRetour('3_absorbe');
          await tester.pumpAndSettle();
          await prendreRetour('4_repos');
          rangees.add(retour);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('planche', (WidgetTester tester) async {
      fixerVueCapture(tester, _vue, 1);
      debugPrint(
        'PNG ${await _planche(tester, 'planche_matiere_5_temps', rangees)}',
      );
    });
  });
}
