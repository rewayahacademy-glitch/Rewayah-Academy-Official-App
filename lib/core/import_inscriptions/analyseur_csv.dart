/// IMM-ACCUEIL-FRONT : lecture d'un fichier CSV colle ou charge, sans paquet.
///
/// Les fichiers viennent du classeur des formulaires Google (separateur
/// virgule) mais un tableur en francais exporte avec un point-virgule : le
/// separateur est donc devine sur l'en-tete. Guillemets RFC 4180 (une cellule
/// peut contenir le separateur, un saut de ligne ou un guillemet double), marque
/// d'ordre des octets (BOM) retiree, lignes vides ignorees.
///
/// Le serveur ne lit que la virgule : [TableCsv.versCsv] reecrit toujours la
/// table en virgules, avec les guillemets qu'il faut, pour que ce qui part soit
/// exactement ce qui a ete analyse.
library;

import 'package:flutter/foundation.dart';

/// Une ligne de donnees.
@immutable
class LigneCsv {
  /// Cree la ligne.
  const LigneCsv({required this.numero, required this.cellules});

  /// Le numero de la ligne, **comme le compte le serveur** : l'en-tete est la
  /// ligne 1, les lignes vides ne comptent pas.
  final int numero;

  /// Les cellules, telles que lues (non rognees).
  final List<String> cellules;

  /// Vrai quand aucune cellule ne porte de texte.
  bool get estVide => cellules.every((String c) => c.trim().isEmpty);
}

/// Un CSV lu.
@immutable
class TableCsv {
  /// Cree la table.
  const TableCsv({
    required this.entetes,
    required this.lignes,
    required this.separateur,
    this.guillemetNonFerme = false,
  });

  /// La table d'un texte sans aucune ligne.
  static const TableCsv vide = TableCsv(
    entetes: <String>[],
    lignes: <LigneCsv>[],
    separateur: ',',
  );

  /// Les noms de colonnes de la premiere ligne.
  final List<String> entetes;

  /// Les lignes de donnees, en-tete exclu.
  final List<LigneCsv> lignes;

  /// Le separateur devine (`,` ou `;`).
  final String separateur;

  /// Vrai quand un guillemet ouvrant n'a jamais ete ferme : la fin du texte a
  /// ete avalee par une cellule, le fichier est a corriger.
  final bool guillemetNonFerme;

  /// Vrai quand le texte ne contenait aucune ligne.
  bool get estVide => entetes.isEmpty && lignes.isEmpty;

  /// La table reecrite en CSV a virgules (RFC 4180, fins de ligne CRLF), prete
  /// pour le serveur. Vide pour une table vide.
  String versCsv() {
    if (entetes.isEmpty) return '';
    final StringBuffer sortie = StringBuffer(_ligne(entetes));
    for (final LigneCsv l in lignes) {
      sortie
        ..write('\r\n')
        ..write(_ligne(l.cellules));
    }
    sortie.write('\r\n');
    return sortie.toString();
  }

  static String _ligne(List<String> cellules) =>
      cellules.map(_cellule).join(',');

  static String _cellule(String c) {
    final bool aGuillemeter =
        c.contains(',') ||
        c.contains('"') ||
        c.contains('\n') ||
        c.contains('\r') ||
        c != c.trim();
    return aGuillemeter ? '"${c.replaceAll('"', '""')}"' : c;
  }
}

/// Le lecteur de CSV.
abstract final class AnalyseurCsv {
  /// Lit [texte]. Un texte vide (ou fait de lignes vides) rend [TableCsv.vide].
  static TableCsv lire(String texte) {
    String brut = texte;
    if (brut.startsWith('﻿')) brut = brut.substring(1);
    if (brut.trim().isEmpty) return TableCsv.vide;

    final String separateur = _deviner(brut);
    final List<List<String>> enregistrements = <List<String>>[];
    List<String> cellules = <String>[];
    final StringBuffer cellule = StringBuffer();
    bool entreGuillemets = false;
    bool guillemetFerme = false;
    bool cellulePresente = false;

    void finirCellule() {
      cellules.add(cellule.toString());
      cellule.clear();
      guillemetFerme = false;
      cellulePresente = false;
    }

    void finirLigne() {
      finirCellule();
      // Une ligne sans le moindre caractere est ignoree, comme au serveur.
      if (!(cellules.length == 1 && cellules.first.isEmpty)) {
        enregistrements.add(cellules);
      }
      cellules = <String>[];
    }

    final int n = brut.length;
    for (int i = 0; i < n; i++) {
      final String c = brut[i];
      if (entreGuillemets) {
        if (c == '"') {
          if (i + 1 < n && brut[i + 1] == '"') {
            cellule.write('"');
            i++;
          } else {
            entreGuillemets = false;
            guillemetFerme = true;
          }
        } else {
          cellule.write(c);
        }
        continue;
      }
      if (c == '"' && !cellulePresente && !guillemetFerme) {
        entreGuillemets = true;
        cellulePresente = true;
      } else if (c == separateur) {
        finirCellule();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < n && brut[i + 1] == '\n') i++;
        finirLigne();
      } else {
        // Un guillemet au milieu d'une cellule, ou du texte apres un guillemet
        // fermant, est garde tel quel : la reecriture le protegera.
        cellule.write(c);
        cellulePresente = true;
      }
    }
    final bool nonFerme = entreGuillemets;
    if (cellulePresente || cellules.isNotEmpty || cellule.isNotEmpty) {
      finirLigne();
    }

    if (enregistrements.isEmpty) return TableCsv.vide;
    final List<String> entetes = enregistrements.first
        .map((String e) => e.trim())
        .toList(growable: false);
    final List<LigneCsv> lignes = <LigneCsv>[
      for (int k = 1; k < enregistrements.length; k++)
        LigneCsv(numero: k + 1, cellules: enregistrements[k]),
    ];
    return TableCsv(
      entetes: entetes,
      lignes: lignes,
      separateur: separateur,
      guillemetNonFerme: nonFerme,
    );
  }

  /// Le separateur de la premiere ligne non vide : le plus frequent hors des
  /// guillemets, la virgule en cas d'egalite.
  static String _deviner(String texte) {
    int virgules = 0;
    int pointsVirgules = 0;
    bool entre = false;
    for (int i = 0; i < texte.length; i++) {
      final String c = texte[i];
      if (c == '"') {
        entre = !entre;
      } else if (!entre) {
        if (c == '\n' || c == '\r') {
          if (virgules + pointsVirgules > 0) break;
        } else if (c == ',') {
          virgules++;
        } else if (c == ';') {
          pointsVirgules++;
        }
      }
    }
    return pointsVirgules > virgules ? ';' : ',';
  }
}
