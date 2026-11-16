// LP-2 (SPEC-LISTE-PERSONNES §2 et §3) : les formes de donnees de la liste des
// enseignants, telles que `lister_enseignants` (LP-1, migration
// 20261129400000) les rend.
//
// Miroir Dart de ce que le serveur rend, jamais un calcul : la phase, ce qui
// manque, qui attend quoi, les gestes permis par ligne et par selection sont
// decides au serveur. Une ligne est le dossier de candidature de la personne
// (`LigneCandidature`), completee par ce qui se passe apres l'embauche.
library;

import 'package:flutter/foundation.dart';

import '../candidature/modeles_candidatures_direction.dart';

/// La phase de la vie d'un enseignant, calculee par le serveur.
enum PhaseEnseignant {
  /// La candidature n'est pas confirmee, ou elle est refusee ou retiree.
  candidat('candidat'),

  /// Confirmee, il manque encore quelque chose.
  accueil('accueil'),

  /// Confirmee, rien ne manque, aucune classe.
  disponible('disponible'),

  /// Au moins une classe en cours.
  enPoste('en_poste'),

  /// En poste, avec une absence declaree sans remplacant.
  absent('absent'),

  /// Mise en pause par la direction.
  pause('pause'),

  /// Compte desactive.
  suspendu('suspendu'),

  /// Compte supprime (masque par defaut).
  parti('parti');

  const PhaseEnseignant(this.valeurSql);

  /// La valeur ecrite par le serveur (`phase`).
  final String valeurSql;

  /// La phase lue, ou `null` : une phase inconnue n'est jamais devinee.
  static PhaseEnseignant? depuisSql(Object? valeur) {
    for (final PhaseEnseignant p in values) {
      if (p.valeurSql == valeur) {
        return p;
      }
    }
    return null;
  }
}

/// Les classes en cours d'un enseignant.
@immutable
class ClassesEnseignant {
  /// Cree la valeur.
  const ClassesEnseignant({required this.nombre, required this.heuresSemaine});

  /// Lit les classes ; une valeur absente vaut zero.
  factory ClassesEnseignant.depuisJson(Object? brut) {
    if (brut is! Map)
      return const ClassesEnseignant(nombre: 0, heuresSemaine: 0);
    final Object? n = brut['nombre'];
    final Object? h = brut['heuresSemaine'];
    return ClassesEnseignant(
      nombre: n is int && n >= 0 ? n : 0,
      heuresSemaine: h is num && h >= 0 ? h.toDouble() : 0,
    );
  }

  /// Le nombre de classes en cours.
  final int nombre;

  /// Les heures par semaine, toutes classes confondues.
  final double heuresSemaine;
}

/// Les remplacements des 30 derniers jours.
@immutable
class RemplacementsEnseignant {
  /// Cree la valeur.
  const RemplacementsEnseignant({required this.donnes, required this.recus});

  /// Lit les remplacements ; une valeur absente vaut zero.
  factory RemplacementsEnseignant.depuisJson(Object? brut) {
    int n(Object? v) => v is int && v >= 0 ? v : 0;
    if (brut is! Map) return const RemplacementsEnseignant(donnes: 0, recus: 0);
    return RemplacementsEnseignant(
      donnes: n(brut['donnes']),
      recus: n(brut['recus']),
    );
  }

  /// Les seances remplacees par cet enseignant.
  final int donnes;

  /// Les seances de cet enseignant remplacees par un autre.
  final int recus;
}

/// Une ligne de la liste : une personne, une seule fois, quelle que soit sa
/// phase.
@immutable
class LigneEnseignant {
  /// Cree la ligne.
  const LigneEnseignant({
    required this.dossier,
    required this.phase,
    this.manque = const <String>[],
    this.quiAttend,
    this.classes = const ClassesEnseignant(nombre: 0, heuresSemaine: 0),
    this.prochaineSeance,
    this.remplacements = const RemplacementsEnseignant(donnes: 0, recus: 0),
    this.coordonneesVersement = false,
    this.gestes = const <String>[],
    this.gestesGroupables = const <String>[],
    this.actionsPhase = const <String>[],
  });

  /// Lit une ligne, ou `null` quand elle n'a ni identifiant ni phase lisibles :
  /// on n'invente pas une ligne.
  static LigneEnseignant? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final LigneCandidature? dossier = LigneCandidature.depuisJson(brut);
    final PhaseEnseignant? phase = PhaseEnseignant.depuisSql(brut['phase']);
    if (dossier == null || phase == null) return null;
    List<String> mots(Object? v) => List<String>.unmodifiable(<String>[
      if (v is List)
        for (final Object? m in v)
          if (m is String && m.isNotEmpty) m,
    ]);
    final Object? attend = brut['quiAttend'];
    return LigneEnseignant(
      dossier: dossier,
      phase: phase,
      manque: mots(brut['manque']),
      quiAttend: attend is String && attend.isNotEmpty ? attend : null,
      classes: ClassesEnseignant.depuisJson(brut['classes']),
      prochaineSeance: DateTime.tryParse(
        brut['prochaineSeance'] is String
            ? brut['prochaineSeance'] as String
            : '',
      ),
      remplacements: RemplacementsEnseignant.depuisJson(
        brut['remplacements30j'],
      ),
      coordonneesVersement: brut['coordonneesVersement'] == true,
      gestes: mots(brut['gestes']),
      gestesGroupables: mots(brut['gestesGroupables']),
      actionsPhase: mots(brut['actionsPhase']),
    );
  }

  /// Le dossier de candidature de la personne.
  final LigneCandidature dossier;

  /// La phase, decidee par le serveur.
  final PhaseEnseignant phase;

  /// Ce qui manque encore a un enseignant en accueil (cles du serveur).
  final List<String> manque;

  /// Qui attend : `candidat`, `direction`, `enseignant`, ou `null`.
  final String? quiAttend;

  /// Les classes en cours.
  final ClassesEnseignant classes;

  /// La prochaine seance, ou `null`.
  final DateTime? prochaineSeance;

  /// Les remplacements des 30 derniers jours.
  final RemplacementsEnseignant remplacements;

  /// Vrai quand des coordonnees de versement sont validees.
  final bool coordonneesVersement;

  /// Les gestes permis sur cette ligne (noms du moteur des gestes).
  final List<String> gestes;

  /// Parmi eux, ceux que la selection peut grouper.
  final List<String> gestesGroupables;

  /// Les actions propres a la phase (`affecter_classe`, `reaffecter_classe`).
  final List<String> actionsPhase;

  /// L'identifiant du dossier.
  String get id => dossier.id;
}

/// Les compteurs de la liste, toute la portee, sans les autres filtres.
@immutable
class CompteursEnseignants {
  /// Cree les compteurs.
  const CompteursEnseignants({
    this.parPhase = const <PhaseEnseignant, int>{},
    this.nouveaux = 0,
    this.sansDossier = 0,
  });

  /// Lit les compteurs ; une phase absente n'est pas servie.
  factory CompteursEnseignants.depuisJson(Object? brut) {
    if (brut is! Map) return const CompteursEnseignants();
    int n(Object? v) => v is int && v >= 0 ? v : 0;
    return CompteursEnseignants(
      parPhase: Map<PhaseEnseignant, int>.unmodifiable(<PhaseEnseignant, int>{
        for (final PhaseEnseignant p in PhaseEnseignant.values)
          if (brut[p.valeurSql] case final int c when c >= 0) p: c,
      }),
      nouveaux: n(brut['nouveaux']),
      sansDossier: n(brut['sansDossier']),
    );
  }

  /// Le nombre de personnes par phase.
  final Map<PhaseEnseignant, int> parPhase;

  /// Les candidatures « nouvelles ».
  final int nouveaux;

  /// Les comptes enseignants sans dossier de candidature (comptes a part).
  final int sansDossier;

  /// Le nombre de personnes de [phase], ou 0.
  int de(PhaseEnseignant phase) => parPhase[phase] ?? 0;
}

/// Une page de la liste, telle que le serveur la rend.
@immutable
class PageEnseignants {
  /// Cree une page.
  const PageEnseignants({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taillePage,
    this.compteurs = const CompteursEnseignants(),
  });

  /// Lit la reponse de `lister_enseignants`. Une reponse sans total ni page
  /// n'est pas une page : [FormatException], jamais une liste inventee.
  factory PageEnseignants.depuisJson(Object? brut) {
    if (brut is! Map) {
      throw const FormatException('Page d\'enseignants attendue.');
    }
    final Object? total = brut['total'];
    final Object? page = brut['page'];
    final Object? taille = brut['taillePage'];
    if (total is! int || page is! int || taille is! int || taille < 1) {
      throw const FormatException('Total, page ou taille de page absents.');
    }
    final Object? brutLignes = brut['lignes'];
    return PageEnseignants(
      lignes: List<LigneEnseignant>.unmodifiable(<LigneEnseignant>[
        if (brutLignes is List)
          for (final Object? b in brutLignes)
            if (LigneEnseignant.depuisJson(b) case final LigneEnseignant l) l,
      ]),
      total: total,
      page: page,
      taillePage: taille,
      compteurs: CompteursEnseignants.depuisJson(brut['compteursPhases']),
    );
  }

  /// Les lignes de la page, dans l'ordre du tri serveur.
  final List<LigneEnseignant> lignes;

  /// Le total reel du filtre.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de lignes par page, fixe par le serveur.
  final int taillePage;

  /// Les compteurs par phase.
  final CompteursEnseignants compteurs;

  /// Le nombre de pages, une au moins.
  int get pages => total <= 0 ? 1 : (total + taillePage - 1) ~/ taillePage;
}

/// Le tri, fait au serveur.
enum TriEnseignants {
  /// Derniere activite d'abord.
  activite('activite'),

  /// Arrivees recentes d'abord.
  recente('recente'),

  /// Par nom.
  nom('nom');

  const TriEnseignants(this.valeurSql);

  /// La valeur envoyee au serveur (`p_tri`).
  final String valeurSql;
}

/// Le filtre de la liste : seules les cles que `lister_enseignants` connait.
@immutable
class FiltreEnseignants {
  /// Cree le filtre.
  const FiltreEnseignants({
    this.recherche = '',
    this.phase,
    this.nouveau,
    this.partis = false,
  });

  /// Le texte cherche.
  final String recherche;

  /// La phase, ou `null` : toutes (les partis exceptes).
  final PhaseEnseignant? phase;

  /// Vrai : seulement les nouvelles candidatures.
  final bool? nouveau;

  /// Vrai : les enseignants partis sont montres aussi.
  final bool partis;

  /// Le texte cherche, sans les blancs de bord.
  String get rechercheNette => recherche.trim();

  /// Vrai quand aucun axe n'est pose.
  bool get estVide =>
      rechercheNette.isEmpty && phase == null && nouveau == null && !partis;

  /// Le meme filtre, un axe change.
  FiltreEnseignants avec({
    String? recherche,
    PhaseEnseignant? Function()? phase,
    bool? Function()? nouveau,
    bool? partis,
  }) => FiltreEnseignants(
    recherche: recherche ?? this.recherche,
    phase: phase == null ? this.phase : phase(),
    nouveau: nouveau == null ? this.nouveau : nouveau(),
    partis: partis ?? this.partis,
  );

  /// Le filtre tel que le serveur le lit : seules les cles posees.
  Map<String, Object> enJson() => <String, Object>{
    if (rechercheNette.isNotEmpty) 'recherche': rechercheNette,
    if (phase != null) 'phase': phase!.valeurSql,
    'nouveau': ?nouveau,
    if (partis) 'partis': true,
  };

  @override
  bool operator ==(Object other) =>
      other is FiltreEnseignants &&
      other.rechercheNette == rechercheNette &&
      other.phase == phase &&
      other.nouveau == nouveau &&
      other.partis == partis;

  @override
  int get hashCode => Object.hash(rechercheNette, phase, nouveau, partis);
}

/// La requete d'une page : le filtre, le tri et la page (a partir de 1).
@immutable
class RequeteEnseignants {
  /// Cree la requete.
  const RequeteEnseignants({
    this.filtre = const FiltreEnseignants(),
    this.tri = TriEnseignants.activite,
    this.page = 1,
  });

  /// Le filtre.
  final FiltreEnseignants filtre;

  /// Le tri.
  final TriEnseignants tri;

  /// La page.
  final int page;

  @override
  bool operator ==(Object other) =>
      other is RequeteEnseignants &&
      other.filtre == filtre &&
      other.tri == tri &&
      other.page == page;

  @override
  int get hashCode => Object.hash(filtre, tri, page);
}
