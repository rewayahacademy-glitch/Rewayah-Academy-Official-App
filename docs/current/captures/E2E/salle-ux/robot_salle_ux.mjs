// Robot SALLE-UX (lot 11) sur la pile LOCALE : enseignant seul.
// UX-040 (fin apres « Quitter », seance encore en cours) puis UX-043 (seance
// close par le serveur, connexion tombee). Usage : node salle_ux.mjs <390|1440> <classe>
import crypto from 'node:crypto';
import { parcours, connecter, trouver, trouverTexte, libelles, sql, activerSemantique, COMPTES }
  from '/home/user/Rewayah-Academy-Official-App/tool/e2e/commun.mjs';
const largeur = process.argv[2] ?? '1440';
const classe = process.argv[3];
const telephone = largeur === '390';
const q = await parcours(`SALLE-UX robot ${largeur}`, `salle-ux/robot-${largeur}`);
const groupe = `(select id from public.groupes where libelle = '${classe}' and ended_at is null limit 1)`;
const seance = sql(`select id from public.sessions where groupe_id = ${groupe} and deleted_at is null
  and status in ('planned','preflight','in_progress') order by abs(extract(epoch from started_at - now())) limit 1`);
if (!seance) process.exit(q.fin('rouge', `aucune seance pour ${classe}`));
sql(`update public.sessions set started_at = now() - interval '7 minutes', ended_at = now() + interval '2 minutes',
  join_opens_at = now() - interval '27 minutes' where id = '${seance}'`);
const fin = Date.parse(sql(`select to_char(ended_at at time zone 'utc','YYYY-MM-DD"T"HH24:MI:SS"Z"') from public.sessions where id = '${seance}'`));
q.dire(`Seance ${seance}, fin prevue ${new Date(fin).toISOString()}`);
const e = await q.contexte('enseignant', telephone ? { telephone: true } : { vue: { width: 1440, height: 900 } });
await connecter(e.page, COMPTES.enseignant);
let r = await trouver(e.page, new RegExp(`^Rejoindre la salle de la Classe ${classe}`), { delai: 20000 });
if (!r) { await q.capture(e, '00_journee'); process.exit(q.fin('rouge', `pas de « Rejoindre » ; ${(await libelles(e.page)).slice(0, 15).join(' | ')}`)); }
await r.click(); await e.page.waitForTimeout(9000); await activerSemantique(e.page);
await q.capture(e, '01_enseignant_en_salle');
// UX-040 : Quitter (confirmation), puis l'ecran de fin
const quitter = await trouver(e.page, /^Quitter/, { delai: 10000 });
if (quitter) { await quitter.click(); await e.page.waitForTimeout(1500); }
const confirmer = await trouver(e.page, /^Quitter/, { delai: 4000, role: 'button' });
if (confirmer) { await confirmer.click(); await e.page.waitForTimeout(5000); }
await activerSemantique(e.page);
const lus040 = (await libelles(e.page)).join(' | ');
await q.capture(e, '02_ux040_enseignant_apres_quitter');
const ok040 = /quitté la séance/.test(lus040) && !/Séance terminée/.test(lus040) && !/(^| )Terminée( |$)/.test(lus040);
const retour = /Retourner dans la salle/.test(lus040);
const barre = /Aujourd/.test(lus040);
q.dire(`UX-040 : « Vous avez quitté » ${/quitté la séance/.test(lus040)} ; « Séance terminée » ${/Séance terminée/.test(lus040)} ; « Retourner dans la salle » ${retour} ; barre de l'enseignant (Aujourd'hui) ${barre}`);
// Retour dans la salle, puis fin du serveur
const ret = await trouver(e.page, /^Retourner dans la salle/, { delai: 5000 });
if (ret) { await ret.click(); await e.page.waitForTimeout(9000); await activerSemantique(e.page); }
await q.capture(e, '03_enseignant_de_retour');
await e.page.waitForTimeout(Math.max(0, fin + 5000 - Date.now()));
sql(`update public.sessions set status = 'ended' where id = '${seance}' and status in ('in_progress','planned','preflight')`);
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const t = Math.floor(Date.now() / 1000);
const corps = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ iss: 'devkey', nbf: t - 10, exp: t + 300, video: { roomCreate: true, roomAdmin: true, roomList: true } })}`;
const jeton = `${corps}.${crypto.createHmac('sha256', 'secret_e2e_local_livekit_0123456789abcdef').update(corps).digest('base64url')}`;
const lk = (m, c) => fetch(`http://127.0.0.1:7880/twirp/livekit.RoomService/${m}`, { method: 'POST', headers: { Authorization: `Bearer ${jeton}`, 'Content-Type': 'application/json' }, body: JSON.stringify(c) });
const salles = ((await (await lk('ListRooms', {})).json()).rooms ?? []).map((x) => x.name);
for (const nom of salles) q.dire(`DeleteRoom ${nom} : HTTP ${(await lk('DeleteRoom', { room: nom })).status}`);
await e.page.waitForTimeout(12000); await activerSemantique(e.page);
await trouverTexte(e.page, /cahier de transmission/i, 20000);
const lus043 = (await libelles(e.page)).join(' | ');
await q.capture(e, '04_ux043_enseignant_seance_close');
const ok043 = /cahier de transmission/i.test(lus043) && !/Retourner dans la salle/.test(lus043);
const pastille = /En direct/.test(lus043);
q.dire(`UX-043 : cahier ${/cahier de transmission/i.test(lus043)} ; « Retourner dans la salle » ${/Retourner dans la salle/.test(lus043)} ; « En direct » ${pastille}`);
q.dire(`Libelles fin close : ${lus043.slice(0, 600)}`);
const manque = [!ok040 && 'UX-040', !retour && 'UX-040 retour', !ok043 && 'UX-043', pastille && 'En direct apres la fin'].filter(Boolean);
await q.fin(manque.length ? 'rouge' : 'vert', manque.join(', '));
