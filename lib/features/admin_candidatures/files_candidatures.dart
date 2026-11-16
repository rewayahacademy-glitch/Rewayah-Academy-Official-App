// BE-LISTE-2 : les files de la liste des candidatures.
//
// Les deux cartes « Qui attend quoi » et « A traiter » deviennent une seule
// rangee de puces : chaque file porte son nombre, une puce touchee choisit la
// file (une seule a la fois), la puce choisie est pleine. Les nombres viennent
// des deux lectures existantes (`attentes_recrutement()` et les alertes de
// `lister_candidatures`), rien n'est recalcule ni lu en plus.
//
// Une file qui compte zero n'est pas montree (« Toutes » reste). Une alerte que
// le serveur sait compter mais **pas filtrer** (`entretiensEnRetard`,
// `bloquees`, `confirmeesIndisponibles` : aucune cle de filtre) se montre en
// puce non touchable, jamais en puce qui ouvrirait une liste d'une autre
// longueur que son nombre.
//
// Les phrases d'explication de chaque file (« la plus ancienne depuis 1 jour »,
// « a valider dans le dossier ») vivent dans la feuille « Filtres », en petit,
// sous la file.
library;

import 'package:flutter/foundation.dart';

import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';

/// La phrase « depuis quand » d'une attente, ou `null` sans date.
String? depuisQuand(DateTime? plusAncien, DateTime maintenant) {
  if (plusAncien == null) return null;
  final Duration d = maintenant.difference(plusAncien);
  final a = t.admin.candidatures.attentes;
  // DUREE-INSECABLE : le nombre et son unite ne se separent jamais.
  if (d.inDays >= 1) {
    return LibellesGroupe.insecable(a.depuisJours(n: d.inDays));
  }
  if (d.inHours >= 1) {
    return LibellesGroupe.insecable(a.depuisHeures(n: d.inHours));
  }
  return LibellesGroupe.insecable(
    a.depuisMinutes(n: d.inMinutes < 1 ? 1 : d.inMinutes),
  );
}

/// Une file : sa puce et sa phrase.
@immutable
class FileCandidatures {
  /// Cree une file.
  const FileCandidatures({
    required this.cle,
    required this.libelle,
    required this.estChoisie,
    this.nombre,
    this.explication,
    this.alerteCreneau = false,
    this.appliquer,
  });

  /// Le nom stable de la file (cles des tests).
  final String cle;

  /// Le mot de la puce.
  final String libelle;

  /// Le nombre de personnes, ou `null` (nombre pas encore connu).
  final int? nombre;

  /// La phrase d'explication, dite en petit dans la feuille « Filtres ».
  final String? explication;

  /// Vrai : aucun creneau d'entretien n'est ouvert (icone d'alerte).
  final bool alerteCreneau;

  /// Pose la file sur un filtre (les autres axes, recherche comprise, restent),
  /// ou `null` : la puce ne se touche pas.
  final FiltreCandidatures Function(FiltreCandidatures)? appliquer;

  /// Vrai quand le filtre courant est cette file.
  final bool Function(FiltreCandidatures) estChoisie;
}

/// Les morceaux non vides d'une explication, un par ligne, ou `null`.
String? _phrase(List<String?> morceaux) {
  final String s = morceaux.whereType<String>().join('\n');
  return s.isEmpty ? null : s;
}

/// Le filtre d'une file d'etat : cet etat, en cours, hors pause.
FiltreCandidatures _etat(FiltreCandidatures f, EtatCandidature e) => f.avec(
  etat: () => e,
  pieceEnAttente: () => null,
  enPause: () => false,
  issue: () => IssueCandidature.enCours,
  nouveau: () => null,
);

/// Les files, dans l'ordre de la rangee.
///
/// [totalToutes] est le nombre de « Toutes » quand il est connu (lu sur une
/// page sans filtre), sinon la puce n'a pas de nombre.
List<FileCandidatures> filesDe({
  required AttentesRecrutement? attentes,
  required CompteursAlertes alertes,
  required int? totalToutes,
  required DateTime maintenant,
  int compteurNouveaux = 0,
}) {
  final e = t.admin.candidatures.etats;
  final a = t.admin.candidatures.attentes;
  final al = t.admin.candidatures.alertes;

  FileCandidatures? etat(
    EtatCandidature etat,
    String libelle, {
    String? aide,
    bool alerteCreneau = false,
  }) {
    final Attente? at = attentes?.etat(etat);
    if (at == null || at.nombre == 0) return null;
    return FileCandidatures(
      cle: 'etat-${etat.valeurSql}',
      libelle: libelle,
      nombre: at.nombre,
      explication: _phrase(<String?>[
        depuisQuand(at.plusAncien, maintenant),
        aide,
      ]),
      alerteCreneau: alerteCreneau,
      appliquer: (FiltreCandidatures f) => _etat(f, etat),
      estChoisie: (FiltreCandidatures f) =>
          f.etat == etat && f.pieceEnAttente == null && f.nouveau != true,
    );
  }

  final int creneaux = attentes?.creneauxOuverts ?? 0;
  final List<FileCandidatures?> files = <FileCandidatures?>[
    // NOUVEAU-LISTE : les candidatures « nouvelles » (moins de 7 jours, dossier
    // jamais ouvert), comptees par le serveur (`compteurNouveaux`) : en cours,
    // pause comprise, comme le filtre `nouveau` que la file pose.
    if (compteurNouveaux > 0)
      FileCandidatures(
        cle: 'nouveaux',
        libelle: t.recrutement.file.nouveaux,
        nombre: compteurNouveaux,
        appliquer: (FiltreCandidatures f) => f.avec(
          nouveau: () => true,
          etat: () => null,
          pieceEnAttente: () => null,
          enPause: () => null,
          issue: () => IssueCandidature.enCours,
        ),
        estChoisie: (FiltreCandidatures f) => f.nouveau == true,
      ),
    etat(EtatCandidature.enExamen, e.enExamen),
    if (attentes != null && attentes.pieceAValider.nombre > 0)
      FileCandidatures(
        cle: 'piece',
        libelle: t.recrutement.file.pieceCourt,
        nombre: attentes.pieceAValider.nombre,
        explication: _phrase(<String?>[
          depuisQuand(attentes.pieceAValider.plusAncien, maintenant),
          a.pieceAide,
        ]),
        // La cle serveur `pieceEnAttente` (PR 505) compte exactement ce que
        // la puce annonce : en cours, hors pause.
        appliquer: (FiltreCandidatures f) => f.avec(
          pieceEnAttente: () => true,
          etat: () => null,
          enPause: () => false,
          issue: () => IssueCandidature.enCours,
          nouveau: () => null,
        ),
        estChoisie: (FiltreCandidatures f) =>
            f.pieceEnAttente == true && f.nouveau != true,
      ),
    etat(
      EtatCandidature.entretienAPlanifier,
      e.entretienAPlanifier,
      aide: creneaux == 0 ? a.aucunCreneau : a.creneauxOuverts(n: creneaux),
      alerteCreneau: creneaux == 0,
    ),
    etat(EtatCandidature.entretienPlanifie, e.entretienPlanifie),
    etat(EtatCandidature.decisionEnAttente, e.decisionEnAttente),
    etat(EtatCandidature.aCompleter, e.aCompleter),
    etat(
      EtatCandidature.paiementNonDisponible,
      e.versementImpossible,
      aide: a.versementAide,
    ),
    if (attentes != null && attentes.enPause > 0)
      FileCandidatures(
        cle: 'pause',
        libelle: e.enPause,
        nombre: attentes.enPause,
        appliquer: (FiltreCandidatures f) => f.avec(
          etat: () => null,
          pieceEnAttente: () => null,
          enPause: () => true,
          issue: () => IssueCandidature.enCours,
          nouveau: () => null,
        ),
        estChoisie: (FiltreCandidatures f) =>
            f.enPause == true &&
            f.etat == null &&
            f.pieceEnAttente == null &&
            f.nouveau != true,
      ),
    FileCandidatures(
      cle: 'toutes',
      libelle: t.admin.candidatures.filtres.toutes,
      nombre: totalToutes,
      appliquer: (FiltreCandidatures f) => f.avec(
        etat: () => null,
        pieceEnAttente: () => null,
        enPause: () => null,
        issue: () => null,
        nouveau: () => null,
      ),
      estChoisie: (FiltreCandidatures f) =>
          f.etat == null &&
          f.pieceEnAttente == null &&
          f.enPause == null &&
          f.issue == null &&
          f.nouveau == null,
    ),
    // Les alertes que le serveur compte sans savoir les filtrer : seulement
    // si le nombre n'est pas zero, jamais touchables.
    if ((alertes.entretiensEnRetard ?? 0) > 0)
      FileCandidatures(
        cle: 'alerte-retard',
        libelle: al.entretiensEnRetard,
        nombre: alertes.entretiensEnRetard,
        estChoisie: (FiltreCandidatures _) => false,
      ),
    if ((alertes.bloquees ?? 0) > 0)
      FileCandidatures(
        cle: 'alerte-bloquees',
        libelle: al.bloquees,
        nombre: alertes.bloquees,
        estChoisie: (FiltreCandidatures _) => false,
      ),
    if ((alertes.confirmeesIndisponibles ?? 0) > 0)
      FileCandidatures(
        cle: 'alerte-confirmees',
        libelle: t.recrutement.file.confirmeesIndisponibles,
        nombre: alertes.confirmeesIndisponibles,
        estChoisie: (FiltreCandidatures _) => false,
      ),
  ];
  return <FileCandidatures>[...files.whereType<FileCandidatures>()];
}

/// Le nombre de filtres poses **en dehors des files** (ce que dit l'icone
/// « Filtres ») : la recherche et les files n'y comptent pas.
int nombreFiltresPoses(FiltreCandidatures f, List<FileCandidatures> files) {
  final bool uneFile = files.any(
    (FileCandidatures x) => x.cle != 'toutes' && x.estChoisie(f),
  );
  int n = f.nombreAxes - (f.rechercheNette.isEmpty ? 0 : 1);
  if (uneFile) {
    // Une file pose jusqu'a trois axes (etat ou piece ou pause, issue, pause) :
    // ils ne sont pas des « filtres » de plus.
    n -= <Object?>[
      f.etat,
      f.pieceEnAttente,
      f.enPause,
      f.issue,
      if (f.nouveau == true) f.nouveau,
    ].where((Object? x) => x != null).length;
  }
  return n < 0 ? 0 : n;
}
