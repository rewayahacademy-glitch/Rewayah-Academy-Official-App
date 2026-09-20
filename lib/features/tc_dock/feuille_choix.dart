import 'package:flutter/material.dart';

import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';

/// Un choix ferme, en une feuille et un geste.
///
/// **Une seule feuille pour les trois questions du dock** : quelle intention
/// pour « Marquer », quelle intention pour « Revision », quelle portee pour le
/// stylet. Trois feuilles jumelles auraient diverge au premier ajout.
///
/// **Aucun formulaire.** La spec est explicite pour l'outil Revision : creer un
/// travail « sans formulaire long » (section 8.1). On choisit, et c'est fini --
/// le choix vaut validation. Le groupe, la ressource, la plage et l'auteur sont
/// deja connus du systeme : les retaper serait de la bureaucratie, et
/// l'application est la pour l'absorber.
///
/// Le choix passe par `ChoiceCardGroup`, seul point d'entree d'un choix propose
/// a l'utilisateur (ADR-013), avec `autoriserSaisieLibre: false` : ces
/// vocabulaires sont fermes, et une sixieme intention ecrite a la main
/// casserait la derivation de couleur comme le vocabulaire partage avec les
/// assignations.
class FeuilleChoix extends StatelessWidget {
  /// Cree le corps de la feuille.
  const FeuilleChoix({
    required this.aide,
    required this.options,
    required this.onChoix,
    super.key,
    this.valeurInitiale,
  });

  /// La phrase qui explique ce que le choix va produire.
  final String aide;

  /// Les reponses possibles.
  final List<OptionChoix> options;

  /// Appele avec la valeur retenue.
  final void Function(String valeur) onChoix;

  /// La valeur deja retenue, s'il y en a une.
  final String? valeurInitiale;

  /// Ouvre la feuille et rend l'intention choisie, ou `null` si elle est
  /// fermee sans choix.
  static Future<IntentionPedagogique?> ouvrirIntention(
    BuildContext context, {
    required String titre,
    required String aide,
    IntentionPedagogique? intentionInitiale,
  }) async {
    final String? valeur = await _ouvrir(
      context,
      titre: titre,
      aide: aide,
      valeurInitiale: intentionInitiale?.valeurSql,
      options: <OptionChoix>[
        for (final IntentionPedagogique intention
            in IntentionPedagogique.values)
          OptionChoix(
            valeur: intention.valeurSql,
            libelle: libelleIntentionPedagogique(intention),
          ),
      ],
    );
    return IntentionPedagogique.depuisSql(valeur);
  }

  /// Ouvre la feuille et rend la portee choisie, ou `null` si elle est fermee
  /// sans choix.
  static Future<PorteeAnnotation?> ouvrirPortee(
    BuildContext context, {
    required String titre,
    required String aide,
    PorteeAnnotation? porteeInitiale,
  }) async {
    final String? valeur = await _ouvrir(
      context,
      titre: titre,
      aide: aide,
      valeurInitiale: porteeInitiale?.valeurSql,
      options: <OptionChoix>[
        for (final PorteeAnnotation portee in PorteeAnnotation.values)
          OptionChoix(
            valeur: portee.valeurSql,
            libelle: libellePorteeAnnotation(portee),
          ),
      ],
    );
    return PorteeAnnotation.depuisSql(valeur);
  }

  static Future<String?> _ouvrir(
    BuildContext context, {
    required String titre,
    required String aide,
    required List<OptionChoix> options,
    String? valeurInitiale,
  }) => AppBottomSheet.ouvrir<String>(
    context,
    titre: titre,
    constructeur: (BuildContext contexteFeuille) => FeuilleChoix(
      aide: aide,
      options: options,
      valeurInitiale: valeurInitiale,
      onChoix: (String valeur) => Navigator.of(contexteFeuille).pop(valeur),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          aide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: options,
          valeurInitiale: valeurInitiale == null
              ? null
              : ReponseChoix(valeurs: <String>{valeurInitiale!}),
          onChange: (ReponseChoix reponse) {
            if (reponse.valeurs.isNotEmpty) {
              onChoix(reponse.valeurs.first);
            }
          },
        ),
      ],
    );
  }
}
