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

/// La meme table, lue sur **l'etat d'une ligne de la file** (LISTES-1,
/// REPRISE-CAND-4) : le menu d'une ligne n'a pas lu le dossier, il propose ce
/// que la ligne permet ; au choix, l'ecran relit le dossier et rappelle
/// [gestePermis] avant d'ouvrir la feuille. **Une seule table**, pas une copie.
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
      // COMPLEMENT-SALLE-EXAMEN (T7) : aussi quand le paiement n'est pas
      // disponible (variante 4 du serveur, le seul code `versement`).
      return sansPause &&
          (enExamen ||
              etape == EtapeCandidature.verifications ||
              (etape == EtapeCandidature.prequalification &&
                  l.etat == EtatCandidature.paiementNonDisponible));
    case GesteCandidature.modifierComplement:
      // COMPLEMENT-SALLE-EXAMEN (T6) : la regle `demander_complement`
      // variante 3 du serveur (a_completer, complement en cours).
      return sansPause &&
          etape == EtapeCandidature.prequalification &&
          l.etat == EtatCandidature.aCompleter &&
          l.complementEnCours;
    case GesteCandidature.annulerComplement:
      return sansPause &&
          etape == EtapeCandidature.prequalification &&
          l.etat == EtatCandidature.aCompleter &&
          l.complementEnCours;
    case GesteCandidature.cloreComplement:
      // Le serveur refuse « aucun_complement » sans demande en cours : le
      // geste n'est rendu que si la ligne dit qu'une demande court.
      return sansPause &&
          etape == EtapeCandidature.verifications &&
          l.complementEnCours;
    case GesteCandidature.admettreVerifications:
      // GESTES-RAISON (pilote, 16/11/2026) : la regle du serveur est « en
      // examen ET versement compatible ». Un bouton qui ne peut pas aboutir
      // n'est pas rendu (K-56) ; la phrase sous la rangee dit pourquoi.
      return sansPause && enExamen && l.paiement == EtatVersement.compatible;
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
    case GesteCandidature.debloquerVersement:
      // La regle `debloquer_versement` du serveur (20261128500100) : en Salle
      // d'examen, en examen ou versement impossible, en cours, hors pause.
      // Aucune condition sur le moyen : le serveur recalcule le versement.
      return sansPause &&
          etape == EtapeCandidature.prequalification &&
          (l.etat == EtatCandidature.enExamen ||
              l.etat == EtatCandidature.paiementNonDisponible);
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
    case GesteCandidature.validerPiece:
      // Les sources permises de `valider_piece` (CAND-L2A1) : en Salle de
      // verification et d'entretien, la decision attendue, en cours, hors
      // pause. Les sept controles restent ceux du serveur.
      return sansPause &&
          etape == EtapeCandidature.verifications &&
          l.etat == EtatCandidature.decisionEnAttente;
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
  if (permis(GesteCandidature.validerPiece)) {
    return GesteCandidature.validerPiece;
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

/// Pourquoi la rangee des gestes montre ce qu'elle montre (GESTES-RAISON,
/// directeur, 16/11/2026 : « je n'arrive pas a comprendre le pattern de ces
/// 3 boutons, parfois je les vois parfois non »). **Une seule fonction**,
/// calculee sur le meme etat que la table des gestes : l'ecran n'a pas sa
/// propre copie de la regle.
enum RaisonGestes {
  /// Le compte ne peut pas decider de ce dossier.
  droit,

  /// Le dossier est ferme (refuse, retire, termine).
  fermee,

  /// Le dossier est en pause.
  pause,

  /// La personne doit encore completer son dossier.
  attenteCandidat,

  /// Aucun moyen de versement possible pour l'instant.
  versementImpossible,

  /// Un moyen de versement reste a confirmer.
  versementAConfirmer,

  /// Des points du dossier manquent avant d'accepter.
  controlesManquants,

  /// En Salle d'examen, tout est en ordre pour decider.
  pretADecider,

  /// Retenu pour l'entretien, a planifier.
  entretienAPlanifier,

  /// Entretien planifie, pas encore tenu.
  entretienPlanifie,

  /// Entretien tenu, la decision attend la direction.
  decisionAttendue,

  /// Aucune decision a prendre a cette etape.
  aucuneDecision,
}

/// La raison de la rangee des gestes pour [l]. [accepterPropose] : le geste
/// d'accepter est propose ; [controlesBloquants] : des controles faux le
/// retiennent (les noms viennent du dossier, jamais devines ici).
RaisonGestes raisonDesGestes(
  LigneCandidature l, {
  required bool peutDecider,
  required bool accepterPropose,
  required bool controlesBloquants,
}) {
  if (!peutDecider) return RaisonGestes.droit;
  if (l.issue != IssueCandidature.enCours) return RaisonGestes.fermee;
  if (l.enPause) return RaisonGestes.pause;
  switch (l.etat) {
    case EtatCandidature.aCompleter:
      return RaisonGestes.attenteCandidat;
    case EtatCandidature.paiementNonDisponible:
      return RaisonGestes.versementImpossible;
    case EtatCandidature.enExamen:
      if (l.paiement == EtatVersement.aVerifier) {
        return RaisonGestes.versementAConfirmer;
      }
      if (l.paiement != EtatVersement.compatible) {
        return RaisonGestes.versementImpossible;
      }
      return controlesBloquants && !accepterPropose
          ? RaisonGestes.controlesManquants
          : RaisonGestes.pretADecider;
    case EtatCandidature.entretienAPlanifier:
      return RaisonGestes.entretienAPlanifier;
    case EtatCandidature.entretienPlanifie:
      return RaisonGestes.entretienPlanifie;
    case EtatCandidature.decisionEnAttente:
      return controlesBloquants && !accepterPropose
          ? RaisonGestes.controlesManquants
          : RaisonGestes.decisionAttendue;
    case null:
      return RaisonGestes.aucuneDecision;
  }
}

/// L'ordre du menu des autres gestes.
const List<GesteCandidature> _ordreMenu = <GesteCandidature>[
  GesteCandidature.demanderComplement,
  GesteCandidature.cloreComplement,
  GesteCandidature.modifierComplement,
  GesteCandidature.annulerComplement,
  GesteCandidature.confirmerMoyenPaiement,
  GesteCandidature.infirmerMoyenPaiement,
  GesteCandidature.debloquerVersement,
  GesteCandidature.admettreVerifications,
  GesteCandidature.validerPiece,
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
/// ordre que [gestesProposes] (LISTES-1, REPRISE-CAND-4). Voir
/// [gestePermisPourLigne] pour la cause de restriction.
///
/// [sansResponsable] : « Choisir le responsable » n'est pas propose. Le menu
/// d'une ligne le masque tant que la liste des responsables n'est pas servie
/// (`CAND-BR-04`) : un geste qui ne peut pas aboutir n'est pas offert.
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
  return GestesProposes(
    principal: principal,
    autres: <GesteCandidature>[
      for (final GesteCandidature g in _ordreMenu)
        if (g != principal &&
            ouvert(g) &&
            !(sansResponsable && g == GesteCandidature.definirResponsable))
          g,
    ],
  );
}
