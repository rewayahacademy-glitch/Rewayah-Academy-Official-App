import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/accent_profil.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Le nom affiche d'un accent de profil.
String libelleAccent(AccentProfil accent) => switch (accent) {
  AccentProfil.menthe => t.ficheEleve.couleur.menthe,
  AccentProfil.ciel => t.ficheEleve.couleur.ciel,
  AccentProfil.lavande => t.ficheEleve.couleur.lavande,
  AccentProfil.rose => t.ficheEleve.couleur.rose,
  AccentProfil.peche => t.ficheEleve.couleur.peche,
  AccentProfil.sable => t.ficheEleve.couleur.sable,
};

/// Le choix de la couleur d'un profil : **un simple selecteur de pastilles**
/// (revue du directeur du 04/10/2026, K-62 : « de simples selecteurs, pas
/// des cartes empilees »).
///
/// Une rangee de ronds de couleur, puis un rond « Sans couleur ». La couleur
/// retenue se voit par trois signaux, jamais la couleur seule : un anneau
/// d'accent autour du rond, une coche dedans, et son nom ecrit dessous. Sous
/// la rangee, une phrase dit la consequence (K-58) : le nom retenu, et les
/// couleurs deja prises par un autre profil du foyer.
///
/// Seul point d'entree du choix d'une couleur de profil : un ecran ne
/// recompose jamais des ronds ou des cartes de couleur.
class SelecteurCouleurProfil extends StatelessWidget {
  /// Cree le selecteur.
  const SelecteurCouleurProfil({
    required this.valeur,
    required this.prenom,
    super.key,
    this.onChoix,
    this.prises = const <AccentProfil, String>{},
  });

  /// La couleur retenue, `null` pour « Sans couleur ».
  final AccentProfil? valeur;

  /// Le prenom du profil, pour la phrase « Sans couleur ».
  final String prenom;

  /// Appele au choix d'une couleur (`null` : sans couleur). `null` quand le
  /// choix ne peut pas aboutir (hors ligne) : les ronds ne se pressent plus,
  /// l'ecran dit pourquoi.
  final void Function(AccentProfil? accent)? onChoix;

  /// Les couleurs deja choisies pour un autre profil du foyer, avec son
  /// prenom.
  final Map<AccentProfil, String> prises;

  /// La cle du rond d'une couleur.
  static Key rondDe(AccentProfil accent) =>
      Key('selecteurCouleur.${accent.name}');

  /// La cle du rond « Sans couleur ».
  static const Key rondAucune = Key('selecteurCouleur.aucune');

  /// Le diametre visible d'un rond (la cible tactile reste de 48, l'anneau
  /// de la couleur retenue de 40).
  static const double diametre = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle note = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final AccentProfil? v = valeur;
    final String? priseRetenue = v == null ? null : prises[v];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: t.ficheEleve.couleur.titre,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              for (final AccentProfil a in AccentProfil.values)
                _Rond(
                  key: rondDe(a),
                  retenu: v == a,
                  lu: switch (prises[a]) {
                    final String autre =>
                      '${libelleAccent(a)}. '
                          '${t.ficheEleve.couleur.dejaPrise(prenom: autre)}',
                    null => libelleAccent(a),
                  },
                  paire: palette.accentProfil(a),
                  onPress: onChoix == null ? null : () => onChoix!(a),
                ),
              _Rond(
                key: rondAucune,
                retenu: v == null,
                lu: t.ficheEleve.couleur.aucune,
                paire: palette.surfaceSunken,
                icone: AppIcons.interdit,
                onPress: onChoix == null ? null : () => onChoix!(null),
              ),
            ],
          ),
        ),
        Ecart.vMd,
        Text(
          v == null
              ? t.ficheEleve.couleur.aucuneDetail(prenom: prenom)
              : t.ficheEleve.couleur.choisie(couleur: libelleAccent(v)),
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (priseRetenue != null)
          Text(
            t.ficheEleve.couleur.dejaPrise(prenom: priseRetenue),
            style: note,
          ),
        for (final MapEntry<AccentProfil, String> p in prises.entries)
          if (p.key != v)
            Text(
              t.ficheEleve.couleur.priseLigne(
                couleur: libelleAccent(p.key),
                prenom: p.value,
              ),
              style: note,
            ),
      ],
    );
  }
}

/// Un rond du selecteur : cible de 48, rond visible de
/// [SelecteurCouleurProfil.diametre].
class _Rond extends StatelessWidget {
  const _Rond({
    required this.retenu,
    required this.lu,
    required this.paire,
    required this.onPress,
    super.key,
    this.icone,
  });

  final bool retenu;
  final String lu;

  /// Le fond du rond et l'encre de sa coche.
  final AppColorPair paire;
  final VoidCallback? onPress;
  final AppIcon? icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    const double d = SelecteurCouleurProfil.diametre;
    final Widget rond = SizedBox.square(
      dimension: AppSpacing.titreEcran,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // L'anneau d'accent de la couleur retenue, ecarte du rond.
          if (retenu)
            SizedBox.square(
              dimension: AppSpacing.section,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    palette.inkAccent.asBorderSide(width: 2),
                  ),
                ),
              ),
            ),
          SizedBox.square(
            dimension: d,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: paire.background,
                border: Border.fromBorderSide(
                  palette.borderResting.asBorderSide(),
                ),
              ),
              child: Center(
                child: retenu
                    ? Icon(
                        AppIcons.succes.actif,
                        size: AppSpacing.xl,
                        color: paire.onBackground,
                      )
                    : icone == null
                    ? null
                    : Icon(
                        icone!.repos,
                        size: AppSpacing.xl,
                        color: paire.onBackground,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
    return Pressable(
      onPress: onPress,
      actif: onPress != null,
      libelleSemantique: lu,
      selectionne: retenu,
      child: rond,
    );
  }
}
