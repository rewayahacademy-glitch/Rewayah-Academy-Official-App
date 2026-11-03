// COURRIELS-UX (pilote et garde-cap, 03/11/2026) : l'heure d'un e-mail se dit
// avec la VILLE de son fuseau, la meme que dans l'application (UX-030), jamais
// un nom de region ni le code IANA.
//
// Source : la table `commun.fuseaux` des fichiers `assets/i18n/fr.i18n.json` et
// `assets/i18n/ar.i18n.json`, lue par `lib/core/i18n/villes_fuseau.dart`
// (decision AR-FUSEAU-VILLE du 12/10/2026, sources dans
// `tool/libelles_sources.json`). Recopiee telle quelle : la fonction Edge ne lit
// pas les fichiers de l'application. Le test `courriel_test.ts` verifie que les
// deux tables restent egales. Hors de la table, comme dans l'application : le
// dernier segment de l'identifiant IANA (« Los Angeles »), isole (U+2068 ...
// U+2069) en arabe. L'application n'a que le francais et l'arabe : l'anglais,
// l'espagnol et le portugais reprennent les noms du francais (noms IANA lisibles).

export const VILLES_FUSEAU_FR: Record<string, string> = {
  'Europe/Paris': 'Paris',
  'Africa/Conakry': 'Conakry',
  'America/Toronto': 'Toronto',
  'Europe/London': 'London',
  'Asia/Riyadh': 'Riyadh',
  'America/Los_Angeles': 'Los Angeles',
  'Africa/Lagos': 'Lagos',
  'Africa/Abidjan': 'Abidjan',
  'America/New_York': 'New York',
  'Africa/Casablanca': 'Casablanca',
  'Asia/Tokyo': 'Tokyo',
  'America/Argentina/Buenos_Aires': 'Buenos Aires',
  'Africa/Dakar': 'Dakar',
  'Africa/Bamako': 'Bamako',
  'Africa/Nouakchott': 'Nouakchott',
  'Europe/Brussels': 'Brussels',
}

export const VILLES_FUSEAU_AR: Record<string, string> = {
  'Europe/Paris': 'باريس',
  'Africa/Conakry': 'كوناكري',
  'America/Toronto': 'تورنتو',
  'Europe/London': 'لندن',
  'Asia/Riyadh': 'الرياض',
  'America/Los_Angeles': 'لوس أنجلوس',
  'Africa/Lagos': 'لاغوس',
  'Africa/Abidjan': 'أبيدجان',
  'America/New_York': 'نيويورك',
  'Africa/Casablanca': 'الدار البيضاء',
  'Asia/Tokyo': 'طوكيو',
  'America/Argentina/Buenos_Aires': 'بوينس آيرس',
  'Africa/Dakar': 'داكار',
  'Africa/Bamako': 'باماكو',
  'Africa/Nouakchott': 'نواكشوط',
  'Europe/Brussels': 'بروكسل',
}

/// La ville du fuseau `iana` dans la langue `langue` (code court : fr, ar, en,
/// es, pt) ; nul pour un identifiant vide ou mal forme.
export function villeDuFuseau(iana: unknown, langue: string): string | null {
  if (typeof iana !== 'string' || !/^[A-Za-z_]+(\/[A-Za-z0-9_+-]+)*$/.test(iana)) return null
  const table = langue === 'ar' ? VILLES_FUSEAU_AR : VILLES_FUSEAU_FR
  const connue = table[iana]
  if (connue) return connue
  const nom = iana.split('/').pop()!.replaceAll('_', ' ').trim()
  if (!nom) return null
  return langue === 'ar' ? `\u2068${nom}\u2069` : nom
}
