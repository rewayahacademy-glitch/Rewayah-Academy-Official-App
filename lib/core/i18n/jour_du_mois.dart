// Le numero du jour dans une date en toutes lettres (revue FI-VAGUE-R
// R8-05) : le francais ecrit « 1er novembre 2026 », jamais « 1 novembre
// 2026 » ; les autres jours restent en chiffres (« 2 novembre »). La forme du
// premier jour vient de la langue (`commun.dates.premierJour`).

import 'strings.g.dart';

/// Le jour [jour] du mois tel qu'il s'ecrit dans une date : « 1er » pour le
/// premier, le nombre sinon.
String jourDuMois(int jour) =>
    jour == 1 ? t.commun.dates.premierJour : jour.toString();
