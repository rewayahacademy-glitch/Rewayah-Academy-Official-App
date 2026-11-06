// ENTREE-ORDRE (PLAN-LOTS rang 22 0, constat du directeur du 05/11/2026) :
// pour un nouveau profil, le questionnaire passe avant l'e-mail et la
// connexion. Sur la pile LOCALE seulement (G5), a 390 et 1440, en francais et
// en arabe. Quatre cas :
//   A. nouveau visiteur : `/` et `/connexion` nue (cible des boutons du site)
//      menent au questionnaire ; « J'ai deja un compte » mene a la connexion ;
//   B. quelqu'un qui revient (l'appareil a deja ouvert une session) :
//      `/connexion` tapee garde la connexion, `/` aussi ;
//   C. un lien de connexion recu, ouvert sur un appareil neuf : la session
//      s'ouvre, jamais le questionnaire ;
//   D. un tuteur inscrit deux enfants avant d'envoyer sa demande : premier
//      enfant au questionnaire, e-mail, lien, puis « Ajouter un autre profil
//      eleve » au recapitulatif ; la demande part avec les deux enfants.
// Usage : node tool/e2e/entree_ordre.mjs  (pile.sh, amorcer.sh, construire et
// servir d'abord).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, cliquer, taper, libelles, attendreTexte,
  activerSemantique, amenerEnVue, dernierLien, sql, COMPTES, MDP, DEPOT } from './commun.mjs';

const lire = (fichier) => {
  const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n', fichier), 'utf8'));
  return (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
};
const LANGUES = { fr: lire('fr.i18n.json'), ar: lire('ar.i18n.json') };
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/// Un texte des fichiers de langue, en motif : les espaces (insecables
/// comprises, comme avant « ? ») valent toute espace.
const souple = (s) => echapper(s).replace(/[\s\u00a0\u202f]+/g, '\\s*');
const exact = (s) => new RegExp(`^\\s*${souple(s)}\\s*$`);
const debut = (s) => new RegExp(`^\\s*${souple(s)}`);

const p = await parcours('ENTREE-ORDRE : le questionnaire avant l\'e-mail', 'entree-ordre');
const tampon = `${Date.now() % 1000000}`;
const verdicts = {};

function noter(cle, nom, ok, detail = '') {
  verdicts[cle] ??= {};
  verdicts[cle][nom] = ok;
  p.dire(`  ${ok ? 'OK' : 'ROUGE'} ${cle} : ${nom}${detail ? ` (${detail})` : ''}`);
}

const chemin = (page) => decodeURIComponent(new URL(page.url()).hash.replace(/^#/, ''));

async function attendreChemin(page, motif, delai = 15000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    if (motif.test(chemin(page))) return true;
    await page.waitForTimeout(300);
  }
  return false;
}

/// Va a une adresse de l'application dans la meme page (comme une adresse
/// tapee : l'application se recharge).
async function taperAdresse(page, route) {
  await ouvrir(page, `/#${route}`);
  await page.waitForTimeout(1500);
  await activerSemantique(page);
}

async function surQuestionnaire(page, T) {
  return (await attendreChemin(page, /^\/commencer/))
    && attendreTexte(page, new RegExp(souple(T('inscription.usage.question'))), 15000);
}

async function surConnexion(page, T) {
  return (await attendreChemin(page, /^\/connexion/))
    && (await trouver(page, debut(T('connexion.envoyerLien')), { delai: 15000 })) !== null;
}

// --- A. Nouveau visiteur ------------------------------------------------------
async function casA(c, cle, T) {
  await ouvrir(c.page, '/');
  await c.page.waitForTimeout(1500); await activerSemantique(c.page);
  noter(cle, 'la racine mene au questionnaire', await surQuestionnaire(c.page, T), chemin(c.page));
  await c.page.mouse.move(2, 2);
  await p.capture(c, `${cle}_A1_racine_questionnaire`);

  await taperAdresse(c.page, '/connexion');
  noter(cle, '/connexion nue (boutons du site) mene au questionnaire',
    await surQuestionnaire(c.page, T), chemin(c.page));
  await p.capture(c, `${cle}_A2_connexion_nue_questionnaire`);

  const deja = await trouver(c.page, exact(T('inscription.questionnaire.dejaUnCompte')), { delai: 10000 });
  noter(cle, '« J\'ai deja un compte » present sur le questionnaire', deja !== null);
  if (deja) {
    await amenerEnVue(c.page, deja); await deja.click(); await c.page.waitForTimeout(2000);
    await activerSemantique(c.page);
  }
  noter(cle, '« J\'ai deja un compte » mene a la connexion', await surConnexion(c.page, T), chemin(c.page));
  noter(cle, 'aucun repere « compte connu » pose sans session', await c.page.evaluate(
    () => localStorage.getItem('rewayah.entree.compte_connu') === null));
  await c.page.mouse.move(2, 2);
  await p.capture(c, `${cle}_A3_deja_un_compte_connexion`);
}

// --- B. Quelqu'un qui revient ---------------------------------------------------
async function casB(c, cle, T) {
  // Une vraie connexion (mot de passe : construction locale), puis une vraie
  // sortie par l'interface.
  await ouvrir(c.page, '/');
  const deja = await trouver(c.page, exact(T('inscription.questionnaire.dejaUnCompte')), { delai: 10000 });
  if (deja) { await deja.click(); await c.page.waitForTimeout(1500); }
  await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', COMPTES.enseignant);
  await taper(c.page, 'input[type=password]', MDP);
  await c.page.keyboard.press('Enter');
  await c.page.waitForTimeout(7000); await activerSemantique(c.page);
  const connecte = await attendreChemin(c.page, /^\/(enseignant|attente)/, 20000);
  noter(cle, 'la premiere connexion ouvre la session', connecte, chemin(c.page));
  noter(cle, 'la session pose le repere « compte connu »', await c.page.evaluate(
    () => localStorage.getItem('rewayah.entree.compte_connu') !== null));
  // La sortie par l'interface (pilote, 06/11) : Profil, « Se deconnecter »,
  // puis la confirmation. L'appareil connu revient a la connexion, jamais au
  // questionnaire.
  await taperAdresse(c.page, '/enseignant/profil');
  await cliquer(c.page, exact(T('compte.deconnexion')), { pause: 1500 });
  await cliquer(c.page, exact(T('enseignant.profil.deconnexionConfirmer')), { pause: 4000 });
  await activerSemantique(c.page);
  noter(cle, 'apres la sortie, la session est fermee', await c.page.evaluate(
    () => !Object.keys(localStorage).some((k) => k.startsWith('sb-') && k.endsWith('auth-token'))));
  noter(cle, 'apres la sortie : la connexion, pas le questionnaire',
    await surConnexion(c.page, T), chemin(c.page));
  await c.page.mouse.move(2, 2);
  await p.capture(c, `${cle}_B1_apres_sortie_connexion`);

  await taperAdresse(c.page, '/connexion');
  noter(cle, '/connexion tapee par quelqu\'un qui revient garde la connexion',
    await surConnexion(c.page, T), chemin(c.page));
  await c.page.mouse.move(2, 2);
  await p.capture(c, `${cle}_B2_revient_connexion_tapee`);

  await taperAdresse(c.page, '/');
  noter(cle, 'la racine aussi', await surConnexion(c.page, T), chemin(c.page));
}

// --- C. Lien recu, ouvert sur un appareil neuf --------------------------------
async function demanderLien(c, T) {
  await ouvrir(c.page, '/');
  const deja = await trouver(c.page, exact(T('inscription.questionnaire.dejaUnCompte')), { delai: 10000 });
  if (deja) { await deja.click(); await c.page.waitForTimeout(1500); }
  const depuis = Date.now();
  await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', COMPTES.enseignant);
  await cliquer(c.page, debut(T('connexion.envoyerLien')), { pause: 2500 });
  return (await dernierLien(COMPTES.enseignant, depuis))?.lien ?? null;
}

async function casC(c, cNeuf, cle, T) {
  // 1. Un lien demande ici, ouvert sur un AUTRE appareil (jamais connu) :
  // l'echange n'y aboutit pas (flux PKCE de Supabase, la clef reste sur
  // l'appareil demandeur ; limite hors de ce lot), mais l'application garde
  // la connexion, jamais le questionnaire.
  const lienAutre = await demanderLien(c, T);
  noter(cle, 'le lien de connexion arrive dans la boite (Mailpit)', Boolean(lienAutre));
  if (!lienAutre) return;
  await cNeuf.page.goto(lienAutre);
  await cNeuf.page.waitForTimeout(7000); await activerSemantique(cNeuf.page);
  p.dire(`  ${cle} : lien ouvert sur un autre appareil, arrivee ${cNeuf.page.url().slice(0, 160)}`);
  noter(cle, 'lien ouvert sur un autre appareil : la connexion, jamais le questionnaire',
    await surConnexion(cNeuf.page, T), chemin(cNeuf.page));
  await cNeuf.page.mouse.move(2, 2);
  await p.capture(cNeuf, `${cle}_C1_lien_autre_appareil_connexion`);

  // 2. Un lien demande et ouvert dans le meme navigateur, qui n'a jamais
  // ouvert de session (aucun repere « compte connu ») : la session s'ouvre.
  noter(cle, 'avant le lien, aucun repere « compte connu »', await c.page.evaluate(
    () => localStorage.getItem('rewayah.entree.compte_connu') === null));
  const lien = await demanderLien(c, T);
  noter(cle, 'un second lien arrive', Boolean(lien));
  if (!lien) return;
  await c.page.goto(lien);
  await c.page.waitForTimeout(7000); await activerSemantique(c.page);
  p.dire(`  ${cle} : lien ouvert, arrivee ${c.page.url().slice(0, 120)}`);
  noter(cle, 'le lien recu ouvre la session', await attendreChemin(c.page, /^\/(enseignant|attente)/, 20000),
    chemin(c.page));
  noter(cle, 'le lien recu ne mene jamais au questionnaire', !/^\/commencer/.test(chemin(c.page)));
  await c.page.mouse.move(2, 2);
  await p.capture(c, `${cle}_C2_lien_recu_session`);
}

// --- D. Un tuteur, deux enfants --------------------------------------------------
/// Repond a l'ecran courant du questionnaire, sans dependre de la langue :
/// un champ (un prenom), sinon la premiere carte (la seconde pour « Pour
/// qui » : la famille), puis « Continuer ».
async function repondre(page, T, prenom) {
  await activerSemantique(page);
  const etape = new URL(page.url()).hash.match(/etape=([^&]+)/)?.[1] ?? '';
  if (/^prenom/.test(etape)) {
    await taper(page, 'input', prenom);
  } else {
    const cartes = page.getByRole('radio');
    const cases = page.getByRole('checkbox');
    if (await cartes.count()) {
      const choisie = await page.locator('[role=radio][aria-checked=true]').count();
      if (!choisie) {
        const carte = cartes.nth(etape === 'pourQui' ? 1 : 0);
        await amenerEnVue(page, carte); await carte.click(); await page.waitForTimeout(600);
      }
    } else if (/^age/.test(etape)) {
      // L'age : des boutons (« 6 ans » a « 18 ans ou plus ») ; le troisieme
      // porteur d'un chiffre (latin ou arabe), « 8 ans ».
      const ages = page.getByRole('button', { name: /[0-9\u0660-\u0669]/ });
      const age = ages.nth(2);
      await amenerEnVue(page, age); await age.click(); await page.waitForTimeout(600);
    } else if (await cases.count()) {
      const cochee = await page.locator('[role=checkbox][aria-checked=true]').count();
      if (!cochee) { await cases.first().click(); await page.waitForTimeout(600); }
    } else {
      // Des reponses en boutons (le genre) : la premiere qui n'est ni
      // « Retour » ni « Continuer ».
      const boutons = page.getByRole('button');
      for (let i = 0; i < await boutons.count(); i++) {
        const nom = (await boutons.nth(i).getAttribute('aria-label')) ?? (await boutons.nth(i).innerText());
        if (exact(T('commun.retour')).test(nom) || exact(T('commun.continuer')).test(nom)) continue;
        await amenerEnVue(page, boutons.nth(i)); await boutons.nth(i).click(); await page.waitForTimeout(600);
        break;
      }
    }
  }
  await cliquer(page, exact(T('commun.continuer')), { pause: 1400 });
  return etape;
}

async function casD(c, cle, T) {
  const courriel = `e2e-entree-${cle}-${tampon}@example.com`;
  const enfants = [`Yasmine${tampon}`, `Hakim${tampon}`];
  await ouvrir(c.page, '/');
  noter(cle, 'le tuteur commence par le questionnaire', await surQuestionnaire(c.page, T));
  // Premier enfant : le questionnaire jusqu'a l'acces (l'e-mail).
  const vues = [];
  for (let k = 0; k < 16 && !/etape=acces/.test(c.page.url()); k++) {
    vues.push(await repondre(c.page, T, enfants[0]));
  }
  p.dire(`  ${cle} : ecrans du questionnaire ${vues.join(', ')}`);
  noter(cle, 'l\'e-mail vient apres le questionnaire (?etape=acces)', /etape=acces/.test(c.page.url()));
  await activerSemantique(c.page);
  await p.capture(c, `${cle}_D1_acces_apres_questionnaire`);
  const depuis = Date.now();
  await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(c.page, debut(T('connexion.envoyerLien')), { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  noter(cle, 'le lien d\'inscription arrive', Boolean(recu?.lien));
  if (!recu?.lien) return;
  await c.page.goto(recu.lien);
  await c.page.waitForTimeout(7000); await activerSemantique(c.page);

  // Apres la connexion : identite, genre... jusqu'au recapitulatif.
  async function jusquAuRecapitulatif() {
    for (let k = 0; k < 10; k++) {
      if (await trouver(c.page, exact(T('inscription.questionnaire.envoyer')), { delai: 1500 })) return true;
      await activerSemantique(c.page);
      for (const champ of await c.page.locator('input').all()) {
        if ((await champ.inputValue().catch(() => 'x')) !== '') continue;
        await champ.click({ force: true }); await c.page.keyboard.type('Test', { delay: 10 });
      }
      const cartes = c.page.getByRole('radio');
      if (await cartes.count() && !(await c.page.locator('[role=radio][aria-checked=true]').count())) {
        await cartes.first().click(); await c.page.waitForTimeout(400);
      }
      const suite = await trouver(c.page, exact(T('commun.continuer')), { delai: 2000 });
      if (suite) { await amenerEnVue(c.page, suite); await suite.click(); await c.page.waitForTimeout(1500); }
    }
    return false;
  }
  noter(cle, 'le recapitulatif s\'ouvre apres le lien', await jusquAuRecapitulatif());
  const ajouter = await trouver(c.page, exact(T('inscription.questionnaire.ajouterProfil')), { delai: 8000 });
  noter(cle, '« Ajouter un autre profil eleve » au recapitulatif', ajouter !== null);
  if (!ajouter) return;
  await amenerEnVue(c.page, ajouter);
  await p.capture(c, `${cle}_D2_recapitulatif_un_enfant`);
  await ajouter.click(); await c.page.waitForTimeout(1500);
  noter(cle, 'l\'ajout ouvre le prenom du deuxieme enfant', /etape=prenom-1/.test(c.page.url()), c.page.url());
  // Deuxieme enfant : ses ecrans seulement, puis retour a l'inscription.
  for (let k = 0; k < 6 && /\/commencer/.test(c.page.url()); k++) {
    await repondre(c.page, T, enfants[1]);
  }
  noter(cle, 'retour au recapitulatif avec deux enfants', await jusquAuRecapitulatif());
  const texte = (await libelles(c.page)).join(' | ');
  const lesDeux = enfants.every((e) => texte.includes(e))
    || (await attendreTexte(c.page, enfants[0], 3000) && await attendreTexte(c.page, enfants[1], 3000));
  noter(cle, 'les deux enfants au recapitulatif', lesDeux);
  await p.capture(c, `${cle}_D3_recapitulatif_deux_enfants`);
  const envoyer = await trouver(c.page, exact(T('inscription.questionnaire.envoyer')), { delai: 4000 });
  await amenerEnVue(c.page, envoyer); await envoyer.click();
  await c.page.waitForTimeout(6000); await activerSemantique(c.page);
  noter(cle, 'la demande part : « Votre compte »', await attendreTexte(c.page, new RegExp(souple(T('attente.titreCompte'))), 15000));
  const nb = sql(`select count(*) from public.candidature_apprenants ca
    join public.candidatures cd on cd.id = ca.candidature_id
    join auth.users u on u.id = cd.profile_id
    where u.email = '${courriel}' and not ca.est_titulaire`);
  noter(cle, 'deux enfants enregistres avec la demande', /^[2-9]$/.test(nb), `en base : ${nb}`);
  await p.capture(c, `${cle}_D4_demande_envoyee`);
}

let code = 1;
try {
  for (const langue of ['fr', 'ar']) {
    const T = LANGUES[langue];
    const locale = langue === 'ar' ? 'ar-SA' : 'fr-FR';
    for (const [largeur, hauteur] of [[390, 844], [1440, 900]]) {
      const cle = `${largeur}_${langue}`;
      // E2E_SEUL=390_fr : une seule combinaison (mise au point).
      if (process.env.E2E_SEUL && process.env.E2E_SEUL !== cle) continue;
      const vue = { width: largeur, height: hauteur };
      const nouveau = await p.contexte('visiteur', { vue, langue: locale });
      await casA(nouveau, cle, T); await nouveau.ctx.close();
      const revient = await p.contexte('revient', { vue, langue: locale });
      await casB(revient, cle, T); await revient.ctx.close();
      const demande = await p.contexte('demande', { vue, langue: locale });
      const neuf = await p.contexte('appareil_neuf', { vue, langue: locale });
      await casC(demande, neuf, cle, T); await demande.ctx.close(); await neuf.ctx.close();
      const tuteur = await p.contexte('tuteur', { vue, langue: locale });
      await casD(tuteur, cle, T); await tuteur.ctx.close();
    }
  }
  const rouges = Object.entries(verdicts).flatMap(([k, v]) =>
    Object.entries(v).filter(([, ok]) => !ok).map(([n]) => `${k} : ${n}`));
  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
