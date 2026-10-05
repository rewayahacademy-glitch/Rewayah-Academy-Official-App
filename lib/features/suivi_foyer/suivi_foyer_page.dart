import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/groupes_seances.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'composants_historique.dart';
import 'donnees_historique.dart';
import 'filtres_historique.dart';
import 'vue_suivi_foyer.dart';

/// L'Historique du tuteur, segment Seances (`/tuteur/suivi`, alias
/// `/tuteur/historique` ; mandat Tuteur V1, lot E sous-paquet 2).
///
/// Composition de la maquette V8 D2 : titre et cloche (coquille), selecteur
/// de profils (contrat K1, meme selection que l'Accueil), segment Seances /
/// Observations, filtres Classe / Periode / Statut, puis UNE carte de lignes
/// separees par un filet. Sur bureau, la meme colonne alignee au debut,
/// bornee a la largeur de lecture.
///
/// Trois regles tenues par test :
///
///   * **le sort du cours passe avant l'etat de l'eleve** (annule, non tenu) ;
///   * **aucune absence deduite d'une deconnexion** : apres la seance, un
///     lien coupe, un depart ou un calcul non confirme se disent « En cours de
///     verification » ;
///   * **aucune action d'ecriture** : l'Historique se lit ; corriger une
///     presence appartient a l'enseignant et a l'administration.
///
/// Le reseau (eleve, enseignant) de l'ancienne capture n'est pas affiche : il
/// n'est pas mesure (DB-HIS-03). La classe vient de `sessions.groupe_id` et
/// des classes courantes (DB-CRS-13) : une classe quittee ne se nomme pas.
class SuiviFoyerPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const SuiviFoyerPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant (injectable pour les tests).
  final DateTime Function() horloge;

  @override
  ConsumerState<SuiviFoyerPage> createState() => _SuiviFoyerPageEtat();
}

class _SuiviFoyerPageEtat extends ConsumerState<SuiviFoyerPage> {
  bool _requeteLue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requeteLue) {
      return;
    }
    _requeteLue = true;
    // L'entree depuis la Classe (lot C) : `?eleve=&classe=`. Une demande,
    // jamais une autorisation : un eleve inconnu du foyer est ignore par K1.
    final String? eleve = parametreRequete(context, 'eleve');
    final String? classe = parametreRequete(context, 'classe');
    if (eleve == null && classe == null) {
      return;
    }
    // Hors de la construction : un provider ne change pas pendant un build.
    scheduleMicrotask(() {
      if (!mounted) {
        return;
      }
      if (eleve != null) {
        ref.read(selectionEleveProvider.notifier).choisir(eleve);
      }
      if (classe != null) {
        ref
            .read(filtresSeancesProvider.notifier)
            .poser(FiltresHistorique<StatutHistorique>(classeId: classe));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime maintenant = widget.horloge();
    final FiltresHistorique<StatutHistorique> filtres = ref.watch(
      filtresSeancesProvider,
    );
    return PageShell(
      titre: t.historique.titre,
      child: ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EnteteHistorique(
              segment: SegmentHistorique.seances,
              maintenant: maintenant,
            ),
            Ecart.vLg,
            _Corps(
              maintenant: maintenant,
              filtres: filtres,
              onFiltres: ref.read(filtresSeancesProvider.notifier).poser,
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
  final FiltresHistorique<StatutHistorique> filtres;
  final ValueChanged<FiltresHistorique<StatutHistorique>> onFiltres;

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
      return const Skeleton.liste(lignes: 4);
    }
    final ProfilEleveFoyer? retenu = ref.watch(eleveSelectionneProvider).value;
    if (retenu == null) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.historique.seances.videTitre,
        phrase: t.historique.seances.videPhraseFoyer,
      );
    }

    return BlocAsynchrone<List<Seance>>(
      valeur: ref.watch(seancesDuSuiviProvider),
      squelette: const Skeleton.liste(lignes: 4),
      onReessayer: () => ref
        ..invalidate(seancesDuSuiviProvider)
        ..invalidate(presenceDuSuiviProvider)
        ..invalidate(groupesDesSeancesProvider),
      construire: (List<Seance> seances) => _Liste(
        seances: seances,
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
    required this.seances,
    required this.eleve,
    required this.maintenant,
    required this.filtres,
    required this.onFiltres,
  });

  final List<Seance> seances;
  final ProfilEleveFoyer eleve;
  final DateTime maintenant;
  final FiltresHistorique<StatutHistorique> filtres;
  final ValueChanged<FiltresHistorique<StatutHistorique>> onFiltres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PresenceParticipant>?> presence = ref.watch(
      presenceDuSuiviProvider,
    );
    final List<PresenceParticipant>? presences = presence.value;
    final bool presenceIllisible =
        !presence.isLoading && (presence.hasError || presences == null);
    final Map<String, String> classeDe = ref.watch(classeDesSeancesProvider);
    final Map<String, GroupSummaryVM> classes = ref.watch(
      classesCourantesProvider,
    );

    final List<LigneSuivi> toutes = seancesPassees(
      seances: seances,
      presences: presences,
      maintenant: maintenant,
      eleveId: eleve.eleveId,
    );
    if (toutes.isEmpty) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.historique.seances.videTitre,
        phrase: t.historique.seances.videPhrase(prenom: eleve.prenom),
      );
    }

    // Les choix des menus se derivent de la lecture : une classe ou un statut
    // sans ligne serait une impasse construite a la main.
    final Map<String, String> classesPresentes = <String, String>{
      for (final LigneSuivi l in toutes)
        if (classes[classeDe[l.seance.id]] case final GroupSummaryVM g)
          g.groupeId: g.libelle,
    };
    final Map<StatutHistorique, int> parStatut = <StatutHistorique, int>{};
    for (final LigneSuivi l in toutes) {
      parStatut.update(statutDe(l), (int n) => n + 1, ifAbsent: () => 1);
    }
    final List<LigneSuivi> retenues = filtrerSeances(
      toutes,
      filtres,
      classeDe: (String id) => classeDe[id],
      maintenant: maintenant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BarreFiltresHistorique<StatutHistorique>(
          filtres: filtres,
          classes: classesPresentes,
          statuts: <(StatutHistorique, int)>[
            for (final StatutHistorique s in StatutHistorique.values)
              if (parStatut[s] case final int n) (s, n),
          ],
          onFiltres: onFiltres,
        ),
        Ecart.vLg,
        if (retenues.isEmpty)
          EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: t.historique.seances.filtreVideTitre,
            phrase: t.historique.seances.filtreVidePhrase,
            onAction: () =>
                onFiltres(const FiltresHistorique<StatutHistorique>()),
          )
        else ...<Widget>[
          if (presenceIllisible) ...<Widget>[
            NoteHistorique(t.historique.presenceIllisible),
            Ecart.vMd,
          ],
          CarteLignes(
            lignes: <Widget>[
              for (final LigneSuivi l in retenues)
                _ligne(context, l, classes[classeDe[l.seance.id]]),
            ],
          ),
          Ecart.vMd,
          NoteHistorique(t.historique.fuseauListe),
          if (seances.length >= plafondSuiviFoyer) ...<Widget>[
            Ecart.vXs,
            NoteHistorique(
              t.historique.seances.tronquee(nombre: plafondSuiviFoyer),
            ),
          ],
        ],
      ],
    );
  }

  Widget _ligne(BuildContext context, LigneSuivi l, GroupSummaryVM? classe) {
    final String nom = classe?.libelle ?? t.historique.classeInconnue;
    final String statut = libelleStatut(l);
    return LigneHistorique(
      key: ValueKey<String>('seance-${l.seance.id}-${l.seance.eleveId}'),
      date: dateCourte(l.seance.debut),
      meta: plageHoraire(l.seance.debut, l.seance.fin),
      titre: nom,
      sousTitre: enseignantAffiche(l.seance, classe),
      statut: statut,
      ton: statutDe(l).ton,
      annulee: statutDe(l) == StatutHistorique.annule,
      semantique: t.historique.seances.ouvrir(
        date: dateLongueHistorique(l.seance.debut),
        classe: nom,
        etat: statut,
      ),
      // `go` : l'adresse du detail est la vraie (lien profond, rechargement
      // web) ; les filtres vivent en memoire de session et survivent.
      onPress: () => GoRouter.of(context).go(
        Uri(
          path: Routes.seancePour(l.seance.id),
          queryParameters: <String, String>{'eleve': l.seance.eleveId},
        ).toString(),
      ),
    );
  }
}
