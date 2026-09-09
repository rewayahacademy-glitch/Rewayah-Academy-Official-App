import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'service_dossier.dart';

/// Un dossier a valider, tel que `dossiers_en_attente()` le rend.
@immutable
class DossierAValider {
  /// Cree la description d'un dossier.
  const DossierAValider({
    required this.documentId,
    required this.profilId,
    required this.type,
    required this.cleObjet,
    required this.deposeLe,
    required this.prenom,
    required this.nom,
    required this.identifiantImmuable,
    required this.role,
  });

  /// Lit une ligne rendue par la fonction.
  factory DossierAValider.depuisJson(Map<String, dynamic> json) =>
      DossierAValider(
        documentId: json['document_id'] as String,
        profilId: json['profile_id'] as String,
        type:
            TypePiece.depuisSql(json['doc_type'] as String?) ?? TypePiece.autre,
        cleObjet: json['object_key'] as String? ?? '',
        deposeLe:
            DateTime.tryParse(json['depose_le'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        prenom: json['first_name'] as String? ?? '',
        nom: json['last_name'] as String? ?? '',
        identifiantImmuable: json['immutable_id'] as String? ?? '',
        role: AppRole.depuisSql(json['role'] as String?) ?? AppRole.guardian,
      );

  /// Identifiant de la piece.
  final String documentId;

  /// Le profil concerne.
  final String profilId;

  /// La nature de la piece.
  final TypePiece type;

  /// La cle de l'objet dans le seau prive.
  final String cleObjet;

  /// Date de depot. Le tri de la file suit l'anciennete.
  final DateTime deposeLe;

  /// Prenom du titulaire.
  final String prenom;

  /// Nom du titulaire. Visible ici, jamais d'un enseignant (ADR-008).
  final String nom;

  /// Identifiant immuable.
  final String identifiantImmuable;

  /// Role du titulaire.
  final AppRole role;
}

/// Ce que l'administration peut faire d'un dossier.
///
/// Le cloisonnement de genre et la journalisation ne sont **pas** appliques ici
/// : ils vivent dans `read_kyc_documents()`, sur laquelle `dossiers_en_attente()`
/// et `decider_dossier()` sont toutes deux construites. Un ecran ne peut donc
/// pas les contourner, meme en connaissant un identifiant.
abstract interface class ServiceValidation {
  /// La file, la plus ancienne en premier.
  Future<List<DossierAValider>> enAttente();

  /// Une URL signee de courte duree pour l'apercu de la piece.
  Future<String> apercu(String cleObjet);

  /// Le verdict. Un refus exige un motif : la base le refuse sans.
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  });
}

/// Levee quand le genre du lecteur n'est pas renseigne.
///
/// Un cas a part parce qu'il a une reponse precise a l'ecran : ce n'est pas une
/// panne, c'est une information manquante que l'administrateur peut fournir.
class GenreLecteurInconnu implements Exception {
  /// Cree l'exception.
  const GenreLecteurInconnu();
}

/// L'implementation reelle.
class ServiceValidationSupabase implements ServiceValidation {
  /// Cree le service.
  const ServiceValidationSupabase(this._client);

  final SupabaseClient _client;

  /// Duree de vie de l'URL d'apercu, en secondes.
  ///
  /// Courte volontairement : une URL signee qui traine dans un historique de
  /// navigateur est une piece d'identite qui traine.
  static const int dureeApercuSecondes = 60;

  @override
  Future<List<DossierAValider>> enAttente() async {
    try {
      final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
        'dossiers_en_attente',
      );
      return lignes
          .cast<Map<String, dynamic>>()
          .map(DossierAValider.depuisJson)
          .toList();
    } on PostgrestException catch (erreur) {
      if (erreur.message.contains('genre du lecteur inconnu')) {
        throw const GenreLecteurInconnu();
      }
      rethrow;
    }
  }

  @override
  Future<String> apercu(String cleObjet) => _client.storage
      .from(ServiceDossierSupabase.seauKyc)
      .createSignedUrl(cleObjet, dureeApercuSecondes);

  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) => _client.rpc<void>(
    'decider_dossier',
    params: <String, dynamic>{
      'p_document_id': documentId,
      'p_approuve': approuve,
      'p_motif': ?motif,
    },
  );
}

/// Le service de validation employe par l'application.
final Provider<ServiceValidation> serviceValidationProvider =
    Provider<ServiceValidation>(
      (Ref ref) => ServiceValidationSupabase(Supabase.instance.client),
    );

/// La file des dossiers a valider.
final FutureProvider<List<DossierAValider>> dossiersEnAttenteProvider =
    FutureProvider<List<DossierAValider>>(
      (Ref ref) => ref.watch(serviceValidationProvider).enAttente(),
    );
