// La deconnexion (fiche du 27/10/2026, lignes 16 a 18) : la session locale
// est fermee d'abord, le serveur est prevenu ensuite au mieux sans bloquer ;
// la base locale est videe ; la memoire de l'application repart de zero ;
// l'ecran d'entree ne montre rien de la personne precedente, meme sans reseau.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appairage/profils_locaux.dart' show baseLocaleProvider;
import '../auth/service_auth.dart';
import '../cache/db/app_database.dart';
import '../observabilite/journal_dev.dart';

/// Remet toute la memoire de l'application a zero : la racine renouvelle sa
/// `ProviderScope`, et chaque provider se reconstruit a sa prochaine lecture.
/// Par defaut rien : c'est la racine reelle (`RacineDemonstrable`) qui le
/// fournit ; un ecran teste seul, la galerie ou une session d'observation
/// n'ont rien a renouveler.
final Provider<void Function()> remiseAZeroProvider = Provider<void Function()>(
  (Ref ref) => () {},
);

/// Vide toutes les tables de la base locale, en une transaction : profils du
/// foyer, seances a venir, ressources hors ligne, preferences, rapports en
/// attente. Rien de la personne ne reste sur l'appareil.
Future<void> viderTablesDeLAppareil(AppDatabase base) =>
    base.transaction(() async {
      for (final TableInfo<Table, dynamic> table in base.allTables) {
        await base.delete(table).go();
      }
    });

/// Ce que « Se deconnecter » fait, dans l'ordre.
class Deconnexion {
  /// Cree la deconnexion.
  const Deconnexion({
    required this.auth,
    required this.viderAppareil,
    required this.remiseAZero,
  });

  /// Ferme la session locale ; le serveur est prevenu au mieux, sans que
  /// l'appel ne l'attende.
  final ServiceAuth auth;

  /// Vide la base locale.
  final Future<void> Function() viderAppareil;

  /// Remet la memoire de l'application a zero.
  final void Function() remiseAZero;

  /// Execute la deconnexion. Ne leve jamais : une etape qui echoue est
  /// journalisee et la suivante se fait quand meme, parce que la sortie doit
  /// toujours aboutir.
  Future<void> executer() async {
    try {
      await auth.deconnexion();
    } on Object catch (erreur) {
      journalDev('Deconnexion : session locale, ${erreur.runtimeType}');
    }
    try {
      await viderAppareil();
    } on Object catch (erreur) {
      journalDev('Deconnexion : base locale non videe, ${erreur.runtimeType}');
    }
    remiseAZero();
  }
}

/// La deconnexion employee par l'application. La base locale n'est lue qu'au
/// moment du geste : un ecran monte sans base locale (test, galerie) ne
/// l'ouvre jamais.
final Provider<Deconnexion> deconnexionProvider = Provider<Deconnexion>(
  (Ref ref) => Deconnexion(
    auth: ref.watch(serviceAuthProvider),
    viderAppareil: () => viderTablesDeLAppareil(ref.read(baseLocaleProvider)),
    remiseAZero: ref.watch(remiseAZeroProvider),
  ),
);
