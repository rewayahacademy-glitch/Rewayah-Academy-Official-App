import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_notifications.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../suivi_foyer/composants_historique.dart';
import '../suivi_foyer/filtres_historique.dart';

/// Les notifications du tuteur (`/tuteur/notifications`, lot E sous-paquet 3).
///
/// Ouvertes par la cloche de l'en-tete (coquille du tuteur, une seule place),
/// rangees sous l'Accueil : l'Accueil reste actif dans la barre, le disque
/// retour ramene a l'Accueil. Composition du manifeste (section 5, ligne
/// `/tuteur/notifications`) : titre, UNE carte a filets, date a gauche,
/// chevron quand la notification mene quelque part.
///
/// **Aucune source n'existe (DB-CPT-04)** : le port de production rend
/// `CapaciteIndisponible`, l'ecran dit « Les notifications ne sont pas encore
/// disponibles », sans « Reessayer » et sans faux etat vide ; la cloche reste
/// sans point. La liste, le vide et l'echec ne se voient qu'en simulation.
/// Pas de route de detail (mapping, ligne 9) : une notification ouvre sa
/// destination interne, deja validee par le port, ou rien.
class NotificationsPage extends ConsumerWidget {
  /// Cree la page.
  const NotificationsPage({super.key, this.onRetour});

  /// Le retour ; par defaut, l'Accueil du tuteur. L'eleve adulte revient a
  /// son propre Accueil (EA-7), sans fork de la page.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationTuteur>> valeur = ref.watch(
      notificationsTuteurProvider,
    );
    return PageShell(
      titre: t.notifications.titre,
      onRetour: onRetour ?? () => GoRouter.of(context).go(Routes.tuteurAccueil),
      child: ColonneHistorique(
        child: valeur.error is CapaciteIndisponible
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.notifications.indisponibleTitre,
                phrase: t.notifications.indisponiblePhrase,
                dependance: (valeur.error! as CapaciteIndisponible).dependance,
              )
            : BlocAsynchrone<List<NotificationTuteur>>(
                valeur: valeur,
                squelette: const Skeleton.liste(lignes: 4),
                onReessayer: () => ref.invalidate(notificationsTuteurProvider),
                vide: EtatSysteme(
                  nature: NatureEtat.aucunResultat,
                  titre: t.notifications.videTitre,
                  phrase: t.notifications.videPhrase,
                ),
                construire: (List<NotificationTuteur> liste) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CarteLignes(
                      lignes: <Widget>[
                        for (final NotificationTuteur n in liste)
                          LigneNotification(
                            key: ValueKey<String>('notification-${n.id}'),
                            notification: n,
                            onPress: switch (n.destination) {
                              final String chemin => () => GoRouter.of(
                                context,
                              ).go(chemin),
                              null => null,
                            },
                          ),
                      ],
                    ),
                    Ecart.vMd,
                    NoteHistorique(t.historique.fuseauListe),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Les notifications, la plus recente d'abord (tri du port, jamais refait).
final FutureProvider<List<NotificationTuteur>> notificationsTuteurProvider =
    FutureProvider<List<NotificationTuteur>>(
      (Ref ref) => ref.watch(portNotificationsProvider).liste(),
    );

/// Une ligne de notification : date et heure a gauche, filet vertical, titre,
/// chevron quand elle mene quelque part. Sans destination, la ligne n'est pas
/// une cible (aucun chevron, aucun geste).
class LigneNotification extends StatelessWidget {
  /// Cree une ligne.
  const LigneNotification({
    required this.notification,
    required this.onPress,
    super.key,
  });

  /// La notification.
  final NotificationTuteur notification;

  /// L'ouverture de sa destination, ou `null`.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final DateTime quand = notification.date.toLocal();
    final String semantique = t.notifications.ligne(
      titre: notification.titre,
      date: dateLongueHistorique(quand),
      heure: heureMinute(quand),
    );
    if (onPress == null) {
      return Semantics(
        label: semantique,
        excludeSemantics: true,
        child: _contenu(context, null),
      );
    }
    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: semantique,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression? etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime quand = notification.date.toLocal();
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool actif = etat != null && (etat.survole || etat.presse);
    return ColoredBox(
      color: actif
          ? Color.alphaBlend(
              palette.calqueInteraction(presse: etat.presse),
              palette.surfaceRaised.background,
            )
          : palette.surfaceRaised.background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (BuildContext _, BoxConstraints contraintes) => Row(
                children: <Widget>[
                  // Largeur proportionnelle et commune : les filets verticaux
                  // s'alignent d'une ligne a l'autre, comme dans l'Historique.
                  SizedBox(
                    width:
                        contraintes.maxWidth *
                        (contraintes.maxWidth >= AppPage.largeurDialogue
                            ? 0.3
                            : 0.38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(dateCourte(quand), style: fort),
                        Ecart.vXs,
                        Text(
                          heureMinute(quand),
                          style: AppTypography.tabulaire(doux),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.section,
                    child: VerticalDivider(
                      width: AppSpacing.xxl,
                      thickness: palette.contourCarte.asBorderSide().width,
                      color: palette.contourCarte.asBorderSide().color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      notification.titre,
                      style: palette.inkStrong.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                  ),
                  if (onPress != null) ...<Widget>[
                    Ecart.hXs,
                    IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                      child: Icon(AppIcons.chevron.repos),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
