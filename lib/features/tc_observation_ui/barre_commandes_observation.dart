import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/pressable.dart';

/// Au-dela de ce grossissement du texte, les commandes du telephone passent
/// l'icone au-dessus du libelle (maquette V8 M3) : trois libelles cote a cote
/// ne tiennent plus sur 390 points.
const double seuilTexteEmpile = 1.3;

/// Un point de garde pour l'arrondi des glyphes : au plancher lisible,
/// [TexteSansCoupure] ne retire plus sa marge de deux points, le mot doit
/// seulement tenir dans sa place ; ce point evite de jouer la decision a un
/// arrondi pres.
const double _gardeArrondi = 1;

/// La barre de commandes de la salle d'observation : **trois elements, pas un
/// de plus** (decision du directeur, `03` section 1 bis-5) : le son recu,
/// agrandir le support, quitter. Aucun micro, aucune camera, aucun chat, aucune
/// reaction.
///
/// **Un style par format** (manifeste section 5, « Barre de commandes de
/// l'observation ») : sur telephone, les trois en ligne, a parts egales
/// (maquette V8 M4) ; des la tablette, la barre pleine largeur de D1, son a
/// gauche, agrandir au centre, quitter a droite. La meme icone « Quitter »
/// (fleche de sortie) partout.
///
/// « Son recu » est un **temoin**, pas un bouton : le moteur de salle n'expose
/// aucune commande de volume recu (`VideoSessionProvider`, lecture seule pour
/// ce lot, demande O-9). Il dit si le son de la classe arrive, en mot et en
/// icone, jamais par la couleur seule.
class BarreCommandesObservation extends StatelessWidget {
  /// Cree la barre.
  const BarreCommandesObservation({
    required this.sonRecu,
    required this.agrandi,
    required this.onAgrandir,
    required this.onQuitter,
    required this.large,
    super.key,
  });

  /// Vrai quand le son de la classe arrive.
  final bool sonRecu;

  /// Vrai quand le support occupe toute la salle.
  final bool agrandi;

  /// Agrandit ou reduit le support.
  final VoidCallback onAgrandir;

  /// La sortie volontaire.
  final VoidCallback onQuitter;

  /// Vrai des la tablette : barre de D1.
  final bool large;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) =>
        _barre(context, c.maxWidth),
  );

  /// Vrai quand le mot le plus long d'un libelle affiche ne tient pas a cote
  /// de son medaillon dans la case qu'il aura VRAIMENT en une rangee, meme
  /// reduit au plancher lisible de [TexteSansCoupure]. La barre passe alors
  /// en deux rangees, comme a texte tres agrandi.
  ///
  /// OBS-COUPE-1b (revue du 4 octobre 2026) : la regle precedente supposait
  /// trois tiers egaux. Or, en une rangee, « Quitter » garde sa largeur
  /// propre (pilule, M4) et ne laisse aux deux autres que le reste, et le mot
  /// etait mesure a l'echelle de l'appareil au lieu de celle du theme, sur
  /// laquelle [TexteSansCoupure] pose son plancher. « Agrandir »
  /// etait coupe a 340 et 360 px, « Son interrompu » a 375 px, « Reduire » a
  /// 320 px.
  bool _uneRangeeCoupe(BuildContext context, double largeur) {
    if (!largeur.isFinite) return false;
    final v = t.tc.observation.visite;
    final TextStyle style = _style(context, Theme.of(context).textTheme);
    final double facteur = MediaQuery.textScalerOf(context).scale(1);
    // L'echelle la plus basse que [TexteSansCoupure] s'autorise.
    final double plancher = math.min(echelleMinimaleLisible, facteur);
    final double motLong =
        <String>[
              if (sonRecu) v.sonRecu else v.sonInterrompu,
              if (agrandi) v.reduire else v.agrandir,
            ]
            .map(
              (String l) =>
                  largeurMotLePlusLong(context, l, style, TextScaler.noScaling),
            )
            .reduce(math.max);
    final double cases =
        (largeur -
            2 * AppSpacing.sm -
            2 * AppSpacing.xs -
            _Quitter.largeur(context)) /
        2;
    return cases - _Medaillon.diametre - AppSpacing.sm <
        motLong * plancher + _gardeArrondi;
  }

  /// Vrai quand la barre de D1 (son a gauche, agrandir au centre, quitter a
  /// droite) ne tient pas dans [largeur] sans couper un mot.
  ///
  /// PAGESHELL-200-1 (reserve 2 de la revue OBS-COUPE-1b) : sur un panneau
  /// de 680 a 840 px, texte a 200 ou 300 %, « Agrandir » garde sa largeur
  /// propre au centre et ne laisse a « Quitter » qu'une bande de quelques
  /// points : le mot etait coupe lettre par lettre, et « Son recu » aussi a
  /// 300 %. La barre passe alors en deux rangees, comme sur telephone a
  /// texte tres agrandi.
  bool _barreLargeCoupe(BuildContext context, double largeur) {
    if (!largeur.isFinite) return false;
    final v = t.tc.observation.visite;
    final TextStyle style = _style(context, Theme.of(context).textTheme);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double facteur = echelle.scale(1);
    final double plancher = math.min(echelleMinimaleLisible, facteur);
    // « Agrandir » au centre : sa largeur propre, sur une ligne.
    final TextPainter centre = TextPainter(
      text: TextSpan(
        text: agrandi ? v.reduire : v.agrandir,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    final double agrandir = _Medaillon.diametre + AppSpacing.sm + centre.width;
    centre.dispose();
    // Ce qui reste de chaque cote, pour le son et pour quitter.
    final double cote = (largeur - 2 * AppSpacing.sm - agrandir) / 2;
    final double son =
        _Medaillon.diametre +
        AppSpacing.sm +
        largeurMotLePlusLong(
              context,
              sonRecu ? v.sonRecu : v.sonInterrompu,
              style,
              TextScaler.noScaling,
            ) *
            plancher +
        _gardeArrondi;
    // « Quitter » peut se reduire jusqu'au plancher lisible, comme les
    // autres libelles ([TexteSansCoupure] dans [ActionPrincipale]).
    final double texteQuitter = _Quitter.largeur(context) - _Quitter.marges;
    final double quitter = _Quitter.marges + texteQuitter * plancher / facteur;
    return cote < son || cote < quitter + _gardeArrondi;
  }

  Widget _barre(BuildContext context, double largeur) {
    final AppPalette palette = AppPalette.of(context);
    final bool empile = large
        ? _barreLargeCoupe(context, largeur)
        : (MediaQuery.textScalerOf(context).scale(AppSpacing.lg) /
                      AppSpacing.lg >
                  seuilTexteEmpile ||
              _uneRangeeCoupe(context, largeur));
    final Widget son = _TemoinSon(sonRecu: sonRecu, empile: empile);
    final Widget agrandir = _Agrandir(
      agrandi: agrandi,
      onPress: onAgrandir,
      empile: empile,
    );
    final Widget quitter = _Quitter(onPress: onQuitter, empile: empile);

    return DecoratedBox(
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: large && !empile
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: son,
                    ),
                  ),
                  agrandir,
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: quitter,
                    ),
                  ),
                ],
              )
            // OBS-COUPE-1 : tres agrandie, « Quitter » passe sur sa propre
            // rangee, pleine largeur, sous le son et agrandir. Dans un tiers
            // de 320 px, il se lisait lettre par lettre (« Q/u/i/t/t/e/r »)
            // et la barre mangeait la salle.
            : empile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: son),
                      Ecart.hXs,
                      Expanded(child: agrandir),
                    ],
                  ),
                  Ecart.vSm,
                  quitter,
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(child: son),
                  Ecart.hXs,
                  Expanded(child: agrandir),
                  Ecart.hXs,
                  // La pilule garde sa largeur (M4).
                  quitter,
                ],
              ),
      ),
    );
  }
}

/// Le style des libelles : `labelMedium` sur telephone (trois commandes sur
/// 390 points, M4), `labelLarge` des la tablette (D1).
TextStyle _style(BuildContext context, TextTheme textes) =>
    (AppGabarit.de(context).estLarge
        ? textes.labelLarge
        : textes.labelMedium) ??
    const TextStyle();

/// Une icone et son libelle : cote a cote (M4, D1), ou l'icone au-dessus quand
/// le texte est tres agrandi (M3).
class _IconeEtLibelle extends StatelessWidget {
  const _IconeEtLibelle({
    required this.icone,
    required this.libelle,
    required this.empile,
  });

  final Widget icone;
  final Widget libelle;
  final bool empile;

  @override
  Widget build(BuildContext context) => empile
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[icone, Ecart.vXs, libelle],
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icone,
            Ecart.hSm,
            Flexible(child: libelle),
          ],
        );
}

/// Le medaillon rond d'une commande (maquette M4 : icone dans un cercle doux).
class _Medaillon extends StatelessWidget {
  const _Medaillon({required this.icone, required this.paire});

  final AppIcon icone;
  final AppColorPair paire;

  /// 40 : le medaillon de M4 (environ 44 px sur une planche plus dense). La
  /// cible tactile, elle, reste de 48 (le `Pressable` qui l'entoure).
  static const double diametre = AppSpacing.section;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diametre,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: paire.background,
      ),
      child: Center(
        child: IconTheme(
          data: IconThemeData(color: paire.onBackground, size: AppSpacing.xl),
          child: Icon(icone.repos),
        ),
      ),
    ),
  );
}

/// Le temoin du son recu.
class _TemoinSon extends StatelessWidget {
  const _TemoinSon({required this.sonRecu, required this.empile});

  final bool sonRecu;
  final bool empile;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String libelle = sonRecu
        ? t.tc.observation.visite.sonRecu
        : t.tc.observation.visite.sonInterrompu;

    return Semantics(
      label: libelle,
      excludeSemantics: true,
      child: _IconeEtLibelle(
        empile: empile,
        icone: _Medaillon(
          icone: AppIcons.libelleAudio,
          paire: sonRecu ? palette.washSuccess : palette.surfaceSunken,
        ),
        // OBS-COUPE-1 : jamais « Son interr/ompu » ; le mot se reduit ou
        // passe a la ligne entier.
        libelle: TexteSansCoupure(
          libelle,
          textAlign: empile ? TextAlign.center : TextAlign.start,
          style: (sonRecu ? palette.inkStrong : palette.inkMuted).applyTo(
            _style(context, textes),
          ),
        ),
      ),
    );
  }
}

/// Agrandir ou reduire le support.
class _Agrandir extends StatelessWidget {
  const _Agrandir({
    required this.agrandi,
    required this.onPress,
    required this.empile,
  });

  final bool agrandi;
  final VoidCallback onPress;
  final bool empile;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String libelle = agrandi
        ? t.tc.observation.visite.reduire
        : t.tc.observation.visite.agrandir;

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiSm,
      child: _IconeEtLibelle(
        empile: empile,
        icone: _Medaillon(icone: AppIcons.focus, paire: palette.washAccent),
        libelle: TexteSansCoupure(
          libelle,
          textAlign: empile ? TextAlign.center : TextAlign.start,
          style: palette.inkStrong.applyTo(_style(context, textes)),
        ),
      ),
    );
  }
}

/// « Quitter », en pilule rouge douce (maquette M4, D1).
class _Quitter extends StatelessWidget {
  const _Quitter({required this.onPress, required this.empile});

  final VoidCallback onPress;
  final bool empile;

  /// La largeur propre de la pilule en une rangee : les marges
  /// d'[ActionPrincipale] (`xl` de chaque cote), l'icone (`xl`), l'ecart
  /// (`sm`) et le libelle a l'echelle de l'appareil, mesure dans la graisse
  /// la plus large qu'il puisse prendre (600).
  static double largeur(BuildContext context) {
    final TextStyle style = AppTypography.graisse(
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
      FontWeight.w600,
    );
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: t.tc.observation.visite.quitter,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double texte = p.width;
    p.dispose();
    return marges + texte;
  }

  /// Ce que la pilule ajoute a son libelle : les marges d'[ActionPrincipale]
  /// (`xl` de chaque cote), l'icone (`xl`) et l'ecart (`sm`).
  static const double marges =
      2 * AppSpacing.xl + AppSpacing.xl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final AppColorPair paire = AppPalette.of(context).washAlert;

    // Le bouton du core, registre doux d'alerte (K-54) : fond, centrage et
    // cible tactile viennent d'`ActionPrincipale`, jamais d'une pilule peinte
    // ici. Tres agrandi, il prend la largeur de sa case.
    return ActionPrincipale(
      libelle: t.tc.observation.visite.quitter,
      niveau: NiveauAction.destructive,
      doux: true,
      pleineLargeur: empile,
      prefixe: IconTheme(
        data: IconThemeData(color: paire.onBackground, size: AppSpacing.xl),
        child: Icon(AppIcons.sortie.repos),
      ),
      onPress: onPress,
    );
  }
}
