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
// PAY-UX (02/11/2026) : les sessions Checkout du formulaire integre.
//   POST /v1/checkout/sessions             cree une session `open` (une meme cle
//                                          d'idempotence rend la meme session) ;
//   GET  /v1/checkout/sessions/:id         la relit ;
//   POST /v1/checkout/sessions/:id/expire  l'expire si elle est ouverte ; refuse
//                                          (400) si elle ne l'est pas, ou si le
//                                          robot a demande le refus ;
//   POST /__payer/:id                      la marque `complete` (paiement simule) ;
//   POST /__refuser_expiration?oui=1|0     fait refuser (ou non) les expirations.
// Il ne prouve que la forme de la requete : l'appel au vrai Stripe n'est pas
// prouve ici.
//
// Usage : node tool/e2e/faux_stripe.mjs [port]   (12111 par defaut)
import http from 'node:http';

const port = Number(process.argv[2] ?? 12111);
const journal = [];
const parCle = new Map();
const remboursements = [];
const sessions = new Map();
let refuserExpiration = false;
let n = 0;
const lancement = Date.now().toString(36);

function repondre(res, statut, corps) {
  // PAY-UX : le faux formulaire du navigateur relit sa session (fond, noms).
  res.writeHead(statut, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
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
    if (u.pathname === '/v1/checkout/sessions' && req.method === 'POST') {
      if (cle && parCle.has(cle)) return repondre(res, 200, parCle.get(cle));
      n += 1;
      // Forme des vrais identifiants (cs_test_ puis lettres et chiffres).
      const id = `cs_test_banc${lancement}x${n}`;
      const session = {
        id,
        object: 'checkout.session',
        status: 'open',
        livemode: false,
        ui_mode: corps.ui_mode ?? null,
        url: corps.ui_mode === 'embedded_page' ? null : `http://127.0.0.1:${port}/payer/${id}`,
        client_secret: corps.ui_mode === 'embedded_page' ? `${id}_secret_banc` : null,
        // Ce que le serveur a demande, relu par le robot.
        branding_settings: {
          background_color: corps['branding_settings[background_color]'] ?? null,
          display_name: corps['branding_settings[display_name]'] ?? null,
        },
        noms: Object.entries(corps)
          .filter(([k]) => /^line_items\[\d+\]\[price_data\]\[product_data\]\[name\]$/.test(k))
          .map(([, v]) => v),
      };
      sessions.set(id, session);
      if (cle) parCle.set(cle, session);
      return repondre(res, 200, session);
    }
    const mSession = u.pathname.match(/^\/v1\/checkout\/sessions\/([^/]+)(\/expire)?$/);
    if (mSession) {
      const session = sessions.get(mSession[1]);
      if (!session) return repondre(res, 404, { error: { type: 'invalid_request_error', message: 'No such checkout.session' } });
      if (!mSession[2] && req.method === 'GET') return repondre(res, 200, session);
      if (mSession[2] && req.method === 'POST') {
        if (refuserExpiration || session.status !== 'open') {
          return repondre(res, 400, { error: { type: 'invalid_request_error',
            message: `Only Checkout Sessions with a status of open can be expired (${session.status}).` } });
        }
        session.status = 'expired';
        return repondre(res, 200, session);
      }
    }
    const mPayer = u.pathname.match(/^\/__payer\/([^/]+)$/);
    if (mPayer && req.method === 'POST') {
      const session = sessions.get(mPayer[1]);
      if (!session) return repondre(res, 404, { error: { message: 'session inconnue' } });
      session.status = 'complete';
      return repondre(res, 200, session);
    }
    if (u.pathname === '/__refuser_expiration' && req.method === 'POST') {
      refuserExpiration = u.searchParams.get('oui') === '1';
      return repondre(res, 200, { refuserExpiration });
    }
    if (u.pathname === '/v1/refunds' && req.method === 'GET') {
      const pi = u.searchParams.get('payment_intent');
      return repondre(res, 200, { object: 'list', has_more: false,
        data: remboursements.filter((r) => !pi || r.payment_intent === pi) });
    }
    return repondre(res, 404, { error: { message: 'inconnu du faux Stripe' } });
  });
}).listen(port, '0.0.0.0', () => console.log(`faux Stripe de banc sur :${port}`));
