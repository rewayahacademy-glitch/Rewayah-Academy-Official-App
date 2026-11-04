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
| **Texte arabe de chaque verset et de chaque hadith cité** (quatrième message : « on a besoin de l'arabe ») | `build_site.py`, `content/pages.json`, `styles/site.css` | présent dans le code ; 17 versets identiques, lettre pour lettre, aux données du Mushaf de l'application ; 11 extraits de hadiths retrouvés mot pour mot dans le texte complet des recueils ; captures bureau et mobile |
| **Pied de page lisible** (cinquième message : « presque illisible, l'arrière-plan doit être moins foncé ») | fin de `styles/site.css` | présent dans le code ; fond violet profond `#4E2983` au lieu du prune `#25113F` ; texte blanc à 10,7:1, lavande à 8,0:1 ; la carte s'efface sous le petit texte ; captures bureau et mobile |
| **Bouton d'en-tête d'un seul mot** (« S'inscrire », à toutes les largeurs) | `build_site.py`, `styles/site.css` | présent dans le code ; « Commencer mon inscription » reste dans le corps (haut de l'accueil, fin des pages) |
| **Lumière lointaine à travers la porte, contenu qui flotte, lumières animées** | fin de `styles/site.css`, `build_site.py` | présent dans le code ; halo derrière l'arche de l'accueil, lueur dans l'embrasure, rayons qui tombent sur le chemin, porte de lumière lointaine au fond des pages, ombres portées des cartes et des illustrations, reflet sur le bouton principal ; captures, y compris pendant le passage de la porte |
| **Cartes du hub redessinées** (« je ne vois pas où cliquer » ; « trop moches, couleurs et formes uniformes ») | `build_site.py`, `styles/site.css`, `content/pages.json` | présent dans le code ; le plus récent à la une sur lavande claire ; les suivants illustrés, en verre clair en arche, violet profond, lavande au grand coin ; toute la carte est le lien, bouton « Lire l'article » ; le bouton du haut de la page mène à la liste ; captures bureau, mobile et production au 8 novembre |
| **Article « enfant fatigué » réécrit en profondeur** (« trop court, aucune valeur ») | `content/pages.json` | présent dans le code ; 2 032 mots au lieu de 865 (après la correction du 04/11) ; al-Ghazâlî, Ibn Khaldûn, cinq hadiths et quatre versets de plus, le sommeil (Paruthi 2016), tous vérifiés (§6) ; la phrase « ne portent pas sur le Coran » est retirée |
| **Parution programmée, deux jours d'écart au moins** | `build_site.py`, `content/pages.json` | présent dans le code ; 5, 8, 11 et 14 novembre ; testé localement à chaque date ; **automatique seulement si la production se reconstruit ces jours-là** (§7, point 6) |
| **Tout le site au mode clair de l'application** (sixième message, 04/11 : « le thème violet ne permet pas la lecture facile » ; « le violet devient rare, juste pour les CTA principaux ») | `content/direction.json` (`teinte: jour`), `build_site.py`, fin de `styles/site.css`, `DESIGN.md` | présent dans le code ; mise en page, images, mouvements et lumières inchangés, couleurs seules du thème clair de l'app ; violet plein sur les boutons seulement ; contraste de chaque texte mesuré sur 16 pages à 1440 et 390 px, appareil clair et sombre : aucun texte sous le seuil WCAG AA ; un test vérifie que chaque couleur du bloc vient de `app_palette.dart` |
| **Correction à la maison, avec sagesse** (relecture du directeur, 04/11) | `content/pages.json` | présent dans le code ; « enfant fatigué » et « apprendre le Coran à son enfant » : le parent peut corriger, doucement, une erreur à la fois, sans que l'enfant sente que le cours le suit partout ni que le Coran est une corvée ; une erreur qui revient se signale à l'enseignant |
| **Défauts signalés le 04/11** (cercles du simulateur déformés ; fiche « Les cours en bref », texte au bord, « ombre de PowerPoint des années 90 ») | fin de `styles/site.css` (commit `cfef9fa3`) | présent dans le code ; boutons « − » et « + » à 52 × 52 ; la fiche sans cadre ne reçoit plus d'ombre ; ombres des cartes courtes et centrées ; vu sur l'aperçu Vercel à 1440 et 390 px |
| **Le chemin de lumière** (septième message, 04/11 : élever l'arrière-plan et les liaisons entre les sections ; « j'aime bien le proto de la vidéo avec la ligne qui crée le mouvement » ; une lumière sur la ligne, qui éclaire ce qu'elle touche et laisse s'atténuer ce qui s'éloigne) | bloc « Le chemin de lumière » de `styles/site.css`, `preparerVoyage` dans `styles/motion.js`, `DESIGN.md` | présent dans le code, sur toutes les pages en teinte jour ; polices, logo et couleurs de marque inchangés. Fond continu dont la teinte suit la lecture, quatre lumières en profondeur, grain fin ; un fil violet qui longe les marges et ne traverse la page que dans un vide, dessiné jusqu'à la ligne de lecture ; sa lumière blanche sous ce qu'on lit ; titres et illustrations sans texte qui s'atténuent loin d'elle (jamais le texte courant) ; le panneau du directeur de nuit, qui s'ouvre en arche, et les bandes d'appel de fin en arche lavande. Contraste mesuré au pire cas (fond lavande, titres au plus atténué) sur 16 pages à 1440 et 390 px : aucun texte sous le seuil WCAG AA. Mouvement réduit : fil entier, sans pointe ni lumière, arches plates, rien d'atténué. Sans script : la page d'avant. Défilement : autant d'images lentes qu'avant (mesuré dans le navigateur sans carte graphique du conteneur) ; vidéo de l'accueil montrée au directeur |

Testé localement : 123 tests `python3 -m unittest discover -s site-public/tests` (80 au départ, 43 ajoutés), et 92 vues (23 routes à 360, 390, 768 et
1440 px) sans débordement horizontal, sans ressource en erreur, sans erreur JavaScript, refaites sur ce commit (blocs arabes et polices compris ;
captures des blocs arabes à 390 et 1366 px). Testé sur staging : l'aperçu de la PR 187 a servi les deux premiers commits ; les suivants
ne sont pas encore vus. Déployé : non.

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
- **Quatrième message (03/11, soir)** : « Là on a besoin de l'arabe, donc il le faut » : exception datée au registre M-29, **dans les articles
  seulement**, pour le texte original des versets et des hadiths cités. Et « si tous les articles sont publiés le même jour, à la même heure et par le
  même auteur, ça ne va pas marcher » : publication automatique séparée de deux jours au moins.
- **Cinquième message (03/11, soir)** : pied de page moins foncé ; bouton d'en-tête d'un seul mot, la formule longue dans le corps ; la phrase
  « ne portent pas sur le Coran » est technique, le public n'en a pas besoin ; l'article sur l'enfant fatigué est trop court ; la flottaison ne
  se voit pas : une lumière lointaine à travers la porte, un contenu qui flotte au-dessus d'une grande profondeur, des lumières animées pour
  souligner ce qui compte (cinq images d'inspiration : halos chauds, porte de lumière, faisceau, grand cercle lumineux lointain).

- **Sixième message (04/11)** : relecture de l'article sur la fatigue : « très bon article avec de la valeur » ; une seule chose à changer : le
  parent peut rectifier, mais avec sagesse ; l'enfant ne doit pas sentir que le cours le suit partout, ni que le Coran est une corvée. Et « le thème
  violet ne permet pas la lecture facile » : tout le site au mode clair de l'application, le reste ne change pas, seules les couleurs s'adaptent
  (filigrane, texte) ; le violet devient rare, pour souligner les choses très importantes comme les CTA principaux.

- **Septième message (04/11)** : le nouveau style est « trop banal », l'ancien « trop cheap » ; « crois-moi, ce qui manque vraiment c'est comment
  élever le niveau de l'arrière-plan pour ne pas que ça soit un simple PDF d'un document ms.word, les interactions entre les sections » ; « ne change
  pas le style de marque : utilise les polices et le branding de la marque, c'est pas ça que tu dois changer » (la maquette au titre en serif est
  abandonnée). Devant le prototype en vidéo : « j'aime bien le proto de la vidéo avec la ligne qui crée le mouvement » ; puis « si cette ligne pouvait
  aussi aller avec une lumière, tout ce qu'elle touche devient plus clair (mais lisible) et plus elle s'éloigne d'un élément celui-ci devient
  atténué ». L'agent a répondu : oui pour la lumière ; l'atténuation pour les titres et les illustrations, pas pour le texte courant, dont le gris
  passerait sous le seuil de lisibilité.

## 3. Choix de l'agent, modifiables en une ligne

- **Teinte jour (04/11)** : réglage `teinte` de `direction.json`, réversible en une ligne (`violet`). Choix faits pour rester dans le mode clair de
  l'app : le pied de page passe sur la lavande #EEE6FA (encre #110E20, carte du monde et symbole en violet pâle), pas sur un fond sombre, puisque le
  pied sombre gênait déjà la lecture ; les bandes sombres (prune, panneau du directeur, appel) deviennent des bandes blanches ; les progressions (étapes,
  tuiles, parcours, dates du paiement) vont du blanc au lilas #BA98FB sans aplat violet ; la carte « Le plus récent » est lavande, les autres blanche,
  lilas ou blanche selon leur rang ; le site reste clair même si l'appareil est en mode sombre (c'est le mode clair de l'app qui est demandé). Le
  violet plein : boutons principaux, « S'inscrire », bouton des bandes d'appel, « Lire l'article », puces, étoiles, filet des citations du Coran, focus.

- **Chemin de lumière (04/11)** : la toile de l'app (#F1EFF4) sert de base et une section sur quatre, avec celles qui étaient lavande, passe à
  la lavande (#EEE6FA), pour que la lumière blanche du fil se voie (sur du blanc, elle est invisible) ; les bandes blanches d'avant prennent la mise
  en avant (#F7F5FE). La lumière se tient sur la ligne de lecture (58 % de l'écran), entre le milieu de la page et la pointe du fil. S'atténuent :
  les titres de section, jusqu'au plancher qui garde leur contraste WCAG AA (calculé pour leur couleur sur le fond le plus foncé du parcours), et
  les illustrations qui ne portent aucun texte (jusqu'à 55 %). Le dégradé fixe, les halos, l'arche géante et la porte lointaine du fond laissent la
  place à la couche continue (le prototype vu par le directeur les retirait). Le panneau du directeur devient une bande de nuit #25113F, la seule
  grande surface sombre du site, comme dans la vidéo ; s'il la trouve trop forte, une ligne la rend à la bande blanche.

- `bloc_avis.AVIS_MOYENNE_MIN = 5` et `AVIS_APERCU_MIN = 3` : pas de moyenne avant 5 avis, pas d'aperçu avant 3 ; les trois plus récents, jamais les mieux notés.
- **Filigrane géant derrière du texte conservé** (4 à 6 % d'opacité) : le README du logo l'autorise pour `ornement-contour` et `symbole-contour` (« filigrane
  très grand ») ; il ne dit « jamais derrière du texte » que pour le logo lui-même, qui n'est jamais rendu transparent. Si le directeur préfère, on le restreint.
- **Pas de mesure d'audience ajoutée.** Elle exige d'activer Vercel Web Analytics (geste du directeur) et de dire la mesure dans la politique de confidentialité
  (texte juridique). Google Analytics et Microsoft Clarity restent déconseillés (consentement exigé en France ; sessions enregistrées sur un site pour des familles).
  Tant qu'elle n'existe pas, aucune donnée de trafic n'est lisible : seule la Search Console compte les impressions.
- **Auteur des articles : le directeur** (signature sous le titre, lien vers « Le mot du directeur », balisage `Person`), comme il l'a demandé. Un seul
  auteur, réel et présenté, n'est pas un défaut pour les moteurs ; un auteur inventé en serait un. Signer du nom d'un autre fondateur demanderait son accord.
- **Parution** : jeudi 5 novembre (enfant), dimanche 8 (seul sans maître), mercredi 11 (groupe), samedi 14 (enfant fatigué) : deux par semaine, en
  alternant les publics. La date est le jour de parution ; avant elle, la production ne contient ni la page, ni sa carte, ni sa place dans le plan du site,
  ni aucun lien qui y mène, et le hub reste hors de l'index tant qu'aucun article n'est paru. Un aperçu montre tout, marqué « À paraître le … ».
  Le jour est celui du serveur de construction (UTC). Pas d'heure : la date seule est publiée, comme avant.
- **« Occident »** est employé, comme le directeur l'a demandé, avec « et partout où les musulmans vivent en minorité » pour ne pas exclure les
  familles qui vivent ailleurs. La règle de marque vise les noms de pays et de continents ; « Occident » n'en est pas un.
- **L'arabe, depuis le quatrième message** : chaque citation française d'un verset ou d'un hadith est suivie, en bloc, de son texte arabe (`lang="ar"`,
  `dir="rtl"`, légende en français). Versets : texte KFGQPC UthmanicHafs v3.0 du paquet `@quran.ws/text` 0.1.0, celui du Mushaf de l'application,
  avec ses signes de pause et le numéro en rosace (chiffres arabo-indiens) ; un extrait français est suivi du verset entier, signalé. Hadiths : seule la
  parole citée, sans la chaîne de transmission, dans la forme exacte du jeu public hadith-api (copie des textes de sunnah.com). Hors de ces blocs, le
  français reste français : l'eulogie s'écrit toujours « (paix et bénédictions sur lui) » et qalb, kalb en lettres latines (lisibles par tous les lecteurs
  d'écran). Le test M-29 garde l'arabe hors de toutes les autres pages et hors du texte français des articles.
- **Polices de l'arabe** : les deux fichiers du Complexe du Roi Fahd déjà dans `assets/fonts` (UthmanicHafs pour le Coran, Uthman Taha Naskh pour les
  hadiths, tous deux dans la charte), copiés **tels quels** avec leur licence : elle permet d'utiliser, de copier et de distribuer, jamais de modifier,
  donc ni sous-ensemble ni woff2. Coût : 294 Ko et 161 Ko, chargés par les seuls articles, une fois pour toutes (cache). Noto Sans Arabic (libre, réductible)
  a été écartée : un hadith en linéale à côté d'un verset en naskh se voyait.
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

- **Lumières (cinquième message)** : la lumière n'entre que par les portes, motif de la marque : l'arche de l'accueil (halo, lueur, rayons) et une
  porte lointaine au fond des pages. Aucune lueur derrière les autres illustrations : les puits de lumière du premier essai avaient été retirés
  (`UX_REVIEW_SITE-MOUV-1.md`, V4). Teintes : blanc et lavandes des jetons ; l'orange des images d'inspiration est hors de la palette (M-16), on en
  garde la douceur. Là où un texte peut passer, une lumière ne dépasse pas 12 % de blanc (texte blanc mesuré à 5:1 au moins) ; sous les liens de
  l'en-tête, 10 %. **Exception datée au contrat E** (plafond de 400 ms, règle gelée) : respirations de 6 à 11 s et reflet du bouton principal toutes
  les 8 s, sur le site public seulement, demandées par le directeur le 03/11 ; en mouvement réduit, tout s'arrête (règle générale du site).
- **Bouton d'en-tête** : « S'inscrire » partout. La compétence `mots-rewayah` dit encore « S'inscrire sous 1100 px, Commencer mon inscription
  au-delà » : à mettre à jour par le pilote (§7).

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
   (superlatif que rien ne prouve ; un institut cité demande des prix très bas en groupe, d'après son site). « Occident » avait d'abord été écarté
   (nom de région) ; le directeur l'a demandé à la troisième relecture, il est employé (§3).
6. **Le pied de page avait été compacté** après une revue de trois jurés ; la demande du 03/11 l'emporte.
7. **Erreur de l'agent sur les avis, corrigée.** J'avais écrit au directeur que `/fr/avis` était hors de l'index : c'était vrai de ma construction
   locale (sans base, zéro avis), faux en production. Vérifié le 03/11 : la production sert `/fr/avis` en `index,follow` et la met dans son plan du
   site, parce que sa construction lit les avis publiés dans la base (`avis_publics()`) et y a trouvé les deux avis de test. L'indexation ne « sait »
   rien d'autre : elle compte, à chaque construction, les avis publiés. Quand le directeur les aura supprimés, la construction suivante de la
   production remettra `/fr/avis` en `noindex` et la retirera du plan du site, sans intervention. D'ici là, Google peut l'indexer.

## 5. Ce qui n'est PAS fait

- **Passe mobile générale** (paddings, tailles de police, espacement des cartes) : seul le menu est traité. Revue page par page à 360 et 390 px à faire.
- **Refonte des animations** au-delà des cartes, des boutons et des liens du pied.
- **Hub : 4 articles** (2 réécrits, 2 nouveaux). Les autres sujets du plan sont à écrire un par un, signés et relus ; aucun n'est publié en série.
- **Mesure d'audience** (voir §3).
- **Rendu du chemin de lumière vérifié sur l'aperçu Vercel** : pas encore (le commit qui l'apporte est le dernier) ; captures et vidéo locales seulement.
- **Fil sur un vrai téléphone** : vérifié seulement à 390 px dans le navigateur ; la fluidité sur un téléphone d'entrée de gamme n'est pas mesurée.
- **Construction automatique les jours de parution** : non. Elle touche `.github/workflows/flutter-deploy.yml`, zone interdite aux agents (§7, point 6).
- **Registre de marque M-29** : l'exception datée du 03/11 est écrite ici et dans les tests, pas encore au registre (`docs/current/marque/`), hors de ma zone.

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

**Texte arabe** (ajouté le 03/11, soir). Versets : `@quran.ws/text` 0.1.0, `data/hafs.json` (SHA-256 `31186b3a…2568`, la même empreinte que
`lib/core/tc_coran/donnees/LISEZMOI.md`), signes de pause rattachés comme le fait `tool/generer_layout_madina_15.dart` ; le test
`test_les_versets_sont_ceux_du_mushaf_de_l_application` compare chaque verset aux fichiers générés de l'application. Hadiths : extraits retrouvés dans
le texte arabe complet (chaîne comprise) d'al-Bukhârî 5027, 893, 6, 5000, 4999, 69, 2101, de Muslim 798 a, 783 b, 2699 a et d'Abû Dâwûd 4833 ; la
source écrit la chadda avant la voyelle, la forme publiée est celle de la source. Le hadith du vendeur de musc, évoqué sans guillemets, reçoit
l'arabe de la comparaison seule (al-Bukhârî 2101, signalé « extrait »).

**Article « enfant fatigué », sources ajoutées le 03/11 au soir** (agent de vérification dédié, aucun blocage contourné ; sunnah.com,
le journal de l'AASM et Springer n'ont pas pu être lus). Versets (Hamidullah, quran.com) : 2:286, 94:5-6, 25:74 (« Notre Seigneur! »), 14:40.
Hadiths : « Allah est Doux, et Il aime la douceur en toute chose » est **al-Bukhârî 6927** (et non Muslim : 2165 n'a pas « Doux », 2593
continue autrement), traduction du sens ; Muslim 2594 (traduction HadeethEnc 5796) ; Anas, al-Bukhârî 6038 et Muslim 2309 (traduction du
sens) ; « N'est pas des nôtres… » cité d'après **at-Tirmidhî 1920 et Abû Dâwûd 4943** (traduction HadeethEnc 3083 ; at-Tirmidhî 1919 est
« gharîb » selon at-Tirmidhî lui-même, 1921 est faible, non cités) ; la prière abrégée, al-Bukhârî 707 et Muslim 470 (HadeethEnc 4249).
Ibn Khaldûn : De Slane, troisième partie, p. 290-291, chapitre « Trop de sévérité dans l'enseignement des élèves leur est nuisible » (relu
sur les images des pages ; l'article dit qu'il met en garde contre l'excès, pas contre toute exigence, comme son texte). Al-Ghazâlî :
*Iḥyâ'*, éd. Dâr al-Ma'rifa, t. 3, p. 73 (Shamela 9472/819) ; aucune traduction française publiée trouvée : traduction du sens, signalée.
Sommeil : Paruthi et coll., *J Clin Sleep Med* 2016, DOI 10.5664/jcsm.5866 (9 à 12 heures de 6 à 12 ans, 8 à 10 heures de 13 à 18 ans).

**Faits sur Rewayah** dans les articles : seulement ceux que le site publie déjà (classes de 3 à 5 enfants de 6 à 17 ans, trois séances d'une heure ;
classes de 3 à 6 adultes, trois séances d'1 h 30 ; ouverture dès trois inscrits ; observation du parent, deux minutes ; compte rendu de fin de semaine ;
les étapes des bases).

## 6 bis. Pages non indexées (question du directeur, 03/11)

En production, toutes les pages prêtes sont indexables, dont `/fr/contact` (et les adresses qu'elle donne, écrites de façon illisible pour les robots
collecteurs, pas pour les moteurs), les pages légales et les articles parus. Non indexées, volontairement : `/fr/avis` tant qu'aucun avis n'est publié
(**correction, §4 point 7** : elle est indexée en ce moment, à cause des deux avis de test), `/fr/articles` tant qu'aucun article n'est paru, la page 404,
et `/fr/courriels/desinscription`. Deux domaines entiers
répondent `noindex` : `app.rewayahacademy.com` (l'application, ses écrans de connexion) et `rewayah-academy.vercel.app` (copie technique du site, qui
ferait doublon). Les aperçus des PR sont toujours `noindex`. C'est ce que signale la Search Console le 26/10 : pas une panne.

## 7. Décisions encore ouvertes

1. Relire les quatre articles (citations, ton, et la signature) et la page des autres chemins. Rien ne se fusionne sans cette relecture.
2. Qui relit `le-coran.com` avant de le citer ?
3. Activer Vercel Web Analytics, avec le texte de confidentialité correspondant ?
4. Vercel : le plan Pro règle la saturation des déploiements (le pilote l'a déjà proposé).
5. Lancer la passe mobile et les animations après cette tranche ?
6. **Pour le pilote : rendre la parution vraiment automatique.** Le site ne se reconstruit en production qu'à une poussée sur `main` (ou à un
   lancement manuel). Un article daté du 8 paraît donc à la première construction de production du 8 ou après. Trois voies, au choix du pilote ou du
   directeur : (a) ajouter à `flutter-deploy.yml` un déclencheur `schedule` (par exemple `cron: '17 4 * * *'`, 04 h 17 UTC chaque jour ; la règle
   « cible » du workflow traite déjà un `schedule` sur `main` comme la production) ; (b) le restreindre aux jours de parution
   (`cron: '17 4 5,8,11,14 11 *'`) ; (c) sans changer le workflow, le directeur lance « Run workflow » sur `main` dans GitHub Actions ces jours-là.
   La voie (a) redéploie chaque jour le même bundle (application comprise) : une construction et un déploiement Vercel par jour.
7. **Pour le pilote : la garde du workflow.** `flutter-deploy.yml` vérifie, après la construction, la présence de quatre polices du site. Ajouter
   `fr/assets/UthmanicHafs-v-3.0.ttf` et `fr/assets/UthmanTahaNaskh-Regular.otf` à cette liste (le test du site le dit, et vérifie déjà les fichiers octet
   pour octet).
8. **Pour le pilote : registre de marque M-29.** Y inscrire l'exception datée du 03/11 (arabe des citations, dans les articles seulement).
9. **Pour le pilote : `mots-rewayah`**, ligne « S'inscrire » : le bouton court vaut désormais à toutes les largeurs (directeur, 03/11).
10. **Pour le pilote : `DESIGN-GOV-2026-09-26.md`, contrat E.** Y noter l'exception datée du 03/11 pour le site public (lumières lentes, reflet du
    bouton principal), si le directeur la confirme comme règle et non comme essai.
11. **Pour le pilote : registre de marque (O-16 et cahier visuel).** Le site passe au mode clair de l'app (directeur, 04/11) ; il garde un
    dégradé de fond très léger (blanc en haut à gauche, lavande en bas à droite), dans la dérogation O-16 déjà inscrite.
12. **Pour le directeur : le chemin de lumière sur l'aperçu.** Garder la nuit du panneau du directeur et l'atténuation des titres ? Chacun se
    retire en une ligne. **Pour le pilote** : le registre de marque (cahier visuel) n'a ni fil ni fond continu ; à y inscrire si le directeur garde.

## 8. Vérifier

```
python3 -m unittest discover -s site-public/tests
python3 -I site-public/carte_monde.py chemin/vers/ne_110m_land.geojson   # régénère assets/carte-monde-points.svg (identique)
python3 site-public/build_site.py --output /tmp/site && cd /tmp/site && python3 -m http.server 8770
```

Un aperçu (sans `--allow-indexing`) montre les quatre articles, marqués « À paraître le … » avant leur date. La production du jour J ne publie que
ceux dont la date est passée ; `tests/test_articles.py` (classe `Parution`) le vérifie à chaque date.
