import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enseignant/modeles_enseignant.dart' show SeanceEnseignant;
import '../../core/enseignant/service_enseignant.dart'
    show seancesEnseignantProvider;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/tc_horloge/chrono_seance.dart' show BornesChrono;
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/signal_rappel.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pressable.dart';
import 'bornes_salle.dart';
import 'chrono_salle.dart';
import 'marque_chrono.dart';
import 'pilote_dynamique.dart';
import 'relais_salle.dart';
import 'vue_seance.dart' show ConnexionSeance;

/// La barre « Seance toujours en direct » (directeur, 31/10/2026).
///
/// Pendant une seance, l'enseignant (et tout role qui atteint `/salle`) quitte
/// l'ecran de la salle et fait autre chose dans l'application, en continuant
/// d'entendre la classe, comme dans un appel. L'appel est tenu par
/// `controleurSessionProvider` ; cette barre le montre sur **tous les autres
/// ecrans**, au-dessus de la page, et ramene a la salle d'un appui, dans le
/// meme appel (le controleur le tient : ni jeton, ni reconnexion).
///
/// Elle lit des capacites, jamais un role : le micro n'y figure que si le
/// jeton permet de parler (`peutPublier`).
///
/// Etats : chargement et erreur du flux ne montrent rien (on ne pretend pas
/// a une seance qu'on ne connait pas ; l'erreur est journalisee) ; aucune
/// seance, rien ; seance en direct, la pastille ; lien perdu ou retour de
/// veille non reconfirme, la phrase de reconnexion de la salle.
///
/// Elle **compose** [child] : quand elle est visible, elle prend la marge du
/// haut de l'appareil (encoche), et la page dessous ne la reprend pas.
///
/// **La structure ne change jamais**, barre visible ou non : une colonne,
/// une place pour la barre, la page. Basculer entre « la page seule » et
/// « la barre et la page » remonterait le Navigator entier, et la pile de
/// l'application avec. Elle porte aussi son propre `Overlay` : posee
/// au-dessus du Navigator, l'infobulle de son micro n'en aurait aucun.
class BarreSeanceEnDirect extends StatefulWidget {
  /// Cree la barre au-dessus de [child].
  const BarreSeanceEnDirect({
    required this.routeur,
    required this.child,
    super.key,
  });

  /// Le routeur de l'application : la barre se cache sur `/salle`, et y mene.
  final GoRouter routeur;

  /// L'ile (tests, captures).
  static const Key cleIle = ValueKey<String>('ile-seance-hors-salle');

  /// La pastille et le chrono, qui ramenent a la salle.
  static const Key cleRetour = ValueKey<String>('ile-seance-retour');

  /// DYNAMIQUE-CHRONO-2 : l'alerte de l'ile (appel recu, pause).
  static const Key cleAlerte = ValueKey<String>('ile-seance-alerte');

  /// Le chevron qui deplie ou replie l'ile.
  static const Key cleChevron = ValueKey<String>('ile-seance-chevron');

  /// Le detail de l'ile depliee.
  static const Key cleDetail = ValueKey<String>('ile-seance-detail');

  /// Le micro de l'ile.
  static const Key cleMicro = ValueKey<String>('ile-seance-micro');

  /// Le chrono de l'ile.
  static const Key cleChrono = ValueKey<String>('ile-seance-chrono');

  /// La page courante.
  final Widget child;

  @override
  State<BarreSeanceEnDirect> createState() => _BarreSeanceEnDirectEtat();
}

class _BarreSeanceEnDirectEtat extends State<BarreSeanceEnDirect> {
  late final OverlayEntry _entree = OverlayEntry(
    builder: (BuildContext _) =>
        _Colonne(routeur: widget.routeur, child: widget.child),
  );

  @override
  void didUpdateWidget(BarreSeanceEnDirect ancien) {
    super.didUpdateWidget(ancien);
    _entree.markNeedsBuild();
  }

  @override
  void dispose() {
    _entree
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entree]);
}

class _Colonne extends ConsumerStatefulWidget {
  const _Colonne({required this.routeur, required this.child});

  final GoRouter routeur;
  final Widget child;

  @override
  ConsumerState<_Colonne> createState() => _ColonneEtat();
}

class _ColonneEtat extends ConsumerState<_Colonne> {
  /// La hauteur que l'ile REPLIEE reserve en haut de la page, mesuree sur sa
  /// rangee compacte. Directeur, 11/11/2026 : depliee, l'ile se pose SUR la
  /// page, elle ne la pousse ni ne la reduit ; seule sa forme repliee, qui
  /// reste, garde sa place (rien ne recouvre en permanence un contenu a lire).
  double? _bande;

  void _noterBande(double hauteur) {
    if (!mounted || (_bande != null && (hauteur - _bande!).abs() < 0.5)) {
      return;
    }
    setState(() => _bande = hauteur);
  }

  @override
  void initState() {
    super.initState();
    widget.routeur.routerDelegate.addListener(_routeChangee);
  }

  @override
  void didUpdateWidget(_Colonne ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.routeur, widget.routeur)) {
      ancien.routeur.routerDelegate.removeListener(_routeChangee);
      widget.routeur.routerDelegate.addListener(_routeChangee);
    }
  }

  @override
  void dispose() {
    widget.routeur.routerDelegate.removeListener(_routeChangee);
    super.dispose();
  }

  /// Le routeur notifie aussi pendant le premier rendu du Router, qui est
  /// sous cette barre : la reconstruction attend alors la fin de l'image.
  void _routeChangee() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter routeur = widget.routeur;
    final AsyncValue<EtatSessionPersistante> lecture = ref.watch(
      etatSessionProvider,
    );
    if (lecture.hasError) {
      journalDev('barre de seance : ${lecture.error}');
    }
    final EtatSessionPersistante? etat = lecture.value;
    final SessionEnCours? cours = etat?.cours;
    final bool visible =
        etat != null && cours != null && !_dansLaSalle(routeur);
    // La place de l'ile repliee, avant sa premiere mesure : la zone sure, les
    // marges de la bande et une cible tactile.
    final double bande =
        _bande ??
        MediaQuery.paddingOf(context).top +
            2 * AppSpacing.sm +
            2 * AppSpacing.xs +
            AppTouchTarget.standard;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: visible ? bande : 0),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: visible,
              child: widget.child,
            ),
          ),
        ),
        if (visible)
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            // TRANSITIONS-SALLE (11/11/2026) : la salle reduite se replie
            // dans l'ile, qui arrive en se resserrant vers sa place en haut
            // de l'ecran ; « Retourner dans la salle » la redeplie
            // (`PassageSalle`, `FaconPassage.depuisIle`).
            child: _RepliVersIle(
              child: _Barre(
                etat: etat,
                cours: cours,
                bande: bande,
                onBande: _noterBande,
                onRetour: () => routeur.go(
                  Routes.salle,
                  // Un billet neuf : celui de l'entree a pu expirer pendant la
                  // seance (ADR-005), l'appel, lui, continue.
                  extra: BilletSalle(
                    sessionId: cours.sessionId,
                    emisA: DateTime.now(),
                    groupeId: cours.groupeId.isEmpty ? null : cours.groupeId,
                    eleveId: cours.eleveId,
                    interfaceGuidee: cours.interfaceGuidee,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// TRANSITIONS-SALLE : l'arrivee de l'ile quand la salle se reduit. Elle
/// part un peu plus grande ([AppMouvement.echelleVersIle] inverse), comme la
/// salle qui se resserre, et se pose a sa place sur le ressort sans rebond,
/// en apparaissant. Une fois, a l'arrivee ; un fondu seul en mouvement
/// reduit. Elle recoit les gestes des la premiere image.
class _RepliVersIle extends StatefulWidget {
  const _RepliVersIle({required this.child});

  final Widget child;

  @override
  State<_RepliVersIle> createState() => _EtatRepliVersIle();
}

class _EtatRepliVersIle extends State<_RepliVersIle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMouvement.deplacementEntree,
  );
  bool _parti = false;
  bool _reduit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parti) return;
    _parti = true;
    _reduit = AppMouvement.mouvementReduit(context);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (BuildContext context, Widget? enfant) {
      final double v = _c.value;
      final double echelle = _reduit
          ? 1
          : 1 / AppMouvement.echelleVersIle -
                (1 / AppMouvement.echelleVersIle - 1) *
                    AppMouvement.ressortDeplacement.transform(v);
      return Opacity(
        opacity: AppMouvement.courbeFondu.transform(v),
        child: Transform.scale(
          scale: echelle,
          alignment: Alignment.topCenter,
          child: enfant,
        ),
      );
    },
  );
}

/// UX-011 (31/10/2026) : la page affichee est-elle la salle ?
///
/// Lue sur la route du dessus de la pile, jamais sur l'adresse seule : le
/// tuteur entre par `push` (« Rejoindre la salle avec … »), et go_router
/// garde alors l'adresse de l'ecran d'en dessous. La barre proposait de
/// « Retourner dans la salle » a qui y etait deja.
bool _dansLaSalle(GoRouter routeur) {
  final RouteMatchList pile = routeur.routerDelegate.currentConfiguration;
  final String chemin = pile.lastOrNull?.matchedLocation ?? pile.uri.path;
  return Uri.parse(chemin).path == Routes.salle ||
      pile.uri.path == Routes.salle;
}

/// ILE-SALLE (directeur, 11/11/2026 : « pense a la Dynamic Island de Apple
/// pour que la pilule donne les meilleures informations [...] lorsqu'on
/// reduit la classe et qu'on sort, mais que la session continue ») : la barre
/// devient une ile a deux formes, avec les memes capacites qu'avant, jamais
/// plus de droits.
///
/// - **Compacte** (toujours visible, au-dessus de la page, sans la
///   recouvrir) : la pastille « Seance toujours en direct », le temps
///   restant (le chrono de la salle, sobre chez qui ne conduit pas la
///   seance), le micro si le jeton permet de parler ; un appui sur la
///   pastille ramene a la salle.
/// - **Depliee** (chevron, au clavier comme au doigt ; aucun appui long) : le
///   nom de la Classe, l'etat qui se dit (reconnexion, cinq dernieres
///   minutes, fin prevue atteinte), le mot du micro, « Retourner dans la
///   salle ».
/// - Elle se deplie **d'elle-meme** quand le lien est perdu (et revient
///   compacte quand il revient), et, chez qui conduit la seance, pour les
///   cinq dernieres minutes et la fin prevue ([AppMouvement.ilePassage],
///   puis elle se replie).
///
/// Le chrono reste au meme endroit dans les deux formes : il n'est jamais
/// recree (son etat, et le signal de fin, ne repartent pas de zero).
class _Barre extends ConsumerStatefulWidget {
  const _Barre({
    required this.etat,
    required this.cours,
    required this.onRetour,
    required this.bande,
    required this.onBande,
  });

  final EtatSessionPersistante etat;
  final SessionEnCours cours;
  final VoidCallback onRetour;

  /// La hauteur reservee a l'ile repliee : le fond de la bande s'arrete la,
  /// l'ile depliee deborde dessous, sur la page.
  final double bande;

  /// Recoit la hauteur mesuree de la bande repliee.
  final ValueChanged<double> onBande;

  @override
  ConsumerState<_Barre> createState() => _BarreEtat();
}

class _BarreEtat extends ConsumerState<_Barre> {
  bool _deplie = false;

  /// La rangee compacte, mesuree apres chaque image pour dire a la page la
  /// place que l'ile repliee lui prend.
  final GlobalKey _cleCompacte = GlobalKey();

  void _mesurerBande() {
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      final RenderObject? rendu = _cleCompacte.currentContext
          ?.findRenderObject();
      if (rendu is! RenderBox || !rendu.hasSize) return;
      widget.onBande(
        MediaQuery.paddingOf(context).top +
            2 * AppSpacing.sm +
            2 * AppSpacing.xs +
            rendu.size.height,
      );
    });
  }

  /// Vrai quand l'ile s'est depliee d'elle-meme : elle se replie seule.
  bool _depliAuto = false;
  Timer? _replier;
  EtatChronoVivant? _etatChrono;

  bool _horsLigne(EtatSessionPersistante e) =>
      e.lienPerdu || e.retourDeSuspension;

  /// DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026, point 15 : « la barre doit
  /// etre exploitee au max quand la salle est reduite ») : la meme logique
  /// que la salle (`PiloteDynamique`, `PilotePause`), ecrite une fois. L'ile
  /// recoit l'appel (sonnerie repetee, alerte, marque) et la pause (debut,
  /// heure de reprise, fin, et chez qui la pilote : la proposition et la fin
  /// a l'heure) par les paquets de la visio, que la salle soit ouverte ou non.
  final PiloteDynamique _dynamique = PiloteDynamique();
  late final SonnerieAppel _sonnerie = SonnerieAppel(
    () => ref.read(signalRappelProvider)(),
  );
  late final PilotePause _pause = PilotePause(
    dynamique: _dynamique,
    maintenant: () => ref.read(horlogeChronoProvider)().toUtc(),
    commandes: _CommandesPauseIle(this),
  );
  StreamSubscription<PaquetDonnees>? _sDonnees;
  PauseSeance? _pauseObservee;
  bool _pauseJamaisObservee = true;

  void _dynamiqueChange() {
    if (mounted) setState(() {});
  }

  void _recevoir(PaquetDonnees paquet) {
    if (!mounted) return;
    final String sessionId = widget.cours.sessionId;
    if (paquet.sujet == sujetPauseSalle) {
      // Seul qui ne conduit pas lit le relais (qui conduit lit le serveur).
      if (widget.etat.acces?.capacites.peutModerer ?? true) return;
      final PauseSeance? pause = pauseDepuisCharge(paquet.charge);
      if (pause == null) return;
      ref.read(pausesRecuesProvider)[sessionId] = pause;
      setState(() {});
      return;
    }
    // Le rappel est adresse au seul eleve vise : le recevoir, c'est etre
    // appele (qui conduit la seance ne l'est jamais). Son propre paquet ne
    // revient pas ; le profil, quand il est connu, l'ecarte en plus.
    if (widget.etat.acces?.capacites.peutModerer ?? false) return;
    String profil = '';
    try {
      profil = ref.read(sessionProvider).profileId ?? '';
    } on Object {
      // Session illisible : le paquet adresse suffit.
    }
    if (paquetRappelPour(paquet, sessionId: sessionId, profilLocalId: profil)) {
      _sonnerie.lancer();
      _dynamique.annoncer(
        alerteAppelRecu(
          tutoie: widget.cours.interfaceGuidee,
          numero: _dynamique.numero,
        ),
      );
    }
  }

  /// Une commande de la pause, par le port ; l'etat est relu ensuite.
  ///
  /// HARMONIE-SALLE (13/11/2026) : l'etat rendu par le serveur est relaye a
  /// la classe sur le canal fiable, comme le fait la salle
  /// (`_diffuserPause`, `salle_page.dart`) : une pause demarree, finie ou
  /// refusee depuis la salle reduite arrive chez les eleves sur le moment
  /// (avant : seulement au retour de l'enseignant dans la salle). Rien n'est
  /// decide ici ; sans droit de publier, rien ne part.
  Future<void> _commanderPause(
    Future<PauseSeance> Function(PortPauseSeance port, String cle) commande,
  ) async {
    try {
      final PauseSeance etat = await commande(
        ref.read(portPauseSeanceProvider),
        'ile-${widget.cours.sessionId}-${DateTime.now().microsecondsSinceEpoch}',
      ).timeout(AppDelais.requeteMax);
      if (widget.etat.acces?.capacites.peutPublierDonnees ?? false) {
        try {
          await ref
              .read(moteurSalleProvider)
              .publierDonnees(
                sujet: sujetPauseSalle,
                charge: utf8.encode(jsonEncode(chargePause(etat))),
                fiable: true,
              );
        } on Object catch (erreur) {
          journalDev('pause non relayee depuis la salle reduite : $erreur');
        }
      }
    } finally {
      if (mounted) {
        ref.invalidate(pauseSeanceProvider(widget.cours.sessionId));
      }
    }
  }

  void _observerPause(PauseSeance? pause, {required bool pilote}) {
    if (!_pauseJamaisObservee && pause == _pauseObservee) return;
    _pauseJamaisObservee = false;
    _pauseObservee = pause;
    scheduleMicrotask(() {
      if (mounted) _pause.observer(pause, pilote: pilote);
    });
  }

  @override
  void initState() {
    super.initState();
    if (_horsLigne(widget.etat)) {
      _deplie = true;
      _depliAuto = true;
    }
    _dynamique
      ..addListener(_dynamiqueChange)
      ..auToucher(() {
        _sonnerie.arreter();
        _dynamique.oublier(cleAppelRecu);
      })
      ..aChaqueBattement(() {
        if (mounted) _pause.evaluer();
      })
      ..demarrer();
    _sDonnees = ref.read(moteurSalleProvider).donneesRecues.listen(_recevoir);
  }

  @override
  void didUpdateWidget(_Barre ancien) {
    super.didUpdateWidget(ancien);
    final bool avant = _horsLigne(ancien.etat);
    final bool maintenant = _horsLigne(widget.etat);
    if (!avant && maintenant && !_deplie) {
      // Ce qui empeche d'entendre se dit tant que ca dure.
      _replier?.cancel();
      _deplie = true;
      _depliAuto = true;
    } else if (avant && !maintenant && _depliAuto) {
      _deplie = false;
      _depliAuto = false;
    }
  }

  @override
  void dispose() {
    _replier?.cancel();
    _sonnerie.arreter();
    unawaited(_sDonnees?.cancel());
    _dynamique
      ..removeListener(_dynamiqueChange)
      ..dispose();
    super.dispose();
  }

  void _basculer() {
    _replier?.cancel();
    setState(() {
      _deplie = !_deplie;
      _depliAuto = false;
    });
  }

  /// Le chrono change d'etat (pendant sa propre construction) : l'ile le
  /// dit apres l'image.
  void _changerEtat(EtatChronoVivant etat, {required bool conduit}) {
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      setState(() => _etatChrono = etat);
      final bool aDire =
          conduit &&
          (etat == EtatChronoVivant.bientot ||
              etat == EtatChronoVivant.depassement);
      if (!aDire || (_deplie && !_depliAuto)) return;
      setState(() {
        _deplie = true;
        _depliAuto = true;
      });
      _replier?.cancel();
      _replier = Timer(AppMouvement.ilePassage, () {
        if (!mounted || !_depliAuto || _horsLigne(widget.etat)) return;
        setState(() {
          _deplie = false;
          _depliAuto = false;
        });
      });
    });
  }

  /// Le nom de la Classe : celui que le cours porte, sinon (chez qui conduit
  /// la seance) celui des seances deja servies. `null` : aucun nom connu.
  String? _nomClasse(SessionEnCours cours, {required bool conduit}) {
    if (cours.libelleGroupe.isNotEmpty) return cours.libelleGroupe;
    if (!conduit) return null;
    for (final SeanceEnseignant s
        in ref.watch(seancesEnseignantProvider).value ??
            const <SeanceEnseignant>[]) {
      final bool meme =
          s.id == cours.sessionId ||
          (s.aCreer && s.groupeId != null && s.groupeId == cours.groupeId);
      final String? nom = s.groupeLibelle;
      if (meme && nom != null && nom.isNotEmpty) return nom;
    }
    return null;
  }

  /// Les bornes du chrono : les memes que celles de la salle (seances deja
  /// servies), sinon l'horloge du cours. `null` : pas de temps restant.
  BornesChrono? _bornes(SessionEnCours cours, {required bool conduit}) {
    final BornesChrono? servies = ref.watch(
      bornesSalleProvider((
        seanceId: cours.sessionId,
        groupeId: cours.groupeId.isEmpty ? null : cours.groupeId,
        enseignant: conduit,
      )),
    );
    if (servies != null) return servies;
    final SessionClockVM? h = cours.horloge;
    if (h == null || h.finPrevueUtc.isBefore(h.debutUtc)) return null;
    return BornesChrono(
      debutUtc: h.debutUtc.toUtc(),
      finPrevueUtc: h.finPrevueUtc.toUtc(),
      depassementMax: h.graceApresFin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.surfaceRaised;
    final EtatSessionPersistante etat = widget.etat;
    final bool horsLigne = _horsLigne(etat);
    final CapacitesSalle? capacites = etat.acces?.capacites;
    final bool peutParler = capacites?.peutPublier ?? false;
    // Un widget lit une capacite, jamais un role : qui peut moderer la
    // seance la conduit (l'enseignant effectif, verifie par le serveur).
    final bool conduit = capacites?.peutModerer ?? false;
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle style = paire.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final String? nom = _nomClasse(widget.cours, conduit: conduit);
    final BornesChrono? bornes = _bornes(widget.cours, conduit: conduit);
    // DYNAMIQUE-CHRONO-2 : la pause, lue au serveur par qui conduit, recue
    // par le relais chez les autres.
    final String seance = widget.cours.sessionId;
    final PauseSeance? pause = conduit
        ? ref.watch(pauseSeanceProvider(seance)).value
        : ref.read(pausesRecuesProvider)[seance];
    _observerPause(pause, pilote: conduit && (pause?.peutPiloter ?? false));
    final AlerteChrono? alerte = _dynamique.alerte;

    final Widget? chrono = bornes == null
        ? null
        : ChronoSalle(
            key: BarreSeanceEnDirect.cleChrono,
            bornes: bornes,
            connexion: horsLigne
                ? ConnexionSeance.reconnexion
                : ConnexionSeance.enLigne,
            style: paire.applyTo(textes.labelMedium ?? const TextStyle()),
            garderCouleur: true,
            surfaceCapsule: paire,
            dansUnePilule: true,
            sobre: !conduit,
            sonne: conduit,
            onEtat: (EtatChronoVivant e) => _changerEtat(e, conduit: conduit),
            pause: pause,
            marques: _dynamique.marques,
            // DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, point 15 : « elle
            // marche bien aussi quand on reduit la salle ») : la meme ligne
            // repliee que la Dynamique chrono de la salle (l'anneau,
            // « Reste 37:51 ») ; le toucher garde son geste, retourner dans
            // la salle.
            deplie: false,
          );

    final EtatChronoVivant? etatChrono = _etatChrono;
    final String? phrase = horsLigne
        ? t.salle.secours.reconnexion
        : !conduit
        ? null
        : etatChrono == EtatChronoVivant.bientot
        ? t.salle.ile.conclure
        : etatChrono == EtatChronoVivant.depassement
        ? t.salle.ile.finAtteinte
        : null;

    // Compacte : la pastille (ou la reconnexion) et le chrono ramenent a la
    // salle d'un appui ; le micro ; le chevron.
    final Widget zoneRetour = Pressable(
      key: BarreSeanceEnDirect.cleRetour,
      // Le toucher coupe aussi la sonnerie et efface l'appel recu ; il garde
      // son geste : retourner dans la salle.
      onPress: () {
        _dynamique.toucher();
        widget.onRetour();
      },
      libelleSemantique: t.salle.retourner,
      arrondiFocus: AppRadius.arrondiLg,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        // Centree sur la hauteur de la cible (48) : alignee sur le micro et
        // le chevron.
        runAlignment: WrapAlignment.center,
        children: <Widget>[
          FonduLiquide(
            cle: horsLigne,
            child: horsLigne
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconTheme(
                        data: IconThemeData(
                          color: paire.onBackground,
                          size: AppSpacing.xl,
                        ),
                        child: Icon(AppIcons.reconnexion.repos),
                      ),
                      Ecart.hSm,
                      Flexible(
                        child: Text(t.salle.reconnexionCourt, style: style),
                      ),
                    ],
                  )
                // Compacte : le mot court « En direct » ; la phrase
                // « Seance toujours en direct » vit dans l'ile depliee.
                : const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
          ),
          ?chrono,
        ],
      ),
    );

    // Une rangee qui passe a la ligne : a 320 points en texte agrandi, le
    // micro et le chevron descendent sous le chrono plutot que de l'ecraser.
    _mesurerBande();
    final Widget compacte = Wrap(
      key: _cleCompacte,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: <Widget>[
        zoneRetour,
        if (peutParler && !horsLigne) _MicroDeLaBarre(moteur: moteur),
        BoutonIcone(
          key: BarreSeanceEnDirect.cleChevron,
          icone: _deplie ? AppIcons.replier : AppIcons.suiteEnBas,
          libelle: _deplie ? t.salle.ile.replier : t.salle.ile.deplier,
          infobulle: _deplie ? t.salle.ile.replier : t.salle.ile.deplier,
          selectionne: _deplie,
          onPress: _basculer,
        ),
      ],
    );

    final Widget detail = _deplie
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              start: AppSpacing.xs,
              end: AppSpacing.md,
            ),
            child: Column(
              key: BarreSeanceEnDirect.cleDetail,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (nom != null)
                  Text(
                    nom,
                    style: paire.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                if (nom != null) Ecart.vXs,
                Text(phrase ?? t.tc.groupe.temps.prolongee, style: style),
                if (peutParler && !horsLigne) ...<Widget>[
                  Ecart.vXs,
                  _MicroDeLaBarre(moteur: moteur, mot: true, style: style),
                ],
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 1,
                  child: LienFleche(
                    libelle: t.salle.retourner,
                    onPress: widget.onRetour,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Directeur, 11/11/2026 : l'ile depliee se pose SUR la page. Le fond de
    // la bande ne couvre que la place de l'ile repliee ; le detail deborde
    // dessous, par-dessus le contenu, qui ne bouge pas.
    return Semantics(
      container: true,
      liveRegion: true,
      child: Listener(
        // DYNAMIQUE-CHRONO-2, point 6 : toucher l'ile arrete la sonnerie.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent _) => _sonnerie.arreter(),
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              height: widget.bande,
              child: ColoredBox(color: palette.surfaceCanvas.background),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Center(
                  child: IleLiquide(
                    key: BarreSeanceEnDirect.cleIle,
                    decoration: paire.decoration(
                      borderRadius: AppRadius.arrondiLg,
                      side: palette.borderStrong.asBorderSide(),
                    ),
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.md,
                      end: AppSpacing.xs,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        compacte,
                        if (alerte != null)
                          _AlerteIle(
                            key: BarreSeanceEnDirect.cleAlerte,
                            alerte: alerte,
                            style: style,
                            titre: paire.applyTo(
                              textes.titleSmall ?? const TextStyle(),
                            ),
                            onChoix: (ActionAlerteChrono a) {
                              a.onPress();
                              _dynamique.choisir(alerte.id);
                            },
                          )
                        else
                          FonduLiquide(cle: _deplie, child: detail),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couper ou rouvrir son micro sans retourner dans la salle. L'etat se lit a
/// l'icone (barree ou non) et au libelle ; ile depliee, le meme etat se dit
/// aussi en un mot ([mot]) : jamais a la couleur seule.
class _MicroDeLaBarre extends StatelessWidget {
  const _MicroDeLaBarre({required this.moteur, this.mot = false, this.style});

  final VideoSessionProvider moteur;

  /// Vrai : le mot d'etat (« Micro coupé »), pas le bouton.
  final bool mot;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ParticipantSalle>>(
    stream: moteur.participants,
    builder: (BuildContext context, AsyncSnapshot<List<ParticipantSalle>> s) {
      final List<ParticipantSalle> liste = s.data ?? const <ParticipantSalle>[];
      final bool ouvert = liste.any(
        (ParticipantSalle p) => p.estLocal && p.micro,
      );
      if (mot) {
        // Le bouton porte deja l'etat pour le lecteur d'ecran.
        return ExcludeSemantics(
          child: Text(
            ouvert ? t.salle.microOuvert : t.salle.microCoupe,
            style: style,
          ),
        );
      }
      return BoutonIcone(
        key: BarreSeanceEnDirect.cleMicro,
        icone: ouvert ? AppIcons.micro : AppIcons.microCoupe,
        libelle: ouvert ? t.salle.fermerMicro : t.salle.ouvrirMicro,
        infobulle: ouvert ? t.salle.microOuvert : t.salle.microCoupe,
        selectionne: ouvert,
        onPress: () => unawaited(moteur.reglerMicro(actif: !ouvert)),
      );
    },
  );
}

/// DYNAMIQUE-CHRONO-2 : l'alerte dans l'ile de la salle reduite (titre, une
/// phrase, une ou deux actions), lue une fois.
class _AlerteIle extends StatelessWidget {
  const _AlerteIle({
    required this.alerte,
    required this.style,
    required this.titre,
    required this.onChoix,
    super.key,
  });

  final AlerteChrono alerte;
  final TextStyle style;
  final TextStyle titre;
  final ValueChanged<ActionAlerteChrono> onChoix;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.sm,
      start: AppSpacing.xs,
      end: AppSpacing.md,
      bottom: AppSpacing.xs,
    ),
    child: Semantics(
      key: ValueKey<String>('alerte-ile-${alerte.id}'),
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: <Widget>[
          Text(alerte.titre, style: titre),
          if (alerte.detail case final String detail)
            Text(detail, style: style),
          if (alerte.actions.isNotEmpty)
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final ActionAlerteChrono a in alerte.actions)
                  a.principale
                      ? ActionPrincipale(
                          libelle: a.libelle,
                          compacte: true,
                          pleineLargeur: false,
                          onPress: () => onChoix(a),
                        )
                      : LienFleche(
                          libelle: a.libelle,
                          fleche: false,
                          onPress: () => onChoix(a),
                        ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// DYNAMIQUE-CHRONO-2 : les commandes de la pause depuis l'ile.
class _CommandesPauseIle implements CommandesPause {
  _CommandesPauseIle(this._ile);

  final _BarreEtat _ile;

  String get _seance => _ile.widget.cours.sessionId;

  @override
  Future<void> demarrer() => _ile._commanderPause(
    (PortPauseSeance port, String cle) =>
        port.demarrer(seanceId: _seance, cleIdempotence: cle),
  );

  @override
  Future<void> terminer() => _ile._commanderPause(
    (PortPauseSeance port, String cle) =>
        port.terminer(seanceId: _seance, cleIdempotence: cle),
  );

  @override
  Future<void> refuser() => _ile._commanderPause(
    (PortPauseSeance port, String cle) =>
        port.refuser(seanceId: _seance, cleIdempotence: cle),
  );
}
