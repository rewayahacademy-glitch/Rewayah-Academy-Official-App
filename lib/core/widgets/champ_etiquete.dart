import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import 'point_rappel.dart';
import 'zone_saisie.dart';

/// Un champ de texte dont l'etiquette est un texte au-dessus, sur autant de
/// lignes qu'il faut (FORM-CORR-1).
///
/// L'etiquette flottante de Material tient sur une ligne et se coupe en
/// « Nom du nouveau cy... » a 320 de large, texte a 200 % (revue C1-FORM-R,
/// N1). Ici le libelle est un `Text` ordinaire : il passe a la ligne, et il
/// reste lu par les lecteurs d'ecran comme le nom du champ.
class ChampEtiquete extends StatelessWidget {
  /// Cree le champ.
  const ChampEtiquete({
    required this.libelle,
    required this.controller,
    super.key,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.aide,
    this.indice,
    this.obligatoire = false,
  });

  /// Vrai : l'etiquette porte la marque des champs obligatoires (le point de
  /// [PointRappel], fixe, au bord de debut), et le lecteur d'ecran l'annonce
  /// apres le nom du champ (CLASSE-FORM-1). Faux par defaut : rendu inchange.
  final bool obligatoire;

  /// Le nom du champ, ecrit en entier.
  final String libelle;

  /// Le texte saisi.
  final TextEditingController controller;

  /// Appele a chaque frappe.
  final ValueChanged<String>? onChanged;

  /// Le clavier voulu.
  final TextInputType? keyboardType;

  /// Le nombre de lignes du champ.
  final int maxLines;

  /// L'alignement du texte saisi.
  final TextAlign textAlign;

  /// La casse proposee par le clavier.
  final TextCapitalization textCapitalization;

  /// Une phrase sous le champ.
  final String? aide;

  /// Un exemple grise dans le champ vide.
  final String? indice;

  @override
  Widget build(BuildContext context) {
    // Plusieurs lignes : la zone de saisie partagee, seule a porter un champ
    // multiligne (SUPERPOS-1, reunie par JONCTION-LIGNES-1). Meme contrat :
    // l'etiquette au-dessus, sur autant de lignes qu'il faut.
    if (maxLines > 1) {
      final Widget zone = ZoneSaisie(
        controleur: controller,
        libelle: obligatoire
            ? t.formulaire.champObligatoire(champ: libelle)
            : libelle,
        // Obligatoire (CLASSE-FORM-1) : l'etiquette porte la marque, posee
        // par [TitreChamp] au-dessus ; la zone ne la redit pas a l'ecran.
        libelleVisible: obligatoire ? false : null,
        aide: indice,
        explication: aide,
        minLignes: maxLines,
        maxLignes: maxLines,
        majuscules: textCapitalization,
        onChanged: onChanged,
      );
      if (!obligatoire) return zone;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: TitreChamp(
              libelle,
              style: Theme.of(context).textTheme.labelLarge,
              obligatoire: true,
            ),
          ),
          Ecart.vSm,
          zone,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: TitreChamp(
            libelle,
            style: Theme.of(context).textTheme.labelLarge,
            obligatoire: obligatoire,
            sansCoupure: false,
          ),
        ),
        Ecart.vXs,
        Semantics(
          label: obligatoire
              ? t.formulaire.champObligatoire(champ: libelle)
              : libelle,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textAlign: textAlign,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              helperText: aide,
              helperMaxLines: 10,
              hintText: indice,
              hintMaxLines: 4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le titre d'un champ de formulaire, avec la marque des champs obligatoires
/// quand il l'est (CLASSE-FORM-1).
///
/// **Seul point d'entree de ce motif** (K-10), range avec [ChampEtiquete] qui
/// en est le premier lecteur : `ChampEtiquete`,
/// `SelecteurPersonne` et les sections choisies d'un formulaire (public,
/// genre, creneau, seuil) le partagent. Obligatoire : le point de
/// [PointRappel], fixe, au bord de debut, un palier ([Ecart.hSm]), puis le
/// nom du champ, qui prend la place restante. Sinon, le nom seul.
class TitreChamp extends StatelessWidget {
  /// Cree le titre.
  const TitreChamp(
    this.titre, {
    required this.style,
    super.key,
    this.obligatoire = false,
    this.sansCoupure = true,
  });

  /// Le nom du champ, ecrit en entier.
  final String titre;

  /// Le style du nom (`titleMedium` pour une section, `labelLarge` pour
  /// l'etiquette d'un champ de texte).
  final TextStyle? style;

  /// Vrai : la marque des champs obligatoires precede le nom.
  final bool obligatoire;

  /// Vrai (par defaut) : le nom passe par [TexteSansCoupure] (aucun mot
  /// coupe a 320 en texte x2). Faux : un `Text` ordinaire, le rendu
  /// historique de l'etiquette de `ChampEtiquete`.
  final bool sansCoupure;

  @override
  Widget build(BuildContext context) {
    final Widget nom = sansCoupure
        ? TexteSansCoupure(titre, style: style)
        : Text(titre, style: style);
    if (!obligatoire) return nom;
    return Row(
      children: <Widget>[
        PointRappel(libelle: t.formulaire.obligatoire, battements: 0),
        Ecart.hSm,
        Expanded(child: nom),
      ],
    );
  }
}
