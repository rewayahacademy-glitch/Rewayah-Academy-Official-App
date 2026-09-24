// Revue : matrice de contraste WCAG calculee sur les SOURCES de app_palette.dart
// (base 3cf3544 et HEAD), hors Flutter. Usage :
//   dart contrastes_revue.dart <palette_base.dart> <palette_head.dart>
import 'dart:io';
import 'dart:math' as math;

double _lin(int c) {
  final double s = c / 255.0;
  return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double lum(int argb) =>
    0.2126 * _lin((argb >> 16) & 0xFF) +
    0.7152 * _lin((argb >> 8) & 0xFF) +
    0.0722 * _lin(argb & 0xFF);

double ratio(int a, int b) {
  final double la = lum(a), lb = lum(b);
  final double hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

class Theme {
  final Map<String, (int, int)> paires = <String, (int, int)>{};
  final Map<String, int> encres = <String, int>{};
  final Map<String, int> points = <String, int>{};
}

String hex(int v) => '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Map<String, Theme> lire(String chemin) {
  final String src = File(chemin).readAsStringSync();
  final Map<String, Theme> out = <String, Theme>{};
  for (final String f in <String>['claire', 'sombre']) {
    final int debut = src.indexOf('factory AppPalette.$f()');
    final int fin = src.indexOf('teintesIdentite:', debut);
    final String bloc = src.substring(debut, fin);
    final Theme t = Theme();
    final RegExp paire = RegExp(
      r'(\w+):\s*AppColorPair\(\s*background:\s*Color\(0x([0-9A-Fa-f]{8})\),\s*onBackground:\s*Color\(0x([0-9A-Fa-f]{8})\)',
    );
    for (final RegExpMatch m in paire.allMatches(bloc)) {
      t.paires[m.group(1)!] = (int.parse(m.group(2)!, radix: 16), int.parse(m.group(3)!, radix: 16));
    }
    final RegExp encre = RegExp(r'(\w+):\s*AppInkColor\(Color\(0x([0-9A-Fa-f]{8})\)\)');
    for (final RegExpMatch m in encre.allMatches(bloc)) {
      t.encres[m.group(1)!] = int.parse(m.group(2)!, radix: 16);
    }
    final RegExp point = RegExp(r'(\w+):\s*AppIndicatorColor\(Color\(0x([0-9A-Fa-f]{8})\)\)');
    for (final RegExpMatch m in point.allMatches(bloc)) {
      t.points[m.group(1)!] = int.parse(m.group(2)!, radix: 16);
    }
    out[f] = t;
  }
  return out;
}

List<(int, int)> teintes(String chemin, String nom) {
  final String src = File(chemin).readAsStringSync();
  final int d = src.indexOf('const List<AppColorPair> $nom');
  final int f = src.indexOf('];', d);
  return RegExp(r'background:\s*Color\(0x([0-9A-Fa-f]{8})\),\s*onBackground:\s*Color\(0x([0-9A-Fa-f]{8})\)')
      .allMatches(src.substring(d, f))
      .map((RegExpMatch m) => (int.parse(m.group(1)!, radix: 16), int.parse(m.group(2)!, radix: 16)))
      .toList();
}

void main(List<String> args) {
  final Map<String, Map<String, Theme>> versions = <String, Map<String, Theme>>{
    'base': lire(args[0]),
    'head': lire(args[1]),
  };
  const List<String> encresTexte = <String>[
    'inkStrong', 'inkMuted', 'inkFaint', 'inkAccent', 'inkAlert', 'inkSuccess', 'inkWarning',
  ];
  // Toutes les surfaces sur lesquelles une encre libre peut se poser.
  const List<String> fonds = <String>[
    'surfaceCanvas', 'surfaceRaised', 'surfaceSunken', 'surfaceOverlay', 'surfaceMiseEnAvant',
    'washFamily', 'washAccent', 'washSuccess', 'washWarning', 'washAlert', 'surfaceActionDouce',
    'surfaceQuran',
  ];
  for (final String theme in <String>['claire', 'sombre']) {
    final Theme b = versions['base']![theme]!;
    final Theme h = versions['head']![theme]!;
    stdout.writeln('==================== $theme ====================');
    stdout.writeln('--- 1. Paires fond/texte (seuil 4,5) : base -> head');
    for (final String n in h.paires.keys) {
      final (int, int) p = h.paires[n]!;
      final double r = ratio(p.$1, p.$2);
      final String avant = b.paires.containsKey(n)
          ? ratio(b.paires[n]!.$1, b.paires[n]!.$2).toStringAsFixed(2)
          : 'nouveau';
      stdout.writeln('${r < 4.5 ? "ECHEC " : "      "}$n ${hex(p.$1)}/${hex(p.$2)} : $avant -> ${r.toStringAsFixed(2)}');
    }
    stdout.writeln('--- 2. Encres x surfaces (texte 4,5) : seulement < 4,5 a HEAD, avec la valeur base');
    for (final String e in encresTexte) {
      for (final String f in fonds) {
        if (!h.paires.containsKey(f)) continue;
        final double r = ratio(h.encres[e]!, h.paires[f]!.$1);
        if (r < 4.5) {
          final String avant = (b.paires.containsKey(f) && b.encres.containsKey(e))
              ? ratio(b.encres[e]!, b.paires[f]!.$1).toStringAsFixed(2)
              : 'n/a';
          stdout.writeln('  $e ${hex(h.encres[e]!)} sur $f ${hex(h.paires[f]!.$1)} : base $avant -> head ${r.toStringAsFixed(2)}');
        }
      }
    }
    stdout.writeln('--- 3. Encres x surfaces : regressions (base >= 4,5, head < 4,5) ou baisses > 0,5');
    for (final String e in encresTexte) {
      for (final String f in fonds) {
        if (!h.paires.containsKey(f) || !b.paires.containsKey(f)) continue;
        final double rb = ratio(b.encres[e]!, b.paires[f]!.$1);
        final double rh = ratio(h.encres[e]!, h.paires[f]!.$1);
        if ((rb >= 4.5 && rh < 4.5) || (rb - rh > 0.5)) {
          stdout.writeln('  $e sur $f : ${rb.toStringAsFixed(2)} -> ${rh.toStringAsFixed(2)}');
        }
      }
    }
    stdout.writeln('--- 4. Composants (3:1) : borderStrong, borderResting, surfacePrimary, surfaceActionDouce, inkAccent(focus) sur les fonds');
    for (final String c in <String>['borderStrong', 'borderResting', 'borderHairline']) {
      for (final String f in fonds) {
        if (!h.paires.containsKey(f)) continue;
        final double r = ratio(h.encres[c]!, h.paires[f]!.$1);
        if (r < 3) stdout.writeln('  $c ${hex(h.encres[c]!)} sur $f ${hex(h.paires[f]!.$1)} : ${r.toStringAsFixed(2)}');
      }
    }
    for (final String c in <String>['surfacePrimary', 'surfaceActionDouce']) {
      for (final String f in <String>['surfaceCanvas', 'surfaceRaised', 'surfaceSunken', 'surfaceOverlay', 'surfaceMiseEnAvant', 'surfaceInverse']) {
        final double r = ratio(h.paires[c]!.$1, h.paires[f]!.$1);
        stdout.writeln('  ${r < 3 ? "<3 " : "   "}$c ${hex(h.paires[c]!.$1)} contre $f ${hex(h.paires[f]!.$1)} : ${r.toStringAsFixed(2)}');
      }
    }
    for (final String f in <String>['surfaceCanvas', 'surfaceRaised', 'surfaceActionDouce', 'washAccent']) {
      final double r = ratio(h.encres['inkAccent']!, h.paires[f]!.$1);
      stdout.writeln('     inkAccent (anneau de focus / soulignement) sur $f : ${r.toStringAsFixed(2)}');
    }
    stdout.writeln('--- 5. Points de statut (3:1) sur toutes les surfaces');
    for (final String p in h.points.keys) {
      for (final String f in fonds) {
        if (!h.paires.containsKey(f)) continue;
        final double r = ratio(h.points[p]!, h.paires[f]!.$1);
        if (r < 3) stdout.writeln('  point $p ${hex(h.points[p]!)} sur $f ${hex(h.paires[f]!.$1)} : ${r.toStringAsFixed(2)}');
      }
    }
    stdout.writeln('--- 6. Valeurs figees : surfaceQuran base ${hex(b.paires['surfaceQuran']!.$1)}/${hex(b.paires['surfaceQuran']!.$2)} head ${hex(h.paires['surfaceQuran']!.$1)}/${hex(h.paires['surfaceQuran']!.$2)}');
  }
  for (final String nom in <String>['_teintesIdentiteClaires', '_teintesIdentiteSombres']) {
    final List<(int, int)> tb = teintes(args[0], nom);
    final List<(int, int)> th = teintes(args[1], nom);
    double mini = 99;
    for (final (int, int) t in th) {
      mini = math.min(mini, ratio(t.$1, t.$2));
    }
    stdout.writeln('--- teintes $nom : ${th.length} paires, identiques a la base : ${tb.toString() == th.toString()}, min ${mini.toStringAsFixed(2)}');
  }
}
