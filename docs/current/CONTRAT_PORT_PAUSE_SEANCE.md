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
| `actif` | bool | défaut de colonne `false` ; **une classe sans ligne reçoit la pause par défaut** (§7) |
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
| `proposer_a` | timestamptz | PAUSE-SERVEUR (§7) : quand la barre du chrono propose la pause ; nul s'il n'y a plus de proposition |
| `refus_nombre` | int | PAUSE-SERVEUR : nombre de Non |
| `motif` | text | PAUSE-SERVEUR : nul (ordinaire) ou `priere` (pause prévue par le serveur) |

Transitions :

- `programmee → en_cours` (`demarrer`) ; `en_cours → prise` (`terminer`).
- Fin de séance sans `demarrer` → `non_prise` (le serveur la pose, jamais le client).
- `demarrer` pendant `en_cours`, ou `terminer` hors `en_cours` : sans effet, rend l'état
  courant (pas d'erreur bruyante). Une seule pause par séance.
- Pause encore `en_cours` à la fin de la séance : le serveur la clôt (`fin_utc` = fin de
  séance) et la compte `prise`.
- Aucune pause : `non_prevue` (réglage inactif, durée par défaut réglée à 0, ou pause par
  défaut qui ne tient pas dans la séance). Depuis PAUSE-SERVEUR, une classe sans réglage
  n'est plus `non_prevue` par défaut (§7).

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
`etat`, `demarrer`, `terminer`, `refuser` (PAUSE-SERVEUR). `PauseSeance` porte en plus
`proposerAUtc`, `refusNombre` et `motif` (`MotifPause.ordinaire` / `priere`, valeur
inconnue lue `ordinaire`). L'adaptateur `*_supabase.dart` associe `reglage_obsolete`
à `ReglagePauseObsolete`, toute autre erreur reste une erreur ordinaire (l'écran dit
« échec »). Tant que l'adaptateur n'est pas câblé, `PauseSeanceIndisponible`.

## 7. La pause proposée (PAUSE-SERVEUR, directeur, 12/11/2026)

Demande du directeur : « La pause de 10 est un réglage, il faut permettre à l'enseignant
de la gérer lui-même ; par défaut, le système active automatiquement la pause juste après
le milieu de la session ; pour une classe d'adultes, à 45 min, la barre du chrono propose
à l'enseignant de prendre une pause de 10 min ; il accepte par un simple OUI ou refuse par
NON ; s'il accepte, tous les participants reçoivent l'alerte et l'heure exacte de reprise ;
s'il refuse, le système le lui rappelle après quelques minutes (réglable par l'admin,
5 min par défaut), car la pause est un droit. »

Migration `supabase/migrations/20261124100000_pause_proposee.sql` (additive, aucun
effacement), scénario `supabase/tests/scenarios_pause_proposee.sql`.

Statuts de preuve : **présent dans le code** ; **testé localement** (scénario SQL rejoué
sur Postgres 16 local, tests Flutter) ; **testé sur staging : non** ; **déployé : non**.
L'écran (la barre du chrono qui pose Oui / Non) est un autre lot.

- **Pause par défaut.** Une classe sans ligne `pause_reglages` reçoit une pause au milieu
  de la durée prévue de la séance (45 min pour 90, 30 pour 60), d'une durée lue selon le
  public de la classe : `seance.pause_minutes_adulte` (10) ou `seance.pause_minutes_enfant`
  (5), ramenée au multiple de 5 le plus proche entre 5 et 30 ; 0 = pas de pause. Si la
  pause et le reste minimum ne tiennent pas dans la séance, pas de pause (`non_prevue`).
  Une classe avec une ligne garde le choix de son enseignant (`actif = false` : pas de
  pause). `pause_reglage_lire` rend cette pause par défaut (version `0`,
  `par_defaut = true`) : la fiche de la classe montre la vérité.
- **Moment.** Compté depuis le début **prévu** (`sessions.started_at`, jamais réécrit au
  démarrage) : `debut_prevu_utc = greatest(now(), started_at) + délai`.
- **Oui** = `pause_seance_demarrer`. **Non** = `pause_seance_refuser(p_seance_id,
  p_cle_idempotence)` : enseignant titulaire, séance en cours, pause `programmee` ;
  `refus_nombre + 1`, prochaine proposition à `now() + seance.pause_rappel_minutes` (5) ;
  idempotente (`pause_idempotence`, opération `refuser`).
- **`proposer_a`** = `debut_prevu_utc` tant qu'il n'y a pas eu de Non, puis l'instant posé
  par le dernier Non ; nul quand `proposer_a + durée + seance.pause_reste_minimum_minutes`
  (15) dépasse la fin prévue, ou quand le statut n'est plus `programmee`. L'enseignant peut
  toujours démarrer la pause lui-même tant qu'elle est `programmee`.
- **Fin.** Pas de minuterie serveur : l'écran de l'enseignant appelle `pause_seance_terminer`
  à l'heure de reprise (autre lot).
- **Pause prévue par le serveur** (lot de la prière, objet `public.seance_pause_prevue`,
  table ou vue, peut ne pas exister) : au démarrage, une ligne valide (durée de 5 à 30 par
  pas de 5, pause entière dans la séance) donne l'heure, la durée et le `motif` ; elle prime
  sur le milieu et sur le moment choisi par l'enseignant. **Point à confirmer par le
  directeur** : elle est posée même si l'enseignant a désactivé la pause de sa classe.
- **Droits.** Inchangés : élève, tuteur, contrôleur et tout autre appelant ne lisent ni
  ne pilotent la pause sur le serveur (le relais par la visio reste).
- **Réglages de la direction** (Configuration > Règles, section « Pause pendant la
  séance ») : les quatre clés ci-dessus.
- **Client sur un serveur ancien** : sans les nouveaux champs, aucune proposition ; un Non
  envoyé à un serveur sans `pause_seance_refuser` relit l'état au lieu de casser l'écran.
