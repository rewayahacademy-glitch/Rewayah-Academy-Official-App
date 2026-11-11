// LUMIERE-ACCUEILS, points 3 et 4 (directeur, 09-10/11/2026 ; arbitrages du
// pilote du 10-11/11/2026) : les signaux de l'« Aujourd'hui » de l'enseignant
// et de l'accueil de la direction, **calcules uniquement depuis des etats que
// le serveur rend**. Aucune lumiere n'est deduite sur l'appareil : ces fonctions
// ne lisent ni l'horloge ni un role, seulement ce que les lectures ont rendu.
//
// Sources (lues par les ecrans, jamais ici) :
// * enseignant :
//   - remplacements : `offres_remplacement()` (DECISION-REMPLACEMENT) -> urgent ;
//   - eleves absents ou en retard pendant la seance en cours : A VENIR, en
//     dernier. Ce rouge lira la meme fonction serveur que le rouge « retard »
//     de H (migration de H, plage 20261122700000 a 799999) ; aucune source
//     propre ici (arbitrage du pilote du 11/11/2026). « Excusee » reste
//     lisible dans la presence, sans lumiere propre ;
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
import '../widgets/halo_lumiere.dart';

/// Ce que signale une lumiere de l'« Aujourd'hui » de l'enseignant.
enum MotifEnseignant {
  /// Une ou plusieurs offres de remplacement.
  remplacement,

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

  /// La lumiere du signal (rouge urgent, orange a preparer : `HaloLumiere`).
  final NatureHalo nature;

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
/// priorite : les remplacements (urgent), puis le cahier (a preparer).
List<SignalAccueil<MotifEnseignant>> signauxAujourdhui({
  required int offresRemplacement,
  required int cahiersARemplir,
}) => <SignalAccueil<MotifEnseignant>>[
  if (offresRemplacement > 0)
    SignalAccueil<MotifEnseignant>(
      nature: NatureHalo.urgent,
      motif: MotifEnseignant.remplacement,
      nombre: offresRemplacement,
    ),
  if (cahiersARemplir > 0)
    SignalAccueil<MotifEnseignant>(
      nature: NatureHalo.aPreparer,
      motif: MotifEnseignant.cahier,
      nombre: cahiersARemplir,
    ),
];

/// Les signaux de l'accueil de la direction, dans l'ordre de priorite.
///
/// [alertes] est la liste rendue par `signalements_ouverts_direction()` (ou
/// `null` : illisible, aucun signal invente) ; seules les alertes de gravite
/// urgente allument le rouge. [indicateurs] est la ligne de
/// `indicateurs_admin()`, ou `null` quand elle n'est pas lisible.
///
/// [dossiersAffiches] est le nombre que la tuile « Dossiers a valider » montre
/// (enseignants seulement, lu dans la file) quand la file est lue : la lumiere
/// suit le chiffre affiche, jamais un autre compte (le compteur serveur compte
/// encore les tuteurs, BR-1.c). Nul : le compteur serveur.
List<SignalAccueil<MotifDirection>> signauxDirection({
  required List<Alerte>? alertes,
  required IndicateursAdmin? indicateurs,
  int? dossiersAffiches,
}) {
  final int prioritaires = <Alerte>[...?alertes]
      .where((Alerte a) => a.gravite == GraviteAlerte.urgent)
      .length;
  final IndicateursAdmin? i = indicateurs;
  return <SignalAccueil<MotifDirection>>[
    if (prioritaires > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureHalo.urgent,
        motif: MotifDirection.signalement,
        nombre: prioritaires,
      ),
    if (i != null && i.incidents24h > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureHalo.aPreparer,
        motif: MotifDirection.incidents,
        nombre: i.incidents24h,
      ),
    if (i != null && (dossiersAffiches ?? i.dossiersEnAttente) > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureHalo.aPreparer,
        motif: MotifDirection.dossiers,
        nombre: dossiersAffiches ?? i.dossiersEnAttente,
      ),
    if (i != null && i.demandesEnAttente > 0)
      SignalAccueil<MotifDirection>(
        nature: NatureHalo.aPreparer,
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
