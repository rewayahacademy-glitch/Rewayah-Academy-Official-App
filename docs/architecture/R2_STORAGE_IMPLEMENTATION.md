# Stockage Cloudflare R2 : quatre seaux, quatre responsabilités

> Ce document ne contient aucune valeur de secret, et ne doit jamais en contenir.
> Les **noms** des variables d'environnement y figurent ; leurs **valeurs** vivent
> uniquement dans les secrets du serveur Supabase.

État au 21 septembre 2026. Les quatre seaux existent chez Cloudflare, sous
juridiction européenne, et leur cycle complet (écriture, relecture, comparaison
octet à octet, suppression, vérification d'absence) a été mesuré au vert sur les
quatre. Ce document décrit ce que **le code de cette application** en fait.

---

## 1. Les quatre domaines de stockage

Un appelant ne nomme jamais un seau. Il nomme une **responsabilité métier**, et
la couche d'infrastructure résout le seau. C'est ce qui fait qu'une faute de
frappe ne peut pas envoyer une pièce d'identité dans le seau de la messagerie :
il n'existe aucun chemin de code qui accepte un nom de seau en paramètre.

| Domaine (`DomaineStockage`) | Seau physique | Groupe de secrets | État du branchement |
| :--- | :--- | :--- | :--- |
| `pieceIdentite` | `rewayah-identity-vault` | `R2_IDENTITY_VAULT_*` | **Chemin serveur livré**, Flutter non basculé |
| `archiveSeance` | `rewayah-session-recordings` | `R2_RECORDINGS_*` | **Chemin serveur livré**, Egress non démarré |
| `pieceJointeMessage` | `rewayah-message-attachments` | `R2_MESSAGING_*` | **Déclaré seulement.** Aucun point d'entrée |
| `priveApplicatif` | `rewayah-app-private-storage` | `R2_APP_PRIVATE_*` | **Déclaré seulement.** Aucun consommateur |

La table de correspondance vit dans `supabase/functions/_shared/r2/domaines.ts`
et nulle part ailleurs.

### Les cinq secrets par domaine

Pour chaque préfixe `<P>` de la colonne « groupe de secrets » :

| Nom | Forme attendue | Rôle |
| :--- | :--- | :--- |
| `<P>_ACCOUNT_ID` | 32 caractères hexadécimaux | Lu pour être **vérifié**, jamais transporté |
| `<P>_ACCESS_KEY_ID` | 32 caractères hexadécimaux | Identifiant de clé S3 |
| `<P>_SECRET_ACCESS_KEY` | 64 caractères hexadécimaux | Secret de signature |
| `<P>_BUCKET_NAME` | le nom exact du seau | Comparé au seau attendu du domaine |
| `<P>_ENDPOINT` | `https://<compte>.eu.r2.cloudflarestorage.com` | **Lu, jamais reconstruit** |

Soit **4 groupes x 5 valeurs = 20 secrets**.

Trois gardes valent d'être expliquées, parce que ce sont des pannes réellement
rencontrées le 21 septembre en posant les trousseaux :

- `<P>_BUCKET_NAME` est **comparé** au seau attendu du domaine. Un trousseau qui
  désigne le seau d'un autre domaine échoue franchement au lieu de réussir au
  mauvais endroit. C'est ce qui rend vrai « aucun domaine ne partage
  accidentellement le seau d'un autre », plutôt que de l'espérer.
- `<P>_ENDPOINT` doit porter l'identifiant de compte **de ce domaine**. Les
  quatre seaux vivent sur quatre comptes Cloudflare distincts : un point
  d'accès recopié d'un domaine à l'autre signerait vers le compte du voisin, et
  R2 répondrait `403` sans jamais dire pourquoi.
- La **forme** de chaque valeur est vérifiée. Une variable qui contenait
  `NOM = url` et une autre qui contenait le nom de la variable au lieu de son
  contenu ont coûté une session entière de diagnostic ; les deux se voient
  désormais au premier appel, avec un message qui nomme le secret fautif et ne
  reprend jamais sa valeur.

### Le point d'accès n'est jamais fabriqué

Les quatre seaux sont sous juridiction européenne, donc leur hôte porte un
segment `.eu.` :

```
https://<ACCOUNT_ID>.eu.r2.cloudflarestorage.com
```

Reconstruire cet hôte à partir de l'identifiant de compte produirait la forme
**sans** `.eu.`, qui répond `403` sur cette configuration. La valeur est donc
lue depuis `<P>_ENDPOINT`, et le code se contente d'en vérifier la forme : URL
absolue, `https`, hôte sous `r2.cloudflarestorage.com`, sans chemin ni
paramètre.

> Note d'exploitation : R2 répond `AccessDenied` là où S3 dirait
> `NoSuchBucket`. Un `403` peut donc signifier « mauvais endpoint », « seau
> inexistant » ou « clé sans droit » indifféremment. Seul le contraste à un
> paramètre près permet de trancher.

---

## 2. Responsabilité de chaque seau

### `rewayah-identity-vault` — sensibilité maximale

Pièces d'identité et justificatifs KYC. Aucun accès direct depuis Flutter,
aucune URL publique permanente, aucun listing client. Toute ouverture **par ce
chemin serveur** est autorisée en base puis journalisée dans `audit_logs` avec
l'identité de la personne qui regarde.

> Ce chemin n'est pas encore le seul. L'aperçu KYC d'aujourd'hui
> (`service_validation.dart`) signe son URL **depuis le navigateur** de
> l'administrateur, avec sa propre session, et n'écrit aucune trace nominative.
> Tant que Flutter n'est pas basculé, les deux voies coexistent et une seule
> journalise. La policy Storage `kyc_lecture_admin` laisse par ailleurs un
> `controller` lire le seau `kyc` en direct, sans journal : c'est la décision
> ouverte n° 6.

Le cloisonnement par genre posé par `0001` reste la règle : la porte
`autoriser_lecture_piece_identite()` est construite **sur**
`read_kyc_documents()` et n'en duplique pas le filtre. Un administrateur
masculin n'ouvre pas une pièce féminine, et le refus est indistinct d'une pièce
inexistante.

### `rewayah-session-recordings` — archives audio des séances

Archives `audio_only` déposées **directement par LiveKit Egress**. Le binaire ne
transite ni par Supabase, ni par une fonction Edge, ni par Flutter. Supabase ne
conserve que les métadonnées de `session_recordings` : séance, clé d'objet,
durée, taille, codec, statut, expiration, gel éventuel.

Rétention normale : **30 jours** (`app_config.recording_retention_days`), avec
capacité de gel pour litige.

### `rewayah-message-attachments` — non branché, et c'est délibéré

**Le domaine messagerie n'existe pas dans ce dépôt.** Vérifié par balayage
exhaustif : zéro table `conversations`, `conversation_participants` ou
`messages` dans les 35 migrations, zéro route de messagerie dans le routeur,
zéro écran, zéro fonction Edge. Le registre des décisions classe la nature de la
messagerie en **question ouverte n° 18**, « à trancher avant le premier écran ».

Il n'existe donc aujourd'hui **aucun moyen serveur de répondre à « cette
personne est-elle membre de cette conversation ? »**. Or une pièce jointe ne
s'autorise pas autrement. Le domaine est déclaré dans la couche typée, il
résout son seau, et il n'a délibérément **aucun point d'entrée** : en créer un
exigerait d'inventer une table de conversations, c'est-à-dire d'inventer une
décision produit.

### `rewayah-app-private-storage` — non branché, faute de consommateur

Les trois cibles naturelles sont vides : les supports pédagogiques
(`library_resource`, `resource_version`, `download_asset` comptent 0 ligne et
n'ont aucun adaptateur Supabase), les photos d'enseignants (colonne
`photo_storage_key` présente, jamais renseignée, jamais lue par Flutter) et les
exports (`ADM-03` est marqué BLOCKED, décision opérateur non prise).

Les deux flux de stockage réellement vivants — KYC et avatars — sont servis par
Supabase Storage et leur autorisation est écrite en RLS sur `storage.objects`.
Les déplacer serait une migration de données, pas un branchement. Et le KYC
relève de toute façon du coffre d'identité.

---

## 3. Architecture serveur

```
supabase/functions/_shared/r2/
  domaines.ts            configuration typée, résolution domaine -> seau, erreurs
  cles.ts                convention de clés d'objets, fabrication et vérification
  signature.ts           SEUL fichier autorisé à signer, politique de durée
  client_appelant.ts     client Supabase porteur du JWT de l'appelant
  stockage_historique.ts lecture signée du seau Supabase `kyc` (transition)
  ingestion_archive.ts   entrée des métadonnées quand Egress annonce sa fin

supabase/functions/
  piece-identite-acces/    ouvrir une pièce d'identité
  piece-identite-depot/    réserver une clé et signer un dépôt
  piece-identite-confirme/ vérifier l'objet déposé, rendre la pièce visible
  archive-seance-acces/    écouter une archive de séance
  livekit-webhook/         branchement `egress_ended` (ajout de 15 lignes)
```

Une seule logique de création de client S3, une configuration explicite par
domaine, aucune duplication de signature. `signature.ts` est au stockage ce que
`_shared/livekit.ts` est aux jetons vidéo : le seul fichier qui détient les
identifiants, vérifiable d'un seul `grep`.

### Dépendance ajoutée

`npm:aws4fetch@1.0.20` — 6 Ko, zéro dépendance d'exécution, bibliothèque que
Cloudflare emploie elle-même pour R2. Le même arbitrage que pour le SDK LiveKit :
une chaîne canonique SigV4 écrite de mémoire marche le jour où on l'écrit et
casse en silence sur un détail d'encodage.

---

## 4. Flux

### Ouvrir une pièce d'identité

```
Flutter
  -> POST /piece-identite-acces  { document_id }
     1. l'appelant est identifié par SON jeton
     2. autoriser_lecture_piece_identite(document_id)   <- la porte + l'audit
     3. signature d'une URL GET de 60 s
  <- { url, expire_dans_secondes }
```

### Déposer une pièce d'identité

```
Flutter
  -> POST /piece-identite-depot  { profile_id?, doc_type, type_mime, taille_octets }
     1. identité lue dans le jeton
     2. preparer_depot_piece_identite()  <- la porte, puis tire l'identifiant,
                                            FABRIQUE la clé, crée la réservation
                                            INVISIBLE
     3. signature d'une URL PUT de 120 s, content-type et content-length signés
  <- { document_id, url, methode, en_tetes_exiges, expire_dans_secondes }

  -> PUT <url> avec exactement les en-têtes exigés  -> R2

  -> POST /piece-identite-confirme  { document_id }
     1. la porte du dépôt est rejouée, sous le jeton de l'appelant
     2. HEAD sur R2 : l'objet est-il réellement là ?
     3. confirmer_depot_piece_identite()  <- la pièce devient visible
  <- { confirme: true }
```

**Pourquoi trois appels et non deux.** La clé doit exister avant d'être signée,
donc la ligne naît avant l'envoi. Mais une ligne créée avant l'envoi peut n'avoir
jamais d'objet : réseau coupé, application fermée, envoi refusé. Laissée visible,
elle entrerait dans la file de validation et l'administration ouvrirait un
document inexistant. La réservation naît donc **invisible** (`deleted_at` posé),
et la confirmation ne la croit pas sur parole : elle demande à R2, par un `HEAD`,
si l'objet est là. Sans cette vérification, « j'ai fini d'envoyer » ne serait
qu'une affirmation du client.

`confirmer_depot_piece_identite()` n'est accordée qu'à `service_role`,
précisément pour que le `HEAD` ne soit pas contournable.

### Écouter une archive

```
Flutter
  -> POST /archive-seance-acces  { recording_id }
     1. identité lue dans le jeton
     2. autoriser_ecoute_archive()  <- relation, statut, expiration, gel + audit
     3. signature d'une URL GET de 60 s
  <- { url, expire_dans_secondes, duree_secondes }
  -> lecture en flux, par plages HTTP, directement depuis R2
```

Aucun de ces flux ne fait transiter un octet par une fonction Edge.

---

## 5. Règles de signature

| Règle | Application |
| :--- | :--- |
| Durée de lecture sensible | **60 s** (`DUREE_LECTURE_SENSIBLE_S`), valeur d'ADR-002 |
| Durée de dépôt | **120 s** (`DUREE_DEPOT_S`), justifiée ci-dessous |
| Méthode | `GET` pour lire, `PUT` pour déposer. La méthode entre dans la chaîne canonique : une URL de lecture ne peut pas écrire |
| Durée hors bornes | refusée avant signature (1 s à 3600 s) |
| Encodage | aucun `+` dans la chaîne de requête, vérifié à la signature (voir ci-dessous) |
| Journalisation | ni l'URL, ni la chaîne de requête de signature n'entrent jamais dans un journal |

**Le piège d'encodage, et pourquoi il n'y a pas de nom de fichier proposé.**
`URLSearchParams` encode l'espace en `+`, alors que SigV4 impose l'encodage
RFC 3986, où l'espace s'écrit `%20`. Un seul paramètre contenant une espace —
`response-content-disposition: attachment; filename="..."` en était un — et la
chaîne signée diffère de celle que R2 recalcule : **403 sur toute lecture**.
Mesuré le 21 septembre 2026 avec `aws4fetch@1.0.20`. L'option a été retirée, une
garde refuse désormais toute URL signée contenant un `+`, et un test la couvre.

Les durées vivent dans `signature.ts` et nulle part ailleurs. Une durée recopiée
dans dix fonctions est une durée qu'on ne peut plus raccourcir.

**Pourquoi 120 s pour le dépôt et non 60 s.** `X-Amz-Expires` est évalué par R2
au moment où la requête lui parvient, pas pendant son déroulement : la borne
limite le délai avant le **début** de l'envoi, non sa durée. Cent vingt secondes
couvrent la sélection du fichier et sa lecture sur un appareil lent, sans
allonger la fenêtre pendant laquelle une URL interceptée reste utilisable.

### Contraintes du dépôt

`content-type` et `content-length` sont vérifiés côté serveur, puis **signés**.
Comme ils entrent dans `X-Amz-SignedHeaders`, R2 refuse un envoi qui annonce
autre chose que ce qui a été accordé. Le type annoncé par le client n'est jamais
cru sur parole : il est contraint.

| Contrainte | Valeur |
| :--- | :--- |
| Types acceptés (pièce d'identité) | `image/jpeg`, `image/png`, `image/heic`, `application/pdf` |
| Taille maximale | 8 Mio, le plafond que `service_dossier.dart` appliquait déjà côté client |

> R2 ne supporte pas les *POST policies* S3. Le `content-length` signé est donc
> le seul moyen de borner la taille à la signature, et il tient parce que la
> valeur signée doit correspondre à la taille réelle du corps.

---

## 6. Règles d'autorisation

**Une URL signée n'est pas une autorisation.** C'est le produit d'une
autorisation déjà accordée. L'autorisation est vérifiée en base, avant la
signature, par une RPC dédiée au domaine. Aucune fonction générique du type
`getSignedUrl(seau, cle)` n'est exposée.

Aucun point d'entrée n'accepte de clé d'objet : un `object_key` dans le corps de
la requête est refusé explicitement.

| Domaine | Ce qui est vérifié, et par qui |
| :--- | :--- |
| Pièce d'identité, lecture | `autoriser_lecture_piece_identite()` : compte valide, rôle `admin` ou `controller`, cloisonnement par genre délégué à `read_kyc_documents()`, pièce non supprimée. Journalise `kyc_document_open` |
| Pièce d'identité, dépôt | `peut_deposer_piece_identite()`, sans effet de bord, rejoue **exactement** les trois policies d'insertion (voir ci-dessous). Puis `preparer_depot_piece_identite()` fabrique la clé. Journalise `kyc_document_prepare` |
| Pièce d'identité, confirmation | la même porte, rejouée sous le jeton de l'appelant, puis un `HEAD` sur R2. `confirmer_depot_piece_identite()` est réservée à `service_role`. Journalise `kyc_document_confirm` |
| Archive | `autoriser_ecoute_archive()` : compte valide, puis `admin`/`controller`, **ou** enseignant de la séance, **ou** foyer d'un participant *si la séance ne réunit qu'un seul foyer*. Archive non supprimée, non révoquée, non expirée. Journalise `recording_listen` |
| Gel de conservation | `geler_archive_seance()` : `admin` uniquement, sens du gel et motif obligatoires. Journalise `recording_legal_hold_set` / `_lift`, motif compris |
| Métadonnées d'archive | `enregistrer_archive_seance()` : `service_role` uniquement. L'appelant est le webhook, jamais une personne |

**Qui peut déposer une pièce d'identité.** La porte rejoue l'union exacte des
trois policies d'insertion de `kyc_documents`, ni plus ni moins :
`kyc_admin_all` (l'administration, pour qui elle veut), `kyc_guardian_insert`
(un **tuteur**, pour une personne de son foyer) et `kyc_staff_self_insert` (un
**enseignant** ou un **contrôleur**, pour lui-même). Le rôle compte autant que
la relation : une porte qui se contenterait de « pour soi, ou pour son foyer »
ouvrirait le dépôt aux **élèves**, que les trois policies excluent — tout élève
a un foyer, donc son jeton porte un `household_id`, et il pourrait créer une
pièce au nom de son tuteur puis obtenir une URL de dépôt sous le préfixe de
celui-ci.

**Pourquoi la famille n'écoute pas une archive de groupe.**
`session_in_household()` rend vrai dès qu'un seul participant appartient au
foyer interrogé. Elle a été écrite quand une séance comptait deux personnes,
et voulait alors dire « le foyer de l'élève de ce cours ». Depuis le pivot du
19 septembre, `0017` porte le plafond à 7 participants : une séance de groupe
réunit cinq enfants de cinq foyers. Appliquée telle quelle, cette relation
donnerait à **chaque** tuteur l'audio complet de la séance, où récitent aussi
les enfants des autres familles. La branche famille est donc bornée aux séances
d'un seul foyer jusqu'à ce que l'opérateur tranche (décision ouverte n° 8).

Les portes sont écrites en **exigence positive enveloppée de `coalesce`**, jamais
en refus. Un refus écrit `app_role() <> 'admin'` ne se déclenche pas sur le
`NULL` d'un appelant anonyme, et c'est exactement la fuite que `0029` a corrigée.

### Pourquoi les RPC sont appelées sous le jeton de l'appelant

`log_sensitive_access()` lit l'acteur dans `auth.uid()`. Appelée avec la clé de
service, elle écrirait un acteur **vide** — l'inverse de ce que l'ADR-002
demande. Les points d'entrée R2 appellent donc leurs RPC avec un client porteur
du JWT de l'appelant (`client_appelant.ts`). Trois choses deviennent vraies
ensemble : `auth.uid()` désigne la bonne personne, `app_role()` rend son rôle
réel, et la trace est exacte sans qu'aucun identifiant ne soit reçu du client.

---

## 7. Conventions de clés d'objets

Une clé est **fabriquée par le serveur**, jamais reçue du client, et ne porte
**aucune donnée lisible** : pas de nom, pas de courriel, pas de téléphone, pas
de numéro de document, pas de type de pièce, pas de genre. Rien que des UUID.

```
identity/<profile_id>/<document_id>
recordings/<session_id>/<recording_id>.ogg
messages/<conversation_id>/<attachment_id>        (convention posée, non utilisée)
private/<famille>/<resource_id>                   (convention posée, non utilisée)
```

Le genre mérite sa propre phrase : dans `kyc_documents`, il décide **qui** peut
ouvrir le dossier. L'écrire dans un chemin de fichier exposerait une donnée de
cloisonnement sous une forme que ni la RLS ni le journal ne gouvernent.

Le premier segment d'une clé d'identité est le profil titulaire, et ce n'est pas
esthétique : c'est déjà la forme du stockage Supabase actuel
(`<auth.uid()>/<horodatage>.<ext>`), où la policy `kyc_depot_self` compare ce
segment à `auth.uid()`.

`verifierCle()` fait le chemin inverse : toute clé venue de l'extérieur — le
`filepath` qu'un Egress annonce, une ligne écrite par un chemin qu'on ne connaît
pas encore — est confrontée à la convention avant d'être signée ou insérée. Une
clé d'un autre domaine, une remontée de chemin, une profondeur inattendue ou un
conteneur audio inattendu sont refusés.

---

## 8. Rétention

**Aucune politique n'est inventée ici.** Ce qui n'est pas décidé est signalé
comme décision requise, section 13.

| Domaine | Politique réellement décidée | État |
| :--- | :--- | :--- |
| Archives | 30 jours (`recording_retention_days`), **sauf litige qui gèle la pièce** (ADR-002) | Expiration calculée à l'entrée. **Aucune purge n'existe** |
| Pièce d'identité | 90 jours (`kyc_retention_days`), `purge_at` calculé à l'insertion | **Aucune purge n'existe**. L'arbitrage « purge après validation ou conservation intégrale » n'a jamais été tranché |
| Messagerie | néant | Le domaine n'existe pas |
| Privé applicatif | néant | Dépend du type de ressource, aucune n'existe |

### Le gel de conservation

`session_recordings` porte désormais `legal_hold_since`. Une purge future
**doit** tester cette colonne avant de supprimer quoi que ce soit.

Un gel prolonge l'accès pour l'administration et le contrôle uniquement : il
existe pour un litige, pas pour rendre une pièce expirée réécoutable par la
famille.

**Le motif ne vit pas sur la ligne, et c'est délibéré.** La RLS borne les
lignes, jamais les colonnes : les deux policies de `session_recordings` donnent
le `select` à l'enseignant de la séance et au foyer d'un participant, sur la
ligne entière. Un motif tel que « plainte de la famille X contre l'enseignant
Y » serait donc lisible par l'enseignant mis en cause. Le motif est écrit dans
`audit_logs`, qui est réservé à l'administration, append-only et chaîné par
empreinte ; la ligne ne porte que le **fait** du gel, une date que tout le
monde peut voir sans dommage.

`p_gel` à `NULL` **échoue** au lieu de dégeler. Sans ce refus, `if p_gel and …`
ne se déclenche pas (`NULL and true` vaut `NULL`, donc aucun motif n'est exigé)
et le `case when p_gel then … else null end` tombe dans le `else` : une archive
retenue pour un litige perdrait sa protection sur un argument omis. C'est le
même renversement qu'`0029` a corrigé ailleurs — l'inconnue doit fermer.

> Choix d'implémentation : une **colonne** et non une valeur de
> `recording_status`. PostgreSQL refuse d'utiliser une valeur d'enum ajoutée
> dans la même transaction (`55P04`, leçon de `0031`), ce qui aurait obligé à
> scinder la migration en deux. Et le gel dit mieux ce qu'il est : non pas un
> état de l'archive, mais une contrainte posée **sur** elle, qui coexiste avec
> `available` ou `expired`.

---

## 9. Intégration LiveKit

**Aucun Egress n'est démarré par ce dépôt.** `_shared/livekit.ts` n'importe du
SDK que `AccessToken` et `WebhookReceiver` ; il n'existe ni `EgressClient`, ni
appel à `startRoomCompositeEgress`. Ce qui est livré ici est le **contrat
d'arrivée**, pour que l'archive entre toute seule le jour où Egress sera
configuré.

```
LiveKit Egress (audio_only)
  -> dépose directement dans rewayah-session-recordings
  -> webhook `egress_ended`
     -> ingestion_archive.ts : vérifie l'état, la clé, la convention
     -> enregistrer_archive_seance(room_name, egress_id, cle, duree, taille, codec)
        -> résout la séance depuis `session_video_route.room_name`
        -> idempotente sur `egress_id`
```

Le gabarit que la configuration Egress devra respecter :

```
filepath = recordings/<session_id>/<uuid>.ogg
```

Ce gabarit doit être **calculé par le serveur** au démarrage de l'Egress — c'est
exactement ce que `cleDe('archiveSeance', sessionId, uuid)` fabrique — et non
laissé aux variables de LiveKit : `{room_name}` est opaque, et surtout un
gabarit que nous ne calculons pas est un gabarit que nous ne contrôlons pas.

Une clé hors convention est **refusée**, pas insérée : une clé qu'on ne
reconnaît pas est une clé qu'on ne saura pas autoriser ensuite. Le refus est
consigné et reste rattrapable à la main.

L'ingestion ne peut jamais faire échouer la réponse du webhook. Un `200` est dû
à LiveKit pour l'événement de présence traité plus haut ; répondre autre chose
déclencherait un renvoi de l'événement **entier**, donc un doublon de présence
pour rattraper une archive.

---

## 10. Erreurs

| Classe | Origine | Ce que le client apprend |
| :--- | :--- | :--- |
| `configuration` | secret absent ou mal formé | `stockage indisponible` (503) |
| `signature` | échec de la bibliothèque de signature | `stockage indisponible` (503) |
| `validation` | type, taille ou durée refusés | `depot refuse` (400) |
| refus métier | la RPC a dit non | `acces refuse` (403) |

Un échec de configuration et un échec de signature disent tous deux
« indisponible » : la différence intéresse l'exploitant, pas l'appelant, et la
lui donner renseignerait sur l'état interne du trousseau.

De même, un refus d'accès ne distingue jamais « vous n'avez pas le droit » de
« cela n'existe pas ». La différence renseignerait sur le contenu du coffre.

### Observabilité

Une trace de stockage (`TraceStockage`) est une forme **fermée** : domaine,
opération, statut, identifiant opaque de ressource, corrélation, classe
d'erreur, durée. Il n'existe aucun champ par lequel une URL pré-signée, une
chaîne de requête de signature, un secret, un contenu de fichier ou une donnée
personnelle pourraient passer.

---

## 11. Tests

### Deno — `supabase/functions/_shared/r2/` (44 contrôles)

Aucun n'appelle Cloudflare : la connectivité a déjà été prouvée, et la refaire
n'apprendrait rien. Ce qui est mesuré est ce que **le code** fait.

- **Configuration** : chaque domaine résout son propre groupe de secrets ; aucun
  domaine ne partage le seau d'un autre ; un secret absent échoue explicitement
  sans exposer de valeur ; aucun repli silencieux ; les quatre fautes de collage
  réellement rencontrées sont refusées sur la forme ; le point d'accès est lu et
  jamais fabriqué, et il doit désigner le compte de son domaine.
- **Routage** : les quatre correspondances domaine → seau, vérifiées jusque dans
  le chemin de l'URL signée, avec l'assurance qu'aucun autre seau n'y apparaît.
- **Clés** : aucune donnée lisible, casse normalisée, remontée de chemin
  refusée, clé d'un autre domaine refusée.
- **URL pré-signées** : expiration inscrite et conforme, URL non permanente,
  méthode bornée, aucune credential permanente dans l'URL, **aucun paramètre
  encodé en `+`**.
- **Dépôt** : `content-type` et `content-length` présents dans
  `X-Amz-SignedHeaders`, type hors liste refusé, taille hors plafond refusée.
- **Ingestion Egress** : un Egress avorté n'écrit rien, une clé hors convention
  est refusée et jamais insérée, la durée en nanosecondes est convertie, la
  séance n'est jamais reçue, le codec n'est pas inventé, une panne de base est
  rapportée et jamais levée.
- **Observabilité** : un échec ne dit rien au client, une trace ne peut pas
  porter d'URL signée.

### SQL — `supabase/tests/scenarios_r2.sql` (17 contrôles)

La moitié qui ne peut se prouver qu'en base : **la porte**.

`R1` idempotence de l'entrée des métadonnées et résolution de la séance par la
salle · `R2` l'anonyme n'obtient rien, par le `revoke` **et** par la porte ·
`R3` rôle non autorisé, tuteur compris · `R4` cloisonnement par genre jusque
dans l'ouverture d'une pièce · `R5` la trace porte l'identité de l'auditrice ·
`R6` la clé est fabriquée par le serveur, ne porte rien de lisible, et la
réservation n'entre pas dans ADM-02 · `R6 bis` la confirmation rend la pièce
visible et reste hors de portée d'un compte humain · `R6 ter` un élève ne dépose
rien, ni pour lui ni au nom de son tuteur · `R7` on ne dépose pas pour un autre
foyer · `R8` l'écoute exige une relation avec la séance · `R9` archive expirée,
gel qui rouvre pour la seule administration, sens du gel obligatoire, et le
motif n'est pas stocké sur la ligne · `R10` gel réservé à l'administration,
archive révoquée muette pour tous · `R11` chaque écoute et chaque gel laissent
leur trace · `R12` l'entrée des métadonnées reste hors de portée d'une personne,
et `agent_ro` n'a aucun droit sur les fonctions qui écrivent · `R14` sur une
séance de **groupe**, aucune famille n'obtient l'audio · `R13` aucune valeur de
secret dans le schéma.

### CI

Un job `edge-r2` a été ajouté : c'est le **premier job Deno du dépôt**. Avant
lui, rien ne vérifiait `supabase/functions` — le TypeScript des fonctions Edge
n'était ni compilé ni testé. Il lance les tests, le type-check des fichiers R2,
et une garde qui refuse toute chaîne de 64 caractères hexadécimaux ou tout point
d'accès R2 dans `lib/` et les migrations.

---

## 12. Limites connues

1. **Flutter n'est pas basculé.** Le dépôt KYC continue d'écrire dans le seau
   Supabase `kyc` ; les points d'entrée livrés ne sont appelés par aucun écran.
   C'est délibéré : basculer l'interface est une décision d'exploitation, et les
   fichiers concernés étaient en cours de modification par un autre agent.
2. **`piece-identite-acces` sert les deux stockages.** `storage_backend` dit
   lequel. C'est une transition, pas un état cible.
3. **Le dépôt R2 n'a jamais été exercé de bout en bout.** La forme de l'URL
   signée est vérifiée localement, y compris les deux en-têtes signés et
   l'absence de `+`, mais aucun `PUT` réel n'a été envoyé à R2 depuis ce code.
   Le premier dépôt réel est le moment de vérité.
4. **Aucune purge n'existe**, pour aucun des deux domaines à rétention.
5. **`enregistrer_archive_seance` crée puis met à jour `egress_id`** en deux
   temps, pour que la violation d'unicité soit rattrapée par le bloc
   `exception`. C'est correct mais peu élégant.
8. **La convention de clés est écrite deux fois** : en TypeScript (`cleDe()`,
   pour le contrat Egress et les tests) et en SQL (`preparer_depot_piece_identite()`,
   qui est la source de vérité en production). Une divergence serait attrapée
   immédiatement par `verifierCle()`, qui garde l'entrée de chaque clé, mais
   elle reste possible.
9. **Une URL d'archive vit 60 secondes**, ce qui borne le **début** de chaque
   requête. Une écoute longue par plages HTTP devra redemander une URL en
   cours de route, et chaque demande est journalisée — c'est la conséquence
   directe de l'ADR-002, pas un défaut d'implémentation, mais le volume de
   traces que cela produit mérite d'être mesuré au premier usage réel.
10. **Une archive dont le chemin ne respecte pas la convention est refusée**
    et n'est reprise par rien : l'objet reste dans le seau sans ligne en base.
    Le refus est consigné avec son `egressId`, donc rattrapable à la main, mais
    il n'existe aucune file de reprise.
6. **Deux défauts pré-existants bloquent la CI**, indépendants de ce lot et
   laissés tels quels : `0030_tc_socle.sql` écrit dans `storage.buckets` sans
   la garde `to_regclass` que `0004` emploie, ce qui fait échouer
   `migrate-check` sur un Postgres nu ; et `scenarios_etape3.sql:287` échoue
   avec « ADM-02 ECHEC : 4 dossiers en attente au lieu de 2 ». Les deux ont été
   mesurés sur `main` sans aucune modification de ce lot.
7. **`_shared/livekit.ts:104` porte une erreur de type** (`canPublishSources`),
   introduite le 12 septembre. Elle fait échouer `deno check` sur
   `livekit-webhook`, qui est donc exclu du type-check de la CI.

---

## 13. Décisions encore ouvertes

Aucune de ces décisions n'a été prise à la place de l'opérateur.

| # | Décision requise | Pourquoi elle bloque |
| :--- | :--- | :--- |
| 1 | **Basculer le dépôt KYC de Flutter vers R2 ?** Et si oui, migrer les 18 objets existants ou les laisser dans Supabase Storage ? | Sans elle, le coffre d'identité reste alimenté à zéro |
| 2 | **Purge des archives : `pg_cron` ou règle de cycle de vie du seau ?** L'ADR-002 dit l'un, l'ADR-006 dit l'autre, et `pg_cron` n'est installée nulle part | Rien n'efface jamais une archive aujourd'hui. Une règle de cycle de vie côté seau **ignorerait le gel légal**, ce qui est probablement rédhibitoire |
| 3 | **Rétention KYC : purge après validation, ou conservation intégrale ?** Posée dans `audit-initial.md`, jamais tranchée | `purge_at` est calculé mais rien ne le lit |
| 4 | **Nature de la messagerie** (question ouverte n° 18 du registre) | Tant qu'elle n'est pas tranchée, `rewayah-message-attachments` ne peut pas être branché sans inventer un modèle d'autorisation |
| 5 | **Usage du seau privé applicatif** : supports pédagogiques, photos d'enseignants, exports (`ADM-03`) ? | Le seau n'a aucun consommateur |
| 6 | **Le contrôleur peut-il lire le seau `kyc` en direct ?** La policy `kyc_lecture_admin` l'autorise, **sans journal**, alors que la porte serveur journalise tout | Une voie d'accès non tracée coexiste avec une voie tracée |
| 7 | **Une fonction `r2-selftest` est active en production** (v49) et n'existe pas dans le dépôt. Son source déployé est un talon HTTP 410. Faut-il la supprimer ? | Une fonction déployée que le dépôt ignore |
| 8 | **Que peut réécouter une famille d'une séance de groupe ?** L'archive porte la voix de cinq enfants de cinq foyers | La branche famille est pour l'instant bornée aux séances d'un seul foyer. Ouvrir plus large exigerait soit un consentement des cinq familles, soit un découpage par piste que l'ADR-002 range explicitement hors MVP-0 |

---

## 14. Ce qui n'a pas été touché chez Cloudflare

Aucun seau créé, renommé ou supprimé. Aucune credential générée. Aucun endpoint
remplacé. Aucune juridiction modifiée. Aucun seau rendu public.
