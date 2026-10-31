// Met a jour la ligne d'un parcours dans docs/current/ETAT-OUVERTURE.md a
// partir de docs/current/captures/E2E/parcours-<n>/verdict.json.
// Usage : node tool/e2e/etat.mjs <n> [cause complementaire]
import fs from 'node:fs';
import path from 'node:path';

const DEPOT = path.resolve(new URL('../..', import.meta.url).pathname);
const n = process.argv[2];
const complement = process.argv[3] ?? '';
const dossier = `docs/current/captures/E2E/parcours-${n}`;
const v = JSON.parse(fs.readFileSync(path.join(DEPOT, dossier, 'verdict.json'), 'utf8'));
const fichier = path.join(DEPOT, 'docs/current/ETAT-OUVERTURE.md');
const lignes = fs.readFileSync(fichier, 'utf8').split('\n');
const i = lignes.findIndex((l) => l.startsWith(`| ${n} |`));
if (i < 0) throw new Error(`ligne du parcours ${n} introuvable`);
const cellules = lignes[i].split('|').map((c) => c.trim());
// | # | Parcours | Test | Cause | Dernier passage | Captures |
const nett = (s) => s.replace(/\|/g, '/').replace(/\s+/g, ' ').trim();
cellules[3] = v.verdict === 'vert' ? 'vert (local)' : 'rouge (local)';
cellules[4] = nett([v.verdict === 'vert' ? '' : v.cause, complement].filter(Boolean).join(' ; '));
cellules[5] = `${v.fin.slice(0, 16).replace('T', ' ')} UTC`;
cellules[6] = `[parcours-${n}](captures/E2E/parcours-${n}/)`;
lignes[i] = `| ${cellules.slice(1, 7).join(' | ')} |`;
fs.writeFileSync(fichier, lignes.join('\n'));
console.log(lignes[i]);
