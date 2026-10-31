// Parcours 5 bis : l'eleve enfant rejoint la seance depuis SON appareil (pas le
// compte du tuteur). Le tuteur : Foyer › Appareils du foyer › l'enfant ›
// « Connecter un appareil » (code de six caracteres) ; l'appareil de l'enfant :
// « Connecter l'appareil d'un élève » › « Saisir le code » › « Connecter
// l'appareil » ; puis Accueil de l'enfant › « Rejoindre », l'enseignante dans
// la salle ; chacun voit l'autre.
// Donnees : l'enfant du parcours 3 ; une classe mixte creee ici par la direction
// avec l'enseignante validee au parcours 1 (le premier enseignant peut etre pris).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecter, connecterParLien, cliquer, trouver, trouverTexte,
  libelles, taper, activerSemantique, allerOnglet, sql, COMPTES, TRAVAIL } from './commun.mjs';
import { ouvrirClasses, creerClasse, ajouterEleve, cloturerClasse } from './classes.mjs';
import { horaireProche } from './horaire.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 5 bis : l\'eleve rejoint depuis son propre appareil', 'parcours-5bis');
let code = 1;
try {
  const { FAMILLE } = lire('comptes_parcours3.json');
  // L'enseignant : E2E_PROF_5BIS (courriel) ou, par defaut, l'enseignante validee au parcours 1.
  const choix = process.env.E2E_PROF_5BIS
    ? `u.email = '${process.env.E2E_PROF_5BIS}'` : `p.first_name = 'E2E Candidate'`;
  const prof = sql(`select u.email || '|' || p.first_name || ' ' || p.last_name from public.profiles p join auth.users u on u.id = p.id
    where p.role = 'teacher' and p.account_status = 'active' and ${choix} order by p.created_at desc limit 1`);
  if (!prof) throw new Error('aucun enseignant actif pour le 5 bis');
  const [profCourriel, profNom] = prof.split('|');
  // La seance ne doit chevaucher aucune seance prevue de cet enseignant.
  const libre = sql(`select coalesce(max(s.ended_at), now()) from public.sessions s
    where s.teacher_id = (select id from auth.users where email = '${profCourriel}') and s.deleted_at is null
      and s.status in ('planned', 'preflight', 'in_progress') and s.ended_at > now() and s.started_at < now() + interval '2 hours'`);
  const pasAvant = new Date(libre);
  // Meme fuseau que les classes actives de l'enseignant : le controle compare
  // 52 semaines, changements d'heure compris.
  const tz = sql(`select string_agg(distinct g.timezone_iana, ',') from public.groupes g
    where g.ended_at is null and g.teacher_id = (select id from auth.users where email = '${profCourriel}')`);
  const fuseaux = tz ? tz.split(',') : undefined;
  let h; let nom;
  const reprise = process.env.E2E_CLASSE_5BIS;
  if (reprise) {
    const r = sql(`select g.timezone_iana || '|' || min(s.started_at) from public.groupes g join public.sessions s on s.groupe_id = g.id
      where g.libelle = '${reprise}' and g.ended_at is null and s.ended_at > now() and s.deleted_at is null group by g.timezone_iana`);
    const [fz, debut] = r.split('|');
    h = { fuseau: fz, debut: new Date(debut), jour: '-', heure: '-' };
    nom = reprise;
  } else {
    h = horaireProche({ delaiMax: 75, pasAvant, fuseaux });
    while (!h) { await new Promise((r) => setTimeout(r, 60000)); h = horaireProche({ delaiMax: 75, pasAvant, fuseaux }); }
    sql(`update public.teacher_profiles set timezone_iana = '${h.fuseau}' where profile_id = (select id from auth.users where email = '${profCourriel}')`);
    nom = `E2E Classe mixte ${new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '')}`;
  }
  p.dire(`Enseignant ${profNom} (${profCourriel}) ; classe « ${nom} » ${h.jour} ${h.heure} h (${h.fuseau}), debut ${h.debut.toISOString()}${reprise ? ' (reprise)' : ''}`);

  // Preparation : la direction cree la classe et y place l'enfant.
  if (!reprise) {
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await ouvrirClasses(d.page);
  // Un eleve n'est que dans une classe active : on clot d'abord, par l'interface,
  // les classes E2E encore actives de l'enfant et de l'enseignante.
  const aClore = sql(`select string_agg(distinct g.libelle, '|') from public.groupes g
    left join public.groupe_membres gm on gm.groupe_id = g.id and gm.left_at is null
    left join public.profiles e on e.id = gm.student_id
    where g.ended_at is null and g.libelle like 'E2E %'
      and (e.first_name = '${FAMILLE.enfant}' or (g.libelle like 'E2E Classe mixte%' and g.teacher_id = (select id from auth.users where email = '${profCourriel}')))`);
  for (const c of aClore ? aClore.split('|') : []) await cloturerClasse(p, d, c);
  await creerClasse(p, d, { public: 'Enfants', genre: 'Mixte', enseignant: profNom.split(' ').slice(0, 2).join(' ').replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
    creneaux: [{ jour: h.jour, heure: h.heure }], nom });
  await ajouterEleve(p, d, { classe: nom, eleve: FAMILLE.enfant });
  await d.ctx.close();
  }

  // 1. Le tuteur affiche le code de l'appareil de l'enfant.
  const t = await p.contexte('tuteur', { telephone: true });
  await connecterParLien(t.page, FAMILLE.courriel);
  await allerOnglet(t.page, 'Foyer', '/tuteur/foyer', p.dire);
  await cliquer(t.page, /^Appareils du foyer/, { pause: 2000 });
  await cliquer(t.page, new RegExp(`^${FAMILLE.enfant}`), { pause: 2000 });
  // Les passages precedents ont relie des appareils : le tuteur les retire
  // (« Retirer … »), comme le propose l'ecran une fois la limite atteinte.
  // Le bouton « Retirer » est fondu dans la ligne de l'appareil (pas de noeud
  // propre) : on le touche a sa position (390 x 780 : x 311, y 220), puis on confirme.
  for (let k = 0; k < 6 && await trouver(t.page, /^Navigateur web Connecté/, { delai: 2000, role: 'button' }); k++) {
    await t.page.mouse.click(311, 220); await t.page.waitForTimeout(1500);
    const ok = await trouver(t.page, /^(Retirer|Confirmer|Oui)/, { delai: 2500, role: 'button' });
    p.dire(`  retrait d'un appareil : ${ok ? ((await ok.getAttribute('aria-label')) ?? 'confirmation') : 'pas de confirmation'}`);
    if (ok) { await ok.click(); await t.page.waitForTimeout(2500); } else break;
  }
  await p.capture(t, 'appareils');
  await cliquer(t.page, /^Connecter un appareil$/, { pause: 4000 });
  if (await trouverTexte(t.page, /Un code est déjà valable/, 2000)) {
    // Le bouton « Générer un nouveau code » est fondu dans le groupe du message
    // (pas de noeud propre dans l'arbre d'accessibilite) : on touche le bouton
    // a l'ecran, en bas du groupe.
    p.dire('  ECART : un code etait deja valable (non reaffichable) ; « Générer un nouveau code » n\'a pas de noeud propre dans l\'arbre d\'accessibilite');
    // Position du bouton sur la capture au telephone (390 x 780) : centre, y = 422.
    await t.page.mouse.click(195, 422);
    await t.page.waitForTimeout(3000);
    const conf = await trouver(t.page, /^(Générer|Confirmer|Oui)/, { delai: 2000, role: 'button' });
    if (conf) { await conf.click(); await t.page.waitForTimeout(3000); }
  }
  await p.capture(t, 'code_affiche');
  const lu = await trouverTexte(t.page, /Code à saisir : [A-Z0-9 ]+/, 10000);
  const codeAppareil = lu?.match(/Code à saisir : ([A-Z0-9 ]+)/)?.[1].replace(/\s/g, '');
  if (!codeAppareil) throw new Error(`tuteur, « Connecter un appareil » : pas de code affiche ; ecran : ${(await libelles(t.page)).slice(0, 15).join(' | ')}`);
  p.dire(`Code de l'appareil : ${codeAppareil}`);

  // 2. L'appareil de l'enfant (telephone) : « Connecter l'appareil d'un élève ».
  const e = await p.contexte('eleve', { telephone: true });
  await ouvrir(e.page, '/');
  const entree = await trouver(e.page, /^Connecter l'appareil d'un élève$/, { delai: 4000 });
  if (entree) {
    await entree.click(); await e.page.waitForTimeout(1500);
    await p.capture(e, 'feuille_appareil');
    await cliquer(e.page, /^Saisir le code$/, { pause: 1500 });
  } else {
    // Limite du banc : la construction locale (AUTH_PAR_MOT_DE_PASSE=true)
    // masque cette entree (connexion_page.dart, `if (!demo)`). En production
    // elle est sous le formulaire de connexion. On ouvre son ecran par l'adresse.
    p.dire('  LIMITE : entree « Connecter l\'appareil d\'un élève » masquee par la construction de test ; ecran ouvert par /connexion/eleve');
    await e.page.evaluate(() => { location.hash = '#/connexion/eleve'; });
    await e.page.waitForTimeout(3000); await activerSemantique(e.page);
    await p.capture(e, 'ecran_code_eleve');
    const s = await trouver(e.page, /^Saisir le code$/, { delai: 3000 });
    if (s) { await s.click(); await e.page.waitForTimeout(1500); }
  }
  await taper(e.page, 'input, textarea', codeAppareil);
  await p.capture(e, 'code_saisi');
  await cliquer(e.page, /^Connecter l'appareil$/, { pause: 6000 });
  await activerSemantique(e.page);
  await p.capture(e, 'apres_connexion');
  p.dire(`Appareil de l'enfant : ${e.page.url()} ; ${(await libelles(e.page)).slice(0, 10).join(' | ')}`);
  // Un code personnel peut etre demande a la premiere ouverture.
  for (let k = 0; k < 4; k++) {
    const pin = await trouverTexte(e.page, /(code personnel|Choisissez un code|Confirmez|Entre-le encore)/i, 2000);
    if (!pin) break;
    p.dire(`  ${pin}`);
    // Les touches du clavier n'ont pas de nom lisible : position sur 390 x 780
    // (colonne du milieu : 2, 5, 8, 0).
    // Le second ecran (« Entre-le encore une fois ») n'a pas de sous-titre :
    // la grille remonte.
    const ys = /Entre-le encore/.test(pin) ? [400, 480, 558, 637] : [447, 526, 605, 685];
    for (const y of ys) { await e.page.mouse.click(195, y); await e.page.waitForTimeout(350); }
    await e.page.waitForTimeout(2500); await activerSemantique(e.page);
    await p.capture(e, `code_personnel_${k}`);
  }
  if (await trouverTexte(e.page, /Choisis ton code personnel|Confirme ton code|Entre-le encore/, 1500)) throw new Error('appareil de l\'enfant : le code personnel n\'a pas pu etre choisi');
  const accueil = await trouverTexte(e.page, new RegExp(`${nom}|Rejoindre|Prochaine`), 10000);
  if (!accueil) throw new Error(`appareil de l'enfant apres le code : pas d'Accueil de l'eleve ; ecran : ${(await libelles(e.page)).slice(0, 15).join(' | ')}`);

  // 3. Attente de l'ouverture (20 min avant), l'enseignante entre.
  const ouverture = h.debut.getTime() - 20 * 60000;
  if (Date.now() < ouverture) {
    p.dire(`Attente de l'ouverture de la salle (${new Date(ouverture).toISOString()})`);
    await new Promise((r) => setTimeout(r, ouverture - Date.now() + 20000));
  }
  const ens = await p.contexte('enseignante');
  await connecterParLien(ens.page, profCourriel);
  let r = await trouver(ens.page, new RegExp(`^Rejoindre la salle de la Classe ${nom}`), { delai: 10000 });
  if (!r) {
    p.dire('  ECART (FN-006) : « Aujourd\'hui » garde la seance precedente ; passage par l\'onglet Classes');
    await allerOnglet(ens.page, 'Classes', '/enseignant/classes', p.dire);
    r = await trouver(ens.page, new RegExp(`^Rejoindre la salle de la Classe ${nom}`), { delai: 10000 });
  }
  if (!r) throw new Error(`enseignante : pas de « Rejoindre la salle de la Classe ${nom} » ; ecran : ${(await libelles(ens.page)).slice(0, 15).join(' | ')}`);
  await r.click(); await ens.page.waitForTimeout(6000);
  await cliquer(ens.page, /^Allumer la caméra/, { pause: 1500 });
  await cliquer(ens.page, /^Ouvrir le micro/, { pause: 1500 });

  // 4. L'enfant, sur son appareil : Accueil › « Rejoindre ».
  await e.page.reload(); await e.page.waitForTimeout(6000); await activerSemantique(e.page);
  await p.capture(e, 'accueil_salle_ouverte');
  const rejoindre = await trouver(e.page, /^Rejoindre/, { delai: 15000, role: 'button' });
  if (!rejoindre) throw new Error(`appareil de l'enfant, salle ouverte : pas de « Rejoindre » ; ecran : ${(await libelles(e.page)).slice(0, 20).join(' | ')}`);
  p.dire(`Enfant : ${(await rejoindre.getAttribute('aria-label')) ?? (await rejoindre.textContent())}`);
  await rejoindre.click();
  await e.page.waitForTimeout(8000); await activerSemantique(e.page);
  for (const c of [/^Allumer la caméra/, /^Ouvrir le micro/]) { const b = await trouver(e.page, c, { delai: 2000 }); if (b) { await b.click(); await e.page.waitForTimeout(1000); } }
  await ens.page.waitForTimeout(6000);
  await p.capture(e, 'salle');
  await p.capture(ens, 'salle_eleve_arrive');
  const vuParEns = await trouverTexte(ens.page, new RegExp(`fiche d.{1,4}${FAMILLE.enfant}[^|]*`), 10000);
  const vuParEnfant = await trouverTexte(e.page, /(Sayyida?|E2E Candidate)[^|]*/, 8000);
  p.dire(`Enseignante voit : « ${vuParEns ?? '-'} » ; enfant voit : « ${vuParEnfant ?? '-'} »`);
  if (!vuParEns || /Pas encore connecté/.test(vuParEns)) throw new Error(`salle, enseignante : l'enfant n'apparait pas (« ${vuParEns} »)`);
  if (!vuParEnfant || /Sans image/.test(vuParEnfant)) throw new Error(`salle, appareil de l'enfant : l'enseignante n'apparait pas ou sans image (« ${vuParEnfant} »)`);
  fs.writeFileSync(path.join(TRAVAIL, 'classe_5bis.json'), JSON.stringify({ nom, profCourriel, ...h }, null, 2));
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
