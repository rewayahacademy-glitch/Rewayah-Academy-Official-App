// Adaptateur CPT-BR-18. Les agrégats et conversions restent exclusivement SQL.
import 'package:supabase_flutter/supabase_flutter.dart';

import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'port_series_tresorerie.dart';

/// Lit la série déjà calculée par `public.series_tresorerie()`.
class SeriesTresorerieSupabase implements PortSeriesTresorerie {
  /// Crée l'adaptateur avec le client authentifié de l'application.
  const SeriesTresorerieSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SeriesTresorerie> series() async =>
      decoder(await _client.rpc('series_tresorerie'));

  /// Décode strictement la réponse RPC, sans compléter ni recalculer les séries.
  static SeriesTresorerie decoder(Object? value) {
    final Map<String, dynamic> json = _objet(value, 'racine');
    final List<Object?> repartition = _liste(json, 'repartition');
    final List<Object?> mensuel = _liste(json, 'mensuel');
    final List<Object?> flux = _liste(json, 'flux30Jours');
    final List<Object?> evolution = _liste(json, 'evolution');
    if (repartition.length != Coffre.values.length ||
        mensuel.length != 6 ||
        flux.length != 30 ||
        evolution.length != 6) {
      throw const FormatException('dimensions SeriesTresorerie invalides');
    }

    final List<PartCoffre> parts = repartition
        .map((Object? item) {
          final Map<String, dynamic> row = _objet(item, 'repartition[]');
          final String code = _texte(row, 'coffre');
          final Coffre coffre = _coffre(code);
          return PartCoffre(coffre: coffre, montant: _montant(row, 'montant'));
        })
        .toList(growable: false);
    if (parts.map((PartCoffre p) => p.coffre).toSet().length !=
            Coffre.values.length ||
        !parts.asMap().entries.every(
          (MapEntry<int, PartCoffre> entry) =>
              entry.value.coffre == Coffre.values[entry.key],
        )) {
      throw const FormatException('ordre, coffre manquant ou doublon');
    }

    return SeriesTresorerie(
      repartition: parts,
      mensuel: mensuel
          .map((Object? item) {
            final Map<String, dynamic> row = _objet(item, 'mensuel[]');
            return PointMensuel(
              mois: _date(row, 'mois'),
              entrees: _montant(row, 'entrees'),
              sorties: _montant(row, 'sorties'),
            );
          })
          .toList(growable: false),
      flux30Jours: flux
          .map((Object? item) {
            final Map<String, dynamic> row = _objet(item, 'flux30Jours[]');
            return PointJour(
              jour: _date(row, 'jour'),
              encaissements: _montant(row, 'encaissements'),
              decaissements: _montant(row, 'decaissements'),
            );
          })
          .toList(growable: false),
      evolution: evolution
          .map((Object? item) {
            final Map<String, dynamic> row = _objet(item, 'evolution[]');
            return PointEvolution(
              mois: _date(row, 'mois'),
              detenue: _montant(row, 'detenue'),
            );
          })
          .toList(growable: false),
      entrees30Jours: _montant(json, 'entrees30Jours'),
      sorties30Jours: _montant(json, 'sorties30Jours'),
      variationEntreesPourMille: _nullableInt(
        json,
        'variationEntreesPourMille',
      ),
      variationSortiesPourMille: _nullableInt(
        json,
        'variationSortiesPourMille',
      ),
    );
  }

  static Coffre _coffre(String code) => switch (code) {
    'fonds_clients_engages' => Coffre.fondsClientsEngages,
    'paie_a_decaisser' => Coffre.paieADecaisser,
    'charges_essentielles' => Coffre.chargesEssentielles,
    'taxes_obligations' => Coffre.taxesObligations,
    'reserve_strategique' => Coffre.reserveStrategique,
    'en_transit' => Coffre.enTransit,
    'tresorerie_libre' => Coffre.tresorerieLibre,
    _ => throw FormatException('coffre inconnu: $code'),
  };

  static Map<String, dynamic> _objet(Object? value, String cle) {
    if (value is Map<String, dynamic>) return value;
    throw FormatException('objet JSON invalide: $cle');
  }

  static List<Object?> _liste(Map<String, dynamic> json, String cle) {
    final Object? value = json[cle];
    if (value is List<Object?>) return value;
    throw FormatException('liste absente ou invalide: $cle');
  }

  static String _texte(Map<String, dynamic> json, String cle) {
    final Object? value = json[cle];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('texte absent ou invalide: $cle');
  }

  static DateTime _date(Map<String, dynamic> json, String cle) {
    final String value = _texte(json, cle);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('date invalide: $cle');
    }
    try {
      final DateTime date = DateTime.parse(value);
      if (date.toIso8601String().substring(0, 10) != value) {
        throw const FormatException('date non canonique');
      }
      return date;
    } on FormatException {
      throw FormatException('date invalide: $cle');
    }
  }

  static Montant _montant(Map<String, dynamic> json, String cle) {
    final Map<String, dynamic> value = _objet(json[cle], cle);
    final Object? mineur = value['mineur'];
    final Object? devise = value['devise'];
    if (mineur is int &&
        devise is String &&
        RegExp(r'^[A-Z]{3}$').hasMatch(devise)) {
      return Montant(mineur, devise);
    }
    throw FormatException('montant invalide: $cle');
  }

  static int? _nullableInt(Map<String, dynamic> json, String cle) {
    if (!json.containsKey(cle)) {
      throw FormatException('cle absente: $cle');
    }
    final Object? value = json[cle];
    if (value == null || value is int) return value as int?;
    throw FormatException('entier nullable invalide: $cle');
  }
}
