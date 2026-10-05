import '../i18n/strings.g.dart';

/// Les motifs proposes par `SelecteurMotif`, ecran par ecran (FORM-L1, L7).
///
/// Redigés par l'agent a partir du vocabulaire deja present dans l'app et dans
/// `docs/current` (01, 06, 07), decides par delegation le 05/10. La source de
/// chaque motif est ecrite dans `docs/current/FORM-L1-7-13_MOTIFS.md`.
///
/// **Le motif reste une chaine** : la puce choisie part telle quelle vers la
/// meme RPC qu'avant. Ces listes ne decident de rien ; « Autre » reste ouvert.
abstract final class MotifsProposes {
  /// Ajouter un eleve a une classe (Operations > Classes).
  static List<String> ajoutEleve() => <String>[
    t.motifs.ajoutEleve.diagnostic,
    t.motifs.ajoutEleve.attente,
    t.motifs.ajoutEleve.transfert,
    t.motifs.ajoutEleve.famille,
  ];

  /// Retirer un eleve d'une classe.
  static List<String> retraitEleve() => <String>[
    t.motifs.retraitEleve.famille,
    t.motifs.retraitEleve.transfert,
    t.motifs.retraitEleve.ecartNiveau,
    t.motifs.retraitEleve.finInscription,
  ];

  /// Clore une classe.
  static List<String> clotureClasse() => <String>[
    t.motifs.clotureClasse.finCycle,
    t.motifs.clotureClasse.remplissage,
    t.motifs.clotureClasse.transfert,
    t.motifs.clotureClasse.remplacement,
    t.motifs.clotureClasse.parErreur,
  ];

  /// Attribuer sur une heure que la famille n'a pas posee.
  static List<String> attribution() => <String>[
    t.motifs.attribution.confirmee,
    t.motifs.attribution.aucuneCommune,
    t.motifs.attribution.continuite,
    t.motifs.attribution.famille,
  ];

  /// Refuser une demande (la phrase part a la partie qui a demande).
  static List<String> refusDemande() => <String>[
    t.motifs.refusDemande.aucunEnseignant,
    t.motifs.refusDemande.exceptionnel,
    t.motifs.refusDemande.reglePlateforme,
    t.motifs.refusDemande.plafond,
    t.motifs.refusDemande.insuffisant,
  ];

  /// Poser une regle individuelle.
  static List<String> poserRegle() => <String>[
    t.motifs.poserRegle.famille,
    t.motifs.poserRegle.pedagogique,
    t.motifs.poserRegle.age,
    t.motifs.poserRegle.charge,
    t.motifs.poserRegle.parErreur,
  ];

  /// Revenir a la regle de la plateforme.
  static List<String> cloreSurcharge() => <String>[
    t.motifs.cloreSurcharge.termine,
    t.motifs.cloreSurcharge.famille,
    t.motifs.cloreSurcharge.changement,
    t.motifs.cloreSurcharge.parErreur,
  ];

  /// Annuler une evaluation.
  static List<String> annulationEvaluation() => <String>[
    t.motifs.annulationEvaluation.absenceEleve,
    t.motifs.annulationEvaluation.absenceEnseignant,
    t.motifs.annulationEvaluation.pasPret,
    t.motifs.annulationEvaluation.report,
    t.motifs.annulationEvaluation.parErreur,
  ];

  /// Changer le niveau d'un eleve (promotion).
  static List<String> changementNiveau() => <String>[
    t.motifs.changementNiveau.reussie,
    t.motifs.changementNiveau.stable,
    t.motifs.changementNiveau.enseignant,
    t.motifs.changementNiveau.reevaluation,
    t.motifs.changementNiveau.placement,
  ];

  /// Poser un blocage.
  static List<String> blocage() => <String>[
    t.motifs.blocage.prerequis,
    t.motifs.blocage.renforcement,
    t.motifs.blocage.aRevoir,
    t.motifs.blocage.absences,
  ];

  /// Poser une derogation.
  static List<String> derogation() => <String>[
    t.motifs.derogation.aucunGroupe,
    t.motifs.derogation.avance,
    t.motifs.derogation.enseignant,
    t.motifs.derogation.direction,
  ];

  /// Clore une exception (blocage ou derogation).
  static List<String> cloreException() => <String>[
    t.motifs.cloreException.stables,
    t.motifs.cloreException.groupe,
    t.motifs.cloreException.inutile,
    t.motifs.cloreException.parErreur,
  ];

  /// Decider un placement apres diagnostic.
  static List<String> placement() => <String>[
    t.motifs.placement.debutant,
    t.motifs.placement.lecture,
    t.motifs.placement.declaratif,
    t.motifs.placement.procheNiveau,
    t.motifs.placement.provisoire,
  ];

  /// Refuser un dossier (la phrase est montree a la personne concernee).
  static List<String> refusDossier() => <String>[
    t.motifs.refusDossier.illisible,
    t.motifs.refusDossier.expiree,
    t.motifs.refusDossier.nom,
    t.motifs.refusDossier.nonTransmise,
    t.motifs.refusDossier.accord,
  ];

  /// Corriger une presence a la main.
  static List<String> presenceCorrigee() => <String>[
    t.motifs.presenceCorrigee.nonDetectee,
    t.motifs.presenceCorrigee.reseau,
    t.motifs.presenceCorrigee.retard,
    t.motifs.presenceCorrigee.appareil,
    t.motifs.presenceCorrigee.parErreur,
  ];

  /// Excuser une absence.
  static List<String> presenceExcusee() => <String>[
    t.motifs.presenceExcusee.prevenue,
    t.motifs.presenceExcusee.reseau,
    t.motifs.presenceExcusee.conge,
    t.motifs.presenceExcusee.familiale,
  ];

  /// Demande du tuteur : changer d'enseignant.
  static List<String> reglageEnseignant() => <String>[
    t.motifs.reglageEnseignant.horaire,
    t.motifs.reglageEnseignant.niveau,
    t.motifs.reglageEnseignant.fuseau,
    t.motifs.reglageEnseignant.fratrie,
  ];

  /// Demande du tuteur : changer la duree des cours.
  static List<String> reglageDuree() => <String>[
    t.motifs.reglageDuree.tropLongue,
    t.motifs.reglageDuree.plusDeTemps,
    t.motifs.reglageDuree.pause,
    t.motifs.reglageDuree.horaire,
  ];

  /// Demande du tuteur : changer la duree minimale payable.
  static List<String> reglageMinimum() => <String>[
    t.motifs.reglageMinimum.ecourtees,
    t.motifs.reglageMinimum.reseau,
    t.motifs.reglageMinimum.duree,
    t.motifs.reglageMinimum.horaire,
  ];

  /// Phrases-types d'un signalement enseignant, par categorie (L7). La
  /// categorie se donne par sa valeur SQL (`pedagogique`, `presence`,
  /// `technique`, `changement`, `autre`) ; « autre » n'a pas de phrase-type,
  /// seul le champ libre s'affiche.
  static List<String> signalement(String categorie) => switch (categorie) {
    'pedagogique' => <String>[
      t.motifs.signalement.pedagogique.renforcement,
      t.motifs.signalement.pedagogique.revision,
      t.motifs.signalement.pedagogique.regularite,
      t.motifs.signalement.pedagogique.echange,
    ],
    'presence' => <String>[
      t.motifs.signalement.presence.absences,
      t.motifs.signalement.presence.retards,
      t.motifs.signalement.presence.prevenir,
    ],
    'technique' => <String>[
      t.motifs.signalement.technique.son,
      t.motifs.signalement.technique.essai,
      t.motifs.signalement.technique.camera,
    ],
    'changement' => <String>[
      t.motifs.signalement.changement.classe,
      t.motifs.signalement.changement.niveau,
      t.motifs.signalement.changement.suite,
    ],
    _ => const <String>[],
  };
}
