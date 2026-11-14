// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la reponse de la direction a une
// demande de pause au-dela du plafond : accepter, ou refuser avec un motif.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/tranche_age.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_etiquete.dart';

// ---------------------------------------------------------------------------

/// Ouvre la reponse a une demande de pause.
void ouvrirDecisionPause(
  BuildContext context,
  WidgetRef ref,
  DemandePauseDirection d,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.calendrier.pauses.refusTitre,
    constructeur: (BuildContext contexte) => _FeuilleDecision(demande: d),
  );
}

class _FeuilleDecision extends ConsumerStatefulWidget {
  const _FeuilleDecision({required this.demande});

  final DemandePauseDirection demande;

  @override
  ConsumerState<_FeuilleDecision> createState() => _FeuilleDecisionEtat();
}

class _FeuilleDecisionEtat extends ConsumerState<_FeuilleDecision> {
  final TextEditingController _motif = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _decider({required bool accepter}) async {
    final PortPauses? port = ref.read(portPausesProvider);
    if (port == null) return;
    final String motif = _motif.text.trim();
    if (!accepter && motif.length < 3) {
      setState(
        () => _erreur = messageRefusDecisionPause(MotifRefusPause.motifRequis),
      );
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.decider(
        widget.demande.id,
        accepter: accepter,
        motif: motif.isEmpty ? null : motif,
      );
      ref.invalidate(filePausesProvider);
      if (mounted) Navigator.of(context).pop();
    } on PauseRefusee catch (r) {
      if (mounted) {
        setState(() => _erreur = messageRefusDecisionPause(r.motif));
      }
    } on Object {
      if (mounted) {
        setState(
          () => _erreur = messageRefusDecisionPause(MotifRefusPause.inconnu),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.calendrier.pauses;
    final DemandePauseDirection d = widget.demande;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(d.eleveNom, style: textes.titleMedium),
        Ecart.vSm,
        Text(
          p.ligneDescription(mois: moisEnMots(d.debut), n: d.moisAccordes),
          style: textes.bodyMedium,
        ),
        if (d.cohorte != null) ...<Widget>[
          Ecart.vSm,
          Text(libelleTranche(d.cohorte!), style: textes.bodyMedium),
        ],
        Ecart.vLg,
        ChampEtiquete(
          libelle: p.refusMotif,
          controller: _motif,
          aide: p.refusPhrase,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String _) {
            if (_erreur != null) setState(() => _erreur = null);
          },
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: const ValueKey<String>('pause-accepter'),
          libelle: p.accepter,
          enCours: _envoi,
          onPress: () => _decider(accepter: true),
        ),
        Ecart.vMd,
        ActionPrincipale(
          key: const ValueKey<String>('pause-refuser'),
          libelle: p.refusEnvoyer,
          niveau: NiveauAction.secondaire,
          enCours: _envoi,
          onPress: () => _decider(accepter: false),
        ),
      ],
    );
  }
}
