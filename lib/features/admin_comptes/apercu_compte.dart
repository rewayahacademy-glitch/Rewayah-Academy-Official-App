// PERSONNES-UNE-PAGE, etape (a) (directeur, 20/11/2026 : « Les lignes entieres
// ne sont pas cliquables, on doit viser les 3 points pour ouvrir un menu, alors
// que ce menu doit rester tout en permettant de cliquer la ligne entiere »).
//
// L'apercu d'un compte : ce que la ligne montre deja, sans rien relire, et les
// gestes du menu « ... » de la ligne, sauf celui qui efface. Il n'existe pas de fiche d'un eleve, d'une
// famille ou d'un membre de la direction : la ligne ouvre donc cet apercu
// (contrat de navigation §1, le volet : panneau a droite sur ordinateur, feuille
// du bas au telephone, par `AppBottomSheet`). Un enseignant qui a un dossier
// ouvre son dossier, pas cet apercu.
//
// Aucune lecture, aucune regle : les lignes sont celles des colonnes de la vue,
// les gestes ceux que le menu de la ligne offre (memes capacites).
library;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_actions.dart';

/// Une information de l'apercu : le titre de la colonne et sa valeur.
typedef InformationCompte = ({String titre, String valeur});

/// La cle d'un geste de l'apercu, par son rang dans le menu de la ligne.
Key cleGesteApercuCompte(int rang) =>
    ValueKey<String>('apercu-compte-geste-$rang');

/// La cle du corps de l'apercu.
const Key cleApercuCompte = ValueKey<String>('apercu-compte');

/// Ouvre l'apercu du compte nomme [nom].
///
/// [informations] : les colonnes de la vue, sauf le nom ; une valeur vide n'est
/// pas rendue. [gestes] : les gestes du menu de la ligne qui n'effacent rien
/// (un geste qui efface reste dans le menu) ; choisir un geste ferme l'apercu,
/// puis le lance (une seule surface a la fois).
Future<void> ouvrirApercuCompte(
  BuildContext context, {
  required String nom,
  required List<InformationCompte> informations,
  required List<EntreeAction> gestes,
}) => AppBottomSheet.ouvrir<void>(
  context,
  titre: nom,
  libelleFermer: t.commun.fermer,
  panneauLateral: true,
  constructeur: (BuildContext contexte) => Column(
    key: cleApercuCompte,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final InformationCompte i in informations)
        if (i.valeur.trim().isNotEmpty)
          LigneCleValeur(cle: i.titre, valeur: i.valeur),
      if (gestes.isNotEmpty) Ecart.vLg,
      for (final (int rang, EntreeAction g) in gestes.indexed) ...<Widget>[
        if (rang > 0) Ecart.vSm,
        ActionPrincipale(
          key: cleGesteApercuCompte(rang),
          libelle: g.libelle,
          // Jamais de bouton plein : l'apercu informe d'abord (K-56).
          niveau: NiveauAction.secondaire,
          onPress: () {
            Navigator.of(contexte).pop();
            g.onChoix();
          },
        ),
      ],
    ],
  ),
);
