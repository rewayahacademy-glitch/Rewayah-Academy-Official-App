// Faux Stripe de BANC (FN-115c, pilote, 02/11/2026) : aucune cle secrete,
// meme de test, n'est fournie a la pile locale. La fonction Edge
// remboursement-stripe y est envoyee par STRIPE_API_BASE_BANC (cle sk_test_
// et adresse locale seulement, `_shared/stripe.ts`).
//
// Ce serveur repond a :
//   POST /v1/refunds        cree un remboursement ; une meme cle
//                           d'idempotence rend le meme remboursement, comme
//                           Stripe ;
//   GET  /v1/refunds        la liste, filtree par payment_intent ;
//   GET  /__journal         ce qu'il a recu (pour le robot) : methode, chemin,
//                           cle d'idempotence, corps decode.
// Il ne prouve que la forme de la requete : l'appel au vrai Stripe n'est pas
// prouve ici.
//
// Usage : node tool/e2e/faux_stripe.mjs [port]   (12111 par defaut)
import http from 'node:http';

const port = Number(process.argv[2] ?? 12111);
const journal = [];
const parCle = new Map();
const remboursements = [];
let n = 0;
const lancement = Date.now().toString(36);

function repondre(res, statut, corps) {
  res.writeHead(statut, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(corps));
}

http.createServer((req, res) => {
  let brut = '';
  req.on('data', (c) => { brut += c; });
  req.on('end', () => {
    const u = new URL(req.url, `http://${req.headers.host}`);
    const corps = Object.fromEntries(new URLSearchParams(brut));
    const cle = req.headers['idempotency-key'] ?? null;
    if (u.pathname !== '/__journal') {
      journal.push({ methode: req.method, chemin: u.pathname, cle, corps,
        autorisation: (req.headers.authorization ?? '').slice(0, 15) });
    }
    if (u.pathname === '/__journal') return repondre(res, 200, journal);
    if (u.pathname === '/v1/refunds' && req.method === 'POST') {
      if (cle && parCle.has(cle)) return repondre(res, 200, parCle.get(cle));
      n += 1;
      const r = {
        // Unique d'un lancement a l'autre : la base de banc garde les
        // identifiants des passages precedents (cle unique).
        id: `re_banc_${lancement}_${n}`,
        object: 'refund',
        amount: Number(corps.amount),
        currency: 'usd',
        payment_intent: corps.payment_intent,
        status: 'succeeded',
        created: Math.floor(Date.now() / 1000),
        metadata: {
          demande: corps['metadata[demande]'] ?? null,
          profil: corps['metadata[profil]'] ?? null,
        },
      };
      remboursements.push(r);
      if (cle) parCle.set(cle, r);
      return repondre(res, 200, r);
    }
    if (u.pathname === '/v1/refunds' && req.method === 'GET') {
      const pi = u.searchParams.get('payment_intent');
      return repondre(res, 200, { object: 'list', has_more: false,
        data: remboursements.filter((r) => !pi || r.payment_intent === pi) });
    }
    return repondre(res, 404, { error: { message: 'inconnu du faux Stripe' } });
  });
}).listen(port, '0.0.0.0', () => console.log(`faux Stripe de banc sur :${port}`));
