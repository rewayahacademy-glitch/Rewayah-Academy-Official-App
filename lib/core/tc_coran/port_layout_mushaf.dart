import 'package:flutter/foundation.dart';

/// Ce que la source de layout peut promettre.
///
/// `indisponible` est la valeur attendue **tant que `verset.ligne` est NULL et
/// qu'aucun asset de layout n'est fourni**. Le moteur ne renvoie jamais
/// `fidele` sans donnees de ligne reelles : une page approximee qui se
/// declarerait fidele serait pire qu'une page absente, parce que plus rien
/// ensuite ne distinguerait les deux.
enum DisponibiliteLayout {
  /// La repartition en lignes vient de l'edition. Rendu au glyphe pres.
  fidele,

  /// Des reperes existent, mais pas la composition complete.
  degrade,

  /// Aucune donnee de ligne. La composition interne est approximee.
  indisponible,
}

/// Un segment de verset pose sur une ligne de page.
///
/// **Ce type n'est jamais construit par approximation.** Il n'existe que
/// lorsqu'une source de layout reelle dit ou le mot commence et ou il finit.
@immutable
class SegmentVersetLigne {
  /// Cree un segment.
  const SegmentVersetLigne({
    required this.sourate,
    required this.ayah,
    required this.texte,
    required this.debuteLAyah,
    required this.termineLAyah,
  });

  /// La sourate du verset.
  final int sourate;

  /// Le rang du verset dans sa sourate.
  final int ayah;

  /// Le texte porte par ce segment.
  final String texte;

  /// Vrai quand le verset commence dans ce segment.
  final bool debuteLAyah;

  /// Vrai quand le verset se termine dans ce segment : c'est la que se pose
  /// la rosace du numero.
  final bool termineLAyah;
}

/// Ce qu'une ligne imprimee porte.
enum TypeLigneMushaf {
  /// Une ligne de texte : des segments de versets, justifiee sur le cadre.
  texte,

  /// Le cadre de sourate (titre), centre, sur une ligne a lui seul.
  enteteSourate,

  /// La basmala qui ouvre une sourate, centree, sur une ligne a elle seule.
  basmala,
}

/// Une ligne d'une page du mushaf.
///
/// C'est le contrat `SectionLigne` de `TEACHING_CORE_CONTRACTS.md` : l'unite
/// que le renderer pose, une fois qu'une source de layout reelle la fournit.
/// Aucun `SectionLigne` n'est construit par le moteur lui-meme : voir
/// [DisponibiliteLayout].
@immutable
class SectionLigne {
  /// Cree une ligne.
  const SectionLigne({
    required this.numero,
    required this.segments,
    this.centree = false,
    this.type = TypeLigneMushaf.texte,
    this.sourate,
    this.termineLaSourate = false,
  });

  /// Son rang sur la page, de 1 au nombre de lignes de l'edition.
  final int numero;

  /// Ce qu'elle porte, de droite a gauche.
  final List<SegmentVersetLigne> segments;

  /// Vrai pour les lignes qui ne se justifient pas : titre de sourate,
  /// basmala, et les lignes d'Al-Fatiha.
  final bool centree;

  /// La nature de la ligne.
  final TypeLigneMushaf type;

  /// La sourate d'un cadre ou d'une basmala ; `null` pour une ligne de texte.
  final int? sourate;

  /// Vrai quand la ligne de texte porte la fin d'une sourate : l'edition la
  /// laisse courte et centree quand elle ne remplit pas le cadre.
  final bool termineLaSourate;
}

/// La mise en page d'une page du mushaf, telle que l'edition la compose.
@immutable
class LayoutPage {
  /// Cree un layout de page.
  const LayoutPage({
    required this.numeroPage,
    required this.lignes,
    required this.nombreLignes,
    required this.ratioLargeurSurHauteur,
    this.juz,
    this.hizb,
    this.rubDansHizb,
    this.quartsDebutes = const <int>[],
  });

  /// La page concernee.
  final int numeroPage;

  /// Ses lignes, de la premiere a la derniere.
  final List<SectionLigne> lignes;

  /// Le nombre de lignes que l'edition pose sur cette page.
  ///
  /// Quinze pour le Mushaf de Medine, sauf les pages 1 et 2.
  final int nombreLignes;

  /// La proportion du cadre de texte, largeur divisee par hauteur.
  final double ratioLargeurSurHauteur;

  /// Le juz du premier verset de la page, de 1 a 30.
  final int? juz;

  /// Le hizb du premier verset de la page, de 1 a 60.
  final int? hizb;

  /// Le quart parcouru dans le hizb au premier verset : 0 (debut), 1, 2, 3.
  final int? rubDansHizb;

  /// Les quarts de hizb (1 a 240) qui commencent sur cette page.
  final List<int> quartsDebutes;
}

/// La source de mise en page du mushaf.
///
/// **Point d'extension, pas une promesse.** Le moteur de rendu interroge
/// toujours [disponibilite] avant [layoutDe], et sait se passer d'un layout :
/// c'est ce qui permet de brancher une source reelle -- lignes importees,
/// polices QCF, fichier de coordonnees -- sans toucher a une ligne du
/// renderer.
///
/// Signature fixee par `TEACHING_CORE_CONTRACTS.md` section 17.
abstract class PortLayoutMushaf {
  /// Ce que cette source peut promettre. Interroge avant tout rendu.
  Future<DisponibiliteLayout> disponibilite();

  /// La mise en page d'une page, ou `null` si cette source ne l'a pas.
  Future<LayoutPage?> layoutDe(int numeroPage);
}
