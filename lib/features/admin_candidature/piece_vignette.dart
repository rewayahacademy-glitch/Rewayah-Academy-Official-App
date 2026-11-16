// PIECE-DANS-DOSSIER (directeur, 16/11/2026) : la pièce d'identité déposée par
// un candidat de la Salle d'examen s'affiche dans sa rubrique, en vignette ; un
// toucher l'ouvre en grand (règle du 16/11 : pas de bouton « voir en grand »).
//
// Pourquoi ce chemin existe. La file « Fichiers à valider » (`dossiers_en_attente`)
// n'a pas les pièces déposées en Salle d'examen : « une pièce déposée en salle 1
// n'entre pas dans la file de la direction avant l'admission en salle 2 »
// (migration 20261119100000). La revue sur place (`RevueDossier`, qui lit cette
// file) ne trouvait donc pas le candidat, et la rubrique n'offrait que le lien
// vers la liste de tous les fichiers : une impasse. Ici, la pièce se lit par son
// identifiant de document (`piece_dossier_candidat`) et s'aperçoit par la même
// porte de signature que « Fichiers à valider » (`ServiceValidation.apercu`).
//
// Valider et Refuser n'y sont PAS : `decider_dossier` passe un compte
// `pending_kyc` à `active` (approbation) et désactive le compte d'un enseignant
// sans autre pièce approuvée (refus). Ce n'est pas un geste de Salle d'examen ;
// la pièce se décide en Salle de vérification et d'entretien, par la revue sur
// place habituelle. La phrase le dit (K-56 : un geste qui ne peut pas aboutir
// n'est pas rendu).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_dossiers/visionneuse_piece.dart' show imagePieceProvider;
import 'dossier_trois_etages.dart' show ouvrirPhotoEnGrand;

/// L'adresse signée, courte, de la pièce [documentId] ; elle expire : elle ne
/// se garde pas, une relecture en demande une autre.
final FutureProviderFamily<String, String> adressePieceProvider = FutureProvider
    .autoDispose
    .family<String, String>(
      (Ref ref, String documentId) =>
          ref.watch(serviceValidationProvider).apercu(documentId),
      retry: (int _, Object _) => null,
    );

/// La pièce déposée, en vignette.
class PieceVignette extends ConsumerWidget {
  /// Crée la vignette.
  const PieceVignette({required this.documentId, required this.nom, super.key});

  /// Le document le plus récent du candidat.
  final String documentId;

  /// Le nom du candidat (titre de la pièce ouverte en grand).
  final String nom;

  /// La clé du bloc.
  static const Key cle = ValueKey<String>('piece-vignette');

  /// La clé de l'image qu'on touche.
  static const Key cleImage = ValueKey<String>('piece-vignette-toucher');

  /// La clé de la phrase qui dit où se décide la pièce.
  static const Key cleDecision = ValueKey<String>('piece-vignette-decision');

  /// La clé de la phrase d'échec de l'aperçu.
  static const Key cleEchec = ValueKey<String>('piece-vignette-echec');

  /// La hauteur de la vignette.
  static const double hauteur = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.candidatures.detail;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle muet = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final AsyncValue<String> adresse = ref.watch(
      adressePieceProvider(documentId),
    );
    final Widget apercu;
    if (adresse.hasValue) {
      final String url = adresse.requireValue;
      apercu = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Pressable(
          key: cleImage,
          libelleSemantique: r.pieceAgrandir,
          onPress: () => unawaited(
            ouvrirPhotoEnGrand(
              context,
              ref,
              url: url,
              nom: r.pieceTitre(nom: nom),
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.arrondiSm,
            child: Image(
              image: ref.read(imagePieceProvider)(Uri.parse(url)),
              height: hauteur,
              fit: BoxFit.contain,
              // Un format que l'écran n'affiche pas (HEIC, PDF) : la phrase le
              // dit, et la pièce se redemande en un geste.
              errorBuilder: (BuildContext c, Object e, StackTrace? s) =>
                  TexteSansCoupure(
                    r.pieceIllisible,
                    key: cleEchec,
                    style: palette.inkAlert.applyTo(
                      Theme.of(c).textTheme.bodyMedium ?? const TextStyle(),
                    ),
                  ),
            ),
          ),
        ),
      );
    } else if (adresse.hasError) {
      apercu = EtatSysteme(
        key: cleEchec,
        nature: NatureEtat.echecServeur,
        phrase: r.pieceEchec,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(adressePieceProvider(documentId)),
      );
    } else {
      apercu = const Skeleton.liste(lignes: 2);
    }
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        apercu,
        Ecart.vSm,
        TexteSansCoupure(
          r.pieceDecisionPlusTard,
          key: cleDecision,
          style: muet,
        ),
      ],
    );
  }
}
