import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../journal_sorties/port_journal_sorties.dart';
import '../observabilite/journal_dev.dart';
import '../tc_horloge/session_clock_vm.dart';
import '../theme/app_delais.dart';
import '../video/diagnostic_transport.dart';
import '../video/ecran_eveille.dart';
import '../video/livekit_session_provider.dart';
import '../video/pre_vol.dart';
import '../video/service_video.dart';
import '../video/video_session_provider.dart';
import 'garde_hors_application.dart';
import 'port_session_persistante.dart';

/// Ce que l'application sait de la classe en cours, a un instant donne.
///
/// **Une seule source, et non une sixieme machine a etats.** Elle porte les
/// trois faits que le moteur ne connait pas -- le materiel inspecte, le jeton
/// obtenu, le refus recu -- et rien de plus. La **phase** d'entree, elle, reste
/// derivee par `VueSalle.depuis`, qui existe deja et qui est testee : la
/// cartographie interdit explicitement d'en ecrire une seconde.
@immutable
class EtatSessionPersistante {
  /// Declare l'etat.
  const EtatSessionPersistante({
    this.cours,
    this.enArrierePlan = false,
    this.retourDeSuspension = false,
    this.materielPret = false,
    this.acces,
    this.refus,
    this.lienPerdu = false,
    this.sortieHorsApplication,
  });

  /// Aucun cours, aucune entree en route.
  static const EtatSessionPersistante aucun = EtatSessionPersistante();

  /// Le cours ouvert. `null` tant que la salle n'est pas rejointe.
  final SessionEnCours? cours;

  /// Vrai quand le systeme a reellement suspendu l'application.
  ///
  /// **Ce n'est pas une deconnexion**, et ce n'est pas non plus affichable :
  /// une application suspendue ne rend aucune image. `SchedulerBinding` coupe
  /// les frames des que l'etat passe a `paused` -- c'est **mesure**, pas
  /// suppose. Ce drapeau sert donc a la logique, jamais a un message ; le
  /// message, lui, se lit au RETOUR, dans [retourDeSuspension].
  final bool enArrierePlan;

  /// Vrai depuis le retour au premier plan, tant que le lien n'est pas reconfirme.
  ///
  /// **C'est lui qui s'affiche**, et c'est le seul honnete : sur mobile, une
  /// suspension longue coupe le reseau sans que le moteur puisse rien y faire.
  /// Afficher « tout va bien » au retour serait promettre une connexion que la
  /// plateforme ne permet pas. Le drapeau tombe quand le moteur redit
  /// `connecte` ou `retabli`, et pas avant.
  final bool retourDeSuspension;

  /// Le pre-vol a rendu un materiel utilisable.
  final bool materielPret;

  /// Le jeton d'entree en cours.
  ///
  /// **Il ne sort pas de la Classe Live.** Le depot a deja tranche : les
  /// capacites se derivent en booleens plutot que d'ouvrir le jeton signe a
  /// toutes les features. Il est ici parce que `VueSalle.depuis` en a besoin, et
  /// parce que c'est lui qui rend l'entree **idempotente** : une salle deja
  /// rejointe ne redemande pas de jeton.
  final AccesSalle? acces;

  /// Le refus du backend, quand il y en a eu un.
  final MotifRefusSalle? refus;

  /// Vrai quand le moteur a perdu le lien et que LiveKit le retablit
  /// (`EtatSalle.reconnexion`) : la barre le dit au lieu de promettre une
  /// seance qui s'entend encore.
  final bool lienPerdu;

  /// HORS-SALLE-1 (directeur, 12/11/2026 au soir) : l'eleve est sorti de la
  /// salle parce qu'il a quitte l'application plus longtemps que le delai
  /// permis. Porte la seance quittee, pour l'ecran du retour
  /// (`IssueSeance.horsApplication`) ; `null` sinon. Retombe des que la salle
  /// l'a lu ([ControleurSessionPersistante.oublierSortieHorsApplication]) ou
  /// a la prochaine entree.
  final SessionEnCours? sortieHorsApplication;

  /// Vrai quand une salle est rejointe pour cette seance.
  bool estOuvertePour(String sessionId) => cours?.sessionId == sessionId;

  /// Le meme etat, avec d'autres drapeaux de suspension.
  EtatSessionPersistante avecSuspension({
    required bool enArrierePlan,
    required bool retourDeSuspension,
  }) => EtatSessionPersistante(
    cours: cours,
    enArrierePlan: enArrierePlan,
    retourDeSuspension: retourDeSuspension,
    materielPret: materielPret,
    acces: acces,
    refus: refus,
    lienPerdu: lienPerdu,
    sortieHorsApplication: sortieHorsApplication,
  );

  /// Le meme etat, avec un autre lien.
  EtatSessionPersistante avecLien({required bool perdu}) =>
      EtatSessionPersistante(
        cours: cours,
        enArrierePlan: enArrierePlan,
        retourDeSuspension: retourDeSuspension,
        materielPret: materielPret,
        acces: acces,
        refus: refus,
        lienPerdu: perdu,
        sortieHorsApplication: sortieHorsApplication,
      );

  @override
  bool operator ==(Object other) =>
      other is EtatSessionPersistante &&
      other.cours == cours &&
      other.enArrierePlan == enArrierePlan &&
      other.retourDeSuspension == retourDeSuspension &&
      other.materielPret == materielPret &&
      identical(other.acces, acces) &&
      other.refus == refus &&
      other.lienPerdu == lienPerdu &&
      other.sortieHorsApplication == sortieHorsApplication;

  @override
  int get hashCode => Object.hash(
    cours,
    enArrierePlan,
    retourDeSuspension,
    materielPret,
    acces,
    refus,
    lienPerdu,
    sortieHorsApplication,
  );
}

/// Le proprietaire **applicatif** du cycle de vie de la salle.
///
/// **C'est le deuxieme invariant du lot** (spec section 9.4, decision D-24).
/// Le controleur de room ne vit pas dans le widget de la page Classe : il vit
/// ici, au niveau de l'application, aussi longtemps que le conteneur Riverpod.
/// Retourner au Groupe, a l'Accueil ou ouvrir la Bibliotheque demonte un ecran ;
/// cela **ne doit pas** couper un cours.
///
/// Le socle etait deja bon : `moteurSalleProvider` est un Provider **racine**,
/// donc unique pour l'application et non attache a un ecran. Ce qui manquait
/// etait quelqu'un pour dire quand on entre et quand on sort. Personne ne le
/// disait, alors `_SallePageEtat.dispose()` le disait a sa place -- ce qui
/// revient a couper le cours des qu'on regarde ailleurs.
///
/// **Ce controleur n'appelle `quitter()` sur le moteur qu'en deux endroits** :
/// dans [_quitter], atteint par un geste explicite ([quitter]) ou, pour
/// l'eleve seulement, apres une absence hors de l'application plus longue
/// que le delai permis (HORS-SALLE-1, [_sortirHorsApplication]), et dans
/// [_fermerApresFin], quand le moteur dit que l'appel est deja fini (seance
/// close par le serveur, lien perdu pour de bon, participant retire) : il ne
/// reste alors qu'a liberer le micro. C'est verifiable d'un `grep` sur ce
/// fichier.
///
/// Branche a `/salle` le 31/10/2026 (directeur : l'enseignant quitte l'ecran
/// de la salle et continue d'entendre l'eleve, comme dans un appel) : la
/// salle entre par son propre chemin (pre-vol selon le role, jeton de
/// l'eleve D6), puis confie l'appel ouvert a ce controleur par [adopter].
/// La barre « Seance toujours en direct » (`BarreSeanceEnDirect`) le lit sur
/// tous les autres ecrans.
///
/// Passage en arriere-plan : rien n'est coupe chez qui modere la seance.
/// Chez l'eleve, depuis le 12/11/2026 (HORS-SALLE-1, directeur), un court
/// delai sans coupure, puis la sortie de la salle ([GardeHorsApplication]).
/// La machine de reconnexion du
/// moteur existe deja (`EtatSalle.reconnexion`, `retabli`, `echec`), et c'est
/// elle qui decide. L'ecran lit [EtatSessionPersistante.enArrierePlan] pour **ne
/// pas promettre** une connexion que la plateforme ne permet pas quand le
/// systeme a reellement suspendu le processus.
class ControleurSessionPersistante
    with WidgetsBindingObserver
    implements PortSessionPersistante {
  /// Cree le controleur et s'abonne au cycle de vie de l'application.
  /// Les deux dependances sont **positionnelles et privees** : le moteur et le
  /// service video restent enfermes ici. Les exposer en champs publics
  /// donnerait a n'importe quel appelant un `moteur.quitter()` a portee de main,
  /// et l'invariant « un seul endroit quitte la salle » ne serait plus
  /// verifiable d'un `grep` sur ce fichier.
  ///
  /// [ecranEveille] : le gardien de l'ecran allume (ECRAN-EVEILLE) ; celui
  /// de la plateforme par defaut, un double dans les tests.
  ///
  /// HORS-SALLE-1 : [delaiHorsApplication] et [coupureSuspendue] sont lus a
  /// chaque absence (`delaiHorsApplicationProvider`,
  /// `coupureSuspendueProvider`) ; [maintenant] et [minuterie] sont l'horloge
  /// et la minuterie de la garde (doubles dans les tests) ; [signalerAbsence]
  /// recoit les traces de l'enseignant (`signalerAbsencePage` par defaut).
  ///
  /// HORS-SALLE-2 : [noterSortieApp] note une absence de l'eleve a son
  /// retour (le port du journal des sorties ; le serveur n'ecrit qu'avec un
  /// accord) ; rien par defaut.
  ControleurSessionPersistante(
    this._moteur,
    this._serviceVideo, {
    this.observeLeCycleDeVie = true,
    EcranEveille? ecranEveille,
    Duration Function()? delaiHorsApplication,
    bool Function()? coupureSuspendue,
    DateTime Function()? maintenant,
    Timer Function(Duration, void Function())? minuterie,
    void Function(String evenement, Map<String, Object?> donnees)?
    signalerAbsence,
    this.noterSortieApp,
  }) : _ecran = ecranEveille ?? EcranEveille.dePlateforme() {
    _garde = GardeHorsApplication(
      regle: _regleHorsApplication,
      sortir: _sortirHorsApplication,
      delai: delaiHorsApplication ?? () => AppDelais.horsApplicationEleve,
      coupureSuspendue: coupureSuspendue ?? () => false,
      // Le nom opaque de la salle seulement, jamais une identite.
      signaler: (String evenement, Map<String, Object?> donnees) =>
          (signalerAbsence ?? signalerAbsencePage)(evenement, <String, Object?>{
            'salle': _moteur.accesCourant?.nomSalle ?? _etat.acces?.nomSalle,
            ...donnees,
          }),
      etatConnexion: () => _moteur.etatCourant.name,
      reprises: () => _reprises,
      sonBloque: () => switch (_moteur) {
        final SonRecuBloque son => son.sonBloque,
        _ => false,
      },
      noter: _noterSortie,
      maintenant: maintenant,
      minuterie: minuterie,
    );
    if (observeLeCycleDeVie) {
      WidgetsBinding.instance.addObserver(this);
    }
    _suiviMoteur = _moteur.etats.listen(_moteurDit);
  }

  /// HORS-SALLE-1 : ce qui se passe quand la page est cachee pendant un
  /// appel tenu ([GardeHorsApplication]).
  late final GardeHorsApplication _garde;

  /// HORS-SALLE-2 : note une absence de l'eleve au journal des sorties.
  final Future<bool> Function({
    required String seanceId,
    required int secondes,
    required bool sortieSalle,
    String? eleveId,
  })?
  noterSortieApp;

  /// HORS-SALLE-2 : la seance tenue quand la page a ete cachee (apres une
  /// sortie de la salle, l'etat ne la porte plus).
  SessionEnCours? _coursCache;

  /// HORS-SALLE-2 : au retour de l'eleve, la duree mesuree par l'horloge part
  /// au port ; rien ne s'affiche, quoi que le serveur reponde.
  void _noterSortie(Duration absence, bool sortieSalle) {
    final SessionEnCours? cours = _coursCache;
    final noter = noterSortieApp;
    if (cours == null || noter == null) return;
    unawaited(
      noter(
        seanceId: cours.sessionId,
        secondes: absence.inSeconds,
        sortieSalle: sortieSalle,
        eleveId: cours.eleveId,
      ),
    );
  }

  /// HORS-SALLE-1 : les reprises de la connexion depuis le debut (chaque
  /// passage a `reconnexion`), pour les traces de l'enseignant.
  int _reprises = 0;

  /// HORS-SALLE-1 : la regle de l'appel tenu, lue sur les capacites signees
  /// par le serveur (jamais sur un role).
  RegleHorsApplication _regleHorsApplication() {
    final AccesSalle? acces = _moteur.accesCourant ?? _etat.acces;
    return regleHorsApplication(
      appelTenu: _etat.cours != null && _etat.acces != null,
      peutModerer: acces?.capacites.peutModerer ?? false,
      peutPublier: acces?.capacites.peutPublier ?? false,
      publicationDifferee: acces?.publicationDifferee ?? false,
      invisible: acces?.capacites.invisible ?? false,
    );
  }

  /// HORS-SALLE-1 : l'eleve a quitte l'application trop longtemps. Le meme
  /// chemin que « Quitter » (annonce, puis deconnexion) ; l'etat garde la
  /// seance quittee pour l'ecran du retour.
  Future<void> _sortirHorsApplication() async {
    final SessionEnCours? cours = _etat.cours;
    if (cours == null) return;
    await _quitter(horsApplication: cours);
  }

  /// HORS-SALLE-1 : la salle a lu la sortie et montre l'ecran du retour.
  void oublierSortieHorsApplication() {
    if (_etat.sortieHorsApplication == null) return;
    _poser(
      EtatSessionPersistante(
        cours: _etat.cours,
        enArrierePlan: _etat.enArrierePlan,
        retourDeSuspension: _etat.retourDeSuspension,
        materielPret: _etat.materielPret,
        acces: _etat.acces,
        refus: _etat.refus,
        lienPerdu: _etat.lienPerdu,
      ),
    );
  }

  StreamSubscription<EtatSalle>? _suiviMoteur;

  final VideoSessionProvider _moteur;
  final ServiceVideo _serviceVideo;

  /// L'ecran reste allume tant qu'un appel est confie (ECRAN-EVEILLE).
  final EcranEveille _ecran;

  /// Vrai tant que l'application est visible (ni onglet cache, ni ecran
  /// eteint, ni suspendue).
  bool _visible = true;

  /// Vrai quand le controleur ecoute le cycle de vie de l'application.
  ///
  /// Faux dans les tests qui n'ont pas de liaison de widgets : `addObserver`
  /// exigerait une instance de `WidgetsBinding`, et un test purement Dart n'en
  /// a pas.
  final bool observeLeCycleDeVie;

  /// Diffusion : plusieurs surfaces ecoutent le meme cours -- la barre compacte,
  /// l'en-tete de la Classe Live, et la page de Groupe.
  final StreamController<EtatSessionPersistante> _sortie =
      StreamController<EtatSessionPersistante>.broadcast();

  EtatSessionPersistante _etat = EtatSessionPersistante.aucun;
  bool _ouvertureEnCours = false;

  /// L'etat courant, sans passer par un `Future`.
  ///
  /// Le contrat expose [courante] en asynchrone ; une barre compacte qui se
  /// reconstruit a chaque image a besoin d'une lecture immediate, sans quoi
  /// elle clignoterait a chaque reconstruction.
  EtatSessionPersistante get etatCourant => _etat;

  /// L'etat, a chaque changement.
  Stream<EtatSessionPersistante> get etats => _sortie.stream;

  @override
  Stream<SessionEnCours?> suivre() =>
      _sortie.stream.map((EtatSessionPersistante e) => e.cours);

  @override
  Future<SessionEnCours?> courante() async => _etat.cours;

  /// Ouvre la salle : materiel, jeton, connexion. **Idempotent.**
  ///
  /// Les trois temps, et leur ordre n'est pas une preference : une salle qui
  /// echoue apres etre entree laisse tout le groupe dedans, dont l'un est muet
  /// sans savoir pourquoi. Verifier le micro pendant qu'on est encore seul
  /// devant son ecran coute une seconde et evite cela.
  ///
  /// **Un second appel pour la meme seance ne fait rien**, et c'est ce qui rend
  /// le retour depuis la barre « Seance toujours en direct » instantane : on ne redemande
  /// pas de jeton, et surtout on ne rejoint pas une seconde fois -- ce serait
  /// une seconde `Room`, donc exactement ce que le socle interdit.
  ///
  /// [preVol] est passe en parametre plutot que lu ici : `preVolProvider` garde
  /// sa valeur en cache, et c'est l'appelant qui sait s'il faut remesurer -- un
  /// casque branche entre deux essais ne compterait pas autrement.
  Future<void> ouvrir({
    required SessionEnCours cours,
    required Future<ResultatPreVol> Function() preVol,
  }) async {
    if (_ouvertureEnCours || _dejaEnSalle(cours.sessionId)) {
      return;
    }
    _ouvertureEnCours = true;
    try {
      _poser(EtatSessionPersistante(enArrierePlan: _etat.enArrierePlan));

      final ResultatPreVol materiel = await preVol();
      if (!materiel.peutEntrer) {
        // Aucun refus de backend : l'impasse est materielle, et l'appelant la
        // lit dans le pre-vol lui-meme. Poser ici un `MotifRefusSalle` ferait
        // dire au backend une chose qu'il n'a pas dite.
        _poser(EtatSessionPersistante(enArrierePlan: _etat.enArrierePlan));
        return;
      }
      _poser(
        EtatSessionPersistante(
          enArrierePlan: _etat.enArrierePlan,
          materielPret: true,
        ),
      );

      final AccesSalle acces;
      try {
        acces = await _serviceVideo.acces(cours.sessionId);
      } on EchecSalle catch (echec) {
        _poser(
          EtatSessionPersistante(
            enArrierePlan: _etat.enArrierePlan,
            materielPret: true,
            refus: echec.motif,
          ),
        );
        return;
      }
      _poser(
        EtatSessionPersistante(
          enArrierePlan: _etat.enArrierePlan,
          materielPret: true,
          acces: acces,
        ),
      );

      try {
        await _moteur.rejoindre(acces);
      } catch (erreur) {
        // Le moteur a deja pose son etat d'echec et tout libere ; il ne reste
        // qu'a nommer la cause. Aucun detail technique ne remonte a l'ecran :
        // « ICE failed » ne se lit pas devant un enfant.
        journalDev('entree en Classe Live impossible : $erreur');
        _poser(
          EtatSessionPersistante(
            enArrierePlan: _etat.enArrierePlan,
            materielPret: true,
            acces: acces,
            refus: MotifRefusSalle.reseau,
          ),
        );
        return;
      }

      adopter(cours: cours, acces: acces);
    } finally {
      _ouvertureEnCours = false;
    }
  }

  /// Prend en charge un appel que la salle vient d'ouvrir elle-meme.
  ///
  /// La salle a son propre chemin d'entree (pre-vol selon le role, jeton de
  /// l'eleve qui rejoint depuis l'appareil de son tuteur) : le recopier ici
  /// ferait deux entrees qui divergeraient. Elle rejoint, puis confie l'appel.
  /// Des cet instant, quitter l'ecran de la salle ne coupe plus rien.
  void adopter({required SessionEnCours cours, required AccesSalle acces}) {
    _poser(
      EtatSessionPersistante(
        cours: cours,
        enArrierePlan: _etat.enArrierePlan,
        materielPret: true,
        acces: acces,
        lienPerdu: _moteur.etatCourant == EtatSalle.reconnexion,
      ),
    );
    // HORS-SALLE-2 : lit le delai de la direction des l'entree, pour que la
    // premiere absence l'applique deja (la constante tant qu'il n'est pas lu).
    _garde.delai();
  }

  /// Vrai quand l'appel de [sessionId] est ouvert et confie a ce controleur.
  bool tient(String sessionId) => _dejaEnSalle(sessionId);

  /// Vrai quand ce controleur pilote [moteur].
  ///
  /// Une demonstration ou un test qui surcharge le moteur dans une portee
  /// imbriquee a un autre moteur que ce controleur racine : la salle ne lui
  /// confie alors rien, et garde son ancienne regle (l'ecran ferme l'appel).
  bool pilote(VideoSessionProvider moteur) => identical(moteur, _moteur);

  /// Ce que dit le moteur, tant qu'un appel est confie.
  ///
  /// **Un seul abonnement, ici, pour toute l'application** : quand l'ecran
  /// de la salle n'est plus monte, personne d'autre n'ecoute le moteur, et
  /// la barre doit pourtant se fermer quand l'appel finit.
  void _moteurDit(EtatSalle etat) {
    if (_etat.cours == null) {
      return;
    }
    switch (etat) {
      case EtatSalle.connecte || EtatSalle.retabli:
        confirmerLien();
        if (_etat.lienPerdu) _poser(_etat.avecLien(perdu: false));
      case EtatSalle.instable:
        if (_etat.lienPerdu) _poser(_etat.avecLien(perdu: false));
      case EtatSalle.reconnexion:
        if (!_etat.lienPerdu) {
          _reprises++;
          _poser(_etat.avecLien(perdu: true));
        }
      case EtatSalle.echec || EtatSalle.retire:
        unawaited(_fermerApresFin());
      // `absent` ne vient que de nos propres `quitter()` (le moteur cesse
      // d'ecouter la salle avant de la fermer) : une nouvelle entree, ou
      // une sortie deja faite ici. `connexion` precede `connecte`.
      case EtatSalle.absent || EtatSalle.connexion:
        break;
    }
  }

  /// L'appel est fini sans geste de l'usager : la barre se ferme, et le
  /// micro est libere. Aucune annonce de sortie : elle n'a pas ete voulue.
  Future<void> _fermerApresFin() async {
    _garde.annuler();
    _poser(EtatSessionPersistante(enArrierePlan: _etat.enArrierePlan));
    await _moteur.quitter();
  }

  bool _dejaEnSalle(String sessionId) =>
      _etat.estOuvertePour(sessionId) && _etat.acces != null;

  /// Met a jour l'horloge du cours ouvert, sans changer de cours.
  ///
  /// Ignore une mise a jour qui designerait une autre seance : la barre suivrait
  /// alors un cours qu'on n'a pas rejoint.
  void rafraichirHorloge(String sessionId, SessionClockVM? horloge) {
    final SessionEnCours? cours = _etat.cours;
    if (cours == null || cours.sessionId != sessionId) {
      return;
    }
    if (cours.horloge == horloge) {
      return;
    }
    _poser(
      EtatSessionPersistante(
        cours: cours.avecHorloge(horloge),
        enArrierePlan: _etat.enArrierePlan,
        materielPret: _etat.materielPret,
        acces: _etat.acces,
        refus: _etat.refus,
        lienPerdu: _etat.lienPerdu,
      ),
    );
  }

  @override
  Future<void> quitter() async {
    // HORS-SALLE-1 : une sortie voulue pendant le delai de l'eleve hors de
    // l'application : plus rien a couper, une seule sortie.
    _garde.annuler();
    await _quitter();
  }

  /// La sortie, voulue ([quitter]) ou apres une absence trop longue de
  /// l'eleve ([horsApplication], la seance quittee).
  Future<void> _quitter({SessionEnCours? horsApplication}) async {
    final SessionEnCours? cours = _etat.cours;
    // Poser l'etat AVANT les appels reseau : l'interface doit refermer la barre
    // compacte sans attendre le serveur, et un second appui sur « Quitter »
    // pendant l'attente ne doit pas relancer l'annonce.
    _poser(
      EtatSessionPersistante(
        enArrierePlan: _etat.enArrierePlan,
        sortieHorsApplication: horsApplication,
      ),
    );

    if (cours != null) {
      // **L'annonce precede la deconnexion.** LiveKit emet le meme evenement
      // `left` dans les deux cas ; seule cette ecriture distingue une sortie
      // volontaire d'une perte de reseau, et le webhook la deduplique dans une
      // fenetre de 30 secondes. Annoncer apres laisserait le webhook arriver le
      // premier et inscrire une deconnexion.
      await _serviceVideo.annoncerSortie(cours.sessionId);
    }
    await _moteur.quitter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ECRAN-EVEILLE (11/11/2026) : dans un navigateur, Flutter ne dit jamais
    // `paused` ; un onglet cache ou un ecran eteint arrive en `hidden`
    // (moteur web : `visibilitychange`). Le moteur l'apprend pour reprendre
    // l'appel au retour, sans geste. `inactive` (fenetre sans le focus) n'est
    // pas un arriere-plan : la page reste visible.
    final bool visible =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (visible != _visible) {
      _visible = visible;
      if (_moteur case final RepriseAutomatique moteur) {
        moteur.premierPlan(visible: visible);
      }
      // HORS-SALLE-1 (directeur, 12/11/2026 au soir) : l'enseignant n'est
      // jamais coupe ; l'eleve a un court delai, puis il sort de la salle.
      if (visible) {
        unawaited(_garde.revenue());
      } else {
        _coursCache = _etat.cours;
        _garde.cachee();
      }
    }
    final bool suspendu =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
    if (suspendu == _etat.enArrierePlan) {
      return;
    }
    if (!suspendu && _lienVivant(_moteur.etatCourant)) {
      // Constat du 11/11/2026 : au retour, si le moteur n'avait jamais perdu
      // le lien, aucun `connecte` ni `retabli` ne venait faire tomber le
      // doute, et le message du retour restait affiche pour rien. Le moteur
      // dit deja que le lien est la : on le croit. S'il est mort sans que le
      // moteur le sache encore, `reconnexion` suivra et la barre le dira.
      _poser(
        _etat.avecSuspension(enArrierePlan: false, retourDeSuspension: false),
      );
      return;
    }
    // **Rien n'est coupe ici, et c'est le coeur de l'invariant.** Un `quitter()`
    // pose sur `paused` fermerait le cours a chaque appel telephonique recu. La
    // machine de reconnexion du moteur fait deja ce qui peut l'etre ; ce
    // controleur ne fait que le dire.
    //
    // Au RETOUR, le doute reste : [EtatSessionPersistante.retourDeSuspension]
    // tient jusqu'a ce que le moteur redise que le lien est la. Rien ne
    // s'affiche pendant la suspension elle-meme -- une application suspendue ne
    // rend aucune image.
    _poser(
      _etat.avecSuspension(
        enArrierePlan: suspendu,
        // Pose des la suspension, et **tenu au retour** : c'est au retour qu'il
        // se lit, puisque rien ne se rend pendant la suspension.
        retourDeSuspension: suspendu || _etat.retourDeSuspension,
      ),
    );
  }

  /// Le moteur a reconfirme le lien : le doute du retour tombe.
  ///
  /// Appele par [_moteurDit] quand `EtatSalle.connecte` ou
  /// `EtatSalle.retabli` arrive pour un appel confie.
  void confirmerLien() {
    if (!_etat.retourDeSuspension) {
      return;
    }
    _poser(
      _etat.avecSuspension(
        enArrierePlan: _etat.enArrierePlan,
        retourDeSuspension: false,
      ),
    );
  }

  void _poser(EtatSessionPersistante etat) {
    _etat = etat;
    _suivreLAppel(etat.cours);
    if (!_sortie.isClosed) {
      _sortie.add(etat);
    }
  }

  /// Vrai quand le moteur tient le lien (`instable` compris : le son passe).
  static bool _lienVivant(EtatSalle etat) =>
      etat == EtatSalle.connecte ||
      etat == EtatSalle.retabli ||
      etat == EtatSalle.instable;

  /// ECRAN-EVEILLE (directeur, 11/11/2026) : tant qu'un appel est confie, et
  /// **seulement** tant qu'il l'est, l'ecran reste allume et le moteur sait
  /// d'ou tirer un jeton neuf pour une reprise sans geste. Un seul endroit,
  /// ici, parce que chaque changement d'etat y passe : entree ([adopter]),
  /// sortie voulue ([quitter]), fin de l'appel ([_fermerApresFin]). La salle
  /// reduite continue de tenir l'appel, donc l'ecran.
  void _suivreLAppel(SessionEnCours? cours) {
    final RepriseAutomatique? moteur = switch (_moteur) {
      final RepriseAutomatique r => r,
      _ => null,
    };
    if (cours == null) {
      _ecran.rendre();
      moteur?.sourceJeton = null;
      return;
    }
    _ecran.tenir();
    moteur?.sourceJeton = () =>
        _serviceVideo.acces(cours.sessionId, eleveId: cours.eleveId);
  }

  /// Libere le controleur. **Ne quitte pas la salle.**
  ///
  /// Appele quand le conteneur Riverpod entier se defait, c'est-a-dire quand
  /// l'application se ferme : le moteur, lui, est libere par son propre
  /// `onDispose` dans `moteurSalleProvider`.
  void liberer() {
    if (observeLeCycleDeVie) {
      WidgetsBinding.instance.removeObserver(this);
    }
    unawaited(_suiviMoteur?.cancel());
    _suiviMoteur = null;
    _garde.liberer();
    _ecran.rendre();
    unawaited(_sortie.close());
  }
}

/// Le proprietaire de la seance en direct, pour toute l'application.
///
/// **Un seul, racine, comme `moteurSalleProvider`.** Deux controleurs donneraient
/// deux barres « Seance toujours en direct » qui se contrediraient.
final Provider<ControleurSessionPersistante> controleurSessionProvider =
    Provider<ControleurSessionPersistante>((Ref ref) {
      final ControleurSessionPersistante controleur =
          ControleurSessionPersistante(
            ref.watch(moteurSalleProvider),
            // Lu au moment d'ouvrir ou de quitter, jamais a la construction :
            // la barre lit ce controleur sur tous les ecrans, et le service
            // video reel ouvre Supabase (31/10/2026).
            _ServiceVideoDiffere(() => ref.read(serviceVideoProvider)),
            // HORS-SALLE-1 : lus a chaque absence, pour qu'un reglage de la
            // direction s'applique sans recreer le controleur.
            delaiHorsApplication: () => ref.read(delaiHorsApplicationProvider),
            coupureSuspendue: () => ref.read(coupureSuspendueProvider),
            // HORS-SALLE-2 : le journal des sorties, lu au moment de noter.
            noterSortieApp:
                ({
                  required String seanceId,
                  required int secondes,
                  required bool sortieSalle,
                  String? eleveId,
                }) => ref
                    .read(portJournalSortiesProvider)
                    .noterSortie(
                      seanceId: seanceId,
                      secondes: secondes,
                      sortieSalle: sortieSalle,
                      eleveId: eleveId,
                    ),
          );
      ref.onDispose(controleur.liberer);
      return controleur;
    });

/// Le port, pour qui n'a pas besoin des commandes du controleur.
final Provider<PortSessionPersistante> portSessionPersistanteProvider =
    Provider<PortSessionPersistante>(
      (Ref ref) => ref.watch(controleurSessionProvider),
    );

/// L'etat de la classe en cours, observe.
///
/// L'etat courant, **puis** le flux : le meme motif que `contenusPresentes` dans
/// `video_session_provider.dart`. Une barre qui se remonte au milieu d'un cours
/// -- rotation, retour de veille, changement d'ecran -- doit reapparaitre sans
/// attendre le prochain changement.
final StreamProvider<EtatSessionPersistante> etatSessionProvider =
    StreamProvider<EtatSessionPersistante>(
      (Ref ref) => _avecCourant(ref.watch(controleurSessionProvider)),
    );

Stream<EtatSessionPersistante> _avecCourant(
  ControleurSessionPersistante controleur,
) async* {
  yield controleur.etatCourant;
  yield* controleur.etats;
}

/// Le service video, resolu a chaque appel plutot qu'a la construction.
class _ServiceVideoDiffere implements ServiceVideo {
  _ServiceVideoDiffere(this._lire);

  final ServiceVideo Function() _lire;

  @override
  Future<AccesSalle> acces(String seanceId, {String? eleveId}) =>
      _lire().acces(seanceId, eleveId: eleveId);

  @override
  Future<void> observerEnControle(String seanceId) =>
      _lire().observerEnControle(seanceId);

  @override
  Future<void> annoncerSortie(String seanceId) =>
      _lire().annoncerSortie(seanceId);
}
