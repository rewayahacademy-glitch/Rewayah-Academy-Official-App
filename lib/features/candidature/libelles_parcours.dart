// Les textes du parcours du candidat, retrouves par le code du serveur.
//
// Le serveur rend des codes (`hafs`, `coran_entier`, `orange_money`...), jamais
// des libelles. Chaque code a ses textes dans `assets/i18n`, sous
// `recrutement.parcours`, en francais et en arabe. Un code sans traduction
// rend `null` : l'ecran ne l'affiche pas, il ne montre jamais un code brut
// (CONS section 9) ; un test verifie que chaque code de `salle-examen-1` a
// ses textes dans les deux langues.
library;

import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';

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

/// Les textes de l'option [option] du champ [champ], ou `null` quand le libelle
/// manque.
TextesOption? textesOption(String champ, String option) {
  final String? libelle = texteParcours('q.$champ.options.$option.libelle');
  if (libelle == null) {
    return null;
  }
  return TextesOption(
    libelle: libelle,
    description: texteParcours('q.$champ.options.$option.description'),
    explication: texteParcours('q.$champ.options.$option.explication'),
    exemple: texteParcours('q.$champ.options.$option.exemple'),
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

/// Le nom d'une plage de la journee (0 a 5).
String nomDePlage(int plage) => texteParcours('creneaux.plage$plage') ?? '';

/// La region du monde d'un fuseau IANA (`Africa/Dakar` donne « Afrique »), ou
/// `null` pour un identifiant sans region connue.
String? regionDuFuseau(String iana) {
  final String region = iana.split('/').first;
  return texteParcours('fuseau.regions.$region');
}

/// Une heure « HH:MM » isolee pour rester a sa place dans une phrase arabe.
String heureIsolee(String heure) => isolerSens(heure);
