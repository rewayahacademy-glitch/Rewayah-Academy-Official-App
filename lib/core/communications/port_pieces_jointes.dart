// Les pieces jointes des communications (spec section 12, COM-BR-04).
//
// Le frontend ne code en dur aucune politique de taille ni de type : la
// politique vient du serveur par `PortPolitiquePiecesJointes` (le
// `AttachmentPolicyPort` de la spec). Tant qu'aucun contrat n'existe, le port
// de production dit « indisponible » (`CapaciteIndisponible`), jamais une
// politique inventee.
//
// Une piece jointe ne porte qu'une REFERENCE OPAQUE : jamais une URL de
// stockage (R2), un chemin interne, un jeton signe ou un secret. L'ouverture
// passera par un jeton ephemere demande au serveur au moment du toucher
// (BR-1), jamais par une adresse gardee dans le modele.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// La reference opaque d'une piece jointe, telle que le serveur la donne.
///
/// Refuse a la construction tout ce qui ressemble a une adresse : un schema
/// (`https:`, `r2:`, `s3:`), une barre oblique ou inverse (chemin), un
/// parametre de requete (`?`, `&`, jeton signe), une espace. Une reference
/// valide est un identifiant, rien d'autre.
@immutable
class ReferencePieceJointe {
  /// Cree la reference. Leve [ArgumentError] si [valeur] n'est pas opaque.
  ReferencePieceJointe(this.valeur) {
    if (!estOpaque(valeur)) {
      throw ArgumentError.value(
        '<masquee>',
        'valeur',
        'Une reference de piece jointe est un identifiant opaque, '
            'jamais une adresse ni un chemin.',
      );
    }
  }

  /// La forme admise : lettres, chiffres, tiret, souligne, point, de 1 a
  /// 128 caracteres, sans `..`. Ni deux-points (schema), ni barre (chemin),
  /// ni `?`, `&` ou `=` (parametre, jeton signe), ni espace.
  static final RegExp _forme = RegExp(r'^[A-Za-z0-9_.-]{1,128}$');

  /// Vrai si [brut] est une reference opaque admissible.
  static bool estOpaque(String brut) =>
      _forme.hasMatch(brut) && !brut.contains('..');

  /// L'identifiant, a renvoyer tel quel au serveur. Jamais affiche.
  final String valeur;

  @override
  bool operator ==(Object other) =>
      other is ReferencePieceJointe && other.valeur == valeur;

  @override
  int get hashCode => valeur.hashCode;

  /// Ne rend jamais la valeur : une reference ne s'ecrit pas dans un journal.
  @override
  String toString() => 'ReferencePieceJointe(<opaque>)';
}

/// L'etat d'une piece jointe (spec section 12, sept etats).
enum EtatPieceJointe {
  /// Autorisee par la politique, prete a partir.
  autorisee,

  /// Plus lourde que la politique ne l'admet.
  tropVolumineuse,

  /// D'un type que la politique refuse.
  typeInterdit,

  /// En cours d'envoi.
  enCours,

  /// Envoyee, sur accuse du serveur seulement.
  envoyee,

  /// L'envoi n'a pas ete confirme (« non confirme », jamais « non envoye »).
  echec,

  /// La piece n'est pas disponible (retiree, non autorisee, source absente).
  indisponible,
}

/// La nature d'une piece jointe, pour choisir l'icone et la lecture.
enum NaturePieceJointe {
  /// Un document (PDF, texte...).
  document,

  /// Une image.
  image,

  /// Un enregistrement audio importe.
  audio,

  /// Un message vocal enregistre dans l'application (COM-VOC).
  vocal,

  /// Une autre nature.
  autre,
}

/// Une piece jointe telle qu'elle s'affiche : nom, type, taille, etat.
///
/// Rien d'autre n'est affichable : la [reference] reste opaque et ne
/// s'affiche jamais (spec section 12).
@immutable
class PieceJointe {
  /// Cree la piece jointe. [nom] est reduit a son dernier segment : un
  /// chemin (`dossier/sous/fichier.pdf`) ne s'affiche jamais.
  PieceJointe({
    required this.reference,
    required String nom,
    required this.nature,
    required this.typeLisible,
    this.tailleOctets,
    this.duree,
    this.etat = EtatPieceJointe.envoyee,
    this.peutOuvrir = false,
  }) : assert(
         tailleOctets == null || tailleOctets >= 0,
         'Une taille est positive ou nulle.',
       ),
       nom = nomAffichable(nom);

  /// La reference opaque, a renvoyer au serveur pour ouvrir la piece.
  final ReferencePieceJointe reference;

  /// Le nom du fichier, sans chemin.
  final String nom;

  /// La nature.
  final NaturePieceJointe nature;

  /// Le type, deja redige pour l'affichage (« PDF », « Image »).
  final String typeLisible;

  /// La taille en octets ; `null` si le serveur ne la donne pas.
  final int? tailleOctets;

  /// La duree d'un audio ou d'un vocal ; `null` sinon.
  final Duration? duree;

  /// L'etat.
  final EtatPieceJointe etat;

  /// Vrai si l'action « Ouvrir » est autorisee pour la personne qui lit. Une
  /// action non autorisee n'est pas rendue (jamais grisee).
  final bool peutOuvrir;

  /// Le dernier segment de [brut], sans chemin ni parametre ; « » si rien ne
  /// reste.
  static String nomAffichable(String brut) {
    final String sansParametre = brut.split(RegExp(r'[?#]')).first;
    final String segment = sansParametre.split(RegExp(r'[/\\]')).last.trim();
    return segment;
  }

  /// Une copie dans un autre etat.
  PieceJointe avecEtat(EtatPieceJointe nouvelEtat) => PieceJointe(
    reference: reference,
    nom: nom,
    nature: nature,
    typeLisible: typeLisible,
    tailleOctets: tailleOctets,
    duree: duree,
    etat: nouvelEtat,
    peutOuvrir: peutOuvrir,
  );
}

/// La politique des pieces jointes, telle que le serveur la donne.
///
/// Les types sont des types MIME en minuscules (`application/pdf`) ; un type
/// generique `image/*` admet toute image.
@immutable
class PolitiquePiecesJointes {
  /// Cree la politique.
  PolitiquePiecesJointes({
    required this.tailleMaxOctets,
    required Set<String> typesAutorises,
  }) : assert(tailleMaxOctets > 0, 'Une taille maximale est positive.'),
       typesAutorises = Set<String>.unmodifiable(
         typesAutorises.map((String t) => t.trim().toLowerCase()),
       );

  /// La taille maximale d'une piece, en octets.
  final int tailleMaxOctets;

  /// Les types MIME admis.
  final Set<String> typesAutorises;

  /// L'etat d'un fichier choisi, avant tout envoi : [EtatPieceJointe.autorisee],
  /// [EtatPieceJointe.typeInterdit] ou [EtatPieceJointe.tropVolumineuse].
  /// Le type est verifie d'abord : un fichier interdit l'est quelle que soit
  /// sa taille.
  EtatPieceJointe evaluer({
    required String typeMime,
    required int tailleOctets,
  }) {
    if (!admetType(typeMime)) {
      return EtatPieceJointe.typeInterdit;
    }
    if (tailleOctets > tailleMaxOctets) {
      return EtatPieceJointe.tropVolumineuse;
    }
    return EtatPieceJointe.autorisee;
  }

  /// Vrai si [typeMime] est admis, exactement ou par un type generique.
  bool admetType(String typeMime) {
    final String type = typeMime.trim().toLowerCase();
    if (typesAutorises.contains(type)) {
      return true;
    }
    final int barre = type.indexOf('/');
    return barre > 0 &&
        typesAutorises.contains('${type.substring(0, barre)}/*');
  }
}

/// La politique des pieces jointes (`AttachmentPolicyPort`, spec section 12).
abstract interface class PortPolitiquePiecesJointes {
  /// La politique en vigueur pour la personne connectee.
  Future<PolitiquePiecesJointes> politique();
}

/// La politique tant qu'aucun contrat serveur n'existe (COM-BR-04) : elle
/// echoue avec [CapaciteIndisponible], jamais une politique inventee. L'ecran
/// ne propose alors pas de joindre un fichier.
class PolitiquePiecesJointesIndisponible implements PortPolitiquePiecesJointes {
  /// Cree l'implementation.
  const PolitiquePiecesJointesIndisponible();

  @override
  Future<PolitiquePiecesJointes> politique() =>
      Future<PolitiquePiecesJointes>.error(
        const CapaciteIndisponible('COM-BR-04'),
      );
}

/// La politique des pieces jointes employee par l'application. La
/// demonstration la remplace par `overrideWithValue`, sous
/// `environnementAutoriseDemo`.
final Provider<PortPolitiquePiecesJointes> portPolitiquePiecesJointesProvider =
    Provider<PortPolitiquePiecesJointes>(
      (Ref ref) => const PolitiquePiecesJointesIndisponible(),
    );
