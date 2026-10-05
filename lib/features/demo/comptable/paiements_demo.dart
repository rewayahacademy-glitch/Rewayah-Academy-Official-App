// La demonstration des paiements sortants (CPT-BR-01, 02, 10). Posee vide par
// CPT-F ; **propriete de la voie CPT-PAY ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 tenue ici : 15
// enseignants, 5 contractuels, 12 prets, 2 infos manquantes, 1 methode
// modifiee recemment, 1 auto-payout interdit, 1 validation supplementaire,
// 1 payout echoue, 1 lot partiellement pret (le preflight de « tous les
// prets » exclut celui dont le prestataire est indisponible), 1 recalcul a
// la source pendant la confirmation (R-FIN-18, DR-13). Les identites
// viennent de `socle_comptable_demo.dart` ; aucun paiement (K-28), aucune
// vraie coordonnee, aucun appel serveur.
//
// La source de demonstration fait ce que fera le serveur et que l'ecran ne
// fait jamais : elle additionne les totaux d'un lot, decide des exclusions et
// de leur raison, refuse une version perimee, rejoue une cle d'idempotence
// sans second envoi, et fait avancer un payout soumis -> en transit -> reussi
// a chaque lecture du suivi (jamais « reussi » sur simple appui, §5.3).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_capacite_payout.dart';
import '../../../core/capacites/port_obligations_payables.dart';
import '../../../core/capacites/port_payout.dart';
import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import 'socle_comptable_demo.dart';
import 'validations_demo.dart';

/// Les identifiants remarquables de la demonstration, pour les tests et la
/// recette.
abstract final class PaiementsDemo {
  /// Le Comptable lui-meme : « Traitement par un autre responsable requis ».
  static const String obligationComptable = 'obl-cpt-01-2026-10';

  /// Methode modifiee recemment : validation supplementaire (R-FIN-14).
  static const String obligationMethodeRecente = 'obl-ens-12-2026-10';

  /// Beneficiaire lie a l'operateur : validation supplementaire (§21.4).
  static const String obligationLieeOperateur = 'obl-ens-15-2026-10';

  /// Le payout echoue chez le prestataire.
  static const String obligationEchouee = 'obl-ens-13-2026-10';

  /// Infos de paiement manquantes (enseignant).
  static const String obligationInfosManquantes = 'obl-ens-11-2026-10';

  /// Pret, mais le prestataire prevu est indisponible : exclu au preflight.
  static const String obligationFournisseurIndisponible = 'obl-ctr-02-2026-10';

  /// Pret, puis recalcule a la source a la premiere soumission (R-FIN-18).
  static const String obligationRecalculee = 'obl-ens-09-2026-10';

  /// Deja soumise, en transit chez le prestataire.
  static const String obligationEnTransit = 'obl-ctr-04-2026-10';
}

/// L'etat partage des trois doubles : les obligations, les preflights, les
/// soumissions deja recues (par cle d'idempotence) et les suivis.
class EtatDemoPaiements {
  /// Cree l'etat de depart de la demonstration.
  EtatDemoPaiements() {
    for (final ObligationPayable o in _obligationsDeDepart()) {
      obligations[o.id] = o;
    }
  }

  /// Les obligations, par identifiant, dans l'ordre d'insertion.
  final Map<String, ObligationPayable> obligations =
      <String, ObligationPayable>{};

  /// Les preflights rendus, par identifiant.
  final Map<String, PreflightLot> preflights = <String, PreflightLot>{};

  /// Les reponses deja rendues, par cle d'idempotence : la meme cle rend la
  /// meme reponse, sans second envoi.
  final Map<String, List<SuiviPayout>> soumissions =
      <String, List<SuiviPayout>>{};

  /// Les demandes de validation deja deposees, par cle.
  final Map<String, DemandeValidationDeposee> validations =
      <String, DemandeValidationDeposee>{};

  /// Les signalements deja deposes, par cle.
  final Map<String, SignalementEcart> signalements =
      <String, SignalementEcart>{};

  /// Les suivis, par payout.
  final Map<String, SuiviPayout> suivis = <String, SuiviPayout>{};

  /// Le journal ajoute pendant la demonstration, par obligation.
  final Map<String, List<EntreeJournal>> journal =
      <String, List<EntreeJournal>>{};

  /// Le nombre d'envois que la source a acceptes (un par obligation et par
  /// cle) : les tests d'idempotence le lisent.
  int envoisAcceptes = 0;

  /// Vrai tant que la premiere soumission de
  /// [PaiementsDemo.obligationRecalculee] n'a pas eu lieu.
  bool recalculEnAttente = true;

  int _sequence = 0;

  String _id(String prefixe) => '$prefixe-${++_sequence}';

  /// Applique aux obligations la decision du registre unique des
  /// validations (CPT-VAL-1), comme le fera le serveur : une demande en
  /// attente retire « Demander validation » ; validee, le paiement devient
  /// payable par le Comptable (sauf sa propre paie, toujours traitee par un
  /// autre responsable) ; refusee, la demande peut etre refaite apres
  /// correction.
  void suivreValidations() {
    for (final ObligationPayable o in obligations.values.toList()) {
      if (o.etat != EtatPaiementSortant.validationRequise) continue;
      final DemandeValidation? d = RegistreValidationsDemo.instance.derniere(
        o.id,
      );
      if (d == null) continue;
      switch (d.etat) {
        case EtatDemandeValidation.enAttente:
          obligations[o.id] = _copie(
            o,
            permissions: PermissionsFinance(
              actions: o.permissions.actions.difference(<ActionFinance>{
                ActionFinance.demanderValidation,
              }),
              blocages: o.permissions.blocages,
            ),
          );
        case EtatDemandeValidation.validee:
          if (o.permissions.raisonDe(ActionFinance.payer) ==
              RaisonBlocage.validationRequise) {
            obligations[o.id] = _copie(
              o,
              etat: EtatPaiementSortant.pretAPayer,
              permissions: _peutPayer,
            );
          }
        case EtatDemandeValidation.refusee:
          obligations[o.id] = _copie(
            o,
            permissions: _bloque(
              RaisonBlocage.validationRequise,
              validation: true,
            ),
          );
      }
    }
  }
}

/// Les obligations payables en demonstration.
class ObligationsPayablesDemo implements PortObligationsPayables {
  /// Cree le double sur [etat].
  ObligationsPayablesDemo(this.etat);

  /// L'etat partage.
  final EtatDemoPaiements etat;

  @override
  Future<List<ObligationPayable>> liste(FiltreObligations filtre) async {
    etat.suivreValidations();
    return etat.obligations.values
        .where((ObligationPayable o) => _retenue(o, filtre))
        .toList();
  }

  @override
  Future<ObligationPayable> detail(String obligationId) async {
    etat.suivreValidations();
    final ObligationPayable? o = etat.obligations[obligationId];
    if (o == null) {
      throw const ObligationIntrouvableDemo();
    }
    return o;
  }

  @override
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
    required String cleIdempotence,
  }) async => etat.signalements.putIfAbsent(
    cleIdempotence,
    () => SignalementEcart(
      id: etat._id('ecart'),
      obligationId: obligationId,
      ligneId: ligneId,
      date: SocleComptableDemo.aujourdhui,
    ),
  );

  @override
  Future<List<EntreeJournal>> journal(String obligationId) async =>
      <EntreeJournal>[
        ...?etat.journal[obligationId]?.reversed,
        ..._journalDeDepart(obligationId),
      ];
}

/// Une obligation inconnue de la demonstration (adresse tapee a la main).
class ObligationIntrouvableDemo implements Exception {
  /// Cree l'erreur.
  const ObligationIntrouvableDemo();
}

/// Le payout en demonstration : preflight, soumission idempotente, suivi
/// qui avance a chaque lecture. Aucun paiement.
class PayoutDemo implements PortPayout {
  /// Cree le double sur [etat].
  PayoutDemo(this.etat);

  /// L'etat partage.
  final EtatDemoPaiements etat;

  @override
  Future<PreflightLot> preflight(List<ObligationChoisie> selection) async {
    etat.suivreValidations();
    final List<ObligationChoisie> prets = <ObligationChoisie>[];
    final List<ExclusionLot> exclus = <ExclusionLot>[];
    bool sensible = false;
    for (final ObligationChoisie choix in selection) {
      final ObligationPayable? o = etat.obligations[choix.obligationId];
      if (o == null) continue;
      final bool seuleSensible =
          selection.length == 1 &&
          o.permissions.raisonDe(ActionFinance.payer) ==
              RaisonBlocage.validationRequise &&
          o.permissions.permet(ActionFinance.demanderValidation);
      final RaisonBlocage? raison = _raisonExclusion(o);
      if (seuleSensible) {
        // Un paiement sensible ouvert seul : la feuille propose « Demander
        // validation » au lieu de « Confirmer le paiement » (§40). Dans un
        // lot, il est exclu : on ne le fait pas passer en le noyant parmi
        // d'autres (§47).
        sensible = true;
        prets.add(choix);
      } else if (raison == null) {
        prets.add(choix);
      } else {
        exclus.add(
          ExclusionLot(
            obligationId: o.id,
            beneficiaire: o.beneficiaire,
            raison: raison,
          ),
        );
      }
    }
    final Map<String, int> totaux = <String, int>{};
    final Set<String> beneficiaires = <String>{};
    final Set<String> prestataires = <String>{};
    for (final ObligationChoisie choix in prets) {
      final ObligationPayable o = etat.obligations[choix.obligationId]!;
      totaux[o.montant.devise] =
          (totaux[o.montant.devise] ?? 0) + o.montant.mineur;
      beneficiaires.add(o.beneficiaire.id);
      final String? p = o.prestatairePrevu;
      if (p != null) prestataires.add(p);
    }
    final String? seule = prets.length == 1 ? prets.single.obligationId : null;
    final PreflightLot lot = PreflightLot(
      id: etat._id('preflight'),
      nombreBeneficiaires: beneficiaires.length,
      totauxParDevise: <Montant>[
        for (final MapEntry<String, int> e in totaux.entries)
          Montant(e.value, e.key),
      ],
      prets: prets,
      exclus: exclus,
      prestataires: <PrestataireFinance>[
        for (final PrestataireFinance p in SocleComptableDemo.prestataires)
          if (prestataires.contains(p.nom)) p,
      ],
      plafondsRestants: <Montant>[SocleComptableDemo.usd(6000)],
      fraisEtChange: seule == SocleComptableDemo.obligationDiallo
          ? _fraisDiallo
          : null,
      sensible: sensible,
    );
    etat.preflights[lot.id] = lot;
    return lot;
  }

  @override
  Future<List<SuiviPayout>> soumettre({
    required String preflightId,
    required String cleIdempotence,
  }) async {
    // La meme cle rend la meme reponse : un double appui, une reponse perdue
    // puis rejouee, n'envoient qu'une fois.
    final List<SuiviPayout>? deja = etat.soumissions[cleIdempotence];
    if (deja != null) return deja;
    final PreflightLot? lot = etat.preflights[preflightId];
    if (lot == null || lot.sensible) {
      throw const RefusPayout(MotifRefusPayout.preflightPerime);
    }
    final List<String> perimees = <String>[
      for (final ObligationChoisie c in lot.prets)
        if (etat.obligations[c.obligationId]?.version != c.version)
          c.obligationId,
    ];
    if (etat.recalculEnAttente &&
        lot.prets.any(
          (ObligationChoisie c) =>
              c.obligationId == PaiementsDemo.obligationRecalculee,
        )) {
      // Le recalcul arrive a la source entre le preflight et l'envoi : la
      // version change, rien ne part (DR-13).
      etat.recalculEnAttente = false;
      _recalculer(PaiementsDemo.obligationRecalculee);
      perimees.add(PaiementsDemo.obligationRecalculee);
    }
    if (perimees.isNotEmpty) {
      throw RefusPayout(
        MotifRefusPayout.versionChangee,
        obligationIds: perimees,
      );
    }
    final List<SuiviPayout> suivis = <SuiviPayout>[];
    for (final ObligationChoisie c in lot.prets) {
      final ObligationPayable o = etat.obligations[c.obligationId]!;
      final SuiviPayout suivi = SuiviPayout(
        payoutId: etat._id('payout'),
        obligationId: o.id,
        etat: EtatPaiementSortant.soumis,
        montant: o.montant,
        prestataire: o.prestatairePrevu,
        miseAJour: SocleComptableDemo.aujourdhui,
      );
      etat.suivis[suivi.payoutId] = suivi;
      etat.envoisAcceptes++;
      _changerEtat(o, EtatPaiementSortant.soumis);
      suivis.add(suivi);
    }
    etat.soumissions[cleIdempotence] = suivis;
    return suivis;
  }

  @override
  Future<SuiviPayout> suivre(String payoutId) async {
    final SuiviPayout? suivi = etat.suivis[payoutId];
    if (suivi == null) {
      throw const CapaciteIndisponible('CPT-BR-02');
    }
    // Chaque lecture avance d'un etat, comme le ferait le webhook du
    // prestataire : soumis -> en transit -> reussi.
    final EtatPaiementSortant suivant = switch (suivi.etat) {
      EtatPaiementSortant.soumis => EtatPaiementSortant.enTransit,
      EtatPaiementSortant.enTransit => EtatPaiementSortant.reussi,
      final EtatPaiementSortant autre => autre,
    };
    final SuiviPayout avance = SuiviPayout(
      payoutId: suivi.payoutId,
      obligationId: suivi.obligationId,
      etat: suivant,
      montant: suivi.montant,
      prestataire: suivi.prestataire,
      reference: suivant == EtatPaiementSortant.reussi
          ? 'DEMO-${suivi.payoutId.toUpperCase()}'
          : suivi.reference,
      miseAJour: SocleComptableDemo.aujourdhui,
    );
    etat.suivis[payoutId] = avance;
    final ObligationPayable? o = etat.obligations[suivi.obligationId];
    if (o != null) _changerEtat(o, suivant);
    return avance;
  }

  @override
  Future<DemandeValidationDeposee> demanderValidation({
    required String obligationId,
    required String motif,
    required String cleIdempotence,
  }) async {
    final DemandeValidationDeposee? deja = etat.validations[cleIdempotence];
    if (deja != null) return deja;
    final ObligationPayable? o = etat.obligations[obligationId];
    if (o == null) throw const ObligationIntrouvableDemo();
    // Le registre unique (CPT-VAL-1) : la demande part dans l'onglet
    // « A valider » de la direction, qui seule la decide.
    final bool sienne =
        o.permissions.raisonDe(ActionFinance.payer) ==
        RaisonBlocage.autoPaiement;
    final DateTime? modification = o.destination?.derniereModification;
    final DemandeValidation demande = RegistreValidationsDemo.instance.deposer(
      nature: sienne
          ? NatureDemandeValidation.payoutDuComptable
          : NatureDemandeValidation.payoutSensible,
      demandeurId: SocleComptableDemo.comptableId,
      demandeurNom: SocleComptableDemo.leComptable.nom,
      objet: '${o.periode} · ${o.beneficiaire.nom}',
      montant: o.montant,
      raison:
          o.permissions.raisonDe(ActionFinance.payer) ??
          RaisonBlocage.validationRequise,
      cleIdempotence: cleIdempotence,
      objetId: o.id,
      precision: modification != null
          ? 'Coordonnées du bénéficiaire modifiées le '
                '${dateComptable(modification)}.'
          : o.beneficiaire.lieALOperateur
          ? 'Bénéficiaire lié à la personne qui prépare le paiement.'
          : null,
    );
    etat.suivreValidations();
    return etat.validations[cleIdempotence] = DemandeValidationDeposee(
      demandeId: demande.id,
      obligationId: obligationId,
      etat: demande.etat,
    );
  }

  void _changerEtat(ObligationPayable o, EtatPaiementSortant nouvel) {
    if (o.etat == nouvel) return;
    etat.obligations[o.id] = _copie(
      o,
      etat: nouvel,
      permissions: PermissionsFinance.lectureSeule,
    );
    (etat.journal[o.id] ??= <EntreeJournal>[]).add(
      EntreeJournal(
        id: etat._id('journal'),
        date: SocleComptableDemo.aujourdhui,
        initiateur: nouvel == EtatPaiementSortant.soumis
            ? SocleComptableDemo.leComptable.nom
            : o.prestatairePrevu ?? _prestA,
        objet: o.periode,
        ancienEtat: _mot(o.etat),
        nouvelEtat: _mot(nouvel),
        montant: o.montant,
        prestataire: o.prestatairePrevu,
      ),
    );
  }

  void _recalculer(String obligationId) {
    final ObligationPayable o = etat.obligations[obligationId]!;
    final LigneCalcul ajustement = LigneCalcul(
      id: '$obligationId-l9',
      libelle: 'Ajustement approuvé',
      montant: SocleComptableDemo.usd(-10),
      source: 'Séance du 22 septembre annulée',
      auteur: 'Direction pédagogique',
      validation: 'Approuvé le 4 octobre 2026',
      date: SocleComptableDemo.aujourdhui,
    );
    etat.obligations[obligationId] = _copie(
      o,
      version: 'v2',
      lignes: <LigneCalcul>[...o.lignes, ajustement],
      montant: Montant(
        o.montant.mineur + ajustement.montant.mineur,
        o.montant.devise,
      ),
    );
    (etat.journal[obligationId] ??= <EntreeJournal>[]).add(
      EntreeJournal(
        id: etat._id('journal'),
        date: SocleComptableDemo.aujourdhui,
        initiateur: 'Calcul automatique',
        objet: 'Recalcul à la source (version 2)',
        source: ajustement.source,
      ),
    );
  }
}

/// Le mot lisible d'un etat, pour le journal de demonstration.
String _mot(EtatPaiementSortant etat) => switch (etat) {
  EtatPaiementSortant.pretAPayer => 'Prêt à payer',
  EtatPaiementSortant.soumis => 'Soumis',
  EtatPaiementSortant.enTransit => 'En transit',
  EtatPaiementSortant.reussi => 'Réussi',
  EtatPaiementSortant.echoue => 'Échoué',
  _ => etat.name,
};

/// La raison d'exclusion d'une obligation au preflight, ou `null` si elle
/// est prete.
RaisonBlocage? _raisonExclusion(ObligationPayable o) {
  if (!o.permissions.permet(ActionFinance.payer)) {
    return o.permissions.raisonDe(ActionFinance.payer) ??
        RaisonBlocage.capaciteAbsente;
  }
  for (final PrestataireFinance p in SocleComptableDemo.prestataires) {
    if (p.nom == o.prestatairePrevu &&
        p.capacite != CapacitePayout.prisEnCharge) {
      return RaisonBlocage.fournisseurIndisponible;
    }
  }
  return null;
}

/// Les prestataires neutres du socle ; un corridor GN et SN est pris en
/// charge, tout autre corridor ne l'est pas.
class CapacitePayoutDemo implements PortCapacitePayout {
  /// Cree le double.
  const CapacitePayoutDemo();

  @override
  Future<List<PrestataireFinance>> prestataires() async =>
      SocleComptableDemo.prestataires;

  @override
  Future<CapacitePayout> capacite(CorridorPayout corridor) async =>
      switch (corridor.pays) {
        'GN' || 'SN' => CapacitePayout.prisEnCharge,
        _ => CapacitePayout.nonPrisEnCharge,
      };
}

/// Les surcharges de la demonstration des paiements : un seul etat partage
/// par les trois doubles, neuf a chaque appel (chaque ouverture de la
/// demonstration repart de l'etat de depart).
List<Override> surchargesDemoPaiements() {
  final EtatDemoPaiements etat = EtatDemoPaiements();
  return <Override>[
    portObligationsPayablesProvider.overrideWithValue(
      ObligationsPayablesDemo(etat),
    ),
    portPayoutProvider.overrideWithValue(PayoutDemo(etat)),
    portCapacitePayoutProvider.overrideWithValue(const CapacitePayoutDemo()),
  ];
}

// --- Donnees de depart ------------------------------------------------------

const PermissionsFinance _peutPayer = PermissionsFinance(
  actions: <ActionFinance>{ActionFinance.payer, ActionFinance.signalerEcart},
);

PermissionsFinance _bloque(RaisonBlocage raison, {bool validation = false}) =>
    PermissionsFinance(
      actions: <ActionFinance>{
        if (raison != RaisonBlocage.autoPaiement) ActionFinance.signalerEcart,
        if (validation) ActionFinance.demanderValidation,
        if (raison == RaisonBlocage.infosManquantes) ActionFinance.relancer,
      },
      blocages: <ActionFinance, RaisonBlocage>{ActionFinance.payer: raison},
    );

final DateTime _echeance = DateTime(2026, 10, 10);

const String _prestA = 'Prestataire A';
const String _prestB = 'Prestataire B';

const String _periode = 'Octobre 2026';

const DestinationMasquee _mobileSn = DestinationMasquee(
  type: 'Mobile money',
  operateur: 'Operateur B',
  suffixe: '1187',
  pays: 'SN',
  devise: 'XOF',
  verification: EtatProfilPaiement.verifie,
);

/// Le detail de l'exemple §13.3, ligne a ligne, chacune avec sa source.
List<LigneCalcul> _lignesDiallo(String id) => <LigneCalcul>[
  LigneCalcul(
    id: '$id-l1',
    libelle: 'Classe Al-Fajr',
    montant: SocleComptableDemo.usd(100),
    source: '10 séances tenues, présences du registre',
  ),
  LigneCalcul(
    id: '$id-l2',
    libelle: 'Classe An-Nour',
    montant: SocleComptableDemo.usd(80),
    source: '8 séances tenues, présences du registre',
  ),
  LigneCalcul(
    id: '$id-l3',
    libelle: 'Remplacement',
    montant: SocleComptableDemo.usd(12),
    source: 'Remplacement du 12 septembre, Classe Al-Huda',
  ),
  LigneCalcul(
    id: '$id-l4',
    libelle: 'Bonus approuvé',
    montant: SocleComptableDemo.usd(20),
    source: 'Bonus Internet de septembre',
    auteur: 'Direction pédagogique',
    validation: 'Approuvé le 30 septembre 2026',
  ),
];

/// Des lignes generiques : une ou deux Classes, sans remplacement.
List<LigneCalcul> _lignes(String id, List<(String, int, int)> classes) =>
    <LigneCalcul>[
      for (final (int i, (String classe, int unites, int seances))
          in classes.indexed)
        LigneCalcul(
          id: '$id-l${i + 1}',
          libelle: 'Classe $classe',
          montant: SocleComptableDemo.usd(unites),
          source: '$seances séances tenues, présences du registre',
        ),
    ];

Montant _somme(List<LigneCalcul> lignes) => Montant(
  lignes.fold<int>(0, (int s, LigneCalcul l) => s + l.montant.mineur),
  SocleComptableDemo.devise,
);

ObligationPayable _enseignant(
  int rang, {
  required List<(String, int, int)> classes,
  EtatPaiementSortant etat = EtatPaiementSortant.pretAPayer,
  PermissionsFinance permissions = _peutPayer,
  DestinationMasquee? destination = SocleComptableDemo.destinationMobile,
  DateTime? echeance,
}) {
  final IdentiteBeneficiaire b = SocleComptableDemo.enseignants[rang - 1];
  final String id = 'obl-${b.id}-2026-10';
  final List<LigneCalcul> lignes = id == SocleComptableDemo.obligationDiallo
      ? _lignesDiallo(id)
      : _lignes(id, classes);
  return ObligationPayable(
    id: id,
    version: 'v1',
    periode: _periode,
    beneficiaire: b,
    lignes: lignes,
    montant: _somme(lignes),
    etat: etat,
    echeance: echeance ?? _echeance,
    destination: destination,
    preuve: 'Registre de présence de septembre 2026',
    prestatairePrevu: destination == null ? null : _prestA,
    permissions: permissions,
    classes: <String>[for (final (String c, _, _) in classes) c],
  );
}

ObligationPayable _contractuel(
  int rang, {
  required String objet,
  required int unites,
  EtatPaiementSortant etat = EtatPaiementSortant.pretAPayer,
  PermissionsFinance permissions = _peutPayer,
  DestinationMasquee? destination = SocleComptableDemo.destinationBanque,
  String prestataire = _prestA,
}) {
  final IdentiteBeneficiaire b = SocleComptableDemo.contractuels[rang - 1];
  final String id = rang == 1
      ? SocleComptableDemo.obligationFacture024
      : 'obl-${b.id}-2026-10';
  final LigneCalcul ligne = LigneCalcul(
    id: '$id-l1',
    libelle: objet,
    montant: SocleComptableDemo.usd(unites),
    source: 'Obligation ponctuelle approuvée, montant figé',
    auteur: 'Direction',
    validation: 'Approuvée le 1 octobre 2026',
  );
  return ObligationPayable(
    id: id,
    version: 'v1',
    periode: objet,
    beneficiaire: b,
    lignes: <LigneCalcul>[ligne],
    montant: ligne.montant,
    etat: etat,
    echeance: DateTime(2026, 10, 12),
    destination: destination,
    preuve: 'Justificatif joint à l’obligation',
    prestatairePrevu: destination == null ? null : prestataire,
    permissions: permissions,
  );
}

List<ObligationPayable> _obligationsDeDepart() => <ObligationPayable>[
  // Les douze prets (§44), dont un dont le prestataire est indisponible.
  _enseignant(
    1,
    classes: <(String, int, int)>[('Al-Fajr', 100, 10), ('An-Nour', 80, 8)],
  ),
  _enseignant(2, classes: <(String, int, int)>[('An-Nour', 140, 14)]),
  _enseignant(
    3,
    classes: <(String, int, int)>[('Al-Fatiha', 90, 9), ('Al-Huda', 60, 6)],
  ),
  _enseignant(4, classes: <(String, int, int)>[('Al-Huda', 120, 12)]),
  _enseignant(
    5,
    classes: <(String, int, int)>[('Al-Fajr', 70, 7)],
    destination: _mobileSn,
  ),
  _enseignant(6, classes: <(String, int, int)>[('An-Nour', 110, 11)]),
  _enseignant(
    7,
    classes: <(String, int, int)>[('Al-Fatiha', 80, 8), ('An-Nour', 40, 4)],
  ),
  _enseignant(8, classes: <(String, int, int)>[('Al-Huda', 150, 15)]),
  _enseignant(9, classes: <(String, int, int)>[('Al-Fajr', 130, 13)]),
  _enseignant(10, classes: <(String, int, int)>[('Al-Fatiha', 100, 10)]),
  _contractuel(1, objet: 'Facture #024', unites: 350),
  _contractuel(
    2,
    objet: 'Facture #031',
    unites: 180,
    prestataire: _prestB,
    destination: _mobileSn,
  ),
  // Infos de paiement manquantes (2).
  _enseignant(
    11,
    classes: <(String, int, int)>[('An-Nour', 90, 9)],
    etat: EtatPaiementSortant.infosManquantes,
    permissions: _bloque(RaisonBlocage.infosManquantes),
    destination: null,
    echeance: DateTime(2026, 10, 2),
  ),
  _contractuel(
    3,
    objet: 'Facture #017',
    unites: 240,
    etat: EtatPaiementSortant.infosManquantes,
    permissions: _bloque(RaisonBlocage.infosManquantes),
    destination: null,
  ),
  // Methode modifiee recemment (R-FIN-14).
  _enseignant(
    12,
    classes: <(String, int, int)>[('Al-Huda', 100, 10)],
    etat: EtatPaiementSortant.validationRequise,
    permissions: _bloque(RaisonBlocage.validationRequise, validation: true),
    destination: DestinationMasquee(
      type: 'Mobile money',
      operateur: 'Operateur A',
      suffixe: '9031',
      pays: 'GN',
      devise: 'GNF',
      verification: EtatProfilPaiement.verifie,
      derniereModification: DateTime(2026, 10, 2),
    ),
  ),
  // Payout echoue chez le prestataire : la source permet une nouvelle
  // tentative (nouvelle cle d'idempotence).
  _enseignant(
    13,
    classes: <(String, int, int)>[('Al-Fajr', 60, 6)],
    etat: EtatPaiementSortant.echoue,
    echeance: DateTime(2026, 9, 30),
  ),
  // Verification de la methode requise.
  _enseignant(
    14,
    classes: <(String, int, int)>[('An-Nour', 70, 7)],
    etat: EtatPaiementSortant.verificationRequise,
    permissions: _bloque(RaisonBlocage.verificationRequise),
    destination: const DestinationMasquee(
      type: 'Mobile money',
      operateur: 'Operateur A',
      suffixe: '5520',
      pays: 'GN',
      devise: 'GNF',
      verification: EtatProfilPaiement.enVerification,
    ),
  ),
  // Lie a l'operateur : validation supplementaire (§21.4).
  _enseignant(
    15,
    classes: <(String, int, int)>[('Al-Fatiha', 120, 12)],
    etat: EtatPaiementSortant.validationRequise,
    permissions: _bloque(RaisonBlocage.validationRequise, validation: true),
  ),
  _contractuel(
    4,
    objet: 'Maintenance de septembre',
    unites: 160,
    etat: EtatPaiementSortant.enTransit,
    permissions: PermissionsFinance.lectureSeule,
  ),
  _contractuel(
    5,
    objet: 'Traduction du livret',
    unites: 210,
    etat: EtatPaiementSortant.aVerifier,
    permissions: _bloque(RaisonBlocage.nonApprouvee),
  ),
  // Le Comptable lui-meme (§20, R-FIN-15) : rendu par la source, jamais
  // compare a la session.
  ObligationPayable(
    id: PaiementsDemo.obligationComptable,
    version: 'v1',
    periode: _periode,
    beneficiaire: SocleComptableDemo.leComptable,
    lignes: <LigneCalcul>[
      LigneCalcul(
        id: '${PaiementsDemo.obligationComptable}-l1',
        libelle: 'Forfait mensuel',
        montant: SocleComptableDemo.usd(400),
        source: 'Contrat de prestation comptable',
      ),
    ],
    montant: SocleComptableDemo.usd(400),
    etat: EtatPaiementSortant.pretAPayer,
    echeance: _echeance,
    destination: SocleComptableDemo.destinationBanque,
    prestatairePrevu: _prestA,
    permissions: _bloque(RaisonBlocage.autoPaiement),
  ),
];

ObligationPayable _copie(
  ObligationPayable o, {
  EtatPaiementSortant? etat,
  PermissionsFinance? permissions,
  String? version,
  List<LigneCalcul>? lignes,
  Montant? montant,
}) => ObligationPayable(
  id: o.id,
  version: version ?? o.version,
  periode: o.periode,
  beneficiaire: o.beneficiaire,
  lignes: lignes ?? o.lignes,
  montant: montant ?? o.montant,
  etat: etat ?? o.etat,
  echeance: o.echeance,
  destination: o.destination,
  preuve: o.preuve,
  prestatairePrevu: o.prestatairePrevu,
  permissions: permissions ?? o.permissions,
  classes: o.classes,
);

bool _retenue(ObligationPayable o, FiltreObligations f) {
  if (f.type != null && o.beneficiaire.type != f.type) return false;
  if (f.classe != null && !o.classes.contains(f.classe)) return false;
  return switch (f.filtre) {
    null => true,
    FiltrePaiements.prets => o.etat == EtatPaiementSortant.pretAPayer,
    FiltrePaiements.infos => o.etat == EtatPaiementSortant.infosManquantes,
    FiltrePaiements.verification =>
      o.etat == EtatPaiementSortant.verificationRequise,
    FiltrePaiements.validation =>
      o.etat == EtatPaiementSortant.validationRequise,
    FiltrePaiements.retard =>
      o.echeance.isBefore(SocleComptableDemo.aujourdhui) &&
          !<EtatPaiementSortant>{
            EtatPaiementSortant.soumis,
            EtatPaiementSortant.enTransit,
            EtatPaiementSortant.reussi,
          }.contains(o.etat),
  };
}

/// Frais et change de l'exemple §13.3, tels qu'un prestataire les rendrait
/// (valeurs fictives, aucune conversion faite par l'ecran).
final FraisEtChange _fraisDiallo = FraisEtChange(
  deviseObligation: 'USD',
  devisePayout: 'GNF',
  tauxRendu: '1 USD = 8 600 GNF',
  dateTaux: DateTime(2026, 10, 4, 9, 30),
  fraisPrestataire: const Montant(150, 'USD'),
  montantEnvoye: const Montant(21350, 'USD'),
  montantRecuAttendu: const Montant(1823200, 'GNF'),
);

List<EntreeJournal> _journalDeDepart(String obligationId) => <EntreeJournal>[
  if (obligationId == PaiementsDemo.obligationEchouee)
    EntreeJournal(
      id: '$obligationId-j2',
      date: DateTime(2026, 10, 1),
      initiateur: _prestA,
      objet: 'Payout de septembre',
      ancienEtat: 'En transit',
      nouvelEtat: 'Échoué',
      montant: SocleComptableDemo.usd(60),
      prestataire: _prestA,
      reference: 'DEMO-PAY-0913',
    ),
  EntreeJournal(
    id: '$obligationId-j1',
    date: DateTime(2026, 10, 1),
    initiateur: 'Calcul automatique',
    objet: 'Obligation calculée',
    source: 'Registre de présence de septembre 2026',
    nouvelEtat: 'Calculé',
  ),
];
