// PUSH-1 (07/11/2026, DECISION-PUSH-2026-11-01 §3.5) : le worker des
// notifications push, separe de flutter_service_worker.js (que le build
// regenere et qui se retire de lui-meme). Il ne met rien en cache et ne
// touche a aucune requete : il affiche un push recu et, au toucher, ouvre la
// page concernee de l'application.
//
// Charge utile (fonction Edge push-envoi, chiffree pour cet appareil) :
//   { titre, texte, destination, tag }
// Le texte ne contient jamais de nom, de montant ni de motif (garde-cap,
// 07/11) : le detail se lit dans l'application, apres connexion.
'use strict';

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

// Une destination de l'application : un chemin interne, jamais une adresse
// d'un autre site.
function cheminSur(destination) {
  if (typeof destination !== 'string') return '/';
  if (!/^\/[A-Za-z0-9\-_/]*$/.test(destination) || destination.indexOf('//') === 0) return '/';
  return destination;
}

// L'application route sur le fragment : /#/chemin.
function adresseDe(destination) {
  return new URL('./#' + cheminSur(destination), self.registration.scope).href;
}

self.addEventListener('push', function (event) {
  var donnees = {};
  try {
    donnees = event.data ? event.data.json() : {};
  } catch (e) {
    donnees = {};
  }
  var titre = typeof donnees.titre === 'string' && donnees.titre ? donnees.titre : 'Rewayah Academy';
  var options = {
    body: typeof donnees.texte === 'string' ? donnees.texte : '',
    icon: new URL('icons/Icon-192.png', self.registration.scope).href,
    badge: new URL('icons/Icon-maskable-192.png', self.registration.scope).href,
    data: { destination: cheminSur(donnees.destination) }
  };
  // Une etiquette remplace l'alerte precedente du meme sujet (« N nouvelles
  // candidatures a examiner ») et la fait de nouveau sonner.
  if (typeof donnees.tag === 'string' && donnees.tag) {
    options.tag = donnees.tag;
    options.renotify = true;
  }
  event.waitUntil(self.registration.showNotification(titre, options));
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var destination = (event.notification.data && event.notification.data.destination) || '/';
  var adresse = adresseDe(destination);
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (fenetres) {
      for (var i = 0; i < fenetres.length; i++) {
        var f = fenetres[i];
        if (new URL(f.url).origin === self.location.origin && 'focus' in f) {
          return f.focus().then(function (ouverte) {
            if (ouverte && 'navigate' in ouverte) {
              return ouverte.navigate(adresse).catch(function () {
                ouverte.postMessage({ type: 'rewayah-push-ouvrir', destination: cheminSur(destination) });
              });
            }
            return undefined;
          });
        }
      }
      return self.clients.openWindow(adresse);
    })
  );
});
