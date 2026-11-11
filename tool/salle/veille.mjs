// Banc de la salle : l'ecran qui s'eteint. Un enseignant et un eleve au
// telephone dans la VRAIE application ; la page de l'eleve est gelee comme le
// fait un telephone qui se verrouille (protocole de Chromium :
// Page.setWebLifecycleState « frozen »), puis reveillee.
//
// Ce que le script mesure, sans juger a la place d'un humain :
//  - l'application demande-t-elle a l'ecran de rester allume (Screen Wake Lock) ?
//  - au reveil, sans aucun geste : en combien de secondes la voix de
//    l'enseignant revient, le micro de l'eleve est-il de nouveau ouvert et
//    emet-il, un bouton « reprendre » attend-il la personne ?
//
// Limite dite : un gel de page n'est pas un vrai telephone. Android et iOS
// decident eux-memes de ce qu'ils coupent ; seul un essai sur un vrai
// telephone le prouve (docs/current/salle/ECRAN-ET-VEILLE.md).
//
// Usage : node tool/salle/veille.mjs [--gels=20,75] [--dossier=veille]
import fs from 'node:fs';
import path from 'node:path';
import { participant, connecter, appuyer } from './banc.mjs';
import { amorcerClasse } from './amorce.mjs';
import { COMPTES, DEPOT, alleger, libelles } from '../e2e/commun.mjs';

const arg = (nom, defaut) => (process.argv.find((a) => a.startsWith(`--${nom}=`)) ?? `=${defaut}`).split('=')[1];
const GELS = arg('gels', '20,75').split(',').map(Number);
const SORTIE = path.join(DEPOT, 'docs/current/captures/E2E/salle-banc', arg('dossier', 'veille'));
const RECITATION = '/opt/banc-audio/ref/recitation.wav';
fs.mkdirSync(SORTIE, { recursive: true });
for (const f of fs.readdirSync(SORTIE)) if (/\.png$|^journal\.txt$/.test(f)) fs.rmSync(path.join(SORTIE, f));
const journal = [];
const dire = (m) => { console.log(m); journal.push(m); fs.writeFileSync(path.join(SORTIE, 'journal.txt'), `${journal.join('\n')}\n`); };
let n = 0;
const capture = async (p, etiquette) => {
  n += 1;
  await p.page.screenshot({ path: path.join(SORTIE, `${String(n).padStart(2, '0')}_${p.nom}_${etiquette}.png`) });
};

// Espion du verrou d'ecran : combien de demandes, combien tenues, combien
// relachees par le navigateur.
const ESPION_VERROU = `
  window.__veille = { demandes: 0, tenus: 0, relaches: 0, erreurs: [], absent: !navigator.wakeLock };
  if (navigator.wakeLock) {
    const origine = navigator.wakeLock.request.bind(navigator.wakeLock);
    navigator.wakeLock.request = async (type) => {
      window.__veille.demandes += 1;
      try {
        const verrou = await origine(type);
        window.__veille.tenus += 1;
        verrou.addEventListener('release', () => { window.__veille.relaches += 1; });
        return verrou;
      } catch (e) { window.__veille.erreurs.push(String(e)); throw e; }
    };
  }`;

const octets = (liste) => liste.filter((x) => x.genre === 'audio').reduce((s, x) => s + (x.octets ?? 0), 0);

/// L'etat lisible de la page : le son recu et emis (octets), le micro, les
/// boutons qui attendent un geste.
async function etat(p) {
  const s = await p.stats();
  const lus = await libelles(p.page);
  return {
    recu: octets(s.recu), emis: octets(s.emis),
    microOuvert: lus.some((l) => /^Couper le micro/.test(l)),
    microFerme: lus.some((l) => /^Ouvrir le micro/.test(l)),
    attend: lus.filter((l) => /Reprendre|Réessayer|Rejoindre|Revenir|Reconnexion|Reconnecter/i.test(l)).slice(0, 6),
  };
}

const c = amorcerClasse({ n: 1, etiquette: `veille ${Date.now() % 100000}` });
dire(`== Ecran qui s'eteint ; ${new Date().toISOString()} ; classe « ${c.nom} » ; gels : ${GELS.join(' s, ')} s`);
const ouverts = [];
try {
  const ens = await participant('enseignant', fs.existsSync(RECITATION) ? { audio: RECITATION } : {});
  ouverts.push(ens);
  await connecter(ens, COMPTES.enseignant);
  if (!(await appuyer(ens, /^Rejoindre la salle/, { delai: 25000, pause: 9000 }))) throw new Error(`enseignant : pas de « Rejoindre la salle » ; ${await ens.lus(20)}`);
  dire(`enseignant, micro : ${await appuyer(ens, /^Ouvrir le micro/, { pause: 2500 })}`);

  const eleve = await participant('eleve-telephone', { telephone: true });
  ouverts.push(eleve);
  await eleve.ctx.addInitScript(ESPION_VERROU);
  await connecter(eleve, c.eleves[0].courriel);
  if (!(await appuyer(eleve, /^Rejoindre/, { delai: 25000, pause: 9000 }))) throw new Error(`eleve : pas de « Rejoindre » ; ${await eleve.lus(20)}`);
  dire(`eleve, micro : ${await appuyer(eleve, /^Ouvrir le micro/, { delai: 8000, pause: 3000 })}`);
  await eleve.page.waitForTimeout(6000);
  dire(`verrou d'ecran chez l'eleve : ${JSON.stringify(await eleve.page.evaluate(() => window.__veille ?? null))}`);
  const avant = await etat(eleve);
  dire(`eleve avant le gel : ${JSON.stringify(avant)}`);
  await capture(eleve, 'avant');

  const cdp = await eleve.ctx.newCDPSession(eleve.page);
  for (const duree of GELS) {
    dire(`-- gel de ${duree} s`);
    const depart = await etat(eleve);
    await cdp.send('Page.setWebLifecycleState', { state: 'frozen' });
    await ens.page.waitForTimeout(duree * 1000);
    dire(`enseignant, pendant le gel, voit : ${(await ens.lus(40)).slice(0, 500)}`);
    await cdp.send('Page.setWebLifecycleState', { state: 'active' });
    const t0 = Date.now();
    let precedent = null; let voix = null; let micro = null; let dernier = null;
    await eleve.page.waitForTimeout(1500);
    await capture(eleve, `reveil-apres-${duree}s`);
    while (Date.now() - t0 < 60000 && (voix === null || micro === null)) {
      dernier = await etat(eleve).catch(() => null);
      const t = Math.round((Date.now() - t0) / 100) / 10;
      if (dernier && precedent) {
        if (voix === null && dernier.recu - precedent.recu > 1500) voix = t;
        if (micro === null && dernier.microOuvert && dernier.emis - precedent.emis > 1500) micro = t;
      }
      precedent = dernier ?? precedent;
      await eleve.page.waitForTimeout(1000);
    }
    dire(`reveil apres ${duree} s : voix de l'enseignant revenue en ${voix ?? 'PLUS DE 60'} s ; micro de l'eleve ouvert et emettant en ${micro ?? 'PLUS DE 60'} s (avant le gel : ouvert=${depart.microOuvert})`);
    dire(`eleve apres le reveil : ${JSON.stringify(dernier)}`);
    dire(`verrou d'ecran : ${JSON.stringify(await eleve.page.evaluate(() => window.__veille ?? null))}`);
    await capture(eleve, `repris-apres-${duree}s`);
    if (eleve.journal.length) dire(`eleve, erreurs de page : ${eleve.journal.slice(-6).join(' ; ')}`);
  }
  dire('== fin sans erreur de script');
} catch (e) {
  dire(`ECHEC : ${String(e.message ?? e).slice(0, 600)}`);
} finally {
  for (const p of ouverts) await p.fermer().catch(() => {});
  alleger(SORTIE);
}
