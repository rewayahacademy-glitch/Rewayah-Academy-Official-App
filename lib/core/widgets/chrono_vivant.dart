// CHRONO-ETAT (directeur, 10 et 11/11/2026, `docs/current/CAHIER-SALLE.md` §8) :
// le chrono de la salle, visible et vivant.
//
// - Il montre ce qui reste, avec son mot (« Reste 56:44 », directeur,
//   12/11/2026, DYNAMIQUE-CHRONO-1), dans une capsule, avec un anneau qui se
//   remplit a mesure que la seance avance.
// - A cinq minutes de la fin, la capsule change de teinte : c'est le moment de
//   conclure.
// - A zero, il continue en croissant (« Apres la fin +03:12 ») tant que le depassement regle
//   par la direction n'est pas epuise ([ChronoSeance.enDepassement]) ; ensuite
//   il dit que le temps prevu est ecoule.
// - Chaque chiffre qui change roule (le nouveau monte, l'ancien s'efface),
//   comme le texte numerique d'iOS ; chaque changement d'etat donne a la
//   capsule un pouls liquide (ILE-SALLE, 11/11/2026) : elle part un peu plus
//   petite, sa largeur revient la premiere sur le ressort raide de l'effet
//   liquide ([AppMouvement.ressortGoutteTete]), sa hauteur suit sur le souple
//   ([AppMouvement.ressortGoutteQueue]). Elle s'etire, puis se reforme.
//   **Aucun rebond** : amortissement critique, comme la barre de navigation
//   (le ressort a rebond du 10/11 est retire).
//
// Ce composant ne compte rien : il dessine le [ChronoSeance] qu'on lui donne.
// Le temps reste recalcule depuis les horodatages du serveur par l'appelant
// (`ChronoSalle`). Il ne sonne pas non plus : il previent par [onEtat], et
// l'appelant decide qui entend quoi.
//
// Mouvement reduit (reglage de l'appareil) : aucun roulement, aucun ressort ;
// les chiffres et la teinte changent d'un coup. L'information reste entiere.
// Lecteur d'ecran : un seul noeud, annonce par l'appelant (une fois par
// minute, pas par seconde).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../tc_horloge/chrono_seance.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Ou en est le chrono, pour l'oeil.
enum EtatChronoVivant {
  /// La seance avance, rien ne presse.
  calme,

  /// Il reste [ChronoVivant.seuilBientot] ou moins : il faut conclure.
  bientot,

  /// La fin prevue est passee, le depassement autorise court.
  depassement,

  /// Le depassement autorise est epuise.
  fini,
}

/// Le chrono de la salle : une capsule, le temps restant, un anneau.
class ChronoVivant extends StatefulWidget {
  /// Cree le chrono pour [chrono].
  const ChronoVivant({
    required this.chrono,
    required this.annonce,
    required this.libelleFini,
    this.surface,
    this.seuilBientot = const Duration(minutes: 5),
    this.sobre = false,
    this.dansUnePilule = false,
    this.onEtat,
    this.libelleReste,
    this.libelleApresFin,
    this.uneLigne = false,
    super.key,
  });

  /// DYNAMIQUE-CHRONO-1 : vrai dans la Dynamique chrono, ou la ligne entiere
  /// se reduit d'un bloc plutot que de passer a la ligne (aucun element
  /// flexible : la ligne est mesuree sans borne).
  final bool uneLigne;

  /// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026 : « ajouter un mot au chrono,
  /// Reste 37:51 ») : le mot visible devant le temps restant. `null` : les
  /// chiffres seuls (planches anciennes).
  final String? libelleReste;

  /// Le mot visible devant le depassement (« Apres la fin +03:12 ») : il
  /// garde le sens de l'annonce (seance toujours en direct apres la fin
  /// prevue). `null` : le plus seul.
  final String? libelleApresFin;

  /// La cle du mot visible devant les chiffres (tests).
  static const Key cleMot = ValueKey<String>('chrono-vivant-mot');

  /// Le chrono loge deja dans une pilule (celle de l'etat de la salle) : au
  /// calme, il n'a ni fond ni marge a lui, pour ne pas faire une capsule dans
  /// une capsule ; quand la fin approche ou est passee, sa propre capsule
  /// teintee apparait.
  final bool dansUnePilule;

  /// Sans teinte d'urgence : la capsule garde sa surface quand la fin
  /// approche et pendant le depassement. Pour qui ne conduit pas la seance
  /// (l'eleve) : tenir l'heure n'est pas son affaire, et une alerte rouge lui
  /// mettrait une pression inutile. Les chiffres, eux, disent la meme chose
  /// a tous.
  final bool sobre;

  /// L'etat de la seance a cet instant (fonction pure des horodatages).
  final ChronoSeance chrono;

  /// Ce que lit le lecteur d'ecran (en minutes : une annonce par minute).
  final String annonce;

  /// Le texte dit quand le depassement autorise est epuise.
  final String libelleFini;

  /// La paire de la capsule au calme ; `null` : la surface relevee du theme.
  /// Les etats pressants prennent les lavis d'attention et d'alerte.
  final AppColorPair? surface;

  /// Le temps restant sous lequel le chrono dit qu'il faut conclure.
  final Duration seuilBientot;

  /// Appele quand le chrono change d'etat, jamais a la premiere construction :
  /// l'appelant y branche le signal sonore de qui dirige la seance.
  final ValueChanged<EtatChronoVivant>? onEtat;

  /// La cle de la capsule (tests, captures).
  static const Key cleCapsule = ValueKey<String>('chrono-vivant-capsule');

  /// La cle des chiffres (tests).
  static const Key cleChiffres = ValueKey<String>('chrono-vivant-chiffres');

  /// L'etat que [chrono] donne a voir.
  static EtatChronoVivant etatDe(ChronoSeance chrono, Duration seuilBientot) {
    if (chrono.prevuEcoule) return EtatChronoVivant.fini;
    if (chrono.enDepassement) return EtatChronoVivant.depassement;
    return chrono.restant <= seuilBientot
        ? EtatChronoVivant.bientot
        : EtatChronoVivant.calme;
  }

  /// Les chiffres que [chrono] donne a lire : le reste, puis le depassement
  /// precede d'un plus.
  static String chiffresDe(ChronoSeance chrono) => chrono.finPrevueAtteinte
      ? '+${formaterChronoCourt(chrono.depasse)}'
      : formaterChronoCourt(chrono.restant);

  @override
  State<ChronoVivant> createState() => _ChronoVivantEtat();
}

class _ChronoVivantEtat extends State<ChronoVivant>
    with TickerProviderStateMixin {
  /// L'echelle de la capsule : 1 au repos, elle part d'un peu moins a
  /// l'entree et a chaque changement d'etat. [_souffle] porte la largeur (le
  /// bord de devant, raide), [_suite] la hauteur (le bord de derriere, qui
  /// suit) : la capsule s'etire puis se reforme, sans jamais depasser 1.
  late final AnimationController _souffle = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _suite = AnimationController(
    vsync: this,
    value: 1,
  );

  static const double _echelleEntree = 0.7;
  static const double _echelleChangement = 0.88;

  EtatChronoVivant get _etat =>
      ChronoVivant.etatDe(widget.chrono, widget.seuilBientot);

  bool _entree = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entree) {
      _entree = false;
      _respirer(_echelleEntree);
    }
  }

  @override
  void didUpdateWidget(ChronoVivant ancien) {
    super.didUpdateWidget(ancien);
    final EtatChronoVivant avant = ChronoVivant.etatDe(
      ancien.chrono,
      ancien.seuilBientot,
    );
    if (avant != _etat) {
      _respirer(_echelleChangement);
      widget.onEtat?.call(_etat);
    }
  }

  /// Fait repartir la capsule de [depuis] vers sa taille : la largeur sur le
  /// ressort raide, la hauteur sur le souple. Bornes 0 a 1 : jamais au-dela
  /// de la taille, donc aucun rebond.
  void _respirer(double depuis) {
    if (AppMouvement.mouvementReduit(context)) {
      _souffle.value = 1;
      _suite.value = 1;
      return;
    }
    _souffle.animateWith(
      SpringSimulation(AppMouvement.ressortGoutteTete, depuis, 1, 0),
    );
    _suite.animateWith(
      SpringSimulation(AppMouvement.ressortGoutteQueue, depuis, 1, 0),
    );
  }

  @override
  void dispose() {
    _souffle.dispose();
    _suite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final EtatChronoVivant etat = _etat;
    final AppColorPair calme = widget.surface ?? palette.surfaceRaised;
    final AppColorPair paire = widget.sobre
        ? calme
        : switch (etat) {
            EtatChronoVivant.calme => calme,
            EtatChronoVivant.bientot => palette.washWarning,
            EtatChronoVivant.depassement ||
            EtatChronoVivant.fini => palette.washAlert,
          };
    // Dans une pilule, au calme : ni fond ni marge (la pilule les porte).
    final bool nu = widget.dansUnePilule && identical(paire, calme);
    final TextStyle style = paire.applyTo(
      (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
    final ChronoSeance chrono = widget.chrono;
    final double avancement = chrono.finPrevueAtteinte
        ? 1
        : chrono.duree.inMilliseconds <= 0
        ? 0
        : (1 - chrono.restant.inMilliseconds / chrono.duree.inMilliseconds)
              .clamp(0, 1)
              .toDouble();
    final Duration fondu = AppMouvement.duree(context, AppMouvement.navigation);
    final Widget contenu = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.square(
          dimension: AppSpacing.xl,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: avancement),
            duration: fondu,
            builder: (BuildContext _, double valeur, Widget? _) => CustomPaint(
              painter: _Anneau(avancement: valeur, couleur: paire.onBackground),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (etat == EtatChronoVivant.fini)
          // [uneLigne] (la Dynamique chrono) : une ligne, toujours ; la ligne
          // entiere de la barre se reduit d'un bloc (`ChronoSalle`). Sinon,
          // texte agrandi ou place etroite : la phrase passe a la ligne, elle
          // ne deborde jamais.
          widget.uneLigne
              ? Text(
                  widget.libelleFini,
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                )
              : Flexible(child: Text(widget.libelleFini, style: style))
        else ...<Widget>[
          if (chrono.finPrevueAtteinte
                  ? widget.libelleApresFin
                  : widget.libelleReste
              case final String mot) ...<Widget>[
            Text(
              mot,
              key: ChronoVivant.cleMot,
              maxLines: 1,
              softWrap: false,
              // Le mot, plus discret que les chiffres (c'est eux qu'on cherche
              // de l'oeil) : la taille des libelles, la meme encre.
              style: paire.applyTo(
                Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          _ChiffresRoulants(
            key: ChronoVivant.cleChiffres,
            texte: ChronoVivant.chiffresDe(chrono),
            style: style,
          ),
        ],
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.annonce,
      child: ExcludeSemantics(
        child: ScaleTransition(
          scale: _souffle,
          // Le bord de derriere : la hauteur rattrape la largeur.
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_souffle, _suite]),
            builder: (BuildContext _, Widget? capsule) => Transform.scale(
              scaleY: _souffle.value <= 0 ? 1 : _suite.value / _souffle.value,
              child: capsule,
            ),
            child: AnimatedContainer(
              key: ChronoVivant.cleCapsule,
              duration: fondu,
              curve: AppMouvement.selection,
              decoration: nu
                  ? const BoxDecoration(borderRadius: AppRadius.arrondiFull)
                  : paire.decoration(borderRadius: AppRadius.arrondiFull),
              padding: nu
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
              // La capsule change de largeur quand les chiffres en gagnent ou
              // en perdent un (59:59, 1:00:00, +00:01) : elle s'etire au lieu
              // de sauter. Sous reduction du mouvement, elle change d'un coup
              // (et `AnimatedSize` ne supporte pas une duree nulle).
              child: fondu == Duration.zero
                  ? contenu
                  : AnimatedSize(
                      duration: fondu,
                      curve: AppMouvement.entree,
                      alignment: AlignmentDirectional.centerStart,
                      child: contenu,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les chiffres du chrono : chacun roule quand il change. Toujours de gauche
/// a droite, en arabe aussi (ce sont des chiffres, pas une phrase).
class _ChiffresRoulants extends StatelessWidget {
  const _ChiffresRoulants({
    required this.texte,
    required this.style,
    super.key,
  });

  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Duration duree = AppMouvement.duree(context, AppMouvement.apparition);
    final double course = AppMouvement.translation(context, 1);
    final int n = texte.length;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < n; i++)
            // La place se compte depuis la droite : les secondes gardent leur
            // case quand une heure ou un plus arrive devant.
            AnimatedSwitcher(
              key: ValueKey<int>(n - i),
              duration: duree,
              switchInCurve: AppMouvement.entree,
              switchOutCurve: AppMouvement.sortie,
              transitionBuilder: (Widget enfant, Animation<double> a) =>
                  ClipRect(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, course * 0.6),
                        end: Offset.zero,
                      ).animate(a),
                      child: FadeTransition(opacity: a, child: enfant),
                    ),
                  ),
              child: Text(
                texte[i],
                key: ValueKey<String>(texte[i]),
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

/// L'anneau d'avancement : une piste pale, un arc plein qui part du haut.
class _Anneau extends CustomPainter {
  const _Anneau({required this.avancement, required this.couleur});

  final double avancement;
  final Color couleur;

  static const double _epaisseur = 3;
  static const double _opacitePiste = 0.24;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double rayon = (math.min(size.width, size.height) - _epaisseur) / 2;
    final Paint piste = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _epaisseur
      ..color = couleur.withValues(alpha: _opacitePiste);
    canvas.drawCircle(centre, rayon, piste);
    if (avancement <= 0) return;
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _epaisseur
      ..color = couleur;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon),
      -math.pi / 2,
      2 * math.pi * avancement,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_Anneau ancien) =>
      ancien.avancement != avancement || ancien.couleur != couleur;
}
