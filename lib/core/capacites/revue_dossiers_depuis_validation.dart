// Adaptateur de production du port de revue (AD-5, AD-6), construit sur le
// service existant `ServiceValidation` : AUCUN nouvel appel serveur. La file
// et le detail partagent le meme cache (`dossiersEnAttenteProvider`), donc un
// seul appel a la RPC existante `dossiers_en_attente`.
//
// Ce que la RPC ne fournit pas reste honnetement absent : ni total, ni
// curseur, ni revision, ni accord versionne, ni consequence (AD-BR-01, 02,
// 06). AD-8 : la decision passe par le port, sur la RPC EXISTANTE
// `decider_dossier` (ServiceValidation.decider), sans idempotence ni revision
// serveur (AD-BR-06, AD-BR-07) : apres un resultat inconnu, l'etat est relu
// (file en cache, puis rechargement existant de `dossiers_en_attente`).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 a sorti `Override` de l'export principal.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderException;
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, PostgrestException;

import '../admin/service_comptes.dart' show EtatPiece;
import '../domain/enums.dart';
import '../dossier/service_validation.dart';
import '../theme/app_delais.dart';
import 'capacite_indisponible.dart';
import 'port_revue_dossiers.dart';

/// Les verifications humaines de la revue, dans l'ordre de l'ecran.
const List<String> verificationsRevue = <String>['lisible', 'nom', 'validite'];

/// Le port de revue lu depuis la file du service existant.
class RevueDossiersDepuisValidation extends RevueDossiersIndisponible {
  /// [lire] rend la file du service existant (en production, le cache
  /// partage `dossiersEnAttenteProvider`).
  ///
  /// [apercu] signe une URL courte de la piece (a partir de BR-1,
  /// ServiceValidation.apercu : le createSignedUrl de 60 s DEJA utilise
  /// avant AD-6, aucun nouvel appel ni changement serveur ; en production
  /// aujourd'hui l'apercu est ferme, voir `surchargeRevueDossiersProduction`).
  /// La porte serveur `autoriser_lecture_piece_identite` n'est pas branchee
  /// (AD-BR-03, BR-1).
  ///
  /// [deciderExistant] appelle `decider_dossier` (ServiceValidation.decider,
  /// a partir de BR-1 ; ferme en production aujourd'hui) ;
  /// [relire] recharge la file par `dossiers_en_attente`. Nuls, la decision
  /// reste indisponible.
  const RevueDossiersDepuisValidation(
    this.lire, {
    this.apercu,
    this.horloge,
    this.deciderExistant,
    this.relire,
  });

  /// La RPC existante `decider_dossier`.
  final DeciderExistant? deciderExistant;

  /// Le rechargement existant de la file (invalidation puis relecture).
  final Future<List<DossierAValider>> Function()? relire;

  final Future<List<DossierAValider>> Function() lire;

  /// Signe l'URL courte d'une piece, par son identifiant de document (la
  /// cle d'objet reste cote serveur) ; nul, la piece reste indisponible.
  final Future<String> Function(String documentId)? apercu;

  /// L'heure courante (tests) ; DateTime.now par defaut.
  final DateTime Function()? horloge;

  /// Les formats que la visionneuse affiche, par extension de la cle.
  static const Map<String, String> typesImage = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Le type MIME deduit de l'extension de la cle, ou nul hors image
  /// (pdf, heic, inconnue). La file ne fournit pas content_type (AD-BR).
  static String? typeImage(String? cleObjet) {
    if (cleObjet == null) {
      return null;
    }
    final int point = cleObjet.lastIndexOf('.');
    final int barre = cleObjet.lastIndexOf('/');
    if (point < 0 || point < barre) {
      return null;
    }
    return typesImage[cleObjet.substring(point + 1).toLowerCase()];
  }

  /// Lit la file et traduit ses erreurs en reponses metier typees.
  ///
  /// K-47 (HL-A-6) : la file ADM-02 ne porte que des ENSEIGNANTS. Tant que
  /// `dossiers_en_attente` rend aussi les tuteurs `pending_kyc` (BR-1.c), ils
  /// sont ecartes ici, sans nouvel appel : liste, detail, piece et decision
  /// lisent tous cette file filtree.
  Future<List<DossierAValider>> _lire() async =>
      enseignantsSeulement(await _lireBrut());

  /// Garde les seules lignes d'enseignants. Une ligne au role illisible
  /// (repliee sur `guardian` par `DossierAValider.depuisJson`) est ecartee.
  static List<DossierAValider> enseignantsSeulement(
    List<DossierAValider> lignes,
  ) => <DossierAValider>[
    for (final DossierAValider d in lignes)
      if (d.role == AppRole.teacher) d,
  ];

  Future<List<DossierAValider>> _lireBrut() async {
    try {
      return await lire();
    } on Object catch (e) {
      // Riverpod 3 enveloppe l'erreur d'un provider lu par `.future`.
      Object cause = e;
      while (cause is ProviderException) {
        cause = cause.exception;
      }
      if (cause is GenreLecteurInconnu) {
        throw const ErreurRevueDossier(CodeErreurRevue.profilACompleter);
      }
      if (cause is PostgrestException && cause.code == '42501') {
        throw const ErreurRevueDossier(CodeErreurRevue.interdit);
      }
      rethrow;
    }
  }

  static EtatPieceRevue? _etatPiece(DossierAValider d) => switch (d.etatPiece) {
    EtatPiece.nonVisible => EtatPieceRevue.nonVisible,
    EtatPiece.aucune => EtatPieceRevue.absente,
    _ when d.documentId != null => EtatPieceRevue.disponible,
    _ => null,
  };

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) async {
    // Aucun curseur n'est jamais rendu : une demande de suite est vide.
    if (curseur != null) {
      return const PageDossiers(elements: <DossierEnFile>[]);
    }
    final List<DossierAValider> lignes = await _lire();
    // La RPC rend une ligne par piece visible (left join) : une personne, une
    // ligne, la plus ancienne gardee (AD-BR-01).
    final Set<String> vus = <String>{};
    return PageDossiers(
      elements: <DossierEnFile>[
        for (final DossierAValider d in lignes)
          if ((role == null || d.role == role) && vus.add(d.profilId))
            DossierEnFile(
              dossierId: d.profilId,
              nomAffiche: d.libelle,
              role: d.role,
              soumisLeUtc: d.deposeLe.toUtc(),
              statut: StatutRevue.aVerifier,
              // Jamais affichee : la RPC ne la fournit pas (AD-BR-06).
              revision: 0,
              aPieceIdentite:
                  d.documentId != null || d.etatPiece == EtatPiece.nonVisible,
              // Lu dans la meme reponse (`etat_piece`) : aucun appel de plus.
              etatPiece: _etatPiece(d),
            ),
      ],
    );
  }

  /// Le detail, reconstruit depuis la MEME file (AD-6) : aucun appel de plus.
  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) async {
    final List<DossierAValider> lignes = await _lire();
    final DossierAValider? d = lignes
        .where((DossierAValider x) => x.profilId == dossierId)
        .firstOrNull;
    if (d == null) {
      throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
    }
    final EtatPieceRevue piece = _etatPiece(d) ?? EtatPieceRevue.absente;
    final bool disponible = piece == EtatPieceRevue.disponible;
    // AD-7 : une piece image s'ouvre dans la visionneuse et les
    // verifications deviennent modifiables apres sa lecture (lectureRequise).
    // La validation reste fermee a l'ecran tant que la consequence est
    // inconnue (Q21), et ici tant que la decision n'est pas branchee
    // (AD-M3-PROD). Un format que la visionneuse n'affiche pas (pdf, heic,
    // inconnu) garde les verifications fermees (P-ADM-06).
    final bool consultable =
        disponible && apercu != null && typeImage(d.cleObjet) != null;
    final BlocageRevue? manque = switch (piece) {
      EtatPieceRevue.disponible when consultable => null,
      EtatPieceRevue.disponible => BlocageRevue.pieceNonConsultable,
      EtatPieceRevue.nonVisible => BlocageRevue.pieceNonVisible,
      _ => BlocageRevue.pieceAbsente,
    };
    // AD-M3-PROD (decision S1 -> a du 27/09) : sans `decider_dossier`
    // branche, le refus est ferme comme la validation, jusqu'a BR-1.
    final bool decisionBranchee = deciderExistant != null;
    // `decider_dossier` exige `p_document_id` : sans piece, aucun geste.
    final bool peutRefuser = d.documentId != null && decisionBranchee;
    final List<BlocageRevue> blocagesDecision = <BlocageRevue>[
      if (d.documentId != null && !decisionBranchee)
        BlocageRevue.decisionIndisponible,
    ];
    return DossierPourRevue(
      dossierId: d.profilId,
      // Jamais affichee : la RPC ne la fournit pas (AD-BR-06).
      revision: 0,
      prenom: d.prenom,
      nom: d.nom,
      role: d.role,
      soumisLeUtc: d.deposeLe.toUtc(),
      statut: StatutRevue.aVerifier,
      exigencePiece: ExigencePiece.requise,
      etatPiece: piece,
      typePiece: d.type,
      documentId: d.documentId,
      verifications: <VerificationRevue>[
        if (disponible)
          for (final String id in verificationsRevue)
            VerificationRevue(
              id: id,
              origine: OrigineVerification.humaine,
              obligatoire: true,
              etat: EtatVerification.aFaire,
              modifiable: consultable,
            ),
      ],
      // Aucun accord versionne n'est lu (AD-BR-02) : la carte est masquee.
      accords: const <AccordSoumis>[],
      peutValider: consultable && decisionBranchee,
      // La cle finit par une extension d'image : c'est une promesse, pas une
      // lecture. La revue attend l'affichage reussi (AD-7, P-ADM-06 pt 5).
      lectureRequise: consultable,
      peutRefuser: peutRefuser,
      // AD-M3-PROD : sans signature branchee, aucune URL n'est demandee.
      peutVoirPiece:
          apercu != null &&
          d.documentId != null &&
          piece != EtatPieceRevue.nonVisible,
      blocagesValidation: <BlocageRevue>[...blocagesDecision, ?manque],
      blocagesRefus: peutRefuser
          ? const <BlocageRevue>[]
          : blocagesDecision.isNotEmpty
          ? blocagesDecision
          : <BlocageRevue>[?manque],
      // Branchee, la decision passe par `ServiceValidation` sans consequence
      // connue ; sinon `decisionIndisponible` ferme les deux gestes.
      consequence: ConsequenceValidation.indeterminee,
    );
  }

  /// La vue de la piece, retrouvee dans la MEME file en cache puis signee
  /// par le mecanisme existant. Aucune URL ne part dans un message d'erreur.
  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) async {
    final Future<String> Function(String)? signer = apercu;
    if (signer == null) {
      throw const CapaciteIndisponible('AD-BR-03');
    }
    final List<DossierAValider> lignes = await _lire();
    final DossierAValider? d = lignes
        .where(
          (DossierAValider x) =>
              x.profilId == dossierId && x.documentId == documentId,
        )
        .firstOrNull;
    if (d == null) {
      throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
    }
    if (d.etatPiece == EtatPiece.nonVisible) {
      throw const ErreurRevueDossier(CodeErreurRevue.interdit);
    }
    final String? cle = d.cleObjet;
    if (cle == null) {
      throw const ErreurRevueDossier(CodeErreurRevue.introuvable);
    }
    final String? type = typeImage(cle);
    if (type == null) {
      throw const ErreurRevueDossier(CodeErreurRevue.typeNonPrisEnCharge);
    }
    final DateTime maintenant = (horloge ?? DateTime.now)().toUtc();
    final String url;
    try {
      url = await signer(documentId);
    } on ApercuRefuse {
      // La porte serveur a refuse : une regle (genre), pas une panne. Le refus
      // remonte tel quel pour que la visionneuse en dise la cause.
      rethrow;
    } on FunctionException catch (e) {
      // La porte `piece-identite-acces` repond par un statut : 403 est un
      // refus de regle (traite comme `ApercuRefuse`), 400 et 404 un document
      // introuvable, le reste une panne temporaire.
      if (e.status == 403) {
        throw const ApercuRefuse();
      }
      throw ErreurRevueDossier(switch (e.status) {
        400 || 404 => CodeErreurRevue.introuvable,
        _ => CodeErreurRevue.indisponibleTemporairement,
      });
    } on Object {
      throw const ErreurRevueDossier(
        CodeErreurRevue.indisponibleTemporairement,
      );
    }
    return VuePiece(
      documentId: documentId,
      source: SourcePieceUrl(Uri.parse(url)),
      expireLeUtc: maintenant.add(
        const Duration(seconds: ServiceValidationSupabase.dureeApercuSecondes),
      ),
      typeMime: type,
    );
  }

  /// Le document de ce dossier encore present dans [lignes], ou nul.
  static String? _documentEnFile(List<DossierAValider> lignes, String id) =>
      lignes
          .where(
            (DossierAValider x) => x.profilId == id && x.documentId != null,
          )
          .map((DossierAValider x) => x.documentId!)
          .firstOrNull;

  /// La decision sur `decider_dossier`. Le document est cherche dans la file
  /// DEJA en cache : absent, le dossier est deja traite, sans aucun appel.
  /// Aucune relance automatique ; un delai de [AppDelais.requeteMax] ou une
  /// reponse perdue donnent `reponsePerdue`, jamais un echec certain.
  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async {
    // AD-RC m2 : la validation reste fermee en production jusqu'a BR-1
    // (aucune consequence connue, AD-BR-02). Refusee ici meme, avant toute
    // lecture ou RPC, pour ne pas dependre du seul bouton desactive.
    if (decision == DecisionDossier.valider) {
      throw const CapaciteIndisponible('AD-BR-02');
    }
    final DeciderExistant? rpc = deciderExistant;
    if (rpc == null) {
      throw const CapaciteIndisponible('AD-BR-06');
    }
    final String? documentId = _documentEnFile(await _lire(), dossierId);
    if (documentId == null) {
      throw const ErreurRevueDossier(CodeErreurRevue.dejaDecide);
    }
    // AD-NETTOYAGE-2 : depuis la garde ci-dessus, `decision` ne peut plus etre
    // `valider` ici ; `approuve` est donc toujours faux et les branches
    // `approuve ? ...` ci-dessous ne s'executent pas. Elles restent pour que
    // la reouverture de la validation (BR-1) ne demande que le retrait de la
    // garde, pas une reecriture de l'appel et de la reponse.
    final bool approuve = decision == DecisionDossier.valider;
    try {
      await rpc(
        documentId: documentId,
        approuve: approuve,
        motif: approuve ? null : motif,
      ).timeout(AppDelais.requeteMax);
    } on PostgrestException catch (e) {
      // Le serveur a repondu : la transaction est annulee, echec certain.
      // AD-BR : la carte repose sur des sous-chaines de message (P0001).
      final String m = e.message;
      if (m.contains('un refus exige un motif')) {
        throw const ErreurRevueDossier(CodeErreurRevue.motifRequis);
      }
      // L1-05 : `decider_dossier` refuse une seconde decision (« dossier déjà
      // décidé »). Le serveur a repondu : c'est un fait, pas un echec.
      if (m.contains('dossier déjà décidé')) {
        throw const ErreurRevueDossier(CodeErreurRevue.dejaDecide);
      }
      if (e.code == '42501' ||
          m.contains('introuvable ou hors du perimetre') ||
          m.contains('seul un administrateur')) {
        throw const ErreurRevueDossier(CodeErreurRevue.interdit);
      }
      throw const EchecDecisionCertain();
    } on Object {
      // Delai, coupure : la decision a pu etre enregistree (P-ADM-10).
      throw const ErreurRevueDossier(CodeErreurRevue.reponsePerdue);
    }
    return ResultatDecision(
      dossierId: dossierId,
      statutFinal: approuve ? StatutRevue.valide : StatutRevue.refuse,
      // La RPC ne rend ni revision ni etat du compte (AD-BR-06) : on ne
      // promet jamais « compte active ».
      nouvelleRevision: 0,
      decideLeUtc: (horloge ?? DateTime.now)().toUtc(),
    );
  }

  /// Aucun `get_decision_result` (AD-BR-07) : la file en cache d'abord, puis
  /// le rechargement existant. Absent : deja traite, sans attribuer la
  /// decision au clic local (17.6). Present : toujours en attente, JAMAIS un
  /// echec -- la requete peut etre encore en vol et `decider_dossier` n'est
  /// ni idempotent ni garde (AD-BR-06/07) : aucune reprise ouverte (Q-AD8-9).
  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) async {
    final Future<List<DossierAValider>> Function()? recharger = relire;
    if (recharger == null) {
      throw const CapaciteIndisponible('AD-BR-07');
    }
    if (_documentEnFile(await _lire(), dossierId) == null) {
      return const EtatCommandeEchouee(CodeErreurRevue.dejaDecide);
    }
    if (_documentEnFile(enseignantsSeulement(await recharger()), dossierId) ==
        null) {
      return const EtatCommandeEchouee(CodeErreurRevue.dejaDecide);
    }
    return const EtatCommandeEnAttente();
  }
}

/// La signature de `ServiceValidation.decider` (RPC `decider_dossier`).
typedef DeciderExistant = Future<void> Function({
  required String documentId,
  required bool approuve,
  String? motif,
});

/// Le serveur a repondu par un refus sans code connu : echec certain, la
/// reprise de la meme charge est permise. Aucun message serveur n'est garde.
class EchecDecisionCertain implements Exception {
  /// Cree l'echec.
  const EchecDecisionCertain();
}

/// Le branchement de production, pose dans `lib/main.dart` seulement.
///
/// AD-M3-PROD (decision du directeur du 27/09, S1 -> a) : la file et le
/// detail sont lus, mais le refus et l'apercu de la piece restent fermes
/// comme la validation jusqu'a BR-1 : ni `decider_dossier`, ni
/// `createSignedUrl`. A BR-1, rebrancher ici `apercu`
/// (ServiceValidation.apercu), `deciderExistant` (ServiceValidation.decider)
/// et `relire` (invalidation puis relecture de `dossiersEnAttenteProvider`).
final Override surchargeRevueDossiersProduction = portRevueDossiersProvider
    .overrideWith(
      (Ref ref) => RevueDossiersDepuisValidation(
        () => ref.read(dossiersEnAttenteProvider.future),
      ),
    );
