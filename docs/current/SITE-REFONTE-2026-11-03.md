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
| **Deux articles professionnels** | `content/pages.json`, `content/direction.json`, `build_site.py` | présent dans le code ; relecture par le directeur à faire avant fusion |
| **Page « Autres chemins pour apprendre le Coran »** | `content/pages.json` | présent dans le code, 5 sites lus sur 6 (voir §4) |

Testé localement : 107 tests `python3 -m unittest discover -s site-public/tests` (80 au départ, 27 ajoutés), et 84 vues (21 routes à 360, 390, 768 et
1440 px) sans débordement horizontal, sans ressource en erreur, sans erreur JavaScript. Testé sur staging : l'aperçu de la PR 187 a servi le premier
commit ; le second n'est pas encore vu. Déployé : non.

## 2. Décisions du directeur le 03/11 (écrites ici pour la mémoire du dépôt)

- **Jonctions** : transition très large et très progressive d'une couleur vers l'autre, sans bande sombre perceptible entre les deux.
- **Avis** : le directeur a posté lui-même les deux avis pour l'aperçu et les supprime dans la console d'administration. La question est close ;
  tant qu'il reste moins de 3 avis publiés, aucun aperçu ne s'affiche (seuil volontaire).
- **Articles** : au moins deux, professionnels, fidèles aux valeurs de l'académie.
- **Le reste** : délégué à l'agent (« tu choisis le meilleur »). Les choix de l'agent sont au §3.

## 3. Choix de l'agent, modifiables en une ligne

- `bloc_avis.AVIS_MOYENNE_MIN = 5` et `AVIS_APERCU_MIN = 3` : pas de moyenne avant 5 avis, pas d'aperçu avant 3 ; les trois plus récents, jamais les mieux notés.
- **Filigrane géant derrière du texte conservé** (4 à 6 % d'opacité) : le README du logo l'autorise pour `ornement-contour` et `symbole-contour` (« filigrane
  très grand ») ; il ne dit « jamais derrière du texte » que pour le logo lui-même, qui n'est jamais rendu transparent. Si le directeur préfère, on le restreint.
- **Pas de mesure d'audience ajoutée.** Elle exige d'activer Vercel Web Analytics (geste du directeur) et de dire la mesure dans la politique de confidentialité
  (texte juridique). Google Analytics et Microsoft Clarity restent déconseillés (consentement exigé en France ; sessions enregistrées sur un site pour des familles).
  Tant qu'elle n'existe pas, aucune donnée de trafic n'est lisible : seule la Search Console compte les impressions.
- **Auteur des articles : l'académie**, pas une personne : aucun enseignant n'a approuvé de signature. Date de publication : 2026-11-03 (celle du fichier).
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
- **Hub : 2 articles sur 15 sujets** proposés (4 piliers, 11 articles liés). Les autres sont à écrire un par un, signés et relus ; aucun n'est publié en série.
- **Mesure d'audience** (voir §3).
- **Rendu vérifié sur l'aperçu Vercel du second commit** : non ; seules mes captures locales existent.

## 6. Sources des articles

L'article « Mon enfant est fatigué » cite deux travaux, **vérifiés dans le registre Crossref** le 03/11/2026 : Cepeda et coll., *Psychological Bulletin* 132, 2006, p. 354-380
(DOI 10.1037/0033-2909.132.3.354) ; Dunlosky et coll., *Psychological Science in the Public Interest* 14, 2013, p. 4-58 (DOI 10.1177/1529100612453266). L'article dit lui-même
que ces travaux portent sur l'apprentissage en général, pas sur le Coran. L'article « Comment choisir » ne cite aucune étude et le dit.

## 7. Décisions encore ouvertes

1. Relire les deux articles et la page des autres chemins (mots, ton). Rien ne se fusionne sans cette relecture.
2. Qui relit `le-coran.com` avant de le citer ?
3. Activer Vercel Web Analytics, avec le texte de confidentialité correspondant ?
4. Signer les articles d'un enseignant nommé (meilleur pour la confiance) ou garder l'académie ?
5. Vercel : le plan Pro règle la saturation des déploiements (le pilote l'a déjà proposé).
6. Lancer la passe mobile et les animations après cette tranche ?

## 8. Vérifier

```
python3 -m unittest discover -s site-public/tests
python3 -I site-public/carte_monde.py chemin/vers/ne_110m_land.geojson   # régénère assets/carte-monde-points.svg (identique)
python3 site-public/build_site.py --output /tmp/site && cd /tmp/site && python3 -m http.server 8770
```
