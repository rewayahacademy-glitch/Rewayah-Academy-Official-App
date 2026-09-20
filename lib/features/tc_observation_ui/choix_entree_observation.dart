import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/mode_entree_admin.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import 'options_entree_observation.dart';

/// Ce qui se passe avant d'entrer dans une seance.
///
/// **Le choix de mode n'apparait que pour l'administration.** Le controleur
/// n'en a pas -- specification 11.6, « ne pas lui donner le choix d'un mode
/// visible dans ce chantier » -- et le tuteur non plus, dont le mode est fixe
/// par la politique du groupe. Ce n'est pas le widget qui en decide : il lit
/// [OptionsEntreeObservation], ou la regle est ecrite une seule fois et se
/// teste sans arbre de widgets.
///
/// **Presentation seule, aucun provider.**
class ChoixEntreeObservation extends StatelessWidget {
  /// Cree l'ecran de choix.
  const ChoixEntreeObservation({
    required this.options,
    required this.onMode,
    required this.onEntrer,
    super.key,
    this.modeRetenu,
    this.enCours = false,
  });

  /// Ce que ce compte peut faire devant cette porte.
  final OptionsEntreeObservation options;

  /// Le mode retenu, quand un choix est propose.
  final ModeEntreeAdmin? modeRetenu;

  /// Appele quand le mode change.
  final ValueChanged<ModeEntreeAdmin> onMode;

  /// Appele a la demande d'entree. `null` desactive l'action.
  final VoidCallback? onEntrer;

  /// Vrai pendant que le serveur repond.
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final RoleObservateur? role = options.roleDemande(modeRetenu);
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(options.intro, style: textes.bodyMedium),
        if (options.choisitSonMode) ...<Widget>[
          Ecart.vXl,
          // `ChoiceCardGroup` est le seul point d'entree d'un choix propose a
          // l'utilisateur (ADR-013). La saisie libre est fermee : les deux
          // modes sont une liste administrative close, pas une question
          // ouverte.
          ChoiceCardGroup(
            options: <OptionChoix>[
              for (final ModeEntreeAdmin mode in options.modes)
                OptionChoix(
                  valeur: mode.name,
                  libelle: _libelle(mode),
                  icone: _icone(mode),
                ),
            ],
            onChange: _choisir,
            autoriserSaisieLibre: false,
            valeurInitiale: modeRetenu == null
                ? null
                : ReponseChoix(valeurs: <String>{modeRetenu!.name}),
          ),
          if (modeRetenu case final ModeEntreeAdmin mode) ...<Widget>[
            Ecart.vSm,
            Text(_detail(mode), style: discret),
          ],
        ],
        if (role != null && ProfilObservateur.pour(role).incognito) ...<Widget>[
          Ecart.vLg,
          // L'incognito est invisible aux participants, jamais invisible a
          // l'audit : le rappel est permanent, y compris pour celui qui
          // l'accepte chaque jour.
          Text(t.tc.observation.entree.visiteJournalisee, style: discret),
        ],
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.tc.observation.entree.entrer,
          onPress: options.observationPossible ? onEntrer : null,
          enCours: enCours,
        ),
      ],
    );
  }

  void _choisir(ReponseChoix reponse) {
    for (final ModeEntreeAdmin mode in options.modes) {
      if (reponse.valeurs.contains(mode.name)) {
        onMode(mode);
        return;
      }
    }
  }

  static String _libelle(ModeEntreeAdmin mode) => switch (mode) {
    ModeEntreeAdmin.observerDiscretement => t.tc.observation.entree.modeDiscret,
    ModeEntreeAdmin.rejoindreLaClasse => t.tc.observation.entree.modeVisible,
  };

  static String _detail(ModeEntreeAdmin mode) => switch (mode) {
    ModeEntreeAdmin.observerDiscretement =>
      t.tc.observation.entree.modeDiscretDetail,
    ModeEntreeAdmin.rejoindreLaClasse =>
      t.tc.observation.entree.modeVisibleDetail,
  };

  static AppIcon _icone(ModeEntreeAdmin mode) => switch (mode) {
    ModeEntreeAdmin.observerDiscretement => AppIcons.observationIncognito,
    ModeEntreeAdmin.rejoindreLaClasse => AppIcons.administrationVisible,
  };
}
