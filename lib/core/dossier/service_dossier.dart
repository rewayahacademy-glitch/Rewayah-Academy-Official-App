import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import 'etat_dossier.dart';

/// Le serveur n'a pas consomme le code d'invitation a la creation du profil
/// enseignant (`inscrire_enseignant_invite`) : aucun profil n'a ete cree.
/// [resultat] est la raison rendue (`expiree`, `deja_utilisee`, `inconnue`).
class InvitationNonConsommee implements Exception {
  /// Cree le refus.
  const InvitationNonConsommee(this.resultat);

  /// La raison rendue par le serveur.
  final String resultat;
}

/// Une piece prete a partir.
class PieceAEnvoyer {
  /// Cree une piece.
  const PieceAEnvoyer({
    required this.octets,
    required this.nomFichier,
    required this.type,
  });

  /// Le contenu du fichier.
  final Uint8List octets;

  /// Le nom d'origine, dont on ne garde que l'extension.
  final String nomFichier;

  /// La nature de la piece.
  final TypePiece type;

  /// Taille en mega-octets, pour le message de refus.
  double get tailleMo => octets.lengthInBytes / (1024 * 1024);

  /// L'extension retenue, en minuscules et sans point.
  String get extension {
    final int point = nomFichier.lastIndexOf('.');
    if (point < 0 || point == nomFichier.length - 1) {
      return 'bin';
    }
    return nomFichier.substring(point + 1).toLowerCase();
  }
}

/// Tout ce qui touche au dossier d'inscription et de KYC.
///
/// Separe de [ServiceAuth] volontairement : l'authentification dit qui vous
/// etes, le dossier dit ou vous en etes. Les deux ne changent pas au meme
/// rythme et ne se testent pas de la meme facon.
abstract interface class ServiceDossier {
  /// Cree le profil manquant apres une premiere connexion.
  ///
  /// Le role est **declare** par l'utilisateur mais **borne** par la base :
  /// `creer_profil_inscription()` refuse tout ce qui n'est pas tuteur ou
  /// enseignant, et ecrit `pending_kyc` en dur. Un role recu du client n'est
  /// jamais un role accorde.
  ///
  /// [codeInvitation] : le code verifie par le candidat enseignant (C-14).
  /// Pour un enseignant, le profil est alors cree ET le code consomme dans
  /// la meme transaction serveur ; un code refuse leve
  /// [InvitationNonConsommee] et ne cree rien.
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
    String? codeInvitation,
  });

  /// Ou en est le dossier.
  Future<EtatDossier> etat();

  /// Enregistre une acceptation. Elle ne se modifie ni ne s'efface ensuite.
  Future<void> accepterContrat(SorteContrat sorte, String version);

  /// Vrai pour le service de la demonstration : rien n'est signe pour de
  /// vrai. Il choisit la version du contrat enseignant
  /// (`VersionsContrat.politiqueControlePubliee`).
  bool get demonstration;

  /// Depose une piece d'identite et cree sa ligne de suivi.
  ///
  /// **Le genre du dossier n'est pas un parametre.** Il decide quel membre du
  /// personnel pourra ouvrir la piece (audit 1.3) : le laisser venir du client
  /// reviendrait a confier au deposant le choix de qui le regarde. Un
  /// declencheur de la base l'ecrase par celui du profil concerne, et refuse le
  /// depot quand ce genre est inconnu.
  Future<void> deposerPiece(PieceAEnvoyer piece);

  /// Taille maximale acceptee pour une piece.
  static const int tailleMaximaleOctets = 8 * 1024 * 1024;
}

/// L'implementation reelle.
class ServiceDossierSupabase implements ServiceDossier {
  /// Cree le service a partir d'un client Supabase.
  const ServiceDossierSupabase(this._client);

  final SupabaseClient _client;

  /// Le seau prive des pieces d'identite, cree par la migration 0004.
  static const String seauKyc = 'kyc';

  @override
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
    String? codeInvitation,
  }) async {
    if (role == AppRole.teacher && codeInvitation != null) {
      final Object? reponse = await _client.rpc<Object?>(
        'inscrire_enseignant_invite',
        params: <String, dynamic>{
          'p_code': codeInvitation,
          'p_first_name': prenom,
          'p_last_name': nom,
          'p_gender': genre?.valeurSql,
        },
      );
      final Object? resultat = reponse is Map ? reponse['resultat'] : null;
      if (resultat != 'consommee') {
        throw InvitationNonConsommee(
          resultat is String ? resultat : 'inconnue',
        );
      }
      return;
    }
    await _client.rpc<void>(
      'creer_profil_inscription',
      params: <String, dynamic>{
        'p_role': role.valeurSql,
        'p_first_name': prenom,
        'p_last_name': nom,
        'p_gender': genre?.valeurSql,
      },
    );
  }

  @override
  Future<EtatDossier> etat() async {
    final Object? reponse = await _client.rpc<Object?>('etat_dossier');
    if (reponse is Map<String, dynamic>) {
      return EtatDossier.depuisJson(reponse);
    }
    return const EtatDossier.sansProfil();
  }

  @override
  bool get demonstration => false;

  @override
  Future<void> accepterContrat(SorteContrat sorte, String version) async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('aucune session');
    }
    await _client.from('contract_acceptances').insert(<String, dynamic>{
      'profile_id': uid,
      'contract_kind': sorte.valeurSql,
      'version': version,
    });
  }

  @override
  Future<void> deposerPiece(PieceAEnvoyer piece) async {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('aucune session');
    }

    // Le chemin porte l'identifiant du deposant en premier segment : c'est ce
    // que la policy de stockage compare a `auth.uid()`. Un nom de fichier
    // aleatoire evite qu'un second depot ecrase le premier avant sa lecture.
    final String cle =
        '$uid/${DateTime.now().toUtc().millisecondsSinceEpoch}.${piece.extension}';

    await _client.storage
        .from(ServiceDossierSupabase.seauKyc)
        .uploadBinary(cle, piece.octets);

    // Insertion sans `.select()` : la table n'a volontairement aucune policy de
    // lecture pour le titulaire, qui suit son dossier par `etat_dossier()`.
    //
    // Ni `gender` ni `purge_at` ne sont envoyes : un declencheur de la base les
    // pose, et ecrase toute valeur qui arriverait d'ici.
    await _client.from('kyc_documents').insert(<String, dynamic>{
      'profile_id': uid,
      'doc_type': piece.type.valeurSql,
      'object_key': cle,
    });
  }
}

/// Le service de dossier employe par l'application.
final Provider<ServiceDossier> serviceDossierProvider =
    Provider<ServiceDossier>(
      (Ref ref) => ServiceDossierSupabase(Supabase.instance.client),
    );

/// L'etat du dossier du compte courant.
final FutureProvider<EtatDossier> etatDossierProvider =
    FutureProvider<EtatDossier>(
      (Ref ref) => ref.watch(serviceDossierProvider).etat(),
    );
