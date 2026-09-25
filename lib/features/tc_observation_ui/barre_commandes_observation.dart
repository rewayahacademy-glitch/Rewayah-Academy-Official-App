import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// Au-dela de ce grossissement du texte, les commandes du telephone passent
/// l'icone au-dessus du libelle (maquette V8 M3) : trois libelles cote a cote
/// ne tiennent plus sur 390 points.
const double seuilTexteEmpile = 1.3;

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
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool empile =
        !large &&
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >
            seuilTexteEmpile;
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
        child: large
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
            : Row(
                children: <Widget>[
                  Expanded(child: son),
                  Ecart.hXs,
                  Expanded(child: agrandir),
                  Ecart.hXs,
                  // La pilule garde sa largeur (M4) ; tres agrandie, elle
                  // prend un tiers comme les deux autres.
                  if (empile) Expanded(child: quitter) else quitter,
                ],
              ),
      ),
    );
  }
}

/// Le style des libelles : `labelMedium` sur telephone (trois commandes sur
/// 390 points, M4), `labelLarge` des la tablette (D1).
TextStyle _style(BuildContext context, TextTheme textes) =>
    (AppGabarit.de(context).estLarge ? textes.labelLarge : textes.labelMedium) ??
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: paire.background),
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
        libelle: Text(
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
        libelle: Text(
          libelle,
          textAlign: empile ? TextAlign.center : TextAlign.start,
          style: palette.inkStrong.applyTo(
            _style(context, textes),
          ),
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = AppPalette.of(context).washAlert;

    return Pressable(
      onPress: onPress,
      libelleSemantique: t.tc.observation.visite.quitter,
      arrondiFocus: AppRadius.arrondiFull,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: DecoratedBox(
          decoration: paire.decoration(
            borderRadius: empile ? AppRadius.arrondiMd : AppRadius.arrondiFull,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: _IconeEtLibelle(
                empile: empile,
                icone: IconTheme(
                  data: IconThemeData(
                    color: paire.onBackground,
                    size: AppSpacing.xl,
                  ),
                  child: Icon(AppIcons.sortie.repos),
                ),
                libelle: Text(
                  t.tc.observation.visite.quitter,
                  textAlign: TextAlign.center,
                  style: paire.applyTo(_style(context, textes)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
