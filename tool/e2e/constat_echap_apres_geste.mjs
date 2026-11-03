// REJEU-E2E (03/11/2026), constat non corrige : Personnes > Demandes, apres
// « Accepter la demande … », le focus tombe sur la page (le bouton disparait)
// et Echap ne ferme plus la boite ; avant le geste, Echap la ferme. Pile
// LOCALE seulement. Usage : node tool/e2e/constat_echap_apres_geste.mjs
import { randomUUID } from 'node:crypto';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique, amenerEnVue, sql, COMPTES } from './commun.mjs';
const p = await parcours('Constat : Echap ne ferme plus la boite d une demande apres Accepter', 'rejeu-2026-11-03/constats/echap-apres-accepter');
for (const [w, h] of [[1440, 900], [390, 844]]) {
  const u = randomUUID(); const suf = `${Date.now() % 1000000}`;
  sql(`begin;
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    values ('${u}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'e2e.sonde.${suf}@exemple.test', '', now(), '{}', '{}', now(), now());
    select set_config('request.jwt.claims', '{"sub":"${u}","role":"authenticated"}', true);
    select set_config('request.jwt.claim.sub', '${u}', true);
    select id from public.inscrire_titulaire('moi', 'Karima', 'Sonde${suf}', 'female', 'Europe/Paris', false);
    commit;`);
  const nom = `Karima Sonde${suf}`;
  const c = await p.contexte('direction', { vue: { width: w, height: h } });
  await connecter(c.page, COMPTES.direction);
  await ouvrir(c.page, '/#/admin/personnes/demandes'); await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  const ad = await trouver(c.page, /^Élèves adultes/, { delai: 8000 }); await ad.click(); await c.page.waitForTimeout(2000);
  const carte = await trouver(c.page, new RegExp(nom), { delai: 8000 }); await amenerEnVue(c.page, carte); await carte.click(); await c.page.waitForTimeout(2000);
  // Echap avant de toucher quoi que ce soit
  await c.page.keyboard.press('Escape'); await c.page.waitForTimeout(1500); await activerSemantique(c.page);
  const fermeeAvant = !(await trouver(c.page, /^Accepter la demande/, { delai: 1500 }));
  const carte2 = await trouver(c.page, new RegExp(nom), { delai: 8000 }); await amenerEnVue(c.page, carte2); await carte2.click(); await c.page.waitForTimeout(2000);
  const acc = await trouver(c.page, /^Accepter la demande/, { delai: 5000 }); await amenerEnVue(c.page, acc); await acc.click(); await c.page.waitForTimeout(4000);
  const focus = await c.page.evaluate(() => `${document.activeElement?.tagName}:${document.activeElement?.getAttribute('aria-label') ?? ''}`);
  await c.page.keyboard.press('Escape'); await c.page.waitForTimeout(1500); await activerSemantique(c.page);
  const fermeeApres = !(await trouver(c.page, /est acceptée/, { delai: 1500 }));
  await p.capture(c, `${w}_apres_accepter_puis_echap`);
  p.dire(`${w} : Echap avant geste ferme=${fermeeAvant} ; focus apres Accepter=${focus} ; Echap apres Accepter ferme=${fermeeApres}`);
  await c.ctx.close();
}
await p.fin('joué'); process.exit(0);
