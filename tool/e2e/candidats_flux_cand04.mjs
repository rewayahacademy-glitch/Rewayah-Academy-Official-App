// CANDIDATS-FLUX, PR B (CAND-04, 06/11/2026) : sur la pile LOCALE seulement
// (jamais un apercu Vercel, jamais la production, G5 et B7).
//
// Un candidat arrive par le lien public (`/inscription`, celui du courriel
// « lien_inscription »), sans code :
//   1. « J'ai un code d'invitation », adresse, lien recu dans Mailpit (le
//      courriel est confirme par ce lien) ;
//   2. « Deposer ma candidature » (l'inscription sans code, ouverte dans la base
//      LOCALE seulement), identite, genre, telephone (indicatif cherche), le
//      recapitulatif : langue de l'application, case de confidentialite,
//      « Envoyer ma candidature » ;
//   3. la Salle d'examen (questionnaire salle-examen-2) : langue maternelle
//      « Malinke (mandinka) », puis langues d'explication « Arabe » puis
//      « Malinke (mandinka) », chacune avec « Rewayah propose des cours dans
//      cette langue » ;
//   4. controles dans la base locale : la porte (lien public), la version de
//      confidentialite acceptee (2026-11-v1), la langue, les reponses.
//
// Quatre passages : 390 et 1440 de large, en francais et en arabe (langue du
// navigateur, puis langue choisie au recapitulatif).
//
// Prealable : la cle `candidatures.inscription_publique_ouverte` est ouverte
// ICI, dans la base locale ; en production elle reste fermee (le pilote la
// basculera apres la mise en production).
//
// Usage : node tool/e2e/candidats_flux_cand04.mjs
import fs from 'node:fs';
import { parcours, ouvrir, libelles, taper, trouver, trouverTexte, dernierLien,
  activerSemantique, amenerEnVue, sql, DEPOT } from './commun.mjs';

const p = await parcours('CANDIDATS-FLUX PR B : candidat venu du lien public, Arabe puis Malinké', 'candidats-flux-cand04');
const manque = [];
const un = (q) => sql(q).split('\n')[0].trim();
const lus = async (page, n = 70) => (await libelles(page)).slice(0, n).join(' | ');
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const I18N = {
  fr: JSON.parse(fs.readFileSync(`${DEPOT}/assets/i18n/fr.i18n.json`, 'utf8')),
  ar: JSON.parse(fs.readFileSync(`${DEPOT}/assets/i18n/ar.i18n.json`, 'utf8')),
};
const texte = (langue, cle) => cle.split('.').reduce((x, k) => x[k], I18N[langue]);
/// Debut exact d'un libelle (l'arbre d'accessibilite y ajoute la description).
const debut = (langue, cle) => new RegExp(`^${echapper(texte(langue, cle))}`);
const exact = (langue, cle) => new RegExp(`^${echapper(texte(langue, cle))}$`);

function controle(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK' : 'ROUGE'} ${quoi}${detail ? ` : ${detail}` : ''}`);
  if (!ok) manque.push(quoi);
  return ok;
}

async function toucher(a, motif, quoi, options = {}) {
  const e = await trouver(a.page, motif, { delai: 15000, ...options });
  if (!e) {
    manque.push(`${a.role} : ${quoi} absent`);
    p.dire(`[${a.role}] ${quoi} ABSENT ; ${await lus(a.page)}`);
    throw new Error(`${quoi} absent`);
  }
  await amenerEnVue(a.page, e);
  await e.click();
  await a.page.waitForTimeout(options.pause ?? 2000);
  await activerSemantique(a.page);
}

async function etape(a, nom) {
  await activerSemantique(a.page);
  p.dire(`[${a.role}] ${nom} : ${a.page.url().replace(/^.*#/, '#')}`);
  await p.capture(a, nom);
}

// --- Amorce locale ----------------------------------------------------------
sql(`update public.app_config set value = 'true'::jsonb where key = 'candidatures.inscription_publique_ouverte'`);
controle(un(`select value #>> '{}' from public.app_config where key = 'candidatures.confidentialite_version'`) === '2026-11-v1',
  'réglage serveur de confidentialité à 2026-11-v1 (migration 20261110310000)');

async function passage({ largeur, langue }) {
  const telephone = largeur < 600;
  const a = await p.contexte(`${largeur}_${langue}`, {
    vue: telephone ? { width: 390, height: 844 } : { width: 1440, height: 900 },
    langue: langue === 'ar' ? 'ar-SA' : 'fr-FR',
  });
  const courriel = `cand04.${largeur}.${langue}.${Date.now() % 1000000}@example.com`;
  p.dire(`== Passage ${largeur} ${langue.toUpperCase()} : ${courriel}`);

  // 1. Le lien public, puis le compte (lien recu, courriel confirme).
  await ouvrir(a.page, '/inscription');
  await etape(a, 'lien_public');
  await toucher(a, exact(langue, 'inscription.usage.enseignant'), 'J\'ai un code d\'invitation');
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await etape(a, 'compte');
  await toucher(a, exact(langue, 'connexion.envoyerLienCreation'), 'Recevoir le lien d\'inscription', { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  controle(Boolean(recu?.lien), `${largeur} ${langue} : lien de confirmation reçu dans Mailpit`, recu?.sujet ?? '');
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  controle(un(`select (email_confirmed_at is not null)::text from auth.users where email = '${courriel}'`) === 'true',
    `${largeur} ${langue} : courriel confirmé`);

  // 2. Sans code : « Deposer ma candidature ».
  await etape(a, 'code');
  await toucher(a, exact(langue, 'inscription.usage.deposerCandidature'), 'Déposer ma candidature');
  await etape(a, 'identite');
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.prenom')}"]`, 'Ibrahima');
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.nom')}"]`, 'Keita');
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (identité)');
  await etape(a, 'genre');
  await toucher(a, debut(langue, 'inscription.genreHomme'), 'Un homme', { role: 'radio', pause: 800 });
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (genre)');
  await etape(a, 'telephone');
  await toucher(a, debut(langue, 'inscription.telephone.choisirPays'), 'Choisir votre pays', { pause: 1500 });
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.telephone.rechercherPays')}"]`, '+224');
  await a.page.waitForTimeout(800);
  await etape(a, 'pays');
  await toucher(a, /\+224/, 'Guinée (+224)', { role: 'button', pause: 1200 });
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.telephone.numeroCourt')}"]`, '622 12 34 56');
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (téléphone)');
  await etape(a, 'recapitulatif');
  controle(Boolean(await trouverTexte(a.page, /2026-11-v1/, 5000)), `${largeur} ${langue} : version 2026-11-v1 affichée au récapitulatif`);
  // La langue de l'application, choisie ici : celle du passage.
  await toucher(a, debut(langue, langue === 'ar' ? 'inscription.langue.arabe' : 'inscription.langue.francais'),
    'langue de l\'application', { role: 'radio', pause: 1500 });
  await toucher(a, exact(langue, 'inscription.confidentialite.case'), 'case de confidentialité', { role: 'checkbox', pause: 800 });
  await etape(a, 'recapitulatif_coche');
  await toucher(a, exact(langue, 'inscription.candidat.envoyer'), 'Envoyer ma candidature', { pause: 6000 });
  await etape(a, 'salle_examen');
  controle(a.page.url().includes('/attente'), `${largeur} ${langue} : arrivée en Salle d'examen (/attente)`, a.page.url());

  // 3. Le questionnaire salle-examen-2.
  await toucher(a, exact(langue, 'recrutement.portail.completer'), 'Compléter ma candidature', { pause: 3000 });
  for (let k = 0; k < 3; k++) {
    await etape(a, `presentation_${k + 1}`);
    await toucher(a, exact(langue, 'commun.continuer'), `Continuer (présentation ${k + 1})`);
  }
  await etape(a, 'langue_maternelle');
  await toucher(a, exact(langue, 'candidatsFlux.langues.man'), 'Malinké (langue maternelle)', { role: 'radio', pause: 800 });
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (langue maternelle)');
  await etape(a, 'langues_explication');
  const propose = texte(langue, 'recrutement.parcours.langues.dansReferentiel');
  for (const [cle, nom] of [['recrutement.parcours.langues.ar', 'Arabe'], ['candidatsFlux.langues.man', 'Malinké (mandinka)']]) {
    const motif = new RegExp(`^${echapper(texte(langue, cle))}\\.? ?${echapper(propose)}`);
    const carte = await trouver(a.page, motif, { delai: 8000, role: 'checkbox' });
    controle(Boolean(carte), `${largeur} ${langue} : « ${nom} » proposé avec « ${propose} »`);
    await toucher(a, debut(langue, cle), nom, { role: 'checkbox', pause: 800 });
    // La capture montre la carte cochee (L2).
    const cochee = await trouver(a.page, debut(langue, cle), { delai: 4000, role: 'checkbox' });
    controle((await cochee?.getAttribute('aria-checked')) === 'true', `${largeur} ${langue} : « ${nom} » coché`);
    if (cochee) {
      await amenerEnVue(a.page, cochee);
      const b = await cochee.boundingBox();
      const vue = a.page.viewportSize();
      if (b) {
        await a.page.mouse.move(vue.width * 0.6, vue.height / 2);
        await a.page.mouse.wheel(0, b.y - vue.height / 3);
      }
    }
    await a.page.waitForTimeout(700);
    await p.capture(a, `choisi_${nom.split(' ')[0]}`);
  }
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (langues d\'explication)', { pause: 3000 });
  await etape(a, 'apres_langues');

  // 4. La base locale.
  const id = un(`select id from auth.users where email = '${courriel}'`);
  const accord = un(`select version || '/' || porte from public.candidat_accords_confidentialite where profile_id = '${id}'`);
  controle(accord === '2026-11-v1/lien_public', `${largeur} ${langue} : accord de confidentialité 2026-11-v1, porte lien_public`, accord);
  const langueEnregistree = un(`select coalesce(langue, 'null') from public.candidatures where profile_id = '${id}'`);
  controle(langueEnregistree === langue, `${largeur} ${langue} : langue de la candidature`, langueEnregistree);
  const reponses = un(`select r.questionnaire_version || ' ' || (r.reponses -> 'langueMaternelle')::text || ' '
      || coalesce((r.reponses -> 'languesExplication')::text, 'null')
    from public.candidature_reponses r join public.candidatures c on c.id = r.candidature_id
    where c.profile_id = '${id}'`);
  // L'ordre enregistre est celui des cartes (man avant ar), pas celui des
  // touchers : on controle l'ensemble.
  const [version, maternelle, ...reste] = reponses.split(' ');
  const explication = JSON.parse(reste.join(' ') || 'null') ?? [];
  controle(version === 'salle-examen-2' && maternelle === '"man"'
      && explication.length === 2 && explication.includes('ar') && explication.includes('man'),
    `${largeur} ${langue} : réponses salle-examen-2, langue maternelle man, explication {ar, man}`, reponses);
  await a.ctx.close();
}

let echec = '';
for (const largeur of [390, 1440]) {
  for (const langue of ['fr', 'ar']) {
    try {
      await passage({ largeur, langue });
    } catch (e) {
      echec = echec || `${largeur} ${langue} : ${e.message}`;
      p.dire(`ARRET ${largeur} ${langue} : ${e.message}`);
    }
  }
}
// La base locale revient a l'etat de la production : la porte publique fermee.
sql(`update public.app_config set value = 'false'::jsonb where key = 'candidatures.inscription_publique_ouverte'`);
if (manque.length) p.dire(`Manques : ${manque.join(' ; ')}`);
process.exit(await p.fin(manque.length || echec ? 'rouge' : 'vert', echec || manque.join(' ; ')));
