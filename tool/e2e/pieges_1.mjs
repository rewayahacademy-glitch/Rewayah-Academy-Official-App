// Parcours 1 : les pieges d'une personne pressee (docs/current/captures/E2E/parcours-1/pieges.md).
// Chaque piege est joue pour de vrai dans le navigateur, sur la pile locale ;
// le resultat (vert / rouge / non joue) est reecrit dans pieges.md.
// Vert : l'ecran guide ou rattrape. Rouge : l'erreur passe sans un mot clair
// ou sans moyen de revenir (constat UX-xxx ou FN-xxx a ouvrir).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  dernierLien, activerSemantique, sql, COMPTES, DEPOT, APP } from './commun.mjs';

const p = await parcours('Parcours 1 : pieges', 'parcours-1/pieges');
const PIECE = path.join(DEPOT, 'tool/e2e/piece_factice.png');
const PDF = path.join(p.sortie, '..', 'document_test.pdf');
fs.writeFileSync(PDF, '%PDF-1.4\n% E2E document de test, pas une image\n%%EOF\n');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
let n = 0;
const adresse = (x) => `e2e-p1-${x}-${Date.now().toString(36)}${n++}@example.com`;

async function inviter(d, courriel, { doubleClic = false } = {}) {
  await cliquer(d.page, 'Personnes Onglet');
  await cliquer(d.page, /^Sections de la page/);
  await cliquer(d.page, /^Candidatures/, { pause: 1500 });
  await cliquer(d.page, /^Invitations$/, { pause: 1500 });
  await cliquer(d.page, /^Un enseignant\./);
  await taper(d.page, 'textarea, input[aria-label^="Adresse de courriel"]', courriel);
  const b = await trouver(d.page, /^Créer l'invitation$/, { role: 'button' });
  if (doubleClic) await b.dblclick(); else await b.click();
  await d.page.waitForTimeout(2500);
  // Message actuel (i1.invitations.creee) : « Invitation créée. L'e-mail avec
  // le code XXXX‑XXXX‑XXXX part vers … » ; le code s'ecrit avec un tiret
  // insecable, rendu en tiret simple (comme parcours_1).
  const message = await trouverTexte(d.page, /(Invitation créée|Transmettez ce code|existe déjà|déjà active|n'a pas la forme|pas confirmée|pas été créée)[^|]*/, 8000);
  const code = message?.match(/([A-Z0-9]{4}(?:[-\u2010\u2011\u2013][A-Z0-9]{4})+)/)?.[1]
    ?.replace(/[\u2010\u2011\u2013]/g, '-') ?? null;
  return { message, code };
}

/// Cree le compte de la candidate par le lien, jusqu'a l'ecran « Votre code ».
async function compteParLien(c, courriel) {
  await ouvrir(c.page, '/');
  // Depuis ENTREE-ORDRE (05/11/2026), `/` ouvre directement le questionnaire.
  await cliquer(c.page, /^J'ai un code d'invitation$/);
  const depuis = Date.now();
  await taper(c.page, 'input[inputmode=email], input[autocomplete=email]', courriel);
  await cliquer(c.page, /^Recevoir le lien/, { pause: 2000 });
  const recu = await dernierLien(courriel, depuis);
  await c.page.goto(recu.lien);
  await c.page.waitForTimeout(6000);
  await activerSemantique(c.page);
  const encore = await trouver(c.page, /^J'ai un code d'invitation$/, { delai: 4000 });
  if (encore) { await encore.click(); await c.page.waitForTimeout(1500); }
  return recu.lien;
}

async function verifierCode(c, code) {
  const autre = await trouver(c.page, /^Saisir un autre code/, { delai: 1000 });
  if (autre) { await autre.click(); await c.page.waitForTimeout(1500); }
  await taper(c.page, 'textarea, input', code);
  await cliquer(c.page, /^Vérifier le code$/, { pause: 2500 });
  const r = await trouverTexte(c.page, /(Invitation valide|non reconnu|n'a pas pu être utilisé|expiré|ne correspond|invalide|introuvable|Saisissez)[^|]*/, 6000);
  const suite = await trouverTexte(c.page, /Vérifiez le code[^|]*|Demandez[^|]*/, 800);
  return r && suite && !/Invitation valide/.test(r) ? `${r} ${suite}` : r;
}

async function piege(id, f) {
  try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 900)}`); }
}

const d = await p.contexte('direction');
await connecter(d.page, COMPTES.direction);

await piege('1.1', async () => {
  const brut = `  E2E-Maj-${Date.now().toString(36)}@Example.COM `;
  const inv = await inviter(d, brut);
  await p.capture(d, 'p1-1_invitation_majuscules');
  if (!inv.code) return noter('1.1', 'rouge', `adresse avec majuscules et espaces refusee : « ${inv.message} »`);
  const c = await p.contexte('candidate-maj');
  await compteParLien(c, brut.trim().toLowerCase());
  const r = await verifierCode(c, inv.code);
  await p.capture(c, 'p1-1_code_en_minuscules');
  noter('1.1', /Invitation valide/.test(r ?? '') ? 'vert' : 'rouge', `invitation « ${inv.message} » ; code verifie avec l'adresse en minuscules : « ${r} »`);
  await c.ctx.close();
});

await piege('1.2', async () => {
  const inv = await inviter(d, COMPTES.direction);
  await p.capture(d, 'p1-2_adresse_existante');
  noter('1.2', /existe déjà/.test(inv.message ?? '') ? 'vert' : 'rouge', `« ${inv.message} »`);
});

await piege('1.3', async () => {
  const courriel = adresse('double');
  const inv = await inviter(d, courriel, { doubleClic: true });
  const nb = sql(`select count(*) from public.invitations_enseignant where lower(email) = lower('${courriel}')`);
  await p.capture(d, 'p1-3_double_clic');
  noter('1.3', nb === '1' ? 'vert' : 'rouge', `${nb} invitation(s) en base ; message « ${inv.message} »`);
});

// Une invitation pour les pieges de la candidate.
const C1 = adresse('cand');
const inv1 = await inviter(d, C1);
const C2 = adresse('autre');
const inv2 = await inviter(d, C2);
p.dire(`Invitations : ${C1} ${inv1.code} ; ${C2} ${inv2.code}`);
const c = await p.contexte('candidate');
await compteParLien(c, C1);

await piege('1.5', async () => {
  const faux = inv1.code.slice(0, -1) + (inv1.code.endsWith('A') ? 'B' : 'A');
  const r = await verifierCode(c, faux);
  await p.capture(c, 'p1-5_code_faux');
  noter('1.5', r && !/Invitation valide/.test(r) ? 'vert' : 'rouge', `code faux : « ${r} »`);
});
await piege('1.6', async () => {
  const r = await verifierCode(c, inv2.code);
  await p.capture(c, 'p1-6_code_autre_adresse');
  noter('1.6', r && !/Invitation valide/.test(r) ? 'vert' : 'rouge', `code d'une autre adresse : « ${r} »`);
});
await piege('1.4', async () => {
  const r = await verifierCode(c, ` ${inv1.code.toLowerCase().replace(/-/g, ' - ')} `);
  await p.capture(c, 'p1-4_code_minuscules_espaces');
  noter('1.4', /Invitation valide/.test(r ?? '') ? 'vert' : 'rouge', `code en minuscules avec espaces : « ${r} »`);
  if (!/Invitation valide/.test(r ?? '')) await verifierCode(c, inv1.code);
});

await cliquer(c.page, /^Créer mon profil$/, { pause: 2000 });
await piege('1.10', async () => {
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  const m = await trouverTexte(c.page, /(nécessaire|obligatoire|Indiquez|Saisissez)[^|]*/, 3000);
  await p.capture(c, 'p1-10_identite_vide');
  noter('1.10', m && /identite/.test(c.page.url()) ? 'vert' : 'rouge', `« Continuer » a vide : ${m ? `« ${m} »` : 'aucun message'} ; ${c.page.url()}`);
});
await piege('1.9', async () => {
  await taper(c.page, 'input[aria-label="Prénom"]', 'E2E ' + 'Abdourahmane'.repeat(6));
  await taper(c.page, 'input[aria-label="Nom"]', 'النجار');
  await p.capture(c, 'p1-9_arabe_long');
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  const ok = /genre/.test(c.page.url());
  noter('1.9', ok ? 'vert' : 'rouge', `prenom de 76 caracteres et nom en arabe : ${ok ? 'acceptes' : `refuses (${(await libelles(c.page)).slice(0, 6).join(' | ')})`}`);
  if (ok) await cliquer(c.page, /^Retour$/, { pause: 1500 });
});
await piege('1.8', async () => {
  await taper(c.page, 'input[aria-label="Prénom"]', 'E2E Rechargee');
  await taper(c.page, 'input[aria-label="Nom"]', 'Enseignante');
  await c.page.reload();
  await c.page.waitForTimeout(6000);
  await activerSemantique(c.page);
  await p.capture(c, 'p1-8_apres_rechargement');
  const l = await libelles(c.page);
  const garde = await c.page.locator('input[aria-label="Prénom"]').inputValue().catch(() => '');
  noter('1.8', /identite/.test(c.page.url()) && garde ? 'vert' : 'rouge',
    `apres rechargement : ${c.page.url()} ; prenom ${garde ? `garde (« ${garde} »)` : 'vide'} ; ecran : ${l.filter((x) => x.startsWith('flt-semantics:')).slice(0, 3).join(' | ')}`);
});

// Remettre la candidate sur le chemin : identite, genre, compte.
/// « Compléter ma candidature », le questionnaire de 24 etapes (une reponse
/// neutre a chaque question) puis « Envoyer ma candidature », une fois le cadre
/// accepte. Chaque etape est journalisee.
async function completerCandidature() {
  // On quitte l'ecran de la piece (refusee avant la candidature) : retour au dossier.
  if (/piece/.test(c.page.url())) { await ouvrir(c.page, '/'); await c.page.waitForTimeout(3000); await activerSemantique(c.page); }
  // FIXTURE LOCALE, pas un parcours d'ecran : aucun ecran du client n'enregistre
  // l'acceptation du cadre religieux et pedagogique (la page des accords ne le propose
  // pas ; constat remonte au pilote le 07/11). On l'ecrit en SQL pour que l'envoi
  // de la candidature, lui, puisse etre rejoue.
  p.dire('  FIXTURE : acceptation du cadre ecrite en SQL local (aucun ecran ne la propose)');
  sql(`insert into public.contract_acceptances (profile_id, contract_kind, version)
    select u.id, 'teacher_religious_framework', r.version
      from auth.users u, public.contract_required_versions r
     where u.email = '${C1}' and r.contract_kind = 'teacher_religious_framework'
    on conflict do nothing`);
  await ouvrir(c.page, '/'); await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  const completer = await trouver(c.page, /^Compléter ma candidature$/, { delai: 20000 });
  if (!completer) {
    const lab = (await libelles(c.page)).filter((x) => /^(flt-semantics|button|checkbox)/.test(x)).join(' | ');
    throw new Error(`apres « Envoyer ma candidature » : ecran ${lab.slice(0, 600)}`);
  }
  await completer.click(); await c.page.waitForTimeout(2500); await activerSemantique(c.page);
  // Questionnaire de candidature (« Étape N sur 23 ») : une reponse neutre a
  // chaque question jusqu'aux conditions. Chaque etape est journalisee.
  for (let k = 0; k < 40; k++) {
    const l = await libelles(c.page);
    p.dire(`  candidature ${k} : ${l.filter((x) => /^(flt-semantics|h2|input|textarea|radio|checkbox|button)/.test(x)).slice(0, 7).join(' | ').slice(0, 260)}`);
    // « Relisez votre candidature » : les cases et l'envoi sont plus bas ; on
    // defile pour qu'ils existent dans la page.
    if (l.some((x) => /Relisez votre candidature/.test(x))) {
      await c.page.mouse.move(600, 400);
      await c.page.mouse.wheel(0, 6000);
      await c.page.waitForTimeout(1200);
      await activerSemantique(c.page);
      // La photo est obligatoire pour envoyer (« Votre photo est obligatoire ») : portrait fictif.
      const choisirPhoto = await trouver(c.page, /^Choisir une photo/, { delai: 2500 });
      if (choisirPhoto) {
        c.page.once('filechooser', (fc) => fc.setFiles(path.join(DEPOT, 'tool/e2e/portrait_factice.png')));
        await choisirPhoto.click();
        await c.page.waitForTimeout(3500);
        await activerSemantique(c.page);
        const valider = await trouver(c.page, /^(Utiliser cette photo|Valider|Enregistrer|Confirmer|Continuer)/, { delai: 2500, role: 'button' });
        if (valider) { await valider.click(); await c.page.waitForTimeout(3000); }
        await p.capture(c, 'p1-photo_candidate');
      }
    }
    for (const champ of await c.page.locator('input:visible, textarea:visible').all()) {
      const v = await champ.inputValue().catch(() => '');
      if (!v) { await champ.click({ force: true }); await c.page.keyboard.type('Reponse E2E', { delay: 8 }); }
    }
    // « À quelle heure pouvez-vous commencer, le … ? » : des pastilles d'heure
    // (FilterPill), aucune n'est choisie d'avance.
    if (l.some((x) => /À quelle heure pouvez-vous commencer/.test(x))) {
      const heure = await trouver(c.page, /^\d{1,2}[\s\u00a0]?h/, { delai: 2000, role: 'button' });
      if (heure) { await heure.click(); await c.page.waitForTimeout(300); }
    }
    const radios = c.page.getByRole('radio');
    if (await radios.count() && !(await c.page.locator('[role=radio][aria-checked=true]').count())) { await radios.first().click(); await c.page.waitForTimeout(300); }
    const cochees = c.page.getByRole('checkbox');
    for (let i = 0; i < await cochees.count(); i++) {
      if ((await cochees.nth(i).getAttribute('aria-checked')) !== 'true') { await cochees.nth(i).click(); await c.page.waitForTimeout(200); }
    }
    const suite = await trouver(c.page, /^(Continuer|Suivant|Commencer|C'est parti|Envoyer.*)$/, { delai: 2500, role: 'button' });
    if (!suite) {
      await p.capture(c, `p1-suite_etape_${k}_sans_bouton`);
      throw new Error(`candidature, etape ${k} : aucun bouton de suite ; ${l.filter((x) => /^(button|checkbox|radio)/.test(x)).join(' | ').slice(-700)}`);
    }
    const nomBouton = (await suite.getAttribute('aria-label')) ?? (await suite.textContent()) ?? '';
    await suite.click(); await c.page.waitForTimeout(1500); await activerSemantique(c.page);
    if (/^Envoyer/.test(nomBouton.trim())) {
      // Le resultat de l'envoi : la phrase de succes, ou le message du serveur.
      await c.page.waitForTimeout(3500);
      await activerSemantique(c.page);
      await p.capture(c, 'p1-envoi_candidature');
      const ok = await trouverTexte(c.page, /Votre candidature est envoyée[^|]*/, 3000);
      const refus = await trouverTexte(c.page, /(Il manque une réponse|n'est plus valable|à revoir|se chevauchent|ne soit pas parvenue|pas été envoyée|Acceptez|Cochez|refus)[^|]*/i, 1500);
      const etat = sql(`select c.etape || '/' || c.etat from public.candidatures c join public.profiles pr on pr.id = c.profile_id
        where pr.first_name = 'E2E Candidate' and pr.last_name = 'Pieges' order by c.recue_le desc limit 1`);
      const envoyee = /en_examen/.test(etat);
      noter('questionnaire', ok || envoyee ? 'vert' : 'rouge', `24 etapes puis « Envoyer ma candidature » : ${ok ? `« ${ok} »` : (envoyee ? 'candidature envoyee (la base la dit en examen)' : `pas de phrase de succes${refus ? `, message « ${refus} »` : ''}`)} ; candidature en base : ${etat}`);
      return;
    }
  }
  throw new Error('candidature : le questionnaire ne finit pas');
}

await piege('suite', async () => {
  // Apres le rechargement, l'ecran n'offre plus que « Créer mon profil » avec le
  // code mal forme de l'URL (constat, voir le bilan) : on rouvre l'ecran du
  // code avec le code exact pour que la creation reussisse.
  await c.page.goto(`${APP}/#/inscription/invitation?code=${inv1.code}`);
  await c.page.reload();
  await c.page.waitForTimeout(6000);
  await activerSemantique(c.page);
  await cliquer(c.page, /^Créer mon profil$/, { pause: 2000 });
  await taper(c.page, 'input[aria-label="Prénom"]', 'E2E Candidate');
  await taper(c.page, 'input[aria-label="Nom"]', 'Pieges');
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await cliquer(c.page, /^Une femme\./, { role: 'radio' });
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  // Depuis CAND-04, le candidat enseignant donne son telephone (pays puis
  // numero) avant le recapitulatif : /inscription/telephone.
  if (await trouver(c.page, /^(Choisir votre pays|Pays\b)/, { delai: 3000 })) {
    await cliquer(c.page, /^(Choisir votre pays|Pays\b)/, { pause: 1000 });
    await taper(c.page, 'input[type=text], input:not([aria-label])', 'France');
    await cliquer(c.page, /^France, \+33/, { pause: 1000 });
    await taper(c.page, 'input[aria-label^="Numéro"]', '612345678');
    await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  }
  // Recapitulatif du candidat : politique de confidentialite a cocher, puis
  // « Envoyer ma candidature » (t.inscription.candidat.envoyer).
  const caseConf = await trouver(c.page, /^J'ai lu et j'accepte la politique de confidentialité/, { delai: 3000 });
  if (caseConf && (await caseConf.getAttribute('aria-checked')) !== 'true') { await caseConf.click(); await c.page.waitForTimeout(500); }
  await cliquer(c.page, /^Envoyer ma candidature$/, { pause: 3000 });
  await activerSemantique(c.page);
  await p.capture(c, 'p1-suite_apres_envoi');
  // Le compte cree, la candidate arrive sur « Votre dossier » : le cadre
  // religieux et pedagogique (publie par la direction) est a accepter d'abord ;
  // « Compléter ma candidature » vient ensuite (voir completerCandidature).
  const cadre = await trouver(c.page, /^Lire et accepter nos conditions$/, { delai: 20000 });
  if (!cadre) {
    const lab = (await libelles(c.page)).filter((x) => /^(flt-semantics|button|checkbox)/.test(x)).join(' | ');
    throw new Error(`apres « Envoyer ma candidature » : pas de « Lire et accepter nos conditions » ; ecran ${lab.slice(0, 600)}`);
  }
  await cadre.click(); await c.page.waitForTimeout(2000); await activerSemantique(c.page);
  R.suite = undefined;
});
await piege('1.13', async () => {
  // FN-102 (lot 13, 06/11/2026) : le nom signe est celui du compte, montre en
  // lecture seule ; le serveur l'ecrit lui-meme (20261108400000). Le piege
  // essaie quand meme de taper un autre nom, signe, puis lit le nom
  // enregistre en base.
  const champ = c.page.locator('textarea[aria-label^="Nom du signataire"], input[aria-label^="Nom du signataire"]').first();
  let valeur = '';
  if (await champ.count()) {
    await champ.click({ force: true });
    await c.page.keyboard.press('Control+A');
    await c.page.keyboard.type('Quelqu\'un d\'autre');
    valeur = await champ.inputValue().catch(() => '');
  }
  const cases = c.page.getByRole('checkbox');
  for (let i = 0; i < await cases.count(); i++) {
    if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await c.page.waitForTimeout(300); }
  }
  await cliquer(c.page, /^Suivant$/, { pause: 3000 });
  await activerSemantique(c.page);
  await p.capture(c, 'p1-13_signature_autre_nom');
  const signe = sql(`select ca.signer_name from public.contract_acceptances ca join public.profiles pr on pr.id = ca.profile_id
    where ca.contract_kind = 'teacher_nda' and pr.first_name = 'E2E Candidate' and pr.last_name = 'Pieges'
    order by ca.accepted_at desc limit 1`);
  const tape = /Quelqu/.test(valeur);
  const ok = !tape && signe === 'E2E Candidate Pieges';
  noter('1.13', ok ? 'vert' : 'rouge', ok
    ? `nom en lecture seule (champ : « ${valeur} ») ; signature enregistree au nom du compte : « ${signe} »`
    : `champ : « ${valeur} » ; signature enregistree : « ${signe || 'aucune'} »`);
});
await piege('1.11', async () => {
  // Diagnostic : les appels refuses (statut et debut du message du serveur, jamais une cle).
  c.page.on('response', async (r) => {
    if (r.status() >= 400 && /\/(rest|functions|storage)\/v1\//.test(r.url())) {
      p.dire(`  reseau : ${r.request().method()} ${new URL(r.url()).pathname.replace(/[0-9a-f-]{36}/g, '<id>')} -> ${r.status()}${r.status() >= 400 ? ` ${(await r.text().catch(() => '')).slice(0, 160)}` : ''}`);
    }
  });
  if (!/piece/.test(c.page.url())) return noter('1.11', 'non joué', 'ecran « Votre pièce » non atteint');
  // « Un bouton qui ne peut pas aboutir n'est pas rendu » : sans type ni photo,
  // « Envoyer ma pièce » n'existe pas dans la page, l'erreur est impossible.
  const envoyerSans = await trouver(c.page, /^Envoyer ma pièce$/, { delai: 2500, role: 'button' });
  if (!envoyerSans) {
    await p.capture(c, 'p1-11_envoyer_sans_piece');
    return noter('1.11', 'non joué', 'hors de l\'ordre actuel (voir 1.12) ; constat : « Envoyer ma pièce » n\'est pas rendu tant que le type et la photo manquent');
  }
  // Present mais inactif (aria-disabled) : le clic n'aboutit pas, Playwright attend ;
  // on borne l'attente a 3 s.
  const clique = await envoyerSans.click({ timeout: 3000 }).then(() => true).catch(() => false);
  if (!clique) {
    await p.capture(c, 'p1-11_envoyer_sans_piece');
    return noter('1.11', 'non joué', 'hors de l\'ordre actuel (voir 1.12) ; constat : « Envoyer ma pièce » est inactif tant que le type et la photo manquent');
  }
  await c.page.waitForTimeout(2000);
  const m = await trouverTexte(c.page, /(Choisissez|choisir|ajoutez|photo)[^|]*/i, 3000);
  await p.capture(c, 'p1-11_envoyer_sans_piece');
  noter('1.11', m && /piece/.test(c.page.url()) ? 'vert' : 'rouge', `« Envoyer ma pièce » sans type ni photo : ${m ? `« ${m} »` : 'aucun message'}`);
});
await piege('1.12', async () => {
  if (!/piece/.test(c.page.url())) return noter('1.12', 'non joué', 'ecran « Votre pièce » non atteint');
  await cliquer(c.page, /^Carte d'identité\./, { role: 'radio' });
  c.page.once('filechooser', (fc) => fc.setFiles(PDF));
  await cliquer(c.page, /^Choisir la photo$/, { pause: 3000 });
  await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 4000 });
  await activerSemantique(c.page);
  await p.capture(c, 'p1-12_pdf');
  // Le texte fixe de l'ecran (« Une photo lisible suffit ») n'est pas un refus : on
  // ne retient qu'un message sur le format. « L'envoi n'a pas abouti » est autre chose.
  const echec = await trouverTexte(c.page, /L'envoi n'a pas abouti[^|]*/, 2000);
  const m = await trouverTexte(c.page, /(n'est pas une image|format|JPEG|PNG|type de fichier)[^|]*/i, 3000);
  const depose = await trouverTexte(c.page, /en cours de vérification/, 2000);
  if (echec && !m && !depose) {
    // CAND-L1B (20261022...) : la piece d'un compte candidat « se depose en Salle de
    // verification et d'entretien (candidature en cours) ou apres » : le serveur
    // refuse (403 sur kyc_documents) avant l'envoi de la candidature. L'ecran, lui,
    // affiche « Votre piece d'identite » apres les accords et dit « Reessayez dans un
    // instant » : mauvaise cause, aucune issue (K-59).
    return noter('1.12', 'non joué', `hors de l'ordre actuel ; CONSTAT PRODUIT (ticket) : apres les accords l'application propose « Votre pièce d'identité » ; le serveur refuse le dépôt (403, CAND-L1B : la pièce d'un compte candidat se dépose en Salle de vérification, après l'envoi de la candidature) et l'écran dit « ${echec} » : mauvaise cause, aucune issue ; piège « PDF » non tranché ici`);
  }
  noter('1.12', depose ? 'rouge' : (m ? 'vert' : 'rouge'), depose ? 'un PDF qui n\'est pas une image est accepte comme piece d\'identite' : `PDF : ${m ? `« ${m} »` : 'aucun message clair'}`);
  if (!depose) {
    c.page.once('filechooser', (fc) => fc.setFiles(PIECE));
    const ch = await trouver(c.page, /^(Choisir la photo|Changer la photo|Choisir une autre photo)/, { delai: 2000 });
    if (ch) { await ch.click(); await c.page.waitForTimeout(2500); }
    await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 4000 });
  }
});
await piege('questionnaire', completerCandidature);
await piege('1.14', async () => {
  const autre = await p.contexte('candidate-lendemain', { telephone: true });
  const { connecterParLien } = await import('./commun.mjs');
  await connecterParLien(autre.page, C1);
  await p.capture(autre, 'p1-14_autre_appareil');
  const m = await trouverTexte(autre.page, /(Votre dossier[^|]*|en cours de vérification|Il manque|À fournir)[^|]*/, 8000);
  noter('1.14', m ? 'vert' : 'rouge', `autre appareil, le lendemain : ${m ? `« ${m} »` : 'rien ne dit ou en est le dossier'}`);
  await autre.ctx.close();
});
await piege('1.15', async () => {
  const autre = await p.contexte('lien-deux-fois');
  const r = await (await fetch(`${(await import('./commun.mjs')).MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${C1}`)}`)).json();
  // Le plus ancien courriel qui porte un lien de verification (l'invitation de
  // l'academie, livree par la file, n'en porte pas).
  let lien;
  for (const premier of [...r.messages].reverse()) {
    const m = await (await fetch(`${(await import('./commun.mjs')).MAILPIT}/api/v1/message/${premier.ID}`)).json();
    lien = [...`${m.HTML} ${m.Text}`.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&')).find((u) => u.includes('/auth/v1/verify'));
    if (lien) break;
  }
  await autre.page.goto(lien); await autre.page.waitForTimeout(6000); await activerSemantique(autre.page);
  await p.capture(autre, 'p1-15_lien_deja_utilise');
  const l = (await libelles(autre.page)).filter((x) => x.startsWith('flt-semantics:') || x.startsWith('button:')).slice(0, 6).join(' | ');
  const clair = /(expiré|déjà|plus valable|nouveau lien|Recevoir)/i.test(l);
  noter('1.15', clair ? 'vert' : 'rouge', `lien deja utilise, ouvert de nouveau : ${autre.page.url()} ; ${l}`);
  await autre.ctx.close();
});

// Direction : les pieges sur le dossier de la candidate.
await ouvrir(d.page, '/');
await d.page.waitForTimeout(1500);
await cliquer(d.page, 'Personnes Onglet');
await cliquer(d.page, /^Sections de la page/);
await cliquer(d.page, /^Dossiers à valider/, { pause: 2000 });
const dossier = await trouver(d.page, /Pieges/, { delai: 10000 });
if (dossier) { await dossier.click(); await d.page.waitForTimeout(2500); }
await piege('1.16', async () => {
  if (!dossier) return noter('1.16', 'non joué', `hors de l'ordre actuel : la pièce se dépose après l'envoi de la candidature et l'entretien (CAND-L1B), plus juste après les accords ; un robot « candidature complète, entretien, pièce » est un autre lot`);
  const v = await trouver(d.page, /^Valider le dossier/, { delai: 3000 });
  const aide = await trouverTexte(d.page, /(Terminez les vérifications|pas encore prêt)[^|]*/, 3000);
  if (v) { await v.click({ timeout: 3000 }).catch(() => {}); await d.page.waitForTimeout(1500); }
  await p.capture(d, 'p1-16_valider_sans_cases');
  const valide = await trouverTexte(d.page, /Dossier validé/, 1500);
  noter('1.16', !valide && aide ? 'vert' : 'rouge', valide ? 'dossier valide sans les trois verifications' : `« ${aide ?? 'aucune phrase'} »`);
});
await piege('1.17', async () => {
  if (!dossier) return noter('1.17', 'non joué', `hors de l'ordre actuel : la pièce se dépose après l'envoi de la candidature et l'entretien (CAND-L1B), plus juste après les accords ; un robot « candidature complète, entretien, pièce » est un autre lot`);
  const caseLisible = d.page.getByRole('checkbox', { name: /La pièce est lisible/ }).first();
  const active = await caseLisible.isEnabled().catch(() => false);
  await p.capture(d, 'p1-17_cases_avant_piece');
  noter('1.17', active ? 'rouge' : 'vert', active ? 'les cases se cochent sans avoir ouvert la piece' : 'cases inactives tant que la piece n\'a pas ete ouverte');
});
await piege('1.18', async () => {
  if (!dossier) return noter('1.18', 'non joué', `hors de l'ordre actuel : la pièce se dépose après l'envoi de la candidature et l'entretien (CAND-L1B), plus juste après les accords ; un robot « candidature complète, entretien, pièce » est un autre lot`);
  await cliquer(d.page, /Voir la pièce$/, { pause: 3500 });
  const fermer = await trouver(d.page, /^Fermer$/, { delai: 2000, role: 'button' });
  if (fermer) { await fermer.click(); await d.page.waitForTimeout(1000); }
  for (const l of [/^La pièce est lisible/, /^Le nom correspond/, /^La pièce n'est pas expirée/]) await cliquer(d.page, l, { role: 'checkbox', pause: 400 });
  const v = await trouver(d.page, /^Valider le dossier/, { delai: 3000, role: 'button' });
  await v.dblclick();
  await d.page.waitForTimeout(3000);
  await p.capture(d, 'p1-18_double_clic_valider');
  const decisions = sql(`select count(*) from public.audit_logs where action = 'kyc_decision' and created_at > now() - interval '2 minutes'`);
  const erreur = await trouverTexte(d.page, /(déjà décidé|erreur|n'a pas)[^|]*/i, 1500);
  noter('1.18', decisions === '1' && !erreur ? 'vert' : 'rouge', `${decisions} decision(s) journalisee(s) ; ${erreur ? `message « ${erreur} »` : 'aucun message d\'erreur'}`);
});
noter('1.7', 'rouge', 'joué en exploration (31/10 20:56 UTC) : apres le lien, « Je m\'inscris pour moi » mene au parcours famille jusqu\'a « Votre demande est en cours », sans rappel du code d\'invitation ni retour vers l\'inscription enseignante (UX-013)');
noter('1.19', 'non joué', 'refuser exige un motif et retire l\'acces : a jouer sur un dossier dedie');
noter('1.20', 'non joué', 'lecture faite sur les captures, voir le bilan');
noter('1.21', 'non joué', 'parcours candidate au telephone : a jouer');
noter('1.22', 'non joué', 'direction au telephone : a jouer');

// Report dans pieges.md.
const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-1/pieges.md');
const lignes = fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (1\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
});
fs.writeFileSync(f, lignes.join('\n'));
await p.fin('joué');
