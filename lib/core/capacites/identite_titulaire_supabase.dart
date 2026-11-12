import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../theme/app_delais.dart';
import 'port_identite_titulaire.dart';

/// L'identite du titulaire lue sans backend nouveau (contrat K6, lot E).
///
/// - Prenom, nom et statut : `profiles`, ligne de la personne connectee
///   (policy `profiles_self_select`) ; l'identifiant est celui de la session,
///   comme `SourceSessionSupabase`.
/// - Courriel et methode de connexion : la session Supabase
///   (`auth.currentUser`), jamais une requete.
///
/// - Ecriture ([modifier], EDIT-INFOS-PERSO, 12/11/2026) : le prenom et le
///   nom seuls, sur la ligne de soi, par la politique `profiles_self_update` ;
///   le serveur refuse le changement a un eleve mineur.
class IdentiteTitulaireSupabase implements PortIdentiteTitulaire {
  /// Cree l'adaptateur.
  ///
  /// [motDePassePossible] vaut `Env.authParMotDePasseActive` : dans une
  /// compilation de demonstration, un compte « email » a pu entrer par mot de
  /// passe, et l'ecran ne doit pas affirmer « lien par courriel ».
  const IdentiteTitulaireSupabase(
    this._client, {
    this.motDePassePossible = false,
  });

  final SupabaseClient _client;

  /// Vrai quand la compilation autorise la connexion par mot de passe.
  final bool motDePassePossible;

  @override
  Future<IdentiteTitulaire> lire() async {
    final User? utilisateur = _client.auth.currentUser;
    if (utilisateur == null) {
      throw StateError('Aucune session ouverte : identite illisible.');
    }
    final Map<String, dynamic>? ligne = await _client
        .from('profiles')
        .select('first_name, last_name, account_status')
        .eq('id', utilisateur.id)
        .maybeSingle()
        .timeout(AppDelais.requeteMax);
    if (ligne == null) {
      // La session existe mais la ligne ne se lit pas : un echec, jamais un
      // titulaire sans nom fabrique.
      throw StateError('Profil du titulaire introuvable.');
    }
    return identiteDepuis(
      ligne,
      courriel: utilisateur.email,
      appMetadata: utilisateur.appMetadata,
      motDePassePossible: motDePassePossible,
    );
  }

  @override
  Future<void> modifier({String? prenom, String? nom}) async {
    final User? utilisateur = _client.auth.currentUser;
    if (utilisateur == null) {
      throw StateError('Aucune session ouverte : identite non modifiable.');
    }
    final Map<String, String> champs = champsIdentite(prenom: prenom, nom: nom);
    // EDIT-INFOS-PERSO (garde-cap, 12/11/2026) : la ligne de soi, et elle
    // seule (`profiles_self_update`) ; la garde `guard_profile_privileged_columns`
    // refuse au serveur le changement de nom d'un eleve mineur. Une ligne non
    // ecrite (aucune rendue) est un echec, jamais une reussite supposee.
    final List<Map<String, dynamic>> ecrites = await _client
        .from('profiles')
        .update(champs)
        .eq('id', utilisateur.id)
        .select('id')
        .timeout(AppDelais.requeteMax);
    if (ecrites.isEmpty) {
      throw StateError('Identite non modifiee : aucune ligne ecrite.');
    }
  }
}

/// L'identite lue depuis une ligne `profiles` et la session. Pure, testee.
IdentiteTitulaire identiteDepuis(
  Map<String, dynamic> ligne, {
  required String? courriel,
  required Map<String, dynamic> appMetadata,
  bool motDePassePossible = false,
}) {
  String texte(Object? valeur) => valeur is String ? valeur.trim() : '';
  final String adresse = courriel?.trim() ?? '';
  return IdentiteTitulaire(
    prenom: texte(ligne['first_name']),
    nom: texte(ligne['last_name']),
    courriel: adresse.isEmpty ? null : adresse,
    methodeConnexion: methodeConnexionDepuis(
      appMetadata,
      motDePassePossible: motDePassePossible,
    ),
    statut: AccountStatus.depuisSql(ligne['account_status'] as String?),
  );
}

/// La methode de connexion d'apres le fournisseur principal de la session
/// (`app_metadata.provider`). Pure.
///
/// En production, un compte `email` n'entre que par lien a usage unique
/// (`service_auth.dart`) ; si la compilation autorise le mot de passe, la
/// methode n'est plus determinable et reste [MethodeConnexion.inconnue].
MethodeConnexion methodeConnexionDepuis(
  Map<String, dynamic> appMetadata, {
  bool motDePassePossible = false,
}) => switch (appMetadata['provider']) {
  'google' => MethodeConnexion.google,
  'email' when !motDePassePossible => MethodeConnexion.lienCourriel,
  _ => MethodeConnexion.inconnue,
};
