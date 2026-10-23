import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'grille_bento.dart';
import 'pressable.dart';

/// Une option proposee a l'utilisateur.
@immutable
class OptionChoix {
  /// Cree une option.
  const OptionChoix({
    required this.valeur,
    required this.libelle,
    this.icone,
    this.description,
    this.explication,
    this.exemple,
    this.illustration,
    this.disponible = true,
    this.raisonIndisponible,
    this.cle,
  });

  /// Une cle posee sur la carte de l'option, pour qu'un test la vise sans
  /// dependre du libelle (demande A-5.3).
  final Key? cle;

  /// La valeur transmise a l'appelant.
  final String valeur;

  /// Le libelle affiche.
  final String libelle;

  /// Icone facultative.
  final AppIcon? icone;

  /// Une phrase sous le libelle, qui dit ce que l'option change (style liste
  /// avec description, planches V5 et V6 E1 ; demande B-3).
  final String? description;

  /// Ce qu'il faut savoir avant de choisir : quand prendre cette option et ce
  /// qu'elle change (K-58, decision du directeur du 17/10/2026). Toujours
  /// visible, sur telephone comme sur grand ecran.
  final String? explication;

  /// Un cas concret, facultatif, quand il aide a comprendre avant de
  /// choisir (« Vous inscrivez Yasmine, 9 ans, et Bilal, 12 ans »). Affiche
  /// precede de « Par exemple ».
  final String? exemple;

  /// L'illustration de la carte en disposition bento (grand ecran). A
  /// defaut, l'[icone] seule sert d'illustration. Sous 900 px, la carte garde
  /// son icone.
  final IllustrationChoix? illustration;

  /// Faux pour une option **visible mais indisponible** (K3) : elle reste
  /// lisible, dit pourquoi, et ne se presse pas.
  final bool disponible;

  /// Pourquoi l'option est indisponible, affiche sous elle. A defaut, la
  /// carte dit seulement « Indisponible ».
  final String? raisonIndisponible;
}

/// L'illustration d'une carte de choix, dessinee en code avec les jetons du
/// theme (lot E2) : une scene douce (disques et arc peints par
/// [CustomPainter]) autour d'une icone principale, entouree d'au plus trois
/// icones secondaires qui racontent l'option. Aucune image, aucune couleur
/// en dur : tout vient de la palette et du catalogue Phosphor.
@immutable
class IllustrationChoix {
  /// Cree une illustration.
  const IllustrationChoix(this.principale, {this.autour = const <AppIcon>[]});

  /// L'icone au centre de la scene.
  final AppIcon principale;

  /// Les icones posees autour, dans l'ordre de lecture : trois au plus sont
  /// dessinees, les suivantes sont ignorees.
  final List<AppIcon> autour;
}

/// Ce que l'utilisateur a repondu.
@immutable
class ReponseChoix {
  /// Cree une reponse.
  const ReponseChoix({required this.valeurs, this.saisieLibre});

  /// Les valeurs des cartes retenues.
  final Set<String> valeurs;

  /// Le texte saisi quand la carte « Autre » est retenue.
  final String? saisieLibre;

  /// Vrai quand l'utilisateur a repondu quelque chose d'exploitable.
  bool get renseignee =>
      valeurs.isNotEmpty || (saisieLibre != null && saisieLibre!.isNotEmpty);
}

/// Selection par cartes, avec repli « Autre » en saisie libre.
///
/// **Seul point d'entree pour tout choix propose a l'utilisateur** (ADR-013),
/// dans l'onboarding comme ailleurs. La carte « Autre » est systematique : elle
/// n'est pas une option de l'appelant, parce qu'un parcours qui n'offre aucune
/// issue a celui qui ne se reconnait dans aucune reponse est un parcours qui
/// perd cet utilisateur.
class ChoiceCardGroup extends StatefulWidget {
  /// Cree un groupe de cartes.
  const ChoiceCardGroup({
    required this.options,
    required this.onChange,
    super.key,
    this.selectionMultiple = false,
    this.valeurInitiale,
    this.autoriserSaisieLibre = true,
    this.coteACote = false,
    this.indicationMultiple = true,
  });

  /// Vrai (par defaut) : en selection multiple, la phrase « Plusieurs reponses
  /// possibles » se lit en tete du groupe. Faux quand l'ecran empile plusieurs
  /// groupes d'une meme question (les competences par famille) et la dit une
  /// seule fois, au-dessus : la phrase ne se repete pas.
  final bool indicationMultiple;

  /// Vrai pour poser les options **cote a cote** (demande A-5.2, maquette
  /// « onboarding Mble d ») : cartes de meme hauteur, contenu centre, icone
  /// dans un disque au-dessus du titre, radio en haut cote `start`. Faite pour
  /// deux ou trois options courtes ; la carte « Autre », si elle est permise,
  /// reste pleine largeur dessous. Faux par defaut : rendu en liste inchange.
  final bool coteACote;

  /// Les reponses les plus courantes.
  final List<OptionChoix> options;

  /// Appele a chaque changement de reponse.
  final void Function(ReponseChoix reponse) onChange;

  /// Vrai pour autoriser plusieurs reponses.
  final bool selectionMultiple;

  /// Reponse pre-cochee, utile a l'onboarding de confirmation (ADR-014).
  final ReponseChoix? valeurInitiale;

  /// Legacy flows may keep an "Other" text answer. New scheduling choices use
  /// closed administrative proposals and pass false.
  final bool autoriserSaisieLibre;

  /// Valeur interne de la carte « Autre ».
  static const String valeurAutre = r'$autre';

  /// Largeur d'ecran a partir de laquelle les options passent en disposition
  /// bento (lot E2, decision du directeur du 17/10/2026) : sur grand ecran,
  /// des cartes propres au grand ecran, jamais les cartes du mobile etirees.
  /// Il faut aussi que le groupe ait la place de quatre colonnes de
  /// [GrilleBento] ; sinon la liste reste.
  static const double seuilBento = 900;

  /// La hauteur minimale d'une ligne de la grille bento des choix : une
  /// tuile `1 x 1` est a peu pres carree a 1440 px. Le contenu peut la
  /// depasser (texte agrandi) : la tuile grandit, rien n'est coupe.
  static const double hauteurLigneBento = AppPage.hauteurChoix * 2;

  /// Les etendues des tuiles bento pour [n] options, sur quatre colonnes.
  ///
  /// Jamais deux cartes identiques cote a cote : de 1 a 5 options, toutes
  /// les tuiles ont des tailles differentes (un carre, des rectangles larges
  /// de 2, 3 ou 4 colonnes, un rectangle haut) et aucune ne touche une
  /// tuile de meme taille ; la grille n'a aucun trou et se decoupe toujours
  /// en bandes (aucun moulinet, que [GrilleBento] lirait en une colonne).
  /// Au-dela de 5, les quatre premieres gardent le dessin de 4 et les suivantes
  /// vont par rangees de deux (carre et large, puis large et carre, en
  /// alternance), la derniere seule en pleine largeur : deux voisines d'une
  /// meme rangee different toujours.
  static List<EtendueBento> etenduesBento(int n) {
    const List<List<EtendueBento>> dessins = <List<EtendueBento>>[
      <EtendueBento>[],
      <EtendueBento>[EtendueBento(4, 1)],
      <EtendueBento>[EtendueBento(3, 1), EtendueBento.carree],
      <EtendueBento>[
        EtendueBento(4, 1),
        EtendueBento(3, 1),
        EtendueBento.carree,
      ],
      <EtendueBento>[
        EtendueBento(3, 1),
        EtendueBento.haute,
        EtendueBento.large,
        EtendueBento.carree,
      ],
      <EtendueBento>[
        EtendueBento(3, 1),
        EtendueBento.haute,
        EtendueBento.large,
        EtendueBento.carree,
        EtendueBento(4, 1),
      ],
    ];
    if (n < dessins.length) return dessins[n];
    final List<EtendueBento> etendues = <EtendueBento>[...dessins[4]];
    int reste = n - etendues.length;
    for (int paire = 0; reste > 0; paire++) {
      if (reste == 1) {
        etendues.add(const EtendueBento(4, 1));
        break;
      }
      etendues.addAll(
        paire.isEven
            ? const <EtendueBento>[EtendueBento.carree, EtendueBento(3, 1)]
            : const <EtendueBento>[EtendueBento(3, 1), EtendueBento.carree],
      );
      reste -= 2;
    }
    return etendues;
  }

  @override
  State<ChoiceCardGroup> createState() => _ChoiceCardGroupState();
}

class _ChoiceCardGroupState extends State<ChoiceCardGroup> {
  late Set<String> _selection =
      widget.valeurInitiale?.valeurs.toSet() ?? <String>{};
  late final TextEditingController _saisie = TextEditingController(
    text: widget.valeurInitiale?.saisieLibre ?? '',
  );

  bool get _autreRetenu => _selection.contains(ChoiceCardGroup.valeurAutre);

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  void _basculer(String valeur) {
    setState(() {
      if (widget.selectionMultiple) {
        if (!_selection.remove(valeur)) {
          _selection.add(valeur);
        }
      } else {
        _selection = <String>{valeur};
      }
    });
    _notifier();
  }

  void _notifier() {
    widget.onChange(
      ReponseChoix(
        valeurs: Set<String>.unmodifiable(_selection),
        saisieLibre: _autreRetenu ? _saisie.text.trim() : null,
      ),
    );
  }

  Widget _carteOption(
    OptionChoix option, {
    required bool verticale,
    _FormeBento? bento,
  }) => _Carte(
    key: option.cle,
    bento: bento,
    coteACote: widget.coteACote,
    explication: option.explication,
    exemple: option.exemple,
    illustration:
        option.illustration ??
        (option.icone == null ? null : IllustrationChoix(option.icone!)),
    // Cartes empilees de meme largeur : titres et descriptions gardent la meme
    // taille d'une carte a l'autre (COUPE-MOTS-1 point 6).
    voisinsLibelle: verticale || bento != null
        ? const <String>[]
        : <String>[for (final OptionChoix o in widget.options) o.libelle],
    voisinsDescription: verticale || bento != null
        ? const <String>[]
        : <String>[
            for (final OptionChoix o in widget.options) ...<String>[
              ?o.description,
              ?o.explication,
            ],
          ],
    libelle: option.libelle,
    icone: option.icone,
    description: option.description,
    raisonIndisponible: option.disponible
        ? null
        : option.raisonIndisponible ?? t.commun.choix.indisponible,
    retenue: _selection.contains(option.valeur),
    radio: !widget.selectionMultiple,
    verticale: verticale,
    onPress: option.disponible ? () => _basculer(option.valeur) : null,
  );

  /// Vrai quand chaque mot de chaque libelle tient sur une ligne d'une
  /// carte cote a cote de cette [largeur] de groupe.
  ///
  /// SUPERPOS-1 (decide par delegation le 05/10) : a 320 en texte double,
  /// une carte n'a que 92 de contenu ; « homme » s'y coupait en « hom /
  /// me ». Les cartes s'empilent alors, chacune pleine largeur, avec la
  /// meme anatomie (radio, disque, titre centre) : aucun mot n'est coupe.
  /// La liste en ligne ne suffisait pas : l'icone et le radio y prennent
  /// encore la place du mot.
  bool _motsTiennent(BuildContext context, double largeur) {
    final int n = widget.options.length;
    if (n == 0 || !largeur.isFinite) return true;
    final double carte = (largeur - (n - 1) * AppSpacing.lg) / n;
    // Le filet de la carte (1 de chaque cote) compte aussi.
    final double contenu = carte - 2 * AppSpacing.xl - 2;
    final TextTheme textes = Theme.of(context).textTheme;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    // COUPE-MOTS-4 : la description et la raison d'indisponibilite comptent
    // aussi (« obser / vation » dans une description).
    for (final OptionChoix option in widget.options) {
      for (final (String?, TextStyle?) e in <(String?, TextStyle?)>[
        (option.libelle, textes.titleMedium),
        (option.description, textes.bodyMedium),
        (option.explication, textes.bodyMedium),
        (
          option.exemple == null
              ? null
              : t.choix.exemple(texte: option.exemple!),
          textes.bodySmall,
        ),
        (
          option.disponible
              ? null
              : option.raisonIndisponible ?? t.commun.choix.indisponible,
          textes.labelMedium,
        ),
      ]) {
        if (e.$1 == null) continue;
        if (largeurMotLePlusLong(context, e.$1!, e.$2, echelle) > contenu) {
          return false;
        }
      }
    }
    return true;
  }

  Widget _rangeeCoteACote() => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < widget.options.length; i++) ...<Widget>[
            if (i > 0) Ecart.hLg,
            Expanded(child: _carteOption(widget.options[i], verticale: true)),
          ],
        ],
      ),
    ),
  );

  Widget _pileVerticale() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final OptionChoix option in widget.options)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: IntrinsicHeight(child: _carteOption(option, verticale: true)),
        ),
    ],
  );

  /// La disposition bento : des tuiles de tailles et de formes variees
  /// ([etenduesBento]), chacune illustree, sur quatre colonnes.
  Widget _bento() => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: GrilleBento(
      hauteurMinimale: true,
      hauteurDeLigne: ChoiceCardGroup.hauteurLigneBento,
      tuiles: <TuileBento>[
        for (final (int i, EtendueBento e) in ChoiceCardGroup.etenduesBento(
          widget.options.length,
        ).indexed)
          TuileBento(
            etendue: e,
            child: _carteOption(
              widget.options[i],
              verticale: false,
              bento: e.colonnes > e.lignes
                  ? _FormeBento.large
                  : _FormeBento.haute,
            ),
          ),
      ],
    ),
  );

  /// La disposition du telephone et des fenetres etroites (inchangee).
  Widget _dispositionMobile() => widget.coteACote
      ? LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) =>
              _motsTiennent(context, contraintes.maxWidth)
              ? _rangeeCoteACote()
              : _pileVerticale(),
        )
      : _liste();

  Widget _liste() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final OptionChoix option in widget.options)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _carteOption(option, verticale: false),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.selectionMultiple && widget.indicationMultiple) ...<Widget>[
          TexteSansCoupure(
            t.choix.selectionMultiple,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vMd,
        ],
        // Lot E2 : au-dela de [ChoiceCardGroup.seuilBento] d'ecran, et si le
        // groupe a la place de quatre colonnes a l'echelle du texte, les
        // options passent en bento ; sinon la disposition du telephone.
        if (widget.options.isNotEmpty &&
            MediaQuery.sizeOf(context).width >= ChoiceCardGroup.seuilBento)
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) =>
                contraintes.maxWidth.isFinite &&
                    GrilleBento.colonnesPour(
                          contraintes.maxWidth,
                          MediaQuery.textScalerOf(context).scale(1),
                        ) ==
                        4
                ? _bento()
                : _dispositionMobile(),
          )
        else
          _dispositionMobile(),
        if (widget.autoriserSaisieLibre)
          _Carte(
            libelle: t.choix.autre,
            icone: AppIcons.autreChoix,
            retenue: _autreRetenu,
            radio: !widget.selectionMultiple,
            onPress: () => _basculer(ChoiceCardGroup.valeurAutre),
          ),
        if (widget.autoriserSaisieLibre && _autreRetenu) ...<Widget>[
          Ecart.vMd,
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metriques.cibleTactile),
            child: TextField(
              controller: _saisie,
              onChanged: (String _) => _notifier(),
              decoration: InputDecoration(labelText: t.choix.autreInvite),
            ),
          ),
        ],
      ],
    );
  }
}

/// La forme d'une tuile bento : plus large que haute, ou carree et haute.
enum _FormeBento { large, haute }

class _Carte extends StatelessWidget {
  const _Carte({
    required this.libelle,
    required this.retenue,
    required this.onPress,
    required this.radio,
    super.key,
    this.icone,
    this.description,
    this.explication,
    this.exemple,
    this.illustration,
    this.raisonIndisponible,
    this.verticale = false,
    this.bento,
    this.coteACote = false,
    this.voisinsLibelle = const <String>[],
    this.voisinsDescription = const <String>[],
  });

  /// Non nul en disposition bento : la forme de la tuile.
  final _FormeBento? bento;

  /// Vrai quand le groupe est demande cote a cote (options courtes) : en
  /// bento, le repere garde sa rangee au-dessus du titre.
  final bool coteACote;

  final String? explication;
  final String? exemple;
  final IllustrationChoix? illustration;

  /// Les titres et descriptions des cartes voisines (meme largeur).
  final List<String> voisinsLibelle;
  final List<String> voisinsDescription;

  /// Vrai pour la disposition cote a cote : contenu centre, icone dans un
  /// disque au-dessus du titre, radio (ou coche) en haut a droite.
  final bool verticale;

  final String libelle;
  final bool retenue;

  /// `null` pour une option indisponible : la carte ne se presse pas.
  final VoidCallback? onPress;

  /// Vrai en selection unique : un radio dessine dit le choix ; en selection
  /// multiple, la coche garde ce role.
  final bool radio;
  final AppIcon? icone;
  final String? description;

  /// Non nul quand l'option est indisponible : la phrase affichee.
  final String? raisonIndisponible;

  bool get _disponible => raisonIndisponible == null;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // La selection change la PAIRE entiere, pas seulement le fond : le texte
    // suit toujours son fond.
    //
    // **Le lot C la passe au registre doux.** Une carte retenue etait peinte en
    // aplat violet plein : sur une page de parcours qui porte deja son bouton
    // « Continuer » en `surfacePrimary`, deux aplats satures se disputaient
    // l'ecran, ce que la regle de la zone pleine unique interdit
    // (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 3). La selection se dit
    // maintenant par la teinte douce et par le contour fort, qui est la seule
    // bordure porteuse de sens.
    final AppColorPair paire = retenue
        ? palette.washAccent
        : palette.surfaceRaised;

    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Le libelle lu : le titre seul tant qu'il n'y a rien d'autre (les
    // usages existants restent lus a l'identique), puis la description et la
    // raison d'indisponibilite.
    final String lu = <String>[
      libelle,
      ?description,
      ?explication,
      if (exemple != null) t.choix.exemple(texte: exemple!),
      ?raisonIndisponible,
    ].join('. ');

    // E1 (demande du directeur du 17/10) : **toute la carte est la cible** et
    // elle doit se lire comme telle. Le [Pressable] couvre toute la surface
    // (geste opaque, curseur main sur le Web, clavier), le repere de
    // selection est en tete cote `start`, et le survol change le fond (calque
    // d'interaction, comme `AppCard`) et le titre (encre d'accent), pas
    // seulement le filet. La hauteur minimale (112, 224 cote a cote) depasse
    // toujours la cible tactile du mode courant.
    final double cible = AppMetriques.of(context).cibleTactile;
    return Semantics(
      checked: retenue,
      inMutuallyExclusiveGroup: radio,
      child: Pressable.selon(
        onPress: onPress,
        actif: _disponible,
        libelleSemantique: lu,
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiLg,
        // La selection passe d'une teinte a l'autre en fondu court (P2-16).
        constructeur: (BuildContext contexte, EtatPression etat) {
          final bool interaction = etat.survole || etat.presse;
          return AnimatedContainer(
            duration: Mouvement.duree(contexte, Mouvement.court),
            curve: Mouvement.entree,
            constraints: BoxConstraints(
              // En bento, la grille fixe la hauteur minimale de la tuile.
              minHeight: bento != null
                  ? cible
                  : math.max(
                      cible,
                      verticale
                          ? AppPage.hauteurChoix * 2
                          : AppPage.hauteurChoix,
                    ),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration:
                AppElevation.avecFilet(
                  surface: paire,
                  // Retenue : le filet prend l'encre d'accent, la bordure qui
                  // porte le sens ; survol et pression : le filet fort.
                  filet: retenue
                      ? palette.inkAccent
                      : interaction
                      ? palette.borderStrong
                      : palette.borderResting,
                  ombre: palette.ombre,
                  arrondi: AppRadius.arrondiLg,
                  ombres: AppElevation.niveau0,
                ).copyWith(
                  // Survol et pression : le calque d'interaction d'`AppCard`.
                  color: interaction
                      ? Color.alphaBlend(
                          palette.calqueInteraction(presse: etat.presse),
                          paire.background,
                        )
                      : null,
                ),
            // Le libelle lu est [lu] : les textes visibles ne sont pas relus
            // une seconde fois a sa suite.
            child: ExcludeSemantics(
              child: bento != null
                  ? _contenuBento(
                      palette,
                      paire,
                      textes,
                      styleSecondaire,
                      survole: interaction,
                    )
                  : verticale
                  ? _contenuVertical(
                      palette,
                      paire,
                      textes,
                      styleSecondaire,
                      survole: interaction,
                    )
                  : _contenuListe(
                      palette,
                      paire,
                      textes,
                      styleSecondaire,
                      survole: interaction,
                    ),
            ),
          );
        },
      ),
    );
  }
}

extension on _Carte {
  /// Le style du titre : celui de la paire, l'encre d'accent au survol (la
  /// carte se lit comme une cible), ou le ton doux si l'option est
  /// indisponible.
  TextStyle _styleTitre(
    AppPalette palette,
    AppColorPair paire,
    TextTheme t, {
    required bool survole,
  }) => !_disponible
      ? palette.inkMuted.applyTo(t.titleMedium ?? const TextStyle())
      : survole
      ? palette.inkAccent.applyTo(t.titleMedium ?? const TextStyle())
      : paire.applyTo(t.titleMedium ?? const TextStyle());

  /// Le repere de selection, toujours dessine et toujours en tete de carte
  /// cote `start` : radio en selection unique, case en selection multiple.
  /// Il double la teinte : une selection qui ne se lirait qu'a la couleur
  /// n'existerait pas pour un daltonien.
  Widget get _repere => radio
      ? RadioChoix(retenue: retenue, disponible: _disponible)
      : CaseChoix(retenue: retenue, disponible: _disponible);

  /// Les textes de la carte et leur style : titre, description, raison.
  List<(String, TextStyle)> _textesStyles(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire, {
    required bool survole,
  }) => <(String, TextStyle)>[
    (libelle, _styleTitre(palette, paire, textes, survole: survole)),
    if (description != null) (description!, styleSecondaire),
    if (explication != null) (explication!, styleSecondaire),
    if (exemple != null)
      (
        t.choix.exemple(texte: exemple!),
        palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
      ),
    if (raisonIndisponible != null)
      (
        raisonIndisponible!,
        palette.inkMuted.applyTo(textes.labelMedium ?? const TextStyle()),
      ),
  ];

  /// Le contenu de la carte en liste : repere (radio ou case) en tete cote
  /// `start`, icone, textes.
  ///
  /// COUPE-MOTS-4 (decide par delegation le 09/10) : a 320 en texte double,
  /// l'icone et le radio laissaient trop peu de place aux textes, et des
  /// mots s'y coupaient (« nor / malement », « administ / ration »,
  /// « Acc / essibilité »). Quand un mot d'un texte ne tient pas a cote
  /// d'eux, a l'echelle de l'appareil, le radio et l'icone passent sur une
  /// rangee au-dessus et les textes prennent toute la largeur de la carte.
  /// Chaque texte passe par [TexteSansCoupure] : un mot qui ne tiendrait
  /// toujours pas se reduit (echelle bornee) au lieu d'etre coupe.
  Widget _contenuListe(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire, {
    required bool survole,
  }) {
    final List<(String, TextStyle)> aEcrire = _textesStyles(
      palette,
      paire,
      textes,
      styleSecondaire,
      survole: survole,
    );
    final Widget? symbole = icone == null
        ? null
        : IconTheme(
            data: _disponible
                ? IconThemeData(color: paire.onBackground, size: AppSpacing.xxl)
                : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
            child: Icon(icone!.resoudre(selectionne: retenue)),
          );
    final Widget indicateur = _repere;
    final Widget colonne = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, (String texte, TextStyle style))
            in aEcrire.indexed) ...<Widget>[
          if (i > 0) texte == raisonIndisponible ? Ecart.vSm : Ecart.vXs,
          // Le titre garde un nom compose entier (« Abd al-Rahman B. ») :
          // il ne passe pas a la ligne apres son trait d'union. Lot E2 : les
          // explications et exemples aussi (« vous-même » restait coupe a
          // 320 en texte double), aucun mot d'une carte de choix ne se coupe.
          TexteSansCoupure(
            texte,
            style: style,
            nomsComposesEntiers: true,
            // Les cartes d'un meme groupe gardent la meme taille de texte
            // (FORM-MINEURS) : le titre avec les titres, la description avec
            // les descriptions.
            voisins: i == 0
                ? voisinsLibelle
                : texte == description || texte == explication
                ? voisinsDescription
                : const <String>[],
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        // La place prise a cote des textes : le repere et l'icone, chacun
        // avec son ecart. Le repere est toujours dessine : la carte ne
        // change pas de disposition quand on la coche.
        final double cote =
            (symbole == null ? 0 : AppSpacing.xxl + AppSpacing.md) +
            AppSpacing.md +
            AppSpacing.xxl;
        final TextScaler echelle = MediaQuery.textScalerOf(contexte);
        final double place = contraintes.maxWidth - cote;
        final bool empile =
            contraintes.maxWidth.isFinite &&
            aEcrire.any(
              ((String, TextStyle) e) =>
                  largeurMotLePlusLong(contexte, e.$1, e.$2, echelle) > place,
            );
        if (!empile) {
          return Row(
            children: <Widget>[
              indicateur,
              Ecart.hMd,
              if (symbole != null) ...<Widget>[symbole, Ecart.hMd],
              Expanded(child: colonne),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                indicateur,
                if (symbole != null) ...<Widget>[Ecart.hMd, symbole],
              ],
            ),
            Ecart.vSm,
            colonne,
          ],
        );
      },
    );
  }

  /// Le contenu de la carte cote a cote : repere (radio ou case) en haut
  /// cote `start` (E1, 17/10), icone dans un disque puis titre, centres.
  ///
  /// SUPERPOS-1 (decision du 05/10/2026, prise par delegation) : le radio a
  /// sa propre ligne, en tete, dans le flux. Peint dans un `Stack`, il
  /// recouvrait le disque de l'icone a 320 de large (92 de contenu par
  /// carte). La carte est posee dans une `IntrinsicHeight` (groupe cote a
  /// cote) : le contenu prend la hauteur restante, centre.
  Widget _contenuVertical(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire, {
    required bool survole,
  }) {
    const double disque = AppSpacing.respiration + AppSpacing.sm;
    final AppColorPair fondDisque = retenue
        ? palette.surfaceActionDouce
        : palette.surfaceSunken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(alignment: AlignmentDirectional.topStart, child: _repere),
        Ecart.vXs,
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icone != null) ...<Widget>[
                  SizedBox.square(
                    dimension: disque,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fondDisque.background,
                      ),
                      child: Center(
                        child: IconTheme(
                          data: _disponible
                              ? IconThemeData(
                                  color: fondDisque.onBackground,
                                  size: AppSpacing.xxxl,
                                )
                              : palette.inkMuted.asIconTheme(
                                  size: AppSpacing.xxxl,
                                ),
                          child: Icon(icone!.resoudre(selectionne: retenue)),
                        ),
                      ),
                    ),
                  ),
                  Ecart.vLg,
                ],
                for (final (int i, (String texte, TextStyle style))
                    in _textesStyles(
                      palette,
                      paire,
                      textes,
                      styleSecondaire,
                      survole: survole,
                    ).indexed) ...<Widget>[
                  if (i > 0)
                    texte == raisonIndisponible ? Ecart.vSm : Ecart.vXs,
                  TexteSansCoupure(
                    texte,
                    style: style,
                    textAlign: TextAlign.center,
                    nomsComposesEntiers: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension on _Carte {
  /// Les textes d'une tuile bento, alignes au debut de lecture : titre,
  /// description, explication, exemple, raison.
  Widget _textesBento(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire, {
    required bool survole,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final (int i, (String texte, TextStyle style)) in _textesStyles(
        palette,
        paire,
        textes,
        styleSecondaire,
        survole: survole,
      ).indexed) ...<Widget>[
        if (i > 0) i == 1 ? Ecart.vSm : Ecart.vXs,
        TexteSansCoupure(texte, style: style, nomsComposesEntiers: true),
      ],
    ],
  );

  /// Le contenu d'une tuile bento (lot E2) : l'illustration et les textes,
  /// arranges selon la forme de la tuile, pour que deux tuiles voisines ne
  /// se ressemblent jamais.
  ///
  /// * Tuile large, options longues : repere en tete cote `start`, textes au
  ///   milieu, illustration cote `end`.
  /// * Tuile large, options courtes (cote a cote) : repere sur sa rangee,
  ///   puis illustration et textes cote a cote.
  /// * Tuile carree ou haute : repere sur sa rangee, illustration, puis
  ///   textes dessous.
  ///
  /// Aucun `LayoutBuilder` ici : la grille mesure les hauteurs intrinseques
  /// des tuiles d'une meme bande pour les egaliser.
  Widget _contenuBento(
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
    TextStyle styleSecondaire, {
    required bool survole,
  }) {
    final Widget textesVus = _textesBento(
      palette,
      paire,
      textes,
      styleSecondaire,
      survole: survole,
    );
    final IllustrationChoix? dessin = illustration;
    Widget scene(double taille) => dessin == null
        ? const SizedBox.shrink()
        : VueIllustrationChoix(
            illustration: dessin,
            taille: taille,
            retenue: retenue,
            disponible: _disponible,
          );
    // Tuile large : le contenu se centre dans la hauteur que la bande lui
    // donne (une voisine haute l'allonge), au lieu de laisser un vide en bas.
    if (bento == _FormeBento.large && !coteACote) {
      return Row(
        children: <Widget>[
          _repere,
          Ecart.hLg,
          Expanded(child: textesVus),
          if (dessin != null) ...<Widget>[
            Ecart.hXxl,
            scene(VueIllustrationChoix.tailleLarge),
          ],
        ],
      );
    }
    if (bento == _FormeBento.large) {
      // Le repere en tete, le reste centre dans la place restante ; aucun
      // enfant flexible : la bande peut etre de hauteur libre.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Align(alignment: AlignmentDirectional.topStart, child: _repere),
          Row(
            children: <Widget>[
              if (dessin != null) ...<Widget>[
                scene(VueIllustrationChoix.tailleLarge),
                Ecart.hXxl,
              ],
              Expanded(child: textesVus),
            ],
          ),
          const SizedBox.shrink(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(alignment: AlignmentDirectional.topStart, child: _repere),
        if (dessin != null) ...<Widget>[
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: scene(VueIllustrationChoix.tailleHaute),
          ),
        ],
        Ecart.vLg,
        textesVus,
      ],
    );
  }
}

/// L'illustration d'une carte de choix en bento : la scene peinte par
/// [_FondIllustration], l'icone principale dans un disque, les icones
/// secondaires dans de petits disques autour. Toutes les teintes viennent de
/// la palette ; la scene se retourne en arabe (droite a gauche).
class VueIllustrationChoix extends StatelessWidget {
  /// Cree la vue.
  const VueIllustrationChoix({
    required this.illustration,
    required this.taille,
    super.key,
    this.retenue = false,
    this.disponible = true,
  });

  /// La taille de la scene d'une tuile large.
  static const double tailleLarge = AppSpacing.respiration * 2;

  /// La taille de la scene d'une tuile carree ou haute.
  static const double tailleHaute = AppSpacing.respiration + AppSpacing.xxxl;

  /// Ce qui est dessine.
  final IllustrationChoix illustration;

  /// Le cote de la scene, carree.
  final double taille;

  /// Vrai quand l'option est retenue : la scene prend la teinte d'action.
  final bool retenue;

  /// Faux pour une option indisponible : icones au ton doux.
  final bool disponible;

  /// Les places des icones secondaires, dans le sens de lecture.
  static const List<AlignmentDirectional> _places = <AlignmentDirectional>[
    AlignmentDirectional(-0.95, -0.85),
    AlignmentDirectional(0.95, -0.35),
    AlignmentDirectional(-0.7, 0.95),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Le grand disque se detache de la carte dans les deux themes : teinte
    // d'accent douce au repos, teinte d'action quand la carte (deja en
    // `washAccent`) est retenue.
    final AppColorPair fond = retenue
        ? palette.surfaceActionDouce
        : palette.washAccent;
    final AppColorPair disque = palette.surfaceRaised;
    final AppInkColor encre = disponible ? palette.inkAccent : palette.inkMuted;
    final double centre = taille * 0.46;
    final double satellite = taille * 0.3;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: taille,
        child: CustomPaint(
          painter: _FondIllustration(
            fond: fond.background,
            accent: retenue
                ? palette.surfaceRaised.background
                : palette.surfaceActionDouce.background,
            trait: palette.borderResting.asBorderSide().color,
            sens: Directionality.of(context),
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: SizedBox.square(
                  dimension: centre,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: disque.background,
                      border: Border.fromBorderSide(
                        palette.borderHairline.asBorderSide(),
                      ),
                    ),
                    child: Center(
                      child: IconTheme(
                        data: encre.asIconTheme(size: centre * 0.55),
                        child: Icon(
                          illustration.principale.resoudre(
                            selectionne: retenue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final (int i, AppIcon icone)
                  in illustration.autour.take(_places.length).indexed)
                Align(
                  alignment: _places[i],
                  child: SizedBox.square(
                    dimension: satellite,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: disque.background,
                        border: Border.fromBorderSide(
                          palette.borderHairline.asBorderSide(),
                        ),
                      ),
                      child: Center(
                        child: IconTheme(
                          data: palette.inkMuted.asIconTheme(
                            size: satellite * 0.55,
                          ),
                          child: Icon(icone.repos),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le fond de la scene : un grand disque doux, un petit disque d'accent en
/// haut cote `end`, un arc fin et trois points cote `start`.
class _FondIllustration extends CustomPainter {
  _FondIllustration({
    required this.fond,
    required this.accent,
    required this.trait,
    required this.sens,
  });

  final Color fond;
  final Color accent;
  final Color trait;
  final TextDirection sens;

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.shortestSide;
    // x en fraction du sens de lecture : 0 au debut, 1 a la fin.
    Offset point(double x, double y) => Offset(
      (sens == TextDirection.rtl ? 1 - x : x) * size.width,
      y * size.height,
    );
    canvas
      ..drawCircle(point(0.5, 0.52), d * 0.44, Paint()..color = fond)
      ..drawCircle(point(0.86, 0.16), d * 0.1, Paint()..color = accent);
    final Paint arc = Paint()
      ..color = trait
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final double debut = sens == TextDirection.rtl
        ? math.pi * 0.05
        : math.pi * 0.55;
    canvas.drawArc(
      Rect.fromCircle(center: point(0.5, 0.52), radius: d * 0.49),
      debut,
      math.pi * 0.4,
      false,
      arc,
    );
    final Paint pointille = Paint()..color = trait;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(point(0.04 + i * 0.07, 0.5), d * 0.015, pointille);
    }
  }

  @override
  bool shouldRepaint(_FondIllustration ancien) =>
      ancien.fond != fond ||
      ancien.accent != accent ||
      ancien.trait != trait ||
      ancien.sens != sens;
}

/// Le radio dessine d'une carte de choix : anneau, point plein quand elle est
/// retenue. L'anneau garde au moins 3:1 sur la carte (`borderStrong` au
/// repos, `inkAccent` retenu) ; indisponible, il passe au filet de repos,
/// comme tout controle inactif. Sans semantique propre : la carte porte
/// l'etat coche.
class RadioChoix extends StatelessWidget {
  /// Cree le radio.
  const RadioChoix({required this.retenue, super.key, this.disponible = true});

  /// Vrai quand l'option est retenue.
  final bool retenue;

  /// Faux pour une option indisponible.
  final bool disponible;

  /// La couleur de l'anneau dans [palette].
  AppInkColor anneau(AppPalette palette) => retenue
      ? palette.inkAccent
      : disponible
      ? palette.borderStrong
      : palette.borderResting;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              anneau(palette).asBorderSide(width: 2),
            ),
          ),
          child: retenue
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: _Croissance(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surfacePrimary.background,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// La case dessinee d'une carte de choix en selection multiple : carre a
/// filet, plein et coche quand l'option est retenue. Memes encres que
/// [RadioChoix] ; sans semantique propre : la carte porte l'etat coche.
class CaseChoix extends StatelessWidget {
  /// Cree la case.
  const CaseChoix({required this.retenue, super.key, this.disponible = true});

  /// Vrai quand l'option est retenue.
  final bool retenue;

  /// Faux pour une option indisponible.
  final bool disponible;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppInkColor bord = RadioChoix(
      retenue: retenue,
      disponible: disponible,
    ).anneau(palette);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSpacing.xxl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.arrondiXs,
            color: retenue ? palette.surfacePrimary.background : null,
            border: Border.fromBorderSide(bord.asBorderSide(width: 2)),
          ),
          child: retenue
              ? _Croissance(
                  child: IconTheme(
                    data: IconThemeData(
                      color: palette.surfacePrimary.onBackground,
                      size: AppSpacing.lg,
                    ),
                    child: Icon(AppIcons.succes.actif),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Le point du radio grandit a sa pose, une fois (P2-16). Rendu tel quel
/// quand les animations sont reduites.
class _Croissance extends StatelessWidget {
  const _Croissance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Mouvement.reduit(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: Mouvement.court,
      curve: Mouvement.entree,
      child: child,
      builder: (BuildContext _, double f, Widget? enfant) =>
          Transform.scale(scale: f, child: enfant),
    );
  }
}
