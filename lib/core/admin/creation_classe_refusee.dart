/// CAND-Q15, lot creer_groupe (21/10/2026) : le refus, par le serveur, de
/// creer une classe avec l'enseignant choisi.
///
/// Depuis la migration `20261021210200`, `creer_groupe` passe par le predicat
/// d'affectation (piece d'identite validee, date d'acces, profil enseignant,
/// genre connu, plafond hebdomadaire, collisions ; pas la couverture par les
/// disponibilites, decision du directeur). Le serveur refuse donc
/// legitimement : ces refus sont une reponse, et l'ecran dit une phrase par
/// motif. **Jamais le texte SQL** : « plafond horaire enseignant dépassé » est
/// technique, et en francais meme dans l'interface arabe. Un motif inconnu
/// donne une phrase generique honnete.
///
/// Hors d'un fichier `port_*.dart` a dessein (`AGENTS.md`, contrat commun) :
/// `PortCreationClasse` et `ServiceGroupes` gardent leur signature ; seul
/// l'adaptateur Supabase traduit l'erreur.
library;

import 'dart:convert' show jsonDecode;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'plafond_classes.dart';

/// Pourquoi le serveur a refuse de creer la classe.
enum MotifRefusCreationClasse {
  /// La personne connectee ne peut pas creer de classe (garde de la
  /// direction active, ou SQLSTATE 42501).
  reservee,

  /// Le compte de l'enseignant n'existe plus, n'est pas un compte
  /// d'enseignant ou n'est pas actif.
  compteEnseignant,

  /// Piece d'identite non validee, acces termine, profil d'enseignant absent
  /// ou supprime, ou genre non renseigne.
  enseignantNonEligible,

  /// Le genre de l'enseignant ne correspond pas au public de la classe.
  genreIncompatible,

  /// La classe depasserait le plafond d'heures par semaine de l'enseignant.
  plafond,

  /// L'enseignant a deja une classe active ou un eleve suivi au meme instant.
  chevauchementClasse,

  /// L'enseignant a deja une seance prevue au meme instant (seance
  /// ponctuelle, seance d'une autre classe, ou seance encore planifiee d'une
  /// classe close ; C1 : aussi le SQLSTATE 23P01 de
  /// `sessions_no_teacher_overlap`).
  chevauchementSeance,

  /// C1 (02/11/2026) : deux creneaux de la classe elle-meme se chevauchent
  /// (DETAIL `{"creneaux_propres": true}`, migration 20261105200000).
  chevauchementCreneauxPropres,

  /// FN-113 : l'enseignant tient deja le nombre maximum de Classes actives
  /// (`plafond_classes_atteint`, reglage `enseignant.classes_max`, migration
  /// 20261022000200). Le DETAIL du serveur donne les deux nombres.
  plafondClasses,

  /// FN-113 : les creneaux envoyes sont refuses (`CreneauxInvalides`,
  /// `CreneauxEnDouble`, SQLSTATE 22023).
  creneaux,

  /// Un refus que le client ne connait pas : phrase generique.
  inconnu,
}

/// C1 / UX-020 (02/11/2026) : la classe et l'heure en conflit, lues dans le
/// DETAIL du refus de chevauchement (migration 20261105200000). Rien n'est
/// invente : un champ absent du DETAIL reste nul.
@immutable
class ConflitHoraire {
  /// Cree le conflit.
  const ConflitHoraire({
    required this.jour,
    required this.heure,
    this.classe,
    this.minute = 0,
    this.fuseau,
    this.date,
  });

  /// Le nom de la classe en conflit ; nul pour un eleve suivi seul ou une
  /// seance hors classe.
  final String? classe;

  /// Le jour ISO (1 = lundi, 7 = dimanche), dans [fuseau].
  final int jour;

  /// L'heure (0-23), dans [fuseau].
  final int heure;

  /// Les minutes (0 pour un creneau d'une heure pleine).
  final int minute;

  /// Le fuseau IANA de la classe en conflit.
  final String? fuseau;

  /// La date locale (`AAAA-MM-JJ`) d'une seance datee ; nulle pour un horaire
  /// recurrent.
  final String? date;

  @override
  bool operator ==(Object other) =>
      other is ConflitHoraire &&
      other.classe == classe &&
      other.jour == jour &&
      other.heure == heure &&
      other.minute == minute &&
      other.fuseau == fuseau &&
      other.date == date;

  @override
  int get hashCode => Object.hash(classe, jour, heure, minute, fuseau, date);
}

/// Le JSON pose a la fin du DETAIL d'un refus de chevauchement, ou `null` :
/// pas de DETAIL, pas d'objet, ou un objet illisible (jamais d'exception).
Map<String, dynamic>? jsonDuDetail(String? detail) {
  if (detail == null) return null;
  final int debut = detail.indexOf('{');
  if (debut < 0) return null;
  try {
    final Object? lu = jsonDecode(detail.substring(debut));
    return lu is Map<String, dynamic> ? lu : null;
  } on FormatException {
    return null;
  }
}

/// Le conflit decrit par le DETAIL [detail], ou `null` s'il n'en decrit pas
/// (jour ou heure absents ou hors bornes).
ConflitHoraire? conflitDuDetail(String? detail) {
  final Map<String, dynamic>? json = jsonDuDetail(detail);
  if (json == null) return null;
  final Object? jour = json['jour'];
  final Object? heure = json['heure'];
  if (jour is! num || heure is! num) return null;
  if (jour < 1 || jour > 7 || heure < 0 || heure > 23) return null;
  final Object? minute = json['minute'];
  final Object? classe = json['classe'];
  final Object? fuseau = json['fuseau'];
  final Object? date = json['date'];
  return ConflitHoraire(
    classe: classe is String && classe.trim().isNotEmpty ? classe.trim() : null,
    jour: jour.toInt(),
    heure: heure.toInt(),
    minute: minute is num && minute >= 0 && minute < 60 ? minute.toInt() : 0,
    fuseau: fuseau is String && fuseau.isNotEmpty ? fuseau : null,
    date: date is String && date.isNotEmpty ? date : null,
  );
}

/// Le serveur a repondu non a la creation d'une classe.
@immutable
class CreationClasseRefusee implements Exception {
  /// Cree le refus.
  const CreationClasseRefusee(
    this.motif, {
    this.actives,
    this.maximum,
    this.conflit,
  });

  /// Le motif, ferme. L'ecran le met en mots ; le texte du serveur n'est pas
  /// garde.
  final MotifRefusCreationClasse motif;

  /// FN-113 : pour [MotifRefusCreationClasse.plafondClasses], le nombre de
  /// Classes actives de l'enseignant, lu dans le DETAIL du serveur ; `null`
  /// s'il ne s'y lit pas (rien n'est invente).
  final int? actives;

  /// FN-113 : le maximum fixe dans les Regles, lu dans le DETAIL ; `null`
  /// s'il ne s'y lit pas.
  final int? maximum;

  /// C1 : pour un chevauchement, la classe et l'heure en conflit lues dans
  /// le DETAIL ; `null` si le serveur ne les donne pas.
  final ConflitHoraire? conflit;

  @override
  String toString() => 'CreationClasseRefusee(${motif.name})';
}

/// Les debuts des messages leves par `creer_groupe` et par le predicat
/// d'affectation (`0082`, repris par `20261021210200`), avec leur motif. Le
/// prefixe suffit, et deux messages portent un accent que le serveur ecrit
/// tel quel : on compare sans eux.
const List<(String, MotifRefusCreationClasse)>
_prefixes = <(String, MotifRefusCreationClasse)>[
  ('creation de groupe reservee', MotifRefusCreationClasse.reservee),
  ('cet enseignant n', MotifRefusCreationClasse.compteEnseignant),
  ('enseignant indisponible', MotifRefusCreationClasse.enseignantNonEligible),
  (
    'enseignant incompatible avec le public',
    MotifRefusCreationClasse.genreIncompatible,
  ),
  ('plafond horaire enseignant', MotifRefusCreationClasse.plafond),
  (
    'chevauchement avec une classe',
    MotifRefusCreationClasse.chevauchementClasse,
  ),
  ('chevauchement avec une s', MotifRefusCreationClasse.chevauchementSeance),
  // FN-113 : codes leves par creer_classe_creneaux_admin et le predicat
  // d'affectation, jusqu'ici rendus par la phrase generique.
  (messagePlafondClasses, MotifRefusCreationClasse.plafondClasses),
  ('creneauxinvalides', MotifRefusCreationClasse.creneaux),
  ('creneauxendouble', MotifRefusCreationClasse.creneaux),
];

/// Le motif d'un refus serveur, d'apres son SQLSTATE ([code]) et son
/// [message]. Fonction pure : aucune phrase ici, et le message n'est jamais
/// rendu tel quel.
MotifRefusCreationClasse motifRefusCreationClasse({
  required String? code,
  required String message,
}) {
  if (code == '42501') return MotifRefusCreationClasse.reservee;
  // C1 : la contrainte sessions_no_teacher_overlap, si un chemin la laisse
  // encore passer, est un chevauchement de seance, pas un refus inconnu.
  if (code == '23P01') return MotifRefusCreationClasse.chevauchementSeance;
  final String m = message.trim().toLowerCase();
  for (final (String prefixe, MotifRefusCreationClasse motif) in _prefixes) {
    if (m.startsWith(prefixe)) return motif;
  }
  return MotifRefusCreationClasse.inconnu;
}

/// Lance [appel] et traduit un refus du serveur (`PostgrestException`) en
/// [CreationClasseRefusee]. Toute autre erreur (reseau, format) passe telle
/// quelle : ce n'est pas un refus, l'ecran la dit comme avant.
Future<T> traduireRefusCreationClasse<T>(Future<T> Function() appel) async {
  try {
    return await appel();
  } on PostgrestException catch (e) {
    final MotifRefusCreationClasse motif = motifRefusCreationClasse(
      code: e.code,
      message: e.message,
    );
    if (motif == MotifRefusCreationClasse.plafondClasses) {
      final ({int? actives, int? maximum}) n = nombresPlafondClasses(
        e.details?.toString(),
      );
      throw CreationClasseRefusee(
        motif,
        actives: n.actives,
        maximum: n.maximum,
      );
    }
    if (motif == MotifRefusCreationClasse.chevauchementSeance &&
        jsonDuDetail(e.details?.toString())?['creneaux_propres'] == true) {
      throw const CreationClasseRefusee(
        MotifRefusCreationClasse.chevauchementCreneauxPropres,
      );
    }
    if (motif == MotifRefusCreationClasse.chevauchementClasse ||
        motif == MotifRefusCreationClasse.chevauchementSeance) {
      throw CreationClasseRefusee(
        motif,
        conflit: conflitDuDetail(e.details?.toString()),
      );
    }
    throw CreationClasseRefusee(motif);
  }
}
