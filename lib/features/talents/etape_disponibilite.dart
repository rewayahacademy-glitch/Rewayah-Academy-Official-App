// La derniere etape de « Vos autres talents » (`CAND-07`) : la disponibilite pour
// une mission, et l'accord d'etre contacte.
//
// Quatre cartes decrites (une seule se choisit), puis la case de l'accord, que
// la personne coche ou non : rien ne s'efface si elle ne la coche pas, et la
// phrase sous la case dit ce que cela change (l'academie lit les reponses sans
// proposer de mission). Rien sur le montant d'une mission : chaque mission aura
// ses conditions, dites au moment du contact.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card_group.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;
import 'controleur_talents.dart';
import 'libelles_talents.dart';

/// Le corps de l'etape de la disponibilite et de l'accord.
class EtapeDisponibilite extends StatelessWidget {
  /// Cree le corps.
  const EtapeDisponibilite({
    required this.controleur,
    this.enCours = false,
    super.key,
  });

  /// Le parcours.
  final ControleurTalents controleur;

  /// Vrai pendant l'enregistrement : la case se fige.
  final bool enCours;

  /// La cle du groupe des quatre disponibilites.
  static const Key groupeKey = ValueKey<String>('talents-disponibilites');

  /// La cle de la case de l'accord.
  static const Key accordKey = ValueKey<String>('talents-accord');

  /// La cle de la phrase qui dit ce que change l'accord.
  static const Key accordNoteKey = ValueKey<String>('talents-accord-note');

  /// La cle de la carte d'une disponibilite.
  static Key carteKey(DisponibiliteMission dispo) =>
      ValueKey<String>('talents-dispo-${dispo.valeurSql}');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final DisponibiliteMission? choisie = controleur.disponibilite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChoiceCardGroup(
          key: groupeKey,
          autoriserSaisieLibre: false,
          valeurInitiale: choisie == null
              ? null
              : ReponseChoix(valeurs: <String>{choisie.valeurSql}),
          options: <OptionChoix>[
            for (final DisponibiliteMission d in DisponibiliteMission.values)
              OptionChoix(
                cle: carteKey(d),
                valeur: d.valeurSql,
                libelle: libelleDisponibilite(d),
                description: descriptionDisponibilite(d),
                icone: _icone(d),
              ),
          ],
          onChange: (ReponseChoix reponse) {
            final DisponibiliteMission? d = reponse.valeurs.isEmpty
                ? null
                : DisponibiliteMission.depuisSql(reponse.valeurs.first);
            if (d != null) {
              controleur.definirDisponibilite(d);
            }
          },
        ),
        Ecart.vXl,
        CaseAccordTexte(
          key: accordKey,
          libelle: t.recrutement.talents.disponibilite.accord,
          cochee: controleur.accord,
          onChanged: enCours
              ? null
              : (bool v) => controleur.definirAccord(accord: v),
        ),
        Ecart.vSm,
        TexteSansCoupure(
          t.recrutement.talents.disponibilite.accordNote,
          key: accordNoteKey,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }

  static AppIcon _icone(DisponibiliteMission d) => switch (d) {
    DisponibiliteMission.quelquesHeures => AppIcons.horloge,
    DisponibiliteMission.miTemps => AppIcons.disponibilites,
    DisponibiliteMission.plus => AppIcons.journee,
    DisponibiliteMission.pasMaintenant => AppIcons.attente,
  };
}
