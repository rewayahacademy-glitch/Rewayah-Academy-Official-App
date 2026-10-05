import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

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
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(libelle, style: Theme.of(context).textTheme.labelLarge),
        ),
        Ecart.vXs,
        Semantics(
          label: libelle,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
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
