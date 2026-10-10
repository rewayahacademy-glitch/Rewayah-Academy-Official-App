// La couleur d'accent des profils eleves, choisie par le tuteur (decision du
// directeur du 04/10/2026, K-62 ; FI-2, FI-BR-19).
//
// Frontend seulement : aucune source serveur a ce jour, la colonne arrive en
// BR-1. La demonstration garde le choix en memoire. Une cle de jeton
// ([AccentProfil]) par profil, jamais une couleur libre.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/accent_profil.dart';
import 'capacite_indisponible.dart';

/// Les accents des profils du foyer.
abstract interface class PortAccentsProfils {
  /// L'accent de chaque profil du foyer qui en a un, par identifiant de
  /// profil eleve. Un profil absent n'a pas d'accent.
  Future<Map<String, AccentProfil>> lire();

  /// Fixe l'accent de [profilId] ; `null` retire l'accent. Le titulaire
  /// seulement (FI-BR-19 : la source refusera tout autre ecrivain).
  Future<void> choisir(String profilId, AccentProfil? accent);
}

/// **Aucune source serveur a ce jour** (FI-BR-19).
class AccentsProfilsIndisponibles implements PortAccentsProfils {
  /// Cree l'implementation.
  const AccentsProfilsIndisponibles();

  @override
  Future<Map<String, AccentProfil>> lire() =>
      Future<Map<String, AccentProfil>>.error(
        const CapaciteIndisponible('FI-BR-19'),
      );

  @override
  Future<void> choisir(String profilId, AccentProfil? accent) =>
      Future<void>.error(const CapaciteIndisponible('FI-BR-19'));
}

/// Les accents gardes en memoire : la demonstration et les tests. Rien
/// n'est envoye (K-28).
class AccentsProfilsEnMemoire implements PortAccentsProfils {
  /// Cree le depot avec [initial].
  AccentsProfilsEnMemoire([Map<String, AccentProfil>? initial])
    : _accents = <String, AccentProfil>{...?initial};

  final Map<String, AccentProfil> _accents;

  @override
  Future<Map<String, AccentProfil>> lire() async =>
      Map<String, AccentProfil>.unmodifiable(_accents);

  @override
  Future<void> choisir(String profilId, AccentProfil? accent) async {
    if (accent == null) {
      _accents.remove(profilId);
    } else {
      _accents[profilId] = accent;
    }
  }
}

/// Le port des accents ; la demonstration le surcharge.
final Provider<PortAccentsProfils> portAccentsProfilsProvider =
    Provider<PortAccentsProfils>((Ref _) => const AccentsProfilsIndisponibles());

/// Les accents du foyer, relus apres chaque choix (`ref.invalidate`).
final FutureProvider<Map<String, AccentProfil>> accentsProfilsProvider =
    FutureProvider<Map<String, AccentProfil>>(
      (Ref ref) => ref.watch(portAccentsProfilsProvider).lire(),
    );

/// L'accent du profil [profilId] quand il est connu, `null` sinon (lecture
/// en cours, en echec, indisponible ou aucun choix) : l'ecran pose alors le
/// cercle seul, sans bandeau, jamais une couleur au hasard.
AccentProfil? accentLu(AsyncValue<Map<String, AccentProfil>> accents,
        String profilId) =>
    accents.hasValue ? accents.value![profilId] : null;
