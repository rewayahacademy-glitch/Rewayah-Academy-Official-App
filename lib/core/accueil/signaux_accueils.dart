// LUMIERE-ACCUEILS, points 3 et 4 (directeur, 09-10/11/2026 ; arbitrages du
// pilote du 10-11/11/2026) : les signaux de l'« Aujourd'hui » de l'enseignant
// et de l'accueil de la direction, **calcules uniquement depuis des etats que
// le serveur rend**. Aucune lumiere n'est deduite sur l'appareil : ces fonctions
// ne lisent ni l'horloge ni un role, seulement ce que les lectures ont rendu.
//
// Sources (lues par les ecrans, jamais ici) :
// * enseignant :
//   - remplacements : `offres_remplacement()` (DECISION-REMPLACEMENT) -> urgent ;
//   - eleves absents ou en retard **pendant la seance en cours** :
//     `presence_seance_v` (etats `absente`, `en_retard`) -> urgent ;
//     « excusee » (absence annoncee par la famille) reste lisible dans la
//     presence, sans lumiere propre ;
//   - cahier a remplir : `mes_rapports_en_attente()` -> a preparer ;
//   - les messages sont hors de ce lot.
// * direction :
//   - signalement prioritaire : `signalements_ouverts_direction()`, gravite
//     urgente -> urgent ;
//   - incidents des 24 h, dossiers et demandes en attente :
//     `indicateurs_admin()` -> a preparer.
//
// L'affichage de la lumiere (composant core `HaloLumiere`, a venir dans la
// 2a-bis de B) choisira le signal dominant : **une seule lumiere en mouvement
// par ecran**, la plus urgente ; les autres restent en lueur fixe ou en
// pastille et mot.
library;

import 'package:flutter/foundation.dart';

import '../admin/service_admin.dart';
import '../alertes/alerte.dart';
import '../presence/service_presence.dart';

/// Ce qu'un signal d'accueil demande, par priorite decroissante.
enum NatureSignal {
  /// Rouge qui tourne : urgent.
  urgent,

  /// Orange qui respire : a preparer.
  aPreparer,
}

/// Ce que signale une lumiere de l'« Aujourd'hui » de l'enseignant.
enum MotifEnseignant {
  /// Une ou plusieurs offres de remplacement.
  remplacement,

  /// Des eleves absents ou en retard pendant la seance en cours.
  presence,

  /// Des cahiers de transmission a remplir.
  cahier,
}

/// Ce que signale une lumiere de l'accueil de la direction.
enum MotifDirection {
  /// Un signalement prioritaire (securite d'un enfant).
  signalement,

  /// Des seances en echec ou en absence sur les dernieres 24 heures.
  incidents,

  /// Des dossiers d'identite en attente de validation.
  dossiers,

  /// Des demandes en attente de decision.
  demandes,
}

/// Un signal : sa nature, son motif et le nombre que le serveur a rendu.
@immutable
class SignalAccueil<M extends Enum> {
  /// Cree un signal.
  const SignalAccueil({
    required this.nature,
    required this.motif,
    required this.nombre,
  });

  /// Ce que le signal demande.
  final NatureSignal nature;

  /// Ce qu'il signale.
  final M motif;

  /// Le nombre rendu par le serveur (toujours au moins 1).
  final int nombre;

  @override
  bool operator ==(Object other) =>
      other is SignalAccueil<M> &&
      other.nature == nature &&
      other.motif == motif &&
      other.nombre == nombre;

  @override
  int get hashCode => Object.hash(nature, motif, nombre);

  @override
  String toString() => 'SignalAccueil(${nature.name}, ${motif.name}, $nombre)';
}

/// Les signaux de l'« Aujourd'hui » de l'enseignant, dans l'ordre de
/// priorite : urgents d'abord (remplacements, puis presence), puis a preparer.
///
/// [presenceEnCours] est la presence de la seance **en cours**, ou `null` : pas
/// de seance en cours, ou presence illisible. Une presence inconnue n'est
/// jamais une absence (invariant J3) : elle ne fait aucun signal.
List<SignalAccueil<MotifEnseignant>> signauxAujourdhui({
  required int offresRemplacement,
  required List<PresenceParticipant>? presenceEnCours,
  required int cahiersARemplir,
}) {
  final int absentsOuEnRetard = <PresenceParticipant>[...?presenceEnCours]
      .where(
        (PresenceParticipant p) =>
            !p.estEnseignant && _absentOuEnRetard(p.etat),
      )
      .length;
  return <SignalAccueil<MotifEnseignant>>[
    if (offresRemplacement > 0)
      SignalAccueil<MotifEnseignant>(
        nature: NatureSignal.urgent,
        motif: MotifEnseignant.remplacement,
        nombre: offresRemplacement,
      ),
    if (absentsOuEnRetard > 0)
      SignalAccueil<MotifEnseignant>(
        nature: NatureSignal.urgent,
        motif: MotifEnseignant.presence,
        nombre: absentsOuEnRetard,
      ),
    if (cahiersARemplir > 0)
      SignalAccueil<MotifEnseignant>(
        nature: NatureSignal.aPreparer,
        motif: MotifEnseignant.cahier,
        nombre: cahiersARemplir,
      ),
  ];
}

bool _absentOuEnRetard(EtatPresence etat) =>
    etat == EtatPresence.absente || etat == EtatPresence.enRetard;

/// Les signaux de l'accueil de la direction, dans l'ordre de priorite.
///
/// [alertes] est la liste rendue par `signalements_ouverts_direction()` (ou
/// `null` : illisible, aucun signal invente) ; seules les alertes de gravite
/// urgente allument le rouge. [indicateurs] est la ligne de
/// `indicateurs_admin()`, ou `null` quand elle n'est pas lisible.
List<SignalAccueil<MotifDirection>> signauxDirection({
  required List<Alerte>? alertes,
  required IndicateursAdmin? indicateurs,
}) {
  final int prioritaires = <Alerte>[...?alertes]
      .where((Alerte a) => a.gravite == GraviteAlerte.urgent)
      .length;
  final IndicateursAdmin? i = indicateurs;
  return <SignalAccueil<MotifDirection>>[
    if (prioritaires > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureSignal.urgent,
        motif: MotifDirection.signalement,
        nombre: prioritaires,
      ),
    if (i != null && i.incidents24h > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureSignal.aPreparer,
        motif: MotifDirection.incidents,
        nombre: i.incidents24h,
      ),
    if (i != null && i.dossiersEnAttente > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureSignal.aPreparer,
        motif: MotifDirection.dossiers,
        nombre: i.dossiersEnAttente,
      ),
    if (i != null && i.demandesEnAttente > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureSignal.aPreparer,
        motif: MotifDirection.demandes,
        nombre: i.demandesEnAttente,
      ),
  ];
}

/// Le signal qui porte la seule lumiere en mouvement de l'ecran : le premier
/// de la liste (elle est deja dans l'ordre de priorite), ou `null`.
SignalAccueil<M>? signalDominant<M extends Enum>(
  List<SignalAccueil<M>> signaux,
) => signaux.isEmpty ? null : signaux.first;
