// PE-B4 (directeur, 19/11/2026, PLAN arbitrage A9 et §15.2) : l'onglet
// Academie de l'accueil du candidat.
//
// - les annonces de l'academie y sont rangees (le fil d'ANNONCES-SIMPLES,
//   `AnnoncesRecues`, tel quel) ;
// - « Ce qu'il faut savoir » : les informations que les candidats n'ont pas
//   (la remuneration, le deroulement des cours, l'organisation des
//   entretiens). Aucune source publiee par la direction n'existe encore pour
//   elles : chaque ligne le dit (« S'affichera ici quand l'academie le rendra
//   public »), jamais un texte invente ;
// - partager l'academie et « Vos autres talents », tels quels ;
// - « Reglages » : la langue, le versement et le retrait de la candidature
//   quittent la page (directeur : « Langue et Retirer ma candidature vont dans
//   un reglage »). La ligne se deplie au toucher.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/deconnexion.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/skeleton.dart';
import '../com_annonces/annonces_recues.dart';
import '../com_annonces/port_annonces_direction.dart';
import '../compte/lignes_compte.dart';
import '../partage_offre/tuile_partage.dart';
import '../talents/tuile_talents.dart';
import 'onglet_dossier.dart' show Depliant;
import 'pays_versement_portail.dart';
import 'portail_candidature.dart';

/// L'onglet Academie.
class OngletAcademie extends ConsumerStatefulWidget {
  /// Cree l'onglet. [onRetire] : apres un retrait, l'accueil ramene a
  /// l'onglet Dossier, ou la reprise est proposee.
  const OngletAcademie({
    required this.candidature,
    required this.onRetire,
    super.key,
  });

  /// La candidature.
  final CandidatureDossier candidature;

  /// Appele apres un retrait reussi.
  final VoidCallback onRetire;

  /// La cle de la phrase « aucune annonce ».
  static const Key cleAnnoncesVide = ValueKey<String>('academie-annonces-vide');

  /// La cle du bloc « Ce qu'il faut savoir ».
  static const Key cleSavoir = ValueKey<String>('academie-savoir');

  /// La cle de la ligne « Reglages ».
  static const Key cleReglages = ValueKey<String>('academie-reglages');

  /// La cle du contenu deplie des reglages.
  static const Key cleReglagesOuverts = ValueKey<String>(
    'academie-reglages-ouverts',
  );

  /// La cle de « Se deconnecter ».
  static const Key cleDeconnexion = ValueKey<String>('academie-deconnexion');

  @override
  ConsumerState<OngletAcademie> createState() => _EtatOngletAcademie();
}

class _EtatOngletAcademie extends ConsumerState<OngletAcademie> {
  bool _reglages = false;

  @override
  Widget build(BuildContext context) {
    final CandidatureDossier c = widget.candidature;
    final a = t.recrutement.accueil.academie;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle titre = palette.inkStrong.applyTo(
      textes.titleMedium ?? const TextStyle(),
    );
    final AsyncValue<List<AnnonceRecue>> annonces = ref.watch(
      mesAnnoncesProvider,
    );
    final bool sansAnnonce =
        annonces.error is CapaciteIndisponible ||
        (annonces.hasValue && annonces.requireValue.isEmpty);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    // Un texte tres agrandi : l'icone cede sa place, aucun mot ne se coupe.
    final bool agrandi = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Les annonces rangees : chargement, contenu, vide, echec.
        if (!annonces.hasValue && !annonces.hasError) ...<Widget>[
          Text(t.com.annonces.fil.titre, style: titre),
          Ecart.vMd,
          const Skeleton.liste(lignes: 2),
          Ecart.vXl,
        ] else if (sansAnnonce) ...<Widget>[
          Semantics(
            header: true,
            child: Text(t.com.annonces.fil.titre, style: titre),
          ),
          Ecart.vSm,
          Text(
            a.annoncesVide,
            key: OngletAcademie.cleAnnoncesVide,
            style: muet,
          ),
          Ecart.vXl,
        ] else
          const AnnoncesRecues(ecartApres: Ecart.vXl),
        // Ce que les candidats n'ont pas encore : dit, jamais invente.
        Semantics(header: true, child: Text(a.savoirTitre, style: titre)),
        Ecart.vMd,
        CarteGroupee(
          key: OngletAcademie.cleSavoir,
          sections: <Widget>[
            for (final ({AppIcon icone, String nom}) s
                in <({AppIcon icone, String nom})>[
                  (icone: AppIcons.paiements, nom: a.remuneration),
                  (icone: AppIcons.cours, nom: a.cours),
                  (icone: AppIcons.discussion, nom: a.entretiens),
                ])
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!agrandi) ...<Widget>[
                    ExcludeSemantics(
                      child: IconTheme(
                        data: palette.inkAccent.asIconTheme(
                          size: AppSpacing.xxl,
                        ),
                        child: Icon(s.icone.repos),
                      ),
                    ),
                    Ecart.hMd,
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          s.nom,
                          style: palette.inkStrong.applyTo(
                            textes.bodyLarge ?? const TextStyle(),
                          ),
                        ),
                        Ecart.vXs,
                        Text(a.bientot, style: muet),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        // CAND-06 : partager, pour qui candidate encore ; CAND-07 : « Vos
        // autres talents ». Chaque tuile porte son ecart du haut.
        if (c.issue == IssueCandidature.enCours) const TuilePartageOffre(),
        const TuileTalents(),
        Ecart.vXl,
        // « Reglages » : une ligne qui se deplie.
        ToucherVivant(
          key: OngletAcademie.cleReglages,
          enfoncement: 0.985,
          onPress: () => setState(() => _reglages = !_reglages),
          libelleSemantique: '${a.reglages}. ${a.reglagesLegende}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTouchTarget.standard,
            ),
            child: Row(
              children: <Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(AppIcons.reglages.repos),
                ),
                Ecart.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(a.reglages, style: titre),
                      Text(a.reglagesLegende, style: muet),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _reglages ? (rtl ? -0.25 : 0.25) : 0,
                  duration: AppMouvement.duree(context, AppMouvement.micro),
                  child: IconTheme(
                    data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                    child: Icon(AppIcons.chevron.repos),
                  ),
                ),
              ],
            ),
          ),
        ),
        Depliant(
          child: !_reglages
              ? const SizedBox(width: double.infinity)
              : Padding(
                  key: OngletAcademie.cleReglagesOuverts,
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GroupeReglages(
                        lignes: <LigneRubrique>[ligneLangueCompte(context)],
                      ),
                      // PAYS-VERSEMENT puis VERSEMENT-QUESTIONS : le bloc de
                      // versement se modifie apres l'envoi tant que le
                      // dossier n'est pas valide.
                      if (afficheBlocVersement(c)) ...<Widget>[
                        Ecart.vMd,
                        LienPaysVersement(candidature: c),
                      ],
                      // PE-A6 : le retrait quitte le pied de l'accueil.
                      if (c.peutRetirer) ...<Widget>[
                        Ecart.vMd,
                        LienRetraitCandidature(
                          candidature: c,
                          alignerEnDebut: true,
                          onRetire: widget.onRetire,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        Ecart.vXl,
        // La deconnexion reste toujours possible, en action discrete.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: OngletAcademie.cleDeconnexion,
            libelle: t.attente.seDeconnecter,
            onPress: () => unawaited(seDeconnecter(context, ref)),
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}
