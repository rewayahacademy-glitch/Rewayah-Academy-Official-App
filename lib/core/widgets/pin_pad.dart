import 'package:flutter/material.dart';

import '../i18n/cle_audio.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'audio_label.dart';
import 'pressable.dart';

/// Pave numerique geant pour le code de l'eleve.
///
/// **Le code ne quitte jamais l'appareil.** Ce composant ne transmet aucune
/// valeur : il appelle [onCodeComplet] avec le code saisi, et c'est a la
/// verification **locale** de le comparer a l'empreinte conservee dans le
/// stockage securise. Aucun chemin de ce widget n'envoie le code au reseau
/// (ADR-005, authentification enfant).
class PinPad extends StatefulWidget {
  /// Cree un pave numerique.
  const PinPad({
    required this.onCodeComplet,
    super.key,
    this.longueur = 4,
    this.enErreur = false,
  });

  /// Appele quand [longueur] chiffres ont ete saisis. La verification est
  /// locale, ce rappel ne doit alimenter aucun appel reseau avec le code.
  final void Function(String code) onCodeComplet;

  /// Nombre de chiffres attendus.
  final int longueur;

  /// Affiche l'etat d'echec de la derniere tentative.
  final bool enErreur;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _saisie = '';

  void _ajouter(int chiffre) {
    if (_saisie.length >= widget.longueur) {
      return;
    }
    setState(() => _saisie += '$chiffre');
    if (_saisie.length == widget.longueur) {
      final String code = _saisie;
      setState(() => _saisie = '');
      widget.onCodeComplet(code);
    }
  }

  void _effacer() {
    if (_saisie.isEmpty) {
      return;
    }
    setState(
      () => _saisie = _saisie.substring(0, _saisie.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AudioLabel(cle: ClesAudio.pinTitre),
        Ecart.vXl,
        _Pastilles(
          remplies: _saisie.length,
          total: widget.longueur,
          enErreur: widget.enErreur,
        ),
        if (widget.enErreur) ...<Widget>[
          Ecart.vMd,
          Text(
            t.pin.erreur,
            style: palette.surfaceAlert.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vXxl,
        for (final List<int> ligne in const <List<int>>[
          <int>[1, 2, 3],
          <int>[4, 5, 6],
          <int>[7, 8, 9],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final int chiffre in ligne)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: _Touche(
                      chiffre: chiffre,
                      onPress: () => _ajouter(chiffre),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: metriques.cibleTactile * 1.4 + AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _Touche(chiffre: 0, onPress: () => _ajouter(0)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Pressable(
                onPress: _effacer,
                libelleSemantique: t.pin.effacer,
                child: SizedBox(
                  width: metriques.cibleTactile * 1.4,
                  height: metriques.cibleTactile * 1.4,
                  child: IconTheme(
                    data: IconThemeData(
                      color: palette.surfaceBase.onBackground,
                      size: AppSpacing.xxl,
                    ),
                    child: Icon(AppIcons.effacer.repos),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Touche extends StatelessWidget {
  const _Touche({required this.chiffre, required this.onPress});

  final int chiffre;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final AppColorPair paire = palette.surfacePrimary;
    final double cote = metriques.cibleTactile * 1.4;

    return Pressable(
      onPress: onPress,
      libelleSemantique: '$chiffre',
      respecterCibleTactile: false,
      child: Container(
        width: cote,
        height: cote,
        alignment: Alignment.center,
        decoration: paire.decoration(
          borderRadius: BorderRadius.circular(cote / 2),
        ),
        child: Text(
          '$chiffre',
          style: paire.applyTo(
            Theme.of(context).textTheme.headlineMedium ?? const TextStyle(),
          ),
        ),
      ),
    );
  }
}

class _Pastilles extends StatelessWidget {
  const _Pastilles({
    required this.remplies,
    required this.total,
    required this.enErreur,
  });

  final int remplies;
  final int total;
  final bool enErreur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair pleine = enErreur
        ? palette.surfaceAlert
        : palette.surfacePrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < remplies ? pleine.background : null,
                border: Border.fromBorderSide(
                  palette.borderDefault.asBorderSide(width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
