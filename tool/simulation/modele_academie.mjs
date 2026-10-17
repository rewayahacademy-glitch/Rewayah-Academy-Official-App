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

export const VERSION_MODELE = 1;

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
    // Tranches d'âge de la migration 0043 ; ≤ 17 ans = public enfant.
    tranchesEnfant: { '5-7': 0.25, '8-10': 0.3, '11-14': 0.3, '15-17': 0.15 },
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

  groupes: {
    maxEnfants: 5,
    maxAdultes: 6,
    minimumLancement: 3,
    groupesParEnseignant: 2,
    separerAdultesParSexe: true,
    separerEnfantsParSexe: false,
  },

  administration: { effectif: 4, coutMensuelCentimes: 0 },

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
  },

  // Encaissement par carte (grille Stripe France publique, octobre 2026).
  paiementEnLigne: {
    origineCartes: { eee: 0.5, royaumeUni: 0.1, international: 0.4 },
    bps: { eee: 150, royaumeUni: 250, international: 325 },
    fixeCentimes: 29, // 0,25 € converti en dollars
    conversionBps: 200, // prix en USD, compte réglé en EUR
  },

  enseignants: { fraisVirementBps: 200, fraisVirementFixeCentimes: 100 },

  // Prélèvements assis sur l'encaissé (TVA, cotisations…). Zéro par défaut
  // tant que la structure juridique n'est pas connue : à renseigner.
  fiscalite: { prelevementsBps: 0 },

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

/** Découpe `n` élèves en groupes équilibrés d'au plus `max`. */
export function repartirEnGroupes(n, max) {
  if (n <= 0) return [];
  const k = Math.ceil(n / max);
  const base = Math.floor(n / k);
  const reste = n % k;
  return Array.from({ length: k }, (_, i) => base + (i < reste ? 1 : 0));
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
  const nbEnfants = Math.round(e.eleves * e.partEnfants);
  const nbAdultes = e.eleves - nbEnfants;
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

function formerGroupes(eleves, p) {
  const g = p.groupes;
  const viviers = new Map();
  for (const eleve of eleves) {
    const parSexe = eleve.type === 'enfant' ? g.separerEnfantsParSexe : g.separerAdultesParSexe;
    const cle = `${eleve.type}|${eleve.tranche}|${parSexe ? eleve.sexe : 'mixte'}`;
    if (!viviers.has(cle)) viviers.set(cle, []);
    viviers.get(cle).push(eleve);
  }
  const groupes = [];
  for (const [cle, membres] of [...viviers].sort(([a], [b]) => a.localeCompare(b))) {
    const [type, tranche, public_] = cle.split('|');
    const max = type === 'enfant' ? g.maxEnfants : g.maxAdultes;
    let curseur = 0;
    for (const taille of repartirEnGroupes(membres.length, max)) {
      const groupe = {
        id: groupes.length, type, tranche, public: public_,
        minutes: type === 'enfant' ? p.rythme.minutesEnfant : p.rythme.minutesAdulte,
        membres: membres.slice(curseur, curseur + taille).map((x) => x.id),
        sousMinimum: taille < g.minimumLancement,
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
  const eleves = population.eleves.map((x) => ({ ...x, actif: true, retourAuMois: null }));
  const foyers = population.foyers.map((x) => ({ ...x, membres: [...x.membres], impayes: 0, reporte: 0 }));
  const mois = [];

  for (let m = 1; m <= p.mois; m++) {
    const r = {
      mois: m, factureCentimes: 0, encaisseCentimes: 0, impayeCentimes: 0, reporteCentimes: 0,
      remisesCentimes: 0, fraisCarteCentimes: 0, paiements: 0, heuresEnseigneesCentiemes: 0,
      minutesParticipant: 0, seancesTenues: 0, seancesAnnulees: 0, plaintes: 0, departs: 0,
      suspensions: 0, elevesActifs: 0, foyersActifs: 0,
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
      } else {
        r.impayeCentimes += du;
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

    // 4. Plaintes et départs.
    for (const eleve of eleves) {
      if (!eleve.actif) continue;
      r.elevesActifs++;
      const plainte = c.plaintes[eleve.plaintes];
      r.plaintes += tirerPoisson(aleatoire, plainte.parMois);
      if (aleatoire() < c.disponibilite[eleve.disponibilite].departMensuel + plainte.departMensuel) {
        liberer(eleve, m, c, r);
      }
    }

    r.coutsServicesCentimes = coutsServices(r, p);
    r.prelevementsCentimes = Math.round((r.encaisseCentimes * p.fiscalite.prelevementsBps) / 10000);
    r.virementsEnseignants = population.enseignants.length;
    r.resultatAvantEnseignantsCentimes =
      r.encaisseCentimes - r.fraisCarteCentimes - r.coutsServicesCentimes.total - r.prelevementsCentimes -
      p.administration.coutMensuelCentimes;
    mois.push(r);
  }
  return mois;
}

function liberer(eleve, m, c, r) {
  eleve.actif = false;
  eleve.retourAuMois = c.delaiRemplacementMois == null ? null : m + 1 + c.delaiRemplacementMois;
  r.departs++;
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

/**
 * Taux horaire enseignant maximal (centimes/h) tenant la marge `marge`
 * (0,3 = 30 % de l'encaissé) sur un mois simulé.
 */
export function tauxHoraireMax(moisSimule, marge, p) {
  const heures = moisSimule.heuresEnseigneesCentiemes / 100;
  if (heures === 0) return 0;
  const fixeVirements = moisSimule.virementsEnseignants * p.enseignants.fraisVirementFixeCentimes;
  const disponible = moisSimule.resultatAvantEnseignantsCentimes - marge * moisSimule.encaisseCentimes - fixeVirements;
  return Math.max(0, Math.floor(disponible / (heures * (1 + p.enseignants.fraisVirementBps / 10000))));
}

/** Coût complet de la paie enseignante pour un taux donné. */
export function coutEnseignants(moisSimule, tauxCentimesParHeure, p) {
  const brut = Math.round((moisSimule.heuresEnseigneesCentiemes * tauxCentimesParHeure) / 100);
  const frais =
    Math.round((brut * p.enseignants.fraisVirementBps) / 10000) +
    moisSimule.virementsEnseignants * p.enseignants.fraisVirementFixeCentimes;
  return { brut, frais, total: brut + frais };
}

export function centile(valeurs, q) {
  const tri = [...valeurs].sort((a, b) => a - b);
  if (tri.length === 0) return 0;
  return tri[Math.min(tri.length - 1, Math.max(0, Math.floor(q * (tri.length - 1) + 0.5)))];
}

const moyenne = (valeurs) => valeurs.reduce((s, v) => s + v, 0) / Math.max(1, valeurs.length);

/**
 * Lance la simulation complète d'un jeu de paramètres.
 * `marges` : marges cibles pour lesquelles calculer le taux enseignant max.
 * `tauxEnseignantCentimes` : taux horaire appliqué pour le résultat final.
 */
export function simuler(p, { marges = [0.2, 0.3, 0.4], tauxEnseignantCentimes = 0 } = {}) {
  const population = genererPopulation(p);
  const aleatoire = generateur((p.graine ^ 0x9e3779b9) >>> 0);
  const tirages = [];
  for (let t = 0; t < p.tirages; t++) tirages.push(simulerTirage(population, p, aleatoire));

  const stables = tirages.flatMap((mois) => mois.slice(p.premierMoisStable - 1));
  const serie = (cle) => stables.map((x) => x[cle]);
  const distribution = (valeurs) => ({
    p10: centile(valeurs, 0.1), p50: centile(valeurs, 0.5), p90: centile(valeurs, 0.9), moyenne: moyenne(valeurs),
  });

  const trajectoire = Array.from({ length: p.mois }, (_, i) => {
    const duMois = tirages.map((mois) => mois[i]);
    return {
      mois: i + 1,
      encaisseP50: centile(duMois.map((x) => x.encaisseCentimes), 0.5),
      elevesActifsP50: centile(duMois.map((x) => x.elevesActifs), 0.5),
    };
  });

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
      prelevements: distribution(serie('prelevementsCentimes')),
      resultatAvantEnseignants: distribution(serie('resultatAvantEnseignantsCentimes')),
      enseignants: distribution(stables.map((x) => coutEnseignants(x, tauxEnseignantCentimes, p).total)),
      resultat: distribution(stables.map(
        (x) => x.resultatAvantEnseignantsCentimes - coutEnseignants(x, tauxEnseignantCentimes, p).total)),
      heuresEnseignees: distribution(stables.map((x) => x.heuresEnseigneesCentiemes / 100)),
      minutesParticipant: distribution(serie('minutesParticipant')),
      seancesTenues: distribution(serie('seancesTenues')),
      plaintes: distribution(serie('plaintes')),
      departs: distribution(serie('departs')),
      suspensions: distribution(serie('suspensions')),
      elevesActifs: distribution(serie('elevesActifs')),
    },
    // p10 = taux tenu dans 90 % des mois (prudent) ; p50 = un mois sur deux.
    tauxEnseignantMax: marges.map((marge) => {
      const taux = stables.map((x) => tauxHoraireMax(x, marge, p));
      return { marge, prudent: centile(taux, 0.1), median: centile(taux, 0.5) };
    }),
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
      enseignant: g.enseignant, heuresParMois: heuresParGroupe(g), sousMinimum: g.sousMinimum,
    })),
    enseignants: enseignants.map((x) => ({
      id: x.id, sexe: x.sexe, groupes: x.groupes,
      heuresParMois: x.groupes.reduce((s, id) => s + heuresParGroupe(groupes[id]), 0),
    })),
    administration: p.administration.effectif,
    seancesParMois: nbSeances,
  };
}
