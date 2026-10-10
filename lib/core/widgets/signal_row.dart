import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'status_pill.dart';

/// Une ligne « a traiter » : icone, phrase, anciennete, chevron.
///
/// **C'est le composant du `signal vers action`.** Le parcours attendu d'un
/// tableau de bord est `signal, decision, action`, jamais
/// `tableau de bord, statistiques, menu, recherche, action`
/// (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 2). Une ligne qui n'irait nulle part
/// serait donc un rapport, pas un signal : [onPress] est obligatoire.
///
/// L'etat n'est jamais porte par la seule couleur : l'icone, la phrase et la
/// teinte disent la meme chose trois fois, et un lecteur d'ecran lit la phrase
/// (`01-systeme-visuel.md` section 8).
class SignalRow extends StatelessWidget {
  /// Cree une ligne de signal.
  const SignalRow({
    required this.phrase,
    required this.icone,
    required this.onPress,
    super.key,
    this.anciennete,
    this.ton = TonEtat.neutre,
  });

  /// Ce qu'il y a a traiter, en une phrase. **Pas un code, pas un identifiant
  /// technique** : « Dossier d'identite d'Aicha », pas « KYC-4471 ».
  final String phrase;

  /// L'icone semantique du signal.
  final AppIcon icone;

  /// L'ecran d'action ou mene la ligne.
  final VoidCallback onPress;

  /// Depuis combien de temps le signal attend, en clair : « En attente depuis
  /// 3 jours ». C'est ce qui permet de trier a l'oeil.
  final String? anciennete;

  /// La famille semantique du signal.
  final TonEtat ton;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = _paire(palette);

    final Widget icone = IconTheme(
      data: IconThemeData(color: paire.onBackground, size: AppSpacing.xxl),
      child: Icon(this.icone.repos),
    );
    // Le chevron se miroite en arabe : c'est une direction de lecture, pas
    // une progression du temps.
    final Widget chevron = IconTheme(
      data: IconThemeData(color: paire.onBackground, size: AppSpacing.xl),
      child: Icon(AppIcons.chevron.repos),
    );
    final Widget textesLigne = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // COUPE-MOTS-1 : un mot trop long pour la largeur se reduit
        // (« Remboursement » a 320 px, texte x2, CPT-FUS).
        TexteSansCoupure(
          phrase,
          style: paire.applyTo(textes.titleSmall ?? const TextStyle()),
        ),
        if (anciennete != null) ...<Widget>[
          Ecart.vXs,
          Text(
            anciennete!,
            // L'encre secondaire se choisit sur la surface : `inkFaint`
            // tombe a 4,48 sur la surface enfoncee, et c'est le seul
            // trou de la rampe.
            style: palette
                .encreSecondaireSur(paire)
                .applyTo(textes.bodySmall ?? const TextStyle()),
          ),
        ],
      ],
    );
    // Texte agrandi (`AppGabarit.seuilTexteColonne`, meme seuil que
    // `LigneCleValeur`) : entre l'icone et le chevron, la phrase n'a plus la
    // place d'un mot long a 320 px (« Enseignants », « Contractuels » se
    // coupaient, CPT-FUS). Icone et chevron passent au-dessus, la phrase
    // prend toute la largeur ; l'ordre de lecture ne change pas.
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;

    return AppCard(
      surface: paire,
      onPress: onPress,
      libelleSemantique: anciennete == null ? phrase : '$phrase, $anciennete',
      child: empiler
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(children: <Widget>[icone, const Spacer(), chevron]),
                Ecart.vSm,
                textesLigne,
              ],
            )
          : Row(
              children: <Widget>[
                icone,
                Ecart.hMd,
                Expanded(child: textesLigne),
                Ecart.hSm,
                chevron,
              ],
            ),
    );
  }

  AppColorPair _paire(AppPalette palette) => switch (ton) {
    TonEtat.neutre => palette.surfaceRaised,
    TonEtat.accent => palette.washAccent,
    TonEtat.succes => palette.washSuccess,
    TonEtat.avertissement => palette.washWarning,
    TonEtat.alerte => palette.washAlert,
  };
}
