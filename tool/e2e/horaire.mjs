// Choix d'un horaire de test « dans l'heure qui vient ».
// L'ecran « Nouvelle classe » propose des heures pleines de 6 h a 21 h, dans le
// fuseau de l'enseignant. Pour qu'un passage marche a toute heure UTC, on
// choisit le fuseau de l'enseignant de test (donnee de test, base locale) tel
// que la prochaine heure pleine locale tombe dans [delaiMin, delaiMax] minutes.
const FUSEAUX = [
  'Pacific/Honolulu', 'America/Anchorage', 'America/Los_Angeles', 'America/Denver',
  'America/Chicago', 'America/New_York', 'America/Halifax', 'America/St_Johns',
  'America/Sao_Paulo', 'Atlantic/Azores', 'Europe/London', 'Europe/Paris',
  'Europe/Athens', 'Europe/Moscow', 'Asia/Tehran', 'Asia/Dubai', 'Asia/Kabul',
  'Asia/Karachi', 'Asia/Kolkata', 'Asia/Kathmandu', 'Asia/Dhaka', 'Asia/Yangon',
  'Asia/Bangkok', 'Asia/Singapore', 'Asia/Tokyo', 'Australia/Adelaide',
  'Australia/Sydney', 'Pacific/Noumea', 'Pacific/Auckland', 'Pacific/Chatham',
];
const JOURS = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

function local(fuseau, date) {
  const f = new Intl.DateTimeFormat('en-GB', { timeZone: fuseau, hour12: false,
    weekday: 'short', hour: '2-digit', minute: '2-digit' }).formatToParts(date);
  const v = Object.fromEntries(f.map((p) => [p.type, p.value]));
  const jour = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(v.weekday);
  return { jour, heure: Number(v.hour) % 24, minute: Number(v.minute) };
}

/// Rend { fuseau, jour (libelle), heure, debut (Date UTC), attente (min) }.
export function horaireProche({ delaiMin = 3, delaiMax = 20, maintenant = new Date(), pasAvant = null, fuseaux = FUSEAUX } = {}) {
  let meilleur = null;
  for (const fuseau of fuseaux) {
    const l = local(fuseau, maintenant);
    const attente = 60 - l.minute - maintenant.getUTCSeconds() / 60;
    const prochain = new Date(maintenant.getTime() + attente * 60000);
    const lp = local(fuseau, prochain);
    if (lp.minute !== 0 || lp.heure < 6 || lp.heure > 21) continue;
    if (attente < delaiMin || attente > delaiMax) continue;
    if (pasAvant && prochain < pasAvant) continue;
    if (!meilleur || attente < meilleur.attente) {
      meilleur = { fuseau, jour: JOURS[lp.jour], jourIndex: lp.jour, heure: lp.heure,
        debut: prochain, attente: Math.round(attente) };
    }
  }
  return meilleur;
}

/// Un autre jour de la semaine que `jourIndex` (second creneau).
export function autreJour(jourIndex) {
  return JOURS[(jourIndex + 2) % 7];
}
