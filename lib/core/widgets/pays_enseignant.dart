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
/// - Le drapeau le precede, **image embarquee** (ENS-DRAPEAU-1, decision Q-5
///   du directeur du 05/10/2026) : un seul rendu sur toutes les plateformes,
///   Windows et web compris, sans dependre d'une police d'emoji. Images :
///   `assets/flags/<code>.png`, flag-icons 7.5.0 (MIT, voir
///   `assets/flags/LICENCE.txt`), pour les 19 pays de FORM-L8 seulement. Un
///   pays sans image (ecrit dans « Autre ») garde son nom seul : jamais de
///   lettres orphelines.
/// - Le drapeau a la hauteur du corps du texte (taille de police agrandie
///   par l'echelle de l'appareil), au format 4:3.
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

  /// Cle du drapeau, present seulement quand le pays a son image.
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

/// Le chemin de l'image du drapeau du code [code] (ISO 3166-1 alpha-2).
String cheminDrapeau(String code) => 'assets/flags/${code.toLowerCase()}.png';

/// Le rapport largeur / hauteur des images (flag-icons, dossier `4x3`).
const double rapportDrapeau = 4 / 3;

class _Drapeau extends StatelessWidget {
  const _Drapeau({required this.code, required this.style});

  final String code;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final double corps = MediaQuery.textScalerOf(context)
        .scale(style.fontSize ?? DefaultTextStyle.of(context).style.fontSize!);
    return Padding(
      key: PaysEnseignant.drapeauKey,
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
      child: Image.asset(
        cheminDrapeau(code),
        width: corps * rapportDrapeau,
        height: corps,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        // Image absente du paquet (ne doit pas arriver : un test verifie les
        // 19) : rien a la place, le nom reste seul.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
