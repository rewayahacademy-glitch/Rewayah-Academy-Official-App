import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../core/i18n/cle_audio.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_metriques.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/audio_label.dart';
import '../../../core/widgets/avatar_tile.dart';
import '../../../core/widgets/bento_tile.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/permanent_notice.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/pressable.dart';

/// Banc d'essai des jetons et des composants partages.
///
/// **Compile uniquement avec `--dart-define=GALERIE=true`.** Une version de
/// production ne contient pas cette route : `Env.galerieActive` est faux par
/// defaut et la route n'est alors pas enregistree.
///
/// Trois regles a tenir pour que ce banc ne devienne pas une seconde source de
/// verite : il n'est lie depuis aucun ecran, il ne definit aucun style en
/// propre, et `tool/verifier_jetons.dart` le verifie comme le reste de `lib/`.
class GaleriePage extends StatelessWidget {
  /// Cree la galerie.
  const GaleriePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.galerie.titre)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          const OfflineBanner(),
          BentoTile(
            surface: palette.surfaceWarning,
            child: Text(t.galerie.avertissement),
          ),
          Ecart.vXxxl,

          _Section(titre: t.galerie.paires, enfant: const _Paires()),
          _Section(titre: t.galerie.typographie, enfant: const _Typographie()),
          _Section(titre: t.galerie.polices, enfant: const _Polices()),
          _Section(
            titre: '${t.galerie.composants} : ${t.galerie.modeStandard}',
            enfant: const _Composants(mode: InterfaceMode.standard),
          ),
          _Section(
            titre: '${t.galerie.composants} : ${t.galerie.modeEnfant}',
            enfant: const _Composants(mode: InterfaceMode.enfant),
          ),
          Ecart.vXxxl,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.enfant});

  final String titre;
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(titre, style: Theme.of(context).textTheme.headlineSmall),
        Ecart.vLg,
        enfant,
        Ecart.vXxxl,
      ],
    );
  }
}

class _Paires extends StatelessWidget {
  const _Paires();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Map<String, AppColorPair> paires = <String, AppColorPair>{
      'surfaceBase': palette.surfaceBase,
      'surfacePrimary': palette.surfacePrimary,
      'surfaceSuccess': palette.surfaceSuccess,
      'surfaceWarning': palette.surfaceWarning,
      'surfaceAlert': palette.surfaceAlert,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, AppColorPair> e in paires.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: BentoTile(
              surface: e.value,
              avecBordure: true,
              child: Text(
                e.key,
                style: e.value.applyTo(
                  Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
        BentoTile(
          avecBordure: true,
          child: Text(
            'textOnLightAccent',
            style: palette.textOnLightAccent.applyTo(
              Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Typographie extends StatelessWidget {
  const _Typographie();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _EchelleTexte(
            titre: t.galerie.modeStandard,
            echelle: AppTypography.standard,
          ),
        ),
        Ecart.hLg,
        Expanded(
          child: _EchelleTexte(
            titre: t.galerie.modeEnfant,
            echelle: AppTypography.enfant,
          ),
        ),
      ],
    );
  }
}

class _EchelleTexte extends StatelessWidget {
  const _EchelleTexte({required this.titre, required this.echelle});

  final String titre;
  final TextTheme echelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Map<String, TextStyle?> roles = <String, TextStyle?>{
      'displaySmall': echelle.displaySmall,
      'headlineMedium': echelle.headlineMedium,
      'titleLarge': echelle.titleLarge,
      'bodyLarge': echelle.bodyLarge,
      'bodyMedium': echelle.bodyMedium,
      'labelSmall': echelle.labelSmall,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(titre, style: Theme.of(context).textTheme.titleMedium),
        Ecart.vSm,
        for (final MapEntry<String, TextStyle?> e in roles.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '${e.key} ${e.value?.fontSize?.round()}',
              style: palette.surfaceBase.applyTo(e.value ?? const TextStyle()),
            ),
          ),
      ],
    );
  }
}

class _Polices extends StatelessWidget {
  const _Polices();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.titleLarge ?? const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NotoSans : les Makharij se corrigent a l’oreille',
          style: palette.surfaceBase
              .applyTo(base)
              .copyWith(fontFamily: AppFontFamily.corps),
        ),
        Ecart.vMd,
        Text(
          'VarelaRound : Prochain cours jeudi',
          style: palette.surfaceBase
              .applyTo(base)
              .copyWith(fontFamily: AppFontFamily.titre),
        ),
        Ecart.vMd,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'نوتو عربي',
            style: palette.surfaceBase
                .applyTo(base)
                .copyWith(fontFamily: AppFontFamily.arabeInterface),
          ),
        ),
        Ecart.vMd,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'الحمد لله '
            'رب العالمين',
            style: palette.surfaceBase.applyTo(AppTypography.document()),
          ),
        ),
      ],
    );
  }
}

class _Composants extends StatelessWidget {
  const _Composants({required this.mode});

  final InterfaceMode mode;

  @override
  Widget build(BuildContext context) {
    // On remonte un theme complet plutot que de bricoler les tailles : c'est
    // exactement ce que fait l'application quand le profil change de mode.
    return Theme(
      data: AppTheme.pour(mode),
      child: Builder(
        builder: (BuildContext contexte) {
          final AppPalette palette = AppPalette.of(contexte);
          final AppMetriques metriques = AppMetriques.of(contexte);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('cible tactile ${metriques.cibleTactile.round()} pt'),
              Ecart.vMd,

              // Pressable et BentoTile.
              BentoTile(
                surface: palette.surfacePrimary,
                onPress: () {},
                libelleSemantique: t.eleve.accueil.rejoindre,
                child: Text(
                  t.eleve.accueil.rejoindre,
                  style: palette.surfacePrimary.applyTo(
                    Theme.of(contexte).textTheme.titleLarge ??
                        const TextStyle(),
                  ),
                ),
              ),
              Ecart.vLg,

              // AvatarTile : avec repli sur initiales, et en echec de chargement.
              const Row(
                children: <Widget>[
                  AvatarTile(prenom: 'Amina Bah'),
                  Ecart.hLg,
                  AvatarTile(
                    prenom: 'Ibrahim',
                    urlSignee: 'https://exemple.invalid/introuvable.webp',
                  ),
                ],
              ),
              Ecart.vLg,

              // AudioLabel.
              const AudioLabel(cle: ClesAudio.eleveAccueilRejoindre),
              Ecart.vLg,

              // PermanentNotice : sans parametre, par construction.
              const PermanentNotice(),
              Ecart.vLg,

              // EmptyState.
              SizedBox(
                height: 260,
                child: EmptyState(
                  message: t.vide.aucunCours,
                  invitation: t.vide.aucunCoursDetail,
                  libelleAction: t.commun.reessayer,
                  onAction: () {},
                ),
              ),
              Ecart.vLg,

              // ChoiceCardGroup, avec sa carte « Autre » systematique.
              ChoiceCardGroup(
                options: const <OptionChoix>[
                  OptionChoix(
                    valeur: 'debutant',
                    libelle: 'Debutant',
                    icone: AppIcons.suivi,
                  ),
                  OptionChoix(
                    valeur: 'intermediaire',
                    libelle: 'Intermediaire',
                    icone: AppIcons.suivi,
                  ),
                ],
                onChange: (ReponseChoix _) {},
              ),
              Ecart.vLg,

              // PinPad.
              PinPad(onCodeComplet: (String _) {}),
              Ecart.vLg,

              // Pressable nu, pour mesurer la cible tactile.
              Pressable(
                onPress: () {},
                libelleSemantique: t.commun.continuer,
                child: BentoTile(
                  avecBordure: true,
                  child: Text(t.commun.continuer),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
