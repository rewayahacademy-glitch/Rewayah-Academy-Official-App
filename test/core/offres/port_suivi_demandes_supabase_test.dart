import 'package:flutter_test/flutter_test.dart';

import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes_supabase.dart';

void main() {
  group('decodeSuiviDemandes', () {
    test(
      'keeps the hour of every day and exposes an assigned teacher only',
      () {
        final List<SuiviDemande> demandes = decodeSuiviDemandes(<dynamic>[
          <String, dynamic>{
            'demande_id': 'd-1',
            'eleve_id': 'e-1',
            'prenom': 'Nour',
            'etat': 'enseignant_affecte',
            'jours': <int>[3, 1],
            'heures_locales': <int>[19, 18],
            'fuseau_iana': 'Europe/Paris',
            'personnalisee': true,
            'enseignant': 'Sayyida Maryam',
            'debut_cours_local': '2026-10-12T18:30:00',
            'motif': null,
            'peut_choisir_autre_creneau': false,
          },
        ]);

        expect(demandes, hasLength(1));
        final SuiviDemande demande = demandes.single;
        expect(demande.etape, EtapeDemande.enseignantAffecte);
        expect(demande.creneau.joursIso, <int>[1, 3]);
        expect(demande.creneau.occurrences[0].heure, 18);
        expect(demande.creneau.occurrences[1].heure, 19);
        expect(demande.enseignant, 'Sayyida Maryam');
        expect(demande.debutCours?.isUtc, isFalse);
        expect(demande.debutCours?.hour, 18);
      },
    );

    test(
      'does not leak a teacher before assignment and uses a neutral close',
      () {
        final SuiviDemande demande = decodeSuiviDemandes(<dynamic>[
          <String, dynamic>{
            'demande_id': 'd-2',
            'eleve_id': 'e-2',
            'prenom': 'Adam',
            'etat': 'retiree',
            'jours': <int>[5],
            'heures_locales': <int>[17],
            'fuseau_iana': 'Europe/Paris',
            'personnalisee': false,
            'enseignant': 'Sayid Hidden',
            'debut_cours_local': '2026-10-16T17:00:00',
            'motif': null,
            'peut_choisir_autre_creneau': true,
          },
        ]).single;

        expect(demande.etape, EtapeDemande.close);
        expect(demande.enseignant, isNull);
        expect(demande.debutCours, isNull);
        expect(demande.motif, MotifCloture.inconnu);
        expect(demande.peutChoisirAutreCreneau, isTrue);
      },
    );

    test('rejects malformed parallel day/hour arrays', () {
      expect(
        () => decodeSuiviDemandes(<dynamic>[
          <String, dynamic>{
            'demande_id': 'd-3',
            'eleve_id': 'e-3',
            'prenom': 'Lina',
            'etat': 'envoyee',
            'jours': <int>[1, 3],
            'heures_locales': <int>[18],
            'fuseau_iana': 'Europe/Paris',
          },
        ]),
        throwsFormatException,
      );
    });
  });
}
