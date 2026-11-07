// Le fichier que la direction depose pour l'import des formulaires (`ADM-23`) :
// ce que le client sait de lui avant de l'envoyer, et rien d'autre.
//
// - le classeur et l'onglet, deduits du nom d'un export Google Sheets
//   (« <classeur> - <onglet>.csv »), a corriger si le nom ne les dit pas. Ils
//   entrent dans la **reference source** de chaque reponse : rejouer un fichier
//   corrige n'ajoute rien seulement si ces deux noms ne changent pas ;
// - le texte en CSV a virgules (le serveur ne lit que la virgule) et ses
//   colonnes, pour dire au pas « Colonnes » quel titre est lu comme quoi ;
// - la reference source d'une ligne, que le serveur attend pour un choix de
//   doublon et ne rend pas dans l'apercu (`CONTRAT_PORTS_CANDIDATURES.md`,
//   section 2 : « classeur | onglet | horodatage ecrit dans le fichier »).
//
// Le client ne decide de rien d'autre : l'analyse, les issues et les groupes
// sont ceux du serveur.
library;

import 'package:flutter/foundation.dart';

import '../import_inscriptions/analyseur_csv.dart';
import 'modeles_import_candidatures.dart';

/// La taille maximale que le serveur accepte (`p_csv`, 5 000 000 signes).
const int tailleMaxCsv = 5000000;

/// La longueur maximale du nom d'un classeur ou d'un onglet.
const int longueurMaxNom = 200;

/// Le classeur et l'onglet d'un fichier.
@immutable
class NomsClasseur {
  /// Cree les noms.
  const NomsClasseur({required this.classeur, required this.onglet});

  /// Le nom du classeur.
  final String classeur;

  /// Le nom de l'onglet.
  final String onglet;

  /// Vrai quand les deux noms sont acceptes par le serveur.
  bool get valides => nomValide(classeur) && nomValide(onglet);

  /// Les noms avec [classeur] et [onglet] remplaces.
  NomsClasseur avec({String? classeur, String? onglet}) => NomsClasseur(
    classeur: classeur ?? this.classeur,
    onglet: onglet ?? this.onglet,
  );

  @override
  bool operator ==(Object other) =>
      other is NomsClasseur &&
      other.classeur == classeur &&
      other.onglet == onglet;

  @override
  int get hashCode => Object.hash(classeur, onglet);
}

/// Le serveur refuse un nom vide, de plus de 200 signes ou avec une barre
/// verticale (elle separe les trois parties de la reference source).
bool nomValide(String nom) {
  final String n = nom.trim();
  return n.isNotEmpty && n.length <= longueurMaxNom && !n.contains('|');
}

/// Les noms que dit le nom du fichier [nomFichier]. Google Sheets exporte
/// « `classeur - onglet.csv` » ; un numero de copie « (1) » est ignore.
/// Sans « - », l'onglet reste vide : la direction le dit, rien ne se devine.
/// Une barre verticale du nom est remplacee par un tiret (elle serait refusee).
NomsClasseur deduireNoms(String nomFichier) {
  String base = nomFichier.trim();
  final RegExp extension = RegExp(r'\.(csv|txt)$', caseSensitive: false);
  base = base.replaceFirst(extension, '');
  base = base.replaceFirst(RegExp(r'\s*\(\d+\)$'), '');
  base = base.replaceAll('|', '-').trim();
  final int coupure = base.lastIndexOf(' - ');
  if (coupure > 0 && coupure + 3 < base.length) {
    return NomsClasseur(
      classeur: base.substring(0, coupure).trim(),
      onglet: base.substring(coupure + 3).trim(),
    );
  }
  return NomsClasseur(classeur: base, onglet: '');
}

/// Le fichier choisi : son nom, son texte tel que lu, et sa lecture locale.
@immutable
class FichierFormulaires {
  const FichierFormulaires._({
    required this.nom,
    required this.table,
    required this.csv,
    required this.tailleOriginale,
  });

  /// Lit [texte], le contenu decode du fichier [nom].
  factory FichierFormulaires.lire({required String nom, required String texte}) {
    final TableCsv table = AnalyseurCsv.lire(texte);
    return FichierFormulaires._(
      nom: nom,
      table: table,
      csv: table.versCsv(),
      tailleOriginale: texte.length,
    );
  }

  /// Le nom du fichier.
  final String nom;

  /// Le CSV lu sur l'appareil.
  final TableCsv table;

  /// Le CSV a virgules qui part au serveur : exactement ce qui a ete lu.
  final String csv;

  /// La taille du texte d'origine, en signes.
  final int tailleOriginale;

  /// Vrai quand le fichier n'a aucune ligne de donnees (l'en-tete seul).
  bool get sansLigne => table.lignes.isEmpty;

  /// Le nombre de lignes de donnees, comme le serveur les compte : l'en-tete
  /// exclu, les lignes sans aucun signe ignorees.
  int get nombreLignes => table.lignes.length;

  /// Vrai quand le fichier depasse ce que le serveur accepte.
  bool get tropVolumineux => csv.length > tailleMaxCsv;

  /// Vrai quand un guillemet ouvrant n'a jamais ete ferme.
  bool get guillemetNonFerme => table.guillemetNonFerme;

  /// Le titre de la colonne [position] (a partir de 1), tel que le fichier le
  /// donne, ou une chaine vide.
  String titreDeColonne(int position) {
    final int i = position - 1;
    return i >= 0 && i < table.entetes.length ? table.entetes[i] : '';
  }

  /// Le nombre de colonnes de l'en-tete.
  int get nombreColonnes => table.entetes.length;

  /// L'horodatage tel qu'ecrit dans la ligne [ligne], ou `null`. [colonnes] dit
  /// laquelle des colonnes est l'horodateur.
  String? horodatageDeLigne(int ligne, List<ColonneLue> colonnes) {
    int? position;
    for (final ColonneLue c in colonnes) {
      if (c.champ == ChampFormulaire.horodatage) position = c.position;
    }
    if (position == null) return null;
    for (final LigneCsv l in table.lignes) {
      if (l.numero != ligne) continue;
      if (position > l.cellules.length) return null;
      final String brut = sansEspaces(l.cellules[position - 1]);
      return brut.isEmpty ? null : brut;
    }
    return null;
  }
}

/// La reference source d'une reponse : classeur, onglet et horodatage ecrit
/// dans le fichier, separes par une barre verticale. Meme forme que le
/// serveur (`formulaires_lire` : `p_classeur || '|' || p_onglet || '|' ||
/// horodatage`, les trois sans espaces de tete ni de fin).
String referenceSource({
  required String classeur,
  required String onglet,
  required String horodatage,
}) =>
    '${sansEspaces(classeur)}|${sansEspaces(onglet)}|${sansEspaces(horodatage)}';

/// Retire les espaces de tete et de fin, comme le `btrim` du serveur (des
/// espaces seulement).
String sansEspaces(String s) {
  int debut = 0;
  int fin = s.length;
  while (debut < fin && s[debut] == ' ') {
    debut++;
  }
  while (fin > debut && s[fin - 1] == ' ') {
    fin--;
  }
  return s.substring(debut, fin);
}
