import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/age_eleve.dart';
import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/coran/service_coran.dart'
    show pageCoranProvider, pagesMushafMedine;
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_classe/controleur_recitation.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/commande_salle.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/offline_banner.dart' show ReserveCoinFin;
import '../../core/widgets/ornement_marque.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_eleve/apres_seance_accessibilite.dart';
import '../controleur/compte_rendu_controle.dart' show adresseCompteRendu;
import '../fiche_groupe/preparation_seance.dart';
import '../salle_enseignant/page_coran_salle.dart';
import '../salle_enseignant/panneau_enseignant.dart';
import '../salle_enseignant/presentation_coran.dart'
    show contenuPresenteProvider, presentateurCoranProvider;
import '../salle_seance/actions_seance.dart';
import '../salle_seance/depuis_salle.dart';
import '../salle_seance/ecriture_seance.dart'
    show
        diffusionEcritureProvider,
        diffusionPointeurProvider,
        pointeurDistantProvider;
import '../salle_seance/media_salle.dart';
import '../salle_seance/notes_deposees.dart';
import '../salle_seance/presentation_observee.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/vue_seance.dart';
import '../salle_seance/zone_support.dart';
import '../tc_espace_groupe/roster_classe.dart';
import '../tc_mes_groupes/chemins_tc_a.dart';
import '../tc_observation_ui/indicateur_observation.dart';
import 'fiche_seance.dart';
import 'memoire_page_classe.dart';
import 'preparation_eleve.dart';
import 'preparation_enseignant.dart';
import 'synchro_salle.dart';
import 'vue_salle.dart';

/// `ELV-03`, `ENS-03`, `CTR-02` : la salle.
///
/// **Un seul ecran pour trois codes, et pour quatre roles.** Ce qui les
/// distingue n'est pas le role du compte, que le client porte, mais le jeton
/// emis par `create-room-token` : son `role` et ses capacites signees. Un ecran
/// qui se fierait a `sessionProvider` promettrait des commandes que le serveur
/// LiveKit refuserait ensuite, et trois ecrans separes auraient fini par
/// divergerer sur le bandeau permanent -- ce que l'ADR-011 interdit.
///
/// Ce que cet ecran ne fait pas, et ou cela vit a la place :
///
/// - il **n'ecrit aucun appel reseau video** : tout passe par `lib/core/video/`,
///   et il n'importe pas `livekit_client` ;
/// - il **ne calcule aucun etat de presence** : les quatorze etats sont derives
///   en base par `etat_presence()` et lus par `presence_seance_v`, bornee a ce
///   que l'appelant a le droit de savoir. L'ecran les **montre**, il ne les
///   decide pas -- et il ne dit jamais « absent » quand il ne sait pas
///   (invariant J3) ;
/// - il **ne presente aucun contenu lui-meme** : le transport existe depuis le
///   20 septembre 2026 -- `ContenuPresente`, `VideoSessionProvider.presenterContenu`
///   et `contenusPresentes`, sur le canal de donnees LiveKit -- mais la surface
///   qui l'emploie est celle de l'enseignant (`lib/features/salle_enseignant/`),
///   posee par-dessus cet ecran en un seul point. Le bouton « Ouvrir le Coran »
///   n'existe donc toujours pas ici, plutot que d'etre grise.
///
/// TB-11a (plan V2 §5, UX-21) : le tuteur observateur et le controleur
/// **lisent** la presentation de l'enseignant (support, page, affichage,
/// notes) par la surface partagee de la salle de seance (`ZoneSupport`), sans
/// aucune commande d'ecriture, de page ou de rangement. La donnee vient de
/// `presentationObserveeProvider` (non branchee avant TB-BR : la salle garde
/// alors sa scene).
class SallePage extends ConsumerStatefulWidget {
  /// Cree la salle pour une seance.
  const SallePage({
    required this.seanceId,
    super.key,
    this.preparation = false,
    this.groupeId,
    this.eleveId,
    this.cheminCompteRenduControle = Routes.controleurCompteRendu,
  });

  /// La page du Coran que l'eleve lit en salle (D9).
  static const Key pageEleveKey = ValueKey<String>('salle-page-eleve');

  /// L'eleve qui rejoint la salle depuis l'appareil de son tuteur (D6), lu
  /// dans le billet ; `null` quand la personne connectee entre pour elle-meme.
  final String? eleveId;

  /// La sortie du controleur (CTR-02 vers CTR-03, P-CTR-03 point 12). La
  /// demonstration la redirige vers son compte rendu fictif.
  final String cheminCompteRenduControle;

  /// Montrer d'abord la preparation de l'enseignant (CLV-03, CL-4.5). Vrai
  /// seulement depuis « Preparer l'entree » : rien n'est connecte avant
  /// « Entrer dans la classe ».
  final bool preparation;

  /// La classe d'origine, pour « Retour a la Classe » et le contexte.
  final String? groupeId;

  /// La tuile « Coran » du choix des supports (lot salle 2).
  static const Key supportCoranKey = ValueKey<String>('salle-support-coran');

  /// La seance visee, lue dans le billet d'entree (ADR-005). Elle ne transite
  /// jamais par l'URL : une adresse copiee arrive sans billet et repart.
  final String seanceId;

  @override
  ConsumerState<SallePage> createState() => _SallePageEtat();
}

class _SallePageEtat extends ConsumerState<SallePage> {
  /// Le moteur, capture une fois.
  ///
  /// Capture et non relu dans `dispose` : un `ref.read` au demontage arrive
  /// apres que le conteneur a commence a se defaire, et c'est precisement la
  /// que la liberation des pistes doit encore fonctionner.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);

  StreamSubscription<EtatSalle>? _sEtats;
  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<QualiteLien>? _sQualite;

  bool _materielPret = false;

  /// La preparation de l'enseignant est a l'ecran : rien n'est connecte.
  bool _enPreparation = false;

  /// Vrai pour qui suit le cours : l'eleve, et le compte adulte dont le
  /// serveur sert la capacite « eleve autonome » (EA-ROLE-1, C-24). Un
  /// tuteur seul reste observateur, sans preparation (D-14).
  static bool _suitLesCours(SessionState s) =>
      s.role == AppRole.student ||
      (s.role == AppRole.guardian && s.eleveAutonome);

  /// L'eleve a choisi « Continuer sans micro » (PRE-ERR-01, CL-4.6) : le
  /// micro reste coupe, le blocage materiel ne l'arrete plus.
  bool _sansMicro = false;
  AccesSalle? _acces;
  CauseImpasse? _impasse;
  EtatSalle _etatMoteur = EtatSalle.absent;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  QualiteLien _qualite = QualiteLien.inconnue;

  /// La fin de l'enseignant qui a fait cours (CLV-10), figee a la sortie :
  /// le recapitulatif lit la presence d'AVANT la deconnexion (I-6).
  VueSeance? _finEnseignant;

  /// Le cahier n'a pas pu etre ouvert depuis CLV-10 : « Reessayer ».
  bool _cahierIndisponible = false;

  /// L'eleve sorti de la salle (CLV-09).
  IssueSeance? _sortieEleve;

  /// Lot salle 2 : la page retenue pour la classe a deja ete reprise a cette
  /// entree (une seule fois ; l'enseignant change ensuite librement).
  bool _repriseFaite = false;

  /// S0 : l'etat local de la salle de seance (rien n'est diffuse) : zoom de
  /// la page (paliers 100 a 200 %), page agrandie, panneau et contexte.
  double _zoom = paliersZoom.first;
  bool _agrandi = false;
  PanneauOuvert _panneau = PanneauOuvert.aucun;
  ContexteOuvert _contexte = ContexteOuvert.aucun;

  /// S0.3 : l'enseignant a ouvert le tableau blanc (ferme par defaut).
  bool _tableau = false;

  /// S1 : la synchronisation de l'ecriture de cette seance, creee a la
  /// premiere composition dans la salle, liberee a la sortie.
  SynchroSalle? _synchro;

  /// La synchronisation, raccordee au jeton courant, ou `null` (pas de jeton
  /// ou profil inconnu).
  SynchroSalle? _synchroPour(String? profil) {
    final AccesSalle? acces = _acces;
    if (acces == null || profil == null) return null;
    final SynchroSalle? existante = _synchro;
    if (existante != null && existante.sessionId == widget.seanceId) {
      return existante;
    }
    unawaited(existante?.liberer());
    final SynchroSalle neuve = SynchroSalle(
      moteur: _moteur,
      acces: acces,
      sessionId: widget.seanceId,
      profilLocalId: profil,
    );
    // L'eleve suit le tableau que l'enseignant ouvre ou ferme.
    neuve.tableauOuvert.addListener(() {
      if (mounted) setState(() {});
    });
    return _synchro = neuve;
  }

  /// D14 (S0) : le dernier refus d'allumer la camera, tel que le navigateur
  /// l'a dit, ou `null`.
  String? _erreurCamera;

  /// S0 : la scene video au premier plan, choisie d'un toucher ; `null` :
  /// automatique (l'eleve sans page presentee la voit en grand).
  bool? _scenePremierPlan;

  // CTRL-AGRANDIR-1 (releve VERIF-CT-1) : pas de commande « Agrandir le
  // support » dans la salle du controleur tant qu'aucun support n'y est
  // rendu. Elle agrandissait l'enseignant (la personne dominante), pas un
  // support. Elle reviendra avec le rendu du support partage.

  // CTRL-SON-1 (decision du directeur C5 = a) : pas de commande « Son reçu »
  // dans la salle du controleur jusqu'a BR-1. Une bascule locale changeait le
  // mot sans rien couper ; le moteur doit d'abord savoir couper la lecture
  // des pistes recues (ligne BR de CT-BR.md).

  @override
  void initState() {
    super.initState();
    // On ecoute AVANT d'entrer : le moteur publie son premier etat pendant
    // `rejoindre`, et un abonnement pose apres manquerait la connexion.
    _sEtats = _moteur.etats.listen((EtatSalle etat) {
      if (mounted) {
        setState(() => _etatMoteur = etat);
      }
    });
    _sParticipants = _moteur.participants.listen((
      List<ParticipantSalle> liste,
    ) {
      if (mounted) {
        setState(() => _participants = liste);
      }
    });
    _sQualite = _moteur.qualite.listen((QualiteLien lien) {
      if (mounted) {
        setState(() => _qualite = lien);
      }
    });
    // Le tuteur observateur n'a AUCUNE preparation (D-14) : il n'ouvre ni
    // micro ni camera.
    // Seuls l'eleve et l'enseignant en ont une ; session pas encore lue
    // (role nul) : le choix se refait au `build`.
    final SessionState session0 = ref.read(sessionProvider);
    final AppRole? role = session0.role;
    _enPreparation =
        widget.preparation &&
        (role == null || _suitLesCours(session0) || role == AppRole.teacher);
    if (!_enPreparation) {
      unawaited(_entrer());
    }
  }

  @override
  void dispose() {
    unawaited(_sEtats?.cancel());
    unawaited(_sParticipants?.cancel());
    unawaited(_sQualite?.cancel());
    unawaited(_synchro?.liberer());
    // Quitter au demontage, quelle que soit la raison du demontage : un retour
    // navigateur, une redirection, un billet expire. Sans cela, une salle
    // fermee a l'ecran continuerait a publier un micro ouvert.
    unawaited(_moteur.quitter());
    super.dispose();
  }

  /// Les trois temps de l'entree : le materiel, le jeton, la salle.
  ///
  /// Le pre-vol vient **avant** le jeton, et l'ordre n'est pas une preference :
  /// une salle qui echoue apres etre entree laisse deux personnes dedans dont
  /// l'une est muette sans savoir pourquoi. Verifier le micro pendant que l'on
  /// est encore seul devant son ecran coute une seconde et evite cela.
  Future<void> _entrer() async {
    setState(() {
      _repriseFaite = false;
      _impasse = null;
      _materielPret = false;
      _acces = null;
    });

    // **Un seul chemin vers le pre-vol dans tout le produit** : `preVolProvider`.
    // Deux existaient -- ce provider, que personne n'employait, et un appel
    // imperatif a `servicePreVolProvider` -- et un ecran de plus en aurait
    // choisi un au hasard. `refresh` et non `read` : le materiel a pu changer
    // depuis la derniere mesure, et un casque branche apres un « Reessayer » ne
    // servirait a rien si l'on relisait une valeur en cache.
    //
    // CTRL-PREVOL-1 (releve VERIF-CT-1, P-CTR-03 point 4, R8, R13) : le micro
    // n'est exige que de qui parle. Le controleur, le tuteur temoin et
    // l'administration en observation entrent muets : leur jeton le leur
    // impose. Un compte qui n'est ni eleve ni enseignant n'est donc pas
    // mesure avant le jeton (aucune demande de permission injustifiee, comme
    // `DetailPreCours.aucun`) ; c'est le jeton qui dit ensuite s'il parlera
    // (l'administration visible, elle, a le micro et repasse par le pre-vol).
    // Un compte illisible reste traite comme qui parle : le repli est ferme.
    final AppRole? compte = await _roleDuCompte();
    if (!mounted) {
      return;
    }
    final bool observateur =
        compte != null &&
        !_suitLesCours(ref.read(sessionProvider)) &&
        compte != AppRole.teacher;
    if (!observateur) {
      final ResultatPreVol mesure = await ref.refresh(preVolProvider.future);
      if (!mounted) {
        return;
      }
      if (!mesure.peutEntrer && !_sansMicro) {
        setState(() => _impasse = CauseImpasse.materiel);
        return;
      }
    }
    setState(() => _materielPret = true);

    final AccesSalle acces;
    try {
      acces = await ref
          .read(serviceVideoProvider)
          .acces(widget.seanceId, eleveId: widget.eleveId);
    } on EchecSalle catch (echec) {
      if (mounted) {
        setState(() => _impasse = CauseImpasse.depuis(echec.motif));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    // Le jeton tranche pour l'observateur presume (l'administration peut
    // entrer visible, micro permis) : s'il autorise la voix, le micro
    // redevient exige, avant toute connexion.
    if (observateur && acces.capacites.peutPublier) {
      final ResultatPreVol mesure = await ref.refresh(preVolProvider.future);
      if (!mounted) {
        return;
      }
      if (!mesure.peutEntrer) {
        setState(() => _impasse = CauseImpasse.materiel);
        return;
      }
    }
    setState(() => _acces = acces);

    try {
      await _moteur.rejoindre(acces);
    } catch (erreur) {
      // Le moteur a deja pose son etat d'echec et tout libere ; il ne reste
      // qu'a nommer la cause pour l'usager. Aucun detail technique ne remonte
      // a l'ecran : « ICE failed » ne se lit pas devant un enfant.
      journalDev('entree en salle impossible : $erreur');
      if (mounted) {
        setState(() => _impasse = CauseImpasse.reseau);
      }
    }
  }

  /// Le role du compte, une fois la session lue.
  ///
  /// L'entree part de `initState`, ou la session peut n'etre pas encore lue :
  /// decider sur un role absent ferait d'un controleur un eleve (bloque sans
  /// micro), ou l'inverse. On attend donc la premiere session resolue.
  Future<AppRole?> _roleDuCompte() async {
    final SessionState lue = ref.read(sessionProvider);
    if (lue.resolue) {
      return lue.role;
    }
    final Completer<AppRole?> resolue = Completer<AppRole?>();
    final ProviderSubscription<SessionState> abonnement = ref
        .listenManual<SessionState>(sessionProvider, (
          SessionState? _,
          SessionState etat,
        ) {
          if (etat.resolue && !resolue.isCompleted) {
            resolue.complete(etat.role);
          }
        });
    try {
      return await resolue.future;
    } finally {
      abonnement.close();
    }
  }

  /// La sortie volontaire, confirmee une fois.
  ///
  /// [vue] est passee plutot que relue : la decision de sortie se prend sur
  /// l'etat d'AVANT la deconnexion. Apres `_moteur.quitter()`, la phase est
  /// retombee et `dansLaSalle` serait faux pour tout le monde.
  ///
  /// [confirme] : la question a deja ete posee (le dock de la salle de
  /// seance, `confirmerQuitterSeance`).
  Future<void> _quitter(VueSalle vue, {bool confirme = false}) async {
    if (vue.role == RoleSalle.controleur) {
      return _quitterControle();
    }
    final bool accepte =
        confirme ||
        await ConfirmDestructive.demander(
          context,
          question: t.salle.confirmerSortie,
          consequence: t.salle.consequenceSortie,
          libelleConfirmer: t.salle.quitterLeCours,
        );
    if (!accepte || !mounted) {
      return;
    }

    // Le cours a-t-il eu lieu ? La reponse se lit maintenant, pas apres.
    final bool versLeCahier =
        vue.role == RoleSalle.enseignant && vue.dansLaSalle;
    final bool eleveSorti = vue.role == RoleSalle.eleve && vue.dansLaSalle;
    // CLV-10 : le recapitulatif se fige maintenant, sur la presence deja lue
    // (aucun nouvel appel) ; apres la deconnexion, elle ne dirait plus rien.
    final VueSeance? fin = versLeCahier
        ? DepuisSalle.vue(
            salle: vue,
            mode: AppMetriques.of(context).mode,
            presence: ref.read(presenceSeanceProvider(widget.seanceId)).value,
            monProfil: ref.read(sessionProvider).profileId,
            fin: FinSeance(
              heureFin: DepuisSalle.heure(DateTime.now()),
              cahierACompleter: true,
            ),
          )
        : null;

    // **L'annonce precede la deconnexion, et cet ordre porte une information
    // que rien d'autre ne porte.** LiveKit envoie le meme evenement `left` dans
    // les deux cas ; seule cette ecriture distingue une sortie volontaire d'une
    // perte de reseau. Annoncer apres s'etre deconnecte laisserait le webhook
    // arriver le premier et inscrire une deconnexion.
    await ref.read(serviceVideoProvider).annoncerSortie(widget.seanceId);
    await _moteur.quitter();
    unawaited(_synchro?.liberer());
    _synchro = null;
    if (!mounted) {
      return;
    }
    if (fin != null) {
      // CLV-10 d'abord, puis le cahier : « Ouvrir le cahier » (`_ouvrirCahier`).
      setState(() => _finEnseignant = fin);
      return;
    }
    if (versLeCahier) {
      _ouvrirCahier();
      return;
    }
    if (eleveSorti) {
      // CLV-09 : « Vous avez quitte la seance. » (guidee : « La seance est
      // terminee. »), puis le retour a la racine de son role.
      setState(() => _sortieEleve = IssueSeance.quittee);
      return;
    }
    _rentrer();
  }

  /// CTR-02 : la sortie du controleur, sans fenetre de confirmation
  /// (UX_REVIEW_08 n° 4 d : une sortie normale, sans consequence serieuse).
  /// Elle mene au compte rendu (CTR-03) ; sa transmission automatique au
  /// depart vient avec CT-4.
  Future<void> _quitterControle() async {
    await ref.read(serviceVideoProvider).annoncerSortie(widget.seanceId);
    await _moteur.quitter();
    if (!mounted) {
      return;
    }
    // La visite voyage par l'adresse (`?seance=`) : le compte rendu porte
    // sur CETTE seance, jamais sur la mission courante (revue CT-R B1).
    GoRouter.of(
      context,
    ).go(adresseCompteRendu(widget.cheminCompteRenduControle, widget.seanceId));
  }

  /// **L'invariant du catalogue est tenu** : la sortie de `ENS-03` mene a
  /// `ENS-04` (via CLV-10) et a rien d'autre. `go` et non `push` : la salle
  /// ne doit rester sous aucune pile, l'ADR-005 lui interdit d'etre revenue
  /// en arriere.
  ///
  /// `go` ne leve rien pour une adresse inconnue : il afficherait la page
  /// d'erreur du routeur. Le chemin est donc **verifie avant** d'y aller
  /// ([cheminCahierOuvrable]) ; sans seance ou sans route, CLV-10 reste
  /// affiche avec son message et « Reessayer ».
  void _ouvrirCahier() {
    final GoRouter routeur = GoRouter.of(context);
    final String? chemin = cheminCahierOuvrable(
      routeur.configuration,
      widget.seanceId,
    );
    if (chemin == null) {
      journalDev('cahier impossible a ouvrir : ${widget.seanceId}');
      setState(() => _cahierIndisponible = true);
      return;
    }
    routeur.go(chemin);
  }

  /// « Retour a la Classe » de CLV-09 (eleve standard, matrice section 5) :
  /// l'espace des Classes de l'eleve (`/tc/groupes`, CLV-01 partiel), et non
  /// l'accueil. La guidee garde « Retour a l'accueil » et sa racine.
  void _retourClasse() {
    if (AppMetriques.of(context).mode == InterfaceMode.enfant) {
      _rentrer();
      return;
    }
    GoRouter.of(context).go(Routes.tcGroupes);
  }

  /// D10 : l'enseignant sorti retourne dans la meme salle, par le meme
  /// chemin que l'entree (pre-vol, jeton, salle). Le serveur seul dit si la
  /// seance est close (« salle fermee » : l'impasse le dit).
  void _retournerDansLaSalle() {
    setState(() {
      _finEnseignant = null;
      _cahierIndisponible = false;
    });
    unawaited(_entrer());
  }

  /// Retour a la racine de son role.
  ///
  /// C'est la sortie de qui n'a rien a transmettre : les trois autres roles, et
  /// l'enseignant qui n'est jamais entre -- une impasse ou un abandon pendant la
  /// connexion. Envoyer celui-la au cahier lui demanderait le compte rendu d'un
  /// cours qui n'a pas eu lieu.
  void _rentrer() {
    final AppRole? role = ref.read(sessionProvider).role;
    GoRouter.of(context)
        .go(role == null ? Routes.racine : Routes.racinePour(role));
  }

  Future<void> _basculerMicro(bool ouvert) =>
      _moteur.reglerMicro(actif: !ouvert);

  /// D14 (S0) : un allumage qui echoue n'est plus silencieux. La phrase
  /// exacte du navigateur s'affiche sous l'en-tete, avec sa cause probable et
  /// quoi faire (K-59) ; un essai reussi l'efface.
  Future<void> _basculerCamera(bool ouverte) async {
    try {
      await _moteur.reglerCamera(actif: !ouverte);
      if (mounted && _erreurCamera != null) {
        setState(() => _erreurCamera = null);
      }
    } on Object catch (erreur) {
      journalDev('camera : $erreur');
      if (mounted) setState(() => _erreurCamera = '$erreur');
    }
  }

  /// Point 7 de la passation du 17/10 (spec section 10) : les eleves de la
  /// seance, pour l'enseignant, en feuille ; toucher un eleve ouvre sa fiche
  /// pedagogique. La feuille du roster se referme avant d'ouvrir la fiche :
  /// deux feuilles empilees sur un telephone ne laisseraient rien voir du
  /// cours.
  ///
  /// S0.2 : depuis l'en-tete sur une ligne de la salle de seance, la meme
  /// feuille porte d'abord la presence ([lignes], J3), puis le roster.
  Future<void> _voirEleves({List<_Presence>? lignes}) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.tc.classe.roster.titre,
        constructeur: (BuildContext feuille) => Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            final Widget roster = PanneauRoster(
              roster: _roster(ref),
              onOuvrirFiche: (String academyId) {
                Navigator.of(feuille).pop();
                unawaited(_voirFiche(academyId));
              },
            );
            final List<_Presence>? presence = lignes;
            if (presence == null) return roster;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ListePresence(lignes: presence, entete: true),
                Ecart.vLg,
                roster,
              ],
            );
          },
        ),
      );

  Future<void> _voirFiche(String academyId) {
    final TeacherStudentProjection? eleve = _roster(ref)
        .parAcademyId(academyId);
    if (eleve == null) {
      return Future<void>.value();
    }
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: eleve.firstName,
      constructeur: (BuildContext _) =>
          FicheSeance(eleve: eleve, sessionId: widget.seanceId),
    );
  }

  /// Le roster pedagogique de la seance, avec la file de recitation.
  RosterClasseVM _roster(WidgetRef ref) => ref
      .watch(rosterClasseProvider(widget.seanceId))
      .avecFile(ref.watch(recitationProvider));

  /// Ouvre la presence en feuille, pour qui n'a pas la place de la garder
  /// ouverte a cote de la scene.
  Future<void> _voirPresence(List<_Presence> lignes) => AppBottomSheet.ouvrir(
    context,
    titre: t.presence.titre,
    constructeur: (BuildContext _) => _ListePresence(lignes: lignes),
  );

  /// S0 : la salle de seance, ses rappels et ses medias reels.
  Widget _salleDeSeance(
    VueSalle vue,
    VueSeance base,
    ContenuPresente? presentee, {
    required List<_Presence> lignes,
    required VuePresence mienne,
  }) {
    final bool enseignant = base.role == RoleSeance.enseignant;
    final SynchroSalle? synchro = _synchroPour(
      ref.read(sessionProvider).profileId,
    );
    // S0.3 : le tableau blanc, ouvert par l'enseignant pour toute la classe,
    // prend la place de la page (le tableau libre existant).
    final bool tableau = enseignant
        ? _tableau
        : (synchro?.tableauOuvert.value ?? false);
    final VueSeance seance = tableau
        ? base.copyWith(
            panneau: _panneau,
            contexte: _contexte,
            sansSupportPresente: true,
            // K4 : la forme fixe de la classe (16:9), ajustee sans
            // etirement sur chaque appareil.
            tableauLibre: TableauLibre.classe,
          )
        : base.copyWith(panneau: _panneau, contexte: _contexte);
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final double? plus = palierSuivant(_zoom);
    final double? moins = palierPrecedent(_zoom);
    final ParticipantSalle? moi = vue.moi;
    final int? page = presentee?.page;
    final ActionsSeance actions = ActionsSeance(
      // Le dock de la salle de seance confirme deja la sortie
      // (`confirmerQuitterSeance`) : une seule question.
      onQuitter: () => unawaited(_quitter(vue, confirme: true)),
      // Les commandes suivent le jeton (`peutParler`, `peutMontrer`), jamais
      // le mode d'interface ; pas de bouton sans droit (jamais grise).
      onMicro: vue.peutParler
          ? () => unawaited(_basculerMicro(moi?.micro ?? false))
          : null,
      onCamera: vue.peutMontrer
          ? () => unawaited(_basculerCamera(moi?.camera ?? false))
          : null,
      onAgrandir: () => setState(() => _agrandi = !_agrandi),
      onZoomPlus: plus == null ? null : () => setState(() => _zoom = plus),
      onZoomMoins: moins == null ? null : () => setState(() => _zoom = moins),
      // B' : un seul affichage, « Avec notes » ; aucun bouton d'affichage.
      onAffichage: null,
      onCommandes: enseignant
          ? () => _basculerPanneau(PanneauOuvert.commandes)
          : null,
      // S0.2 : la colonne Eleves de la salle de seance est repliee d'office
      // hors ordinateur.
      // Le panneau Eleves (colonne, ou panneau sur telephone) porte la
      // presence (J3) et le roster reel (fiche, rappel discret).
      onEleves: enseignant
          ? () => _basculerPanneau(PanneauOuvert.eleves)
          : null,
      // La Bibliotheque des Commandes (et la touche B) ouvre le Coran : une
      // autre sourate se presente a tout moment, comme depuis l'ancien
      // panneau.
      // S0.3 : le tableau blanc, ferme par defaut, ouvert pour la classe.
      onTableau: enseignant && synchro != null
          ? () => setState(() {
              _tableau = !_tableau;
              synchro.diffuserTableau(ouvert: _tableau);
            })
          : null,
      // S1 : « Ecrire » et la gomme de l'enseignant ; l'outil s'arme dans
      // `etatOutilsProvider`, l'encre part a la classe (SynchroSalle).
      onOutil: enseignant ? (OutilEnseignement _) {} : null,
      onBibliotheque: enseignant && vue.peutPresenter
          ? () => unawaited(_choisirSupport())
          : null,
      onContexte: (ContexteOuvert c) => setState(() {
        _contexte = c;
        if (c != ContexteOuvert.aucun && _panneau == PanneauOuvert.commandes) {
          _panneau = PanneauOuvert.aucun;
        }
      }),
      // D9 : la page tourne pour toute la classe, par le canal de donnees.
      onPagePrecedente: enseignant && page != null && page > 1
          ? () => unawaited(
              ref.read(presentateurCoranProvider).presenterPage(page - 1),
            )
          : null,
      onPageSuivante: enseignant && page != null && page < pagesMushafMedine
          ? () => unawaited(
              ref.read(presentateurCoranProvider).presenterPage(page + 1),
            )
          : null,
    );
    // La scene en grand : choisie, sinon chez l'eleve tant que rien n'est
    // presente. Le bouton de retour n'existe que si une page (ou le panneau
    // de l'enseignant) attend derriere.
    // Rien de presente : la scene en grand pour tous (les visages, ADR-001) ;
    // une page presentee prend l'espace principal, la video revient en
    // vignette, et la toucher remet la scene en grand.
    final bool scenePremierPlan =
        !tableau && (_scenePremierPlan ?? presentee == null);
    final bool basculable = presentee != null || tableau;
    return PorteeMediaSalle(
      // S0.2 : l'en-tete tient sur une ligne ; la presence de l'eleve y
      // passe en pastille (section 6.6, la sienne seulement) ; la liste de
      // l'enseignant est sa colonne Eleves.
      pleinCadre: true,
      // Au telephone, l'enseignant n'a pas de colonne : « Eleves » ouvre la
      // presence (J3) et le roster (fiche, rappel) en feuille.
      pastille: enseignant ? null : _PastillePresence(mienne: mienne),
      // Standard des commandes d'appel : l'enseignant n'a pas de colonne (K4,
      // 25/10/2026 : ni au telephone ni sur ordinateur) ; le bouton rond
      // « Eleves » ouvre la presence (J3) et le roster (fiche, rappel) en
      // feuille.
      boutonEleves: enseignant
          ? (
              nombre: lignes.length,
              onPress: () => unawaited(_voirEleves(lignes: lignes)),
            )
          : null,
      eleves: enseignant
          ? _ElevesSeance(
              lignes: lignes,
              roster: _roster(ref),
              onOuvrirFiche: (String academyId) =>
                  unawaited(_voirFiche(academyId)),
            )
          : null,
      // D14 : effacee des que la camera publie.
      alerte: (moi?.camera ?? false)
          ? null
          : switch (_erreurCamera ?? _moteur.erreurCameraEntree) {
              final String erreur => _ErreurCamera(erreur: erreur),
              null => null,
            },
      scene: _Scene(
        vue: vue,
        attendu: enseignant ? null : seance.nomEnseignant,
      ),
      scenePremierPlan: scenePremierPlan,
      onBasculerScene: basculable
          ? () => setState(() => _scenePremierPlan = !scenePremierPlan)
          : null,
      // L'enseignant sans page ouvre le Coran depuis la scene : la page
      // choisie prend aussitot l'espace principal.
      actionScene: enseignant && presentee == null && vue.peutPresenter
          ? (
              libelle: t.salle.ouvrirCoran,
              onPress: () => unawaited(_ouvrirCoran()),
            )
          : null,
      video: moteur.renduVideo,
      // L'enseignant chez l'eleve ; sa propre image chez l'enseignant.
      identiteVignette: enseignant ? moi?.identite : vue.dominant?.identite,
      // L'enseignant garde les etats de lecture de son panneau (page
      // indisponible, texte non installe) ; l'eleve lit la page (D9).
      page: (SupportPageFixe support) => enseignant && presentee != null
          ? PageCoranPresentee(contenu: presentee, surCarte: true)
          : PageCoranSalle(
              key: SallePage.pageEleveKey,
              numero: support.page,
              surCarte: true,
            ),
      onZoom: (double z) => setState(() => _zoom = z),
      // Reference 4 : les grandes fleches de part et d'autre de la page.
      onPagePrecedente: actions.onPagePrecedente,
      onPageSuivante: actions.onPageSuivante,
      child: _AvecSynchro(
        synchro: synchro,
        child: SalleSeance(
          key: const ValueKey<String>('salle-de-seance'),
          vue: seance,
          actions: actions,
          local: EtatLocalSeance(
            microOuvert: moi?.micro ?? false,
            cameraAllumee: moi?.camera ?? false,
            zoom: _zoom,
            agrandi: _agrandi,
          ),
        ),
      ),
    );
  }

  /// S0 : la bibliotheque du Coran, puis la page presentee a la classe ;
  /// la scene cede la place a la page.
  /// Lot salle 2 (directeur, 25/10/2026) : la Bibliotheque montre le choix
  /// des supports (aujourd'hui le Coran seul, d'autres viendront) au lieu
  /// d'ouvrir le Coran d'office. Le Coran reprend a la derniere page
  /// presentee dans la classe, sinon le choix de la sourate et du verset.
  Future<void> _choisirSupport() async {
    final bool coran =
        await AppBottomSheet.ouvrir<bool>(
          context,
          titre: t.salle.supports.titre,
          constructeur: (BuildContext feuille) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarteLignes(
                lignes: <Widget>[
                  SettingRow(
                    key: SallePage.supportCoranKey,
                    icon: AppIcons.coran,
                    title: t.salle.supports.coran,
                    description: t.salle.supports.coranDetail,
                    lien: true,
                    onPress: () => Navigator.of(feuille).pop(true),
                  ),
                ],
              ),
              Ecart.vLg,
              Text(
                t.salle.supports.aVenir,
                style: AppPalette.of(feuille).inkMuted.applyTo(
                  Theme.of(feuille).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!coran || !mounted) return;
    final String? groupe = widget.groupeId;
    final int? retenue = groupe == null
        ? null
        : ref.read(memoirePageClasseProvider).lire(groupe);
    if (retenue == null) return _ouvrirCoran();
    setState(() => _scenePremierPlan = null);
    await ref.read(presentateurCoranProvider).presenterPage(retenue);
  }

  /// Lot salle 2 : a l'entree de l'enseignant, la page retenue pour la
  /// classe revient, une fois, si rien n'est encore presente.
  void _reprendrePage(VueSalle vue, ContenuPresente? presentee) {
    final String? groupe = widget.groupeId;
    if (_repriseFaite ||
        groupe == null ||
        vue.role != RoleSalle.enseignant ||
        !vue.dansLaSalle) {
      return;
    }
    _repriseFaite = true;
    final int? retenue = ref.read(memoirePageClasseProvider).lire(groupe);
    if (presentee != null || retenue == null) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      unawaited(ref.read(presentateurCoranProvider).presenterPage(retenue));
    });
  }

  Future<void> _ouvrirCoran() async {
    final ({int sourate, int verset})? choix = await choisirVersetCoran(
      context,
    );
    if (choix == null || !mounted) return;
    setState(() => _scenePremierPlan = null);
    await ref
        .read(presentateurCoranProvider)
        .presenterVerset(sourate: choix.sourate, verset: choix.verset);
  }

  void _basculerPanneau(PanneauOuvert cible) => setState(() {
    _panneau = _panneau == cible ? PanneauOuvert.aucun : cible;
    if (_panneau == PanneauOuvert.commandes) _contexte = ContexteOuvert.aucun;
  });

  @override
  Widget build(BuildContext context) {
    // La session est **observee**, pas lue au dernier moment : `_rentrer` a
    // besoin du role, et un `ref.read` au moment du clic trouverait le provider
    // encore en chargement s'il n'avait jamais ete observe. La sortie tomberait
    // alors sur la racine, qui redirige, au lieu de l'accueil du role.
    final String? monProfil = ref.watch(sessionProvider).profileId;

    // CLV-03 (CL-4.5) : la preparation de l'enseignant, avant toute
    // connexion. « Entrer dans la classe » lance l'entree existante.
    final SessionState session = ref.watch(sessionProvider);
    // Session pas encore lue : aucune preparation n'est choisie a l'aveugle.
    if (_enPreparation && !session.resolue) {
      return const PageShell(actionsCoquille: false, child: SizedBox.shrink());
    }
    // Seuls l'eleve et l'enseignant ont une preparation. Le tuteur
    // observateur n'en a AUCUNE (D-14), et un autre role (admin, controleur)
    // garde le comportement de son role : l'entree directe, jamais la
    // preparation enseignant par defaut (revue CL-4.R, m8).
    if (_enPreparation &&
        !_suitLesCours(session) &&
        session.role != AppRole.teacher) {
      _enPreparation = false;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) unawaited(_entrer());
      });
    }
    // PRE-ELV-01 (CL-4.6) : la preparation presque silencieuse de l'eleve.
    if (_enPreparation && _suitLesCours(session)) {
      final String? groupe = widget.groupeId;
      final bool guidee = session.interfaceMode == InterfaceMode.enfant;
      return _PreparationEleveBranchee(
        guidee: guidee,
        onEntrer: ({required bool sansMicro}) {
          setState(() {
            _enPreparation = false;
            _sansMicro = sansMicro;
          });
          unawaited(_entrer());
        },
        // En Interface guidee, « Retour a l'accueil » mene a l'accueil de
        // l'eleve (spec 02 §2.2) ; en standard, « Retour a la Classe ».
        onRetour: guidee
            ? _rentrer
            : () => GoRouter.of(context).go(
                groupe == null
                    ? Routes.racine
                    : CheminsTcA.espaceGroupe(groupe),
              ),
      );
    }
    if (_enPreparation && session.role == AppRole.teacher) {
      return _PreparationBranchee(
        groupeId: widget.groupeId,
        onEntrer: () {
          setState(() => _enPreparation = false);
          unawaited(_entrer());
        },
        onRetour: () {
          final String? groupe = widget.groupeId;
          GoRouter.of(context).go(
            groupe == null
                ? Routes.enseignantJournee
                : Routes.groupePour(groupe),
          );
        },
      );
    }

    // Les ecrans de sortie de la salle de seance (T7).
    final VueSeance? fin = _finEnseignant;
    if (fin != null) {
      return FinSeanceEnseignant(
        vue: fin,
        actions: ActionsSeance(
          onRetour: _rentrer,
          onNaviguer: (String route) => GoRouter.of(context).go(route),
        ),
        onOuvrirCahier: _ouvrirCahier,
        onRetournerSalle: _retournerDansLaSalle,
        onRevenirJournee: () =>
            GoRouter.of(context).go(Routes.enseignantJournee),
        cahierIndisponible: _cahierIndisponible,
      );
    }
    final IssueSeance? sortie = _sortieEleve;
    if (sortie != null) {
      // MA-APRES-1 (decision A7 = a) : en Mode Accessibilite, UN SEUL ecran
      // de fin, celui de MA-6, monte ici par la vraie salle.
      if (ref.watch(modeAccessibiliteActifProvider)) {
        final String? groupe = widget.groupeId;
        return ApresSeanceSalle(
          groupeId: groupe,
          // MA-APRES-1b : la seance quittee n'est jamais « la prochaine ».
          seanceQuitteeId: widget.seanceId,
          quittee: sortie == IssueSeance.quittee,
          // MA-TUTOIEMENT-1 : le tutoiement suit l'age, jamais la
          // presentation ; port neutre (K-09) avant BR-1, age inconnu :
          // vouvoiement.
          tutoiement: ref.watch(portAgeEleveProvider).ageDeLEleve().tutoiement,
          // « Retour a la Classe » : la destination Ma classe du Mode
          // Accessibilite.
          onRetourClasse: () => GoRouter.of(context).go(Routes.eleveSuivi),
          onClasse: () => GoRouter.of(context).go(
            groupe == null
                ? Routes.eleveSuivi
                : CheminsTcA.espaceGroupe(groupe),
          ),
          // L'aide vit dans Mon espace (MA14, MA-8).
          onAide: () => GoRouter.of(context).go(Routes.compte),
        );
      }
      return ResultatSeance(
        issue: sortie,
        onRetour: _retourClasse,
        // Lot salle 2 : apres « Quitter », revenir par le meme chemin que
        // l'entree (pre-vol, jeton, salle).
        onRevenir: sortie == IssueSeance.quittee
            ? () {
                setState(() => _sortieEleve = null);
                unawaited(_entrer());
              }
            : null,
        onAccueil: _rentrer,
      );
    }

    final VueSalle vue = VueSalle.depuis(
      materielPret: _materielPret,
      acces: _acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse,
    );
    final bool enImpasse = vue.phase == PhaseSalle.refus;
    // SALLE-ENCRE-1 : les textes de la salle prennent l'encre du registre
    // `salle` (celle que `PageImmersive` pose en fond) pour TOUS les roles,
    // hors Mode Accessibilite aussi (`_encreSalle`). Ce drapeau ne garde que
    // le bandeau permanent pose sur la surface des vignettes (MA-5) : le
    // bandeau n'est pas du perimetre (JUR-APP-1).
    final bool encreAccessible =
        vue.role == RoleSalle.eleve &&
        ref.watch(modeAccessibiliteActifProvider);

    // **`.value`, et surtout pas un filtrage par le type de l'AsyncValue**
    // (piege de l'etape 3, Riverpod 3). Les trois cas qui rendent `null` --
    // pas encore charge, lecture refusee, reseau coupe -- se disent de la meme
    // facon a l'ecran : inconnu. C'est J3, et c'est ce qui le rend simple.
    final List<PresenceParticipant>? presence = ref
        .watch(presenceSeanceProvider(widget.seanceId))
        .value;
    final List<_Presence> lignes = _Presence.composer(
      presence: presence,
      vue: vue,
      monProfil: monProfil,
      maintenant: DateTime.now(),
    );
    final VuePresence mienne = VuePresence.depuis(
      ligne: maPresence(presence, monProfil),
      maintenant: DateTime.now(),
    );

    // **Le tuteur de cet enfant observe-t-il ?** Question posee au serveur, qui
    // ne rend que la ligne de l'appelant (`annonce_observation_pour_moi`,
    // `0040`). La condition de role n'ajoute aucune securite -- le serveur
    // refuse deja qui n'est pas membre du groupe -- elle evite de battre la RPC
    // sur l'appareil de l'enseignant, du controleur et de l'observateur, qui
    // montent tous cette meme salle.
    final bool monTuteurObserve =
        vue.role == RoleSalle.eleve &&
        (ref.watch(monTuteurObserveProvider(widget.seanceId)).value ?? false);

    // **L'annonce a l'enseignant, ici.** C'est la seule salle d'enseignant
    // (l'ancienne `/tc/classe` est supprimee depuis le 17/10/2026), ou mene le
    // bouton « Lancer » de sa journee (`ENS-02`). Sans elle, un enseignant
    // ferait cours devant un parent sans le savoir.
    //
    // Meme raison qu'au-dessus pour la condition de role : elle n'ajoute aucune
    // securite -- `annonces_observation` leve `insufficient_privilege` pour qui
    // n'est pas l'enseignant de la seance -- elle evite de battre la RPC toutes
    // les dix secondes sur l'appareil de chaque eleve.
    final List<AnnonceObservation> annonces = vue.role == RoleSalle.enseignant
        ? ref.watch(annoncesObservationProvider(widget.seanceId)).value ??
              const <AnnonceObservation>[]
        : const <AnnonceObservation>[];

    // TB-11a : la presentation lue par l'observateur (tuteur, controleur), ou
    // `null` (role qui ne la suit pas, rien de presente, source absente). La
    // condition evite de lire la source sur l'appareil des participants.
    final VueSeance? presentation =
        vue.suitLaPresentationEnLecture && !enImpasse
        ? DepuisSalle.presentationObservee(
            salle: vue,
            presentation: ref.watch(
              presentationObserveeProvider(widget.seanceId),
            ),
          )
        : null;

    // D9 : l'eleve lit la page du Coran que l'enseignant presente (canal de
    // donnees, `contenuPresenteProvider`), en lecture seule, dans la meme
    // composition que la presentation lue (le document, puis la scene).
    final ContenuPresente? pageEleve = vue.role == RoleSalle.eleve && !enImpasse
        ? ref.watch(contenuPresenteProvider).value
        : null;
    // D9 : l'enseignant presente une page (le flux qu'il lit lui-meme) : sur
    // telephone, la page prend alors toute la largeur ou toute la hauteur.
    final ContenuPresente? pagePresentee = _panneauEnseignant(vue) && !enImpasse
        ? ref.watch(contenuPresenteProvider).value
        : null;
    // Le panneau de l'enseignant lit d'abord la page par le service du Coran
    // (etats de lecture) : la page ne prend la place que si elle est lue.
    final bool pageEnseignant =
        pagePresentee != null &&
        (ref
                .watch(pageCoranProvider(pagePresentee.page))
                .value
                ?.versets
                .isNotEmpty ??
            false) &&
        pageCoranLisible(ref, pagePresentee.page);
    final bool pageEleveLisible =
        pageEleve != null && pageCoranLisible(ref, pageEleve.page);

    // S0 (arbitrage du pilote, 24/10/2026) : une fois dans la salle,
    // l'eleve, la guidee et l'enseignant passent par la salle de seance
    // (`SalleSeance`), raccordee par `DepuisSalle`. L'entree, l'impasse,
    // l'observateur et le controleur gardent leur rendu.
    if (vue.dansLaSalle) {
      final ContenuPresente? presentee =
          vue.role == RoleSalle.eleve || _panneauEnseignant(vue)
          ? ref.watch(contenuPresenteProvider).value
          : null;
      // Lot salle 2 : la page que l'enseignant presente est retenue pour la
      // classe ; a son entree suivante, elle revient.
      final String? groupe = widget.groupeId;
      if (groupe != null &&
          vue.role == RoleSalle.enseignant &&
          presentee != null) {
        ref.read(memoirePageClasseProvider).ecrire(groupe, presentee.page);
      }
      _reprendrePage(vue, presentee);
      final VueSeance? seance = DepuisSalle.vue(
        salle: vue,
        mode: AppMetriques.of(context).mode,
        presence: presence,
        monProfil: monProfil,
        monTuteurObserve: monTuteurObserve,
        annonces: annonces,
        groupeId: widget.groupeId,
        age: ref.watch(portAgeEleveProvider).ageDeLEleve(),
        supportPresente: presentee == null
            ? null
            : DepuisSalle.pageCoran(presentee.page),
      );
      if (seance != null) {
        return _salleDeSeance(
          vue,
          seance,
          presentee,
          lignes: lignes,
          mienne: mienne,
        );
      }
    }

    // CTR-02 : la salle du controleur, la MEME salle (R-salle unique), avec
    // sa zone haute (« Quitter » y vit). Aucune commande en bas : « Son reçu »
    // attend BR-1 (CTRL-SON-1), « Agrandir le support » attend le rendu d'un
    // support (CTRL-AGRANDIR-1). Aucune commande interdite n'est rendue, pas
    // meme grisee (UX_REVIEW_08 n° 4 f).
    if (vue.role == RoleSalle.controleur && !enImpasse) {
      return PageImmersive(
        registre: RegistreImmersif.salle,
        entete: _EnteteControle(
          vue: vue,
          onQuitter: () => unawaited(_quitter(vue)),
        ),
        bandeau: _Bandeaux(vue: vue),
        child: presentation != null
            ? _CorpsDocument(
                vue: vue,
                lignes: lignes,
                document: _PresentationLue(vue: presentation),
                presentationLue: true,
              )
            : _Corps(vue: vue, lignes: lignes),
      );
    }

    return PageImmersive(
      registre: RegistreImmersif.salle,
      lateraleEnPaysage: pageEleveLisible || pageEnseignant,
      entete: _Entete(
        vue: vue,
        monTuteurObserve: monTuteurObserve,
        annonces: annonces,
        // L'eleve lit SON etat, et lui seul : la section 6.6 le dit deux fois,
        // et la vue en base le lui impose de toute facon. L'observateur, lui,
        // n'a aucun etat pedagogique a lire -- il assiste.
        mienne: vue.role == RoleSalle.eleve ? mienne : null,
        // Le bouton n'existe que pour qui a droit a la liste ET n'a pas la
        // place de la garder ouverte. Ailleurs il ferait doublon avec la
        // colonne, et un doublon finit par diverger.
        onVoirPresence:
            vue.voitLesParticipants && !_colonneDePresence(context, vue)
            ? () => unawaited(_voirPresence(lignes))
            : null,
        // La fiche de seance n'est qu'a l'enseignant, et seulement quand le
        // roster pedagogique se lit (jamais un compteur invente).
        eleves: vue.role == RoleSalle.enseignant && !enImpasse
            ? _roster(ref)
            : null,
        onVoirEleves: () => unawaited(_voirEleves()),
      ),
      // Le bandeau disparait dans la seule situation ou il serait faux : une
      // impasse n'est pas une salle, rien n'y est enregistre. Partout ailleurs
      // il est present, y compris pendant l'attente : la regle se lit donc
      // AVANT que le micro puisse s'ouvrir.
      bandeau: enImpasse
          ? null
          : _Bandeaux(vue: vue, encreAccessible: encreAccessible),
      commandes: enImpasse
          ? null
          : _Commandes(
              vue: vue,
              onMicro: _basculerMicro,
              onCamera: _basculerCamera,
              onQuitter: () => _quitter(vue),
            ),
      child: enImpasse
          ? _Impasse(
              cause: vue.cause,
              onReessayer: _entrer,
              onRentrer: _rentrer,
            )
          // `ENS-03` : la surface de presentation de l'enseignant, en UN SEUL
          // point. Les deux conditions comptent. Le role vient du **jeton**
          // (`vue.role`), jamais de `sessionProvider.role` : c'est le jeton qui
          // decide ce qu'on peut faire dans une salle. Et `peutPresenter`
          // conditionne l'affichage, plutot que de montrer des commandes que le
          // moteur refuserait en silence -- `presenterContenu` refuse sans rien
          // dire quand `can_publish_data` est absent.
          : _panneauEnseignant(vue)
          ? _CorpsDocument(
              vue: vue,
              lignes: lignes,
              document: PanneauEnseignantSalle(seanceId: widget.seanceId),
              pageCoran: pageEnseignant,
            )
          // D9 : l'eleve voit la page du Coran presentee.
          : pageEleve != null
          ? _CorpsDocument(
              vue: vue,
              lignes: lignes,
              document: PageCoranSalle(
                key: SallePage.pageEleveKey,
                numero: pageEleve.page,
              ),
              presentationLue: true,
              pageCoran: pageEleveLisible,
            )
          // TB-11a : le tuteur observateur lit la presentation, meme
          // composition (le document d'abord, la scene ensuite).
          : presentation != null
          ? _CorpsDocument(
              vue: vue,
              lignes: lignes,
              document: _PresentationLue(vue: presentation),
              presentationLue: true,
            )
          : _Corps(vue: vue, lignes: lignes),
    );
  }
}

/// D14 (S0) : la cause probable d'un refus de camera, lue dans la phrase du
/// navigateur (`getUserMedia`), et ce qu'il faut faire (K-59).
String causeEchecCamera(String erreur) {
  bool dit(List<String> mots) => mots.any(erreur.contains);
  if (dit(<String>['NotAllowedError', 'Permission', 'permission'])) {
    return t.salle.cameraEchecRefus;
  }
  if (dit(<String>['NotReadableError', 'TrackStartError', 'Could not start'])) {
    return t.salle.cameraEchecOccupee;
  }
  if (dit(<String>['NotFoundError', 'DevicesNotFound', 'not found'])) {
    return t.salle.cameraEchecAbsente;
  }
  return t.salle.cameraEchecAutre;
}

/// S0.2 : le panneau Eleves de l'enseignant dans la salle de seance : la
/// presence de chacun (J3 : jamais « absent » sans le savoir, consolide ou
/// non), puis le roster reel de la seance (fiche, rappel discret).
class _ElevesSeance extends StatelessWidget {
  const _ElevesSeance({
    required this.lignes,
    required this.roster,
    required this.onOuvrirFiche,
  });

  final List<_Presence> lignes;
  final RosterClasseVM roster;
  final ValueChanged<String> onOuvrirFiche;

  @override
  Widget build(BuildContext context) {
    // S0.2c : une ligne par personne (prenom, etat, micro) ; toucher un eleve
    // du roster ouvre sa fiche (rappel discret, recitation). S0.2d : la carte
    // prend la hauteur de son contenu, avec son rembourrage ; au-dela, elle
    // defile (rien de coupe, rien de colle au bord).
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: <Widget>[
          for (final _Presence personne in lignes)
            _LigneEleve(
              personne: personne,
              onFiche:
                  roster.disponible &&
                      personne.academyId != null &&
                      roster.parAcademyId(personne.academyId!) != null
                  ? () => onOuvrirFiche(personne.academyId!)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// S0.2c : la ligne d'une personne dans la colonne Eleves : le prenom en
/// ellipse (jamais coupe ni debordant), son etat en pastille (le mot entier,
/// J7), le micro coupe ; « consolide » dessous quand une decision l'a fige.
class _LigneEleve extends StatelessWidget {
  const _LigneEleve({required this.personne, this.onFiche});

  final _Presence personne;
  final VoidCallback? onFiche;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  personne.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: palette.inkStrong.applyTo(
                    textes.labelLarge ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.hSm,
              StatusPill(
                libelle: LignePresence.libelle(personne.vue.etat),
                ton: personne.vue.ton,
              ),
              if (personne.micro == false) ...<Widget>[
                Ecart.hXs,
                IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                  child: Icon(
                    AppIcons.microCoupe.repos,
                    semanticLabel: t.salle.microCoupe,
                  ),
                ),
              ],
            ],
          ),
          if (personne.vue.consolide)
            Text(
              t.presence.consolide,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
        ],
      ),
    );
    final VoidCallback? fiche = onFiche;
    if (fiche == null) return MergeSemantics(child: ligne);
    return Pressable(
      onPress: fiche,
      libelleSemantique: personne.nom,
      child: ligne,
    );
  }
}

/// S1 : la portee de la synchronisation autour de la salle de seance : le
/// depot local de la seance, l'emission de l'ecriture, et des outils neufs
/// pour cette salle (jamais ceux de la precedente). Sans synchronisation
/// (pas de jeton), la salle est rendue telle quelle.
class _AvecSynchro extends StatelessWidget {
  const _AvecSynchro({required this.synchro, required this.child});

  final SynchroSalle? synchro;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SynchroSalle? s = synchro;
    if (s == null) return child;
    return ProviderScope(
      key: ValueKey<String>('synchro-${s.sessionId}'),
      overrides: <Override>[
        portAnnotationsProvider.overrideWithValue(s.depot),
        notesDeposeesProvider.overrideWith2(NotesDeposees.new),
        traitsNonPartagesProvider.overrideWith(TraitsNonPartages.new),
        etatOutilsProvider.overrideWith(ControleurOutils.new),
        historiquePersonnelProvider.overrideWith(ControleurHistorique.new),
        diffusionEcritureProvider.overrideWithValue(s.diffuser),
        diffusionPointeurProvider.overrideWithValue(s.diffuserPointeur),
        pointeurDistantProvider.overrideWithValue(s.pointeurDistant),
      ],
      child: child,
    );
  }
}

/// S0.2 : l'etat de presence de l'eleve, en pastille dans l'en-tete de la
/// salle de seance (section 6.6 : le sien, et aucun autre).
class _PastillePresence extends StatelessWidget {
  const _PastillePresence({required this.mienne});

  final VuePresence mienne;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: t.presence.mienne,
      child: StatusPill(
        libelle: LignePresence.libelle(mienne.etat),
        ton: mienne.ton,
      ),
    ),
  );
}

/// D14 : la camera n'a pas pu s'allumer ; la phrase exacte du navigateur, sa
/// cause probable et quoi faire (K-59), sous l'en-tete.
class _ErreurCamera extends StatelessWidget {
  const _ErreurCamera({required this.erreur});

  final String erreur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String cause = causeEchecCamera(erreur);
    // K4 (directeur, 25/10/2026) : l'erreur de camera est une pilule
    // translucente sous la ligne d'etat, dans la couche qui se masque, jamais
    // un bloc qui pousse la page. Ce qui manque, la cause et quoi faire
    // (K-59), puis le message exact du navigateur (D14).
    final TextStyle style = palette.piluleSalle.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    return Semantics(
      key: const ValueKey<String>('salle-erreur-camera'),
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: DecoratedBox(
          decoration: palette.piluleSalle.decoration(
            borderRadius: AppRadius.arrondiLg,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                Text(
                  t.salle.cameraEchec,
                  style: palette.piluleSalle.applyTo(
                    textes.labelMedium ?? const TextStyle(),
                  ),
                ),
                Text(cause, style: style),
                Text(t.salle.cameraEchecMessage(erreur: erreur), style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La ligne de contexte : ou l'on en est, ce que vaut le lien, et -- pour
/// l'eleve -- comment sa presence est notee.
///
/// **Deux faits distincts, deux lignes.** La pastille du haut dit l'etat de la
/// **connexion** temps reel, ce que le moteur sait ; celle du bas dit l'etat de
/// **presence**, ce que la base derive. Les confondre serait faux : on peut
/// etre parfaitement connecte et note « en retard », et on peut avoir perdu le
/// lien depuis dix secondes sans etre encore note « deconnecte ».
class _Entete extends StatelessWidget {
  const _Entete({
    required this.vue,
    this.mienne,
    this.monTuteurObserve = false,
    this.annonces = const <AnnonceObservation>[],
    this.onVoirPresence,
    this.eleves,
    this.onVoirEleves,
  });

  final VueSalle vue;

  /// Ma propre presence, pour l'eleve et lui seul. `null` ailleurs.
  final VuePresence? mienne;

  /// Vrai quand le tuteur de l'eleve qui regarde cet ecran observe la seance.
  /// Faux pour tout autre role : c'est une information sur SON foyer.
  final bool monTuteurObserve;

  /// Les tuteurs qui observent, pour l'enseignant et lui seul. Vide ailleurs :
  /// cette liste porte les prenoms de TOUS les enfants observes.
  final List<AnnonceObservation> annonces;

  /// Ouvre la liste de presence, quand elle ne tient pas en colonne.
  final VoidCallback? onVoirPresence;

  /// Le roster pedagogique, pour l'enseignant seulement ; `null` ailleurs.
  final RosterClasseVM? eleves;

  /// Ouvre la feuille des eleves.
  final VoidCallback? onVoirEleves;

  /// Le bouton « 3/4 » des eleves, s'il a lieu d'etre.
  Widget? _boutonEleves(BuildContext context) {
    final RosterClasseVM? roster = eleves;
    final VoidCallback? ouvrir = onVoirEleves;
    if (roster == null || ouvrir == null || !roster.disponible) {
      return null;
    }
    return BoutonRoster(
      key: const ValueKey<String>('salle-eleves'),
      compteur: roster.compteurCompact,
      presents: roster.presents,
      attendus: roster.attendus,
      onOuvrir: ouvrir,
      encre: AppPalette.of(context).surfaceInverse.applyTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    final String? attente = _attenteDe(vue);

    if (attente != null) {
      return Text(attente, style: _encreSalle(context, textes.labelLarge));
    }

    final _EtatLien etatDuLien = _etatDuLien(vue);

    // SALLE-200-1 : texte agrandi au-dela du seuil, l'en-tete se resserre en
    // une seule rangee qui passe a la ligne au lieu de s'empiler (pastille du
    // lien, ma presence, lien vers la liste) : le support garde la hauteur.
    if (!motEtatVisible(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _pastilleDuLien(etatDuLien),
              if (vue.lienADire && vue.phase != PhaseSalle.instable)
                Text(
                  vue.qualite == QualiteLien.perdue
                      ? t.salle.lienPerdu
                      : t.salle.lienMediocre,
                  style: _encreSalle(context, textes.labelMedium),
                ),
              // Ma presence en pastille seule : « Votre presence » est lu avec
              // l'etat, et la pastille porte deja le mot de l'etat (J7).
              if (mienne case final VuePresence etat)
                MergeSemantics(
                  child: Semantics(
                    label: t.presence.mienne,
                    child: StatusPill(
                      libelle: LignePresence.libelle(etat.etat),
                      ton: etat.ton,
                    ),
                  ),
                ),
              if (onVoirPresence != null)
                LienFleche(
                  libelle: t.presence.titre,
                  libelleSemantique: t.presence.voir,
                  onPress: onVoirPresence,
                  fleche: false,
                  encre: AppPalette.of(context).surfaceInverse.applyTo,
                ),
              ?_boutonEleves(context),
            ],
          ),
          if (monTuteurObserve) ...<Widget>[
            Ecart.vSm,
            const IndicateurObservationEnfant(visible: true),
          ],
          if (annonces.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            IndicateurObservation(annonces: annonces),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Une reconnexion n'est pas une absence, et un retablissement n'est
            // pas un silence : la seance continue, et l'ecran le dit sans
            // dramatiser.
            _pastilleDuLien(etatDuLien),
            // La qualite du lien se dit en MOTS. Une pastille de couleur seule
            // ne represente jamais un etat critique (invariant J7). La pastille
            // porte deja le mot quand la phase est `instable` : on ne le repete
            // pas a cote d'elle.
            if (vue.lienADire && vue.phase != PhaseSalle.instable) ...<Widget>[
              Ecart.hSm,
              Flexible(
                child: Text(
                  vue.qualite == QualiteLien.perdue
                      ? t.salle.lienPerdu
                      : t.salle.lienMediocre,
                  style: _encreSalle(context, textes.labelMedium),
                ),
              ),
            ],
            if (onVoirPresence != null) ...<Widget>[
              const Spacer(),
              // **Un mot, pas une icone.** Aucune icone du catalogue ne dit
              // « presence » : emprunter celle du foyer lui donnerait un
              // second sens, et `AppIcons` n'existe que pour qu'un signe garde
              // le sien. Le mot suffit : `LienFleche` lui donne sa cible tactile
              // et son centrage (K-54).
              LienFleche(
                libelle: t.presence.titre,
                libelleSemantique: t.presence.voir,
                onPress: onVoirPresence,
                fleche: false,
                encre: AppPalette.of(context).surfaceInverse.applyTo,
              ),
            ],
            if (_boutonEleves(context) case final Widget bouton) ...<Widget>[
              if (onVoirPresence == null) const Spacer() else Ecart.hMd,
              bouton,
            ],
          ],
        ),
        // Visible en permanence, discrete, jamais superposee au contenu
        // (specification d'etape section 7, `ELV-03`).
        if (mienne case final VuePresence etat) ...<Widget>[
          Ecart.vSm,
          _SurLaSalle(
            active: true,
            child: LignePresence(nom: t.presence.mienne, vue: etat),
          ),
        ],
        // **L'enfant apprend que son tuteur regarde, ici.** C'est la seule
        // salle cote eleve (l'ancienne `/tc/classe` est supprimee depuis le
        // 17/10/2026), ou mene « Rejoindre » depuis l'accueil `ELV-02`.
        //
        // La borne de vie privee est en base : `annonce_observation_pour_moi`
        // (`0040`) porte `enfant_profile_id = auth.uid()` dans son WHERE, donc
        // les quatre autres enfants du groupe ne lisent rien (spec 11.3).
        if (monTuteurObserve) ...<Widget>[
          Ecart.vSm,
          const IndicateurObservationEnfant(visible: true),
        ],
        // Le composant partage de l'observation, pas une seconde ecriture : il
        // porte deja la regle (rien quand personne n'observe, aucune
        // notification de sortie).
        if (annonces.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          IndicateurObservation(annonces: annonces),
        ],
      ],
    );
  }
}

/// L'attente avant la salle, en mots, ou `null` une fois dedans.
///
/// Les trois attentes se disent par des mots differents : elles n'echouent
/// pas pour les memes raisons, donc ne se corrigent pas de la meme facon.
String? _attenteDe(VueSalle vue) => switch (vue.phase) {
  PhaseSalle.materiel => t.salle.verificationMateriel,
  PhaseSalle.ouverture => t.salle.ouverture,
  PhaseSalle.connexion => t.salle.connexion,
  PhaseSalle.enSalle ||
  PhaseSalle.instable ||
  PhaseSalle.reconnexion ||
  PhaseSalle.retabli ||
  PhaseSalle.refus => null,
};

/// L'etat du lien : le mot, le ton et, quand l'etat du lien est celui d'une
/// seance qui se deroule, **l'etat de seance qu'il represente** (le type,
/// jamais une comparaison de mots traduits).
typedef _EtatLien = (String, TonEtat, EtatPastilleSeance?);

/// L'etat du lien, en mot et en ton.
///
/// **Chaque etat porte son mot** (invariant J7) : une pastille jaune sans
/// libelle ne dirait rien a qui ne distingue pas les couleurs, et rien du
/// tout a qui ecoute l'ecran. Les cinq etats du protocole sont donc cinq
/// libelles, et « instable » reprend le mot que la qualite du lien emploie
/// deja plutot que d'en inventer un jumeau.
_EtatLien _etatDuLien(VueSalle vue) => switch (vue.phase) {
  PhaseSalle.reconnexion => (
    t.salle.reconnexionCourt,
    TonEtat.avertissement,
    null,
  ),
  PhaseSalle.instable => (
    vue.qualite == QualiteLien.perdue
        ? t.salle.lienPerdu
        : t.salle.lienMediocre,
    TonEtat.avertissement,
    null,
  ),
  PhaseSalle.retabli => (t.reseau.retabli, TonEtat.succes, null),
  PhaseSalle.enSalle ||
  PhaseSalle.materiel ||
  PhaseSalle.ouverture ||
  PhaseSalle.connexion ||
  PhaseSalle.refus => (
    t.etat.enDirect,
    TonEtat.succes,
    EtatPastilleSeance.enDirect,
  ),
};

/// La pastille de l'etat du lien : « En direct » passe par le composant
/// partage d'etat de seance (ON-AIR-1), les autres etats par `StatusPill`.
Widget _pastilleDuLien(_EtatLien etat) {
  final EtatPastilleSeance? seance = etat.$3;
  return seance == null
      ? StatusPill(libelle: etat.$1, ton: etat.$2)
      : PastilleEtatSeance(etat: seance);
}

/// CTR-02 : la zone haute du controleur, visible de lui seul.
///
/// « Contrôle Rewayah », l'etat reseau (le meme mot que pour tous : une
/// reconnexion n'est jamais un faux direct, R12) et « Quitter » en action
/// secondaire au bord de fin, jamais en rouge plein (UX_REVIEW_08 n° 4 d). Le
/// titre passe sur deux lignes plutot que de se tronquer (n° 20 d). Aucune
/// duree de presence : reportee avec LIVE-CHRONO-01.
class _EnteteControle extends StatelessWidget {
  const _EnteteControle({required this.vue, required this.onQuitter});

  final VueSalle vue;
  final VoidCallback onQuitter;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    // L'encre de la paire du registre `salle` (celle que `PageImmersive` pose
    // en fond) : un style du theme porte l'encre des surfaces claires, qui
    // ecrase le `DefaultTextStyle` de la coquille et disparait sur le fond.
    final AppColorPair salle = AppPalette.of(context).surfaceInverse;
    final String? attente = _attenteDe(vue);
    final _EtatLien lien = _etatDuLien(vue);
    // TB-RC (TB_RAPPORT §d n. 14) : en demonstration, le ruban d'angle
    // (`ReserveCoinFin`) ne recouvre jamais « Quitter » ; en production, la
    // reserve vaut 0.
    final Widget reserve = SizedBox(width: ReserveCoinFin.de(context));

    // SALLE-200-1 : texte agrandi au-dela du seuil, la zone haute tient sur
    // une ligne : l'etat du lien, puis « Quitter » en icone seule (nom lu et
    // infobulle), toujours au bord de fin. Le titre reste annonce comme
    // en-tete au lecteur d'ecran ; le rappel du controleur, au-dessus des
    // commandes, dit deja la visite en toutes lettres.
    if (!motEtatVisible(context)) {
      return Row(
        children: <Widget>[
          Semantics(header: true, label: t.salle.visiteControle.titre),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                liveRegion: true,
                child: attente != null
                    ? Text(
                        attente,
                        style: salle.applyTo(
                          textes.labelLarge ?? const TextStyle(),
                        ),
                      )
                    : _pastilleDuLien(lien),
              ),
            ),
          ),
          Ecart.hMd,
          BoutonIcone(
            icone: AppIcons.sortie,
            libelle: t.salle.quitter,
            onPress: onQuitter,
          ),
          reserve,
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  t.salle.visiteControle.titre,
                  style: salle.applyTo(textes.titleMedium ?? const TextStyle()),
                ),
              ),
              Ecart.vXs,
              Semantics(
                liveRegion: true,
                child: attente != null
                    ? Text(
                        attente,
                        style: salle.applyTo(
                          textes.labelLarge ?? const TextStyle(),
                        ),
                      )
                    : _pastilleDuLien(lien),
              ),
            ],
          ),
        ),
        Ecart.hMd,
        ActionPrincipale(
          libelle: t.salle.quitter,
          niveau: NiveauAction.secondaire,
          pleineLargeur: false,
          onPress: onQuitter,
        ),
        reserve,
      ],
    );
  }
}

/// Le bandeau permanent, et le rappel propre a qui observe.
class _Bandeaux extends StatelessWidget {
  const _Bandeaux({required this.vue, this.encreAccessible = false});

  final VueSalle vue;

  /// MA-5 : l'eleve en Mode Accessibilite lit la salle avec l'encre du
  /// registre (`surfaceInverse`) ; les autres gardent leur rendu (HU-1).
  final bool encreAccessible;

  @override
  Widget build(BuildContext context) {
    // CTRL-SALLE-1 (revue du directeur) : la mention « Cours enregistre,
    // visite de controle possible » s'adresse aux participants (enseignant,
    // eleves), jamais au controleur, qui EST la visite. Il ne garde que son
    // propre rappel, en registre doux (`washWarning`). `PermanentNotice` reste
    // intacte et sans parametre (ADR-011) : c'est le choix de la rendre ou non
    // qui se fait ici, par role, jamais une variante de son texte.
    if (vue.role == RoleSalle.controleur) {
      return _Rappel(
        texte: t.salle.bandeauControle,
        titre: t.salle.bandeauControleTitre,
        ton: TonEtat.avertissement,
        icone: AppIcons.controleQualite,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Un SECOND bandeau, jamais une variante du premier. `PermanentNotice`
        // n'accepte aucun parametre, et c'est ce qui garantit qu'il affiche la
        // meme ligne pour les quatre roles (ADR-011). Le rappel d'invisibilite,
        // lui, ne concerne que l'ecran de qui observe.
        // (Le rappel du controleur est rendu plus haut, avec la mention.)
        if (vue.role == RoleSalle.tuteurObservateur)
          _Rappel(
            texte: t.salle.observationMuette,
            titre: t.salle.observationMuetteTitre,
            ton: TonEtat.accent,
            icone: AppIcons.microCoupe,
          ),
        // SALLE-CORR-3 (releve VERIF-CORR-2) : la mention se pose dans la
        // gouttiere du gabarit, comme l'entete et les commandes, jamais
        // collee au bord de l'ecran.
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppGabarit.de(context).gouttiere,
          ),
          child: _SurLaSalle(
            active: encreAccessible,
            child: encreAccessible
                ? const PermanentNotice()
                : const _EncreDeLaSalle(child: PermanentNotice()),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de rappel pleine largeur, en registre doux.
class _Rappel extends StatelessWidget {
  const _Rappel({
    required this.texte,
    required this.titre,
    required this.ton,
    required this.icone,
  });

  final String texte;

  /// La premiere phrase de [texte], seule montree en texte tres agrandi.
  final String titre;
  final TonEtat ton;
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Registre DOUX, jamais un aplat : la seule zone pleine d'un ecran est son
    // action principale, et une salle n'en a pas. Le « bandeau noir » du
    // catalogue visait une salle sur fond creme ; la salle est desormais en
    // registre inverse, ou un bandeau noir serait invisible -- ironique, pour
    // un rappel d'invisibilite.
    final AppColorPair paire = switch (ton) {
      TonEtat.avertissement => palette.washWarning,
      TonEtat.accent => palette.washAccent,
      TonEtat.neutre || TonEtat.succes || TonEtat.alerte => palette.washAccent,
    };
    final TextTheme textes = Theme.of(context).textTheme;

    // SALLE-CORR-3 (releve VERIF-CORR-2) : le rappel propre a qui observe
    // (controleur, tuteur) garde TOUJOURS son titre, meme en texte tres
    // agrandi : la reduction a la seule icone (SALLE-200-1, 642bb5a) rendait
    // le rappel muet. TB-RC (TB_RAPPORT §d n° 6, WCAG 1.4.4) : au-dela du
    // seuil, il ne se reduit plus a son titre (« Vous n'etes pas entendu. »
    // et l'inscription au journal disparaissaient) : les deux phrases se
    // lisent, chacune sur sa ligne, dans une bande serree. Le lecteur d'ecran
    // lit la phrase entiere, une fois.
    final bool serre = !motEtatVisible(context);
    final String suite = texte.startsWith(titre)
        ? texte.substring(titre.length).trimLeft()
        : '';
    final TextStyle style = paire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Widget bande = DecoratedBox(
      decoration: paire.decoration(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: serre ? AppSpacing.md : AppSpacing.lg,
          vertical: serre ? AppSpacing.xs : AppSpacing.md,
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
              child: serre && suite.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(titre, style: style),
                        Text(suite, style: style),
                      ],
                    )
                  : Text(texte, style: style),
            ),
          ],
        ),
      ),
    );
    if (!serre) return bande;
    return Semantics(label: texte, excludeSemantics: true, child: bande);
  }
}

/// Vrai quand la salle rend la surface de presentation de l'enseignant.
///
/// Les deux conditions ensemble, en un seul endroit, parce que trois endroits
/// s'en servent et qu'une seule des trois qui se tromperait suffirait a rendre
/// la presence injoignable.
bool _panneauEnseignant(VueSalle vue) =>
    vue.role == RoleSalle.enseignant && vue.peutPresenter;

/// Vrai quand la liste de presence est REELLEMENT posee a cote du contenu.
///
/// **Deux facons d'ouvrir la meme liste sur un meme ecran, c'est une de trop** :
/// l'entete n'offre son bouton que si cette fonction est fausse, et la liste
/// n'est posee que si elle est vraie. Elles doivent donc repondre ensemble, et
/// c'est pour cela que la reponse est ici et non recalculee de chaque cote.
///
/// L'enseignant qui presente l'a TOUJOURS sous les yeux, quel que soit le
/// gabarit : sa colonne defile, donc la liste y tient meme sur un telephone, la
/// ou `_Corps` doit renoncer a la poser faute de largeur. C'est la bonne reponse
/// pour lui, et pas un effet de bord : savoir qui manque est la premiere chose
/// qu'on regarde en ouvrant un cours de groupe.
bool _colonneDePresence(BuildContext context, VueSalle vue) {
  if (!vue.voitLesParticipants) {
    return false;
  }
  return _panneauEnseignant(vue) || AppGabarit.de(context).estLarge;
}

/// Le document d'abord, la scene ensuite : la salle de l'enseignant (son
/// panneau de presentation), et celle de l'observateur qui lit la
/// presentation (TB-11a, [_PresentationLue]).
///
/// **La hierarchie de `ENS-03` en une classe.** Le contenu pedagogique est le
/// premier niveau, le media le deuxieme : c'est l'ordre du protocole. Une
/// seule composition pour les deux, jamais une copie (K-10).
///
/// `[RESPONSIVE]` Sur telephone ET sur tablette, le document prend la plus
/// grande part et la scene garde la sienne DESSOUS -- jamais par-dessus : aucune
/// barre d'outils ne couvre le Coran. Au desktop seulement, les trois surfaces
/// se posent cote a cote, le document en tete parce qu'il est le premier niveau
/// de la hierarchie.
///
/// Elle compose `_Scene` et `_ListePresence` directement plutot que `_Corps` :
/// `_Corps` reserve 256 px fixes a la presence, et les lui laisser prendre sur
/// une demi-largeur est exactement ce qui etranglait la scene.
class _CorpsDocument extends StatelessWidget {
  const _CorpsDocument({
    required this.vue,
    required this.lignes,
    required this.document,
    this.presentationLue = false,
    this.pageCoran = false,
  });

  final VueSalle vue;
  final List<_Presence> lignes;

  /// D9 (24/10/2026) : une page du Coran est presentee. Sur telephone, en
  /// portrait, elle prend toute la largeur (sa hauteur suit le ratio de
  /// l'edition de Medine, la colonne defile, jamais la page) ; en paysage,
  /// toute la hauteur, la scene reduite a cote.
  final bool pageCoran;

  /// La largeur de la scene a cote de la page, sur un telephone en paysage.
  static const double largeurSceneLaterale = AppSpacing.respiration * 3;

  /// Le premier niveau : le panneau de l'enseignant, ou la presentation lue.
  final Widget document;

  /// Vrai pour la presentation lue par l'observateur (TB-11a) : son
  /// plancher est [plancherPresentationLue], sa scene montre toutes ses
  /// rangees, et la tablette en paysage pose les surfaces cote a cote.
  final bool presentationLue;

  /// La hauteur sous laquelle le document ne descend pas (la colonne defile
  /// alors) : [_hauteurPlancherDocument] pour le panneau de l'enseignant,
  /// [plancherPresentationLue] pour la presentation lue.
  double get _plancherDocument =>
      presentationLue ? plancherPresentationLue : _hauteurPlancherDocument;

  /// TB-11a : le plancher de la presentation lue. La page se pose en
  /// `BoxFit.contain` dans toute hauteur : elle n'exige pas le plancher des
  /// `EmptyState` du panneau. Cinq respirations : la ligne du titre et de la
  /// page (deux ou trois lignes a 320 et texte x2) et la page sous elle.
  static const double plancherPresentationLue = AppSpacing.respiration * 5;

  /// La hauteur minimale du document, en dessous de laquelle la colonne defile.
  ///
  /// **Mesuree, pas choisie.** Deux etats du panneau ne defilent pas d'eux-memes
  /// -- ce sont des `EmptyState`, c'est-a-dire un `Center` sur une colonne de
  /// taille minimale : « rien n'est presente » demande un peu plus de quatre
  /// respirations et huit suffisent au plus haut des deux, celui du corpus
  /// absent, qui porte en plus un bouton. La page elle-meme, quand le corpus
  /// existe, defile dans son propre `ListView` et ne pese donc rien ici.
  ///
  /// **Le partage en fractions ne pouvait pas marcher, et c'est ce que la mesure
  /// a montre.** A 800 sur 600 -- la surface par defaut de `flutter_test`, donc
  /// une tablette en paysage -- trois cinquiemes de la place donnaient 269 points
  /// au document pour 464 demandes. Un plancher repond a la question une fois
  /// pour toutes, la ou une fraction la repose a chaque gabarit et a chaque
  /// echelle de texte.
  static const double _hauteurPlancherDocument = AppSpacing.respiration * 8;

  /// La bande reservee a la scene sous le document.
  ///
  /// Elle est FIXE et non proportionnelle, parce que le media est le deuxieme
  /// niveau de la hierarchie : il lui faut de quoi reconnaitre qui parle, pas une
  /// part de l'ecran. Trois respirations et non deux -- le plancher de la galerie
  /// -- parce que la vignette locale flotte a deux respirations de haut et se pose
  /// a `lg` du bord : une bande au plancher exact la ferait deborder de sa propre
  /// marge. Au dela de quatre visages la galerie defile a l'interieur, ce qu'elle
  /// sait faire seule (`_Galerie`, physique de defilement sous son plancher).
  static const double _hauteurScene = AppSpacing.respiration * 3;

  @override
  Widget build(BuildContext context) {
    final Widget panneau = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: document,
    );

    final Gabarit gabarit = AppGabarit.de(context);
    if (pageCoran && PageImmersive.telephonePaysage(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: panneau),
          SizedBox(
            width: largeurSceneLaterale,
            child: _Scene(vue: vue),
          ),
        ],
      );
    }
    if (pageCoran &&
        !gabarit.estLarge &&
        MediaQuery.orientationOf(context) == Orientation.portrait) {
      // La page a sa hauteur naturelle (largeur moins les gouttieres) ; la
      // scene se reduit en bande dessous ; la colonne seule defile.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: document,
            ),
            SizedBox(
              height: _hauteurScene,
              child: _Scene(vue: vue),
            ),
            if (_colonneDePresence(context, vue))
              _FondPresence(vue: vue, lignes: lignes),
          ],
        ),
      );
    }
    // TB-RC (TB_RAPPORT §d n° 23) : sur une tablette en paysage, empiler la
    // page et la scene reduisait la page de l'observateur a une vignette
    // (140 points de large a 1100 x 700) : la presentation lue y prend la
    // composition du bureau, la page a cote de la scene. L'orientation vient
    // de l'ecran, jamais d'une largeur comparee a un nombre.
    final bool coteACote =
        gabarit == Gabarit.desktop ||
        (presentationLue &&
            gabarit.estLarge &&
            MediaQuery.orientationOf(context) == Orientation.landscape);
    if (coteACote) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(flex: 3, child: panneau),
          Expanded(flex: 2, child: _Scene(vue: vue)),
          if (_colonneDePresence(context, vue))
            _ColonnePresence(vue: vue, lignes: lignes),
        ],
      );
    }
    // TB-11a (CT-3, tablette) : la presentation lue garde sur tablette la
    // colonne de presence LATERALE de la salle sans presentation (`_Corps`) :
    // la meme liste, au meme endroit, sur la meme surface (`surfaceSunken`
    // chez le controleur). Posee sous la scene, elle n'etait atteignable
    // qu'en defilant. Le panneau de l'enseignant garde sa composition.
    final bool presenceLaterale =
        gabarit.estLarge &&
        !_panneauEnseignant(vue) &&
        _colonneDePresence(context, vue);
    final Widget empile = _empiler(
      context,
      panneau,
      presenceSous: !presenceLaterale,
    );
    if (!presenceLaterale) {
      return empile;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: empile),
        _ColonnePresence(vue: vue, lignes: lignes),
      ],
    );
  }

  /// Le document, puis la scene dessous, puis (si [presenceSous]) la
  /// presence, dans une colonne qui defile.
  Widget _empiler(
    BuildContext context,
    Widget panneau, {
    required bool presenceSous,
  }) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        // Le document prend tout ce qui reste sous la bande de la scene, sans
        // jamais descendre sous son plancher. Sur un telephone de reference --
        // 390 sur 844 -- le compte est juste et rien ne defile : le groupe reste
        // visible sans un geste. Sur une surface courte, c'est la scene qui passe
        // sous la ligne de flottaison, et non le Coran qui se rogne.
        final double plancher = _plancherDocument;
        final double scene = presentationLue
            ? _hauteurSceneLue(context)
            : _hauteurScene;
        final double document = presentationLue
            ? _documentLu(contraintes, scene, plancher)
            : _borne(contraintes, scene, plancher);
        // Le defilement est toujours pose, et ne defile que s'il le faut : quand
        // la place suffit, la colonne fait exactement la hauteur offerte et rien
        // ne bouge. C'est ce qui met l'echelle de texte a 200 % hors de danger --
        // le contenu grandit, la colonne defile, rien ne se rogne.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: document, child: panneau),
              SizedBox(
                height: scene,
                child: _Scene(vue: vue),
              ),
              // La presence sous la scene, et non en feuille : la colonne defile
              // deja, elle a donc la place que `_Corps` n'a pas en largeur.
              // `_ListePresence` est une colonne de taille minimale, elle vit
              // sans hauteur bornee.
              // CT-3 : la meme surface que la colonne laterale.
              if (presenceSous && _colonneDePresence(context, vue))
                _FondPresence(vue: vue, lignes: lignes),
            ],
          ),
        );
      },
    );
  }

  /// Le document sous la bande de la scene, jamais sous son plancher.
  static double _borne(BoxConstraints c, double scene, double plancher) {
    final double reste = c.hasBoundedHeight ? c.maxHeight - scene : plancher;
    return reste < plancher ? plancher : reste;
  }

  /// Le nombre de visages de la galerie (comme [_Scene]).
  int get _distants => (vue.dominant != null ? 1 : 0) + vue.autres.length;

  /// TB-RC (TB_RAPPORT §d n° 5 et 11) : la bande de la scene de
  /// l'observateur montre TOUTES ses rangees a leur plancher, sans
  /// defilement interne. Une bande fixe de trois respirations coupait la
  /// seconde rangee de quatre visages au ras du rappel, sans nom ni indice.
  double _hauteurSceneLue(BuildContext context) => _distants <= 1
      ? _hauteurScene
      : _Galerie.hauteurEntiere(_distants, AppGabarit.de(context)) +
            AppSpacing.lg;

  /// TB-RC (TB_RAPPORT §d n° 5 et 11) : la ligne de flottaison ne tranche
  /// jamais une tuile. Trois cas, dans l'ordre :
  /// 1. tout tient : le document prend le reste, rien ne defile ;
  /// 2. sinon, si le document garde son plancher, la premiere rangee entiere
  ///    finit a la ligne de flottaison et la suivante commence dessous ;
  /// 3. sinon, le document remplit exactement la hauteur visible et la scene
  ///    commence sous la ligne de flottaison.
  /// La colonne defile dans les cas 2 et 3 (une seule zone qui defile).
  double _documentLu(BoxConstraints c, double scene, double plancher) {
    if (!c.hasBoundedHeight) return plancher;
    final double hauteur = c.maxHeight;
    if (hauteur - scene >= plancher) return hauteur - scene;
    final double premiere = _distants <= 1 ? scene : _Galerie.premiereRangee;
    if (hauteur - premiere >= plancher) return hauteur - premiere;
    return hauteur;
  }
}

/// La scene, et la presence quand l'ecran a la place de la garder ouverte.
class _Corps extends StatelessWidget {
  const _Corps({required this.vue, required this.lignes});

  final VueSalle vue;
  final List<_Presence> lignes;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final bool colonne = gabarit.estLarge && vue.voitLesParticipants;

    if (!colonne) {
      return _Scene(vue: vue);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _Scene(vue: vue)),
        _ColonnePresence(vue: vue, lignes: lignes),
      ],
    );
  }
}

/// La colonne de presence posee a cote du contenu, la meme pour `_Corps` et
/// `_CorpsDocument` : une seule mesure de colonne dans ce fichier.
class _ColonnePresence extends StatelessWidget {
  const _ColonnePresence({required this.vue, required this.lignes});

  final VueSalle vue;
  final List<_Presence> lignes;

  @override
  Widget build(BuildContext context) => SizedBox(
    // Une largeur de chrome, deja posee pour la barre laterale : la
    // reutiliser evite d'en inventer une seconde.
    width: AppGabarit.largeurBarreLaterale,
    child: _FondPresence(vue: vue, lignes: lignes, defile: true),
  );
}

/// La liste de presence sur sa surface : une seule decoration pour la
/// colonne laterale et la liste posee sous la scene (CT-3).
class _FondPresence extends StatelessWidget {
  const _FondPresence({
    required this.vue,
    required this.lignes,
    this.defile = false,
  });

  final VueSalle vue;
  final List<_Presence> lignes;

  /// TB-11a (CT-3, texte x2) : la colonne laterale a la hauteur de l'ecran,
  /// pas celle de sa liste. Sur une tablette en paysage (700 ou 768 de
  /// haut) et le texte agrandi, la liste depasse de 184 a 252 points : elle
  /// defile alors dans sa colonne, sous un fond qui garde toute la hauteur.
  /// Posee sous la scene, la liste vit deja dans une colonne qui defile.
  final bool defile;

  @override
  Widget build(BuildContext context) {
    final Widget liste = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _ListePresence(lignes: lignes, entete: true),
    );
    // CT-3, SALLE-ENCRE-1 : la liste se pose, pour tous les roles, sur la
    // surface des vignettes (`surfaceSunken`) : `SectionHeader` et
    // `LignePresence` portent l'encre des surfaces claires, illisible sur le
    // fond de la salle.
    final AppColorPair sunken = AppPalette.of(context).surfaceSunken;
    return DecoratedBox(
      decoration: sunken.decoration(),
      child: IconTheme.merge(
        data: IconThemeData(color: sunken.onBackground),
        child: defile
            ? SingleChildScrollView(
                // Lue par les tests CT-3 a texte x2.
                key: const ValueKey<String>('presence-defile'),
                primary: false,
                child: liste,
              )
            : liste,
      ),
    );
  }
}

/// TB-11a (plan V2 §5, UX-21) : la presentation de l'enseignant, lue par le
/// tuteur observateur et le controleur.
///
/// **Reutilisation, aucune copie (K-10)** : la surface est celle de la salle
/// de seance (`ZoneSupport`, qui pose `SurfacePageFixe` : la page dans son
/// ratio, l'affichage partage, le calque des notes). Au-dessus, une ligne
/// dit le titre du support et la page (« titre, page 3 sur 12 »). **Aucune commande** : ni pagination, ni zoom, ni affichage, ni
/// outil d'ecriture, ni rangement ; les commandes de l'observateur restent
/// celles de son role, en bas ou dans sa zone haute.
class _PresentationLue extends StatelessWidget {
  const _PresentationLue({required this.vue});

  /// La vue de lecture (`DepuisSalle.presentationObservee`).
  final VueSeance vue;

  /// La cle de la presentation lue (tests et captures).
  static const Key cle = ValueKey<String>('presentation-lue');

  /// La ligne du titre et de la page (tests et captures).
  static const Key cleTitre = ValueKey<String>('presentation-lue-titre');

  @override
  Widget build(BuildContext context) {
    final SupportPageFixe? page = vue.supportPresente;
    // L'encre du registre `salle` (fond de `PageImmersive`), comme la zone
    // haute du controleur : un style du theme porterait l'encre des surfaces
    // claires, illisible sur le fond de la salle.
    final AppColorPair salle = AppPalette.of(context).surfaceInverse;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (page != null) ...<Widget>[
          // TB-RC (TB_RAPPORT §d n° 18) : la position se dit en mots, dans la
          // ligne du titre (« Les bonnes manieres, page 3 sur 12 »), et non
          // par la pastille `IndicateurPage`, qui avait ici le style d'un
          // bouton plein a cote de « Quitter » sans rien commander. La ligne
          // passe a la ligne a texte agrandi (SALLE-200-1), jamais rognee.
          // Revue TB-R m12 : la surface dit deja ce titre et cette page au
          // lecteur d'ecran (`SurfacePageFixe`) ; la ligne n'est donc pas
          // relue (trois lectures avant : titre, page, surface).
          ExcludeSemantics(
            child: Text(
              t.salle.seance.surface.page(
                titre: page.titre,
                page: page.page,
                pages: page.total,
              ),
              key: cleTitre,
              style: salle.applyTo(
                Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vMd,
        ],
        Expanded(child: ZoneSupport(vue: vue)),
      ],
    );
  }
}

/// La scene : les autres en galerie, soi-meme en vignette, et ce qui s'affiche
/// quand on est seul.
///
/// **Elle etait dimensionnee pour deux, et le pivot du 19 septembre 2026 en
/// demande six.** La version precedente posait les vignettes dans une `Row` non
/// defilante de 96 points chacune : six participants demandaient 624 points
/// contre 390 de large sur un telephone, donc un debordement certain -- et il
/// etait deja mesure a deux, par le test d'invisibilite du controleur, ou une
/// vignette de 96x128 ne contenait pas son propre bloc « sans image ».
class _Scene extends StatelessWidget {
  const _Scene({required this.vue, this.attendu});

  final VueSalle vue;

  /// Le prenom de l'enseignant attendu, pour l'attente de l'eleve.
  final String? attendu;

  @override
  Widget build(BuildContext context) {
    // Les distants dans l'ordre de lecture que la vue a decide : le role
    // attendu d'abord, les autres ensuite. L'ordre ne bouge pas quand quelqu'un
    // ouvre son micro.
    final List<ParticipantSalle> distants = <ParticipantSalle>[
      if (vue.dominant case final ParticipantSalle premier) premier,
      ...vue.autres,
    ];

    // La vignette locale n'apparait que quand la camera publie : la fiche
    // produit le demande explicitement (« elle disparait si sa camera est
    // coupee »), et l'etat du micro est deja dans les commandes. Elle reste
    // FLOTTANTE et seule -- un seul cadre de 96 points tient partout, et se
    // voir parmi les autres serait se compter comme un eleve.
    final ParticipantSalle? moi = switch (vue.moi) {
      final ParticipantSalle local when local.camera => local,
      _ => null,
    };

    // VIDEO-TUILE-1 : aucune tuile ne touche le bord de l'ecran -- la
    // gouttiere mobile (16 px) de chaque cote -- ni ne passe sous le bandeau
    // ou les commandes du bas : 16 px d'ecart dessous (SUPERPOS-1).
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: _pile(distants, moi),
    );
  }

  Widget _pile(List<ParticipantSalle> distants, ParticipantSalle? moi) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: distants.isEmpty
              ? _Seul(role: vue.role, attendu: attendu)
              : _Galerie(participants: distants),
        ),
        if (moi case final ParticipantSalle local)
          PositionedDirectional(
            bottom: AppSpacing.lg,
            end: AppSpacing.lg,
            child: SizedBox(
              // Derive de l'echelle, jamais posee : une vignette vaut une
              // respiration et demie de large.
              width: AppSpacing.respiration * 1.5,
              height: AppSpacing.respiration * 2,
              child: _Cadre(
                key: ValueKey<String>(local.identite),
                participant: local,
                moi: true,
                compact: true,
              ),
            ),
          ),
      ],
    );
  }
}

/// Les participants distants, tous visibles, aucun rogne.
///
/// **La hauteur d'une tuile se deduit de la place reelle, elle ne se pose
/// jamais** : c'est la seule maniere de garantir qu'a un comme a six, rien ne
/// sort de l'ecran. En dessous d'un plancher -- au dela de six personnes, ce que
/// le seuil de groupe interdit deja en base -- la galerie prefere defiler
/// plutot que de reduire les visages a rien.
///
/// `[RESPONSIVE]` Le nombre de colonnes vient du gabarit, jamais d'une
/// comparaison de largeur : `AppGabarit` est le seul fichier du depot autorise
/// a comparer une largeur a un nombre.
class _Galerie extends StatelessWidget {
  const _Galerie({required this.participants});

  final List<ParticipantSalle> participants;

  /// La hauteur en dessous de laquelle une tuile ne montre plus rien d'utile.
  static const double _hauteurPlancher = AppSpacing.respiration * 2;

  /// L'ecart entre deux tuiles (K-55, VIDEO-TUILE-1) : 16 px.
  static const double _ecart = AppSpacing.lg;

  /// Le nombre de colonnes pour [total] tuiles dans [gabarit].
  static int _colonnes(int total, Gabarit gabarit) => switch (total) {
    2 => gabarit.estLarge ? 2 : 1,
    3 || 4 => 2,
    _ => gabarit.estLarge ? 3 : 2,
  };

  /// TB-RC (TB_RAPPORT §d n° 5 et 11) : la hauteur ou toutes les rangees de
  /// [total] tuiles tiennent a leur plancher, sans defilement interne.
  static double hauteurEntiere(int total, Gabarit gabarit) {
    final int colonnes = _colonnes(total, gabarit);
    final int lignes = (total + colonnes - 1) ~/ colonnes;
    return lignes * _hauteurPlancher + (lignes - 1) * _ecart;
  }

  /// La premiere rangee a son plancher, et l'ecart qui la suit : la rangee
  /// suivante commence juste apres.
  static const double premiereRangee = _hauteurPlancher + _ecart;

  @override
  Widget build(BuildContext context) {
    // Un seul distant : il occupe tout, exactement comme avant le pivot. C'est
    // le cas du cours a deux, et la raison pedagogique tient toujours -- les
    // makharij se lisent sur une bouche, pas sur une mosaique.
    if (participants.length == 1) {
      return _Cadre(
        key: ValueKey<String>(participants.first.identite),
        participant: participants.first,
        moi: false,
      );
    }

    final Gabarit gabarit = AppGabarit.de(context);
    final int total = participants.length;
    final int colonnes = _colonnes(total, gabarit);
    final int lignes = (total + colonnes - 1) ~/ colonnes;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // La hauteur est arrondie vers le bas : une fraction de point en trop
        // ferait deborder la derniere rangee et rognerait ses coins.
        final double largeur =
            (contraintes.maxWidth - _ecart * (colonnes - 1)) / colonnes;
        final double disponible =
            ((contraintes.maxHeight - _ecart * (lignes - 1)) / lignes)
                .floorToDouble();
        final double hauteur = disponible < _hauteurPlancher
            ? _hauteurPlancher
            : disponible;

        return GridView.count(
          crossAxisCount: colonnes,
          mainAxisSpacing: _ecart,
          crossAxisSpacing: _ecart,
          childAspectRatio: largeur / hauteur,
          // Tant que tout tient, la galerie ne defile pas : un geste vertical
          // dans une salle doit rester sans effet, sous peine de faire croire
          // qu'on a raccroche.
          physics: disponible < _hauteurPlancher
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (final ParticipantSalle personne in participants)
              _Cadre(
                key: ValueKey<String>(personne.identite),
                participant: personne,
                moi: personne.estLocal,
                // Une tuile de galerie a six est deja courte : la legende
                // « sans image » n'y tiendrait pas a cote de l'avatar.
                compact: hauteur <= _hauteurPlancher,
              ),
          ],
        );
      },
    );
  }
}

/// Le cadre d'un participant : son image si elle existe, son nom sinon.
class _Cadre extends ConsumerWidget {
  const _Cadre({
    required this.participant,
    required this.moi,
    super.key,
    this.compact = false,
  });

  final ParticipantSalle participant;
  final bool moi;

  /// Vrai dans un cadre trop court pour porter une legende sous l'avatar.
  ///
  /// C'est ce qui manquait : le bloc « sans image » etait dessine a l'identique
  /// dans le grand cadre et dans une vignette de 96x128, ou il depassait de huit
  /// points -- et c'est cet ecart, et rien d'autre, qui faisait echouer le test
  /// d'invisibilite du controleur depuis le pivot.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // **L'ecran ne recoit pas une piste, il recoit un widget deja monte.** C'est
    // ainsi que la portabilite de l'ADR-001 survit au rendu : aucun import de
    // `livekit_client` ici, et changer de moteur ne rouvrirait pas cet ecran.
    final Widget? image = ref
        .watch(moteurSalleProvider)
        .renduVideo(participant.identite);

    final String nom = moi ? t.salle.vousMeme : participant.nom;

    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: metriques.arrondi,
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Stack(
          children: <Widget>[
            // VIDEO-TUILE-1 : sans image, le cercle et le nom centre dessous,
            // ensemble au centre ; l'etiquette du bas n'existe qu'au-dessus
            // d'une video reelle.
            Positioned.fill(
              child: image ?? _SansImage(participant: participant, nom: nom),
            ),
            if (image != null)
              PositionedDirectional(
                start: AppSpacing.sm,
                bottom: AppSpacing.sm,
                end: AppSpacing.sm,
                // Une seule lecture pour les technologies d'assistance : le nom,
                // puis ce qui manque. Trois elements separes feraient trois
                // annonces pour une personne.
                child: MergeSemantics(
                  child: Row(
                    children: <Widget>[
                      if (!participant.micro)
                        IconTheme(
                          data: IconThemeData(
                            color: palette.surfaceSunken.onBackground,
                            size: AppSpacing.xl,
                          ),
                          child: Icon(
                            AppIcons.microCoupe.repos,
                            semanticLabel: t.salle.microCoupe,
                          ),
                        ),
                      if (!participant.micro) Ecart.hXs,
                      Flexible(
                        child: TexteSansCoupure(
                          nom,
                          style: palette.surfaceSunken.applyTo(
                            textes.labelMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui occupe un cadre sans image : la tuile partagee (VIDEO-TUILE-1).
///
/// « Sans image » ne s'ecrit plus : le cercle le dit. Il reste annonce aux
/// technologies d'assistance, pour qui rien ne se voit.
class _SansImage extends StatelessWidget {
  const _SansImage({required this.participant, required this.nom});

  final ParticipantSalle participant;

  /// Le nom affiche (« Vous » pour soi).
  final String nom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return TuileSansImage(
      prenom: participant.nom,
      nom: nom,
      libelleSansImage: t.salle.sansImage,
      libelleMicroCoupe: participant.micro ? null : t.salle.microCoupe,
      couleurIcone: palette.surfaceSunken.onBackground,
      styleNom: palette.surfaceSunken.applyTo(
        textes.labelMedium ?? const TextStyle(),
      ),
    );
  }
}

/// Seul dans la salle.
///
/// Lot salle 2 (directeur, 25/10/2026, capture du telephone de l'eleve) :
/// l'attente etait un texte blanc sur gris clair, illisible. Elle se pose sur
/// sa propre surface teintee du theme (`surfaceSunken`, jamais du blanc pur),
/// avec l'ornement de la marque, un titre qui nomme qui l'on attend et une
/// phrase : ce qui se passe et quoi faire. Encre de la surface (contraste
/// > 4,5:1, clair et sombre). Le depart de l'enseignant ramene ici.
class _Seul extends StatelessWidget {
  const _Seul({required this.role, this.attendu});

  final RoleSalle role;

  /// Le prenom de l'enseignant attendu (eleve), s'il est connu. Le titre
  /// Sayyid / Sayyida n'est pas lu dans `/salle` : le prenom seul, jamais
  /// « le professeur » (TB-10).
  final String? attendu;

  /// La cle de l'attente (tests, captures).
  static const Key cle = ValueKey<String>('salle-attente');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? nom = attendu?.trim();

    // Qui manque depend de qui attend. « Un participant n'est pas connecte »
    // serait vrai et inutile : l'enfant attend son professeur, le professeur
    // attend son eleve, et l'observateur attend que le cours commence.
    final (String, String) phrase = switch (role) {
      RoleSalle.eleve => (
        nom == null || nom.isEmpty
            ? t.salle.seulEnseignant
            : t.salle.attenteDe(deNom: deDevant(nom, cle: 'salle.attenteDe')),
        t.salle.seulEnseignantDetail,
      ),
      RoleSalle.enseignant => (t.salle.seulEleve, t.salle.seulEleveDetail),
      RoleSalle.tuteurObservateur ||
      RoleSalle.controleur ||
      RoleSalle.administrateurIncognito ||
      RoleSalle.administrateurVisible ||
      RoleSalle.inconnu => (
        t.salle.seulObservation,
        t.salle.seulObservationDetail,
      ),
    };

    // SALLE-200-1 : la phrase d'attente defile plutot que de deborder quand
    // le texte est agrandi sur un petit ecran.
    return DecoratedBox(
      key: cle,
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const OrnementMarque(taille: TailleOrnement.grand),
              Ecart.vLg,
              Text(
                phrase.$1,
                textAlign: TextAlign.center,
                style: palette.surfaceSunken.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
              Ecart.vSm,
              Text(
                phrase.$2,
                textAlign: TextAlign.center,
                style: palette.surfaceSunken.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une personne de la seance, telle que la liste la montre.
///
/// **Les inscrits comme ossature, la video comme complement, et l'ordre
/// compte.** Celui qui n'est jamais arrive n'a aucune piste LiveKit, donc
/// aucune ligne cote moteur -- et c'est justement de lui que l'enseignant a
/// besoin de savoir quelque chose. Batir la liste sur les participants
/// connectes reviendrait a ne montrer que ceux dont on n'a pas a s'inquieter.
@immutable
class _Presence {
  const _Presence({
    required this.nom,
    required this.role,
    required this.vue,
    this.micro,
    this.academyId,
  });

  /// Compose la liste que l'ecran affiche.
  ///
  /// Quand la presence est indisponible, la liste retombe sur les participants
  /// que le moteur connait, chacun avec un etat **inconnu** -- et non « absent »
  /// (invariant J3). Une salle ne perd pas sa liste parce qu'une requete a
  /// echoue ; elle perd ce qu'elle ne sait pas, et le dit.
  static List<_Presence> composer({
    required List<PresenceParticipant>? presence,
    required VueSalle vue,
    required String? monProfil,
    required DateTime maintenant,
  }) {
    if (presence == null) {
      return <_Presence>[
        for (final ParticipantSalle personne in vue.participantsListes)
          _Presence(
            nom: personne.estLocal ? t.salle.vousMeme : personne.nom,
            role: _libelleRole(personne.role),
            vue: VuePresence.depuis(ligne: null, maintenant: maintenant),
            micro: personne.micro,
          ),
      ];
    }

    return <_Presence>[
      for (final PresenceParticipant ligne in tableauDePresence(presence))
        _Presence(
          nom: ligne.profilId == monProfil ? t.salle.vousMeme : ligne.prenom,
          role: _libelleRole(ligne.role),
          vue: VuePresence.depuis(ligne: ligne, maintenant: maintenant),
          // La base emet `identity = profile_id` : le rapprochement se fait
          // donc sans table de correspondance. `null` quand la personne n'est
          // pas dans la salle -- et « pas de micro » ne se dit pas alors, parce
          // que ce serait un fait, la ou il n'y a qu'une absence de fait.
          micro: _microDe(vue.participantsListes, ligne.profilId),
          academyId: ligne.identifiantImmuable,
        ),
    ];
  }

  /// L'etat du micro d'une personne, si le moteur la connait.
  static bool? _microDe(List<ParticipantSalle> connectes, String profilId) {
    for (final ParticipantSalle personne in connectes) {
      if (personne.identite == profilId) {
        return personne.micro;
      }
    }
    return null;
  }

  /// Le role de seance, en mots. Un role inconnu ne s'affiche pas du tout
  /// plutot que de s'afficher faux : le vocabulaire vit en base et grandira.
  ///
  /// `administrateurVisible` porte le nom institutionnel ("Administration
  /// Rewayah") : c'est une identite ouvertement declaree, pas une observation
  /// masquee. `administrateurIncognito` reste muet comme `controleur` -- lui
  /// afficher un nom romprait le masquage que `entrer_observation` applique
  /// cote base.
  static String _libelleRole(String brut) => switch (RoleSalle.depuis(brut)) {
    RoleSalle.enseignant => t.salle.roleEnseignant,
    RoleSalle.eleve => t.salle.roleEleve,
    RoleSalle.tuteurObservateur => t.salle.roleTuteur,
    RoleSalle.administrateurVisible => t.salle.roleAdministration,
    RoleSalle.controleur ||
    RoleSalle.administrateurIncognito ||
    RoleSalle.inconnu => '',
  };

  final String nom;
  final String role;
  final VuePresence vue;

  /// Micro ouvert, ferme, ou absent de la salle.
  final bool? micro;

  /// L'identifiant immuable (matricule) de la personne, qui relie sa ligne a
  /// sa fiche du roster ; `null` sans presence lue.
  final String? academyId;
}

/// La presence de la seance, pour qui a le droit de la lire.
///
/// Le meme corps en colonne et en feuille : deux rendus d'une meme liste
/// finiraient par ne plus dire la meme chose, et c'est precisement ce que le
/// lot N3 a evite en refusant trois ecrans de salle.
class _ListePresence extends StatelessWidget {
  const _ListePresence({required this.lignes, this.entete = false});

  final List<_Presence> lignes;

  /// L'en-tete de section, en colonne seulement : la feuille a deja son titre.
  final bool entete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (entete) ...<Widget>[
          SectionHeader(titre: t.presence.titre, compteur: lignes.length),
          Ecart.vMd,
        ],
        for (final _Presence personne in lignes) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: LignePresence(
                  nom: personne.nom,
                  role: personne.role,
                  vue: personne.vue,
                ),
              ),
              // Le micro n'apparait que pour qui est dans la salle : un micro
              // barre a cote de « Pas encore la » dirait deux fois la meme
              // chose, et la deuxieme serait fausse.
              if (personne.micro case final bool ouvert) ...<Widget>[
                Ecart.hSm,
                Icon(
                  ouvert ? AppIcons.micro.repos : AppIcons.microCoupe.repos,
                  semanticLabel: ouvert
                      ? t.presence.etatMicroOuvert
                      : t.presence.etatMicroCoupe,
                  size: AppSpacing.xl,
                ),
              ],
            ],
          ),
          Ecart.vMd,
        ],
      ],
    );
  }
}

/// Les commandes, selon ce que le jeton permet.
///
/// **Le nombre de commandes decoule du jeton, jamais du mode d'interface.** La
/// fiche produit annonce « deux commandes seulement » en mode enfant : c'est le
/// resultat, pas la regle. Un mineur a `camera_policy` a `forbidden` par
/// defaut, donc son jeton refuse l'image, donc le bouton n'existe pas -- il
/// reste le micro et la sortie. Coder le mode plutot que le jeton priverait de
/// sa camera l'enfant dont le tuteur l'a justement autorisee.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.vue,
    required this.onMicro,
    required this.onCamera,
    required this.onQuitter,
  });

  final VueSalle vue;
  final Future<void> Function(bool ouvert) onMicro;
  final Future<void> Function(bool ouverte) onCamera;
  final Future<void> Function() onQuitter;

  @override
  Widget build(BuildContext context) {
    final bool microOuvert = vue.moi?.micro ?? false;
    final bool cameraOuverte = vue.moi?.camera ?? false;
    // Les quatre phases ou la seance continue, reunies par la vue : un lien
    // instable ou un retour de coupure ne ferme pas un micro.
    final bool enSalle = vue.dansLaSalle;

    // SALLE-CORR-3 (releve VERIF-CORR-2) : a 320 px, la rangee de
    // l'enseignant (micro, camera, quitter) debordait de 8 px. Elle se serre
    // d'abord (ecart reduit entre les disques, libelles intacts) ; si cela ne
    // suffit pas encore, elle passe en rangee compacte (EN-12 : « Quitter »
    // en icone, nom en infobulle et lu ; les bascules gardent leur mot).
    final int bascules = (vue.peutParler ? 1 : 0) + (vue.peutMontrer ? 1 : 0);
    // ETATS-MA-1 (decision du 05/10/2026, WCAG 1.4.1) : en Mode
    // Accessibilite, texte au-dela de 130 %, les commandes passent sur deux
    // rangees ; les bascules y gardent leur mot d'etat.
    if (bascules > 0 && commandesSurDeuxRangees(context)) {
      return CommandesSurDeuxRangees(
        diametre: AppMetriques.of(context).cibleTactile,
        commandes: _commandes(microOuvert, cameraOuverte, enSalle, 0),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // La largeur de la rangee, avec [cotes] d'ecart autour de chaque disque.
        double besoin(double cotes) =>
            bascules * (largeurCaseCommande(context, bascule: true) + cotes) +
            math.max(
              diametreCommandeSalle(context),
              _largeurMot(context, t.salle.quitter),
            ) +
            cotes;
        final double ecart = besoin(2 * AppSpacing.sm) <= contraintes.maxWidth
            ? AppSpacing.sm
            : AppSpacing.xs;
        return _RangeeCompacte(
          serree: besoin(2 * ecart) > contraintes.maxWidth,
          child: _rangee(microOuvert, cameraOuverte, enSalle, ecart),
        );
      },
    );
  }

  Widget _rangee(
    bool microOuvert,
    bool cameraOuverte,
    bool enSalle,
    double ecart,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: _commandes(microOuvert, cameraOuverte, enSalle, ecart),
  );

  List<Widget> _commandes(
    bool microOuvert,
    bool cameraOuverte,
    bool enSalle,
    double ecart,
  ) => <Widget>[
    // Un controle que le jeton refuse n'est PAS rendu, et n'est jamais
    // grise : un bouton visible mais inactif invite a appuyer dessus, son
    // absence ne pose pas la question.
    if (vue.peutParler)
      _Commande(
        ecart: ecart,
        icone: microOuvert ? AppIcons.micro : AppIcons.microCoupe,
        libelle: microOuvert ? t.salle.microOuvert : t.salle.microCoupe,
        acte: microOuvert ? t.salle.fermerMicro : t.salle.ouvrirMicro,
        bascule: microOuvert,
        onPress: enSalle ? () => unawaited(onMicro(microOuvert)) : null,
      ),
    if (vue.peutMontrer)
      _Commande(
        ecart: ecart,
        icone: cameraOuverte ? AppIcons.camera : AppIcons.cameraCoupee,
        libelle: cameraOuverte ? t.salle.cameraAllumee : t.salle.cameraCoupee,
        acte: cameraOuverte ? t.salle.fermerCamera : t.salle.ouvrirCamera,
        bascule: cameraOuverte,
        onPress: enSalle ? () => unawaited(onCamera(cameraOuverte)) : null,
      ),
    _Commande(
      ecart: ecart,
      icone: AppIcons.sortie,
      libelle: t.salle.quitter,
      acte: t.salle.quitterLeCours,
      onPress: () => unawaited(onQuitter()),
    ),
  ];
}

/// La largeur d'un mot de commande, au style et a l'echelle de texte courants.
double _largeurMot(BuildContext context, String mot) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(text: mot, style: Theme.of(context).textTheme.labelMedium),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
}

/// SALLE-200-1 (revue du directeur, constat CTRL-SALLE-1) : texte agrandi
/// au-dela du seuil, les commandes de la salle passent en icones seules,
/// compactes, a la cible tactile (le nom reste lu et montre en infobulle,
/// [CommandeSalle]). Elles laissent la hauteur au support partage. A x1 et
/// jusqu'au seuil, rien ne change. [serree] : la rangee ne tient pas sa
/// largeur meme a ecart reduit (SALLE-CORR-3), meme repli.
class _RangeeCompacte extends StatelessWidget {
  const _RangeeCompacte({required this.child, this.serree = false});

  final Widget child;
  final bool serree;

  @override
  Widget build(BuildContext context) {
    if (motEtatVisible(context) && !serree) return child;
    return CommandeSalleCompacte(
      diametre: AppMetriques.of(context).cibleTactile,
      child: child,
    );
  }
}

/// Une commande de la salle : [CommandeSalle] (core), le meme composant que le
/// dock de la seance. Un disque, une icone, un mot, et l'acte pour qui ecoute.
///
/// Deux libelles, et ils ne disent pas la meme chose. **Le mot visible dit
/// l'ETAT** d'une bascule (« Micro ouvert » / « Micro coupe ») ou le nom d'une
/// commande ordinaire (« Quitter ») ; **le libelle parle dit l'ACTE** (« Fermer
/// le micro »), parce qu'un bouton se lit par ce qu'il declenche.
///
/// ETATS-BTN-1 : l'etat d'une bascule se lit par trois signaux cumules, jamais
/// par la couleur seule : le disque (plein actif, contour seul inactif),
/// l'icone (micro / micro barre) et le mot d'etat.
class _Commande extends StatelessWidget {
  const _Commande({
    required this.icone,
    required this.libelle,
    required this.acte,
    required this.onPress,
    this.bascule,
    this.ecart = AppSpacing.sm,
  });

  final AppIcon icone;
  final String libelle;
  final String acte;

  /// `null` : commande ordinaire (Quitter). Sinon l'etat de la bascule.
  final bool? bascule;
  final VoidCallback? onPress;

  /// L'ecart de chaque cote du disque (reduit quand la rangee est serree).
  final double ecart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ecart),
      child: CommandeSalle(
        icone: icone.resoudre(selectionne: bascule ?? false),
        libelle: libelle,
        libelleSemantique: acte,
        bascule: bascule,
        onPress: onPress,
        // SALLE-CORR-3 (releve VERIF-CORR-2) : la rangee se pose TOUJOURS sur
        // le fond du registre `salle` (`surfaceInverse`, `PageImmersive`).
        // L'encre du theme (`inkStrong`) y ecrivait sombre sur sombre en
        // clair, clair sur clair en sombre ; le mot et l'icone d'une bascule
        // a contour seul prennent donc l'encre de la paire du registre, pour
        // tous les roles (avant : controleur et Mode Accessibilite seuls).
        encreLibelle: AppPalette.of(context).surfaceInverse,
      ),
    );
  }
}

/// L'impasse : ce qui bloque, et la seule chose a faire.
class _Impasse extends StatelessWidget {
  const _Impasse({
    required this.cause,
    required this.onReessayer,
    required this.onRentrer,
  });

  final CauseImpasse cause;
  final Future<void> Function() onReessayer;
  final VoidCallback onRentrer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Une cause, un message, une reparation. Le detail dit ou se trouve la
    // faute : sur l'appareil, dans l'heure, ou chez nous. Sans cela, l'usager
    // cherche toujours de son cote.
    final (String, String) dit = switch (cause) {
      CauseImpasse.materiel => (
        t.salle.refusMateriel,
        t.salle.refusMaterielDetail,
      ),
      CauseImpasse.acces => (t.salle.refusAcces, t.salle.refusAccesDetail),
      CauseImpasse.configuration => (
        t.salle.refusConfiguration,
        t.salle.refusConfigurationDetail,
      ),
      CauseImpasse.reseau => (t.salle.refusReseau, t.salle.refusReseauDetail),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              dit.$1,
              textAlign: TextAlign.center,
              style: _encreSalle(context, textes.titleMedium),
            ),
            Ecart.vSm,
            Text(
              dit.$2,
              textAlign: TextAlign.center,
              style: _encreSalle(context, textes.bodyMedium),
            ),
            Ecart.vXxl,
            // Une seule action principale : reessayer quand cela a un sens,
            // rentrer sinon. Un refus d'acces ne se reessaye pas, l'heure
            // n'aura pas change.
            if (cause.seReessaye) ...<Widget>[
              ActionPrincipale(
                libelle: t.commun.reessayer,
                onPress: () => unawaited(onReessayer()),
              ),
              Ecart.vMd,
              ActionPrincipale(
                libelle: t.salle.retourAccueil,
                onPress: onRentrer,
                niveau: NiveauAction.secondaire,
              ),
            ] else
              ActionPrincipale(
                libelle: t.salle.retourAccueil,
                onPress: onRentrer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Le chemin du cahier de [seanceId], ou `null` s'il ne peut pas s'ouvrir :
/// seance inconnue, ou aucune route du [routeur] ne le reconnait.
@visibleForTesting
String? cheminCahierOuvrable(RouteConfiguration routeur, String seanceId) {
  if (seanceId.isEmpty) return null;
  final String chemin = Routes.cahierPour(seanceId);
  return routeur.findMatch(Uri.parse(chemin)).isEmpty ? null : chemin;
}

/// La preparation de l'enseignant sur les vraies lectures : le pre-vol
/// (`preVolProvider`, seul chemin), la connectivite, et la preparation de la
/// seance deja affichee dans la Classe. Aucun jeton n'est demande ici.
class _PreparationBranchee extends ConsumerWidget {
  const _PreparationBranchee({
    required this.groupeId,
    required this.onEntrer,
    required this.onRetour,
  });

  final String? groupeId;
  final VoidCallback onEntrer;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> horsLigne = ref.watch(horsLigneProvider);
    final String? groupe = groupeId;
    final PreparationSeance? preparation = groupe == null
        ? null
        : ref.watch(preparationSeanceProvider(groupe));
    return PageShell(
      defilante: false,
      actionsCoquille: false,
      // La preparation porte son propre message hors ligne (L3-07-reprise).
      bandeauHorsLigne: const SizedBox.shrink(),
      child: PreparationEnseignant(
        resultat: ref.watch(preVolProvider).value,
        reseau: switch (horsLigne.value) {
          null => horsLigne.hasError ? ReseauPreparation.bonne : null,
          true => ReseauPreparation.horsLigne,
          false => ReseauPreparation.bonne,
        },
        contexte: ContextePreparation(
          support: preparation?.supportPrevu,
          reprise: preparation?.positionReprise,
        ),
        onEntrer: onEntrer,
        onRetour: onRetour,
        onReessayer: () => ref.invalidate(preVolProvider),
      ),
    );
  }
}

/// La preparation de l'eleve sur les vraies lectures (CL-4.6) : le pre-vol
/// (`preVolProvider`, seul chemin) et la connectivite (une erreur de lecture
/// vaut « en ligne »). Aucun jeton n'est demande ici.
class _PreparationEleveBranchee extends ConsumerWidget {
  const _PreparationEleveBranchee({
    required this.guidee,
    required this.onEntrer,
    required this.onRetour,
  });

  final bool guidee;
  final void Function({required bool sansMicro}) onEntrer;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> horsLigne = ref.watch(horsLigneProvider);
    return PageShell(
      defilante: false,
      actionsCoquille: false,
      // La preparation porte son propre message hors ligne (L3-07-reprise).
      bandeauHorsLigne: const SizedBox.shrink(),
      child: PreparationEleve(
        guidee: guidee,
        resultat: ref.watch(preVolProvider).value,
        reseau: switch (horsLigne.value) {
          null => horsLigne.hasError ? ReseauPreparation.bonne : null,
          true => ReseauPreparation.horsLigne,
          false => ReseauPreparation.bonne,
        },
        onEntrer: () => onEntrer(sansMicro: false),
        onContinuerSansMicro: () => onEntrer(sansMicro: true),
        onRetour: onRetour,
        onReessayer: () => ref
          ..invalidate(preVolProvider)
          ..invalidate(horsLigneProvider),
      ),
    );
  }
}

/// Un style de texte avec l'encre du registre `salle` (`surfaceInverse`),
/// pour tous les roles (SALLE-ENCRE-1, d'abord reserve a l'eleve en Mode
/// Accessibilite par MA-5) : le style du theme porte l'encre des surfaces
/// claires, sombre sur sombre en clair, clair sur clair en sombre.
TextStyle _encreSalle(BuildContext context, TextStyle? style) =>
    AppPalette.of(context).surfaceInverse.applyTo(style ?? const TextStyle());

/// SALLE-CORR-4 (m10) : la mention permanente se lit sur le fond de la salle.
///
/// `PermanentNotice` n'a aucun parametre (ADR-011) et ecrit en `inkMuted`, l'encre
/// secondaire des surfaces claires : grise sur le fond sombre de la salle en
/// clair, peu lisible dans les deux themes. Plutot que de toucher son API, la
/// salle lui prete, pour ses descendants seulement, une palette dont l'encre
/// secondaire est celle du registre `salle` (`surfaceInverse`), comme
/// `_encreSalle` pour les autres textes. Aucune couleur nouvelle.
class _EncreDeLaSalle extends StatelessWidget {
  const _EncreDeLaSalle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final List<ThemeExtension<ThemeExtension<dynamic>>> extensions =
        <ThemeExtension<ThemeExtension<dynamic>>>[
          ...theme.extensions.values
              .where((ThemeExtension<dynamic> e) => e is! AppPalette)
              .cast<ThemeExtension<ThemeExtension<dynamic>>>(),
          palette.copyWith(
            inkMuted: AppInkColor(palette.surfaceInverse.onBackground),
          ),
        ];
    return Theme(
      data: theme.copyWith(extensions: extensions),
      child: child,
    );
  }
}

/// MA-5 : un composant partage fait pour une surface claire se pose, pour
/// l'eleve en Mode Accessibilite, sur la surface des vignettes
/// (`surfaceSunken`), comme la colonne de presence du controleur (CT-3).
class _SurLaSalle extends StatelessWidget {
  const _SurLaSalle({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final AppColorPair sunken = AppPalette.of(context).surfaceSunken;
    return DecoratedBox(
      decoration: sunken.decoration(),
      child: IconTheme.merge(
        data: IconThemeData(color: sunken.onBackground),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      ),
    );
  }
}
