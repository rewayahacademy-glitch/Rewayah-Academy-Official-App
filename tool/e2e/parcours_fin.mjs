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
