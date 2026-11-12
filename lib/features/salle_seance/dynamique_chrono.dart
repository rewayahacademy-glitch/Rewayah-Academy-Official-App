// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026, seance reelle ; retours sur la
// salle, points 2, 3, 5 et 15 ; `docs/current/salle/PLAN-RETOURS-2026-11-12.md`,
// decision 1) : la « Dynamique chrono », la seule barre d'etat de la salle,
// facon Dynamic Island.
//
// - **Une place reservee, jamais posee sur le contenu** ([ZoneChrono]) : au
//   telephone et sur tablette sans colonne, une rangee de toute la largeur
//   au-dessus de la page ; sur ordinateur (et tablette avec colonne), la tete
//   de la colonne, dont la hauteur suit son contenu.
// - **Repliee, une ligne** : l'anneau, « Reste 37:51 » (le mot visible), et
//   des marques en points de couleur, chacune lue (« En retard », « Yasmine
//   recite », « Pause dans 21 min ») : [MarqueChrono].
// - **Un toucher la deplie** : chaque marque en clair (point ET mot, jamais la
//   couleur seule), et la commande de la pause de qui la conduit (capacite
//   `peutPiloter`). Elle se replie seule apres
//   [AppMouvement.dynamiqueChronoDepliee] ou au second toucher. Depliee, elle
//   peut recouvrir un instant le haut du contenu (un geste court de la
//   personne) ; repliee, jamais. Sur ordinateur ([enPlace]), elle se deplie
//   dans la tete de la colonne, sans rien recouvrir.
// - **La mention permanente** « Visite de controle possible. »
//   ([PermanentNotice], ADR-011) et le mot d'etat du lien (« En salle »,
//   « En ligne ») ne se replient jamais : [LigneEtatSalle], dans la meme
//   zone reservee, sur la meme rangee quand la largeur le permet.
// - **Prete pour la suite** : une alerte passagere ([AlerteChrono]) deplie la
//   barre, part seule et laisse sa trace en marque. Aucune n'est emise dans ce
//   lot (DYNAMIQUE-CHRONO-2) ; aucun son nouveau.
//
// Elle reunit ce qui existait : l'ancienne ile de la salle (`DynamiqueChrono`,
// renommee ici), son chrono (`ChronoSalle`, qui calcule le temps et dessine la
// ligne) et sa capsule vivante (`ChronoVivant`, core). La salle reduite
// (`BarreSeanceEnDirect`) pose la meme ligne repliee (`ChronoSalle`).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart';
import 'chrono_salle.dart';
import 'marque_chrono.dart';
import 'media_salle.dart';
import 'mention_seance.dart';
import 'vue_seance.dart';

/// La Dynamique chrono : la barre du temps et des marques de la salle.
class DynamiqueChrono extends StatefulWidget {
  const DynamiqueChrono({
    required this.vue,
    this.largeurMax = double.infinity,
    this.cle = const ValueKey<String>('pilule-etat-salle'),
    this.surface,
    this.avecChrono = false,
    this.onPause,
    this.onEtatChrono,
    this.microOuvert = false,
    this.marques,
    this.alerte,
    this.enPlace = false,
    super.key,
  });

  final VueSeance vue;

  /// La largeur que la barre ne depasse pas (repliee comme depliee).
  final double largeurMax;

  /// La cle de la barre repliee, a sa place reservee (tests, captures).
  final Key cle;

  /// La surface de la capsule ; `null` : la pilule translucide de la salle.
  final AppColorPair? surface;

  /// La barre porte le chrono quand la vue a ses bornes (hors Interface
  /// guidee : `vue.voitChrono`). Faux : les marques seules (anciens
  /// en-tetes).
  final bool avecChrono;

  /// N3, S2 : demarrer ou terminer la pause programmee, depuis la barre
  /// depliee. Rendue seulement si le serveur a donne `peut_piloter`.
  final VoidCallback? onPause;

  /// CHRONO-ETAT : le chrono change d'etat (cinq minutes avant la fin, fin
  /// prevue) ; la salle y branche le signal sonore de qui dirige la seance.
  final ValueChanged<EtatChronoVivant>? onEtatChrono;

  /// Lot CORAN-ELEVE (pilote, 11/11/2026) : le micro local est ouvert ; la
  /// barre garde son signe (icone et nom lu, jamais la couleur seule).
  final bool microOuvert;

  /// Les marques ; `null` : celles de la salle ([PorteeMediaSalle.marques]).
  final List<MarqueChrono>? marques;

  /// L'alerte passagere en cours, ou `null` (aucune emise dans ce lot).
  final AlerteChrono? alerte;

  /// Vrai (ordinateur, tete de la colonne) : la barre se deplie a sa place,
  /// dans le flux, et pousse ce qui suit ; faux (telephone, tablette) : elle
  /// garde sa hauteur repliee et se deplie un instant par-dessus le haut du
  /// contenu.
  final bool enPlace;

  /// Le toucher qui deplie et replie la barre (tests).
  static const Key cleDeplier = ChronoSalle.cleBasculer;

  /// La barre depliee (tests).
  static const Key cleDepliee = ValueKey<String>('dynamique-chrono-depliee');

  /// Le signe « micro ouvert » (tests).
  static const Key cleMicroOuvert = ValueKey<String>('pilule-etat-micro');

  /// L'alerte passagere (tests).
  static const Key cleAlerte = ValueKey<String>('dynamique-chrono-alerte');

  @override
  State<DynamiqueChrono> createState() => _DynamiqueChronoEtat();
}

class _DynamiqueChronoEtat extends State<DynamiqueChrono> {
  bool _deplie = false;
  Timer? _replier;

  /// L'alerte montree en ce moment (par son identifiant), et celles deja
  /// montrees : une alerte reconstruite ne se rejoue pas.
  AlerteChrono? _alerte;
  final Set<String> _alertesVues = <String>{};
  final List<MarqueChrono> _traces = <MarqueChrono>[];
  Timer? _finAlerte;

  /// Le contenu (le chrono) passe de la barre repliee a la barre depliee
  /// sans etre recree : son etat et son signal sonore ne repartent pas de
  /// zero.
  final GlobalKey _cleContenu = GlobalKey(debugLabel: 'dynamique-chrono');
  final GlobalKey _cleRepliee = GlobalKey(debugLabel: 'dynamique-repliee');
  final LayerLink _lien = LayerLink();
  final OverlayPortalController _portail = OverlayPortalController();

  /// La taille de la barre repliee, gardee pendant qu'elle est depliee
  /// par-dessus : sa place ne change pas.
  Size? _tailleRepliee;

  @override
  void initState() {
    super.initState();
    // Le portail reste ouvert : il ne montre quelque chose que pendant que
    // la barre est depliee par-dessus (sa structure ne change jamais, le
    // chrono passe de l'un a l'autre sans etre recree).
    _portail.show();
    _lireAlerte();
  }

  @override
  void didUpdateWidget(DynamiqueChrono ancien) {
    super.didUpdateWidget(ancien);
    _lireAlerte();
  }

  @override
  void dispose() {
    _replier?.cancel();
    _finAlerte?.cancel();
    super.dispose();
  }

  void _lireAlerte() {
    final AlerteChrono? a = widget.alerte;
    if (a == null || _alertesVues.contains(a.id)) return;
    _alertesVues.add(a.id);
    _alerte = a;
    _finAlerte?.cancel();
    _finAlerte = Timer(
      a.duree ?? AppMouvement.alerteChrono,
      () => _fermerAlerte(a),
    );
  }

  void _fermerAlerte(AlerteChrono a) {
    if (!mounted || !identical(_alerte, a)) return;
    _finAlerte?.cancel();
    setState(() {
      _alerte = null;
      if (a.trace case final MarqueChrono trace) _traces.add(trace);
    });
  }

  void _basculer() {
    _replier?.cancel();
    if (_deplie) {
      setState(() => _deplie = false);
      return;
    }
    final RenderObject? r = _cleRepliee.currentContext?.findRenderObject();
    _tailleRepliee = r is RenderBox && r.hasSize ? r.size : null;
    setState(() => _deplie = true);
    _replier = Timer(AppMouvement.dynamiqueChronoDepliee, () {
      if (mounted) setState(() => _deplie = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final AppPalette palette = AppPalette.of(context);
    // Depliee par-dessus le contenu, la capsule devient opaque et cernee
    // (la surface relevee, son filet et une ombre douce) : la page ne se lit
    // jamais au travers.
    final bool parDessus = _deplie && !widget.enPlace;
    final AppColorPair fond = parDessus
        ? palette.surfaceRaised
        : widget.surface ?? palette.piluleSalle;
    final TextStyle style = fond.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final List<MarqueChrono> marques = <MarqueChrono>[
      ...?(widget.marques ?? PorteeMediaSalle.de(context)?.marques),
      ..._traces,
    ];
    final AlerteChrono? alerte = _alerte;
    final bool avecChrono = widget.avecChrono && vue.voitChrono;
    final bool deplie = alerte != null || _deplie;
    final Widget? micro = widget.microOuvert
        ? Semantics(
            key: DynamiqueChrono.cleMicroOuvert,
            container: true,
            label: t.salle.microOuvert,
            child: ExcludeSemantics(
              child: IconTheme(
                data: IconThemeData(
                  color: fond.onBackground,
                  size: AppSpacing.lg,
                ),
                child: Icon(AppIcons.micro.repos),
              ),
            ),
          )
        : null;
    if (!avecChrono && marques.isEmpty && micro == null && alerte == null) {
      return const SizedBox.shrink();
    }

    final Widget contenu = KeyedSubtree(
      key: _cleContenu,
      child: avecChrono
          ? ChronoSalle(
              bornes: vue.chrono!,
              connexion: vue.connexion,
              pause: vue.pause,
              onPause: widget.onPause,
              echecPause: vue.echecPause,
              style: style,
              garderCouleur: true,
              surfaceCapsule: fond,
              dansUnePilule: true,
              sobre: !vue.conduitLaSeance,
              sonne: vue.conduitLaSeance,
              onEtat: widget.onEtatChrono,
              marques: marques,
              deplie: deplie,
              onBasculer: alerte == null ? _basculer : null,
              libelleBasculer: deplie
                  ? t.salle.ile.replierEtat
                  : t.salle.ile.deplierEtat,
              signes: <Widget>[?micro],
            )
          // Sans chrono (Interface guidee, bornes inconnues) : les marques en
          // clair, une ile vide ne dirait rien.
          : Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (final MarqueChrono m in marques)
                  Semantics(
                    container: true,
                    label: m.annonce,
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox.square(
                            dimension: StatusPill.diametrePastille,
                            child: DecoratedBox(
                              decoration: palette.pastilleDe(m.ton),
                            ),
                          ),
                          Ecart.hSm,
                          Flexible(child: Text(m.libelle, style: style)),
                        ],
                      ),
                    ),
                  ),
                ?micro,
              ],
            ),
    );

    Widget capsule(Widget enfant, {Key? cle, bool cernee = false}) => IleLiquide(
      key: cle,
      decoration: cernee
          ? AppElevation.avecFilet(
              surface: fond,
              filet: palette.borderStrong,
              ombre: palette.ombre,
              arrondi: AppRadius.arrondiLg,
              ombres: AppElevation.niveau2(palette.ombre),
            )
          : fond.decoration(borderRadius: AppRadius.arrondiLg),
      alignement: AlignmentDirectional.topStart,
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        end: AppSpacing.md,
        top: avecChrono ? 0 : AppSpacing.md,
        bottom: avecChrono && !deplie ? 0 : AppSpacing.md,
      ),
      child: enfant,
    );

    // Depliee : l'alerte (s'il y en a une) puis le contenu.
    Widget depliee() => Column(
      key: DynamiqueChrono.cleDepliee,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (alerte != null)
          Padding(
            key: DynamiqueChrono.cleAlerte,
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alerte.titre,
                    style: fond.applyTo(
                      Theme.of(context).textTheme.titleSmall ??
                          const TextStyle(),
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.md,
                    children: <Widget>[
                      for (final ActionAlerteChrono a in alerte.actions)
                        LienFleche(
                          libelle: a.libelle,
                          fleche: false,
                          onPress: () {
                            a.onPress();
                            _fermerAlerte(alerte);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        contenu,
      ],
    );

    final double largeur = widget.largeurMax;
    final bool enPlace = widget.enPlace;

    // Telephone et tablette (et colonne trop serree) : la place reste celle
    // de la barre repliee ; la barre depliee passe un instant par-dessus le
    // haut du contenu. Le coin de debut de la barre (a droite en arabe)
    // reste en place. Le portail existe toujours (la structure ne change
    // pas quand la place change) ; il ne montre rien hors de ce cas.
    final Alignment ancre = AlignmentDirectional.topStart.resolve(
      Directionality.of(context),
    );
    final Size? place = _tailleRepliee;
    return OverlayPortal(
      controller: _portail,
      overlayChildBuilder: (BuildContext _) => !deplie || enPlace
          ? const SizedBox.shrink()
          : Align(
              alignment: AlignmentDirectional.topStart,
              child: CompositedTransformFollower(
                link: _lien,
                showWhenUnlinked: false,
                targetAnchor: ancre,
                followerAnchor: ancre,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: largeur),
                  child: Material(
                    type: MaterialType.transparency,
                    child: capsule(depliee(), cernee: true),
                  ),
                ),
              ),
            ),
      child: CompositedTransformTarget(
        link: _lien,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largeur),
          child: enPlace
              ? capsule(deplie ? depliee() : contenu, cle: widget.cle)
              : deplie
              ? SizedBox(
                  key: widget.cle,
                  width: place?.width,
                  height: place?.height ?? AppSpacing.titreEcran,
                )
              : KeyedSubtree(
                  key: _cleRepliee,
                  child: capsule(contenu, cle: widget.cle),
                ),
        ),
      ),
    );
  }
}

/// Le mot d'etat du lien (« En salle », « En ligne », « Reconnexion... ») et
/// la mention permanente « Visite de controle possible. » (ADR-011) : dans la
/// zone reservee de la Dynamique chrono, jamais repliees, jamais sur la page.
/// La mention n'est jamais rendue au controleur (la vue n'en a pas).
class LigneEtatSalle extends StatelessWidget {
  const LigneEtatSalle({required this.vue, super.key});

  final VueSeance vue;

  /// La cle de la ligne (tests de geometrie).
  static const Key cle = ValueKey<String>('ligne-etat-salle');

  /// La cle du mot d'etat (tests).
  static const Key cleMot = ValueKey<String>('ligne-etat-salle-mot');

  /// Le mot d'etat : « En salle » quand la presence est confirmee, sinon
  /// l'etat de la connexion (« En ligne », « Reconnexion… », image coupee).
  static String motDe(BuildContext context, VueSeance vue) {
    final bool enSalle =
        (PorteeMediaSalle.de(context)?.presenceEnSalle ?? false) &&
        vue.connexion.etablie &&
        // RESEAU-ELEVES : une situation de reseau passe avant « En salle ».
        !vue.reseauADire;
    return enSalle ? t.presence.presente : vue.texteConnexion;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final String mot = motDe(context, vue);
    // Jamais la couleur seule : un disque quand le lien tient, l'icone
    // d'avertissement sinon ; le mot a cote.
    final Widget signe = vue.connexion.etablie
        ? SizedBox.square(
            dimension: AppSpacing.sm,
            child: DecoratedBox(
              decoration: palette.pointsStatut.succes.pastille(),
            ),
          )
        : IconTheme(
            data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
            child: Icon(AppIcons.avertissement.repos),
          );
    return Wrap(
      key: cle,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          container: true,
          liveRegion: true,
          label: mot,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                signe,
                Ecart.hSm,
                Flexible(
                  child: FonduLiquide(
                    cle: mot,
                    child: Text(mot, key: cleMot, style: style),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (vue.texteMention != null)
          MentionSeance(vue: vue, lienSousLaLigne: false),
      ],
    );
  }
}

/// La zone reservee de la Dynamique chrono : la barre, puis le mot d'etat et
/// la mention permanente, sur la meme rangee quand la largeur le permet,
/// sinon sur une seconde ligne fine. Elle a sa place dans la mise en page :
/// rien ne passe dessous, elle ne passe sur rien (repliee).
class ZoneChrono extends StatelessWidget {
  const ZoneChrono({
    required this.vue,
    required this.largeur,
    this.onPause,
    this.onEtatChrono,
    this.microOuvert = false,
    this.enPlace = false,
    this.avecChrono = true,
    this.avecLigneEtat = true,
    this.cleBarre = const ValueKey<String>('ligne-etat-telephone'),
    super.key,
  });

  /// Faux : le mot d'etat et la mention sont poses ailleurs, dans une autre
  /// rangee reservee (colonne de l'ordinateur trop serree).
  final bool avecLigneEtat;

  final VueSeance vue;

  /// La largeur disponible (marges exclues).
  final double largeur;
  final VoidCallback? onPause;
  final ValueChanged<EtatChronoVivant>? onEtatChrono;
  final bool microOuvert;
  final bool enPlace;
  final bool avecChrono;

  /// La cle de la barre elle-meme.
  final Key cleBarre;

  /// La cle de la zone (tests de geometrie).
  static const Key cle = ValueKey<String>('zone-chrono');

  @override
  Widget build(BuildContext context) => SizedBox(
    key: cle,
    width: largeur,
    child: Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        DynamiqueChrono(
          vue: vue,
          largeurMax: largeur,
          cle: cleBarre,
          avecChrono: avecChrono,
          onPause: onPause,
          onEtatChrono: onEtatChrono,
          microOuvert: microOuvert,
          enPlace: enPlace,
        ),
        if (avecLigneEtat) LigneEtatSalle(vue: vue),
      ],
    ),
  );
}
