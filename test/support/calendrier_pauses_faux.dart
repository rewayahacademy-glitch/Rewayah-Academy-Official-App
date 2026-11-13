// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : les doubles des ports du calendrier
// et des pauses, et les reponses du serveur dans leur forme exacte (celle des
// fonctions de la migration 20261123910000). Aucun Supabase.

import 'dart:async';

import 'package:rewayah_academy/core/calendrier/port_calendrier.dart';

/// Une ligne de `calendrier_ecole_liste`.
Map<String, Object?> ligneCalendrier({
  required String id,
  required String type,
  required String titre,
  required String du,
  required String au,
  String? categorie,
  String portee = 'ecole',
  String? cohorte,
  String? groupeId,
  String? groupeLibelle,
  bool publie = false,
  int? elevesVises,
  int? seancesDejaPrevues,
}) => <String, Object?>{
  'id': id,
  'type': type,
  'categorie': categorie,
  'titre': titre,
  'du': du,
  'au': au,
  'jours': DateTime.parse(au).difference(DateTime.parse(du)).inDays + 1,
  'portee': portee,
  'cohorte': cohorte,
  'groupe_id': groupeId,
  'groupe_libelle': groupeLibelle,
  'publie': publie,
  'publie_le': publie ? '2026-11-01T08:00:00+00:00' : null,
  'eleves_vises': elevesVises,
  'seances_deja_prevues': seancesDejaPrevues,
};

/// Le calendrier de l'ecole : une fermeture publiee qui vise 5 eleves et a
/// 4 seances deja prevues, une rencontre non publiee, une evaluation de
/// tranche.
List<Object?> calendrierServeur() => <Object?>[
  ligneCalendrier(
    id: 'c1',
    type: 'fermeture',
    categorie: 'aid_al_adha',
    titre: "Fermeture de l'Aïd al-Adha",
    du: '2027-05-16',
    au: '2027-05-25',
    publie: true,
    elevesVises: 5,
    seancesDejaPrevues: 4,
  ),
  ligneCalendrier(
    id: 'c2',
    type: 'rencontre',
    titre: 'Rencontre de récitation de printemps',
    du: '2027-04-10',
    au: '2027-04-10',
  ),
  ligneCalendrier(
    id: 'c3',
    type: 'evaluation',
    titre: 'Évaluation des 10-13 ans',
    du: '2027-03-06',
    au: '2027-03-06',
    portee: 'tranche',
    cohorte: 'enfant_10_13',
    publie: true,
  ),
];

/// Le calendrier de la direction en memoire.
class FauxCalendrierDirection implements PortCalendrierDirection {
  FauxCalendrierDirection({this.lignes, this.erreur, this.attente, this.refus});

  Object? Function()? lignes;
  Object? erreur;
  Completer<void>? attente;
  CalendrierRefuse? refus;

  final List<Map<String, Object?>> enregistrements = <Map<String, Object?>>[];
  final List<(String, bool)> publications = <(String, bool)>[];

  @override
  Future<List<EvenementCalendrier>> lister() async {
    if (attente case final Completer<void> c) await c.future;
    if (erreur case final Object e) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return evenementsDepuisJson((lignes ?? calendrierServeur)());
  }

  @override
  Future<String> enregistrer({
    required TypeEvenement type,
    required String titre,
    required DateTime du,
    required DateTime au,
    required PorteeEvenement portee,
    String? id,
    CategorieFermeture? categorie,
    String? cohorte,
    String? groupeId,
  }) async {
    if (refus != null) throw refus!;
    enregistrements.add(<String, Object?>{
      'id': id,
      'type': type,
      'categorie': categorie,
      'titre': titre,
      'du': du,
      'au': au,
      'portee': portee,
      'cohorte': cohorte,
      'groupeId': groupeId,
    });
    return id ?? 'nouveau';
  }

  @override
  Future<void> publier(String id, {required bool publie}) async {
    if (refus != null) throw refus!;
    publications.add((id, publie));
  }
}

/// La reponse de `pauses_eleve_lecture` pour un eleve : le serveur dit la
/// regle (7 jours, 2 mois sur 12, 3 jours de reponse), douze mois proposes
/// (les [aLaDirection] vont a la direction), et les pauses.
Map<String, Object?> lecturePausesServeur({
  String? prenom = 'Mariam',
  List<Object?> pauses = const <Object?>[],
  int moisAccordes = 0,
  Set<int> aLaDirection = const <int>{},
  Map<int, String> etats = const <int, String>{},
}) => <String, Object?>{
  'eleve_id': 'eleve-mariam',
  'prenom': prenom,
  'aujourdhui': '2026-11-12',
  'regle': <String, Object?>{
    'preavis_jours': 7,
    'plafond_mois': 2,
    'fenetre_mois': 12,
    'delai_reponse_jours': 3,
  },
  'mois_accordes': moisAccordes,
  'mois_proposes': <Object?>[
    for (int k = 0; k < 12; k++)
      <String, Object?>{
        'mois': DateTime(2026, 12 + k).toIso8601String().substring(0, 10),
        'a_la_direction': aLaDirection.contains(k),
        'etat': etats[k],
      },
  ],
  'pauses': pauses,
};

/// Une pause de la lecture.
Map<String, Object?> pauseServeur({
  required String id,
  required String statut,
  String type = 'mois',
  String debut = '2027-01-01',
  String fin = '2027-01-31',
  bool annulable = false,
  String? repondreAvant,
  String? motifDecision,
}) => <String, Object?>{
  'id': id,
  'type': type,
  'debut': debut,
  'fin': fin,
  'statut': statut,
  'demandee_le': '2026-11-12T09:00:00+00:00',
  'repondre_avant': repondreAvant,
  'decidee_le': motifDecision == null ? null : '2026-11-13T09:00:00+00:00',
  'motif_decision': motifDecision,
  'annulable': annulable,
};

/// La reponse de `pauses_a_traiter`.
Map<String, Object?> fileServeur({bool vide = false}) => <String, Object?>{
  'a_traiter': vide
      ? <Object?>[]
      : <Object?>[
          <String, Object?>{
            'id': 'p1',
            'eleve_id': 'eleve-mariam',
            'eleve_nom': 'Mariam Benali',
            'cohorte': 'enfant_10_13',
            'debut': '2027-02-01',
            'fin': '2027-02-28',
            'demandee_le': '2026-11-12T09:00:00+00:00',
            'repondre_avant': '2026-11-15',
            'en_retard': false,
            'mois_accordes': 2,
          },
          <String, Object?>{
            'id': 'p2',
            'eleve_id': 'eleve-yasmine',
            'eleve_nom': 'Yasmine Haddad',
            'cohorte': 'adulte_18_plus',
            'debut': '2027-03-01',
            'fin': '2027-03-31',
            'demandee_le': '2026-11-01T09:00:00+00:00',
            'repondre_avant': '2026-11-04',
            'en_retard': true,
            'mois_accordes': 2,
          },
        ],
  'recentes': vide
      ? <Object?>[]
      : <Object?>[
          <String, Object?>{
            'id': 'r1',
            'eleve_id': 'eleve-omar',
            'eleve_nom': 'Omar Saidi',
            'type': 'exception',
            'debut': '2026-11-10',
            'fin': '2026-11-20',
            'statut': 'acceptee',
            'motif': 'Maladie soudaine',
            'motif_decision': null,
            'decidee_par_nom': 'Direction Rewayah',
            'decidee_le': '2026-11-10T08:00:00+00:00',
          },
        ],
};

/// Les pauses en memoire.
class FausPauses implements PortPauses {
  FausPauses({
    Object? lecture,
    Object? file,
    this.erreurLecture,
    this.attente,
    this.refusDemande,
    this.refusDecision,
    this.reponseDemande,
    this.trouves,
  }) : lectureBrute = lecture ?? lecturePausesServeur(),
       fileBrute = file ?? fileServeur();

  Object? lectureBrute;
  Object? fileBrute;
  Object? erreurLecture;
  Completer<void>? attente;
  PauseRefusee? refusDemande;
  PauseRefusee? refusDecision;
  Map<String, Object?>? reponseDemande;
  List<EleveTrouve>? trouves;

  final List<(String, DateTime)> demandes = <(String, DateTime)>[];
  final List<String> annulees = <String>[];
  final List<(String, bool, String?)> decisions = <(String, bool, String?)>[];
  final List<(String, DateTime, String)> exceptions =
      <(String, DateTime, String)>[];
  final List<String> lues = <String>[];
  final List<String> recherches = <String>[];

  @override
  Future<LecturePauses?> lecture(String eleveId) async {
    lues.add(eleveId);
    if (attente case final Completer<void> c) await c.future;
    if (erreurLecture case final Object e) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return LecturePauses.depuisJson(lectureBrute);
  }

  @override
  Future<ReponseDemandePause> demander(String eleveId, DateTime mois) async {
    if (refusDemande != null) throw refusDemande!;
    demandes.add((eleveId, mois));
    return ReponseDemandePause.depuisJson(
      reponseDemande ??
          <String, Object?>{
            'id': 'nouvelle',
            'statut': 'acceptee',
            'debut': '${mois.year}-${mois.month.toString().padLeft(2, '0')}-01',
            'fin': '${mois.year}-${mois.month.toString().padLeft(2, '0')}-28',
            'repondre_avant': null,
          },
    )!;
  }

  @override
  Future<void> annuler(String pauseId) async => annulees.add(pauseId);

  @override
  Future<FilePauses> file() async {
    if (attente case final Completer<void> c) await c.future;
    if (erreurLecture case final Object e) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return FilePauses.depuisJson(fileBrute);
  }

  @override
  Future<void> decider(
    String pauseId, {
    required bool accepter,
    String? motif,
  }) async {
    if (refusDecision != null) throw refusDecision!;
    decisions.add((pauseId, accepter, motif));
  }

  @override
  Future<void> accorderException({
    required String eleveId,
    required DateTime fin,
    required String motif,
  }) async {
    if (refusDecision != null) throw refusDecision!;
    exceptions.add((eleveId, fin, motif));
  }

  @override
  Future<List<EleveTrouve>> rechercherEleves(String recherche) async {
    recherches.add(recherche);
    return trouves ??
        const <EleveTrouve>[
          EleveTrouve(
            id: 'eleve-omar',
            nom: 'Omar Saidi',
            cohorte: 'enfant_10_13',
          ),
        ];
  }
}
