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
//
// TB-RC (revue TB-R, M6, m32) : une seule voie d'annulation pour le
// clavier de la couche, le panneau et la palette
// (`ControleurHistorique.annuler`), qui rend l'operation defaite a la
// classe par le rappel de la couche ([emettreEcriture]) ; Annuler n'est
// propose que si sa cible est encore sur la surface (meme regle que la
// couche, `HistoriquePersonnel.peutAnnulerParmi`).

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/evenements_outils.dart';
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
import 'notes_deposees.dart';
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

/// TB-RC (M6) : le transport des evenements d'ecriture vers la classe, ou
/// `null` (aucun transport : demonstration, avant BR-1, qui le branche ici).
final Provider<void Function(EvenementOutil evenement)?>
diffusionEcritureProvider = Provider<void Function(EvenementOutil)?>(
  (Ref _) => null,
);

/// S1 (24/10/2026) : le pointeur de l'enseignant vers la classe, en point
/// normalise de la page (0 a 1), `null` quand il se leve ; ou `null` sans
/// transport.
final Provider<void Function(Offset? point)?> diffusionPointeurProvider =
    Provider<void Function(Offset?)?>((Ref _) => null);

/// S1 : le pointeur recu de l'enseignant (point normalise de la page), ou
/// `null` sans transport.
final Provider<ValueListenable<Offset?>?> pointeurDistantProvider =
    Provider<ValueListenable<Offset?>?>((Ref _) => null);

/// TB-RC (M6) : le seul rappel des evenements d'ecriture de la salle,
/// celui de la couche de la surface ET des boutons Annuler. Il tient la
/// marque des traits non partages (TB-11b) et passe l'evenement au
/// transport ([diffusionEcritureProvider]).
void emettreEcriture(WidgetRef ref, VueSeance vue, EvenementOutil evenement) {
  final TraitsNonPartages suivi = ref.read(traitsNonPartagesProvider.notifier);
  if (evenement is EvenementTraitTermine && vue.encreNonPartagee) {
    suivi.ajouter(evenement.trait.id);
  } else if (evenement is EvenementTraitRetire) {
    suivi.retirer(evenement.traitId);
  }
  ref.read(diffusionEcritureProvider)?.call(evenement);
}

/// Les traits que la surface montree peint : ceux de la vue, puis ceux que
/// le depot a pris pour cette page ([notesDeposeesProvider]). [suivre] :
/// lu pendant la construction (le widget se reconstruit quand ils
/// changent) ; faux dans un rappel.
List<TraitVectoriel> traitsDeLaSurface(
  WidgetRef ref,
  VueSeance vue, {
  bool suivre = true,
}) {
  final ContentPosition? ancrage = vue.ancrageSurface;
  if (ancrage == null) return const <TraitVectoriel>[];
  final List<TraitVectoriel> notes = vue.notesAffichees;
  final Set<String> connus = <String>{
    for (final TraitVectoriel trait in notes) trait.id,
  };
  return <TraitVectoriel>[
    ...notes,
    for (final TraitVectoriel trait
        in suivre
            ? ref.watch(notesDeposeesProvider(ancrage.resourceId))
            : ref.read(notesDeposeesProvider(ancrage.resourceId)))
      if (trait.ancrage == ancrage && !connus.contains(trait.id)) trait,
  ];
}

/// TB-RC (m32) : Annuler a-t-il une cible sur la surface montree ? La
/// meme regle que la couche : un trait pose qui n'est plus peint (gomme par
/// un autre) n'est pas propose.
bool peutAnnulerSurLaSurface(
  WidgetRef ref,
  VueSeance vue, {
  bool suivre = true,
}) {
  final HistoriquePersonnel historique = suivre
      ? ref.watch(historiquePersonnelProvider)
      : ref.read(historiquePersonnelProvider);
  return historique.peutAnnulerParmi(surLaSurface(vue.ancrageSurface), <String>{
    for (final TraitVectoriel trait in traitsDeLaSurface(
      ref,
      vue,
      suivre: suivre,
    ))
      if (!historique.retires.contains(trait.id)) trait.id,
  });
}

/// Annuler : defait la derniere operation personnelle de la surface de
/// [vue] et l'emet a la classe par [emettreEcriture] (TB-RC, M6 : la meme
/// voie que le clavier de la couche).
Future<void> annulerSurLaSurface(WidgetRef ref, VueSeance vue) async {
  final PortAnnotations depot;
  try {
    depot = ref.read(portAnnotationsProvider);
  } on Object {
    // Sans depot, rien n'a ete pris, rien n'est a defaire.
    return;
  }
  // m32 : une cible disparue ne consomme pas l'operation en silence.
  if (!peutAnnulerSurLaSurface(ref, vue, suivre: false)) return;
  await ref
      .read(historiquePersonnelProvider.notifier)
      .annuler(
        surLaSurface(vue.ancrageSurface),
        depot,
        emettre: (EvenementOutil e) => emettreEcriture(ref, vue, e),
      );
}

/// TB-10 (plan V2 §5) : l'outil de trace revient au Stylo s'il n'est pas
/// propose a cette personne (Surligner, reserve a l'enseignant).
void garderOutilPropose(WidgetRef ref, VueSeance vue) {
  if (!vue.outilsEcriture.contains(ref.read(etatOutilsProvider).outilTrait)) {
    ref.read(etatOutilsProvider.notifier).choisirOutilTrait(OutilTrait.stylet);
  }
}

/// La personne ecrit-elle sur la surface montree ? Outil d'ecriture retenu
/// et capacite de la vue.
/// TB-11b (tour 2) : pendant la reprise du tableau (ou l'ecriture distante
/// suspendue), non : l'outil reste retenu, la barre revient avec le tableau.
bool ecritSurLaSurface(WidgetRef ref, VueSeance vue) =>
    vue.ecritureProposee &&
    ref.watch(etatOutilsProvider.select((EtatOutils e) => e.styletArme));

/// La phrase qui explique l'outil retenu (K-58) : lecture, Pointeur ou
/// Ecrire. Rien pour Marquer et Masquer (capacites existantes, preservees).
class AideOutil extends ConsumerWidget {
  /// Cree la phrase.
  const AideOutil({this.ecritureSuspendue = false, super.key = cle});

  /// TB-11b (tour 2) : le tableau suspend l'ecriture ; la phrase d'Ecrire
  /// (« ecrivez sur la page ») mentirait, elle n'est pas rendue (la phrase
  /// de la suspension est posee a cote).
  final bool ecritureSuspendue;

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
      OutilDock.stylet =>
        ecritureSuspendue ? null : t.salle.seance.outils.aideEcrire,
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
    final bool peutAnnuler = peutAnnulerSurLaSurface(ref, vue);
    final AppPalette palette = AppPalette.of(context);
    // La gomme n'a ni couleur ni epaisseur : ses options ne sont pas
    // rendues (options de l'outil actif, plan V2 §4.2). TB-10 : la barre de
    // l'eleve reste courte, sans options (plan V2 §5).
    final bool options =
        vue.voitOptionsEcriture && etat.outilTrait != OutilTrait.gomme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarreStylet(
          onAnnuler: () => unawaited(annulerSurLaSurface(ref, vue)),
          peutAnnuler: peutAnnuler,
          avecPortee: false,
          surface: false,
          onTerminer: controleur.relacherOutil,
          outils: vue.outilsEcriture,
        ),
        if (options) ...<Widget>[
          Ecart.vLg,
          _Option(
            titre: t.salle.seance.ecriture.couleur,
            aide: t.salle.seance.ecriture.couleurAide,
            // Une pilule par couleur (pastille et intention) : elles passent
            // a la ligne plutot que de couper les mots.
            // Choix de formulaire, pas un filtre : la couleur du trait a poser.
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
/// et Terminer. Elle prend la place du declencheur « Commandes », qui devient
/// le dernier bouton de sa rangee (une seule rangee, la hauteur reste a la
/// page) ; toucher l'outil actif rouvre aussi les Commandes ([onCommandes]),
/// ou reparaissent les autres outils.
class PaletteEcriture extends ConsumerWidget {
  /// Cree la palette.
  const PaletteEcriture({
    required this.vue,
    required this.onCommandes,
    this.focusCommandes,
    super.key = cle,
  });

  /// La cle de la palette.
  static const Key cle = ValueKey<String>('ecriture-palette');

  final VueSeance vue;
  final VoidCallback? onCommandes;

  /// Le noeud du declencheur, porte par l'entree « Commandes » : la
  /// fermeture du panneau y rend le focus.
  final FocusNode? focusCommandes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool peutAnnuler = peutAnnulerSurLaSurface(ref, vue);
    return Semantics(
      container: true,
      label: t.salle.seance.ecriture.palette,
      child: BarreStylet(
        compacte: true,
        onOutilActif: onCommandes,
        onAnnuler: () => unawaited(annulerSurLaSurface(ref, vue)),
        peutAnnuler: peutAnnuler,
        avecPortee: false,
        onTerminer: ref.read(etatOutilsProvider.notifier).relacherOutil,
        onCommandes: onCommandes,
        focusCommandes: focusCommandes,
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
