// CAND-PHOTO (06/11/2026) : sur la pile LOCALE seulement (jamais un apercu
// Vercel, jamais la production, G5 et B7).
//
//   1. Un candidat arrive par le lien direct du courriel
//      (`/#/connexion?mode=creer&candidature=1`), cree son compte (lien recu
//      dans Mailpit), depose sa candidature sans code, arrive dans sa
//      candidature. Ses reponses sont amorcees dans la base locale (un
//      brouillon complet) pour aller droit au recapitulatif.
//   2. Au recapitulatif : « Votre photo », obligatoire, avec « Une photo avec
//      le niqab est acceptee » ; il choisit une photo (le selecteur du
//      navigateur repond a sa place) et l'envoie : la cle est posee dans
//      teacher_profiles.photo_storage_key, et l'objet existe dans le seau
//      photos_enseignants de la pile.
//   3. Au meme endroit, la carte de l'accord de publication : il coche ;
//      l'accord est enregistre au serveur, signe du nom du compte, date, a la
//      version publiee.
//   4. Au Profil d'un enseignant actif (compte amorce de la pile) : la carte
//      de l'accord, « Retirer mon accord » derriere la confirmation, l'accord
//      retire (date de retrait), puis redonne.
//
// Quatre passages candidat : 390 et 1440, francais et arabe ; le Profil a 390
// en francais et a 1440 en arabe.
//
// Usage : node tool/e2e/cand_photo.mjs
import fs from 'node:fs';
import { parcours, ouvrir, libelles, taper, trouver, trouverTexte, dernierLien,
  activerSemantique, amenerEnVue, sql, connecter, DEPOT, COMPTES } from './commun.mjs';

const p = await parcours('CAND-PHOTO : photo du candidat et accord de publication', 'cand-photo');
const manque = [];
const un = (q) => sql(q).split('\n')[0].trim();
const lus = async (page, n = 70) => (await libelles(page)).slice(0, n).join(' | ');
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const I18N = {
  fr: JSON.parse(fs.readFileSync(`${DEPOT}/assets/i18n/fr.i18n.json`, 'utf8')),
  ar: JSON.parse(fs.readFileSync(`${DEPOT}/assets/i18n/ar.i18n.json`, 'utf8')),
};
const texte = (langue, cle) => cle.split('.').reduce((x, k) => x[k], I18N[langue]);
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

/// Amene le texte cherche au tiers haut de l'ecran avant une capture (L2).
async function centrer(a, motif) {
  const e = await trouver(a.page, motif, { delai: 4000 });
  if (!e) return;
  await amenerEnVue(a.page, e);
  const b = await e.boundingBox();
  const vue = a.page.viewportSize();
  if (b) {
    await a.page.mouse.move(vue.width * 0.6, vue.height / 2);
    await a.page.mouse.wheel(0, b.y - vue.height / 4);
  }
  await a.page.waitForTimeout(700);
}

// Une vraie image JPEG (le serveur et le navigateur la lisent), faite a la
// volee : un carre uni de 64 x 64.
const JPEG = fs.readFileSync(process.env.E2E_PHOTO ?? '/tmp/e2e-pile/photo-e2e.jpg').toString('base64');

/// Le selecteur de fichier du navigateur : l'<input type=file> recoit la photo
/// au moment ou l'application l'ouvre, comme si la personne l'avait choisie.
async function preparerPhoto(a) {
  await a.page.evaluate((b64) => {
    window.__photoE2E = b64;
    if (window.__clicPhotoPatche) return;
    window.__clicPhotoPatche = true;
    const origine = HTMLInputElement.prototype.click;
    HTMLInputElement.prototype.click = function clic() {
      if (this.type === 'file' && window.__photoE2E) {
        const octets = Uint8Array.from(atob(window.__photoE2E), (c) => c.charCodeAt(0));
        const dt = new DataTransfer();
        dt.items.add(new File([octets], 'portrait.jpg', { type: 'image/jpeg' }));
        this.files = dt.files;
        window.__ouvertPhotoE2E = true;
        setTimeout(() => {
          this.dispatchEvent(new Event('input', { bubbles: true }));
          this.dispatchEvent(new Event('change', { bubbles: true }));
        }, 50);
        return undefined;
      }
      return origine.call(this);
    };
  }, JPEG);
}

// Le brouillon complet d'un candidat (salle-examen-2), amorce en base locale.
const REPONSES = {
  langueMaternelle: 'man', languesExplication: ['ar', 'man'],
  niveauMemorisationDeclare: 'coran_entier', niveauLectureTajwid: 'tajwid_enseigne',
  riwayat: ['hafs', 'warsh'], ijazaPresentable: 'oui', experienceDebutants: 'oui',
  disponibilitesDeclarees: [{ jour: 1, debut: '20:00', fin: '22:00' }, { jour: 3, debut: '20:00', fin: '22:00' }],
  fuseauIana: 'Africa/Conakry', classesSouhaitees: '2', debutPossible: 'immediat',
  publics: ['6_9', 'adultes'], paysResidence: 'GN', paysVersement: 'SA', compteBancaire: true, operateurs: [],
};

sql(`update public.app_config set value = 'true'::jsonb where key = 'candidatures.inscription_publique_ouverte'`);
controle(un(`select value #>> '{}' from public.app_config where key = 'enseignants.publication_version'`) === 'publication-2026-11-v1',
  'migration 20261110330000 posee sur la pile locale (version du texte de publication)');

async function candidat({ largeur, langue }) {
  const a = await p.contexte(`${largeur}_${langue}`, {
    vue: largeur < 600 ? { width: 390, height: 844 } : { width: 1440, height: 900 },
    langue: langue === 'ar' ? 'ar-SA' : 'fr-FR',
  });
  const courriel = `cand-photo.${largeur}.${langue}.${Date.now() % 1000000}@example.com`;
  p.dire(`== Candidat ${largeur} ${langue.toUpperCase()} : ${courriel}`);

  // 1. Le lien direct, le compte, la candidature sans code.
  await ouvrir(a.page, '/#/connexion?mode=creer&candidature=1');
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await toucher(a, exact(langue, 'connexion.envoyerLienCreation'), 'Recevoir le lien d\'inscription', { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.prenom')}"]`, 'Ibrahima');
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.nom')}"]`, 'Keita');
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (identité)');
  await toucher(a, debut(langue, 'inscription.genreHomme'), 'Un homme', { role: 'radio', pause: 800 });
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (genre)');
  await toucher(a, debut(langue, 'inscription.telephone.choisirPays'), 'Choisir votre pays', { pause: 1500 });
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.telephone.rechercherPays')}"]`, '+224');
  await a.page.waitForTimeout(800);
  await toucher(a, /\+224/, 'Guinée (+224)', { role: 'button', pause: 1200 });
  await taper(a.page, `input[aria-label="${texte(langue, 'inscription.telephone.numeroCourt')}"]`, '622 12 34 56');
  await toucher(a, exact(langue, 'commun.continuer'), 'Continuer (téléphone)');
  await toucher(a, exact(langue, 'inscription.confidentialite.case'), 'case de confidentialité', { role: 'checkbox', pause: 800 });
  await toucher(a, exact(langue, 'inscription.candidat.envoyer'), 'Envoyer ma candidature', { pause: 6000 });
  controle(a.page.url().includes('/attente'), `${largeur} ${langue} : candidature déposée`, a.page.url());

  // Le brouillon complet, amorce en base locale.
  const id = un(`select id from auth.users where email = '${courriel}'`);
  const cand = un(`select id from public.candidatures where profile_id = '${id}'`);
  sql(`insert into public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon)
       values ('${cand}', 'salle-examen-2', '${JSON.stringify(REPONSES)}'::jsonb, 'candidat', true)`);

  // 2. Le recapitulatif : la photo.
  await toucher(a, exact(langue, 'recrutement.portail.completer'), 'Compléter ma candidature', { pause: 3000 });
  for (let k = 0; k < 30; k++) {
    if (await trouverTexte(a.page, new RegExp(echapper(texte(langue, 'candidatsFlux.photo.titre'))), 1500)) break;
    const suite = await trouver(a.page, exact(langue, 'commun.continuer'), { delai: 3000, role: 'button' });
    if (!suite) break;
    await amenerEnVue(a.page, suite); await suite.click(); await a.page.waitForTimeout(1500);
    await activerSemantique(a.page);
  }
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.photo.titre'))));
  await etape(a, 'recap_photo');
  controle(Boolean(await trouverTexte(a.page, new RegExp(echapper(texte(langue, 'enseignant.photo.voile'))), 5000)),
    `${largeur} ${langue} : « ${texte(langue, 'enseignant.photo.voile')} »`);
  await preparerPhoto(a);
  await toucher(a, exact(langue, 'enseignant.photo.choisir'), 'Choisir une photo', { pause: 2500 });
  await centrer(a, new RegExp(echapper(texte(langue, 'enseignant.photo.utiliser'))));
  await etape(a, 'photo_apercu');
  await toucher(a, exact(langue, 'enseignant.photo.utiliser'), 'Utiliser cette photo', { pause: 5000 });
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.photo.titre'))));
  await etape(a, 'photo_envoyee');
  const cle = un(`select coalesce(photo_storage_key, 'null') from public.teacher_profiles where profile_id = '${id}'`);
  controle(cle.startsWith(`${id}/`), `${largeur} ${langue} : photo posée (teacher_profiles.photo_storage_key)`, cle);
  controle(un(`select count(*) from storage.objects where bucket_id = 'photos_enseignants' and name = '${cle}'`) === '1',
    `${largeur} ${langue} : l'objet existe dans le seau photos_enseignants`);

  // 3. L'accord de publication.
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.titre'))));
  await etape(a, 'accord_avant');
  await toucher(a, exact(langue, 'candidatsFlux.publication.case'), 'case de l\'accord de publication', { role: 'checkbox', pause: 3000 });
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.titre'))));
  await etape(a, 'accord_donne');
  const accord = un(`select version || '/' || nom_signe || '/' || (retire_le is null)::text
                     from public.accords_publication where profile_id = '${id}'`);
  controle(accord === 'publication-2026-11-v1/Ibrahima Keita/true',
    `${largeur} ${langue} : accord enregistré au serveur, signé du nom du compte, version publiée`, accord);
  await a.ctx.close();
}

async function profil({ largeur, langue }) {
  const a = await p.contexte(`profil_${largeur}_${langue}`, {
    vue: largeur < 600 ? { width: 390, height: 844 } : { width: 1440, height: 900 },
    langue: langue === 'ar' ? 'ar-SA' : 'fr-FR',
  });
  p.dire(`== Profil de l'enseignant ${largeur} ${langue.toUpperCase()}`);
  const id = un(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`update public.accords_publication set retire_le = now() where profile_id = '${id}' and retire_le is null`);
  await connecter(a.page, COMPTES.enseignant);
  await ouvrir(a.page, '/#/enseignant/profil');
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.titre'))));
  await etape(a, 'profil_accord');
  await toucher(a, exact(langue, 'candidatsFlux.publication.case'), 'case de l\'accord (Profil)', { role: 'checkbox', pause: 3000 });
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.titre'))));
  await etape(a, 'profil_accord_donne');
  await toucher(a, exact(langue, 'candidatsFlux.publication.retirer'), 'Retirer mon accord', { pause: 2000 });
  await etape(a, 'profil_confirmation');
  controle(Boolean(await trouverTexte(a.page, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.retirerConsequence').slice(0, 30))), 4000)),
    `${largeur} ${langue} : la confirmation dit l'effet du retrait`);
  const boutons = a.page.getByRole('button', { name: exact(langue, 'candidatsFlux.publication.retirer') });
  await boutons.last().click();
  await a.page.waitForTimeout(3000);
  await activerSemantique(a.page);
  await centrer(a, new RegExp(echapper(texte(langue, 'candidatsFlux.publication.titre'))));
  await etape(a, 'profil_accord_retire');
  controle(un(`select count(*) from public.accords_publication where profile_id = '${id}' and retire_le is null`) === '0'
    && Number(un(`select count(*) from public.accords_publication where profile_id = '${id}'`)) >= 1,
    `${largeur} ${langue} : accord retiré au serveur (la ligne reste, datée)`);
  await a.ctx.close();
}

let echec = '';
for (const [largeur, langue] of [[390, 'fr'], [1440, 'ar'], [390, 'ar'], [1440, 'fr']]) {
  try { await candidat({ largeur, langue }); } catch (e) {
    echec = echec || `candidat ${largeur} ${langue} : ${e.message}`;
    p.dire(`ARRET candidat ${largeur} ${langue} : ${e.message}`);
  }
}
for (const [largeur, langue] of [[390, 'fr'], [1440, 'ar']]) {
  try { await profil({ largeur, langue }); } catch (e) {
    echec = echec || `profil ${largeur} ${langue} : ${e.message}`;
    p.dire(`ARRET profil ${largeur} ${langue} : ${e.message}`);
  }
}
sql(`update public.app_config set value = 'false'::jsonb where key = 'candidatures.inscription_publique_ouverte'`);
if (manque.length) p.dire(`Manques : ${manque.join(' ; ')}`);
process.exit(await p.fin(manque.length || echec ? 'rouge' : 'vert', echec || manque.join(' ; ')));
