// Demonstration admin (AD-4) : neutralisation des services admin encore
// adosses a Supabase. Sous `?demo=admin`, aucun ecran de l'AdminShell ne doit
// parler au serveur (spec 26 quater) : chaque service repond « indisponible »
// (`CapaciteIndisponible`), que l'ecran affiche en clair (contrat K5), sans
// liste vide trompeuse ni faux succes. Jamais en production (garde de
// `mode_demonstration.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/admin/service_plan_classe.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/controle/service_controle.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';

/// La dependance nommee par tout service neutralise de la demonstration.
const String dependanceDemoAdmin = 'AD-BR-DEMO';

/// Toute methode rend un futur en echec « indisponible ». `Future<Never>` est
/// un sous-type de tout `Future<T>` : le transfert genere par Dart l'accepte.
mixin _IndisponibleDemo {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(const CapaciteIndisponible(dependanceDemoAdmin));
}

class ServiceAdminDemo with _IndisponibleDemo implements ServiceAdmin {
  const ServiceAdminDemo();
}

class ServiceComptesDemo with _IndisponibleDemo implements ServiceComptes {
  const ServiceComptesDemo();
}

class ServiceGroupesDemo with _IndisponibleDemo implements ServiceGroupes {
  const ServiceGroupesDemo();
}

class ServiceConfigurationDemo
    with _IndisponibleDemo
    implements ServiceConfiguration {
  const ServiceConfigurationDemo();
}

class ServiceProgrammeDemo with _IndisponibleDemo implements ServiceProgramme {
  const ServiceProgrammeDemo();
}

class ServiceProgressionDemo
    with _IndisponibleDemo
    implements ServiceProgression {
  const ServiceProgressionDemo();
}

class ServiceQualiteDemo with _IndisponibleDemo implements ServiceQualite {
  const ServiceQualiteDemo();
}

class ServiceEvaluationsDemo
    with _IndisponibleDemo
    implements ServiceEvaluations {
  const ServiceEvaluationsDemo();
}

class ServiceDiagnosticsDemo
    with _IndisponibleDemo
    implements ServiceDiagnostics {
  const ServiceDiagnosticsDemo();
}

class ServicePlanClasseDemo
    with _IndisponibleDemo
    implements ServicePlanClasse {
  const ServicePlanClasseDemo();
}

class ServiceJournalDemo with _IndisponibleDemo implements ServiceJournal {
  const ServiceJournalDemo();
}

class ServiceMatchingDemo with _IndisponibleDemo implements ServiceMatching {
  const ServiceMatchingDemo();
}

class ServiceControleDemo with _IndisponibleDemo implements ServiceControle {
  const ServiceControleDemo();
}

class ServiceReglesDemo with _IndisponibleDemo implements ServiceRegles {
  const ServiceReglesDemo();
}

class ServiceAuthDemo with _IndisponibleDemo implements ServiceAuth {
  const ServiceAuthDemo();
}

class ServiceAgentDemo with _IndisponibleDemo implements ServiceAgent {
  const ServiceAgentDemo();
}

class AnnuaireObservationsDemo
    with _IndisponibleDemo
    implements AnnuaireObservations {
  const AnnuaireObservationsDemo();
}

class PolitiqueObservationAdminDemo
    with _IndisponibleDemo
    implements PortPolitiqueObservation {
  const PolitiqueObservationAdminDemo();
}

/// Les surcharges qui ferment tous les services admin adosses a Supabase.
/// [sauf] : les providers qu'un test fournit lui-meme (un seul override par
/// provider dans un meme conteneur).
List<Override> surchargesServicesAdminIndisponibles({
  List<Object> sauf = const <Object>[],
}) => <Override>[
  if (!sauf.contains(serviceAdminProvider))
    serviceAdminProvider.overrideWithValue(const ServiceAdminDemo()),
  if (!sauf.contains(serviceComptesProvider))
    serviceComptesProvider.overrideWithValue(const ServiceComptesDemo()),
  if (!sauf.contains(serviceGroupesProvider))
    serviceGroupesProvider.overrideWithValue(const ServiceGroupesDemo()),
  if (!sauf.contains(serviceConfigurationProvider))
    serviceConfigurationProvider.overrideWithValue(
      const ServiceConfigurationDemo(),
    ),
  if (!sauf.contains(serviceProgrammeProvider))
    serviceProgrammeProvider.overrideWithValue(const ServiceProgrammeDemo()),
  if (!sauf.contains(serviceProgressionProvider))
    serviceProgressionProvider.overrideWithValue(
      const ServiceProgressionDemo(),
    ),
  if (!sauf.contains(serviceQualiteProvider))
    serviceQualiteProvider.overrideWithValue(const ServiceQualiteDemo()),
  if (!sauf.contains(serviceEvaluationsProvider))
    serviceEvaluationsProvider.overrideWithValue(
      const ServiceEvaluationsDemo(),
    ),
  if (!sauf.contains(serviceDiagnosticsProvider))
    serviceDiagnosticsProvider.overrideWithValue(
      const ServiceDiagnosticsDemo(),
    ),
  if (!sauf.contains(servicePlanClasseProvider))
    servicePlanClasseProvider.overrideWithValue(const ServicePlanClasseDemo()),
  if (!sauf.contains(serviceJournalProvider))
    serviceJournalProvider.overrideWithValue(const ServiceJournalDemo()),
  if (!sauf.contains(serviceMatchingProvider))
    serviceMatchingProvider.overrideWithValue(const ServiceMatchingDemo()),
  if (!sauf.contains(serviceControleProvider))
    serviceControleProvider.overrideWithValue(const ServiceControleDemo()),
  if (!sauf.contains(serviceReglesProvider))
    serviceReglesProvider.overrideWithValue(const ServiceReglesDemo()),
  if (!sauf.contains(serviceAuthProvider))
    serviceAuthProvider.overrideWithValue(const ServiceAuthDemo()),
  if (!sauf.contains(serviceAgentProvider))
    serviceAgentProvider.overrideWithValue(const ServiceAgentDemo()),
  if (!sauf.contains(annuaireObservationsProvider))
    annuaireObservationsProvider.overrideWithValue(
      const AnnuaireObservationsDemo(),
    ),
  if (!sauf.contains(portPolitiqueObservationProvider))
    portPolitiqueObservationProvider.overrideWithValue(
      const PolitiqueObservationAdminDemo(),
    ),
];

/// Les providers de service que la demonstration admin neutralise (test).
final List<Provider<Object>> providersServicesAdmin = <Provider<Object>>[
  serviceAdminProvider,
  serviceComptesProvider,
  serviceGroupesProvider,
  serviceConfigurationProvider,
  serviceProgrammeProvider,
  serviceProgressionProvider,
  serviceQualiteProvider,
  serviceEvaluationsProvider,
  serviceDiagnosticsProvider,
  servicePlanClasseProvider,
  serviceJournalProvider,
  serviceMatchingProvider,
  serviceControleProvider,
  serviceReglesProvider,
  serviceAuthProvider,
  serviceAgentProvider,
  annuaireObservationsProvider,
  portPolitiqueObservationProvider,
];
