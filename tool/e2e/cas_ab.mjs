// Cas reels de la semaine (prenoms fictifs, donnees locales), rejoues comme
// parcours nommes. Consigne du directeur du 31/10 au soir.
//
// Cas A, « l'adulte qui devient tuteur » : Amina veut s'inscrire pour elle-meme ;
// pressee, elle touche « J'inscris mon enfant » et donne son propre prenom comme
// prenom de l'enfant. Peut-elle revenir ? Comprend-elle ce qu'elle a cree ?
// Une fois acceptee, « Créer mon profil élève » l'avertit-il qu'un profil eleve a
// deja son nom ?
//
// Cas B, « la mere qui s'inscrit sous le nom de l'enfant » : a l'etape
// « Comment vous appelez-vous ? », la mere tape le nom de l'enfant ; une fois
// acceptee, elle ajoute deux profils eleves pour le meme enfant (nom complet,
// puis nom court). Le doublon est-il detecte ou signale ? Peut-elle le corriger ?
//
// Verdict : rouge si l'application laisse faire sans avertir.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  allerOnglet, activerSemantique, taper, sql, COMPTES } from './commun.mjs';
import { questionnaire, inscrire, accepterDemande, nouveauCompte } from './inscription.mjs';

const cas = process.argv[2] ?? 'A';
const t = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const p = await parcours(`Cas ${cas}`, `cas-${cas}`);
const constats = [];
const constat = (x) => { constats.push(x); p.dire(`CONSTAT : ${x}`); };

/// Le formulaire « Ajouter un profil élève » ou « Créer mon profil élève », en
/// etapes : prenom, nom, age, genre... jusqu'au retour au Foyer.
async function profilEleve(a, { prenom, nom, age = /^9( ans)?$/, genre = /garçon|fille|homme|femme/i }, prefixe) {
  for (let k = 0; k < 10; k++) {
    const l = await libelles(a.page);
    p.dire(`  ${prefixe} ${k} : ${l.filter((x) => /^(flt-semantics|input|radio|button:(?!Notifications|Accueil|Foyer|Historique|Compte))/.test(x)).join(' | ').slice(0, 420)}`);
    await p.capture(a, `${prefixe}_${k}`);
    const alerte = l.find((x) => /(existe déjà|même nom|déjà un profil|doublon|déjà inscrit)/i.test(x));
    if (alerte) return { alerte };
    for (const c of await a.page.locator('input').all()) {
      const n = `${await c.getAttribute('aria-label') ?? ''}`;
      let v = null;
      if (/prénom/i.test(n)) v = prenom; else if (/nom/i.test(n)) v = nom;
      if (v === null) continue;
      await c.click({ force: true }); await a.page.keyboard.press('Control+A');
      await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
    }
    const a1 = await trouver(a.page, age, { delai: 800 });
    if (a1) await a1.click();
    const radios = l.filter((x) => x.startsWith('radio:'));
    if (radios.length) {
      const g = await trouver(a.page, genre, { delai: 800, role: 'radio' }) ?? await trouver(a.page, radios[0].slice(6, 30), { delai: 800 });
      if (g) await g.click();
    }
    const suite = await trouver(a.page, /^(Continuer|Suivant|Ajouter.*|Créer.*|Enregistrer.*|Valider.*|Terminer)$/, { delai: 2500, role: 'button' });
    if (!suite) return { fin: l.slice(0, 12).join(' | ') };
    await suite.click(); await a.page.waitForTimeout(2500); await activerSemantique(a.page);
    if (/#\/tuteur(\/foyer)?\/?$|accueil$/.test(a.page.url()) && k > 0) { await p.capture(a, `${prefixe}_fin`); return { fin: a.page.url() }; }
  }
  return { fin: 'trop d\'etapes' };
}

const profilsDuFoyer = (courriel) => sql(`select string_agg(c.first_name || ' ' || c.last_name || ' (' || c.role || coalesce('/' || sp.student_type, '') || ')', ' ; ' order by c.created_at)
  from public.profiles c join public.profiles t on t.household_id = c.household_id join auth.users u on u.id = t.id
  left join public.student_profiles sp on sp.profile_id = c.id where u.email = '${courriel}'`);

let code = 1;
try {
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);

  if (cas === 'A') {
    const A = { courriel: `e2e-cas-a-${t}@example.com`, prenom: 'E2E Amina', nom: `CasA${t}` };
    const a = await p.contexte('amina', { telephone: true });
    // 1. Le mauvais choix : « J'inscris mon enfant ».
    await nouveauCompte(a, /^J'inscris mon enfant/);
    await p.capture(a, 'mauvais_choix');
    await cliquer(a.page, /^Continuer$/);
    await taper(a.page, 'input', A.prenom);
    await p.capture(a, 'son_prenom_comme_enfant');
    // Peut-elle revenir ? « Retour » jusqu'a « Pour qui ».
    const retour = await trouver(a.page, /^Retour$/, { delai: 2000, role: 'button' });
    if (retour) {
      await retour.click(); await a.page.waitForTimeout(1500);
      const pourQui = await trouverTexte(a.page, /Pour qui créez-vous ce compte/, 3000);
      p.dire(`Retour depuis l'etape 2 : ${pourQui ? 'revient a « Pour qui »' : `ecran ${a.page.url()}`}`);
      await p.capture(a, 'retour_pour_qui');
      await cliquer(a.page, /^J'inscris mon enfant/);
      await cliquer(a.page, /^Continuer$/);
    } else constat('Cas A : pas de « Retour » a l\'etape du prenom de l\'enfant');
    // Elle continue, pressee : son propre prenom, et « 18 ans ou plus ».
    await questionnaire(p, a, [{ q: /Comment s'appelle votre enfant/, saisie: A.prenom }], 'questionnaire');
    await cliquer(a.page, /^18 ans ou plus$/, { pause: 800 });
    await p.capture(a, 'age_18_ou_plus');
    const garde = await trouverTexte(a.page, /À partir de 18 ans[^|]*/, 3000);
    await cliquer(a.page, /^Continuer$/, { pause: 1500 });
    const bloque = /age-0|etape=age/.test(a.page.url());
    p.dire(`« 18 ans ou plus » pour un enfant : ${garde ?? 'aucune phrase'} ; ${bloque ? 'Continuer ne passe pas' : `passe a ${a.page.url()}`}`);
    if (!garde || !bloque) constat('Cas A : « 18 ans ou plus » pour un enfant passe sans avertissement');
    const lien = await trouver(a.page, /Je m'inscris pour moi/, { delai: 1000, role: 'button' }) ?? await trouver(a.page, /Je m'inscris pour moi/, { delai: 500, role: 'link' });
    if (!lien) constat('Cas A : la phrase « avec « Je m\'inscris pour moi » » n\'est pas un lien : il faut deviner deux « Retour » pour changer de choix');
    // Elle revient et s'inscrit pour elle-meme.
    for (let k = 0; k < 4 && !(await trouverTexte(a.page, /Pour qui créez-vous ce compte/, 800)); k++) await cliquer(a.page, /^Retour$/, { pause: 1200 });
    await cliquer(a.page, /^Je m'inscris pour moi/);
    await cliquer(a.page, /^Continuer$/);
    const q = await questionnaire(p, a, [
      { q: /Comment vous appelez-vous|Votre prénom/, saisie: A.prenom },
      { q: /Vous êtes…|Êtes-vous/, choix: /^Une femme$/ },
      { q: /Dans quelle langue/, choix: /^Français$/ },
      { q: /Où en êtes-vous aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
      { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
      { q: /Quels moments/, choix: /^Le soir$/ },
    ], 'questionnaire_moi');
    if (q) throw new Error(`Cas A : questionnaire « pour moi » arrete sur « ${q} »`);
    await inscrire(p, a, { courriel: A.courriel, prenom: A.prenom, nom: A.nom, genre: /^Une femme/ }, 'inscription');
    await accepterDemande(p, d, { liste: 'Élèves adultes', nomComplet: `${A.prenom} ${A.nom}` });
    await connecterParLien(a.page, A.courriel);
    await a.page.waitForTimeout(3000);
    await p.capture(a, 'accueil');
    p.dire(`Profils du foyer apres acceptation : ${profilsDuFoyer(A.courriel)}`);
    // 2. Elle cherche sa classe et « s'inscrit » de nouveau : Foyer › « Ajouter un profil élève » a son nom.
    await allerOnglet(a.page, 'Foyer', '/tuteur/foyer', p.dire);
    await p.capture(a, 'foyer');
    const foyer = (await libelles(a.page)).filter((x) => /profil|Ajouter|Créer/i.test(x)).join(' | ');
    p.dire(`Foyer : ${foyer}`);
    const ajout = await trouver(a.page, /^(Ajouter un profil élève|Créer mon profil élève)/, { delai: 4000 });
    if (!ajout) throw new Error('Cas A : ni « Ajouter un profil élève » ni « Créer mon profil élève » sur le Foyer');
    p.dire(`Elle touche : ${(await ajout.getAttribute('aria-label')) ?? (await ajout.textContent())}`);
    await ajout.click(); await a.page.waitForTimeout(2500);
    const r = await profilEleve(a, { prenom: A.prenom, nom: A.nom, age: /^17( ans)?$/, genre: /fille|femme/i }, 'ajout_a_son_nom');
    const apres = profilsDuFoyer(A.courriel);
    p.dire(`Ajout a son propre nom : ${JSON.stringify(r)} ; profils : ${apres}`);
    const meme = (apres.match(new RegExp(`${A.prenom} ${A.nom}`, 'g')) ?? []).length;
    if (!r.alerte && meme >= 2) constat(`Cas A : une eleve adulte inscrite « pour moi » cree sans avertissement un second profil eleve (mineur) a son propre nom : ${apres}`);
  } else {
    const B = { courriel: `e2e-cas-b-${t}@example.com`, enfant: 'E2E Bilal', nomEnfant: `CasB${t}` };
    const m = await p.contexte('mere', { telephone: true });
    await nouveauCompte(m, /^J'inscris mon enfant/);
    await cliquer(m.page, /^Continuer$/);
    await questionnaire(p, m, [
      { q: /Comment s'appelle votre enfant/, saisie: B.enfant },
      { q: /Quel âge a/, choix: /^8 ans$/ },
      { q: / est…/, choix: /^Un garçon$/ },
      { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
      { q: /Suivez-vous aussi des cours/, choix: /^Non$/ },
      { q: /Dans quelle langue/, choix: /^Français$/ },
      { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
      { q: /Quels moments/, choix: /^Le soir$/ },
    ], 'questionnaire');
    // A l'identite, elle tape le nom de l'enfant (le piege).
    const vus = await inscrire(p, m, { courriel: B.courriel, prenom: B.enfant, nom: B.nomEnfant, genre: /^Une femme/ }, 'inscription');
    const identite = vus.find((x) => /Comment vous appelez-vous/.test(x)) ?? vus[0];
    p.dire(`Ecran d'identite lu : « ${identite} »`);
    if (!/(parent|tuteur|vous-même|votre nom, pas celui|à vous)/i.test(identite)) constat(`Cas B : l'etape d'identite ne dit pas « votre nom a vous, le parent » (lu : « ${identite.slice(0, 200)} »)`);
    const recap = vus.find((x) => /Voici ce que nous avons compris/.test(x)) ?? '';
    p.dire(`Recapitulatif : ${recap.slice(0, 300)}`);
    await accepterDemande(p, d, { liste: 'Familles', nomComplet: `${B.enfant} ${B.nomEnfant}` });
    p.dire('Direction : la demande au nom de l\'enfant (parent et enfant du meme nom) a ete acceptee ; aucun avertissement lu');
    await connecterParLien(m.page, B.courriel);
    await m.page.waitForTimeout(3000);
    await p.capture(m, 'accueil');
    // Deux profils pour le meme enfant : nom complet, puis nom court.
    for (const [i, prenom] of [[1, B.enfant], [2, 'E2E Bil']]) {
      await allerOnglet(m.page, 'Foyer', '/tuteur/foyer', p.dire);
      await cliquer(m.page, /^Ajouter un profil élève/, { pause: 2500 });
      const r = await profilEleve(m, { prenom, nom: B.nomEnfant, age: /^8( ans)?$/, genre: /garçon/i }, `ajout_${i}`);
      p.dire(`Ajout ${i} (« ${prenom} ${B.nomEnfant} ») : ${JSON.stringify(r)}`);
      if (r.alerte) p.dire(`  avertissement : ${r.alerte}`);
    }
    const apres = profilsDuFoyer(B.courriel);
    p.dire(`Profils du foyer : ${apres}`);
    const meme = (apres.match(new RegExp(`${B.enfant} ${B.nomEnfant}`, 'g')) ?? []).length;
    if (meme >= 3) constat(`Cas B : trois personnes « ${B.enfant} ${B.nomEnfant} » dans le foyer (le parent et deux profils eleves) sans aucun avertissement : ${apres}`);
    else if (meme >= 2) constat(`Cas B : doublon de profil au meme nom dans le foyer sans avertissement : ${apres}`);
  }
  fs.writeFileSync(path.join(p.sortie, 'constats.txt'), constats.join('\n') + '\n');
  code = await p.fin(constats.length ? 'rouge' : 'vert', constats.join(' ; ').slice(0, 900));
} catch (err) {
  code = await p.fin('rouge', `le scenario n'a pas pu aller au bout : ${String(err.message ?? err).slice(0, 600)}`);
}
process.exit(code);
