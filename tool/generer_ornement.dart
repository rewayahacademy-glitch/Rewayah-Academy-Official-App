// Genere `lib/core/marque/ornement_traces.g.dart` depuis les SVG du directeur.
//
//   dart run tool/generer_ornement.dart            (ecrit le fichier)
//   dart run tool/generer_ornement.dart --verifier (echoue s'il n'est pas a jour)
//
// Aucun redessin : chaque attribut `d` est recopie OCTET POUR OCTET depuis
// `assets/brand/logo/violet/ornement-plein.svg` et `ornement-contour.svg`. Le
// contour est livre avec un `<mask>` (trace epais, forme pleine retiree) : la
// forme du masque est recopiee aussi, et le rendu la retire comme le fichier.
// Le generateur verifie que `blanc/` et `encre/` portent les memes traces (seul
// le `fill` change) et que chaque trace se lit sans commande inconnue.
import 'dart:io';

import 'package:rewayah_academy/core/marque/trace_svg.dart';

/// Le fichier genere, relatif a la racine du depot.
const String cheminGenere = 'lib/core/marque/ornement_traces.g.dart';

/// Les ornements rendus : nom de constante, fichier.
const Map<String, String> ornements = <String, String>{
  'ornementPlein': 'ornement-plein.svg',
  'ornementContour': 'ornement-contour.svg',
};

const List<String> dossiersCouleur = <String>['violet', 'blanc', 'encre'];

final RegExp _viewBox = RegExp(r'viewBox="([^"]*)"');
final RegExp _trace = RegExp(r'<path\b[^>]*?\sd="([^"]*)"');

/// Ce qu'un fichier d'ornement livre contient d'utile au rendu.
class OrnementLivre {
  const OrnementLivre(this.largeur, this.hauteur, this.trace, this.masque);

  final String largeur;
  final String hauteur;
  final String trace;
  final String? masque;

  @override
  bool operator ==(Object other) =>
      other is OrnementLivre &&
      other.largeur == largeur &&
      other.hauteur == hauteur &&
      other.trace == trace &&
      other.masque == masque;

  @override
  int get hashCode => Object.hash(largeur, hauteur, trace, masque);
}

OrnementLivre lireOrnement(String contenu, String nom) {
  final RegExpMatch? boite = _viewBox.firstMatch(contenu);
  if (boite == null) throw FormatException('viewBox absent', nom);
  final List<String> v = boite.group(1)!.trim().split(RegExp(r'[\s,]+'));
  if (v.length != 4 || v[0] != '0' || v[1] != '0') {
    throw FormatException('viewBox non pris en charge', nom);
  }
  if (contenu.contains('transform="') ||
      contenu.contains('clip-path') ||
      contenu.contains('stroke=')) {
    throw FormatException('construction SVG non reproduite', nom);
  }
  final List<String> traces = <String>[
    for (final RegExpMatch m in _trace.allMatches(contenu)) m.group(1)!,
  ];
  for (final String d in traces) {
    lireTraceSvg(d);
  }
  final bool masque = contenu.contains('<mask');
  if (masque) {
    // Le masque est un rectangle blanc et la forme pleine en noir ; le trace
    // peint vient ensuite, masque par cette forme.
    if (traces.length != 2 || !contenu.contains('mask="url(')) {
      throw FormatException('masque inattendu', nom);
    }
    return OrnementLivre(v[2], v[3], traces[1], traces[0]);
  }
  if (traces.length != 1) throw FormatException('un seul trace attendu', nom);
  return OrnementLivre(v[2], v[3], traces[0], null);
}

String genererSourceOrnement(String racine) {
  final StringBuffer sortie = StringBuffer()
    ..writeln(
      '// GENERE par tool/generer_ornement.dart : ne pas modifier a la main.',
    )
    ..writeln('//')
    ..writeln('// Traces recopies octet pour octet depuis assets/brand/logo/')
    ..writeln('// (livraison du directeur, 10/10/2026). Regenerer :')
    ..writeln('//   dart run tool/generer_ornement.dart')
    ..writeln()
    ..writeln("import 'dessin_ornement.dart';");
  for (final MapEntry<String, String> o in ornements.entries) {
    OrnementLivre? reference;
    for (final String dossier in dossiersCouleur) {
      final String chemin = 'assets/brand/logo/$dossier/${o.value}';
      final OrnementLivre lu = lireOrnement(
        File('$racine/$chemin').readAsStringSync(),
        chemin,
      );
      if (reference == null) {
        reference = lu;
      } else if (lu != reference) {
        throw FormatException(
          'les traces different de violet/${o.value}',
          chemin,
        );
      }
    }
    final OrnementLivre s = reference!;
    sortie
      ..writeln()
      ..writeln('/// `assets/brand/logo/violet/${o.value}`.')
      ..writeln('const DessinOrnement ${o.key} = DessinOrnement(')
      ..writeln("  source: 'assets/brand/logo/violet/${o.value}',")
      ..writeln('  largeur: ${s.largeur},')
      ..writeln('  hauteur: ${s.hauteur},')
      ..writeln("  trace: r'${s.trace}',");
    if (s.masque != null) sortie.writeln("  masque: r'${s.masque}',");
    sortie.writeln(');');
  }
  return sortie.toString();
}

void main(List<String> arguments) {
  final String racine = Directory.current.path;
  final String source = genererSourceOrnement(racine);
  final File cible = File('$racine/$cheminGenere');
  if (arguments.contains('--verifier')) {
    if (!cible.existsSync() || cible.readAsStringSync() != source) {
      stderr.writeln(
        '$cheminGenere n\'est pas a jour : dart run tool/generer_ornement.dart',
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
