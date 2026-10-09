import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/zone_saisie.dart';
import 'presence_correction.dart';

/// Surface propriétaire de la correction, prête à être raccordée au serveur.
///
/// Elle n'est pas enregistrée dans le routeur tant que l'adaptateur serveur
/// n'est pas livré. Une intégration fournit les capacites, la cible, les
/// libelles et l'adaptateur correspondant au contrat validé.
class PresenceCorrectionPage extends StatelessWidget {
  /// Cree la page de correction.
  const PresenceCorrectionPage({
    required this.cible,
    required this.capacites,
    required this.adaptateur,
    required this.libelles,
    super.key,
  });

  final PresenceCorrectionCible cible;
  final PresenceCorrectionCapacites capacites;
  final PresenceCorrectionAdaptateur adaptateur;
  final PresenceCorrectionLibelles libelles;

  @override
  Widget build(BuildContext context) => PageShell(
    titre: libelles.titre,
    child: PresenceCorrectionPanneau(
      cible: cible,
      capacites: capacites,
      adaptateur: adaptateur,
      libelles: libelles,
    ),
  );
}

/// Panneau réutilisable dans la salle enseignant ou l'espace administration.
class PresenceCorrectionPanneau extends ConsumerStatefulWidget {
  /// Cree le panneau.
  const PresenceCorrectionPanneau({
    required this.cible,
    required this.capacites,
    required this.adaptateur,
    required this.libelles,
    super.key,
  });

  final PresenceCorrectionCible cible;
  final PresenceCorrectionCapacites capacites;
  final PresenceCorrectionAdaptateur adaptateur;
  final PresenceCorrectionLibelles libelles;

  @override
  ConsumerState<PresenceCorrectionPanneau> createState() =>
      _PresenceCorrectionPanneauState();
}

enum _EtatMutation { repos, enCours, succes, erreur, horsLigne }

class _PresenceCorrectionPanneauState
    extends ConsumerState<PresenceCorrectionPanneau> {
  _EtatMutation _etat = _EtatMutation.repos;

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final _EtatMutation etat = horsLigne
        ? _EtatMutation.horsLigne
        : (_etat == _EtatMutation.horsLigne ? _EtatMutation.repos : _etat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LignePresence(
                nom: widget.cible.ligne.prenom,
                vue: widget.cible.vue,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.cible.ligne.identifiantImmuable,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (widget.libelles.journalisation
            case final String rappel) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(rappel, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (etat != _EtatMutation.repos) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _EtatMutationVue(etat: etat, libelles: widget.libelles),
        ],
        if (etat != _EtatMutation.horsLigne &&
            etat != _EtatMutation.enCours) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          _actions(context),
        ],
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final bool peutAfficher =
        widget.capacites.peutCorriger || widget.capacites.peutExcuser;
    if (!peutAfficher) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.capacites.peutCorriger)
          ActionPrincipale(
            libelle: widget.libelles.corriger,
            niveau: NiveauAction.secondaire,
            onPress: () => unawaited(
              _ouvrirConfirmation(PresenceCorrectionDecision.corrigeeManuel),
            ),
          ),
        if (widget.capacites.peutCorriger && widget.capacites.peutExcuser)
          const SizedBox(height: AppSpacing.lg),
        if (widget.capacites.peutExcuser)
          ActionPrincipale(
            libelle: widget.libelles.excuser,
            niveau: NiveauAction.secondaire,
            onPress: () => unawaited(
              _ouvrirConfirmation(PresenceCorrectionDecision.excusee),
            ),
          ),
      ],
    );
  }

  Future<void> _ouvrirConfirmation(PresenceCorrectionDecision decision) async {
    if ((ref.read(horsLigneProvider).value ?? false) ||
        _etat == _EtatMutation.enCours) {
      if (mounted) {
        setState(() => _etat = _EtatMutation.horsLigne);
      }
      return;
    }

    final String? motif = await AppBottomSheet.ouvrir<String>(
      context,
      titre: widget.libelles.confirmation,
      constructeur: (BuildContext contexte) => _ConfirmationPresenceSheet(
        decision: decision,
        cible: widget.cible,
        libelles: widget.libelles,
      ),
    );
    if (motif == null || !mounted) {
      return;
    }

    setState(() => _etat = _EtatMutation.enCours);
    try {
      await widget.adaptateur.appliquer(
        PresenceCorrectionCommande(
          sessionId: widget.cible.ligne.seanceId,
          profileId: widget.cible.ligne.profilId,
          decision: decision,
          motif: motif,
        ),
      );
      if (mounted) {
        setState(() => _etat = _EtatMutation.succes);
      }
    } on PresenceCorrectionException catch (erreur) {
      if (mounted) {
        setState(
          () => _etat = erreur.type == PresenceCorrectionErreurType.horsLigne
              ? _EtatMutation.horsLigne
              : _EtatMutation.erreur,
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _etat = _EtatMutation.erreur);
      }
    }
  }
}

class _EtatMutationVue extends StatelessWidget {
  const _EtatMutationVue({required this.etat, required this.libelles});

  final _EtatMutation etat;
  final PresenceCorrectionLibelles libelles;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String message = switch (etat) {
      _EtatMutation.enCours => libelles.mutationEnCours,
      _EtatMutation.succes => libelles.succes,
      _EtatMutation.erreur => libelles.erreur,
      _EtatMutation.horsLigne => libelles.horsLigne,
      _EtatMutation.repos => '',
    };
    final bool alerte =
        etat == _EtatMutation.erreur || etat == _EtatMutation.horsLigne;
    final AppColorPair registre = alerte
        ? palette.washWarning
        : palette.washAccent;

    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: AppCard(
        surface: registre,
        contourFort: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (etat == _EtatMutation.enCours) ...<Widget>[
              const SizedBox.square(
                dimension: AppSpacing.xl,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                message,
                style: registre.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationPresenceSheet extends StatefulWidget {
  const _ConfirmationPresenceSheet({
    required this.decision,
    required this.cible,
    required this.libelles,
  });

  final PresenceCorrectionDecision decision;
  final PresenceCorrectionCible cible;
  final PresenceCorrectionLibelles libelles;

  @override
  State<_ConfirmationPresenceSheet> createState() =>
      _ConfirmationPresenceSheetState();
}

class _ConfirmationPresenceSheetState
    extends State<_ConfirmationPresenceSheet> {
  final TextEditingController _motif = TextEditingController();

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String decision = switch (widget.decision) {
      PresenceCorrectionDecision.corrigeeManuel => widget.libelles.corriger,
      PresenceCorrectionDecision.excusee => widget.libelles.excuser,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.cible.ligne.prenom),
        Text(decision),
        const SizedBox(height: AppSpacing.lg),
        ZoneSaisie(
          controleur: _motif,
          autofocus: true,
          libelle: widget.libelles.motif,
          explication: widget.libelles.motifRequis,
          minLignes: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        ActionPrincipale(
          libelle: widget.libelles.confirmer,
          onPress: _motif.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_motif.text.trim()),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionPrincipale(
          libelle: widget.libelles.annuler,
          niveau: NiveauAction.tertiaire,
          onPress: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
