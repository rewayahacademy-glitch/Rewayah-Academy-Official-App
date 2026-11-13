import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../core/session/session_state.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/tc_horloge/chrono_seance.dart' show BornesChrono;
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pressable.dart';
import '../salle/seance_vivante.dart';
import '../salle/synchro_salle.dart' show ParoleSalle;
import 'bornes_salle.dart';
import 'chrono_salle.dart';
import 'marque_chrono.dart';
import 'pilote_dynamique.dart';
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

  /// SYNCHRO-SESSION : la pastille reduite a son point (place qui manque).
  static const Key clePointDirect = ValueKey<String>('ile-seance-point-direct');

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
  /// etre exploitee au max quand la salle est reduite ») et SYNCHRO-SESSION
  /// (13/11/2026, `HARMONIE-2026-11-13.md` section 7) : la salle reduite lit
  /// LA seance de l'appel ([SeanceVivante]), tenue par le controleur de
  /// session : la meme Dynamique chrono que la salle (une file d'alertes, des
  /// marques qui passent de l'une a l'autre), l'appel recu (sonnerie
  /// repetee, alerte, marque), la recitation, les arrivees chez qui conduit,
  /// la pause (verifiee de qui conduit, ligne 3.3) et, chez qui la pilote, la
  /// proposition et la fin a l'heure. Rien n'est ecrit ici une seconde fois.
  ///
  /// Un controleur sans seance (tests du controleur seul) : l'ile tient la
  /// sienne, liberee avec elle ([_seanceLocale]).
  SeanceVivante? _seanceLocale;

  /// La seance a laquelle l'ile est abonnee.
  SeanceVivante? _seanceSuivie;

  SeanceVivante? _seanceCourante() {
    final SeanceVivante? tenue = seanceTenue(
      ref.read(controleurSessionProvider),
      widget.cours.sessionId,
    );
    if (tenue != null) {
      _libererSeanceLocale();
      return tenue;
    }
    final SeanceVivante? locale = _seanceLocale;
    if (locale != null && !locale.libere) return locale;
    final AccesSalle? acces = widget.etat.acces;
    if (acces == null) return null;
    // La synchronisation a besoin du profil : tant que la session n'est pas
    // lue, l'ile attend (elle se redessine quand il arrive).
    String? profil;
    try {
      profil = ref.watch(
        sessionProvider.select((SessionState s) => s.profileId),
      );
    } on Object {
      profil = null;
    }
    if (profil == null) return null;
    final String seance = widget.cours.sessionId;
    return _seanceLocale = creerSeanceVivante(
      cours: widget.cours,
      acces: acces,
      moteur: ref.read(moteurSalleProvider),
      lire: ref.read,
      relirePause: () {
        if (mounted) ref.invalidate(pauseSeanceProvider(seance));
      },
      terminerRecitationALEntree: false,
    );
  }

  /// Suit la seance courante (et quitte la precedente) : l'ile se redessine
  /// quand la Dynamique chrono, la parole ou la pause recue changent.
  SeanceVivante? _raccorderSeance() {
    final SeanceVivante? s = _seanceCourante();
    if (!identical(s, _seanceSuivie)) {
      _seanceSuivie?.removeListener(_seanceChange);
      _seanceSuivie?.dynamique.removeListener(_seanceChange);
      _seanceSuivie = s;
      s?.addListener(_seanceChange);
      s?.dynamique.addListener(_seanceChange);
    }
    return s;
  }

  void _seanceChange() {
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

  void _libererSeanceLocale() {
    final SeanceVivante? locale = _seanceLocale;
    _seanceLocale = null;
    if (locale != null) unawaited(locale.liberer());
  }

  @override
  void initState() {
    super.initState();
    if (_horsLigne(widget.etat)) {
      _deplie = true;
      _depliAuto = true;
    }
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
    _seanceSuivie?.removeListener(_seanceChange);
    _seanceSuivie?.dynamique.removeListener(_seanceChange);
    _seanceSuivie = null;
    _libererSeanceLocale();
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
    // SYNCHRO-SESSION : la pause recue (de qui conduit seulement, ligne
    // 3.3) est celle que la seance a gardee, salle ouverte ou reduite.
    final SeanceVivante? vivante = _raccorderSeance();
    final String seance = widget.cours.sessionId;
    final PauseSeance? pause = conduit
        ? ref.watch(pauseSeanceProvider(seance)).value
        : vivante?.pauseRecue;
    vivante?.observerPause(
      pause,
      pilote: conduit && (pause?.peutPiloter ?? false),
    );
    final AlerteChrono? alerte = vivante?.dynamique.alerte;
    // SYNCHRO-SESSION, point 4 du plan : la recitation se lit aussi dans la
    // salle reduite (« Yasmine recite », ou « Un eleve recite » quand celui
    // qui regarde ne connait pas le prenom), comme dans la salle.
    final ParoleSalle? parole = vivante?.parole;

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
            marques: <MarqueChrono>[
              ...?vivante?.dynamique.marques,
              if (parole != null)
                MarqueChrono.recitation(
                  libelle: titreRecitation(parole.prenom),
                ),
            ],
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

    final bool texteAgrandi = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final Widget etatCompact = FonduLiquide(
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
                Flexible(child: Text(t.salle.reconnexionCourt, style: style)),
              ],
            )
          // Compacte : le mot court « En direct » ; la phrase « Seance
          // toujours en direct » vit dans l'ile depliee. SYNCHRO-SESSION :
          // quand la place manque, la pastille se reduit a son point (son
          // mot reste lu).
          : texteAgrandi
          ? const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect)
          : _PremierQuiTient(
              children: <Widget>[
                const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
                const PastilleEtatSeance(
                  key: BarreSeanceEnDirect.clePointDirect,
                  etat: EtatPastilleSeance.enDirect,
                  pointSeul: true,
                ),
                // Le chrono prend toute la place (ecart extreme) : la
                // pastille ne se voit plus, son mot reste lu.
                Semantics(
                  label: PastilleEtatSeance.libelleDe(
                    EtatPastilleSeance.enDirect,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
    );

    // Compacte : la pastille (ou la reconnexion) et le chrono ramenent a la
    // salle d'un appui ; le micro ; le chevron.
    final Widget zoneRetour = Pressable(
      key: BarreSeanceEnDirect.cleRetour,
      // Le toucher coupe aussi la sonnerie et efface l'appel recu ; il garde
      // son geste : retourner dans la salle.
      onPress: () {
        vivante?.dynamique.toucher();
        widget.onRetour();
      },
      libelleSemantique: t.salle.retourner,
      arrondiFocus: AppRadius.arrondiLg,
      // SYNCHRO-SESSION (13/11/2026, retour du pilote) : une seule rangee
      // tant que le texte n'est pas agrandi (la pastille cede la premiere ;
      // la rangee coupe ce qui depasserait le temps que l'ile grandit) ;
      // texte agrandi, la pastille et le chrono peuvent passer a la ligne.
      child: texteAgrandi
          ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              runAlignment: WrapAlignment.center,
              children: <Widget>[etatCompact, ?chrono],
            )
          : _EtatEtChrono(
              textDirection: Directionality.of(context),
              children: <Widget>[etatCompact, ?chrono],
            ),
    );

    // Une rangee qui passe a la ligne : a 320 points en texte agrandi, le
    // micro et le chevron descendent sous le chrono plutot que de l'ecraser.
    _mesurerBande();
    // SYNCHRO-SESSION (retour du pilote, 13/11/2026) : le micro et le
    // chevron forment un bloc de fin, jamais separe : au texte normal, ils
    // restent sur la rangee du chrono, au bord de fin ; texte agrandi (plus
    // de 130 %), le bloc entier peut passer a la ligne, jamais un bouton
    // seul.
    final Widget boutons = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
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
    final Widget compacte = texteAgrandi
        ? Wrap(
            key: _cleCompacte,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            children: <Widget>[zoneRetour, boutons],
          )
        // Au telephone (moins de 600 points), la rangee prend la largeur de
        // l'ile : les boutons sont au bord de fin, meme quand l'alerte
        // depliee elargit l'ile ; ailleurs, l'ile garde la taille de son
        // contenu. Si le chrono seul ne laisse pas la place des boutons
        // (ecart extreme), le bloc des boutons passe entier dessous.
        : _RangeeCompacte(
            key: _cleCompacte,
            remplir: MediaQuery.sizeOf(context).width < 600,
            textDirection: Directionality.of(context),
            children: <Widget>[zoneRetour, boutons],
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
        onPointerDown: (PointerDownEvent _) => vivante?.arreterSonnerie(),
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
                              vivante?.dynamique.choisir(alerte.id);
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

/// SYNCHRO-SESSION (13/11/2026) : montre le premier enfant qui tient dans la
/// largeur donnee, sinon le dernier. Seul l'enfant montre est peint, touche
/// et lu ; les autres sont mesures, jamais vus.
class _PremierQuiTient extends MultiChildRenderObjectWidget {
  const _PremierQuiTient({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduPremierQuiTient();
}

class _ParentPremierQuiTient extends ContainerBoxParentData<RenderBox> {}

class _RenduPremierQuiTient extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentPremierQuiTient>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentPremierQuiTient> {
  RenderBox? _montre;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentPremierQuiTient) {
      child.parentData = _ParentPremierQuiTient();
    }
  }

  @override
  void performLayout() {
    final BoxConstraints libres = constraints.loosen();
    RenderBox? enfant = firstChild;
    _montre = null;
    while (enfant != null) {
      final RenderBox? suivant = childAfter(enfant);
      final double largeur = enfant.getMaxIntrinsicWidth(constraints.maxHeight);
      if (suivant == null || largeur <= constraints.maxWidth) {
        _montre = enfant;
        break;
      }
      enfant = suivant;
    }
    RenderBox? autre = firstChild;
    while (autre != null) {
      autre.layout(libres, parentUsesSize: identical(autre, _montre));
      autre = childAfter(autre);
    }
    final RenderBox? montre = _montre;
    size = constraints.constrain(montre?.size ?? Size.zero);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      firstChild?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? montre = _montre;
    if (montre != null) context.paintChild(montre, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? montre = _montre;
    if (montre == null) return false;
    return montre.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final RenderBox? montre = _montre;
    if (montre != null) visitor(montre);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    RenderBox? enfant = firstChild;
    while (enfant != null) {
      final RenderBox? suivant = childAfter(enfant);
      if (suivant == null ||
          enfant.getMaxIntrinsicWidth(constraints.maxHeight) <=
              constraints.maxWidth) {
        return constraints.constrain(enfant.getDryLayout(constraints.loosen()));
      }
      enfant = suivant;
    }
    return constraints.constrain(Size.zero);
  }
}

/// SYNCHRO-SESSION : la pastille et le chrono de l'ile. Le chrono passe
/// d'abord (il ne cede jamais) ; la pastille prend ce qui reste (son mot,
/// son point, ou rien : son mot reste lu).
class _EtatEtChrono extends MultiChildRenderObjectWidget {
  const _EtatEtChrono({required this.textDirection, required super.children});

  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduEtatEtChrono(textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduEtatEtChrono renderObject,
  ) => renderObject.textDirection = textDirection;
}

class _RenduEtatEtChrono extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentPremierQuiTient>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentPremierQuiTient> {
  _RenduEtatEtChrono(this._textDirection);

  TextDirection _textDirection;
  set textDirection(TextDirection valeur) {
    if (valeur == _textDirection) return;
    _textDirection = valeur;
    markNeedsLayout();
  }

  static const double _ecart = AppSpacing.sm;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentPremierQuiTient) {
      child.parentData = _ParentPremierQuiTient();
    }
  }

  RenderBox? get _etat => firstChild;
  RenderBox? get _chrono => childCount > 1 ? lastChild : null;

  @override
  void performLayout() {
    final double largeur = constraints.maxWidth;
    final RenderBox? chrono = _chrono;
    final RenderBox? etat = _etat;
    double lc = 0;
    double hauteur = 0;
    if (chrono != null) {
      chrono.layout(
        BoxConstraints(maxWidth: largeur, maxHeight: constraints.maxHeight),
        parentUsesSize: true,
      );
      lc = chrono.size.width;
      hauteur = chrono.size.height;
    }
    double le = 0;
    if (etat != null) {
      final double reste = math.max(
        0,
        largeur - lc - (chrono == null ? 0 : _ecart),
      );
      etat.layout(
        BoxConstraints(maxWidth: reste, maxHeight: constraints.maxHeight),
        parentUsesSize: true,
      );
      le = etat.size.width;
      hauteur = math.max(hauteur, etat.size.height);
    }
    final double ecart = le > 0 && chrono != null ? _ecart : 0;
    size = constraints.constrain(Size(le + ecart + lc, hauteur));
    final bool rtl = _textDirection == TextDirection.rtl;
    if (etat != null) {
      (etat.parentData! as _ParentPremierQuiTient).offset = Offset(
        rtl ? size.width - le : 0,
        (size.height - etat.size.height) / 2,
      );
    }
    if (chrono != null) {
      (chrono.parentData! as _ParentPremierQuiTient).offset = Offset(
        rtl ? size.width - le - ecart - lc : le + ecart,
        (size.height - chrono.size.height) / 2,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _chrono?.getMaxIntrinsicWidth(height) ??
      _etat?.getMinIntrinsicWidth(height) ??
      0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double e = _etat?.getMaxIntrinsicWidth(height) ?? 0;
    final double c = _chrono?.getMaxIntrinsicWidth(height) ?? 0;
    return e + c + (_chrono == null ? 0 : _ecart);
  }

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _etat?.getMinIntrinsicHeight(width) ?? 0,
    _chrono?.getMinIntrinsicHeight(width) ?? 0,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _etat?.getMaxIntrinsicHeight(width) ?? 0,
    _chrono?.getMaxIntrinsicHeight(width) ?? 0,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      math.min(
        constraints.maxWidth,
        computeMaxIntrinsicWidth(constraints.maxHeight),
      ),
      computeMaxIntrinsicHeight(constraints.maxWidth),
    ),
  );

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// SYNCHRO-SESSION (retour du pilote, 13/11/2026) : la rangee compacte de
/// l'ile. Le retour (pastille et chrono) au bord de debut, le bloc des
/// boutons (micro, chevron) au bord de fin, sur une seule rangee tant que le
/// chrono et les boutons tiennent ensemble ; sinon le bloc entier passe
/// dessous, au bord de fin (jamais un bouton seul).
class _RangeeCompacte extends MultiChildRenderObjectWidget {
  const _RangeeCompacte({
    required this.remplir,
    required this.textDirection,
    required super.children,
    super.key,
  });

  /// Vrai : la rangee prend toute la largeur donnee.
  final bool remplir;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduRangeeCompacte(remplir, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduRangeeCompacte renderObject,
  ) {
    renderObject
      ..remplir = remplir
      ..textDirection = textDirection;
  }
}

class _RenduRangeeCompacte extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentPremierQuiTient>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentPremierQuiTient> {
  _RenduRangeeCompacte(this._remplir, this._textDirection);

  bool _remplir;
  set remplir(bool valeur) {
    if (valeur == _remplir) return;
    _remplir = valeur;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection valeur) {
    if (valeur == _textDirection) return;
    _textDirection = valeur;
    markNeedsLayout();
  }

  static const double _ecart = AppSpacing.sm;
  static const double _entreRangees = AppSpacing.xs;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentPremierQuiTient) {
      child.parentData = _ParentPremierQuiTient();
    }
  }

  void _placer(RenderBox enfant, double x, double y) =>
      (enfant.parentData! as _ParentPremierQuiTient).offset = Offset(x, y);

  @override
  void performLayout() {
    final RenderBox? retour = firstChild;
    final RenderBox? boutons = retour == null ? null : childAfter(retour);
    if (retour == null || boutons == null) {
      size = constraints.smallest;
      return;
    }
    final double largeur = constraints.maxWidth;
    final bool rtl = _textDirection == TextDirection.rtl;
    boutons.layout(constraints.loosen(), parentUsesSize: true);
    final double lb = boutons.size.width;
    final double minRetour = retour.getMinIntrinsicWidth(double.infinity);
    if (minRetour + _ecart + lb <= largeur) {
      retour.layout(
        BoxConstraints(
          maxWidth: math.max(0, largeur - _ecart - lb),
          maxHeight: constraints.maxHeight,
        ),
        parentUsesSize: true,
      );
      final double naturelle = retour.size.width + _ecart + lb;
      final double w = _remplir && largeur.isFinite ? largeur : naturelle;
      final double h = math.max(retour.size.height, boutons.size.height);
      size = constraints.constrain(Size(w, h));
      _placer(
        retour,
        rtl ? size.width - retour.size.width : 0,
        (size.height - retour.size.height) / 2,
      );
      _placer(
        boutons,
        rtl ? 0 : size.width - lb,
        (size.height - boutons.size.height) / 2,
      );
      return;
    }
    retour.layout(constraints.loosen(), parentUsesSize: true);
    final double naturelle = math.max(retour.size.width, lb);
    final double w = _remplir && largeur.isFinite ? largeur : naturelle;
    size = constraints.constrain(
      Size(w, retour.size.height + _entreRangees + boutons.size.height),
    );
    _placer(retour, rtl ? size.width - retour.size.width : 0, 0);
    _placer(
      boutons,
      rtl ? 0 : size.width - lb,
      retour.size.height + _entreRangees,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild?.getMinIntrinsicWidth(height) ?? 0,
    lastChild?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (firstChild?.getMaxIntrinsicWidth(height) ?? 0) +
      _ecart +
      (lastChild?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    firstChild?.getMinIntrinsicHeight(width) ?? 0,
    lastChild?.getMinIntrinsicHeight(width) ?? 0,
  );

  @override
  double computeMaxIntrinsicHeight(double width) =>
      (firstChild?.getMaxIntrinsicHeight(width) ?? 0) +
      _entreRangees +
      (lastChild?.getMaxIntrinsicHeight(width) ?? 0);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(
      computeMaxIntrinsicWidth(constraints.maxHeight),
      computeMinIntrinsicHeight(constraints.maxWidth),
    ),
  );

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
