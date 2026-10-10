// Genere `lib/core/marque/logo_traces.g.dart` depuis les SVG du directeur.
//
//   dart run tool/generer_logo.dart          (ecrit le fichier)
//   dart run tool/generer_logo.dart --verifier (echoue s'il n'est pas a jour)
//
// Aucun redessin : chaque attribut `d` est recopie OCTET POUR OCTET depuis
// `assets/brand/logo/violet/<variante>.svg`, avec son `viewBox` et sa regle de
// remplissage. Le generateur verifie aussi que les dossiers `blanc/` et
// `encre/` portent exactement les memes traces (seul le `fill` change), et que
// chaque trace se lit sans commande inconnue (`lib/core/marque/trace_svg.dart`).
import 'dart:io';

import 'package:rewayah_academy/core/marque/trace_svg.dart';

/// Le fichier genere, relatif a la racine du depot.
const String cheminGenere = 'lib/core/marque/logo_traces.g.dart';

/// Les variantes rendues par l'application : nom de constante, fichier.
const Map<String, String> variantesLogo = <String, String>{
  'logoHorizontal': 'logo-horizontal.svg',
  'logoVertical': 'logo-vertical.svg',
  'logoSymbole': 'symbole-plein.svg',
};

/// Les trois dossiers de couleur livres ; le premier fait reference.
const List<String> dossiersCouleur = <String>['violet', 'blanc', 'encre'];

/// Ce qu'un fichier SVG livre contient d'utile au rendu.
class SvgLivre {
  /// Cree la lecture d'un fichier.
  const SvgLivre({
    required this.largeur,
    required this.hauteur,
    required this.pairImpair,
    required this.traces,
  });

  /// La largeur du `viewBox`.
  final String largeur;

  /// La hauteur du `viewBox`.
  final String hauteur;

  /// `fill-rule="evenodd"` present.
  final bool pairImpair;

  /// Les attributs `d`, mot pour mot, dans l'ordre du fichier.
  final List<String> traces;
}

final RegExp _viewBox = RegExp(r'viewBox="([^"]*)"');
final RegExp _trace = RegExp(r'<path\b[^>]*?\sd="([^"]*)"');
final RegExp _transformation = RegExp(r'\btransform="');

/// Lit un SVG livre. Leve si le fichier sort de ce que le rendu sait
/// reproduire a l'identique (`viewBox` decale, transformation, masque).
SvgLivre lireSvgLivre(String contenu, String nom) {
  final RegExpMatch? boite = _viewBox.firstMatch(contenu);
  if (boite == null) {
    throw FormatException('viewBox absent', nom);
  }
  final List<String> valeurs = boite.group(1)!.trim().split(RegExp(r'[\s,]+'));
  if (valeurs.length != 4 || valeurs[0] != '0' || valeurs[1] != '0') {
    throw FormatException(
      'viewBox non pris en charge : ${boite.group(1)}',
      nom,
    );
  }
  if (_transformation.hasMatch(contenu) ||
      contenu.contains('<mask') ||
      contenu.contains('clip-path') ||
      contenu.contains('stroke=')) {
    throw FormatException(
      'construction SVG non reproduite a l\'identique',
      nom,
    );
  }
  final List<String> traces = <String>[
    for (final RegExpMatch m in _trace.allMatches(contenu)) m.group(1)!,
  ];
  if (traces.isEmpty) {
    throw FormatException('aucun trace', nom);
  }
  for (final String d in traces) {
    lireTraceSvg(d);
  }
  return SvgLivre(
    largeur: valeurs[2],
    hauteur: valeurs[3],
    pairImpair: contenu.contains('fill-rule="evenodd"'),
    traces: traces,
  );
}

/// Le source Dart genere, depuis le depot dont [racine] est la racine.
String genererSourceLogo(String racine) {
  final StringBuffer sortie = StringBuffer()
    ..writeln(
      '// GENERE par tool/generer_logo.dart : ne pas modifier a la main.',
    )
    ..writeln('//')
    ..writeln('// Traces recopies octet pour octet depuis assets/brand/logo/')
    ..writeln('// (livraison du directeur, 10/10/2026). Regenerer :')
    ..writeln('//   dart run tool/generer_logo.dart')
    ..writeln()
    ..writeln("import 'dessin_logo.dart';");
  for (final MapEntry<String, String> variante in variantesLogo.entries) {
    SvgLivre? reference;
    for (final String dossier in dossiersCouleur) {
      final String chemin = 'assets/brand/logo/$dossier/${variante.value}';
      final SvgLivre lu = lireSvgLivre(
        File('$racine/$chemin').readAsStringSync(),
        chemin,
      );
      if (reference == null) {
        reference = lu;
        continue;
      }
      final bool memes =
          lu.largeur == reference.largeur &&
          lu.hauteur == reference.hauteur &&
          lu.pairImpair == reference.pairImpair &&
          lu.traces.length == reference.traces.length &&
          <int>[for (int i = 0; i < lu.traces.length; i++) i]
              .every((int i) => lu.traces[i] == reference!.traces[i]);
      if (!memes) {
        throw FormatException(
          'les traces different de violet/${variante.value}',
          chemin,
        );
      }
    }
    final SvgLivre svg = reference!;
    sortie
      ..writeln()
      ..writeln('/// `assets/brand/logo/violet/${variante.value}`.')
      ..writeln('const DessinLogo ${variante.key} = DessinLogo(')
      ..writeln("  source: 'assets/brand/logo/violet/${variante.value}',")
      ..writeln('  largeur: ${svg.largeur},')
      ..writeln('  hauteur: ${svg.hauteur},')
      ..writeln('  pairImpair: ${svg.pairImpair},')
      ..writeln('  traces: <String>[');
    for (final String d in svg.traces) {
      sortie.writeln("    r'$d',");
    }
    sortie
      ..writeln('  ],')
      ..writeln(');');
  }
  return sortie.toString();
}

void main(List<String> arguments) {
  final String racine = Directory.current.path;
  final String source = genererSourceLogo(racine);
  final File cible = File('$racine/$cheminGenere');
  if (arguments.contains('--verifier')) {
    if (!cible.existsSync() || cible.readAsStringSync() != source) {
      stderr.writeln(
        '$cheminGenere n\'est pas a jour : '
        'dart run tool/generer_logo.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('$cheminGenere a jour.');
    return;
  }
  cible.writeAsStringSync(source);
  stdout.writeln('$cheminGenere ecrit.');
}
