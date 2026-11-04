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
  var entreesChapitres = [];
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
    // Les chapitres se collent sous l'en-tete, leur texte au milieu de l'arche epinglee, et le suivant monte par-dessus.
    // Pendant ses derniers 24 % d'ecran de montee : le texte en place s'efface (premiere moitie), l'arche change
    // d'image, puis le nouveau texte apparait sur les 30 derniers % de la course, presque a sa place. Jamais deux
    // textes lisibles a la fois, toujours a cote de leur image.
    var entete = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--entete')) || 0;
    var course = h * 0.24;
    var restes = Array.prototype.map.call(textesChapitres, function (t, i) {
      return i === 0 ? 0 : Math.max(0, t.getBoundingClientRect().top - entete);
    });
    entreesChapitres = restes.map(function (r, i) { return i === 0 ? 1 : 1 - borne(r / (course * 0.3)); });
    var courante = 0;
    restes.forEach(function (r, i) { if (i > 0 && r <= course * 0.4) courante = i; });
    imagesChapitres.forEach(function (img, j) {
      img.style.setProperty('--o', j === courante ? '1' : '0');
    });
    Array.prototype.forEach.call(textesChapitres, function (t, i) {
      var bloc = t.querySelector('.chapitre__texte') || t;
      var sortie = i + 1 < restes.length ? borne((restes[i + 1] - course * 0.5) / (course * 0.5)) : 1;
      var visible = Math.min(entreesChapitres[i], sortie);
      bloc.style.setProperty('--sortie', visible.toFixed(3));
      bloc.toggleAttribute('data-efface', visible < 0.05);
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
      // Dans la fenetre epinglee des chapitres, l'image ne bouge pas : les mains montent pendant que le texte de leur
      // chapitre apparait, une fois l'image entree.
      var fenetre = fig.closest('[data-chapitre-image]');
      if (fenetre && large.matches) {
        var rang = Array.prototype.indexOf.call(imagesChapitres, fenetre);
        if (rang >= 0 && entreesChapitres.length > rang) {
          fig.style.setProperty('--m', (1 - adoucie(entreesChapitres[rang])).toFixed(4));
          return;
        }
      }
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
    sceneVoyage(h);
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

  /* Le chemin de lumiere (teinte jour ; directeur, 04/11/2026). Le dessin et ses raisons sont dans styles/site.css (« Le
     chemin de lumiere ») ; ici, on mesure la page (au chargement et quand elle change de taille), puis, a chaque image, on
     ne lit que la position de defilement. */
  var voyage = null;
  var LECTURE = 0.58; // la ligne de lecture, ou se tient la pointe du fil : 58 % de la hauteur de l'ecran
  var hexa = function (t) { var m = /^#([0-9a-f]{6})$/i.exec(t || ''); if (!m) return null; var n = parseInt(m[1], 16); return [n >> 16, (n >> 8) & 255, n & 255]; };
  var lisse = function (t) { return t * t * (3 - 2 * t); };
  var lin = function (x) { x /= 255; return x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4); };
  var lum = function (c) { return 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]); };
  var ecart = function (a, b) { var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  var rvb = function (s) { var m = /rgba?\(([^)]+)\)/.exec(s || ''); if (!m) return null; var v = m[1].split(/[\s,/]+/).filter(Boolean).map(Number); return v.length > 3 && v[3] < 1 ? null : v.slice(0, 3); };
  // Fonds du parcours sous un titre sans fond propre : les teintes des sections, et la lavande ourlee de lilas de la lumiere.
  var FONDS = [[255, 255, 255], [247, 245, 254], [241, 239, 244], [238, 230, 250], [233, 222, 251]];

  function preparerVoyage() {
    if (racine.getAttribute('data-teinte') !== 'jour' || !contenu) return;
    var NS = 'http://www.w3.org/2000/svg';
    var couche = document.createElement('div');
    couche.className = 'voyage';
    couche.setAttribute('aria-hidden', 'true');
    couche.innerHTML = '<span class="voyage__lumiere voyage__lumiere--1"></span><span class="voyage__lumiere voyage__lumiere--2"></span>' +
      '<span class="voyage__lumiere voyage__lumiere--3"></span><span class="voyage__lumiere voyage__lumiere--4"></span>' +
      '<span class="voyage__eclat"></span><span class="voyage__grain"></span>';
    document.body.insertBefore(couche, document.body.firstChild);
    var fil = document.createElementNS(NS, 'svg');
    fil.setAttribute('class', 'chemin-fil');
    fil.setAttribute('aria-hidden', 'true');
    fil.setAttribute('focusable', 'false');
    var trace = document.createElementNS(NS, 'path');
    trace.setAttribute('class', 'chemin-fil__trace');
    var bout = document.createElementNS(NS, 'circle');
    bout.setAttribute('class', 'chemin-fil__bout');
    fil.appendChild(trace);
    fil.appendChild(bout);
    contenu.parentNode.insertBefore(fil, contenu);
    var panneau = contenu.querySelector(':scope > .panneau');
    if (panneau) {
      var lueur = document.createElement('span');
      lueur.className = 'panneau__lueur';
      lueur.setAttribute('aria-hidden', 'true');
      panneau.insertBefore(lueur, panneau.firstChild);
    }
    voyage = {
      couche: couche, fil: fil, trace: trace, bout: bout, eclat: couche.querySelector('.voyage__eclat'),
      lumieres: Array.prototype.map.call(couche.querySelectorAll('.voyage__lumiere'), function (el, i) {
        return { el: el, vitesse: [0.06, 0.14, 0.22, 0.32][i], depart: [-0.3, 0.18, 0.62, 0.92][i], h: 0 };
      }),
      arches: Array.prototype.slice.call(contenu.querySelectorAll(':scope > :is(.panneau, .appel--porte, .appel--centre)')),
      blocs: [], points: [], longueur: 0, attenues: [], debut: 0, fin: 0, y0: 0, l: 0, couleur: '', mesure: false
    };
    racine.classList.add('voyage-actif');
    mesurerVoyage();
    var attente = null;
    var remesurer = function () { clearTimeout(attente); attente = setTimeout(function () { mesurerVoyage(); auDefilement(); }, 120); };
    if ('ResizeObserver' in window) new ResizeObserver(remesurer).observe(contenu);
    window.addEventListener('resize', remesurer, { passive: true });
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(remesurer);
    window.addEventListener('load', remesurer);
  }

  /* Les zones occupees de la page, sur toute sa largeur : un texte, une image, un champ, une surface peinte. Un element colle
     (sticky) occupe toute la hauteur ou il peut glisser. */
  function zonesOccupees(sy) {
    var zones = [];
    var collants = new Map();
    var colle = function (el) {
      if (collants.has(el)) return collants.get(el);
      var r = null;
      if (el !== contenu && el.parentElement) r = getComputedStyle(el).position === 'sticky' ? el : colle(el.parentElement);
      collants.set(el, r);
      return r;
    };
    // Une bande qui coupe ce qui deborde (overflow) borne ce qu'elle contient : la lueur du panneau ne deborde pas.
    var bornes = new Map();
    Array.prototype.forEach.call(contenu.children, function (bloc) {
      var o = getComputedStyle(bloc).overflowY;
      if (o !== 'visible') { var rb = bloc.getBoundingClientRect(); bornes.set(bloc, [rb.top, rb.bottom]); }
    });
    contenu.querySelectorAll('*').forEach(function (el) {
      if (el.closest('svg') && el.tagName.toLowerCase() !== 'svg') return;
      var r = el.getBoundingClientRect();
      if (r.width < 2 || r.height < 2) return; // ni vide, ni texte reserve aux lecteurs d'ecran (1 px)
      var cs = getComputedStyle(el);
      if (cs.visibility === 'hidden') return;
      var nom = el.tagName.toLowerCase();
      var visuel = /^(img|svg|video|canvas|picture|input|select|textarea|button|iframe)$/.test(nom) ||
        cs.backgroundColor !== 'rgba(0, 0, 0, 0)' || cs.backgroundImage !== 'none' || cs.boxShadow !== 'none' ||
        parseFloat(cs.borderTopWidth) > 0 || parseFloat(cs.borderBottomWidth) > 0;
      if (!visuel) {
        for (var n = el.firstChild; n; n = n.nextSibling) { if (n.nodeType === 3 && n.textContent.trim()) { visuel = true; break; } }
      }
      if (!visuel) return;
      var haut = r.top, bas = r.bottom;
      var c = colle(el);
      if (c) { haut = Math.min(haut, c.getBoundingClientRect().top); bas = Math.max(bas, c.parentElement.getBoundingClientRect().bottom); }
      var bloc = el;
      while (bloc.parentElement && bloc.parentElement !== contenu) bloc = bloc.parentElement;
      var lim = bornes.get(bloc);
      if (lim) { haut = Math.max(haut, lim[0]); bas = Math.min(bas, lim[1]); if (bas <= haut) return; }
      // 24 px au-dessus : un texte qui n'est pas encore entre est 24 px plus bas que sa place (il monte en entrant).
      zones.push([haut + sy - 24, bas + sy + 8]);
    });
    zones.sort(function (a, b) { return a[0] - b[0]; });
    var fusion = [];
    zones.forEach(function (z) {
      var der = fusion[fusion.length - 1];
      if (der && z[0] <= der[1]) der[1] = Math.max(der[1], z[1]); else fusion.push([z[0], z[1]]);
    });
    return fusion;
  }

  function mesurerVoyage() {
    var v = voyage;
    var sy = window.scrollY, vh = window.innerHeight, W = racine.clientWidth;
    var y0 = contenu.getBoundingClientRect().top + sy;
    v.y0 = y0;
    v.fil.style.top = y0 + 'px';
    v.blocs = Array.prototype.filter.call(contenu.children, function (e) { return e.getClientRects().length; }).map(function (e) {
      var r = e.getBoundingClientRect();
      return { el: e, haut: r.top + sy, bas: r.bottom + sy, c: hexa(getComputedStyle(e).getPropertyValue('--teinte-voyage').trim()) || [247, 245, 254] };
    });
    v.lumieres.forEach(function (l) { l.h = l.el.offsetHeight; });
    if (!v.blocs.length) return;
    // Le fil : la moitie de la marge, de chaque cote du contenu.
    var largeur = parseFloat(getComputedStyle(racine).getPropertyValue('--contenu')) || 1200;
    var marge = parseFloat(getComputedStyle(racine).getPropertyValue('--marge')) || 16;
    var bord = Math.max(marge, (W - largeur) / 2) / 2;
    var gauche = bord, droite = W - bord;
    var premier = v.blocs[0], dernier = v.blocs[v.blocs.length - 1];
    var debut = premier.bas - 40;
    var finBloc = dernier.bas - 160;
    var petit = W < 600;
    var vide = petit ? 56 : 64, pas = vh * 0.35;
    var libres = [];
    var occupees = zonesOccupees(sy);
    var y = debut;
    occupees.forEach(function (z) { if (z[0] > y) libres.push([y, z[0]]); y = Math.max(y, z[1]); });
    if (y < finBloc) libres.push([y, finBloc]);
    // L'appel de fin : le fil vient se poser au milieu, dans le vide juste au-dessus de la derniere bande d'appel ; sans ce
    // vide, il entre dans l'arche de l'appel par sa marge (l'arche le recouvre), ou s'arrete dans sa marge.
    var appel = /\bappel\b/.test(dernier.el.className) ? dernier : null;
    var arche = appel && v.arches.indexOf(appel.el) >= 0;
    var arrivee = null;
    if (appel) {
      for (var a = libres.length - 1; a >= 0; a--) {
        var g = libres[a];
        if (g[1] <= appel.haut + 240 && g[1] >= appel.haut - vh * 0.5 && g[1] - g[0] >= vide && g[0] > debut + vh * 0.5) { arrivee = g; break; }
      }
    }
    if (arche && !arrivee) finBloc = Math.min(finBloc, appel.haut + 80);
    var x = gauche, d = 'M ' + x.toFixed(1) + ' ' + (debut - y0).toFixed(1), dernierPassage = debut;
    libres.forEach(function (g) {
      if (arrivee && g[0] >= arrivee[0]) return;
      var h = g[1] - g[0];
      if (h < vide || g[0] - dernierPassage < pas || g[1] > finBloc) return;
      var course = Math.min(h - 24, 240);
      var ya = g[0] + (h - course) / 2, yb = ya + course, nx = x === gauche ? droite : gauche;
      d += ' L ' + x.toFixed(1) + ' ' + (ya - y0).toFixed(1) +
        ' C ' + x.toFixed(1) + ' ' + ((ya + yb) / 2 - y0).toFixed(1) + ', ' + nx.toFixed(1) + ' ' + ((ya + yb) / 2 - y0).toFixed(1) + ', ' + nx.toFixed(1) + ' ' + (yb - y0).toFixed(1);
      x = nx;
      dernierPassage = yb;
    });
    var finY;
    if (arrivee) {
      var hA = arrivee[1] - arrivee[0], ca = Math.min(hA - 24, 240), ya2 = arrivee[0] + (hA - ca) / 2;
      finY = ya2 + ca;
      d += ' L ' + x.toFixed(1) + ' ' + (ya2 - y0).toFixed(1) +
        ' C ' + x.toFixed(1) + ' ' + ((ya2 + finY) / 2 - y0).toFixed(1) + ', ' + (W / 2).toFixed(1) + ' ' + ((ya2 + finY) / 2 - y0).toFixed(1) + ', ' + (W / 2).toFixed(1) + ' ' + (finY - y0).toFixed(1);
    } else {
      finY = Math.max(finBloc, dernierPassage + 40);
      d += ' L ' + x.toFixed(1) + ' ' + (finY - y0).toFixed(1);
    }
    v.trace.setAttribute('d', d);
    var H = Math.max(contenu.offsetHeight, finY - y0 + 20);
    v.fil.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    v.fil.setAttribute('width', W);
    v.fil.setAttribute('height', H);
    v.fil.style.height = H + 'px';
    v.longueur = v.trace.getTotalLength();
    v.trace.style.strokeDasharray = v.longueur + ' ' + (v.longueur + 2);
    // Le fil, echantillonne : sa hauteur ne fait que croitre le long du trace, on y cherche la pointe par dichotomie.
    v.points = [];
    for (var l = 0; l <= v.longueur; l += 6) { var p = v.trace.getPointAtLength(l); v.points.push([l, p.x, p.y + y0]); }
    var pf = v.trace.getPointAtLength(v.longueur);
    v.points.push([v.longueur, pf.x, pf.y + y0]);
    v.debut = debut;
    v.fin = finY;
    v.l = -1;
    // Ce qui s'attenue loin de la pointe : les titres de section et les illustrations, hors de l'en-tete de page et des cartes.
    v.attenues.forEach(function (a) { a.el.removeAttribute('data-attenue'); a.el.style.removeProperty('--eclat'); });
    v.attenues = [];
    contenu.querySelectorAll('h2, figure, .bande-image').forEach(function (el) {
      if (premier.el.contains(el) || el.closest('a, .article-carte, .avis-carte, .fiche, summary, figure figure')) return;
      if (el.tagName.toLowerCase() === 'figure' && el.parentElement.closest('figure, .bande-image')) return;
      // Une illustration ne s'attenue que si elle ne porte aucun texte (legende, citation) : le texte ne s'attenue jamais.
      if (el.tagName.toLowerCase() !== 'h2' && el.textContent.trim()) return;
      var r = el.getBoundingClientRect();
      if (r.height < 1) return;
      var plancher = 0.55;
      if (el.tagName.toLowerCase() === 'h2') {
        var cs = getComputedStyle(el), couleur = rvb(cs.color);
        if (!couleur) return;
        var fonds = null;
        for (var n = el; n && n !== contenu.parentElement; n = n.parentElement) { var f = rvb(getComputedStyle(n).backgroundColor); if (f) { fonds = [f]; break; } }
        var grand = parseFloat(cs.fontSize) >= 24 || (parseFloat(cs.fontSize) >= 18.66 && parseInt(cs.fontWeight, 10) >= 700);
        var seuil = (grand ? 3 : 4.5) + 0.15;
        plancher = 0.6;
        (fonds || FONDS).forEach(function (fond) {
          var o = plancher;
          while (o < 1 && ecart(couleur.map(function (c, i) { return c * o + fond[i] * (1 - o); }), fond) < seuil) o += 0.02;
          plancher = Math.min(1, Math.max(plancher, o));
        });
      }
      var c = el.closest('[data-chapitre-image], .chapitres__fenetre, .section__titre, .faq-ouverte__tete');
      el.setAttribute('data-attenue', '');
      el.style.setProperty('--eclat-min', plancher.toFixed(2));
      v.attenues.push({ el: el, haut: r.top + sy, bas: r.bottom + sy, plancher: plancher, vivant: !!c, o: -1 });
    });
    v.mesure = true;
  }

  function sceneVoyage(h) {
    var v = voyage;
    if (!v || !v.mesure || !v.blocs.length) return;
    var sy = window.scrollY, bas = sy + h;
    // 1. La teinte : d'une section a la suivante, pendant que la jonction monte du bas de l'ecran jusqu'a 40 % de sa hauteur
    //    (au plus la hauteur de la section qui arrive : deux passages ne se chevauchent jamais).
    var c = v.blocs[0].c.slice();
    for (var k = 1; k < v.blocs.length; k++) {
      var b = v.blocs[k], w = Math.min(h * 0.6, Math.max(1, b.bas - b.haut));
      var t = borne((bas - b.haut) / w);
      if (t <= 0) break;
      t = lisse(t);
      c = c.map(function (x, i) { return x + (b.c[i] - x) * t; });
    }
    var couleur = 'rgb(' + c.map(Math.round).join(' ') + ')';
    if (couleur !== v.couleur) { v.couche.style.setProperty('--voyage', couleur); v.couleur = couleur; }
    if (reduit.matches) {
      if (v.l !== v.longueur) {
        v.l = v.longueur;
        v.trace.style.strokeDashoffset = '0';
        v.bout.setAttribute('r', '0');
        v.eclat.style.setProperty('--eclat-fil', '0');
        v.arches.forEach(function (a) { a.__courbe = '0px'; a.style.setProperty('--courbe', '0px'); });
        v.attenues.forEach(function (a) { a.el.style.removeProperty('--eclat'); a.o = -1; });
      }
      return;
    }
    // Les lumieres a quatre profondeurs : plus elles sont loin, plus elles vont lentement ; elles reviennent par le bas.
    v.lumieres.forEach(function (l) {
      var periode = h + l.h + h * 0.4;
      var y = ((l.depart * h + l.h - sy * l.vitesse) % periode + periode) % periode - l.h;
      l.el.style.transform = 'translate3d(0,' + y.toFixed(1) + 'px,0)';
    });
    // 2. Le fil se dessine jusqu'a la ligne de lecture.
    var cible = sy + h * LECTURE, pts = v.points, lo = 0, hi = pts.length - 1;
    if (cible <= pts[0][2]) hi = 0;
    else if (cible >= pts[hi][2]) lo = hi;
    else { while (hi - lo > 1) { var mi = (lo + hi) >> 1; if (pts[mi][2] < cible) lo = mi; else hi = mi; } }
    var a0 = pts[lo], a1 = pts[hi], u = a1[2] > a0[2] ? (cible - a0[2]) / (a1[2] - a0[2]) : 1;
    u = borne(u);
    var L = a0[0] + (a1[0] - a0[0]) * u, px = a0[1] + (a1[1] - a0[1]) * u, py = a0[2] + (a1[2] - a0[2]) * u;
    if (Math.abs(L - v.l) > 0.5) {
      v.l = L;
      v.trace.style.strokeDashoffset = (v.longueur - L).toFixed(1);
      v.bout.setAttribute('cx', px.toFixed(1));
      v.bout.setAttribute('cy', (py - v.y0).toFixed(1));
      v.bout.setAttribute('r', L > 1 ? '4' : '0');
    }
    // 3. Sa lumiere, sous le contenu, toujours sur la ligne de lecture (meme apres la fin du fil : l'appel de fin reste eclaire) ;
    //    elle s'allume quand le fil part. Elle se tient entre le milieu de la page et la pointe : elle eclaire ce qu'on lit, et
    //    glisse d'un cote a l'autre avec le fil ; le fil fini, elle revient au milieu.
    var allume = borne((cible - v.debut) / 200);
    v.eclat.style.setProperty('--eclat-fil', allume.toFixed(3));
    var finie = borne((cible - v.fin) / (h * 0.3));
    var lx = window.innerWidth / 2 + (px - window.innerWidth / 2) * 0.45 * (1 - finie);
    v.eclat.style.transform = 'translate3d(' + lx.toFixed(1) + 'px,' + (h * LECTURE).toFixed(1) + 'px,0)';
    // Ce qui est loin de la lumiere s'attenue : pleinement eclaire a moins de 10 % d'ecran, au plus bas a 50 %.
    var r0 = h * 0.1, r1 = h * 0.5;
    v.attenues.forEach(function (a) {
      var haut = a.haut, fin = a.bas;
      if (a.vivant) { var r = a.el.getBoundingClientRect(); haut = r.top + sy; fin = r.bottom + sy; }
      if (fin < sy - h || haut > bas + h) return;
      var dist = Math.max(0, haut - cible, cible - fin);
      var o = a.plancher + (1 - a.plancher) * (1 - lisse(borne((dist - r0) / (r1 - r0))));
      o = Math.round(o * 100) / 100;
      if (o !== a.o) { a.o = o; a.el.style.setProperty('--eclat', o.toFixed(2)); }
    });
    // 4. Les arches : la grande courbe quand la section entre par le bas, a plat quand son haut atteint le tiers de l'ecran.
    var courbe = Math.min(260, window.innerWidth * 0.18);
    v.arches.forEach(function (el) {
      var top = el.getBoundingClientRect().top;
      var val = Math.round(courbe * borne((top - h * 0.33) / (h * 0.67))) + 'px';
      if (el.__courbe !== val) { el.__courbe = val; el.style.setProperty('--courbe', val); }
    });
  }

  preparerEntrees();
  preparerVoyage();
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
