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

  /// Faux pour une option **visible mais indisponible** (K3) : elle reste
  /// lisible, dit pourquoi, et ne se presse pas.
  final bool disponible;

  /// Pourquoi l'option est indisponible, affiche sous elle. A defaut, la
  /// carte dit seulement « Indisponible ».
  final String? raisonIndisponible;
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
  });

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

  Widget _carteOption(OptionChoix option, {required bool verticale}) => _Carte(
    key: option.cle,
    // Cartes empilees de meme largeur : titres et descriptions gardent la meme
    // taille d'une carte a l'autre (COUPE-MOTS-1 point 6).
    voisinsLibelle: verticale
        ? const <String>[]
        : <String>[for (final OptionChoix o in widget.options) o.libelle],
    voisinsDescription: verticale
        ? const <String>[]
        : <String>[for (final OptionChoix o in widget.options) ?o.description],
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
        if (widget.selectionMultiple) ...<Widget>[
          TexteSansCoupure(
            t.choix.selectionMultiple,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vMd,
        ],
        if (widget.coteACote)
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) =>
                _motsTiennent(context, contraintes.maxWidth)
                ? _rangeeCoteACote()
                : _pileVerticale(),
          )
        else
          _liste(),
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

class _Carte extends StatelessWidget {
  const _Carte({
    required this.libelle,
    required this.retenue,
    required this.onPress,
    required this.radio,
    super.key,
    this.icone,
    this.description,
    this.raisonIndisponible,
    this.verticale = false,
    this.voisinsLibelle = const <String>[],
    this.voisinsDescription = const <String>[],
  });

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
              minHeight: math.max(
                cible,
                verticale ? AppPage.hauteurChoix * 2 : AppPage.hauteurChoix,
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
              child: verticale
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
          // il ne passe pas a la ligne apres son trait d'union.
          TexteSansCoupure(
            texte,
            style: style,
            nomsComposesEntiers: i == 0,
            // Les cartes d'un meme groupe gardent la meme taille de texte
            // (FORM-MINEURS) : le titre avec les titres, la description avec
            // les descriptions.
            voisins: i == 0
                ? voisinsLibelle
                : texte == description
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
                    nomsComposesEntiers: i == 0,
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
