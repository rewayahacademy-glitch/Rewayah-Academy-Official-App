// Parcours 1 : les pieges d'une personne pressee (docs/current/captures/E2E/parcours-1/pieges.md).
// Chaque piege est joue pour de vrai dans le navigateur, sur la pile locale ;
// le resultat (vert / rouge / non joue) est reecrit dans pieges.md.
// Vert : l'ecran guide ou rattrape. Rouge : l'erreur passe sans un mot clair
// ou sans moyen de revenir (constat UX-xxx ou FN-xxx a ouvrir).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  dernierLien, activerSemantique, sql, COMPTES, DEPOT } from './commun.mjs';

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
  const message = await trouverTexte(d.page, /(Transmettez ce code|existe déjà|déjà active|n'a pas la forme|pas confirmée|pas été créée)[^|]*/, 8000);
  const code = message?.match(/:\s*([A-Z0-9]{4}(?:-[A-Z0-9]{4})+)/)?.[1] ?? null;
  return { message, code };
}

/// Cree le compte de la candidate par le lien, jusqu'a l'ecran « Votre code ».
async function compteParLien(c, courriel) {
  await ouvrir(c.page, '/');
  await cliquer(c.page, /^Créer un compte$/);
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
  try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 220)}`); }
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
await piege('suite', async () => {
  const code = await trouver(c.page, /^J'ai un code d'invitation$/, { delai: 2000 });
  if (code) { await code.click(); await c.page.waitForTimeout(1500); }
  if (await trouver(c.page, /^Créer mon profil$/, { delai: 2000 })) await cliquer(c.page, /^Créer mon profil$/, { pause: 2000 });
  const v = await trouver(c.page, /^Vérifier le code$/, { delai: 1500 });
  if (v) { await verifierCode(c, inv1.code); await cliquer(c.page, /^Créer mon profil$/, { pause: 2000 }); }
  await taper(c.page, 'input[aria-label="Prénom"]', 'E2E Candidate');
  await taper(c.page, 'input[aria-label="Nom"]', 'Pieges');
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await cliquer(c.page, /^Une femme\./, { role: 'radio' });
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await cliquer(c.page, /^Créer mon compte$/, { pause: 3000 });
  await activerSemantique(c.page);
  await cliquer(c.page, /^Lire et accepter nos conditions$/, { pause: 2000 });
  R.suite = undefined;
});
await piege('1.13', async () => {
  await taper(c.page, 'textarea[aria-label^="Votre nom complet"], input[aria-label^="Votre nom complet"]', 'Quelqu\'un d\'autre');
  const cases = c.page.getByRole('checkbox');
  for (let i = 0; i < await cases.count(); i++) {
    if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await c.page.waitForTimeout(300); }
  }
  await cliquer(c.page, /^Suivant$/, { pause: 3000 });
  await activerSemantique(c.page);
  await p.capture(c, 'p1-13_signature_autre_nom');
  const refuse = await trouverTexte(c.page, /(ne correspond|nom du compte|comme sur votre pièce)[^|]*/, 2000);
  const passe = /piece/.test(c.page.url());
  noter('1.13', passe ? 'rouge' : 'vert', passe ? 'signature « Quelqu\'un d\'autre » acceptee sans un mot (nom du compte : E2E Candidate Pieges)' : `refusee : « ${refuse} »`);
});
await piege('1.11', async () => {
  if (!/piece/.test(c.page.url())) return noter('1.11', 'non joué', 'ecran « Votre pièce » non atteint');
  await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 2000 });
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
  const m = await trouverTexte(c.page, /(format|image|photo|n'est pas|accept)[^|]*/i, 3000);
  const depose = await trouverTexte(c.page, /en cours de vérification/, 2000);
  noter('1.12', depose ? 'rouge' : (m ? 'vert' : 'rouge'), depose ? 'un PDF qui n\'est pas une image est accepte comme piece d\'identite' : `PDF : ${m ? `« ${m} »` : 'aucun message clair'}`);
  if (!depose) {
    c.page.once('filechooser', (fc) => fc.setFiles(PIECE));
    const ch = await trouver(c.page, /^(Choisir la photo|Changer la photo|Choisir une autre photo)/, { delai: 2000 });
    if (ch) { await ch.click(); await c.page.waitForTimeout(2500); }
    await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 4000 });
  }
});
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
  const premier = r.messages[r.messages.length - 1];
  const m = await (await fetch(`${(await import('./commun.mjs')).MAILPIT}/api/v1/message/${premier.ID}`)).json();
  const lien = [...`${m.HTML} ${m.Text}`.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&')).find((u) => u.includes('/auth/v1/verify'));
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
  if (!dossier) return noter('1.16', 'non joué', 'dossier de la candidate absent de la file');
  const v = await trouver(d.page, /^Valider le dossier/, { delai: 3000 });
  const aide = await trouverTexte(d.page, /(Terminez les vérifications|pas encore prêt)[^|]*/, 3000);
  if (v) { await v.click({ timeout: 3000 }).catch(() => {}); await d.page.waitForTimeout(1500); }
  await p.capture(d, 'p1-16_valider_sans_cases');
  const valide = await trouverTexte(d.page, /Dossier validé/, 1500);
  noter('1.16', !valide && aide ? 'vert' : 'rouge', valide ? 'dossier valide sans les trois verifications' : `« ${aide ?? 'aucune phrase'} »`);
});
await piege('1.17', async () => {
  if (!dossier) return noter('1.17', 'non joué', 'dossier absent');
  const caseLisible = d.page.getByRole('checkbox', { name: /La pièce est lisible/ }).first();
  const active = await caseLisible.isEnabled().catch(() => false);
  await p.capture(d, 'p1-17_cases_avant_piece');
  noter('1.17', active ? 'rouge' : 'vert', active ? 'les cases se cochent sans avoir ouvert la piece' : 'cases inactives tant que la piece n\'a pas ete ouverte');
});
await piege('1.18', async () => {
  if (!dossier) return noter('1.18', 'non joué', 'dossier absent');
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
noter('1.7', 'rouge', 'joué en exploration (31/10 20:56 UTC) : apres le lien, « Je m\'inscris pour moi » mene au parcours famille jusqu\'a « Votre demande est en cours », sans rappel du code d\'invitation ni retour vers l\'inscription enseignante (UX-011)');
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
