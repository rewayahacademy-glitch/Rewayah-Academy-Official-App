// CORRIGER-SOURATE (directeur, 11/11/2026 ; decisions du garde-cap, 11/11) :
// la confirmation du retrait d'une sourate validee par erreur.
//
// * Le geste « Retirer » n'est montre que pour une sourate que le serveur dit
//   retirable par la personne connectee (`sourates_retirables_classe`) :
//   l'auteur de la validation pendant 24 heures, la direction toujours. Jamais
//   deduit d'un role ici.
// * Action sensible (`DECISION-FLUIDITE-2026-11-07.md`) : on attend la
//   reponse du serveur, le bouton en cours ; rien n'est montre comme fait
//   avant elle.
// * « Annuler » ferme sans rien faire ; un refus du serveur (delai passe) et
//   une erreur se disent dans la feuille, qui reste ouverte.
//
// Etats : contenu, en cours (bouton), refus et erreur (bandeau). Le
// chargement de la liste reste celui du cahier.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import 'sourates_classe.dart';

/// Demande confirmation, puis retire la sourate [nom] par [retirer], qui
/// recoit le motif (ou `null`). Rend `true` quand le serveur a retire la
/// sourate, `false` sinon (annule, ferme).
Future<bool> confirmerRetraitSourate(
  BuildContext context, {
  required String nom,
  required Future<void> Function(String? motif) retirer,
}) async {
  final bool? fait = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.cahierSourates.retirerQuestion(nom: nom),
    constructeur: (BuildContext _) => FeuilleRetraitSourate(retirer: retirer),
  );
  return fait ?? false;
}

enum _Issue { aucune, refus, erreur }

/// Le corps de la confirmation.
@visibleForTesting
class FeuilleRetraitSourate extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleRetraitSourate({required this.retirer, super.key});

  /// Le retrait, au serveur.
  final Future<void> Function(String? motif) retirer;

  /// La cle du champ du motif.
  static const Key cleMotif = ValueKey<String>('retrait-sourate-motif');

  /// La cle du bouton « Retirer ».
  static const Key cleRetirer = ValueKey<String>('retrait-sourate-retirer');

  /// La cle du bandeau d'issue.
  static const Key cleIssue = ValueKey<String>('retrait-sourate-issue');

  @override
  State<FeuilleRetraitSourate> createState() => _FeuilleRetraitSourateState();
}

class _FeuilleRetraitSourateState extends State<FeuilleRetraitSourate> {
  final TextEditingController _motif = TextEditingController();
  bool _enCours = false;
  _Issue _issue = _Issue.aucune;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _retirer() async {
    if (_enCours) return;
    setState(() {
      _enCours = true;
      _issue = _Issue.aucune;
    });
    final String motif = _motif.text.trim();
    _Issue issue;
    try {
      await widget.retirer(motif.isEmpty ? null : motif);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } on RetraitSourateRefuse {
      issue = _Issue.refus;
    } on Object {
      issue = _Issue.erreur;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _issue = issue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = t.cahierSourates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(tr.retirerConsequence),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _motif,
          cleChamp: FeuilleRetraitSourate.cleMotif,
          libelle: tr.retirerMotif,
        ),
        if (_issue != _Issue.aucune) ...<Widget>[
          Ecart.vLg,
          BandeauAttention(
            key: FeuilleRetraitSourate.cleIssue,
            titre: tr.retirer,
            message: _issue == _Issue.refus ? tr.retirerRefus : tr.retirerEchec,
            ton: _issue == _Issue.refus
                ? TonEtat.avertissement
                : TonEtat.alerte,
          ),
        ],
        Ecart.vXl,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: <Widget>[
            ActionPrincipale(
              libelle: t.commun.annuler,
              niveau: NiveauAction.secondaire,
              autofocus: true,
              onPress: _enCours ? null : () => Navigator.of(context).pop(false),
            ),
            if (_issue != _Issue.refus)
              ActionPrincipale(
                key: FeuilleRetraitSourate.cleRetirer,
                libelle: tr.retirer,
                niveau: NiveauAction.destructive,
                enCours: _enCours,
                onPress: _retirer,
              ),
          ],
        ),
      ],
    );
  }
}
