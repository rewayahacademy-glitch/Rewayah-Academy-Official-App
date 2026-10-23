// Les outils d'enseignement (CLV-06), enseignant seulement.
//
// Pointeur, Ecrire, Marquer, Masquer : des tuiles avec libelle. Rendus
// SEULEMENT si `ActionsSeance.onOutil` existe (lib/CLAUDE.md : un outil qui ne
// peut pas aboutir n'est pas affiche ; S CLV-06 : « aucun outil fictif »).
//
// TB-7b : l'outil retenu est l'etat des outils de cet appareil
// (`etatOutilsProvider`, jamais diffuse) : la surface le lit pour savoir si
// un doigt lit, pointe ou ecrit. Un deuxieme appui le repose (lecture).
// Seulement si la salle a un depot d'annotations (`portAnnotationsProvider`) :
// sans lui (Classe Live, qui ouvre le Teaching Dock par ces tuiles), la
// tuile ne fait que son rappel, comme avant TB-7b ; un trait n'y serait
// jamais pris.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/fonction_indisponible.dart' show PortIndisponible;
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_outil.dart';
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
  OutilEnseignement.ecrire => t.salle.seance.outils.ecrire,
  OutilEnseignement.marquer => t.salle.seance.outils.marquer,
  OutilEnseignement.masquer => t.salle.seance.outils.masquer,
};

AppIcon _icone(OutilEnseignement outil) => switch (outil) {
  OutilEnseignement.pointeur => AppIcons.curseur,
  OutilEnseignement.ecrire => AppIcons.annoter,
  OutilEnseignement.marquer => AppIcons.crayon,
  OutilEnseignement.masquer => AppIcons.oeil,
};

/// TB-7b : l'outil de l'etat des outils que retient chaque tuile.
OutilDock outilDock(OutilEnseignement outil) => switch (outil) {
  OutilEnseignement.pointeur => OutilDock.pointeur,
  OutilEnseignement.ecrire => OutilDock.stylet,
  OutilEnseignement.marquer => OutilDock.marquer,
  OutilEnseignement.masquer => OutilDock.masquer,
};

/// La salle a-t-elle un depot d'annotations ? Ni quand le provider leve, ni
/// quand il rend le depot indisponible du defaut de production (SALLE-ROBUSTE) :
/// aucun serveur, rien ne serait conserve (TB-BR).
bool _depotDisponible(WidgetRef ref) {
  try {
    return ref.read(portAnnotationsProvider) is! PortIndisponible;
  } on Object {
    return false;
  }
}

/// Les outils, dans la [forme] voulue. Rien si [onOutil] est nul.
class OutilsEnseignement extends ConsumerWidget {
  const OutilsEnseignement({
    required this.onOutil,
    required this.forme,
    this.avecEcrire = true,
    this.pied,
    this.outils = OutilEnseignement.values,
    super.key,
  });

  /// TB-10 (plan V2 §19.3 point 4) : les outils proposes ; l'eleve autorise
  /// n'a que « Ecrire ».
  final List<OutilEnseignement> outils;

  final ValueChanged<OutilEnseignement>? onOutil;
  final FormeOutils forme;

  /// TB-7b : « Ecrire » n'est rendu que si la surface montree prend des
  /// notes (page fixe ou tableau libre, `VueSeance.voitEcriture`).
  final bool avecEcrire;

  /// Carte seulement : ce qui suit les outils dans la meme carte (CLV-08 :
  /// Eleves et Supports en liste).
  final Widget? pied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueChanged<OutilEnseignement>? rappel = onOutil;
    if (rappel == null) return const SizedBox.shrink();
    final OutilDock? actif = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    final List<OutilEnseignement> outils = <OutilEnseignement>[
      for (final OutilEnseignement o in this.outils)
        if (avecEcrire || o != OutilEnseignement.ecrire) o,
    ];
    Widget tuile(OutilEnseignement o) => _Tuile(
      outil: o,
      actif: outilDock(o) == actif,
      onPress: () {
        if (_depotDisponible(ref)) {
          ref.read(etatOutilsProvider.notifier).choisirOutil(outilDock(o));
        }
        rappel(o);
      },
    );
    final FormeOutils forme = this.forme;
    final Widget? pied = this.pied;
    final Widget corps = switch (forme) {
      FormeOutils.rangee => LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) {
          // Desktop : tuiles de taille fixe ; ailleurs, reparties.
          final bool fixe = c.maxWidth.isInfinite;
          return Row(
            mainAxisSize: fixe ? MainAxisSize.min : MainAxisSize.max,
            spacing: fixe ? AppSpacing.md : AppSpacing.sm,
            children: <Widget>[
              for (final OutilEnseignement o in outils)
                // Des minimums et non des tailles fixes : a 200 %, la tuile
                // grandit avec son icone et son libelle (W-144).
                if (fixe)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MesuresOutils.tuileDesktop.width,
                      minHeight: MesuresOutils.tuileDesktop.height,
                    ),
                    child: tuile(o),
                  )
                else
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: MesuresOutils.hauteurCompacte,
                      ),
                      child: tuile(o),
                    ),
                  ),
            ],
          );
        },
      ),
      // Desktop avec panneau ouvert (CLV-07/08, Q2) : carte titree, quatre
      // tuiles de meme largeur sur une rangee.
      FormeOutils.carte => DecoratedBox(
        decoration: AppPalette.of(context).surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiLg,
          side: AppPalette.of(context).borderHairline.asBorderSide(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ExcludeSemantics(
                child: Text(
                  t.salle.seance.outils.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppPalette.of(context).inkStrong.applyTo(
                    Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vMd,
              Row(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  for (final OutilEnseignement o in outils)
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MesuresOutils.tuileDesktop.height,
                        ),
                        child: tuile(o),
                      ),
                    ),
                ],
              ),
              if (pied != null) ...<Widget>[Ecart.vLg, pied],
            ],
          ),
        ),
      ),
      // La colonne s'elargit avec le facteur de texte, borne a 200 % (W-144).
      FormeOutils.colonne => SizedBox(
        width:
            MesuresOutils.colonne *
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final OutilEnseignement o in outils)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: MesuresOutils.colonne,
                ),
                child: tuile(o),
              ),
          ],
        ),
      ),
    };
    // TB-RC (revue TB-R, m12) : un outil seul (Ecrire de l'eleve autorise)
    // n'est pas un groupe : il garde son seul nom, jamais « Outils
    // d'enseignement, Ecrire ». Plusieurs outils : le groupe nomme, chaque
    // tuile dans son propre noeud.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: outils.length > 1 || pied != null
          ? t.salle.seance.outils.titre
          : null,
      child: KeyedSubtree(
        key: ValueKey<String>('outils-${forme.name}'),
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
    // L'icone, le mot et la surface sont peints par le composant du core
    // (K-54) ; texte agrandi (DESIGN-GOV, 200 %) : l'icone seule, le libelle en
    // infobulle et pour le lecteur d'ecran, plutot qu'un mot tronque.
    final bool agrandi = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    // Verification TB-10 : une tuile seule sur sa rangee (« Ecrire » de
    // l'eleve) a la place de son mot, meme agrandi : elle le garde.
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => Semantics(
        selected: actif,
        child: BoutonOutil(
          key: ValueKey<String>('outil-${outil.name}'),
          icone: _icone(outil),
          libelle: _libelle(outil),
          retenu: actif,
          avecLibelle:
              !agrandi ||
              (c.maxWidth.isFinite && c.maxWidth >= _largeurAvecMot),
          forme: FormeBoutonOutil.tuile,
          onPress: onPress,
        ),
      ),
    );
  }
}

/// La largeur a partir de laquelle une tuile garde son mot au texte agrandi
/// (trois respirations, 192) : une tuile seule sur sa rangee de telephone.
const double _largeurAvecMot = AppSpacing.respiration * 3;
