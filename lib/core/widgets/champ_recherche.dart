// Le champ de recherche partage (revue COM-R, R-07 : une fonction, un
// endroit).
//
// Un seul champ pour toutes les recherches d'une liste (Messages, Le Studio,
// Communaute) : etiquete, avec son aide, la loupe en tete et « Effacer la
// recherche » au bout, rendu seulement s'il y a quelque chose a effacer.
// L'ecran donne ses textes et ses cles ; il ne recompose ni le champ ni son
// bouton.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import 'bouton_icone.dart';

/// Le champ de recherche d'une liste.
class ChampRecherche extends StatelessWidget {
  /// Cree le champ.
  const ChampRecherche({
    required this.controleur,
    required this.libelle,
    required this.aide,
    super.key,
    this.cleChamp,
    this.cleEffacer,
    this.autofocus = false,
    this.focusNode,
    this.onChange,
  });

  /// Le texte cherche ; l'appelant l'ecoute, ou passe [onChange].
  final TextEditingController controleur;

  /// L'etiquette du champ, lue par le lecteur d'ecran (« Rechercher une
  /// conversation »).
  final String libelle;

  /// L'aide dans le champ vide (« Nom, Classe ou dossier »).
  final String aide;

  /// La cle du champ de saisie, pour les tests de l'ecran.
  final Key? cleChamp;

  /// La cle du bouton qui efface, pour les tests de l'ecran.
  final Key? cleEffacer;

  /// Vrai : le champ prend le focus a l'apparition (surface du telephone).
  final bool autofocus;

  /// Le noeud de focus du champ, si l'appelant en a besoin.
  final FocusNode? focusNode;

  /// Chaque changement du texte, effacement compris ; facultatif quand
  /// l'appelant ecoute [controleur].
  final ValueChanged<String>? onChange;

  void _effacer() {
    controleur.clear();
    onChange?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final r = t.commun.recherche;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controleur,
      builder: (BuildContext context, TextEditingValue valeur, Widget? _) =>
          TextField(
            key: cleChamp,
            controller: controleur,
            focusNode: focusNode,
            autofocus: autofocus,
            textInputAction: TextInputAction.search,
            onChanged: onChange,
            decoration: InputDecoration(
              labelText: libelle,
              hintText: aide,
              prefixIcon: ExcludeSemantics(
                child: Icon(AppIcons.recherche.repos),
              ),
              suffixIcon: valeur.text.isEmpty
                  ? null
                  : BoutonIcone(
                      key: cleEffacer,
                      icone: AppIcons.effacer,
                      libelle: r.effacer,
                      infobulle: r.effacer,
                      onPress: _effacer,
                    ),
            ),
          ),
    );
  }
}
