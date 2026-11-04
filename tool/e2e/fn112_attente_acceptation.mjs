// Parcours 3 : une famille et un eleve adulte s'inscrivent (questionnaire, lien
// recu par e-mail dans Mailpit, nom et genre, « Envoyer ma demande »), puis la
// direction accepte les deux demandes ; la famille rouvre son Accueil (c'est la
// que le profil de l'enfant est cree).
// Gestes et libelles : docs/current/PARCOURS-OUVERTURE-2026-11-01.md, parcours 3.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecter, cliquer, trouver, trouverTexte, libelles, taper,
  activerSemantique, sql, COMPTES, MAILPIT, TRAVAIL } from './commun.mjs';

const tampon = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const FAMILLE = { courriel: `e2e-famille-${tampon}@example.com`, enfant: `Yanis${tampon}`,
  prenom: 'E2E Parent', nom: `Famille${tampon}` };
const ADULTE = { courriel: `e2e-adulte-${tampon}@example.com`, prenom: 'E2E Adulte', nom: `Apprenant${tampon}` };

const p = await parcours('FN-112 : l\'eleve adulte, en attente puis accepte, arrive sur son accueil', 'fn112-attente-acceptation');

/// Repond au questionnaire « Créer un compte » jusqu'a l'ecran du courriel.
async function questionnaire(a, reponses) {
  for (let k = 0; k < 14; k++) {
    if (a.page.url().includes('/connexion')) return;
    const l = await libelles(a.page);
    const question = l.filter((x) => x.startsWith('flt-semantics:')).slice(0, 2).join(' / ');
    const regle = reponses.find((r) => r.q.test(question));
    if (!regle) throw new Error(`questionnaire : question imprevue « ${question} »`);
    if (regle.saisie) await taper(a.page, 'input', regle.saisie);
    if (regle.choix) await cliquer(a.page, regle.choix, { pause: 500 });
    if (k < 3 || regle.capture) await p.capture(a, `questionnaire_${k}`);
    await cliquer(a.page, /^Continuer$/, { pause: 1300 });
  }
  throw new Error('questionnaire : trop d\'etapes');
}

/// Dernier lien de Mailpit adresse a `courriel`.
async function lienRecu(courriel, delai = 60000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${courriel}`)}`)).json();
    if (r.messages?.length) {
      const m = await (await fetch(`${MAILPIT}/api/v1/message/${r.messages[0].ID}`)).json();
      const corps = `${m.HTML ?? ''} ${m.Text ?? ''}`;
      const liens = [...corps.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&'));
      const lien = liens.find((u) => u.includes('/auth/v1/verify')) ?? liens.find((u) => /token|code=/.test(u));
      return { sujet: m.Subject, lien, liens };
    }
    await new Promise((res) => setTimeout(res, 1500));
  }
  return null;
}

/// Demande le lien, l'ouvre, remplit nom et genre, envoie la demande.
async function inscrire(a, qui, genre) {
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', qui.courriel);
  await p.capture(a, 'courriel');
  await cliquer(a.page, /^Recevoir le lien d'inscription$/, { pause: 2500 });
  await p.capture(a, 'lien_demande');
  const recu = await lienRecu(qui.courriel);
  if (!recu?.lien) throw new Error(`aucun lien de confirmation recu dans Mailpit pour ${qui.courriel}${recu ? ` (sujet « ${recu.sujet} », liens : ${recu.liens.join(' ')})` : ''}`);
  p.dire(`E-mail recu : « ${recu.sujet} » ; lien ${recu.lien.slice(0, 90)}...`);
  // Le lien passe par l'API (http://127.0.0.1:54321) et revient sur l'application.
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  p.dire(`Apres le lien : ${a.page.url()}`);
  await p.capture(a, 'apres_lien');
  // Nom et genre (formulaire en etapes), puis « Envoyer ma demande ».
  for (let k = 0; k < 8; k++) {
    const l = await libelles(a.page);
    p.dire(`  identite ${k} : ${l.filter((x) => /^(flt-semantics|input|radio|button|checkbox)/.test(x)).join(' | ').slice(0, 400)}`);
    for (const c of await a.page.locator('input').all()) {
      const nom = `${await c.getAttribute('aria-label') ?? ''}`;
      let v = null;
      if (/prénom/i.test(nom)) v = qui.prenom;
      else if (/nom/i.test(nom)) v = qui.nom;
      if (v === null) continue;
      await c.click({ force: true }); await a.page.keyboard.press('Control+A');
      await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
    }
    if (l.some((x) => x.startsWith('radio:'))) {
      const g = await trouver(a.page, genre, { delai: 2000, role: 'radio' });
      if (!g) throw new Error(`formulaire d'identite : aucun choix de genre attendu (${l.filter((x) => x.startsWith('radio:')).join(' | ')})`);
      await g.click(); await a.page.waitForTimeout(500);
    }
    await p.capture(a, `identite_${k}`);
    const envoyer = await trouver(a.page, /^Envoyer ma demande$/, { delai: 1500 });
    if (envoyer) { await envoyer.click(); await a.page.waitForTimeout(4000); break; }
    await cliquer(a.page, /^Continuer$/, { pause: 1500 });
  }
  await activerSemantique(a.page);
  await p.capture(a, 'demande_envoyee');
  // Ecart au carnet : l'application demande ensuite d'accepter les conditions
  // (« Lire et accepter nos conditions ») avant d'afficher l'etat de la demande.
  for (let k = 0; k < 8; k++) {
    if (await trouverTexte(a.page, /Votre demande est en cours/i, 1500)) break;
    const lire = await trouver(a.page, /^Lire et accepter nos conditions$/, { delai: 1500 });
    if (lire) { p.dire('  ECART : « Lire et accepter nos conditions » avant l\'etat de la demande'); await lire.click(); await a.page.waitForTimeout(1500); }
    const cases = a.page.getByRole('checkbox');
    for (let i = 0; i < await cases.count(); i++) {
      const c = cases.nth(i);
      if ((await c.getAttribute('aria-checked')) !== 'true') { await c.click(); await a.page.waitForTimeout(400); }
    }
    p.dire(`  accords ${k} : ${(await libelles(a.page)).filter((x) => /^(checkbox|button)/.test(x)).join(' | ').slice(0, 300)}`);
    await p.capture(a, `accords_${k}`);
    const suite = await trouver(a.page, /^(Suivant|Accepter.*|Valider.*|Terminer|Signer.*|J'accepte.*|Continuer)$/, { delai: 2000, role: 'button' });
    if (suite) { await suite.click(); await a.page.waitForTimeout(2500); await activerSemantique(a.page); }
  }
  await p.capture(a, 'etat_demande');
  const cours = await trouverTexte(a.page, /Votre demande est en cours/i, 15000);
  if (!cours) throw new Error(`apres « Envoyer ma demande » : pas de « Votre demande est en cours » ; ecran : ${(await libelles(a.page)).slice(0, 25).join(' | ')}`);
  p.dire(`${qui.courriel} : ${cours}`);
}

let code = 1;
try {
  // 1-3. Famille (telephone) : « J'inscris mon enfant ».
  const f = await p.contexte('famille', { telephone: true });
  await ouvrir(f.page, '/');
  await cliquer(f.page, /^Créer un compte$/);
  await cliquer(f.page, /^J'inscris mon enfant/);
  await p.capture(f, 'pour_qui');
  await cliquer(f.page, /^Continuer$/);
  await questionnaire(f, [
    { q: /Comment s'appelle votre enfant/, saisie: FAMILLE.enfant },
    { q: /Quel âge a/, choix: /^9 ans$/ },
    { q: / est…/, choix: /^Un garçon$/ },
    { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
    { q: /Suivez-vous aussi des cours/, choix: /^Non$/ },
    { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
    { q: /Quels moments/, choix: /^Le soir$/, capture: true },
  ]);
  await inscrire(f, FAMILLE, /^(Un homme|Homme|Masculin|Un père|Père)/);

  // Eleve adulte (second telephone) : « Je m'inscris pour moi ».
  const ad = await p.contexte('adulte', { telephone: true });
  await ouvrir(ad.page, '/');
  await cliquer(ad.page, /^Créer un compte$/);
  await cliquer(ad.page, /^Je m'inscris pour moi/);
  await cliquer(ad.page, /^Continuer$/);
  await questionnaire(ad, [
    { q: /Comment vous appelez-vous|Votre prénom/, saisie: ADULTE.prenom },
    { q: /Vous êtes…|Êtes-vous/, choix: /^Un homme$/ },
    { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Où en êtes-vous aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
    { q: /Quels moments/, choix: /^Le soir$/, capture: true },
  ]);
  await inscrire(ad, ADULTE, /^(Un homme|Homme|Masculin)/);

  // 4. Direction : Personnes, onglet « Demandes », « Accepter la demande … ».
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Personnes Onglet');
  await cliquer(d.page, /^Sections de la page/);
  await cliquer(d.page, /^Demandes/);
  await p.capture(d, 'demandes');
  for (const [liste, qui] of [['Familles', FAMILLE], ['Élèves adultes', ADULTE]]) {
    await cliquer(d.page, new RegExp(`^${liste}$`), { pause: 2000 });
    await p.capture(d, `liste_${liste.normalize('NFD').replace(/[^A-Za-z]/g, '')}`);
    const nomComplet = `${qui.prenom} ${qui.nom}`;
    await cliquer(d.page, new RegExp(`^Ouvrir la demande d.${nomComplet}`), { pause: 2500 });
    await p.capture(d, `demande_${liste.normalize('NFD').replace(/[^A-Za-z]/g, '')}`);
    const accepter = await trouver(d.page, /^Accepter la demande/, { delai: 8000, role: 'button' });
    if (!accepter) throw new Error(`direction, demande de ${nomComplet} : aucun bouton « Accepter la demande … » ; ecran : ${(await libelles(d.page)).slice(-30).join(' | ')}`);
    p.dire(`Direction : ${(await accepter.getAttribute('aria-label')) ?? (await accepter.textContent())}`);
    await accepter.click();
    await d.page.waitForTimeout(2000);
    const confirmer = await trouver(d.page, /^(Accepter|Confirmer|Oui)/, { delai: 2500, role: 'button' });
    if (confirmer) { p.dire(`  confirmation : ${(await confirmer.getAttribute('aria-label')) ?? ''}`); await confirmer.click(); await d.page.waitForTimeout(3000); }
    await p.capture(d, `acceptee_${liste.normalize('NFD').replace(/[^A-Za-z]/g, '')}`);
    p.dire(`  apres acceptation : ${(await libelles(d.page)).filter((x) => /accept|admis|demande/i.test(x)).slice(0, 6).join(' | ')}`);
    // Fermer la boite : Echap, sinon un toucher hors de la boite.
    await d.page.keyboard.press('Escape');
    await d.page.waitForTimeout(1000);
    if (await trouver(d.page, /^Demande d.E2E/, { delai: 800 })) {
      await d.page.mouse.click(1150, 700);
      await d.page.waitForTimeout(1500);
    }
    if (await trouver(d.page, /^Demande d.E2E/, { delai: 800 })) p.dire('  ECART : la boite de la demande ne se ferme ni par Echap ni par un toucher dehors');
  }
  const etats = sql(`select string_agg(u.email || '=' || p.account_status || '/' || p.role, ' ; ')
    from auth.users u join public.profiles p on p.id = u.id where u.email in ('${FAMILLE.courriel}', '${ADULTE.courriel}')`);
  p.dire(`Base locale apres acceptation : ${etats}`);

  // 5. La famille se reconnecte : son Accueil (le profil de l'enfant est cree ici).
  await ouvrir(f.page, '/');
  await f.page.waitForTimeout(4000);
  await activerSemantique(f.page);
  await p.capture(f, 'accueil_famille');
  const enfantVu = await trouverTexte(f.page, FAMILLE.enfant, 20000);
  p.dire(`Famille, Accueil : ${enfantVu ?? 'enfant non affiche'}`);
  // FN-112 : l'adulte est reste sur la page d'attente pendant l'acceptation
  // (aucun rechargement) ; il presse « Actualiser », comme en production le
  // 01/11/2026. Il doit arriver sur SON accueil, pas sur celui du tuteur.
  await activerSemantique(ad.page);
  await p.capture(ad, 'attente_avant_actualiser');
  const actualiser = await trouver(ad.page, /^Actualiser/, { delai: 10000, role: 'button' });
  if (!actualiser) throw new Error('page d\'attente : « Actualiser » introuvable');
  await actualiser.click();
  await ad.page.waitForTimeout(8000);
  await activerSemantique(ad.page);
  await p.capture(ad, 'accueil_adulte');
  const lu = (await libelles(ad.page)).join(' | ');
  p.dire(`Adulte apres « Actualiser » : ${ad.page.url()} ; ${lu.slice(0, 300)}`);
  if (!ad.page.url().includes('/eleve/adulte')) throw new Error(`FN-112 : l'adulte n'est pas sur son accueil (${ad.page.url()})`);
  if (/Aucun profil élève/.test(lu)) throw new Error('FN-112 : « Aucun profil élève » affiche a l\'adulte');
  const enfantBase = sql(`select count(*) from public.profiles c join public.profiles t on t.household_id = c.household_id
    join auth.users u on u.id = t.id where u.email = '${FAMILLE.courriel}' and c.role = 'student'`);
  p.dire(`Profils eleves du foyer de la famille en base : ${enfantBase}`);
  if (!/active/.test(etats) || (etats.match(/active/g) ?? []).length < 2) throw new Error(`apres « Accepter la demande » : comptes non actifs (${etats})`);
  if (!enfantVu || enfantBase === '0') throw new Error(`famille, Accueil apres acceptation : enfant ${enfantVu ? 'affiche' : 'non affiche'}, ${enfantBase} profil eleve en base`);
  // Les comptes du parcours 3 ne sont pas remplaces.
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
