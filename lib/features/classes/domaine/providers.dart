import 'package:flutter_riverpod/flutter_riverpod.dart';
// Le type d'une famille de providers n'est pas exporte par l'entree
// principale de Riverpod 3 : meme convention que `service_planning.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/admin/service_comptes.dart';
import '../../../core/admin/service_configuration.dart';
import '../../../core/admin/service_groupes.dart';
import '../../../core/admin/service_programme.dart';
import '../../../core/appairage/service_appairage.dart';
import '../../../core/enseignant/service_enseignant.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/tc_groupe/port_groupes.dart';
import 'adaptateurs_existants.dart';
import 'classe_vm.dart';
import 'conformite.dart';
import 'conformite_serveur.dart';
import 'ports.dart';

/// Le port d'administration des Classes employe par l'application.
///
/// **Le defaut est un adaptateur reel**, jamais un faux : il lit
/// `groupes_admin()`, `app_config`, le programme publie et `comptes_admin()`.
/// Les tests le remplacent par un faux **dans leur propre dossier**.
///
/// Les services sont resolus a l'appel (`ref.read` dans une fabrique), pas a
/// la construction : `Supabase.instance` leve tant que l'application n'est pas
/// initialisee, et un provider qui echouerait a sa construction fermerait
/// l'ecran avant qu'il ait rendu quoi que ce soit.
final Provider<PortClassesAdmin> portClassesAdminProvider =
    Provider<PortClassesAdmin>(
      (Ref ref) => ClassesAdminDepuisExistant(
        groupes: () => ref.read(serviceGroupesProvider),
        programme: () => ref.read(serviceProgrammeProvider),
        configuration: () => ref.read(serviceConfigurationProvider),
        comptes: () => ref.read(serviceComptesProvider),
      ),
    );

/// La marketplace employee par l'application.
final Provider<PortMarketplaceClasses> portMarketplaceProvider =
    Provider<PortMarketplaceClasses>(
      (Ref ref) => MarketplaceDepuisExistant(
        role: () => ref.read(sessionProvider).role,
        enseignant: () => ref.read(serviceEnseignantProvider),
        groupes: () => ref.read(portGroupesProvider),
      ),
    );

/// La conformite employee par l'application.
final Provider<PortConformite> portConformiteProvider =
    Provider<PortConformite>(
      (Ref ref) => ConformiteDepuisServeur(
        client: () => Supabase.instance.client,
        comptes: () => ref.read(serviceComptesProvider),
      ),
    );

/// La precondition d'entree en Salle employee par l'application.
final Provider<PortPreconditionSalle> portPreconditionSalleProvider =
    Provider<PortPreconditionSalle>(
      (Ref ref) => PreconditionDepuisFoyer(
        appairage: () => ref.read(serviceAppairageProvider),
        client: () => Supabase.instance.client,
        // Lu a l'appel, jamais a la construction : une session qui ne peut
        // pas se resoudre (aucun backend, comme en test) ne doit pas fermer
        // la porte avant qu'on l'ait demandee.
        monProfilId: () => ref.read(sessionProvider).profileId,
      ),
    );

/// Les Classes, pour Admin > Operations > Classes.
final FutureProvider<List<ClasseVM>> classesAdminProvider =
    FutureProvider<List<ClasseVM>>(
      (Ref ref) => ref.watch(portClassesAdminProvider).classes(),
    );

/// Les regles de l'academie, pour preremplir une Classe.
final FutureProvider<ReglesClasse> reglesClasseProvider =
    FutureProvider<ReglesClasse>(
      (Ref ref) => ref.watch(portClassesAdminProvider).regles(),
    );

/// Les niveaux du programme publie.
final FutureProvider<List<ProgrammeChoix>> programmesClasseProvider =
    FutureProvider<List<ProgrammeChoix>>(
      (Ref ref) => ref.watch(portClassesAdminProvider).programmes(),
    );

/// Les inscrits d'une Classe.
final FutureProviderFamily<List<MembreClasse>, String> membresClasseProvider =
    FutureProvider.family<List<MembreClasse>, String>(
      (Ref ref, String classeId) =>
          ref.watch(portClassesAdminProvider).membres(classeId),
    );

/// Les Classes de l'appelant.
final FutureProvider<List<ClasseVM>> mesClassesProvider =
    FutureProvider<List<ClasseVM>>(
      (Ref ref) => ref.watch(portMarketplaceProvider).mesClasses(),
    );

/// Les Classes disponibles, pour l'appelant (`null`) ou un membre du foyer.
final FutureProviderFamily<List<ClasseVM>, String?> classesDisponiblesProvider =
    FutureProvider.family<List<ClasseVM>, String?>(
      (Ref ref, String? membreId) => ref
          .watch(portMarketplaceProvider)
          .classesDisponibles(membreId: membreId),
    );

/// La conformite de l'appelant.
final FutureProvider<ConformiteCompte> maConformiteProvider =
    FutureProvider<ConformiteCompte>(
      (Ref ref) => ref.watch(portConformiteProvider).laMienne(),
    );

/// La conformite de tous les comptes, par profil. Administration.
final FutureProvider<Map<String, ConformiteCompte>> conformiteComptesProvider =
    FutureProvider<Map<String, ConformiteCompte>>(
      (Ref ref) => ref.watch(portConformiteProvider).pourComptes(),
    );

/// La precondition d'entree en Salle, pour l'appelant (`null`) ou un membre.
///
/// **Ne leve jamais** : l'adaptateur rend une precondition inconnue quand la
/// lecture echoue, et l'ecran laisse alors le serveur trancher.
final FutureProviderFamily<PreconditionSalle, String?>
preconditionSalleProvider = FutureProvider.family<PreconditionSalle, String?>((
  Ref ref,
  String? membreId,
) async {
  try {
    return await ref
        .watch(portPreconditionSalleProvider)
        .pour(membreId: membreId);
  } on Object {
    return const PreconditionSalle.inconnue();
  }
});
