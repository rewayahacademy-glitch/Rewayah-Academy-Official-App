// N3, S2 : la lecture des reponses des fonctions `pause_*` du serveur.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_supabase.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';

void main() {
  group('N3 S2 : reglage', () {
    test('lit le reglage et sa version opaque', () {
      final ReglagePause r = reglageDepuis(<String, dynamic>{
        'actif': true,
        'apres_minutes': 30,
        'duree_minutes': 10,
        'version': '3',
        'peut_modifier': true,
      });
      expect(r.actif, isTrue);
      expect(r.apresMinutes, 30);
      expect(r.dureeMinutes, 10);
      expect(r.version, '3');
      expect(r.peutModifier, isTrue);
    });

    test('sans reglage enregistre : version 0, rien a modifier pour la '
        'direction', () {
      final ReglagePause r = reglageDepuis(<String, dynamic>{
        'actif': false,
        'apres_minutes': 15,
        'duree_minutes': 5,
        'version': '0',
        'peut_modifier': false,
      });
      expect(r.version, '0');
      expect(r.peutModifier, isFalse);
    });

    test('une valeur hors bornes est refusee, jamais une assertion', () {
      expect(
        () => reglageDepuis(<String, dynamic>{
          'actif': true,
          'apres_minutes': 3,
          'duree_minutes': 5,
          'version': '1',
        }),
        throwsFormatException,
      );
    });
  });

  group('N3 S2 : etat de la pause', () {
    test('non prevue', () {
      expect(
        pauseDepuis(<String, dynamic>{
          'statut': 'non_prevue',
          'duree_prevue_minutes': 5,
          'peut_piloter': true,
        }),
        const PauseSeance.nonPrevue(),
      );
    });

    test('en cours : horodatages du serveur, en UTC', () {
      final PauseSeance p = pauseDepuis(<String, dynamic>{
        'statut': 'en_cours',
        'duree_prevue_minutes': 10,
        'debut_prevu_utc': '2026-11-03T14:30:00+00:00',
        'debut_utc': '2026-11-03T14:31:00+00:00',
        'fin_utc': null,
        'peut_piloter': true,
      });
      expect(p.statut, StatutPause.enCours);
      expect(p.debutUtc, DateTime.utc(2026, 11, 3, 14, 31));
      expect(p.repriseUtc, DateTime.utc(2026, 11, 3, 14, 41));
      expect(p.peutPiloter, isTrue);
    });

    test('statut inconnu : refuse', () {
      expect(
        () => pauseDepuis(<String, dynamic>{'statut': 'autre'}),
        throwsFormatException,
      );
    });
  });
}
