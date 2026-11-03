// ADM-UX (03/11/2026) : trois constats de Personnes > Demandes
// (docs/current/UX-CONSTATS.md), sur la pile LOCALE seulement (jamais un
// apercu Vercel, jamais la production).
//
//   UX-007 : la recherche garde le focus ; le nom tape lettre a lettre au
//            clavier entre en entier ;
//   UX-014 : la boite d'une demande se ferme par Echap et par « Fermer » ;
//   UX-006 : apres « Accepter la demande », la boite dit l'etat relu
//            (« Acceptée »), plus « À traiter ».
//
// A 1440 x 900 et 390 x 844, en clair et en sombre. Une personne de test par
// passage, inscrite par le vrai chemin (`inscrire_titulaire`, usage « moi » :
// une eleve adulte, du meme genre que la direction de la pile). Rien d'autre
// n'est touche. Usage : node tool/e2e/adm_ux.mjs
import { randomUUID } from 'node:crypto';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
// PHASE=avant : la meme preuve sur une construction de main, sans le lot.
const phase = process.env.PHASE ?? 'apres';
const p = await parcours(`ADM-UX (${phase}) : Personnes > Demandes (recherche, fermeture, etat apres acceptation)`,
  `adm-ux/${date}/${phase}`);
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const verdicts = {};

/// Une demande recue d'une eleve adulte, par le vrai chemin.
function inscrire(suffixe) {
  const u = randomUUID();
  const nom = `Essai${suffixe}`;
  sql(`begin;
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    values ('${u}', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'e2e.admux.${suffixe}@exemple.test', '', now(), '{}', '{}', now(), now());
    select set_config('request.jwt.claims', '{"sub":"${u}","role":"authenticated"}', true);
    select set_config('request.jwt.claim.sub', '${u}', true);
    select id from public.inscrire_titulaire('moi', 'Karima', '${nom}', 'female', 'Europe/Paris', false);
    commit;`);
  return { id: u, nom: `Karima ${nom}` };
}

let code = 1;
try {
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    for (const sombre of [false, true]) {
      const cle = `${largeur}_${sombre ? 'sombre' : 'clair'}`;
      const personne = inscrire(`${Date.now() % 1000000}`);
      p.dire(`${cle} : personne de test ${personne.nom} (${personne.id})`);
      const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur }, sombre });
      await connecter(c.page, COMPTES.direction);
      await ouvrir(c.page, '/#/admin/personnes/demandes');
      await c.page.waitForTimeout(3000); await activerSemantique(c.page);
      const adultes = await trouver(c.page, /^Élèves adultes/, { delai: 8000 });
      if (adultes) { await adultes.click(); await c.page.waitForTimeout(2000); }

      // UX-007 : le nom tape lettre a lettre, au clavier.
      const champ = await trouver(c.page, /^Rechercher/, { delai: 8000, role: 'textbox' });
      if (!champ) throw new Error(`${cle} : champ de recherche absent ; ${await lus(c.page, 40)}`);
      await champ.click();
      // Le champ de Flutter web prend le focus apres le clic : on attend
      // qu'un vrai champ de saisie ait le focus, comme un humain qui commence
      // a taper apres avoir vu le curseur.
      await c.page.waitForFunction(() => {
        const e = document.activeElement;
        return !!e && (e.tagName === 'INPUT' || e.tagName === 'TEXTAREA');
      }, null, { timeout: 5000 }).catch(() => {});
      await c.page.waitForTimeout(300);
      await c.page.keyboard.type(personne.nom, { delay: 120 });
      await c.page.waitForTimeout(2500); await activerSemantique(c.page);
      const valeur = await c.page.evaluate(() => {
        const e = document.activeElement;
        return e && 'value' in e ? e.value : null;
      });
      const saisie = valeur ?? (await (await trouver(c.page, /^Rechercher/, { delai: 2000, role: 'textbox' }))?.inputValue());
      p.dire(`${cle}, UX-007 : saisi au clavier « ${personne.nom} », le champ contient « ${saisie} »`);
      verdicts[`${cle}_ux007`] = saisie === personne.nom;
      await p.capture(c, `${cle}_recherche_au_clavier`);

      // UX-014 : la boite se ferme par Echap.
      const carte = await trouver(c.page, new RegExp(personne.nom), { delai: 8000 });
      if (!carte) throw new Error(`${cle} : carte de ${personne.nom} absente ; ${await lus(c.page, 40)}`);
      await amenerEnVue(c.page, carte);
      await carte.click(); await c.page.waitForTimeout(2000); await activerSemantique(c.page);
      const ouverteA = !!(await trouver(c.page, /^Accepter la demande/, { delai: 5000 }));
      await p.capture(c, `${cle}_boite_ouverte`);
      await c.page.keyboard.press('Escape');
      await c.page.waitForTimeout(1500); await activerSemantique(c.page);
      const fermeeEchap = !(await trouver(c.page, /^Accepter la demande/, { delai: 1500 }));
      p.dire(`${cle}, UX-014 : boite ouverte ${ouverteA}, fermee par Echap ${fermeeEchap}`);

      // UX-006 : accepter, puis lire la ligne d'etat de la boite.
      const carte2 = await trouver(c.page, new RegExp(personne.nom), { delai: 8000 });
      await amenerEnVue(c.page, carte2);
      await carte2.click(); await c.page.waitForTimeout(2000); await activerSemantique(c.page);
      const fermer = await trouver(c.page, /^Fermer$/, { delai: 5000 });
      const accepter = await trouver(c.page, /^Accepter la demande/, { delai: 5000 });
      if (!accepter) throw new Error(`${cle} : « Accepter la demande » absent ; ${await lus(c.page, 60)}`);
      await amenerEnVue(c.page, accepter);
      await accepter.click(); await c.page.waitForTimeout(5000); await activerSemantique(c.page);
      const boite = await lus(c.page, 200);
      const base = sql(`select etape || ' / ' || issue from public.candidatures where profile_id = '${personne.id}'`);
      p.dire(`${cle}, UX-006 : base « ${base} » ; ecran apres Accepter : ${boite}`);
      await p.capture(c, `${cle}_boite_apres_accepter`);
      // La boite dit « État Acceptée » ; « À traiter » ne reste que dans les
      // compteurs de la page, jamais en face de « État ».
      verdicts[`${cle}_ux006`] = /État[^|]*Acceptée|État \| Acceptée|Acceptée/.test(boite)
        && !/État[^|]*À traiter|État \| À traiter/.test(boite);

      // UX-014 : la croix « Fermer ».
      const fermer2 = await trouver(c.page, /^Fermer$/, { delai: 5000 });
      if (fermer2) { await fermer2.click(); await c.page.waitForTimeout(1500); await activerSemantique(c.page); }
      const fermeeCroix = !(await trouver(c.page, /est acceptée/, { delai: 1500 }));
      p.dire(`${cle}, UX-014 : « Fermer » present ${!!fermer && !!fermer2}, boite fermee par la croix ${fermeeCroix}`);
      verdicts[`${cle}_ux014`] = ouverteA && fermeeEchap && !!fermer && !!fermer2 && fermeeCroix;
      await p.capture(c, `${cle}_boite_fermee`);
      await c.ctx.close();
    }
  }
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(phase === 'avant' ? 'joué' : (ok ? 'vert' : 'rouge'), ok ? '' : JSON.stringify(verdicts));
  if (phase === 'avant') code = 0;
} catch (e) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(e).slice(0, 400));
}
process.exit(code);
