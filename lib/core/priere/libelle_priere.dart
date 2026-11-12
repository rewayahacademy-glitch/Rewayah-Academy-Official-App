import '../domain/enums.dart';
import '../i18n/strings.g.dart';

/// Le nom d'une priere, tel qu'il s'affiche.
///
/// Une seule correspondance pour toute l'application : `ENS-02` et `ELV-02`
/// nomment la meme interruption de la meme facon, sinon la transparence de
/// l'ADR-017 s'arrete au vocabulaire.
String libellePriere(Priere priere) => switch (priere) {
  Priere.fajr => t.priere.fajr,
  Priere.dhuhr => t.priere.dhuhr,
  Priere.asr => t.priere.asr,
  Priere.maghrib => t.priere.maghrib,
  Priere.isha => t.priere.isha,
};

/// Le nom d'une methode de calcul, tel qu'il s'affiche a la direction.
String libelleMethode(MethodeCalcul methode) => switch (methode) {
  MethodeCalcul.ligueMondiale => t.priere.methodes.muslim_world_league,
  MethodeCalcul.egypte => t.priere.methodes.egyptian,
  MethodeCalcul.karachi => t.priere.methodes.karachi,
  MethodeCalcul.ummAlQura => t.priere.methodes.umm_al_qura,
  MethodeCalcul.dubai => t.priere.methodes.dubai,
  MethodeCalcul.moonSighting => t.priere.methodes.moon_sighting_committee,
  MethodeCalcul.ameriqueDuNord => t.priere.methodes.north_america,
  MethodeCalcul.koweit => t.priere.methodes.kuwait,
  MethodeCalcul.qatar => t.priere.methodes.qatar,
  MethodeCalcul.singapour => t.priere.methodes.singapore,
  MethodeCalcul.teheran => t.priere.methodes.tehran,
  MethodeCalcul.turquie => t.priere.methodes.turkey,
};

/// Le nom d'une ecole pour l'Asr.
String libelleEcoleAsr(Madhab ecole) => switch (ecole) {
  Madhab.shafi => t.priere.ecoles.shafi,
  Madhab.hanafi => t.priere.ecoles.hanafi,
};
