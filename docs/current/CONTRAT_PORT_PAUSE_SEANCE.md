# CONTRAT_PORT_PAUSE_SEANCE : pause programmée d'une classe (LIVE-PAUSE-01)

Pour Codex 2 (backend). Décision F3 du directeur (27/09/2026) : l'enseignant programme à
l'avance une pause sur **sa** classe (la prière, par exemple) : à quel moment de la
séance, et combien de minutes. Le réglage vaut de séance en séance jusqu'à ce qu'il le
change. Le système dit si la pause a été prise ou non.

Statuts de preuve : **spécifié** (ce document) ; **présent dans le code** (port
`lib/core/pause_seance/port_pause_seance.dart`, démonstration en mémoire, écrans) ;
**testé localement** (tests Flutter) ; **testé sur staging : non** ; **déployé : non**.
En production, le port rend `CapaciteIndisponible('PAUSE-BR-01')` : l'écran le dit en
clair, aucune fausse bascule.

## 1. Réglage par classe (versionné)

Une ligne par classe. Valable pour toutes ses séances futures.

| Champ | Type | Règle |
| :--- | :--- | :--- |
| `groupe_id` | uuid | clé ; la classe |
| `actif` | bool | défaut `false` |
| `apres_minutes` | int | 5 à 120, pas de 5 : minutes après T0 (début de séance servi par l'horloge de séance) |
| `duree_minutes` | int | 5 à 30, pas de 5 |
| `version` | text/bigint opaque | change à chaque écriture ; rendue à la lecture |
| `peut_modifier` | bool | **calculé côté serveur** pour l'appelant ; jamais déduit d'un rôle par le client |

Bornes exactes reprises de `BornesPause` : le serveur les impose (CHECK), le client ne
fait que proposer des valeurs dans ces bornes (15/30/45/60/90 et 5/10/15/20/30).

### RPC souhaitées

- `pause_reglage_lire(p_groupe_id) → (actif, apres_minutes, duree_minutes, version, peut_modifier)`.
  Accessible à l'enseignant de la classe (modifie) et à l'administration (lit,
  `peut_modifier = false`). Tout autre appelant : refus.
- `pause_reglage_ecrire(p_groupe_id, p_actif, p_apres_minutes, p_duree_minutes,
  p_version_attendue, p_cle_idempotence) → même ligne.`
  - **Seul l'enseignant attitré de la classe** écrit. L'administration ne modifie pas.
  - `p_version_attendue` ne correspond plus → erreur typée `reglage_obsolete`
    (le client relit et le dit ; jamais d'écrasement silencieux).
  - Même `p_cle_idempotence` avec la même demande → même résultat, sans nouvelle version.
  - Valeurs hors bornes → erreur typée `valeur_invalide`.
  - Journal d'audit : qui, quand, ancienne et nouvelle valeur (sans donnée d'élève).

Un changement de réglage **n'agit pas sur les séances déjà commencées** : l'état d'une
séance (§2) fige `duree_prevue_minutes` et `debut_prevu_utc` au moment où la séance
démarre.

## 2. État de la pause d'une séance (événements horodatés par le serveur)

| Champ | Type | Règle |
| :--- | :--- | :--- |
| `seance_id` | uuid | clé |
| `statut` | enum | `non_prevue`, `programmee`, `en_cours`, `prise`, `non_prise` |
| `duree_prevue_minutes` | int | copie du réglage à T0 |
| `debut_prevu_utc` | timestamptz | T0 + `apres_minutes` (copie) |
| `debut_utc` | timestamptz | **horodaté par le serveur** au `demarrer` |
| `fin_utc` | timestamptz | **horodaté par le serveur** au `terminer` |
| `peut_piloter` | bool | calculé côté serveur : l'enseignant de la séance, séance en cours |

Transitions :

- `programmee → en_cours` (`demarrer`) ; `en_cours → prise` (`terminer`).
- Fin de séance sans `demarrer` → `non_prise` (le serveur la pose, jamais le client).
- `demarrer` pendant `en_cours`, ou `terminer` hors `en_cours` : sans effet, rend l'état
  courant (pas d'erreur bruyante). Une seule pause par séance.
- Pause encore `en_cours` à la fin de la séance : le serveur la clôt (`fin_utc` = fin de
  séance) et la compte `prise`.
- Aucune pause : `non_prevue` (réglage inactif ou classe sans réglage).

### RPC souhaitées

- `pause_seance_etat(p_seance_id) → état`. Enseignant de la séance et administration.
- `pause_seance_demarrer(p_seance_id, p_cle_idempotence) → état`
- `pause_seance_terminer(p_seance_id, p_cle_idempotence) → état`

Les deux écritures : enseignant attitré de la séance uniquement, séance en cours,
horodatage `now()` serveur (le client n'envoie jamais d'heure), idempotence par clé.

## 3. Droits

| Qui | Réglage | État de la pause |
| :--- | :--- | :--- |
| Enseignant attitré de la classe | lit, **modifie** | lit, démarre, termine |
| Administration | lit | lit |
| Élève, famille, tuteur, tout autre | refus | refus |

Rien côté famille dans ce lot. RLS sur toutes les tables ; fonctions `SECURITY DEFINER`
avec `search_path` figé ; capacités rendues au client, jamais un rôle.

## 4. Jamais une preuve de présence

La pause compte du **temps de séance**, pas une personne. Aucune colonne d'élève,
aucune heure d'entrée ni de sortie, aucun lien avec la présence, la ponctualité, la
facturation ou la paie. Ne rien en dériver côté serveur non plus.

## 5. Effet sur le chrono (côté client, pour mémoire)

Temps écoulé affiché = (maintenant − T0) − temps de pause. Temps restant = fin prévue −
maintenant, **inchangé** : la pause ne rallonge pas la séance (voir
`UX_REVIEW_LIVE-PAUSE-01.md`). Le client ne recalcule que depuis les horodatages UTC
servis (`debut_utc`, `fin_utc`).

## 6. Ce que le port Flutter attend

`PortPauseSeance` : `reglage`, `enregistrerReglage` (erreur `ReglagePauseObsolete`),
`etat`, `demarrer`, `terminer`. L'adaptateur `*_supabase.dart` associe `reglage_obsolete`
à `ReglagePauseObsolete`, toute autre erreur reste une erreur ordinaire (l'écran dit
« échec »). Tant que l'adaptateur n'est pas câblé, `PauseSeanceIndisponible`.
