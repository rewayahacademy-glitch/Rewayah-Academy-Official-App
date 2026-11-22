// ONBOARDING-PRAXIS (directeur, 22/11/2026) : les valeurs fermees du
// questionnaire avant le compte, et ce que le programme en deduit. Les codes
// sont ceux de la base (`supabase/migrations/20261130978000_onboarding_praxis.sql`) ;
// les libelles sont des cles i18n (`onboarding.*`).
library;

/// La lecture du Coran (directeur, 22/11/2026 : Hafs preselectionnee, Warsh,
/// une autre a preciser). Le nom est le code serveur (`riwaya`).
enum LectureCoran {
  /// Hafs, la plus repandue, choisie par defaut.
  hafs,

  /// Warsh, notee pour la direction (aucune classe n'est promise).
  warsh,

  /// Une autre lecture, a preciser.
  autre,
}

/// Combien est deja memorise.
enum QuantiteMemorisee {
  /// Quelques sourates.
  quelquesSourates('quelques_sourates'),

  /// Un a cinq juz.
  unACinqJuz('1_5_juz'),

  /// Plus de cinq juz.
  plusDeCinqJuz('plus_5_juz'),

  /// Tout le Coran.
  coranEntier('coran_entier');

  const QuantiteMemorisee(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit une quantite, ou `null`.
  static QuantiteMemorisee? depuisSql(String? valeur) => QuantiteMemorisee
      .values
      .where((QuantiteMemorisee q) => q.valeurSql == valeur)
      .firstOrNull;
}

/// L'objectif, tel que l'ecran le propose (la base en deduit son code :
/// « lire » devient « apprendre a lire » ou « devenir fluide » selon le
/// niveau).
enum ObjectifOnboarding {
  /// Apprendre a lire, ou lire tout le Coran couramment.
  lire,

  /// Memoriser le Coran.
  memoriser,

  /// La priere et les invocations (enfant seulement).
  priere,

  /// Pas encore decide : l'enseignant conseillera.
  indecis,
}

/// « Comment avez-vous connu Rewayah ? » (facultatif). Le nom est le code
/// serveur (`source_declaree`).
enum SourceConnaissance {
  /// Mosquee ou association.
  mosquee,

  /// Famille ou ami.
  proche,

  /// Reseaux sociaux.
  reseaux,

  /// Recherche en ligne.
  recherche,

  /// Autre.
  autre,
}

/// Les tranches d'age du programme et la duree des bases pour un debutant
/// (competence `programme-rewayah`, §3 : durees prevues 37, 28, 24, 15
/// semaines ; dates limites 48, 36, 31, 20).
enum TrancheAge {
  /// 6 a 9 ans.
  de6a9(37, 48),

  /// 10 a 13 ans.
  de10a13(28, 36),

  /// 14 a 17 ans.
  de14a17(24, 31),

  /// 18 ans et plus.
  adulte(15, 20);

  const TrancheAge(this.semainesPrevues, this.semainesLimite);

  /// La duree prevue des bases, en semaines.
  final int semainesPrevues;

  /// La date limite des bases, en semaines.
  final int semainesLimite;
}

/// Les 17 sourates des bases, dans l'ordre du programme (Al-Fatiha, puis
/// An-Nas a Az-Zalzalah) ; codes stables de la base.
const List<String> souratesDesBases = <String>[
  'fatiha',
  'nas',
  'falaq',
  'ikhlas',
  'masad',
  'nasr',
  'kafirun',
  'kawthar',
  'maun',
  'quraysh',
  'fil',
  'humaza',
  'asr',
  'takathur',
  'qaria',
  'adiyat',
  'zalzala',
];

/// Un groupe de langues des explications.
enum GroupeLangues {
  /// Les plus demandees.
  plusDemandees,

  /// Langues d'Afrique.
  afrique,

  /// Langues d'Asie.
  asie,

  /// Langues d'Europe.
  europe,
}

/// Les langues des explications, groupees comme la maquette (directeur,
/// 22/11/2026 : les langues des enseignants). Les codes sont ceux des langues
/// declarees par les candidats enseignants (`recrutement.parcours.langues`),
/// et ceux du referentiel des classes quand la langue y est.
const Map<GroupeLangues, List<String>> languesDesExplications =
    <GroupeLangues, List<String>>{
      GroupeLangues.plusDemandees: <String>['francais', 'english', 'ar'],
      GroupeLangues.afrique: <String>[
        'ha',
        'poular',
        'yo',
        'man',
        'snk',
        'wo',
        'bm',
        'sw',
        'so',
        'am',
        'om',
      ],
      GroupeLangues.asie: <String>[
        'ur',
        'hi',
        'bn',
        'ps',
        'fa',
        'tr',
        'id',
        'uz',
      ],
      GroupeLangues.europe: <String>['pt', 'ru', 'de'],
    };

/// Tous les codes, dans l'ordre d'affichage.
final List<String> codesDesExplications = <String>[
  for (final List<String> l in languesDesExplications.values) ...l,
];

/// La langue des explications deduite de la langue de l'appareil (« deduit >
/// choisi > saisi »), ou `null` si elle n'est pas dans la liste.
String? langueDeLAppareil(String codeAppareil) => switch (codeAppareil) {
  'fr' => 'francais',
  'en' => 'english',
  'ff' => 'poular',
  final String c when codesDesExplications.contains(c) => c,
  _ => null,
};
