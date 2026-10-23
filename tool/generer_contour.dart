// Genere `lib/core/marque/contour_traces.g.dart` depuis les SVG du directeur.
//
//   dart run tool/generer_contour.dart            (ecrit le fichier)
//   dart run tool/generer_contour.dart --verifier (echoue s'il n'est pas a jour)
//
// Aucun redessin : chaque attribut `d` est recopie OCTET POUR OCTET depuis
// `assets/brand/logo/violet/symbole-contour.svg`. Ce fichier est un trait
// (`stroke`), pas un aplat : le generateur lit aussi son `stroke-width` et
// refuse toute autre construction (transformation, masque, `fill`, jointure
// autre que ronde, arcs). Il verifie que `blanc/` et `encre/` portent les memes
// traces, la meme epaisseur et le meme `viewBox` (seule la couleur du trait
// change).
import 'dart:io';

import 'package:rewayah_academy/core/marque/trace_svg.dart';

/// Le fichier genere, relatif a la racine du depot.
const String cheminGenere = 'lib/core/marque/contour_traces.g.dart';

/// Le fichier rendu.
const String fichierContour = 'symbole-contour.svg';

const List<String> dossiersCouleur = <String>['violet', 'blanc', 'encre'];

final RegExp _viewBox = RegExp(r'viewBox="([^"]*)"');
final RegExp _balisePath = RegExp(r'<path\b[^>]*>');
final RegExp _attributD = RegExp(r'\sd="([^"]*)"');
final RegExp _epaisseur = RegExp(r'\sstroke-width="([^"]*)"');
final RegExp _jointure = RegExp(r'\sstroke-linejoin="([^"]*)"');

/// Ce qu'un fichier de contour livre contient d'utile au rendu.
class ContourLivre {
  const ContourLivre(this.largeur, this.hauteur, this.epaisseur, this.traces);

  final String largeur;
  final String hauteur;
  final String epaisseur;
  final List<String> traces;

  @override
  bool operator ==(Object other) =>
      other is ContourLivre &&
      other.largeur == largeur &&
      other.hauteur == hauteur &&
      other.epaisseur == epaisseur &&
      _memes(other.traces, traces);

  @override
  int get hashCode => Object.hash(largeur, hauteur, epaisseur, traces.length);
}

bool _memes(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Lit un fichier de contour ; leve une [FormatException] sur ce qu'il ne
/// reproduirait pas a l'identique.
ContourLivre lireContour(String contenu, String nom) {
  final RegExpMatch? boite = _viewBox.firstMatch(contenu);
  if (boite == null) throw FormatException('viewBox absent', nom);
  final List<String> v = boite.group(1)!.trim().split(RegExp(r'[\s,]+'));
  if (v.length != 4 || v[0] != '0' || v[1] != '0') {
    throw FormatException('viewBox non pris en charge', nom);
  }
  if (contenu.contains('transform="') ||
      contenu.contains('clip-path') ||
      contenu.contains('<mask') ||
      contenu.contains('<g')) {
    throw FormatException('construction SVG non reproduite', nom);
  }
  final List<String> traces = <String>[];
  String? epaisseur;
  for (final RegExpMatch balise in _balisePath.allMatches(contenu)) {
    final String texte = balise.group(0)!;
    final RegExpMatch? d = _attributD.firstMatch(texte);
    final RegExpMatch? e = _epaisseur.firstMatch(texte);
    final RegExpMatch? j = _jointure.firstMatch(texte);
    if (d == null || e == null || !texte.contains('stroke="')) {
      throw FormatException('un trace doit etre un trait', nom);
    }
    if (texte.contains(' fill=') && !texte.contains('fill="none"')) {
      throw FormatException('un aplat n\'est pas reproduit', nom);
    }
    if (j == null || j.group(1) != 'round') {
      throw FormatException('jointure autre que ronde', nom);
    }
    if (epaisseur != null && epaisseur != e.group(1)) {
      throw FormatException('epaisseurs differentes', nom);
    }
    epaisseur = e.group(1);
    lireTraceSvg(d.group(1)!);
    traces.add(d.group(1)!);
  }
  if (traces.isEmpty || epaisseur == null) {
    throw FormatException('aucun trace', nom);
  }
  return ContourLivre(v[2], v[3], epaisseur, traces);
}

String genererSourceContour(String racine) {
  ContourLivre? reference;
  for (final String dossier in dossiersCouleur) {
    final String chemin = 'assets/brand/logo/$dossier/$fichierContour';
    final ContourLivre lu = lireContour(
      File('$racine/$chemin').readAsStringSync(),
      chemin,
    );
    if (reference == null) {
      reference = lu;
    } else if (lu != reference) {
      throw FormatException(
        'les traces different de violet/$fichierContour',
        chemin,
      );
    }
  }
  final ContourLivre s = reference!;
  final StringBuffer sortie = StringBuffer()
    ..writeln(
      '// GENERE par tool/generer_contour.dart : ne pas modifier a la main.',
    )
    ..writeln('//')
    ..writeln('// Traces recopies octet pour octet depuis assets/brand/logo/')
    ..writeln('// (livraison du directeur, 10/10/2026). Regenerer :')
    ..writeln('//   dart run tool/generer_contour.dart')
    ..writeln()
    ..writeln("import 'dessin_contour.dart';")
    ..writeln()
    ..writeln('/// `assets/brand/logo/violet/$fichierContour`.')
    ..writeln('const DessinContour symboleContour = DessinContour(')
    ..writeln("  source: 'assets/brand/logo/violet/$fichierContour',")
    ..writeln('  largeur: ${s.largeur},')
    ..writeln('  hauteur: ${s.hauteur},')
    ..writeln('  epaisseur: ${s.epaisseur},')
    ..writeln('  traces: <String>[');
  for (final String d in s.traces) {
    sortie.writeln("    r'$d',");
  }
  sortie
    ..writeln('  ],')
    ..writeln(');');
  return sortie.toString();
}

void main(List<String> arguments) {
  final String racine = Directory.current.path;
  final String source = genererSourceContour(racine);
  final File cible = File('$racine/$cheminGenere');
  if (arguments.contains('--verifier')) {
    if (!cible.existsSync() || cible.readAsStringSync() != source) {
      stderr.writeln(
        '$cheminGenere n\'est pas a jour : dart run tool/generer_contour.dart',
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
