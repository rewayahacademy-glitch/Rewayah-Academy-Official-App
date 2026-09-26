# Maquettes Admin fournies par le directeur (26/09/2026)

Le directeur a fourni ces maquettes le 26/09/2026. Elles font foi pour la mise en page. Le directeur aime ce layout.

On ne redessine rien, on applique la méthode tuteur : relever ce que montre l'image, puis corriger ses erreurs par écrit.

**Ordre de priorité** : règles gelées (DESIGN-GOV) > textes exacts de la spec 03 V1.2 > libellés réels du code (AD-1) > image.

## Les 6 images de l'étape AD-3 (complètes)

| Fichier | Écran |
|---|---|
| `IMG-ADM-02A_desktop_sombre.png` | 02A, file des dossiers, en maître-détail avec la revue 02B à droite |
| `IMG-ADM-02C_desktop_sombre.png` | 02C, visionneuse de pièce (modale) |
| `IMG-ADM-02D_desktop_sombre.png` | 02D, motif du refus (modale) |
| `IMG-ADM-02A-02B-02E_mobile.png` | 02A mobile clair, 02B mobile sombre, 02E confirmation de validation, mobile clair |

## Coque admin (`coque/`)

- `ADMIN-SHELL-01` : Accueil (vue d'ensemble).
- `ADMIN-SHELL-02` : liste-détail des opérations.
- `ADMIN-SHELL-03` : collection et inspecteur.

**Pour ce lot**, seule la coque visible sur 02A est mise en place :
- barre latérale de 288, avec « Rewayah » en tête et le pied « Admin · Administration » ;
- élément actif sur fond discret ;
- en-tête de page : titre, sous-titre, bouton thème et bouton profil à droite ;
- tiroir sur mobile, jamais de barre basse (spec l.1520).

**Entrées de la barre latérale**, celles de 02A : Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit.
- Elles pointent vers les routes existantes.
- Aucune page nouvelle n'est créée derrière.
- Tout écart avec le code existant (entrée absente, autre libellé) est noté dans le relevé et soumis au directeur. On n'invente rien.

**On ne construit pas le contenu des images SHELL** : ni le tableau d'accueil, ni l'espace de traitement, ni la collection pédagogie. Ce sont des références pour la suite du rôle admin (étape AD-X, plus tard).

## Explorations (`exploration/`) : non retenues

**Une seule exception** : la fenêtre « ADM-02.4 · Paramètre Super Admin » (EXPLO-2, en bas à droite). Elle sert de référence de disposition pour AD-9, le réglage de genre. Les textes restent ceux de la spec (§15, l.1197).

**Tout le reste est exclu** :
- les onglets Familles / Enseignants ;
- la recherche et les filtres ;
- les onglets Documents / Historique ;
- le téléchargement de la pièce ;
- les boutons radio Conforme / Non conforme ;
- la barre basse mobile.

**Interdit** : les photos de personnes et les fausses cartes d'identité réalistes (« République française »).

## Rectifications relevées (à appliquer, sans redessiner)

1. **02A, bureau** : les dates de la file passent à la ligne (« 25 sept. / 2026 »). Elles doivent tenir sur une ligne. Si la largeur de 336 manque, la pastille d'état passe sous le nom.
2. **02A et 02B** :
   - le titre « Dossier de Aïcha Benali » doit faire l'élision : « Dossier d'Aïcha Benali » ;
   - la règle d'élision vaut pour tout prénom commençant par une voyelle ;
   - sinon, reprendre le texte exact de la spec.
3. **Vérifications 1, 2, 3** : les barres grises sont volontaires. Elles sont remplacées par les 3 libellés réels relevés en AD-1. Aucun libellé inventé (les libellés des explorations ne comptent pas).
4. **02B, mobile** :
   - le bouton « Refuser le dossier » est coupé au bord gauche. Les deux boutons doivent être entiers, dans la marge de 16 ;
   - « Valider le dossier » se place au bord de fin (trailing) ;
   - si la largeur manque, les deux boutons passent sur deux lignes, sans pleine largeur sur ordinateur (contrat B).
5. **02C** :
   - la pièce de démonstration porte la mention visible « Document fictif » ;
   - la croix et « Fermer » ramènent toutes deux le focus sur « Voir la pièce » (spec l.1030) ;
   - Échap ferme la fenêtre.
6. **02D** :
   - le texte d'aide répète le texte indicatif du champ ;
   - le texte indicatif ne doit porter aucune information obligatoire ; garder l'aide sous le champ ;
   - erreur si le champ est vide : « Indiquez le motif du refus. » (spec l.1056).
7. **02E** : le titre est « Valider ce dossier ? » (spec l.1106). Le texte explicatif est celui de la spec, pas celui de l'image s'ils diffèrent.
8. **Tous les écrans** : les données visibles sont synthétiques, avec la mention « Démonstration ». Aucune vraie identité.
9. **Tous les écrans** : les états absents des images (chargement, vide, erreur, résultat inconnu…) suivent la spec et les composants partagés. Pas de nouvelle image.

L'étape AD-3R complète cette liste après AD-1. La confrontation se fait avec les libellés réels et les textes de la spec, sans aucun redessin.

## Relevé AD-3R (26/09/2026, poste A) : textes et rectifications par image

Ce relevé complète les 9 rectifications ci-dessus. Il ne les remplace pas.

Chaque image a été contre-vérifiée contre la spec 03 V1.2, 01_RELEVE.md, UX_REVIEW_03_ADMIN_DOSSIERS.md, DESIGN-GOV et le code `D:\RA_TUTEUR\admin` (lecture seule).

Harmonisation : le fuseau des dates s'écrit « (zone IANA) », comme la spec l.1929. « (Europe/Paris) » était inventé.

Les questions ouvertes sont regroupées, sans doublon, à la fin (« Questions au directeur »).

### IMG-ADM-02A_desktop_sombre.png (1440 x 900, sombre) : coque, 02A et 02B en maître-détail

| Zone | Dans l'image | Texte à appliquer | Source | Rectification |
|---|---|---|---|---|
| Coque, barre latérale, tête | « Rewayah » | « Rewayah » | fr.i18n.json:1738 (admin.motSymbole) ; 00_MAQUETTES l.25 | aucune |
| Coque, barre latérale, entrée 1 | icône maison + « Accueil » | « Accueil », vers /admin | fr.i18n.json:1723 ; 01_RELEVE l.51-52 (admin_domaine.dart:118-127) | aucune |
| Coque, barre latérale, entrée 2 | icône document + « Opérations » | « Opérations », vers /admin/operations | fr.i18n.json:1724 ; 01_RELEVE l.53 | Libellé conforme. L'icône est celle de Finance : reprendre l'icône d'admin_domaine.dart, sans en dessiner de nouvelle. |
| Coque, barre latérale, entrée 3 (active) | « Personnes » sur fond discret, en gras | « Personnes », actif sur /admin/personnes/*, état « page courante » exposé en sémantique | fr.i18n.json:1725 ; spec §9 l.585 ; spec §20 l.1573 (jamais par la couleur seule) | Libellé conforme. L'état actif est marqué par autre chose que la teinte (la graisse) et exposé en sémantique. |
| Coque, barre latérale, entrée 4 | « Pédagogie » | « Pédagogie » | fr.i18n.json:1726 ; 01_RELEVE l.55 | aucune |
| Coque, barre latérale, entrée 5 | « Finance », même rendu que les autres | « Finance », visible mais inerte, atténuée en inkFaint, sans lien (chemin null) | fr.i18n.json:1727 ; 01_RELEVE l.56 et l.60 (admin_domaine.dart:99 ; admin_shell.dart:191-213) | Finance s'affiche atténuée et inerte, pas comme une entrée cliquable. |
| Coque, barre latérale, entrée 6 | « Configuration » | « Configuration » | fr.i18n.json:1728 ; 01_RELEVE l.57 | aucune |
| Coque, barre latérale, entrée 7 | « Sécurité et audit » | « Sécurité et audit » | fr.i18n.json:1729 ; 01_RELEVE l.58 | Aucune. « Direction » (8e entrée) reste masquée : voitDirection vaut false (01_RELEVE l.59, session_state.dart:140). |
| Coque, pied de la barre latérale | avatar « AD », « Admin », « Administration » | Initiales « AD », « Admin », « Administration » | 00_MAQUETTES l.25 ; fr.i18n.json:1475 (comptes.roleAdmin) ; pied absent d'AdminShell (01_RELEVE l.62) | Aucune sur le texte. Pied nouveau à construire dans AdminShell, avec AvatarTile existant (avatar_tile.dart:29). Données synthétiques seulement. |
| En-tête de page, titre | « Dossiers à valider » | « Dossiers à valider » | spec §9.7 l.653 ; fr.i18n.json:896 (dossiers.titre) | Aucune sur le texte. Le retour manque : EntetePage + DisqueRetour « Retour » (fr.i18n.json:5) vers /admin, au leading (spec §26 ter l.1923 et l.1933 ; UX_REVIEW modif. 5 l.134 ; 01_RELEVE l.63). |
| En-tête de page, sous-titre | « Examinez les dossiers prêts pour une décision. » | « Examinez les dossiers prêts pour une décision. » | spec §9.7 l.655 ; absent du code (01_RELEVE l.62) | Aucune. Clé i18n à créer. |
| En-tête, bouton icône 1 (trailing) | disque, icône de contraste, sans libellé | Libellé accessible « Thème sombre » ou « Thème clair » selon l'état | 00_MAQUETTES l.27 ; spec §19.3 l.1548 ; fr.i18n.json:92-93 ; spec §20 l.1572 | Libellé accessible obligatoire. Cible d'au moins 48 dp (environ 44 px mesurés). Bouton absent du code (01_RELEVE l.62). |
| En-tête, bouton icône 2 (trailing) | disque, icône de profil, sans libellé | Libellé accessible « Mon compte » | fr.i18n.json:1736 (admin.compte) ; 01_RELEVE l.61 (admin_shell.dart:459-528) | Libellé accessible obligatoire. Cible d'au moins 48 dp (environ 44 px mesurés). |
| En-tête, éléments absents | ni recherche de navigation ni cloche | Recherche existante : « Recherche », indication « Rechercher un écran ». Cloche « Notifications » : seulement si les notifications sont réellement disponibles. | spec §19.3 l.1547 ; fr.i18n.json:1731-1733 ; 01_RELEVE l.61 | La spec prime sur l'image : la recherche reste. La cloche peut disparaître tant qu'aucune notification n'existe. À confirmer. |
| Mention démonstration | absente | « Démonstration », mention visible | spec §26 quater l.2053 ; 00_MAQUETTES rectif. 8 | Ajouter la mention. Placement à trancher. |
| 02A, compteur de la file | « 4 dossiers en attente » | « {n} dossiers en attente » ; singulier « 1 dossier en attente » ; seulement si le serveur fournit un total fiable | spec §9.4 l.611 ; fr.i18n.json:899-900 | Texte conforme. dossiers_en_attente() rend une ligne par pièce, pas par personne (01_RELEVE l.151) : le compteur doit compter des personnes, sinon il est masqué. En démonstration, le port le fournit. |
| 02A, action d'en-tête de la file (trailing) | « Actualiser » (lien tertiaire lilas) | « Actualiser les dossiers » | spec §26 ter l.1945 et l.1942 ; spec §18 l.1454 | Libellé complété. ActionPrincipale tertiaire, cible d'au moins 48. Pendant l'actualisation : « Actualisation des dossiers… » (spec l.1937). |
| 02A, avatars d'initiales (lignes et en-tête du détail) | disques « AB », « YD », « FZ », « OB », et « AB » dans le détail | Initiales décoratives, exclues de la sémantique, via AvatarTile / _Initiales | spec §9.4 l.614-619 (la ligne montre « seulement » nom, type, ancienneté, état, chevron) ; avatar_tile.dart:29 et :95 ; aucun avatar dans dossiers_page.dart | Élément non prévu par §9.4. S'il est gardé : décoratif, composant existant, sans photo (00_MAQUETTES l.49). À confirmer. |
| 02A, ligne 1 (sélectionnée) | « Aïcha Benali », « Enseignant · 25 sept. / 2026 » (date coupée), « À revoir », chevron | « Aïcha Benali » ; « Enseignant · 25/09/2026 à HH:mm (zone IANA) » ; pastille d'état (ligne dédiée) ; chevron start/end ; libellé accessible « Ouvrir le dossier d'Aïcha Benali » | spec §9.4 l.614-619 ; §26 ter l.1929 et l.1945 ; fr.i18n.json:1824 ; 00_MAQUETTES rectif. 1 et 2 | Date sur une ligne, au format de la spec. Si 336 ne suffit pas, la pastille passe sous le nom. Sélection invisible dans l'image : barre d'accent ou graisse en plus de la teinte, plus Semantics(selected). Élision « d'Aïcha » (rectif. 2). |
| 02A, ligne 2 | « Yusuf Diallo », « Tuteur · 25 sept. 2026 », « À revoir », chevron | « Yusuf Diallo » ; « Tuteur · 25/09/2026 à HH:mm (zone IANA) » ; libellé accessible « Ouvrir le dossier de Yusuf Diallo » | fr.i18n.json:1825 (roles.guardian) ; spec §26 ter l.1929 et l.1945 ; P-ADM-08 l.1881 | Date au format de la spec. |
| 02A, ligne 3 | « Fatima Zahra », « Enseignante · 24 sept. / 2026 », « À revoir », chevron | « Fatima Zahra » ; « Enseignant · 24/09/2026 à HH:mm (zone IANA) » | spec §9.4 l.616 et §10.11 l.873 ; fr.i18n.json:1824 et 1478 (aucune forme féminine) | « Enseignante » devient « Enseignant ». Date sur une ligne. |
| 02A, ligne 4 | « Omar Bah », « Tuteur · 24 sept. 2026 », « À revoir », chevron | « Omar Bah » ; « Tuteur · 24/09/2026 à HH:mm (zone IANA) » | fr.i18n.json:1825 ; spec §26 ter l.1929 | Date au format de la spec. |
| 02A, pastille d'état des lignes | « À revoir », point lilas, sur les 4 lignes | Cas nominal : « En cours de vérification ». Sur état serveur explicite : « Aucune pièce déposée », « Pièce hors de votre portée » (si la politique de genre est active) | spec §18.1 l.1467 ; spec §9.4 l.618 ; fr.i18n.json:905 et 907 ; dossiers_page.dart:251-256 | « À revoir » n'a aucune source. Le lexique de la spec passe avant « À vérifier » du code (fr.i18n.json:1483, état d'une pièce). Option à confirmer : pas de pastille nominale, comme le code. |
| 02B, en-tête du détail | « Dossier de Aïcha Benali », « Enseignant · Déposé le 25 sept. 2026 », « À revoir » | « Dossier d'Aïcha Benali » ; « Enseignant · Déposé le 25/09/2026 à HH:mm (zone IANA) » ; pastille « En cours de vérification » | spec §10.11 l.871 et l.873 ; fr.i18n.json:901 ; spec §26 ter l.1929 ; 00_MAQUETTES rectif. 2 | Élision. Le code n'affiche que dd/MM/yyyy (dossiers_page.dart:453-455 ; 01_RELEVE l.269). Pastille comme la file. Le titre doit pouvoir recevoir le focus. |
| 02B, carte Identité et dossier, titre | « Identité et dossier » | « Identité et dossier » | spec §10.11 l.875 ; §10.7 | aucune |
| 02B, carte Identité et dossier, lignes | Nom Benali ; Prénom Aïcha ; Type de dossier Enseignant ; État du dossier À revoir | Nom Benali ; Prénom Aïcha ; Type de dossier Enseignant ; État du dossier En cours de vérification | spec §10.7 l.807-811 ; spec §18.1 l.1467 ; LigneCleValeur (contrat C, §4 bis.3 l.270) | Libellés conformes. État comme la pastille. « Date de dépôt » facultative (déjà dans le sous-titre). Rectangle à filets conforme (§10.7 l.799-801). Grille 2 x 2 acceptable si l'ordre de lecture est Nom, Prénom, Type, État. |
| 02B, carte Pièce d'identité | « Pièce d’identité » (apostrophe courbe) ; icône ; « Carte d’identité » sur deux lignes ; « Pièce disponible » ; « Voir la pièce » | « Pièce d'identité » ; « Carte d'identité » ; état de disponibilité (texte à valider) ; « Voir la pièce » | spec §10.8 l.817-824 et §10.11 l.877-879 ; fr.i18n.json:421 (kyc.carteIdentite), depot_piece_page.dart:163-164 ; état : aucun texte (fr.i18n.json:910-911) | Apostrophe droite. Type sur une ligne. « Voir la pièce » : ActionPrincipale tertiaire, cible d'au moins 48. Aucun chemin, clé ni URL. Image.network retiré (UX_REVIEW modif. 13 l.142). « Pièce disponible » sans source. En démonstration, la pièce porte « Document fictif ». |
| 02B, carte Vérifications, titre | « Vérifications » | « Vérifications » | spec §10.9 l.836 ; fr.i18n.json:912 | aucune |
| 02B, vérification 1 | « 1 », barre grise, « À vérifier » | Case non cochée + « La pièce est lisible » | fr.i18n.json:913 ; dossiers_page.dart:49 et 188-192 ; spec §10.9 l.838-851 ; 00_MAQUETTES rectif. 3 | Libellé réel à la place de la barre. Case manuelle, jamais précochée, Semantics(checked), à la place du numéro. Pastille « À vérifier » absente du code : retirée, sauf décision contraire. |
| 02B, vérification 2 | « 2 », barre grise, « À vérifier » | Case non cochée + « Le nom correspond à celui du compte » | fr.i18n.json:914 ; dossiers_page.dart:49 et 190 | Comme la vérification 1. |
| 02B, vérification 3 | « 3 », barre grise, « À vérifier » | Case non cochée + « La pièce n'est pas expirée » | fr.i18n.json:915 ; dossiers_page.dart:49 et 191 | Comme la vérification 1. Ordre lisible, nom, validité : celui du code (§10.9 l.838). |
| 02B, carte Accords et éléments soumis, titre | « Accords et éléments soumis » | « Accords et éléments soumis », seulement si le serveur (ou le port de démonstration) fournit les preuves | spec §10.11 l.883 ; §10.4 l.767 ; §10.10 l.857 | Aucune sur le titre. En mode réel, aucune donnée d'accord aujourd'hui (01_RELEVE l.152 et l.330) : la carte n'apparaît pas. |
| 02B, accord 1 | icône bouclier ; « Notice » ; « Acceptation versionnée disponible » | « Accusé de la notice » ; statut factuel du serveur (texte à valider), jamais « Signé » sans acceptation versionnée | spec §10.10 l.859 et l.865-867 | « Notice » devient « Accusé de la notice ». Statut sans source : à valider. |
| 02B, accord manquant | aucune ligne « Contrat du rôle » | « Contrat du rôle », si le serveur le fournit ; sinon « Un accord requis manque à ce dossier. » | spec §10.10 l.860 ; §26 ter l.1957 ; 01_RELEVE l.162 (0004:459-464) | Ligne à ajouter si la donnée existe. |
| 02B, accord 3 | icône document ; « Pièce reçue » ; « Disponible pour revue » | « Pièce reçue » ; statut factuel (texte à valider) | spec §10.10 l.861 | Libellé conforme. « Disponible pour revue » sans source et en doublon de « Pièce disponible ». |
| 02B, bouton destructif (avant Valider) | « Refuser le dossier », contour et texte rouges | « Refuser le dossier », niveau NiveauAction.destructive existant | spec §10.3 l.753, §10.4 l.769, §10.11 l.887, §18.2 l.1487-1488 ; §4 bis.2 règle 3 l.244 ; action_principale.dart:28-30 et 272-276 ; code : « Refuser » (fr.i18n.json:918), niveau secondaire (dossiers_page.dart:317-321) | Texte conforme. Le contour rouge n'existe dans aucun niveau, et le contrat C (§4 bis.3 l.278) interdit une variante locale : texte rouge, sans contour. Code : clé « Refuser » → « Refuser le dossier », niveau secondaire → destructive. Toujours active, ouvre 02D. |
| 02B, bouton principal (trailing) | « Valider le dossier », plein lilas, actif sans vérification | « Valider le dossier », désactivé tant que les trois cases ne sont pas cochées (ou que le serveur ne juge pas le dossier validable) | spec §10.2 l.749, §10.11 l.885, P-ADM l.524 ; fr.i18n.json:917 ; dossiers_page.dart:142 et 311-315 ; AC-19 l.2043 ; UX_REVIEW modif. 11 l.140 | Désactivé à l'état nominal ; actif après les trois cases, ouvre 02E. Le code empile Valider au-dessus de Refuser (dossiers_page.dart:311-321) : groupe horizontal, Refuser puis Valider au trailing, écart 8 (§4 bis.1 l.220 ; §10.4 l.770). |
| 02B, aide sous les actions | absente | « Terminez les vérifications requises. », permanente, avec lien vers la première case non cochée. Si le serveur bloque : « Ce dossier n'est pas encore prêt à être validé. » | spec §26 ter l.1956 ; §10.11 l.889 ; UX_REVIEW modif. 11 l.140 | Ajouter l'aide, reliée sémantiquement à Valider. |
| 02B, mention d'audit | absente | Ne pas afficher « Chaque consultation de pièce est inscrite au journal d'audit, avec votre nom. » | fr.i18n.json:921 ; 01_RELEVE l.145 ; UX_REVIEW l.115 et modif. 27 l.156 | Aucune : l'absence est conforme. |

**Disposition**

- Grille horizontale : barre latérale 0-288 (288), marge 288-320 (32), file 320-656 (336), gouttière 656-680 (24), détail 680-1408 (728), marge 1408-1440 (32). Largeur utile 1088 : conforme au contrat D (§4 bis.4 l.300-303), à §10.6 l.789 et à AC-20.
- Ordre de lecture : barre latérale, en-tête (titre, sous-titre ; thème et profil au trailing), file (compteur, Actualiser, 4 lignes), détail (en-tête, Identité, Pièce, Vérifications, Accords, actions). Ordre sémantique imposé : titre, statut, identité, pièce, vérifications, accords, décision (§26 ter l.1962).
- Écart : le détail est coupé en deux sous-colonnes (environ 328 et 329, séparées d'environ 21). Gauche : Identité puis Vérifications ; droite : Pièce puis Accords. L'ordre en Z n'est juste que si le focus est forcé (FocusTraversalOrder). 21 est hors échelle (contrat A l.208) : caler sur 16 (l.221) ou 24. §10.6 l.792 juge les colonnes inutiles : question.
- Marge interne du panneau de détail : environ 24, conforme à AppCard au-delà de 600 (§4 bis.1 l.229 ; §4 bis.3 l.282).
- Espacement entre sections : environ 28-29. Contrat A : 32 sur bureau (§4 bis.1 l.225) ; §26 ter l.1925 : 24. La règle gelée prime : 32, contradiction de §26 ter signalée. Titre de section → carte : environ 8-10, conforme au 8 (l.215).
- Actions : hauteur environ 52, conforme (§4 bis.2 l.238). Écart de 8, conforme (l.220). Pas de pleine largeur (l.255 ; §19.3 l.1557). Valider au trailing du contenu (l.254). Haut des actions à environ 16-17 sous Vérifications, conforme (§10.6 l.791 ; §4 bis.1 l.218). Réserve : Accords finit environ 94 px plus haut ; si les sous-colonnes restent, les actions sont à 16 sous le bloc le plus bas. Le contour rouge de Refuser n'est pas l'anatomie destructive (action_principale.dart:272-276).
- Écart : le panneau de détail est étiré jusqu'à 873, avec environ 200 px vides. Le détail ne s'étire pas au-delà de son contenu (§4 bis.4 l.305).
- Pas de pied collé : conforme (§4 bis.2 l.256).
- File : une carte groupée à filets internes, conforme (§9.4 l.622-624). Lignes d'environ 76. Compteur et Actualiser sur une ligne, action au trailing : conforme. Écart ligne d'en-tête → groupe d'environ 24 au lieu de 8 (§4 bis.1 l.215) : caler sur 8.
- Rectification 1 confirmée : dates des lignes 1 et 3 coupées. Au format de la spec (l.1929), la ligne s'allonge : la pastille passe sous le nom si 336 ne suffit pas.
- Barre latérale : entrées d'environ 48, actif sur fond discret (00_MAQUETTES l.26), pied séparé par un filet. Écart : Finance non atténuée.
- En-tête : boutons icônes d'environ 44 x 44 (1312-1356), au lieu d'au moins 48 (§19.1 l.1526 ; §4 bis.2 l.238). Ni recherche ni cloche : écart avec §19.3 l.1547 et le code (01_RELEVE l.61).
- Titre vers y 48, sous-titre vers y 82 : écart d'environ 8, conforme (l.214). DisqueRetour manquant au leading (§26 ter l.1923).
- Aucune pleine largeur, aucun bouton de 72 dp, aucun troisième panneau : conforme (§9.6 l.649, §10.6 l.790, AC-20).
- À 200 % de texte, ou sous 1088 de largeur utile : repli séquentiel, file puis détail (§10.6 l.793 ; UX_REVIEW modif. 7 l.136). Seuil à fixer.

**Hors périmètre**

- Contenu des images SHELL : références pour AD-X (00_MAQUETTES l.35).
- Éléments des explorations, sauf la fenêtre ADM-02.4 d'EXPLO-2, réservée à AD-9 (00_MAQUETTES l.39-47).
- Filtre « Type de dossier » et « Charger les dossiers suivants » : absents tant qu'aucun serveur ne les porte (spec §9.7 l.673-677 ; UX_REVIEW modif. 10 l.139). Absence conforme.
- Surfaces 02C, 02D, 02E : traitées dans leurs images.
- Réglage de la politique de genre : AD-9. « Profil à compléter » et « Pièce hors de votre portée » seulement sur état serveur explicite.
- États absents (chargement, vide, erreur, hors ligne, permission, actualisation, sélection retirée, « Sélectionnez un dossier à examiner. », dossier modifié, déjà traité) : §9.7, §10.11, §26 ter et composants partagés (rectif. 9).
- Contrats serveur (validable, révision, accords, total fiable, persistance des vérifications) : AD-BR (01_RELEVE §5 et §9). En démonstration, fournis par les ports.
- Onglets de Personnes et lignes « Dossier d'identité de {prenom} » de l'Accueil (01_RELEVE l.48).
- Entrée « Direction » : masquée (voitDirection vaut false).

### IMG-ADM-02C_desktop_sombre.png (1440 x 900, sombre) : visionneuse de pièce en fenêtre modale

La fenêtre est posée sur 02A et 02B assombris. La barre latérale n'est pas assombrie.

| Zone | Dans l'image | Texte à appliquer | Source | Rectification |
|---|---|---|---|---|
| Fenêtre, en-tête, à gauche : titre | « Pièce d’identité », apostrophe courbe, gras, environ 24 px | Pièce d'identité | spec §11.5 l.1000 ; §11 l.961 ; 02B l.877 ; §26 ter l.1975 (apostrophe courbe) ; fr.i18n.json:1467 (colonnePiece, apostrophe droite) | Libellé juste. La spec donne la droite 3 fois (l.961, l.1000, l.877) et la courbe 1 fois (l.1975). Le code a partout la droite. Proposition : clé existante, apostrophe droite. À confirmer. |
| Fenêtre, en-tête, sous le titre : type de pièce | « Carte d’identité », apostrophe courbe, petit texte gris | Carte d'identité (valeur du type déposé ; autres valeurs « Passeport », « Titre de séjour ») | spec §11.2 l.975 et l.73 ; fr.i18n.json:421-423 ; 01_RELEVE l.109 | Apostrophe droite du code (fr.i18n.json:421). Texte issu du doc_type par la clé i18n, jamais en dur. « Autre » avec précision : hors périmètre. Titre et sous-titre espacés de 8 (contrat A l.116). |
| Fenêtre, en-tête, à droite : bouton croix | croix seule, bouton rond d'environ 42 px | Icône croix sans texte visible ; libellé accessible et infobulle « Fermer la pièce » | 00_MAQUETTES rectif. 5 ; UX_REVIEW l.67 ; spec l.1966 ; clé absente (01_RELEVE l.230, l.233) | Cible d'au moins 48 dp (contrat B l.140). Clé i18n à créer. Même fermeture que « Fermer », Échap et retour système ; focus rendu à « Voir la pièce » (spec l.1030). La croix est conservée (rectif. 5 ; l.1966 ne l'interdit pas). |
| Zone document : pièce de démonstration | cadre neutre, étiquette violette « DOCUMENT D’IDENTITÉ », rectangle photo vide, 4 barres grises | Document fictif (mention visible sur la pièce) | spec l.2053 ; 00_MAQUETTES rectif. 5 et l.49 | Ajouter « Document fictif ». « DOCUMENT D’IDENTITÉ » n'a pas de source : contenu de la pièce fictive, pas un libellé d'interface. Rectangle photo vide : ni photo, ni blason, ni « République française ». |
| Zone document : 4 barres grises | 4 barres grises à droite du rectangle photo | Aucun texte : lignes neutres de la pièce fictive | 00_MAQUETTES rectif. 3 (vise 02B) ; spec l.1975 ; fr.i18n.json:912-915 | Ce ne sont pas les vérifications : la rectification 3 ne s'applique pas. Barres neutres, sans faux nom ni fausse date. |
| Pied, à gauche : bouton moins | « − » dans un bouton rond d'environ 42 px | Réduire (libellé accessible et infobulle) | spec §26 ter l.1977 ; UX_REVIEW l.68 | Clé i18n à créer. Cible de 48 dp. Raccourci « - ». |
| Pied : niveau de zoom | « 100 % » | 100 % (valeur d'état, espace insécable avant %), à confirmer | image seulement | Absent de la spec et du code. Seulement un état, sans action. Décision du directeur. |
| Pied : bouton plus | « + » dans un bouton rond d'environ 42 px | Agrandir (libellé accessible et infobulle) | spec §26 ter l.1977 ; UX_REVIEW l.68 | Clé i18n à créer. Cible de 48 dp. Raccourcis « + » et « = ». |
| Pied, commande absente | absente | Ajuster à l’écran | spec §26 ter l.1977 (apostrophe courbe ; UX_REVIEW l.68 l'écrit droite) ; UX_REVIEW l.68 | À ajouter dans le groupe Réduire / Agrandir (8 entre boutons, contrat A l.122) : bouton icône, libellé accessible « Ajuster à l’écran », raccourci « 0 ». |
| Pied, à droite : Fermer | « Fermer », bouton à contour, environ 98 x 52, à droite | Fermer | spec §11.5 l.1008 ; §11.2 l.978 ; §26 ter l.1966 ; fr.i18n.json:8 | Libellé et place justes (trailing, secondaire). Échap et retour système font la même fermeture ; focus rendu à « Voir la pièce » (l.1030). |
| Fenêtre, états absents | absents | Chargement de la pièce… · La pièce ne peut pas être affichée. + Réessayer / Fermer · L'accès à cette pièce a expiré. + Recharger la pièce · Aucune pièce n’est disponible. + Fermer · Ce format de pièce ne peut pas être affiché. + Fermer · Vous êtes hors ligne. La pièce ne peut pas être chargée. + Réessayer ou Fermer · Vous n’avez plus accès à cette pièce. (effacer l'image) + Fermer · La consultation de la pièce est indisponible pour le moment. + Fermer | spec §11.5 l.1002-1012 (apostrophes droites) ; §26 ter l.1970-1974 (apostrophes courbes) ; fr.i18n.json:9 ; rectif. 9 | À construire avec Skeleton, EtatSysteme, BlocAsynchrone, sans image. Pas de spinner seul (§4 bis.6 l.342). |
| Fenêtre : mention Démonstration | absente | Démonstration | spec l.2053 ; rectif. 8 | Ajouter la mention. Emplacement à trancher. |
| Arrière-plan : en-tête de page 02A | « Dossiers à valider » ; sous-titre ; « 4 dossiers en atte[nte] » | Dossiers à valider · Examinez les dossiers prêts pour une décision. · {n} dossiers en attente | spec l.653, l.655, l.611 ; fr.i18n.json:896, :899, :900 | Aucune. Sous-titre : clé à créer. Détail en 02A. |
| Arrière-plan : file 02A | 4 lignes tronquées, dates à la ligne, « Enseignante » | Données synthétiques avec « Démonstration » | rectif. 1 et 8 ; spec l.2053 | Hors de 02C. Traité en 02A. |
| Arrière-plan : détail 02B | « À revoir » ; « [V]oir la pièce » ; « …disponible » ; « [Vali]der le dossier » | Voir la pièce · Valider le dossier | spec l.824, l.879, l.1949 ; fr.i18n.json:917 ; « …disponible » peut-être fr.i18n.json:911 (non confirmé) | « À revoir » traité en 02B. « Voir la pièce » reprend le focus à la fermeture (l.1030). |
| Coque : barre latérale, non assombrie | Rewayah ; 7 entrées, Personnes actif ; pied « AD Admin / Administration » | Libellés inchangés (coque de 02A) | 00_MAQUETTES l.24-30 ; spec l.1966 ; l.1638 | « Personnes » actif : juste. Écart : la fenêtre est modale et piège le focus (spec §11.4 l.995, l.1979) : le voile couvre toute l'application, barre latérale comprise. |
| Coque : en-tête à droite (assombri) | boutons thème et profil | Inchangés (coque de 02A) | 00_MAQUETTES l.27 | Aucune. Inatteignables tant que la fenêtre est ouverte. |

**Disposition**

- Fenêtre : x 464-1264 (800 de large), conforme au gabarit 800 (spec l.1979 ; UX_REVIEW l.66). Hauteur y 90-810 (720), au plus viewport - 64 = 836 : conforme. Marges extérieures d'environ 90, au-delà des 32 demandés : conforme.
- Centrage sur x 864 (centre de la zone 288-1440), pas du viewport (720). La spec ne tranche pas. Acceptable si le voile couvre toute l'application, ce que l'image ne montre pas.
- Marges internes d'environ 24. Pas un écart : les « marges 32 » de l.1979 sont extérieures (UX_REVIEW l.66), et 24 est le padding au-delà de 600 (contrat A l.131).
- En-tête : titre (environ 24 px) puis type, 8 entre les deux (contrat A l.116). Croix au trailing, alignée sur le titre.
- Zone document : cadre x 560-1168 (608), y 250-648, environ 85 au-dessus et au-dessous. UX_REVIEW l.66 : en-tête et commandes fixes, seul le document zoome. La zone de lecture (fond neutre, §11.4 l.991) remplit l'espace entre en-tête et pied. L'écart de 85 vient de la mise à l'échelle, pas d'un CTA éloigné. Structure documentée au sens du contrat A l.134, sous réserve du directeur.
- Pied, LTR : [− Réduire] [100 %] [+ Agrandir] au leading, [Fermer] au trailing, sur le bord trailing de la croix (environ x 1238). Conforme au contrat B l.153-155. « Ajuster à l’écran » manque.
- « Fermer » : environ 98 x 52, contour, non étiré. Conforme (contrat B l.140, l.157). Aucun CTA plein : conforme (aucune décision depuis la visionneuse, l.1975).
- Boutons icônes (croix, −, +) : environ 42 px, sous 48 dp (contrat B l.140 ; UX_REVIEW l.68). À corriger.
- Contrat D : pas de troisième panneau, fenêtre modale dédiée (DESIGN-GOV l.206) : conforme. Coque de 288 visible.
- Voile : zone de contenu assombrie, barre latérale non. Écart avec la modale (spec l.995, l.1979 ; UX_REVIEW l.65 showDialog, barrierDismissible: false). Le voile couvre toute l'application.
- Variante sous 840 (sans image) : plein écran, retour au leading (« Fermer la pièce »), puis titre, type, document, commandes (spec §11.2, l.1966, l.1979 ; UX_REVIEW l.63-64 ; rectif. 9).

**Hors périmètre**

- Téléchargement, lien ou URL visible, menu « Enregistrer l'image » (spec §11.4 l.994 ; UX_REVIEW l.65 ; 00_MAQUETTES l.45).
- « Tourner la pièce » : pas de rotation (spec l.993, l.1977 ; UX_REVIEW l.65).
- Pagination (« Page précédente », « Page suivante », « Page {n} sur {total} ») : seulement si le multipage est pris en charge (l.1977).
- OCR, transcription, validation ou refus depuis la visionneuse (l.1975, l.1977).
- Branchement serveur de la lecture (autoriser_lecture_piece_identite, Edge piece-identite-acces au lieu de createSignedUrl) et journal par pièce (01_RELEVE l.25, l.126-127, l.289, l.332) : backend.
- Libellé du type « Autre » avec sa précision : texte libre perdu (01_RELEVE l.110, l.264).
- Textes de l'arrière-plan 02A et 02B : tâches 02A et 02B.
- Images SHELL et explorations (00_MAQUETTES l.35-47).
- Visionneuse avec zoom : aucun composant (01_RELEVE l.226, l.337). À construire en AD-7.

### IMG-ADM-02D_desktop_sombre.png (1440 x 900, sombre) : dialogue « Refuser le dossier »

Le dialogue est posé sur 02A et 02B assombris. La barre latérale n'est pas voilée.

| Zone | Dans l'image | Texte à appliquer | Source | Rectification |
|---|---|---|---|---|
| Dialogue, en-tête : titre | Refuser le dossier | Refuser le dossier | spec §12.2 l.1048 ; §18.1 l.1465 ; §18.2 n°2 l.1487-1488 ; AppBottomSheet (app_bottom_sheet.dart:236-244) | Aucune sur le texte. Écart titre-corps d'environ 12 ; le composant donne 16 (Ecart.vLg, app_bottom_sheet.dart:245). |
| Dialogue, en-tête : croix (disque d'environ 42) | icône X sans libellé | aucun : élément retiré | spec §26 ter l.1983 et l.1995 ; AppBottomSheet sans croix (app_bottom_sheet.dart:214-247) ; DESIGN-GOV §4 bis.3 l.180 | Retirer la croix : ni dans la spec ni dans le composant, et l'ajouter serait un fork. Fermeture par Annuler, Échap et retour, même chemin (UX_REVIEW groupe 5 l.80). |
| Dialogue : ligne nom/type (entre titre et explication) | absente | Nom et type du dossier, figés à l'ouverture. Données de démonstration seulement | spec §26 ter l.1983 et l.1985 ; UX_REVIEW groupe 5 l.77 et l.79 | Ajouter le bloc sous le titre. Format : question. |
| Dialogue : corps | Indiquez le motif qui sera affiché à la personne concernée. | Indiquez le motif qui sera affiché à la personne concernée. | spec §12.2 l.1050 | Aucune sur le texte. Il descend sous la ligne nom/type. |
| Dialogue : étiquette du champ | Motif du refus | Motif du refus (étiquette visible, liée au champ) | spec §12.2 l.1052 ; l.1466 ; UX_REVIEW l.78 | Aucune sur le texte. Code : remplacer motifRequis (fr.i18n.json:920, qui parle de « la famille ») par les clés §12.2 (01_RELEVE §8 n°29). |
| Dialogue : champ multiligne, texte indicatif | Expliquez ce qui doit être corrigé… | aucun texte indicatif (champ vide) | spec §12.2 l.1046-1070 ; rectif. 6 | Supprimer ce texte (hors spec, répète l'aide). Focus initial dans le champ (l.1995). Entrée ajoute une ligne, n'envoie pas (l.1927). |
| Dialogue : aide sous le champ | Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel. | Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel. | spec §12.2 l.1054 ; rectif. 6 | Aucune. Relier au champ comme helperText (UX_REVIEW l.78). |
| Dialogue : erreur du champ (après l'aide) | absente | Vide ou espaces seuls : « Indiquez le motif du refus. » Trop long : « Le motif dépasse la longueur autorisée. » | spec §12.2 l.1056 ; §26 ter l.1983 et l.1985 ; rectif. 6 et 9 | État à ajouter sans image. Lié au champ et annoncé (l.1995). S'efface à la correction (UX_REVIEW l.79). |
| Actions : secondaire (à gauche du groupe) | Annuler (contour clair d'environ 2) | Annuler | spec §12.2 l.1058 ; mode refus actuel sans Annuler (01_RELEVE §8 n°30, dossiers_page.dart:292-309) ; action_principale.dart:21-22, :254-265 | Texte inchangé. Le contour est celui du niveau secondaire, pas un anneau de focus. Si un motif est saisi : « Abandonner le motif saisi ? » avec « Continuer la saisie » et « Abandonner » (l.1995, AC-22 l.2046). |
| Actions : destructive (bord de fin) | Refuser le dossier (texte et contour rouges, sans fond) | Refuser le dossier ; pendant l'envoi : « Refus en cours… » | spec §12.2 l.1060, l.1062 ; §18.2 n°2 ; code « Refuser » (fr.i18n.json:917-919 ; 01_RELEVE §8 n°9) ; §26 ter l.1983 ; action_principale.dart:28-30, :272-276 | Retirer le contour rouge (le niveau destructif n'a pas de filet). Garder le texte inkAlert. « Refus en cours… » en liveRegion (UX_REVIEW l.78). |
| Dialogue : états non dessinés | absents | Erreur : « Le dossier n'a pas pu être refusé. » + « Réessayer » ; conflit : « Ce dossier a été traité par un autre membre de l'équipe. » + « Actualiser le dossier » ; hors ligne : « Vous êtes hors ligne. Le refus n’a pas été envoyé. » + « Réessayer » après reconnexion, motif conservé ; résultat inconnu : « Le résultat du refus n’est pas encore confirmé. » + « Vérifier le résultat » ; interdit : « Vous ne pouvez plus refuser ce dossier. » + « Fermer » ; service absent : « Le refus est indisponible pour le moment. » + « Annuler » ; succès : « Dossier refusé. » (fermeture, ligne retirée) | spec §12.2 l.1064-1070 ; §26 ter l.1989-1993 ; l.1160 | À ajouter avec les composants partagés, sans image. Apostrophes telles quelles : droite en §12.2, courbe en §26 ter. |
| Mention de démonstration | absente | Démonstration (mention visible) | spec l.2053 ; rectif. 8 | À ajouter. Emplacement : question. |
| Voile (barrière modale) | voile sur la zone principale seulement ; dialogue centré sur cette zone | sans texte | showDialog, barrierColor palette.voile, _CadreDialogue (app_bottom_sheet.dart:124-141, :265-271) ; spec §20 l.1578 ; l.1999 | Le voile couvre toute la fenêtre, barre latérale comprise ; navigation inaccessible. Dialogue centré dans la fenêtre (x ≈ 440 à 1000). |
| Arrière-plan : barre latérale | Rewayah ; 7 entrées, Personnes actif ; pied « AD Admin / Administration » | Mêmes libellés et ordre. Finance inerte (inkFaint). Pied « Admin · Administration » | 01_RELEVE §2 l.51-60 ; 00_MAQUETTES l.24-30 | Finance inerte : tâche 02A. |
| Arrière-plan : en-tête de page | Dossiers à valider / sous-titre ; thème et profil | Dossiers à valider ; Examinez les dossiers prêts pour une décision. | spec l.610, l.655 ; l.1460 | Aucune (tâche 02A). |
| Arrière-plan : file 02A | 4 dossiers en attente ; Actualiser ; 4 lignes avec « À revoir » et « Enseignante » | Compteur « {n} dossiers en attente » si total fiable ; dates sur une ligne ; données fictives | spec l.611 ; rectif. 1 et 8 | Dates coupées : rectif. 1 (tâche 02A). |
| Arrière-plan : détail 02B | Dossier de Aïcha Benali ; À revoir ; cartes tronquées ; Refuser le dossier (contour rouge) ; Valider le dossier | « Dossier d'Aïcha Benali » ; « Accords et éléments soumis » ; « Voir la pièce » ; « Refuser le dossier » ; « Valider le dossier » | rectif. 2 ; spec l.753, l.767, l.855, l.879, l.1949 | Élision (tâche 02B). Les 3 vérifications (fr.i18n.json:913-915) sont cachées par le dialogue. |

**Disposition**

- Dialogue : x 584-1144, 560 de large. Conforme à « largeur maximale 560 » (l.1983) et à AppPage.largeurDialogue (app_spacing.dart:85 ; app_bottom_sheet.dart:269-272). Écart : centré sur la zone principale (x 864), alors que _CadreDialogue centre dans la fenêtre (x 720).
- Marges internes d'environ 25 : conformes aux 24 (l.1983 ; AppSpacing.xxl, app_bottom_sheet.dart:210).
- Ordre dessiné : titre, corps, étiquette, champ, aide, actions. Manquent le bloc nom/type (entre titre et corps) et l'erreur associée (l.1983 ; UX_REVIEW l.77). La croix n'a pas sa place.
- Champ : environ 510 x 150, pleine largeur utile (512). Multiligne, 3 lignes minimum (UX_REVIEW l.81).
- Boutons : hauteur 52 (y 551-603), conforme (l.1927). Largeur au texte, conforme (contrat B l.157). Imposer pleineLargeur false : le défaut est vrai (action_principale.dart:56 ; 01_RELEVE §8 n°39).
- Groupe au trailing, Annuler avant le destructif : conforme (DESIGN-GOV l.153-154). Écart d'environ 8.
- Aide → boutons : environ 26, soit le 24 du composant (Ecart.vXxl, app_bottom_sheet.dart:247). Contrat B l.156 : 16 ; UX_REVIEW l.77 : « Espaces 4, 16, 8 ». Pas de jeton relatedAction (01_RELEVE §10 n°24), pas de fork (DESIGN-GOV l.180) : question.
- Titre → corps : environ 12, contre 16 dans le composant (app_bottom_sheet.dart:245).
- Hiérarchie : aucun bouton plein. Le destructif a un contour rouge, absent du niveau destructif (action_principale.dart:272-276). Annuler secondaire : conforme.
- Voile absent de la barre latérale sur l'image. Dans le code, la barrière couvre toute la fenêtre (app_bottom_sheet.dart:124-126). Page et navigation non interactives (l.1578, l.1999).
- Composant : AppBottomSheet.ouvrir, pas ConfirmDestructive (pas de champ, destructif au-dessus d'Annuler : 01_RELEVE l.218, §8 n°40 ; UX_REVIEW l.76). Seul le contenu est nouveau (01_RELEVE §10 n°23).
- Formes : le code donne feuille sous 600, feuille bornée à 560 de 600 à 1199, dialogue sur bureau seulement (app_bottom_sheet.dart:67-71). La spec veut un dialogue dès 768 (l.1983). « Dialogue dès 600 » (UX_REVIEW l.76) est inexact. À 1440 : conforme.
- Focus : non visible sur l'image. Règle : focus initial dans le champ, boucle dans le dialogue, retour sur « Refuser le dossier » de 02B à l'annulation (l.1995 ; §20 l.1578).
- Arrière-plan : 288, file environ 336, gouttière environ 24, détail environ 728. Conforme (spec l.1546) ; tâche 02A.

**Hors périmètre**

- Contenu de 02A et 02B sous le voile : tâches 02A et 02B.
- Taxonomie de motifs, note interne, motif automatique : interdits (spec §12.3 l.1076-1080).
- Longueur maximale du motif : aucune valeur dans le contrat ni le code (01_RELEVE §9 n°25 ; UX_REVIEW l.79). Ne pas l'inventer.
- Serveur : révision figée, already_decided et stale_dossier, idempotence, résultat inconnu vérifiable (01_RELEVE §9 n°6-7). Les états s'affichent, rien n'est simulé.
- Portail /attente après refus : P-ADM-09.
- Formes mobile (390) et tablette (768) : aucune image. Règles de l.1983.
- Explorations : non retenues.

### IMG-ADM-02A-02B-02E_mobile.png (3 téléphones 390 x 844) : 02A clair, 02B sombre, 02E clair

| Zone | Dans l'image | Texte à appliquer | Source | Rectification |
|---|---|---|---|---|
| 02A · en-tête, leading | disque retour, sans libellé visible | DisqueRetour, libellé accessible « Retour », vers /admin | spec §26 ter l.1923 et l.1933 ; §9.4 l.620 ; 01_RELEVE §7 (entete_page.dart:94-96) | Aucune sur l'image. EntetePage et DisqueRetour à ajouter dans le code (dossiers_page.dart:107-108). |
| 02A · en-tête, titre | Dossiers à valider | Dossiers à valider | spec §9.7 l.653 ; fr.i18n.json:896 | aucune |
| 02A · en-tête, sous-titre | Examinez les dossiers prêts pour une décision. | Examinez les dossiers prêts pour une décision. | spec §9.7 l.655 et §9.4 l.610 (clé à créer) | aucune |
| 02A · compteur | 4 dossiers en attente | {n} dossiers en attente (singulier « 1 dossier en attente »), si total fiable, en liveRegion | spec §9.4 l.611 ; fr.i18n.json:899-900 ; UX_REVIEW groupe 2 l.35 et l.40 | Texte conforme. La file compte les pièces, pas les personnes (01_RELEVE §5, 0029:73-145) : total non fiable avant AD-BR. |
| 02A · action d'actualisation | Actualiser (texte violet) | Actualiser les dossiers ; pendant l'actualisation : « Actualisation des dossiers… », liste affichée | spec §26 ter l.1945 et l.1937 ; §18 l.1454 ; contrat B règle 6 ; UX_REVIEW groupe 2 l.34 | Libellé complété. Clé « Actualisation des dossiers… » absente (01_RELEVE §7). Ne tient plus à côté du compteur (voir Disposition) : placement en question. |
| 02A · lignes 1 à 4, avatar | initiales « AB », « YD », « FZ », « OB » | Aucun : la ligne montre « seulement » nom, type, ancienneté, état, chevron | spec §9.4 l.614-619 | Hors de la liste fermée de la spec : retiré, sauf arbitrage. |
| 02A · ligne 1, nom | Aïcha Benali | {prénom} {nom} synthétique, écran avec « Démonstration » | spec §9.4 l.615 ; §26 quater l.2053 ; rectif. 8 | Nom synthétique accepté. Fixtures du code différentes (Amina Benali, Omar Haddad, persona.dart:613-655) : question. |
| 02A · ligne 1, type et date | Enseignant · 25 sept. 2026 (coupé sur deux lignes) | Enseignant · 25/09/2026 à HH:mm (zone IANA : celle du profil admin, sinon celle de l'appareil) ; sans date : « Date de dépôt indisponible » | spec §9.4 l.616 ; fr.i18n.json:1824 ; spec §26 ter l.1929 ; rectif. 1 ; UX_REVIEW groupe 3 l.57 | Format de la spec. La date ne se coupe pas : la pastille passe sous le nom si besoin. Le code n'affiche que « Déposé le {date} » (fr.i18n.json:901), sans heure ni fuseau (dossiers_page.dart:453-455). |
| 02A · lignes 1 à 4, pastille | « À revoir », point violet | Aucun texte nominal sourcé. Code : « Aucune pièce déposée » (fr.i18n.json:905), « Pièce hors de votre portée » (:907), sur état serveur explicite | spec §9.4 l.618 ; §18.1 l.1467 ; UX_REVIEW groupe 7 l.100 ; dossiers_page.dart:251-256 | « À revoir » sans source : retiré, ou remplacé par « En cours de vérification ». Question. |
| 02A · lignes 1 à 4, chevron | chevron droit | Chevron start/end ; libellé accessible « Ouvrir le dossier de {nom} » | spec §9.4 l.619 ; §26 ter l.1945 ; UX_REVIEW groupe 2 l.35 | Libellé accessible à ajouter. Sélection jamais par la couleur seule. |
| 02A · ligne 2 | YD · Yusuf Diallo · Tuteur · 25 sept. 2026 · À revoir | Yusuf Diallo · Tuteur · 25/09/2026 à HH:mm (zone IANA) | fr.i18n.json:1825 ; spec §9.4 l.616 ; P-ADM-08 l.1881 ; §26 ter l.1929 | Format de date. Avatar et pastille comme la ligne 1. |
| 02A · ligne 3 | FZ · Fatima Zahra · Enseignante · 24 sept. 2026 (coupé) · À revoir | Fatima Zahra · Enseignant · 24/09/2026 à HH:mm (zone IANA) | fr.i18n.json:1824 ; spec §9.4 l.616 et §10.11 l.873 | « Enseignante » devient « Enseignant » : pas de forme féminine, le client ne lit pas le genre (source_session.dart:82-85). Date sur une ligne. |
| 02A · ligne 4 | OB · Omar Bah · Tuteur · 24 sept. 2026 · À revoir | Omar Bah · Tuteur · 24/09/2026 à HH:mm (zone IANA) | fr.i18n.json:1825 ; spec §26 ter l.1929 | Format de date. Avatar et pastille comme la ligne 1. |
| 02A · mention démonstration | absente | Démonstration | spec §26 quater l.2053 ; rectif. 8 | À ajouter. Forme et emplacement : question. |
| 02B · en-tête, leading | disque retour | DisqueRetour « Retour », vers 02A, sélection et défilement restaurés | spec §10.4 l.761 ; §26 ter l.1933 et l.1949 | aucune |
| 02B · en-tête, titre | Dossier de Aïcha Benali (sur deux lignes) | Dossier d'Aïcha Benali | spec §10.11 l.871 ; rectif. 2 | Élision devant voyelle. Retour à la ligne accepté. |
| 02B · en-tête, statut | pastille « À revoir » | Statut fourni par le serveur ; aucun texte nominal sourcé | spec §10.4 l.763 ; §18.1 | Comme 02A. |
| 02B · en-tête, type | Enseignant | Enseignant | spec §10.11 l.873 ; fr.i18n.json:1824 | aucune |
| 02B · titre de section | Identité et dossier | Identité et dossier | spec §10.11 l.875 et §10.7 l.797 | aucune |
| 02B · carte Identité, ligne 1 | Nom : Benali \| Prénom : Aïcha (deux colonnes) | Nom : Benali ; Prénom : Aïcha | spec §10.7 l.807-808 | Libellés conformes. Lignes à filets demandées (l.799-801) : grille en question. |
| 02B · carte Identité, ligne 2 | Type de dossier : Enseignant \| Date de dépôt : 25 sept. 2026 | Type de dossier : Enseignant ; Date de dépôt : 25/09/2026 à HH:mm (zone IANA), sinon « Date de dépôt indisponible » | spec §10.7 l.809-810 ; §26 ter l.1929 ; fr.i18n.json:901 | Format de date. « État du dossier » (l.811) seulement s'il est fourni ; jamais « Non renseigné » (l.813). |
| 02B · titre de section | Pièce d’identité (apostrophe courbe) | Pièce d'identité (apostrophe droite) | spec §10.8 l.817 et §10.11 l.877 | Texte conforme. Apostrophe de la spec §10 et du code. |
| 02B · carte Pièce, type | Carte d’identité (icône document) | Carte d'identité | fr.i18n.json:421 ; spec §10.8 l.821 | Aucune sur le texte. Ni chemin, ni clé, ni lien (§10.8 l.826-832). |
| 02B · carte Pièce, état | Pièce disponible | État fourni par le serveur ; aucun libellé nominal dans la spec ni le code | spec §10.8 l.822 ; fr.i18n.json:905, :907, :911 | À valider. En démonstration, la pièce porte « Document fictif » (l.2053 ; rectif. 5). |
| 02B · carte Pièce, action | Voir la pièce (texte violet) | Voir la pièce | spec §10.8 l.824 et §10.11 l.879 | Aucune. Le focus y revient à la fermeture de 02C (l.1030). |
| 02B · titre de section | Vérifications | Vérifications | spec §10.9 l.836 et §10.11 l.881 ; fr.i18n.json:912 | aucune |
| 02B · vérification 1 | « 1 », barre grise, « À vérifier » | La pièce est lisible | fr.i18n.json:913 ; 01_RELEVE §3 (dossiers_page.dart:49, :188-192) ; spec §10.9 l.838-853 ; rectif. 3 | Libellé réel. « À vérifier » sans source : l'état est porté par la case (_Case, dossiers_page.dart:389-429), jamais précochée, Semantics(checked) (UX_REVIEW groupe 3 l.53). |
| 02B · vérification 2 | « 2 », barre grise, « À vérifier » | Le nom correspond à celui du compte | fr.i18n.json:914 | Comme la vérification 1. |
| 02B · vérification 3 | « 3 », barre grise, « À vérifier » | La pièce n'est pas expirée | fr.i18n.json:915 | Comme la vérification 1. Ordre du code (§10.9 l.838). |
| 02B · carte Accords et éléments soumis | absente | Accords et éléments soumis, seulement si le serveur fournit les données | spec §10.4 l.767, §10.10, §10.11 l.883 ; 01_RELEVE §5 et §9 point 9 | Aucune : absence conforme. |
| 02B · actions, leading | Refuser le dossier (contour et texte rouges, coupé au bord gauche) | Refuser le dossier | spec §10.3 l.753, §10.11 l.887, §18.2 n°2 ; code « Refuser » (fr.i18n.json:918) | Bouton entier, dans la marge de 16 (rectif. 4). Niveau destructif existant, jamais plein (§10.3 l.755 ; contrat B règle 3). dossiers.refuser devient « Refuser le dossier » (UX_REVIEW groupe 8 l.115). |
| 02B · actions, trailing | Valider le dossier (plein, lavande) | Valider le dossier | spec §10.2 l.749 et §10.11 l.885 ; fr.i18n.json:917 | Aucune sur le texte. Au trailing, ouvre 02E. Si impossible : « Ce dossier n'est pas encore prêt à être validé. », à 4 sous les actions (§10.11 l.889 ; UX_REVIEW groupe 6 l.92). |
| 02B · mention démonstration | absente | Démonstration | spec §26 quater l.2053 ; rectif. 8 | à ajouter |
| 02E · page sous le voile | disque retour ; « Dossier de Aïcha Benali » ; « Enseignant » ; « Identité et dossier » ; une carte avec « Nom / Benali » et « Pièce d’identité / Disponible » | Même page que 02B : « Dossier d'Aïcha Benali », mêmes cartes, libellés et ordre | spec §26 ter l.1999 ; rectif. 2 | Élision. Le fond diffère de 02B (pièce fondue dans Identité, une colonne, « Disponible ») : aligné sur 02B, sans redessin. |
| 02E · dialogue, titre | Valider ce dossier ? | Valider ce dossier ? | spec §13.2 l.1106 (espace simple avant « ? ») ; rectif. 7 | Aucune. |
| 02E · dialogue, corps | Le dossier de Aïcha Benali sera validé. Les autres conditions d’accès resteront applicables. (nom en gras) | Variante documentaire : « Le dossier de {nom} sera validé. Les autres conditions d’accès resteront applicables. » Variante activation : « Le dossier de {nom} sera validé. Son compte pourra accéder à son espace. » Conséquence inconnue : pas de confirmation, « La validation est indisponible pour le moment. » avec Fermer seul | spec §13.2 l.1108-1119 ; 01_RELEVE §1 et §8 n°21 ; UX_REVIEW groupe 6 l.90 | Texte = variante documentaire. La spec écrit « de {nom} », sans élision : extension de la rectif. 2 en question. Choix de variante : champ serveur absent. Gras non demandé. Aucune promesse de notification, classe ou photo : conforme. |
| 02E · dialogue, type | carte à icône : « Type de dossier » / « Enseignant », après la conséquence | Type de dossier : Enseignant | spec §13.2 l.1113 ; §26 ter l.1999 ; fr.i18n.json:1824 | Libellés conformes. La spec met le type avant la conséquence : question. Blocages connus après la conséquence s'ils existent. |
| 02E · actions, leading | Annuler (contour) | Annuler | spec §13.2 l.1121 | Aucune. Focus initial sur le titre ou Annuler, jamais Valider (§26 ter l.2010). |
| 02E · actions, trailing | Valider le dossier (plein, lavande) | Valider le dossier ; envoi : « Validation en cours… » ; erreur : « Le dossier n'a pas pu être validé. » + « Réessayer » | spec §13.2 l.1123-1129 ; §26 ter l.2003-2008 | Aucune. Après confirmation : « Dossier validé. » via LocalFeedback, retour à la liste sur mobile (§14 l.1160-1163), sans promettre l'activation (l.2008). Clé « Dossier validé. » absente (01_RELEVE §7). |
| 02E · mention démonstration | absente | Démonstration | spec §26 quater l.2053 | à ajouter |
| Coque mobile (02A et 02B) | aucune coque visible | AdminShell en tiroir : « Menu » et en-tête existant (recherche, cloche « Aucune notification », compte) ; jamais de barre basse | spec §9.4 l.605 et l.620, §19.1 l.1520 ; 01_RELEVE §2 (admin_shell.dart:459-528, :492) | La coque reste au-dessus de la page, on ne l'enlève pas. Sans objet pour 02E (modal). |

**Disposition**

- Échelle : environ 370 px pour 390 dp (≈ 0,95 px/dp). Valeurs en dp, à ± 4.
- 02A, gouttières : environ 17-18 dp. Conforme au padding mobile de 16 (contrat A l.128 ; spec §26 ter l.1925).
- 02A, ordre : en-tête (retour, titre, sous-titre), compteur et action, liste groupée. Conforme (§9.4 l.609-620). Absence de filtres conforme (UX_REVIEW groupe 2 l.34).
- 02A, liste : un rectangle à filets internes, lignes d'environ 78-80 dp, sans filet final. Conforme (§9.4 l.622-624 ; GroupeReglages 16 x 12, contrat A l.132).
- 02A, ligne : avatar (≈ 46) \| texte (≈ 145) \| pastille (≈ 80) \| chevron (≈ 24). Texte trop étroit, d'où la date coupée. Le format de la spec est plus long : la pastille passe sous le nom si besoin, sans ellipsis (UX_REVIEW groupe 2 l.43).
- 02A, « Actualiser les dossiers » : compteur ≈ 172 dp + action ≈ 190 dp = 362 dp pour 358 disponibles. Ne tient pas. Soit sous le compteur, aligné end, soit au trailing de l'en-tête (UX_REVIEW groupe 2 l.34). Cible d'au moins 48.
- 02A, espacements : titre → sous-titre ≈ 8, conforme (contrat A l.116). Sous-titre → compteur ≈ 32. Compteur → carte ≈ 24 ; si le compteur est l'en-tête de section, la règle est 8 (contrat A l.117). À régler avec les jetons, pas au jugé (l.136).
- 02B, gouttières : 16 de chaque côté. Seul Refuser déborde à 0 dp : écart (contrat A ; rectif. 4).
- 02B, ordre : retour, titre + type, statut, Identité, Pièce, Vérifications, actions. Conforme (§10.4 l.761-770 ; §26 ter l.1962). Absence d'Accords conforme.
- 02B, espacements : titre de section → carte ≈ 8-10 (l.117), entre sections ≈ 24 (l.126) : conformes.
- 02B, carte Identité : grille 2 x 2 avec un filet. La spec demande des lignes à filets (§10.7 l.799-801 ; LigneCleValeur, contrat C). La grille n'est pas un composant existant. Rien tronqué à 200 % (UX_REVIEW groupe 2 l.43). Question.
- 02B, carte Pièce : icône, type + état, « Voir la pièce » tertiaire au trailing. Conforme (contrat B règle 5).
- 02B, Vérifications : 3 lignes d'environ 62 dp. Contrôle attendu : la case du code (slot controle de LigneRubrique), pas une pastille.
- 02B, actions : environ 18 dp sous Vérifications (≈ 16 : §10.4 l.768 ; contrat A l.120). Dans le flux, non collées : conforme (§10.4 l.772 ; contrat B l.158).
- 02B, boutons : hauteur ≈ 55 (52 attendu), écart ≈ 9 (8 attendu). Valider ≈ 184 dp, Refuser ≥ 179 dp : ≥ 372 pour 358. Deux lignes alignées end, Refuser puis Valider au trailing, sans étirement ni ellipsis (rectif. 4 ; UX_REVIEW groupe 9 l.124 ; contrat B l.153-154). pleineLargeur à false (défaut vrai, action_principale.dart:56).
- 02B, hiérarchie : un seul bouton plein (Valider). Refuser au niveau destructif, sans fond rouge (contrat B règles 1 et 3 ; §10.3 l.755).
- 02E, dialogue : marges ≈ 17 dp (16 attendu, l.1999), padding interne ≈ 24. Conforme (UX_REVIEW groupe 6 l.89).
- 02E, actions : Annuler (≈ 112 dp) au leading, ≈ 8, Valider (≈ 184 dp) au trailing, hauteur ≈ 52-55. Pas de pleine largeur, une seule action pleine, fond voilé et inerte : conforme.
- 02E, ordre : titre, conséquence, carte Type, actions. La spec (l.1999) : titre, nom/type, conséquence, blocages, Annuler, Valider. Question.
- 02E, carte Type : icône dans un disque d'environ 40. Réutiliser AppCard ou une ligne GroupeReglages (contrat C), pas un rendu local.
- Thèmes : 02A et 02E clairs, 02B sombre. Conforme aux références (§21 ; §26 ter). Le fond de 02E reprend la structure de 02B.
- Contrat D : sans objet sur mobile. « Pas de pleine largeur sur bureau » vaudra pour le détail 728 (§10.6 l.791).

**Hors périmètre**

- Légendes sous les téléphones : annotations de planche.
- Contenu de la coque (images SHELL) : AD-X.
- 02C et 02D : leurs propres tâches. « Voir la pièce » mène à 02C, « Refuser le dossier » à 02D.
- Mise en page bureau 1440 et tablette 768 : autres images.
- Filtre « Type de dossier », pagination, « Charger les dossiers suivants » : absents (AD-5).
- Carte « Accords et éléments soumis » : aucune donnée serveur.
- Réglage de genre Super Admin (§15.2) : jamais dans ADM-02 ; AD-9, avec ADM-02.4 d'EXPLO-2 comme seule référence.
- États absents (chargement, vide, erreur, hors ligne, permission, conflit, résultat inconnu, « Profil à compléter ») : spec et composants partagés (rectif. 9).
- Serveur : can_validate, révision, idempotence, champ de conséquence pour 02E, total fiable, persistance des vérifications (01_RELEVE §9, AD-BR).
- Explorations : rien n'est retenu.

### exploration/EXPLO-2_clair_ADM-02.4-genre.png : fenêtre « ADM-02.4 · Paramètre Super Admin » seule (clair)

Référence de disposition pour AD-9 (00_MAQUETTES l.39). Textes de la spec §15.2 l.1195 et l.1197.

| Zone | Dans l'image | Texte à appliquer | Source | Rectification |
|---|---|---|---|---|
| 1. Légende sous la fenêtre (annotation) | « ADM-02.4 · Paramètre Super Admin » / « Version web · Règle de genre (configurable) » | Aucun texte à l'écran. « ADM-02.4 » ne peut pas identifier la surface : le réglage n'appartient pas à ADM-02 | spec §15.2 l.1193 ; P-ADM-07 l.574 ; 00_MAQUETTES l.39 | « ADM-02.4 » reste le nom de la maquette. Identifiant de surface : directeur. |
| 2. En-tête : titre, à gauche | « Paramètre Super Admin » | Aucun titre exact dans la spec. « Configuration Super Admin » est un intitulé de section, pas un texte d'interface. Pas de clé i18n avant décision | spec §15.2 l.1191 ; ni surface ni clé (01_RELEVE l.23, l.96) | Libellé non fixé. Question. |
| 3. En-tête : fermeture, en haut à droite | croix « × » | Croix, nom accessible « Fermer ». Échap et retour système ferment sans mutation ; focus rendu au déclencheur. Échap à tester aussi en forme dialogue d'AppBottomSheet | rectif. 5 ; spec l.1966 et l.2010 ; 01_RELEVE l.219 ; UX_REVIEW l.157 | Nom accessible, retour du focus, test d'Échap en dialogue. Aucun changement visuel. |
| 4. Carte : titre du réglage | « Contrainte de genre pour la revue des dossiers » | « Limiter la revue KYC selon le genre » | spec §15.2 l.1195 (« Libellé proposé ») | Texte remplacé. §18.1 l.1472 déconseille « KYC » seul ; ici il n'est pas seul : texte de la spec gardé (question). |
| 5. Carte : aide sous le titre | « Lorsque cette option est activée, seuls les reviewers du même genre que le candidat peuvent traiter le dossier. » | « Lorsque cette règle est désactivée, tout membre autorisé à revoir les dossiers peut traiter les dossiers de son périmètre, quel que soit son genre. » | spec §15.2 l.1197 | Texte remplacé. L'image décrit l'état activé, non décrit par la spec (l.124). « reviewers » et « candidat » hors lexique (§18.1 l.1458-1468). |
| 6. Carte : interrupteur et libellé d'état | interrupteur violet activé, « Activée », sous l'aide, au leading | Aucun libellé d'état. Nom accessible : titre fusionné avec l'aide. Valeur de get_kyc_review_policy. Pas de bascule optimiste ; inactif pendant la mutation ; retour à la valeur serveur en cas d'échec | spec §15.1 l.1189 ; §17.5 l.1405-1410, l.1434 ; UX_REVIEW l.102 | « Activée » retiré, sauf accord. Interrupteur au trailing, ligne entièrement interactive (UX_REVIEW l.102, pas le contrat C). |
| 7. Premier encadré (fond teinté, icône i) | « Cette règle peut être désactivée à tout moment par un Super Admin. Lorsqu'elle est désactivée, tout reviewer autorisé peut traiter tout dossier, indépendamment du genre. » | Aucun texte : encadré retiré | spec §15.2 l.1195-1197 ; §15.1 l.1187 ; §15.2 l.1205 ; l.125 | Supprimé. Il répète et contredit l'aide : « tout dossier » dépasse le périmètre (l.1205, l.125). « reviewer » hors lexique. |
| 8. Second encadré (fond teinté, icône i) | « Les changements sont enregistrés et audités. » | Aucun texte tant que l'audit de la politique n'est pas prouvé côté serveur | spec l.127 et §15.2 l.1203 ; 01_RELEVE l.23, l.96, l.303 ; précédent : 01_RELEVE l.145, l.261 | Retiré, ou en attente d'AD-BR n°17 et de l'accord du directeur. |
| 9. Pied : action secondaire | bouton à contour « Annuler » | « Annuler » | spec l.1058 et l.1121 ; contrat B l.252 | Texte inchangé. Gardé seulement si le modèle de fenêtre avec enregistrement est retenu. |
| 10. Pied : action principale, bord de fin | bouton plein violet « Enregistrer » | Pas de libellé dans la spec. Le CTA dit l'effet exact. « Enregistrer la règle » : proposition sans source. Si la ligne agit à la bascule, le bouton disparaît | contrat B l.247 (règle 6) ; §18 l.1454 ; UX_REVIEW l.102 | Libellé et existence du bouton : directeur. |
| 11. Conteneur bordé du réglage | carte à filet fin, coins arrondis | Aucun texte. Composant partagé, sans fork : ligne GroupeReglages / LigneRubrique avec slot « controle » (au moins 48, padding 16 x 12) ou AppCard (20 sous 600, 24 au-delà). SwitchListTile à confronter à cette liste | contrat C l.269, l.278, l.282-283 ; 01_RELEVE l.206 | Choix du composant : question. Carte gardée, sans redessin. |
| 12. Vérifications 1, 2, 3 | absentes de cette fenêtre | Sans objet. Les trois libellés réels concernent 02B | 01_RELEVE l.17, l.71-73 (fr.i18n.json:913-915) ; rectif. 3 | aucune |
| 13. Mention « Démonstration » | absente ; aucune donnée de personne | Sur les captures de démonstration d'AD-9, valeur simulée sans appel serveur, avec « Démonstration » visible | rectif. 8 ; spec §26 quater l.2051-2053 | Ajoutée sur les captures de démonstration seulement. |
| 14. États absents | ni chargement, ni erreur, ni envoi, ni accès refusé, ni conflit de version | BlocAsynchrone et Skeleton (180 ms, 8 s, 20 s), EtatSysteme, LocalFeedback après confirmation serveur, en liveRegion. Aucun texte inventé | rectif. 9 ; contrat C l.271-274 ; contrat E l.324-326 ; §17.5 l.1418 ; 01_RELEVE l.217 | États avec les composants partagés. Textes à valider par le directeur. |

**Disposition**

- La planche n'est pas au 1:1 : fenêtre d'environ 378 px sur 1536, échelle estimée 0,67 si la fenêtre fait 560. Les px servent à constater un écart ; les valeurs à appliquer sont celles des contrats.
- Largeur : AppBottomSheet en dialogue, bornée à 560 (01_RELEVE l.219 ; contrat D l.308). Aucune largeur ad hoc. Conforme si la fenêtre est retenue.
- Structure : en-tête (titre, croix), carte (titre, aide, interrupteur), deux encadrés, actions. Contrat A l.222 fixe 16 entre l'en-tête et les actions internes d'AppCard, pas entre l'en-tête et le contenu. Padding selon le composant : 16 x 12 (GroupeReglages, contrat C l.283), 20 ou 24 (AppCard, l.229, l.282). Padding de l'image ≈ 15 à l'échelle : GroupeReglages, trop faible pour AppCard.
- Interrupteur : sous l'aide, au leading, suivi de « Activée ». UX_REVIEW l.102 : ligne interactive, interrupteur au trailing, au moins 48 (contrat C l.283). Écart d'anatomie corrigé par le composant, sans redessin.
- Actions : « Annuler » au leading, « Enregistrer » au trailing. Conforme (contrat B l.251-253). En RTL, inversion par start/end.
- Écart entre boutons : ≈ 12 à l'échelle. Contrat A l.220 : 8, via le jeton space.actionGroup (l.234).
- Objet → CTA : ≈ 27 à l'échelle. Contrat A l.218 et contrat B l.254 : 16 sous la carte du réglage (encadrés 7 et 8 retirés). Bord de fin des boutons aligné sur celui de la carte.
- Largeur des boutons : au contenu, pas pleine largeur sur bureau (contrat B l.255). pleineLargeur=false forcé (défaut vrai : 01_RELEVE l.207, l.277).
- Hauteur des boutons : anatomie ActionPrincipale, 52, padding 20 x 12, rayon 12, cible d'au moins 48 (contrat B l.238).
- Un seul CTA plein : conforme (contrat B règle 1, l.242).
- Structure cible : en-tête, carte ou ligne du réglage, 16, actions (modèle fenêtre). Sinon : en-tête et ligne interactive seule.

**Hors périmètre**

- Tout le reste d'EXPLO-2 (00_MAQUETTES l.37-49) : maître-détail, fil d'Ariane, onglets de statut, recherche et filtres, onglets de détail, fausse carte « République française » et photos (interdites), « Autres pièces » et téléchargement, panneaux ADM-02.1 à 02.3, barre latérale d'exploration.
- Tout toggle de genre dans ADM-02 : interdit (spec §15.2 l.1193).
- État « Profil à compléter » d'ADM-02 (§15.3 l.1215-1219) : AD-9, absent de cette fenêtre.
- Serveur : fondation Super Admin, genre_reviewer_enforced, get_kyc_review_policy et set_kyc_review_policy, audit, actualisation des files (01_RELEVE l.23, l.96-99 ; AD-BR n°16-19, l.302-305). Rien avant BR-1.
- Tout nouveau composant ou fork local (contrat C l.278).

### Questions au directeur

Chaque question porte la valeur appliquée par défaut en attendant (spec, sinon code ; à défaut, la mention le dit).

1. Pastille d'état nominale d'un dossier (file, en-tête 02B, « État du dossier ») : « En cours de vérification », « À vérifier » ou aucune pastille ? Défaut : « En cours de vérification » (spec §18.1 l.1467).
2. Vérifications : pastilles « À vérifier » et numéros 1, 2, 3, ou case manuelle seule ? Défaut : case manuelle du code, sans pastille ni numéro (dossiers_page.dart:389-429).
3. « Refuser le dossier » (02B et 02D) : accepter le niveau destructif sans contour, malgré le commentaire « jamais dans la zone principale » ? Défaut : niveau destructif existant, sans contour (action_principale.dart:28-30).
4. Avatars d'initiales (file et en-tête 02B) : garder en décoration avec AvatarTile ou retirer ? Défaut : retirés (spec §9.4 l.614-619).
5. En-tête de coque : garder la recherche, le bouton thème, la cloche ? Défaut : recherche gardée, bouton thème ajouté, cloche seulement si les notifications existent (spec §19.3 l.1547-1548).
6. Détail bureau : deux sous-colonnes avec ordre de focus imposé, ou une colonne de 728 ? Défaut : une colonne de 728 (spec §10.6 l.792).
7. Espacement entre sections sur bureau : 32 (contrat A) ou 24 (§26 ter l.1925) ? Faut-il corriger §26 ter ? Défaut : 32 (règle gelée).
8. Date dans la file : format complet (pastille sous le nom si besoin) ou ancienneté relative avec date complète en sémantique et en 02B ? Défaut : « dd/MM/yyyy à HH:mm (zone IANA) » sur la ligne (spec §26 ter l.1929).
9. Rôle au féminin (« Enseignante ») ? Défaut : « Enseignant » pour tous (code fr.i18n.json:1824 ; spec §10.11 l.873).
10. Textes d'état de la pièce (« Pièce disponible », « Disponible ») et des accords (« Acceptation versionnée disponible », « Disponible pour revue ») ? Défaut : aucun texte affiché (ni spec ni code).
11. Emplacement et forme de la mention « Démonstration » (02A, 02B, 02C, 02D, 02E) ? Défaut : le repère « Démonstration » déjà utilisé par le mode démonstration du tuteur (P2-07), placé dans l'en-tête de page ; « Document fictif » sur la pièce.
12. Noms de démonstration : ceux de l'image ou les fixtures du code ? Défaut : fixtures du code (persona.dart:613-655).
13. Bouton Valider : désactivé avec l'aide permanente, ou variante « activable » (UX_REVIEW modif. 11) ? Défaut : désactivé, avec « Terminez les vérifications requises. » (spec §26 ter l.1956).
14. DisqueRetour vers /admin sur bureau : partout, ou seulement en tiroir et en rail ? Défaut : partout (spec §26 ter l.1923).
15. Seuil de repli du maître-détail entre 1200 et 1439 de large ? Défaut : repli sous 1088 de largeur utile ou à 200 % de texte (spec §10.6 l.793).
16. Compteur « {n} dossiers en attente » : masqué jusqu'à AD-BR, ou affiché sur le décompte actuel (par pièce) ? Défaut : masqué hors démonstration (spec §9.4 l.611, total fiable exigé).
17. Carte « Identité et dossier » : grille 2 x 2 ou lignes à filets ? Défaut : lignes à filets, LigneCleValeur (spec §10.7 l.799-801).
18. « Actualiser les dossiers » sur mobile : au trailing de l'en-tête, ou sous le compteur, aligné end ? Défaut : aucune valeur dans la spec ni le code ; trailing de l'en-tête (UX_REVIEW groupe 2 l.34).
19. Apostrophe : droite (spec §10-§11, code) ou courbe (image, spec l.1975 et §13.2) ? Harmoniser ou copier chaque source ? Défaut : chaque source copiée telle quelle ; droite pour les clés existantes (« Pièce d'identité », « Carte d'identité »).
20. Élision « d'Aïcha » dans le corps de 02E (spec « Le dossier de {nom} ») ? Défaut : « de {nom} », sans élision (spec §13.2).
21. Corps de 02E sans contrat serveur de conséquence : quelle variante ? Défaut : variante documentaire en démonstration ; hors démonstration, « La validation est indisponible pour le moment. » (spec §13.2 l.1115-1119).
22. Ordre de 02E : carte « Type de dossier » avant ou après la conséquence ? Défaut : avant (spec §26 ter l.1999).
23. Affichage « 100 % » du zoom en 02C ? Défaut : non affiché (ni spec ni code).
24. Pièce fictive de 02C : remplacer « DOCUMENT D’IDENTITÉ » par « Document fictif », ou ajouter à côté ? Défaut : « Document fictif » seul, étiquette sans source retirée (spec l.2053).
25. Bornes du zoom (minimum, maximum) ? Défaut (K-32, K-35 : jamais d'attente sans décision) : 100 % à 400 % par pas de 25 %, retour à 100 %, sans valeur de spec ; à confirmer.
26. Structure en pied fixe de 02C (zone de lecture pleine hauteur, commandes fixes), malgré l'écart de 85 au zoom 100 % ? Défaut : structure d'UX_REVIEW l.66 (ni spec ni code plus précis).
27. Format de la ligne nom/type du dialogue 02D ? Défaut : « {nom} · {type} » (spec §26 ter l.1983, « nom/type »).
28. Espace aide → actions dans AppBottomSheet : 24 du composant, ou 16 du contrat B par évolution partagée ? Défaut : 24 du composant (app_bottom_sheet.dart:247), sans fork.
29. À 768 : faire évoluer AppBottomSheet vers un dialogue (spec l.1983), ou accepter la feuille bornée ? Défaut : feuille bornée du code tant que le composant n'évolue pas.
30. Longueur maximale du motif de refus ? Défaut : aucune valeur ; seule l'erreur serveur « Le motif dépasse la longueur autorisée. » s'affiche.
31. Emplacement du réglage de genre : « Configuration » ou « Sécurité et audit » ? Défaut : aucune surface créée avant BR-1 (spec l.1193 : surface Super Admin « lorsqu'elle existe »).
32. Modèle d'interaction du réglage : fenêtre avec Annuler et enregistrement, ou ligne qui agit à la bascule ? Libellé du bouton si fenêtre ? Défaut : aucune valeur dans la spec ni le code ; ligne interactive sans bouton (UX_REVIEW l.102). **AD-9 livré (écart ouvert)** : la ligne agit à la bascule, mais seul l'interrupteur réagit au tap ; le libellé et l'aide ne basculent pas (LigneRubrique : une ligne à « controle » n'est pas pressable, nom fusionné par MergeSemantics). Rendre toute la ligne pressable = évolution du composant partagé GroupeReglages, qui touche une douzaine d'appelants (compte, cahier, caméra, config_edition...) : à trancher par le directeur (E2), non fait sans décision.
33. Composant du réglage : GroupeReglages / LigneRubrique, SwitchListTile ou AppCard ? Défaut : GroupeReglages / LigneRubrique avec slot « controle » (code existant, contrat C l.278).
34. Titre de la surface : « Paramètre Super Admin », « Configuration Super Admin » ou autre ? Défaut : titre de la section de spec §15 (texte exact), sans identifiant de maquette.
35. Identifiant de la surface (l'image dit « ADM-02.4 », exclu par la spec) ? Défaut : aucun ; « ADM-02.4 » reste le nom de la maquette.
36. Libellé « Activée » / « Désactivée » près de l'interrupteur ? Défaut : retiré (aucune source).
37. Mention « Les changements sont enregistrés et audités. » une fois l'audit prouvé (AD-BR n°17), ou jamais ? Défaut : non affichée.
38. Libellé « Limiter la revue KYC selon le genre » ou formulation sans « KYC » (§18.1 l.1472) ? Défaut : texte de la spec l.1195.
39. Qui rédige les textes des états du réglage (chargement long, échec, conflit expected_version, accès refusé) ? Défaut : composants partagés, aucun texte inventé. **AD-9 livré (choix inscrit)** : le conflit expected_version est rendu par l'échec générique « Le réglage n'a pas pu être enregistré. » (clé existante @:admin.groupes.observationErreur), puis l'interrupteur est relu sur la valeur serveur ; la capture ad9_4_conflit ne se distingue donc pas d'un échec. Un texte de conflit propre (E3) attend une phrase validée par le directeur.
40. Fondation Super Admin : claim ou table de capabilities (pas de valeur super_admin dans app_role) ? Défaut : en démonstration, une capacité « Super Admin » simulée dans le port de démonstration (AD-4), sans toucher `app_role` ; la fondation serveur (claim ou table) est un besoin AD-BR / BR-1. AD-9 se livre en démonstration (K-35), comme le prévoit sa ligne au tableau.
41. « Profil à compléter » (§15.3, P-ADM-07.6-7, AC-11) sans l'action « Compléter mon profil » : l'état reste sans issue, hormis « Actualiser les dossiers », alors que §15.4 exige une UI récupérable. Écart assumé en AD-9 : /compte/profil n'a pas de champ genre et ne doit pas en avoir (§3.6) ; brancher le bouton ouvrirait l'auto-modification du genre tant que la RPC administrative auditée d'AD-BR-20 n'existe pas. À trancher : garder l'état sans action, ou une phrase qui dit à qui s'adresser (texte à fournir, E4) ?
