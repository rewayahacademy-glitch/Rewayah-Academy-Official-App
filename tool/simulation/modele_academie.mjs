// Modèle économique de Rewayah Academy — simulation de Monte-Carlo.
//
// Une population fixe (élèves, foyers, groupes, enseignants) est générée
// une fois à partir d'une graine. Chaque tirage rejoue ensuite douze mois de
// comportements : paiements (en avance, à l'heure, en retard, impayés),
// absences, séances annulées, plaintes, départs et remplacements.
//
// Tout montant est un entier en centimes de dollar (règle transverse du
// dépôt : jamais de float sur de l'argent). Les taux sont en points de base
// (150 bps = 1,5 %). Les seules valeurs flottantes sont des probabilités.
//
// Ce fichier n'a aucune dépendance : il tourne sous Node (`simuler.mjs`,
// tests) et tel quel dans le navigateur (tableau interactif).

export const VERSION_MODELE = 2;

// ---------------------------------------------------------------------------
// Paramètres
// ---------------------------------------------------------------------------

export const PARAMETRES_DEFAUT = Object.freeze({
  graine: 20261017,
  tirages: 1000,
  mois: 12,
  // Les premiers mois portent l'effet de démarrage (aucun retard reporté,
  // aucun remplacement) : le « mois type » se lit à partir de celui-ci.
  premierMoisStable: 3,

  effectif: {
    eleves: 100,
    partEnfants: 0.45,
    partFeminin: 0.5,
    // Tranches d'âge de af_l2_08 (âge minimal 6 ans) ; ≤ 17 ans = public enfant.
    tranchesEnfant: { '6-9': 0.35, '10-13': 0.4, '14-17': 0.25 },
    // Nombre d'enfants inscrits par foyer.
    taillesFratrie: { 1: 0.3, 2: 0.35, 3: 0.2, 4: 0.1, 5: 0.05 },
    // Part des adultes inscrits dans le foyer de leurs enfants (la remise
    // familiale compte toutes les personnes du foyer, enfants et adultes).
    partAdultesAvecEnfants: 0.15,
    // Part des adultes restants inscrits à deux dans le même foyer.
    partAdultesEnCouple: 0.1,
  },

  // Tarifs fixés par l'opérateur le 17 octobre 2026.
  tarifs: {
    enfantCentimes: 5000,
    adulteCentimes: 6000,
    // 1re et 2e personne : aucune remise. 3e : 5 $. 4e et suivantes : 7 $
    // chacune (la 3e garde ses 5 $).
    remiseTroisiemeCentimes: 500,
    remiseQuatriemeEtPlusCentimes: 700,
  },

  rythme: {
    seancesParSemaine: 3,
    minutesEnfant: 60,
    minutesAdulte: 90,
    probabiliteAnnulation: 0.02,
  },

  // Directeur, 17/10/2026 : 5 enfants (parfois 4), 6 adultes (parfois 5), un
  // enseignant pour deux classes. Un élève qui ne tient dans aucune classe
  // attend une place et ne paie pas.
  groupes: {
    maxEnfants: 5,
    minEnfants: 4,
    maxAdultes: 6,
    minAdultes: 5,
    groupesParEnseignant: 2,
    // 'separes' : classes d'hommes et de femmes (genre_public), enseignant du
    // même sexe. 'separes-des-10-ans' : enfants mixtes jusqu'à 9 ans seulement.
    mixiteAdultes: 'separes',
    mixiteEnfants: 'mixte',
  },

  // Directeur, 17/10/2026 : compter 5 personnes à 300 $ par mois.
  administration: {
    effectif: 5,
    salaireMensuelCentimes: 30000,
    // Temps de travail estimé par événement, pour mesurer la charge de
    // l'équipe (ne change pas sa paie, qui est fixe).
    minutesParEvenement: {
      relance: 10, plainte: 15, changement: 30, changementRefuse: 15, depart: 20, arrivee: 45,
    },
  },

  comportements: {
    // Par foyer payeur. dansLeMois + moisSuivant + impaye = 1.
    paiement: {
      avance: { poids: 0.15, dansLeMois: 1, moisSuivant: 0, impaye: 0 },
      ponctuel: { poids: 0.45, dansLeMois: 0.97, moisSuivant: 0.03, impaye: 0 },
      retardLeger: { poids: 0.2, dansLeMois: 0.85, moisSuivant: 0.15, impaye: 0 },
      retardLourd: { poids: 0.12, dansLeMois: 0.3, moisSuivant: 0.65, impaye: 0.05 },
      defaillant: { poids: 0.08, dansLeMois: 0.3, moisSuivant: 0.2, impaye: 0.5 },
    },
    // Par élève.
    disponibilite: {
      occupe: { poids: 0.4, absence: 0.25, departMensuel: 0.03 },
      disponible: { poids: 0.6, absence: 0.08, departMensuel: 0.01 },
    },
    plaintes: {
      jamais: { poids: 0.5, parMois: 0, departMensuel: 0 },
      parfois: { poids: 0.35, parMois: 0.3, departMensuel: 0.005 },
      souvent: { poids: 0.15, parMois: 1.5, departMensuel: 0.03 },
    },
    moisImpayesAvantSuspension: 2,
    // Une place libérée est reprise par un nouvel inscrit après ce délai.
    // `null` : aucune nouvelle inscription.
    delaiRemplacementMois: 1,
    // Instabilité : demandes de changement de classe ou de créneau. Un élève
    // qui change libère sa place ; s'il n'y a aucune place dans une autre
    // classe de sa catégorie, la demande est refusée et il part parfois.
    changementMensuel: 0.02,
    departSiRefus: 0.3,
    multiplicateurDeparts: 1,
  },

  // Élèves perdus pour de bon, sans remplacement. `regrouper` : les classes
  // sont refaites avec les élèves restants (moins de classes et d'heures
  // payées) ; sinon les places restent vides.
  pertes: { enfants: 0, adultes: 0, regrouper: false },

  // Encaissement par carte : l'académie est une société britannique, donc
  // grille Stripe Royaume-Uni (1,5 % carte britannique, 2,5 % carte de l'EEE,
  // 3,25 % carte internationale, plus 20 p). Une carte américaine ou
  // canadienne est internationale.
  paiementEnLigne: {
    origineCartes: { eee: 0.425, royaumeUni: 0.075, international: 0.5 },
    bps: { eee: 250, royaumeUni: 150, international: 325 },
    fixeCentimes: 27, // 20 p convertis en dollars
    conversionBps: 200, // prix en USD, compte réglé en GBP
  },

  // Taux de référence 4 $/h, configurable et daté (docs/current/07 §26) ;
  // plafond 7 $/h de la politique de démonstration.
  enseignants: {
    tauxReferenceCentimes: 400,
    plafondCentimes: 700,
    fraisVirementBps: 200,
    fraisVirementFixeCentimes: 100,
  },

  // Objectif de l'académie : 2 000 $ net par mois (docs/current/07 §27),
  // compté après administration et impôt.
  objectifs: { resultatNetCentimes: 200000, marges: [0.3, 0.35, 0.4] },

  // Directeur, 17/10/2026 : académie enregistrée au Royaume-Uni, impôt sur
  // les bénéfices seulement ; les prix publiés s'entendent hors taxes, que
  // chaque famille ajoute. Impôt sur les sociétés 2026-27 : 19 % jusqu'à
  // 50 000 £ de bénéfice annuel, 25 % au-delà de 250 000 £, allègement
  // dégressif entre les deux (25 % moins 3/200 de l'écart au seuil haut).
  fiscalite: {
    impotSocietes: {
      tauxReduitBps: 1900, tauxNormalBps: 2500,
      seuilBasLivres: 50000, seuilHautLivres: 250000,
      allegementNumerateur: 3, allegementDenominateur: 200,
    },
    centimesParLivre: 133, // 1 £ ≈ 1,33 $, à mettre à jour
  },

  services: [
    { nom: 'Supabase Pro', centimes: 2500 },
    { nom: 'Supabase staging (calcul Micro)', centimes: 1000 },
    { nom: 'Vercel Pro (1 siège)', centimes: 2000 },
    { nom: 'GitHub + Actions', centimes: 0 },
    { nom: 'Sentry (Developer)', centimes: 0 },
    { nom: 'Email transactionnel', centimes: 0 },
    { nom: 'Nom de domaine', centimes: 125 },
    { nom: 'Compte bancaire pro', centimes: 1000 },
  ],

  livekit: {
    forfaitCentimes: 5000, // palier Ship
    minutesIncluses: 150000,
    surcoutCentimesPar1000Minutes: 50, // 0,0005 $ la minute
    goIncluses: 250,
    surcoutCentimesParGo: 12,
    // Débit descendant moyen par participant : audio Opus + vidéo simulcast
    // basse (ADR-001), caméra enfant parfois interdite (ADR-009).
    debitDescendantKbps: 700,
  },

  r2: {
    enregistrementAudio: false,
    moParHeureEleve: 11,
    goGratuits: 10,
    centimesPar100Go: 150, // 0,015 $ le Go-mois
  },
});

export const SCENARIOS = Object.freeze({
  ideal: {
    titre: 'Idéal',
    description: 'Tout le monde paie à l’heure, personne ne part ni ne s’absente.',
    surcharges: {
      comportements: {
        paiement: {
          avance: { poids: 0 }, ponctuel: { poids: 1, dansLeMois: 1, moisSuivant: 0, impaye: 0 },
          retardLeger: { poids: 0 }, retardLourd: { poids: 0 }, defaillant: { poids: 0 },
        },
        disponibilite: {
          occupe: { poids: 0 }, disponible: { poids: 1, absence: 0, departMensuel: 0 },
        },
        plaintes: { jamais: { poids: 1 }, parfois: { poids: 0 }, souvent: { poids: 0 } },
        changementMensuel: 0,
      },
      rythme: { probabiliteAnnulation: 0 },
    },
  },
  optimiste: {
    titre: 'Optimiste',
    description: 'Peu de retards, 2 % de mauvais payeurs.',
    surcharges: {
      comportements: {
        paiement: {
          avance: { poids: 0.25 }, ponctuel: { poids: 0.55 }, retardLeger: { poids: 0.12 },
          retardLourd: { poids: 0.06 }, defaillant: { poids: 0.02 },
        },
        plaintes: { jamais: { poids: 0.6 }, parfois: { poids: 0.32 }, souvent: { poids: 0.08 } },
      },
    },
  },
  realiste: { titre: 'Réaliste', description: 'Le mélange de personas par défaut.', surcharges: {} },
  pessimiste: {
    titre: 'Pessimiste',
    description: '40 % de retards lourds ou de mauvais payeurs, plus de plaintes.',
    surcharges: {
      comportements: {
        paiement: {
          avance: { poids: 0.05 }, ponctuel: { poids: 0.3 }, retardLeger: { poids: 0.25 },
          retardLourd: { poids: 0.2 }, defaillant: { poids: 0.2 },
        },
        disponibilite: { occupe: { poids: 0.55 }, disponible: { poids: 0.45 } },
        plaintes: { jamais: { poids: 0.35 }, parfois: { poids: 0.4 }, souvent: { poids: 0.25 } },
      },
    },
  },
});

// Toutes les combinaisons testées : chaque dimension croisée avec toutes les
// autres (4 × 2 × 3 × 3 × 3 = 216 scénarios).
export const DIMENSIONS = Object.freeze({
  paiement: Object.fromEntries(Object.entries(SCENARIOS).map(([code, x]) => [code, { titre: x.titre }])),
  mixiteAdultes: {
    separes: { titre: 'Adultes séparés', surcharges: { groupes: { mixiteAdultes: 'separes' } } },
    mixte: { titre: 'Adultes mixtes', surcharges: { groupes: { mixiteAdultes: 'mixte' } } },
  },
  mixiteEnfants: {
    mixte: { titre: 'Enfants mixtes', surcharges: { groupes: { mixiteEnfants: 'mixte' } } },
    'separes-des-10-ans': { titre: 'Enfants séparés dès 10 ans', surcharges: { groupes: { mixiteEnfants: 'separes-des-10-ans' } } },
    separes: { titre: 'Enfants séparés', surcharges: { groupes: { mixiteEnfants: 'separes' } } },
  },
  origine: {
    europe: { titre: '70 % Europe', surcharges: { paiementEnLigne: { origineCartes: { eee: 0.595, royaumeUni: 0.105, international: 0.3 } } } },
    equilibre: { titre: '50 / 50', surcharges: { paiementEnLigne: { origineCartes: { eee: 0.425, royaumeUni: 0.075, international: 0.5 } } } },
    amerique: { titre: '70 % Amérique du Nord', surcharges: { paiementEnLigne: { origineCartes: { eee: 0.255, royaumeUni: 0.045, international: 0.7 } } } },
  },
  partEnfants: {
    30: { titre: '30 % d’enfants', surcharges: { effectif: { partEnfants: 0.3 } } },
    45: { titre: '45 % d’enfants', surcharges: { effectif: { partEnfants: 0.45 } } },
    60: { titre: '60 % d’enfants', surcharges: { effectif: { partEnfants: 0.6 } } },
  },
});

/** Produit cartésien des dimensions : [{ choix, parametres }]. */
export function grilleScenarios(surcharges = {}) {
  let combinaisons = [{}];
  for (const [dimension, valeurs] of Object.entries(DIMENSIONS)) {
    combinaisons = combinaisons.flatMap((c) => Object.keys(valeurs).map((v) => ({ ...c, [dimension]: v })));
  }
  return combinaisons.map((choix) => {
    let p = parametresScenario(choix.paiement);
    for (const [dimension, valeur] of Object.entries(choix)) {
      if (dimension !== 'paiement') p = fusionner(p, DIMENSIONS[dimension][valeur].surcharges);
    }
    return { choix, parametres: fusionner(p, surcharges) };
  });
}

export function fusionner(base, surcharges) {
  if (surcharges === undefined) return base;
  if (Array.isArray(base) || typeof base !== 'object' || base === null) return surcharges;
  const sortie = { ...base };
  for (const [cle, valeur] of Object.entries(surcharges)) {
    sortie[cle] = cle in base ? fusionner(base[cle], valeur) : valeur;
  }
  return sortie;
}

export function parametresScenario(code, surcharges = {}) {
  return fusionner(fusionner(PARAMETRES_DEFAUT, SCENARIOS[code].surcharges), surcharges);
}

// ---------------------------------------------------------------------------
// Règles métier pures
// ---------------------------------------------------------------------------

/** Mensualité d'un foyer : `membres` liste des 'enfant' | 'adulte'. */
export function mensualiteFoyer(membres, tarifs) {
  let total = 0;
  for (const type of membres) total += type === 'enfant' ? tarifs.enfantCentimes : tarifs.adulteCentimes;
  return total - remiseFamiliale(membres.length, tarifs);
}

export function remiseFamiliale(nombre, tarifs) {
  if (nombre < 3) return 0;
  return tarifs.remiseTroisiemeCentimes + (nombre - 3) * tarifs.remiseQuatriemeEtPlusCentimes;
}

export function seancesParMois(rythme) {
  return Math.round((rythme.seancesParSemaine * 52) / 12);
}

/**
 * Découpe `n` élèves en classes de `min` à `max` places, en plaçant le plus
 * d'élèves possible avec le moins de classes. Le reste attend une place.
 */
export function repartirEnGroupes(n, max, min = 1) {
  for (let places = n; places > 0; places--) {
    const k = Math.ceil(places / max);
    if (places < k * min) continue;
    const base = Math.floor(places / k);
    const reste = places % k;
    return {
      tailles: Array.from({ length: k }, (_, i) => base + (i < reste ? 1 : 0)),
      enAttente: n - places,
    };
  }
  return { tailles: [], enAttente: n };
}

/** Frais d'un paiement par carte, en centimes. */
export function fraisCarte(montantCentimes, origine, paiementEnLigne) {
  const bps = paiementEnLigne.bps[origine] + paiementEnLigne.conversionBps;
  return Math.round((montantCentimes * bps) / 10000) + paiementEnLigne.fixeCentimes;
}

/** Coût LiveKit du mois, en centimes. */
export function coutLivekit(minutesParticipant, go, livekit) {
  const minutesEnPlus = Math.max(0, minutesParticipant - livekit.minutesIncluses);
  const goEnPlus = Math.max(0, Math.ceil(go - livekit.goIncluses));
  return (
    livekit.forfaitCentimes +
    Math.round((minutesEnPlus * livekit.surcoutCentimesPar1000Minutes) / 1000) +
    goEnPlus * livekit.surcoutCentimesParGo
  );
}

export function goDescendants(minutesParticipant, kbps) {
  return (minutesParticipant * 60 * kbps) / 8 / 1e6;
}

/**
 * Impôt britannique sur les sociétés d'un mois, en centimes : le bénéfice du
 * mois est ramené à l'année pour choisir le taux. Rien à payer sur une perte.
 */
export function impotSocietesMensuel(beneficeCentimes, fiscalite) {
  if (beneficeCentimes <= 0) return 0;
  const is = fiscalite.impotSocietes;
  const annuel = beneficeCentimes * 12;
  const bas = is.seuilBasLivres * fiscalite.centimesParLivre;
  const haut = is.seuilHautLivres * fiscalite.centimesParLivre;
  let impot;
  if (annuel <= bas) impot = (annuel * is.tauxReduitBps) / 10000;
  else if (annuel >= haut) impot = (annuel * is.tauxNormalBps) / 10000;
  else impot = (annuel * is.tauxNormalBps) / 10000 - ((haut - annuel) * is.allegementNumerateur) / is.allegementDenominateur;
  return Math.round(impot / 12);
}

/** Bénéfice avant impôt nécessaire pour garder `netCentimes` après impôt. */
export function beneficeAvantImpotPour(netCentimes, fiscalite) {
  if (netCentimes <= 0) return netCentimes;
  let bas = netCentimes;
  let haut = netCentimes * 2;
  while (bas < haut) {
    const milieu = Math.floor((bas + haut) / 2);
    if (milieu - impotSocietesMensuel(milieu, fiscalite) >= netCentimes) haut = milieu;
    else bas = milieu + 1;
  }
  return bas;
}

// ---------------------------------------------------------------------------
// Hasard reproductible
// ---------------------------------------------------------------------------

export function generateur(graine) {
  let a = graine >>> 0;
  return function aleatoire() {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function tirerPoids(aleatoire, table) {
  const entrees = Object.entries(table).map(([cle, v]) => [cle, typeof v === 'number' ? v : v.poids]);
  const total = entrees.reduce((s, [, p]) => s + p, 0);
  let r = aleatoire() * total;
  for (const [cle, p] of entrees) {
    if (p <= 0) continue;
    if (r < p) return cle;
    r -= p;
  }
  return entrees.filter(([, p]) => p > 0).at(-1)[0];
}

function tirerPoisson(aleatoire, lambda) {
  if (lambda <= 0) return 0;
  const limite = Math.exp(-lambda);
  let k = 0;
  let p = 1;
  do {
    k++;
    p *= aleatoire();
  } while (p > limite);
  return k - 1;
}

// ---------------------------------------------------------------------------
// Population
// ---------------------------------------------------------------------------

function nouveauFoyer(aleatoire, p) {
  return {
    paiement: tirerPoids(aleatoire, p.comportements.paiement),
    origineCarte: tirerPoids(aleatoire, p.paiementEnLigne.origineCartes),
  };
}

function nouvelEleve(aleatoire, p, gabarit) {
  return {
    ...gabarit,
    disponibilite: tirerPoids(aleatoire, p.comportements.disponibilite),
    plaintes: tirerPoids(aleatoire, p.comportements.plaintes),
  };
}

/**
 * Génère les élèves, leurs foyers, les groupes et les enseignants.
 * Déterministe pour une graine donnée.
 */
export function genererPopulation(p) {
  const aleatoire = generateur(p.graine);
  const e = p.effectif;
  const regroupes = p.pertes.regrouper ? p.pertes : { enfants: 0, adultes: 0 };
  const nbEnfantsInscrits = Math.round(e.eleves * e.partEnfants);
  const nbEnfants = Math.max(0, nbEnfantsInscrits - regroupes.enfants);
  const nbAdultes = Math.max(0, e.eleves - nbEnfantsInscrits - regroupes.adultes);
  const eleves = [];
  const foyers = [];
  const sexe = () => (aleatoire() < e.partFeminin ? 'F' : 'M');

  const ajouterFoyer = () => {
    foyers.push({ id: foyers.length, ...nouveauFoyer(aleatoire, p), membres: [] });
    return foyers.at(-1);
  };
  const ajouterEleve = (foyer, gabarit) => {
    const eleve = { id: eleves.length, foyer: foyer.id, ...nouvelEleve(aleatoire, p, gabarit) };
    eleves.push(eleve);
    foyer.membres.push(eleve.id);
  };

  // Fratries d'enfants.
  let enfantsRestants = nbEnfants;
  const foyersAvecEnfants = [];
  while (enfantsRestants > 0) {
    const taille = Math.min(Number(tirerPoids(aleatoire, e.taillesFratrie)), enfantsRestants);
    const foyer = ajouterFoyer();
    for (let i = 0; i < taille; i++) {
      ajouterEleve(foyer, { type: 'enfant', tranche: tirerPoids(aleatoire, e.tranchesEnfant), sexe: sexe() });
    }
    foyersAvecEnfants.push(foyer);
    enfantsRestants -= taille;
  }

  // Adultes : parent inscrit avec ses enfants, couple, ou seul.
  let adultesRestants = nbAdultes;
  const parents = Math.min(Math.round(nbAdultes * e.partAdultesAvecEnfants), foyersAvecEnfants.length);
  for (let i = 0; i < parents; i++) {
    ajouterEleve(foyersAvecEnfants[i], { type: 'adulte', tranche: '18+', sexe: sexe() });
    adultesRestants--;
  }
  const couples = Math.floor((adultesRestants * e.partAdultesEnCouple) / 2);
  for (let i = 0; i < couples; i++) {
    const foyer = ajouterFoyer();
    ajouterEleve(foyer, { type: 'adulte', tranche: '18+', sexe: 'F' });
    ajouterEleve(foyer, { type: 'adulte', tranche: '18+', sexe: 'M' });
    adultesRestants -= 2;
  }
  while (adultesRestants > 0) {
    ajouterEleve(ajouterFoyer(), { type: 'adulte', tranche: '18+', sexe: sexe() });
    adultesRestants--;
  }

  const { groupes, enseignants } = formerGroupes(eleves, p);
  return { eleves, foyers, groupes, enseignants };
}

function separeParSexe(eleve, g) {
  if (eleve.type === 'adulte') return g.mixiteAdultes === 'separes';
  if (g.mixiteEnfants === 'separes') return true;
  return g.mixiteEnfants === 'separes-des-10-ans' && eleve.tranche !== '6-9';
}

function formerGroupes(eleves, p) {
  const g = p.groupes;
  const viviers = new Map();
  for (const eleve of eleves) {
    const cle = `${eleve.type}|${eleve.tranche}|${separeParSexe(eleve, g) ? eleve.sexe : 'mixte'}`;
    if (!viviers.has(cle)) viviers.set(cle, []);
    viviers.get(cle).push(eleve);
  }
  const groupes = [];
  for (const [cle, membres] of [...viviers].sort(([a], [b]) => a.localeCompare(b))) {
    const [type, tranche, public_] = cle.split('|');
    const max = type === 'enfant' ? g.maxEnfants : g.maxAdultes;
    const min = type === 'enfant' ? g.minEnfants : g.minAdultes;
    const { tailles, enAttente } = repartirEnGroupes(membres.length, max, min);
    for (const x of membres.slice(membres.length - enAttente)) x.enAttente = true;
    let curseur = 0;
    for (const taille of tailles) {
      const groupe = {
        id: groupes.length, type, tranche, public: public_,
        minutes: type === 'enfant' ? p.rythme.minutesEnfant : p.rythme.minutesAdulte,
        membres: membres.slice(curseur, curseur + taille).map((x) => x.id),
      };
      for (const id of groupe.membres) eleves[id].groupe = groupe.id;
      groupes.push(groupe);
      curseur += taille;
    }
  }
  return { groupes, enseignants: affecterEnseignants(groupes, g.groupesParEnseignant) };
}

// Une femme enseigne aux groupes de femmes, un homme aux groupes d'hommes ;
// les groupes d'enfants comblent les places restantes, puis ouvrent des
// postes d'enseignantes.
function affecterEnseignants(groupes, parEnseignant) {
  const enseignants = [];
  const pourvoir = (sexe, liste) => {
    for (const groupe of liste) {
      let enseignant = enseignants.find((x) => x.sexe === sexe && x.groupes.length < parEnseignant);
      if (!enseignant) {
        enseignant = { id: enseignants.length, sexe, groupes: [] };
        enseignants.push(enseignant);
      }
      enseignant.groupes.push(groupe.id);
      groupe.enseignant = enseignant.id;
    }
  };
  pourvoir('F', groupes.filter((x) => x.public === 'F'));
  pourvoir('M', groupes.filter((x) => x.public === 'M'));
  for (const groupe of groupes.filter((x) => x.public === 'mixte')) {
    const libre = enseignants.find((x) => x.groupes.length < parEnseignant);
    if (libre) {
      libre.groupes.push(groupe.id);
      groupe.enseignant = libre.id;
    } else {
      pourvoir('F', [groupe]);
    }
  }
  return enseignants;
}

// ---------------------------------------------------------------------------
// Simulation
// ---------------------------------------------------------------------------

function simulerTirage(population, p, aleatoire) {
  const c = p.comportements;
  const nbSeances = seancesParMois(p.rythme);
  const eleves = population.eleves.map((x) => ({ ...x, actif: !x.enAttente, retourAuMois: null }));
  const foyers = population.foyers.map((x) => ({ ...x, membres: [...x.membres], impayes: 0, reporte: 0 }));
  const mois = [];

  // Places de chaque catégorie de classe (type, tranche, public), pour les
  // changements de classe ou de créneau.
  const categorie = (eleve) => {
    const g = population.groupes[eleve.groupe];
    return `${g.type}|${g.tranche}|${g.public}`;
  };
  const places = new Map();
  for (const eleve of eleves.filter((x) => x.groupe !== undefined)) {
    const cle = categorie(eleve);
    if (!places.has(cle)) places.set(cle, []);
    places.get(cle).push(eleve.id);
  }

  // Élèves perdus pour de bon : leur place reste vide (sans regroupement).
  if (!p.pertes.regrouper) {
    for (const [type, nombre] of [['enfant', p.pertes.enfants], ['adulte', p.pertes.adultes]]) {
      const candidats = eleves.filter((x) => x.actif && x.type === type);
      for (let i = 0; i < Math.min(nombre, candidats.length); i++) {
        const j = i + Math.floor(aleatoire() * (candidats.length - i));
        [candidats[i], candidats[j]] = [candidats[j], candidats[i]];
        Object.assign(candidats[i], { actif: false, ferme: true });
      }
    }
  }

  for (let m = 1; m <= p.mois; m++) {
    const r = {
      mois: m, factureCentimes: 0, encaisseCentimes: 0, impayeCentimes: 0, reporteCentimes: 0,
      remisesCentimes: 0, fraisCarteCentimes: 0, paiements: 0, heuresEnseigneesCentiemes: 0,
      minutesParticipant: 0, seancesTenues: 0, seancesAnnulees: 0, plaintes: 0, departs: 0,
      suspensions: 0, elevesActifs: 0, foyersActifs: 0, arrivees: 0, relances: 0,
      changements: 0, changementsRefuses: 0,
    };
    const encaisser = (foyer, montant) => {
      r.encaisseCentimes += montant;
      r.fraisCarteCentimes += fraisCarte(montant, foyer.origineCarte, p.paiementEnLigne);
      r.paiements++;
    };

    // 1. Les places libérées sont reprises par de nouvelles familles.
    for (const eleve of eleves) {
      if (!eleve.actif && eleve.retourAuMois === m) {
        const foyer = { id: foyers.length, ...nouveauFoyer(aleatoire, p), membres: [eleve.id], impayes: 0, reporte: 0 };
        foyers.push(foyer);
        Object.assign(eleve, nouvelEleve(aleatoire, p, eleve), { foyer: foyer.id, actif: true, retourAuMois: null });
        r.arrivees++;
      }
    }

    // 2. Facturation et encaissement, foyer par foyer.
    for (const foyer of foyers) {
      if (foyer.reporte > 0) {
        encaisser(foyer, foyer.reporte);
        foyer.reporte = 0;
      }
      const actifs = foyer.membres.filter((id) => eleves[id].actif && eleves[id].foyer === foyer.id);
      if (actifs.length === 0) continue;
      r.foyersActifs++;
      const types = actifs.map((id) => eleves[id].type);
      const du = mensualiteFoyer(types, p.tarifs);
      r.factureCentimes += du;
      r.remisesCentimes += remiseFamiliale(types.length, p.tarifs);
      const profil = c.paiement[foyer.paiement];
      const tirage = aleatoire();
      if (tirage < profil.dansLeMois) {
        encaisser(foyer, du);
        foyer.impayes = 0;
      } else if (tirage < profil.dansLeMois + profil.moisSuivant) {
        foyer.reporte = du;
        r.reporteCentimes += du;
        r.relances++;
      } else {
        r.impayeCentimes += du;
        r.relances++;
        foyer.impayes++;
        if (foyer.impayes >= c.moisImpayesAvantSuspension) {
          r.suspensions++;
          for (const id of actifs) liberer(eleves[id], m, c, r);
        }
      }
    }

    // 3. Séances : annulations, absences, minutes de visio, heures payées.
    for (const groupe of population.groupes) {
      const presents = groupe.membres.filter((id) => eleves[id].actif);
      if (presents.length === 0) continue;
      for (let s = 0; s < nbSeances; s++) {
        if (aleatoire() < p.rythme.probabiliteAnnulation) {
          r.seancesAnnulees++;
          continue;
        }
        let la = 0;
        for (const id of presents) {
          if (aleatoire() >= c.disponibilite[eleves[id].disponibilite].absence) la++;
        }
        r.seancesTenues++;
        r.heuresEnseigneesCentiemes += Math.round((groupe.minutes * 100) / 60);
        r.minutesParticipant += (la + 1) * groupe.minutes;
      }
    }

    // 4. Plaintes, départs et demandes de changement de classe ou de créneau.
    const deplaces = new Set();
    for (const eleve of eleves) {
      if (!eleve.actif || deplaces.has(eleve.id)) continue;
      r.elevesActifs++;
      const plainte = c.plaintes[eleve.plaintes];
      r.plaintes += tirerPoisson(aleatoire, plainte.parMois);
      const depart = (c.disponibilite[eleve.disponibilite].departMensuel + plainte.departMensuel) * c.multiplicateurDeparts;
      if (aleatoire() < depart) {
        liberer(eleve, m, c, r);
        continue;
      }
      if (eleve.groupe === undefined || aleatoire() >= c.changementMensuel) continue;
      r.changements++;
      const libres = places.get(categorie(eleve)).filter((id) =>
        eleves[id].groupe !== eleve.groupe && !eleves[id].actif && !eleves[id].ferme);
      if (libres.length === 0) {
        r.changementsRefuses++;
        if (aleatoire() < c.departSiRefus) liberer(eleve, m, c, r);
        continue;
      }
      const cible = eleves[libres[Math.floor(aleatoire() * libres.length)]];
      Object.assign(cible, {
        foyer: eleve.foyer, disponibilite: eleve.disponibilite, plaintes: eleve.plaintes, sexe: eleve.sexe,
        actif: true, retourAuMois: null,
      });
      if (!foyers[eleve.foyer].membres.includes(cible.id)) foyers[eleve.foyer].membres.push(cible.id);
      deplaces.add(cible.id);
      // La place quittée se libère comme après un départ, sans perdre l'élève.
      eleve.actif = false;
      eleve.retourAuMois = c.delaiRemplacementMois == null ? null : m + 1 + c.delaiRemplacementMois;
    }

    const minutes = p.administration.minutesParEvenement;
    r.heuresAdministration = (
      r.relances * minutes.relance + r.plaintes * minutes.plainte +
      (r.changements - r.changementsRefuses) * minutes.changement + r.changementsRefuses * minutes.changementRefuse +
      r.departs * minutes.depart + r.arrivees * minutes.arrivee) / 60;
    r.coutsServicesCentimes = coutsServices(r, p);
    r.virementsEnseignants = population.enseignants.length;
    r.resultatAvantEnseignantsCentimes =
      r.encaisseCentimes - r.fraisCarteCentimes - r.coutsServicesCentimes.total - coutAdministration(p);
    mois.push(r);
  }
  return mois;
}

function liberer(eleve, m, c, r) {
  eleve.actif = false;
  eleve.retourAuMois = c.delaiRemplacementMois == null ? null : m + 1 + c.delaiRemplacementMois;
  r.departs++;
}

export function coutAdministration(p) {
  return p.administration.effectif * p.administration.salaireMensuelCentimes;
}

function coutsServices(r, p) {
  const go = goDescendants(r.minutesParticipant, p.livekit.debitDescendantKbps);
  const livekit = coutLivekit(r.minutesParticipant, go, p.livekit);
  let r2 = 0;
  if (p.r2.enregistrementAudio) {
    const goR2 = ((r.minutesParticipant / 60) * p.r2.moParHeureEleve) / 1000;
    r2 = Math.round((Math.max(0, goR2 - p.r2.goGratuits) * p.r2.centimesPar100Go) / 100);
  }
  const fixes = p.services.reduce((s, x) => s + x.centimes, 0);
  return { livekit, goLivekit: go, r2, fixes, total: livekit + r2 + fixes };
}

/** Coût complet de la paie enseignante pour un taux donné. */
export function coutEnseignants(moisSimule, tauxCentimesParHeure, p) {
  const brut = Math.round((moisSimule.heuresEnseigneesCentiemes * tauxCentimesParHeure) / 100);
  const frais =
    Math.round((brut * p.enseignants.fraisVirementBps) / 10000) +
    moisSimule.virementsEnseignants * p.enseignants.fraisVirementFixeCentimes;
  return { brut, frais, total: brut + frais };
}

/** Résultat d'un mois simulé pour un taux enseignant : avant impôt, impôt, net. */
export function resultatMois(moisSimule, tauxCentimesParHeure, p) {
  const avantImpot = moisSimule.resultatAvantEnseignantsCentimes - coutEnseignants(moisSimule, tauxCentimesParHeure, p).total;
  const impot = impotSocietesMensuel(avantImpot, p.fiscalite);
  return { avantImpot, impot, net: avantImpot - impot };
}

/**
 * Taux horaire enseignant maximal (centimes/h) qui garde, après impôt, au
 * moins `cibleNet(mois)` centimes. 0 si la cible est hors d'atteinte même
 * sans payer les enseignants.
 */
export function tauxHoraireMax(moisSimule, cibleNet, p) {
  const tient = (taux) => resultatMois(moisSimule, taux, p).net >= cibleNet(moisSimule);
  if (!tient(0)) return 0;
  let bas = 0;
  let haut = 100000;
  while (bas < haut) {
    const milieu = Math.ceil((bas + haut) / 2);
    if (tient(milieu)) bas = milieu;
    else haut = milieu - 1;
  }
  return bas;
}

/**
 * Ce que l'académie peut se permettre en un mois avant de passer sous
 * `cibleNetCentimes` après impôt : encaissement qu'on peut perdre, nombre
 * d'enfants ou d'adultes perdus ou en bourse complète, remise maximale sur
 * toutes les mensualités. Négatif : la cible est déjà manquée de ce montant.
 */
export function margeDeManoeuvre(moisSimule, tauxCentimesParHeure, cibleNetCentimes, p) {
  const avantImpot = resultatMois(moisSimule, tauxCentimesParHeure, p).avantImpot;
  const ecart = avantImpot - beneficeAvantImpotPour(cibleNetCentimes, p.fiscalite);
  // Un dollar d'encaissement en moins économise aussi ses frais de carte.
  const partFrais = moisSimule.encaisseCentimes ? moisSimule.fraisCarteCentimes / moisSimule.encaisseCentimes : 0;
  const encaissementPerdable = Math.round(ecart / (1 - partFrais));
  return {
    encaissementPerdable,
    enfants: Math.floor(encaissementPerdable / p.tarifs.enfantCentimes),
    adultes: Math.floor(encaissementPerdable / p.tarifs.adulteCentimes),
    remiseMaxBps: moisSimule.encaisseCentimes
      ? Math.floor((encaissementPerdable * 10000) / moisSimule.encaisseCentimes) : 0,
  };
}

export function centile(valeurs, q) {
  const tri = [...valeurs].sort((a, b) => a - b);
  if (tri.length === 0) return 0;
  return tri[Math.min(tri.length - 1, Math.max(0, Math.floor(q * (tri.length - 1) + 0.5)))];
}

const moyenne = (valeurs) => valeurs.reduce((s, v) => s + v, 0) / Math.max(1, valeurs.length);

/**
 * Lance la simulation complète d'un jeu de paramètres.
 * `marges` : marges cibles (part de l'encaissé gardée après impôt) pour
 * lesquelles calculer le taux enseignant max.
 * `tauxEnseignantCentimes` : taux horaire appliqué pour le résultat final.
 */
export function simuler(
  p,
  { marges = p.objectifs.marges, tauxEnseignantCentimes = p.enseignants.tauxReferenceCentimes } = {},
) {
  const population = genererPopulation(p);
  const aleatoire = generateur((p.graine ^ 0x9e3779b9) >>> 0);
  const tirages = [];
  for (let t = 0; t < p.tirages; t++) tirages.push(simulerTirage(population, p, aleatoire));

  const stables = tirages.flatMap((mois) => mois.slice(p.premierMoisStable - 1));
  const serie = (cle) => stables.map((x) => x[cle]);
  const distribution = (valeurs) => ({
    p10: centile(valeurs, 0.1), p50: centile(valeurs, 0.5), p90: centile(valeurs, 0.9), moyenne: moyenne(valeurs),
  });
  const auTaux = stables.map((x) => resultatMois(x, tauxEnseignantCentimes, p));
  const auPlafond = stables.map((x) => resultatMois(x, p.enseignants.plafondCentimes, p));
  const objectif = p.objectifs.resultatNetCentimes;

  const trajectoire = Array.from({ length: p.mois }, (_, i) => {
    const duMois = tirages.map((mois) => mois[i]);
    return {
      mois: i + 1,
      encaisseP50: centile(duMois.map((x) => x.encaisseCentimes), 0.5),
      elevesActifsP50: centile(duMois.map((x) => x.elevesActifs), 0.5),
    };
  });

  // p10 = tenu 9 mois sur 10 (prudent) ; p50 = un mois sur deux.
  const tauxMax = (cible) => {
    const taux = stables.map((x) => tauxHoraireMax(x, cible, p));
    return { prudent: centile(taux, 0.1), median: centile(taux, 0.5) };
  };
  const manoeuvre = (cibleNet) => {
    const m = stables.map((x) => margeDeManoeuvre(x, tauxEnseignantCentimes, cibleNet, p));
    const champ = (cle) => ({ prudent: centile(m.map((x) => x[cle]), 0.1), median: centile(m.map((x) => x[cle]), 0.5) });
    return {
      encaissementPerdable: champ('encaissementPerdable'), enfants: champ('enfants'),
      adultes: champ('adultes'), remiseMaxBps: champ('remiseMaxBps'),
    };
  };

  return {
    parametres: p,
    population: resumerPopulation(population, p),
    moisType: {
      facture: distribution(serie('factureCentimes')),
      encaisse: distribution(serie('encaisseCentimes')),
      impaye: distribution(serie('impayeCentimes')),
      reporte: distribution(serie('reporteCentimes')),
      remises: distribution(serie('remisesCentimes')),
      fraisCarte: distribution(serie('fraisCarteCentimes')),
      livekit: distribution(stables.map((x) => x.coutsServicesCentimes.livekit)),
      goLivekit: distribution(stables.map((x) => x.coutsServicesCentimes.goLivekit)),
      r2: distribution(stables.map((x) => x.coutsServicesCentimes.r2)),
      servicesFixes: stables[0]?.coutsServicesCentimes.fixes ?? 0,
      administration: coutAdministration(p),
      resultatAvantEnseignants: distribution(serie('resultatAvantEnseignantsCentimes')),
      enseignants: distribution(stables.map((x) => coutEnseignants(x, tauxEnseignantCentimes, p).total)),
      avantImpot: distribution(auTaux.map((x) => x.avantImpot)),
      impot: distribution(auTaux.map((x) => x.impot)),
      resultat: distribution(auTaux.map((x) => x.net)),
      resultatAuPlafond: distribution(auPlafond.map((x) => x.net)),
      // Part des mois où le résultat net atteint l'objectif, puis ne perd pas d'argent.
      objectifAtteint: auTaux.filter((x) => x.net >= objectif).length / Math.max(1, stables.length),
      rentable: auTaux.filter((x) => x.net >= 0).length / Math.max(1, stables.length),
      heuresEnseignees: distribution(stables.map((x) => x.heuresEnseigneesCentiemes / 100)),
      minutesParticipant: distribution(serie('minutesParticipant')),
      seancesTenues: distribution(serie('seancesTenues')),
      plaintes: distribution(serie('plaintes')),
      departs: distribution(serie('departs')),
      arrivees: distribution(serie('arrivees')),
      suspensions: distribution(serie('suspensions')),
      relances: distribution(serie('relances')),
      changements: distribution(serie('changements')),
      changementsRefuses: distribution(serie('changementsRefuses')),
      heuresAdministration: distribution(serie('heuresAdministration')),
      elevesActifs: distribution(serie('elevesActifs')),
    },
    tauxEnseignantMax: {
      rentable: tauxMax(() => 0),
      objectif: tauxMax(() => objectif),
      marges: marges.map((marge) => ({ marge, ...tauxMax((x) => marge * x.encaisseCentimes) })),
    },
    margeDeManoeuvre: { rentable: manoeuvre(0), objectif: manoeuvre(objectif) },
    trajectoire,
  };
}

function resumerPopulation(population, p) {
  const { eleves, foyers, groupes, enseignants } = population;
  const compter = (liste, cle) =>
    liste.reduce((acc, x) => ({ ...acc, [x[cle]]: (acc[x[cle]] ?? 0) + 1 }), {});
  const taillesFoyers = compter(foyers.map((f) => ({ n: f.membres.length })), 'n');
  const nbSeances = seancesParMois(p.rythme);
  const heuresParGroupe = (g) => (g.minutes * nbSeances) / 60;
  return {
    eleves: eleves.length,
    enfants: eleves.filter((x) => x.type === 'enfant').length,
    adultes: eleves.filter((x) => x.type === 'adulte').length,
    feminin: eleves.filter((x) => x.sexe === 'F').length,
    enAttente: eleves.filter((x) => x.enAttente).length,
    tranches: compter(eleves, 'tranche'),
    foyers: foyers.length,
    taillesFoyers,
    paiement: compter(foyers, 'paiement'),
    disponibilite: compter(eleves, 'disponibilite'),
    plaintes: compter(eleves, 'plaintes'),
    origineCartes: compter(foyers, 'origineCarte'),
    factureTheoriqueCentimes: foyers.reduce(
      (s, f) => s + mensualiteFoyer(f.membres.map((id) => eleves[id].type), p.tarifs), 0),
    remisesTheoriquesCentimes: foyers.reduce((s, f) => s + remiseFamiliale(f.membres.length, p.tarifs), 0),
    groupes: groupes.map((g) => ({
      id: g.id, type: g.type, tranche: g.tranche, public: g.public, taille: g.membres.length,
      enseignant: g.enseignant, heuresParMois: heuresParGroupe(g),
    })),
    enseignants: enseignants.map((x) => ({
      id: x.id, sexe: x.sexe, groupes: x.groupes,
      heuresParMois: x.groupes.reduce((s, id) => s + heuresParGroupe(groupes[id]), 0),
    })),
    administration: p.administration.effectif,
    seancesParMois: nbSeances,
  };
}
