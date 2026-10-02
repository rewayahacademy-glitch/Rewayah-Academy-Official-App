import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Les quatre niveaux d'action, pas cinq.
///
/// Source : `docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 4. Le nombre par ecran est
/// une regle d'ecran, pas une regle de composant : elle se tient en revue, et
/// c'est `08-catalogue-ecrans.md` qui la porte.
enum NiveauAction {
  /// Fond plein `surfaceActionDouce` (lavande doux en clair, accent plein en
  /// sombre). **Une seule par ecran**, zero si l'ecran est en lecture.
  principale,

  /// Filet fin `borderStrong` sur `surfaceRaised`. Deux au plus.
  secondaire,

  /// Texte `inkAccent`, sans contour. Autant que necessaire, mais jamais
  /// alignees comme des boutons.
  tertiaire,

  /// Texte `inkAlert`, **jamais un fond rouge plein**. Jamais dans la zone
  /// principale.
  destructive,
}

/// L'action d'un ecran, dans l'un de ses quatre niveaux.
///
/// **Seul point d'entree des actions du produit.** `tool/verifier_jetons.dart`
/// echoue sur tout `ElevatedButton`, `TextButton`, `OutlinedButton` ou
/// `FilledButton` dans `lib/` : un bouton Material rapporterait la palette de
/// Material avec lui.
///
/// Regle d'ecran heritee des parcours : **un ecran, une action principale.** Si
/// deux [NiveauAction.principale] se disputent un ecran, l'ecran est a revoir,
/// pas le composant.
///
/// Le quatrieme niveau, le destructif, a ete ajoute au lot C de la refonte.
/// Avant lui, un refus se peignait en passant la paire `surfaceAlert` au
/// bouton, c'est-a-dire en aplat rouge plein, ce que
/// `01-systeme-visuel.md` section 3 interdit.
class ActionPrincipale extends StatelessWidget {
  /// Cree une action.
  const ActionPrincipale({
    required this.libelle,
    required this.onPress,
    super.key,
    this.niveau = NiveauAction.principale,
    this.enCours = false,
    this.pleineLargeur = true,
    this.prefixe,
    this.fleche = false,
    this.pilule = false,
    this.compacte = false,
    this.doux = false,
    this.autofocus = false,
    this.focusNode,
  });

  /// Vrai pour prendre le focus clavier a l'ouverture de l'ecran : un ecran
  /// qui remplace la page sans geste (acces retire en salle) pose le focus
  /// sur son action, sinon le clavier repart du haut du document.
  final bool autofocus;

  /// Format reduit, meme peinture : la pastille « Ouvrir » d'une ligne de
  /// liste (≈ 34 de haut au lieu de 52). La zone pressable garde la cible
  /// tactile du mode ; en Interface guidee, le format reduit est ignore.
  final bool compacte;

  /// Registre doux d'un [NiveauAction.destructive] : pilule sur le fond doux
  /// d'alerte (`washAlert`) au lieu du texte nu. **Jamais un aplat rouge** : la
  /// paire douce garde l'encre lisible. Reserve a la sortie volontaire d'une
  /// salle (maquette M4, D1). Ignore pour les autres niveaux.
  final bool doux;

  /// Le libelle du bouton. **Un verbe et son objet** : « Poser un creneau »,
  /// pas « Valider » (`02-regles-ux.md` section 9).
  final String libelle;

  /// L'action. `null` rend le bouton inerte, et le dit visuellement.
  final VoidCallback? onPress;

  /// Le niveau hierarchique de l'action.
  final NiveauAction niveau;

  /// Remplace le libelle par un indicateur d'activite, et bloque la pression.
  final bool enCours;

  /// Faux pour que le bouton ne prenne que la largeur de son libelle.
  final bool pleineLargeur;

  /// Un element pose avant le libelle, dans le meme alignement.
  ///
  /// **Reserve a ce que le libelle ne peut pas dire** : aujourd'hui le seul
  /// usage est le logo Google du bouton de connexion, qu'une marque tierce
  /// impose de montrer tel quel. Ce n'est pas une porte d'entree pour
  /// l'iconographie du produit : une action du produit se nomme, elle ne
  /// s'illustre pas (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 9).
  ///
  /// L'indicateur d'activite le remplace tant que [enCours] vaut vrai : les
  /// deux occuperaient la meme place, et c'est l'attente qui prime.
  final Widget? prefixe;

  /// Pose une fleche apres le libelle : « Voir la classe -> ». C'est l'anatomie
  /// du CTA dominant des maquettes Tuteur (decisions du coordinateur, section
  /// 3, point 3). Decorative : le libelle seul porte le sens, l'etiquette
  /// semantique ne change pas. Miroitee en arabe.
  final bool fleche;

  /// Forme pilule (`AppRadius.full`) au lieu du rayon `sm` des boutons.
  ///
  /// **Reservee au CTA des etapes d'admission**, seule exception retenue par
  /// le coordinateur (decisions, section 3, point 2) ; partout ailleurs, un
  /// bouton a le rayon `sm` (12).
  final bool pilule;

  /// Le noeud de focus, pour y rendre le focus apres une modale.
  final FocusNode? focusNode;

  BorderRadius get _arrondi =>
      pilule ? AppRadius.arrondiFull : AppRadius.arrondiSm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final bool actif = onPress != null && !enCours;
    final bool reduit = compacte && !metriques.estEnfant;

    return Pressable.selon(
      onPress: actif ? onPress : null,
      libelleSemantique: libelle,
      // Le format reduit est plus petit que la cible : `Pressable` l'y porte,
      // la pastille reste centree dedans.
      respecterCibleTactile: reduit,
      arrondiFocus: _arrondi,
      autofocus: autofocus,
      focusNode: focusNode,
      constructeur: (BuildContext contexte, EtatPression etat) {
        final Widget corps = _corps(
          contexte,
          palette,
          metriques,
          etat,
          actif: actif,
          reduit: reduit,
        );
        return reduit ? Center(child: corps) : corps;
      },
    );
  }

  Widget _corps(
    BuildContext context,
    AppPalette palette,
    AppMetriques metriques,
    EtatPression etat, {
    required bool actif,
    bool reduit = false,
  }) {
    final _Peinture peinture = _peinturePour(
      palette,
      actif: actif,
      etat: etat,
      guidee: metriques.estEnfant,
    );

    // K-54 : le contenu est centre en largeur ET en hauteur. Un `Container`
    // avec `alignment` s'etirait a toute la largeur offerte meme avec
    // `pleineLargeur: false` (un parent `Align` ou `Column` donne des
    // contraintes souples) : le bouton « compact » prenait 1408 de large sur
    // bureau. `Center(widthFactor: 1)` lui rend la largeur de son contenu, et
    // `heightFactor: 1` le centre dans la hauteur minimale sans l'etirer.
    return SizedBox(
      width: pleineLargeur ? double.infinity : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: reduit
              ? AppSpacing.xxxl + AppSpacing.xs / 2
              : metriques.estEnfant
              ? AppTouchTarget.enfant
              : AppPage.hauteurBouton,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: peinture.fond,
            borderRadius: _arrondi,
            border: peinture.filet == null
                ? null
                : Border.fromBorderSide(peinture.filet!),
          ),
          child: Padding(
            padding: reduit
                ? const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  )
                : const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
            child: Center(
              widthFactor: pleineLargeur ? null : 1,
              heightFactor: 1,
              child: Semantics(
                liveRegion: enCours,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (enCours) ...<Widget>[
                      SizedBox.square(
                        dimension: AppSpacing.xl,
                        child: CircularProgressIndicator(
                          value: 0.65,
                          strokeWidth: 2,
                          color: peinture.encre(const TextStyle()).color,
                        ),
                      ),
                      Ecart.hSm,
                    ] else if (prefixe != null) ...<Widget>[
                      prefixe!,
                      Ecart.hSm,
                    ],
                    // Le libelle est deja porte par `Pressable` : le texte visible
                    // est retire de l'arbre semantique, sinon un lecteur d'ecran
                    // annonce le bouton deux fois.
                    Flexible(
                      child: ExcludeSemantics(
                        child: Text(
                          libelle,
                          textAlign: TextAlign.center,
                          style: _styleLibelle(context, peinture, actif: actif),
                        ),
                      ),
                    ),
                    if (fleche && !enCours) ...<Widget>[
                      Ecart.hSm,
                      IconTheme(
                        data: IconThemeData(
                          color: peinture.encre(const TextStyle()).color,
                          size: AppSpacing.xl,
                        ),
                        child: Icon(AppIcons.flecheAction.repos),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Le style du libelle : **une seule graisse percue, dans les deux themes.**
  ///
  /// L'action pleine porte le semi-gras des images (700 dessine, lu comme un
  /// semi-gras sur son fond doux) ; les autres niveaux restent a 600. Une
  /// encre claire sur fond sombre se lit plus grasse qu'une encre sombre sur
  /// fond clair au meme `wght` (irradiation, mesuree sur les captures T7) :
  /// elle perd donc 100, pour qu'un meme bouton ait la meme graisse en clair
  /// et en sombre.
  TextStyle _styleLibelle(
    BuildContext context,
    _Peinture peinture, {
    required bool actif,
  }) {
    final TextStyle base = peinture.encre(
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
    );
    final int centaines =
        (actif && niveau == NiveauAction.principale ? 7 : 6) -
        (encreClaire(base.color) ? 1 : 0);
    return AppTypography.graisse(base, FontWeight.values[centaines - 1]);
  }

  /// Vrai pour une encre claire (texte clair sur fond sombre).
  @visibleForTesting
  static bool encreClaire(Color? encre) =>
      encre != null && encre.computeLuminance() > 0.5;

  /// Le fond, l'encre et le filet du niveau, dans l'etat courant.
  ///
  /// **Un bouton inerte ne se signale pas par de la transparence** : baisser
  /// l'opacite ferait tomber tout le sous-arbre sous le seuil de contraste. Il
  /// change de paire, donc son texte reste lisible et suit son fond.
  ///
  /// **Un [NiveauAction.principale] desactive reste plus lourd qu'un
  /// secondaire au repos** (lot T2, cause n2 mesuree du rejet du 11 septembre
  /// 2026) : avant ce lot, le fond `surfaceSunken` se fondait presque dans
  /// `surfaceCanvas` (1,06:1 d'ecart) et le filet `borderResting` etait le plus
  /// faible de la rampe, si bien que le bouton le plus important de l'ecran
  /// disparaissait au premier champ vide et se lisait comme une panne. Il
  /// passe desormais sur `surfaceRaised` avec le filet `borderStrong`, plus
  /// epais que celui d'un secondaire (3 contre 1) : la forme reste visible et
  /// pese plus, seule l'encre `inkMuted` dit qu'il attend une condition.
  ///
  /// Le survol n'invente aucune couleur : il passe au registre doux de la meme
  /// famille pour les niveaux plats, et pose le filet fort sur le niveau plein.
  _Peinture _peinturePour(
    AppPalette palette, {
    required bool actif,
    required EtatPression etat,
    required bool guidee,
  }) {
    if (!actif) {
      return _Peinture(
        fond: palette.surfaceRaised.background,
        encre: palette.inkMuted.applyTo,
        filet: palette.borderStrong.asBorderSide(width: 3),
      );
    }

    switch (niveau) {
      case NiveauAction.principale:
        // `surfaceActionDouce` depuis le 24/09/2026 (decisions du
        // coordinateur, section 3.1 et 3.3) : lavande doux et encre
        // `inkStrong` en clair, accent plein et encre sombre en sombre. Plus
        // aucun aplat violet sature en clair : aucune maquette n'en montre.
        //
        // **Sauf en Interface guidee** : la lavande douce ne se detache de sa
        // carte qu'a 1,5:1, et c'est souvent la seule action de l'ecran d'un
        // enfant. Tant que le directeur n'a pas tranche sur capture, le CTA
        // guide garde l'aplat `surfacePrimary`, a 3:1 au moins contre chaque
        // surface (teste), comme avant le chantier (revue phase 0, jetons D3).
        // En sombre, les deux paires sont identiques.
        final AppColorPair paireCta = guidee
            ? palette.surfacePrimary
            : palette.surfaceActionDouce;
        return _Peinture(
          fond: paireCta.background,
          encre: paireCta.applyTo,
          // Au survol, l'aplat plein ne change pas de teinte : il gagne le
          // filet fort. Une seconde nuance de violet serait une couleur de
          // plus, hors palette.
          filet: etat.survole || etat.presse
              ? palette.borderStrong.asBorderSide(width: 2)
              : null,
        );
      case NiveauAction.secondaire:
        {
          // Le survol passe au registre doux de l'accent : la paire change en
          // entier, le texte suit donc toujours son fond.
          final AppColorPair paire = etat.survole
              ? palette.washAccent
              : palette.surfaceRaised;
          // Surface pleine a filet fin (images CLV-10) : `borderStrong` garde
          // le contraste du contour, l'epaisseur 1 le rend discret.
          return _Peinture(
            fond: paire.background,
            encre: paire.applyTo,
            filet: palette.borderStrong.asBorderSide(),
          );
        }
      case NiveauAction.tertiaire:
        return _Peinture(
          fond: etat.survole ? palette.washAccent.background : null,
          encre: palette.inkAccent.applyTo,
        );
      case NiveauAction.destructive:
        if (doux) {
          return _Peinture(
            fond: palette.washAlert.background,
            encre: palette.washAlert.applyTo,
            filet: etat.survole || etat.presse
                ? palette.borderStrong.asBorderSide()
                : null,
          );
        }
        return _Peinture(
          fond: etat.survole ? palette.washAlert.background : null,
          encre: palette.inkAlert.applyTo,
        );
    }
  }
}

/// Ce qu'il faut peindre : un fond eventuel, une encre, un filet eventuel.
///
/// L'encre est une **fonction de style** et non une couleur : c'est la
/// signature commune a `AppColorPair.applyTo` et a `AppInkColor.applyTo`, et
/// c'est ce qui permet aux quatre niveaux de puiser dans les deux familles
/// sans qu'aucune couleur brute ne transite par ce type.
@immutable
class _Peinture {
  const _Peinture({required this.fond, required this.encre, this.filet});

  final Color? fond;
  final TextStyle Function(TextStyle base) encre;
  final BorderSide? filet;
}

/// La rangee d'actions du contrat B (DESIGN-GOV-2026-09-26 section 4 bis.2) :
/// la sortie avant la poursuite, groupees au bord de fin, chacune a la
/// largeur de son libelle, 8 entre les deux.
///
/// Quand la rangee ne tient pas sur une ligne, les actions s'empilent dans
/// le meme ordre, **a la meme largeur** (celle du plus long libelle, bornee a
/// la place offerte), le groupe toujours cale au bord de fin : jamais une
/// colonne en escalier (HU-1, EA-PL).
///
/// Extraite de `EtatSysteme` et de l'invitation du Foyer (HU-1) : une seule
/// rangee, jamais recopiee. Elle vit ici, avec les actions qu'elle range.
class RangeeActions extends MultiChildRenderObjectWidget {
  /// Cree la rangee ; [children] dans l'ordre de lecture du contrat B.
  const RangeeActions({required super.children, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduRangeeActions(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenduRangeeActions).sens = Directionality.of(context);
  }
}

class _DonneesRangee extends ContainerBoxParentData<RenderBox> {}

class _RenduRangeeActions extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesRangee>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesRangee> {
  _RenduRangeeActions(this._sens);

  static const double _ecart = AppSpacing.sm;

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesRangee) {
      child.parentData = _DonneesRangee();
    }
  }

  List<RenderBox> get _enfants {
    final List<RenderBox> liste = <RenderBox>[];
    RenderBox? enfant = firstChild;
    while (enfant != null) {
      liste.add(enfant);
      enfant = childAfter(enfant);
    }
    return liste;
  }

  /// Les largeurs naturelles, bornees a la place offerte.
  List<double> _largeurs(double max) => <double>[
    for (final RenderBox e in _enfants)
      math.min(e.getMaxIntrinsicWidth(double.infinity), max),
  ];

  double _somme(List<double> l) =>
      l.fold<double>(0, (double a, double b) => a + b) +
      _ecart * math.max(0, l.length - 1);

  @override
  double computeMinIntrinsicWidth(double height) => _enfants.fold<double>(
    0,
    (double m, RenderBox e) => math.max(m, e.getMinIntrinsicWidth(height)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _somme(_largeurs(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _mesure(BoxConstraints(maxWidth: width), seche: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _mesure(constraints, seche: true);

  @override
  void performLayout() {
    size = _mesure(constraints, seche: false);
  }

  /// Une ligne si tout tient, sinon une colonne de meme largeur ; le groupe
  /// au bord de fin. [seche] : mesure sans poser les enfants.
  Size _mesure(BoxConstraints c, {required bool seche}) {
    final List<RenderBox> enfants = _enfants;
    if (enfants.isEmpty) return c.smallest;
    final double max = c.maxWidth;
    final List<double> largeurs = _largeurs(max);
    final double ligne = _somme(largeurs);
    final bool enLigne = ligne <= max;
    final double groupe = enLigne ? ligne : largeurs.fold<double>(0, math.max);
    final double largeur = max.isFinite ? max : groupe;
    // Le bord de fin : a droite en LTR, a gauche en RTL.
    final bool rtl = _sens == TextDirection.rtl;
    double x(double depuisDebut, double w) =>
        rtl ? groupe - depuisDebut - w : largeur - groupe + depuisDebut;

    final List<Size> tailles = <Size>[
      for (int i = 0; i < enfants.length; i++)
        () {
          // Hauteur libre, comme dans un `Wrap` : le bouton garde la sienne.
          final BoxConstraints ce = BoxConstraints.tightFor(
            width: enLigne ? largeurs[i] : groupe,
          );
          if (seche) return enfants[i].getDryLayout(ce);
          enfants[i].layout(ce, parentUsesSize: true);
          return enfants[i].size;
        }(),
    ];

    double hauteur = 0;
    if (enLigne) {
      for (final Size t in tailles) {
        hauteur = math.max(hauteur, t.height);
      }
      if (!seche) {
        double debut = 0;
        for (int i = 0; i < enfants.length; i++) {
          (enfants[i].parentData! as _DonneesRangee).offset = Offset(
            x(debut, tailles[i].width),
            (hauteur - tailles[i].height) / 2,
          );
          debut += tailles[i].width + _ecart;
        }
      }
    } else {
      for (int i = 0; i < enfants.length; i++) {
        if (!seche) {
          (enfants[i].parentData! as _DonneesRangee).offset = Offset(
            x(0, groupe),
            hauteur,
          );
        }
        hauteur += tailles[i].height + (i < enfants.length - 1 ? _ecart : 0);
      }
    }
    return c.constrain(Size(largeur, hauteur));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
