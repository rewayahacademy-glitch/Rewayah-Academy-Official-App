import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Le bandeau permanent de la salle de cours.
///
/// **Ce constructeur ne prend aucun parametre, et c'est le coeur de l'ADR-011.**
///
/// Tout le monde sait que la visite de controle est possible ; personne ne sait
/// qu'elle a lieu. Un bandeau qui apparaitrait a l'entree d'un controleur
/// detruirait l'invisibilite en une seconde. Il affiche donc en continu, pour
/// l'enseignant comme pour l'eleve, la meme ligne inchangee, que le controleur
/// soit present ou non.
///
/// Aucun parametre de visibilite, de texte ou de variante n'existe ici : si un
/// tel parametre existait dans l'API, quelqu'un finirait par s'en servir. Un
/// seul composant, partage entre `ELV-03` et `ENS-03`, garantit qu'il ne peut
/// jamais afficher un texte different selon l'ecran.
///
/// `tool/verifier_jetons.dart` echoue si ce constructeur gagne un parametre.
class PermanentNotice extends StatelessWidget {
  /// Cree le bandeau. Sans parametre, definitivement.
  ///
  /// L'absence de `key` est volontaire, comme celle de tout le reste : ce
  /// constructeur ne doit exposer aucune prise. La regle de lint est donc
  /// ecartee ici, et seulement ici.
  // ignore: use_key_in_widget_constructors
  const PermanentNotice();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.surfaceBase;

    return Semantics(
      liveRegion: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        color: paire.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: paire.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(AppIcons.controleQualite.repos),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                t.salle.bandeauPermanent,
                textAlign: TextAlign.center,
                style: paire.applyTo(
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
