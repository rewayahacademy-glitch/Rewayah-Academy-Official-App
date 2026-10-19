// La liste des pays de la planete (ISO 3166-1 alpha-2), avec leur nom en
// francais et en arabe, pour le formulaire des avis (DECISION-AVIS-2026-10-19).
//
// Une table de donnees, pas des libelles d'ecran : le nom d'un pays est un
// nom propre, il suit la langue de l'interface comme `villes_fuseau.dart`. Le
// serveur ne recoit que le code a deux lettres. Une langue sans table (anglais,
// espagnol, portugais) lit le nom francais.

import 'strings.g.dart';

/// Un pays : son code ISO et ses noms.
class PaysIso {
  /// Cree un pays.
  const PaysIso(this.code, this.fr, this.ar);

  /// Le code ISO 3166-1 alpha-2, en majuscules.
  final String code;

  /// Le nom en francais.
  final String fr;

  /// Le nom en arabe.
  final String ar;

  /// Le nom dans la langue active de l'interface.
  String get nom => LocaleSettings.currentLocale == AppLocale.ar ? ar : fr;
}

/// Tous les pays, dans l'ordre des codes.
final List<PaysIso> paysIso = List<PaysIso>.unmodifiable(<PaysIso>[
  for (final String ligne in _table.trim().split('\n'))
    PaysIso(ligne.split('|')[0], ligne.split('|')[1], ligne.split('|')[2]),
]);

final Map<String, PaysIso> _parCode = <String, PaysIso>{
  for (final PaysIso p in paysIso) p.code: p,
};

/// Le pays de [code], ou `null` si le code est inconnu.
PaysIso? paysDuCode(String? code) => _parCode[code?.toUpperCase()];

/// Le nom du pays de [code] dans la langue active ; le code lui-meme s'il est
/// inconnu (jamais un trou).
String nomDuPays(String code) => paysDuCode(code)?.nom ?? code;

/// La forme de recherche d'un texte : minuscules, sans accent, sans tiret ni
/// apostrophe, espaces simples. Les marques arabes (voyelles breves) et la
/// forme des lettres alif sont ramenees a l'alif nu.
String formeDeRecherche(String texte) {
  const Map<String, String> sansAccent = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'ø': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'œ': 'oe',
    'ÿ': 'y',
    'ć': 'c',
    'č': 'c',
    'š': 's',
    'ž': 'z',
    'ı': 'i',
    'ğ': 'g',
    'ș': 's',
    'ț': 't',
    'ł': 'l',
    '’': ' ',
    "'": ' ',
    '-': ' ',
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ى': 'ي',
    'ة': 'ه',
  };
  final StringBuffer sortie = StringBuffer();
  for (final String c in texte.trim().toLowerCase().split('')) {
    final int u = c.codeUnitAt(0);
    // Les marques de voyelles arabes (U+064B a U+0652) ne comptent pas.
    if (u >= 0x064B && u <= 0x0652) continue;
    sortie.write(sansAccent[c] ?? c);
  }
  return sortie.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Les pays dont le nom (dans la langue active, ou l'autre) ou le code
/// contient [requete], tries par nom dans la langue active. Une requete vide
/// rend tous les pays.
List<PaysIso> chercherPays(String requete) {
  final String q = formeDeRecherche(requete);
  final List<PaysIso> trouves = paysIso
      .where(
        (PaysIso p) =>
            q.isEmpty ||
            formeDeRecherche(p.nom).contains(q) ||
            formeDeRecherche(p.fr).contains(q) ||
            formeDeRecherche(p.ar).contains(q) ||
            p.code.toLowerCase() == q,
      )
      .toList();
  trouves.sort(
    (PaysIso a, PaysIso b) =>
        formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom)),
  );
  return trouves;
}

const String _table = '''
AF|Afghanistan|أفغانستان
AX|Îles Åland|جزر أولاند
AL|Albanie|ألبانيا
DZ|Algérie|الجزائر
AS|Samoa américaines|ساموا الأمريكية
AD|Andorre|أندورا
AO|Angola|أنغولا
AI|Anguilla|أنغيلا
AQ|Antarctique|أنتاركتيكا
AG|Antigua-et-Barbuda|أنتيغوا وبربودا
AR|Argentine|الأرجنتين
AM|Arménie|أرمينيا
AW|Aruba|أروبا
AU|Australie|أستراليا
AT|Autriche|النمسا
AZ|Azerbaïdjan|أذربيجان
BS|Bahamas|جزر البهاما
BH|Bahreïn|البحرين
BD|Bangladesh|بنغلاديش
BB|Barbade|بربادوس
BY|Biélorussie|بيلاروسيا
BE|Belgique|بلجيكا
BZ|Belize|بليز
BJ|Bénin|بنين
BM|Bermudes|برمودا
BT|Bhoutan|بوتان
BO|Bolivie|بوليفيا
BQ|Pays-Bas caribéens|هولندا الكاريبية
BA|Bosnie-Herzégovine|البوسنة والهرسك
BW|Botswana|بوتسوانا
BV|Île Bouvet|جزيرة بوفيه
BR|Brésil|البرازيل
IO|Territoire britannique de l'océan Indien|إقليم المحيط الهندي البريطاني
BN|Brunei|بروناي
BG|Bulgarie|بلغاريا
BF|Burkina Faso|بوركينا فاسو
BI|Burundi|بوروندي
CV|Cap-Vert|الرأس الأخضر
KH|Cambodge|كمبوديا
CM|Cameroun|الكاميرون
CA|Canada|كندا
KY|Îles Caïmans|جزر كايمان
CF|République centrafricaine|جمهورية أفريقيا الوسطى
TD|Tchad|تشاد
CL|Chili|تشيلي
CN|Chine|الصين
CX|Île Christmas|جزيرة كريسماس
CC|Îles Cocos|جزر كوكوس
CO|Colombie|كولومبيا
KM|Comores|جزر القمر
CG|Congo|الكونغو
CD|République démocratique du Congo|جمهورية الكونغو الديمقراطية
CK|Îles Cook|جزر كوك
CR|Costa Rica|كوستاريكا
CI|Côte d'Ivoire|ساحل العاج
HR|Croatie|كرواتيا
CU|Cuba|كوبا
CW|Curaçao|كوراساو
CY|Chypre|قبرص
CZ|Tchéquie|التشيك
DK|Danemark|الدنمارك
DJ|Djibouti|جيبوتي
DM|Dominique|دومينيكا
DO|République dominicaine|جمهورية الدومينيكان
EC|Équateur|الإكوادور
EG|Égypte|مصر
SV|Salvador|السلفادور
GQ|Guinée équatoriale|غينيا الاستوائية
ER|Érythrée|إريتريا
EE|Estonie|إستونيا
SZ|Eswatini|إسواتيني
ET|Éthiopie|إثيوبيا
FK|Îles Malouines|جزر فوكلاند
FO|Îles Féroé|جزر فارو
FJ|Fidji|فيجي
FI|Finlande|فنلندا
FR|France|فرنسا
GF|Guyane française|غويانا الفرنسية
PF|Polynésie française|بولينيزيا الفرنسية
TF|Terres australes françaises|الأقاليم الجنوبية الفرنسية
GA|Gabon|الغابون
GM|Gambie|غامبيا
GE|Géorgie|جورجيا
DE|Allemagne|ألمانيا
GH|Ghana|غانا
GI|Gibraltar|جبل طارق
GR|Grèce|اليونان
GL|Groenland|غرينلاند
GD|Grenade|غرينادا
GP|Guadeloupe|غوادلوب
GU|Guam|غوام
GT|Guatemala|غواتيمالا
GG|Guernesey|غيرنزي
GN|Guinée|غينيا
GW|Guinée-Bissau|غينيا بيساو
GY|Guyana|غيانا
HT|Haïti|هايتي
HM|Îles Heard-et-MacDonald|جزيرة هيرد وجزر ماكدونالد
VA|Vatican|الفاتيكان
HN|Honduras|هندوراس
HK|Hong Kong|هونغ كونغ
HU|Hongrie|المجر
IS|Islande|آيسلندا
IN|Inde|الهند
ID|Indonésie|إندونيسيا
IR|Iran|إيران
IQ|Irak|العراق
IE|Irlande|أيرلندا
IM|Île de Man|جزيرة مان
IL|Israël|إسرائيل
IT|Italie|إيطاليا
JM|Jamaïque|جامايكا
JP|Japon|اليابان
JE|Jersey|جيرسي
JO|Jordanie|الأردن
KZ|Kazakhstan|كازاخستان
KE|Kenya|كينيا
KI|Kiribati|كيريباتي
KP|Corée du Nord|كوريا الشمالية
KR|Corée du Sud|كوريا الجنوبية
KW|Koweït|الكويت
KG|Kirghizistan|قيرغيزستان
LA|Laos|لاوس
LV|Lettonie|لاتفيا
LB|Liban|لبنان
LS|Lesotho|ليسوتو
LR|Libéria|ليبيريا
LY|Libye|ليبيا
LI|Liechtenstein|ليختنشتاين
LT|Lituanie|ليتوانيا
LU|Luxembourg|لوكسمبورغ
MO|Macao|ماكاو
MG|Madagascar|مدغشقر
MW|Malawi|مالاوي
MY|Malaisie|ماليزيا
MV|Maldives|جزر المالديف
ML|Mali|مالي
MT|Malte|مالطا
MH|Îles Marshall|جزر مارشال
MQ|Martinique|مارتينيك
MR|Mauritanie|موريتانيا
MU|Maurice|موريشيوس
YT|Mayotte|مايوت
MX|Mexique|المكسيك
FM|Micronésie|ميكرونيزيا
MD|Moldavie|مولدوفا
MC|Monaco|موناكو
MN|Mongolie|منغوليا
ME|Monténégro|الجبل الأسود
MS|Montserrat|مونتسرات
MA|Maroc|المغرب
MZ|Mozambique|موزمبيق
MM|Birmanie|ميانمار
NA|Namibie|ناميبيا
NR|Nauru|ناورو
NP|Népal|نيبال
NL|Pays-Bas|هولندا
NC|Nouvelle-Calédonie|كاليدونيا الجديدة
NZ|Nouvelle-Zélande|نيوزيلندا
NI|Nicaragua|نيكاراغوا
NE|Niger|النيجر
NG|Nigéria|نيجيريا
NU|Niue|نيوي
NF|Île Norfolk|جزيرة نورفولك
MK|Macédoine du Nord|مقدونيا الشمالية
MP|Îles Mariannes du Nord|جزر ماريانا الشمالية
NO|Norvège|النرويج
OM|Oman|عمان
PK|Pakistan|باكستان
PW|Palaos|بالاو
PS|Palestine|فلسطين
PA|Panama|بنما
PG|Papouasie-Nouvelle-Guinée|بابوا غينيا الجديدة
PY|Paraguay|باراغواي
PE|Pérou|بيرو
PH|Philippines|الفلبين
PN|Îles Pitcairn|جزر بيتكيرن
PL|Pologne|بولندا
PT|Portugal|البرتغال
PR|Porto Rico|بورتوريكو
QA|Qatar|قطر
RE|La Réunion|لا ريونيون
RO|Roumanie|رومانيا
RU|Russie|روسيا
RW|Rwanda|رواندا
BL|Saint-Barthélemy|سان بارتيلمي
SH|Sainte-Hélène|سانت هيلانة
KN|Saint-Christophe-et-Niévès|سانت كيتس ونيفيس
LC|Sainte-Lucie|سانت لوسيا
MF|Saint-Martin (partie française)|سان مارتن الفرنسية
PM|Saint-Pierre-et-Miquelon|سان بيير وميكلون
VC|Saint-Vincent-et-les-Grenadines|سانت فنسنت والغرينادين
WS|Samoa|ساموا
SM|Saint-Marin|سان مارينو
ST|Sao Tomé-et-Principe|ساو تومي وبرينسيبي
SA|Arabie saoudite|السعودية
SN|Sénégal|السنغال
RS|Serbie|صربيا
SC|Seychelles|سيشل
SL|Sierra Leone|سيراليون
SG|Singapour|سنغافورة
SX|Saint-Martin (partie néerlandaise)|سينت مارتن الهولندية
SK|Slovaquie|سلوفاكيا
SI|Slovénie|سلوفينيا
SB|Îles Salomon|جزر سليمان
SO|Somalie|الصومال
ZA|Afrique du Sud|جنوب أفريقيا
GS|Géorgie du Sud et îles Sandwich du Sud|جورجيا الجنوبية وجزر ساندويتش الجنوبية
SS|Soudan du Sud|جنوب السودان
ES|Espagne|إسبانيا
LK|Sri Lanka|سريلانكا
SD|Soudan|السودان
SR|Suriname|سورينام
SJ|Svalbard et Jan Mayen|سفالبارد ويان ماين
SE|Suède|السويد
CH|Suisse|سويسرا
SY|Syrie|سوريا
TW|Taïwan|تايوان
TJ|Tadjikistan|طاجيكستان
TZ|Tanzanie|تنزانيا
TH|Thaïlande|تايلاند
TL|Timor oriental|تيمور الشرقية
TG|Togo|توغو
TK|Tokelau|توكيلاو
TO|Tonga|تونغا
TT|Trinité-et-Tobago|ترينيداد وتوباغو
TN|Tunisie|تونس
TR|Turquie|تركيا
TM|Turkménistan|تركمانستان
TC|Îles Turques-et-Caïques|جزر توركس وكايكوس
TV|Tuvalu|توفالو
UG|Ouganda|أوغندا
UA|Ukraine|أوكرانيا
AE|Émirats arabes unis|الإمارات
GB|Royaume-Uni|المملكة المتحدة
US|États-Unis|الولايات المتحدة
UM|Îles mineures éloignées des États-Unis|جزر الولايات المتحدة الصغيرة النائية
UY|Uruguay|أوروغواي
UZ|Ouzbékistan|أوزبكستان
VU|Vanuatu|فانواتو
VE|Venezuela|فنزويلا
VN|Viêt Nam|فيتنام
VG|Îles Vierges britanniques|جزر فيرجن البريطانية
VI|Îles Vierges des États-Unis|جزر فيرجن الأمريكية
WF|Wallis-et-Futuna|واليس وفوتونا
EH|Sahara occidental|الصحراء الغربية
YE|Yémen|اليمن
ZM|Zambie|زامبيا
ZW|Zimbabwe|زيمبابوي
''';
