/// DASH-ADM-INC : les incidents des 24 dernieres heures, ce que compte la
/// tuile « Incidents (24 h) » du Centre de commande, qui y mene.
///
/// Le critere est celui du compteur : des SEANCES passees en incident
/// technique, enseignant absent ou eleve absent depuis 24 heures, pas des
/// entrees du journal d'audit (qui reste a `JournalPage`). Plus recents
/// d'abord, une ligne par seance, la classe par son nom distinct (R16).
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu), et port absent
/// (« disponible au branchement serveur », la lecture serveur viendra au
/// BR-1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/port_incidents_seances.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart' show StatutSeance;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_planning/ligne_seance_direction.dart';
import '../admin_planning/planning_libelles.dart';

/// Le mot de la nature d'un incident.
String libelleNatureIncident(StatutSeance statut) => switch (statut) {
  StatutSeance.incidentTechnique => t.admin.incidents.natureTechnique,
  StatutSeance.enseignantAbsent => t.admin.incidents.natureEnseignantAbsent,
  _ => t.admin.incidents.natureEleveAbsent,
};

/// L'ecran « Incidents des 24 dernieres heures ».
class IncidentsPage extends ConsumerWidget {
  /// Cree l'ecran.
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.incidents;
    final AsyncValue<List<IncidentSeance>> lecture = ref.watch(
      incidentsSeancesProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      titre: l.titre,
      sousTitre: l.sousTitre,
      child: ColonneCorps(
        children: <Widget>[
          BlocAsynchrone<List<IncidentSeance>>(
            key: const ValueKey<String>('incidents-bloc'),
            valeur: lecture,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: () => ref.invalidate(incidentsSeancesProvider),
            estVide: (List<IncidentSeance> i) => i.isEmpty,
            vide: EmptyState(
              key: const ValueKey<String>('incidents-vide'),
              message: l.vide,
              invitation: l.videDetail,
              icone: AppIcons.rienAAfficher,
            ),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
              // Port absent : ni un echec, ni un vide. Rien ne se reessaie.
              if (erreur is CapaciteIndisponible) {
                return EtatSysteme(
                  key: const ValueKey<String>('incidents-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: t.commun.etats.branchementServeur,
                  phrase: l.indisponiblePhrase,
                  dependance: erreur.dependance,
                );
              }
              return horsLigne
                  ? EtatSansDonnees(
                      key: const ValueKey<String>('incidents-sans-donnees'),
                      quoi: l.sansDonnees,
                      onAction: reessayer,
                    )
                  : EtatSysteme(
                      key: const ValueKey<String>('incidents-erreur'),
                      nature: NatureEtat.echecServeur,
                      phrase: l.erreur,
                      onAction: reessayer,
                    );
            },
            construire: (List<IncidentSeance> incidents) => Column(
              key: const ValueKey<String>('incidents-liste'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SectionHeader(titre: l.liste, compteur: incidents.length),
                Ecart.vMd,
                CarteLignes(
                  lignes: <Widget>[
                    for (final IncidentSeance i in incidents)
                      LigneSeanceDirection(
                        key: ValueKey<String>('incident-${i.id}'),
                        classe: i.classe,
                        detail:
                            '${l.survenu(date: libelleJour(i.survenuLe), heure: libelleHeure(i.survenuLe))}\n'
                            '${libelleEnseignantPlanning(i.enseignant)}',
                        statut: i.statut,
                        mot: libelleNatureIncident(i.statut),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
