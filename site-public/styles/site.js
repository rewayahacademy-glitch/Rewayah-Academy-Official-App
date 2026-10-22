/*
 * Simulateur de tarif.
 * Aucune valeur de tarif ici : tout vient des donnees injectees au build dans
 * <script type="application/json" id="tarifs-data">. Les calculs sont des
 * entiers en unite mineure (centimes), arrondis au demi vers le haut comme
 * le serveur ; aucun nombre a virgule n'est multiplie.
 */

// Arrondi au demi vers le haut de (a / b), a et b entiers positifs.
function diviserArrondi(a, b) {
  return Math.floor((2 * a + b) / (2 * b));
}

function tarifDe(d, age) {
  return age < d.ageAdulte ? d.enfant : d.adulte;
}

// Prix d'un mois pour l'eleve de ce rang dans le foyer (remise de rang).
function prixDuRang(d, tarif, rang) {
  let applicable = null;
  d.remises.forEach((r) => { if (rang >= r.aPartirDuRang) applicable = r; });
  if (!applicable) return tarif;
  if (applicable.pourMille !== undefined) return diviserArrondi(tarif * (d.echelle - applicable.pourMille), d.echelle);
  return Math.max(0, tarif + applicable.montantMineur);
}

function periode(d, paiement) {
  const formule = paiement === 'mensuel' ? null : d.prepaiement[paiement];
  return formule && formule.pourMille ? formule : null;
}

/*
 * eleves : liste ordonnee (ordre d'inscription) de { age, bourse }.
 * options : { paiement: 'mensuel' | 'trimestre' | 'annee', parrainage: bool }.
 */
function calculer(d, eleves, options) {
  const opt = options || {};
  const pre = periode(d, opt.paiement || 'mensuel');
  const n = pre ? pre.mois : 1;
  const lignes = [];
  let total = 0;
  let marge = 0;
  eleves.forEach((el, i) => {
    const rang = i + 1;
    const tarif = tarifDe(d, el.age);
    const base = tarif * n;
    if (el.bourse && d.bourse) {
      const bourse = diviserArrondi(tarif * d.bourse.pourMille, d.echelle) * n;
      lignes.push({ rang, age: el.age, adulte: tarif === d.adulte && el.age >= d.ageAdulte, base, foyer: 0, prepaiement: 0, bourse, plafond: 0, total: base - bourse });
      total += base - bourse;
      return;
    }
    const foyer = (tarif - prixDuRang(d, tarif, rang)) * n;
    const prep = pre ? diviserArrondi(base * pre.pourMille, d.echelle) : 0;
    let remise = foyer + prep;
    const plafondMax = d.cumulMax === null ? null : Math.floor(base * d.cumulMax / d.echelle);
    let ajust = 0;
    if (plafondMax !== null && remise > plafondMax) {
      ajust = remise - plafondMax;
      remise = plafondMax;
    }
    let du = base - remise;
    if (n > 1) du = Math.floor((2 * du + d.unite) / (2 * d.unite)) * d.unite;
    lignes.push({ rang, age: el.age, adulte: el.age >= d.ageAdulte, base, foyer, prepaiement: prep, bourse: 0, plafond: ajust, total: du });
    total += du;
    if (plafondMax !== null) marge += Math.max(0, plafondMax - remise);
  });
  let credit = 0;
  const eligible = eleves.some((el) => !(el.bourse && d.bourse));
  if (opt.parrainage && d.parrainageCredit && eligible) {
    credit = d.cumulMax === null ? d.parrainageCredit : Math.min(d.parrainageCredit, marge);
  }
  return {
    mois: n,
    lignes,
    credit,
    creditDemande: opt.parrainage && eligible ? d.parrainageCredit : 0,
    totalSansCredit: total,
    totalPeriode: total - credit,
    parMois: n > 1 ? diviserArrondi(total - credit, n) : total - credit,
    parMoisSansCredit: n > 1 ? diviserArrondi(total, n) : total,
  };
}

// Le rang suit l'ordre d'inscription : on donne la fourchette entre l'ordre le
// plus favorable et le moins favorable, pour les eleves de prix differents.
function fourchette(d, eleves, options) {
  const prix = (el) => tarifDe(d, el.age);
  const croissant = eleves.slice().sort((a, b) => prix(a) - prix(b));
  const decroissant = eleves.slice().sort((a, b) => prix(b) - prix(a));
  const totaux = [eleves, croissant, decroissant].map((liste) => calculer(d, liste, options).totalPeriode);
  return { min: Math.min(...totaux), max: Math.max(...totaux) };
}

function formaterMontant(d, mineur) {
  const signe = mineur < 0 ? '-' : '';
  const abs = Math.abs(mineur);
  const entier = Math.floor(abs / d.unite);
  const reste = abs % d.unite;
  const largeur = String(d.unite).length - 1;
  const texte = String(entier).replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + (reste ? ',' + String(reste).padStart(largeur, '0') : '');
  return signe + texte + ' ' + d.symbole;
}

function formaterPourMille(d, pm) {
  const parPourcent = d.echelle / d.pourcent;
  const entier = Math.floor(pm / parPourcent);
  const reste = pm % parPourcent;
  return entier + (reste ? ',' + String(reste) : '') + '\u00a0%';
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { calculer, fourchette, formaterMontant, diviserArrondi };
}

if (typeof document !== 'undefined') {
  const simulator = document.getElementById('tarif-simulator');
  const dataNode = document.getElementById('tarifs-data');
  let donnees = null;
  try {
    donnees = dataNode ? JSON.parse(dataNode.textContent) : null;
  } catch (erreur) {
    donnees = null;
  }
  if (simulator) initialiserSimulateur(simulator, donnees);
}

function initialiserSimulateur(simulator, d) {
  let opener;
  const total = simulator.querySelector('#sim-total');
  const students = simulator.querySelector('#sim-students');
  const paiement = simulator.querySelector('#sim-paiement');
  const parrainage = simulator.querySelector('#sim-parrainage');
  const result = simulator.querySelector('#sim-result');

  function ouvrir() {
    // Sur la page des tarifs, le simulateur est pose dans la page : rien a ouvrir.
    if (simulator.tagName !== 'DIALOG') return;
    document.querySelectorAll('[data-open-simulator]').forEach((button) => {
      button.addEventListener('click', () => {
        opener = button;
        simulator.showModal();
        total.focus();
      });
    });
    simulator.addEventListener('close', () => opener && opener.focus());
    simulator.addEventListener('click', (event) => {
      const bounds = simulator.getBoundingClientRect();
      if (event.target === simulator && (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom)) simulator.close();
    });
  }

  if (!d) {
    result.textContent = 'Le calcul est momentanément indisponible. Réessayez dans un instant.';
    ouvrir();
    return;
  }

  total.max = String(d.elevesMax);
  [['mensuel', 'Chaque mois'], ['trimestre', 'Au trimestre'], ['annee', 'À l’année']].forEach(([valeur, libelle]) => {
    const formule = valeur === 'mensuel' ? null : d.prepaiement[valeur];
    if (valeur !== 'mensuel' && !(formule && formule.pourMille)) return;
    const option = document.createElement('option');
    option.value = valeur;
    option.textContent = formule ? libelle + ' (remise de ' + formaterPourMille(d, formule.pourMille) + ')' : libelle;
    paiement.appendChild(option);
  });
  if (!d.parrainageCredit) parrainage.closest('label').hidden = true;

  function el(tag, text, attrs) {
    const node = document.createElement(tag);
    if (text !== undefined) node.textContent = text;
    Object.keys(attrs || {}).forEach((k) => node.setAttribute(k, attrs[k]));
    return node;
  }

  function synchroniserLignes() {
    const voulu = Math.min(Math.max(parseInt(total.value, 10) || 0, 0), d.elevesMax);
    while (students.children.length > voulu * (d.bourse ? 2 : 1)) students.removeChild(students.lastChild);
    for (let i = students.children.length / (d.bourse ? 2 : 1); i < voulu; i += 1) {
      // Le libelle nomme le champ par son id ; les boutons moins et plus sont a cote de lui, hors du libelle.
      const age = el('div', undefined, { class: 'simulator__champ' });
      age.appendChild(el('label', 'Âge de l’élève ' + (i + 1), { for: 'sim-age-' + (i + 1) }));
      const champ = el('input', undefined, { type: 'number', inputmode: 'numeric', min: String(d.ageEnfantMin), step: '1', placeholder: 'Par exemple ' + (d.ageEnfantMin + 2), 'data-age': '', id: 'sim-age-' + (i + 1) });
      // Le premier eleve part d'un exemple, pour que le calcul se lise tout de suite ; on le change en un geste.
      if (i === 0) champ.value = String(d.ageEnfantMin + 2);
      champ.addEventListener('input', calculerEtAfficher);
      // L'age se regle aussi aux boutons moins et plus, comme le nombre d'eleves.
      const pas = el('span', undefined, { class: 'pas' });
      [['-1', 'Un an de moins'], ['1', 'Un an de plus']].forEach(([sens, libelle], j) => {
        const bouton = el('button', j ? '+' : '−', { type: 'button', 'data-pas-age': sens, 'aria-label': libelle + ', élève ' + (i + 1) });
        bouton.addEventListener('click', (evenement) => {
          evenement.preventDefault();
          const actuel = parseInt(champ.value, 10);
          champ.value = String(Number.isNaN(actuel) ? d.ageEnfantMin : Math.max(actuel + Number(sens), d.ageEnfantMin));
          champ.dispatchEvent(new Event('input'));
        });
        if (j) pas.append(champ, bouton); else pas.append(bouton);
      });
      age.appendChild(pas);
      students.appendChild(age);
      if (d.bourse) {
        const bourse = el('label', 'Bourse, élève ' + (i + 1) + ' ');
        const case_ = el('input', undefined, { type: 'checkbox', 'data-bourse': '' });
        case_.addEventListener('change', calculerEtAfficher);
        bourse.appendChild(case_);
        students.appendChild(bourse);
      }
    }
  }

  function lire() {
    const nombre = Number(total.value);
    if (total.value === '' || !Number.isSafeInteger(nombre) || nombre < 1 || nombre > d.elevesMax) {
      return { erreur: 'Indiquez un nombre d’élèves entier, de 1 à ' + d.elevesMax + '.' };
    }
    const eleves = [];
    const ages = students.querySelectorAll('[data-age]');
    const bourses = students.querySelectorAll('[data-bourse]');
    for (let i = 0; i < nombre; i += 1) {
      const brut = ages[i] ? ages[i].value : '';
      const age = Number(brut);
      if (brut === '' || !Number.isSafeInteger(age) || age < d.ageEnfantMin) {
        return { erreur: 'Indiquez l’âge de l’élève ' + (i + 1) + ', à partir de ' + d.ageEnfantMin + ' ans.', ageVide: brut === '' };
      }
      eleves.push({ age, bourse: Boolean(bourses[i] && bourses[i].checked) });
    }
    return { eleves };
  }

  function ligneTexte(parent, texte) {
    parent.appendChild(el('p', texte));
  }

  function afficher(eleves) {
    const options = { paiement: paiement.value, parrainage: parrainage.checked };
    const r = calculer(d, eleves, options);
    const m = (x) => formaterMontant(d, x);
    result.replaceChildren();
    // Le total d'abord, en grand : c'est la reponse. Le detail par eleve vient dessous, une ligne par eleve.
    const pour = eleves.length > 1 ? ' pour ' + eleves.length + ' élèves' : '';
    const fort = el('p', (r.mois > 1 ? m(r.totalPeriode) : m(r.totalSansCredit)) + ' ', { class: 'simulator__prix simulator__total' });
    fort.appendChild(el('small', r.mois > 1 ? 'à payer d’avance pour ' + r.mois + ' mois' + pour + ', hors taxes' : 'par mois' + pour + ', hors taxes'));
    result.appendChild(fort);
    if (r.mois > 1) ligneTexte(result, 'Soit environ ' + m(r.parMois) + ' par mois (arrondi au centime).');
    if (r.credit && r.mois === 1) ligneTexte(result, 'Premier paiement, crédit de parrainage déduit : ' + m(r.totalPeriode) + '. Ensuite ' + m(r.totalSansCredit) + ' par mois.');
    result.appendChild(el('p', r.mois > 1 ? 'Détail par élève, pour ' + r.mois + ' mois' : 'Détail par élève, pour un mois', { class: 'simulator__legende' }));
    const liste = el('ul', undefined, { class: 'simulator__eleves' });
    r.lignes.forEach((l) => {
      const li = el('li');
      li.appendChild(el('span', 'Élève ' + l.rang + ' · ' + l.age + ' ans · ' + (l.adulte ? 'adulte' : 'enfant'), { class: 'simulator__eleve' }));
      const details = [];
      if (l.foyer) details.push('remise foyer ' + m(-l.foyer));
      if (l.prepaiement) details.push('paiement d’avance ' + m(-l.prepaiement));
      if (l.plafond) details.push('plafond : ' + m(l.plafond) + ' non appliqués');
      if (l.bourse) details.push('bourse ' + m(-l.bourse) + ' (ne se cumule pas)');
      li.appendChild(el('span', 'Prix ' + m(l.base) + ' · ' + (details.length ? details.join(', ') : 'aucune remise'), { class: 'simulator__calcul' }));
      const du = el('strong');
      du.append(el('span', 'À payer : ', { class: 'sr-only' }), m(l.total));
      li.appendChild(du);
      liste.appendChild(li);
    });
    result.appendChild(liste);
    if (r.credit || r.creditDemande) {
      const limite = r.credit < r.creditDemande ? ' Le plafond de cumul limite ce crédit à ' + m(r.credit) + '.' : '';
      ligneTexte(result, 'Crédit de parrainage : ' + m(-r.credit) + ' sur le premier paiement.' + limite);
    }
    const prix = new Set(eleves.map((e) => tarifDe(d, e.age)));
    if (eleves.length > 1 && prix.size > 1) {
      const f = fourchette(d, eleves, options);
      if (f.min !== f.max) ligneTexte(result, 'Les remises suivent l’ordre d’inscription dans le foyer. Selon cet ordre, le premier paiement est compris entre ' + m(f.min) + ' et ' + m(f.max) + '.');
    }
    if (d.bourse) ligneTexte(result, 'La bourse est accordée par la direction, sur demande écrite, et ne se cumule avec aucune autre remise.');
    if (!d.essaiActif) ligneTexte(result, 'Il n’y a pas d’essai\u00a0: la première semaine est remboursée si le cours ne\u00a0convient\u00a0pas.');
  }

  // Tant qu'un age manque, le prix publie s'affiche en grand, avec la consigne dessous.
  function afficherRepere(consigne) {
    result.replaceChildren();
    const prix = el('p', formaterMontant(d, d.enfant) + ' ', { class: 'simulator__prix' });
    prix.appendChild(el('small', 'par mois et par enfant, hors taxes'));
    result.appendChild(prix);
    ligneTexte(result, formaterMontant(d, d.adulte) + ' par mois pour un adulte, dès ' + d.ageAdulte + ' ans. ' + consigne);
  }

  function calculerEtAfficher() {
    const lecture = lire();
    if (lecture.erreur) {
      if (lecture.ageVide) afficherRepere(lecture.erreur);
      else result.textContent = lecture.erreur;
      return;
    }
    afficher(lecture.eleves);
  }

  total.addEventListener('input', () => { synchroniserLignes(); calculerEtAfficher(); });
  simulator.querySelectorAll('[data-pas]').forEach((bouton) => bouton.addEventListener('click', (evenement) => {
    evenement.preventDefault();
    const actuel = parseInt(total.value, 10) || 0;
    total.value = String(Math.min(Math.max(actuel + Number(bouton.dataset.pas), 1), d.elevesMax));
    total.dispatchEvent(new Event('input'));
  }));
  paiement.addEventListener('change', calculerEtAfficher);
  parrainage.addEventListener('change', calculerEtAfficher);
  synchroniserLignes();
  calculerEtAfficher();
  ouvrir();
}
