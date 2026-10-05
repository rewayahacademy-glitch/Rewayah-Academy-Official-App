// La demonstration des encaissements et du rapprochement (CPT-BR-07, 14,
// 15). Posee vide par CPT-F ; **propriete de la voie CPT-ENC ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Spec §44 tenue et depassee :
// six encaissements (un par etat utile aux filtres §33), deux remboursements
// (un que la politique permet d'executer, un qui attend son approbation),
// six elements a rapprocher dont deux rapprochements proposes et un doublon
// potentiel.
//
// Aucun appel serveur, aucune vraie famille, aucun vrai prestataire (noms
// neutres « (demonstration) », DR-21). Les ecritures (`rapprocher`,
// `marquerDoublon`, `executerRemboursement`) rendent l'etat qu'une source
// rendrait, jamais un succes invente : un remboursement execute reste
// « Approuve » en attendant le prestataire, pas « Execute » (spec §5.3). Les
// reponses sont memorisees par cle d'idempotence : la meme cle rejouee rend
// la meme reponse, une seule fois agie.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_encaissements.dart';
import '../../../core/capacites/port_rapprochement.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../comptable/encaissements/donnees_encaissements.dart';
import '../../comptable/encaissements/rapprochement/donnees_rapprochement.dart';
import 'socle_comptable_demo.dart';

/// Les donnees de la demonstration, lisibles par les tests.
abstract final class DonneesEncaissementsDemo {
  static Montant _usd(int centimes) =>
      Montant(centimes, SocleComptableDemo.devise);

  static String _prestataire(int i) => t.comptable.commun
      .prestataireDemonstration(nom: SocleComptableDemo.prestataires[i].nom);

  /// L'encaissement confirme et deja rapproche (celui de l'adresse de
  /// demonstration du detail, `enc-01`).
  static const String encConfirme = 'enc-01';

  /// L'encaissement confirme, a rapprocher.
  static const String encARapprocher = 'enc-02';

  /// L'encaissement en attente du prestataire.
  static const String encEnAttente = 'enc-03';

  /// La transaction proposee a verifier.
  static const String trxAVerifier = 'trx-02';

  /// La transaction vue en doublon potentiel.
  static const String trxDoublon = 'trx-03';

  /// La transaction hors delegation (raison de blocage rendue).
  static const String trxHorsDelegation = 'trx-04';

  /// Le remboursement que la politique permet d'executer.
  static const String rembApprouve = 'remb-01';

  /// Le remboursement qui attend une approbation.
  static const String rembAApprouver = 'remb-02';

  /// Les encaissements, du plus recent au plus ancien.
  static List<Encaissement> encaissements() => <Encaissement>[
    Encaissement(
      id: encConfirme,
      date: DateTime(2026, 10, 3, 14, 32),
      famille: 'Famille Bah',
      brut: _usd(12000),
      frais: _usd(378),
      net: _usd(11622),
      moyen: 'Carte bancaire',
      prestataire: _prestataire(0),
      reference: 'DEMO-7A21',
      etat: EtatEncaissement.rapproche,
      rapprochement: EtatRapprochement.automatique,
      foyerId: 'foyer-bah',
      profils: <AffectationProfil>[
        AffectationProfil(
          profilId: 'p-amina',
          prenom: 'Amina',
          montant: _usd(6000),
        ),
        AffectationProfil(
          profilId: 'p-ibrahim',
          prenom: 'Ibrahim',
          montant: _usd(6000),
        ),
      ],
    ),
    Encaissement(
      id: encARapprocher,
      date: DateTime(2026, 10, 3, 9, 5),
      famille: 'Famille Diallo',
      brut: _usd(6000),
      frais: _usd(189),
      net: _usd(5811),
      moyen: 'Mobile money',
      prestataire: _prestataire(0),
      reference: 'DEMO-7A1F',
      etat: EtatEncaissement.aRapprocher,
      rapprochement: EtatRapprochement.aVerifier,
      foyerId: 'foyer-diallo',
      profils: <AffectationProfil>[
        AffectationProfil(
          profilId: 'p-youssef',
          prenom: 'Youssef',
          montant: _usd(6000),
        ),
      ],
    ),
    Encaissement(
      id: encEnAttente,
      date: DateTime(2026, 10, 2, 18, 40),
      famille: 'Famille Sylla',
      brut: _usd(9000),
      frais: _usd(0),
      net: _usd(9000),
      moyen: 'Carte bancaire',
      prestataire: _prestataire(1),
      reference: 'DEMO-79E4',
      etat: EtatEncaissement.enAttente,
      foyerId: 'foyer-sylla',
      profils: <AffectationProfil>[
        AffectationProfil(
          profilId: 'p-maryam',
          prenom: 'Maryam',
          montant: _usd(4500),
        ),
        AffectationProfil(
          profilId: 'p-souleymane',
          prenom: 'Souleymane',
          montant: _usd(4500),
        ),
      ],
    ),
    Encaissement(
      id: 'enc-04',
      date: DateTime(2026, 10, 1, 11, 12),
      famille: 'Famille Camara',
      brut: _usd(6000),
      frais: _usd(0),
      net: _usd(0),
      moyen: 'Carte bancaire',
      prestataire: _prestataire(0),
      reference: 'DEMO-79C0',
      etat: EtatEncaissement.echoue,
      foyerId: 'foyer-camara',
    ),
    Encaissement(
      id: 'enc-05',
      date: DateTime(2026, 9, 29, 16, 20),
      famille: 'Famille Keita',
      brut: _usd(12000),
      frais: _usd(378),
      net: _usd(11622),
      moyen: 'Mobile money',
      prestataire: _prestataire(0),
      reference: 'DEMO-7955',
      etat: EtatEncaissement.partiellementRembourse,
      rapprochement: EtatRapprochement.rapproche,
      foyerId: 'foyer-keita',
      profils: <AffectationProfil>[
        AffectationProfil(
          profilId: 'p-hawa',
          prenom: 'Hawa',
          montant: _usd(6000),
        ),
        AffectationProfil(
          profilId: 'p-moussa',
          prenom: 'Moussa',
          montant: _usd(6000),
        ),
      ],
    ),
    Encaissement(
      id: 'enc-06',
      date: DateTime(2026, 9, 27, 10, 2),
      famille: 'Famille Touré',
      brut: _usd(6000),
      frais: _usd(189),
      net: _usd(5811),
      moyen: 'Carte bancaire',
      prestataire: _prestataire(0),
      reference: 'DEMO-7930',
      etat: EtatEncaissement.conteste,
      rapprochement: EtatRapprochement.conflit,
      foyerId: 'foyer-toure',
      profils: <AffectationProfil>[
        AffectationProfil(
          profilId: 'p-fatou',
          prenom: 'Fatoumata',
          montant: _usd(6000),
        ),
      ],
    ),
  ];

  /// Les remboursements et avoirs (§26).
  static List<Remboursement> remboursements() => <Remboursement>[
    Remboursement(
      id: rembApprouve,
      date: DateTime(2026, 9, 30),
      beneficiaire: 'Famille Keita',
      motif: 'Séance annulée par l’académie',
      montant: _usd(3000),
      source: 'Encaissement DEMO-7955',
      etat: EtatRemboursement.approuve,
      approbationRequise: false,
      encaissementId: 'enc-05',
      permissions: const PermissionsFinance(
        actions: <ActionFinance>{ActionFinance.rembourser},
      ),
    ),
    Remboursement(
      id: rembAApprouver,
      date: DateTime(2026, 10, 2),
      beneficiaire: 'Famille Touré',
      motif: 'Paiement contesté auprès du prestataire',
      montant: _usd(6000),
      source: 'Encaissement DEMO-7930',
      etat: EtatRemboursement.approbationRequise,
      approbationRequise: true,
      encaissementId: 'enc-06',
      permissions: const PermissionsFinance(
        blocages: <ActionFinance, RaisonBlocage>{
          ActionFinance.rembourser: RaisonBlocage.validationRequise,
        },
      ),
    ),
  ];

  static const PermissionsFinance _peutRapprocher = PermissionsFinance(
    actions: <ActionFinance>{ActionFinance.rapprocher},
  );

  /// Les elements de l'espace de rapprochement (§25).
  static List<ElementRapprochement> elements() => <ElementRapprochement>[
    ElementRapprochement(
      id: 'trx-01',
      nature: NatureElementRapprochement.transactionPrestataire,
      date: DateTime(2026, 10, 3, 14, 32),
      libelle: 'Famille Bah · carte bancaire',
      montant: _usd(12000),
      etat: EtatRapprochement.automatique,
      reference: 'DEMO-7A21',
      prestataire: _prestataire(0),
      cibleId: 'att-bah-10',
      cibleLibelle: 'Mensualité d’octobre · Amina et Ibrahim',
    ),
    ElementRapprochement(
      id: trxAVerifier,
      nature: NatureElementRapprochement.transactionPrestataire,
      date: DateTime(2026, 10, 3, 9, 5),
      libelle: 'Famille Diallo · mobile money',
      montant: _usd(6000),
      etat: EtatRapprochement.aVerifier,
      reference: 'DEMO-7A1F',
      prestataire: _prestataire(0),
      permissions: _peutRapprocher,
    ),
    ElementRapprochement(
      id: trxDoublon,
      nature: NatureElementRapprochement.transactionPrestataire,
      date: DateTime(2026, 10, 3, 9, 7),
      libelle: 'Famille Diallo · mobile money',
      montant: _usd(6000),
      etat: EtatRapprochement.doublonPotentiel,
      reference: 'DEMO-7A20',
      prestataire: _prestataire(0),
      permissions: _peutRapprocher,
    ),
    ElementRapprochement(
      id: trxHorsDelegation,
      nature: NatureElementRapprochement.frais,
      date: DateTime(2026, 10, 1),
      libelle: 'Frais mensuels du prestataire',
      montant: _usd(-1500),
      etat: EtatRapprochement.sansCorrespondance,
      reference: 'DEMO-F10',
      prestataire: _prestataire(0),
      permissions: const PermissionsFinance(
        blocages: <ActionFinance, RaisonBlocage>{
          ActionFinance.rapprocher: RaisonBlocage.horsDelegation,
        },
      ),
    ),
    ElementRapprochement(
      id: 'trx-05',
      nature: NatureElementRapprochement.transactionPrestataire,
      date: DateTime(2026, 9, 27, 10, 2),
      libelle: 'Famille Touré · carte bancaire',
      montant: _usd(6000),
      etat: EtatRapprochement.conflit,
      reference: 'DEMO-7930',
      prestataire: _prestataire(0),
      permissions: _peutRapprocher,
    ),
    ElementRapprochement(
      id: 'trx-06',
      nature: NatureElementRapprochement.transactionPrestataire,
      date: DateTime(2026, 9, 29, 16, 20),
      libelle: 'Famille Keita · mobile money',
      montant: _usd(12000),
      etat: EtatRapprochement.rapproche,
      reference: 'DEMO-7955',
      prestataire: _prestataire(0),
      cibleId: 'att-keita-10',
      cibleLibelle: 'Mensualité d’octobre · Hawa et Moussa',
    ),
  ];

  /// Les candidats proposes pour une transaction.
  static PropositionRapprochement proposition(String transactionId) {
    ElementRapprochement attendu(String id, String libelle) =>
        ElementRapprochement(
          id: id,
          nature: NatureElementRapprochement.paiementAttendu,
          date: DateTime(2026, 10, 1),
          libelle: libelle,
          montant: _usd(6000),
          etat: EtatRapprochement.aVerifier,
        );
    return switch (transactionId) {
      trxAVerifier => PropositionRapprochement(
        transactionId: transactionId,
        candidats: <ElementRapprochement>[
          attendu('att-diallo-10', 'Mensualité d’octobre · Youssef'),
        ],
      ),
      trxDoublon => PropositionRapprochement(
        transactionId: transactionId,
        doublonPotentiel: true,
        candidats: <ElementRapprochement>[
          attendu('att-diallo-10', 'Mensualité d’octobre · Youssef'),
        ],
      ),
      'trx-05' => PropositionRapprochement(
        transactionId: transactionId,
        candidats: <ElementRapprochement>[
          attendu('att-toure-10', 'Mensualité d’octobre · Fatoumata'),
          attendu('att-toure-09', 'Mensualité de septembre · Fatoumata'),
        ],
      ),
      _ => PropositionRapprochement(
        transactionId: transactionId,
        candidats: const <ElementRapprochement>[],
      ),
    };
  }

  /// Le journal d'un objet (§48), tel qu'une source le rendrait.
  static List<EntreeJournal> journal(String objetId) {
    final String prestataire = _prestataire(0);
    final statuts = t.comptable.statuts;
    return switch (objetId) {
      encConfirme => <EntreeJournal>[
        EntreeJournal(
          id: 'j-01',
          date: DateTime(2026, 10, 3, 14, 33),
          initiateur: prestataire,
          objet: 'Paiement reçu de la Famille Bah',
          ancienEtat: statuts.encaissement.enAttente,
          nouvelEtat: statuts.encaissement.confirme,
          montant: _usd(12000),
          prestataire: prestataire,
          reference: 'DEMO-7A21',
        ),
        EntreeJournal(
          id: 'j-02',
          date: DateTime(2026, 10, 3, 14, 35),
          initiateur: 'Rapprochement automatique',
          objet: 'Relié à la mensualité d’octobre',
          ancienEtat: statuts.encaissement.aRapprocher,
          nouvelEtat: statuts.encaissement.rapproche,
          reference: 'DEMO-7A21',
        ),
      ],
      trxDoublon => <EntreeJournal>[
        EntreeJournal(
          id: 'j-10',
          date: DateTime(2026, 10, 3, 9, 8),
          initiateur: prestataire,
          objet: 'Transaction reçue deux minutes après DEMO-7A1F',
          nouvelEtat: statuts.rapprochement.doublonPotentiel,
          montant: _usd(6000),
          reference: 'DEMO-7A20',
        ),
      ],
      rembApprouve => <EntreeJournal>[
        EntreeJournal(
          id: 'j-20',
          date: DateTime(2026, 9, 30, 10),
          initiateur: 'La direction',
          objet: 'Remboursement accordé selon la politique',
          ancienEtat: statuts.remboursement.demande,
          nouvelEtat: statuts.remboursement.approuve,
          montant: _usd(3000),
        ),
      ],
      _ => const <EntreeJournal>[],
    };
  }
}

/// Les encaissements en demonstration.
class EncaissementsDemo implements PortEncaissements {
  /// Cree le double.
  EncaissementsDemo();

  /// Les reponses deja rendues, par cle d'idempotence.
  final Map<String, Remboursement> _parCle = <String, Remboursement>{};

  /// L'etat courant d'un remboursement apres une execution.
  final Map<String, Remboursement> _parId = <String, Remboursement>{};

  @override
  Future<List<Encaissement>> liste(FiltreEncaissements filtre) async {
    final String recherche = (filtre.recherche ?? '').trim().toLowerCase();
    return <Encaissement>[
      for (final Encaissement e in DonneesEncaissementsDemo.encaissements())
        if ((filtre.etat == null || e.etat == filtre.etat) &&
            (recherche.isEmpty ||
                e.famille.toLowerCase().contains(recherche) ||
                e.reference.toLowerCase().contains(recherche)))
          e,
    ];
  }

  @override
  Future<Encaissement> detail(String encaissementId) async {
    for (final Encaissement e in DonneesEncaissementsDemo.encaissements()) {
      if (e.id == encaissementId) return e;
    }
    throw const CapaciteIndisponible('CPT-BR-07');
  }

  @override
  Future<List<Remboursement>> remboursements(
    FiltreRemboursements filtre,
  ) async => <Remboursement>[
    for (final Remboursement r in DonneesEncaissementsDemo.remboursements())
      if (filtre.etat == null || (_parId[r.id] ?? r).etat == filtre.etat)
        _parId[r.id] ?? r,
  ];

  @override
  Future<Remboursement> executerRemboursement({
    required String remboursementId,
    required String cleIdempotence,
  }) async {
    final Remboursement? deja = _parCle[cleIdempotence];
    if (deja != null) return deja;
    final Remboursement r =
        _parId[remboursementId] ??
        DonneesEncaissementsDemo.remboursements().firstWhere(
          (Remboursement x) => x.id == remboursementId,
        );
    if (!r.permissions.permet(ActionFinance.rembourser)) {
      throw const CapaciteIndisponible('CPT-BR-15');
    }
    // Pas de faux succes : la demande part, le prestataire n'a encore rien
    // confirme. L'etat reste « Approuve » et l'action n'est plus permise.
    final Remboursement soumis = Remboursement(
      id: r.id,
      date: r.date,
      beneficiaire: r.beneficiaire,
      motif: r.motif,
      montant: r.montant,
      source: r.source,
      etat: EtatRemboursement.approuve,
      approbationRequise: r.approbationRequise,
      encaissementId: r.encaissementId,
    );
    _parCle[cleIdempotence] = soumis;
    _parId[r.id] = soumis;
    return soumis;
  }

  @override
  Future<List<EntreeJournal>> journal(String objetId) async =>
      DonneesEncaissementsDemo.journal(objetId);
}

/// Le rapprochement en demonstration.
class RapprochementDemo implements PortRapprochement {
  /// Cree le double.
  RapprochementDemo();

  final Map<String, ElementRapprochement> _parCle =
      <String, ElementRapprochement>{};
  final Map<String, ElementRapprochement> _parId =
      <String, ElementRapprochement>{};

  @override
  Future<List<ElementRapprochement>> aRapprocher(
    FiltreRapprochement filtre,
  ) async => <ElementRapprochement>[
    for (final ElementRapprochement e in DonneesEncaissementsDemo.elements())
      if ((filtre.etat == null || (_parId[e.id] ?? e).etat == filtre.etat) &&
          (filtre.nature == null || e.nature == filtre.nature))
        _parId[e.id] ?? e,
  ];

  @override
  Future<PropositionRapprochement> proposer(String transactionId) async =>
      DonneesEncaissementsDemo.proposition(transactionId);

  ElementRapprochement _element(String id) =>
      _parId[id] ??
      DonneesEncaissementsDemo.elements().firstWhere(
        (ElementRapprochement e) => e.id == id,
      );

  ElementRapprochement _apres(
    ElementRapprochement e,
    EtatRapprochement etat, {
    String? cibleId,
    String? cibleLibelle,
  }) => ElementRapprochement(
    id: e.id,
    nature: e.nature,
    date: e.date,
    libelle: e.libelle,
    montant: e.montant,
    etat: etat,
    reference: e.reference,
    prestataire: e.prestataire,
    cibleId: cibleId ?? e.cibleId,
    cibleLibelle: cibleLibelle ?? e.cibleLibelle,
  );

  Future<ElementRapprochement> _ecrire(
    String transactionId,
    String cleIdempotence,
    ElementRapprochement Function(ElementRapprochement e) apres,
  ) async {
    final ElementRapprochement? deja = _parCle[cleIdempotence];
    if (deja != null) return deja;
    final ElementRapprochement e = _element(transactionId);
    if (!e.permissions.permet(ActionFinance.rapprocher)) {
      throw const CapaciteIndisponible('CPT-BR-14');
    }
    final ElementRapprochement reponse = apres(e);
    _parCle[cleIdempotence] = reponse;
    _parId[transactionId] = reponse;
    return reponse;
  }

  @override
  Future<ElementRapprochement> rapprocher({
    required String transactionId,
    required String cibleId,
    required String cleIdempotence,
  }) {
    final String libelleCible =
        DonneesEncaissementsDemo.proposition(transactionId).candidats
            .where((ElementRapprochement c) => c.id == cibleId)
            .map((ElementRapprochement c) => c.libelle)
            .fold<String>(cibleId, (String _, String l) => l);
    return _ecrire(
      transactionId,
      cleIdempotence,
      (ElementRapprochement e) => _apres(
        e,
        EtatRapprochement.rapproche,
        cibleId: cibleId,
        cibleLibelle: libelleCible,
      ),
    );
  }

  @override
  Future<ElementRapprochement> marquerDoublon({
    required String transactionId,
    required String cleIdempotence,
  }) =>
      // Le doublon reste visible et marque, sans action : jamais efface en
      // silence (§47). La source le relie a la transaction d'origine.
      _ecrire(
        transactionId,
        cleIdempotence,
        (ElementRapprochement e) => _apres(
          e,
          EtatRapprochement.doublonPotentiel,
          cibleId: DonneesEncaissementsDemo.trxAVerifier,
          cibleLibelle: 'Transaction DEMO-7A1F',
        ),
      );

  @override
  Future<List<EntreeJournal>> journal(String elementId) async =>
      DonneesEncaissementsDemo.journal(elementId);
}

/// Les surcharges de la demonstration des encaissements.
///
/// La coquille de demonstration est une portee imbriquee : un lecteur
/// derive (liste, detail, journal) non surcharge vivrait dans le conteneur
/// racine et lirait le vrai port, sans source. Chaque lecteur de la voie
/// est donc recree ici, dans la portee, sur les ports de demonstration
/// (meme parade que `demo_finance_page.dart`).
List<Override> surchargesDemoEncaissements() {
  final EncaissementsDemo enc = EncaissementsDemo();
  final RapprochementDemo rap = RapprochementDemo();
  return <Override>[
    portEncaissementsProvider.overrideWithValue(enc),
    portRapprochementProvider.overrideWithValue(rap),
    listeEncaissementsProvider.overrideWith(
      (Ref _) => enc.liste(FiltreEncaissements.tout),
    ),
    detailEncaissementProvider.overrideWith(
      (Ref _, String id) => enc.detail(id),
    ),
    journalEncaissementProvider.overrideWith(
      (Ref _, String id) => enc.journal(id),
    ),
    remboursementsProvider.overrideWith(
      (Ref _) => enc.remboursements(FiltreRemboursements.tout),
    ),
    elementsRapprochementProvider.overrideWith(
      (Ref _) => rap.aRapprocher(FiltreRapprochement.tout),
    ),
    propositionRapprochementProvider.overrideWith(
      (Ref _, String id) => rap.proposer(id),
    ),
    journalRapprochementProvider.overrideWith(
      (Ref _, String id) => rap.journal(id),
    ),
  ];
}
