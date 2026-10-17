import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Le role ecrit a cote du matricule (DECISION-IMMATRICULATION section 1) :
/// une etiquette calculee d'apres les donnees du serveur, jamais lue dans le
/// code. Une personne garde son matricule si elle change de role.
enum RoleAffiche {
  /// Eleve.
  eleve,

  /// Tuteur.
  tuteur,

  /// Enseignant.
  enseignant,

  /// Administration.
  administration,

  /// Controleur.
  controleur,

  /// Comptable.
  comptable;

  /// Le role d'apres la valeur SQL de `profiles.role`, ou `null` si inconnue.
  static RoleAffiche? depuisSql(String? valeur) => switch (valeur) {
    'student' => RoleAffiche.eleve,
    'guardian' => RoleAffiche.tuteur,
    'teacher' => RoleAffiche.enseignant,
    'admin' => RoleAffiche.administration,
    'controller' => RoleAffiche.controleur,
    'accountant' => RoleAffiche.comptable,
    _ => null,
  };
}

/// Le matricule d'une personne : `RA-26-4817`, attribue par le serveur.
final class Matricule {
  /// Cree un matricule.
  const Matricule({required this.valeur, required this.role});

  /// La valeur canonique, `RA-AA-NNNN` (ou `NNNNN`). Le role n'y entre pas.
  final String valeur;

  /// Le role affiche a cote de la valeur.
  final RoleAffiche role;

  /// La forme canonique attendue du serveur.
  static final RegExp forme = RegExp(r'^RA-[0-9]{2}-[0-9]{4,5}$');
}

/// La lecture du matricule d'une personne (IMM-FRONT-1).
///
/// Lisible par son titulaire et, pour ses enfants, par le tuteur du foyer :
/// la politique de lecture du serveur decide, le port ne tranche rien.
abstract interface class PortMatricule {
  /// Le matricule de [profileId], ou `null` s'il est indisponible (profil
  /// non lisible, matricule pas encore attribue) : l'ecran n'affiche alors
  /// aucune ligne.
  Future<Matricule?> matriculeDe(String profileId);
}

/// Le port tant que son adaptateur n'est pas branche : aucun matricule.
class MatriculeIndisponible implements PortMatricule {
  /// Cree l'implementation.
  const MatriculeIndisponible();

  @override
  Future<Matricule?> matriculeDe(String profileId) async => null;
}

/// Le port employe par l'application.
final Provider<PortMatricule> portMatriculeProvider = Provider<PortMatricule>(
  (Ref ref) => const MatriculeIndisponible(),
);

/// Le matricule d'un profil ; une erreur de lecture vaut « indisponible ».
final FutureProviderFamily<Matricule?, String> matriculeProvider =
    FutureProvider.family<Matricule?, String>((
      Ref ref,
      String profileId,
    ) async {
      try {
        return await ref.watch(portMatriculeProvider).matriculeDe(profileId);
      } on Object {
        return null;
      }
    });
