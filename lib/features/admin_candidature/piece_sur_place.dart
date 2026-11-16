/// SALLE2-FICHE (directeur, 14/11/2026) : « pièce d'identité à ouvrir
/// ailleurs (Dossiers à valider) avec cases discrètes ». La piece d'une
/// candidature s'ouvre et se decide SUR la fiche : la meme revue que
/// « Dossiers à valider » (`RevueDossier` : visionneuse, verifications
/// « lisible, nom conforme, non expirée », Valider ou Refuser par
/// `decider_dossier`), jamais une copie.
///
/// Etats : lecture (squelette), echec (« Reessayer »), piece a deposer,
/// validee, a corriger (avec le motif), en attente (la revue sur place). Une
/// piece en attente absente de la file (lue avant la mise a jour) garde le
/// lien vers « Dossiers à valider ».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/piece_candidature.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_dossiers/etat_file_dossiers.dart';
import '../admin_dossiers/revue_dossier.dart';
import 'piece_vignette.dart';

/// La piece d'une candidature, sur la fiche.
class PieceSurPlace extends ConsumerWidget {
  /// Cree le bloc.
  const PieceSurPlace({
    required this.candidatureId,
    required this.onDecision,
    required this.nom,
    this.onDemanderNouvellePiece,
    super.key,
  });

  /// COMPLEMENT-ET-FORMATS : ouvre le complement « pièce d'identité » deja
  /// coche, ou `null` quand le complement n'est pas permis maintenant.
  final VoidCallback? onDemanderNouvellePiece;

  /// La cle de la phrase « Format non lisible ».
  static const Key cleIllisible = ValueKey<String>('piece-format-illisible');

  /// La cle du lien « Demander une nouvelle pièce d'identité ».
  static const Key cleRedemander = ValueKey<String>('piece-redemander');

  /// La candidature.
  final String candidatureId;

  /// Apres une decision sur la piece (message du retour local).
  final ValueChanged<String> onDecision;

  /// Le nom du candidat (titre de la piece ouverte en grand).
  final String nom;

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('candidature-piece-sur-place');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.admin.candidatures.detail;
    final TextStyle muet = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    final AsyncValue<PieceCandidature?> lecture = ref.watch(
      pieceCandidatureProvider(candidatureId),
    );
    void relire() => ref.invalidate(pieceCandidatureProvider(candidatureId));

    // PIECE-DANS-DOSSIER (16/11/2026) : plus de lien vers « Fichiers a
    // valider » depuis la rubrique (la liste de tous les fichiers ne retrouve
    // pas le candidat). Une piece deposee hors de la file s'apercoit ici.
    Widget vignette(String documentId) =>
        PieceVignette(key: cle, documentId: documentId, nom: nom);

    if (!lecture.hasValue) {
      return lecture.hasError
          ? EtatSysteme(
              key: cle,
              nature: NatureEtat.echecServeur,
              phrase: r.pieceEchec,
              libelleAction: t.commun.reessayer,
              onAction: relire,
            )
          : const Skeleton.liste(key: cle, lignes: 2);
    }
    final PieceCandidature? piece = lecture.requireValue;
    if (piece == null) return const SizedBox.shrink(key: cle);
    final String? profil = piece.profilId;
    Widget phrase(String texte) => Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Text(texte, style: muet)],
    );
    switch (piece.statut) {
      case StatutPieceCandidature.sansCompte:
        return phrase(r.pieceSansCompte);
      case StatutPieceCandidature.aDeposer:
        return phrase(r.etatsPiece.aDeposer);
      case StatutPieceCandidature.validee:
        return phrase(r.etatsPiece.validee);
      case StatutPieceCandidature.refusee:
        final String? motif = piece.motifRefus?.trim();
        return phrase(
          motif == null || motif.isEmpty
              ? r.etatsPiece.aCorriger
              : r.pieceMotif(etat: r.etatsPiece.aCorriger, motif: motif),
        );
      case StatutPieceCandidature.inconnu:
        return phrase(r.etatsPiece.deposee);
      case StatutPieceCandidature.enAttente:
        final String? document = piece.documentId;
        if (profil == null) {
          return document == null
              ? phrase(r.etatsPiece.deposee)
              : vignette(document);
        }
    }
    final AsyncValue<DossierPourRevue> dossier = ref.watch(
      dossierPourRevueProvider(profil),
    );
    if (dossier.hasValue) {
      final DossierPourRevue d = dossier.requireValue;
      final Widget revue = RevueDossier(
        key: ValueKey<String>('${cle.toString()}-${d.dossierId}-${d.revision}'),
        dossier: d,
        avecTitre: false,
        onDecision: (String message) {
          relire();
          ref.invalidate(dossierPourRevueProvider(profil));
          onDecision(message);
        },
        onActualiser: () => ref.invalidate(dossierPourRevueProvider(profil)),
      );
      if (!d.formatIllisible) return revue;
      // COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : une piece deja deposee
      // en HEIC ou en PDF ne s'affiche pas sur ordinateur. L'ecran le dit avant
      // l'ouverture, et la nouvelle piece se demande en un geste.
      final VoidCallback? redemander = onDemanderNouvellePiece;
      return Column(
        key: cle,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            r.pieceIllisible,
            key: cleIllisible,
            style: AppPalette.of(context).inkAlert.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
          if (redemander != null) ...<Widget>[
            Ecart.vXs,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: cleRedemander,
                libelle: r.demanderNouvellePiece,
                alignerEnDebut: true,
                onPress: redemander,
              ),
            ),
          ],
          Ecart.vMd,
          revue,
        ],
      );
    }
    if (dossier.hasError) {
      // Hors de la file : une piece deposee en Salle d'examen n'y entre pas
      // avant l'admission (migration 20261119100000). Elle s'apercoit ici, par
      // son document ; sans document, l'etat seul.
      final String? document = piece.documentId;
      return document == null
          ? phrase(r.etatsPiece.deposee)
          : vignette(document);
    }
    return const Skeleton.liste(key: cle, lignes: 3);
  }
}
