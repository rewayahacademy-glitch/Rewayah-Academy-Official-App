// Session refusee par le serveur (prod du 01/11/2026 : 401 en boucle et
// ecran « La connexion prend plus de temps que prevu » sans issue).
// Banc LOCAL : la famille se connecte ; la session est rendue invalide
// (jeton d'acces altere dans le navigateur, sessions effacees dans la base
// locale, comme un autre compte qui ouvre une session ailleurs) ; au
// rechargement, l'application doit revenir a « Se connecter » avec le
// bandeau « Vous avez été déconnecté ».
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecterParLien, activerSemantique, libelles, trouverTexte, sql, TRAVAIL } from './commun.mjs';

const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const p = await parcours('Session refusee : retour a « Se connecter »', 'session-refusee');
const echecs = [];
let code = 1;
try {
  const f = await p.contexte('tuteur', { telephone: true });
  await connecterParLien(f.page, FAMILLE.courriel);
  await f.page.waitForTimeout(4000); await activerSemantique(f.page);
  await p.capture(f, 'connecte');
  p.dire(`Connecte : ${(await libelles(f.page)).slice(0, 3).join(' | ')}`);

  // 1. Le jeton d'acces du navigateur ne vaut plus (signature alteree).
  const altere = await f.page.evaluate(() => {
    const cle = Object.keys(localStorage).find((k) => k.startsWith('sb-') && k.endsWith('-auth-token'));
    if (!cle) return false;
    const s = JSON.parse(localStorage.getItem(cle));
    const j = s.access_token;
    s.access_token = j.slice(0, -6) + (j.slice(-6) === 'AAAAAA' ? 'BBBBBB' : 'AAAAAA');
    localStorage.setItem(cle, JSON.stringify(s));
    return true;
  });
  // 2. Le serveur ne connait plus cette session (base LOCALE).
  sql(`delete from auth.sessions where user_id = (select id from auth.users where email = '${FAMILLE.courriel}')`);
  p.dire(`Jeton altere : ${altere} ; sessions effacees dans la base locale`);
  if (!altere) throw new Error('jeton introuvable dans le navigateur');

  await f.page.reload();
  await f.page.waitForTimeout(9000); await activerSemantique(f.page);
  await p.capture(f, 'apres_refus');
  const bandeau = await trouverTexte(f.page, /Vous avez été déconnecté/, 20000);
  const seConnecter = await trouverTexte(f.page, /Se connecter|J'ai déjà un compte/, 5000);
  p.dire(`Bandeau : ${bandeau ?? '-'} ; ecran : ${seConnecter ?? '-'} ; ${f.page.url()}`);
  if (!bandeau) echecs.push('bandeau « Vous avez été déconnecté » absent');
  if (!seConnecter) echecs.push('l\'ecran « Se connecter » ne s\'affiche pas');
  if (/prend plus de temps/.test((await libelles(f.page)).join(' '))) echecs.push('ecran « prend plus de temps que prevu » encore affiche');
  code = await p.fin(echecs.length ? 'rouge' : 'vert', echecs.join(' ; '));
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 600));
}
process.exit(code);
