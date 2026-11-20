// Ce que l'application sait afficher du questionnaire de la Salle d'examen :
// la forme de chaque champ, par son code (CAND-01).
//
// Le serveur rend des **codes**, jamais des libelles (`Questionnaire`) ; les
// textes viennent de `assets/i18n` (`recrutement.parcours.q.<code>`), en
// francais et en arabe. Un champ que cette version de l'application ne connait
// pas ne s'affiche pas a moitie : le parcours dit que l'etape n'est pas encore
// ouverte (`reconnu`), au lieu d'un code brut ou d'un champ sans texte.
library;

import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/icons/app_icons.dart';

/// La facon de poser une question.
enum FormeQuestion {
  /// Une reponse parmi quelques cartes.
  choix,

  /// Plusieurs reponses parmi quelques cartes.
  choixMultiple,

  /// Oui ou non (reponse booleenne).
  ouiNon,

  /// Une langue : cartes, puis recherche.
  langue,

  /// Plusieurs langues : cartes, puis recherche.
  langues,

  /// Un pays : cartes, puis recherche.
  pays,

  /// Plusieurs riwayat : cartes, puis recherche.
  riwayat,

  /// Les disponibilites de la semaine : les jours, puis les heures de debut
  /// (plusieurs ecrans, `EtapeDisponibilites`).
  creneaux,

  /// Le fuseau horaire : confirmation, puis recherche d'une ville.
  fuseau,

  /// Les moyens de paiement sur telephone confirmes dans le pays.
  operateurs,

  /// Le nombre de Classes que la personne veut tenir (de 1 au maximum fixe par
  /// la direction), avec les heures par semaine que cela represente.
  classes,

  /// Les moyens de paiement connus de l'academie, au choix, a titre
  /// d'information : facultatif, jamais lu par le versement.
  moyensAccessibles,
}

/// Ce que l'application sait d'un champ.
class ModeleQuestion {
  /// Cree le modele.
  const ModeleQuestion(
    this.forme, {
    this.icone,
    this.autour = const <AppIcon>[],
    this.icones = const <String, AppIcon>{},
  });

  /// La forme de la question.
  final FormeQuestion forme;

  /// L'icone de la question (recapitulatif).
  final AppIcon? icone;

  /// Les icones secondaires des cartes d'une question a peu de choix.
  final List<AppIcon> autour;

  /// L'icone de chaque option, pour une question a peu de choix.
  final Map<String, AppIcon> icones;
}

/// Les tranches d'age d'enfants du champ `publics` (6 a 17 ans).
const Set<String> tranchesEnfants = <String>{'6_9', '10_13', '14_17'};

/// La tranche des adultes du champ `publics` (18 ans et plus).
const String trancheAdultes = 'adultes';

/// La duree des cours dont les heures se declarent, d'apres les tranches d'age
/// que la personne enseigne ([publics], la reponse brute du champ `publics`) :
/// 90 minutes des qu'une classe d'adultes est possible (chaque heure touchee
/// par la seance se declare : l'heure suivante aussi), 60 minutes sinon.
int dureeDeclareeDe(Object? publics) =>
    publics is List && publics.contains(trancheAdultes)
    ? dureeSeanceAdulteMinutes
    : dureeSeanceEnfantMinutes;

/// Les langues proposees d'emblee en cartes, dans l'ordre : celles du public
/// de l'academie (decision du directeur du 22/10/2026) ; les autres se
/// trouvent par la recherche. Poular, peul et fulfulde sont une seule langue
/// (`poular`). CANDIDATS-FLUX (06/11/2026, PLAN-LOTS 22 m, consigne du
/// directeur qui remplace celle du 22/10) : malinke et mandinka sont une seule
/// langue (`man`, « Malinke (mandinka) ») et `mnk` n'est plus propose ;
/// l'arabe et le portugais sont des langues de cours.
const List<String> languesDuPublic = <String>[
  'poular',
  'man',
  'sus',
  'sw',
  'ha',
  'wo',
  'bm',
  'snk',
  'francais',
  'english',
  'ar',
  'pt',
  'autre',
];

/// Les codes de langue qui ne sont plus proposes : `mnk` est ramene a `man`
/// (CANDIDATS-FLUX, 06/11/2026).
const Set<String> languesRetirees = <String>{'mnk'};

/// PE-B1 (directeur, 19/11/2026, plan du parcours A10 et §12.1) : la
/// memorisation se dit « tout le Coran », « rien pour l'instant », ou un
/// nombre exact de juz, de 1 a 29.
///
/// Le format stocke : le meme champ `niveauMemorisationDeclare`, qui garde
/// ses quatre anciens codes ([memorisationAnciennes] : `moins_10_juz` et
/// `de_10_a_29_juz` ne sont plus proposes mais restent valides et se
/// relisent) et accepte `juz_1` a `juz_29` (migration
/// `20261130920000_juz_nombre_exact.sql`, qui les propose et les permet).
const String champMemorisation = 'niveauMemorisationDeclare';

/// Tout le Coran.
const String memorisationTout = 'coran_entier';

/// Rien pour l'instant.
const String memorisationRien = 'aucune';

/// Le plus grand nombre exact de juz (30 juz, c'est [memorisationTout]).
const int juzMaximum = 29;

/// Les anciennes reponses en tranche, qui ne sont plus proposees.
const Set<String> memorisationAnciennes = <String>{
  'moins_10_juz',
  'de_10_a_29_juz',
};

/// Le code d'un nombre exact de juz : `juz_12`.
String codeJuz(int n) => 'juz_$n';

/// Le nombre exact de juz de [code] (`juz_12` : 12), ou `null` pour tout
/// autre code (ancien ou inconnu). `juz_0`, `juz_30` et `juz_01` ne se lisent
/// pas : le serveur les refuse.
int? juzExact(String? code) {
  final RegExpMatch? m = RegExp(r'^juz_([1-9]|1[0-9]|2[0-9])$')
      .firstMatch(code ?? '');
  return m == null ? null : int.parse(m.group(1)!);
}

/// PE-B1 (directeur, 19/11/2026, Q3) : les riwayat se choisissent par lecteur.
/// Les dix lecteurs, dans l'ordre de la tradition, avec leurs deux riwayat
/// (les codes du questionnaire). Les sept premiers sont « les sept ».
const List<({String lecteur, List<String> riwayat})> lecteursRiwayat =
    <({String lecteur, List<String> riwayat})>[
      (lecteur: 'nafi', riwayat: <String>['qalun', 'warsh']),
      (lecteur: 'ibnKathir', riwayat: <String>['al_bazzi', 'qunbul']),
      (lecteur: 'abuAmr', riwayat: <String>['ad_duri_abi_amr', 'as_susi']),
      (lecteur: 'ibnAmir', riwayat: <String>['hisham', 'ibn_dhakwan']),
      (lecteur: 'asim', riwayat: <String>['shuba', 'hafs']),
      (lecteur: 'hamza', riwayat: <String>['khalaf_an_hamza', 'khallad']),
      (
        lecteur: 'kisai',
        riwayat: <String>['abu_al_harith', 'ad_duri_al_kisai'],
      ),
      (lecteur: 'abuJafar', riwayat: <String>['ibn_wardan', 'ibn_jammaz']),
      (lecteur: 'yaqub', riwayat: <String>['ruways', 'rawh']),
      (lecteur: 'khalaf', riwayat: <String>['ishaq', 'idris']),
    ];

/// Les quatorze riwayat des sept lecteurs.
final Set<String> riwayatSept = <String>{
  for (final l in lecteursRiwayat.take(7)) ...l.riwayat,
};

/// Les vingt riwayat des dix lecteurs.
final Set<String> riwayatDix = <String>{
  for (final l in lecteursRiwayat) ...l.riwayat,
};

/// Les quatre facons de repondre a la question des riwayat.
enum ModeRiwayat {
  /// Les dix lectures : les vingt riwayat.
  dix,

  /// Les sept lectures : les quatorze riwayat des sept lecteurs.
  sept,

  /// Une seule riwaya, choisie dans la liste.
  une,

  /// Quelques riwayat, choisies lecteur par lecteur.
  quelques,
}

/// Le mode que montre une reponse deja enregistree : les vingt codes, les
/// dix lectures ; les quatorze des sept lecteurs, les sept ; un seul code,
/// une seule riwaya ; plusieurs, quelques-unes ; rien, `null`. Une ancienne
/// reponse (avant ce lot) se relit ainsi sans perte : le format n'a pas
/// change.
ModeRiwayat? modeDesRiwayat(Set<String> codes) {
  if (codes.isEmpty) return null;
  if (codes.length == riwayatDix.length && codes.containsAll(riwayatDix)) {
    return ModeRiwayat.dix;
  }
  if (codes.length == riwayatSept.length && codes.containsAll(riwayatSept)) {
    return ModeRiwayat.sept;
  }
  return codes.length == 1 ? ModeRiwayat.une : ModeRiwayat.quelques;
}

/// Les champs connus de `salle-examen-1`, par code.
const Map<String, ModeleQuestion> modelesQuestions = <String, ModeleQuestion>{
  'langueMaternelle': ModeleQuestion(
    FormeQuestion.langue,
    icone: AppIcons.discussion,
  ),
  'languesExplication': ModeleQuestion(
    FormeQuestion.langues,
    icone: AppIcons.discussion,
  ),
  'niveauMemorisationDeclare': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.coran,
    icones: <String, AppIcon>{
      'aucune': AppIcons.lecon,
      'moins_10_juz': AppIcons.livreOuvert,
      'de_10_a_29_juz': AppIcons.reciter,
      'coran_entier': AppIcons.coran,
    },
  ),
  'niveauLectureTajwid': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.reciter,
    icones: <String, AppIcon>{
      'lecture_sans_regles_tajwid': AppIcons.lecon,
      'tajwid_applique': AppIcons.reciter,
      'tajwid_enseigne': AppIcons.classes,
    },
  ),
  'riwayat': ModeleQuestion(FormeQuestion.riwayat, icone: AppIcons.livreOuvert),
  'ijazaPresentable': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.etoile,
    icones: <String, AppIcon>{
      'oui': AppIcons.etoile,
      'pret_test': AppIcons.reciter,
      'non': AppIcons.lecon,
    },
  ),
  'experienceDebutants': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.eleves,
    icones: <String, AppIcon>{'oui': AppIcons.eleves, 'non': AppIcons.profil},
  ),
  'disponibilitesDeclarees': ModeleQuestion(
    FormeQuestion.creneaux,
    icone: AppIcons.disponibilites,
  ),
  'fuseauIana': ModeleQuestion(FormeQuestion.fuseau, icone: AppIcons.horloge),
  'classesSouhaitees': ModeleQuestion(
    FormeQuestion.classes,
    icone: AppIcons.classes,
  ),
  'debutPossible': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.echeance,
    icones: <String, AppIcon>{
      'immediat': AppIcons.horloge,
      'mois_prochain': AppIcons.echeance,
      'sous_3_mois': AppIcons.disponibilites,
      'inconnu': AppIcons.info,
    },
  ),
  'publics': ModeleQuestion(
    FormeQuestion.choixMultiple,
    icone: AppIcons.eleves,
    icones: <String, AppIcon>{
      '6_9': AppIcons.eleves,
      '10_13': AppIcons.lecon,
      '14_17': AppIcons.livreOuvert,
      'adultes': AppIcons.profil,
    },
  ),
  'paysResidence': ModeleQuestion(FormeQuestion.pays, icone: AppIcons.maison),
  'paysVersement': ModeleQuestion(
    FormeQuestion.pays,
    icone: AppIcons.paiements,
  ),
  'compteBancaire': ModeleQuestion(
    FormeQuestion.ouiNon,
    icone: AppIcons.paiements,
    icones: <String, AppIcon>{
      'oui': AppIcons.paiements,
      'non': AppIcons.appareil,
    },
  ),
  'operateurs': ModeleQuestion(
    FormeQuestion.operateurs,
    icone: AppIcons.appareil,
  ),
  'moyensAccessibles': ModeleQuestion(
    FormeQuestion.moyensAccessibles,
    icone: AppIcons.appareil,
  ),
};

/// Vrai quand cette version de l'application sait afficher chaque champ du
/// questionnaire, avec la forme que son type annonce.
bool questionnaireReconnu(Questionnaire q) {
  for (final ChampQuestionnaire c in q.champs) {
    final ModeleQuestion? m = modelesQuestions[c.code];
    if (m == null || !_formeCompatible(m.forme, c.type)) {
      return false;
    }
  }
  return true;
}

bool _formeCompatible(FormeQuestion forme, TypeChamp type) => switch (forme) {
  FormeQuestion.choix ||
  FormeQuestion.langue ||
  FormeQuestion.pays ||
  FormeQuestion.fuseau ||
  FormeQuestion.classes => type == TypeChamp.choix,
  FormeQuestion.choixMultiple ||
  FormeQuestion.langues ||
  FormeQuestion.riwayat ||
  FormeQuestion.operateurs ||
  FormeQuestion.moyensAccessibles => type == TypeChamp.choixMultiple,
  FormeQuestion.ouiNon => type == TypeChamp.booleen,
  FormeQuestion.creneaux => type == TypeChamp.creneaux,
};
