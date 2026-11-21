import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_agrandi.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/port_notifications.dart';
import '../../core/communications/modeles_communication.dart'
    show IndicateurAttention;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../suivi_foyer/composants_historique.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'cloche/contenu_cloche.dart';
import 'detail_notification.dart';
import 'notifications_supabase_provider.dart';
import 'reglages_push.dart';

/// Le centre de notifications partage, page complete de la cloche
/// (« Voir tout »).
///
/// **CLOCHE-C, etape 2 (directeur, 21/11/2026, DECISION-ANNONCES-NOTIFS
/// regles 1 et 10)** : la page suit la grammaire du panneau et de la
/// feuille de la cloche, style C : les memes trois onglets avec leur
/// nombre, les memes lignes, le detail sur place, la croix des annonces avec
/// « Annuler », « Tout marquer comme lu », 20 a la fois. Largeur de lecture
/// de 800 au plus sur ordinateur, jamais une colonne etiree. Les sections
/// « A faire / Nouvelles / Plus anciennes », le regroupement et « Ecarter »
/// de NOTIFS-L6 sont remplaces par cette grammaire unique.
///
/// **Une seule page pour tous les roles** : la cloche de chaque coquille y
/// mene sous son prefixe (`Routes.notificationsPour`), chacune avec son
/// retour ([onRetour]). Ce que la page montre vient des ports, deja choisis
/// pour la personne connectee : aucun role n'est lu ici.
class NotificationsPage extends ConsumerWidget {
  /// Cree la page.
  const NotificationsPage({super.key, this.onRetour});

  /// Le retour ; par defaut, l'Accueil du tuteur. Chaque role passe le sien.
  final VoidCallback? onRetour;

  /// La cle du lien des Reglages des notifications sur l'appareil (PUSH-1).
  static const ValueKey<String> cleReglagesPush = ValueKey<String>(
    'notifications-reglages-push',
  );

  /// La cle de la liste, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>(
    'notifications-liste',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter routeur = GoRouter.of(context);
    return PageShell(
      // D-FUS-3 : seul le bandeau hors ligne des Communications.
      bandeauHorsLigne: const BandeauHorsLigneCommunication(),
      titre: t.notifications.titre,
      onRetour: onRetour ?? () => routeur.go(Routes.tuteurAccueil),
      child: ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // PUSH-1 (07/11/2026) : les Reglages des notifications sur
            // l'appareil, atteints par tous les roles.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: cleReglagesPush,
                libelle: t.push1.reglages.lien,
                icone: AppIcons.notifications,
                alignerEnDebut: true,
                onPress: () => unawaited(ouvrirReglagesPush(context)),
              ),
            ),
            Ecart.vMd,
            KeyedSubtree(
              key: cleListe,
              child: ContenuCloche(
                forme: FormeCloche.page,
                naviguer: (String chemin) {
                  // BUREAU-NAV : dans le bureau, l'objet s'empile sur la
                  // page ; ailleurs, il la remplace.
                  if (chemin.startsWith('${Routes.admin}/')) {
                    unawaited(routeur.push<void>(chemin));
                  } else {
                    routeur.go(chemin);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les notifications, dans l'ordre du port (la plus recente d'abord).
///
/// Une seule lecture pour la page et pour le point de la cloche de chaque
/// coquille (`nonLuesProvider`), relue par la veille de fraicheur a chaque
/// changement de la table `notifications` (fiche du 27/10, lignes 12 et 14).
/// Aucune relance automatique (Riverpod 3) : la cloche regarde cette liste
/// sur toutes les pages, et une relance qui insiste depuis chaque ecran n'est
/// pas voulue ; une capacite absente ne revient pas en insistant. La liste
/// se relit par la veille (retour du reseau, canal rejoint, table changee),
/// par « Reessayer » et apres une lecture. Pendant une relance automatique,
/// « Reessayer » aurait de plus ete inerte (`BlocAsynchrone` le tient pour
/// « en cours »).
final FutureProvider<List<NotificationTuteur>> notificationsTuteurProvider =
    FutureProvider<List<NotificationTuteur>>(
      (Ref ref) => ref.watch(notificationsPagePortProvider).liste(),
      retry: (int _, Object _) => null,
    );

/// L'horloge du centre de notifications : l'instant de reference de la date
/// compacte des lignes (sans l'annee en cours, N-10). Surchargee par les
/// tests et les captures, qui ne dependent plus de l'annee courante (revue
/// COM-R-3, constat 4).
final Provider<DateTime Function()> horlogeNotificationsProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// Une ligne de notification : date et heure a gauche, filet vertical, titre,
/// puis le type, « Non lue » et le niveau en toutes lettres ; chevron quand
/// elle mene quelque part. Sans action, la ligne n'est pas une cible (aucun
/// chevron, aucun geste).
class LigneNotification extends StatelessWidget {
  /// Cree une ligne.
  const LigneNotification({
    required this.notification,
    required this.onPress,
    required this.maintenant,
    super.key,
    this.selectionnee = false,
    this.nombre = 1,
  });

  /// La notification.
  final NotificationTuteur notification;

  /// NOTIFS-L6 : le nombre de repetitions du meme evenement le meme jour
  /// que la ligne represente (« 3 fois »). 1 : une seule.
  final int nombre;

  /// L'instant de reference de la date compacte (sans l'annee en cours),
  /// lu par la page dans [horlogeNotificationsProvider] : jamais l'heure de
  /// l'appareil en dur.
  final DateTime maintenant;

  /// L'ouverture de la notification (detail ou destination), ou `null`.
  final VoidCallback? onPress;

  /// Vrai quand son detail est ouvert a cote (ordinateur).
  final bool selectionnee;

  /// La cle de la ligne dont la date est au-dessus du titre, pour les tests.
  static const ValueKey<String> cleDateAuDessus = ValueKey<String>(
    'notification-date-au-dessus',
  );

  /// Vrai a texte agrandi (1,5 et plus) : la date passe au-dessus du titre.
  static bool dateAuDessus(BuildContext context) =>
      SeuilsTexteAgrandi.texteAgrandi(context);

  /// La part de la largeur que prend la colonne de la date : 30 % des la
  /// largeur d'un dialogue, un quart en dessous (telephone, R-09).
  static double largeurDateNotification(double largeur) =>
      largeur >= AppPage.largeurDialogue ? 0.3 : 0.25;

  /// La phrase lue par le lecteur d'ecran : titre, date, type, non lue,
  /// niveau (« Information » compris) et mention.
  static String phraseSemantique(
    NotificationTuteur notification, {
    int nombre = 1,
  }) {
    final DateTime quand = chezMoi(notification.date);
    final IndicateurAttention? geste = indicateurLigne(notification);
    final String? badge = geste == null
        ? null
        : BadgeNonLu.phraseSemantique(
            geste,
            libelleAction: libelleGeste(notification),
          );
    return <String>[
      t.notifications.ligne(
        titre: notification.titre,
        date: dateLongueHistorique(quand),
        heure: heureMinute(quand),
      ),
      if (notification.type != TypeNotification.autre)
        libelleTypeNotification(notification.type),
      if (nombre > 1) t.notifications.repetitions(n: nombre),
      if (!notification.lue) t.notifications.nonLueSemantique,
      // Un seul signe (reprise du pilote, 02/11) : le geste attendu sur une
      // ligne « A faire » ; « Non lue » seul sur une non lue, sans « A
      // lire » qui le repetait ; « Information » sur une lue, dit en toutes
      // lettres (spec section 13.1 : chaque niveau est dit).
      if (badge != null)
        badge
      else if (notification.lue)
        BadgeNonLu.libelleNiveau(NiveauAttention.information),
    ].join(', ');
  }

  /// Reprise de NOTIFS-L6 (pilote, 02/11/2026) : un seul signe par ligne.
  /// Le badge n'existe que sur une ligne « A faire », au niveau « action
  /// requise » (ou « urgent ») ; ailleurs, le mot « Non lue » suffit.
  static IndicateurAttention? indicateurLigne(NotificationTuteur n) {
    if (!n.aFaire) return null;
    return IndicateurAttention(
      niveau: n.niveau.estAuMoins(NiveauAttention.actionRequise)
          ? n.niveau
          : NiveauAttention.actionRequise,
    );
  }

  /// Le mot du geste attendu d'une ligne « A faire », selon l'evenement ;
  /// « A faire » quand l'evenement n'est pas connu (ports de demonstration).
  static String libelleGeste(NotificationTuteur n) {
    final mots = t.notifications;
    final gestes = t.push1.gestes;
    // La portee ne remonte pas jusqu'ici : la destination la dit (la
    // direction et le comptable ouvrent leurs propres pages).
    final String destination = n.destination ?? '';
    final bool gestion =
        destination.startsWith('/admin') ||
        destination.startsWith('/comptable');
    return switch (n.evenement) {
      'paiement_relance' || 'acces_suspendu_paiement' => mots.gesteRecharger,
      // PUSH-1 (07/11/2026) : les gestes attendus, par role.
      'paiement_echoue' => gestion ? gestes.voirPaiement : mots.gesteRecharger,
      'admission_recue' ||
      'candidature_enseignant_a_examiner' ||
      'demande_horaire_recue' => gestes.examiner,
      'piece_identite_deposee' => gestes.verifierPiece,
      'signalement_eleve_recu' => gestes.traiterSignalement,
      'suppression_compte_demandee' => gestes.traiterDemande,
      'remplacement_personne_en_salle' ||
      'titulaire_en_retard' => gestes.trouverRemplacant,
      'versement_coordonnees_a_valider' => gestes.validerCoordonnees,
      'remboursement_echec' => gestes.voirRemboursement,
      'cahier_en_retard' => gestes.remplirCahier,
      'remplacement_avertissement' => gestes.rejoindreSalle,
      'remplacement_propose' ||
      'remplacement_pre_alerte' => mots.gestePrendreSeance,
      'demande_presentation' ||
      // MESSAGERIE-PUSH (14/11/2026) : repondre au candidat.
      'message_candidat_recu' => mots.gesteRepondre,
      'controle_mission_attribuee' => mots.gesteObserver,
      'litige_ouvert' => mots.gesteTraiterContestation,
      _ => mots.sectionAFaire,
    };
  }

  @override
  Widget build(BuildContext context) {
    final String semantique = phraseSemantique(notification, nombre: nombre);
    if (onPress == null) {
      return Semantics(
        label: semantique,
        excludeSemantics: true,
        child: _contenu(context, null),
      );
    }
    return Semantics(
      selected: selectionnee,
      child: Pressable.selon(
        onPress: onPress,
        libelleSemantique: semantique,
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiSm,
        constructeur: _contenu,
      ),
    );
  }

  Widget _contenu(BuildContext context, EtatPression? etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime quand = chezMoi(notification.date);
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool actif = etat != null && (etat.survole || etat.presse);
    final IndicateurAttention? indicateur = indicateurLigne(notification);
    final bool avecType = notification.type != TypeNotification.autre;
    final bool nonLue = !notification.lue;
    final bool repetee = nombre > 1;
    return ColoredBox(
      color: actif || selectionnee
          ? Color.alphaBlend(
              palette.calqueInteraction(presse: etat?.presse ?? false),
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
              builder: (BuildContext _, BoxConstraints contraintes) {
                final Widget date = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // N-10 : sans l'annee en cours, la date tient sur une
                    // ligne (« 4 oct. », plus « 4 oct. / 2026 »).
                    Text(dateCompacte(quand, maintenant), style: fort),
                    Ecart.vXs,
                    Text(
                      heureMinute(quand),
                      style: AppTypography.tabulaire(doux),
                    ),
                  ],
                );
                final Widget corps = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Un mot trop long se reduit, jamais coupe (R-09).
                    TexteSansCoupure(
                      notification.titre,
                      // Non lue : le titre au rang du nom de carte, plus
                      // gras ; le mot « Non lue » le dit aussi.
                      style: nonLue
                          ? fort
                          : palette.inkStrong.applyTo(
                              textes.bodyMedium ?? const TextStyle(),
                            ),
                    ),
                    if (avecType || nonLue || repetee) ...<Widget>[
                      Ecart.vXs,
                      TexteSansCoupure(
                        <String>[
                          if (avecType)
                            libelleTypeNotification(notification.type),
                          if (repetee) t.notifications.repetitions(n: nombre),
                          if (nonLue) t.notifications.nonLue,
                        ].join(' · '),
                        style: doux,
                      ),
                    ],
                    if (indicateur != null) ...<Widget>[
                      Ecart.vSm,
                      BadgeNonLu(
                        indicateur: indicateur,
                        libelleAction: libelleGeste(notification),
                      ),
                    ],
                  ],
                );
                final Widget? chevron = onPress == null
                    ? null
                    : IconTheme(
                        data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                        child: Icon(AppIcons.chevron.repos),
                      );
                // Texte agrandi (1,5 et plus) : la date passe au-dessus du
                // titre, qui garde toute la largeur (revue COM-R, R-09).
                if (dateAuDessus(context)) {
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          key: LigneNotification.cleDateAuDessus,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[date, Ecart.vSm, corps],
                        ),
                      ),
                      if (chevron != null) ...<Widget>[Ecart.hXs, chevron],
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    // Largeur proportionnelle et commune : les filets
                    // verticaux s'alignent d'une ligne a l'autre, comme dans
                    // l'Historique. Un quart sur telephone (R-09).
                    SizedBox(
                      width:
                          contraintes.maxWidth *
                          largeurDateNotification(contraintes.maxWidth),
                      child: date,
                    ),
                    SizedBox(
                      height: AppSpacing.section,
                      child: VerticalDivider(
                        width: AppSpacing.xxl,
                        thickness: palette.contourCarte.asBorderSide().width,
                        color: palette.contourCarte.asBorderSide().color,
                      ),
                    ),
                    Expanded(child: corps),
                    if (chevron != null) ...<Widget>[Ecart.hXs, chevron],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
