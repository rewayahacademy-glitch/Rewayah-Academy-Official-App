import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/db/app_database.dart';

/// Un profil connu de cet appareil.
///
/// Le strict necessaire pour dessiner une tuile de choix : un prenom et une
/// photo. Ni nom de famille, ni courriel, ni statut. **Le cache local ne peut
/// pas fuiter ce qu'il ne contient pas.**
@immutable
class ProfilLocal {
  /// Cree un profil local.
  const ProfilLocal({
    required this.id,
    required this.prenom,
    required this.identifiantImmuable,
    this.cleAvatar,
  });

  /// Identifiant du profil, identique a celui de la base.
  final String id;

  /// Prenom.
  final String prenom;

  /// Identifiant immuable.
  final String identifiantImmuable;

  /// Cle du fichier avatar dans le cache media.
  final String? cleAvatar;
}

/// Les profils que cet appareil connait.
///
/// C'est ce qui fait que `ELV-01` ne redemande jamais de code sur un appareil
/// deja appaire, et que le choix de profil fonctionne hors ligne.
abstract interface class ProfilsLocaux {
  /// Les profils appaires sur cet appareil.
  Future<List<ProfilLocal>> lister();

  /// Ajoute ou met a jour un profil.
  Future<void> enregistrer(ProfilLocal profil);

  /// Retire un profil de cet appareil.
  Future<void> oublier(String profilId);
}

/// L'implementation sur la base locale.
class ProfilsLocauxDrift implements ProfilsLocaux {
  /// Cree le depot.
  const ProfilsLocauxDrift(this._base);

  final AppDatabase _base;

  @override
  Future<List<ProfilLocal>> lister() async {
    final List<ProfilsFoyerData> lignes = await _base
        .select(_base.profilsFoyer)
        .get();
    return lignes
        .map(
          (ProfilsFoyerData l) => ProfilLocal(
            id: l.id,
            prenom: l.prenom,
            identifiantImmuable: l.identifiantImmuable,
            cleAvatar: l.cleAvatarCache,
          ),
        )
        .toList();
  }

  @override
  Future<void> enregistrer(ProfilLocal profil) async {
    await _base
        .into(_base.profilsFoyer)
        .insertOnConflictUpdate(
          ProfilsFoyerCompanion.insert(
            id: profil.id,
            identifiantImmuable: profil.identifiantImmuable,
            prenom: profil.prenom,
            cleAvatarCache: Value<String?>(profil.cleAvatar),
            synchroniseA: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> oublier(String profilId) async {
    await (_base.delete(
      _base.profilsFoyer,
    )..where(($ProfilsFoyerTable p) => p.id.equals(profilId))).go();
  }
}

/// La base locale de l'appareil.
final Provider<AppDatabase> baseLocaleProvider = Provider<AppDatabase>((
  Ref ref,
) {
  final AppDatabase base = AppDatabase();
  ref.onDispose(() => unawaited(base.close()));
  return base;
});

/// Les profils connus de cet appareil.
final Provider<ProfilsLocaux> profilsLocauxProvider = Provider<ProfilsLocaux>(
  (Ref ref) => ProfilsLocauxDrift(ref.watch(baseLocaleProvider)),
);
