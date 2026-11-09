import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Ce que le cache media sait faire.
///
/// Une interface, pour que la regle de purge se verifie sans toucher au disque.
abstract interface class CacheMedia {
  /// Retire un fichier du cache.
  Future<void> retirer(String cle);

  /// Les cles actuellement conservees.
  Future<Set<String>> clesConservees();

  /// Depose des octets sous une cle.
  ///
  /// Ajoute a la demande d'Agent B (`TC_CONTRACT_REQUEST_B.md` §3) : le
  /// hors-ligne de la Bibliotheque a besoin d'ecrire un support telecharge,
  /// ce que l'interface ne savait pas faire.
  Future<void> deposer(String cle, List<int> octets);

  /// Relit les octets d'une cle. `null` quand rien n'est conserve.
  Future<List<int>?> obtenir(String cle);
}

/// Un evenement de synchronisation venu du serveur.
///
/// La photo d'un enfant peut etre remplacee ou supprimee par le tuteur a tout
/// moment. La purge locale ne se declenche donc **pas** sur une expiration de
/// duree : elle se declenche sur cet evenement.
class EvenementPhoto {
  /// Cree un evenement.
  const EvenementPhoto({required this.cleAvatar, required this.survenuA});

  /// La cle de la photo concernee.
  final String cleAvatar;

  /// Quand le serveur a enregistre le changement.
  final DateTime survenuA;
}

/// Purge des photos de profil mises en cache.
///
/// L'ADR-012 impose des photos reelles d'enfants, ce qui rend la regle de purge
/// explicite plutot qu'implicite :
///
/// - L'image mise en cache est celle **deja compressee cote serveur**, jamais
///   l'originale. Le cache local ne conserve donc jamais un fichier plus lourd
///   que celui deja reduit, ce qui borne l'espace disque sans effort.
/// - Le retrait est declenche par un **evenement de synchronisation**, pas par
///   une expiration de duree. Un parent qui retire une photo ne doit pas la
///   retrouver affichee trois jours plus tard sur l'appareil de l'enfant.
/// - [delaiMaximal] est une **borne de securite**, pas le mecanisme : si aucun
///   evenement n'est arrive, une photo dont on a appris le changement est
///   retiree au plus tard 24 heures apres.
class PurgePhotos {
  /// Cree la purge.
  PurgePhotos(this._cache);

  final CacheMedia _cache;
  final Map<String, DateTime> _aRetirer = <String, DateTime>{};

  /// Delai maximal entre le changement cote serveur et la disparition locale.
  static const Duration delaiMaximal = Duration(hours: 24);

  /// Enregistre un changement de photo signale par le serveur et retire
  /// immediatement le fichier concerne.
  Future<void> signaler(EvenementPhoto evenement) async {
    _aRetirer[evenement.cleAvatar] = evenement.survenuA;
    await _cache.retirer(evenement.cleAvatar);
    _aRetirer.remove(evenement.cleAvatar);
  }

  /// Rattrape les retraits qu'un evenement n'a pas pu executer, par exemple
  /// parce que l'application etait fermee. A appeler au demarrage et a chaque
  /// synchronisation.
  ///
  /// Retourne les cles effectivement retirees.
  Future<Set<String>> rattraper(DateTime maintenant) async {
    final Set<String> retirees = <String>{};
    final Set<String> conservees = await _cache.clesConservees();

    for (final MapEntry<String, DateTime> e in _aRetirer.entries.toList()) {
      final bool depasse = maintenant.difference(e.value) >= delaiMaximal;
      if (conservees.contains(e.key) || depasse) {
        await _cache.retirer(e.key);
        retirees.add(e.key);
      }
    }
    _aRetirer.removeWhere((String cle, DateTime _) => retirees.contains(cle));
    return retirees;
  }

  /// Les retraits encore en attente. Expose pour les tests et le diagnostic.
  Map<String, DateTime> get enAttente =>
      Map<String, DateTime>.unmodifiable(_aRetirer);
}

/// Le cache media reel, adosse a `flutter_cache_manager`.
class CacheMediaFichiers implements CacheMedia {
  /// Cree le cache.
  CacheMediaFichiers([BaseCacheManager? gestionnaire])
    : _gestionnaire = gestionnaire ?? DefaultCacheManager();

  final BaseCacheManager _gestionnaire;
  final Set<String> _cles = <String>{};

  /// Memorise une cle deposee dans le cache.
  void noter(String cle) => _cles.add(cle);

  @override
  Future<void> retirer(String cle) async {
    await _gestionnaire.removeFile(cle);
    _cles.remove(cle);
  }

  @override
  Future<Set<String>> clesConservees() async => Set<String>.of(_cles);

  @override
  Future<void> deposer(String cle, List<int> octets) async {
    await _gestionnaire.putFile(
      cle,
      Uint8List.fromList(octets),
      key: cle,
    );
    noter(cle);
  }

  @override
  Future<List<int>?> obtenir(String cle) async {
    final FileInfo? info = await _gestionnaire.getFileFromCache(cle);
    if (info == null) {
      return null;
    }
    return info.file.readAsBytes();
  }
}
