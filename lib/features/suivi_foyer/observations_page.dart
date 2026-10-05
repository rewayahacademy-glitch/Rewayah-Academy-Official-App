import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'composants_historique.dart';
import 'donnees_historique.dart';
import 'filtres_historique.dart';

/// L'Historique du tuteur, segment Observations (`/tuteur/suivi/observations`,
/// maquette V8 D2, lot E sous-paquet 2).
///
/// Une ligne par seance observee et par eleve : date, nombre de visites et
/// duree totale **ecrite par le serveur** (sinon « Duree non confirmee »),
/// classe, eleve, statut. Le motif de fin n'est jamais affiche : le serveur
/// ecrit toujours « sortie volontaire » (DB-OBS-04) ; « Limite atteinte » de
/// la maquette n'est donc pas reproduit. Une visite sans sortie reste
/// « Sortie non enregistree » (DB-OBS-03).
///
/// Source : `guardian_session_visit` sous RLS (port K4). Tant que le
/// coordinateur n'a pas branche l'adaptateur du lot (demande E-7), le port de
/// production rend « indisponible » : l'ecran le dit, jamais une liste locale.
class ObservationsPage extends ConsumerWidget {
  /// Cree la page.
  const ObservationsPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant (injectable pour les tests).
  final DateTime Function() horloge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime maintenant = horloge();
    return PageShell(
      titre: t.historique.titre,
      child: ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EnteteHistorique(
              segment: SegmentHistorique.observations,
              maintenant: maintenant,
            ),
            Ecart.vLg,
            _Corps(
              maintenant: maintenant,
              filtres: ref.watch(filtresObservationsProvider),
              onFiltres: ref.read(filtresObservationsProvider.notifier).poser,
            ),
          ],
        ),
      ),
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({
    required this.maintenant,
    required this.filtres,
    required this.onFiltres,
  });

  final DateTime maintenant;
  final FiltresHistorique<StatutObservation> filtres;
  final ValueChanged<FiltresHistorique<StatutObservation>> onFiltres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    if (profils.hasError && !profils.hasValue) {
      return EtatSysteme(
        nature: NatureEtat.echecServeur,
        onAction: () => ref.invalidate(elevesDuFoyerProvider),
      );
    }
    if (!profils.hasValue) {
      return const Skeleton.liste(lignes: 3);
    }
    final ProfilEleveFoyer? retenu = ref.watch(eleveSelectionneProvider).value;
    if (retenu == null) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.historique.observations.videTitre,
        phrase: t.historique.observations.videPhraseFoyer,
      );
    }

    final AsyncValue<List<ObservationsSeance>> valeur = ref.watch(
      mesObservationsProvider(retenu.eleveId),
    );
    if (valeur.error is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.historique.observations.indisponibleTitre,
        phrase: t.historique.observations.indisponiblePhrase,
        dependance: (valeur.error! as CapaciteIndisponible).dependance,
      );
    }
    return BlocAsynchrone<List<ObservationsSeance>>(
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () =>
          ref.invalidate(mesObservationsProvider(retenu.eleveId)),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.historique.observations.videTitre,
        phrase: t.historique.observations.videPhrase(prenom: retenu.prenom),
      ),
      construire: (List<ObservationsSeance> groupes) => _Liste(
        groupes: groupes,
        eleve: retenu,
        maintenant: maintenant,
        filtres: filtres,
        onFiltres: onFiltres,
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({
    required this.groupes,
    required this.eleve,
    required this.maintenant,
    required this.filtres,
    required this.onFiltres,
  });

  final List<ObservationsSeance> groupes;
  final ProfilEleveFoyer eleve;
  final DateTime maintenant;
  final FiltresHistorique<StatutObservation> filtres;
  final ValueChanged<FiltresHistorique<StatutObservation>> onFiltres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, GroupSummaryVM> classes = ref.watch(
      classesCourantesProvider,
    );
    final Map<String, String> classesPresentes = <String, String>{
      for (final ObservationsSeance o in groupes)
        if (classes[o.groupeId] case final GroupSummaryVM g)
          g.groupeId: g.libelle,
    };
    final Map<StatutObservation, int> parStatut = <StatutObservation, int>{};
    for (final ObservationsSeance o in groupes) {
      parStatut.update(
        statutObservationDe(o),
        (int n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    final List<ObservationsSeance> retenues = filtrerObservations(
      groupes,
      filtres,
      maintenant: maintenant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BarreFiltresHistorique<StatutObservation>(
          filtres: filtres,
          classes: classesPresentes,
          statuts: <(StatutObservation, int)>[
            for (final StatutObservation s in StatutObservation.values)
              if (parStatut[s] case final int n) (s, n),
          ],
          onFiltres: onFiltres,
        ),
        Ecart.vLg,
        if (retenues.isEmpty)
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.historique.observations.filtreVideTitre,
            phrase: t.historique.observations.filtreVidePhrase,
            onAction: () =>
                onFiltres(const FiltresHistorique<StatutObservation>()),
          )
        else ...<Widget>[
          CarteLignes(
            lignes: <Widget>[
              for (final ObservationsSeance o in retenues)
                _ligne(context, o, classes[o.groupeId]),
            ],
          ),
          Ecart.vMd,
          NoteHistorique(t.historique.fuseauListe),
        ],
      ],
    );
  }

  Widget _ligne(
    BuildContext context,
    ObservationsSeance o,
    GroupSummaryVM? classe,
  ) {
    final String nom = classe?.libelle ?? t.historique.classeInconnue;
    final StatutObservation statut = statutObservationDe(o);
    final DateTime entree = premiereEntree(o);
    return LigneHistorique(
      key: ValueKey<String>('observation-${o.seanceId}-${o.enfantId}'),
      date: dateCourte(entree),
      meta: resumeVisites(o),
      titre: nom,
      sousTitre: eleve.prenom,
      statut: statut.libelle,
      ton: statut.ton,
      semantique: t.historique.observations.ouvrir(
        date: dateLongueHistorique(entree),
        classe: nom,
        etat: statut.libelle,
      ),
      // `go` : l'adresse du detail est la vraie (lien profond, rechargement
      // web) ; les filtres vivent en memoire de session et survivent.
      onPress: () => GoRouter.of(context)
          .go(Routes.observationsSeancePour(o.seanceId, eleveId: o.enfantId)),
    );
  }
}
