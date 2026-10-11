// Outillage de test de la mise en page du Mushaf de Medine (MUSHAF-15L) : un
// corpus fabrique depuis les donnees de layout (le texte « Tanzil » n'est pas
// visible : il ne sert qu'a la semantique), la police KFGQPC chargee depuis le
// fichier (pubspec ne la declare pas encore), et le montage d'une page.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/donnees/layout_madina_15.g.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/layout_madina_15.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../capture/outil_capture.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart'
    show FauxNavigationCoran;

/// Charge UthmanicHafs sous le nom de la famille, comme le ferait `pubspec`.
Future<void> chargerPoliceMadina15() async {
  final FontLoader chargeur = FontLoader(FamilleMushaf15L.nom)
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(
          Uint8List.fromList(File(FamilleMushaf15L.fichier).readAsBytesSync()),
        ),
      ),
    );
  await chargeur.load();
}

/// Un corpus complet fabrique depuis le layout : les versets d'une page sont
/// ceux que la mise en page y pose. Le texte est celui de l'edition, pas celui
/// de Tanzil : il ne sert qu'aux tests.
class CorpusDepuisLayout implements PortCorpusCoran {
  /// Cree le corpus sur [source].
  CorpusDepuisLayout(this.source);

  /// La source des lignes.
  final LayoutMadina15 source;

  @override
  Future<List<SourateVM>> sourates() async => <SourateVM>[
    for (int i = 0; i < layoutMadina15NomsSourates.length; i++)
      SourateVM(
        numero: i + 1,
        nomArabe: layoutMadina15NomsSourates[i],
        nomTranslittere: 'Sourate ${i + 1}',
        mecquoise: true,
        nombreVersets: 1,
      ),
  ];

  @override
  Future<PageCorpus?> page(int numeroPage) async {
    final LayoutPage? p = source.depuis(numeroPage);
    if (p == null) return null;
    final Map<String, StringBuffer> textes = <String, StringBuffer>{};
    final List<String> ordre = <String>[];
    for (final SectionLigne l in p.lignes) {
      for (final SegmentVersetLigne s in l.segments) {
        final String cle = '${s.sourate}:${s.ayah}';
        if (!textes.containsKey(cle)) {
          textes[cle] = StringBuffer();
          ordre.add(cle);
        } else {
          textes[cle]!.write(' ');
        }
        textes[cle]!.write(s.texte);
      }
    }
    return PageCorpus(
      numero: numeroPage,
      juzNumero: p.juz,
      versets: <VersetCorpus>[
        for (final String cle in ordre)
          VersetCorpus(
            sourate: int.parse(cle.split(':')[0]),
            numero: int.parse(cle.split(':')[1]),
            texte: textes[cle].toString(),
            pageNumero: numeroPage,
          ),
      ],
    );
  }

  @override
  Future<PageCorpus?> pageDeAyah({required int sourate, required int ayah}) =>
      Future<PageCorpus?>.value(null);

  @override
  Future<int?> pageDeDebutDeSourate(int sourate) async => null;

  @override
  Future<int?> pageDeDebutDeJuz(int juz) async => null;

  @override
  Future<List<ResultatRechercheCoran>> rechercher(String requete) async =>
      const <ResultatRechercheCoran>[];
}

class _LecteurALaPage extends ControleurLectureCoran {
  _LecteurALaPage(this.page);

  final int page;

  @override
  EtatLectureCoran build() => EtatLectureCoran.ouverture(page: page);
}

/// Les surcharges qui posent la mise en page de Medine et un corpus complet,
/// le lecteur ouvert a la page [page].
List<Override> surchargesMadina15({required int page, bool miseEnPage = true}) {
  final LayoutMadina15 source = LayoutMadina15();
  return <Override>[
    portLayoutMushafProvider.overrideWithValue(
      miseEnPage ? source : const LayoutLignesIndisponible(),
    ),
    portCorpusCoranProvider.overrideWithValue(CorpusDepuisLayout(source)),
    lectureCoranProvider.overrideWith(() => _LecteurALaPage(page)),
  ];
}

/// Monte la vue du mushaf a la page [page], dans la fenetre [taille].
Future<void> monterPageMadina15(
  WidgetTester tester, {
  required int page,
  required Size taille,
  ThemeMode theme = ThemeMode.light,
  double echelleTexte = 1,
  bool miseEnPage = true,
  bool ecranComplet = false,
  Widget Function(Widget vue)? enrober,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      ecranComplet
          ? const MushafPage()
          : Scaffold(
              body: SizedBox(
                height: taille.height,
                child: (enrober ?? (Widget v) => v)(const VuePageMushaf()),
              ),
            ),
      surcharges: <Override>[
        ...surchargesMadina15(page: page, miseEnPage: miseEnPage),
        if (ecranComplet)
          portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
      ],
      themeMode: theme,
      echelleTexte: echelleTexte,
      interfaceMode: InterfaceMode.standard,
    ),
  );
  await stabiliser(tester);
}
