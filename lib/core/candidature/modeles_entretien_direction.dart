// V2-a (04/11/2026) : les formes de donnees de l'entretien, cote direction
// (`ADM-21`, bloc Entretien), miroir de ce que rendent les RPC de V1-a et
// V1-a-bis (`20261108000001_v1a_entretiens.sql`,
// `20261109100000_v1a_bis_super_admin_entretiens.sql`) :
//
// - `mes_entretiens(p_jours)` : les entretiens de ce cote (une ligne par
//   seance), dont l'ecran garde ceux de la candidature ouverte ;
// - `lire_entretien(p_session)` : les participants, les comptes rendus et le
//   journal des presents ;
// - `personnel_pour_entretien(p_candidature)` : le personnel qu'on peut
//   choisir, du cote de la candidature, plus le super-admin.
//
// **Aucun calcul ici.** Le compte des fondateurs, la regle en vigueur, le cote
// de chaque personne et l'issue sont rendus par le serveur ; l'ecran les lit.
// Jamais le contact du candidat : le serveur ne le rend pas, aucun champ ne le
// recoit.
library;

import 'package:flutter/foundation.dart';

/// L'issue d'un entretien, consignee par la direction.
enum IssueEntretien {
  /// L'entretien a eu lieu (au moins un compte rendu ecrit).
  tenu('tenu'),

  /// L'entretien est annule.
  annule('annule'),

  /// Le candidat ne s'est pas presente.
  manqueCandidat('manque_candidat'),

  /// Une personne qui menait l'entretien ne s'est pas presentee.
  manqueIntervieweur('manque_intervieweur');

  const IssueEntretien(this.valeurSql);

  /// La valeur envoyee au serveur et lue de lui.
  final String valeurSql;

  /// Un motif interne est exige : toute issue sauf « tenu » (regle 12).
  bool get exigeMotif => this != tenu;

  /// La valeur lue, ou `null` (entretien pas encore consigne).
  static IssueEntretien? depuisSql(Object? valeur) {
    for (final IssueEntretien i in values) {
      if (i.valeurSql == valeur) return i;
    }
    return null;
  }
}

/// Un entretien d'une candidature, tel que `mes_entretiens` le rend.
@immutable
class EntretienCandidature {
  /// Cree l'entretien.
  const EntretienCandidature({
    required this.sessionId,
    required this.candidatureId,
    required this.debut,
    required this.fin,
    required this.participants,
    required this.fondateurs,
    this.issue,
    this.jeParticipe = false,
  });

  /// Lit une ligne de `mes_entretiens`. Une ligne sans seance, sans
  /// candidature ou sans dates est rejetee : jamais un entretien devine.
  factory EntretienCandidature.depuisJson(Map<String, dynamic> json) {
    final Object? session = json['session_id'];
    final Object? candidature = json['candidature_id'];
    final DateTime? debut = _instant(json['debut']);
    final DateTime? fin = _instant(json['fin']);
    if (session is! String ||
        candidature is! String ||
        debut == null ||
        fin == null) {
      throw const FormatException('Entretien incomplet.');
    }
    return EntretienCandidature(
      sessionId: session,
      candidatureId: candidature,
      debut: debut,
      fin: fin,
      issue: IssueEntretien.depuisSql(json['issue']),
      jeParticipe: json['je_participe'] == true,
      participants: _entier(json['participants']),
      fondateurs: _entier(json['fondateurs']),
    );
  }

  /// La seance de l'entretien.
  final String sessionId;

  /// La candidature.
  final String candidatureId;

  /// Le debut prevu, en UTC.
  final DateTime debut;

  /// La fin prevue, en UTC.
  final DateTime fin;

  /// L'issue consignee, ou `null` tant que l'entretien est ouvert.
  final IssueEntretien? issue;

  /// L'appelant fait partie des participants.
  final bool jeParticipe;

  /// Le nombre de participants actifs, compte par le serveur.
  final int participants;

  /// Le nombre de fondateurs parmi eux, compte par le serveur.
  final int fondateurs;

  /// L'entretien n'est pas encore consigne.
  bool get ouvert => issue == null;

  /// La duree prevue, en minutes.
  int get dureeMinutes => fin.difference(debut).inMinutes;
}

/// Un participant d'un entretien (`lire_entretien().participants`).
@immutable
class ParticipantEntretien {
  /// Cree le participant.
  const ParticipantEntretien({
    required this.profilId,
    required this.prenom,
    required this.nom,
    this.fondateur = false,
    this.retire = false,
  });

  /// Lit une ligne. Sans profil : rejetee.
  factory ParticipantEntretien.depuisJson(Map<String, dynamic> json) {
    final Object? id = json['profileId'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Participant sans profil.');
    }
    return ParticipantEntretien(
      profilId: id,
      prenom: _texte(json['prenom']),
      nom: _texte(json['nom']),
      fondateur: json['fondateur'] == true,
      retire: json['retire'] == true,
    );
  }

  /// Le profil.
  final String profilId;

  /// Le prenom.
  final String prenom;

  /// Le nom.
  final String nom;

  /// Compte parmi les fondateurs de cet entretien.
  final bool fondateur;

  /// Retire de l'entretien (la ligne reste, pour l'historique).
  final bool retire;

  /// Le nom complet, tel qu'il s'affiche.
  String get nomComplet =>
      <String>[prenom, nom].where((String s) => s.isNotEmpty).join(' ');
}

/// L'avis d'un compte rendu, tel que le participant l'a pose.
enum AvisEntretien {
  /// Favorable.
  favorable('favorable'),

  /// Avec reserve.
  reserve('reserve'),

  /// Defavorable.
  defavorable('defavorable');

  const AvisEntretien(this.valeurSql);

  /// La valeur lue du serveur.
  final String valeurSql;

  /// La valeur lue, ou `null`.
  static AvisEntretien? depuisSql(Object? valeur) {
    for (final AvisEntretien a in values) {
      if (a.valeurSql == valeur) return a;
    }
    return null;
  }
}

/// Le compte rendu d'un participant (`lire_entretien().comptesRendus`).
@immutable
class CompteRenduEntretien {
  /// Cree le compte rendu.
  const CompteRenduEntretien({
    required this.auteurId,
    required this.texte,
    this.avis,
    this.ecritLe,
  });

  /// Lit une ligne. Sans auteur : rejetee.
  factory CompteRenduEntretien.depuisJson(Map<String, dynamic> json) {
    final Object? auteur = json['auteurId'];
    if (auteur is! String || auteur.isEmpty) {
      throw const FormatException('Compte rendu sans auteur.');
    }
    return CompteRenduEntretien(
      auteurId: auteur,
      texte: _texte(json['texte']),
      avis: AvisEntretien.depuisSql(json['avis']),
      ecritLe: _instant(json['ecritLe']),
    );
  }

  /// L'auteur (un participant).
  final String auteurId;

  /// Le texte, tel que l'auteur l'a ecrit.
  final String texte;

  /// L'avis, quand l'auteur l'a pose.
  final AvisEntretien? avis;

  /// La derniere ecriture.
  final DateTime? ecritLe;
}

/// Une arrivee ou un depart dans la salle (`lire_entretien().presences`,
/// journal du webhook LiveKit).
@immutable
class PresenceEntretien {
  /// Cree la presence.
  const PresenceEntretien({
    required this.profilId,
    required this.arrivee,
    required this.le,
  });

  /// Lit une ligne. Un evenement autre qu'une arrivee ou un depart, ou sans
  /// heure, est rejete.
  factory PresenceEntretien.depuisJson(Map<String, dynamic> json) {
    final Object? profil = json['profileId'];
    final Object? evenement = json['evenement'];
    final DateTime? le = _instant(json['le']);
    if (profil is! String ||
        le == null ||
        (evenement != 'joined' && evenement != 'left')) {
      throw const FormatException('Presence illisible.');
    }
    return PresenceEntretien(
      profilId: profil,
      arrivee: evenement == 'joined',
      le: le,
    );
  }

  /// Le profil.
  final String profilId;

  /// Vrai pour une arrivee, faux pour un depart.
  final bool arrivee;

  /// L'instant, en UTC.
  final DateTime le;
}

/// Ce que `lire_entretien` rend a la direction de ce cote.
@immutable
class DetailEntretien {
  /// Cree le detail.
  const DetailEntretien({
    required this.sessionId,
    this.issue,
    this.participants = const <ParticipantEntretien>[],
    this.comptesRendus = const <CompteRenduEntretien>[],
    this.presences = const <PresenceEntretien>[],
  });

  /// Lit la reponse. Une ligne illisible est ecartee, jamais inventee.
  factory DetailEntretien.depuisJson(Map<String, dynamic> json) {
    final Object? session = json['sessionId'];
    if (session is! String) {
      throw const FormatException('Entretien sans seance.');
    }
    List<T> lignes<T>(String cle, T Function(Map<String, dynamic>) lire) =>
        List<T>.unmodifiable(<T>[
          if (json[cle] is List)
            for (final Object? l in json[cle] as List)
              if (l is Map)
                if (_lisible(() => lire(Map<String, dynamic>.from(l)))
                    case final T v)
                  v,
        ]);
    return DetailEntretien(
      sessionId: session,
      issue: IssueEntretien.depuisSql(json['issue']),
      participants: lignes('participants', ParticipantEntretien.depuisJson),
      comptesRendus: lignes('comptesRendus', CompteRenduEntretien.depuisJson),
      presences: lignes('presences', PresenceEntretien.depuisJson),
    );
  }

  /// La seance.
  final String sessionId;

  /// L'issue consignee, ou `null`.
  final IssueEntretien? issue;

  /// Tous les participants, retires compris, dans l'ordre du serveur
  /// (fondateurs d'abord).
  final List<ParticipantEntretien> participants;

  /// Les comptes rendus, du plus ancien au plus recent.
  final List<CompteRenduEntretien> comptesRendus;

  /// Les arrivees et departs, dans l'ordre.
  final List<PresenceEntretien> presences;

  /// Les participants actifs.
  List<ParticipantEntretien> get actifs => <ParticipantEntretien>[
    for (final ParticipantEntretien p in participants)
      if (!p.retire) p,
  ];

  /// Le nom d'un profil de l'entretien, ou `null` s'il n'en fait pas partie.
  String? nomDe(String profilId) {
    for (final ParticipantEntretien p in participants) {
      if (p.profilId == profilId) return p.nomComplet;
    }
    return null;
  }
}

/// Une personne du personnel qu'on peut choisir pour un entretien
/// (`personnel_pour_entretien`).
@immutable
class PersonnelEntretien {
  /// Cree la personne.
  const PersonnelEntretien({
    required this.profilId,
    required this.prenom,
    required this.nom,
    this.fondateur = false,
  });

  /// Lit une ligne. Sans profil : rejetee.
  factory PersonnelEntretien.depuisJson(Map<String, dynamic> json) {
    final Object? id = json['profile_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Personnel sans profil.');
    }
    return PersonnelEntretien(
      profilId: id,
      prenom: _texte(json['prenom']),
      nom: _texte(json['nom']),
      fondateur: json['fondateur'] == true,
    );
  }

  /// Le profil.
  final String profilId;

  /// Le prenom.
  final String prenom;

  /// Le nom.
  final String nom;

  /// Coche fondateur, lue au serveur.
  final bool fondateur;

  /// Le nom complet, tel qu'il s'affiche.
  String get nomComplet =>
      <String>[prenom, nom].where((String s) => s.isNotEmpty).join(' ');
}

// --- Les refus de l'entretien -----------------------------------------------

/// Un refus nomme d'un geste d'entretien, rendu par le serveur sans rien
/// ecrire. L'ecran le dit en mots, jamais par son code.
sealed class RefusEntretien implements Exception {
  const RefusEntretien();
}

/// Il manque des fondateurs parmi les participants (regle active).
final class FondateursInsuffisants extends RefusEntretien {
  /// Cree le refus.
  const FondateursInsuffisants({required this.exiges, required this.presents});

  /// Le minimum en vigueur.
  final int exiges;

  /// Le nombre de fondateurs choisis.
  final int presents;
}

/// Le debut choisi n'est pas permis : moins de 5 minutes, ou plus de 90 jours.
final class DebutInvalide extends RefusEntretien {
  /// Cree le refus.
  const DebutInvalide();
}

/// La duree n'est pas entre 15 et 120 minutes.
final class DureeInvalide extends RefusEntretien {
  /// Cree le refus.
  const DureeInvalide();
}

/// Aucun participant n'a ete choisi.
final class ParticipantsRequis extends RefusEntretien {
  /// Cree le refus.
  const ParticipantsRequis();
}

/// Plus de douze participants.
final class ParticipantsTropNombreux extends RefusEntretien {
  /// Cree le refus.
  const ParticipantsTropNombreux();
}

/// Une personne choisie n'est pas un membre actif du personnel.
final class ParticipantNonAutorise extends RefusEntretien {
  /// Cree le refus.
  const ParticipantNonAutorise();
}

/// Une personne choisie n'est pas du cote de la candidature.
final class ParticipantAutreCote extends RefusEntretien {
  /// Cree le refus.
  const ParticipantAutreCote();
}

/// La personne n'a pas encore de compte.
final class CandidatSansCompte extends RefusEntretien {
  /// Cree le refus.
  const CandidatSansCompte();
}

/// Un entretien est deja planifie et pas encore consigne.
final class EntretienDejaPlanifie extends RefusEntretien {
  /// Cree le refus.
  const EntretienDejaPlanifie();
}

/// L'entretien est deja consigne : il ne change plus.
final class EntretienConsigne extends RefusEntretien {
  /// Cree le refus.
  const EntretienConsigne();
}

/// Retirer cette personne laisserait l'entretien sans participant.
final class DernierParticipant extends RefusEntretien {
  /// Cree le refus.
  const DernierParticipant();
}

/// La personne n'est plus participante.
final class ParticipantAbsent extends RefusEntretien {
  /// Cree le refus.
  const ParticipantAbsent();
}

/// « Tenu » exige au moins un compte rendu d'un participant.
final class CompteRenduRequis extends RefusEntretien {
  /// Cree le refus.
  const CompteRenduRequis();
}

/// L'entretien n'existe pas, ou plus, de ce cote.
final class EntretienIntrouvable extends RefusEntretien {
  /// Cree le refus.
  const EntretienIntrouvable();
}

// --- Aides de lecture -------------------------------------------------------

String _texte(Object? v) => v is String ? v : '';

int _entier(Object? v) => v is int ? v : (v is num ? v.toInt() : 0);

DateTime? _instant(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toUtc() : null;

T? _lisible<T>(T Function() lire) {
  try {
    return lire();
  } on FormatException {
    return null;
  }
}
