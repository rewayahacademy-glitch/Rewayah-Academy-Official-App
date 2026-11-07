// Lot salle 2 (directeur, 25/10/2026, transmis par le pilote) : la salle se
// souvient de la derniere page du Coran presentee par classe, et y revient a
// l'ouverture suivante, pour l'enseignant (les eleves suivent l'enseignant).
//
// CAHIER-C1 (06/11/2026) : la memoire n'est plus seulement sur l'appareil.
// Chaque nouvelle page presentee est aussi envoyee au serveur
// ([PortPositionReprise.enregistrer]) ; la preparation de la seance suivante
// la relit, sur un autre appareil comme pour le remplacant. La carte locale
// reste : elle repond tout de suite dans la salle ouverte, sans attendre le
// reseau, et evite de renvoyer la meme page a chaque reconstruction.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observabilite/journal_dev.dart';
import 'position_reprise.dart';

/// La derniere page du Coran presentee, par classe.
class MemoirePageClasse {
  /// Cree la memoire ; [port] recoit chaque nouvelle page.
  MemoirePageClasse([this._port = const PositionRepriseAbsente()]);

  final PortPositionReprise _port;
  final Map<String, int> _pages = <String, int>{};
  // La derniere page acceptee par le serveur, par seance : on n'envoie
  // qu'un changement, et on renvoie apres un echec.
  final Map<String, int> _envoyees = <String, int>{};
  final Map<String, int> _enCours = <String, int>{};

  /// La derniere page presentee dans la classe [groupeId], ou `null`.
  int? lire(String groupeId) => _pages[groupeId];

  /// Retient [page] pour la classe [groupeId] (1 a 604). Avec [sessionId],
  /// la page part aussi au serveur si elle a change : le serveur retrouve la
  /// classe de la seance, meme quand la salle n'a pas recu [groupeId] (entree
  /// d'un remplacant).
  void ecrire(String? groupeId, int page, {String? sessionId}) {
    if (page < 1 || page > 604) return;
    if (groupeId != null) _pages[groupeId] = page;
    if (sessionId == null) return;
    if (_envoyees[sessionId] == page || _enCours[sessionId] == page) return;
    _enCours[sessionId] = page;
    unawaited(_envoyer(sessionId, page));
  }

  Future<void> _envoyer(String sessionId, int page) async {
    try {
      await _port.enregistrer(sessionId: sessionId, page: page);
      _envoyees[sessionId] = page;
    } catch (erreur) {
      // La salle continue ; la page repartira au prochain changement.
      journalDev('page presentee non enregistree : $erreur');
    } finally {
      if (_enCours[sessionId] == page) _enCours.remove(sessionId);
    }
  }
}

/// La memoire des pages, une pour la vie de l'application.
final Provider<MemoirePageClasse> memoirePageClasseProvider =
    Provider<MemoirePageClasse>(
      (Ref ref) => MemoirePageClasse(ref.watch(portPositionRepriseProvider)),
    );
