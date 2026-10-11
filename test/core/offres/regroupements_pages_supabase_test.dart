import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/page_regroupements.dart';
import 'package:rewayah_academy/core/offres/regroupements_pages_supabase.dart';

void main() {
  test('decodes a server page without deriving quota or class capacity', () {
    final PageRegroupements page = pageRegroupementsDepuisJson(
      <String, dynamic>{
        'lignes': <Object?>[
          <String, Object?>{
            'regroupement_id': 'o:opaque',
            'type_public': 'adulte',
            'langue_code': 'francais',
            'langue_nom': 'Français',
            'fuseau_iana': 'Europe/Paris',
            'occurrences': <Object?>[
              <String, Object?>{'jour_iso': '1', 'heure': 18, 'minute': 0},
            ],
            'nombre_eleves': 4,
            'quota': 6,
            'autres_fuseaux': <Object?>[
              <String, Object?>{
                'fuseau': 'Asia/Riyadh',
                'jour_iso': '1',
                'heure': 20,
                'minute': 0,
                'decalage_jour': 0,
              },
            ],
            'peut_creer_classe': false,
            'classe': null,
            'minimum': null,
            'classes_existantes': null,
          },
        ],
        'total': 1,
        'page': 1,
        'taille': 25,
        'compteurs': <String, int>{'aFinir': 0, 'pret': 0, 'incomplet': 1},
        'jours': <int>[1],
        'heures': <int>[18],
        'fuseaux': <String>['Europe/Paris'],
        'total_sans_filtre': 1,
        'demandes_sans_filtre': 4,
      },
    );

    expect(page.lignes, hasLength(1));
    expect(page.lignes.single.public.name, 'adultes');
    expect(page.lignes.single.occurrences.single.heure, 18);
    expect(page.lignes.single.autresFuseaux.single.heure, 20);
    expect(page.lignes.single.minimum, isNull);
    expect(page.compteurs[EtatRegroupement.incomplet], 1);
    expect(page.demandesSansFiltre, 4);
  });

  test('fails closed on malformed server data', () {
    expect(
      () => pageRegroupementsDepuisJson(<String, dynamic>{
        'lignes': 'not a list',
      }),
      throwsFormatException,
    );
  });
}
