import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// Le pays d'un enseignant, tel que tout le monde le lit sur sa carte
/// (ENS-PAYS-1, demande du directeur du 04/10/2026 : « Je veux que le pays de
/// chaque enseignant apparaisse sur sa carte publiquement [...] Si ca peut
/// etre avec le drapeau tant mieux »).
///
/// **Le seul point d'entree de cette fonction** : tuteur, eleve, Mode
/// Accessibilite, controleur et administration lisent le meme composant, a la
/// meme place (sous le nom de l'enseignant), dans le meme registre discret
/// (`bodySmall`, encre attenuee, aucune couleur ni police nouvelle).
///
/// - Pays non declare (nul, vide) : **rien n'est rendu**, pas de « inconnu ».
/// - Le nom du pays est **toujours** ecrit, en entier, sans coupure de mot
///   ([TexteSansCoupure]).
/// - Le drapeau le precede **seulement quand l'appareil sait le dessiner**
///   ([drapeauDessinable]) : un drapeau se compose de deux « lettres
///   regionales » que la police d'emoji fusionne. Chrome et Edge sous
///   Windows, sans police qui les fusionne, montrent deux lettres (« GN ») :
///   le composant le mesure et, dans ce cas, n'affiche que le nom. Jamais
///   deux lettres orphelines a l'ecran.
/// - Le drapeau est decoratif pour le lecteur d'ecran : la phrase lue est
///   « Pays : Guinee ».
class PaysEnseignant extends StatelessWidget {
  /// Cree la ligne du pays.
  const PaysEnseignant({
    required this.pays,
    super.key,
    this.style,
    this.centre = false,
  });

  /// Le pays declare par l'enseignant (`teacher_profiles.country`, nom en
  /// clair depuis FORM-L8), ou nul.
  final String? pays;

  /// Le style du nom ; par defaut `bodySmall` en encre attenuee.
  final TextStyle? style;

  /// Vrai sous un avatar en disposition verticale : la ligne se centre sur
  /// le meme axe que le nom.
  final bool centre;

  /// Cle de la ligne, pour les tests.
  static const Key ligneKey = ValueKey<String>('pays-enseignant');

  /// Cle du drapeau, present seulement quand il est dessinable.
  static const Key drapeauKey = ValueKey<String>('pays-enseignant-drapeau');

  /// Le nom a afficher, ou nul si rien n'est declare.
  static String? nomAffichable(String? pays) {
    final String? nom = pays?.trim();
    return (nom == null || nom.isEmpty) ? null : nom;
  }

  /// La ligne du pays, ou nul quand rien n'est declare : pour un emplacement
  /// facultatif (`LigneCleValeur.complement`).
  static Widget? siDeclare(String? pays, {TextStyle? style}) =>
      nomAffichable(pays) == null
      ? null
      : PaysEnseignant(pays: pays, style: style);

  @override
  Widget build(BuildContext context) {
    final String? nom = nomAffichable(pays);
    if (nom == null) return const SizedBox.shrink();
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleNom =
        style ??
        AppPalette.of(context).inkMuted
            .applyTo(textes.bodySmall ?? const TextStyle());
    final String? code = codeIsoDuPays(nom);
    return Semantics(
      key: ligneKey,
      label: t.enseignant.pays.semantique(pays: nom),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: centre
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            if (code != null) _Drapeau(code: code, style: styleNom),
            Flexible(
              child: TexteSansCoupure(
                nom,
                style: styleNom,
                textAlign: centre ? TextAlign.center : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les 19 pays proposes par FORM-L8 (`paysProposes`, noms en francais tels
/// qu'enregistres par `maj_profil_enseignant`) et leur code ISO 3166-1
/// alpha-2. Un test verifie que chaque pays de la liste de FORM-L8 y figure.
const Map<String, String> codesIsoDesPays = <String, String>{
  'France': 'FR',
  'Belgique': 'BE',
  'Espagne': 'ES',
  'Royaume-Uni': 'GB',
  'Irlande': 'IE',
  'Guinée': 'GN',
  'Sénégal': 'SN',
  'Mali': 'ML',
  'Mauritanie': 'MR',
  'Maroc': 'MA',
  "Côte d'Ivoire": 'CI',
  'Burkina Faso': 'BF',
  'Togo': 'TG',
  'Nigéria': 'NG',
  'Niger': 'NE',
  'Tchad': 'TD',
  'Cameroun': 'CM',
  'Canada': 'CA',
  'États-Unis': 'US',
};

/// Une forme de comparaison : minuscules, sans accent, apostrophe droite,
/// espaces et tirets ramenes a un seul espace. « cote d’ivoire »,
/// « Guinee » et « etats unis » retrouvent ainsi leur pays quand
/// l'enseignant l'a ecrit dans « Autre ».
String _forme(String nom) {
  const Map<String, String> sansAccent = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    '’': "'",
  };
  final StringBuffer sortie = StringBuffer();
  for (final String c in nom.trim().toLowerCase().split('')) {
    sortie.write(sansAccent[c] ?? c);
  }
  return sortie.toString().replaceAll(RegExp(r'[\s-]+'), ' ');
}

final Map<String, String> _codesParForme = <String, String>{
  for (final MapEntry<String, String> e in codesIsoDesPays.entries)
    _forme(e.key): e.value,
};

/// Le code ISO 3166-1 alpha-2 du pays [nom], ou nul si le pays n'est pas
/// l'un des 19 de FORM-L8 (un pays ecrit dans « Autre » garde alors son nom,
/// sans drapeau).
String? codeIsoDuPays(String? nom) {
  if (nom == null || nom.trim().isEmpty) return null;
  return _codesParForme[_forme(nom)];
}

/// Le drapeau du code [code] : ses deux lettres regionales Unicode
/// (U+1F1E6 a U+1F1FF), construites ici plutot qu'ecrites dans le source.
String drapeauDuCode(String code) => String.fromCharCodes(<int>[
  for (final int c in code.toUpperCase().codeUnits) 0x1F1E6 + c - 0x41,
]);

/// La police d'emoji que Flutter Web charge pour les glyphes absents des
/// polices de l'application, et celle d'Android : nommee en repli du seul
/// drapeau, sans rien embarquer ni changer aux polices du produit.
const String _repliDrapeau = 'Noto Color Emoji';

/// Le style du drapeau : celui du nom, avec la police d'emoji en repli.
TextStyle _styleDrapeau(TextStyle style) => style.copyWith(
  fontFamilyFallback: <String>[...?style.fontFamilyFallback, _repliDrapeau],
);

final Map<String, bool> _dessinables = <String, bool>{};

/// Vrai quand l'appareil dessine le drapeau [code] en un seul glyphe.
///
/// **Mesure, pas supposition.** Les deux lettres regionales se fusionnent en
/// un drapeau quand la police sait le faire : la paire prend alors la largeur
/// d'un seul glyphe. Sinon (Chrome ou Edge sous Windows, police d'emoji pas
/// encore chargee, police de test) la paire est deux fois plus large qu'une
/// lettre seule : le drapeau n'est pas dessinable, seul le nom s'affiche.
/// Le resultat est garde par code et par style ; il est oublie quand les
/// polices du systeme changent (Flutter Web finit de charger sa police
/// d'emoji), et les drapeaux se redessinent alors.
bool drapeauDessinable(String code, TextStyle style) {
  final TextStyle s = _styleDrapeau(style);
  final String cle =
      '$code|${s.fontFamily}|${s.fontSize}|${s.fontFamilyFallback?.join(',')}';
  return _dessinables.putIfAbsent(cle, () {
    double largeur(String texte) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: texte, style: s),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final double w = peintre.width;
      peintre.dispose();
      return w;
    }

    final String paire = drapeauDuCode(code);
    final double seule = largeur(String.fromCharCode(paire.runes.first));
    final double ensemble = largeur(paire);
    return seule > 0 && ensemble < seule * 1.5;
  });
}

/// Oublie les mesures (tests, et changement des polices du systeme).
@visibleForTesting
void oublierDrapeauxMesures() => _dessinables.clear();

class _Drapeau extends StatefulWidget {
  const _Drapeau({required this.code, required this.style});

  final String code;
  final TextStyle style;

  @override
  State<_Drapeau> createState() => _DrapeauEtat();
}

class _DrapeauEtat extends State<_Drapeau> {
  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_policesChangees);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_policesChangees);
    super.dispose();
  }

  void _policesChangees() {
    _dessinables.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!drapeauDessinable(widget.code, widget.style)) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: PaysEnseignant.drapeauKey,
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
      child: Text(
        drapeauDuCode(widget.code),
        style: _styleDrapeau(widget.style),
      ),
    );
  }
}
