// TB-7b (CMD-02, CMD-03 ; plan V2 §4.2, §7, §19.1, §20) : l'ecriture dans
// la salle.
//
// Commandes > Outils > « Ecrire » retient l'outil d'ecriture ; dessous,
// la barre du stylet ([BarreStylet], reprise du Teaching Dock) : Stylo,
// Surligner, Gomme, Annuler, Terminer ; puis les options de l'outil actif,
// « Couleur » et « Epaisseur », en choix courts lisibles par forme, texte
// et couleur. Aucune couleur nouvelle : la couleur derive de l'intention
// (`CouleurIntention`, encres du theme), et le trait garde son intention.
//
// Panneau ferme, une palette courte reste : l'outil actif (qui rouvre les
// Commandes), Annuler, Terminer. « Terminer » repose l'outil : la surface
// revient a la lecture, l'encre demeure.
//
// « Annuler » ne defait que la derniere operation personnelle de la
// surface montree (`historiquePersonnelProvider`), jamais le travail d'un
// autre (§7, UX_REVIEW_TB n. 21).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/filter_pill.dart';
import '../tc_dock/barre_stylet.dart';
import 'vue_seance.dart';

/// Les couleurs proposees : quatre intentions, quatre encres du theme
/// (neutre, accent, alerte, succes). « Pour l'evaluation » (encre
/// d'avertissement, la plus claire sur la page) n'est pas proposee au
/// stylo : un trait fin doit rester lisible de loin.
const List<IntentionPedagogique> couleursEcriture = <IntentionPedagogique>[
  IntentionPedagogique.aRevoir,
  IntentionPedagogique.aApprendre,
  IntentionPedagogique.aRenforcer,
  IntentionPedagogique.aEntretenir,
];

/// Annuler : defait la derniere operation personnelle de [surface].
Future<void> annulerSurLaSurface(
  WidgetRef ref,
  ContentPosition? surface,
) async {
  final PortAnnotations depot;
  try {
    depot = ref.read(portAnnotationsProvider);
  } on Object {
    // Sans depot, rien n'a ete pris, rien n'est a defaire.
    return;
  }
  await ref
      .read(historiquePersonnelProvider.notifier)
      .annuler(surLaSurface(surface), depot);
}

/// La personne ecrit-elle sur la surface montree ? Outil d'ecriture retenu
/// et capacite de la vue.
bool ecritSurLaSurface(WidgetRef ref, VueSeance vue) =>
    vue.voitEcriture &&
    ref.watch(etatOutilsProvider.select((EtatOutils e) => e.styletArme));

/// La phrase qui explique l'outil retenu (K-58) : lecture, Pointeur ou
/// Ecrire. Rien pour Marquer et Masquer (capacites existantes, preservees).
class AideOutil extends ConsumerWidget {
  /// Cree la phrase.
  const AideOutil({super.key = cle});

  /// La cle de la phrase.
  static const Key cle = ValueKey<String>('ecriture-aide-outil');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OutilDock? actif = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    final String? texte = switch (actif) {
      null => t.salle.seance.outils.aideLecture,
      OutilDock.pointeur => t.salle.seance.outils.aidePointeur,
      OutilDock.stylet => t.salle.seance.outils.aideEcrire,
      _ => null,
    };
    if (texte == null) return const SizedBox.shrink();
    return Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle()),
    );
  }
}

/// La partie « Ecrire » du panneau Commandes : la barre, puis les options.
class EcritureSeance extends ConsumerWidget {
  /// Cree la partie.
  const EcritureSeance({required this.vue, super.key = cle});

  /// La cle de la partie.
  static const Key cle = ValueKey<String>('ecriture-seance');

  /// La cle des couleurs.
  static const Key cleCouleur = ValueKey<String>('ecriture-couleur');

  /// La cle des epaisseurs.
  static const Key cleEpaisseur = ValueKey<String>('ecriture-epaisseur');

  final VueSeance vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    final ContentPosition? surface = vue.ancrageSurface;
    final bool peutAnnuler = ref.watch(
      historiquePersonnelProvider.select(
        (HistoriquePersonnel h) => h.peutAnnuler(surLaSurface(surface)),
      ),
    );
    final AppPalette palette = AppPalette.of(context);
    // La gomme n'a ni couleur ni epaisseur : ses options ne sont pas
    // rendues (options de l'outil actif, plan V2 §4.2).
    final bool options = etat.outilTrait != OutilTrait.gomme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarreStylet(
          onAnnuler: () => unawaited(annulerSurLaSurface(ref, surface)),
          peutAnnuler: peutAnnuler,
          avecPortee: false,
          surface: false,
          onTerminer: controleur.relacherOutil,
        ),
        if (options) ...<Widget>[
          Ecart.vLg,
          _Option(
            titre: t.salle.seance.ecriture.couleur,
            aide: t.salle.seance.ecriture.couleurAide,
            // Une pilule par couleur (pastille et intention) : elles passent
            // a la ligne plutot que de couper les mots.
            choix: Wrap(
              key: cleCouleur,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final IntentionPedagogique i in couleursEcriture)
                  FilterPill(
                    libelle: libelleIntentionPedagogique(i),
                    retenue:
                        i ==
                        (couleursEcriture.contains(etat.intention)
                            ? etat.intention
                            : couleursEcriture.first),
                    apercu: _Pastille(
                      encre: CouleurIntention.encre(palette, i).encre,
                    ),
                    onPress: () => controleur.choisirIntention(i),
                  ),
              ],
            ),
          ),
          Ecart.vLg,
          _Option(
            titre: t.salle.seance.ecriture.epaisseur,
            aide: t.salle.seance.ecriture.epaisseurAide,
            choix: ControleSegmente<EpaisseurTrait>(
              key: cleEpaisseur,
              rectangle: true,
              segments: <Segment<EpaisseurTrait>>[
                for (final EpaisseurTrait e in EpaisseurTrait.values)
                  Segment<EpaisseurTrait>(
                    valeur: e,
                    libelle: libelleEpaisseur(e),
                    apercu: _Epaisseur(epaisseur: e, encre: palette.inkStrong),
                  ),
              ],
              valeur: etat.epaisseur,
              onChange: controleur.choisirEpaisseur,
            ),
          ),
        ],
      ],
    );
  }
}

/// Le libelle d'une epaisseur.
String libelleEpaisseur(EpaisseurTrait epaisseur) => switch (epaisseur) {
  EpaisseurTrait.fine => t.salle.seance.ecriture.fine,
  EpaisseurTrait.moyenne => t.salle.seance.ecriture.moyenne,
  EpaisseurTrait.epaisse => t.salle.seance.ecriture.epaisse,
};

/// La palette courte (plan V2 §4.2) : panneau ferme, l'outil actif, Annuler
/// et Terminer. Toucher l'outil actif rouvre les Commandes ([onCommandes]),
/// ou reparaissent les autres outils.
class PaletteEcriture extends ConsumerWidget {
  /// Cree la palette.
  const PaletteEcriture({
    required this.vue,
    required this.onCommandes,
    super.key = cle,
  });

  /// La cle de la palette.
  static const Key cle = ValueKey<String>('ecriture-palette');

  final VueSeance vue;
  final VoidCallback? onCommandes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentPosition? surface = vue.ancrageSurface;
    final bool peutAnnuler = ref.watch(
      historiquePersonnelProvider.select(
        (HistoriquePersonnel h) => h.peutAnnuler(surLaSurface(surface)),
      ),
    );
    return Semantics(
      container: true,
      label: t.salle.seance.ecriture.palette,
      child: BarreStylet(
        compacte: true,
        onOutilActif: onCommandes,
        onAnnuler: () => unawaited(annulerSurLaSurface(ref, surface)),
        peutAnnuler: peutAnnuler,
        avecPortee: false,
        onTerminer: ref.read(etatOutilsProvider.notifier).relacherOutil,
      ),
    );
  }
}

/// Une option de l'outil actif : son titre, la phrase qui l'explique
/// (K-58), puis le choix.
class _Option extends StatelessWidget {
  const _Option({required this.titre, required this.aide, required this.choix});

  final String titre;
  final String aide;
  final Widget choix;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            titre,
            style: palette.inkMuted.applyTo(
              textes.labelLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          aide,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        choix,
      ],
    );
  }
}

/// La pastille d'une couleur d'encre : un disque plein, peint par le bord
/// de l'encre (aucune couleur posee ici).
class _Pastille extends StatelessWidget {
  const _Pastille({required this.encre});

  final AppInkColor encre;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSpacing.lg,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(encre.asBorderSide(width: AppSpacing.sm)),
      ),
    ),
  );
}

/// Le trait d'une epaisseur : la forme dit la valeur (fin, moyen, epais).
class _Epaisseur extends StatelessWidget {
  const _Epaisseur({required this.epaisseur, required this.encre});

  final EpaisseurTrait epaisseur;
  final AppInkColor encre;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AppSpacing.xl,
    height: AppSpacing.lg,
    child: Center(
      child: SizedBox(
        width: AppSpacing.xl,
        height: AppSpacing.xs * epaisseur.facteur,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: encre.asBorderSide(width: AppSpacing.xs * epaisseur.facteur),
            ),
          ),
        ),
      ),
    ),
  );
}
