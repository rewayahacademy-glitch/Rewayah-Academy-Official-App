import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// A grouped settings line. It contains presentation only: no profile write,
/// provider, or navigation contract is coupled to this primitive.
class SettingRow extends StatelessWidget {
  const SettingRow({
    required this.title,
    required this.icon,
    super.key,
    this.description,
    this.value,
    this.controle,
    this.onPress,
    this.enabled = true,
    this.largeurControle,
  });

  final String title;
  final String? description;
  final String? value;

  /// Controle natif place en fin de ligne, sans enveloppe interactive.
  ///
  /// Un [Switch] ou un [Radio] conserve ainsi sa gestion de focus et de geste.
  final Widget? controle;
  final AppIcon icon;
  final VoidCallback? onPress;
  final bool enabled;

  /// La largeur connue du [controle], quand l'ecran peut la donner.
  ///
  /// Nulle (defaut) : une ligne a valeur et controle met la valeur sous le
  /// libelle. Donnee : la valeur reste en fin de ligne tant que libelle,
  /// valeur et controle y tiennent sans couper un mot.
  final double? largeurControle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final active = enabled && onPress != null;
    // Une ligne qui porte un controle natif (interrupteur, rond de choix) sans
    // se presser elle-meme : libelle, description et etat du controle forment
    // un seul noeud pour le lecteur d'ecran, en un seul arret (WCAG 4.1.2).
    // Le libelle vient alors des textes de la ligne, sans doublon.
    final bool fusion = controle != null && onPress == null;
    final Widget ligne = Pressable.selon(
      onPress: active ? onPress : null,
      actif: enabled,
      libelleSemantique: fusion ? null : title,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiMd,
      constructeur: (context, etat) => Container(
        constraints: const BoxConstraints(minHeight: AppPage.hauteurReglage),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: etat.survole || etat.presse
              ? Color.alphaBlend(
                  palette.calqueInteraction(presse: etat.presse),
                  palette.surfaceRaised.background,
                )
              : palette.surfaceRaised.background,
          borderRadius: AppRadius.arrondiMd,
          border: Border(bottom: palette.contourCarte.asBorderSide()),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final TextStyle styleTitre =
                Theme.of(context).textTheme.titleMedium ?? const TextStyle();
            final TextStyle styleSecondaire = palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            );
            // Texte agrandi : aucun mot n'est coupe au milieu (« autom /
            // atiquement ») ; a l'echelle 1, un simple texte, sans mesure.
            final bool agrandi = MediaQuery.textScalerOf(context).scale(1) > 1;
            Widget texte(String s, TextStyle style) => agrandi
                ? TexteSansCoupure(s, style: style)
                : Text(s, style: style);
            final Widget icone = IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icon.repos),
            );
            // Texte agrandi avec un controle : la ligne passe en colonne
            // (icone et titre, puis description et valeur pleine largeur,
            // puis le controle en fin) ; aucun mot n'est comprime ni coupe.
            if (controle != null &&
                MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      icone,
                      Ecart.hMd,
                      Expanded(child: texte(title, styleTitre)),
                    ],
                  ),
                  if (description != null) ...<Widget>[
                    Ecart.vXs,
                    texte(description!, styleSecondaire),
                  ],
                  if (value != null) ...<Widget>[
                    Ecart.vXs,
                    texte(value!, styleSecondaire),
                  ],
                  Ecart.vXs,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: controle,
                  ),
                ],
              );
            }
            final bool dessous =
                value != null &&
                _valeurDoitPasserDessous(
                  context,
                  c.maxWidth,
                  styleTitre,
                  styleSecondaire,
                );
            return Row(
              children: <Widget>[
                icone,
                Ecart.hMd,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      texte(title, styleTitre),
                      if (description != null) ...<Widget>[
                        Ecart.vXs,
                        texte(description!, styleSecondaire),
                      ],
                      // Etroit ou texte agrandi : la valeur passe sous le
                      // libelle au lieu de comprimer la colonne de gauche.
                      if (dessous) ...<Widget>[
                        Ecart.vXs,
                        texte(value!, styleSecondaire),
                      ],
                    ],
                  ),
                ),
                if (value != null && !dessous) ...<Widget>[
                  Ecart.hMd,
                  Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: styleSecondaire,
                  ),
                ],
                if (controle != null) ...<Widget>[Ecart.hSm, controle!],
                if (onPress != null) ...<Widget>[
                  Ecart.hSm,
                  IconTheme(
                    data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.chevron.repos),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
    return fusion ? MergeSemantics(child: ligne) : ligne;
  }

  /// Vrai quand la valeur, en fin de ligne, ne laisserait pas au texte de
  /// gauche la place de ses mots entiers : un mot n'est jamais coupe.
  bool _valeurDoitPasserDessous(
    BuildContext context,
    double largeur,
    TextStyle styleTitre,
    TextStyle styleSecondaire,
  ) {
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    // Un controle de largeur inconnue (pas a pas) : la valeur passe dessous.
    if (echelle.scale(1) > 1.3) return true;
    if (controle != null && largeurControle == null) return true;
    double mesure(String texte, TextStyle style) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: texte, style: style),
        textDirection: Directionality.of(context),
        textScaler: echelle,
      )..layout();
      return p.width;
    }

    double motLong(String? texte, TextStyle style) {
      double m = 0;
      for (final String mot in (texte ?? '').split(RegExp(r'\s+'))) {
        if (mot.isNotEmpty) m = m > mesure(mot, style) ? m : mesure(mot, style);
      }
      return m;
    }

    // Icone, ecarts, controle ou chevron (le padding est deja retire).
    final double reserve =
        AppSpacing.xxl +
        AppSpacing.md * 2 +
        (onPress != null ? AppSpacing.sm + AppSpacing.xl : 0) +
        (controle != null ? AppSpacing.sm + largeurControle! : 0);
    final double gauche = largeur - reserve - mesure(value!, styleSecondaire);
    final double titre = motLong(title, styleTitre);
    final double desc = motLong(description, styleSecondaire);
    return gauche < (titre > desc ? titre : desc);
  }
}
