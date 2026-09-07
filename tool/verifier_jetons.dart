// Verificateur des invariants de l'etape 2.
//
// Ces regles sont ecrites ici plutot que confiees a la relecture, parce qu'une
// relecture les laisse passer un jour ou l'autre
// (docs/architecture/etape-2-core-flutter.md section 7).
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
/// (`docs/produit/design-tokens.md` section 7).
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
/// (`docs/design/01-systeme-visuel.md` section 9).
const String _fichierPalette = 'core/theme/app_palette.dart';
const String _fichierRayons = 'core/theme/app_radius.dart';
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
final RegExp _dureeAnimation = RegExp(r'\bDuration\s*\(\s*milliseconds\s*:');
final RegExp _courbeNommee = RegExp(r'\bCurves\.[a-zA-Z]');
final RegExp _rayonLitteral = RegExp(
  r'\bBorderRadius\.circular\s*\(\s*(\d+(?:\.\d+)?)\s*\)',
);

/// Le vocabulaire d'avant la refonte.
///
/// Le renommage des jetons s'est fait en une passe au lot T. Sans cette regle,
/// les deux vocabulaires cohabiteraient, et le mauvais serait recopie
/// (`docs/produit/design-tokens.md` section 1.8).
const Map<String, String> vocabulairePerime = <String, String>{
  'surfaceBase': 'surfaceCanvas',
  'borderDefault': 'borderHairline, borderResting ou borderStrong',
  'textOnLightAccent': 'inkAccent',
  'textOnLightAlert': 'inkAlert',
  'VarelaRound': 'BricolageGrotesque',
  'NotoSans': 'InstrumentSans',
};

/// Les icones se declarent en un seul endroit : `AppIcons`. Les polices
/// Phosphor sont integrees en assets, il n'y a donc aucun paquet a importer,
/// mais un `IconData` construit ailleurs reintroduirait un second catalogue.
final RegExp _iconeHorsCatalogue = RegExp(
  r'\bIconData\s*\(|\bIcons\.[a-zA-Z]|package:phosphor_flutter',
);
final RegExp _onTapNu = RegExp(r'\bonTap\s*:');

/// Les boutons de Material.
///
/// Ajoutee au lot C, en meme temps que les quatre niveaux d'`ActionPrincipale`
/// (`docs/design/07-catalogue-composants.md` section 6). Un bouton Material
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
final RegExp _appelEspacement = RegExp(
  r'(?:EdgeInsets(?:Directional)?'
  r'\.(?:all|symmetric|only|fromLTRB|fromSTEB)|SizedBox)\(',
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

      // 1. Aucune couleur nue hors du fichier de palette.
      if (_couleurLitterale.hasMatch(code) &&
          !chemin.endsWith(_fichierPalette)) {
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
      if (_dureeAnimation.hasMatch(code) &&
          !chemin.endsWith(_fichierMouvement)) {
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

      // 2. Une seule librairie d'icones, un seul point d'entree.
      if (_iconeHorsCatalogue.hasMatch(code) &&
          !chemin.endsWith('core/icons/app_icons.dart')) {
        violations.add(
          Violation(chemin, numero, 'icone-hors-catalogue', ligne),
        );
      }

      // 3. Aucun onTap nu : tout passe par Pressable.
      if (_onTapNu.hasMatch(code) &&
          !chemin.endsWith('core/widgets/pressable.dart')) {
        violations.add(Violation(chemin, numero, 'ontap-nu', ligne));
      }

      // 3 bis. Aucun bouton Material : tout passe par ActionPrincipale et ses
      // quatre niveaux.
      if (_boutonMaterial.hasMatch(code)) {
        violations.add(Violation(chemin, numero, 'bouton-material', ligne));
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
    }

    // 5. Echelle d'espacement fixe. Balayage sur le fichier entier : un
    // constructeur ecrit sur plusieurs lignes doit etre vu comme les autres.
    violations.addAll(_espacementsHorsEchelle(chemin, contenu));

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
