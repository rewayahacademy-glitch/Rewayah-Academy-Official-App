// Plan de la salle du 26/10/2026 (§3, docs/current/maquettes/salle/
// PLAN-SALLE-COMPOSITION-2026-10-26.md) : la barre d'outils de l'ordinateur,
// au standard de la tablette. Quand l'enseignant ecrit (Ecrire retenu, ou
// tableau ouvert), une barre horizontale se pose juste au-dessus des
// commandes et reste tant qu'il ecrit : Stylo, Surligneur, Gomme, Annuler,
// Retablir, Tout effacer, dix couleurs, trois epaisseurs. Tout visible
// d'un coup, rien dans un menu.
//
// Les couleurs : les quatre tons d'intention d'abord, avec leurs noms (la
// pedagogie reste lisible), puis les six couleurs franches
// ([AppNuancierTrait]). Les pastilles montrent la couleur du trait sur la
// page, qui reste claire dans les deux themes.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_couleur.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/commande_salle.dart' show TuileCommandeSalle;
import '../../core/widgets/controle_segmente.dart';
import 'actions_seance.dart';
import 'dock_seance.dart' show BoutonAppel, diametreBoutonAppel;
import 'ecriture_seance.dart';
import 'outils_enseignement.dart';
import 'vue_seance.dart';

/// Le nom d'une couleur franche.
String libelleCouleurFranche(CouleurFranche couleur) => switch (couleur) {
  CouleurFranche.noir => t.salle.seance.ecriture.couleurs.noir,
  CouleurFranche.bleu => t.salle.seance.ecriture.couleurs.bleu,
  CouleurFranche.turquoise => t.salle.seance.ecriture.couleurs.turquoise,
  CouleurFranche.orange => t.salle.seance.ecriture.couleurs.orange,
  CouleurFranche.rose => t.salle.seance.ecriture.couleurs.rose,
  CouleurFranche.marron => t.salle.seance.ecriture.couleurs.marron,
};

/// Vrai quand la barre d'outils se montre : l'enseignant ecrit sur la
/// surface, ou le tableau est ouvert.
bool barreOutilsVisible(WidgetRef ref, VueSeance vue) =>
    ecritSurLaSurface(ref, vue) || (vue.tableauOuvert && vue.ecritureProposee);

/// Les dix pastilles de couleur du trait : les quatre tons d'intention, puis
/// les six couleurs franches ; toucher une pastille arme l'ecriture
/// ([armer]). La barre de l'ordinateur et la rangee du telephone.
List<Widget> pastillesCouleurSalle(
  EtatOutils etat,
  ControleurOutils controleur,
  VoidCallback armer,
) {
  // La page et le tableau restent clairs : la pastille montre la couleur
  // que le trait aura sur eux.
  final AppPalette page = AppPalette.claire();
  final CouleurFranche? franche = etat.couleur;
  return <Widget>[
    for (final IntentionPedagogique i in couleursEcriture)
      BoutonCouleur(
        key: ValueKey<String>('barre-couleur-${i.valeurSql}'),
        encre: CouleurIntention.encre(page, i).encre,
        libelle: libelleIntentionPedagogique(i),
        retenue: franche == null && etat.intention == i,
        onPress: () {
          armer();
          controleur.choisirIntention(i);
        },
      ),
    for (final CouleurFranche c in CouleurFranche.values)
      BoutonCouleur(
        key: ValueKey<String>('barre-couleur-${c.valeurSql}'),
        encre: encreFranche(c).encre,
        libelle: libelleCouleurFranche(c),
        retenue: franche == c,
        onPress: () {
          armer();
          controleur.choisirCouleur(c);
        },
      ),
  ];
}

/// La largeur du choix des trois epaisseurs (≈ 96 par segment).
const double largeurEpaisseurs = AppSpacing.respiration * 4 + AppSpacing.xxxl;

/// La barre d'outils de l'ordinateur.
class BarreOutilsSalle extends ConsumerWidget {
  const BarreOutilsSalle({required this.vue, super.key = cle});

  /// La cle de la barre.
  static const Key cle = ValueKey<String>('salle-barre-outils');

  final VueSeance vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    final double diametre = diametreBoutonAppel(context);
    final bool ecrit = etat.styletArme;

    void armer() {
      if (!ecrit) controleur.choisirOutil(OutilDock.stylet);
    }

    Widget bouton({
      required Key key,
      required AppIcon icone,
      required String libelle,
      required VoidCallback onPress,
      bool retenu = false,
    }) => BoutonIcone(
      key: key,
      forme: FormeBoutonIcone.appel,
      icone: icone,
      tonAppel: retenu ? TonAppel.ouvert : TonAppel.actif,
      diametre: diametre,
      libelle: libelle,
      infobulle: libelle,
      selectionne: retenu,
      onPress: onPress,
    );

    // Annuler et Retablir disparaissent quand ils n'ont rien a faire ; leur
    // place reste (jamais grise, la barre ne saute pas).
    Widget ouPlace(bool possible, Widget enfant) =>
        possible ? enfant : SizedBox.square(dimension: diametre);

    final List<Widget> outils = <Widget>[
      for (final OutilTrait outil in vue.outilsEcriture)
        bouton(
          key: ValueKey<String>('barre-outils-${outil.name}'),
          icone: switch (outil) {
            OutilTrait.stylet => AppIcons.stylet,
            OutilTrait.surligneur => AppIcons.surligneur,
            OutilTrait.gomme => AppIcons.gomme,
          },
          libelle: libelleOutilTrait(outil),
          retenu: ecrit && etat.outilTrait == outil,
          onPress: () {
            armer();
            controleur.choisirOutilTrait(outil);
          },
        ),
      ouPlace(
        peutAnnulerSurLaSurface(ref, vue),
        bouton(
          key: const ValueKey<String>('barre-outils-annuler'),
          icone: AppIcons.annuler,
          libelle: t.tc.outils.trait.annuler,
          onPress: () => unawaited(annulerSurLaSurface(ref, vue)),
        ),
      ),
      ouPlace(
        peutRetablirSurLaSurface(ref, vue),
        bouton(
          key: const ValueKey<String>('barre-outils-retablir'),
          icone: AppIcons.retablir,
          libelle: t.salle.seance.ecriture.retablir,
          onPress: () => unawaited(retablirSurLaSurface(ref, vue)),
        ),
      ),
      bouton(
        key: const ValueKey<String>('barre-outils-effacer'),
        icone: AppIcons.toutEffacer,
        libelle: t.salle.seance.ecriture.toutEffacer,
        onPress: () => unawaited(toutEffacerSurLaSurface(ref, vue)),
      ),
    ];

    final List<Widget> couleurs = pastillesCouleurSalle(
      etat,
      controleur,
      armer,
    );

    return Semantics(
      container: true,
      label: t.salle.seance.ecriture.palette,
      child: DecoratedBox(
        decoration: palette.piluleSalle.decoration(
          borderRadius: AppRadius.arrondiLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          // Choix de formulaire, pas un filtre : les outils, les couleurs et
          // l'epaisseur du trait a poser, tout visible ; la barre passe sur
          // deux rangees plutot que de couper un groupe.
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _Groupe(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: outils,
                ),
              ),
              Semantics(
                container: true,
                label: t.salle.seance.ecriture.couleur,
                child: _Groupe(
                  child: Row(
                    key: const ValueKey<String>('barre-outils-couleurs'),
                    mainAxisSize: MainAxisSize.min,
                    children: couleurs,
                  ),
                ),
              ),
              // Trois epaisseurs, a la largeur de leurs mots : jamais
              // etirees sur toute la barre.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: largeurEpaisseurs),
                child: ControleSegmente<EpaisseurTrait>(
                  key: const ValueKey<String>('barre-outils-epaisseur'),
                  segments: <Segment<EpaisseurTrait>>[
                    for (final EpaisseurTrait e in EpaisseurTrait.values)
                      Segment<EpaisseurTrait>(
                        valeur: e,
                        libelle: libelleEpaisseur(e),
                      ),
                  ],
                  valeur: etat.epaisseur,
                  onChange: (EpaisseurTrait e) {
                    armer();
                    controleur.choisirEpaisseur(e);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un groupe de la barre : au telephone (plan §4, PR B), la place manque pour
/// dix couleurs sur une rangee ; le groupe defile alors au doigt, sans
/// qu'aucune couleur ni aucun outil disparaisse. Sur ordinateur, il garde sa
/// largeur naturelle.
class _Groupe extends StatelessWidget {
  const _Groupe({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
}

/// Fiche 1 (26/10/2026), ligne 8 : l'onglet Outils du tiroir du telephone.
/// Une rangee de quatre tuiles de meme taille, Stylo, Surligner, Gomme,
/// Annuler, l'outil retenu seul en couleur ; dessous, seulement quand Stylo
/// ou Surligner est retenu, la rangee des couleurs, qui defile au doigt.
/// Retablir, Tout effacer et les epaisseurs restent sur ordinateur. Toucher
/// un outil arme l'ecriture (reponse L8 a du pilote : Stylo arme l'ecriture,
/// Pointeur n'est pas au telephone).
class OutilsTelephone extends ConsumerWidget {
  const OutilsTelephone({
    required this.vue,
    required this.actions,
    super.key = cle,
  });

  /// La cle de l'onglet (tests, captures).
  static const Key cle = ValueKey<String>('telephone-outils');

  /// La cle de la rangee des tuiles.
  static const Key cleTuiles = ValueKey<String>('telephone-outils-tuiles');

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final ControleurOutils controleur = ref.read(etatOutilsProvider.notifier);
    final bool ecrit = etat.styletArme;
    final TextTheme textes = Theme.of(context).textTheme;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final AppPalette palette = AppPalette.of(context);
    final String? suspendue = vue.texteEcritureSuspendue;
    if (!vue.ecritureProposee) {
      // Un outil qui ne peut pas aboutir n'est pas rendu : une phrase dit
      // pourquoi, quand il y en a une.
      return suspendue == null
          ? const SizedBox.shrink()
          : Text(
              suspendue,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            );
    }

    void armer() {
      if (!ecrit && depotAnnotationsDisponible(ref)) {
        controleur.choisirOutil(OutilDock.stylet);
      }
      actions.onOutil?.call(OutilEnseignement.ecrire);
    }

    final List<({Key cle, String nom, Widget? tuile})> cases =
        <({Key cle, String nom, Widget? tuile})>[
          for (final OutilTrait outil in vue.outilsEcriture)
            (
              cle: ValueKey<String>('barre-outils-${outil.name}'),
              nom: libelleOutilTrait(outil),
              tuile: BoutonAppel(
                key: ValueKey<String>('barre-outils-${outil.name}'),
                icone: switch (outil) {
                  OutilTrait.stylet => AppIcons.stylet,
                  OutilTrait.surligneur => AppIcons.surligneur,
                  OutilTrait.gomme => AppIcons.gomme,
                },
                libelle: libelleOutilTrait(outil),
                nom: libelleOutilTrait(outil),
                retenu: ecrit && etat.outilTrait == outil,
                selectionne: ecrit && etat.outilTrait == outil,
                onPress: () {
                  armer();
                  controleur.choisirOutilTrait(outil);
                },
              ),
            ),
          // Annuler disparait quand il n'a rien a faire ; sa case reste (jamais
          // grise, la rangee ne saute pas).
          (
            cle: const ValueKey<String>('barre-outils-annuler'),
            nom: t.tc.outils.trait.annuler,
            tuile: peutAnnulerSurLaSurface(ref, vue)
                ? BoutonAppel(
                    key: const ValueKey<String>('barre-outils-annuler'),
                    icone: AppIcons.annuler,
                    libelle: t.tc.outils.trait.annuler,
                    nom: t.tc.outils.trait.annuler,
                    onPress: () => unawaited(annulerSurLaSurface(ref, vue)),
                  )
                : null,
          ),
        ];
    final bool couleurs =
        ecrit &&
        (etat.outilTrait == OutilTrait.stylet ||
            etat.outilTrait == OutilTrait.surligneur);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Quatre cases de meme largeur ; texte agrandi, deux par rangee (puis
        // une), jamais un nom coupe.
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints c) {
            double plusLong = 0;
            for (final ({Key cle, String nom, Widget? tuile}) k in cases) {
              plusLong = math.max(
                plusLong,
                largeurMotLePlusLong(
                  contexte,
                  k.nom,
                  textes.labelMedium,
                  echelle,
                ),
              );
            }
            final double tuile = math.max(
              TuileCommandeSalle.largeurMin,
              plusLong + 2 * AppSpacing.md,
            );
            int parRangee = cases.length;
            while (parRangee > 1 &&
                parRangee * tuile + (parRangee - 1) * AppSpacing.sm >
                    c.maxWidth) {
              parRangee = parRangee > 2 ? 2 : 1;
            }
            return Column(
              key: cleTuiles,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (int i = 0; i < cases.length; i += parRangee)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      for (int j = i; j < i + parRangee; j++)
                        Expanded(
                          child: j < cases.length
                              ? cases[j].tuile ?? const SizedBox.shrink()
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        if (couleurs) ...<Widget>[
          Ecart.vMd,
          Semantics(
            container: true,
            label: t.salle.seance.ecriture.couleur,
            child: _Groupe(
              child: Row(
                key: const ValueKey<String>('barre-outils-couleurs'),
                mainAxisSize: MainAxisSize.min,
                children: pastillesCouleurSalle(etat, controleur, armer),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
