// INVITATION-COMPTE (garde-cap, 07/11/2026), banc LOCAL seulement.
// La pile doit avoir les inscriptions FERMEES comme la production :
//   E2E_INSCRIPTIONS_FERMEES=1 tool/e2e/pile.sh demarrer
// (« Signups not allowed for this instance »). Quatre chemins :
//   A. FOYER (par l'interface) : le titulaire invite une adresse, voit
//      « Invitation envoyee », la renvoie ; l'e-mail porte le code et le lien
//      ?mode=creer&foyer=1&code= ; l'ancien code ne sert plus ; une adresse non
//      invitee, un code faux ne creent rien ; le lien ouvert sans session
//      cree le compte de l'adresse invitee et le lien de connexion arrive ;
//      le code reutilise ne cree rien ; ouvert par le titulaire connecte :
//      « Cette invitation est pour une autre adresse… », rien de consomme.
//   B. ENSEIGNANT et C. COMPTABLE : invitation posee en SQL (local), lien
//      ?mode=creer&invitation=1&code= ; compte cree ; code faux refuse.
//   D. CANDIDAT : reponse de formulaire et courriel lien_inscription poses en
//      SQL (local) ; le code du courriel cree le compte ; reutilise, refuse.
//   E. DEBIT : cinq demandes par heure ; la sixieme, meme avec le bon code,
//      ne cree rien.
// Usage : node tool/e2e/invitation_compte.mjs [--bureau]   (parcours_3 d'abord)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, cliquer, libelles, attendreTexte, activerSemantique,
  amenerEnVue, connecterParLien, saisir, taper, sql, dernierLien, API, MAILPIT, DEPOT } from './commun.mjs';

const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const T = (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const souple = (s) => echapper(s).replace(/[\s  ]+/g, '\\s*');
const exact = (s) => new RegExp(`^\\s*${souple(s)}\\s*$`);
const bureau = process.argv.includes('--bureau');
const ts = Date.now().toString(36);

const p = await parcours(`INVITATION-COMPTE : creation du compte sur invitation, inscriptions fermees (${bureau ? '1440' : '390'})`,
  `invitation-compte/robot-${bureau ? '1440' : '390'}`);
const rouges = [];
function noter(ok, quoi, detail = '') {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}${detail ? ` (${detail})` : ''}`);
  if (!ok) rouges.push(quoi);
}
const compteExiste = (courriel) => sql(`select count(*) from auth.users where lower(email) = lower('${courriel}')`) === '1';
// Le debit compte par adresse et par IP ; tout le robot vient de la meme IP.
const remettreDebit = () => sql('delete from app_private.demandes_invitation_compte');
async function edge(type, code, email) {
  const r = await fetch(`${API}/functions/v1/invitation-compte`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ type, code, email }),
  });
  return { statut: r.status, corps: await r.text() };
}
const CODE = /\b([A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4})\b/;
async function codeDuCourriel(courriel, depuis, sujet) {
  const fin = Date.now() + 90000;
  while (Date.now() < fin) {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${courriel}`)}`)).json();
    const m0 = (r.messages ?? []).find((m) => Date.parse(m.Created) >= depuis - 2000 && sujet.test(m.Subject));
    if (m0) {
      const m = await (await fetch(`${MAILPIT}/api/v1/message/${m0.ID}`)).json();
      const corps = `${m.HTML ?? ''} ${m.Text ?? ''}`.replace(/&amp;/g, '&');
      const lien = [...corps.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0]).find((u) => u.includes('mode=creer'));
      return { code: corps.match(CODE)?.[1] ?? null, lien, sujet: m.Subject };
    }
    await new Promise((res) => setTimeout(res, 2000));
  }
  return null;
}
// La creation par l'interface, sans session : le lien de l'e-mail, l'adresse,
// « Recevoir le lien d'inscription ».
async function creerParLeLien(ctx, chemin, courriel, nom, attendu = null) {
  const page = ctx.page;
  await ouvrir(page, chemin); await page.waitForTimeout(2500); await activerSemantique(page);
  const depuis = Date.now();
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(page, new RegExp(`^${souple(T('connexion.envoyerLienCreation'))}`), { pause: 3000 });
  await activerSemantique(page);
  const texte = (await libelles(page)).join(' | ');
  noter(!texte.includes(T('connexion.inscriptionFermee').slice(0, 40)), `${nom} : aucune phrase « inscriptions fermees »`);
  noter(compteExiste(courriel), `${nom} : le compte de l'adresse invitee est cree (auth.users)`, courriel);
  const recu = await dernierLien(courriel, depuis, 60000);
  noter(!!recu?.lien, `${nom} : le lien de connexion arrive (Mailpit)`, recu?.sujet ?? 'rien');
  await p.capture(ctx, `${nom}_lien_envoye`);
  if (recu?.lien) {
    await page.goto(recu.lien); await page.waitForTimeout(6000); await activerSemantique(page);
    const apres = decodeURIComponent(new URL(page.url()).hash.replace(/^#/, ''));
    noter(!apres.startsWith('/connexion'), `${nom} : le lien ouvre une session`, apres);
    if (attendu) noter(attendu.test(apres), `${nom} : la session arrive au bon ecran`, apres);
    await p.capture(ctx, `${nom}_session_ouverte`);
  }
}

let code = 1;
try {
  remettreDebit();
  const admin = sql(`select id from public.profiles where role = 'admin' and deleted_at is null order by created_at limit 1`);

  // ---------------------------------------------------------------- A. FOYER
  const ligne = sql(`select u.email || '|' || t.household_id from auth.users u
    join public.profiles t on t.id = u.id
    join public.households h on h.id = t.household_id and h.primary_guardian_id = t.id
    where u.email like 'e2e-famille-%' order by u.created_at desc limit 1`);
  if (!ligne) throw new Error('aucune famille titulaire : lancer parcours_3 d\'abord');
  const [titulaire, foyer] = ligne.split('|');
  sql(`update public.invitations_foyer set statut = 'annulee', updated_at = now() where foyer_id = '${foyer}' and statut = 'en_attente'`);
  const invite = `e2e-invite-${ts}@example.com`;
  p.dire(`A. Titulaire ${titulaire} ; adresse invitee ${invite}`);

  const f = await p.contexte('titulaire', bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
  await connecterParLien(f.page, titulaire);
  await ouvrir(f.page, '/#/tuteur/foyer'); await f.page.waitForTimeout(3000); await activerSemantique(f.page);
  const inviter = await trouver(f.page, new RegExp(`^(${souple(T('adulte.invitation.titreElle'))}|${souple(T('adulte.invitation.titreLui'))}|${souple(T('adulte.invitation.titreNeutre'))})`), { delai: 8000 });
  noter(inviter !== null, 'A : la ligne « Inviter … » du Foyer');
  if (inviter) { await amenerEnVue(f.page, inviter); await inviter.click(); await f.page.waitForTimeout(2500); }
  await saisir(f.page, T('adulte.invitation.prenom'), 'Amina');
  await saisir(f.page, T('adulte.invitation.courriel'), invite);
  await cliquer(f.page, exact(T('adulte.invitation.verifier')), { pause: 2000 });
  const depuisEnvoi = Date.now();
  await cliquer(f.page, exact(T('adulte.invitation.envoyer')), { pause: 3000 });
  await p.capture(f, 'a_invitation_partie');
  // Retour au Foyer par l'onglet, comme une personne qui ne touche pas
  // « Revenir a Ma famille » : la ligne doit etre a jour quand meme.
  await cliquer(f.page, new RegExp(`^${souple(T('nav.tuteur.foyer'))}( Onglet.*)?$`), { pause: 3000 });
  await activerSemantique(f.page);
  const envoyee = await trouver(f.page, new RegExp(`^${souple(T('adulte.famille.place.invitationEnvoyee'))}`), { delai: 8000 });
  const texteFoyer = (await libelles(f.page)).join(' | ');
  noter(envoyee !== null && texteFoyer.includes(invite), 'A : le Foyer montre « Invitation envoyee » et l\'adresse');
  await p.capture(f, 'a_foyer_invitation_envoyee');
  const premier = await codeDuCourriel(invite, depuisEnvoi, /invite/i);
  noter(!!premier?.code && /mode=creer&foyer=1&code=/.test(premier?.lien ?? ''), 'A : l\'e-mail porte le code et le lien de creation', premier?.lien ?? 'rien');

  if (envoyee) { await amenerEnVue(f.page, envoyee); await envoyee.click(); await f.page.waitForTimeout(2500); await activerSemantique(f.page); }
  const depuisRenvoi = Date.now();
  await cliquer(f.page, exact(T('adulte.invitation.renvoyer')), { pause: 3000 });
  await activerSemantique(f.page);
  noter((await libelles(f.page)).join(' | ').includes('avec un nouveau code'), 'A : « Renvoyer l\'invitation » : la phrase du renvoi');
  await p.capture(f, 'a_renvoyee');
  const second = await codeDuCourriel(invite, depuisRenvoi, /invite/i);
  noter(!!second?.code && second.code !== premier?.code, 'A : le renvoi porte un nouveau code', `${premier?.code} -> ${second?.code}`);
  noter(sql(`select count(*) from public.invitations_foyer where foyer_id = '${foyer}' and statut = 'en_attente'`) === '1',
    'A : la meme invitation (une seule en attente)');

  // Refus, par la fonction Edge (reponse uniforme, rien de cree).
  await edge('foyer', premier?.code ?? 'x', invite);
  noter(!compteExiste(invite), 'A : l\'ancien code (avant renvoi) ne cree rien');
  const intrus = `e2e-intrus-${ts}@example.com`;
  const rIntrus = await edge('foyer', second?.code ?? 'x', intrus);
  noter(!compteExiste(intrus) && rIntrus.corps === '{"ok":true}', 'A : une adresse non invitee ne cree rien (reponse uniforme)', rIntrus.corps);
  const rFaux = await edge('foyer', 'AAAA-BBBB-CCCC', invite);
  noter(!compteExiste(invite) && rFaux.corps === '{"ok":true}', 'A : un code faux ne cree rien (reponse uniforme)', rFaux.corps);
  remettreDebit();

  // Le titulaire connecte ouvre le lien : autre adresse, rien de consomme.
  if (second?.code) {
    await ouvrir(f.page, `/#/connexion?mode=creer&foyer=1&code=${second.code}`);
    await f.page.waitForTimeout(3500); await activerSemantique(f.page);
    noter(await attendreTexte(f.page, new RegExp(souple(T('connexion.invitationFoyer.autreAdresse'))), 6000),
      'A : connecte a un autre compte : « Cette invitation est pour une autre adresse… »');
    await p.capture(f, 'a_autre_adresse');
    noter(sql(`select count(*) from app_private.codes_invitation_foyer c join public.invitations_foyer i on i.id = c.invitation_id
      where i.email_invite = '${invite}' and c.utilise_le is not null`) === '0', 'A : rien n\'est consomme par cette ouverture');
  }

  // Le lien, sans session : le compte de l'adresse invitee.
  const g = await p.contexte('invite', bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
  if (second?.code) await creerParLeLien(g, `/#/connexion?mode=creer&foyer=1&code=${second.code}`, invite, 'a_foyer');
  const intrus2 = `e2e-intrus2-${ts}@example.com`;
  await edge('foyer', second?.code ?? 'x', intrus2);
  noter(!compteExiste(intrus2), 'A : le code reutilise (autre adresse) ne cree rien');
  remettreDebit();

  // ----------------------------------------------- B. ENSEIGNANT, C. COMPTABLE
  for (const [lettre, table, nom] of [['B', 'invitations_enseignant', 'enseignant'], ['C', 'invitations_comptable', 'comptable']]) {
    const adresse = `e2e-${nom}-${ts}@example.com`;
    const c = sql(`with c as (select app_private.code_invitation_neuf() as code)
      insert into public.${table} (code, email, cree_par, expire_le)
      select code, '${adresse}', '${admin}', now() + interval '14 days' from c returning code`).split('\n')[0];
    p.dire(`${lettre}. ${nom} ${adresse} code ${c}`);
    await edge('equipe', 'AAAA-BBBB-CCCC', adresse);
    noter(!compteExiste(adresse), `${lettre} : un code faux ne cree rien`);
    await edge('equipe', c, `e2e-autre-${nom}-${ts}@example.com`);
    noter(!compteExiste(`e2e-autre-${nom}-${ts}@example.com`), `${lettre} : une adresse non invitee ne cree rien`);
    remettreDebit();
    const h = await p.contexte(nom, bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
    await creerParLeLien(h, `/#/connexion?mode=creer&invitation=1&code=${c}`, adresse, `${lettre.toLowerCase()}_${nom}`);
    remettreDebit();
  }

  // ------------------------------------------------------------ D. CANDIDAT
  const candidat = `e2e-candidat-${ts}@example.com`;
  const lot = sql(`select id from public.formulaires_lots order by cree_le limit 1`).split('\n')[0]
    || sql(`insert into public.formulaires_lots (cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
             values ('e2e-lot-${ts}', '${admin}', 'Candidatures (réponses)', 'Réponses', md5('${ts}'), '{}', '{}') returning id`).split('\n')[0];
  sql(`insert into public.formulaires_reponses (reference_source, lot_id, recue_le, genre, nom_affiche, courriel, reponses, contenu_empreinte)
       values ('e2e|${ts}', '${lot}', now(), 'male', 'Candidat E2E', '${candidat}', '{}', md5('r${ts}'))`);
  const courrielId = sql(`select public.courriel_enfiler('recrutement', 'lien_inscription', '${candidat}', null, '{}'::jsonb,
       'lien_inscription:${candidat}', 'manuel', null)`);
  const codeCandidat = sql(`select donnees->>'code' from public.courriels_sortants where id = '${courrielId}'`);
  p.dire(`D. candidat ${candidat} code ${codeCandidat}`);
  noter(CODE.test(codeCandidat), 'D : le courriel lien_inscription porte un code');
  await edge('candidat', 'AAAA-BBBB-CCCC', candidat);
  noter(!compteExiste(candidat), 'D : un code faux ne cree rien');
  remettreDebit();
  const k = await p.contexte('candidat', bureau ? { vue: { width: 1440, height: 900 } } : { telephone: true });
  // Le candidat arrive sur son ecran (candidature=1), jamais sur l'ecran du
  // code d'un enseignant avec son code a lui.
  await creerParLeLien(k, `/#/connexion?mode=creer&candidature=1&code=${codeCandidat}`, candidat, 'd_candidat',
    /candidature=1/);
  await edge('candidat', codeCandidat, `e2e-candidat2-${ts}@example.com`);
  noter(!compteExiste(`e2e-candidat2-${ts}@example.com`), 'D : le code reutilise ne cree rien');
  remettreDebit();

  // --------------------------------------------------------------- E. DEBIT
  const debit = `e2e-debit-${ts}@example.com`;
  const cd = sql(`with c as (select app_private.code_invitation_neuf() as code)
    insert into public.invitations_enseignant (code, email, cree_par, expire_le)
    select code, '${debit}', '${admin}', now() + interval '14 days' from c returning code`).split('\n')[0];
  for (let i = 0; i < 5; i++) await edge('equipe', 'AAAA-BBBB-CCCC', debit);
  const sixieme = await edge('equipe', cd, debit);
  noter(!compteExiste(debit) && sixieme.corps === '{"ok":true}', 'E : la sixieme demande de l\'heure, meme avec le bon code, ne cree rien (reponse uniforme)');
  noter(sql(`select count(*) from app_private.demandes_invitation_compte where not acceptee`) !== '0', 'E : le refus est journalise');
  remettreDebit();

  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
