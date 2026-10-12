import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/frise_demandes_supabase.dart';
import 'package:rewayah_academy/core/offres/port_frise_demande.dart';

void main() {
  test('projects only listed events as household wall-clock times', () {
    final List<FriseDemande> result = frisesDepuisDonnees(
      <dynamic>[
        <String, Object?>{
          'demande_id': 'd-1',
          'eleve_id': 'e-1',
          'prenom': 'Mina',
          'etape': 'classe_validee',
          'motif': null,
          'fuseau_iana': 'Europe/Paris',
          'debut_cours': '2026-10-12T10:00:00',
          'peut_choisir_autre_creneau': false,
        },
      ],
      <Map<String, dynamic>>[
        <String, dynamic>{
          'demande_id': 'd-1',
          'type': 'envoyee',
          'motif_attente': null,
          'survenu_le_foyer': '2026-10-11T08:15:00',
        },
        <String, dynamic>{
          'demande_id': 'd-1',
          'type': 'classe_creee',
          'motif_attente': null,
          'survenu_le_foyer': null,
        },
        <String, dynamic>{
          'demande_id': 'autre-demande',
          'type': 'eleve_integre',
          'motif_attente': null,
          'survenu_le_foyer': '2026-10-11T09:00:00',
        },
      ],
    );

    expect(result, hasLength(1));
    expect(result.single.courante, TypeEtapeFrise.classeCreee);
    expect(result.single.etapes.first.quand, DateTime(2026, 10, 11, 8, 15));
    expect(result.single.etapes[1].quand, isNull);
    expect(result.single.etapes.last.quand, DateTime(2026, 10, 12, 10));
    expect(result.single.fuseauIana, 'Europe/Paris');
  });

  test('rejects UTC instants in the household wall-clock projection', () {
    expect(
      () => frisesDepuisDonnees(
        <dynamic>[
          <String, Object?>{
            'demande_id': 'd-1',
            'eleve_id': 'e-1',
            'prenom': 'Mina',
            'etape': 'envoyee',
            'motif': null,
            'fuseau_iana': 'Europe/Paris',
            'debut_cours': null,
            'peut_choisir_autre_creneau': false,
          },
        ],
        <Map<String, dynamic>>[
          <String, dynamic>{
            'demande_id': 'd-1',
            'type': 'envoyee',
            'motif_attente': null,
            'survenu_le_foyer': '2026-10-11T08:15:00Z',
          },
        ],
      ),
      throwsFormatException,
    );
  });
}
