import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_programme.dart`).
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// D5 (30/10/2026) : qui « Ajouter un eleve » propose pour UNE classe.
///
/// `eleves_proposables_classe(p_groupe_id)` rend les eleves actifs, comme
/// [personnesProposablesDepuis] avec [AppRole.student], plus l'adulte qui
/// apprend pour lui-meme (compte `guardian` avec un profil d'eleve sur
/// lui-meme) quand la classe est adulte et de son genre. Le meme filtre que
/// `ajouter_eleve_groupe` : on ne propose jamais quelqu'un que le serveur
/// refuserait.
abstract interface class LecteurElevesProposables {
  /// Les personnes a proposer pour la classe [groupeId].
  Future<List<PersonneProposee>> pourClasse(String groupeId);
}

/// L'implementation reelle.
class LecteurElevesProposablesSupabase implements LecteurElevesProposables {
  /// Cree le lecteur.
  const LecteurElevesProposablesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PersonneProposee>> pourClasse(String groupeId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'eleves_proposables_classe',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return <PersonneProposee>[
      for (final dynamic ligne in reponse)
        personneProposeeDepuisJson(ligne as Map<String, dynamic>),
    ];
  }
}

/// Une ligne de `eleves_proposables_classe`. Le nom se replie sur
/// l'identifiant immuable, comme `CompteAdmin.libelle`.
PersonneProposee personneProposeeDepuisJson(Map<String, dynamic> json) {
  final String identifiant = json['immutable_id'] as String? ?? '';
  final String complet = <String?>[
    json['prenom'] as String?,
    json['nom'] as String?,
  ].whereType<String>().join(' ').trim();
  return PersonneProposee(
    id: json['profile_id'] as String,
    nom: complet.isEmpty ? identifiant : complet,
    identifiant: identifiant,
  );
}

/// Le lecteur employe par l'application.
final Provider<LecteurElevesProposables> lecteurElevesProposablesProvider =
    Provider<LecteurElevesProposables>(
      (Ref ref) => LecteurElevesProposablesSupabase(Supabase.instance.client),
    );

/// Les personnes a proposer pour une classe, triees par nom. Aucune relance
/// automatique : l'echec se voit tout de suite, et « Reessayer » relit.
final FutureProviderFamily<List<PersonneProposee>, String>
elevesProposablesClasseProvider = FutureProvider.autoDispose
    .family<List<PersonneProposee>, String>((Ref ref, String groupeId) async {
      final List<PersonneProposee> personnes = await ref
          .watch(lecteurElevesProposablesProvider)
          .pourClasse(groupeId);
      return personnes..sort(
        (PersonneProposee a, PersonneProposee b) =>
            RechercheCatalogue.normaliser(a.nom)
                .compareTo(RechercheCatalogue.normaliser(b.nom)),
      );
    }, retry: (int _, Object _) => null);
