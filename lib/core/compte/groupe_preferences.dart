// PROFILS P1 (directeur, 11/11/2026) : la section Preferences du Compte,
// posee sur la page, sans engrenage. Theme en choix en ligne (instantane,
// DECISION-FLUIDITE) ; UNE seule ligne « Langue » (langue du compte et de
// l'interface) ; Notifications ; Accessibilite. Une ligne n'existe que si sa
// capacite est servie.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/controle_segmente.dart';
import '../widgets/groupe_reglages.dart';
import 'langue_compte.dart';

/// La section Preferences du Compte.
class GroupePreferences extends ConsumerStatefulWidget {
  /// Cree la section.
  const GroupePreferences({
    super.key,
    this.langue = true,
    this.onNotifications,
    this.onAccessibilite,
  });

  /// Vrai quand la langue du compte est servie : la ligne « Langue » existe.
  final bool langue;

  /// Ouvre les notifications ; nul : pas de ligne.
  final VoidCallback? onNotifications;

  /// Ouvre l'accessibilite ; nul : pas de ligne.
  final VoidCallback? onAccessibilite;

  /// La cle du choix du theme.
  static const Key themeKey = Key('compte.preferences.theme');

  /// La cle de la ligne « Langue ».
  static const Key langueKey = Key('compte.preferences.langue');

  /// La cle d'une langue dans la feuille.
  static Key choixLangueKey(PreferenceLangue langue) =>
      Key('compte.preferences.langue.${langue.name}');

  /// La cle du message « langue non enregistree ».
  static const Key langueNonEnregistreeKey = Key(
    'compte.preferences.langueNonEnregistree',
  );

  @override
  ConsumerState<GroupePreferences> createState() => _GroupePreferencesEtat();
}

class _GroupePreferencesEtat extends ConsumerState<GroupePreferences> {
  bool _langueNonEnregistree = false;

  static String _nomLangue(PreferenceLangue langue) =>
      langue == PreferenceLangue.arabe
      ? t.commun.langue.arabe
      : t.commun.langue.francais;

  Future<void> _choisirLangue() async {
    final PreferenceLangue? choisie =
        await AppBottomSheet.ouvrir<PreferenceLangue>(
          context,
          titre: t.compte.langue,
          constructeur: (BuildContext feuille) => GroupeReglages(
            lignes: <LigneRubrique>[
              for (final PreferenceLangue langue in languesDuCompte)
                LigneRubrique(
                  libelle: _nomLangue(langue),
                  selectionnee:
                      langue == ref.read(preferencesLocalesProvider).langue,
                  onPress: () => Navigator.of(feuille).pop(langue),
                ),
            ],
          ),
        );
    if (choisie == null || !mounted) return;
    final bool ok = await choisirLangueCompte(ref, choisie);
    if (mounted) setState(() => _langueNonEnregistree = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PreferencesLocales preferences = ref.watch(
      preferencesLocalesProvider,
    );
    // La langue affichee est celle de l'interface : le choix explicite, ou,
    // sur « Systeme », la langue que l'interface parle en ce moment.
    final PreferenceLangue langue = switch (preferences.langue) {
      PreferenceLangue.arabe => PreferenceLangue.arabe,
      PreferenceLangue.francais => PreferenceLangue.francais,
      PreferenceLangue.systeme =>
        TranslationProvider.of(context).locale == AppLocale.ar
            ? PreferenceLangue.arabe
            : PreferenceLangue.francais,
    };
    final List<LigneRubrique> lignes = <LigneRubrique>[
      if (widget.langue)
        LigneRubrique(
          libelle: t.compte.langue,
          valeur: _nomLangue(langue),
          onPress: () => unawaited(_choisirLangue()),
        ),
      if (widget.onNotifications != null)
        LigneRubrique(
          libelle: t.compte.notifications,
          onPress: widget.onNotifications,
        ),
      if (widget.onAccessibilite != null)
        LigneRubrique(
          libelle: t.compte.accessibilite,
          onPress: widget.onAccessibilite,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.compte.page.preferences,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          t.compte.page.theme,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        ControleSegmente<PreferenceTheme>(
          key: GroupePreferences.themeKey,
          rectangle: true,
          valeur: preferences.theme,
          onChange: (PreferenceTheme theme) =>
              ref.read(preferencesLocalesProvider.notifier).theme(theme),
          segments: <Segment<PreferenceTheme>>[
            Segment<PreferenceTheme>(
              valeur: PreferenceTheme.systeme,
              libelle: t.compte.themeSysteme,
            ),
            Segment<PreferenceTheme>(
              valeur: PreferenceTheme.clair,
              libelle: t.compte.themeClair,
            ),
            Segment<PreferenceTheme>(
              valeur: PreferenceTheme.sombre,
              libelle: t.compte.themeSombre,
            ),
          ],
        ),
        if (lignes.isNotEmpty) ...<Widget>[
          Ecart.vMd,
          KeyedSubtree(
            key: GroupePreferences.langueKey,
            child: GroupeReglages(lignes: lignes),
          ),
        ],
        if (_langueNonEnregistree) ...<Widget>[
          Ecart.vSm,
          Text(
            t.compte.page.langueNonEnregistree,
            key: GroupePreferences.langueNonEnregistreeKey,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}
