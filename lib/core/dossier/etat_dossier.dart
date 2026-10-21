import 'package:flutter/foundation.dart';

import '../domain/enums.dart';

/// Ce que le titulaire d'un foyer a choisi a l'inscription (L5-01).
///
/// Garde par le serveur (`households.usage_inscription`) : il choisit la
/// variante du contrat, meme apres un rechargement ou sur un autre appareil.
enum UsageTitulaire {
  /// « Moi uniquement » : un eleve adulte, son propre tuteur.
  moi('moi'),

  /// « Moi et ma famille » : un tuteur de foyer.
  famille('famille');

  const UsageTitulaire(this.valeurSql);

  /// La valeur ecrite en base.
  final String valeurSql;

  /// La valeur lue en base, ou `null`.
  static UsageTitulaire? depuisSql(Object? valeur) {
    for (final UsageTitulaire u in values) {
      if (u.valeurSql == valeur) {
        return u;
      }
    }
    return null;
  }
}

/// Ce qui manque au dossier, tel que le portail d'attente le lira.
///
/// Miroir Dart de la fonction SQL `public.etat_dossier()`. Le calcul est en
/// base et non ici : le portail doit dire la meme chose que ce que
/// l'administration voit, et deux calculs finissent toujours par diverger.
@immutable
class EtatDossier {
  /// Cree un etat de dossier.
  const EtatDossier({
    required this.profilExiste,
    this.role,
    this.statutCompte,
    this.pieceDeposee = false,
    this.statutPiece,
    this.motifRefus,
    this.deposeLe,
    this.contratSigne = false,
    this.accuseSigne = false,
    this.codeConduiteSigne = true,
    this.correctionAutorisee,
    this.pieceRequise = true,
    this.usage,
    this.suitDesCours = false,
  });

  /// L'etat d'un compte dont le profil reste a creer.
  const EtatDossier.sansProfil() : this(profilExiste: false);

  /// Lit la reponse de `public.etat_dossier()`.
  factory EtatDossier.depuisJson(Map<String, dynamic> json) {
    if (json['profil'] != true) {
      return const EtatDossier.sansProfil();
    }
    final Object? depose = json['depose_le'];
    return EtatDossier(
      profilExiste: true,
      role: AppRole.depuisSql(json['role'] as String?),
      statutCompte: AccountStatus.depuisSql(json['statut'] as String?),
      pieceDeposee: json['piece_deposee'] == true,
      statutPiece: StatutPiece.depuisSql(json['piece_statut'] as String?),
      motifRefus: json['motif_refus'] as String?,
      deposeLe: depose is String ? DateTime.tryParse(depose)?.toLocal() : null,
      contratSigne: json['contrat_signe'] == true,
      accuseSigne: json['accuse_signe'] == true,
      codeConduiteSigne: json['code_conduite_signe'] as bool? ?? true,
      correctionAutorisee: json['correction_autorisee'] as bool?,
      pieceRequise: json['piece_requise'] as bool? ?? true,
      usage: UsageTitulaire.depuisSql(json['usage']),
      suitDesCours: json['suit_des_cours'] == true,
    );
  }

  /// Vrai quand une ligne `profiles` existe.
  final bool profilExiste;

  /// Le role du titulaire.
  final AppRole? role;

  /// Le statut de compte.
  final AccountStatus? statutCompte;

  /// Vrai quand une piece a ete deposee.
  final bool pieceDeposee;

  /// Le statut de la derniere piece deposee.
  final StatutPiece? statutPiece;

  /// Le motif de refus, en une phrase. Toujours present quand la piece est
  /// refusee : la base refuse un verdict negatif sans motif.
  final String? motifRefus;

  /// Date de depot de la derniere piece.
  final DateTime? deposeLe;

  /// Vrai quand le contrat propre au role est signe.
  final bool contratSigne;

  /// Vrai quand la carte d'accuse de l'ADR-011 a ete accusee.
  final bool accuseSigne;

  /// CAND-Q15 conduite : faux quand le code de conduite reste a accepter a sa
  /// version requise. Le serveur rend vrai pour tout compte qui n'est pas
  /// enseignant : l'ecran ne lit aucun role pour le savoir. Absent d'un
  /// serveur d'avant ce lot, qui ne l'exigeait pas : vrai.
  final bool codeConduiteSigne;

  /// Faux quand l'administration interdit la correction d'un dossier refuse.
  /// Absent de la reponse actuelle d'`etat_dossier()` (AD-BR-28) : nul, et la
  /// correction reste permise comme avant.
  final bool? correctionAutorisee;

  /// Faux quand le serveur dit qu'aucune piece n'est attendue. K-47 : la
  /// piece ne concerne que l'enseignant (voir [pieceExigee]) ; il n'y a plus
  /// de dispense famille. Absent de la reponse actuelle d'`etat_dossier()`
  /// (AD-BR-29) : vrai, comme avant.
  final bool pieceRequise;

  /// L5-01 : « Moi » ou « Famille », garde par le serveur pour le titulaire
  /// d'un foyer ; `null` pour les autres roles et les comptes d'avant.
  final UsageTitulaire? usage;

  /// L5-01 : vrai quand le titulaire a sa propre fiche d'eleve.
  final bool suitDesCours;

  /// Ce que le portail d'attente doit afficher.
  ///
  /// L'ordre compte : un compte suspendu le reste quel que soit l'etat de son
  /// dossier, et un refus prime sur une piece manquante puisque c'est lui qui
  /// dit quoi corriger.
  EtapeDossier get etape {
    if (statutCompte == AccountStatus.disabled) {
      return EtapeDossier.suspendu;
    }
    // K-47 (HL-A-6) : un tuteur n'a pas de piece, donc pas de refus de piece,
    // meme s'il en avait depose une avant la decision.
    if (statutPiece == StatutPiece.refusee && !estTuteur) {
      return EtapeDossier.refuse;
    }
    if (manquants.isNotEmpty) {
      return EtapeDossier.incomplet;
    }
    // Personne ne verifie le dossier d'un tuteur : son acces attend le
    // serveur (BR-1), pas une validation.
    return estTuteur
        ? EtapeDossier.accesEnPreparation
        : EtapeDossier.enVerification;
  }

  /// Vrai pour un tuteur (famille ou eleve adulte). K-47 : la piece
  /// d'identite et la validation ne concernent que l'enseignant.
  bool get estTuteur => role == AppRole.guardian;

  /// Vrai quand un profil existe sans role lisible : ni tuteur ni enseignant
  /// ne se devinent, le portail le dit illisible (jamais une piece demandee).
  bool get roleIllisible => profilExiste && role == null;

  /// Vrai quand une piece d'identite est attendue : pour l'enseignant
  /// seulement (K-47), meme tant que `etat_dossier()` ne rend pas
  /// `piece_requise`. Un role absent n'exige rien.
  bool get pieceExigee => pieceRequise && role == AppRole.teacher;

  /// Ce qu'il reste a fournir, dans l'ordre ou l'ecran le proposera.
  ///
  /// Deux ou trois elements au maximum, chacun avec son bouton : jamais un
  /// formulaire long (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, `TUT-00b`).
  ///
  /// L'accuse vient **avant** le contrat, et non l'inverse : il dit en langage
  /// clair ce que le contrat formalisera ensuite. Une clause signee au milieu
  /// d'un texte long n'informe personne, et c'est exactement le litige que
  /// l'ADR-011 cherche a eviter. Le code de conduite suit le contrat, sur la
  /// meme page des accords, et precede la piece.
  List<PieceManquante> get manquants => <PieceManquante>[
    if (!accuseSigne) PieceManquante.accuse,
    if (!contratSigne) PieceManquante.contrat,
    if (!codeConduiteSigne) PieceManquante.codeConduite,
    if (pieceExigee && (!pieceDeposee || statutPiece == StatutPiece.refusee))
      PieceManquante.pieceIdentite,
  ];

  @override
  bool operator ==(Object other) =>
      other is EtatDossier &&
      other.profilExiste == profilExiste &&
      other.role == role &&
      other.statutCompte == statutCompte &&
      other.pieceDeposee == pieceDeposee &&
      other.statutPiece == statutPiece &&
      other.motifRefus == motifRefus &&
      other.deposeLe == deposeLe &&
      other.contratSigne == contratSigne &&
      other.accuseSigne == accuseSigne &&
      other.codeConduiteSigne == codeConduiteSigne &&
      other.correctionAutorisee == correctionAutorisee &&
      other.pieceRequise == pieceRequise &&
      other.usage == usage &&
      other.suitDesCours == suitDesCours;

  @override
  int get hashCode => Object.hash(
    profilExiste,
    role,
    statutCompte,
    pieceDeposee,
    statutPiece,
    motifRefus,
    deposeLe,
    contratSigne,
    accuseSigne,
    codeConduiteSigne,
    correctionAutorisee,
    pieceRequise,
    usage,
    suitDesCours,
  );
}

/// Les cinq etats du portail d'attente.
enum EtapeDossier {
  /// Il manque des pieces. Une liste courte, chacune avec son bouton.
  incomplet,

  /// Tout est depose, l'academie verifie (enseignant).
  enVerification,

  /// Tuteur : accords signes, aucune piece a fournir ; l'acces s'ouvre cote
  /// serveur (BR-1). Aucune verification, aucun delai promis.
  accesEnPreparation,

  /// Refuse, avec un motif et de quoi corriger.
  refuse,

  /// Compte suspendu par decision d'administration.
  suspendu,
}

/// Ce qui peut manquer a un dossier.
enum PieceManquante {
  /// La carte a accuser une fois (ADR-011).
  accuse,

  /// La signature du contrat ou des conditions.
  contrat,

  /// Le code de conduite de l'enseignant, a accepter avant l'activation
  /// (CAND-Q15 conduite). Il se lit et s'accepte sur la page des accords.
  codeConduite,

  /// La piece d'identite.
  pieceIdentite,
}
