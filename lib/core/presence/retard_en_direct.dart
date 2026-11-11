// LUMIERE-RETARD (11/11/2026) : le rouge « retard » des accueils. La seance
// est en direct et l'eleve n'est pas encore entre, au-dela du seuil du
// serveur (`presence.seuil_retard_secondes`). La reponse vient de la fonction
// serveur `retard_en_direct(uuid)` (migration 20261122700000) : l'appareil ne
// compare ni heure ni seuil, il ne fait que lire la liste.
//
// Une lecture absente ou en echec rend `null` : aucune lumiere, rien n'est
// devine. Le rouge « absents / en retard » de l'enseignant (lot E) lit la meme
// fonction par ce meme port.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;

import '../session/session_controleur.dart';

/// Un eleve pas encore entre dans une seance en direct, seuil depasse.
@immutable
class EleveEnRetard {
  /// Cree la ligne.
  const EleveEnRetard({required this.eleveId, required this.retardSecondes});

  /// L'eleve.
  final String eleveId;

  /// Les secondes ecoulees depuis le debut de la seance.
  final int retardSecondes;

  @override
  bool operator ==(Object other) =>
      other is EleveEnRetard &&
      other.eleveId == eleveId &&
      other.retardSecondes == retardSecondes;

  @override
  int get hashCode => Object.hash(eleveId, retardSecondes);
}

/// Les eleves en retard d'une seance en direct, lus sur le serveur.
abstract class PortRetardEnDirect {
  /// La liste, vide quand personne n'est en retard, `null` quand la lecture
  /// echoue (jamais une liste devinee).
  Future<List<EleveEnRetard>?> pour(String seanceId);
}

/// Sans serveur branche (tests, demonstration) : aucune lecture, aucune lumiere.
class RetardEnDirectIndisponible implements PortRetardEnDirect {
  /// Cree le port neutre.
  const RetardEnDirectIndisponible();

  @override
  Future<List<EleveEnRetard>?> pour(String seanceId) async => null;
}

/// Le port, neutre tant que `lib/main.dart` ne branche pas le serveur.
final Provider<PortRetardEnDirect> portRetardEnDirectProvider =
    Provider<PortRetardEnDirect>((Ref _) => const RetardEnDirectIndisponible());

/// La cadence de relecture : celle de la presence (un sixieme de la plus
/// courte fenetre de bascule d'etat), pour que la lumiere suive la salle.
const Duration cadenceRetardEnDirect = Duration(seconds: 20);

/// Les eleves en retard d'une seance, relus a la [cadenceRetardEnDirect], tant
/// que quelqu'un est connecte. Comme la presence, le flux ne s'interrompt
/// jamais sur une erreur : une lecture qui echoue emet `null`.
final StreamProviderFamily<List<EleveEnRetard>?, String>
retardEnDirectProvider = StreamProvider.family<List<EleveEnRetard>?, String>((
  Ref ref,
  String seanceId,
) {
  final String? personne = surveillerPersonneConnectee(ref);
  if (seanceId.trim().isEmpty || personne == null) {
    return Stream<List<EleveEnRetard>?>.value(null);
  }
  final PortRetardEnDirect port = ref.watch(portRetardEnDirectProvider);
  final StreamController<List<EleveEnRetard>?> sortie =
      StreamController<List<EleveEnRetard>?>();

  Future<void> lire() async {
    List<EleveEnRetard>? lignes;
    try {
      lignes = await port.pour(seanceId);
    } on Object {
      lignes = null;
    }
    if (!sortie.isClosed) sortie.add(lignes);
  }

  final Timer minuterie = Timer.periodic(
    cadenceRetardEnDirect,
    (Timer _) => unawaited(lire()),
  );
  ref.onDispose(() {
    minuterie.cancel();
    unawaited(sortie.close());
  });
  unawaited(lire());
  return sortie.stream;
});
