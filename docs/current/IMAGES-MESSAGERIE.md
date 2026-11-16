# Images et cœurs dans la messagerie : contrat serveur

Lot IMAGES-MESSAGERIE, plan validé par le directeur le 16/11/2026. **Partie serveur seulement**
(migrations, fonctions Edge, tests). L'interface fait l'objet d'une seconde PR, écrite d'après ce
contrat. Statut au dépôt de cette PR : *présent dans le code*, *testé localement* (scénario SQL sur
un Postgres nu, tests Deno) ; ni *testé sur staging* ni *déployé*, donc rien n'est *prouvé* au sens
du directeur.

Rien de ce qui suit n'ajoute de seau ni de secret : le seau est celui de la messagerie (domaine R2
`pieceJointeMessage`, secrets `R2_MESSAGING_*`) ; la confirmation réutilise le secret déjà posé pour
la bibliothèque (`LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY` côté Edge, table
`private.library_upload_confirmation_secrets` côté base) avec son propre préfixe de signature
(`message-image-v1`) ; la purge réutilise `COURRIELS_ENVOI_SECRET`.

## 1. Ce que le client doit savoir d'abord

- **Un message d'abord, l'image ensuite.** Un message a toujours un texte (non vide, 5 000
  caractères au plus : règle inchangée de `com_envoyer_message`). L'image se rattache à un message
  **que la personne vient d'envoyer** (`com_envoyer_message` rend son `id`). Les messages restent en
  ajout seul : le serveur n'en modifie aucun.
- **Une seule image par message.** Le même dépôt (mêmes types) peut être redemandé tant qu'il n'est
  pas confirmé (lien expiré avant l'envoi) : la même image revient, avec les mêmes clés. Un dépôt
  annulé ou refusé pour contenu invalide **ferme** ce message aux images : la personne envoie un
  nouveau message.
- **Compression sur l'appareil, avant tout.** Image ≤ 2 Mo (2 097 152 octets), miniature ≤ 100 Ko
  (102 400 octets), JPEG, PNG ou WebP. Le serveur ne recompresse rien.
- **Jamais de clé R2 côté client.** Le client reçoit des URL signées, rien d'autre.

## 2. Qui peut quoi

| Geste | Condition |
| :--- | :--- |
| Lire les images et les cœurs d'un fil | être partie du fil, avec les mêmes droits de lecture que `com_lire_fil` |
| Déposer une image | être l'auteur du message, avoir le droit d'écrire dans le fil (`peut_ecrire`), **ne pas être un compte élève de moins de 18 ans** |
| Poser ou retirer son cœur | avoir le droit de lire le fil (la lecture seule garde le cœur) |

**Le candidat enseignant (compte `pending_kyc`) est partie de son fil « candidature » et dépose des
images comme n'importe quelle partie** (IMAGE-CANDIDAT, 16/11/2026, migration
`20261129400000_image_candidat.sql`). Il avait été oublié : les fonctions de dépôt lisaient
`app_account_valid()` et `private.com_appelant()`, deux portes fermées à un compte `pending_kyc`, d'où le
refus 403 vu en production. Elles lisent maintenant la porte de la messagerie
(`private.com_appelant_msg()`, valide d'abord, à défaut le candidat). **Un message dont le texte n'est que
« [image] » et auquel AUCUNE ligne d'image ne se rattache n'est rendu à personne**, auteur compris (`com_fil_json`) ;
une image confirmée puis purgée garde son message et sa ligne « image retirée ».
Le mot « Image » des premiers essais n'est pas masqué : une personne peut l'écrire.

**Vérité d'abord : un élève mineur n'est partie d'aucun fil aujourd'hui.** `private.com_appelant()`
refuse tout compte mineur et un déclencheur interdit qu'un mineur soit partie d'un fil
(COM-BACK-1). La règle « un compte élève de moins de 18 ans ne dépose pas d'image » est donc posée
explicitement (code `mineur_refuse`, vérifiée avant toute autre) mais, avec la messagerie actuelle,
elle double un refus déjà acquis. « Il peut en recevoir » est vrai par son **foyer** (les tuteurs
lisent le fil de l'enfant), pas par le compte de l'enfant. L'âge se lit comme partout ailleurs
(`private.com_est_mineur` : `student_type = 'minor'`) ; il n'existe pas de date de naissance
consultée ici.

## 3. Le dépôt : fonction Edge `message-image-depot`

Appel authentifié (`Authorization: Bearer <jeton>`), `POST`, corps JSON, trois actions.

### 3.1 `demander`

```json
{
  "action": "demander",
  "message_id": "<uuid du message>",
  "image":     { "mime": "image/jpeg", "octets": 150000, "largeur": 800, "hauteur": 600,
                 "couleur_moyenne": "#a1b2c3" },
  "miniature": { "mime": "image/webp", "octets": 8000 }
}
```

`couleur_moyenne` : facultative, `#rrggbb` (le `#` est facultatif à l'envoi, toujours rendu avec).
`largeur` et `hauteur` : entiers de 1 à 20 000, ceux de l'image **après** compression.

Réponse 200 :

```json
{
  "image_id": "<uuid>",
  "expire_dans_secondes": 600,
  "image":     { "url": "...", "methode": "PUT", "en_tetes_exiges": { "content-type": "image/jpeg", "content-length": "150000" } },
  "miniature": { "url": "...", "methode": "PUT", "en_tetes_exiges": { "content-type": "image/webp", "content-length": "8000" } }
}
```

Le client envoie chaque fichier par `PUT` sur son URL, **avec exactement** les en-têtes exigés : le
type et la taille sont signés, R2 refuse un envoi qui s'en écarte (c'est ce qui tient la limite de
taille). Les URL valent 10 minutes. Clés fabriquées par la base :
`fils/<fil_id>/<uuid>.(jpg|png|webp)` et `fils/<fil_id>/<uuid>-min.(jpg|png|webp)` (l'extension suit
le type de chaque fichier).

### 3.2 `confirmer`

```json
{ "action": "confirmer", "image_id": "<uuid>" }
```

Après les deux `PUT`. Le serveur lit **les 16 premiers octets** de chaque objet, les compare au
type annoncé (JPEG, PNG, WebP), signe en HMAC et la base passe l'image à `confirmee`. Réponse 200 :
`{ "phase": "pret", "image_id": "...", "etat": "confirmee" }`. Les autres parties du fil reçoivent
le signal temps réel « message » (`com_signaux`) et relisent le fil. Si le contenu n'est pas du type
annoncé, les deux objets sont retirés, le dépôt est abandonné (`supprimee`) et la réponse est
`contenu_different`.

### 3.3 `annuler`

```json
{ "action": "annuler", "image_id": "<uuid>" }
```

Abandonne un dépôt en attente : retire les objets, passe la ligne à `supprimee`. Réponse
`{ "annule": true|false }`. Le message ne peut plus recevoir d'image : voir §1.

### 3.4 Refus

Corps `{ "error": "<phrase>", "code": "<code>" }`. **Le client se règle sur `code`**, jamais sur la
phrase (en français, technique, non destinée à l'affichage).

| `code` | Statut | Cause vraie |
| :--- | :---: | :--- |
| `demande_invalide` | 400 | corps illisible, identifiant, taille, dimension ou couleur hors bornes |
| `type_refuse` | 415 | autre chose que JPEG, PNG, WebP |
| `image_trop_lourde` | 413 | image > 2 Mo |
| `miniature_trop_lourde` | 413 | miniature > 100 Ko |
| `non_autorise` | 403 | pas partie du fil, lecture seule, message d'un autre, message inconnu (jamais distingués) |
| `mineur_refuse` | 403 | compte élève de moins de 18 ans |
| `limite_horaire` | 429 | 20 images demandées dans l'heure écoulée par cette personne |
| `deja_une_image` | 409 | ce message a déjà son image (confirmée, annulée, ou autre type) |
| `depot_indisponible` | 410 | dépôt inconnu, déjà confirmé, annulé ou vieux de plus d'un jour |
| `contenu_different` | 422 | les premiers octets ne sont pas ceux du type annoncé |
| `objet_introuvable` | 422 | `confirmer` avant que les deux fichiers soient arrivés |
| `stockage_indisponible` | 503 | secrets `R2_MESSAGING_*` absents ou R2 en panne |
| `confirmation_indisponible` / `confirmation_mal_reglee` | 503 | secret de confirmation absent, ou différent entre l'Edge et la base |
| `depot_impossible` | 500 | panne de la base ; jamais présenté comme un refus de la personne |

`401 { "error": "authentification requise" }` sans jeton valide.

## 4. La lecture

### 4.1 Dans le fil : aucune requête de plus

`com_lire_fil` et `com_lister_fils` rendent, pour **chaque message**, dans la même requête :

```json
{ "id": "...", "texte": "...", "envoye_le": "...", "auteur": { ... },
  "image": { "id": "...", "largeur": 800, "hauteur": 600, "couleur_moyenne": "#a1b2c3", "etat": "confirmee" },
  "coeurs": 2,
  "aime_par_moi": true }
```

- `image` vaut `null` si le message n'a pas d'image. Pas de clé R2, pas d'URL.
- `etat` : `en_attente` (**visible de son auteur seulement**), `confirmee`, `supprimee`.
  **Correctif du 16/11 (20261129200000) : un message dont l'image est `en_attente` n'est rendu
  qu'à son auteur, et un message dont l'image est `supprimee` sans `confirmee_le` (dépôt annulé ou
  refusé) n'est rendu à personne.** La règle vaut pour `com_lire_fil` et `com_lister_fils` (dernier
  message et compte des non lus). L'autre partie ne voit donc plus un message vide avant la
  confirmation.
- Une image `confirmee` dont les 90 jours sont passés est rendue **`supprimee` dès l'échéance**,
  sans attendre la tâche de nuit. L'écran affiche alors « Image retirée après 90 jours » ; la
  largeur, la hauteur et la couleur moyenne restent rendues pour garder la place dans la bulle.
- `coeurs` : nombre de cœurs actuellement donnés. `aime_par_moi` : l'appelant a donné le sien.

### 4.2 Les URL : fonction Edge `message-images-lecture`

Appel authentifié, `POST`.

```json
{ "fil_id": "<uuid>" }                          // toutes les miniatures du fil, EN UNE FOIS
{ "fil_id": "<uuid>", "image_id": "<uuid>" }    // l'image complète demandée
```

Réponse 200 :

```json
{ "images": [
  { "id": "...", "message_id": "...", "etat": "confirmee", "url": "https://...", "mime": "image/webp", "expire_dans_secondes": 3600 },
  { "id": "...", "message_id": "...", "etat": "supprimee" }
] }
```

- URL `GET` signées, **1 heure**. Pour la liste : la miniature (200 images au plus, les plus
  récentes d'abord). Avec `image_id` : l'image complète.
- Une image `supprimee` rend son état **sans `url`**. Une image `en_attente` d'un autre n'est jamais
  rendue.
- **Un seul appel par ouverture de fil** (plus un par image ouverte en plein écran). Jamais un appel
  par image dans une liste.
- Refus : `non_autorise` (403) si la personne n'est pas partie du fil ; `stockage_indisponible`
  (503) ; `demande_invalide` (400).

## 5. Cœurs

RPC Supabase, appelées avec le jeton de la personne :

| RPC | Effet | Rend |
| :--- | :--- | :--- |
| `aimer_message(p_message uuid)` | pose **son** cœur | `{ "coeurs": n, "aime_par_moi": true }` |
| `ne_plus_aimer_message(p_message uuid)` | retire **son** cœur | `{ "coeurs": n, "aime_par_moi": false }` |

Appels répétés sans effet (un cœur déjà donné reste donné ; retirer un cœur jamais donné ne fait
rien). Refus : exception `CoeurNonAutorise`, SQLSTATE `42501`, pour un message ou un fil illisible
(jamais distingués). Une pose ou un retrait réels envoient le signal temps réel « message » aux
autres parties : leur écran relit le fil et voit le nouveau compte.

La table `com_message_coeurs` garde la ligne d'un cœur retiré (`retire_le` renseigné) : aucune
suppression de ligne n'existe nulle part dans ce lot.

## 6. Expiration à 90 jours

- `expire_le = cree_le + 90 jours`, posé à la demande de dépôt.
- Tâche pg_cron `message-images-purge`, **une fois par jour à 03 h 41 UTC**, qui appelle la fonction
  Edge `message-images-purge` (porte : secret `COURRIELS_ENVOI_SECRET`, en-tête
  `x-courriels-secret`). Par lots de 200, au plus 25 lots par appel : lit les images dues, supprime
  les deux objets R2, puis marque la ligne `supprimee` (`supprimee_le = maintenant`). **La ligne
  reste.** Une ligne n'est marquée que si les deux objets sont partis ; sinon la nuit suivante la
  reprend. Sont dus : toute image non supprimée dont `expire_le` est passé, et tout dépôt jamais
  confirmé depuis plus d'un jour.
- La tâche n'est planifiée que sur un projet Supabase (pg_cron, pg_net et le coffre présents) ; elle
  suppose le secret du coffre `courriels_envoi_url` (déjà posé pour `push-envoi`) dont elle déduit
  l'adresse.

## 7. Tables (lecture directe, pour mémoire)

`com_message_images` et `com_message_coeurs` : RLS activée, lecture réservée aux participants du
fil (via `com_fil_lisible` / `com_message_lisible`), **aucune écriture directe**. Les colonnes
`cle_r2` et `cle_miniature` ne sont pas lisibles par un client. L'interface n'a pas besoin de lire
ces tables : tout passe par la lecture du fil et par `message-images-lecture`.

## 8. Gestes prévus côté interface (rappel du plan du 16/11, à réaliser par la seconde PR)

1. Joindre : choisir une photo, la compresser sur l'appareil (image ≤ 2 Mo, miniature ≤ 100 Ko),
   envoyer le message **texte**, puis `demander` → deux `PUT` → `confirmer`. Montrer les trois états
   du dépôt ; une phrase vraie par code de refus (§3.4), jamais « connexion » pour un refus du
   serveur.
2. Afficher : réserver la place avec `largeur` × `hauteur`, peindre `couleur_moyenne` en fond, puis
   la miniature (un seul appel `message-images-lecture` à l'ouverture du fil), puis l'image complète
   au toucher.
3. Image `supprimee` : « Image retirée après 90 jours », sans URL ni ré-essai.
4. Cœur : double toucher ou toucher du cœur sous la bulle ; mise à jour immédiate, retour arrière en
   cas d'échec (action courante, `DECISION-FLUIDITE-2026-11-07.md`).
5. Compte élève mineur : le bouton de pièce jointe n'est pas proposé (le serveur refuse de toute
   façon, `mineur_refuse`).

## 9. À savoir (limites connues)

- **Taille réelle de l'objet** : elle est tenue par le `content-length` signé à la demande (R2 refuse
  un envoi d'une autre taille), pas relue à la confirmation. Seuls les 16 premiers octets sont lus.
- **Contenu au-delà de l'en-tête** : l'en-tête prouve un type de fichier, pas qu'il s'agit d'une
  image lisible ni sans contenu piégé.
- **Pas de modération ni d'analyse du contenu** dans ce lot.
- **Compteur de l'heure** : il compte les dépôts *demandés* (confirmés ou non) ; un dépôt
  abandonné compte donc dans les 20.
- **Un message dont le dépôt a été annulé ou refusé** ne peut plus recevoir d'image (§1).
- `contenu_piece.ts` ne connaît pas WebP (il sert aux pièces d'identité) : le contrôle WebP est dans
  `_shared/r2/message_image.ts`. `cles.ts` porte une convention `messages/<conversation>/<pièce>`
  que personne n'emploie ; les images suivent la convention du plan (`fils/<fil>/<uuid>`) avec leur
  propre vérificateur.

## 10. Correctif du 16/11/2026 (lot IMAGES-CORRECTIF)

Constat du directeur en production : 6 envois, aucun appel à `confirmer`, le `PUT` vers R2 échoue
(`RefusImage.envoiStockage`) ; le destinataire voyait le mot « Image » sans photo ; l'expéditeur
voyait deux bulles. **Cause probable du `PUT` : la règle d'origine (CORS) manque sur le seau
R2_MESSAGING. Elle se règle dans Cloudflare, par le directeur : ce correctif n'y change rien et ne
le prouve pas.** Tant qu'elle manque, aucun envoi d'image n'aboutit.

- **Texte de remplissage** : `texteImageSeule = '[image]'` (`phrases_images.dart`, un seul endroit) ;
  `'Image'` (les deux messages d'essai en base) est lu de même quand le message porte une image.
  Ni la bulle ni l'aperçu de la liste ne l'écrivent ; la liste dit « Photo » (fr, en, ar) avec une
  petite icône image.
- **Migration `20261129200000_images_messagerie_non_confirmee.sql`** (installée par le pilote après
  fusion) : colonne `com_message_images.confirmee_le`, posée par `message_image_confirmer` ; règle de
  rendu ci-dessus dans `private.com_fil_json`. Les images confirmées avant la migration n'ont pas de
  date : la règle ne regarde que les images `supprimee`, et aucune image confirmée n'a encore été
  purgée (90 jours).
- **Une seule bulle** : la bulle locale garde l'identifiant du message serveur (`ProgressionImage`
  rapporte `messageCree` puis `depotCree`) ; la copie serveur n'est pas affichée tant que la bulle
  locale est en cours ou en échec, et la bulle locale s'efface une fois l'image confirmée relue.
- **Échec** : l'icône d'alerte ronde et la ligne « Non confirmé · Toucher pour réessayer » ouvrent un
  menu « Réessayer » (le même message : la RPC accepte de redemander le même dépôt) et « Supprimer »
  (`message-image-depot` action `annuler`, puis la bulle disparaît). Une cause qui ne change pas en
  réessayant (limite horaire, compte mineur) se dit par sa phrase et ne propose que « Supprimer ».
- **Phrase du stockage** : « L'envoi de l'image n'a pas abouti. Réessayez plus tard. » (la tournure
  « n'a pas pu être envoyée » est interdite par le contrôle `affirmation-reseau`).
- **Limite connue** : si `demander` échoue après la création du message (limite horaire, panne), le
  message `[image]` existe sans image côté serveur (les messages sont en ajout seul) ; « Supprimer »
  n'a alors aucun dépôt à annuler. Le destinataire le voit comme une bulle sans texte ni photo.

### 10 bis. Miniature qui reste un aplat de la couleur moyenne (constat du pilote, après l'ajout du CORS)

- **Prouvé** : le défaut n'est ni `ImageDeBulle` ni la compression. Sur un build web release servi en
  Chromium (Playwright, 1440 de large), une image violette 1080 x 1350 réduite par le canevas du
  navigateur, servie d'une autre origine (CORS), se peint dans la bulle. La préparation sur
  l'appareil (décodage, image 1600, miniature 320, couleur moyenne) prend 290 à 310 ms pour une
  photo de 4,4 Mo (4032 x 3024), avec Chromium sans carte graphique.
- **Défaut prouvé par un test** (qui échoue sans le correctif) : le port garde la liste des
  miniatures d'un fil une heure (`urlsMiniatures`). Une image arrivée après cette lecture n'y
  figure pas ; le fil l'avait déjà marquée « demandée » et ne redemandait jamais : la bulle restait
  l'aplat de la couleur moyenne. La visionneuse, elle, demande l'image complète à chaque ouverture
  (appel frais) : elle affichait la vraie image. Cela explique le destinataire. **Pour
  l'expéditeur, une course est possible (une lecture du fil entre la confirmation côté serveur et le
  retrait de la liste gardée) mais n'est pas prouvée** : aucun accès à R2 ni à la fonction de
  lecture en production.
- **Correctif** : si une image visible n'est pas dans la liste rendue, le fil relit une fois le
  serveur sans le cache (`miniatures(frais: true)`) ; si la miniature est en échec ou sans adresse,
  la bulle va chercher l'image complète (`repli`) au lieu d'un aplat muet.
- **Chargement** : tant que les pixels n'arrivent pas, la couleur moyenne porte le reflet lent du
  `Skeleton` (`ReflecAttente`, `AppMouvement.refletSquelette`) ; il s'arrête à la première image et
  reste fixe sous « réduire les animations ». Le cercle de progression de l'expéditeur est gardé.
- **Où passe le temps** : seule la préparation est mesurée (ci-dessus). Les autres temps ne sont
  pas connus : chaque envoi écrit désormais dans la console du navigateur des lignes
  `[images-temps]` (message créé, demande du dépôt, `PUT` image, `PUT` miniature, confirmation,
  préparation, lecture des adresses signées), à relever au prochain essai en production.

### 10 ter. Photo jamais peinte, ni chez l'expéditeur ni chez le destinataire (urgence du 16/11, IMAGE-EXPEDITEUR)

- **Constat en production** : serveur sain (image confirmée, `com_fil_json` et `message-images-lecture`
  répondent) ; la bulle reste un aplat de la couleur moyenne avec le reflet, sans fin.
- **Reproduit dans Chromium** (build web release, Playwright, 1440) avec le vrai `FilDiscussion` et la vraie
  compression du navigateur : si le `GET` de l'adresse signée est servi **sans `Access-Control-Allow-Origin`**,
  `Image.network` (lecture par octets, `fetch`) est refusé par le navigateur ; la miniature échoue, le repli vers
  l'image complète échoue de la même façon, la bulle reste l'aplat. Avec l'en-tête, tout se peint. Captures :
  `docs/current/captures/E2E/IMAGE-EXPEDITEUR/`.
- **Non prouvé** : que la règle CORS du seau n'autorise pas le `GET` depuis l'origine de l'application (aucun accès
  à Cloudflare). Cela reste à vérifier par le directeur. Le correctif ne remplace pas cette règle : il rend
  l'affichage robuste quelle qu'elle soit.
- **Correctif** : `Image.network(..., webHtmlElementStrategy: WebHtmlElementStrategy.fallback)` dans
  `ImageDeBulle` (miniature, repli et visionneuse). L'image se lit d'abord par octets ; si le navigateur refuse,
  elle passe par une balise `<img>`, qui n'exige aucun en-tête CORS. Limites : la copie « Enregistrer l'image »
  lit toujours les octets (`http.readBytes`) et exige donc le CORS ; le rendu par balise `<img>` ne passe pas par
  le décodage à la taille d'affichage.
