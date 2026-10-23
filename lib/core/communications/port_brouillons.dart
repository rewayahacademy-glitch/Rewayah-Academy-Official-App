// Les brouillons des communications (`DraftPersistence`, spec section 8.2 et
// section 20 ; COM-BR-12).
//
// V1 : MEMOIRE DE SESSION seulement. Le brouillon survit a la navigation
// locale (changer de fil, ouvrir le Focus, revenir), pas a la fermeture de
// l'application. Aucun stockage local : `StockagePreferencesDrift` n'est
// approuve que pour des preferences, jamais pour le texte d'un message
// (spec section 20 : ne jamais persister en clair des donnees sensibles dans
// un stockage non approuve). Aucune synchronisation entre appareils n'est
// promise sans contrat serveur.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'modeles_communication.dart';

/// L'endroit ou un brouillon est ecrit : la surface et l'objet vise.
///
/// Le brouillon porte l'identifiant de son objet (fil, canal, publication),
/// jamais « l'objet courant » (lecons des roles, 15) : passer d'un fil a
/// l'autre ne melange jamais deux textes.
@immutable
class CleBrouillon {
  /// Cree la cle. [objetId] ne peut pas etre vide.
  const CleBrouillon({required this.type, required this.objetId})
    : assert(objetId != '', 'Un brouillon vise un objet identifie.');

  /// La nature de l'objet vise (fil de message, canal, publication...).
  final TypeObjetLie type;

  /// L'identifiant de l'objet vise.
  final String objetId;

  @override
  bool operator ==(Object other) =>
      other is CleBrouillon && other.type == type && other.objetId == objetId;

  @override
  int get hashCode => Object.hash(type, objetId);

  @override
  String toString() => 'CleBrouillon(${type.name}, $objetId)';
}

/// Un brouillon garde.
@immutable
class Brouillon {
  /// Cree le brouillon.
  const Brouillon({
    required this.cle,
    required this.texte,
    required this.modifieLe,
  });

  /// L'endroit du brouillon.
  final CleBrouillon cle;

  /// Le texte, tel qu'il a ete saisi.
  final String texte;

  /// L'instant de la derniere modification (UTC).
  final DateTime modifieLe;
}

/// Les brouillons de la personne connectee.
abstract interface class PortBrouillons {
  /// Le brouillon de [cle] ; `null` s'il n'y en a pas.
  Future<Brouillon?> lire(CleBrouillon cle);

  /// Garde [texte] pour [cle]. Un texte vide (ou fait seulement d'espaces)
  /// efface le brouillon : un brouillon vide n'est pas un brouillon.
  Future<void> enregistrer(CleBrouillon cle, String texte);

  /// Efface le brouillon de [cle] (apres envoi confirme, ou abandon).
  Future<void> effacer(CleBrouillon cle);

  /// Tous les brouillons, le plus recent d'abord.
  Future<List<Brouillon>> tous();
}

/// Les brouillons en memoire de session : le comportement V1 retenu
/// (spec section 8.2), pas un double de demonstration.
///
/// Rien ne quitte la memoire du processus. Une nouvelle personne connectee
/// recoit une memoire neuve (voir [portBrouillonsProvider]).
class BrouillonsMemoire implements PortBrouillons {
  /// Cree une memoire vide. [maintenant] est injectable pour les tests.
  BrouillonsMemoire({DateTime Function()? maintenant})
    : _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final DateTime Function() _maintenant;
  final Map<CleBrouillon, Brouillon> _brouillons = <CleBrouillon, Brouillon>{};

  @override
  Future<Brouillon?> lire(CleBrouillon cle) async => _brouillons[cle];

  @override
  Future<void> enregistrer(CleBrouillon cle, String texte) async {
    if (texte.trim().isEmpty) {
      _brouillons.remove(cle);
      return;
    }
    _brouillons[cle] = Brouillon(
      cle: cle,
      texte: texte,
      modifieLe: _maintenant(),
    );
  }

  @override
  Future<void> effacer(CleBrouillon cle) async {
    _brouillons.remove(cle);
  }

  @override
  Future<List<Brouillon>> tous() async {
    final List<Brouillon> liste = _brouillons.values.toList()
      ..sort((Brouillon a, Brouillon b) => b.modifieLe.compareTo(a.modifieLe));
    return List<Brouillon>.unmodifiable(liste);
  }

  /// Oublie tous les brouillons.
  void vider() => _brouillons.clear();
}

/// Les brouillons employes par l'application.
///
/// La memoire est liee a la personne connectee : le provider se reconstruit
/// quand le profil change (deconnexion, autre compte), et les brouillons du
/// compte precedent sont oublies, jamais montres au suivant.
final Provider<PortBrouillons> portBrouillonsProvider =
    Provider<PortBrouillons>((Ref ref) {
      ref.watch(sessionProvider.select((SessionState s) => s.profileId));
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      ref.onDispose(memoire.vider);
      return memoire;
    });
