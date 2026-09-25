// Les outils d'enseignement (CLV-06), enseignant seulement.
//
// Pointeur, Marquer, Masquer, Annoter : des tuiles avec libelle. Rendus
// SEULEMENT si `ActionsSeance.onOutil` existe (lib/CLAUDE.md : un outil qui ne
// peut pas aboutir n'est pas affiche ; S CLV-06 : « aucun outil fictif »).
// L'outil choisi est un etat local de cet ecran : il ne publie rien.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';
import 'actions_seance.dart';

/// La disposition des tuiles.
enum FormeOutils {
  /// Desktop CLV-06 (au-dessus du support) et telephone (entre support et
  /// dock, tuiles reparties sur la largeur).
  rangee,

  /// Web etroit : colonne a droite du support.
  colonne,

  /// Desktop CLV-07/08 : carte « Outils d'enseignement » (T5, T6).
  carte,
}

/// Les mesures des tuiles, prises sur les images.
abstract final class MesuresOutils {
  /// Tuile desktop, rangee au-dessus du support (≈ 74 x 88).
  static const Size tuileDesktop = Size(
    AppSpacing.titreEcran + AppSpacing.xxxl,
    AppSpacing.titreEcran + AppSpacing.titreEcran - AppSpacing.sm,
  );

  /// Largeur de la colonne du web etroit (≈ 80).
  static const double colonne = AppSpacing.titreEcran + AppSpacing.xxxl;

  /// Hauteur d'une tuile au telephone (≈ 64).
  static const double hauteurCompacte = AppSpacing.respiration;
}

String _libelle(OutilEnseignement outil) => switch (outil) {
  OutilEnseignement.pointeur => t.salle.seance.outils.pointeur,
  OutilEnseignement.marquer => t.salle.seance.outils.marquer,
  OutilEnseignement.masquer => t.salle.seance.outils.masquer,
  OutilEnseignement.annoter => t.salle.seance.outils.annoter,
};

AppIcon _icone(OutilEnseignement outil) => switch (outil) {
  OutilEnseignement.pointeur => AppIcons.curseur,
  OutilEnseignement.marquer => AppIcons.crayon,
  OutilEnseignement.masquer => AppIcons.oeil,
  OutilEnseignement.annoter => AppIcons.annoter,
};

/// Les quatre outils, dans la [forme] voulue. Rien si [onOutil] est nul.
class OutilsEnseignement extends StatefulWidget {
  const OutilsEnseignement({
    required this.onOutil,
    required this.forme,
    this.initial = OutilEnseignement.pointeur,
    super.key,
  });

  final ValueChanged<OutilEnseignement>? onOutil;
  final FormeOutils forme;

  /// L'outil actif a l'ouverture (images : Pointeur).
  final OutilEnseignement initial;

  @override
  State<OutilsEnseignement> createState() => _OutilsEnseignementState();
}

class _OutilsEnseignementState extends State<OutilsEnseignement> {
  late OutilEnseignement _actif = widget.initial;

  void _choisir(ValueChanged<OutilEnseignement> rappel, OutilEnseignement o) {
    setState(() => _actif = o);
    rappel(o);
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<OutilEnseignement>? rappel = widget.onOutil;
    if (rappel == null) return const SizedBox.shrink();
    Widget tuile(OutilEnseignement o) => _Tuile(
      outil: o,
      actif: o == _actif,
      onPress: () => _choisir(rappel, o),
    );
    final Widget corps = switch (widget.forme) {
      FormeOutils.rangee => LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) {
          // Desktop : tuiles de taille fixe ; ailleurs, reparties.
          final bool fixe = c.maxWidth.isInfinite;
          return Row(
            mainAxisSize: fixe ? MainAxisSize.min : MainAxisSize.max,
            spacing: fixe ? AppSpacing.md : AppSpacing.sm,
            children: <Widget>[
              for (final OutilEnseignement o in OutilEnseignement.values)
                if (fixe)
                  SizedBox.fromSize(
                    size: MesuresOutils.tuileDesktop,
                    child: tuile(o),
                  )
                else
                  Expanded(
                    child: SizedBox(
                      height: MesuresOutils.hauteurCompacte,
                      child: tuile(o),
                    ),
                  ),
            ],
          );
        },
      ),
      FormeOutils.colonne || FormeOutils.carte => SizedBox(
        width: MesuresOutils.colonne,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final OutilEnseignement o in OutilEnseignement.values)
              SizedBox(height: MesuresOutils.colonne, child: tuile(o)),
          ],
        ),
      ),
    };
    return Semantics(
      container: true,
      label: t.salle.seance.outils.titre,
      child: KeyedSubtree(
        key: ValueKey<String>('outils-${widget.forme.name}'),
        child: corps,
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({
    required this.outil,
    required this.actif,
    required this.onPress,
  });

  final OutilEnseignement outil;
  final bool actif;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String libelle = _libelle(outil);
    return Semantics(
      selected: actif,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiMd,
        child: DecoratedBox(
          key: ValueKey<String>('outil-${outil.name}'),
          decoration: (actif ? palette.washAccent : palette.surfaceRaised)
              .decoration(
                borderRadius: AppRadius.arrondiMd,
                side: palette.borderHairline.asBorderSide(),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconTheme(
                  data: (actif ? palette.inkAccent : palette.inkStrong)
                      .asIconTheme(size: AppSpacing.xxl),
                  child: Icon(_icone(outil).resoudre(selectionne: actif)),
                ),
                Ecart.vXs,
                Text(
                  libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
