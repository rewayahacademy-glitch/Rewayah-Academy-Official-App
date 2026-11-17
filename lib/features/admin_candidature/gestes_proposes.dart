// Les gestes que la page propose pour une candidature : la prochaine action
// (le seul bouton plein) et le menu des autres gestes (`ADM-21`, fiche :
// « Gestes du menu (rendus seulement s'ils sont permis depuis l'etat) »).
//
// **Le serveur dit quels gestes sont permis, l'ecran ne recalcule plus la regle**
// (GESTES-DU-SERVEUR, 16/11/2026 ; carte des gestes T5, T10, T14). Chaque ligne
// de candidature porte `gestes` : les gestes que le moteur (etape, etat, issue,
// pause, condition) ET le droit de la session (cote, mission et son perimetre)
// permettent. Un geste est rendu seulement s'il est servi ET connu de l'ecran :
// un nom que l'ecran ne sait pas faire (dispenser l'entretien, restreindre...)
// n'est pas montre. Une ligne sans `gestes` n'en montre aucun (K-56).
//
// Deux choses restent a l'ecran, parce que le serveur ne les sert pas :
//   * la garde « versement compatible » d'Admettre (GESTES-RAISON, pilote,
//     16/11/2026, tant que le serveur ne sert pas les controles) ;
//   * la **prochaine action** et l'ordre du menu (une presentation, pas une regle).
//
// Un geste que le serveur n'ouvre pas au compte
// (`capacites_candidatures().gestes`, une cle absente vaut faux) n'est jamais
// propose. Un widget lit cette capacite, il ne lit pas un role.
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

/// Le serveur permet-il ce geste sur ce dossier ? (La cle `gestes` de sa
/// ligne.)
bool gestePermis(GesteCandidature geste, DetailCandidature detail) =>
    gestePermisPourLigne(geste, detail.ligne);

/// Le meme controle, lu sur **la ligne de la file** : le menu d'une ligne
/// propose ce que le serveur sert pour elle ; au choix, l'ecran relit le
/// dossier et rappelle [gestePermis] avant d'ouvrir la feuille. **Une seule
/// source** : la cle `gestes` de la ligne.
///
/// Seule garde de l'ecran : Admettre exige un versement compatible
/// (GESTES-RAISON : un bouton qui ne peut pas aboutir n'est pas rendu, K-56),
/// parce que le serveur ne sert pas encore les controles.
bool gestePermisPourLigne(GesteCandidature geste, LigneCandidature l) {
  // COMPLEMENT-SALLE-EXAMEN : le serveur sert le meme nom `demander_complement`
  // pour demander (en examen, en paiement non disponible, en salle de
  // verification) et pour MODIFIER une demande en cours (variante 3, seule
  // permise en `a_completer`). L'ecran les nomme par l'etat que la ligne porte :
  // une presentation, pas une regle.
  final bool enACompleter =
      l.etape == EtapeCandidature.prequalification &&
      l.etat == EtatCandidature.aCompleter;
  if (geste == GesteCandidature.demanderComplement && enACompleter) {
    return false;
  }
  if (geste == GesteCandidature.modifierComplement) {
    return enACompleter && l.gestes.contains('demander_complement');
  }
  if (geste != GesteCandidature.modifierComplement && !l.sert(geste)) {
    return false;
  }
  if (geste == GesteCandidature.admettreVerifications) {
    return l.paiement == EtatVersement.compatible;
  }
  return true;
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
  GesteCandidature.dispenserEntretien,
  GesteCandidature.restreindre,
  GesteCandidature.demanderVerificationPiece,
  GesteCandidature.demanderVerificationVersement,
  GesteCandidature.leverRestriction,
  GesteCandidature.refaireEntretien,
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
) => gestesProposesPourLigne(detail.ligne, caps);

/// Les gestes proposes pour une **ligne de la file** : la meme table et le meme
/// ordre que [gestesProposes] (LISTES-1, REPRISE-CAND-4).
///
/// [sansResponsable] : « Choisir le responsable » n'est pas propose. Le menu
/// d'une ligne le masque tant que la liste des responsables n'est pas servie
/// (`CAND-BR-04`) : un geste qui ne peut pas aboutir n'est pas offert.
GestesProposes gestesProposesPourLigne(
  LigneCandidature ligne,
  CapacitesCandidatures caps, {
  bool sansResponsable = false,
}) {
  if (!caps.peutDecider) {
    return const GestesProposes();
  }
  bool permis(GesteCandidature g) => gestePermisPourLigne(g, ligne);
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
