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
class BarreStylet extends ConsumerWidget {
  /// Cree la barre du stylet.
  const BarreStylet({required this.onAnnuler, super.key, this.peutAnnuler = true});

  /// Annule le dernier geste. C'est l'hote qui sait quelle couche est
  /// concernee : la barre ne connait pas les couches.
  final VoidCallback onAnnuler;

  /// Faux quand il n'y a rien a annuler : le bouton devient inerte plutot que
  /// de promettre un geste sans effet.
  final bool peutAnnuler;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final OutilTrait outil in OutilTrait.values)
              BoutonOutil(
                icone: _icone(outil),
                libelle: libelleOutilTrait(outil),
                retenu: etat.outilTrait == outil,
                onPress: () => controleur.choisirOutilTrait(outil),
              ),
            BoutonOutil(
              icone: AppIcons.annuler,
              libelle: t.tc.outils.trait.annuler,
              onPress: peutAnnuler ? onAnnuler : null,
            ),
            BoutonOutil(
              icone: AppIcons.menu,
              libelle: t.tc.outils.trait.plus,
              onPress: () => unawaited(_choisirPortee(context, controleur, etat)),
            ),
          ],
        ),
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
