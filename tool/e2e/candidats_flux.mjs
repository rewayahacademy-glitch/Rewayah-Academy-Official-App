// CANDIDATS-FLUX (PLAN-LOTS §7 rang 22 k, 06/11/2026) : sur la pile LOCALE
// seulement (jamais un aperçu Vercel, jamais la production, G5 et B7).
//
//   1. amorce SQL locale : une direction super administratrice (homme) avec
//      un second facteur vérifié, la catégorie « recrutement » non essentielle
//      comme en production, un désinscrit du recrutement, un message d'attente
//      déjà reçu en anglais à une adresse ;
//   2. au bureau (1440, FR) : Candidatures, « Importer les formulaires », le
//      code de vérification demandé au geste, le dépôt d'un CSV de 23 lignes
//      (20 hommes, dont un nom en arabe, un doublon de courriel, un désinscrit,
//      une femme), les huit pas jusqu'au rapport ;
//   3. le même fichier rejoué : rien d'ajouté (rejouable sans doublon) ;
//   4. « Prévenir par e-mail » : le réglage passe à 15 par jour, l'envoi met
//      20 invitations en file (le désinscrit et la femme exclus) ;
//   5. la vraie file (tâche chaque minute, fonction courriels-envoi, Mailpit) :
//      15 le premier jour ; 24 heures simulées dans la base locale ; les 5
//      dernières le lendemain ; jamais deux messages à la même adresse ; la
//      langue de chacun (anglais, arabe, français) ;
//   6. au téléphone (390) en arabe et au bureau en arabe, au téléphone en
//      français : la feuille « Prévenir » et la page d'import.
//
// Usage : node tool/e2e/candidats_flux.mjs
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, MDP, MAILPIT, trouverTexte } from './commun.mjs';

const p = await parcours('CANDIDATS-FLUX : import, Prévenir, file étalée à 15 par jour', 'candidats-flux');
const manque = [];
const un = (q) => sql(q).split('\n')[0].trim();
const tampon = String(Date.now()).slice(-6);
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');

function totp(cle, decalage = 0) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const c of cle.replace(/[\s=]/g, '').toUpperCase()) bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
  const octets = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const compteur = Buffer.alloc(8);
  compteur.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000) + decalage));
  const h = crypto.createHmac('sha1', octets).update(compteur).digest();
  const o = h[h.length - 1] & 0xf;
  return String((h.readUInt32BE(o) & 0x7fffffff) % 1000000).padStart(6, '0');
}

function controle(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK' : 'ROUGE'} ${quoi}${detail ? ` : ${detail}` : ''}`);
  if (!ok) manque.push(quoi);
  return ok;
}

async function toucher(a, motif, quoi, options = {}) {
  const e = await trouver(a.page, motif, { delai: 15000, ...options });
  if (!e) { manque.push(`${a.role} : ${quoi} absent`); p.dire(`[${a.role}] ${quoi} ABSENT ; ${await lus(a.page, 70)}`); return false; }
  await amenerEnVue(a.page, e);
  await e.click();
  await a.page.waitForTimeout(options.pause ?? 2500);
  await activerSemantique(a.page);
  return true;
}

async function voir(a, motif, quoi, delai = 15000) {
  const t = await trouverTexte(a.page, motif, delai);
  p.dire(`[${a.role}] ${quoi} : ${t ? 'vu' : 'ABSENT'}`);
  if (!t) { manque.push(`${a.role} : ${quoi}`); p.dire(`   lus : ${(await lus(a.page, 90)).slice(0, 1500)}`); }
  return Boolean(t);
}

/// Le bouton d'un etat systeme (« Saisir mon code ») : l'arbre d'accessibilite
/// rend la carte et son action en un seul noeud « button » (constat consigne au
/// rendu) ; on touche l'action la ou elle est dessinee, en bas au bord de fin.
async function actionDeCarte(a, motif, quoi, { rtl = false } = {}) {
  const e = await trouver(a.page, motif, { delai: 12000, role: 'button' });
  if (!e) { manque.push(`${a.role} : ${quoi} absent`); p.dire(`[${a.role}] ${quoi} ABSENT`); return false; }
  await amenerEnVue(a.page, e);
  const b = await e.boundingBox();
  const x = rtl ? b.x + 16 + 50 : b.x + b.width - 16 - 50;
  await a.page.mouse.click(x, b.y + b.height - 16 - 22);
  await a.page.waitForTimeout(2500);
  await activerSemantique(a.page);
  p.dire(`[${a.role}] ${quoi} : touché (action de la carte)`);
  return true;
}

/// Amene en vue le texte cherche avant la capture : la capture montre ce
/// qu'elle pretend montrer (L2).
async function centrerSur(a, motif) {
  const e = await trouver(a.page, motif, { delai: 4000 });
  if (e) await amenerEnVue(a.page, e);
  await a.page.waitForTimeout(600);
}

// --- 1. Amorce locale -------------------------------------------------------
const SECRET = 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP';
const courrielDir = `e2e.flux.${tampon}@example.com`;
const idDir = un(`with u as (
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    '${courrielDir}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
  returning id),
i as (insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
  select gen_random_uuid(), u.id, u.id::text, jsonb_build_object('sub', u.id::text, 'email', '${courrielDir}', 'email_verified', true),
         'email', now(), now(), now() from u returning user_id)
select id from u`);
sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  values ('${idDir}', 'E2E-FLUX-${tampon}', 'admin', 'Direction', 'Flux${tampon}', 'active', 'male')`);
sql(`insert into private.super_admin_kyc (profile_id) values ('${idDir}') on conflict do nothing`);
sql(`insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret)
  values (gen_random_uuid(), '${idDir}', 'e2e', 'totp', 'verified', now(), now(), '${SECRET}')`);
sql(`update public.app_config set value = 'true'::jsonb
  where key in ('kyc_exception_super_admin', 'candidatures.inscription_publique_ouverte')`);
// Comme en production depuis le 25/10/2026.
sql(`update public.courriel_categories set essentielle = false where code = 'recrutement'`);
// Le reglage repart du defaut ; la direction le changera par l'ecran.
sql(`update public.app_config set value = '300'::jsonb where key = 'courriels.non_essentiels_par_jour'`);
const A = (n) => `flux${tampon}.m${String(n).padStart(2, '0')}@example.com`;
const DESINSCRIT = `flux${tampon}.desinscrit@example.com`;
const FEMME = `flux${tampon}.f01@example.com`;
sql(`insert into public.courriel_desinscriptions (adresse, categorie) values ('${DESINSCRIT}', 'recrutement')`);
// Le message d'attente du 25/10, deja parti en anglais a m02 (historique : il
// ne repart pas et ne compte pas dans le plafond du jour).
sql(`select public.courriel_enfiler('recrutement', 'attente_candidat', '${A(2)}', NULL,
  '{"langue": "en"}'::jsonb, 'candidat_attente:${A(2)}', 'manuel', NULL)`);
sql(`update public.courriels_sortants set statut = 'envoye', envoye_le = now() - interval '12 days',
  reserve_le = now() - interval '12 days' where destinataire_adresse = '${A(2)}'`);
p.dire(`Amorce : direction super administratrice ${courrielDir} (${idDir}), facteur vérifié : `
  + un(`select count(*) from auth.mfa_factors where user_id = '${idDir}' and status = 'verified'`));

// --- Le fichier -------------------------------------------------------------
const TITRES = ['Horodateur', 'هل أنت', 'الاسم الكامل', 'رقم الواتساب مع رمز الدولة', 'ما هي لغتك الأم',
  'بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه', 'ما مستواك في حفظ القرآن',
  'هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة', 'هل لديك خبرة في تعليم المبتدئين القراءة',
  'هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة', 'كم ساعة في الأسبوع تستطيع التدريس بانتظام',
  'متى تستطيع أن تبدأ', 'أوافق على أن يتصل بي فريق المشروع عبر واتساب', 'البريد الألكتروني'];
const ligne = (h, genre, nom, tel, courriel) => [h, genre, nom, tel, 'الفرنسية', 'الفرنسية', 'حفظت القرآن كله',
  'نعم', 'نعم', 'جاهز في أي وقت من اليوم', 'من 6 إلى 10', 'يمكن لي البدء فورا', 'أوافق', courriel]
  .map((c) => (c.includes(',') ? `"${c}"` : c)).join(',');
const lignes = [TITRES.join(',')];
for (let n = 1; n <= 20; n++) {
  const nom = n === 3 ? 'عبد الله يوسف' : `Candidat Flux ${n}`;
  lignes.push(ligne(`14/10/2026 ${String(8 + Math.floor(n / 4)).padStart(2, '0')}:${String((n * 7) % 60).padStart(2, '0')}:00`,
    'ذكر', nom, `+33600${tampon}${String(n).padStart(2, '0')}`.slice(0, 14), A(n)));
}
// Le doublon : m01 a repondu une seconde fois, plus tard.
lignes.push(ligne('16/10/2026 10:00:00', 'ذكر', 'Candidat Flux 1 bis', `+33611${tampon}01`, A(1)));
lignes.push(ligne('15/10/2026 09:00:00', 'ذكر', 'Candidat Desinscrit', `+33622${tampon}01`, DESINSCRIT));
lignes.push(ligne('15/10/2026 09:30:00', 'أنثى', 'Candidate Flux', `+33633${tampon}01`, FEMME));
const dossierCsv = fs.mkdtempSync(path.join(os.tmpdir(), 'flux-csv-'));
const fichier = path.join(dossierCsv, 'Candidature enseignants Rewayah (réponses) - Réponses au formulaire 1.csv');
fs.writeFileSync(fichier, lignes.join('\r\n') + '\r\n');
p.dire(`Fichier : ${lignes.length - 1} lignes (20 hommes, 1 doublon, 1 désinscrit, 1 femme)`);

async function codeDeVerification(a) {
  await voir(a, /Code de vérification/, 'feuille « Code de vérification »');
  const champ = a.page.locator('input:not([disabled]), textarea:not([disabled])').last();
  await champ.waitFor({ state: 'visible', timeout: 10000 });
  await amenerEnVue(a.page, champ);
  await champ.click(); await a.page.waitForTimeout(400);
  await a.page.keyboard.type(totp(SECRET), { delay: 60 });
  await toucher(a, /^Confirmer le code et continuer$/, '« Confirmer le code et continuer »', { role: 'button', pause: 6000 });
}

async function importer(a, { premier }) {
  // Le selecteur de fichier du navigateur : Playwright repond a sa place.
  // Le selecteur de file_picker (web) prend la fenetre du choix pilotee par
  // Playwright pour une annulation : l'<input type=file> recoit le fichier au
  // moment ou l'application l'ouvre, comme si la personne l'avait choisi.
  await a.page.evaluate(({ nom, texte }) => {
    window.__fichierE2E = { nom, texte };
    if (window.__clicFichierPatche) return;
    window.__clicFichierPatche = true;
    const origine = HTMLInputElement.prototype.click;
    HTMLInputElement.prototype.click = function clic() {
      const f = window.__fichierE2E;
      if (this.type === 'file' && f) {
        window.__ouvertE2E = true;
        const dt = new DataTransfer();
        dt.items.add(new File([f.texte], f.nom, { type: 'text/csv' }));
        this.files = dt.files;
        setTimeout(() => {
          this.dispatchEvent(new Event('input', { bubbles: true }));
          this.dispatchEvent(new Event('change', { bubbles: true }));
        }, 50);
        return undefined;
      }
      return origine.call(this);
    };
  }, { nom: path.basename(fichier), texte: fs.readFileSync(fichier, 'utf8') });
  const carte = await trouver(a.page, /Choisir un fichier CSV|Choisir un autre fichier/, { delai: 4000 });
  if (carte) { await amenerEnVue(a.page, carte); await carte.click(); }
  await a.page.waitForTimeout(4000); await activerSemantique(a.page);
  const ouvert = await a.page.evaluate(() => window.__ouvertE2E === true);
  if (!ouvert) { manque.push('sélecteur de fichier non ouvert'); p.dire('sélecteur de fichier non ouvert'); return; }
  if (process.env.E2E_ARRET_DEPOT) { await p.capture(a, 'debug_depot'); throw new Error(`arret demande ; ${await lus(a.page, 60)}`); }
  await voir(a, /23 lignes de réponses dans ce fichier/, 'dépôt : 23 lignes lues');
  if (premier) { await centrerSur(a, /Classeur/); await p.capture(a, '1440_import_1_depot'); }
  await toucher(a, /^Analyser le fichier$/, '« Analyser le fichier »', { role: 'button', pause: 6000 });
  if (premier) await p.capture(a, '1440_import_2_apercu');
  for (let pas = 0; pas < 6; pas++) {
    if (await trouverTexte(a.page, /Importer ces réponses maintenant/, 1500)) break;
    if (await trouverTexte(a.page, /Ces nombres sont-ils ceux que vous attendiez/, 1500)) {
      if (premier) await p.capture(a, '1440_import_5_comptes');
      await toucher(a, /Aucun décompte à comparer/, 'carte « Aucun décompte à comparer »', { pause: 1200 });
    }
    if (premier && await trouverTexte(a.page, /Ces lignes viennent-elles de la même personne/, 1500)) {
      await p.capture(a, '1440_import_4_doublons');
    }
    const suite = await trouver(a.page, /^Continuer$/, { delai: 6000, role: 'button' });
    if (!suite) break;
    await amenerEnVue(a.page, suite); await suite.click();
    await a.page.waitForTimeout(3000); await activerSemantique(a.page);
  }
  await voir(a, /Importer ces réponses maintenant/, 'pas « Confirmation »');
  if (premier) await p.capture(a, '1440_import_6_confirmation');
  await toucher(a, /^Importer les réponses$/, '« Importer les réponses »', { role: 'button', pause: 7000 });
  await voir(a, /Import terminé/, 'rapport « Import terminé »');
  await p.capture(a, premier ? '1440_import_7_rapport' : '1440_import_rejoue_rapport');
}

let code = 1;
try {
  // --- 2. Import, au bureau, en francais ------------------------------------
  const d = await p.contexte('direction', { vue: { width: 1440, height: 900 } });
  await connecter(d.page, courrielDir);
  if (await d.page.locator('input[type=password]').count()) await connecter(d.page, courrielDir);
  await ouvrir(d.page, '/#/admin/personnes/candidatures');
  await d.page.waitForTimeout(3000); await activerSemantique(d.page);
  await voir(d, /Importer les formulaires/, 'lien « Importer les formulaires » sur la page Candidatures');
  await voir(d, /Prévenir par e-mail/, 'lien « Prévenir par e-mail » sur la page Candidatures');
  await p.capture(d, '1440_candidatures_liens');
  await toucher(d, /^Importer les formulaires/, 'lien « Importer les formulaires »', { pause: 4000 });
  await voir(d, /Saisir mon code/, 'double vérification demandée au geste (« Saisir mon code »)');
  await p.capture(d, '1440_import_0_double_verification');
  await actionDeCarte(d, /Saisir mon code/, '« Saisir mon code »');
  await codeDeVerification(d);
  controle(un(`select count(*) from auth.users where id = '${idDir}'`) === '1', 'session gardée (aucune déconnexion)');
  await importer(d, { premier: true });
  const actives = () => un(`select count(*) from public.formulaires_reponses where courriel like 'flux${tampon}.%' and etat = 'active'`);
  const toutes = () => un(`select count(*) from public.formulaires_reponses where courriel like 'flux${tampon}.%'`);
  const apres1 = { actives: actives(), toutes: toutes() };
  p.dire(`Base locale après l'import : ${apres1.toutes} réponses, ${apres1.actives} actives`);
  controle(apres1.actives === '22', 'une réponse active par personne (20 hommes + désinscrit + femme)', apres1.actives);
  controle(un(`select count(distinct courriel) from public.formulaires_reponses where courriel like 'flux${tampon}.%' and etat = 'active'`) === '22',
    'le doublon de m01 ne fait qu\'une personne active');

  // --- 3. Le meme fichier rejoue : rien d'ajoute ----------------------------
  await toucher(d, /^Importer un autre fichier$/, '« Importer un autre fichier »', { pause: 3000 });
  await importer(d, { premier: false });
  const apres2 = { actives: actives(), toutes: toutes() };
  controle(apres2.actives === apres1.actives && apres2.toutes === apres1.toutes,
    'fichier rejoué : aucune réponse ajoutée', `${apres1.toutes} -> ${apres2.toutes}`);

  // --- 4. Prevenir : reglage a 15, envoi -----------------------------------
  await ouvrir(d.page, '/#/admin/personnes/candidatures');
  await d.page.waitForTimeout(3000); await activerSemantique(d.page);
  await toucher(d, /^Prévenir par e-mail/, 'lien « Prévenir par e-mail »', { pause: 4000 });
  await voir(d, /20 personnes à prévenir/, '20 personnes à prévenir (hommes, doublon compté une fois)');
  await voir(d, /1 personne a demandé à ne plus recevoir/, 'le désinscrit compté à part');
  await voir(d, /au plus 300 messages de ce type partent chaque jour/, 'rythme : 300 par jour (défaut)');
  await centrerSur(d, /personnes à prévenir/);
  await p.capture(d, '1440_prevenir_1_apercu');
  const champ = await trouver(d.page, /Messages de ce type par jour/, { delai: 8000, role: 'textbox' });
  if (!champ) { manque.push('champ du réglage absent'); } else {
    await amenerEnVue(d.page, champ); await champ.click(); await d.page.waitForTimeout(400);
    await d.page.keyboard.press('Control+A'); await d.page.keyboard.type('15', { delay: 40 });
  }
  await toucher(d, /^Enregistrer le réglage/, '« Enregistrer le réglage »', { pause: 3000 });
  await voir(d, /Réglage enregistré\s*:\s*15 messages par jour/, 'réglage enregistré à 15');
  controle(un(`select value from public.app_config where key = 'courriels.non_essentiels_par_jour'`) === '15', 'base locale : réglage à 15');
  await centrerSur(d, /Réglage enregistré/);
  await p.capture(d, '1440_prevenir_2_reglage_15');
  await toucher(d, /^Envoyer le lien à 20 personnes$/, '« Envoyer le lien à 20 personnes »', { role: 'button', pause: 5000 });
  await voir(d, /20 messages mis en file/, '« 20 messages mis en file »');
  await voir(d, /au plus 15 messages de ce type partent chaque jour/, 'rythme dit après l\'envoi : 15 par jour');
  await centrerSur(d, /mis en file/);
  await p.capture(d, '1440_prevenir_3_envoye');
  const enFile = un(`select count(*) from public.courriels_sortants where modele = 'lien_inscription' and destinataire_adresse like 'flux${tampon}.%'`);
  controle(enFile === '20', '20 invitations en file', enFile);
  controle(un(`select count(*) from public.courriels_sortants where modele = 'lien_inscription' and destinataire_adresse in ('${DESINSCRIT}', '${FEMME}')`) === '0',
    'ni le désinscrit ni la femme (autre côté) en file');
  controle(un(`select count(*) from public.courriels_sortants where modele = 'lien_inscription' and destinataire_adresse like 'flux${tampon}.%'
    and cle_idempotence <> 'lien_inscription:' || destinataire_adresse`) === '0', 'clé lien_inscription:<adresse> pour chacune');
  const langues = sql(`select destinataire_adresse || '=' || langue from public.courriels_sortants where modele = 'lien_inscription'
    and destinataire_adresse in ('${A(1)}', '${A(2)}', '${A(3)}') order by 1`).replace(/\n/g, ' ; ');
  controle(langues === `${A(1)}=fr ; ${A(2)}=en ; ${A(3)}=ar`, 'langue de chacun (fr, en du message d\'attente, ar du nom)', langues);
  // Un second envoi ne met rien de plus en file.
  await toucher(d, /^Fermer$/, '« Fermer »', { role: 'button', pause: 1500 });
  await toucher(d, /^Prévenir par e-mail/, 'lien « Prévenir par e-mail » (seconde fois)', { pause: 4000 });
  await voir(d, /Tout le monde est déjà prévenu/, 'seconde ouverture : tout le monde est déjà prévenu, aucun bouton d\'envoi');
  await voir(d, /attendent leur tour|Aucun message n'attend son tour/, 'seconde ouverture : la file se lit');
  await p.capture(d, '1440_prevenir_4_deja_prevenus');
  await d.ctx.close();

  // --- 5. La vraie file : 15, puis le lendemain 5 --------------------------
  async function messagesMailpit() {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:flux${tampon}`)}&limit=200`)).json();
    return (r.messages ?? []).map((m) => ({ a: (m.To ?? []).map((x) => x.Address).join(','), sujet: m.Subject }));
  }
  const attendre = async (cond, ms) => { const fin = Date.now() + ms; while (Date.now() < fin) { if (await cond()) return true; await new Promise((r) => setTimeout(r, 5000)); } return false; };
  const partis = () => un(`select count(*) from public.courriels_sortants where modele = 'lien_inscription'
    and destinataire_adresse like 'flux${tampon}.%' and statut = 'envoye'`);
  await attendre(async () => partis() === '15', 150000);
  await new Promise((r) => setTimeout(r, 70000)); // une minute de plus : rien ne doit partir
  const jour1 = partis();
  const m1 = await messagesMailpit();
  controle(jour1 === '15', 'jour 1 : 15 invitations parties, pas une de plus après une minute d\'attente', jour1);
  p.dire(`Mailpit jour 1 : ${m1.length} messages ; en attente : ${un(`select count(*) from public.courriels_sortants where modele = 'lien_inscription' and destinataire_adresse like 'flux${tampon}.%' and statut = 'en_attente'`)}`);
  // 24 heures passent (base locale) : les reservations de la veille sortent de la fenetre.
  sql(`update public.courriels_sortants set reserve_le = reserve_le - interval '25 hours' where reserve_le is not null`);
  await attendre(async () => partis() === '20', 150000);
  const jour2 = partis();
  const m2 = await messagesMailpit();
  const parAdresse = {};
  for (const m of m2) parAdresse[m.a] = (parAdresse[m.a] ?? 0) + 1;
  const doubles = Object.entries(parAdresse).filter(([, n]) => n > 1);
  controle(jour2 === '20', 'jour 2 : les 5 dernières parties', jour2);
  controle(m2.length === 20 && doubles.length === 0, 'Mailpit : 20 messages, 20 adresses, aucune deux fois',
    `${m2.length} messages, doubles : ${JSON.stringify(doubles)}`);
  controle(!m2.some((m) => m.a === DESINSCRIT || m.a === FEMME), 'Mailpit : rien pour le désinscrit ni pour la femme');
  const sujets = [...new Set(m2.map((m) => m.sujet))];
  p.dire(`Sujets reçus : ${sujets.join(' | ')}`);
  controle(sujets.some((s) => /créez votre compte/.test(s)), 'sujet français « créez votre compte » reçu');

  // --- 6. Telephone et arabe -----------------------------------------------
  for (const [vue, langue, nom] of [[{ width: 390, height: 844 }, 'ar-SA', '390_ar'],
    [{ width: 1440, height: 900 }, 'ar-SA', '1440_ar'], [{ width: 390, height: 844 }, 'fr-FR', '390_fr']]) {
    const t = await p.contexte('direction', { vue, langue });
    await connecter(t.page, courrielDir);
    if (await t.page.locator('input[type=password]').count()) await connecter(t.page, courrielDir);
    await ouvrir(t.page, '/#/admin/personnes/candidatures');
    await t.page.waitForTimeout(3000); await activerSemantique(t.page);
    const ar = langue.startsWith('ar');
    await toucher(t, ar ? /إبلاغ الأشخاص بالبريد الإلكتروني/ : /^Prévenir par e-mail/, `${nom} : lien Prévenir`, { pause: 4000 });
    await voir(t, ar ? /عدد الرسائل من هذا النوع في اليوم/ : /Messages de ce type par jour/, `${nom} : le réglage se lit`);
    await centrerSur(t, ar ? /تُرسَل كل يوم/ : /partent chaque jour/);
    await p.capture(t, `${nom}_prevenir`);
    // Comme une personne : la feuille se ferme avant d'aller ailleurs.
    await t.page.keyboard.press('Escape'); await t.page.waitForTimeout(1200);
    await ouvrir(t.page, '/#/admin/personnes/candidatures');
    await t.page.waitForTimeout(3000); await activerSemantique(t.page);
    await toucher(t, ar ? /استيراد/ : /^Importer les formulaires/, `${nom} : lien d'import`, { pause: 4000 });
    if (await trouver(t.page, ar ? /إدخال رمزي/ : /Saisir mon code/, { delai: 5000 })) {
      await p.capture(t, `${nom}_import_double_verification`);
      await actionDeCarte(t, ar ? /إدخال رمزي/ : /Saisir mon code/, `${nom} : saisir le code`, { rtl: ar });
      await new Promise((r) => setTimeout(r, 30000 - (Date.now() % 30000) + 1500));
      const champ = t.page.locator('input:not([disabled]), textarea:not([disabled])').last();
      await champ.click(); await t.page.keyboard.type(totp(SECRET), { delay: 60 });
      await toucher(t, ar ? /تأكيد/ : /^Confirmer le code et continuer$/, `${nom} : confirmer le code`, { role: 'button', pause: 6000 });
    }
    await p.capture(t, `${nom}_import_depot`);
    await t.ctx.close();
  }

  code = await p.fin(manque.length === 0 ? 'vert' : 'rouge', manque.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
