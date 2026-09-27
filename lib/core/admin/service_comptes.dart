import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// L'etat de la piece d'identite d'un compte, vu par l'administration.
///
/// `nonVisible` n'est pas un synonyme d'`aucune` : la piece existe, mais la
/// regle de genre interdit a ce lecteur de la consulter (audit 1.3). Les
/// confondre ferait passer un dossier feminin lu par un membre du personnel
/// masculin pour un dossier jamais depose.
enum EtatPiece {
  /// Aucune piece deposee. C'est le cas qui n'etait visible nulle part avant
  /// le 18 septembre 2026.
  aucune('aucune'),

  /// Piece deposee, en attente de verdict.
  aVerifier('a_verifier'),

  /// Piece validee.
  validee('validee'),

  /// Piece refusee, avec motif.
  refusee('refusee'),

  /// Piece presente mais hors de portee de ce lecteur.
  nonVisible('non_visible');

  const EtatPiece(this.valeurSql);

  /// La valeur telle que la base la rend.
  final String valeurSql;

  /// Lit un etat depuis sa valeur SQL.
  ///
  /// Se replie sur `aucune` : c'est le seul repli qui ne promet rien. Se
  /// replier sur `validee` inventerait une verification.
  static EtatPiece depuisSql(String? valeur) {
    for (final EtatPiece etat in EtatPiece.values) {
      if (etat.valeurSql == valeur) {
        return etat;
      }
    }
    return EtatPiece.aucune;
  }
}

/// Un compte du produit, vu par l'administration (`ADM-08`).
@immutable
class CompteAdmin {
  /// Cree une ligne de compte.
  const CompteAdmin({
    required this.profilId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.role,
    required this.etat,
    required this.inscritLe,
    required this.accesJusquAu,
    required this.foyerId,
    required this.piece,
    required this.contrats,
    required this.aEnseignant,
    required this.enfantsDuFoyer,
  });

  /// Lit une ligne rendue par `comptes_admin()`.
  factory CompteAdmin.depuisJson(Map<String, dynamic> json) {
    DateTime? date(String cle) {
      final Object? brut = json[cle];
      return brut is String ? DateTime.tryParse(brut)?.toLocal() : null;
    }

    int entier(String cle) => (json[cle] as num?)?.toInt() ?? 0;

    return CompteAdmin(
      profilId: json['profile_id'] as String,
      identifiant: json['immutable_id'] as String? ?? '',
      prenom: json['prenom'] as String?,
      nom: json['nom'] as String?,
      role: AppRole.depuisSql(json['role'] as String?),
      etat: AccountStatus.depuisSql(json['etat_compte'] as String?),
      inscritLe: date('inscrit_le') ?? DateTime.now(),
      accesJusquAu: date('acces_jusqu_au'),
      foyerId: json['foyer_id'] as String?,
      piece: EtatPiece.depuisSql(json['etat_piece'] as String?),
      contrats: entier('contrats'),
      aEnseignant: json['a_enseignant'] as bool? ?? false,
      enfantsDuFoyer: entier('enfants_du_foyer'),
    );
  }

  /// L'identifiant technique du profil.
  final String profilId;

  /// L'identifiant immuable, `[ROLE]-[INITIALES]-[SEQ]`.
  final String identifiant;

  /// Le prenom. **Nul quand l'identite est masquee** : un agent qui observe
  /// avec masquage ne lit que l'identifiant.
  final String? prenom;

  /// Le nom de famille. Nul dans les memes conditions que le prenom.
  final String? nom;

  /// Le role du compte.
  final AppRole? role;

  /// L'etat du compte.
  final AccountStatus? etat;

  /// La date d'inscription.
  final DateTime inscritLe;

  /// La fin d'acces d'un compte provisoire (ADR-014).
  final DateTime? accesJusquAu;

  /// Le foyer auquel ce compte appartient.
  final String? foyerId;

  /// L'etat de la piece d'identite.
  final EtatPiece piece;

  /// Le nombre de contrats acceptes.
  final int contrats;

  /// Vrai quand cet eleve a un enseignant en cours.
  final bool aEnseignant;

  /// Le nombre d'enfants du foyer de ce compte.
  final int enfantsDuFoyer;

  /// Ce qui s'affiche pour nommer la personne.
  ///
  /// L'identifiant immuable sert de repli, jamais une chaine vide : une ligne
  /// sans libelle serait une ligne qu'on ne peut pas citer dans un journal.
  String get libelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }

  /// Vrai quand ce compte attend une decision de l'administration.
  ///
  /// Seul un enseignant en attente attend une decision (K-47) : la
  /// verification d'identite et la validation ne concernent que lui. Un tuteur
  /// `pending_kyc` ne depose rien et n'attend aucune validation.
  bool get attendUneDecision =>
      etat == AccountStatus.pendingKyc && role == AppRole.teacher;

  /// Depuis combien de jours ce compte attend, en jours pleins.
  int joursDAttente(DateTime maintenant) =>
      maintenant.difference(inscritLe).inDays;
}

/// La lecture des comptes par l'administration.
abstract interface class ServiceComptes {
  /// Tous les comptes, ce qui attend une decision d'abord.
  Future<List<CompteAdmin>> comptes();
}

/// L'implementation reelle.
class ServiceComptesSupabase implements ServiceComptes {
  /// Cree le service.
  const ServiceComptesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CompteAdmin>> comptes() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'comptes_admin',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              CompteAdmin.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

/// Le service des comptes employe par l'application.
final Provider<ServiceComptes> serviceComptesProvider =
    Provider<ServiceComptes>(
      (Ref ref) => ServiceComptesSupabase(Supabase.instance.client),
    );

/// Les comptes de `ADM-08`.
final FutureProvider<List<CompteAdmin>> comptesProvider =
    FutureProvider<List<CompteAdmin>>(
      (Ref ref) => ref.watch(serviceComptesProvider).comptes(),
    );
