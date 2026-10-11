// DELEG-FIN-1 : lever la suspension des delegations.
//
// Un acte explicite de la Direction, jamais automatique : une feuille dit la
// consequence, demande une raison **obligatoire** (le bouton reste actif ;
// une raison vide est dite en clair, jamais un bouton grise), puis rend la
// raison saisie. La capacite et la MFA sont exigees par le serveur ; la
// reactivation est inscrite au journal et ne restaure jamais une delegation
// expiree (seul le renouvellement le fait).

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/champ_etiquete.dart';

/// La feuille de reactivation : rend la raison saisie, ou rien si la
/// Direction garde les delegations suspendues.
class FeuilleReactivation extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleReactivation({super.key});

  /// Ouvre la feuille ; `null` : la Direction y renonce.
  static Future<String?> ouvrir(BuildContext context) =>
      AppBottomSheet.ouvrir<String>(
        context,
        titre: t.comptable.direction.delegationPanneau.reactiverTitre,
        constructeur: (BuildContext _) => const FeuilleReactivation(),
      );

  /// La cle du champ de raison.
  static const Key cleRaison = ValueKey<String>('deleg-reactiver-raison');

  /// La cle du bouton « Reactiver ».
  static const Key cleConfirmer = ValueKey<String>('deleg-reactiver-confirmer');

  /// La cle du bouton « Garder suspendues ».
  static const Key cleGarder = ValueKey<String>('deleg-reactiver-garder');

  /// La cle du message « raison manquante ».
  static const Key cleErreur = ValueKey<String>('deleg-reactiver-erreur');

  @override
  State<FeuilleReactivation> createState() => _FeuilleReactivationEtat();
}

class _FeuilleReactivationEtat extends State<FeuilleReactivation> {
  final TextEditingController _raison = TextEditingController();
  bool _tente = false;

  @override
  void dispose() {
    _raison.dispose();
    super.dispose();
  }

  void _confirmer() {
    final String raison = _raison.text.trim();
    if (raison.isEmpty) {
      setState(() => _tente = true);
      return;
    }
    Navigator.of(context).pop(raison);
  }

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool vide = _tente && _raison.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(d.reactiverPhrase, style: textes.bodyMedium),
        Ecart.vXxl,
        ChampEtiquete(
          key: FeuilleReactivation.cleRaison,
          libelle: d.reactiverRaison,
          controller: _raison,
          maxLines: 3,
          obligatoire: true,
          aide: d.reactiverRaisonAide,
          onChanged: (String _) {
            if (_tente) setState(() {});
          },
        ),
        if (vide) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              d.reactiverRaisonVide,
              key: FeuilleReactivation.cleErreur,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vXxl,
        ActionPrincipale(
          key: FeuilleReactivation.cleConfirmer,
          libelle: d.reactiverConfirmer,
          onPress: _confirmer,
        ),
        Ecart.vMd,
        ActionPrincipale(
          key: FeuilleReactivation.cleGarder,
          libelle: d.reactiverGarder,
          niveau: NiveauAction.secondaire,
          onPress: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
