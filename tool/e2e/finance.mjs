// Finance : paie des enseignants, factures du mois, revenus de l'enseignant,
// vue globale. Joue l'interface et confronte au bareme (DECISION-TARIFS :
// 55 $ enfant, 65 $ adulte hors taxes ; enseignant 1,99 $ / 1,57 $ par eleve
// present et par heure).
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, sql, COMPTES } from './commun.mjs';

const p = await parcours('Finance : paie, factures, revenus', 'finance');
const constats = [];
const noter = (x) => { constats.push(x); p.dire(`CONSTAT : ${x}`); };
const section = async (page, nom) => {
  await cliquer(page, /^Sections de la page/);
  await cliquer(page, new RegExp(`^${nom}$`), { pause: 2500 });
};
try {
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  await cliquer(d.page, 'Finance Onglet', { pause: 2500 });
  await p.capture(d, 'vue_globale');
  const vg = await trouverTexte(d.page, /Pas encore disponible[^|]*/, 3000);
  if (vg) noter(`Finance › Vue globale : « ${vg} »`);

  // Paie des enseignants : montants, detail d'octobre.
  await section(d.page, 'Paie des enseignants');
  const aff = await trouver(d.page, /^Afficher les montants/, { delai: 2000 });
  if (aff) { await aff.click(); await d.page.waitForTimeout(1500); }
  await p.capture(d, 'paie_liste');
  const lignes = (await libelles(d.page)).filter((x) => /^checkbox:Sélectionner le paiement/.test(x));
  p.dire(`Paie : ${lignes.join(' | ').slice(0, 600)}`);
  await d.page.getByRole('button', { name: /^Voir$/ }).first().click();
  await d.page.waitForTimeout(3000);
  await p.capture(d, 'paie_detail');
  const err = await trouverTexte(d.page, /Nous n'avons pas pu lire[^|]*/, 3000);
  if (err) noter(`Paie › détail : « ${err} »`);
  const detail = (await libelles(d.page)).filter((x) => /\$|Classe|Source/.test(x));
  p.dire(`Detail : ${detail.join(' | ').slice(0, 500)}`);
  // Factures du mois.
  await cliquer(d.page, /^Retour$/, { role: 'button', pause: 2000 });
  await section(d.page, 'Paiements');
  await p.capture(d, 'paiements');
  const f = sql(`select string_agg(p.first_name || ' (' || coalesce(sp.student_type::text, '?') || ') ' || f.mois || ' ' || (f.lignes -> 0 -> 'montant' ->> 'mineur'), ' ; ')
    from public.factures_mensuelles f join public.profiles p on p.id = f.profile_id left join public.student_profiles sp on sp.profile_id = p.id`);
  p.dire(`Factures en base : ${f || 'aucune'}`);
  for (const m of (f || '').split(' ; ').filter(Boolean)) {
    const attendu = /\(minor\)/.test(m) ? '5500' : '6500';
    if (!m.endsWith(attendu)) noter(`facture hors bareme : ${m} (attendu ${attendu} cents)`);
  }

  // Revenus de l'enseignant : le mois des seances donnees.
  const e = await p.contexte('enseignant');
  await connecter(e.page, COMPTES.enseignant);
  await cliquer(e.page, /^Voir vos revenus estimés/, { pause: 3000 });
  await cliquer(e.page, /^Mois/, { pause: 1500 });
  const mois = (await libelles(e.page)).filter((x) => x.startsWith('menuitem:')).map((x) => x.slice(9));
  await p.capture(e, 'revenus_mois');
  p.dire(`Revenus : mois proposes : ${mois.join(', ')}`);
  if (!mois.some((m) => /octobre/.test(m))) noter(`Revenus estimés : seul « ${mois.join(', ')} » est proposé ; octobre, mois des séances données, n'est pas consultable`);
  await e.page.keyboard.press('Escape');

  // Famille : paiements et recus.
  p.dire(`Constats : ${constats.length}`);
  await p.fin(constats.length ? 'rouge' : 'vert', constats.join(' ; ').slice(0, 900));
} catch (err) {
  await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
