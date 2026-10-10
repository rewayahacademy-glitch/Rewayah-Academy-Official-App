import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/service_comptes.dart' show EtatPiece;
import '../domain/enums.dart';

/// Un dossier a valider, tel que `dossiers_en_attente()` le rend.
///
/// **Une ligne est une PERSONNE, pas un document**, depuis la migration `0015`.
/// Avant elle, la fonction lisait `kyc_documents where status = 'pending'` :
/// une personne inscrite qui n'avait pas encore depose sa piece n'existait donc
/// pour aucun ecran, et trois enseignants ont attendu sept jours sans que le
/// centre de commande les compte. Les champs de la piece sont par consequent
/// **nullables** : [etatPiece] dit lequel des trois cas s'applique.
@immutable
class DossierAValider {
  /// Cree la description d'un dossier.
  ///
  /// Les trois derniers champs ont une valeur par defaut qui **preserve le sens
  /// d'avant la migration `0015`** : une ligne construite sans eux decrit un
  /// dossier dont la piece est deposee et attend un verdict, ce qui etait le
  /// seul cas possible quand la fonction lisait des documents.
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
    this.etatPiece = EtatPiece.aVerifier,
    this.inscritLeConnue,
    this.etatCompte,
  });

  /// Lit une ligne rendue par la fonction.
  factory DossierAValider.depuisJson(Map<String, dynamic> json) {
    DateTime? date(String cle) =>
        DateTime.tryParse(json[cle] as String? ?? '')?.toLocal();

    final DateTime inscription = date('inscrit_le') ?? DateTime.now();

    return DossierAValider(
      // **Nullable, et ce n'est pas une precaution** : une personne sans piece
      // deposee est desormais dans cette file, et c'est tout l'objet de la
      // migration `0015`. Un `as String` sec ici levait un `TypeError` et
      // rendait l'ecran en erreur des la premiere inscription incomplete.
      documentId: json['document_id'] as String?,
      profilId: json['profile_id'] as String,
      type: TypePiece.depuisSql(json['doc_type'] as String?),
      cleObjet: json['object_key'] as String?,
      // Faute de depot, l'anciennete se compte depuis l'inscription : c'est
      // elle qui mesure l'attente de la personne.
      deposeLe: date('depose_le') ?? inscription,
      prenom: json['first_name'] as String? ?? '',
      nom: json['last_name'] as String? ?? '',
      identifiantImmuable: json['immutable_id'] as String? ?? '',
      // K-47 (HL-A-6) : un role illisible retombe sur guardian, que la file
      // ADM-02 ecarte (enseignants seulement) : jamais pris pour un enseignant.
      role: AppRole.depuisSql(json['role'] as String?) ?? AppRole.guardian,
      etatPiece: EtatPiece.depuisSql(json['etat_piece'] as String?),
      inscritLeConnue: inscription,
      etatCompte: AccountStatus.depuisSql(json['account_status'] as String?),
    );
  }

  /// Identifiant de la piece. **Nul quand aucune piece n'a ete deposee.**
  final String? documentId;

  /// Le profil concerne.
  final String profilId;

  /// La nature de la piece. Nulle quand aucune piece n'a ete deposee.
  final TypePiece? type;

  /// La cle de l'objet dans le seau prive. Nulle sans piece deposee.
  final String? cleObjet;

  /// Date de depot, ou date d'inscription faute de depot. Le tri de la file
  /// suit l'anciennete.
  final DateTime deposeLe;

  /// Prenom du titulaire.
  final String prenom;

  /// Nom du titulaire. Visible ici, jamais d'un enseignant (ADR-008).
  final String nom;

  /// Identifiant immuable.
  final String identifiantImmuable;

  /// Role du titulaire.
  final AppRole role;

  /// L'etat de la piece : aucune, a verifier, ou presente mais hors de portee
  /// de ce lecteur (regle de genre, audit 1.3).
  final EtatPiece etatPiece;

  /// La date d'inscription telle que la base la rend. Nulle pour une ligne
  /// construite sans elle.
  final DateTime? inscritLeConnue;

  /// La date d'inscription de la personne.
  ///
  /// Se replie sur la date de depot quand elle n'est pas connue : c'est la
  /// meilleure approximation disponible, et jamais `now()`, qui afficherait
  /// « inscrit aujourd'hui » sur une personne qui attend depuis une semaine.
  DateTime get inscritLe => inscritLeConnue ?? deposeLe;

  /// L'etat du compte de la personne.
  final AccountStatus? etatCompte;

  /// Vrai quand l'identite de la personne est lisible.
  ///
  /// Fausse en mode observation, ou `dossiers_en_attente()` rend les noms
  /// nuls : c'est alors l'identifiant immuable qui designe la personne, et
  /// l'afficher deux fois n'apprend rien.
  bool get nomConnu => prenom.isNotEmpty || nom.isNotEmpty;

  /// Comment nommer cette personne a l'ecran.
  ///
  /// **Se replie sur l'identifiant immuable plutot que sur une ligne vide.**
  /// Le 18 septembre 2026, `ADM-02` affichait « Abdallah Sow » alors que la
  /// banniere d'observation promettait des prenoms masques ; la migration
  /// `0016` a ferme la fuite en base, et sans ce repli la fiche rendrait un
  /// titre vide au-dessus de l'identifiant.
  String get libelle {
    final String complet = '$prenom $nom'.trim();
    return complet.isEmpty ? identifiantImmuable : complet;
  }

  /// Comment nommer cette personne **dans une phrase**, hors de sa fiche.
  ///
  /// Le prenom seul, et l'identifiant faute de prenom. Le nom de famille n'a
  /// sa place que sur la fiche `ADM-02`, ou l'un des trois constats porte
  /// justement sur lui (« le nom correspond a celui du compte ») : ailleurs,
  /// il allonge la ligne sans rien ajouter au jugement (ADR-008).
  String get libelleCourt => prenom.isEmpty ? identifiantImmuable : prenom;

  /// Vrai quand un verdict est possible : il faut une piece, et qu'elle soit
  /// visible par ce lecteur.
  ///
  /// **Un dossier sans piece n'est pas jugeable, et ce n'est pas une panne** :
  /// il n'y a rien a constater, donc rien a trancher. L'ecran le dit au lieu
  /// de proposer deux boutons qui echoueraient.
  bool get jugeable => documentId != null && etatPiece == EtatPiece.aVerifier;

  /// Depuis combien de jours cette personne attend, en jours pleins.
  int joursDAttente(DateTime maintenant) =>
      maintenant.difference(inscritLe).inDays;
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

  /// Demande au serveur une URL de courte duree, identifiee par document.
  /// La cle de stockage ne quitte jamais le backend.
  Future<String> apercu(String documentId);

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
  Future<String> apercu(String documentId) async {
    final dynamic data = (await _client.functions.invoke(
      'piece-identite-acces',
      body: <String, dynamic>{'document_id': documentId},
    )).data;
    if (data is! Map<String, dynamic> || data['url'] is! String) {
      throw const FormatException('Reponse de signature de piece invalide');
    }
    final Uri? url = Uri.tryParse(data['url'] as String);
    if (url == null || !url.hasScheme || url.host.isEmpty) {
      throw const FormatException('URL de piece invalide');
    }
    return url.toString();
  }

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
///
/// `retry: null` (aucune retentative automatique) : Riverpod 3 relance tout
/// seul, avec un delai croissant (200 ms a 6,4 s, jusqu'a dix fois, ~32 s au
/// total), toute erreur qui n'etend pas `Error` (dont `GenreLecteurInconnu`,
/// une `Exception`) avant de la rendre par `.future` -- `ref.watch` la voit
/// tout de suite (`hasError` monte independamment de `isLoading`), mais
/// `ref.read(...future)` reste en attente jusqu'a la derniere retentative.
/// Sans ce reglage, l'ecran resterait sur son squelette pendant ~32 s avant
/// de dire enfin « Renseignez votre genre... » (AD-5) : le bouton
/// « Reessayer » de l'ecran est la retentative explicite, la base n'en doit
/// pas rejouer une en silence derriere lui.
final FutureProvider<List<DossierAValider>> dossiersEnAttenteProvider =
    FutureProvider<List<DossierAValider>>(
      (Ref ref) => ref.watch(serviceValidationProvider).enAttente(),
      retry: (int retryCount, Object error) => null,
    );
