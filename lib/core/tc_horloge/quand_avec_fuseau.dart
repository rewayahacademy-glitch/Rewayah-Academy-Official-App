// PARCOURS-BOUT-EN-BOUT, partie B3 (directeur, 22/11/2026 : « bien travailler
// les fuseaux horaires, sinon ce sera dangereux ») : une date montree a une
// famille dit toujours dans quel fuseau elle se lit.
//
// L'heure de la personne d'abord, avec le nom de son fuseau (sa ville, ou
// « heure de cet appareil » quand elle n'a pas choisi de ville), puis, en
// second, l'heure de La Mecque quand elle differe (regle des mots).

import '../../features/suivi_demandes/libelles_suivi_demandes.dart'
    show deFuseau, hhmmDemande, jourDateDemande;
import '../i18n/strings.g.dart';
import 'mon_horloge.dart';

/// « Lundi 23 novembre à 18:00, heure de Paris · Heure de La Mecque : 20:00 »
/// pour l'instant [instantUtc] (UTC). Sans ville choisie : « Lundi 23
/// novembre, 18:00 (heure de cet appareil) ».
String quandAvecFuseau(DateTime instantUtc) {
  final DateTime chez = chezMoi(instantUtc);
  final String date = jourDateDemande(chez);
  final String heure = hhmmDemande(chez.hour, chez.minute);
  final String? iana = fuseauChezMoi(instantUtc);
  final String base = iana == null
      ? '$date, $heure (${t.lieu.heureAppareil.toLowerCase()})'
      : t.suiviDemandes.debutValeur(
          date: date,
          heure: heure,
          deVille: deFuseau(iana, cle: 'suiviDemandes.debutValeur'),
        );
  final String? mecque = heureMecqueSiDifferente(instantUtc);
  return mecque == null
      ? base
      : '$base · ${t.tc.groupe.horloges.mecqueEnSecond(heure: mecque)}';
}
