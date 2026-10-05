import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_agrandi.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_notifications.dart';
import '../../core/communications/modeles_communication.dart'
    show IndicateurAttention;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_annonces/port_annonces.dart';
import '../suivi_foyer/composants_historique.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'detail_notification.dart';

/// Le centre de notifications partage (`NotificationCenter`, spec
/// Communications V1, sections 13.1 et 18 ; COM-ANN-1).
///
/// **Une seule page pour tous les roles** : la cloche de chaque coquille
/// l'ouvre sous son prefixe (`/tuteur`, `/enseignant`, `/controleur`,
/// `/admin`, `Routes.notificationsPour`), chacune avec son propre retour
/// ([onRetour]). Jamais un second centre ; l'eleve adulte la reutilise aussi
/// (EA-7). Ce que la page montre vient du port, deja choisi pour la personne
/// connectee : aucun role n'est lu ici.
///
/// Composition :
///
/// - les filtres « Toutes », « Non lues », « Mentions », « Action requise »
///   (`SelecteurSection`, quatre sections : controle segmente, tout visible) ;
/// - UNE carte a filets, une ligne par notification : date a gauche, titre,
///   type, « Non lue » et le niveau en toutes lettres (`BadgeNonLu`) ; une
///   urgence non lue passe en tete (`lib/CLAUDE.md`), le reste garde l'ordre
///   du port ;
/// - **ordinateur** (au moins `AppGabarit.seuilEtendu` de large recus) :
///   la liste et le detail cote a cote, dans la coquille du role ;
/// - **telephone et tablette etroite** : une surface a la fois. Une annonce
///   de Classe ou une notification sans destination s'ouvre en detail (le
///   retour ramene a la liste) ; une notification a destination l'ouvre
///   directement. Aucune ligne n'est inerte (revue COM-R, R-06).
///
/// Une notification d'annonce ouvre l'annonce, puis sa Classe (R-COM-12).
/// Ouvrir une notification enregistre sa lecture si le port le sait
/// (`PortLectureNotifications`) ; un echec la garde non lue et le dit.
///
/// **Aucune source n'existe (DB-CPT-04)** : le port de production rend
/// `CapaciteIndisponible`, l'ecran dit « Les notifications ne sont pas encore
/// disponibles », sans « Reessayer » et sans faux etat vide ; la cloche reste
/// sans point. La liste, les filtres, le vide et l'echec ne se voient qu'en
/// simulation ou en demonstration.
class NotificationsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const NotificationsPage({super.key, this.onRetour});

  /// Le retour ; par defaut, l'Accueil du tuteur. Chaque role passe le sien
  /// (racine du role), l'eleve adulte revient a son propre Accueil (EA-7).
  final VoidCallback? onRetour;

  /// La cle du selecteur de filtres, pour les tests.
  static const ValueKey<String> cleFiltres = ValueKey<String>(
    'notifications-filtres',
  );

  /// La cle de la colonne de detail (ordinateur), pour les tests.
  static const ValueKey<String> cleDetail = ValueKey<String>(
    'notifications-detail',
  );

  /// La cle de la liste, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>(
    'notifications-liste',
  );

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

/// Les filtres du centre (spec section 13.1).
enum FiltreNotifications {
  /// Toutes les notifications.
  toutes,

  /// Celles que la personne n'a pas lues.
  nonLues,

  /// Celles qui la mentionnent.
  mentions,

  /// Celles qui attendent une action (action requise ou urgent).
  actionRequise;

  /// Vrai si [n] passe ce filtre.
  bool retient(NotificationTuteur n) => switch (this) {
    FiltreNotifications.toutes => true,
    FiltreNotifications.nonLues => !n.lue,
    FiltreNotifications.mentions => n.mention,
    FiltreNotifications.actionRequise => n.demandeAction,
  };

  /// Le libelle du filtre.
  String get libelle {
    final f = t.notifications.filtres;
    return switch (this) {
      FiltreNotifications.toutes => f.toutes,
      FiltreNotifications.nonLues => f.nonLues,
      FiltreNotifications.mentions => f.mentions,
      FiltreNotifications.actionRequise => f.actionRequise,
    };
  }
}

/// L'ordre d'affichage : les urgences non lues en tete, le reste dans
/// l'ordre du port (le plus recent d'abord), jamais retrie autrement.
List<NotificationTuteur> ordreNotifications(List<NotificationTuteur> liste) {
  bool enTete(NotificationTuteur n) =>
      !n.lue && n.niveau == NiveauAttention.urgent;
  return <NotificationTuteur>[
    ...liste.where(enTete),
    ...liste.where((NotificationTuteur n) => !enTete(n)),
  ];
}

/// Vrai si la largeur recue tient la liste et le detail cote a cote.
bool listeEtDetail(double largeur) => largeur >= AppGabarit.seuilEtendu;

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  FiltreNotifications _filtre = FiltreNotifications.toutes;

  /// La notification ouverte en detail, par son identifiant.
  String? _selection;

  /// Vrai quand la derniere mise en page tenait la liste et le detail cote a
  /// cote. Lu au toucher seulement (retour, ouverture), jamais pour peindre.
  bool _deuxPanneaux = false;

  /// Le retour local d'une lecture non confirmee.
  String? _retour;

  bool get _detailSeul => _selection != null && !_deuxPanneaux;

  void _retourPage() {
    if (_detailSeul) {
      setState(() => _selection = null);
      return;
    }
    final VoidCallback? retour = widget.onRetour;
    if (retour != null) {
      retour();
    } else {
      GoRouter.of(context).go(Routes.tuteurAccueil);
    }
  }

  /// Vrai si la notification s'ouvre en detail sur telephone : une
  /// annonce, ou toute notification sans destination. Le detail dit au
  /// moins le titre, la date, le type et le niveau : aucune ligne n'est
  /// inerte (revue COM-R, R-06).
  static bool _aUnDetail(NotificationTuteur n) =>
      n.annonceId != null || n.destination == null;

  /// L'action d'une ligne : son detail, ou sa destination. Toute ligne est
  /// une cible (R-06).
  VoidCallback _actionLigne(NotificationTuteur n, {required bool deux}) {
    final String? destination = n.destination;
    if (deux || _aUnDetail(n) || destination == null) {
      return () {
        unawaited(_marquerLue(n));
        setState(() => _selection = n.id);
      };
    }
    return () {
      unawaited(_marquerLue(n));
      GoRouter.of(context).go(destination);
    };
  }

  /// Enregistre la lecture de [n] (et de son annonce), puis relit la liste.
  /// Rien n'est suppose : sans port de lecture, rien ne change ; un echec
  /// garde la notification non lue et le dit.
  ///
  /// Les deux lectures sont independantes : une lecture de notification
  /// enregistree relit la liste meme si celle de l'annonce echoue ensuite,
  /// et seule cette derniere est alors dite non confirmee.
  Future<void> _marquerLue(NotificationTuteur n) async {
    if (n.lue) return;
    final PortNotifications port = ref.read(portNotificationsProvider);
    final PortAnnonces annonces = ref.read(portAnnoncesProvider);
    final String? annonceId = n.annonceId;
    try {
      if (port case final PortLectureNotifications lecture) {
        await lecture.marquerLue(n.id);
      }
    } on CapaciteIndisponible {
      // Pas de source : rien a enregistrer.
      return;
    } on Object {
      if (!mounted) return;
      setState(() => _retour = t.notifications.lectureNonConfirmee);
      return;
    }
    if (!mounted) return;
    ref.invalidate(notificationsTuteurProvider);
    bool annonceConfirmee = true;
    if (annonceId != null) {
      try {
        await annonces.marquerLue(annonceId);
      } on CapaciteIndisponible {
        // Aucune source d'annonces : rien n'est enregistre ni affirme.
      } on Object {
        annonceConfirmee = false;
      }
      if (!mounted) return;
      ref.invalidate(annonceProvider(annonceId));
    }
    setState(
      () => _retour = annonceConfirmee
          ? null
          : t.notifications.lectureNonConfirmee,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<NotificationTuteur>> valeur = ref.watch(
      notificationsTuteurProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PopScope(
      // Telephone, detail ouvert : le retour systeme ramene a la liste.
      canPop: !_detailSeul,
      onPopInvokedWithResult: (bool sorti, Object? _) {
        if (!sorti && _detailSeul) setState(() => _selection = null);
      },
      child: PageShell(
        titre: t.notifications.titre,
        onRetour: _retourPage,
        child: valeur.error is CapaciteIndisponible
            ? ColonneHistorique(
                child: EtatSysteme(
                  nature: NatureEtat.indisponible,
                  titre: t.notifications.indisponibleTitre,
                  phrase: t.notifications.indisponiblePhrase,
                  dependance:
                      (valeur.error! as CapaciteIndisponible).dependance,
                ),
              )
            : BlocAsynchrone<List<NotificationTuteur>>(
                valeur: valeur,
                squelette: const ColonneHistorique(
                  child: Skeleton.liste(lignes: 4),
                ),
                onReessayer: () => ref.invalidate(notificationsTuteurProvider),
                // Hors ligne (suivi), l'echec se dit comme tel, avec
                // « Réessayer » (revue COM-R, R-24).
                erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
                    ? ColonneHistorique(
                        child: VueEtatCommunication(
                          etat: EtatCommunication.horsLigne,
                          onReessayer: reessayer,
                        ),
                      )
                    : null,
                vide: ColonneHistorique(
                  child: EtatSysteme(
                    nature: NatureEtat.aucunResultat,
                    titre: t.notifications.videTitre,
                    phrase: t.notifications.videPhrase,
                  ),
                ),
                construire: (List<NotificationTuteur> liste) => LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final bool deux = listeEtDetail(c.maxWidth);
                    _deuxPanneaux = deux;
                    return _centre(context, ordreNotifications(liste), deux);
                  },
                ),
              ),
      ),
    );
  }

  Widget _centre(
    BuildContext context,
    List<NotificationTuteur> liste,
    bool deux,
  ) {
    final NotificationTuteur? choisie = liste
        .where((NotificationTuteur n) => n.id == _selection)
        .firstOrNull;
    final String? retour = _retour;

    // Telephone, detail ouvert : une surface a la fois.
    if (!deux && choisie != null) {
      return ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _detail(context, choisie),
            if (retour != null) ...<Widget>[
              Ecart.vSm,
              LocalFeedback(message: retour),
            ],
          ],
        ),
      );
    }

    final List<NotificationTuteur> retenues = liste
        .where(_filtre.retient)
        .toList();
    final Widget filtres = SelecteurSection<FiltreNotifications>(
      key: NotificationsPage.cleFiltres,
      libelle: t.notifications.filtres.libelle,
      sections: <Segment<FiltreNotifications>>[
        for (final FiltreNotifications f in FiltreNotifications.values)
          Segment<FiltreNotifications>(valeur: f, libelle: f.libelle),
      ],
      valeur: _filtre,
      onChange: (FiltreNotifications f) => setState(() => _filtre = f),
    );
    final Widget liste0 = KeyedSubtree(
      key: NotificationsPage.cleListe,
      child: retenues.isEmpty
          ? EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.notifications.filtreVideTitre,
              phrase: t.notifications.filtreVidePhrase,
              libelleAction: t.notifications.voirToutes,
              onAction: () =>
                  setState(() => _filtre = FiltreNotifications.toutes),
            )
          : CarteLignes(
              lignes: <Widget>[
                for (final NotificationTuteur n in retenues)
                  LigneNotification(
                    key: ValueKey<String>('notification-${n.id}'),
                    notification: n,
                    selectionnee: deux && n.id == _selection,
                    onPress: _actionLigne(n, deux: deux),
                  ),
              ],
            ),
    );
    final Widget pied = NoteHistorique(t.historique.fuseauListe);

    if (!deux) {
      return ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            filtres,
            Ecart.vLg,
            liste0,
            if (retour != null) ...<Widget>[
              Ecart.vSm,
              LocalFeedback(message: retour),
            ],
            Ecart.vMd,
            pied,
          ],
        ),
      );
    }

    // Ordinateur : la liste et le detail, cote a cote (spec section 18).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(alignment: AlignmentDirectional.centerStart, child: filtres),
        Ecart.vLg,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  liste0,
                  if (retour != null) ...<Widget>[
                    Ecart.vSm,
                    LocalFeedback(message: retour),
                  ],
                  Ecart.vMd,
                  pied,
                ],
              ),
            ),
            Ecart.hXxl,
            Expanded(
              flex: 2,
              child: KeyedSubtree(
                key: NotificationsPage.cleDetail,
                child: choisie == null
                    ? AppCard(
                        child: EtatSysteme(
                          nature: NatureEtat.aucunResultat,
                          titre: t.notifications.detail.choisirTitre,
                          phrase: t.notifications.detail.choisirPhrase,
                        ),
                      )
                    : _detail(context, choisie),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detail(BuildContext context, NotificationTuteur n) {
    final String? destination = n.destination;
    return DetailNotification(
      key: ValueKey<String>('detail-${n.id}'),
      notification: n,
      onOuvrir: destination == null
          ? null
          : () => GoRouter.of(context).go(destination),
    );
  }
}

/// Les notifications, dans l'ordre du port (la plus recente d'abord).
final FutureProvider<List<NotificationTuteur>> notificationsTuteurProvider =
    FutureProvider<List<NotificationTuteur>>(
      (Ref ref) => ref.watch(portNotificationsProvider).liste(),
    );

/// Une ligne de notification : date et heure a gauche, filet vertical, titre,
/// puis le type, « Non lue » et le niveau en toutes lettres ; chevron quand
/// elle mene quelque part. Sans action, la ligne n'est pas une cible (aucun
/// chevron, aucun geste).
class LigneNotification extends StatelessWidget {
  /// Cree une ligne.
  const LigneNotification({
    required this.notification,
    required this.onPress,
    super.key,
    this.selectionnee = false,
  });

  /// La notification.
  final NotificationTuteur notification;

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
  static String phraseSemantique(NotificationTuteur notification) {
    final DateTime quand = notification.date.toLocal();
    final String? badge = BadgeNonLu.phraseSemantique(
      indicateurNotification(notification),
    );
    return <String>[
      t.notifications.ligne(
        titre: notification.titre,
        date: dateLongueHistorique(quand),
        heure: heureMinute(quand),
      ),
      if (notification.type != TypeNotification.autre)
        libelleTypeNotification(notification.type),
      if (!notification.lue) t.notifications.nonLueSemantique,
      // Rien a signaler : le niveau « Information » est dit quand meme, en
      // toutes lettres (spec section 13.1 : quatre niveaux, chacun dit).
      badge ?? BadgeNonLu.libelleNiveau(NiveauAttention.information),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final String semantique = phraseSemantique(notification);
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
    final DateTime quand = notification.date.toLocal();
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool actif = etat != null && (etat.survole || etat.presse);
    final IndicateurAttention indicateur = indicateurNotification(notification);
    final bool avecType = notification.type != TypeNotification.autre;
    final bool nonLue = !notification.lue;
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
                    Text(dateCourte(quand), style: fort),
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
                    if (avecType || nonLue) ...<Widget>[
                      Ecart.vXs,
                      TexteSansCoupure(
                        <String>[
                          if (avecType)
                            libelleTypeNotification(notification.type),
                          if (nonLue) t.notifications.nonLue,
                        ].join(' · '),
                        style: doux,
                      ),
                    ],
                    if (indicateur.estVisible) ...<Widget>[
                      Ecart.vSm,
                      BadgeNonLu(indicateur: indicateur),
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
