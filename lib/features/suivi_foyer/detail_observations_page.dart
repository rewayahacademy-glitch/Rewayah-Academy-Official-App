import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/carte_rubriques.dart';
import 'composants_historique.dart';
import 'donnees_historique.dart';
import 'filtres_historique.dart';

/// Le detail des visites d'observation d'une seance, pour un eleve
/// (`/tuteur/seances/:seanceId/observations?eleve=`, maquette V8 D4, lot E
/// sous-paquet 2).
///
/// Composition de D4 : retour, titre = la classe, sous-titre = l'eleve et la
/// date, l'enseignant ; une carte de resume (observateur, eleve, duree
/// totale), une carte des visites (« Visite n », plage horaire, duree,
/// statut), la note de fuseau. Le bouton « Retour a l'historique » de la
/// maquette n'est pas rendu : il doublerait le disque retour (une fonction,
/// une place).
///
/// Ce que le serveur ne garantit pas n'est pas affiche : aucun motif de fin
/// (DB-OBS-04), aucune duree recollee a partir de deux horodatages (duree
/// ecrite par le serveur seulement), une visite ouverte dit « sortie non
/// enregistree » (DB-OBS-03).
class DetailObservationsPage extends ConsumerWidget {
  /// Cree la page.
  const DetailObservationsPage({
    required this.seanceId,
    super.key,
    this.eleveId,
  });

  /// La seance concernee.
  final String seanceId;

  /// L'eleve concerne (`?eleve=`), s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ObservationsSeance?> valeur = ref.watch(
      detailObservationsProvider((seanceId, eleveId)),
    );
    final ObservationsSeance? lu = valeur.hasValue && !valeur.hasError
        ? valeur.requireValue
        : null;
    final Map<String, GroupSummaryVM> classes = ref.watch(
      classesCourantesProvider,
    );
    final GroupSummaryVM? classe = lu == null ? null : classes[lu.groupeId];
    final List<ProfilEleveFoyer> profils =
        ref.watch(profilsElevesFoyerProvider).value ??
        const <ProfilEleveFoyer>[];

    // Toujours vers la liste des observations : la route est imbriquee sous
    // le detail de seance, un `pop` y ramenerait au lieu de la liste.
    void retour() => GoRouter.of(context).go(Routes.tuteurSuiviObservations);

    final Widget corps;
    if (valeur.error is CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.historique.observations.indisponibleTitre,
        phrase: t.historique.observations.indisponiblePhrase,
        dependance: (valeur.error! as CapaciteIndisponible).dependance,
      );
    } else {
      corps = BlocAsynchrone<ObservationsSeance?>(
        valeur: valeur,
        squelette: const Skeleton.liste(lignes: 4),
        onReessayer: () =>
            ref.invalidate(detailObservationsProvider((seanceId, eleveId))),
        vide: EtatSysteme(
          nature: NatureEtat.introuvable,
          titre: t.historique.observation.introuvableTitre,
          phrase: t.historique.observation.introuvablePhrase,
          libelleAction: t.historique.retour,
          onAction: () =>
              GoRouter.of(context).go(Routes.tuteurSuiviObservations),
        ),
        construire: (ObservationsSeance? o) => _Contenu(
          observations: o!,
          classe: classe,
          prenom: prenomEleve(o.enfantId ?? eleveId, profils),
        ),
      );
    }

    final DateTime? entree = lu == null ? null : premiereEntree(lu);
    return PageShell(
      titre: lu == null
          ? t.historique.segments.observations
          : classe?.libelle ??
                t.historique.observation.titreSansClasse(
                  date: dateCourte(entree!),
                ),
      sousTitre: lu == null
          ? null
          : '${prenomEleve(lu.enfantId ?? eleveId, profils)} · '
                '${dateMoyenne(entree!)}',
      onRetour: retour,
      child: ColonneHistorique(child: corps),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.observations,
    required this.classe,
    required this.prenom,
  });

  final ObservationsSeance observations;
  final GroupSummaryVM? classe;
  final String prenom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // L'enseignant se lit sur la ligne de seance du foyer (meme lecture que
    // l'Historique) ; absent de la fenetre lue, il n'est pas affiche.
    final List<Seance> seances =
        ref.watch(seancesDuSuiviProvider).value ?? const <Seance>[];
    Seance? seance;
    for (final Seance s in seances) {
      if (s.id == observations.seanceId &&
          (seance == null || s.eleveId == observations.enfantId)) {
        seance = s;
      }
    }
    final Duration? total = observations.dureeTotaleConfirmee;
    final DateTime premiere = premiereEntree(observations);

    Widget titreBloc(String texte) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          texte,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        titreBloc(t.historique.observation.blocResume),
        SurfaceCarte(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LigneCleValeur(
                  cle: t.historique.observation.observateur,
                  valeur: t.historique.observation.vous,
                ),
                LigneCleValeur(
                  cle: t.historique.observation.eleve,
                  valeur: prenom,
                ),
                if (seance != null)
                  LigneCleValeur(
                    cle: t.historique.observation.enseignant,
                    valeur: enseignantAffiche(seance, classe),
                  ),
                LigneCleValeur(
                  cle: t.historique.observation.dureeTotale,
                  valeur: total == null
                      ? t.historique.observations.dureeNonConfirmee
                      : dureeLisible(total),
                  chiffres: total != null,
                ),
              ],
            ),
          ),
        ),
        Ecart.vXl,
        titreBloc(t.historique.observation.blocVisites),
        CarteLignes(
          lignes: <Widget>[
            for (final GuardianSessionVisit v in observations.visites)
              _Visite(visite: v),
          ],
        ),
        Ecart.vMd,
        NoteHistorique(
          t.historique.fuseauDetail(decalage: decalageUtc(premiere)),
        ),
      ],
    );
  }
}

/// Une visite : « Visite n » et sa plage a gauche, duree et statut a droite.
class _Visite extends StatelessWidget {
  const _Visite({required this.visite});

  final GuardianSessionVisit visite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime entree = visite.enteredAtUtc.toLocal();
    final DateTime? sortie = visite.leftAtUtc?.toLocal();
    final Duration? duree = visite.durationSeconds;
    final bool terminee = sortie != null && duree != null;
    final String plage = sortie == null
        ? t.historique.observation.plageOuverte(debut: heureMinute(entree))
        : plageHoraire(entree, sortie);
    final StatutObservation statut = terminee
        ? StatutObservation.terminee
        : StatutObservation.sortieNonEnregistree;

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      t.historique.observation.visite(n: visite.visitNumber),
                      style: palette.inkStrong.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vXs,
                    Text(
                      plage,
                      style: AppTypography.tabulaire(
                        palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Ecart.hMd,
              // Calee a droite, contre le bord de la carte (maquette D4).
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Une duree seulement quand le serveur l'a ecrite.
                  if (terminee) ...<Widget>[
                    Text(
                      dureeLisible(duree),
                      style: AppTypography.tabulaire(
                        palette.inkStrong.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                    Ecart.vXs,
                  ],
                  StatusPill(libelle: statut.libelle, ton: statut.ton),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
