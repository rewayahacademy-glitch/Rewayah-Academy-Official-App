// WEB-BUREAU (PLAN-LOTS 22 n, directeur, 06/11/2026 vers 14:05 UTC) : la
// LISTE COMPLETE des routes, par role, a 1440 et a 390, chaque ligne verte ou
// rouge. Lit le rapport du robot `fil_ariane.mjs` (avec E2E_FIL_MESURER_BUREAU)
// et ecrit `liste.md` a cote. « Fait » = 100 % de lignes vertes, ou chaque
// exception justifiee par ecrit (DEFINITION-PAGE-ORDINATEUR-2026-11-06.md §3).
//
// Une ligne est verte quand :
//   - a 390 et a 1440, un geste visible ramene ailleurs (ou la page est la
//     racine du role, ou une exception ecrite) ;
//   - a 1440, B1 : la barre laterale est dessinee (sauf exception ecrite) ;
//   - a 1440, B3 : le fil est la sur une page de niveau 2 ou plus ;
//   - a 1440, B5 : aucun bouton de plus de 640 px.
// B4, B6 et B7 (lecture, tete, pied) sont mesures par le garde-fou Flutter.
//
// Usage : node tool/e2e/liste_web_bureau.mjs <dossier du rapport>
import fs from 'node:fs';
import path from 'node:path';

const dossier = process.argv[2];
const rapport = JSON.parse(fs.readFileSync(path.join(dossier, 'rapport.json'), 'utf8'));

// Les destinations de premier niveau de chaque coquille (`destinationsPour`,
// `domainesAdmin`) : une page qui en est une n'a pas besoin de fil (B3).
const RACINES = new Set([
  '/tuteur', '/tuteur/foyer', '/tuteur/suivi', '/tuteur/compte',
  '/eleve', '/eleve/suivi', '/eleve/coran', '/compte',
  '/enseignant/journee', '/enseignant/classes', '/enseignant/creneaux', '/enseignant/profil',
  '/controleur', '/controleur/historique', '/controleur/echanges',
  '/comptable', '/comptable/paiements', '/comptable/tresorerie',
  '/admin', '/admin/operations', '/admin/personnes', '/admin/pedagogie', '/admin/finance',
  '/admin/configuration', '/admin/securite-audit',
]);
// Exceptions ecrites de la definition (§3) : pages d'entree, salle, porte MFA.
const SANS_BARRE = /^\/(|connexion.*|commencer|bienvenue|inscription.*|attente.*|juridique.*|avis\/.*|acces-refuse|hors-ligne|agent|salle|controleur\/mfa)$/;
const normal = (c) => c.replace(/[0-9a-f]{8}-[0-9a-f-]{27}/g, ':id');

const lignes = new Map();
for (const j of rapport.joues) {
  const cle = `${j.role} ${j.route}`;
  const l = lignes.get(cle) ?? { role: j.role, route: j.route };
  if (j.largeur >= 1200) {
    l.obtenu = j.obtenu;
    l.sortie1440 = j.geste;
    l.b1 = j.bureau?.barreLaterale;
    l.b3 = j.bureau?.filPresent;
    l.b5 = j.bureau?.boutonsEtires;
  } else {
    l.sortie390 = j.geste;
  }
  lignes.set(cle, l);
}

const ok = (g) => g !== null && g !== undefined;
const verdicts = [];
for (const l of lignes.values()) {
  const exception = SANS_BARRE.test(l.obtenu ?? '') || l.role === 'visiteur';
  const niveau2 = !RACINES.has(l.obtenu ?? '') && !exception && l.sortie1440 !== 'racine';
  const raisons = [];
  if (!ok(l.sortie1440)) raisons.push('sans sortie a 1440');
  if (l.sortie390 !== undefined && !ok(l.sortie390)) raisons.push('sans sortie a 390');
  if (!exception && l.b1 === false) raisons.push('B1 pas de barre laterale');
  if (niveau2 && l.b3 === false) raisons.push('B3 pas de fil');
  if ((l.b5 ?? 0) > 0) raisons.push(`B5 ${l.b5} bouton(s) etire(s)`);
  verdicts.push({ ...l, exception, vert: raisons.length === 0, raisons });
}
verdicts.sort((a, b) => a.role.localeCompare(b.role) || a.route.localeCompare(b.route));

const vertes = verdicts.filter((v) => v.vert).length;
let md = `# Liste WEB-BUREAU : ${vertes} / ${verdicts.length} lignes vertes\n\n`;
md += `Rapport : \`${path.relative(process.cwd(), path.join(dossier, 'rapport.json'))}\` (${rapport.debut}).\n`;
md += 'B1 barre laterale, B3 fil, B5 boutons etires : definition `docs/current/DEFINITION-PAGE-ORDINATEUR-2026-11-06.md`.\n';
md += 'B4, B6, B7 (lecture, tete, pied) : mesures par le garde-fou Flutter, pas encore ici.\n\n';
const roles = [...new Set(verdicts.map((v) => v.role))];
md += '| Role | Lignes | Vertes |\n|---|---|---|\n';
for (const r of roles) {
  const d = verdicts.filter((v) => v.role === r);
  md += `| ${r} | ${d.length} | ${d.filter((v) => v.vert).length} |\n`;
}
for (const r of roles) {
  md += `\n## ${r}\n\n| Route | Obtenue a 1440 | Sortie 1440 | Sortie 390 | B1 | B3 | B5 | Verdict |\n|---|---|---|---|---|---|---|---|\n`;
  for (const v of verdicts.filter((x) => x.role === r)) {
    const b = (x) => (x === undefined ? '-' : x ? 'oui' : 'non');
    md += `| \`${v.route}\` | \`${normal(v.obtenu ?? '-')}\` | ${v.sortie1440 ?? 'AUCUNE'} | ${v.sortie390 === undefined ? '-' : v.sortie390 ?? 'AUCUNE'} | ${v.exception ? 'exception' : b(v.b1)} | ${b(v.b3)} | ${v.b5 ?? '-'} | ${v.vert ? 'vert' : `**rouge** : ${v.raisons.join(', ')}`} |\n`;
  }
}
fs.writeFileSync(path.join(dossier, 'liste.md'), md);
fs.writeFileSync(path.join(dossier, 'liste.json'), JSON.stringify(verdicts, null, 1));
console.log(`${vertes} / ${verdicts.length} lignes vertes`);
