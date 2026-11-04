// Lot C1 (02/11/2026) : creer, cloturer, recreer une classe.
//
// Pile LOCALE seulement (jamais un apercu Vercel, jamais la production). La
// migration 20261105200000 doit etre installee sur la pile.
//   1. « Nouvelle classe » s'ouvre sur UN creneau (UX-003) ; la phrase du
//      fuseau dit la ville, jamais l'identifiant IANA (UX-030) ; Echap avec une
//      saisie demande confirmation (UX-031) ; la classe A se cree avec un seul
//      creneau.
//   2. La premiere seance de A est ramenee a maintenant (debut il y a 5
//      minutes, en SQL local : « pendant l'heure de sa seance ») ; la direction
//      cloture A depuis sa fiche ; la seance passe « annulee » (FN-103).
//   3. La classe B, meme enseignant, meme horaire : acceptee.
//   4. La classe C, meme enseignant, meme horaire : refusee, et le refus nomme
//      la classe B et l'heure (UX-020).
// Usage : node tool/e2e/c1_classes.mjs ; VUE=390x844 pour le telephone.
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, taper, sql,
  nettoyerClassesE2E, activerSemantique, COMPTES } from './commun.mjs';
import { horaireProche } from './horaire.mjs';

const [largeur, hauteur] = (process.env.VUE ?? '1440x900').split('x').map(Number);
const p = await parcours(`C1 : creer, cloturer, recreer une classe (${largeur} x ${hauteur})`,
  `c1-classes/${largeur}`);
let code = 1;
const echap = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const verdicts = {};
try {
  let h = horaireProche({ delaiMin: 8, delaiMax: 60 });
  while (!h) { await new Promise((r) => setTimeout(r, 60000)); h = horaireProche({ delaiMin: 8, delaiMax: 60 }); }
  const suffixe = new Date().toISOString().slice(11, 16).replace(':', '');
  const noms = { a: `E2E C1 A ${largeur} ${suffixe}`, b: `E2E C1 B ${largeur} ${suffixe}`, c: `E2E C1 C ${largeur} ${suffixe}` };
  p.dire(`Horaire : ${h.jour} ${h.heure} h (${h.fuseau}), debut ${h.debut.toISOString()} ; classes ${JSON.stringify(noms)}`);
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  nettoyerClassesE2E();
  sql(`update public.teacher_profiles set timezone_iana = '${h.fuseau}' where profile_id = '${prof}'`);

  const d = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  await connecter(d.page, COMPTES.direction);
  const allerAuxClasses = async () => {
    // Au telephone, la navigation de la direction est derriere « Menu ».
    if (!(await trouver(d.page, /^Opérations( Onglet.*)?$/, { delai: 3000 }))) {
      await cliquer(d.page, /^Menu$/, { role: 'button', pause: 1200 });
    }
    await cliquer(d.page, /^Opérations( Onglet.*)?$/);
    await cliquer(d.page, /^Classes$/);
    await d.page.waitForTimeout(1500);
  };
  await allerAuxClasses();

  // Remplit la feuille « Nouvelle classe » (un seul creneau) ; rend le texte lu.
  const remplir = async (nom, { capturer = false } = {}) => {
    await cliquer(d.page, 'Nouvelle classe');
    await d.page.waitForTimeout(1200);
    if (capturer) {
      const heures = await d.page.getByRole('button', { name: /^Heure/ }).count();
      const retirer = await trouver(d.page, /^Retirer le créneau 2/, { delai: 1500 });
      verdicts.unSeulCreneau = heures === 1 && !retirer;
      const ajouter = await trouver(d.page, /^Ajouter un créneau/, { delai: 3000 });
      if (ajouter) await ajouter.scrollIntoViewIfNeeded().catch(() => {});
      await d.page.waitForTimeout(600);
      const phraseAutres = await trouverTexte(d.page, /Ajoutez une ligne par autre jour/, 3000);
      verdicts.unSeulCreneau = verdicts.unSeulCreneau && !!ajouter && !!phraseAutres;
      p.dire(`UX-003 : boutons « Heure » a l'ouverture = ${heures} ; « Retirer le créneau 2 » ${retirer ? 'present' : 'absent'} ; « Ajouter un créneau » ${ajouter ? 'present' : 'absent'} ; phrase : ${phraseAutres ?? 'absente'}`);
      await p.capture(d, 'nouvelle_classe_un_seul_creneau');
    }
    await cliquer(d.page, /^Enfants\./, { role: 'radio' });
    await cliquer(d.page, /^Garçons\./, { role: 'radio' });
    await cliquer(d.page, /^E2E Enseignant Valide/, { role: 'radio' });
    await d.page.getByRole('button', { name: new RegExp(`^${h.jour}$`) }).first().click();
    await d.page.waitForTimeout(500);
    await d.page.getByRole('button', { name: /^Heure/ }).first().click();
    await d.page.waitForTimeout(700);
    await cliquer(d.page, new RegExp(`^${h.heure} h$`), { role: 'menuitem' });
    await taper(d.page, 'input[aria-label^="Nom de la classe"]', nom);
    if (capturer) {
      const phrase = await trouverTexte(d.page, /Heures à l.heure/, 5000);
      verdicts.villeEnClair = !!phrase && !phrase.includes(h.fuseau) && !/[A-Za-z]+\/[A-Za-z]/.test(phrase);
      p.dire(`UX-030 : phrase du fuseau : ${phrase ?? 'absente'}`);
      const cible = await trouver(d.page, /^Heure/, { role: 'button', delai: 2000 });
      if (cible) await cible.scrollIntoViewIfNeeded().catch(() => {});
      await p.capture(d, 'creneau_et_ville_en_clair');
      // UX-031 : Echap avec une saisie demande confirmation ; on continue.
      await d.page.keyboard.press('Escape');
      await d.page.waitForTimeout(1500);
      const question = await trouverTexte(d.page, /Abandonner la nouvelle classe/, 4000);
      await p.capture(d, 'echap_demande_confirmation');
      await cliquer(d.page, /^Continuer la saisie$/, { role: 'button', pause: 1200 });
      const toujours = await trouver(d.page, /^Créer la classe$/, { role: 'button', delai: 3000 });
      verdicts.echapConfirme = !!question && !!toujours;
      p.dire(`UX-031 : Echap -> ${question ?? 'aucune question'} ; feuille gardee : ${!!toujours}`);
    }
    await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 3500 });
  };
  const enBase = (nom) => sql(`select g.etat || '|' || (select count(*) from public.groupe_creneaux c where c.groupe_id = g.id)
     from public.groupes g where g.libelle = '${nom}' and g.ended_at is null`);

  // 1. Classe A, un seul creneau.
  await remplir(noms.a, { capturer: true });
  const a = enBase(noms.a);
  verdicts.classeACreee = a === 'active|1';
  p.dire(`Classe A en base : ${a || 'absente'} (attendu active|1)`);
  const idA = sql(`select id from public.groupes where libelle = '${noms.a}'`);
  if (!idA) throw new Error(`classe A absente ; ecran : ${(await libelles(d.page)).slice(-20).join(' | ')}`);

  // 2. La premiere seance de A commence il y a 5 minutes (base locale).
  const seanceA = sql(`update public.sessions set started_at = now() - interval '5 minutes',
       join_opens_at = now() - interval '25 minutes'
     where id = (select id from public.sessions where groupe_id = '${idA}' and status = 'planned'
                  order by started_at limit 1)
     returning id || ' ' || started_at || ' -> ' || ended_at`);
  p.dire(`Seance de A ramenee a maintenant : ${seanceA}`);
  const idSeanceA = seanceA.split(' ')[0];

  await activerSemantique(d.page);
  await cliquer(d.page, new RegExp(`^${echap(noms.a)}`));
  await d.page.waitForTimeout(2000); await activerSemantique(d.page);
  await cliquer(d.page, /^Clôturer la classe$/, { pause: 1500 });
  await cliquer(d.page, /^Fin du cycle de la classe$/);
  await p.capture(d, 'cloture_pendant_la_seance');
  await cliquer(d.page, /^Clôturer$/, { role: 'button', pause: 3000 });
  const statut = sql(`select status from public.sessions where id = '${idSeanceA}'`);
  const close = sql(`select ended_at is not null from public.groupes where id = '${idA}'`) === 't';
  verdicts.seanceAnnulee = close && statut === 'canceled';
  p.dire(`FN-103 : A close = ${close} ; seance en cours de A : ${statut} (attendu canceled)`);

  // 3. Classe B : meme enseignant, meme horaire : acceptee.
  await activerSemantique(d.page);
  if (!(await trouver(d.page, 'Nouvelle classe', { delai: 3000 }))) await allerAuxClasses();
  await remplir(noms.b);
  const b = enBase(noms.b);
  verdicts.classeBAcceptee = b === 'active|1';
  p.dire(`Classe B (meme horaire, meme enseignant) en base : ${b || 'absente'} ; ecran : ${(await libelles(d.page)).slice(-8).join(' | ')}`);
  await activerSemantique(d.page);
  const ligneB = await trouverTexte(d.page, noms.b, 8000);
  if (ligneB) {
    const l = await trouver(d.page, new RegExp(`^${echap(noms.b)}`), { delai: 2000 });
    if (l) await l.scrollIntoViewIfNeeded().catch(() => {});
  }
  await p.capture(d, 'classe_b_recreee_meme_horaire');

  // 4. Classe C : meme horaire, refusee ; le refus nomme B et l'heure.
  await remplir(noms.c);
  await activerSemantique(d.page);
  // L'ecran voit la collision avant le serveur (meme creneau) ; sinon le
  // serveur la nomme (DETAIL). Les deux phrases nomment la classe B.
  const refus = await trouverTexte(d.page, /enseigne déjà la classe|La classe n.est pas créée/, 8000);
  const c = enBase(noms.c);
  verdicts.refusNomme = !c && !!refus && refus.includes(noms.b)
    && new RegExp(`${h.jour.toLowerCase()} à ${h.heure}\\s*h`).test(refus) && !/P0001|23P01|chevauchement avec/.test(refus);
  p.dire(`UX-020 : refus = ${refus ?? 'aucun'} ; C en base : ${c || 'absente'}`);
  // La capture montre le message lui-meme (L2), pas le haut de la feuille.
  const message = await trouver(d.page, /enseigne déjà la classe|La classe n.est pas créée/, { delai: 2000 });
  if (message) await message.scrollIntoViewIfNeeded().catch(() => {});
  await d.page.waitForTimeout(600);
  await p.capture(d, 'refus_nomme_la_classe');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const attendus = ['unSeulCreneau', 'villeEnClair', 'echapConfirme', 'classeACreee', 'seanceAnnulee', 'classeBAcceptee', 'refusNomme'];
  const ok = attendus.every((k) => verdicts[k] === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(e).slice(0, 400));
}
process.exit(code);
