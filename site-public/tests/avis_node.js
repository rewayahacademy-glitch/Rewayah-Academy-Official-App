// Lit { cas } sur l'entree standard : pour chaque reponse, ce que avis.js en fait (valide ou non, signature).
// Utilise le vrai styles/avis.js.
const fs = require('fs');
const path = require('path');
const avis = require(path.join(__dirname, '..', 'styles', 'avis.js'));
const { cas } = JSON.parse(fs.readFileSync(0, 'utf8'));
process.stdout.write(JSON.stringify(cas.map((c) => {
  const v = avis.valider(c);
  return { valide: v !== null, signature: v ? avis.signature(v) : null };
})));
