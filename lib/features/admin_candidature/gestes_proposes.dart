// Les gestes que la page propose pour une candidature : la prochaine action
// (le seul bouton plein) et le menu des autres gestes (`ADM-21`, fiche :
// « Gestes du menu (rendus seulement s'ils sont permis depuis l'etat) »).
//
// **Une commodite de presentation, pas une regle.** Le serveur reste l'autorite :
// il refuse tout geste interdit par `TransitionInterdite`, et l'ecran dit ce
// refus. Cette table ne fait que ne pas proposer ce que le serveur refuserait a
// coup sur depuis l'etape, l'etat, l'issue, la pause, la restriction et le
// versement qu'il a lui-meme rendus (les sources permises de CAND-L2A1,
// `private.candidature_gestes_regles`). Elle ne calcule aucun controle : les
// controles faux sont nommes par le refus du serveur, jamais devines ici.
//
// Un geste que le serveur n'ouvre pas (`capacites_candidatures().gestes`, une
// cle absente vaut faux) n'est jamais propose. Un widget lit cette capacite, il
// ne lit pas un role.
library;

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';

/// Ce que la page propose : la prochaine action, et les autres gestes.
class GestesProposes {
  /// Cree la proposition.
  const GestesProposes({
    this.principal,
    this.autres = const <GesteCandidature>[],
  });

  /// La prochaine action : le seul bouton plein, ou `null` quand elle attend la
  /// personne ou qu'aucun geste ouvert ne convient.
  final GesteCandidature? principal;

  /// Les autres gestes permis, dans l'ordre du menu.
  final List<GesteCandidature> autres;

  /// Aucun geste n'est propose.
  bool get vide => principal == null && autres.isEmpty;
}

/// Depuis cet etat, le serveur peut-il accepter ce geste ? (Sources permises de
/// CAND-L2A1, restreintes aux gestes que CAND-L2A2 ouvre.)
bool gestePermis(GesteCandidature geste, DetailCandidature detail) =>
    gestePermisPourLigne(
      geste,
      detail.ligne,
      restrictionCause: detail.restrictionCause,
    );

/// La meme table, lue sur **l'etat d'une ligne de la file** (LISTES-1) : le menu
/// d'une ligne n'a pas lu le dossier, il propose ce que la ligne permet, puis
/// l'ecran relit le dossier et rappelle [gestePermis] avant d'ouvrir la
/// feuille. **Une seule table**, pas une copie.
///
/// [restrictionCause] est la cause d'une restriction : la ligne ne la porte pas
/// (elle n'est que dans le dossier). Sans elle, la confirmation d'un moyen de
/// versement d'une candidature confirmee sous restriction n'est pas proposee
/// depuis la ligne : elle se fait depuis le dossier, qui la lit.
bool gestePermisPourLigne(
  GesteCandidature geste,
  LigneCandidature l, {
  String? restrictionCause,
}) {
  final bool enCours = l.issue == IssueCandidature.enCours;
  final bool sansPause = enCours && !l.enPause;
  final EtapeCandidature? etape = l.etape;
  final bool avantSalle3 =
      etape == EtapeCandidature.recue ||
      etape == EtapeCandidature.invitee ||
      etape == EtapeCandidature.prequalification ||
      etape == EtapeCandidature.verifications;
  final bool enExamen =
      etape == EtapeCandidature.prequalification &&
      l.etat == EtatCandidature.enExamen;
  switch (geste) {
    case GesteCandidature.demanderComplement:
      return sansPause && (enExamen || etape == EtapeCandidature.verifications);
    case GesteCandidature.cloreComplement:
      return sansPause && etape == EtapeCandidature.verifications;
    case GesteCandidature.admettreVerifications:
      return sansPause && enExamen;
    case GesteCandidature.confirmerMoyenPaiement:
      return sansPause &&
          l.paiement == EtatVersement.aVerifier &&
          (enExamen ||
              (etape == EtapeCandidature.confirmee &&
                  l.restreinte &&
                  restrictionCause == 'paiement'));
    case GesteCandidature.infirmerMoyenPaiement:
      return sansPause &&
          enExamen &&
          (l.paiement == EtatVersement.aVerifier ||
              l.paiement == EtatVersement.compatible);
    case GesteCandidature.mettreEnPause:
      return sansPause && etape != null;
    case GesteCandidature.leverPause:
      return enCours && l.enPause && etape != null;
    case GesteCandidature.refuser:
    case GesteCandidature.consignerRetrait:
      return enCours && avantSalle3;
    case GesteCandidature.rouvrir:
      return !enCours && !l.enPause && avantSalle3;
    case GesteCandidature.definirResponsable:
      return sansPause && etape != null;
  }
}

/// La prochaine action selon l'etat (fiche `ADM-21`, « Prochaine action, selon
/// l'etat »), parmi les gestes que le serveur ouvre : en pause, lever la pause ;
/// en examen, confirmer le moyen de versement a verifier, puis, le versement
/// confirme, admettre. Ailleurs, aucune : la raison s'ecrit.
GesteCandidature? _prochaine(
  LigneCandidature l,
  bool Function(GesteCandidature) permis,
) {
  if (l.issue != IssueCandidature.enCours) {
    return null;
  }
  if (l.enPause) {
    return GesteCandidature.leverPause;
  }
  if (permis(GesteCandidature.confirmerMoyenPaiement)) {
    return GesteCandidature.confirmerMoyenPaiement;
  }
  if (permis(GesteCandidature.admettreVerifications) &&
      l.paiement == EtatVersement.compatible) {
    return GesteCandidature.admettreVerifications;
  }
  return null;
}

/// L'ordre du menu des autres gestes.
const List<GesteCandidature> _ordreMenu = <GesteCandidature>[
  GesteCandidature.demanderComplement,
  GesteCandidature.cloreComplement,
  GesteCandidature.confirmerMoyenPaiement,
  GesteCandidature.infirmerMoyenPaiement,
  GesteCandidature.admettreVerifications,
  GesteCandidature.mettreEnPause,
  GesteCandidature.leverPause,
  GesteCandidature.refuser,
  GesteCandidature.consignerRetrait,
  GesteCandidature.rouvrir,
  GesteCandidature.definirResponsable,
];

/// Les gestes proposes pour [detail], selon les capacites [caps] que le serveur
/// rend. Sans le droit de decider, rien n'est propose.
GestesProposes gestesProposes(
  DetailCandidature detail,
  CapacitesCandidatures caps,
) => gestesProposesPourLigne(
  detail.ligne,
  caps,
  restrictionCause: detail.restrictionCause,
);

/// Les gestes proposes pour une **ligne de la file** : la meme table et le meme
/// ordre que [gestesProposes] (LISTES-1). Voir [gestePermisPourLigne] pour la
/// cause de restriction.
///
/// **L'ordre est celui de la fiche** ([_ordreMenu]), inchange : la fiche est un
/// ecran hors du perimetre des listes (relecture du code R-8). Le menu d'une
/// ligne range lui-meme les gestes **destructifs** a la suite, en un seul groupe
/// (`gestesDuMenuLigne`).
///
/// [sansResponsable] : « Choisir le responsable » n'est pas propose. Le menu
/// d'une ligne le masque tant que la liste des responsables n'est pas servie
/// (`CAND-BR-04`) : elle se lit par candidature, et un geste qui ne peut pas
/// aboutir n'est pas offert.
GestesProposes gestesProposesPourLigne(
  LigneCandidature ligne,
  CapacitesCandidatures caps, {
  String? restrictionCause,
  bool sansResponsable = false,
}) {
  if (!caps.peutDecider) {
    return const GestesProposes();
  }
  bool permis(GesteCandidature g) =>
      gestePermisPourLigne(g, ligne, restrictionCause: restrictionCause);
  bool ouvert(GesteCandidature g) => caps.geste(g.capacite) && permis(g);
  final GesteCandidature? prochaine = _prochaine(ligne, permis);
  final GesteCandidature? principal = prochaine != null && ouvert(prochaine)
      ? prochaine
      : null;
  final List<GesteCandidature> autres = <GesteCandidature>[
    for (final GesteCandidature g in _ordreMenu)
      if (g != principal &&
          ouvert(g) &&
          !(sansResponsable && g == GesteCandidature.definirResponsable))
        g,
  ];
  return GestesProposes(principal: principal, autres: autres);
}
