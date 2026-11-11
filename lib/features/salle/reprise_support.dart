// Lot PARTAGE-GENERIQUE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : la page
// de reprise d'un support qui n'est pas le Coran, par Classe ET par support.
//
// Le Coran garde sa position (`position_reprise.dart`, table
// `classe_position_reprise`, une ligne par Classe) : rien n'y change, et la
// page d'un autre support n'y est jamais ecrite (elle ecraserait la page du
// Coran de la Classe). Les autres supports ont leur propre memoire : une page
// par Classe et par support.
//
// Le serveur ne sait la retenir qu'apres l'installation de la migration
// `20261123000000_partage_generique_position_support.sql` (brouillon non
// applique le 11/11/2026). Sans elle, l'application marche : la page est
// retenue le temps de la seance sur cet appareil, et une phrase dit a
// l'enseignant qu'elle ne l'est pas encore d'une seance a l'autre.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/observabilite/journal_dev.dart';

/// La page de reprise des supports d'une Classe, cote serveur.
abstract interface class PortRepriseSupport {
  /// Les pages retenues pour la Classe de la seance [sessionId], par
  /// identifiant de support. Vide quand rien n'est retenu.
  Future<Map<String, int>> pagesDeLaSeance(String sessionId);

  /// Retient la page [page] du support [support] pour la Classe de la seance
  /// [sessionId]. Rend `false` quand le serveur ne sait pas encore la retenir
  /// (migration non installee, ou aucun serveur) : ce n'est pas une erreur.
  Future<bool> enregistrer({
    required String sessionId,
    required String support,
    required String version,
    required int page,
    required int pages,
  });
}

/// Le port sans serveur (tests, demonstration) : rien n'est retenu.
class RepriseSupportAbsente implements PortRepriseSupport {
  /// Cree le port.
  const RepriseSupportAbsente();

  @override
  Future<Map<String, int>> pagesDeLaSeance(String sessionId) async =>
      const <String, int>{};

  @override
  Future<bool> enregistrer({
    required String sessionId,
    required String support,
    required String version,
    required int page,
    required int pages,
  }) async => false;
}

/// Le port employe. L'application reelle le surcharge par l'adaptateur
/// Supabase (`main.dart`).
final Provider<PortRepriseSupport> portRepriseSupportProvider =
    Provider<PortRepriseSupport>((Ref _) => const RepriseSupportAbsente());

/// Les pages de reprise des supports de la Classe d'une seance. Vide en
/// lecture, en echec ou sans page : rien n'est affiche plutot que suppose.
final FutureProviderFamily<Map<String, int>, String>
pagesRepriseSupportsProvider = FutureProvider.family<Map<String, int>, String>((
  Ref ref,
  String sessionId,
) async {
  try {
    return await ref
        .watch(portRepriseSupportProvider)
        .pagesDeLaSeance(sessionId);
  } on Object catch (erreur) {
    journalDev('pages de reprise des supports illisibles : $erreur');
    return const <String, int>{};
  }
}, retry: (int _, Object _) => null);

/// Vrai des que le serveur a repondu qu'il ne sait pas encore retenir la page
/// d'un support : la Bibliotheque le dit a l'enseignant par une phrase.
class RepriseSupportNonRetenue extends Notifier<bool> {
  @override
  bool build() => false;

  /// Le serveur ne retient pas (ou retient de nouveau) la page.
  void noter({required bool nonRetenue}) {
    if (state != nonRetenue) state = nonRetenue;
  }
}

/// Voir [RepriseSupportNonRetenue].
final NotifierProvider<RepriseSupportNonRetenue, bool>
repriseSupportNonRetenueProvider =
    NotifierProvider<RepriseSupportNonRetenue, bool>(
      RepriseSupportNonRetenue.new,
    );

/// La derniere page presentee d'un support, par Classe et par support : sur
/// cet appareil tout de suite, au serveur des qu'il sait la retenir.
class MemoireRepriseSupport {
  /// Cree la memoire ; [port] recoit chaque nouvelle page, [surNonRetenue]
  /// apprend si le serveur l'a retenue.
  MemoireRepriseSupport(this._port, {this.surNonRetenue});

  final PortRepriseSupport _port;

  /// Appele apres chaque reponse du serveur : `true` quand il ne retient pas.
  final void Function(bool nonRetenue)? surNonRetenue;

  final Map<(String, String), int> _pages = <(String, String), int>{};
  final Map<(String, String), int> _envoyees = <(String, String), int>{};
  final Map<(String, String), int> _enCours = <(String, String), int>{};

  /// La derniere page du support [support] presentee dans la Classe
  /// [groupeId] sur cet appareil, ou `null`.
  int? lire(String groupeId, String support) => _pages[(groupeId, support)];

  /// Retient [page] du support [support] pour la Classe [groupeId]. Avec
  /// [sessionId], la page part aussi au serveur si elle a change.
  void ecrire(
    String? groupeId, {
    required String support,
    required String version,
    required int page,
    required int pages,
    String? sessionId,
  }) {
    if (page < 1 || page > pages) return;
    if (groupeId != null) _pages[(groupeId, support)] = page;
    if (sessionId == null) return;
    final (String, String) cle = (sessionId, support);
    if (_envoyees[cle] == page || _enCours[cle] == page) return;
    _enCours[cle] = page;
    unawaited(_envoyer(cle, version: version, page: page, pages: pages));
  }

  Future<void> _envoyer(
    (String, String) cle, {
    required String version,
    required int page,
    required int pages,
  }) async {
    try {
      final bool retenue = await _port.enregistrer(
        sessionId: cle.$1,
        support: cle.$2,
        version: version,
        page: page,
        pages: pages,
      );
      // Retenue ou non, on ne renvoie pas la meme page a chaque
      // reconstruction ; la suivante repartira.
      _envoyees[cle] = page;
      surNonRetenue?.call(!retenue);
    } on Object catch (erreur) {
      // La salle continue ; la page repartira au prochain changement.
      journalDev('page du support non enregistree : $erreur');
    } finally {
      if (_enCours[cle] == page) _enCours.remove(cle);
    }
  }
}

/// La memoire des pages des supports, une pour la vie de l'application.
final Provider<MemoireRepriseSupport> memoireRepriseSupportProvider =
    Provider<MemoireRepriseSupport>(
      (Ref ref) => MemoireRepriseSupport(
        ref.watch(portRepriseSupportProvider),
        surNonRetenue: (bool nonRetenue) => ref
            .read(repriseSupportNonRetenueProvider.notifier)
            .noter(nonRetenue: nonRetenue),
      ),
    );
