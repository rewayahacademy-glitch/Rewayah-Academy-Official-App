// PIECE-SUR-LA-FICHE (carte des gestes de la direction, T13, 16/11/2026) :
// « valider ou refuser la pièce sur la fiche, en Salle d'examen ».
//
// La porte est celle qui existe, `decider_dossier` (`ServiceValidation.decider`),
// la seule qui décide d'une pièce SEULE : depuis SALLE2-ENTRETIEN
// (20261125820000) elle laisse un candidat d'avant la salle 3 en `pending_kyc`,
// et `read_kyc_documents` ne filtre que par genre. `valider_piece_candidat` est
// « Accueillir » (compte actif, étape confirmée), jamais un geste de pièce.
// Aucune règle n'est copiée ici : le serveur répond, l'écran dit sa phrase.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/candidature/piece_candidature.dart';
import '../../core/candidature/port_candidatures_direction.dart'
    show capacitesCandidaturesProvider;
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/lien_fleche.dart';
import '../admin_dossiers/surfaces_decision.dart' show raisonEchecDecision;

/// Le serveur ouvre-t-il la décision de la pièce à ce lecteur ? (`decider_dossier`
/// : direction active de genre connu ; un porteur de mission ne l'a pas.)
bool peutDeciderPiece(WidgetRef ref) =>
    ref.watch(deciderPieceProvider) != null &&
    (ref.watch(capacitesCandidaturesProvider).value?.geste('deciderPiece') ??
        false);

/// Valider ou refuser la pièce déposée, sur la fiche.
class DecisionPiece extends ConsumerStatefulWidget {
  /// Crée le bloc.
  const DecisionPiece({
    required this.documentId,
    required this.onDecision,
    super.key,
  });

  /// Le document à décider.
  final String documentId;

  /// Après une décision réussie : la phrase du retour local ; la fiche relit.
  final ValueChanged<String> onDecision;

  /// La clé du bloc.
  static const Key cle = ValueKey<String>('piece-decision');

  /// La clé de « Valider la pièce ».
  static const Key cleValider = ValueKey<String>('piece-decision-valider');

  /// La clé de « Refuser la pièce ».
  static const Key cleRefuser = ValueKey<String>('piece-decision-refuser');

  /// La clé du champ du motif.
  static const Key cleMotif = ValueKey<String>('piece-decision-motif');

  /// La clé de « Refuser la pièce » une fois le motif saisi.
  static const Key cleConfirmerRefus = ValueKey<String>(
    'piece-decision-confirmer-refus',
  );

  /// La clé de la phrase d'échec.
  static const Key cleEchec = ValueKey<String>('piece-decision-echec');

  @override
  ConsumerState<DecisionPiece> createState() => _EtatDecisionPiece();
}

class _EtatDecisionPiece extends ConsumerState<DecisionPiece> {
  final TextEditingController _motif = TextEditingController();
  bool _motifOuvert = false;
  bool _enCours = false;
  String? _echec;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _decider({required bool approuve}) async {
    final r = t.admin.candidatures.detail;
    final Future<void> Function({
      required String documentId,
      required bool approuve,
      String? motif,
    })?
    decider = ref.read(deciderPieceProvider);
    if (decider == null || _enCours) return;
    final String motif = _motif.text.trim();
    if (!approuve && motif.isEmpty) {
      setState(() => _echec = t.dossiers.refus.erreurVide);
      return;
    }
    if (ref.read(horsLigneProvider).value ?? false) {
      setState(() => _echec = r.pieceHorsLigne);
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    String? phraseEchec;
    try {
      await decider(
        documentId: widget.documentId,
        approuve: approuve,
        motif: approuve ? null : motif,
      );
    } on Object catch (e) {
      phraseEchec = _phrase(e, approuve: approuve);
    }
    if (!mounted) return;
    if (phraseEchec != null) {
      setState(() {
        _enCours = false;
        _echec = phraseEchec;
      });
      return;
    }
    setState(() => _enCours = false);
    widget.onDecision(approuve ? r.pieceValidee : r.pieceRefusee);
  }

  /// La phrase vraie : le serveur a répondu (sa raison est dite), ou rien n'est
  /// arrivé (délai, coupure : le résultat n'est pas confirmé, jamais « connexion »
  /// pour un refus du serveur).
  String _phrase(Object e, {required bool approuve}) {
    final r = t.admin.candidatures.detail;
    if (e is TimeoutException) return r.pieceNonConfirmee;
    final String m = _messageServeur(e);
    if (m.isEmpty) return r.pieceNonConfirmee;
    if (m.contains('dossier déjà décidé')) return r.pieceDejaDecidee;
    if (m.contains('un refus exige un motif')) {
      return t.dossiers.refus.erreurVide;
    }
    if (m.contains('introuvable ou hors du perimetre') ||
        m.contains('seul un administrateur')) {
      return t.dossiers.validation.interdit;
    }
    return raisonEchecDecision(m, refus: !approuve);
  }

  static String _messageServeur(Object e) =>
      e is PostgrestException ? e.message.trim() : '';

  @override
  Widget build(BuildContext context) {
    final r = t.admin.candidatures.detail;
    // « Le bouton n'apparaît que si la capacité serveur le permet » : la clé
    // `gestes.deciderPiece` de `capacites_candidatures()` (CAPACITE-DECIDER-PIECE),
    // jamais le simple branchement de la porte. Absente (porteur de mission,
    // serveur plus ancien) : rien n'est rendu (K-56).
    if (!peutDeciderPiece(ref)) {
      return const SizedBox.shrink(key: DecisionPiece.cle);
    }
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Column(
      key: DecisionPiece.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_motifOuvert) ...<Widget>[
          KeyedSubtree(
            key: DecisionPiece.cleMotif,
            child: ChampEtiquete(
              libelle: t.dossiers.refus.champ,
              aide: t.dossiers.refus.aide,
              controller: _motif,
              maxLines: 3,
              lectureSeule: _enCours,
            ),
          ),
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: DecisionPiece.cleConfirmerRefus,
              libelle: r.pieceRefuser,
              niveau: NiveauAction.destructive,
              pleineLargeur: false,
              enCours: _enCours,
              onPress: () => unawaited(_decider(approuve: false)),
            ),
          ),
        ] else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: DecisionPiece.cleValider,
              libelle: r.pieceValider,
              pleineLargeur: false,
              enCours: _enCours,
              onPress: () => unawaited(_decider(approuve: true)),
            ),
          ),
        if (_echec != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _echec!,
            key: DecisionPiece.cleEchec,
            style: AppPalette.of(context).inkAlert.applyTo(corps),
          ),
        ],
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: DecisionPiece.cleRefuser,
            libelle: _motifOuvert ? r.pieceRefusAnnuler : r.pieceRefuser,
            alignerEnDebut: true,
            onPress: _enCours
                ? null
                : () => setState(() {
                    _motifOuvert = !_motifOuvert;
                    _echec = null;
                  }),
          ),
        ),
      ],
    );
  }
}
