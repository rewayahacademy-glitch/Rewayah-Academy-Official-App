import 'package:flutter/material.dart';

import 'app_color_pair.dart';

/// La palette de l'application, exposee comme extension de theme.
///
/// **C'est le seul fichier du depot autorise a contenir une valeur de couleur
/// litterale.** `tool/verifier_jetons.dart` echoue si un `Color(0x...)` ou un
/// `Colors.` apparait ailleurs dans `lib/`.
///
/// Source : `docs/produit/design-tokens.md` section 1, revision du 7 septembre
/// 2026 (refonte UX/UI v1.0, ADR-018). Les valeurs y sont figees telles
/// quelles avec leur mesure de contraste : elles ne se recalculent pas ici.
/// `test/theme/contraste_test.dart` rejoue chaque mesure du tableau.
///
/// Trois familles de jetons, et elles ne se melangent pas
/// (`docs/design/01-systeme-visuel.md` sections 2 et 3) :
///
/// - **la rampe neutre** : trois surfaces, trois bordures, trois encres. C'est
///   elle qui porte la hierarchie de l'ecran ;
/// - **les paires pleines** : un aplat sature et son encre. **Une seule zone
///   pleine par ecran**, au plus ;
/// - **les paires douces** : une teinte tres pale et une encre foncee de la
///   meme famille. C'est le registre par defaut de tout ce qui informe.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Cree une palette.
  const AppPalette({
    required this.surfaceRaised,
    required this.surfaceCanvas,
    required this.surfaceSunken,
    required this.borderHairline,
    required this.borderResting,
    required this.borderStrong,
    required this.inkFaint,
    required this.inkMuted,
    required this.inkStrong,
    required this.surfacePrimary,
    required this.surfaceSuccess,
    required this.surfaceWarning,
    required this.surfaceAlert,
    required this.surfaceInverse,
    required this.washAccent,
    required this.washSuccess,
    required this.washWarning,
    required this.washAlert,
    required this.washFamily,
    required this.surfaceQuran,
    required this.inkAccent,
    required this.inkSuccess,
    required this.inkWarning,
    required this.inkAlert,
    required this.ombre,
  });

  /// La palette claire de l'application.
  ///
  /// Voir aussi [AppPalette.sombre], le lot T3 (Bible V2 section 7.3,
  /// ADR-019, ecart 23 de `decisions.md`) : aucune mesure de la palette
  /// sombre ne se transpose de celle-ci, chacune a ete calculee separement.
  factory AppPalette.claire() => const AppPalette(
    // --- Rampe neutre chaude (design-tokens.md 1.3) -----------------------
    //
    // Elle relie le creme au noir de la charte en passant par la taupe
    // rechauffee. Les contrastes indiques sont mesures SUR LE CREME.
    //
    // Cartes, tuiles, feuilles, menus, barres de navigation.
    surfaceRaised: AppColorPair(
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF1C1D21),
    ),
    // Fond general. Le jaunissement se lit sur l'ecart entre canaux, pas sur
    // la teinte : 248, 244, 238 donne un ecart de 10, contre 34 pour un creme
    // jaunatre. Teinte 36 degres, donc franchement chaude et a dix degres du
    // jaune (design-tokens.md 1.2).
    surfaceCanvas: AppColorPair(
      background: Color(0xFFF8F4EE),
      onBackground: Color(0xFF1C1D21),
    ),
    // Champs, en-tetes de tableau, pistes, cases vides de grille. 1.06 sur le
    // creme : c'est un plan, pas un trait.
    surfaceSunken: AppColorPair(
      background: Color(0xFFF3EDE7),
      onBackground: Color(0xFF1C1D21),
    ),
    // Filet entre deux blocs, contour de carte. 1.36 sur le creme (lot T2,
    // remonte depuis 1.20 : le langage etait trop timide, cause n3 mesuree du
    // rejet du 11 septembre 2026). Toujours decoratif : reste sous 3:1.
    borderHairline: AppInkColor(Color(0xFFDCD2C8)),
    // Contour d'un controle au repos. 1.69 sur le creme (lot T2, remonte
    // depuis 1.45). Decoratif, et toujours accompagne d'un fond enfonce,
    // jamais seul a delimiter.
    //
    // Les trois surfaces neutres (surfaceRaised, surfaceCanvas, surfaceSunken)
    // ne bougent PAS au lot T2, contrairement a l'intention initiale de les
    // ecarter davantage : mesure faite, le moindre assombrissement de
    // surfaceSunken fait chuter borderStrong sous 3:1 sur cette surface (2,96
    // des le premier cran teste), qui n'a deja que 3,21 de marge. La
    // profondeur manquante se corrige par l'ombre et les bordures, qui n'ont
    // pas ce plancher, pas par les surfaces.
    borderResting: AppInkColor(Color(0xFFC9BCB1)),
    // **La seule bordure porteuse de sens** : selection, focus, bord de
    // tableau dense. 3.40, donc au dessus du seuil de 3:1 de WCAG 1.4.11.
    // C'est ce jeton qui remplace l'ancien borderDefault mesure a 1.86, qui
    // servait a la fois de decor et de sens et ne pouvait pas faire les deux.
    borderStrong: AppInkColor(Color(0xFF8F8279)),
    // Texte tertiaire, metadonnees. 4.74 sur le creme.
    //
    // ATTENTION : **interdit sur surfaceSunken**, ou il mesure 4.48, sous le
    // seuil de 4.5. C'est le seul jeton de la rampe qui a une surface
    // interdite. Passer par [encreSecondaireSur] plutot que de s'en souvenir.
    inkFaint: AppInkColor(Color(0xFF756B63)),
    // Texte secondaire. 6.56 sur le creme, 6.19 sur la surface enfoncee.
    inkMuted: AppInkColor(Color(0xFF5E564F)),
    // Texte principal. 15.37 sur le creme. C'est le noir de la charte.
    inkStrong: AppInkColor(Color(0xFF1C1D21)),

    // --- Paires pleines (design-tokens.md 1.4) ----------------------------
    //
    // Un aplat sature et son encre. **Une seule zone pleine par ecran** : si un
    // ecran en contient deux, l'une des deux est un badge et passe en registre
    // doux (01-systeme-visuel.md section 3).
    //
    // L'action principale.
    surfacePrimary: AppColorPair(
      background: Color(0xFF8652E6),
      onBackground: Color(0xFFFFFFFF),
    ),
    // Pastille en direct. **Jamais de texte blanc** : la charte d'origine
    // mesurait 1.46 avec du blanc.
    surfaceSuccess: AppColorPair(
      background: Color(0xFF70EE9C),
      onBackground: Color(0xFF1C1D21),
    ),
    // Reserve aux pastilles. **Jamais de texte blanc** : 1.75 avec du blanc.
    // Un avertissement de pleine largeur passe par washWarning, pas par ici.
    surfaceWarning: AppColorPair(
      background: Color(0xFFFFB703),
      onBackground: Color(0xFF1C1D21),
    ),
    // Contour de champ en erreur, pastille critique. Rouge assombri :
    // l'original 0xFFFF385C echouait a 3.51 sur du blanc.
    surfaceAlert: AppColorPair(
      background: Color(0xFFB01B3C),
      onBackground: Color(0xFFFFFFFF),
    ),
    // Le bandeau permanent de la salle.
    surfaceInverse: AppColorPair(
      background: Color(0xFF1C1D21),
      onBackground: Color(0xFFF8F4EE),
    ),

    // --- Paires douces (design-tokens.md 1.5) -----------------------------
    //
    // Une teinte pale et une encre foncee de la MEME famille. Registre par
    // defaut de tout ce qui informe : bandeaux, badges, lignes d'alerte, fonds
    // de section. C'est la reponse au "pas brutal" du diagnostic.
    washAccent: AppColorPair(
      background: Color(0xFFE9E0FC),
      onBackground: Color(0xFF5B36B0),
    ),
    washSuccess: AppColorPair(
      background: Color(0xFFC6F0D9),
      onBackground: Color(0xFF0F5F35),
    ),
    washWarning: AppColorPair(
      background: Color(0xFFFCE7B8),
      onBackground: Color(0xFF6B4A00),
    ),
    washAlert: AppColorPair(
      background: Color(0xFFFBE3E9),
      onBackground: Color(0xFFB01B3C),
    ),
    // Couleur de DOMAINE, pas d'etat : le foyer. C'est le rose pale de la
    // charte, qui etait le fond de tout le produit et qui recoit enfin un role
    // (cartes enfant de TUT-01, avatars, TUT-05).
    washFamily: AppColorPair(
      background: Color(0xFFF1E3E4),
      onBackground: Color(0xFF1C1D21),
    ),
    // Couleur de DOMAINE : le lecteur. Un parchemin legerement plus chaud que
    // le creme, ce que parcours-utilisateurs.md demandait pour ELV-04.
    surfaceQuran: AppColorPair(
      background: Color(0xFFF3EAD9),
      onBackground: Color(0xFF1C1D21),
    ),

    // --- Les quatre encres semantiques sur fond clair ----------------------
    //
    // Ce sont les onBackground des paires douces, exposes separement pour un
    // texte ou une icone pose directement sur le creme ou sur une carte.
    // Mesures sur le creme : 7.37, 7.08, 7.36, 6.25.
    //
    // Le violet plein ne s'ecrit JAMAIS en texte sur une surface claire : il
    // mesure 4.39 sur le creme et 4.14 sur la surface enfoncee. C'est la raison
    // d'etre d'inkAccent.
    inkAccent: AppInkColor(Color(0xFF5B36B0)),
    inkSuccess: AppInkColor(Color(0xFF0F5F35)),
    inkWarning: AppInkColor(Color(0xFF6B4A00)),
    // Le piege deja paye : `surfaceAlert.applyTo(...)` pose sur la page ecrit
    // en BLANC, puisque le blanc est l'encre du fond rouge. Blanc sur le fond
    // general mesure 1.19 : le message existait dans l'arbre de widgets et
    // n'existait pas a l'ecran. Tout message d'erreur pose sur une surface
    // claire passe par cette encre.
    inkAlert: AppInkColor(Color(0xFFB01B3C)),

    // --- Ombre (design-tokens.md 9) ---------------------------------------
    //
    // Chaude, jamais grise : une ombre neutre sur un fond creme se lit comme
    // une salissure. Les quatre niveaux sont dans `app_elevation.dart`.
    ombre: AppShadowColor(Color(0xFF3A302A)),
  );

  /// La palette sombre de l'application (lot T3, Bible V2 section 7.3,
  /// ADR-019, ecart 23 de `decisions.md`).
  ///
  /// Toutes les mesures ci-dessous sont calculees pour CETTE palette : aucune
  /// ne se transpose de [AppPalette.claire]. Methode : la meme formule WCAG
  /// que `test/theme/contraste_test.dart` (luminance relative de
  /// `Color.computeLuminance`), rejouee par
  /// `test/theme/contraste_sombre_test.dart`.
  ///
  /// Deux familles de jetons sont **reutilisees telles quelles**, et ce n'est
  /// pas un oubli :
  ///
  /// - les quatre paires pleines ([surfacePrimary], [surfaceSuccess],
  ///   [surfaceWarning], [surfaceAlert]) sont des couleurs de marque
  ///   saturees : chacune cree son propre plan lumineux (un aplat vif) et son
  ///   contraste interne fond/encre ne depend pas du canevas alentour. Seule
  ///   [surfaceInverse] s'inverse : son role est justement de designer le pole
  ///   oppose au canevas courant, donc elle bascule creme+noir au lieu de
  ///   noir+creme ;
  /// - [ombre] reste la meme teinte chaude : c'est une couleur de marque, pas
  ///   un jeton de surface, au meme titre que les paires pleines.
  ///
  /// La rampe neutre et les paires douces, elles, sont entierement neuves.
  factory AppPalette.sombre() => const AppPalette(
    // --- Rampe neutre chaude sombre -----------------------------------
    //
    // Ancree sur `0xFF1C1D21`, deja le noir de la charte cote clair (texte,
    // et fond de `surfaceInverse`) : le canevas sombre reprend cette teinte
    // etablie plutot que d'en inventer une nouvelle. Les deux autres plans
    // sont neufs et gardent le sens du clair : eleve est plus clair que le
    // canevas, enfonce est plus sombre.
    //
    // Cartes, tuiles, feuilles, menus, barres de navigation. Plus clair que
    // le canevas (1.24:1), symetrique du blanc plus clair que le creme cote
    // clair.
    surfaceRaised: AppColorPair(
      background: Color(0xFF302E29),
      onBackground: Color(0xFFF5F1E9),
    ),
    // Fond general sombre. Reprend le noir de la charte.
    surfaceCanvas: AppColorPair(
      background: Color(0xFF1C1D21),
      onBackground: Color(0xFFF5F1E9),
    ),
    // Champs, en-tetes de tableau, pistes, cases vides de grille. Plus sombre
    // que le canevas (1.12:1), symetrique de la surface enfoncee du clair.
    surfaceSunken: AppColorPair(
      background: Color(0xFF121110),
      onBackground: Color(0xFFF5F1E9),
    ),
    // Filet entre deux blocs, contour de carte. 1.44 sur le canevas.
    // Toujours decoratif : reste sous 3:1.
    borderHairline: AppInkColor(Color(0xFF3B3833)),
    // Contour d'un controle au repos. 1.81 sur le canevas. Decoratif.
    borderResting: AppInkColor(Color(0xFF4C463F)),
    // **La seule bordure porteuse de sens**, comme cote clair : selection,
    // focus, bord de tableau dense. 6.13 sur le canevas, 4.93 sur la surface
    // elevee, 6.86 sur la surface enfoncee : passe 3:1 (WCAG 1.4.11) sur les
    // TROIS surfaces, avec une marge plus large que cote clair (qui n'avait
    // que 3.21 sur la plus fine des trois).
    borderStrong: AppInkColor(Color(0xFFA69A8F)),
    // Texte tertiaire, metadonnees. 6.00 sur le canevas, 4.83 sur la surface
    // elevee, 6.72 sur la surface enfoncee.
    //
    // A LA DIFFERENCE DU CLAIR : ce jeton n'a PAS de surface interdite ici.
    // Cote clair, inkFaint echouait a 4.48 sur surfaceSunken (juste sous
    // 4.5) parce que la surface enfoncee etait a peine plus sombre que le
    // canevas, donc plus proche de l'encre. Cote sombre, la surface la plus
    // proche d'une encre claire est au contraire la surface ELEVEE (plus
    // claire que le canevas) : la valeur retenue ici (0xFF9D9A93) a ete
    // choisie pour rester au-dessus de 4.5 meme sur cette surface (4.83), ce
    // qui ferme le trou plutot que de le deplacer. [encreSecondaireSur] reste
    // donc valide mais ne trouve plus jamais son cas d'echec sur cette
    // palette : voir `contraste_sombre_test.dart`.
    inkFaint: AppInkColor(Color(0xFF9D9A93)),
    // Texte secondaire. 9.28 sur le canevas, 7.48 sur la surface elevee,
    // 10.40 sur la surface enfoncee.
    inkMuted: AppInkColor(Color(0xFFC4C0B8)),
    // Texte principal. 14.95 sur le canevas, 12.04 sur la surface elevee,
    // 16.74 sur la surface enfoncee. Un blanc casse chaud, pas un blanc pur :
    // meme famille que le creme du clair, juste a l'autre bout de la rampe.
    inkStrong: AppInkColor(Color(0xFFF5F1E9)),

    // --- Paires pleines : REUTILISEES telles quelles (voir doc de classe) --
    surfacePrimary: AppColorPair(
      background: Color(0xFF8652E6),
      onBackground: Color(0xFFFFFFFF),
    ),
    surfaceSuccess: AppColorPair(
      background: Color(0xFF70EE9C),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceWarning: AppColorPair(
      background: Color(0xFFFFB703),
      onBackground: Color(0xFF1C1D21),
    ),
    surfaceAlert: AppColorPair(
      background: Color(0xFFB01B3C),
      onBackground: Color(0xFFFFFFFF),
    ),
    // Le bandeau permanent de la salle. INVERSEE par rapport au clair : son
    // role est de designer le pole oppose au canevas courant, donc elle
    // bascule vers le creme (avec le noir en encre) au lieu du noir (avec le
    // creme en encre). Memes deux couleurs, roles swappes : le contraste
    // reste 15.37, exact au clair puisque c'est la meme paire de teintes.
    surfaceInverse: AppColorPair(
      background: Color(0xFFF8F4EE),
      onBackground: Color(0xFF1C1D21),
    ),

    // --- Paires douces : NEUVES, teinte sombre mate + encre claire ---------
    //
    // Le registre doux du clair (teinte tres pale + encre foncee) se lirait
    // comme une pastille lumineuse posee sur un ecran sombre : il s'inverse
    // en teinte sombre desaturee + encre claire de la meme famille, en
    // gardant la meme discretion vis-a-vis du canevas (rapports 1.04 a 1.21,
    // comparables aux 1.09-1.16 du clair : la teinte reste a peine
    // distinguable du fond, ce n'est jamais un aplat).
    washAccent: AppColorPair(
      background: Color(0xFF2E2247),
      onBackground: Color(0xFFC9B8F5),
    ),
    washSuccess: AppColorPair(
      background: Color(0xFF12301F),
      onBackground: Color(0xFF8FE0B0),
    ),
    washWarning: AppColorPair(
      background: Color(0xFF3A2A05),
      onBackground: Color(0xFFF5C56B),
    ),
    washAlert: AppColorPair(
      background: Color(0xFF3B141B),
      onBackground: Color(0xFFF2A0B4),
    ),
    // Couleur de DOMAINE, pas d'etat : le foyer. Reprend l'encre generique
    // (inkStrong sombre), comme le clair le fait deja avec son inkStrong a
    // lui plutot qu'une encre rose dediee.
    washFamily: AppColorPair(
      background: Color(0xFF3A262A),
      onBackground: Color(0xFFF5F1E9),
    ),
    // Couleur de DOMAINE : le lecteur. Meme logique, encre generique.
    surfaceQuran: AppColorPair(
      background: Color(0xFF2E2417),
      onBackground: Color(0xFFF5F1E9),
    ),

    // --- Les quatre encres semantiques sur fond sombre ---------------------
    //
    // Les onBackground des paires douces ci-dessus, exposes separement,
    // exactement comme cote clair. Mesurees sur le canevas puis sur la
    // surface elevee : 9.35/7.53, 10.79/8.69, 10.49/8.45, 8.39/6.76.
    //
    // Le violet plein ne s'ecrit toujours pas en texte directement sur une
    // surface sombre : il mesure 3.50 sur le canevas (le piege du clair, ou
    // il mesurait 4.39, se reproduit ici en pire : la marge d'echec est plus
    // large). inkAccent reste la raison d'etre de ce contournement.
    inkAccent: AppInkColor(Color(0xFFC9B8F5)),
    inkSuccess: AppInkColor(Color(0xFF8FE0B0)),
    inkWarning: AppInkColor(Color(0xFFF5C56B)),
    // A LA DIFFERENCE DU CLAIR : le piege de `surfaceAlert.applyTo(...)` pose
    // directement sur la page (l'encre blanche prevue pour le fond rouge) ne
    // se reproduit PAS ici. Sur le creme, le blanc mesurait 1.10 et le
    // message disparaissait. Sur le canevas sombre, ce meme blanc mesure
    // 16.84 : il reste parfaitement lisible. Documente ici pour que la
    // difference ne soit pas prise pour un oubli de mesure -- inkAlert reste
    // neanmoins la bonne reponse par coherence de regle (toujours passer par
    // l'encre semantique, jamais par l'encre d'une paire pleine), pas par
    // necessite de contraste sur cette palette precise.
    inkAlert: AppInkColor(Color(0xFFF2A0B4)),

    // --- Ombre : REUTILISEE telle quelle (voir doc de classe) --------------
    ombre: AppShadowColor(Color(0xFF3A302A)),
  );

  /// Cartes, tuiles Bento, feuilles, menus, barres de navigation.
  final AppColorPair surfaceRaised;

  /// Fond general de l'application. Rien n'y est pose directement sans etre
  /// dans une carte ou une section.
  final AppColorPair surfaceCanvas;

  /// Champs de saisie, en-tetes de tableau, pistes de progression, cases vides.
  final AppColorPair surfaceSunken;

  /// Filet entre deux blocs, contour de carte. Decoratif.
  final AppInkColor borderHairline;

  /// Contour d'un controle au repos. Decoratif.
  final AppInkColor borderResting;

  /// Contour porteur de sens : selection, focus, bord de tableau.
  final AppInkColor borderStrong;

  /// Texte tertiaire. **Interdit sur [surfaceSunken]** : voir
  /// [encreSecondaireSur].
  final AppInkColor inkFaint;

  /// Texte secondaire.
  final AppInkColor inkMuted;

  /// Texte principal.
  final AppInkColor inkStrong;

  /// Actions principales.
  final AppColorPair surfacePrimary;

  /// Succes et validation, en pastille.
  final AppColorPair surfaceSuccess;

  /// Avertissement, en pastille uniquement.
  final AppColorPair surfaceWarning;

  /// Alerte et erreur.
  final AppColorPair surfaceAlert;

  /// Surface inversee : le bandeau permanent de la salle.
  final AppColorPair surfaceInverse;

  /// Registre doux de l'accent.
  final AppColorPair washAccent;

  /// Registre doux du succes.
  final AppColorPair washSuccess;

  /// Registre doux de l'avertissement.
  final AppColorPair washWarning;

  /// Registre doux de l'alerte.
  final AppColorPair washAlert;

  /// Teinte du domaine foyer.
  final AppColorPair washFamily;

  /// Teinte du domaine lecteur.
  final AppColorPair surfaceQuran;

  /// Accent violet lisible sur une surface claire.
  final AppInkColor inkAccent;

  /// Vert de succes lisible sur une surface claire.
  final AppInkColor inkSuccess;

  /// Brun d'avertissement lisible sur une surface claire.
  final AppInkColor inkWarning;

  /// Rouge d'alerte lisible sur une surface claire. **A employer pour tout
  /// message d'erreur pose sur la page**, jamais `surfaceAlert.applyTo`, qui
  /// ecrirait en blanc.
  final AppInkColor inkAlert;

  /// Couleur d'ombre chaude. Les niveaux sont dans `app_elevation.dart`.
  final AppShadowColor ombre;

  /// L'encre de texte secondaire valable sur [surface].
  ///
  /// [inkFaint] mesure 4.48 sur [surfaceSunken], sous le seuil de 4.5 : c'est
  /// le seul trou de la rampe. Plutot que de compter sur la vigilance de qui
  /// ecrit l'ecran, on passe par ici, qui rend le choix a la surface.
  AppInkColor encreSecondaireSur(AppColorPair surface) =>
      surface == surfaceSunken ? inkMuted : inkFaint;

  /// Raccourci de lecture depuis un widget.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    AppColorPair? surfaceRaised,
    AppColorPair? surfaceCanvas,
    AppColorPair? surfaceSunken,
    AppInkColor? borderHairline,
    AppInkColor? borderResting,
    AppInkColor? borderStrong,
    AppInkColor? inkFaint,
    AppInkColor? inkMuted,
    AppInkColor? inkStrong,
    AppColorPair? surfacePrimary,
    AppColorPair? surfaceSuccess,
    AppColorPair? surfaceWarning,
    AppColorPair? surfaceAlert,
    AppColorPair? surfaceInverse,
    AppColorPair? washAccent,
    AppColorPair? washSuccess,
    AppColorPair? washWarning,
    AppColorPair? washAlert,
    AppColorPair? washFamily,
    AppColorPair? surfaceQuran,
    AppInkColor? inkAccent,
    AppInkColor? inkSuccess,
    AppInkColor? inkWarning,
    AppInkColor? inkAlert,
    AppShadowColor? ombre,
  }) {
    return AppPalette(
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      borderHairline: borderHairline ?? this.borderHairline,
      borderResting: borderResting ?? this.borderResting,
      borderStrong: borderStrong ?? this.borderStrong,
      inkFaint: inkFaint ?? this.inkFaint,
      inkMuted: inkMuted ?? this.inkMuted,
      inkStrong: inkStrong ?? this.inkStrong,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSuccess: surfaceSuccess ?? this.surfaceSuccess,
      surfaceWarning: surfaceWarning ?? this.surfaceWarning,
      surfaceAlert: surfaceAlert ?? this.surfaceAlert,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      washAccent: washAccent ?? this.washAccent,
      washSuccess: washSuccess ?? this.washSuccess,
      washWarning: washWarning ?? this.washWarning,
      washAlert: washAlert ?? this.washAlert,
      washFamily: washFamily ?? this.washFamily,
      surfaceQuran: surfaceQuran ?? this.surfaceQuran,
      inkAccent: inkAccent ?? this.inkAccent,
      inkSuccess: inkSuccess ?? this.inkSuccess,
      inkWarning: inkWarning ?? this.inkWarning,
      inkAlert: inkAlert ?? this.inkAlert,
      ombre: ombre ?? this.ombre,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      surfaceRaised: AppColorPair.lerp(surfaceRaised, other.surfaceRaised, t),
      surfaceCanvas: AppColorPair.lerp(surfaceCanvas, other.surfaceCanvas, t),
      surfaceSunken: AppColorPair.lerp(surfaceSunken, other.surfaceSunken, t),
      borderHairline: AppInkColor.lerp(borderHairline, other.borderHairline, t),
      borderResting: AppInkColor.lerp(borderResting, other.borderResting, t),
      borderStrong: AppInkColor.lerp(borderStrong, other.borderStrong, t),
      inkFaint: AppInkColor.lerp(inkFaint, other.inkFaint, t),
      inkMuted: AppInkColor.lerp(inkMuted, other.inkMuted, t),
      inkStrong: AppInkColor.lerp(inkStrong, other.inkStrong, t),
      surfacePrimary: AppColorPair.lerp(
        surfacePrimary,
        other.surfacePrimary,
        t,
      ),
      surfaceSuccess: AppColorPair.lerp(
        surfaceSuccess,
        other.surfaceSuccess,
        t,
      ),
      surfaceWarning: AppColorPair.lerp(
        surfaceWarning,
        other.surfaceWarning,
        t,
      ),
      surfaceAlert: AppColorPair.lerp(surfaceAlert, other.surfaceAlert, t),
      surfaceInverse: AppColorPair.lerp(
        surfaceInverse,
        other.surfaceInverse,
        t,
      ),
      washAccent: AppColorPair.lerp(washAccent, other.washAccent, t),
      washSuccess: AppColorPair.lerp(washSuccess, other.washSuccess, t),
      washWarning: AppColorPair.lerp(washWarning, other.washWarning, t),
      washAlert: AppColorPair.lerp(washAlert, other.washAlert, t),
      washFamily: AppColorPair.lerp(washFamily, other.washFamily, t),
      surfaceQuran: AppColorPair.lerp(surfaceQuran, other.surfaceQuran, t),
      inkAccent: AppInkColor.lerp(inkAccent, other.inkAccent, t),
      inkSuccess: AppInkColor.lerp(inkSuccess, other.inkSuccess, t),
      inkWarning: AppInkColor.lerp(inkWarning, other.inkWarning, t),
      inkAlert: AppInkColor.lerp(inkAlert, other.inkAlert, t),
      ombre: AppShadowColor.lerp(ombre, other.ombre, t),
    );
  }
}
