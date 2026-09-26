// Adaptateur de production du port de revue (AD-5), construit sur le service
// existant `ServiceValidation` : AUCUN nouvel appel serveur. La file et le
// detail partagent le meme cache (`dossiersEnAttenteProvider`), donc un seul
// appel a la RPC existante `dossiers_en_attente`.
//
// Ce que la RPC ne fournit pas reste honnetement absent : ni total, ni
// curseur, ni revision (AD-BR-01, 02, 06). Les gestes de revue du port
// (detail, piece, decision) restent indisponibles : l'ecran d'AD-5 decide
// encore par le service existant (`revue_existante.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 a sorti `Override` de l'export principal.
import 'package:flutter_riverpod/misc.dart' show Override, ProviderException;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../admin/service_comptes.dart' show EtatPiece;
import '../domain/enums.dart';
import '../dossier/service_validation.dart';
import 'port_revue_dossiers.dart';

/// Le port de revue lu depuis la file du service existant.
class RevueDossiersDepuisValidation extends RevueDossiersIndisponible {
  /// [lire] rend la file du service existant (en production, le cache
  /// partage `dossiersEnAttenteProvider`).
  const RevueDossiersDepuisValidation(this.lire);

  final Future<List<DossierAValider>> Function() lire;

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
    final List<DossierAValider> lignes;
    try {
      lignes = await lire();
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
              etatPiece: switch (d.etatPiece) {
                EtatPiece.nonVisible => EtatPieceRevue.nonVisible,
                EtatPiece.aucune => EtatPieceRevue.absente,
                _ when d.documentId != null => EtatPieceRevue.disponible,
                _ => null,
              },
            ),
      ],
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
