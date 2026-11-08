// PHOTO-CANDIDATURE-FIGEE (07/11/2026), banc LOCAL seulement (jamais un
// apercu, jamais la production).
//   1. Une candidate (compte, dossier en cours et brouillon complet poses en
//      base locale, car les inscriptions de la pile sont fermees) depose
//      DEUX photos dans le seau photos_enseignants avec son propre jeton, pose
//      la premiere comme photo, donne l'accord de publication, et ENVOIE ses
//      reponses par la vraie RPC (envoyer_reponses_salle_examen).
//   2. La photo est figee dans le dossier (candidatures.photo_cle_figee).
//   3. Avec son jeton, la candidate ne peut PAS remplacer le fichier du
//      dossier (upsert refuse) ; elle remplace librement son autre photo, et
//      change sa photo d'affichage pour la seconde.
//   4. La direction ouvre la fiche de la candidature : le bloc « Photo
//      envoyee avec la candidature » charge la photo du DOSSIER (URL signee
//      de la premiere cle), jamais la photo d'affichage du jour.
// Usage : node tool/e2e/photo_figee.mjs [--bureau]
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, attendreTexte, activerSemantique, amenerEnVue, connecter, sql,
  API, MDP, COMPTES, DEPOT, TRAVAIL } from './commun.mjs';

const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const T = (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const souple = (s) => echapper(s).replace(/[\s  ]+/g, '\\s*');
const bureau = process.argv.includes('--bureau');
const statut = Object.fromEntries(fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => { const i = l.indexOf('='); return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')]; }));
const ANON = statut.ANON_KEY;
const SERVICE = statut.SERVICE_ROLE_KEY;
const un = (q) => sql(q).split('\n')[0].trim();

const p = await parcours(`PHOTO-FIGEE : la photo du dossier de candidature (${bureau ? '1440' : '390'})`,
  `photo-candidature-figee/robot-${bureau ? '1440' : '390'}`);
const rouges = [];
function noter(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}${detail ? ` (${detail})` : ''}`);
  if (!ok) rouges.push(quoi);
}
async function rpc(jeton, nom, corps = {}) {
  const r = await fetch(`${API}/rest/v1/rpc/${nom}`, {
    method: 'POST',
    headers: { apikey: ANON, Authorization: `Bearer ${jeton}`, 'content-type': 'application/json' },
    body: JSON.stringify(corps),
  });
  return { statut: r.status, corps: await r.json().catch(() => null) };
}
async function deposer(jeton, cle, fichier, remplacer = false) {
  const r = await fetch(`${API}/storage/v1/object/photos_enseignants/${cle}`, {
    method: 'POST',
    headers: { apikey: ANON, Authorization: `Bearer ${jeton}`, 'content-type': 'image/png',
      ...(remplacer ? { 'x-upsert': 'true' } : {}) },
    body: fs.readFileSync(fichier),
  });
  return { statut: r.status, corps: await r.text() };
}

let code = 1;
try {
  const ts = Date.now().toString(36);
  const courriel = `e2e-photo-figee-${ts}@example.com`;
  // 1. Le compte (admin de la pile : les inscriptions sont fermees).
  const cree = await (await fetch(`${API}/auth/v1/admin/users`, {
    method: 'POST',
    headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}`, 'content-type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP, email_confirm: true }),
  })).json();
  const uid = cree.id;
  if (!uid) throw new Error(`compte non cree : ${JSON.stringify(cree).slice(0, 200)}`);
  sql(`insert into public.profiles (id, role, first_name, last_name, account_status, gender)
         values ('${uid}', 'teacher', 'Mariam', 'Photo', 'pending_kyc', 'female')`);
  sql(`insert into public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
         values ('${uid}', 'GN', array['francais'], 40, 'pending', 'Africa/Conakry')`);
  sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
         values ('enseignant', '${uid}', 'female', 'Mariam Photo', 'prequalification', 'a_completer', 'en_cours', 'lien_public')`);
  const candidature = un(`select id from public.candidatures where profile_id = '${uid}'`);
  const reference = un(`select reference from public.candidatures where id = '${candidature}'`);
  p.dire(`Candidate ${courriel} (${uid}), dossier ${reference} (${candidature})`);
  const REPONSES = {
    langueMaternelle: 'man', languesExplication: ['ar', 'man'],
    niveauMemorisationDeclare: 'coran_entier', niveauLectureTajwid: 'tajwid_enseigne',
    riwayat: ['hafs', 'warsh'], ijazaPresentable: 'oui', experienceDebutants: 'oui',
    disponibilitesDeclarees: [{ jour: 1, debut: '20:00', fin: '22:00' }, { jour: 3, debut: '20:00', fin: '22:00' }],
    fuseauIana: 'Africa/Conakry', classesSouhaitees: '2', debutPossible: 'immediat',
    publics: ['6_9', 'adultes'], paysResidence: 'GN', paysVersement: 'SA', compteBancaire: true, operateurs: [],
  };
  sql(`insert into public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon)
       values ('${candidature}', 'salle-examen-2', '${JSON.stringify(REPONSES)}'::jsonb, 'candidat', true)`);

  // Le jeton de la candidate.
  const session = await (await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: ANON, 'content-type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  })).json();
  const jeton = session.access_token;
  noter(!!jeton, 'la candidate a une session');
  const moi = await rpc(jeton, 'photo_candidat_moi');
  noter(moi.corps === true, 'la candidate peut poser sa photo (photo_candidat_moi)', JSON.stringify(moi.corps));

  const cle1 = `${uid}/1.png`;
  const cle2 = `${uid}/2.png`;
  const d1 = await deposer(jeton, cle1, path.join(TRAVAIL, 'photo-figee-1.png'));
  const d2 = await deposer(jeton, cle2, path.join(TRAVAIL, 'photo-figee-2.png'));
  noter(d1.statut === 200 && d2.statut === 200, 'deux photos deposees avec son jeton', `${d1.statut} ${d2.statut}`);
  const pose = await rpc(jeton, 'poser_photo_candidat', { p_cle: cle1 });
  noter(pose.statut === 200, 'la premiere est sa photo', JSON.stringify(pose.corps).slice(0, 120));
  const accord = await rpc(jeton, 'accepter_accord_publication', { p_version: 'publication-2026-11-v1' });
  noter(accord.statut === 200, 'accord de publication donne', JSON.stringify(accord.corps).slice(0, 120));

  // Les engagements requis sur la pile (versions publiees), puis l'envoi. La
  // pile n'a pas de cadre religieux publie : une version de test, comme le
  // scenario SQL (base locale seulement).
  sql(`insert into public.contract_required_versions (contract_kind, version)
       select 'teacher_religious_framework', 'e2e-cadre-1'
        where not exists (select 1 from public.contract_required_versions where contract_kind = 'teacher_religious_framework')`);
  for (const ligne of sql(`select contract_kind || '|' || version from public.contract_required_versions
                            where contract_kind in ('teacher_religious_framework')`).split('\n').filter(Boolean)) {
    const [kind, version] = ligne.split('|');
    sql(`insert into public.contract_acceptances (profile_id, contract_kind, version) values ('${uid}', '${kind}', '${version}') on conflict do nothing`);
  }
  const cond = await rpc(jeton, 'conditions_remuneration_candidat');
  const version = Number(un(`select version from public.candidatures where id = '${candidature}'`));
  const envoi = await rpc(jeton, 'envoyer_reponses_salle_examen', {
    p_questionnaire_version: 'salle-examen-2', p_reponses: REPONSES, p_accord_remuneration: true,
    p_version_conditions: cond.corps?.version ?? null, p_version_attendue: version,
    p_cle_idempotence: `e2e-photo-figee-${ts}`,
  });
  noter(envoi.statut === 200 && !envoi.corps?.erreur, 'les reponses sont envoyees (vraie RPC)', JSON.stringify(envoi.corps).slice(0, 200));

  // 2. Figee.
  noter(un(`select photo_cle_figee from public.candidatures where id = '${candidature}'`) === cle1,
    'la photo de l\'envoi est figee dans le dossier', cle1);

  // 3. Le fichier du dossier ne se remplace pas ; l'autre, oui.
  const r1 = await deposer(jeton, cle1, path.join(TRAVAIL, 'photo-figee-2.png'), true);
  noter(r1.statut >= 400, 'remplacer le fichier du dossier est refuse (upsert)', `${r1.statut} ${r1.corps.slice(0, 80)}`);
  const r2 = await deposer(jeton, cle2, path.join(TRAVAIL, 'photo-figee-1.png'), true);
  noter(r2.statut === 200, 'remplacer son autre photo reste possible', `${r2.statut}`);
  const change = await rpc(jeton, 'poser_photo_candidat', { p_cle: cle2 });
  noter(change.statut === 200 && un(`select photo_storage_key from public.teacher_profiles where profile_id = '${uid}'`) === cle2,
    'la photo d\'affichage change librement');
  noter(un(`select photo_cle_figee from public.candidatures where id = '${candidature}'`) === cle1,
    'la photo du dossier, elle, ne change pas');

  // 4. La direction ouvre la fiche : la photo chargee est celle du dossier.
  const d = await p.contexte('direction', bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
  const urls = [];
  d.page.on('request', (r) => { if (r.url().includes('/storage/v1/object/sign/photos_enseignants/')) urls.push(r.url()); });
  await connecter(d.page, COMPTES.direction);
  await ouvrir(d.page, `/#/admin/personnes/candidatures/${encodeURIComponent(reference)}`);
  await d.page.waitForTimeout(6000); await activerSemantique(d.page);
  const bloc = await trouver(d.page, new RegExp(souple(T('admin.candidatures.detail.photo.titre'))), { delai: 10000 });
  noter(bloc !== null, 'la fiche montre « Photo envoyee avec la candidature »');
  if (bloc) await amenerEnVue(d.page, bloc);
  await d.page.waitForTimeout(2500);
  await p.capture(d, 'fiche_photo_du_dossier');
  noter(urls.some((u) => u.includes(`/${uid}/1.png`)), 'la photo chargee est celle du DOSSIER (1.png)', urls.map((u) => u.replace(/\?.*$/, '').split('/').slice(-2).join('/')).join(', ') || 'aucune');
  noter(!urls.some((u) => u.includes(`/${uid}/2.png`)), 'jamais la photo d\'affichage du jour (2.png)');
  noter(await attendreTexte(d.page, new RegExp(souple(T('admin.candidatures.detail.photo.figeeLe').split('{date}')[0])), 4000),
    'la fiche dit quand la photo a ete gardee');

  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
