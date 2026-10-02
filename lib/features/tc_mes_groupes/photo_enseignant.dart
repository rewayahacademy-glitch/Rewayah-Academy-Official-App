import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';

/// La photo de l'enseignant, ou l'aveu qu'elle manque.
///
/// **La photo est obligatoire** (decision `D-01`) : son absence declenche un
/// etat explicite, jamais un avatar generique silencieux. Ce composant fait
/// donc une distinction que `AvatarTile` seul ne sait pas faire :
///
/// - `photoUrlOuCle == null` : **la photo n'existe pas**. On le dit. C'est un
///   manque de donnee, et le masquer derriere des initiales le rendrait
///   invisible a tout le monde, y compris a l'administration.
/// - `photoUrlOuCle != null` mais [urlSignee] absente : **la photo existe, elle
///   n'est simplement pas encore resolue**. On persiste la cle de stockage,
///   jamais une URL signee qui expire ; la resolution demande une capacite
///   serveur qui n'existe pas encore (section 5 de `TC_CONTRACT_REQUEST_A.md`).
///   Les initiales sont alors un etat de chargement, pas un cache-misere.
///
/// `AvatarTile` est **reutilise tel quel** pour le second cas : son repli, son
/// contour et son cadrage sont deja calibres, et le redessiner ferait diverger
/// deux avatars du meme produit.
class PhotoEnseignant extends StatelessWidget {
  /// Cree la photo d'un enseignant.
  const PhotoEnseignant({
    required this.enseignant,
    super.key,
    this.urlSignee,
    this.diametre,
    this.repliInitiales = false,
  });

  /// Vrai sur un ecran de l'eleve (Accueil du Mode Accessibilite, MA-3) :
  /// une photo manquante y montre les initiales, comme `PhotoEleve` cote
  /// famille. Le manque est une donnee pour l'enseignant et l'administration,
  /// jamais un avertissement pour un enfant. Faux partout ailleurs : l'etat
  /// « photo manquante » reste explicite (D-01).
  final bool repliInitiales;

  /// L'enseignant concerne.
  final EnseignantVM enseignant;

  /// L'URL signee de courte duree, quand l'hote sait la resoudre.
  final String? urlSignee;

  /// Le diametre du cadre.
  final double? diametre;

  @override
  Widget build(BuildContext context) {
    if (!enseignant.photoManquante || repliInitiales) {
      return AvatarTile(
        prenom: enseignant.nomAffichage,
        urlSignee: enseignant.photoManquante ? null : urlSignee,
        diametre: diametre,
      );
    }

    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washWarning;
    final double taille = diametre ?? AppAvatar.moyen;

    // Un etat, donc un libelle : une pastille de couleur seule serait un defaut
    // d'accessibilite (invariant J7). Le libelle complet est porte par la
    // semantique, et la pastille visible est posee par la carte appelante.
    return Semantics(
      label: LibellesGroupe.photoManquante,
      child: SizedBox(
        width: taille,
        height: taille,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: paire.background,
            border: Border.fromBorderSide(palette.borderStrong.asBorderSide()),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: palette.inkWarning.applyTo(const TextStyle()).color,
                size: AppSpacing.xxl,
              ),
              child: Icon(AppIcons.avertissement.repos),
            ),
          ),
        ),
      ),
    );
  }
}
