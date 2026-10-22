// Ce que l'application sait afficher du questionnaire de la Salle d'examen :
// la forme de chaque champ, par son code (CAND-01).
//
// Le serveur rend des **codes**, jamais des libelles (`Questionnaire`) ; les
// textes viennent de `assets/i18n` (`recrutement.parcours.q.<code>`), en
// francais et en arabe. Un champ que cette version de l'application ne connait
// pas ne s'affiche pas a moitie : le parcours dit que l'etape n'est pas encore
// ouverte (`reconnu`), au lieu d'un code brut ou d'un champ sans texte.
library;

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

  /// La grille des plages de la semaine.
  creneaux,

  /// Le fuseau horaire : confirmation, puis recherche d'une ville.
  fuseau,

  /// Les moyens de paiement sur telephone confirmes dans le pays.
  operateurs,
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
      'coran_entier': AppIcons.coran,
      'ijaza_lecture_enseignement': AppIcons.etoile,
      'plus_de_10_juz': AppIcons.livreOuvert,
      'moins_de_10_juz': AppIcons.lecon,
      'bonne_lecture_sans_memorisation': AppIcons.reciter,
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
    icones: <String, AppIcon>{'oui': AppIcons.etoile, 'non': AppIcons.lecon},
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
  'heuresParSemaine': ModeleQuestion(
    FormeQuestion.choix,
    icone: AppIcons.horloge,
    icones: <String, AppIcon>{
      'moins_de_3': AppIcons.horloge,
      'de_3_a_5': AppIcons.classes,
      'de_6_a_10': AppIcons.classes,
      'plus_de_10': AppIcons.classes,
    },
    autour: <AppIcon>[AppIcons.horloge],
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
      'enfant': AppIcons.eleves,
      'adulte': AppIcons.profil,
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
  FormeQuestion.fuseau => type == TypeChamp.choix,
  FormeQuestion.choixMultiple ||
  FormeQuestion.langues ||
  FormeQuestion.riwayat ||
  FormeQuestion.operateurs => type == TypeChamp.choixMultiple,
  FormeQuestion.ouiNon => type == TypeChamp.booleen,
  FormeQuestion.creneaux => type == TypeChamp.creneaux,
};
