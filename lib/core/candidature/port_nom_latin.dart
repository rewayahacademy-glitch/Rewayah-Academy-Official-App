// Le port du nom en lettres latines : `PortNomLatin` (decision du directeur du
// 23/10/2026, `docs/current/DECISION-CANDIDATURES-2026-10-21.md`, section « Les
// noms dans une seule ecriture sur les listes »).
//
// Le titulaire d'une candidature lit l'etat de son nom et confirme son nom en
// lettres latines. Le serveur n'ecrit que ce que la personne confirme : il ne
// translittere rien (la proposition est calculee par `proposerNomLatin`, cote
// ecran). Deux appels, ceux des RPC `lire_nom_latin()` et
// `confirmer_nom_latin(texte)` de `20261024000000_cand_nom_latin.sql`.
//
// Un lot serveur absent leve `CapaciteIndisponible('CAND-NOM-LATIN')` : l'ecran
// n'a alors rien a demander. Une panne de reseau est [HorsLigneCandidature] :
// ce qui a ete envoye est non confirme (D5).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// L'identifiant de la dependance serveur du nom latin, pour la trace et les
/// tests : jamais affiche.
const String dependanceNomLatin = 'CAND-NOM-LATIN';

/// L'etat du nom du titulaire, tel que le serveur le rend.
@immutable
class EtatNomLatin {
  /// Cree l'etat.
  const EtatNomLatin({
    required this.nomComplet,
    required this.dejaLatin,
    required this.aConfirmer,
    this.nomLatin,
  });

  /// Lit la reponse de `lire_nom_latin()`.
  factory EtatNomLatin.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Objet attendu.');
    }
    final Object? nom = brut['nomComplet'];
    final Object? latin = brut['nomLatin'];
    return EtatNomLatin(
      nomComplet: nom is String ? nom : '',
      nomLatin: latin is String && latin.trim().isNotEmpty ? latin : null,
      dejaLatin: brut['dejaLatin'] == true,
      aConfirmer: brut['aConfirmer'] == true,
    );
  }

  /// Le nom d'origine, tel que la personne l'a saisi.
  final String nomComplet;

  /// Le nom latin que la personne a confirme, ou `null`.
  final String? nomLatin;

  /// Le nom d'origine est deja en lettres latines.
  final bool dejaLatin;

  /// Il reste a demander le nom latin : le nom d'origine ne l'est pas et rien
  /// n'est confirme.
  final bool aConfirmer;
}

/// Le texte envoye n'est pas un nom en lettres latines (le serveur l'a refuse,
/// rien n'est ecrit).
final class NomNonLatin implements Exception {
  /// Cree l'erreur.
  const NomNonLatin();
}

/// Le port du nom latin.
abstract interface class PortNomLatin {
  /// Lit l'etat du nom du titulaire. `PermissionInsuffisante` sans candidature ;
  /// `CapaciteIndisponible('CAND-NOM-LATIN')` sans lot serveur.
  Future<EtatNomLatin> lire();

  /// Confirme [nomLatin] (deja nettoye). Rend le nom latin retenu. Leve
  /// [NomNonLatin] quand le serveur refuse le texte.
  Future<String> confirmer(String nomLatin);
}

/// Le port du nom latin : absent avant le branchement serveur.
final Provider<PortNomLatin?> portNomLatinProvider = Provider<PortNomLatin?>(
  (Ref _) => null,
);

/// L'etat du nom du titulaire. Sans port, ou sans lot serveur : `null`, la
/// question ne se pose pas. Une lecture qui echoue pour une autre cause laisse
/// l'erreur (la page la traite : elle ne bloque jamais le questionnaire).
final FutureProvider<EtatNomLatin?> etatNomLatinProvider =
    FutureProvider.autoDispose<EtatNomLatin?>((Ref ref) async {
      final PortNomLatin? port = ref.watch(portNomLatinProvider);
      if (port == null) {
        return null;
      }
      try {
        return await port.lire();
      } on CapaciteIndisponible {
        return null;
      }
    }, retry: (int _, Object _) => null);
