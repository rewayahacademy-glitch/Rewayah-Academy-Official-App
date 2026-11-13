// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : la pause d'exception accordee par
// la direction (maladie soudaine, interruption accordee) : l'eleve, le motif, le
// dernier jour. Sans preavis, jamais dans le passe ; elle ne compte pas dans le
// plafond de la famille.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendrier/libelles_calendrier.dart';
import '../../core/calendrier/port_calendrier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/tranche_age.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/lien_fleche.dart';

// ---------------------------------------------------------------------------

/// Ouvre la pause d'exception.
void ouvrirExceptionPause(BuildContext context, WidgetRef ref) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.calendrier.pauses.exceptionTitre,
    constructeur: (BuildContext contexte) => const _FeuilleException(),
  );
}

class _FeuilleException extends ConsumerStatefulWidget {
  const _FeuilleException();

  @override
  ConsumerState<_FeuilleException> createState() => _FeuilleExceptionEtat();
}

class _FeuilleExceptionEtat extends ConsumerState<_FeuilleException> {
  final TextEditingController _recherche = TextEditingController();
  final TextEditingController _motif = TextEditingController();
  List<EleveTrouve> _trouves = const <EleveTrouve>[];
  EleveTrouve? _eleve;
  DateTime? _fin;
  bool _envoi = false;
  bool _cherche = false;
  String? _erreur;

  @override
  void dispose() {
    _recherche.dispose();
    _motif.dispose();
    super.dispose();
  }

  Future<void> _chercher(String q) async {
    final PortPauses? port = ref.read(portPausesProvider);
    final String texte = q.trim();
    if (port == null || texte.length < 2) {
      setState(() {
        _trouves = const <EleveTrouve>[];
        _cherche = false;
      });
      return;
    }
    setState(() => _cherche = true);
    try {
      final List<EleveTrouve> l = await port.rechercherEleves(texte);
      // Une reponse perimee (la saisie a change) est ecartee.
      if (mounted && _recherche.text.trim() == texte) {
        setState(() {
          _trouves = l;
          _cherche = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _trouves = const <EleveTrouve>[];
          _cherche = false;
          _erreur = messageRefusDecisionPause(MotifRefusPause.inconnu);
        });
      }
    }
  }

  Future<void> _accorder() async {
    final PortPauses? port = ref.read(portPausesProvider);
    if (port == null) return;
    final EleveTrouve? eleve = _eleve;
    final DateTime? fin = _fin;
    String? manque;
    if (eleve == null) {
      manque = messageRefusDecisionPause(MotifRefusPause.eleveIntrouvable);
    } else if (_motif.text.trim().length < 3) {
      manque = messageRefusDecisionPause(MotifRefusPause.motifRequis);
    } else if (fin == null) {
      manque = messageRefusDecisionPause(MotifRefusPause.datesInvalides);
    }
    if (manque != null) {
      setState(() => _erreur = manque);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await port.accorderException(
        eleveId: eleve!.id,
        fin: fin!,
        motif: _motif.text.trim(),
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
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime aujourdhui = ref.watch(horlogeFormulairesProvider)();
    final EleveTrouve? eleve = _eleve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(p.exceptionPhrase, style: textes.bodyMedium),
        Ecart.vLg,
        if (eleve == null) ...<Widget>[
          ChampEtiquete(
            libelle: p.exceptionRecherche,
            controller: _recherche,
            aide: p.exceptionRechercheAide,
            onChanged: _chercher,
          ),
          Ecart.vMd,
          if (_trouves.isNotEmpty)
            ChoiceCardGroup(
              key: ValueKey<String>('trouves-${_recherche.text.trim()}'),
              autoriserSaisieLibre: false,
              options: <OptionChoix>[
                for (final EleveTrouve e in _trouves)
                  OptionChoix(
                    valeur: e.id,
                    libelle: e.nom,
                    description: e.cohorte == null
                        ? null
                        : libelleTranche(e.cohorte!),
                  ),
              ],
              onChange: (ReponseChoix r) {
                if (r.valeurs.isEmpty) return;
                final String id = r.valeurs.first;
                setState(() {
                  _eleve = _trouves.firstWhere((EleveTrouve e) => e.id == id);
                  _erreur = null;
                });
              },
            )
          else if (!_cherche && _recherche.text.trim().length >= 2)
            Text(p.exceptionAucun, style: textes.bodyMedium),
          if (_erreur != null) ...<Widget>[
            Ecart.vMd,
            Text(
              _erreur!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ] else ...<Widget>[
          Text(p.exceptionEleve(nom: eleve.nom), style: textes.titleSmall),
          Ecart.vSm,
          LienFleche(
            libelle: p.exceptionChanger,
            onPress: () => setState(() => _eleve = null),
            alignerEnDebut: true,
          ),
          Ecart.vLg,
          ChampEtiquete(
            libelle: p.exceptionMotif,
            controller: _motif,
            maxLines: 3,
            obligatoire: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (String _) {
              if (_erreur != null) setState(() => _erreur = null);
            },
          ),
          Ecart.vLg,
          ChampDate(
            libelle: p.exceptionFin,
            valeur: _fin,
            aujourdhui: aujourdhui,
            dernier: aujourdhui.add(const Duration(days: 365)),
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
            key: const ValueKey<String>('pause-exception-accorder'),
            libelle: p.exceptionEnregistrer,
            enCours: _envoi,
            onPress: _accorder,
          ),
        ],
      ],
    );
  }
}
