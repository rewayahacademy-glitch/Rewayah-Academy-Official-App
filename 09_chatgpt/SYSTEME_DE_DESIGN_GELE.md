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
| `ombre` | `#211E28` dans les deux thèmes | Couleur de toutes les ombres rendues à `cefab7f`. [critique] Une seconde couleur existe : `ombreDialogue` = noir `#000000` (`app_palette.dart:325`), consommée seulement par `AppElevation.dialogue()`, que rien n'appelle (voir §5) |

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
| `dialogue()` | `niveau2` en clair (couleur `#000000`, `ombreDialogue`), **aucune ombre en sombre** | [critique] **Aucun emploi réel** : la fonction n'est appelée nulle part dans `lib/` à `cefab7f`. La feuille ET la boîte de dialogue d'`AppBottomSheet` rendent `niveau3` en `#211E28` dans les deux thèmes, sombre compris, avec le filet `borderHairline` ; la boîte de dialogue prend `surfaceOverlay`, rayon 24 (`app_bottom_sheet.dart:189-208`). À dessiner selon ce rendu, ou à trancher |

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
| Couleur de démarrage [critique] | **ÉCART** : le fond affiché pendant le chargement web vaut `#F8F4EE`, l'ancien crème archivé, et non `surfaceCanvas` `#F8F7FA` (`web/index.html:49` ; `web/manifest.json`, `background_color`), sans variante sombre : éclair clair au démarrage en thème sombre. `theme_color` = `#8652E6`. Android : fond de lancement du gabarit Flutter, couleur système `?android:colorBackground` (`android/app/src/main/res/drawable-v21/launch_background.xml:4`), pas un jeton | `web/index.html:40-49` (le commentaire renvoie à l'ancien `design-tokens.md`) |
| Maquettes existantes | 19 fichiers dans `docs de lancement/tutuor image/` ([critique] 9 dans `mobile/` et 10 à la racine, et non 10 dans `mobile/`), inventoriés et corrigés par le manifeste §1 et §5 ; écrans du tuteur encore sans maquette : `09_chatgpt/TUTEUR_ECRANS_SANS_MAQUETTE.md` | manifeste §1 |

## 13. Écarts et décisions en attente qui touchent le dessin

1. CTA en Interface guidée : aplat `surfacePrimary` gardé tant que le directeur n'a pas tranché sur capture (`action_principale.dart:235-240`).
2. Rail de tablette : icônes seules pour le tuteur, icône et nom pour élève et enseignant, en attendant une décision du directeur (`nav_shell.dart:283-291`).
3. Carte de choix : le code rend `washAccent` + filet `borderStrong` 1 + coche, rayon 24 ; le manifeste décrit bordure 2 `inkAccent` + radio 24 (manifeste §3.4, « Carte de choix ») ; extension radio, description et miniature demandée (`demandes/E.md:44-48`).
4. `lib/CLAUDE.md:45-46` dit encore « `inkFaint` interdit sur `surfaceSunken` (4,48) » : valeur périmée, mesure actuelle 4,65 (`04_phase0/0b_jetons.md:82`, `:121`).
5. Préférence clair / sombre non persistée sur le web : perdue à chaque rechargement (`revue_jetons_a11y.md:36`, D10).
6. Quatre commentaires du code annoncent des valeurs que le code n'applique pas : gouttières (§3.3), opacités d'ombre et « filet ET ombre » (§5), durées de feuille (§6). Les valeurs du code font foi.
7. [critique] Ombre des dialogues en sombre : la règle « aucune ombre en sombre » (`AppElevation.dialogue()`) n'est appliquée par aucun composant ; `AppBottomSheet` rend `niveau3` dans les deux thèmes (§5).
8. [critique] Fond de démarrage web `#F8F4EE` hors palette gelée, sans version sombre (§12). À aligner sur `surfaceCanvas` clair et sombre par décision, puisque le gel exige une décision datée pour toute valeur.
