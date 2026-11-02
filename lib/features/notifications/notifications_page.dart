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
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart' show Segment;
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_annonces/port_annonces.dart';
import '../suivi_foyer/composants_historique.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'detail_notification.dart';
import 'notifications_supabase_provider.dart';

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

  /// La cle de la section « A faire », pour les tests.
  static const ValueKey<String> cleAFaire = ValueKey<String>(
    'notifications-a-faire',
  );

  /// La cle de la section « Nouvelles », pour les tests.
  static const ValueKey<String> cleNouvelles = ValueKey<String>(
    'notifications-nouvelles',
  );

  /// La cle du titre repliable « Plus anciennes », pour les tests.
  static const ValueKey<String> cleAnciennes = ValueKey<String>(
    'notifications-anciennes',
  );

  /// La cle de « Voir plus », pour les tests.
  static const ValueKey<String> cleVoirPlus = ValueKey<String>(
    'notifications-voir-plus',
  );

  /// La cle de « Tout marquer comme lu », pour les tests.
  static const ValueKey<String> cleToutLire = ValueKey<String>(
    'notifications-tout-lire',
  );

  /// La cle de la liste, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>(
    'notifications-liste',
  );

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

/// Les filtres du centre : un seul selecteur (NOTIFS-L6, pilote, 02/11/2026).
///
/// « Mentions » est retire : aucune source ne le remplit. « Action requise »
/// devient « A faire », qui lit le geste en attente du serveur.
enum FiltreNotifications {
  /// Les trois sections.
  toutes,

  /// « A faire » seulement.
  aFaire,

  /// « Nouvelles » seulement : les non lues.
  nonLues;

  /// Le libelle du filtre.
  String get libelle {
    final f = t.notifications.filtres;
    return switch (this) {
      FiltreNotifications.toutes => f.toutes,
      FiltreNotifications.aFaire => t.notifications.sectionAFaire,
      FiltreNotifications.nonLues => f.nonLues,
    };
  }
}

/// Une ligne de la page : une notification, ou les repetitions d'un meme
/// evenement le meme jour (NOTIFS-L6, regle 4), la plus recente en tete.
@immutable
class GroupeNotifications {
  /// Cree un groupe, [membres] du plus recent au plus ancien.
  const GroupeNotifications(this.membres);

  /// Les notifications du groupe, la plus recente d'abord.
  final List<NotificationTuteur> membres;

  /// Celle qui se montre et s'ouvre.
  NotificationTuteur get tete => membres.first;

  /// Le nombre de repetitions.
  int get nombre => membres.length;
}

/// Les trois sections de la page (NOTIFS-L6) : « A faire » (un geste en
/// attente, lue ou non, jamais effacee par la seule ouverture), « Nouvelles »
/// (non lues), « Plus anciennes » (lues).
@immutable
class SectionsNotifications {
  /// Cree les sections.
  const SectionsNotifications({
    required this.aFaire,
    required this.nouvelles,
    required this.anciennes,
  });

  /// Repartit [toutes] (deja dedoublonnees) dans les trois sections.
  factory SectionsNotifications.depuis(List<NotificationTuteur> toutes) {
    List<NotificationTuteur> trier(Iterable<NotificationTuteur> l) => l.toList()
      ..sort(
        (NotificationTuteur a, NotificationTuteur b) =>
            b.date.compareTo(a.date),
      );
    final List<NotificationTuteur> aFaire = trier(
      toutes.where((NotificationTuteur n) => n.aFaire),
    );
    // Les urgences en tete de « A faire » (`lib/CLAUDE.md`).
    final List<NotificationTuteur> urgentes = <NotificationTuteur>[
      ...aFaire.where(
        (NotificationTuteur n) => n.niveau == NiveauAttention.urgent,
      ),
      ...aFaire.where(
        (NotificationTuteur n) => n.niveau != NiveauAttention.urgent,
      ),
    ];
    return SectionsNotifications(
      aFaire: regrouperNotifications(urgentes),
      nouvelles: regrouperNotifications(
        trier(toutes.where((NotificationTuteur n) => !n.aFaire && !n.lue)),
      ),
      anciennes: regrouperNotifications(
        trier(toutes.where((NotificationTuteur n) => !n.aFaire && n.lue)),
      ),
    );
  }

  /// « A faire ».
  final List<GroupeNotifications> aFaire;

  /// « Nouvelles ».
  final List<GroupeNotifications> nouvelles;

  /// « Plus anciennes ».
  final List<GroupeNotifications> anciennes;

  /// Vrai s'il n'y a rien du tout.
  bool get vide => aFaire.isEmpty && nouvelles.isEmpty && anciennes.isEmpty;
}

/// Regroupe les repetitions d'un meme evenement le meme jour (heure de
/// l'appareil) : meme [NotificationTuteur.cleRegroupement] et meme jour.
/// L'ordre est celui de la premiere apparition. Sans cle, jamais regroupee.
/// Ce n'est pas exactement « le meme objet » : les parametres ne portent
/// volontairement aucun identifiant (pilote, Q2).
List<GroupeNotifications> regrouperNotifications(
  List<NotificationTuteur> liste,
) {
  final Map<String, List<NotificationTuteur>> parCle =
      <String, List<NotificationTuteur>>{};
  for (final NotificationTuteur n in liste) {
    final String? cle = n.cleRegroupement;
    final DateTime jour = n.date.toLocal();
    final String cleLigne = cle == null
        ? 'seule|${n.id}'
        : '$cle|${jour.year}-${jour.month}-${jour.day}';
    (parCle[cleLigne] ??= <NotificationTuteur>[]).add(n);
  }
  return <GroupeNotifications>[
    for (final List<NotificationTuteur> membres in parCle.values)
      GroupeNotifications(List<NotificationTuteur>.unmodifiable(membres)),
  ];
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  FiltreNotifications _filtre = FiltreNotifications.toutes;

  /// La notification ouverte en detail (en page), par son identifiant.
  String? _selection;

  /// Le retour local d'une lecture ou d'un ecart non confirme.
  String? _retour;

  /// « Plus anciennes » : repliees par defaut quand une priorite est
  /// au-dessus (regle 3) ; ouvertes d'office quand il n'y a rien a faire ni
  /// de nouveau (la page ne montre pas qu'un titre replie). Nul : ce
  /// reglage par defaut ; sinon, le choix de la personne.
  bool? _anciennesOuvertes;

  /// Le nombre de lignes « Plus anciennes » montrees.
  int _anciennesMontrees = PortPagesNotifications.taillePage;

  /// Les lues lues en plus, page par page (« Voir plus »).
  final List<NotificationTuteur> _plus = <NotificationTuteur>[];

  /// Vrai quand le serveur n'a plus de lues plus anciennes.
  bool _finLues = false;

  /// Une page de lues en cours de lecture.
  bool _chargePlus = false;

  bool get _detailOuvert => _selection != null;

  // NOTIFS-L6 (regle 2) : ouvrir la page ne marque plus rien comme lu (la
  // fiche du 27/10, ligne 14, le faisait : « Non lues » et « Action requise »
  // etaient vides a l'arrivee). Une notification devient lue quand on
  // l'ouvre, ou par « Tout marquer comme lu ».

  /// Marque lues toutes les notifications non lues, si le port le sait
  /// (`PortLectureGroupeeNotifications`), puis relit la liste. Rien n'est
  /// suppose : un echec garde les notifications non lues et le dit.
  Future<void> _marquerToutesLues() async {
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    if (port is! PortLectureGroupeeNotifications) return;
    final PortLectureGroupeeNotifications groupee =
        port as PortLectureGroupeeNotifications;
    try {
      await groupee.marquerToutesLues();
    } on CapaciteIndisponible {
      return;
    } on Object {
      if (!mounted) return;
      setState(() => _retour = t.notifications.lectureNonConfirmee);
      return;
    }
    if (!mounted) return;
    ref.invalidate(notificationsTuteurProvider);
  }

  /// Ecarte une notification « A faire » (`PortEcartNotifications`), puis
  /// relit la liste ; un echec la garde et le dit.
  Future<void> _ecarter(GroupeNotifications g) async {
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    if (port is! PortEcartNotifications) return;
    final PortEcartNotifications ecart = port as PortEcartNotifications;
    try {
      for (final NotificationTuteur n in g.membres) {
        await ecart.ecarter(n.id);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _retour = t.notifications.ecartNonConfirme);
      return;
    }
    if (!mounted) return;
    setState(() => _retour = null);
    ref.invalidate(notificationsTuteurProvider);
  }

  void _retourPage() {
    if (_detailOuvert) {
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

  /// Vrai si la notification s'ouvre en detail, en page : une annonce, ou
  /// toute notification sans destination (regle du 01/11 : plus de detail a
  /// cote de la liste).
  static bool _aUnDetail(NotificationTuteur n) =>
      n.annonceId != null || n.destination == null;

  /// L'action d'une ligne : son detail en page, ou sa destination. Les
  /// repetitions regroupees sont toutes marquees lues.
  VoidCallback _actionLigne(GroupeNotifications g) {
    final NotificationTuteur n = g.tete;
    final String? destination = n.destination;
    void lire() {
      for (final NotificationTuteur m in g.membres) {
        unawaited(_marquerLue(m));
      }
    }

    if (_aUnDetail(n) || destination == null) {
      return () {
        lire();
        setState(() => _selection = n.id);
      };
    }
    return () {
      lire();
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
    final PortNotifications port = ref.read(notificationsPagePortProvider);
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

  /// « Voir plus » : 20 lignes « Plus anciennes » de plus ; quand toutes les
  /// lues deja lues sont montrees, la page suivante est demandee au serveur
  /// (`PortPagesNotifications`), jamais une lecture sans fin.
  Future<void> _voirPlus(
    SectionsNotifications sections,
    DateTime? avant,
  ) async {
    final int montrees = _anciennesMontrees;
    setState(() => _anciennesMontrees += PortPagesNotifications.taillePage);
    if (montrees + PortPagesNotifications.taillePage <=
            sections.anciennes.length ||
        _finLues ||
        avant == null) {
      return;
    }
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    if (port is! PortPagesNotifications) {
      setState(() => _finLues = true);
      return;
    }
    final PortPagesNotifications pages = port as PortPagesNotifications;
    setState(() => _chargePlus = true);
    try {
      final List<NotificationTuteur> lues = await pages.lues(avant: avant);
      if (!mounted) return;
      setState(() {
        _plus.addAll(lues);
        _finLues = lues.length < PortPagesNotifications.taillePage;
        _chargePlus = false;
        _retour = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _chargePlus = false;
        _anciennesMontrees = montrees;
        _retour = t.notifications.voirPlusErreur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<NotificationTuteur>> valeur = ref.watch(
      notificationsTuteurProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PopScope(
      // Detail ouvert : le retour systeme ramene a la liste.
      canPop: !_detailOuvert,
      onPopInvokedWithResult: (bool sorti, Object? _) {
        if (!sorti && _detailOuvert) setState(() => _selection = null);
      },
      child: PageShell(
        // D-FUS-3 : seul le bandeau hors ligne des Communications.
        bandeauHorsLigne: const BandeauHorsLigneCommunication(),
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
                construire: (List<NotificationTuteur> liste) =>
                    _centre(context, liste),
              ),
      ),
    );
  }

  Widget _centre(BuildContext context, List<NotificationTuteur> liste) {
    // La tete du port et les pages lues en plus, sans doublon.
    final Map<String, NotificationTuteur> parId = <String, NotificationTuteur>{
      for (final NotificationTuteur n in _plus) n.id: n,
      for (final NotificationTuteur n in liste) n.id: n,
    };
    final List<NotificationTuteur> toutes = parId.values.toList();
    final NotificationTuteur? choisie = toutes
        .where((NotificationTuteur n) => n.id == _selection)
        .firstOrNull;
    final String? retour = _retour;

    // Le detail, en page (plus de detail a cote de la liste).
    if (choisie != null) {
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

    final SectionsNotifications sections = SectionsNotifications.depuis(toutes);
    final DateTime maintenant = ref.watch(horlogeNotificationsProvider)();
    final PortNotifications port = ref.watch(notificationsPagePortProvider);
    final bool peutEcarter = port is PortEcartNotifications;
    final bool peutToutLire = port is PortLectureGroupeeNotifications;
    final DateTime? plusAncienneLue = toutes
        .where((NotificationTuteur n) => n.lue)
        .map((NotificationTuteur n) => n.date)
        .fold<DateTime?>(
          null,
          (DateTime? m, DateTime d) => m == null || d.isBefore(m) ? d : m,
        );
    final bool aSuiteServeur = port is PortPagesNotifications && !_finLues;
    final TextTheme textes = Theme.of(context).textTheme;

    Widget ligne(GroupeNotifications g, {bool ecartable = false}) {
      final Widget l = LigneNotification(
        key: ValueKey<String>('notification-${g.tete.id}'),
        notification: g.tete,
        nombre: g.nombre,
        maintenant: maintenant,
        onPress: _actionLigne(g),
      );
      if (!ecartable) return l;
      // LISTES-1 : le menu « ... » en bout de ligne porte « Ecarter ». Le
      // fond de la ligne court sous le menu : sans lui, le filet de la carte
      // changeait de teinte a l'aplomb du « ... » (capture R3, 1440).
      return ColoredBox(
        color: AppPalette.of(context).surfaceRaised.background,
        child: Row(
          children: <Widget>[
            Expanded(child: l),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: MenuActions(
                key: ValueKey<String>('notification-menu-${g.tete.id}'),
                points: true,
                objet: g.tete.titre,
                actions: <EntreeAction>[
                  EntreeAction(
                    libelle: t.notifications.ecarter,
                    onChoix: () => unawaited(_ecarter(g)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Le titre au debut, l'action au bord de fin ; a l'etroit (390, texte
    // agrandi), l'action passe dessous, toujours au bord de fin.
    Widget titreSection(String titre, {Widget? action}) {
      final Widget texte = Semantics(
        header: true,
        child: TexteSansCoupure(
          titre,
          style: textes.titleMedium ?? const TextStyle(),
        ),
      );
      if (action == null) return texte;
      return OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: AppSpacing.sm,
        children: <Widget>[texte, action],
      );
    }

    final bool anciennesOuvertes =
        _anciennesOuvertes ??
        (sections.aFaire.isEmpty && sections.nouvelles.isEmpty);
    final bool voirAFaire = _filtre != FiltreNotifications.nonLues;
    final bool voirNouvelles = _filtre != FiltreNotifications.aFaire;
    final bool voirAnciennes = _filtre == FiltreNotifications.toutes;
    final bool rienDansLeFiltre =
        (!voirAFaire || sections.aFaire.isEmpty) &&
        (!voirNouvelles || sections.nouvelles.isEmpty) &&
        (!voirAnciennes || sections.anciennes.isEmpty);

    final List<Widget> blocs = <Widget>[
      if (voirAFaire && sections.aFaire.isNotEmpty) ...<Widget>[
        titreSection(t.notifications.sectionAFaire),
        Ecart.vSm,
        CarteLignes(
          key: NotificationsPage.cleAFaire,
          lignes: <Widget>[
            for (final GroupeNotifications g in sections.aFaire)
              ligne(g, ecartable: peutEcarter),
          ],
        ),
        Ecart.vXl,
      ],
      if (voirNouvelles && sections.nouvelles.isNotEmpty) ...<Widget>[
        titreSection(
          t.notifications.sectionNouvelles,
          action: peutToutLire
              ? IntrinsicWidth(
                  child: ActionPrincipale(
                    key: NotificationsPage.cleToutLire,
                    libelle: t.notifications.toutMarquerLu,
                    niveau: NiveauAction.tertiaire,
                    pleineLargeur: false,
                    onPress: () => unawaited(_marquerToutesLues()),
                  ),
                )
              : null,
        ),
        Ecart.vSm,
        CarteLignes(
          key: NotificationsPage.cleNouvelles,
          lignes: <Widget>[
            for (final GroupeNotifications g in sections.nouvelles) ligne(g),
          ],
        ),
        Ecart.vXl,
      ],
      if (voirAnciennes && sections.anciennes.isNotEmpty) ...<Widget>[
        // Repliees par defaut (regle 3) : le titre est le bouton.
        Semantics(
          button: true,
          expanded: anciennesOuvertes,
          child: Pressable(
            key: NotificationsPage.cleAnciennes,
            onPress: () =>
                setState(() => _anciennesOuvertes = !anciennesOuvertes),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TexteSansCoupure(
                      t.notifications.sectionPlusAnciennes,
                      style: textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  Icon(
                    anciennesOuvertes
                        ? AppIcons.replier.repos
                        : AppIcons.suiteEnBas.repos,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (anciennesOuvertes) ...<Widget>[
          Ecart.vSm,
          CarteLignes(
            lignes: <Widget>[
              for (final GroupeNotifications g in sections.anciennes.take(
                _anciennesMontrees,
              ))
                ligne(g),
            ],
          ),
          if (sections.anciennes.length > _anciennesMontrees ||
              aSuiteServeur) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: NotificationsPage.cleVoirPlus,
                libelle: t.notifications.voirPlus,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                enCours: _chargePlus,
                onPress: () => unawaited(_voirPlus(sections, plusAncienneLue)),
              ),
            ),
          ],
        ],
      ],
    ];

    return ColonneHistorique(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SelecteurSection<FiltreNotifications>(
            key: NotificationsPage.cleFiltres,
            libelle: t.notifications.filtres.libelle,
            sections: <Segment<FiltreNotifications>>[
              for (final FiltreNotifications f in FiltreNotifications.values)
                Segment<FiltreNotifications>(valeur: f, libelle: f.libelle),
            ],
            valeur: _filtre,
            onChange: (FiltreNotifications f) => setState(() => _filtre = f),
          ),
          Ecart.vLg,
          if (retour != null) ...<Widget>[
            LocalFeedback(message: retour),
            Ecart.vSm,
          ],
          KeyedSubtree(
            key: NotificationsPage.cleListe,
            child: rienDansLeFiltre
                ? EtatSysteme(
                    nature: NatureEtat.aucunResultat,
                    titre: t.notifications.filtreVideTitre,
                    phrase: t.notifications.filtreVidePhrase,
                    libelleAction: t.notifications.voirToutes,
                    onAction: () =>
                        setState(() => _filtre = FiltreNotifications.toutes),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: blocs,
                  ),
          ),
          Ecart.vMd,
          NoteHistorique(t.historique.fuseauListe),
        ],
      ),
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
      if (nombre > 1) t.notifications.repetitions(n: nombre),
      if (!notification.lue) t.notifications.nonLueSemantique,
      // Rien a signaler : le niveau « Information » est dit quand meme, en
      // toutes lettres (spec section 13.1 : quatre niveaux, chacun dit).
      badge ?? BadgeNonLu.libelleNiveau(NiveauAttention.information),
    ].join(', ');
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
