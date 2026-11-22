// ONBOARDING-PRAXIS (directeur, 22/11/2026 ; maquette validee
// `docs/current/maquettes/onboarding-praxis/prototype.html`) : l'habillage
// commun de chaque ecran du questionnaire avant le compte, de l'acces et de la
// demande apres la connexion.
//
// En haut : le retour, le chapitre (« 2/4 · Ou en est le niveau ») et la
// barre de progression en quatre segments, un par chapitre. Puis la scene de
// Praxis : lui (le seul Praxis de l'application, `PraxisVivant`, employe
// sans le modifier) et sa bulle, ou ses mots apparaissent un a un. Puis le
// titre, la phrase, le corps, et en bas le bouton, les liens et l'indice.
//
// Telephone (moins de 840 points) : une colonne, la page defile. Ordinateur :
// deux colonnes bornees (jamais une carte de telephone etiree) : Praxis et sa
// bulle au debut de ligne, la question et ses reponses a cote.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../../core/accessibilite/mode_accessibilite.dart';
import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_mouvement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/vivant/entree/gestes_praxis.dart';
import '../../../core/vivant/entree/lumiere_entree.dart' show Teinte;
import '../../../core/vivant/entree/praxis_reference.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/entete_page.dart' show DisqueRetour;
import '../../../core/widgets/page_shell.dart';
import 'questionnaire_inscription.dart' show Chapitre;

/// L'expression de Praxis, dans les mots de la maquette ; chacune se rend
/// par une humeur du dessin de l'application.
enum ExpressionPraxis {
  /// Au repos, il attend une reponse.
  attente,

  /// Un leger sourire.
  sourire,

  /// La joie : grand sourire, mains levees.
  joie,

  /// Il reflechit ou se concentre.
  reflexion,

  /// Il s'etonne (« Ma cha' Allah »).
  etonne,

  /// Il se concentre.
  concentre;

  /// Le visage du Praxis de reference.
  Expr get visage => switch (this) {
    ExpressionPraxis.attente => Expr.attente,
    ExpressionPraxis.sourire => Expr.sourire,
    ExpressionPraxis.joie => Expr.joie,
    ExpressionPraxis.reflexion => Expr.reflexion,
    ExpressionPraxis.etonne => Expr.etonne,
    ExpressionPraxis.concentre => Expr.concentre,
  };
}

/// La largeur au-dela de laquelle la page passe en deux colonnes.
const double seuilDeuxColonnesOnboarding = AppGabarit.seuilEtendu;

/// La largeur totale bornee des deux colonnes sur ordinateur.
const double largeurOnboardingBureau = 1040;

/// La largeur de la colonne de Praxis sur ordinateur.
const double largeurSceneBureau = 360;

/// L'habillage d'un ecran de l'onboarding.
class CoquilleOnboarding extends StatelessWidget {
  /// Cree l'ecran.
  const CoquilleOnboarding({
    required this.phrase,
    required this.corps,
    super.key,
    this.chapitre,
    this.remplissage = const <double>[0, 0, 0, 0],
    this.onRetour,
    this.expression = ExpressionPraxis.attente,
    this.geste = Geste.aucun,
    this.grand = false,
    this.titre,
    this.sousTitre,
    this.action,
    this.liens = const <Widget>[],
    this.indice,
  });

  /// Le chapitre courant ; `null` : ni chapitre ni barre (l'accueil, la
  /// branche « Enseigner »).
  final Chapitre? chapitre;

  /// Le remplissage des quatre segments, de 0 a 1.
  final List<double> remplissage;

  /// Le retour ; `null` : pas de disque.
  final VoidCallback? onRetour;

  /// Ce que Praxis dit.
  final String phrase;

  /// Son expression.
  final ExpressionPraxis expression;

  /// Son geste (la maquette : salut, montrer, main sur le coeur...).
  final Geste geste;

  /// Vrai pour un interlude : Praxis en grand, la bulle centree dessous.
  final bool grand;

  /// Le titre de l'ecran.
  final String? titre;

  /// La phrase sous le titre.
  final String? sousTitre;

  /// Les reponses, les panneaux.
  final List<Widget> corps;

  /// Le bouton plein, en bas (un seul par ecran).
  final Widget? action;

  /// Les liens discrets sous le bouton.
  final List<Widget> liens;

  /// L'indice en petit, tout en bas.
  final String? indice;

  /// La cle de la bulle de Praxis.
  static const Key cleBulle = ValueKey<String>('onboarding-bulle');

  /// La cle de la barre des chapitres.
  static const Key cleBarre = ValueKey<String>('onboarding-barre');

  @override
  Widget build(BuildContext context) => PageShell(
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double facteur = MediaQuery.textScalerOf(context).scale(1);
        final bool bureau = c.maxWidth / facteur >= seuilDeuxColonnesOnboarding;
        return bureau ? _bureau(context) : _telephone(context);
      },
    ),
  );

  Widget _tete() =>
      _Tete(chapitre: chapitre, remplissage: remplissage, onRetour: onRetour);

  Widget _contenu(BuildContext context, {required bool bureau}) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (titre case final String t) ...<Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              t,
              key: const ValueKey<String>('onboarding-titre'),
              style:
                  (bureau ? textes.headlineMedium : textes.headlineSmall) ??
                  const TextStyle(),
            ),
          ),
          Ecart.vXs,
        ],
        if (sousTitre case final String s) ...<Widget>[
          TexteSansCoupure(
            s,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
        ],
        if (titre != null || sousTitre != null) Ecart.vSm,
        ...corps,
        Ecart.vXl,
        if (action case final Widget a)
          Align(
            alignment: bureau
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.center,
            child: bureau ? a : SizedBox(width: double.infinity, child: a),
          ),
        for (final Widget l in liens) ...<Widget>[Ecart.vSm, Center(child: l)],
        if (indice case final String i) ...<Widget>[
          Ecart.vSm,
          Text(
            i,
            key: const ValueKey<String>('onboarding-indice'),
            textAlign: TextAlign.center,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vXl,
      ],
    );
  }

  Widget _telephone(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _tete(),
      Ecart.vLg,
      _ScenePraxis(
        phrase: phrase,
        expression: expression,
        geste: geste,
        grand: grand,
        bureau: false,
        taille: grand ? 150 : 96,
      ),
      Ecart.vLg,
      _contenu(context, bureau: false),
    ],
  );

  Widget _bureau(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: largeurOnboardingBureau),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _tete(),
          Ecart.vXxxl,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: largeurSceneBureau,
                child: _ScenePraxis(
                  phrase: phrase,
                  expression: expression,
                  geste: geste,
                  grand: true,
                  bureau: true,
                  taille: grand ? 200 : 160,
                ),
              ),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPage.largeurFormulaire,
                    ),
                    child: _contenu(context, bureau: true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Le haut : retour, chapitre, barre des quatre chapitres.
class _Tete extends StatelessWidget {
  const _Tete({
    required this.chapitre,
    required this.remplissage,
    required this.onRetour,
  });

  final Chapitre? chapitre;
  final List<double> remplissage;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Chapitre? ch = chapitre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (onRetour case final VoidCallback r)
              DisqueRetour(onPress: r)
            else
              const SizedBox(height: AppTouchTarget.standard),
            Ecart.hMd,
            Expanded(
              child: ch == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      label: t.onboarding.chapitres.luLong(
                        n: ch.index + 1,
                        nom: nomChapitre(ch),
                      ),
                      excludeSemantics: true,
                      child: Text(
                        t.onboarding.chapitres.lu(
                          n: ch.index + 1,
                          nom: nomChapitre(ch),
                        ),
                        key: const ValueKey<String>('onboarding-chapitre'),
                        textAlign: TextAlign.end,
                        style: palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        // La barre est toujours la (vide sur l'accueil et la branche
        // « Enseigner »), comme la maquette.
        ...<Widget>[
          Ecart.vSm,
          ExcludeSemantics(
            child: Row(
              key: CoquilleOnboarding.cleBarre,
              children: <Widget>[
                for (final (int i, double r)
                    in remplissage.indexed) ...<Widget>[
                  if (i > 0) Ecart.hXs,
                  Expanded(child: _Segment(remplissage: r)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Le nom d'un chapitre.
String nomChapitre(Chapitre c) => switch (c) {
  Chapitre.quiApprend => t.onboarding.chapitres.quiApprend,
  Chapitre.niveau => t.onboarding.chapitres.niveau,
  Chapitre.cours => t.onboarding.chapitres.cours,
  Chapitre.demande => t.onboarding.chapitres.demande,
};

class _Segment extends StatelessWidget {
  const _Segment({required this.remplissage});

  final double remplissage;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool reduit = EffetsReduits.de(context);
    return ClipRRect(
      borderRadius: AppRadius.arrondiFull,
      child: SizedBox(
        height: AppSpacing.sm,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(color: palette.surfaceSunken.background),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: remplissage.clamp(0, 1)),
              duration: reduit ? Duration.zero : AppMouvement.descente,
              curve: AppMouvement.entree,
              builder: (BuildContext context, double v, Widget? _) =>
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: v,
                    child: ColoredBox(color: palette.surfacePrimary.background),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Praxis et sa bulle.
class _ScenePraxis extends StatelessWidget {
  const _ScenePraxis({
    required this.phrase,
    required this.expression,
    required this.geste,
    required this.bureau,
    required this.grand,
    required this.taille,
  });

  final String phrase;
  final ExpressionPraxis expression;
  final Geste geste;
  final bool bureau;
  final bool grand;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final Widget praxis = PraxisGuide(
      expression: expression.visage,
      geste: geste,
      phrase: phrase,
      taille: taille,
      viseDeCote: bureau,
    );
    final Widget bulle = BullePraxis(phrase: phrase, centree: grand);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // A texte agrandi sur un petit ecran, la bulle a cote de Praxis
        // couperait des mots : Praxis passe au-dessus d'elle.
        final double facteur = MediaQuery.textScalerOf(context).scale(1);
        final bool empile = grand || c.maxWidth / facteur < largeurBulleACote;
        return _disposer(praxis, bulle, empile: empile);
      },
    );
  }

  /// La largeur utile sous laquelle la bulle passe sous Praxis.
  static const double largeurBulleACote = 300;

  Widget _disposer(Widget praxis, Widget bulle, {required bool empile}) {
    if (empile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(child: praxis),
          Ecart.vLg,
          bulle,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        praxis,
        Ecart.hMd,
        Expanded(child: bulle),
      ],
    );
  }
}

/// Praxis guide : le Praxis de reference en volume (`Corps` et
/// `peindrePraxis`, `lib/core/vivant/entree/praxis_reference.dart`, le meme
/// que la page d'entree ; aucun nouveau dessin), avec le visage ([Expr]) et le
/// geste ([Geste]) de la maquette a chaque ecran (directeur, 22/11/2026 :
/// « il faut ajouter les gestes »). Il joue son geste un moment, puis se pose
/// et plus aucune image n'est produite ; une phrase ou un geste nouveau le
/// reveille. Sous « Reduire les effets », il est pose d'emblee, sans
/// mouvement, le geste visible (les mains a leur place).
class PraxisGuide extends StatefulWidget {
  /// Cree Praxis.
  const PraxisGuide({
    required this.expression,
    required this.geste,
    required this.phrase,
    required this.taille,
    super.key,
    this.viseDeCote = false,
  });

  /// Son visage.
  final Expr expression;

  /// Son geste.
  final Geste geste;

  /// Ce qu'il dit : une phrase nouvelle le reveille.
  final String phrase;

  /// Sa largeur.
  final double taille;

  /// Vrai quand les reponses sont a cote de lui (ordinateur) : il montre de
  /// ce cote, sinon vers le bas.
  final bool viseDeCote;

  /// Combien de temps il joue avant de se poser.
  static const Duration momentEveille = Duration(seconds: 4);

  /// La cle du dessin, pour les tests.
  static const Key cle = ValueKey<String>('onboarding-praxis');

  /// La hauteur du dessin pour une largeur [taille] (la toque et une main
  /// levee comprises).
  static double hauteurPour(double taille) => taille * 1.2;

  @override
  State<PraxisGuide> createState() => _EtatPraxisGuide();
}

class _EtatPraxisGuide extends State<PraxisGuide>
    with SingleTickerProviderStateMixin {
  final Corps _corps = Corps();
  late final Ticker _horloge = createTicker(_image);
  Duration _avant = Duration.zero;
  double _joue = 0;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _corps.placer(1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jouer();
  }

  @override
  void didUpdateWidget(PraxisGuide ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.phrase != widget.phrase ||
        ancien.expression != widget.expression ||
        ancien.geste != widget.geste ||
        ancien.viseDeCote != widget.viseDeCote) {
      _jouer();
    }
  }

  void _jouer() {
    final bool reduit = EffetsReduits.de(context);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    _corps
      ..reduit = reduit
      ..vise = widget.viseDeCote
          ? Offset(rtl ? -0.92 : 0.92, 0.38)
          : const Offset(0, 1)
      ..poser(widget.expression)
      ..faire(widget.geste);
    if (widget.geste == Geste.pointe) _corps.montrer();
    _joue = 0;
    if (reduit) {
      // Pose d'emblee : les ressorts vont a leur place sans horloge.
      _horloge.stop();
      for (int i = 0; i < 90; i++) {
        _corps.pas(1 / 60);
      }
      _version++;
      return;
    }
    _avant = Duration.zero;
    if (!_horloge.isActive) _horloge.start();
  }

  void _image(Duration d) {
    final double dt = _avant == Duration.zero
        ? 1 / 60
        : (d - _avant).inMicroseconds / 1e6;
    _avant = d;
    _corps.pas(dt.clamp(0, 0.05));
    _joue += dt;
    setState(() => _version++);
    if (_joue >= PraxisGuide.momentEveille.inMicroseconds / 1e6) {
      _horloge.stop();
    }
  }

  @override
  void dispose() {
    _horloge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    key: PraxisGuide.cle,
    child: SizedBox(
      width: widget.taille,
      height: PraxisGuide.hauteurPour(widget.taille),
      child: CustomPaint(painter: _PeintrePraxisGuide(_corps, _version)),
    ),
  );
}

class _PeintrePraxisGuide extends CustomPainter {
  _PeintrePraxisGuide(this.corps, this.version);

  final Corps corps;
  final int version;

  @override
  void paint(Canvas canvas, Size taille) {
    final double largeur = taille.width;
    // Le point du sol entre les pieds (100, 206 dans la boite de 200) ; la
    // marge du haut laisse la place a la toque et a une main levee.
    final Offset pied = Offset(largeur / 2, taille.height - largeur * 0.04);
    peindrePraxis(
      canvas,
      corps,
      pied,
      largeur,
      Eclairage(couleur: Teinte.coeur, dir: const Offset(-0.6, -0.8)),
    );
  }

  @override
  bool shouldRepaint(_PeintrePraxisGuide ancien) => ancien.version != version;
}

/// La bulle de Praxis : ses mots apparaissent un a un (rien ne bouge sous
/// « Reduire les effets »), et le lecteur d'ecran lit la phrase entiere.
class BullePraxis extends StatefulWidget {
  /// Cree la bulle.
  const BullePraxis({required this.phrase, super.key, this.centree = false});

  /// La phrase.
  final String phrase;

  /// Vrai : texte centre (interludes).
  final bool centree;

  @override
  State<BullePraxis> createState() => _EtatBullePraxis();
}

class _EtatBullePraxis extends State<BullePraxis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mots = AnimationController(vsync: this);

  List<String> get _liste => widget.phrase.split(' ');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jouer();
  }

  @override
  void didUpdateWidget(BullePraxis ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.phrase != widget.phrase) _jouer();
  }

  void _jouer() {
    if (EffetsReduits.de(context)) {
      _mots.value = 1;
      return;
    }
    final int n = _liste.length;
    _mots
      ..duration = AppMouvement.echelon * n + AppMouvement.fonduEntree
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _mots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final List<String> mots = _liste;
    return AppCard(
      key: CoquilleOnboarding.cleBulle,
      surface: palette.surfaceRaised,
      child: Semantics(
        liveRegion: true,
        label: widget.phrase,
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _mots,
          builder: (BuildContext context, Widget? _) {
            final double total =
                (AppMouvement.echelon * mots.length + AppMouvement.fonduEntree)
                    .inMicroseconds
                    .toDouble();
            final double ecoule = _mots.value * total;
            return Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  for (final (int i, String m) in mots.indexed)
                    TextSpan(
                      text: i == mots.length - 1 ? m : '$m ',
                      style: style.copyWith(
                        color: style.color?.withValues(
                          alpha:
                              ((ecoule -
                                          AppMouvement.echelon.inMicroseconds *
                                              i) /
                                      AppMouvement.fonduEntree.inMicroseconds)
                                  .clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                ],
              ),
              textAlign: widget.centree ? TextAlign.center : TextAlign.start,
            );
          },
        ),
      ),
    );
  }
}
