import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Un lien de texte suivi d'une fleche : « Voir tout -> », « Voir
/// l'historique -> » (manifeste visuel Tuteur V1, section 3.4).
///
/// **Un lien, pas un bouton.** Il ne porte aucune surface : encre `inkStrong`,
/// souligne au survol, et c'est tout. L'action dominante d'un ecran reste
/// `ActionPrincipale` ; un lien fleche mene ailleurs, il n'engage rien.
///
/// La fleche est decorative : le libelle seul porte le sens, et c'est lui que
/// lit le lecteur d'ecran. Elle se miroite en arabe
/// (`AppIcons.flecheAction`). La cible tactile fait au moins 48 sur 48, meme
/// quand le texte est plus petit (`Pressable`).
class LienFleche extends StatelessWidget {
  /// Cree un lien.
  const LienFleche({
    required this.libelle,
    required this.onPress,
    super.key,
    this.fleche = true,
  });

  /// Le texte du lien : un verbe et son objet (« Voir l'historique »).
  final String libelle;

  /// La destination. `null` rend le lien inerte ; un lien qui ne mene nulle
  /// part ne devrait d'ailleurs pas etre rendu.
  final VoidCallback? onPress;

  /// Faux pour un lien sans fleche, en fin de phrase par exemple.
  final bool fleche;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: (BuildContext contexte, EtatPression etat) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        // Le libelle est deja porte par `Pressable` : le texte visible est
        // retire de l'arbre semantique pour ne pas etre lu deux fois.
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  libelle,
                  style: palette.inkStrong
                      .applyTo(base)
                      .copyWith(
                        decoration: etat.survole || etat.focus
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                ),
              ),
              if (fleche) ...<Widget>[
                Ecart.hXs,
                IconTheme(
                  data: palette.inkStrong.asIconTheme(size: AppSpacing.lg),
                  child: Icon(AppIcons.flecheAction.repos),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
