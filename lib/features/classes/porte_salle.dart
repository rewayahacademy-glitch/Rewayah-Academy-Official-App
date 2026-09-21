import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import 'domaine/conformite.dart';

/// La porte d'entree en Salle : le bouton, ou ce qui l'explique.
///
/// **Le bouton dit la condition avant l'echec.** Pour un membre mineur sans
/// photo d'identification televersee, le serveur refusera le jeton ; plutot
/// que de laisser « Rejoindre » echouer apres le clic, la porte rend un rappel
/// calme : pourquoi la photo est demandee, ce qu'elle permet, et l'action qui
/// debloque. Aucun vocabulaire menacant, et le rappel se reaffiche tant qu'il
/// le faut.
///
/// **Seule une exigence positive bloque.** Une precondition inconnue ou non
/// exigee rend le bouton tel quel : c'est le serveur qui tranche a l'emission
/// du jeton, et l'ecran n'invente pas un blocage pour un eleve adulte.
class PorteSalle extends StatelessWidget {
  /// Cree la porte.
  const PorteSalle({
    required this.precondition,
    required this.onRejoindre,
    super.key,
    this.onAjouterPhoto,
    this.libelle,
  });

  /// Ce que le serveur exige. `null` : inconnu, le bouton reste.
  final PreconditionSalle? precondition;

  /// Ce que fait « Rejoindre ». `null` rend le bouton inerte.
  final VoidCallback? onRejoindre;

  /// Ce que fait « Ajouter la photo ». `null` quand ce n'est pas cet ecran qui
  /// peut l'ajouter : la porte dit alors ou cela se fait.
  final VoidCallback? onAjouterPhoto;

  /// Le libelle du bouton d'entree. Par defaut « Rejoindre ».
  final String? libelle;

  /// La cle du rappel de photo, pour les tests.
  static const Key cleRappelPhoto = Key('porte-salle-photo');

  @override
  Widget build(BuildContext context) {
    final PreconditionSalle? condition = precondition;
    if (condition == null || !condition.bloqueParPhoto) {
      return ActionPrincipale(
        libelle: libelle ?? t.classes.porte.rejoindre,
        onPress: onRejoindre,
      );
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      key: cleRappelPhoto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.classes.porte.photoTitre(prenom: condition.prenom),
            style: textes.titleSmall ?? const TextStyle(),
          ),
          Ecart.vXs,
          Text(
            t.classes.porte.photoRaison,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          if (onAjouterPhoto != null)
            ActionPrincipale(
              libelle: t.classes.porte.ajouterPhoto,
              niveau: NiveauAction.secondaire,
              onPress: onAjouterPhoto,
            )
          else
            Text(
              t.classes.porte.photoParTuteur,
              style: textes.bodySmall ?? const TextStyle(),
            ),
        ],
      ),
    );
  }
}
