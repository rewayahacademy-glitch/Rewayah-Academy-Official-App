import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/libelles_tc_g.dart';
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
        const SectionHeader(titre: LibellesTcG.reglagesTitre),
        Ecart.vSm,
        Text(LibellesTcG.reglagesIntro, style: textes.bodyMedium),
        Ecart.vXl,
        // Trois choix fermes : `ChoiceCardGroup` sans saisie libre est le seul
        // point d'entree d'un choix propose a l'utilisateur (ADR-013).
        ChoiceCardGroup(
          options: <OptionChoix>[
            OptionChoix(
              valeur: SourcePolitique.academie.valeurSql,
              libelle: LibellesTcG.reglagesHeriter,
              // TC-ICONE: heritage
              icone: AppIcons.reglages,
            ),
            OptionChoix(
              valeur: SourcePolitique.groupe.valeurSql,
              libelle: LibellesTcG.reglagesPersonnaliser,
              // TC-ICONE: personnalisation-groupe
              icone: AppIcons.foyer,
            ),
            OptionChoix(
              valeur: SourcePolitique.desactivee.valeurSql,
              libelle: LibellesTcG.reglagesDesactiver,
              // TC-ICONE: observation-fermee
              icone: AppIcons.cameraCoupee,
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
            title: LibellesTcG.reglagesMaxVisites,
            description: LibellesTcG.valeurHeritee(
              LibellesTcG.uniteVisites(
                widget.politiqueAcademie.maxVisitsPerSession,
              ),
            ),
            icon: AppIcons.foyer,
            value: LibellesTcG.uniteVisites(_etat.maxVisites),
            controle: _Pas(
              onMoins: () => _changer(_etat.deplacerVisites(-1)),
              onPlus: () => _changer(_etat.deplacerVisites(1)),
            ),
          ),
          SettingRow(
            title: LibellesTcG.reglagesTempsTotal,
            description: LibellesTcG.valeurHeritee(
              LibellesTcG.uniteSecondes(
                widget.politiqueAcademie.maxTotalObservationTime.inSeconds,
              ),
            ),
            icon: AppIcons.pause,
            value: LibellesTcG.uniteSecondes(_etat.tempsTotal.inSeconds),
            controle: _Pas(
              onMoins: () => _changer(_etat.deplacerTemps(-1)),
              onPlus: () => _changer(_etat.deplacerTemps(1)),
            ),
          ),
        ],
        if (problemes.contains(InvaliditeReglages.visitesTropBas)) ...<Widget>[
          Ecart.vSm,
          Text(LibellesTcG.reglagesInvalideVisites, style: discret),
        ],
        if (problemes.contains(InvaliditeReglages.tempsTropBas)) ...<Widget>[
          Ecart.vSm,
          Text(LibellesTcG.reglagesInvalideTemps, style: discret),
        ],
        Ecart.vLg,
        // La version de politique est affichee parce qu'elle est journalisee
        // avec chaque visite : six mois plus tard, c'est elle qui explique
        // pourquoi une visite avait droit a cent vingt secondes.
        Text(
          LibellesTcG.versionPolitique(widget.politiqueGroupe.policyVersion),
          style: discret,
        ),
        Ecart.vLg,
        ActionPrincipale(
          libelle: LibellesTcG.reglagesEnregistrer,
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
        libelle: LibellesTcG.reglagesDiminuer,
        onPress: onMoins,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
      Ecart.hSm,
      ActionPrincipale(
        libelle: LibellesTcG.reglagesAugmenter,
        onPress: onPlus,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
    ],
  );
}
