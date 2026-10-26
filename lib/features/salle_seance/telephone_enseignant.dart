// Plan de composition de la salle du 26/10/2026, §4 (PR B), valide par le
// directeur a 08:40 : l'enseignant au telephone (moins de 600 points).
//
// Au repos, la page ou le tableau seul et, en bas, « Commandes ». Au toucher,
// en haut la capsule de sa video (« Voir la video en grand »), en bas la
// pilule micro, camera, quitter. « Commandes » deplie un tiroir a trois
// onglets : Support (la Bibliotheque), Outils (Pointeur, Ecrire, Tableau, et
// quand on ecrit la barre d'outils), Seance (micro, camera, eleves, quitter).
// Les eleves montent en feuille du bas, leurs cartes se deplient sur place.
// Rien de neuf : le cadre est [PanneauSeance] (feuille), la Bibliotheque
// [PanneauBibliothequeSalle], les tuiles celles de la barre de l'ordinateur
// ([DockSeance] nommee, [tuileOutilSalle]), la barre d'outils
// [BarreOutilsSalle], les eleves [PanneauEleves].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/selecteur_section.dart';
import 'actions_seance.dart';
import 'barre_outils_salle.dart';
import 'dock_seance.dart';
import 'media_salle.dart';
import 'panneau_bibliotheque_salle.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart';
import 'salle_ordinateur.dart' show tuileOutilSalle;
import 'salle_seance.dart' show EtatLocalSeance;
import 'vignette_video.dart';
import 'vue_seance.dart';

/// Les trois onglets du tiroir des Commandes du telephone.
enum OngletTiroir { support, outils, seance }

/// La capsule du haut : la video de l'enseignant, petite, et « Voir la video
/// en grand ».
class CapsuleVideoTelephone extends StatelessWidget {
  const CapsuleVideoTelephone({required this.vue, super.key = cle});

  final VueSeance vue;

  /// La cle de la capsule (tests, captures).
  static const Key cle = ValueKey<String>('telephone-capsule');

  /// La cle de « Voir la video en grand ».
  static const Key cleVoir = ValueKey<String>('telephone-capsule-voir');

  /// La largeur de la video dans la capsule.
  static const double largeurVideo = AppSpacing.respiration * 1.5;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? enGrand = PorteeMediaSalle.de(context)?.onBasculerScene;
    return DecoratedBox(
      decoration: palette.piluleSalle.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: <Widget>[
            VignetteVideo(vue: vue, largeur: largeurVideo),
            if (enGrand != null)
              BoutonIcone(
                key: cleVoir,
                icone: AppIcons.oeil,
                libelle: t.salle.voirVideoEnGrand,
                infobulle: t.salle.voirVideoEnGrand,
                forme: FormeBoutonIcone.appel,
                onPress: enGrand,
              ),
          ],
        ),
      ),
    );
  }
}

/// Une bande sombre de tuiles, comme la barre de l'ordinateur.
class _Bande extends StatelessWidget {
  const _Bande({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: AppPalette.of(context).surfaceInverse
        .decoration(borderRadius: AppRadius.arrondiLg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(child: child),
    ),
  );
}

/// Le tiroir des Commandes : « Commandes », « Reduire », trois onglets.
class TiroirCommandesTelephone extends ConsumerStatefulWidget {
  const TiroirCommandesTelephone({
    required this.vue,
    required this.actions,
    required this.local,
    required this.hauteur,
    super.key = cle,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// La hauteur maximale du tiroir : il la prend si la place le permet (la
  /// meme pour les trois onglets, rien ne saute quand on change d'onglet),
  /// et se tasse quand la pilule de l'appel grandit (texte agrandi).
  final double hauteur;

  /// La cle du tiroir (tests, captures).
  static const Key cle = ValueKey<String>('telephone-tiroir');

  /// La cle des onglets.
  static const Key cleOnglets = ValueKey<String>('telephone-tiroir-onglets');

  /// La cle de la tuile « Eleves » de l'onglet Seance (le bouton rond du
  /// haut garde la sienne).
  static const Key cleEleves = ValueKey<String>('salle-eleves-tiroir');

  /// La cle de la bande des outils, et celle de la bande de la seance.
  static const Key cleOutils = ValueKey<String>('telephone-tiroir-outils');
  static const Key cleSeance = ValueKey<String>('telephone-tiroir-seance');

  @override
  ConsumerState<TiroirCommandesTelephone> createState() => _EtatTiroir();
}

class _EtatTiroir extends ConsumerState<TiroirCommandesTelephone> {
  /// Un outil retenu rouvre le tiroir sur « Outils », la ou il se change.
  late OngletTiroir _onglet = ref.read(etatOutilsProvider).outilActif == null
      ? OngletTiroir.support
      : OngletTiroir.outils;

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final ActionsSeance actions = widget.actions;
    final EtatLocalSeance local = widget.local;
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final OutilDock? outil = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.outilActif),
    );
    final Widget contenu = switch (_onglet) {
      OngletTiroir.support => PanneauBibliothequeSalle(
        supports: media?.supports ?? const <SupportBibliotheque>[],
      ),
      OngletTiroir.outils => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Bande(
              child: DockSeance(
                key: TiroirCommandesTelephone.cleOutils,
                vue: vue,
                actions: actions,
                microOuvert: local.microOuvert,
                cameraAllumee: local.cameraAllumee,
                nommee: true,
                commandes: const <CommandeDock>[CommandeDock.tableau],
                avant: <Widget>[
                  if (actions.onOutil != null) ...<Widget>[
                    tuileOutilSalle(
                      ref,
                      actions: actions,
                      outil: outil,
                      o: OutilEnseignement.pointeur,
                    ),
                    if (vue.ecritureProposee)
                      tuileOutilSalle(
                        ref,
                        actions: actions,
                        outil: outil,
                        o: OutilEnseignement.ecrire,
                      ),
                  ],
                ],
              ),
            ),
            // Plan §3 : quand l'enseignant ecrit, la barre d'outils, tout
            // visible (stylo, surligneur, gomme, annuler, retablir, couleurs,
            // epaisseurs).
            if (barreOutilsVisible(ref, vue)) ...<Widget>[
              Ecart.vMd,
              BarreOutilsSalle(vue: vue),
            ],
          ],
        ),
      ),
      OngletTiroir.seance => SingleChildScrollView(
        child: _Bande(
          child: DockSeance(
            key: TiroirCommandesTelephone.cleSeance,
            vue: vue,
            actions: actions,
            microOuvert: local.microOuvert,
            cameraAllumee: local.cameraAllumee,
            agrandi: local.agrandi,
            nommee: true,
            commandes: const <CommandeDock>[
              CommandeDock.micro,
              CommandeDock.camera,
              CommandeDock.quitter,
            ],
            avantQuitter: <Widget>[
              if (actions.onEleves case final VoidCallback eleves)
                BoutonAppel(
                  key: TiroirCommandesTelephone.cleEleves,
                  icone: AppIcons.eleves,
                  libelle: t.salle.seance.eleves,
                  nom: t.salle.seance.eleves,
                  onPress: eleves,
                ),
            ],
          ),
        ),
      ),
    };
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.hauteur),
      child: PanneauSeance(
        titre: t.salle.seance.commandes.titre,
        onFermer: actions.onCommandes,
        libelleFermer: t.salle.seance.commandes.reduire,
        semantiqueFermer: t.salle.seance.commandes.reduireSemantique,
        forme: FormePanneau.feuille,
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            KeyedSubtree(
              key: TiroirCommandesTelephone.cleOnglets,
              // ONGLETS-1 : le selecteur du core ; a 360 en texte x2, les
              // trois mots ne tiennent pas en ligne et il passe en menu
              // deroulant plutot que de couper « Support ».
              child: SelecteurSection<OngletTiroir>(
                libelle: t.salle.seance.commandes.titre,
                sections: <Segment<OngletTiroir>>[
                  Segment<OngletTiroir>(
                    valeur: OngletTiroir.support,
                    libelle: t.salle.seance.commandes.ongletSupport,
                  ),
                  Segment<OngletTiroir>(
                    valeur: OngletTiroir.outils,
                    libelle: t.salle.seance.commandes.ongletOutils,
                  ),
                  Segment<OngletTiroir>(
                    valeur: OngletTiroir.seance,
                    libelle: t.salle.seance.commandes.ongletSeance,
                  ),
                ],
                valeur: _onglet,
                onChange: (OngletTiroir o) => setState(() => _onglet = o),
              ),
            ),
            Ecart.vMd,
            Expanded(child: contenu),
          ],
        ),
      ),
    );
  }
}

/// Les eleves de l'enseignant au telephone : une feuille du bas, une carte
/// par eleve qui se deplie sur place (les memes cartes que sur ordinateur).
class FeuilleElevesTelephone extends StatelessWidget {
  const FeuilleElevesTelephone({
    required this.vue,
    required this.actions,
    required this.hauteur,
    super.key = cle,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final double hauteur;

  /// La cle de la feuille (tests, captures).
  static const Key cle = ValueKey<String>('telephone-feuille-eleves');

  @override
  Widget build(BuildContext context) {
    final String? message = PorteeMediaSalle.de(context)?.messageEleves;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hauteur),
      child: PanneauSeance(
        titre: t.salle.seance.compteurEleves(
          connectes: vue.connectes,
          inscrits: vue.inscrits,
        ),
        onFermer: actions.onEleves,
        forme: FormePanneau.feuille,
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LocalFeedback(message: message),
            Expanded(
              child: PanneauEleves(
                eleves: vue.eleves,
                actions: actions,
                recitation: vue.recitation,
                autorisationEcrire: vue.voitAutorisationEcrire,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
