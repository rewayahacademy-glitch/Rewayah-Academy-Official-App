import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';

/// Le role de la personne connectee dans son propre foyer, tel que le serveur
/// le rend (`mon_role_foyer()`, migration 20261106700000 ; lot N2). Une
/// capacite lue, jamais un role devine : le Foyer montre « Inviter un second
/// adulte » au titulaire et « Demander la reprise du foyer » au second
/// adulte.
enum RoleFoyer {
  /// Titulaire du foyer.
  titulaire,

  /// Second adulte, rattache au foyer d'un autre titulaire.
  secondAdulte,

  /// Aucun des deux (compte non valide, foyer ferme, autre role).
  aucun,
}

/// La lecture de [RoleFoyer] et du genre enregistre sur le profil de la
/// personne elle-meme.
@immutable
class RoleFoyerLu {
  /// Cree la lecture.
  const RoleFoyerLu({required this.role, this.femme});

  /// Le role.
  final RoleFoyer role;

  /// Vrai pour une femme, faux pour un homme, `null` quand le genre n'est pas
  /// enregistre : la page d'invitation prend alors sa forme neutre.
  final bool? femme;

  /// La place offerte au second adulte, pour la page d'invitation : une
  /// conjointe quand le titulaire est un homme, un conjoint quand c'est une
  /// femme, `null` (forme neutre) sans genre enregistre.
  bool? get placeFeminine => femme == null ? null : !femme!;
}

/// La lecture de la reponse de `mon_role_foyer()` ; une forme inconnue se lit
/// « aucun », sans genre.
RoleFoyerLu roleFoyerDepuis(Object? reponse) {
  if (reponse is! Map) return const RoleFoyerLu(role: RoleFoyer.aucun);
  final RoleFoyer role = switch (reponse['role']) {
    'titulaire' => RoleFoyer.titulaire,
    'second_adulte' => RoleFoyer.secondAdulte,
    _ => RoleFoyer.aucun,
  };
  final bool? femme = switch (reponse['genre']) {
    'female' => true,
    'male' => false,
    _ => null,
  };
  return RoleFoyerLu(role: role, femme: femme);
}

/// Le role dans le foyer. Sans adaptateur : `CapaciteIndisponible`, et les
/// lignes qui en dependent ne sont pas posees. `lib/main.dart` le surcharge
/// avec `mon_role_foyer()`.
final FutureProvider<RoleFoyerLu> roleFoyerProvider =
    FutureProvider<RoleFoyerLu>(
      (Ref _) => Future<RoleFoyerLu>.error(
        const CapaciteIndisponible('mon_role_foyer'),
      ),
      retry: (int _, Object _) => null,
    );
