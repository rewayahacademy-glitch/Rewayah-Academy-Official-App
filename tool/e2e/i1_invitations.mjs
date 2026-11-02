// I1 « Inviter quelqu'un » (02/11/2026), banc LOCAL seulement (G5, B7).
//
// Preuves demandees par le pilote :
// - la ligne `courriels_sortants` creee pour un enseignant et pour un foyer
//   importe (un foyer par « Envoyer l'invitation », un autre par « Envoyer a
//   toutes les familles », apres confirmation) ;
// - le parcours d'invitation d'un enseignant, depuis le lien de l'e-mail recu
//   dans Mailpit, avec un rechargement au milieu, jusqu'au compte cree ;
// - UX-015 (« Invitations » dans les sections de Personnes), UX-013 et UX-017
//   (le code survit au lien et au rechargement), UX-018 (lien deja servi).
// Captures a 1440 (direction) et 390 (candidate, et la liste des familles).
// Les deux foyers importes sont amorces en SQL local (adresses example.com) :
// l'import par l'interface est prouve par ses propres parcours.
import { parcours, ouvrir, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  dernierLien, activerSemantique, sql, COMPTES, APP, MAILPIT } from './commun.mjs';

const tampon = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const CAND = { courriel: `e2e-i1-candidat-${tampon}@example.com`, prenom: 'E2E Candidat', nom: `Invite${tampon}` };
const FAM = [`e2e-i1-famille-a-${tampon}@example.com`, `e2e-i1-famille-b-${tampon}@example.com`];
const VUE = { width: 1440, height: 900 };
const p = await parcours('I1 : inviter quelqu\'un (enseignant, familles importees)', 'i1-invitations');
const verifs = [];
function verifier(ok, quoi) {
  verifs.push({ ok, quoi });
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}`);
  if (!ok) throw new Error(quoi);
}

/// Le dernier e-mail de l'application (pas un lien de connexion) pour `a`.
async function courrielApp(a, sujet, delai = 150000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${a}`)}`)).json();
    const m0 = (r.messages ?? []).find((m) => sujet.test(m.Subject ?? ''));
    if (m0) {
      const m = await (await fetch(`${MAILPIT}/api/v1/message/${m0.ID}`)).json();
      const corps = `${m.HTML ?? ''} ${m.Text ?? ''}`;
      return { sujet: m.Subject, texte: m.Text ?? '', liens: [...corps.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&')) };
    }
    await new Promise((res) => setTimeout(res, 3000));
  }
  return null;
}

let code = 1;
try {
  // 0. Deux foyers importes et confirmes (base locale).
  for (const [i, adresse] of FAM.entries()) {
    sql(`with h as (insert into private.preinscription_households (email_normalise, status)
           values ('${adresse}', 'confirmed') returning id)
         insert into private.preinscription_persons (household_id, person_kind, first_name, source_row)
         select h.id, k, n, r from h, (values ('guardian', 'E2E Parent', ${10 + i * 2}), ('student', 'E2E Eleve', ${11 + i * 2})) v(k, n, r)`);
  }
  p.dire(`Foyers importes amorces : ${FAM.join(', ')}`);

  // 1. Direction, 1440 : Personnes, « Sections de la page », « Invitations » (UX-015).
  const d = await p.contexte('direction', { vue: VUE });
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Personnes Onglet');
  await cliquer(d.page, /^Sections de la page/, { pause: 1200 });
  await p.capture(d, '1440_sections_personnes');
  const entree = await trouver(d.page, /^Invitations/, { delai: 8000 });
  verifier(Boolean(entree), 'UX-015 : « Invitations » est dans les sections de Personnes');
  await entree.click();
  await d.page.waitForTimeout(2500);
  verifier(d.page.url().includes('/admin/personnes/invitations'), `UX-015 : la section ouvre la page des invitations (${d.page.url()})`);

  // 2. Inviter un enseignant : l'e-mail part avec le code.
  await cliquer(d.page, /^Un enseignant\./);
  const aide = await trouverTexte(d.page, /part aussitôt par e-mail[^|]*/, 5000);
  const ancienne = await trouverTexte(d.page, /pas envoyé automatiquement/, 1500);
  verifier(Boolean(aide) && !ancienne, `aide du champ : « ${aide ?? '-'} » ; ancien texte absent`);
  await taper(d.page, 'textarea, input[aria-label^="Adresse de courriel"]', CAND.courriel);
  await cliquer(d.page, /^Créer l'invitation$/, { pause: 2500 });
  const message = await trouverTexte(d.page, /Invitation créée[^|]*/, 10000);
  await p.capture(d, '1440_invitation_enseignant_creee');
  const invitation = message?.match(/code ([A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4})/)?.[1];
  verifier(Boolean(invitation) && message.includes(CAND.courriel), `message : « ${message ?? '-'} »`);
  const ligneEns = sql(`select id || ' | ' || categorie || ' | ' || modele || ' | ' || statut || ' | ' || origine || ' | code=' || (donnees->>'code')
                          from public.courriels_sortants where modele = 'invitation_enseignant' and destinataire_adresse = '${CAND.courriel}'`);
  p.dire(`courriels_sortants (enseignant) : ${ligneEns}`);
  verifier(ligneEns.split('\n').length === 1 && ligneEns.includes(`code=${invitation}`) && ligneEns.includes('recrutement'),
    'une seule ligne courriels_sortants pour l\'enseignant, avec son code, categorie recrutement');

  // 3. Familles importees : une par son bouton, l'autre par « toutes ».
  await cliquer(d.page, /^Une famille déjà inscrite/, { pause: 2500 });
  // La liste est sous les cartes : la page defile jusqu'a elle.
  await d.page.mouse.move(800, 600);
  await d.page.mouse.wheel(0, 900);
  await d.page.waitForTimeout(1500);
  await p.capture(d, '1440_familles_a_inviter');
  const idA = sql(`select id from private.preinscription_households where email_normalise = '${FAM[0]}'`);
  const boutonA = await trouver(d.page, new RegExp(`Envoyer l'invitation à ${FAM[0].replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`), { delai: 8000 });
  if (!boutonA) p.dire(`  libelles : ${(await libelles(d.page)).filter((x) => /Envoyer|famille-a/.test(x)).join(' | ')}`);
  verifier(Boolean(boutonA), `bouton « Envoyer l'invitation » de ${FAM[0]}`);
  await boutonA.click();
  await d.page.waitForTimeout(2500);
  const envoye = await trouverTexte(d.page, /L'invitation part vers[^|]*/, 8000);
  await p.capture(d, '1440_famille_envoyee');
  verifier(Boolean(envoye), `message : « ${envoye ?? '-'} »`);
  const ligneA = sql(`select id || ' | ' || categorie || ' | ' || modele || ' | ' || statut || ' | ' || cle_idempotence
                        from public.courriels_sortants where modele = 'invitation_famille_importee' and destinataire_adresse = '${FAM[0]}'`);
  p.dire(`courriels_sortants (foyer importe A) : ${ligneA}`);
  verifier(ligneA.split('\n').length === 1 && ligneA.includes(idA) && ligneA.includes('inscription'),
    'une seule ligne courriels_sortants pour le foyer A, categorie inscription');
  verifier(sql(`select count(*) from public.courriels_sortants where destinataire_adresse = '${FAM[1]}'`) === '0',
    'rien n\'est parti tout seul vers le foyer B');

  const toutes = await trouver(d.page, /^Envoyer à toutes les familles \(\d+\)/, { delai: 8000 });
  verifier(Boolean(toutes), '« Envoyer à toutes les familles » propose, avec le nombre');
  const nombre = Number((await toutes.getAttribute('aria-label') ?? (await toutes.textContent()) ?? '').match(/\((\d+)\)/)?.[1]);
  await toutes.click();
  await d.page.waitForTimeout(1500);
  const question = await trouverTexte(d.page, /Envoyer l'invitation à toutes les familles[^|]*/, 5000);
  await p.capture(d, '1440_confirmation_toutes');
  verifier(Boolean(question) && question.includes(String(nombre)), `confirmation : « ${question ?? '-'} »`);
  await cliquer(d.page, new RegExp(`^Oui, envoyer à toutes les familles \\(${nombre}\\)`), { pause: 3000 });
  const parties = await trouverTexte(d.page, /Les invitations partent[^|]*/, 8000);
  await p.capture(d, '1440_toutes_envoyees');
  const ligneB = sql(`select id || ' | ' || categorie || ' | ' || modele || ' | ' || statut || ' | ' || cle_idempotence
                        from public.courriels_sortants where modele = 'invitation_famille_importee' and destinataire_adresse = '${FAM[1]}'`);
  p.dire(`courriels_sortants (foyer importe B) : ${ligneB}`);
  verifier(Boolean(parties) && ligneB.split('\n').length === 1, `envoi a toutes : « ${parties ?? '-'} » et une ligne pour le foyer B`);

  // La liste des familles a 390.
  const d390 = await p.contexte('direction', { telephone: true });
  await connecter(d390.page, COMPTES.direction);
  await ouvrir(d390.page, '/#/admin/personnes/invitations');
  await d390.page.waitForTimeout(2500);
  await activerSemantique(d390.page);
  await cliquer(d390.page, /^Une famille déjà inscrite/, { pause: 2500 });
  await d390.page.mouse.move(200, 500);
  await d390.page.mouse.wheel(0, 1400);
  await d390.page.waitForTimeout(1500);
  const ligneFamille = await trouver(d390.page, /^Envoyée|^En cours d'envoi/, { delai: 5000 });
  if (ligneFamille) await ligneFamille.scrollIntoViewIfNeeded().catch(() => {});
  await p.capture(d390, '390_familles_apres_envoi');

  // 4. L'e-mail de l'enseignant arrive (courriels-envoi -> Mailpit), avec le lien.
  const mail = await courrielApp(CAND.courriel, /invitation à enseigner/i);
  verifier(Boolean(mail), `e-mail recu dans Mailpit : « ${mail?.sujet ?? 'aucun'} »`);
  const lienMail = mail.liens.find((u) => u.includes('invitation=1'));
  verifier(Boolean(lienMail) && lienMail.includes(`code=${invitation}`) && mail.texte.includes(invitation),
    `le lien de l'e-mail porte invitation=1 et le code : ${lienMail}`);
  const statutEns = sql(`select statut from public.courriels_sortants where modele = 'invitation_enseignant' and destinataire_adresse = '${CAND.courriel}'`);
  p.dire(`courriels_sortants (enseignant) apres l'envoi : ${statutEns}`);

  // 5. La candidate, 390 : le lien de l'e-mail (meme chemin, sur le banc local).
  const c = await p.contexte('candidat', { telephone: true });
  const u = new URL(lienMail);
  await ouvrir(c.page, `${u.pathname}${u.search}`);
  await c.page.waitForTimeout(2000);
  await p.capture(c, '390_lien_de_l_email');
  const depuis = Date.now();
  await taper(c.page, 'input[inputmode=email], input[autocomplete=email]', CAND.courriel);
  await cliquer(c.page, /^Recevoir le lien/, { pause: 2000 });
  const recu = await dernierLien(CAND.courriel, depuis);
  verifier(Boolean(recu?.lien), 'lien de connexion recu dans Mailpit');
  // Comme depuis une messagerie : le lien s'ouvre dans un NOUVEL onglet.
  c.page = await c.ctx.newPage();
  await c.page.goto(recu.lien);
  await c.page.waitForTimeout(7000);
  await activerSemantique(c.page);
  const pourQui = await trouverTexte(c.page, /Pour qui créez-vous ce compte/, 2500);
  const creerProfil = await trouver(c.page, /^Créer mon profil$/, { delai: 15000 });
  await p.capture(c, '390_retour_du_lien_code_valide');
  verifier(!pourQui && Boolean(creerProfil) && c.page.url().includes('/inscription/invitation'),
    `UX-013 : au retour du lien, le code est la et valide (${c.page.url()}), sans « Pour qui »`);

  // 6. Identite, puis rechargement au milieu (UX-017).
  await creerProfil.click();
  await c.page.waitForTimeout(2000);
  await taper(c.page, 'input[aria-label="Prénom"]', CAND.prenom);
  await p.capture(c, '390_identite_avant_rechargement');
  await c.page.reload();
  await c.page.waitForTimeout(7000);
  await activerSemantique(c.page);
  const pourQui2 = await trouverTexte(c.page, /Pour qui créez-vous ce compte/, 2500);
  const creerProfil2 = await trouver(c.page, /^Créer mon profil$/, { delai: 15000 });
  await p.capture(c, '390_apres_rechargement_code_garde');
  verifier(!pourQui2 && Boolean(creerProfil2), `UX-017 : apres le rechargement, le code est garde et valide (${c.page.url()})`);
  await creerProfil2.click();
  await c.page.waitForTimeout(2000);
  await taper(c.page, 'input[aria-label="Prénom"]', CAND.prenom);
  await taper(c.page, 'input[aria-label="Nom"]', CAND.nom);
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await cliquer(c.page, /^Un homme\./, { role: 'radio' });
  await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  await p.capture(c, '390_recapitulatif');
  await cliquer(c.page, /^Créer mon compte$/, { pause: 5000 });
  await activerSemantique(c.page);
  await p.capture(c, '390_compte_cree');
  const profil = sql(`select p.role || ' | ' || p.account_status from public.profiles p join auth.users u on u.id = p.id where u.email = '${CAND.courriel}'`);
  const consommee = sql(`select (utilisee_le is not null)::text from public.invitations_enseignant where code = '${invitation}'`);
  p.dire(`Profil : ${profil} ; invitation consommee : ${consommee} ; ecran : ${c.page.url()}`);
  verifier(profil.startsWith('teacher') && consommee === 'true', 'compte enseignant cree, invitation consommee');
  const marque = await c.page.evaluate(() => localStorage.getItem('rewayah.inscription.invitation_en_cours'));
  verifier(marque === null, 'la marque de l\'invitation en cours est effacee apres la creation du profil');

  // 7. UX-018 : le lien de connexion deja servi, ouvert de nouveau (1440).
  const autre = await p.contexte('lien-deux-fois', { vue: VUE });
  await autre.page.goto(recu.lien);
  await autre.page.waitForTimeout(7000);
  await activerSemantique(autre.page);
  // Deux chemins : l'adresse d'erreur que le routeur ne connait pas (page
  // « Ce lien a deja servi ou a expire », I1) ou la recuperation d'acces
  // (« Ce lien n'est plus valable ») ; jamais « page introuvable ».
  const explique = await trouverTexte(autre.page, /Ce lien a déjà servi ou a expiré|Ce lien n'est plus valable/, 10000);
  const action = await trouver(autre.page, /^Recevoir un nouveau lien/, { delai: 5000 });
  await p.capture(autre, '1440_lien_deja_servi');
  p.dire(`Lien deja servi : ${autre.page.url()} ; ${(await libelles(autre.page)).slice(0, 6).join(' | ')}`);
  verifier(Boolean(explique) && Boolean(action), `UX-018 : le lien deja servi est explique (« ${explique ?? '-'} »), avec « Recevoir un nouveau lien »`);

  code = await p.fin('vert', `${verifs.length} verifications vertes`);
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
