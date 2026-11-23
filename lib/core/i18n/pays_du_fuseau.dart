import 'dart:ui' show Locale, PlatformDispatcher;

import 'indicatifs_telephoniques.dart';

/// Les fuseaux IANA courants des familles de l'academie, avec leur pays (ISO).
/// Une liste volontairement courte : un fuseau absent ne preremplit rien, la
/// personne choisit son pays elle-meme.
const Map<String, String> _paysParFuseau = <String, String>{
  'Europe/Paris': 'FR',
  'Europe/Brussels': 'BE',
  'Europe/Zurich': 'CH',
  'Europe/London': 'GB',
  'Europe/Luxembourg': 'LU',
  'Europe/Berlin': 'DE',
  'Europe/Madrid': 'ES',
  'Europe/Rome': 'IT',
  'Europe/Amsterdam': 'NL',
  'Europe/Lisbon': 'PT',
  'Europe/Istanbul': 'TR',
  'America/Toronto': 'CA',
  'America/Montreal': 'CA',
  'America/Vancouver': 'CA',
  'America/New_York': 'US',
  'America/Chicago': 'US',
  'America/Los_Angeles': 'US',
  'Africa/Casablanca': 'MA',
  'Africa/Algiers': 'DZ',
  'Africa/Tunis': 'TN',
  'Africa/Cairo': 'EG',
  'Africa/Dakar': 'SN',
  'Africa/Abidjan': 'CI',
  'Asia/Riyadh': 'SA',
  'Asia/Dubai': 'AE',
  'Asia/Qatar': 'QA',
  'Asia/Kuwait': 'KW',
  'Asia/Amman': 'JO',
  'Asia/Beirut': 'LB',
};

/// Le pays (ISO) a proposer pour l'indicatif du numero WhatsApp : celui de la
/// langue de l'appareil quand il porte un pays, sinon celui du [fuseau]. `null`
/// quand rien ne se lit : le champ attend alors le choix de la personne. Jamais
/// un pays sans indicatif connu.
String? paysPourIndicatif({String? fuseau, Locale? locale}) {
  final String? depuisLangue = (locale ?? PlatformDispatcher.instance.locale)
      .countryCode
      ?.toUpperCase();
  if (depuisLangue != null && indicatifDuPays(depuisLangue) != null) {
    return depuisLangue;
  }
  final String? depuisFuseau = _paysParFuseau[fuseau];
  return depuisFuseau != null && indicatifDuPays(depuisFuseau) != null
      ? depuisFuseau
      : null;
}
