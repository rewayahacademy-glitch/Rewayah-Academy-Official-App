// Rapport du modèle économique, en Markdown sur la sortie standard.
//
//   node tool/simulation/simuler.mjs                 # 1 000 tirages × 12 mois
//   node tool/simulation/simuler.mjs --tirages 200   # plus rapide
//   node tool/simulation/simuler.mjs --json          # résultats bruts

import { SCENARIOS, parametresScenario, simuler } from './modele_academie.mjs';

const args = process.argv.slice(2);
const valeur = (nom) => {
  const i = args.indexOf(nom);
  return i === -1 ? undefined : args[i + 1];
};
const surcharges = {};
if (valeur('--tirages')) surcharges.tirages = Number(valeur('--tirages'));
if (valeur('--graine')) surcharges.graine = Number(valeur('--graine'));

const resultats = Object.fromEntries(
  Object.keys(SCENARIOS).map((code) => [code, simuler(parametresScenario(code, surcharges))]),
);

if (args.includes('--json')) {
  console.log(JSON.stringify(resultats, null, 2));
  process.exit(0);
}

const usd = (centimes) =>
  `${(centimes / 100).toLocaleString('fr-FR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })} $`;
const usd2 = (centimes) =>
  `${(centimes / 100).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} $`;
const pct = (x) => `${Math.round(x * 100)} %`;
const ligne = (cellules) => `| ${cellules.join(' | ')} |`;
const codes = Object.keys(SCENARIOS);
const titres = codes.map((c) => SCENARIOS[c].titre);
const sortie = [];
const ecrire = (...x) => sortie.push(...x);

const ref = resultats.realiste;
const pop = ref.population;
const p = ref.parametres;

ecrire(
  `# Simulation économique — ${p.tirages} tirages × ${p.mois} mois, graine ${p.graine}`,
  '',
  '## Population',
  '',
  `- ${pop.eleves} élèves : ${pop.enfants} enfants, ${pop.adultes} adultes, ${pop.feminin} filles ou femmes.`,
  `- Tranches : ${Object.entries(pop.tranches).map(([k, v]) => `${k} ans ×${v}`).join(', ')}.`,
  `- ${pop.foyers} foyers payeurs ; taille : ${Object.entries(pop.taillesFoyers).map(([k, v]) => `${k} pers. ×${v}`).join(', ')}.`,
  `- ${pop.groupes.length} groupes, ${pop.enseignants.length} enseignants (${pop.enseignants.filter((x) => x.sexe === 'F').length} femmes), ${pop.administration} personnes en administration.`,
  `- Facturation théorique pleine : ${usd(pop.factureTheoriqueCentimes)} / mois, dont ${usd(pop.remisesTheoriquesCentimes)} de remises familiales.`,
  '',
  ligne(['Groupe', 'Public', 'Taille', 'Heures / mois', 'Enseignant']),
  ligne(['---', '---', '---:', '---:', '---:']),
  ...pop.groupes.map((g) =>
    ligne([`G${g.id + 1}`, `${g.type} ${g.tranche} ${g.public}`, `${g.taille}${g.sousMinimum ? ' ⚠' : ''}`, g.heuresParMois, `E${g.enseignant + 1}`]),
  ),
  '',
  '## Mois type (médiane, entre parenthèses : 1 mois sur 10 en dessous / au-dessus)',
  '',
  ligne(['', ...titres]),
  ligne(['---', ...codes.map(() => '---:')]),
);

const rangee = (libelle, f) => ecrire(ligne([libelle, ...codes.map((c) => f(resultats[c].moisType))]));
const fourchette = (d) => `${usd(d.p50)} (${usd(d.p10)} – ${usd(d.p90)})`;
rangee('Élèves actifs', (m) => `${m.elevesActifs.p50}`);
rangee('Facturé', (m) => usd(m.facture.p50));
rangee('**Encaissé**', (m) => `**${fourchette(m.encaisse)}**`);
rangee('Reporté au mois suivant', (m) => usd(m.reporte.p50));
rangee('Perdu (impayés)', (m) => usd(m.impaye.p50));
rangee('Frais de carte', (m) => usd(m.fraisCarte.p50));
rangee('LiveKit', (m) => usd(m.livekit.p50));
rangee('Autres services', (m) => usd(m.servicesFixes));
rangee('**Reste avant enseignants**', (m) => `**${fourchette(m.resultatAvantEnseignants)}**`);
rangee('Heures enseignées', (m) => `${Math.round(m.heuresEnseignees.p50)} h`);
rangee('Minutes visio (participant)', (m) => m.minutesParticipant.p50.toLocaleString('fr-FR'));
rangee('Plaintes', (m) => `${m.plaintes.p50}`);
rangee('Départs', (m) => `${m.departs.p50}`);

ecrire(
  '',
  '## Taux horaire enseignant maximal',
  '',
  'Prudent : la marge est tenue 9 mois sur 10. Médian : 1 mois sur 2.',
  '',
  ligne(['Marge visée', ...titres]),
  ligne(['---', ...codes.map(() => '---:')]),
);
for (const [i, { marge }] of ref.tauxEnseignantMax.entries()) {
  ecrire(ligne([pct(marge), ...codes.map((c) => {
    const t = resultats[c].tauxEnseignantMax[i];
    return `${usd2(t.prudent)} / h (méd. ${usd2(t.median)})`;
  })]));
}

const tauxRef = ref.tauxEnseignantMax.find((x) => x.marge === 0.3)?.prudent ?? 0;
const heuresEnseignant = pop.enseignants.map((x) => x.heuresParMois);
ecrire(
  '',
  `À ${usd2(tauxRef)} / h (marge 30 %, scénario réaliste prudent), un enseignant à deux groupes gagne entre ` +
    `${usd(Math.min(...heuresEnseignant) * tauxRef)} et ${usd(Math.max(...heuresEnseignant) * tauxRef)} par mois.`,
  '',
  '## Trajectoire réaliste sur 12 mois (médiane)',
  '',
  ligne(['Mois', ...ref.trajectoire.map((x) => x.mois)]),
  ligne(['---', ...ref.trajectoire.map(() => '---:')]),
  ligne(['Élèves', ...ref.trajectoire.map((x) => x.elevesActifsP50)]),
  ligne(['Encaissé', ...ref.trajectoire.map((x) => usd(x.encaisseP50))]),
);

console.log(sortie.join('\n'));
