// POINT-DE-SEANCE (lot 6 de la charte ; directeur, 13/11/2026 : « le cahier me
// fatigue »). Le contrat du point de fin de seance et de l'historique des
// seances. Tout est decide par le serveur (migration 20261125000000) : qui est
// present, qui est tire, ce qui est acquis ou a renforcer, le delai de
// correction. L'ecran ne calcule rien.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// La reponse de l'enseignant pour un eleve present.
enum ReponsePoint {
  /// Le defaut d'un present : aucun toucher.
  aSuivi('a_suivi'),

  /// Le toucher de l'enseignant.
  aRenforcer('a_renforcer'),

  /// Reserve a l'eleve tire.
  acquis('acquis'),

  /// La sortie honnete pour l'eleve tire : « Pas eu le temps de l'ecouter ».
  pasEcoute('pas_ecoute');

  const ReponsePoint(this.code);

  /// Le code du serveur.
  final String code;

  /// La reponse de code [code], ou nulle.
  static ReponsePoint? depuis(Object? code) {
    for (final ReponsePoint r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// La presence mesuree par le serveur.
enum PresencePoint {
  /// Present pour au moins la moitie du cours.
  presente,

  /// Present en partie.
  partielle,

  /// Aucune connexion.
  absente,

  /// Pas encore connue : jamais une absence.
  inconnue;

  /// La presence de code [code].
  static PresencePoint depuis(Object? code) => switch (code) {
    'presente' => presente,
    'partielle' => partielle,
    'absente' => absente,
    _ => inconnue,
  };
}

/// Un eleve present, sur la page du point.
@immutable
class ElevePoint {
  /// Cree la ligne.
  const ElevePoint({
    required this.eleveId,
    required this.prenom,
    required this.tire,
    this.etape,
    this.reponse,
  });

  /// L'eleve.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Le nom de son etape, ou nul.
  final String? etape;

  /// C'est l'eleve tire : il n'a pas de defaut.
  final bool tire;

  /// La reponse en vigueur ; nulle pour l'eleve tire avant l'envoi.
  final ReponsePoint? reponse;
}

/// Un eleve de la seance qui ne figure pas au point (absent, present en
/// partie).
@immutable
class EleveHorsPoint {
  /// Cree la ligne.
  const EleveHorsPoint({required this.prenom, required this.presence});

  /// Son prenom.
  final String prenom;

  /// Sa presence mesuree.
  final PresencePoint presence;
}

/// La page du point de fin de seance, telle que le serveur la rend.
@immutable
class PointSeance {
  /// Cree la page.
  const PointSeance({
    required this.seanceId,
    required this.classe,
    required this.debut,
    required this.tenue,
    required this.envoye,
    required this.peutEnvoyer,
    required this.eleves,
    this.horsPoint = const <EleveHorsPoint>[],
    this.modifiableJusqua,
    this.note,
  });

  /// La seance.
  final String seanceId;

  /// Le nom de la Classe.
  final String classe;

  /// Le debut de la seance.
  final DateTime debut;

  /// La seance est tenue : le point peut se faire.
  final bool tenue;

  /// Le point est deja envoye.
  final bool envoye;

  /// La personne connectee peut envoyer ou corriger (decide par le serveur).
  final bool peutEnvoyer;

  /// Les presents, l'eleve tire en tete.
  final List<ElevePoint> eleves;

  /// Les absents et les presents en partie.
  final List<EleveHorsPoint> horsPoint;

  /// La fin du delai de correction d'un point envoye.
  final DateTime? modifiableJusqua;

  /// La note facultative (enseignant et direction).
  final String? note;

  /// Lit la reponse du serveur ; nulle si elle n'a pas la forme attendue.
  static PointSeance? depuisLecture(Object? lecture) {
    if (lecture is! Map) return null;
    final DateTime? debut = DateTime.tryParse('${lecture['debut']}');
    final Object? id = lecture['session_id'];
    if (debut == null || id is! String) return null;
    return PointSeance(
      seanceId: id,
      classe: lecture['classe'] as String? ?? '',
      debut: debut.toLocal(),
      tenue: lecture['tenue'] == true,
      envoye: lecture['envoye'] == true,
      peutEnvoyer: lecture['peut_envoyer'] == true,
      modifiableJusqua: DateTime.tryParse('${lecture['modifiable_jusqua']}')
          ?.toLocal(),
      note: lecture['note'] as String?,
      eleves: <ElevePoint>[
        for (final Object? e in lecture['eleves'] as List<Object?>? ?? const [])
          if (e is Map && e['student_id'] is String)
            ElevePoint(
              eleveId: e['student_id'] as String,
              prenom: e['prenom'] as String? ?? '',
              etape: e['etape'] as String?,
              tire: e['tire'] == true,
              reponse: ReponsePoint.depuis(e['reponse']),
            ),
      ],
      horsPoint: <EleveHorsPoint>[
        for (final Object? e
            in lecture['hors_point'] as List<Object?>? ?? const [])
          if (e is Map)
            EleveHorsPoint(
              prenom: e['prenom'] as String? ?? '',
              presence: PresencePoint.depuis(e['presence']),
            ),
      ],
    );
  }
}

/// Une seance tenue qui attend son point.
@immutable
class PointAFaire {
  /// Cree la ligne.
  const PointAFaire({
    required this.seanceId,
    required this.classe,
    required this.debut,
  });

  /// La seance.
  final String seanceId;

  /// Le nom de la Classe.
  final String classe;

  /// Le debut de la seance.
  final DateTime debut;
}

/// Pourquoi le serveur a refuse un envoi. Chaque cas a sa phrase, qui dit quoi
/// faire.
enum RefusPoint {
  /// L'eleve tire n'a pas de reponse.
  eleveTireSansReponse,

  /// Le delai de correction est passe.
  delaiDepasse,

  /// La seance n'est pas encore tenue.
  seanceNonTenue,

  /// La liste des presents a change depuis l'ouverture de la page.
  presentsChanges,

  /// Personne n'etait present.
  aucunPresent,

  /// La personne connectee n'est pas l'enseignant de la seance.
  refuse,

  /// Le serveur n'a pas repondu.
  reseau,
}

/// Un envoi refuse.
class EchecPointSeance implements Exception {
  /// Cree l'echec.
  const EchecPointSeance(this.refus);

  /// Le motif.
  final RefusPoint refus;

  @override
  String toString() => 'EchecPointSeance(${refus.name})';
}

/// Le travail que le serveur deduit du dernier point.
enum TravailPoint {
  /// Relire ce qui a ete vu.
  relire,

  /// Le travail cible, apres un « A renforcer ».
  cible;

  /// Le travail de code [code], ou nul.
  static TravailPoint? depuis(Object? code) => switch (code) {
    'relire' => relire,
    'cible' => cible,
    _ => null,
  };
}

/// Une seance passee d'un eleve, ecrite par le systeme.
@immutable
class SeancePassee {
  /// Cree la ligne.
  const SeancePassee({
    required this.seanceId,
    required this.debut,
    required this.presence,
    this.reponse,
    this.travail,
    this.tire = false,
    this.note,
  });

  /// La seance.
  final String seanceId;

  /// Son debut.
  final DateTime debut;

  /// La presence mesuree.
  final PresencePoint presence;

  /// La reponse du point ; nulle sans point, ou pour un absent.
  final ReponsePoint? reponse;

  /// Le travail qui en decoule.
  final TravailPoint? travail;

  /// L'eleve etait tire (enseignant et direction seulement).
  final bool tire;

  /// La note de l'enseignant (enseignant et direction seulement).
  final String? note;
}

/// L'historique des seances d'un eleve et ce que le serveur en deduit.
@immutable
class HistoriqueSeances {
  /// Cree l'historique.
  const HistoriqueSeances({
    required this.seances,
    this.etape,
    this.points = 0,
    this.acquis = 0,
    this.aRenforcer = false,
    this.aRenforcerDepuis,
    this.travail,
    this.deuxDeSuite = false,
  });

  /// Les seances, la plus recente d'abord.
  final List<SeancePassee> seances;

  /// Le nom de l'etape en cours.
  final String? etape;

  /// Le nombre de points de fin de seance sur l'etape en cours.
  final int points;

  /// Le nombre d'observations « Acquis » retenues par le serveur.
  final int acquis;

  /// Le dernier point de l'eleve dit « A renforcer ».
  final bool aRenforcer;

  /// Le cours ou ce « A renforcer » a ete note.
  final DateTime? aRenforcerDepuis;

  /// Le travail avant le prochain cours.
  final TravailPoint? travail;

  /// Deux « A renforcer » de suite (enseignant et direction seulement).
  final bool deuxDeSuite;

  /// Lit la reponse du serveur ; nulle si elle n'a pas la forme attendue.
  static HistoriqueSeances? depuisLecture(Object? lecture) {
    if (lecture is! Map) return null;
    final Object? s = lecture['synthese'];
    final Map<Object?, Object?> synthese = s is Map ? s : const {};
    return HistoriqueSeances(
      etape: synthese['etape'] as String?,
      points: (synthese['points'] as num?)?.toInt() ?? 0,
      acquis: (synthese['acquis'] as num?)?.toInt() ?? 0,
      aRenforcer: synthese['a_renforcer'] == true,
      aRenforcerDepuis: DateTime.tryParse('${synthese['a_renforcer_depuis']}')
          ?.toLocal(),
      travail: TravailPoint.depuis(synthese['travail']),
      deuxDeSuite: synthese['deux_de_suite'] == true,
      seances: <SeancePassee>[
        for (final Object? e
            in lecture['seances'] as List<Object?>? ?? const [])
          if (e is Map && DateTime.tryParse('${e['debut']}') != null)
            SeancePassee(
              seanceId: '${e['session_id']}',
              debut: DateTime.parse('${e['debut']}').toLocal(),
              presence: PresencePoint.depuis(e['presence']),
              reponse: ReponsePoint.depuis(e['reponse']),
              travail: TravailPoint.depuis(e['travail']),
              tire: e['tire'] == true,
              note: e['note'] as String?,
            ),
      ],
    );
  }
}

/// Le point de fin de seance et l'historique des seances.
abstract interface class PortPointSeance {
  /// La page du point de [seanceId].
  Future<PointSeance?> lire(String seanceId);

  /// Envoie le point (ou le corrige pendant le delai). Leve
  /// [EchecPointSeance] quand le serveur refuse.
  Future<PointSeance?> envoyer(
    String seanceId,
    Map<String, ReponsePoint> reponses, {
    String? note,
  });

  /// Les seances tenues de l'enseignant qui attendent leur point.
  Future<List<PointAFaire>> aFaire();

  /// L'historique des seances de [eleveId].
  Future<HistoriqueSeances?> historique(String eleveId);
}

/// Le port : absent tant que `main.dart` ne le pose pas.
final Provider<PortPointSeance?> portPointSeanceProvider =
    Provider<PortPointSeance?>((Ref _) => null);

/// La page du point d'une seance.
final FutureProviderFamily<PointSeance?, String> pointSeanceProvider =
    FutureProvider.family<PointSeance?, String>((Ref ref, String seanceId) {
      final PortPointSeance? port = ref.watch(portPointSeanceProvider);
      if (port == null) return Future<PointSeance?>.value();
      return port.lire(seanceId);
    }, retry: (int _, Object _) => null);

/// Les points a faire de l'enseignant connecte ; vide sans port.
final FutureProvider<List<PointAFaire>> pointsAFaireProvider =
    FutureProvider<List<PointAFaire>>((Ref ref) {
      final PortPointSeance? port = ref.watch(portPointSeanceProvider);
      if (port == null) {
        return Future<List<PointAFaire>>.value(const <PointAFaire>[]);
      }
      return port.aFaire();
    }, retry: (int _, Object _) => null);

/// L'historique des seances d'un eleve ; `null` sans port.
final FutureProviderFamily<HistoriqueSeances?, String>
historiqueSeancesProvider = FutureProvider.family<HistoriqueSeances?, String>((
  Ref ref,
  String eleveId,
) {
  final PortPointSeance? port = ref.watch(portPointSeanceProvider);
  if (port == null) return Future<HistoriqueSeances?>.value();
  return port.historique(eleveId);
}, retry: (int _, Object _) => null);
