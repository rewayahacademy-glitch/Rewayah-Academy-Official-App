# CONTRACT_REQUEST_FABLE_CLASSROOM — ce que la Salle attend d'Astra

Agent Fable · lot 2 · branche `core24/fable-frontend`. Chaque demande dit ce que le frontend fait **aujourd'hui sans elle**, pour que rien ne soit bloqué en attendant. Ordre = priorité.

## 1. Persistance de l'état partagé : une ressource `library_resource` pour le Coran

- **Constat (base, 22/09, lecture seule)** : `session_shared_content.resource_id` est un `uuid not null references library_resource(id)` ; `library_resource` est **vide** ; la RPC `publier_etat_partage` existe ; le client identifie le Coran par la chaîne `identifiantRessourceCoran = 'quran:<code mushaf>'` (`lib/core/tc_coran/port_navigation_coran.dart`, « double local déclaré » depuis TC_CONTRACT_REQUEST_C).
- **Demandé** : (a) une ligne `library_resource` pour le Mushaf de Médine (type `quran`, capacités `pageable, searchable, zoomable, selectable, focusable, presentable_in_class, supports_offline`, politique d'accès `inscrits`), semée par migration ; (b) une manière **stable** pour le client de la retrouver sans coder l'uuid : soit une colonne `code text unique` (`'quran:madina-1405'`), soit une RPC `ressource_par_code(text)`.
- **Aujourd'hui** : `portEtatPartagePersistantProvider` reste `EtatPartageMemoire` (in-process). Le protocole voyage sur LiveKit ; un arrivant tardif dépend de la republication du pilote (décision D-L2-03). Dès (a)+(b), Fable écrit `EtatPartageSupabase` (`lire` = select par `session_id`, `enregistrer` = `publier_etat_partage`) et le branche dans `providers_tc_etat_partage.dart` ; aucun écran ne change.

## 2. `effacer` l'état partagé en fin de séance

- **Constat** : `PortEtatPartagePersistant.effacer(sessionId)` n'a aucune RPC ; la table n'a pas de policy `delete`.
- **Demandé** : RPC `effacer_etat_partage(p_session_id uuid)` réservée à l'enseignant de la séance (`session_belongs_to_teacher`) et à l'admin, ou un déclencheur sur `sessions.ended_at`.
- **Aujourd'hui** : rien n'est effacé (mémoire seulement).

## 3. Catalogue réel : `PortCatalogue` sur `library_resource`

- **Constat** : `portCatalogueProvider` = `CatalogueLocal()` vide en prod ; la Bibliothèque en classe ne montre que la carte « Présenter le Coran » (posée par Fable, indépendante du catalogue).
- **Demandé** : adaptateur Supabase de `PortCatalogue` (lecture `library_resource` + assignations par groupe + récents) — intégration Astra, hors frontière Fable.
- **Aujourd'hui** : seule surface présentable = le Coran.

## 4. Groupes réels : `PortGroupes` sur `mes_groupes_v`

- **Constat** : `portGroupesProvider` = `GroupesDemonstrationLocale` → l'Espace Groupe et `/tc/classe` via `routes_tc_a` montrent des groupes de **démonstration** en prod.
- **Demandé** : adaptateur Supabase de `PortGroupes` (`mesGroupes`, `groupe`) — déjà demandé en TC_CONTRACT_REQUEST_A §2.
- **Aujourd'hui** : la Salle réelle entre par `/salle` (billet) ; le billet porte `groupeId`/`libelleGroupe` seulement depuis la Journée enseignant (`mes_seances_enseignant_v`). Pour l'élève, le tuteur et le contrôleur, la séance n'a pas de groupe connu : pas d'outil « Révision » ni de section « Ce groupe ».

## 5. Séance → groupe pour les participants non enseignants

- **Constat** : `mes_seances_v` (élève, tuteur, contrôleur) ne porte ni `groupe_id` ni libellé ; `sessions.groupe_id` existe (`materialiser_seances_groupe`).
- **Demandé** : ajouter `groupe_id` et `groupe_libelle` à `mes_seances_v` (mêmes règles de visibilité), ou une vue `seance_groupe_v(session_id, groupe_id, libelle)` lisible par les participants.
- **Aujourd'hui** : en-tête « Cours en direct » + prénom de l'enseignant.

## 6. Rendu du masquage et du pointeur par le moteur Mushaf (Teaching Core C, pas backend)

- **Constat** : `outilsDisponibles` offre Masquer et Pointeur dès `peutPiloterSupport`, mais le renderer ne rend ni `hiddenRanges` ni `EvenementPointeur`. L'hôte de dock de Fable retire ces capacités pour ne pas offrir un geste sans effet (D-L2-06).
- **Demandé** : (a) en mode verset/focus, un verset dans `hiddenRanges` rendu comme bloc sémantique « verset masqué » (jamais une distribution artificielle des mots en mode page) ; (b) un pointeur éphémère dessiné sur l'ancrage `ContentPosition.ayah`. Lot renderer, pas Astra.
- **Aujourd'hui** : dock = Bibliothèque + Focus.

## 7. Observation tuteur par `/tc/observation` (rappel)

- Déjà documenté (mémoire 21/09, `entete_classe.dart`) : sans `0037`, la bascule d'« Assister » reste sur `assister_seance` → `/salle`. Inchangé par ce lot.
