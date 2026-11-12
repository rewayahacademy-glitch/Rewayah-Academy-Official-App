import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/accessibilite/age_eleve.dart';
import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/coran/service_coran.dart' show pagesMushafMedine;
import '../../core/coran/vue_lecteur.dart' show EtatLecteur;
import '../../core/domain/enums.dart';
import '../../core/enseignant/modeles_enseignant.dart'
    show GroupeEnseignant, SeanceEnseignant;
import '../../core/enseignant/service_enseignant.dart'
    show groupesEnseignantProvider, seancesEnseignantProvider;
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/passage_salle.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/profil/service_profil_enseignant.dart'
    show ProfilEnseignant, profilEnseignantParIdProvider;
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_classe/controleur_recitation.dart';
import '../../core/tc_classe/port_rappel_discret.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/rappel_discret.dart'
    show RelaisRappelSalle, portRappelDiscretProvider;
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/chrono_seance.dart' show BornesChrono;
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_parcours/port_signalement.dart'
    show portSignalementProvider;
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/fermeture_salle.dart';
import '../../core/video/garde_fermeture.dart';
import '../../core/video/gestes_salle.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/politique_camera.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/publication_differee.dart';
import '../../core/video/releve_qualite.dart';
import '../../core/video/repli_audio.dart';
import '../../core/video/service_video.dart';
import '../../core/video/seuils_reseau.dart';
import '../../core/video/signal_rappel.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/commande_salle.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/entree_arche.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/offline_banner.dart' show ReserveCoinFin;
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/texte_protege.dart';
import '../accueil_eleve/apres_seance_accessibilite.dart';
import '../controleur/compte_rendu_controle.dart' show adresseCompteRendu;
import '../fiche_groupe/etape_eleve.dart' show etapesElevesClasseProvider;
import '../fiche_groupe/fiche_eleve_enseignant.dart' show signalementDisponible;
import '../fiche_groupe/observations_eleve.dart'
    show observationsClasseProvider;
import '../fiche_groupe/preparation_seance.dart';
import '../ma_classe_adulte/ma_classe_adulte_page.dart'
    show ParticipantClasseAdulte, maClasseAdulteProvider;
import '../salle_enseignant/page_coran_salle.dart';
import '../salle_enseignant/panneau_enseignant.dart';
import '../salle_enseignant/presentation_coran.dart'
    show contenuPresenteProvider, presentateurCoranProvider;
import '../salle_seance/actions_seance.dart';
import '../salle_seance/annonce_geste.dart';
import '../salle_seance/bornes_salle.dart';
import '../salle_seance/depuis_salle.dart';
import '../salle_seance/ecriture_seance.dart'
    show
        diffusionEcritureProvider,
        diffusionPointeurProvider,
        pointeurDistantProvider;
import '../salle_seance/lecteur_support.dart';
import '../salle_seance/marque_chrono.dart';
import '../salle_seance/media_salle.dart';
import '../salle_seance/notes_deposees.dart';
import '../salle_seance/panneau_bibliotheque_salle.dart';
import '../salle_seance/presentation_observee.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/signalement_seance.dart';
import '../salle_seance/vue_seance.dart';
import '../salle_seance/zone_support.dart';
import '../tc_espace_groupe/roster_classe.dart';
import '../tc_flux_academique/carte_feedback_seance.dart';
import '../tc_mes_groupes/chemins_tc_a.dart';
import '../tc_observation_ui/indicateur_observation.dart';
import 'annuaire_seance.dart';
import 'fiche_seance.dart';
import 'memoire_page_classe.dart';
import 'position_reprise.dart';
import 'preparation_eleve.dart';
import 'preparation_enseignant.dart';
import 'reprise_support.dart';
import 'scene_classe.dart';
import 'suivi_fiche_seance.dart';
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
    this.interfaceGuidee = false,
    this.cheminCompteRenduControle = Routes.controleurCompteRendu,
  });

  /// La page du Coran que l'eleve lit en salle (D9).
  static const Key pageEleveKey = ValueKey<String>('salle-page-eleve');

  /// L'eleve qui rejoint la salle depuis l'appareil de son tuteur (D6), lu
  /// dans le billet ; `null` quand la personne connectee entre pour elle-meme.
  final String? eleveId;

  /// Vrai quand la salle s'ouvre dans l'Interface guidee de [eleveId] : la
  /// barre « Seance toujours en direct » le redit au retour.
  final bool interfaceGuidee;

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

  /// ENTREE-ROBUSTE : l'annonce du son recu bloque par le navigateur.
  static const Key sonBloqueKey = ValueKey<String>('salle-son-bloque');

  /// ENTREE-ROBUSTE : le lien « Activer le son » de cette annonce.
  static const Key activerSonKey = ValueKey<String>('salle-activer-son');

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

  /// UX-038 : le fournisseur dit-il que la salle a ete ouverte ailleurs ?
  bool get _ouverteAilleurs => switch (_moteur) {
    final MotifEchecSalle motif => motif.ouverteAilleurs,
    _ => false,
  };

  /// FERMETURE-SALLE (11/11/2026, D-018) : le serveur a-t-il ferme la salle
  /// elle-meme (seance finie) ? Ni une panne, ni une exclusion.
  bool get _salleFermee => switch (_moteur) {
    final FermetureParLeServeur fermeture => fermeture.salleFermee,
    _ => false,
  };

  /// Le proprietaire de l'appel hors de l'ecran (31/10/2026) : la salle lui
  /// confie l'appel ouvert, et le retour arriere ne coupe plus rien.
  late final ControleurSessionPersistante _session = ref.read(
    controleurSessionProvider,
  );

  /// Vrai quand le controleur de session pilote le moteur de cette salle :
  /// toujours en production ; pas dans une demonstration qui surcharge le
  /// moteur sous la racine.
  late final bool _confiable = _session.pilote(_moteur);

  /// L'appel de cette seance est confie au controleur.
  bool get _tenu => _confiable && _session.tient(widget.seanceId);

  StreamSubscription<EtatSalle>? _sEtats;
  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<QualiteLien>? _sQualite;

  /// MICRO-AVANT-ENSEIGNANT (11/11/2026) : les droits de publication que le
  /// serveur change pendant la seance (`DroitsPublicationVivants`).
  StreamSubscription<AccesSalle>? _sAcces;

  /// SITUATIONS-GRAVES (defaut n° 6) : la pause relayee par l'enseignant.
  StreamSubscription<PaquetDonnees>? _sPause;

  /// ENTREE-ROBUSTE (12/11/2026) : le navigateur bloque le son recu
  /// (`SonRecuBloque` du moteur).
  StreamSubscription<bool>? _sSon;
  bool _sonBloque = false;

  /// ENTREE-ROBUSTE : l'annonce « Le son est coupe par le navigateur », avec
  /// « Activer le son », tant que le son recu est bloque dans une salle
  /// ouverte ; `null` sinon. Elle reste a la place des annonces de geste
  /// (en tete de la salle) : ne rien entendre passe avant tout.
  AnnonceGeste? get _annonceSon => _sonBloque && _impasse == null
      ? AnnonceGeste(
          cle: SallePage.sonBloqueKey,
          titre: t.salle.sonBloque,
          message: '',
          ton: TonEtat.avertissement,
          action: LienFleche(
            key: SallePage.activerSonKey,
            libelle: t.salle.activerSon,
            onPress: () => unawaited(_activerSon()),
          ),
        )
      : null;

  /// ENTREE-ROBUSTE : « Activer le son », sur le geste de la personne (le
  /// navigateur ne relance la lecture que sur un geste).
  Future<void> _activerSon() async {
    if (_moteur case final SonRecuBloque son) {
      await son.activerSon();
      if (mounted) setState(() => _sonBloque = son.sonBloque);
    }
  }

  /// SITUATIONS-GRAVES : la pause recue de l'enseignant (eleve, tuteur), ou
  /// `null`. Chez l'enseignant : la derniere pause diffusee.
  PauseSeance? _pauseRecue;
  PauseSeance? _pauseDiffusee;
  int _participantsVus = 0;

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

  /// K4 n° 13 : la relecture periodique de la politique de camera de
  /// l'eleve, armee une fois la salle ouverte ([_armerVeilleCamera]).
  Timer? _veilleCamera;

  /// Une relecture est en cours : la suivante attend.
  bool _relectureCamera = false;
  EtatSalle _etatMoteur = EtatSalle.absent;

  /// Vrai des que la salle s'est ouverte a cette entree.
  bool _aEteConnecte = false;

  /// Lot salle 3 (audit reseau du 25/10/2026) : le repli audio, suivi sur le
  /// flux de qualite avec la meme hysteresis que le moteur ; la pilule d'etat
  /// dit « Image coupee... La voix continue. » tant qu'il dure.
  final RepliAudio _repliAffiche = RepliAudio();

  /// RESEAU-ELEVES (11/11/2026) : le reseau de chaque participant, filtre
  /// contre le clignotement ; en memoire seulement, rien n'est conserve.
  late final SuiviReseau _suiviReseau = SuiviReseau(
    quandChange: () {
      if (mounted) setState(_releverQualite);
    },
  );

  /// RESEAU-PREUVE (11/11/2026) : le releve de qualite garde comme preuve.
  /// L'appareil n'envoie que SA ligne, a un rythme borne.
  late final EnvoiReleve _envoiReleve = EnvoiReleve(
    port: () => ref.read(portReleveQualiteProvider),
    // Le serveur vient de repondre qu'il tient le releve : l'information
    // peut s'afficher.
    quandTenu: () {
      if (mounted) setState(() {});
    },
  );

  void _releverQualite() => _envoiReleve.observer(
    seanceId: widget.seanceId,
    participants: _participants,
    etats: _suiviReseau.etats(),
  );
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  QualiteLien _qualite = QualiteLien.inconnue;

  /// La fin de l'enseignant qui a fait cours (CLV-10), figee a la sortie :
  /// le recapitulatif lit la presence d'AVANT la deconnexion (I-6).
  VueSeance? _finEnseignant;

  /// Le cahier n'a pas pu etre ouvert depuis CLV-10 : « Reessayer ».
  bool _cahierIndisponible = false;

  /// L'eleve sorti de la salle (CLV-09).
  IssueSeance? _sortieEleve;

  /// FN-024 : l'heure de fin servie par le serveur, dite par l'ecran de fin
  /// de l'eleve (« La seance s'est terminee a 18:00. »).
  DateTime? _finServeur;

  /// FN-025 : le motif du dernier refus d'acces, quand le serveur l'a donne.
  DetailRefusSalle? _detailRefus;

  /// FN-024 : une seule verification de fin a la fois.
  bool _verificationFin = false;

  /// Salle en groupe (30/10/2026) : le dernier geste sur un eleve qui n'a
  /// pas abouti, dit dans le panneau Eleves, ou `null`.
  String? _echecGeste;

  /// S0 : l'etat local de la salle de seance (rien n'est diffuse) : zoom de
  /// la page (paliers 100 a 200 %), page agrandie, panneau et contexte.
  double _zoom = paliersZoom.first;
  bool _agrandi = false;
  PanneauOuvert _panneau = PanneauOuvert.aucun;
  ContexteOuvert _contexte = ContexteOuvert.aucun;

  /// S0.3 : l'enseignant a ouvert le tableau blanc (ferme par defaut).
  bool _tableau = false;

  /// Plan de composition du 26/10/2026 : le dernier rappel discret qui n'a
  /// pas pu partir depuis le panneau Eleves, ou `null`.
  String? _echecRappel;

  /// N3, S2 : le dernier geste sur la pause n'est pas confirme (K-59).
  String? _echecPause;

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
    // Point 2 (30/10/2026) : l'eleve qui recite, mis en avant chez tous.
    neuve.parole.addListener(() {
      if (!mounted) return;
      _paroleChangee(neuve);
      setState(() {});
    });
    // GESTES-POINTEUR : celui qui conduit entre (ou revient, page
    // rechargee) sans recitation connue de cet appareil. Si le serveur en
    // tient encore une, il la termine : jamais une classe muette que
    // l'enseignant ne voit pas.
    if (acces.capacites.peutModerer) {
      unawaited(
        ref
            .read(portGestesSalleProvider)
            .terminerRecitation(widget.seanceId)
            .catchError(
              (Object e) => journalDev('recitation non relue a l entree : $e'),
            ),
      );
    }
    // Rappel discret (30/10/2026) : l'eleve appele le lit, et son appareil
    // vibre ou sonne quand il le permet.
    neuve.rappelsRecus.addListener(_rappelRecu);
    return _synchro = neuve;
  }

  /// GESTES-POINTEUR (directeur, 11/11/2026) : ce que le dernier geste dit a
  /// la personne (appel recu, recitation, retour a l'enseignant), ou `null`.
  /// Une seule place pour tous les roles et tous les ecrans
  /// ([CoucheAnnonceGeste]) ; elle s'efface seule.
  AnnonceGeste? _annonce;
  Timer? _finAnnonce;

  /// Le tutoiement de la salle affichee (lu a la composition).
  bool _tutoieSalle = false;

  void _annoncer(AnnonceGeste annonce) {
    if (!mounted) return;
    _finAnnonce?.cancel();
    _finAnnonce = Timer(AppMouvement.annonceGesteMaintien, () {
      if (mounted) setState(() => _annonce = null);
    });
    setState(() => _annonce = annonce);
  }

  /// « Appeler » : l'eleve appele l'entend (son court, vibration quand
  /// l'appareil la permet) et le lit en tete de la salle, quel que soit
  /// l'ecran.
  void _rappelRecu() {
    if (!mounted) return;
    ref.read(signalRappelProvider)();
    _annoncer(
      AnnonceGeste(
        cle: const ValueKey<String>('rappel-recu'),
        titre: _tutoieSalle
            ? t.salle.gestes.appelRecuTitreTutoie
            : t.salle.gestes.appelRecuTitre,
        message: _tutoieSalle
            ? t.salle.gestes.appelRecuTutoie
            : t.salle.gestes.appelRecu,
      ),
    );
  }

  /// La derniere recitation vue par cet appareil (eleve).
  ParoleSalle? _paroleVue;

  /// GESTES-POINTEUR : chez un eleve, la recitation se dit en une phrase.
  /// Le recitant : « ouvrez votre micro » (son micro n'est jamais ouvert de
  /// force). Ses camarades : leur micro est ferme, et pourquoi. A la fin :
  /// ils peuvent le rouvrir.
  void _paroleChangee(SynchroSalle synchro) {
    if (_acces?.capacites.peutModerer ?? true) return;
    final ParoleSalle? avant = _paroleVue;
    final ParoleSalle? parole = synchro.parole.value;
    _paroleVue = parole;
    final bool tu = _tutoieSalle;
    if (parole == null) {
      if (avant == null) return;
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-finie'),
          titre: t.salle.gestes.finRecitationTitre,
          message: tu
              ? t.salle.gestes.finRecitationTutoie
              : t.salle.gestes.finRecitation,
        ),
      );
    } else if (parole.profilId == synchro.profilLocalId) {
      ref.read(signalRappelProvider)();
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-a-vous'),
          titre: tu
              ? t.salle.gestes.aVousTitreTutoie
              : t.salle.gestes.aVousTitre,
          message: tu ? t.salle.gestes.aVousTutoie : t.salle.gestes.aVous,
        ),
      );
    } else {
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-autre'),
          titre: t.salle.gestes.autreReciteTitre(prenom: parole.prenom),
          message: tu
              ? t.salle.gestes.autreReciteTutoie
              : t.salle.gestes.autreRecite,
        ),
      );
    }
  }

  /// Le transport du rappel discret pendant que cette salle vit
  /// (`RelaisRappelSalle`) : un paquet adresse au seul eleve vise, sur le
  /// canal de donnees de l'enseignant. Le cooldown reste celui du port.
  Future<void> _envoyerRappel({
    required String sessionId,
    required String academyId,
  }) async {
    final SynchroSalle? synchro = _synchro;
    final String? profil = _profilDe(academyId);
    if (synchro == null || profil == null || sessionId != widget.seanceId) {
      throw const EchecRappel(MotifEchecRappel.transport);
    }
    await synchro.emettreRappel(academyId: academyId, profilCible: profil);
  }

  /// D14 (S0) : le dernier refus d'allumer la camera, tel que le navigateur
  /// l'a dit, ou `null`.
  String? _erreurCamera;

  /// Lot salle 3 (directeur, 25/10/2026) : tout bandeau d'erreur se ferme.
  /// Vrai quand l'usager a ferme le message de la camera ; un nouvel essai
  /// le fait revenir s'il echoue encore.
  bool _erreurCameraFermee = false;

  /// Lot salle 3 (pilote, 25/10/2026, audit reseau) : le pre-vol sait qu'il
  /// n'y a aucune camera ; un appui sur « camera » dit la phrase existante
  /// sans rien demander au navigateur.
  bool _cameraAbsente = false;

  /// S0 : la scene video au premier plan, choisie d'un toucher ; `null` :
  /// automatique (l'eleve sans page presentee la voit en grand).
  bool? _scenePremierPlan;

  /// TRANSITIONS-SALLE (directeur, 11/11/2026) : le moment de l'arche
  /// habille l'attente reelle de la PREMIERE entree de cet ecran. Faux au
  /// retour dans une salle reduite (l'appel est tenu), apres un rechargement
  /// ([RepriseSalle] porte cette seance) ; il retombe a faux pour de bon des
  /// que l'attente finit (une reconnexion, une seconde entree ne le
  /// rejouent jamais).
  bool _archeAJouer = false;

  /// Vrai quand l'arche a ete montree pendant l'attente : la salle prete
  /// prend alors la main par le voile qui s'efface ([FaconPassage.voile]).
  bool _archeMontree = false;

  /// TRANSITIONS-SALLE : l'ecran rouvert depuis l'ile (« Retourner dans la
  /// salle ») se redeplie depuis le haut ([FaconPassage.depuisIle]).
  bool _depuisIle = false;

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
        setState(() {
          _etatMoteur = etat;
          // Lot salle 3 (audit reseau du 25/10/2026) : un echec qui suit une
          // salle ouverte est une connexion perdue pour de bon, pas une salle
          // qui n'a pas pu s'ouvrir ; jamais un ecran « Connexion » fige.
          if (etat == EtatSalle.connecte || etat == EtatSalle.retabli) {
            _aEteConnecte = true;
          } else if (etat == EtatSalle.echec && _ouverteAilleurs) {
            // UX-038 : ouverte ailleurs par le meme compte ; ni panne de
            // reseau, ni fin de seance a verifier.
            _impasse = CauseImpasse.ouverteAilleurs;
          } else if (etat == EtatSalle.echec && _salleFermee) {
            // FERMETURE-SALLE : le serveur a ferme la salle, la seance est
            // terminee. Ni « connexion perdue », ni « votre enseignant vous
            // a fait sortir » : l'ecran de fin de chaque role le dit.
            _impasse = CauseImpasse.seanceTerminee;
            unawaited(Future<void>.microtask(_seanceFermee));
          } else if (etat == EtatSalle.echec && _aEteConnecte) {
            _impasse = CauseImpasse.connexionPerdue;
            // FN-024 : la connexion est tombee ; le serveur dit-il que la
            // seance est finie ?
            unawaited(Future<void>.microtask(_verifierFin));
          } else if (etat == EtatSalle.retire) {
            // 30/10/2026 : l'enseignant a fait sortir cet eleve.
            _impasse = CauseImpasse.retire;
            // SITUATIONS-GRAVES (11/11/2026, defaut n° 7) : un observateur
            // (sans voix) n'est jamais sorti par l'enseignant ; le serveur
            // dit pourquoi il l'a retire.
            if (!(_acces?.capacites.peutPublier ?? true)) {
              unawaited(Future<void>.microtask(_motifDuRetrait));
            }
          }
        });
      }
    });
    _sParticipants = _moteur.participants.listen((
      List<ParticipantSalle> liste,
    ) {
      if (!mounted) return;
      // Lot salle 3, audit reseau (e) : la salle n'affiche pas qui parle ; un
      // changement d'orateur seul (ActiveSpeakersChangedEvent, plusieurs fois
      // par seconde) ne reconstruit pas toute la page.
      if (memesHorsParole(_participants, liste)) {
        _participants = liste;
        return;
      }
      setState(() {
        _participants = liste;
        _suiviReseau.mesurer(liste);
        _releverQualite();
      });
      _verifierRecitant(liste);
      _veillerEnseignant(liste);
      // SITUATIONS-GRAVES : un arrivant recoit la pause en cours.
      if (liste.length > _participantsVus && _pauseDiffusee != null) {
        unawaited(_diffuserPause(_pauseDiffusee!, forcer: true));
      }
      _participantsVus = liste.length;
    });
    _sPause = _moteur.donneesRecues
        .where((PaquetDonnees p) => p.sujet == sujetPauseSalle)
        .listen(_pauseRecueDe);
    // ENTREE-ROBUSTE (12/11/2026) : le son recu bloque par le navigateur se
    // dit en tete de la salle, avec son geste (« Activer le son »).
    if (_moteur case final SonRecuBloque son) {
      _sonBloque = son.sonBloque;
      _sSon = son.sonBloqueChange.listen((bool bloque) {
        if (mounted) setState(() => _sonBloque = bloque);
      });
    }
    _sQualite = _moteur.qualite.listen((QualiteLien lien) {
      if (mounted) {
        setState(() {
          _qualite = lien;
          // Lot salle 3 : la meme hysteresis que le moteur, pour le dire.
          _repliAffiche.mesurer(lien);
        });
      }
    });
    // MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026) : quand le serveur rend
    // a l'eleve son droit de publier (son enseignant est entre), le bouton
    // du micro apparait. Le micro reste ferme : seul l'eleve l'ouvre.
    if (_moteur case final DroitsPublicationVivants vivants) {
      _sAcces = vivants.accesMisAJour.listen((AccesSalle acces) {
        if (!mounted || _acces == null) return;
        final AccesSalle? avant = _acces;
        setState(() => _acces = acces);
        // FERMETURE-SALLE : le serveur vient de fermer le micro de l'eleve
        // parce que son enseignant n'est plus dans la salle. Il le lit en
        // tete de la salle ; la phrase d'attente reste ensuite a la place du
        // bouton (« Votre micro s'ouvrira quand votre enseignant sera la. »).
        if (microFermeSansEnseignant(
          avant: avant,
          apres: acces,
          enseignantPresent: enseignantDansLaSalle(_participants),
        )) {
          _annoncer(
            AnnonceGeste(
              cle: const ValueKey<String>('micro-ferme-sans-enseignant'),
              titre: _tutoieSalle
                  ? t.salle.fermeture.sansEnseignantTitreTutoie
                  : t.salle.fermeture.sansEnseignantTitre,
              message: _tutoieSalle
                  ? t.salle.fermeture.microFermeTutoie
                  : t.salle.fermeture.microFerme,
            ),
          );
        }
        // La barre « Seance toujours en direct » lit le meme acces.
        if (_tenu) _confier(acces);
      });
    }
    // Le tuteur observateur n'a AUCUNE preparation (D-14) : il n'ouvre ni
    // micro ni camera.
    // Seuls l'eleve et l'enseignant en ont une ; session pas encore lue
    // (role nul) : le choix se refait au `build`.
    final SessionState session0 = ref.read(sessionProvider);
    final AppRole? role = session0.role;
    _enPreparation =
        widget.preparation &&
        (role == null || _suitLesCours(session0) || role == AppRole.teacher);
    RelaisRappelSalle.inscrire(_envoyerRappel);
    // SORTIE-SALLE (11/11/2026) : tant que le controleur tient un appel,
    // fermer ou recharger l'onglet demande la confirmation du navigateur.
    if (_confiable) {
      GardeFermeture.suivre(
        _session.suivre().map((SessionEnCours? cours) => cours != null),
        initial: _session.etatCourant.cours != null,
      );
    }
    // TRANSITIONS-SALLE : l'arche ne se joue ni au retour depuis l'ile, ni
    // apres un rechargement de cette meme seance.
    _depuisIle = _tenu;
    _archeAJouer =
        !_tenu &&
        RepriseSalle.lire(DateTime.now())?.sessionId != widget.seanceId;
    if (_tenu) {
      // Retour par la barre « Seance toujours en direct » : le meme appel,
      // sans pre-vol, sans jeton, sans reconnexion.
      _reprendre();
    } else if (!_enPreparation) {
      unawaited(_entrer());
    }
  }

  /// La salle rouverte sur l'appel confie a `controleurSessionProvider`.
  void _reprendre() {
    // MICRO-AVANT-ENSEIGNANT : l'acces du moteur d'abord, il suit les droits
    // que le serveur a pu changer pendant que l'ecran etait ferme.
    final AccesSalle? acces =
        _moteur.accesCourant ?? _session.etatCourant.acces;
    _enPreparation = false;
    _materielPret = true;
    _acces = acces;
    _aEteConnecte = true;
    _etatMoteur = _moteur.etatCourant;
    if (acces != null) {
      _armerVeilleCamera(acces);
    }
  }

  /// Confie l'appel ouvert au proprietaire applicatif (31/10/2026) : des
  /// lors, quitter l'ecran ne le coupe plus, et la barre le montre ailleurs.
  void _confier(AccesSalle acces) {
    if (!_confiable) return;
    _session.adopter(
      cours: SessionEnCours(
        sessionId: widget.seanceId,
        groupeId: widget.groupeId ?? '',
        // ILE-SALLE (11/11/2026) : l'ile hors de la salle nomme la Classe,
        // pour l'eleve comme pour l'enseignant, quand elle est deja lue.
        libelleGroupe: _nomClasse(
          ref,
          RoleSalle.depuis(acces.role),
          ecoute: false,
        ),
        eleveId: widget.eleveId,
        interfaceGuidee: widget.interfaceGuidee,
      ),
      acces: acces,
    );
  }

  /// La sortie de l'appel : par le controleur quand il le tient (annonce,
  /// puis deconnexion, la barre se ferme), sinon directement.
  Future<void> _quitterAppel() async {
    // SITUATIONS-GRAVES : une sortie voulue n'est pas a reprendre.
    RepriseSalle.oublier();
    if (_tenu) {
      await _session.quitter();
      return;
    }
    await ref.read(serviceVideoProvider).annoncerSortie(widget.seanceId);
    await _moteur.quitter();
  }

  @override
  void dispose() {
    RelaisRappelSalle.retirer(_envoyerRappel);
    _suiviReseau.fermer();
    _envoiReleve.fermer();
    _finAnnonce?.cancel();
    unawaited(_sEtats?.cancel());
    unawaited(_sParticipants?.cancel());
    unawaited(_sQualite?.cancel());
    unawaited(_sAcces?.cancel());
    unawaited(_sPause?.cancel());
    unawaited(_sSon?.cancel());
    _veilleCamera?.cancel();
    unawaited(_synchro?.liberer());
    // Directeur, 31/10/2026 : un appel ouvert et confie continue hors de
    // l'ecran (retour arriere, autre ecran), comme un appel telephonique ; la
    // barre « Seance toujours en direct » le montre partout. Seule une salle
    // qui n'a pas d'appel confie (preparation, entree inachevee, impasse) se
    // ferme avec l'ecran, pour ne jamais laisser un micro ouvert sans barre.
    if (!_tenu) {
      unawaited(_moteur.quitter());
    }
    super.dispose();
  }

  /// Les trois temps de l'entree : le materiel, le jeton, la salle.
  ///
  /// Le pre-vol vient **avant** le jeton, et l'ordre n'est pas une preference :
  /// une salle qui echoue apres etre entree laisse deux personnes dedans dont
  /// l'une est muette sans savoir pourquoi. Verifier le micro pendant que l'on
  /// est encore seul devant son ecran coute une seconde et evite cela.
  Future<void> _entrer() async {
    _veilleCamera?.cancel();
    _veilleCamera = null;
    setState(() {
      _impasse = null;
      _detailRefus = null;
      _aEteConnecte = false;
      // Revue de la PR 59 : une nouvelle entree relit le materiel ; une
      // camera branchee entre-temps ne fait plus dire « aucune camera ».
      _cameraAbsente = false;
      _erreurCameraFermee = false;
      _repliAffiche.remettre();
      _suiviReseau.remettre();
      _envoiReleve.remettre();
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
    // Une autre seance encore en direct se ferme d'abord, par la sortie
    // volontaire habituelle : un seul appel a la fois.
    if (_confiable &&
        _session.etatCourant.cours != null &&
        !_session.tient(widget.seanceId)) {
      await _session.quitter();
    }
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
      // SITUATIONS-GRAVES (11/11/2026) : la permission du micro, lue avant
      // l'entree, nomme la cause de l'impasse ; entre sans micro, la feuille
      // « micro bloque » la dit deja au premier appui.
      _microRefuseAvant = mesure.permissionRefusee;
      if (mesure.permissionRefusee) _causeMicro = CauseMicroBloque.refuse;
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
      // SITUATIONS-GRAVES : un refus du serveur ne se reprend pas au
      // prochain rechargement.
      if (echec.motif == MotifRefusSalle.acces) RepriseSalle.oublier();
      if (mounted) {
        setState(() {
          _impasse = CauseImpasse.depuis(echec.motif);
          _detailRefus = echec.detail;
        });
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
      if (!mounted) {
        // L'ecran est parti pendant l'entree : rien n'a ete confie, rien ne
        // doit rester ouvert.
        await _moteur.quitter();
        return;
      }
      _confier(acces);
      _armerVeilleCamera(acces);
      // SITUATIONS-GRAVES (11/11/2026, defaut n° 4) : un rechargement de la
      // page retrouve cette salle ; seuls la seance, la classe et l'eleve
      // sont gardes, jamais le jeton (le serveur en rend un neuf).
      RepriseSalle.retenir(
        BilletSalle(
          sessionId: widget.seanceId,
          emisA: DateTime.now(),
          groupeId: widget.groupeId,
          eleveId: widget.eleveId,
          interfaceGuidee: widget.interfaceGuidee,
        ),
      );
    } on EntreeInterrompue {
      // ENTREE-ROBUSTE : la salle a ete quittee pendant les essais du moteur
      // (sortie, ecran ferme) : ce n'est pas une panne, rien a dire.
      return;
    } catch (erreur) {
      // Le moteur a deja pose son etat d'echec et tout libere, apres ses
      // essais (ENTREE-ROBUSTE : jusqu'a trois, sans geste) ; il ne reste
      // qu'a nommer la cause pour l'usager. Aucun detail technique ne remonte
      // a l'ecran : « ICE failed » ne se lit pas devant un enfant.
      journalDev('entree en salle impossible : $erreur');
      if (mounted) {
        // ENTREE-ROBUSTE (directeur, 12/11/2026 au soir) : le meme compte est
        // dans la salle sur un autre appareil ; ce n'est pas le reseau.
        setState(
          () => _impasse = erreur is EntreeOuverteAilleurs || _ouverteAilleurs
              ? CauseImpasse.ouverteAilleurs
              : CauseImpasse.reseau,
        );
      }
    }
  }

  /// FN-024 (arbitrage du pilote du 01/11/2026) : la connexion est tombee
  /// apres la fin prevue. Le client redemande le jeton ; si le serveur
  /// repond que la seance est finie (`motif_refus_salle`), l'ecran le dit,
  /// avec l'heure de fin du serveur : « Seance terminee » pour l'eleve,
  /// l'ecran de fin et le cahier pour l'enseignant. Sinon (salle encore
  /// ouverte, refus generique, reseau), l'impasse « connexion perdue » reste,
  /// avec son « Reessayer ».
  ///
  /// Seulement apres la fin prevue connue (bornes du chrono, FN-023) : une
  /// coupure en pleine seance n'est pas une fin, et sans bornes rien n'est
  /// suppose ; « Reessayer » dira alors le motif du serveur (FN-025).
  Future<void> _verifierFin() async {
    if (_verificationFin || !mounted) return;
    final AccesSalle? acces = _acces;
    final RoleSalle role = RoleSalle.depuis(acces?.role);
    if (role != RoleSalle.eleve && role != RoleSalle.enseignant) return;
    final BornesChrono? bornes = ref.read(
      bornesSalleProvider((
        seanceId: widget.seanceId,
        groupeId: widget.groupeId,
        enseignant: role == RoleSalle.enseignant,
      )),
    );
    if (bornes == null ||
        DateTime.now().toUtc().isBefore(bornes.finPrevueUtc)) {
      return;
    }
    _verificationFin = true;
    try {
      await ref
          .read(serviceVideoProvider)
          .acces(widget.seanceId, eleveId: widget.eleveId);
      // Un jeton : la salle est encore ouverte, « Reessayer » y ramene.
    } on EchecSalle catch (echec) {
      final DetailRefusSalle? detail = echec.detail;
      if (!mounted ||
          detail == null ||
          detail.motif == MotifServeurSalle.pasEncoreOuverte ||
          _impasse != CauseImpasse.connexionPerdue) {
        return;
      }
      final DateTime? fin = detail.motif == MotifServeurSalle.terminee
          ? detail.finUtc
          : null;
      _montrerFin(role, fin);
    } catch (erreur) {
      journalDev('verification de fin impossible : $erreur');
    } finally {
      _verificationFin = false;
    }
  }

  /// La seance est terminee, le serveur l'a dit : « Seance terminee » pour
  /// l'eleve ; pour l'enseignant, l'ecran de fin (CLV-10) puis le cahier,
  /// comme apres « Quitter ». [fin] est l'instant du serveur quand il l'a
  /// donne ; l'heure se forme au dessin (HEURE-PROFIL).
  void _montrerFin(RoleSalle role, DateTime? fin) {
    if (!mounted) return;
    if (role == RoleSalle.eleve) {
      setState(() {
        _finServeur = fin;
        _sortieEleve = IssueSeance.terminee;
      });
      return;
    }
    final VueSeance? vue = DepuisSalle.vue(
      salle: VueSalle.depuis(
        materielPret: _materielPret,
        acces: _acces,
        etatMoteur: _etatMoteur,
        participants: _participants,
        qualite: _qualite,
        impasse: null,
      ),
      mode: AppMetriques.of(context).mode,
      presence: ref.read(presenceSeanceProvider(widget.seanceId)).value,
      monProfil: ref.read(sessionProvider).profileId,
      // UX-043 : le serveur a dit la seance terminee.
      fin: FinSeance(finA: fin ?? DateTime.now(), cahierACompleter: true),
    );
    if (vue != null) setState(() => _finEnseignant = vue);
  }

  /// FERMETURE-SALLE (directeur, 11/11/2026, D-018) : le serveur a ferme la
  /// salle parce que la seance est finie. L'eleve arrive sur « Seance
  /// terminee » et son retour a l'accueil, l'enseignant sur l'ecran de fin et
  /// le cahier de transmission, sans rien avoir a toucher. Les autres roles
  /// (tuteur, controle, direction) lisent « La seance est terminee. » sur
  /// l'ecran d'impasse, avec le retour.
  void _seanceFermee() {
    if (!mounted) return;
    final RoleSalle role = RoleSalle.depuis(_acces?.role);
    if (role != RoleSalle.eleve && role != RoleSalle.enseignant) return;
    _veilleCamera?.cancel();
    _veilleCamera = null;
    _montrerFin(role, null);
  }

  /// K4 n° 13 (pilote, 30/10/2026) : le jeton d'un eleve fige sa camera a
  /// l'entree. Si son tuteur l'ouvre ou la ferme pendant la seance, la salle
  /// le voit a la relecture suivante, redemande un jeton (la base reste seule
  /// juge) et rentre avec lui ; le micro ouvert le reste.
  void _armerVeilleCamera(AccesSalle acces) {
    _veilleCamera?.cancel();
    _veilleCamera = null;
    if (acces.role != 'student') {
      return;
    }
    _veilleCamera = Timer.periodic(
      intervallePolitiqueCamera,
      (Timer _) => unawaited(_relireCamera()),
    );
  }

  /// L'age de l'eleve devant l'ecran (garde-cap et pilote, 11/11/2026 : un
  /// enfant etait vouvoye dans la salle). L'eleve connecte, ou l'enfant du
  /// foyer pour qui le tuteur ouvre la salle ([SallePage.eleveId]) : son
  /// type est lu une fois sur le serveur ([ageEleveProvider]). Tant que la
  /// lecture n'est pas revenue, l'ancien port (inconnu en production :
  /// vouvoiement).
  ///
  /// Revue du garde-cap du 11/11/2026 (B3) : aucune lecture de ROLE ici (un
  /// widget lit une capacite, jamais un role). La personne devant l'ecran,
  /// quelle qu'elle soit : seul un eleve a une fiche d'eleve, donc pour un
  /// enseignant, un tuteur ou la direction le serveur ne rend rien (la RLS en
  /// decide), l'age reste inconnu et la salle vouvoie.
  AgeEleve _ageDeLEleve() {
    final AgeEleve repli = ref.watch(portAgeEleveProvider).ageDeLEleve();
    final String? eleve =
        widget.eleveId ?? ref.watch(sessionProvider).profileId;
    if (eleve == null || repli != AgeEleve.inconnu) return repli;
    return ref.watch(ageEleveProvider(eleve)).value ?? repli;
  }

  Future<void> _relireCamera() async {
    final AccesSalle? courant = _acces;
    final String? eleve = widget.eleveId ?? ref.read(sessionProvider).profileId;
    if (_relectureCamera || courant == null || eleve == null || !mounted) {
      return;
    }
    _relectureCamera = true;
    try {
      final bool? autorisee = await ref
          .read(politiqueCameraProvider)
          .cameraAutorisee(eleve);
      if (!mounted ||
          !identical(_acces, courant) ||
          !jetonCameraPerime(courant, cameraAutorisee: autorisee)) {
        return;
      }
      final AccesSalle neuf = await ref
          .read(serviceVideoProvider)
          .acces(widget.seanceId, eleveId: widget.eleveId);
      if (!mounted ||
          !identical(_acces, courant) ||
          neuf.capacites.peutPublierVideo ==
              courant.capacites.peutPublierVideo) {
        return;
      }
      final bool microOuvert = _participants.any(
        (ParticipantSalle p) => p.estLocal && p.micro,
      );
      setState(() => _acces = neuf);
      // `rejoindre` ferme l'ancienne salle avant d'ouvrir la nouvelle.
      await _moteur.rejoindre(neuf);
      if (mounted) _confier(neuf);
      if (microOuvert && mounted) {
        await _moteur.reglerMicro(actif: true);
      }
    } catch (erreur) {
      // Une relecture manquee n'arrete pas la seance : la suivante reessaie.
      journalDev('politique de camera non relue : $erreur');
    } finally {
      _relectureCamera = false;
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
            // UX-040 : apres « Quitter », la seance continue (FN-006).
            fin: FinSeance(
              finA: DateTime.now(),
              cahierACompleter: true,
              close: false,
            ),
          )
        : null;

    // **L'annonce precede la deconnexion, et cet ordre porte une information
    // que rien d'autre ne porte.** LiveKit envoie le meme evenement `left` dans
    // les deux cas ; seule cette ecriture distingue une sortie volontaire d'une
    // perte de reseau. Annoncer apres s'etre deconnecte laisserait le webhook
    // arriver le premier et inscrire une deconnexion.
    _veilleCamera?.cancel();
    _veilleCamera = null;
    await _quitterAppel();
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
    await _quitterAppel();
    if (!mounted) {
      return;
    }
    // La visite voyage par l'adresse (`?seance=`) : le compte rendu porte
    // sur CETTE seance, jamais sur la mission courante (revue CT-R B1).
    GoRouter.of(
      context,
    ).go(adresseCompteRendu(widget.cheminCompteRenduControle, widget.seanceId));
  }

  /// Salle en groupe (30/10/2026) : le geste de l'enseignant sur un eleve
  /// de la grille. La sortie se confirme d'abord (action lourde) ; la base
  /// reverifie le droit a chaque appel (`salle-gestes`).
  Future<void> _geste(ParticipantSalle eleve, GesteSalle geste) async {
    if (geste == GesteSalle.faireSortir) {
      final bool accepte = await ConfirmDestructive.demander(
        context,
        question: t.salle.gestes.confirmerSortie(prenom: eleve.nom),
        consequence: t.salle.gestes.consequenceSortie(prenom: eleve.nom),
        libelleConfirmer: t.salle.gestes.faireSortir(prenom: eleve.nom),
      );
      if (!accepte || !mounted) return;
    }
    try {
      await ref
          .read(portGestesSalleProvider)
          .appliquer(widget.seanceId, eleve.identite, geste);
      if (!mounted) return;
      setState(() => _echecGeste = null);
      if (geste == GesteSalle.faireSortir) {
        ref.invalidate(elevesSortisProvider(widget.seanceId));
        if (_synchro?.parole.value?.profilId == eleve.identite) {
          unawaited(_terminerRecitation(partie: true));
        }
      }
    } catch (e) {
      journalDev('geste $geste impossible : $e');
      if (mounted) setState(() => _echecGeste = t.salle.gestes.echec);
    }
  }

  /// GESTES-POINTEUR (directeur, 11/11/2026) : « Faire reciter Yasmine ».
  ///
  /// **Le serveur d'abord** : il ferme le micro des camarades (droit de
  /// publier retire, `salle-gestes`). Ensuite seulement l'application le dit
  /// a la classe. S'il refuse ou ne repond pas, rien n'est annonce : aucun
  /// ecran ne pretend qu'une recitation a commence.
  Future<void> _faireReciter(ParoleSalle eleve) async {
    final IssueRecitation issue;
    try {
      issue = await ref
          .read(portGestesSalleProvider)
          .faireReciter(widget.seanceId, eleve.profilId)
          .timeout(AppDelais.requeteMax);
    } on Object catch (e) {
      journalDev('recitation non ouverte : $e');
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-echec'),
          titre: t.salle.gestes.recitationEchecTitre,
          message: t.salle.gestes.recitationEchec,
          ton: TonEtat.alerte,
        ),
      );
      return;
    }
    if (!mounted) return;
    if (issue != IssueRecitation.ouverte) {
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-absent'),
          titre: t.salle.gestes.recitationAbsentTitre(prenom: eleve.prenom),
          message: t.salle.gestes.recitationAbsent(prenom: eleve.prenom),
          ton: TonEtat.alerte,
        ),
      );
      return;
    }
    _donnerLaParole(eleve);
    _annoncer(
      AnnonceGeste(
        cle: const ValueKey<String>('recitation-ouverte'),
        titre: t.salle.gestes.recitationOuverteTitre(prenom: eleve.prenom),
        message: t.salle.gestes.recitationOuverte(prenom: eleve.prenom),
      ),
    );
  }

  bool _finRecitationEnCours = false;

  /// GESTES-POINTEUR : « Terminer la recitation ». Le serveur rend leur droit
  /// a tous (micros fermes) ; tant qu'il ne l'a pas confirme, la recitation
  /// reste affichee et le geste reste propose. [partie] : le recitant a
  /// quitte la salle, la recitation se termine d'elle-meme.
  Future<void> _terminerRecitation({bool partie = false}) async {
    final ParoleSalle? parole = _synchro?.parole.value;
    if (parole == null || _finRecitationEnCours) return;
    _finRecitationEnCours = true;
    try {
      await ref
          .read(portGestesSalleProvider)
          .terminerRecitation(widget.seanceId, eleveId: parole.profilId)
          .timeout(AppDelais.requeteMax);
    } on Object catch (e) {
      journalDev('recitation non terminee : $e');
      _finRecitationEnCours = false;
      _annoncer(
        AnnonceGeste(
          cle: const ValueKey<String>('recitation-fin-echec'),
          titre: t.salle.gestes.finEchecTitre,
          message: t.salle.gestes.finEchec,
          ton: TonEtat.alerte,
        ),
      );
      return;
    }
    _finRecitationEnCours = false;
    if (!mounted) return;
    _donnerLaParole(null);
    _annoncer(
      AnnonceGeste(
        cle: const ValueKey<String>('recitation-terminee'),
        titre: t.salle.gestes.recitationTermineeTitre,
        message: partie
            ? t.salle.gestes.recitationFinieSeule(prenom: parole.prenom)
            : t.salle.gestes.recitationTerminee,
      ),
    );
  }

  /// GESTES-POINTEUR : la recitation ne tient que tant que le recitant est
  /// dans la salle. Le serveur la termine de son cote (webhook de sortie) ;
  /// l'appareil de celui qui conduit le demande aussi, pour que la classe ne
  /// reste jamais muette si ce webhook se perd.
  void _verifierRecitant(List<ParticipantSalle> liste) {
    if (!(_acces?.capacites.peutModerer ?? false)) return;
    final ParoleSalle? parole = _synchro?.parole.value;
    if (parole == null) return;
    if (liste.any((ParticipantSalle p) => p.identite == parole.profilId)) {
      return;
    }
    unawaited(_terminerRecitation(partie: true));
  }

  /// Readmet un eleve sorti ; la liste des sortis se relit.
  Future<void> _readmettre(EleveSorti eleve) async {
    try {
      await ref
          .read(portGestesSalleProvider)
          .readmettre(widget.seanceId, eleve.profilId);
      if (mounted) setState(() => _echecGeste = null);
    } catch (e) {
      journalDev('readmission impossible : $e');
      if (mounted) setState(() => _echecGeste = t.salle.gestes.echec);
    }
    ref.invalidate(elevesSortisProvider(widget.seanceId));
  }

  /// Point 2 (30/10/2026) : donner la parole agit chez toute la classe. La
  /// file locale (pastille du roster) suit, et le canal de donnees de
  /// l'enseignant porte l'eleve qui recite a chaque appareil. `null` reprend
  /// la parole. GESTES-POINTEUR : ce n'est plus que l'annonce a la classe ;
  /// les micros, eux, sont fermes puis rendus par le serveur
  /// ([_faireReciter], [_terminerRecitation]).
  void _donnerLaParole(ParoleSalle? eleve) {
    final ControleurRecitation file = ref.read(recitationProvider.notifier);
    final String? matricule = eleve == null
        ? null
        : _matriculeDe(eleve.profilId);
    if (matricule != null) {
      file.donnerLaParoleA(matricule);
    } else {
      file.arreter();
    }
    _synchro?.diffuserParole(eleve);
  }

  /// Le matricule d'un profil de la seance, lu dans la presence.
  String? _matriculeDe(String profilId) {
    for (final PresenceParticipant p
        in ref.read(presenceSeanceProvider(widget.seanceId)).value ??
            const <PresenceParticipant>[]) {
      if (p.profilId == profilId && p.identifiantImmuable.isNotEmpty) {
        return p.identifiantImmuable;
      }
    }
    return null;
  }

  /// Le profil d'un matricule de la seance, lu dans la presence.
  String? _profilDe(String matricule) {
    for (final PresenceParticipant p
        in ref.read(presenceSeanceProvider(widget.seanceId)).value ??
            const <PresenceParticipant>[]) {
      if (p.identifiantImmuable == matricule && p.profilId.isNotEmpty) {
        return p.profilId;
      }
    }
    return null;
  }

  /// Le menu des gestes sur un eleve de la grille, pour qui en a la
  /// capacite (`can_moderate` du jeton) ; `null` pour tout autre cadre.
  Widget? _menuGestes(ParticipantSalle p, {required bool recite}) {
    if (!(_acces?.capacites.peutModerer ?? false) ||
        p.estLocal ||
        RoleSalle.depuis(p.role) != RoleSalle.eleve) {
      return null;
    }
    return MenuActions(
      points: true,
      libelle: t.salle.gestes.menu(prenom: p.nom),
      actions: <EntreeAction>[
        if (recite)
          EntreeAction(
            libelle: t.salle.gestes.terminerRecitation,
            onChoix: () => unawaited(_terminerRecitation()),
          )
        else
          EntreeAction(
            libelle: t.salle.gestes.faireReciter(prenom: p.nom),
            onChoix: () => unawaited(
              _faireReciter(ParoleSalle(profilId: p.identite, prenom: p.nom)),
            ),
          ),
        // « Appeler » : attirer l'attention d'un eleve present qui ne repond
        // pas. Reserve a qui conduit la seance (ce menu n'existe que pour
        // lui), sur un eleve dans la salle (cette grille ne montre qu'eux).
        EntreeAction(
          libelle: t.salle.gestes.appeler(prenom: p.nom),
          onChoix: () => unawaited(_appelerParticipant(p)),
        ),
        if (p.micro)
          EntreeAction(
            libelle: t.salle.gestes.couperMicro(
              dePrenom: deDevant(p.nom, cle: 'salle.gestes.couperMicro'),
            ),
            onChoix: () => unawaited(_geste(p, GesteSalle.couperMicro)),
          ),
        if (p.camera)
          EntreeAction(
            libelle: t.salle.gestes.couperCamera(
              dePrenom: deDevant(p.nom, cle: 'salle.gestes.couperCamera'),
            ),
            onChoix: () => unawaited(_geste(p, GesteSalle.couperCamera)),
          ),
        EntreeAction(
          libelle: t.salle.gestes.faireSortir(prenom: p.nom),
          destructif: true,
          onChoix: () => unawaited(_geste(p, GesteSalle.faireSortir)),
        ),
      ],
    );
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
  /// La fleche de la salle pendant l'appel (31/10/2026) : l'ecran d'ou l'on
  /// vient, sans question et sans couper l'appel (`_session` le tient).
  void _quitterLEcran() {
    final String? groupe = widget.groupeId;
    if (ref.read(sessionProvider).role == AppRole.teacher && groupe != null) {
      GoRouter.of(context).go(Routes.groupePour(groupe));
      return;
    }
    _rentrer();
  }

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

  /// SITUATIONS-GRAVES (11/11/2026, defaut n° 3) : un micro que le
  /// navigateur refuse n'est plus muet. La cause (refuse, pris, absent) se
  /// dit tout de suite en tete de la salle, avec quoi faire (K-59), et la
  /// feuille « micro bloque » la reprend au geste suivant ; un essai reussi
  /// l'efface. Le micro n'est jamais ouvert sans geste.
  Future<void> _basculerMicro(bool ouvert) async {
    try {
      await _moteur.reglerMicro(actif: !ouvert);
      if (mounted && !ouvert && _causeMicro != null) {
        setState(() => _causeMicro = null);
      }
    } on Object catch (erreur) {
      journalDev('micro : $erreur');
      if (!mounted || ouvert) return;
      final CauseMicroBloque cause = causeEchecMicro('$erreur');
      setState(() => _causeMicro = cause);
      _annoncer(annonceMicroBloque(cause));
    }
  }

  /// SITUATIONS-GRAVES (11/11/2026, defaut n° 6) : la pause n'est lue au
  /// serveur que par l'enseignant (`pause_seance_etat`) ; son poste la
  /// relaie a la classe sur le canal fiable de la salle, a chaque changement
  /// et a chaque arrivant. L'etat reste celui du serveur : rien n'est decide
  /// ici, et aucun micro n'est touche.
  Future<void> _diffuserPause(PauseSeance pause, {bool forcer = false}) async {
    if (!forcer && pause == _pauseDiffusee) return;
    _pauseDiffusee = pause;
    if (!(_acces?.capacites.peutPublierDonnees ?? false)) return;
    try {
      await _moteur.publierDonnees(
        sujet: sujetPauseSalle,
        charge: utf8.encode(jsonEncode(chargePause(pause))),
        fiable: true,
      );
    } on Object catch (erreur) {
      journalDev('pause non relayee : $erreur');
    }
  }

  /// SITUATIONS-GRAVES : la pause recue, seulement de qui conduit la seance
  /// (l'identite du jeton signe) ; dite une fois en tete quand elle commence.
  void _pauseRecueDe(PaquetDonnees paquet) {
    if (!mounted || (_acces?.capacites.peutModerer ?? true)) return;
    final bool deLEnseignant = _participants.any(
      (ParticipantSalle p) =>
          p.identite == paquet.emetteurIdentite && p.role == roleQuiConduit,
    );
    if (!deLEnseignant) return;
    final PauseSeance? pause = pauseDepuisCharge(paquet.charge);
    if (pause == null) return;
    final bool commence =
        pause.statut == StatutPause.enCours &&
        _pauseRecue?.statut != StatutPause.enCours;
    setState(() => _pauseRecue = pause);
    if (commence) _annoncer(annoncePause());
  }

  /// SITUATIONS-GRAVES (11/11/2026, defaut n° 2) : ce que l'eleve sait de
  /// son enseignant, qu'il soit seul ou avec d'autres eleves.
  final VeilleEnseignant _veille = VeilleEnseignant();

  /// SITUATIONS-GRAVES (defaut n° 2) : l'eleve est prevenu, en tete de la
  /// salle (jamais sur la page), des que son enseignant n'est pas dans la
  /// salle : pas encore arrive, ou parti. Avant, la phrase d'attente ne
  /// s'affichait que si personne d'autre n'etait visible.
  void _veillerEnseignant(List<ParticipantSalle> liste) {
    if (_acces?.role != AccesSalle.roleEleve) return;
    if (!liste.any((ParticipantSalle p) => p.estLocal)) return;
    final AnnonceGeste? annonce = _veille.observer(
      enseignantPresent: enseignantDansLaSalle(liste),
      // Seul dans la salle, la scene d'attente dit deja « Votre professeur
      // n'est pas encore arrive » : l'annonce de tete ne le redit pas.
      seul: !liste.any((ParticipantSalle p) => !p.estLocal),
      tutoie: _tutoieSalle,
    );
    if (annonce != null) _annoncer(annonce);
  }

  /// SITUATIONS-GRAVES (11/11/2026, defaut n° 7) : pourquoi le serveur a
  /// retire cet observateur. LiveKit ne dit que « participant retire » ; le
  /// motif vient du serveur : une nouvelle demande d'entree, qu'il refuse
  /// avec sa vraie raison (« temps d'observation termine »). Aucun jeton
  /// rendu n'est employe : la salle reste fermee, rien ne se reconnecte.
  Future<void> _motifDuRetrait() async {
    try {
      await ref
          .read(serviceVideoProvider)
          .acces(widget.seanceId, eleveId: widget.eleveId);
    } on EchecSalle catch (echec) {
      final DetailRefusSalle? detail = echec.detail;
      if (!mounted ||
          _impasse != CauseImpasse.retire ||
          detail == null ||
          detail.motif == MotifServeurSalle.sorti) {
        return;
      }
      setState(() {
        _impasse = CauseImpasse.acces;
        _detailRefus = detail;
      });
    } on Object catch (erreur) {
      journalDev('motif du retrait illisible : $erreur');
    }
  }

  /// SITUATIONS-GRAVES : la cause du dernier refus du micro, ou `null`.
  CauseMicroBloque? _causeMicro;

  /// SITUATIONS-GRAVES : le pre-vol a lu la permission du micro refusee.
  bool _microRefuseAvant = false;

  /// D14 (S0) : un allumage qui echoue n'est plus silencieux. La phrase
  /// exacte du navigateur s'affiche sous l'en-tete, avec sa cause probable et
  /// quoi faire (K-59) ; un essai reussi l'efface.
  Future<void> _basculerCamera(bool ouverte) async {
    if (_erreurCameraFermee) setState(() => _erreurCameraFermee = false);
    if (!ouverte && ref.read(preVolProvider).value?.cameraDisponible == false) {
      setState(() => _cameraAbsente = true);
      return;
    }
    try {
      await _moteur.reglerCamera(actif: !ouverte);
      if (mounted && (_erreurCamera != null || (!ouverte && _cameraAbsente))) {
        // Une camera allumee : elle existe (revue de la PR 59).
        setState(() {
          _erreurCamera = null;
          if (!ouverte) _cameraAbsente = false;
        });
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

  /// L'enseignant de la seance, lu la ou le role de l'appelant le permet
  /// (revue de la PR 60, 26/10/2026) : son identite dans la salle ou dans la
  /// presence ; sa fiche par son profil (`teacher_profiles` : lui-meme, la
  /// direction) ; sinon la Classe de la famille (`mes_groupes_famille_v` :
  /// l'eleve et le tuteur), celle du billet, ou celle de cette seance quand
  /// l'eleve arrive par son accueil, sans Classe dans le billet. `null` :
  /// rien de lisible ; les prenoms de la presence restent.
  FicheEnseignantSeance? _ficheEnseignant(
    WidgetRef ref,
    List<PresenceParticipant>? presence,
  ) {
    String? id;
    for (final ParticipantSalle p in _participants) {
      if (RoleSalle.depuis(p.role) == RoleSalle.enseignant) id = p.identite;
    }
    for (final PresenceParticipant ligne
        in presence ?? const <PresenceParticipant>[]) {
      if (RoleSalle.depuis(ligne.role) == RoleSalle.enseignant &&
          ligne.profilId.isNotEmpty) {
        id ??= ligne.profilId;
      }
    }
    final String? groupe = widget.groupeId;
    final GroupSummaryVM? classe = groupe != null
        ? ref.watch(groupeProvider(groupe)).value
        : _classeDeLaSeance(ref.watch(mesGroupesProvider).value, id);
    final EnseignantVM? deLaClasse = classe?.enseignant;
    id ??= deLaClasse == null || deLaClasse.enseignantId.isEmpty
        ? null
        : deLaClasse.enseignantId;
    if (id == null) return null;
    final ProfilEnseignant? profil = ref
        .watch(profilEnseignantParIdProvider(id))
        .value;
    return (
      id: id,
      prenom: profil?.prenom ?? deLaClasse?.nomAffichage ?? '',
      titre: TitreEnseignant.depuisSql(profil?.titre) ?? deLaClasse?.titre,
      clePhoto: profil?.clePhoto ?? deLaClasse?.photoUrlOuCle,
      // DRAPEAUX (04/11/2026) : son propre profil pour l'enseignant, sinon la
      // Classe de la famille (`mes_groupes_famille_v.teacher_country`, masque
      // comme le prenom).
      pays: profil?.pays ?? deLaClasse?.pays,
    );
  }

  /// Le nom de la Classe de la seance : pour l'enseignant, dans ses Classes
  /// (`mes_groupes_v`) ; pour les familles, la Classe du billet, ou celle de
  /// cette seance ; vide si rien n'est lisible (« Séance en direct »).
  /// [ecoute] faux : lecture seule, hors d'un `build` (l'appel confie a la
  /// session, pour l'ile hors de la salle).
  String _nomClasse(WidgetRef ref, RoleSalle role, {bool ecoute = true}) {
    final String? groupe = widget.groupeId;
    if (role == RoleSalle.enseignant) {
      for (final GroupeEnseignant g
          in (ecoute
                      ? ref.watch(groupesEnseignantProvider)
                      : ref.read(groupesEnseignantProvider))
                  .value ??
              const <GroupeEnseignant>[]) {
        if (g.id == groupe) return g.libelle;
      }
      // Repli par la seance (meme principe que la famille) : `mes_groupes_v`
      // pas encore charge, ou `groupeId` absent de l'adresse. La seance de
      // l'enseignant porte deja le nom de sa Classe (`mes_seances_enseignant_v`),
      // sans nouvelle requete.
      for (final SeanceEnseignant e
          in (ecoute
                      ? ref.watch(seancesEnseignantProvider)
                      : ref.read(seancesEnseignantProvider))
                  .value ??
              const <SeanceEnseignant>[]) {
        if (e.id == widget.seanceId) return e.groupeLibelle ?? '';
      }
      return '';
    }
    final GroupSummaryVM? classe = groupe != null
        ? (ecoute
                  ? ref.watch(groupeProvider(groupe))
                  : ref.read(groupeProvider(groupe)))
              .value
        : _classeDeLaSeance(
            (ecoute
                    ? ref.watch(mesGroupesProvider)
                    : ref.read(mesGroupesProvider))
                .value,
            null,
          );
    return classe?.libelle ?? '';
  }

  /// La Classe de cette seance parmi celles de la famille : par la seance
  /// (prochaine occurrence ou horloge), sinon par l'enseignant [idEnseignant].
  GroupSummaryVM? _classeDeLaSeance(
    List<GroupSummaryVM>? classes,
    String? idEnseignant,
  ) {
    final List<GroupSummaryVM> toutes = classes ?? const <GroupSummaryVM>[];
    for (final GroupSummaryVM c in toutes) {
      if (c.prochaineSeance?.sessionId == widget.seanceId ||
          c.horloge?.sessionId == widget.seanceId) {
        return c;
      }
    }
    if (idEnseignant == null) return null;
    for (final GroupSummaryVM c in toutes) {
      if (c.enseignant.enseignantId == idEnseignant) return c;
    }
    return null;
  }

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
    final VueSeance seanceSansFiches = tableau
        ? base.copyWith(
            panneau: _panneau,
            contexte: _contexte,
            sansSupportPresente: true,
            // K4 : la forme fixe de la classe (16:9), ajustee sans
            // etirement sur chaque appareil.
            tableauLibre: TableauLibre.classe,
            microBloque: _causeMicro != null,
            causeMicro: _causeMicro,
          )
        : base.copyWith(
            panneau: _panneau,
            contexte: _contexte,
            // SITUATIONS-GRAVES : le vrai refus du micro alimente la feuille.
            microBloque: _causeMicro != null,
            causeMicro: _causeMicro,
          );
    // N3, S2 : la pause programmee de la classe, lue au serveur pour
    // l'enseignant seulement (`pause_seance_etat` refuse les autres roles).
    // Sans reponse, le chrono reste sans pause : jamais une pause inventee.
    final PauseSeance? pause = enseignant
        ? ref.watch(pauseSeanceProvider(widget.seanceId)).value
        : _pauseRecue;
    // SITUATIONS-GRAVES (defaut n° 6) : l'enseignant relaie la pause servie.
    if (enseignant && pause != null && pause != _pauseDiffusee) {
      unawaited(Future<void>.microtask(() => _diffuserPause(pause)));
    }
    _tutoieSalle = base.tutoiement ?? base.role == RoleSeance.guidee;
    // GESTES-POINTEUR : chez un camarade du recitant, la phrase du micro dit
    // la vraie raison (le serveur garde son micro ferme le temps de la
    // recitation).
    final ParoleSalle? paroleRecue = synchro?.parole.value;
    final bool camaradeRecite =
        !enseignant &&
        paroleRecue != null &&
        paroleRecue.profilId != synchro?.profilLocalId;
    final VueSeance seance = enseignant
        ? seanceSansFiches.copyWith(
            eleves: _avecFiches(
              seanceSansFiches.eleves,
              _roster(ref),
              _suiviClasse(ref),
            ),
            pause: pause,
            echecPause: _echecPause,
          )
        : camaradeRecite
        ? seanceSansFiches.copyWith(
            recitantPrenom: paroleRecue.prenom,
            pause: pause,
          )
        // SITUATIONS-GRAVES : la pause relayee se lit dans l'ile.
        : seanceSansFiches.copyWith(pause: pause);
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final double? plus = palierSuivant(_zoom);
    final double? moins = palierPrecedent(_zoom);
    final ParticipantSalle? moi = vue.moi;
    final int? page = presentee?.page;
    // PARTAGE-GENERIQUE (11/11/2026) : le support presente, quel qu'il soit.
    // `pageCoran` ne vaut que pour le Coran (etats de lecture du mushaf).
    final List<SupportDeSalle> supportsConnus = ref.watch(
      supportsDeSalleProvider,
    );
    final int? pageCoran = (presentee?.estCoran ?? false) ? page : null;
    final SupportDeSalle? supportOuvert = presentee == null
        ? null
        : supportDeSalleDe(presentee, supportsConnus);
    final int dernierePage = presentee == null
        ? 0
        : presentee.estCoran
        ? pagesMushafMedine
        : (supportOuvert?.pages ?? 0);
    final ActionsSeance actions = ActionsSeance(
      // Directeur, 31/10/2026 : la fleche quitte l'ecran, pas l'appel ; la
      // barre « Seance toujours en direct » y ramene. SORTIE-SALLE
      // (11/11/2026) : c'est « Reduire la salle », donne seulement quand
      // l'appel est confie au controleur ; sinon quitter l'ecran couperait
      // l'appel, et le geste n'est pas propose.
      onRetour: _tenu ? _quitterLEcran : null,
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
      // N3, S2 : demarrer ou terminer la pause ; le chrono ne rend la commande
      // que si le serveur a donne `peut_piloter`.
      onPause: enseignant && pause != null
          ? () => unawaited(_basculerPause(pause))
          : null,
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
      // Plan de composition du 26/10/2026 : la carte d'un eleve, depliee
      // dans le panneau de gauche, porte les actions qui aboutissent dans
      // `/salle` (rappel discret, recitation, et depuis NON-BRANCHE 7 le
      // signalement). « Noter » n'a pas encore de proprietaire : absente,
      // jamais grisee.
      // NON-BRANCHE-LIVRAISON 7 : « Signaler un besoin », gardee par la
      // capacite de la feuille (`signalementDisponible` : Classe connue,
      // serveur present), la meme que sur la fiche de l'eleve.
      onSignaler:
          signalementDisponible(
            ref.watch(portSignalementProvider),
            widget.groupeId,
          )
          ? (EleveSeance e) => unawaited(
              signalerDepuisSeance(
                context,
                e,
                seance,
                seanceId: widget.seanceId,
                groupeId: widget.groupeId,
              ),
            )
          : null,
      onRappeler: enseignant
          ? (EleveSeance e) => unawaited(_rappeler(e))
          : null,
      onChoisirPourReciter: enseignant
          ? (EleveSeance e) {
              final String? id = e.id;
              if (id == null) return;
              final String? profil = _profilDe(id);
              if (profil == null) {
                // Sans presence lue, la pastille du roster suit quand meme.
                ref.read(recitationProvider.notifier).donnerLaParoleA(id);
                return;
              }
              // Le meme bouton termine la recitation de l'eleve qui recite.
              if (_synchro?.parole.value?.profilId == profil) {
                unawaited(_terminerRecitation());
              } else {
                unawaited(
                  _faireReciter(
                    ParoleSalle(profilId: profil, prenom: e.prenom),
                  ),
                );
              }
            }
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
      // Lot salle 3 (directeur, 25/10/2026) : un support ouvert se ferme ;
      // la classe revient au tableau ou a la scene.
      onRanger: enseignant && presentee != null
          ? () => unawaited(ref.read(presentateurCoranProvider).fermer())
          : null,
      onContexte: (ContexteOuvert c) => setState(() {
        _contexte = c;
        if (c != ContexteOuvert.aucun && _panneau == PanneauOuvert.commandes) {
          _panneau = PanneauOuvert.aucun;
        }
      }),
      // D9 : la page tourne pour toute la classe, par le canal de donnees.
      // PARTAGE-GENERIQUE : tourner la page ne sait rien du support ; un
      // support que cet appareil ne connait pas ne se tourne pas d'ici.
      onPagePrecedente:
          enseignant && presentee != null && page != null && page > 1
          ? () => unawaited(_tournerPage(presentee, supportOuvert, page - 1))
          : null,
      onPageSuivante:
          enseignant && presentee != null && page != null && page < dernierePage
          ? () => unawaited(_tournerPage(presentee, supportOuvert, page + 1))
          : null,
    );
    // La scene en grand : choisie, sinon chez l'eleve tant que rien n'est
    // presente. Le bouton de retour n'existe que si une page (ou le panneau
    // de l'enseignant) attend derriere.
    // Rien de presente : la scene en grand pour tous (les visages, ADR-001) ;
    // une page presentee prend l'espace principal, la video revient en
    // vignette, et la toucher remet la scene en grand.
    // SCENE-CLASSE : la demande « voir la classe », calculee a un seul
    // endroit (`voirLaClasse`, `media_salle.dart`) ; le mode de la scene en
    // decoule (`modeSceneDe`, `zone_support.dart`).
    final bool scenePremierPlan = voirLaClasse(
      tableauOuvert: tableau,
      pagePresentee: presentee != null,
      choix: _scenePremierPlan,
    );
    final bool basculable = presentee != null || tableau;
    // Point 2 (30/10/2026) : l'eleve qui a la parole, chez tous.
    final ParoleSalle? parole = synchro?.parole.value;
    return PorteeMediaSalle(
      // S0.2 : l'en-tete tient sur une ligne ; la presence de l'eleve y
      // passe en pastille (section 6.6, la sienne seulement) ; la liste de
      // l'enseignant est sa colonne Eleves.
      pleinCadre: true,
      supports: enseignant && vue.peutPresenter
          ? <SupportBibliotheque>[
              _coranDeLaBibliotheque(pageCoran),
              // PARTAGE-GENERIQUE : les autres supports que la salle sait
              // partager (aucun en production le 11/11/2026).
              for (final SupportDeSalle s in supportsConnus)
                _supportDeLaBibliotheque(s),
            ]
          : const <SupportBibliotheque>[],
      messageEleves: enseignant ? (_echecGeste ?? _echecRappel) : null,
      // La page presentee ne se lit pas : rien ne se pose par-dessus son
      // constat ni son « Reessayer » (capsule du telephone).
      pageEnErreur: pageCoran != null && pagePresenteeEnErreur(ref, pageCoran),
      // Au telephone, l'enseignant n'a pas de colonne : « Eleves » ouvre la
      // presence (J3) et le roster (fiche, rappel) en feuille.
      // DYNAMIQUE-CHRONO-1 : la presence et l'eleve qui recite sont des
      // marques de la Dynamique chrono, plus des pastilles posees a cote.
      marques: enseignant
          ? const <MarqueChrono>[]
          : marquesPresence(mienne: mienne, parole: parole),
      // CHRONO-ETAT (11/11/2026) : presence confirmee, la pilule d'etat le
      // dit elle-meme (« En salle ») et la pastille ne le repete pas.
      presenceEnSalle: !enseignant && mienne.etat == EtatPresence.presente,
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
              sortis: vue.peutModerer
                  ? (
                      lecture: ref.watch(elevesSortisProvider(widget.seanceId)),
                      onReadmettre: (EleveSorti e) => unawaited(_readmettre(e)),
                      onRelire: () =>
                          ref.invalidate(elevesSortisProvider(widget.seanceId)),
                    )
                  : null,
              gestesPour: vue.peutModerer
                  ? (String profil) {
                      for (final ParticipantSalle p in vue.participantsListes) {
                        if (p.identite == profil) {
                          return _menuGestes(
                            p,
                            recite: parole?.profilId == profil,
                          );
                        }
                      }
                      return null;
                    }
                  : null,
            )
          : null,
      // D14 : effacee des que la camera publie.
      // GESTES-POINTEUR : l'appel recu ne passe plus ici (cette couche se
      // masque au telephone) ; il se dit en tete de la salle
      // ([CoucheAnnonceGeste]).
      alerte: (moi?.camera ?? false) || _erreurCameraFermee
          ? null
          : _cameraAbsente
          ? _ErreurCamera(
              erreur: null,
              onFermer: () => setState(() => _erreurCameraFermee = true),
            )
          : switch (_erreurCamera ?? _moteur.erreurCameraEntree) {
              final String erreur => _ErreurCamera(
                erreur: erreur,
                onFermer: () => setState(() => _erreurCameraFermee = true),
              ),
              null => null,
            },
      scene: SceneClasse(
        vue: vue,
        attendu: enseignant ? null : seance.nomEnseignant,
        tutoie: _tutoieSalle,
        recitant: parole?.profilId,
        menuPour: _menuGestes,
        // Une personne, un cadre (defaut D-1, cahier §8) : l'image de
        // l'enseignant est deja sa vignette (en tete du panneau des eleves
        // sur ordinateur, capsule au telephone).
        moiDejaEnCadre: enseignant,
        // VISAGES (point 8) : LA scene du mode Classe, avec son fond doux ;
        // elle n'est montree que lorsque ni la page ni le tableau ne
        // l'occupent (`modeSceneDe`).
        fond: true,
      ),
      scenePremierPlan: scenePremierPlan,
      onBasculerScene: basculable
          ? () => setState(() => _scenePremierPlan = !scenePremierPlan)
          : null,
      // L'enseignant sans page ouvre le Coran depuis la scene : la page
      // choisie prend aussitot l'espace principal.
      actionScene: enseignant && presentee == null && vue.peutPresenter
          ? (
              libelle: t.salle.seance.commandes.bibliotheque,
              onPress: () => unawaited(_ouvrirCoran()),
            )
          : null,
      video: moteur.renduVideo,
      // RUBAN-ORDINATEUR : la parole de chacun, pour l'anneau des cadres du
      // panneau des Eleves (seul le cadre l'ecoute, jamais la page).
      parle: (String identite) => moteur.participants
          .map(
            (List<ParticipantSalle> l) => l.any(
              (ParticipantSalle p) => p.identite == identite && p.parle,
            ),
          )
          .distinct(),
      // L'enseignant chez l'eleve ; sa propre image chez l'enseignant.
      // RUBAN-TELEPHONE (MODES-AFFICHAGE §4, precise le 11/11) : chez
      // l'eleve, la vignette montre TOUJOURS l'enseignant (c'est lui qui
      // corrige ; le camarade qui recite s'entend, et sur un ecran large il
      // a son cadre dans la bande de cote). Remplace le Point 2 du 30/10.
      identiteVignette: (enseignant ? moi : vue.dominant)?.identite,
      identiteRecitant: parole?.profilId,
      // RUBAN-TELEPHONE : LE cadre de la grille, hors de la grille.
      cadre:
          (
            String identite, {
            String? libelleNom,
            Widget? coin,
            bool detache = false,
          }) => SceneClasse.cadreHorsGrille(
            vue,
            identite,
            recitant: parole?.profilId,
            libelleNom: libelleNom,
            coin: coin,
            detache: detache,
          ),
      // PHOTOS-A (04/11/2026) : la photo de la vignette se lit par
      // identiteVignette (l'id), dans VignetteVideo ; plus de cle copiee.
      // L'enseignant garde les etats de lecture de son panneau (page
      // indisponible, texte non installe) ; l'eleve lit la page (D9).
      // PARTAGE-GENERIQUE : un lecteur par support. Le Coran garde le
      // sien ; un support connu rend sa page ; un support inconnu de cette
      // application le dit, jamais une page vide ni une page du Coran.
      page: (SupportPageFixe support) =>
          support.id != ContenuPresente.supportCoran
          ? KeyedSubtree(
              key: SallePage.pageEleveKey,
              child: _pageDuSupport(context, supportsConnus, support),
            )
          : enseignant && presentee != null
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
        child: CoucheAnnonceGeste(
          // ENTREE-ROBUSTE : le son bloque passe avant l'annonce d'un geste.
          annonce: _annonceSon ?? _annonce,
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
      ),
    );
  }

  /// Plan de composition du 26/10/2026 : les inscrits de la seance avec leur
  /// fiche (roster pedagogique), pour le panneau Eleves de l'ordinateur. Un
  /// fait que le serveur ne projette pas reste vide (la carte ne le montre
  /// pas) ; un eleve que le roster ne rend pas (lecture en echec) garde une
  /// fiche vide : sa carte se deplie quand meme et porte ses actions
  /// (rappel, recitation), qui ne visent que son matricule.
  static List<EleveSeance> _avecFiches(
    List<EleveSeance> eleves,
    RosterClasseVM roster,
    SuiviClasseSalle? suivi,
  ) => <EleveSeance>[
    for (final EleveSeance e in eleves)
      switch (e.id == null ? null : roster.parAcademyId(e.id!)) {
        final TeacherStudentProjection p => EleveSeance(
          prenom: e.prenom,
          statut: e.statut,
          id: e.id,
          cleAvatar: e.cleAvatar,
          profilId: e.profilId,
          peutEcrire: e.peutEcrire,
          // RUBAN-ORDINATEUR : le reseau et le micro lus du moteur
          // (`depuis_salle.dart`) ne se perdent plus en route.
          reseau: e.reseau,
          microOuvert: e.microOuvert,
          fiche: _completer(ficheDeSeance(p), e.profilId, suivi),
        ),
        null when e.id != null => EleveSeance(
          prenom: e.prenom,
          statut: e.statut,
          id: e.id,
          cleAvatar: e.cleAvatar,
          profilId: e.profilId,
          peutEcrire: e.peutEcrire,
          reseau: e.reseau,
          microOuvert: e.microOuvert,
          fiche: _completer(
            const FicheEleveSeance(
              niveau: '',
              objectifActuel: '',
              derniereSeance: '',
              aReprendre: '',
              presenceRecente: '',
              travailActuel: '',
            ),
            e.profilId,
            suivi,
          ),
        ),
        null => e,
      },
  ];

  /// RELEVE-SUIVI point 4 : la fiche completee par le suivi de la Classe,
  /// quand la salle connait sa Classe.
  static FicheEleveSeance _completer(
    FicheEleveSeance base,
    String? profilId,
    SuiviClasseSalle? suivi,
  ) => suivi == null
      ? base
      : ficheAvecSuivi(base, profilId: profilId, suivi: suivi);

  /// Les trois lectures du suivi de la Classe de la seance (deja branchees
  /// pour la fiche de la classe et le cahier), ou `null` quand la salle ne
  /// connait pas sa Classe.
  SuiviClasseSalle? _suiviClasse(WidgetRef ref) {
    final String? groupe = widget.groupeId;
    if (groupe == null) return null;
    return (
      etapes: ref.watch(etapesElevesClasseProvider(groupe)),
      observations: ref.watch(observationsClasseProvider(groupe)),
      pageClasse: ref.watch(pageRepriseClasseProvider(groupe)),
    );
  }

  /// Le rappel discret depuis le panneau Eleves ; l'echec se dit sous son
  /// titre, la reussite ne dit rien (spec section 10.2).
  /// N3, S2 : demarre la pause programmee, ou la termine si elle est en
  /// cours. Le serveur horodate ; on relit son etat dans tous les cas.
  Future<void> _basculerPause(PauseSeance pause) async {
    final PortPauseSeance port = ref.read(portPauseSeanceProvider);
    final String cle = const Uuid().v4();
    String? echec;
    setState(() => _echecPause = null);
    try {
      if (pause.statut == StatutPause.enCours) {
        await port
            .terminer(seanceId: widget.seanceId, cleIdempotence: cle)
            .timeout(AppDelais.requeteMax);
      } else {
        await port
            .demarrer(seanceId: widget.seanceId, cleIdempotence: cle)
            .timeout(AppDelais.requeteMax);
      }
    } on Object {
      // Non confirme : la phrase le dit, et l'etat relu ci-dessous dit ce
      // que le serveur sait.
      echec = t.salle.seance.pause.echec;
    }
    if (!mounted) return;
    setState(() => _echecPause = echec);
    ref.invalidate(pauseSeanceProvider(widget.seanceId));
  }

  Future<void> _rappeler(EleveSeance eleve) async {
    final String? id = eleve.id;
    if (id == null) return;
    final String? echec = await rappelerDiscretement(
      ref.read(portRappelDiscretProvider),
      sessionId: widget.seanceId,
      academyId: id,
    );
    if (!mounted) return;
    setState(() => _echecRappel = echec);
    _retourAppel(eleve.prenom, echec);
  }

  /// GESTES-POINTEUR : « Appeler » rend toujours un retour a qui conduit la
  /// seance. Parti : l'eleve a recu un son et un message. Pas parti : la
  /// raison et quoi faire.
  void _retourAppel(String prenom, String? echec) {
    _annoncer(
      echec == null
          ? AnnonceGeste(
              cle: const ValueKey<String>('appel-envoye'),
              titre: t.salle.gestes.appelEnvoyeTitre(prenom: prenom),
              message: t.salle.gestes.appelEnvoye,
            )
          : AnnonceGeste(
              cle: const ValueKey<String>('appel-echec'),
              titre: t.salle.gestes.appelEchecTitre(prenom: prenom),
              message: echec,
              ton: TonEtat.alerte,
            ),
    );
  }

  /// « Appeler » depuis le menu d'un cadre de la grille.
  Future<void> _appelerParticipant(ParticipantSalle p) async {
    final String? matricule = _matriculeDe(p.identite);
    if (matricule == null) {
      _retourAppel(
        p.nom,
        t.salle.gestes.appelEchec(quePrenom: queDevant(p.nom)),
      );
      return;
    }
    final String? echec = await rappelerDiscretement(
      ref.read(portRappelDiscretProvider),
      sessionId: widget.seanceId,
      academyId: matricule,
    );
    if (mounted) _retourAppel(p.nom, echec);
  }

  /// La page retenue pour la Classe : celle de cet appareil d'abord, sinon
  /// celle du serveur (CAHIER-C1, autre appareil ou remplacant).
  int? _pageRetenue() {
    final String? groupe = widget.groupeId;
    final int? locale = groupe == null
        ? null
        : ref.read(memoirePageClasseProvider).lire(groupe);
    return locale ?? ref.read(pageRepriseSeanceProvider(widget.seanceId)).value;
  }

  /// Le Coran dans la Bibliotheque de l'ordinateur : « Presenter » choisit
  /// la sourate et le verset ; « Reprendre page N » la page retenue pour la
  /// Classe.
  SupportBibliotheque _coranDeLaBibliotheque(int? pagePresentee) {
    final int? retenue = _pageRetenue();
    return SupportBibliotheque(
      id: 'coran',
      titre: t.salle.supports.coran,
      detail: retenue == null
          // SUPPORTS-ETAGERE : « Partager » et « Afficher » s'expliquent sur
          // la fiche ; la legende dit seulement ou en est la classe.
          ? t.salle.etagere.jamaisOuvert
          // CAHIER-C1 (06/11/2026) : la page retenue au serveur se dit
          // « On reprend page N », pour le titulaire comme pour le
          // remplacant qui entre dans la salle.
          : t.cahierC1.onReprendPage(page: retenue),
      couverture: CouvertureRessource.coran(t.salle.supports.coran),
      onPresenter: () => unawaited(_ouvrirCoran()),
      pageReprise: retenue,
      onReprendre: retenue == null
          ? null
          : () => unawaited(_presenterPage(retenue)),
      presenterSecondaire:
          pagePresentee != null && pagePresenteeEnErreur(ref, pagePresentee),
      // SUPPORTS-ETAGERE (11/11/2026) : « Afficher », la page lue par
      // l'enseignant seul ; « Partager page N » la presente a la classe.
      lecteur: LecteurSupport(
        pages: pagesMushafMedine,
        pageDepart: retenue ?? pagePresentee ?? 1,
        // PAGES-FLUIDES : sans cle par numero, la page lue reste a l'ecran
        // pendant que la suivante se lit, puis le fondu (`PageCoranSalle`).
        page: (BuildContext _, int numero) => PageCoranSalle(numero: numero),
        partagerPage: (int numero) => unawaited(_presenterPage(numero)),
      ),
    );
  }

  Future<void> _presenterPage(int page) async {
    setState(() => _scenePremierPlan = null);
    await ref.read(presentateurCoranProvider).presenterPage(page);
  }

  /// PARTAGE-GENERIQUE : la page [support] rendue par le lecteur de son
  /// support, ou l'etat « ce support ne peut pas encore s'afficher ici ».
  static Widget _pageDuSupport(
    BuildContext context,
    List<SupportDeSalle> connus,
    SupportPageFixe support,
  ) {
    for (final SupportDeSalle s in connus) {
      if (s.id == support.id && s.version == support.version) {
        // PAGES-FLUIDES (directeur, 12/11/2026) : le meme fondu court que
        // la page du Coran au changement de page ; rien sous « reduire les
        // animations » (`FonduAuChangement`).
        return FonduAuChangement(
          cle: '${support.id}:${support.page}',
          child: s.page(context, support.page),
        );
      }
    }
    return const SupportIllisibleIci();
  }

  /// PARTAGE-GENERIQUE : la page retenue du support [id] pour la Classe :
  /// celle de cet appareil d'abord, sinon celle du serveur.
  int? _pageRetenueDe(SupportDeSalle support) {
    final String? groupe = widget.groupeId;
    final int? locale = groupe == null
        ? null
        : ref.read(memoireRepriseSupportProvider).lire(groupe, support.id);
    final int? retenue =
        locale ??
        ref
            .read(pagesRepriseSupportsProvider(widget.seanceId))
            .value?[support.id];
    return retenue == null || retenue > support.pages ? null : retenue;
  }

  /// PARTAGE-GENERIQUE : un support de la salle sur l'etagere, avec le meme
  /// mecanisme que le Coran : « Partager » (a la page retenue, sinon la
  /// premiere), « Afficher » pour soi, « Partager page N ».
  SupportBibliotheque _supportDeLaBibliotheque(SupportDeSalle support) {
    final int? retenue = _pageRetenueDe(support);
    // Le serveur ne sait pas encore retenir la page de ce support (migration
    // non installee) : une phrase le dit, jamais une erreur.
    final bool nonRetenue = ref.watch(repriseSupportNonRetenueProvider);
    return SupportBibliotheque(
      id: support.id,
      titre: support.titre,
      detail: support.detail ?? t.salle.etagere.jamaisOuvert,
      note: nonRetenue ? t.salle.support.repriseNonRetenue : null,
      couverture: support.couverture,
      aValider: support.aValider,
      repere: support.repere,
      onPresenter: () => unawaited(_partagerSupport(support, 1)),
      pageReprise: retenue,
      onReprendre: retenue == null
          ? null
          : () => unawaited(_partagerSupport(support, retenue)),
      lecteur: LecteurSupport(
        pages: support.pages,
        pageDepart: retenue ?? 1,
        page: (BuildContext contexte, int numero) => AspectRatio(
          aspectRatio: support.largeurPage / support.hauteurPage,
          child: support.page(contexte, numero),
        ),
        partagerPage: (int numero) =>
            unawaited(_partagerSupport(support, numero)),
      ),
    );
  }

  /// PARTAGE-GENERIQUE : partage la page [numero] de [support] a la classe.
  /// Le droit reste celui du jeton : sans `can_publish_data`, le moteur
  /// refuse en silence et rien ne part.
  Future<void> _partagerSupport(SupportDeSalle support, int numero) async {
    setState(() => _scenePremierPlan = null);
    await ref
        .read(moteurSalleProvider)
        .presenterContenu(
          support.contenu(
            numero: numero,
            presentePar: ref.read(sessionProvider).profileId ?? '',
            emisLe: DateTime.now(),
          ),
        );
  }

  /// PARTAGE-GENERIQUE : tourne la page du support presente, quel qu'il
  /// soit. Le Coran passe par son presentateur (il situe sourate et verset).
  Future<void> _tournerPage(
    ContenuPresente presentee,
    SupportDeSalle? support,
    int numero,
  ) async {
    if (presentee.estCoran) {
      await ref.read(presentateurCoranProvider).presenterPage(numero);
    } else if (support != null) {
      await _partagerSupport(support, numero);
    }
  }

  /// S0 : la bibliotheque du Coran, puis la page presentee a la classe ;
  /// la scene cede la place a la page.
  /// Lot salle 2 (directeur, 25/10/2026) : la Bibliotheque montre le choix
  /// des supports (aujourd'hui le Coran seul) au lieu
  /// d'ouvrir le Coran d'office. Le Coran reprend a la derniere page
  /// presentee dans la classe, sinon le choix de la sourate et du verset.
  Future<void> _choisirSupport() async {
    final bool coran =
        await AppBottomSheet.ouvrir<bool>(
          context,
          // Plan de composition du 26/10/2026 : « Bibliotheque » partout,
          // et aucune promesse de supports a venir.
          titre: t.tc.bibliotheque.titre,
          constructeur: (BuildContext feuille) => CarteLignes(
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
        ) ??
        false;
    if (!coran || !mounted) return;
    final int? retenue = _pageRetenue();
    if (retenue == null) return _ouvrirCoran();
    setState(() => _scenePremierPlan = null);
    await ref.read(presentateurCoranProvider).presenterPage(retenue);
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
    // HEURE-PROFIL (12/11/2026) : la salle se redessine quand le fuseau du
    // profil arrive ; chaque heure (fin de seance, refus) est formee au
    // dessin par `DepuisSalle.heure`, a partir d'un instant garde.
    ref.watch(monHorlogeProvider);
    return _dessiner(context);
  }

  Widget _dessiner(BuildContext context) =>
      // Selection du texte (directeur, 07/11/2026) : la salle en entier est
      // hors de la selection, l'appui long y a un role.
      TexteProtege(
        // SORTIE-SALLE (11/11/2026) : le retour du telephone quand la salle
        // est la seule page de la pile (entree par `go`) fermerait
        // l'application et couperait l'appel ; il reduit la salle a la place.
        // Le retour du navigateur, lui, change d'adresse sans passer ici : la
        // page se demonte et l'appel confie continue.
        child: PopScope<Object?>(
          canPop: !_tenu || (GoRouter.maybeOf(context)?.canPop() ?? true),
          onPopInvokedWithResult: (bool fait, Object? _) {
            if (!fait && _tenu) _quitterLEcran();
          },
          // TRANSITIONS-SALLE : le passage d'une etape a l'autre (l'arche
          // passe la main, la sortie), sans jamais retarder l'ecran.
          child: PassageSalle(
            etape: _etape(),
            arrivee: _depuisIle ? FaconPassage.depuisIle : FaconPassage.aucune,
            choisir: _passage,
            child: _construireSalle(context),
          ),
        ),
      );

  /// TRANSITIONS-SALLE : l'etape de l'ecran, lue sur l'etat deja tenu.
  _EtapeSalle _etape() {
    if (_finEnseignant != null || _sortieEleve != null) return _EtapeSalle.fin;
    if (_enPreparation) return _EtapeSalle.preparation;
    final PhaseSalle phase = VueSalle.depuis(
      materielPret: _materielPret,
      acces: _acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse,
    ).phase;
    return switch (phase) {
      PhaseSalle.materiel ||
      PhaseSalle.ouverture ||
      PhaseSalle.connexion => _EtapeSalle.attente,
      PhaseSalle.refus => _EtapeSalle.refus,
      PhaseSalle.enSalle ||
      PhaseSalle.instable ||
      PhaseSalle.reconnexion ||
      PhaseSalle.retabli => _EtapeSalle.salle,
    };
  }

  /// TRANSITIONS-SALLE : la salle prete prend la main de l'arche par un
  /// voile qui s'efface ; toute sortie (volontaire ou subie, impasse
  /// comprise) est un fondu court, jamais un moment de marque.
  FaconPassage _passage(Object avant, Object apres) {
    if (avant == _EtapeSalle.attente && apres == _EtapeSalle.salle) {
      final bool voile = _archeMontree;
      _archeMontree = false;
      return voile ? FaconPassage.voile : FaconPassage.aucune;
    }
    if (avant == _EtapeSalle.salle &&
        (apres == _EtapeSalle.fin || apres == _EtapeSalle.refus)) {
      return FaconPassage.fondu;
    }
    return FaconPassage.aucune;
  }

  Widget _construireSalle(BuildContext context) {
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
        seanceId: widget.seanceId,
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
        // UX-043 : seance close par le serveur, aucun retour propose.
        onRetournerSalle: (fin.fin?.close ?? false)
            ? null
            : _retournerDansLaSalle,
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
          tutoiement: _ageDeLEleve().tutoiement,
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
        finA: _finServeur,
        // NON-BRANCHE-LIVRAISON 5 : le Retour eclair apres une seance
        // terminee. Le serveur decide s'il pose une question (une seance sur
        // quatre en moyenne) ; sans question, la carte n'occupe aucune place.
        complement: sortie == IssueSeance.terminee
            ? CarteFeedbackSeance(sessionId: widget.seanceId)
            : null,
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

    // **`.value`, et surtout pas un filtrage par le type de l'AsyncValue**
    // (piege de l'etape 3, Riverpod 3). Les trois cas qui rendent `null` --
    // pas encore charge, lecture refusee, reseau coupe -- se disent de la meme
    // facon a l'ecran : inconnu. C'est J3, et c'est ce qui le rend simple.
    final List<PresenceParticipant>? presence = ref
        .watch(presenceSeanceProvider(widget.seanceId))
        .value;
    // Directeur, 26/10/2026 (test en production) : le jeton ne porte aucun
    // nom. L'annuaire de la seance nomme chaque participant (« Sayyida
    // Amina », « Yasmine ») et donne sa photo ; l'identite technique n'est
    // jamais rendue.
    final FicheEnseignantSeance? ficheEnseignant = _ficheEnseignant(
      ref,
      presence,
    );
    // PHOTOS-2b (pilote, 04/11/2026) : l'eleve adulte nomme ses camarades
    // par sa Classe (`participants_classe_eleve_adulte`) ; un enfant ne lit
    // aucun prenom de camarade (protection des mineurs, decision du pilote
    // du 04/11/2026) : la vignette garde la photo ou un cercle neutre,
    // jamais « Participant ». Seuls l'enseignant et le controleur, qui lisent
    // la liste, gardent ce repli.
    final RoleSalle roleSalle = RoleSalle.depuis(_acces?.role);
    final List<CamaradeSeance> camarades =
        ref.watch(sessionProvider.select((SessionState s) => s.eleveAutonome))
        ? <CamaradeSeance>[
            for (final ParticipantClasseAdulte c
                in ref.watch(maClasseAdulteProvider).value?.participants ??
                    const <ParticipantClasseAdulte>[])
              (id: c.id, prenom: c.prenom),
          ]
        : const <CamaradeSeance>[];
    final AnnuaireSeance annuaire = AnnuaireSeance(
      presence: presence,
      enseignant: ficheEnseignant,
      camarades: camarades,
      nommerLesInconnus:
          roleSalle == RoleSalle.enseignant ||
          roleSalle == RoleSalle.controleur,
    );
    final VueSalle vue = VueSalle.depuis(
      materielPret: _materielPret,
      acces: _acces,
      etatMoteur: _etatMoteur,
      participants: <ParticipantSalle>[
        for (final ParticipantSalle p in _participants) annuaire.nommer(p),
      ],
      qualite: _qualite,
      impasse: _impasse,
    );
    final bool enImpasse = vue.phase == PhaseSalle.refus;
    // TRANSITIONS-SALLE : l'arche tient la place de l'attente nue, le temps
    // de l'attente reelle et pas plus ; l'attente finie, elle ne revient
    // jamais sur cet ecran.
    final bool arche = _archeAJouer && _attenteDe(vue) != null;
    if (_attenteDe(vue) == null) _archeAJouer = false;
    if (arche) _archeMontree = true;
    // SALLE-ENCRE-1 : les textes de la salle prennent l'encre du registre
    // `salle` (celle que `PageImmersive` pose en fond) pour TOUS les roles,
    // hors Mode Accessibilite aussi (`_encreSalle`). Ce drapeau ne garde que
    // le bandeau permanent pose sur la surface des vignettes (MA-5) : le
    // bandeau n'est pas du perimetre (JUR-APP-1).
    final bool encreAccessible =
        vue.role == RoleSalle.eleve &&
        ref.watch(modeAccessibiliteActifProvider);

    final List<_Presence> lignes = _Presence.composer(
      presence: presence,
      vue: vue,
      monProfil: monProfil,
      maintenant: DateTime.now(),
      annuaire: annuaire,
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
    // PARTAGE-GENERIQUE : les etats de lecture du mushaf ne valent que pour
    // le Coran ; un autre support a son lecteur.
    final bool coranEleve = pageEleve?.estCoran ?? false;
    // D9 : l'enseignant presente une page (le flux qu'il lit lui-meme) : sur
    // telephone, la page prend alors toute la largeur ou toute la hauteur.
    final ContenuPresente? pagePresentee = _panneauEnseignant(vue) && !enImpasse
        ? ref.watch(contenuPresenteProvider).value
        : null;
    // Le panneau de l'enseignant lit d'abord la page (etats de lecture) : la
    // page ne prend la place que si elle est lue. PAGES-FLUIDES : dans le
    // meme cache que le rendu (`etatPagePresentee`), plus de seconde lecture.
    final bool pageEnseignant =
        pagePresentee != null &&
        pagePresentee.estCoran &&
        etatPagePresentee(ref, pagePresentee.page) == EtatLecteur.lecture &&
        pageCoranLisible(ref, pagePresentee.page);
    final bool pageEleveLisible =
        pageEleve != null &&
        coranEleve &&
        pageCoranLisible(ref, pageEleve.page);

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
      // classe. Lot salle 3 (directeur, 25/10/2026) : elle ne se rouvre plus
      // seule a l'entree ; « Ouvrir le Coran » la propose (choix de
      // l'enseignant).
      // CAHIER-C1 (06/11/2026) : la page part aussi au serveur, pour la
      // preparation de la seance suivante et pour le remplacant ; le serveur
      // retrouve la classe par la seance.
      final String? groupe = widget.groupeId;
      // PARTAGE-GENERIQUE : la page d'un autre support ne s'ecrit jamais
      // dans la memoire du Coran (elle ecraserait la page du Coran de la
      // Classe) ; elle a la sienne, par Classe et par support.
      if (vue.role == RoleSalle.enseignant && presentee != null) {
        if (presentee.estCoran) {
          ref
              .read(memoirePageClasseProvider)
              .ecrire(groupe, presentee.page, sessionId: widget.seanceId);
        } else if (supportDeSalleDe(
              presentee,
              ref.read(supportsDeSalleProvider),
            )
            case final SupportDeSalle ouvert) {
          ref
              .read(memoireRepriseSupportProvider)
              .ecrire(
                groupe,
                support: ouvert.id,
                version: ouvert.version,
                page: presentee.page,
                pages: ouvert.pages,
                sessionId: widget.seanceId,
              );
        }
      }
      // CAHIER-C1 : la page retenue au serveur, lue une fois a l'entree, pour
      // « Reprendre page N » sur un autre appareil.
      if (vue.role == RoleSalle.enseignant) {
        ref.watch(pageRepriseSeanceProvider(widget.seanceId));
        // PARTAGE-GENERIQUE : les pages retenues des autres supports, lues
        // seulement quand la salle en connait (aucun en production).
        if (ref.watch(supportsDeSalleProvider).isNotEmpty) {
          ref.watch(pagesRepriseSupportsProvider(widget.seanceId));
        }
      }
      // Plan de composition du 26/10/2026 : le nom de la Classe et le titre
      // de l'enseignant (« Sayyida Amina ») en haut de la salle. Revue de la
      // PR 60 : l'enseignant lit le nom de sa Classe dans les siennes
      // (`mes_groupes_v`) ; la vue des familles ne lui rend rien.
      final String nomClasse = _nomClasse(ref, vue.role);
      final VueSeance? seance = DepuisSalle.vue(
        salle: vue,
        mode: AppMetriques.of(context).mode,
        nomEnseignantConnu: annuaire.enseignant,
        paysEnseignant: annuaire.paysEnseignant,
        idEnseignant: ficheEnseignant?.id,
        nomClasse: nomClasse,
        titreEnseignant: ficheEnseignant?.titre,
        presence: presence,
        monProfil: monProfil,
        monTuteurObserve: monTuteurObserve,
        annonces: annonces,
        groupeId: widget.groupeId,
        age: _ageDeLEleve(),
        releveTenu: _envoiReleve.tenuParLeServeur,
        // PARTAGE-GENERIQUE : le support presente, quel qu'il soit.
        supportPresente: presentee == null
            ? null
            : supportPresenteDe(presentee, ref.watch(supportsDeSalleProvider)),
        videoSuspendue: _repliAffiche.videoSuspendue,
        // RESEAU-ELEVES : le reseau de chacun, filtre (barres, alerte).
        reseaux: _suiviReseau.etats(),
        // L'ile reste posee partout, sauf au telephone de l'enseignant (moins
        // de 840 points), ou elle ne vit que dans le profil deplie : le
        // bandeau y garde la phrase de reseau (`salleTelephoneEnseignant`).
        reseauDansIle:
            vue.role != RoleSalle.enseignant ||
            MediaQuery.sizeOf(context).width >= AppGabarit.seuilEtendu,
        // FN-023 : le chrono du temps restant, sur les bornes que le serveur
        // sert deja (seances de l'enseignant ou de l'eleve).
        chrono: ref.watch(
          bornesSalleProvider((
            seanceId: widget.seanceId,
            groupeId: widget.groupeId,
            enseignant: vue.role == RoleSalle.enseignant,
          )),
        ),
      );
      // FERMETURE-SALLE : le moteur apprend la fin du depassement autorise
      // (servie par le serveur) ; a ce moment, il demande au serveur de
      // relire la regle. Il ne ferme rien lui-meme.
      if (_moteur case final FermetureParLeServeur fermeture) {
        fermeture.finPorteUtc = seance?.chrono?.finDepassementUtc;
      }
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
      return CoucheAnnonceGeste(
        annonce: _annonceSon,
        child: PageImmersive(
          registre: RegistreImmersif.salle,
          entete: _EnteteControle(
            vue: vue,
            onQuitter: () => unawaited(_quitter(vue)),
          ),
          bandeau: _Bandeaux(vue: vue),
          child: arche
              ? const _ArcheDeLAttente()
              : presentation != null
              ? _CorpsDocument(
                  vue: vue,
                  lignes: lignes,
                  document: _PresentationLue(vue: presentation),
                  presentationLue: true,
                )
              : _Corps(vue: vue, lignes: lignes),
        ),
      );
    }

    // ENTREE-ROBUSTE : la meme annonce du son bloque que dans la salle de
    // seance (tuteur observateur, autres roles).
    return CoucheAnnonceGeste(
      annonce: _annonceSon,
      child: PageImmersive(
        registre: RegistreImmersif.salle,
        lateraleEnPaysage: pageEleveLisible || pageEnseignant,
        entete: _Entete(
          vue: vue,
          monTuteurObserve: monTuteurObserve,
          annonces: annonces,
          // L'eleve lit SON etat, et lui seul : la section 6.6 le dit deux fois,
          // et la vue en base le lui impose de toute facon. L'observateur, lui,
          // n'a aucun etat pedagogique a lire -- il assiste.
          // ENTREE-ROBUSTE (relecture du 12/11) : quand ce compte est deja
          // dans la salle sur un autre appareil, « Votre presence : a quitte
          // le cours » contredirait le message de l'impasse (la personne EST
          // dans la salle, ailleurs) : l'etat n'est pas affiche.
          mienne:
              vue.role == RoleSalle.eleve &&
                  _impasse != CauseImpasse.ouverteAilleurs
              ? mienne
              : null,
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
                detail: _detailRefus,
                microRefuse: _microRefuseAvant,
                onReessayer: _entrer,
                onRentrer: _rentrer,
              )
            // TRANSITIONS-SALLE : le moment de l'arche, pendant l'attente
            // reelle seulement.
            : arche
            ? const _ArcheDeLAttente()
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
                document: coranEleve
                    ? PageCoranSalle(
                        key: SallePage.pageEleveKey,
                        numero: pageEleve.page,
                      )
                    : KeyedSubtree(
                        key: SallePage.pageEleveKey,
                        child: _pageDuSupport(
                          context,
                          ref.watch(supportsDeSalleProvider),
                          supportPresenteDe(
                            pageEleve,
                            ref.watch(supportsDeSalleProvider),
                          ),
                        ),
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
      ),
    );
  }
}

/// TRANSITIONS-SALLE : les etapes d'un ecran de salle, pour ses passages.
enum _EtapeSalle { preparation, attente, salle, refus, fin }

/// TRANSITIONS-SALLE : l'arche a la place de la scene, avec les marges de la
/// scene (rien ne touche le bord de l'ecran ni le bandeau).
class _ArcheDeLAttente extends StatelessWidget {
  const _ArcheDeLAttente();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    child: EntreeArche(),
  );
}

/// SITUATIONS-GRAVES (directeur, 11/11/2026, defaut n° 6) : le sujet du
/// paquet qui relaie la pause de la seance a la classe (canal fiable).
const String sujetPauseSalle = 'tc.salle.pause';

/// La charge du relais de pause : l'etat servi, sans aucune identite.
Map<String, Object?> chargePause(PauseSeance pause) => <String, Object?>{
  'statut': pause.statut.name,
  'duree': pause.dureePrevueMinutes,
  'debut': pause.debutUtc?.toUtc().toIso8601String(),
  'fin': pause.finUtc?.toUtc().toIso8601String(),
  'debutPrevu': pause.debutPrevuUtc?.toUtc().toIso8601String(),
};

/// Lit un relais de pause, ou `null` s'il est illisible. Jamais de commande :
/// `peutPiloter` reste faux chez qui le recoit.
PauseSeance? pauseDepuisCharge(List<int> charge) {
  try {
    final Object? lu = jsonDecode(utf8.decode(charge));
    if (lu is! Map) return null;
    final StatutPause? statut = StatutPause.values
        .where((StatutPause s) => s.name == lu['statut'])
        .firstOrNull;
    final Object? duree = lu['duree'];
    if (statut == null ||
        duree is! int ||
        duree < BornesPause.dureeMin ||
        duree > BornesPause.dureeMax) {
      return null;
    }
    DateTime? instant(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;
    return PauseSeance(
      statut: statut,
      dureePrevueMinutes: duree,
      debutUtc: instant(lu['debut']),
      finUtc: instant(lu['fin']),
      debutPrevuUtc: instant(lu['debutPrevu']),
    );
  } on Object {
    return null;
  }
}

/// L'annonce de tete d'une pause qui commence.
AnnonceGeste annoncePause() => AnnonceGeste(
  cle: const ValueKey<String>('pause-annonce'),
  titre: t.salle.situations.pauseTitre,
  message: t.salle.situations.pause,
);

/// SITUATIONS-GRAVES (directeur, 11/11/2026, defaut n° 2) : ce que l'eleve
/// sait de son enseignant. Une annonce par changement, jamais en boucle :
/// « pas encore arrive » a la premiere observation sans lui, « n'est plus
/// dans la salle » quand il part ; rien quand il est la. Seule la presence
/// lue dans la salle decide : la fermeture de la salle et les micros restent
/// au serveur.
class VeilleEnseignant {
  bool _vu = false;
  bool _dit = false;

  /// L'annonce a poser pour cette observation, ou `null`.
  ///
  /// [seul] : personne d'autre n'est dans la salle. Tant que l'enseignant
  /// n'est jamais venu, la scene d'attente le dit deja en grand : aucune
  /// annonce, et rien n'est retenu (l'annonce viendra si un camarade entre).
  AnnonceGeste? observer({
    required bool enseignantPresent,
    bool seul = false,
    bool tutoie = false,
  }) {
    if (enseignantPresent) {
      _vu = true;
      _dit = false;
      return null;
    }
    if (_dit) return null;
    if (!_vu && seul) return null;
    _dit = true;
    return _vu
        ? AnnonceGeste(
            cle: const ValueKey<String>('enseignant-parti'),
            titre: t.salle.situations.enseignantPartiTitre,
            message: tutoie
                ? t.salle.situations.enseignantPartiTutoie
                : t.salle.situations.enseignantParti,
          )
        : AnnonceGeste(
            cle: const ValueKey<String>('enseignant-attendu'),
            titre: tutoie
                ? t.salle.seulEnseignantTutoie
                : t.salle.seulEnseignant,
            message: tutoie
                ? t.salle.seulEnseignantDetailTutoie
                : t.salle.seulEnseignantDetail,
          );
  }
}

/// SITUATIONS-GRAVES (11/11/2026, defaut n° 3) : l'annonce de tete d'un
/// micro que le navigateur refuse : ce qui se passe, puis quoi faire.
AnnonceGeste annonceMicroBloque(CauseMicroBloque cause) => AnnonceGeste(
  cle: const ValueKey<String>('micro-bloque-annonce'),
  titre: t.salle.situations.microEchecTitre,
  message: texteCauseMicro(cause),
  ton: TonEtat.alerte,
);

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
/// Salle en groupe (30/10/2026) : les eleves sortis de la seance, pour qui
/// peut les readmettre.
typedef SortisSalle = ({
  AsyncValue<List<EleveSorti>> lecture,
  ValueChanged<EleveSorti> onReadmettre,
  VoidCallback onRelire,
});

class _ElevesSeance extends StatelessWidget {
  const _ElevesSeance({
    required this.lignes,
    required this.roster,
    required this.onOuvrirFiche,
    this.sortis,
    this.gestesPour,
  });

  final List<_Presence> lignes;
  final RosterClasseVM roster;
  final ValueChanged<String> onOuvrirFiche;

  /// Les eleves sortis et la readmission ; `null` sans `can_moderate`.
  final SortisSalle? sortis;

  /// Le menu des gestes sur un eleve connecte, par son profil ; `null` sans
  /// `can_moderate`. Le meme que sur son cadre : atteignable aussi quand une
  /// page du Coran occupe l'ecran.
  final Widget? Function(String profilId)? gestesPour;

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
              gestes: personne.profilId == null
                  ? null
                  : gestesPour?.call(personne.profilId!),
            ),
          if (sortis case final SortisSalle s) _ElevesSortis(sortis: s),
        ],
      ),
    );
  }
}

/// Salle en groupe (30/10/2026) : « Sortis du cours » et « Readmettre ».
/// Rien pendant la lecture ni quand personne n'est sorti (le cas courant) ;
/// une lecture en echec (reseau coupe compris) le dit, avec « Reessayer ».
class _ElevesSortis extends StatelessWidget {
  const _ElevesSortis({required this.sortis});

  final SortisSalle sortis;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveSorti>> lecture = sortis.lecture;
    if (!lecture.hasValue && lecture.hasError) {
      return Column(
        key: const ValueKey<String>('sortis-erreur'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.salle.gestes.sortisErreur,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          LienFleche(libelle: t.commun.reessayer, onPress: sortis.onRelire),
        ],
      );
    }
    final List<EleveSorti> liste = lecture.value ?? const <EleveSorti>[];
    if (liste.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey<String>('sortis'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.salle.gestes.sortis,
          style: palette.inkStrong.applyTo(
            textes.labelLarge ?? const TextStyle(),
          ),
        ),
        for (final EleveSorti e in liste)
          LienFleche(
            key: ValueKey<String>('readmettre-${e.profilId}'),
            libelle: t.salle.gestes.readmettre(prenom: e.prenom),
            onPress: () => sortis.onReadmettre(e),
          ),
      ],
    );
  }
}

/// S0.2c : la ligne d'une personne dans la colonne Eleves : le prenom en
/// ellipse (jamais coupe ni debordant), son etat en pastille (le mot entier,
/// J7), le micro coupe ; « consolide » dessous quand une decision l'a fige.
class _LigneEleve extends StatelessWidget {
  const _LigneEleve({required this.personne, this.onFiche, this.gestes});

  final _Presence personne;
  final VoidCallback? onFiche;

  /// Salle en groupe (30/10/2026) : le menu des gestes de l'enseignant sur
  /// cet eleve, au bord de fin, ou `null`.
  final Widget? gestes;

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
          // Fiche 1, ligne 14 (27/10/2026) : etroit ou texte agrandi, l'etat
          // passe sous le prenom plutot que de le tronquer.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                personne.nom,
                style: palette.inkStrong.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
              StatusPill(
                libelle: LignePresence.libelle(personne.vue.etat),
                ton: personne.vue.ton,
              ),
              if (personne.micro == false) ...<Widget>[
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
    final Widget corps = fiche == null
        ? MergeSemantics(child: ligne)
        : Pressable(
            onPress: fiche,
            libelleSemantique: personne.nom,
            child: ligne,
          );
    final Widget? menu = gestes;
    if (menu == null) return corps;
    return Row(
      children: <Widget>[
        Expanded(child: corps),
        menu,
      ],
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

/// S0.2 : l'etat de presence de l'eleve dans la salle de seance (section
/// 6.6 : le sien, et aucun autre), et l'eleve qui recite (point 2 du
/// 30/10/2026).
///
/// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026 : « le chrono cache le
/// document ») : ce ne sont plus des pastilles posees a cote de la barre,
/// sur la page, mais des marques de la Dynamique chrono (point de couleur lu,
/// en clair quand elle est depliee).
@visibleForTesting
List<MarqueChrono> marquesPresence({
  required VuePresence mienne,
  ParoleSalle? parole,
}) {
  // CHRONO-ETAT (directeur, 11/11/2026) : « En salle » est deja dit par la
  // ligne d'etat ; la marque ne reste que pour ce qui s'en ecarte (« Pas
  // encore la », « En retard »...). RESEAU-ELEVES (defaut C6-4) : la
  // reconnexion et la coupure de ma propre connexion sont dites par la ligne
  // d'etat ; la marque ne les redit pas.
  final bool ditAilleurs =
      mienne.etat == EtatPresence.presente ||
      mienne.etat == EtatPresence.enReconnexion ||
      mienne.etat == EtatPresence.deconnectee;
  final ParoleSalle? p = parole;
  return <MarqueChrono>[
    if (!ditAilleurs)
      MarqueChrono.presence(
        libelle: LignePresence.libelle(mienne.etat),
        ton: mienne.ton,
      ),
    if (p != null && p.prenom.isNotEmpty)
      MarqueChrono.recitation(
        libelle: t.tc.classe.recitation.actif(prenom: p.prenom),
      ),
  ];
}

/// D14 : la camera n'a pas pu s'allumer ; sa cause probable et quoi faire
/// (K-59), sous l'en-tete. La phrase exacte du navigateur ne s'affiche plus
/// (directeur, 12/11/2026 au soir : un eleve ne lit jamais un message
/// technique en anglais) ; le moteur l'envoie a la supervision
/// (`signalerMediaImpossible`).
///
/// Lot salle 3 (directeur, 25/10/2026) : le message se ferme (croix au bord
/// de fin, cible de 48, « Fermer »).
class _ErreurCamera extends StatelessWidget {
  const _ErreurCamera({required this.erreur, required this.onFermer});

  /// La phrase du navigateur, ou `null` quand le pre-vol a vu qu'aucune
  /// camera n'existe (rien n'a ete demande au navigateur).
  final String? erreur;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? navigateur = erreur;
    final String cause = navigateur == null
        ? t.salle.cameraEchecAbsente
        : causeEchecCamera(navigateur);
    // K4 (directeur, 25/10/2026) : l'erreur de camera est une pilule
    // translucente sous la ligne d'etat, dans la couche qui se masque, jamais
    // un bloc qui pousse la page. Ce qui manque, la cause et quoi faire
    // (K-59) ; le message du navigateur va a la supervision, pas a l'ecran.
    final TextStyle style = palette.piluleSalle.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // Le message et sa croix sont deux noeuds : le message s'annonce, la
    // croix est un bouton a part (sinon tout le message devenait le bouton).
    return Semantics(
      key: const ValueKey<String>('salle-erreur-camera'),
      container: true,
      explicitChildNodes: true,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Semantics(
                      liveRegion: true,
                      container: true,
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
                        ],
                      ),
                    ),
                  ),
                ),
                BoutonIcone(
                  key: const ValueKey<String>('salle-erreur-camera-fermer'),
                  icone: AppIcons.fermer,
                  libelle: t.commun.fermer,
                  onPress: onFermer,
                  forme: FormeBoutonIcone.nue,
                ),
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

    final _EtatLien? etatDuLien = _etatDuLien(vue);

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
              ?_pastilleDuLien(etatDuLien),
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
            ?_pastilleDuLien(etatDuLien),
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
///
/// UX-042 (01/11/2026) : en impasse (`refus` : seance terminee, salle
/// fermee, acces retire), aucun etat du lien. « En direct » au-dessus de
/// « Seance terminee » contredisait l'ecran.
_EtatLien? _etatDuLien(VueSalle vue) => switch (vue.phase) {
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
  PhaseSalle.refus => null,
  PhaseSalle.enSalle ||
  PhaseSalle.materiel ||
  PhaseSalle.ouverture ||
  PhaseSalle.connexion => (
    t.etat.enDirect,
    TonEtat.succes,
    EtatPastilleSeance.enDirect,
  ),
};

/// La pastille de l'etat du lien : « En direct » passe par le composant
/// partage d'etat de seance (ON-AIR-1), les autres etats par `StatusPill`.
/// `null` en impasse : rien a dire sur le lien (UX-042).
Widget? _pastilleDuLien(_EtatLien? etat) {
  if (etat == null) return null;
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
    final _EtatLien? lien = _etatDuLien(vue);
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
                    : _pastilleDuLien(lien) ?? const SizedBox.shrink(),
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
                    : _pastilleDuLien(lien) ?? const SizedBox.shrink(),
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
    // SALLE-2-ENTRETIEN (07/11/2026) : un entretien n'est pas un cours, la
    // mention du cours n'y a pas sa place. Et aucune mention a l'ecran
    // pendant l'entretien (decision du directeur du 21/10, CAND-Q09 : « c'est
    // ephemere ») : ni rappel ni bandeau, pour le candidat comme pour les
    // personnes qui menent l'entretien.
    if (vue.role == RoleSalle.candidat || vue.role == RoleSalle.intervieweur) {
      return const SizedBox.shrink();
    }
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
  /// sait faire seule (`GrilleVisages`, en pages sous son plancher).
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
            child: SceneClasse(vue: vue),
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
              child: SceneClasse(vue: vue),
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
          Expanded(flex: 2, child: SceneClasse(vue: vue)),
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
                child: SceneClasse(vue: vue),
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
      : SceneClasse.hauteurEntiere(_distants, AppGabarit.de(context)) +
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
    final double premiere = _distants <= 1 ? scene : SceneClasse.premiereRangee;
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

    // VISAGES (point 8) : rien n'est presente ici, la scene est en mode
    // Classe : son fond doux.
    if (!colonne) {
      return SceneClasse(vue: vue, fond: true);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: SceneClasse(vue: vue, fond: true)),
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

// SCENE-CLASSE (11/11/2026) : la scene en mode Classe (`SceneClasse`, la
// grille des visages, le cadre d'une personne, l'attente quand on est seul)
// vit dans `scene_classe.dart`.

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
    this.profilId,
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
    AnnuaireSeance? annuaire,
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
          nom: ligne.profilId == monProfil
              ? t.salle.vousMeme
              : annuaire?.personne(ligne.profilId)?.nom ?? ligne.prenom,
          role: _libelleRole(ligne.role),
          vue: VuePresence.depuis(ligne: ligne, maintenant: maintenant),
          // La base emet `identity = profile_id` : le rapprochement se fait
          // donc sans table de correspondance. `null` quand la personne n'est
          // pas dans la salle -- et « pas de micro » ne se dit pas alors, parce
          // que ce serait un fait, la ou il n'y a qu'une absence de fait.
          micro: _microDe(vue.participantsListes, ligne.profilId),
          academyId: ligne.identifiantImmuable,
          profilId: ligne.profilId,
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
    RoleSalle.candidat => t.salle.roleCandidat,
    RoleSalle.intervieweur => t.salle.roleIntervieweur,
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

  /// Son profil, qui est son identite dans la salle ; `null` sans presence
  /// lue.
  final String? profilId;
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
    this.detail,
    this.microRefuse = false,
  });

  final CauseImpasse cause;

  /// SITUATIONS-GRAVES (11/11/2026) : le navigateur refuse le micro (lu
  /// avant l'entree) ; l'impasse du materiel dit cette cause-la.
  final bool microRefuse;

  /// FN-025 : le motif servi par le serveur a qui avait droit a la salle.
  final DetailRefusSalle? detail;

  /// HEURE-PROFIL : « Heure de cet appareil », sur une petite ligne sous un
  /// refus qui dit une heure, quand cette heure n'est pas celle du profil.
  static String? _mentionAcces(DetailRefusSalle? detail) =>
      switch (detail?.motif) {
        MotifServeurSalle.terminee when detail?.finUtc != null =>
          DepuisSalle.mentionAppareil(detail!.finUtc!),
        MotifServeurSalle.pasEncoreOuverte when detail?.ouvertureUtc != null =>
          DepuisSalle.mentionAppareil(detail!.ouvertureUtc!),
        _ => null,
      };

  /// FN-025 : le refus dit sa raison et l'heure du serveur, quand le serveur
  /// les donne ; sinon le refus generique.
  static (String, String) _ditAcces(DetailRefusSalle? detail) {
    final DateTime? fin = detail?.finUtc;
    final DateTime? ouverture = detail?.ouvertureUtc;
    return switch (detail?.motif) {
      MotifServeurSalle.terminee when fin != null => (
        t.salle.fin.titre,
        t.salle.refusTerminee(heure: DepuisSalle.heure(fin)),
      ),
      MotifServeurSalle.pasEncoreOuverte when ouverture != null => (
        t.salle.refusAcces,
        t.salle.refusPasEncoreOuverte(heure: DepuisSalle.heure(ouverture)),
      ),
      MotifServeurSalle.annulee => (t.salle.refusAcces, t.salle.refusAnnulee),
      MotifServeurSalle.accesPerdu => (
        t.salle.refusAccesPerduTitre,
        t.salle.refusAccesPerdu,
      ),
      // A3-bis (03/11/2026) : le refus dit qui est entre le premier.
      MotifServeurSalle.titulaireEntre => (
        t.a3bis.salle.titulaireEntreTitre,
        t.a3bis.salle.titulaireEntre,
      ),
      MotifServeurSalle.remplacantEntre => (
        t.a3bis.salle.remplacantEntreTitre,
        t.a3bis.salle.remplacantEntre,
      ),
      // SNT (03/11/2026) : la seance n'a pas ete tenue, elle est reportee.
      MotifServeurSalle.seanceReportee => (
        t.snt.salle.reporteeTitre,
        t.snt.salle.reportee,
      ),
      // SITUATIONS-GRAVES (11/11/2026, defaut n° 8) : chaque refus dit sa
      // vraie raison et quoi faire, sans detail d'argent.
      MotifServeurSalle.nonInscrit => (
        t.salle.situations.nonInscritTitre,
        t.salle.situations.nonInscrit,
      ),
      MotifServeurSalle.accesSuspendu => (
        t.salle.situations.accesSuspenduTitre,
        t.salle.situations.accesSuspendu,
      ),
      MotifServeurSalle.sorti => (t.salle.retire, t.salle.retireDetail),
      MotifServeurSalle.observationTerminee => (
        t.salle.situations.observationTermineeTitre,
        t.salle.situations.observationTerminee,
      ),
      MotifServeurSalle.compteInvalide => (
        t.salle.situations.compteInvalideTitre,
        t.salle.situations.compteInvalide,
      ),
      _ => (t.salle.refusAcces, t.salle.refusAccesDetail),
    };
  }

  final Future<void> Function() onReessayer;
  final VoidCallback onRentrer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Une cause, un message, une reparation. Le detail dit ou se trouve la
    // faute : sur l'appareil, dans l'heure, ou chez nous. Sans cela, l'usager
    // cherche toujours de son cote.
    final (String, String) dit = switch (cause) {
      CauseImpasse.materiel when microRefuse => (
        t.salle.situations.microEchecTitre,
        t.salle.situations.microRefuseEntree,
      ),
      CauseImpasse.materiel => (
        t.salle.refusMateriel,
        t.salle.refusMaterielDetail,
      ),
      CauseImpasse.acces => _ditAcces(detail),
      CauseImpasse.configuration => (
        t.salle.refusConfiguration,
        t.salle.refusConfigurationDetail,
      ),
      CauseImpasse.reseau => (t.salle.refusReseau, t.salle.refusReseauDetail),
      // Lot salle 3 (audit reseau du 25/10/2026) : la salle etait ouverte ;
      // « Reessayer » rentre avec un nouveau jeton.
      CauseImpasse.connexionPerdue => (t.salle.perdue, t.salle.secours.echec),
      // 30/10/2026 : « Reessayer » rentre des que l'enseignant a readmis.
      CauseImpasse.retire => (t.salle.retire, t.salle.retireDetail),
      // FERMETURE-SALLE : la seance est finie, le serveur a ferme la salle.
      CauseImpasse.seanceTerminee => (
        t.salle.fermeture.seanceTerminee,
        t.salle.fermeture.seanceTermineeDetail,
      ),
      // UX-038 (K-59) : ce qui s'est passe, et quoi faire.
      CauseImpasse.ouverteAilleurs => (
        t.salle.ouverteAilleurs,
        t.salle.ouverteAilleursDetail,
      ),
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
            if (cause == CauseImpasse.acces)
              if (_mentionAcces(detail) case final String mention) ...<Widget>[
                Ecart.vXs,
                Text(
                  mention,
                  textAlign: TextAlign.center,
                  style: _encreSalle(context, textes.bodySmall),
                ),
              ],
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
    required this.seanceId,
    required this.onEntrer,
    required this.onRetour,
  });

  final String? groupeId;

  /// La seance : la position de reprise se lit par elle (CAHIER-C1), pour
  /// le remplacant qui n'a pas recu la Classe.
  final String seanceId;
  final VoidCallback onEntrer;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> horsLigne = ref.watch(horsLigneProvider);
    final String? groupe = groupeId;
    final PreparationSeance? preparation = groupe == null
        ? null
        : ref.watch(preparationSeanceProvider(groupe));
    // CAHIER-C1 (06/11/2026) : « On reprend page N », lue au serveur par la
    // seance, pour le titulaire comme pour le remplacant.
    final int? pageReprise =
        preparation?.pageReprise ??
        ref.watch(pageRepriseSeanceProvider(seanceId)).value;
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
          reprise:
              preparation?.positionReprise ??
              (pageReprise == null
                  ? null
                  : t.cahierC1.onReprendPage(page: pageReprise)),
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
