import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'bloc_seance.dart';
import 'liste_preparation.dart';

/// « Derniere seance » : date et duree, presence confirmee, lien vers
/// l'Historique, puis « Details de la seance › » (maquettes V1 et V2).
///
/// **Aucun reseau affiche** : la qualite de connexion de l'eleve ou de
/// l'enseignant n'est montree que mesuree et autorisee (defaut C5), et rien
/// ne la mesure aujourd'hui. **Aucune absence deduite** : une presence
/// illisible s'affiche par la table unique de `LignePresence` (etat inconnu),
/// jamais « Absence » (invariant J3). Une seance annulee ou non tenue dit son
/// statut a la place d'une presence.
class LigneDerniereSeance extends StatelessWidget {
  /// Cree la section.
  const LigneDerniereSeance({
    required this.derniere,
    required this.presence,
    required this.maintenantServeurUtc,
    required this.onVoirHistorique,
    required this.onDetails,
    required this.onReessayer,
    super.key,
  });

  /// La derniere seance passee de l'eleve (K2).
  final AsyncValue<SeanceFamille?> derniere;

  /// La ligne de presence de l'eleve a cette seance, quand elle est lue.
  final AsyncValue<PresenceParticipant?>? presence;

  /// L'instant serveur, `null` sans horloge serveur.
  final DateTime? maintenantServeurUtc;

  /// Ouvre l'Historique, filtre sur l'eleve.
  final VoidCallback onVoirHistorique;

  /// Ouvre le detail d'une seance.
  final ValueChanged<String> onDetails;

  /// Relit la derniere seance.
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    final List<Widget> corps;
    if (derniere.hasError) {
      corps = <Widget>[
        Text(t.tuteur.accueil.derniereIllisible, style: discret),
        ActionPrincipale(
          libelle: t.commun.reessayer,
          onPress: onReessayer,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
        ),
      ];
    } else if (!derniere.hasValue) {
      corps = const <Widget>[Skeleton.texte(lignes: 2)];
    } else if (derniere.value == null) {
      corps = <Widget>[Text(t.tuteur.accueil.aucuneDerniere, style: discret)];
    } else {
      final SeanceFamille seance = derniere.value!;
      final AffichageSeance affichage = AffichageSeance.depuis(
        seance,
        maintenantServeurUtc: maintenantServeurUtc,
      );
      corps = <Widget>[
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Une seance annulee : date barree et attenuee (ANNUL-VIS-1).
            TexteHeureSeance(
              heure: t.tuteur.accueil.dateEtDuree(
                date: affichage.date,
                duree: affichage.duree,
              ),
              annulee: affichage.etatPastille == EtatPastilleSeance.annulee,
              style: discret,
            ),
            ?_pastille(seance, affichage),
          ],
        ),
        Ecart.vSm,
        _LigneDetails(onPress: () => onDetails(seance.seanceId)),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EnteteSection(
          icone: AppIcons.suivi,
          titre: t.tuteur.accueil.derniereSeance,
          lien: t.tuteur.accueil.voirHistorique,
          onLien: onVoirHistorique,
        ),
        Ecart.vSm,
        ...corps,
      ],
    );
  }

  /// La pastille : le statut d'une seance qui n'a pas eu lieu, sinon la
  /// presence de l'eleve par la table unique de `LignePresence`.
  Widget? _pastille(SeanceFamille seance, AffichageSeance affichage) {
    final Widget? statut = affichage.widgetPastille;
    final bool pasTenue = switch (affichage.etat) {
      EtatSeanceFamille.annulee ||
      EtatSeanceFamille.annuleeTardive ||
      EtatSeanceFamille.nonTenue ||
      EtatSeanceFamille.reportee => true,
      _ => false,
    };
    if (pasTenue && statut != null) {
      return statut;
    }
    final AsyncValue<PresenceParticipant?>? lue = presence;
    if (lue == null || lue.isLoading && !lue.hasValue) {
      return null;
    }
    final VuePresence vue = VuePresence.depuis(
      ligne: lue.value,
      maintenant: (maintenantServeurUtc ?? seance.finPrevueUtc).toLocal(),
    );
    return StatusPill(libelle: LignePresence.libelle(vue.etat), ton: vue.ton);
  }
}

/// « Details de la seance › » : une ligne sobre, grise, chevron (V2 ;
/// « Details et connexion » renomme, defaut A8).
class _LigneDetails extends StatelessWidget {
  const _LigneDetails({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Pressable(
      onPress: onPress,
      libelleSemantique: t.tuteur.accueil.detailsSeance,
      arrondiFocus: AppRadius.arrondiSm,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  t.tuteur.accueil.detailsSeance,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
