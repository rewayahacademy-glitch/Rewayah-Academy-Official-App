// Fixtures d'observation : les quatre situations de politique tuteur, et la
// table des capacites par role d'observateur.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.

import 'contrats/contrats_g_observation.dart';

/// La politique **heritee de l'Academie** : les defauts normatifs, intacts.
///
/// Observation activee, 1 visite, 120 secondes, micro et camera interdits,
/// aucune admission enseignant (spec 1.1 et 11.1).
const GuardianObservationPolicy politiqueHeritee = GuardianObservationPolicy(
  policyVersion: 'acad-2026-09-01',
  source: SourcePolitique.academie,
);

/// La politique **personnalisee par groupe** : deux visites, 300 secondes.
///
/// Elle illustre la surcharge par groupe -- la vraie nouveaute du domaine --
/// sans jamais desserrer ce qui ne se desserre pas : micro, camera et
/// publication data restent interdits.
const GuardianObservationPolicy politiquePersonnalisee =
    GuardianObservationPolicy(
      policyVersion: 'grp-lanternes-v3',
      source: SourcePolitique.groupe,
      maxVisitsPerSession: 2,
      maxTotalObservationTime: Duration(seconds: 300),
      maxParVisite: Duration(seconds: 180),
    );

/// La politique **desactivee** : aucune observation possible sur ce groupe.
const GuardianObservationPolicy politiqueDesactivee = GuardianObservationPolicy(
  policyVersion: 'grp-veilleurs-v1',
  source: SourcePolitique.desactivee,
  observationActivee: false,
  maxVisitsPerSession: 0,
  maxTotalObservationTime: Duration.zero,
);

/// Une politique ou le **temps** s epuise avant le nombre de visites.
///
/// Trois visites autorisees, mais 120 secondes au total : c est le temps qui
/// ferme la porte, pas le compteur de visites. Les deux motifs de refus ne
/// sont pas interchangeables -- la famille n entend pas la meme chose.
const GuardianObservationPolicy politiqueQuotaTempsCourt =
    GuardianObservationPolicy(
      policyVersion: 'grp-sources-v2',
      source: SourcePolitique.groupe,
      maxVisitsPerSession: 3,
    );

/// Une politique dont le plafond **par visite depasse le plafond total**.
///
/// Piege volontaire : 180 s par visite contre 120 s au total. Le plafond par
/// visite ne contourne jamais le total (CONTRACTS section 13, invariant 2).
const GuardianObservationPolicy politiquePlafondIncoherent =
    GuardianObservationPolicy(
      policyVersion: 'grp-piege-v1',
      source: SourcePolitique.groupe,
      maxParVisite: Duration(seconds: 180),
    );

/// Le budget d'un tuteur qui n'a encore rien consomme.
const BudgetObservation budgetIntact = BudgetObservation(
  policyVersion: 'acad-2026-09-01',
  visitesUtilisees: 0,
  visitesMax: 1,
  tempsConsomme: Duration.zero,
  tempsTotalMax: Duration(seconds: 120),
  restant: Duration(seconds: 120),
  peutEntrer: true,
);

/// Le budget d'un tuteur dont le **temps** est epuise.
const BudgetObservation budgetTempsEpuise = BudgetObservation(
  policyVersion: 'acad-2026-09-01',
  visitesUtilisees: 1,
  visitesMax: 1,
  tempsConsomme: Duration(seconds: 120),
  tempsTotalMax: Duration(seconds: 120),
  restant: Duration.zero,
  peutEntrer: false,
  motifRefus: MotifRefusObservation.tempsEpuise,
);

/// Ce qu'un observateur peut faire une fois entre.
///
/// **Ce n'est PAS un type de contrat.** C'est la forme executable des
/// decisions D-14, D-15 et D-16 : la verite est le jeton serveur
/// (`autoriser_jeton_video`), et aucune capacite ne se calcule cote client.
/// Ce double sert a verifier que la table des roles est la bonne, pas a la
/// faire appliquer.
class CapacitesObservateur {
  /// Cree un jeu de capacites.
  const CapacitesObservateur({
    required this.micro,
    required this.camera,
    required this.publicationData,
    required this.visibleDesParticipants,
    required this.annonceFaite,
    required this.auditee,
  });

  /// Le micro est-il autorise.
  final bool micro;

  /// La camera est-elle autorisee.
  final bool camera;

  /// La publication de donnees est-elle autorisee.
  final bool publicationData;

  /// Apparait-il dans la liste des participants.
  final bool visibleDesParticipants;

  /// Une annonce est-elle faite dans la classe.
  final bool annonceFaite;

  /// La visite est-elle journalisee. **Toujours vrai.**
  final bool auditee;
}

/// La table des capacites, par role d'observateur.
///
/// - Le **tuteur** observe, muet et sans camera, et l'enseignant est prevenu.
/// - L'**Admin incognito** est invisible aux participants, sans micro, sans
///   camera, sans annonce -- mais jamais invisible a l'audit.
/// - L'**Admin visible** rejoint la classe sous un nom institutionnel, avec
///   micro et camera, et l'annonce est faite.
/// - Le **Controleur** est incognito uniquement (decision D-16) : aucune
///   variante visible n'existe dans ce chantier.
CapacitesObservateur capacitesDe(RoleObservateur role) => switch (role) {
  RoleObservateur.tuteur => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: true,
    auditee: true,
  ),
  RoleObservateur.adminIncognito => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: false,
    auditee: true,
  ),
  RoleObservateur.adminVisible => const CapacitesObservateur(
    micro: true,
    camera: true,
    publicationData: true,
    visibleDesParticipants: true,
    annonceFaite: true,
    auditee: true,
  ),
  RoleObservateur.controleur => const CapacitesObservateur(
    micro: false,
    camera: false,
    publicationData: false,
    visibleDesParticipants: false,
    annonceFaite: false,
    auditee: true,
  ),
};

/// Le nom institutionnel sous lequel un Admin visible rejoint une classe.
const String nomInstitutionnelAdmin = 'Administration Rewayah';

/// Le plafond reellement applicable a une visite, quelle que soit la politique.
///
/// `maxParVisite` ne contourne jamais `maxTotalObservationTime` : on retient
/// le plus petit des deux, et le temps deja consomme s'en deduit.
Duration plafondEffectifDeVisite(
  GuardianObservationPolicy politique,
  Duration dejaConsomme,
) {
  final Duration restantTotal =
      politique.maxTotalObservationTime - dejaConsomme;
  final Duration borneBasse = restantTotal.isNegative
      ? Duration.zero
      : restantTotal;
  final Duration? parVisite = politique.maxParVisite;
  if (parVisite == null) return borneBasse;
  return parVisite < borneBasse ? parVisite : borneBasse;
}
