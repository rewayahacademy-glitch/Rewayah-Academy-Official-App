// Demonstration admin (AD-4) : jeu synthetique de dossiers, etat en memoire
// partage, doubles des deux ports de revue et pont vers l'ecran actuel.
//
// Donnees manifestement fictives, aucune vraie identite, aucune photo : toute
// piece est une `SourcePieceFictive` que l'ecran dessine avec « Document
// fictif ». Le genre n'est jamais stocke : le drapeau `horsPorteeSiPolitique`
// simule l'effet de la regle serveur. Jamais en production (garde de
// `mode_demonstration.dart`).

import '../../core/admin/service_comptes.dart' show EtatPiece;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';

/// Marque de toute piece de demonstration. En dur, hors traductions produit,
/// comme `libelleRepereDemonstration` : le mode n'existe que hors production.
const String libelleDocumentFictif = 'Document fictif';

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
  final DateTime soumisLe;
  final List<AccordSoumis> accords;
  final ConsequenceValidation consequence;
  final ExigencePiece exigence;
  final bool pieceTransmise;
  final TypePiece? typePiece;
  final String? documentId;
  final int? revisionDocument;
  final bool horsPorteeSiPolitique;
  final bool lienExpireSimule;

  bool conflitSimule;
  bool reponsePerdueSimulee;
  StatutRevue statut = StatutRevue.aVerifier;
  int revision;
  AccountStatus etatCompte = AccountStatus.pendingKyc;

  /// L'etat de la piece pour le relecteur, selon la politique courante.
  EtatPieceRevue etatPiece({required bool politiqueGenre}) {
    if (exigence == ExigencePiece.dispensee) {
      return EtatPieceRevue.nonRequise;
    }
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
  final Set<String> vuesExpireesConsommees = <String>{};

  /// Nombre de decisions reellement enregistrees.
  int nombreDecisions = 0;

  DateTime get maintenant => horloge();

  int get nombreAVerifier => dossiers.values
      .where((DossierDemo d) => d.statut == StatutRevue.aVerifier)
      .length;

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
  static const String tuteurDocumentaire = 'demo-dossier-02';
  static const String familleDispensee = 'demo-dossier-03';
  static const String pieceAbsente = 'demo-dossier-04';
  static const String conflit = 'demo-dossier-05';
  static const String horsPortee = 'demo-dossier-06';
  static const String reponsePerdue = 'demo-dossier-07';
  static const String lienExpire = 'demo-dossier-08';

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

  static const List<AccordSoumis> _accordsTuteur = <AccordSoumis>[
    AccordSoumis(
      sorte: SorteContrat.conditionsTuteur,
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
        prenom: 'Idriss',
        nom: 'Exemple',
        role: AppRole.teacher,
        soumisLe: il(72),
        revision: 2,
        documentId: 'demo-piece-01',
        accords: _accordsEnseignant,
        consequence: ConsequenceValidation.activationPossible,
      ),
      DossierDemo(
        id: tuteurDocumentaire,
        identifiantImmuable: 'DEMO-D02',
        prenom: 'Salma',
        nom: 'Essai',
        role: AppRole.guardian,
        soumisLe: il(48),
        revision: 1,
        typePiece: TypePiece.passeport,
        documentId: 'demo-piece-02',
        accords: _accordsTuteur,
        consequence: ConsequenceValidation.documentaireSeule,
      ),
      DossierDemo(
        id: familleDispensee,
        identifiantImmuable: 'DEMO-D03',
        prenom: 'Hana',
        nom: 'Témoin',
        role: AppRole.guardian,
        soumisLe: il(44),
        revision: 1,
        exigence: ExigencePiece.dispensee,
        pieceTransmise: false,
        typePiece: null,
        revisionDocument: null,
        accords: _accordsTuteur,
        consequence: ConsequenceValidation.activationPossible,
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
        role: AppRole.guardian,
        soumisLe: il(28),
        revision: 1,
        documentId: 'demo-piece-07',
        accords: _accordsTuteur,
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
    final List<BlocageRevue> refus = ouvert
        ? const <BlocageRevue>[]
        : const <BlocageRevue>[BlocageRevue.dejaDecide];
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
      consequence: d.consequence,
    );
  }

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) async {
    final DossierDemo d = _dossier(dossierId);
    if (d.documentId == null || d.documentId != documentId) {
      throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
    }
    switch (d.etatPiece(politiqueGenre: etat.politiqueGenre)) {
      case EtatPieceRevue.nonVisible:
        throw const ErreurRevueDossier(CodeErreurRevue.interdit);
      case EtatPieceRevue.absente:
      case EtatPieceRevue.nonRequise:
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
    final DossierDemo d = _dossier(dossierId);
    final ChargeDecision charge = (
      dossierId: dossierId,
      revisionAttendue: revisionAttendue,
      decision: decision,
      motif: motif?.trim(),
    );
    final (ChargeDecision, ResultatDecision)? deja = etat.commandes[commandeId];
    if (deja != null) {
      if (deja.$1 != charge) {
        throw const ErreurRevueDossier(CodeErreurRevue.commandeIncoherente);
      }
      return deja.$2;
    }
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
    }

    final bool valide = decision == DecisionDossier.valider;
    d
      ..statut = valide ? StatutRevue.valide : StatutRevue.refuse
      ..revision += 1;
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
      d.reponsePerdueSimulee = false;
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
    return c == null || c.$1.dossierId != dossierId
        ? const EtatCommandeInconnue()
        : EtatCommandeReussie(c.$2);
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

/// Pont vers l'ecran `ADM-02` actuel, en demonstration seulement (disparait
/// avec AD-5). Il transmet les trois verifications comme faites : l'ecran
/// exige deja les trois coches avant Valider. Jamais hors demonstration.
class ServiceValidationDemo implements ServiceValidation {
  ServiceValidationDemo(this.etat) : _revue = RevueDossiersDemo(etat);

  final EtatRevueDemo etat;
  final RevueDossiersDemo _revue;
  int _commandes = 0;

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
        EtatPieceRevue.absente || EtatPieceRevue.nonRequise => EtatPiece.aucune,
      },
      inscritLeConnue: d.soumisLe.toLocal(),
      etatCompte: d.etatCompte,
    );
  }

  @override
  Future<String> apercu(String cleObjet) =>
      Future<String>.error(const CapaciteIndisponible('AD-BR-03'));

  @override
  Future<void> decider({
    required String documentId,
    required bool approuve,
    String? motif,
  }) async {
    final DossierDemo d = etat.dossiers.values.firstWhere(
      (DossierDemo d) => d.documentId == documentId,
      orElse: () => throw const ErreurRevueDossier(CodeErreurRevue.introuvable),
    );
    _commandes += 1;
    await _revue.decider(
      dossierId: d.id,
      revisionAttendue: d.revision,
      decision: approuve ? DecisionDossier.valider : DecisionDossier.refuser,
      commandeId: 'demo-commande-${d.id}-$_commandes',
      verificationsFaites: verificationsDemo.toSet(),
      motif: motif,
    );
  }
}
