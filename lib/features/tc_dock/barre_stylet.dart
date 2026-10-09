import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_outil.dart';
import 'feuille_choix.dart';

/// La barre du stylet : cinq boutons, pas un de plus.
///
/// **Pas de palette type Photoshop** (spec section 8.4). Ni epaisseur, ni
/// opacite, ni nuancier : la couleur derive de l'intention, et l'intention se
/// choisit ailleurs, dans le dock. Ce qui reste ici, c'est ce qu'une main tient
/// pendant qu'elle ecrit : l'encre, le surligneur, la gomme, l'annulation, et
/// le reste sous « Plus ».
///
/// « Plus » ouvre la seule question qui ne se devine pas : **combien de temps
/// cette annotation doit-elle vivre**. C'est la seule decision que le systeme
/// ne peut pas prendre a la place de l'enseignant.
///
/// TB-7b (plan V2 §4.2, §19.1) : la meme barre sert la salle. Dans le
/// panneau « Commandes », sous « Ecrire » : Stylo, Surligner, Gomme,
/// Annuler et « Terminer » (sans « Plus » : la conservation se dit dans le
/// contexte de la seance, TB-9). Panneau ferme, la palette courte
/// ([compacte]) : l'outil actif (qui rouvre les Commandes), Annuler,
/// Terminer. Les boutons passent a la ligne plutot que de deborder.
class BarreStylet extends ConsumerWidget {
  /// Cree la barre du stylet.
  const BarreStylet({
    required this.onAnnuler,
    super.key,
    this.peutAnnuler = true,
    this.avecPortee = true,
    this.onTerminer,
    this.compacte = false,
    this.onOutilActif,
    this.surface = true,
  });

  /// La cle de « Terminer ».
  static const Key cleTerminer = ValueKey<String>('barre-stylet-terminer');

  /// La cle d'« Annuler ».
  static const Key cleAnnuler = ValueKey<String>('barre-stylet-annuler');

  /// La cle de l'outil actif de la palette courte.
  static const Key cleOutilActif = ValueKey<String>('barre-stylet-actif');

  /// La cle d'un outil de trace.
  static Key cleOutil(OutilTrait outil) =>
      ValueKey<String>('barre-stylet-${outil.name}');

  /// Annule le dernier geste. C'est l'hote qui sait quelle couche est
  /// concernee : la barre ne connait pas les couches.
  final VoidCallback onAnnuler;

  /// Faux quand il n'y a rien a annuler : le bouton n'est pas rendu
  /// (lib/CLAUDE.md : un bouton qui ne peut pas aboutir n'est pas grise).
  final bool peutAnnuler;

  /// « Plus » (la portee) est rendu.
  final bool avecPortee;

  /// TB-7b : « Terminer » sort de l'ecriture ; `null` : pas de bouton.
  final VoidCallback? onTerminer;

  /// TB-7b : la palette courte du telephone (outil actif, Annuler,
  /// Terminer).
  final bool compacte;

  /// TB-7b, palette courte : toucher l'outil actif rouvre les Commandes, ou
  /// reparaissent les autres outils.
  final VoidCallback? onOutilActif;

  /// La barre porte sa propre surface elevee (barre flottante) ; dans un
  /// panneau, elle se pose a plat.
  final bool surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);

    final List<Widget> boutons = <Widget>[
      if (compacte)
        BoutonOutil(
          key: cleOutilActif,
          icone: _icone(etat.outilTrait),
          libelle: libelleOutilTrait(etat.outilTrait),
          avecLibelle: true,
          retenu: true,
          onPress: onOutilActif,
        )
      else
        for (final OutilTrait outil in OutilTrait.values)
          BoutonOutil(
            key: cleOutil(outil),
            icone: _icone(outil),
            libelle: libelleOutilTrait(outil),
            avecLibelle: !avecPortee,
            retenu: etat.outilTrait == outil,
            onPress: () => controleur.choisirOutilTrait(outil),
          ),
      if (peutAnnuler)
        BoutonOutil(
          key: cleAnnuler,
          icone: AppIcons.annuler,
          libelle: t.tc.outils.trait.annuler,
          avecLibelle: !avecPortee || compacte,
          onPress: onAnnuler,
        ),
      if (avecPortee && !compacte)
        BoutonOutil(
          icone: AppIcons.menu,
          libelle: t.tc.outils.trait.plus,
          onPress: () => unawaited(_choisirPortee(context, controleur, etat)),
        ),
      if (onTerminer case final VoidCallback terminer)
        BoutonOutil(
          key: cleTerminer,
          icone: AppIcons.succes,
          libelle: t.salle.seance.ecriture.terminer,
          avecLibelle: true,
          onPress: terminer,
        ),
    ];
    final Widget rangee = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: boutons,
    );
    if (!surface) return rangee;
    return DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceOverlay,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiLg,
        ombres: AppElevation.niveau2(palette.ombre),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: rangee,
      ),
    );
  }

  Future<void> _choisirPortee(
    BuildContext context,
    ControleurOutils controleur,
    EtatOutils etat,
  ) async {
    final PorteeAnnotation? portee = await FeuilleChoix.ouvrirPortee(
      context,
      titre: t.tc.outils.dock.stylet,
      aide: t.tc.outils.portee.aide,
      porteeInitiale: etat.portee,
    );
    if (portee != null) {
      controleur.choisirPortee(portee);
    }
  }

  static AppIcon _icone(OutilTrait outil) => switch (outil) {
    OutilTrait.stylet => AppIcons.stylet,
    OutilTrait.surligneur => AppIcons.surligneur,
    OutilTrait.gomme => AppIcons.effacer,
  };
}
