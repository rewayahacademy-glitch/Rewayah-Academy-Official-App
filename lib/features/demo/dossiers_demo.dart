// Demonstration admin (AD-4) : jeu synthetique de dossiers, etat en memoire
// partage, doubles des deux ports de revue et pont vers l'ecran actuel.
//
// Donnees manifestement fictives, aucune vraie identite, aucune photo : toute
// piece est une `SourcePieceFictive` ; la mention visible « Document fictif »
// arrivera avec l'ecran de revue d'AD-7 (l'ecran ADM-02 actuel affiche
// « Apercu indisponible »). Le genre n'est jamais stocke : le drapeau
// `horsPorteeSiPolitique` simule l'effet de la regle serveur. Jamais en
// production (garde de `mode_demonstration.dart`).
//
// Noms : les deux premiers dossiers reprennent les fixtures de
// `persona.dart` (Q12) ; les suivants portent des patronymes manifestement
// fictifs (« Exemple », « Fictif »...), pour la regle « aucune vraie
// identite ».

import 'dart:typed_data';

import '../../core/admin/service_comptes.dart' show EtatPiece;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/selecteur_fichier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/dossier/service_validation.dart';

/// Les trois verifications humaines obligatoires d'une piece disponible.
const List<String> verificationsDemo = <String>['lisible', 'nom', 'validite'];

/// La charge d'une commande, pour l'idempotence.
typedef ChargeDecision = ({
  String dossierId,
  int revisionAttendue,
  DecisionDossier decision,
  String? motif,
});

/// Un dossier synthetique. Ses drapeaux de simulation ne sortent jamais par
/// les ports.
class DossierDemo {
  DossierDemo({
    required this.id,
    required this.identifiantImmuable,
    required this.prenom,
    required this.nom,
    required this.role,
    required this.soumisLe,
    required this.revision,
    required this.accords,
    required this.consequence,
    this.exigence = ExigencePiece.requise,
    this.pieceTransmise = true,
    this.typePiece = TypePiece.carteIdentite,
    this.documentId,
    this.revisionDocument = 1,
    this.horsPorteeSiPolitique = false,
    this.conflitSimule = false,
    this.reponsePerdueSimulee = false,
    this.lienExpireSimule = false,
  });

  final String id;
  final String identifiantImmuable;
  final String prenom;
  final String nom;
  final AppRole role;
  DateTime soumisLe;
  final List<AccordSoumis> accords;
  final ConsequenceValidation consequence;
  final ExigencePiece exigence;
  bool pieceTransmise;
  final TypePiece? typePiece;
  String? documentId;
  int? revisionDocument;

  /// Le motif du dernier refus, lu par le portail de la personne (AD-10).
  String? motifRefus;

  /// Faux quand l'administration interdit la correction du refus (AD-BR-28,
  /// `?dossier=refuse-fige`). Nul : permise, comme en production.
  bool? correctionAutorisee;
  final bool horsPorteeSiPolitique;
  final bool lienExpireSimule;

  bool conflitSimule;
  bool reponsePerdueSimulee;
  StatutRevue statut = StatutRevue.aVerifier;
  int revision;
  AccountStatus etatCompte = AccountStatus.pendingKyc;

  /// L'etat de la piece pour le relecteur, selon la politique courante.
  EtatPieceRevue etatPiece({required bool politiqueGenre}) {
    if (!pieceTransmise) {
      return EtatPieceRevue.absente;
    }
    if (horsPorteeSiPolitique && politiqueGenre) {
      return EtatPieceRevue.nonVisible;
    }
    return EtatPieceRevue.disponible;
  }
}

/// L'etat en memoire, une instance par portee (jamais statique).
class EtatRevueDemo {
  EtatRevueDemo._({
    required this.dossiers,
    required this.politiqueGenre,
    required this.politiqueModifieeLe,
    required this.superAdmin,
    required this.genreRelecteurRenseigne,
    required this.horloge,
  });

  /// L'etat de depart. [maintenant] fige l'horloge (tests).
  factory EtatRevueDemo.initial({
    DateTime? maintenant,
    bool superAdmin = true,
    bool politiqueGenre = true,
    bool genreRelecteurRenseigne = true,
  }) {
    final DateTime Function() horloge = maintenant == null
        ? () => DateTime.now().toUtc()
        : () => maintenant.toUtc();
    final DateTime depart = horloge();
    return EtatRevueDemo._(
      dossiers: <String, DossierDemo>{
        for (final DossierDemo d in DonneesDossiersDemo.fabriquer(depart))
          d.id: d,
      },
      politiqueGenre: politiqueGenre,
      politiqueModifieeLe: depart.subtract(const Duration(days: 30)),
      superAdmin: superAdmin,
      genreRelecteurRenseigne: genreRelecteurRenseigne,
      horloge: horloge,
    );
  }

  /// L'horloge UTC de la demonstration (figee en test).
  final DateTime Function() horloge;
  final Map<String, DossierDemo> dossiers;
  bool politiqueGenre;
  int versionPolitique = 1;
  DateTime politiqueModifieeLe;
  bool superAdmin;
  bool genreRelecteurRenseigne;
  final Map<String, (ChargeDecision, ResultatDecision)> commandes =
      <String, (ChargeDecision, ResultatDecision)>{};

  /// Echecs metier memorises par commande (17.6), rejoues a l'identique.
  final Map<String, (ChargeDecision, CodeErreurRevue)> echecs =
      <String, (ChargeDecision, CodeErreurRevue)>{};

  /// Commandes dont la premiere relecture rend « en attente ».
  final Set<String> commandesEnAttente = <String>{};
  final Set<String> vuesExpireesConsommees = <String>{};

  /// Nombre de decisions reellement enregistrees.
  int nombreDecisions = 0;

  DateTime get maintenant => horloge();

  int get nombreAVerifier => dossiers.values
      .where((DossierDemo d) => d.statut == StatutRevue.aVerifier)
      .length;

  /// La personne corrige son dossier refuse (AD-10, P-ADM-09.4) : une
  /// nouvelle revision revient dans la file, sans reprendre les cases de
  /// l'ancienne piece (la cle de revue porte la revision).
  void resoumettre(String id) {
    final DossierDemo d = dossiers[id]!;
    final int n = (d.revisionDocument ?? 0) + 1;
    d
      ..statut = StatutRevue.aVerifier
      ..revision += 1
      ..pieceTransmise = true
      ..documentId = 'demo-piece-${d.id}-r$n'
      ..revisionDocument = n
      ..soumisLe = maintenant
      ..motifRefus = null;
  }

  /// La file triee : soumission croissante puis identifiant.
  List<DossierDemo> get fileTriee =>
      dossiers.values
          .where((DossierDemo d) => d.statut == StatutRevue.aVerifier)
          .toList()
        ..sort((DossierDemo a, DossierDemo b) {
          final int c = a.soumisLe.compareTo(b.soumisLe);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
}

/// Le jeu synthetique, dates relatives a l'ouverture.
abstract final class DonneesDossiersDemo {
  static const String enseignantNominal = 'demo-dossier-01';
  // K-47 (HL-A-6) : la file ne porte que des enseignants. D03 (famille
  // dispensee, un tuteur) est retire ; D02 garde son identifiant.
  static const String enseignantDocumentaire = 'demo-dossier-02';
  static const String pieceAbsente = 'demo-dossier-04';
  static const String conflit = 'demo-dossier-05';
  static const String horsPortee = 'demo-dossier-06';
  static const String reponsePerdue = 'demo-dossier-07';
  static const String lienExpire = 'demo-dossier-08';
  static const String accordManquant = 'demo-dossier-09';
  static const String decisionIndisponible = 'demo-dossier-10';

  static const List<AccordSoumis> _accordsEnseignantIncomplets = <AccordSoumis>[
    AccordSoumis(
      sorte: SorteContrat.accuseEnregistrementControle,
      version: 'v1',
      etat: EtatAccord.accepte,
    ),
    AccordSoumis(
      sorte: SorteContrat.contratEnseignant,
      etat: EtatAccord.manquant,
    ),
  ];

  static const List<AccordSoumis> _accordsEnseignant = <AccordSoumis>[
    AccordSoumis(
      sorte: SorteContrat.accuseEnregistrementControle,
      version: 'v1',
      etat: EtatAccord.accepte,
    ),
    AccordSoumis(
      sorte: SorteContrat.contratEnseignant,
      version: 'v1',
      etat: EtatAccord.accepte,
    ),
  ];

  static List<DossierDemo> fabriquer(DateTime maintenant) {
    DateTime il(int heures) => maintenant.subtract(Duration(hours: heures));
    return <DossierDemo>[
      DossierDemo(
        id: enseignantNominal,
        identifiantImmuable: 'DEMO-D01',
        prenom: 'Omar',
        nom: 'Haddad',
        role: AppRole.teacher,
        soumisLe: il(72),
        revision: 2,
        documentId: 'demo-piece-01',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
      ),
      DossierDemo(
        id: enseignantDocumentaire,
        identifiantImmuable: 'DEMO-D02',
        prenom: 'Amina',
        nom: 'Benali',
        role: AppRole.teacher,
        soumisLe: il(48),
        revision: 1,
        typePiece: TypePiece.passeport,
        documentId: 'demo-piece-02',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.documentaireSeule,
      ),
      DossierDemo(
        id: pieceAbsente,
        identifiantImmuable: 'DEMO-D04',
        prenom: 'Yanis',
        nom: 'Fictif',
        role: AppRole.teacher,
        soumisLe: il(40),
        revision: 1,
        pieceTransmise: false,
        typePiece: null,
        revisionDocument: null,
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
      ),
      DossierDemo(
        id: conflit,
        identifiantImmuable: 'DEMO-D05',
        prenom: 'Lina',
        nom: 'Modèle',
        role: AppRole.teacher,
        soumisLe: il(36),
        revision: 1,
        documentId: 'demo-piece-05',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
        conflitSimule: true,
      ),
      DossierDemo(
        id: horsPortee,
        identifiantImmuable: 'DEMO-D06',
        prenom: 'Adam',
        nom: 'Démo',
        role: AppRole.teacher,
        soumisLe: il(32),
        revision: 1,
        documentId: 'demo-piece-06',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
        horsPorteeSiPolitique: true,
      ),
      DossierDemo(
        id: reponsePerdue,
        identifiantImmuable: 'DEMO-D07',
        prenom: 'Inès',
        nom: 'Exemple',
        role: AppRole.teacher,
        soumisLe: il(28),
        revision: 1,
        documentId: 'demo-piece-07',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
        reponsePerdueSimulee: true,
      ),
      DossierDemo(
        id: lienExpire,
        identifiantImmuable: 'DEMO-D08',
        prenom: 'Karim',
        nom: 'Fictif',
        role: AppRole.teacher,
        soumisLe: il(24),
        revision: 1,
        documentId: 'demo-piece-08',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
        lienExpireSimule: true,
      ),
      DossierDemo(
        id: accordManquant,
        identifiantImmuable: 'DEMO-D09',
        prenom: 'Sofia',
        nom: 'Exemple',
        role: AppRole.teacher,
        soumisLe: il(20),
        revision: 1,
        documentId: 'demo-piece-09',
        accords: _accordsEnseignantIncomplets,
        consequence: ConsequenceValidation.activationPossible,
      ),
      DossierDemo(
        id: decisionIndisponible,
        identifiantImmuable: 'DEMO-D10',
        prenom: 'Nabil',
        nom: 'Fictif',
        role: AppRole.teacher,
        soumisLe: il(16),
        revision: 1,
        documentId: 'demo-piece-10',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.indeterminee,
      ),
    ];
  }
}

/// Double de demonstration du port de revue, relu a chaque appel (aucun
/// cache) : une bascule de politique se voit tout de suite.
class RevueDossiersDemo implements PortRevueDossiers {
  RevueDossiersDemo(this.etat);

  final EtatRevueDemo etat;

  void _exigerProfil() {
    if (etat.politiqueGenre && !etat.genreRelecteurRenseigne) {
      throw const ErreurRevueDossier(CodeErreurRevue.profilACompleter);
    }
  }

  DossierDemo _dossier(String id) =>
      etat.dossiers[id] ??
      (throw const ErreurRevueDossier(CodeErreurRevue.introuvable));

  List<BlocageRevue> _blocagesValidation(DossierDemo d) {
    if (d.statut != StatutRevue.aVerifier) {
      return const <BlocageRevue>[BlocageRevue.dejaDecide];
    }
    return <BlocageRevue>[
      if (d.etatPiece(politiqueGenre: etat.politiqueGenre) ==
          EtatPieceRevue.absente)
        BlocageRevue.pieceAbsente,
      if (d.etatPiece(politiqueGenre: etat.politiqueGenre) ==
          EtatPieceRevue.nonVisible)
        BlocageRevue.pieceNonVisible,
      if (d.accords.any((AccordSoumis a) => a.etat == EtatAccord.manquant))
        BlocageRevue.accordManquant,
      if (d.consequence == ConsequenceValidation.indeterminee)
        BlocageRevue.decisionIndisponible,
    ];
  }

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) async {
    _exigerProfil();
    final List<DossierDemo> file = etat.fileTriee
        .where((DossierDemo d) => role == null || d.role == role)
        .toList();
    final int debut = (int.tryParse(curseur ?? '') ?? 0).clamp(0, file.length);
    final int fin = (debut + limite).clamp(debut, file.length);
    return PageDossiers(
      elements: <DossierEnFile>[
        for (final DossierDemo d in file.sublist(debut, fin))
          DossierEnFile(
            dossierId: d.id,
            nomAffiche: '${d.prenom} ${d.nom}',
            role: d.role,
            soumisLeUtc: d.soumisLe,
            statut: d.statut,
            revision: d.revision,
            aPieceIdentite: d.pieceTransmise,
            etatPiece: d.etatPiece(politiqueGenre: etat.politiqueGenre),
          ),
      ],
      curseurSuivant: fin < file.length ? '$fin' : null,
      total: file.length,
    );
  }

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) async {
    _exigerProfil();
    final DossierDemo d = _dossier(dossierId);
    final EtatPieceRevue piece = d.etatPiece(
      politiqueGenre: etat.politiqueGenre,
    );
    final bool ouvert = d.statut == StatutRevue.aVerifier;
    final List<BlocageRevue> validation = _blocagesValidation(d);
    // Le filtre de genre s'applique aussi a la decision (0004:545) : un
    // relecteur hors portee ne refuse pas plus qu'il ne valide.
    final List<BlocageRevue> refus = <BlocageRevue>[
      if (!ouvert) BlocageRevue.dejaDecide,
      if (ouvert && piece == EtatPieceRevue.nonVisible)
        BlocageRevue.pieceNonVisible,
    ];
    final List<BlocageRevue> acces = <BlocageRevue>[
      if (piece == EtatPieceRevue.nonVisible) BlocageRevue.pieceNonVisible,
      if (piece == EtatPieceRevue.absente) BlocageRevue.pieceAbsente,
    ];
    return DossierPourRevue(
      dossierId: d.id,
      revision: d.revision,
      prenom: d.prenom,
      nom: d.nom,
      role: d.role,
      soumisLeUtc: d.soumisLe,
      statut: d.statut,
      exigencePiece: d.exigence,
      etatPiece: piece,
      typePiece: d.typePiece,
      documentId: piece == EtatPieceRevue.disponible ? d.documentId : null,
      revisionDocument: piece == EtatPieceRevue.disponible
          ? d.revisionDocument
          : null,
      verifications: <VerificationRevue>[
        if (piece == EtatPieceRevue.disponible)
          for (final String id in verificationsDemo)
            VerificationRevue(
              id: id,
              origine: OrigineVerification.humaine,
              obligatoire: true,
              etat: EtatVerification.aFaire,
              modifiable: ouvert,
            ),
      ],
      accords: d.accords,
      peutValider: validation.isEmpty,
      peutRefuser: refus.isEmpty,
      peutVoirPiece: piece == EtatPieceRevue.disponible,
      blocagesValidation: validation,
      blocagesRefus: refus,
      blocagesAcces: acces,
      peutResoumettre: d.statut == StatutRevue.refuse,
      consequence: d.consequence,
    );
  }

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) async {
    _exigerProfil();
    final DossierDemo d = _dossier(dossierId);
    if (d.documentId == null || d.documentId != documentId) {
      throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
    }
    switch (d.etatPiece(politiqueGenre: etat.politiqueGenre)) {
      case EtatPieceRevue.nonVisible:
        throw const ErreurRevueDossier(CodeErreurRevue.interdit);
      case EtatPieceRevue.absente:
        throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
      case EtatPieceRevue.disponible:
        break;
    }
    if (d.lienExpireSimule && etat.vuesExpireesConsommees.add(d.id)) {
      throw const ErreurRevueDossier(CodeErreurRevue.expire);
    }
    return VuePiece(
      documentId: documentId,
      source: const SourcePieceFictive(),
      expireLeUtc: etat.maintenant.add(const Duration(seconds: 60)),
      typeMime: 'image/png',
    );
  }

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async {
    _exigerProfil();
    final DossierDemo d = _dossier(dossierId);
    final ChargeDecision charge = (
      dossierId: dossierId,
      revisionAttendue: revisionAttendue,
      decision: decision,
      motif: motif?.trim(),
    );
    final (ChargeDecision, ResultatDecision)? deja = etat.commandes[commandeId];
    final (ChargeDecision, CodeErreurRevue)? echec = etat.echecs[commandeId];
    if (deja != null || echec != null) {
      if ((deja?.$1 ?? echec!.$1) != charge) {
        throw const ErreurRevueDossier(CodeErreurRevue.commandeIncoherente);
      }
      if (deja != null) {
        return deja.$2;
      }
      throw ErreurRevueDossier(echec!.$2);
    }
    try {
      return _deciderUneFois(d, charge, commandeId, verificationsFaites);
    } on ErreurRevueDossier catch (e) {
      // Un echec metier est memorise (17.6) ; la reponse perdue, non : la
      // decision a bien ete enregistree.
      if (e.code != CodeErreurRevue.reponsePerdue) {
        etat.echecs[commandeId] = (charge, e.code);
      }
      rethrow;
    }
  }

  ResultatDecision _deciderUneFois(
    DossierDemo d,
    ChargeDecision charge,
    String commandeId,
    Set<String> verificationsFaites,
  ) {
    final DecisionDossier decision = charge.decision;
    final int revisionAttendue = charge.revisionAttendue;
    final String? motif = charge.motif;
    if (d.statut != StatutRevue.aVerifier) {
      throw const ErreurRevueDossier(CodeErreurRevue.dejaDecide);
    }
    if (d.conflitSimule) {
      // Un autre administrateur a tranche juste avant.
      d
        ..conflitSimule = false
        ..statut = StatutRevue.valide
        ..revision += 1;
      throw const ErreurRevueDossier(CodeErreurRevue.perime);
    }
    if (revisionAttendue != d.revision) {
      throw const ErreurRevueDossier(CodeErreurRevue.perime);
    }
    if (decision == DecisionDossier.refuser) {
      if (d.etatPiece(politiqueGenre: etat.politiqueGenre) ==
          EtatPieceRevue.nonVisible) {
        throw const ErreurRevueDossier(CodeErreurRevue.interdit);
      }
      if ((motif ?? '').trim().isEmpty) {
        throw const ErreurRevueDossier(CodeErreurRevue.motifRequis);
      }
    } else {
      final EtatPieceRevue piece = d.etatPiece(
        politiqueGenre: etat.politiqueGenre,
      );
      if (piece == EtatPieceRevue.absente ||
          piece == EtatPieceRevue.nonVisible) {
        throw const ErreurRevueDossier(CodeErreurRevue.pieceIndisponible);
      }
      if (piece == EtatPieceRevue.disponible &&
          !verificationsFaites.containsAll(verificationsDemo)) {
        throw const ErreurRevueDossier(CodeErreurRevue.verificationManquante);
      }
      if (d.accords.any((AccordSoumis a) => a.etat == EtatAccord.manquant)) {
        throw const ErreurRevueDossier(CodeErreurRevue.accordManquant);
      }
      // 17.4 : `can_validate` lu auparavant ne vaut pas autorisation.
      if (d.consequence == ConsequenceValidation.indeterminee) {
        throw const ErreurRevueDossier(
          CodeErreurRevue.indisponibleTemporairement,
        );
      }
    }

    final bool valide = decision == DecisionDossier.valider;
    d
      ..statut = valide ? StatutRevue.valide : StatutRevue.refuse
      ..revision += 1
      ..motifRefus = valide ? null : motif!.trim();
    if (valide && d.consequence == ConsequenceValidation.activationPossible) {
      d.etatCompte = AccountStatus.active;
    }
    final ResultatDecision resultat = ResultatDecision(
      dossierId: d.id,
      statutFinal: d.statut,
      etatCompte: d.etatCompte,
      nouvelleRevision: d.revision,
      decideLeUtc: etat.maintenant,
    );
    etat.commandes[commandeId] = (charge, resultat);
    etat.nombreDecisions += 1;
    if (d.reponsePerdueSimulee) {
      // La decision est enregistree, seule la reponse se perd.
      // La premiere relecture la dira encore « en attente ».
      d.reponsePerdueSimulee = false;
      etat.commandesEnAttente.add(commandeId);
      throw const ErreurRevueDossier(CodeErreurRevue.reponsePerdue);
    }
    return resultat;
  }

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) async {
    final (ChargeDecision, ResultatDecision)? c = etat.commandes[commandeId];
    final (ChargeDecision, CodeErreurRevue)? e = etat.echecs[commandeId];
    if (c != null && c.$1.dossierId == dossierId) {
      return etat.commandesEnAttente.remove(commandeId)
          ? const EtatCommandeEnAttente()
          : EtatCommandeReussie(c.$2);
    }
    if (e != null && e.$1.dossierId == dossierId) {
      return EtatCommandeEchouee(e.$2);
    }
    return const EtatCommandeInconnue();
  }
}

/// Double de demonstration de la politique ; capacite Super Admin simulee
/// ici seulement (Q40).
class PolitiqueRevueKycDemo implements PortPolitiqueRevueKyc {
  PolitiqueRevueKycDemo(this.etat);

  final EtatRevueDemo etat;

  PolitiqueRevueKyc _lue() => PolitiqueRevueKyc(
    genreRelecteurApplique: etat.politiqueGenre,
    version: etat.versionPolitique,
    modifieeLeUtc: etat.politiqueModifieeLe,
    peutModifier: etat.superAdmin,
  );

  @override
  Future<PolitiqueRevueKyc> lire() async => _lue();

  @override
  Future<PolitiqueRevueKyc> modifier({
    required bool genreRelecteurApplique,
    required int versionAttendue,
  }) async {
    if (!etat.superAdmin) {
      throw const ErreurRevueDossier(CodeErreurRevue.interdit);
    }
    if (versionAttendue != etat.versionPolitique) {
      throw const ErreurRevueDossier(CodeErreurRevue.perime);
    }
    etat
      ..politiqueGenre = genreRelecteurApplique
      ..versionPolitique += 1
      ..politiqueModifieeLe = etat.maintenant;
    return _lue();
  }
}

/// Pont vers les decisions de la revue (`revue_dossier.dart`), en
/// demonstration seulement : depuis AD-6, le detail est lu par le port et ce
/// pont ne sert plus qu'a lister la file (`enAttente`). Les decisions passent
/// par `RevueDossiersDemo` ; ici, [decider] refuse. Jamais hors demonstration.
class ServiceValidationDemo implements ServiceValidation {
  ServiceValidationDemo(this.etat);

  final EtatRevueDemo etat;

  /// Toute la file, dans l'ordre du port (AD-5) : chaque ligne de la file
  /// doit trouver son detail ici, sinon elle ouvrirait « Ce dossier n'est
  /// plus disponible ». La revue actuelle sait deja dire « rien a trancher ».
  @override
  Future<List<DossierAValider>> enAttente() async {
    if (etat.politiqueGenre && !etat.genreRelecteurRenseigne) {
      throw const GenreLecteurInconnu();
    }
    return <DossierAValider>[
      for (final DossierDemo d in etat.fileTriee) _versEcran(d),
    ];
  }

  DossierAValider _versEcran(DossierDemo d) {
    final EtatPieceRevue piece = d.etatPiece(
      politiqueGenre: etat.politiqueGenre,
    );
    final bool disponible = piece == EtatPieceRevue.disponible;
    return DossierAValider(
      documentId: disponible ? d.documentId : null,
      profilId: d.id,
      type: d.typePiece,
      // Cle factice : l'apercu est de toute facon indisponible, aucune URL.
      cleObjet: disponible ? 'demo-fictif/${d.documentId}' : null,
      deposeLe: d.soumisLe.toLocal(),
      prenom: d.prenom,
      nom: d.nom,
      identifiantImmuable: d.identifiantImmuable,
      role: d.role,
      etatPiece: switch (piece) {
        EtatPieceRevue.disponible => EtatPiece.aVerifier,
        EtatPieceRevue.nonVisible => EtatPiece.nonVisible,
        EtatPieceRevue.absente => EtatPiece.aucune,
      },
      inscritLeConnue: d.soumisLe.toLocal(),
      etatCompte: d.etatCompte,
    );
  }

  @override
  Future<String> apercu(String cleObjet) =>
      Future<String>.error(const CapaciteIndisponible('AD-BR-03'));

  /// AD-NETTOYAGE-2 (n10) : ce pont n'a aucun appelant dans l'application (la
  /// demonstration branche `RevueDossiersDemo` sur le port, qui lit les
  /// verifications reellement cochees). Il transmettait jusqu'ici les trois
  /// verifications comme faites, quoi qu'ait coche l'administrateur : un
  /// chemin de decision qui contournait les cases. Il refuse donc.
  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) => Future<void>.error(const CapaciteIndisponible('AD-8'));
}

/// Le dossier vu par la personne elle-meme (AD-10), lu dans le meme etat que
/// la revue admin : une decision de l'administration s'y voit a la relecture.
/// Accuse et contrat sont tenus pour signes (le jeu ne simule que la piece).
class ServiceDossierDemo implements ServiceDossier {
  ServiceDossierDemo(this.etatRevue, this.titulaire);

  final EtatRevueDemo etatRevue;
  final String titulaire;

  DossierDemo get _d => etatRevue.dossiers[titulaire]!;

  @override
  bool get demonstration => true;

  @override
  Future<void> creerProfil({
    required AppRole role,
    required String prenom,
    required String nom,
    Genre? genre,
  }) async {}

  @override
  Future<EtatDossier> etat() async {
    final DossierDemo d = _d;
    return EtatDossier(
      profilExiste: true,
      role: d.role,
      statutCompte: d.etatCompte,
      pieceDeposee: d.pieceTransmise,
      statutPiece: switch (d.statut) {
        StatutRevue.aVerifier => StatutPiece.enAttente,
        StatutRevue.valide => StatutPiece.validee,
        StatutRevue.refuse => StatutPiece.refusee,
      },
      motifRefus: d.motifRefus,
      deposeLe: d.soumisLe,
      contratSigne: true,
      accuseSigne: true,
      correctionAutorisee: d.correctionAutorisee,
      // Le titulaire est toujours un enseignant (K-47) : piece exigee.
      pieceRequise: true,
    );
  }

  @override
  Future<void> accepterContrat(SorteContrat sorte, String version) async {}

  @override
  Future<void> deposerPiece(PieceAEnvoyer piece) async =>
      etatRevue.resoumettre(titulaire);
}

/// Un choix de fichier sans fichier : quelques octets synthetiques, jamais
/// une image realiste (« document-fictif.png »).
class SelecteurFichierDemo implements SelecteurFichier {
  const SelecteurFichierDemo();

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async => PieceAEnvoyer(
    octets: Uint8List.fromList(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature PNG
    ]),
    nomFichier: 'document-fictif.png',
    type: type,
  );
}
