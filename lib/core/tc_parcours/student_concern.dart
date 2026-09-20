import 'package:flutter/foundation.dart';

/// De quoi parle un signalement (spec section 12.2).
enum CategorieSignalement {
  /// Difficulte d'apprentissage, contenu inadapte, besoin de reorientation.
  pedagogique('pedagogique'),

  /// Absences, retards repetes, disponibilite.
  presence('presence'),

  /// Materiel, reseau, son, image.
  technique('technique'),

  /// Demande de changement de groupe, d'horaire, d'enseignant.
  changement('changement'),

  /// Ce qui n'entre dans aucune des quatre autres.
  autre('autre');

  const CategorieSignalement(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit une categorie depuis sa valeur SQL. `null` sur valeur inconnue.
  static CategorieSignalement? depuisSql(String? valeur) {
    for (final CategorieSignalement categorie in CategorieSignalement.values) {
      if (categorie.valeurSql == valeur) {
        return categorie;
      }
    }
    return null;
  }
}

/// Ou en est un signalement.
enum StatutSignalement {
  /// Recu, pas encore examine.
  ouvert('ouvert'),

  /// L'administration l'instruit.
  enExamen('en_examen'),

  /// Un message est parti a la famille ou a l'eleve adulte.
  transmis('transmis'),

  /// Traite, plus rien a faire.
  clos('clos');

  const StatutSignalement(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` sur valeur inconnue.
  static StatutSignalement? depuisSql(String? valeur) {
    for (final StatutSignalement statut in StatutSignalement.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// A qui l'administration transmet.
enum CibleTransmission {
  /// Le tuteur legal, quand l'eleve est mineur.
  tuteurDuMineur('tuteur_du_mineur'),

  /// L'eleve lui-meme, quand il est majeur.
  eleveAdulte('eleve_adulte');

  const CibleTransmission(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit une cible depuis sa valeur SQL. `null` sur valeur inconnue.
  static CibleTransmission? depuisSql(String? valeur) {
    for (final CibleTransmission cible in CibleTransmission.values) {
      if (cible.valeurSql == valeur) {
        return cible;
      }
    }
    return null;
  }
}

/// Le signalement structure (`TEACHING_CORE_CONTRACTS.md` section 16).
///
/// **Contrat produit par Agent H**, consomme par H, E (action de fiche), Q et
/// l'administration a l'integration.
///
/// **Deux champs de texte, et ils ne se melangent jamais.** [internalDetails]
/// est ce que l'enseignant dit a l'administration ; [familySummary] est ce que
/// la famille peut lire. Le second n'est pas un resume automatique du premier :
/// il est ecrit ou valide par un humain, et il reste `null` tant que personne
/// ne l'a ecrit. C'est la seule forme qui tienne la regle « une note interne ne
/// part jamais automatiquement a la famille » : une troncature, un extrait ou
/// un champ unique avec un drapeau de visibilite finiraient tous par fuir.
///
/// Le contexte -- seance, groupe, eleve, enseignant -- est **prerempli par
/// l'implementation du port**, jamais retape par l'enseignant.
@immutable
class StudentConcern {
  /// Cree un signalement.
  StudentConcern({
    required this.id,
    required this.categorie,
    required this.groupeId,
    required this.academyId,
    required this.enseignantId,
    required this.internalDetails,
    required this.statut,
    required this.creeLeUtc,
    this.sessionId,
    this.familySummary,
    this.transmisLeUtc,
    this.transmisA,
  }) : assert(creeLeUtc.isUtc, 'tout instant de contrat est en UTC'),
       assert(
         transmisLeUtc == null || transmisLeUtc.isUtc,
         'tout instant de contrat est en UTC',
       ),
       assert(
         transmisLeUtc == null || familySummary != null,
         'rien ne part a la famille sans un message ecrit pour elle',
       );

  /// L'identifiant du signalement.
  final String id;

  /// De quoi il s'agit.
  final CategorieSignalement categorie;

  /// Le groupe concerne. **Prerempli.**
  final String groupeId;

  /// La seance concernee, quand le signalement nait d'une seance. **Prerempli.**
  final String? sessionId;

  /// L'eleve concerne, par son identifiant d'academie.
  ///
  /// **Jamais un nom de famille**, pas meme une initiale (decision `D-08`) :
  /// `RA-AB0012` desambiguise deux homonymes, et c'est deja ce que fait la
  /// Journee de l'enseignant.
  final String academyId;

  /// L'enseignant qui signale. **Prerempli.**
  final String enseignantId;

  /// Ce que l'administration doit savoir. **Ne part jamais a la famille.**
  final String internalDetails;

  /// Ce que la famille peut lire. `null` est un cas **normal**.
  final String? familySummary;

  /// L'etat du signalement.
  final StatutSignalement statut;

  /// Quand il a ete cree, en UTC.
  final DateTime creeLeUtc;

  /// Quand il a ete transmis, en UTC. `null` tant qu'il ne l'a pas ete.
  final DateTime? transmisLeUtc;

  /// A qui il a ete transmis. `null` tant qu'il ne l'a pas ete.
  final CibleTransmission? transmisA;

  /// Vrai quand un message existe pour la famille.
  ///
  /// C'est la **condition d'ouverture** de l'action Admin « Transmettre » :
  /// sans message ecrit pour elle, il n'y a rien a transmettre, et surtout pas
  /// la note interne.
  bool get peutEtreTransmis =>
      familySummary != null && familySummary!.trim().isNotEmpty;

  /// Ce que la famille recoit, ou `null` quand il n'y a rien a lui dire.
  ///
  /// **Ce type est la preuve, pas la promesse.** Il ne porte aucun champ
  /// capable de transporter [internalDetails] : un futur developpeur qui
  /// voudrait faire fuir la note interne devrait ajouter un champ, ce qui se
  /// voit en relecture -- alors qu'un oubli de masquage dans un ecran ne se
  /// voit pas.
  ResumeFamilleSignalement? pourLaFamille() {
    if (!peutEtreTransmis) {
      return null;
    }
    return ResumeFamilleSignalement(
      concernId: id,
      categorie: categorie,
      message: familySummary!.trim(),
      transmisA: transmisA,
      transmisLeUtc: transmisLeUtc,
    );
  }

  /// Le meme signalement, transmis.
  ///
  /// Refuse de produire un signalement transmis sans message pour la famille :
  /// l'assertion du constructeur le dirait en mode debug, la garde le dit en
  /// production.
  StudentConcern transmis({
    required CibleTransmission cible,
    required DateTime maintenantUtc,
  }) {
    if (!peutEtreTransmis) {
      throw const EchecSignalement(MotifEchecSignalement.familleSansMessage);
    }
    return StudentConcern(
      id: id,
      categorie: categorie,
      groupeId: groupeId,
      sessionId: sessionId,
      academyId: academyId,
      enseignantId: enseignantId,
      internalDetails: internalDetails,
      familySummary: familySummary,
      statut: StatutSignalement.transmis,
      creeLeUtc: creeLeUtc,
      transmisLeUtc: maintenantUtc.toUtc(),
      transmisA: cible,
    );
  }
}

/// Ce que la famille -- ou l'eleve adulte -- recoit d'un signalement.
///
/// **Aucun champ de note interne, a aucun niveau d'imbrication.**
@immutable
class ResumeFamilleSignalement {
  /// Cree un resume famille.
  const ResumeFamilleSignalement({
    required this.concernId,
    required this.categorie,
    required this.message,
    this.transmisA,
    this.transmisLeUtc,
  });

  /// Le signalement d'origine, pour le rattachement cote administration.
  final String concernId;

  /// De quoi il s'agit.
  final CategorieSignalement categorie;

  /// Le message ecrit pour la famille.
  final String message;

  /// A qui il a ete transmis.
  final CibleTransmission? transmisA;

  /// Quand, en UTC.
  final DateTime? transmisLeUtc;

  /// Le message tel qu'il partirait.
  ///
  /// Serialise ici et nulle part ailleurs : un test peut alors verifier sur la
  /// charge utile exacte qu'aucun mot de la note interne n'en fait partie.
  Map<String, dynamic> versJson() => <String, dynamic>{
    'concern_id': concernId,
    'categorie': categorie.valeurSql,
    'message': message,
    if (transmisA != null) 'transmis_a': transmisA!.valeurSql,
    if (transmisLeUtc != null)
      'transmis_le': transmisLeUtc!.toIso8601String(),
  };
}

/// Pourquoi un signalement a echoue.
enum MotifEchecSignalement {
  /// Reseau coupe, ecriture refusee, reponse illisible.
  ecriture,

  /// La note interne est vide : il n'y a rien a signaler.
  interneVide,

  /// La transmission a ete demandee alors qu'aucun message famille n'existe.
  familleSansMessage,

  /// Le signalement demande n'existe pas.
  inconnu,
}

/// L'echec d'un signalement.
class EchecSignalement implements Exception {
  /// Cree un echec.
  const EchecSignalement(this.motif);

  /// Ce qui a echoue.
  final MotifEchecSignalement motif;

  @override
  String toString() => 'EchecSignalement($motif)';
}
