# SITE-REFONTE : fiche du 03/11/2026 (site public)

Demande du directeur du 03/11/2026 (session claude.ai « Rewayah Academy site final version »), zone `site-public/**` et cette fiche
seulement. Feu vert du pilote à 16:00 : committer et pousser la branche `claude/happy-mccarthy-meqjyy`, **ne pas ouvrir la PR avant
son signal** (Vercel a refusé trois déploiements aujourd'hui ; 30 déploiements en 4 h 30).

**Statuts (CLAUDE.md : un statut par ligne, aucun PASS inventé).** « Présent dans le code » et « testé localement » ne veulent pas dire
« déployé » : rien de ceci n'est sur `main`, rien n'est sur un aperçu Vercel, rien n'a été vu par le directeur en production.

## 1. Ce qui est fait dans le code

| Demande | Où | Statut |
| :--- | :--- | :--- |
| Retirer le mot « Menu » à côté de l'icône mobile | `build_site.py` (summary), `styles/site.css` | présent dans le code ; capture 390 px ; le mot reste lu par les lecteurs d'écran (`.sr-only`) |
| Effets de profondeur : arche géante lointaine, halos d'ambiance, cartes flottantes | fin de `styles/site.css` (« Profondeur ») | présent dans le code ; captures 1440 et 390 px ; mouvement lié au défilement seulement, fixe si « mouvement réduit » |
| Pied de page grand et aéré, filigrane du symbole | `build_site.py`, bloc « Pied de page » de `site.css`, `assets/symbole-contour-white.svg` | présent dans le code ; captures ; hauteur de 237 à environ 570 px au bureau |
| Carte du monde tamisée dans le pied de page (demande du 03/11) | `carte_monde.py`, `assets/carte-monde-points.svg` | présent dans le code ; points sans frontière ni nom ; données Natural Earth (domaine public) |
| Jonctions douces entre les bandes de couleur (demande du 03/11) | fin de `styles/site.css` (« Jonctions douces ») | présent dans le code ; captures de 5 jonctions |
| Avis chaleureux, aperçus sur l'accueil et trois pages | `bloc_avis.py`, `build_site.py`, `site.css`, `tests/test_avis.py` | présent dans le code ; testé localement avec des avis **fictifs** (jamais commités) |
| SEO technique | `build_site.py` | présent dans le code : dimensions de l'image OG (18 pages sur 18 égales aux fichiers réels), fil d'Ariane sur 16 pages (ni l'accueil, ni `/fr/avis`) |

Testé localement : 90 tests `python3 -m unittest discover -s site-public/tests` (80 au départ, 10 ajoutés), et 72 vues (18 routes à 360, 390,
768 et 1440 px) sans débordement horizontal, sans ressource en erreur, sans erreur JavaScript. Testé sur staging : non. Déployé : non.

## 2. Ce qui n'est PAS fait (à dire clairement)

- **Mobile : la passe générale sur les paddings, les tailles de police et l'espacement des cartes n'est pas faite.** Seul le menu l'est.
  Elle demande une revue page par page à 360 et 390 px avec captures ; je l'ai écartée pour ne pas la bâcler.
- **Animations : pas de refonte des animations d'apparition ni du survol** au-delà des cartes, des boutons et des liens du pied.
  Le contrat de mouvement (plafond 400 ms, durée 0 en mouvement réduit) est respecté pour tout ce qui est ajouté.
- **Contenu éditorial** (transparence, local d'abord, diaspora, page des autres chemins, hub d'articles) : **rien n'est écrit dans le site.**
  Les textes proposés sont au §5, à valider ; ils parlent de tiers et engagent la marque.
- **Rapports Google et Microsoft** : voir §3, ils ne contiennent aucune donnée de performance exploitable.

## 3. Constats qui changent le plan (vérité d'abord)

1. **Aucune mesure de trafic n'existe.** Vercel Web Analytics n'est pas activé sur le projet (`web_analytics_not_enabled`). Aucun e-mail
   Clarity ni Analytics n'a jamais été reçu. Les cinq e-mails Google et Bing de la boîte `staff@` disent seulement : propriété validée le
   23/10 ; impressions comptées depuis le 24/10 (sans chiffre) ; « exclue par noindex » et « page avec redirection » (26/10) ; scan Bing
   « 1st » lancé (son rapport n'est que dans l'interface Bing) ; un modèle générique sur « www.website.com ». Le message du 26/10 décrit
   un comportement voulu : `app.` est en `noindex` et `www` et la racine redirigent. **Ce n'est pas une panne.**
   Les notes des pilotes disent « Search Console et Bing non faits » : c'est en retard, les e-mails prouvent l'inverse.
2. **`/fr/articles` annonce « Aucun article n'est encore publié » et est `indexable: false`, alors que la navigation y renvoie.**
   18 pages, presque toutes produit ou juridique, zéro contenu éditorial : c'est le levier organique principal, et il est vide.
3. **Les deux avis publiés** sont signés « A.M. SOW, Arabie saoudite » et « Dynah, Guinée ». Le premier correspond aux initiales, au nom et au pays
   du directeur (registre M-21). Origine des deux : **inconnue** (les pilotes ne savent pas). Décision du 19/10 : accord de publication et
   lecture par la direction. Une vitrine de preuve sociale construite sur deux avis internes nuit à la marque : d'où les seuils du §4.
4. **Vercel est saturé** : 30 déploiements en 4 h 30 ; chaque PR vers `main` qui touche `site-public/**` ajoute un aperçu.
5. **Le pied de page avait été compacté volontairement** après une revue de trois jurés. La demande du directeur du 03/11 est plus
   récente et l'emporte ; les règles de compaction ont été retirées sur place (commentaire dans `site.css`).

## 4. Choix que j'ai faits à ta place (modifiables en une ligne)

- `bloc_avis.AVIS_MOYENNE_MIN = 5` : pas de moyenne chiffrée avant 5 avis ; avant, la page dit « N avis publiés pour l'instant, lus par la
  direction avant publication et jamais retouchés ».
- `bloc_avis.AVIS_APERCU_MIN = 3` : l'aperçu (accueil, cours, familles, tarifs) n'apparaît qu'à partir de 3 avis ; il montre les **trois plus
  récents**, jamais les mieux notés. **Avec les 2 avis d'aujourd'hui, rien ne s'affiche sur l'accueil.**
- Une grille, pas de carrousel (décision du 01/11 : aucun contenu qui défile dans un cadre).
- Aucun balisage d'étoiles pour les moteurs (décision du 19/10 ; Google n'affiche pas les étoiles d'avis qu'une entreprise publie sur elle-même).
- Aucune couleur nouvelle, aucun nouveau dégradé de décor : jetons existants ; les halos et les jonctions réutilisent la dérogation O-16 (page violette).
- Le logo n'est ni modifié ni rendu transparent. Le filigrane géant utilise `ornement-contour` (autorisé « arrière-plan » par `assets/brand/logo/README.md`),
  celui du pied utilise `symbole-contour` (« filigrane très grand »). Le test `test_logo_files_are_the_official_ones` vérifie qu'ils sont identiques aux originaux.
  Point à trancher par le directeur : le README dit aussi « jamais derrière du texte » pour le logo ; le filigrane passe derrière du texte à 4 à 6 % d'opacité.

## 5. Textes proposés, NON publiés (à valider, mots exacts à arrêter par le directeur)

Règles tenues : pas de « meilleur », « certifié », « garanti » ; pas de nom de pays ni de continent ; pas de tiret long ; le présentiel d'abord
(vérité fondatrice de la marque).

**Transparence.** « Nous avons commencé le 1er mai 2024. Nous sommes jeunes et nous le disons : nous construisons pas à pas, avec les familles
qui nous font confiance. Nous préférons vous dire ce que nous ne savons pas encore plutôt que promettre ce que nous n'avons pas prouvé. »

**Le présentiel d'abord.** « Si vous avez près de chez vous un bon enseignement du Coran, en présence, choisissez-le d'abord : rien ne remplace
une salle, une mosquée, un enseignant que l'on croise. Rewayah existe pour les familles pour qui ce n'est pas possible. »
*Écart avec la demande :* « la meilleure alternative » est écrit comme interdit par la marque (« le meilleur », et jamais « le distanciel est supérieur »).

**Nos familles vivent loin des écoles coraniques.** « Chaque jour, nous travaillons à leur offrir un enseignement rigoureux. Nos prix sont publiés, hors taxes,
et nous expliquons où va chaque paiement. »
*Écart avec la demande :* « les coûts les plus bas possibles » est un superlatif que rien ne prouve (un institut cité demande 5 € de l'heure en groupe, d'après son site).
« Occident » est écarté : nom de région, interdit par la règle sur les pays et continents.

**Notre manière (différence, sans comparer).** « Une classe chez Rewayah, c'est un enseignant attitré, un horaire fixe et quelques élèves qui avancent ensemble.
Ils s'encouragent sans se comparer. La récitation se reçoit de vive voix, de l'enseignant à l'élève. »
(Le terme « talaqqî » n'est pas dans le registre : à décider.)

**Page « Autres chemins pour apprendre le Coran » (proposition).** Ordre alphabétique par format, jamais de classement, aucun prix, chaque ligne « d'après son site,
consulté le 03/11/2026 », aucun lien demandé en retour. Ce que j'ai **lu** sur chaque site, et ce qui contredit ta classification :

| Site | Ce que son site dit | Remarque |
| :--- | :--- | :--- |
| Noor Elbayan Academy | cours individuels en direct, tous âges, enseignants « avec ijaza à chaîne continue », essai annoncé gratuit | site en arabe |
| Quran Web Learning | cours 1 contre 1 dès 4 ans, programmes pour femmes avec enseignantes, 4 langues dont le français | |
| Institut Al Rayhan | cours en ligne (Zoom), individuel ou groupe de 5 au plus, dès 6 ans | **100 % en ligne, pas un « institut installé » ; année de fondation non indiquée ; compteur « diplômes délivrés + 0 »** |
| Institut As-Sahaba | cours en visioconférence, individuel, binôme ou groupe, professeurs bilingues | **100 % en ligne ; fondé en 2016 ; aucune mention d'ijaza** : « certifications rigoureuses » ne se lit pas sur son site |
| House of Quran | outils en ligne : récitation mot à mot et mémorisation | outils, pas des cours ; « gratuit » : seul le titre de la page le dit |
| Le-Coran.com | **non vérifié** : le site a répondu 403 à la lecture automatique | à relire par une personne avant toute phrase |

Les adresses données dans la demande n'avaient pas leur `https` : elles ne fonctionnent pas telles quelles.

## 6. Liens et backlinks : la règle exacte

Un lien **de** notre site **vers** un autre site n'est pas un backlink pour nous (Mueller, Google, 31/07/2023 : « Nothing happens. Why should it? »).
Cette page ne rapporte donc rien en référencement ; elle est utile au lecteur et à la confiance, et neutre pour le classement. Elle devient risquée seulement avec
une réciprocité organisée ou une contrepartie (spam policies de Google : « échanges excessifs », pages partenaires). Règle : 5 à 8 sites, lien sans attribut, aucune
demande en retour. « Insérer discrètement » des liens est contraire à l'esprit « transparence radicale » : ils doivent être assumés et expliqués.

Vrais backlinks, du meilleur rapport effort/effet au pire (rapport d'un sous-agent, sources à relire, effet chiffré **non vérifié**) : ressources partageables
(fiche imprimable « lire le Coran à 6 ans », calendrier de rentrée et de Ramadan) ; mosquées et associations (offrir la fiche) ; podcasts ; presse locale ou
communautaire sur une actualité réelle ; messages courtois aux autres instituts, sans demander de lien ; profils de marque reliés par `sameAs` (déjà en place).
À éviter : achat ou troc de liens, annuaires de faible qualité, Wikipédia (trop tôt, conflit d'intérêts), publier 15 articles d'un coup.

## 7. Mesure d'audience : à décider

Kit minimal proposé (5 outils, tous gratuits) : Search Console, Bing Webmaster (déjà là), une mesure **sans cookie** (Vercel Web Analytics, si le plan Hobby l'autorise
à usage commercial : **non vérifié** ; sinon Plausible), PageSpeed Insights, Rich Results Test. **Google Analytics 4 et Microsoft Clarity déconseillés** : la CNIL
cite Google Analytics parmi les offres hors exemption ; Clarity exige un consentement depuis le 31/10/2025 (EEE, Royaume-Uni, Suisse) et enregistre des sessions, sur
un site pour des familles et des enfants. Aucun outil n'est « validé » par la CNIL. Activer l'outil sans cookie est un geste du directeur (Vercel) ; il se décrit alors dans la
politique de confidentialité.

## 8. Hub d'articles (un à la fois, signé par un enseignant nommé, relu par l'académie)

4 piliers, 11 articles liés, volumes « à mesurer dans Search Console » (aucun chiffre inventé) :
A. Le Coran en ligne : marche-t-il, comment choisir (classe ou cours particulier ; questions avant de s'inscrire ; lire à 6 ans ; adulte débutant).
B. À quel âge commencer (enfant fatigué et trois séances par semaine ; préparer sans conflit ; il veut arrêter).
C. Sécurité d'un enfant en visio (ses données ; temps d'écran utile ; matériel et coin calme). Seuil de 15 ans et accord parental : à contrôler sur Légifrance.
D. Transmettre le Coran loin d'une mosquée (routine de rentrée et de Ramadan : avant le début de Ramadan 2027, à confirmer).
Aucun avis religieux sur l'âge : conseil pédagogique seulement. Le vocabulaire est celui de `mots-rewayah`.

## 9. Décisions à prendre par le directeur

1. Les deux avis publiés : les garder, ou les retirer (outil `avis_moderer`, motif obligatoire) ? Et avec quel message pour la collecte de nouveaux avis ?
2. Les textes du §5 : lesquels publier, avec quels mots ? La page « Autres chemins » : oui ou non, et qui relit Le-Coran.com ?
3. Seuils des avis (§4) : 5 et 3 te conviennent-ils ?
4. Mesure d'audience (§7) : activer Vercel Web Analytics ?
5. Le filigrane géant derrière du texte (§4) : accepté, ou à restreindre aux zones sans texte ?
6. La page `/fr/articles` vide : masquer son entrée de menu jusqu'au premier article, ou publier un premier article tout de suite ?
7. Vercel : le plan Pro règle la saturation (le pilote l'a déjà proposé) ; le coût de la PR de ce lot en dépend.
8. Passe mobile générale et animations : à lancer après la validation de cette première tranche ?

## 10. Vérifier

```
python3 -m unittest discover -s site-public/tests
python3 -I site-public/carte_monde.py chemin/vers/ne_110m_land.geojson   # régénère assets/carte-monde-points.svg (identique)
python3 site-public/build_site.py --output /tmp/site && cd /tmp/site && python3 -m http.server 8770
```
