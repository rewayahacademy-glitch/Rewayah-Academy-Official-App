import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_classe/controleur_recitation.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/tc_etat_partage/shared_content_state.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/status_pill.dart';
import '../salle/vue_salle.dart';
import '../tc_dock/teaching_dock.dart';
import '../tc_mushaf/selection_verset.dart';
import '../tc_mushaf/vue_verset_agrandi.dart';
import 'commandes_classe.dart';
import 'entete_classe.dart';
import 'etat_partage_classe.dart';
import 'fiche_seance.dart';
import 'hote_dock_classe.dart';
import 'pre_vol_classe.dart';
import 'roster_classe.dart';
import 'scene_classe.dart';
import 'slots_tc_classe.dart';
import 'vue_classe_live.dart';

/// Ce que la coque rend a l'appelant apres une sortie volontaire.
///
/// **La coque ne navigue pas** (decision D-04) : elle dit qui sort et si le
/// cours a reellement eu lieu, et la route decide -- cahier pour l'enseignant
/// qui a tenu le cours, racine du role pour les autres.
@immutable
class SortieClasse {
  /// Declare une sortie.
  const SortieClasse({required this.role, required this.aEteEnSalle});

  /// Le role tenu, lu du jeton.
  final RoleSalle role;

  /// Vrai quand la sortie a lieu depuis une salle rejointe.
  final bool aEteEnSalle;
}

/// Tout ce que la Classe Live recoit de l'exterieur.
///
/// Chaque champ facultatif designe une chose que l'ecran d'entree pouvait ne
/// pas savoir : un controleur entre par une seance, pas par un groupe. La
/// coque le dit a l'ecran plutot que d'inventer.
@immutable
class ContexteClasseLive {
  /// Declare le contexte d'une seance.
  const ContexteClasseLive({
    required this.sessionId,
    required this.libelleGroupe,
    this.groupeId,
    this.enseignant,
    this.horloge,
    this.seuilMax,
    this.supportActifId,
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

  /// Le groupe dont la seance est l'etat temporaire, quand il est connu.
  final String? groupeId;

  /// Le nom familier du groupe, ou un libelle de repli.
  final String libelleGroupe;

  /// Qui enseigne, quand l'ecran d'entree le savait.
  final EnseignantDeClasse? enseignant;

  /// L'horloge de la seance, rendue par `PortHorlogeSeance` (Agent A).
  final SessionClockVM? horloge;

  /// Le plafond du groupe, **lu du serveur**. Jamais la valeur 5 en dur.
  final int? seuilMax;

  /// Un support impose. `null` = celui que l'etat partage designe.
  final String? supportActifId;

  /// Un rendu de support impose (tests). `null` = le Coran suivi.
  final WidgetBuilder? support;

  /// Un dock impose (tests). `null` = le Teaching Dock d'Agent D.
  final WidgetBuilder? dock;

  /// Une Bibliotheque imposee (tests). `null` = celle d'Agent B.
  final WidgetBuilder? bibliotheque;

  /// Ouvre le cahier de seance.
  final VoidCallback? onNoter;

  /// Ouvre le signalement d'Agent H.
  final VoidCallback? onSignaler;

  /// Ouvre le contexte pedagogique complet.
  final VoidCallback? onOuvrirContexte;

  /// Ou l'on va apres une sortie volontaire.
  final void Function(SortieClasse sortie)? onSortie;
}

/// La Classe Live : la salle Rewayah, une seule pour les six roles.
///
/// **Cet ecran ne possede pas la salle.** Il ne cree aucune `Room`, n'ouvre
/// aucun second moteur, et **son `dispose` ne quitte rien**. Le proprietaire
/// du cycle de vie est `ControleurSessionPersistante` (spec 9.4, D-24).
///
/// Ce qu'il fait, et rien d'autre :
///
/// - il **compose** : qui domine, ou se lit le roster, quelle place prend la
///   video -- decide par `VueClasseLive`, fonction pure ;
/// - il **montre** ce que les autres produisent : le Coran suivi par l'etat
///   partage, le dock d'Agent D, la Bibliotheque d'Agent B, les annonces
///   d'Agent G, la presence derivee par la base ;
/// - il **projette** le roster pedagogique, et seulement
///   `TeacherStudentProjection`.
///
/// Aucune capacite n'est calculee ici : elles viennent du jeton signe, via
/// `VueSalle`. Aucune presence n'est recalculee : elle est lue.
class ClasseLivePage extends ConsumerStatefulWidget {
  /// Cree la Classe Live d'une seance.
  const ClasseLivePage({required this.contexte, super.key});

  /// Tout ce que la page recoit de l'exterieur.
  final ContexteClasseLive contexte;

  @override
  ConsumerState<ClasseLivePage> createState() => _ClasseLivePageEtat();
}

class _ClasseLivePageEtat extends ConsumerState<ClasseLivePage> {
  /// Le moteur, capture une fois : un `ref.read` au demontage arrive apres que
  /// le conteneur a commence a se defaire.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);
  late final ControleurSessionPersistante _controleur = ref.read(
    controleurSessionProvider,
  );
  late final HoteDockClasse _hoteDock = HoteDockClasse(
    sessionId: widget.contexte.sessionId,
    groupeId: widget.contexte.groupeId,
    profilId: _profil(),
    etatPartage: () =>
        ref.read(etatPartageClasseProvider(widget.contexte.sessionId)).value,
    selection: () => ref.read(selectionVersetProvider),
    salle: () => _salle,
    ouvrirBibliotheque: _ouvrirBibliotheque,
  );

  StreamSubscription<EtatSalle>? _sEtats;
  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<QualiteLien>? _sQualite;

  EtatSalle _etatMoteur = EtatSalle.absent;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  QualiteLien _qualite = QualiteLien.inconnue;
  bool _materielMesureBloque = false;
  bool _bibliothequeOuverte = false;
  bool _microEnCours = false;
  bool _cameraEnCours = false;
  bool _microErreur = false;
  bool _cameraErreur = false;
  String? _motPresentation;

  /// La salle telle que le dernier build l'a lue. Lue **a l'usage** par le
  /// dock et par la republication, jamais recalculee.
  VueSalle _salle = VueSalle.depuis(
    materielPret: false,
    acces: null,
    etatMoteur: EtatSalle.absent,
    participants: const <ParticipantSalle>[],
    qualite: QualiteLien.inconnue,
  );

  /// Les identites vues dans la salle, pour reconnaitre un arrivant.
  final Set<String> _identitesVues = <String>{};

  /// Un arrivant declenche une republication, une seule, apres un court
  /// silence : trois eleves qui entrent ensemble ne valent qu'une revision.
  final Debounce _republication = Debounce(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    _etatMoteur = _moteur.etatCourant;
    _sEtats = _moteur.etats.listen((EtatSalle etat) {
      // **Le seul endroit qui confirme le lien apres une suspension.**
      if (etat == EtatSalle.connecte || etat == EtatSalle.retabli) {
        _controleur.confirmerLien();
      }
      if (mounted) {
        setState(() => _etatMoteur = etat);
      }
    });
    _sParticipants = _moteur.participants.listen(_surParticipants);
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
    _republication.annuler();
    // **Aucun `quitter()` ici, et c'est l'invariant du lot E.** Le
    // proprietaire du cycle de vie est `ControleurSessionPersistante` ; lui
    // seul quitte, et seulement sur un geste explicite.
    super.dispose();
  }

  /// Lit son propre profil, **sous garde** : un conteneur de test sans backend
  /// n'a pas de session, et l'identite ne decide d'aucun droit.
  String? _profil() {
    try {
      return ref.read(sessionProvider).profileId;
    } on Object {
      return null;
    }
  }

  void _surParticipants(List<ParticipantSalle> liste) {
    // Un participant qui entre -- ou qui revient -- n'a pas l'etat partage.
    // Tant que la persistance serveur n'existe pas (voir
    // `CONTRACT_REQUEST_FABLE_CLASSROOM.md`), le pilote lui republie l'etat
    // courant : une revision complete, cause `restauration`, rien d'autre.
    // Ce n'est ni une presence ni un heartbeat : c'est la liste que le moteur
    // publie deja, lue une fois de plus.
    final bool arrivant = liste.any(
      (ParticipantSalle p) =>
          !p.estLocal && !_identitesVues.contains(p.identite),
    );
    _identitesVues
      ..clear()
      ..addAll(liste.map((ParticipantSalle p) => p.identite));
    if (mounted) {
      setState(() => _participants = liste);
    }
    if (arrivant && _salle.peutPresenter) {
      _republication.planifier(() => unawaited(_republier()));
    }
  }

  Future<void> _republier() async {
    try {
      await ref
          .read(presentateurClasseProvider)(widget.contexte.sessionId)
          .republier();
    } on Object catch (e) {
      // L'arrivant lira « aucun support » jusqu'au prochain geste : c'est dit
      // sur son ecran, pas ici.
      debugPrint('republication non aboutie : $e');
    }
  }

  /// Entre en salle, ou constate qu'on y est deja.
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
  /// lui qui annonce la sortie au serveur AVANT de deconnecter le moteur.
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
    // La decision de sortie se lit AVANT la deconnexion : apres, la phase est
    // retombee et « en salle » serait faux pour tout le monde.
    final SortieClasse sortie = SortieClasse(
      role: _salle.role,
      aEteEnSalle: _salle.dansLaSalle,
    );
    await _controleur.quitter();
    ref.read(recitationProvider.notifier).reinitialiser();
    ref.read(selectionVersetProvider.notifier).effacer();
    if (!mounted) {
      return;
    }
    widget.contexte.onSortie?.call(sortie);
  }

  Future<void> _voirRoster(RosterClasseVM roster) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.tc.classe.roster.titre,
        constructeur: (BuildContext _) => PanneauRoster(
          roster: roster,
          onOuvrirFiche: (String academyId) {
            // Deux feuilles empilees sur un telephone ne laisseraient plus rien
            // voir du cours : la premiere se referme avant la seconde.
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

  /// Ouvre la Bibliotheque **sans quitter la room** (decision D-20).
  ///
  /// Sur un ecran large, c'est un panneau lateral -- un etat de cette page.
  /// Sur telephone, une feuille modale, qui s'empile sans demonter la page.
  Future<void> _ouvrirBibliotheque() async {
    if (AppGabarit.de(context).estLarge) {
      setState(() => _bibliothequeOuverte = true);
      return;
    }
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: t.tc.classe.support.bibliotheque,
      constructeur: (BuildContext feuille) => _bibliotheque(
        enPanneau: false,
        fermer: () => Navigator.of(feuille).pop(),
      ),
    );
  }

  Widget _bibliotheque({
    required bool enPanneau,
    required VoidCallback fermer,
  }) => EmplacementBibliothequeEnClasse(
    slot: SlotClasse(
      sessionId: widget.contexte.sessionId,
      groupeId: widget.contexte.groupeId,
      contenu: widget.contexte.bibliotheque,
    ),
    enPanneau: enPanneau,
    onPresenterCoran: () {
      fermer();
      unawaited(_presenterCoran(null));
    },
    onChoisir: (LibraryResource ressource, ContentPosition? position) {
      fermer();
      if (ressource.resourceType == TypeRessource.quran) {
        unawaited(_presenterCoran(position));
        return;
      }
      // Seul le Coran est rendu dans la salle pour le moment : le dire au
      // pilote, sans le publier a une classe qui ne pourrait pas le lire.
      setState(() => _motPresentation = t.tc.classe.support.nonPrisEnCharge);
    },
  );

  /// Presente le Coran : a [position] si la Bibliotheque en donne une, sinon
  /// a la page que le pilote lit deja sur cet appareil.
  ///
  /// **Aucun toast de reussite** : le support apparait, et c'est evident.
  Future<void> _presenterCoran(ContentPosition? position) async {
    try {
      ContentPosition cible = position ?? await _positionCourante();
      if (cible.resourceId != identifiantRessourceCoran) {
        cible = await _positionCourante();
      }
      await ref
          .read(presentateurClasseProvider)(widget.contexte.sessionId)
          .presenter(resourceId: identifiantRessourceCoran, position: cible);
      if (mounted && _motPresentation != null) {
        setState(() => _motPresentation = null);
      }
    } on Object {
      if (mounted) {
        setState(() => _motPresentation = t.tc.classe.support.publicationEchec);
      }
    }
  }

  Future<ContentPosition> _positionCourante() async {
    final int page = ref.read(lectureCoranProvider).page;
    final PageMushafVM vue = await ref.read(pageMushafProvider(page).future);
    return vue.aDuTexte
        ? positionDe(vue).versContentPosition()
        : ContentPosition.page(
            resourceId: identifiantRessourceCoran,
            page: page,
          );
  }

  /// Ce que le dock a a dire a la classe : un focus devient une revision.
  void _surEvenementOutil(EvenementOutil evenement) {
    if (evenement is! EvenementFocus) {
      return;
    }
    unawaited(() async {
      try {
        await ref
            .read(presentateurClasseProvider)(widget.contexte.sessionId)
            .focaliser(evenement.plage);
      } on Object {
        if (mounted) {
          setState(
            () => _motPresentation = t.tc.classe.support.publicationEchec,
          );
        }
      }
    }());
  }

  Future<void> _basculerMicro(bool ouvert) async {
    setState(() {
      _microEnCours = true;
      _microErreur = false;
    });
    try {
      await _moteur.reglerMicro(actif: !ouvert);
    } on Object {
      _microErreur = true;
    } finally {
      if (mounted) {
        setState(() => _microEnCours = false);
      }
    }
  }

  Future<void> _basculerCamera(bool ouverte) async {
    setState(() {
      _cameraEnCours = true;
      _cameraErreur = false;
    });
    try {
      await _moteur.reglerCamera(actif: !ouverte);
    } on Object {
      _cameraErreur = true;
    } finally {
      if (mounted) {
        setState(() => _cameraEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ContexteClasseLive contexte = widget.contexte;
    final EtatSessionPersistante etat =
        ref.watch(etatSessionProvider).value ?? EtatSessionPersistante.aucun;

    // **Aucune capacite n'est calculee ici** : `VueSalle` les lit dans le jeton
    // signe, qui est la seule verite.
    final VueSalle salle = VueSalle.depuis(
      materielPret: etat.materielPret,
      acces: etat.acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse(etat),
    );
    _salle = salle;

    // L'annonce d'observation est lue par l'enseignant, et par lui seul : le
    // serveur refuserait de toute facon les autres (`annonces_observation`).
    final List<AnnonceObservation> annonces = salle.role == RoleSalle.enseignant
        ? ref.watch(annoncesObservationProvider(contexte.sessionId)).value ??
              const <AnnonceObservation>[]
        : const <AnnonceObservation>[];

    final RosterClasseVM roster = ref
        .watch(rosterClasseProvider(contexte.sessionId))
        .avecFile(ref.watch(recitationProvider))
        .avecSeuil(contexte.seuilMax);

    // Le support actif est celui que l'etat partage designe : c'est ce seul
    // fait qui fait basculer la composition (spec 9.1).
    final SharedContentState? partage = ref
        .watch(etatPartageClasseProvider(contexte.sessionId))
        .value;
    final SessionLiveVM session = SessionLiveVM(
      sessionId: contexte.sessionId,
      groupeId: contexte.groupeId,
      libelleGroupe: contexte.libelleGroupe,
      enseignant: contexte.enseignant,
      etatLien: _etatMoteur,
      horloge: etat.cours?.horloge ?? contexte.horloge,
      supportActifId: contexte.supportActifId ?? partage?.resourceId,
    );

    final Size taille = MediaQuery.sizeOf(context);
    final VueClasseLive vue = VueClasseLive.depuis(
      gabarit: AppGabarit.de(context),
      session: session,
      roster: roster,
      voitLeRoster: salle.voitLesParticipants,
      peutPiloterSupport: salle.peutPresenter,
      suspensionNonConfirmee: etat.retourDeSuspension,
      hauteurCourte: taille.height < VueClasseLive.seuilHauteurCourte,
    );

    // L'eleve lit SON etat de presence, et lui seul : derive par la base,
    // jamais recalcule ici (invariant J3 : indisponible se dit « inconnu »).
    final List<PresenceParticipant>? presence = ref
        .watch(presenceSeanceProvider(contexte.sessionId))
        .value;
    final VuePresence? mienne = salle.role == RoleSalle.eleve
        ? VuePresence.depuis(
            ligne: maPresence(presence, _profil()),
            maintenant: DateTime.now(),
          )
        : null;

    final bool enImpasse = salle.phase == PhaseSalle.refus;
    final bool enAttente =
        salle.phase == PhaseSalle.materiel ||
        salle.phase == PhaseSalle.ouverture ||
        salle.phase == PhaseSalle.connexion;

    final SlotClasse slotSupport = SlotClasse(
      sessionId: contexte.sessionId,
      groupeId: contexte.groupeId,
      resourceId: session.supportActifId,
      contenu: contexte.support,
    );

    return PageImmersive(
      registre: RegistreImmersif.salle,
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          EnteteClasse(
            session: session,
            vue: vue,
            roster: roster,
            annonces: annonces,
            // Le bouton compact n'existe que la ou le roster est replie.
            onVoirRoster: vue.placeRoster == PlaceRoster.feuille
                ? () => unawaited(_voirRoster(roster))
                : null,
          ),
          if (mienne != null) ...<Widget>[
            Ecart.vSm,
            LignePresence(nom: t.presence.mienne, vue: mienne),
          ],
          if (_motPresentation case final String mot) ...<Widget>[
            Ecart.vSm,
            StatusPill(libelle: mot, ton: TonEtat.avertissement),
          ],
        ],
      ),
      bandeau: enImpasse ? null : _Bandeaux(role: salle.role),
      commandes: enImpasse || enAttente
          ? null
          : CommandesClasse(
              salle: salle,
              preVol: ref.watch(preVolProvider).value,
              microEnCours: _microEnCours,
              cameraEnCours: _cameraEnCours,
              microErreur: _microErreur,
              cameraErreur: _cameraErreur,
              peutOuvrirBibliotheque: salle.peutPresenter,
              onBibliotheque: () => unawaited(_ouvrirBibliotheque()),
              onMicro: _basculerMicro,
              onCamera: _basculerCamera,
              onQuitter: () => unawaited(_quitter()),
            ),
      child: enImpasse || enAttente
          ? _Attente(
              phase: salle.phase,
              libelleGroupe: contexte.libelleGroupe,
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
              dockImpose: contexte.dock,
              hoteDock: _hoteDock,
              onEvenementOutil: _surEvenementOutil,
              bibliothequeOuverte: _bibliothequeOuverte,
              panneauBibliotheque: _bibliotheque(
                enPanneau: true,
                fermer: () => setState(() => _bibliothequeOuverte = false),
              ),
              onFermerBibliotheque: () =>
                  setState(() => _bibliothequeOuverte = false),
              onOuvrirFiche: (String id) => unawaited(_voirFiche(roster, id)),
            ),
    );
  }

  /// L'impasse, telle que l'usager doit la comprendre. Le materiel passe
  /// **devant** le refus du backend.
  CauseImpasse? _impasse(EtatSessionPersistante etat) {
    if (_materielMesureBloque) {
      return CauseImpasse.materiel;
    }
    final MotifRefusSalle? refus = etat.refus;
    return refus == null ? null : CauseImpasse.depuis(refus);
  }
}

/// Le bandeau permanent, et le rappel propre a qui observe.
///
/// Un SECOND bandeau, jamais une variante du premier : `PermanentNotice`
/// n'accepte aucun parametre, et c'est ce qui garantit qu'il affiche la meme
/// ligne pour tous les roles (ADR-011). Le rappel, lui, ne concerne que l'ecran
/// de qui observe -- controleur, tuteur, administration incognito (D-15 : la
/// visite est journalisee, et l'ecran le dit).
class _Bandeaux extends StatelessWidget {
  const _Bandeaux({required this.role});

  final RoleSalle role;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        switch (role) {
          RoleSalle.controleur => _Rappel(
            texte: t.salle.bandeauControle,
            ton: TonEtat.avertissement,
            icone: AppIcons.controleQualite,
          ),
          RoleSalle.administrateurIncognito => _Rappel(
            texte: t.tc.classe.rappel.adminIncognito,
            ton: TonEtat.avertissement,
            icone: AppIcons.observationIncognito,
          ),
          RoleSalle.tuteurObservateur => _Rappel(
            texte: t.salle.observationMuette,
            ton: TonEtat.accent,
            icone: AppIcons.microCoupe,
          ),
          RoleSalle.enseignant ||
          RoleSalle.eleve ||
          RoleSalle.administrateurVisible ||
          RoleSalle.inconnu => const SizedBox.shrink(),
        },
        const PermanentNotice(),
      ],
    );
  }
}

/// Une ligne de rappel pleine largeur, en registre doux. Reprise de la salle du
/// lot N3 : jamais un aplat, la seule zone pleine d'un ecran est son action
/// principale, et une salle n'en a pas.
class _Rappel extends StatelessWidget {
  const _Rappel({required this.texte, required this.ton, required this.icone});

  final String texte;
  final TonEtat ton;
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = switch (ton) {
      TonEtat.avertissement => palette.washWarning,
      TonEtat.accent ||
      TonEtat.neutre ||
      TonEtat.succes ||
      TonEtat.alerte => palette.washAccent,
    };
    final TextTheme textes = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: paire.decoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: paire.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(icone.repos),
            ),
            Ecart.hSm,
            Flexible(
              child: Text(
                texte,
                style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui occupe l'ecran avant d'etre en salle.
///
/// **Le pre-cours d'abord, l'attente ensuite.** L'enseignant voit son preflight
/// (spec 9.5) ; l'eleve ne voit rien tant que rien ne bloque, et lit a la place
/// ou en est l'entree. Calme : le nom du cours, un mot, rien a remplir.
class _Attente extends StatelessWidget {
  const _Attente({
    required this.phase,
    required this.libelleGroupe,
    required this.vue,
    required this.onReessayer,
  });

  final PhaseSalle phase;
  final String libelleGroupe;
  final VuePreCours vue;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
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
      // Le backend ne dit jamais pourquoi il refuse : un seul message, voulu.
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
              libelleGroupe,
              textAlign: TextAlign.center,
              style: textes.titleMedium ?? const TextStyle(),
            ),
            Ecart.vSm,
            Text(
              mot,
              textAlign: TextAlign.center,
              style: textes.bodyMedium ?? const TextStyle(),
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
///
/// [RESPONSIVE] Quatre compositions, decidees par `VueClasseLive` :
///
/// - **telephone portrait** : support plein, vignette en bande SOUS le support,
///   roster en feuille ;
/// - **paysage court** : support + vignette en colonne etroite a cote, roster
///   en feuille ;
/// - **tablette** : support (3) + bande de visages (1), roster en colonne pour
///   qui le voit ;
/// - **bureau** : roster | support | bande | Bibliotheque en panneau.
///
/// Sans support, la video EST le contenu : la scene prend toute la place que le
/// roster lui laisse, a tous les gabarits. Aucun cadre vide.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    required this.roster,
    required this.salle,
    required this.support,
    required this.dockImpose,
    required this.hoteDock,
    required this.onEvenementOutil,
    required this.bibliothequeOuverte,
    required this.panneauBibliotheque,
    required this.onFermerBibliotheque,
    required this.onOuvrirFiche,
  });

  final VueClasseLive vue;
  final RosterClasseVM roster;
  final VueSalle salle;
  final SlotClasse support;
  final WidgetBuilder? dockImpose;
  final HoteDockClasse hoteDock;
  final void Function(EvenementOutil evenement) onEvenementOutil;
  final bool bibliothequeOuverte;
  final Widget panneauBibliotheque;
  final VoidCallback onFermerBibliotheque;
  final void Function(String academyId) onOuvrirFiche;

  @override
  Widget build(BuildContext context) {
    final List<ParticipantSalle> distants = <ParticipantSalle>[
      if (salle.dominant case final ParticipantSalle premier) premier,
      ...salle.autres,
    ];
    final Widget scene = SceneClasse(
      participants: distants,
      poids: vue.poidsVideo,
    );

    Widget principal;
    if (vue.supportDomine) {
      Widget surface = SurfaceSupport(
        slot: support,
        peutPiloter: salle.peutPresenter,
      );
      // La selection d'un verset n'existe que pour qui pilote : hors de cette
      // portee, un tap sur le Coran ne fait rien de plus qu'avant.
      if (salle.peutPresenter) {
        surface = PorteeSelectionVerset(child: surface);
      }
      // **Le dock ne couvre pas le Coran** : `HoteDuDock` mesure le dock et
      // reserve exactement sa place. Il n'existe que pour qui peut piloter.
      principal = vue.dockFlottant
          ? HoteDuDock(
              contenu: surface,
              dock:
                  dockImpose?.call(context) ??
                  TeachingDock(hote: hoteDock, onEvenement: onEvenementOutil),
            )
          : surface;
    } else {
      principal = scene;
    }

    // Sur telephone, la vignette se pose SOUS le support, en bande : jamais
    // par-dessus, et jamais en colonne qui rognerait le texte.
    if (vue.poidsVideo == PoidsVideo.vignette && !vue.vignetteLaterale) {
      principal = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: principal),
          SizedBox(
            height: AppSpacing.respiration * 1.5,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.lg,
                top: AppSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AspectRatio(aspectRatio: 4 / 3, child: scene),
              ),
            ),
          ),
        ],
      );
    }

    final Widget colonneRoster = SizedBox(
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

    // Echap ferme le panneau : un panneau qu'on ne peut fermer qu'a la souris
    // n'est pas un panneau de bureau (Bible section 13.4).
    final Widget panneau = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onFermerBibliotheque,
      },
      child: FocusScope(
        child: SizedBox(
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
                Expanded(child: panneauBibliotheque),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le roster est **secondaire** : etroit, jamais a la place du support.
        if (vue.placeRoster == PlaceRoster.colonne) colonneRoster,
        Expanded(flex: 3, child: principal),
        // La video en bande a cote du support garde de quoi reconnaitre qui
        // parle, pas une part de l'ecran.
        if (vue.poidsVideo == PoidsVideo.bande)
          Expanded(child: scene)
        else if (vue.poidsVideo == PoidsVideo.vignette && vue.vignetteLaterale)
          SizedBox(
            width: AppSpacing.respiration * 2.5,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.topCenter,
                child: AspectRatio(aspectRatio: 4 / 3, child: scene),
              ),
            ),
          ),
        if (bibliothequeOuverte) panneau,
      ],
    );
  }
}
