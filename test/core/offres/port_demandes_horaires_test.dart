import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/port_demandes_horaires.dart';

void main() {
  group('DemandeHoraireFamille', () {
    test(
      'lit une étape connue et conserve le motif sans données de regroupement',
      () {
        final DemandeHoraireFamille demande = DemandeHoraireFamille.depuisJson(
          <String, dynamic>{
            'id': 'd-1',
            'etat': 'refusee',
            'prochaine_etape': 'choisir_autre_horaire',
            'motif': 'Créneau indisponible',
            'updated_at': '2026-10-09T20:00:00Z',
          },
        );

        expect(demande.etat, EtatDemandeHoraire.refusee);
        expect(demande.prochaineEtape, 'choisir_autre_horaire');
        expect(demande.motif, 'Créneau indisponible');
        expect(demande.updatedAt.isUtc, isTrue);
      },
    );

    test('échoue fermé sur un état serveur inconnu', () {
      expect(
        () => EtatDemandeHoraire.depuisSql('offre_publiee'),
        throwsFormatException,
      );
    });
  });

  test('lit le regroupement sans identité familiale', () {
    final RegroupementDemandesHoraires regroupement =
        RegroupementDemandesHoraires.depuisJson(<String, dynamic>{
          'regroupement_id': 'a1b2',
          'type_public': 'adulte',
          'langue_code': 'francais',
          'fuseau_iana': 'Europe/Paris',
          'jours': <int>[2, 4, 6],
          'heures_locales': <int>[18, 18, 18],
          'nombre_eleves': 6,
          'quota': 6,
          'pret': true,
        });

    expect(regroupement.pret, isTrue);
    expect(regroupement.nombreEleves, regroupement.quota);
  });
}
