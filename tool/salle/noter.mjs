// Banc de la salle : note (ou note de nouveau) les enregistrements d'un dossier
// de mesure deja fait par `mesure_voix.mjs`, et ecrit `<sens>.json` complete.
// Usage : node tool/salle/noter.mjs <dossier> [<dossier>...]
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const PYTHON = process.env.BANC_PYTHON ?? '/opt/banc-audio/venv/bin/python';
const RECITATION = process.env.BANC_RECITATION ?? '/opt/banc-audio/ref/recitation.wav';

for (const dossier of process.argv.slice(2)) {
  for (const f of fs.readdirSync(dossier).filter((x) => /^(ens-eleve|eleve-ens).*\.json$/.test(x))) {
    const chemin = path.join(dossier, f);
    const mesure = JSON.parse(fs.readFileSync(chemin, 'utf8'));
    const lignes = mesure.resultats.filter((r) => r.fichier && fs.existsSync(r.fichier));
    if (!lignes.length) continue;
    const notes = execFileSync(PYTHON, [path.join(import.meta.dirname, 'mesure_audio.py'), RECITATION, ...lignes.map((r) => r.fichier)],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 1 << 26 }).trim().split('\n').map((l) => JSON.parse(l));
    for (const r of lignes) {
      const n = notes.find((x) => x.fichier === r.fichier) ?? {};
      Object.assign(r, { estoi: n.estoi, estoi_pire: n.estoi_pire, trous: n.trous, wer: n.wer, mots: n.mots_original, erreur: n.erreur });
      console.log(`${mesure.etiquette} ${mesure.sens}${mesure.camera ? ' camera' : ''}${mesure.tampon ? ` tampon${mesure.tampon}` : ''} ${r.profil} : mots perdus ou changes ${n.wer} ; ESTOI ${n.estoi} (pire ${n.estoi_pire}) ; trous ${n.trous} ; son reconstruit ${r.audio?.[0]?.dissimule} ; pertes ${r.audio?.[0]?.pertes} ; debit ${r.audio?.[0]?.debitKbps} kbit/s ; video ${r.video || '-'}`);
    }
    fs.writeFileSync(chemin, JSON.stringify(mesure, null, 1));
  }
}
