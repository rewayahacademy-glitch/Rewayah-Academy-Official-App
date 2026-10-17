// Demonstration admin (AD-4) : neutralisation des services admin encore
// adosses a Supabase. Sous `?demo=admin`, aucun ecran de l'AdminShell ne doit
// parler au serveur (spec 26 quater) : chaque service repond « indisponible »
// (`CapaciteIndisponible`), que l'ecran affiche en clair (contrat K5), sans
// liste vide trompeuse ni faux succes. Jamais en production (garde de
// `mode_demonstration.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/admin/service_admin.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/admin/service_configuration.dart';
import '../../core/admin/service_diagnostics.dart';
import '../../core/admin/service_evaluations.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/admin/service_programme.dart';
import '../../core/admin/service_progression.dart';
import '../../core/admin/service_qualite.dart';
import '../../core/agent/service_agent.dart';
import '../../core/auth/service_auth.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/controle/service_controle.dart';
import '../../core/journal/service_journal.dart';
import '../../core/matching/service_matching.dart';
import '../../core/regles/service_regles.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../admin_observations/annuaire_observations.dart';

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
List<Override> surchargesServicesAdminIndisponibles() => <Override>[
  serviceAdminProvider.overrideWithValue(const ServiceAdminDemo()),
  serviceComptesProvider.overrideWithValue(const ServiceComptesDemo()),
  serviceGroupesProvider.overrideWithValue(const ServiceGroupesDemo()),
  serviceConfigurationProvider.overrideWithValue(
    const ServiceConfigurationDemo(),
  ),
  serviceProgrammeProvider.overrideWithValue(const ServiceProgrammeDemo()),
  serviceProgressionProvider.overrideWithValue(const ServiceProgressionDemo()),
  serviceQualiteProvider.overrideWithValue(const ServiceQualiteDemo()),
  serviceEvaluationsProvider.overrideWithValue(const ServiceEvaluationsDemo()),
  serviceDiagnosticsProvider.overrideWithValue(const ServiceDiagnosticsDemo()),
  serviceJournalProvider.overrideWithValue(const ServiceJournalDemo()),
  serviceMatchingProvider.overrideWithValue(const ServiceMatchingDemo()),
  serviceControleProvider.overrideWithValue(const ServiceControleDemo()),
  serviceReglesProvider.overrideWithValue(const ServiceReglesDemo()),
  serviceAuthProvider.overrideWithValue(const ServiceAuthDemo()),
  serviceAgentProvider.overrideWithValue(const ServiceAgentDemo()),
  annuaireObservationsProvider.overrideWithValue(
    const AnnuaireObservationsDemo(),
  ),
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
  serviceJournalProvider,
  serviceMatchingProvider,
  serviceControleProvider,
  serviceReglesProvider,
  serviceAuthProvider,
  serviceAgentProvider,
  annuaireObservationsProvider,
  portPolitiqueObservationProvider,
];
