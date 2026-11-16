/// SALLE2-FICHE (directeur, 14/11/2026) : la piece d'identite d'une
/// candidature, lue pour la fiche de la direction (`piece_dossier_candidat`,
/// migration 20261125900000) : le profil, le document le plus recent et son
/// etat. La piece s'ouvre et se decide sur place par le circuit existant des
/// dossiers (`RevueDossier`, `decider_dossier`), sans quitter la fiche.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// L'etat de la piece, lu au serveur.
enum StatutPieceCandidature {
  /// Aucun compte rattache a la candidature.
  sansCompte,

  /// Aucune piece deposee.
  aDeposer,

  /// Deposee, en attente de decision.
  enAttente,

  /// Validee.
  validee,

  /// Refusee.
  refusee,

  /// Valeur inconnue (serveur plus recent).
  inconnu,
}

/// Le genre du fichier de la piece, tel que le serveur l'a enregistre au depot
/// (PIECE-TYPE, migration 20261129490000). Jamais devine par l'ecran.
enum GenreFichierPiece {
  /// Un PDF.
  pdf,

  /// Une image.
  image,
}

/// La piece d'une candidature.
class PieceCandidature {
  /// Cree la piece.
  const PieceCandidature({
    required this.statut,
    this.profilId,
    this.documentId,
    this.motifRefus,
    this.genre,
    this.typeContenu,
  });

  /// Lit la reponse de `piece_dossier_candidat` ; `null` hors de portee.
  static PieceCandidature? depuisJson(Object? brut) {
    if (brut is! Map || brut['erreur'] != null) return null;
    return PieceCandidature(
      statut: switch (brut['statut']) {
        'sans_compte' => StatutPieceCandidature.sansCompte,
        'a_deposer' => StatutPieceCandidature.aDeposer,
        'pending' => StatutPieceCandidature.enAttente,
        'approved' => StatutPieceCandidature.validee,
        'rejected' => StatutPieceCandidature.refusee,
        _ => StatutPieceCandidature.inconnu,
      },
      profilId: brut['profilId'] as String?,
      documentId: brut['documentId'] as String?,
      motifRefus: brut['motifRefus'] as String?,
      // `genreFichier` absent (serveur plus ancien), null (aucun type
      // enregistre) ou inconnu : null, l'ecran ne pretend rien savoir.
      genre: switch (brut['genreFichier']) {
        'pdf' => GenreFichierPiece.pdf,
        'image' => GenreFichierPiece.image,
        _ => null,
      },
      typeContenu: brut['typeContenu'] as String?,
    );
  }

  /// L'etat.
  final StatutPieceCandidature statut;

  /// Le profil du candidat (l'identifiant du dossier cote revue).
  final String? profilId;

  /// Le document le plus recent.
  final String? documentId;

  /// Le motif d'un refus.
  final String? motifRefus;

  /// Le genre du fichier (`genreFichier`) ; `null` : type non enregistre.
  final GenreFichierPiece? genre;

  /// Le type MIME enregistre au depot (`typeContenu`) ; `null` : inconnu.
  final String? typeContenu;
}

/// La lecture ; `null` : capacite indisponible (la fiche garde alors son
/// ancien lien vers « Dossiers a valider »).
final Provider<Future<PieceCandidature?> Function(String candidatureId)?>
lirePieceCandidatureProvider =
    Provider<Future<PieceCandidature?> Function(String candidatureId)?>(
      (Ref _) => null,
    );

/// La lecture sur Supabase.
Future<PieceCandidature?> Function(String) lirePieceCandidatureSupabase(
  SupabaseClient client,
) =>
    (String candidatureId) async => PieceCandidature.depuisJson(
      await client.rpc<Object?>(
        'piece_dossier_candidat',
        params: <String, dynamic>{'p_candidature': candidatureId},
      ),
    );

/// La piece d'une candidature ; `null` sans lecture branchee ou hors portee.
final FutureProviderFamily<PieceCandidature?, String> pieceCandidatureProvider =
    FutureProvider.autoDispose.family<PieceCandidature?, String>((
      Ref ref,
      String candidatureId,
    ) async {
      final Future<PieceCandidature?> Function(String)? lire = ref.watch(
        lirePieceCandidatureProvider,
      );
      if (lire == null) return null;
      return lire(candidatureId);
    }, retry: (int _, Object _) => null);
