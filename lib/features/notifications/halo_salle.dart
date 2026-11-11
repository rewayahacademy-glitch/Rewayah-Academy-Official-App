// NAV-REFONTE 2b (directeur, 10/11/2026) : le halo vert du cercle Compte, «
// la salle est ouverte ». Il ne calcule rien lui-meme : il lit le calcul
// unique de chaque role (tuteur : `salleOuverteDuFoyerProvider`, celui de
// l'Accueil ; enseignant : `carteSeanceEnseignantProvider`, celui de la
// Journee), et son bouton appelle le geste du bouton de ces ecrans.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/enseignant/carte_seance.dart';
import '../../core/enseignant/cta_seance.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/halo_compte.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import '../accueil_famille/salle_rejoignable.dart';
import '../journee/journee_page.dart'
    show maintenantJourneeProvider, rejoindreSeanceEnseignant;

/// Le halo du cercle Compte, vivant : il se relit toutes les
/// [AncreHorlogeServeur.cadence] (l'instant serveur du tuteur, celui de la
/// Journee de l'enseignant), pour s'allumer et s'eteindre seul quand la salle
/// ouvre ou ferme. [notifications] est le halo de la cloche (Urgent, Nouveau) ;
/// [construire] recoit le halo retenu.
///
/// Le minuteur vit dans ce widget, comme celui de l'Accueil : il s'arrete avec
/// la coquille.
class HaloVivant extends ConsumerStatefulWidget {
  /// Cree le halo vivant.
  const HaloVivant({
    required this.role,
    required this.notifications,
    required this.construire,
    this.horlogeAppareil = DateTime.now,
    super.key,
  });

  /// Le role de la coquille.
  final AppRole role;

  /// Le halo tire des notifications, ou `null`.
  final EtatHaloCompte? notifications;

  /// La coquille, avec le halo retenu.
  final Widget Function(BuildContext contexte, EtatHaloCompte? halo) construire;

  /// L'horloge de l'appareil, pour mesurer un ecoulement seulement.
  final DateTime Function() horlogeAppareil;

  @override
  ConsumerState<HaloVivant> createState() => _EtatHaloVivant();
}

class _EtatHaloVivant extends ConsumerState<HaloVivant>
    with AncreHorlogeServeur<HaloVivant> {
  @override
  DateTime Function() get horlogeAppareil => widget.horlogeAppareil;

  @override
  Widget build(BuildContext context) => widget.construire(
    context,
    haloPrioritaire(
      notifications: widget.notifications,
      salle: switch (widget.role) {
        AppRole.guardian => _haloTuteur(ref, maintenantServeur()),
        AppRole.teacher => _haloEnseignant(
          ref,
          ref.watch(maintenantJourneeProvider)(),
        ),
        _ => null,
      },
    ),
  );
}

EtatHaloCompte? _haloTuteur(WidgetRef ref, DateTime? instant) {
  final ({ProfilEleveFoyer eleve, SalleDeLEleve salle})? ouverte = ref.watch(
    salleOuverteDuFoyerProvider(instant),
  );
  if (ouverte == null) return null;
  final ProfilEleveFoyer eleve = ouverte.eleve;
  return EtatHaloCompte.salle(
    action: t.classe.seance.rejoindreAvec(prenom: eleve.prenom),
    chemin: Routes.tuteurAccueil,
    agir: (BuildContext contexte) => rejoindreSalleDeLEleve(
      contexte,
      eleve: eleve,
      salle: ouverte.salle,
      versAccueil: () => GoRouter.of(contexte).go(Routes.tuteurAccueil),
    ),
  );
}

EtatHaloCompte? _haloEnseignant(WidgetRef ref, DateTime instant) {
  final CarteSeanceEnseignant? carte = ref.watch(
    carteSeanceEnseignantProvider(instant),
  );
  if (carte == null || carte.cta.etat != EtatCtaSeance.rejoindre) return null;
  return EtatHaloCompte.salle(
    action: t.enseignant.journee.rejoindreSalle,
    chemin: Routes.enseignantJournee,
    agir: (BuildContext contexte) =>
        rejoindreSeanceEnseignant(contexte, carte.seance),
  );
}

/// Un seul halo a la fois, le plus prioritaire l'emporte (planche du 09/11) :
/// Urgent, puis la salle ouverte, puis Nouveau.
EtatHaloCompte? haloPrioritaire({
  required EtatHaloCompte? notifications,
  required EtatHaloCompte? salle,
}) => notifications?.nature == NatureHalo.urgent
    ? notifications
    : salle ?? notifications;
