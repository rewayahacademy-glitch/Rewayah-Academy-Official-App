// Le contenu de la cloche, le meme dans le panneau d'ordinateur, la feuille du
// telephone et la page complete (CLOCHE-C, decision du directeur du
// 21/11/2026, `DECISION-ANNONCES-NOTIFS-2026-11-21.md` ; maquette : style C).
//
// Trois onglets (« Tout », « Annonces », « A faire ») avec leur nombre, une
// ligne par element, le detail dans la meme surface (toucher la ligne l'ouvre
// et la marque lue), la croix des annonces avec « Annuler » pendant 5 s,
// « Tout marquer comme lu », 20 elements a la fois puis « Voir plus ». Tous
// les etats : chargement (squelette), vide par onglet, echec avec sa cause et
// « Reessayer », hors ligne, page suivante en cours, tout lu.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_notifications.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/tc_bibliotheque/ouvreur_onglet.dart';
import '../../../core/tc_horloge/mon_horloge.dart';
import '../../../core/theme/app_mouvement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/controle_segmente.dart' show Segment;
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/local_feedback.dart';
import '../../../core/widgets/selecteur_section.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/vue_etat_communication.dart';
import '../../com_annonces/port_annonces.dart';
import '../../com_messages/liens_message_staff.dart';
import '../../suivi_foyer/filtres_historique.dart';
import '../detail_notification.dart';
import '../notifications_page.dart'
    show
        LigneNotification,
        horlogeNotificationsProvider,
        notificationsTuteurProvider;
import '../notifications_supabase_provider.dart';
import 'annonces_cloche.dart';
import 'elements_cloche.dart';
import 'etat_annonces_cloche.dart';
import 'ligne_cloche.dart';

/// La surface qui porte le contenu.
enum FormeCloche {
  /// Le panneau ancre de 400 sous la cloche (ordinateur, 840 et plus).
  panneau,

  /// La feuille du bas (telephone et tablette).
  feuille,

  /// La page complete (« Voir tout »).
  page,
}

/// Le contenu de la cloche.
class ContenuCloche extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const ContenuCloche({
    required this.forme,
    required this.naviguer,
    super.key,
    this.cheminPage,
  });

  /// La surface qui le porte.
  final FormeCloche forme;

  /// La page complete du role (« Voir tout »), ou nul : pas de lien (la page
  /// elle-meme, ou un role sans page, le candidat).
  final String? cheminPage;

  /// Ouvre un chemin de l'application : le panneau ou la feuille se ferment
  /// d'abord.
  final void Function(String chemin) naviguer;

  /// La taille d'une page (regle 5).
  static const int pas = SourceAnnoncesCloche.taillePage;

  /// La cle du selecteur d'onglets, pour les tests.
  static const ValueKey<String> cleOnglets = ValueKey<String>('cloche-onglets');

  /// La cle de « Tout marquer comme lu », pour les tests.
  static const ValueKey<String> cleToutLire = ValueKey<String>(
    'cloche-tout-lire',
  );

  /// La cle de « Tout est lu », pour les tests.
  static const ValueKey<String> cleToutLu = ValueKey<String>('cloche-tout-lu');

  /// La cle de « Voir plus », pour les tests.
  static const ValueKey<String> cleVoirPlus = ValueKey<String>(
    'cloche-voir-plus',
  );

  /// La cle de « Voir tout », pour les tests.
  static const ValueKey<String> cleVoirTout = ValueKey<String>(
    'cloche-voir-tout',
  );

  /// La cle du retour du detail vers la liste, pour les tests.
  static const ValueKey<String> cleRetourListe = ValueKey<String>(
    'cloche-retour-liste',
  );

  /// La cle de « Voir le texte original », pour les tests.
  static const ValueKey<String> cleOriginal = ValueKey<String>(
    'cloche-original',
  );

  /// La cle de la ligne d'un element, pour les tests.
  static ValueKey<String> cleLigne(String cle) =>
      ValueKey<String>('cloche-ligne-$cle');

  /// La cle de la ligne « Annuler » d'une annonce fermee, pour les tests.
  static ValueKey<String> cleAnnulation(String id) =>
      ValueKey<String>('cloche-annulation-$id');

  @override
  ConsumerState<ContenuCloche> createState() => _ContenuClocheState();
}

class _ContenuClocheState extends ConsumerState<ContenuCloche> {
  OngletCloche _onglet = OngletCloche.tout;

  /// Le nombre d'elements montres, par onglet.
  final Map<OngletCloche, int> _montres = <OngletCloche, int>{};

  /// La cle de l'element ouvert en detail, ou nul.
  String? _detail;

  /// Le detail d'une annonce traduite montre l'original.
  bool _original = false;

  /// Les annonces qui montrent « Annuler », et leur minuteur.
  final Map<String, Timer> _annulations = <String, Timer>{};

  /// Le retour local d'un geste non confirme.
  String? _retour;

  /// Les notifications lues en plus, page par page.
  final List<NotificationTuteur> _plusNotifs = <NotificationTuteur>[];
  bool _finNotifs = false;
  bool _chargeNotifs = false;

  @override
  void dispose() {
    for (final Timer m in _annulations.values) {
      m.cancel();
    }
    super.dispose();
  }

  int _montresDe(OngletCloche o) => _montres[o] ?? ContenuCloche.pas;

  // -- Gestes ---------------------------------------------------------------

  Future<void> _lireNotification(NotificationTuteur n) async {
    if (n.lue) return;
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    try {
      if (port case final PortLectureNotifications lecture) {
        await lecture.marquerLue(n.id);
      }
    } on CapaciteIndisponible {
      return;
    } on Object {
      if (mounted) {
        setState(() => _retour = t.notifications.lectureNonConfirmee);
      }
      return;
    }
    if (!mounted) return;
    ref.invalidate(notificationsTuteurProvider);
    // R-COM-12 : la notification d'une annonce de Classe lit aussi l'annonce ;
    // un echec seul est dit non confirme, la notification reste lue.
    final String? annonceId = n.annonceId;
    if (annonceId == null) return;
    try {
      await ref.read(portAnnoncesProvider).marquerLue(annonceId);
    } on CapaciteIndisponible {
      return;
    } on Object {
      if (mounted) {
        setState(() => _retour = t.notifications.lectureNonConfirmee);
      }
      return;
    }
    if (mounted) ref.invalidate(annonceProvider(annonceId));
  }

  Future<void> _voirAnnonce(AnnonceCloche a) async {
    if (a.vue) return;
    // Montree vue tout de suite ; un echec n'empeche pas la lecture, elle
    // sera recomptee a la prochaine ouverture.
    ref.read(annoncesClocheProvider(false).notifier).vue(a.id);
    ref.read(annoncesClocheProvider(true).notifier).vue(a.id);
    try {
      await ref.read(sourceAnnoncesClocheProvider).marquerVue(a.id);
    } on Object {
      // Rien a dire : la lecture n'est pas perdue.
    }
  }

  Future<void> _toutLire(
    List<NotificationTuteur> notifs,
    List<AnnonceCloche> annonces,
  ) async {
    for (final AnnonceCloche a in annonces) {
      if (!a.vue) unawaited(_voirAnnonce(a));
    }
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    if (port is! PortLectureGroupeeNotifications) return;
    if (!notifs.any((NotificationTuteur n) => !n.lue)) return;
    try {
      await (port as PortLectureGroupeeNotifications).marquerToutesLues();
    } on CapaciteIndisponible {
      return;
    } on Object {
      if (mounted) {
        setState(() => _retour = t.notifications.lectureNonConfirmee);
      }
      return;
    }
    if (mounted) ref.invalidate(notificationsTuteurProvider);
  }

  /// Ferme [a] : la ligne devient « Annonce fermee. Annuler » pendant 5 s,
  /// puis s'efface ; le serveur est appele tout de suite, un echec rouvre la
  /// ligne et le dit (DECISION-FLUIDITE).
  Future<void> _fermer(AnnonceCloche a) async {
    final FermeturesCloche fermetures = ref.read(
      fermeturesClocheProvider.notifier,
    );
    fermetures.poser(a.id, fermee: true);
    _annulations[a.id]?.cancel();
    setState(() {
      _retour = null;
      if (_detail == 'a-${a.id}') _detail = null;
      _annulations[a.id] = Timer(AppMouvement.annulationFermeture, () {
        if (mounted) setState(() => _annulations.remove(a.id));
      });
    });
    try {
      await ref.read(sourceAnnoncesClocheProvider).fermer(a.id);
    } on Object {
      fermetures.retirer(a.id);
      if (!mounted) return;
      setState(() {
        _annulations.remove(a.id)?.cancel();
        _retour = t.notifications.cloche.fermetureNonConfirmee;
      });
    }
  }

  Future<void> _annuler(String id) async {
    final FermeturesCloche fermetures = ref.read(
      fermeturesClocheProvider.notifier,
    );
    fermetures.poser(id, fermee: false);
    setState(() => _annulations.remove(id)?.cancel());
    try {
      await ref.read(sourceAnnoncesClocheProvider).rouvrir(id);
    } on Object {
      fermetures.poser(id, fermee: true);
      if (mounted) {
        setState(() => _retour = t.notifications.cloche.fermetureNonConfirmee);
      }
    }
  }

  Future<void> _voirPlus(
    int total,
    EtatAnnoncesCloche ouvertes,
    EtatAnnoncesCloche? toutes,
    List<NotificationTuteur> notifs,
  ) async {
    final OngletCloche o = _onglet;
    final int montres = _montresDe(o);
    setState(() => _montres[o] = montres + ContenuCloche.pas);
    if (montres + ContenuCloche.pas <= total) return;
    final List<Future<void>> lectures = <Future<void>>[];
    if (o == OngletCloche.annonces && toutes != null) {
      lectures.add(ref.read(annoncesClocheProvider(true).notifier).suivante());
    }
    if (o == OngletCloche.tout && ouvertes.suite != null) {
      lectures.add(ref.read(annoncesClocheProvider(false).notifier).suivante());
    }
    if (o != OngletCloche.annonces) lectures.add(_notifsSuivantes(notifs));
    await Future.wait(lectures);
  }

  Future<void> _notifsSuivantes(List<NotificationTuteur> notifs) async {
    final PortNotifications port = ref.read(notificationsPagePortProvider);
    if (_finNotifs || _chargeNotifs || port is! PortPagesNotifications) return;
    final DateTime? avant = notifs
        .where((NotificationTuteur n) => n.lue)
        .map((NotificationTuteur n) => n.date)
        .fold<DateTime?>(
          null,
          (DateTime? m, DateTime d) => m == null || d.isBefore(m) ? d : m,
        );
    if (avant == null) {
      setState(() => _finNotifs = true);
      return;
    }
    setState(() => _chargeNotifs = true);
    try {
      final List<NotificationTuteur> lues =
          await (port as PortPagesNotifications).lues(avant: avant);
      if (!mounted) return;
      setState(() {
        _plusNotifs.addAll(lues);
        _finNotifs = lues.length < PortPagesNotifications.taillePage;
        _chargeNotifs = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _chargeNotifs = false;
        _retour = t.notifications.voirPlusErreur;
      });
    }
  }

  // -- Rendu ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final AsyncValue<List<NotificationTuteur>> valeur = ref.watch(
      notificationsTuteurProvider,
    );
    final EtatAnnoncesCloche ouvertes = ref.watch(
      annoncesClocheProvider(false),
    );
    // « Annonces » n'est lu qu'a la demande : la plupart des ouvertures ne
    // vont jamais dans cet onglet.
    final EtatAnnoncesCloche? toutes = _onglet == OngletCloche.annonces
        ? ref.watch(annoncesClocheProvider(true))
        : null;
    final Map<String, bool> fermetures = ref.watch(fermeturesClocheProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    final bool notifsIndispo = valeur.error is CapaciteIndisponible;
    final List<NotificationTuteur> notifs = valeur.hasValue && !notifsIndispo
        ? <NotificationTuteur>[
            ...valeur.requireValue,
            ..._plusNotifs.where(
              (NotificationTuteur p) => !valeur.requireValue.any(
                (NotificationTuteur n) => n.id == p.id,
              ),
            ),
          ]
        : const <NotificationTuteur>[];

    final List<ElementCloche> elements = elementsOnglet(
      _onglet,
      notifications: notifs,
      annoncesOuvertes: ouvertes.lues,
      annoncesToutes: toutes?.lues ?? const <AnnonceCloche>[],
      fermeturesLocales: fermetures,
      enAnnulation: _annulations.keys.toSet(),
    );

    final ElementCloche? ouvert = _detail == null
        ? null
        : <ElementCloche>[
            ...elementsOnglet(
              OngletCloche.tout,
              notifications: notifs,
              annoncesOuvertes: ouvertes.lues,
              annoncesToutes: const <AnnonceCloche>[],
              fermeturesLocales: fermetures,
            ),
            ...elements,
          ].where((ElementCloche e) => e.cle == _detail).firstOrNull;

    final Widget corps = ouvert != null
        ? _vueDetail(context, ouvert, fermetures)
        : _vueListe(
            context,
            elements: elements,
            valeur: valeur,
            notifs: notifs,
            ouvertes: ouvertes,
            toutes: toutes,
            fermetures: fermetures,
            horsLigne: horsLigne,
          );
    return AnimatedSwitcher(
      duration: AppMouvement.duree(context, AppMouvement.apparition),
      switchInCurve: AppMouvement.entree,
      switchOutCurve: AppMouvement.sortie,
      child: KeyedSubtree(key: ValueKey<String?>(ouvert?.cle), child: corps),
    );
  }

  EdgeInsetsDirectional get _marges => EdgeInsetsDirectional.symmetric(
    horizontal: widget.forme == FormeCloche.panneau ? AppSpacing.xl : 0,
  );

  /// La marge laterale d'une ligne : 20 dans le panneau, 12 dans la feuille
  /// (qui a deja sa marge), 16 dans la page.
  double get _margeLigne => switch (widget.forme) {
    FormeCloche.panneau => AppSpacing.xl,
    FormeCloche.feuille => AppSpacing.md,
    FormeCloche.page => AppSpacing.lg,
  };

  Widget _vueListe(
    BuildContext context, {
    required List<ElementCloche> elements,
    required AsyncValue<List<NotificationTuteur>> valeur,
    required List<NotificationTuteur> notifs,
    required EtatAnnoncesCloche ouvertes,
    required EtatAnnoncesCloche? toutes,
    required Map<String, bool> fermetures,
    required bool horsLigne,
  }) {
    final c = t.notifications.cloche;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    int nombre(OngletCloche o) => nombreOnglet(
      o,
      notifications: notifs,
      annoncesOuvertes: ouvertes.lues,
      fermeturesLocales: fermetures,
    );
    String libelle(OngletCloche o, String nom) {
      final int n = nombre(o);
      return n > 0 ? c.avecNombre(libelle: nom, n: n) : nom;
    }

    final bool notifsIndispo = valeur.error is CapaciteIndisponible;
    final bool notifsEchec = valeur.hasError && !notifsIndispo;
    final bool notifsAttente = valeur.isLoading && !valeur.hasValue;
    final EtatAnnoncesCloche annonces = _onglet == OngletCloche.annonces
        ? (toutes ?? const EtatAnnoncesCloche())
        : ouvertes;

    // L'etat de l'onglet : ce qu'il lit seulement.
    final bool lisNotifs = _onglet != OngletCloche.annonces;
    final bool lisAnnonces = _onglet != OngletCloche.aFaire;
    final bool attente =
        elements.isEmpty &&
        ((lisNotifs && notifsAttente) || (lisAnnonces && annonces.chargement));
    final bool indispo =
        (!lisNotifs || notifsIndispo) &&
        (!lisAnnonces || annonces.indisponible);
    final bool echec =
        elements.isEmpty &&
        ((lisNotifs && notifsEchec) || (lisAnnonces && annonces.echec));
    void reessayer() {
      if (lisNotifs && notifsEchec) ref.invalidate(notificationsTuteurProvider);
      if (lisAnnonces && annonces.echec) {
        unawaited(
          ref
              .read(
                annoncesClocheProvider(_onglet == OngletCloche.annonces)
                    .notifier,
              )
              .relire(),
        );
      }
    }

    final int nonLus = nombre(OngletCloche.tout);
    final bool rien = elements.isEmpty;
    final Widget? enTete = rien && !attente
        ? null
        : nonLus > 0
        ? ActionPrincipale(
            key: ContenuCloche.cleToutLire,
            libelle: t.notifications.toutMarquerLu,
            niveau: NiveauAction.tertiaire,
            compacte: true,
            pleineLargeur: false,
            onPress: () => unawaited(_toutLire(notifs, ouvertes.lues)),
          )
        : attente
        ? null
        : Text(
            c.toutLu,
            key: ContenuCloche.cleToutLu,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          );

    final int montres = _montresDe(_onglet);
    final bool suiteNotifs =
        lisNotifs &&
        !_finNotifs &&
        ref.read(notificationsPagePortProvider) is PortPagesNotifications &&
        notifs.any((NotificationTuteur n) => n.lue);
    final bool suite =
        elements.length > montres ||
        (lisAnnonces && annonces.suite != null) ||
        (suiteNotifs && elements.length >= montres);
    final bool chargePlus = annonces.chargePlus || _chargeNotifs;

    final List<Widget> lignes = <Widget>[
      for (final ElementCloche e in elements.take(montres))
        _ligne(context, e, notifs: notifs),
    ];

    Widget corpsListe;
    if (attente) {
      corpsListe = Padding(
        padding: _marges,
        child: const Skeleton.liste(lignes: 4),
      );
    } else if (indispo) {
      corpsListe = Padding(
        padding: _marges,
        child: EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: t.notifications.indisponibleTitre,
          phrase: t.notifications.indisponiblePhrase,
          dependance: switch (valeur.error) {
            final CapaciteIndisponible c => c.dependance,
            _ => null,
          },
        ),
      );
    } else if (echec) {
      corpsListe = Padding(
        padding: _marges,
        child: horsLigne
            ? VueEtatCommunication(
                etat: EtatCommunication.horsLigne,
                onReessayer: reessayer,
              )
            : EtatSysteme(
                nature: NatureEtat.echecServeur,
                titre: c.erreurTitre,
                phrase: c.erreurPhrase,
                libelleAction: t.commun.etats.actions.reessayer,
                onAction: reessayer,
              ),
      );
    } else if (rien) {
      final (String titre, String phrase) = switch (_onglet) {
        OngletCloche.tout => (c.videToutTitre, c.videToutPhrase),
        OngletCloche.annonces => (c.videAnnoncesTitre, c.videAnnoncesPhrase),
        OngletCloche.aFaire => (c.videAFaireTitre, c.videAFairePhrase),
      };
      corpsListe = Padding(
        padding: _marges,
        child: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: titre,
          phrase: phrase,
        ),
      );
    } else {
      corpsListe = AnimatedSize(
        duration: AppMouvement.duree(context, AppMouvement.apparition),
        curve: AppMouvement.entree,
        alignment: AlignmentDirectional.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < lignes.length; i++) ...<Widget>[
              if (i > 0) _filet(palette),
              lignes[i],
            ],
          ],
        ),
      );
    }

    // La page complete : la liste dans UNE carte a filets, sur le fond de la
    // page (K-55), bornee a la largeur de lecture par la page.
    if (widget.forme == FormeCloche.page &&
        !attente &&
        !indispo &&
        !echec &&
        !rien) {
      corpsListe = DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          borderRadius: AppRadius.arrondiMd,
          border: Border.fromBorderSide(palette.contourCarte.asBorderSide()),
        ),
        child: ClipRRect(borderRadius: AppRadius.arrondiMd, child: corpsListe),
      );
    }

    final bool annoncesEchecPartiel =
        _onglet == OngletCloche.tout && ouvertes.echec && !rien;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le titre au debut (panneau), l'action au bord de fin ; a l'etroit
        // (texte agrandi), l'action passe dessous, toujours au bord de fin.
        if (widget.forme == FormeCloche.panneau || enTete != null)
          Padding(
            padding: _marges,
            child: OverflowBar(
              alignment: widget.forme == FormeCloche.panneau
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: AppSpacing.md,
              overflowSpacing: AppSpacing.xs,
              children: <Widget>[
                if (widget.forme == FormeCloche.panneau)
                  Semantics(
                    header: true,
                    child: Text(
                      t.notifications.titre,
                      style: palette.inkStrong.applyTo(
                        textes.titleLarge ?? const TextStyle(),
                      ),
                    ),
                  ),
                ?enTete,
              ],
            ),
          ),
        Ecart.vSm,
        Padding(
          padding: _marges,
          child: SelecteurSection<OngletCloche>(
            key: ContenuCloche.cleOnglets,
            libelle: c.ongletsLibelle,
            sections: <Segment<OngletCloche>>[
              Segment<OngletCloche>(
                valeur: OngletCloche.tout,
                libelle: libelle(OngletCloche.tout, c.ongletTout),
              ),
              Segment<OngletCloche>(
                valeur: OngletCloche.annonces,
                libelle: libelle(OngletCloche.annonces, c.ongletAnnonces),
              ),
              Segment<OngletCloche>(
                valeur: OngletCloche.aFaire,
                libelle: libelle(
                  OngletCloche.aFaire,
                  t.notifications.sectionAFaire,
                ),
              ),
            ],
            valeur: _onglet,
            onChange: (OngletCloche o) => setState(() => _onglet = o),
          ),
        ),
        Ecart.vMd,
        if (horsLigne && !echec) ...<Widget>[
          Padding(
            padding: _marges,
            child: Text(
              c.horsLigne,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        if (_retour != null) ...<Widget>[
          Padding(
            padding: _marges,
            child: LocalFeedback(message: _retour),
          ),
          Ecart.vSm,
        ],
        if (annoncesEchecPartiel) ...<Widget>[
          Padding(
            padding: _marges,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  t.com.annonces.fil.echec,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
                LienFleche(
                  libelle: t.commun.etats.actions.reessayer,
                  alignerEnDebut: true,
                  onPress: () => unawaited(
                    ref.read(annoncesClocheProvider(false).notifier).relire(),
                  ),
                ),
              ],
            ),
          ),
          Ecart.vSm,
        ],
        if (widget.forme != FormeCloche.page) _filet(palette),
        corpsListe,
        if (!rien && suite && !attente) ...<Widget>[
          if (widget.forme != FormeCloche.page) _filet(palette),
          Ecart.vMd,
          Center(
            child: ActionPrincipale(
              key: ContenuCloche.cleVoirPlus,
              libelle: t.notifications.voirPlus,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              compacte: true,
              enCours: chargePlus,
              onPress: () => unawaited(
                _voirPlus(elements.length, ouvertes, toutes, notifs),
              ),
            ),
          ),
        ],
        if (annonces.erreurPlus) ...<Widget>[
          Ecart.vSm,
          Padding(
            padding: _marges,
            child: Text(
              t.notifications.voirPlusErreur,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
        if (widget.cheminPage case final String chemin) ...<Widget>[
          if (rien || !suite) _filet(palette),
          Ecart.vSm,
          Center(
            child: LienFleche(
              key: ContenuCloche.cleVoirTout,
              libelle: widget.forme == FormeCloche.panneau
                  ? c.voirToutPage
                  : c.voirTout,
              onPress: () => widget.naviguer(chemin),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filet(AppPalette palette) => Divider(
    height: palette.contourCarte.asBorderSide().width,
    thickness: palette.contourCarte.asBorderSide().width,
    color: palette.contourCarte.asBorderSide().color,
  );

  /// Le moment d'une ligne : l'heure aujourd'hui, « Hier », sinon le jour.
  String _quand(DateTime instant) {
    final DateTime maintenant = chezMoi(
      ref.read(horlogeNotificationsProvider)(),
    );
    final DateTime ici = chezMoi(instant);
    final DateTime jour = DateTime(ici.year, ici.month, ici.day);
    final DateTime aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final int ecart = aujourdhui.difference(jour).inDays;
    if (ecart == 0) return heureMinute(ici);
    if (ecart == 1) return t.notifications.cloche.hier;
    return dateCompacte(ici, maintenant);
  }

  Widget _ligne(
    BuildContext context,
    ElementCloche e, {
    required List<NotificationTuteur> notifs,
  }) {
    final bool compacte = widget.forme == FormeCloche.panneau;
    switch (e) {
      case ElementNotification(:final NotificationTuteur notification):
        final NotificationTuteur n = notification;
        final String? destination = n.destination;
        final bool geste = n.aFaire && destination != null;
        return LigneCloche(
          key: ContenuCloche.cleLigne(e.cle),
          categorie: n.aFaire
              ? CategorieLigneCloche.aFaire
              : (n.type == TypeNotification.changementSeance ||
                    n.type == TypeNotification.changementPlanning)
              ? CategorieLigneCloche.seance
              : CategorieLigneCloche.autre,
          prefixe: n.type == TypeNotification.autre
              ? null
              : libelleTypeNotification(n.type),
          titre: n.titre,
          texte: n.texte,
          quand: _quand(n.date),
          nonLu: !n.lue,
          compacte: compacte,
          margeLaterale: _margeLigne,
          libelleSemantique: LigneNotification.phraseSemantique(n),
          libelleAction: geste ? LigneNotification.libelleGeste(n) : null,
          onAction: geste
              ? () {
                  unawaited(_lireNotification(n));
                  widget.naviguer(destination);
                }
              : null,
          // Toucher la ligne la marque lue. Une notification qui mene a un
          // objet (un fil, une classe, un paiement) l'ouvre directement, comme
          // avant (R-06, BUREAU-NAV : aucune etape de plus) ; sans destination,
          // ou pour une annonce de Classe (R-COM-12), son detail s'ouvre sur
          // place.
          onOuvrir: () {
            unawaited(_lireNotification(n));
            if (destination != null && n.annonceId == null) {
              widget.naviguer(destination);
            } else {
              setState(() => _detail = e.cle);
            }
          },
        );
      case ElementAnnonce(:final AnnonceCloche annonce):
        final AnnonceCloche a = annonce;
        if (_annulations.containsKey(a.id) && _onglet == OngletCloche.tout) {
          return Padding(
            key: ContenuCloche.cleAnnulation(a.id),
            padding: _marges.add(
              const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            child: LocalFeedback(
              message: t.notifications.cloche.annonceFermee,
              libelleAnnuler: t.notifications.cloche.annuler,
              onAnnuler: () => unawaited(_annuler(a.id)),
              persistant: true,
            ),
          );
        }
        final OuvreurOnglet? ouvrir = ref.watch(ouvreurOngletProvider);
        final Uri? lien = liensHttps(a.texte).firstOrNull;
        final bool fermable =
            ref.watch(sourceAnnoncesClocheProvider).fermetureServie &&
            !a.fermee;
        return LigneCloche(
          key: ContenuCloche.cleLigne(e.cle),
          categorie: CategorieLigneCloche.annonce,
          prefixe: t.notifications.cloche.annonce,
          titre: a.titre,
          texte: a.texte,
          quand: _quand(a.publieeLe),
          nonLu: !a.vue,
          fermee: a.fermee,
          compacte: compacte,
          margeLaterale: _margeLigne,
          libelleSemantique: <String>[
            t.notifications.cloche.annonceLu(
              titre: a.titre,
              quand: _quand(a.publieeLe),
            ),
            if (!a.vue) t.notifications.nonLueSemantique,
            if (a.fermee) t.notifications.cloche.fermee,
          ].join(', '),
          libelleAction: ouvrir != null && lien != null
              ? t.notifications.cloche.ouvrirLien
              : null,
          onAction: ouvrir != null && lien != null
              ? () {
                  unawaited(_voirAnnonce(a));
                  ouvrir(lien);
                }
              : null,
          onFermer: fermable ? () => unawaited(_fermer(a)) : null,
          libelleFermer: t.notifications.cloche.fermerAnnonceLu(titre: a.titre),
          onOuvrir: () {
            unawaited(_voirAnnonce(a));
            setState(() {
              _detail = e.cle;
              _original = false;
            });
          },
        );
    }
  }

  Widget _vueDetail(
    BuildContext context,
    ElementCloche e,
    Map<String, bool> fermetures,
  ) {
    final c = t.notifications.cloche;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget retour = Align(
      alignment: AlignmentDirectional.centerStart,
      child: LienFleche(
        key: ContenuCloche.cleRetourListe,
        libelle: c.retourListe,
        icone: AppIcons.retour,
        fleche: false,
        alignerEnDebut: true,
        onPress: () => setState(() => _detail = null),
      ),
    );
    final Widget contenu = switch (e) {
      ElementNotification(:final NotificationTuteur notification) =>
        DetailNotification(
          key: ValueKey<String>('cloche-detail-${notification.id}'),
          notification: notification,
          onOuvrir: notification.destination == null
              ? null
              : () => widget.naviguer(notification.destination!),
        ),
      ElementAnnonce(:final AnnonceCloche annonce) => _detailAnnonce(
        context,
        annonce,
        palette,
        textes,
      ),
    };
    return Padding(
      padding: _marges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          retour,
          Ecart.vMd,
          contenu,
          if (_retour != null) ...<Widget>[
            Ecart.vSm,
            LocalFeedback(message: _retour),
          ],
          Ecart.vMd,
        ],
      ),
    );
  }

  Widget _detailAnnonce(
    BuildContext context,
    AnnonceCloche a,
    AppPalette palette,
    TextTheme textes,
  ) {
    final c = t.notifications.cloche;
    final bool original = _original && a.aUnOriginal;
    final String titre = original ? (a.titreOriginal ?? a.titre) : a.titre;
    final String texte = original ? (a.texteOriginal ?? a.texte) : a.texte;
    final bool fermable =
        ref.watch(sourceAnnoncesClocheProvider).fermetureServie && !a.fermee;
    // L'original garde le sens de sa langue (l'arabe de droite a gauche dans
    // une interface en francais, et l'inverse).
    final TextDirection? sens = !original || a.langueOriginale == null
        ? null
        : (a.langueOriginale == 'ar' ? TextDirection.rtl : TextDirection.ltr);
    return Column(
      key: ValueKey<String>('cloche-detail-annonce-${a.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              titre,
              textDirection: sens,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          t.com.annonces.fil.date(
            date: dateCourte(chezMoi(a.publieeLe)),
            heure: heureMinute(chezMoi(a.publieeLe)),
          ),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        if (a.aUnOriginal) ...<Widget>[
          Ecart.vSm,
          Text(
            c.traduite,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          LienFleche(
            key: ContenuCloche.cleOriginal,
            annonceLien: false,
            libelle: original ? c.voirTraduction : c.voirOriginal,
            fleche: false,
            alignerEnDebut: true,
            onPress: () => setState(() => _original = !_original),
          ),
        ],
        Ecart.vMd,
        SizedBox(
          width: double.infinity,
          child: Text(
            texte,
            textDirection: sens,
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IntrinsicWidth(child: LiensMessageStaff(texte: texte)),
        ),
        if (fermable) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            key: LigneCloche.cleFermer('detail-${a.id}'),
            libelle: c.fermerAnnonce,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () => unawaited(_fermer(a)),
          ),
        ],
      ],
    );
  }
}
