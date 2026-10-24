// S0.3b et standard des commandes d'appel (pilote et directeur, 24/10/2026) :
// la palette du tableau blanc. Une seconde pilule, posee SUR le tableau quand
// il est ouvert : verticale au bord droit sur ordinateur et tablette,
// horizontale juste au-dessus de la pilule d'appel au telephone. Memes boutons
// ronds que l'appel, icones seules, outil actif rempli : stylet, surligneur,
// gomme, annuler, tout effacer, fermer le tableau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import 'actions_seance.dart';
import 'dock_seance.dart' show diametreBoutonAppel;
import 'ecriture_seance.dart';
import 'vue_seance.dart';

/// La palette du tableau ouvert (enseignant).
class PaletteTableau extends ConsumerWidget {
  /// Cree la palette ; [verticale] au bord droit (ordinateur), sinon en
  /// rangee (telephone).
  const PaletteTableau({
    required this.vue,
    required this.actions,
    this.verticale = false,
    super.key = cle,
  });

  /// La cle de la palette.
  static const Key cle = ValueKey<String>('palette-tableau');

  final VueSeance vue;
  final ActionsSeance actions;
  final bool verticale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    final double diametre = diametreBoutonAppel(context);
    final bool ecrit = etat.styletArme;

    void choisir(OutilTrait outil) {
      if (!ecrit) controleur.choisirOutil(OutilDock.stylet);
      controleur.choisirOutilTrait(outil);
    }

    Widget bouton({
      required AppIcon icone,
      required String libelle,
      required VoidCallback? onPress,
      bool retenu = false,
      Key? key,
    }) => BoutonIcone(
      key: key,
      forme: FormeBoutonIcone.appel,
      icone: icone,
      tonAppel: retenu ? TonAppel.ouvert : TonAppel.actif,
      diametre: diametre,
      libelle: libelle,
      selectionne: onPress == null ? null : retenu,
      onPress: onPress,
    );

    final List<Widget> boutons = <Widget>[
      for (final OutilTrait outil in vue.outilsEcriture)
        bouton(
          key: ValueKey<String>('palette-tableau-${outil.name}'),
          icone: switch (outil) {
            OutilTrait.stylet => AppIcons.stylet,
            OutilTrait.surligneur => AppIcons.surligneur,
            OutilTrait.gomme => AppIcons.effacer,
          },
          libelle: libelleOutilTrait(outil),
          retenu: ecrit && etat.outilTrait == outil,
          onPress: () => choisir(outil),
        ),
      bouton(
        key: const ValueKey<String>('palette-tableau-annuler'),
        icone: AppIcons.annuler,
        libelle: t.tc.outils.trait.annuler,
        onPress: () => unawaited(annulerSurLaSurface(ref, vue)),
      ),
      bouton(
        key: const ValueKey<String>('palette-tableau-effacer'),
        icone: AppIcons.toutEffacer,
        libelle: t.salle.seance.ecriture.toutEffacer,
        onPress: () => unawaited(toutEffacerSurLaSurface(ref, vue)),
      ),
      if (actions.onTableau case final VoidCallback fermer)
        bouton(
          key: const ValueKey<String>('palette-tableau-fermer'),
          icone: AppIcons.fermer,
          libelle: t.salle.seance.fermerTableau,
          onPress: fermer,
        ),
    ];
    final double ecart = verticale ? AppSpacing.lg : AppSpacing.md;
    return Semantics(
      container: true,
      label: t.salle.seance.ecriture.palette,
      child: DecoratedBox(
        decoration: palette.piluleSalle.decoration(
          borderRadius: AppRadius.arrondiFull,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Flex(
            direction: verticale ? Axis.vertical : Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            spacing: ecart,
            children: boutons,
          ),
        ),
      ),
    );
  }
}
