import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/cle_audio.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
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
    // Le passage d'un cran, l'un des trois seuls usages haptiques du produit
    // (`docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md` section 6). Il double la pastille
    // qui se remplit : un enfant qui ne regarde pas l'ecran sait qu'un chiffre
    // est entre.
    unawaited(HapticFeedback.selectionClick());
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
    setState(() => _saisie = _saisie.substring(0, _saisie.length - 1));
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
          // Encre d'alerte, et non `surfaceAlert.applyTo` : cette paire porte du
          // blanc, prevu pour un fond rouge. Pose sur le fond general, le
          // message etait ecrit en blanc sur clair, a 1.19:1. Il existait dans
          // l'arbre et pas a l'ecran.
          Text(
            t.pin.erreur,
            style: palette.inkAlert.applyTo(
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
                      color: palette.surfaceCanvas.onBackground,
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
    // Registre doux, et non l'aplat violet d'origine : dix touches pleines
    // faisaient dix zones saturees sur un meme ecran, la ou la regle n'en
    // autorise qu'une (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 3). Le
    // contour fort porte la lisibilite du bouton, la teinte porte son
    // appartenance a l'accent.
    final AppColorPair paire = palette.washAccent;
    final double cote = metriques.cibleTactile * 1.4;

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: '$chiffre',
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiFull,
      constructeur: (BuildContext contexte, EtatPression etat) => Container(
        width: cote,
        height: cote,
        alignment: Alignment.center,
        decoration: paire.decoration(
          borderRadius: AppRadius.arrondiFull,
          side: etat.survole || etat.presse
              ? palette.borderStrong.asBorderSide(width: 2)
              : palette.borderResting.asBorderSide(width: 2),
        ),
        // Le style chiffre, et non `headlineMedium` : ce role est un titre en
        // DM Sans, police sans chiffres tabulaires. Un chiffre de touche se
        // lit en Plus Jakarta Sans, comme tous les codes du produit.
        //
        // La touche a une taille fixe : a 200 % de texte, le chiffre
        // debordait sur l'anneau (capture 0b du 24/09/2026). Il remplit
        // desormais la touche au plus, sans jamais etre coupe.
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$chiffre',
              style: paire.applyTo(AppTypography.chiffre()),
            ),
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
                  palette.borderResting.asBorderSide(width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
