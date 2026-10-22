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
    }, { rootMargin: '0px', threshold: 0 });
    elements.forEach(function (el) { vue.observe(el); });
  }

  /* Titres ligne a ligne : le texte reste le meme, on l'entoure seulement. */
  function decouper(titre) {
    var texte = titre.getAttribute('data-texte') || titre.textContent;
    titre.setAttribute('data-texte', texte);
    titre.textContent = '';
    var mots = texte.split(/[ \t\n\r]+/).filter(Boolean); // l'espace insecable reste dans le mot
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
  var mains = document.querySelectorAll('.scene[data-anime="mains"]');
  var demande = false;

  function scenePorte(h) {
    if (!porte || !large.matches) return;
    var r = porte.getBoundingClientRect();
    var course = r.height - h;
    if (course <= 0) return;
    var p = borne(-r.top / course);
    var z = borne(p / 0.62);
    /* La classe apparait avant que la porte ne soit tres agrandie : les visages restent petits. */
    var c = adoucie(borne((p - 0.42) / 0.42));
    porte.style.setProperty('--z', z.toFixed(4));
    porte.style.setProperty('--z2', (z * z).toFixed(4));
    porte.style.setProperty('--c', c.toFixed(4));
    if (z > 0.28) porte.setAttribute('data-passee', ''); else porte.removeAttribute('data-passee');
    if (c > 0.3) porte.setAttribute('data-cercle', ''); else porte.removeAttribute('data-cercle');
    if (c > 0.98) porte.setAttribute('data-plein', ''); else porte.removeAttribute('data-plein');
  }

  function sceneChapitres(h) {
    if (!chapitres || !large.matches || !textesChapitres.length) return;
    // Une seule illustration a la fois : elle change des que le titre du chapitre suivant passe 60 % de la hauteur
    // de l'ecran, pour que le texte et son image arrivent ensemble ; le fondu est porte par le CSS.
    var courante = 0;
    Array.prototype.forEach.call(textesChapitres, function (t, i) {
      var titre = t.querySelector('h2') || t;
      if (titre.getBoundingClientRect().top < h * 0.6) courante = i;
    });
    imagesChapitres.forEach(function (img, j) {
      img.style.setProperty('--o', j === courante ? '1' : '0');
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

  /* Les mains de l'eleve montent jusqu'au Coran. En haut de page, le contact se fait sur le premier tiers
     d'ecran defile ; plus bas, pendant la demi-hauteur d'ecran qui suit l'entree de l'image. */
  function sceneMains(h) {
    var y = window.scrollY;
    mains.forEach(function (fig) {
      // En haut de page, l'illustration se montre telle qu'elle est faite : les mains tiennent deja le livre.
      if (fig.closest('.entete-page')) { fig.style.setProperty('--m', '0'); return; }
      var haut = fig.getBoundingClientRect().top + y;
      var debut = haut < h ? 0 : haut - h;
      var fin = debut + (haut < h ? h * 0.35 : h * 0.5);
      fig.style.setProperty('--m', (1 - adoucie(borne((y - debut) / (fin - debut)))).toFixed(4));
    });
  }

  function image() {
    demande = false;
    var h = window.innerHeight;
    if (entete) enteteSuit(window.scrollY);
    if (reduit.matches) return;
    scenePorte(h);
    sceneChapitres(h);
    sceneParallaxes(h);
    sceneMains(h);
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

  /* Le tapis du chemin ondule doucement, sans fin : une onde qui court vers la porte. Il est dessine dans une toile
     posee sur sa zone ; le calque d'origine reste dans la page pour qui n'a pas de script. Un bouton l'arrete
     (WCAG 2.2.2) et le choix est garde. */
  function preparerTapis() {
    var figures = Array.prototype.slice.call(document.querySelectorAll('.scene[data-anime="tapis"]'));
    if (!figures.length || reduit.matches) return;
    var arret = false;
    try { arret = window.localStorage.getItem('rewayah-animation') === 'arret'; } catch (e) { arret = false; }
    var boutons = [];
    function etiquette() {
      boutons.forEach(function (bouton) {
        var texte = arret ? 'Relancer l’animation du tapis' : 'Arrêter l’animation du tapis';
        bouton.setAttribute('aria-pressed', arret ? 'true' : 'false');
        bouton.querySelector('.sr-only').textContent = texte;
        bouton.title = texte;
      });
    }
    function creerBouton(hote) {
      var bouton = document.createElement('button');
      bouton.type = 'button';
      bouton.className = 'pause-anim';
      bouton.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="pause-anim__pause" d="M8 5v14M16 5v14" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" fill="none"/><path class="pause-anim__lecture" d="M8 5.5v13l11-6.5z" fill="currentColor"/></svg><span class="sr-only"></span>';
      bouton.addEventListener('click', function () {
        arret = !arret;
        try { window.localStorage.setItem('rewayah-animation', arret ? 'arret' : 'marche'); } catch (e) { /* choix non garde */ }
        etiquette();
        lancer();
      });
      hote.appendChild(bouton);
      boutons.push(bouton);
    }
    var scenes = [];
    var visibles = new Set();
    var boucle = false;
    figures.forEach(function (fig) {
      var calque = fig.querySelector('.scene__calque--tapis');
      var cadre = fig.querySelector('.scene__cadre');
      if (!calque || !cadre) return;
      var cs = getComputedStyle(fig);
      var zone = ['--zx', '--zy', '--zl', '--zh'].map(function (n) { return parseFloat(cs.getPropertyValue(n)) || 0; });
      var toile = document.createElement('canvas');
      toile.className = 'scene__onde';
      toile.setAttribute('aria-hidden', 'true');
      var ctx = toile.getContext('2d');
      if (!ctx) return;
      var sc = { fig: fig, img: null, cadre: cadre, toile: toile, ctx: ctx, zone: zone, pret: false, l: 0, h: 0 };
      scenes.push(sc);
      /* La toile lit les pixels reels du fichier : avec srcset, naturalWidth est corrige par la densite. */
      var pret = function () {
        if (!calque.naturalWidth || sc.img) return;
        var source = new Image();
        source.decoding = 'async';
        source.onload = function () { sc.img = source; demarrer(); };
        source.src = calque.currentSrc || calque.src;
      };
      var demarrer = function () {
        cadre.appendChild(toile);
        sc.pret = true;
        dimensionner(sc);
        fig.setAttribute('data-onde', '');
        dessiner(sc, performance.now());
        if (visibles.has(fig)) lancer();
      };
      if (calque.complete && calque.naturalWidth) pret(); else calque.addEventListener('load', pret, { once: true });
    });
    function dimensionner(sc) {
      var r = Math.min(window.devicePixelRatio || 1, 2);
      sc.l = sc.cadre.offsetWidth * sc.zone[2];
      sc.h = sc.cadre.offsetHeight * sc.zone[3];
      sc.toile.width = Math.max(1, Math.round(sc.l * r));
      sc.toile.height = Math.max(1, Math.round(sc.h * r));
    }
    function pente(a, b, x) { var t = borne((x - a) / (b - a)); return t * t * (3 - 2 * t); }
    function dessiner(sc, t) {
      /* Colonnes de 2 pixels d'ecran, bord a bord : aucun recouvrement, donc aucune bande sombre aux bords. */
      var ctx = sc.ctx, img = sc.img, z = sc.zone;
      var nw = img.naturalWidth, nh = img.naturalHeight;
      var sx0 = z[0] * nw, sy0 = z[1] * nh, sw = z[2] * nw, sh = z[3] * nh;
      var lp = sc.toile.width, hp = sc.toile.height, r = lp / Math.max(sc.l, 1);
      var amp = sc.cadre.offsetWidth * 0.0042 * r;
      var s = t / 1000, col = 2;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, lp, hp);
      for (var x = 0; x < lp; x += col) {
        var u = z[0] + (x / lp) * z[2];
        var force = 1 - pente(0.06, 0.46, u);
        var onde = 0.5 + 0.37 * Math.sin(2 * Math.PI * (u / 0.2 - s / 7)) + 0.13 * Math.sin(2 * Math.PI * (u / 0.11 - s / 4.3) + 1.3);
        ctx.drawImage(img, sx0 + (x / lp) * sw, sy0, (col / lp) * sw, sh, x, amp * force * onde, col, hp);
      }
    }
    function tour(t) {
      if (arret || !visibles.size) { boucle = false; return; }
      scenes.forEach(function (sc) { if (sc.pret && visibles.has(sc.fig)) dessiner(sc, t); });
      requestAnimationFrame(tour);
    }
    function lancer() { if (!boucle && !arret) { boucle = true; requestAnimationFrame(tour); } }
    figures.forEach(function (fig) {
      var porte = fig.closest('.porte');
      creerBouton(porte ? porte.querySelector('.porte__texte') || fig : fig);
    });
    etiquette();
    if ('IntersectionObserver' in window) {
      var vue = new IntersectionObserver(function (entrees) {
        entrees.forEach(function (e) { if (e.isIntersecting) visibles.add(e.target); else visibles.delete(e.target); });
        lancer();
      });
      figures.forEach(function (fig) { vue.observe(fig); });
    }
    var attente = null;
    window.addEventListener('resize', function () {
      clearTimeout(attente);
      attente = setTimeout(function () { scenes.forEach(function (sc) { if (sc.pret) { dimensionner(sc); dessiner(sc, performance.now()); } }); }, 150);
    });
  }

  /* Halo : une lumiere douce suit la souris, avec un leger retard. Ambiance violette, souris seulement. */
  function preparerHalo() {
    var halo = document.querySelector('.halo');
    if (!halo || reduit.matches || !window.matchMedia('(hover: hover) and (pointer: fine)').matches) return;
    var cx = window.innerWidth * 0.72, cy = window.innerHeight * 0.28, tx = cx, ty = cy, actif = false;
    function pas() {
      cx += (tx - cx) * 0.12;
      cy += (ty - cy) * 0.12;
      halo.style.setProperty('--hx', cx.toFixed(1) + 'px');
      halo.style.setProperty('--hy', cy.toFixed(1) + 'px');
      if (Math.abs(tx - cx) > 0.5 || Math.abs(ty - cy) > 0.5) requestAnimationFrame(pas); else actif = false;
    }
    window.addEventListener('pointermove', function (e) {
      tx = e.clientX; ty = e.clientY;
      if (!actif) { actif = true; requestAnimationFrame(pas); }
    }, { passive: true });
  }

  /* Schema « la classe se forme » : les eleves (des points) rejoignent leur place autour de l'enseignant ; la classe
     ouvre au nombre d'inscrits requis. Joue une fois quand le schema entre a l'ecran, puis a la demande. Les chiffres
     viennent du build (tarifs) ; sans JavaScript ou en mouvement reduit, la classe complete reste affichee. */
  function preparerSchemas() {
    document.querySelectorAll('[data-schema="classe"]').forEach(function (bloc) {
      var NS = 'http://www.w3.org/2000/svg';
      var ouverture = +bloc.dataset.ouverture, tailles = { enfants: +bloc.dataset.enfants, adultes: +bloc.dataset.adultes };
      var places = bloc.querySelector('.schema-classe__places'), eleves = bloc.querySelector('.schema-classe__eleves');
      var anneau = bloc.querySelector('.schema-classe__anneau'), etat = bloc.querySelector('.schema-classe__etat');
      var etapes = bloc.querySelectorAll('.schema-classe__etapes li');
      var boutons = bloc.querySelectorAll('[data-public]');
      var departs = [[40, 60], [560, 50], [580, 400], [30, 410], [300, 20], [20, 230], [580, 230]];
      var publicChoisi = 'enfants', minuteurs = [];
      function point(i, n) { var a = -Math.PI / 2 + i * 2 * Math.PI / n; return [300 + 150 * Math.cos(a), 220 + 150 * Math.sin(a)]; }
      function etape(k) { etapes.forEach(function (li, i) { li.classList.toggle('est-active', i === k); }); }
      function plus(ms, f) { minuteurs.push(setTimeout(f, ms)); }
      function ouvrir(oui) { anneau.setAttribute('stroke-dasharray', oui ? '0' : '10 14'); anneau.style.opacity = oui ? '1' : '.6'; }
      function nom(k) { return k + ' ' + (publicChoisi === 'enfants' ? 'enfants' : 'adultes'); }
      function dessiner(final) {
        minuteurs.forEach(clearTimeout); minuteurs = [];
        places.replaceChildren(); eleves.replaceChildren();
        var n = tailles[publicChoisi];
        for (var i = 0; i < n; i++) {
          var p = point(i, n), c = document.createElementNS(NS, 'circle');
          c.setAttribute('cx', p[0]); c.setAttribute('cy', p[1]); c.setAttribute('r', 22);
          c.setAttribute('fill', 'none'); c.setAttribute('stroke', '#BA98FB'); c.setAttribute('stroke-width', 2); c.setAttribute('stroke-dasharray', '4 6');
          places.appendChild(c);
        }
        for (var j = 0; j < n; j++) {
          (function (j) {
            var p = point(j, n), d = departs[j], c = document.createElementNS(NS, 'circle');
            c.setAttribute('r', 16); c.setAttribute('fill', '#FFFFFF');
            c.style.transition = final ? 'none' : 'transform .9s cubic-bezier(.2, 0, 0, 1)';
            c.style.transform = 'translate(' + (final ? p[0] : d[0]) + 'px,' + (final ? p[1] : d[1]) + 'px)';
            eleves.appendChild(c);
            if (!final) plus(1200 + j * 1000, function () { c.style.transform = 'translate(' + p[0] + 'px,' + p[1] + 'px)'; });
          })(j);
        }
        if (final) { ouvrir(true); etape(3); etat.textContent = 'Classe complète : ' + nom(n); return; }
        ouvrir(false); etape(0); etat.textContent = 'En attente sur l’horaire choisi';
        plus(900, function () { etape(1); etat.textContent = 'Les demandes se regroupent'; });
        for (var k = 1; k <= n; k++) {
          (function (k) {
            plus(1200 + k * 1000, function () {
              if (k < ouverture) etat.textContent = k + (k > 1 ? ' inscrits' : ' inscrit');
              else if (k === ouverture) { ouvrir(true); etape(2); etat.textContent = k + ' inscrits : la direction crée la classe'; }
              else if (k < n) etat.textContent = k + ' inscrits';
              else { etape(3); etat.textContent = 'Classe complète : ' + nom(n); }
            });
          })(k);
        }
      }
      function jouer() { dessiner(reduit.matches); }
      boutons.forEach(function (b) {
        b.addEventListener('click', function () {
          publicChoisi = b.dataset.public;
          boutons.forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
          jouer();
        });
      });
      bloc.querySelector('[data-rejouer]').addEventListener('click', jouer);
      dessiner(true);
      if (reduit.matches || !('IntersectionObserver' in window)) return;
      var vu = new IntersectionObserver(function (entrees) {
        if (!entrees[0].isIntersecting) return;
        vu.disconnect();
        dessiner(false);
      }, { threshold: 0.5 });
      vu.observe(bloc);
    });
  }

  /* Cours : au survol d'une arche, ses lettres arabes s'ecrivent de nouveau (styles/site.css). Changer le nom de
     l'animation la relance : on alterne entre deux noms au dessin identique. */
  function preparerArches() {
    if (reduit.matches || !window.matchMedia('(hover: hover)').matches) return;
    document.querySelectorAll('.parcours__etape').forEach(function (arche) {
      if (!arche.querySelector('.parcours__lettre, .parcours__mot')) return;
      var tour = 0;
      arche.addEventListener('pointerenter', function () {
        if (!arche.parentElement.classList.contains('est-visible')) return;
        tour += 1;
        arche.classList.toggle('rejoue-a', tour % 2 === 1);
        arche.classList.toggle('rejoue-b', tour % 2 === 0);
      });
    });
  }

  preparerEntrees();
  preparerArches();
  preparerTapis();
  preparerHalo();
  preparerTitres();
  preparerSommaire();
  preparerTuiles();
  preparerSchemas();
  window.addEventListener('scroll', auDefilement, { passive: true });
  window.addEventListener('resize', auDefilement, { passive: true });
  reduit.addEventListener('change', auDefilement);
  large.addEventListener('change', auDefilement);
  image();
})();
