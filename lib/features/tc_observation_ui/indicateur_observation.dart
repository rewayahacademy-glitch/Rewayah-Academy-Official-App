import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/status_pill.dart';

/// Vrai quand cet eleve doit recevoir l'indicateur discret.
///
/// **Lui seul.** La specification 11.3 est explicite : « les autres eleves
/// n'ont pas besoin d'etre interrompus ». Une classe de cinq enfants ou tout le
/// monde apprend qu'un parent regarde transformerait une visite de deux minutes
/// en evenement collectif.
///
/// Fonction pure, testable sans arbre de widgets.
///
/// TC-Z-SUIVI : **non branchee, et pas par oubli.** Aucun fichier de `lib/` ne
/// l'appelle (mesure du 21/09/2026, seul `test/teaching_core/g/
/// ecrans_observation_test.dart` la reference). Voir
/// [IndicateurObservationEnfant] pour la raison : la source de donnees qu'elle
/// filtrerait n'est pas lisible par l'eleve cote serveur.
bool enfantConcerneParObservation(
  List<AnnonceObservation> annonces,
  String? monProfilId,
) {
  if (monProfilId == null) {
    return false;
  }
  for (final AnnonceObservation annonce in annonces) {
    if (annonce.enfantConcerneId == monProfilId) {
      return true;
    }
  }
  return false;
}

/// L'annonce lue par l'enseignant pendant qu'un tuteur observe.
///
/// **Discrete par construction.** Une ligne, un temps restant, et rien quand
/// personne n'observe : ni bandeau qui pousse le contenu, ni son, ni fenetre.
/// Et **aucune notification de sortie** -- le flux cesse simplement de porter
/// l'annonce.
///
/// L'enseignant n'apprend jamais **quel** tuteur observe : voir
/// `t.tc.observation.annonce.tuteurObserve`.
class IndicateurObservation extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurObservation({required this.annonces, super.key});

  /// Les observations en cours. Vide = rien ne s'affiche.
  final List<AnnonceObservation> annonces;

  @override
  Widget build(BuildContext context) {
    if (annonces.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final AnnonceObservation annonce in annonces)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                  child: Icon(AppIcons.foyer.repos),
                ),
                Ecart.hSm,
                Expanded(
                  child: Text(
                    annonce.libelle,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
                if (annonce.tempsRestant case final Duration restant) ...<Widget>[
                  Ecart.hSm,
                  StatusPill(
                    libelle: t.tc.observation.annonce.restant(
                      secondes: restant.inSeconds,
                    ),
                    ton: TonEtat.neutre,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// L'indicateur discret, du cote de l'enfant observe.
///
/// Un mot, sans action et sans bouton. Un enfant de sept ans n'a rien a decider
/// ici : il a seulement le droit de savoir.
///
/// TC-Z-SUIVI : **le cote enfant n'est PAS livre, et il manque une capacite
/// serveur, pas un cablage.** Ce composant n'est monte dans aucun ecran de
/// `lib/` -- mesure du 21/09/2026 : la seule reference hors de ce fichier est
/// `test/teaching_core/g/ecrans_observation_test.dart`. Le brancher
/// aujourd'hui poserait un indicateur qui ne s'allumerait jamais, pour deux
/// verrous independants :
///
/// 1. `annonces_observation(p_session_id)` -- l'unique lecture des visites en
///    cours -- leve `insufficient_privilege` pour tout appelant qui n'est pas
///    l'enseignant de la seance (`0033_tc_vues_rpc.sql:1275`). Un eleve n'en
///    obtient donc jamais une ligne.
/// 2. La RLS de `guardian_session_visit` ne donne le SELECT qu'a l'observateur
///    lui-meme (`guardian_visit_self`) ou a un administrateur
///    (`guardian_visit_admin`) -- `0032_tc_catalogue.sql:488-492`. L'eleve
///    observe n'est ni l'un ni l'autre.
///
/// Ce qu'il faudrait d'abord : une RPC de lecture reservee a l'eleve concerne,
/// qui ne rende QUE sa propre ligne. C'est une exigence de vie privee, pas un
/// detail d'implementation : un enfant ne doit jamais apprendre que le parent
/// d'un AUTRE enfant observe (specification 11.3, « les autres eleves n'ont pas
/// besoin d'etre interrompus »). Le jour ou elle existe, l'indicateur se pose
/// DANS un bloc deja present de l'accueil eleve ou dans la salle, jamais en
/// troisieme bloc : `test/features/accueil_eleve_test.dart`, groupe « ELV-02 :
/// deux blocs, rien d'autre », fige ce compte, et un ajout y a deja du etre
/// reverte.
class IndicateurObservationEnfant extends StatelessWidget {
  /// Cree l'indicateur.
  const IndicateurObservationEnfant({required this.visible, super.key});

  /// Vrai quand le tuteur de cet enfant observe.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconTheme(
          data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
          child: Icon(AppIcons.foyer.repos),
        ),
        Ecart.hSm,
        Flexible(
          child: Text(
            t.tc.observation.annonce.enfantIndicateur,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
