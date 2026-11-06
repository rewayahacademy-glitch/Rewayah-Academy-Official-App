/* Avis en direct (directeur, 06/11/2026) : la page affiche les avis publies sans attendre une mise en production.
 *
 * La page porte deja les avis lus au moment de la construction (pour les moteurs de recherche, et si la base ne repond
 * pas). Ce script demande ensuite la liste a jour a la seule fonction publique `avis_publics()`, avec la cle publiable,
 * et remplace les cartes si la liste a change. Protections, une par risque :
 *  - injection de code : un avis est toujours ecrit comme du texte (textContent, createElement), jamais comme du HTML ;
 *  - reponse inattendue : memes controles que la construction (cles exactes, types, bornes) ; un seul defaut et rien
 *    ne change a l'ecran ;
 *  - base lente ou absente : 6 secondes au plus, puis la page garde ce qu'elle avait ; aucune erreur visible ;
 *  - charge sur la base : une demande par visite au plus toutes les 5 minutes (memoire de l'onglet) ;
 *  - vie privee : aucun cookie envoye (credentials: 'omit'), aucune page d'origine transmise (no-referrer) ;
 *  - redirection piegee : refusee (redirect: 'error') ; reponse plus grosse que 1 Mo : ignoree.
 */
(function () {
  'use strict';

  var CLES = ['depuis', 'nom', 'note', 'pays', 'publie_le', 'qualite', 'texte', 'titre'];
  var QUALITES = ['parent', 'eleve_adulte'];
  var AVIS_MAX = 200;
  var TAILLE_MAX = 1024 * 1024;
  var DELAI_MS = 6000;
  var MEMOIRE_MS = 5 * 60 * 1000;
  var ECHEC_MS = 60 * 1000;     // apres un echec, une minute sans redemander : une base en panne n'est pas sollicitee

  // Longueurs en caracteres (points de code), comme Python : un emoji compte pour un.
  function longueur(v) { return Array.from(v).length; }

  function chaine(v, bas, haut) {
    return typeof v === 'string' && longueur(v) <= haut && longueur(v.trim()) >= bas;
  }

  function dateIso(v) {
    if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}/.test(v)) return null;
    var a = +v.slice(0, 4), m = +v.slice(5, 7), j = +v.slice(8, 10);
    var d = new Date(Date.UTC(a, m - 1, j));
    if (d.getUTCFullYear() !== a || d.getUTCMonth() !== m - 1 || d.getUTCDate() !== j) return null;
    return { annee: a, mois: m, jour: j };
  }

  function entier(v) {
    return typeof v === 'number' && Math.floor(v) === v && isFinite(v);
  }

  /* Les memes regles que bloc_avis.valider_avis (construction du site). Rend la reponse, ou null si quoi que ce soit cloche. */
  function valider(brut) {
    if (!brut || typeof brut !== 'object' || Array.isArray(brut)) return null;
    if (Object.keys(brut).sort().join() !== 'avis,moyenne_dixiemes,nombre') return null;
    var n = brut.nombre, moyenne = brut.moyenne_dixiemes, liste = brut.avis;
    if (!entier(n) || n < 0) return null;
    if (!Array.isArray(liste) || liste.length > AVIS_MAX || liste.length > n) return null;
    if (n === 0) {
      if (moyenne !== null || liste.length) return null;
    } else if (!entier(moyenne) || moyenne < 10 || moyenne > 50) {
      return null;
    }
    for (var i = 0; i < liste.length; i++) {
      var a = liste[i];
      if (!a || typeof a !== 'object' || Array.isArray(a)) return null;
      if (Object.keys(a).sort().join() !== CLES.join()) return null;
      if (!chaine(a.nom, 2, 60)) return null;
      if (QUALITES.indexOf(a.qualite) < 0) return null;
      if (typeof a.pays !== 'string' || !/^[A-Z]{2}$/.test(a.pays)) return null;
      var depuis = dateIso(a.depuis);
      if (!depuis || depuis.jour !== 1 || depuis.annee < 2015) return null;
      if (!entier(a.note) || a.note < 1 || a.note > 5) return null;
      if (a.titre !== null && !chaine(a.titre, 0, 80)) return null;
      if (!chaine(a.texte, 20, 1500)) return null;
      if (!dateIso(a.publie_le)) return null;
    }
    return brut;
  }

  /* Ce qui distingue deux listes a l'ecran : si rien n'a change, on ne touche a rien. */
  function signature(avis) {
    return avis.nombre + '|' + avis.avis.map(function (a) { return a.publie_le.slice(0, 10) + '~' + a.nom + '~' + longueur(a.texte); }).join('|');
  }

  function remplir(modele, valeurs) {
    return modele.replace(/\{(\w+)\}/g, function (_, k) { return valeurs[k] === undefined ? '' : String(valeurs[k]); });
  }

  function fmtMois(c, iso) {
    var d = dateIso(iso);
    var mois = c.mois[d.mois - 1];
    return c.langue === 'es' || c.langue === 'pt' ? mois + ' de ' + d.annee : mois + ' ' + d.annee;
  }

  function fmtDate(c, iso) {
    var d = dateIso(iso);
    var mois = c.mois[d.mois - 1];
    if (c.langue === 'fr') return (d.jour === 1 ? '1er' : d.jour) + ' ' + mois + ' ' + d.annee;
    return c.langue === 'es' || c.langue === 'pt' ? d.jour + ' de ' + mois + ' de ' + d.annee : d.jour + ' ' + mois + ' ' + d.annee;
  }

  function fmtMoyenne(c, dixiemes) {
    var e = Math.floor(dixiemes / 10), r = dixiemes % 10;
    return e + (c.langue === 'en' || c.langue === 'ar' ? '.' : ',') + r;
  }

  function nomPays(c, code) {
    if (c.pays && Object.prototype.hasOwnProperty.call(c.pays, code)) return c.pays[code];
    try { return new Intl.DisplayNames([c.langue], { type: 'region' }).of(code) || code; } catch (e) { return code; }
  }

  function initiale(nom) {
    var t = nom.trim();
    for (var i = 0; i < t.length; i++) {
      var ch = t.charAt(i);
      if (ch.toLowerCase() !== ch.toUpperCase()) return ch.toUpperCase();
    }
    return '·';
  }

  var SVG = 'http://www.w3.org/2000/svg';
  var POINTS = '12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26';

  function el(nom, classe, texte) {
    var e = document.createElement(nom);
    if (classe) e.className = classe;
    if (texte !== undefined) e.textContent = texte;
    return e;
  }

  function etoiles(conteneur, pleines) {
    for (var i = 0; i < 5; i++) {
      var s = document.createElementNS(SVG, 'svg');
      s.setAttribute('class', 'etoile ' + (i < pleines ? 'etoile--pleine' : 'etoile--vide'));
      s.setAttribute('viewBox', '0 0 24 24');
      s.setAttribute('aria-hidden', 'true');
      s.setAttribute('focusable', 'false');
      var p = document.createElementNS(SVG, 'polygon');
      p.setAttribute('points', POINTS);
      s.appendChild(p);
      conteneur.appendChild(s);
    }
    return conteneur;
  }

  /* Une carte, comme bloc_avis._un_avis : tout le texte de l'avis passe par textContent. */
  function carte(c, a) {
    var t = c.textes;
    var art = el('article', 'avis-carte');
    var g = el('span', 'avis-guillemet', '“');
    g.setAttribute('aria-hidden', 'true');
    art.appendChild(g);
    var note = el('span', 'avis-note');
    note.setAttribute('role', 'img');
    note.setAttribute('aria-label', remplir(t.note, { n: a.note }));
    art.appendChild(etoiles(note, a.note));
    if (a.titre) art.appendChild(el('h3', '', a.titre));
    var bq = el('blockquote', 'avis-texte');
    var p = el('p');
    a.texte.replace(/\r\n?/g, '\n').split('\n').forEach(function (ligne, i) {
      if (i) p.appendChild(document.createElement('br'));
      p.appendChild(document.createTextNode(ligne));
    });
    bq.appendChild(p);
    art.appendChild(bq);
    var pied = el('footer', 'avis-auteur');
    var ini = el('span', 'avis-initiale', initiale(a.nom));
    ini.setAttribute('aria-hidden', 'true');
    pied.appendChild(ini);
    var qui = el('div');
    qui.appendChild(el('strong', '', a.nom));
    qui.appendChild(el('span', '', nomPays(c, a.pays) + ' · ' + t[a.qualite] + (c.langue === 'ar' ? '، ' : ', ') + remplir(t.depuis, { mois: fmtMois(c, a.depuis) })));
    qui.appendChild(el('span', 'avis-date', remplir(t.publie, { date: fmtDate(c, a.publie_le) })));
    pied.appendChild(qui);
    art.appendChild(pied);
    return art;
  }

  function entete(c, avis) {
    var t = c.textes, n = avis.nombre;
    if (n >= c.seuils.moyenne) {
      var bloc = el('div', 'avis-moyenne');
      bloc.setAttribute('role', 'group');
      bloc.setAttribute('aria-label', remplir(t.resume, { m: fmtMoyenne(c, avis.moyenne_dixiemes), n: n }));
      var ligne = el('p', 'avis-moyenne__note');
      ligne.setAttribute('aria-hidden', 'true');
      ligne.appendChild(el('span', 'avis-moyenne__chiffre', fmtMoyenne(c, avis.moyenne_dixiemes)));
      ligne.appendChild(etoiles(el('span', 'avis-note'), Math.round(avis.moyenne_dixiemes / 10)));
      bloc.appendChild(ligne);
      var texte = el('p', 'avis-moyenne__texte', remplir(t.moyenne, { n: n }));
      texte.setAttribute('aria-hidden', 'true');
      bloc.appendChild(texte);
      return bloc;
    }
    return el('p', 'avis-intro', remplir(n > 1 ? t.intro : t.intro1, { n: n }));
  }

  function grille(c, liste, revelee) {
    var g = el('div', 'avis-grille');
    liste.forEach(function (a) { g.appendChild(carte(c, a)); });
    if (revelee) { g.setAttribute('data-revele-enfants', ''); g.classList.add('est-visible'); }
    return g;
  }

  function afficher(c, avis) {
    // La page des avis : l'en-tete (nombre ou moyenne) et toutes les cartes.
    var liste = document.querySelector('[data-avis-liste]');
    if (liste) {
      var morceaux = avis.nombre ? [entete(c, avis), grille(c, avis.avis, false)] : [el('p', '', c.textes.vide)];
      while (liste.firstChild) liste.removeChild(liste.firstChild);
      morceaux.forEach(function (m) { liste.appendChild(m); });
    }
    // L'apercu des autres pages : les plus recents, montre des le seuil.
    var apercu = document.querySelector('[data-avis-apercu]');
    if (apercu) {
      var ancienne = apercu.querySelector('.avis-grille');
      var assez = avis.nombre >= c.seuils.apercu && avis.avis.length >= c.seuils.apercu;
      if (ancienne) ancienne.parentNode.replaceChild(grille(c, avis.avis.slice(0, c.seuils.apercu_max), true), ancienne);
      apercu.hidden = !assez;
      if (assez) apercu.querySelectorAll('[data-revele]').forEach(function (e) { e.classList.add('est-visible'); });
    }
  }

  function lireMemoire(cle) {
    try {
      var m = JSON.parse(sessionStorage.getItem(cle) || 'null');
      if (!m) return null;
      if (m.echec) return Date.now() - m.t < ECHEC_MS ? '' : null;
      return Date.now() - m.t < MEMOIRE_MS ? m.texte : null;
    } catch (e) { return null; }
  }

  function ecrireMemoire(cle, texte) {
    try { sessionStorage.setItem(cle, JSON.stringify({ t: Date.now(), texte: texte })); } catch (e) { /* memoire indisponible */ }
  }

  function traiter(c, texte) {
    if (typeof texte !== 'string' || texte.length > TAILLE_MAX) return;
    var avis;
    try { avis = valider(JSON.parse(texte)); } catch (e) { return; }
    if (!avis || signature(avis) === c.signature) return;
    afficher(c, avis);
  }

  function demarrer() {
    var bloc = document.getElementById('avis-direct');
    if (!bloc || typeof fetch !== 'function') return;
    var c;
    try { c = JSON.parse(bloc.textContent); } catch (e) { return; }
    if (!c || typeof c.url !== 'string' || c.url.indexOf('https://') !== 0 || typeof c.cle !== 'string') return;
    var cleMemoire = 'ra-avis:' + c.url;
    var memoire = lireMemoire(cleMemoire);
    if (memoire !== null) { if (memoire) traiter(c, memoire); return; }
    var arret = typeof AbortController === 'function' ? new AbortController() : null;
    var minuterie = setTimeout(function () { if (arret) arret.abort(); }, DELAI_MS);
    fetch(c.url, {
      method: 'POST', body: '{}', mode: 'cors', credentials: 'omit', cache: 'no-store', redirect: 'error',
      referrerPolicy: 'no-referrer', signal: arret ? arret.signal : undefined,
      headers: { 'apikey': c.cle, 'Content-Type': 'application/json', 'Accept': 'application/json' }
    }).then(function (r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      var taille = +(r.headers.get('content-length') || 0);
      if (taille > TAILLE_MAX) throw new Error('trop gros');
      return r.text();
    }).then(function (texte) {
      clearTimeout(minuterie);
      if (texte.length > TAILLE_MAX) return;
      ecrireMemoire(cleMemoire, texte);
      traiter(c, texte);
    }).catch(function () {
      clearTimeout(minuterie);   // la page garde les avis de la construction
      try { sessionStorage.setItem(cleMemoire, JSON.stringify({ t: Date.now(), echec: true })); } catch (e) { /* memoire indisponible */ }
    });
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { valider: valider, signature: signature, fmtDate: fmtDate, fmtMois: fmtMois, fmtMoyenne: fmtMoyenne, remplir: remplir };
  } else if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', demarrer);
  } else {
    demarrer();
  }
})();
