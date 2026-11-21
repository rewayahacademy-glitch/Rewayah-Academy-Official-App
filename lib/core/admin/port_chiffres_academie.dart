/// CHIFFRES-ACADEMIE (directeur, 20/11/2026) : les chiffres de l'academie,
/// rendus en UN appel par `chiffres_academie()` (migration 20261130969500).
///
/// Des nombres seulement : jamais un nom, une adresse ni un identifiant. Le
/// serveur compte tout ; l'ecran ne calcule que des parts (un nombre sur un
/// autre) pour ses dessins.
///
/// Sans port ([portChiffresAcademieProvider] vaut `null`), la lecture leve
/// [CapaciteIndisponible] et l'ecran le dit en clair.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les chiffres de la page, tels que le serveur les rend.
@immutable
class ChiffresAcademie {
  /// Cree un releve.
  const ChiffresAcademie({
    required this.genereLe,
    this.memoriseLe,
    required this.candidatsRecus,
    required this.candidatsAujourdhui,
    required this.candidatsSeptJours,
    required this.candidatsSeptPleins,
    required this.candidatsSeptPleinsAvant,
    required this.candidatsParJour,
    required this.pays,
    required this.hommes,
    required this.femmes,
    required this.repondants,
    required this.coranEntier,
    required this.juzMin,
    required this.ijaza,
    required this.riwayat,
    required this.langues,
    required this.enseignants,
    required this.eleves,
    required this.elevesEnClasse,
    required this.familles,
    required this.classes,
    required this.languesCours,
    required this.seancesTenues,
    required this.seancesMinutes,
    required this.seancesSeptJours,
    required this.seancesSeptPleins,
    required this.seancesSeptPleinsAvant,
  });

  /// L'heure du serveur a la lecture.
  final DateTime genereLe;

  /// L'heure du dernier recalcul des chiffres memorises (10 minutes au plus).
  final DateTime? memoriseLe;

  /// Candidatures d'enseignants recues, toutes issues.
  final int candidatsRecus;

  /// ... recues depuis minuit a La Mecque.
  final int candidatsAujourdhui;

  /// ... recues sur les 7 derniers jours, aujourd'hui compris.
  final int candidatsSeptJours;

  /// ... recues sur 7 jours pleins (d'il y a 7 jours a hier).
  final int candidatsSeptPleins;

  /// ... recues sur les 7 jours pleins d'avant.
  final int candidatsSeptPleinsAvant;

  /// Les 7 derniers jours, du plus ancien a aujourd'hui.
  final List<int> candidatsParJour;

  /// Pays de residence distincts des candidats.
  final int pays;

  /// Candidats hommes.
  final int hommes;

  /// Candidates femmes.
  final int femmes;

  /// Candidats qui ont envoye leurs reponses.
  final int repondants;

  /// ... qui declarent avoir memorise tout le Coran.
  final int coranEntier;

  /// Le minimum certain des juz declares.
  final int juzMin;

  /// ... qui declarent une ijaza.
  final int ijaza;

  /// Riwayat distinctes declarees.
  final int riwayat;

  /// Langues d'explication distinctes declarees.
  final int langues;

  /// Comptes d'enseignants actifs.
  final int enseignants;

  /// Eleves inscrits.
  final int eleves;

  /// Eleves membres d'une classe ouverte.
  final int elevesEnClasse;

  /// Familles inscrites.
  final int familles;

  /// Classes ouvertes.
  final int classes;

  /// Langues de cours actives.
  final int languesCours;

  /// Seances de classe terminees.
  final int seancesTenues;

  /// Leur duree totale, en minutes.
  final int seancesMinutes;

  /// Seances terminees sur les 7 derniers jours.
  final int seancesSeptJours;

  /// Seances terminees sur 7 jours pleins (d'il y a 7 jours a hier).
  final int seancesSeptPleins;

  /// Seances terminees sur les 7 jours pleins d'avant.
  final int seancesSeptPleinsAvant;

  /// Vrai quand la base ne sait encore rien : aucun chiffre a montrer.
  bool get estVide =>
      candidatsRecus == 0 &&
      enseignants == 0 &&
      eleves == 0 &&
      familles == 0 &&
      classes == 0 &&
      seancesTenues == 0;

  /// Les nombres, dans l'ordre : deux releves sont egaux quand aucun chiffre
  /// n'a change (l'heure de lecture ne compte pas), et la page ne se
  /// redessine alors pas.
  List<int> get _nombres => <int>[
    candidatsRecus,
    candidatsAujourdhui,
    candidatsSeptJours,
    candidatsSeptPleins,
    candidatsSeptPleinsAvant,
    pays,
    hommes,
    femmes,
    repondants,
    coranEntier,
    juzMin,
    ijaza,
    riwayat,
    langues,
    enseignants,
    eleves,
    elevesEnClasse,
    familles,
    classes,
    languesCours,
    seancesTenues,
    seancesMinutes,
    seancesSeptJours,
    seancesSeptPleins,
    seancesSeptPleinsAvant,
    ...candidatsParJour,
  ];

  @override
  bool operator ==(Object other) =>
      other is ChiffresAcademie && listEquals(other._nombres, _nombres);

  @override
  int get hashCode => Object.hashAll(_nombres);

  /// Lit la reponse de `chiffres_academie()`.
  factory ChiffresAcademie.json(Map<String, dynamic> m) {
    final Map<String, dynamic> c = _objet(m['candidats']);
    final Map<String, dynamic> d = _objet(m['declarations']);
    final Map<String, dynamic> a = _objet(m['academie']);
    final Map<String, dynamic> s = _objet(m['seances']);
    final Object? jours = c['par_jour'];
    return ChiffresAcademie(
      genereLe:
          DateTime.tryParse('${m['genere_le']}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      memoriseLe: DateTime.tryParse('${m['memorise_le']}'),
      candidatsRecus: _entier(c['recus']),
      candidatsAujourdhui: _entier(c['aujourd_hui']),
      candidatsSeptJours: _entier(c['sept_jours']),
      candidatsSeptPleins: _entier(c['sept_pleins']),
      candidatsSeptPleinsAvant: _entier(c['sept_pleins_avant']),
      candidatsParJour: List<int>.unmodifiable(<int>[
        if (jours is List)
          for (final Object? j in jours) _entier(j),
      ]),
      pays: _entier(c['pays']),
      hommes: _entier(c['hommes']),
      femmes: _entier(c['femmes']),
      repondants: _entier(d['repondants']),
      coranEntier: _entier(d['coran_entier']),
      juzMin: _entier(d['juz_min']),
      ijaza: _entier(d['ijaza']),
      riwayat: _entier(d['riwayat']),
      langues: _entier(d['langues']),
      enseignants: _entier(a['enseignants']),
      eleves: _entier(a['eleves']),
      elevesEnClasse: _entier(a['eleves_en_classe']),
      familles: _entier(a['familles']),
      classes: _entier(a['classes']),
      languesCours: _entier(a['langues_cours']),
      seancesTenues: _entier(s['tenues']),
      seancesMinutes: _entier(s['minutes']),
      seancesSeptJours: _entier(s['sept_jours']),
      seancesSeptPleins: _entier(s['sept_pleins']),
      seancesSeptPleinsAvant: _entier(s['sept_pleins_avant']),
    );
  }

  static Map<String, dynamic> _objet(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

  static int _entier(Object? v) {
    final int n = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return n < 0 ? 0 : n;
  }
}

/// La lecture des chiffres : un seul appel.
abstract interface class PortChiffresAcademie {
  /// Lit tous les chiffres.
  Future<ChiffresAcademie> lire();
}

/// Le serveur refuse : la page est reservee a la direction active.
class ChiffresReserves implements Exception {
  /// Cree le refus.
  const ChiffresReserves();

  @override
  String toString() => 'ChiffresReserves';
}

/// Ce qui manque quand le port est absent.
const String dependanceChiffresAcademie = 'DB-CHIFFRES-ACADEMIE';

/// Le port : absent sans serveur.
final Provider<PortChiffresAcademie?> portChiffresAcademieProvider =
    Provider<PortChiffresAcademie?>((Ref _) => null);
