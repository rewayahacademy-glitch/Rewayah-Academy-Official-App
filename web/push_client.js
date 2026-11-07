// PUSH-1 (07/11/2026) : le pont entre l'application et le Web Push du
// navigateur, lu par lib/core/push/navigateur_push_web.dart. Rien ne se fait
// au demarrage : l'autorisation n'est demandee que par activer(), appelee
// depuis le geste de la personne (« Recevoir les notifications sur cet
// appareil »), et c'est son premier appel, sans attente avant lui (Safari
// exige que la demande suive directement le geste).
//
// Toutes les fonctions rendent une promesse de texte, simple a lire en Dart.
(function () {
  'use strict';

  var PORTEE = './';
  var WORKER = 'push_worker.js';

  function estIos() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  }

  function ouverteDepuisEcranAccueil() {
    return (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) ||
      navigator.standalone === true;
  }

  function prisEnCharge() {
    return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  }

  function octetsDe(base64url) {
    var b = base64url.replace(/-/g, '+').replace(/_/g, '/');
    while (b.length % 4) b += '=';
    var brut = atob(b);
    var o = new Uint8Array(brut.length);
    for (var i = 0; i < brut.length; i++) o[i] = brut.charCodeAt(i);
    return o;
  }

  function memeCle(abonnement, cle) {
    var actuelle = abonnement.options && abonnement.options.applicationServerKey;
    if (!actuelle) return true;
    var a = new Uint8Array(actuelle);
    var b = octetsDe(cle);
    if (a.length !== b.length) return false;
    for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
    return true;
  }

  function enregistrementActuel() {
    return navigator.serviceWorker.getRegistration(PORTEE).then(function (r) {
      return r && r.active && /push_worker\.js$/.test(r.active.scriptURL) ? r : null;
    });
  }

  function abonnementActuel() {
    return enregistrementActuel().then(function (r) {
      return r ? r.pushManager.getSubscription() : null;
    });
  }

  window.rewayahPush = {
    // « non_pris_en_charge », « ios_ecran_accueil », « refuse », « inactif »
    // ou « actif ».
    etat: function () {
      if (!prisEnCharge()) {
        return Promise.resolve(estIos() && !ouverteDepuisEcranAccueil() ? 'ios_ecran_accueil' : 'non_pris_en_charge');
      }
      if (Notification.permission === 'denied') return Promise.resolve('refuse');
      return abonnementActuel().then(function (a) {
        return a && Notification.permission === 'granted' ? 'actif' : 'inactif';
      }, function () { return 'inactif'; });
    },

    // L'adresse de l'abonnement de cet appareil, ou une chaine vide.
    adresse: function () {
      if (!prisEnCharge()) return Promise.resolve('');
      return abonnementActuel().then(function (a) { return a ? a.endpoint : ''; },
        function () { return ''; });
    },

    // Demande l'autorisation (premier appel, dans le geste), inscrit le
    // worker, abonne l'appareil avec la cle publique du serveur. Rend le JSON
    // { endpoint, p256dh, auth } ou { erreur : « refuse » | « ignore » |
    // « non_pris_en_charge » | « echec » }.
    activer: function (cle) {
      if (!prisEnCharge()) return Promise.resolve(JSON.stringify({ erreur: 'non_pris_en_charge' }));
      return Notification.requestPermission().then(function (permission) {
        if (permission !== 'granted') {
          return JSON.stringify({ erreur: permission === 'denied' ? 'refuse' : 'ignore' });
        }
        return navigator.serviceWorker.register(WORKER, { scope: PORTEE })
          .then(function () { return navigator.serviceWorker.ready; })
          .then(function (r) {
            return r.pushManager.getSubscription().then(function (a) {
              if (a && memeCle(a, cle)) return a;
              var suite = a ? a.unsubscribe() : Promise.resolve(true);
              return suite.then(function () {
                return r.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: octetsDe(cle) });
              });
            });
          })
          .then(function (a) {
            var j = a.toJSON();
            return JSON.stringify({ endpoint: j.endpoint, p256dh: j.keys.p256dh, auth: j.keys.auth });
          })
          .catch(function () { return JSON.stringify({ erreur: 'echec' }); });
      });
    },

    // Retire l'abonnement de cet appareil ; rend son adresse (ou vide).
    desactiver: function () {
      if (!prisEnCharge()) return Promise.resolve('');
      return abonnementActuel().then(function (a) {
        if (!a) return '';
        var adresse = a.endpoint;
        return a.unsubscribe().then(function () { return adresse; }, function () { return adresse; });
      }, function () { return ''; });
    },

    // Un nom court de l'appareil, sans donnee personnelle.
    appareil: function () {
      var ua = navigator.userAgent;
      if (/iPhone/.test(ua)) return 'iPhone';
      if (/iPad/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'iPad';
      if (/Android/.test(ua)) return 'Android';
      if (/Windows/.test(ua)) return 'Windows';
      if (/Mac OS X/.test(ua)) return 'Mac';
      if (/Linux/.test(ua)) return 'Linux';
      return 'Navigateur';
    }
  };

  // Le toucher d'une notification quand la fenetre ne peut pas naviguer :
  // l'application lit l'adresse et y va.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('message', function (e) {
      if (e.data && e.data.type === 'rewayah-push-ouvrir' && typeof e.data.destination === 'string') {
        window.location.hash = '#' + e.data.destination;
      }
    });
  }
})();
