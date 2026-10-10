// Le champ de recherche partage (revue COM-R, R-07 : une fonction, un
// endroit).
//
// Un seul champ pour toutes les recherches d'une liste (Messages, Le Studio,
// Communaute) : etiquete, avec son aide, la loupe en tete et « Effacer la
// recherche » au bout, rendu seulement s'il y a quelque chose a effacer.
// L'ecran donne ses textes et ses cles ; il ne recompose ni le champ ni son
// bouton.

import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
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

  /// La place que l'etiquette perd dans le champ : la loupe (une cible de
  /// 48) et les marges interieures du theme, de part et d'autre.
  static const double _retraitEtiquette =
      AppTouchTarget.standard + 2 * AppSpacing.lg;

  /// Le nombre de lignes de l'aide quand l'etiquette est sortie du champ.
  static const int _lignesAide = 6;

  /// Vrai quand l'etiquette ne tient pas sur une ligne dans le champ, a
  /// toute taille de texte (RECETTE-NUIT-B : a texte x2 elle etait tronquee ;
  /// COM-RC tour 2, recette : « Rechercher une
  /// conve... » dans la colonne de 256 des Messages et du Studio a 768).
  bool _etiquetteDehors(BuildContext context, double largeur) {
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    if (!largeur.isFinite) return false;
    final TextPainter mesure = TextPainter(
      text: TextSpan(
        text: libelle,
        style: DefaultTextStyle.of(context).style
            .merge(Theme.of(context).textTheme.bodyLarge),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double largeurEtiquette = mesure.width;
    mesure.dispose();
    return largeurEtiquette > largeur - _retraitEtiquette;
  }

  @override
  Widget build(BuildContext context) {
    final r = t.commun.recherche;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool dehors = _etiquetteDehors(context, contraintes.maxWidth);
        final Widget champ = ValueListenableBuilder<TextEditingValue>(
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
                  labelText: dehors ? null : libelle,
                  hintText: aide,
                  // L'aide passe a la ligne dans le champ au lieu d'etre tronquee.
                  hintMaxLines: _lignesAide,
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
        if (!dehors) return champ;
        // Une etiquette qui ne tient pas dans le champ se pose au-dessus,
        // entiere, passee a la ligne entre ses mots. Elle reste le nom du
        // champ pour le lecteur d'ecran, posee sur le champ et non lue deux
        // fois.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: TexteSansCoupure(
                libelle,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vXs,
            Semantics(label: libelle, child: champ),
          ],
        );
      },
    );
  }
}
