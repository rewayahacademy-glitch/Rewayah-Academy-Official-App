import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import 'etat_reglages_observation.dart';

/// Le module de reglage de l'observation d'un groupe.
///
/// **Composant isole, volontairement non route.** Il n'est declare ni dans
/// `admin_domaine.dart` -- gele a huit domaines, regle d'architecture absolue --
/// ni dans `ongletsConfiguration()`, dont le commentaire rappelle que seules
/// les fonctions reellement construites y figurent. C'est Agent Z qui le
/// branchera dans « Groupe > Reglages ». L'inscrire ici ferait echouer la
/// navigation au clic, exactement ce que l'audit Admin interdit.
///
/// Il ne lit ni n'ecrit aucun provider : les deux politiques lui sont donnees,
/// et il rend la politique demandee. L'ecriture est le travail de l'hote.
class ModuleReglagesObservation extends StatefulWidget {
  /// Cree le module.
  const ModuleReglagesObservation({
    required this.politiqueAcademie,
    required this.politiqueGroupe,
    required this.onEnregistrer,
    super.key,
    this.enCours = false,
  });

  /// Ce dont le groupe herite.
  final GuardianObservationPolicy politiqueAcademie;

  /// Ce qui s'applique au groupe aujourd'hui.
  final GuardianObservationPolicy politiqueGroupe;

  /// Appele avec la politique demandee.
  final ValueChanged<GuardianObservationPolicy> onEnregistrer;

  /// Vrai pendant l'enregistrement.
  final bool enCours;

  @override
  State<ModuleReglagesObservation> createState() =>
      _ModuleReglagesObservationEtat();
}

class _ModuleReglagesObservationEtat extends State<ModuleReglagesObservation> {
  late EtatReglagesObservation _etat = EtatReglagesObservation.depuis(
    widget.politiqueGroupe,
  );

  void _changer(EtatReglagesObservation suivant) =>
      setState(() => _etat = suivant);

  void _choisirSource(ReponseChoix reponse) {
    for (final SourcePolitique source in SourcePolitique.values) {
      if (reponse.valeurs.contains(source.valeurSql)) {
        _changer(_etat.avecSource(source));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Set<InvaliditeReglages> problemes = _etat.invalidites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.tc.observation.reglages.titre),
        Ecart.vSm,
        Text(t.tc.observation.reglages.intro, style: textes.bodyMedium),
        Ecart.vXl,
        // Trois choix fermes : `ChoiceCardGroup` sans saisie libre est le seul
        // point d'entree d'un choix propose a l'utilisateur (ADR-013).
        ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(
              valeur: SourcePolitique.academie.valeurSql,
              libelle: t.tc.observation.reglages.heriter,
              icone: AppIcons.heritage,
            ),
            OptionChoix(
              valeur: SourcePolitique.groupe.valeurSql,
              libelle: t.tc.observation.reglages.personnaliser,
              icone: AppIcons.personnalisationGroupe,
            ),
            OptionChoix(
              valeur: SourcePolitique.desactivee.valeurSql,
              libelle: t.tc.observation.reglages.desactiver,
              icone: AppIcons.observationFermee,
            ),
          ],
          onChange: _choisirSource,
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(
            valeurs: <String>{_etat.source.valeurSql},
          ),
        ),
        if (_etat.editable) ...<Widget>[
          Ecart.vXl,
          SettingRow(
            title: t.tc.observation.reglages.maxVisites,
            description: t.tc.observation.reglages.valeurHeritee(
              valeur: uniteVisitesObservation(
                widget.politiqueAcademie.maxVisitsPerSession,
              ),
            ),
            icon: AppIcons.foyer,
            value: uniteVisitesObservation(_etat.maxVisites),
            controle: _Pas(
              onMoins: () => _changer(_etat.deplacerVisites(-1)),
              onPlus: () => _changer(_etat.deplacerVisites(1)),
            ),
          ),
          SettingRow(
            title: t.tc.observation.reglages.tempsTotal,
            description: t.tc.observation.reglages.valeurHeritee(
              valeur: t.tc.observation.reglages.uniteSecondes(
                n: widget.politiqueAcademie.maxTotalObservationTime.inSeconds,
              ),
            ),
            icon: AppIcons.pause,
            value: t.tc.observation.reglages.uniteSecondes(
              n: _etat.tempsTotal.inSeconds,
            ),
            controle: _Pas(
              onMoins: () => _changer(_etat.deplacerTemps(-1)),
              onPlus: () => _changer(_etat.deplacerTemps(1)),
            ),
          ),
        ],
        if (problemes.contains(InvaliditeReglages.visitesTropBas)) ...<Widget>[
          Ecart.vSm,
          Text(t.tc.observation.reglages.invalideVisites, style: discret),
        ],
        if (problemes.contains(InvaliditeReglages.tempsTropBas)) ...<Widget>[
          Ecart.vSm,
          Text(t.tc.observation.reglages.invalideTemps, style: discret),
        ],
        Ecart.vLg,
        // La version de politique est affichee parce qu'elle est journalisee
        // avec chaque visite : six mois plus tard, c'est elle qui explique
        // pourquoi une visite avait droit a cent vingt secondes.
        Text(
          t.tc.observation.reglages.versionPolitique(
            version: widget.politiqueGroupe.policyVersion,
          ),
          style: discret,
        ),
        Ecart.vLg,
        ActionPrincipale(
          libelle: t.tc.observation.reglages.enregistrer,
          enCours: widget.enCours,
          onPress: _etat.valide
              ? () => widget.onEnregistrer(
                  _etat.appliquerA(widget.politiqueAcademie),
                )
              : null,
        ),
      ],
    );
  }
}

/// Les deux pas d'un quota.
///
/// Des mots, pas des signes : « Diminuer » et « Augmenter » se lisent a voix
/// haute par un lecteur d'ecran, la ou un moins et un plus ne disent rien.
class _Pas extends StatelessWidget {
  const _Pas({required this.onMoins, required this.onPlus});

  final VoidCallback onMoins;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      ActionPrincipale(
        libelle: t.tc.observation.reglages.diminuer,
        onPress: onMoins,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
      Ecart.hSm,
      ActionPrincipale(
        libelle: t.tc.observation.reglages.augmenter,
        onPress: onPlus,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
    ],
  );
}
