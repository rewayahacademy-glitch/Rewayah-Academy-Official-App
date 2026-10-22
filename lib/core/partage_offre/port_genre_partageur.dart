// Le genre de la personne qui partage la carte (CAND-06).
//
// **Un seul usage, decide par le directeur le 22/10/2026** : choisir la variante
// de la carte (la teinte et la silhouette, `VarianteCarte`) et dire « une sœur »
// ou « une personne » dans l'invitation a partager. Le genre est **lu** sur le
// profil de la personne (`profiles.gender`, lisible par son titulaire seulement :
// politique `profiles_self_select`), **jamais devine** d'un prenom ou d'une
// photo. Il ne pilote aucun droit, aucune notification, aucune donnee : le
// serveur n'en recoit rien de plus.
//
// Quand il ne se lit pas (profil illisible, hors ligne, aucun port), il vaut
// `null` : la carte prend la variante des hommes, qui est la neutre.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';

/// La lecture du genre du titulaire du compte.
abstract interface class PortGenrePartageur {
  /// Le genre du profil du titulaire, ou `null` s'il ne se lit pas.
  Future<Genre?> genreDuTitulaire();
}

/// Le port tant que son adaptateur n'est pas branche : genre inconnu.
class GenreIndisponible implements PortGenrePartageur {
  /// Cree l'implementation.
  const GenreIndisponible();

  @override
  Future<Genre?> genreDuTitulaire() async => null;
}

/// Le port employe par l'application.
final Provider<PortGenrePartageur> portGenrePartageurProvider =
    Provider<PortGenrePartageur>((Ref _) => const GenreIndisponible());

/// Le genre de la personne qui partage ; une erreur de lecture vaut « inconnu »
/// (`null`), jamais un echec de la page.
final FutureProvider<Genre?> genrePartageurProvider =
    FutureProvider.autoDispose<Genre?>((Ref ref) async {
      try {
        return await ref.watch(portGenrePartageurProvider).genreDuTitulaire();
      } on Object {
        return null;
      }
    });
