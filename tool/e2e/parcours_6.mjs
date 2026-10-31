// Parcours 6 : presence et cahier, apres une seance tenue (celle du parcours 5).
// 1. Rien a cocher : la presence se calcule sur les minutes passees en salle
//    (present a 50 % du temps prevu ou plus, partiel au-dessous, absent a zero).
// 2. Enseignant : « Aujourd'hui », section « À terminer », ligne « Cahier de
//    transmission … ». 3. Remplir, puis « Valider le cahier de transmission ».
// La seance doit etre close (cloture automatique a fin + 30 min).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, taper, sql,
  activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 6 : presence et cahier', 'parcours-6');

/// La presence calculee, lue comme la direction la lit (claims d'admin, base locale).
function presence(seance) {
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  return sql(`begin; set local role authenticated;
    select set_config('request.jwt.claims', '{"sub":"${admin}","role":"authenticated","app_metadata":{"role":"admin"}}', true);
    select string_agg(prenom || ' : ' || coalesce(presence_temps, '?') || ' (' || coalesce(minutes_connectees, 0) || '/' || coalesce(minutes_prevues, 0) || ' min)', ' ; ')
      from public.presence_seance_v where session_id = '${seance}' and role = 'student';
    rollback;`).split('\n').filter((l) => l.includes(' min)')).join(' ');
}

let code = 1;
try {
  const classe = lire('classe_parcours2.json');
  const s = sql(`select s.id || '|' || s.status from public.sessions s join public.groupes g on g.id = s.groupe_id
    where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`);
  const [seance, statut] = s.split('|');
  p.dire(`Seance ${seance} de « ${classe.nom} » : ${statut}`);
  if (!['ended', 'tech_failure', 'teacher_absent', 'completed'].includes(statut)) {
    throw new Error(`la seance n'est pas close (statut ${statut}) : le cahier n'entre dans « À terminer » qu'apres la cloture automatique (fin + 30 min)`);
  }
  // 1. Presence calculee.
  const pres = presence(seance);
  p.dire(`Presence calculee : ${pres || 'aucune ligne'}`);
  if (!pres) throw new Error('aucune presence calculee pour les eleves de la seance');

  // 2. Enseignant : « Aujourd'hui », « À terminer », « Cahier de transmission … ».
  const e = await p.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  await p.capture(e, 'aujourdhui');
  let ligne = await trouver(e.page, /^Cahier de transmission/, { delai: 10000 });
  if (!ligne) {
    const voir = await trouver(e.page, /À terminer/, { delai: 3000 });
    if (voir) { await voir.click(); await e.page.waitForTimeout(2000); }
    ligne = await trouver(e.page, /^Cahier de transmission/, { delai: 5000 });
  }
  if (!ligne) throw new Error(`enseignant, Aujourd'hui : pas de ligne « Cahier de transmission … » dans « À terminer » ; ecran : ${(await libelles(e.page)).slice(0, 25).join(' | ')}`);
  p.dire(`Ligne : ${(await ligne.getAttribute('aria-label')) ?? (await ligne.textContent())}`);
  await ligne.click();
  await e.page.waitForTimeout(3000);
  await activerSemantique(e.page);
  await p.capture(e, 'cahier_ouvert');
  p.dire(`Cahier : ${(await libelles(e.page)).filter((x) => /^(input|textarea|radio|checkbox|button)/.test(x)).join(' | ').slice(0, 1500)}`);

  // 3. Remplir : « Où la Classe s'est arrêtée » (obligatoire) : sourate et verset.
  await cliquer(e.page, /^Où la Classe s'est arrêtée/, { pause: 2500 });
  await cliquer(e.page, /^109\. Al-Kaafiroon/, { role: 'radio', pause: 1500 });
  await cliquer(e.page, /^6$/, { role: 'button', pause: 800 });
  await p.capture(e, 'position_choisie');
  await cliquer(e.page, /^Retenir cette position$/, { pause: 2500 });
  // Champs libres eventuels.
  for (const c of await e.page.locator('textarea').all()) {
    const nom = (await c.getAttribute('aria-label')) ?? '';
    await c.click({ force: true }); await e.page.keyboard.press('Control+A');
    await e.page.keyboard.type(`E2E : lettres revues, lecture lente.`, { delay: 5 });
    await e.page.waitForTimeout(200);
    p.dire(`  saisi dans « ${nom.split('\n')[0]} »`);
  }
  await p.capture(e, 'cahier_rempli');
  const valider = await trouver(e.page, /^Valider le cahier de transmission/, { delai: 5000, role: 'button' });
  if (!valider) throw new Error(`cahier : pas de « Valider le cahier de transmission » ; ecran : ${(await libelles(e.page)).slice(-25).join(' | ')}`);
  await valider.click();
  await e.page.waitForTimeout(3000);
  const confirmer = await trouver(e.page, /^(Valider|Confirmer)/, { delai: 1500, role: 'button' });
  if (confirmer) { await confirmer.click(); await e.page.waitForTimeout(3000); }
  await activerSemantique(e.page);
  await p.capture(e, 'cahier_valide');
  const erreur = await trouverTexte(e.page, /(manque|obligatoire|n'est pas|impossible|réessayez)[^|]*/i, 1500);
  const cahier = sql(`select count(*) || ' rapport(s)' from public.lesson_reports where session_id = '${seance}'`);
  p.dire(`Apres validation : ${erreur ?? 'aucun message d\'erreur'} ; cahier en base : ${cahier || '-'}`);
  const fini = await trouverTexte(e.page, /(enregistré|validé|déposé|envoyé|Tous vos cahiers de transmission sont terminés)[^|]*/i, 8000);
  p.dire(`Ecran : ${fini ?? '-'}`);
  if (!fini) throw new Error(`cahier : apres « Valider le cahier de transmission », pas de confirmation (${erreur ?? 'aucun message'})`);
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
