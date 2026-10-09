import 'package:flutter/material.dart';

import '../i18n/isolat_bidi.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'pressable.dart';

/// Ce qu'une colonne devient quand le tableau se replie en cartes.
///
/// C'est la regle de transformation de `docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md`
/// section 4, portee par le type plutot que par la vigilance : « la colonne
/// identifiante devient le titre, deux a trois colonnes deviennent la ligne
/// secondaire, le reste passe dans le detail ».
enum RoleColonne {
  /// Le titre de la carte. **Une seule par collection.**
  identifiante,

  /// Rejoint la ligne secondaire de la carte, avec les autres, separees par un
  /// point median.
  secondaire,

  /// Prend sa propre ligne sous les autres. Pour ce qui est long : un contenu
  /// libre, une phrase, un objet serialise. Deux a trois colonnes se lisent sur
  /// une ligne commune ; une douzaine de mots, non.
  aPart,
}

/// La definition d'une colonne, valable pour les deux rendus.
///
/// **Une seule definition pour le tableau et pour la carte.** Deux listes de
/// colonnes divergeraient au premier ajout, et c'est exactement ce que
/// `05-regles-responsive.md` section 4 demande d'eviter.
@immutable
class ColonneDonnees<T> {
  /// Cree une colonne.
  const ColonneDonnees({
    required this.titre,
    required this.texte,
    this.role = RoleColonne.secondaire,
    this.flex = 1,
    this.tabulaire = false,
    this.rendu,
    this.rendreMemeSiTexteVide = false,
    this.insecable = false,
  });

  /// L'en-tete de colonne, en rendu tableau. Il sert aussi de libelle parle en
  /// rendu carte, ou aucun en-tete n'est visible.
  final String titre;

  /// La valeur, en texte. **Toujours renseignee, meme quand [rendu] l'est** :
  /// c'est elle que lisent les technologies d'assistance et le point median de
  /// la carte.
  final String Function(T ligne) texte;

  /// Ce que la colonne devient en rendu carte.
  final RoleColonne role;

  /// Sa part de largeur, en rendu tableau.
  final int flex;

  /// Vrai pour les chiffres et les horodatages : sans les chiffres tabulaires,
  /// une colonne de dates fait danser celle d'a cote a chaque ligne.
  final bool tabulaire;

  /// Un rendu riche facultatif : une pastille d'etat, une puce. Le texte reste
  /// obligatoire a cote, il ne le remplace pas.
  final Widget Function(BuildContext context, T ligne)? rendu;

  /// Pour une colonne [RoleColonne.aPart] dont [rendu] ne depend pas de
  /// [texte] : `false` (par defaut) garde le comportement existant, ou un
  /// [texte] vide fait disparaitre la cellule entiere en rendu carte -- c'est
  /// ce qui masque la cellule « Observer » de `CTR-01` quand la ligne ne
  /// l'est pas. `true` rend [rendu] meme si [texte] est vide : c'est le cas
  /// d'un menu d'actions, qui n'a rien a dire en texte.
  final bool rendreMemeSiTexteVide;

  /// Vrai pour une valeur qui se lit d'un bloc, un identifiant
  /// (« TEACHER-AS-000001 ») : en rendu tableau, elle ne passe pas a la ligne
  /// a ses traits d'union tant qu'elle tient entiere dans sa cellule (un
  /// gluon invisible, U+2060, suit chaque trait a l'affichage ; le libelle
  /// parle garde la valeur telle quelle). Trop longue pour sa cellule, elle
  /// se coupe a ses traits, jamais au milieu d'un mot.
  final bool insecable;
}

/// Un tableau dense sur desktop, une liste de cartes ailleurs.
///
/// **Le composant unique de `07-catalogue-composants.md` (P1).** Il n'existait
/// pas avant `ADM-04`, premier ecran du produit dont la forme naturelle est un
/// tableau (`05-regles-responsive.md` section 3).
///
/// Le seuil est le desktop et non la tablette : une tablette en portrait n'a
/// pas la largeur d'un tableau dense, et un tableau retreci est precisement ce
/// que la regle interdit.
///
/// **Il defile lui-meme**, et la page qui le porte passe donc `defilante: false`
/// a son `PageShell`. C'est ce qui permet a l'en-tete de colonnes de rester
/// collee en haut pendant que les lignes defilent : un en-tete pris dans le
/// defilement de la page disparaitrait a la premiere molette, et une colonne de
/// journal sans son en-tete ne se lit plus.
class DataCollection<T> extends StatelessWidget {
  /// Cree une collection.
  const DataCollection({
    required this.colonnes,
    required this.lignes,
    super.key,
    this.piedDePage,
    this.cle,
    this.onSelectionner,
  });

  /// Les colonnes, dans l'ordre d'affichage.
  final List<ColonneDonnees<T>> colonnes;

  /// Les donnees.
  final List<T> lignes;

  /// Ce qui suit la derniere ligne : un bouton « charger la suite », une phrase
  /// de fin. Il defile avec les lignes, il ne colle pas.
  final Widget? piedDePage;

  /// De quoi donner a chaque ligne une cle stable. Sans elle, une page ajoutee
  /// en fin de liste reconstruit tout.
  final Key Function(T ligne)? cle;

  /// Ce qui se passe quand une ligne ou une carte est choisie. `null` laisse
  /// la collection en pure lecture, comme avant l'ajout de ce parametre.
  final void Function(T ligne)? onSelectionner;

  @override
  Widget build(BuildContext context) {
    // DUREE-INSECABLE-5 : une page qui empile plusieurs collections dans son
    // propre defilement (Qualite, une collection par type d'anomalie) leur
    // donne une hauteur non bornee. La collection s'y deploie alors a sa
    // hauteur naturelle, sans defiler elle-meme ; avant, « Vertical viewport
    // was given unbounded height » vidait l'ecran a toute largeur.
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) =>
          _construire(contexte, integree: !contraintes.hasBoundedHeight),
    );
  }

  Widget _construire(BuildContext context, {required bool integree}) {
    // DUREE-INSECABLE-5 (reprise) : a texte agrandi (150 % et plus, le
    // seuil des choix en colonnes), un tableau de sept colonnes coupait ses
    // mots (« Enseigna / nt ») et tronquait ses en-tetes ; la collection se
    // replie alors en cartes, comme sous le seuil desktop (decide par
    // delegation le 09/10).
    final bool tableau =
        AppGabarit.de(context) == Gabarit.desktop &&
        MediaQuery.textScalerOf(context).scale(16) / 16 <
            AppGabarit.seuilTexteColonne;

    if (!tableau) {
      return _Defilement<T>(
        lignes: lignes,
        piedDePage: piedDePage,
        cle: cle,
        integree: integree,
        espacement: AppSpacing.md,
        constructeur: (BuildContext contexte, T ligne) => _Carte<T>(
          colonnes: colonnes,
          ligne: ligne,
          onSelectionner: onSelectionner,
        ),
      );
    }

    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);

    // Le filet et l'arrondi sont portes par le bloc entier, et le decoupage par
    // un seul `ClipRRect` : arrondir separement les deux coins hauts de
    // l'en-tete et les deux coins bas du corps demanderait deux arrondis
    // partiels, donc deux valeurs de rayon a tenir synchrones pour rien.
    return DecoratedBox(
      decoration: palette.surfaceRaised.decoration(
        borderRadius: metriques.arrondi,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Column(
          mainAxisSize: integree ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _EnTeteTableau<T>(colonnes: colonnes),
            Flexible(
              fit: integree ? FlexFit.loose : FlexFit.tight,
              child: _Defilement<T>(
                lignes: lignes,
                piedDePage: piedDePage,
                cle: cle,
                integree: integree,
                espacement: 0,
                constructeur: (BuildContext contexte, T ligne) =>
                    _LigneTableau<T>(
                      colonnes: colonnes,
                      ligne: ligne,
                      onSelectionner: onSelectionner,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La zone defilante, commune aux deux rendus.
class _Defilement<T> extends StatelessWidget {
  const _Defilement({
    required this.lignes,
    required this.constructeur,
    required this.espacement,
    required this.integree,
    this.piedDePage,
    this.cle,
  });

  final List<T> lignes;
  final Widget Function(BuildContext context, T ligne) constructeur;
  final double espacement;

  /// Vrai dans le defilement d'une page (hauteur non bornee) : la liste prend
  /// sa hauteur naturelle et laisse la page defiler.
  final bool integree;
  final Widget? piedDePage;
  final Key Function(T ligne)? cle;

  @override
  Widget build(BuildContext context) {
    final int total = lignes.length + (piedDePage == null ? 0 : 1);

    return ListView.builder(
      shrinkWrap: integree,
      physics: integree ? const NeverScrollableScrollPhysics() : null,
      itemCount: total,
      itemBuilder: (BuildContext contexte, int index) {
        if (index >= lignes.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: piedDePage,
          );
        }
        final T ligne = lignes[index];
        return Padding(
          key: cle?.call(ligne),
          padding: EdgeInsets.only(
            bottom: index == lignes.length - 1 ? 0 : espacement,
          ),
          child: constructeur(contexte, ligne),
        );
      },
    );
  }
}

/// L'en-tete de colonnes : surface enfoncee, collee en haut du tableau.
class _EnTeteTableau<T> extends StatelessWidget {
  const _EnTeteTableau({required this.colonnes});

  final List<ColonneDonnees<T>> colonnes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );

    return DecoratedBox(
      // Aucun arrondi ici : le `ClipRRect` du bloc s'en charge, et l'en-tete se
      // contente d'etre le seul plan enfonce du tableau.
      decoration: BoxDecoration(
        color: palette.surfaceSunken.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        // L'en-tete est exclu de l'arbre semantique : chaque cellule porte deja
        // le titre de sa colonne dans son propre libelle parle, et le lire deux
        // fois ferait entendre la grille avant le contenu.
        child: ExcludeSemantics(
          child: Row(
            children: <Widget>[
              for (final ColonneDonnees<T> colonne in colonnes)
                Expanded(
                  flex: colonne.flex,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.md,
                    ),
                    child: Text(
                      colonne.titre,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// Une ligne du tableau dense.
class _LigneTableau<T> extends StatelessWidget {
  const _LigneTableau({
    required this.colonnes,
    required this.ligne,
    this.onSelectionner,
  });

  final List<ColonneDonnees<T>> colonnes;
  final T ligne;
  final void Function(T ligne)? onSelectionner;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base = textes.bodySmall ?? const TextStyle();

    final Widget contenu = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final ColonneDonnees<T> colonne in colonnes)
            Expanded(
              flex: colonne.flex,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                child: _Cellule<T>(
                  colonne: colonne,
                  ligne: ligne,
                  style: colonne.tabulaire
                      ? AppTypography.tabulaire(base)
                      : base,
                ),
              ),
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: onSelectionner == null
          ? contenu
          : Pressable(
              onPress: () => onSelectionner!(ligne),
              respecterCibleTactile: false,
              child: contenu,
            ),
    );
  }
}

/// Une cellule, avec le titre de sa colonne dans son libelle parle.
///
/// Flutter ne sait pas associer un en-tete de tableau a ses cellules comme le
/// fait un `<th>` : sans ce libelle, un lecteur d'ecran enoncerait une suite de
/// valeurs sans dire de quoi elles sont les valeurs.
class _Cellule<T> extends StatelessWidget {
  const _Cellule({
    required this.colonne,
    required this.ligne,
    required this.style,
  });

  final ColonneDonnees<T> colonne;
  final T ligne;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget Function(BuildContext, T)? rendu = colonne.rendu;
    if (rendu != null) {
      return rendu(context, ligne);
    }
    // DUREE-INSECABLE-5 : la valeur suit le titre de la colonne dans le
    // libelle parle ; une valeur ancree pour s'afficher seule (« 12 jours »,
    // marque U+200E en tete) y perd son ancre ([sansAncre]), qui n'a pas a
    // se trouver au milieu d'un libelle. Le texte affiche, seul dans sa
    // cellule, la garde.
    return Semantics(
      label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}',
      excludeSemantics: true,
      child: colonne.insecable
          ? _TexteInsecable(colonne.texte(ligne), style: style)
          : Text(colonne.texte(ligne), style: style),
    );
  }
}

/// Le gluon invisible (WORD JOINER, U+2060) : aucune coupure a cote.
const String _gluon = '\u2060';

/// Un texte qui ne passe pas a la ligne a ses traits d'union quand il tient
/// entier dans la largeur offerte ([ColonneDonnees.insecable]).
class _TexteInsecable extends StatelessWidget {
  const _TexteInsecable(this.texte, {required this.style});

  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!texte.contains('-')) return Text(texte, style: style);
    final TextStyle complet = DefaultTextStyle.of(context).style.merge(style);
    final TextDirection sens = Directionality.of(context);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        final TextPainter p = TextPainter(
          text: TextSpan(text: texte, style: complet),
          textDirection: sens,
          textScaler: echelle,
          maxLines: 1,
        )..layout();
        final bool tient = p.width <= c.maxWidth;
        p.dispose();
        return Text(
          tient ? texte.replaceAll('-', '-$_gluon') : texte,
          style: style,
        );
      },
    );
  }
}

/// Une ligne repliee en carte.
class _Carte<T> extends StatelessWidget {
  const _Carte({
    required this.colonnes,
    required this.ligne,
    this.onSelectionner,
  });

  final List<ColonneDonnees<T>> colonnes;
  final T ligne;
  final void Function(T ligne)? onSelectionner;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Iterable<ColonneDonnees<T>> secondaires = colonnes.where(
      (ColonneDonnees<T> c) => c.role == RoleColonne.secondaire,
    );
    final Iterable<ColonneDonnees<T>> aPart = colonnes.where(
      (ColonneDonnees<T> c) => c.role == RoleColonne.aPart,
    );
    // Ecrit a la main plutot qu'avec `firstOrNull` : cette extension vient de
    // `package:collection`, que ce fichier n'a aucune autre raison d'importer.
    ColonneDonnees<T>? titre;
    for (final ColonneDonnees<T> colonne in colonnes) {
      if (colonne.role == RoleColonne.identifiante) {
        titre = colonne;
        break;
      }
    }

    // Le point median, et non un tiret : le tiret cadratin est refuse par
    // `tool/verifier_jetons.dart`, et le tiret court se confond avec un signe
    // moins dans une colonne de chiffres. DUREE-INSECABLE-4 : une valeur
    // ancree pour sa cellule (« 12 jours ») perd son ancre de sens (U+200E)
    // quand elle n'ouvre pas la ligne ([enchainer]).
    final String resume = enchainer(
      secondaires.map((ColonneDonnees<T> c) => c.texte(ligne)),
      ' · ',
    );

    // La carte entiere se lit comme un seul element : sans ce regroupement, un
    // lecteur d'ecran enoncerait quatre fragments sans lien entre eux.
    return MergeSemantics(
      child: AppCard(
        onPress: onSelectionner == null ? null : () => onSelectionner!(ligne),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (titre != null) ...<Widget>[
              titre.rendu?.call(context, ligne) ??
                  Text(
                    titre.texte(ligne),
                    style: textes.titleMedium ?? const TextStyle(),
                  ),
              Ecart.vSm,
            ],
            if (resume.isNotEmpty)
              Text(
                resume,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            for (final ColonneDonnees<T> colonne in aPart)
              if (colonne.rendreMemeSiTexteVide ||
                  colonne.texte(ligne).isNotEmpty) ...<Widget>[
                Ecart.vSm,
                colonne.rendu?.call(context, ligne) ??
                    Text(
                      colonne.texte(ligne),
                      style: palette.inkMuted.applyTo(
                        AppTypography.tabulaire(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
              ],
          ],
        ),
      ),
    );
  }
}
