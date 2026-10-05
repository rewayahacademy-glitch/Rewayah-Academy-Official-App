// Le detail d'une notification dans le centre partage (spec Communications
// V1, sections 13.1 et 18 « Notifications desktop » : le shell du role, le
// motif liste et detail, le centre et la carte d'annonce ; pas de nouvelle
// fonction).
//
// Une notification d'annonce de Classe montre l'annonce elle-meme
// (`AnnonceDetail`, R-COM-12) ; toute autre notification montre son type,
// son niveau en toutes lettres (« Information » en texte neutre, sans
// pastille, quand aucun badge ne le dit), sa date, son texte et, si elle en a une,
// l'ouverture de sa destination deja validee par le port.

import 'package:flutter/material.dart';

import '../../core/capacites/port_notifications.dart';
import '../../core/communications/modeles_communication.dart'
    show IndicateurAttention;
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/lien_fleche.dart';
import '../com_annonces/annonce_detail.dart';
import '../suivi_foyer/filtres_historique.dart';

/// Le mot qui nomme le type d'une notification (catalogue section 13.2).
String libelleTypeNotification(TypeNotification type) {
  final n = t.notifications.types;
  return switch (type) {
    TypeNotification.annonceClasse => n.annonceClasse,
    TypeNotification.changementSeance => n.changementSeance,
    TypeNotification.decisionDossier => n.decisionDossier,
    TypeNotification.messageMetier => n.messageMetier,
    TypeNotification.reponseAttendue => n.reponseAttendue,
    TypeNotification.accesFinance => n.accesFinance,
    TypeNotification.observation => n.observation,
    TypeNotification.travailRessource => n.travailRessource,
    TypeNotification.annonceDirection => n.annonceDirection,
    TypeNotification.changementPlanning => n.changementPlanning,
    TypeNotification.remplacement => n.remplacement,
    TypeNotification.mentionCommunaute => n.mentionCommunaute,
    TypeNotification.reponseCommunaute => n.reponseCommunaute,
    TypeNotification.messageAdministration => n.messageAdministration,
    TypeNotification.dossierATraiter => n.dossierATraiter,
    TypeNotification.signalementCommunaute => n.signalementCommunaute,
    TypeNotification.reponseFil => n.reponseFil,
    TypeNotification.annoncePlanifiee => n.annoncePlanifiee,
    TypeNotification.evenementOperationnel => n.evenementOperationnel,
    TypeNotification.mission => n.mission,
    TypeNotification.changementMission => n.changementMission,
    TypeNotification.reponseAdministration => n.reponseAdministration,
    TypeNotification.mentionStudio => n.mentionStudio,
    TypeNotification.reponseStudio => n.reponseStudio,
    TypeNotification.decisionDemandee => n.decisionDemandee,
    TypeNotification.elementAssigne => n.elementAssigne,
    TypeNotification.annonceInterne => n.annonceInterne,
    TypeNotification.evenementContextuel => n.evenementContextuel,
    TypeNotification.autre => n.autre,
  };
}

/// Ce que le badge d'une notification dit : son niveau (« A lire »,
/// « Action requise », « Urgent ») et la mention. Une notification lue de
/// niveau « A lire » redevient neutre ; une action requise ou une urgence
/// restent dites tant que la notification existe.
IndicateurAttention indicateurNotification(NotificationTuteur n) =>
    IndicateurAttention(
      niveau: n.lue && !n.demandeAction
          ? NiveauAttention.information
          : n.niveau,
      mention: n.mention,
    );

/// Le detail d'une notification.
class DetailNotification extends StatelessWidget {
  /// Cree le detail.
  const DetailNotification({
    required this.notification,
    super.key,
    this.onOuvrir,
  });

  /// La notification.
  final NotificationTuteur notification;

  /// Ouvre la destination de la notification ; sans lui, aucun lien.
  final VoidCallback? onOuvrir;

  /// La cle du lien vers la destination, pour les tests.
  static const ValueKey<String> cleOuvrir = ValueKey<String>(
    'notification-ouvrir',
  );

  /// La cle de la ligne du type et du niveau neutre, pour les tests.
  static const ValueKey<String> cleTypeNiveau = ValueKey<String>(
    'notification-type-niveau',
  );

  @override
  Widget build(BuildContext context) {
    final String? annonceId = notification.annonceId;
    if (annonceId != null) {
      return AnnonceDetail(
        key: ValueKey<String>('detail-annonce-$annonceId'),
        annonceId: annonceId,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime quand = notification.date.toLocal();
    final IndicateurAttention indicateur = indicateurNotification(notification);
    final String? texte = notification.texte;
    final VoidCallback? ouvrir = onOuvrir;
    return CarteGroupee(
      key: ValueKey<String>('detail-notification-${notification.id}'),
      sections: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Le type, et le niveau « Information » en toutes lettres quand
            // aucun badge ne le dit : texte neutre, jamais une pastille.
            Text(
              <String>[
                libelleTypeNotification(notification.type),
                if (!indicateur.estVisible)
                  BadgeNonLu.libelleNiveau(NiveauAttention.information),
              ].join(' · '),
              key: cleTypeNiveau,
              style: palette.inkMuted.applyTo(
                textes.labelMedium ?? const TextStyle(),
              ),
            ),
            if (indicateur.estVisible) ...<Widget>[
              Ecart.vSm,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BadgeNonLu(indicateur: indicateur),
              ),
            ],
            Ecart.vSm,
            Semantics(
              header: true,
              child: Text(
                notification.titre,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vXs,
            Text(
              t.notifications.detail.recue(
                date: dateLongueHistorique(quand),
                heure: heureMinute(quand),
              ),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
            if (texte != null) ...<Widget>[
              Ecart.vMd,
              Text(
                texte,
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
        if (ouvrir != null && notification.destination != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LienFleche(
              key: cleOuvrir,
              libelle: t.notifications.detail.ouvrir,
              alignerEnFin: true,
              onPress: ouvrir,
            ),
          ),
      ],
    );
  }
}
