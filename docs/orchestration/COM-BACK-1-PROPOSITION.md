# COM-BACK-1 — proposition de contrat serveur (V1)

Date : 2026-10-12
Branche : `codex/com-back-1-wip`
Statut : proposition documentaire, aucun schéma ni RPC appliqué.

## Sources de contrat examinées

- `lib/features/com_messages/port_messages_metier.dart` (`PortMessagesMetier`)
- `lib/features/com_annonces/port_annonces.dart` (`PortAnnonces`)
- `lib/features/com_communaute/port_communaute.dart` (`PortCommunaute`)
- `lib/core/communications/moderation.dart` (`PortModeration`)
- `lib/core/communications/port_pieces_jointes.dart`
- `lib/core/communications/modeles_communication.dart`

Cette proposition couvre les fils métier, les annonces de Classe, la
Communauté enseignants et la modération. Elle ne branche aucun adaptateur Dart
et ne modifie aucun comportement client.

## Principes de données

1. Le serveur dérive l'identité avec `auth.uid()`, vérifie `app_account_valid()`
   et recalcule les appartenances/capacités métier au moment de chaque appel.
   Un rôle, un destinataire ou un contexte transmis par le client n'accorde
   aucun droit.
2. Un fil métier est rattaché à une paire autorisée
   `(type_objet, objet_id, interlocuteur_id)`. L'ID d'un fil n'est jamais une
   autorisation. Une conversation refusée est absente (`null` dans le port).
3. Les mutations passent par des RPC transactionnelles et idempotentes. Les
   rôles SQL `authenticated` et `anon` n'obtiennent aucun droit direct
   d'insertion, de mise à jour ou de suppression sur les tables métier.
4. Toute fonction nouvelle `SECURITY DEFINER` aura `SET search_path = ''`,
   des noms de tables qualifiés, et un commentaire F86 `A_CALCULER` jusqu'au
   calcul d'empreinte. `EXECUTE` est accordé seulement aux appelants requis.
5. Les pièces jointes restent dans le stockage R2 existant. La base ne garde
   que leurs métadonnées et références opaques; les URL signées sont émises à
   la demande et ne sont jamais persistées dans le journal de messages.

## Tables proposées

| Table | Champs principaux | Invariants |
| --- | --- | --- |
| `communication_threads` | `id`, `type_objet`, `objet_id`, `cree_le`, `dernier_message_le` | Un seul fil canonique par objet et interlocuteur; types limités au contrat `TypeObjetLie`; aucune création par écriture directe. |
| `communication_thread_members` | `thread_id`, `profile_id`, `ajoute_le`, `retire_le`, `dernier_lu_le` | PK `(thread_id, profile_id)`; appartenance créée par RPC après validation serveur; les retraits n'effacent pas l'historique. |
| `communication_messages` | `id`, `thread_id`, `auteur_id`, `texte`, `envoye_le`, `cle_idempotence` | Append-only; unicité `(auteur_id, cle_idempotence)`; auteur fixé par `auth.uid()`; index `(thread_id, envoye_le, id)`. |
| `communication_message_attachments` | `id`, `message_id`, `nature`, `nom_affiche`, `taille`, `mime`, `empreinte`, `cle_stockage` | Métadonnées validées côté serveur; clé privée jamais rendue; suppression logique selon la politique de rétention. |
| `class_announcements` | `id`, `classe_id`, `auteur_id`, `titre`, `texte`, `publie_le`, `programme_le`, `etat`, `cle_idempotence` | Audience créée depuis les cibles métier permises; publication idempotente; auteur et portée fixés côté serveur. |
| `class_announcement_recipients` | `annonce_id`, `profile_id`, `lu_le` | PK `(annonce_id, profile_id)`; l'état de lecture est par destinataire et n'est jamais partagé avec les autres membres. |
| `community_categories` | `id`, `libelle`, `ordre`, `active` | Lecture par personnes admissibles à la communauté; changements limités à l'administration autorisée. |
| `community_publications` | `id`, `auteur_id`, `categorie_id`, `titre`, `texte`, `etat`, `cree_le`, `publie_le` | Écriture de l'auteur par RPC; visibilité publique seulement dans l'état publié et pour une personne actuellement admissible. |
| `community_replies` | `id`, `publication_id`, `auteur_id`, `texte`, `etat`, `cree_le`, `cle_idempotence` | Append-only; unicité `(auteur_id, cle_idempotence)`; refus si la publication est masquée/fermée. |
| `community_reports` | `id`, `objet_type`, `objet_id`, `auteur_signalement_id`, `motif`, `precision`, `etat`, `cree_le`, `cle_idempotence` | Un seul signalement par personne/objet; texte de précision borné et nettoyé; aucun extrait privé exposé à la file sans capacité. |
| `community_moderation_events` | `id`, `report_id`, `moderateur_id`, `action`, `motif_interne`, `cree_le` | Journal append-only; la mutation de visibilité du contenu et son événement sont atomiques. |

Les états stockés sont des valeurs fermées correspondant aux enums Dart. Les
contraintes CHECK, clés étrangères et index uniques doivent porter les
invariants indépendamment de l'interface.

## RPC proposées, alignées sur les ports

### Messages métier — `PortMessagesMetier` / COM-BR-01 et COM-BR-02

- `communication_lister_fils()` : rend uniquement les fils encore lisibles,
  du plus récent au plus ancien, avec contexte, participants autorisés,
  dernier message et attention.
- `communication_lire_fil(p_fil_id)` : rend le fil et ses messages paginés;
  renvoie `null` pour absent et non autorisé sans révéler lequel.
- `communication_fil_pour_objet(p_type, p_objet_id)` : résout/crée le fil
  canonique après validation de la paire.
- `communication_ouvrir_conversation(p_type, p_objet_id,
  p_interlocuteur_id)` : valide une paire de `ConversationPossible`; le serveur
  décide si elle existe et quels membres y participent.
- `communication_conversations_pour_objet(p_type, p_objet_id)` : rend
  seulement les interlocuteurs ouverts par le contrat courant.
- `communication_marquer_lu(p_fil_id)` : met à jour le marqueur individuel
  après vérification de l'appartenance actuelle.
- `communication_envoyer(p_fil_id, p_texte, p_cle_idempotence,
  p_pieces_jointes)` : contrôle longueur, capacité d'écriture, pièces jointes,
  idempotence et appartenance dans la même transaction; rend l'accusé serveur.

### Annonces de Classe — `PortAnnonces` / COM-BR-10

- `annonces_classe_lister(p_classe_id)` et
  `annonce_classe_lire(p_annonce_id)` : filtres d'audience et d'accès recalculés
  côté serveur; incluent le marqueur lu du seul appelant.
- `annonce_classe_marquer_lue(p_annonce_id)` : mutation du reçu individuel.
- `annonces_cibles_publication(p_classe_id)` : produit la liste fermée des
  cibles visibles à l'appelant; l'ID de cible envoyé ensuite est revalidé.
- `annonce_classe_publier(p_brouillon, p_cle_idempotence)` : valide contenu,
  audience, capacité et fenêtre de programmation, crée l'annonce et les reçus
  dans une transaction, puis rend `AnnonceConfirmee`.
- `annonces_administration_lister()` : projection autorisée des annonces
  publiées et programmées; aucun accès général à la table.

### Communauté enseignants — `PortCommunaute` / COM-BR-05

- `communaute_capacites()` : seules les capacités utiles aux écrans sont
  rendues; elles sont informatives, et chaque mutation répète son contrôle.
- `communaute_categories()` et `communaute_lister_publications(p_categorie,
  p_recherche)` : ne rendent que le contenu actuellement visible; le filtre
  local n'élargit jamais l'accès.
- `communaute_lire_publication(p_id)` et
  `communaute_lister_reponses(p_publication_id)` : les éléments retirés,
  masqués ou non autorisés sont absents.
- `communaute_publier(p_brouillon, p_cle_idempotence)` et
  `communaute_repondre(p_publication_id, p_texte, p_cle_idempotence)` :
  identité auteur du JWT, limites de contenu, capacité et idempotence
  contrôlées côté serveur.

### Modération — `PortModeration` / COM-BR-06

- `communication_moderation_capacites()` : actions permises et capacité de
  signaler pour l'appelant.
- `communication_signaler(p_objet_type, p_objet_id, p_motif,
  p_precision, p_cle_idempotence)` : déduplication et réponse
  `enregistre`/`dejaSignale`.
- `communication_mes_signalements()` : projection de l'appelant seulement.
- `communication_file_moderation()` : file réservée à la capacité serveur;
  chaque extrait est filtré selon les règles de confidentialité.
- `communication_moderation_appliquer(p_signalement_id, p_action)` :
  vérification de capacité, transition d'état permise et journal append-only
  dans une seule transaction. Aucune sanction automatique de compte n'est
  incluse.

## RLS, privilèges et transitions

- Activer RLS sur chaque table. Les politiques de lecture appellent des
  prédicats serveur étroits (`app_account_valid()` et une fonction
  d'appartenance/capacité propre à la ressource); aucune policy basée sur un
  `user_id` fourni par le client.
- Accorder les `SELECT` nécessaires aux projections autorisées seulement.
  Révoquer les mutations directes de `PUBLIC`, `anon` et `authenticated`; les
  RPC écrivent en propriétaire contrôlé avec `search_path` vide.
- Les fonctions de vérification d'accès ne prennent pas uniquement un UUID de
  fil pour faire confiance à une appartenance périmée : elles revalident le
  lien avec la classe, le dossier, le foyer ou la mission selon le type.
- Les tables de messages, reçus et événements de modération sont append-only
  ou à mises à jour très ciblées; aucun effacement d'historique par client.
- Les notifications réutilisent le stockage et les règles de destinataire du
  lot B-09 après cartographie de la table existante; COM-BACK-1 ne crée pas une
  seconde table de notifications.

## Décisions métier à verrouiller avant les migrations

1. Le contrat `PortAnnonces` ne précise pas les délais maximaux de
   programmation, ni le fuseau/règle de publication. Le serveur doit reprendre
   une règle déjà approuvée ou obtenir une décision avant d'inventer ces bornes.
2. Les enums donnent les actions de modération, mais pas les rôles exacts qui
   les reçoivent, le délai de traitement, ni la politique d'appel. À définir
   avant d'ouvrir la file.
3. Définir les plafonds texte, pièces jointes, conservation et suppression
   légale, ainsi que les règles d'édition/suppression d'un message ou d'une
   publication après envoi.
4. Confirmer les audiences et destinataires d'annonces (notamment tuteurs,
   élèves et nouveaux membres) à partir du contrat d'accès aux Classes.
5. Cartographier le schéma et les déclencheurs du lot Notifications B-09 avant
   de choisir ses points d'insertion; ne pas dupliquer ses journalisations.
6. Définir les familles R2, métadonnées, limites et signaux de révocation des
   pièces jointes à partir de `PortPiecesJointes` et des règles de stockage
   déjà acceptées.

## Séquence de livraison proposée

1. Valider les décisions métier ci-dessus et les références exactes des
   politiques existantes.
2. Livrer les migrations noyau (fils, membres, messages, idempotence, RLS,
   postflights F86) et scénarios négatifs avant les adaptateurs.
3. Ajouter les RPC et scénarios métier messages, annonces, communauté et
   modération par lots isolés, chacun avec une branche et des preuves séparées.
4. Brancher les adaptateurs `*_supabase.dart` sur les ports existants; garder
   le comportement « indisponible » tant que le serveur n'est pas validé.
5. Rejouer une base PostgreSQL neuve, les scénarios d'accès/refus et les
   contrats Dart. Aucun résultat STAGING/PROD n'est implicite dans cette
   proposition.
