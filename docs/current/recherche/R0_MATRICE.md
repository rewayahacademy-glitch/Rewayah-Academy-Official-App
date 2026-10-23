# RECH-0 / R0 : inventaire de la recherche et revue des sept maquettes

Fiche RECH-0, voie RECH. Lecture seule : aucun code, aucune table. Source des exigences :
`REWAYAH_RECH_03_SPEC_CANONIQUE_FRONT_BACK_SECURITE_PERFORMANCE_V3.md` (branche
`docs/specs-entrantes-2026-10-10` @ db050205, `docs/entrants/2026-10-10/rech/`), notée « spec §n ».
Sept maquettes : `rech/maquettes/IMG-RECH-01-M` à `07-T` (références statiques non validées, spec §11).

Statuts de preuve employés : `spécifié`, `présent dans le code`, `testé localement`, `testé sur staging`,
`déployé`. Rien n'est `testé sur staging` ni `déployé` ici : aucun accès à staging n'a été utilisé.

## 1. Constat de départ

| Point | Constat (10/10/2026) |
| :--- | :--- |
| Ligne de travail | branche `claude/recherche` partie de `origin/ccr-1b1bfa0b-m1kvkk` @ 744dac49 (fusion EA-ECRANS) |
| Port de recherche transversal | **Aucun** : ni `PortRecherche`, ni `rechercheGlobale`, ni route `/recherche` dans `lib/` (`grep -ri "PortRecherche\|rechercheGlobale"` vide). Tout est à créer. |
| Recherches existantes (propriétaires de leur domaine, à ne pas dupliquer) | `lib/core/tc_bibliotheque/recherche_catalogue.dart` (supports, fonctions pures, `PortCatalogue.rechercher`) ; `lib/features/com_messages/recherche_fils.dart` (fils, texte du fil seulement) ; `lib/features/com_studio/recherche_studio.dart` ; `lib/features/com_communaute/flux_publications.dart` ; champs de liste admin (`admin_groupes`, `admin_regroupements`, `admin_tirage`, `admin_observations/annuaire_observations.dart`, `comptable/encaissements`) |
| Composants partagés de recherche | `lib/core/widgets/champ_recherche.dart` (champ, effacer, étiquette dehors à 320 px) et `surface_recherche.dart` (recherche plein écran du téléphone) : **réutilisés**, jamais recréés (spec §11 « champ de recherche partagé ») |
| Route canonique | À choisir : une seule route **commune** `/recherche`, hors préfixes de rôle, dans le même bloc que `/compte` (`redirection.dart`, « espace commun »), enveloppée par `_CoquilleSecondaire` (chrome du rôle). Aucune route n'existe déjà. |
| Capacité d'espace | Un adulte autonome reste `AppRole.guardian` avec `SessionState.eleveAutonome` (C-24, EA-ROLE-1 fusionné) : le contexte de recherche se dérive de capacités, jamais d'une étiquette de rôle (spec §1, §2). |
| Migrations | `supabase/migrations/` : 0001 à 0048 présentes, **0039 à 0043 sont dans le dépôt** (la spec §17 les croyait absentes) ; 0044 à 0048 s'ajoutent (RPC admin et KYC sécurisées, agent, révocation d'exécution). Seul `0030_tc_socle.sql` mentionne `pg_trgm` / `texte_recherche`. Aucun objet SQL de recherche transversale n'existe. Lecture seule : rien touché. |
| Environnement serveur | Non consulté (hors périmètre front, zone ChatGPT K-68). Aucun accès staging ni production. |
| Worktrees | `/home/user/Rewayah-Academy-Official-App` (cette branche) et `/tmp/base_wt` (base détachée, outil de comparaison). |
| Fiches liées | CAP29-0 `en_cours` (autre session, `claude/bibliotheque`, non fusionné) : le corpus « supports » de RECH-D1 se lit donc sur `PortCatalogue` existant. RECH-D4 `a_faire` (attend CPT-COM, COM-FUS). RECH-D2 : `attend` Immatriculation, non levé. |

## 2. Matrice exigence → source → état du code → serveur → preuve → bloqueur

Légende serveur : `—` rien d'existant ; `à écrire (Codex)` : adaptateur `*_supabase.dart` et RPC de
recherche, zone ChatGPT (K-68), ligne Contrats ouverte par RECH-1.

| # | Exigence | Source | État du code (front) | Serveur | Preuve visée | Bloqueur |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Une seule surface de recherche, route canonique unique, entrée par loupe contextualisée | §1, §4.1, §9 | rien (route absente) ; `/compte` donne le patron de route commune | — | route `/recherche` + test de redirection par rôle ; RECH-D5 pour la loupe | Entrée dans les coques réservée à RECH-D5 (coques partagées) |
| 2 | Capacités de recherche : `availableSearchScopes` ne rend que les domaines autorisés, aucun domaine « désactivé » nommé | §8.1, §13.3 | à créer : `PortRecherche.portees` | à écrire (Codex) | test : domaine absent du résultat, jamais grisé | — |
| 3 | `searchDomain(domain, query, context, filters, cursor, limit)` ; `items` en liste blanche ; `target.kind` borné | §8.2 | à créer : DTO, `CibleRecherche` à `kind` fermé | à écrire (Codex) | tests DTO (champ inconnu ignoré, jamais sérialisé) | — |
| 4 | États contractuels `ok`, `temporarily_unavailable`, `timeout`, `rate_limited`, `session_expired`, `context_revoked`, `invalid_query`, `stale_cursor` ; vide confirmé = `ok` + `items=[]` seulement | §0.2, §5, §13.3 | à créer : `StatutRecherche` | à écrire (Codex) | un test par statut → un texte, jamais « aucun résultat » | — |
| 5 | Agrégateur à retours partiels, 3 domaines à la fois, 5 éléments par domaine, un domaine lent ne bloque pas | §6.2, §8.3, §13.1 | à créer | à écrire (Codex) | test : domaine lent + domaine rapide, rendu partiel | — |
| 6 | Machine d'états `idle→input→debounce→loading→partial|success|empty|error|timeout`, jeton de génération, annulation | §5 (transitions) | à créer : contrôleur Riverpod | — | tests : réponse tardive ignorée (SEC-R05) | — |
| 7 | Garde-fous client : debounce 250 ms, 3 caractères min, 160 max, 8 termes, rien sans saisie, timeout 3 s, lenteur à 2 s | §6.2, §13.3 | à créer ; budgets en constantes nommées | — | tests de bornes | Valeurs « proposées, non mesurées » : à recetter (§6.2) |
| 8 | Pagination par curseur opaque, 20 par page, plafond 50, pas de total spéculatif, « Voir davantage » | §6.2, §8.2 | à créer | à écrire (Codex) | tests : curseur d'un autre contexte rejeté côté client, aucun compteur total | — |
| 9 | Pas d'exploration locale : aucun filtre local d'un corpus complet comme « recherche » | §6.1 | `RechercheCatalogue.filtrer` existe pour un catalogue déjà chargé (usage Bibliothèque) ; ne pas l'élever en recherche transversale | — | test : la surface ne charge aucune liste complète | — |
| 10 | Purge au déconnexion, changement de compte, changement d'espace, révocation (SEC-R07, R08, REC-07) | §7.3, §13.4 | à créer : le contrôleur écoute `sessionProvider` | — | test : A → B vide résultats, curseur, requêtes en cours | — |
| 11 | Aucun cache partagé ni historique de requêtes persistant ; aucune requête dans l'URL, les logs, la télémétrie | §7.3, §13.4, SEC-R20 | à créer : requête en mémoire d'écran seulement ; `observabilite` à vérifier (aucun appel) | — | test : la requête ne figure dans aucune route ni trace | — |
| 12 | Textes UI exacts FR (tableau §5), pluriels, AR/RTL, RA/EV en LTR | §4.6, §5 | à créer : clés `recherche.*` fr + ar (complétude ar exigée par `test/i18n/ar_domaines_test.dart`) | — | tests i18n + RTL | Pluriels exacts : à confirmer en RECH-2 |
| 13 | Surlignage échappé (jamais HTML ni `ts_headline` brut) | §7.2 SEC-R11 | à créer : segmentation texte pur | — | test : `<b>` dans le titre rendu littéral | — |
| 14 | Aucune action d'écriture depuis un résultat ; navigation vers l'écran canonique | §4.1, §9 | à créer : résultat = lien seulement, route de la liste blanche | — | test : aucun bouton d'action métier ; cible sans route non cliquable | — |
| 15 | Ouverture réautorisée : « Cet élément n'est plus accessible. » | §5, §13.1 | à créer | à écrire (Codex) | test `denied_stale` | — |
| 16 | Recherche contextuelle d'abord (Bibliothèque, Espace Classe) ; domaines classes et supports | §3, §6.1 4, §15 D1 | supports : `PortCatalogue.rechercher` présent ; classes : `PortClassesFoyer`, `PortCatalogueClasses` (catalogue sans source serveur) | à écrire (Codex) | RECH-D1 sur démo | CAP29-0 non fusionné : on lit le port existant |
| 17 | Familles / élèves, RA exact non énumérable, homonymes, second adulte, aucun cross-foyer | §3, §7.2, §15 D2 | rien | à écrire ; **Immatriculation / R3 non livrée** | RECH-D2 | `attend` Immatriculation, **non pris** |
| 18 | Enseignants, remplaçants, pédagogie, contrôle ; mission expirée refuse ; aucun champ privé matchable | §2, §3, §15 D3 | `PortRemplacements` (`lib/core/enseignant`), `PortTirageControle`, ports classes enseignant ; pas de recherche | à écrire (Codex) | RECH-D3 sur démo | — |
| 19 | Finance FI/CPT, fils COM/Studio sans corps de message | §3, §12, §15 D4 | recherche des fils déjà propre à COM ; finance : rien de transversal | à écrire | RECH-D4 | CPT-COM et COM-FUS non clos |
| 20 | Entrée universelle dans les coques, Ctrl/Cmd+K, tablette, Interface guidée | §4.1 à 4.5, §15 D5 | rien ; coques `NavShell`, `AdminShell`, `_CoquilleSecondaire` | — | RECH-D5 | Fichiers de coques réservés ; dépend de D2 et D4 |
| 21 | Aucune donnée d'un rôle non autorisé, même en démo | §2, §10.3 | à créer : démo filtrée par contexte | — | test par espace (famille, élève guidé, enseignant, contrôleur, comptable, admin) | — |
| 22 | Mode démonstration : aucun endpoint de production, démo identifiée | §10.3 | `environnementAutoriseDemo` existe (`features/demo/mode_demonstration.dart`) | — | test : en production le port retombe sur `Indisponible` | — |
| 23 | Performance serveur (p95 SQL 150 ms, API 400 ms, index, plans, charge) | §6.3, §10.2, §13 | hors front | à écrire (Codex), staging synthétique | Gates D, E : **non faisables par ce lot** | R1 baseline staging, R2 sécurité commune |
| 24 | Sécurité serveur SEC-R01 à R22, REC-01 à REC-14 | §7, §14 | côté front : DTO liste blanche, purge, génération ; reste serveur | à écrire (Codex) | tests front listés §4 ci-dessous | R2 |
| 25 | Libellés « Classe », jamais « groupe » ; zéro emoji ni tiret long ; jetons gelés, aucune couleur nouvelle | `lib/CLAUDE.md` | à respecter | — | `verifier_jetons` ≤ 18, `verifier_revue` | — |

## 3. Routes, ports, permissions : constat utile aux lots suivants

- **Route** : `Routes.recherche = '/recherche'`, commune. `redirection.dart` : bloc « espace commun »
  (même traitement que `/compte`), uniquement pour `PorteAcces.actif`. Pas de `/recherche` public
  (K-64) : un visiteur est renvoyé à la connexion par la règle générale.
- **Coque** : `_CoquilleSecondaire` (app_router) lit le rôle pour le chrome seulement. La page lit une
  capacité (`capacitesRechercheProvider`), jamais le rôle.
- **Bibliothèque** : `PortCatalogue` (`tous`, `recents`, `pourGroupe`, `parId`, `rechercher`,
  `derniereLecture`), `LibraryResource` (titre, type, langue, catégorie, politique d'accès).
  `/tc/bibliotheque` est ouvert à l'élève et au tuteur ; l'enseignant y accède par le dock en salle.
- **Classes** : `PortClassesFoyer` (classes des enfants), `PortCatalogueClasses` (sans source
  serveur, `CatalogueClassesIndisponible`), `ClasseListee` (admin).
- **Enseignants et contrôle** : `PortRemplacements` (C-09), `PortTirageControle` (C-29).
- **Capacité d'espace** : `sessionProvider` (`role`, `eleveAutonome`, `interfaceMode`,
  `peutVoirDirection`) ; l'espace se déduit dans UN provider, pas dans l'écran.
- **Contrats** : C-24 (capacité élève autonome) est la dernière ligne vue ; les lignes de recherche
  s'ajoutent après (RECH-1).

## 4. Tests de sécurité côté front (à écrire en RECH-1 à RECH-D3)

SEC-R05 (réponse tardive), SEC-R07 / R08 (purge compte et espace), SEC-R09 (aucun total, aucune
facette globale), SEC-R10 (DTO liste blanche), SEC-R11 (texte hostile), SEC-R12 (cible hors liste
blanche non cliquable), SEC-R17 (limite de requêtes côté client), SEC-R18 (hors ligne : pas de
résultat périmé), SEC-R20 (aucune requête dans l'URL ni la trace), SEC-R21 (bornes de saisie).
Le reste (R01 à R04, R06, R13 à R16, R19, R22) est **serveur** : le front ne peut que ne rien
supposer ; il reste `bloqué` jusqu'aux adaptateurs de Codex.

## 5. Revue des sept maquettes (quatre regards)

Limite assumée : le lot RECH-0 est en lecture seule et aucune capture de l'écran réel n'existe
(l'écran n'existe pas). La comparaison porte sur les **composants et jetons réels du dépôt**
(`champ_recherche.dart`, `surface_recherche.dart`, `filter_pill.dart` / `rangee_filtres.dart`,
`carte_groupee.dart`, `avatar_tile.dart`, `empty_state.dart`, `skeleton.dart`, `selecteur_section.dart`,
thème `app_palette.dart`). Les captures Flutter réelles à 390, 768, 1440 et 320 px sont produites en
RECH-2 et comparées aux sept PNG dans `docs/current/recherche/UX_REVIEW_RECH-2.md`.

| Maquette | Produit | Sécurité | UX | Performance |
| :--- | :--- | :--- | :--- | :--- |
| 01-M famille (390) | Sections « Mes classes » puis « Supports », pied « limités aux éléments autorisés dans votre foyer » : cohérent avec §2. Ajouter à la carte enseignant la photo publique seulement si la carte réelle la porte. | Aucun profil étranger ; pas de nom d'enfant ailleurs que dans « Classe de Mariam » (donnée du foyer lui-même). Le libellé « Voir tout » n'apparaît que pour un domaine autorisé et branché (§4.1). | Barre basse Accueil · Foyer · Historique · Compte conservée : à respecter. Puces « Tout / Mes classes / Supports » : `RangeeFiltres` + `FilterPill` (jamais `Wrap`). Titre « Recherche » vs surface « Rechercher » : texte §5 prime. | 5 éléments par domaine au premier écran ; « Voir tout » = curseur, aucun total. |
| 02-M guidée (390) | « Trouver un support » (§4.5), 2 grosses lignes, aide audio : conforme. | Seulement ses supports et ses leçons ; aucun annuaire, aucune finance : le domaine se déduit de la capacité, pas de l'Interface guidée. | Pied « Retour à ma classe » = un seul bouton plein (K-56). « Écouter l'aide » : composant d'aide audio existant (`AudioLabel`), pas un nouveau bouton. Cibles 72 (MA-NAV-1). | Peu de résultats visibles ; pas de filtre technique. |
| 03-D enseignant sombre (1440) | Mes classes, Mes élèves, Supports + encart « Informations pédagogiques seulement » : conforme à §2 (projection pédagogique). | Élèves : projection de classe seulement ; remplaçant expiré refusé (serveur). Encart de confidentialité = texte statique, sans compteur masqué (SEC-R09 : jamais « X résultats masqués »). | Deux colonnes, pas un dashboard décoratif : l'encart de droite est du texte, à garder discret. Navigation maquette « Aujourd'hui, Mes classes, Bibliothèque, Messages, Compte » : **à reprendre de `destinationsPour`**, pas de la maquette. | Domaines en parallèle, plafonnés à 3. |
| 04-D admin clair (1440) | « Classes autorisées », « Actions disponibles », « Personnes dans votre périmètre » : « Actions disponibles » est une **navigation** statique (§1 intention 3), jamais une commande métier ; à vérifier chaque lien contre une route réelle. Intitulés de menu à reprendre de `domainesAdmin`. | Pas de KYC ni de pièce dans la recherche commune (§3) ; « Matricule non exposé sans nécessité » : RA seulement en recherche exacte (D2, bloquée). CPT-Q1 non résolu : aucune lecture automatique Direction de la finance. | Puce « Période : Toutes » = filtre de domaine propriétaire, à n'afficher que s'il est servi. « Tous les domaines autorisés » : liste servie par `portees`, jamais codée. | Chaque puce de domaine = requête bornée, pas un fan-out silencieux. |
| 05-D comptable clair (1440) | Table Référence / Objet / Date / État, sans action de paiement : conforme. **Domaine finance = RECH-D4**, hors de ce lot ; la maquette sert de cible. | Montants, bénéficiaires, coordonnées uniquement selon capacité (§3 Finance) ; aucun montant simulé présenté comme réel ; pastilles d'état avec texte (pas la couleur seule). | Table en `DataCollection` / `CarteLignes`, pas une table recomposée ; cartes collées interdites (K-55). | Références exactes : B-tree côté serveur ; pas de total. |
| 06-M états (planche) | Six états : chargement, vide, hors ligne, domaine en panne, délai, accès retiré. **Manquent** dans la planche : « Session expirée », « Requête trop courte », « Domaine non raccordé », « Filtre vide », « Chargement de page suivante », « Erreur globale » (§5). | « Accès retiré » ne dit rien de l'objet ; le message de bas de planche (« aucun état de panne… traduit par Aucun résultat ») est la règle `ok + []` seulement. | Boutons : texte « Réessayer », « Modifier la recherche », « Réessayer ce domaine », « Retour aux résultats » (§5) ; jamais grisés ; une seule action pleine (K-56). Utiliser `EmptyState` / `EtatSysteme` existants. | Pas de spinner sans fin : sortie d'état à 2 s puis timeout à 3 s. |
| 07-T tablette Classe (1024×768) | Tiroir « Bibliothèque » dans la salle : « Consulter sans partager » (l'enseignant reste maître). Le rectangle « Support coranique » n'est **pas** un Muṣḥaf : ne pas le reproduire (rendu du Coran interdit). | Une lecture individuelle ne change pas le support présenté ; l'élève n'obtient aucune commande professorale. | Salle (`salle`, `tc_classe_live`, `tc_dock`) : **fichiers réservés** ; RECH-D1 ne livre que le panneau de recherche, pas son branchement dans la salle sans fiche qui le nomme. | Recherche contextuelle de la Classe, pas de fan-out. |

Écarts à écrire en RECH-2 (déjà identifiables) : navigation des maquettes (à reprendre du code),
puces de filtre (servies par le port), états manquants de la planche 06, absence de texte ×2 et
d'arabe dans toutes les maquettes, matricule LTR en interface arabe (§4.6), aucune maquette de
tablette hors Classe, aucune maquette Contrôle ni élève adulte.

## 6. Restes et décisions à porter

1. **Pas de serveur** : toute l'activation réelle est derrière les lignes Contrats (RECH-1) ; en
   production le port est neutre (`Indisponible`) et la page dit « Recherche indisponible pour le moment. ».
2. RECH-D2 reste en attente de l'Immatriculation (`attend`) ; RECH-D4 de CPT-COM et COM-FUS.
3. Captures Flutter réelles : RECH-2 (cette fiche n'en a pas, l'écran n'existe pas).
4. Gates D (performance) et E (release) : non atteignables sans staging ; hors de ce lot.
