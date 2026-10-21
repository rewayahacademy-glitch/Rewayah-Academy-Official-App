/*
 * Couche de mouvement du site public.
 *
 * Le defilement reste natif : rien n'intercepte la molette ni le toucher
 * (SITE_03, dossier maitre 17.5). Les scenes lisent seulement la position de la
 * page et posent des variables CSS ; la feuille de style decide du dessin.
 * Sans JavaScript, ou quand le systeme demande de reduire le mouvement, tout le
 * contenu est la, immobile. Le logo ne bouge jamais.
 */
(function () {
  'use strict';
  window.__mv = true;
  var racine = document.documentElement;
  racine.classList.add('js');

  var reduit = window.matchMedia('(prefers-reduced-motion: reduce)');
  var large = window.matchMedia('(min-width: 840px)');
  var borne = function (v) { return v < 0 ? 0 : v > 1 ? 1 : v; };
  var adoucie = function (t) { return 1 - Math.pow(1 - t, 3); };

  /* En-tete : un fond plein des que la page a quitte son haut. */
  var entete = document.querySelector('[data-entete]');
  var contenu = document.querySelector('.site-main');

  /* Entrees des sections : titre, puis texte, puis image, une seule fois. */
  function preparerEntrees() {
    document.querySelectorAll('[data-revele-enfants]').forEach(function (bloc) {
      Array.prototype.forEach.call(bloc.children, function (enfant, i) { enfant.style.setProperty('--rang', String(Math.min(i, 5))); });
    });
    var elements = document.querySelectorAll('[data-revele], [data-revele-enfants]');
    var rangs = new Map();
    elements.forEach(function (el) {
      if (!el.hasAttribute('data-revele')) return;
      var parent = el.parentElement;
      var rang = rangs.get(parent) || 0;
      el.style.setProperty('--rang', String(Math.min(rang, 5)));
      rangs.set(parent, rang + 1);
    });
    if (!('IntersectionObserver' in window) || reduit.matches) {
      elements.forEach(function (el) { el.classList.add('est-visible'); });
      return;
    }
    var vue = new IntersectionObserver(function (entrees) {
      entrees.forEach(function (entree) {
        if (entree.isIntersecting) {
          entree.target.classList.add('est-visible');
          vue.unobserve(entree.target);
        }
      });
    }, { rootMargin: '0px 0px -12% 0px', threshold: 0.01 });
    elements.forEach(function (el) { vue.observe(el); });
  }

  /* Titres ligne a ligne : le texte reste le meme, on l'entoure seulement. */
  function decouper(titre) {
    var texte = titre.getAttribute('data-texte') || titre.textContent;
    titre.setAttribute('data-texte', texte);
    titre.textContent = '';
    var mots = texte.split(/\s+/).filter(Boolean);
    var spans = mots.map(function (mot, i) {
      var s = document.createElement('span');
      s.textContent = mot + (i < mots.length - 1 ? ' ' : '');
      titre.appendChild(s);
      return s;
    });
    var lignes = [];
    var haut = null;
    spans.forEach(function (s) {
      if (haut === null || Math.abs(s.offsetTop - haut) > 4) { lignes.push([]); haut = s.offsetTop; }
      lignes[lignes.length - 1].push(s.textContent);
    });
    titre.textContent = '';
    lignes.forEach(function (ligne, i) {
      var l = document.createElement('span');
      l.className = 'ligne';
      var dedans = document.createElement('span');
      dedans.className = 'ligne__in';
      dedans.style.setProperty('--rang', String(i));
      dedans.textContent = ligne.join('');
      l.appendChild(dedans);
      titre.appendChild(l);
    });
  }

  function preparerTitres() {
    if (reduit.matches) return;
    var titres = Array.prototype.map.call(document.querySelectorAll('[data-lignes]'), function (bloc) { return bloc.querySelector('h1'); }).filter(Boolean);
    /* Le titre ne se decoupe que si les polices arrivent tout de suite. Sinon il reste tel quel : un titre
       deja peint ne doit jamais disparaitre pour rejouer son entree (ni flash, ni decalage de mise en page). */
    var trop_tard = false;
    var faire = function () {
      if (trop_tard) return;
      titres.forEach(decouper);
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { titres.forEach(function (t) { t.classList.add('est-dit'); }); });
      });
    };
    if (document.fonts && document.fonts.status !== 'loaded') {
      setTimeout(function () { trop_tard = document.fonts.status !== 'loaded'; }, 100);
      document.fonts.ready.then(faire);
    } else { faire(); }
    var attente = null;
    var derniereLargeur = window.innerWidth;
    window.addEventListener('resize', function () {
      if (window.innerWidth === derniereLargeur) return;
      derniereLargeur = window.innerWidth;
      clearTimeout(attente);
      attente = setTimeout(function () { titres.forEach(decouper); titres.forEach(function (t) { t.classList.add('est-dit'); }); }, 150);
    });
  }

  /* Les scenes liees au defilement : une seule boucle, lue a chaque image. */
  var porte = document.querySelector('[data-porte]');
  var chapitres = document.querySelector('.chapitres');
  var imagesChapitres = chapitres ? chapitres.querySelectorAll('[data-chapitre-image]') : [];
  var textesChapitres = chapitres ? chapitres.querySelectorAll('[data-chapitre]') : [];
  var parallaxes = document.querySelectorAll('[data-parallaxe]');
  var bandes = document.querySelectorAll('.bande-image--large');
  var appels = document.querySelectorAll('.appel__lien');
  var demande = false;

  function scenePorte(h) {
    if (!porte || !large.matches) return;
    var r = porte.getBoundingClientRect();
    var course = r.height - h;
    if (course <= 0) return;
    var p = borne(-r.top / course);
    var z = borne(p / 0.62);
    var c = adoucie(borne((p - 0.46) / 0.42));
    porte.style.setProperty('--z', z.toFixed(4));
    porte.style.setProperty('--z2', (z * z).toFixed(4));
    porte.style.setProperty('--c', c.toFixed(4));
    if (z > 0.28) porte.setAttribute('data-passee', ''); else porte.removeAttribute('data-passee');
    if (c > 0.3) porte.setAttribute('data-cercle', ''); else porte.removeAttribute('data-cercle');
  }

  function sceneChapitres(h) {
    if (!chapitres || !large.matches || !textesChapitres.length) return;
    var milieu = h / 2;
    var centres = Array.prototype.map.call(textesChapitres, function (t) {
      var r = t.getBoundingClientRect();
      return r.top + r.height / 2;
    });
    var position = 0;
    for (var i = 0; i < centres.length - 1; i++) {
      if (milieu >= centres[i]) position = i + borne((milieu - centres[i]) / (centres[i + 1] - centres[i]));
    }
    imagesChapitres.forEach(function (img, j) {
      img.style.setProperty('--o', borne(1 - Math.abs(position - j) * 1.8 + 0.4).toFixed(3));
    });
  }

  function sceneParallaxes(h) {
    parallaxes.forEach(function (el) {
      var r = el.getBoundingClientRect();
      if (r.bottom < 0 || r.top > h) return;
      el.style.setProperty('--par', ((r.top + r.height / 2 - h / 2) * 0.06).toFixed(1));
    });
    bandes.forEach(function (el) {
      var r = el.getBoundingClientRect();
      if (r.bottom < 0 || r.top > h) return;
      var t = borne((h - r.top) / (h + r.height));
      el.style.setProperty('--pan', ((0.5 - t) * 160).toFixed(1));
    });
    appels.forEach(function (el) {
      var r = el.getBoundingClientRect();
      el.style.setProperty('--v', adoucie(borne((h - r.top) / (h * 0.6))).toFixed(3));
    });
  }

  /* L'en-tete s'efface en descendant et revient en remontant ; jamais menu ouvert, jamais mouvement reduit. */
  var dernierY = window.scrollY;
  function enteteSuit(y) {
    if (y > 8) entete.setAttribute('data-flotte', ''); else entete.removeAttribute('data-flotte');
    var menuOuvert = entete.querySelector('details[open]');
    /* Un seul logo visible a la fois : l'en-tete s'efface aussi quand le pied de page se decouvre, c'est-a-dire
       quand la fin du contenu remonte dans l'ecran (le pied peut etre colle au bas de l'ecran, sous le contenu). */
    var piedVisible = contenu && contenu.getBoundingClientRect().bottom < window.innerHeight - 40;
    if (!menuOuvert && (piedVisible || (!reduit.matches && y > 480 && y > dernierY + 4))) entete.setAttribute('data-cache', '');
    else if (!piedVisible && (y < dernierY - 4 || y <= 480 || menuOuvert || reduit.matches)) entete.removeAttribute('data-cache');
    dernierY = y;
  }

  function image() {
    demande = false;
    var h = window.innerHeight;
    if (entete) enteteSuit(window.scrollY);
    if (reduit.matches) return;
    scenePorte(h);
    sceneChapitres(h);
    sceneParallaxes(h);
  }

  function auDefilement() {
    if (!demande) { demande = true; requestAnimationFrame(image); }
  }

  /* Sommaire des pages longues : la section lue est marquee. */
  function preparerSommaire() {
    var liens = document.querySelectorAll('.lecture__sommaire a');
    if (!liens.length || !('IntersectionObserver' in window)) return;
    var parCible = {};
    liens.forEach(function (a) { parCible[a.getAttribute('href').slice(1)] = a; });
    var vue = new IntersectionObserver(function (entrees) {
      entrees.forEach(function (entree) {
        if (!entree.isIntersecting) return;
        liens.forEach(function (a) { a.removeAttribute('aria-current'); });
        var a = parCible[entree.target.id];
        if (a) a.setAttribute('aria-current', 'true');
      });
    }, { rootMargin: '-30% 0px -60% 0px' });
    document.querySelectorAll('.lecture__section').forEach(function (s) { vue.observe(s); });
  }

  /* Une seule question ouverte a la fois, meme ou l'attribut name n'est pas encore pris en charge. */
  function preparerTuiles() {
    document.querySelectorAll('details.tuile[name]').forEach(function (d) {
      d.addEventListener('toggle', function () {
        if (!d.open) return;
        document.querySelectorAll('details.tuile[name="' + d.getAttribute('name') + '"]').forEach(function (autre) {
          if (autre !== d) autre.open = false;
        });
      });
    });
  }

  preparerEntrees();
  preparerTitres();
  preparerSommaire();
  preparerTuiles();
  window.addEventListener('scroll', auDefilement, { passive: true });
  window.addEventListener('resize', auDefilement, { passive: true });
  reduit.addEventListener('change', auDefilement);
  large.addEventListener('change', auDefilement);
  image();
})();
