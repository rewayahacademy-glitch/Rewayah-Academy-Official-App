// Les etats et vocabulaires fermes du Comptable V1 (CPT-F, spec
// `REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1` §15, §24.1, §25, §28, §38,
// §42, §49 ; `20_comptable/CPT-BR.md` §1).
//
// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A) :
// une voie qui a besoin d'une valeur de plus ecrit une ligne pour CPT-FUS,
// sans modifier. Chaque enumeration est rendue par la source ; l'ecran
// affiche la valeur, il ne la deduit jamais (DR-19). Les mots a l'ecran
// viennent de `pastilles_comptable.dart` (`comptable.statuts.*`), jamais du
// nom Dart.

/// Les quinze etats d'un paiement sortant (spec §15), lisibles sans couleur.
enum EtatPaiementSortant {
  /// La remuneration n'est pas encore calculee.
  aCalculer,

  /// Calculee depuis les donnees canoniques, pas encore verifiee.
  calcule,

  /// A verifier avant d'etre prete.
  aVerifier,

  /// Le beneficiaire n'a pas de methode de paiement complete (§27).
  infosManquantes,

  /// La methode de paiement doit etre verifiee avant tout payout (§19).
  verificationRequise,

  /// Pret a payer : montant calcule, methode verifiee, delegation respectee.
  pretAPayer,

  /// Paiement sensible : « Validation supplementaire requise » (§21.4).
  validationRequise,

  /// Soumis au prestataire, pas encore parti.
  soumis,

  /// En transit chez le prestataire.
  enTransit,

  /// Reussi, confirme par le prestataire (jamais sur simple appui, §5.3).
  reussi,

  /// Echoue chez le prestataire.
  echoue,

  /// A relancer (le beneficiaire doit agir).
  aRelancer,

  /// Annule.
  annule,

  /// Rembourse ou retourne par le prestataire.
  retourne,

  /// Indisponible : la source ne sait pas le dire.
  indisponible,
}

/// Les neuf etats d'un encaissement (spec §24.1). « Confirme » seulement
/// apres le prestataire (§24.3).
enum EtatEncaissement {
  /// En attente de confirmation.
  enAttente,

  /// Confirme par le prestataire.
  confirme,

  /// Echoue.
  echoue,

  /// Rembourse en totalite.
  rembourse,

  /// Partiellement rembourse.
  partiellementRembourse,

  /// Conteste par le payeur.
  conteste,

  /// Chargeback impose par le reseau de paiement.
  chargeback,

  /// Confirme, pas encore rapproche.
  aRapprocher,

  /// Rapproche.
  rapproche,
}

/// Les six etats d'un rapprochement (spec §25).
enum EtatRapprochement {
  /// Rapproche automatiquement par la source.
  automatique,

  /// Proposition a verifier par le Comptable.
  aVerifier,

  /// Rapproche et confirme.
  rapproche,

  /// Deux candidats contradictoires.
  conflit,

  /// Aucune correspondance trouvee.
  sansCorrespondance,

  /// Doublon potentiel : jamais silencieux (§47).
  doublonPotentiel,
}

/// Les etats du profil de paiement d'un beneficiaire (spec §38), plus
/// « Invitation envoyee » du beneficiaire externe sans compte (§18).
enum EtatProfilPaiement {
  /// Aucune methode de paiement.
  aucunMoyen,

  /// Methode incomplete.
  incomplet,

  /// Nouvelle methode en verification (§19).
  enVerification,

  /// Methode verifiee.
  verifie,

  /// Payout suspendu (par le personnel, selon capacite, §16.2).
  suspendu,

  /// Le beneficiaire doit agir.
  actionRequise,

  /// Beneficiaire externe : invitation securisee envoyee, methode a saisir
  /// par lui seul (§18, DR-16).
  invitationEnvoyee,
}

/// Les cinq retours du `PayoutCapabilityPort` pour un corridor (spec §42).
/// Le frontend ne suppose jamais un pays, une devise, un operateur ou un
/// solde ; il affiche ce que la source rend.
enum CapacitePayout {
  /// `supported`.
  prisEnCharge,

  /// `unsupported`.
  nonPrisEnCharge,

  /// `temporarilyUnavailable`.
  temporairementIndisponible,

  /// `needsVerification`.
  verificationRequise,

  /// `insufficientProviderBalance`.
  soldePrestataireInsuffisant,
}

/// Les actions qu'une source peut permettre sur un objet (ensemble ferme,
/// `CPT-BR.md` §1). Un ecran n'affiche un bouton que si l'action est dans
/// `actionsPermises` ; jamais `if (role == ...)`.
enum ActionFinance {
  /// Payer une obligation prete.
  payer,

  /// Demander une validation pour un paiement ou un mouvement sensible.
  demanderValidation,

  /// Relancer un beneficiaire par Messages metier (§27).
  relancer,

  /// Demander au beneficiaire une mise a jour de ses coordonnees.
  demanderMiseAJour,

  /// Suspendre un payout.
  suspendre,

  /// Signaler un ecart sur une ligne de calcul (§13.4).
  signalerEcart,

  /// Alimenter la Reserve strategique selon la politique (§9.5).
  alimenter,

  /// Transferer entre deux coffres (§10).
  transferer,

  /// Creer une obligation de contractuel (§22.3).
  creerObligation,

  /// Approuver une obligation.
  approuver,

  /// Rapprocher une transaction (§25).
  rapprocher,

  /// Executer un remboursement selon la politique (§26).
  rembourser,
}

/// Pourquoi une action attendue n'est pas permise (`CPT-BR.md` §1). L'ecran
/// affiche la raison rendue, il ne la deduit jamais (DR-19).
enum RaisonBlocage {
  /// Le beneficiaire est la personne connectee : « Traitement par un autre
  /// responsable requis » (§20, R-FIN-15).
  autoPaiement,

  /// Paiement ou mouvement sensible : validation supplementaire (§21.4).
  validationRequise,

  /// Informations de paiement manquantes (§27).
  infosManquantes,

  /// Methode de paiement a verifier (§19).
  verificationRequise,

  /// Hors de la delegation du Comptable (§21.2).
  horsDelegation,

  /// Fournisseur indisponible pour ce corridor (§42).
  fournisseurIndisponible,

  /// Fonds insuffisants dans le coffre d'origine.
  fondsInsuffisants,

  /// Doublon potentiel non leve (§47).
  doublonPotentiel,

  /// Obligation manuelle non approuvee (§22.3).
  nonApprouvee,

  /// La capacite n'existe pas pour ce compte.
  capaciteAbsente,
}

/// Les deux listes d'Aujourd'hui (DR-10) : une ligne n'appartient qu'a une
/// seule des deux, la source dit laquelle.
enum ListeAttention {
  /// « A traiter » : ce qui attend une action du Comptable (payer, relancer,
  /// rapprocher, approuver). Chaque ligne ouvre l'ecran canonique filtre.
  aTraiter,

  /// « Alertes » : les risques sans action immediate.
  alerte,
}

/// Les douze types d'alerte du Comptable (spec §28), avec la liste
/// d'Aujourd'hui que chacun rejoint par defaut (DR-10). La source peut
/// rendre une autre liste ; cette valeur est celle de la demonstration.
enum TypeAlerteComptable {
  /// Enseignants a payer.
  enseignantsAPayer(ListeAttention.aTraiter),

  /// Contractuels a echeance.
  contractuelsAEcheance(ListeAttention.aTraiter),

  /// Informations de paiement manquantes (« Relancer »).
  infosManquantes(ListeAttention.aTraiter),

  /// Payout echoue.
  payoutEchoue(ListeAttention.aTraiter),

  /// Paiement d'une famille echoue.
  paiementFamilleEchoue(ListeAttention.aTraiter),

  /// Transaction non rapprochee.
  transactionNonRapprochee(ListeAttention.aTraiter),

  /// Remboursement en attente.
  remboursementEnAttente(ListeAttention.aTraiter),

  /// Reserve strategique sous l'objectif.
  reserveSousObjectif(ListeAttention.alerte),

  /// Solde prestataire insuffisant.
  soldePrestataireInsuffisant(ListeAttention.alerte),

  /// Methode de paiement modifiee recemment (§19, §21.4).
  methodeModifieeRecemment(ListeAttention.alerte),

  /// Doublon potentiel.
  doublonPotentiel(ListeAttention.alerte),

  /// Validation supplementaire requise.
  validationRequise(ListeAttention.aTraiter);

  const TypeAlerteComptable(this.listeParDefaut);

  /// La liste d'Aujourd'hui que ce type rejoint quand la source n'en dit
  /// pas d'autre.
  final ListeAttention listeParDefaut;
}

/// Les etats de la Reserve strategique (spec §49, §9.7 ; CPT-BR-12).
enum EtatReserve {
  /// Objectif atteint.
  atteint,

  /// Sous l'objectif.
  sousObjectif,

  /// Au-dessus de l'objectif.
  depassement,

  /// Regle d'alimentation inactive.
  regleInactive,

  /// Une alimentation est prevue.
  alimentationPrevue,

  /// Un mouvement sensible (retrait) attend sa validation.
  mouvementSensible,
}

/// Les sept coffres canoniques de tresorerie (spec §8.1), dans l'ordre de
/// la spec, qui est aussi l'ordre d'affichage de W04.
enum Coffre {
  /// Argent encaisse lie a des prestations non acquises. Protege.
  fondsClientsEngages(protege: true),

  /// Obligations de remuneration calculees et dues. Protege.
  paieADecaisser(protege: true),

  /// Infrastructure, abonnements, fonctions fixes. Protege.
  chargesEssentielles(protege: true),

  /// Provision fiscale, sociale, reglementaire. Protege.
  taxesObligations(protege: true),

  /// Coffre de continuite et de securite (§9). Protege.
  reserveStrategique(protege: true),

  /// Argent engage dans une operation non confirmee.
  enTransit(protege: false),

  /// Ce qui est reellement disponible (§11).
  tresorerieLibre(protege: false);

  const Coffre({required this.protege});

  /// Vrai pour un coffre protege : une sortie en est sensible (§10.3) et sa
  /// somme n'est jamais comptee libre (§8).
  final bool protege;
}

/// Le type d'un beneficiaire d'un paiement sortant (spec §13, §22).
enum TypeBeneficiaire {
  /// Un enseignant, remunere par obligation calculee.
  enseignant,

  /// Un contractuel, recurrent ou ponctuel.
  contractuel,
}

/// Le type d'une obligation de contractuel (spec §22.1).
enum TypeObligationContractuel {
  /// Recurrente, calculee si le contrat est connu.
  recurrente,

  /// Ponctuelle, montant saisi a la creation, fige apres approbation.
  ponctuelle,
}

/// Les etats d'une obligation de contractuel (spec §22.3 ; CPT-BR-08).
enum EtatObligationContractuel {
  /// Brouillon, pas encore soumis.
  brouillon,

  /// A approuver par un approbateur distinct de l'auteur.
  aApprouver,

  /// Approuvee : montant fige, elle devient une obligation payable.
  approuvee,

  /// Refusee avec motif.
  refusee,

  /// Payee (etat final de son obligation payable).
  payee,

  /// Annulee.
  annulee,
}

/// Les etats d'un remboursement ou d'un avoir (spec §26 ; CPT-BR-15).
enum EtatRemboursement {
  /// Demande.
  demande,

  /// La politique exige une approbation.
  approbationRequise,

  /// Approuve, a executer.
  approuve,

  /// Execute (etat rendu par le prestataire).
  execute,

  /// Refuse avec motif.
  refuse,
}

/// Les etats d'une demande de validation (CPT-BR-09).
enum EtatDemandeValidation {
  /// En attente d'une autre personne que le demandeur.
  enAttente,

  /// Validee.
  validee,

  /// Refusee avec motif.
  refusee,
}

/// Les filtres de la liste « Paiements a effectuer » (`?filtre=`), dans
/// l'ordre de `Routes.filtresPaiementsComptable`.
enum FiltrePaiements {
  /// Prets a payer.
  prets,

  /// Informations de paiement manquantes.
  infos,

  /// Verification requise.
  verification,

  /// Validation supplementaire requise.
  validation,

  /// En retard sur l'echeance.
  retard,
}
