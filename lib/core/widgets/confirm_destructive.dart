import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'app_bottom_sheet.dart';

/// Les trois temps du destructif : question, consequence, deux actions.
///
/// **Seul point d'entree d'une confirmation destructive.** Jamais
/// `clic vers suppression`, et jamais une `AlertDialog` posee dans un ecran :
/// `docs/design/07-catalogue-composants.md` section 6 interdit tout autre
/// chemin.
///
/// Trois regles portees par l'API elle-meme, et non par la relecture
/// (`02-regles-ux.md` section 5) :
///
/// 1. [consequence] est **obligatoire**, et s'ecrit en langage humain : « Son
///    acces sera desactive et ses cahiers ne seront plus consultables depuis ce
///    foyer », jamais « supprimer la ligne ? » ;
/// 2. [libelleConfirmer] **nomme l'objet et l'acte** : « Retirer Aicha », jamais
///    « Supprimer » ni « OK » ;
/// 3. le bouton destructif n'est **ni le premier atteint au doigt ni le premier
///    au clavier** : « Annuler » vient avant lui dans l'ordre de lecture, donc
///    dans l'ordre de tabulation.
class ConfirmDestructive extends StatelessWidget {
  /// Cree le corps d'une confirmation.
  ///
  /// Rendu directement plutot que par [demander] dans la galerie : c'est le
  /// seul moyen de montrer ses etats sans ouvrir une vraie feuille.
  const ConfirmDestructive({
    required this.question,
    required this.consequence,
    required this.libelleConfirmer,
    required this.onConfirmer,
    required this.onAnnuler,
    super.key,
    this.irreversible = false,
  });

  /// La question, qui nomme l'objet : « Retirer Aicha du foyer ? »
  final String question;

  /// Ce qui arrivera, en langage humain. Jamais un terme technique.
  final String consequence;

  /// Le libelle de l'action destructive : un verbe et son objet.
  final String libelleConfirmer;

  /// Ce qui se passe quand la personne confirme.
  final VoidCallback onConfirmer;

  /// Ce qui se passe quand la personne renonce.
  final VoidCallback onAnnuler;

  /// Vrai quand l'acte ne se defait pas.
  ///
  /// **Ce qui n'est pas reversible le dit.** Ce qui l'est propose plutot une
  /// annulation de quelques secondes dans le retour local, et n'a alors pas
  /// besoin de cette feuille du tout.
  final bool irreversible;

  /// Ouvre la confirmation et rend `true` si la personne a confirme.
  ///
  /// Rend `false` en cas d'annulation **comme en cas de fermeture par le
  /// glissement ou par `Echap`** : une feuille fermee n'a rien confirme.
  static Future<bool> demander(
    BuildContext context, {
    required String question,
    required String consequence,
    required String libelleConfirmer,
    bool irreversible = false,
  }) async {
    final bool? reponse = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: question,
      constructeur: (BuildContext contexte) => ConfirmDestructive(
        question: question,
        consequence: consequence,
        libelleConfirmer: libelleConfirmer,
        irreversible: irreversible,
        onConfirmer: () => Navigator.of(contexte).pop(true),
        onAnnuler: () => Navigator.of(contexte).pop(false),
      ),
      // La feuille porte deja la question en titre : le corps n'affiche donc
      // que la consequence, et les deux actions vivent dans la zone collee.
      actions: (BuildContext contexte) => _Actions(
        libelleConfirmer: libelleConfirmer,
        onConfirmer: () => Navigator.of(contexte).pop(true),
        onAnnuler: () => Navigator.of(contexte).pop(false),
      ),
    );
    return reponse ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          consequence,
          style: palette.surfaceRaised.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (irreversible) ...<Widget>[
          Ecart.vMd,
          Text(
            t.destructif.irreversible,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Les deux actions, asymetriques et dans cet ordre.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.libelleConfirmer,
    required this.onConfirmer,
    required this.onAnnuler,
  });

  final String libelleConfirmer;
  final VoidCallback onConfirmer;
  final VoidCallback onAnnuler;

  @override
  Widget build(BuildContext context) {
    // La feuille est ancree au bas de l'ecran : le bas est la zone du pouce.
    // Le destructif n'y est donc **jamais** le premier atteint au doigt, et
    // l'ordre de clavier est force pour qu'il ne le soit pas non plus la
    // (`02-regles-ux.md` section 5). D'ou la dissociation : le destructif est
    // physiquement en haut, « Annuler » en bas et au rang de tabulation 1.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: ActionPrincipale(
              libelle: libelleConfirmer,
              onPress: onConfirmer,
              niveau: NiveauAction.destructive,
            ),
          ),
          Ecart.vMd,
          // Le plus bas au pouce, le premier au clavier : c'est le renoncement
          // qui est a portee, pas la suppression.
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: ActionPrincipale(
              libelle: t.commun.annuler,
              onPress: onAnnuler,
              niveau: NiveauAction.secondaire,
            ),
          ),
        ],
      ),
    );
  }
}
