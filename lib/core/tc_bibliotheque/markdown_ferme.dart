// PX-BD-SUPPORT : l'analyseur du Markdown FERME des supports que Praxis
// redige, cote application. Meme grammaire, meme resultat que l'analyseur du
// serveur (`supabase/functions/_shared/support/markdown_ferme.ts`) : les deux
// passent les memes vecteurs (`vecteurs.json`), et un cas qui differe est
// rouge (`test/core/tc_bibliotheque/markdown_ferme_test.dart`).
//
// Admis : titres `#`, `##`, `###`, paragraphes, listes a puces et numerotees
// (un seul niveau), gras `**x**`, italique `*x*`, citation `> `, separateur
// `---`. Refuse, avec son code : balise HTML, lien, image, tableau, code,
// barre, marque non fermee ou imbriquee, liste a deux niveaux, caractere de
// commande ou de surcharge du sens de lecture. Aucune « reparation » : ce que
// le serveur a laisse passer se lit, le reste est refuse ici aussi.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Un morceau de texte d'un paragraphe.
@immutable
sealed class InlineMd {
  const InlineMd(this.texte);

  /// Le texte du morceau, sans ses marques.
  final String texte;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is InlineMd &&
      other.texte == texte;

  @override
  int get hashCode => Object.hash(runtimeType, texte);
}

/// Du texte courant.
final class TexteMd extends InlineMd {
  /// Cree le morceau.
  const TexteMd(super.texte);
}

/// Du gras.
final class GrasMd extends InlineMd {
  /// Cree le morceau.
  const GrasMd(super.texte);
}

/// De l'italique.
final class ItaliqueMd extends InlineMd {
  /// Cree le morceau.
  const ItaliqueMd(super.texte);
}

/// Un bloc du document.
@immutable
sealed class BlocMd {
  const BlocMd();
}

/// Un titre (niveau 1 a 3).
final class TitreMd extends BlocMd {
  /// Cree le titre.
  const TitreMd(this.niveau, this.inlines);

  /// Le niveau, de 1 a 3.
  final int niveau;

  /// Son texte.
  final List<InlineMd> inlines;
}

/// Un paragraphe.
final class ParagrapheMd extends BlocMd {
  /// Cree le paragraphe.
  const ParagrapheMd(this.inlines);

  /// Son texte.
  final List<InlineMd> inlines;
}

/// Une liste a puces.
final class PucesMd extends BlocMd {
  /// Cree la liste.
  const PucesMd(this.items);

  /// Ses elements.
  final List<List<InlineMd>> items;
}

/// Une liste numerotee.
final class NumeroteeMd extends BlocMd {
  /// Cree la liste.
  const NumeroteeMd(this.debut, this.items);

  /// Le premier numero.
  final int debut;

  /// Ses elements.
  final List<List<InlineMd>> items;
}

/// Une citation.
final class CitationMd extends BlocMd {
  /// Cree la citation.
  const CitationMd(this.inlines);

  /// Son texte.
  final List<InlineMd> inlines;
}

/// Un separateur.
final class SeparateurMd extends BlocMd {
  /// Cree le separateur.
  const SeparateurMd();
}

/// Pourquoi un texte est refuse.
enum CodeRefusMd {
  /// Rien a lire.
  vide,

  /// Plus de 100 000 octets.
  tropLong,

  /// Une ligne de plus de 5 000 signes.
  ligneTropLongue,

  /// Plus de 2 000 blocs.
  tropDeBlocs,

  /// Un caractere de commande ou de surcharge du sens de lecture.
  caractereInterdit,

  /// Une balise HTML.
  html,

  /// Un lien.
  lien,

  /// Une image.
  image,

  /// Un tableau.
  tableau,

  /// Du code.
  code,

  /// Du texte barre.
  barre,

  /// Un gras ou un italique qui ne se ferme pas.
  margueNonFermee,

  /// Un gras dans un italique, ou l'inverse.
  imbrication,

  /// Une liste a deux niveaux.
  listeImbriquee,

  /// Un titre de niveau 4 ou plus.
  titreTropProfond,
}

/// Le resultat : le document, ou le refus et sa ligne.
@immutable
class ResultatMd {
  /// Un document lu.
  const ResultatMd.ok(List<BlocMd> this.blocs) : code = null, ligne = 0;

  /// Un refus.
  const ResultatMd.refus(CodeRefusMd this.code, this.ligne) : blocs = null;

  /// Les blocs, quand le texte est admis.
  final List<BlocMd>? blocs;

  /// Le refus, sinon.
  final CodeRefusMd? code;

  /// La ligne du defaut (0 : le texte entier).
  final int ligne;

  /// Vrai quand le texte est admis.
  bool get estOk => blocs != null;
}

/// Les bornes, les memes que celles du serveur.
const int octetsMaxMd = 100000;

/// Longueur maximale d'une ligne.
const int ligneMaxMd = 5000;

/// Nombre maximal de blocs.
const int blocsMaxMd = 2000;

final RegExp _titre = RegExp(r'^(#{1,3}) (.+)$');
final RegExp _puce = RegExp(r'^[-*] (.+)$');
final RegExp _num = RegExp(r'^(\d{1,3})\. (.+)$');
final RegExp _imbriquee = RegExp(r'^ +(?:[-*]|\d{1,3}\.) ');
final RegExp _html = RegExp(r'<[A-Za-z/!?]');
final RegExp _lien = RegExp(r'\[[^\]\n]*\]\([^)\n]*\)');
final RegExp _tropProfond = RegExp(r'^#{4,}( |$)');

bool _interdit(int c) {
  if (c == 0x0a || c == 0x09) return false;
  if (c < 0x20 || c == 0x7f) return true;
  if (c >= 0x202a && c <= 0x202e) return true;
  if (c >= 0x2066 && c <= 0x2069) return true;
  return false;
}

/// Les marques en ligne d'un texte deja joint. Rend les morceaux, ou le code
/// du refus.
(List<InlineMd>?, CodeRefusMd?) _inlines(String texte) {
  final List<InlineMd> sortie = <InlineMd>[];
  final StringBuffer tampon = StringBuffer();
  void vider() {
    if (tampon.isEmpty) return;
    final String t = tampon.toString();
    tampon.clear();
    if (sortie.isNotEmpty && sortie.last is TexteMd) {
      sortie[sortie.length - 1] = TexteMd('${sortie.last.texte}$t');
    } else {
      sortie.add(TexteMd(t));
    }
  }

  String? car(int i) => i < texte.length ? texte[i] : null;
  int i = 0;
  while (i < texte.length) {
    final String c = texte[i];
    if (c == r'\') {
      final String? s = car(i + 1);
      if (s == '*' || s == r'\') {
        tampon.write(s);
        i += 2;
      } else {
        tampon.write(c);
        i += 1;
      }
      continue;
    }
    if (c == '*') {
      final bool gras = car(i + 1) == '*';
      int j = i + (gras ? 2 : 1);
      final StringBuffer contenu = StringBuffer();
      bool ferme = false;
      while (j < texte.length) {
        final String d = texte[j];
        if (d == r'\' && (car(j + 1) == '*' || car(j + 1) == r'\')) {
          contenu.write(car(j + 1));
          j += 2;
          continue;
        }
        if (d == '*') {
          if (gras) {
            if (car(j + 1) == '*') {
              ferme = true;
              j += 2;
              break;
            }
            return (null, CodeRefusMd.imbrication);
          }
          if (car(j + 1) == '*') return (null, CodeRefusMd.imbrication);
          ferme = true;
          j += 1;
          break;
        }
        contenu.write(d);
        j += 1;
      }
      if (!ferme || contenu.isEmpty) {
        return (null, CodeRefusMd.margueNonFermee);
      }
      vider();
      sortie.add(
        gras ? GrasMd(contenu.toString()) : ItaliqueMd(contenu.toString()),
      );
      i = j;
      continue;
    }
    tampon.write(c);
    i += 1;
  }
  vider();
  return (sortie, null);
}

CodeRefusMd? _motifInterdit(String ligne) {
  if (ligne.contains('![')) return CodeRefusMd.image;
  if (_lien.hasMatch(ligne)) return CodeRefusMd.lien;
  if (_html.hasMatch(ligne)) return CodeRefusMd.html;
  if (ligne.contains('`')) return CodeRefusMd.code;
  if (ligne.contains('~~')) return CodeRefusMd.barre;
  return null;
}

/// Analyse [source] : le document, ou le premier refus.
ResultatMd analyserMarkdownFerme(String source) {
  if (utf8.encode(source).length > octetsMaxMd) {
    return const ResultatMd.refus(CodeRefusMd.tropLong, 0);
  }
  final String normalise = source.replaceAll(RegExp(r'\r\n?'), '\n');
  for (final int c in normalise.codeUnits) {
    if (_interdit(c)) {
      return const ResultatMd.refus(CodeRefusMd.caractereInterdit, 0);
    }
  }
  final List<String> lignes = normalise.replaceAll('\t', ' ').split('\n');
  if (lignes.every((String l) => l.trim().isEmpty)) {
    return const ResultatMd.refus(CodeRefusMd.vide, 0);
  }
  final List<BlocMd> blocs = <BlocMd>[];
  List<String> para = <String>[];
  List<String> citation = <String>[];
  List<String>? puces;
  List<String>? nums;
  int debutNum = 0;
  int courante = 0;

  ResultatMd refus(CodeRefusMd c) => ResultatMd.refus(c, courante);

  List<List<InlineMd>>? items(
    List<String> textes,
    void Function(CodeRefusMd) e,
  ) {
    final List<List<InlineMd>> sortie = <List<InlineMd>>[];
    for (final String t in textes) {
      final (List<InlineMd>? r, CodeRefusMd? err) = _inlines(t);
      if (err != null) {
        e(err);
        return null;
      }
      sortie.add(r!);
    }
    return sortie;
  }

  CodeRefusMd? fermer() {
    CodeRefusMd? echec;
    if (para.isNotEmpty) {
      final (List<InlineMd>? r, CodeRefusMd? e) = _inlines(para.join(' '));
      para = <String>[];
      if (e != null) return e;
      blocs.add(ParagrapheMd(r!));
    }
    if (citation.isNotEmpty) {
      final (List<InlineMd>? r, CodeRefusMd? e) = _inlines(citation.join(' '));
      citation = <String>[];
      if (e != null) return e;
      blocs.add(CitationMd(r!));
    }
    if (puces != null) {
      final List<List<InlineMd>>? l = items(
        puces!,
        (CodeRefusMd e) => echec = e,
      );
      puces = null;
      if (l == null) return echec;
      blocs.add(PucesMd(l));
    }
    if (nums != null) {
      final List<List<InlineMd>>? l = items(
        nums!,
        (CodeRefusMd e) => echec = e,
      );
      nums = null;
      if (l == null) return echec;
      blocs.add(NumeroteeMd(debutNum, l));
    }
    return null;
  }

  for (int n = 0; n < lignes.length; n++) {
    courante = n + 1;
    final String brute = lignes[n];
    if (brute.length > ligneMaxMd) return refus(CodeRefusMd.ligneTropLongue);
    final String l = brute.trimRight();
    if (l.trim().isEmpty) {
      final CodeRefusMd? e = fermer();
      if (e != null) return refus(e);
      continue;
    }
    if (l.startsWith('|')) return refus(CodeRefusMd.tableau);
    if (l.trim().startsWith('```') || l.trim().startsWith('~~~')) {
      return refus(CodeRefusMd.code);
    }
    final CodeRefusMd? m = _motifInterdit(l);
    if (m != null) return refus(m);
    if (_imbriquee.hasMatch(l)) return refus(CodeRefusMd.listeImbriquee);
    if (_tropProfond.hasMatch(l)) return refus(CodeRefusMd.titreTropProfond);
    final RegExpMatch? t = _titre.firstMatch(l);
    if (t != null) {
      final CodeRefusMd? e = fermer();
      if (e != null) return refus(e);
      final (List<InlineMd>? r, CodeRefusMd? err) = _inlines(
        t.group(2)!.trim(),
      );
      if (err != null) return refus(err);
      blocs.add(TitreMd(t.group(1)!.length, r!));
      continue;
    }
    if (l.trim() == '---') {
      final CodeRefusMd? e = fermer();
      if (e != null) return refus(e);
      blocs.add(const SeparateurMd());
      continue;
    }
    if (l.startsWith('>')) {
      if (para.isNotEmpty || puces != null || nums != null) {
        final CodeRefusMd? e = fermer();
        if (e != null) return refus(e);
      }
      citation.add(l.replaceFirst(RegExp(r'^> ?'), '').trim());
      continue;
    }
    final RegExpMatch? p = _puce.firstMatch(l);
    if (p != null) {
      if (para.isNotEmpty || citation.isNotEmpty || nums != null) {
        final CodeRefusMd? e = fermer();
        if (e != null) return refus(e);
      }
      (puces ??= <String>[]).add(p.group(1)!.trim());
      continue;
    }
    final RegExpMatch? q = _num.firstMatch(l);
    if (q != null) {
      if (para.isNotEmpty || citation.isNotEmpty || puces != null) {
        final CodeRefusMd? e = fermer();
        if (e != null) return refus(e);
      }
      if (nums == null) {
        nums = <String>[];
        debutNum = int.parse(q.group(1)!);
      }
      nums!.add(q.group(2)!.trim());
      continue;
    }
    if (citation.isNotEmpty || puces != null || nums != null) {
      final CodeRefusMd? e = fermer();
      if (e != null) return refus(e);
    }
    para.add(l.trim());
  }
  courante = lignes.length;
  final CodeRefusMd? e = fermer();
  if (e != null) return refus(e);
  if (blocs.length > blocsMaxMd) {
    return const ResultatMd.refus(CodeRefusMd.tropDeBlocs, 0);
  }
  return ResultatMd.ok(blocs);
}
