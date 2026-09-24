# 00 - Manifeste visuel du chantier frontend Tuteur V1

Date : 24/09/2026. Rédacteur : synthétiseur du manifeste visuel (lecture seule, aucun fichier du dépôt modifié).

Sources consolidées :
- `pilotage-tuteur-v1/BRIEF.md` ;
- mandat `docs de lancement/REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§2, §4, §5, §6, §8, §9, complément « observation » §1-§8) ;
- les 9 rapports `01_visuel/V1_accueil_mobile.md` à `V9_anciennes_captures.md` ;
- jetons actuels du dépôt (lecture seule) : `lib/core/theme/app_palette.dart`, `app_typography.dart`, `app_radius.dart`, `app_spacing.dart`, `app_elevation.dart`, `app_theme.dart`, plus `app_gabarit.dart` et `lib/core/widgets/nav_shell.dart` pour le shell.

Contrôle d'arbitrage personnel : j'ai ouvert moi-même `acceuil tuteur desktop light.png` et `mobile/accueil  tuteur mobile light mode.png`, puis rééchantillonné 45 zones (System.Drawing, mode des aplats, 6 % d'encre la plus sombre pour le texte, 10 % des pixels les plus saturés pour les accents). J'ai aussi contrôlé les fonds et cartes de trois maquettes sombres (`acceuil tuteur desktop dark.png`, `mobile/mon compte tuteur desktop dark mode.png`, `réglages tutor mobile dark mode.png`). Les valeurs marquées « contrôle » ci-dessous viennent de ce rééchantillonnage.

| Zone (contrôle) | Mobile Accueil clair | Desktop Accueil clair |
|---|---|---|
| Fond de page | `#F6F6F8` | hors shell `#F8F7FE`, contenu `#FDFDFE` |
| Carte | `#FEFDFE` | séance teintée `#F7F5FE`, colonne droite `#FDFDFE` |
| Bloc imbriqué | `#F4F3F6` | absent |
| CTA doux | `#DAC7FD`, libellé `#020105` | `#DFD2FD`, libellé `#000013` |
| Accent icône / onglet actif | `#B491F8` (pâle) | `#7D4AEE` (saturé) |
| Accent texte / lien | libellé d'onglet `#AC85F6` | `#6534E6` (nav), `#784BEA` / `#6F42E9` (liens) |
| Monogramme (fond / lettre) | `#F2EDFD` / `#AB85F8` | `#E8E0FD` / `#7D4BED` |
| Anneau profil actif | `#B594F6` | `#B99EF8` (cœur saturé `#936AF9`) |
| Pastille verte (fond / texte) | `#DBF9E5` / `#154A27` | `#E1F1EE` / `#0E8045` ; « Présente » `#E4F6EE` / `#0E5920` |
| Titre de page | `#0E071D` | `#000017` |
| Texte secondaire | `#56545F` | `#646581` |
| Texte tertiaire | `#706E7B` | `#70718F` |
| Alerte | fond `#FEF6E7`, icône `#D18B07` | pas de fond, icône `#F29704` |

| Zone (contrôle, sombre) | Accueil desktop sombre | Compte mobile sombre | Réglages sombre |
|---|---|---|---|
| Fond | `#21222D` (planche `#1B1D25`) | `#161822` | `#1A1A25` |
| Carte | `#2B2B39` (séance), colonne `#1F1F2A` | `#1B1D28` | `#23232F` |
| CTA plein / nav active | `#BC9BFC` / `#BA98FB` | `#B790F8` | - |

Conclusion du contrôle : **les deux high-fi clairs de l'Accueil n'emploient pas le même accent**. Le mobile utilise un lavande pâle (≈ `#AC88F7`, 2,8:1 sur blanc) pour icônes et onglet actif ; le desktop, le Compte (V3) et l'Observation (V8) emploient un violet saturé (≈ `#6538E4` à `#7B48ED`). L'arbitrage retient le violet saturé pour tout texte, icône porteuse de sens et état actif, et réserve le lavande aux fonds et anneaux (§3.1).

---

## 1. Manifeste des références visuelles

19 fichiers dans `D:\RA _APP\docs de lancement\tutuor image\` (dont 10 dans `mobile\`), tous ouverts par au moins un agent. Les planches multi-écrans sont découpées par zone (coordonnées en pixels source). Les étiquettes de planche (« TABLETTE », « 01 / Compte », « 1 OBSERVATION EN DIRECT… ») et le chrome système iOS (« 9:41 », indicateur d'accueil) ne sont pas de l'interface.

| # | Fichier exact (px) | Zone | Écran représenté | État | Thème | Format | Statut | Route logique (§4) | Rapport |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `acceuil tuteur desktop light.png` (1774×887) | entière | Accueil tuteur + shell, rail déplié, 4 destinations | Nominal jour J, T-13 min, salle ouverte, blocage « aucun appareil », 3 tâches, dernière séance présente | Clair | Desktop ≈ 1440 dp | Nouveau high-fi | `/tuteur/accueil` | V2 |
| 2 | `acceuil tuteur desktop dark.png` (1774×887) | x 36-642 (« TABLETTE ») | Accueil tuteur + rail replié | Identique à #1 | Sombre | Tablette portrait ≈ 690 dp | Nouveau high-fi (planche 2 formats) | `/tuteur/accueil` | V2 |
| 3 | idem | x 677-1740 (« DESKTOP / WEB ») | Accueil tuteur + rail déplié | Identique à #1 | Sombre | Desktop étroit ≈ 1100 dp | Nouveau high-fi (planche 2 formats) | `/tuteur/accueil` | V2 |
| 4 | `mobile\accueil  tuteur mobile light mode.png` (845×1862, deux espaces) | entière | Accueil tuteur, barre basse **3 onglets** | Nominal jour J, T-13, profil Mariam, blocage appareil + lien photo | Clair | Mobile | Nouveau high-fi | `/tuteur/accueil` | V1 |
| 5 | `mon compte tuteur desktop light mode.png` (1672×941) | entière | Mon compte + rail 4 destinations (Compte actif) | Nominal, accès actif, foyer de 4 | Clair | Desktop | Nouveau high-fi | `/tuteur/compte` (existant `/compte`, `routes.dart:291`) | V3 |
| 6 | `mobile\mon compte tuteur mobile light mode.png` (805×1953) | entière (pleine hauteur) | Mon compte, barre basse 4 destinations | Nominal | Clair | Mobile | Nouveau high-fi | `/tuteur/compte` | V3 |
| 7 | `mobile\mon compte tuteur desktop dark mode.png` (805×1954) | entière | **Mon compte version MOBILE** (nom de fichier faux) | Nominal | Sombre | Mobile | Nouveau high-fi | `/tuteur/compte` | V3 |
| 8 | `réglages tutor mobile dark mode.png` (1672×941) | écran 01, x 343-753 | Réglages (hub des préférences du titulaire) | Nominal | Sombre | Mobile | Nouveau high-fi (planche de flux) | `/tuteur/compte/preferences` (existant `/compte/reglages`, `routes.dart:297` ; **≠** `/tuteur/reglages` = réglages par enfant) | V4 |
| 9 | idem | écran 02, x 918-1328 | Apparence | « Système » sélectionné, 2 bascules désactivées | Sombre | Mobile | Nouveau high-fi | sous-route de `.../preferences` (à créer ou section) | V4 |
| 10 | `onboarding Mble.png` (941×1672) | entière | Choix d'usage « Quel type de compte… », 2 sur 5 | Option 2 sélectionnée, CTA actif | Sombre | Mobile | Nouveau high-fi | `/onboarding/usage` | V5 |
| 11 | `onboarding Mble d.png` (941×1672) | entière | Genre, 3 sur 5 (« d » ne veut pas dire dark) | « Homme » sélectionné | Sombre | Mobile | Nouveau high-fi | `/onboarding/...` identité (existant `/inscription`, page genre) | V5 |
| 12 | `onboarding mobile 1.png` (1806×871) | E1, x 149-612 | Usage « Pour qui créez-vous ce compte ? », 1 sur 6 | « Moi uniquement » sélectionné | Sombre | Mobile | Nouveau high-fi (planche de flux) | `/onboarding/usage` | V6 |
| 13 | idem | E2, x 674-1132 | Genre, 2 sur 6 | « Homme » sélectionné | Sombre | Mobile | Nouveau high-fi | `/onboarding/...` identité | V6 |
| 14 | idem | E3, x 1194-1656 | Âge (champ « 28 ans »), 3 sur 6 | Rempli | Sombre | Mobile | Nouveau high-fi | `/onboarding/...` âge (existant : tranche serveur, `parcours_offres`) | V6 |
| 15 | `Onboarding mobile 2.png` (1806×871) | E4, x 149-612 | Langue de l'application, 4 sur 6 | « Français » sélectionné | Sombre | Mobile | Nouveau high-fi | relève de `.../preferences`, pas de l'admission (voir §5) | V6 |
| 16 | idem | E5, x 674-1132 | Objectif, 5 sur 6 | Une option sélectionnée | Sombre | Mobile | Nouveau high-fi | `/onboarding/...` objectif | V6 |
| 17 | idem | E6, x 1194-1656 | Récapitulatif « Tout commence ici. », 6 sur 6 | Barre pleine | Sombre | Mobile | Nouveau high-fi | `/onboarding/recapitulatif` | V6 |
| 18 | `mobile\tuteur observation mobile light.png` (1536×1024, planche 01 « Parcours mobile ») | M1, x 196-551, y 79-593 | Classe de l'enfant, entrée d'observation, barre basse 4 | Séance en direct, enfant présente, 2 visites | Clair | Mobile | Nouveau high-fi | `/tuteur/classes/:classeId` | V8 |
| 19 | idem | M2, x 590-947, y 79-593 | Explication de première utilisation | Avant connexion, compteur arrêté | Clair | Mobile | Nouveau high-fi | `.../observer` (étape 0) | V8 |
| 20 | idem | M3, x 985-1342, y 79-593 | Salle d'observation | En direct, visite 1/2 | **Sombre** (malgré « light ») | Mobile | Nouveau high-fi | `.../observer` | V8 |
| 21 | idem | M4, x 196-551, y 612-1005 | Salle d'observation | En direct, visite 2/2 | Clair | Mobile | Nouveau high-fi | `.../observer` | V8 |
| 22 | idem | M5, x 590-947, y 612-1005 | Fin de visite | 1re visite terminée, 1 restante | Clair | Mobile | Nouveau high-fi | `.../observer` → classe | V8 |
| 23 | idem | M6, x 985-1342, y 612-1005 | Consentement « Les visites des parents » | Case non cochée, CTA désactivé | Clair | Mobile | Nouveau high-fi | `/onboarding/...` consentement | V8 |
| 24 | `tuteur observation desktop light.png` (1536×1024, planche 02) | D1, x 22-1075, y 85-630 | Observation en direct sur ordinateur | Visite 1/2 · 01:42 | Clair | Desktop | Nouveau high-fi | `.../observer` | V8 |
| 25 | idem | D2, x 1088-1520, y 68-635 | Historique, segment Observations, barre basse 4 | 3 lignes | **Sombre** | Mobile | Nouveau high-fi | `/tuteur/historique` | V8 |
| 26 | idem | D3, x 22-1075, y 645-1020 | Historique des observations (administration) | 3 lignes | Clair | Desktop | Nouveau high-fi | route admin existante (hors arbre tuteur) | V8 |
| 27 | idem | D4, x 1088-1520, y 645-1020 | Détail d'une observation | 2 visites | Clair | Mobile | Nouveau high-fi | absente de §4 : `/tuteur/historique/observations/:id` ou sous `/tuteur/seances/:seanceId` (à trancher) | V8 |
| 28 | `tutor observation map.png` (1972×2106, fond transparent) | entière | Logigramme du parcours Observation (14 nœuds, 20 arêtes) | Enchaînements et états | Clair (styles de l'outil de diagramme) | Sans format | **Planche de direction** (logigramme) : aucune valeur visuelle ne devient jeton | Classe → `.../observer` → classe | V7 |
| 29 | `mobile\Accueil.png` (1162×2559) | entière | Accueil, barre 3 onglets | Nominal | Sombre (ancienne palette) | Mobile | **Ancienne capture**, remplacée par #4 | `/tuteur/accueil` | V9 |
| 30 | `mobile\Foyer Member.png` (1162×2559) | entière | Foyer | 3 enfants, 1 appareil partagé | Sombre | Mobile | Ancienne capture, **seule référence de contenu** | `/tuteur/foyer` | V9 |
| 31 | `mobile\Historique.png` (1162×2559) | entière | Historique des séances d'un élève | 4 séances | Sombre | Mobile | Ancienne capture, seule référence séances | `/tuteur/historique` | V9 |
| 32 | `mobile\Classe Details.png` (1162×2559) | entière | Classe An-Nour (vue tuteur) | T-13, CTA d'observation | Sombre | Mobile | Ancienne capture | `/tuteur/classes/:classeId` | V9 |
| 33 | `mobile\Profil.png` (1162×2559) | entière | **Fiche de l'élève Mariam** (pas le compte ; onglet actif « Compte » faux) | Nominal | Sombre | Mobile | Ancienne capture | `/tuteur/foyer/:eleveId` | V9 |

Pièces manquantes à demander au directeur (mandat §2 : « demande uniquement le fichier manquant ») :
- **Planche 3 « États particuliers et notices de présence »** du complément observation : introuvable (V8 §1). Les états et notices sont à dériver (§6).
- Aucune **planche de direction de type design system** (échantillons, typographie) n'existe dans le dossier. `onboarding mobile 1/2.png` sont des planches de flux d'écrans high-fi, pas un nuancier. Les jetons ci-dessous sont donc déduits des écrans.

---

## 2. Écrans de l'arbre §4 sans maquette et référence de dérivation

Règle : composer avec les composants approuvés du §3.4, sans nouvelle direction artistique, et consigner la référence ici. « Contenu » = ancienne capture utile uniquement pour le contenu et l'ordre, jamais pour le rendu.

| Route logique | Écran | Maquette approuvée la plus proche | Ce qu'on en reprend |
|---|---|---|---|
| `/bienvenue` | Bienvenue | #17 récapitulatif E6 + #22 écran résultat M5 | Colonne centrée, titre DM Sans, sous-titre, CTA dominant ancré en bas, lien secondaire « connexion existante » |
| `/connexion` | Connexion | #14 champ E3 (gabarit d'étape V6 §6) | Champ encadré à étiquette flottante, erreur sous champ, CTA ancré ; lien « accès appareil élève » discret |
| `/recuperation` | Récupérer mon accès | #14 + #22 | Saisie E3 ; attente / lien expiré en écran résultat M5 |
| `/inscription` | Votre compte | #14 + #23 consentement M6 | Champs E3 ; consentements en lignes à case non précochée (M6) ; pas de double création |
| `/onboarding/...` identité (prénom, nom) | Question d'identité | #14 champ E3 | Deux champs E3 empilés, écart 12 |
| `/onboarding/...` élèves (branche familiale) | Élèves du foyer | #12 cartes de choix E1 + #14 | Liste de cartes E1 par élève nommé, ajout par champ E3 |
| `/onboarding/...` niveau, lieu et fuseau, moments | Questions pédagogiques | #16 lignes E5, #15 lignes E4 | Lignes de choix compactes à radio ; prénom de l'élève en contexte |
| `/onboarding/...` choix de classe | Choix d'une classe | Carte classe de #1 / #4 + cartes E1 | Voir `/tuteur/classes/catalogue` |
| `/tuteur/notifications` | Notifications | Lignes de l'historique #25 D2 + en-tête Accueil #1/#4 | Titre + cloche, liste à filets, date à gauche, chevron ; état vide M5 |
| `/tuteur/foyer` | Foyer | Contenu #30 ; rendu : lignes de rubrique de #5/#6 (Compte) + avatars du sélecteur #1/#4 | Titre, action « Ajouter un profil élève », groupe de lignes (avatar ou initiale, prénom, classe, statut textuel, chevron), section Appareils partagés en lignes ; pas de compteurs |
| `/tuteur/foyer/ajouter` | Ajouter un profil élève | Gabarit d'étape V6 (#12, #14) | Parcours plein écran, sans shell, même flux depuis Accueil, Foyer et Compte |
| `/tuteur/foyer/:eleveId` | Fiche élève | Contenu #33 ; rendu : carte d'identité + groupes de lignes de #5/#6 | En-tête (photo, prénom, âge, classe) puis lignes groupées ; onglet actif **Foyer** |
| `.../informations` (élève) | Informations de l'élève | Lignes #6 + champs E3 | Groupe de champs, photo (sélection, aperçu, progression) |
| `.../inscription` (élève) | Parcours et inscription | Récapitulatif E6 (#17) + lignes #6 | Rangées légende/valeur à filets inset, correction par rangée |
| `.../interface` | Interface | Options de thème de #9 (Apparence) | Cartes d'option à radio, sélection = bordure 2 + surface + radio |
| `.../camera` | Caméra en cours | Lignes à interrupteur de #9 (« Confort visuel ») | Ligne titre + légende + interrupteur (piste ≥ 3:1) |
| `.../acces` (élève) | Accès Rewayah | Carte « Abonnement et accès » de #5/#6 | Médaillon, statut en pastille, échéance réelle |
| `.../appareils` (élève) | Appareils | Contenu #33 ; rendu : lignes #6 + pastille « Appareil actuel » | Lignes appareil, action de retrait (confirmation), CTA « Connecter un appareil » |
| `/tuteur/foyer/appareils` | Appareils du foyer | Lignes #6 | Nom, profils autorisés, gestion |
| `/appareils/connexion` | Émetteur QR / code | Écran résultat M5 (#22) : colonne centrée | QR central sur fond blanc dans les deux thèmes, code manuel, état textuel ; succès en M5 |
| `/appareils/scanner` | Scanner | Salle M3 (#20) pour le plein cadre sombre ; D1 (#24) pour la version desktop centrée | Viseur plein écran, retour 48 dp, « Saisir le code » ; desktop : panneau centré, pas de feuille étirée |
| `/appareils/code`, `/appareil/pin` | Saisie de code / PIN | Champ E3 (#14) | Champ unique à chiffres tabulaires, erreur sous champ |
| `/appareil/profils` | Choisir mon profil | Grille de #11/#13 (cartes genre) + avatars du sélecteur | Grille 2 colonnes d'avatars, repli en pile à 200 % |
| `/tuteur/classes/catalogue` | Choisir une classe | Carte classe (#1 colonne gauche) + cartes E1 | Une carte par classe : parcours, enseignant (photo), toutes les séances, fuseau, places |
| `/tuteur/classes/:classeId` desktop et tablette | Classe | Mobile #18 M1 ; composition 2 colonnes de #1 | Colonne gauche = carte séance (enseignant, prochaine séance, observation) ; colonne droite = lignes Planning, Travail, Ressources, Progression, Historique |
| `.../planning` | Planning | Lignes de l'historique #25 D2 | Jour, heure locale, durée ; exceptions en pastille |
| `.../travail` | Travail à préparer | Liste de tâches à cercles (#1, #4) sans limite de 3 | Même composant, statuts du service |
| `.../ressources` | Bibliothèque | Lignes #6 + carte du support M3/D1 | Lignes ressource à chevron, lecteur existant |
| `.../progression` | Progression | Ligne « Dernière séance » (#1) + lignes #6 | Rangées de résultats partageables |
| `.../observer` : états de la planche 3 manquante | Enfant absent, vérification, visites épuisées, non commencée, terminée, désactivée, connexion prolongée, échec, reconnexion, caméra désactivée, aucun support | M1 (ligne d'état dans le bloc), M5 (écran résultat), M3/M4 (surimpression dans la salle) ; enchaînements #28 | Voir §6.3 |
| `/tuteur/historique` clair, et desktop | Historique | #25 D2 (sombre, mobile) ; contenu #31 | Titre, sélecteur, segment Séances / Observations, filtres, liste à filets |
| `/tuteur/seances/:seanceId` | Détail de séance | #27 D4 | Lien retour, titre, carte d'infos, rangées ; réseau seulement si mesuré |
| `.../informations` (compte) | Informations personnelles | Carte d'identité et lignes de #5/#6 + champs E3 | |
| `.../securite` | Connexion et sécurité | Carte « Sécurité et connexion » de #5/#6 | Méthodes réelles, sessions, mot de passe |
| `.../acces` (compte) | Abonnement et accès | Carte de #5/#6 | Statut exact et échéance réelle |
| `.../paiements` | Paiements | Liste #25 D2 + détail #27 D4 | Montant, devise, statut, date fournis ; indisponible propre sinon |
| `.../preferences` : Langue et région, Notifications | Sous-pages de préférences | #9 (lignes à radio et à interrupteur) | Même en-tête à disque retour 48 dp |
| `.../aide`, `.../informations-legales` | Aide, informations légales | Lignes de #5/#6 | Lignes sobres ; contenu réellement disponible |
| Fallback 404, accès refusé, session expirée | Pages transversales | Écran résultat M5 (#22) | Cercle héros, titre humain, phrase utile, action principale, lien secondaire |
| États §8 (chargement, hors ligne, erreur de bloc) | Famille d'états | Carte en place (squelette), M5 pour l'erreur globale | Voir §6.3 |

---

## 3. Langage visuel commun

### 3.1 Palette : jetons existants confrontés aux mesures

Méthode : pour chaque rôle, la « valeur mesurée » est la médiane des sources **nouveau high-fi** (V1 à V8), jamais les anciennes captures (V9). « Garder » quand l'écart est faible, que les sources divergent entre elles autour de l'existant, ou que l'existant est conforme AA et proche. « Ajuster » seulement quand toutes les sources s'accordent contre l'existant ou qu'une règle d'accessibilité l'impose. Tout ajustement touche les autres rôles (élève, enseignant, admin) : c'est au coordinateur, propriétaire unique du thème, de le valider sur leurs écrans.

Référence des valeurs existantes : `AppPalette.claire()` (`app_palette.dart:40-113`), `AppPalette.sombre()` (`:115-188`), `contourCarte` (`:245-249`, 8 % d'encre).

#### Thème clair

| Rôle sémantique | Jeton existant | Valeur existante | Valeur mesurée (sources) | Écart | Recommandation |
|---|---|---|---|---|---|
| Fond de page | `surfaceCanvas` | `#F8F7FA` | `#F6F6F8` (V1), `#F8F7FE` hors shell / `#FDFDFE` contenu (V2), `#FBFAF9` chaud (V3), `#F9F9FB` (V8) | Les sources divergent autour de l'existant | **Garder** |
| Carte | `surfaceRaised` | `#FFFFFF` | `#FEFDFE`, `#FDFDFE`, `#FEFEFE` | Nul | **Garder** |
| Carte mise en avant (séance desktop) | aucun | - | `#F7F5FE` (V2, contrôle) | Rôle manquant | **Ajouter** une paire (proposition `surfaceMiseEnAvant`, clair `#F7F5FE`) |
| Zone imbriquée, champ | `surfaceSunken` | `#F0EDF4` | `#F4F3F6` (V1), en-tête de tableau `#F6F6FB` (V8) | Faible | **Garder** |
| Contour de carte | `contourCarte` | 8 % de `#211E28` ≈ `#EDEDEE` sur blanc | `#EDEDF1` (V1), `#EDEEF9` (V2), `#EDEEEF` (V3), `#EEF0F5` (V8) | Nul | **Garder** ; les cartes et séparateurs tuteur consomment `contourCarte`, pas `borderHairline` |
| Filet de champ, `outlineVariant` | `borderHairline` | `#E3DEE9` | séparateurs `#EFEFF4`, `#E8E6F4`, `#F0F0F5`, `#F3F3F8` | Existant plus foncé | **Garder** (utilisé par les champs et les autres rôles) ; ne pas l'employer comme séparateur de liste tuteur |
| Texte principal | `inkStrong` | `#211E28` (16,9:1) | `#0D0820` (V1), `#000017` (V2), `#0C0F1F` (V3), `#000012` (V8) | Mesuré nettement plus noir et plus bleu (ΔL* ≈ 7), visible sur les titres de 28-34 dp | **Ajuster**, priorité basse → `#110E20` |
| Texte secondaire | `inkMuted` | `#655E70` (6,2:1) | `#5A5863` (V1), `#646581` (V2), `#6E7491` (V3), `#6E7392` (V8) | Teinte légèrement plus froide, contraste équivalent | **Garder** |
| Texte tertiaire, légende | `inkFaint` | `#84798F` (4,1:1 sur blanc, **sous AA**) | `#74727F` (V1), `#70718F` (V2), `#737895` (V3) | Existant plus clair et non conforme AA pour du texte | **Ajuster** → `#6A687E` (5,4:1 sur blanc, 4,6:1 sur `surfaceSunken`) |
| Accent texte, lien, icône porteuse, état actif | `inkAccent` | `#5B36B0` (8,1:1) | `#6534E6` / `#784BEA` (V2, contrôle), `#5D1AF9` / `#6439E6` (V3), `#5D25F2` (V8) ; **V1 mobile `#AC88F7` non retenu** (2,8:1) | Mesuré plus saturé et plus bleu | **Ajuster** → `#6538E4` (6,5:1 sur blanc, 6,0:1 sur `#F7F5FE`, 5,3:1 sur `washAccent`) |
| Accent plein (anneau de sélection, progression) | `surfacePrimary` | `#8652E6` / encre `#FFFFFF` (4,8:1) | anneau `#9974F5` (V2), `#B594F6` (V1, contrôle) ; aucun CTA violet plein en clair | Anneau mesuré plus pâle mais sous 3:1 | **Garder** ; l'anneau du sélecteur consomme `surfacePrimary.background` (≥ 3:1) au lieu du lavande mesuré |
| CTA dominant (doux) | aucun | - | `#DAC7FD` (V1), `#DFD2FD` (V2), `#E2CFFE` / `#E8D6FE` (V3), `#D6C5FC` (V8) ; libellé quasi noir | Rôle manquant : le thème actuel remplit le `FilledButton` de `surfacePrimary` (`app_theme.dart:93-106`), ce qu'aucune maquette claire ne montre | **Ajouter** une paire (proposition `surfaceActionDouce`) clair `#DCCAFD` / encre `inkStrong` (≈ 11:1) ; en sombre elle vaut l'accent plein (voir plus bas) |
| Fond doux accent (nav active, monogramme, médaillon, encart) | `washAccent` | `#EEE6FA` / `#4E2983` | nav `#F1EDFE` (contrôle) / `#F2EBFE` (V3), monogramme `#E8E0FD`, médaillon `#F7F1FE`, encart `#EFEAFD` (V8) | Nul | **Garder** |
| Pastille succès (fond / texte) | `washSuccess` | `#E4F4EB` / `#175D3A` | `#D8F9E4` / `#1A4F2D` (V1), `#E1F1EE` / `#0E8045` (V2), `#E1FCEA` / `#0B9442` sous AA (V3), `#DEFDE9` (V8) | Nul | **Garder** |
| Point de statut succès | `surfaceSuccess` | `#70EE9C` (1,5:1 sur blanc) | `#22CA6B` (V1), `#04B764` / `#03C16C` (V2), `#1FD069` (V8) | Existant trop pâle pour un point sur blanc | **Ajuster l'usage** : groupe de points de statut dédié (tableau suivant) ; `surfaceSuccess` reste la surface pleine |
| Avertissement (fond de bandeau) | `washWarning` | `#FFF2CE` / `#755200` | fond `#FEF6E7`, bordure `#F8ECD9`, bouton `#FEE9BB`, icône `#D18B07` (V1) | Fond existant visiblement plus jaune | **Ajuster** le fond → `#FEF5E4` ; garder l'encre `#755200` (≈ 7:1) ; bordure = encre à 12 % |
| Avertissement (surface pleine, point) | `surfaceWarning` | `#FFB703` | points `#EFA60F` (V1), `#FAB509` (V2) | Nul | **Garder** |
| Alerte (fond doux / encre) | `washAlert` | `#FCE8ED` / `#921734` | « Quitter » doux `#FEEBF1` / `#FEE0E6`, texte `#F80113` (V8) ; « Se déconnecter » `#EE2B47` (V3, 4,1:1) | Fond conforme ; encre existante bien plus sombre que le rouge vif mesuré | **Garder** le fond ; **ajuster** `inkAlert` → `#C21D3D` (5,9:1 sur blanc, 5,0:1 sur `washAlert`) |
| Alerte pleine | `surfaceAlert` | `#B01B3C` / `#FFFFFF` | point rouge `#E0375A` (V1), `#F53F54` (V2) | Existant plus sombre | **Garder** (surface pleine) ; le point consomme le groupe ci-dessous |
| Barre basse, rail | `surfaceRaised` | `#FFFFFF` | `#FDFCFD` (V1), `#FFFEFD` (V3), `#FDFDFE` (V2) | Nul | **Garder** |

Points de statut (groupe à ajouter, clair / sombre), toujours doublés d'un libellé textuel et d'une étiquette sémantique :

| Point | Clair mesuré | Sombre mesuré | Proposition clair / sombre |
|---|---|---|---|
| Succès, en direct, présent | `#22CA6B`, `#04B764`, `#1FD069` | `#3DF4A6`, `#34FBA9`, `#62F4AC` | `#1FC46A` / `#70EE9C` (= `surfaceSuccess` sombre, garder) |
| Attention, à venir | `#EFA60F`, `#FAB509` | `#F6B00E`, `#FFDC06` | `#FFB703` / `#FFB703` (= `surfaceWarning`, garder) |
| Alerte, interrompu | `#E0375A`, `#F53F54` | `#F92F4A`, `#FB5451` | `#E0375A` / `#F9505E` |
| Neutre, inactif | `#A7A4BC`, `#A5A6BB` | `#7B799B`, `#8380A0` | `#A5A4BC` / `#7F7D9E` |

#### Thème sombre

Toutes les maquettes sombres high-fi (V2, V3, V4, V5, V6, V8) s'accordent sur une **ardoise bleu-violet** ; l'existant est un quasi-noir chaud. C'est l'écart le plus important du lot.

| Rôle sémantique | Jeton existant | Valeur existante | Valeur mesurée (sources) | Écart | Recommandation |
|---|---|---|---|---|---|
| Fond de page | `surfaceCanvas` | `#111014` | `#21222D` (V2, contrôle), `#161822` (V3, contrôle), `#1A1A25` (V4, contrôle), `#161621` (V5), `#1A1923` (V6), `#23202C` (V8) ; médiane ≈ `#1A1A25` | Existant plus noir et plus chaud, contraire à toutes les sources | **Ajuster** → `#1A1A25` |
| Carte | `surfaceRaised` | `#1A181F` | `#1B1D28` (V3), `#23232F` (V4), `#1C1D2A` (V5), `#201F2B` (V6), `#2D2A38` (V8) ; médiane ≈ `#21212D` | Idem | **Ajuster** → `#22222E` |
| Carte mise en avant (séance), superposition | `surfaceOverlay` | `#2C2834` | carte séance `#2B2B39` (V2, contrôle) ; disque retour `#2B293A` (V4) | Teinte chaude contre froide | **Ajuster** → `#2B2B39` ; `surfaceMiseEnAvant` sombre = même valeur |
| Zone imbriquée, option non sélectionnée, champ | `surfaceSunken` | `#24212B` | `#252432` / `#292A37` (V4), piste de segment `#2A2734` (V8) | Teinte | **Ajuster** → `#262534` |
| Contour de carte | `contourCarte` | 8 % de blanc ≈ `#343440` sur `#22222E` | `#282B38` (V3), `#2E2E3B` (V4), `#333342` (V6), `#3B3C52` (V5) | Nul | **Garder** |
| Séparateur, `outlineVariant` | `borderHairline` | `#3A3443` | `#2B2E3C` (V3), `#2E2E3B` / `#30313F` (V4), `#2D2C3B` (V6), `#3C3C4C` (V2) | Teinte chaude | **Ajuster** → `#32323F` |
| Texte principal | `inkStrong` | `#F5F2FA` | `#FFFFFF`, `#FCFCFD`, `#F6F5F7` | Nul | **Garder** |
| Texte secondaire | `inkMuted` | `#BAB3C5` | `#B3B5D7` (V3), `#9A9DBE` (V4), `#AAAECE` (V5), `#A9B0CA` (V6), `#B0AFBB` (V8) ; médiane ≈ `#AEB1CE` | Chaud contre froid | **Ajuster** → `#AEB1CE` (8,2:1 sur le fond, 7,5:1 sur carte) |
| Texte tertiaire | `inkFaint` | `#95899F` | `#999CB8` (V3), `#8588A4` (V4), `#8C91A8` (V6) | Teinte | **Ajuster** → `#9194B0` (5,4:1 sur carte) |
| Accent texte, icône | `inkAccent` | `#C9AEFF` | `#CDB6F5` / `#CFB0FF` (V2), `#CBABFD` (V3), `#C4A0FB` (V4), `#C9A8FB` (V5) | Nul | **Garder** |
| Accent plein (CTA dominant, nav active, radio, progression) | `surfacePrimary` | `#C9AEFF` / `#25113F` | `#BC9BFC` / `#BA98FB` (V2, contrôle), `#B790F8` (V3, contrôle), `#BC98FA` (V5), `#BA9FFC` (V6) ; libellé `#0B011C` à `#010002` | Existant plus pâle, contraire à toutes les sources | **Ajuster** le fond → `#BA98FB` ; **garder** l'encre `#25113F` (7,3:1) |
| Fond doux accent (sélection, monogramme, médaillon, segment actif) | `washAccent` | `#332643` / `#E8D8FF` | `#2F2B42` (V4), `#28233F` (V5), `#292438` (V6), médaillon `#2C2842` (V3), segment `#514871` (V8), monogramme `#534D71` (V2) | Faible | **Garder** ; monogramme et segment actif peuvent monter à `#514871` (variante renforcée, à documenter) |
| Pastille succès | `washSuccess` | `#173B2B` / `#9DDEB5` | `#254D45` / `#214A42` (V2), `#233938` / `#85F2BF` (V3), `#283D3A` (V8) | Fond existant un peu plus vert, encre conforme | **Garder** |
| Avertissement | `washWarning` | `#44361A` / `#F4D480` | aucune source high-fi (icône `#FFBC33`, V2) | - | **Garder** |
| Alerte | `washAlert` | `#4A2030` / `#FFD9E0` | pastille « Interrompue » `#58293B` (V8), texte « Se déconnecter » `#F06168` (V3) | Fond conforme ; encre existante rose très pâle contre rouge clair mesuré | **Garder** le fond ; **ajuster** `inkAlert` → `#F4777D` (5,8:1 sur carte) |
| Barre basse | aucun spécifique | - | `#191D26` (V3) ; **gris neutre `#4B4B4B` (V8) et `#5D5D5D` (V9) rejetés** | - | Consommer `surfaceRaised` + `contourCarte` |
| Surface Coran | `surfaceQuran` | inchangée | - | - | **Garder** (paire volontairement figée, `app_palette.dart:5-7`) |

### 3.2 Rayons, espacements, élévations

Échelle : les mesures en dp dépendent d'une hypothèse d'échelle. Les images mobiles V1 et V3 sont environ 1,4 fois plus denses qu'un vrai écran de 390 dp (V1 §2, V3 §2) ; V4 (1,054 px/dp), V6 (0,844 px/dp), V8 mobile (1,095 px/dp) et V2 desktop (1,232 px/dp, CTA = 48 dp) sont réalistes. **On reprend les proportions et la hiérarchie, puis on arrondit à l'échelle de jetons.** Aucune distance absolue n'est recopiée.

Rayons (`app_radius.dart:13-33`) :

| Élément | Mesuré | Jeton recommandé | Statut |
|---|---|---|---|
| Carte, groupe | 12-16 (V1 ≈ 13, V2 14, V3 16 mobile / 10 desktop, V4 16, V5 12-15, V6 12, V8 12) | `md` 16 | Garder |
| Bloc imbriqué, bandeau, option, rail actif | 10-12 | `sm` 12 | Garder |
| Bouton et CTA dans l'app | 12-14 (V1, V2), 12 (V3), 8-10 (V8) | `sm` 12 | **Ajuster le thème** : `app_theme.dart:24` et `:54` posent `arrondiMd` (16) sur boutons et champs, alors que `AppRadius.sm` est documenté « Champs, boutons » |
| CTA de l'admission (V5, V6) | pilule (rayon ≈ 27) | `full` | À trancher : conserver la pilule pour le seul gabarit d'étape d'admission, ou unifier à `sm` (§5, registre F) |
| Pastilles de statut, chips de filtre | pilule (V1, V2, V8) ; 8 (V3) | `full` | Garder `full` ; V3 est l'écart |
| Barre basse flottante | stade (V1) ; ≈ 16 (V3) | `md` 16 | Retenir V3 (seule barre mobile conforme à 4 destinations) |
| Avatars, radios, points | cercle | `full` | Garder |
| Cadre arrondi du shell desktop sur fond lavande (V2) | ≈ 20 | aucun | Mise en scène de maquette, non reproduite |

Espacements (`app_spacing.dart:13-42`, `AppPage` `:63-83`, `AppGabarit.margePour` `app_gabarit.dart:79-83`) :

| Espace | Mesuré | Jeton recommandé |
|---|---|---|
| Gouttière mobile | 16 (V4, V6, V8 à échelle réaliste) ; 19-24 (V1, V5 en proportion) ; 39 (V3) | `gouttiereMobile` 16 : **garder**. Point unique d'alignement : titre de page, bord des cartes et sélecteur sur la même verticale (V1 aligne mal le titre, x 64 contre 50) |
| Gouttière tablette / desktop | ≈ 20 (V2) | `margePour` 24 / 32 : garder |
| Padding de carte | 16-20 mobile, 25-28 desktop | `lg` 16 mobile, `xxl` 24 desktop |
| Entre cartes | Accueil 18-28 selon l'échelle (V1) ; listes de rubriques 12 (V3), 10-11 (V4), 12 (V8) | `lg` 16 entre blocs de l'Accueil ; `md` 12 entre cartes de rubriques ; gouttière de colonnes desktop 16 |
| En-tête de page → sélecteur | 13-20 | `md` 12 à `lg` 16 |
| Sélecteur → première carte | 26 desktop, 31-49 mobile | `xxl` 24 |
| Titre → première carte (sans sélecteur) | 16-28 | `xxl` 24 |
| Ligne de liste (tâche, historique) | 39-44 mesurés, **sous 48** | 48 minimum (`AppTouchTarget.standard`) |
| Ligne de rubrique à deux niveaux | 52-56 (V3), 67 (V4) | `hauteurReglage` 64 : garder |
| CTA | 48 (V2), 55 (V5, V6), 40 (V8, trop bas) | `hauteurBouton` 52 : garder |
| Cible des petits contrôles (repli du rail 33, segments de thème 31, « Modifier » 37-39, engrenage 39-41, case à cocher) | sous 48 | visuel conservé, zone tactile 48 |
| Réserve basse du contenu mobile | V1 masque la carte « Dernière séance » sous la barre | hauteur de barre + zone sûre + `lg` 16 |

Élévations (`app_elevation.dart`) : aucune maquette ne montre d'ombre perceptible sur les cartes ; les surfaces se distinguent par la teinte et un filet de 1 px (V1 §4.3, V2 §2.2, V3 §6).

| Surface | Recommandation |
|---|---|
| Cartes, groupes, lignes | `niveau0` + filet `contourCarte` : c'est déjà le défaut de `AppElevation.avecFilet` (`app_elevation.dart:85`). **Garder** |
| Barre basse flottante | `niveau1` + filet (V1 : bordure + ombre ambiante très faible) |
| Menus, popovers | `niveau2` |
| Feuilles, dialogues | `niveau3` / `dialogue` (inchangé) |
| Halo de sélection de l'admission (V5 : accent ≈ 15 %, flou ≈ 16) | Non retenu par défaut : la sélection est déjà portée par bordure 2 dp + surface + radio. Si le coordinateur le veut, il s'ajoute dans `app_elevation.dart`, seul fichier autorisé à construire une ombre |

### 3.3 Typographie

État du dépôt : **toutes** les entrées du `TextTheme` utilisent `InstrumentSans`, titres compris (`app_typography.dart:150-166`, `_corps` `:171-189`). `BricolageGrotesque` est déclarée (`:26`, `pubspec.yaml:126`) mais n'est employée que dans la galerie de développement (`galerie_page.dart:644`). Ni DM Sans ni Plus Jakarta Sans ne sont présentes, contrairement au mandat (« Jakarta est déjà déclarée ») : contradiction consignée par le BRIEF.

Règle écrite qui prévaut sur les images (complément observation §1) : **DM Sans pour les titres français** (`display*` s'il s'agit de titres, `headline*`, `title*`) ; **Plus Jakarta Sans pour tout le reste** (`body*`, `label*`, navigation, boutons, pastilles, statuts, champs, légendes). Les chiffres d'horaire et le chronomètre ne sont pas des titres français : Jakarta, chiffres tabulaires (`AppTypography.tabulaire`). Polices arabes inchangées. Le coordinateur doit vérifier qu'aucun écran existant n'emploie un style `title*` pour un libellé qui n'est pas un titre.

| Niveau | Mobile mesuré | Desktop mesuré | Jeton existant | Recommandation |
|---|---|---|---|---|
| Titre de page | 27-30 dp, 700-800 (V1 28, V3 27, V4 28, V5 28-30, V6 30) | 33-36 dp, 700 (V2 34-36, V3 33) | `headlineSmall` 28/36, 600 ; `headlineMedium` 32/40, 600 | Mobile `headlineSmall` 28 ; desktop `headlineMedium` 32. Taille **garder**, graisse **600 → 700**, famille DM Sans |
| Titre de section, de carte | 17-20 dp, 600 (V1 17-18, V3 18, V4 20) | 19-24 dp, 700 (V2 21-24, V3 19) | `titleMedium` 18/26, 600 ; `titleLarge` 22/28, 600 | Mobile `titleMedium` 18 ; desktop `titleLarge` 22 ; 600 ; DM Sans |
| Nom de l'élève dans la carte séance | 20-23 dp, 700 | ≈ 26 dp, 600-700 | `titleLarge` 22 ; `headlineSmall` 28 | Mobile `titleLarge` 22 ; desktop `headlineSmall` 28 (+8 % contre -15 % pour 22) ; DM Sans |
| Sous-titre de carte (classe) | 18-19 dp, 600-700 | ≈ 20 dp, 700 | `titleMedium` 18 | Garder ; DM Sans |
| Corps | 14 dp, 400 (V1, V3) ; 16 en admission (V5, V6) | 15-18 dp, 400 (V2, V3) | `bodyMedium` 14/20 ; `bodyLarge` 16/24 | Mobile `bodyMedium` 14 (admission `bodyLarge` 16) ; desktop `bodyLarge` 16 ; Jakarta 400 |
| Légende, méta, sous-libellé d'avatar | 12-13 dp, 400-500 | 14-15 dp | `bodySmall` 12/16 ; `labelMedium` 12, 500 | Mobile `bodySmall` 12 ; desktop `bodyMedium` 14 ; Jakarta |
| Libellé de navigation | 11-13 dp, 500 (V3 recommande 12) | ≈ 15 dp (rail) | `labelMedium` 12, 500 | Barre basse `labelMedium` 12 ; rail `bodyLarge` 16 en 500, actif 600 ; Jakarta |
| Libellé de CTA, bouton | 16-18 dp, 600 | ≈ 17 dp, 600 | `labelLarge` 16/20, 600 | Garder ; Jakarta |
| Pastille, chip | 12-14 dp, 500-600 | 13-14 dp | `labelMedium` 12, 500 | Garder ; Jakarta |
| Chiffre d'horaire (valeur forte) | « 13:45 Paris » ≈ 18 dp, 600 | « 13:45 » ≈ 40 dp, 700 ; « 1 h 30 » ≈ 25 dp | `titleMedium` 18 ; `displaySmall` 36, 600, tabulaire | Mobile `titleMedium` 18 en tabulaire ; desktop `displaySmall` 36 (garder, -10 %) en **700** ; durée desktop `titleLarge` 22 en 700 ; Jakarta tabulaire |
| Chronomètre d'observation « Visite 1/2 · 01:42 » | ≈ 15-18 dp | ≈ 18 dp, gras sur les chiffres | `titleMedium` 18 | Jakarta tabulaire, chiffres en 700 |
| Question de l'admission | 28-30 dp, 700-800 | - | `headlineSmall` 28 | Garder ; DM Sans 700 ; un mot en accent par texte riche i18n (décoratif) |

Remarques : l'échelle `enfant` (`app_typography.dart:79-86`) ne concerne pas le rôle tuteur ; le crénage `crenage()` reste calculé par taille ; apostrophe typographique U+2019 et espace fine insécable U+202F avant « ? » (V3 §5, V5 §7).

### 3.4 Composants récurrents

Icônes : Phosphor, déjà embarqué. **Regular** pour le contenu et la navigation inactive, **Fill** pour l'état actif et les médaillons (convention déjà codée dans `nav_shell.dart:27-28`). Icônes de section en `inkAccent`, 20-24 dp.

| Composant | Anatomie retenue | Jetons | États et accessibilité | Sources, divergences arbitrées |
|---|---|---|---|---|
| **Sélecteur de profils (avatars à pastille de statut)** | Rangée d'items : avatar rond (photo réelle, sinon initiale sur `washAccent`), point de statut en bas à droite cerclé de 2 dp de la couleur du fond, prénom, sous-libellé d'état. Dernier item : cercle à contour plein « + » et libellé court. Mobile : défilement horizontal ; desktop : aligné à gauche | Avatar 56 dp mobile / 72 dp desktop ; anneau 2 dp `surfacePrimary` ; point 12 dp (groupe de points) ; prénom `labelLarge` 600 `inkStrong` ; sous-libellé `bodySmall` `inkMuted`, **`inkAccent` pour le profil sélectionné** | `Semantics` « Mariam, en séance, sélectionnée » ; statut toujours doublé d'un texte ; cible 48 ; le profil du parent figure sans le mot « enfant » ; libellé visible « Ajouter », étiquette sémantique « Ajouter un profil élève » | V1, V2, V8 D2. Repli silhouette (V1, V2) contre initiale (carte) : **initiale partout**. Sous-libellé sarcelle `#139694` (V1) : rejeté. « + » pointillé en sombre (V2 B, C) : **contour plein** dans les deux thèmes |
| **Carte classe (séance)** | En-tête d'identité : portrait ou initiale de l'élève, prénom (titre), classe (sous-titre), **photo publique et nom de l'enseignant avec Sayyid / Sayyida**, parcours lisible. Puis bloc séance, CTA dominant « Voir la classe → », ligne d'aide appareil | Mobile : `surfaceRaised` + `contourCarte`, `md` 16, padding 16. Desktop : `surfaceMiseEnAvant` + filet, padding 24, séparateur interne `contourCarte` | Un seul CTA dominant ; ordre de focus = ordre visuel ; aucun lien « fournir une photo » concurrent d'un blocage | V1, V2. La photo de l'enseignant manque sur **toutes** les maquettes : à dériver (avatar 32-40 dp à gauche du nom) |
| **Bloc séance** | Ligne 1 : date ou « Prochaine séance » + pastille d'état à droite. Ligne 2 : deux colonnes (heure locale + ville de fuseau / durée) séparées par un filet vertical. Ligne 3 : horloge + compte à rebours. Ligne 4 : recommandation d'appareil | Mobile : zone imbriquée `surfaceSunken`, sans bordure, `sm` 12 (seule imbrication admise). Desktop : pas de zone, contenu à même la carte mise en avant | Compte à rebours issu de la même source que le sélecteur ; jamais négatif | V1 (imbriqué), V2 (à plat). Filet vertical plus foncé mesuré (`#A9A8AF`, `#AEAEC6`) : **`contourCarte`** comme les autres |
| **CTA dominant** | Pleine largeur, libellé + flèche → | Clair : `surfaceActionDouce` `#DCCAFD` + `inkStrong`. Sombre : `surfacePrimary` `#BA98FB` + `#25113F` ; `sm` 12, hauteur 52 | Un seul par écran ; état « en cours » contre la double soumission | V1, V2, V3, V8. Aucun CTA violet plein en clair. Deux couleurs de libellé en V8 (noir, violet en D4) : **encre `inkStrong`** |
| **Pastille « Salle ouverte »** (et toute pastille de statut : Présente, Accès actif, Terminée, Limite atteinte, Interrompue) | Pilule : point 8 dp + libellé | Fond `wash*`, texte `ink*` du même rôle, point du groupe de points ; hauteur 28-32 ; padding 12 × 6 ; `labelMedium` | Jamais la couleur seule ; « Salle ouverte » selon la fenêtre de la politique, pas à T-13 fixe | V1, V2, V3, V8. Forme `sm` 8 (V3) : **pilule** |
| **Bandeau d'alerte ambre** (action bloquante unique) | Mobile : bandeau pleine largeur, icône cerclée, titre, phrase concrète, action. Desktop : bloc de tête de la colonne droite, icône orange, titre, corps, lien d'action | Fond `washWarning` ajusté `#FEF5E4`, bordure encre à 12 %, `sm` 12 ; icône `#D18B07` ; titre `titleSmall` DM Sans ; bouton tonal ambre | Un seul blocage à la fois, confirmé par les données ; action sur une ligne ou sous le texte (V1 : bouton coupé sur deux lignes) ; corps ≥ 4,5:1 (V1 : 3,87:1) | V1, V2, V9. Brun opaque des anciennes captures rejeté |
| **Liste de tâches à cercles** (« Avant le prochain cours ») | En-tête : icône livre accent + titre + « Voir tout → ». Au plus 3 lignes : cercle vide + libellé ; filets en retrait sous le texte, pas de filet sous l'en-tête | Cercle 22 dp, trait 1,5 dp `inkFaint` ; texte `bodyMedium` `inkStrong` ; filet `contourCarte` | Lignes ≥ 48 dp (mesurées 39-41) ; cocher ne signifie pas maîtrise ; pas de coche locale sans service | V1, V2. Texte tertiaire (V1) contre foncé (V2) : **foncé**. Tablette « 1 tâche + 2 autres activités » (V2 B) : 3 tâches partout |
| **Ligne « Dernière séance »** | Icône barres accent + « Dernière séance » ; date • durée ; à droite « Voir l'historique → » et pastille de présence ; desktop : ligne « Détails de la séance › » | Titre `titleMedium` ; méta `bodySmall` `inkMuted` ; lien `inkAccent` | Réseau (élève, enseignant) **masqué par défaut**, affiché seulement si mesuré et autorisé ; présence incertaine = « En cours de vérification » | V1, V2, V9 |
| **Rail desktop repliable** | Déplié : mot-symbole « Rewayah » + bouton de repli, destinations icône + libellé, **Compte épinglé en bas**. Replié : icônes seules, bouton de dépliage | Largeur dépliée : `largeurBarreLaterale` 256 (mesuré 195-230, écart accepté) ; repliée : `largeurRail` 80 (conforme V2 B) ; item 48 dp, `sm` 12, pas ≈ 56 ; actif clair : `washAccent` + icône Fill et libellé `inkAccent` ; actif sombre : `surfacePrimary` plein + icône et libellé `#25113F` (V2 C) ; inactif : icône Regular `inkMuted`, libellé `inkStrong` ; filet `contourCarte` | Replié : infobulle + `Semantics` + focus visible ; bouton de repli visuel 33 dp dans une cible de 48 ; préférence de repli mémorisée par appareil | V2, V3, V8 D3. Inactif Fill gris (V2) contre Regular (V3) : **Regular** (M3, `nav_shell.dart`). Libellé « Compte » plus bleu (V2) : artefact, même jeton |
| **Barre basse flottante arrondie** | 4 destinations, pilule flottante au-dessus de la zone sûre | Fond `surfaceRaised`, filet `contourCarte`, `md` 16, `niveau1`, marges 12-16, hauteur 64 + zone sûre ; icône 24 ; actif : icône Fill `inkAccent`, libellé `labelMedium` 600 `inkAccent`, **soulignement 3 dp** `inkAccent` arrondi ; inactif : icône Regular `inkMuted`, libellé `inkMuted` | Libellés ≥ 4,5:1 (V1 : 2,24:1 et 2,66:1) ; le contenu ne passe jamais sous la barre | V3 (4 destinations, indicateur) retenu ; V1 (stade, 3 onglets, aucun indicateur) corrigé ; gris neutres V8 / V9 rejetés |
| **Bascule clair / sombre** | Contrôle segmenté soleil / lune dans l'en-tête, à gauche de la cloche | Conteneur `surfaceRaised` + filet, pilule ; segment actif clair `washAccent` + icône `inkAccent` ; sombre `surfacePrimary` + icône `#25113F` | Cibles 48 (mesuré 31) ; pilote **la même préférence** que Compte > Préférences > Apparence (Système / Clair / Sombre, V4 écran 02) ; affichée à partir de la tablette (V2 A, B, C), absente sur mobile (V1) et sur le Compte desktop (V3) | V2. Absence du mode « Système » : à trancher (proposition : la bascule reflète le thème effectif, « Système » reste dans Apparence) |
| **Cloche à pastille** | Cloche en trait à droite de l'en-tête, point accent en haut à droite | Icône 24 `inkStrong` (mobile) / `inkMuted` (desktop) ; point 8-10 dp `surfacePrimary` cerclé du fond | Point uniquement pour de vrais non-lus ; `Semantics` « Notifications, n non lues » ; cible 48 ; route `/tuteur/notifications` | V1, V2, V8 D2 |

Autres composants récurrents, utiles aux dérivations du §2 :

| Composant | Référence | Spécification courte |
|---|---|---|
| En-tête secondaire à disque retour | V4 01-02, V8 M1-M2 | Disque 48 dp `surfaceOverlay`, flèche `inkAccent`, titre `headlineSmall` + sous-titre `bodyLarge` `inkMuted` |
| Ligne de rubrique (réglage) | V3, V4, V9 Profil | Icône 20-24 `inkAccent`, libellé `bodyLarge` + valeur ou légende `inkMuted`, chevron ; groupe à filets en retrait. Hub Réglages : **un seul groupe à filets**, pas quatre cartes (V4) |
| Médaillon de section | V3 | Cercle 40-48 dp `washAccent`, anneau 1 dp, icône Fill `inkAccent` |
| Carte de choix (admission) | V5, V6 | Surface `surfaceRaised`, filet ; sélection : bordure 2 dp `inkAccent` (sombre : `#C8B0FD`) + `washAccent` + radio pleine ; radio 24 dp, anneau non sélectionné ≥ 3:1 |
| En-tête d'étape | V5, V6 | Retour rond 48, barre continue 8 dp (piste `surfaceSunken`, remplissage `surfacePrimary`), « n sur N » calculé |
| Écran résultat | V8 M5 | Cercle héros 88-96 dp `washAccent`, titre 22 DM Sans, sous-titre, encart `washAccent`, CTA dominant, lien |
| Segment « Séances / Observations » et chips de filtre | V8 D2 | Piste `surfaceSunken`, segment actif `washAccent` renforcé, pilule, hauteur 48 ; chips pilule à icône accent et chevron |
| Ligne d'historique | V8 D2, D4 | Date (600) et méta, filet vertical, classe et élève, pastille de statut, chevron ; fuseau explicite |
| Barre de commandes de l'observation | V8 M3, M4, D1 | **Un style par format** : mobile = 3 commandes en ligne (Son reçu, Agrandir, Quitter en pilule rouge douce) ; desktop = barre pleine largeur de D1 ; même icône « Quitter » (flèche de sortie) partout |

---

## 4. Shell : mobile contre desktop

### 4.1 Ce que montre chaque maquette

| Maquette | Format | Chrome | Destinations montrées | Actif | Indicateur |
|---|---|---|---|---|---|
| #4 Accueil mobile clair (V1) | Mobile | Barre basse flottante en stade | **3** : Accueil, Foyer, Compte | Accueil | Couleur seule (icône Fill + libellé lavande), aucun fond ni trait |
| #1 Accueil desktop clair (V2 A) | Desktop | Rail déplié + en-tête (titre, bascule de thème, cloche) | **4** : Accueil, Foyer, Historique, Compte épinglé en bas | Accueil | Pilule `#F1EDFE` |
| #2 Accueil tablette sombre (V2 B) | Tablette | Rail replié (80 dp) + en-tête | **4** (icônes seules) | Accueil | Tuile pleine accent |
| #3 Accueil desktop sombre (V2 C) | Desktop | Rail déplié + en-tête | **4**, Compte en bas | Accueil | Pilule pleine accent |
| #5 Compte desktop clair (V3) | Desktop | Rail déplié à logo, pas d'en-tête global (engrenage dans la page) | **4** dans l'ordre, Compte en 4e position de la pile | Compte | Pilule `#F2EBFE` |
| #6, #7 Compte mobile clair et sombre (V3) | Mobile | Barre basse flottante | **4** : Accueil, Foyer, Historique, Compte | Compte | Icône Fill + libellé + soulignement |
| #8, #9 Réglages, Apparence (V4) | Mobile | Aucun : écran secondaire poussé, disque retour | 0 | - | - |
| #10 à #17 Admission (V5, V6) | Mobile | Aucun : parcours plein écran | 0 | - | - |
| #18 Classe M1 (V8) | Mobile | Barre basse | **4** | Accueil | Icône Fill violette |
| #19 à #23 Observation M2-M6 (V8) | Mobile | Aucun | 0 | - | - |
| #24 D1 observation desktop (V8) | Desktop | Aucun (panneau de planche) | 0 | - | - |
| #25 D2 Historique mobile sombre (V8) | Mobile | Barre basse **grise `#4B4B4B`** | **4** | Historique | Icône Fill |
| #26 D3 admin (V8) | Desktop | Barre latérale admin (Vue d'ensemble, Personnes, Classes, Historique) | hors tuteur | - | - |
| #29 ancienne Accueil (V9) | Mobile | Barre grise `#5D5D5D` | **3** | Accueil | Couleur |
| #30 à #33 anciennes captures (V9) | Mobile | Barre grise | **4** | Foyer, Historique, Foyer, **Compte (faux, c'est la fiche élève)** | Couleur + taille |

Bilan : **seule la maquette mobile de l'Accueil (et son ancienne capture) montre 3 destinations.** Toutes les autres maquettes à navigation (V2 A/B/C, V3 ×3, V8 M1 et D2, V9 ×4) en montrent 4 dans l'ordre Accueil · Foyer · Historique · Compte. Le mandat §4 le prescrit et interdit une navigation variable. Le BRIEF (« maquette mobile high-fi montre 3 onglets ») doit préciser qu'il s'agit de la seule maquette Accueil.

Existant : le tuteur a aujourd'hui 4 destinations **Accueil · Disponibilités · Réglages · Suivi** (`nav_shell.dart:79-99`) ; les seuils du shell sont déjà ceux des maquettes : barre basse sous 600, rail replié de 600 à 1199, barre latérale à partir de 1200 (`app_gabarit.dart:60-66`, `:113`, `:121`).

### 4.2 Recommandation (conforme au mandat)

1. **4 destinations partout, même ordre : Accueil · Foyer · Historique · Compte.** Remplacer la liste tuteur de `nav_shell.dart:79-99`. Les anciennes destinations restent atteignables : Disponibilités (si la politique existe) depuis le Foyer, les réglages par enfant depuis la fiche élève, le Suivi dans Historique.
2. **Mobile (< 600)** : barre basse flottante arrondie du §3.4 (style V3 : 4 destinations, soulignement actif, `md` 16), en-tête de page avec titre à gauche et **cloche** à droite ; pas de bascule de thème (elle est dans Apparence).
3. **Tablette (600-1199)** : rail replié 80 dp (V2 B), icônes seules avec infobulles, bouton de dépliage ; en-tête : titre, bascule de thème, cloche.
4. **Desktop (≥ 1200)** : rail déplié (V2 A, C) avec mot-symbole, bouton de repli, Compte épinglé en bas ; en-tête : titre, bascule de thème, cloche. La bascule manuelle repli / dépli est une préférence d'appareil. Le cadre arrondi sur fond lavande de V2 n'est pas reproduit.
5. **Pages de niveau 2** (Classe, fiche élève, détail de séance) : le shell reste visible avec la destination parente active (V8 M1 : Accueil actif sur la Classe). **Tâches focalisées** (admission, ajout de profil, salle d'observation et explication, scanner, émetteur QR, sous-pages de préférences) : sans barre basse sur mobile, disque retour 48 dp (V4, V8 M2-M5). Sur tablette et desktop, le rail reste visible sauf dans la salle d'observation et l'admission.

### 4.3 Réponse sur la 4e destination (« Historique, ou autre chose de plus important ? »)

Candidats examinés, avec leur meilleur emplacement :

| Candidat | Pourquoi pas en onglet | Où il vit |
|---|---|---|
| Classe(s) | Une classe dépend du profil sélectionné ; l'Accueil y mène déjà par le CTA dominant « Voir la classe » | Accueil → Classe ; Foyer → fiche élève → Classe |
| Notifications | Mandat : transversal, pas une destination | Cloche de l'en-tête sur tous les formats |
| Appareils | Sous-fonction du Foyer (§4) | Foyer → Appareils du foyer ; bandeau de blocage de l'Accueil |
| Observation | Se déclenche dans la Classe, selon autorisation | Classe → Observer la séance |
| Progression, travail | Rattachés à une classe et à un élève | Classe → Travail, Progression |

**Historique reste le bon choix** : c'est la seule fonction transversale à tous les élèves et à toutes les classes, le complément observation §8 la rend **obligatoire** avec la bascule « Séances / Observations » (tuteur et administration), le mandat §4 la nomme explicitement, et 8 des 9 écrans high-fi dotés d'une navigation l'affichent déjà (seul #4 l'omet). Aucun candidat ne justifie de la remplacer.

---

## 5. Registre consolidé des erreurs de maquette à ne pas reproduire

Règle générale (mandat §2) : reproduire le langage visuel, jamais les erreurs métier. Source entre parenthèses.

### A. Vocabulaire et libellés

| # | Maquette | Correction |
|---|---|---|
| A1 | « Session dans 13 min », « Session 18:00 », « Observer la session » (V1, V2, V8 D2, V9) | « Cours dans 13 min », « Séance à 18:00 », « Observer la séance » ; clés existantes `tc.groupe.temps.dansMinutes` / `dansHeures` (`fr.i18n.json:1690-1691`) |
| A2 | « Ajouter enfant », « Ajouter un enfant », « Enfants », « Gérer tous les enfants », « Paramètres de l'enfant », « Classe de l'enfant » (V1, V2, V7, V8, V9) | « Ajouter un profil élève » (même flux `/tuteur/foyer/ajouter` partout), « profils élèves », « Réglages de {prénom} » ; ne pas réutiliser `fr.i18n.json:224` et `:1159` |
| A3 | « Avant / Après la séance » (V1, V2, V8 M1, V9) | « Avant le prochain cours » (§5), clé `avantProchainCours` (`fr.i18n.json:1723`) |
| A4 | « Cours en cours » : absent des images, mais présent dans `tc.groupe.temps.enCours` (`fr.i18n.json:1700`) | Interdit (complément §2). Contradiction à arbitrer : le mandat §5 écrit « Cours toujours en cours » pour une séance prolongée ; proposition : « Séance toujours en direct » ou « En direct », sans compteur négatif |
| A5 | « Sayda », « Ustadh », « Aîcha », « Accés », « Configure un appareil », « quii », « per sonne » (V5, V8, V9) | Sayyid / Sayyida, orthographe corrigée ; ne pas recopier les artefacts |
| A6 | « Sécurité et connexion » (V3), « Réglages » contre « Préférences » (V4) | « Connexion et sécurité » ; un seul libellé pour `.../preferences`, sans collision avec `/tuteur/reglages` (réglages par enfant) |
| A7 | « Quel type de compte souhaitez-vous créer ? », « Pour qui créez-vous ce compte ? », « Moi et les membres de ma famille », descriptions promettant « les paiements » (V5, V6) | Titre « Pour qui souhaitez-vous utiliser Rewayah ? », options « Moi uniquement » / « Moi et ma famille » avec les descriptions exactes du §6 ; lien discret vers l'inscription enseignant |
| A8 | « Détails et connexion » (V2) | « Détails de la séance » |
| A9 | « Deux minutes écoulées » (V7), « 2 visites de 2 minutes » (V8 M2), « Temps restant » ambigu (V8 M1) | Libellés calculés depuis la politique effective (`fin.quotaAtteint`) ; distinguer durée de séance et chronomètre de visite |
| A10 | « Dernière séance 1 h » (V1, V2, V8, V9), « Absente » pour un prénom masculin (V1, V2, V9) | Libellé explicite dérivé des données ; accord correct ; « En cours de vérification » si la présence est incertaine |
| A11 | Genre sans raison, « Sélectionnez une option. » (V5, V6) | Garder la raison existante `inscription.genreRaison` (`fr.i18n.json:171`) en sous-titre |
| A12 | Apostrophes droites et typographiques mélangées (V3, V4, V8) | U+2019 partout ; espace fine insécable avant « ? » |
| A13 | Textes du consentement (V8 M6) et de l'explication (V8 M2) différents du mandat | Texte exact du complément §6, variantes responsable légal et élève adulte |

### B. Données illustratives qui ne deviennent jamais des constantes

Prénoms (Mariam, Yusuf, Aïcha, Adam, Salam, Fatimah, Fatoumata Diallo), « Classe An-Nour », « Sayyida Amina », « Règles de lecture • Niveau 1 », « 13:45 », « 1 h 30 », « 13 min », « pages 24 à 26 », « Hifz », « Paris », « Heure de Paris », « Europe/Paris », « Asia/Riyadh », décalage fixe Paris / Abidjan, « 30 octobre 2026 », « 4 membres liés », « 2 appareils », « 1/2 appareils », « 2 visites · 2 min », « 01:42 », « 3 min 42 s », « n sur 5 », « n sur 6 », « 28 ans », téléphone et courriel d'exemple (V1 à V9). Dates incohérentes : lundi 21 et jeudi 18 septembre ne coexistent dans aucune année ; l'Historique ancien affiche des jours faux et l'année 2024 (V1, V9). Tout vient des services, de la locale fr et du fuseau IANA.

### C. États et logique métier

| # | Maquette | Correction |
|---|---|---|
| C1 | Mariam « En séance » dans le sélecteur et « dans 13 min » dans la carte (V1, V9) | Un seul état temporel, même source pour le sélecteur et la carte |
| C2 | « Salle ouverte » à T-13 figé (V1, V2) | Fenêtre de la politique (généralement T-20), clés `salleOuverte` (`fr.i18n.json:1693-1694`) |
| C3 | Deux blocages simultanés : lien « fournir une photo » + bandeau appareil (V1, V9) | Un seul blocage prioritaire, confirmé par les données |
| C4 | Initiale de l'élève à la place de la photo de l'enseignant (V1, V2, V9) | Photo publique de l'enseignant + titre ; portrait élève distinct |
| C5 | « Réseau élève / enseignant : Bon » (V1, V9), réseau au premier plan de l'Historique (V9) | Masqué par défaut, affiché seulement si mesuré ; jamais le réseau de l'enseignant sans décision explicite |
| C6 | Observation proposée à T-13 avant le début, sans quota (V9 Classe) | Disponible seulement enfant présent et séance en cours ; visites et durée affichées avant l'entrée |
| C7 | Décision « Observation disponible ? » binaire (V7) | Troisième issue « présence en vérification » ; jamais d'absence déduite d'une déconnexion ou d'une caméra coupée |
| C8 | Reconnexion qui revient au direct, échec qui revient à « Observer » (V7) | Pas de faux direct ; compteur relu auprès du serveur, jamais remis à zéro ni décrémenté localement |
| C9 | Chronomètre « 01:42 » ambigu (V8), compteur pendant l'explication (V7) | Trancher décompte ou écoulé ; démarrage seulement à l'entrée confirmée |
| C10 | Accès direct à la salle (V7) | `.../observer` repasse toujours par « Connexion et vérification » |
| C11 | Présélections sur toutes les étapes de l'admission (V5, V6) | État initial vide, CTA désactivé ou erreur sous le groupe |
| C12 | Pas de carte « Autre » alors que `ChoiceCardGroup` en ajoute toujours une (ADR-013, `choice_card_group.dart:46-52`) (V5, V6) | Contradiction à trancher explicitement |
| C13 | Âge exact « 28 » (V6) contre tranches serveur existantes | Contradiction à consigner, pas à trancher dans l'UI |
| C14 | Langue de l'application demandée dans l'admission (V6 E4) | Ne remplace pas la langue du cours ; seules les langues d'interface réellement traduites (un seul fichier `fr`) |
| C15 | « Vos préférences sont prêtes. » (V6), « Appliqué sur cet appareil. » avec des préférences en mémoire (V4) | Pas de faux succès ; formulation honnête ou persistance décidée par le coordinateur |
| C16 | CTA dominant « Gérer les paiements », « Moyen de paiement », doublons vers `.../paiements` (V3) | Indisponible proprement sans service ; une seule entrée ; le paiement n'est pas le CTA dominant du compte |
| C17 | « Compte vérifié » (V3) | Seulement si un statut serveur existe |
| C18 | « Appareils connectés · 2 appareils », « disponibilités » (V3, V9) | Sessions du titulaire nommées comme telles, ou lien vers les appareils du foyer ; pas de disponibilités sans politique |
| C19 | Rubriques absentes du Compte : Préférences (engrenage muet), Informations légales, « Créer mon profil élève » (V3) | À ajouter en lignes sobres |
| C20 | « Taille du texte » avec chevron sans destination (V4) | Sous-écran dérivé ou ligne informative ; respect de `TextScaler` |
| C21 | Compteurs décoratifs « 3 enfants / 1 appareil / 2 alertes », « Diagnostic à terminer », « iPhone de Mariam » comme appareil familial (V9) | Supprimés ou remplacés par une action réelle |
| C22 | Bascule « Séances / Observations » absente de l'ancien Historique (V9) ; filtre « Statut » sans colonne (V8 D3) | Bascule obligatoire ; filtres cohérents avec les colonnes |
| C23 | Contenu arabe faux : ث et ت confondus, kasra manquante sous ب, ordre de voyelles variable (V8) | Le support est un document partagé vérifié, jamais un décor |
| C24 | Barre de progression à 54 % pour 3/5 (V5) | Valeur calculée |

### D. Navigation et shell

- Barre à 3 onglets (V1, V9 Accueil) : 4 destinations partout (§4).
- Onglet actif « Compte » sur la fiche élève `Profil.png` (V9) : Foyer.
- Barres basses sombres en gris neutre `#4B4B4B` (V8 D2) et `#5D5D5D` (V9) : surface de la palette.
- Cadre arrondi du shell posé sur fond lavande (V2) : mise en scène.
- Bascule de thème sans mode Système, déconnectée d'Apparence (V2) : même préférence.
- Barre latérale admin « Vue d'ensemble / Personnes / Classes / Historique » (V8 D3) : navigation admin existante, pas une spec.

### E. Accessibilité

- **Cibles sous 48 dp** : CTA « Observer la séance » ≈ 40 (V8 M1), « Retour à l'historique » ≈ 29 (V8 D4), lignes de tâches 39-41 (V1, V2), lignes de liste 44 (V8), bouton de repli du rail 33 (V2), segments de thème 31 (V2), « Modifier » 37-39, engrenage 39-41, CTA doux 42 desktop, bande « Se déconnecter » 33 (V3), case de consentement (V8).
- **Contrastes sous AA** : onglets inactifs `#ABABAE` 2,24:1 et libellé actif `#AF89F5` 2,66:1 (V1) ; « En séance » sarcelle 3,3:1 (V1) ; corps du bandeau `#7E7C7A` 3,87:1 (V1) ; légendes `#7F8399` 3,7:1, texte vert `#0B9442` 3,6:1, « Se déconnecter » 3,8-4,1:1 (V3) ; piste d'interrupteur désactivé `#48475D` 1,77:1 (V4) ; anneau de radio non sélectionné `#535369` 2,17:1 (V6) et `#636582` 3,0:1 (V5) ; « Faible » `#FF5757` 4,38:1 (V9).
- Statuts codés par la seule couleur (points du sélecteur, rubans colorés de V9) : libellé et étiquette sémantique.
- Rail replié sans libellés (V2) : infobulle, `Semantics`, focus.
- Légende rétrécie pour tenir sur une ligne (V4) : retour à la ligne à texte agrandi.
- Grilles à deux colonnes (genre V5, V6) : repli en pile à 200 % (`AppGabarit.choixEnColonnes`).

### F. Incohérences de jetons entre maquettes (à normaliser, jamais à copier)

Deux accents clairs (V1 pâle contre V2, V3, V8 saturé) ; trois fonds clairs (froid V1, chaud V3, quasi blanc V2) ; six fonds sombres ; deux verts pour « en direct » (point `#22CA6B` contre texte sarcelle `#139694`) et deux fonds verts sur un même écran (V1) ; filet vertical plus foncé que les autres séparateurs (V1, V2) ; marges de 8 et 16 dp sur deux écrans de la même planche (V4) ; espacements irréguliers et lignes d'« Aide et support » indentées (V3 desktop) ; pastilles d'icône de 46 à 67 dp (V6) ; trois teintes de pastille d'icône sélectionnée (V5, V6) ; hiérarchie de lignes incohérente (V4) ; trois styles de barre de commandes et deux icônes « Quitter » (V8) ; deux couleurs de libellé de CTA doux (V8) ; repli silhouette contre initiale (V1, V2) ; « + » plein contre pointillé et colonne droite en carte contre trait vertical (V2 clair contre sombre : **un seul arbre de widgets, seul le format change la composition, jamais le thème**) ; CTA rectangle dans l'app contre pilule dans l'admission (V5, V6 contre V1, V2, V3, V8) ; typographie mêlant trois familles (V9).

### G. Artefacts et chrome à ne pas dessiner

Barre d'état iOS et indicateur d'accueil (tous les mobiles) ; étiquettes de planche (« TABLETTE », « DESKTOP / WEB », « 01 / Compte », « 1 OBSERVATION EN DIRECT · ORDINATEUR », légendes « 01 Réglages », flèche de flux) ; texte fantôme derrière le libellé du CTA (V9) ; halo de netteté et liseré noir autour des glyphes (V2, V5) ; rubans colorés derrière les avatars (V9) ; styles du logigramme : crème `#FFF6D9`, brun `#6E5400`, Segoe UI, nœuds de 120 px, pointillés (V7).

### H. Fichiers au nom trompeur (le nom ne détermine ni l'écran ni la route)

- `mobile/mon compte tuteur desktop dark mode.png` = Mon compte **mobile** sombre (V3).
- `mobile/tuteur observation mobile light.png` contient un écran **sombre** (M3) (V8).
- `tuteur observation desktop light.png` contient deux écrans **mobiles**, dont un sombre (D2, D4) et un écran admin (D3) (V8).
- `onboarding Mble d.png` : « d » n'est pas « dark », c'est l'étape genre (V5).
- `mobile/Profil.png` = fiche élève, pas le compte (V9, mandat §2).
- `acceuil …` (coquille du nom de fichier) ; `mobile/accueil  tuteur …` avec deux espaces.

---

## 6. Dérivations nécessaires

### 6.1 Couverture thème × format des high-fi

| Écran | Clair | Sombre | À dériver |
|---|---|---|---|
| Accueil | mobile #4, desktop #1 | tablette #2, desktop #3 | **mobile sombre**, tablette claire |
| Mon compte | desktop #5, mobile #6 | mobile #7 | **desktop sombre**, tablette |
| Réglages, Apparence | - | mobile #8, #9 | **clair**, desktop et tablette (colonne `largeurReglages` 760) |
| Admission (usage, genre, âge, langue, objectif, récapitulatif) | consentement M6 seulement | mobile #10 à #17 | **clair**, desktop et tablette (colonne centrée 480-560 dp, CTA en bas de colonne) |
| Classe + entrée d'observation | mobile M1 | - | sombre ; desktop et tablette (2 colonnes de #1) |
| Explication, fin de visite, consentement | mobile M2, M5, M6 | - | sombre ; desktop (colonne centrée ou dialogue, pas de feuille étirée) |
| Salle d'observation | mobile M4, desktop D1 | mobile M3 | desktop sombre, paysage, tablette |
| Historique (Observations) | - | mobile D2 | **clair**, desktop ; segment Séances |
| Détail d'observation | mobile D4 | - | sombre, desktop |
| Tous les écrans du §2 | - | - | les deux thèmes |

### 6.2 Règles de dérivation clair ↔ sombre, tirées des paires observées

Paires de référence : Accueil clair #1 ↔ sombre #3 (V2), Compte clair #6 ↔ sombre #7 (V3, géométrie identique au pixel près), salle M4 ↔ M3 (V8), miniatures « Clair » / « Sombre » de l'écran Apparence #9 (V4). Ces paires montrent que la dérivation **n'est pas une inversion** : les surfaces ne s'inversent pas, l'accent garde sa teinte et change de rôle, les conteneurs sémantiques gardent leur teinte et s'assombrissent.

| Rôle | Clair | Sombre | Règle |
|---|---|---|---|
| Fond | `#F8F7FA` | `#1A1A25` | Ardoise bleu-violet, jamais noir pur ni gris neutre |
| Carte | blanc + filet 8 % d'encre | `#22222E` + filet 8 % de blanc | L'élévation se lit par la clarté (carte plus claire que le fond), pas par l'ombre |
| Carte mise en avant | `#F7F5FE` | `#2B2B39` | Même écart relatif au fond |
| CTA dominant | **lavande doux** `#DCCAFD`, libellé quasi noir | **lavande plein** `#BA98FB`, libellé `#25113F` | Le CTA devient **plus saturé** en sombre ; le libellé reste sombre |
| Navigation active | pilule `washAccent` pâle + icône et libellé violet saturé | pilule pleine `#BA98FB` + icône et libellé sombres (rail) ; soulignement lavande (barre basse) | Même composant, rôle d'accent échangé |
| Accent texte, lien | violet saturé `#6538E4` | lavande `#C9AEFF` | Teinte conservée, clarté déplacée vers le contraste |
| Pastille de statut | fond pâle + texte foncé du rôle | fond sombre désaturé du rôle (`#214A42`, `#58293B`) + texte clair (menthe `#9DDEB5`, rose clair) | La teinte sémantique survit, l'intensité s'inverse |
| Points de statut | intensité moyenne | néon plus clair (`#70EE9C`, `#F9505E`) | Toujours doublés d'un libellé ; viser 3:1 dès qu'un point reste le seul indice visuel (les points clairs mesurés sont à 2,3-2,4:1) |
| Danger en texte | `#C21D3D` | `#F4777D` | Éclairci, jamais le même rouge |
| Monogramme | `#E8E0FD` + lettre violette | `#534D71` + lettre lavande | Fond violet nuit, lettre claire |
| Médaillon | `#F7F1FE` + anneau `#9974EF` | `#2C2842` + anneau `#B697F4` | Idem |
| Avertissement | fond crème `#FEF5E4`, icône `#D18B07` | fond `#44361A`, icône `#FFBC33` | Icône plus claire, fond brun désaturé discret (pas le brun opaque des anciennes captures) |
| Sélection (admission) | surface `washAccent` + bordure 2 dp `inkAccent` + radio pleine violette | surface `#292438` + bordure 2 dp `#C8B0FD` + radio `#BA98FB` | Trois signaux dans les deux thèmes ; halo facultatif, plus faible en clair |
| Progression | piste `surfaceSunken`, remplissage `surfacePrimary` | piste `#3D3B4F`, remplissage `#BA98FB` | - |
| Contenu non chrome (support pédagogique, QR, photos, surface Coran) | inchangé | **inchangé** (le support reste blanc dans la salle sombre M3) | On ne dérive pas un document ni un QR ; le QR reste noir sur blanc pour le scan |

Contrôles après dérivation : texte ≥ 4,5:1, composants et indicateurs d'état ≥ 3:1 (corriger l'interrupteur désactivé et l'anneau de radio sombres, E), mêmes positions et même arbre de widgets dans les deux thèmes, capture comparative clair et sombre à viewport identique.

### 6.3 Dérivations par écran et par état

| Cas | Dérivation |
|---|---|
| Accueil mobile sombre | Composition de #4 à l'identique, couleurs de #3 : carte `#22222E`, zone imbriquée `surfaceSunken` sombre, CTA plein `#BA98FB`, pastille « Salle ouverte » sombre, barre basse `surfaceRaised` sombre |
| Mon compte desktop sombre | Composition de #5, couleurs de #7 (règles de V3 §3.2) : médaillons violet nuit, CTA plein lavande, pastilles vert sombre à texte menthe, rouge éclairci ; rail sombre de #3 |
| Réglages et Apparence clairs | Composition de #8 et #9, couleurs de #6 ; hub en un seul groupe à filets ; miniatures « Clair » de #9 (fond `#FBF8FF`, pastilles `#C3A4FD`) comme indice de rendu |
| Admission claire | Gabarit d'étape V6 : fond `#F8F7FA`, cartes blanches à filet, sélection `washAccent` + bordure `inkAccent` 2 dp, CTA doux `#DCCAFD` (même CTA que l'app), piste de progression `surfaceSunken` ; le consentement M6 donne déjà la version claire des cases et du CTA désactivé (`#E2DCFB`, texte `#8C80D2` à relever vers 4,5:1) |
| Admission desktop et tablette | Même gabarit dans une colonne centrée de 480-560 dp, CTA en bas de colonne, aucun écran mobile étiré |
| Historique clair et desktop | Composition de D2 (#25) en couleurs de #6 ; desktop : sélecteur aligné à gauche, liste pleine largeur limitée à `largeurLecture`, rail de #1 |
| Classe desktop | Deux colonnes de #1 : carte séance à gauche (enseignant avec photo, prochaine séance, « Observer la séance », visites disponibles, « Comment ça marche ? »), lignes à droite |
| États de la planche 3 manquante (observation) | Indisponibilités (enfant absent, visites épuisées, non commencée, terminée, désactivée, présence en vérification) : ligne d'état textuelle dans le bloc Observation de M1, CTA retiré ou désactivé avec motif. Connexion prolongée, échec : écran M5 ou M2 en variante « attente » puis « erreur » avec « Réessayer ». Reconnexion, caméra désactivée, aucun support, support indisponible : surimpression discrète dans la salle M3 / M4, sans faux direct. Fins (sortie volontaire, durée atteinte, fin de séance, interruption) : variantes du résultat M5. Notices enseignant et enfant (« Votre maman… » si le lien est connu, sinon « Votre parent… ») : bandeau discret dans les salles existantes, conçu par l'agent Cours à partir du bandeau d'information |
| États système §8 | Chargement : squelette de la carte en place (mêmes dimensions, `surfaceSunken`). Erreur de bloc : la carte garde son cadre avec titre humain et « Réessayer ». Erreur globale, 404, accès refusé, session expirée, hors ligne : écran résultat M5 (cercle héros, titre, phrase, action, lien). Vide : même écran résultat avec l'action d'inscription ou d'ajout de profil, jamais une fausse classe |
| Séance en direct, prolongée, annulée, reportée, DST | Même bloc séance : pastille changée (« En direct », « Séance toujours en direct », « Annulée », « Reportée ») avec le groupe de points ; clés `dst.*` existantes (`fr.i18n.json:1712-1716`) |

### 6.4 Décisions à remonter au coordinateur (ne pas trancher en silence)

1. Passage de la palette sombre du quasi-noir chaud à l'ardoise bleu-violet (§3.1) : impact sur tous les rôles.
2. Ajouts de paires `surfaceMiseEnAvant`, `surfaceActionDouce` et du groupe de points de statut.
3. Rayon des boutons : `arrondiMd` (thème actuel) contre `sm` 12 (maquettes et documentation de `AppRadius`).
4. CTA en pilule pour le seul gabarit d'admission, ou forme unique.
5. Familles DM Sans et Plus Jakarta Sans à intégrer (absentes du dépôt, mandat inexact).
6. Bascule de thème de l'en-tête sans mode « Système ».
7. Libellé de séance prolongée (« Cours toujours en cours » du §5 contre l'interdiction « Cours en cours »).
8. Carte « Autre » d'ADR-013, âge exact contre tranches, barre continue contre segmentée (V5, V6).
9. Route du détail d'observation (D4).
10. Planche 3 de l'observation à obtenir du directeur.
