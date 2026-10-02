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
/// **Jamais la couleur seule** (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 8).
/// Une pastille sans mot ne dit rien a qui ne distingue pas le vert du rouge,
/// et rien du tout a un lecteur d'ecran.
///
/// La pastille est le **seul** endroit du produit ou un aplat sature apparait
/// sans etre l'action principale : elle mesure 8 points, c'est-a-dire trop peu
/// pour peser dans la regle de la zone pleine unique
/// (`01-systeme-visuel.md` section 3).
class StatusPill extends StatelessWidget {
  /// Cree une pilule d'etat.
  const StatusPill({
    required this.libelle,
    required this.ton,
    super.key,
    this.marqueur,
  });

  /// Ce qui remplace le disque de statut, ou `null` pour le disque du ton.
  ///
  /// Reserve a `PastilleEtatSeance` (point qui pulse, icone d'annulation) :
  /// le marqueur prend la place du disque, sur [diametrePastille] de large
  /// au plus, sans changer la mise en page de la pilule.
  final Widget? marqueur;

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
    final BoxDecoration pastille = _pastille(palette);

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
          // Etiree par son parent, la pastille garde son contenu au centre
          // (K-54).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            marqueur ??
                SizedBox.square(
                  dimension: diametrePastille,
                  child: DecoratedBox(decoration: pastille),
                ),
            Ecart.hSm,
            Flexible(
              child: Text(
                libelle,
                textAlign: TextAlign.center,
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

  /// Le disque de la pastille.
  ///
  /// Succes, attention, alerte et neutre prennent les **points de statut**
  /// (`palette.pointsStatut`), valides a 3:1 contre leur fond doux et les
  /// surfaces par `test/theme` : l'aplat `surfaceSuccess` clair (`#70EE9C`)
  /// ne mesurait que 1,28:1 sur `washSuccess` (revue phase 0, jetons D8).
  /// L'accent, sans point dedie, garde `surfacePrimary`.
  BoxDecoration _pastille(AppPalette palette) => switch (ton) {
    TonEtat.neutre => palette.pointsStatut.neutre.pastille(),
    TonEtat.accent => BoxDecoration(
      shape: BoxShape.circle,
      color: palette.surfacePrimary.background,
    ),
    TonEtat.succes => palette.pointsStatut.succes.pastille(),
    TonEtat.avertissement => palette.pointsStatut.attention.pastille(),
    TonEtat.alerte => palette.pointsStatut.alerte.pastille(),
  };
}
