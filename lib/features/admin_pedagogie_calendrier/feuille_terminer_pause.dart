// CALENDRIER-ET-PAUSES (lot 2, revue du 13/11/2026, I2) : « Terminer la pause
// d'exception a telle date ». La direction raccourcit une pause d'exception
// accordee : l'eleve reprend plus tot. Jamais dans le passe ; la fin d'origine et
// le geste sont gardes par le serveur, les jours deja passes restent comptes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';

/// Ouvre la feuille qui termine la pause d'exception [pause] plus tot.
void ouvrirTerminerPause(
  BuildContext context,
  WidgetRef ref,
  DecisionPause pause,
) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.calendrier.pauses.terminerTitre,
    constructeur: (BuildContext contexte) => _FeuilleTerminer(pause: pause),
  );
}

class _FeuilleTerminer extends ConsumerStatefulWidget {
  const _FeuilleTerminer({required this.pause});

  final DecisionPause pause;

  @override
  ConsumerState<_FeuilleTerminer> createState() => _FeuilleTerminerEtat();
}

class _FeuilleTerminerEtat extends ConsumerState<_FeuilleTerminer> {
  DateTime? _fin;
  bool _envoi = false;
  String? _erreur;

  Future<void> _terminer() async {
    final PortPauses? port = ref.read(portPausesProvider);
    final DateTime? fin = _fin;
    if (port == null) return;
    if (fin == null) {
      setState(
        () =>
            _erreur = messageRefusDecisionPause(MotifRefusPause.datesInvalides),
      );
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.terminerException(widget.pause.id, fin);
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
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime aujourdhui = ref.watch(horlogeFormulairesProvider)();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.pause.eleveNom, style: textes.titleSmall),
        Ecart.vSm,
        Text(
          p.periode(
            du: jourEnMots(widget.pause.debut),
            au: jourEnMots(widget.pause.fin),
          ),
          style: textes.bodyMedium,
        ),
        Ecart.vLg,
        Text(p.terminerPhrase, style: textes.bodyMedium),
        Ecart.vLg,
        ChampDate(
          libelle: p.terminerChamp,
          valeur: _fin,
          aujourdhui: aujourdhui,
          dernier: widget.pause.fin.subtract(const Duration(days: 1)),
          onChoix: (DateTime jour) => setState(() {
            _fin = jour;
            _erreur = null;
          }),
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
          key: const ValueKey<String>('pause-terminer-envoyer'),
          libelle: p.terminerEnvoyer,
          enCours: _envoi,
          onPress: _terminer,
        ),
      ],
    );
  }
}
