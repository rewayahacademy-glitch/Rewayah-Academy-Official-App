// FIL-ARIANE (PLAN-LOTS rang 22 n, directeur, 06/11/2026 : « impossible de
// sortir de cette page, et c'est partout pareil sur ordinateur […] pour la
// file d'ariane c'est maintenant »). Sur la pile LOCALE seulement.
//
// 1. L'arbre des routes est LU dans le code du routeur (app_router.dart et
//    les listes de routes qu'il deplie), jamais recopie a la main : chaque
//    GoRoute, son chemin complet, ses parametres remplaces par des
//    identifiants amorces. Les routes de demonstration (drapeaux de
//    developpement, forces a faux en production) sont ecartees.
// 2. Pour chaque role (famille, eleve, enseignant, direction, controle,
//    comptabilite, visiteur), chaque route du role est ouverte, a 1440 x 900
//    puis a 390 x 844. Sur la page obtenue (apres redirection eventuelle), un
//    geste VISIBLE doit ramener ailleurs : un segment du fil d'Ariane, le
//    disque « Retour », ou une destination de la barre (laterale ou basse ;
//    le menu de la direction au telephone). Le robot touche ce geste et
//    verifie que l'adresse change.
// 3. Les captures R3 : la Bibliotheque depuis le Compte (famille,
//    enseignant), la fiche de l'eleve (Finances), une page de la direction ;
//    390 et 1440, francais et arabe.
//
// Le rapport (rapport.json) liste chaque route jouee, ou elle a mene et le
// geste qui en sort. Le robot consigne, il ne corrige pas.
//
// Usage : node tool/e2e/fil_ariane.mjs   (pile.sh, amorcer.sh, construire et
// servir d'abord). E2E_FIL_ROLES=famille,direction pour restreindre ;
// E2E_FIL_TAILLES=1440 pour une seule taille ; E2E_FIL_SANS_CAPTURES=1.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, activerSemantique, trouver, amenerEnVue, taper, sql, connecter,
  COMPTES, MDP, DEPOT } from './commun.mjs';

const SEULEMENT_R3 = Boolean(process.env.E2E_FIL_SEULEMENT_R3);
const p = await parcours(SEULEMENT_R3 ? 'FIL-ARIANE : captures R3' : 'FIL-ARIANE : aucune page sans sortie',
  process.env.E2E_FIL_DOSSIER ?? (SEULEMENT_R3 ? 'fil-ariane/r3' : 'fil-ariane'));
const n = Date.now() % 1000000;
const ID = {};
const FR = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const AR = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8'));
const lire = (o, cle) => cle.split('.').reduce((x, k) => x?.[k], o);

// ---------------------------------------------------------------------------
// 1. L'arbre des routes, lu dans le code.
// ---------------------------------------------------------------------------

// Les constantes de chemin de tout lib/ (`Routes`, `RoutesTcB`, `CheminsTcA`...),
// par nom qualifie (`RoutesTcB.bibliotheque`) et par nom seul.
const FICHIERS_LIB = [];
(function lister(dossier) {
  for (const f of fs.readdirSync(dossier, { withFileTypes: true })) {
    const c = path.join(dossier, f.name);
    if (f.isDirectory()) lister(c);
    else if (f.name.endsWith('.dart') && !f.name.endsWith('.g.dart')) FICHIERS_LIB.push(c);
  }
})(path.join(DEPOT, 'lib'));
const CONSTANTES = {};
for (const f of FICHIERS_LIB) {
  const texte = fs.readFileSync(f, 'utf8');
  if (!texte.includes('static const String')) continue;
  let classe = '';
  for (const bloc of texte.split(/(?=\b(?:abstract\s+)?(?:final\s+)?class\s+\w+)/)) {
    const c = /^(?:abstract\s+)?(?:final\s+)?class\s+(\w+)/.exec(bloc);
    if (c) classe = c[1];
    for (const m of bloc.matchAll(/static const String (\w+)\s*=\s*((?:'[^']*'\s*)+);/g)) {
      const v = [...m[2].matchAll(/'([^']*)'/g)].map((x) => x[1]).join('');
      CONSTANTES[`${classe}.${m[1]}`] = { v, classe };
      if (!(m[1] in CONSTANTES) || classe === 'Routes') CONSTANTES[m[1]] = { v, classe };
    }
  }
}
function constante(nom, classe) {
  return CONSTANTES[nom.includes('.') ? nom : `${classe}.${nom}`] ?? CONSTANTES[nom.split('.').pop()];
}
function resoudre(valeur, classe = 'Routes', pile = 0) {
  if (pile > 10) return valeur;
  const sub = (_, k) => {
    const c = constante(k, classe);
    return c ? resoudre(c.v, c.classe, pile + 1) : `{${k}}`;
  };
  return valeur.replace(/\$\{([\w.]+)\}/g, sub).replace(/\$(\w+)/g, sub);
}
function expression(brut) {
  const e = brut.trim().replace(/,$/, '');
  const nom = /^([A-Za-z_][\w.]*)$/.exec(e);
  if (nom) {
    const c = constante(nom[1], 'Routes');
    return c ? resoudre(c.v, c.classe) : null;
  }
  const litteral = /^'([^']*)'$/.exec(e);
  if (litteral) return resoudre(litteral[1]);
  return null;
}
const joindre = (parent, enfant) =>
  enfant.startsWith('/') ? enfant : `${parent === '/' ? '' : parent}/${enfant}`;

// Le fichier qui definit une liste de routes depliee (`...routesTcA(`).
function fichierDe(fonction) {
  const motif = new RegExp(`List<(?:RouteBase|GoRoute)>\\s+${fonction}\\s*\\(`);
  return FICHIERS_LIB.find((f) => motif.test(fs.readFileSync(f, 'utf8')));
}

function routesDe(fichier, parentDeBase, sortie, depuisLigne = null) {
  const lignes = fs.readFileSync(fichier, 'utf8').split('\n');
  let debut = 0;
  let fin = lignes.length;
  if (depuisLigne) {
    debut = lignes.findIndex((l) => depuisLigne.test(l));
    // La fonction finit a la premiere ligne `}` ou `];` en colonne 0 apres elle.
    fin = lignes.findIndex((l, i) => i > debut && /^(\}|\];)/.test(l));
    if (fin === -1) fin = lignes.length;
  }
  const pile = []; // { indent, chemin }
  for (let i = debut; i < fin; i++) {
    const ligne = lignes[i];
    if (/^\s*\/\//.test(ligne)) continue;
    const route = /^(\s*)GoRoute\(/.exec(ligne);
    const depli = /^(\s*)\.\.\.(\w+)\(/.exec(ligne);
    if (route) {
      const indent = route[1].length;
      while (pile.length && pile.at(-1).indent >= indent) pile.pop();
      const parent = pile.length ? pile.at(-1).chemin : parentDeBase;
      // Le chemin : sur la ligne, ou dans les trois suivantes.
      let chemin = null;
      for (let j = i; j < i + 4 && j < fin; j++) {
        const m = /path:\s*(.+)$/.exec(lignes[j]);
        if (m) { chemin = expression(m[1]); break; }
      }
      if (chemin === null) continue;
      const complet = joindre(parent, chemin);
      pile.push({ indent, chemin: complet });
      sortie.push({ chemin: complet, fichier: path.relative(DEPOT, fichier), ligne: i + 1 });
    } else if (depli && /^routes/.test(depli[2])) {
      const indent = depli[1].length;
      while (pile.length && pile.at(-1).indent >= indent) pile.pop();
      const parent = pile.length ? pile.at(-1).chemin : parentDeBase;
      const f = fichierDe(depli[2]);
      if (f && !/\/demo\//.test(f)) {
        routesDe(f, parent, sortie, new RegExp(`List<(?:RouteBase|GoRoute)>\\s+${depli[2]}\\s*\\(`));
      }
    }
  }
}

const ARBRE = [];
routesDe(path.join(DEPOT, 'lib/core/router/app_router.dart'), '/', ARBRE);
// Les routes de developpement (galerie, demonstrations) ne sont pas en
// production : `Env` les force a faux.
const ARBRE_PROD = [...new Map(ARBRE
  .filter((r) => !/^\/(_|demo)/.test(r.chemin))
  .map((r) => [r.chemin, r])).values()];
p.dire(`Arbre lu : ${ARBRE.length} GoRoute, ${ARBRE_PROD.length} chemins de production`);
if (process.env.E2E_FIL_LISTER) {
  for (const r of ARBRE_PROD) console.log(r.chemin, r.fichier, r.ligne);
  process.exit(0);
}

// ---------------------------------------------------------------------------
// 2. Les comptes (SQL LOCAL, comme amorcer.sh) et les identifiants.
// ---------------------------------------------------------------------------

function creerCompte(courriel) {
  const existant = sql(`select id from auth.users where email = '${courriel}'`);
  if (existant) return existant;
  return sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${courriel}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
}
function matriculeLibre() {
  for (;;) {
    const m = `RA-26-${1000 + Math.floor(Math.random() * 9000)}`;
    if (sql(`select count(*) from public.profiles where immutable_id = '${m}'`) === '0') return m;
  }
}

const COURRIELS = {
  famille: 'e2e-fil-famille@example.com',
  eleve: 'e2e-fil-eleve@example.com',
  controle: 'e2e-fil-controle@example.com',
  comptabilite: 'e2e-fil-comptable@example.com',
};

function amorcer() {
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.tuteur = creerCompte(COURRIELS.famille);
  const deja = sql(`select household_id from public.profiles where id = '${ID.tuteur}'`);
  if (deja) {
    ID.foyer = deja;
    ID.eleve = sql(`select id from public.profiles where household_id = '${deja}' and role = 'student' limit 1`);
    ID.classe = sql(`select groupe_id from public.groupe_membres where student_id = '${ID.eleve}' limit 1`);
  } else {
    ID.eleve = creerCompte(COURRIELS.eleve);
    ID.foyer = sql('select gen_random_uuid()');
    ID.classe = sql('select gen_random_uuid()');
    sql(`begin;
      insert into public.households (id, timezone) values ('${ID.foyer}', 'Europe/Paris');
      insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
        ('${ID.tuteur}', '${matriculeLibre()}', 'guardian', '${ID.foyer}', 'Samira', 'FamilleFil', 'active', 'female'),
        ('${ID.eleve}', '${matriculeLibre()}', 'student', '${ID.foyer}', 'Mariam', 'EleveFil', 'active', 'female');
      update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.foyer}';
      insert into public.student_profiles (profile_id, student_type, interface_mode)
        values ('${ID.eleve}', 'minor', 'standard');
      insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
        values ('${ID.classe}', '${ID.prof}', 'enfant', 5, 'E2E FIL An-Nour ${n}', 3, 7);
      insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.eleve}');
      commit;`);
  }
  // Le controle exige la double verification : un facteur TOTP verifie, a
  // cle connue, amorce en base LOCALE (comme mfa_direction.mjs la lit).
  ID.cleMfa = 'JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP';
  for (const [cle, role] of [['controle', 'controller'], ['comptabilite', 'accountant']]) {
    const id = creerCompte(COURRIELS[cle]);
    ID[cle] = id;
    sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
      values ('${id}', '${matriculeLibre()}', '${role}', 'E2E', 'Fil ${cle}', 'active', 'female')
      on conflict (id) do nothing`);
  }
  sql(`insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, secret, created_at, updated_at)
    select gen_random_uuid(), '${ID.controle}', 'E2E FIL', 'totp', 'verified', '${ID.cleMfa}', now(), now()
    where not exists (select 1 from auth.mfa_factors where user_id = '${ID.controle}')`);
  p.dire(`Amorce : foyer ${ID.foyer}, eleve ${ID.eleve}, classe ${ID.classe}`);
}

const FAUX = '00000000-0000-4000-8000-000000000000';
function remplir(chemin) {
  return chemin.replace(/:(\w+)/g, (_, k) => {
    if (/^(eleveId|profilId)$/.test(k)) return ID.eleve;
    if (/^(classeId|groupeId)$/.test(k)) return ID.classe;
    if (k === 'texte') return 'conditions';
    return FAUX;
  });
}

// Les routes de chaque role, par prefixe ; les routes partagees (Compte,
// Bibliotheque, recherche) sont jouees par chaque role connecte.
const PARTAGEES = /^\/(compte|tc|recherche)(\/|$)/;
const PREFIXES = {
  famille: /^\/tuteur(\/|$)/,
  eleve: /^\/eleve(\/|$)/,
  enseignant: /^\/enseignant(\/|$)/,
  direction: /^\/admin(\/|$)/,
  controle: /^\/controleur(\/|$)/,
  comptabilite: /^\/comptable(\/|$)/,
};
const SANS_SORTIE_ATTENDUE = new Set(['/salle', '/agent']); // billet ou jeton : redirigees
const RACINES_VISITEUR = new Set(['/commencer', '/connexion']);
function routesDuRole(role) {
  if (role === 'visiteur') {
    return ARBRE_PROD.filter((r) => !Object.values(PREFIXES).some((m) => m.test(r.chemin))
      && !PARTAGEES.test(r.chemin));
  }
  return ARBRE_PROD.filter((r) => PREFIXES[role].test(r.chemin) || PARTAGEES.test(r.chemin));
}

// Les libelles de la navigation de chaque role (barre, colonne, menu).
const NAV = {
  famille: Object.values(FR.nav.tuteur),
  eleve: Object.values(FR.nav.eleve),
  enseignant: Object.values(FR.nav.enseignant),
  direction: Object.values(FR.nav.admin),
  controle: Object.values(FR.nav.controleur),
  comptabilite: Object.values(FR.comptable?.nav ?? {}),
  visiteur: [],
};
// Le disque retour, et le retour d'une page d'etat (introuvable, refusee).
const RETOUR = new Set(['commun.entete.retour', 'commun.etats.actions.retourAccueil']
  .flatMap((cle) => [lire(FR, cle), lire(AR, cle)]).filter(Boolean));

// ---------------------------------------------------------------------------
// 3. Jouer une route : ouvrir, chercher un geste visible, le toucher.
// ---------------------------------------------------------------------------

const hash = (page) => decodeURIComponent(new URL(page.url()).hash.replace(/^#/, '')).split('?')[0] || '/';

async function aller(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(2200);
  await activerSemantique(page);
}

/// Les gestes visibles de la page, dans l'ordre ou le robot les essaie.
async function gestes(page, role, largeur) {
  const liste = [];
  const segments = page.locator('[flt-semantics-identifier^="filAriane:"]');
  for (let i = 0; i < await segments.count(); i++) {
    const e = segments.nth(i);
    if (await e.isVisible().catch(() => false)) {
      liste.push({ nature: 'fil', nom: (await e.getAttribute('flt-semantics-identifier')).slice(10), e });
    }
  }
  const boutons = page.locator('flt-semantics[role="button"], flt-semantics[role="link"], flt-semantics[role="tab"], [role="button"], [role="link"], [role="tab"]');
  const nb = await boutons.count();
  for (let i = 0; i < nb; i++) {
    const e = boutons.nth(i);
    const nom = ((await e.getAttribute('aria-label').catch(() => null)) ?? (await e.innerText().catch(() => ''))).trim();
    if (!nom) continue;
    if (RETOUR.has(nom)) liste.push({ nature: 'retour', nom, e });
    else if (NAV[role].some((l) => nom === l || nom.startsWith(`${l}\n`) || nom.startsWith(`${l} `))) {
      liste.push({ nature: largeur < 600 ? 'barre' : 'colonne', nom, e });
    } else if (role === 'direction' && nom === FR.nav.admin.menu) {
      liste.push({ nature: 'menu', nom, e });
    }
  }
  const ordre = largeur < 600 ? ['retour', 'fil', 'barre', 'menu', 'colonne'] : ['fil', 'retour', 'colonne', 'barre', 'menu'];
  return liste.sort((a, b) => ordre.indexOf(a.nature) - ordre.indexOf(b.nature));
}

async function sortir(page, role, largeur, depart) {
  const candidats = await gestes(page, role, largeur);
  const essais = [];
  for (const g of candidats.slice(0, 4)) {
    try {
      await g.e.click({ timeout: 3000 });
      await page.waitForTimeout(1500);
      if (g.nature === 'menu') {
        // Le menu de la direction s'ouvre : on choisit un domaine du tiroir.
        await activerSemantique(page);
        const domaine = await trouver(page, FR.nav.admin.accueil, { delai: 3000, exact: true });
        if (domaine) { await domaine.click(); await page.waitForTimeout(1500); }
      }
      const arrivee = hash(page);
      essais.push(`${g.nature}:${g.nom}`);
      if (arrivee !== depart) return { geste: g.nature, nom: g.nom, arrivee, essais };
      await aller(page, depart);
    } catch (e) {
      essais.push(`${g.nature}:${g.nom}:echec`);
    }
  }
  // La barre (laterale au bureau, basse au telephone) est dessinee mais
  // absente de l'arbre d'accessibilite du web (constat de ce lot, deja note
  // « ECART : onglet absent » par les robots precedents) : le robot la touche
  // alors la ou elle est dessinee, comme une personne, et le dit.
  const vue = page.viewportSize();
  const points = largeur < 600
    ? [0.125, 0.375, 0.625, 0.875].map((x) => [Math.round(vue.width * x), vue.height - 40])
    : [101, 157, 213, 269, 325, vue.height - 43].map((y) => [128, y]);
  for (const [x, y] of points) {
    await page.mouse.click(x, y);
    await page.waitForTimeout(1500);
    const arrivee = hash(page);
    essais.push(`barre-dessinee:${x},${y}`);
    if (arrivee !== depart) {
      return { geste: largeur < 600 ? 'barre-dessinee' : 'colonne-dessinee', nom: `${x},${y}`, arrivee, essais };
    }
  }
  return { geste: null, arrivee: hash(page), essais, candidats: candidats.length };
}

const ROLES = (process.env.E2E_FIL_ROLES ?? 'famille,eleve,enseignant,direction,controle,comptabilite,visiteur').split(',');
const TAILLES = (process.env.E2E_FIL_TAILLES ?? '1440,390').split(',').map(Number);
const COURRIEL_DE = {
  famille: COURRIELS.famille, eleve: COURRIELS.eleve, enseignant: COMPTES.enseignant,
  direction: COMPTES.direction, controle: COURRIELS.controle, comptabilite: COURRIELS.comptabilite,
};

function totp(cle) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const c of cle) bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
  const octets = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const compteur = Buffer.alloc(8);
  compteur.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const h = crypto.createHmac('sha1', octets).update(compteur).digest();
  const o = h[h.length - 1] & 0xf;
  return String((h.readUInt32BE(o) & 0x7fffffff) % 1000000).padStart(6, '0');
}

/// La connexion d'une langue autre que le francais : le bouton « J'ai deja
/// un compte » du questionnaire porte le mot de cette langue.
async function connecterEn(page, courriel, L) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, lire(L, 'inscription.questionnaire.dejaUnCompte'), { delai: 8000 })
      ?? await trouver(page, lire(L, 'connexion.modeConnexion'), { delai: 4000 });
    if (e) { await e.click(); await page.waitForTimeout(1500); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(6000);
  await activerSemantique(page);
  if (/^\/(connexion|commencer)/.test(hash(page))) {
    throw new Error(`connexion refusee (${courriel}), arrive sur ${hash(page)}`);
  }
}

async function connecterRole(page, role, L = FR) {
  if (role === 'visiteur') { await ouvrir(page, '/'); return; }
  if (L !== FR) { await connecterEn(page, COURRIEL_DE[role], L); return; }
  // Une machine chargee peut depasser le delai d'un premier affichage : une
  // seconde tentative, puis l'echec est dit.
  try {
    await connecter(page, COURRIEL_DE[role]);
  } catch (e) {
    p.dire(`  (connexion ${role} : seconde tentative apres ${String(e).slice(0, 80)})`);
    await connecter(page, COURRIEL_DE[role]);
  }
  if (role === 'controle' && hash(page) === '/controleur/mfa') {
    // Un code par fenetre de 30 s : on attend une fenetre neuve.
    await page.waitForTimeout(30000 - (Date.now() % 30000) + 1500);
    const champ = page.locator('input:not([disabled]), textarea:not([disabled])').last();
    await champ.waitFor({ state: 'visible', timeout: 10000 });
    await champ.click();
    // Rempli d'un coup : une frappe lente sur une machine chargee perdait un
    // chiffre (« 55936 », 06/11).
    await champ.fill(totp(ID.cleMfa));
    await page.keyboard.press('Enter');
    await page.waitForTimeout(5000);
    await activerSemantique(page);
    if (hash(page) === '/controleur/mfa') {
      throw new Error('double verification du controle non franchie (code refuse ou bouton absent)');
    }
  }
  if (/^\/(connexion|commencer)/.test(hash(page))) {
    throw new Error(`connexion refusee pour ${role} (${COURRIEL_DE[role]}), arrive sur ${hash(page)}`);
  }
}

const rapport = { debut: new Date().toISOString(), arbre: ARBRE_PROD.map((r) => r.chemin), joues: [], bloques: [] };
let rouges = 0;

async function jouerRole(role, largeur) {
  const acteur = await p.contexte(`${role}-${largeur}`, { vue: { width: largeur, height: largeur < 600 ? 844 : 900 } });
  try {
    try {
      await connecterRole(acteur.page, role);
    } catch (e) {
      rouges += 1;
      rapport.bloques.push(`${role} ${largeur} : ${e.message}`);
      p.dire(`  ROUGE [${role} ${largeur}] ${e.message}`);
      await p.capture(acteur, `connexion_refusee_${role}`);
      return;
    }
    const accueil = hash(acteur.page);
    p.dire(`[${role} ${largeur}] connecte, accueil ${accueil}`);
    for (const r of routesDuRole(role)) {
      const demande = remplir(r.chemin);
      await aller(acteur.page, demande);
      const obtenu = hash(acteur.page);
      let issue;
      if (SANS_SORTIE_ATTENDUE.has(r.chemin) && obtenu === demande) {
        issue = { geste: 'exempte', arrivee: obtenu, essais: [] };
      } else {
        issue = await sortir(acteur.page, role, largeur, obtenu);
        // La racine du role (son accueil ; pour le visiteur, ses deux pages
        // d'entree) n'a nulle part ou « revenir » : elle est notee comme
        // telle, jamais comptee comme une sortie prouvee.
        if (issue.geste === null && (obtenu === accueil || (role === 'visiteur' && RACINES_VISITEUR.has(obtenu)))) {
          issue = { ...issue, geste: 'racine' };
        }
      }
      const ligne = { role, largeur, route: r.chemin, demande, obtenu, ...issue, source: `${r.fichier}:${r.ligne}` };
      delete ligne.e;
      rapport.joues.push(ligne);
      const ok = issue.geste !== null;
      if (!ok) rouges += 1;
      p.dire(`  ${ok ? 'OK' : 'ROUGE'} ${demande}${obtenu !== demande ? ` -> ${obtenu}` : ''} : ${issue.geste ?? 'aucune sortie'}${issue.nom ? ` (${issue.nom})` : ''}${ok ? ` -> ${issue.arrivee}` : ` [${issue.essais.join(', ')}]`}`);
      if (!ok && process.env.E2E_FIL_CAPTURER_ROUGES) {
        await p.capture(acteur, `rouge_${demande.replace(/[^a-z0-9]+/gi, '_').slice(0, 60)}`);
      }
    }
  } finally {
    await acteur.ctx.close();
  }
}

// ---------------------------------------------------------------------------
// 4. Les captures R3.
// ---------------------------------------------------------------------------

async function capturesR3() {
  for (const langue of ['fr', 'ar']) {
    for (const largeur of [390, 1440]) {
      const vue = { width: largeur, height: largeur < 600 ? 844 : 900 };
      const options = { vue, langue: langue === 'ar' ? 'ar-SA' : 'fr-FR' };
      const L = langue === 'ar' ? AR : FR;
      // Famille : Compte, puis Bibliotheque par sa ligne.
      for (const [role, compte] of [['famille', '/tuteur/compte'], ['enseignant', '/compte']]) {
        const a = await p.contexte(`${role}`, options);
        await connecterRole(a.page, role, L);
        await aller(a.page, compte);
        const titre = lire(L, 'tc.bibliotheque.titre');
        // La ligne est plus bas dans le Compte : on fait defiler la page,
        // comme une personne, jusqu'a la voir.
        let ligneBiblio = null;
        for (let i = 0; i < 12 && !ligneBiblio; i++) {
          ligneBiblio = await trouver(a.page, lire(L, 'tc.bibliotheque.detail.entreeLigne'), { delai: 1200 })
            ?? await trouver(a.page, new RegExp(`^\\s*${titre}`), { delai: 800 });
          if (!ligneBiblio) {
            const v = a.page.viewportSize();
            await a.page.mouse.move(v.width * 0.6, v.height / 2);
            await a.page.mouse.wheel(0, 400);
            await a.page.waitForTimeout(600);
            await activerSemantique(a.page);
          }
        }
        if (ligneBiblio) await amenerEnVue(a.page, ligneBiblio);
        // `push` ne change pas l'adresse du navigateur (go_router) : la
        // Bibliotheque se reconnait a son champ de recherche.
        const surBibliotheque = async () => {
          await activerSemantique(a.page);
          return Boolean(await trouver(a.page, lire(L, 'tc.bibliotheque.rechercheIndication'), { delai: 4000, role: 'textbox' }));
        };
        let depuisCompte = false;
        if (ligneBiblio) {
          await ligneBiblio.click();
          await a.page.waitForTimeout(3000);
          depuisCompte = await surBibliotheque();
        }
        if (!depuisCompte) await aller(a.page, '/tc/bibliotheque');
        p.dire(`  R3 ${role} ${langue} ${largeur} : Bibliotheque ${depuisCompte ? 'ouverte depuis le Compte' : 'ouverte par son adresse (pas de ligne dans le Compte)'}`);
        await p.capture(a, `${langue}_${largeur}_${role}_bibliotheque${depuisCompte ? '_depuis_compte' : ''}`);
        // La sortie : le geste visible (segment du fil au bureau, disque
        // retour au telephone), puis la Bibliotheque n'est plus a l'ecran.
        const geste = largeur < 600
          ? await trouver(a.page, lire(L, 'commun.entete.retour'), { delai: 4000, exact: true })
          : a.page.locator(`[flt-semantics-identifier="filAriane:${role === 'famille' ? '/tuteur/compte' : '/enseignant/profil'}"]`).first();
        let sortie = false;
        if (geste && (largeur < 600 || await geste.count())) {
          await geste.click();
          await a.page.waitForTimeout(2500);
          sortie = !(await surBibliotheque());
        }
        p.dire(`    sortie : ${largeur < 600 ? 'disque retour' : 'segment du fil'} -> ${sortie ? hash(a.page) : 'AUCUNE'}`);
        if (!sortie) rouges += 1;
        await p.capture(a, `${langue}_${largeur}_${role}_apres_sortie`);
        if (role === 'famille') {
          await aller(a.page, `/tuteur/foyer/${ID.eleve}/finances`);
          await a.page.waitForTimeout(2000);
          await p.capture(a, `${langue}_${largeur}_famille_fiche_finances`);
          await aller(a.page, `/tuteur/foyer/${ID.eleve}`);
          await p.capture(a, `${langue}_${largeur}_famille_fiche`);
        }
        await a.ctx.close();
      }
      const d = await p.contexte('direction', options);
      await connecterRole(d.page, 'direction', L);
      await aller(d.page, '/admin/pedagogie/bibliotheque');
      await p.capture(d, `${langue}_${largeur}_direction_pedagogie_bibliotheque`);
      await d.ctx.close();
    }
  }
}

let code = 1;
try {
  amorcer();
  if (!process.env.E2E_FIL_SANS_CAPTURES) await capturesR3();
  if (!SEULEMENT_R3) {
    for (const largeur of TAILLES) {
      for (const role of ROLES) await jouerRole(role, largeur);
    }
  }
  rapport.fin = new Date().toISOString();
  rapport.routesJouees = rapport.joues.length;
  rapport.sansSortie = rapport.joues.filter((j) => j.geste === null).map((j) => `${j.role} ${j.largeur} ${j.demande} -> ${j.obtenu}`);
  rapport.parGeste = rapport.joues.reduce((o, j) => ({ ...o, [j.geste ?? 'aucune']: (o[j.geste ?? 'aucune'] ?? 0) + 1 }), {});
  rapport.routesDistinctes = new Set(rapport.joues.map((j) => j.route)).size;
  fs.writeFileSync(path.join(p.sortie, 'rapport.json'), JSON.stringify(rapport, null, 2));
  p.dire(`Routes jouees : ${rapport.routesJouees} ; sans sortie : ${rapport.sansSortie.length}`);
  code = await p.fin(rouges === 0 ? 'vert' : 'rouge', rouges === 0 ? '' : `${rouges} page(s) sans sortie (rapport.json)`);
} catch (e) {
  p.dire(`erreur : ${e.stack ?? e}`);
  fs.writeFileSync(path.join(p.sortie, 'rapport.json'), JSON.stringify(rapport, null, 2));
  code = await p.fin('rouge', String(e).slice(0, 200));
}
process.exit(code);
