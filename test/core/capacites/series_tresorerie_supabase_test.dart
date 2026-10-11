import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/series_tresorerie_supabase.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';

void main() {
  group('SeriesTresorerieSupabase.decoder', () {
    test('decode les sept coffres et les series fixes sans calcul client', () {
      final result = SeriesTresorerieSupabase.decoder(_payload());

      expect(
        result.repartition.map((part) => part.coffre).toList(),
        Coffre.values,
      );
      expect(result.repartition.first.montant.mineur, 1234);
      expect(result.mensuel, hasLength(6));
      expect(result.flux30Jours, hasLength(30));
      expect(result.evolution, hasLength(6));
      expect(result.variationEntreesPourMille, isNull);
      expect(result.variationSortiesPourMille, 125);
    });

    test('refuse une cle obligatoire absente', () {
      final Map<String, dynamic> payload = _payload()..remove('evolution');
      expect(
        () => SeriesTresorerieSupabase.decoder(payload),
        throwsFormatException,
      );
    });

    test('refuse un coffre manquant ou duplique', () {
      final Map<String, dynamic> payload = _payload();
      payload['repartition'] = <Object?>[
        ...(payload['repartition'] as List<Object?>).take(6),
        (payload['repartition'] as List<Object?>).first,
      ];
      expect(
        () => SeriesTresorerieSupabase.decoder(payload),
        throwsFormatException,
      );
    });

    test('refuse les montants décimaux', () {
      final Map<String, dynamic> payload = _payload();
      (payload['repartition'] as List<Map<String, dynamic>>)
              .first['montant']['mineur'] =
          12.34;
      expect(
        () => SeriesTresorerieSupabase.decoder(payload),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _payload() => <String, dynamic>{
  'repartition': <Map<String, dynamic>>[
    for (final coffre in <String>[
      'fonds_clients_engages',
      'paie_a_decaisser',
      'charges_essentielles',
      'taxes_obligations',
      'reserve_strategique',
      'en_transit',
      'tresorerie_libre',
    ])
      <String, dynamic>{
        'coffre': coffre,
        'montant': <String, dynamic>{
          'mineur': coffre == 'fonds_clients_engages' ? 1234 : 0,
          'devise': 'USD',
        },
      },
  ],
  'mensuel': <Map<String, dynamic>>[
    for (int i = 0; i < 6; i++)
      <String, dynamic>{
        'mois': '2026-${(i + 1).toString().padLeft(2, '0')}-01',
        'entrees': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
        'sorties': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
      },
  ],
  'flux30Jours': <Map<String, dynamic>>[
    for (int i = 0; i < 30; i++)
      <String, dynamic>{
        'jour': '2026-10-${(i + 1).toString().padLeft(2, '0')}',
        'encaissements': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
        'decaissements': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
      },
  ],
  'evolution': <Map<String, dynamic>>[
    for (int i = 0; i < 6; i++)
      <String, dynamic>{
        'mois': '2026-${(i + 1).toString().padLeft(2, '0')}-01',
        'detenue': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
      },
  ],
  'entrees30Jours': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
  'sorties30Jours': <String, dynamic>{'mineur': 0, 'devise': 'USD'},
  'variationEntreesPourMille': null,
  'variationSortiesPourMille': 125,
};
