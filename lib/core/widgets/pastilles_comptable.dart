import 'package:flutter/material.dart';

import '../comptable/statuts_comptable.dart';
import '../i18n/strings.g.dart';
import 'status_pill.dart';

/// Les habits de [StatusPill] du Comptable V1 (`FinancialStatusChip`,
/// `FinanceProviderStatus`, spec §39 ; CPT-F) : un mot **et** une famille de
/// ton, jamais la couleur seule (spec §15 « chaque statut doit etre lisible
/// sans couleur »). `PastilleFinanciere` (profil eleve) n'est pas etendue.
///
/// Chaque fonction `libelle...` rend le mot seul, pour une cellule de table
/// ou une phrase ; chaque `ton...` sa famille. **Fichier gele apres CPT-F**
/// (`20_comptable/02_DECOUPAGE.md`, liste A).

/// Le mot d'un etat de paiement sortant (§15).
String libellePaiementSortant(EtatPaiementSortant etat) {
  final p = t.comptable.statuts.paiement;
  return switch (etat) {
    EtatPaiementSortant.aCalculer => p.aCalculer,
    EtatPaiementSortant.calcule => p.calcule,
    EtatPaiementSortant.aVerifier => p.aVerifier,
    EtatPaiementSortant.infosManquantes => p.infosManquantes,
    EtatPaiementSortant.verificationRequise => p.verificationRequise,
    EtatPaiementSortant.pretAPayer => p.pretAPayer,
    EtatPaiementSortant.validationRequise => p.validationRequise,
    EtatPaiementSortant.soumis => p.soumis,
    EtatPaiementSortant.enTransit => p.enTransit,
    EtatPaiementSortant.reussi => p.reussi,
    EtatPaiementSortant.echoue => p.echoue,
    EtatPaiementSortant.aRelancer => p.aRelancer,
    EtatPaiementSortant.annule => p.annule,
    EtatPaiementSortant.retourne => p.retourne,
    EtatPaiementSortant.indisponible => p.indisponible,
  };
}

/// La famille d'un etat de paiement sortant.
TonEtat tonPaiementSortant(EtatPaiementSortant etat) => switch (etat) {
  EtatPaiementSortant.aCalculer ||
  EtatPaiementSortant.calcule ||
  EtatPaiementSortant.annule ||
  EtatPaiementSortant.retourne ||
  EtatPaiementSortant.indisponible => TonEtat.neutre,
  EtatPaiementSortant.pretAPayer ||
  EtatPaiementSortant.soumis ||
  EtatPaiementSortant.enTransit => TonEtat.accent,
  EtatPaiementSortant.reussi => TonEtat.succes,
  EtatPaiementSortant.aVerifier ||
  EtatPaiementSortant.infosManquantes ||
  EtatPaiementSortant.verificationRequise ||
  EtatPaiementSortant.validationRequise ||
  EtatPaiementSortant.aRelancer => TonEtat.avertissement,
  EtatPaiementSortant.echoue => TonEtat.alerte,
};

/// Le mot d'un etat d'encaissement (§24.1).
String libelleEncaissement(EtatEncaissement etat) {
  final e = t.comptable.statuts.encaissement;
  return switch (etat) {
    EtatEncaissement.enAttente => e.enAttente,
    EtatEncaissement.confirme => e.confirme,
    EtatEncaissement.echoue => e.echoue,
    EtatEncaissement.rembourse => e.rembourse,
    EtatEncaissement.partiellementRembourse => e.partiellementRembourse,
    EtatEncaissement.conteste => e.conteste,
    EtatEncaissement.chargeback => e.chargeback,
    EtatEncaissement.aRapprocher => e.aRapprocher,
    EtatEncaissement.rapproche => e.rapproche,
  };
}

/// La famille d'un etat d'encaissement.
TonEtat tonEncaissement(EtatEncaissement etat) => switch (etat) {
  EtatEncaissement.enAttente ||
  EtatEncaissement.rembourse ||
  EtatEncaissement.partiellementRembourse => TonEtat.neutre,
  EtatEncaissement.aRapprocher => TonEtat.accent,
  EtatEncaissement.confirme || EtatEncaissement.rapproche => TonEtat.succes,
  EtatEncaissement.conteste => TonEtat.avertissement,
  EtatEncaissement.echoue || EtatEncaissement.chargeback => TonEtat.alerte,
};

/// Le mot d'un etat de rapprochement (§25).
String libelleRapprochement(EtatRapprochement etat) {
  final r = t.comptable.statuts.rapprochement;
  return switch (etat) {
    EtatRapprochement.automatique => r.automatique,
    EtatRapprochement.aVerifier => r.aVerifier,
    EtatRapprochement.rapproche => r.rapproche,
    EtatRapprochement.conflit => r.conflit,
    EtatRapprochement.sansCorrespondance => r.sansCorrespondance,
    EtatRapprochement.doublonPotentiel => r.doublonPotentiel,
  };
}

/// La famille d'un etat de rapprochement.
TonEtat tonRapprochement(EtatRapprochement etat) => switch (etat) {
  EtatRapprochement.sansCorrespondance => TonEtat.neutre,
  EtatRapprochement.automatique => TonEtat.accent,
  EtatRapprochement.rapproche => TonEtat.succes,
  EtatRapprochement.aVerifier => TonEtat.avertissement,
  EtatRapprochement.conflit ||
  EtatRapprochement.doublonPotentiel => TonEtat.alerte,
};

/// Le mot d'un etat de profil de paiement (§38, §18).
String libelleProfilPaiement(EtatProfilPaiement etat) {
  final p = t.comptable.statuts.profil;
  return switch (etat) {
    EtatProfilPaiement.aucunMoyen => p.aucunMoyen,
    EtatProfilPaiement.incomplet => p.incomplet,
    EtatProfilPaiement.enVerification => p.enVerification,
    EtatProfilPaiement.verifie => p.verifie,
    EtatProfilPaiement.suspendu => p.suspendu,
    EtatProfilPaiement.actionRequise => p.actionRequise,
    EtatProfilPaiement.invitationEnvoyee => p.invitationEnvoyee,
  };
}

/// La famille d'un etat de profil de paiement.
TonEtat tonProfilPaiement(EtatProfilPaiement etat) => switch (etat) {
  EtatProfilPaiement.aucunMoyen ||
  EtatProfilPaiement.invitationEnvoyee => TonEtat.neutre,
  EtatProfilPaiement.enVerification => TonEtat.accent,
  EtatProfilPaiement.verifie => TonEtat.succes,
  EtatProfilPaiement.incomplet ||
  EtatProfilPaiement.actionRequise => TonEtat.avertissement,
  EtatProfilPaiement.suspendu => TonEtat.alerte,
};

/// Le mot d'un retour de capacite de payout (§42).
String libelleCapacitePayout(CapacitePayout capacite) {
  final c = t.comptable.statuts.capacite;
  return switch (capacite) {
    CapacitePayout.prisEnCharge => c.prisEnCharge,
    CapacitePayout.nonPrisEnCharge => c.nonPrisEnCharge,
    CapacitePayout.temporairementIndisponible => c.temporairementIndisponible,
    CapacitePayout.verificationRequise => c.verificationRequise,
    CapacitePayout.soldePrestataireInsuffisant => c.soldePrestataireInsuffisant,
  };
}

/// La famille d'un retour de capacite.
TonEtat tonCapacitePayout(CapacitePayout capacite) => switch (capacite) {
  CapacitePayout.prisEnCharge => TonEtat.succes,
  CapacitePayout.nonPrisEnCharge => TonEtat.neutre,
  CapacitePayout.verificationRequise => TonEtat.avertissement,
  CapacitePayout.temporairementIndisponible ||
  CapacitePayout.soldePrestataireInsuffisant => TonEtat.alerte,
};

/// Le mot d'un etat de la Reserve strategique (§49).
String libelleEtatReserve(EtatReserve etat) {
  final r = t.comptable.statuts.reserve;
  return switch (etat) {
    EtatReserve.atteint => r.atteint,
    EtatReserve.sousObjectif => r.sousObjectif,
    EtatReserve.depassement => r.depassement,
    EtatReserve.regleInactive => r.regleInactive,
    EtatReserve.alimentationPrevue => r.alimentationPrevue,
    EtatReserve.mouvementSensible => r.mouvementSensible,
  };
}

/// La famille d'un etat de la Reserve.
TonEtat tonEtatReserve(EtatReserve etat) => switch (etat) {
  EtatReserve.regleInactive => TonEtat.neutre,
  EtatReserve.alimentationPrevue || EtatReserve.depassement => TonEtat.accent,
  EtatReserve.atteint => TonEtat.succes,
  EtatReserve.sousObjectif ||
  EtatReserve.mouvementSensible => TonEtat.avertissement,
};

/// Le mot d'un etat d'obligation de contractuel (§22.3).
String libelleObligationContractuel(EtatObligationContractuel etat) {
  final o = t.comptable.statuts.obligation;
  return switch (etat) {
    EtatObligationContractuel.brouillon => o.brouillon,
    EtatObligationContractuel.aApprouver => o.aApprouver,
    EtatObligationContractuel.approuvee => o.approuvee,
    EtatObligationContractuel.refusee => o.refusee,
    EtatObligationContractuel.payee => o.payee,
    EtatObligationContractuel.annulee => o.annulee,
  };
}

/// La famille d'un etat d'obligation de contractuel.
TonEtat tonObligationContractuel(EtatObligationContractuel etat) =>
    switch (etat) {
      EtatObligationContractuel.brouillon ||
      EtatObligationContractuel.annulee => TonEtat.neutre,
      EtatObligationContractuel.approuvee => TonEtat.accent,
      EtatObligationContractuel.payee => TonEtat.succes,
      EtatObligationContractuel.aApprouver => TonEtat.avertissement,
      EtatObligationContractuel.refusee => TonEtat.alerte,
    };

/// Le mot d'un etat de remboursement (§26).
String libelleRemboursement(EtatRemboursement etat) {
  final r = t.comptable.statuts.remboursement;
  return switch (etat) {
    EtatRemboursement.demande => r.demande,
    EtatRemboursement.approbationRequise => r.approbationRequise,
    EtatRemboursement.approuve => r.approuve,
    EtatRemboursement.execute => r.execute,
    EtatRemboursement.refuse => r.refuse,
  };
}

/// La famille d'un etat de remboursement.
TonEtat tonRemboursement(EtatRemboursement etat) => switch (etat) {
  EtatRemboursement.demande => TonEtat.neutre,
  EtatRemboursement.approuve => TonEtat.accent,
  EtatRemboursement.execute => TonEtat.succes,
  EtatRemboursement.approbationRequise => TonEtat.avertissement,
  EtatRemboursement.refuse => TonEtat.alerte,
};

/// Le mot d'une demande de validation (CPT-BR-09).
String libelleDemandeValidation(EtatDemandeValidation etat) {
  final v = t.comptable.statuts.validation;
  return switch (etat) {
    EtatDemandeValidation.enAttente => v.enAttente,
    EtatDemandeValidation.validee => v.validee,
    EtatDemandeValidation.refusee => v.refusee,
  };
}

/// La famille d'une demande de validation.
TonEtat tonDemandeValidation(EtatDemandeValidation etat) => switch (etat) {
  EtatDemandeValidation.enAttente => TonEtat.avertissement,
  EtatDemandeValidation.validee => TonEtat.succes,
  EtatDemandeValidation.refusee => TonEtat.alerte,
};

/// La phrase d'une raison de blocage (`CPT-BR.md` §1), rendue telle quelle :
/// l'ecran ne la deduit jamais (DR-19).
String libelleRaisonBlocage(RaisonBlocage raison) {
  final r = t.comptable.statuts.raison;
  return switch (raison) {
    RaisonBlocage.autoPaiement => r.autoPaiement,
    RaisonBlocage.validationRequise => r.validationRequise,
    RaisonBlocage.infosManquantes => r.infosManquantes,
    RaisonBlocage.verificationRequise => r.verificationRequise,
    RaisonBlocage.horsDelegation => r.horsDelegation,
    RaisonBlocage.fournisseurIndisponible => r.fournisseurIndisponible,
    RaisonBlocage.fondsInsuffisants => r.fondsInsuffisants,
    RaisonBlocage.doublonPotentiel => r.doublonPotentiel,
    RaisonBlocage.nonApprouvee => r.nonApprouvee,
    RaisonBlocage.capaciteAbsente => r.capaciteAbsente,
    RaisonBlocage.delegationsSuspendues => r.delegationsSuspendues,
    RaisonBlocage.delegationExpiree => r.delegationExpiree,
    RaisonBlocage.sortieEnAttenteDelai => r.sortieEnAttenteDelai,
    RaisonBlocage.coffreNonAutorise => r.coffreNonAutorise,
    RaisonBlocage.beneficiaireExclu => r.beneficiaireExclu,
    RaisonBlocage.plafondExceptionDepasse => r.plafondExceptionDepasse,
  };
}

/// Le mot d'un type d'alerte (§28).
String libelleAlerteComptable(TypeAlerteComptable type) {
  final a = t.comptable.alertes;
  return switch (type) {
    TypeAlerteComptable.enseignantsAPayer => a.enseignantsAPayer,
    TypeAlerteComptable.contractuelsAEcheance => a.contractuelsAEcheance,
    TypeAlerteComptable.infosManquantes => a.infosManquantes,
    TypeAlerteComptable.payoutEchoue => a.payoutEchoue,
    TypeAlerteComptable.paiementFamilleEchoue => a.paiementFamilleEchoue,
    TypeAlerteComptable.transactionNonRapprochee => a.transactionNonRapprochee,
    TypeAlerteComptable.remboursementEnAttente => a.remboursementEnAttente,
    TypeAlerteComptable.reserveSousObjectif => a.reserveSousObjectif,
    TypeAlerteComptable.soldePrestataireInsuffisant =>
      a.soldePrestataireInsuffisant,
    TypeAlerteComptable.methodeModifieeRecemment => a.methodeModifieeRecemment,
    TypeAlerteComptable.doublonPotentiel => a.doublonPotentiel,
    TypeAlerteComptable.validationRequise => a.validationRequise,
  };
}

/// La famille d'un type d'alerte : alerte pour un echec ou un doublon,
/// avertissement pour ce qui attend, accent pour ce qui est a payer.
TonEtat tonAlerteComptable(TypeAlerteComptable type) => switch (type) {
  TypeAlerteComptable.enseignantsAPayer ||
  TypeAlerteComptable.contractuelsAEcheance => TonEtat.accent,
  TypeAlerteComptable.payoutEchoue ||
  TypeAlerteComptable.paiementFamilleEchoue ||
  TypeAlerteComptable.doublonPotentiel ||
  TypeAlerteComptable.soldePrestataireInsuffisant => TonEtat.alerte,
  TypeAlerteComptable.infosManquantes ||
  TypeAlerteComptable.transactionNonRapprochee ||
  TypeAlerteComptable.remboursementEnAttente ||
  TypeAlerteComptable.reserveSousObjectif ||
  TypeAlerteComptable.methodeModifieeRecemment ||
  TypeAlerteComptable.validationRequise => TonEtat.avertissement,
};

/// Le nom d'un coffre (§8.1).
String libelleCoffre(Coffre coffre) {
  final c = t.comptable.coffres;
  return switch (coffre) {
    Coffre.fondsClientsEngages => c.fondsClientsEngages,
    Coffre.paieADecaisser => c.paieADecaisser,
    Coffre.chargesEssentielles => c.chargesEssentielles,
    Coffre.taxesObligations => c.taxesObligations,
    Coffre.reserveStrategique => c.reserveStrategique,
    Coffre.enTransit => c.enTransit,
    Coffre.tresorerieLibre => c.tresorerieLibre,
  };
}

/// La pastille d'un etat de paiement sortant.
class PastillePaiementSortant extends StatelessWidget {
  /// Cree la pastille.
  const PastillePaiementSortant(this.etat, {super.key});

  /// L'etat.
  final EtatPaiementSortant etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libellePaiementSortant(etat),
    ton: tonPaiementSortant(etat),
  );
}

/// La pastille d'un etat d'encaissement.
class PastilleEncaissement extends StatelessWidget {
  /// Cree la pastille.
  const PastilleEncaissement(this.etat, {super.key});

  /// L'etat.
  final EtatEncaissement etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleEncaissement(etat),
    ton: tonEncaissement(etat),
  );
}

/// La pastille d'un etat de rapprochement.
class PastilleRapprochement extends StatelessWidget {
  /// Cree la pastille.
  const PastilleRapprochement(this.etat, {super.key});

  /// L'etat.
  final EtatRapprochement etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleRapprochement(etat),
    ton: tonRapprochement(etat),
  );
}

/// La pastille d'un etat de profil de paiement.
class PastilleProfilPaiement extends StatelessWidget {
  /// Cree la pastille.
  const PastilleProfilPaiement(this.etat, {super.key});

  /// L'etat.
  final EtatProfilPaiement etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleProfilPaiement(etat),
    ton: tonProfilPaiement(etat),
  );
}

/// La pastille d'un retour de capacite (`FinanceProviderStatus`).
class PastilleCapacitePayout extends StatelessWidget {
  /// Cree la pastille.
  const PastilleCapacitePayout(this.capacite, {super.key});

  /// Le retour.
  final CapacitePayout capacite;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleCapacitePayout(capacite),
    ton: tonCapacitePayout(capacite),
  );
}

/// La pastille d'un etat de la Reserve strategique.
class PastilleEtatReserve extends StatelessWidget {
  /// Cree la pastille.
  const PastilleEtatReserve(this.etat, {super.key});

  /// L'etat.
  final EtatReserve etat;

  @override
  Widget build(BuildContext context) =>
      StatusPill(libelle: libelleEtatReserve(etat), ton: tonEtatReserve(etat));
}

/// La pastille d'un etat d'obligation de contractuel.
class PastilleObligationContractuel extends StatelessWidget {
  /// Cree la pastille.
  const PastilleObligationContractuel(this.etat, {super.key});

  /// L'etat.
  final EtatObligationContractuel etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleObligationContractuel(etat),
    ton: tonObligationContractuel(etat),
  );
}

/// La pastille d'un etat de remboursement.
class PastilleRemboursement extends StatelessWidget {
  /// Cree la pastille.
  const PastilleRemboursement(this.etat, {super.key});

  /// L'etat.
  final EtatRemboursement etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleRemboursement(etat),
    ton: tonRemboursement(etat),
  );
}

/// La pastille d'une demande de validation.
class PastilleDemandeValidation extends StatelessWidget {
  /// Cree la pastille.
  const PastilleDemandeValidation(this.etat, {super.key});

  /// L'etat.
  final EtatDemandeValidation etat;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleDemandeValidation(etat),
    ton: tonDemandeValidation(etat),
  );
}
