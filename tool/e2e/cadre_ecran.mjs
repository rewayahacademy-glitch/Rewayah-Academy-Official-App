// CADRE-ECRAN (07/11/2026), banc LOCAL seulement (jamais un apercu, jamais la
// production). Donnees de TEST uniquement : un compte candidat fabrique, un
// texte de cadre de TEST (jamais le texte valide du directeur, que publiera
// la migration 20261118000000).
//   0. La pile simule cette migration : elle elargit localement les
//      contraintes de contract_texts (sorte du cadre, langue arabe) et la
//      policy de lecture, si la base locale ne le fait pas deja.
//   1. Rien de publie : la page du cadre dit « pas encore publie », sans
//      bouton.
//   2. Publie (texte de test FR et AR, version de test requise) : le portail
//      propose « Lire et accepter », qui mene a la page du cadre (plus a celle
//      des accords) ; le texte publie s'affiche, dans la langue de l'appli.
//   3. Case et « Accepter le cadre » : la ligne contract_acceptances existe
//      a la version publiee (le serveur a accepte, par sa policy) ; la page
//      propose « Completer ma candidature », qui ouvre le questionnaire.
// Usage : node tool/e2e/cadre_ecran.mjs [--bureau] [--arabe]
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, activerSemantique, amenerEnVue, taper, libelles, sql,
  API, MDP, DEPOT, TRAVAIL } from './commun.mjs';

const bureau = process.argv.includes('--bureau');
const arabe = process.argv.includes('--arabe');
const fr = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const ar = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8'));
const lire = (o, cle) => cle.split('.').reduce((x, k) => x?.[k], o);
const T = (cle) => (arabe ? lire(ar, cle) : undefined) ?? lire(fr, cle);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const souple = (s) => echapper(s).replace(/[\s  ]+/g, '\\s*');
const un = (q) => sql(q).split('\n')[0].trim();
const statut = Object.fromEntries(fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => { const i = l.indexOf('='); return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')]; }));
const SERVICE = statut.SERVICE_ROLE_KEY;

const VERSION = 'e2e-cadre-test';
const TEXTE_FR = '**Cadre de test (banc local)**\n\nCeci est un texte de TEST, jamais le texte publie.\n\n- premier point de test\n- second point de test';
const TEXTE_AR = '**إطار تجريبي (اختبار محلي)**\n\nهذا نص تجريبي، وليس النص المنشور.\n\n- النقطة التجريبية الأولى\n- النقطة التجريبية الثانية';

const largeur = bureau ? '1440' : '390';
const p = await parcours(`CADRE-ECRAN : le candidat accepte le cadre (${largeur}, ${arabe ? 'AR' : 'FR'})`,
  `cadre-ecran/robot-${largeur}-${arabe ? 'ar' : 'fr'}`);
const rouges = [];
function noter(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}${detail ? ` (${detail})` : ''}`);
  if (!ok) rouges.push(quoi);
}
async function connecter(page, courriel) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const motifs = [T('inscription.questionnaire.dejaUnCompte'), lire(fr, 'inscription.questionnaire.dejaUnCompte')];
    const deja = await trouver(page, new RegExp(`^\\s*(${motifs.map(echapper).join('|')})\\s*$`), { delai: 10000 });
    if (deja) { await deja.click(); await page.waitForTimeout(1500); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(6000);
  await activerSemantique(page);
}
async function chercher(page, motif, delai = 8000) {
  let e = await trouver(page, motif, { delai: Math.min(delai, 5000) });
  const v = page.viewportSize();
  for (let i = 0; !e && i < 12; i++) {
    await page.mouse.move(v.width * 0.6, v.height / 2);
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(500);
    e = await trouver(page, motif, { delai: 700 });
  }
  if (e) await amenerEnVue(page, e);
  return e;
}
const arbre = async (page) => (await libelles(page)).join(' | ');

let code = 1;
try {
  // 0. La publication simulee (base LOCALE seulement).
  sql(`do $$ begin
         alter table public.contract_texts drop constraint if exists contract_texts_contract_kind_check;
         alter table public.contract_texts add constraint contract_texts_contract_kind_check
           check (contract_kind in ('teacher_nda', 'teacher_religious_framework'));
         alter table public.contract_texts drop constraint if exists contract_texts_locale_check;
         alter table public.contract_texts add constraint contract_texts_locale_check check (locale in ('fr', 'ar'));
         drop policy if exists contract_texts_published_read on public.contract_texts;
         create policy contract_texts_published_read on public.contract_texts
           for select to authenticated using (is_current and locale in ('fr', 'ar'));
       end $$`);
  // Rien de publie au depart.
  sql(`delete from public.contract_required_versions where contract_kind = 'teacher_religious_framework'`);
  sql(`update public.contract_texts set is_current = false where contract_kind = 'teacher_religious_framework'`);

  // Le candidat de test.
  const ts = Date.now().toString(36);
  const courriel = `e2e-cadre-${ts}@example.com`;
  const cree = await (await fetch(`${API}/auth/v1/admin/users`, {
    method: 'POST',
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'content-type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP, email_confirm: true }),
  })).json();
  const uid = cree.id;
  if (!uid) throw new Error(`compte non cree : ${JSON.stringify(cree).slice(0, 200)}`);
  sql(`insert into public.profiles (id, role, first_name, last_name, account_status, gender)
         values ('${uid}', 'teacher', 'Candidat', 'Test', 'pending_kyc', 'male')`);
  sql(`insert into public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
         values ('${uid}', 'FR', array['francais'], 40, 'pending', 'Europe/Paris')`);
  sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
         values ('enseignant', '${uid}', 'male', 'Candidat Test', 'prequalification', 'a_completer', 'en_cours', 'lien_public')`);
  p.dire(`Candidat de test ${courriel} (${uid})`);

  const c = await p.contexte('candidat', { ...(bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true }),
    langue: arabe ? 'ar-SA' : 'fr-FR' });
  await connecter(c.page, courriel);

  // 1. Rien de publie : la page du cadre le dit, sans bouton.
  await ouvrir(c.page, '/#/attente/cadre'); await c.page.waitForTimeout(5000); await activerSemantique(c.page);
  const nonPublie = await chercher(c.page, new RegExp(souple(T('accords.cadreNonPublie').slice(0, 40))));
  noter(nonPublie !== null, 'rien de publie : « pas encore publie »', nonPublie ? '' : (await arbre(c.page)).slice(0, 300));
  noter(await trouver(c.page, new RegExp(souple(T('recrutement.cadre.accepter'))), { delai: 1500 }) === null,
    'rien de publie : aucun bouton « Accepter le cadre »');
  await p.capture(c, 'non_publie');

  // 2. Publie (texte de TEST).
  for (const [langue, texte] of [['fr', TEXTE_FR], ['ar', TEXTE_AR]]) {
    sql(`insert into public.contract_texts (contract_kind, version, locale, body, sha256, is_current)
         values ('teacher_religious_framework', '${VERSION}', '${langue}', $t$${texte}$t$,
                 encode(extensions.digest(convert_to($t$${texte}$t$, 'UTF8'), 'sha256'), 'hex'), true)
         on conflict (contract_kind, version, locale) do update set is_current = true`);
  }
  sql(`insert into public.contract_required_versions (contract_kind, version) values ('teacher_religious_framework', '${VERSION}')
       on conflict (contract_kind) do update set version = excluded.version`);

  // Le dossier deja lu est en memoire : on recharge, comme une personne qui
  // revient plus tard.
  await ouvrir(c.page, '/#/attente'); await c.page.reload(); await c.page.waitForTimeout(6000); await activerSemantique(c.page);
  const lireAccepter = await chercher(c.page, new RegExp(souple(T('attente.lireEtAccepter'))));
  noter(lireAccepter !== null, 'portail : « Lire et accepter nos conditions »');
  await p.capture(c, 'portail_lire_accepter');
  if (lireAccepter) { await lireAccepter.click(); await c.page.waitForTimeout(4000); await activerSemantique(c.page); }
  noter(c.page.url().includes('/attente/cadre'), 'le portail mene au cadre, pas aux accords', c.page.url().replace(/^.*#/, ''));
  const ligneTest = arabe ? 'النقطة التجريبية الأولى' : 'premier point de test';
  noter(await chercher(c.page, new RegExp(echapper(ligneTest))) !== null, `le texte publie s'affiche (${arabe ? 'arabe' : 'francais'})`);
  await ouvrir(c.page, '/#/attente/cadre'); await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  await p.capture(c, 'cadre_texte');

  // 3. Accepter.
  const caseAccord = await chercher(c.page, new RegExp(souple(T('recrutement.cadre.caseAccord').slice(0, 25))));
  noter(caseAccord !== null, 'la case d\'accord est la');
  if (caseAccord) { await caseAccord.click(); await c.page.waitForTimeout(800); }
  const accepter = await chercher(c.page, new RegExp(souple(T('recrutement.cadre.accepter'))));
  noter(accepter !== null, 'le bouton « Accepter le cadre » est la');
  await p.capture(c, 'cadre_case_cochee');
  if (accepter) { await accepter.click(); await c.page.waitForTimeout(4000); await activerSemantique(c.page); }
  noter(un(`select count(*) from public.contract_acceptances where profile_id = '${uid}'
             and contract_kind = 'teacher_religious_framework' and version = '${VERSION}'`) === '1',
  'le serveur a enregistre l\'accord a la version publiee (policy existante)');
  const completer = await chercher(c.page, new RegExp(souple(T('recrutement.portail.completer'))));
  noter(completer !== null, 'apres acceptation : « Completer ma candidature »', completer ? '' : (await arbre(c.page)).slice(0, 300));
  await p.capture(c, 'cadre_accepte');
  if (completer) { await completer.click(); await c.page.waitForTimeout(4000); }
  noter(c.page.url().includes('/attente/candidature'), '« Completer » ouvre le questionnaire', c.page.url().replace(/^.*#/, ''));
  await p.capture(c, 'questionnaire');

  // Retour au portail : plus de « Lire et accepter », la suite est « Completer ».
  await ouvrir(c.page, '/#/attente'); await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  noter(await trouver(c.page, new RegExp(souple(T('attente.lireEtAccepter'))), { delai: 2000 }) === null,
    'portail : plus de « Lire et accepter » (plus de boucle)');
  noter(await chercher(c.page, new RegExp(souple(T('recrutement.portail.completer')))) !== null,
    'portail : « Completer ma candidature »');
  await p.capture(c, 'portail_completer');

  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
