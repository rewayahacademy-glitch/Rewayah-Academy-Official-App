// Admission, lot C (fiche du 30/10/2026, ecart dit au pilote) : apres
// l'acceptation, les enfants de la demande recoivent leur profil d'eleve. Un
// profil d'eleve exige un utilisateur d'authentification, que seule la
// fonction Edge `creer-profil-enfant` sait creer (cle de service) : la base ne
// peut donc pas le faire dans la transaction de l'acceptation. L'application
// du tuteur le fait a sa premiere ouverture de l'Accueil, puis lie chaque
// profil a son enfant de la demande (`lier_apprenant_profil`), qui range le
// genre, le niveau, l'objectif et la langue du cours.
//
// La creation n'est pas idempotente (DB-FOY-06) : un enfant deja lie n'est
// jamais recree, et un profil du foyer au meme prenom que le serveur propose
// (`profil_probable`, une reponse perdue) est lie au lieu d'en creer un
// second. Au premier echec, on s'arrete : l'ouverture suivante reprend.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un enfant de la demande, tel que `mes_apprenants_demande` le rend.
typedef EnfantDemande = ({
  String id,
  String prenom,
  int? age,
  bool titulaire,
  String? profilEleveId,
  String? profilProbable,
  String? nomFamille,
});

/// Lit une ligne du serveur ; `null` si elle est illisible.
EnfantDemande? enfantDepuisJson(Object? ligne) {
  if (ligne is! Map<String, dynamic> ||
      ligne['id'] is! String ||
      ligne['prenom'] is! String) {
    return null;
  }
  return (
    id: ligne['id'] as String,
    prenom: ligne['prenom'] as String,
    age: (ligne['age'] as num?)?.toInt(),
    titulaire: ligne['est_titulaire'] == true,
    profilEleveId: ligne['profil_eleve_id'] as String?,
    profilProbable: ligne['profil_probable'] as String?,
    nomFamille: ligne['nom_famille'] as String?,
  );
}

/// Les trois appels de la creation.
abstract interface class PortProfilsDemande {
  /// Les apprenants de la demande du compte connecte.
  Future<List<EnfantDemande>> lire();

  /// Cree le profil d'un enfant ; rend son identifiant, ou `null` si la
  /// reponse ne le dit pas.
  Future<String?> creer({
    required String prenom,
    required String nom,
    required int age,
  });

  /// Lie un enfant de la demande a son profil.
  Future<void> lier(String apprenantId, String profilEleveId);
}

/// Cree et lie les profils qui manquent ; rend le nombre d'enfants lies par
/// cet appel. Ne leve pas : un echec arrete la boucle, l'ouverture suivante
/// reprend ou elle s'est arretee.
Future<int> creerProfilsDemande(PortProfilsDemande port) async {
  int lies = 0;
  try {
    for (final EnfantDemande e in await port.lire()) {
      if (e.titulaire || e.profilEleveId != null) {
        continue;
      }
      final String? probable = e.profilProbable;
      final int? age = e.age;
      final String? nom = e.nomFamille;
      final String? profil =
          probable ??
          (age == null || nom == null || nom.trim().isEmpty
              ? null
              : await port.creer(prenom: e.prenom, nom: nom, age: age));
      if (profil == null) {
        return lies;
      }
      await port.lier(e.id, profil);
      lies++;
    }
  } on Object {
    return lies;
  }
  return lies;
}

/// L'adaptateur reel.
class ProfilsDemandeSupabase implements PortProfilsDemande {
  /// Cree l'adaptateur.
  const ProfilsDemandeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EnfantDemande>> lire() async {
    final Object? r = await _client.rpc<Object?>('mes_apprenants_demande');
    return <EnfantDemande>[
      if (r is List<Object?>)
        for (final Object? l in r)
          if (enfantDepuisJson(l) case final EnfantDemande e) e,
    ];
  }

  @override
  Future<String?> creer({
    required String prenom,
    required String nom,
    required int age,
  }) async {
    final FunctionResponse r = await _client.functions.invoke(
      'creer-profil-enfant',
      body: <String, dynamic>{
        'first_name': prenom,
        'last_name': nom,
        'age': age,
      },
    );
    final Object? donnees = r.data;
    return donnees is Map<String, dynamic> && donnees['profile_id'] is String
        ? donnees['profile_id'] as String
        : null;
  }

  @override
  Future<void> lier(String apprenantId, String profilEleveId) =>
      _client.rpc<void>(
        'lier_apprenant_profil',
        params: <String, dynamic>{
          'p_apprenant_id': apprenantId,
          'p_profil_eleve_id': profilEleveId,
        },
      );
}

/// Le port employe par l'application ; `null` sans Supabase (tests, outils).
final Provider<PortProfilsDemande?> portProfilsDemandeProvider =
    Provider<PortProfilsDemande?>((Ref _) {
      try {
        return ProfilsDemandeSupabase(Supabase.instance.client);
      } on Object {
        return null;
      }
    });

/// Une seule passe par session : le nombre d'enfants lies.
final FutureProvider<int> profilsDemandeCreesProvider = FutureProvider<int>((
  Ref ref,
) async {
  final PortProfilsDemande? port = ref.watch(portProfilsDemandeProvider);
  return port == null ? 0 : creerProfilsDemande(port);
}, retry: (int _, Object _) => null);
