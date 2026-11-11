import 'dart:async';

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
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
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
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pressable.dart';
import 'bornes_salle.dart';
import 'chrono_salle.dart';
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
    return Column(
      children: <Widget>[
        if (visible)
          _Barre(
            etat: etat,
            cours: cours,
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
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: widget.child,
          ),
        ),
      ],
    );
  }
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
  });

  final EtatSessionPersistante etat;
  final SessionEnCours cours;
  final VoidCallback onRetour;

  @override
  ConsumerState<_Barre> createState() => _BarreEtat();
}

class _BarreEtat extends ConsumerState<_Barre> {
  bool _deplie = false;

  /// Vrai quand l'ile s'est depliee d'elle-meme : elle se replie seule.
  bool _depliAuto = false;
  Timer? _replier;
  EtatChronoVivant? _etatChrono;

  bool _horsLigne(EtatSessionPersistante e) =>
      e.lienPerdu || e.retourDeSuspension;

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
      onPress: widget.onRetour,
      libelleSemantique: t.salle.retourner,
      arrondiFocus: AppRadius.arrondiLg,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
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
                : PastilleEtatSeance(
                    etat: EtatPastilleSeance.enDirect,
                    libelle: t.tc.groupe.temps.prolongee,
                  ),
          ),
          ?chrono,
        ],
      ),
    );

    // Une rangee qui passe a la ligne : a 320 points en texte agrandi, le
    // micro et le chevron descendent sous le chrono plutot que de l'ecraser.
    final Widget compacte = Wrap(
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
                if (phrase != null) ...<Widget>[
                  if (nom != null) Ecart.vXs,
                  Text(phrase, style: style),
                ],
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

    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: palette.surfaceCanvas.background,
        child: SafeArea(
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
                    FonduLiquide(cle: _deplie, child: detail),
                  ],
                ),
              ),
            ),
          ),
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
