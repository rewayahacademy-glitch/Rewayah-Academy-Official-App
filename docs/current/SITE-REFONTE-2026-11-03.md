# SITE-REFONTE : fiche du 03/11/2026 (site public)

Demande du directeur du 03/11/2026 (session claude.ai « Rewayah Academy site final version »). Zone : `site-public/**` et cette fiche
seulement. Pilote : feu vert pour travailler et pousser la branche `claude/happy-mccarthy-meqjyy` ; PR 187 en brouillon ; une seule
correction groupée après la première relecture du directeur.

**Statuts (CLAUDE.md : un statut par ligne, aucun PASS inventé).** « Présent dans le code » et « testé localement » ne veulent pas dire
« déployé » : rien de ceci n'est sur `main`, ni vu par le directeur en production.

## 1. Ce qui est fait dans le code

| Demande | Où | Statut |
| :--- | :--- | :--- |
| Retirer le mot « Menu » à côté de l'icône mobile | `build_site.py`, `styles/site.css` | présent dans le code ; capture 390 px ; le mot reste lu par les lecteurs d'écran |
| Profondeur : arche géante lointaine, halos d'ambiance, cartes qui flottent | fin de `styles/site.css` | présent dans le code ; captures ; mouvement lié au défilement, fixe en « mouvement réduit » |
| Pied de page grand et aéré, filigrane du symbole | bloc « Pied de page » de `site.css`, `assets/symbole-contour-white.svg` | présent dans le code ; captures |
| Carte du monde tamisée dans le pied de page | `carte_monde.py`, `assets/carte-monde-points.svg` | présent dans le code ; points sans frontière ni nom ; données Natural Earth (domaine public) |
| **Jonctions douces, version 2 (retour du directeur : « encore très fort »)** | fin de `styles/site.css` | présent dans le code ; fondus de 200 à 400 px, adoucis en S, derrière le contenu ; captures bureau et mobile sur 6 vues |
| Avis chaleureux, aperçus sur l'accueil et trois pages | `bloc_avis.py`, `build_site.py`, `site.css` | présent dans le code ; testé avec des avis **fictifs** (jamais commités) |
| SEO technique | `build_site.py` | présent dans le code : dimensions de l'image de partage, fil d'Ariane, balisage `Article`, date de mise à jour au plan du site pour les articles |
| **Quatre articles signés du directeur** (troisième relecture : valeur et service d'abord) | `content/pages.json`, `content/direction.json`, `build_site.py` | présent dans le code ; chaque verset et chaque hadith vérifiés (§6) ; relecture du directeur à faire avant fusion |
| **Page « Autres chemins pour apprendre le Coran »** | `content/pages.json` | présent dans le code, 5 sites lus sur 6 (voir §4) |

Testé localement : 110 tests `python3 -m unittest discover -s site-public/tests` (80 au départ, 30 ajoutés), et 92 vues (23 routes à 360, 390, 768 et
1440 px) sans débordement horizontal, sans ressource en erreur, sans erreur JavaScript. Testé sur staging : l'aperçu de la PR 187 a servi le premier
commit ; le second n'est pas encore vu. Déployé : non.

## 2. Décisions du directeur le 03/11 (écrites ici pour la mémoire du dépôt)

- **Jonctions** : transition très large et très progressive d'une couleur vers l'autre, sans bande sombre perceptible entre les deux.
- **Avis** : le directeur a posté lui-même les deux avis pour l'aperçu et les supprime dans la console d'administration. La question est close ;
  tant qu'il reste moins de 3 avis publiés, aucun aperçu ne s'affiche (seuil volontaire).
- **Articles** : au moins deux, professionnels, fidèles aux valeurs de l'académie.
- **Le reste** : délégué à l'agent (« tu choisis le meilleur »). Les choix de l'agent sont au §3.
- **Troisième relecture (03/11, soir)** : les articles sont signés du directeur ; ils ne citent pas les autres sites, ils disent seulement que
  d'autres existent et renvoient à la page « Autres chemins » (dont la manière de citer est validée) ; ils donnent de la valeur avant de parler de
  Rewayah (langage éducatif, profondeur spirituelle, historique et sociale, peu de listes) ; deux articles de plus : apprendre seul sans maître, et
  le pouvoir du groupe (avec le fonctionnement des classes de Rewayah) ; « n'invente rien ».

## 3. Choix de l'agent, modifiables en une ligne

- `bloc_avis.AVIS_MOYENNE_MIN = 5` et `AVIS_APERCU_MIN = 3` : pas de moyenne avant 5 avis, pas d'aperçu avant 3 ; les trois plus récents, jamais les mieux notés.
- **Filigrane géant derrière du texte conservé** (4 à 6 % d'opacité) : le README du logo l'autorise pour `ornement-contour` et `symbole-contour` (« filigrane
  très grand ») ; il ne dit « jamais derrière du texte » que pour le logo lui-même, qui n'est jamais rendu transparent. Si le directeur préfère, on le restreint.
- **Pas de mesure d'audience ajoutée.** Elle exige d'activer Vercel Web Analytics (geste du directeur) et de dire la mesure dans la politique de confidentialité
  (texte juridique). Google Analytics et Microsoft Clarity restent déconseillés (consentement exigé en France ; sessions enregistrées sur un site pour des familles).
  Tant qu'elle n'existe pas, aucune donnée de trafic n'est lisible : seule la Search Console compte les impressions.
- **Auteur des articles : le directeur** (signature sous le titre, lien vers « Le mot du directeur », balisage `Person`). Date : 2026-11-03.
- **« Occident »** est employé, comme le directeur l'a demandé, avec « et partout où les musulmans vivent en minorité » pour ne pas exclure les
  familles qui vivent ailleurs. La règle de marque vise les noms de pays et de continents ; « Occident » n'en est pas un.
- **Pas d'écriture arabe sur les pages françaises** (registre M-29, test existant) : l'eulogie s'écrit « (paix et bénédictions sur lui) », à chaque
  mention ; les mots arabes s'écrivent en lettres latines (qalb, kalb).
- **Citations** : un extrait de verset n'est accepté que s'il est mot pour mot dans le texte vérifié (sinon le script s'arrête) ; un hadith est cité
  dans la traduction publiée par HadeethEnc quand elle existe, sinon dans une traduction du sens, signalée comme telle. Script :
  `articles_v3.py` (hors dépôt, dans le dossier de travail de la session), qui lit `sources_verifiees.json`.
- **Aucune règle de l'académie dans un article si le site ne la publie pas déjà.** Exemple : l'absence d'un élève et le rattrapage (règle décidée, non publiée) ne
  sont pas écrits. Un test le garde.
- **Aucun prix dans un article ni dans la page des autres chemins** (source unique : `DECISION-TARIFS-2026-10-18.md`).
- **Les textes « transparence » et « présentiel d'abord »** sont placés dans l'article « Comment choisir » et dans la page des autres chemins, pas sur l'accueil.
  L'accueil n'est pas modifié : il porte la promesse de la marque.
- **« at-talaqqî »** : le terme est du directeur (sa demande du 03/11). Il apparaît une fois, dans « Notre manière » de la page des autres chemins. Il n'est pas au
  registre des mots : à confirmer.

## 4. Écarts avec la demande initiale (vérité d'abord)

1. **Aucun rapport de performance n'existe.** Vercel Web Analytics n'est pas activé ; aucun e-mail Clarity ni Analytics. Les 5 e-mails Google et Bing de `staff@`
   disent seulement : propriété validée le 23/10, impressions comptées depuis le 24/10 (sans chiffre), « exclue par noindex » et « page avec redirection » (26/10, comportement voulu),
   scan Bing lancé (rapport dans l'interface Bing), un modèle générique. Les notes des pilotes (« Search Console et Bing non faits ») sont en retard.
2. **Un lien sortant n'est pas un backlink pour nous** (Google : « Nothing happens. Why should it? »). La page des autres chemins sert le lecteur et la confiance, pas le
   classement. Règle suivie : 5 à 8 sites, lien sans attribut, aucune demande en retour, jamais « discrètement ». Vrais backlinks : ressources partageables, mosquées et
   associations, podcasts, presse locale, messages courtois aux autres instituts sans demander de lien (rapport d'un sous-agent, effet chiffré non vérifié).
3. **La classification des sites de la demande était en partie fausse** : Institut Al Rayhan et Institut As-Sahaba sont 100 % en ligne d'après leurs sites (pas des instituts
   « installés ») ; As-Sahaba ne mentionne aucune ijaza ; Al Rayhan n'indique pas son ancienneté. La page les range donc par **format**, pas par histoire.
4. **`le-coran.com` n'est pas cité.** Son site a répondu 403 à la lecture automatique ; contourner ce blocage n'est pas permis, donc rien n'est vérifié. Il peut entrer après
   une lecture par une personne (le test `test_seuls_les_sites_lus_sont_cites` le garde : il faut le modifier volontairement).
5. **Deux formules de la demande sont interdites par la marque** : « la meilleure alternative » (jamais « le meilleur ») et « les coûts les plus bas possibles »
   (superlatif que rien ne prouve ; un institut cité demande des prix très bas en groupe, d'après son site). « Occident » est écarté (nom de région).
6. **Le pied de page avait été compacté** après une revue de trois jurés ; la demande du 03/11 l'emporte.

## 5. Ce qui n'est PAS fait

- **Passe mobile générale** (paddings, tailles de police, espacement des cartes) : seul le menu est traité. Revue page par page à 360 et 390 px à faire.
- **Refonte des animations** au-delà des cartes, des boutons et des liens du pied.
- **Hub : 4 articles** (2 réécrits, 2 nouveaux). Les autres sujets du plan sont à écrire un par un, signés et relus ; aucun n'est publié en série.
- **Mesure d'audience** (voir §3).
- **Rendu vérifié sur l'aperçu Vercel du second commit** : non ; seules mes captures locales existent.

## 6. Sources des articles (vérifiées le 03/11/2026)

Vérification par un agent dédié, sans contourner aucun blocage (sunnah.com refuse la lecture automatique : numéros confirmés par l'index de
recherche de sunnah.com, par le jeu de données public hadith-api qui en recopie les textes, et par HadeethEnc). Résultat : 17 versets sur 17 et
11 hadiths sur 11 vérifiés ; Ibn Khaldûn (De Slane, *Les Prolégomènes*, III, 1868, p. 285, relu sur l'image de la page) ; le kuttâb (Essam Ayyad,
*Journal of the Royal Asiatic Society*, 2022) ; Ibn al-Jazarî, *at-Tamhîd*, p. 21-22 (faute apparente, faute cachée). Corrections appliquées :
Muslim 783 **b** (et non 783 a) ; H3 cité dans la formulation de Muslim 798 a ; « vendeur de musc et forgeron » rapporté en al-Bukhârî 2101 ;
« Prenez le Coran de quatre » en al-Bukhârî 4999, d'après ‘Abd Allâh ibn ‘Amr ; « Facilitez… annoncez la bonne nouvelle » en al-Bukhârî 69 seul ;
le hadith « l'homme suit la religion de son ami » est dit **hasan** ; la première révélation cite al-Bukhârî 3 et 4953, et mentionne l'autre récit
(al-Bukhârî 4922). L'exemple qalb/kalb est de l'article, pas d'Ibn al-Jazarî, qui illustre par « an‘amta » (Al-Fâtiha). Deux coquilles de l'édition
en ligne de Hamidullah (54:17 : « médiation », « Y a-t- il ») sont corrigées et signalées dans la section Sources de l'article. L'article sur la fatigue
cite aussi Cepeda 2006 et Dunlosky 2013 (Crossref), en disant qu'ils ne portent pas sur le Coran.

**Faits sur Rewayah** dans les articles : seulement ceux que le site publie déjà (classes de 3 à 5 enfants de 6 à 17 ans, trois séances d'une heure ;
classes de 3 à 6 adultes, trois séances d'1 h 30 ; ouverture dès trois inscrits ; observation du parent, deux minutes ; compte rendu de fin de semaine ;
les étapes des bases).

## 6 bis. Pages non indexées (question du directeur, 03/11)

En production, 20 pages sur 23 sont indexables, dont `/fr/contact`, les pages légales et les articles. Non indexées, volontairement : `/fr/avis`
tant qu'aucun avis n'est publié (elle s'indexe d'elle-même au premier avis), la page 404, et `/fr/courriels/desinscription`. Deux domaines entiers
répondent `noindex` : `app.rewayahacademy.com` (l'application, ses écrans de connexion) et `rewayah-academy.vercel.app` (copie technique du site, qui
ferait doublon). Les aperçus des PR sont toujours `noindex`. C'est ce que signale la Search Console le 26/10 : pas une panne.

## 7. Décisions encore ouvertes

1. Relire les quatre articles (citations, ton, et la signature) et la page des autres chemins. Rien ne se fusionne sans cette relecture.
2. Qui relit `le-coran.com` avant de le citer ?
3. Activer Vercel Web Analytics, avec le texte de confidentialité correspondant ?
4. Vercel : le plan Pro règle la saturation des déploiements (le pilote l'a déjà proposé).
5. Lancer la passe mobile et les animations après cette tranche ?

## 8. Vérifier

```
python3 -m unittest discover -s site-public/tests
python3 -I site-public/carte_monde.py chemin/vers/ne_110m_land.geojson   # régénère assets/carte-monde-points.svg (identique)
python3 site-public/build_site.py --output /tmp/site && cd /tmp/site && python3 -m http.server 8770
```
