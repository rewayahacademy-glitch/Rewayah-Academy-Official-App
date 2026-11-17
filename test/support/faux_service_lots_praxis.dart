// Le double de `ServiceLotsPraxis` : aucune base, des lots fictifs, un journal
// de ce que l'ecran a demande.

import 'package:rewayah_academy/core/agent/lots_praxis.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Un lot fictif (code, resume et heure inventes).
LotPraxis lotFictif({
  String id = 'l1',
  String code = '482913',
  int nb = 2,
  List<String>? resume,
  DateTime? expireLe,
}) => LotPraxis(
  id: id,
  acte: 'acte_fictif',
  nb: nb,
  resume: resume ?? <String>['Note S : un', 'Note S : deux'],
  code: code,
  expireLe: expireLe ?? DateTime.utc(2026, 11, 17, 14, 35),
);

/// Le double.
class FauxServiceLotsPraxis implements ServiceLotsPraxis {
  /// Cree le double.
  FauxServiceLotsPraxis({
    List<LotPraxis>? lots,
    this.erreurLecture,
    this.refusDroit = false,
    this.annulationRendue = true,
  }) : lots = lots ?? <LotPraxis>[];

  /// Les lots en attente.
  List<LotPraxis> lots;

  /// Une lecture qui echoue (reseau, serveur).
  Exception? erreurLecture;

  /// Vrai : la base refuse faute de double verification (42501).
  bool refusDroit;

  /// Ce que rend `annuler` (faux : le lot n'attendait deja plus).
  bool annulationRendue;

  /// Ce que l'ecran a demande, dans l'ordre.
  final List<String> appels = <String>[];

  @override
  Future<List<LotPraxis>> enAttente() async {
    appels.add('enAttente');
    if (refusDroit) {
      throw const PostgrestException(message: 'refus', code: '42501');
    }
    if (erreurLecture != null) {
      throw erreurLecture!;
    }
    return List<LotPraxis>.of(lots);
  }

  @override
  Future<bool> annuler(String id) async {
    appels.add('annuler:$id');
    if (refusDroit) {
      throw const PostgrestException(message: 'refus', code: '42501');
    }
    if (annulationRendue) {
      lots = lots.where((LotPraxis l) => l.id != id).toList();
    }
    return annulationRendue;
  }
}
