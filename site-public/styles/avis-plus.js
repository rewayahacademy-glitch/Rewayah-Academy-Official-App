/* Avis : textes longs repliables, liste montree par paquets (SITE-CORRECTIFS 6, directeur, 22/11/2026).
 *
 * Amelioration progressive : sans JavaScript, tous les avis sont la, en entier. Avec JavaScript :
 *  - un avis qui depasse 4 lignes est replie, avec un vrai bouton « Lire la suite » (aria-expanded, aria-controls, clavier natif) ;
 *  - la page des avis montre les 6 premiers, puis un bouton « Voir plus d'avis » en ajoute 6 ; le focus passe au premier
 *    avis ajoute, pour qu'un lecteur d'ecran ou le clavier continue la ou la liste s'est allongee.
 * Les textes du bouton viennent de la page (attributs data-* de cette balise script), dans la langue de la page.
 * Le texte d'un avis n'est jamais modifie : seule sa hauteur change (line-clamp), le contenu reste dans la page.
 * avis.js, quand il remet la liste a jour, rappelle window.ameliorerAvis().
 */
(function () {
  'use strict';
  var script = document.currentScript;
  var T = {
    lire: (script && script.dataset.lire) || 'Lire la suite',
    reduire: (script && script.dataset.reduire) || 'Réduire',
    plus: (script && script.dataset.plus) || 'Voir plus d’avis'
  };
  var PAR_PAQUET = 6;
  var compteur = 0;

  function plusieursFois(rappel) {
    var attente = false;
    return function () {
      if (attente) return;
      attente = true;
      requestAnimationFrame(function () { attente = false; rappel(); });
    };
  }

  /* Un avis : replie s'il depasse, avec son bouton. Lecture (mesure) avant ecriture, une carte a la fois. */
  function mesurer(carte) {
    var texte = carte.querySelector('.avis-texte');
    if (!texte || carte.hidden) return;
    var bouton = carte.querySelector('.avis-lire');
    if (bouton && bouton.getAttribute('aria-expanded') === 'true') return;   // un avis ouvert reste ouvert
    texte.setAttribute('data-court', '');
    var p = texte.querySelector('p');
    var trop = p && p.scrollHeight > p.clientHeight + 1;
    if (!trop) {
      texte.removeAttribute('data-court');
      if (bouton) bouton.remove();
      return;
    }
    if (bouton) return;
    if (!texte.id) texte.id = 'avis-texte-' + (++compteur);
    bouton = document.createElement('button');
    bouton.type = 'button';
    bouton.className = 'avis-lire';
    bouton.setAttribute('aria-expanded', 'false');
    bouton.setAttribute('aria-controls', texte.id);
    bouton.textContent = T.lire;
    bouton.addEventListener('click', function () {
      var ouvert = bouton.getAttribute('aria-expanded') === 'true';
      bouton.setAttribute('aria-expanded', ouvert ? 'false' : 'true');
      bouton.textContent = ouvert ? T.lire : T.reduire;
      if (ouvert) texte.setAttribute('data-court', ''); else texte.removeAttribute('data-court');
    });
    texte.insertAdjacentElement('afterend', bouton);
  }

  function replierTout() {
    var cartes = Array.prototype.slice.call(document.querySelectorAll('.avis-carte'));
    cartes.forEach(mesurer);
  }

  /* La page des avis : six avis, puis des paquets de six. */
  function paquets() {
    var liste = document.querySelector('[data-avis-liste]');
    if (!liste) return;
    var grille = liste.querySelector('.avis-grille');
    if (!grille || grille.hasAttribute('data-paquets')) return;
    grille.setAttribute('data-paquets', '');
    var cartes = Array.prototype.slice.call(grille.children);
    if (cartes.length <= PAR_PAQUET) return;
    cartes.slice(PAR_PAQUET).forEach(function (c) { c.hidden = true; });
    var bouton = document.createElement('button');
    bouton.type = 'button';
    bouton.className = 'avis-plus cta cta--secondary';
    bouton.textContent = T.plus;
    bouton.addEventListener('click', function () {
      var caches = cartes.filter(function (c) { return c.hidden; });
      var paquet = caches.slice(0, PAR_PAQUET);
      paquet.forEach(function (c) { c.hidden = false; });
      paquet.forEach(mesurer);
      if (caches.length <= PAR_PAQUET) {
        bouton.remove();
      }
      var premier = paquet[0];
      if (premier) { premier.tabIndex = -1; premier.focus({ preventScroll: false }); }
    });
    grille.insertAdjacentElement('afterend', bouton);
  }

  function ameliorer() {
    paquets();
    replierTout();
  }

  window.ameliorerAvis = ameliorer;
  var remesurer = plusieursFois(replierTout);
  window.addEventListener('resize', remesurer, { passive: true });
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(remesurer);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', ameliorer); else ameliorer();
  window.addEventListener('load', remesurer);
})();
