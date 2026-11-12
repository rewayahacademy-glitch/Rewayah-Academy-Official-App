import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'capacite_indisponible.dart';

/// Comment le titulaire se connecte en production.
enum MethodeConnexion {
  /// Lien a usage unique recu par courriel.
  lienCourriel,

  /// Compte Google.
  google,

  /// Non determinable depuis la session.
  inconnue,
}

/// L'identite du titulaire du compte, en lecture.
@immutable
class IdentiteTitulaire {
  /// Cree l'identite.
  const IdentiteTitulaire({
    required this.prenom,
    required this.nom,
    required this.methodeConnexion,
    this.courriel,
    this.statut,
  });

  /// Prenom (`profiles.first_name`).
  final String prenom;

  /// Nom (`profiles.last_name`).
  final String nom;

  /// Courriel de la session. `null` : non expose.
  final String? courriel;

  /// Methode de connexion.
  final MethodeConnexion methodeConnexion;

  /// Statut du compte. `null` : illisible, jamais « actif » par defaut.
  final AccountStatus? statut;
}

/// L'identite du titulaire du compte, tous roles (contrat K6, consommateur :
/// le Compte du tuteur et celui de l'enseignant, COMPTE-ENSEIGNANT-IDENTITE,
/// 12/11/2026). Rien n'y depend du role : la ligne `profiles` de soi et la
/// session.
abstract interface class PortIdentiteTitulaire {
  /// L'identite de la personne connectee.
  Future<IdentiteTitulaire> lire();

  /// Modifie le prenom et le nom de la personne connectee (EDIT-INFOS-PERSO,
  /// 12/11/2026). Le serveur reste seul juge : il refuse le changement a un
  /// eleve mineur. Une erreur, quelle qu'elle soit, est un echec.
  Future<void> modifier({String? prenom, String? nom});
}

/// La longueur maximale d'un prenom ou d'un nom saisi.
const int longueurMaxNom = 80;

/// Pourquoi un prenom ou un nom saisi n'est pas envoye.
enum DefautNom {
  /// Vide, ou fait seulement d'espaces.
  vide,

  /// Plus long que [longueurMaxNom].
  tropLong,
}

/// Le defaut d'un prenom ou d'un nom saisi, ou `null` s'il peut partir. Pure.
DefautNom? defautNom(String? valeur) {
  final String texte = valeur?.trim() ?? '';
  if (texte.isEmpty) return DefautNom.vide;
  if (texte.characters.length > longueurMaxNom) return DefautNom.tropLong;
  return null;
}

/// Les seules colonnes ecrites (`first_name`, `last_name`), rognees. Leve une
/// [ArgumentError] si l'une manque ou depasse : rien ne part alors. Pure.
Map<String, String> champsIdentite({String? prenom, String? nom}) {
  if (defautNom(prenom) case final DefautNom defaut) {
    throw ArgumentError.value(prenom, 'prenom', defaut.name);
  }
  if (defautNom(nom) case final DefautNom defaut) {
    throw ArgumentError.value(nom, 'nom', defaut.name);
  }
  return <String, String>{
    'first_name': prenom!.trim(),
    'last_name': nom!.trim(),
  };
}

/// L'identite tant que son adaptateur n'est pas livre.
///
/// **La lecture est branchable sans backend** : `profiles` par soi
/// (`profiles_self_select`) et `auth.currentUser` (courriel, fournisseur).
/// L'adaptateur reel `lib/core/capacites/identite_titulaire_supabase.dart` est
/// ecrit par le **lot E** (`00_OWNERSHIP.md` section 3), qui remplace alors
/// l'implementation du provider ci-dessous.
class IdentiteTitulaireIndisponible implements PortIdentiteTitulaire {
  /// Cree l'implementation.
  const IdentiteTitulaireIndisponible();

  @override
  Future<IdentiteTitulaire> lire() =>
      Future<IdentiteTitulaire>.error(const CapaciteIndisponible('LOT-E'));

  @override
  Future<void> modifier({String? prenom, String? nom}) =>
      Future<void>.error(const CapaciteIndisponible('DB-CPT-01'));
}

/// L'identite du titulaire employee par l'application.
final Provider<PortIdentiteTitulaire> portIdentiteTitulaireProvider =
    Provider<PortIdentiteTitulaire>(
      (Ref ref) => const IdentiteTitulaireIndisponible(),
    );
