# GABARITS — Catalogue de gabarits du rôle Tuteur et méthode « mapping sans maquette »

Date : 25/09/2026. Rédacteur : agent de mesure (poste B, lecture du dépôt `ui/tuteur-v1` @ `a855b23`, aucun fichier du dépôt modifié). Objectif : répondre à la question du directeur — les références actuelles (captures + composants + jetons) suffisent-elles à produire les visuels d'un rôle à partir d'un mapping (états, écrans, contenu), sans dessiner une maquette par écran ?

Sources : `lib/features/**` (rôle tuteur), `lib/core/router/routes.dart` et `app_router.dart`, `lib/core/widgets/**`, `lib/core/mouvement/**`, `lib/core/theme/**`, `01_visuel/00_MANIFESTE.md` (§1 inventaire des 33 références, §2 dérivation sans maquette, §3.4 composants), `05_recette/T/TRI.md` et le diff `origin/ui/tuteur-v1...origin/ui/tuteur-v1-t`.

---

## 1. Catalogue de gabarits

9 gabarits couvrent la totalité des 30 écrans du rôle Tuteur recensés dans le routeur (`app_router.dart`, branches `tuteurAccueil` / `tuteurFoyer` / `tuteurSuivi` / `tuteurCompte`).

### G1 — Accueil / tableau de bord
- **Composants partagés** : `SelecteurProfils` (`selecteur_profils.dart`), carte séance/classe (`carte_seance_classe.dart` + `AppCard`), `BandeauObservation`, liste de tâches à cercles (interne à la page, cercles + `contourCarte`), ligne « Dernière séance » (`ligne_cle_valeur.dart` / `lien_fleche.dart`), `BasculeTheme`, cloche à pastille (`entete_page.dart`).
- **Référence** : `/tuteur` — `lib/features/accueil_famille/accueil_famille_page.dart` — capture manifeste #4 `mobile\accueil tuteur mobile light mode.png` (existante, non encore recapturée en 390x844 réel).
- **Mise en page** : mobile = colonne unique, sélecteur en défilement horizontal ; bureau = rail déplié + 2 colonnes (carte séance à gauche, listes à droite).
- **États obligatoires** : chargement (squelette de carte), vide (aucun enfant → CTA « Ajouter un profil »), erreur (bandeau), indisponible (blocage appareil ambre), hors ligne (`OfflineBanner`).

### G2 — Liste (rubriques ou entrées homogènes)
- **Écrans** : Foyer, Notifications, Suivi/Historique (séances + observations), Paiements, Appareils, Catalogue de classes.
- **Composants partagés** : `GroupeReglages` / `SettingRow` (lignes de rubrique), `StatusPill`, `FilterPill` / `MenuFiltre`, `LignePresence`, `TimelineRow`, `LienFleche`.
- **Référence** : `/tuteur/foyer` — `lib/features/foyer/foyer_page.dart` — capture manifeste #30 `mobile\Foyer Member.png` (contenu seul, rendu à refaire sur les lignes actuelles).
- **Mise en page** : mobile = liste pleine largeur à filets en retrait ; bureau = même liste dans une colonne centrée ou à côté d'un panneau de détail (Historique, Paiements).
- **États obligatoires** : chargement (squelette de lignes), vide (`EmptyState`), erreur (`EtatSysteme`), indisponible (port neutre, ex. observations 🔌), hors ligne.

### G3 — Fiche / détail
- **Écrans** : Fiche élève, Classe (tuteur), Détail de séance, Détail d'observation.
- **Composants partagés** : en-tête d'identité (photo/initiale + titre + sous-titre), `GroupeReglages`/`SettingRow` en rangées légende-valeur, `LigneCleValeur`, `SectionHeader`.
- **Référence** : `/tuteur/classes/:classeId` — `lib/features/classe_tuteur/classe_tuteur_page.dart` — capture manifeste #18 `mobile\tuteur observation mobile light.png` (M1).
- **Mise en page** : mobile = en-tête puis sections empilées ; bureau = 2 colonnes (carte d'identité/séance à gauche, rangées à droite).
- **États obligatoires** : chargement, indisponible par section (ex. réseau masqué), erreur de bloc, hors ligne.

### G4 — Formulaire par étapes
- **Écrans** : Ajouter un profil élève, Informations de l'élève, Inscription/parcours, tous les écrans d'admission (`inscription/etapes`, `parcours_offres`).
- **Composants partagés** : `PageEtape` (en-tête retour 48 dp + barre de progression), champs à étiquette flottante, `ChoiceCardGroup`, `ConfirmDestructive` pour l'abandon.
- **Référence** : `/tuteur/foyer/ajouter` — `lib/features/appareils/ajouter_enfant_page.dart` / `lib/features/foyer/formulaire_profil_eleve.dart` — capture manifeste #12-14 (planche flux onboarding mobile 1).
- **Mise en page** : plein écran sans shell, colonne centrée bornée en largeur sur bureau.
- **États obligatoires** : validation de champ (erreur sous champ), soumission en cours, échec de soumission.

### G5 — Questionnaire à choix
- **Écrans** : sous-étapes d'onboarding à cartes (usage, genre, objectif, choix de classe/catalogue).
- **Composants partagés** : `ChoiceCardGroup`, `PageEtape`.
- **Référence** : `/tuteur/classes/catalogue` — `lib/features/classe_tuteur/catalogue_classes_page.dart` — capture manifeste #12/#16 (planches E1/E5).
- **Mise en page** : grille 1 colonne mobile, 2 colonnes ou plus sur bureau.
- **États obligatoires** : aucune option disponible (vide), chargement des options, sélection requise avant CTA actif.

### G6 — Réglages / compte
- **Écrans** : Compte, Informations, Sécurité, Accès, Paiements, Préférences, Apparence, Aide, Informations légales, Interface élève, Caméra élève.
- **Composants partagés** : `GroupeReglages`/`SettingRow`, `ControleSegmente`, `BasculeTheme`, `ChoiceCardGroup` (apparence).
- **Référence** : `/tuteur/compte` — `lib/features/compte/compte_tuteur_page.dart` — capture manifeste #5 `mon compte tuteur desktop light mode.png`.
- **Mise en page** : mobile = un seul groupe à filets par section ; bureau = rail à logo + colonne de contenu, engrenage dans la page.
- **États obligatoires** : port indisponible (paiements, moyens de paiement), lecture seule honnête, hors ligne.

### G7 — Résultat / succès / échec
- **Écrans** : Bienvenue, Récupération de mot de passe, fin de visite d'observation, appairage réussi/échoué, pages transversales (404, accès refusé, session expirée).
- **Composants partagés** : `EcranResultat` (cercle héros, titre, sous-titre, encart, CTA dominant, lien secondaire).
- **Référence** : `.../observer` (fin de visite) — capture manifeste #22 `M5`.
- **Mise en page** : colonne centrée, identique mobile/bureau (largeur bornée).
- **États obligatoires** : succès, échec, attente (lien expiré).

### G8 — État vide / erreur / indisponible / hors ligne (famille transversale)
- **Composants partagés** : `EmptyState`, `EtatSysteme`, `OfflineBanner`, `BlocAsynchrone`, `Skeleton`, `PermanentNotice`.
- **Référence** : présent dans chaque écran de G1-G6 en superposition ou substitution ; capture de série existante dans `05_recette/*/captures` (états chargement/vide/erreur/hors-ligne déjà photographiés par d'autres lots, ex. lots A/B/D).
- **Règle** : ce n'est pas un écran séparé mais un état obligatoire de chaque gabarit ci-dessus — voir §5 de la procédure.

### G9 — Scanner / caméra / salle d'observation
- **Écrans** : Scanner QR, saisie de code/PIN, caméra de l'élève, salle d'observation (vidéo en direct côté tuteur).
- **Composants partagés** : `PinPad`, `PageImmersive` (plein cadre sans shell), `BandeauObservation`, barre de commandes (Son reçu / Agrandir / Quitter).
- **Référence** : `.../observer` — capture manifeste #20/#21 (M3/M4 salle) et #24 (D1 bureau).
- **Mise en page** : plein écran mobile (viseur/vidéo) ; bureau = panneau centré, jamais une feuille étirée.
- **États obligatoires** : caméra refusée, connexion en cours, reconnexion, visites épuisées, aucun support, désactivée.

---

## 2. Mesure de composition (30 écrans du rôle Tuteur)

Méthode : import de composants `lib/core/widgets` ou `lib/core/mouvement` par fichier + recherche de widgets bruts dessinés à la main (`Container(`, `BoxDecoration(`, `Card(`, `ListTile(` employés hors des composants partagés).

| Écran (fichier) | Widgets bruts (fichier:ligne) |
|---|---|
| `classe_tuteur/travail_classe_page.dart` | `BoxDecoration(` aux lignes 200 et 212 (halo local de progression, non couvert par un jeton `AppElevation`) |
| `foyer/fiche/acces_page.dart` | `BoxDecoration(` à la ligne 98 (encart de statut d'accès dessiné localement) |
| Les 28 autres écrans du routeur Tuteur (Accueil, Foyer, toutes les fiches, Compte et ses 8 sous-pages, Notifications, Suivi, Appareils, Appairage, Catalogue, Planning, Ressources, Progression, Parcours) | Aucun widget brut détecté ; composition entièrement à partir de `lib/core/widgets` / `lib/core/mouvement` |

**Résultat : 28 / 30 écrans, soit 93 % des écrans du rôle Tuteur, sont composés à 100 % de composants partagés.** Les 2 écarts sont mineurs (un `BoxDecoration` ponctuel chacun, pas une direction artistique nouvelle) — candidats à remonter en jeton `AppElevation`/`AppRadius` plutôt qu'à garder en dur.

---

## 3. Test sur le lot T (finance : soldes, recharges, remises, accès)

Lecture de `05_recette/T/TRI.md` et du diff `origin/ui/tuteur-v1...origin/ui/tuteur-v1-t` (44 fichiers, +4055/-322).

**Verdict : partiellement — la structure des écrans a pu être composée sans nouvelle maquette, mais le domaine « argent » n'existait dans aucune référence, donc le lot a dû créer 5 nouveaux composants partagés avant de composer les pages.**

- TRI.md le confirme lui-même : le manque de référence est le sujet même de la section 1 (« le gros manque »)  — aucun jeton, aucune capture des 33 références du manifeste ne montre un solde, un montant, une recharge ou un mouvement.
- Le lot n'a pas dessiné une maquette : il a **fabriqué de nouveaux composants génériques** dans `lib/core/widgets` en réutilisant les jetons existants (palette, rayons, typographie) : `resume_solde.dart` (166 lignes), `ligne_beneficiaire.dart` (68), `selection_profils.dart` (135), `resultat_par_profil.dart` (60), plus `selecteur_theme.dart` (215, hors finance, LT-1). Les nouvelles pages (`soldes_page.dart`, `mouvements_page.dart`) composent ensuite ces briques avec les gabarits G2 (Liste) et G6 (Réglages/compte) déjà catalogués ici.
- Ce qui a manqué : (1) aucun composant de type « montant/solde » ou « ligne bénéficiaire » n'existait avant le lot — le mapping n'aurait pas suffi seul, il fallait une décision de conception (forme du composant, pas seulement son contenu) ; (2) les données de démonstration financières (`finance_demo.dart`) ont dû être inventées, car aucun serveur ni maquette n'en fournit ; (3) seul LT-1 (sélecteur de thème) a des captures dans `05_recette/T/LT-1` — LT-4 à LT-12 (Foyer/Compte finance, mouvements, recharge) n'ont pas encore de planche de validation, donc le test visuel n'est pas bouclé.
- **Conclusion pour la méthode** : le mapping seul (états/écrans/contenu) suffit quand le contenu rentre dans un gabarit déjà catalogué avec ses composants ; il ne suffit pas quand le **type de contenu** est nouveau (ici : argent). Dans ce cas, il faut soit une décision de composant explicite du directeur (forme attendue), soit une maquette ponctuelle du seul composant nouveau — pas de l'écran entier.

---

## 4. Limites — écrans qui exigent encore une maquette

Aucun gabarit du §1 ne couvre, de façon factuelle (absence de référence, de composant et de capture dans le dépôt et les 33 sources du manifeste) :

- **Salle de classe en visio (multi-flux, enseignant + élèves)** : `lib/features/tc_classe_live`, `tc_espace_groupe` existent côté enseignant/salle, mais aucune capture ni jeton ne couvre une grille vidéo multi-participants ; le rôle Tuteur ne montre que la salle d'**observation** (lecture seule, G9), pas la classe elle-même.
- **Lecteur du Coran / Mushaf** : `lib/features/tc_mushaf` existe en code ; `surfaceQuran` est un jeton volontairement figé (`app_palette.dart:5-7`) mais sans capture de mise en page (ligatures arabes, pagination, annotations) — une maquette reste nécessaire pour toute page qui l'affiche.
- **Interface guidée pour enfant 5-10 ans** : `accueil_eleve`, `reglages_enfant` existent, mais aucune des 33 références visuelles ne concerne un enfant de cet âge (cibles tactiles, densité de texte, guidage) ; le manifeste ne traite que le rôle Tuteur (adulte).
- **Tableaux denses d'administration/comptabilité sur bureau** : `admin_pedagogie_*`, `admin_journal`, `admin_comptes`, etc. — aucun gabarit de liste ou de fiche catalogué ici ne couvre une grille de données dense (tri, colonnes multiples, export) ; le G2 (Liste) suppose des lignes simples, pas un tableau.
- **Page publique / landing (site vitrine)** : hors de `lib/features` (relève de systeme.io ou d'un site séparé) ; aucune référence ni jeton d'app n'y correspond.

---

## 5. Procédure « mapping du rôle → écrans sans maquette »

1. **Recevoir le mapping** du directeur au format du §6 ci-dessous (un écran par ligne).
2. **Classer chaque écran** dans un des 9 gabarits du §1. Si aucun gabarit ne convient et qu'aucun composant partagé ne peut être composé (comme en §4), s'arrêter ici pour cet écran : c'est un cas de doute (étape 8).
3. **Lister les états obligatoires** de l'écran (chargement, vide, erreur, indisponible, hors ligne + états métier propres, ex. « visites épuisées ») à partir de la colonne « États » du mapping et du gabarit choisi.
4. **Composer l'écran** uniquement avec les composants partagés du gabarit (`lib/core/widgets`, `lib/core/mouvement`) et les jetons (`lib/core/theme`) ; si un composant manque pour le **type de contenu** (pas seulement son texte), le signaler comme un nouveau composant à valider avant d'aller plus loin (voir le précédent du lot T, §3).
5. **Activer le mode démonstration** (données factices déjà en place, ex. `finance_demo.dart` comme modèle) pour peupler l'écran sans dépendre d'un service indisponible.
6. **Produire les captures réelles** : 390x844 et 1440x900, clair et sombre, nommées `<lot><tâche>_<écran>_<taille>_<thème>.png` (convention déjà en usage dans `05_recette/*/captures`).
7. **Construire une planche de validation** pour le directeur : les 4 captures d'un même écran côte à côte, légendées par le gabarit utilisé et les composants partagés consommés (traçabilité).
8. **Règle du doute** : dès qu'un écran ne rentre dans aucun gabarit, ou qu'un composant partagé manquerait pour un **type de contenu inédit**, poser une question précise au directeur (quoi, pourquoi ce gabarit ne suffit pas) et ne demander qu'**une seule** maquette ciblée sur le point de doute — jamais l'écran entier par défaut.

## 6. Format attendu du mapping (colonnes)

| Colonne | Contenu attendu |
|---|---|
| Route logique | ex. `/tuteur/compte/acces` |
| Écran (nom court) | ex. « Abonnement et accès » |
| Gabarit visé (§1) | G1 à G9, ou « aucun » si doute |
| États requis | liste parmi chargement/vide/erreur/indisponible/hors ligne + états métier |
| Contenu réel | champs, libellés, exemples de valeurs (pas de placeholder « Lorem ») |
| Composants partagés pressentis | noms de `lib/core/widgets` déjà catalogués au gabarit |
| Doute signalé | vide, ou description précise du point bloquant (déclenche l'étape 8) |

---

Commit et publication : voir historique Git de cette branche (`pilotage/tuteur-v1`).
