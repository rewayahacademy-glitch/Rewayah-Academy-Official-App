// Les indicatifs telephoniques des pays (`CAND-04`, `CAND-F12`), pour que la
// personne **choisisse** l'indicatif dans la liste des pays (recherche en
// francais ou en arabe, `pays_iso.dart`) au lieu de le taper.
//
// Une table de donnees : le code ISO du pays et l'indicatif de l'UIT, sans le
// « + ». Elle ne contient que des indicatifs que le serveur reconnait
// (`private.indicatifs_telephoniques`, migration
// `20261022000600_cand_l3_inscription_import_rapprochement.sql`) : un test les
// lit dans la migration et echoue si un indicatif d'ici manque la-bas. Un
// indicatif absent n'est jamais devine. Le pays de Bouvet (`BV`) n'a aucun
// indicatif et n'est donc jamais propose.
//
// Les pays du plan nord-americain partagent `1` ; la zone locale (514, 809...)
// fait partie du numero saisi.

import 'pays_iso.dart';

/// Les indicatifs dont le numero **garde** son 0 de debut : l'Italie, la Cote
/// d'Ivoire, le Gabon et le Benin (comme le serveur, qui ne les refuse pas).
const Set<String> indicatifsQuiGardentLeZero = <String>{
  '39',
  '225',
  '241',
  '229',
};

/// Le nombre de chiffres, indicatif compris, d'un numero plausible : celui que
/// le serveur accepte pour un numero en forme internationale.
const int chiffresMinimum = 8;

/// Voir [chiffresMinimum].
const int chiffresMaximum = 15;

/// L'indicatif (sans « + ») du pays [iso], ou `null` s'il n'en a pas.
String? indicatifDuPays(String? iso) => _parPays[iso?.toUpperCase()];

/// Les pays qui ont un indicatif, dans l'ordre de `pays_iso.dart`.
final List<PaysIso> paysAvecIndicatif = List<PaysIso>.unmodifiable(
  paysIso.where((PaysIso p) => _parPays.containsKey(p.code)),
);

/// L'indicatif tel qu'on l'affiche (par exemple « +33 »), isole pour que le
/// signe plus reste en tete dans un texte ecrit de droite a gauche.
String indicatifAffiche(String indicatif) => '\u2066+$indicatif\u2069';

/// Le numero **international** (`+` puis l'indicatif et le numero) que le
/// serveur attend, ou `null` quand [saisie] ne se lit pas comme un numero sans
/// indicatif.
///
/// - les chiffres arabo-indiens et persans sont lus comme des chiffres ;
/// - les espaces, points, tirets, barres obliques et parentheses sont ignores ;
/// - le 0 de debut (le « 0 » national : `06...` pour la France) est retire,
///   sauf pour [indicatifsQuiGardentLeZero] ;
/// - un « + », une lettre, ou un numero qui repete un 0 apres celui-la ne se
///   lit pas : la personne doit le corriger, rien n'est devine ;
/// - le numero complet compte de [chiffresMinimum] a [chiffresMaximum] chiffres.
String? telephoneInternational({
  required String indicatif,
  required String saisie,
}) {
  final StringBuffer chiffres = StringBuffer();
  for (final int c in saisie.runes) {
    if (c >= 0x30 && c <= 0x39) {
      chiffres.writeCharCode(c);
    } else if (c >= 0x0660 && c <= 0x0669) {
      chiffres.writeCharCode(0x30 + c - 0x0660);
    } else if (c >= 0x06F0 && c <= 0x06F9) {
      chiffres.writeCharCode(0x30 + c - 0x06F0);
    } else if (!_separateurs.contains(c)) {
      return null;
    }
  }
  String national = chiffres.toString();
  final bool garde = indicatifsQuiGardentLeZero.contains(indicatif);
  if (!garde && national.startsWith('0')) {
    national = national.substring(1);
  }
  if (national.isEmpty || (!garde && national.startsWith('0'))) {
    return null;
  }
  final int total = indicatif.length + national.length;
  if (total < chiffresMinimum || total > chiffresMaximum) {
    return null;
  }
  return '+$indicatif$national';
}

/// Ce qui separe les groupes de chiffres d'un numero et ne compte pas : espace,
/// espace insecable (fine ou non), point, tiret, barre oblique, parentheses, et
/// les marques de direction du texte.
const Set<int> _separateurs = <int>{
  0x20,
  0xA0,
  0x202F,
  0x2E,
  0x2D,
  0x2F,
  0x28,
  0x29,
  0x200E,
  0x200F,
  0x202A,
  0x202B,
  0x202C,
  0x202D,
  0x202E,
  0x2066,
  0x2067,
  0x2068,
  0x2069,
};

final Map<String, String> _parPays = <String, String>{
  for (final String ligne in _table.trim().split(RegExp(r'\s+')))
    ligne.split('|')[0]: ligne.split('|')[1],
};

const String _table = '''
AF|93 AX|358 AL|355 DZ|213 AS|1 AD|376 AO|244 AI|1 AQ|672 AG|1 AR|54
AM|374 AW|297 AU|61 AT|43 AZ|994 BS|1 BH|973 BD|880 BB|1 BY|375 BE|32
BZ|501 BJ|229 BM|1 BT|975 BO|591 BQ|599 BA|387 BW|267 BR|55 IO|246
BN|673 BG|359 BF|226 BI|257 CV|238 KH|855 CM|237 CA|1 KY|1 CF|236
TD|235 CL|56 CN|86 CX|61 CC|61 CO|57 KM|269 CG|242 CD|243 CK|682
CR|506 CI|225 HR|385 CU|53 CW|599 CY|357 CZ|420 DK|45 DJ|253 DM|1 DO|1
EC|593 EG|20 SV|503 GQ|240 ER|291 EE|372 SZ|268 ET|251 FK|500 FO|298
FJ|679 FI|358 FR|33 GF|594 PF|689 TF|262 GA|241 GM|220 GE|995 DE|49
GH|233 GI|350 GR|30 GL|299 GD|1 GP|590 GU|1 GT|502 GG|44 GN|224 GW|245
GY|592 HT|509 HM|672 VA|39 HN|504 HK|852 HU|36 IS|354 IN|91 ID|62
IR|98 IQ|964 IE|353 IM|44 IL|972 IT|39 JM|1 JP|81 JE|44 JO|962 KZ|7
KE|254 KI|686 KP|850 KR|82 KW|965 KG|996 LA|856 LV|371 LB|961 LS|266
LR|231 LY|218 LI|423 LT|370 LU|352 MO|853 MG|261 MW|265 MY|60 MV|960
ML|223 MT|356 MH|692 MQ|596 MR|222 MU|230 YT|262 MX|52 FM|691 MD|373
MC|377 MN|976 ME|382 MS|1 MA|212 MZ|258 MM|95 NA|264 NR|674 NP|977
NL|31 NC|687 NZ|64 NI|505 NE|227 NG|234 NU|683 NF|672 MK|389 MP|1
NO|47 OM|968 PK|92 PW|680 PS|970 PA|507 PG|675 PY|595 PE|51 PH|63
PN|64 PL|48 PT|351 PR|1 QA|974 RE|262 RO|40 RU|7 RW|250 BL|590 SH|290
KN|1 LC|1 MF|590 PM|508 VC|1 WS|685 SM|378 ST|239 SA|966 SN|221 RS|381
SC|248 SL|232 SG|65 SX|1 SK|421 SI|386 SB|677 SO|252 ZA|27 GS|500
SS|211 ES|34 LK|94 SD|249 SR|597 SJ|47 SE|46 CH|41 SY|963 TW|886
TJ|992 TZ|255 TH|66 TL|670 TG|228 TK|690 TO|676 TT|1 TN|216 TR|90
TM|993 TC|1 TV|688 UG|256 UA|380 AE|971 GB|44 US|1 UM|1 UY|598 UZ|998
VU|678 VE|58 VN|84 VG|1 VI|1 WF|681 EH|212 YE|967 ZM|260 ZW|263
''';
