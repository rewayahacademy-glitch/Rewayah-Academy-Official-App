// Lot FOYER-UX (06/11/2026), UX-009 en local : un foyer dont l'enfant a une
// seance en cours ; la seance seule est sans fenetre (horloge_seance rendue
// illisible pour les comptes, BASE LOCALE SEULEMENT), l'horloge de la classe
// ouvre la porte. Avant le lot, l'Accueil disait « Rejoindre la salle avec… »
// ET « Ouverture de la salle non confirmée pour l'instant ». Apres : un seul
// message. Captures 390 et 1440, FR et AR.
//
// Usage : node tool/e2e/foyer_ux_009.mjs <courriel d'un compte tuteur local accepte>
import { parcours, connecter, connecterParLien, trouver, trouverTexte, cliquer, taper, dernierLien, libelles, activerSemantique, ouvrir, sql, COMPTES } from './commun.mjs';
import { accepterDemande } from './inscription.mjs';

let courriel = process.argv[2] ?? 'nouveau';
const p = await parcours('FOYER-UX UX-009', 'foyer-ux-009');
const ecarts = [];
let code = 1;

/// Le formulaire « Ajouter un profil élève » ou « Créer mon profil élève », en
/// etapes : prenom, nom, age, genre... jusqu'au retour au Foyer.
async function profilEleve(a, { prenom, nom, age = /^9( ans)?$/, genre = /garçon|fille|homme|femme/i }, prefixe) {
  for (let k = 0; k < 10; k++) {
    const l = await libelles(a.page);
    p.dire(`  ${prefixe} ${k} : ${l.filter((x) => /^(flt-semantics|input|radio|button:(?!Notifications|Accueil|Foyer|Historique|Compte))/.test(x)).join(' | ').slice(0, 420)}`);
    await p.capture(a, `${prefixe}_${k}`);
    const alerte = l.find((x) => /(existe déjà|même nom|déjà un profil|doublon|déjà inscrit)/i.test(x));
    if (alerte) return { alerte };
    for (const c of await a.page.locator('input').all()) {
      const n = `${await c.getAttribute('aria-label') ?? ''}`;
      let v = null;
      if (/prénom/i.test(n)) v = prenom; else if (/nom/i.test(n)) v = nom;
      if (v === null) continue;
      await c.click({ force: true }); await a.page.keyboard.press('Control+A');
      await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
    }
    const a1 = await trouver(a.page, age, { delai: 800 });
    if (a1) await a1.click();
    const radios = l.filter((x) => x.startsWith('radio:'));
    if (radios.length) {
      const g = await trouver(a.page, genre, { delai: 800, role: 'radio' }) ?? await trouver(a.page, radios[0].slice(6, 30), { delai: 800 });
      if (g) await g.click();
    }
    const suite = await trouver(a.page, /^(Continuer|Suivant|Ajouter.*|Créer.*|Enregistrer.*|Valider.*|Terminer)$/, { delai: 2500, role: 'button' });
    if (!suite) return { fin: l.slice(0, 12).join(' | ') };
    await suite.click(); await a.page.waitForTimeout(2500); await activerSemantique(a.page);
    if (/#\/tuteur(\/foyer)?\/?$|accueil$/.test(a.page.url()) && k > 0) { await p.capture(a, `${prefixe}_fin`); return { fin: a.page.url() }; }
  }
  return { fin: 'trop d\'etapes' };
}


async function inscrireIci(p, a, { courriel, prenom, nom, genre }, prefixe = 'i') {
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(a.page, /^Recevoir le lien( d'inscription)?$/, { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  if (!recu?.lien) throw new Error(`aucun lien recu pour ${courriel}`);
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  const vus = [];
  for (let k = 0; k < 8; k++) {
    const l = await libelles(a.page);
    vus.push(l.filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h2:')).join(' / '));
    for (const c of await a.page.locator('input').all()) {
      const n = `${await c.getAttribute('aria-label') ?? ''}`;
      let v = null;
      if (/prénom/i.test(n)) v = prenom; else if (/nom/i.test(n)) v = nom;
      if (v === null) continue;
      await c.click({ force: true }); await a.page.keyboard.press('Control+A');
      await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
    }
    if (l.some((x) => x.startsWith('radio:'))) {
      const g = await trouver(a.page, genre, { delai: 2000, role: 'radio' });
      if (g) { await g.click(); await a.page.waitForTimeout(400); }
    }
    await p.capture(a, `${prefixe}_identite_${k}`);
    const envoyer = await trouver(a.page, /^Envoyer ma demande$/, { delai: 1500 });
    if (envoyer) { await envoyer.click(); await a.page.waitForTimeout(4000); break; }
    await cliquer(a.page, /^Continuer$/, { pause: 1500 });
  }
  await activerSemantique(a.page);
  for (let k = 0; k < 6; k++) {
    if (await trouverTexte(a.page, /Votre demande est en cours/i, 1500)) break;
    const lire = await trouver(a.page, /^Lire et accepter nos conditions$/, { delai: 1500 });
    if (lire) { await lire.click(); await a.page.waitForTimeout(1500); }
    const cases = a.page.getByRole('checkbox');
    for (let i = 0; i < await cases.count(); i++) {
      if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await a.page.waitForTimeout(300); }
    }
    const suite = await trouver(a.page, /^(Suivant|Continuer)$/, { delai: 2000, role: 'button' });
    if (suite) { await suite.click(); await a.page.waitForTimeout(2500); await activerSemantique(a.page); }
  }
  await p.capture(a, `${prefixe}_demande`);
  return vus;
}



const PRENOM = 'Yanis';
async function preuves(a, langue) {
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    await a.page.setViewportSize({ width: w, height: h });
    await a.page.evaluate(() => { location.hash = '#/tuteur'; });
    await a.page.waitForTimeout(1500);
    await a.page.evaluate(() => { location.hash = '#/tuteur'; });
    await a.page.waitForTimeout(5000); await activerSemantique(a.page);
    await p.capture(a, `${langue}_${w}_accueil`);
    const l = (await libelles(a.page)).join(' | ');
    const rejoindre = langue === 'fr' ? new RegExp(`Rejoindre la salle avec ${PRENOM}`) : new RegExp(PRENOM);
    const incertain = langue === 'fr' ? /non confirmée pour l'instant/ : /فتح القاعة غير مؤك/;
    const r = rejoindre.test(l); const n = incertain.test(l);
    p.dire(`  ${langue} ${w} Accueil : « Rejoindre » ${r ? 'present' : 'ABSENT'} ; « non confirmée » ${n ? 'PRESENT' : 'absent'}`);
    if (!r) ecarts.push(`${langue} ${w} : « Rejoindre la salle avec » absent (etat non reproduit)`);
    if (r && n) ecarts.push(`${langue} ${w} : deux messages contradictoires`);
  }
}

try {
  const a = await p.contexte('tuteur', { telephone: true });
  if (courriel === 'nouveau') {
    const t = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
    const F = { courriel: `e2e-foyer-ux-fam-${t}@example.com`, prenom: 'E2E Karim', nom: `Fam${t}` };
    courriel = F.courriel;
    const d = await p.contexte('direction');
    await connecter(d.page, COMPTES.direction);
    await ouvrir(a.page, '/');
    if (await trouver(a.page, /^Créer un compte$/, { delai: 3000 })) await cliquer(a.page, /^Créer un compte$/);
    await cliquer(a.page, /^J'inscris mon enfant/);
    await cliquer(a.page, /^Continuer$/);
    const choix = [/^9 ans$/, /^Un garçon$/, /^Nous commençons par les lettres$/, /^Non$/, /^Français$/, /^Apprendre à lire$/, /^Le soir$/];
    for (let k = 0; k < 14; k++) {
      if (await a.page.locator('input[autocomplete=email], input[inputmode=email]').count()) break;
      await p.capture(a, `questionnaire_${k}`);
      const champ = a.page.locator('input');
      if (await champ.count() && !(await champ.first().inputValue())) await taper(a.page, 'input', PRENOM);
      for (const c of choix) {
        const e = await trouver(a.page, c, { delai: 400 });
        if (e) { await e.click(); await a.page.waitForTimeout(400); break; }
      }
      await cliquer(a.page, /^Continuer$/, { pause: 1300 });
    }
    await inscrireIci(p, a, { courriel: F.courriel, prenom: F.prenom, nom: F.nom, genre: /^Un homme/ }, 'inscription');
    await accepterDemande(p, d, { liste: 'Familles', nomComplet: `${F.prenom} ${F.nom}` });
  }
  await connecterParLien(a.page, courriel);
  await a.page.waitForTimeout(3000);
  const foyer = sql(`select p.household_id from auth.users u join public.profiles p on p.id = u.id where u.email = '${courriel}'`);
  let enfant = sql(`select id from public.profiles where household_id = '${foyer}' and first_name = '${PRENOM}' and role = 'student' limit 1`);
  if (!enfant) {
    await a.page.evaluate(() => { location.hash = '#/tuteur/foyer/ajouter'; });
    await a.page.waitForTimeout(3500); await activerSemantique(a.page);
    const r = await profilEleve(a, { prenom: PRENOM, nom: 'FoyerUx', genre: /garçon/i }, 'ajout');
    p.dire(`Ajout de l'enfant : ${JSON.stringify(r)}`);
    enfant = sql(`select id from public.profiles where household_id = '${foyer}' and first_name = '${PRENOM}' limit 1`);
  }
  if (!enfant) throw new Error('enfant non cree');
  const ens = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  // Passage precedent (base locale) : ses seances repoussees d'un an en
  // arriere et closes, sa classe fermee (aucun effacement : cles etrangeres).
  const clore = (cond) => {
    sql(`update public.sessions set status = 'ended' where status in ('in_progress', 'preflight') and ${cond}`);
    sql(`update public.sessions set status = 'canceled' where status = 'planned' and ${cond}`);
    sql(`update public.sessions set started_at = started_at - interval '400 days', ended_at = ended_at - interval '400 days' where ${cond} and started_at > now() - interval '300 days'`);
  };
  clore(`groupe_id in (select id from public.groupes where libelle = 'E2E FOYER-UX 009')`);
  // Classe active, creneau de l'heure en cours (Paris), seance en cours.
  // Le fuseau dont l'heure pleine est la plus recente (moins de 30 min) : la
  // seance commence a l'heure du creneau, sans que la regle « aucun
  // enseignant a T+30 » la close pendant la preuve.
  const tz = sql(`select tz from (values ('Europe/Paris'), ('Asia/Kolkata'), ('Asia/Kathmandu')) v(tz)
    order by now() - (date_trunc('hour', now() at time zone tz) at time zone tz) limit 1`);
  const debut = `(date_trunc('hour', now() at time zone '${tz}') at time zone '${tz}')`;
  const jour = `extract(isodow from now() at time zone '${tz}')::smallint`;
  const heure = `extract(hour from now() at time zone '${tz}')::smallint`;
  // L'enseignant de test, disponible a cette heure dans ce fuseau (base locale).
  sql(`insert into public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
    select '${ens}', d, h, '${tz}' from generate_series(1, 7) d, generate_series(0, 23) h
    on conflict do nothing`);
  let groupe = sql(`select g.id from public.groupes g join public.groupe_membres m on m.groupe_id = g.id and m.left_at is null where g.libelle = 'E2E FOYER-UX 009' and m.student_id = '${enfant}' limit 1`);
  // Les autres classes de test de ce robot sont fermees (chevauchement).
  sql(`update public.groupes set ended_at = now(), ended_by = '${ens}', end_reason = 'E2E FOYER-UX : passage precedent'
    where libelle = 'E2E FOYER-UX 009' and ended_at is null and id::text <> '${groupe || '-'}'`);
  if (!groupe) {
    groupe = sql(`with g as (insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, etat)
      values ('${ens}', 'enfant', 6, 'E2E FOYER-UX 009', ${jour}, ${heure}, '${tz}', 'active') returning id)
    select id from g`).split('\n')[0];
    sql(`insert into public.groupe_membres (groupe_id, student_id) values ('${groupe}', '${enfant}')`);
  } else {
    sql(`update public.groupes set timezone_iana = '${tz}', weekday = ${jour}, hour_local = ${heure} where id = '${groupe}'`);
  }
  sql(`update public.groupe_creneaux set weekday = ${jour}, hour_local = ${heure} where groupe_id = '${groupe}'`);
  if (sql(`select count(*) from public.groupe_creneaux where groupe_id = '${groupe}'`) === '0') {
    sql(`insert into public.groupe_creneaux (groupe_id, weekday, hour_local) values ('${groupe}', ${jour}, ${heure})`);
  }
  clore(`groupe_id = '${groupe}'`);
  const seance = sql(`with s as (insert into public.sessions (teacher_id, groupe_id, started_at, ended_at, status)
      values ('${ens}', '${groupe}', ${debut}, ${debut} + interval '3 hours', 'in_progress') returning id)
    select id from s`).split('\n')[0];
  p.dire(`Fuseau de la classe : ${tz} ; debut ${sql(`select ${debut}`)}`);
  sql(`insert into public.session_participants (session_id, profile_id, role) values ('${seance}', '${enfant}', 'student')`);
  // L'etat d'UX-009 : la fenetre de la seance n'est pas rendue.
  sql(`revoke execute on function public.horloge_seance(uuid) from authenticated, anon, public`);
  p.dire(`Classe ${groupe}, seance ${seance} (en cours, a l'heure du creneau : l'horloge de la classe porte cette seance), horloge_seance revoquee (local)`);
  await ouvrir(a.page, '/');
  await a.page.waitForTimeout(4000); await activerSemantique(a.page);
  await preuves(a, 'fr');

  const stockage = await a.page.evaluate(() => JSON.stringify(Object.entries(localStorage)));
  const ar = await p.contexte('tuteur-ar', { telephone: true, langue: 'ar-SA' });
  await ar.ctx.addInitScript((s) => {
    if (sessionStorage.getItem('e2e-pose')) return;
    for (const [k, v] of JSON.parse(s)) if (!/langue|locale|lang/i.test(k)) localStorage.setItem(k, v);
    sessionStorage.setItem('e2e-pose', '1');
  }, stockage);
  await ouvrir(ar.page, '/');
  await ar.page.waitForTimeout(5000); await activerSemantique(ar.page);
  await preuves(ar, 'ar');
  code = await p.fin(ecarts.length ? 'rouge' : 'vert', ecarts.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
} finally {
  try { sql(`grant execute on function public.horloge_seance(uuid) to authenticated`); } catch {}
}
process.exit(code);
