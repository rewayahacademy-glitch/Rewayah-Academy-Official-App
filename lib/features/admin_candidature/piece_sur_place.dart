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

/// La piece d'une candidature, sur la fiche.
class PieceSurPlace extends ConsumerWidget {
  /// Cree le bloc.
  const PieceSurPlace({
    required this.candidatureId,
    required this.onDecision,
    this.onOuvrirDossier,
    super.key,
  });

  /// La candidature.
  final String candidatureId;

  /// Apres une decision sur la piece (message du retour local).
  final ValueChanged<String> onDecision;

  /// Mene a « Dossiers a valider », ou `null`.
  final VoidCallback? onOuvrirDossier;

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

    Widget lien() => onOuvrirDossier == null
        ? const SizedBox.shrink()
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              libelle: r.ouvrirDossier,
              alignerEnDebut: true,
              onPress: onOuvrirDossier,
            ),
          );

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
    if (piece == null) {
      return Column(
        key: cle,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[lien()],
      );
    }
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
        if (profil == null) return phrase(r.etatsPiece.deposee);
    }
    final AsyncValue<DossierPourRevue> dossier = ref.watch(
      dossierPourRevueProvider(profil),
    );
    if (dossier.hasValue) {
      final DossierPourRevue d = dossier.requireValue;
      return RevueDossier(
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
    }
    if (dossier.hasError) {
      // Hors de la file (deja traitee ailleurs, ou file pas encore relue) :
      // l'etat dit, et le chemin existant.
      return Column(
        key: cle,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(r.etatsPiece.deposee, style: muet),
          Ecart.vXs,
          lien(),
        ],
      );
    }
    return const Skeleton.liste(key: cle, lignes: 3);
  }
}
