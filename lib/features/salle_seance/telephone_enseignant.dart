// Fiche 1 de la salle au telephone (26/10/2026, docs/current/maquettes/salle/
// FICHE-1-TELEPHONE-2026-10-26.md) : l'enseignant sous 840 points de large
// (telephone, iPad en portrait).
//
// Au repos, la capsule de sa video en haut et « Commandes » en bas. Au
// toucher, la pilule Micro, Camera, Eleves, Quitter, et « Commandes »
// au-dessus. Toucher la capsule deplie le profil. « Commandes » deplie un
// tiroir a deux onglets : Support (Tableau, « Ranger le support », la
// Bibliotheque), Outils (Stylo, Surligner, Gomme, Annuler, et les couleurs).
// Les eleves montent en feuille du bas, leurs cartes se deplient sur place.
// Rien de neuf : le cadre est [PanneauSeance] (feuille), la Bibliotheque
// [PanneauBibliothequeSalle], les tuiles [TuileCommandeSalle], les eleves
// [PanneauEleves].

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_outils/etat_outils.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/commande_salle.dart' show SurfaceTuilesSalle;
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/setting_row.dart';
import 'actions_seance.dart';
import 'barre_outils_salle.dart';
import 'dock_seance.dart' show CoucheSalle, diametreBoutonAppel;
import 'media_salle.dart';
import 'panneau_bibliotheque_salle.dart';
import 'panneau_eleves.dart';
import 'panneau_seance.dart';
import 'pilule_etat_salle.dart';
import 'salle_seance.dart' show EtatLocalSeance;
import 'vignette_video.dart' show MesuresVignette, SignalVideo, VignetteVideo;
import 'vue_seance.dart';

/// Les deux onglets du tiroir des Commandes du telephone (fiche 1, ligne 7 :
/// l'appel est dans la pilule, jamais dans un onglet).
enum OngletTiroir { support, outils }

/// Fiche 1 (26/10/2026), ligne 2 : la capsule du haut, une seule, sombre,
/// au centre : la vignette video, le point d'etat (rouge seulement sur un
/// enregistrement reel, vert sinon), l'oeil « Voir la video en grand ».
/// Ligne 5 : toucher la capsule (hors de l'oeil) deplie le profil.
class CapsuleVideoTelephone extends StatelessWidget {
  const CapsuleVideoTelephone({
    required this.vue,
    required this.onDeplier,
    this.onRevenirPage,
    this.oeil = true,
    super.key = cle,
  });

  /// Pilote C9 : faux dans la scene sans aucune page (rien a mettre en
  /// grand, aucune page ou revenir).
  final bool oeil;

  /// La video est en grand devant la page (pilote, 26/10) : l'oeil devient
  /// « Revenir a la page » ; `null` : « Voir la video en grand ».
  final VoidCallback? onRevenirPage;

  final VueSeance vue;

  /// Deplie la carte du profil ([ProfilTelephone]).
  final VoidCallback onDeplier;

  /// La cle de la capsule (tests, captures).
  static const Key cle = ValueKey<String>('telephone-capsule');

  /// La cle de « Voir la video en grand ».
  static const Key cleVoir = ValueKey<String>('telephone-capsule-voir');

  /// La cle de « Revenir a la page ».
  static const Key cleRevenir = ValueKey<String>('telephone-capsule-revenir');

  /// La cle de la partie qui deplie le profil.
  static const Key cleDeplier = ValueKey<String>('telephone-capsule-deplier');

  /// La largeur de la video dans la capsule.
  static const double largeurVideo = AppSpacing.respiration * 1.5;

  /// La hauteur de la capsule : la plus haute de la video, de la cible du
  /// point et de l'oeil, et sa marge.
  static double hauteur(BuildContext context) =>
      2 * AppSpacing.sm +
      math.max(
        largeurVideo / MesuresVignette.ratio,
        math.max(AppTouchTarget.standard, diametreBoutonAppel(context)),
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? enGrand = PorteeMediaSalle.de(context)?.onBasculerScene;
    // C1 : UNE surface sombre qui porte la vignette, le point et l'oeil.
    return CoucheSalle(
      child: DecoratedBox(
        decoration: palette.coucheSalle.decoration(
          borderRadius: AppRadius.arrondiLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Pressable(
                key: cleDeplier,
                onPress: onDeplier,
                libelleSemantique: t.salle.seance.contexte.titre,
                arrondiFocus: AppRadius.arrondiMd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    VignetteVideo(
                      vue: vue,
                      largeur: largeurVideo,
                      touchable: false,
                      avecNom: false,
                    ),
                    SizedBox.square(
                      dimension: AppTouchTarget.standard,
                      child: Center(child: PointEtatTelephone(vue: vue)),
                    ),
                  ],
                ),
              ),
              if (!oeil)
                ...<Widget>[]
              else if (onRevenirPage case final VoidCallback revenir)
                BoutonIcone(
                  key: cleRevenir,
                  icone: AppIcons.coran,
                  libelle: t.salle.revenirALaPage,
                  infobulle: t.salle.revenirALaPage,
                  forme: FormeBoutonIcone.appel,
                  onPress: revenir,
                )
              else if (enGrand != null)
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
      ),
    );
  }
}

/// Le point d'etat de la capsule et du profil : rouge seulement sur un
/// enregistrement reel ([VueSeance.voitPointEnregistrement], faux tant
/// qu'aucun cours n'est capte, A-01), vert sinon.
class PointEtatTelephone extends StatelessWidget {
  const PointEtatTelephone({required this.vue, super.key = cle});

  final VueSeance vue;

  /// La cle du point (tests).
  static const Key cle = ValueKey<String>('telephone-point-etat');

  /// Vrai quand le point est rouge (tests).
  static bool rouge(VueSeance vue) => vue.voitPointEnregistrement;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return SizedBox.square(
      dimension: AppSpacing.md,
      child: DecoratedBox(
        decoration:
            (rouge(vue)
                    ? palette.pointsStatut.alerte
                    : palette.pointsStatut.succes)
                .pastille(),
      ),
    );
  }
}

/// Fiche 1, ligne 5 : la carte du profil, depliee depuis la capsule, en haut :
/// la video, le nom, le role, le point d'etat et le signal, « Reduire », et
/// dessous la ligne d'etat de la salle ([PiluleEtatSalle]), qu'on ne lit
/// nulle part ailleurs au telephone.
class ProfilTelephone extends StatelessWidget {
  const ProfilTelephone({
    required this.vue,
    required this.onReduire,
    super.key = cle,
  });

  final VueSeance vue;
  final VoidCallback onReduire;

  /// La cle de la carte (tests, captures).
  static const Key cle = ValueKey<String>('telephone-profil');

  /// La cle de « Reduire ».
  static const Key cleReduire = ValueKey<String>('telephone-profil-reduire');

  // C4 : la capsule depliee, meme surface sombre, texte clair.
  @override
  Widget build(BuildContext context) =>
      CoucheSalle(child: Builder(builder: _contenu));

  Widget _contenu(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String role = vue.titreEnseignant == TitreEnseignant.sayyida
        ? t.salle.seance.contexte.enseignante
        : t.commun.roles.enseignant;
    final Widget identite = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: <Widget>[
        Text(
          vue.nomEnseignant,
          style: palette.coucheSalle.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        Text(
          role,
          style: palette.coucheSalle.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: <Widget>[
            PointEtatTelephone(vue: vue),
            if (vue.voitSignalVideo)
              SignalVideo(
                key: const ValueKey<String>('telephone-profil-signal'),
                barres: vue.signalEnseignant,
              ),
          ],
        ),
      ],
    );
    final Widget reduire = BoutonReduire(
      key: cleReduire,
      mot: t.salle.seance.contexte.reduire,
      semantique: t.salle.seance.contexte.reduireInformations,
      icone: AppIcons.replier,
      sur: palette.coucheSalle,
      onPress: onReduire,
    );
    final Widget photo = VignetteVideo(
      vue: vue,
      largeur: CapsuleVideoTelephone.largeurVideo,
      avecSignal: false,
      avecNom: false,
    );
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    return DecoratedBox(
      decoration: palette.coucheSalle.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // COUPE-MOTS-1 : quand le mot le plus long du nom ou du role ne
            // tient plus a cote de « Reduire », « Reduire » passe dessous, au
            // bord de fin, plutot que de couper le nom.
            LayoutBuilder(
              builder: (BuildContext contexte, BoxConstraints c) {
                final double mot = math.max(
                  largeurMotLePlusLong(
                    contexte,
                    vue.nomEnseignant,
                    textes.titleSmall,
                    echelle,
                  ),
                  largeurMotLePlusLong(
                    contexte,
                    role,
                    textes.bodySmall,
                    echelle,
                  ),
                );
                final double largeurReduire = math.max(
                  AppSpacing.titreEcran,
                  largeurMotLePlusLong(
                        contexte,
                        t.salle.seance.contexte.reduire,
                        textes.labelLarge,
                        echelle,
                      ) +
                      AppSpacing.xs +
                      AppSpacing.xl +
                      2 * AppSpacing.sm,
                );
                const double video = CapsuleVideoTelephone.largeurVideo;
                final bool photoACote =
                    video + AppSpacing.md + mot <= c.maxWidth;
                final bool aCote =
                    photoACote &&
                    video + mot + largeurReduire + 2 * AppSpacing.md <=
                        c.maxWidth;
                if (aCote) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.md,
                    children: <Widget>[
                      photo,
                      Expanded(child: identite),
                      reduire,
                    ],
                  );
                }
                // Etroit ou texte agrandi : « Reduire » sous le nom, au bord
                // de fin ; tres etroit, le nom passe aussi sous la photo.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    if (photoACote)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.md,
                        children: <Widget>[
                          photo,
                          Expanded(child: identite),
                        ],
                      )
                    else ...<Widget>[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: photo,
                      ),
                      identite,
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: reduire,
                    ),
                  ],
                );
              },
            ),
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PiluleEtatSalle(
                vue: vue,
                aLaLigne: true,
                surface: palette.coucheSalle,
                cle: const ValueKey<String>('ligne-etat-telephone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le tiroir des Commandes : « Commandes », « Reduire », deux onglets, sur
/// une seule surface du theme (fiche 1, ligne 7).
class TiroirCommandesTelephone extends ConsumerStatefulWidget {
  const TiroirCommandesTelephone({
    required this.vue,
    required this.actions,
    required this.local,
    required this.hauteur,
    this.ajuste = false,
    super.key = cle,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final EtatLocalSeance local;

  /// Pilote C8 : a 600 de large et plus, le tiroir prend la hauteur de son
  /// contenu, jusqu'a [hauteur].
  final bool ajuste;

  /// La hauteur maximale du tiroir : il la prend si la place le permet (la
  /// meme pour les trois onglets, rien ne saute quand on change d'onglet),
  /// et se tasse quand la pilule de l'appel grandit (texte agrandi).
  final double hauteur;

  /// La cle du tiroir (tests, captures).
  static const Key cle = ValueKey<String>('telephone-tiroir');

  /// La cle des onglets.
  static const Key cleOnglets = ValueKey<String>('telephone-tiroir-onglets');

  /// La cle de « Ranger le support » (fiche 1, ligne 9).
  static const Key cleRanger = ValueKey<String>('salle-ranger-support');

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
    final PorteeMediaSalle? media = PorteeMediaSalle.de(context);
    final VoidCallback? tableau = actions.onTableau;
    final VoidCallback? ranger = vue.voitRanger ? actions.onRanger : null;
    final Widget contenu = switch (_onglet) {
      // Fiche 1, ligne 9 : le Tableau, « Ranger le support » (a la place de
      // la croix du haut), puis la Bibliotheque (le Coran et les supports).
      OngletTiroir.support => PanneauBibliothequeSalle(
        supports: media?.supports ?? const <SupportBibliotheque>[],
        entete: <Widget>[
          if (tableau != null || ranger != null) ...<Widget>[
            CarteLignes(
              lignes: <Widget>[
                if (tableau != null)
                  SettingRow(
                    key: const ValueKey<String>('bouton-tableau'),
                    icon: AppIcons.annoter,
                    title: t.salle.seance.commandes.affichageTableau,
                    value: vue.tableauOuvert
                        ? t.salle.seance.tableauOuvert
                        : t.salle.seance.tableauFerme,
                    onPress: tableau,
                  ),
                if (ranger != null)
                  SettingRow(
                    key: TiroirCommandesTelephone.cleRanger,
                    icon: AppIcons.fermer,
                    title: t.salle.seance.rangement.rangerSupport,
                    onPress: ranger,
                  ),
              ],
            ),
            Ecart.vLg,
          ],
        ],
      ),
      // Fiche 1, ligne 8 : Stylo, Surligner, Gomme, Annuler.
      OngletTiroir.outils => SingleChildScrollView(
        child: OutilsTelephone(vue: vue, actions: actions),
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
        ajusteAuContenu: widget.ajuste,
        sansOmbre: true,
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: widget.ajuste ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            KeyedSubtree(
              key: TiroirCommandesTelephone.cleOnglets,
              // ONGLETS-1 : le selecteur du core, deux segments.
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
                ],
                valeur: _onglet,
                onChange: (OngletTiroir o) => setState(() => _onglet = o),
              ),
            ),
            Ecart.vMd,
            // Les tuiles se posent sur la surface du tiroir, sans bloc d'une
            // autre couleur ; leur encre est la sienne.
            Flexible(
              fit: widget.ajuste ? FlexFit.loose : FlexFit.tight,
              child: SurfaceTuilesSalle(
                surface: AppPalette.of(context).surfaceRaised,
                child: contenu,
              ),
            ),
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
    this.ajuste = false,
    super.key = cle,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final double hauteur;

  /// Pilote C8 : comme le tiroir, a 600 de large et plus.
  final bool ajuste;

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
        // Fiche 1, ligne 11 : « Reduire » comme le tiroir.
        libelleFermer: t.salle.seance.contexte.reduire,
        semantiqueFermer: t.salle.seance.contexte.reduireParticipants,
        forme: FormePanneau.feuille,
        ajusteAuContenu: ajuste,
        sansOmbre: true,
        enfant: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: ajuste ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            LocalFeedback(message: message),
            Flexible(
              fit: ajuste ? FlexFit.loose : FlexFit.tight,
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
