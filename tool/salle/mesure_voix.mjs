// Banc de la salle : « l'eleve comprend-il chaque mot de l'enseignant ? », et
// l'inverse. Une vraie seance (vraie application, pile LOCALE), un enseignant
// sur ordinateur, un eleve au telephone ; l'un recite (son micro factice lit
// une recitation), l'autre ecoute sous un reseau abime ; on enregistre ce que
// l'auditeur entend et on le note (tool/salle/mesure_audio.py).
//
// Usage :
//   node tool/salle/mesure_voix.mjs <etiquette> [--sens=ens-eleve|eleve-ens] [--profils=a,b,c] [--camera]
// Variables : BANC_RECITATION (WAV mono 48 kHz, defaut /opt/banc-audio/ref/recitation.wav),
//             BANC_SORTIE (dossier des enregistrements et du tableau), E2E_APP (application servie).
// Le reseau abime est celui de l'ELEVE (c'est lui qui a la mauvaise connexion),
// dans les deux sens : les pertes touchent ce qu'il recoit et ce qu'il envoie.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { participant, connecter, appuyer, reseau, ecouter, bilanAudio } from './banc.mjs';
import { amorcerClasse } from './amorce.mjs';
import { COMPTES } from '../e2e/commun.mjs';

const arg = (nom, defaut) => (process.argv.find((a) => a.startsWith(`--${nom}=`)) ?? `=${defaut}`).split('=')[1];
const etiquette = process.argv[2] ?? 'essai';
const sens = arg('sens', 'ens-eleve');
const avecCamera = process.argv.includes('--camera');
const RECITATION = process.env.BANC_RECITATION ?? '/opt/banc-audio/ref/recitation.wav';
const SORTIE = process.env.BANC_SORTIE ?? `/tmp/banc-salle/${etiquette}`;
const PYTHON = process.env.BANC_PYTHON ?? '/opt/banc-audio/venv/bin/python';
const DUREE = Number(arg('duree', '70'));
// `--tampon=250` : le tampon de gigue vise chez l'auditeur, en ms (0 : celui du navigateur).
const TAMPON = Number(arg('tampon', '0'));
const SUFFIXE = `${avecCamera ? '_camera' : ''}${TAMPON ? `_tampon${TAMPON}` : ''}`;

// Les memes reglages dans les deux sens du lien de l'eleve.
// Chaque essai avec pertes porte aussi une latence ordinaire (100 ms aller-retour,
// un peu de gigue) : sur un lien sans latence, le serveur a le temps de renvoyer
// chaque paquet perdu, ce qu'un vrai reseau ne permet pas, et la mesure flatterait.
const LIEN = { delai: 50, gigue: 10 };
export const PROFILS = {
  parfait: {},
  'pertes-10': { ...LIEN, perte: 0.10 },
  'pertes-10-rafales': { ...LIEN, perte: 0.10, rafale: 3 },
  'pertes-20': { ...LIEN, perte: 0.20 },
  'pertes-20-rafales': { ...LIEN, perte: 0.20, rafale: 3 },
  'pertes-30-rafales': { ...LIEN, perte: 0.30, rafale: 4 },
  'latence-300': { delai: 150, gigue: 40 }, // 150 ms par sens : 300 ms aller-retour
  // Mobile 3G moyen : 384 kbit/s en reception, 128 en emission, 300 ms aller-retour, 2 % de pertes.
  '3g': { descendant: { debit: 384, delai: 150, gigue: 40, perte: 0.02 }, montant: { debit: 128, delai: 150, gigue: 40, perte: 0.02 } },
};
/// Note les enregistrements de `resultats` et complete chaque ligne.
export function noter(sortie, sens, resultats, dire = console.log) {
  const notes = execFileSync(PYTHON, [path.join(import.meta.dirname, 'mesure_audio.py'), RECITATION, ...resultats.map((r) => r.fichier)],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 1 << 26 }).trim().split('\n').map((l) => JSON.parse(l));
  for (const r of resultats) {
    const n = notes.find((x) => x.fichier === r.fichier) ?? {};
    Object.assign(r, { estoi: n.estoi, estoi_pire: n.estoi_pire, trous: n.trous, wer: n.wer, mots: n.mots_original, erreur: n.erreur });
    dire(`${sens} ${r.profil} : mots perdus ou changes ${n.wer} ; ESTOI ${n.estoi} (pire ${n.estoi_pire}) ; son reconstruit ${r.audio[0]?.dissimule} ; pertes ${r.audio[0]?.pertes} ; debit ${r.audio[0]?.debitKbps} kbit/s`);
  }
}

const choisis = arg('profils', Object.keys(PROFILS).join(',')).split(',');

fs.mkdirSync(SORTIE, { recursive: true });
const dire = (m) => { console.log(m); fs.appendFileSync(path.join(SORTIE, 'journal.txt'), `${m}\n`); };
const c = amorcerClasse({ n: 1, etiquette: `voix ${etiquette}` });
const ens = await participant('enseignant', { audio: RECITATION });
const eleve = await participant('eleve', { audio: RECITATION, telephone: true });
const resultats = [];
try {
  await connecter(ens, COMPTES.enseignant);
  if (!(await appuyer(ens, /^Rejoindre la salle/, { delai: 25000, pause: 9000 }))) throw new Error(`enseignant : pas de « Rejoindre la salle » ; ${await ens.lus(20)}`);
  await connecter(eleve, c.eleves[0].courriel);
  if (!(await appuyer(eleve, /^Rejoindre/, { delai: 25000, pause: 9000 }))) throw new Error(`eleve : pas de « Rejoindre » ; ${await eleve.lus(20)}`);
  const [parleur, auditeur] = sens === 'ens-eleve' ? [ens, eleve] : [eleve, ens];
  if (!(await appuyer(parleur, /^Ouvrir le micro/, { pause: 3000 }))) throw new Error(`${parleur.nom} : pas de « Ouvrir le micro » ; ${await parleur.lus(40)}`);
  if (avecCamera) dire(`camera de l'enseignant : ${await appuyer(ens, /^Allumer la caméra/, { pause: 3000 })}`);
  await auditeur.page.waitForTimeout(6000);
  if (TAMPON) dire(`tampon de gigue vise : ${TAMPON} ms sur ${await auditeur.page.evaluate((ms) => window.__tampon(ms), TAMPON)} recepteur(s) audio`);
  const emis = (await parleur.stats()).emis.filter((x) => x.genre === 'audio');
  dire(`== ${etiquette} ; sens ${sens} ; camera ${avecCamera} ; ${new Date().toISOString()}`);
  dire(`emission audio : ${JSON.stringify(emis.map((x) => ({ codec: x.codec, fmtp: x.fmtp, cible: x.cible })))}`);
  dire(`negociation audio chez l'auditeur : ${(await auditeur.page.evaluate(() => window.__sdpAudio())).join(' | ')}`);

  for (const nom of choisis) {
    const p = PROFILS[nom];
    const reglage = p.montant || p.descendant ? p : { montant: p, descendant: p };
    const ports = await reseau(eleve, reglage);
    await auditeur.page.waitForTimeout(8000); // le temps que l'emetteur et le tampon s'adaptent
    const avant = await auditeur.stats();
    const fichier = path.join(SORTIE, `${sens}${SUFFIXE}_${nom}.webm`);
    await ecouter(auditeur, DUREE, fichier);
    const apres = await auditeur.stats();
    const video = apres.recu.filter((x) => x.genre === 'video').map((x) => `${x.largeur}x${x.hauteur}@${x.ips ?? 0}`).join(',');
    await reseau(eleve, {});
    const ligne = { profil: nom, fichier, ports: ports.length, audio: bilanAudio(avant, apres), video };
    resultats.push(ligne);
    dire(JSON.stringify(ligne));
    await auditeur.page.waitForTimeout(4000);
  }
  // La notation, en un lot : le modele de reconnaissance n'est charge qu'une fois.
  // `--sans-note` : on enregistre seulement ; `tool/salle/noter.mjs` notera plus tard.
  await ens.fermer(); await eleve.fermer();
  if (!process.argv.includes('--sans-note')) noter(SORTIE, sens, resultats, dire);
} catch (e) {
  dire(`ECHEC : ${String(e.message ?? e).slice(0, 500)}`);
} finally {
  fs.writeFileSync(path.join(SORTIE, `${sens}${SUFFIXE}.json`), JSON.stringify({ etiquette, sens, camera: avecCamera, tampon: TAMPON, date: new Date().toISOString(), resultats }, null, 1));
  await ens.fermer().catch(() => {}); await eleve.fermer().catch(() => {});
}
