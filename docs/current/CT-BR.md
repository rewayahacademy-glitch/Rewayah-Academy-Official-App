# CT-BR : cahier de tests du branchement BR-1 (notifications), à jouer sur STAGING

Statut de preuve : `spécifié` (ce document). Rien ici n'est `testé sur staging` ni `déployé`. Chaque ligne du § 6 se remplit le jour du jeu, avec sa preuve ; aucun `PASS` n'est inscrit d'avance.

Périmètre : la boîte privée de notifications, c'est-à-dire `NotificationsSupabase` (`lib/core/capacites/notifications_supabase.dart`), le résolveur de libellés (`lib/features/notifications/contenu_notification.dart`), la table `public.notifications` (migration 0063), ses producteurs (0086 et les déclencheurs des demandes, classes et remplacements) et les quatre pages de cloche. Hors périmètre : le reste de BR-1 (ports de la carte `docs/orchestration/BR1-CARTE-BRANCHEMENT.md`), qui aura son propre cahier.

## 0. Conditions pour jouer ce cahier

À réunir **avant** le premier contrôle. Sinon on s'arrête et on l'écrit, on ne joue pas à moitié.

1. **Environnement : staging uniquement** (`ENVIRONNEMENT=staging`, aperçu Vercel d'une branche, base de staging). Jamais la production, même en lecture seule, sans GO écrit du directeur. Jamais la clé `service_role` côté client ni dans les preuves.
2. **Code branché** : `NotificationsSupabase` câblé (BR-1 fusionné ou aperçu de la branche), **après** la correction de Codex sur b09 (doublon de déclencheur : une seule ligne par événement, voir contrôle P-3). Le SHA exact de l'aperçu est noté en tête de la fiche de preuve.
3. **Comptes de test de staging** (jamais de vrais comptes ni de vraies familles), un par ligne, créés par l'administration de staging :

| Clé | Rôle | Usage |
| :--- | :--- | :--- |
| `tuteur-A` | tuteur, foyer 1, avec un enfant élève | destinataire des événements de demande |
| `tuteur-B` | tuteur, foyer 2 | voisin : ne doit **rien** voir de A |
| `eleve-A` | élève du foyer 1 | pas de cloche (réponse Q5 du 04/10) |
| `enseignant-A` | enseignant | destinataire des remplacements |
| `enseignant-B` | enseignant | voisin |
| `controleur-A` | contrôleur | cloche sans événement attendu |
| `admin-A` | administration | crée les classes, affecte, valide |
| `suspendu` | tuteur dont `account_status` ≠ `active` | refus de compte |
| `en-attente` | compte en attente de validation | refus de compte |

4. **Outils de preuve** : navigateur (captures nommées), onglet réseau exporté sans en-têtes d'autorisation, et, côté base de staging, une lecture SQL **en lecture seule** par un compte de recette (jamais `service_role`). Aucune valeur de jeton, de clé ou de mot de passe n'entre dans une preuve.
5. **Zones interdites** : ce cahier ne modifie ni `supabase/`, ni les services, ni `*_supabase.dart`, ni `.github/`. Un écart trouvé se note ; il part chez Codex (serveur) ou chez l'auteur de l'écran.

## 1. Ce que le serveur doit faire (référence)

- Table `public.notifications` (0063) : `destinataire` (profil), `foyer_id`, `evenement` (6 valeurs), `params` (objet JSON, ≤ 8 Ko), `destination` (2 valeurs), `cree_le`, `lu_le`. RLS : lecture et accusé de lecture **seulement** par le destinataire et seulement si `app_account_valid()`. `UPDATE` limité à la colonne `lu_le`, que le serveur fixe lui-même (`notifications_accuse_serveur`). Aucun `INSERT` ni `DELETE` côté client. Aucun accès `anon`.
- Les 6 événements affichables : `demande_recue`, `classe_validee`, `enseignant_affecte`, `demande_close`, `remplacement_propose`, `remplacement_pris`. Le client refuse toute ligne dont l'événement est inconnu, dont les `params` ne sont pas un objet, ou dont la date est illisible.
- Destinations autorisées : `/tuteur/demandes` (famille) et `/enseignant/journee/remplacements` (enseignant). Le client n'ouvre jamais une autre destination.
- Texte : il vient **uniquement** de la table de traduction (`notifications.evenements.*`, fr et ar). Les `params` (état, début, motif) ne sont jamais recopiés à l'écran.

| Événement | Destinataire attendu | Destination | Producteur |
| :--- | :--- | :--- | :--- |
| `demande_recue` | tuteur principal du foyer de l'élève | `/tuteur/demandes` | insertion d'une demande d'horaire d'un enfant (0086) |
| `demande_close` | tuteur principal | `/tuteur/demandes` | état → `refusee` ou `retiree` (0086) |
| `classe_validee` | tuteur | `/tuteur/demandes` | création et validation de la classe (à confirmer, voir § 7) |
| `enseignant_affecte` | tuteur | `/tuteur/demandes` | affectation de l'enseignant à la classe (à confirmer) |
| `remplacement_propose` | enseignant remplaçant | `/enseignant/journee/remplacements` | proposition de remplacement (à confirmer) |
| `remplacement_pris` | enseignant d'origine ou famille, à confirmer | selon le producteur | remplacement accepté (à confirmer) |

Une demande d'**adulte** ne crée aucune notification de tuteur (scénario b09 : « adult requests must not create guardian notifications »).

## 2. Parcours par rôle

Chaque parcours se joue en français, puis en arabe (RTL), à 1440 px et à 390 px, texte ×1 puis ×2 sur le plus étroit. La langue et la taille ne changent aucune règle d'accès.

### 2.1 Tuteur (`tuteur-A`)

| # | Parcours | Résultat attendu |
| :--- | :--- | :--- |
| T-1 | Rien de nouveau : ouvrir la cloche (`/tuteur/notifications`) | état vide avec sa phrase, sans point sur la cloche, aucun bouton grisé |
| T-2 | `admin-A` ou l'élève crée une demande d'horaire pour l'enfant | une ligne `demande_recue`, titre et texte du fr, point sur la cloche, ligne non lue |
| T-3 | Ouvrir la ligne | le détail s'ouvre ; `lu_le` est fixé par le serveur ; le point disparaît ; la destination ouverte est `/tuteur/demandes` |
| T-4 | `admin-A` refuse la demande, puis une autre est retirée par la famille | une ligne `demande_close` chacune, texte sans genre, sans motif libre |
| T-5 | Classe validée, enseignant affecté | `classe_validee` puis `enseignant_affecte`, dans cet ordre, du plus récent au plus ancien en tête |
| T-6 | Rechargement de la page | mêmes lignes, même état lu ; aucune ligne dupliquée (voir P-3) |
| T-7 | Réseau coupé (mode hors ligne du navigateur) | le bandeau hors ligne seul, sans faux état vide ; au retour du réseau, « Réessayer » relit |
| T-8 | Coque `/compte` puis Ctrl/Cmd + K (si un domaine de recherche est servi) | sans lien avec la boîte : vérifie seulement que la cloche reste unique |

### 2.2 Enseignant (`enseignant-A`)

| # | Parcours | Résultat attendu |
| :--- | :--- | :--- |
| E-1 | Cloche (`/enseignant/notifications`) sans événement | vide, sans point |
| E-2 | Un remplacement lui est proposé | `remplacement_propose`, ouvre `/enseignant/journee/remplacements` |
| E-3 | Il accepte | `remplacement_pris` pour le destinataire prévu au § 1, aucune ligne en double |
| E-4 | Un événement de tuteur (`demande_recue`) est produit pour `tuteur-A` | `enseignant-A` ne le voit **pas** (ni liste, ni détail par l'identifiant) |

### 2.3 Contrôleur (`controleur-A`) et administration (`admin-A`)

| # | Parcours | Résultat attendu |
| :--- | :--- | :--- |
| C-1 | Cloche du contrôleur (`/controleur/notifications`) | aucun des 6 événements ne lui est destiné : état vide ou, si la page garde ses données de démonstration, à écrire comme écart (jamais de démonstration sur staging branché) |
| A-1 | Cloche de l'admin (`/admin/notifications`) | même constat que C-1 ; la page admin ne lit pas la boîte privée d'un autre profil |
| A-2 | Actions de l'admin qui produisent les événements (refus, validation, affectation) | les lignes apparaissent chez les destinataires, **pas** chez l'admin |

### 2.4 Élève (`eleve-A`)

| # | Parcours | Résultat attendu |
| :--- | :--- | :--- |
| L-1 | Parcourir les coques élève (standard et Interface guidée) | aucune cloche, aucune route de notifications ; l'ouverture directe de `/tuteur/notifications` est refusée par le routeur (page d'accès refusé, pas de données) |

## 3. Refus attendus

Pour chaque refus : le **refus est net** (aucun contenu, aucune donnée d'un autre, un message sans détail technique), et la **preuve** est la capture de l'écran, plus la réponse réseau (code et corps, sans en-têtes d'autorisation) ou le résultat SQL de recette.

| # | Cas | Action | Refus attendu | Preuve attendue |
| :--- | :--- | :--- | :--- | :--- |
| R-1 | **Anonyme** | ouvrir `/tuteur/notifications` sans session ; appeler la lecture de `notifications` avec la clé publique seule | le routeur renvoie à la connexion ; côté API : 401, ou liste vide sous RLS, **jamais** une ligne | capture de la redirection ; réponse réseau |
| R-2 | **Anonyme, écriture** | `INSERT`, `UPDATE`, `DELETE` sur `notifications` avec la clé publique seule | refusé (401 ou 403 ; aucune ligne modifiée) | réponse réseau + relecture SQL (comptage inchangé) |
| R-3 | **Rôle non autorisé, lecture** | `tuteur-B` lit les lignes de `tuteur-A` : liste, puis détail par l'identifiant d'une ligne de A | liste sans les lignes de A ; détail rendu `null` (aucune fuite, pas d'erreur qui confirme l'existence) | réponses réseau ; capture |
| R-4 | **Rôle non autorisé, accusé** | `enseignant-A` tente `UPDATE lu_le` sur une ligne de `tuteur-A` | 0 ligne modifiée ; la ligne de A reste non lue | relecture SQL de `lu_le` |
| R-5 | **Rôle non autorisé, écran** | `eleve-A`, `enseignant-A` ouvrent `/tuteur/notifications` ; `tuteur-A` ouvre `/enseignant/notifications`, `/controleur/notifications`, `/admin/notifications` | accès refusé par le routeur, sans contenu | captures |
| R-6 | **Rôle non autorisé, contenu** | tout client tente de modifier `evenement`, `params`, `destination`, `destinataire`, `cree_le` | refusé (droit de colonne) ; contenu inchangé | réponse réseau + relecture SQL |
| R-7 | **Suppression** | tout client tente `DELETE` | refusé | réponse réseau + relecture SQL |
| R-8 | **Compte suspendu** | `suspendu` se connecte (ou garde sa session ouverte) puis ouvre la cloche | la session est refusée ou ramenée à l'écran du statut de compte ; la lecture ne rend aucune ligne (`app_account_valid()` faux) ; l'accusé ne modifie rien | capture ; réponse réseau ; relecture SQL |
| R-9 | **Compte en attente** | `en-attente` ouvre la cloche | même refus que R-8 | idem |
| R-10 | **JWT expiré** | laisser la session expirer (ou invalider le jeton de recette), rouvrir la cloche, puis tenter l'accusé de lecture | le client renouvelle la session ou renvoie à la connexion ; la requête expirée reçoit 401 ; aucune ligne affichée à partir d'un cache ; aucun accusé enregistré | capture ; réponse réseau 401 ; relecture SQL |
| R-11 | **JWT d'un autre compte** | rejouer la requête de `tuteur-A` avec l'identifiant de destinataire de `tuteur-B` dans le filtre | le serveur ne rend que les lignes du porteur du jeton (le filtre client ne fait pas foi) | réponse réseau |
| R-12 | **Événement inconnu** | faire insérer par la base de recette (côté serveur uniquement) une ligne dont l'événement n'est pas dans la liste | la contrainte de la table la refuse ; si elle passait, le client la refuserait plutôt que d'afficher une clé brute | résultat SQL ; capture si affichée |
| R-13 | **Destination hors liste** | idem avec une destination non autorisée | refusée par la contrainte ; le client n'ouvre jamais un lien libre | résultat SQL |
| R-14 | **Paramètres hostiles** | `params` contenant du texte libre, un lien, un identifiant, du HTML | l'écran n'en montre rien (texte uniquement de la traduction) ; aucun lien cliquable créé | capture du détail |

## 4. Contrôles transverses

| # | Contrôle | Résultat attendu | Preuve |
| :--- | :--- | :--- | :--- |
| P-1 | **Isolement par foyer** : `tuteur-B` ne voit aucune ligne du foyer 1 ; `enseignant-B` aucune de `enseignant-A` | listes disjointes | deux captures + comptages SQL par destinataire |
| P-2 | **Atomicité** : l'événement naît dans la même transaction que le changement (demande, classe, remplacement). Faire échouer le changement (donnée invalide) | aucune ligne de notification orpheline | relecture SQL avant et après |
| P-3 | **Doublon de déclencheur (b09)** : un seul événement par fait | exactement **1** ligne par fait, pour chacun des 6 événements ; si 2, le branchement n'est pas validé | comptage SQL par (destinataire, évènement, instant) |
| P-4 | **Ordre et horodatage** : plusieurs faits à la suite | tri du plus récent au plus ancien ; `cree_le` croissant avec l'ordre des faits | capture + relecture SQL |
| P-5 | **Accusé idempotent** : ouvrir deux fois la même ligne | `lu_le` fixé à la première lecture, jamais déplacé | relecture SQL |
| P-6 | **Les 5 états** de la page : chargement, contenu, vide, erreur, hors ligne | chacun a son écran ; l'erreur propose « Réessayer » seulement quand la relecture est possible | cinq captures |
| P-7 | **Textes** : fr sans genre, deux-points précédés d'une espace insécable ; arabe relu par un arabophone | conforme aux gardes `ponctuation_fr` et `typographie_fr` ; **l'arabe reste à valider par un locuteur natif** (réserve ouverte de BR-1) | note de relecture signée |
| P-8 | **Aucune démonstration** : en staging branché, aucune donnée de démo dans les cloches | pas de fausse ligne, pas de mode démo sans le paramètre voulu | captures |
| P-9 | **Performance** : 200 lignes pour un destinataire | la liste s'affiche sans blocage visible ; la requête ne rend que le nécessaire (colonnes du `select`) | durée relevée + réponse réseau |
| P-10 | **Aucun secret** : les captures, journaux et exports de la recette ne contiennent ni jeton, ni clé, ni en-tête d'autorisation | zéro occurrence | relecture avant dépôt de la preuve |

## 5. Ordre de jeu conseillé

1. § 0 (conditions), puis P-3 seul sur un fait simple : si le doublon subsiste, on s'arrête là et on renvoie à Codex.
2. Refus R-1 à R-14 (ils ne dépendent d'aucun parcours).
3. Parcours T, E, C/A, L.
4. Transverses P-1, P-2, P-4 à P-10.
5. Remplir la fiche du § 6 et la déposer avec les captures nommées `CT-BR_<id>_<fr|ar>_<largeur>.png`.

## 6. Fiche de preuve (à remplir le jour du jeu)

En-tête : date, SHA de l'aperçu, base de staging utilisée, personne qui joue, personne qui relit (différente).

| Id | Résultat (`réussi` / `échec` / `non joué`) | Preuve (fichier ou capture) | Écart noté |
| :--- | :--- | :--- | :--- |
| P-3 | | | |
| R-1 … R-14 | | | |
| T-1 … T-8 | | | |
| E-1 … E-4 | | | |
| C-1, A-1, A-2 | | | |
| L-1 | | | |
| P-1, P-2, P-4 … P-10 | | | |

Règle de verdict : l'étape est **validée** seulement si tout est `réussi` ou `non joué` avec une raison écrite et acceptée par le directeur. Un seul `échec` en R-* ou P-1 à P-3 bloque le branchement (sécurité ou exactitude), quel que soit le reste.

## 7. Ce que ce cahier ne sait pas encore

- **Producteurs des quatre derniers événements** (`classe_validee`, `enseignant_affecte`, `remplacement_propose`, `remplacement_pris`) : lus dans les contraintes de la table, mais leur déclencheur et leur destinataire exacts sont à confirmer dans les migrations fusionnées de Codex. Les lignes « à confirmer » du § 1 se corrigent alors, et les parcours E-2 et E-3 avec elles.
- **Correction b09** : attendue de Codex ; tant qu'elle n'est pas fusionnée, ce cahier ne peut pas être joué (§ 0, point 2).
- **Pages cloche du contrôleur et de l'administration** : leur source de données au moment du branchement est à vérifier (C-1, A-1). Si elles lisent encore des données locales, l'écart se note et ne bloque pas les autres contrôles.
- **Arabe** : relu par un arabophone avant la validation (P-7).
- **Comptes de staging** : leur création est une action de l'administration de staging, hors de ce cahier.
