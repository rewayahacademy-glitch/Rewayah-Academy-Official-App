// Rang 14 (03/11/2026) : captures des trois salles du parcours d'un candidat
// enseignant, pour le directeur, sur la pile LOCALE seulement (jamais un
// apercu Vercel, jamais la production). Aucun fichier de lib/ n'est touche.
//
// Les trois salles (noms cote candidat du 02/11, recrutement.salles) :
//   1. Salle d'examen                       (etape prequalification) ;
//   2. Salle de verification et d'entretien (etape verifications) ;
//   3. Salle des prets a enseigner          (etape confirmee).
//
// Amorce (SQL local, comme amorcer.sh et i1_invitations pour ce que ce robot
// ne prouve pas) : trois comptes de candidat, un par salle, et leur
// candidature a l'etape de la salle. Le parcours qui les y mene (invitation,
// questionnaire, admission) est prouve par ses propres robots ; ici on montre
// seulement ce que chacun VOIT. Ce qui est vu :
//   - le candidat connecte, sur son ecran d'attente (/attente/candidature) ;
//   - la direction, sur Personnes > Candidatures filtre sur la salle (ADM-20),
//     puis la fiche du candidat (ADM-21).
// A 390 x 844 et 1440 x 900. Captures dans
// docs/current/captures/E2E/trois-salles/<date>/.
//
// Usage : node tool/e2e/trois_salles.mjs
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES, MDP } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('Rang 14 : les trois salles du candidat enseignant', `trois-salles/${date}`);
const n = Date.now() % 1000000;
const lus = async (page, k = 80) => (await libelles(page)).slice(0, k).join(' | ');

const SALLES = [
  { cle: 'salle-1-examen', nom: "Salle d'examen", etape: 'prequalification', etat: 'a_completer',
    filtre: /^Salle d'examen/, prenom: 'E2E Amina', genre: 'female' },
  { cle: 'salle-2-verification', nom: "Salle de vérification et d'entretien", etape: 'verifications',
    etat: 'entretien_a_planifier', filtre: /^Salle de vérification et d'entretien/, prenom: 'E2E Khadija', genre: 'female' },
  { cle: 'salle-3-prets', nom: 'Salle des prêts à enseigner', etape: 'confirmee', etat: null,
    filtre: /^Salle des prêts à enseigner/, prenom: 'E2E Maryam', genre: 'female', piecesFaites: true },
];
// Les trois candidates sont des femmes, comme la direction de test : la liste
// de la direction est cloisonnee par genre EN BASE (CAND-Q07), un candidat
// homme n'y apparaitrait pas pour elle.

function creerCompte(courriel) {
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

function amorcer(s, i) {
  s.courriel = `e2e-salle${i + 1}-${n}@example.com`;
  s.nomFamille = `Salle${i + 1}x${n}`;
  s.id = creerCompte(s.courriel);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${s.id}', 'E2E-SAL${i + 1}-${n}', 'teacher', '${s.prenom}', '${s.nomFamille}', 'pending_kyc', '${s.genre}')`);
  s.reference = sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source, pays_residence)
       values ('enseignant', '${s.id}', '${s.genre}', '${s.prenom} ${s.nomFamille}', '${s.etape}',
               ${s.etat ? `'${s.etat}'` : 'null'}, 'lien_public', 'FR')
       returning reference`).split('\n')[0];
  if (s.piecesFaites) {
    // Salle 3 : la piece d'identite et les conditions se font en Salle de
    // verification ; une candidate en Salle des prets les a deja. Comme
    // amorcer.sh pour l'enseignant valide : piece approuvee, accord et code
    // signes ; le compte reste en attente (pending_kyc).
    sql(`insert into public.teacher_profiles (profile_id, country, languages, kyc_status)
         values ('${s.id}', 'FR', '{fr}', 'approved')
         on conflict (profile_id) do update set kyc_status = 'approved'`);
    // Une piece d'identite approuvee (aucun fichier : la cle d'objet est
    // fictive, la piece n'est jamais ouverte par ce robot).
    sql(`insert into public.kyc_documents (profile_id, doc_type, gender, object_key, status, verified_by, verified_at)
         values ('${s.id}', 'id_card', '${s.genre}', 'e2e/trois-salles/${s.id}.jpg', 'approved',
                 (select id from auth.users where email = '${COMPTES.direction}'), now())`);
    sql(`do $c$ declare v_nda text; v_notice text; begin
      select version into v_nda from public.contract_texts where contract_kind='teacher_nda' and locale='fr' and is_current;
      select version into v_notice from public.contract_required_versions where contract_kind='recording_and_control_notice';
      perform set_config('request.jwt.claim.sub', '${s.id}', true);
      perform set_config('request.jwt.claims', '{"sub":"${s.id}","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
      perform public.signer_contrat(v_nda, '${s.prenom} ${s.nomFamille}');
      insert into public.contract_acceptances(profile_id, contract_kind, version)
        values ('${s.id}', 'recording_and_control_notice', v_notice) on conflict do nothing;
      insert into public.contract_acceptances(profile_id, contract_kind, version)
        values ('${s.id}', 'teacher_conduct_code', public.code_conduite_version_requise()) on conflict do nothing;
    end $c$;`);
  }
  p.dire(`Amorce ${s.cle} : ${s.prenom} ${s.nomFamille} (${s.courriel}), ${s.reference}, etape ${s.etape}${s.etat ? ` / ${s.etat}` : ''}`);
}

let code = 1;
const constats = {};
try {
  SALLES.forEach(amorcer);

  for (const [largeur, hauteur] of [[390, 844], [1440, 900]]) {
    const vue = { width: largeur, height: hauteur };
    for (const s of SALLES) {
      // 1. Ce que voit le candidat.
      const c = await p.contexte(`${s.cle}-candidat`, { vue });
      await connecter(c.page, s.courriel);
      await c.page.waitForTimeout(4000); await activerSemantique(c.page);
      const ecran = await lus(c.page, 120);
      p.dire(`${largeur} ${s.cle}, candidat (${c.page.url()}) : ${ecran}`);
      constats[`${s.cle}_${largeur}_candidat`] = { adresse: c.page.url(), nomDeLaSalle: ecran.includes(s.nom) };
      await p.capture(c, `${s.cle}_candidat_${largeur}`);
      await c.ctx.close();

      // 2. Ce que voit la direction : la liste filtree sur la salle, puis la fiche.
      const d = await p.contexte(`${s.cle}-direction`, { vue });
      await connecter(d.page, COMPTES.direction);
      await ouvrir(d.page, '/#/admin/personnes/candidatures');
      await d.page.waitForTimeout(3000); await activerSemantique(d.page);
      let filtre = await trouver(d.page, s.filtre, { delai: 3000 });
      if (!filtre) {
        // Bureau : les salles sont rangees sous « Plus ».
        const plus = await trouver(d.page, /^Plus$/, { delai: 4000 });
        if (plus) { await plus.click(); await d.page.waitForTimeout(1200); await activerSemantique(d.page); }
        filtre = await trouver(d.page, s.filtre, { delai: 5000 });
      }
      if (filtre) {
        await amenerEnVue(d.page, filtre); await filtre.click(); await d.page.waitForTimeout(2000);
        // La boite « Autres filtres » se ferme, la liste filtree reste.
        const ouverte = async () => (await lus(d.page, 200)).includes('Autres filtres');
        await activerSemantique(d.page);
        if (await ouverte()) {
          await d.page.keyboard.press('Escape'); await d.page.waitForTimeout(1500); await activerSemantique(d.page);
          const fermeeParEchap = !(await ouverte());
          constats[`${s.cle}_${largeur}_autres_filtres_echap`] = fermeeParEchap;
          if (!fermeeParEchap) {
            // Toucher en dehors de la boite, comme un humain.
            await d.page.mouse.click(8, hauteur - 8); await d.page.waitForTimeout(1500); await activerSemantique(d.page);
            constats[`${s.cle}_${largeur}_autres_filtres_dehors`] = !(await ouverte());
          }
        }
      }
      const liste = await lus(d.page, 120);
      p.dire(`${largeur} ${s.cle}, direction, liste filtree (${filtre ? 'filtre touche' : 'FILTRE ABSENT'}) : ${liste}`);
      constats[`${s.cle}_${largeur}_liste`] = { filtre: Boolean(filtre), candidatVu: liste.includes(s.nomFamille) };
      await p.capture(d, `${s.cle}_direction_liste_${largeur}`);
      await ouvrir(d.page, `/#/admin/personnes/candidatures/${encodeURIComponent(s.reference)}`);
      await d.page.waitForTimeout(3000); await activerSemantique(d.page);
      const fiche = await lus(d.page, 160);
      p.dire(`${largeur} ${s.cle}, direction, fiche ${s.reference} : ${fiche}`);
      constats[`${s.cle}_${largeur}_fiche`] = { nomDeLaSalle: fiche.includes(s.nom) };
      await p.capture(d, `${s.cle}_direction_fiche_${largeur}`);
      await d.ctx.close();
    }
  }
  p.dire(`Constats : ${JSON.stringify(constats)}`);
  // Des captures, pas une recette : le verdict dit que tout a ete montre ;
  // les manques sont ecrits a la main dans les pages de chaque salle.
  code = await p.fin('joué', 'captures des trois salles, cote candidat et cote direction');
} catch (err) {
  p.dire(`Constats partiels : ${JSON.stringify(constats)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
