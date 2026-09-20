// Fixtures d'observation : les quatre situations de politique tuteur, et la
// table des capacites par role d'observateur.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.

import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';

/// La politique **heritee de l'Academie** : les defauts normatifs, intacts.
///
/// Observation activee, 1 visite, 120 secondes, micro et camera interdits,
/// aucune admission enseignant (spec 1.1 et 11.1).
const GuardianObservationPolicy politiqueHeritee =
    GuardianObservationPolicy.defautsNormatifs(
      policyVersion: 'acad-2026-09-01',
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
      observationActivee: true,
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
      observationActivee: true,
      maxVisitsPerSession: 3,
      maxTotalObservationTime: Duration(seconds: 120),
    );

/// Une politique dont le plafond **par visite depasse le plafond total**.
///
/// Piege volontaire : 180 s par visite contre 120 s au total. Le plafond par
/// visite ne contourne jamais le total (CONTRACTS section 13, invariant 2).
const GuardianObservationPolicy politiquePlafondIncoherent =
    GuardianObservationPolicy(
      policyVersion: 'grp-piege-v1',
      source: SourcePolitique.groupe,
      observationActivee: true,
      maxVisitsPerSession: 1,
      maxTotalObservationTime: Duration(seconds: 120),
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
