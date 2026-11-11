// Banc de la salle : relais UDP qui abime le reseau entre un navigateur et le
// serveur LiveKit LOCAL. Le noyau de la machine de test n'a pas `netem`
// (CONFIG_NET_SCH_NETEM absent) : on degrade donc en espace utilisateur.
//
// Chaque flux (adresse et port source d'un navigateur) a son propre profil,
// dans chaque sens :
//   perte      : probabilite de perte d'un paquet, 0 a 1 ;
//   rafale     : longueur moyenne d'une rafale de pertes, en paquets (modele de
//                Gilbert-Elliott ; 1 = pertes independantes). Un vrai reseau
//                mobile perd par rafales, pas paquet par paquet ;
//   delai      : latence ajoutee, en ms ;
//   gigue      : variation aleatoire du delai, en ms (plus ou moins) ;
//   debit      : plafond en kbit/s (0 = sans plafond), file de `file` ms ;
//   coupe      : true = rien ne passe (coupure, tunnel).
//
// Pilotage par HTTP local :
//   GET  /flux                     la liste des flux et leurs compteurs
//   POST /profil  {port, montant:{...}, descendant:{...}}   port = port source
//        du navigateur, ou "tous" ; `montant` = navigateur vers serveur.
//
// Usage : node tool/salle/reseau_degrade.mjs <ip_ecoute> <port> <ip_serveur> <port_serveur> [port_pilotage]
// Rien ne sort de la machine : les deux adresses sont locales.
import dgram from 'node:dgram';
import http from 'node:http';

const [ipEcoute, portEcoute, ipServeur, portServeur, portPilotage = '7890'] = process.argv.slice(2);
if (!ipEcoute || !portEcoute || !ipServeur || !portServeur) {
  console.error('usage : reseau_degrade.mjs <ip_ecoute> <port> <ip_serveur> <port_serveur> [port_pilotage]');
  process.exit(2);
}
for (const ip of [ipEcoute, ipServeur]) {
  if (!/^(127\.|172\.(1[6-9]|2\d|3[01])\.|10\.|192\.168\.)/.test(ip)) {
    console.error(`refus : ${ip} n'est pas une adresse locale`); process.exit(2);
  }
}

const NEUTRE = { perte: 0, rafale: 1, delai: 0, gigue: 0, debit: 0, file: 300, coupe: false };

class Sens {
  constructor() { this.regler({}); this.passes = 0; this.perdus = 0; this.octets = 0; }
  regler(p) {
    this.p = { ...NEUTRE, ...p };
    this.mauvais = false;      // etat de Gilbert-Elliott
    this.libreA = 0;           // instant ou le lien (debit) sera libre
    this.dernier = 0;          // garde l'ordre des paquets malgre la gigue
  }
  /// Rend le delai d'envoi en ms, ou -1 si le paquet est perdu.
  juger(taille, maintenant) {
    const p = this.p;
    if (p.coupe) { this.perdus += 1; return -1; }
    if (p.perte > 0) {
      // Deux etats : bon (rien ne se perd), mauvais (tout se perd). La duree
      // moyenne du mauvais etat est `rafale` ; le taux moyen reste `perte`.
      const sortir = 1 / Math.max(1, p.rafale);
      const entrer = Math.min(1, (p.perte * sortir) / Math.max(1e-9, 1 - p.perte));
      this.mauvais = this.mauvais ? Math.random() >= sortir : Math.random() < entrer;
      if (this.mauvais) { this.perdus += 1; return -1; }
    }
    let depart = maintenant;
    if (p.debit > 0) {
      const duree = (taille * 8) / p.debit; // ms, car kbit/s = bit/ms
      const debut = Math.max(maintenant, this.libreA);
      if (debut - maintenant > p.file) { this.perdus += 1; return -1; } // file pleine
      this.libreA = debut + duree;
      depart = this.libreA;
    }
    let sortie = depart + p.delai + (p.gigue > 0 ? (Math.random() * 2 - 1) * p.gigue : 0);
    if (sortie < this.dernier) sortie = this.dernier; // pas de desordre
    this.dernier = sortie;
    this.passes += 1; this.octets += taille;
    return Math.max(0, sortie - maintenant);
  }
}

const flux = new Map(); // "ip:port" du navigateur -> { amont, montant, descendant, ... }
let profilDefaut = { montant: {}, descendant: {} };
const ecoute = dgram.createSocket('udp4');
let prochainPort = 0;

function fluxDe(adresse, port) {
  const cle = `${adresse}:${port}`;
  let f = flux.get(cle);
  if (f) return f;
  const amont = dgram.createSocket('udp4');
  f = { cle, adresse, port, amont, montant: new Sens(), descendant: new Sens(), vu: Date.now(), ne: Date.now() };
  f.montant.regler(profilDefaut.montant); f.descendant.regler(profilDefaut.descendant);
  amont.on('message', (msg) => {
    f.vu = Date.now();
    const d = f.descendant.juger(msg.length, performance.now());
    if (d < 0) return;
    if (d < 1) ecoute.send(msg, port, adresse); else setTimeout(() => ecoute.send(msg, port, adresse), d);
  });
  amont.on('error', () => {});
  // Ports 20000 a 20999 : le pare-feu du banc (tool/salle/banc.sh) ne laisse
  // LiveKit repondre qu'a eux, pour que rien ne contourne le relais.
  amont.bind(20000 + (prochainPort++ % 1000), ipEcoute);
  flux.set(cle, f);
  return f;
}

ecoute.on('message', (msg, info) => {
  const f = fluxDe(info.address, info.port);
  f.vu = Date.now();
  const d = f.montant.juger(msg.length, performance.now());
  if (d < 0) return;
  if (d < 1) f.amont.send(msg, Number(portServeur), ipServeur);
  else setTimeout(() => f.amont.send(msg, Number(portServeur), ipServeur), d);
});
ecoute.bind(Number(portEcoute), ipEcoute, () => console.log(`relais UDP ${ipEcoute}:${portEcoute} -> ${ipServeur}:${portServeur} ; pilotage 127.0.0.1:${portPilotage}`));

// Un flux muet depuis 2 minutes est ferme.
setInterval(() => {
  for (const [cle, f] of flux) if (Date.now() - f.vu > 120000) { f.amont.close(); flux.delete(cle); }
}, 30000).unref();

const etat = (s) => ({ ...s.p, passes: s.passes, perdus: s.perdus, octets: s.octets });
http.createServer((req, res) => {
  const rendre = (code, o) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(o)); };
  if (req.method === 'GET' && req.url === '/flux') {
    return rendre(200, [...flux.values()].map((f) => ({ port: f.port, adresse: f.adresse, ne: f.ne, vu: f.vu,
      montant: etat(f.montant), descendant: etat(f.descendant) })));
  }
  if (req.method === 'POST' && req.url === '/profil') {
    let corps = '';
    req.on('data', (c) => { corps += c; });
    req.on('end', () => {
      try {
        const o = JSON.parse(corps);
        const cibles = o.port === 'tous' ? [...flux.values()] : [...flux.values()].filter((f) => f.port === Number(o.port));
        if (o.port === 'tous' && o.defaut) profilDefaut = { montant: o.montant ?? {}, descendant: o.descendant ?? {} };
        for (const f of cibles) { f.montant.regler(o.montant ?? {}); f.descendant.regler(o.descendant ?? {}); }
        rendre(200, { regles: cibles.length });
      } catch (e) { rendre(400, { erreur: String(e) }); }
    });
    return undefined;
  }
  return rendre(404, { erreur: 'inconnu' });
}).listen(Number(portPilotage), '127.0.0.1');
