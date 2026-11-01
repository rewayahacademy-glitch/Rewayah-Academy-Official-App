// Parcours « fin de seance » (demande du directeur, 01/11) : la seance de la classe
// d'adultes a atteint ended_at. Usage : node tool/e2e/parcours_fin.mjs <etiquette>
// (ex. « fin+2 », « fin+15 », « close »). Observe, pour l'adulte et l'enseignant :
// la carte de classe sur l'Accueil, « Rejoindre » et ce qu'il ouvre (salle, ecran de fin,
// motif de refus de re-entree), le temps restant affiche en salle, les notifications.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, trouver, trouverTexte, libelles, sql,
  activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';
const etiquette = process.argv[2] ?? 'fin';
const classe = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'classe_adultes.json'), 'utf8'));
const { ADULTE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
if (etiquette === 'chrono') {
  // FN-023 (lot « Fin de seance », etape 1) : le chrono du temps restant dans la
  // salle, pour l'enseignant et l'eleve adulte, puis son passage a « Temps prevu
  // ecoule » a la fin prevue. Pile LOCALE : la prochaine seance materialisee de la
  // classe d'adultes est avancee en SQL pour finir dans 3 minutes (sans cela, il
  // faudrait attendre une heure et demie) ; aucun texte n'est lu ailleurs que
  // dans l'application.
  process.exit(await chrono());
}
const p = await parcours(`Fin de seance (${etiquette})`, `parcours-fin/${etiquette}`);
const etat = sql(`select s.status || ' ; prevue ' || to_char(s.started_at,'HH24:MI') || '-' || to_char(s.ended_at,'HH24:MI') || ' UTC ; maintenant ' || to_char(now() at time zone 'utc','HH24:MI') from public.sessions s join public.groupes g on g.id = s.groupe_id
  where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`);
p.dire(`Seance : ${etat}`);
const resume = async (page) => (await libelles(page)).filter((x) => !/^(input|a:)/.test(x)).slice(0, 18).join(' | ').slice(0, 900);

async function role(nom, entrer, reRejoindre) {
  const c = await p.contexte(nom, { telephone: nom === 'adulte' });
  await entrer(c.page);
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  await p.capture(c, `${nom}_accueil`);
  p.dire(`${nom}, Accueil : ${await resume(c.page)}`);
  const r = await trouver(c.page, reRejoindre, { delai: 5000 });
  p.dire(`${nom}, « Rejoindre » : ${r ? (await r.getAttribute('aria-label')) : 'absent'}`);
  if (r) {
    await r.click(); await c.page.waitForTimeout(8000); await activerSemantique(c.page);
    await p.capture(c, `${nom}_apres_rejoindre`);
    p.dire(`${nom}, apres « Rejoindre » : ${c.page.url()} ; ${await resume(c.page)}`);
    const temps = await trouverTexte(c.page, /(restant|reste|minutes?|dépass|terminée|fin)[^|]*/i, 2000);
    p.dire(`${nom}, temps ou fin affiche : ${temps ?? 'rien'}`);
  }
  const n = await trouver(c.page, /^Notifications/, { delai: 3000 });
  if (n) { await n.click(); await c.page.waitForTimeout(3000); await activerSemantique(c.page); await p.capture(c, `${nom}_notifications`); p.dire(`${nom}, notifications : ${await resume(c.page)}`); }
  await c.ctx.close();
}
await role('adulte', (pg) => connecterParLien(pg, ADULTE.courriel), /^Rejoindre/);
await role('enseignant', (pg) => connecter(pg, COMPTES.enseignant), new RegExp(`^Rejoindre la salle`));
p.dire(`Seance (fin du script) : ${sql(`select s.status from public.sessions s join public.groupes g on g.id = s.groupe_id where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`)}`);
await p.fin('joué');

async function chrono() {
  const q = await parcours('Fin de seance, etape 1 : chrono du temps restant en salle', 'fin-seance-chrono');
  const groupe = `(select id from public.groupes where libelle = '${classe.nom}' and ended_at is null limit 1)`;
  const seance = sql(`select id from public.sessions where groupe_id = ${groupe} and deleted_at is null
    and status in ('planned','preflight','in_progress') order by abs(extract(epoch from started_at - now())) limit 1`);
  if (!seance) return q.fin('rouge', `aucune seance materialisee pour ${classe.nom}`);
  sql(`update public.sessions set started_at = now() - interval '57 minutes', ended_at = now() + interval '3 minutes',
    join_opens_at = now() - interval '77 minutes' where id = '${seance}'`);
  const fin = Date.parse(sql(`select to_char(ended_at at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"') from public.sessions where id = '${seance}'`));
  q.dire(`Seance ${seance} : ${sql(`select status || ' ; ' || to_char(started_at at time zone 'utc','HH24:MI:SS') || '-' || to_char(ended_at at time zone 'utc','HH24:MI:SS') || ' UTC' from public.sessions where id = '${seance}'`)}`);
  const MOTIF_RESTANT = /min restantes|restant/;
  const MOTIF_ECOULE = /Temps prévu écoulé/;
  const acteurs = [];
  const e = await q.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  let r = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe.nom}`), { delai: 15000 });
  if (!r) { await q.capture(e, 'aujourdhui'); return q.fin('rouge', `enseignant : pas de « Rejoindre la salle » ; ${(await libelles(e.page)).slice(0, 15).join(' | ')}`); }
  await r.click(); await e.page.waitForTimeout(8000); await activerSemantique(e.page);
  acteurs.push(e);
  const a = await q.contexte('adulte', { telephone: true });
  await connecterParLien(a.page, ADULTE.courriel);
  await a.page.waitForTimeout(3000); await activerSemantique(a.page);
  r = await trouver(a.page, /^Rejoindre/, { delai: 15000, role: 'button' });
  if (!r) { await q.capture(a, 'accueil'); return q.fin('rouge', `adulte : pas de « Rejoindre » ; ${(await libelles(a.page)).slice(0, 15).join(' | ')}`); }
  await r.click(); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
  acteurs.push(a);
  const avant = {};
  for (const x of acteurs) {
    await activerSemantique(x.page);
    avant[x.role] = await trouverTexte(x.page, MOTIF_RESTANT, 10000);
    await q.capture(x, 'salle_temps_restant');
    q.dire(`${x.role}, ${new Date().toISOString()}, avant la fin prevue : ${avant[x.role] ?? 'aucun temps restant affiche'}`);
  }
  const attente = fin + 10000 - Date.now();
  q.dire(`Attente de la fin prevue (${Math.max(0, Math.round(attente / 1000))} s)`);
  // A moins d'une minute de la fin : le temps restant se compte en secondes.
  if (attente > 70000) {
    await e.page.waitForTimeout(attente - 60000);
    for (const x of acteurs) {
      await activerSemantique(x.page);
      const t = await trouverTexte(x.page, MOTIF_RESTANT, 5000);
      await q.capture(x, 'salle_derniere_minute');
      q.dire(`${x.role}, ${new Date().toISOString()}, derniere minute : ${t ?? 'rien'}`);
    }
  }
  await e.page.waitForTimeout(Math.max(0, fin + 10000 - Date.now()));
  const apres = {};
  for (const x of acteurs) {
    await activerSemantique(x.page);
    apres[x.role] = await trouverTexte(x.page, MOTIF_ECOULE, 10000);
    await q.capture(x, 'salle_temps_prevu_ecoule');
    q.dire(`${x.role}, ${new Date().toISOString()}, apres la fin prevue : ${apres[x.role] ?? 'rien'}`);
  }
  const manque = acteurs.filter((x) => !avant[x.role] || !apres[x.role]).map((x) => x.role);
  return q.fin(manque.length ? 'rouge' : 'vert', manque.length ? `chrono absent ou fige pour : ${manque.join(', ')}` : '');
}
