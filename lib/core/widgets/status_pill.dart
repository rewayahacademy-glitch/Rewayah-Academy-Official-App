import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// La famille semantique d'un etat nomme.
///
/// Un ton n'est pas une couleur : c'est la famille dont le composant tire sa
/// paire douce et son aplat de pastille. C'est ce qui empeche un ecran de
/// choisir « du vert » sans dire ce que le vert signifie.
enum TonEtat {
  /// Ni bon ni mauvais : en attente, brouillon, non commence.
  neutre,

  /// En cours, actif, retenu.
  accent,

  /// Termine, valide, en direct.
  succes,

  /// A surveiller, en retard, incomplet.
  avertissement,

  /// Refuse, echoue, annule.
  alerte,
}

/// L'accesseur du plan d'integration Teaching Core section 9.2 : centralise
/// la paire douce d'un ton d'etat, jusque-la dupliquee entre `_fond` ici et
/// `CouleurIntention.encre` (`lib/core/tc_outils/couleur_intention.dart`).
///
/// En extension plutot qu'en methode de [AppPalette] : [TonEtat] vit dans ce
/// fichier de widgets, et `app_palette.dart` reste le fichier de jetons purs,
/// sans dependance vers la couche widgets.
extension PaireDeTonEtat on AppPalette {
  /// La paire douce d'un ton : teinte pale, encre foncee de la meme famille.
  /// Le neutre n'a pas de famille semantique, il prend la surface enfoncee de
  /// la rampe.
  AppColorPair paireDe(TonEtat ton) => switch (ton) {
    TonEtat.neutre => surfaceSunken,
    TonEtat.accent => washAccent,
    TonEtat.succes => washSuccess,
    TonEtat.avertissement => washWarning,
    TonEtat.alerte => washAlert,
  };
}

/// Un etat nomme : une pastille de couleur **et** un mot.
///
/// **Jamais la couleur seule** (`docs/design/01-systeme-visuel.md` section 8).
/// Une pastille sans mot ne dit rien a qui ne distingue pas le vert du rouge,
/// et rien du tout a un lecteur d'ecran.
///
/// La pastille est le **seul** endroit du produit ou un aplat sature apparait
/// sans etre l'action principale : elle mesure 8 points, c'est-a-dire trop peu
/// pour peser dans la regle de la zone pleine unique
/// (`01-systeme-visuel.md` section 3).
class StatusPill extends StatelessWidget {
  /// Cree une pilule d'etat.
  const StatusPill({required this.libelle, required this.ton, super.key});

  /// Le mot qui nomme l'etat. Court : deux mots au plus.
  final String libelle;

  /// La famille semantique de l'etat.
  final TonEtat ton;

  /// Diametre de la pastille.
  static const double diametrePastille = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = _fond(palette);
    final Color pastille = _pastille(palette);

    return Semantics(
      label: libelle,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: fond.decoration(borderRadius: AppRadius.arrondiFull),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: diametrePastille,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pastille,
                ),
              ),
            ),
            Ecart.hSm,
            Flexible(
              child: Text(
                libelle,
                style: fond.applyTo(
                  Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// La paire douce de la famille. Voir [PaireDeTonEtat.paireDe].
  AppColorPair _fond(AppPalette palette) => palette.paireDe(ton);

  /// L'aplat sature de la pastille.
  ///
  /// Le neutre prend `borderStrong`, la seule encre neutre qui passe le seuil
  /// de 3:1 des elements porteurs de sens : une pastille grise decorative
  /// serait invisible sur la surface enfoncee.
  Color _pastille(AppPalette palette) => switch (ton) {
    TonEtat.neutre => palette.borderStrong.asBorderSide().color,
    TonEtat.accent => palette.surfacePrimary.background,
    TonEtat.succes => palette.surfaceSuccess.background,
    TonEtat.avertissement => palette.surfaceWarning.background,
    TonEtat.alerte => palette.surfaceAlert.background,
  };
}
