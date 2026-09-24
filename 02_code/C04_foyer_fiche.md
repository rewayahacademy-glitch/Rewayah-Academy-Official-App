# C04 - Foyer et fiche élève : cartographie du code (lecture seule)

Agent : C04_foyer_fiche. Date : 24/09/2026. Phase lecture seule : aucun fichier du dépôt modifié, aucune branche changée, aucune requête sur la base de production.

## 0. Base, méthode, limites

- Checkout lu : `c0/configuration-baseline-2026-09-23`. Sur les fichiers du domaine, l'écart avec `main` ne touche que des commentaires (liens `docs/...` réécrits vers `docs/archive/...`) : `git diff main...c0/configuration-baseline-2026-09-23` sur `accueil_famille`, `reglages_enfant`, `appareils`, `avatar_tile`, `child_card`, `attente_page`. Le comportement décrit vaut donc pour `main`.
- Autres branches lues par `git show` / `git diff main...<branche>` : `observation/lot-2026-09-21`, `integration/core24-classes-v2`, `docs/core24-classes-arbitration`, `core24/fable-frontend` (ces trois dernières relèvent de CORE24, déclaré **non conforme** : référence de contrat seulement, jamais une base à intégrer).
- Migrations SQL lues pour comprendre ce que le code consomme (lecture seule). Rappel `docs/current/08:79` : `0043_offres_horaires_et_intentions.sql` est sur `main` mais **non appliquée en production** ; `0039`-`0042` sont appliquées en production mais absentes de `main`.
- Tests : aucun test lancé dans cette phase. Tout ce qui suit est du **présent dans le code**, pas du « testé ».
- Maquettes : il n'existe **aucun high-fi nouveau pour Foyer ni pour la fiche élève** dans `docs de lancement\tutuor image\`. Seules existent deux captures historiques, ouvertes et lues : `mobile\Foyer Member.png` et `mobile\Profil.png` (fiche de « Mariam »). Elles ne sont pas des références approuvées (mandat §2) ; je ne m'en sers que pour identifier les données illustratives. Le high-fi « accueil tuteur mobile » (relevé par l'agent V1) montre un lien « fournir une photo » et un bandeau « appareil non prêt », qui touchent ce domaine.

## 1. Synthèse en douze points

1. **Il n'existe pas d'écran « Foyer » au sens du mandat.** `/tuteur/foyer` rend `AppareilsPage` (`app_router.dart:278-281`), titrée « Appareils » (`appareils_page.dart:54`, `fr.i18n.json:208`) : une carte par enfant avec ses appareils. Il est hors de la barre de navigation (`nav_shell.dart:79-100` : Accueil, Disponibilités, Réglages, Suivi).
2. **Il n'existe pas de fiche élève unique.** Deux demi-fiches coexistent : `ProfilEnfantPage` en lecture seule sous `/compte/profils/:profilId` (`compte_page.dart:415-460`, `app_router.dart:179-186`) et les cartes éditables de `ReglagesEnfantPage` sous `/tuteur/reglages`, un écran pour **tous** les enfants (`reglages_enfant_page.dart:39-96`).
3. **Le modèle ne connaît que des élèves `student` mineurs créés par le tuteur.** `profils_du_foyer_v` ne rend que `role = 'student'` (`0014_acces_agent.sql:828-846`) ; `creer_profil_enfant` écrit toujours `student_type = 'minor'` (`0004:892-893`). Pas de « pour moi », pas de « proche adulte ». Le titulaire (rôle `guardian`) n'a jamais de fiche élève.
4. **Aucune date de naissance, aucun âge conservé.** L'âge saisi à l'ajout (3 à 18 côté client, `ajouter_enfant_page.dart:42-48`) ne sert qu'à dériver mode et caméra, puis est jeté (`0004:869-893`). `0043` refuse explicitement la date de naissance (`0043:83-88`) ; l'arbitrage CORE24 l'exige (branche non fusionnée). Contradiction ouverte.
5. **Photo : Supabase Storage, seau privé `avatars`, pas R2 et pas de fonction Edge** (`service_avatar.dart:118,140-142`). Téléversement direct par le client, URL signée 600 s, écriture de la clé dans `student_profiles` (`reglages_enfant_page.dart:175-180`). Pas d'aperçu, pas de progression réelle, pas de compression, pas de nettoyage de l'ancienne photo.
6. **La photo n'est affichée qu'à un seul endroit** (`ReglagesEnfantPage`, `reglages_enfant_page.dart:307-328`). L'accueil (`accueil_famille_page.dart:339-361`), le Foyer (`appareils_page.dart:131`) et la fiche Compte (`compte_page.dart:531,571`) montrent toujours les initiales.
7. **« Photo requise avant première visio » n'existe pas sur la base de travail.** Ni code, ni migration, ni `docs/current`. L'ADR-012 archivé dit même l'inverse (photo facultative). La règle n'existe que sur les branches CORE24/FABLE, déduite côté client du mode enfant, avec une demande de contrat serveur non livrée.
8. **Interface guidée : trois règles divergentes, aucune conforme au mandat.** Création : `age <= child_ui_mode_max_age` (défaut 8) donne `child` (`0004:869-874`) ; `0043` (non appliquée) : cohortes `5-7` et `8-10` en `child` (`0043:112-119`) ; arbitrage CORE24 : demande de l'enfant à 10 ans révolus, décision du tuteur (branche `docs/core24-classes-arbitration`, fichier `docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md:119-136,337-346`). La « demande de standard à partir de 10 ans » **n'est confirmée ni dans `docs/current` ni sur `main`**.
9. **Faille serveur probable sur les réglages élève** : la policy `student_profiles_family_update` ne teste pas le rôle (`0005:535-556`) et le grant de colonnes vise tout `authenticated` (`0005:563-564`). Le hook de jeton pose `household_id` pour tout profil, élèves compris (`0001:485-491`). Lecture statique : un élève connecté peut écrire `interface_mode`, `camera_policy`, `avatar_storage_key` de lui-même et de sa fratrie ; `camera_policy` décide ensuite de `can_publish_video` (`0033_tc_vues_rpc.sql:1723-1730`). Aucun scénario SQL ne teste ce cas (`scenarios_etape4.sql:647-706` ne teste que le tuteur). CORE24 le corrige sur sa branche. **Non vérifié par exécution.**
10. **Accès : une seule date, pas de statut, pas de motif.** `profils_du_foyer_v.access_until` seulement ; l'écran affiche « Accès jusqu'au <date> » même si la date est passée (`accueil_famille_page.dart:556-565`, `compte_page.dart:603-609`), alors que `app_account_valid()` ferme tout après cette date (`0001:412-423`).
11. **Préférences du compte : sept réglages écrits, aucun lu.** `preferencesLocalesProvider` n'a qu'un consommateur, la page qui l'écrit (`compte_page.dart:196-206`). Le thème choisi n'est jamais appliqué (`app.dart:32,50`, `main.dart:68`).
12. **L'accueil famille repose sur le modèle abandonné** (recherche d'enseignant, « Proposer des heures » vers `/tuteur/disponibilites`) et renvoie vers les groupes de démonstration (`accueil_famille_page.dart:463-468` vers `/tc/groupes`, servi par `GroupesDemonstrationLocale`, `port_groupes.dart:33-39`).

## 2. Carte existant -> cible (domaine B)

| Cible mandat §4 | Route existante | Fichier | Ce que fait l'écran aujourd'hui | Entrées réelles |
|---|---|---|---|---|
| Accueil `/tuteur/accueil` | `/tuteur` (`routes.dart:65`) | `features/accueil_famille/accueil_famille_page.dart` | Bloc parcours, une `ChildCard` par enfant, « Gérer le foyer », bloc Accès (§3) | racine du rôle (`routes.dart:350,361`), onglet 1 |
| Foyer `/tuteur/foyer` | `/tuteur/foyer` (`routes.dart:68`) | `features/appareils/appareils_page.dart` | Appareils par enfant, ajout d'enfant (§4) | Accueil « Appareils du foyer » (`accueil_famille_page.dart:445-450`), Compte « Foyer » (`compte_page.dart:74-82`, `:340-348`) |
| Ajouter un profil élève `/tuteur/foyer/ajouter` | `/tuteur/foyer/ajouter-enfant` (`routes.dart:71`) | `features/appareils/ajouter_enfant_page.dart` | Prénom, nom, âge 3-18 (§5) | Accueil vide, Foyer, Compte > Profils, Réglages vide |
| Fiche `/tuteur/foyer/:eleveId` | aucune ; le plus proche : `/compte/profils/:profilId` (`app_router.dart:179-186`) | `features/compte/compte_page.dart:415-622` | Lecture seule : identifiant, mode, caméra, accès, lien Réglages (§6) | Compte > Profils du foyer seulement (`compte_page.dart:400-402`) |
| `.../informations` (identité, naissance, photo) | aucune ; photo dans `/tuteur/reglages` | `reglages_enfant_page.dart:220-240` | Ajout/changement de photo | onglet Réglages |
| `.../inscription` | `/tuteur/parcours/:eleveId` (`routes.dart:89-95`) | `features/parcours_offres/*` | Questionnaire et choix d'offre (domaine C03/C05) | bloc parcours de l'accueil (`bloc_parcours.dart:145-150`) |
| `.../interface` | dans `/tuteur/reglages` | `reglages_enfant_page.dart:266-284` | Bascule directe `child`/`standard` | onglet Réglages |
| `.../camera` | dans `/tuteur/reglages` | `reglages_enfant_page.dart:243-263` | Bascule directe `allowed`/`forbidden` | onglet Réglages |
| `.../acces` | aucune | lecture seule `compte_page.dart:603-609`, `accueil_famille_page.dart:541-570` | Date de fin d'accès | - |
| `.../appareils` | par enfant dans `/tuteur/foyer` | `appareils_page.dart:103-173` | Liste, retrait, ajout (domaine D) | - |
| Historique `/tuteur/historique` | `/tuteur/suivi` (`routes.dart:104`) | `features/suivi_foyer/*` | Historique des séances du foyer, filtre par enfant (§13) | onglet 4 « Suivi » |
| Compte > Préférences | `/compte/reglages` (`routes.dart:297`) | `compte_page.dart:190-359` | Préférences locales non appliquées (§15) | Compte, Réglages par enfant (`reglages_enfant_page.dart:71-76`) |

Conséquence pour la navigation cible : l'onglet « Suivi » actuel **est** l'Historique (données réelles `mes_seances_v` + `presence_seance_v`), l'onglet « Réglages » deviendrait des sous-pages de fiche élève, l'onglet « Disponibilités » sert le matching abandonné (`docs/current/00:26`). Du point de vue de ce domaine, « Historique » est la destination la moins coûteuse à rendre réelle ; je ne vois rien dans le code du foyer qui mérite davantage cette place.

## 3. Accueil famille actuel (`AccueilFamillePage`, TUT-01)

Titre « Votre foyer » (`fr.i18n.json:1259`, `accueil_famille_page.dart:228`), pas « Accueil ». Ordre de rendu (`accueil_famille_page.dart:227-287`) :

1. `BlocParcours` (`:236`, `bloc_parcours.dart:32-76`) : une carte par apprenant dont le parcours n'est pas « groupe confirmé », lue dans `v_parcours_onboarding` (`service_offres.dart:130-135`). La vue vient de `0043` (`0043:945-983`), **non appliquée en production** : la lecture échoue et le bloc se tait (`bloc_parcours.dart:46-48`). Le titre de section prend le prénom du **premier** apprenant pour toute la liste (`bloc_parcours.dart:66`).
2. États : squelette au premier chargement (`:237-238`) ; foyer vide : `EmptyState` « Aucun enfant dans le foyer » avec action vers l'ajout (`:239-246`) ; sinon une `ChildCard` par enfant (`:248-262`).
3. `ChildCard` (`child_card.dart:100-355`) : prénom, initiales (aucune URL de photo passée, `accueil_famille_page.dart:339-361`), phase parmi cinq (`PhaseEnfant`, `:43-59`) : en cours (pastille « En direct », bouton « Assister »), cours aujourd'hui, autre jour, en recherche d'enseignant, séance annulée. Carte non cliquable (`:348-351`) : **aucune entrée vers une fiche élève depuis l'accueil**. `EnfantImminent`, `horsLigne`, `onReessayer` existent dans le composant mais ne sont jamais produits ici.
4. « Assister » (`:180-197`) : RPC `assister_seance` (`service_video.dart:131-134`) puis `/salle` avec `BilletSalle` en `extra`. Sur `observation/lot-2026-09-21`, ce geste est remplacé par `Routes.tcObservation(seanceId)` (diff lu) : le chemin actuel contourne la politique d'observation. Domaine Cours/Observation.
5. Retour local d'échec (`:265`) et message d'erreur global en encre d'alerte (`:266-276`).
6. Section « Gérer le foyer » (`:278-280`, `_GererLeFoyer` `:437-472`) : trois lignes dans une `AppCard` : « Appareils du foyer » (vers `/tuteur/foyer`), « Réglages par enfant » (vers `/tuteur/reglages`), « Mes groupes » (vers `/tc/groupes`, **groupes de démonstration**).
7. `_BlocAcces` (`:541-570`) : une ligne par enfant, « Accès de X jusqu'au JJ/MM/AAAA » ou « sans date de fin ».

Horloge : minuteur d'une minute (`:160-163`), heures en heure locale de l'appareil sans fuseau affiché (`_hhmm` `:581-583`), jour de semaine via `t.disponibilites.joursLongs`.

Écarts avec le mandat §5 Accueil : pas de sélecteur de profil (une carte par enfant à la place) ; pas de classe, parcours, enseignant avec photo ni titre Sayyid/Sayyida (seul `enseignantPrenom`) ; pas de « Voir la classe » ; pas de blocage contextualisé (photo, dossier, appareil) ; pas de « Avant le prochain cours » ni « Dernière séance » ; profil propre du parent absent ; phase « en recherche d'un enseignant » et « Proposer des heures » issues du matching abandonné ; lien vers des données fictives. Le bloc Accès et les liens Réglages/Appareils dupliquent le Foyer, ce que le mandat interdit (« Ne duplique pas toutes les fonctions du Foyer »).

## 4. Foyer actuel : liste des membres

Deux listes de membres, toutes deux sur `elevesDuFoyerProvider` (`service_appairage.dart:293-296`, vue `profils_du_foyer_v`) :

**A. `/tuteur/foyer` = `AppareilsPage` (TUT-02)** (`appareils_page.dart:27-101`)
- Phrase de règle en tête : « Deux appareils au maximum par enfant, un seul en cours à la fois. » (`:60`, `fr.i18n.json:209`, texte figé).
- Vide : `EmptyState` vers l'ajout (`:62-69`).
- Par enfant (`_BlocEleve`, `:103-173`) : `BentoTile`, initiales (jamais la photo, `:131`), prénom, **identifiant immuable** (`:138`), appareils actifs (plateforme brute « Windows/Android/iOS/Web », dernière utilisation), bouton « Retirer » par appareil, puis « Ajouter un appareil » ou message de limite (`:156-168`).
- Retrait : appel direct `revoquer_appareil`, **sans confirmation** (la chaîne `appareils.revoquerConfirmation` n'est utilisée que dans la galerie de dev, `catalogue_galerie.dart:652,662`), **sans gestion d'erreur** ni retour (`:83-86`, `unawaited` `:151`).
- En bas : bouton secondaire « Ajouter un enfant » (`:90-95`).
- États manquants : aucun chargement ni erreur pour les élèves (colonne vide) ; une erreur de lecture des appareils s'affiche « Aucun appareil appairé » (`:77`, `:145-146`), **une absence inventée** et un bouton d'ajout qui ne tient plus compte de la limite.
- Aucune classe, aucun état d'inscription, aucun état d'accès, aucun titulaire.

**B. `/compte/profils` = `ProfilsComptePage`** (`compte_page.dart:362-412`)
- États complets (squelette, erreur avec réessayer, vide avec action « Ajouter un enfant »).
- Par enfant : `AppCard` cliquable, initiales, prénom, « Identifiant : X », « Mode enfant » / « Mode standard » (`:523-556`). Libellé interdit « Mode enfant » (`fr.i18n.json:1161`).

Ce qui manque au Foyer cible : titulaire non élève et « Créer mon profil élève » (aucun modèle, voir §10), classe ou inscription en cours par membre, statut d'accès lisible, appareils partagés (un appareil = une ligne `devices` par profil : `mes_appareils_v`, `0014:848-866`), nom d'appareil (la vue porte `label`, `0014:857`, mais `AppareilAppaire.depuisJson` ne le lit pas, `service_appairage.dart:47-62`).

## 5. Ajout d'un profil

`AjouterEnfantPage` (`ajouter_enfant_page.dart:19-140`), une seule page `PageParcours` « 1 sur 1 » :
- Champs : prénom, nom, âge (`:28-30`) ; âge valide 3 à 18 (`:42-48`, message `fr.i18n.json:228`) ; explication « L'âge fixe le mode d'affichage et la politique caméra » (`fr.i18n.json:229`).
- Envoi : `ServiceAppairage.creerEnfant` -> fonction Edge `creer-profil-enfant` (`service_appairage.dart:241-259`) -> RPC `creer_profil_enfant` (service_role, `0004:828-905`).
- Côté serveur : appelant `guardian` au compte `active`/`provisional_active` (`0004:850-858`, donc impossible en `pending_kyc`) ; âge 3 à 99 (`0004:862`) ; mode `child` si `age <= child_ui_mode_max_age` (défaut 8), caméra `allowed` si `age >= camera_auto_allow_min_age` (défaut 11) (`0004:869-875`) ; `student_type = 'minor'` en dur (`0004:893`) ; statut de compte hérité du tuteur au moment T (`0004:888`) ; l'âge n'est stocké nulle part.
- Fonction Edge : crée un utilisateur auth au courriel aléatoire à chaque appel (`creer-profil-enfant/index.ts:49-57`), compensation si la RPC échoue (`:71-77`). Pas d'idempotence : une réponse perdue puis un nouvel essai créent un doublon (constat partagé avec C03).
- Après succès : retour à `/tuteur/foyer` (`ajouter_enfant_page.dart:74`), pas d'enchaînement vers le questionnaire ni vers la photo. Erreur générique unique (`:76-79`).

Absent : choix « pour moi / pour un enfant ou proche », date de naissance, lien de parenté, consentement propre d'un proche adulte, photo à la création, niveau (le paramètre `niveau` existe dans le service, `service_appairage.dart:163`, jamais envoyé par l'écran).

## 6. Fiche élève : ce qui existe rubrique par rubrique

| Rubrique mandat | Existant | Source réelle | Écriture possible | Manque |
|---|---|---|---|---|
| En-tête (prénom, photo, âge, classe) | `ProfilEnfantPage` : initiales + prénom (`compte_page.dart:567-581`) ; **titre toujours « Profil de Non disponible »** (`:429`, passe `t.compte.nonDisponible` au lieu du prénom) | `profils_du_foyer_v.first_name` | non | photo (URL jamais demandée ici), âge (non stocké), classe |
| Identité | prénom seul ; « Identifiant » = identifiant immuable (`:584-588`) | `profiles.first_name`, `immutable_id` | **non** : aucune policy ni RPC ne permet au tuteur de modifier le prénom/nom d'un enfant (`profiles_self_update` ne vise que soi, `0001:713-715`) | nom de famille (volontairement exclu des vues), édition |
| Date de naissance | rien | aucune colonne sur `main` (recherche `birth|naissance` : seul `0043:83-88`, qui la refuse) | non | colonne, RPC, politique d'âge (voir §8) |
| Photo | `ReglagesEnfantPage` seulement (§7) | `student_profiles.avatar_storage_key`, seau `avatars` | oui (grant colonne + policy stockage `guardian`) | aperçu, progression, reprise, affichage partout ailleurs |
| Classe / inscription | rien sur la fiche ; affectation lue ailleurs (`mes_affectations_v`, `service_planning.dart:311-313`) ; parcours dans `v_parcours_onboarding` (non appliquée en prod) | - | - | nom de classe, enseignant, état d'inscription |
| Interface | `ProfilEnfantPage` : ligne titrée « Mode enfant » valant « Mode enfant »/« Mode standard » (`compte_page.dart:589-595`) ; bascule dans `ReglagesEnfantPage` (`reglages_enfant_page.dart:266-284`) | `student_profiles.interface_mode` | oui, écriture directe de colonne (§8) | libellé « Interface guidée », politique, demande enfant |
| Caméra en cours | lecture (`compte_page.dart:596-602`) ; bascule (`reglages_enfant_page.dart:243-263`) | `student_profiles.camera_policy` | oui, écriture directe | confirmation, mention « séance suivante » vérifiée serveur |
| Accès Rewayah | « Accès sans date de fin » / « Accès jusqu'au AAAA-MM-JJ » (`compte_page.dart:603-609`, format ISO `:620-621`, différent du JJ/MM/AAAA du reste) | `profiles.access_until` | non | statut, date de début, motif, état expiré (§11) |
| Appareils | pas sur la fiche ; par enfant dans `AppareilsPage` | `mes_appareils_v` | retrait via RPC | nom d'appareil, appareil partagé, confirmation |
| Demandes (hors mandat) | réaffectation, durée, minimum payable (`reglages_enfant_page.dart:336-403`) via `serviceMatchingProvider.demander` | RPC du matching (`core/matching`) | oui | relève du modèle matching, à réexaminer avec le modèle classe |

`ProfilEnfantPage` retrouve l'enfant en filtrant toute la liste du foyer (`compte_page.dart:439-455`) : un identifiant inconnu donne « Aucun profil pour l'instant » (registre subi), pas un « accès impossible ». Son lien « Réglages » ouvre `/tuteur/reglages`, **la liste de tous les enfants**, pas les réglages de celui-ci (`:611-616`).

## 7. Photo : chaîne réelle et règles

Chaîne (`reglages_enfant_page.dart:150-190`) :
1. `SelecteurPhotoNatif.choisirPhoto` : `FilePicker.pickFile`, extensions `jpg jpeg png webp heic` (`service_avatar.dart:54-67`). Aucune capture caméra, aucune vérification de type réel (MIME), extension par défaut `jpg` si absente (`:29-35`).
2. Refus avant envoi au-delà de 4 Mo (`reglages_enfant_page.dart:162-173`, `ServiceAvatar.tailleMaximaleOctets` `service_avatar.dart:107`). Le seau n'a **aucune limite serveur** (création sans `file_size_limit` ni `allowed_mime_types`, `0004:997-999`).
3. `uploadBinary('avatars', '<eleveId>/<epochMs>.<ext>')` sans `contentType` (`service_avatar.dart:136-142`).
4. Écriture de la clé par `majReglages(cleAvatar:)` -> `update student_profiles` (`service_appairage.dart:262-283`).
5. Invalidation de `avatarUrlProvider` (`reglages_enfant_page.dart:180`) ; affichage par URL signée 600 s (`service_avatar.dart:125,148-150`), repli initiales identique en cas d'échec ou de chargement (`avatar_tile.dart:59-73`).

Policies de stockage (`0004:1019-1062`) : écriture, remplacement et suppression réservés à `app_role() = 'guardian'` dans le dossier d'un profil de son foyer ; lecture par le foyer ou par l'élève lui-même. Enseignant et autres élèves exclus (ADR-012 archivé, `docs/archive/2026-09-pre-remise-a-plat/architecture/decisions.md:379-395`).

Défauts : pas d'aperçu avant envoi (déjà noté en `etape-4-journal.md:291` archivé) ; « progression » = simple indicateur `enCours` ; si l'écriture de la clé échoue après le téléversement, l'objet reste orphelin et l'erreur est affichée (le `catch` interne de `_ecrire` avale l'exception, `reglages_enfant_page.dart:139-142`) ; l'ancienne photo n'est jamais supprimée ; HEIC accepté mais non affichable par `Image.network` sur plusieurs plateformes, donc repli silencieux sur les initiales ; compression serveur supposée par l'ADR-012 mais inexistante (question 17 ouverte, `decisions.md:1824`). Aucune confusion avec la pièce d'identité : types séparés `PhotoEnfant` / `PieceAEnvoyer`, seaux séparés `avatars` / `kyc` (`service_avatar.dart:9-13`, `service_dossier.dart:87`).

**Photo requise avant la première visio** : aucune règle sur la base de travail.
- `docs/current` : rien. `02_ARCHITECTURE_ET_SECURITE.md:22` parle de « portraits visibles en classe », ce qui contredit l'ADR-012 archivé (photo jamais montrée à l'enseignant ni aux autres élèves). À arbitrer.
- ADR-012 : photo réelle, ajoutée par le tuteur, **pas imposée** (`decisions.md:381`).
- Seule trace : branches CORE24/FABLE. `core24/fable-frontend:docs/core24/CONTRACT_REQUEST_FABLE.md:228-245` demande au serveur un drapeau `photo_identification_requise` et une erreur `{ "error": "photo_requise" }` de `create-room-token` ; en attendant, l'exigence y est **déduite côté client** du mode enfant (`integration/core24-classes-v2:lib/features/classes/domaine/adaptateurs_existants.dart` ~l. 487-497 : `photoRequise: m.mode == InterfaceMode.enfant`, ou `live_photo_required`). Rien de cela n'est livré côté serveur sur `main`.
- Conclusion : un bandeau « photo requise » (vu sur le high-fi accueil mobile) serait aujourd'hui une obligation inventée. Au mieux, afficher « Pas encore de photo » avec une action facultative, ou dépendance backend documentée.

## 8. Interface guidée : règles réelles

Ce que le code **fait** :
- Valeur stockée `student_profiles.interface_mode` (`child`/`standard`), enum Dart `InterfaceMode.enfant`/`standard`, repli `standard` si illisible (`enums.dart:85-107`).
- Valeur initiale à la création : `child` si `age <= get_config('child_ui_mode_max_age', 8)` (`0004:869-874`). Valeur effective en production de `app_config` : **INCONNU** (non lue).
- Changement : bouton libre dans `ReglagesEnfantPage` (« Passer X au grand affichage » / « à l'affichage courant », `reglages_enfant_page.dart:275-283`) qui écrit la colonne directement (`service_appairage.dart:268-282`). Aucune limite d'âge, aucune demande de l'enfant, aucune confirmation.
- Application : le mode est lu à la résolution de session de l'élève (`source_session.dart:79-104`) et pilote le thème (`app.dart:48-49`) ; un changement ne s'applique qu'à la prochaine résolution de session de l'appareil élève, ce que le texte d'intro traduit par « à la séance suivante » (`fr.i18n.json:1296`) sans preuve serveur.
- Le titulaire (`guardian`) n'a pas de `student_profiles` : il ne peut **pas** activer l'Interface guidée pour lui-même, contrairement à `docs/current/00:28` et `08:39` (« adulte peut activer le mode »).
- Libellés : « Grand affichage / Affichage courant » dans Réglages (`fr.i18n.json:1308-1312`), « Mode enfant / Mode standard » dans Compte (`fr.i18n.json:1161-1162`) et la galerie (`:1654-1655`). « Interface guidée » n'existe que dans l'espace enseignant Teaching Core (`fr.i18n.json:1957`). Aucune occurrence conforme côté tuteur.

Ce que les documents **prétendent** :
- `docs/current/00:28`, `03:12`, `06:30`, `08:39` : renommer en « Interface guidée », activable aussi par un adulte ; conserver la valeur technique `child`.
- `enums.dart:86-89` (commentaire) : « environ 6 à 8 ans » / « 9 ans et plus ».
- `0043:91-92,112-119,578-635` (non appliquée en prod) : mode **déduit de la cohorte** par `enregistrer_profil_apprentissage` (`5-7` et `8-10` -> `child`), donc un enfant de 9-10 ans passerait en `child` alors que la création l'aurait mis en `standard`, et le choix du tuteur serait écrasé à chaque enregistrement du parcours.
- Arbitrage CORE24 (branche `docs/core24-classes-arbitration`, commit `196eb06`, 22/09) : cohortes `6-9`, `10-13`, `14-17`, `18+` sur **date de naissance** ; bouton « Demander l'affichage standard » pour l'enfant à 10 ans révolus, demande au tuteur, pas de changement direct ; tuteur peut activer directement ; Interface guidée indépendante de la cohorte ; `child_ui_mode_max_age` ne décide plus rien (`CORE24_CLASSES_ARBITRATION_FINAL.md:110-139,337-346`).
- Implémentation CORE24 (branche `integration/core24-classes-v2`, commit `dcafddf`, **non conforme, non fusionnée, non appliquée**) : migration `20260923000400_core24_interface_guidee.sql` avec `demander_affichage_standard()` (élève, >= 10 ans, date connue), `repondre_demande_affichage_standard(uuid, boolean)`, `activer_affichage_standard_tuteur(uuid)`, `repasser_interface_guidee(uuid)`, `interface_guidee_etat()`, retrait de `interface_mode` du grant client (l. 24-25) et policies par rôle ; côté Flutter, champ `interface_standard_request_status` dans `profils_du_foyer_v` et trois méthodes de service (diff `main...integration/core24-classes-v2` sur `service_appairage.dart` et `reglages_enfant_page.dart`).

Verdict pour l'agent B : « demande de standard à partir de 10 ans » et « activation par le tuteur » ne sont **pas confirmées dans le dépôt actif** ; elles existent seulement dans un arbitrage non fusionné et dans un code déclaré non conforme. Le frontend peut préparer l'écran `.../interface` (libellé neutre, état courant, action tuteur existante) mais toute demande de l'enfant est une **dépendance backend** (contrat CORE24 réutilisable comme spécification). Ne pas fabriquer de bascule côté élève.

## 9. Caméra en cours

- Valeur `student_profiles.camera_policy` (`allowed`/`forbidden`, repli `forbidden`, `enums.dart:502-524`).
- Initiale : `allowed` si `age >= camera_auto_allow_min_age` (défaut 11) (`0004:871-875`) ; règle archivée « plus de 10 ans » (`decisions.md:301-306`).
- **Application serveur réelle** : `autoriser_jeton_video` lit `camera_policy` et fixe `can_publish_video` (`0033_tc_vues_rpc.sql:1723-1730`), traduit en `canPublishSources` LiveKit (`supabase/functions/_shared/livekit.ts:90-104`). La préférence n'est donc pas qu'un affichage.
- Écriture : même chemin et même faiblesse que le mode (§1 point 9) : policy sans rôle, grant à tout `authenticated`.
- Écran : bouton immédiat sans confirmation (`reglages_enfant_page.dart:252-263`) ; un seul drapeau `_reglageEnCours` partagé par caméra et mode (`:110,257,280`), les deux boutons tournent ensemble.
- Aucun lien avec la permission caméra de l'appareil (scanner QR) : bien séparé dans le code.

## 10. Proches adultes et « pour moi »

- Inscription : « Élève adulte » crée un `guardian` sans fiche élève, comme « Parent » (`inscription_page.dart:33-41`, `0004:370-413`). Aucun chemin ne crée de `student_profiles` `autonomous` (constat détaillé par C03, §4 et dépendance D1).
- Ajout : toujours `minor` (`0004:893`), bornes client 3-18. Un proche adulte ne peut pas être ajouté depuis l'écran ; s'il l'était par l'API (serveur jusqu'à 99 ans), il serait traité en mineur : le tuteur pourrait modifier sa photo, sa caméra, son mode et verrait sa présence et ses séances.
- Aucune notion de lien (parent, proche), de consentement propre, de droits différenciés ni de majorité atteinte. Les fonctions `peut_decrire_apprenant` / `peut_poser_disponibilite` prévoient un `autonomous` qui agit pour lui-même (`0043:197-227`, `0005:425-450`) mais rien ne le crée.
- Conclusion : l'option « pour un proche adulte » et « Créer mon profil élève » sont des **dépendances backend** (D1, D2 de C03). L'UI ne doit pas les simuler.

## 11. Statuts d'accès

- Donnée exposée au foyer : `access_until` seulement (`profils_du_foyer_v`, `0014:839`). Commentaire du modèle : `null` est le cas ordinaire, la date ne concerne que les foyers importés (`service_appairage.dart:133-138`).
- Effet réel : `app_account_valid()` exige `account_status in ('active','provisional_active')` **et** `access_until > now()` (`0001:412-423`) : un enfant dont la date est dépassée ne passe plus aucune policy.
- Affichage : pas d'état « expiré » (`accueil_famille_page.dart:556-565`, `compte_page.dart:603-609`) ; formats de date différents entre les deux écrans.
- Absents : `account_status` de l'enfant (non exposé par la vue), date de début, motif (offert, payé hors application, suspendu), historique. Le statut de l'enfant est copié du tuteur à la création (`0004:888`) ; la validation KYC ne met à jour que le profil concerné (`0004:558-562`) ; aucune propagation trouvée dans les migrations lues (à confirmer côté admin).
- Mandat « Accès Rewayah : statut, dates, motif utile » : **dépendance backend** (projection statut + dates + motif par élève).

## 12. Appareils (vu depuis la fiche, domaine D)

- Code : `creer_code_appairage` (tuteur valide, plafond `max_devices_per_student` défaut 2, `0004:580-608`), `revoquer_appareil` (tuteur ou admin du foyer, efface `token_hash`, journalise, `0004:731-766`), vue `mes_appareils_v`.
- Aucune règle « retrait indisponible pendant la séance » côté serveur (lu `0004:731-766`) : la mention de la capture historique `Profil.png` serait inventée.
- Un appareil partagé = plusieurs lignes `devices`, une par profil ; `profils_locaux.dart` garde les profils connus de l'appareil. Pas de notion « Cet appareil » côté tuteur.

## 13. Historique (`SuiviFoyerPage`, TUT-06)

Lecture pure (`suivi_foyer_page.dart:22-46`) : `mes_seances_v` et `presence_seance_v` plafonnées à 200 (`service_suivi.dart:16,59-78`) ; tri par date décroissante ; filtres par enfant seulement à partir de deux enfants (`:163-165`) ; colonnes Date, Enfant, Enseignant (« prénom · identifiant », `:306-307`), État ; le sort du cours prime sur la présence (`vue_suivi_foyer.dart:195-205`) ; présence illisible = inconnu, jamais absent (`vue_suivi_foyer.dart:121-124`). États chargement, erreur, vide, filtre vide présents (`:214-251`). Pas de filtre classe/période/statut, pas de détail de séance, pas d'onglet Observations. Domaine E pour la suite ; base réelle réutilisable.

## 14. Dossier (KYC) : titulaire uniquement

`AttentePage`, `AccusePage`, `ContratPage`, `DepotPiecePage` (`features/dossier/*`) servent le dossier du **titulaire** (`etat_dossier()`, `contract_acceptances`, seau `kyc` + `kyc_documents`, `service_dossier.dart:107-156`). Rien ne concerne l'élève ni son portrait. `creerProfil` n'envoie pas `p_timezone` (`service_dossier.dart:96-104`) : tout foyer naît en `Europe/Paris` (`0004:352,386-388`). Domaine Admission (C03).

## 15. Préférences (`core/preferences`)

`PreferencesLocales` : sept valeurs en mémoire, perdues au redémarrage (`preferences_locales.dart:18-22,87`). Aucune n'est lue ailleurs que par la page qui les écrit : le thème n'atteint pas `MaterialApp` (`app.dart:32,50` ; `main.dart:68` construit `const RewayahApp()`), les animations suivent seulement `MediaQuery.disableAnimationsOf` (`app_mouvement.dart:122`), les notifications n'ont aucun service. Le texte « Ces préférences restent sur cet appareil et s'appliquent tout de suite. » (`fr.i18n.json:1124`) est faux sur les deux points. Complète le relevé V4.

## 16. Services, vues, RPC, tables, fonctions consommés (noms exacts)

| Consommateur | Appel | Nature | Statut serveur |
|---|---|---|---|
| `ServiceAppairageSupabase.eleves` | `profils_du_foyer_v` select | vue (`0014:828-846`) | appliquée |
| `ServiceAppairageSupabase.appareils` | `mes_appareils_v` select order `paired_at` | vue (`0014:848-866`) | appliquée |
| `.creerCode` | RPC `creer_code_appairage(p_student_profile_id)` | `0004:580` | appliquée |
| `.revoquer` | RPC `revoquer_appareil(p_device_id)` | `0004:731` | appliquée |
| `.creerEnfant` | Edge `creer-profil-enfant` {first_name, last_name, age, level?} -> RPC `creer_profil_enfant` | `index.ts`, `0004:828` | présente dans le dépôt ; déploiement non vérifié ici |
| `.majReglages` | `student_profiles` update (`interface_mode`, `camera_policy`, `avatar_storage_key`) eq `profile_id` | table + policy `student_profiles_family_update` + grant colonnes (`0005:535-565`) | appliquée |
| `ServiceAvatarSupabase.televerser` | Storage `avatars` `uploadBinary` | seau + 4 policies (`0004:997-1062`) | appliquée |
| `.urlSignee` | Storage `avatars` `createSignedUrl(600)` | idem | appliquée |
| `ServiceVideo.assisterEnTuteur` | RPC `assister_seance(p_session_id)` | `0012` | appliquée |
| `ServicePlanning` | `mes_seances_v`, `mes_affectations_v`, `weekly_availability`, RPC `mon_fuseau` | vues/table | appliquées |
| `ServiceSuivi` | `mes_seances_v`, `presence_seance_v` | vues | appliquées |
| `ServiceOffres` (bloc parcours) | `v_parcours_onboarding`, RPC `regles_academie` | `0043:945` | **non appliquée en production** |
| `ServiceMatching.demander` | demandes réaffectation/règle | `core/matching` | modèle abandonné |
| `serviceRegles` | `regle_effective` via `valeurRegleProvider` | - | appliquée (non revérifiée) |
| `ServiceAcceptationsSupabase` | `contract_acceptances` select | table | appliquée |
| `ServiceDossierSupabase` | RPC `creer_profil_inscription`, `etat_dossier`, `contract_acceptances` insert, Storage `kyc`, `kyc_documents` insert | - | appliquées |
| `SourceSession` | `profiles` select `account_status, student_profiles(interface_mode)` | table | appliquée |
| `portGroupesProvider` (lien « Mes groupes ») | `GroupesDemonstrationLocale` | **double de démonstration** | aucune donnée réelle |

## 17. Manques et dépendances backend (contrats à demander, sans les écrire)

| # | Besoin mandat | Existant | Contrat nécessaire (entrée / sortie) | Impact si absent |
|---|---|---|---|---|
| B1 | Fiche élève avec classe, enseignant, état d'inscription | `mes_affectations_v`, `v_parcours_onboarding` (non appliquée) | projection par élève du foyer : classe, enseignant public, état (inscrit, en attente, liste d'attente) | en-tête et ligne « Parcours et inscription » vides ou « indisponible » |
| B2 | Date de naissance, âge | rien | colonne protégée + RPC tuteur `definir_date_naissance_apprenant(uuid, date)` (nom CORE24) ; décision `0043` contre CORE24 | pas d'âge affiché, pas de cohorte fiable |
| B3 | Interface guidée selon politique | écriture directe de colonne | RPC `activer_affichage_standard_tuteur`, `repasser_interface_guidee`, `repondre_demande_affichage_standard`, `demander_affichage_standard`, `interface_guidee_etat` + statut de demande dans la vue (contrat CORE24) ; retrait de `interface_mode` du grant | pas de demande enfant ; bascule actuelle conservée |
| B4 | Sécurité réglages élève | policy sans rôle (`0005:535-556`) | policy restreinte à `app_role() = 'guardian'` (ou RPC) + scénario SQL négatif « élève » | risque d'élévation caméra/mode par l'élève |
| B5 | Photo requise avant visio (si décidée) | rien | drapeau `photo_identification_requise` par membre + erreur structurée `photo_requise` de `create-room-token` (demande FABLE) ; limite de taille/MIME du seau ; compression ; purge | aucun blocage réel ; ne pas l'inventer |
| B6 | Accès : statut, dates, motif | `access_until` | projection `statut`, `debut`, `fin`, `motif` par élève | ligne « Accès » réduite à une date |
| B7 | Créer mon profil élève (titulaire) | rien | D1 de C03 | option absente, pas simulée |
| B8 | Proche adulte | rien | D2 de C03 (type, consentement, droits bornés) | seul « enfant » proposé |
| B9 | Modifier identité de l'élève | rien | RPC tuteur bornée (prénom, nom) journalisée | champs en lecture seule |
| B10 | Nom d'appareil, appareil partagé | `label` présent dans la vue mais non lu | lire `label` (frontend seul) ; modèle partagé = domaine D | - |
| B11 | Persistance des préférences | mémoire | stockage local (dépendance à ajouter par le coordinateur) ou préférences serveur | réglages perdus au redémarrage |

## 18. Données fictives et constantes illustratives

Dans le code :
| Emplacement | Valeur | Nature |
|---|---|---|
| `service_appairage.dart:189` | `appareilsParEleve = 2` | copie client d'une config serveur (`max_devices_per_student`, `0004:608`) |
| `fr.i18n.json:209,211` | « Deux appareils au maximum », « Deux appareils sont déjà appairés » | constante figée dans le texte |
| `ajouter_enfant_page.dart:44`, `fr.i18n.json:228` | âge 3 à 18 | borne client, serveur 3 à 99 (`0004:862`) |
| `service_avatar.dart:107,125` | 4 Mo, URL 600 s | bornes client seulement |
| `reglages_enfant_page.dart:447` | durées 30, 45, 60, 90 min | raccourcis de saisie (documentés comme tels) |
| `accueil_famille_page.dart:463-468` -> `port_groupes.dart:37-39` | groupes `GroupesDemonstrationLocale` | **données fictives servies au tuteur** |
| `bloc_parcours.dart:61` ; `service_offres.dart:102-106` | `minimumLancement ?? 0` ; défauts de `ReglesAcademie` si la RPC rend `null` | repli silencieux |
| `service_planning.dart:259` ; `0004:352,387` | fuseau `Europe/Paris` par défaut | repli qui peut fausser les heures |
| `service_appairage.dart:58` | `appaireA = DateTime.now()` si absent | date inventée |
| `compte_page.dart:149-153` | « Langue : Français » en dur | valeur affichée non lue |
| `enums.dart:86-89` | « environ 6 à 8 ans / 9 ans et plus » | commentaire non contractuel |
| `service_suivi.dart:16` | plafond 200 séances | borne de lecture (affichée honnêtement) |

Dans les captures historiques (`Foyer Member.png`, `Profil.png`), à ne jamais coder : « 3 enfants », « 1 appareil familial », « 2 alertes », « 1/2 appareils », âges « 8 ans / 10 ans / 6 ans », classes « Al-Fajr / An-Nour / Al-Badr », « Actif · Accès normal », « Diagnostic à terminer », « iPhone de Mariam », « Disponible pour Salam, Mariam, Fatimah », « Actif jusqu'au 30 octobre », « Dernière utilisation : 18 septembre, 14:20 », « Appareil actuel », « Indisponible pendant la séance », « Autorisée à la séance suivante », bandeau « Choix du profil + PIN ». Aucune de ces données n'a de source dans la vue foyer (pas d'âge, pas de classe, pas d'alerte, pas de nom d'appareil lu, pas de règle de retrait en séance). Les compteurs décoratifs sont en outre proscrits par le mandat §5 Foyer.

## 19. Défauts constatés dans le code (à corriger côté frontend quand le contrat le permet)

1. Titre de fiche « Profil de Non disponible » (`compte_page.dart:429`).
2. Photo jamais affichée hors `ReglagesEnfantPage` (`accueil_famille_page.dart:339-361`, `appareils_page.dart:131`, `compte_page.dart:531,571`) alors que `avatarUrlProvider` existe.
3. Retrait d'appareil sans confirmation ni erreur (`appareils_page.dart:83-86,151`).
4. Erreur de lecture des appareils présentée comme « Aucun appareil appairé » (`appareils_page.dart:77,145-146`).
5. `ReglagesEnfantPage` sans état chargement ni erreur (`reglages_enfant_page.dart:78-91`) ; `AppareilsPage` idem pour les élèves (`appareils_page.dart:62-88`).
6. Libellés interdits « Mode enfant » (`fr.i18n.json:1161`, `compte_page.dart:545-549,590`) et absence de « Interface guidée » côté tuteur.
7. Lien « Réglages » de la fiche vers la liste globale (`compte_page.dart:611-616`).
8. Formats de date hétérogènes (ISO `compte_page.dart:620-621` contre JJ/MM/AAAA ailleurs).
9. Accès expiré affiché comme valide (`accueil_famille_page.dart:556-565`, `compte_page.dart:603-609`).
10. Préférences écrites mais jamais appliquées, texte d'intro faux (§15).
11. Messages d'erreur Postgrest bruts potentiellement exposés (`_message`, `reglages_enfant_page.dart:602-610`), contraire au mandat §8 « pas de code technique exposé ».
12. Titre de section du bloc parcours au prénom du premier apprenant seulement (`bloc_parcours.dart:66`).
13. `label` d'appareil non lu (`service_appairage.dart:47-62`).
14. Photo orpheline si l'écriture de clé échoue ; ancienne photo jamais purgée (`reglages_enfant_page.dart:175-180`).
15. Lien « Mes groupes » vers des groupes fictifs (`accueil_famille_page.dart:463-468`) : bloquant pour de vraies familles (`08:36,66`).

## 20. Contradictions à arbitrer (ne pas trancher en silence)

| # | Sujet | Source A | Source B | Proposition minimale |
|---|---|---|---|---|
| X1 | Âge : tranche ou date de naissance | `0043:83-88` (tranche, jamais de date) ; `fr.i18n.json:975` | Arbitrage CORE24 `:119-123` (date de naissance source unique) ; mandat §6 | écran frontend capable d'afficher un âge s'il est fourni, sans le saisir tant que B2 manque |
| X2 | Cohortes | `0043:112-119` : 5-7, 8-10, 11-14, 15-17, 18+ | CORE24 et mandat §6 : 6-9, 10-13, 14-17, 18+ | aucune constante de cohorte côté client ; lire la source |
| X3 | Qui décide de l'Interface guidée | création par âge (`0004:869-874`) ; `0043` par cohorte (écrase) ; bascule libre du tuteur | CORE24 : indépendante de la cohorte, demande enfant à 10 ans, décision tuteur | garder la bascule tuteur existante, libellé neutre, demande enfant = dépendance B3 |
| X4 | Photo élève en classe | ADR-012 archivé : jamais visible par enseignant ni élèves | `02_ARCHITECTURE:22` « portraits visibles en classe » ; FABLE « photo d'identification requise » | ne rien exposer de plus ; décision directeur |
| X5 | Photo obligatoire avant visio | ADR-012 : non imposée | mandat §5 (« si règles réelles ») ; high-fi accueil (« fournir une photo ») ; FABLE | pas de blocage tant que B5 n'existe pas |
| X6 | Âge caméra par défaut | `decisions.md:303-304` (plus de 10 ans) | `0004:871` (11 ans et plus) | équivalents pour des âges entiers ; valeur serveur fait foi |
| X7 | Adulte et Interface guidée | `00:28`, `08:39` : activable par un adulte | titulaire sans fiche élève, aucun chemin | dépendance B7 |

## 21. Recommandations pour l'agent B (sans écrire de code maintenant)

- Réutiliser `EleveDuFoyer`, `elevesDuFoyerProvider`, `ServiceAppairage.majReglages`, `ServiceAvatar`, `avatarUrlProvider`, `AvatarTile`, `SettingRow` : ne pas créer de second service.
- Faire de `/tuteur/foyer` le vrai Foyer (liste de membres sobre) et créer la fiche `/tuteur/foyer/:eleveId` en **déplaçant** le contenu de `ReglagesEnfantPage` (photo, caméra, interface) et de `ProfilEnfantPage` (lecture) dans des sous-pages ; prévoir des alias pour `/compte/profils/:id` et `/tuteur/reglages` (routeur = coordinateur). Garder `/tuteur/foyer/ajouter-enfant` accessible par alias vers `/tuteur/foyer/ajouter`.
- Brancher la photo partout où un portrait élève apparaît (`ChildCard.urlAvatar`, `AvatarTile.urlSignee`).
- Photo : ajouter aperçu avant envoi, erreur avec reprise, et passer `contentType` ; aucune compression ni purge sans backend.
- Interface guidée : écran `.../interface` avec libellé « Interface guidée », explication neutre valable pour un adulte, bascule tuteur actuelle ; aucune demande enfant tant que B3 manque ; signaler B4 au coordinateur comme risque de sécurité à ne pas masquer par l'UI.
- Accès : afficher « expiré » quand `access_until < maintenant` (calcul d'affichage seulement, le serveur fait déjà foi), sinon « indisponible » pour statut et motif.
- « Pour moi / proche adulte / Créer mon profil élève » : écran honnête d'indisponibilité ou option absente, jamais un faux succès.
- Retirer de l'Accueil ce qui duplique le Foyer (bloc Accès, liens Appareils/Réglages) seulement quand le Foyer et la fiche les portent.

## 22. Tests existants du domaine (non exécutés dans cette phase)

`test/features/accueil_famille_test.dart` (706 l., phases, Assister, accès, vide), `appareils_test.dart` (211 l., limite, révocation, appairage), `compte_test.dart` (224 l., préférences locales en mémoire, profils, RTL 200 %), `reglages_enfant_test.dart` (416 l., trois colonnes, photo, demandes), `suivi_foyer_test.dart` (404 l.), `test/suivi/vue_suivi_foyer_test.dart` (351 l.), `dossier_test.dart` (338 l.). Aucun test ne couvre le titre de `ProfilEnfantPage`, l'affichage de la photo hors réglages, l'erreur de lecture des appareils, ni l'accès expiré. Côté SQL, `scenarios_etape4.sql:647-706` teste le tuteur (écriture autorisée, niveau refusé, autre foyer refusé) mais **pas** un élève qui écrirait ses propres réglages.
