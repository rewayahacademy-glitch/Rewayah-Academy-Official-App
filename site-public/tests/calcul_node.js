// Lit { donnees, cas } sur l'entree standard, rend un tableau de resultats.
// Utilise le vrai styles/site.js (aucune copie du calcul).
const fs = require('fs');
const path = require('path');
const sim = require(path.join(__dirname, '..', 'styles', 'site.js'));

const { donnees, cas } = JSON.parse(fs.readFileSync(0, 'utf8'));
const sortie = cas.map((c) => {
  if (c.montant !== undefined) return { texte: sim.formaterMontant(donnees, c.montant) };
  const options = { paiement: c.paiement, parrainage: c.parrainage };
  if (c.fourchette) return sim.fourchette(donnees, c.eleves, options);
  return sim.calculer(donnees, c.eleves, options);
});
process.stdout.write(JSON.stringify(sortie));
