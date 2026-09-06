import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une option proposee a l'utilisateur.
@immutable
class OptionChoix {
  /// Cree une option.
  const OptionChoix({required this.valeur, required this.libelle, this.icone});

  /// La valeur transmise a l'appelant.
  final String valeur;

  /// Le libelle affiche.
  final String libelle;

  /// Icone facultative.
  final AppIcon? icone;
}

/// Ce que l'utilisateur a repondu.
@immutable
class ReponseChoix {
  /// Cree une reponse.
  const ReponseChoix({required this.valeurs, this.saisieLibre});

  /// Les valeurs des cartes retenues.
  final Set<String> valeurs;

  /// Le texte saisi quand la carte « Autre » est retenue.
  final String? saisieLibre;

  /// Vrai quand l'utilisateur a repondu quelque chose d'exploitable.
  bool get renseignee =>
      valeurs.isNotEmpty || (saisieLibre != null && saisieLibre!.isNotEmpty);
}

/// Selection par cartes, avec repli « Autre » en saisie libre.
///
/// **Seul point d'entree pour tout choix propose a l'utilisateur** (ADR-013),
/// dans l'onboarding comme ailleurs. La carte « Autre » est systematique : elle
/// n'est pas une option de l'appelant, parce qu'un parcours qui n'offre aucune
/// issue a celui qui ne se reconnait dans aucune reponse est un parcours qui
/// perd cet utilisateur.
class ChoiceCardGroup extends StatefulWidget {
  /// Cree un groupe de cartes.
  const ChoiceCardGroup({
    required this.options,
    required this.onChange,
    super.key,
    this.selectionMultiple = false,
    this.valeurInitiale,
  });

  /// Les reponses les plus courantes.
  final List<OptionChoix> options;

  /// Appele a chaque changement de reponse.
  final void Function(ReponseChoix reponse) onChange;

  /// Vrai pour autoriser plusieurs reponses.
  final bool selectionMultiple;

  /// Reponse pre-cochee, utile a l'onboarding de confirmation (ADR-014).
  final ReponseChoix? valeurInitiale;

  /// Valeur interne de la carte « Autre ».
  static const String valeurAutre = r'$autre';

  @override
  State<ChoiceCardGroup> createState() => _ChoiceCardGroupState();
}

class _ChoiceCardGroupState extends State<ChoiceCardGroup> {
  late Set<String> _selection =
      widget.valeurInitiale?.valeurs.toSet() ?? <String>{};
  late final TextEditingController _saisie = TextEditingController(
    text: widget.valeurInitiale?.saisieLibre ?? '',
  );

  bool get _autreRetenu => _selection.contains(ChoiceCardGroup.valeurAutre);

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _basculer(String valeur) {
    setState(() {
      if (widget.selectionMultiple) {
        if (!_selection.remove(valeur)) {
          _selection.add(valeur);
        }
      } else {
        _selection = <String>{valeur};
      }
    });
    _notifier();
  }

  void _notifier() {
    widget.onChange(
      ReponseChoix(
        valeurs: Set<String>.unmodifiable(_selection),
        saisieLibre: _autreRetenu ? _saisie.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.selectionMultiple) ...<Widget>[
          Text(
            t.choix.selectionMultiple,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vMd,
        ],
        for (final OptionChoix option in widget.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _Carte(
              libelle: option.libelle,
              icone: option.icone,
              retenue: _selection.contains(option.valeur),
              onPress: () => _basculer(option.valeur),
            ),
          ),
        // La carte « Autre » n'est jamais conditionnelle.
        _Carte(
          libelle: t.choix.autre,
          icone: AppIcons.autreChoix,
          retenue: _autreRetenu,
          onPress: () => _basculer(ChoiceCardGroup.valeurAutre),
        ),
        if (_autreRetenu) ...<Widget>[
          Ecart.vMd,
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metriques.cibleTactile),
            child: TextField(
              controller: _saisie,
              onChanged: (String _) => _notifier(),
              decoration: InputDecoration(labelText: t.choix.autreInvite),
            ),
          ),
        ],
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({
    required this.libelle,
    required this.retenue,
    required this.onPress,
    this.icone,
  });

  final String libelle;
  final bool retenue;
  final VoidCallback onPress;
  final AppIcon? icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    // La selection change la PAIRE entiere, pas seulement le fond : le texte
    // suit toujours son fond.
    final AppColorPair paire = retenue
        ? palette.surfacePrimary
        : palette.surfaceBase;

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      respecterCibleTactile: false,
      child: Container(
        constraints: BoxConstraints(minHeight: metriques.cibleTactile),
        padding: EdgeInsets.all(metriques.marge),
        decoration: paire.decoration(
          borderRadius: BorderRadius.circular(metriques.rayon),
          side: retenue ? null : palette.borderDefault.asBorderSide(width: 2),
        ),
        child: Row(
          children: <Widget>[
            if (icone != null) ...<Widget>[
              IconTheme(
                data: IconThemeData(
                  color: paire.onBackground,
                  size: AppSpacing.xxl,
                ),
                child: Icon(icone!.resoudre(selectionne: retenue)),
              ),
              Ecart.hMd,
            ],
            Expanded(
              child: Text(
                libelle,
                style: paire.applyTo(
                  Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            if (retenue)
              IconTheme(
                data: IconThemeData(
                  color: paire.onBackground,
                  size: AppSpacing.xxl,
                ),
                child: Icon(AppIcons.succes.actif),
              ),
          ],
        ),
      ),
    );
  }
}
