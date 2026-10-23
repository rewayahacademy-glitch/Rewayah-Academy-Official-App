// Le double du port de la direction, oracle des tests de widget d'`ADM-20`.
// Importe par aucune ligne de production (`CONTRAT_PORTS_CANDIDATURES.md`,
// section 6, premier double).
//
// Il rejoue ce que fait `lister_candidatures` (CAND-L1, redefinie par
// CAND-L2A2) : filtre sur les axes que le serveur connait, tri par derniere
// activite, date de reception ou nom, pages de 50, total reel du filtre,
// compteurs d'etapes sur toute la portee, deux alertes servies et deux non
// servies (`NULL`). Aucune regle metier de plus : un test qui veut un refus
// le programme.

import 'dart:async';

import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';

/// Les capacites d'une direction qui decide, du cote de son genre.
const CapacitesCandidatures capacitesQuiDecide = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
  peutDecider: true,
  gestes: <String, bool>{'agirEnLot': true},
);

/// Les capacites d'une direction qui lit seulement.
const CapacitesCandidatures capacitesQuiLit = CapacitesCandidatures(
  peutLire: true,
  genreLecteurConnu: true,
);

/// Une ligne de test, avec des valeurs par defaut raisonnables.
LigneCandidature ligneTest({
  String id = 'c1',
  String? reference,
  String nom = 'Amina Diallo',
  EtapeCandidature? etape = EtapeCandidature.prequalification,
  EtatCandidature? etat = EtatCandidature.enExamen,
  IssueCandidature issue = IssueCandidature.enCours,
  bool enPause = false,
  DateTime? repriseLe,
  bool restreinte = false,
  bool indisponible = false,
  DateTime? indisponibleJusquAu,
  EtatVersement paiement = EtatVersement.compatible,
  String? paysResidence = 'SN',
  bool courrielAObtenir = false,
  bool indicatifAConfirmer = false,
  DateTime? derniereActivite,
  DateTime? recueLe,
}) => LigneCandidature(
  id: id,
  reference: reference ?? 'CAND-${id.toUpperCase().padLeft(6, '0')}',
  nomComplet: nom,
  type: 'enseignant',
  etape: etape,
  etat: etat,
  issue: issue,
  enPause: enPause,
  repriseLe: repriseLe,
  restreinte: restreinte,
  indisponible: indisponible,
  indisponibleJusquAu: indisponibleJusquAu,
  paiement: paiement,
  paysResidence: paysResidence,
  courrielAObtenir: courrielAObtenir,
  indicatifAConfirmer: indicatifAConfirmer,
  derniereActivite: derniereActivite ?? DateTime.utc(2026, 10, 20, 9),
  recueLe: recueLe ?? DateTime.utc(2026, 10, 1, 9),
);

/// [n] lignes distinctes, reparties sur les cinq etapes, la derniere activite
/// decroissante avec le numero.
List<LigneCandidature> lignesEnMasse(int n) => <LigneCandidature>[
  for (int i = 0; i < n; i++)
    ligneTest(
      id: 'm$i',
      nom: 'Personne ${i.toString().padLeft(4, '0')}',
      etape: EtapeCandidature.values[i % EtapeCandidature.values.length],
      etat: switch (EtapeCandidature.values[i %
          EtapeCandidature.values.length]) {
        EtapeCandidature.prequalification => EtatCandidature.enExamen,
        EtapeCandidature.verifications => EtatCandidature.entretienAPlanifier,
        _ => null,
      },
      derniereActivite: DateTime.utc(
        2026,
        10,
        20,
      ).subtract(Duration(minutes: i)),
      recueLe: DateTime.utc(2026, 10, 1).add(Duration(minutes: i)),
    ),
];

/// Les reponses d'un candidat complet a `salle-examen-1`, avec des codes que
/// l'application sait dire.
Map<String, Object?> reponsesTest() => <String, Object?>{
  'langueMaternelle': 'poular',
  'languesExplication': <String>['francais', 'wo'],
  'niveauMemorisationDeclare': 'de_10_a_29_juz',
  'niveauLectureTajwid': 'tajwid_enseigne',
  'riwayat': <String>['hafs', 'warsh'],
  'ijazaPresentable': 'pret_test',
  'experienceDebutants': 'oui',
  'disponibilitesDeclarees': <Map<String, Object?>>[
    <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
    <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '21:00'},
  ],
  'fuseauIana': 'Africa/Dakar',
  'classesSouhaitees': '2',
  'debutPossible': 'mois_prochain',
  'publics': <String>['10_13', 'adultes'],
  'paysResidence': 'SN',
  'paysVersement': 'SN',
  'compteBancaire': true,
  'operateurs': <String>['orange_money'],
  'moyensAccessibles': <String>['wave'],
};

/// Un dossier de test, avec des valeurs par defaut raisonnables.
DetailCandidature detailTest({
  String id = 'c1',
  String? reference,
  String nom = 'Amina Diallo',
  EtapeCandidature? etape = EtapeCandidature.prequalification,
  EtatCandidature? etat = EtatCandidature.enExamen,
  IssueCandidature issue = IssueCandidature.enCours,
  bool enPause = false,
  DateTime? repriseLe,
  bool restreinte = false,
  String? restrictionCause,
  bool indisponible = false,
  EtatVersement paiement = EtatVersement.aVerifier,
  String? paysResidence = 'SN',
  String? responsableId,
  bool courrielAObtenir = false,
  bool indicatifAConfirmer = false,
  int version = 3,
  ProvenanceCandidature? provenance = ProvenanceCandidature.lienPublic,
  String? pauseModele,
  String? refusModele,
  List<DocumentReponses>? documents,
  List<ControleCandidature>? controles,
  EtatPiece? piece,
  ReponsesAutresCompetences? autresCompetences,
  DateTime? derniereActivite,
  DateTime? recueLe,
}) => DetailCandidature(
  ligne: LigneCandidature(
    id: id,
    reference: reference ?? 'CAND-${id.toUpperCase().padLeft(6, '0')}',
    nomComplet: nom,
    type: 'enseignant',
    etape: etape,
    etat: etat,
    issue: issue,
    enPause: enPause,
    repriseLe: repriseLe,
    restreinte: restreinte,
    indisponible: indisponible,
    paiement: paiement,
    paysResidence: paysResidence,
    responsableId: responsableId,
    courrielAObtenir: courrielAObtenir,
    indicatifAConfirmer: indicatifAConfirmer,
    derniereActivite: derniereActivite ?? DateTime.utc(2026, 10, 20, 9),
    recueLe: recueLe ?? DateTime.utc(2026, 10, 1, 9),
  ),
  version: version,
  provenance: provenance,
  pauseModele: pauseModele,
  refusModele: refusModele,
  restrictionCause: restrictionCause,
  documents:
      documents ??
      <DocumentReponses>[
        DocumentReponses(
          questionnaireVersion: 'salle-examen-1',
          reponses: reponsesTest(),
          importe: false,
          soumisLe: DateTime.utc(2026, 10, 18, 14),
        ),
      ],
  controles: controles,
  piece: piece,
  autresCompetences: autresCompetences,
);

/// Les capacites d'une direction qui decide et dont le serveur ouvre les
/// gestes de CAND-L2A2, avec leurs listes fermees.
const CapacitesCandidatures capacitesGestes = CapacitesCandidatures(
  peutLire: true,
  peutVoirContact: true,
  genreLecteurConnu: true,
  peutDecider: true,
  gestes: <String, bool>{
    'demanderComplement': true,
    'cloreComplement': true,
    'admettreVerifications': true,
    'confirmerMoyenPaiement': true,
    'infirmerMoyenPaiement': true,
    'mettreEnPause': true,
    'leverPause': true,
    'refuser': true,
    'consignerRetrait': true,
    'rouvrir': true,
    'definirResponsable': true,
    'agirEnLot': true,
  },
  listes: ListesGestes(
    modelesRefus: <String>[
      'refus_general',
      'refus_niveau',
      'refus_besoins',
      'refus_sans_reponse',
    ],
    modelesPause: <String>[
      'pause_attente_besoin',
      'pause_attente_informations',
      'pause_demande_candidat',
      'pause_general',
    ],
    complementSalleExamen: <String>[
      'langues',
      'recitation',
      'disponibilites',
      'publics',
      'versement',
      'cadre_religieux',
    ],
    complementSalleVerification: <String>[
      'piece_identite',
      'cadre_religieux',
      'contrat',
      'avis',
    ],
    canauxRetrait: <String>['conversation', 'courriel'],
    codesClotureComplement: <String>['complement_clos'],
  ),
);

/// Un evenement d'historique de test.
EvenementCandidature evenementTest({
  int id = 1,
  String type = 'transition',
  AuteurEvenement auteur = AuteurEvenement.direction,
  DateTime? quand,
  EtapeCandidature? etapeAvant,
  EtapeCandidature? etapeApres,
  EtatCandidature? etatAvant,
  EtatCandidature? etatApres,
  IssueCandidature? issueAvant,
  IssueCandidature? issueApres,
  String? motif,
}) => EvenementCandidature(
  id: id,
  type: type,
  auteur: auteur,
  quand: quand ?? DateTime.utc(2026, 10, 19, 10),
  etapeAvant: etapeAvant,
  etapeApres: etapeApres,
  etatAvant: etatAvant,
  etatApres: etatApres,
  issueAvant: issueAvant,
  issueApres: issueApres,
  motif: motif,
);

/// Un geste vu par le double, pour que le test dise ce qui est parti.
class AppelGeste {
  /// Cree la trace.
  const AppelGeste(this.demande);

  /// Ce qui est parti.
  final DemandeGeste demande;
}

/// Une requete lue par le double, pour que le test dise ce qui est parti au
/// serveur.
class AppelLister {
  /// Cree la trace.
  const AppelLister(this.filtre, this.tri, this.page);

  /// Le filtre envoye.
  final FiltreCandidatures filtre;

  /// Le tri envoye.
  final TriCandidatures tri;

  /// La page demandee.
  final int page;
}

/// Le port de la direction en memoire.
class FauxCandidaturesDirection implements PortCandidaturesDirection {
  /// Cree le double.
  FauxCandidaturesDirection({
    List<LigneCandidature> lignes = const <LigneCandidature>[],
    this.capacitesRendues = capacitesQuiLit,
    this.alertes,
    this.erreurCapacites,
    this.erreurLister,
    this.attente,
    this.taillePage = 50,
    List<DetailCandidature> details = const <DetailCandidature>[],
    this.contacts = const <String, ContactCandidat>{},
    this.historiques = const <String, List<EvenementCandidature>>{},
    this.responsables = const <ResponsablePossible>[],
    this.moyens = const <String, MoyensConfirmes>{},
    this.erreurLire,
    this.erreurContact,
    this.erreurHistorique,
    this.erreurGeste,
    this.attenteLire,
    this.effetGeste,
    this.responsablesIndisponibles = false,
    this.perteApresEcriture = false,
    this.erreurLot,
    this.refusParLigne = const <String, String>{},
  }) : lignes = List<LigneCandidature>.of(lignes),
       details = <String, DetailCandidature>{
         for (final DetailCandidature d in details) d.ligne.id: d,
       };

  /// Toute la portee du lecteur (le serveur borne par genre : ici, tout ce
  /// qu'on donne est dans la portee).
  final List<LigneCandidature> lignes;

  /// Ce que `capacites()` rend.
  CapacitesCandidatures capacitesRendues;

  /// Les compteurs d'alertes rendus. Nul : comme le serveur d'aujourd'hui, deux
  /// servis (informations manquantes, confirmees indisponibles) et deux non
  /// servis (`NULL`).
  CompteursAlertes? alertes;

  /// Ce que `capacites()` jette, ou `null`.
  Object? erreurCapacites;

  /// Ce que `lister()` jette, ou `null`. Une fonction : l'erreur peut changer
  /// d'un appel a l'autre (echec puis succes).
  Object? Function(int appel)? erreurLister;

  /// Tant que cette attente n'est pas terminee, `lister()` ne repond pas.
  Completer<void>? attente;

  /// Le nombre de lignes par page (50 au serveur).
  final int taillePage;

  /// Les dossiers que `lire` rend, par identifiant. Ils comptent aussi dans la
  /// portee de `lister`.
  final Map<String, DetailCandidature> details;

  /// Le contact de chaque candidature, par identifiant.
  final Map<String, ContactCandidat> contacts;

  /// L'historique de chaque candidature, par identifiant (le plus recent
  /// d'abord), servi par pages de deux evenements.
  final Map<String, List<EvenementCandidature>> historiques;

  /// Les responsables possibles.
  final List<ResponsablePossible> responsables;

  /// Les moyens confirmes, par pays.
  final Map<String, MoyensConfirmes> moyens;

  /// Ce que `lire()` jette, ou `null`. Une fonction : l'erreur peut changer
  /// d'un appel a l'autre.
  Object? Function(int appel)? erreurLire;

  /// Ce que `lireContact()` jette, ou `null`.
  Object? erreurContact;

  /// Ce que `historique()` jette, ou `null`.
  Object? erreurHistorique;

  /// Ce que `geste()` jette, ou `null`. Une fonction : l'erreur peut changer
  /// d'un essai a l'autre (non confirme, puis succes).
  Object? Function(DemandeGeste demande, int essai)? erreurGeste;

  /// Tant que cette attente n'est pas terminee, `lire()` ne repond pas.
  Completer<void>? attenteLire;

  /// L'effet d'un geste reussi sur le dossier : rend le dossier apres le
  /// geste. Sans lui, seule la version augmente.
  DetailCandidature Function(DemandeGeste demande, DetailCandidature avant)?
  effetGeste;

  /// Vrai : la liste des responsables n'est pas servie.
  bool responsablesIndisponibles;

  /// Vrai : quand `erreurGeste` rend [GesteNonConfirme], la demande est quand
  /// meme arrivee au serveur et ecrite ; seule la reponse est perdue. Rejouer
  /// la meme cle rend alors le premier resultat, sans ecrire une seconde fois.
  bool perteApresEcriture;

  /// Ce que `executerLot()` jette, ou `null`. Une fonction : l'erreur peut
  /// changer d'un essai a l'autre (non confirme, puis succes).
  Object? Function(DemandeLot demande, int essai)? erreurLot;

  /// Les candidatures dont le geste de lot est refuse par le serveur, avec le
  /// code du refus (`conflit_candidature`...) : un refus par ligne, sans
  /// annuler les autres.
  final Map<String, String> refusParLigne;

  /// Les apercus de lot demandes, dans l'ordre.
  final List<({GesteLot geste, List<String> ids})> appelsApercuLot =
      <({GesteLot geste, List<String> ids})>[];

  /// Les lots recus, dans l'ordre (un essai rejoue compte).
  final List<DemandeLot> appelsLot = <DemandeLot>[];

  /// Les rapports des lots deja joues, par cle (rejeu sans ecriture).
  final Map<String, RapportLot> _lots = <String, RapportLot>{};

  /// Les lectures de dossier (identifiants), dans l'ordre.
  final List<String> appelsLire = <String>[];

  /// Les lectures du contact (identifiants), dans l'ordre : chacune est
  /// inscrite au journal du serveur.
  final List<String> appelsContact = <String>[];

  /// Les curseurs demandes a l'historique, dans l'ordre.
  final List<int?> appelsHistorique = <int?>[];

  /// Les gestes recus, dans l'ordre (un essai rejoue compte).
  final List<AppelGeste> appelsGeste = <AppelGeste>[];

  /// Les cles d'idempotence deja jouees, avec leur resultat (rejeu sans
  /// ecriture).
  final Map<String, ResultatGeste> _cles = <String, ResultatGeste>{};

  /// Les lectures de liste, dans l'ordre.
  final List<AppelLister> appels = <AppelLister>[];

  /// Le nombre d'appels a `capacites()`.
  int appelsCapacites = 0;

  @override
  Future<CapacitesCandidatures> capacites() async {
    appelsCapacites++;
    final Object? e = erreurCapacites;
    if (e != null) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return capacitesRendues;
  }

  @override
  Future<PageCandidatures> lister({
    required FiltreCandidatures filtre,
    required TriCandidatures tri,
    required int page,
  }) async {
    appels.add(AppelLister(filtre, tri, page));
    final Object? e = erreurLister?.call(appels.length);
    if (e != null) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    final Completer<void>? a = attente;
    if (a != null) {
      await a.future;
    }
    final List<LigneCandidature> portee = <LigneCandidature>[
      ...lignes,
      for (final DetailCandidature d in details.values)
        if (!lignes.any((LigneCandidature l) => l.id == d.ligne.id)) d.ligne,
    ];
    final List<LigneCandidature> filtrees = <LigneCandidature>[
      for (final LigneCandidature l in portee)
        if (_garde(l, filtre)) l,
    ]..sort((LigneCandidature a, LigneCandidature b) => _comparer(a, b, tri));
    final int debut = (page - 1) * taillePage;
    final List<LigneCandidature> cette = debut >= filtrees.length
        ? <LigneCandidature>[]
        : filtrees.sublist(
            debut,
            debut + taillePage > filtrees.length
                ? filtrees.length
                : debut + taillePage,
          );
    return PageCandidatures(
      lignes: cette,
      total: filtrees.length,
      page: page,
      taillePage: taillePage,
      compteursEtapes: <EtapeCandidature, int>{
        for (final EtapeCandidature e in EtapeCandidature.values)
          e: lignes
              .where(
                (LigneCandidature l) =>
                    l.issue == IssueCandidature.enCours && l.etape == e,
              )
              .length,
      },
      compteursAlertes: alertes ?? _alertesDuServeur(),
    );
  }

  @override
  Future<DetailCandidature> lire(String candidatureId) async {
    appelsLire.add(candidatureId);
    final Object? e = erreurLire?.call(appelsLire.length);
    if (e != null) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    final Completer<void>? a = attenteLire;
    if (a != null) {
      await a.future;
    }
    final DetailCandidature? d = details[candidatureId];
    if (d == null) {
      throw const CandidatureIntrouvable();
    }
    return d;
  }

  @override
  Future<ContactCandidat> lireContact(String candidatureId) async {
    appelsContact.add(candidatureId);
    final Object? e = erreurContact;
    if (e != null) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return contacts[candidatureId] ?? const ContactCandidat();
  }

  @override
  Future<PageHistorique> historique(
    String candidatureId, {
    int? curseur,
  }) async {
    appelsHistorique.add(curseur);
    final Object? e = erreurHistorique;
    if (e != null) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    final List<EvenementCandidature> tous =
        historiques[candidatureId] ?? <EvenementCandidature>[];
    final int debut = curseur == null
        ? 0
        : tous.indexWhere((EvenementCandidature x) => x.id == curseur) + 1;
    final List<EvenementCandidature> page = tous.skip(debut).take(2).toList();
    final bool reste = debut + page.length < tous.length;
    return PageHistorique(
      evenements: page,
      curseurSuivant: reste ? page.last.id : null,
    );
  }

  @override
  Future<List<ResponsablePossible>> responsablesPossibles(
    String candidatureId,
  ) async {
    if (responsablesIndisponibles) {
      throw const CapaciteIndisponible(dependanceGestesCandidature);
    }
    return responsables;
  }

  @override
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement) async =>
      moyens[paysVersement] ?? const MoyensConfirmes();

  @override
  Future<ResultatGeste> geste(DemandeGeste demande) async {
    appelsGeste.add(AppelGeste(demande));
    final ResultatGeste? rejeu = _cles[demande.cleIdempotence];
    if (rejeu != null) {
      return ResultatGeste(
        candidature: rejeu.candidature,
        rejoue: true,
        elementsDemandes: rejeu.elementsDemandes,
      );
    }
    final int essai = appelsGeste
        .where(
          (AppelGeste a) => a.demande.cleIdempotence == demande.cleIdempotence,
        )
        .length;
    final Object? e = erreurGeste?.call(demande, essai);
    final bool perdue = e is GesteNonConfirme && perteApresEcriture;
    if (e != null && !perdue) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    final DetailCandidature? avant = details[demande.candidatureId];
    if (avant == null) {
      throw const CandidatureIntrouvable();
    }
    if (avant.version != demande.versionAttendue) {
      throw ConflitGeste(avant.version);
    }
    final DetailCandidature apres =
        effetGeste?.call(demande, avant) ?? _memeEtat(avant);
    details[demande.candidatureId] = apres;
    final ResultatGeste resultat = ResultatGeste(
      candidature: EtatApresGeste(
        version: apres.version,
        etape: apres.ligne.etape,
        etat: apres.ligne.etat,
        issue: apres.ligne.issue,
        enPause: apres.ligne.enPause,
        paiement: apres.ligne.paiement,
      ),
      elementsDemandes: demande.elements,
    );
    _cles[demande.cleIdempotence] = resultat;
    if (perdue) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return resultat;
  }

  /// La raison pour laquelle le serveur exclut [l] d'un lot de [geste], ou
  /// `null` : elle est eligible. Les regles de `candidature_gestes_regles`
  /// pour les trois gestes du lot.
  static ({String raison, String? detail})? _exclusion(
    LigneCandidature l,
    GesteLot geste,
  ) {
    final bool enCours = l.issue == IssueCandidature.enCours;
    switch (geste) {
      case GesteLot.mettreEnPause:
        if (!enCours) return (raison: 'transition_interdite', detail: 'etat');
        if (l.enPause) return (raison: 'transition_interdite', detail: 'pause');
      case GesteLot.leverPause:
        if (!enCours || !l.enPause) {
          return (raison: 'transition_interdite', detail: 'etat');
        }
      case GesteLot.refuser:
        final bool avantSalle3 =
            l.etape != EtapeCandidature.confirmee && l.etape != null;
        if (!enCours || !avantSalle3) {
          return (raison: 'transition_interdite', detail: 'etat');
        }
    }
    return null;
  }

  LigneCandidature? _ligneDuLot(String id) {
    for (final LigneCandidature l in lignes) {
      if (l.id == id) return l;
    }
    return details[id]?.ligne;
  }

  int _versionDuLot(String id) => details[id]?.version ?? 1;

  /// Un jeton stable pour ces eligibles et ces versions : 32 signes
  /// hexadecimaux, comme le HMAC du serveur.
  String _jeton(GesteLot geste, List<String> eligibles) {
    final List<String> parts = <String>[
      for (final String id in eligibles) '$id:${_versionDuLot(id)}',
    ]..sort();
    final String base = '${geste.valeurSql}|${parts.join(',')}';
    int h = 0x811c9dc5;
    final StringBuffer sortie = StringBuffer();
    for (int tour = 0; tour < 4; tour++) {
      for (final int c in '$tour$base'.codeUnits) {
        h = ((h ^ c) * 0x01000193) & 0xffffffff;
      }
      sortie.write(h.toRadixString(16).padLeft(8, '0'));
    }
    return sortie.toString();
  }

  @override
  Future<ApercuLot> preparerLot({
    required GesteLot geste,
    required List<String> ids,
  }) async {
    appelsApercuLot.add((geste: geste, ids: List<String>.of(ids)));
    final List<EligibleLot> eligibles = <EligibleLot>[];
    final List<ExclusLot> exclus = <ExclusLot>[];
    for (final String id in ids.toSet()) {
      final LigneCandidature? l = _ligneDuLot(id);
      if (l == null) {
        exclus.add(ExclusLot(id: id, raison: RaisonExclusion.absente));
        continue;
      }
      final ({String raison, String? detail})? x = _exclusion(l, geste);
      if (x == null) {
        eligibles.add(
          EligibleLot(
            id: l.id,
            reference: l.reference,
            nomComplet: l.nomComplet,
            etape: l.etape,
            etat: l.etat,
            issue: l.issue,
            enPause: l.enPause,
            version: _versionDuLot(l.id),
          ),
        );
      } else {
        exclus.add(
          ExclusLot(
            id: l.id,
            raison: RaisonExclusion.transitionInterdite,
            reference: l.reference,
            nomComplet: l.nomComplet,
            etape: l.etape,
            etat: l.etat,
            issue: l.issue,
            enPause: l.enPause,
            parLaPause: x.detail == 'pause',
          ),
        );
      }
    }
    return ApercuLot(
      geste: geste,
      motifRequis: geste != GesteLot.leverPause,
      modeleRequis: geste != GesteLot.leverPause,
      eligibles: eligibles,
      exclus: exclus,
      nombre: eligibles.length,
      jeton: _jeton(geste, <String>[
        for (final EligibleLot e in eligibles) e.id,
      ]),
    );
  }

  @override
  Future<RapportLot> executerLot(DemandeLot demande) async {
    appelsLot.add(demande);
    final RapportLot? rejeu = _lots[demande.cleIdempotence];
    if (rejeu != null) {
      return RapportLot(
        geste: rejeu.geste,
        nombre: rejeu.nombre,
        reussies: rejeu.reussies,
        exclues: rejeu.exclues,
        refusees: rejeu.refusees,
        lignes: rejeu.lignes,
        rejoue: true,
      );
    }
    final int essai = appelsLot
        .where((DemandeLot d) => d.cleIdempotence == demande.cleIdempotence)
        .length;
    final Object? e = erreurLot?.call(demande, essai);
    final bool perdu = e is GesteNonConfirme && perteApresEcriture;
    if (e != null && !perdu) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    if (demande.geste != GesteLot.leverPause) {
      if ((demande.motif ?? '').trim().isEmpty) throw const MotifRequis();
      if (demande.modele == null) throw const ModeleRequis();
    }
    final List<String> eligibles = <String>[
      for (final String id in demande.ids.toSet())
        if (_ligneDuLot(id) case final LigneCandidature l
            when _exclusion(l, demande.geste) == null)
          id,
    ];
    if (demande.jeton != _jeton(demande.geste, eligibles)) {
      throw const JetonPerime();
    }
    if (eligibles.isEmpty) throw const AucunEligible();
    if (eligibles.length != demande.nombreConfirme) {
      throw NombreDiscordant(eligibles.length);
    }
    final List<LigneRapportLot> rapport = <LigneRapportLot>[];
    int reussies = 0;
    int exclues = 0;
    int refusees = 0;
    for (final String id in demande.ids.toSet()) {
      final LigneCandidature? l = _ligneDuLot(id);
      if (l == null) {
        rapport.add(
          LigneRapportLot(
            id: id,
            issue: IssueLigneLot.exclue,
            raison: 'absente',
          ),
        );
        exclues++;
        continue;
      }
      final ({String raison, String? detail})? x = _exclusion(l, demande.geste);
      if (x != null) {
        rapport.add(
          LigneRapportLot(
            id: id,
            reference: l.reference,
            issue: IssueLigneLot.exclue,
            raison: x.raison,
            parLaPause: x.detail == 'pause',
          ),
        );
        exclues++;
      } else if (refusParLigne[id] != null) {
        rapport.add(
          LigneRapportLot(
            id: id,
            reference: l.reference,
            issue: IssueLigneLot.refusee,
            raison: refusParLigne[id],
          ),
        );
        refusees++;
      } else {
        _appliquerAuLot(l, demande.geste);
        rapport.add(
          LigneRapportLot(
            id: id,
            reference: l.reference,
            issue: IssueLigneLot.reussie,
          ),
        );
        reussies++;
      }
    }
    final RapportLot resultat = RapportLot(
      geste: demande.geste,
      nombre: eligibles.length,
      reussies: reussies,
      exclues: exclues,
      refusees: refusees,
      lignes: rapport,
    );
    _lots[demande.cleIdempotence] = resultat;
    if (perdu) {
      Error.throwWithStackTrace(e, StackTrace.current);
    }
    return resultat;
  }

  void _appliquerAuLot(LigneCandidature l, GesteLot geste) {
    final int i = lignes.indexWhere((LigneCandidature x) => x.id == l.id);
    if (i < 0) return;
    lignes[i] = LigneCandidature(
      id: l.id,
      reference: l.reference,
      nomComplet: l.nomComplet,
      type: l.type,
      etape: l.etape,
      etat: l.etat,
      issue: geste == GesteLot.refuser ? IssueCandidature.refusee : l.issue,
      enPause: switch (geste) {
        GesteLot.mettreEnPause => true,
        GesteLot.leverPause => false,
        GesteLot.refuser => l.enPause,
      },
      restreinte: l.restreinte,
      indisponible: l.indisponible,
      paiement: l.paiement,
      courrielAObtenir: l.courrielAObtenir,
      indicatifAConfirmer: l.indicatifAConfirmer,
      derniereActivite: l.derniereActivite,
      repriseLe: l.repriseLe,
      indisponibleJusquAu: l.indisponibleJusquAu,
      paysResidence: l.paysResidence,
      responsableId: l.responsableId,
      recueLe: l.recueLe,
    );
  }

  static DetailCandidature _memeEtat(DetailCandidature d) => DetailCandidature(
    ligne: d.ligne,
    version: d.version + 1,
    provenance: d.provenance,
    pauseModele: d.pauseModele,
    refusModele: d.refusModele,
    restrictionCause: d.restrictionCause,
    documents: d.documents,
    controles: d.controles,
    piece: d.piece,
    autresCompetences: d.autresCompetences,
  );

  CompteursAlertes _alertesDuServeur() => CompteursAlertes(
    informationsManquantes: lignes
        .where(
          (LigneCandidature l) =>
              l.issue == IssueCandidature.enCours &&
              !l.enPause &&
              l.etat == EtatCandidature.aCompleter,
        )
        .length,
    confirmeesIndisponibles: lignes
        .where(
          (LigneCandidature l) =>
              l.issue == IssueCandidature.enCours &&
              !l.enPause &&
              l.etape == EtapeCandidature.confirmee &&
              l.indisponible,
        )
        .length,
  );

  static bool _garde(LigneCandidature l, FiltreCandidatures f) {
    if (f.etape != null && l.etape != f.etape) return false;
    if (f.etat != null && l.etat != f.etat) return false;
    if (f.issue != null && l.issue != f.issue) return false;
    if (f.enPause != null && l.enPause != f.enPause) return false;
    if (f.paiement != null && l.paiement != f.paiement) return false;
    if (f.paysResidence != null && l.paysResidence != f.paysResidence) {
      return false;
    }
    final String q = f.rechercheNette.toLowerCase();
    if (q.isNotEmpty) {
      return l.reference.toLowerCase() == q ||
          l.nomComplet.toLowerCase().contains(q);
    }
    return true;
  }

  static int _comparer(
    LigneCandidature a,
    LigneCandidature b,
    TriCandidatures t,
  ) => switch (t) {
    TriCandidatures.activite => b.derniereActivite.compareTo(
      a.derniereActivite,
    ),
    TriCandidatures.recente => (b.recueLe ?? b.derniereActivite).compareTo(
      a.recueLe ?? a.derniereActivite,
    ),
    TriCandidatures.nom => a.nomComplet.compareTo(b.nomComplet),
  };
}

/// Un double dont la fonction n'existe pas encore cote serveur.
class CandidaturesDirectionIndisponible implements PortCandidaturesDirection {
  /// Cree le double.
  const CandidaturesDirectionIndisponible();

  @override
  Future<CapacitesCandidatures> capacites() =>
      Future<CapacitesCandidatures>.error(
        const CapaciteIndisponible(dependanceFileCandidatures),
      );

  @override
  Future<PageCandidatures> lister({
    required FiltreCandidatures filtre,
    required TriCandidatures tri,
    required int page,
  }) => Future<PageCandidatures>.error(
    const CapaciteIndisponible(dependanceFileCandidatures),
  );

  @override
  Future<DetailCandidature> lire(String candidatureId) =>
      Future<DetailCandidature>.error(
        const CapaciteIndisponible(dependanceDetailCandidature),
      );

  @override
  Future<ContactCandidat> lireContact(String candidatureId) =>
      Future<ContactCandidat>.error(
        const CapaciteIndisponible(dependanceDetailCandidature),
      );

  @override
  Future<PageHistorique> historique(String candidatureId, {int? curseur}) =>
      Future<PageHistorique>.error(
        const CapaciteIndisponible(dependanceHistoriqueCandidature),
      );

  @override
  Future<ResultatGeste> geste(DemandeGeste demande) =>
      Future<ResultatGeste>.error(
        const CapaciteIndisponible(dependanceGestesCandidature),
      );

  @override
  Future<List<ResponsablePossible>> responsablesPossibles(
    String candidatureId,
  ) => Future<List<ResponsablePossible>>.error(
    const CapaciteIndisponible(dependanceGestesCandidature),
  );

  @override
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement) =>
      Future<MoyensConfirmes>.error(
        const CapaciteIndisponible(dependanceGestesCandidature),
      );

  @override
  Future<ApercuLot> preparerLot({
    required GesteLot geste,
    required List<String> ids,
  }) => Future<ApercuLot>.error(
    const CapaciteIndisponible(dependanceGestesCandidature),
  );

  @override
  Future<RapportLot> executerLot(DemandeLot demande) =>
      Future<RapportLot>.error(
        const CapaciteIndisponible(dependanceGestesCandidature),
      );
}
