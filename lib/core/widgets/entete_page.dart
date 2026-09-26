import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// L'en-tete d'une page du tuteur : disque retour eventuel, titre, sous-titre,
/// actions a droite (maquettes V1, V2, V4, V8 ; manifeste visuel Tuteur V1
/// sections 3.3 et 3.4).
///
/// - Titre en DM Sans 700 : `headlineSmall` (28) sur telephone,
///   `headlineMedium` (32) au-dela ; annonce comme en-tete.
/// - Disque retour de 48, `surfaceOverlay`, fleche d'accent : seulement pour
///   une page de niveau 2 ou une tache focalisee ([onRetour]).
/// - Actions a droite, dans l'ordre donne : la bascule de theme
///   (`BasculeTheme`, tablette et bureau seulement) puis la cloche
///   ([ClocheNotifications]).
///
/// Ce n'est pas la coquille : `PageShell` reste le seul gabarit de page ;
/// l'en-tete se pose dans son corps ou dans son emplacement d'en-tete.
class EntetePage extends StatelessWidget {
  /// Cree un en-tete.
  const EntetePage({
    required this.titre,
    super.key,
    this.sousTitre,
    this.onRetour,
    this.actions = const <Widget>[],
    this.focusTitre,
  });

  /// Rend le titre focalisable par programme (hors parcours clavier) : une
  /// page y ramene le focus quand son contenu disparait.
  final FocusNode? focusTitre;

  /// Le titre de la page. Il ne souhaite pas la bienvenue.
  final String titre;

  /// Une ligne sous le titre, en encre attenuee.
  final String? sousTitre;

  /// Le retour. Sans lui, pas de disque retour.
  final VoidCallback? onRetour;

  /// Les actions a droite du titre.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final TextStyle styleTitre =
        (mobile ? textes.headlineSmall : textes.headlineMedium) ??
        const TextStyle();

    return Row(
      children: <Widget>[
        if (onRetour != null) ...<Widget>[
          DisqueRetour(onPress: onRetour!),
          Ecart.hMd,
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              titreFocalisable(
                focusTitre,
                Semantics(
                  header: true,
                  child: Text(
                    titre,
                    style: palette.inkStrong.applyTo(styleTitre),
                  ),
                ),
              ),
              if (sousTitre != null) ...<Widget>[
                Ecart.vXs,
                Text(
                  sousTitre!,
                  style: palette.inkMuted.applyTo(
                    textes.bodyLarge ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final Widget action in actions) ...<Widget>[Ecart.hXs, action],
      ],
    );
  }
}

/// Enveloppe [titre] dans un [Focus] hors parcours clavier quand [noeud] est
/// donne ; sinon le rend tel quel (aucune semantique ajoutee).
Widget titreFocalisable(FocusNode? noeud, Widget titre) => noeud == null
    ? titre
    : Focus(focusNode: noeud, skipTraversal: true, child: titre);

/// Le disque retour de 48 : surface des superpositions, filet de carte,
/// fleche d'accent miroitee en arabe. Lu « Retour ».
class DisqueRetour extends StatelessWidget {
  /// Cree le disque.
  const DisqueRetour({
    required this.onPress,
    super.key,
    this.libelleSemantique,
  });

  /// Le retour.
  final VoidCallback onPress;

  /// Ce qu'annonce le disque ; « Retour » par defaut (« Fermer la piece »
  /// dans la visionneuse plein ecran).
  final String? libelleSemantique;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelleSemantique ?? t.commun.entete.retour,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceOverlay.background,
              border: Border.fromBorderSide(
                palette.contourCarte.asBorderSide(),
              ),
            ),
            child: Center(
              child: IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                child: Icon(AppIcons.retour.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La cloche de l'en-tete, et son point de non-lus.
///
/// **Le point n'existe que pour de vrais non-lus** : [nonLues] vient du
/// service de notifications ; tant qu'aucune source n'existe (DB-CPT-04), il
/// vaut `null` et la cloche n'a pas de point. Lue « Notifications » ou
/// « Notifications, n non lues ».
class ClocheNotifications extends StatelessWidget {
  /// Cree la cloche.
  const ClocheNotifications({required this.onPress, super.key, this.nonLues});

  /// L'ouverture des notifications (`/tuteur/notifications`).
  final VoidCallback? onPress;

  /// Le nombre de notifications non lues, tel que le service le rend.
  final int? nonLues;

  /// Diametre du point de non-lus.
  static const double diametrePoint = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final int nombre = nonLues ?? 0;
    final String libelle = switch (nombre) {
      <= 0 => t.commun.entete.notifications,
      1 => t.commun.entete.notificationsUneNonLue,
      _ => t.commun.entete.notificationsNonLues(nombre: nombre),
    };

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Stack(
            children: <Widget>[
              Center(
                child: IconTheme(
                  data: (mobile ? palette.inkStrong : palette.inkMuted)
                      .asIconTheme(size: AppSpacing.xxl),
                  child: Icon(AppIcons.notifications.repos),
                ),
              ),
              if (nombre > 0)
                PositionedDirectional(
                  top: AppSpacing.md,
                  end: AppSpacing.md,
                  child: SizedBox.square(
                    dimension: diametrePoint,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surfacePrimary.background,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: palette.surfaceCanvas.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
