// Les textes du parcours du candidat, retrouves par le code du serveur.
//
// Le serveur rend des codes (`hafs`, `coran_entier`, `orange_money`...), jamais
// des libelles. Chaque code a ses textes dans `assets/i18n`, sous
// `recrutement.parcours`, en francais et en arabe. Un code sans traduction
// rend `null` : l'ecran ne l'affiche pas, il ne montre jamais un code brut
// (CONS section 9) ; un test verifie que chaque code de `salle-examen-1` a
// ses textes dans les deux langues.
library;

import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';

/// Un texte de `recrutement.parcours`, ou `null` s'il manque.
String? texteParcours(String chemin) {
  final Object? valeur = t.$meta.getTranslation('recrutement.parcours.$chemin');
  return valeur is String && valeur.isNotEmpty ? valeur : null;
}

/// Les textes d'une option de choix.
class TextesOption {
  /// Cree les textes.
  const TextesOption({
    required this.libelle,
    this.description,
    this.explication,
    this.exemple,
  });

  /// Le titre de la carte.
  final String libelle;

  /// Ce que c'est.
  final String? description;

  /// Ce que ce choix entraine.
  final String? explication;

  /// Un cas concret, sans le « Par exemple » que la carte ajoute.
  final String? exemple;
}

/// La cle i18n d'un code d'option. slang renomme une cle qui commence par un
/// chiffre (`6_9` devient `k69`, ce que rien ne lie au code) : les tranches
/// d'age du public s'ecrivent donc `o_6_9`, `o_10_13`, `o_14_17`.
String cleOption(String code) =>
    code.startsWith(RegExp(r'\d')) ? 'o_$code' : code;

/// Les textes de l'option [option] du champ [champ], ou `null` quand le libelle
/// manque.
TextesOption? textesOption(String champ, String option) {
  final String cle = cleOption(option);
  final String? libelle = texteParcours('q.$champ.options.$cle.libelle');
  if (libelle == null) {
    return null;
  }
  return TextesOption(
    libelle: libelle,
    description: texteParcours('q.$champ.options.$cle.description'),
    explication: texteParcours('q.$champ.options.$cle.explication'),
    exemple: texteParcours('q.$champ.options.$cle.exemple'),
  );
}

/// La question posee par le champ [champ].
String? titreQuestion(String champ) => texteParcours('q.$champ.titre');

/// L'explication de la question posee par le champ [champ].
String? explicationQuestion(String champ) =>
    texteParcours('q.$champ.explication');

/// Le nom court d'un champ, pour le recapitulatif.
String? nomCourtQuestion(String champ) => texteParcours('q.$champ.court');

/// Le nom d'une langue par son code, ou `null`. Un nom propre suit la langue
/// de l'interface ; en arabe il reste dans la phrase arabe.
String? nomDeLangue(String code) => texteParcours('langues.$code');

/// Le nom d'un pays par son code ISO (jamais le code lui-meme : un code
/// inconnu rend `null`).
String? nomDePaysConnu(String code) => paysDuCode(code)?.nom;

/// La ville d'un fuseau IANA, dans la langue de l'interface.
String nomDeLieu(String iana) => villeDuFuseauLibelle(iana);

/// Le nom d'un jour ISO (1 pour lundi), avec sa majuscule.
String nomDeJour(int jour) {
  final String nom = t.disponibilites.joursLongs[jour - 1];
  return nom.isEmpty ? nom : nom[0].toUpperCase() + nom.substring(1);
}

/// Une heure entiere : « 18 h » (« 18:00 » en arabe), insecable.
String libelleHeure(int heure) =>
    LibellesGroupe.insecable(t.recrutement.parcours.creneaux.heure(h: heure));

/// Un instant de la journee, en minutes depuis minuit : « 19 h 30 ». Au-dela de
/// 24 h, c'est le lendemain (un cours qui passe minuit finit a « 0 h 30 »).
String libelleInstant(int minutes) {
  final int m = minutes % (heuresParJour * 60);
  final int heure = m ~/ 60;
  final int reste = m % 60;
  final r = t.recrutement.parcours.creneaux;
  return LibellesGroupe.insecable(
    reste == 0
        ? r.heure(h: heure)
        : r.heureMinutes(h: heure, m: reste.toString().padLeft(2, '0')),
  );
}

/// Une duree en minutes : « 1 h », « 1 h 30 », « 4 h 30 ».
String libelleDuree(int minutes) => libelleInstant(minutes);

/// « de 18 h à 19 h 30 », pour un cours.
String libelleIntervalle(IntervalleCours i) => t.recrutement.parcours.creneaux
    .intervalle(debut: libelleInstant(i.debut), fin: libelleInstant(i.fin));

/// Plusieurs intervalles, separes par une virgule : « de 9 h à 10 h, de 18 h à
/// 21 h 30 ».
String libelleIntervalles(Iterable<IntervalleCours> intervalles) => intervalles
    .map(libelleIntervalle)
    .join(t.recrutement.parcours.creneaux.separateurListe);

/// Des heures de debut separees par une virgule : « 18 h, 19 h, 20 h ».
String libelleHeures(Iterable<int> heures) => heures
    .map(libelleHeure)
    .join(t.recrutement.parcours.creneaux.separateurListe);

/// Les heures d'un moment de la journee, pour les puces : `nuit` (0 a 5 h),
/// `matin` (6 a 11 h), `apresMidi` (12 a 17 h), `soir` (18 a 23 h).
const List<({String code, int de, int a})> momentsDeLaJournee =
    <({String code, int de, int a})>[
      (code: 'nuit', de: 0, a: 5),
      (code: 'matin', de: 6, a: 11),
      (code: 'apresMidi', de: 12, a: 17),
      (code: 'soir', de: 18, a: 23),
    ];

/// Le titre d'un moment de la journee (« Le soir, de 18 h à 23 h »).
String titreMoment(String code) =>
    texteParcours('creneaux.moments.$code') ?? '';

/// La region du monde d'un fuseau IANA (`Africa/Dakar` donne « Afrique »), ou
/// `null` pour un identifiant sans region connue.
String? regionDuFuseau(String iana) {
  final String region = iana.split('/').first;
  return texteParcours('fuseau.regions.$region');
}

/// Une heure « HH:MM » isolee pour rester a sa place dans une phrase arabe.
String heureIsolee(String heure) => isolerSens(heure);
