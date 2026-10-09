import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_classe/controleur_recitation.dart';
import '../../core/tc_classe/port_rappel_discret.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/rappel_discret.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/status_pill.dart';
import '../salle/vue_salle.dart';
import '../salle_seance/actions_seance.dart';
import '../salle_seance/depuis_classe_live.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/vue_seance.dart';
import 'entete_classe.dart';
import 'fiche_seance.dart';
import 'pre_vol_classe.dart';
import 'roster_classe.dart';
import 'scene_classe.dart';
import 'slots_tc_classe.dart';
import 'vue_classe_live.dart';

/// Tout ce que la Classe Live recoit de l'exterieur.
///
/// **Un objet plutot que quinze parametres**, parce que c'est exactement ce
/// qu'Agent Z aura a remplir a l'integration, et qu'une liste nommee se relit.
/// Chaque champ nul designe une surface **non encore branchee**, et la Classe
/// Live le dit a l'ecran plutot que de laisser un blanc.
@immutable
class ContexteClasseLive {
  /// Declare le contexte d'une seance.
  const ContexteClasseLive({
    required this.sessionId,
    required this.groupeId,
    required this.libelleGroupe,
    required this.enseignant,
    this.horloge,
    this.seuilMax,
    this.supportActifId,
    this.descriptionSupport,
    this.supportPresente,
    this.support,
    this.dock,
    this.bibliotheque,
    this.onNoter,
    this.onSignaler,
    this.onOuvrirContexte,
    this.onSortie,
  });

  /// La seance. Elle vient du billet d'entree, jamais de l'URL (ADR-005).
  final String sessionId;

  /// Le groupe dont la seance est l'etat temporaire.
  final String groupeId;

  /// Le nom familier du groupe.
  final String libelleGroupe;

  /// Qui enseigne : titre, nom, photo.
  final EnseignantDeClasse enseignant;

  /// L'horloge de la seance, rendue par `PortHorlogeSeance` (Agent A).
  ///
  /// `null` tant qu'elle n'est pas branchee : l'en-tete affiche alors le groupe
  /// sans temps restant, plutot qu'un compte a rebours calcule sur l'horloge de
  /// l'appareil.
  final SessionClockVM? horloge;

  /// Le plafond du groupe, **lu du serveur**. Jamais la valeur 5 en dur.
  final int? seuilMax;

  /// La ressource presentee. `null` = aucun support, la video reprend la place.
  final String? supportActifId;

  /// Ce que la salle sait du support partage (chapitre, titre, page sur
  /// nombre de pages), rendu par la salle de seance elle-meme quand aucun
  /// [support] n'est fourni. `null` tant que le catalogue n'est pas branche
  /// (BR-1) ; la demonstration et les captures le remplissent.
  final SupportSeance? descriptionSupport;

  /// Le support a page fixe PRESENTE a la classe (TB-1b, plan V2 §8), port
  /// neutre : `null` tant que l'etat partage n'est pas branche (TB-BR). Avec
  /// lui, la capsule compacte remplace la vignette pendant le partage (TB-3,
  /// UI-01) ; sans lui, la vignette reste.
  final SupportPageFixe? supportPresente;

  /// Le rendu du support, par Agent B ou Agent C.
  final WidgetBuilder? support;

  /// Le Teaching Dock d'Agent D.
  final WidgetBuilder? dock;

  /// Le `ClassLibraryPicker` d'Agent B.
  final WidgetBuilder? bibliotheque;

  /// Ouvre le cahier de seance. Branche par Agent Z.
  final VoidCallback? onNoter;

  /// Ouvre le signalement d'Agent H. Branche par Agent Z.
  final VoidCallback? onSignaler;

  /// Ouvre le contexte pedagogique complet. Branche par Agent Z.
  final VoidCallback? onOuvrirContexte;

  /// Ou l'on va apres une sortie volontaire. Branche par Agent Z.
  final VoidCallback? onSortie;
}

/// La Classe Live : la salle Rewayah, sans reimplementer LiveKit.
///
/// **Cet ecran ne possede pas la salle.** Il ne cree aucune `Room`, n'ouvre
/// aucun second moteur, et surtout : **son `dispose` ne quitte rien**. Revenir
/// au Groupe, a l'Accueil ou ouvrir la Bibliotheque demonte cet ecran ; le cours,
/// lui, continue, parce que son proprietaire est `ControleurSessionPersistante`,
/// au niveau applicatif (spec section 9.4, decision D-24).
///
/// Ce qu'il fait, et rien d'autre :
///
/// - il **compose** : qui domine, ou se lit le roster, quelle place prend la
///   video. La decision est prise par `VueClasseLive`, fonction pure ;
/// - il **montre** ce que les autres produisent : le support (Agents B et C), le
///   dock (Agent D), la Bibliotheque (Agent B), les annonces (Agent G) ;
/// - il **projette** le roster pedagogique, et seulement
///   `TeacherStudentProjection`.
///
/// Ce qu'il ne fait pas : aucune capacite calculee ici -- elles viennent du
/// jeton signe, via `VueSalle` ; aucune commande vocale (decision D-10) ; aucune
/// navigation pour ouvrir un support.
class ClasseLivePage extends ConsumerStatefulWidget {
  /// Cree la Classe Live d'une seance.
  const ClasseLivePage({required this.contexte, super.key});

  /// Tout ce que la page recoit de l'exterieur.
  final ContexteClasseLive contexte;

  @override
  ConsumerState<ClasseLivePage> createState() => _ClasseLivePageEtat();
}

class _ClasseLivePageEtat extends ConsumerState<ClasseLivePage> {
  /// Le moteur, capture une fois.
  ///
  /// Capture et non relu dans `dispose` : un `ref.read` au demontage arrive
  /// apres que le conteneur a commence a se defaire.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);
  late final ControleurSessionPersistante _controleur = ref.read(
    controleurSessionProvider,
  );

  StreamSubscription<EtatSalle>? _sEtats;
  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<QualiteLien>? _sQualite;

  EtatSalle _etatMoteur = EtatSalle.absent;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  QualiteLien _qualite = QualiteLien.inconnue;
  bool _materielMesureBloque = false;
  bool _bibliothequeOuverte = false;

  @override
  void initState() {
    super.initState();
    // On ecoute AVANT d'entrer : le moteur publie son premier etat pendant
    // `rejoindre`, et un abonnement pose apres manquerait la connexion.
    _etatMoteur = _moteur.etatCourant;
    _sEtats = _moteur.etats.listen((EtatSalle etat) {
      // **Le seul endroit qui confirme le lien apres une suspension.** Tant que
      // le moteur n'a pas redit « connecte » ou « retabli », on ne promet rien :
      // quand la plateforme tue le reseau, aucune machine de reconnexion ne peut
      // tenir parole.
      if (etat == EtatSalle.connecte || etat == EtatSalle.retabli) {
        _controleur.confirmerLien();
      }
      if (mounted) {
        setState(() => _etatMoteur = etat);
      }
    });
    _sParticipants = _moteur.participants.listen((List<ParticipantSalle> l) {
      if (mounted) {
        setState(() => _participants = l);
      }
    });
    _sQualite = _moteur.qualite.listen((QualiteLien lien) {
      if (mounted) {
        setState(() => _qualite = lien);
      }
    });
    unawaited(_entrer());
  }

  @override
  void dispose() {
    unawaited(_sEtats?.cancel());
    unawaited(_sParticipants?.cancel());
    unawaited(_sQualite?.cancel());
    // **Aucun `quitter()` ici, et c'est l'invariant du lot.** C'est exactement
    // ce que faisait `salle_page.dart`, et c'est pour cela qu'y retourner au
    // Groupe coupait le cours. Le proprietaire du cycle de vie est
    // `ControleurSessionPersistante` ; lui seul quitte, et seulement sur un
    // geste explicite.
    super.dispose();
  }

  /// Entre en salle, ou constate qu'on y est deja.
  ///
  /// Le pre-vol est **remesure** a chaque entree volontaire : un casque branche
  /// entre deux essais ne servirait a rien si l'on relisait le cache. En
  /// revanche un retour depuis la barre « Cours en cours » ne remesure rien --
  /// `ouvrir` s'arrete avant, la salle etant deja rejointe.
  Future<void> _entrer() async {
    setState(() => _materielMesureBloque = false);
    await _controleur.ouvrir(
      cours: SessionEnCours(
        sessionId: widget.contexte.sessionId,
        groupeId: widget.contexte.groupeId,
        libelleGroupe: widget.contexte.libelleGroupe,
        horloge: widget.contexte.horloge,
      ),
      preVol: () => ref.refresh(preVolProvider.future),
    );
    if (!mounted) {
      return;
    }
    final ResultatPreVol? mesure = ref.read(preVolProvider).value;
    setState(
      () => _materielMesureBloque = mesure != null && !mesure.peutEntrer,
    );
  }

  /// La sortie volontaire, confirmee une fois.
  ///
  /// **Le seul geste qui coupe la salle**, et il passe par le controleur : c'est
  /// lui qui annonce la sortie au serveur AVANT de deconnecter le moteur, ordre
  /// sans lequel une sortie voulue se lirait comme une coupure de reseau.
  Future<void> _quitter() async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.tc.classe.commandes.quitterQuestion,
      consequence: t.tc.classe.commandes.quitterConsequence,
      libelleConfirmer: t.tc.classe.commandes.quitter,
    );
    if (!confirme || !mounted) {
      return;
    }
    await _sortir();
  }

  /// La sortie elle-meme, une fois confirmee (la salle de seance confirme
  /// Quitter de son cote : `confirmerQuitterSeance`).
  Future<void> _sortir() async {
    await _controleur.quitter();
    ref.read(recitationProvider.notifier).reinitialiser();
    if (!mounted) {
      return;
    }
    widget.contexte.onSortie?.call();
  }

  /// Le mot du lien, dans une feuille (bouton Reseau du dock enseignant).
  Future<void> _voirReseau(VueSeance vue) => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.salle.seance.reseau,
    constructeur: (BuildContext _) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: switch (_Commandes._reseau(_qualite)) {
        final (String, TonEtat) dit => StatusPill(libelle: dit.$1, ton: dit.$2),
        null => Text(vue.texteConnexion),
      },
    ),
  );

  /// Quitte la salle puis ouvre [route] (rail enseignant).
  Future<void> _sortirVers(String route) async {
    await _controleur.quitter();
    ref.read(recitationProvider.notifier).reinitialiser();
    if (!mounted) {
      return;
    }
    GoRouter.maybeOf(context)?.go(route);
  }

  /// Ouvre [route] sans quitter la salle : le controleur de session
  /// persistante garde la room, la barre « Cours en cours » y ramene (D-24).
  void _allerSansQuitter(String route) => GoRouter.maybeOf(context)?.go(route);

  /// Le Groupe de la seance, selon le role : la fiche du groupe pour
  /// l'enseignant, l'Espace Groupe pour l'eleve, l'accueil pour la guidee.
  String _routeDuGroupe(RoleSeance role) => switch (role) {
    RoleSeance.enseignant => Routes.groupePour(widget.contexte.groupeId),
    RoleSeance.eleve => Routes.tcEspaceGroupe(widget.contexte.groupeId),
    RoleSeance.guidee => Routes.eleve,
  };

  /// La cloche : aucune source de notifications avant BR-1 (K-28), la
  /// feuille le dit plutot que d'inventer une liste.
  Future<void> _voirNotifications() => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.notifications.titre,
    constructeur: (BuildContext _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.notifications.indisponibleTitre,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Ecart.vXs,
        Text(t.notifications.indisponiblePhrase),
      ],
    ),
  );

  /// Le panneau ouvert a cote du support (enseignant).
  PanneauOuvert _panneau = PanneauOuvert.aucun;

  /// TB-3 (CTX-01, CTX-02) : le contexte deplie depuis la capsule. Etat
  /// local d'interface, jamais diffuse.
  ContexteOuvert _contexte = ContexteOuvert.aucun;

  /// Le zoom local, qui n'agit que sur cet ecran.
  double _zoom = 1;

  /// TB-5 (UI-03) : le focus local de l'enseignant (Commandes > Focus).
  /// Etat local d'interface, jamais diffuse ; la connexion n'en depend pas
  /// (UX-24).
  bool _agrandi = false;

  /// Le seul retour d'un rappel discret : son echec (spec 10.2).
  String? _echecRappel;

  void _basculerPanneau(PanneauOuvert panneau) => setState(() {
    _panneau = _panneau == panneau ? PanneauOuvert.aucun : panneau;
    // TB-4 (plan V2 §18.3) : un seul panneau secondaire ; les Commandes
    // remplacent le contexte deplie.
    if (_panneau == PanneauOuvert.commandes) _contexte = ContexteOuvert.aucun;
  });

  void _zoomer(double pas) => setState(() {
    _zoom = ((_zoom + pas).clamp(0.5, 2) * 10).round() / 10;
  });

  /// Le rappel discret, depuis la fiche du panneau Eleves. La reussite ne
  /// produit rien ; l'echec se dit, sur son motif.
  Future<void> _rappeler(EleveSeance eleve) async {
    final String? academyId = eleve.id;
    if (academyId == null) return;
    final PortRappelDiscret rappel = ref.read(portRappelDiscretProvider);
    final String sessionId = widget.contexte.sessionId;
    try {
      await rappel.rappeler(sessionId: sessionId, academyId: academyId);
      if (mounted) setState(() => _echecRappel = null);
    } on EchecRappel catch (echec) {
      if (!mounted) return;
      setState(
        () => _echecRappel = switch (echec.motif) {
          MotifEchecRappel.cooldown => t.tc.classe.rappel.cooldown(
            secondes:
                (rappel.cooldownRestant(
                          sessionId: sessionId,
                          academyId: academyId,
                        ) ??
                        rappel.cooldown)
                    .inSeconds,
          ),
          MotifEchecRappel.droitRefuse => t.tc.classe.rappel.echecDroit,
          MotifEchecRappel.transport => t.tc.classe.rappel.echec,
        },
      );
    }
  }

  /// La salle de seance unique (`SalleSeance`), celle de `/salle`, pour les
  /// roles eleve, guidee et enseignant. Les rappels ne sont poses que si ce
  /// qu'ils ouvrent est fourni par le contexte : un bouton qui ne peut pas
  /// aboutir n'est pas rendu.
  Widget _salleSeance({
    required VueSeance vue,
    required VueSalle salle,
    required SlotClasse support,
    required SlotClasse bibliotheque,
    required SlotClasse dock,
    required bool suspensionNonConfirmee,
  }) {
    final ContexteClasseLive contexte = widget.contexte;
    final bool enseignant = vue.role == RoleSeance.enseignant;
    final bool enSalle = salle.dansLaSalle;
    final bool microOuvert = salle.moi?.micro ?? false;
    final bool cameraOuverte = salle.moi?.camera ?? false;
    final VoidCallback? noter = contexte.onNoter;
    final VoidCallback? signaler = contexte.onSignaler;
    final bool rendSupport =
        contexte.support != null ||
        (contexte.supportActifId != null &&
            contexte.descriptionSupport == null);
    final Widget salleSeance = SalleSeance(
      vue: vue,
      local: EtatLocalSeance(
        microOuvert: microOuvert,
        cameraAllumee: cameraOuverte,
        zoom: _zoom,
        agrandi: _agrandi,
      ),
      contenuSupport: rendSupport ? SurfaceSupport(slot: support) : null,
      actions: ActionsSeance(
        // Revenir au Groupe ne quitte rien : la barre « Cours en cours »
        // ramene ici (session persistante, D-24).
        // Ouverte par `go` (bouton « Rejoindre »), la route n'a rien a
        // depiler : le chevron ramene alors au Groupe, sans quitter non plus.
        onRetour: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : () => _allerSansQuitter(_routeDuGroupe(vue.role)),
        // Coin de l'en-tete (images CLV-06 et CLV-07) : aucune source de
        // notifications n'est branchee avant BR-1, la cloche le dit sur place
        // ; reglages et compte ouvrent les pages communes `/compte`, la salle
        // restant ouverte (barre « Cours en cours », D-24).
        onNotifications: () => unawaited(_voirNotifications()),
        onReglages: () => _allerSansQuitter(Routes.compteReglages),
        onCompte: () => _allerSansQuitter(Routes.compte),
        onQuitter: () => unawaited(_sortir()),
        // Le rail enseignant (desktop) : la salle confirme la sortie, puis on
        // quitte vraiment avant d'aller ailleurs, comme le dit la confirmation.
        onNaviguer: enseignant
            ? (String route) => unawaited(_sortirVers(route))
            : null,
        onMicro: salle.peutParler && enSalle
            ? () => unawaited(_basculerMicro(microOuvert))
            : null,
        onCamera: salle.peutMontrer && enSalle
            ? () => unawaited(_basculerCamera(cameraOuverte))
            : null,
        // L'etat du lien, en un mot (J7), lu du moteur : aucune mesure maison.
        // Depuis TB-2, le Reseau n'est plus dans la barre : la feuille s'ouvre
        // par « Detail du reseau » du contexte enseignant (TB-3, plan §19.6).
        onReseau: enseignant ? () => unawaited(_voirReseau(vue)) : null,
        // TB-3 : l'avatar et l'oeil de la capsule deplient le contexte,
        // « Reduire » le replie ; etat local, rien n'est diffuse.
        // TB-4 (plan V2 §18.3) : le contexte deplie remplace les Commandes
        // (un seul panneau secondaire), qui ne reviennent pas a sa fermeture.
        onContexte: (ContexteOuvert c) => setState(() {
          _contexte = c;
          if (c != ContexteOuvert.aucun &&
              _panneau == PanneauOuvert.commandes) {
            _panneau = PanneauOuvert.aucun;
          }
        }),
        onZoomMoins: () => _zoomer(-0.1),
        onZoomPlus: () => _zoomer(0.1),
        // TB-4 (CMD-01) : le panneau « Commandes » de l'enseignant (etat
        // local) ; « Ajuster a l'ecran » remet le zoom local a 100 %. Les
        // affichages partages attendent leur champ serveur (TB-BR-13) : pas
        // de rappel, pas de choix rendu.
        onCommandes: enseignant
            ? () => _basculerPanneau(PanneauOuvert.commandes)
            : null,
        onAjusterEcran: enseignant ? () => setState(() => _zoom = 1) : null,
        // TB-5 (UI-03) : Focus et « Quitter le focus » ; la salle replie et
        // restaure ses panneaux.
        onAgrandir: enseignant
            ? () => setState(() => _agrandi = !_agrandi)
            : null,
        onEleves: enseignant && salle.voitLesParticipants && vue.elevesConnus
            ? () => _basculerPanneau(PanneauOuvert.eleves)
            : null,
        // La Bibliotheque s'ouvre sans quitter la room (D-20), et seulement
        // si elle est fournie.
        onSupports: enseignant && contexte.bibliotheque != null && enSalle
            ? () => unawaited(_ouvrirBibliotheque(bibliotheque, feuille: true))
            : null,
        onBibliotheque: enseignant && contexte.bibliotheque != null
            ? () => unawaited(_ouvrirBibliotheque(bibliotheque, feuille: true))
            : null,
        // Le Teaching Dock d'Agent D porte les outils : sans lui, aucun outil.
        onOutil: enseignant && contexte.dock != null
            ? (OutilEnseignement _) => unawaited(
                AppBottomSheet.ouvrir<void>(
                  context,
                  titre: t.salle.seance.outils.titre,
                  constructeur: (BuildContext _) => HoteDock(slot: dock),
                ),
              )
            : null,
        onRappeler: enseignant
            ? (EleveSeance e) => unawaited(_rappeler(e))
            : null,
        onChoisirPourReciter: enseignant
            ? (EleveSeance e) {
                final String? id = e.id;
                if (id != null) {
                  ref.read(recitationProvider.notifier).donnerLaParoleA(id);
                }
              }
            : null,
        onNoter: enseignant && noter != null
            ? (EleveSeance _) => noter()
            : null,
        onSignaler: enseignant && signaler != null
            ? (EleveSeance _) => signaler()
            : null,
      ),
    );
    final String? avis = suspensionNonConfirmee
        ? t.tc.classe.lien.retourDeSuspension
        : null;
    if (avis == null && _echecRappel == null) return salleSeance;
    // Les deux seuls messages de la Classe Live qui ne sont pas dans la salle
    // de seance : une ligne au-dessus, jamais par-dessus.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (avis != null) LocalFeedback(message: avis, persistant: true),
        if (_echecRappel case final String echec)
          LocalFeedback(message: echec, persistant: true),
        Expanded(child: salleSeance),
      ],
    );
  }

  Future<void> _voirRoster(
    RosterClasseVM roster,
  ) => AppBottomSheet.ouvrir<void>(
    context,
    titre: t.tc.classe.roster.titre,
    constructeur: (BuildContext _) => PanneauRoster(
      roster: roster,
      onOuvrirFiche: (String academyId) {
        // La feuille de roster se referme avant d'ouvrir la fiche : deux
        // feuilles empilees sur un telephone ne laisseraient plus rien voir du
        // cours.
        Navigator.of(context).pop();
        unawaited(_voirFiche(roster, academyId));
      },
    ),
  );

  Future<void> _voirFiche(RosterClasseVM roster, String academyId) {
    final TeacherStudentProjection? eleve = roster.parAcademyId(academyId);
    if (eleve == null) {
      return Future<void>.value();
    }
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: eleve.firstName,
      constructeur: (BuildContext _) => FicheSeance(
        eleve: eleve,
        sessionId: widget.contexte.sessionId,
        onNoter: widget.contexte.onNoter,
        onSignaler: widget.contexte.onSignaler,
        onOuvrirContexte: widget.contexte.onOuvrirContexte,
      ),
    );
  }

  /// Ouvre la Bibliotheque **sans quitter la room**.
  ///
  /// Sur un ecran large, c'est un panneau lateral -- un simple etat de cette
  /// page, donc aucune navigation. Sur telephone, c'est une feuille modale, qui
  /// s'empile sur la page sans la demonter. Dans les deux cas, personne
  /// n'appelle `quitter` et personne ne change de route (decision D-20).
  Future<void> _ouvrirBibliotheque(
    SlotClasse slot, {
    bool feuille = false,
  }) async {
    if (!feuille && AppGabarit.de(context).estLarge) {
      setState(() => _bibliothequeOuverte = true);
      return;
    }
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: t.tc.classe.support.bibliotheque,
      constructeur: (BuildContext _) =>
          EmplacementBibliothequeEnClasse(slot: slot),
    );
  }

  Future<void> _basculerMicro(bool ouvert) =>
      _moteur.reglerMicro(actif: !ouvert);

  Future<void> _basculerCamera(bool ouverte) =>
      _moteur.reglerCamera(actif: !ouverte);

  @override
  Widget build(BuildContext context) {
    final ContexteClasseLive contexte = widget.contexte;
    final EtatSessionPersistante etat =
        ref.watch(etatSessionProvider).value ?? EtatSessionPersistante.aucun;

    // **Aucune capacite n'est calculee ici** : `VueSalle` les lit dans le jeton
    // signe, qui est la seule verite. Elle est CONSOMMEE, pas recopiee -- elle
    // decide de la phase d'entree, du role et de qui occupe le cadre ; c'est
    // `VueClasseLive` qui decide de la composition.
    final VueSalle salle = VueSalle.depuis(
      materielPret: etat.materielPret,
      acces: etat.acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse(etat),
    );

    // **L'annonce d'observation est lue par l'enseignant, et par lui seul.**
    // Le role vient du jeton signe, jamais d'un calcul local, et le serveur
    // redit la meme chose de son cote : `annonces_observation` leve
    // `insufficient_privilege` pour qui n'est pas l'enseignant de la seance
    // (`supabase/migrations/0033_tc_vues_rpc.sql:1275`). La condition ici
    // n'ajoute donc aucune securite -- elle evite seulement de battre toutes
    // les dix secondes une RPC qui refusera, sur l'appareil de chaque eleve.
    final List<AnnonceObservation> annonces = salle.role == RoleSalle.enseignant
        ? ref.watch(annoncesObservationProvider(contexte.sessionId)).value ??
              const <AnnonceObservation>[]
        : const <AnnonceObservation>[];

    // **La symetrie cote eleve, par une AUTRE lecture.** L'eleve ne peut pas
    // se servir de celle de l'enseignant : elle lui est refusee par le serveur,
    // et elle porte les prenoms de tous les enfants observes.
    // `annonce_observation_pour_moi` (`0040`) ne rend que SA ligne, et rien
    // d'un autre foyer -- pas meme son nombre.
    //
    // Meme raison qu'au-dessus pour la condition de role : elle n'ajoute
    // aucune securite (le serveur refuse deja qui n'est pas membre du groupe),
    // elle evite de battre la RPC sur l'appareil de l'enseignant et du
    // controleur, qui montent le meme en-tete.
    final bool monTuteurObserve =
        salle.role == RoleSalle.eleve &&
        (ref.watch(monTuteurObserveProvider(contexte.sessionId)).value ??
            false);

    final RosterClasseVM roster = ref
        .watch(rosterClasseProvider(contexte.sessionId))
        .avecFile(ref.watch(recitationProvider))
        .avecSeuil(contexte.seuilMax);

    final SessionLiveVM session = SessionLiveVM(
      sessionId: contexte.sessionId,
      groupeId: contexte.groupeId,
      libelleGroupe: contexte.libelleGroupe,
      enseignant: contexte.enseignant,
      etatLien: _etatMoteur,
      horloge: etat.cours?.horloge ?? contexte.horloge,
      supportActifId: contexte.supportActifId,
    );

    final VueClasseLive vue = VueClasseLive.depuis(
      gabarit: AppGabarit.de(context),
      session: session,
      roster: roster,
      voitLeRoster: salle.voitLesParticipants,
      peutPiloterSupport: salle.peutPresenter,
      // **Le retour de suspension, pas la suspension elle-meme** : une
      // application suspendue ne rend aucune image, donc un avertissement
      // affiche pendant la suspension ne serait jamais lu.
      suspensionNonConfirmee: etat.retourDeSuspension,
    );

    final bool enImpasse = salle.phase == PhaseSalle.refus;
    final bool enAttente =
        salle.phase == PhaseSalle.materiel ||
        salle.phase == PhaseSalle.ouverture ||
        salle.phase == PhaseSalle.connexion;

    final SlotClasse slotSupport = SlotClasse(
      sessionId: contexte.sessionId,
      groupeId: contexte.groupeId,
      resourceId: contexte.supportActifId,
      contenu: contexte.support,
    );
    final SlotClasse slotBibliotheque = SlotClasse(
      sessionId: contexte.sessionId,
      groupeId: contexte.groupeId,
      contenu: contexte.bibliotheque,
    );

    // **En seance, la salle unique** : le meme gabarit que `/salle`, pour
    // l'eleve, la guidee et l'enseignant (plan de code, CL-2). Les autres
    // roles du jeton (tuteur observateur, controleur) gardent le rendu
    // ci-dessous, comme dans `/salle`.
    if (!enImpasse && !enAttente) {
      final VueSeance? seance = DepuisClasseLive.vue(
        salle: salle,
        mode: AppMetriques.of(context).mode,
        roster: roster,
        libelleGroupe: contexte.libelleGroupe,
        nomEnseignant: nomAvecTitre(contexte.enseignant),
        groupeId: contexte.groupeId,
        horloge: session.horloge,
        monTuteurObserve: monTuteurObserve,
        annonces: annonces,
        support:
            contexte.descriptionSupport ??
            (contexte.supportActifId == null
                ? null
                : SupportSeance(
                    ressourceId: contexte.supportActifId,
                    chapitre: '',
                    titre: '',
                    encadre: '',
                    points: const <String>[],
                    page: 1,
                    pages: 1,
                  )),
        panneau: _panneau,
      );
      if (seance != null) {
        return _salleSeance(
          vue: seance.copyWith(
            supportPresente: contexte.supportPresente,
            contexte: _contexte,
          ),
          salle: salle,
          support: slotSupport,
          bibliotheque: slotBibliotheque,
          dock: SlotClasse(
            sessionId: contexte.sessionId,
            groupeId: contexte.groupeId,
            resourceId: contexte.supportActifId,
            contenu: contexte.dock,
          ),
          suspensionNonConfirmee: etat.retourDeSuspension,
        );
      }
    }

    return PageImmersive(
      registre: RegistreImmersif.salle,
      entete: EnteteClasse(
        session: session,
        vue: vue,
        roster: roster,
        annonces: annonces,
        monTuteurObserve: monTuteurObserve,
        // Le bouton compact n'existe que la ou le roster est replie : a cote
        // d'une colonne, il ferait doublon.
        onVoirRoster: vue.placeRoster == PlaceRoster.feuille
            ? () => unawaited(_voirRoster(roster))
            : null,
      ),
      bandeau: enImpasse ? null : const PermanentNotice(),
      commandes: enImpasse || enAttente
          ? null
          : _Commandes(
              salle: salle,
              qualite: _qualite,
              peutOuvrirBibliotheque: salle.peutPresenter,
              onBibliotheque: () =>
                  unawaited(_ouvrirBibliotheque(slotBibliotheque)),
              onMicro: _basculerMicro,
              onCamera: _basculerCamera,
              onQuitter: () => unawaited(_quitter()),
            ),
      child: enImpasse || enAttente
          ? _Attente(
              phase: salle.phase,
              vue: VuePreCours.depuis(
                role: salle.role,
                resultat: ref.watch(preVolProvider).value,
              ),
              onReessayer: () => unawaited(_entrer()),
            )
          : _Corps(
              vue: vue,
              roster: roster,
              salle: salle,
              support: slotSupport,
              bibliotheque: slotBibliotheque,
              dock: SlotClasse(
                sessionId: contexte.sessionId,
                groupeId: contexte.groupeId,
                resourceId: contexte.supportActifId,
                contenu: contexte.dock,
              ),
              bibliothequeOuverte: _bibliothequeOuverte,
              onFermerBibliotheque: () =>
                  setState(() => _bibliothequeOuverte = false),
              onOuvrirFiche: (String id) => unawaited(_voirFiche(roster, id)),
            ),
    );
  }

  /// L'impasse, telle que l'usager doit la comprendre.
  ///
  /// Le materiel passe **devant** le refus du backend : quand aucun micro ne
  /// repond, aucun jeton n'a meme ete demande, et dire « acces refuse » enverrait
  /// l'enseignant chercher la faute du mauvais cote.
  CauseImpasse? _impasse(EtatSessionPersistante etat) {
    if (_materielMesureBloque) {
      return CauseImpasse.materiel;
    }
    final MotifRefusSalle? refus = etat.refus;
    return refus == null ? null : CauseImpasse.depuis(refus);
  }
}

/// Ce qui occupe l'ecran avant d'etre en salle.
///
/// **Le pre-cours d'abord, l'attente ensuite.** L'enseignant voit son preflight
/// (spec section 9.5) ; l'eleve ne voit rien tant que rien ne bloque, et une
/// page blanche serait alors un defaut : il lit a la place ou en est l'entree.
///
/// Les trois attentes se disent par des **mots differents** : elles n'echouent
/// pas pour les memes raisons, donc ne se corrigent pas de la meme facon. Un
/// unique « Chargement... » obligerait a deviner.
class _Attente extends StatelessWidget {
  const _Attente({
    required this.phase,
    required this.vue,
    required this.onReessayer,
  });

  final PhaseSalle phase;
  final VuePreCours vue;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    if (vue.visible) {
      return PreCours(vue: vue, onReessayer: onReessayer);
    }
    final String mot = switch (phase) {
      PhaseSalle.materiel => t.tc.classe.attente.materiel,
      PhaseSalle.ouverture => t.tc.classe.attente.ouverture,
      PhaseSalle.connexion ||
      PhaseSalle.enSalle ||
      PhaseSalle.instable ||
      PhaseSalle.reconnexion ||
      PhaseSalle.retabli => t.tc.classe.attente.connexion,
      // Une impasse qui n'est pas materielle : le backend a refuse, et il ne
      // dit jamais pourquoi -- ni « seance inconnue », ni « pas inscrit », ni
      // « trop tot ». Un seul message, et c'est voulu.
      PhaseSalle.refus => t.tc.classe.attente.refus,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              mot,
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
            ),
            if (phase == PhaseSalle.refus) ...<Widget>[
              Ecart.vLg,
              ActionPrincipale(
                libelle: t.tc.classe.prevol.reessayer,
                onPress: onReessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le corps de la Classe Live : le support domine, la video suit.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    required this.roster,
    required this.salle,
    required this.support,
    required this.bibliotheque,
    required this.dock,
    required this.bibliothequeOuverte,
    required this.onFermerBibliotheque,
    required this.onOuvrirFiche,
  });

  final VueClasseLive vue;
  final RosterClasseVM roster;
  final VueSalle salle;
  final SlotClasse support;
  final SlotClasse bibliotheque;
  final SlotClasse dock;
  final bool bibliothequeOuverte;
  final VoidCallback onFermerBibliotheque;
  final void Function(String academyId) onOuvrirFiche;

  @override
  Widget build(BuildContext context) {
    // La scene lit l'ordre decide par `VueSalle` : le role attendu d'abord.
    final List<ParticipantSalle> distants = <ParticipantSalle>[
      if (salle.dominant case final ParticipantSalle premier) premier,
      ...salle.autres,
    ];

    final Widget scene = SceneClasse(
      participants: distants,
      poids: vue.poidsVideo,
    );

    // Sans support presente, la video EST le contenu : elle prend toute la
    // place que le roster lui laisse (spec section 9.1).
    final Widget principal = vue.supportDomine
        ? Stack(
            children: <Widget>[
              Positioned.fill(child: SurfaceSupport(slot: support)),
              // **Le dock FLOTTE, il ne couvre pas le Coran** : il se pose en
              // bas, a distance du bord, et il n'existe que pour qui peut
              // piloter le support.
              if (vue.dockFlottant)
                PositionedDirectional(
                  bottom: AppSpacing.lg,
                  start: AppSpacing.lg,
                  end: AppSpacing.lg,
                  child: HoteDock(slot: dock),
                ),
            ],
          )
        : scene;

    final Widget colonneRoster = SizedBox(
      // Une largeur de chrome deja posee pour la barre laterale : la reutiliser
      // evite d'en inventer une seconde.
      width: AppGabarit.largeurBarreLaterale,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PanneauRoster(
          roster: roster,
          entete: true,
          onOuvrirFiche: onOuvrirFiche,
        ),
      ),
    );

    final Widget panneauBibliotheque = SizedBox(
      width: AppGabarit.largeurBarreLaterale,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ActionPrincipale(
              libelle: t.tc.classe.commandes.fermerBibliotheque,
              onPress: onFermerBibliotheque,
              niveau: NiveauAction.tertiaire,
            ),
            Ecart.vMd,
            Expanded(
              child: EmplacementBibliothequeEnClasse(slot: bibliotheque),
            ),
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le roster est **secondaire** : a gauche, etroit, et il ne prend
        // jamais la place du support (spec section 9.1).
        if (vue.placeRoster == PlaceRoster.colonne) colonneRoster,
        Expanded(flex: 3, child: principal),
        // La video en bande a cote du support : elle garde de quoi reconnaitre
        // qui parle, pas une part de l'ecran. En vignette, elle se pose SOUS le
        // support et non par-dessus -- aucune barre d'outils ne couvre le Coran.
        if (vue.poidsVideo == PoidsVideo.bande)
          Expanded(child: scene)
        else if (vue.poidsVideo == PoidsVideo.vignette)
          SizedBox(width: AppSpacing.respiration * 1.5, child: scene),
        if (bibliothequeOuverte) panneauBibliotheque,
      ],
    );
  }
}

/// La barre basse : micro, camera, etat reseau, Bibliotheque, Quitter.
///
/// **Le nombre de commandes decoule du jeton, jamais du mode d'interface.** Un
/// controle que le jeton refuse n'est PAS rendu, et n'est jamais grise : un
/// bouton visible mais inactif invite a appuyer dessus, son absence ne pose pas
/// la question.
///
/// Elle passe par `ActionPrincipale`, seul point d'entree des actions du
/// produit : `tool/verifier_jetons.dart` refuse tout bouton Material.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.salle,
    required this.qualite,
    required this.peutOuvrirBibliotheque,
    required this.onBibliotheque,
    required this.onMicro,
    required this.onCamera,
    required this.onQuitter,
  });

  final VueSalle salle;
  final QualiteLien qualite;
  final bool peutOuvrirBibliotheque;
  final VoidCallback onBibliotheque;
  final Future<void> Function(bool ouvert) onMicro;
  final Future<void> Function(bool ouverte) onCamera;
  final VoidCallback onQuitter;

  @override
  Widget build(BuildContext context) {
    // **Micro et camera sont fermes a l'entree, pour tout le monde** (spec 9.3).
    // Ce n'est pas re-code ici : `livekit_session_provider.dart` ne publie rien
    // a l'entree, pour les quatre roles, et le serveur le fait respecter. Cette
    // barre ne fait que lire ce que le moteur rapporte.
    final bool microOuvert = salle.moi?.micro ?? false;
    final bool cameraOuverte = salle.moi?.camera ?? false;
    final bool enSalle = salle.dansLaSalle;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (salle.peutParler)
          ActionPrincipale(
            libelle: microOuvert
                ? t.tc.classe.commandes.microFermer
                : t.tc.classe.commandes.micro,
            onPress: enSalle ? () => unawaited(onMicro(microOuvert)) : null,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
        if (salle.peutMontrer)
          ActionPrincipale(
            libelle: cameraOuverte
                ? t.tc.classe.commandes.cameraFermer
                : t.tc.classe.commandes.camera,
            onPress: enSalle ? () => unawaited(onCamera(cameraOuverte)) : null,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
        if (peutOuvrirBibliotheque)
          ActionPrincipale(
            libelle: t.tc.classe.support.bibliotheque,
            onPress: enSalle ? onBibliotheque : null,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
        // L'etat reseau se dit par un MOT (invariant J7). Aucune mesure maison :
        // c'est `QualiteLien`, publie par le moteur, qui le donne.
        if (_reseau(qualite) case final (String, TonEtat) dit)
          StatusPill(libelle: dit.$1, ton: dit.$2),
        ActionPrincipale(
          libelle: t.tc.classe.commandes.quitter,
          onPress: onQuitter,
          niveau: NiveauAction.destructive,
          pleineLargeur: false,
        ),
      ],
    );
  }

  /// L'etat du lien, en un mot. `null` avant la premiere mesure.
  static (String, TonEtat)? _reseau(QualiteLien qualite) => switch (qualite) {
    QualiteLien.inconnue => null,
    QualiteLien.excellente ||
    QualiteLien.bonne => (t.tc.classe.reseau.bon, TonEtat.succes),
    QualiteLien.mediocre => (
      t.tc.classe.reseau.mediocre,
      TonEtat.avertissement,
    ),
    QualiteLien.perdue => (t.tc.classe.reseau.perdu, TonEtat.alerte),
  };
}
