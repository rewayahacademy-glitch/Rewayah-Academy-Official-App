// NOM-PROPRE (INCIDENT-CANDIDATS, directeur, 14/11/2026) : un prenom et un nom
// s'ecrivent en lettres (toutes ecritures, signes diacritiques compris),
// espaces, trait d'union et apostrophes ; au moins deux lettres ; ni chiffre,
// ni symbole, ni emoji. Meme regle que `private.nom_propre_valide` (migration
// 20261125950000) : le serveur decide, l'ecran previent avant l'envoi.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

final RegExp _caracteresPermis = RegExp(
  r"^[\p{L}\p{M}‌' ’ʼ-]+$",
  unicode: true,
);
final RegExp _chiffre = RegExp(r'[\p{Nd}]', unicode: true);
final RegExp _lettre = RegExp(r'\p{L}', unicode: true);

/// Vrai quand [valeur] (espaces de bord retires) suit la regle du nom propre.
bool nomPropreValide(String valeur) {
  final String v = valeur.trim();
  return _caracteresPermis.hasMatch(v) &&
      !_chiffre.hasMatch(v) &&
      _lettre.allMatches(v).length >= 2;
}

/// Ce que le serveur dit du nom enregistre de la personne connectee
/// (`mon_nom_a_corriger()`).
final class EtatNomPropre {
  /// Cree l'etat.
  const EtatNomPropre({required this.aCorriger, this.prenom, this.nom});

  /// Lit la reponse du serveur ; une forme inconnue ne demande rien.
  factory EtatNomPropre.depuisJson(Object? brut) {
    if (brut is! Map) return const EtatNomPropre(aCorriger: false);
    return EtatNomPropre(
      aCorriger: brut['a_corriger'] == true,
      prenom: brut['prenom'] as String?,
      nom: brut['nom'] as String?,
    );
  }

  /// Vrai quand le nom enregistre ne suit pas la regle.
  final bool aCorriger;

  /// Le prenom enregistre.
  final String? prenom;

  /// Le nom enregistre.
  final String? nom;
}

/// Le serveur refuse le nom (`nom_non_conforme`).
class NomNonConforme implements Exception {
  /// Cree le refus.
  const NomNonConforme();
}

/// Lecture et correction du nom de la personne connectee.
abstract interface class PortNomPropre {
  /// Le nom enregistre est-il a corriger ?
  Future<EtatNomPropre> lire();

  /// Corrige le nom ; leve [NomNonConforme] sur un refus du serveur.
  Future<void> corriger({required String prenom, required String nom});
}

/// Le port employe : aucun par defaut (tests, demonstration) ; `main.dart`
/// pose l'adaptateur Supabase.
final Provider<PortNomPropre?> portNomPropreProvider = Provider<PortNomPropre?>(
  (Ref ref) => null,
);

/// L'etat du nom pour un profil ; nul sans port.
final FutureProviderFamily<EtatNomPropre?, String> nomACorrigerProvider =
    FutureProvider.family<EtatNomPropre?, String>((
      Ref ref,
      String profileId,
    ) async {
      final PortNomPropre? port = ref.watch(portNomPropreProvider);
      if (port == null) return null;
      return port.lire();
    });
