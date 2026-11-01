// FN-112, deuxieme essai : compare les claims du jeton d'origine et du jeton renouvele
// (renouvellement demande a l'API locale avec le jeton de renouvellement de la page),
// puis recharge la page avec la session renouvelee. Observe, ne corrige rien.
import fs from 'node:fs';
import { parcours, connecterParLien, libelles, activerSemantique, TRAVAIL } from './commun.mjs';
const { ADULTE } = JSON.parse(fs.readFileSync(TRAVAIL + '/comptes_parcours3.json', 'utf8'));
const p = await parcours('FN-112 : jeton renouvele', 'constats/FN-112-jeton');
const a = await p.contexte('adulte', { telephone: true });
await connecterParLien(a.page, ADULTE.courriel);
const res = await a.page.evaluate(async () => {
  const cle = Object.keys(localStorage).find((k) => /auth-token/.test(k));
  const s = JSON.parse(localStorage.getItem(cle));
  const claims = (t) => JSON.parse(atob(t.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
  const apikey = [...performance.getEntriesByType('resource')].length ? null : null;
  return { cle, s, avant: claims(s.access_token) };
});
const env = Object.fromEntries(fs.readFileSync('/tmp/e2e-pile/statut.env', 'utf8').split('\n').filter((l) => l.includes('=')).map((l) => [l.split('=')[0], l.split('=').slice(1).join('=').replace(/^"|"$/g, '')]));
const cleApi = env.PUBLISHABLE_KEY ?? env.ANON_KEY;
const r = await fetch('http://127.0.0.1:54321/auth/v1/token?grant_type=refresh_token', { method: 'POST', headers: { apikey: cleApi, 'content-type': 'application/json' }, body: JSON.stringify({ refresh_token: res.s.refresh_token }) });
const neuf = await r.json();
const claims = (t) => JSON.parse(Buffer.from(t.split('.')[1], 'base64url').toString());
const apres = claims(neuf.access_token);
const garder = (c) => ({ role: c.role, app_metadata: c.app_metadata, user_role: c.user_role, aal: c.aal, amr: c.amr, session_id: c.session_id ? 'oui' : 'non', autres: Object.keys(c).sort().join(',') });
p.dire(`Claims d'origine : ${JSON.stringify(garder(res.avant))}`);
p.dire(`Claims renouveles : ${JSON.stringify(garder(apres))}`);
await a.page.evaluate(([cle, s]) => localStorage.setItem(cle, JSON.stringify(s)), [res.cle, { ...res.s, ...neuf, expires_at: neuf.expires_at }]);
await a.page.reload(); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
await p.capture(a, 'rechargement_jeton_renouvele');
p.dire(`Apres rechargement avec le jeton renouvele : ${a.page.url()} ; ${(await libelles(a.page)).slice(0, 3).join(' | ')}`);
await a.page.goto('http://127.0.0.1:8090/'); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
p.dire(`Apres ouverture de la racine : ${a.page.url()} ; ${(await libelles(a.page)).slice(0, 3).join(' | ')}`);
await p.capture(a, 'racine_jeton_renouvele');
await p.fin('joué');
