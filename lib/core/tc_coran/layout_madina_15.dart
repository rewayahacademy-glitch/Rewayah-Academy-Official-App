import 'package:flutter/foundation.dart';

import '../theme/app_typography.dart' show AppFontFamily;
import 'donnees/layout_madina_15.g.dart';
import 'port_layout_mushaf.dart';

/// La famille de police du texte de la mise en page de Medine (MUSHAF-15L).
///
/// **Un choix par constante, jamais deux endroits.** KFGQPC UthmanicHafs v3.0
/// porte tous les codepoints du texte officiel et ses signes de pause ;
/// `UthmanTahaNaskh`, qui sert le reste de l'application, n'en porte pas 16
/// (alef wasla, tanwin ouvert, petites lettres) ni aucun signe de pause.
///
/// L'entree `pubspec.yaml` qui declare cette famille est decrite dans
/// `docs/current/coran/PUBSPEC_MUSHAF_15L.md` (decision du directeur du
/// 11/10/2026). Tant qu'elle n'y est pas, Flutter retombe sur la police de
/// secours : la composition reste juste, les glyphes manquants sont ceux de la
/// police de secours. Les tests et les captures chargent le fichier de police
/// avec `FontLoader` sous ce meme nom.
abstract final class FamilleMushaf15L {
  /// Le nom de la famille declaree dans `pubspec.yaml`.
  static const String nom = AppFontFamily.arabeMushaf;

  /// Le fichier de police, pour `FontLoader` dans les tests et les captures.
  static const String fichier = 'assets/fonts/UthmanicHafs-v-3.0.ttf';
}

/// Le nombre de lignes d'une page ordinaire du Mushaf de Medine.
const int lignesPageMadina15 = 15;

/// Le nombre de lignes des deux premieres pages (Al-Fatiha, debut d'Al-Baqara).
const int lignesPagesDebutMadina15 = 8;

/// La proportion du cadre de texte, largeur divisee par hauteur.
const double ratioCadreMadina15 = 0.7;

/// Le nom arabe de la sourate [numero] (1 a 114), tel que le KFGQPC l'ecrit.
String nomSourateMadina15(int numero) => layoutMadina15NomsSourates[numero - 1];

/// La mise en page du Mushaf de Medine : 604 pages de 15 lignes (8 pour les
/// pages 1 et 2), d'apres le texte KFGQPC UthmanicHafs v3.0 et ses sauts de
/// ligne (paquet `@quran.ws/text` 0.1.0, valides contre `hafsData_v2-0.csv`
/// du KFGQPC). Voir `donnees/LISEZMOI.md`.
///
/// Une source **reelle** : elle ne devine ni ne rearrange rien, elle lit ce que
/// le generateur (`tool/generer_layout_madina_15.dart`) a ecrit. Les sources de
/// donnees sont des chaines compactes, analysees page par page a la demande.
class LayoutMadina15 implements PortLayoutMushaf {
  /// Cree la source sur [pages] (les 604 chaines generees par defaut).
  // ignore: prefer_initializing_formals
  LayoutMadina15({List<String> pages = layoutMadina15Pages}) : _pages = pages;

  final List<String> _pages;
  final Map<int, LayoutPage> _cache = <int, LayoutPage>{};

  @override
  Future<DisponibiliteLayout> disponibilite() async =>
      DisponibiliteLayout.fidele;

  @override
  Future<LayoutPage?> layoutDe(int numeroPage) async => depuis(numeroPage);

  /// La page [numeroPage], ou `null` hors de 1 a 604. Synchrone : les donnees
  /// sont en memoire.
  LayoutPage? depuis(int numeroPage) {
    if (numeroPage < 1 || numeroPage > _pages.length) return null;
    return _cache.putIfAbsent(
      numeroPage,
      () => analyserPageMadina15(numeroPage, _pages[numeroPage - 1]),
    );
  }
}

/// Analyse une page generee (format dans `tool/generer_layout_madina_15.dart`).
@visibleForTesting
LayoutPage analyserPageMadina15(int numeroPage, String donnee) {
  final List<String> brut = donnee.split('\n');
  final List<String> entete = brut.first.split(';');
  final List<int> quarts = entete.length > 3 && entete[3].isNotEmpty
      ? entete[3].split(',').map(int.parse).toList(growable: false)
      : const <int>[];
  final List<SectionLigne> lignes = <SectionLigne>[];
  for (int i = 1; i < brut.length; i++) {
    final String ligne = brut[i];
    final int numero = i;
    switch (ligne[0]) {
      case 'H':
        lignes.add(
          SectionLigne(
            numero: numero,
            segments: const <SegmentVersetLigne>[],
            centree: true,
            type: TypeLigneMushaf.enteteSourate,
            sourate: int.parse(ligne.substring(2)),
          ),
        );
      case 'B':
        lignes.add(
          SectionLigne(
            numero: numero,
            segments: const <SegmentVersetLigne>[],
            centree: true,
            type: TypeLigneMushaf.basmala,
            sourate: int.parse(ligne.substring(2)),
          ),
        );
      default:
        final int sep = ligne.indexOf(';', 2);
        final int flags = int.parse(ligne.substring(2, sep));
        lignes.add(
          SectionLigne(
            numero: numero,
            segments: <SegmentVersetLigne>[
              for (final String s in ligne.substring(sep + 1).split('¦'))
                _segment(s),
            ],
            centree: flags & 1 != 0,
            termineLaSourate: flags & 2 != 0,
          ),
        );
    }
  }
  return LayoutPage(
    numeroPage: numeroPage,
    lignes: List<SectionLigne>.unmodifiable(lignes),
    nombreLignes: numeroPage <= 2
        ? lignesPagesDebutMadina15
        : lignesPageMadina15,
    ratioLargeurSurHauteur: ratioCadreMadina15,
    juz: int.parse(entete[0]),
    hizb: int.parse(entete[1]),
    rubDansHizb: int.parse(entete[2]),
    quartsDebutes: quarts,
  );
}

SegmentVersetLigne _segment(String s) {
  final int a = s.indexOf(':');
  final int b = s.indexOf(':', a + 1);
  final int c = s.indexOf(':', b + 1);
  final int f = int.parse(s.substring(b + 1, c));
  return SegmentVersetLigne(
    sourate: int.parse(s.substring(0, a)),
    ayah: int.parse(s.substring(a + 1, b)),
    texte: s.substring(c + 1),
    debuteLAyah: f & 1 != 0,
    termineLAyah: f & 2 != 0,
  );
}

/// La basmala imprimee (le texte du verset 1:1, sans numero), pour la ligne
/// qui ouvre chaque sourate sauf Al-Fatiha et At-Tawba.
final String basmalaMadina15 = analyserPageMadina15(
  1,
  layoutMadina15Pages.first,
).lignes[1].segments.first.texte;
