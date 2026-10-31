import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/pays_iso.dart';
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
///   `assets/flags/LICENCE.txt`) : les 19 pays de FORM-L8, reconnus par leur
///   nom, et 46 autres reconnus **par leur code** ([PaysEnseignant.parCode]).
///   Un pays sans image (ecrit dans « Autre ») garde son nom seul : jamais de
///   lettres orphelines.
/// - Le drapeau a la hauteur du corps du texte (taille de police agrandie
///   par l'echelle de l'appareil), au format 4:3.
/// - Le drapeau est decoratif pour le lecteur d'ecran : la phrase lue est
///   « Pays : Guinee ».
///
/// **Par code ISO (LISTES-1, 23/10/2026)** : [PaysEnseignant.parCode] prend le
/// code a deux lettres que portent les candidatures, les comptes et le serveur
/// (`pays_residence`), pas un nom francais. Le nom vient de `pays_iso.dart`,
/// **dans la langue de l'interface** (francais ou arabe) ; le drapeau est
/// l'image embarquee du code si elle existe ([drapeauxEmbarques]), sinon le nom
/// reste seul. Le nom est toujours ecrit : le drapeau n'est jamais la seule
/// information.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class PaysEnseignant extends StatelessWidget {
  /// Cree la ligne du pays.
  const PaysEnseignant({
    required this.pays,
    super.key,
    this.style,
    this.centre = false,
  }) : codeIso = null;

  /// Cree la ligne du pays d'un **code ISO 3166-1 alpha-2** (« GN »), ou rien
  /// si le code est nul ou n'est pas de deux lettres. Le nom est celui de la
  /// langue de l'interface ; un code que la table ne connait pas s'ecrit tel
  /// quel, sans drapeau (jamais un trou).
  const PaysEnseignant.parCode({
    required this.codeIso,
    super.key,
    this.style,
    this.centre = false,
  }) : pays = null;

  /// Le code ISO du pays ([PaysEnseignant.parCode]), ou nul.
  final String? codeIso;

  /// Le pays declare par l'enseignant (`teacher_profiles.country`, nom en
  /// clair depuis FORM-L8), ou nul.
  final String? pays;

  /// Le code ISO en majuscules s'il est bien de deux lettres, sinon nul.
  static String? codeValide(String? code) {
    final String? c = code?.trim().toUpperCase();
    return c != null && RegExp(r'^[A-Z]{2}$').hasMatch(c) ? c : null;
  }

  /// Vrai quand l'image du drapeau du code [code] est embarquee.
  static bool aUnDrapeau(String? code) {
    final String? c = codeValide(code);
    return c != null && drapeauxEmbarques.contains(c);
  }

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
    final String? codePropre = codeValide(codeIso);
    final String? nom = codeIso != null
        ? (codePropre == null ? null : nomDuPays(codePropre))
        : nomAffichable(pays);
    if (nom == null) return const SizedBox.shrink();
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleNom =
        style ??
        AppPalette.of(context).inkMuted
            .applyTo(textes.bodySmall ?? const TextStyle());
    final String? code = codeIso != null
        ? (aUnDrapeau(codePropre) ? codePropre : null)
        : codeIsoDuPays(nom);
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

/// Les codes ISO dont l'image du drapeau est embarquee (`assets/flags/`). Un
/// test compare cette liste au contenu du dossier : une image ajoutee sans la
/// declarer ici, ou declaree sans image, echoue. Les 19 pays de FORM-L8, puis
/// ceux de l'Afrique de l'Ouest, centrale et de l'Est, du Maghreb, de l'Europe
/// de l'Ouest, de l'Amerique du Nord et du Golfe (LISTES-1, 23/10/2026), puis
/// tous les pays de la liste des indicatifs (CAND-04, 23/10/2026).
const Set<String> drapeauxEmbarques = <String>{
  'AD',
  'AE',
  'AF',
  'AG',
  'AI',
  'AL',
  'AM',
  'AO',
  'AQ',
  'AR',
  'AS',
  'AT',
  'AU',
  'AW',
  'AX',
  'AZ',
  'BA',
  'BB',
  'BD',
  'BE',
  'BF',
  'BG',
  'BH',
  'BI',
  'BJ',
  'BL',
  'BM',
  'BN',
  'BO',
  'BQ',
  'BR',
  'BS',
  'BT',
  'BW',
  'BY',
  'BZ',
  'CA',
  'CC',
  'CD',
  'CF',
  'CG',
  'CH',
  'CI',
  'CK',
  'CL',
  'CM',
  'CN',
  'CO',
  'CR',
  'CU',
  'CV',
  'CW',
  'CX',
  'CY',
  'CZ',
  'DE',
  'DJ',
  'DK',
  'DM',
  'DO',
  'DZ',
  'EC',
  'EE',
  'EG',
  'EH',
  'ER',
  'ES',
  'ET',
  'FI',
  'FJ',
  'FK',
  'FM',
  'FO',
  'FR',
  'GA',
  'GB',
  'GD',
  'GE',
  'GF',
  'GG',
  'GH',
  'GI',
  'GL',
  'GM',
  'GN',
  'GP',
  'GQ',
  'GR',
  'GS',
  'GT',
  'GU',
  'GW',
  'GY',
  'HK',
  'HM',
  'HN',
  'HR',
  'HT',
  'HU',
  'ID',
  'IE',
  'IL',
  'IM',
  'IN',
  'IO',
  'IQ',
  'IR',
  'IS',
  'IT',
  'JE',
  'JM',
  'JO',
  'JP',
  'KE',
  'KG',
  'KH',
  'KI',
  'KM',
  'KN',
  'KP',
  'KR',
  'KW',
  'KY',
  'KZ',
  'LA',
  'LB',
  'LC',
  'LI',
  'LK',
  'LR',
  'LS',
  'LT',
  'LU',
  'LV',
  'LY',
  'MA',
  'MC',
  'MD',
  'ME',
  'MF',
  'MG',
  'MH',
  'MK',
  'ML',
  'MM',
  'MN',
  'MO',
  'MP',
  'MQ',
  'MR',
  'MS',
  'MT',
  'MU',
  'MV',
  'MW',
  'MX',
  'MY',
  'MZ',
  'NA',
  'NC',
  'NE',
  'NF',
  'NG',
  'NI',
  'NL',
  'NO',
  'NP',
  'NR',
  'NU',
  'NZ',
  'OM',
  'PA',
  'PE',
  'PF',
  'PG',
  'PH',
  'PK',
  'PL',
  'PM',
  'PN',
  'PR',
  'PS',
  'PT',
  'PW',
  'PY',
  'QA',
  'RE',
  'RO',
  'RS',
  'RU',
  'RW',
  'SA',
  'SB',
  'SC',
  'SD',
  'SE',
  'SG',
  'SH',
  'SI',
  'SJ',
  'SK',
  'SL',
  'SM',
  'SN',
  'SO',
  'SR',
  'SS',
  'ST',
  'SV',
  'SX',
  'SY',
  'SZ',
  'TC',
  'TD',
  'TF',
  'TG',
  'TH',
  'TJ',
  'TK',
  'TL',
  'TM',
  'TN',
  'TO',
  'TR',
  'TT',
  'TV',
  'TW',
  'TZ',
  'UA',
  'UG',
  'UM',
  'US',
  'UY',
  'UZ',
  'VA',
  'VC',
  'VE',
  'VG',
  'VI',
  'VN',
  'VU',
  'WF',
  'WS',
  'YE',
  'YT',
  'ZA',
  'ZM',
  'ZW',
};

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
