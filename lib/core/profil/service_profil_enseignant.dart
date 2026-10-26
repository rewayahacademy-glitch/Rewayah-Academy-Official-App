import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../session/session_controleur.dart';

/// Les informations de profil enseignant que les contrats actuels exposent.
///
/// Ce contrat est volontairement en lecture seule. Il ne porte ni finance, ni
/// salaire, ni indicateur calculé côté client.
class ProfilEnseignant {
  /// Crée une projection de profil enseignant.
  const ProfilEnseignant({
    required this.prenom,
    required this.identifiant,
    this.pays,
    this.langues = const <String>[],
    this.plafondHeures,
    this.statutCompte,
    this.verification,
    this.titre,
    this.clePhoto,
  });

  /// Le titre (`sayyid`, `sayyida`) de `teacher_profiles.titre`, ou `null`
  /// (salle, directeur, 26/10/2026 : « Sayyida Prenom » dans sa propre salle).
  final String? titre;

  /// La cle de la photo publique (`teacher_profiles.photo_storage_key`, seau
  /// `photos_enseignants`), ou `null`.
  final String? clePhoto;

  /// Prénom fourni par le profil authentifié.
  final String prenom;

  /// Identifiant immuable fourni par le profil authentifié.
  final String identifiant;

  /// Code du pays du contrat enseignant, s'il est renseigné.
  final String? pays;

  /// Langues déclarées dans le contrat enseignant.
  final List<String> langues;

  /// Plafond hebdomadaire contractuel, s'il est renseigné.
  final int? plafondHeures;

  /// Statut du compte lu sur le profil.
  final AccountStatus? statutCompte;

  /// Statut KYC lu sur le profil enseignant.
  final VerificationEnseignant? verification;

  /// Construit la projection depuis une ligne Supabase et sa relation.
  static ProfilEnseignant depuisJson(Map<String, dynamic> json) {
    final Map<String, dynamic> enseignant = _relationEnseignant(
      json['teacher_profiles'],
    );
    return ProfilEnseignant(
      prenom: _texte(json['first_name']),
      identifiant: _texte(json['immutable_id']),
      pays: _texteOptionnel(enseignant['country']),
      langues: _langues(enseignant['languages']),
      plafondHeures: _entier(enseignant['weekly_hours_cap']),
      titre: _texteOptionnel(enseignant['titre']),
      clePhoto: _texteOptionnel(enseignant['photo_storage_key']),
      statutCompte: AccountStatus.depuisSql(
        _texteOptionnel(json['account_status']),
      ),
      verification: VerificationEnseignant.depuisSql(
        _texteOptionnel(enseignant['kyc_status']),
      ),
    );
  }

  static Map<String, dynamic> _relationEnseignant(Object? relation) {
    if (relation is Map<String, dynamic>) {
      return relation;
    }
    if (relation is List<Object?> && relation.isNotEmpty) {
      final Object? premier = relation.first;
      if (premier is Map<String, dynamic>) {
        return premier;
      }
    }
    return const <String, dynamic>{};
  }

  static String _texte(Object? valeur) => valeur is String ? valeur.trim() : '';

  static String? _texteOptionnel(Object? valeur) {
    final String texte = _texte(valeur);
    return texte.isEmpty ? null : texte;
  }

  static List<String> _langues(Object? valeur) {
    if (valeur is! List<Object?>) {
      return const <String>[];
    }
    return valeur
        .whereType<String>()
        .map((String langue) => langue.trim())
        .where((String langue) => langue.isNotEmpty)
        .toList(growable: false);
  }

  static int? _entier(Object? valeur) => valeur is int ? valeur : null;
}

/// Statut de vérification du profil enseignant.
enum VerificationEnseignant {
  /// Dossier transmis, pas encore validé.
  enAttente('pending'),

  /// Dossier validé.
  validee('approved'),

  /// Dossier refusé ou à reprendre.
  refusee('rejected');

  const VerificationEnseignant(this.valeurSql);

  /// Valeur telle qu'elle existe dans le contrat SQL.
  final String valeurSql;

  /// Lit un statut SQL sans repli trompeur.
  static VerificationEnseignant? depuisSql(String? valeur) {
    for (final VerificationEnseignant statut in values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// Contrat de lecture du profil enseignant courant.
abstract interface class ServiceProfilEnseignant {
  /// Renvoie `null` si le profil enseignant n'existe pas encore.
  Future<ProfilEnseignant?> profil(String profilId);
}

/// Lecture Supabase des tables existantes, sans migration ni écriture.
class ServiceProfilEnseignantSupabase implements ServiceProfilEnseignant {
  /// Crée le service à partir d'un client Supabase.
  const ServiceProfilEnseignantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfilEnseignant?> profil(String profilId) async {
    final Map<String, dynamic>? ligne = await _client
        .from('profiles')
        .select(
          'first_name, immutable_id, account_status, '
          // `titre` et `photo_storage_key` (0030) : la salle nomme et montre
          // l'enseignant dans sa propre salle (teacher_profiles_self).
          'teacher_profiles(country, languages, weekly_hours_cap, kyc_status, '
          'titre, photo_storage_key)',
        )
        .eq('id', profilId)
        .maybeSingle();

    if (ligne == null || !_aUneRelationEnseignant(ligne)) {
      return null;
    }
    return ProfilEnseignant.depuisJson(ligne);
  }

  bool _aUneRelationEnseignant(Map<String, dynamic> ligne) {
    final Object? relation = ligne['teacher_profiles'];
    if (relation is Map<String, dynamic>) {
      return relation.isNotEmpty;
    }
    return relation is List<Object?> && relation.isNotEmpty;
  }
}

/// Service de profil enseignant de l'application.
final Provider<ServiceProfilEnseignant> serviceProfilEnseignantProvider =
    Provider<ServiceProfilEnseignant>(
      (Ref ref) => ServiceProfilEnseignantSupabase(Supabase.instance.client),
    );

/// Profil enseignant associé à la session courante.
final FutureProvider<ProfilEnseignant?> profilEnseignantProvider =
    FutureProvider<ProfilEnseignant?>((Ref ref) {
      final String? profilId = ref.watch(
        sessionProvider.select((session) => session.profileId),
      );
      if (profilId == null) {
        return null;
      }
      return ref.watch(serviceProfilEnseignantProvider).profil(profilId);
    });

/// La fiche d'un enseignant par son profil, quand l'appelant a le droit de
/// la lire (lui-meme : `teacher_profiles_self` ; la direction :
/// `teacher_profiles_admin_all`). Ailleurs, `null` : la salle se replie sur
/// la Classe de la famille (salle, annuaire de seance, 26/10/2026).
final FutureProviderFamily<ProfilEnseignant?, String>
profilEnseignantParIdProvider =
    FutureProvider.family<ProfilEnseignant?, String>(
      (Ref ref, String profilId) =>
          ref.watch(serviceProfilEnseignantProvider).profil(profilId),
    );
