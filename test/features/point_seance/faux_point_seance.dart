// POINT-DE-SEANCE : un faux port pour les tests et les captures.

import 'package:rewayah_academy/core/point_seance/port_point_seance.dart';

/// La page d'un point a faire : Aicha tiree, Bilal et Chams « A suivi »,
/// Dalia absente.
Map<String, Object?> pointAFaireBrut({bool envoye = false}) =>
    <String, Object?>{
      'session_id': 's1',
      'groupe_id': 'g1',
      'classe': 'An-Nour',
      'debut': '2026-11-12T17:00:00Z',
      'fin': '2026-11-12T18:00:00Z',
      'tenue': true,
      'envoye': envoye,
      'peut_envoyer': true,
      'modifiable_jusqua': envoye ? '2026-11-13T18:05:00Z' : null,
      'eleve_tire': 'e1',
      'note': envoye ? 'Bilal confond ba et ta.' : null,
      'eleves': <Object?>[
        <String, Object?>{
          'student_id': 'e1',
          'prenom': 'Aïcha',
          'etape': 'Les lettres',
          'tire': true,
          'reponse': envoye ? 'acquis' : null,
        },
        <String, Object?>{
          'student_id': 'e2',
          'prenom': 'Bilal',
          'etape': 'Les lettres',
          'tire': false,
          'reponse': envoye ? 'a_renforcer' : 'a_suivi',
        },
        <String, Object?>{
          'student_id': 'e3',
          'prenom': 'Chams',
          'etape': 'Les voyelles',
          'tire': false,
          'reponse': 'a_suivi',
        },
      ],
      'hors_point': <Object?>[
        <String, Object?>{
          'student_id': 'e4',
          'prenom': 'Dalia',
          'presence': 'absente',
        },
      ],
    };

/// L'historique d'un eleve « A renforcer » ; [academie] : avec la note, le
/// tirage et « deux de suite » (enseignant, direction).
Map<String, Object?> historiqueBrut({bool academie = false}) =>
    <String, Object?>{
      'eleve_id': 'e2',
      'lecteur': academie ? 'academie' : 'famille',
      'synthese': <String, Object?>{
        'etape': 'Les lettres',
        'points': 4,
        'acquis': 2,
        'a_renforcer': true,
        'a_renforcer_depuis': '2026-11-12T17:00:00Z',
        'travail': 'cible',
        if (academie) 'deux_de_suite': true,
      },
      'seances': <Object?>[
        <String, Object?>{
          'session_id': 's4',
          'debut': '2026-11-12T17:00:00Z',
          'presence': 'presente',
          'point': true,
          'reponse': 'a_renforcer',
          'travail': 'cible',
          if (academie) 'tire': true,
          if (academie) 'note': 'Bilal confond ba et ta.',
        },
        <String, Object?>{
          'session_id': 's3',
          'debut': '2026-11-10T17:00:00Z',
          'presence': 'absente',
          'point': true,
        },
        <String, Object?>{
          'session_id': 's2',
          'debut': '2026-11-07T17:00:00Z',
          'presence': 'presente',
          'point': true,
          'reponse': 'a_renforcer',
          'travail': 'cible',
        },
        <String, Object?>{
          'session_id': 's1',
          'debut': '2026-11-05T17:00:00Z',
          'presence': 'presente',
          'point': true,
          'reponse': 'a_suivi',
          'travail': 'relire',
        },
      ],
    };

/// Un faux port : rend ce qu'on lui donne, garde ce qu'on lui envoie.
class FauxPointSeance implements PortPointSeance {
  /// Cree le faux.
  FauxPointSeance({
    this.point,
    this.historiqueRendu,
    this.aFaireRendus = const <PointAFaire>[],
    this.erreurLecture = false,
    this.refus,
  });

  /// La page rendue (brute, comme le serveur).
  Map<String, Object?>? point;

  /// L'historique rendu (brut) ; nul : le serveur ne l'ouvre pas.
  Map<String, Object?>? historiqueRendu;

  /// Les points a faire.
  List<PointAFaire> aFaireRendus;

  /// La lecture echoue.
  bool erreurLecture;

  /// Le refus leve a l'envoi.
  RefusPoint? refus;

  /// Les envois recus.
  final List<Map<String, ReponsePoint>> envois = <Map<String, ReponsePoint>>[];

  /// Les notes recues.
  final List<String?> notes = <String?>[];

  @override
  Future<PointSeance?> lire(String seanceId) async {
    if (erreurLecture) throw StateError('lecture');
    return PointSeance.depuisLecture(point);
  }

  @override
  Future<PointSeance?> envoyer(
    String seanceId,
    Map<String, ReponsePoint> reponses, {
    String? note,
  }) async {
    if (refus != null) throw EchecPointSeance(refus!);
    envois.add(Map<String, ReponsePoint>.of(reponses));
    notes.add(note);
    point = pointAFaireBrut(envoye: true);
    return PointSeance.depuisLecture(point);
  }

  @override
  Future<List<PointAFaire>> aFaire() async => aFaireRendus;

  @override
  Future<HistoriqueSeances?> historique(String eleveId) async {
    if (erreurLecture) throw StateError('lecture');
    return HistoriqueSeances.depuisLecture(historiqueRendu);
  }
}
