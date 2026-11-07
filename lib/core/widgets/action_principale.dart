import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
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
    this.reussite,
    this.pleineLargeur,
    this.prefixe,
    this.fleche = false,
    this.pilule = false,
    this.compacte = false,
    this.doux = false,
    this.autofocus = false,
    this.focusNode,
    this.encre,
    this.libelleSemantique,
    this.affleurant = false,
    this.affirmee = false,
    this.margeHorizontaleReduite = false,
    this.libelleReduit = false,
  });

  /// La paire de la surface sur laquelle une action [NiveauAction.tertiaire]
  /// est posee, quand ce n'est pas celle de la page : la salle en direct
  /// (`surfaceInverse`, SALLE-ENCRE-1), ou `inkAccent` disparait (sombre sur
  /// sombre en clair, clair sur clair en sombre). Au repos, le texte en prend
  /// l'encre ; au survol, la paire douce de l'accent garde son propre couple.
  /// Ignore pour les autres niveaux, qui portent leur fond. `null` :
  /// `inkAccent`.
  final AppColorPair? encre;

  /// Vrai pour peindre le niveau [NiveauAction.principale] en aplat
  /// `surfacePrimary` (violet plein et encre claire en clair, accent plein en
  /// sombre) au lieu de la lavande douce, comme en Interface guidee. Reserve a
  /// l'action qui fait avancer un parcours (« Continuer », « Envoyer ma
  /// candidature ») et a l'unique invitation d'un ecran de la Salle d'examen
  /// (« Partager », CAND-06) : demande du directeur du 22/10/2026, la lavande
  /// douce y paraissait desactivee meme apres un choix. Un bouton inerte garde
  /// son propre aspect. Ignore pour les autres niveaux.
  final bool affirmee;

  /// Vrai pour poser le LIBELLE au bord de debut du contenu (lot K, point
  /// 3) : un bouton texte ([NiveauAction.tertiaire]) seul en debut de ligne
  /// se lisait en retrait de sa marge interne (12 en format reduit, 20
  /// sinon), « Mode focus » sous le titre du canal par exemple. Le bouton
  /// glisse de cette marge vers le debut (vers la droite en arabe) : son
  /// texte s'aligne sur le titre, sa cible garde ses 48 points et son fond
  /// de survol deborde dans la gouttiere. La mise en page ne change pas.
  /// Reserve aux boutons sans fond ni filet au repos, en debut de ligne.
  final bool affleurant;

  /// Ce que lit le lecteur d'ecran quand le verbe visible ne suffit pas :
  /// « Retirer devoir.pdf » sous un « Retirer » (revue COM-F-R, m3). Par
  /// defaut, le libelle.
  final String? libelleSemantique;

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
  /// salle (maquette M4, D1) et, depuis le 01/11/2026 (constat du directeur,
  /// pilote), a la cloture d'une classe : un geste qui ne s'annule pas doit se
  /// lire actif, jamais comme un bouton grise. Ignore pour les autres niveaux.
  final bool doux;

  /// Marges laterales reduites (8 au lieu de 20) et ecart de 4 entre l'icone
  /// et le libelle, **meme hauteur** : pour des boutons egaux cote a cote qui
  /// doivent garder leur libelle sur une ligne (CONNEXION-ALIGN, decision du
  /// pilote du 04/11/2026). Faux par defaut : rien ne change ailleurs. Sans
  /// effet sur le format reduit ([compacte]), qui a deja ses marges.
  final bool margeHorizontaleReduite;

  /// Libelle au registre `labelMedium` au lieu de `labelLarge`, pour des
  /// boutons egaux cote a cote dont le libelle doit tenir en deux lignes au
  /// plus (CONNEXION-ALIGN, decision du pilote du 04/11/2026). Faux par
  /// defaut : rien ne change ailleurs.
  final bool libelleReduit;

  /// Le libelle du bouton. **Un verbe et son objet** : « Poser un creneau »,
  /// pas « Valider » (`02-regles-ux.md` section 9).
  final String libelle;

  /// L'action. `null` rend le bouton inerte, et le dit visuellement.
  final VoidCallback? onPress;

  /// Le niveau hierarchique de l'action.
  final NiveauAction niveau;

  /// Remplace le libelle par un indicateur d'activite, et bloque la pression.
  final bool enCours;

  /// FLUIDITE-1 (DECISION-FLUIDITE-2026-11-07 §2) : « une reussite se
  /// voit ». A chaque nouvelle valeur non nulle, posee par l'ecran **apres
  /// la confirmation du serveur**, une coche breve est jouee une seule fois
  /// sur le bouton (opacite et echelle), puis le libelle revient. Nul : rien.
  /// En mouvement reduit, la coche s'affiche fixe le meme temps, sans
  /// mouvement.
  final Object? reussite;

  /// Vrai pour que le bouton prenne toute la largeur offerte, faux pour qu'il
  /// ne prenne que celle de son libelle. **Nul par defaut** (L4-07) : pleine
  /// largeur sur telephone seulement, ou le pouce vise une bande ; sur
  /// tablette et bureau, la largeur de son contenu et de ses marges, au lieu
  /// d'un bandeau de 1000 points pour un verbe.
  final bool? pleineLargeur;

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

  /// L'opacite du contenu (prefixe, libelle, fleche) pendant l'attente :
  /// l'attente se voit meme sans rotation (mouvement reduit).
  static const double _opaciteAttente = 0.6;

  /// La marge laterale du bouton : au repos, [repos] ; en attente sans
  /// prefixe, diminuee de la demi-place de l'anneau (jamais negative).
  double _margeLaterale(double repos) => enCours && prefixe == null
      ? math.max(0, repos - _AvecIndicateur.placeAnneau / 2)
      : repos;

  BorderRadius get _arrondi =>
      pilule ? AppRadius.arrondiFull : AppRadius.arrondiSm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final bool actif = onPress != null && !enCours;
    final bool reduit = compacte && !metriques.estEnfant;

    final Widget bouton = Pressable.selon(
      onPress: actif ? onPress : null,
      libelleSemantique: libelleSemantique ?? libelle,
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
        // R-12 (decision du directeur du 05/10, choix a) : `widthFactor: 1`.
        // Un `Center` sans facteur prenait toute la largeur offerte par un
        // parent souple (`Wrap`, `Align`, `Column` en debut) et y centrait la
        // pastille : « Mode focus », « Quitter le focus », « Enregistrer » se
        // posaient au milieu de leur ligne. Il ne garde que la cible tactile
        // autour de la pastille ; c'est le parent qui place le bouton (en
        // debut de ligne, miroir en arabe).
        return reduit ? Center(widthFactor: 1, child: corps) : corps;
      },
    );
    if (!affleurant) return bouton;
    final double marge = reduit ? AppSpacing.md : AppSpacing.xl;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.translate(
      offset: Offset(rtl ? marge : -marge, 0),
      child: bouton,
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
    final bool pleine =
        pleineLargeur ?? AppGabarit.de(context) == Gabarit.mobile;
    final _Peinture peinture = _peinturePour(
      palette,
      actif: actif,
      etat: etat,
      guidee: metriques.estEnfant || affirmee,
    );

    // K-54 : le contenu est centre en largeur ET en hauteur. Un `Container`
    // avec `alignment` s'etirait a toute la largeur offerte meme avec
    // `pleineLargeur: false` (un parent `Align` ou `Column` donne des
    // contraintes souples) : le bouton « compact » prenait 1408 de large sur
    // bureau. `Center(widthFactor: 1)` lui rend la largeur de son contenu, et
    // `heightFactor: 1` le centre dans la hauteur minimale sans l'etirer.
    return SizedBox(
      width: pleine ? double.infinity : null,
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
            // FLUIDITE-1 : en attente, sans prefixe, l'anneau entre dans la
            // rangee ; la marge laterale lui cede sa place de chaque cote,
            // pour que le bouton garde sa largeur.
            padding: EdgeInsets.symmetric(
              horizontal: _margeLaterale(
                reduit
                    ? AppSpacing.md
                    : margeHorizontaleReduite
                    ? AppSpacing.sm
                    : AppSpacing.xl,
              ),
              vertical: reduit ? AppSpacing.xs : AppSpacing.md,
            ),
            child: Center(
              widthFactor: pleine ? null : 1,
              heightFactor: 1,
              child: Semantics(
                liveRegion: enCours,
                // Correction du garde-cap (07/11) : l'attente se voit dans
                // TOUS les modes. Le contenu passe a [_opaciteAttente] :
                // anime sur `micro` en mouvement normal, immediat en
                // mouvement reduit (ou l'anneau ne tourne pas).
                child: _AvecIndicateur(
                  enCours: enCours,
                  reussite: reussite,
                  avecPrefixe: prefixe != null,
                  encre: peinture.encre(const TextStyle()).color,
                  child: AnimatedOpacity(
                    opacity: enCours ? _opaciteAttente : 1,
                    duration: AppMouvement.duree(context, AppMouvement.micro),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // BOUTON-ATTENTE (DECISION-FLUIDITE-2026-11-07 §2) : le
                        // prefixe, le libelle et la fleche restent en place pendant
                        // l'attente : le bouton garde sa taille, et un libelle
                        // d'attente (« Ouverture du support... ») se lit entier.
                        // L'attente vivante passe par-dessus (voir plus bas).
                        if (prefixe != null) ...<Widget>[
                          // En attente, l'anneau prend la place du prefixe :
                          // le prefixe garde sa place, invisible.
                          if (enCours)
                            Opacity(opacity: 0, child: prefixe)
                          else
                            prefixe!,
                          if (margeHorizontaleReduite) Ecart.hXs else Ecart.hSm,
                        ],
                        // Le libelle est deja porte par `Pressable` : le texte visible
                        // est retire de l'arbre semantique, sinon un lecteur d'ecran
                        // annonce le bouton deux fois.
                        Flexible(
                          child: ExcludeSemantics(
                            // DASH-MA-PROD (lecon 8) : a 200 % dans une place
                            // etroite, « Reessay / er » ; le mot entier se
                            // reduit plutot que d'etre coupe.
                            child: TexteSansCoupure(
                              libelle,
                              textAlign: TextAlign.center,
                              style: _styleLibelle(
                                context,
                                peinture,
                                actif: actif,
                              ),
                            ),
                          ),
                        ),
                        if (fleche) ...<Widget>[
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
      (libelleReduit
              ? Theme.of(context).textTheme.labelMedium
              : Theme.of(context).textTheme.labelLarge) ??
          const TextStyle(),
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
        final AppColorPair? pose = encre;
        if (pose != null) {
          return _Peinture(
            fond: etat.survole ? palette.washAccent.background : null,
            encre: etat.survole ? palette.washAccent.applyTo : pose.applyTo,
          );
        }
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
  const RangeeActions({
    required super.children,
    this.pileePleineLargeur = false,
    super.key,
  });

  /// Vrai pour qu'une rangee qui ne tient pas s'empile **pleine largeur**
  /// (toute la place offerte) au lieu de la largeur du plus long libelle :
  /// le formulaire d'entree sur ordinateur a texte agrandi, qui retrouve
  /// alors la colonne du telephone (directeur, 25/10/2026). Faux par defaut.
  final bool pileePleineLargeur;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduRangeeActions(Directionality.of(context), pileePleineLargeur);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenduRangeeActions)
      ..sens = Directionality.of(context)
      ..pileePleineLargeur = pileePleineLargeur;
  }
}

class _DonneesRangee extends ContainerBoxParentData<RenderBox> {}

class _RenduRangeeActions extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesRangee>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesRangee> {
  _RenduRangeeActions(this._sens, this._pileePleineLargeur);

  static const double _ecart = AppSpacing.sm;

  bool _pileePleineLargeur;
  set pileePleineLargeur(bool valeur) {
    if (valeur == _pileePleineLargeur) return;
    _pileePleineLargeur = valeur;
    markNeedsLayout();
  }

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
    final double groupe = enLigne
        ? ligne
        : _pileePleineLargeur && max.isFinite
        ? max
        : largeurs.fold<double>(0, math.max);
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

/// Pose l'indicateur du bouton sans rien changer a sa taille : en attente,
/// l'anneau qui tourne devant le libelle attenue (dans la rangee, la marge
/// laterale lui cedant sa place) ; apres une reussite, la coche jouee une
/// fois. Au repos, le contenu seul. Miroir en arabe par la rangee.
class _AvecIndicateur extends StatelessWidget {
  const _AvecIndicateur({
    required this.enCours,
    required this.reussite,
    required this.avecPrefixe,
    required this.encre,
    required this.child,
  });

  final bool enCours;
  final Object? reussite;
  final bool avecPrefixe;
  final Color? encre;
  final Widget child;

  /// La taille de l'anneau : celle de l'ancien anneau fige.
  static const double _tailleAnneau = AppSpacing.xl;

  /// La place que l'anneau prend dans la rangee : lui et son ecart.
  static const double placeAnneau = _tailleAnneau + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    if (enCours) {
      final Widget anneau = SizedBox.square(
        dimension: _tailleAnneau,
        child: AttenteVivante(encre: encre),
      );
      // Avec un prefixe : l'anneau se pose sur le prefixe devenu invisible.
      if (avecPrefixe) {
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[child, anneau],
        );
      }
      // Sans prefixe : l'anneau entre dans la rangee, devant le libelle
      // attenue ; la marge du bouton lui a cede sa place.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          anneau,
          Ecart.hSm,
          Flexible(child: child),
        ],
      );
    }
    final Object? jeton = reussite;
    if (jeton == null) return child;
    return CocheReussite(
      key: ValueKey<Object>(jeton),
      encre: encre,
      child: child,
    );
  }
}

/// L'attente vivante d'un bouton (BOUTON-ATTENTE, FLUIDITE-1, correction du
/// directeur du 07/11/2026 : « ca doit dire : attendez, je fais quelque
/// chose ») : un anneau indetermine qui tourne vraiment, a la place et a la
/// taille de l'ancien anneau fige, a cote du libelle attenue (DESIGN-GOV :
/// un indicateur local dans un bouton est permis).
///
/// - Le bouton garde sa taille, n'est plus cliquable, et l'attente est
///   annoncee au lecteur d'ecran (« Chargement », region vivante).
/// - Mouvement reduit (systeme ou `ReglageMouvement`) : aucune rotation ; un
///   pictogramme d'attente fixe ([AppIcons.attente]) et le libelle attenue.
@visibleForTesting
class AttenteVivante extends StatelessWidget {
  /// Cree l'attente, dans l'encre du bouton.
  const AttenteVivante({required this.encre, super.key});

  /// L'encre de l'anneau : celle du libelle.
  final Color? encre;

  @override
  Widget build(BuildContext context) {
    final bool fixe = AppMouvement.mouvementReduit(context);
    return Semantics(
      liveRegion: true,
      label: t.commun.chargement,
      child: ExcludeSemantics(
        child: fixe
            ? IconTheme(
                data: IconThemeData(color: encre, size: AppSpacing.xl),
                child: Icon(AppIcons.attente.repos),
              )
            : RepaintBoundary(
                child: CircularProgressIndicator(strokeWidth: 2, color: encre),
              ),
      ),
    );
  }
}

/// La coche de reussite (FLUIDITE-1, decision §2) : le libelle s'efface, la
/// coche entre (opacite et echelle), reste [AppMouvement.reussiteMaintien],
/// puis sort et le libelle revient. **Une seule fois par jeton** : l'etat vit
/// tant que le jeton ne change pas. Mouvement reduit : la coche s'affiche
/// fixe le meme temps, sans mouvement. Annoncee au lecteur d'ecran.
@visibleForTesting
class CocheReussite extends StatefulWidget {
  /// Cree la coche, dans l'encre du bouton, par-dessus [child].
  const CocheReussite({required this.encre, required this.child, super.key});

  /// L'encre de la coche : celle du libelle.
  final Color? encre;

  /// Le contenu du bouton.
  final Widget child;

  @override
  State<CocheReussite> createState() => _CocheReussiteState();
}

class _CocheReussiteState extends State<CocheReussite>
    with SingleTickerProviderStateMixin {
  static const Duration _entree = AppMouvement.apparition;
  static const Duration _sortie = AppMouvement.disparitionOpacite;
  static const Duration _maintien = AppMouvement.reussiteMaintien;

  late final AnimationController _jeu = AnimationController(
    vsync: this,
    duration: _entree + _maintien + _sortie,
  );
  bool _lance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lance) return;
    _lance = true;
    _jeu.forward().ignore();
    // Le bouton actif fond son contenu dans son propre libelle : la reussite
    // est dite au lecteur d'ecran par une annonce, une seule fois.
    SemanticsService.sendAnnouncement(
      View.of(context),
      t.commun.reussite,
      Directionality.of(context),
    );
  }

  @override
  void dispose() {
    _jeu.dispose();
    super.dispose();
  }

  double get _total =>
      (_entree + _maintien + _sortie).inMicroseconds.toDouble();

  /// De 0 a 1 pendant l'entree, 1 pendant le maintien, de 1 a 0 a la sortie.
  double _presence(double v) {
    final double t = v * _total;
    final double finEntree = _entree.inMicroseconds.toDouble();
    final double debutSortie = (_entree + _maintien).inMicroseconds.toDouble();
    if (t <= finEntree) return t / finEntree;
    if (t < debutSortie) return 1;
    return math.max(0, 1 - (t - debutSortie) / _sortie.inMicroseconds);
  }

  @override
  Widget build(BuildContext context) {
    final bool fixe = AppMouvement.mouvementReduit(context);
    return AnimatedBuilder(
      animation: _jeu,
      builder: (BuildContext _, Widget? contenu) {
        final bool fini = _jeu.value >= 1;
        // Mouvement reduit : presente entiere tant que le jeu court, sans
        // entree ni sortie animees.
        final double p = fini ? 0 : (fixe ? 1 : _presence(_jeu.value));
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Opacity(opacity: 1 - p, child: contenu),
            if (!fini)
              ExcludeSemantics(
                child: Opacity(
                  opacity: p,
                  child: Transform.scale(
                    scale: fixe
                        ? 1
                        : 0.6 + 0.4 * AppMouvement.entree.transform(p),
                    child: IconTheme(
                      data: IconThemeData(
                        color: widget.encre,
                        size: AppSpacing.xl,
                      ),
                      child: Icon(AppIcons.succes.repos),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
