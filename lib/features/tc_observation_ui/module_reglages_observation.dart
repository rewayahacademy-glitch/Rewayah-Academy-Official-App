import 'package:flutter/material.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/libelles_observation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import 'etat_reglages_observation.dart';

/// Le module de reglage de l'observation d'un groupe.
///
/// **Son hote est Admin > Operations > Groupes**, en feuille sur la ligne du
/// groupe (`lib/features/admin_groupes/feuille_observation_groupe.dart`) : la
/// politique que `definir_politique_observation_groupe` ecrit est PAR GROUPE,
/// elle se regle donc depuis le groupe. Il n'est toujours declare ni dans
/// `admin_domaine.dart` -- gele a huit domaines, regle d'architecture absolue --
/// ni dans `ongletsConfiguration()` : Configuration porterait les defauts de
/// l'Academie, qui vivent dans `app_config`, pas le reglage d'un groupe.
///
/// Il ne lit ni n'ecrit aucun provider : les deux politiques lui sont donnees,
/// et il rend la politique demandee. L'ecriture est le travail de l'hote.
///
/// Le plafond par visite qu'il expose n'existe cote serveur qu'a partir de la
/// migration `0036`, **non appliquee en production au 21 septembre 2026** :
/// tant qu'elle attend, l'enregistrement echoue entierement en
/// `MotifEchecObservation.capaciteAbsente` et l'hote le dit en clair.
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

  /// « Augmenter » des deux quotas qui peuvent etre trop bas : le focus y
  /// revient quand l'enregistrement est presse trop tot (BOUTONS-GRISES-1).
  final FocusNode _focusVisites = FocusNode(debugLabel: 'augmenter-visites');
  final FocusNode _focusTemps = FocusNode(debugLabel: 'augmenter-temps');

  @override
  void dispose() {
    _focusVisites.dispose();
    _focusTemps.dispose();
    super.dispose();
  }

  void _changer(EtatReglagesObservation suivant) =>
      setState(() => _etat = suivant);

  /// Jamais grise (BOUTONS-GRISES-1) : des reglages invalides se disent deja
  /// sous les quotas ; l'appui les annonce et rend le focus a « Augmenter »
  /// du premier quota trop bas.
  void _enregistrer() {
    final Set<InvaliditeReglages> problemes = _etat.invalidites;
    if (problemes.isEmpty) {
      widget.onEnregistrer(_etat.appliquerA(widget.politiqueAcademie));
      return;
    }
    final bool visites = problemes.contains(InvaliditeReglages.visitesTropBas);
    signalerManque(
      context,
      <String>[
        if (visites) t.tc.observation.reglages.invalideVisites,
        if (problemes.contains(InvaliditeReglages.tempsTropBas))
          t.tc.observation.reglages.invalideTemps,
      ].join(' '),
      champ: visites ? _focusVisites : _focusTemps,
    );
  }

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
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.tc.observation.reglages.maxVisites,
                description: t.tc.observation.reglages.valeurHeritee(
                  valeur: uniteVisitesObservation(
                    widget.politiqueAcademie.maxVisitsPerSession,
                  ),
                ),
                icon: AppIcons.foyer,
                value: uniteVisitesObservation(_etat.maxVisites),
                largeurControle: _Pas.largeur(context),
                controle: _Pas(
                  focusPlus: _focusVisites,
                  onMoins: () => _changer(_etat.deplacerVisites(-1)),
                  onPlus: () => _changer(_etat.deplacerVisites(1)),
                ),
              ),
              SettingRow(
                title: t.tc.observation.reglages.tempsTotal,
                description: t.tc.observation.reglages.valeurHeritee(
                  valeur: LibellesGroupe.insecable(
                    t.tc.observation.reglages.uniteSecondes(
                      n: widget
                          .politiqueAcademie
                          .maxTotalObservationTime
                          .inSeconds,
                    ),
                  ),
                ),
                icon: AppIcons.pause,
                value: LibellesGroupe.valeurSeule(
                  t.tc.observation.reglages.uniteSecondes(
                    n: _etat.tempsTotal.inSeconds,
                  ),
                ),
                largeurControle: _Pas.largeur(context),
                controle: _Pas(
                  focusPlus: _focusTemps,
                  onMoins: () => _changer(_etat.deplacerTemps(-1)),
                  onPlus: () => _changer(_etat.deplacerTemps(1)),
                ),
              ),
              // Le cinquieme parametre de `definir_politique_observation_groupe`,
              // ajoute par la migration `0036` -- non appliquee en production au
              // 21 septembre 2026. Sans lui, un groupe personnalise perdait son
              // plafond par visite et consommait tout son temps d'un seul coup :
              // la seconde visite, qui est la raison d'etre du reglage, naissait
              // vide.
              SettingRow(
                title: t.tc.observation.reglages.plafondVisite,
                description: t.tc.observation.reglages.valeurHeritee(
                  valeur: LibellesGroupe.insecable(
                    t.tc.observation.reglages.uniteSecondes(
                      n: widget.politiqueAcademie
                          .plafondDeVisite(
                            widget.politiqueAcademie.maxTotalObservationTime,
                          )
                          .inSeconds,
                    ),
                  ),
                ),
                icon: AppIcons.creneaux,
                value: LibellesGroupe.valeurSeule(
                  t.tc.observation.reglages.uniteSecondes(
                    n: _etat.plafondEffectif.inSeconds,
                  ),
                ),
                largeurControle: _Pas.largeur(context),
                controle: _Pas(
                  onMoins: () => _changer(_etat.deplacerPlafond(-1)),
                  onPlus: () => _changer(_etat.deplacerPlafond(1)),
                ),
              ),
            ],
          ),
        ],
        if (problemes.contains(InvaliditeReglages.visitesTropBas)) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.tc.observation.reglages.invalideVisites,
              style: discret,
            ),
          ),
        ],
        if (problemes.contains(InvaliditeReglages.tempsTropBas)) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.tc.observation.reglages.invalideTemps,
              style: discret,
            ),
          ),
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
          onPress: _enregistrer,
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
  const _Pas({required this.onMoins, required this.onPlus, this.focusPlus});

  final VoidCallback onMoins;
  final VoidCallback onPlus;

  /// Le focus d'« Augmenter », rendu quand le quota est trop bas.
  final FocusNode? focusPlus;

  /// La largeur du pas a pas (deux actions tertiaires et leur ecart) : la
  /// ligne garde alors sa valeur en fin de ligne quand tout y tient.
  static double largeur(BuildContext context) {
    final TextStyle style = AppTypography.graisse(
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
      FontWeight.w700,
    );
    double mesure(String libelle) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: libelle, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final double l = p.width;
      p.dispose();
      return l;
    }

    // Marge de 2 par action : l'arrondi des glyphes.
    return mesure(t.tc.observation.reglages.diminuer) +
        mesure(t.tc.observation.reglages.augmenter) +
        AppSpacing.xl * 4 +
        AppSpacing.sm +
        4;
  }

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
        focusNode: focusPlus,
        onPress: onPlus,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
      ),
    ],
  );
}
