// ADM-UX-bis (03/11/2026) : Personnes > Demandes, apres « Accepter la
// demande … », le focus va sur la phrase faite et Echap ferme la boite
// (constat du rejeu du 03/11 : le focus tombait sur la page). Pile LOCALE
// seulement (jamais un apercu Vercel, jamais la production).
//
// A 1440 x 900 et 390 x 844 : une demande recue (vrai chemin,
// `inscrire_titulaire`), ouverte, acceptee, puis Echap, sans toucher la croix.
// PHASE=avant : la meme preuve sur une construction de main, sans le lot.
// Usage : node tool/e2e/adm_ux_bis.mjs
import { randomUUID } from 'node:crypto';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique, amenerEnVue,
  sql, COMPTES } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const phase = process.env.PHASE ?? 'apres';
const p = await parcours(`ADM-UX-bis (${phase}) : Echap ferme la boite apres « Accepter »`,
  `ADM-UX-bis/${date}/${phase}`);
const verdicts = {};
const lus = async (page, n = 60) => (await libelles(page)).slice(0, n).join(' | ');

function inscrire() {
  const u = randomUUID();
  const suffixe = `${Date.now() % 1000000}`;
  sql(`begin;
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    values ('${u}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'e2e.admuxbis.${suffixe}@exemple.test', '', now(), '{}', '{}', now(), now());
    select set_config('request.jwt.claims', '{"sub":"${u}","role":"authenticated"}', true);
    select set_config('request.jwt.claim.sub', '${u}', true);
    select id from public.inscrire_titulaire('moi', 'Karima', 'Bis${suffixe}', 'female', 'Europe/Paris', false);
    commit;`);
  return `Karima Bis${suffixe}`;
}

let code = 1;
try {
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const nom = inscrire();
    const c = await p.contexte('direction', { vue: { width: w, height: h } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/personnes/demandes');
    await c.page.waitForTimeout(3000); await activerSemantique(c.page);
    const adultes = await trouver(c.page, /^Élèves adultes/, { delai: 8000 });
    if (adultes) { await adultes.click(); await c.page.waitForTimeout(2000); }
    const carte = await trouver(c.page, new RegExp(nom), { delai: 8000 });
    if (!carte) throw new Error(`${w} : carte de ${nom} absente ; ${await lus(c.page)}`);
    await amenerEnVue(c.page, carte);
    await carte.click(); await c.page.waitForTimeout(2000); await activerSemantique(c.page);
    const accepter = await trouver(c.page, /^Accepter la demande/, { delai: 5000 });
    if (!accepter) throw new Error(`${w} : « Accepter la demande » absent ; ${await lus(c.page)}`);
    await amenerEnVue(c.page, accepter);
    await accepter.click(); await c.page.waitForTimeout(4000); await activerSemantique(c.page);
    const focus = await c.page.evaluate(() => {
      const e = document.activeElement;
      return `${e?.tagName}:${e?.getAttribute('aria-label') ?? e?.textContent?.slice(0, 60) ?? ''}`;
    });
    await p.capture(c, `${w}_apres_accepter`);
    await c.page.keyboard.press('Escape');
    await c.page.waitForTimeout(1500); await activerSemantique(c.page);
    const fermee = !(await trouver(c.page, /est acceptée/, { delai: 1500 }));
    await p.capture(c, `${w}_apres_echap`);
    p.dire(`${w} : focus apres « Accepter » = ${focus} ; boite fermee par Echap = ${fermee}`);
    verdicts[w] = fermee;
    await c.ctx.close();
  }
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(phase === 'avant' ? 'joué' : (ok ? 'vert' : 'rouge'), ok ? '' : JSON.stringify(verdicts));
  if (phase === 'avant') code = 0;
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 400));
}
process.exit(code);
