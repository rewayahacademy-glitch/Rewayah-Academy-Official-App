/// BE-LISTE : ce que la liste des candidatures dit dans son adresse.
///
/// Le filtre, le tri et la page vivent dans l'adresse (comme Comptes) : un
/// retour, un rechargement ou un lien partage retrouvent la meme liste.
/// **Le texte cherche n'y est pas** : c'est un nom de personne, il n'a rien a
/// faire dans une adresse ni dans l'historique du navigateur (relecture du
/// coordinateur, 16/11/2026) ; la page le garde en memoire pour le retour d'un
/// dossier. Lecture et ecriture sont des fonctions pures. Une valeur inconnue
/// est ignoree : une adresse partagee et perimee ne doit jamais casser la page.
library;

import '../../core/agent/travail_praxis.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';

/// Les parametres d'adresse que la liste possede : tout autre parametre est
/// laisse tel quel. `q` (l'ancien lien avec recherche) y reste pour etre
/// retire de l'adresse a la premiere ecriture, jamais lu.
const Set<String> clesAdresseCandidatures = <String>{
  'q',
  'etape',
  'etat',
  'issue',
  'pause',
  'versement',
  'pays',
  'genre',
  'domaine',
  'niveau',
  'dispo',
  'accord',
  'piece',
  'nouveau',
  'complet',
  'pile',
  'etiquette',
  // PERSONNES-UNE-PAGE (d) : les filtres de la feuille qui n'avaient pas de
  // cle (ils ne survivaient ni au rechargement ni au passage au suivant).
  'responsable',
  'majorite',
  'ijaza',
  'langue',
  'riwaya',
  'public',
  'jours',
  'heure_de',
  'heure_a',
  'jours_min',
  'tri',
  'page',
};

/// Ce que l'adresse dit : la requete de la liste.
RequeteCandidatures requeteDepuisAdresse(Map<String, String> q) {
  T? choix<T extends Enum>(List<T> valeurs, String cle) {
    for (final T v in valeurs) {
      if (v.name == q[cle]) return v;
    }
    return null;
  }

  bool? booleen(String cle) => switch (q[cle]) {
    'oui' => true,
    'non' => false,
    _ => null,
  };

  String? texte(String cle) {
    final String? v = q[cle];
    return v == null || v.isEmpty ? null : v;
  }

  int? entier(String cle, int min, int max) {
    final int? n = int.tryParse(q[cle] ?? '');
    return n == null || n < min || n > max ? null : n;
  }

  // Les jours (1 a 7), separes par des virgules, sans doublon, dans l'ordre.
  final List<int> jours = <int>{
    for (final String j in (q['jours'] ?? '').split(','))
      if (int.tryParse(j) case final int n when n >= 1 && n <= 7) n,
  }.toList()..sort();

  final int? page = int.tryParse(q['page'] ?? '');
  return RequeteCandidatures(
    filtre: FiltreCandidatures(
      etape: choix(EtapeCandidature.values, 'etape'),
      etat: choix(EtatCandidature.values, 'etat'),
      issue: choix(IssueCandidature.values, 'issue'),
      enPause: booleen('pause'),
      paiement: choix(EtatVersement.values, 'versement'),
      paysResidence: texte('pays'),
      genre: switch (q['genre']) {
        'male' || 'female' => q['genre'],
        _ => null,
      },
      competenceDomaine: texte('domaine'),
      competenceNiveauMin: choix(NiveauCompetence.values, 'niveau'),
      competenceDisponibilite: choix(DisponibiliteMission.values, 'dispo'),
      competenceAccord: booleen('accord'),
      pieceEnAttente: booleen('piece'),
      nouveau: booleen('nouveau'),
      // PE-LISTE-CANDIDATURES : seules les valeurs du serveur sont lues (la
      // page « Le travail de Praxis » y mene par ces deux cles).
      dossierComplet: booleen('complet'),
      pilePraxis: _valeurPermise(
        q['pile'],
        PilePraxis.values.map((PilePraxis p) => p.sql),
      ),
      etiquettePraxis: _valeurPermise(
        q['etiquette'],
        EtiquettePraxis.values.map((EtiquettePraxis e) => e.sql),
      ),
      responsable: _valeurPermise(q['responsable'], const <String>[
        'moi',
        'aucun',
      ]),
      majorite: _valeurPermise(q['majorite'], const <String>[
        'attestee',
        'non_attestee',
        'moins_18',
      ]),
      ijaza: texte('ijaza'),
      langueExplication: texte('langue'),
      riwaya: texte('riwaya'),
      publicVise: texte('public'),
      jours: jours.isEmpty ? null : jours,
      heureMin: entier('heure_de', 0, 23),
      heureMax: entier('heure_a', 1, 24),
      joursMin: entier('jours_min', 1, 7),
    ),
    tri: choix(TriCandidatures.values, 'tri') ?? TriCandidatures.activite,
    page: page == null || page < 1 ? 1 : page,
  );
}

/// Ce que la requete dit dans l'adresse : seulement ce qui est pose (le tri par
/// defaut et la premiere page n'y sont pas).
Map<String, String> requeteEnAdresse(RequeteCandidatures r) {
  final FiltreCandidatures f = r.filtre;
  String oui(bool b) => b ? 'oui' : 'non';
  return <String, String>{
    if (f.etape != null) 'etape': f.etape!.name,
    if (f.etat != null) 'etat': f.etat!.name,
    if (f.issue != null) 'issue': f.issue!.name,
    if (f.enPause != null) 'pause': oui(f.enPause!),
    if (f.paiement != null) 'versement': f.paiement!.name,
    if (f.paysResidence != null) 'pays': f.paysResidence!,
    if (f.genre != null) 'genre': f.genre!,
    if (f.competenceDomaine != null) 'domaine': f.competenceDomaine!,
    if (f.competenceNiveauMin != null) 'niveau': f.competenceNiveauMin!.name,
    if (f.competenceDisponibilite != null)
      'dispo': f.competenceDisponibilite!.name,
    if (f.competenceAccord != null) 'accord': oui(f.competenceAccord!),
    if (f.pieceEnAttente != null) 'piece': oui(f.pieceEnAttente!),
    if (f.nouveau != null) 'nouveau': oui(f.nouveau!),
    if (f.dossierComplet != null) 'complet': oui(f.dossierComplet!),
    if (f.pilePraxis != null) 'pile': f.pilePraxis!,
    if (f.etiquettePraxis != null) 'etiquette': f.etiquettePraxis!,
    if (f.responsable != null) 'responsable': f.responsable!,
    if (f.majorite != null) 'majorite': f.majorite!,
    if (f.ijaza != null) 'ijaza': f.ijaza!,
    if (f.langueExplication != null) 'langue': f.langueExplication!,
    if (f.riwaya != null) 'riwaya': f.riwaya!,
    if (f.publicVise != null) 'public': f.publicVise!,
    if (f.jours != null && f.jours!.isNotEmpty) 'jours': f.jours!.join(','),
    if (f.heureMin != null) 'heure_de': '${f.heureMin}',
    if (f.heureMax != null) 'heure_a': '${f.heureMax}',
    if (f.joursMin != null) 'jours_min': '${f.joursMin}',
    if (r.tri != TriCandidatures.activite) 'tri': r.tri.name,
    if (r.page > 1) 'page': '${r.page}',
  };
}

String? _valeurPermise(String? v, Iterable<String> permises) =>
    v != null && permises.contains(v) ? v : null;
