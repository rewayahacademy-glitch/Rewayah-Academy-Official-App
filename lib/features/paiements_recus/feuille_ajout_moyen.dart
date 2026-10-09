// La feuille « Ajouter » ou « Remplacer » une methode de paiement
// (`BeneficiaryPaymentSetup`, spec §17, §19 ; CPT-BEN-2).
//
// Un seul champ, **choisi** (K-57) : le type de methode, parmi ceux que la
// source propose (`corridorsProposes`), preselectionne quand il n'y en a
// qu'un. Les coordonnees ne sont **jamais saisies ici** : la personne
// continue vers la saisie securisee (chez le prestataire, ou champ chiffre
// jamais conserve), qui rend un jeton opaque (`SaisieSecurisee`). La phrase
// de contexte le dit avant le geste (K-58).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/choice_card_group.dart';

/// Ouvre la feuille et rend le type choisi, ou `null` si la personne
/// renonce.
Future<String?> choisirTypeMoyen(
  BuildContext context, {
  required String titre,
  required List<String> types,
}) => AppBottomSheet.ouvrir<String>(
  context,
  titre: titre,
  constructeur: (BuildContext contexte) => CorpsAjoutMoyen(
    types: types,
    onContinuer: (String type) => Navigator.of(contexte).pop(type),
  ),
);

/// Le corps de la feuille, rendu seul dans les tests.
class CorpsAjoutMoyen extends StatefulWidget {
  /// Cree le corps.
  const CorpsAjoutMoyen({
    required this.types,
    required this.onContinuer,
    super.key,
  });

  /// Les types proposes par la source.
  final List<String> types;

  /// Recoit le type retenu.
  final ValueChanged<String> onContinuer;

  /// La cle du bouton « Continuer vers la saisie securisee ».
  static const Key continuerKey = ValueKey<String>('recevoir-continuer');

  @override
  State<CorpsAjoutMoyen> createState() => _CorpsAjoutMoyenEtat();
}

class _CorpsAjoutMoyenEtat extends State<CorpsAjoutMoyen> {
  // Un seul type propose : il est deja choisi (K-57, deduit avant choisi).
  late String? _type = widget.types.length == 1 ? widget.types.first : null;
  bool _tente = false;

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.surfaceRaised.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    if (widget.types.isEmpty) {
      return Text(r.aucunType, style: corps);
    }
    final String? type = _type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(r.ajoutContexte, style: corps),
        Ecart.vLg,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: type == null
              ? null
              : ReponseChoix(valeurs: <String>{type}),
          options: <OptionChoix>[
            for (final String nom in widget.types)
              OptionChoix(
                valeur: nom,
                libelle: nom,
                cle: ValueKey<String>('recevoir-type-$nom'),
              ),
          ],
          onChange: (ReponseChoix reponse) => setState(
            () =>
                _type = reponse.valeurs.isEmpty ? null : reponse.valeurs.first,
          ),
        ),
        if (_tente && type == null) ...<Widget>[
          Ecart.vMd,
          Text(
            r.typeRequis,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vMd,
        Text(
          r.verificationAnnoncee,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        ActionPrincipale(
          key: CorpsAjoutMoyen.continuerKey,
          libelle: r.continuerSaisie,
          onPress: () {
            final String? choisi = _type;
            if (choisi == null) {
              setState(() => _tente = true);
              return;
            }
            widget.onContinuer(choisi);
          },
        ),
      ],
    );
  }
}
