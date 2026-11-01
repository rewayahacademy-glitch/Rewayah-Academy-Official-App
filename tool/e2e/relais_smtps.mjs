// Relais SMTPS local pour les e-mails des fonctions Edge (courriels-envoi).
// Le transport de l'application parle en TLS implicite (port 465) avec des
// identifiants (`secure: true`, `auth`) ; le Mailpit de la pile locale parle en
// clair, sans authentification. Ce relais termine le TLS, annonce AUTH, accepte
// tout identifiant (local seulement) et transmet le reste a Mailpit.
// Usage : node relais_smtps.mjs <cert.pem> <cle.pem> <ecoute ip:port> <mailpit ip:port>
import tls from 'node:tls';
import net from 'node:net';
import fs from 'node:fs';

const [cert, cle, ecoute, cible] = process.argv.slice(2);
const [hoteE, portE] = ecoute.split(':');
const [hoteC, portC] = cible.split(':');

tls.createServer({ cert: fs.readFileSync(cert), key: fs.readFileSync(cle) }, (client) => {
  const amont = net.connect(Number(portC), hoteC);
  let tamponC = '';
  let tamponA = '';
  let auth = null; // 'login-user' | 'login-pass'
  amont.on('data', (d) => {
    tamponA += d.toString('utf8');
    let i;
    while ((i = tamponA.indexOf('\r\n')) >= 0) {
      let ligne = tamponA.slice(0, i + 2);
      tamponA = tamponA.slice(i + 2);
      // Fin de la reponse EHLO : on annonce AUTH avant la derniere ligne.
      if (/^250 /.test(ligne) && amont.ehlo) { client.write('250-AUTH PLAIN LOGIN\r\n'); amont.ehlo = false; }
      client.write(ligne);
    }
  });
  client.on('data', (d) => {
    tamponC += d.toString('utf8');
    let i;
    while ((i = tamponC.indexOf('\r\n')) >= 0) {
      const ligne = tamponC.slice(0, i + 2);
      tamponC = tamponC.slice(i + 2);
      if (auth === 'login-user') { auth = 'login-pass'; client.write('334 UGFzc3dvcmQ6\r\n'); continue; }
      if (auth === 'login-pass') { auth = null; client.write('235 2.7.0 Authentication successful\r\n'); continue; }
      if (/^AUTH PLAIN/i.test(ligne)) { client.write('235 2.7.0 Authentication successful\r\n'); continue; }
      if (/^AUTH LOGIN/i.test(ligne)) { auth = 'login-user'; client.write('334 VXNlcm5hbWU6\r\n'); continue; }
      if (/^EHLO/i.test(ligne)) amont.ehlo = true;
      amont.write(ligne);
    }
  });
  const fin = () => { client.destroy(); amont.destroy(); };
  amont.on('error', fin); client.on('error', fin); amont.on('close', fin); client.on('close', fin);
}).listen(Number(portE), hoteE, () => console.log(`smtps://${ecoute} -> smtp://${cible}`));
