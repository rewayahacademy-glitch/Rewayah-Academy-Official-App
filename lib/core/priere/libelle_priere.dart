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
