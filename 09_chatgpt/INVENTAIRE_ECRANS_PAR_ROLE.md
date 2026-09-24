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
13. **Publication impossible en l'état** : aucune suppression de compte, aucun document légal, aucune notification (ni push, ni e-mail applicatif), pas de lien profond mobile pour le lien de connexion, permission micro non déclarée (manifeste Android principal, `Info.plist` iOS), nom Android « rewayah_academy », traduction arabe quasi vide (32 lignes contre 2 366). [critique] S'y ajoutent : aucune acceptation des conditions à l'inscription, aucun modèle d'e-mail transactionnel ni SMTP de production dans le dépôt, aucun traitement administratif des demandes de suppression ou d'export (section 14).
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
| Transverse | [critique] Signalements des enseignants (sans code) | Aucune | Examiner un signalement, rédiger le résumé destiné à la famille, le transmettre au tuteur ou à l'élève adulte, clore | **Absent** côté administration, alors que le serveur porte le circuit complet : table `student_concern`, catégories (pédagogique, présence, technique, changement, autre), statuts `ouvert`, `en_examen`, `transmis`, `clos`, mise à jour réservée à l'admin (`supabase/migrations/0032_tc_catalogue.sql:567-619`) ; lecture famille par la vue `concern_famille_v` (`0033_tc_vues_rpc.sql:267-282`). Côté enseignant, la feuille existe mais écrit dans un double local (`lib/core/tc_parcours/port_signalement.dart:50`) | `06` Communications | Aucune |
| Transverse | [critique] Avis de fin de séance (sans code) | Aucune | Lire les retours des élèves après la séance | **Absent** : la table `session_feedback` n'est lisible que par l'admin (`0032_tc_catalogue.sql:560-561`) et aucun écran ne la lit | `01` Classe | Aucune |
| Transverse | [critique] Demandes de suppression de compte et d'export des données (sans code) | Aucune | Recevoir, exécuter ou refuser (conservation légale, `ADM-17`), tracer au journal | **Absent** (aucune occurrence dans `lib/` ni `supabase/`) ; indispensable dès que la suppression existe côté utilisateur (section 14) | Stores ; RGPD | Aucune |
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
| **Connexion** | `/connexion` : lien par courriel ou Google ; élève : `/connexion/eleve` | Web fonctionnel ; mobile natif : le retour du lien tombe sur le site web | `DEP` DB-ADM-07 (aucun `intent-filter` Android, aucun `CFBundleURLSchemes` iOS) ; `DEP` DB-TRV-04 (retour vers la page demandée). [critique] Aucun fichier `.entitlements` dans `ios/Runner` (donc ni Associated Domains ni push) ; Google est le seul fournisseur externe (`lib/core/auth/service_auth.dart:52, 64`) | Liens profonds Android et iOS ; retour à la page demandée après le lien ; refonte lot A. [critique] Sur iOS, la règle App Store 4.8 peut exiger, à côté de Google, une option de connexion équivalente qui protège l'adresse (type « Se connecter avec Apple ») : **à vérifier** avant la soumission |
| [critique] **Acceptation des conditions à l'inscription** | Aucune case ni lien dans `/inscription` ; seul un contrat de rôle est signé plus tard dans `/attente/contrat` | **Absent** | Aucune chaîne « conditions générales » ni « politique de confidentialité » dans `fr.i18n.json` (seule « Confidentialité », désactivée, `:1244-1245`) | Lien vers conditions et confidentialité avant création du compte, version acceptée conservée ; consentement parental pour les profils mineurs |
| **Récupération d'accès** | `/connexion/recuperation` | STUB, aucun lien | `recuperation_page.dart` | L'écran, le lien depuis la connexion, les états (lien expiré, déjà utilisé, renvoyer) ; lot A |
| **Inscription et choix du rôle** | `/inscription` (rôle, identité, genre, récapitulatif) | Atteignable ; étapes nouvelles en STUB | `inscription_page.dart` ; `LOTS` A.2 | Élève adulte réel (DB-FOY-01) ; lien « Je suis enseignant » ; migration des élèves et enseignants déjà inscrits ailleurs (onboarding de confirmation, comptes provisoires : `decisions.md:435` archive, `06` Inscription) |
| **KYC enseignant** | `/inscription` (rôle Enseignant) → `/attente` → `/attente/accuse` → `/attente/contrat` → `/attente/piece` → attente de validation | Atteignable ; après validation, arrivée sur la Journée, **jamais** sur « Premiers pas » | `attente_page.dart:138-150` ; `routes.dart:538` | Texte et maquette du contrat enseignant ; statut et délai annoncés ; bouton vers « Premiers pas » ; notification de validation |
| **Validation des dossiers par l'administration** | `ADM-02` (valider, refuser avec motif) ; `ADM-08` (lecture) | Atteignable ; bloqué si genre de l'admin manquant | `dossiers_page.dart:305-319, 444` | Moyen de renseigner le genre du personnel ; activation, suspension, compte provisoire ; création des comptes du personnel (enseignant, contrôleur, comptable, admin) : **à vérifier** (peut-être seulement par la console Supabase) |
| **Notifications** | Cloche admin (feuille vide), cloche tuteur (STUB), réglages de notifications sans effet | **Absent** | `DEP` DB-CPT-04 ; `pubspec.yaml` sans aucune dépendance de notification push ; `supabase/functions/` sans envoi d'e-mail ni de push ; table `device_tokens` créée (`0001_fondations.sql:348`) mais sans émetteur | Notifications de cours, de changement, de validation (push, e-mail) et leurs textes ; seuls les e-mails de connexion envoyés par Supabase Auth existent (**à vérifier** : modèle et langue). [critique] Dans le dépôt : aucun modèle d'e-mail personnalisé (`supabase/config.toml:249-258` commenté, aucun dossier `supabase/templates`), SMTP de production commenté (`:239-247`), lien valable 1 h (`otp_expiry = 3600`, `:237`) : les modèles Supabase par défaut sont en anglais, et le SMTP intégré a un quota d'envoi très bas (réglage du projet de production **à vérifier**). E-mails transactionnels à spécifier : lien de connexion, dossier incomplet, validé ou refusé, rappel et changement de séance, accès qui arrive à échéance, confirmation de suppression du compte. Permission `POST_NOTIFICATIONS` (Android 13+) absente ; écran d'amorce avant la demande système à prévoir |
| [critique] **Supervision des erreurs** | `sentry_flutter` 8.14.2 (`pubspec.yaml`), filtre `beforeSend` (`lib/core/observabilite/supervision.dart:72`) | Présent | idem | À déclarer dans la politique de confidentialité, Data safety et App Privacy ; compatibilité avec la catégorie Enfants et le programme Familles **à vérifier** |
| **Paiements manuels** | Aucun écran | **Absent** | `DEP` DB-CPT-03 ; seule la date `access_until` existe | Saisie admin d'un paiement hors application, accès daté, relance humaine, lecture famille ; jamais un paiement simulé comme réglé (`01`) |
| **Mentions légales et confidentialité** | Tuteur : `/tuteur/compte/informations-legales` (STUB) ; autres rôles : ligne « Confidentialité », sous-titre « Bientôt disponible », désactivée | **Absent** | `DEP` DB-CPT-08 (aucun document dans le dépôt) ; `compte_page.dart:87-92` | Textes (mentions légales, confidentialité, conditions, consentement parental), pages publiques et dans l'application pour tous les rôles |
| **Suppression de compte** | Aucune | **Absent** | Aucune occurrence dans `lib/` ni `supabase/` | Demande de suppression depuis l'application pour chaque rôle, conséquences sur le foyer et les enfants, conservation légale (durées de `ADM-17`) ; exigée par Apple et Google (**à vérifier** sur les règles en vigueur). [critique] Google Play demande aussi une adresse web de suppression utilisable sans l'application (**à vérifier**) ; traitement côté administration absent (section 6) ; export des données personnelles (droit d'accès et de portabilité) absent lui aussi |
| **Langue** | Français seul | Partiel | `assets/i18n/ar.i18n.json` : 32 lignes ; `fr.i18n.json` : 2 366 | Décision sur l'arabe au lancement ; sélecteur de langue |
| **Libellés audio (Interface guidée)** | Composant présent | Sans son | `assets/audio/fr/` : seulement `.gitkeep` | Enregistrer les fichiers de `lib/core/i18n/cle_audio.dart` |
| **Mode démonstration par rôle** | Seulement un mot de passe de démonstration (`DEMO_AUTH`) et un bac à sable de développement (`PLAYGROUND`) | **Absent** comme sélecteur de rôle | `connexion_page.dart:89-121` ; `DEC` §1 ter-6 | Sélecteur de rôle hors production, repère « Démonstration », aucun appel serveur |
| **Publication Android** | `applicationId` `com.rewayahacademy.rewayah_academy` ; version `0.2.0+1` | Non prêt | `android/app/build.gradle.kts:19` ; `pubspec.yaml:5` ; nom affiché « rewayah_academy » (`AndroidManifest.xml:11`) ; manifeste principal : seule la permission `CAMERA`. [critique] Correction : `RECORD_AUDIO` n'est déclarée **nulle part** (ni dans `src/debug`, ni dans `src/profile`, qui ne portent que `INTERNET`, ni dans les manifestes de `livekit_client` 2.12.0 et `flutter_webrtc` 1.6.0 du cache pub) ; `INTERNET` en version publiée : fusion par les paquets **à vérifier** ; `ACCESS_NETWORK_STATE` apporté par `connectivity_plus`. CI : construction apk en échec (`08D` §5 bis, run CI #4) | Nom, icône, permissions micro et réseau, fiche Play Store, programme Familles, Data safety |
| **Publication iOS** | `CFBundleDisplayName` « Rewayah Academy » | Non prêt | `ios/Runner/Info.plist` : `NSCameraUsageDescription` présent, **`NSMicrophoneUsageDescription` absent**. [critique] Aucun `UIBackgroundModes` (son de la visio quand l'application passe en arrière-plan : **à vérifier**), aucun `PrivacyInfo.xcprivacy` ni `.entitlements` dans `ios/Runner` | Texte d'usage du micro, fiche App Store, catégorie Enfants ou non, App Privacy, compte de démonstration pour la revue ; [critique] manifeste de confidentialité Apple (**à vérifier**) |
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

[critique] Maquettes du tuteur qui servent de **modèle le plus proche** (pas de maquette de l'écran lui-même) pour d'autres rôles : Mon compte #5 à #7 et Réglages / Apparence #8, #9 pour `/compte`, `/compte/profil`, `/compte/reglages` (mêmes fonctions : thème Système, Clair, Sombre ; langue ; notifications) ; écran résultat #22 pour les pages d'état transverses du §1.3 (introuvable, accès refusé, hors ligne), que `TUTEUR_ECRANS_SANS_MAQUETTE.md` SM-45 à SM-47 dérive déjà de #22 pour tous les rôles. Recherche faite le 24/09 : aucune autre image de maquette dans `D:\RA _APP` ni `D:\RA_TUTEUR` hors captures de code.

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
2. **Jeton vidéo** : la migration `0042` refuse-t-elle vraiment tout jeton (`DEP` DB-OBS-01) ? Sans jeton, aucune rencontre élève-enseignant. [critique] `0039` à `0042` n'existent dans aucune branche du dépôt (ni `cefab7f`, ni `origin/main` @ `4a7aa2b` : `supabase/migrations/` saute de `0038` à `0043`) ; elles ne sont connues qu'en production (`DEP` DB-OBS-13). La vérification se fait donc en base, pas dans le code.
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
