import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_programme.dart`).
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../domain/enums.dart';
import '../tc_bibliotheque/recherche_catalogue.dart';
import '../widgets/selecteur_personne.dart';
import 'service_comptes.dart';

/// Les personnes qu'un formulaire d'administration peut proposer pour un
/// role (FORM-L2).
///
/// **Aucune lecture serveur de plus** : derive de [comptesProvider]
/// (`comptes_admin()`, qui rend role, prenom et nom). Ne retient que les
/// comptes actifs ou provisoires, les seuls que les RPC `creer_groupe`,
/// `ajouter_eleve_groupe` (`0019_groupes_durcissement.sql`) et
/// `planifier_evaluation` (`0023_evaluations.sql`) acceptent : proposer un
/// compte en attente ferait choisir une personne que le serveur refuse.
/// Tri par nom, sans accent ni casse.
///
/// **Une projection, pas un `FutureProvider`, et l'echec d'abord** : Riverpod
/// 3 relance seul un provider en echec, et pendant cette relance l'etat est
/// a la fois « en chargement » et « en erreur ». Un `FutureProvider` qui
/// attendrait `comptesProvider.future`, comme `whenData`, repasserait en
/// simple chargement : l'echec de lecture ne se verrait jamais (mesure du
/// test FORM-L2).
final ProviderFamily<AsyncValue<List<PersonneProposee>>, AppRole>
personnesProposablesProvider =
    Provider.family<AsyncValue<List<PersonneProposee>>, AppRole>((
      Ref ref,
      AppRole role,
    ) {
      final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);
      if (comptes.hasError) {
        return AsyncError<List<PersonneProposee>>(
          comptes.error!,
          comptes.stackTrace ?? StackTrace.empty,
        );
      }
      if (comptes.hasValue) {
        return AsyncData<List<PersonneProposee>>(
          personnesProposablesDepuis(comptes.requireValue, role),
        );
      }
      return const AsyncLoading<List<PersonneProposee>>();
    });

/// Le filtre de [personnesProposablesProvider], en fonction pure.
List<PersonneProposee> personnesProposablesDepuis(
  List<CompteAdmin> comptes,
  AppRole role,
) {
  final List<PersonneProposee> retenues = <PersonneProposee>[
    for (final CompteAdmin c in comptes)
      if (c.role == role &&
          (c.etat == AccountStatus.active ||
              c.etat == AccountStatus.provisionalActive))
        PersonneProposee(
          id: c.profilId,
          nom: c.libelle,
          identifiant: c.identifiant,
        ),
  ];
  return retenues..sort(
    (PersonneProposee a, PersonneProposee b) =>
        RechercheCatalogue.normaliser(a.nom)
            .compareTo(RechercheCatalogue.normaliser(b.nom)),
  );
}
