// Verificateur des invariants de l'etape 2.
//
// Ces regles sont ecrites ici plutot que confiees a la relecture, parce qu'une
// relecture les laisse passer un jour ou l'autre
// (docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md section 7).
//
// Lancement : dart run tool/verifier_jetons.dart

import 'dart:io';

/// Un manquement constate.
class Violation {
  Violation(this.fichier, this.ligne, this.regle, this.extrait);

  final String fichier;
  final int ligne;
  final String regle;
  final String extrait;

  @override
  String toString() => '$fichier:$ligne  [$regle]  ${extrait.trim()}';
}

/// L'echelle d'espacement autorisee, miroir de `AppSpacing`.
///
/// Etendue vers le haut par la refonte : 40, 48 et 64 servent le rythme de
/// page, la ou les paliers courts servaient l'interieur des composants
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md` section 7).
const Set<String> echelleEspacement = <String>{
  '4',
  '8',
  '12',
  '16',
  '20',
  '24',
  '32',
  '40',
  '48',
  '64',
  '0',
};

/// Les fichiers qui detiennent chacun un jeton, et sont donc les seuls
/// autorises a en poser la valeur litterale.
///
/// Une regle de style qui n'est pas verifiee par un outil n'est pas une regle :
/// c'est un souhait, et l'etape suivante la contredit
/// (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 9).
const String _fichierPalette = 'core/theme/app_palette.dart';
const String _fichierRayons = 'core/theme/app_radius.dart';

/// Les deux seuls fichiers qui posent une couleur litterale.
///
/// `app_palette.dart` porte les jetons du produit. `logo_google.dart` porte les
/// quatre couleurs de la marque Google, qui n'en sont pas : un logo tiers se
/// pose tel quel, ne se decline pas et ne suit pas le theme. C'est une
/// exemption NOMINATIVE, pas une exemption de dossier : toute autre couleur
/// nue reste une violation, y compris dans `core/marque/`.
const List<String> _fichiersCouleur = <String>[
  _fichierPalette,
  'core/marque/logo_google.dart',
];
const String _fichierElevation = 'core/theme/app_elevation.dart';
const String _fichierTypographie = 'core/theme/app_typography.dart';
const String _fichierMouvement = 'core/theme/app_mouvement.dart';

/// Les deux seuls fichiers qui touchent a une [BoxShadow].
///
/// `app_color_pair.dart` porte le constructeur unique, `AppShadowColor`, et
/// `app_elevation.dart` compose les quatre niveaux avec. Le premier ne peut pas
/// etre fusionne dans le second : la palette importe les types de couleur, et
/// l'elevation importe la palette.
const List<String> _fichiersOmbre = <String>[
  _fichierElevation,
  'core/theme/app_color_pair.dart',
];

final RegExp _couleurLitterale = RegExp(r'Color\(0x|Colors\.[a-zA-Z]');
final RegExp _ombreLitterale = RegExp(r'\bBoxShadow\s*\(');
final RegExp _crenageLitteral = RegExp(r'\bletterSpacing\s*:');

/// `fontWeight:` en argument nomme. Les polices du produit sont variables :
/// une graisse posee sans l'axe `wght` ne change pas le dessin, Flutter
/// synthetise au mieux un faux gras (revue phase 0 du chantier Tuteur V1,
/// mesure a 40 px). Hors d'`app_typography.dart`, une graisse passe par
/// `AppTypography.graisse`, qui pose les deux.
final RegExp _graisseLitterale = RegExp(r'\bfontWeight\s*:');
final RegExp _dureeAnimation = RegExp(r'\bDuration\s*\(\s*milliseconds\s*:');
final RegExp _courbeNommee = RegExp(r'\bCurves\.[a-zA-Z]');
final RegExp _rayonLitteral = RegExp(
  r'\bBorderRadius\.circular\s*\(\s*(\d+(?:\.\d+)?)\s*\)',
);

/// Le vocabulaire d'avant la refonte.
///
/// Le renommage des jetons s'est fait en une passe au lot T. Sans cette regle,
/// les deux vocabulaires cohabiteraient, et le mauvais serait recopie
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md` section 1.8).
///
/// Les deux familles francaises de la refonte, Instrument Sans et Bricolage
/// Grotesque, sont retirees des assets depuis le 24/09/2026 (chantier Tuteur
/// V1, decisions du coordinateur section 3.4) : elles rejoignent la liste.
/// `\bNotoSans\b` n'attrape pas `NotoSansArabic` (pas de frontiere de mot).
const Map<String, String> vocabulairePerime = <String, String>{
  'surfaceBase': 'surfaceCanvas',
  'borderDefault': 'borderHairline, borderResting ou borderStrong',
  'textOnLightAccent': 'inkAccent',
  'textOnLightAlert': 'inkAlert',
  'VarelaRound': 'DMSans (titres) ou PlusJakartaSans (corps)',
  'NotoSans': 'PlusJakartaSans',
  'InstrumentSans': 'PlusJakartaSans (AppFontFamily.corps)',
  'BricolageGrotesque': 'DMSans (AppFontFamily.titre)',
};

/// Les familles de police autorisees : quatre de texte (deux arabes, deux
/// francaises) et les deux graisses d'icones Phosphor, pas une de plus.
///
/// Miroir de `AppFontFamily.texte` et du `pubspec.yaml` (decisions du
/// coordinateur du 24/09/2026, section 3.4). Toute famille declaree au
/// `pubspec.yaml` ou nommee dans le code hors de cette liste est une
/// violation, et chacune doit y etre declaree.
const Set<String> famillesAutorisees = <String>{
  'UthmanTahaNaskh',
  'NotoSansArabic',
  'PlusJakartaSans',
  'DMSans',
  'Phosphor',
  'PhosphorFill',
};

/// Les deux seuls fichiers qui nomment une famille de police : la
/// typographie (texte) et le catalogue d'icones (Phosphor). Partout ailleurs,
/// un texte prend un role du theme ou un style d'`AppTypography`, jamais un
/// `fontFamily` pose a la main : c'est ce qui garde la bascule d'une famille
/// a un seul fichier.
const List<String> _fichiersPolice = <String>[
  _fichierTypographie,
  'core/icons/app_icons.dart',
];

/// `fontFamily:` en argument nomme. `fontFamilyFallback:` n'est pas vise.
final RegExp _familleDePolice = RegExp(r'\bfontFamily\s*:');

/// Un nom de famille ecrit en toutes lettres : argument `fontFamily: '...'`,
/// ou constante `static const String x = '...'` des fichiers de police.
final RegExp _familleLitterale = RegExp(
  r'''\bfontFamily\s*:\s*['"]([^'"]+)['"]''',
);
final RegExp _constanteChaine = RegExp(
  r'''\bstatic\s+const\s+String\s+\w+\s*=\s*['"]([^'"]+)['"]''',
);

/// Une declaration de famille du `pubspec.yaml`.
final RegExp _familleDuPubspec = RegExp(r'^\s*-\s*family:\s*(\S+)\s*$');

/// Les icones se declarent en un seul endroit : `AppIcons`. Les polices
/// Phosphor sont integrees en assets, il n'y a donc aucun paquet a importer,
/// mais un `IconData` construit ailleurs reintroduirait un second catalogue.
final RegExp _iconeHorsCatalogue = RegExp(
  r'\bIconData\s*\(|\bIcons\.[a-zA-Z]|package:phosphor_flutter',
);
final RegExp _onTapNu = RegExp(r'\bonTap\s*:');

/// Exemption NOMINATIVE, jamais de dossier : `TabBar.onTap` est le callback
/// structure du composant Material lui-meme -- il ne construit aucune zone
/// pressable ad hoc, `TabBar` porte deja sa propre ondulation et son propre
/// retour visuel. Ce n'est pas le geste nu que la regle vise (un
/// `GestureDetector`/`InkWell.onTap` pose a la main autour d'un widget
/// quelconque). Entérinée le 21/09 par Agent Z (plan §10, défaut 1).
const String _fichierTabBarOnTap = 'core/widgets/sous_navigation_domaine.dart';

/// Les boutons de Material.
///
/// Ajoutee au lot C, en meme temps que les quatre niveaux d'`ActionPrincipale`
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 6). Un bouton Material
/// rapporterait la palette de Material avec lui, et son etat desactive
/// travaille par transparence, ce qui fait tomber le texte sous le seuil de
/// contraste. **Verifiee en la faisant echouer** sur un fichier piege.
final RegExp _boutonMaterial = RegExp(
  r'\b(?:Elevated|Text|Outlined|Filled|Icon)Button\b',
);

/// Le forcage d'etat d'interaction.
///
/// Il existe pour que la galerie puisse montrer les dix etats cote a cote, ce
/// qu'aucune souris ne saurait faire dans une capture. C'est une prise, donc un
/// risque : employee dans un ecran, elle peindrait un survol qui n'existe pas.
final RegExp _pressionForcee = RegExp(r'\bPressionForcee\b');
final RegExp _constructeurGoRouter = RegExp(r'\bGoRouter\s*\(');
final RegExp _mDash = RegExp('—');

/// Trois regles ajoutees au lot B0, adoption de la Bible Frontend V2
/// (ADR-019, `docs/archive/2026-09-pre-remise-a-plat/design/00-bible-frontend-v2.md`).

/// `EdgeInsets.fromLTRB` est directionnel par construction : ses quatre
/// arguments positionnels sont gauche/haut/droite/bas, jamais debut/fin. Toute
/// occurrence est une violation, il n'existe pas de forme correcte.
final RegExp _edgeInsetsFromLTRB = RegExp(r'\bEdgeInsets\.fromLTRB\s*\(');

/// `EdgeInsets.only` et `Positioned`, dont seuls les arguments `left`/`right`
/// posent probleme : `top`/`bottom` sont deja neutres a la direction. Les
/// arguments se relisent avec le meme decoupage a parentheses equilibrees que
/// [_espacementsHorsEchelle], parce qu'un appel etale sur plusieurs lignes
/// echapperait a une expression reguliere de ligne.
final RegExp _edgeInsetsOnly = RegExp(r'\bEdgeInsets\.only\s*\(');
final RegExp _positionedConstructeur = RegExp(r'\bPositioned\s*\(');
final RegExp _argumentLeftOuRight = RegExp(r'^\s*(?:left|right)\s*:');

/// Les quatre constantes d'`Alignment` qui codent un cote en dur. Les huit
/// autres (`center`, `topCenter`, `bottomCenter`, et les quatre variantes
/// `*Start`/`*End` d'`AlignmentDirectional`) restent permises : elles sont
/// deja neutres ou deja directionnelles.
final RegExp _alignementNonDirectionnel = RegExp(
  r'\bAlignment\.(?:centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b',
);

/// Le seul dossier ou un rayon, une couleur ou une ombre peut legitimement
/// avoir besoin d'un point de reference non directionnel pour construire un
/// type Flutter bas niveau. Aucune occurrence connue aujourd'hui : la
/// derogation est ecrite, pas silencieuse (Bible V2 section 0.3).
const String _dossierTheme = 'core/theme/';

/// Un ecran de `Scaffold` nu, sans passer par la coquille du produit
/// (`PageShell` ou `PageParcours`). C'est exactement le defaut mesure sur le
/// tunnel d'entree le 11 septembre 2026 : `connexion_page.dart` montait un
/// `Scaffold` nu, sans carte, sans ombre, sans marque -- et c'est le seul
/// ecran visible sans compte, donc tout ce que l'operateur a vu.
final RegExp _scaffoldConstructeur = RegExp(r'\bScaffold\s*\(');

/// Les ecrans de `lib/features/` encore a l'etat brut au moment du lot B0.
///
/// Exemption TEMPORAIRE et NOMINATIVE, jamais une exemption de dossier entier :
/// chaque ligne se retire au lot qui reprend reellement l'ecran vise, jamais
/// avant. Une entree retiree sans que l'ecran soit repris romprait la garantie
/// que cette regle existe pour tenir (Bible V2 section 0.3, derogation ecrite).
const Set<String> _ecransEnAttenteDeCoquille = <String>{
  // Lot R0 fait le 11 septembre 2026 : les cinq ecrans du tunnel d'entree
  // passent par PageShell, retires de cette liste.
  // Lot R4 fait le 11 septembre 2026 : le reste de l'existant passe par
  // PageShell, retire de cette liste. Le lot R est desormais complet.
};

/// Un tag de conformite (Bible V2 section 45) : une ligne de commentaire qui ne
/// contient QUE `[TAG]`, comme dans l'exemple de la Bible. L'ancrage sur la
/// ligne entiere evite qu'une classe de caracteres de `RegExp` telle que
/// `'[A-Z2-9]'` posee dans du code ne soit prise pour un tag : elle ne suit
/// jamais `//` en debut de ligne.
final RegExp _tagConformite = RegExp(
  r'^\s*//\s*\[([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)\]\s*$',
);

/// Le vocabulaire ferme des tags, miroir de `lib/CLAUDE.md`.
const Set<String> _tagsConformiteConnus = <String>{
  'M3-COLOR',
  'A11Y',
  'RESPONSIVE',
  'QURAN-STAGE',
};
final RegExp _emoji = RegExp(
  '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
  unicode: true,
);

/// Les constructeurs dont les arguments sont des espacements.
///
/// `BorderRadius.circular` n'y figure plus : les rayons ont leur propre echelle
/// depuis la refonte, et 999 n'appartient pas a celle des espacements. Ils sont
/// controles par [_rayonLitteral].
///
/// `EdgeInsetsDirectional` a ete ajoute au lot C, et c'etait un trou : la regle
/// RTL de `05-regles-responsive.md` section 7 impose les variantes
/// directionnelles dans les ecrans, or elles echappaient au controle
/// d'espacement. Chaque marge reprise au lot R serait donc sortie de l'echelle
/// sans que rien ne le dise.
///
/// Le `SizedBox` est pris seul : `FractionallySizedBox` porte une fraction
/// (`widthFactor: 0.86`), pas un ecart, et tombait a tort dans ce controle.
final RegExp _appelEspacement = RegExp(
  r'(?:EdgeInsets(?:Directional)?'
  r'\.(?:all|symmetric|only|fromLTRB|fromSTEB)|(?<![A-Za-z0-9_])SizedBox)\(',
);

/// Un argument dont la valeur est **entierement** un nombre litteral.
///
/// Volontairement strict : `cote / 2` ou `cibleTactile * 1.4` sont des calculs
/// derives d'un jeton, pas des valeurs ponctuelles. Seul un nombre pose tel
/// quel echappe a l'echelle.
final RegExp _valeurNumeriquePure = RegExp(r'^(\d+(?:\.\d+)?)$');
final RegExp _parametresPermanentNotice = RegExp(
  r'const\s+PermanentNotice\s*\(\s*([^)]*)\)',
);

/// Le constructeur `Container`, pour la regle « une surface d'ecran ne se pose
/// pas a la main ».
final RegExp _containerConstructeur = RegExp(r'\bContainer\s*\(');

/// Un argument nomme `decoration`, en tete d'un morceau de liste d'arguments.
final RegExp _argumentDecoration = RegExp(r'^\s*decoration\s*:');

/// `showDialog`, avec ou sans argument de type.
final RegExp _showDialog = RegExp(r'\bshowDialog\s*(?:<[^>]*>)?\s*\(');

/// Les deux seuls fichiers autorises a ouvrir une boite de dialogue : le point
/// d'entree unique des surfaces modales, `AppBottomSheet.ouvrir`, qui ouvre
/// une boite de dialogue centree sur bureau au lieu d'une feuille de telephone
/// etiree (contrat K5 du chantier Tuteur V1, phase 0c1 du 24/09/2026), et le
/// composant de confirmation destructive, qui passe par lui. Exemption
/// NOMINATIVE : un ecran n'ouvre jamais de dialogue lui-meme.
const Set<String> _fichiersDialogue = <String>{
  'core/widgets/app_bottom_sheet.dart',
  'core/widgets/confirm_destructive.dart',
};

void main() {
  final Directory racine = Directory.current;
  final List<Violation> violations = <Violation>[];

  final List<File> sources = Directory('${racine.path}/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'))
      .toList();

  int routeursTrouves = 0;

  for (final File fichier in sources) {
    final String chemin = _relatif(fichier.path, racine.path);
    final List<String> lignes = fichier.readAsLinesSync();
    final String contenu = lignes.join('\n');

    if (_constructeurGoRouter.hasMatch(_sansCommentaires(contenu))) {
      routeursTrouves++;
      if (!chemin.endsWith('core/router/app_router.dart')) {
        violations.add(
          Violation(chemin, 1, 'routeur-unique', 'construit un GoRouter'),
        );
      }
    }

    for (int i = 0; i < lignes.length; i++) {
      final String ligne = lignes[i];
      final int numero = i + 1;
      final String code = _sansCommentaireDeLigne(ligne);

      // 1. Aucune couleur nue hors des fichiers qui detiennent des couleurs.
      if (_couleurLitterale.hasMatch(code) &&
          !_fichiersCouleur.any(chemin.endsWith)) {
        violations.add(Violation(chemin, numero, 'couleur-nue', ligne));
      }

      // 1 bis. Aucune ombre composee hors du fichier d'elevation, aucun crenage
      // pose hors du fichier de typographie, aucune duree d'animation ni
      // courbe nommee hors du fichier de mouvement. Les durees METIER, elles,
      // restent libres : une pause de priere en minutes n'est pas du mouvement.
      if (_ombreLitterale.hasMatch(code) &&
          !_fichiersOmbre.any(chemin.endsWith)) {
        violations.add(Violation(chemin, numero, 'ombre-hors-echelle', ligne));
      }
      if (_crenageLitteral.hasMatch(code) &&
          !chemin.endsWith(_fichierTypographie)) {
        violations.add(Violation(chemin, numero, 'crenage-litteral', ligne));
      }
      if (_graisseLitterale.hasMatch(code) &&
          !chemin.endsWith(_fichierTypographie)) {
        violations.add(
          Violation(chemin, numero, 'graisse-hors-typographie', ligne),
        );
      }
      if (_dureeAnimation.hasMatch(code) &&
          !chemin.endsWith(_fichierMouvement) &&
          !chemin.endsWith('core/theme/app_delais.dart')) {
        violations.add(Violation(chemin, numero, 'duree-litterale', ligne));
      }
      if (_courbeNommee.hasMatch(code) && !chemin.endsWith(_fichierMouvement)) {
        violations.add(Violation(chemin, numero, 'courbe-litterale', ligne));
      }

      // 1 ter. Aucun rayon pose tel quel : l'echelle a cinq crans et 999 n'est
      // pas un espacement. Une valeur derivee d'un jeton reste permise.
      final RegExpMatch? rayon = _rayonLitteral.firstMatch(code);
      if (rayon != null && !chemin.endsWith(_fichierRayons)) {
        violations.add(Violation(chemin, numero, 'rayon-litteral', ligne));
      }

      // 1 quater. Le vocabulaire d'avant la refonte ne revient pas.
      for (final MapEntry<String, String> perime in vocabulairePerime.entries) {
        if (RegExp('\\b${perime.key}\\b').hasMatch(code)) {
          violations.add(
            Violation(
              chemin,
              numero,
              'vocabulaire-perime',
              '${perime.key} : employer ${perime.value}',
            ),
          );
        }
      }

      // 1 quinquies. Aucune famille de police posee hors de la typographie et
      // du catalogue d'icones, et aucune famille hors de la liste fermee.
      if (_familleDePolice.hasMatch(code) &&
          !_fichiersPolice.any(chemin.endsWith)) {
        violations.add(
          Violation(chemin, numero, 'police-hors-typographie', ligne),
        );
      }
      final List<String> famillesNommees = <String>[
        for (final RegExpMatch m in _familleLitterale.allMatches(code))
          m.group(1)!,
        if (_fichiersPolice.any(chemin.endsWith))
          for (final RegExpMatch m in _constanteChaine.allMatches(code))
            m.group(1)!,
      ];
      for (final String famille in famillesNommees) {
        if (!famillesAutorisees.contains(famille)) {
          violations.add(
            Violation(
              chemin,
              numero,
              'famille-non-autorisee',
              '$famille : familles autorisees ${famillesAutorisees.join(', ')}',
            ),
          );
        }
      }

      // 2. Une seule librairie d'icones, un seul point d'entree.
      if (_iconeHorsCatalogue.hasMatch(code) &&
          !chemin.endsWith('core/icons/app_icons.dart')) {
        violations.add(
          Violation(chemin, numero, 'icone-hors-catalogue', ligne),
        );
      }

      // 3. Aucun onTap nu : tout passe par Pressable.
      if (_onTapNu.hasMatch(code) &&
          !chemin.endsWith('core/widgets/pressable.dart') &&
          !chemin.endsWith(_fichierTabBarOnTap)) {
        violations.add(Violation(chemin, numero, 'ontap-nu', ligne));
      }

      // 3 bis. Aucun bouton Material : tout passe par ActionPrincipale et ses
      // quatre niveaux.
      if (_boutonMaterial.hasMatch(code)) {
        violations.add(Violation(chemin, numero, 'bouton-material', ligne));
      }

      // 3 bis (suite). Aucun showDialog hors du point d'entree des surfaces
      // modales : une confirmation destructive passe par ConfirmDestructive,
      // une surface modale par AppBottomSheet.ouvrir, jamais par une
      // AlertDialog posee dans un ecran
      // (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 6). Ajoutee au lot
      // R ; AppBottomSheet admis le 24/09/2026 pour sa forme de bureau.
      if (_showDialog.hasMatch(code) &&
          !_fichiersDialogue.any(chemin.endsWith)) {
        violations.add(
          Violation(chemin, numero, 'showdialog-hors-confirmation', ligne),
        );
      }

      // 3 ter. Le forcage d'etat ne sort pas de la galerie.
      if (_pressionForcee.hasMatch(code) &&
          !chemin.endsWith('core/widgets/pressable.dart') &&
          !chemin.contains('features/_dev/')) {
        violations.add(
          Violation(chemin, numero, 'pression-forcee-hors-galerie', ligne),
        );
      }

      // 4. Zero emoji, zero M-dash, code comme libelles.
      if (_emoji.hasMatch(ligne)) {
        violations.add(Violation(chemin, numero, 'emoji', ligne));
      }
      if (_mDash.hasMatch(ligne)) {
        violations.add(Violation(chemin, numero, 'm-dash', ligne));
      }

      // 4 bis. Direction geree, jamais un cote code en dur (lot B0, Bible V2
      // section 14). `EdgeInsets.only`/`Positioned` se relisent a part : seuls
      // leurs arguments `left`/`right` posent probleme, voir
      // _violationsPositionDirectionnelle.
      if (_edgeInsetsFromLTRB.hasMatch(code) &&
          !chemin.contains(_dossierTheme)) {
        violations.add(Violation(chemin, numero, 'direction-non-geree', ligne));
      }
      if (_alignementNonDirectionnel.hasMatch(code) &&
          !chemin.contains(_dossierTheme)) {
        violations.add(Violation(chemin, numero, 'direction-non-geree', ligne));
      }

      // 4 ter. Un ecran de lib/features/ passe par une coquille (PageShell,
      // PageParcours), jamais par un Scaffold nu (lot B0, Bible V2 sections 6
      // et 52) -- c'est le defaut mesure sur le tunnel d'entree le 11 septembre
      // 2026. La galerie de developpement n'est pas un ecran du catalogue.
      if (_scaffoldConstructeur.hasMatch(code) &&
          chemin.startsWith('lib/features/') &&
          !chemin.contains('features/_dev/') &&
          !_ecransEnAttenteDeCoquille.any(chemin.endsWith)) {
        violations.add(Violation(chemin, numero, 'page-sans-coquille', ligne));
      }

      // 4 quater. Vocabulaire ferme des tags de conformite (lot B0, Bible V2
      // section 45). Verifie sur la ligne BRUTE, pas sur `code` : le tag est un
      // commentaire, `_sansCommentaireDeLigne` l'aurait deja retire.
      final RegExpMatch? tag = _tagConformite.firstMatch(ligne);
      if (tag != null && !_tagsConformiteConnus.contains(tag.group(1))) {
        violations.add(Violation(chemin, numero, 'tag-conformite', ligne));
      }
    }

    // 5. Echelle d'espacement fixe. Balayage sur le fichier entier : un
    // constructeur ecrit sur plusieurs lignes doit etre vu comme les autres.
    violations.addAll(_espacementsHorsEchelle(chemin, contenu));

    // 5 ter. `EdgeInsets.only(left:/right:)` et `Positioned(left:/right:)`,
    // balayes sur le fichier entier pour la meme raison : ces deux
    // constructeurs s'etalent le plus souvent sur plusieurs lignes (lot B0).
    if (!chemin.contains(_dossierTheme)) {
      violations.addAll(_violationsPositionDirectionnelle(chemin, contenu));
    }

    // 5 bis. Aucun `Container` porteur d'une `decoration` sous `lib/features/` :
    // les surfaces d'un ecran viennent d'`AppCard` et de `PageShell`
    // (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 6). La regle nomme
    // `Container`, pas `DecoratedBox` : le seul `DecoratedBox` de `features/`
    // est celui de `GrilleSemaine`, composant partage que l'arborescence a
    // laisse la. Ajoutee au lot R avec la reprise de `TUT-01`, premiere a
    // retirer son `Container` decore, la pastille verte passee a `StatusPill`.
    if (chemin.startsWith('lib/features/')) {
      violations.addAll(_containersDecoresDeFeatures(chemin, contenu));
    }

    // 6. PermanentNotice n'accepte aucun parametre.
    if (chemin.endsWith('core/widgets/permanent_notice.dart')) {
      final RegExpMatch? m = _parametresPermanentNotice.firstMatch(contenu);
      if (m == null) {
        violations.add(
          Violation(
            chemin,
            1,
            'notice-constructeur',
            'constructeur const PermanentNotice() introuvable',
          ),
        );
      } else if (m.group(1)!.trim().isNotEmpty) {
        violations.add(
          Violation(
            chemin,
            1,
            'notice-parametre',
            'le constructeur a gagne un parametre : ${m.group(1)}',
          ),
        );
      }
    }
  }

  // 7. Aucun fichier de routes duplique par mode d'interface.
  for (final File f in sources) {
    final String nom = f.uri.pathSegments.last;
    if (RegExp(r'rout(e|es|eur).*(enfant|standard|child)').hasMatch(nom)) {
      violations.add(
        Violation(
          _relatif(f.path, racine.path),
          1,
          'arborescence-dupliquee',
          'un fichier de routes par mode existe',
        ),
      );
    }
  }

  // 7 bis. Le `pubspec.yaml` ne declare que les familles autorisees, et
  // toutes. Une police ajoutee sans passer par cette liste serait une
  // cinquieme famille de texte, ce que la charte refuse.
  final File pubspec = File('${racine.path}/pubspec.yaml');
  if (pubspec.existsSync()) {
    final List<String> lignes = pubspec.readAsLinesSync();
    final Set<String> declarees = <String>{};
    for (int i = 0; i < lignes.length; i++) {
      final RegExpMatch? m = _familleDuPubspec.firstMatch(lignes[i]);
      if (m == null) {
        continue;
      }
      declarees.add(m.group(1)!);
      if (!famillesAutorisees.contains(m.group(1))) {
        violations.add(
          Violation('pubspec.yaml', i + 1, 'famille-non-autorisee', lignes[i]),
        );
      }
    }
    for (final String attendue in famillesAutorisees.difference(declarees)) {
      violations.add(
        Violation(
          'pubspec.yaml',
          1,
          'famille-absente',
          '$attendue autorisee mais non declaree',
        ),
      );
    }
  }

  if (routeursTrouves == 0) {
    violations.add(
      Violation(
        'lib/core/router/app_router.dart',
        1,
        'routeur-absent',
        'aucun GoRouter construit',
      ),
    );
  }

  // 8. Les libelles ne portent ni emoji ni M-dash non plus.
  final Directory i18n = Directory('${racine.path}/assets/i18n');
  if (i18n.existsSync()) {
    for (final File f in i18n.listSync().whereType<File>()) {
      final List<String> lignes = f.readAsLinesSync();
      for (int i = 0; i < lignes.length; i++) {
        if (_emoji.hasMatch(lignes[i])) {
          violations.add(
            Violation(_relatif(f.path, racine.path), i + 1, 'emoji', lignes[i]),
          );
        }
        if (_mDash.hasMatch(lignes[i])) {
          violations.add(
            Violation(
              _relatif(f.path, racine.path),
              i + 1,
              'm-dash',
              lignes[i],
            ),
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'Jetons verifies : ${sources.length} fichiers, aucune violation.',
    );
    return;
  }

  stdout.writeln('${violations.length} violation(s) :');
  for (final Violation v in violations) {
    stdout.writeln('  $v');
  }
  exitCode = 1;
}

/// Releve les valeurs d'espacement posees telles quelles, hors de l'echelle.
///
/// Le balayage compte les parentheses plutot que de faire confiance a une
/// expression reguliere : un `SizedBox` qui contient un autre widget s'etale
/// sur plusieurs lignes et imbrique ses parentheses.
List<Violation> _espacementsHorsEchelle(String chemin, String contenu) {
  final String code = _sansCommentaires(contenu);
  final List<Violation> trouvees = <Violation>[];

  for (final RegExpMatch appel in _appelEspacement.allMatches(code)) {
    final int ouverture = appel.end - 1;
    int profondeur = 0;
    int fin = ouverture;
    for (int i = ouverture; i < code.length; i++) {
      if (code[i] == '(') {
        profondeur++;
      } else if (code[i] == ')') {
        profondeur--;
        if (profondeur == 0) {
          fin = i;
          break;
        }
      }
    }
    if (fin == ouverture) {
      continue;
    }

    // On ne garde que les arguments du premier niveau : ceux d'un widget
    // imbrique sont controles a leur propre tour par la boucle englobante.
    final String arguments = code.substring(ouverture + 1, fin);
    for (final String argument in _decouperNiveauUn(arguments)) {
      final int sep = argument.indexOf(':');
      final String valeur = (sep == -1 ? argument : argument.substring(sep + 1))
          .trim();
      final RegExpMatch? nombre = _valeurNumeriquePure.firstMatch(valeur);
      if (nombre != null && !echelleEspacement.contains(nombre.group(1))) {
        final int ligne =
            '\n'.allMatches(code.substring(0, appel.start)).length + 1;
        trouvees.add(
          Violation(
            chemin,
            ligne,
            'espacement-hors-echelle',
            '${appel.group(0)}...$valeur',
          ),
        );
      }
    }
  }
  return trouvees;
}

/// Releve les `EdgeInsets.only` et `Positioned` dont un argument `left` ou
/// `right` code un cote en dur, au lieu de `start`/`end`.
///
/// Meme balayage a parentheses equilibrees que [_espacementsHorsEchelle] : ces
/// deux constructeurs s'etalent le plus souvent sur plusieurs lignes, une
/// expression reguliere de ligne les manquerait.
/// **Verifiee en la faisant echouer** sur un fichier piege.
List<Violation> _violationsPositionDirectionnelle(
  String chemin,
  String contenu,
) {
  final String code = _sansCommentaires(contenu);
  final List<Violation> trouvees = <Violation>[];

  for (final RegExp constructeur in <RegExp>[
    _edgeInsetsOnly,
    _positionedConstructeur,
  ]) {
    for (final RegExpMatch appel in constructeur.allMatches(code)) {
      final int ouverture = appel.end - 1;
      int profondeur = 0;
      int fin = ouverture;
      for (int i = ouverture; i < code.length; i++) {
        if (code[i] == '(') {
          profondeur++;
        } else if (code[i] == ')') {
          profondeur--;
          if (profondeur == 0) {
            fin = i;
            break;
          }
        }
      }
      if (fin == ouverture) {
        continue;
      }

      final String arguments = code.substring(ouverture + 1, fin);
      final bool porteLeftOuRight = _decouperNiveauUn(arguments)
          .any(_argumentLeftOuRight.hasMatch);
      if (!porteLeftOuRight) {
        continue;
      }

      final int ligne =
          '\n'.allMatches(code.substring(0, appel.start)).length + 1;
      trouvees.add(
        Violation(
          chemin,
          ligne,
          'direction-non-geree',
          '${appel.group(0)}... left/right au lieu de start/end',
        ),
      );
    }
  }
  return trouvees;
}

/// Releve les `Container` porteurs d'une `decoration` sous `lib/features/`.
///
/// Meme balayage a parentheses equilibrees que [_espacementsHorsEchelle] : la
/// `decoration` est le plus souvent posee sur une autre ligne que le
/// `Container(`, et une expression reguliere de ligne la manquerait.
/// **Verifiee en la faisant echouer** sur un fichier piege.
List<Violation> _containersDecoresDeFeatures(String chemin, String contenu) {
  final String code = _sansCommentaires(contenu);
  final List<Violation> trouvees = <Violation>[];

  for (final RegExpMatch appel in _containerConstructeur.allMatches(code)) {
    final int ouverture = appel.end - 1;
    int profondeur = 0;
    int fin = ouverture;
    for (int i = ouverture; i < code.length; i++) {
      if (code[i] == '(') {
        profondeur++;
      } else if (code[i] == ')') {
        profondeur--;
        if (profondeur == 0) {
          fin = i;
          break;
        }
      }
    }
    if (fin == ouverture) {
      continue;
    }

    final String arguments = code.substring(ouverture + 1, fin);
    final bool porteDecoration = _decouperNiveauUn(arguments)
        .any(_argumentDecoration.hasMatch);
    if (!porteDecoration) {
      continue;
    }

    final int ligne =
        '\n'.allMatches(code.substring(0, appel.start)).length + 1;
    trouvees.add(
      Violation(chemin, ligne, 'container-decore-dans-features', 'Container('),
    );
  }
  return trouvees;
}

/// Decoupe une liste d'arguments sur les virgules de premier niveau.
List<String> _decouperNiveauUn(String arguments) {
  final List<String> morceaux = <String>[];
  final StringBuffer courant = StringBuffer();
  int profondeur = 0;

  for (int i = 0; i < arguments.length; i++) {
    final String c = arguments[i];
    if (c == '(' || c == '[' || c == '{' || c == '<') {
      profondeur++;
    } else if (c == ')' || c == ']' || c == '}' || c == '>') {
      profondeur--;
    }
    if (c == ',' && profondeur == 0) {
      morceaux.add(courant.toString());
      courant.clear();
    } else {
      courant.write(c);
    }
  }
  morceaux.add(courant.toString());
  return morceaux;
}

String _relatif(String chemin, String racine) =>
    chemin.replaceFirst(racine, '').replaceAll(r'\', '/').replaceFirst('/', '');

/// Retire les commentaires de ligne, pour qu'un exemple cite en documentation
/// ne compte pas comme une violation.
String _sansCommentaireDeLigne(String ligne) {
  final int i = ligne.indexOf('//');
  return i == -1 ? ligne : ligne.substring(0, i);
}

String _sansCommentaires(String contenu) =>
    contenu.split('\n').map(_sansCommentaireDeLigne).join('\n');
