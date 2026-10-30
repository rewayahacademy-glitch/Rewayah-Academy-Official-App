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
    this.paysEnseignant,
    this.detailsServis = false,
    this.tranche,
    this.classeId,
    this.classeLibelle,
    this.classeNumero,
    this.classesActives = 0,
    this.tuteurId,
    this.tuteurPrenom,
    this.tuteurNom,
    this.admissionATraiter = false,
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
      // ENS-PAYS-1 : lu des que `comptes_admin()` le rend (BR-1), nul avant.
      paysEnseignant: json['teacher_country'] as String?,
      // LISTES (30/10) : rendus par `comptes_admin_par_role()` seulement. Sa
      // presence se lit sur une colonne qu'elle rend toujours.
      detailsServis: json.containsKey('admission_a_traiter'),
      tranche: switch (json['tranche_age']) {
        'enfant' => TrancheAge.enfant,
        'adulte' => TrancheAge.adulte,
        _ => null,
      },
      classeId: json['classe_id'] as String?,
      classeLibelle: json['classe_libelle'] as String?,
      classeNumero: (json['classe_numero'] as num?)?.toInt(),
      classesActives: entier('classes_actives'),
      tuteurId: json['tuteur_id'] as String?,
      tuteurPrenom: json['tuteur_prenom'] as String?,
      tuteurNom: json['tuteur_nom'] as String?,
      admissionATraiter: json['admission_a_traiter'] as bool? ?? false,
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

  /// Le pays declare, pour un compte enseignant seulement (ENS-PAYS-1). Nul
  /// pour les autres roles, quand rien n'est declare, sous masquage, ou tant
  /// que le serveur ne le rend pas (BR-1).
  final String? paysEnseignant;

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

  /// Vrai quand la ligne vient de `comptes_admin_par_role()` : tranche,
  /// classe, tuteur et demande d'admission sont alors lus. Faux quand le
  /// serveur n'a que `comptes_admin()` : ces champs sont inconnus, pas vides.
  final bool detailsServis;

  /// La tranche d'age d'un eleve. Nulle hors eleve ou quand elle n'est pas lue.
  final TrancheAge? tranche;

  /// La classe active d'un eleve (la plus ancienne s'il en a plusieurs).
  final String? classeId;

  /// Le nom de cette classe.
  final String? classeLibelle;

  /// Son numero dans sa famille de classes (R16), pour la distinguer.
  final int? classeNumero;

  /// Le nombre de classes actives de l'eleve.
  final int classesActives;

  /// Le tuteur dont depend un eleve.
  final String? tuteurId;

  /// Son prenom, nul sous masquage d'identite.
  final String? tuteurPrenom;

  /// Son nom, nul dans les memes conditions.
  final String? tuteurNom;

  /// Vrai quand ce compte porte une demande d'admission recue, encore a
  /// traiter (famille ou eleve adulte, DECISION-ADMISSION du 27/10).
  final bool admissionATraiter;

  /// Le nom du tuteur : nul quand l'eleve n'en a pas ou que son identite est
  /// masquee.
  String? get tuteurLibelle {
    final String complet = <String?>[
      tuteurPrenom,
      tuteurNom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? null : complet;
  }

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
  ///
  /// Depuis l'admission (27/10), une famille ou un eleve adulte dont la
  /// demande est recue et encore a traiter attend aussi une decision.
  bool get attendUneDecision =>
      (etat == AccountStatus.pendingKyc && role == AppRole.teacher) ||
      admissionATraiter;

  /// Vrai quand l'acces provisoire est echu : la meme definition que le
  /// compteur « Acces echus » du Centre de commande (compte provisoire dont
  /// la date de fin d'acces est passee), lue sur les memes colonnes
  /// (DASH-ADM-ECHUS).
  bool accesEchu(DateTime maintenant) {
    final DateTime? fin = accesJusquAu;
    return etat == AccountStatus.provisionalActive &&
        fin != null &&
        fin.isBefore(maintenant);
  }

  /// Depuis combien de jours ce compte attend, en jours pleins.
  int joursDAttente(DateTime maintenant) =>
      maintenant.difference(inscritLe).inDays;
}

/// La tranche d'age d'un eleve, lue sur son type (`student_type`), jamais sur
/// une date de naissance.
enum TrancheAge {
  /// Un enfant (moins de 18 ans).
  enfant,

  /// Un adulte autonome.
  adulte,
}

/// Le nombre de lignes au-dela duquel le serveur coupe sans le dire
/// (`max_rows = 1000`, `supabase/config.toml` ; la valeur distante n'est pas
/// connue). La lecture des comptes n'a ni page ni total : quand la liste recue
/// atteint ce nombre, elle est peut-etre tronquee, et les inscriptions les
/// plus recentes sont les premieres a manquer (tri par anciennete croissante).
const int plafondComptesServeur = 1000;

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
    List<dynamic> reponse;
    try {
      reponse = await _client.rpc<List<dynamic>>('comptes_admin_par_role');
    } on PostgrestException catch (e) {
      // Tant que la migration 20261101100000 n'est pas installee, la fonction
      // n'existe pas (PGRST202) : on lit l'ancienne, et l'ecran dit ce qui
      // manque. Toute autre erreur remonte telle quelle.
      if (e.code != 'PGRST202') rethrow;
      reponse = await _client.rpc<List<dynamic>>('comptes_admin');
    }
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
