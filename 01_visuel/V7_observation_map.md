# V7 - Carte du parcours Observation tuteur (relevé visuel)

Agent : V7_observation_map. Phase lecture seule, aucun fichier du dépôt modifié.
Source unique : `D:\RA _APP\docs de lancement\tutuor image\tutor observation map.png` (1972 x 2106 px, PNG 32 bits ARGB, **fond transparent** (alpha 0), 96 dpi, 258 519 octets).

Images réellement ouvertes : l'image entière (affichée à 1873 x 2000, facteur 1,053 vers l'original), 6 tuiles pleine résolution et 5 zooms, tous dans `D:\RA _APP\pilotage-tuteur-v1\01_visuel\tuiles\V7_observation_map\` :

| Tuile | Zone d'origine (x, y, l, h) | Contenu lu |
|---|---|---|
| `t1_haut_gauche.png` | 0, 0, 1000, 760 | Quitter volontairement, Deux minutes écoulées, départs des connecteurs, retour gauche vers le direct |
| `t2_haut_droite.png` | 900, 0, 1072, 760 | Observation en direct, Séance terminée, Interruption ou reconnexion, Observation interrompue |
| `t3_milieu_gauche.png` | 0, 700, 1000, 760 | pastille Oui, Observer · visites restantes |
| `t4_milieu_droite.png` | 900, 700, 1072, 760 | Classe de l'enfant, Retour à la classe, Observation disponible ?, pastille Non, Motif affiché dans la classe |
| `t5_bas_gauche.png` | 0, 1380, 1000, 726 | Explication à la première utilisation, pastille Explication déjà vue, Connexion et vérification, Connexion impossible |
| `t6_bas_droite.png` | 900, 1380, 1072, 726 | fin de Connexion impossible, montée du retour vers Observer (zone droite vide) |
| `z1_typo_classe_enfant.png` | 960, 800, 300, 60 (x3) | typographie des nœuds |
| `z2_pill_deja_vue_et_oui.png` | 620, 1545, 290, 70 (x3) | typographie et forme des pastilles |
| `z3_decision_bord_pointille.png` | 1230, 960, 260, 150 (x3) | bordure pointillée du losange logique |
| `z4_fleche_et_coude.png` | 1330, 690, 120, 100 (x5) | coudes arrondis et pointes de flèche |
| `z5_fleche_haut_obs.png` | 930, 130, 80, 70 (x6) | flèche montante vers « Observation en direct » |

---

## 1. Manifeste

| Champ | Valeur |
|---|---|
| Fichier | `tutuor image\tutor observation map.png` |
| Nature | **Planche de direction : logigramme d'enchaînement**, pas un écran. Aucune maquette d'interface, aucun CTA, aucune barre de navigation, aucun avatar. |
| Statut | « planche de direction » (ni high-fi ni ancienne capture) |
| Thème | Clair (nœuds crème sur fond transparent). Aucune variante sombre. |
| Format | Diagramme 1972 x 2106 px, sans format d'appareil. Mesures en dp **non applicables** (pas de largeur mobile 390 dp de référence). |
| Rôle dans le mandat | Illustre le §5 du « Prompt étape observation tuteur » (parcours Classe → disponibilité → explication → connexion → observation → sortie → retour à la classe). Complète les deux high-fi `tuteur observation desktop light.png` et `mobile\tuteur observation mobile light.png` (relevés par d'autres agents, non ouverts ici). |
| Usage attendu | Source d'**enchaînements et d'états** pour l'agent Cours (routes, machine d'états). **Aucune valeur visuelle de cette planche ne doit devenir un token** : c'est le rendu par défaut d'un outil de diagramme (voir §5). |

---

## 2. Inventaire des nœuds (tous les textes, recopiés exactement)

Coordonnées en pixels de l'image d'origine (gauche, haut, droite, bas), mesurées par balayage alpha.

| # | Texte exact | Type | Boîte (L, T, R, B) | Taille |
|---|---|---|---|---|
| N1 | `Observation en direct` | état (écran salle) | 895, 16, 1340, 135 | 446 x 120 |
| N2 | `Séance terminée` | fin de visite | 962, 296, 1337, 415 | 376 x 120 |
| N3 | `Interruption ou reconnexion` | incident réseau | 1418, 296, 1954, 415 | 537 x 120 |
| N4 | `Quitter volontairement` | fin de visite | 98, 496, 563, 615 | 466 x 120 |
| N5 | `Deux minutes écoulées` | fin de visite | 643, 496, 1109, 615 | 467 x 120 |
| N6 | `Observation interrompue` | fin de visite | 1437, 496, 1935, 615 | 499 x 120 |
| N7 | `Classe de l’enfant` (apostrophe typographique U+2019) | point d'entrée | 914, 776, 1298, 895 | 385 x 120 |
| N8 | `Retour à la classe` | retour | 1379, 776, 1763, 895 | 385 x 120 |
| N9 | `Observation disponible ?` (espace avant « ? ») | **décision** (bord pointillé, fond plus clair) | 1244, 975, 1735, 1095 | 492 x 121 |
| P1 | `Oui` | étiquette d'arête (pastille) | 719, 1175, 810, 1228 | 92 x 54 |
| P2 | `Non` | étiquette d'arête (pastille) | 1521, 1175, 1620, 1228 | 100 x 54 |
| N10 | `Observer · visites restantes` (point médian U+00B7) | entrée (CTA dans la classe) | 508, 1308, 1021, 1427 | 514 x 120 |
| N11 | `Motif affiché dans la classe` | indisponibilité | 1312, 1308, 1830, 1427 | 519 x 120 |
| N12 | `Explication à la première` / `utilisation` (2 lignes) | aide première fois | 58, 1508, 543, 1677 | 486 x 170 |
| P3 | `Explication déjà vue` | étiquette d'arête (pastille) | 623, 1552, 905, 1605 | 283 x 54 |
| N13 | `Connexion et vérification` | chargement / contrôle | 396, 1769, 887, 1888 | 492 x 120 |
| N14 | `Connexion impossible` | erreur d'entrée | 643, 1969, 1095, 2088 | 453 x 120 |

Il n'y a aucun autre texte sur la planche (ni titre, ni légende, ni numéro, ni date, ni nom propre, ni compteur chiffré).

---

## 3. Enchaînements (arêtes relevées une à une sur les tuiles)

Connecteurs orthogonaux à coudes arrondis, pointes de flèche ouvertes (chevron). Le sens est donné par la pointe.

| De | Vers | Tracé (coordonnées d'origine) | Étiquette |
|---|---|---|---|
| N7 Classe de l'enfant | N9 Observation disponible ? | départ bas x≈1106, coude y≈936, arrivée x≈1408 | - |
| N8 Retour à la classe | N9 Observation disponible ? | vertical x≈1571 | - |
| N9 | N10 Observer · visites restantes | départ bas x≈1408, coude y≈1136, descente x≈765 | **Oui** |
| N9 | N11 Motif affiché dans la classe | vertical x≈1571 | **Non** |
| N10 | N12 Explication à la première utilisation | départ bas x≈636, coude y≈1468, arrivée x≈300 | - (implicite : première fois) |
| N10 | N13 Connexion et vérification | vertical x≈765 | **Explication déjà vue** |
| N12 | N13 Connexion et vérification | départ bas x≈300, coude y≈1689, arrivée x≈642 | - |
| N13 | N1 Observation en direct | départ haut x≈519, coude y≈1729, remonte tout le bord gauche x≈16, coude y≈176, flèche montante x≈958 | - (succès) |
| N13 | N14 Connexion impossible | départ bas x≈642, coude y≈1929, arrivée x≈793 | - (échec) |
| N14 | N10 Observer · visites restantes | départ haut x≈945, coude y≈1468, flèche montante x≈894 | - (nouvel essai) |
| N1 | N4 Quitter volontairement | départ x≈1022, coude y≈215, arrivée x≈330 | - |
| N1 | N5 Deux minutes écoulées | départ x≈1086, coude y≈255, arrivée x≈876 | - |
| N1 | N2 Séance terminée | vertical x≈1150 | - |
| N1 | N3 Interruption ou reconnexion | départ x≈1214, coude y≈215, arrivée x≈1597 | - |
| N3 | N1 Observation en direct | départ haut x≈1877, coude y≈176, flèche montante x≈1277 | - (reconnexion réussie) |
| N3 | N6 Observation interrompue | vertical x≈1677 | - (reconnexion échouée) |
| N4 | N8 Retour à la classe | départ x≈330, coude y≈735, arrivée x≈1455 | - |
| N5 | N8 Retour à la classe | départ x≈876, coude y≈695, arrivée x≈1531 | - |
| N2 | N8 Retour à la classe | départ x≈1143, coude y≈655, arrivée x≈1609 | - |
| N6 | N8 Retour à la classe | vertical x≈1686 | - |

Nœud sans sortie : **N11 Motif affiché dans la classe** (terminal). Aucune arête vers l'Historique.

### Lecture en boucle (ce que la planche prescrit)

1. Entrée : Classe de l'enfant → décision serveur « Observation disponible ? ».
2. Non → le motif s'affiche **dans la classe** (pas un écran séparé).
3. Oui → CTA « Observer » accompagné des visites restantes.
4. Première utilisation → explication, puis connexion. Explication déjà vue → connexion directe.
5. Connexion et vérification → succès : salle « Observation en direct » ; échec : « Connexion impossible » puis retour au CTA Observer (nouvel essai).
6. En direct, quatre sorties : Quitter volontairement, Deux minutes écoulées, Séance terminée, Interruption ou reconnexion.
7. Interruption : soit reconnexion vers le direct, soit « Observation interrompue ».
8. Toutes les fins mènent à « Retour à la classe », qui **ré-interroge la disponibilité** : c'est la boucle de la deuxième visite (Oui si une visite reste, Non avec motif « visites épuisées » sinon).

---

## 4. Fiches par état (nœud → route logique du mandat §4)

La planche ne dessine pas d'écran : chaque fiche indique l'état à produire, la route logique et le composant probable. Les compositions visuelles viennent des high-fi observation desktop/mobile et de la classe, pas de cette planche.

| Nœud | Route logique probable | Nature UI | État | Clé i18n existante la plus proche (dépôt, lecture seule) |
|---|---|---|---|---|
| N7 Classe de l'enfant | `/tuteur/classes/:classeId` | bloc Observation de l'écran Classe | nominal | `observation.entree.titre` « Observer la séance » (`assets/i18n/fr.i18n.json:2049`) |
| N9 Observation disponible ? | aucune (logique) | résultat de la politique effective renvoyée par le serveur | décision | `observation.refus.*` (`fr.i18n.json:2062-2070`) |
| N10 Observer · visites restantes | `/tuteur/classes/:classeId` | CTA principal du bloc + mention « N visites de D min » | disponible (2 restantes / 1 restante) | `observation.entree.titre`, `observation.visite.visites` « Visite {rang} sur {total} » (`:2084`) |
| N11 Motif affiché dans la classe | `/tuteur/classes/:classeId` | ligne d'état dans le bloc, pas de CTA mort | indisponible | `refus.quotaVisites` (`:2064`), `refus.tempsEpuise` (`:2065`), `refus.seanceNonActive` (`:2067`), `refus.horsFenetre` (`:2068`), `refus.politiqueDesactivee` (`:2063`), `refus.lienTuteur` (`:2066`), `refus.capaciteAbsente` (`:2070`) |
| N12 Explication à la première utilisation | `.../observer` (étape 0) ou feuille modale depuis la classe, plus lien « Comment ça marche ? » toujours disponible | aide, compteur **non démarré** | première fois | `observation.entree.tuteurIntro` (`:2050`) à remplacer par le texte du mandat §6 |
| N13 Connexion et vérification | `.../observer` | chargement borné, compteur **non démarré** | chargement / connexion prolongée | aucune clé dédiée « connexion prolongée » repérée |
| N14 Connexion impossible | `.../observer` puis retour classe | erreur de page avec « Réessayer » ramenant au CTA | échec | `refus.indisponible` (`:2069`) |
| N1 Observation en direct | `.../observer` (non restaurable par lien direct) | salle : support dominant, 2 vignettes, commandes son/agrandir/quitter, « Visite 1/2 · 01:42 » | en direct | `observation.visite.*` (`:2072-2085`) ; titre existant « Observation en cours » (`:2073`) |
| N3 Interruption ou reconnexion | `.../observer` | bandeau/surimpression de reconnexion dans la salle | reconnexion | `fin.deconnexion` « La connexion a été perdue. » (`:2091`) |
| N4 Quitter volontairement | `.../observer` → classe | confirmation de fin | sortie volontaire | `fin.sortieVolontaire` (`:2087`) |
| N5 Deux minutes écoulées | `.../observer` → classe | fin automatique | durée atteinte | `fin.quotaAtteint` « Votre temps d'observation est écoulé. » (`:2088`) |
| N2 Séance terminée | `.../observer` → classe | fin automatique | fin de séance | `fin.seanceTerminee` (`:2089`) |
| N6 Observation interrompue | `.../observer` → classe | fin par serveur ou réseau | interrompue | `fin.revocationServeur` (`:2090`) |
| N8 Retour à la classe | `/tuteur/classes/:classeId` | navigation retour, élève sélectionné conservé, disponibilité rechargée | retour | - |

---

## 5. Relevé visuel (valeurs mesurées)

Mesures par `System.Drawing.Bitmap.GetPixel`, coordonnées de l'image d'origine.

| Élément | HEX mesuré | Coordonnées de la mesure |
|---|---|---|
| Fond de planche | transparent (`#000000`, alpha 0) | (5,5), (1000,1000), (1900,2000) |
| Remplissage des nœuds (tous, y compris échecs) | `#FFF6D9` | (1000,40), (1350,1330), (700,2000), (1460,520) |
| Remplissage du nœud de décision et des pastilles | `#FFFBED` | (1300,1010), (1450,976), (1530,1200), (734-795,1180) |
| Bordure des nœuds, des pastilles et connecteurs | `#E5DDC3` | bordure (1000,16) et (1000,135) ; connecteur (15-16,1000) et (1149-1150,500) |
| Texte (nœuds et pastilles) | `#6E5400` (anti-crénelage `#775E0D`, `#907A33`) | (1250,72-73), histogramme des boîtes N1, N2, N12, P1-P3 |

Constats :

- **Aucune couleur de statut** : « Connexion impossible », « Observation interrompue » et « Observation en direct » ont exactement le même fond `#FFF6D9`. Pas de vert, orange, rouge, gris, pas de bandeau d'alerte, pas de CTA plein ni doux, pas d'onglet actif : ces tokens ne peuvent pas être relevés sur cette planche.
- Contraste texte `#6E5400` sur `#FFF6D9` : environ 6,6:1 (conforme AA), à titre indicatif seulement.
- Nœuds : hauteur uniforme 120 px (170 px pour le nœud sur deux lignes), rayon d'angle ≈ 26-27 px, bordure 1 px.
- Pastilles d'arête : hauteur 54 px, forme en stade (rayon = demi-hauteur), bordure 1-2 px.
- Nœud de décision : bordure **pointillée** 2 px, tirets de 5 px et espaces de 3 px (balayage y=976, x 1300-1360), fond `#FFFBED`.
- Connecteurs : trait 2 px `#E5DDC3`, coudes arrondis (rayon ≈ 10-12 px), pointes en chevron ouvert d'environ 14 x 8 px.
- Texte des nœuds : hauteur d'ascendante 24 px (« Observation en direct », y 63-86), soit une police d'environ 32-33 px. En supposant un export à 2x, cela donne environ 16 px de corps. Pastilles : hauteur de capitale 19 px (« Oui »), soit environ 26-27 px (13-14 px à 2x).
- Espacements verticaux entre rangées de nœuds : 161 px (N1 → N2/N3), 81 px (N2/N3 → N4-N6), 161 px (N4-N6 → N7/N8), 80 px (N7/N8 → N9).
- **Typographie observée** : sans-serif humaniste de type **Segoe UI Semibold** (police Windows par défaut de l'outil de diagramme ; « t » à fût biseauté, « a » à deux étages, apostrophe typographique). La police n'appartient pas à la direction de Rewayah. La règle écrite s'applique : **DM Sans pour les titres français, Plus Jakarta Sans pour tout le reste**. Rappel du BRIEF : aucune de ces deux familles n'est encore déclarée dans le dépôt, qui utilise `InstrumentSans` et `BricolageGrotesque`.
- Recherche en lecture seule : aucune de ces couleurs (`FFF6D9`, `6E5400`, `E5DDC3`, `FFFBED`) n'existe dans `RA -OFFICIAL-APP\lib`. Ce ne sont pas des tokens de l'application, et elles ne doivent pas le devenir.

---

## 6. Couverture du mandat : ce que la carte montre, ce qui manque

Comparaison avec le §5 du « Prompt étape observation tuteur ».

| État exigé par le mandat | Sur la carte ? | Remarque |
|---|---|---|
| Deux visites disponibles / une visite restante | oui (N10, générique) | le chiffre vient de la politique effective |
| Visites épuisées | implicite (N9 Non → N11) | le motif doit être explicite |
| Enfant absent | implicite (N11) | |
| **Présence en vérification** | **non** | la décision N9 est binaire (Oui/Non) : un troisième résultat « Présence en cours de vérification » est nécessaire, sans absence inventée |
| Séance non commencée / terminée / observation désactivée | implicite (N11) ; « Séance terminée » en sortie de direct | |
| Chargement | oui (N13) | |
| **Connexion prolongée** | **non** | à ajouter dans N13 (« La connexion prend plus de temps que prévu », §8 du prompt principal) |
| Échec | oui (N14) | |
| Reconnexion | oui (N3, boucle vers N1) | |
| **Caméra de l'enfant désactivée, aucun support partagé, support indisponible** | **non** | sous-états de la salle N1, pris dans les high-fi |
| Sortie volontaire / durée atteinte / fin de séance | oui (N4, N5, N2) + N6 | |
| **Historique et détail après le retour à la classe** | **non** | le parcours du mandat se termine par « historique et détail » : l'onglet « Séances / Observations » doit rester accessible depuis la classe et depuis Historique |
| **Notices enseignant / enfant** | **non** | voir la planche « états particuliers et notices de présence » |
| **Annuler pendant l'explication ou la vérification** | **non** | un retour sans consommer de visite est à prévoir (N12 et N13 n'ont aucune sortie arrière) |
| « Comment ça marche ? » accessible à tout moment | **non** (première fois seulement) | le lien doit rester visible dans le bloc Observation, même après « Explication déjà vue » |

---

## 7. Erreurs et raccourcis de la planche à NE PAS reproduire

1. **« Deux minutes écoulées » fige une durée.** Le mandat impose des valeurs par défaut configurables par l'administration (2 visites, 120 s par visite, 240 s au total, jamais une visite unique de 4 minutes). Le libellé UI doit venir de la politique, par exemple « Durée de visite atteinte » ou la clé existante `fin.quotaAtteint`. Aucune constante `120` ni `2` dans le frontend. La règle « 1 visite / 120 s cumulées » est obsolète.
2. **Boucle « Interruption ou reconnexion » → « Observation en direct ».** Une reconnexion ne doit ni simuler du direct ni remettre le compteur à zéro. Le temps restant est relu auprès du serveur (clé existante `visite.budgetIncertain` si l'information n'est pas confirmée). L'image vidéo ne doit pas être présentée comme en direct pendant la coupure.
3. **Boucle « Connexion impossible » → « Observer ».** La carte ne dit pas si l'échec consomme une visite. Le frontend ne décrémente rien localement : il recharge les visites restantes auprès du serveur. Point ouvert à consigner (visite écourtée ou échouée, mandat §9).
4. **Décision binaire « Observation disponible ? ».** Elle ignore « présence en vérification ». Il ne faut jamais afficher « enfant absent » sur une simple déconnexion ou une caméra coupée. La clé existante `visite.enfantAbsent` (« Votre enfant n'a pas d'image ouverte. », `fr.i18n.json:2079`) mélange absence et caméra désactivée : incohérence de nommage à signaler à l'agent Cours.
5. **« Classe de l'enfant ».** C'est une étiquette de diagramme, pas un texte d'écran. À l'écran, le prénom de l'élève s'affiche. Le propre profil du parent n'est jamais appelé « enfant ». L'observation suppose que l'élève soit présent et que le lien tuteur soit valide (`refus.lienTuteur`).
6. **« Observer · visites restantes ».** Le CTA du mandat est « Observer la séance ». Les visites restantes et leur durée apparaissent en information secondaire avant l'entrée. Pendant la visite, le format est « Visite 1/2 · 01:42 » (mm:ss). Le dépôt utilise aujourd'hui « Visite {rang} sur {total} » et « {secondes} s restantes » (`fr.i18n.json:2083-2084`) : écart de format à arbitrer par l'agent Cours.
7. **Compteur.** Selon la carte, l'explication (N12) et la vérification (N13) précèdent le direct. Le compteur ne démarre qu'à l'entrée confirmée par le serveur dans N1, jamais pendant l'explication ou la vérification.
8. **Accès direct à la salle.** La carte n'entre dans le direct que par N13 ou N3. `.../observer` ne doit pas restaurer une salle par lien direct, rafraîchissement ou état restauré. On repasse toujours par « Connexion et vérification » (mandat §4 : la salle éphémère n'est pas un lien public).
9. **« Explication déjà vue ».** La mémorisation n'est pas un secret, mais si aucun service ne la conserve par compte, un stockage local par appareil est acceptable et doit être documenté. « Comment ça marche ? » reste accessible dans tous les cas.
10. **Libellé interdit.** La carte ne contient pas « Cours en cours » (conforme). Garder « Observation en direct », « En direct » ou « En séance ». Le titre existant « Observation en cours » (`fr.i18n.json:2073`) n'est pas le libellé interdit, mais on peut l'aligner sur « Observation en direct » de la carte.
11. **Notice côté enfant.** Hors de cette planche, la clé existante `annonce.enfantIndicateur` « Ton tuteur regarde le cours » (`fr.i18n.json:2096`) contredit le mandat, qui demande « Votre maman… » si le lien est connu et « Votre parent… » sinon. À transmettre à l'agent Cours (source : planche 3).
12. **Styles de diagramme.** Ne transformer en tokens ni le crème `#FFF6D9`, ni le brun `#6E5400`, ni Segoe UI, ni les nœuds de 120 px, ni le pointillé. Ce sont les réglages par défaut du logigramme.

---

## 8. Recommandation de machine d'états pour l'agent Cours (dérivée de la carte et du mandat)

`classe.disponibilite` ∈ { disponible(restantes, dureeMax, totalRestant), indisponible(motif), verificationPresence, chargement, erreur } → CTA « Observer la séance » →
`observation` ∈ { explication (compteur arrêté), connexion (compteur arrêté, prolongée après seuil centralisé), echecConnexion → retour classe, direct(visite, total, restant depuis le serveur), reconnexion (compteur relu, pas de faux direct), fin(motif ∈ sortieVolontaire | dureeAtteinte | seanceTerminee | interrompue) } → retour classe → rechargement de `classe.disponibilite`. Depuis la classe, on garde l'accès à Historique > Observations.

Toutes les autorisations, les quotas et les fins sont garantis par le serveur. Le timer affiché n'est qu'un reflet.
