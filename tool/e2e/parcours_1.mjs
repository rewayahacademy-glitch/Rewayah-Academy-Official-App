// Parcours 1 : la direction valide un enseignant.
// Preparation par l'interface (un NOUVEAU compte enseignant en attente) : la
// direction cree une invitation, la candidate s'inscrit avec le code (lien recu
// dans Mailpit), signe ses accords et depose une piece d'identite factice.
// Puis les gestes du carnet : Personnes, « Dossiers à valider », ouvrir le
// dossier, « Voir la pièce », trois cases, « Valider le dossier »,
// « Dossier validé. », et l'enseignante arrive sur « Aujourd'hui ».
// La piece d'un enseignant est relue par un membre du meme genre : la direction
// de test est une femme, la candidate aussi.
import { parcours, ouvrir, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  dernierLien, activerSemantique, sql, COMPTES, DEPOT } from './commun.mjs';
import path from 'node:path';

const tampon = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const CAND = { courriel: `e2e-candidate-${tampon}@example.com`, prenom: 'E2E Candidate', nom: `Enseignante${tampon}` };
const PIECE = path.join(DEPOT, 'tool/e2e/piece_factice.png');
const p = await parcours('Parcours 1 : la direction valide un enseignant', 'parcours-1');

async function ouvrirSection(page, section) {
  await cliquer(page, 'Personnes Onglet');
  await cliquer(page, /^Sections de la page/);
  await cliquer(page, new RegExp(`^${section}`), { pause: 2000 });
}

let code = 1;
try {
  // Preparation 1 : la direction cree l'invitation.
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await ouvrirSection(d.page, 'Candidatures');
  await cliquer(d.page, /^Invitations$/);
  await cliquer(d.page, /^Un enseignant\./);
  await taper(d.page, 'textarea, input[aria-label^="Adresse de courriel"]', CAND.courriel);
  await cliquer(d.page, /^Créer l'invitation$/, { pause: 2500 });
  await p.capture(d, 'invitation_creee');
  const message = await trouverTexte(d.page, /Transmettez ce code[^|]*/, 10000);
  const invitation = message?.match(/:\s*([A-Z0-9]{4}(?:-[A-Z0-9]{4})+)/)?.[1];
  if (!invitation) throw new Error(`preparation : pas de code d'invitation affiche (${message})`);
  p.dire(`Invitation : ${invitation} pour ${CAND.courriel}`);

  // Preparation 2 : la candidate s'inscrit avec le code.
  const c = await p.contexte('candidate');
  await ouvrir(c.page, '/');
  await cliquer(c.page, /^Créer un compte$/);
  await cliquer(c.page, /^J'ai un code d'invitation$/);
  const depuis = Date.now();
  await taper(c.page, 'input[inputmode=email], input[autocomplete=email]', CAND.courriel);
  await cliquer(c.page, /^Recevoir le lien/, { pause: 2000 });
  const recu = await dernierLien(CAND.courriel, depuis);
  if (!recu?.lien) throw new Error('preparation : aucun lien recu dans Mailpit');
  await c.page.goto(recu.lien);
  await c.page.waitForTimeout(6000);
  await activerSemantique(c.page);
  // Ecart : apres le lien, l'ecran « Pour qui » revient ; le code se ressaisit.
  const encore = await trouver(c.page, /^J'ai un code d'invitation$/, { delai: 4000 });
  if (encore) { p.dire('  ECART : apres le lien, « Pour qui créez-vous ce compte ? » revient ; « J\'ai un code d\'invitation » a toucher de nouveau'); await encore.click(); await c.page.waitForTimeout(1500); }
  await taper(c.page, 'textarea, input', invitation);
  await cliquer(c.page, /^Vérifier le code$/, { pause: 2500 });
  await p.capture(c, 'code_verifie');
  await cliquer(c.page, /^Créer mon profil$/, { pause: 2000 });
  await taper(c.page, 'input[aria-label="Prénom"]', CAND.prenom);
  await taper(c.page, 'input[aria-label="Nom"]', CAND.nom);
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await cliquer(c.page, /^Une femme\./, { role: 'radio' });
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await p.capture(c, 'recapitulatif');
  await cliquer(c.page, /^Créer mon compte$/, { pause: 3000 });
  await activerSemantique(c.page);
  await cliquer(c.page, /^Lire et accepter nos conditions$/, { pause: 2000 });
  await taper(c.page, 'textarea[aria-label^="Votre nom complet"], input[aria-label^="Votre nom complet"]', `${CAND.prenom} ${CAND.nom}`);
  const cases = c.page.getByRole('checkbox');
  for (let i = 0; i < await cases.count(); i++) {
    if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await c.page.waitForTimeout(300); }
  }
  await p.capture(c, 'accords');
  await cliquer(c.page, /^Suivant$/, { pause: 3000 });
  await activerSemantique(c.page);
  await cliquer(c.page, /^Carte d'identité\./, { role: 'radio' });
  c.page.once('filechooser', (fc) => fc.setFiles(PIECE));
  await cliquer(c.page, /^Choisir la photo$/, { pause: 3000 });
  await p.capture(c, 'piece_choisie');
  await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 4000 });
  await activerSemantique(c.page);
  await p.capture(c, 'dossier_en_verification');
  const attente = await trouverTexte(c.page, /Votre dossier est en cours de vérification/, 10000);
  if (!attente) throw new Error(`preparation : dossier non depose ; ecran : ${(await libelles(c.page)).slice(0, 12).join(' | ')}`);
  p.dire(`Candidate : ${attente}`);

  // 1. Direction : Personnes, « Dossiers à valider ».
  await ouvrir(d.page, '/');
  await d.page.waitForTimeout(2000);
  await ouvrirSection(d.page, 'Dossiers à valider');
  await p.capture(d, 'dossiers_a_valider');
  // 2. Ouvrir le dossier, « Voir la pièce ».
  const dossier = await trouver(d.page, new RegExp(CAND.nom), { delai: 15000 });
  if (!dossier) throw new Error(`direction, « Dossiers à valider » : le dossier de ${CAND.nom} n'apparait pas ; ecran : ${(await libelles(d.page)).slice(-12).join(' | ')}`);
  p.dire(`Dossier : ${(await dossier.getAttribute('aria-label')) ?? (await dossier.textContent())}`);
  await dossier.click();
  await d.page.waitForTimeout(2500);
  await p.capture(d, 'dossier_ouvert');
  const voir = await trouver(d.page, /Voir la pièce$/, { delai: 8000 });
  if (!voir) throw new Error(`direction, dossier : pas de « Voir la pièce » ; ecran : ${(await libelles(d.page)).slice(-20).join(' | ')}`);
  await voir.click();
  await d.page.waitForTimeout(4000);
  await p.capture(d, 'piece_affichee');
  const echecPiece = await trouverTexte(d.page, /(ne peut pas|n'a pas pu|indisponible|impossible|erreur)[^|]*/i, 1500);
  const imagePiece = await d.page.evaluate(() => [...document.querySelectorAll('img')]
    .filter((i) => i.naturalWidth > 100).map((i) => `${i.naturalWidth}x${i.naturalHeight}`));
  p.dire(`Piece : images ${imagePiece.join(', ') || 'aucune <img>'} ; ${echecPiece ?? 'pas de message d\'echec'}`);
  if (echecPiece) throw new Error(`direction, « Voir la pièce » : ${echecPiece}`);
  const fermer = await trouver(d.page, /^(Fermer|Retour au dossier)$/, { delai: 1500, role: 'button' });
  if (fermer) { await fermer.click(); await d.page.waitForTimeout(1200); }
  // 3. Les trois cases.
  for (const libelle of [/^La pièce est lisible/, /^Le nom correspond/, /^La pièce n'est pas expirée/]) {
    await cliquer(d.page, libelle, { role: 'checkbox', pause: 500 });
  }
  await p.capture(d, 'cases_cochees');
  // 4. « Valider le dossier » -> « Dossier validé. »
  await cliquer(d.page, /^Valider le dossier/, { role: 'button', pause: 2000 });
  const confirmer = await trouver(d.page, /^(Valider|Confirmer)/, { delai: 1500, role: 'button' });
  if (confirmer && !(await trouverTexte(d.page, /Dossier validé/, 500))) { await confirmer.click(); await d.page.waitForTimeout(2000); }
  await p.capture(d, 'dossier_valide');
  const valide = await trouverTexte(d.page, /Dossier validé/, 10000);
  const etat = sql(`select p.account_status from public.profiles p join auth.users u on u.id = p.id where u.email = '${CAND.courriel}'`);
  p.dire(`Direction : « ${valide ?? '-'} » ; compte en base : ${etat}`);
  if (!valide) throw new Error(`direction, « Valider le dossier » : pas de « Dossier validé. » (compte ${etat}) ; ecran : ${(await libelles(d.page)).slice(-12).join(' | ')}`);
  // 5. L'enseignante se reconnecte : « Aujourd'hui », plus la page d'attente.
  await ouvrir(c.page, '/');
  await c.page.waitForTimeout(4000);
  await activerSemantique(c.page);
  await p.capture(c, 'apres_validation');
  const aujourdhui = await trouverTexte(c.page, /^(h2:)?Aujourd'hui$|Aujourd'hui/, 15000);
  p.dire(`Enseignante : ${c.page.url()} ; « ${aujourdhui ?? '-'} »`);
  if (!c.page.url().includes('/enseignant') || !aujourdhui) throw new Error(`enseignante apres validation : ${c.page.url()} au lieu de « Aujourd'hui » ; ecran : ${(await libelles(c.page)).slice(0, 12).join(' | ')}`);
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
