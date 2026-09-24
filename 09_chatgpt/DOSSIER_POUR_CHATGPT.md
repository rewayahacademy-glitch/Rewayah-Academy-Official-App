# DOSSIER POUR CHATGPT : faits vérifiés de Rewayah Academy

Préparé le 24/09/2026 par Claude Code (coordinateur), à partir du dépôt au commit `cefab7f` (branche `ui/tuteur-v1`) et des documents du directeur. Tout ce qui suit est sourcé ; ce qui n'a pas pu être prouvé est marqué « à vérifier ». Tu n'as pas accès au code : ce dossier est ta seule source sur l'existant.

## 0. L'essentiel, à lire en premier

1. **Application** : Flutter (Android, iOS, web), Supabase, LiveKit, stockage R2. Cours de Coran en visio par **classes stables** (groupe fixe, horaire récurrent, enseignant attitré). Rôles : tuteur (famille), élève adulte, élève enfant (Interface guidée), enseignant, administration, contrôleur, contrôleur invité, finance et comptable.
2. **Ordre des vagues** décidé par le directeur (section B) : Tuteur V1 (en cours de construction), puis **Classe et visio (priorité n° 1 : un élève et un enseignant se rencontrent et se voient)**, puis validation des dossiers par l'admin, backend, puis les autres rôles, le lecteur du Coran, la landing web, la publication.
3. **Système de design GELÉ** (section C) : palette, polices DM Sans (titres) et Plus Jakarta Sans (tout le reste), rayons, espacements, composants. Aucune nouvelle couleur ni police. Les maquettes existantes donnent la DISPOSITION, pas les couleurs.
4. **Règles du directeur** (section A, §1 bis et suivants) : une fonction = un seul endroit ; carte groupée = un seul rectangle à fins filets ; navigation, retour et déconnexion toujours accessibles ; web = vraie version ordinateur ; rien d'affiché comme fait sans garantie serveur ; plan fermé.
5. **Faits de produit tranchés par le directeur** : l'enregistrement audio des cours est RÉEL (bucket R2 dédié), la notice « Cours enregistré, visite de contrôle possible. » est conservée ; observation par le parent : 2 visites de 2 minutes par parent et par séance, une visite écourtée est consommée ; salle d'observation épurée avec un bandeau pleine largeur (décompte seconde par seconde, « 1/2 visite restante pour cette séance »).
6. **Deux points à signaler au directeur, pas à trancher seul** :
   - une règle d'éthique visuelle ancienne (archivée, section C) interdisait les images générées par une IA et recommandait vert et or pour les accents religieux. Le directeur te demande aujourd'hui de générer des maquettes : sa demande récente prime pour des MAQUETTES de travail, mais signale dans chaque document que les visuels destinés au public (icône, captures des stores, illustrations) doivent être validés contre cette règle ;
   - le dépôt ne contient **aucun logo** et l'icône de l'application est celle de Flutter par défaut : à prévoir dans le document de publication.

## Sommaire

- A. Décisions du coordinateur et réponses du directeur (fichier `03_DECISIONS_COORDINATEUR.md`)
- B. Vagues du projet et backlog de la vague Classe et visio
- C. Système de design gelé (valeurs réelles du code)
- D. Tuteur : écrans et états sans maquette, maquettes existantes et leurs erreurs
- E. Inventaire des écrans de tous les autres rôles, avec l'état réel du code
- F. Mandat original du directeur pour le rôle Tuteur (référence du niveau de détail attendu)

---



---


# A. Décisions du coordinateur et réponses du directeur

# 03 - Décisions du coordinateur (Lot 0)

Date : 24/09/2026. Statut : arbitrages RÉVERSIBLES pris pour ne pas bloquer le chantier, sur une branche locale non poussée. Chaque point marqué **[DIRECTEUR]** reste à confirmer avant toute fusion dans `main` ; il est repris dans le rapport final.

Sources : `01_visuel/00_MANIFESTE.md`, `02_code/00_*.md` (mapping, contrats, ownership, dépendances, contradictions).

## 1. Git et environnement

| Sujet | Décision |
|---|---|
| Base | `c0/configuration-baseline-2026-09-23` @ `3cf3544` (porte `docs/current`, `lib/` identique à `main` aux commentaires près). |
| Branche d'intégration | `ui/tuteur-v1`, worktree `D:\RA_TUTEUR\integration`. Commits locaux uniquement : **aucun push**, aucune PR, aucun merge `main`. |
| Branches de lot | `ui/tuteur-v1-<lot>` (a, b, c, cobs, d, e), worktrees `D:\RA_TUTEUR\lot-<lot>`, issues de `ui/tuteur-v1` après la phase 0. |
| Style de commit | Conventionnel en français, comme le dépôt : `feat(tuteur-foyer): ...`, `fix(...)`, `chore(...)`. Message sans emoji ni M-dash. |
| Commandes lourdes | Toujours via `D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1` (verrou système). Analyse ciblée et tests ciblés dans les lots ; analyse complète, suite complète et build web réservés au coordinateur. |
| Frontière backend | `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc` doit rester vide. |
| i18n | Chaque lot committe **ses** clés dans `assets/i18n/fr.i18n.json` sous **ses** espaces de noms (`00_OWNERSHIP.md` §4), jamais une clé d'un autre espace ; il régénère (`dart run slang`) pour compiler. À l'intégration, le coordinateur résout les conflits JSON par union des espaces de noms et régénère. Les squelettes d'espaces de noms sont créés en phase 0 à des emplacements séparés du fichier. |

## 1 bis. RÉPONSES DU DIRECTEUR (24/09, elles PRIMENT sur le §2 ci-dessous)

1. **Classes factices ou réelles** : l'application n'est pas officiellement lancée ; le déploiement sert au directeur à voir le rendu. Des classes de démonstration sont acceptables. Conséquence : les adaptateurs réels restent le défaut, ET un **mode démonstration tuteur explicite et isolé** (données fictives, aucun appel serveur, repère discret « Démonstration ») est ajouté pour que le directeur voie le rendu complet sur l'aperçu. Jamais de repli silencieux d'un service réel vers des fixtures.
2. **Enregistrement audio : il est RÉEL** (bucket R2 dédié, Cloudflare). On **garde la notice** : `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. » (valeur de la base `3cf3544`), `contrat.pointEnregistrement` et `enseignant.profil.contratAccuse` inchangés. **Aucune** modification de libellé d'enregistrement issue de `33503fe` ne doit subsister (si elle a été reprise, la rétablir à la valeur de `3cf3544`).
3. **Consentement d'observation** : rédiger un paragraphe en mots clairs et bienveillants, pour que les familles comprennent réellement de quoi il s'agit (qui peut observer, ce qu'il entend et voit, ce qu'il ne peut pas faire, pourquoi, limites de visites). Nouvelle version du texte signé = texte existant (notice d'enregistrement comprise) + ce paragraphe ; variantes responsable légal et élève adulte ; case non précochée.
4. **Quota de visites** : **par parent** (par compte observateur), **2 visites par défaut par séance** (par salle), que la salle contienne un ou plusieurs de ses enfants. **Une visite écourtée est consommée** et n'est pas reconduite : le parent n'a plus que la seconde et dernière. L'explication « Comment ça marche ? » le dit clairement. Valeurs toujours lues depuis la politique effective (jamais codées en dur).
5. **Salle d'observation** : visio moderne, épurée, **très peu de boutons ou d'options à l'écran**. En haut, un **bandeau pleine largeur** qui affiche au tuteur le **décompte du temps restant seconde par seconde** et le **nombre de visites restantes** (« 1/2 visite restante pour cette séance » ; accord au pluriel ; « Aucune visite restante pour cette séance » à 0). Commandes réduites au strict nécessaire (son reçu, agrandir le support, quitter).
6. **Notices côté enseignant et élève** : **hors périmètre** de ce chantier ; elles seront conçues avec les rôles enseignant et élève. Ne pas étendre ce qui existe (reprise de la branche observation conservée telle quelle).

## 1 ter. RÉPONSES DU DIRECTEUR (24/09, soir, dans le document « Rewayah — Audit de méthode ») : elles PRIMENT

1. **Les high-fi font AUTORITÉ pour le layout et le placement des fonctions ; pas pour la palette.** Pour la composition, suivre les maquettes de près : ordre des sections, colonnes, proportions, regroupements, emplacement exact de chaque fonction, de chaque bouton et de chaque action, et la route qu'ils ouvrent. Un écart de placement est un défaut, au même titre qu'un bug. Pour les couleurs seulement, la direction reste celle des jetons (Bible) : des maquettes on ne prend qu'une **idée générale** de la palette, jamais une recopie à 100 %.
   - **Une fonction = un seul endroit.** Chaque action a une place unique, celle de la maquette, ou à défaut celle de l'arbre du mandat §4. **Aucun doublon** : pas la même action dans deux écrans, pas deux écrans pour la même fonction, pas deux routes concurrentes. Seule exception : les raccourcis que le mandat prévoit explicitement (ex. « Créer mon profil élève » depuis Foyer ET Compte), qui ouvrent **le même** flux, jamais une copie.
   - Contrôle obligatoire par lot et en revue Q : une **carte des fonctions** (fonction → écran unique → route → emplacement dans la maquette) ; toute fonction placée ailleurs que prévu ou présente deux fois est corrigée avant intégration.
2. **Design system GELÉ** : la palette ajustée et les polices DM Sans (titres) + Plus Jakarta Sans (le reste) de cette vague deviennent **immuables jusqu'à nouvel ordre du directeur**. Tout changement de jeton exige une décision datée. Un test doit figer les valeurs des jetons.
3. **Carte groupée = UN SEUL rectangle** qui regroupe les éléments d'un même sujet, séparés par une **fine ligne horizontale** (filet en retrait) qui traverse la carte. **Interdit** : un rectangle par ligne, ou des rectangles collés entre eux pour imiter une carte. Un seul composant partagé porte ce motif ; tout écran l'utilise.
4. **Navigation et sortie toujours possibles** : barre de navigation présente, retour visible sur chaque écran de niveau 2 et chaque tâche focalisée, **déconnexion** accessible sur tous les formats. Aucune impasse (le directeur a dû désinstaller la PWA faute de pouvoir revenir en arrière). Testé automatiquement.
5. **Web = vraie version desktop**, jamais la version mobile étirée : rail à partir de 600, barre latérale à partir de 1200, compositions en colonnes dérivées des high-fi desktop. Capture 1440 obligatoire pour chaque écran.
6. **Voir le rendu sans compte ni KYC** : un **mode démonstration par rôle** (sessions fictives, aucune donnée réelle, aucun appel serveur, sélecteur de rôle), activé seulement hors production ; le tuteur d'abord, les autres rôles ensuite. Les captures maquette/rendu de chaque lot sont publiées au fil de l'eau dans `05_recette/` et dans une page artefact.
7. **Frontend d'abord, backend ensuite** (le directeur préfère finir le frontend Tuteur, puis câbler). Chaque écran déclare son contrat serveur (ports K6, identifiants DB-xxx) pour que le câblage se fasse sans refonte. Le lot Backend T1 est reporté après le frontend Tuteur.
8. **Composants réutilisables** : ce qui est construit ici doit servir tels quels aux rôles suivants (admin, enseignant, élève adulte, élève enfant avec mode accessibilité, contrôleur, finance, comptable, contrôleur invité, salle, bibliothèque, Coran). Aucun composant spécifique au tuteur quand un composant partagé peut faire le travail.
9. **À venir côté tuteur (ne pas construire, laisser la place)** : recharge de solde, **chaque enfant consomme son propre solde**, parcours d'ajout d'un nouvel enfant revu. Les visuels viendront plus tard. Compte > Paiements et Foyer > fiche élève doivent pouvoir accueillir un solde par enfant sans refonte.
10. **Coran** : le rendu actuel « se lit en marche arrière et du bas vers le haut ». Hors périmètre de ce chantier, proposé comme étape parallèle (fichiers disjoints : `lib/features/tc_mushaf`, `lib/core/tc_coran`, `lib/core/coran`).

## 1 ter bis. LEÇONS DU REGISTRE DU CODE NON LIVRÉ (`06_registre/00_REGISTRE.md`), obligatoires pour tous les lots

1. **Définition de « fait » (registre §5 bis).** Une fonction n'est « faite » que si : (a) son fichier est atteignable depuis `lib/main.dart` (`D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1 -Ref <commit>`) ; (b) un bouton, un onglet ou un lien y mène, trouvé hors routeur et hors tests ; (c) après publication de l'aperçu, un de ses textes figure dans le `main.dart.js` servi. **Un test qui appelle `routeur.go(...)` ne prouve pas l'accès** : chaque parcours du lot est aussi testé en touchant les boutons (tap), depuis la navigation.
2. **Tri PostgREST.** `postgrest` trie en DÉCROISSANT quand on n'écrit rien (cause du Coran lu à l'envers). Tout `.order(...)` écrit ou touché par un lot précise `ascending: true` ou `false`, avec un test qui vérifie l'ordre. Les lots relisent les `.order(` des services qu'ils consomment (séances, appareils, présence, historique) et signalent tout tri sans sens.
3. Les 21 fichiers de contrats de la phase 0 non encore atteignables doivent l'être à la fin de la phase 1 (sinon : justification écrite ou suppression sur accord).

4. **Coran : NE PAS CORRIGER dans ce chantier** (ordre du directeur, 24/09 soir). Aucun lot ne modifie `lib/core/coran`, `lib/core/tc_coran`, `lib/features/tc_mushaf`, même pour un défaut évident. Les défauts sont consignés dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md`. La vague suivante (« Classe et visio ») a pour priorité n° 1 la rencontre élève-enseignant en visio. Tout défaut hors périmètre découvert par un agent est consigné dans ce backlog, jamais corrigé en passant.

## 1 quater. AUTORISATION DU DIRECTEUR (24/09, soir)

Le directeur **autorise**, à la fin de la phase 0 puis à la fin de chaque lot : `git push` de la branche `ui/tuteur-v1` vers `origin`, et l'ouverture (puis la mise à jour) d'une **pull request brouillon** `ui/tuteur-v1 -> main` pour obtenir l'URL d'aperçu Vercel. **Toujours interdit sans nouvel accord explicite** : fusion dans `main`, déploiement en production, `workflow_dispatch`, migration distante, push de toute autre branche. Avant chaque push : vérification complète verte ou échecs listés, frontière backend vide, aucun secret dans le diff.

Fait vérifié (`flutter-deploy.yml:89-90, 128-133`) : l'aperçu de PR utilise **les mêmes secrets Supabase que la production** (même base, vraies données, vraie connexion) avec `ENVIRONNEMENT=staging`, et force `PLAYGROUND=false` et `GALERIE=false` sur tous les builds. Conséquence pour le mode démonstration : il s'active sur `ENVIRONNEMENT != production` (aperçu, local), jamais via `PLAYGROUND`, et reste impossible en production. Rythme proposé au directeur : aperçu par lot, puis fusion dans `main` le jour même après sa validation (fusion = nouvel accord explicite à chaque fois).

## 2. Points directeur : défauts retenus (remplacés par le §1 bis là où ils divergent)

| # | Question | Défaut retenu (réversible) | Justification |
|---|---|---|---|
| P1 | Catalogue : vraies classes ou offres sans enseignant ? | **Vraies classes** (enseignant avec photo, toutes les séances, fuseau, places réelles) comme l'exige le mandat du 24/09. `PortCatalogueClasses` sans source en production : écran honnête « le choix de classe en ligne n'est pas encore ouvert », aucune réservation locale. **[DIRECTEUR]** | Le mandat est la demande explicite la plus récente (§2, rang 1) ; l'arbitrage Classes V2 du 22/09 vit sur des branches gelées. |
| P2 | Consentement d'observation et textes signés | Nouvelle **version** de texte signé côté front (`VersionsContrat`) qui ajoute le paragraphe d'observation exact du mandat (variantes responsable légal / élève adulte) ; case **non précochée** ; enregistrement par le mécanisme existant (`contract_acceptances`, insertion self) avec la nouvelle version. Comptes existants : invite `/tuteur/compte/consentements` qui lit les acceptations et propose la nouvelle version ; **aucun compte considéré comme ayant accepté**. Le serveur n'exige pas la version (`etat_dossier`) : dépendance backend consignée. **Remplacé par §1 bis-2 et 3 : l'enregistrement audio est réel, la notice est conservée telle quelle dans la nouvelle version** ; l'ancienne version reste intacte (jamais réécrite). **[DIRECTEUR : valider le texte avant fusion]** | Mandat observation §6 ; ne jamais réécrire un texte déjà signé (X10, X40). |
| P3 | Observation réelle | Interrupteur de compilation `OBSERVATION_TUTEUR_REELLE` (défaut **false**, forcé false en production tant que présence enfant, fin de visite et jeton vidéo ne sont pas garantis par le serveur). En production : bloc Observation avec motif « pas encore ouverte » (`garantieServeurAbsente`). Parcours complet démontré en simulation (tests, playground). **[DIRECTEUR]** | Mandat observation §3 : « n'active pas une fonctionnalité réelle avec une protection uniquement locale » ; DB-OBS-01/02/03/05. |
| P4 | Quota par parent ou par foyer, plusieurs enfants, visite écourtée | **Tranché par le directeur (§1 bis-4)** : par parent, 2 visites par séance quel que soit le nombre de ses enfants dans la salle ; visite écourtée consommée. L'UI affiche les valeurs rendues par le serveur ; tout écart entre ce comportement et le serveur est une dépendance backend. | Réponse du directeur du 24/09. |
| P5 | Décrire les élèves avant validation du dossier | Suivre le serveur : l'ajout d'élève reste après validation (porte `actif`). L'admission l'annonce honnêtement et enchaîne sur le formulaire commun dès l'arrivée en porte `actif`. Dépendance DB-ADM-04. **[DIRECTEUR]** | Pas de contournement serveur. |
| P6 | « Photo requise avant la première visio » | Aucune règle sur la base : **aucun** blocage photo affiché. | Mandat §5 : seulement si confirmé par les données. |
| P7 | Décisions Classes V2 (cohortes 6-9/10-13/14-17/18+, date de naissance, débutant direct, demande d'interface standard à 10 ans) | Pas de constante côté front : l'UI consomme les cohortes, règles et branches rendues par le serveur (`regles_academie`, 0043) ; quand le serveur ne les fournit pas, état indisponible. Libellés métier alignés sur Classes V2 quand ils ne créent aucune règle. **[DIRECTEUR : intégrer ces décisions à `docs/current`]** | Décisions datées mais hors `docs/current`, backend non appliqué. |
| P8 | Reprise du front de `33503fe` (vraies classes) et de `observation/lot-2026-09-21` | **Oui**, en deux commits séparés, nommés et réversibles, **partie `lib/ test/ assets/` uniquement**, sans aucune migration, sans fichiers générés (régénérés), et **sans** les clés signées `contrat.pointEnregistrement` et `enseignant.profil.contratAccuse` de `33503fe`. **[DIRECTEUR]** | Le mandat interdit les fixtures servies en production (`port_groupes.dart:37-39`, `port_horloge_seance.dart:54-55`) et impose la politique 2 x 120 s déjà en production (0036). |
| P9 | Palette sombre ardoise pour tous les rôles | **Oui**, un seul système de jetons ; contrôle de non-régression (contrastes, captures des autres rôles). | Toutes les maquettes sombres s'accordent ; un seul thème. |
| P10 | Planche 3 « États particuliers et notices de présence » | Demandée au directeur ; états dérivés en attendant (manifeste §6.3). | Mandat §2. |

## 3. Arbitrages visuels (manifeste §6.4)

1. Palette : ajustements du manifeste §3.1 appliqués (clair : `inkStrong #110E20`, `inkFaint #6A687E`, `inkAccent #6538E4`, `washWarning #FEF5E4`, `inkAlert #C21D3D` ; sombre : ardoise `#1A1A25` / `#22222E` / `#2B2B39` / `#262534` / `#32323F`, `inkMuted #AEB1CE`, `inkFaint #9194B0`, `surfacePrimary #BA98FB` encre `#25113F`, `inkAlert #F4777D`). Ajouts : paires `surfaceMiseEnAvant` (`#F7F5FE` / `#2B2B39`), `surfaceActionDouce` (clair `#DCCAFD` + `inkStrong` ; sombre = `surfacePrimary`), groupe de points de statut (succès, attention, alerte, neutre). Chaque valeur est vérifiée en contraste (texte 4,5:1, composants 3:1) par test.
2. Boutons et champs : rayon `AppRadius.sm` (12). Exception : CTA des étapes d'admission en pilule (`AppRadius.full`), comme les high-fi d'admission.
3. CTA dominant : `surfaceActionDouce` (lavande doux en clair, lavande plein en sombre), libellé + flèche ; un seul par écran.
4. Typographie : DM Sans pour `display*` de titre, `headline*`, `title*` ; Plus Jakarta Sans pour tout le reste ; style `chiffre` Jakarta tabulaire pour horaires, codes, PIN, chronomètre, initiales (DM Sans n'a pas de chiffres tabulaires). Graisse des titres de page 700. Polices arabes inchangées. `BricolageGrotesque` et `InstrumentSans` retirées des assets (4 familles, pas une de plus).
5. Bascule clair/sombre de l'en-tête (tablette et desktop) : pilote la même préférence qu'Apparence (Système / Clair / Sombre) ; la préférence est enfin appliquée au `MaterialApp`.
6. Navigation tuteur : **Accueil · Foyer · Historique · Compte**, identique sur tous les formats (barre basse flottante < 600, rail replié 600-1199, barre latérale dépliée ≥ 1200, Compte épinglé en bas). Historique confirmé comme 3e destination (manifeste §4.3).
7. Libellés : « Cours en cours » interdit partout dans le périmètre tuteur ; séance prolongée = « Séance toujours en direct » ; « Session » -> « Séance » / « Cours » ; « Ajouter enfant » -> « Ajouter un profil élève ».
8. Choix d'usage : deux cartes (« Moi uniquement », « Moi et ma famille ») **sans carte « Autre »** (`ChoiceCardGroup.autoriserSaisieLibre: false`), lien discret « Je suis enseignant ». Écart assumé à la règle ADR-013 : décision explicite du directeur.
9. Détail d'observation : `/tuteur/seances/:seanceId/observations?eleve=`.

## 4. Alertes sécurité à remonter (hors périmètre, aucune correction dans ce chantier)

- Policy `student_profiles_family_update` sans contrôle de rôle : un élève pourrait modifier caméra, mode, photo (`0005:535-564`, `0033:1723-1730`). Lecture, non exécuté.
- `lesson_reports` d'une séance de groupe lisible en entier par un foyer (`0001:1070-1078`).
- `flutter-deploy.yml` (sur `main`) : `workflow_dispatch` déploie en production quelle que soit la branche.
- Hooks `.claude` actifs seulement sur l'outil Bash, pas PowerShell.
- `0042` (appliquée) refuserait tout jeton vidéo (affirmation d'archive, non remesurée).


---


# B1. Vagues du projet

# Vagues du projet Rewayah Academy

Ordre décidé par le directeur (24/09/2026). Une vague = une branche de base, un dossier de pilotage, des lots, des lignes dans le tableau de suivi. La vague suivante ne commence qu'après accord du directeur.

| Vague | État | Branche de base | Dossier de pilotage | Objectif |
|---|---|---|---|---|
| Tuteur V1 (frontend) | en cours | `ui/tuteur-v1` | branche `pilotage/tuteur-v1` | Tous les écrans et parcours du rôle Tuteur, fidèles aux maquettes, honnêtes sur ce que le serveur ne fait pas encore |
| Classe et visio | prévue | à créer | à créer | **Priorité n° 1 : un élève et un enseignant se rencontrent et se voient** (salle unique, visio, jeton serveur, entrée depuis la classe, présence) ; validation des dossiers enseignants par l'admin ; puis lecteur du Coran fidèle |
| Backend T1 | prévue, après le frontend Tuteur | à créer | à créer | Garanties serveur du tuteur, sécurité, CI verte (prompt prêt dans le document « Rewayah — Audit de méthode ») |
| Rôles suivants | à planifier | - | - | Enseignant, élève adulte, élève enfant (Interface guidée, accessibilité), administration, contrôleur, contrôleur invité, finance et comptable, bibliothèque et ressources, solde par enfant et recharge, landing page web, publication iOS, Play Store, Windows |

Backlog consigné pour la vague Classe et visio : `pilotage/tuteur-v1` : `08_BACKLOG_VAGUE_CLASSE_VISIO.md`.


---


# B2. Backlog de la vague Classe et visio

# Backlog : vague « Classe et visio » (après le chantier frontend Tuteur V1)

Consigné le 24/09/2026 sur ordre du directeur : **ne rien corriger maintenant**, ne pas sortir du chantier Tuteur en cours.

## Priorité n° 1 de la vague suivante

**Permettre à un élève et à un enseignant de se rencontrer et de se voir** : une seule salle, visio LiveKit fonctionnelle, jeton vidéo délivré par le serveur, entrée depuis la classe pour l'élève et pour l'enseignant, présence. Tout le reste (outils pédagogiques, Coran fidèle) vient après que ce parcours marche réellement.

Prérequis connus (registre `06_registre/00_REGISTRE.md`, dépendances `02_code/00_DEPENDANCES_BACKEND.md`) :
- Migration `0042` appliquée en production qui refuserait tout jeton vidéo (affirmation du correctif non committé `D:\RA_OBS\...\0043_autoriser_jeton_video_verifie_le_bon_compte.sql`, sauvegardé ; à vérifier en base, puis renuméroter au prochain numéro libre).
- Deux salles concurrentes (`/salle` et `/tc/classe`) : arbitrage du directeur pour une salle unique.
- Synchronisation en direct (`lib/core/tc_realtime`), reprise après coupure (`lib/core/tc_etat_partage`) : présents sur `main`, jamais branchés.
- La page du Coran présentée par l'enseignant n'est reçue par aucun écran élève.

## Coran : défauts connus (rendu en production), à traiter dans cette vague, après la visio

Constatés par le directeur le 24/09 :
1. **Ordre inversé** : les versets s'affichent du dernier au premier, lecture du bas vers le haut. Cause prouvée : `lib/core/coran/service_coran.dart:309, 329, 330, 459, 460`, `.order(...)` sans `ascending: true` (postgrest 2.9.1 trie en décroissant par défaut). Même cause : la recherche renvoie les 50 **dernières** occurrences.
2. **Voyelles (harakat) absentes** : la fatha et les autres signes ne s'affichent pas sur presque tous les mots.
3. **Espacement** : mots trop éloignés les uns des autres, interligne trop large.
4. **Mise en forme non officielle** : ne respecte pas le Mushaf du complexe du roi Fahd (Madinah) : pas de pages standard (604 pages, 15 lignes), pas de marquages hizb, juz', rub', sajda, début de sourate, numéros de verset dans leur ornement.
5. **Résumé du directeur** : la version en production n'affiche que des mots bruts éparpillés.
6. **Commandes absentes** pour gérer le Coran (navigation page, sourate, juz', verset agrandi, suivi de la classe, zoom).

Pistes à instruire (sans décision) : police et données de mise en page officielles (KFGQPC / QPC, données de lignes par page), vérification du corpus chargé (6 236 versets, `0013`) et de sa normalisation Unicode (les harakat peuvent être perdus à l'import ou par la police), `layout_lignes_indisponible.dart:51-52` (mise en page fidèle désactivée), gestes de page et boutons en sens contraires (registre §4). Règle permanente : le texte canonique n'est jamais modifié ; sans mise en page de référence, afficher honnêtement le mode verset, jamais une fausse page « Mushaf ».

## Réponses du directeur sur le registre (24/09, soir)

- **Vocabulaire** : à l'écran on dit « Classe », jamais « groupe » (règle déjà imposée aux lots du chantier Tuteur).
- **Deux salles** (`/salle` et `/tc/classe`) : garder la plus complète, y combiner le meilleur de l'autre, puis supprimer le doublon (vague Classe et visio).
- **Lecteur du Coran en double** (`/tc/mushaf` et `/eleve/coran`) : même règle : compléter, combiner, supprimer le doublon.
- **Anciens lots Codex (13-15/09)** : abandon autorisé, mais examiner d'abord ce qui est récupérable comme inspiration (Codex jugé meilleur dans certains domaines).
- **Décision « badges à cinq niveaux »** : OUI, à intégrer aux specs (`docs/current`).

## Points du directeur restés sans réponse dans l'audit (à traiter)

- **Rôle enseignant inaccessible** : bloqué par le KYC, car l'administration n'a pas d'écran pour revoir et accepter les dossiers. À traiter en tête de la vague Classe et visio (sans enseignant validé, pas de rencontre élève-enseignant).
- **Accès de test sans parcours complet** : voir chaque rôle sans créer plusieurs comptes. Réponse retenue : mode démonstration par rôle sur l'aperçu (jamais en production) pour VOIR ; pour tester en vrai, comptes de test par rôle créés et validés par l'admin une fois l'écran de validation livré.
- **Système de jetons d'accès pour agents (comme PISI)** : jamais fonctionnel ; remplacé par l'aperçu de PR, le mode démonstration et les captures ; à ne pas relancer sans décision.

## Autres points consignés pour les vagues suivantes

- Outils de classe de l'enseignant, après-cours, signalement, micro-avis élève, bibliothèque en classe : présents sur `main`, jamais branchés (registre, groupe A).
- Écran de bienvenue enseignant sans bouton ; liste des élèves de l'enseignant refusée par la porte d'accès ; Coran hors salle absent pour l'enseignant (registre, groupes B et C).
- 11 autres appels `.order(...)` sans sens écrit (appareils, séances, créneaux, offres) : à vérifier dans chaque lot qui les consomme.
- [lot C, 24/09] `mes_groupes_famille_v` (`0033:140-170`) : jointure `m` (tous les eleves du foyer) croisee avec `m2`, `count(m2.id)` probablement multiplie quand deux enfants d'un meme foyer sont dans la meme classe (effectif gonfle). Lecture seule, non mesure. Backend.
- [lot C, 24/09] `groupeDepuisLigne` (`groupes_supabase.dart:48-50`) replie un titre absent sur Sayyid : le mandat interdit de deviner le titre ; `EnseignantVM.titre` non nullable (fichiers du coordinateur, demande C-3).


---


# C. Système de design gelé

# Système de design GELÉ de Rewayah Academy : état réel du code

Date du relevé : 24/09/2026. Dépôt lu : `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (lecture seule, aucun fichier modifié).
Destinataire : ChatGPT, qui n'a pas accès au code. Tout ce qui suit est relevé dans le code ou dans un document cité par `fichier:ligne`. Ce qui n'a pas pu être prouvé porte la mention **À VÉRIFIER**. Les écarts entre le code et les documents portent la mention **ÉCART**.

## 0. Règles de lecture

| Règle | Source |
|---|---|
| Le système de design est **gelé** : palette ajustée, DM Sans (titres) et Plus Jakarta Sans (le reste) sont immuables jusqu'à nouvel ordre du directeur. Tout changement de jeton exige une décision datée. | `pilotage-tuteur-v1/03_DECISIONS_COORDINATEUR.md:33` (§1 ter-2) |
| Les maquettes font autorité pour la **disposition** (ordre, colonnes, emplacement de chaque action), jamais pour la palette : on n'en prend qu'une idée générale. | `03_DECISIONS_COORDINATEUR.md:30` (§1 ter-1) |
| Quand un commentaire du code contredit la valeur du code, **la valeur du code fait foi** (c'est elle qui s'affiche). | constat de ce relevé |
| `docs/archive/` n'est pas une instruction ; une règle archivée qui contredit `docs/current/` est caduque. | `integration/CLAUDE.md:23-25` |
| La demande explicite la plus récente du directeur prévaut sur `docs/current`. | `docs/current/00_LIRE_D_ABORD.md:12` |
| Gel vérifié par test : **partiel**. Les tests figent 17 valeurs claires et 13 valeurs sombres (fonds, encres ajustées, CTA doux, Coran), pas toutes les paires. | `test/theme/contraste_test.dart:19-44`, `test/theme/contraste_sombre_test.dart:26-45` |
| ÉCART : `docs/current/03_DESIGN_SYSTEM_ET_UX.md:5` dit « les documents fournis ne fixent pas de valeurs HEX officielles » et « violet fortement atténué, jamais primaire par défaut ». La décision de gel du 24/09 (§1 ter-2) est plus récente et prime ; le violet plein n'est plus le CTA en clair, ce qui va dans le sens de `03`. | `docs/current/03:5` ; `03_DECISIONS:33` |

## 1. Palette (`lib/core/theme/app_palette.dart`)

Principe : le thème n'expose jamais une couleur seule. Il expose des **paires** (fond, encre) `AppColorPair`, des **encres** de premier plan `AppInkColor` (texte, trait, icône, jamais un fond), des **indicateurs** `AppIndicatorColor` (point plein seulement) et une **ombre** `AppShadowColor`. Source : `app_color_pair.dart:3-11`, `:56-64`, `:103-111`, `:159-166`. Aucune couleur hors de ce fichier n'est acceptée par `tool/verifier_jetons.dart` (`lib/CLAUDE.md:17-19`).

### 1.1 Surfaces (paires fond / encre)

Clair : `app_palette.dart:61-152`. Sombre : `:154-247`.

| Jeton | Clair fond / encre | Sombre fond / encre | Rôle (source) |
|---|---|---|---|
| `surfaceCanvas` | `#F8F7FA` / `#110E20` | `#1A1A25` / `#F5F2FA` | Fond de page (manifeste §3.1). En sombre : « ardoise bleu-violet », jamais noir pur ni gris neutre (`app_palette.dart:16-20`, manifeste §6.2) |
| `surfaceRaised` | `#FFFFFF` / `#110E20` | `#22222E` / `#F5F2FA` | Carte, carte groupée, barre basse, rail et barre latérale, zone d'action collée, feuille mobile, bouton secondaire (`nav_shell.dart:400`, `:633` ; `page_shell.dart:267` ; `action_principale.dart:258-260`) |
| `surfaceSunken` | `#F0EDF4` / `#110E20` | `#262534` / `#F5F2FA` | Zone imbriquée (bloc séance mobile, seule imbrication admise), fond de champ, piste de contrôle segmenté, squelette, en-tête de tableau, ton « neutre » des pastilles (`app_theme.dart:163` ; `controle_segmente.dart` ; `skeleton.dart` ; `status_pill.dart:42` ; manifeste §3.4) |
| `surfaceOverlay` | `#FFFFFF` / `#110E20` | `#2B2B39` / `#F5F2FA` | Boîte de dialogue, disque retour, bouton de repli du rail (`app_theme.dart:146` ; `entete_page.dart:115` ; `nav_shell.dart:707`). Menus : À VÉRIFIER (le commentaire `app_elevation.dart:59-60` le dit, le thème ne le fixe pas) |
| `surfaceMiseEnAvant` | `#F7F5FE` / `#110E20` | `#2B2B39` / `#F5F2FA` | Carte de séance mise en avant (Accueil desktop), un cran au-dessus de la carte ordinaire (`app_palette.dart:254-256`) |
| `surfaceActionDouce` | `#DCCAFD` / `#110E20` | `#BA98FB` / `#25113F` | **CTA dominant, un seul par écran** : lavande doux en clair, accent plein en sombre (même valeur que `surfacePrimary`). Aucune maquette claire ne montre de CTA violet plein (`app_palette.dart:258-261` ; test `contraste_sombre_test.dart:47-49`) |
| `surfacePrimary` | `#8652E6` / `#FFFFFF` | `#BA98FB` / `#25113F` | Accent plein : anneau de sélection d'avatar (2 px), point de non-lus, remplissage de progression, destination active du rail en sombre, point de la pastille « accent », CTA en Interface guidée (`selecteur_profils.dart` ; `entete_page.dart:188` ; `page_parcours.dart` ; `nav_shell.dart:801` ; `action_principale.dart:241-243`) |
| `surfaceSuccess` | `#70EE9C` / `#1C1D21` | `#70EE9C` / `#1C1D21` | Surface pleine de succès. Ne sert plus de point de statut (1,28:1 sur `washSuccess`) (`status_pill.dart:113-119`) |
| `surfaceWarning` | `#FFB703` / `#1C1D21` | `#FFB703` / `#1C1D21` | Surface pleine d'avertissement, réservée |
| `surfaceAlert` | `#B01B3C` / `#FFFFFF` | `#FFB1BD` / `#570D22` | Contour d'un champ en erreur (`colorScheme.error`, `app_theme.dart:206`). **Jamais un bouton rouge plein** (`action_principale.dart:28-30`, `:44-47`) |
| `surfaceInverse` | `#211E28` / `#F5F2FA` | `#F5F2FA` / `#211E28` | Fond du registre immersif « salle » (`page_immersive.dart:14-16`) |
| `surfaceQuran` | `#F3EAD9` / `#1C1D21` | `#2E2417` / `#F5F1E9` | Lecteur du Coran, registre immersif « lecture ». **Paire figée, jamais modifiée** (`app_palette.dart:5-7` ; tests `contraste_test.dart:41-43`) |

### 1.2 Fonds doux (« lavages ») et famille

| Jeton | Clair fond / encre | Sombre fond / encre | Rôle |
|---|---|---|---|
| `washAccent` | `#EEE6FA` / `#4E2983` | `#332643` / `#E8D8FF` | Destination active du rail en clair, segment actif, carte ou option retenue, cercle héros, encart d'écran résultat, monogramme, médaillon, survol d'un bouton secondaire ou tertiaire (`nav_shell.dart:802` ; `controle_segmente.dart:120` ; `app_card.dart:83-85` ; `ecran_resultat.dart:146`) |
| `washSuccess` | `#E4F4EB` / `#175D3A` | `#173B2B` / `#9DDEB5` | Pastille et signal de succès (« Présente », « Accès actif ») |
| `washWarning` | `#FEF5E4` / `#755200` | `#44361A` / `#F4D480` | Bandeau hors ligne, bandeau d'observation IA, bandeau de blocage ambre, carte « sans planning » (`offline_banner.dart:25-31` ; `bandeau_observation.dart:29-31`) |
| `washAlert` | `#FCE8ED` / `#921734` | `#4A2030` / `#FFD9E0` | Pastille « Interrompue », survol d'une action destructive, « Quitter » en pilule rouge douce (manifeste §3.4) |
| `washFamily` | `#F0EDF4` / `#110E20` | `#262534` / `#F5F2FA` | Domaine foyer : repli à initiales de l'avatar sans photo (`avatar_tile.dart:23-28`) |

Correspondance ton sémantique vers fond doux (`status_pill.dart:13-47`) : `neutre` = `surfaceSunken` (en attente, brouillon, non commencé) ; `accent` = `washAccent` (en cours, actif, retenu) ; `succes` = `washSuccess` (terminé, validé, en direct) ; `avertissement` = `washWarning` (à surveiller, en retard, incomplet) ; `alerte` = `washAlert` (refusé, échoué, annulé).

### 1.3 Encres et filets (premier plan uniquement)

| Jeton | Clair | Sombre | Emploi |
|---|---|---|---|
| `inkStrong` | `#110E20` | `#F5F2FA` | Texte principal, titres |
| `inkMuted` | `#655E70` | `#AEB1CE` | Texte secondaire, sous-titre, icône inactive, clé d'une ligne clé-valeur |
| `inkFaint` | `#6A687E` | `#9194B0` | Texte tertiaire, texte d'invite des champs (`app_theme.dart:165-171`) |
| `inkAccent` | `#6538E4` | `#C9AEFF` | Lien, icône porteuse de sens, libellé actif, anneau de focus, icône de rubrique. Le violet plein `#8652E6` ne s'écrit jamais en texte (4,15:1 sur `surfaceSunken`) |
| `inkSuccess` | `#175D3A` | `#9DDEB5` | Texte de succès, icône d'état vide « bonne nouvelle » |
| `inkWarning` | `#755200` | `#F4D480` | Texte d'avertissement |
| `inkAlert` | `#C21D3D` | `#F4777D` | Erreur sous un champ, action destructive (texte seul), « Se déconnecter » |
| `borderHairline` | `#E3DEE9` | `#32323F` | Filet des champs inertes, séparateur `Divider`, filet haut de la zone d'action collée, filet des feuilles (`app_theme.dart:85-89`, `:181` ; `page_shell.dart:268`) |
| `borderResting` | `#84798F` | `#95899F` | Contour de contrôle au repos, carte de choix non retenue, poignée de feuille (`choice_card_group.dart:210-212`) |
| `borderStrong` | `#84798F` | `#95899F` | **Seule bordure porteuse de sens** : sélection, focus fort, contour de champ actif, survol, bouton secondaire (2 px), bouton principal désactivé (3 px) (`app_card.dart:59-61` ; `action_principale.dart:220-225`, `:264`) |

Valeurs dérivées (`app_palette.dart:317-328`) :

| Dérivé | Valeur | Emploi |
|---|---|---|
| `contourCarte` | encre à 8 % : `#211E28` à 8 % en clair (≈ `#EDEDEE` sur blanc), blanc à 8 % en sombre (≈ `#34343F` sur `#22222E`) | Filet de 1 px de toute carte, carte groupée, filet en retrait entre lignes, barre basse, bord de la colonne latérale, disque retour. Les séparateurs du tuteur consomment `contourCarte`, pas `borderHairline` (manifeste §3.1, ligne « Contour de carte ») |
| `voile` | noir à 32 % (clair), 56 % (sombre) | Voile sous une feuille ou une boîte de dialogue |
| `calqueInteraction` | `inkAccent` à 4 % (survol, focus), 10 % (pressé) | Survol et pression des lignes et cartes |
| `ombre` | `#211E28` dans les deux thèmes | Couleur de toutes les ombres |

### 1.4 Points de statut (`app_palette.dart:144-149`, `:239-244`)

Toujours doublés d'un libellé textuel et d'une étiquette sémantique ; ils visent 3:1 contre leur surface (`app_palette.dart:466-471`).

| Point | Clair | Sombre | Sens (`app_palette.dart:482-491`) |
|---|---|---|---|
| `succes` | `#199C55` | `#70EE9C` | Succès, en direct, présent, salle ouverte |
| `attention` | `#B38000` | `#FFB703` | Attention, à venir |
| `alerte` | `#E0375A` | `#F9505E` | Alerte, interrompu |
| `neutre` | `#8685A5` | `#7F7D9E` | Neutre, inactif |

### 1.5 Teintes d'identité (32 paires, décoratives)

Rôle : teinte d'un groupe (classe) ou d'une couverture de ressource calculée, par index stable. **Jamais le seul identifiant** : toujours posée à côté d'un nom (invariant J7). Aucune ne reprend une teinte porteuse de sens (accent, succès, avertissement, alerte, Coran). Source : `app_palette.dart:290-315`, clair `:519-552`, sombre `:556-589`.

| # | Clair fond / encre | Sombre fond / encre | # | Clair fond / encre | Sombre fond / encre |
|---|---|---|---|---|---|
| 0 | `#EB7070` / `#5B1313` | `#2D1515` / `#CC6666` | 16 | `#F4C1AF` / `#903C1D` | `#573529` / `#D79B86` |
| 1 | `#7070EB` / `#0C0C3B` | `#15152D` / `#7878D2` | 17 | `#F8D9CE` / `#A44422` | `#6C4233` / `#E1B4A4` |
| 2 | `#E7CEF8` / `#8729C7` | `#55336C` / `#C6A0DF` | 18 | `#F4AFDF` / `#911E6E` | `#572949` / `#D88AC1` |
| 3 | `#A9EB70` / `#3C6915` | `#202D15` / `#67A035` | 19 | `#EB70A9` / `#5D1336` | `#2D1520` / `#CB6293` |
| 4 | `#D98FEF` / `#65197C` | `#3A1F42` / `#BC76D1` | 20 | `#CEE9F8` / `#1F6B97` | `#33576C` / `#A8CDE2` |
| 5 | `#70EBC2` / `#15684C` | `#152D25` / `#36A27E` | 21 | `#EF9F8F` / `#7B2A19` | `#42251F` / `#CF8070` |
| 6 | `#DDF4AF` / `#547217` | `#475729` / `#B2D174` | 22 | `#8F8FEF` / `#1D1D8C` | `#1F1F42` / `#8282D5` |
| 7 | `#EF8FC2` / `#78194C` | `#421F32` / `#D174A6` | 23 | `#EF8FDF` / `#771867` | `#421F3C` / `#D072C0` |
| 8 | `#EFB38F` / `#7A3C19` | `#422C1F` / `#CC8A65` | 24 | `#AFF4B8` / `#187424` | `#29572F` / `#7AD386` |
| 9 | `#AFF4EA` / `#177367` | `#295751` / `#77D2C6` | 25 | `#8FA9EF` / `#1C3888` | `#1F2842` / `#778FD2` |
| 10 | `#EB70C6` / `#5E1348` | `#2D1526` / `#CA60AA` | 26 | `#CEF8EA` / `#197A5A` | `#336C59` / `#BBE8D9` |
| 11 | `#E1AFF4` / `#7B209C` | `#4A2957` / `#C48BD8` | 27 | `#F8CECE` / `#B32525` | `#6C3333` / `#E0A2A2` |
| 12 | `#D270EB` / `#4E135D` | `#28152D` / `#B764CB` | 28 | `#F4B6AF` / `#952A1E` | `#572D29` / `#D8918A` |
| 13 | `#EB9570` / `#672E15` | `#2D1C15` / `#C57350` | 29 | `#F8CEED` / `#A92385` | `#6C335C` / `#E0A3D0` |
| 14 | `#F8F8CE` / `#737318` | `#6C6C33` / `#EDEDC8` | 30 | `#AFBFF4` / `#2444AE` | `#293457` / `#8A9DD8` |
| 15 | `#93EF8F` / `#196D16` | `#20421F` / `#43BD3F` | 31 | `#CEF8CF` / `#197B1D` | `#336C34` / `#B8E7BA` |

### 1.6 Contrastes mesurés (WCAG 2.x, recalculés pour ce relevé ; concordent avec les tests)

| Encre | Clair : fond / carte / zone imbriquée / mise en avant / `washAccent` | Sombre : fond / carte / zone imbriquée / superposition / `washAccent` |
|---|---|---|
| `inkStrong` | 17,77 / 18,96 / 16,37 / 17,56 / 15,65 | 15,56 / 14,19 / 13,58 / 12,58 / 12,65 |
| `inkMuted` | 5,81 / 6,20 / 5,35 / 5,74 / 5,12 | 8,19 / 7,47 / 7,15 / 6,62 / 6,66 |
| `inkFaint` | 5,05 / 5,39 / 4,65 / 4,99 / **4,45** | 5,80 / 5,29 / 5,06 / 4,69 / 4,71 |
| `inkAccent` | 6,07 / 6,48 / 5,60 / 6,00 / 5,35 | 9,01 / 8,22 / 7,86 / 7,29 / 7,33 |
| `inkAlert` | 5,56 / 5,94 / 5,12 / 5,50 / 4,90 | 6,39 / 5,82 / 5,57 / 5,16 / 5,19 |
| `borderStrong` (composant, seuil 3) | 3,85 / 4,11 / 3,55 / 3,80 / 3,39 | 5,22 / 4,76 / 4,55 / 4,22 / 4,24 |

Paires internes : CTA doux clair `#DCCAFD`/`#110E20` = 12,56 ; CTA sombre `#BA98FB`/`#25113F` = 7,29 ; `surfacePrimary` clair = 4,81 ; `washAccent` clair 8,80 ; Coran 14,10 (clair) et 13,50 (sombre).

**Paires interdites** (sous 4,5:1, aucun usage connu, à ne jamais créer) : clair `inkFaint` sur `washAccent` (4,45) ; sombre `inkFaint` sur `washSuccess`, `inkFaint` sur `washWarning`, `inkAlert` sur `washWarning` (4,35). Source : `test/theme/contraste_test.dart:11-17`, `contraste_sombre_test.dart:11-24`.

À savoir pour le dessin : le CTA doux clair ne se détache de sa carte qu'à 1,51:1 (1,41 sur le fond). C'est accepté pour l'adulte ; en **Interface guidée** le CTA garde l'aplat `surfacePrimary` (≥ 3:1) tant que le directeur n'a pas tranché sur capture (`action_principale.dart:235-243`).

### 1.7 Règles d'emploi de la couleur

| Règle | Source |
|---|---|
| **Une seule zone pleine par écran : l'action principale.** Alertes, badges, bandeaux prennent le registre doux (`wash*` + `ink*`). La pastille de 8 px est le seul aplat saturé toléré en plus. | `lib/CLAUDE.md:62-63` ; `status_pill.dart:56-59` ; `archive/design/01-systeme-visuel.md:60-73` |
| CTA dominant : lavande doux en clair, lavande plein en sombre, libellé plus flèche « → », un seul par écran. | `03_DECISIONS:76` (§3.3) |
| Un état n'est jamais porté par la couleur seule : pastille, icône, mot, au moins deux des trois. | `archive/design/01-systeme-visuel.md:210-212` ; `ligne_presence.dart:11-16` |
| Clair vers sombre n'est **pas une inversion** : les surfaces restent claires sur foncé, l'accent change de rôle, les conteneurs sémantiques s'assombrissent. Carte plus claire que le fond en sombre (l'élévation se lit par la clarté). | manifeste §6.2 |
| Contenu non chrome (support pédagogique, QR, photos, surface Coran) **inchangé** en sombre ; le QR reste noir sur blanc. | manifeste §6.2, dernière ligne |
| Un même arbre de widgets dans les deux thèmes : seul le format change la composition, jamais le thème. | manifeste §5 F |
| Barre basse sombre en gris neutre (`#4B4B4B`, `#5D5D5D`) : rejetée ; elle prend `surfaceRaised` + `contourCarte`. | manifeste §5 D |

## 2. Typographie (`lib/core/theme/app_typography.dart`)

### 2.1 Les quatre familles, pas une de plus (`app_typography.dart:17-43` ; `pubspec.yaml:107-153`)

| Famille | Fichier | Emploi |
|---|---|---|
| `DMSans` | `DMSans-Variable.ttf` (axes `opsz` 9 à 40, `wght` 100 à 1000) | Titres français : `headline*`, `title*`. Pas de chiffres tabulaires (aucune fonction `tnum`). |
| `PlusJakartaSans` | `PlusJakartaSans-Variable.ttf` (`wght` 200 à 800) | Tout le reste : corps, libellés, boutons, champs, navigation, pastilles, légendes, **tous les chiffres** (horaires, codes, PIN, chronomètre, initiales, statistiques), et les styles `display*`. |
| `UthmanTahaNaskh` | `UthmanTahaNaskh-Regular.otf` (KFGQPC, Complexe du Roi Fahd) | **Arabe document** : Coran, hadiths, livres, lettres, textes pédagogiques. Style `AppTypography.document()`, taille 28 et interligne 2 par défaut (`:229-235`). |
| `NotoSansArabic` | `NotoSansArabic-Variable.ttf` | **Arabe d'interface** : RTL, menus, boutons, libellés, navigation. Aujourd'hui posée seulement en **police de repli** de tous les styles latins (`:31-33`) ; aucun style d'interface arabe dédié n'existe. |
| Icônes (hors texte) | `Phosphor-Regular.ttf`, `Phosphor-Fill.ttf` | Voir §7. |

Polices retirées : Instrument Sans, Bricolage Grotesque (`:13-16`), Varela Round, Noto Sans (`lib/CLAUDE.md:27-28`). Toute maquette qui les emploie est fausse.

### 2.2 Échelle standard (rôles adultes) (`app_typography.dart:237-253`)

Crénage calculé par la taille (`:130-146`) : -0,02 em dès 32 ; -0,015 em de 24 à 31 ; -0,01 em de 18 à 23 ; 0 de 15 à 17 ; +0,01 em sous 15. Libellé en capitales de 12 px ou moins : +0,06 em (`:158-164`).

| Style | Famille | Taille / interligne (px) | Graisse | Crénage (px) | Emploi relevé |
|---|---|---|---|---|---|
| `displayLarge`, `displayMedium`, `displaySmall` | Jakarta tabulaire | 36 / 44 | 700 | -0,72 | Valeurs fortes seulement : compte à rebours, `StatTile`, heure « 13:45 » desktop |
| `headlineLarge` | DM Sans | 36 / 44 | 700 | -0,72 | Titre de page sans en-tête riche, mot-marque « Rewayah Academy » (`page_shell.dart:123` ; `marque_page.dart:22-31`) |
| `headlineMedium` | DM Sans | 32 / 40 | 700 | -0,64 | Titre de page à partir de 600 px (`entete_page.dart:52-54`) |
| `headlineSmall` | DM Sans | 28 / 36 | 700 | -0,42 | Titre de page sous 600 px, titre de feuille ou dialogue, question d'admission |
| `titleLarge` | DM Sans | 22 / 28 | 600 | -0,22 | Titre d'écran résultat, message d'état vide, mot-symbole « Rewayah » du rail (en 700) |
| `titleMedium` | DM Sans | 18 / 26 | 600 | -0,18 | Titre de section, de carte, de groupe, prénom sur carte enfant |
| `titleSmall` | DM Sans | 16 / 24 | 600 | 0 | Titre d'état système en bloc, titre de bandeau ambre |
| `bodyLarge` | Jakarta | 16 / 24 | 400 | 0 | Corps desktop, libellé de rubrique, sous-titre de page, libellé du rail |
| `bodyMedium` | Jakarta | 14 / 20 | 400 | 0,14 | Corps mobile, légende et valeur de rubrique, encart |
| `bodySmall` | Jakarta | 12 / 16 | 400 | 0,12 | Méta, sous-libellé d'avatar, bandeaux |
| `labelLarge` | Jakarta | 16 / 20 | 600 | 0 | Libellé de bouton, de lien fléché, de segment, d'onglet |
| `labelMedium` | Jakarta | 12 / 16 | 500 | 0,12 | Pastille de statut, libellé de barre basse (600 si actif) |
| `labelSmall` | Jakarta | 12 / 16 | 500 | 0,12 | Petits libellés |
| `chiffre()` | Jakarta tabulaire | défaut 32 / 40 (taille + 8) | 600 | selon taille | Horaires, codes d'appairage, PIN, chronomètre, initiales d'avatar (`:219-223`) |

### 2.3 Échelle Interface guidée (environ +20 %) (`app_typography.dart:110-123`)

Facteur 1,2, décidé dans ce seul fichier. Styles changés : `headlineSmall` 32/40 700 ; `titleLarge` 32/40 600 ; `bodyLarge` 20/28 400 ; `bodyMedium` 20/28 400 ; `labelLarge` 20/28 600 ; `bodySmall` 16/24 400. Les autres styles restent ceux du §2.2. Métriques liées (`app_metriques.dart:18-52`) : cible tactile 72 (48 en standard), rayon de surface 24 (16 en standard), marge interne 24 (16 en standard).

### 2.4 Règles typographiques

| Règle | Source |
|---|---|
| Titres de page en 700, titres de section et de carte en 600, corps 400, libellés et boutons 500 à 600, valeurs fortes 700. | `app_typography.dart:95-97` |
| Un titre DM Sans ne se retaille pas : une autre taille de titre se demande dans le fichier. Une graisse se change seulement par `AppTypography.graisse` (axe `wght`), jamais par un faux gras. | `:99-102`, `:185-210` |
| Chiffres tabulaires obligatoires dans toute colonne, compteur, minuteur, tuile de statistique. | `:166-183` |
| Onglets et sous-navigation en Jakarta `labelLarge`, pas en DM Sans. | `app_theme.dart:138-144` |
| Hiérarchie par la couleur des trois encres, jamais par une police amincie (pas de graisse « light »). | `archive/produit/design-tokens.md:241-244` |
| Typographie française imposée par le manifeste : apostrophe typographique U+2019, espace fine insécable U+202F avant « ? ». | manifeste §3.3 (remarques) et §5 A12 |
| **ÉCART** : `assets/i18n/fr.i18n.json` compte 555 apostrophes droites U+0027 contre 8 typographiques, aucune U+202F, et 31 « ? » précédés d'une espace ordinaire. La règle n'est pas encore appliquée aux chaînes existantes. | comptage de ce relevé |
| **Arbitrage ouvert** : en Plus Jakarta Sans, l'apostrophe (droite ou typographique) est plus large qu'une espace ; rendu lu « l 'heure ». | `04_phase0/revue_jetons_a11y.md:35` (D9) |

## 3. Espacements et gabarits (`app_spacing.dart`, `app_gabarit.dart`)

### 3.1 Échelle (`app_spacing.dart:13-57`)

`4 (xs) · 8 (sm) · 12 (md) · 16 (lg) · 20 (xl) · 24 (xxl) · 32 (xxxl) · 40 (section) · 48 (titreEcran) · 64 (respiration)`. Aucune autre valeur n'est acceptée (`lib/CLAUDE.md:22-23`).

### 3.2 Largeurs et hauteurs (`app_spacing.dart:63-96`, `:102-108`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `largeurMaxContenu` | 1200 | Colonne de page, centrée au-delà (`page_shell.dart:239-251`) |
| `largeurGestion` | 1440 | Écrans de gestion (administration) |
| `largeurLecture` | 800 (et 68 caractères pour tout texte suivi) | Lecture, historique desktop |
| `largeurReglages` | 760 | Réglages, préférences |
| `largeurFormulaire` | 640 | Formulaires |
| `largeurDialogue` | 560 | Feuille bornée sur tablette, boîte de dialogue sur bureau, colonne d'admission (manifeste : 480 à 560) |
| `largeurEtatVide` | 400 | Écran résultat, état vide |
| `hauteurBouton` | 52 (72 en Interface guidée) | Bouton |
| `hauteurReglage` | 64 | Ligne de réglage à deux niveaux |
| `hauteurChoix` | 112 | Carte de choix |
| Cible tactile | 48 standard, 72 Interface guidée | Toute cible, même quand le dessin est plus petit |

### 3.3 Points de rupture et chrome (`app_gabarit.dart:10-121`)

| Gabarit | Largeur | Gouttière | Navigation |
|---|---|---|---|
| Mobile | < 600 | 16 | Barre basse flottante |
| Tablette | 600 à 1199 | 24 | Rail replié de 80 (icônes seules et infobulle pour le tuteur ; icône et nom dessous pour élève et enseignant, `nav_shell.dart:283-291`) |
| Desktop | ≥ 1200 | 32 | Barre latérale dépliée de 256 (admin : 288, `admin_shell.dart:100`) |

Seuils de contenu en plus : 840 (classe « étendue », densité seulement, `:62-63`), 560 (choix en deux colonnes si le texte est sous 150 %, `:70-71`, `:84-85`). **ÉCART** : le commentaire de `page_shell.dart:18-19` annonce des gouttières 20 / 32 / 48 ; le code applique 16 / 24 / 32 (`app_gabarit.dart:28-34`, `app_spacing.dart:65-71`).

Web = vraie version desktop, jamais le mobile étiré ; capture 1440 obligatoire pour chaque écran (`03_DECISIONS:36`, §1 ter-5).

## 4. Rayons (`app_radius.dart:13-77`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `xs` | 8 | Pastilles, petits contrôles, vignettes |
| `sm` | 12 | Champs, boutons, bloc imbriqué, bandeau, item du rail, encart (`app_theme.dart:24-27`) |
| `md` | 16 | Cartes, carte groupée, barre basse flottante |
| `lg` | 24 | Tuiles Bento, carte de choix, boîte de dialogue, carte « dominante », surfaces en Interface guidée |
| `full` | 999 | Avatars, pilules d'état, contrôle segmenté, bascule de thème, **CTA des étapes d'admission (seule exception de bouton en pilule)** (`action_principale.dart:96-101` ; `03_DECISIONS:75`) |
| `arrondiFeuille` | 24 en haut seulement | Feuille de bas d'écran |

Règle : le rayon d'un enfant est plus petit que celui de son parent (`app_radius.dart:10-12`).

## 5. Élévation (`app_elevation.dart:32-88`)

| Niveau | Composition (couleur `#211E28`) | Emploi réel |
|---|---|---|
| `niveau0` | aucune ombre | **Défaut réel des cartes, cartes groupées, cartes de choix** : filet `contourCarte` de 1 px sans ombre (`app_card.dart:140-142` ; manifeste §3.2 : aucune maquette ne montre d'ombre de carte) |
| `niveau1` | y 2, flou 8, 4 % + y 8, flou 24, 6 %, étalement -4 | Barre basse flottante ; carte « dominante » en clair seulement |
| `niveau2` | y 4, flou 12, 8 % + y 16, flou 40, 10 %, étalement -8 | Zone d'action collée en bas, menus, popovers, retour local |
| `niveau3` | y 12, flou 32, 22 % | Feuille, boîte de dialogue |
| `dialogue()` | `niveau2` en clair, **aucune ombre en sombre** | Dialogues et menus en sombre : surface plus claire au lieu d'une ombre |

Règles : une carte n'est jamais posée sur une carte (deux plans suffisent) (`:18-20`). **ÉCART** : le commentaire annonce des opacités « remontées à 0,10 / 0,09 » (`:38-40`) et une règle « filet ET ombre » (`:21-23`) ; le code rend 0,04 / 0,06 et, par défaut, un filet sans ombre.

## 6. Mouvement et délais (`app_mouvement.dart:17-123`, `app_delais.dart:14-29`)

| Jeton | Valeur | Emploi |
|---|---|---|
| `retourTactile` | 100 ms | Pression (échelle 0,98, retour haptique moyen, `pressable.dart:159-166`) |
| `micro` | 120 ms | Bascule, case, pastille qui change d'état, survol |
| `apparition` | 180 ms | Ligne qui entre, bandeau, retour local ; aussi délai avant squelette |
| `navigation` | 220 ms | Passage de page (translation 16, inversée en RTL) |
| `feuilleOuverture` / `feuilleFermeture` | 180 / 120 ms | Feuille et dialogue (**ÉCART** : les commentaires de `app_bottom_sheet.dart:35-37` et `:150-154` disent 280 / 200 ms) |
| `plafond` | 400 ms | Aucune animation plus longue |
| `pulsation` | 1200 ms | **Un seul élément pulse dans tout le produit** : le bloc « cours dans moins de 5 minutes » de l'élève (ELV-02) |
| `retourLocalMaintien` | 3 s | Retour local (translation 12) |
| Courbes | entrée `easeOutCubic`, sortie `easeInCubic`, ressort sans rebond ; `linear` réservé aux progressions indéterminées ; aucun rebond, même en Interface guidée | `:65-85` |
| Mouvement réduit | durée 0, translation 0 ; la pulsation devient une bordure `borderStrong` fixe | `:101-122` |
| `chargementProlonge` | 8 s | Le squelette reste et une phrase dit que c'est long |
| `requeteMax` | 20 s | Tentative tenue pour perdue, « Réessayer » (3 fois au plus, `bloc_asynchrone.dart:75`) |

## 7. Iconographie (`lib/core/icons/app_icons.dart`)

- Une seule bibliothèque : **Phosphor**, deux graisses embarquées : `regular` (repos, contenu, navigation inactive) et `fill` (actif, sélectionné, médaillon, cercle héros). La paire est liée à la construction (`:3-20`). Zéro emoji, aucun Material ni Font Awesome (`:24-29`).
- 80 icônes au catalogue (`static const AppIcon`, comptage de ce relevé). Taille courante 24 (navigation, rubrique, disque retour), 20 (chevron, flèche de CTA, bouton de repli), 40 (cercle héros), 64 (état vide ; 96 en Interface guidée).
- Directionnelles miroitées en arabe : retour, flèche de CTA, chevron de ligne, repli et dépli du rail, se connecter. Non miroitées : horloge, progression du temps (`suivant`), menu déroulant (vers le bas), rotation (`:84-107`, `:347-380`, `:427-451`).
- Icônes de navigation du tuteur : Accueil `0xe2c2`, Foyer `0xe68e`, Historique `clock-counter-clockwise 0xe1a0`, Compte `0xe4c2` (`:46-50`, `:66-70`, `:84-92`, `:123-127`). « Un tuteur observe » = œil ouvert `0xe220` (`:599-615`). Prière `0xecee` (pictogramme compris sans lire, `:246-253`).
- Une icône ne porte jamais seule un état (`archive/produit/design-tokens.md:325-326`).

## 8. Navigation et coquilles (faits du code)

| Rôle | Destinations, dans l'ordre | Source |
|---|---|---|
| Tuteur | **Accueil · Foyer · Historique · Compte**, identiques sur tous les formats ; Compte épinglé en bas de la colonne latérale | `nav_shell.dart:91-120` ; `03_DECISIONS:79` (§3.6) |
| Élève (standard) | Accueil · Coran · Suivi · Compte | `nav_shell.dart:66-90` |
| Élève (Interface guidée) | aucune navigation | `:52-57` |
| Enseignant | Journée · Créneaux · Profil (exactement trois) | `:121-144` |
| Contrôleur, comptable | aucune coquille | `:145-157` |
| Administration | coquille propre, 8 domaines : Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit, Direction ; tiroir < 600, rail 600-1199, barre latérale ≥ 1200 ; jamais de barre basse ; barre supérieure = recherche, notifications, compte seulement | `admin_shell.dart:17-42` ; `core/admin/admin_domaine.dart:55-62` |

Anatomie :
- **Barre basse flottante** (< 600) : pilule `surfaceRaised`, rayon 16, filet `contourCarte`, `niveau1`, marges 12 à gauche et à droite, 8 au-dessus, au moins 12 sous elle dans la zone sûre ; hauteur minimale 64 ; icône 24 ; libellé `labelMedium` 500 (600 si actif) ; actif = icône pleine + libellé `inkAccent` + soulignement 40 x 3 `inkAccent` arrondi ; inactif = icône au trait + `inkMuted` ; texte borné à 150 % (`nav_shell.dart:361-507`).
- **Colonne latérale** (≥ 600) : `surfaceRaised`, filet `contourCarte` côté contenu ; en tête le mot-symbole « Rewayah » (`titleLarge` 700, `inkStrong`) et un bouton de repli (disque 40 `surfaceOverlay` dans une cible 48) ; items de 48 au moins, rayon 12, icône 24, libellé `bodyLarge` 500 (600 actif) ; actif clair = fond `washAccent` + `inkAccent` ; actif sombre = fond `surfacePrimary` + encre `#25113F` ; inactif = icône `inkMuted`, libellé `inkStrong`. Repli mémorisé par appareil (`:571-927`).
- **En-tête de page** : disque retour 48 (niveau 2 et tâche focalisée seulement) puis titre (`headlineSmall` 28 sous 600, `headlineMedium` 32 au-delà) et sous-titre `bodyLarge` `inkMuted` ; à droite, bascule clair/sombre (tablette et bureau seulement) puis cloche 48 (point de non-lus 8 `surfacePrimary` cerclé de 2, seulement pour de vrais non-lus) (`entete_page.dart:11-205`).
- **Page** (`page_shell.dart:41-199`) : 48 au-dessus du titre (24 si l'en-tête porte retour ou actions ; 64 en Interface guidée), 24 sous le titre, puis l'en-tête fixe éventuel (sélecteur, segment) suivi de 20 ; 40 de respiration en bas ; zone d'action collée en bas sur `surfaceRaised`, filet haut `borderHairline`, `niveau2`, marges 16.
- **Tâche focalisée** (ajout de profil, questionnaire, émetteur QR, sous-pages de préférences, consentement) : pas de barre basse sur mobile, disque retour obligatoire ; la colonne latérale reste sur tablette et bureau (`nav_shell.dart:276-281`).

## 9. Catalogue des composants partagés (`lib/core/widgets/`)

Colonne « Employé » : nombre de fichiers hors `core/widgets` et hors galerie de développement qui l'emploient à `cefab7f`. « 0 » = créé en phase 0, pas encore consommé par un écran sur cette branche (les lots peuvent l'employer sur leurs branches, À VÉRIFIER).

| Composant (fichier:ligne) | Rôle | Anatomie en une ligne | Employé |
|---|---|---|---|
| `ActionPrincipale` (`action_principale.dart:48`) | Seul point d'entrée d'un bouton ; 4 niveaux | Hauteur 52, marges 20 x 12, rayon 12, `labelLarge` ; **principale** = `surfaceActionDouce`, une par écran, flèche « → » facultative ; **secondaire** = `surfaceRaised` + filet `borderStrong` 2 (deux au plus) ; **tertiaire** = texte `inkAccent` ; **destructive** = texte `inkAlert`, jamais de fond rouge ; désactivé = `surfaceRaised` + filet 3 + `inkMuted` ; en cours = indicateur 20 | 48 |
| `PageShell` (`page_shell.dart:41`) | Gabarit de toute page | Voir §8 | 48 |
| `PageParcours` (`page_parcours.dart:26`) | Page de parcours : une question, une action | Progression en segments (« n sur N »), temps restant, retour, un seul bouton qui avance | 3 |
| `PageImmersive` (`page_immersive.dart:49`) | Plein cadre sans titre (salle, Coran) | Registre « salle » (`surfaceInverse`) ou « lecture » (`surfaceQuran`) ; ordre : en-tête, contenu, bandeau, commandes | 5 |
| `NavShell` (`nav_shell.dart:204`) | Navigation de premier niveau, 4 destinations au plus | Voir §8 | 1 |
| `AdminShell` (`admin_shell.dart:43`) | Coquille admin, 8 domaines | Tiroir, rail 80, barre 288 ; domaine sans fonction = visible mais atténué, inerte | 1 |
| `EntetePage`, `DisqueRetour`, `ClocheNotifications` (`entete_page.dart:25`, `:94`, `:139`) | En-tête, retour, cloche | Voir §8 | via `PageShell` |
| `BasculeTheme` (`bascule_theme.dart:30`) | Bascule clair/sombre de l'en-tête (≥ 600) | Pilule `surfaceRaised` + filet, segments soleil / lune de 48 ; actif clair `washAccent` + icône `inkAccent`, sombre `surfacePrimary` ; même préférence que Compte > Préférences > Apparence | 1 |
| `AppCard` (`app_card.dart:27`) | Seule surface de contenu | `surfaceRaised`, rayon 16, filet `contourCarte` 1, marge 20 (< 600) ou 24 ; retenue = `washAccent` + filet `inkAccent` 2 ; « dominante » = rayon 24 + `niveau1` en clair ; en-tête et actions facultatifs espacés de 16 | 32 |
| `GroupeReglages` + `LigneRubrique` (`groupe_reglages.dart:55`, `:13`) | **La carte groupée** (§1 ter-3) : un seul rectangle, lignes séparées par filets en retrait | Titre facultatif `titleMedium` au-dessus, 8 ; surface `surfaceRaised` rayon 16 filet `contourCarte` ; ligne ≥ 48 : icône 24 `inkAccent`, 12, libellé `bodyLarge` `inkStrong`, valeur ou légende `bodyMedium` `inkMuted`, chevron 20 `inkMuted` ou interrupteur ; filet `contourCarte` sous le texte (pas sous l'icône), absent sous la dernière ligne ; marges 16 et 12 | 0 |
| `SettingRow` (`setting_row.dart:11`) | Ancienne ligne de réglage | **Chaque ligne est son propre rectangle** (rayon 16, filet bas), icône `inkMuted`, titre `titleMedium` : contraire à §1 ter-3 pour une carte groupée ; retrait proposé quand les écrans seront migrés (`04_phase0/0c1_composants.md:75`) | 8 |
| `BentoTile` (`bento_tile.dart:42`) | Bloc de grille | Largeur pleine, demie, tiers ou quart ; `surfaceRaised` + filet | 13 |
| `ChoiceCardGroup` (`choice_card_group.dart:53`) | Tout choix proposé | Cartes ≥ 112, marge 20, rayon 24, filet `borderResting` ; retenue = `washAccent` + `borderStrong` + coche pleine ; libellé `titleMedium` ; carte « Autre » systématique sauf `autoriserSaisieLibre: false` (choix d'usage, décision du directeur, `03_DECISIONS:81`) | 12 |
| `ControleSegmente` (`controle_segmente.dart:35`) | 2 à 4 vues exclusives (« Séances / Observations ») | Piste `surfaceSunken` en pilule ; segment actif `washAccent` + filet `inkAccent` ; `labelLarge` ; segments ≥ 48, largeur égale | 0 |
| `SelecteurProfils` (`selecteur_profils.dart:74`) | Rangée de profils élèves (Accueil, Historique) | Avatar 56 (mobile) ou 72 ; initiale ou photo ; point de statut 12 cerclé du fond ; anneau 2 `surfacePrimary` si sélectionné ; prénom `labelLarge`, état `bodySmall` (`inkAccent` si sélectionné) ; dernier item « Ajouter » ; défilement horizontal sur mobile | 0 |
| `AvatarTile` (`avatar_tile.dart:29`) | Photo d'élève ou initiales | Diamètre par défaut 96 (144 guidée) ; repli `washFamily` + contour `borderStrong`, initiale en `chiffre` ; échec de chargement = même repli, jamais une icône d'erreur | 10 |
| `StatusPill` (`status_pill.dart:60`) | État nommé | Pilule, marges 12 x 4, point 8 + 8 + mot `labelMedium` ; fond doux du ton ; point pris dans `pointsStatut` | 34 |
| `EcranResultat` (`ecran_resultat.dart:31`) | Tout ce qui remplace le contenu (fin de visite, 404, accès refusé, session expirée, vide actionnable) | Colonne 400 centrée : cercle héros 96 (fond doux du ton, icône pleine 40), 24, titre `titleLarge`, 8, phrase `bodyLarge` `inkMuted`, 20, encart `washAccent` rayon 12, 24, CTA avec flèche, 8, lien tertiaire | 0 |
| `EtatSysteme` (`etat_systeme.dart:79`) | 12 natures d'état, portée bloc ou page | Bloc : carte à filet rayon 16, médaillon 40, titre `titleSmall`, phrase `bodyMedium`, action secondaire ; page : grammaire d'`EcranResultat`. Aucun code technique affiché | 2 |
| `EmptyState` (`empty_state.dart:46`) | Liste vide | Icône 64 (96 guidée) ; `titleLarge` ; invitation `bodyMedium` ; 3 registres : actionnable (accent + bouton), subi (neutre, sans bouton), bonne nouvelle (vert, ton neutre, sans félicitations) | 51 |
| `BlocAsynchrone` (`bloc_asynchrone.dart:40`) | Bloc qui charge | Squelette, puis phrase « long » à 8 s, puis erreur de bloc à 20 s, puis contenu ou vide ; « Réessayer » 3 fois au plus ; « indisponible » sans « Réessayer » | 0 |
| `Skeleton` (`skeleton.dart:27`) | Chargement | Blocs `surfaceSunken` à la forme du contenu final, rien avant 180 ms, ni scintillement ni pulsation | 42 |
| `OfflineBanner` (`offline_banner.dart:32`) | Hors ligne | Pleine largeur en tête de page, `washWarning` + `inkWarning`, filet fort en tête, dit ce qui continue de marcher | 1 (+ `PageShell`) |
| `LocalFeedback` (`local_feedback.dart:27`) | Retour d'une action | Bandeau `washAccent` rayon 12 posé sous la zone qui a changé, `niveau2`, 3 s ; jamais de boîte de succès ; « Annuler » préféré à une confirmation | 10 |
| `ConfirmDestructive` (`confirm_destructive.dart:27`) | Seule confirmation destructive | Question, conséquence en langage humain (obligatoire), « Annuler » d'abord, puis l'action qui nomme l'objet et l'acte (« Retirer Aicha ») | 4 |
| `AppBottomSheet` (`app_bottom_sheet.dart:40`) | Seule surface modale | Mobile : feuille pleine largeur, poignée 40 x 4, rayon 24 en haut ; tablette : bornée à 560 ; bureau : boîte de dialogue centrée 560, rayon 24, `surfaceOverlay` ; titre `headlineSmall` ; `niveau3` ; `Echap` ferme | 18 |
| `SectionHeader` (`section_header.dart:19`) | Titre de section, compteur, action tertiaire | Compteur tabulaire, zéro affiché | 20 |
| `LienFleche` (`lien_fleche.dart:20`) | « Voir tout → », « Voir l'historique → » | Texte `labelLarge` `inkAccent` + flèche 20, souligné au survol, cible 48, aucune surface | 0 |
| `LigneCleValeur` (`ligne_cle_valeur.dart:19`) | « Horaire : 18:00 (heure de Paris) » | Clé `inkMuted`, valeur `inkStrong` côte à côte ; empilées dès 150 % de texte ; lues en un seul nœud | 0 |
| `LignePresence` (`ligne_presence.dart:28`) | Présence d'une personne | Nom, pastille et mot, durée (« en salle depuis 12 min ») ; présence illisible = « État inconnu », jamais « Absence » | 5 |
| `SignalRow` (`signal_row.dart:21`) | Ligne « à traiter » | Icône, phrase, ancienneté, chevron ; mène toujours à une action | 2 |
| `StatTile` (`stat_tile.dart:22`) | Chiffre et libellé | `displaySmall` tabulaire + `labelMedium`, zéro affiché, mène à son écran | 3 |
| `TimelineRow` (`timeline_row.dart:20`) | Journée : cours, pause, prière | Même ligne pour les trois, libellé et icône décidés par le composant | 1 |
| `FilterPill` (`filter_pill.dart:25`) | Valeur de filtre d'un axe fermé | Pilule, compteur tabulaire | 12 |
| `MenuFiltre` (`menu_filtre.dart:54`) | Axe de filtre ouvert | Bouton pilule qui porte la sélection courante, menu dessous | 3 |
| `MenuActions` (`menu_actions.dart:36`) | Actions rares d'un objet | Menu contextuel, jamais un bouton permanent par ligne | 5 |
| `DataCollection` (`data_collection.dart:96`) | Tableau dense sur desktop, cartes ailleurs | Seuil desktop ; en-tête collé `surfaceSunken` ; colonne identifiante = titre de carte | 11 |
| `ChildCard` (`child_card.dart:100`) | Carte enfant de l'ancien Accueil famille (7 états) | Avatar, prénom `titleMedium`, détail, action ; imminent = liseré gauche 4 `borderStrong` ; « sans planning » = contour fort. Héritage du matching remplacé, À VÉRIFIER s'il survit au nouvel Accueil | 1 |
| `ScheduleOption` (`schedule_option.dart:13`) | Proposition d'horaire de l'administration | Carte rayon 16, aucune saisie libre de date | 1 |
| `SelecteurNiveauProgramme` (`selecteur_niveau_programme.dart:13`) | Niveaux du programme groupés par cycle | Nom humain seul, jamais le code | 3 |
| `SousNavigationDomaine` (`sous_navigation_domaine.dart:21`) | Onglets d'un domaine admin | Onglets = routes distinctes | 8 |
| `MarquePage` (`marque_page.dart:13`) | Marque du tunnel d'entrée | « Rewayah Academy » en `headlineLarge` `inkAccent` ; aucun logo n'existe | 6 |
| `PermanentNotice` (`permanent_notice.dart:25`) | Bandeau permanent de la salle | Aucun paramètre ; même ligne pour tous, contrôleur présent ou non : « Cours enregistré, visite de contrôle possible. » (`03_DECISIONS:22`) | 2 |
| `BandeauObservation` (`bandeau_observation.dart:35`) | Session d'observation par un agent IA | Registre doux `washWarning` ; dit lecture seule, prénoms masqués, heure d'expiration | 1 |
| `AudioLabel` (`audio_label.dart:23`) | Haut-parleur qui rejoue un libellé (zéro lecture) | Icône `inkAccent` ; clé audio, jamais un chemin libre | 1 |
| `PinPad` (`pin_pad.dart:25`) | Pavé numérique géant de l'élève | Le code ne quitte jamais l'appareil | 1 |
| `RosaceVerset` (`rosace_verset.dart:23`) | Numéro de verset | Cercle dessiné + chiffres arabo-indiens, muet pour le lecteur d'écran | 3 |
| `Pressable` (`pressable.dart:83`) | Seul retour tactile | Échelle 0,98, 100 ms, haptique moyen, survol et anneau de focus 2 `inkAccent` | 10 (+ tous les composants) |

Carte groupée : `GroupeReglages` ne sait pas encore porter un en-tête **dans** le rectangle (médaillon 48, titre, résumé, pastille) comme les cartes de Mon compte (V3) ; le lot E a posé une carte locale en attendant la promotion demandée (`demandes/E.md:34-42`). Deux défauts relevés au même endroit : valeur collée au libellé au lieu d'être calée à droite ; fond de survol qui recouvre le filet latéral.

## 10. Vocabulaire

| Imposé | Interdit | Source |
|---|---|---|
| « Interface guidée » | « Mode enfant », « mode enfant » | `docs/current/00:28` ; test `q09_interface_guidee_cibles_test.dart:119-138` |
| « Sayyid » / « Sayyida » (enseignants, dans l'espace de cours) | « Ustadh », « Sayda » | `docs/current/00:28`, `docs/current/03:12` ; manifeste §5 A5 ; clés `tc.groupe.enseignant.sayyid` (`fr.i18n.json:1838-1839`) |
| « Séance », « Cours » | « Session » (au sens de séance ; « session » d'authentification reste) | `03_DECISIONS:80` (§3.7) ; manifeste §5 A1 |
| « Séance toujours en direct », « En direct » (séance prolongée) | « Cours en cours », « Cours toujours en cours », compteur négatif | `03_DECISIONS:80` ; manifeste §5 A4 |
| « Ajouter un profil élève », « profils élèves », « Réglages de {prénom} » | « Ajouter enfant », « Ajouter un enfant », « Enfants », « Gérer tous les enfants », « Paramètres de l'enfant » | `03_DECISIONS:80` ; manifeste §5 A2 |
| « Avant le prochain cours » | « Avant / Après la séance » | manifeste §5 A3 |
| « Connexion et sécurité » | « Sécurité et connexion » | manifeste §5 A6 |
| « Pour qui souhaitez-vous utiliser Rewayah ? », « Moi uniquement », « Moi et ma famille » | « Quel type de compte… », « Pour qui créez-vous ce compte ? » | manifeste §5 A7 ; `03_DECISIONS:81` |
| « Détails de la séance » | « Détails et connexion » | manifeste §5 A8 |
| « En cours de vérification » (présence incertaine), « État inconnu » | « Absence » déduite d'une déconnexion | manifeste §5 A10, C7 ; `ligne_presence.dart:18-22` |
| Noms humains | Codes internes visibles (`F1-PHO-01`, `CORE24`, `DB-xxx`, codes de niveau) | `docs/current/03:12` ; `etat_systeme.dart:77-78` ; `selecteur_niveau_programme.dart:9-10` |
| Bouton = verbe et objet (« Poser un créneau », « Retirer Aicha ») | « Valider », « OK », « Supprimer » seuls | `action_principale.dart:62-63` ; `confirm_destructive.dart:22-23` |
| Titre qui nomme (« Aujourd'hui ») | Titre qui accueille (« Bienvenue sur votre tableau de bord ») | `page_shell.dart:58-60` |
| État vide = invitation (« Aucun cours aujourd'hui, ton prochain cours est jeudi ») | « Aucune donnée » | `empty_state.dart:34-37` |
| Ponctuation classique, deux-points | Emoji, tiret cadratin (U+2014) | `lib/CLAUDE.md:34` ; `archive/produit/design-tokens.md:319-322` |
| Phrases courtes et concrètes | « Dans le monde numérique d'aujourd'hui… », « Il est important de noter que… », « Révolutionnez… », « Sans plus attendre… », « Découvrez… », superlatifs | `archive/produit/design-tokens.md:386-412` (archive, non contredite) |
| « Classe » côté tuteur (« Voir la classe », routes `/tuteur/classes`) | À VÉRIFIER pour les autres rôles : à `cefab7f`, 71 chaînes visibles contiennent « groupe » et 4 « classe » ; `docs/current/06:18` dit « Espace Groupe » | manifeste §2 et §3.4 ; comptage de ce relevé |

**ÉCART** (chaînes existantes encore contraires, à remplacer dans les spécifications) : `enfant.titre` = « Ajouter un enfant » (`fr.i18n.json:336`) ; `compte.ajouterEnfant` = « Ajouter un enfant » (`:1297`) ; `compte.modeEnfant` = « Mode enfant » (`:1299`) ; `tc.groupe.temps.enCours` = « Cours en cours · {reste} » (`:1857`) ; `tc.groupe.temps.prolongee` = « Cours toujours en cours » (`:1859`).

Langue arabe : `assets/i18n/ar.i18n.json` ne contient qu'une vingtaine de clés (suivi élève et « Sayyid / Sayyida »). L'interface arabe n'existe donc pas encore au-delà de ces écrans. À VÉRIFIER avec le directeur avant de dessiner une maquette RTL complète.

## 11. Éthique visuelle trouvée dans le dépôt

| Règle | Statut | Source |
|---|---|---|
| Pas de femmes non voilées dans les illustrations, avatars ou images décoratives. | Archive, non contredite par `docs/current` : À CONFIRMER par le directeur | `docs/archive/2026-09-pre-remise-a-plat/produit/design-tokens.md:353-366` (§5 « Éthique islamique ») |
| Pas d'idoles ni de représentations de divinités. | idem | idem |
| Pas de caricatures obscènes ou malsaines. | idem | idem |
| Pas de représentation des prophètes ni des compagnons. | idem | idem |
| Pas de symboles religieux non musulmans (croix, étoile à six branches, etc.). | idem | idem |
| Recommandé : personnages masculins avec barbe et/ou kufi ou turban quand c'est approprié ; personnages féminins avec hijab ; motifs géométriques et calligraphiques islamiques pour la décoration. | idem | `design-tokens.md:368-374` |
| Recommandé : vert et or pour les accents religieux. **CONFLIT** avec le gel : aucun jeton or, le vert est réservé au succès. Le gel (§1 ter-2) prime tant que le directeur n'a rien décidé. | À TRANCHER | `design-tokens.md:373-374` ; `03_DECISIONS:33` |
| Illustrations : style Storyset / Rafiki, vectorielles, **ramenées à la palette** ; photos réelles réservées aux profils ; **« Pas de génération IA d'images »**. **CONFLIT** avec la demande de faire produire des images par ChatGPT : la règle vise les illustrations du produit ; une maquette est un document de travail. À TRANCHER : toute illustration visible dans une maquette reste un emplacement réservé, jamais un visuel destiné à la production. | À TRANCHER | `design-tokens.md:332-349`, `:376-382` |
| Photo d'élève : URL signée courte, jamais exposée à l'enseignant ni aux autres élèves ; repli identique au cas sans photo, jamais un triangle d'erreur. | Code | `avatar_tile.dart:8-22` |
| Photos publiques d'enseignants distinctes des pièces d'identité. | Canonique | `docs/current/03:12` |
| Le Coran ne se traite jamais comme une carte entourée de contrôles ; contenu avant chrome ; texte canonique jamais modifié ; aucun « Mushaf fidèle » simulé par retour à la ligne ; annotation dans sa couche, jamais dans le texte. | Code et canonique | `page_immersive.dart:29-32` ; `docs/current/03:17` ; `docs/current/00:31` |
| Chiffres de verset arabo-indiens dans une rosace dessinée, jamais un glyphe absent. | Code | `rosace_verset.dart:7-22` |
| Surface Coran figée dans les deux thèmes. | Code et test | `app_palette.dart:5-7` ; `contraste_test.dart:41-43` |
| Aucun texte arabe inventé ni approximatif dans une maquette (lettres confondues, voyelles manquantes relevées sur V8) : le support est un document vérifié, jamais un décor. | Manifeste | manifeste §5 C23 |
| Transparence de l'observation : la visite de contrôle est annoncée en permanence par une ligne identique pour tous ; une observation qui ne se voit pas est une observation cachée ; « un tuteur observe » s'affiche par un œil. | Code | `permanent_notice.dart:9-24` ; `bandeau_observation.dart:12-19` ; `app_icons.dart:599-611` |
| Ton jamais culpabilisant, jamais infantilisant, même en Interface guidée ; pas de félicitations sur un écran vu vingt fois par jour. | Archive et code | `design-tokens.md:407` ; `empty_state.dart:25-29` |
| Aucune règle trouvée sur la mixité ou la séparation des genres dans les visuels, ni sur les formules religieuses à l'écran. | À VÉRIFIER | recherche « éthique », « islamique », « voil », « hijab », « mixit » dans `lib/` et `docs/` |

Mise en garde : ce même fichier d'archive (`design-tokens.md`) porte les **anciennes valeurs** (fond crème `#F8F4EE`, Bricolage Grotesque, Instrument Sans, ombre `#3A302A`, gouttières 20 / 32 / 48). Elles sont périmées ; seules ses règles d'éthique et de rédaction sont citées ici. Même chose pour l'identité « vert `#1B6B5A`, or `#C9A84C`, beige `#F7F5F1` » d'un ancien audit (`archive/architecture/audit-initial.md:188`) : elle ne fait pas partie du système gelé.

## 12. Actifs visuels absents du dépôt (à connaître avant de dessiner)

| Actif | Constat | Source |
|---|---|---|
| Logo | Aucun fichier ; la marque est le texte « Rewayah Academy » (`commun.marque`) ou « Rewayah » (mot-symbole du rail) | `marque_page.dart:8-12` ; `fr.i18n.json:3` ; `nav` `motSymbole` |
| Icône d'application | `web/icons/Icon-192.png` est l'icône Flutter par défaut (vue) ; icônes Android et iOS de tailles typiques du gabarit Flutter, À VÉRIFIER à l'œil | `web/icons/`, `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset` |
| Illustrations | Aucune image dans `assets/` (seulement `audio`, `fonts`, `i18n`) ; les états vides emploient une icône Phosphor de 64 | `assets/` ; `empty_state.dart:95-103` |
| Maquettes existantes | 19 fichiers dans `docs de lancement/tutuor image/` (10 dans `mobile/`), inventoriés et corrigés par le manifeste §1 et §5 ; écrans du tuteur encore sans maquette : `09_chatgpt/TUTEUR_ECRANS_SANS_MAQUETTE.md` | manifeste §1 |

## 13. Écarts et décisions en attente qui touchent le dessin

1. CTA en Interface guidée : aplat `surfacePrimary` gardé tant que le directeur n'a pas tranché sur capture (`action_principale.dart:235-240`).
2. Rail de tablette : icônes seules pour le tuteur, icône et nom pour élève et enseignant, en attendant une décision du directeur (`nav_shell.dart:283-291`).
3. Carte de choix : le code rend `washAccent` + filet `borderStrong` 1 + coche, rayon 24 ; le manifeste décrit bordure 2 `inkAccent` + radio 24 (manifeste §3.4, « Carte de choix ») ; extension radio, description et miniature demandée (`demandes/E.md:44-48`).
4. `lib/CLAUDE.md:45-46` dit encore « `inkFaint` interdit sur `surfaceSunken` (4,48) » : valeur périmée, mesure actuelle 4,65 (`04_phase0/0b_jetons.md:82`, `:121`).
5. Préférence clair / sombre non persistée sur le web : perdue à chaque rechargement (`revue_jetons_a11y.md:36`, D10).
6. Quatre commentaires du code annoncent des valeurs que le code n'applique pas : gouttières (§3.3), opacités d'ombre et « filet ET ombre » (§5), durées de feuille (§6). Les valeurs du code font foi.


---


# D. Tuteur : écrans sans maquette

# Rôle Tuteur : écrans et états sans maquette high-fi (faits vérifiés)

Date : 24/09/2026. Destinataire : ChatGPT, pour le document `01_TUTEUR_COMPLEMENTS.md` et ses maquettes.
Statut : relevé en lecture seule, aucun fichier du dépôt modifié.

## 0. Comment lire ce document

**Sources** (toutes lues pour ce relevé) :
- `MANIFESTE` = `pilotage-tuteur-v1/01_visuel/00_MANIFESTE.md` (§1 inventaire des maquettes, §2 écrans sans maquette, §5 erreurs, §6 dérivations).
- `V1` à `V9` = rapports détaillés `pilotage-tuteur-v1/01_visuel/V*.md` (une maquette ou un groupe par rapport).
- `MANDAT` = `docs de lancement/REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§4 arbre des routes, §5 contenu, §6 admission, §7 appareils, §8 états) ; `MANDAT-OBS` = sa seconde partie « Prompt étape observation tuteur » (§1 à §10).
- `DÉCISIONS` = `pilotage-tuteur-v1/03_DECISIONS_COORDINATEUR.md` (les §1 bis, §1 ter, §1 ter bis sont des réponses du directeur et priment).
- `MAPPING` = `pilotage-tuteur-v1/02_code/00_MAPPING_ROUTES.md` (numéros de ligne de son §3 : « l.n ») ; `C03` = `02_code/C03_admission.md`.
- `LOTS` = `pilotage-tuteur-v1/05_LOTS_PHASE1.md` ; `BACKLOG` = `pilotage-tuteur-v1/08_BACKLOG_VAGUE_CLASSE_VISIO.md`.
- `CODE` = dépôt `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (fin de la phase 0 : routeur, thème, composants partagés ; les écrans des lots sont encore des écrans réservés marqués « STUB PHASE 0 » dans 40 fichiers de `lib/`).
- `FINANCE` = `RA -OFFICIAL-APP/docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md`.

**Conventions** :
- `#n` = numéro de la zone de maquette dans MANIFESTE §1 (33 zones dans 19 fichiers du dossier `docs de lancement/tutuor image/`). Le tableau du §1 ci-dessous les rappelle.
- `SM-nn` = identifiant d'un écran **sans maquette** dans ce document. ChatGPT peut le reprendre ou le remplacer par `TUT-nn`, à condition de garder la correspondance.
- `DB-xxx` = dépendance serveur manquante, recensée dans `02_code/00_DEPENDANCES_BACKEND.md`. En production, l'écran affiche alors l'état « indisponible » (texte existant : « Pas encore disponible » / « Cette fonction n'est pas encore ouverte. », `CODE assets/i18n/fr.i18n.json:56-59`).
- « À vérifier » = fait que je n'ai pas pu prouver.

**Règles du directeur qui s'appliquent à chaque maquette à produire** (DÉCISIONS §1 ter) :
1. Les maquettes font autorité pour la **disposition** (ordre des sections, colonnes, place exacte de chaque bouton et de la route qu'il ouvre), jamais pour la palette. Couleurs et polices viennent du système gelé : DM Sans pour les titres, Plus Jakarta Sans pour tout le reste, palette ajustée listée en DÉCISIONS §3.1.
2. Une fonction = un seul endroit, aucun doublon. Seul raccourci admis : « Créer mon profil élève » depuis Foyer ET Compte, qui ouvre le même flux.
3. Carte groupée = UN seul rectangle, lignes séparées par un filet fin en retrait. Jamais un rectangle par ligne.
4. Barre de navigation, retour visible sur chaque écran de niveau 2 et chaque tâche focalisée, déconnexion accessible sur tous les formats. Aucune impasse.
5. Web = vraie version ordinateur (rail dès 600 dp, barre latérale dès 1200 dp), jamais le mobile étiré.
6. Captures de recette exigées : **390 × 844 et 1440 × 900, clair ET sombre** pour chaque écran (LOTS §0).
7. Navigation tuteur : **Accueil · Foyer · Historique · Compte**, même ordre partout (DÉCISIONS §3.6).

---

## 1. Rappel : les maquettes qui existent déjà (ne pas les redessiner)

| # | Fichier | Écran réel | Thème | Format | Route retenue (CODE) |
|---|---|---|---|---|---|
| 1 | `acceuil tuteur desktop light.png` | Accueil | Clair | Ordinateur ≈ 1440 | `/tuteur` |
| 2 | `acceuil tuteur desktop dark.png` (moitié gauche) | Accueil, rail replié | Sombre | Tablette ≈ 690 | `/tuteur` |
| 3 | `acceuil tuteur desktop dark.png` (moitié droite) | Accueil, rail déplié | Sombre | Ordinateur étroit ≈ 1100 | `/tuteur` |
| 4 | `mobile/accueil  tuteur mobile light mode.png` | Accueil | Clair | Mobile | `/tuteur` |
| 5 | `mon compte tuteur desktop light mode.png` | Mon compte | Clair | Ordinateur | `/tuteur/compte` |
| 6 | `mobile/mon compte tuteur mobile light mode.png` | Mon compte | Clair | Mobile | `/tuteur/compte` |
| 7 | `mobile/mon compte tuteur desktop dark mode.png` | Mon compte (nom de fichier faux : c'est un MOBILE) | Sombre | Mobile | `/tuteur/compte` |
| 8 | `réglages tutor mobile dark mode.png` (écran 01) | Réglages (hub des préférences du titulaire) | Sombre | Mobile | `/tuteur/compte/preferences` |
| 9 | idem (écran 02) | Apparence | Sombre | Mobile | `/tuteur/compte/preferences/apparence` |
| 10 | `onboarding Mble.png` | Choix d'usage | Sombre | Mobile | `/inscription/usage` |
| 11 | `onboarding Mble d.png` | Genre (« d » ne veut pas dire dark) | Sombre | Mobile | `/inscription/genre` |
| 12 | `onboarding mobile 1.png` E1 | Choix d'usage (autre version) | Sombre | Mobile | `/inscription/usage` |
| 13 | idem E2 | Genre | Sombre | Mobile | `/inscription/genre` |
| 14 | idem E3 | Âge (champ libre) | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 15 | `Onboarding mobile 2.png` E4 | Langue de l'application | Sombre | Mobile | relève de `/tuteur/compte/preferences`, pas de l'admission |
| 16 | idem E5 | Objectif | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 17 | idem E6 | Récapitulatif « Tout commence ici. » | Sombre | Mobile | `/inscription/recapitulatif` |
| 18 | `mobile/tuteur observation mobile light.png` M1 | Classe de l'enfant + bloc Observation | Clair | Mobile | `/tuteur/classes/:classeId` |
| 19 | idem M2 | Explication de première utilisation | Clair | Mobile | `/tc/observation/:seanceId` (étape avant « Entrer ») |
| 20 | idem M3 | Salle d'observation, visite 1/2 | **Sombre** | Mobile | `/tc/observation/:seanceId` |
| 21 | idem M4 | Salle d'observation, visite 2/2 | Clair | Mobile | `/tc/observation/:seanceId` |
| 22 | idem M5 | Fin de visite (écran résultat) | Clair | Mobile | retour `/tuteur/classes/:classeId` |
| 23 | idem M6 | Consentement « Les visites des parents » | Clair | Mobile | `/attente/contrat` et `/tuteur/compte/consentements` |
| 24 | `tuteur observation desktop light.png` D1 | Salle d'observation | Clair | Ordinateur | `/tc/observation/:seanceId` |
| 25 | idem D2 | Historique, segment Observations | **Sombre** | **Mobile** | `/tuteur/suivi/observations` |
| 26 | idem D3 | Historique des observations, ADMINISTRATION | Clair | Ordinateur | `/admin/securite-audit/observations` (hors rôle tuteur) |
| 27 | idem D4 | Détail d'une observation | Clair | **Mobile** | `/tuteur/seances/:seanceId/observations?eleve=` |
| 28 | `tutor observation map.png` | Logigramme du parcours Observation | - | - | aucune (planche de direction, aucune valeur visuelle réutilisable) |
| 29 | `mobile/Accueil.png` | ANCIENNE capture de l'Accueil (remplacée par #4) | Sombre | Mobile | contenu seulement |
| 30 | `mobile/Foyer Member.png` | ANCIENNE capture du Foyer | Sombre | Mobile | contenu seulement |
| 31 | `mobile/Historique.png` | ANCIENNE capture de l'Historique des séances | Sombre | Mobile | contenu seulement |
| 32 | `mobile/Classe Details.png` | ANCIENNE capture de la Classe | Sombre | Mobile | contenu seulement |
| 33 | `mobile/Profil.png` | ANCIENNE capture de la FICHE ÉLÈVE (pas le compte) | Sombre | Mobile | contenu seulement |

Sources : MANIFESTE §1 ; routes vérifiées dans `CODE lib/core/router/routes.dart` (lignes citées plus bas) ; route du détail d'observation tranchée en DÉCISIONS §3.9.

Les anciennes captures #29 à #33 ne servent qu'au **contenu et à l'ordre** des informations, jamais au rendu (MANDAT §2).

---

## 2. Écrans du rôle Tuteur sans AUCUNE maquette high-fi

Pour chaque écran : route exacte (constante du CODE), contenu attendu (MANDAT §4-§8 et MANDAT-OBS), états à dessiner, maquette la plus proche à imiter (MANIFESTE §2, MAPPING §7.2). Les états système communs (chargement, hors ligne, échec, etc.) sont détaillés une seule fois au §2.8 et s'appliquent à tous les écrans.

### 2.1 Public et admission

| Id | Route (CODE `routes.dart`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-01 | `/bienvenue` (`:35`) | Bienvenue | Titre, sous-titre, CTA « Commencer », lien secondaire « J'ai déjà un compte ». Les deux mènent à `/connexion` : c'est le lien envoyé par courriel qui crée le compte, pas de double création (MAPPING l.1). Remplace l'écran actuel qui affiche « Écran à construire ». | Nominal ; chargement prolongé | #17 (colonne centrée) + #22 (CTA ancré en bas, lien secondaire) |
| SM-02 | `/` (`app_router.dart:156-159`, `EcranDemarrage`) | Démarrage neutre | Écran affiché le temps de vérifier la session. Aucun texte de chantier. | Attente ; attente prolongée ; hors ligne au démarrage (texte existant : « Rewayah a besoin d'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez. », `fr.i18n.json:61`) | #22 |
| SM-03 | `/connexion` (`:15`) | Connexion | En production : **lien de connexion à usage unique par courriel** et **Google** seulement ; le mot de passe n'existe qu'en démonstration locale (`CODE lib/core/auth/service_auth.dart:12-24`). « Renvoyer le lien », état « lien expiré ou déjà utilisé », lien discret « accès appareil élève » vers `/connexion/eleve` (MAPPING l.2). | Saisie ; envoi en cours ; lien envoyé (attente) ; lien expiré ou déjà utilisé ; erreur sous le champ ; échec Google | #14 (champ encadré à étiquette, erreur sous le champ, CTA ancré) |
| SM-04 | `/connexion/recuperation` (`:32`) | Récupérer mon accès | Récupérer = redemander un lien (pas de mot de passe en production). | Saisie ; attente ; retour ; lien expiré ; erreur | #14 + #22 |
| SM-05 | `/inscription/identite` (`:49`) | Identité du titulaire | Texte existant : « Comment vous appelez-vous ? » ; « Ce nom doit être celui de votre pièce d'identité. » ; champs « Prénom », « Nom » (C03 §3.2). Préremplir ce que Google fournit déjà (MANDAT §6 « ne pas redemander sans raison » ; aujourd'hui rien n'est prérempli). | Vide (CTA désactivé) ; erreur sous chaque champ ; rempli | #14 : deux champs empilés, écart 12 dp |
| SM-06 | `/attente` (`:58`) | Portail du dossier | Quatre états calculés par le serveur : incomplet, en vérification, refusé (avec motif serveur), suspendu (C03 §3.3). Afficher le statut exact et **une seule** prochaine action. « Se déconnecter » accessible. Interdit : cartes empilées et jusqu'à 3 CTA pleins (MAPPING l.7 ; MANDAT §4 : « trop de CTA et trop de rectangles… à bannir »). « Contacter l'académie » reste non actionnable tant que DB-CPT-07 manque. | Incomplet (liste des pièces manquantes dans l'ordre accusé, contrat, pièce) ; en vérification ; refusé ; suspendu | #17 + #22 |
| SM-07 | `/attente/accuse` (`:64`) | À savoir avant de commencer | Deux points : notice d'enregistrement et notice de contrôle. **L'enregistrement audio est réel** : garder mot pour mot les clés `contrat.pointEnregistrement` et `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. » (DÉCISIONS §1 bis-2). Action « J'ai compris ». | Nominal ; envoi ; erreur | #23 (lignes icône + texte, CTA) |
| SM-08 | `/attente/contrat` (`:67`) | Ce que vous signez | Nouvelle version du texte signé = texte existant (notice d'enregistrement comprise) + paragraphe d'observation clair et bienveillant : qui peut observer, ce qu'il entend et voit, ce qu'il ne peut pas faire, pourquoi, limites de visites. Variantes « responsable légal » et « élève adulte ». Case **non précochée** (DÉCISIONS §1 bis-3 ; MANDAT-OBS §6). Seule la partie observation a une maquette (#23), avec un texte à corriger (voir §6). | Case non cochée (CTA désactivé) ; cochée ; envoi ; erreur ; variante responsable légal ; variante élève adulte | #23 |
| SM-09 | `/attente/piece` (`:70`) | Votre pièce d'identité | Choix du type (Carte d'identité, Passeport, Titre de séjour, Autre), « Choisir la photo », aperçu, « Envoyer ma pièce », plafond 8 Mo vérifié avant envoi (C03 §3.3). Jamais confondue avec le portrait de l'élève. | Aucun fichier ; aperçu ; envoi avec progression ; fichier trop lourd ; échec avec reprise ; envoyé | Cartes de choix #12 + champ #14 |
| SM-10 | `/tuteur/parcours/:eleveId` (`:159-165`) | Questionnaire pédagogique, par élève nommé | Sept étapes existantes (C03 §3.5), prénom de l'élève dans chaque question : 1) âge par **tranche** fournie par le serveur ; 2) langue **du cours** (pas celle de l'application) ; 3) lieu, pour l'heure locale ; 4) niveau (« Où en est {prénom} aujourd'hui ? », 5 réponses) ; 5) objectif ; 6) moments de la journée ; 7) horaires ou classes proposés. Branches débutant / non-débutant selon les règles rendues par le serveur, aucun code interne (MANDAT §6). En production le serveur de ce questionnaire n'est pas déployé : état indisponible honnête (MAPPING l.6, DB-ADM-01). | Chaque étape vide / remplie / erreur ; « n sur N » calculé selon la branche ; reprise ; indisponible ; aucune proposition compatible (« Aucun horaire ouvert ne correspond encore », avec « Me prévenir si de nouveaux horaires ouvrent ») | Étapes 1 et 5 : #14 et #16 existent mais sont en conflit (voir §6) ; étapes 2, 3, 4, 6, 7 : lignes de choix #15 / #16 |

Remarques admission :
- CONFLIT à ne pas trancher en silence : le high-fi #14 demande un âge exact (« 28 ans ») alors que le code propose des tranches serveur et que MANDAT §6 parle de cohortes 6-9, 10-13, 14-17, 18+ et de date de naissance (C03 §3.5, V6 E3, MANIFESTE §5 C13).
- CONFLIT : étape 7, classe réelle ou « offre horaire » (DÉCISIONS §2 P1 : défaut retenu « vraies classes », à confirmer par le directeur).
- La langue de l'application (#15) n'est pas une étape d'admission : elle relève des préférences (MANIFESTE §5 C14).

### 2.2 Accueil et Classe

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-11 | `/tuteur/notifications` (`:260`) | Notifications | Liste, détail, destination liée (MANDAT §4). Aucune source de notifications n'existe : en production, écran indisponible et **cloche sans pastille** (MAPPING l.9, DB-CPT-04). Pas de route de détail tant que la source manque (MAPPING §7.1). | Indisponible ; vide ; liste (non lues / lues) ; chargement ; erreur | Lignes de #25 + en-tête de #1 / #4 |
| SM-12 | `/tuteur/classes/catalogue?eleve=` (`:204`) | Choisir une classe | Une carte par classe : parcours, public ou niveau, langue, enseignant avec photo et Sayyid / Sayyida, **toutes** les séances de la semaine, durée, fuseau, places réelles. Confirmer la même classe et le même enseignant sur toute la semaine. Aucune réservation locale (MANDAT §5 Classe). En production : « le choix de classe en ligne n'est pas encore ouvert » (DÉCISIONS §2 P1). | Liste ; aucune classe compatible ; liste d'attente ; dernière place perdue ; confirmation refusée ; confirmation en cours ; confirmée ; indisponible | Carte classe de #1 (colonne gauche) + cartes de choix #12 |
| SM-13 | `/tuteur/classes/:classeId/planning` (`routes.dart:216-225`) | Planning | Tous les jours récurrents de la classe, même enseignant, heure locale, durée, **fuseau explicite** ; exceptions datées (annulée, reportée, absence d'enseignant, remplacement) jamais présentées comme un cours normal. Aucun décalage UTC fixe (MANDAT §5 Classe). Le service du planning complet n'existe pas : le créneau connu s'affiche dans le fuseau de la classe avec un libellé explicite (MAPPING l.27, DB-CRS-03 à 06). | Planning ; exception annulée ; reportée ; remplacement ; indisponible ; vide | Lignes de #25 |
| SM-14 | `/tuteur/classes/:classeId/travail` | Travail à préparer | Consignes, détails, supports, statuts. « Marquer fait » n'atteste aucune maîtrise (FINANCE l.12) et n'existe pas côté serveur (DB-CRS-10) : aucune coche locale. | Liste complète (sans la limite de 3 de l'Accueil) ; vide ; indisponible | Liste de tâches à cercles de #1 / #4 |
| SM-15 | `/tuteur/classes/:classeId/ressources` | Bibliothèque | Ressources autorisées, ouverture dans le lecteur existant `/tc/bibliotheque/:resourceId`. Aucun lecteur PDF (MAPPING l.29). | Liste ; vide ; ressource retirée ; erreur | Lignes de #6 + carte du support de #20 / #24 |
| SM-16 | `/tuteur/classes/:classeId/progression` | Progression | Séances et présences réelles, observations partageables. Jamais les comptes rendus internes des enseignants (MAPPING l.30, DB-CRS-11, DB-TRV-02). | Contenu ; vide ; indisponible | Ligne « Dernière séance » de #1 + lignes de #6 |

La Classe elle-même (`/tuteur/classes/:classeId`) a une maquette mobile claire (#18) : ses variantes manquantes sont au §3, ses états d'observation au §4.

### 2.3 Foyer et fiche élève (aucune maquette high-fi : seulement les anciennes captures #30 et #33 pour le contenu)

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-17 | `/tuteur/foyer` (`:102`) | Foyer | Titre « Foyer », description courte si utile, action « Ajouter un profil élève » (vers `/tuteur/foyer/ajouter`), une carte groupée des membres (avatar ou initiale, prénom, classe ou « inscription en cours », statut d'accès en texte, chevron vers la fiche), section « Appareils partagés » (ligne vers `/tuteur/foyer/appareils`), option discrète « Créer mon profil élève » tant que ce profil n'existe pas. Pas de compteurs décoratifs, pas de CTA doublon (MANDAT §5 Foyer ; LOTS B-1). | Foyer vide (aucun profil) ; un profil ; plusieurs profils ; profil du titulaire présent ; chargement ; erreur | Contenu #30 ; rendu : lignes de #5 / #6 + avatars du sélecteur de #1 / #4 |
| SM-18 | `/tuteur/foyer/ajouter` (`:110`), `?pour=moi` (`:119`) | Ajouter un profil élève | Parcours plein écran sans barre de navigation, retour 48 dp. Même flux depuis Accueil, Foyer et Compte. Choix « pour un enfant ou mineur » disponible ; « proche adulte » et « moi-même » visibles mais indisponibles et expliqués (DB-FOY-01, DB-FOY-02). Champs existants : prénom, nom, âge entier de 3 à 18 ans (constante du client ; C03 §3.4). Enchaînement vers la fiche puis le questionnaire. Refusé tant que le dossier du titulaire n'est pas validé (DB-ADM-04). **Le directeur annonce une refonte de ce parcours** (voir §5). | Formulaire vide ; erreurs sous les champs ; envoi ; création incertaine (réponse perdue) ; succès ; option indisponible expliquée ; dossier non validé | Gabarit d'étape de #12 / #14 |
| SM-19 | `/tuteur/foyer/:eleveId` (`:126`) | Fiche élève | En-tête : photo, prénom, âge si disponible, classe ou état d'inscription. Puis une carte groupée de six lignes, dans l'ordre du CODE (`routes.dart:134-141`) : Informations, Parcours et inscription, Interface, Caméra en cours, Accès Rewayah, Appareils. Onglet actif : **Foyer**. **Place réservée à un futur solde par élève** (DÉCISIONS §1 ter-9). | Nominal ; élève sans classe ; accès expiré ; identifiant inconnu (« introuvable ») ; chargement | Contenu #33 ; rendu : carte d'identité + groupes de lignes de #5 / #6 |
| SM-20 | `.../informations` | Informations de l'élève | Prénom et nom affichés, non modifiables (DB-FOY-07) ; date de naissance absente du serveur (DB-ADM-05) ; photo : choisir, aperçu, envoi, progression, échec avec reprise. Portrait jamais mélangé avec une pièce d'identité. | Sans photo ; aperçu ; envoi ; échec ; photo enregistrée | Lignes de #6 + champs #14 |
| SM-21 | `.../inscription` | Parcours et inscription | Synthèse : questionnaire, dossier, choix de classe, attente ; liens vers `/tuteur/parcours/:eleveId` et le catalogue. | Questionnaire à faire ; en attente ; inscrit ; indisponible | Récapitulatif #17 + lignes de #6 |
| SM-22 | `.../interface` | Interface | « Interface guidée » ou interface standard selon la politique réelle ; demande d'interface standard par l'élève à partir de 10 ans seulement si confirmée (DB-FOY-04). Aucune bascule qui élève les droits (MANDAT §5 Fiche). | Guidée active ; standard active ; demande en attente ; indisponible | Cartes d'option à radio de #9 |
| SM-23 | `.../camera` | Caméra en cours | Autorisation métier de la caméra de l'élève pendant les séances ; l'effet s'applique à la séance suivante ; confirmation avant changement. Distincte de la permission caméra du scanner QR (MAPPING l.16). | Autorisée ; non autorisée ; confirmation ; enregistrement ; erreur | Lignes à interrupteur de #9 |
| SM-24 | `.../acces` | Accès Rewayah | Statut, dates réelles, « expiré » si la date est passée, motif seulement s'il est fourni (DB-FOY-05). | Actif ; expiré ; sans date ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-25 | `.../appareils` | Appareils de l'élève | Appareils associés, action « Connecter un appareil » (vers l'émetteur QR), retrait avec confirmation et réponse du service. Dire que le retrait ne ferme pas une session déjà ouverte (DB-APP-03). Aucune limite d'appareils codée en dur. | Liste ; vide ; confirmation de retrait ; retrait en cours ; retiré ; échec | Contenu #33 ; rendu : lignes de #6 + pastille |
| SM-26 | `/tuteur/foyer/appareils` (`:123`) | Appareils du foyer | Nom de l'appareil, profils autorisés, gestion. Un appareil partagé n'est pas encore représentable côté serveur (DB-APP-05). Aucun « 1/2 » ni « un seul en cours à la fois » (MAPPING l.19). | Liste ; vide ; indisponible | Lignes de #6 |
| SM-27 | `/tuteur/foyer/ajouter?pour=moi` | Créer mon profil élève (indisponible) | Écran honnête : la création du profil élève du titulaire n'existe pas encore (DB-FOY-01). Même écran depuis Foyer et Compte. | Indisponible | #22 |

### 2.4 Appareils (parcours des deux côtés, MANDAT §7)

Sens existant, vérifié : **le téléphone du tuteur AFFICHE le QR, l'appareil de l'élève, sans session, le LIT** (LOTS D ; MAPPING §2).

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-28 | `/tuteur/foyer/appairer/:eleveId` (`:147-150`) | Connecter un appareil (émetteur) | Grand QR **noir sur fond blanc dans les deux thèmes**, marges libres, code manuel lisible, consigne « Sur l'autre appareil », durée de validité réelle. Dès la confirmation du serveur, QR ET code retirés de l'écran, puis « Appareil connecté ». Aucune décoration sur les modules du QR (MANDAT §7). | Préparation ; actif ; validation en cours ; association confirmée ; expiré ; remplacé ou révoqué ; erreur ; réseau interrompu | #22 (colonne centrée) |
| SM-29 | `/connexion/eleve/scanner` (`:26`) | Scanner le QR code (appareil élève) | Mobile : viseur plein écran, retour 48 dp, « Saisir le code ». Ordinateur et tablette : panneau centré, jamais une feuille mobile étirée. Jamais ouvrir une URL contenue dans un QR. Sur Windows et Linux : pas de bouton scanner (MAPPING l.21). | Demande d'autorisation ; refus ; refus durable ; caméra occupée ; caméra absente ; navigateur sans caméra ; erreur de démarrage ; lecture en cours ; succès ; QR inconnu ; expiré ; déjà utilisé ; révoqué | #20 (plein cadre sombre) ; #24 (version ordinateur centrée) |
| SM-30 | `/connexion/eleve/code` (`:29`) | Saisir le code | Champ unique de 6 caractères (format serveur `^[2-9A-HJ-NP-Z]{6}$`, MAPPING l.21), chiffres tabulaires. Refus différenciés : inconnu, expiré, déjà utilisé, révoqué (DB-APP-06). | Vide ; saisie ; erreur sous le champ ; validation ; succès | #14 |
| SM-31 | `/connexion/eleve` (`:21`), état « choix du profil » | Choisir mon profil (appareil partagé) | Grille à deux colonnes d'avatars des profils autorisés, repli en une colonne à 200 % de texte ; « J'ai un nouveau code ». Aucun accès au compte du tuteur. | Un profil ; plusieurs profils ; aucun profil | Grille de #11 / #13 + avatars du sélecteur |
| SM-32 | `/connexion/eleve`, états « code personnel » | Créer / entrer mon code PIN | Création puis saisie du code personnel ; le code ne quitte jamais l'appareil ; erreurs du pavé visibles ; récupération = le tuteur retire l'appareil et le reconnecte (MAPPING l.24). | Création ; confirmation ; saisie ; erreur ; trop d'essais (à vérifier : règle non relevée) | #14 |

À vérifier : le registre de langue des écrans SM-29 à SM-32, vus par l'élève (tutoiement de l'Interface guidée pour un enfant, vouvoiement pour un adulte) n'est tranché dans aucune source lue.

### 2.5 Historique

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-33 | `/tuteur/seances/:seanceId` (`:185-188`) | Détail de la séance | Identité de la séance (classe, date, heure avec fuseau, enseignant), présence et durée, résumé destiné à la famille (DB-CRS-12), travail et ressources autorisés. Distinguer durée du cours et temps connecté si les deux existent (DB-HIS-03). « En cours de vérification » pour une présence incertaine. Réseau seulement si mesuré. Jamais de notes internes, coordonnées privées ou télémétrie brute (MANDAT §5 Historique). | Présent ; absent validé ; retard validé ; en cours de vérification ; séance annulée ; identifiant inconnu ; résumé indisponible | #27 (détail d'observation) |

### 2.6 Mon compte : sous-pages

| Id | Route (CODE `routes.dart:233-257`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-34 | `/tuteur/compte/informations` | Informations personnelles | Identité et coordonnées du titulaire. Modification impossible côté serveur (DB-CPT-01) : lecture seule honnête. Le fuseau lu par le serveur retombe sur Europe/Paris par défaut : ne pas le présenter comme un choix (MAPPING l.35). | Lecture ; donnée absente ; indisponible pour modification | Carte d'identité et lignes de #5 / #6 + champs #14 |
| SM-35 | `/tuteur/compte/securite` | Connexion et sécurité | Méthodes réelles du compte (lien à usage unique, Google), adresse courriel, sessions actives (DB-CPT-02), déconnexion. Aucun écran de mot de passe en production. | Nominal ; sessions indisponibles ; confirmation de déconnexion | Carte « Sécurité et connexion » de #5 / #6 (titre à corriger) |
| SM-36 | `/tuteur/compte/acces` | Accès (titre à trancher) | Bénéficiaires, accès et échéances réels. Accès offert, accès daté et paiement externe validé ne sont pas un abonnement récurrent (MANDAT §5 Mon compte). CONFLIT de titre : MANDAT §4 « Abonnement et accès » contre MAPPING l.37 « jamais « abonnement » ». | Actif ; expiré ; suspendu ; offert ; en attente ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-37 | `/tuteur/compte/paiements` | Paiements | Historique réel, détail, justificatif disponible ; montants, devises, statuts et dates fournis seulement. Aucun service en production (DB-CPT-03) : indisponible. « Moyen de paiement » masqué ou indisponible ; une seule entrée vers cette page. **Place réservée à la recharge et au solde par élève** (DÉCISIONS §1 ter-9). | Indisponible ; vide ; liste ; détail | Liste de #25 + détail de #27 |
| SM-38 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Langue et région | Langue de l'interface : seul le français est traduit (l'arabe compte 32 lignes contre 2 208), donc « Français » en lecture seule (MAPPING §7.1 l.39, DB-CPT-10). Fuseau en libellé humain (ville), jamais un identifiant technique brut ni un décalage fixe (V4 fiche 01). | Nominal ; fuseau indisponible | Lignes à radio de #9 |
| SM-39 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Notifications | Seulement les réglages qui ont un effet réel ; les interrupteurs sans effet sont retirés ou câblés (MAPPING l.39). | Nominal ; indisponible | Lignes à interrupteur de #9 |
| SM-40 | sous-page de `/tuteur/compte/preferences` (à créer ou ligne informative) | Taille du texte ; Cours et données | « Taille du texte » suit le réglage du système (pas d'impasse derrière un chevron). Les réglages existants « Cours et données » (économie de données, lecture agrandie du Coran) sont à préserver (V4 fiche 01). | Nominal | Lignes de #9 |
| SM-41 | `/tuteur/compte/aide` | Aide et support | Aide, contact disponible, suivi si existant. Canal de contact à fournir par le directeur (DB-CPT-07) : indisponible sinon. | Indisponible ; contenu | Lignes de #5 / #6 |
| SM-42 | `/tuteur/compte/informations-legales` | Informations légales | Documents réellement disponibles ; acceptations déjà signées lisibles ; « Document non disponible » sinon (DB-CPT-08). | Liste ; document indisponible | Lignes de #5 / #6 |
| SM-43 | `/tuteur/compte/consentements` (`:256-257`) | Consentement aux visites d'observation (comptes existants) | Lit les acceptations, propose la nouvelle version ; aucun compte considéré comme ayant accepté (DÉCISIONS §2 P2 ; MAPPING §4 C2). | Non accepté ; accepté ; envoi ; erreur | #23 |
| SM-44 | dialogue depuis `/tuteur/compte` | Confirmation de déconnexion | Déconnexion clairement séparée des autres rubriques, avec confirmation (LOTS E-1). | Ouvert ; déconnexion en cours | Aucune ; surface modale de bureau du CODE (commit `42feded`) |

### 2.7 Pages transversales

| Id | Route (CODE) | Écran | Contenu attendu | Maquette la plus proche |
|---|---|---|---|---|
| SM-45 | `errorBuilder` (`app_router.dart:154`) | Page introuvable | Titre humain, phrase utile, action principale, lien secondaire. Texte existant : « Cette page est introuvable » / « Le lien est peut-être incomplet, ou la page n'existe plus. » (`fr.i18n.json:28-31`) | #22 |
| SM-46 | redirection + notice | Accès refusé | « Vous n'avez pas accès à cette page » / « Ce contenu n'est pas ouvert à votre compte. » (`:32-35`) ; retour sûr, sans fuite de données | #22 |
| SM-47 | `/connexion?retour=<chemin validé>` | Session expirée | « Votre session a expiré » / « Reconnectez-vous pour continuer. » (`:36-39`) ; retour vers la destination autorisée, sans boucle | #22 |
| SM-48 | aucune (hors production seulement) | Mode démonstration | Repère discret « Démonstration » et sélecteur de rôle ; données fictives, aucun appel serveur ; impossible en production (DÉCISIONS §1 bis-1, §1 ter-6, §1 quater). À vérifier : aucun fichier dédié trouvé dans le CODE à `cefab7f`. | Aucune |

### 2.8 États système communs à tous les écrans

Composant du CODE : `lib/core/widgets/etat_systeme.dart:19-66`, deux portées : **bloc** (le reste de la page reste en place) ou **page** (grammaire de l'écran résultat #22). Textes existants (`fr.i18n.json:11-70`) :

| État | Titre existant | Phrase existante | À dessiner |
|---|---|---|---|
| Chargement initial | - | - | Squelette de la carte, mêmes dimensions (MANIFESTE §6.3) |
| Chargement prolongé | « La connexion prend plus de temps que prévu » | « Vous pouvez patienter encore un peu ou réessayer. » | bloc et page |
| Hors ligne | « Vous êtes hors ligne » | « Vérifiez votre connexion. Ce qui est déjà affiché reste consultable. » | bandeau et page |
| Reconnexion | « Reconnexion en cours » | « Une nouvelle tentative de connexion est en cours. » | bandeau discret |
| Échec serveur | « Impossible de charger ces informations » | « Le chargement n'a pas abouti. Réessayez dans un instant. » | bloc (la carte garde son cadre + « Réessayer ») et page |
| Dossier en attente | « Votre dossier est en attente » | « Une étape reste à franchir avant d'ouvrir cet espace. » | page |
| Aucun résultat | « Aucun résultat » | « Rien ne correspond pour le moment. » | bloc, avec « Réinitialiser les filtres » |
| Autorisation refusée | « Autorisation refusée » | « Sans cette autorisation, cette fonction ne peut pas s'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil. » | page, avec alternative (code manuel) |
| Ressource expirée | « Ce contenu n'est plus disponible » | « Il a été retiré, ou son accès a pris fin. » | page |
| Indisponible | « Pas encore disponible » | « Cette fonction n'est pas encore ouverte. » | bloc et page, sans « Réessayer » |

ChatGPT peut proposer de meilleurs textes (marqués PROPOSITION), en gardant un seul texte par état pour toute l'application.

---

## 3. Écrans qui ont une maquette, mais seulement dans un thème ou un format

Formats exigés en recette : 390 × 844 et 1440 × 900, clair et sombre (LOTS §0) ; tablette 768 dans le prompt ChatGPT. Source : MANIFESTE §6.1, complété par V3, V4, V8.

| Écran | Route | Existe | Manque | Règle de composition du manquant |
|---|---|---|---|---|
| Accueil | `/tuteur` | Mobile clair #4 ; ordinateur clair #1 ; tablette sombre #2 ; ordinateur étroit sombre #3 | **Mobile sombre** ; tablette claire | Composition de #4, couleurs de #3 (MANIFESTE §6.3) |
| Mon compte | `/tuteur/compte` | Ordinateur clair #5 ; mobile clair #6 ; mobile sombre #7 | **Ordinateur sombre** ; tablette | Composition de #5, couleurs de #7 |
| Réglages (hub des préférences) | `/tuteur/compte/preferences` | Mobile sombre #8 | **Clair** ; ordinateur ; tablette (colonne de 760 dp) | Un seul groupe à filets au lieu de quatre cartes (V4) |
| Apparence | `/tuteur/compte/preferences/apparence` | Mobile sombre #9 | **Clair** ; ordinateur ; tablette | Composition de #9 ; indice de rendu clair dans ses miniatures |
| Admission : usage, genre, âge, langue, objectif, récapitulatif | `/inscription/*`, `/tuteur/parcours/:eleveId` | Mobile sombre #10 à #17 | **Clair** ; ordinateur et tablette (colonne centrée de 480 à 560 dp, CTA en bas de colonne) | Gabarit d'étape de V6 ; CTA en pilule réservé à l'admission (DÉCISIONS §3.2) |
| Classe + bloc Observation | `/tuteur/classes/:classeId` | Mobile clair #18 | Sombre ; **ordinateur et tablette** | Deux colonnes de #1 : carte séance à gauche (enseignant avec photo, prochaine séance, « Observer la séance », visites disponibles, « Comment ça marche ? »), lignes Planning, Travail, Bibliothèque, Progression, Historique à droite |
| Explication de première utilisation | étape de `/tc/observation/:seanceId` | Mobile clair #19 | Sombre ; ordinateur (colonne centrée ou dialogue) | Pas de feuille étirée |
| Fin de visite | retour classe | Mobile clair #22 | Sombre ; ordinateur ; variantes de fin (voir §4) | Écran résultat |
| Consentement observation | `/attente/contrat`, `/tuteur/compte/consentements` | Mobile clair #23 | Sombre ; ordinateur | Colonne centrée |
| Salle d'observation | `/tc/observation/:seanceId` | Mobile sombre #20 ; mobile clair #21 ; ordinateur clair #24 | Ordinateur sombre ; **mobile paysage** ; tablette ; **et refonte de l'en-tête pour tous les formats** (voir §4.3) | Un seul style de barre de commandes par format |
| Historique | `/tuteur/suivi` et `/tuteur/suivi/observations` | Mobile sombre #25 (segment Observations seulement) | **Clair** ; **ordinateur** ; **segment Séances** (contenu de #31) ; vide ; filtré sans résultat | Composition de #25 ; ordinateur : liste limitée à la largeur de lecture, rail de #1 |
| Détail d'une observation | `/tuteur/seances/:seanceId/observations?eleve=` | Mobile clair #27 | Sombre ; ordinateur ; motifs « Fin de séance » et « Interrompue » | Même ligne de visite que #27 |
| Historique des observations, administration | `/admin/securite-audit/observations` | Ordinateur clair #26 | Sombre (rôle administration, hors tuteur) | Navigation admin existante, pas la barre latérale de #26 |

États absents des maquettes existantes, à dessiner avec les mêmes compositions (V1 §6, V2 §8, V3 n°22, V6) :
- **Accueil** : vide (première inscription ou ajout de profil, jamais une fausse classe) ; chargement ; erreur de bloc ; hors ligne ; avant ouverture de la salle ; salle ouverte (fenêtre donnée par le serveur, en général 20 minutes avant) ; séance en direct ; séance prolongée « Séance toujours en direct » sans compteur négatif (DÉCISIONS §3.7) ; terminée ; annulée ; reportée ; changement d'heure ; horaire incertain sans horloge serveur (état `horaireIncertain` du contrat K2, MAPPING §7.1) ; présence « En cours de vérification » ; profil du titulaire dans le sélecteur (jamais appelé « enfant ») ; photo de l'enseignant (absente de #1 à #4).
- **Mon compte** : rubriques absentes de #5 à #7 : Préférences (engrenage muet), Informations légales, « Créer mon profil élève », ligne Foyer, déconnexion séparée avec confirmation (V3 n°9 ; MAPPING §7.1) ; place pour le futur solde ; chargement, erreur, hors ligne.
- **Admission** : état initial vide sur chaque étape (CTA désactivé ou erreur sous le groupe) ; lien discret « Je suis enseignant » sous les cartes d'usage (DÉCISIONS §3.8) ; raison de la question du genre en sous-titre ; correction par ligne au récapitulatif ; double soumission bloquée.

---

## 4. Planche 3 manquante : « États particuliers et notices de présence »

Fait : MANDAT-OBS §2 annonce trois planches ; la planche 3 est **introuvable** dans le dossier des maquettes (MANIFESTE §1 l.79-80 ; V8 §5 ; DÉCISIONS §2 P10, demandée au directeur). À produire par ChatGPT.

### 4.1 Règles d'observation qui fixent le contenu (priment sur toutes les maquettes)

- Par défaut : 2 visites maximum par séance, 120 secondes maximum par visite, 240 secondes au total, jamais une visite unique de 4 minutes ; valeurs configurables par l'administration, l'écran lit la politique effective (MANDAT-OBS §4).
- Quota **par parent** (par compte observateur), 2 visites par séance quel que soit le nombre de ses enfants dans la salle ; **une visite écourtée est consommée** (DÉCISIONS §1 bis-4).
- Observation possible seulement si l'enfant est présent. Ne pas confondre caméra désactivée, coupure temporaire et absence. Présence incertaine = vérification, jamais une absence inventée (MANDAT-OBS §4).
- Le tuteur entend l'enseignant et les élèves dont le micro est actif, voit le support partagé, l'enseignant et son propre enfant ; il n'a ni micro, ni caméra, ni chat, ni réactions, ni annotations, ni liste des autres élèves (MANDAT-OBS §4).
- Le compteur ne démarre qu'à l'entrée confirmée, jamais pendant l'explication ou la vérification (MANDAT-OBS §5). Une reconnexion ne simule pas du direct et ne remet pas le compteur à zéro (MANDAT-OBS §7).
- En production, l'observation réelle reste fermée (interrupteur `OBSERVATION_TUTEUR_REELLE` à faux, DÉCISIONS §2 P3) : le bloc affiche un motif « pas encore ouverte ». Le parcours complet se montre en démonstration.

### 4.2 États à dessiner, par emplacement (MANIFESTE §6.3 ; V7 §4 et §6 ; LOTS O-3)

| Emplacement | État | Texte existant dans le CODE (`fr.i18n.json`) | Remarque |
|---|---|---|---|
| Bloc Observation de la Classe (#18) | 2 visites disponibles | aucun (« 2 visites disponibles • 2 min par visite » sur #18, valeurs illustratives) | Nombre et durée lus dans la politique |
| idem | 1 visite restante | aucun | Accord au singulier |
| idem | Visites épuisées | `refus.quotaVisites` « Vous avez déjà utilisé vos visites pour cette séance. » (`:2221`) ; `refus.tempsEpuise` (`:2222`) | CTA retiré ou désactivé avec motif |
| idem | Enfant absent | aucun texte dédié | Seulement sur présence validée |
| idem | Présence en cours de vérification | aucun | Troisième issue absente du logigramme #28 (V7 §6) |
| idem | Séance non commencée | `refus.seanceNonActive` « La séance n'est pas en cours. » (`:2224`) ; `refus.horsFenetre` (`:2225`) | |
| idem | Séance terminée | aucun texte de refus dédié | |
| idem | Observation désactivée pour cette classe | `refus.politiqueDesactivee` « L'observation est désactivée pour ce groupe. » (`:2220`) | Texte à corriger : « classe », jamais « groupe » à l'écran (BACKLOG, réponses du directeur) |
| idem | Tuteur non rattaché à un élève de la séance | `refus.lienTuteur` (`:2223`) | |
| idem | Observation pas encore activée (production) | `refus.capaciteAbsente` (`:2227`) | |
| idem | Lien « Comment ça marche ? » toujours visible | - | Même après la première utilisation (V7 §6) |
| Avant la salle (#19 et suivant) | Explication de première utilisation | `entree.tuteurIntro` (`:2207`), à remplacer par le texte de MANDAT-OBS §6 complété par la règle « visite écourtée consommée » | Compteur arrêté ; « Pas maintenant » ramène à la classe |
| idem | Connexion et vérification | aucun | Compteur arrêté |
| idem | Connexion prolongée | texte commun « La connexion prend plus de temps que prévu » | Absent du logigramme (V7 §6) |
| idem | Connexion impossible | `refus.indisponible` (`:2226`) | « Réessayer » ; ne décrémente rien localement |
| idem | Annuler pendant l'explication ou la vérification | aucun | Retour sans consommer de visite (V7 §6) |
| Dans la salle (#20, #21, #24) | Reconnexion | `visite.budgetIncertain` « Temps restant non confirmé par le serveur. » (`:2237`) | Surimpression discrète, pas de faux direct |
| idem | Caméra de l'enfant désactivée | `visite.enfantAbsent` « Votre enfant n'a pas d'image ouverte. » (`:2236`) | Le nom de clé mélange absence et caméra (V7 §7.4) : le texte doit dire « caméra », pas « absent » |
| idem | Aucun support partagé | `visite.supportIndisponible` (`:2233`) | |
| idem | Vidéo de la séance non ouverte | `visite.videoIndisponible` (`:2238`) | |
| idem | Son reçu coupé / rétabli | - | Jamais par la couleur seule |
| idem | Sortie non confirmée | `visite.sortieNonConfirmee` (`:2239`) | |
| Fin de visite (variantes de #22) | Sortie volontaire | `fin.sortieVolontaire` (`:2244`) | Avec visites restantes réelles |
| idem | Durée de visite atteinte | `fin.quotaAtteint` « Votre temps d'observation est écoulé. » (`:2245`) | |
| idem | Fin de séance | `fin.seanceTerminee` (`:2246`) | |
| idem | Observation interrompue | `fin.revocationServeur` (`:2247`) ; `fin.deconnexion` (`:2248`) | |
| idem | Plus aucune visite | « Aucune visite restante pour cette séance » (DÉCISIONS §1 bis-5) | Lien « Voir mes observations » vers `/tuteur/suivi/observations` |

Les lignes `:22xx` renvoient à `CODE assets/i18n/fr.i18n.json` au commit `cefab7f`, dans le bloc `observation` (lignes 2204 à 2255).

### 4.3 Salle d'observation : décision du directeur qui change les maquettes existantes

DÉCISIONS §1 bis-5 : « visio moderne, épurée, très peu de boutons » ; **en haut, un bandeau pleine largeur** qui affiche le **décompte du temps restant seconde par seconde** et le **nombre de visites restantes** (« 1/2 visite restante pour cette séance », accord au pluriel, « Aucune visite restante pour cette séance » à 0) ; commandes : son reçu, agrandir le support, quitter.

Or #20, #21 et #24 placent « Visite 1/2 · 01:42 » dans une pastille de l'en-tête, sans bandeau, et montrent trois styles différents de barre de commandes et deux icônes « Quitter » (V8 M4). Conséquence : **la salle doit être redessinée** (en-tête et barre de commandes) en mobile portrait, mobile paysage, tablette et ordinateur, clair et sombre. Le reste de la composition (support dominant, deux vignettes secondaires qui ne couvrent jamais le support) est conservé. Le décompte tranche l'ambiguïté « décompte ou temps écoulé » relevée en MANIFESTE §5 C9.

### 4.4 Notices de présence (côté enseignant et côté enfant)

- Règle : l'enseignant et l'enfant concerné voient une notice discrète ; les autres élèves ne reçoivent rien ; « Votre maman… » seulement si le lien familial est connu, sinon « Votre parent… » (MANDAT-OBS §4).
- **Hors périmètre du chantier Tuteur** : à concevoir avec les rôles enseignant et élève (DÉCISIONS §1 bis-6). Elles relèvent donc de `02_CLASSE_ET_VISIO.md`, pas des écrans du tuteur.
- Textes existants à corriger (CODE `fr.i18n.json:2250-2255`) : côté enfant « Ton tuteur regarde le cours » (contredit la règle ci-dessus) ; côté enseignant « Tuteur de {prenomEnfant} observe », « {nombre} tuteurs observent ».

---

## 5. Fonctions du tuteur annoncées pour plus tard (DÉCISIONS §1 ter-9)

Texte exact de la décision : « À venir côté tuteur (ne pas construire, laisser la place) : recharge de solde, chaque enfant consomme son propre solde, parcours d'ajout d'un nouvel enfant revu. Les visuels viendront plus tard. Compte > Paiements et Foyer > fiche élève doivent pouvoir accueillir un solde par enfant sans refonte. »

| Fonction | Emplacement décidé | Faits qui encadrent la spec | État dans le CODE |
|---|---|---|---|
| Recharge de solde | Compte > Paiements (`/tuteur/compte/paiements`) | Paiement initial hors application, enregistré et validé manuellement ; pas de débit ni de versement inventé ; aucun prestataire unique imposé ; pas de dépendance permanente à un seul prestataire pour la diaspora (FINANCE §Finance l.20). Prix jamais écrits dans l'application ; valeurs anciennes 50 USD par mois, 90 USD pour deux, 40 USD par personne à partir de trois, **à confirmer** (FINANCE l.23). | Aucun écran, aucun contrat serveur (DB-CPT-03 pour les paiements) : CONTRAT À CRÉER |
| Solde par élève (« chaque enfant consomme son propre solde ») | Foyer > fiche élève (`/tuteur/foyer/:eleveId`) ; résumé possible dans Paiements (une seule fonction par endroit : la recharge dans Paiements, le solde de chaque élève dans sa fiche) | Registre de crédits immuable (attribution, réserve, consommation, libération, expiration, compensation, annulation) ; aucun solde corrigé par écrasement ; équivalence prix / temps à valider avant activation (ancien scénario 50 USD, 30 unités, 12 séances, non universel) ; absence de l'élève et cours assuré selon une politique versionnée ; absence d'enseignant sans remplacement = compensation (FINANCE l.25). | Aucun |
| Parcours d'ajout d'un nouvel enfant revu | `/tuteur/foyer/ajouter` (même flux depuis Accueil, Foyer, Compte) | Actuel : un écran, prénom, nom, âge 3 à 18 ans (C03 §3.4) ; serveur : création d'un profil mineur, âge 3 à 99, mode d'interface et caméra déduits de l'âge (C03 §3.4). Contraintes : cohortes 6-9, 10-13, 14-17, 18+ et date de naissance si confirmées (MANDAT §6 ; DB-ADM-05) ; proche adulte et profil du titulaire à prévoir (DB-FOY-01, DB-FOY-02) ; ajout seulement après validation du dossier (DB-ADM-04) ; idempotence (DB-FOY-06) ; enchaîner vers le questionnaire puis le choix de classe. | Écran réservé au lot B (STUB) |

Ces trois fonctions n'ont ni maquette ni visuel annoncé : ChatGPT les spécifie et les dessine en PROPOSITION, marquées « à venir, ne pas construire avant accord du directeur ».

---

## 6. Erreurs à ne pas reproduire, maquette par maquette

Une ligne par maquette (MANIFESTE §5 ; V1 à V9). Valable pour toutes : prénoms, dates, heures, durées, quotas, compteurs et noms de classe sont illustratifs et ne deviennent jamais des constantes (MANIFESTE §5 B) ; ne pas dessiner la barre d'état iOS ni les étiquettes de planche (MANIFESTE §5 G) ; cibles d'au moins 48 dp et contraste AA (MANIFESTE §5 E).

| # | Erreurs à ne pas reproduire |
|---|---|
| 1 | « Ajouter enfant » ; « Session 18:00 » ; « Adam / Absente » (accord faux, absence par la seule couleur) ; « Dernière séance 1 h » ambigu ; initiale de l'élève à la place de la photo de l'enseignant ; « Détails et connexion » (dire « Détails de la séance ») ; « Avant / Après la séance » (dire « Avant le prochain cours ») ; « Salle ouverte » à T-13 figé ; bascule de thème sans mode Système ; cadre arrondi sur fond lavande (mise en scène). |
| 2 | Mêmes erreurs de texte que #1 ; « 1 tâche + 2 autres activités » (afficher 3 tâches partout) ; « + » en pointillé (contour plein) ; rail replié sans infobulle ni étiquette pour le lecteur d'écran. |
| 3 | Mêmes erreurs de texte que #1 ; colonne droite en trait vertical au lieu d'une carte : un seul arbre d'écran, seul le format change la composition, jamais le thème (MANIFESTE §5 F). |
| 4 | Barre à 3 onglets (4 exigés) ; « Ajouter enfant » ; « Session dans 13 min » ; Mariam « En séance » dans le sélecteur mais « dans 13 min » dans la carte ; deux blocages simultanés (photo et appareil) ; « Réseau élève / enseignant Bon » ; dates incohérentes (lundi 21 et jeudi 18 septembre) ; carte « Dernière séance » cachée sous la barre ; accent lavande pâle illisible (2,8:1) ; bouton « Connecter un appareil » coupé sur deux lignes. |
| 5 | CTA dominant « Gérer les paiements » et doublons vers Paiements ; « Moyen de paiement » ; « Compte vérifié » sans statut serveur ; « Sécurité et connexion » (dire « Connexion et sécurité ») ; « Appareils connectés · 2 appareils » ; « disponibilités » ; téléphone affiché deux fois ; « Email et mot de passe » (méthodes réelles seulement) ; Préférences, Informations légales, « Créer mon profil élève » absents ; lignes d'« Aide et support » indentées ; contenu étiré sur 1096 dp. |
| 6 | Mêmes erreurs de contenu que #5 ; bande « Se déconnecter » trop basse (moins de 48 dp) ; légendes et textes verts sous AA. |
| 7 | Mêmes erreurs de contenu que #5 ; le nom du fichier dit « desktop » mais c'est un mobile ; apostrophes mélangées. |
| 8 | Quatre cartes séparées (un seul groupe à filets) ; « Français · Asia/Riyadh » en dur et identifiant de fuseau brut ; ligne « Sécurité » qui doublonne `.../securite` ; titre « Réglages » contre « Préférences » du mandat (à trancher, sans collision avec les réglages de l'élève) ; rubrique « Cours et données » supprimée. |
| 9 | « Appliqué sur cet appareil. » alors que le choix est perdu au rechargement sur le web ; « Taille du texte » avec chevron sans destination ; piste d'interrupteur désactivé à 1,77:1 ; légende rétrécie pour tenir sur une ligne ; marges de 8 dp au lieu de 16 dp. |
| 10 | Titre « Quel type de compte souhaitez-vous créer ? » (dire « Pour qui souhaitez-vous utiliser Rewayah ? ») ; « Moi et les membres de ma famille » (dire « Moi et ma famille ») ; descriptions à remplacer par celles du directeur ; promesse « les paiements » ; option présélectionnée ; « 2 sur 5 » en dur ; pas de lien enseignant ; artefact « per sonne ». |
| 11 | « Homme » présélectionné ; « Sélectionnez une option. » à la place de la raison de la question ; « 3 sur 5 » et barre à 54 % pour 3/5 ; pictogramme féminin à faire arbitrer par le directeur. |
| 12 | « Pour qui créez-vous ce compte ? » ; descriptions différentes du texte imposé ; promesse « les paiements de la famille » ; aucune entrée enseignant ; option présélectionnée ; « 1 sur 6 » figé. |
| 13 | Pas de sous-titre expliquant la question ; pictogrammes genrés stéréotypés ; présélection ; étape « prénom, nom » absente mais obligatoire. |
| 14 | Âge exact libre « 28 ans » (CONFLIT avec les tranches serveur) ; aide « Pour adapter votre parcours. » plus vague que la raison réelle ; question au « vous » au lieu du prénom de l'élève. |
| 15 | Langue de l'application demandée dans l'admission (elle remplace à tort la langue du cours) ; English et العربية proposés alors qu'ils ne sont pas traduits ; icône « personne » pour une langue. |
| 16 | Options différentes du code (« Je ne sais pas encore » supprimée, « Apprendre les bases de l'islam » ajoutée sans parcours réel) ; question de niveau absente ; pastille sélectionnée d'une autre teinte que #12 et #15. |
| 17 | « Vos préférences sont prêtes. » (faux succès) ; un seul lien « Modifier mes réponses » au lieu d'une correction par ligne ; état du dossier et prochaine action réelle absents ; « 6 sur 6 » figé. |
| 18 | « Temps restant » ambigu (séance ou visite) ; « Avant / Après la séance » ; Bibliothèque, Progression et Historique absents de la liste ; « Niveau 1 » qui ressemble à un code interne ; CTA de 40 dp. |
| 19 | Coquille « quii » ; « 2 visites de 2 minutes » en dur ; texte du mandat incomplet (et règle « visite écourtée consommée » absente) ; « son enseignant » sans Sayyid / Sayyida. |
| 20 | Pastilles d'en-tête au lieu du bandeau pleine largeur décidé (§4.3) ; « 01:42 » ambigu ; kasra manquante sous ب ; chevron retour qui ne passe pas par « Quitter » ; barre de commandes verticale propre à cet écran. |
| 21 | Même en-tête que #20 ; barre de commandes horizontale différente de #20 et #24 ; même erreur d'arabe. |
| 22 | « une visite de 2 minutes » en dur ; seule la variante « première visite terminée » existe (les autres fins sont au §4.2). |
| 23 | Texte différent de celui exigé par MANDAT-OBS §6 ; seulement « pour mon enfant » (variantes responsable légal et élève adulte absentes) ; case et CTA de moins de 48 dp ; CTA désactivé trop peu contrasté. |
| 24 | ث remplacée par ت dans le support ; avatar générique à la place du portrait de l'enfant ; effet « elle parle » sans signal réel ; icône « Quitter » en combiné téléphonique (une seule icône partout) ; pas de bandeau pleine largeur. |
| 25 | « Ajouter enfant » ; « Session 18:00 » ; « Dernière séance 1 h » ; « Terminées » contre « Terminée » ; fuseau absent de la liste ; barre de navigation gris neutre `#4B4B4B` hors palette. |
| 26 | Barre latérale admin inventée (réutiliser la navigation admin existante) ; filtre « Statut » sans colonne correspondante ; filtres tuteur et élève seulement par la recherche ; ligne du 18/09 absente (jeu de démonstration incohérent avec #25). |
| 27 | Horaire « 18:35 – 18:36:42 » au format incohérent ; « Heure de Paris » ici contre « Europe/Paris » en #26 ; lien retour de 29 dp ; deux motifs de fin seulement ; libellé du CTA en violet au lieu de l'encre foncée. |
| 28 | Styles du logigramme (crème, brun, Segoe UI, pointillés) à ne jamais transformer en jetons ; « Deux minutes écoulées » en dur ; décision « disponible ? » binaire sans « présence en vérification » ; reconnexion qui revient au direct ; accès direct à la salle sans vérification. |
| 29 | Ancienne capture : barre à 3 onglets grise ; mêmes erreurs que #4 ; libellés d'onglets sous AA. |
| 30 | Ancienne capture : « Ajouter un enfant », « Enfants », « Gérer tous les enfants » ; compteurs décoratifs « 3 enfants / 1 appareil / 2 alertes » ; « 1/2 appareils » ; « Diagnostic à terminer » ; « Configure un appareil » ; « iPhone de Mariam » comme appareil familial ; « Disponibilités du foyer » ; rubans colorés ; « Créer mon profil élève » absent. |
| 31 | Ancienne capture : pas de bascule Séances / Observations ; dates et année 2024 fausses ; « Sayda », « Ustadh » ; trois classes et trois enseignants pour une élève ; réseau au premier plan ; « Absente » avec « Réseau Bon ». |
| 32 | Ancienne capture : « Observer la session » proposé avant le début et sans quota ; photo de l'enseignant absente ; décalage fixe Paris / Abidjan ; « 13 : 45 » avec espaces ; ressources, progression, historique et exceptions absents. |
| 33 | Ancienne capture : onglet actif « Compte » (c'est la fiche élève : Foyer) ; « Accés » ; « Paramètres de l'enfant » (dire « Réglages de {prénom} ») ; « Indisponible pendant la séance » sans politique établie ; « Appareil actuel » non confirmé ; Informations et Parcours absents. |

---

## 7. Synthèse : nouvelles images à produire pour le rôle Tuteur

PROPOSITION de volume et d'ordre (mon estimation, à valider par le directeur) : pour chaque écran du §2, une maquette mobile 390 × 844 clair et une ordinateur 1440 × 900 clair ; le sombre est dérivé par les règles de MANIFESTE §6.2, sauf pour les écrans où le sombre change la lecture (salle d'observation, émetteur QR).

| Ordre | Groupe | Écrans | Pourquoi d'abord |
|---|---|---|---|
| 1 | Foyer et fiche élève | SM-17 à SM-27 | Aucune maquette high-fi, seulement d'anciennes captures |
| 2 | Appareils | SM-28 à SM-32 | Aucune maquette ; parcours sur deux appareils |
| 3 | Planche 3 et salle redessinée | §4.2, §4.3 | Planche manquante ; décision du directeur contraire aux maquettes |
| 4 | Admission sans image | SM-01 à SM-10 | Écrans publics, premier contact |
| 5 | Classe (sous-pages, catalogue), Historique (détail de séance), Compte (sous-pages), Notifications | SM-11 à SM-16, SM-33 à SM-44 | Dérivations simples de maquettes proches |
| 6 | Variantes de thème et de format | §3 | Règles de dérivation déjà écrites |
| 7 | Fonctions à venir | §5 | Visuels annoncés « plus tard » par le directeur |

Points encore ouverts à signaler à ChatGPT comme CONFLIT, sans les trancher : âge exact ou tranches (§2.1) ; classe réelle ou offre horaire à l'étape 7 (§2.1) ; titre « Abonnement et accès » (SM-36) ; « Réglages » ou « Préférences » (#8) ; pictogramme féminin (#11) ; barre de progression continue ou segmentée et carte « Autre » de l'admission (MANIFESTE §6.4-8) ; registre de langue des écrans de l'appareil élève (§2.4).


---


# E. Inventaire des écrans des autres rôles

# Inventaire des écrans et des parcours, rôle par rôle (hors tuteur)

Date : 24/09/2026. Rédigé par Claude Code, en lecture seule, pour le dossier remis à ChatGPT.
Référence mesurée : dépôt `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (branche du chantier Tuteur V1, **non fusionnée** dans `main`). Aucun fichier du dépôt n'a été modifié.
Portée : tous les rôles **sauf le tuteur** (couvert par le chantier Tuteur V1). Un écran partagé avec le tuteur est cité quand il concerne un autre rôle.

---

## Comment lire ce document

- **Tu n'as pas accès au code.** Chaque fait porte sa preuve : `fichier:ligne` du dépôt, ou nom du document. Ces preuves servent aux agents qui coderont ; tu peux les citer, tu n'as pas à les vérifier. Ce qui n'est pas prouvé est écrit **« à vérifier »**.
- Une **route** est l'adresse interne d'un écran (exemple : `/eleve/coran`). Elle ne s'affiche jamais à l'utilisateur.
- Dans le code, une classe s'appelle souvent **« groupe »** (`groupe`, `/tc/groupes`, `ADM-09 Groupes`). À l'écran, le mot imposé est **« Classe »**. Ce document garde les noms du code entre accents graves et dit « classe » partout ailleurs.
- Les **codes d'écran** existants (`ELV-xx`, `ENS-xx`, `ADM-xx`, `CTR-xx`, `AGT-00`, `CPT-01`) viennent du catalogue d'écrans archivé. Réutilise-les. Un écran sans code est marqué « sans code » : propose-lui un identifiant.
- Trois lots du **chantier Tuteur en cours** construisent aussi des écrans partagés : **lot A** (bienvenue, connexion, récupération, inscription par étapes, dossier `/attente`), **lot D** (scanner et saisie du code sur l'appareil de l'élève), **lot E** (historique des observations côté administration). Ne les réécris pas : signale seulement leurs manques pour les autres rôles (`LOTS` §A, §D, §E).

### Légende des états du code

| État | Définition appliquée |
|---|---|
| **Atteignable** | Route déclarée, **et** au moins un bouton, lien, onglet ou la racine du rôle y mène dans le code (hors routeur, hors tests), **et** la garde d'accès laisse passer ce rôle. Ne veut **pas** dire « fonctionne » : la colonne dit ce qu'on voit. |
| **Atteignable (STUB)** | Atteignable, mais l'écran est un espace réservé provisoire qui affiche « indisponible » (commentaire `STUB PHASE 0` dans le fichier). |
| **Route sans bouton** | Route déclarée, mais aucun bouton ne mène le rôle visé : seule une adresse tapée (web) y mène, ou la garde refuse le seul rôle qui a le bouton. |
| **Code non branché** | Code présent mais monté par aucun écran atteignable (graphe d'imports), ou jamais instancié. |
| **Absent** | Ni route ni écran. |

### Abréviations des sources

| Code | Document |
|---|---|
| `00`, `01`, `02`, `03`, `06`, `07`, `08D` | `D:\RA _APP\RA -OFFICIAL-APP\docs\current\` : `00_LIRE_D_ABORD`, `01_PRODUIT_ET_PARCOURS`, `02_ARCHITECTURE_ET_SECURITE`, `03_DESIGN_SYSTEM_ET_UX`, `06_SPEC_FONCTIONNELLE_MVP`, `07_MEMOIRE_PEDAGOGIE_FINANCE`, `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23` |
| `CAT` | `docs\archive\2026-09-pre-remise-a-plat\design\08-catalogue-ecrans.md` (registre §1, fiches §6 et §7) |
| `AI` | `docs\archive\2026-09-pre-remise-a-plat\design\03-architecture-information.md` |
| `PU` | `docs\archive\2026-09-pre-remise-a-plat\produit\parcours-utilisateurs.md` |
| `DEC` | `D:\RA _APP\pilotage-tuteur-v1\03_DECISIONS_COORDINATEUR.md` (réponses du directeur du 24/09) |
| `BKL` | `D:\RA _APP\pilotage-tuteur-v1\08_BACKLOG_VAGUE_CLASSE_VISIO.md` |
| `DEP` | `D:\RA _APP\pilotage-tuteur-v1\02_code\00_DEPENDANCES_BACKEND.md` (identifiants `DB-xxx`) |
| `MAP` | `D:\RA _APP\pilotage-tuteur-v1\02_code\00_MAPPING_ROUTES.md` |
| `MAN` | `D:\RA _APP\pilotage-tuteur-v1\01_visuel\00_MANIFESTE.md` (numéros `#n` des maquettes) |
| `LOTS` | `D:\RA _APP\pilotage-tuteur-v1\05_LOTS_PHASE1.md` |
| `R4` | `D:\RA _APP\pilotage-tuteur-v1\06_registre\R4_annonce_vs_atteignable.md` (mesuré sur `main` @ `4a7aa2b`, revérifié ici sur `cefab7f`) |

### Méthode et limites

- Routes lues dans `lib/core/router/routes.dart`, `app_router.dart`, `redirection.dart` et les cinq fichiers `routes_tc_{a,b,c,e,g}.dart`. Destinations lues dans `lib/core/widgets/nav_shell.dart` et `lib/core/admin/admin_domaine.dart`.
- Entrées de navigation : recherche de `Routes.`, `CheminsTcA.`, `RoutesTcB.`, `RoutesTcE.`, `RoutesTcG.`, `RoutesCoran.` dans `lib/` hors routeur ; aucune navigation par adresse littérale (`.go('/...')`) n'existe.
- Graphe d'imports rejoué sur `cefab7f` avec `06_registre\outils\graphe_imports.ps1` (sortie hors dépôt) : 422 fichiers Dart dans `lib/`, **356 atteignables** depuis `lib/main.dart`, **66 non atteignables**.
- Lecture statique seulement : aucune application lancée, aucune base interrogée, aucune capture neuve. « Atteignable » ne dit rien de ce que le serveur accepte.

---

## 0. L'essentiel en 15 constats

1. **Six rôles techniques seulement** : `admin`, `accountant`, `controller`, `teacher`, `guardian`, `student` (`lib/core/domain/enums.dart:9-26`). « Élève adulte », « contrôleur invité » et « agent IA » ne sont pas des rôles de l'application (l'agent utilise un rôle de base `agent_ro`).
2. **Élève adulte : parcours absent de bout en bout.** Choisir « Élève adulte » à l'inscription crée un compte **tuteur** sans profil élève (`lib/features/inscription/inscription_page.dart:38-41`). L'adulte ne peut ni étudier, ni choisir une classe, ni rejoindre une séance (`DEP` DB-FOY-01).
3. **Élève en Interface guidée : aucune navigation, aucune déconnexion, et le lecteur du Coran n'a aucun retour visible** (0 destination, `nav_shell.dart:67-68, 312-314` ; aucun retour dans `lib/features/tc_mushaf/mushaf_page.dart` ni `lib/core/widgets/page_immersive.dart`). Impasse probable, **à vérifier sur appareil**.
4. **Pour l'élève, la classe n'existe pas à l'écran** : Espace Classe, bibliothèque, seconde salle et travail à préparer n'ont aucune entrée pour lui. Il ne voit que : accueil, Coran, suivi, compte, salle.
5. **Trois fenêtres d'entrée en séance différentes** : élève à l'heure exacte du début (`accueil_eleve_page.dart:103-107`), enseignant 10 minutes avant (`journee_page.dart:16-31`), serveur 20 minutes avant (`join_window_minutes = 20`, `DEP` §0 ligne 24) ; la spec demande environ T-20 configurable (`01` Espace Groupe).
6. **Enseignant** : ses écrans quotidiens sont atteignables, mais « Premiers pas » (`ENS-01`) n'a aucun bouton, « Journée » et « Créneaux » reposent encore sur l'ancien modèle « prendre un élève » que `00:26` a remplacé par le choix d'une classe stable, et il n'a ni Coran hors salle, ni bibliothèque, ni envoi de sa photo publique.
7. **Salle** : `/salle` est la salle vivante (élève, enseignant, contrôleur) ; `/tc/classe`, seconde salle plus riche, n'a aucune entrée. Décision du directeur : **une salle unique** (`BKL`). La page du Coran présentée par l'enseignant n'est reçue par **aucun** écran élève. Outils de classe, synchronisation en direct et reprise après coupure : code non branché. Le jeton vidéo serait refusé à tous les rôles par la migration `0042` (**à vérifier**, `DEP` DB-OBS-01).
8. **Administration** : 16 écrans atteignables (`ADM-01`, `ADM-02`, `ADM-04` à `ADM-17`), plus une feuille de réglage d'observation, répartis sur 8 domaines. Mais la création d'une classe demande l'**identifiant brut** de l'enseignant, n'accepte **qu'un jour et une heure**, fige le fuseau à `Europe/Paris`, sans durée ni date de début (`lib/features/admin_groupes/groupes_page.dart:415-421, 452`) ; les comptes sont en lecture seule ; aucun paiement manuel, aucune exception de planning, aucune observation de séance.
9. **Validation des dossiers (`ADM-02`)** : l'écran existe, avec « Valider le dossier » et « Refuser ». Il se bloque si le **genre de l'administrateur** n'est pas renseigné (« Renseignez votre genre dans votre profil avant de consulter un dossier. », `dossiers_page.dart:444`), et **aucun écran** ne permet de le renseigner (profil en lecture seule). Cause possible du « rôle enseignant inaccessible » rapporté par le directeur (`BKL` ligne 37) : **à vérifier en base**.
10. **Contrôleur** : planning et observation invisible atteignables ; compte rendu, grille d'audit (`CTR-03`) et signalement **absents**.
11. **Contrôleur invité** : rôle **inexistant** et **jamais spécifié** (seulement nommé dans `AI` §2 et `DEC` §1 ter-8).
12. **Finance et comptable** : `/comptable` affiche seulement « Mon compte » ; le domaine Finance de l'administration est inerte ; aucune table de paiement des familles (`DEP` DB-CPT-03).
13. **Publication impossible en l'état** : aucune suppression de compte, aucun document légal, aucune notification (ni push, ni e-mail applicatif), pas de lien profond mobile pour le lien de connexion, permission micro non déclarée (manifeste Android principal, `Info.plist` iOS), nom Android « rewayah_academy », traduction arabe quasi vide (32 lignes contre 2 366).
14. **Coran** : lecteur atteignable, défauts connus (ordre des versets inversé, voyelles absentes, mise en page non conforme au Mushaf de Médine, commandes manquantes) **consignés et non corrigés** par décision (`08D` §5 bis, 24/09).
15. **Maquettes hors tuteur** : seules existent les planches d'inscription (`MAN` #10 à #17), le consentement (`MAN` #23) et l'historique des observations côté administration (`MAN` #26). **Tout le reste : aucune maquette.**

---

## 1. Cadre commun à tous les rôles

### 1.1 Portes d'accès (ce que la garde décide avant tout écran)

| Porte (état de session) | Ce que voit la personne | Preuve |
|---|---|---|
| Chargement | Écran de démarrage neutre (`/`) | `redirection.dart:57-58` ; `etats_routeur.dart:125-137` |
| Hors ligne (profil illisible) | Page « hors ligne » seule | `redirection.dart:62-63` |
| Déconnecté | Seuls `/connexion` (et ses sous-pages), `/bienvenue`, `/agent` sont ouverts ; tout autre chemin renvoie à `/connexion?retour=...` | `routes.dart:528-532` ; `redirection.dart:71-91` |
| Inscription (compte sans profil) | Seul `/inscription` et ses sous-pages | `redirection.dart:97-100` |
| Attente ou suspendu | Seul `/attente` et ses sous-pages | `redirection.dart:106-110` |
| Actif | Racine du rôle ; `/compte` ouvert à tous ; `/tc/...` selon une table par sous-arbre ; une route d'un autre rôle renvoie à la racine (le tuteur seul voit « Accès refusé ») | `redirection.dart:112-195, 287-304` |

Racines par rôle : élève `/eleve`, tuteur `/tuteur`, enseignant `/enseignant/journee`, contrôleur `/controleur`, admin `/admin`, comptable `/comptable` (`routes.dart:535-542`).

### 1.2 Destinations de navigation par rôle (code actuel)

| Rôle | Destinations, dans l'ordre | Forme | Preuve |
|---|---|---|---|
| Élève, mode standard | Accueil · Coran · Suivi · Compte (4) | Barre basse < 600 ; rail à libellés 600-1199 ; barre latérale ≥ 1200 | `nav_shell.dart:66-90`. Écart : `AI` §5 et `PU` en prévoyaient 3 (sans Compte). |
| Élève, Interface guidée | Aucune (0) | Aucun chrome : l'écran occupe tout | `nav_shell.dart:67-68, 312-314` |
| Enseignant | Journée · Créneaux · Profil (3) | Idem, rail à libellés | `nav_shell.dart:128-144` |
| Contrôleur | Aucune (écran unique) | Pas de barre | `nav_shell.dart:155-157` ; `app_router.dart:737-741` |
| Comptable | Aucune | Pas de barre | `nav_shell.dart:155-157` |
| Administration | 8 domaines : Accueil · Opérations · Personnes · Pédagogie · Finance (inerte) · Configuration · Sécurité et audit · Direction (masqué) | Coquille propre `AdminShell` (barre latérale, tiroir sur mobile), barre supérieure : « Rechercher un écran », cloche, compte | `admin_domaine.dart:92-100, 118-128` ; `lib/core/widgets/admin_shell.dart` ; `session_state.dart:140` (`peutVoirDirection => false`) |

Règles déjà gelées par le directeur et valables pour tous les rôles (`DEC` §1 ter) : disposition des maquettes qui fait autorité, **une fonction à un seul endroit**, carte groupée = un seul rectangle à filets, navigation, retour et déconnexion toujours accessibles, web = vraie version ordinateur (captures 1440 obligatoires), système de design gelé (DM Sans pour les titres, Plus Jakarta Sans pour le reste), composants réutilisables pour tous les rôles, mode démonstration par rôle hors production.

### 1.3 Pages d'état transverses (déjà codées)

| Page | Route | État | Preuve |
|---|---|---|---|
| Démarrage | `/` | Atteignable | `app_router.dart:157-160` ; `etats_routeur.dart:125-137` |
| Page introuvable | toute adresse inconnue | Atteignable | `app_router.dart:154` ; `etats_routeur.dart:36-55` |
| Accès refusé | `/acces-refuse` | Atteignable **pour le tuteur seul** ; les autres rôles sont renvoyés en silence à leur racine | `redirection.dart:194` |
| Hors ligne du démarrage | `/hors-ligne` | Atteignable | `etats_routeur.dart:73-123` |

### 1.4 « Mon compte » commun (hors tuteur)

`/compte` (écran `ComptePage`) est partagé par l'élève, l'enseignant, le contrôleur, le comptable et l'administration. Le tuteur a son propre compte (`/tuteur/compte`).

| Écran | Route | Contenu actuel | État | Preuve |
|---|---|---|---|---|
| Mon compte | `/compte` | Carte d'identité (rôle), Profil, Réglages, « Confidentialité » (désactivé, « Bientôt disponible »), liste « Espaces », « Se déconnecter » | Atteignable (élève standard, enseignant via Profil, contrôleur, admin, comptable) | `compte_page.dart:30-117` |
| Profil | `/compte/profil` | Identifiant, contact « Non disponible », langue, fuseau « Non disponible », statut. **Lecture seule** | Atteignable depuis `/compte` | `compte_page.dart:59, 121-190` |
| Réglages | `/compte/reglages` | Thème (Système, Clair, Sombre), réduire animations et effets, langue (arabe « Bientôt disponible »), notifications (sans source), économie de données, grand texte du Coran. Préférences non conservées au redémarrage (`DEP` DB-CPT-09) | Atteignable depuis `/compte` | `compte_page.dart:65, 194-370` |
| Profils du foyer | `/compte/profils`, `/compte/profils/:id` | Réservé au tuteur, qui est redirigé vers son Foyer | Route sans bouton pour les autres rôles | `compte_page.dart:71, 648` ; `redirection.dart:246-254` |

---

## 2. Parcours publics et entrée dans l'application

**Destinations** : aucune (pas de coquille). Le visiteur sans session arrive sur `/connexion`, pas sur `/bienvenue` (`app_router.dart:196-199`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Bienvenue (sans code) | `/bienvenue` | Accueil public avant connexion | **Route sans bouton + STUB** (`lib/features/bienvenue/bienvenue_page.dart:6-21`) ; lot A | `LOTS` A.1 ; `MAN` §2 | Aucune (dérivation prévue : `MAN` §2) |
| `TUT-00` Connexion | `/connexion` | Recevoir un lien par courriel, ou « Continuer avec Google » ; aucun mot de passe | **Atteignable** (destination par défaut sans session). Refonte en cours, lot A | `CAT` §6 `TUT-00` ; `06` Identité | Aucune (captures de l'existant : `02_code\capture_proto\out\01` à `04_connexion_*.png`) |
| Récupération d'accès (sans code) | `/connexion/recuperation` | Recevoir un nouveau lien | **Route sans bouton + STUB** : aucun lien depuis `/connexion` (`recuperation_page.dart:6-21`) ; lot A | `06` « récupération de compte » ; `LOTS` A.1 | Aucune |
| `ELV-01` Connexion de l'élève | `/connexion/eleve` | Code d'appairage à 6 caractères, choix du profil, code personnel à 4 chiffres | **Atteignable** par « Connecter l'appareil d'un élève » (`connexion_page.dart:168`) ; bloc « Scanner » non affiché (`eleve_connexion_page.dart:331`) | `CAT` §6 `ELV-01` ; `PU` §2 | Aucune |
| Scanner le QR (sans code) | `/connexion/eleve/scanner` | Lire le QR affiché chez le tuteur | **Route sans bouton + STUB** ; lot D | `LOTS` D.2 | Aucune |
| Saisir le code (sans code) | `/connexion/eleve/code` | Saisie manuelle du code | **Route sans bouton + STUB** ; lot D | `LOTS` D.2 | Aucune |
| `TUT-00c` Création de profil | `/inscription` | 4 pages : rôle (« Tuteur », « Élève adulte », « Enseignant »), prénom et nom, genre, récapitulatif | **Atteignable** par la porte « inscription » (`inscription_page.dart:25-173`) | `CAT` §6 `TUT-00c` | Planches d'inscription `MAN` #10 à #17 (cible du lot A) |
| Inscription par étapes (sans code) | `/inscription/usage`, `/identite`, `/genre`, `/recapitulatif` | Nouveau parcours : « Moi uniquement » ou « Moi et ma famille », lien discret « Je suis enseignant » | **Route sans bouton + STUB** (`inscription/etapes/*.dart`) ; lot A | `LOTS` A.2 ; `DEC` §3-8 | `MAN` #10 à #17 |
| `TUT-00b` Portail d'attente | `/attente` | État du dossier : incomplet (liste de pièces, un bouton chacune), en vérification, refusé (motif, « Corriger »), suspendu | **Atteignable** par la porte « attente » (`attente_page.dart:22-100`) ; partagé tuteur et enseignant ; refonte lot A | `CAT` §6 `TUT-00b` | Aucune |
| `TUT-00c/a` Accusé enregistrement et contrôle | `/attente/accuse` | Lire et accuser la carte « enregistrement audio et visite de contrôle » | **Atteignable** depuis `/attente` (`attente_page.dart:138-140`) | `CAT` §6 | Aucune |
| `TUT-00c/b` Contrat | `/attente/contrat` | Lire et signer le contrat **propre au rôle** | **Atteignable** (`attente_page.dart:143-145`) ; version famille avec paragraphe d'observation en cours (lot A) ; variante enseignant non redessinée | `CAT` §6 ; `DEC` §1 bis-3 | Consentement `MAN` #23 (famille seulement) |
| `TUT-00c/c` Dépôt de la pièce | `/attente/piece` | Déposer la pièce d'identité | **Atteignable** (`attente_page.dart:148-150, 201`) | `CAT` §6 | Aucune |
| `AGT-00` Entrée d'un agent | `/agent` | Voir section 10 | Atteignable avec un lien | `CAT` §6 | Aucune |
| Site public, landing web (sans code) | Aucune dans ce dépôt | Présenter l'académie, convaincre, mener à l'inscription | **Absent** : « le site public et l'application sont deux produits », `rewayahacademy.com` (`AI` §1). `web/index.html` n'est que l'hôte de l'application Flutter (titre « Rewayah Academy », description « Cours de Coran en visio, avec un enseignant attitre pour chaque eleve. ») | `AI` §1 | Aucune |
| Mentions légales, confidentialité, conditions (publiques) | Aucune | Pages lisibles sans compte | **Absent** : aucun document légal dans le dépôt (`DEP` DB-CPT-08) | Stores (section 14) | Aucune |

---

## 3. Élève adulte (et élève en mode standard)

**Destinations actuelles** :
- un adulte qui s'inscrit comme « Élève adulte » reçoit le rôle **tuteur** : Accueil · Foyer · Historique · Compte (`inscription_page.dart:38-41` ; `nav_shell.dart:98-120`), **sans aucun espace élève** ;
- un profil élève en mode standard (9 ans et plus, adulte compris selon `PU` §2) : Accueil · Coran · Suivi · Compte (`nav_shell.dart:66-90`). Un adulte ne peut pas l'atteindre aujourd'hui : tout profil élève créé est de type « mineur » (`DEP` DB-FOY-02) et le profil élève du titulaire n'existe pas (`DEP` DB-FOY-01).

Registre des textes actuels : l'accueil élève **tutoie** (« Ton cours a commencé », `eleve.accueil`), le suivi **vouvoie** (« Vos cours s'afficheront ici », `eleve.suivi`). Aucun texte n'est adapté à un adulte.

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-02` Accueil élève | `/eleve` | Deux blocs : prochain cours (6 états : plus tard, imminent, en direct, aucun cours, annulé, hors ligne) et accès au Coran | **Atteignable** (racine, `routes.dart:536` ; barre). « Rejoindre » n'apparaît qu'une fois le cours commencé (`accueil_eleve_page.dart:103-107, 394-406`). Manquent la semaine à venir, les annonces, l'historique des cahiers promis au mode standard (`PU` §2 ligne 178) | `CAT` §6 `ELV-02` ; `01` Rôles ; `06` Accueil par rôle | Aucune (captures de l'existant : `04_phase0\captures_revue_a11y\apres_eleve_accueil_*.png`, `apres_eleve_direct_390_standard_clair.png`) |
| `ELV-04` Le Coran | `/eleve/coran` | Lecteur, voir section 13 | **Atteignable** (barre `nav_shell.dart:75-79` ; bloc de l'accueil `accueil_eleve_page.dart:564-566`) | `CAT` `ELV-04` | Aucune |
| Suivi de mes cours (sans code) | `/eleve/suivi` | Historique des séances : date, cours, enseignant, présence | **Atteignable** (barre). Aucune fiche au catalogue (`CAT` §2, lignes 178-186) ; présence seulement, pas de progression | `CAT` §1 ligne « Suivi élève » | Aucune |
| Mon compte, Profil, Réglages | `/compte`, `/compte/profil`, `/compte/reglages` | Voir §1.4 | **Atteignable** (barre) | `03` Structure | Aucune |
| `ELV-03` Salle, élève | `/salle` | Visio, voir section 11 | **Atteignable** par « Rejoindre » (`accueil_eleve_page.dart:394-404`) | `CAT` `ELV-03` | Aucune |
| Mes classes (sans code) | `/tc/groupes` | Liste des classes de l'élève | **Route sans bouton** : le seul appel (`accueil_famille_page.dart:469`) est côté tuteur | `01` Espace Groupe ; `06` Espace Groupe | Aucune |
| Espace Classe (sans code) | `/tc/groupes/:groupeId` | Page de classe : enseignant, prochaine séance, décompte, travail, bibliothèque | **Route sans bouton** (seule entrée : la liste ci-dessus, `mes_groupes_page.dart:183`) | `01` Espace Groupe | Aucune |
| Classe Live (sans code) | `/tc/classe` | Seconde salle, voir section 11 | **Route sans bouton** (seule entrée : « Rejoindre » de l'Espace Classe, `routes_tc_a.dart:63-83`) | `08D` §3 (salle unique) | Aucune |
| Bibliothèque (sans code) | `/tc/bibliotheque`, `/tc/bibliotheque/:resourceId` | Voir section 12 | **Route sans bouton** (seule entrée depuis l'Espace Classe, `espace_groupe_page.dart:262`) ; contenu toujours vide | `01` Classe et supports | Aucune |
| Avant le prochain cours (sans code) | Aucune | Au plus trois actions entre deux séances | **Code non branché** (`lib/features/tc_flux_academique/bloc_avant_prochain_cours.dart`, non atteignable) | `07` Maison ; `06` Après cours | Aucune |
| Avis de fin de séance (sans code) | Aucune | Micro-retour facultatif de l'élève | **Code non branché** (`tc_flux_academique/carte_feedback_seance.dart`) | `01` Classe (« retour élève sans formulaire obligatoire ») | Aucune |
| Signaler un problème (sans code) | Aucune | Signalement vers l'académie | **Code non branché** (`tc_flux_academique/feuille_signalement.dart`) | `06` Communications | Aucune |
| Ma progression (sans code) | Aucune | Cycle actuel, compétences « À renforcer », « Acquis », « Stable » | **Absent** : la progression n'est lisible que par l'administration (`DEP` DB-CRS-11) | `07` Compétences ; `06` Pédagogie minimale | Aucune |
| Créer mon profil élève (adulte titulaire) | `/tuteur/foyer/ajouter?pour=moi` | L'adulte crée son propre profil élève | **Route sans bouton**, écran d'indisponibilité (`app_router.dart:484-490` ; `creer_mon_profil_indisponible.dart`) ; capacité serveur absente (`DEP` DB-FOY-01) | `DEC` §3-8 ; `LOTS` B.1 | Aucune |
| Choisir une classe (adulte) | `/tuteur/classes/catalogue` | Voir les classes ouvertes, toutes leurs séances, s'inscrire | **Atteignable (STUB) côté tuteur** ; source serveur absente (`DEP` DB-CRS-07, DB-CRS-08) | `01` Admission ; `06` Choix familial | Aucune |
| Activer l'Interface guidée (adulte) | Aucune | Un adulte peut choisir l'Interface guidée | **Absent** : aucune bascule côté élève (`DEP` DB-FOY-04) | `00:28` ; `08D` §3 | Aucune |
| Mes appareils, mes réglages (adulte autonome) | Aucune côté élève | L'adulte gère ce qu'un tuteur gère pour lui-même | **Absent** côté élève (écrans tuteur seulement) | `PU` §2 ligne 182 | Aucune |

---

## 4. Élève enfant (Interface guidée)

**Destinations actuelles** : **aucune**. Le mode est porté par le profil (`InterfaceMode.enfant`, valeur stockée `child`, `enums.dart:85-90`) et ne change que l'affichage, jamais les routes (`routes.dart:5-9`). Les éléments grossissent (`AppMetriques.estEnfant`) et des haut-parleurs lisent les libellés (`AudioLabel`), **mais aucun fichier son n'existe** : `assets/audio/fr/` ne contient que `.gitkeep` (le texte reste affiché, `audio_label.dart:73-74`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-01` Connexion de l'élève | `/connexion/eleve` | « J'ai un code », « Qui es-tu ? », « Choisis ton code secret », pavé numérique | **Atteignable** (voir section 2) | `CAT` `ELV-01` ; `PU` §2 | Aucune |
| Scanner, saisie du code | `/connexion/eleve/scanner`, `/code` | Voir section 2 | **Route sans bouton + STUB** (lot D) | `LOTS` D.2 | Aucune |
| `ELV-02` Accueil guidé | `/eleve` | Deux blocs seulement : prochain cours (décompte, « Avec {prénom} », pause prière en pictogramme) et « Le Coran » | **Atteignable** (racine) | `CAT` `ELV-02` ; `PU` §2 | Aucune (captures de l'existant : `captures_revue_a11y\apres_eleve_direct_390_guidee_clair.png`, `_sombre.png`) |
| `ELV-04` Coran guidé | `/eleve/coran` | Lecture libre ; sélecteur de sourates en gros, sans recherche (`PU` §2) | **Atteignable** par le bloc « Le Coran ». **Aucun retour visible** (0 destination, aucun bouton retour dans le lecteur) : impasse probable, **à vérifier** | `PU` §2 `ELV-04` | Aucune |
| `ELV-03` Salle guidée | `/salle` | Micro et sortie ; caméra seulement si la politique du profil l'autorise ; témoin « ton parent regarde » | **Atteignable** par « Rejoindre » à l'heure du début. Témoin enfant affiché (`salle_page.dart:508-511`). Textes de salle au **vouvoiement** (« Votre professeur n'est pas encore arrivé », `salle.*`) | `CAT` `ELV-03` ; `PU` §2 | Aucune |
| Retour après le cours (sans code) | vers `/eleve` | Retour automatique à l'accueil, animation d'encouragement de moins d'une seconde | Retour à la racine **codé** (`salle_page.dart:236-240`) ; animation d'encouragement **absente** (aucune occurrence) | `PU` §2 `ELV-03` | Aucune |
| Suivi | `/eleve/suivi` | Historique | **Route sans bouton** en Interface guidée (0 destination), conforme à la règle « l'enfant n'a aucune destination » | `AI` §5 | Aucune |
| Mon compte, déconnexion | `/compte` | Se déconnecter | **Route sans bouton** en Interface guidée : **aucune déconnexion possible** sur l'appareil de l'enfant. Contredit la règle du directeur « déconnexion accessible sur tous les formats » (`DEC` §1 ter-4) : **à trancher** | `DEC` §1 ter-4 | Aucune |
| Demande d'affichage standard (sans code) | Aucune | À partir de 10 ans, l'enfant demande l'affichage standard, le tuteur décide | **Absent** (`DEP` DB-FOY-04) | `DEC` P7 (décisions Classes V2) | Aucune |
| Mes classes, Espace Classe, Bibliothèque, Travail | Voir section 3 | | Mêmes états qu'en section 3 (sans entrée) | | Aucune |

---

## 5. Enseignant

**Destinations actuelles** : Journée · Créneaux · Profil (`nav_shell.dart:128-144`). Les écrans de séance et de classe sont des « poses » hors barre (`app_router.dart:702-732`). La déconnexion vit dans Profil (`profil_enseignant_page.dart:78, 616-641`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Inscription, contrat, pièce | `/inscription`, `/attente/*` | Voir section 2 | Atteignable par les portes | `PU` §3 ; `CAT` §7 `ENS-01` | Aucune |
| `ENS-01` Premiers pas | `/enseignant/bienvenue` | Après validation : trois étapes, deux rappels (enregistrement, visite), « Déclarer mes disponibilités » ou « Aller à ma journée » | **Route sans bouton** : aucun appelant ; la racine du rôle est la Journée (`routes.dart:538`) ; texte fondé sur l'ancien modèle (« L'académie vous confie des élèves sur ces heures », `fr.i18n.json:1519`) | `CAT` §7 `ENS-01` ; `R4` n° 22 | Aucune |
| `ENS-02` Votre journée | `/enseignant/journee` | Prochain cours, colonne de la journée (cours, pauses, prières), rapports en attente, absences détectées, « Élèves en attente » | **Atteignable** (racine, barre). Blocs hérités du modèle remplacé : « Prenez un élève en attente : c'est ce qui remplit votre journée. » (`fr.i18n.json:1544`), « Cours individuel » (`:1556`) | `CAT` §6 `ENS-02` ; `00:26` | Aucune (captures de l'existant : `captures_revue_a11y\apres_enseignant_journee_*.png`) |
| `ENS-06` Créneaux | `/enseignant/creneaux` | Grille de disponibilités ; liste d'élèves en attente avec « Prendre {jour} à {heure} h » ; demande de hausse du plafond | **Atteignable** (barre ; `journee_page.dart:361, 372` ; `bienvenue_page.dart:224`). Modèle « matching » remplacé par le choix d'une classe (`00:26` ; `08D` §3) | `CAT` §6 `ENS-06` | Aucune (capture de l'existant : `apres_enseignant_creneaux_390_clair.png`) |
| `ENS-05` Profil | `/enseignant/profil` | Identité professionnelle, pays et langues modifiables, fuseau, plafond, statut du compte, contrats en lecture, « Mes réglages », déconnexion | **Atteignable** (barre). Aucun envoi de photo publique (seulement des initiales, `profil_enseignant_page.dart:180`) | `CAT` §7 `ENS-05` | Aucune |
| Profil personnel, Réglages | `/compte/profil`, `/compte/reglages` | Voir §1.4 | **Atteignable** depuis Profil (`profil_enseignant_page.dart:597, 603`) | | Aucune |
| `ENS-07` Fiche de la classe | `/enseignant/groupe/:groupeId` | Élèves (prénom et identifiant, jamais de coordonnées), rendez-vous, effectif | **Atteignable** depuis la Journée si la séance porte une classe (`journee_page.dart:491`) | `CAT` §7 `ENS-07` | Aucune |
| `ENS-08` Revue de la classe | `/enseignant/groupe/:groupeId/revue` | Anomalies produites par le système, sans décision | **Atteignable** depuis la fiche (`fiche_groupe_page.dart:156`) ; **toujours vide** : les données ne sont lisibles que par l'administration (en-tête de `revue_groupe_page.dart`) | `CAT` §7 `ENS-08` | Aucune |
| `ENS-03` Salle, enseignant | `/salle` | Visio, présence, présentation d'une page du Coran | **Atteignable** par « Lancer le cours » (`journee_page.dart:538-540`), de 10 min avant le début à la fin, après vérification du micro. Panneau de présentation **seulement si** le jeton porte le droit `can_publish_data` (`salle_page.dart:616-617`). Voir section 11 | `CAT` `ENS-03` | Aucune |
| `ENS-04` Cahier de transmission | `/enseignant/seance/:seanceId/cahier` | Prérempli ; l'enseignant ne corrige que les exceptions ; travail à la maison ; point de prononciation ; suspension du nouveau contenu ; file hors ligne | **Atteignable** : sortie obligatoire de la salle (`salle_page.dart:217-225`) et rappel de la Journée (`journee_page.dart:722`) | `CAT` §7 `ENS-04` | Aucune |
| Correction de présence (sans code) | Aucune | Corriger une présence avec motif | Panneau **atteignable** dans le cahier ; page propre `PresenceCorrectionPage` **jamais instanciée** (code non branché) | `R4` n° 30 ; `06` Présence | Aucune |
| Élèves de mes classes (roster) | `/tc/groupes/:id` | Liste pédagogique pendant et hors séance | **Refusé** à l'enseignant par la garde (`redirection.dart:288-291`) : renvoyé à la Journée | `R4` n° 25 ; `BKL` | Aucune |
| Coran hors salle | Aucune | Préparer un passage | **Absent** : `/eleve/coran` et `/tc/mushaf` réservés à l'élève | `CAT` `ELV-04` (« Élève, enseignant ») ; `R4` n° 23 | Aucune |
| Bibliothèque, choisir un support en classe | `/tc/bibliotheque` (refusé) | Choisir, afficher, masquer un support | **Refusé** par la garde ; sélecteur en classe **code non branché** (`tc_catalogue/class_library_picker.dart`) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Outils de classe (sans code) | Aucune | Suivre, pointer, marquer, masquer, annoter, fixer le travail | **Code non branché** (`lib/features/tc_dock/*`, `lib/core/tc_outils/*`) | `06` Outils enseignant ; `03` Salle | Aucune |
| Après-cours et signalement (sans code) | Aucune | Préparer la suite, signaler à l'administration | **Code non branché** (`tc_flux_academique/panneau_post_cours.dart`, `lib/core/tc_parcours/*`) | `06` Après cours | Aucune |
| Envoyer ma photo publique (sans code) | Aucune | Photo visible des familles, distincte de la pièce d'identité | **Absent** (`DEP` DB-CRS-09 : la clé photo n'est jamais résolue) | `01` Espace Groupe ; `03` | Aucune |
| Déclarer une absence, demander un remplacement (sans code) | Aucune | Exception de planning tracée | **Absent** | `01` Admission et classes ; `06` Exceptions planning | Aucune |
| Voir mes deux fuseaux, notices de changement d'heure | Aucune | L'enseignant voit son heure et celle de la classe | **Absent** (aucune bibliothèque de fuseaux côté client, `DEP` DB-CRS-03) | `01` Espace Groupe | Aucune |
| Ma rémunération (sans code) | Aucune | Heures payables, paie | **Absent** (hors premier MVP, `07` Salaire ; `PU` §3 « pas de bloc solde ni de paie ») | `07` | Aucune |
| Notifications | Aucune | Rappels, changements, validation du dossier | **Absent** (`DEP` DB-CPT-04) | `06` Communications | Aucune |

---

## 6. Administration (tous les domaines)

**Destinations actuelles** : barre latérale à 8 domaines (Accueil, Opérations, Personnes, Pédagogie, Finance inerte, Configuration, Sécurité et audit ; Direction masqué), barre supérieure avec « Rechercher un écran » (navigation seulement, `admin_domaine.dart:138-146`), cloche qui ouvre une feuille vide (`admin_shell.dart:459-466` ; `DEP` DB-CPT-04 « faux état vide »), accès à « Mon compte ». Les fonctions secondaires d'Opérations, Personnes et Sécurité ne sont pas dans la barre : elles s'atteignent depuis l'Accueil (`app_router.dart:758-763`).

| Domaine | Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|---|
| Accueil | `ADM-01` Centre de commande | `/admin` | 6 compteurs (Dossiers à valider, Demandes à trancher, Foyers sans enseignant, Cahiers manquants, Incidents (24 h), Accès échus), « À traiter en premier », Outils (Comptes, Accès des agents IA) | **Atteignable** (racine). Deux compteurs **sans écran d'action** : Incidents et Accès échus (`tableau_de_bord_page.dart:284-291` ; texte « ils n'ont pas encore d'écran d'action ») | `CAT` §6 `ADM-01` ; `PU` §5 | Aucune |
| Opérations | `ADM-09` Groupes (classes) | `/admin/operations/groupes` (`/admin/operations` y redirige) | Créer une classe, ajouter ou retirer un élève, modifier le seuil, réglages d'observation, clôturer | **Atteignable** (barre). Création : nom, **identifiant brut de l'enseignant**, public (Enfants, Adultes), **un jour et une heure (0-23)**, seuil ; **fuseau figé `Europe/Paris`** ; ni durée, ni date de début, ni parcours, ni niveau, ni plusieurs jours (`groupes_page.dart:406-431, 445-495`). Ajout d'élève par **identifiant brut** (`:630`). Libellés « groupe » partout | `01` Admission et classes ; `06` Catalogue classes | Aucune |
| Opérations | Réglages d'observation d'une classe (feuille, sans code) | pas de route | Politique d'observation des tuteurs par classe | **Atteignable** (menu de la classe, `groupes_page.dart:78, 346-358`) ; message d'erreur qui cite « migration 0036 » à l'écran (`fr.i18n.json`, `admin.groupes.observationCapaciteAbsente`) | `01` Classe ; `DEC` §1 bis-4 | Aucune |
| Opérations | `ADM-05` Attribution manuelle | `/admin/operations/attributions` | Associer un élève sans enseignant à un enseignant | **Atteignable** depuis le compteur « Foyers sans enseignant » (`tableau_de_bord_page.dart:272`). « Écran de secours du matching inversé » : modèle remplacé (`00:26`) | `CAT` §6 `ADM-05` | Aucune |
| Opérations | `ADM-06` Demandes et règles | `/admin/operations/demandes` | Trancher une demande (changement d'enseignant, plafond, règle), règles individuelles d'un élève | **Atteignable** (`tableau_de_bord_page.dart:87, 267`) | `CAT` §6 `ADM-06` | Aucune |
| Personnes | `ADM-02` Dossiers à valider | `/admin/personnes/dossiers` (`/admin/personnes` y redirige) | Un dossier à la fois : pièce, trois vérifications, « Valider le dossier » ou « Refuser » avec motif | **Atteignable** (barre ; compteur `tableau_de_bord_page.dart:262`). Bloqué si le genre de l'administrateur manque (`dossiers_page.dart:444`) ; aucun écran pour le renseigner. Ne montre que les pièces **déposées** | `CAT` §6 `ADM-02` ; `PU` §5 ; `BKL` ligne 37 | Aucune |
| Personnes | `ADM-08` Comptes | `/admin/personnes/comptes` | Registre de toutes les personnes, ancienneté d'attente, pièce, contrats | **Atteignable** depuis Accueil > Outils (`tableau_de_bord_page.dart:225`). **Lecture seule** : ni activer, ni suspendre, ni changer de rôle, ni créer un compte du personnel | `CAT` §6 `ADM-08` ; `06` Identité (activation, suspension) | Aucune |
| Pédagogie | `ADM-10` Diagnostics | `/admin/pedagogie/diagnostics` (`/admin/pedagogie` y redirige) | Placer un élève sur un niveau d'un programme publié | **Atteignable** (barre, onglets `diagnostics_page.dart:94`) ; dépend d'un programme publié | `CAT` §6 `ADM-10` ; `07` Diagnostic | Aucune |
| Pédagogie | `ADM-11` Progression | `/admin/pedagogie/progression` | Niveau courant par classe et cycle, exceptions, blocages | **Atteignable** (onglets) | `CAT` §6 `ADM-11` | Aucune |
| Pédagogie | `ADM-12` Évaluations | `/admin/pedagogie/evaluations` | Évaluations et certifications | **Atteignable** (onglets) | `CAT` §6 `ADM-12` | Aucune |
| Pédagogie | `ADM-13` Programmes | `/admin/pedagogie/programmes` | Programme versionné (brouillon, publié immuable) | **Atteignable** (onglets) | `CAT` §6 `ADM-13` ; `07` | Aucune |
| Pédagogie | `ADM-14` Qualité | `/admin/pedagogie/qualite` | Anomalies calculées (cahiers manquants, blocages, évaluations en retard) | **Atteignable** (onglets ; compteur « Cahiers manquants » `tableau_de_bord_page.dart:282`) | `CAT` §6 `ADM-14` | Aucune |
| Finance | (domaine) | Aucune | Voir section 9 | **Absent** : libellé visible mais inerte (`admin_domaine.dart:99`) | `07` Finance | Aucune |
| Configuration | `ADM-15` Règles | `/admin/configuration/regles` (`/admin/configuration` y redirige) | Valeurs par défaut de la plateforme | **Atteignable** (barre, onglets `regles_page.dart:40-41`) | `CAT` §6 `ADM-15` | Aucune |
| Configuration | `ADM-16` Fonctionnalités | `/admin/configuration/fonctionnalites` | Interrupteurs de fonctions | **Atteignable** (onglets) | `CAT` §6 `ADM-16` | Aucune |
| Configuration | `ADM-17` Conservation des données | `/admin/configuration/conservation-donnees` | Durées de conservation (enregistrements, pièces d'identité) | **Atteignable** (onglets) | `CAT` §6 `ADM-17` | Aucune |
| Configuration | Académie, Classe en ligne, Notifications, Localisation (sans code) | Aucune | Réglages prévus par le contrat métier du 19/09 | **Absent** (`admin_domaine.dart:35-40` ; `ongletsConfiguration()` `:169-180`) | contrat `ADMIN_FINANCE_CONFIGURATION.md` (archive) | Aucune |
| Sécurité et audit | `ADM-04` Journal d'audit | `/admin/securite-audit/journal` (`/admin/securite-audit` y redirige) | Lecture seule, filtres, état de la chaîne d'empreintes | **Atteignable** (barre) | `CAT` §6 `ADM-04` | Aucune |
| Sécurité et audit | Historique des observations (sans code) | `/admin/securite-audit/observations` | Visites des tuteurs : qui, quelle séance, durée | **Route sans bouton + STUB** : `ongletsSecurite()` n'est appelé par aucun écran (recherche : seule sa définition `admin_domaine.dart:190`) ; écran en cours, lot E | `MAP` C4 ; `LOTS` E.3 | **Oui** : `MAN` #26 (D3, planche `tuteur observation desktop light.png`) |
| Sécurité et audit | `ADM-07` Accès des agents IA | `/admin/securite-audit/acces-agents` | Émettre un jeton de lecture borné dans le temps | **Atteignable** (`tableau_de_bord_page.dart:233`) ; système jugé « jamais fonctionnel » par le directeur (`BKL` ligne 39) | `CAT` §6 `ADM-07` | Aucune |
| Sécurité et audit | Sessions et appareils (`SEC-01`, `ADM-18` proposé) | Aucune | Sessions ouvertes, appareils | **Absent** (« prêt à construire », `HANDOFF.md:99-102` archive) | `ADMIN_SECURITE_DIRECTION.md:183` (archive) | Aucune |
| Sécurité et audit | Incidents sécurité (`SEC-02`, `ADM-19` proposé) | Aucune | Liste des incidents | **Absent** ; compteur « Incidents (24 h) » sans écran | idem `:186` | Aucune |
| Sécurité et audit | Exports et séquestre (`ADM-03`) | Aucune | Exports serveur autorisés | **Absent**, bloqué (contradiction de périmètre `ADM-03`/`CTR-03` non tranchée, `HANDOFF.md:2674-2683` archive) | `06` Contrôle et administration | Aucune |
| Direction | (domaine) | Aucune | Pilotage | **Absent**, masqué (`session_state.dart:140`) | `07` Pilotage | Aucune |
| Transverse | Observer une séance, visible ou incognito (sans code) | `/tc/observation/:seanceId` autorisée à l'admin ; `/salle` | Entrer dans une séance pour contrôle | **Absent** : aucun bouton côté administration (la garde l'autorise, `redirection.dart:298-301`) | `01` Classe (« Admin peut observer en mode visible ou incognito ») ; `06` Visiteurs | Aucune |
| Transverse | Paiements manuels et accès datés (sans code) | Aucune | Consigner un paiement hors application, dater l'accès, relancer | **Absent** (`DEP` DB-CPT-03) | `06` Paiement transitoire (M essentiel) ; `01` Académie et pilotage | Aucune |
| Transverse | Exceptions de planning (sans code) | Aucune | Annuler, reporter, remplacer, congés, jours fériés, changements d'heure | **Absent** (aucun écran d'action ; `DEP` DB-CRS-05) | `01` Admission et classes ; `06` Exceptions planning | Aucune |
| Transverse | Gestion de la bibliothèque (sans code) | Aucune | Importer, versionner, vérifier source et licence, publier | **Absent** | `01` Classe et supports ; `02` Ressources | Aucune |
| Transverse | Annonces et messages (sans code) | Aucune | Informer familles et enseignants | **Absent** | `06` Communications | Aucune |
| Transverse | Mon compte | `/compte` | Voir §1.4 | **Atteignable** (barre supérieure) | | Aucune |

---

## 7. Contrôleur

**Destinations actuelles** : aucune ; un seul écran, sans barre (`nav_shell.dart:145-157` ; `app_router.dart:734-741`). « Mon compte » par un bouton de l'écran (`planning_page.dart:168-172`).

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `CTR-01` Planning du contrôle | `/controleur` | Toutes les séances en cours et à venir, heure locale et UTC, filtres (état, enseignant), rappel permanent « visite journalisée », « Observer » sur les seules séances en cours | **Atteignable** (racine) | `CAT` §6 `CTR-01` ; `PU` §4 | Aucune |
| `CTR-02` Observation invisible | `/salle` | Voir et entendre sans être vu, bandeau « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » | **Atteignable** par « Observer » (`planning_page.dart:133-138`) | `CAT` `CTR-02` ; `PU` §4 ; `01` Classe | Aucune |
| Porte d'observation `/tc/observation/:seanceId` | `/tc/observation/:seanceId` | Seconde porte (celle du tuteur) | **Route sans bouton** pour le contrôleur (autorisé par la garde, `redirection.dart:298-301`) | `08D` §3 | Aucune |
| `CTR-03` Grille d'audit, compte rendu (sans route) | Aucune | Noter et rendre compte d'une visite | **Absent**, reporté (`PU` §4 ; contradiction `ADM-03`/`CTR-03`) | `01` Rôles (« compte rendu ») ; `06` Contrôle | Aucune |
| Signaler une anomalie (sans code) | Aucune | Transmettre un constat à l'administration | **Absent** (« le contrôleur observe et signale », `PU` §4, sans écran) | `PU` §4 | Aucune |
| Flux d'anomalies (sans code) | Aucune | « Qu'est-ce qui nécessite une vérification ? » | **Partiel** : filtre « Incident » dans le planning ; pas de flux dédié | `AI` §6 | Aucune |
| Mon compte | `/compte` | Voir §1.4 | **Atteignable** (`planning_page.dart:172`) | | Aucune |

---

## 8. Contrôleur invité

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Tout le rôle | Aucune | Inconnue | **Absent** : aucun rôle, aucune route, aucune spec. Le terme n'apparaît que comme hypothèse (« le jour où le contrôleur invité obtient une partie des droits admin », `AI` §2) et dans la liste des rôles à servir (`DEC` §1 ter-8) | Aucune | Aucune |

**Question au directeur, à poser avant toute spec** : qui est le contrôleur invité (inspecteur externe, parent référent, partenaire) ? Pour combien de temps ? Sur quelles classes ? Voit-il les noms des élèves ? Son accès est-il un compte ou un lien temporaire comme l'agent IA ?

---

## 9. Finance et comptable

**Destinations actuelles** : aucune. La racine `/comptable` rend l'écran « Mon compte » (`app_router.dart:959-963`). Le libellé du rôle dans « Mon compte » promet « Gère les paiements et les factures » (`fr.i18n.json:1320`), ce qu'aucun écran ne permet.

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `CPT-01` Espace comptable | `/comptable` | Tableau de bord comptable | **Atteignable**, mais n'affiche que « Mon compte » ; `CPT-01` est « hors MVP-0 » (`CAT` §1) | `01` Rôles (Comptable) | Aucune |
| Encaissements et rapprochement (sans code) | Aucune | Paiements reçus, frais, taux de change datés | **Absent** ; aucune table de paiement des familles (`DEP` DB-CPT-03 : les tables de `0001:242-297` concernent la rémunération) | `07` Finance, moteur 2 | Aucune |
| Paiement transitoire saisi par l'admin (sans code) | Aucune | Voir section 6 | **Absent** | `06` (M essentiel) | Aucune |
| Portefeuille, solde par enfant, recharge (`TUT-03`, `CPT-02`) | Aucune | Crédits consommés par enfant | **Absent** ; place réservée côté tuteur (`DEC` §1 ter-9) | `07` Finance, moteur 3 | Aucune |
| Rémunération des enseignants (sans code) | Aucune | Minutes payables, paie en brouillon, versement | **Absent** | `07` Finance, moteur 4 | Aucune |
| Pilotage, prévisions, conseiller IA (sans code) | Aucune | KPI, scénarios | **Absent**, hors premier MVP | `07` Finance, moteurs 5 et 6 | Aucune |
| Exports comptables (sans code) | Aucune | Exports autorisés | **Absent** | `01` Rôles ; `06` Contrôle | Aucune |
| Domaine Finance de l'administration | Aucune | Voir section 6 | **Absent**, inerte | `07` | Aucune |

---

## 10. Agent IA

| Écran | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `AGT-00` Entrée d'un agent | `/agent` (`/agent?jeton=...`) | Ouvrir en lecture seule le parcours d'une personne ; sans jeton, un formulaire ; refus sans distinguer inconnu, révoqué, expiré | **Atteignable** avec le lien fabriqué par `ADM-07` (`acces_agents_page.dart:549`) | `CAT` §6 `AGT-00` | Aucune |
| `ADM-07` Accès des agents IA | `/admin/securite-audit/acces-agents` | Émettre, lister, révoquer les jetons | **Atteignable** (section 6) | `CAT` §6 `ADM-07` | Aucune |

Décision du directeur : ce système de jetons n'a **jamais fonctionné** ; il est remplacé par l'aperçu de pull request, le mode démonstration et les captures, et **ne doit pas être relancé sans décision** (`BKL` ligne 39). Conséquence proposée pour ChatGPT : le laisser « Hors périmètre, pour plus tard ».

---

## 11. Salle de classe et visio

**Entrées actuelles par rôle** : élève « Rejoindre » (accueil) → `/salle` ; enseignant « Lancer le cours » (Journée) → `/salle` ; contrôleur « Observer » (planning) → `/salle` ; tuteur « Assister » → `/tc/observation/:seanceId` (`accueil_famille_page.dart:192-193`) ; administration : **aucune**. La salle `/salle` n'est ni partageable ni mémorisable : le billet d'entrée ne passe pas par l'adresse (`routes.dart:449-454` ; `redirection.dart:163-166`).

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-03` / `ENS-03` / `CTR-02` Salle unique actuelle | `/salle` | Un seul écran pour trois codes : visio, micro et caméra fermés à l'entrée, caméra absente si interdite, présence, réseau faible, reconnexion, bandeau permanent « Cours enregistré, visite de contrôle possible. » | **Atteignable** (élève, enseignant, contrôleur) ; **à vérifier** : le jeton vidéo serait refusé à tous (`DEP` DB-OBS-01 ; `BKL`) | `CAT` §6 ; `01` Classe ; `06` LiveKit | Aucune |
| Classe Live, seconde salle | `/tc/classe` | Salle plus riche (support dominant, entête de classe, fiche de séance, bibliothèque) | **Route sans bouton** ; décision : garder la plus complète, combiner, supprimer le doublon (`BKL` « Deux salles ») | `08D` §3 ; `BKL` | Aucune |
| Porte d'observation | `/tc/observation/:seanceId` | Entrée bornée du tuteur ; autorisée aussi à l'admin et au contrôleur | Atteignable **pour le tuteur seul** ; réelle désactivée en production (`OBSERVATION_TUTEUR_REELLE`, `DEC` P3) | `01` Classe | Maquettes tuteur `MAN` #18 à #24 |
| Pré-vol du matériel | dans `/enseignant/journee` et `/salle` | Vérifier le micro avant d'entrer | **Atteignable** côté enseignant (`journee_page.dart:503-556`) ; élève : vérification à l'entrée de salle (« Vérification de votre micro ») | `PU` §3 | Aucune |
| Présentation d'une page du Coran par l'enseignant | dans `/salle` | L'enseignant choisit une page, la classe la reçoit | Côté enseignant **atteignable sous condition** du droit signé ; côté élève **absent** : seul l'écran enseignant lit le flux (`salle_enseignant/presentation_coran.dart:55`) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Bouton « Ouvrir le Coran » côté élève | Aucune | L'élève ouvre le Coran pendant la séance | **Absent** (`salle_page.dart:55-60`) | `PU` §2 `ELV-03` | Aucune |
| Barre « Séance en direct » persistante | Aucune | Revenir à la séance après avoir navigué | **Code non branché** (`tc_classe_live/barre_cours_en_cours.dart`) | `01` (« session persistante lors de la navigation ») | Aucune |
| Synchronisation en direct et reprise après coupure | Aucune | État partagé du support, rejoué à la reconnexion | **Code non branché** (`lib/core/tc_realtime/*`, `lib/core/tc_etat_partage/*`) | `02` règle 4 ; `06` Outils enseignant | Aucune |
| Outils de classe (dock) | Aucune | Pointer, marquer, masquer, annoter | **Code non branché** (`lib/features/tc_dock/*`) | `06` Outils enseignant | Aucune |
| Bibliothèque pendant la séance | Aucune | Choisir un support | **Code non branché** (`class_library_picker.dart`) | `06` Bibliothèque | Aucune |
| Notices d'observation dans la salle | dans `/salle` | L'enseignant voit qu'un tuteur observe ; l'enfant concerné voit un témoin | **Atteignable** (`salle_page.dart:508-518`). Conception des notices enseignant et élève **hors périmètre** du chantier Tuteur (`DEC` §1 bis-6) : à spécifier | `01` Classe | Aucune (planche 3 « États particuliers et notices de présence » manquante, `MAN` §1) |
| Sortie de salle | depuis `/salle` | Enseignant vers le cahier ; autres rôles vers leur accueil | **Atteignable** (`salle_page.dart:217-240`) | `AI` §5 | Aucune |
| Présence | dans `/salle` et cahier | Présence calculée par le serveur, jamais « absent » inventé | **Atteignable** (lecture) ; consolidation après séance absente (`DEP` DB-HIS-04) | `06` Présence | Aucune |
| Enregistrement audio | bandeau | Le directeur affirme l'enregistrement **réel** (bucket R2) et garde la notice (`DEC` §1 bis-2) ; `06` interdit de l'activer sans décision écrite. **Conflit à signaler** | Bandeau atteignable ; enregistrement serveur **à vérifier** | `06` Enregistrement ; `DEC` §1 bis-2 | Aucune |
| Fenêtre d'entrée | élève, enseignant, serveur | Moment où « Rejoindre » s'ouvre | Trois valeurs : élève au début, enseignant 10 min avant, serveur 20 min avant ; texte de refus « La salle s'ouvre dix minutes avant l'heure du cours, et se ferme un quart d'heure après sa fin. » (`salle.refusAccesDetail`) | `01` (environ T-20 configurable) | Aucune |

---

## 12. Bibliothèque et ressources

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| Bibliothèque | `/tc/bibliotheque` (`?groupe=` pour la section « Pour ce groupe ») | Catalogue des supports | Autorisée à l'élève et au tuteur seulement (`redirection.dart:288-291`). **Route sans bouton** pour l'élève ; tuteur via l'Espace Classe. **Toujours vide** : source locale sans contenu (`lib/core/tc_bibliotheque/donnees_catalogue.dart:28-34`), alors que la fonction serveur `ressources_du_groupe` existerait (`DEP` §0 ligne 25, **à vérifier**) | `01` Classe et supports ; `06` Bibliothèque | Aucune |
| Fiche d'une ressource | `/tc/bibliotheque/:resourceId` | Lire un PDF, une image, une leçon ; téléchargement hors ligne | Même état (entrée depuis la liste, `bibliotheque_page.dart:46`) | idem | Aucune |
| Ressources de la classe (tuteur) | `/tuteur/classes/:id/ressources` | Vue tuteur | STUB, lot C (hors portée de ce document) | `LOTS` C.2 | Aucune |
| Bibliothèque de l'enseignant | Aucune | Préparer et choisir ses supports | **Refusée** par la garde ; sélecteur en classe non branché | `01` | Aucune |
| Gestion par l'administration | Aucune | Importer, versionner (version publiée immuable), source et licence vérifiées, visibilité | **Absent** | `01` ; `02` Ressources ; `06` Bibliothèque | Aucune |
| Leçons, PDF, images : types de contenu | Aucune source | | **Absent** en production (catalogue vide) | `01` | Aucune |

---

## 13. Lecteur du Coran

| Écran ou fonction | Route actuelle | Fonction principale | État du code (preuve) | Spec source | Maquette existante |
|---|---|---|---|---|---|
| `ELV-04` Lecteur | `/eleve/coran` (rend le moteur `MushafPage`) | Trois rendus (page, verset agrandi, focus), zoom, feuille de navigation, reprise personnelle et reprise de la classe, attribution Tanzil au pied | **Atteignable** pour l'élève (section 3). Défauts consignés, **non corrigés par décision** (`08D` §5 bis 24/09 ; `BKL` §Coran) : ordre des versets inversé (`lib/core/coran/service_coran.dart:309, 329-330, 459-460`, tri sans `ascending: true`), voyelles absentes, espacement trop large, mise en page non conforme au Mushaf de Médine (604 pages, 15 lignes, hizb, juz', rub', sajda), commandes manquantes ; gestes et boutons de page en sens contraires (`R4` §5.5) | `CAT` `ELV-04` ; `01` Classe et supports ; `03` Salle ; `BKL` | Aucune |
| Moteur en double | `/tc/mushaf` | Même écran | **Route sans bouton** ; décision : combiner puis supprimer le doublon (`BKL`) | `BKL` | Aucune |
| Suivre la classe dans le lecteur | Aucune | Position de la classe, « suivre le professeur » | **Code non branché** : l'identifiant de séance n'est jamais passé (`app_router.dart:322-323` construit `const MushafPage()`) | `01` Classe (« l'élève suit l'enseignant ») | Aucune |
| Mise en page fidèle ligne par ligne | Aucune | Pages identiques au Mushaf imprimé | **Absent** : port de mise en page désactivé (`lib/core/tc_coran/layout_lignes_indisponible.dart`) ; règle : sans référence, afficher le mode verset, jamais une fausse page « Mushaf » (`BKL`) | `03` Salle | Aucune |
| Coran pour l'enseignant hors salle | Aucune | Préparer | **Absent** (section 5) | `CAT` `ELV-04` | Aucune |
| Coran en Interface guidée | `/eleve/coran` | Sourates par nom et numéro en gros, sans recherche | Même écran que le mode standard ; pas de variante guidée repérée ; aucun retour visible (section 4) | `PU` §2 | Aucune |
| Marque-pages | dans le lecteur | Reprendre sa lecture | Reprise personnelle présente ; **décalée** par l'ordre inversé (`R4` §5.3) | `PU` §2 | Aucune |

---

## 14. Parcours transverses indispensables à la publication

| Parcours | Écrans et étapes actuels | État | Preuves | Ce qui manque pour publier |
|---|---|---|---|---|
| **Connexion** | `/connexion` : lien par courriel ou Google ; élève : `/connexion/eleve` | Web fonctionnel ; mobile natif : le retour du lien tombe sur le site web | `DEP` DB-ADM-07 (aucun `intent-filter` Android, aucun `CFBundleURLSchemes` iOS) ; `DEP` DB-TRV-04 (retour vers la page demandée) | Liens profonds Android et iOS ; retour à la page demandée après le lien ; refonte lot A |
| **Récupération d'accès** | `/connexion/recuperation` | STUB, aucun lien | `recuperation_page.dart` | L'écran, le lien depuis la connexion, les états (lien expiré, déjà utilisé, renvoyer) ; lot A |
| **Inscription et choix du rôle** | `/inscription` (rôle, identité, genre, récapitulatif) | Atteignable ; étapes nouvelles en STUB | `inscription_page.dart` ; `LOTS` A.2 | Élève adulte réel (DB-FOY-01) ; lien « Je suis enseignant » ; migration des élèves et enseignants déjà inscrits ailleurs (onboarding de confirmation, comptes provisoires : `decisions.md:435` archive, `06` Inscription) |
| **KYC enseignant** | `/inscription` (rôle Enseignant) → `/attente` → `/attente/accuse` → `/attente/contrat` → `/attente/piece` → attente de validation | Atteignable ; après validation, arrivée sur la Journée, **jamais** sur « Premiers pas » | `attente_page.dart:138-150` ; `routes.dart:538` | Texte et maquette du contrat enseignant ; statut et délai annoncés ; bouton vers « Premiers pas » ; notification de validation |
| **Validation des dossiers par l'administration** | `ADM-02` (valider, refuser avec motif) ; `ADM-08` (lecture) | Atteignable ; bloqué si genre de l'admin manquant | `dossiers_page.dart:305-319, 444` | Moyen de renseigner le genre du personnel ; activation, suspension, compte provisoire ; création des comptes du personnel (enseignant, contrôleur, comptable, admin) : **à vérifier** (peut-être seulement par la console Supabase) |
| **Notifications** | Cloche admin (feuille vide), cloche tuteur (STUB), réglages de notifications sans effet | **Absent** | `DEP` DB-CPT-04 ; `pubspec.yaml` sans aucune dépendance de notification push ; `supabase/functions/` sans envoi d'e-mail ni de push ; table `device_tokens` créée (`0001_fondations.sql:348`) mais sans émetteur | Notifications de cours, de changement, de validation (push, e-mail) et leurs textes ; seuls les e-mails de connexion envoyés par Supabase Auth existent (**à vérifier** : modèle et langue) |
| **Paiements manuels** | Aucun écran | **Absent** | `DEP` DB-CPT-03 ; seule la date `access_until` existe | Saisie admin d'un paiement hors application, accès daté, relance humaine, lecture famille ; jamais un paiement simulé comme réglé (`01`) |
| **Mentions légales et confidentialité** | Tuteur : `/tuteur/compte/informations-legales` (STUB) ; autres rôles : ligne « Confidentialité », sous-titre « Bientôt disponible », désactivée | **Absent** | `DEP` DB-CPT-08 (aucun document dans le dépôt) ; `compte_page.dart:87-92` | Textes (mentions légales, confidentialité, conditions, consentement parental), pages publiques et dans l'application pour tous les rôles |
| **Suppression de compte** | Aucune | **Absent** | Aucune occurrence dans `lib/` ni `supabase/` | Demande de suppression depuis l'application pour chaque rôle, conséquences sur le foyer et les enfants, conservation légale (durées de `ADM-17`) ; exigée par Apple et Google (**à vérifier** sur les règles en vigueur) |
| **Langue** | Français seul | Partiel | `assets/i18n/ar.i18n.json` : 32 lignes ; `fr.i18n.json` : 2 366 | Décision sur l'arabe au lancement ; sélecteur de langue |
| **Libellés audio (Interface guidée)** | Composant présent | Sans son | `assets/audio/fr/` : seulement `.gitkeep` | Enregistrer les fichiers de `lib/core/i18n/cle_audio.dart` |
| **Mode démonstration par rôle** | Seulement un mot de passe de démonstration (`DEMO_AUTH`) et un bac à sable de développement (`PLAYGROUND`) | **Absent** comme sélecteur de rôle | `connexion_page.dart:89-121` ; `DEC` §1 ter-6 | Sélecteur de rôle hors production, repère « Démonstration », aucun appel serveur |
| **Publication Android** | `applicationId` `com.rewayahacademy.rewayah_academy` ; version `0.2.0+1` | Non prêt | `android/app/build.gradle.kts:19` ; `pubspec.yaml:5` ; nom affiché « rewayah_academy » (`AndroidManifest.xml:11`) ; manifeste principal : seule la permission `CAMERA`, pas `RECORD_AUDIO` ni `INTERNET` (présentes seulement en debug et profile ; fusion par les paquets **à vérifier**) ; CI : construction apk en échec (`08D` §5 bis, run CI #4) | Nom, icône, permissions micro et réseau, fiche Play Store, programme Familles, Data safety |
| **Publication iOS** | `CFBundleDisplayName` « Rewayah Academy » | Non prêt | `ios/Runner/Info.plist` : `NSCameraUsageDescription` présent, **`NSMicrophoneUsageDescription` absent** | Texte d'usage du micro, fiche App Store, catégorie Enfants ou non, App Privacy, compte de démonstration pour la revue |
| **Publication web** | Application Flutter servie par Vercel | Chaîne réparée le 24/09 (aperçu par pull request, production sur `main`) | `08D` §5 bis ; `web/manifest.json` | Site public séparé (section 2), référencement |
| **Publication Windows** | Dossier `windows/` présent | Non prêt | CI Windows en échec (`08D` §5 bis) | Décision de publication, empaquetage |

---

## 15. Maquettes

### 15.1 Maquettes existantes utiles hors tuteur

Toutes les maquettes du dossier `D:\RA _APP\docs de lancement\tutuor image\` ont été dessinées pour le tuteur. Trois groupes servent aussi à d'autres rôles :

| Maquette (`MAN` §1) | Fichier | Écran | Rôles concernés |
|---|---|---|---|
| #10, #11 | `onboarding Mble.png`, `onboarding Mble d.png` | Inscription : usage, genre | Public, élève adulte (« Moi uniquement »), enseignant (lien discret) |
| #12 à #17 | `onboarding mobile 1.png`, `Onboarding mobile 2.png` | Inscription : usage, genre, âge, langue, objectif, récapitulatif | idem |
| #23 | `mobile\tuteur observation mobile light.png`, zone M6 | Consentement « Les visites des parents » | Contrat famille ; la variante enseignant n'existe pas |
| #26 | `tuteur observation desktop light.png`, zone D3 | Historique des observations, administration (ordinateur, clair) | Administration |

### 15.2 Captures de l'état actuel (pas des cibles)

Rendu actuel du code, utile pour voir ce qui existe, jamais comme direction visuelle :
- élève : `D:\RA _APP\pilotage-tuteur-v1\04_phase0\captures_revue_a11y\apres_eleve_accueil_390_clair.png`, `..._390_sombre.png`, `..._1440_sombre.png`, `..._390_clair_texte200.png`, `apres_eleve_direct_390_guidee_clair.png`, `..._guidee_sombre.png`, `apres_eleve_direct_390_standard_clair.png` ;
- enseignant : même dossier, `apres_enseignant_journee_390_clair.png`, `..._390_sombre.png`, `..._390_clair_texte200.png`, `..._1024_clair.png`, `apres_enseignant_creneaux_390_clair.png` ;
- connexion : `D:\RA _APP\pilotage-tuteur-v1\02_code\capture_proto\out\01_connexion_390x844@3_clair.png`, `02_..._sombre.png`, `03_connexion_1440x900@1_clair.png`, `04_..._texte200.png`.

### 15.3 Écrans hors tuteur sans aucune maquette (besoin d'une nouvelle image)

Tous les écrans des sections 3 à 13, **sauf** : l'inscription (#10 à #17), le consentement famille (#23), l'historique des observations admin (#26). Les écrans du lot A (bienvenue, connexion, récupération, dossier `/attente`) ont une **dérivation** écrite (`MAN` §2), pas une maquette. Priorités du directeur pour l'ordre des images : salle élève et enseignant (priorité n° 1, `BKL`), validation des dossiers par l'administration, puis les rôles dans l'ordre du prompt.

---

## 16. Vocabulaire et registre : écarts relevés dans les textes actuels hors tuteur

| Écart | Exemples exacts (`assets/i18n/fr.i18n.json`) |
|---|---|
| « groupe » au lieu de « Classe » | `admin.groupes.*` (lignes 589-640 : « Groupes », « Créer un groupe », « Nom du groupe ») ; enseignant « Voir le groupe » (1559), « Fiche du groupe » (1737), « Note pour le groupe » (1614) ; Espace Classe « Mes groupes » (1817) |
| « Cours en cours » | « Cours en cours · {reste} » (1857, Espace Classe) |
| « Mode enfant » au lieu de « Interface guidée » | « Mode enfant » (1299, 1811) |
| « Ajouter un enfant » | 336, 1297 |
| « session » | « Mettre fin à la session sur cet appareil » (1250) ; « Votre session a expiré » (37) |
| Promesse de date (« bientôt ») | « Bientôt disponible » (1245, 1278, 1891) ; « C'est bientôt » (126) |
| Ancien modèle « matching » | « Prendre {jour} à {heure} h » (404) ; « Prenez un élève en attente » (1544) ; « Cours individuel » (1556) ; « L'académie vous confie des élèves sur ces heures » (1519) |
| Code interne visible | « migration 0036 » dans `admin.groupes.observationCapaciteAbsente` |
| Registre incohérent pour l'élève | Accueil au tutoiement (`eleve.accueil`), suivi et salle au vouvoiement (`eleve.suivi`, `salle.*`) ; aucun texte propre à l'adulte |
| Rôle qui promet l'inexistant | « Gère les paiements et les factures » (1320, comptable) |

---

## 17. Points à vérifier et questions ouvertes

1. **Validation des dossiers** : le blocage vient-il du genre manquant de l'administrateur, d'une absence de pièce déposée, ou du serveur ? À mesurer en base avant de spécifier `03_ADMIN_VALIDATION_DOSSIERS.md`.
2. **Jeton vidéo** : la migration `0042` refuse-t-elle vraiment tout jeton (`DEP` DB-OBS-01) ? Sans jeton, aucune rencontre élève-enseignant.
3. **Fenêtre d'entrée** : quelle valeur unique (10 ou 20 minutes, configurable) pour tous les rôles ?
4. **Salle unique** : laquelle garder comme base (`/salle` ou `/tc/classe`) ?
5. **Élève adulte** : bascule d'un compte titulaire vers son espace élève (un seul rôle par session aujourd'hui, `DEP` DB-FOY-01) : deux comptes, ou une bascule dans le même compte ?
6. **Interface guidée** : l'enfant doit-il pouvoir se déconnecter ou revenir en arrière depuis le Coran, contre la règle « aucune destination » ?
7. **Contrôleur invité** : définition complète (section 8).
8. **Enregistrement audio** : conflit entre `06` (ne pas activer sans décision écrite) et la réponse du directeur (enregistrement réel, `DEC` §1 bis-2).
9. **Capacités et durées des classes** : 5 enfants / 60 min et 6 adultes / 90 min, ou 4/45 et 5/90 (`07` arbitrage 1) ; la création de classe actuelle ne porte pas de durée.
10. **Comptes du personnel** : comment l'administration crée-t-elle un compte contrôleur, comptable ou administrateur ? Aucun écran ne le fait.
11. **Agent IA** : confirmer « hors périmètre » (`BKL` ligne 39).
12. **Arabe au lancement** : oui ou non.

---

## Annexe : rejouer ces constats

```powershell
$r = "D:\RA_TUTEUR\integration"
git -C $r rev-parse --short HEAD                                   # cefab7f
# Routes et gardes
Get-Content "$r\lib\core\router\routes.dart", "$r\lib\core\router\app_router.dart", "$r\lib\core\router\redirection.dart"
# Entrees de navigation hors routeur
rg -o "(Routes\.[a-zA-Z]+|CheminsTcA\.[a-zA-Z]+|RoutesTc[A-Z]\.[a-zA-Z]+|RoutesCoran\.[a-zA-Z]+)" "$r\lib" -g "!**/core/router/**"
# Ecrans provisoires
rg -n "STUB PHASE 0 : propri" "$r\lib"
# Graphe d'imports (lecture seule, sortie hors depot)
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\RA _APP\pilotage-tuteur-v1\06_registre\outils\graphe_imports.ps1" -Repo $r -Ref cefab7f -OutDir <dossier hors depot>
```


---


# F. Mandat original du directeur pour le rôle Tuteur

# Rewayah - implémentation verticale du frontend Tuteur

Prompt d'exécution à transmettre à Claude Code avec les nouvelles maquettes high-fi.

## 1. Mandat immédiat

Tu es Claude Code, responsable de l'orchestration et de l'intégration dans le dépôt Flutter existant de Rewayah. Commence maintenant l'implémentation des nouveaux visuels du rôle Tuteur et des parcours qui y conduisent. Organise tes agents par parcours complets, avec un propriétaire unique par fichier.

Le gel qui empêchait de commencer le perfectionnement UI est levé pour ce périmètre. Cela n'autorise ni l'intégration d'une branche précédemment déclarée non conforme, ni une migration distante, ni une mise en production.

La démarche est verticale à l'intérieur du frontend : entrée du parcours, écrans principaux et secondaires, formulaires, routes, retours, validations locales, états et responsive. Il ne s'agit pas de produire cinq pages isolées ni de commencer maintenant un chantier backend.

Perfectionne l'existant. Refais seulement les parties absentes, trop mauvaises ou incompatibles avec les nouvelles maquettes. Ne réécris ni l'application, ni l'authentification, ni le routeur, ni le moteur de classe. Préserve les fonctions déjà utilisables.

## 2. Sources et arbitrage

Lis les instructions actives du dépôt et `docs/current/00_LIRE_D_ABORD.md`, puis les sources pertinentes `01_PRODUIT_ET_PARCOURS.md`, `02_ARCHITECTURE_ET_SECURITE.md`, `03_DESIGN_SYSTEM_ET_UX.md`, `06_SPEC_FONCTIONNELLE_MVP.md`. Consulte `04` pour la coordination Git et `07` pour les contenus utiles, sans lancer les moteurs avancés. Recherche les décisions canoniques plus récentes, notamment Classes V2 et onboarding. Les documents académiques et Teaching Core servent à retrouver un détail métier manquant, pas à relancer leurs anciens chantiers multi-agents.

Ordre d'arbitrage pour ce lot :

1. Demande explicite actuelle du directeur, dont ce prompt formalise le périmètre.
2. Sécurité et contrats d'accès existants, qui ne peuvent être affaiblis pour reproduire une image.
3. Nouvelles maquettes high-fi fournies par le directeur pour le rendu visuel.
4. Décisions métier canoniques les plus récentes pour le contenu et les comportements.
5. Bible frontend V2, tokens et composants existants pour l'exécution cohérente.
6. Anciennes captures et documents historiques, uniquement comme contexte identifié.

Une maquette peut omettre une fonction, contenir du faux texte, une ancienne appellation, une date incohérente ou un questionnaire incomplet. Reproduis son langage visuel, pas ses erreurs métier. Complète les contenus avec le code et les specs applicables en conservant son style.

Si le code contredit une décision explicite, le code n'a pas raison par défaut. Corrige la présentation et la logique frontend quand le contrat existant le permet. Si la correction exige le backend, isole cette dépendance et continue les autres travaux. Ne tranche pas silencieusement une contradiction métier non résolue.

### Références visuelles : obligation de lecture réelle

Construis un manifeste court : fichier exact, écran représenté, état, thème, format, statut « nouveau high-fi » ou « ancienne capture ». Ouvre effectivement chaque image. Ne prétends pas l'avoir inspectée si elle est inaccessible ; demande uniquement le fichier manquant et poursuis les parties indépendantes.

Les pièces historiques nommées `Accueil.png`, `Foyer Member.png`, `Historique.png`, `Classe Details.png`, `Profil.png` ne deviennent pas automatiquement les nouvelles références approuvées. Les nouvelles images jointes par le directeur les remplacent pour le visuel correspondant. Attention : dans les captures historiques, `Profil.png` représente la fiche d'une élève, pas le compte personnel du tuteur. Le nom du fichier ne suffit pas à déterminer sa route.

La planche de direction onboarding est un design system visuel ; les écrans high-fi qui en découlent sont les références de composition. Ne transforme pas toute la planche en écran utilisateur.

Pour chaque écran de référence, relève : composition, ordre des sections, alignements, proportions, typographie, palette, densité, surfaces, iconographie, rayons, CTA, navigation, états. Centralise les valeurs dans les tokens. Ne remplace pas les maquettes par un dashboard Flutter générique ou une mosaïque de cartes. N'utilise jamais une capture aplatie comme interface interactive.

À taille et thème comparables, produis une capture de l'implémentation et compare-la à l'image source. Corrige les écarts visibles avant de déclarer l'écran conforme. Pour un écran absent des maquettes, dérive sa composition des composants approuvés et consigne la référence utilisée. L'absence de maquette ne permet pas d'inventer une nouvelle direction artistique.

## 3. Frontière frontend / backend

Autorisé : widgets, thème, assets, routes et guards existants consommés correctement, états de présentation, formulaires, validation locale, accessibilité, caméra et décodage QR côté appareil, permissions plateforme, branchement aux services déjà disponibles, tests frontend, jeux de données de démonstration isolés.

Hors périmètre : migrations SQL, tables, RLS, RPC, Edge Functions, émission de tokens, politiques serveur, finance, stockage R2, webhooks et logique LiveKit centrale. Pas de modification opportuniste du backend pour débloquer une page.

Réutilise les contrats réels et les services existants. Pour une capacité absente, crée seulement le port/adaptateur frontend nécessaire avec une signature fondée sur les besoins identifiés. Les fixtures restent dans les tests ou un environnement de démonstration explicitement isolé, jamais comme fallback silencieux de production. Une action sans backend disponible affiche un état indisponible compréhensible, jamais un faux succès.

Distingue dans la livraison : « UI réalisée », « branchée au service existant », « testée en simulation », « vérifiée réellement », « dépendance backend ». Un écran terminé n'atteste pas un parcours métier opérationnel.

## 4. Arbre cible et routes

Les chemins ci-dessous sont des noms logiques de référence. Commence par les mapper aux routes existantes et conserve leurs identifiants lorsque possible. Un alias ou une redirection vaut mieux qu'une deuxième route concurrente. Les routes sensibles ne transportent jamais de secret dans l'URL.

Navigation principale cible : **Accueil · Foyer · Historique · Compte**. Même ordre et mêmes destinations partout. Les anciennes captures à trois destinations ne justifient pas une navigation variable. Si les nouveaux high-fi approuvés prescrivent explicitement un autre shell global, conserve leur shell cohérent et garde toutes les destinations accessibles.

| Parent | Destination / titre utilisateur | Route logique | Contenu ou sorties |
|---|---|---|---|
| Public | Bienvenue | `/bienvenue` | Commencer, connexion existante |
| Public | Connexion | `/connexion` | Connexion, récupération, accès appareil élève |
| Public | Récupérer mon accès | `/recuperation` | Saisie, attente, retour, lien expiré selon auth existante |
| Admission | Votre compte | `/inscription` | Auth et consentements requis, sans double création |
| Admission | Pour qui souhaitez-vous utiliser Rewayah ? | `/onboarding/usage` | Usage personnel ou familial | sans oublier inscription enseignant | formulaire KYC et consentement trop bizarre avec beaucoup de CTA et trop de rectangles les uns sur les autres (à banir).
| Admission | Questionnaire | `/onboarding/...` | Identité, élève(s), langue, objectif, niveau et branches existantes |
| Admission | Récapitulatif | `/onboarding/recapitulatif` | Modifier, confirmer, état de dossier, prochaine action réelle |
| Accueil | Accueil | `/tuteur/accueil` | Élève sélectionné, prochaine séance, préparation, dernière séance |
| Transversal | Notifications | `/tuteur/notifications` | Liste, détail, destination liée |
| Foyer | Foyer | `/tuteur/foyer` | Membres, ajout, appareils partagés |
| Foyer | Ajouter un profil élève | `/tuteur/foyer/ajouter` | Pour moi / pour un enfant ou proche autorisé |
| Foyer | Prénom de l'élève | `/tuteur/foyer/:eleveId` | Identité, classe, accès, préférences autorisées, appareils |
| Fiche élève | Informations de l'élève | `.../informations` | Identité, date de naissance, photo, champs permis |
| Fiche élève | Parcours et inscription | `.../inscription` | Questionnaire repris, dossier, choix de classe, attente |
| Fiche élève | Interface | `.../interface` | Interface guidée / standard selon politique |
| Fiche élève | Caméra en cours | `.../camera` | Autorisation métier existante, distincte du scanner QR |
| Fiche élève | Accès Rewayah | `.../acces` | Statut, dates, motif utile, action autorisée |
| Fiche élève | Appareils | `.../appareils` | Appareils associés, connexion, retrait autorisé |
| Foyer | Appareils du foyer | `/tuteur/foyer/appareils` | Appareil partagé, profils autorisés, gestion |
| Appareils | Connecter un appareil | `/appareils/connexion` | Émetteur QR/code ou scanner selon protocole existant |
| Appareils | Scanner le QR code | `/appareils/scanner` | Caméra réelle, saisie manuelle alternative |
| Appareils | Saisir le code | `/appareils/code` | Code, validation, erreurs, confirmation |
| Appareil élève | Choisir mon profil | `/appareil/profils` | Profils autorisés et PIN si prévu |
| Appareil élève | Entrer mon code PIN | `/appareil/pin` | Vérification existante, récupération assistée |
| Inscription | Choisir une classe | `/tuteur/classes/catalogue` | Catalogue réel, détails, sélection, confirmation/attente |
| Accueil / élève | Nom de la classe | `/tuteur/classes/:classeId` | Élève concerné, enseignant, séance, planning, travail, ressources |
| Classe | Planning | `.../planning` | Séances datées, exceptions, fuseau local |
| Classe | Travail à préparer | `.../travail` | Consignes, détails, supports et statuts existants |
| Classe | Bibliothèque | `.../ressources` | Ressources autorisées et lecteur existant |
| Classe / élève | Progression | `.../progression` | Progrès et observations partageables |
| Classe | Observer la séance | `.../observer` | Vue tuteur bornée, entrée et sortie existantes |
| Historique | Historique | `/tuteur/historique` | Élève, classe, période, statut, séances |
| Historique | Détail de la séance | `/tuteur/seances/:seanceId` | Présence, horaires, résumé, travail et incident utile |
| Compte | Mon compte | `/tuteur/compte` | Identité du titulaire et rubriques ci-dessous |
| Compte | Informations personnelles | `.../informations` | Identité et coordonnées autorisées |
| Compte | Connexion et sécurité | `.../securite` | Méthodes existantes, mot de passe, sessions, déconnexion |
| Compte | Abonnement et accès | `.../acces` | Bénéficiaires, accès et échéances réels |
| Compte | Paiements | `.../paiements` | Historique réel, détail, justificatif disponible |
| Compte | Préférences | `.../preferences` | Langue, apparence, fuseau, notifications selon contrats |
| Compte | Aide et support | `.../aide` | Aide, contact disponible, suivi si existant |
| Compte | Informations légales | `.../informations-legales` | Documents réellement disponibles |
| Transversal | Page introuvable / accès impossible | Route de fallback | 404, accès refusé, session expirée, ressource indisponible |

Cette arborescence consolide les besoins du présent mandat. Vérifie les sous-fonctions dans les specs et le dépôt : elle n'autorise pas à créer des règles métier ou permissions nouvelles. Les notifications/messages renvoient aux modules existants ; ne crée pas une nouvelle messagerie. Une fonction prévue mais sans service reçoit son écran frontend honnête et sa dépendance documentée.

Conserve sélection d'élève, filtres, brouillons non sensibles et position de retour quand approprié. Sur web : retour/avance, refresh et liens directs autorisés. La salle éphémère et les secrets d'association ne deviennent pas des liens publics. Un identifiant de route ne vaut jamais une autorisation. Un lien profond inexistant ne doit pas crasher.

## 5. Contenu et emplacement par écran principal

### Accueil

Ordre de lecture : titre et notifications ; sélecteur des profils élèves ; prochaine séance du profil sélectionné ; éventuelle action bloquante ; préparation ; résumé de dernière séance.

- Sélecteur : prénom, portrait/fallback, état réel compréhensible. Inclure le propre profil du parent s'il existe, sans l'appeler « enfant ». Un changement de profil met à jour tous les blocs concernés.
- Bloc classe : nom de classe, parcours/niveau compréhensible, nom ET photo publique de l'enseignant, titre Sayyid/Sayyida. Ne confonds pas portrait élève et photo enseignant.
- Séance : jour, date, heure locale et fuseau utile, durée effective. Jour J : « Cours dans 3 h 28 » ; ouverture selon fenêtre existante/configurable, généralement T-20 ; séance prolongée : « Cours toujours en cours », jamais compteur négatif.
- CTA principal : « Voir la classe ». L'observation se fait dans la classe selon autorisation. Le tuteur qui veut étudier passe par son propre espace élève, pas par un privilège tuteur.
- Blocage utile : photo requise, dossier à compléter ou appareil non prêt, seulement si confirmé par les données. Action unique contextualisée.
- « Avant le prochain cours » : jusqu'à trois actions visibles, lien vers le travail complet. Marquer fait ne signifie pas compétence acquise.
- « Dernière séance » : date, présence confirmée, résumé ; lien Historique. N'affiche « réseau bon » que si une donnée réelle l'établit. Aucune absence déduite d'une simple déconnexion.
- Vide : première inscription ou ajout de profil, pas une fausse classe. Ne duplique pas toutes les fonctions du Foyer sur cet écran.

### Foyer

Titre « Foyer », description courte si utile. Action « Ajouter un profil élève ». Liste des membres avec identité, classe ou inscription en cours, état d'accès et appareils si utile. Évite les compteurs décoratifs et les CTA doublons. Utilise lignes ou surfaces sobres selon le high-fi.

Un parent sans profil élève reste un titulaire du compte, pas un élève fictif. Affiche l'option discrète « Créer mon profil élève » tant que ce profil n'existe pas ; après création, afficher son profil réel et « Ouvrir mon espace élève » selon accès.

Appareils partagés : nom, profils autorisés et lien de gestion. Les limites d'appareils viennent du contrat, pas du « 1/2 » d'une capture. Une restriction de retrait pendant la séance n'est appliquée que si elle existe dans la politique.

Les disponibilités éventuelles ne réintroduisent pas le matching individuel abandonné : inscription courante par classes précréées. Ne confonds pas disponibilité horaire d'un appareil et disponibilité pour suivre des cours.

### Fiche d'un élève

En-tête : prénom, photo, âge si disponible et utile, classe ou état d'inscription. Puis lignes regroupées : informations, parcours/classe, interface, caméra en cours, accès, appareils. Les données pédagogiques renvoient aux vues dédiées plutôt qu'à une immense fiche.

Photo : sélection, aperçu, upload existant, progression, échec/reprise ; ne mélange pas portrait et pièce d'identité. Respecte les règles réelles de photo avant première visio, sans inventer une nouvelle obligation KYC.

Interface guidée : libellé neutre, accessible également aux adultes. Reprends la politique canonique actuelle, dont demande de standard à partir de 10 ans et activation par le tuteur si confirmées dans le dépôt. Une préférence affichée ne contourne pas le serveur. Ne crée pas de bascule locale permettant d'élever les droits.

Les proches adultes ne sont pas automatiquement des mineurs sous tutelle : vérifie les liens, consentements et droits déjà définis. Ne permets pas au titulaire de consulter ou modifier leurs données au-delà des droits réels.

### Classe

En-tête : nom de classe et élève concerné. Zone principale : enseignant avec photo, parcours, prochaine séance et action contextuelle. Puis planning habituel, exceptions datées, préparation, ressources, progression et historique accessibles sans empilement de cartes imbriquées.

Planning : tous les jours récurrents de la classe, même enseignant permanent, heure locale, durée. La conversion dépend des dates et fuseaux IANA ; aucun décalage UTC fixe. Classe annulée/reportée, absence d'enseignant et remplacement ne se présentent pas comme un cours normal.

Observation : « Observer la séance », durée disponible et motif d'indisponibilité si nécessaire. Politique serveur par classe ; référence historique 1 visite et 120 secondes cumulées, pas des constantes frontend. Aucun micro/caméra ni publication ; pas de roster privé. Affiche temps restant et fin de visite, respecte la sortie existante. Sans garantie serveur disponible, ne rends pas l'observation réelle accessible par simulation.

Catalogue : afficher parcours, public/niveau, langue, enseignant, toutes les séances hebdomadaires, durée, fuseau et places réelles. Confirmer la même classe et le même enseignant sur la semaine. Prévoir aucune classe compatible, liste d'attente existante, dernière place perdue et confirmation refusée. Ne crée aucune réservation locale mensongère.

### Historique et détail de séance

Titre, sélecteur élève, filtres proches de la liste : classe, période, statut. Lignes lisibles avec date, horaire, classe, enseignant, présence/retard validé. La qualité réseau est secondaire et uniquement disponible si mesurée.

Détail : identité de la séance, présence et durée pertinentes, résumé destiné à la famille, travail et ressources autorisés. Distingue durée du cours et temps connecté si tous deux existent. État « En cours de vérification » pour preuve ambiguë. Ne livre jamais notes internes, coordonnées privées ou télémétrie brute.

### Mon compte

Le compte concerne le titulaire ; la fiche élève concerne l'apprentissage. Le tuteur peut être titulaire sans étudier.

Ordre : identité et modification ; abonnement/accès ; paiements ; connexion et sécurité ; informations personnelles ; préférences ; accès au foyer ; aide et support ; informations légales ; déconnexion clairement séparée. Adapte l'ordre exact au nouveau high-fi approuvé tout en conservant ces destinations.

Chaque rubrique est une ligne ou un groupe sobre avec résumé utile. Pas un catalogue de grandes cartes. Le raccourci Foyer mène au Foyer existant. « Créer mon profil élève » reste possible ici aussi, mais ouvre le même flux.

Paiements et accès : affiche uniquement montants, devises, statuts et dates fournis. Accès offert, accès daté et paiement externe validé ne deviennent pas automatiquement un abonnement récurrent. N'ajoute pas un prestataire, des tarifs fixes ou un faux paiement réussi. Les actions financières absentes du service sont indisponibles proprement.

## 6. Onboarding complet, même quand les maquettes sont partielles

Inventorie d'abord le questionnaire actuel : questions, branchements, champs obligatoires, consentements, reprise et sorties. Rapproche chaque étape du code et des specs. Complète les étapes manquantes dans le langage visuel high-fi ; ne raccourcis pas le questionnaire au seul nombre d'images fournies.

### Choix d'usage : décision explicite du directeur

Garde de préférence deux choix et clarifie leur description. Texte conseillé :

- **Moi uniquement** : « Je souhaite suivre les cours avec mon propre profil élève. »
- **Moi et ma famille** : « Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment. »

Ne crée pas un troisième choix « Mes enfants uniquement » par défaut : la description lève l'ambiguïté. Si le high-fi utilise un titre légèrement différent, conserve la composition et assure exactement cette compréhension.

Choisir l'usage familial ne crée PAS automatiquement un profil élève pour le parent et ne l'oblige pas à choisir un cours, un niveau ou à payer pour lui-même. Le compte gestionnaire existe séparément des profils élèves.

Des années plus tard, le parent doit pouvoir choisir « Créer mon profil élève » dans Foyer ou Compte, compléter son propre parcours et rejoindre une classe. Même compte, même foyer, historique des enfants conservé, aucun doublon de titulaire. Le choix initial n'est pas un verrou permanent. L'adulte initialement seul peut accéder à l'ajout de proches si le modèle de droits existant le permet.

### Complétude et branches

- Réutiliser identité et coordonnées déjà connues, ne pas les redemander sans raison.
- Déterminer pour qui chaque question est posée : titulaire ou élève nommé. Afficher ce prénom dans le contexte lorsqu'il y a plusieurs élèves.
- Reprendre les questions de langue, objectif, lecture de l'arabe/Coran, mémorisation et expérience prévues, uniquement dans leurs branches utiles. Aucun code académique interne à l'écran.
- Débutant déclaré : appliquer la dernière décision canonique de parcours débutant direct et de suppression du diagnostic inutile ; vérifier notamment les décisions Classes V2 plus récentes que les anciens documents. Non-débutant : pré-diagnostic court et décision pédagogique selon le processus existant. Ne transformer aucune autodéclaration en certification.
- Les cohortes et dates de naissance suivent la politique actuelle, notamment 6-9, 10-13, 14-17, 18+ si confirmée par les décisions en vigueur. Prévoir anniversaire pendant le flux, âge manquant, borne et politique non disponible ; ne pas deviner un âge.
- Préserver consentements et pièces réellement requis. Si dépôt et specs se contredisent, consigner la source, la correction frontend et l'éventuelle dépendance serveur.
- Choix de classe avec toutes les séances ; pas de disponibilités libres qui promettent un enseignant différent chaque jour.
- Retour sans perte, progression adaptée aux branches, erreurs sous les champs, correction depuis le récapitulatif, double soumission empêchée, reprise selon mécanisme existant. Aucun stockage persistant nouveau de secrets ou pièces sensibles.

Recette obligatoire : parent inscrivant seulement un enfant ; parent ajoutant plusieurs enfants ; parent et enfant élèves ; adulte seul ; parent ajoutant son profil après une longue période ; profil personnel déjà existant ; débutant ; non-débutant ; reprise interrompue. Ne force pas un parent sans profil élève à répondre aux questions pédagogiques pour lui-même.

## 7. Connexion des appareils : parcours complet des deux côtés

Avant de coder, trace le protocole existant : appareil affichant le QR, appareil qui scanne, utilisateur authentifié, sélection de l'élève, validation serveur et résultat de chaque côté. Ne suppose pas le sens du scan. Conserve ce sens s'il est sûr ; nomme les instructions « Sur l'autre appareil » avec une explication contextualisée.

### Écran affichant le QR et le code

L'écran actuel constitue une base à améliorer, pas à remplacer systématiquement. Grand QR central lisible, fond contrasté, marges libres de scan, code manuel lisible, consigne courte, état textuel et durée de validité réelle si disponible. Taille adaptative avec QR prioritaire, sans débordement ni décoration sur ses modules.

Un léger halo extérieur ou indicateur d'attente peut signaler l'activité. Prévoir apparition douce, changement de code, validation et disparition. Respecter mouvement réduit, contraste et performance. Aucun effet qui empêche le scan.

États : préparation ; actif ; validation en cours ; association confirmée ; expiré ; révoqué ; erreur ; réseau interrompu. Dès confirmation valide de l'association par le service autoritatif, retirer immédiatement QR ET code de l'écran, de l'arbre sémantique et des états restaurables. Puis afficher « Appareil connecté » avec destination utile. Ne laisse pas le code derrière un panneau de succès.

Un simple décodage caméra ne prouve pas une association réussie. Pendant validation, masquer/neutraliser la présentation si prévu par le protocole ; ne déclarer le code consommé qu'après réponse autoritative. Après expiration ou révocation confirmée, aucun code utilisable ne reste affiché. À la reprise de l'app, vérifier le statut avant de réafficher ; ne pas restaurer un ancien QR depuis un cache.

Invalider réellement un code, empêcher son rejeu, borner sa durée et l'associer au bon foyer exigent le serveur. Audite la capacité existante sans modifier le backend. Si elle manque, documente le contrat nécessaire et empêche une association réelle présentée comme sûre. Le frontend ne doit jamais prétendre garantir l'usage unique par une simple animation.

### Écran scanner

Implémente effectivement l'accès caméra et le décodage QR, en utilisant une dépendance déjà compatible ou une dépendance justifiée intégrée par le coordinateur. Une illustration de caméra n'est pas une fonctionnalité.

Mobile : vraie page de scan, viseur suffisamment grand, retour accessible et « Saisir le code » en alternative. Desktop/tablette : page centrée ou panneau adapté, aperçu vidéo confortable. Aucun bottom sheet mobile étiré sur desktop.

Demander la permission au moment d'ouvrir la caméra. Prévoir caméra absente, refus, refus durable, caméra occupée, erreur de démarrage, contexte web ne permettant pas la caméra, sélection de caméra si nécessaire. La saisie manuelle reste accessible. Ne pas confondre permission caméra pour scanner et droit d'activer la caméra de l'élève en cours.

Après lecture : suspendre les lectures répétées, valider le format attendu, ne jamais ouvrir une URL arbitraire contenue dans un QR, appeler le service existant, montrer progression puis succès réel ou erreur. QR inconnu, expiré, déjà utilisé, révoqué ou mauvais foyer : message simple et reprise possible. Ne pas révéler les données d'un autre foyer.

Arrêter/libérer la caméra à la sortie, à la mise en arrière-plan et après traitement selon cycle de vie. Gérer reprise, requêtes tardives après navigation, scans concurrents, rotation du code et reconnexion sans double association. Aucun token dans les logs, URLs, analytics ou captures de recette.

### Après association

Mettre à jour les appareils via source existante ; retour vers l'élève concerné. Appareil partagé : choix parmi profils autorisés puis PIN selon protocole existant, sans accès au compte tuteur. Retrait avec confirmation et réponse du service ; ne pas faire croire à une révocation distante sur suppression locale seulement.

## 8. États système et erreurs

Construis une famille visuelle commune, déclinée au bon endroit : erreur de bloc conserve le reste de la page ; erreur globale occupe la page. Un titre humain, une phrase utile, une action principale, éventuellement un lien secondaire. Pas de code technique exposé.

| État | Présentation et reprise |
|---|---|
| Chargement initial | Skeleton adapté ou progression ; aucune fausse donnée métier |
| Chargement prolongé | « La connexion prend plus de temps que prévu » ; réessayer ou revenir selon contexte |
| Hors ligne | « Vous êtes hors ligne » ; contenu en cache identifié si autorisé, action de reprise |
| Reconnexion | État discret, progression bornée, pas de boucle infinie ni multiplication des requêtes |
| Échec serveur | « Impossible de charger… » ; réessayer en conservant le contexte |
| 404 | « Cette page est introuvable » ; retour à l'accueil ou connexion selon session |
| Accès refusé | « Vous n'avez pas accès à cette page » ; retour sûr, sans fuite de données |
| Session expirée | Reconnexion avec retour vers la destination autorisée, sans boucle |
| Dossier en attente / suspendu | Statut exact et prochaine action permise, pas un écran vide |
| Aucun résultat / aucun cours | Explication pertinente, réinitialisation des filtres ou action d'inscription |
| Permission refusée | Explication contextuelle et alternative, notamment code manuel |
| Ressource supprimée / expirée | Message et retour contextualisé ; aucune page qui tourne indéfiniment |

Les seuils de timeout proviennent de la politique réseau du projet ou d'une configuration frontend centralisée explicitement documentée. Une tentative échouée ne devient jamais un succès. Annuler les opérations à la sortie et empêcher leur réponse tardive de rouvrir un écran.

## 9. Règles visuelles transversales

- Un objectif et un CTA dominant par écran/étape, actions secondaires discrètes mais accessibles.
- Moins de cartes imbriquées ; listes, séparateurs, espaces et typographie pour structurer selon high-fi.
- M3 et adaptation iOS pertinente ; pas de remplacement de la direction fournie par le thème Flutter par défaut.
- Tokens sémantiques, composants réutilisés, aucun style arbitraire répété dans les écrans.
- Clair/sombre complets. Si une seule variante est fournie, dériver l'autre sans inverser naïvement toutes les couleurs et documenter cette dérivation.
- Mise en page selon espace disponible : mobile, tablette, desktop ; navigation persistante adaptée, largeur de lecture raisonnable. Préserver clavier et scroll quand un champ prend le focus.
- Cibles tactiles au moins 48 dp, focus visible, lecteur d'écran, texte agrandi sans coupure, RTL pour les contenus concernés et formats locaux. Ne pas encoder un statut seulement par couleur.
- Animations discrètes, désactivables/réduites ; aucune animation ne remplace le texte d'un état.
- Employer Classe, Sayyid, Sayyida, Interface guidée. Pas de jargon interne, de codes de compétences ou de « mode enfant ».
- Noms, tarifs, photos, dates, capacités et métriques illustratifs des maquettes ne deviennent jamais des constantes métier.

## 10. Orchestration demandée à Claude

### Lot 0 : coordinateur, avant délégation d'écriture

Inspecte branche, état Git, agents actifs et instructions locales. Identifie la base réellement utilisable, sans reprendre aveuglément un ancien hash. Réserve les fichiers des autres chantiers. Aucun reset, stash du travail d'autrui ou écrasement.

Produis un dossier de pilotage compact avec :

- mapping existant -> cible des routes et fonctionnalités ;
- manifeste des high-fi et composants/tokens ;
- ownership de fichiers exacts ;
- interfaces consommées, fixtures isolées et dépendances backend ;
- tableau des contradictions et recette.

Le coordinateur possède seul le routeur global, le shell, le thème partagé, les exports communs, le point d'injection, les dépendances et les configurations caméra plateforme. Il prépare les composants et contrats partagés nécessaires avant la phase parallèle. Les agents métier soumettent une demande courte s'ils ont besoin d'un changement partagé.

### Lots délégués

| Agent | Parcours à livrer | Frontière |
|---|---|---|
| A - Admission | Auth visuelle et onboarding complet, branches, récapitulatif, reprise | Utilise le flux commun d'ajout d'élève, sans doublon |
| B - Foyer | Foyer, fiche élève, ajout personnel/proche, paramètres élève autorisés | Possède le formulaire élève partagé avec A après contrat stable |
| C - Cours | Accueil, classe, catalogue, planning, travail, ressources/progression, observation UI | Réutilise les services de classe/LiveKit existants |
| D - Appareils | Émetteur QR/code, scanner caméra, saisie, succès/erreurs, appareils partagés/PIN | Coordinateur seul pour dépendances/config globale |
| E - Compte et suivi | Mon compte et sous-pages, Historique et détail, notifications/support existants | Utilise les composants et services partagés |
| Q - Revue indépendante | Fidélité high-fi, parcours/routes, responsive/accessibilité, frontière sécurité | Lecture du code de production, défauts confiés au propriétaire |

Adapter le nombre d'agents aux capacités réelles ; les lots peuvent être séquencés. Aucun agent imaginaire ni validation de comité inventée. Q peut mener séparément les revues spécialisées UX/UI, navigation/accessibilité et appareil/sécurité ; préciser preuves et limites de chaque revue.

Un fichier = un propriétaire. Chaque agent reçoit : mandat, fichiers autorisés, références exactes, interfaces, sorties et critères de recette. Worktrees/branches isolés si adaptés au dépôt. L'agent ne modifie pas les fichiers partagés pour se débloquer. Pas de dépendances circulaires entre lots : stabiliser d'abord le formulaire élève, le contexte de sélection, les modèles de séance et les composants d'état.

Chaque lot livre un parcours navigable avec ses sous-écrans et erreurs. Le coordinateur intègre progressivement, vérifie routes et régressions, puis poursuit. Il ne redessine pas les contributions conformes lors de l'intégration. Pas de demande de validation à chaque détail réversible ; remonter uniquement les ambiguïtés qui changent réellement le produit ou une action externe non autorisée.

## 11. Recette et preuves exigées

La recette couvre tous les écrans de l'arbre, pas uniquement les cinq principaux. Tenir une matrice avec référence visuelle, route réelle, contenu, états, responsive, service, preuve et statut.

1. Toutes les destinations et CTA visibles conduisent au bon écran, état ou résultat réel. Aucun bouton décoratif, route orpheline, `TODO` maquillé ou impasse.
2. Parcours : inscription familiale sans parent élève -> ajout enfant -> choix classe -> accueil -> classe -> travail/historique ; puis création ultérieure du propre profil du parent sans altération des enfants.
3. Appareils : caméra réelle lorsque plateforme testable, alternative manuelle, expiration, scan invalide, double scan, succès confirmé, disparition immédiate QR/code, reprise après arrière-plan et retrait. Séparer preuve frontend simulée et association serveur réelle.
4. Navigation : changement de profil sans données croisées, retour stable, refresh web, liens directs autorisés, 404, accès refusé, session expirée.
5. États temporels : avant ouverture, T-20 selon politique, début, en cours, prolongation, fin, report/annulation, changement de fuseau et DST.
6. Fidélité : comparaison image source/capture à viewport identique pour chaque high-fi. Les golden tests ne suffisent pas à prouver la fidélité s'ils ont été générés depuis une UI incorrecte.
7. Responsive : petit mobile, mobile courant, tablette, desktop ; clair/sombre, texte agrandi, clavier, permissions refusées, réseau lent/coupé. Images QA sans secrets ni données personnelles réelles.
8. Exécuter analyse Flutter, tests significatifs ciblés puis builds accessibles des plateformes concernées. Mentionner iOS ou appareil physique non testable si environnement indisponible, jamais inventer PASS.
9. Vérifier que le diff n'introduit aucune modification backend et aucune régression des autres rôles via thème/routeur partagés. Les modifications globales restent limitées et justifiées.

Une simulation démontre un état frontend, pas l'autorisation serveur. Le retrait visuel du QR ne prouve pas l'invalidation. Un build réussi ne prouve pas le parcours caméra. Mentionne ces distinctions dans le bilan, sans bloquer les livrables indépendants.

## 12. Livraison et fin de mission

Livre le code sur la branche de travail autorisée, les captures comparatives, la matrice écrans/routes et une liste précise des dépendances backend restantes avec service attendu, entrée/sortie et impact. Pas de merge main, déploiement, migration distante ou nettoyage irréversible sans autorisation spécifique.

Rapport au directeur, bref : écrans/parcours réalisés ; conformité aux high-fi et écarts résiduels ; fonctions réellement branchées ; tests réellement exécutés ; blocages restants. Ne déclare pas « rôle tuteur terminé » si des sous-écrans du périmètre sont oubliés ou si une dépendance simulée est présentée comme fonctionnelle.

Commence par l'inventaire et le mapping, puis exécute les lots frontend autorisés. Ne t'arrête pas après avoir seulement rédigé un plan.



##Prompt étape obeservation tuteur:

Tu poursuis le chantier frontend Tuteur de Rewayah. Ce complément ajoute le parcours Observation aux lots déjà préparés et corrige certaines instructions précédentes. Intègre-le au plan commun, puis commence l’exécution. Ne recrée pas un chantier concurrent.

**1. Priorité absolue : mettre à jour les jetons de design avant les écrans**

La typographie officielle est :

* **DM Sans pour les titres en français** : titres de page, de section et autres styles de titres.
* **Jakarta pour les autres textes** : paragraphes, libellés, boutons, champs, navigation, légendes et statuts.

Jakarta est déjà déclarée dans les jetons : retrouve son nom technique exact et conserve cette déclaration. N’ajoute pas une seconde famille équivalente.

Inspecte les assets et le thème existants, puis corrige les styles sémantiques centralisés. Les widgets doivent consommer les jetons, sans `fontFamily` dispersé dans les pages. Préserve les polices dédiées à l’arabe et au Coran.

Vérifie les graisses disponibles, les accents français, le redimensionnement du texte et les thèmes clair/sombre. Ne réinitialise pas les autres jetons déjà conformes aux maquettes.

Le coordinateur est seul propriétaire de cette modification partagée. Il stabilise les jetons avant l’implémentation visuelle parallèle, puis contrôle leurs conséquences sur les autres rôles.

**2. Sources visuelles et corrections prioritaires**

Les trois planches jointes couvrent :

1. Parcours mobile et consentement.
2. Observation sur ordinateur et historique.
3. États particuliers et notices de présence.

Ouvre réellement les images et utilise fidèlement leurs compositions, composants et proportions. Complète les états absents avec le même langage visuel.

Les règles écrites ci-dessous prévalent sur les erreurs ou raccourcis éventuels des images :

* Le libellé **« Cours en cours » est interdit**. Employer « Séance en direct », « En direct » ou « En séance » selon le contexte.
* Deux visites maximum par séance, de deux minutes maximum chacune, par défaut.
* Aucun compteur illustratif, nom, date ou quota ne devient une constante métier.
* La typographie doit respecter DM Sans/Jakarta, même si une image générée semble employer une autre police.
* Les commandes montrées côté enfant ou enseignant ne sont jamais celles du tuteur observateur. Ces vignettes ne constituent pas un mandat de reconstruire leurs salles.

**3. Périmètre : frontend uniquement**

Conserve la frontière du prompt principal : UI, navigation, états, caméra déjà prévue dans les autres lots, adaptateurs et consommation des services existants.

Aucune migration, modification RLS/RPC, émission de token, nouvelle politique serveur ou refonte LiveKit dans ce lot.

Inspecte les capacités existantes. Si une règle ci-dessous exige une évolution backend absente, documente précisément cette dépendance. Réalise et teste les états frontend avec des fixtures isolées, mais n’active pas une fonctionnalité réelle avec une protection uniquement locale.

**4. Règles d’observation à remplacer dans les instructions actives**

La règle précédente « une visite et 120 secondes cumulées » est obsolète.

Valeurs par défaut :

* Maximum **2 visites** par séance.
* Maximum **120 secondes par visite**.
* Maximum **240 secondes au total**, sans possibilité de faire une seule visite de quatre minutes.
* Paramètres configurables par l’administration ; l’interface consomme la politique effective.

Le tuteur peut observer seulement si son enfant est présent dans la séance. Ne confonds pas caméra désactivée, coupure temporaire et absence. Une présence incertaine affiche une vérification, pas une absence inventée.

Le tuteur :

* Entend l’enseignant et tous les élèves dont le micro est actif.
* Voit le support partagé, l’enseignant et son propre enfant selon les médias autorisés.
* Ne dispose ni de micro, caméra, chat, réactions, annotations ou commandes pédagogiques.
* Ne voit pas le roster complet ni les fiches des autres élèves.

L’enseignant et l’enfant concerné voient une notice discrète de sa présence. Les autres élèves ne reçoivent aucune notification de cette visite. Employer « Votre maman… » uniquement si le lien familial est connu ; sinon « Votre parent… ».

Les autorisations, quotas et fins de visite doivent être garantis par le serveur existant. Le timer visuel ne constitue pas cette garantie.

**5. Parcours complet à raccorder**

Classe de l’enfant → disponibilité de l’observation → explication de première utilisation → connexion → observation → sortie → retour à la classe → historique et détail.

Prévoir :

* Deux visites disponibles, une visite restante, visites épuisées.
* Enfant absent, présence en vérification.
* Séance non commencée, terminée, observation désactivée.
* Chargement, connexion prolongée, échec, reconnexion.
* Caméra désactivée, aucun support partagé, support indisponible.
* Sortie volontaire, durée atteinte, fin de séance.

Aucun bouton sans destination ni état explicatif. Conserve le contexte de l’enfant au retour.

Avant l’entrée : afficher les visites disponibles et leur durée.
Pendant : afficher par exemple **« Visite 1/2 · 01:42 »**, correspondant à la visite actuelle.
Après : afficher le nombre réel de visites restantes.

Le compteur ne démarre pas pendant la lecture de l’explication ou une simple vérification préalable.

**6. Explication et consentement**

L’aide accessible depuis « Comment ça marche ? » explique :

« Vous disposez de deux visites de deux minutes par séance. Si un autre élève récite lors de votre première visite, vous pourrez revenir plus tard pour écouter votre enfant. Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe. »

Adapter les chiffres à la politique effective.

Dans l’onboarding, compléter le consentement existant avec cette information :

« Les parents des élèves présents peuvent observer brièvement la séance. Ils entendent l’enseignant et les élèves qui prennent la parole, y compris votre enfant. Ces visites permettent de suivre l’apprentissage sans interrompre la classe : les observateurs ne peuvent ni parler ni activer leur caméra. »

Prévoir les formulations adaptées au responsable légal et à l’élève adulte. Accord explicite, non précoché, enregistré par le mécanisme existant. La présence en classe ne remplace pas un accord effectivement recueilli.

Pour les comptes existants, vérifier le mécanisme de mise à jour des consentements. Ne pas les considérer automatiquement comme ayant accepté cette nouvelle information. Documenter toute dépendance backend.

**7. Salle d’observation**

Le support pédagogique domine. Les deux vignettes enseignant/enfant restent secondaires et ne couvrent jamais le document.

Commandes du tuteur uniquement :

* Couper/rétablir le son reçu.
* Agrandir le support.
* Quitter.

Le zoom est local et ne modifie pas le document partagé. Aucune fausse page du Coran : réutiliser les ressources vérifiées.

Adapter réellement mobile, paysage, tablette et ordinateur. Pas de bottom sheet mobile étiré sur desktop. Respecter clavier, lecteur d’écran, texte agrandi et réduction des animations.

Une interruption réseau ne doit ni simuler du direct ni remettre automatiquement le compteur à zéro.

**8. Historique des observations : obligatoire**

L’historique doit être conservé et consultable par le tuteur et l’administration. Ce n’est pas un enregistrement audio/vidéo.

Réutilise le style de l’Historique déjà conçu : sélecteur d’élève, filtres, lignes séparées, statuts discrets, accès au détail. Ajoute la distinction **« Séances / Observations »**, sans créer un second système d’historique.

Vue tuteur :

* Uniquement les observations auxquelles ses droits donnent accès.
* Regroupement lisible par séance et enfant.
* Date, classe, nombre de visites, durée totale et état.
* Détail : tuteur observateur, enfant, enseignant, entrée/sortie de chaque visite, durée et motif de fin.
* Fuseau horaire explicite et cohérent.

Vue administration :

* Consultation des observations autorisées.
* Recherche et filtres par tuteur, élève, classe, période et statut.
* Accès aux mêmes détails factuels.
* Réutilisation de la navigation et des composants admin existants ; coordonner les fichiers avec tout agent déjà actif sur ce rôle.

Aucune suppression ou édition de traces dans ce périmètre. Ne décide pas arbitrairement d’une durée de conservation. Une actualisation ou reconnexion ne doit pas faire perdre l’historique réel.

Consomme le journal persistant existant s’il est disponible. Sinon, livre l’UI avec la dépendance de persistance explicitement signalée : ne présente pas une liste locale ou fictive comme un historique enregistré.

**9. Orchestration avec les lots en attente**

* Coordinateur : jetons d’abord, contrats partagés, routeur, intégration.
* Agent Admission : consentement et aide de première utilisation.
* Agent Cours : entrée depuis la classe, observation, états et notices contextuelles.
* Agent Compte/Historique : liste et détail tuteur, consultation administrative coordonnée.
* Agent QA : fidélité aux planches, typographie, parcours et distinction simulation/service réel.

Un fichier a un seul propriétaire. Stabiliser les modèles partagés de politique et de visite avant les écritures parallèles.

Ne tranche pas silencieusement les points encore ouverts : quota partagé ou individuel entre responsables, plusieurs enfants dans une même séance, traitement exact d’une visite écourtée ou d’une déconnexion de l’enfant. Retrouve une décision canonique ; sinon isole le point sans bloquer les travaux indépendants.

**10. Recette avant livraison**

Prouver notamment :

* DM Sans sur les titres français, Jakarta sur les autres textes.
* Absence du libellé interdit.
* Première puis seconde visite ; troisième entrée refusée selon réponse serveur.
* Enfant absent : observation indisponible.
* Aucun moyen d’émettre du son ou de la vidéo côté tuteur.
* Notices réservées à l’enseignant et à l’enfant concerné.
* Sortie et reconnexion sans remise à zéro frauduleuse du quota.
* Historique, filtres et détail cohérents, sans données d’un autre foyer.
* Captures comparatives des écrans avec les high-fi.
* Aucun changement backend dans le diff.

Distingue clairement UI réalisée, simulation testée, service branché et fonctionnement réellement vérifié.

Ce complément débloque la préparation commune attendue : mets d’abord les jetons à jour, puis exécute les lots frontend autorisés. Aucun merge main, déploiement ou migration distante n’est autorisé par ce prompt.


---

