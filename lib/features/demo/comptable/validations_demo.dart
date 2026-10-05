// Les validations en demonstration (CPT-BR-09 ; CPT-VAL-1, decision Q-8 =
// (a) du 05/10). **Un seul registre pour toute la demonstration** : une
// demande deposee par le Comptable (`/demo/comptable`, « Demander
// validation ») apparait dans l'onglet « A valider » de la direction
// (`/demo/finance?ecran=aValider`), et la decision de la direction revient
// au Comptable (« Validee » ou « Refusee (motif) »). Hors production
// seulement (K-09) ; aucun appel serveur, aucun paiement.
//
// Le registre fait ce que fera le serveur et que l'ecran ne fait jamais :
// il calcule pour chaque lecteur ce qu'il peut faire d'une demande
// (`approuver` permise, ou bloquee `autoPaiement` quand il est le
// demandeur), refuse une decision du demandeur lui-meme, un refus sans
// motif et une demande deja decidee, et rejoue une cle d'idempotence sans
// seconde decision.

import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import 'socle_comptable_demo.dart';

/// Les identifiants et les personnes remarquables, pour les tests et la
/// recette.
abstract final class ValidationsDemo {
  /// La personne de la direction qui ouvre `/demo/finance`.
  static const String directionId = 'dir-01';

  /// Son nom rendu.
  static const String directionNom = 'Fatoumata Barry (direction)';

  /// Paiement sensible : beneficiaire lie a l'operateur (en attente).
  static const String demandeLieeOperateur = 'val-001';

  /// La paie du Comptable lui-meme (en attente).
  static const String demandePaieComptable = 'val-002';

  /// Retrait de la Reserve strategique (en attente).
  static const String demandeRetraitReserve = 'val-003';

  /// Obligation ponctuelle creee par le Comptable (en attente).
  static const String demandeObligationPonctuelle = 'val-004';

  /// Obligation ponctuelle creee par la direction elle-meme : en attente,
  /// mais la direction ne peut pas la valider.
  static const String demandeDeLaDirection = 'val-005';

  /// Deja validee.
  static const String demandeValidee = 'val-006';

  /// Deja refusee, avec motif.
  static const String demandeRefusee = 'val-007';

  /// L'objet de la demande deja refusee (obligation de demonstration).
  static const String objetRefuse = 'obl-ens-07-2026-09';
}

/// Une demande et son demandeur (identifiant), gardes par le registre.
class _Entree {
  _Entree(this.demande, this.demandeurId);

  DemandeValidation demande;
  final String demandeurId;
}

/// Le registre unique de la demonstration.
class RegistreValidationsDemo {
  RegistreValidationsDemo._() {
    reinitialiser();
  }

  /// L'instance partagee par `/demo/comptable` et `/demo/finance`.
  static final RegistreValidationsDemo instance = RegistreValidationsDemo._();

  final List<_Entree> _entrees = <_Entree>[];
  final Map<String, DemandeValidation> _decisions =
      <String, DemandeValidation>{};
  final Map<String, DemandeValidation> _depots = <String, DemandeValidation>{};
  int _compteur = 0;

  /// Repart de l'etat de depart (tests, nouvelle recette).
  void reinitialiser() {
    _entrees
      ..clear()
      ..addAll(_depart());
    _decisions.clear();
    _depots.clear();
    _compteur = 100;
  }

  /// Depose une demande au nom de [demandeurId], une seule fois par
  /// [cleIdempotence], et une seule demande en attente par objet.
  DemandeValidation deposer({
    required NatureDemandeValidation nature,
    required String demandeurId,
    required String demandeurNom,
    required String objet,
    required Montant montant,
    required RaisonBlocage raison,
    required String cleIdempotence,
    String? objetId,
    String? precision,
  }) {
    final DemandeValidation? deja = _depots[cleIdempotence];
    if (deja != null) return deja;
    if (objetId != null) {
      final DemandeValidation? enAttente = derniere(objetId);
      if (enAttente != null &&
          enAttente.etat == EtatDemandeValidation.enAttente) {
        return _depots[cleIdempotence] = enAttente;
      }
    }
    _compteur++;
    final DemandeValidation demande = DemandeValidation(
      id: 'val-$_compteur',
      nature: nature,
      date: SocleComptableDemo.aujourdhui,
      demandeur: demandeurNom,
      objet: objet,
      montant: montant,
      raison: raison,
      etat: EtatDemandeValidation.enAttente,
      objetId: objetId,
      precision: precision,
    );
    _entrees.insert(0, _Entree(demande, demandeurId));
    return _depots[cleIdempotence] = demande;
  }

  /// La demande la plus recente pour [objetId], ou `null`.
  DemandeValidation? derniere(String objetId) {
    for (final _Entree e in _entrees) {
      if (e.demande.objetId == objetId) return e.demande;
    }
    return null;
  }

  /// Les demandes vues par [lecteurId], filtrees, chacune avec ce que ce
  /// lecteur peut en faire.
  List<DemandeValidation> demandes(
    String lecteurId,
    FiltreDemandesValidation filtre,
  ) => <DemandeValidation>[
    for (final _Entree e in _entrees)
      if ((filtre.etat == null || e.demande.etat == filtre.etat) &&
          (filtre.nature == null || e.demande.nature == filtre.nature) &&
          (filtre.objetId == null || e.demande.objetId == filtre.objetId))
        _pour(e, lecteurId),
  ];

  /// Decide au nom de [lecteurId], comme le fera le serveur.
  DemandeValidation decider({
    required String lecteurId,
    required String lecteurNom,
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) {
    final DemandeValidation? deja = _decisions[cleIdempotence];
    if (deja != null) return deja;
    final _Entree e = _entrees.firstWhere(
      (_Entree x) => x.demande.id == demandeId,
      orElse: () => throw const RefusDecision(MotifRefusDecision.dejaDecidee),
    );
    if (e.demandeurId == lecteurId) {
      throw const RefusDecision(MotifRefusDecision.demandeurNePeutPasValider);
    }
    if (e.demande.etat != EtatDemandeValidation.enAttente) {
      throw const RefusDecision(MotifRefusDecision.dejaDecidee);
    }
    final String? motifPropre = motif?.trim();
    if (decision == DecisionValidation.refuser &&
        (motifPropre == null || motifPropre.isEmpty)) {
      throw const RefusDecision(MotifRefusDecision.motifObligatoire);
    }
    final DemandeValidation d = e.demande;
    e.demande = DemandeValidation(
      id: d.id,
      nature: d.nature,
      date: d.date,
      demandeur: d.demandeur,
      objet: d.objet,
      montant: d.montant,
      raison: d.raison,
      etat: decision == DecisionValidation.valider
          ? EtatDemandeValidation.validee
          : EtatDemandeValidation.refusee,
      objetId: d.objetId,
      decideur: lecteurNom,
      motifDecision: decision == DecisionValidation.refuser
          ? motifPropre
          : null,
      dateDecision: SocleComptableDemo.aujourdhui,
      precision: d.precision,
    );
    return _decisions[cleIdempotence] = _pour(e, lecteurId);
  }

  /// Le journal d'une demande.
  List<EntreeJournal> journal(String demandeId) {
    final _Entree? e = _entrees
        .where((_Entree x) => x.demande.id == demandeId)
        .firstOrNull;
    if (e == null) return const <EntreeJournal>[];
    final DemandeValidation d = e.demande;
    return <EntreeJournal>[
      if (d.etat != EtatDemandeValidation.enAttente)
        EntreeJournal(
          id: '${d.id}-2',
          date: d.dateDecision ?? d.date,
          initiateur: d.decideur ?? '',
          objet: d.objet,
          ancienEtat: 'Validation demandée',
          nouvelEtat: d.etat == EtatDemandeValidation.validee
              ? 'Validée'
              : 'Refusée',
          montant: d.montant,
        ),
      EntreeJournal(
        id: '${d.id}-1',
        date: d.date,
        initiateur: d.demandeur,
        objet: d.objet,
        source: 'Demande de validation',
        nouvelEtat: 'Validation demandée',
        montant: d.montant,
      ),
    ];
  }

  DemandeValidation _pour(_Entree e, String lecteurId) {
    final DemandeValidation d = e.demande;
    final PermissionsFinance permissions =
        d.etat != EtatDemandeValidation.enAttente
        ? PermissionsFinance.lectureSeule
        : e.demandeurId == lecteurId
        ? const PermissionsFinance(
            blocages: <ActionFinance, RaisonBlocage>{
              ActionFinance.approuver: RaisonBlocage.autoPaiement,
            },
          )
        : const PermissionsFinance(
            actions: <ActionFinance>{ActionFinance.approuver},
          );
    return DemandeValidation(
      id: d.id,
      nature: d.nature,
      date: d.date,
      demandeur: d.demandeur,
      objet: d.objet,
      montant: d.montant,
      raison: d.raison,
      etat: d.etat,
      objetId: d.objetId,
      decideur: d.decideur,
      motifDecision: d.motifDecision,
      dateDecision: d.dateDecision,
      precision: d.precision,
      permissions: permissions,
    );
  }
}

/// Le port des validations en demonstration, lu au nom de [lecteurId].
class ValidationsFinanceDemo implements PortValidationsFinance {
  /// Cree le double ; la direction de demonstration lit par defaut.
  const ValidationsFinanceDemo({
    this.lecteurId = ValidationsDemo.directionId,
    this.lecteurNom = ValidationsDemo.directionNom,
  });

  /// Qui lit (le serveur le saura par la session).
  final String lecteurId;

  /// Son nom rendu, ecrit comme decideur.
  final String lecteurNom;

  RegistreValidationsDemo get _registre => RegistreValidationsDemo.instance;

  @override
  Future<List<DemandeValidation>> demandes(
    FiltreDemandesValidation filtre,
  ) async => _registre.demandes(lecteurId, filtre);

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) async => _registre.decider(
    lecteurId: lecteurId,
    lecteurNom: lecteurNom,
    demandeId: demandeId,
    decision: decision,
    cleIdempotence: cleIdempotence,
    motif: motif,
  );

  @override
  Future<List<EntreeJournal>> journal(String demandeId) async =>
      _registre.journal(demandeId);
}

// --- Donnees de depart ------------------------------------------------------

DateTime _jour(int decalage) =>
    SocleComptableDemo.aujourdhui.add(Duration(days: decalage));

List<_Entree> _depart() {
  final String comptable = SocleComptableDemo.leComptable.nom;
  const String cptId = SocleComptableDemo.comptableId;
  return <_Entree>[
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeLieeOperateur,
        nature: NatureDemandeValidation.payoutSensible,
        date: _jour(0),
        demandeur: comptable,
        objet: 'Octobre 2026 · ${SocleComptableDemo.enseignants[14].nom}',
        montant: SocleComptableDemo.usd(120),
        raison: RaisonBlocage.validationRequise,
        etat: EtatDemandeValidation.enAttente,
        objetId: 'obl-ens-15-2026-10',
        precision: 'Bénéficiaire lié à la personne qui prépare le paiement.',
      ),
      cptId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandePaieComptable,
        nature: NatureDemandeValidation.payoutDuComptable,
        date: _jour(-1),
        demandeur: comptable,
        objet: 'Octobre 2026 · $comptable',
        montant: SocleComptableDemo.usd(400),
        raison: RaisonBlocage.autoPaiement,
        etat: EtatDemandeValidation.enAttente,
        objetId: 'obl-cpt-01-2026-10',
        precision: 'Le Comptable ne paie jamais sa propre paie.',
      ),
      cptId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeRetraitReserve,
        nature: NatureDemandeValidation.retraitReserve,
        date: _jour(-1),
        demandeur: comptable,
        objet: 'Retrait de la Réserve stratégique vers la trésorerie libre',
        montant: SocleComptableDemo.usd(500),
        raison: RaisonBlocage.validationRequise,
        etat: EtatDemandeValidation.enAttente,
        objetId: 'mvt-reserve-demo-01',
        precision:
            'Toute sortie de la Réserve stratégique passe par une '
            'seconde personne.',
      ),
      cptId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeObligationPonctuelle,
        nature: NatureDemandeValidation.obligationAApprouver,
        date: _jour(-1),
        demandeur: comptable,
        objet: 'Devis affiches de la rentrée',
        montant: SocleComptableDemo.usd(180),
        raison: RaisonBlocage.nonApprouvee,
        etat: EtatDemandeValidation.enAttente,
        objetId: 'obl-ctr-025',
        precision: 'Obligation ponctuelle : montant figé après approbation.',
      ),
      cptId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeDeLaDirection,
        nature: NatureDemandeValidation.obligationAApprouver,
        date: _jour(-2),
        demandeur: ValidationsDemo.directionNom,
        objet: 'Traduction du support de Tajwid',
        montant: SocleComptableDemo.usd(260),
        raison: RaisonBlocage.nonApprouvee,
        etat: EtatDemandeValidation.enAttente,
        objetId: 'obl-ctr-027',
      ),
      ValidationsDemo.directionId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeValidee,
        nature: NatureDemandeValidation.payoutSensible,
        date: _jour(-4),
        demandeur: comptable,
        objet: 'Septembre 2026 · ${SocleComptableDemo.enseignants[2].nom}',
        montant: SocleComptableDemo.usd(150),
        raison: RaisonBlocage.validationRequise,
        etat: EtatDemandeValidation.validee,
        objetId: 'obl-ens-03-2026-09',
        decideur: ValidationsDemo.directionNom,
        dateDecision: _jour(-3),
        precision: 'Premier paiement de ce bénéficiaire.',
      ),
      cptId,
    ),
    _Entree(
      DemandeValidation(
        id: ValidationsDemo.demandeRefusee,
        nature: NatureDemandeValidation.payoutSensible,
        date: _jour(-5),
        demandeur: comptable,
        objet: 'Septembre 2026 · ${SocleComptableDemo.enseignants[6].nom}',
        montant: SocleComptableDemo.usd(120),
        raison: RaisonBlocage.validationRequise,
        etat: EtatDemandeValidation.refusee,
        objetId: ValidationsDemo.objetRefuse,
        decideur: ValidationsDemo.directionNom,
        motifDecision: 'Coordonnées du bénéficiaire à vérifier',
        dateDecision: _jour(-4),
        precision: 'Coordonnées modifiées il y a 2 jours.',
      ),
      cptId,
    ),
  ];
}
