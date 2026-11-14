// La liste des pays de la planete (ISO 3166-1 alpha-2), avec leur nom en
// francais et en arabe, pour le formulaire des avis (DECISION-AVIS-2026-10-19).
//
// Une table de donnees, pas des libelles d'ecran : le nom d'un pays est un
// nom propre, il suit la langue de l'interface comme `villes_fuseau.dart`. Le
// serveur ne recoit que le code a deux lettres. Une langue sans table (espagnol,
// portugais) lit le nom francais.

import 'strings.g.dart';

/// Un pays : son code ISO et ses noms.
class PaysIso {
  /// Cree un pays.
  const PaysIso(this.code, this.fr, this.ar, this.en);

  /// Le code ISO 3166-1 alpha-2, en majuscules.
  final String code;

  /// Le nom en francais.
  final String fr;

  /// Le nom en arabe.
  final String ar;

  /// Le nom en anglais (LANGUES-1).
  final String en;

  /// Le nom dans la langue active de l'interface.
  String get nom => switch (LocaleSettings.currentLocale) {
    AppLocale.ar => ar,
    AppLocale.en => en,
    AppLocale.fr => fr,
  };
}

/// Tous les pays, dans l'ordre des codes.
final List<PaysIso> paysIso = List<PaysIso>.unmodifiable(<PaysIso>[
  for (final String ligne in _table.trim().split('\n'))
    PaysIso(
      ligne.split('|')[0],
      ligne.split('|')[1],
      ligne.split('|')[2],
      ligne.split('|')[3],
    ),
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

const String _table = '''AF|Afghanistan|أفغانستان|Afghanistan
AX|Îles Åland|جزر أولاند|Åland Islands
AL|Albanie|ألبانيا|Albania
DZ|Algérie|الجزائر|Algeria
AS|Samoa américaines|ساموا الأمريكية|American Samoa
AD|Andorre|أندورا|Andorra
AO|Angola|أنغولا|Angola
AI|Anguilla|أنغيلا|Anguilla
AQ|Antarctique|أنتاركتيكا|Antarctica
AG|Antigua-et-Barbuda|أنتيغوا وبربودا|Antigua and Barbuda
AR|Argentine|الأرجنتين|Argentina
AM|Arménie|أرمينيا|Armenia
AW|Aruba|أروبا|Aruba
AU|Australie|أستراليا|Australia
AT|Autriche|النمسا|Austria
AZ|Azerbaïdjan|أذربيجان|Azerbaijan
BS|Bahamas|جزر البهاما|Bahamas
BH|Bahreïn|البحرين|Bahrain
BD|Bangladesh|بنغلاديش|Bangladesh
BB|Barbade|بربادوس|Barbados
BY|Biélorussie|بيلاروسيا|Belarus
BE|Belgique|بلجيكا|Belgium
BZ|Belize|بليز|Belize
BJ|Bénin|بنين|Benin
BM|Bermudes|برمودا|Bermuda
BT|Bhoutan|بوتان|Bhutan
BO|Bolivie|بوليفيا|Bolivia
BQ|Pays-Bas caribéens|هولندا الكاريبية|Bonaire, Sint Eustatius and Saba
BA|Bosnie-Herzégovine|البوسنة والهرسك|Bosnia and Herzegovina
BW|Botswana|بوتسوانا|Botswana
BV|Île Bouvet|جزيرة بوفيه|Bouvet Island
BR|Brésil|البرازيل|Brazil
IO|Territoire britannique de l'océan Indien|إقليم المحيط الهندي البريطاني|British Indian Ocean Territory
BN|Brunei|بروناي|Brunei
BG|Bulgarie|بلغاريا|Bulgaria
BF|Burkina Faso|بوركينا فاسو|Burkina Faso
BI|Burundi|بوروندي|Burundi
CV|Cap-Vert|الرأس الأخضر|Cape Verde
KH|Cambodge|كمبوديا|Cambodia
CM|Cameroun|الكاميرون|Cameroon
CA|Canada|كندا|Canada
KY|Îles Caïmans|جزر كايمان|Cayman Islands
CF|République centrafricaine|جمهورية أفريقيا الوسطى|Central African Republic
TD|Tchad|تشاد|Chad
CL|Chili|تشيلي|Chile
CN|Chine|الصين|China
CX|Île Christmas|جزيرة كريسماس|Christmas Island
CC|Îles Cocos|جزر كوكوس|Cocos (Keeling) Islands
CO|Colombie|كولومبيا|Colombia
KM|Comores|جزر القمر|Comoros
CG|Congo|الكونغو|Congo
CD|République démocratique du Congo|جمهورية الكونغو الديمقراطية|DR Congo
CK|Îles Cook|جزر كوك|Cook Islands
CR|Costa Rica|كوستاريكا|Costa Rica
CI|Côte d'Ivoire|ساحل العاج|Côte d'Ivoire
HR|Croatie|كرواتيا|Croatia
CU|Cuba|كوبا|Cuba
CW|Curaçao|كوراساو|Curaçao
CY|Chypre|قبرص|Cyprus
CZ|Tchéquie|التشيك|Czechia
DK|Danemark|الدنمارك|Denmark
DJ|Djibouti|جيبوتي|Djibouti
DM|Dominique|دومينيكا|Dominica
DO|République dominicaine|جمهورية الدومينيكان|Dominican Republic
EC|Équateur|الإكوادور|Ecuador
EG|Égypte|مصر|Egypt
SV|Salvador|السلفادور|El Salvador
GQ|Guinée équatoriale|غينيا الاستوائية|Equatorial Guinea
ER|Érythrée|إريتريا|Eritrea
EE|Estonie|إستونيا|Estonia
SZ|Eswatini|إسواتيني|Eswatini
ET|Éthiopie|إثيوبيا|Ethiopia
FK|Îles Malouines|جزر فوكلاند|Falkland Islands
FO|Îles Féroé|جزر فارو|Faroe Islands
FJ|Fidji|فيجي|Fiji
FI|Finlande|فنلندا|Finland
FR|France|فرنسا|France
GF|Guyane française|غويانا الفرنسية|French Guiana
PF|Polynésie française|بولينيزيا الفرنسية|French Polynesia
TF|Terres australes françaises|الأقاليم الجنوبية الفرنسية|French Southern Territories
GA|Gabon|الغابون|Gabon
GM|Gambie|غامبيا|Gambia
GE|Géorgie|جورجيا|Georgia
DE|Allemagne|ألمانيا|Germany
GH|Ghana|غانا|Ghana
GI|Gibraltar|جبل طارق|Gibraltar
GR|Grèce|اليونان|Greece
GL|Groenland|غرينلاند|Greenland
GD|Grenade|غرينادا|Grenada
GP|Guadeloupe|غوادلوب|Guadeloupe
GU|Guam|غوام|Guam
GT|Guatemala|غواتيمالا|Guatemala
GG|Guernesey|غيرنزي|Guernsey
GN|Guinée|غينيا|Guinea
GW|Guinée-Bissau|غينيا بيساو|Guinea-Bissau
GY|Guyana|غيانا|Guyana
HT|Haïti|هايتي|Haiti
HM|Îles Heard-et-MacDonald|جزيرة هيرد وجزر ماكدونالد|Heard Island and McDonald Islands
VA|Vatican|الفاتيكان|Vatican City
HN|Honduras|هندوراس|Honduras
HK|Hong Kong|هونغ كونغ|Hong Kong
HU|Hongrie|المجر|Hungary
IS|Islande|آيسلندا|Iceland
IN|Inde|الهند|India
ID|Indonésie|إندونيسيا|Indonesia
IR|Iran|إيران|Iran
IQ|Irak|العراق|Iraq
IE|Irlande|أيرلندا|Ireland
IM|Île de Man|جزيرة مان|Isle of Man
IL|Israël|إسرائيل|Israel
IT|Italie|إيطاليا|Italy
JM|Jamaïque|جامايكا|Jamaica
JP|Japon|اليابان|Japan
JE|Jersey|جيرسي|Jersey
JO|Jordanie|الأردن|Jordan
KZ|Kazakhstan|كازاخستان|Kazakhstan
KE|Kenya|كينيا|Kenya
KI|Kiribati|كيريباتي|Kiribati
KP|Corée du Nord|كوريا الشمالية|North Korea
KR|Corée du Sud|كوريا الجنوبية|South Korea
KW|Koweït|الكويت|Kuwait
KG|Kirghizistan|قيرغيزستان|Kyrgyzstan
LA|Laos|لاوس|Laos
LV|Lettonie|لاتفيا|Latvia
LB|Liban|لبنان|Lebanon
LS|Lesotho|ليسوتو|Lesotho
LR|Libéria|ليبيريا|Liberia
LY|Libye|ليبيا|Libya
LI|Liechtenstein|ليختنشتاين|Liechtenstein
LT|Lituanie|ليتوانيا|Lithuania
LU|Luxembourg|لوكسمبورغ|Luxembourg
MO|Macao|ماكاو|Macau
MG|Madagascar|مدغشقر|Madagascar
MW|Malawi|مالاوي|Malawi
MY|Malaisie|ماليزيا|Malaysia
MV|Maldives|جزر المالديف|Maldives
ML|Mali|مالي|Mali
MT|Malte|مالطا|Malta
MH|Îles Marshall|جزر مارشال|Marshall Islands
MQ|Martinique|مارتينيك|Martinique
MR|Mauritanie|موريتانيا|Mauritania
MU|Maurice|موريشيوس|Mauritius
YT|Mayotte|مايوت|Mayotte
MX|Mexique|المكسيك|Mexico
FM|Micronésie|ميكرونيزيا|Micronesia
MD|Moldavie|مولدوفا|Moldova
MC|Monaco|موناكو|Monaco
MN|Mongolie|منغوليا|Mongolia
ME|Monténégro|الجبل الأسود|Montenegro
MS|Montserrat|مونتسرات|Montserrat
MA|Maroc|المغرب|Morocco
MZ|Mozambique|موزمبيق|Mozambique
MM|Birmanie|ميانمار|Myanmar
NA|Namibie|ناميبيا|Namibia
NR|Nauru|ناورو|Nauru
NP|Népal|نيبال|Nepal
NL|Pays-Bas|هولندا|Netherlands
NC|Nouvelle-Calédonie|كاليدونيا الجديدة|New Caledonia
NZ|Nouvelle-Zélande|نيوزيلندا|New Zealand
NI|Nicaragua|نيكاراغوا|Nicaragua
NE|Niger|النيجر|Niger
NG|Nigéria|نيجيريا|Nigeria
NU|Niue|نيوي|Niue
NF|Île Norfolk|جزيرة نورفولك|Norfolk Island
MK|Macédoine du Nord|مقدونيا الشمالية|North Macedonia
MP|Îles Mariannes du Nord|جزر ماريانا الشمالية|Northern Mariana Islands
NO|Norvège|النرويج|Norway
OM|Oman|عمان|Oman
PK|Pakistan|باكستان|Pakistan
PW|Palaos|بالاو|Palau
PS|Palestine|فلسطين|Palestine
PA|Panama|بنما|Panama
PG|Papouasie-Nouvelle-Guinée|بابوا غينيا الجديدة|Papua New Guinea
PY|Paraguay|باراغواي|Paraguay
PE|Pérou|بيرو|Peru
PH|Philippines|الفلبين|Philippines
PN|Îles Pitcairn|جزر بيتكيرن|Pitcairn
PL|Pologne|بولندا|Poland
PT|Portugal|البرتغال|Portugal
PR|Porto Rico|بورتوريكو|Puerto Rico
QA|Qatar|قطر|Qatar
RE|La Réunion|لا ريونيون|Réunion
RO|Roumanie|رومانيا|Romania
RU|Russie|روسيا|Russia
RW|Rwanda|رواندا|Rwanda
BL|Saint-Barthélemy|سان بارتيلمي|Saint Barthélemy
SH|Sainte-Hélène|سانت هيلانة|Saint Helena
KN|Saint-Christophe-et-Niévès|سانت كيتس ونيفيس|Saint Kitts and Nevis
LC|Sainte-Lucie|سانت لوسيا|Saint Lucia
MF|Saint-Martin (partie française)|سان مارتن الفرنسية|Saint Martin (French part)
PM|Saint-Pierre-et-Miquelon|سان بيير وميكلون|Saint Pierre and Miquelon
VC|Saint-Vincent-et-les-Grenadines|سانت فنسنت والغرينادين|Saint Vincent and the Grenadines
WS|Samoa|ساموا|Samoa
SM|Saint-Marin|سان مارينو|San Marino
ST|Sao Tomé-et-Principe|ساو تومي وبرينسيبي|Sao Tome and Principe
SA|Arabie saoudite|السعودية|Saudi Arabia
SN|Sénégal|السنغال|Senegal
RS|Serbie|صربيا|Serbia
SC|Seychelles|سيشل|Seychelles
SL|Sierra Leone|سيراليون|Sierra Leone
SG|Singapour|سنغافورة|Singapore
SX|Saint-Martin (partie néerlandaise)|سينت مارتن الهولندية|Sint Maarten (Dutch part)
SK|Slovaquie|سلوفاكيا|Slovakia
SI|Slovénie|سلوفينيا|Slovenia
SB|Îles Salomon|جزر سليمان|Solomon Islands
SO|Somalie|الصومال|Somalia
ZA|Afrique du Sud|جنوب أفريقيا|South Africa
GS|Géorgie du Sud et îles Sandwich du Sud|جورجيا الجنوبية وجزر ساندويتش الجنوبية|South Georgia and the South Sandwich Islands
SS|Soudan du Sud|جنوب السودان|South Sudan
ES|Espagne|إسبانيا|Spain
LK|Sri Lanka|سريلانكا|Sri Lanka
SD|Soudan|السودان|Sudan
SR|Suriname|سورينام|Suriname
SJ|Svalbard et Jan Mayen|سفالبارد ويان ماين|Svalbard and Jan Mayen
SE|Suède|السويد|Sweden
CH|Suisse|سويسرا|Switzerland
SY|Syrie|سوريا|Syria
TW|Taïwan|تايوان|Taiwan
TJ|Tadjikistan|طاجيكستان|Tajikistan
TZ|Tanzanie|تنزانيا|Tanzania
TH|Thaïlande|تايلاند|Thailand
TL|Timor oriental|تيمور الشرقية|Timor-Leste
TG|Togo|توغو|Togo
TK|Tokelau|توكيلاو|Tokelau
TO|Tonga|تونغا|Tonga
TT|Trinité-et-Tobago|ترينيداد وتوباغو|Trinidad and Tobago
TN|Tunisie|تونس|Tunisia
TR|Turquie|تركيا|Turkey
TM|Turkménistan|تركمانستان|Turkmenistan
TC|Îles Turques-et-Caïques|جزر توركس وكايكوس|Turks and Caicos Islands
TV|Tuvalu|توفالو|Tuvalu
UG|Ouganda|أوغندا|Uganda
UA|Ukraine|أوكرانيا|Ukraine
AE|Émirats arabes unis|الإمارات|United Arab Emirates
GB|Royaume-Uni|المملكة المتحدة|United Kingdom
US|États-Unis|الولايات المتحدة|United States
UM|Îles mineures éloignées des États-Unis|جزر الولايات المتحدة الصغيرة النائية|United States Minor Outlying Islands
UY|Uruguay|أوروغواي|Uruguay
UZ|Ouzbékistan|أوزبكستان|Uzbekistan
VU|Vanuatu|فانواتو|Vanuatu
VE|Venezuela|فنزويلا|Venezuela
VN|Viêt Nam|فيتنام|Vietnam
VG|Îles Vierges britanniques|جزر فيرجن البريطانية|British Virgin Islands
VI|Îles Vierges des États-Unis|جزر فيرجن الأمريكية|U.S. Virgin Islands
WF|Wallis-et-Futuna|واليس وفوتونا|Wallis and Futuna
EH|Sahara occidental|الصحراء الغربية|Western Sahara
YE|Yémen|اليمن|Yemen
ZM|Zambie|زامبيا|Zambia
ZW|Zimbabwe|زيمبابوي|Zimbabwe
''';
