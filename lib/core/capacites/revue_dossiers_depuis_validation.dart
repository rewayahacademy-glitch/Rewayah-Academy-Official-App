// Adaptateur de production du port de revue (AD-5, AD-6), construit sur le
// service existant `ServiceValidation` : AUCUN nouvel appel serveur. La file
// et le detail partagent le meme cache (`dossiersEnAttenteProvider`), donc un
// seul appel a la RPC existante `dossiers_en_attente`.
//
// Ce que la RPC ne fournit pas reste honnetement absent : ni total, ni
// curseur, ni revision, ni accord versionne, ni consequence (AD-BR-01, 02,
// 06). La piece et la decision du port restent indisponibles : jusqu'a AD-8,
// l'ecran decide encore par `ServiceValidation.decider`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 a sorti `Override` de l'export principal.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderException;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../admin/service_comptes.dart' show EtatPiece;
import '../domain/enums.dart';
import '../dossier/service_validation.dart';
import 'port_revue_dossiers.dart';

/// Les verifications humaines de la revue, dans l'ordre de l'ecran.
const List<String> verificationsRevue = <String>['lisible', 'nom', 'validite'];

/// Le port de revue lu depuis la file du service existant.
class RevueDossiersDepuisValidation extends RevueDossiersIndisponible {
  /// [lire] rend la file du service existant (en production, le cache
  /// partage `dossiersEnAttenteProvider`).
  const RevueDossiersDepuisValidation(this.lire);

  final Future<List<DossierAValider>> Function() lire;

  /// Lit la file et traduit ses erreurs en reponses metier typees.
  Future<List<DossierAValider>> _lire() async {
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
    final BlocageRevue manque = piece == EtatPieceRevue.nonVisible
        ? BlocageRevue.pieceNonVisible
        : BlocageRevue.pieceAbsente;
    // `decider_dossier` exige `p_document_id` : sans piece, aucun geste.
    final bool peutRefuser = d.documentId != null;
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
              modifiable: true,
            ),
      ],
      // Aucun accord versionne n'est lu (AD-BR-02) : la carte est masquee.
      accords: const <AccordSoumis>[],
      peutValider: disponible,
      peutRefuser: peutRefuser,
      peutVoirPiece: d.documentId != null,
      blocagesValidation: disponible
          ? const <BlocageRevue>[]
          : <BlocageRevue>[manque],
      blocagesRefus: peutRefuser
          ? const <BlocageRevue>[]
          : <BlocageRevue>[manque],
      // La decision passe encore par `ServiceValidation` : pas de blocage
      // `decisionIndisponible`, mais aucune consequence connue.
      consequence: ConsequenceValidation.indeterminee,
    );
  }
}

/// Le branchement de production, pose dans `lib/main.dart` seulement.
final Override surchargeRevueDossiersProduction = portRevueDossiersProvider
    .overrideWith(
      (Ref ref) => RevueDossiersDepuisValidation(
        () => ref.read(dossiersEnAttenteProvider.future),
      ),
    );
