// N3, S2 : la lecture des reponses des fonctions `pause_*` du serveur.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_supabase.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

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

    test('PAUSE-SERVEUR : proposition, refus et motif lus du serveur', () {
      final PauseSeance p = pauseDepuis(<String, dynamic>{
        'statut': 'programmee',
        'duree_prevue_minutes': 10,
        'debut_prevu_utc': '2026-11-12T18:45:00+00:00',
        'proposer_a': '2026-11-12T18:50:00+00:00',
        'refus_nombre': 1,
        'motif': 'priere',
        'peut_piloter': true,
      });
      expect(p.proposerAUtc, DateTime.utc(2026, 11, 12, 18, 50));
      expect(p.refusNombre, 1);
      expect(p.motif, MotifPause.priere);
    });

    test('PAUSE-SERVEUR : serveur ancien, sans les champs : aucune '
        'proposition, zero refus, pause ordinaire', () {
      final PauseSeance p = pauseDepuis(<String, dynamic>{
        'statut': 'programmee',
        'duree_prevue_minutes': 10,
        'debut_prevu_utc': '2026-11-12T18:45:00+00:00',
        'peut_piloter': true,
      });
      expect(p.proposerAUtc, isNull);
      expect(p.refusNombre, 0);
      expect(p.motif, MotifPause.ordinaire);
    });

    test('PAUSE-SERVEUR : plus de proposition ; motif inconnu = ordinaire', () {
      final PauseSeance p = pauseDepuis(<String, dynamic>{
        'statut': 'programmee',
        'duree_prevue_minutes': 10,
        'debut_prevu_utc': '2026-11-12T18:45:00+00:00',
        'proposer_a': null,
        'refus_nombre': '3',
        'motif': 'autre',
      });
      expect(p.proposerAUtc, isNull);
      expect(p.refusNombre, 3);
      expect(p.motif, MotifPause.ordinaire);
    });

    test('PAUSE-SERVEUR : une pause en cours ne se propose plus', () {
      final PauseSeance p = pauseDepuis(<String, dynamic>{
        'statut': 'en_cours',
        'duree_prevue_minutes': 10,
        'debut_prevu_utc': '2026-11-12T18:45:00+00:00',
        'debut_utc': '2026-11-12T18:46:00+00:00',
        'proposer_a': '2026-11-12T18:45:00+00:00',
      });
      expect(p.proposerAUtc, isNull);
    });

    test('PAUSE-SERVEUR : fonction absente reconnue (PostgREST, Postgres)', () {
      expect(
        fonctionAbsente(
          const PostgrestException(message: '', code: 'PGRST202'),
        ),
        isTrue,
      );
      expect(
        fonctionAbsente(const PostgrestException(message: '', code: '42883')),
        isTrue,
      );
      expect(
        fonctionAbsente(const PostgrestException(message: '', code: '42501')),
        isFalse,
      );
    });

    test('statut inconnu : refuse', () {
      expect(
        () => pauseDepuis(<String, dynamic>{'statut': 'autre'}),
        throwsFormatException,
      );
    });
  });
}
