// La recherche plein ecran du telephone, partagee (revue COM-R, R-07 : une
// fonction, un endroit).
//
// Ce n'est ni une route ni un ecran : un ETAT temporaire d'une liste
// (Messages, Le Studio, Communaute ; spec section 18). Le retour en tete,
// puis le champ partage (`ChampRecherche`), puis les resultats que l'ecran
// donne. Le retour referme la surface et rend la liste a l'appelant, qui
// garde sa position.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';
import 'champ_recherche.dart';

/// La recherche plein ecran du telephone : retour, champ, resultats.
class SurfaceRecherche extends StatelessWidget {
  /// Cree la surface.
  const SurfaceRecherche({
    required this.controleur,
    required this.libelle,
    required this.aide,
    required this.onFermer,
    required this.resultats,
    super.key,
    this.cleChamp,
    this.cleEffacer,
    this.cleFermer,
    this.onChange,
  });

  /// Le texte cherche.
  final TextEditingController controleur;

  /// L'etiquette du champ.
  final String libelle;

  /// L'aide dans le champ vide.
  final String aide;

  /// Ferme la recherche (« Fermer la recherche »).
  final VoidCallback onFermer;

  /// Les resultats, sous le champ ; ils gerent leur propre defilement.
  final Widget resultats;

  /// La cle du champ de saisie, pour les tests de l'ecran.
  final Key? cleChamp;

  /// La cle du bouton qui efface, pour les tests de l'ecran.
  final Key? cleEffacer;

  /// La cle du bouton qui ferme, pour les tests de l'ecran.
  final Key? cleFermer;

  /// Chaque changement du texte (voir `ChampRecherche.onChange`).
  final ValueChanged<String>? onChange;

  @override
  Widget build(BuildContext context) {
    final String fermer = t.commun.recherche.fermer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            BoutonIcone(
              key: cleFermer,
              icone: AppIcons.retour,
              libelle: fermer,
              infobulle: fermer,
              onPress: onFermer,
            ),
            Ecart.hSm,
            Expanded(
              child: ChampRecherche(
                controleur: controleur,
                libelle: libelle,
                aide: aide,
                cleChamp: cleChamp,
                cleEffacer: cleEffacer,
                onChange: onChange,
                autofocus: true,
              ),
            ),
          ],
        ),
        Ecart.vLg,
        Expanded(child: resultats),
      ],
    );
  }
}
