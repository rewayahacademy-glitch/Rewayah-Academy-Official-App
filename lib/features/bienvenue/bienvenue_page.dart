// PUB-1 : la presentation publique, avant la connexion (decision deleguee du
// 05/10/2026, choix b : codee directement, fiche dans
// `docs/current/UX_REVIEW_PUB-1.md`).
//
// Cinq pages, une idee par page : le service (le Coran en classe, en visio),
// la classe stable a horaire fixe, l'enseignant attitre, le parcours selon le
// niveau, le suivi de la famille. Le visiteur arrive a la connexion en
// sachant a quel service il s'inscrit.
//
// Defilement automatique toutes les six secondes, avec une ligne d'etat qui
// se charge ; en pause tant qu'un doigt touche la page, que la souris la
// survole ou que le focus clavier y est ; jamais quand « reduire les
// animations » est actif ou qu'un lecteur d'ecran est ouvert. Un geste du
// visiteur (glissement, fleche, touche) lui rend la main : le defilement
// automatique s'arrete pour de bon. Il s'arrete aussi a la derniere page,
// sans boucler. Une croix, en haut, passe tout et mene a la connexion.
//
// Vue une seule fois par appareil (`presentationProvider`) : la croix et les
// boutons de la derniere page la notent, puis la racine mene a la connexion.
// Aucune donnee lue : l'etat de chargement est l'ecran de demarrage du
// routeur, le temps de lire l'appareil ; aucun etat vide ni d'erreur a dire
// (un stockage illisible montre la presentation, comme a la premiere visite).
// Hors ligne : le bandeau de `PageShell` ; le texte reste lisible.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/presentation_vue.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';

/// Le temps de lecture d'une page avant le passage automatique a la
/// suivante : six secondes, au milieu de la fourchette de 5 a 7 secondes
/// demandee par le directeur. Un rythme de lecture, pas une duree
/// d'animation : le passage lui-meme suit [AppMouvement.navigation].
const Duration rythmePresentation = Duration(seconds: 6);

/// Largeur maximale du contenu sur bureau (pictogramme et texte cote a cote).
const double _largeurBureau = 1040;

/// Largeur de la colonne unique sur telephone et tablette.
const double _largeurColonne = 460;

/// Une page de la presentation : un pictogramme, une idee, son explication.
@immutable
class _PagePresentation {
  const _PagePresentation({
    required this.cle,
    required this.icone,
    required this.titre,
    required this.texte,
  });

  final String cle;
  final AppIcon icone;
  final String Function() titre;
  final String Function() texte;
}

/// Les cinq pages, dans l'ordre de lecture. Textes tires de l'ancien accueil
/// public et de `docs/current/01_PRODUIT_ET_PARCOURS.md` : aucun prix, aucun
/// chiffre.
final List<_PagePresentation> _pagesPresentation = <_PagePresentation>[
  _PagePresentation(
    cle: 'service',
    icone: AppIcons.camera,
    titre: () => t.bienvenue.accroche,
    texte: () => t.bienvenue.phrase,
  ),
  _PagePresentation(
    cle: 'classe',
    icone: AppIcons.classes,
    titre: () => t.bienvenue.pointClasseTitre,
    texte: () => t.bienvenue.pointClasse,
  ),
  _PagePresentation(
    cle: 'enseignant',
    icone: AppIcons.profil,
    titre: () => t.bienvenue.pointEnseignantTitre,
    texte: () => t.bienvenue.pointEnseignant,
  ),
  _PagePresentation(
    cle: 'parcours',
    icone: AppIcons.livreOuvert,
    titre: () => t.bienvenue.pointParcoursTitre,
    texte: () => t.bienvenue.pointParcours,
  ),
  _PagePresentation(
    cle: 'foyer',
    icone: AppIcons.foyer,
    titre: () => t.bienvenue.pointFoyerTitre,
    texte: () => t.bienvenue.pointFoyer,
  ),
];

/// Le nombre de pages de la presentation (3 a 5, demande du directeur).
int get nombrePagesPresentation => _pagesPresentation.length;

/// La presentation publique avant la connexion (`/bienvenue`).
class BienvenuePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const BienvenuePage({super.key});

  @override
  ConsumerState<BienvenuePage> createState() => _BienvenuePageState();
}

class _BienvenuePageState extends ConsumerState<BienvenuePage>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  late final AnimationController _minuteur = AnimationController(
    vsync: this,
    duration: rythmePresentation,
  )..addStatusListener(_finDuMinuteur);

  int _index = 0;

  /// Le visiteur a pris la main (glissement, fleche, touche) : plus de
  /// defilement automatique pendant cette visite.
  bool _main = false;

  bool _touche = false;
  bool _survol = false;
  bool _focus = false;

  /// Le contexte interdit le defilement automatique (mouvement reduit,
  /// lecteur d'ecran).
  bool _automatiqueExclu = false;

  int get _derniere => _pagesPresentation.length - 1;

  bool get _automatique => !_main && !_automatiqueExclu;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _automatiqueExclu =
        AppMouvement.mouvementReduit(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _actualiser();
  }

  @override
  void dispose() {
    _minuteur.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Lance ou arrete le minuteur selon l'etat de la page.
  void _actualiser() {
    final bool enPause = _touche || _survol || _focus;
    if (_automatique && !enPause && !_minuteur.isCompleted) {
      unawaited(_minuteur.forward());
    } else {
      _minuteur.stop();
    }
  }

  void _finDuMinuteur(AnimationStatus statut) {
    if (statut != AnimationStatus.completed || !mounted) return;
    if (_index < _derniere) _aller(_index + 1, parLeVisiteur: false);
  }

  void _aller(int cible, {required bool parLeVisiteur}) {
    if (cible < 0 || cible > _derniere) return;
    if (parLeVisiteur) _main = true;
    final Duration duree = AppMouvement.duree(context, AppMouvement.navigation);
    setState(() => _index = cible);
    _minuteur.value = 0;
    if (_pages.hasClients) {
      if (duree == Duration.zero) {
        _pages.jumpToPage(cible);
      } else {
        unawaited(
          _pages.animateToPage(
            cible,
            duration: duree,
            curve: AppMouvement.entree,
          ),
        );
      }
    }
    _actualiser();
  }

  /// Le glissement du doigt a change la page.
  void _pageChangee(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _minuteur.value = 0;
    _actualiser();
  }

  /// Le visiteur fait glisser les pages (un toucher immobile n'en est pas
  /// un : c'est une pause) : il prend la main.
  bool _glissement(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.idle && !_main) {
      setState(() => _main = true);
      _actualiser();
    }
    return false;
  }

  void _pause({bool? touche, bool? survol, bool? focus}) {
    _touche = touche ?? _touche;
    _survol = survol ?? _survol;
    _focus = focus ?? _focus;
    _actualiser();
  }

  KeyEventResult _touches(FocusNode _, KeyEvent evenement) {
    if (evenement is! KeyDownEvent) return KeyEventResult.ignored;
    final bool arabe = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey touche = evenement.logicalKey;
    if (touche == LogicalKeyboardKey.arrowRight) {
      _aller(arabe ? _index - 1 : _index + 1, parLeVisiteur: true);
      return KeyEventResult.handled;
    }
    if (touche == LogicalKeyboardKey.arrowLeft) {
      _aller(arabe ? _index + 1 : _index - 1, parLeVisiteur: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// La croix et les boutons de la derniere page : la presentation est vue
  /// sur cet appareil, la connexion suit.
  void _terminer() {
    unawaited(ref.read(presentationProvider.notifier).marquerVue());
    GoRouter.of(context).go(Routes.connexion);
  }

  @override
  Widget build(BuildContext context) {
    final bool bureau =
        AppGabarit.de(context) != Gabarit.mobile &&
        MediaQuery.sizeOf(context).width >= 900;
    final int total = _pagesPresentation.length;
    final int numero = _index + 1;

    return PageShell(
      defilante: false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (bool focus) => _pause(focus: focus),
        onKeyEvent: _touches,
        child: MouseRegion(
          onEnter: (PointerEnterEvent _) => _pause(survol: true),
          onExit: (PointerExitEvent _) => _pause(survol: false),
          child: Listener(
            onPointerDown: (PointerDownEvent _) => _pause(touche: true),
            onPointerUp: (PointerUpEvent _) => _pause(touche: false),
            onPointerCancel: (PointerCancelEvent _) => _pause(touche: false),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: bureau ? _largeurBureau : _largeurColonne,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: MarquePage(),
                          ),
                        ),
                        Ecart.hSm,
                        BoutonIcone(
                          key: const ValueKey<String>('bienvenue-passer'),
                          icone: AppIcons.fermer,
                          libelle: t.bienvenue.passer,
                          onPress: _terminer,
                        ),
                      ],
                    ),
                    Ecart.vMd,
                    AnimatedBuilder(
                      animation: _minuteur,
                      builder: (BuildContext _, Widget? _) => _LigneEtat(
                        total: total,
                        index: _index,
                        avancee: _automatique ? _minuteur.value : 1,
                      ),
                    ),
                    Ecart.vLg,
                    Expanded(
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: _glissement,
                        child: PageView.builder(
                          key: const ValueKey<String>('bienvenue-pages'),
                          controller: _pages,
                          itemCount: total,
                          onPageChanged: _pageChangee,
                          itemBuilder: (BuildContext _, int i) => _Page(
                            page: _pagesPresentation[i],
                            bureau: bureau,
                            derniere: i == _derniere,
                            onTerminer: _terminer,
                          ),
                        ),
                      ),
                    ),
                    Ecart.vMd,
                    BarrePrecedentSuivant(
                      position: t.bienvenue.position(
                        numero: numero,
                        total: total,
                      ),
                      positionSemantique: t.bienvenue.positionLecteur(
                        numero: numero,
                        total: total,
                      ),
                      libellePrecedent: t.bienvenue.precedente,
                      libelleSuivant: t.bienvenue.suivante,
                      onPrecedent: _index > 0
                          ? () => _aller(_index - 1, parLeVisiteur: true)
                          : null,
                      onSuivant: _index < _derniere
                          ? () => _aller(_index + 1, parLeVisiteur: true)
                          : null,
                    ),
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

/// La petite ligne d'etat : un segment par page. Les pages lues sont
/// pleines, la page courante se charge au rythme du defilement (pleine quand
/// il est arrete), les suivantes sont vides. Decorative pour le lecteur
/// d'ecran : la position est dite par la barre du bas.
class _LigneEtat extends StatelessWidget {
  const _LigneEtat({
    required this.total,
    required this.index,
    required this.avancee,
  });

  final int total;
  final int index;
  final double avancee;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      key: const ValueKey<String>('bienvenue-ligne-etat'),
      spacing: AppSpacing.xs,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Expanded(
            child: LinearProgressIndicator(
              key: ValueKey<String>('bienvenue-segment-$i'),
              value: i < index ? 1 : (i == index ? avancee : 0),
              minHeight: AppSpacing.xs,
              borderRadius: AppRadius.arrondiFull,
            ),
          ),
      ],
    ),
  );
}

/// Une page : le pictogramme, l'idee, son explication ; sur la derniere, les
/// deux sorties vers la connexion, 16 sous le texte qu'elles concluent.
class _Page extends StatelessWidget {
  const _Page({
    required this.page,
    required this.bureau,
    required this.derniere,
    required this.onTerminer,
  });

  final _PagePresentation page;
  final bool bureau;
  final bool derniere;
  final VoidCallback onTerminer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget texte = Column(
      crossAxisAlignment: bureau
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            page.titre(),
            key: ValueKey<String>(
              page.cle == 'service'
                  ? 'bienvenue-accroche'
                  : 'bienvenue-titre-${page.cle}',
            ),
            textAlign: bureau ? TextAlign.start : TextAlign.center,
            // Un titre d'ecran, jamais `displaySmall` (valeurs chiffrees) :
            // il reste strictement plus grand que le mot-marque (HIER-1).
            style: bureau ? textes.headlineLarge : textes.headlineMedium,
          ),
        ),
        Ecart.vSm,
        TexteSansCoupure(
          page.texte(),
          textAlign: bureau ? TextAlign.start : TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (derniere) ...<Widget>[
          Ecart.vLg,
          _Sorties(bureau: bureau, onTerminer: onTerminer),
        ],
      ],
    );

    final Widget contenu = bureau
        ? Row(
            children: <Widget>[
              _Pictogramme(icone: page.icone, bureau: true),
              const SizedBox(width: AppSpacing.titreEcran),
              Expanded(child: texte),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(child: _Pictogramme(icone: page.icone, bureau: false)),
              Ecart.vXxxl,
              texte,
            ],
          );

    // Une page ne deborde jamais : centree quand la place suffit, defilante
    // sinon (320 px, texte x2).
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) => SingleChildScrollView(
        key: ValueKey<String>('bienvenue-page-${page.cle}'),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(child: contenu),
        ),
      ),
    );
  }
}

/// Le pictogramme d'une page, dans un disque doux. Decoratif : l'idee est
/// dite par le titre.
class _Pictogramme extends StatelessWidget {
  const _Pictogramme({required this.icone, required this.bureau});

  final AppIcon icone;
  final bool bureau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Multiples de l'echelle, comme le pictogramme d'`EmptyState`.
    final double disque = bureau
        ? AppSpacing.respiration * 3
        : AppSpacing.xxxl * 4;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: disque,
        child: DecoratedBox(
          decoration: palette.washAccent.decoration(
            borderRadius: AppRadius.arrondiFull,
          ),
          child: Center(
            child: IconTheme(
              data: palette.inkAccent.asIconTheme(size: disque / 2),
              child: Icon(icone.repos),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les deux sorties de la derniere page, vers la connexion : « Commencer »
/// (un compte se cree par le lien de connexion, puis l'inscription) et
/// « J'ai deja un compte ». Un seul bouton plein (K-56). Sur bureau, les deux
/// boutons a la largeur de leur libelle, l'action principale au bord de fin
/// (contrat B) ; sur telephone, l'action principale sur toute la colonne.
class _Sorties extends StatelessWidget {
  const _Sorties({required this.bureau, required this.onTerminer});

  final bool bureau;
  final VoidCallback onTerminer;

  @override
  Widget build(BuildContext context) {
    final Widget commencer = ActionPrincipale(
      key: const ValueKey<String>('bienvenue-commencer'),
      libelle: t.bienvenue.commencer,
      onPress: onTerminer,
      pleineLargeur: !bureau,
    );
    final Widget dejaCompte = ActionPrincipale(
      key: const ValueKey<String>('bienvenue-deja-compte'),
      libelle: t.bienvenue.dejaCompte,
      onPress: onTerminer,
      niveau: NiveauAction.tertiaire,
      pleineLargeur: false,
    );
    if (bureau) {
      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[dejaCompte, commencer],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        commencer,
        Ecart.vSm,
        Align(child: dejaCompte),
      ],
    );
  }
}
