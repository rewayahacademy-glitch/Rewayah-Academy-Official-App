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

  // FRISE-HEURE (08/11/2026) : la vue rend un timestamptz, que PostgREST
  // envoie avec un decalage. Avant le correctif, cet instant levait une
  // FormatException et la frise de la famille tombait en erreur.
  group('FRISE-HEURE : un instant avec decalage', () {
    List<FriseDemande> lire(Object? survenu, {Object? debut, Object? murale}) =>
        frisesDepuisDonnees(
          <dynamic>[
            <String, Object?>{
              'demande_id': 'd-1',
              'eleve_id': 'e-1',
              'prenom': 'Mina',
              'etape': 'envoyee',
              'motif': null,
              'fuseau_iana': 'Europe/Paris',
              'debut_cours': debut,
              'peut_choisir_autre_creneau': false,
            },
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{
              'demande_id': 'd-1',
              'type': 'envoyee',
              'motif_attente': null,
              'survenu_le_foyer': survenu,
              'survenu_le_murale': murale,
            },
          ],
        );

    test('la forme de PostgREST (+00:00) ne fait plus tomber la frise', () {
      expect(() => lire('2026-10-11T12:15:00+00:00'), returnsNormally);
    });

    test('la forme de PostgREST (+00:00) est lue : le jour seul', () {
      const String brut = '2026-10-11T12:15:00+00:00';
      final EtapeFrise envoyee = lire(brut).single.etapes.first;
      final DateTime jour = DateTime.parse(brut).toLocal();
      expect(envoyee.jourSeul, isTrue);
      expect(envoyee.quand, DateTime(jour.year, jour.month, jour.day));
      expect(envoyee.quand!.isUtc, isFalse);
    });

    test('la forme Z est lue de meme', () {
      final EtapeFrise envoyee = lire('2026-10-11T12:15:00Z')
          .single
          .etapes
          .first;
      expect(envoyee.jourSeul, isTrue);
      expect(envoyee.quand!.hour, 0);
    });

    test('une heure murale sans decalage garde le jour et l heure', () {
      final EtapeFrise envoyee = lire('2026-10-11T08:15:00')
          .single
          .etapes
          .first;
      expect(envoyee.jourSeul, isFalse);
      expect(envoyee.quand, DateTime(2026, 10, 11, 8, 15));
    });

    // FRISE-HEURE client (08/11/2026) : la vue rend aussi survenu_le_murale,
    // l'heure murale du foyer calculee par le serveur (migration
    // 20261121700000). Elle prime : l'heure revient dans la frise.
    test('survenu_le_murale prime : jour et heure du foyer', () {
      final EtapeFrise envoyee = lire(
        '2026-10-11T12:15:00+00:00',
        murale: '2026-10-11T14:15:00',
      ).single.etapes.first;
      expect(envoyee.jourSeul, isFalse);
      expect(envoyee.quand, DateTime(2026, 10, 11, 14, 15));
    });

    test('sans survenu_le_murale, l instant redonne le jour seul', () {
      final EtapeFrise envoyee = lire('2026-10-11T12:15:00+00:00')
          .single
          .etapes
          .first;
      expect(envoyee.jourSeul, isTrue);
    });

    test('une date illisible reste refusee', () {
      expect(() => lire('pas une date'), throwsFormatException);
      expect(() => lire(42), throwsFormatException);
    });
  });
}
