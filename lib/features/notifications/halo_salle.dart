// NAV-REFONTE 2b (directeur, 10/11/2026) : le halo vert du cercle Compte, «
// la salle est ouverte ». Il ne calcule rien lui-meme : il lit le calcul
// unique de chaque role (tuteur : `salleOuverteDuFoyerProvider`, celui de
// l'Accueil ; enseignant : `carteSeanceEnseignantProvider`, celui de la
// Journee), et son bouton appelle le geste du bouton de ces ecrans.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enseignant/carte_seance.dart';
import '../../core/enseignant/cta_seance.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/cadence_seance.dart';
import '../../core/widgets/halo_compte.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import '../accueil_famille/salle_rejoignable.dart';
import '../journee/journee_page.dart'
    show maintenantJourneeProvider, rejoindreSeanceEnseignant;

/// Le halo du cercle Compte, vivant : il s'allume et s'eteint seul quand la
/// salle ouvre ou ferme, au meme instant que le bouton de l'ecran (tuteur :
/// l'instant serveur partage de la coquille ; enseignant : la cadence de la
/// Journee). [notifications] est le halo de la cloche (Urgent, Nouveau) ;
/// [construire] recoit le halo retenu.
///
/// Le minuteur vit dans ce widget, comme celui de l'Accueil : il s'arrete avec
/// la coquille.
/// Ou le halo vert lit « salle rejoignable » : le calcul unique de chaque
/// ecran, choisi par la coquille (jamais par un role lu ici, COM-BR-16).
enum SourceSalle {
  /// Les profils du foyer, comme l'Accueil du tuteur
  /// (`salleOuverteDuFoyerProvider`).
  foyer,

  /// La carte de la Journee de l'enseignant (`carteSeanceEnseignantProvider`).
  journee,
}

class HaloVivant extends ConsumerStatefulWidget {
  /// Cree le halo vivant.
  const HaloVivant({
    required this.source,
    required this.notifications,
    required this.construire,
    this.horlogeAppareil = DateTime.now,
    super.key,
  });

  /// La source du halo vert, ou `null` : pas de halo vert.
  final SourceSalle? source;

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
  Widget build(BuildContext context) => switch (widget.source) {
    // Le tuteur : l'instant de l'HorlogeServeurPartagee de la coquille, celui
    // de l'Accueil et de la Classe.
    SourceSalle.foyer => _avec(_haloTuteur(ref, maintenantServeur())),
    // L'enseignant : la cadence de la Journee (meme horloge, memes bascules
    // a l'instant exact, chaque minute pleine), jamais un autre battement.
    SourceSalle.journee => CadenceSeance(
      lire: ref.watch(maintenantJourneeProvider),
      instants: <DateTime>[
        for (final SeanceEnseignant s
            in ref.watch(seancesEnseignantProvider).value ??
                const <SeanceEnseignant>[])
          ...basculesSeance(s.debut, s.fin),
      ],
      constructeur: (DateTime maintenant) =>
          _avec(_haloEnseignant(ref, maintenant)),
    ),
    null => _avec(null),
  };

  Widget _avec(EtatHaloCompte? salle) => widget.construire(
    context,
    haloPrioritaire(notifications: widget.notifications, salle: salle),
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
