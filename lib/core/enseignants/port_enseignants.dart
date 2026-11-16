// LP-2 : le port de la liste des enseignants (`lister_enseignants`, LP-1).
//
// Absent avant le branchement serveur : sans port, la lecture est une capacite
// indisponible. Aucune retentative automatique : chaque lecture est
// journalisee au serveur, un echec se relit par « Reessayer ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import 'modeles_enseignants.dart';

/// L'identifiant de la dependance serveur de la liste, pour la trace : jamais
/// affiche.
const String dependanceListeEnseignants = 'LP-1';

/// La liste paginee des enseignants.
abstract interface class PortEnseignants {
  /// Une page de la liste (50 lignes), portee par le genre du lecteur.
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  });
}

/// Le port de la liste des enseignants : absent avant le branchement serveur.
final Provider<PortEnseignants?> portEnseignantsProvider =
    Provider<PortEnseignants?>((Ref _) => null);

/// Une page de la liste. Sans port : [CapaciteIndisponible].
final FutureProviderFamily<PageEnseignants, RequeteEnseignants>
pageEnseignantsProvider = FutureProvider.autoDispose
    .family<PageEnseignants, RequeteEnseignants>((
      Ref ref,
      RequeteEnseignants requete,
    ) {
      final PortEnseignants? port = ref.watch(portEnseignantsProvider);
      if (port == null) {
        return Future<PageEnseignants>.error(
          const CapaciteIndisponible(dependanceListeEnseignants),
        );
      }
      return port.lister(
        filtre: requete.filtre,
        tri: requete.tri,
        page: requete.page,
      );
    }, retry: (int _, Object _) => null);
