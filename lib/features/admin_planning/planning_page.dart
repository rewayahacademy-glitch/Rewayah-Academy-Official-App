/// DASH-ADM-PLANNING : la page « Planning » de la direction, les seances de
/// la semaine toutes classes confondues, jour par jour.
///
/// La navigation d'une semaine a l'autre passe par `BarrePrecedentSuivant`
/// (jamais deux boutons a libelle). Le jour porte un en-tete et une carte a
/// lignes fines (K-55) ; une ligne dit la classe (son nom distinct, R16),
/// l'horaire, l'enseignant ou « Sans enseignant », et l'etat en pastille.
/// Rien n'est appuyable : un rapport, jamais un bouton grise (D9).
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (le bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu), et port absent
/// (« disponible au branchement serveur »).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/port_planning_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_seance_direction.dart';
import 'planning_libelles.dart';

/// L'ecran « Planning ».
class PlanningPage extends ConsumerStatefulWidget {
  /// Cree l'ecran. [semaineInitiale] (tout jour de la semaine voulue) sert
  /// aux tests ; par defaut, la semaine en cours.
  const PlanningPage({super.key, this.semaineInitiale});

  /// Un jour de la semaine a ouvrir, ou `null` pour la semaine en cours.
  final DateTime? semaineInitiale;

  @override
  ConsumerState<PlanningPage> createState() => _PlanningPageEtat();
}

class _PlanningPageEtat extends ConsumerState<PlanningPage> {
  late final DateTime _courante = lundiDe(
    widget.semaineInitiale ?? DateTime.now(),
  );
  late DateTime _lundi = _courante;

  void _aller(int semaines) => setState(
    () =>
        _lundi = DateTime(_lundi.year, _lundi.month, _lundi.day + 7 * semaines),
  );

  void _relire() => ref.invalidate(planningSemaineProvider);

  @override
  Widget build(BuildContext context) {
    final l = t.admin.planning;
    final AsyncValue<List<SeancePlanning>> lecture = ref.watch(
      planningSemaineProvider(_lundi),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String semaine = libelleSemaine(_lundi);
    return PageShell(
      titre: l.titre,
      sousTitre: l.sousTitre,
      child: ColonneCorps(
        children: <Widget>[
          BarrePrecedentSuivant(
            key: const ValueKey<String>('planning-navigation'),
            position: semaine,
            positionSemantique: semaine,
            libellePrecedent: l.precedente,
            libelleSuivant: l.suivante,
            onPrecedent: () => _aller(-1),
            onSuivant: () => _aller(1),
          ),
          if (_lundi != _courante) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              key: const ValueKey<String>('planning-cette-semaine'),
              libelle: l.cetteSemaine,
              alignerEnDebut: true,
              onPress: () => setState(() => _lundi = _courante),
            ),
          ],
          Ecart.vXl,
          BlocAsynchrone<List<SeancePlanning>>(
            key: const ValueKey<String>('planning-bloc'),
            valeur: lecture,
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: _relire,
            estVide: (List<SeancePlanning> s) => s.isEmpty,
            vide: EmptyState(
              key: const ValueKey<String>('planning-vide'),
              message: l.vide,
              invitation: l.videDetail,
              icone: AppIcons.planningGlobal,
            ),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
              // Port absent : ni un echec, ni un vide. Rien ne se reessaie.
              if (erreur is CapaciteIndisponible) {
                return EtatSysteme(
                  key: const ValueKey<String>('planning-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: t.commun.etats.branchementServeur,
                  phrase: l.indisponiblePhrase,
                  dependance: erreur.dependance,
                );
              }
              return horsLigne
                  ? EtatSansDonnees(
                      key: const ValueKey<String>('planning-sans-donnees'),
                      quoi: l.sansDonnees,
                      onAction: reessayer,
                    )
                  : EtatSysteme(
                      key: const ValueKey<String>('planning-erreur'),
                      nature: NatureEtat.echecServeur,
                      phrase: l.erreur,
                      onAction: reessayer,
                    );
            },
            construire: (List<SeancePlanning> seances) =>
                _Jours(jours: parJour(seances)),
          ),
        ],
      ),
    );
  }
}

/// Les jours de la semaine qui ont des seances, chacun avec sa carte.
class _Jours extends StatelessWidget {
  const _Jours({required this.jours});

  final Map<DateTime, List<SeancePlanning>> jours;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('planning-jours'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xl,
      children: <Widget>[
        for (final MapEntry<DateTime, List<SeancePlanning>> jour
            in jours.entries)
          Column(
            key: ValueKey<String>('planning-jour-${jour.key.weekday}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SectionHeader(
                titre: libelleJour(jour.key),
                compteur: jour.value.length,
              ),
              Ecart.vMd,
              CarteLignes(
                lignes: <Widget>[
                  for (final SeancePlanning s in jour.value)
                    LigneSeanceDirection(
                      key: ValueKey<String>('planning-seance-${s.id}'),
                      classe: s.classe,
                      detail:
                          '${libelleHorairePlanning(s)}\n'
                          '${libelleEnseignantPlanning(s.enseignant)}',
                      statut: s.statut,
                      mot: libelleStatutPlanning(s.statut),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
