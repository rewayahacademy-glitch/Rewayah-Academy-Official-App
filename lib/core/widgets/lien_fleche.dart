import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Un lien de texte suivi d'une fleche : « Voir tout -> », « Voir
/// l'historique -> » (manifeste visuel Tuteur V1, section 3.4).
///
/// **Un lien, pas un bouton.** Il ne porte aucune surface : encre `inkAccent`,
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
    this.icone,
    this.annonceLien = false,
    this.alignerEnFin = false,
    this.legende = false,
  });

  /// Vrai : le lien se range au bord de fin, comme les actions qu'il suit
  /// (HL-A-3) : aucun retrait de fin, lignes alignees en fin quand le texte
  /// passe a la ligne (200 %, 390). Faux (defaut) : rendu inchange.
  final bool alignerEnFin;

  /// Registre de legende (`labelSmall`, fleche plus petite) : le « Voir tout »
  /// d'un titre de rubrique dense. La cible tactile reste de 48 sur 48.
  final bool legende;

  /// Icone decorative facultative devant le libelle (« Comment ca marche ? »
  /// precede de `AppIcons.info`). Le libelle seul reste lu.
  final AppIcon? icone;

  /// Le texte du lien : un verbe et son objet (« Voir l'historique »).
  final String libelle;

  /// La destination. `null` rend le lien inerte ; un lien qui ne mene nulle
  /// part ne devrait d'ailleurs pas etre rendu.
  final VoidCallback? onPress;

  /// Vrai : annonce comme lien (Semantics.link), non comme bouton. Pour un
  /// lien qui deplace le focus dans l'ecran (AD-6).
  final bool annonceLien;

  /// Faux pour un lien sans fleche, en fin de phrase par exemple.
  final bool fleche;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        (legende ? textes.labelSmall : textes.labelLarge) ?? const TextStyle();
    final double tailleIcone = legende ? AppSpacing.md : AppSpacing.lg;

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: libelle,
      lien: annonceLien,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: (BuildContext contexte, EtatPression etat) => Padding(
        padding: alignerEnFin
            ? const EdgeInsetsDirectional.only(start: AppSpacing.xs)
            : const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        // Le libelle est deja porte par `Pressable` : le texte visible est
        // retire de l'arbre semantique pour ne pas etre lu deux fois.
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icone != null) ...<Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.lg),
                  child: Icon(icone!.repos),
                ),
                Ecart.hXs,
              ],
              Flexible(
                child: Text(
                  libelle,
                  textAlign: alignerEnFin ? TextAlign.end : null,
                  style: palette.inkAccent
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
                  data: palette.inkAccent.asIconTheme(size: tailleIcone),
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
