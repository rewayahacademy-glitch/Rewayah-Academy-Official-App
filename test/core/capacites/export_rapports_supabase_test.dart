import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/export_rapports_supabase.dart';

void main() {
  group('ExportRapportsSupabase.decoder', () {
    test('accepte la référence et le nombre de lignes contractuels', () {
      final result = ExportRapportsSupabase.decoder(<String, dynamic>{
        'reference': 'EXP-20261011-A1B2C3',
        'lignes': 17,
      });

      expect(result.reference, 'EXP-20261011-A1B2C3');
      expect(result.lignes, 17);
    });

    test('accepte un export vide', () {
      final result = ExportRapportsSupabase.decoder(<String, dynamic>{
        'reference': 'EXP-20261011-ABC123',
        'lignes': 0,
      });
      expect(result.lignes, 0);
    });

    test('refuse une référence, un type ou un compte hors contrat', () {
      for (final Object value in <Object>[
        <String, dynamic>{'reference': 'bad', 'lignes': 1},
        <String, dynamic>{'reference': 'EXP-20261011-ABC123', 'lignes': '1'},
        <String, dynamic>{'reference': 'EXP-20261011-ABC123', 'lignes': 5001},
        <String, dynamic>{'reference': 'EXP-20261011-ABC123'},
      ]) {
        expect(
          () => ExportRapportsSupabase.decoder(value),
          throwsFormatException,
        );
      }
    });
  });
}
