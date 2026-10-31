import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observabilite/journal_dev.dart';
import '../tc_horloge/session_clock_vm.dart';
import '../video/livekit_session_provider.dart';
import '../video/pre_vol.dart';
import '../video/service_video.dart';
import '../video/video_session_provider.dart';
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
      other.lienPerdu == lienPerdu;

  @override
  int get hashCode => Object.hash(
    cours,
    enArrierePlan,
    retourDeSuspension,
    materielPret,
    acces,
    refus,
    lienPerdu,
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
/// dans [quitter], atteint seulement par un geste explicite, et dans
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
/// Passage en arriere-plan : rien n'est coupe. La machine de reconnexion du
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
  ControleurSessionPersistante(
    this._moteur,
    this._serviceVideo, {
    this.observeLeCycleDeVie = true,
  }) {
    if (observeLeCycleDeVie) {
      WidgetsBinding.instance.addObserver(this);
    }
    _suiviMoteur = _moteur.etats.listen(_moteurDit);
  }

  StreamSubscription<EtatSalle>? _suiviMoteur;

  final VideoSessionProvider _moteur;
  final ServiceVideo _serviceVideo;

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
  }

  /// Vrai quand l'appel de [sessionId] est ouvert et confie a ce controleur.
  bool tient(String sessionId) => _dejaEnSalle(sessionId);

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
        if (!_etat.lienPerdu) _poser(_etat.avecLien(perdu: true));
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
    final SessionEnCours? cours = _etat.cours;
    // Poser l'etat AVANT les appels reseau : l'interface doit refermer la barre
    // compacte sans attendre le serveur, et un second appui sur « Quitter »
    // pendant l'attente ne doit pas relancer l'annonce.
    _poser(EtatSessionPersistante(enArrierePlan: _etat.enArrierePlan));

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
    final bool suspendu =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
    if (suspendu == _etat.enArrierePlan) {
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
    if (!_sortie.isClosed) {
      _sortie.add(etat);
    }
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
            ref.watch(serviceVideoProvider),
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
