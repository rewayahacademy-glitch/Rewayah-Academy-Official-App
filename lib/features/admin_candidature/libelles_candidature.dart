// Les mots de la candidature ouverte (`ADM-21`) : chaque geste, controle,
// evenement, modele de message, element de complement et refus du serveur se dit
// par son libelle, **jamais par son code** (`CATALOGUE_ECRANS_RECRUTEMENT.md`
// 5.4). Ce fichier ne decide rien : il traduit ce que le serveur a rendu en mots.
// Un code que cette version ne connait pas se dit par une phrase neutre ; il
// ne s'affiche jamais tel quel.
library;

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../admin_candidatures/libelles_candidatures.dart';

/// Le libelle d'un geste : le verbe et son objet.
String libelleGeste(GesteCandidature geste) {
  final g = t.admin.candidatures.gestes;
  return switch (geste) {
    GesteCandidature.admettreVerifications => g.admettre,
    GesteCandidature.validerPiece => g.accueillir,
    GesteCandidature.confirmerMoyenPaiement => g.confirmerMoyen,
    GesteCandidature.infirmerMoyenPaiement => g.ecarterMoyen,
    GesteCandidature.debloquerVersement => g.debloquerVersement,
    GesteCandidature.demanderComplement => g.demanderComplement,
    GesteCandidature.cloreComplement => g.cloreComplement,
    GesteCandidature.modifierComplement => g.modifierComplement,
    GesteCandidature.annulerComplement => g.annulerComplement,
    GesteCandidature.mettreEnPause => g.mettreEnPause,
    GesteCandidature.leverPause => g.leverPause,
    GesteCandidature.refuser => g.refuser,
    GesteCandidature.consignerRetrait => g.retrait,
    GesteCandidature.rouvrir => g.rouvrir,
    GesteCandidature.definirResponsable => g.responsable,
  };
}

/// Ce qui arrive quand le geste est fait, en une phrase (K-58 : la consequence
/// se dit avant le choix).
String libelleConsequence(GesteCandidature geste) {
  final c = t.admin.candidatures.consequences;
  return switch (geste) {
    GesteCandidature.admettreVerifications => c.admettre,
    GesteCandidature.validerPiece => c.accueillir,
    GesteCandidature.confirmerMoyenPaiement => c.confirmerMoyen,
    GesteCandidature.infirmerMoyenPaiement => c.ecarterMoyen,
    GesteCandidature.debloquerVersement => c.debloquerVersement,
    GesteCandidature.demanderComplement => c.demanderComplement,
    GesteCandidature.cloreComplement => c.cloreComplement,
    GesteCandidature.modifierComplement => c.modifierComplement,
    GesteCandidature.annulerComplement => c.annulerComplement,
    GesteCandidature.mettreEnPause => c.mettreEnPause,
    GesteCandidature.leverPause => c.leverPause,
    GesteCandidature.refuser => c.refuser,
    GesteCandidature.consignerRetrait => c.retrait,
    GesteCandidature.rouvrir => c.rouvrir,
    GesteCandidature.definirResponsable => c.responsable,
  };
}

/// Le retour local d'un geste reussi : dit seulement apres la reponse du
/// serveur.
String libelleRetour(GesteCandidature geste) {
  final r = t.admin.candidatures.retours;
  return switch (geste) {
    GesteCandidature.admettreVerifications => r.admettre,
    GesteCandidature.validerPiece => r.accueillir,
    GesteCandidature.confirmerMoyenPaiement => r.confirmerMoyen,
    GesteCandidature.infirmerMoyenPaiement => r.ecarterMoyen,
    GesteCandidature.debloquerVersement => r.debloquerVersement,
    GesteCandidature.demanderComplement => r.demanderComplement,
    GesteCandidature.cloreComplement => r.cloreComplement,
    GesteCandidature.modifierComplement => r.modifierComplement,
    GesteCandidature.annulerComplement => r.annulerComplement,
    GesteCandidature.mettreEnPause => r.mettreEnPause,
    GesteCandidature.leverPause => r.leverPause,
    GesteCandidature.refuser => r.refuser,
    GesteCandidature.consignerRetrait => r.retrait,
    GesteCandidature.rouvrir => r.rouvrir,
    GesteCandidature.definirResponsable => r.responsable,
  };
}

/// Le nom d'un controle du serveur.
String libelleControle(String nom) {
  final c = t.admin.candidatures.controles.noms;
  return switch (nom) {
    'compte_conforme' => c.compteConforme,
    'paiement_compatible' => t.recrutement.paiement.compatible,
    'cadre_religieux' => c.cadreReligieux,
    'questionnaire_complet' => c.questionnaireComplet,
    'entretien_conclu' => c.entretienConclu,
    'evaluation_validee' => c.evaluationValidee,
    'accords_signes' => c.accordsSignes,
    'profil_renseigne' => c.profilRenseigne,
    'profil_unique' => c.profilUnique,
    'aucune_restriction' => c.aucuneRestriction,
    'piece_validee' => c.pieceValidee,
    'complement_clos' => c.complementClos,
    _ => c.inconnu,
  };
}

/// La cause d'un controle faux, ou « Cause non precisee ».
String libelleCauseControle(String nom, String? cause) {
  final c = t.admin.candidatures.controles.causes;
  if (nom == 'paiement_compatible') {
    return switch (cause) {
      'inconnu' => t.recrutement.paiement.inconnu,
      'a_verifier' => t.recrutement.paiement.aVerifier,
      'incompatible' => t.recrutement.paiement.incompatible,
      _ => c.inconnue,
    };
  }
  return switch (cause) {
    'supprime' => c.supprime,
    'role' => c.role,
    'statut' => c.statut,
    'expire' => c.expire,
    'engagement' => c.engagement,
    'non_publie' => c.nonPublie,
    'non_accepte' => c.nonAccepte,
    'questionnaire_absent' => c.questionnaireAbsent,
    'absent' => c.absent,
    'perime' => c.perime,
    'incomplet' => c.incomplet,
    'entretien_non_disponible' => c.entretienNonDisponible,
    'entretien_non_tenu' => c.entretienNonTenu,
    'avis_non_favorable' => c.avisNonFavorable,
    'constat_incomplet' => c.constatIncomplet,
    'reponses_incompletes' => c.reponsesIncompletes,
    // AUDIT-PORTAIL-CANDIDAT (14/11/2026) : le premier accord manquant
    // (`accords_signes`) et l'etat de la piece (`piece_validee`), dits en mots.
    'teacher_nda' => c.contratNonSigne,
    'recording_and_control_notice' => c.avisNonAccepte,
    'teacher_conduct_code' => c.conduiteNonAcceptee,
    'teacher_religious_framework' => c.cadreNonAccepte,
    'compte_absent' => c.compteAbsent,
    'piece_absente' => c.pieceAbsente,
    'piece_a_verifier' => c.pieceAVerifier,
    'piece_a_redeposer' => c.pieceARedeposer,
    // ACCUEIL-SEPARE : un complement demande bloque l'accueil.
    'complement_en_cours' => c.complementEnCours,
    _ => c.inconnue,
  };
}

/// Un controle et sa cause, en une ligne : « Nom : cause ».
String controleEtCause(String nom, String? cause) =>
    t.admin.candidatures.detail.controleLigne(
      nom: libelleControle(nom),
      cause: libelleCauseControle(nom, cause),
    );

/// Le nom d'un modele de message par son code, ou « Autre message » pour un
/// code que cette version ne connait pas.
String libelleModele(String code) {
  final m = t.admin.candidatures.modeles;
  return switch (code) {
    'refus_general' => m.refusGeneral,
    'refus_niveau' => m.refusNiveau,
    'refus_besoins' => m.refusBesoins,
    'refus_sans_reponse' => m.refusSansReponse,
    'pause_attente_besoin' => m.pauseAttenteBesoin,
    'pause_attente_informations' => m.pauseAttenteInformations,
    'pause_demande_candidat' => m.pauseDemandeCandidat,
    'pause_general' => m.pauseGeneral,
    _ => m.autre,
  };
}

/// Le nom d'un element de complement par son code, ou `null` pour un code que
/// cette version ne connait pas : il n'est alors pas propose.
///
/// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : en salle 1, la direction
/// redemande tout ce que le candidat fournit ; les documents et accords se
/// nomment du point de vue de la direction (« La pièce d'identité »).
String? libelleElementComplement(String code) => switch (code) {
  'langues' => t.recrutement.questionnaire.langues,
  'recitation' => t.recrutement.questionnaire.recitation,
  'disponibilites' => t.recrutement.questionnaire.disponibilites,
  'publics' => t.recrutement.questionnaire.publics,
  'versement' => t.recrutement.questionnaire.versement,
  'cadre_religieux' => t.recrutement.portail.elementCadre,
  'contrat' => t.recrutement.portail.elementContrat,
  'avis' => t.attente.carteAccuse,
  'code_conduite' => t.admin.candidatures.complement.codeConduite,
  'piece_identite' => t.admin.candidatures.complement.piece,
  'photo' => t.admin.candidatures.complement.photo,
  'accord_publication' => t.admin.candidatures.complement.accordPublication,
  _ => null,
};

/// Les codes de complement qui sont des documents ou des accords (et non une
/// carte du questionnaire), dans l'ordre du parcours du candidat.
const List<String> codesDocumentsEtAccords = <String>[
  'cadre_religieux',
  'contrat',
  'avis',
  'code_conduite',
  'piece_identite',
  'photo',
  'accord_publication',
];

/// L'etat d'une candidature tel que le serveur le nomme dans un refus, dit par
/// son libelle : l'issue, la pause, puis l'etat dans l'etape, puis la salle.
String libelleEtatCourant({
  required IssueCandidature issue,
  required bool enPause,
  EtapeCandidature? etape,
  EtatCandidature? etat,
}) {
  final r = t.admin.candidatures.etats;
  if (issue == IssueCandidature.refusee) {
    return r.refusee;
  }
  if (issue == IssueCandidature.retiree) {
    return r.retiree;
  }
  if (enPause) {
    return r.enPause;
  }
  return libelleEtatDansEtape(etat)?.libelle ??
      switch (etape) {
        EtapeCandidature.recue => r.gardee,
        EtapeCandidature.invitee => r.invitee,
        _ => libelleSalle(etape) ?? r.indisponible,
      };
}

/// La provenance d'une candidature.
String libelleProvenance(ProvenanceCandidature provenance) {
  final p = t.admin.candidatures.etats.provenance;
  return switch (provenance) {
    ProvenanceCandidature.importee => p.formulairesImportes,
    ProvenanceCandidature.lienPublic => p.lienPublic,
    ProvenanceCandidature.invitation => p.invitation,
  };
}

/// La restriction d'une candidature confirmee, avec sa cause quand le serveur
/// la donne.
String libelleRestriction(String? cause) {
  final r = t.admin.candidatures.etats;
  return switch (cause) {
    'piece' => r.restreintePiece,
    'paiement' => r.restreinteVersement,
    'manuelle' => r.restreinteDirection,
    _ => r.restreinte,
  };
}

/// Qui a fait un evenement, par sa qualite.
String libelleAuteur(AuteurEvenement auteur) {
  final a = t.admin.candidatures.historique.auteur;
  return switch (auteur) {
    AuteurEvenement.direction => a.direction,
    AuteurEvenement.candidat => a.personne,
    AuteurEvenement.systeme => a.automatique,
  };
}

/// Le type d'un evenement, ou « Evenement » pour un type inconnu.
String libelleTypeEvenement(String type) {
  final e = t.admin.candidatures.historique.types;
  return switch (type) {
    'creee' => e.creee,
    'transition' => e.transition,
    'pause' => e.pause,
    'reprise' => e.reprise,
    'restriction' => e.restriction,
    'levee_restriction' => e.leveeRestriction,
    'responsable' => e.responsable,
    'controle' => e.controle,
    'import' => e.importation,
    'correction_import' => e.correctionImport,
    'lecture_contact' => e.lectureContact,
    'lecture_hors_portee' => e.lectureHorsPortee,
    'entretien' => e.entretien,
    'engagement' => e.engagement,
    'prevenu' => e.prevenu,
    _ => e.inconnu,
  };
}

/// Le changement d'un evenement, en mots (« De "X" a "Y" »), ou `null` quand il
/// ne change ni l'etape, ni l'etat, ni l'issue.
String? libelleChangement(EvenementCandidature e) {
  String? situation(
    EtapeCandidature? etape,
    EtatCandidature? etat,
    IssueCandidature? issue,
  ) {
    if (etape == null && etat == null && issue == null) {
      return null;
    }
    return libelleEtatCourant(
      issue: issue ?? IssueCandidature.enCours,
      enPause: false,
      etape: etape,
      etat: etat,
    );
  }

  final String? avant = situation(e.etapeAvant, e.etatAvant, e.issueAvant);
  final String? apres = situation(e.etapeApres, e.etatApres, e.issueApres);
  if (avant == null || apres == null || avant == apres) {
    return null;
  }
  return t.admin.candidatures.historique.deA(avant: avant, apres: apres);
}

/// Un instant de l'historique : « Le 20 oct. 2026 a 09:00 », dans le fuseau de
/// la personne qui lit.
String instantHistorique(DateTime instant) {
  // HEURES-PROFIL H2 : le fuseau du profil de la personne qui lit.
  // dateCourteCandidature appelle toLocal() : on lui passe le jour du profil
  // en local ([jourChezMoi]), jamais la valeur de chezMoi (marquee UTC).
  final String heure = heureChezMoi(instant);
  return t.admin.candidatures.historique.le(
    date: dateCourteCandidature(jourChezMoi(instant)),
    heure: isolerSens(heure),
  );
}

/// Le message que la direction lit pour un refus du serveur : ce qui n'a pas
/// ete fait, pourquoi, quoi faire (K-59), jamais un code.
String messageRefus(RefusGeste refus) {
  final e = t.admin.candidatures.erreurs;
  return switch (refus) {
    ConflitGeste() => e.conflit,
    GesteInterdit(
      :final EtapeCandidature? etape,
      :final EtatCandidature? etat,
      :final IssueCandidature issue,
      :final bool enPause,
    ) =>
      e.transition(
        etat: libelleEtatCourant(
          issue: issue,
          enPause: enPause,
          etape: etape,
          etat: etat,
        ),
      ),
    ControlesNonSatisfaits(:final controles) => e.controles(
      controles: controles
          .map(
            (({String nom, String? cause}) c) =>
                controleEtCause(c.nom, c.cause),
          )
          .join(t.admin.candidatures.detail.separateurControles),
    ),
    MotifRequis() => e.motifRequis,
    ModeleRequis() => e.modeleRequis,
    ModeleInconnu() => e.modeleInconnu,
    ElementsRequis() => e.elementsRequis,
    ElementsInvalides() => e.elementsInvalides,
    AucunComplement() => e.aucunComplement,
    RepriseInvalide() => e.repriseInvalide,
    DateDemandeInvalide() => e.dateDemande,
    MoyenNonConfirmable(:final bool nonDeclare) =>
      nonDeclare ? e.moyenNonDeclare : e.moyenNonConfirmable,
    MoyenNonDeclare() => e.moyenNonDeclare,
    ResponsableInvalide() => e.responsableInvalide,
    CleReutilisee() => e.cleReutilisee,
    GesteNonConfirme() => e.nonConfirme,
  };
}
