# PX-KYC : lire les pièces d'identité avec un modèle de vision (étude et plan, phase 1)

- **Statut : ÉTUDE ET PLAN. Aucun code, aucune migration** (numéro réservé : `20261129940000`, non utilisé).
  Écrit par BE-DOSSIER le 17/11/2026, sur ordre du pilote, lot prioritaire du directeur (17/11 : « lire les pièces, des
  milliers de documents, c'est ce qui prend le plus de temps et a le plus besoin d'automatisation »).
- **Aucune pièce réelle lue, aucune ligne de personne lue.** Une seule mesure en production : un compteur agrégé
  (§1.4). Les images d'essai seront fictives (§5).

## 0. Faux, bloqué ou non prouvé (en premier)

1. **Rien de ce circuit n'existe.** Aucune fonction ne lit le contenu d'une pièce autrement que par ses 16 premiers
   octets (`kyc-confirme`, `piece-identite-confirme`). Aucune clé API d'un fournisseur d'IA n'est dans le dépôt.
2. **Le prix par image, la durée de conservation chez le fournisseur et la politique « pas d'entraînement » ne sont pas
   vérifiés ici.** Je ne les écris pas de mémoire (§4). Le directeur les lit sur la console et le contrat du fournisseur.
3. **Un modèle ne prouve pas qu'une pièce est vraie** (§3). Ce circuit réduit le temps de lecture, il ne remplace ni
   un contrôle de pièce par un spécialiste ni une preuve de vie. Le dire au directeur avant de promettre « vérifié ».
4. **Le format HEIC (photos d'iPhone) n'est pas lisible par l'API d'un modèle de vision** (JPEG, PNG, GIF, WebP et PDF
   le sont). Une part des pièces ne sera donc pas lue sans conversion (§2.6). Part inconnue ici.
5. **Envoyer l'image d'une femme à un fournisseur ne respecte pas, en soi, le cloisonnement par genre** que l'application
   applique à la lecture humaine (`read_kyc_documents`, `autoriser_lecture_piece_identite`) : le modèle n'a pas de
   genre. C'est une décision du directeur (§4, D3), pas un détail technique.
6. **RGPD art. 22 :** aucune décision entièrement automatique. Le circuit ne refuse jamais, ne valide jamais seul.
   Le risque réel est ailleurs : la validation « en lot d'un geste » peut devenir un tampon sans lecture (§2.5).

## 1. L'existant (relevé du dépôt, `main` au 17/11/2026, tête `39829cca5`)

### 1.1 Où vit la pièce

| Quoi | Où | Preuve |
| :--- | :--- | :--- |
| La ligne | `public.kyc_documents` : `id`, `profile_id`, `doc_type` (`id_card`, `passport`, `residence_permit`, `other`), `gender` (posé par le déclencheur, celui du profil), `object_key`, `status` (`pending`, `approved`, `rejected`), `rejection_reason`, `verified_by`, `verified_at`, `purge_at`, `deleted_at`, `storage_backend` (`supabase` ou `r2`) | `0001_fondations.sql:112`, `0004`, `0034_r2_stockage.sql:104` |
| Le fichier | **Seau Supabase Storage privé `kyc`** pour toutes les pièces existantes (le commentaire du dépôt parle de « dix-huit pièces » : faux aujourd'hui, voir §1.4). Le coffre R2 `rewayah-identity-vault` est prêt côté code (`piece-identite-depot`, `piece-identite-confirme`) mais **aucune pièce n'y est** | `supabase/functions/_shared/r2/stockage_historique.ts`, mesure §1.4 |
| Formats et taille | JPEG, PNG, HEIC, PDF ; 8 Mo au plus ; contrôle des 16 premiers octets au dépôt | `_shared/r2/signature.ts:66-79`, `_shared/r2/contenu_piece.ts`, FN-101 |
| Conservation | `purge_at` posé par la base à l'insertion : `now() + kyc_retention_days` (90 jours par défaut), valeur du déposant ignorée (HYGIENE-2) | `20261122100000_hygiene_purge_kyc.sql` |

### 1.2 Qui la voit, et par quel chemin

- **Lecture par la direction seulement**, active, de **genre connu**, du **même côté** que la pièce (le super-administrateur
  fait exception, interrupteur `kyc_exception_super_admin`, modifiable par `postgres` seul). `public.read_kyc_documents()`
  filtre ; `public.autoriser_lecture_piece_identite(document)` journalise l'accès **avant** toute signature, puis la
  fonction Edge `piece-identite-acces` signe une URL de 60 secondes. Le client nomme un document, jamais une clé.
- Un enseignant, un tuteur ou un candidat ne voit que sa propre pièce, pas par cette porte.
- **Praxis ne voit aucune pièce** : R4 de `SECURITE-PRAXIS.md` l'interdit, et `praxis_lire` ne rend « jamais de contact,
  de pièce, de photo » (`_shared/praxis/outils.ts:153`).

### 1.3 Les gestes qui existent déjà

| Geste | Fonction | Ce qu'il fait |
| :--- | :--- | :--- |
| Lire la pièce sur la fiche | `public.piece_dossier_candidat(candidature)` + `piece-identite-acces` | rend `documentId`, `statut`, `motifRefus`, `deposeLe`, `decideLe`, `typeContenu`, `genreFichier` (PIECE-TYPE : le type se lit dans le MIME enregistré) |
| Décider la pièce | `public.decider_dossier(document, approuve, motif)` | `pending` vers `approved` ou `rejected` ; **un refus exige un motif** ; journalise `kyc_decision` ; active le compte ou le désactive selon le cas ; capacité serveur `gestes.deciderPiece` |
| Valider la pièce de salle 3 | `public.valider_piece_candidat` (transition 14 du moteur) | décide la pièce **et** exige les sept contrôles de la salle 3 |
| Restreindre | geste `restreindre` du moteur des candidatures (transition 20) | une candidature confirmée puis restreinte (piece, versement ou decision) : cause jamais montrée |
| Confirmer le contenu | `public.kyc_confirmer_contenu` (service_role seul) | pose `private.kyc_contenus_confirmes` après lecture des 16 octets |

Il n'existe **aucun** geste « vrai type » distinct du contrôle de signature de contenu.

### 1.4 Combien de pièces en attente (compteur seul, production, 17/11/2026)

Requête exécutée, une seule, agrégée (`count(*)` groupé par état, stockage et effacement ; aucune ligne lue, aucun
identifiant) :

| État | Stockage | Effacée | Pièces |
| :--- | :--- | :--- | ---: |
| **pending** | supabase | non | **254** |
| approved | supabase | non | 117 |
| rejected | supabase | non | 19 |
| **Total** | | | **390** |

Conséquences : **254 pièces attendent aujourd'hui une décision humaine** ; toutes sont dans le seau `kyc` (rien dans
R2) ; les commentaires du dépôt qui disent « dix-huit pièces » sont périmés. Ce que je **ne sais pas** : la répartition
par type de personne (candidat enseignant, enseignant, tuteur), par `doc_type`, par format (HEIC ou non), ni l'ancienneté.
Ces ventilations sont des mesures agrégées de plus ; je ne les ai pas faites sans ordre.

## 2. Le circuit proposé, isolé de Praxis

### 2.1 Principe

Une fonction Edge **dédiée**, `piece-identite-lecture`, sans lien avec Praxis ni avec le connecteur `praxis-mcp`.
Pour une pièce en attente : (1) elle télécharge l'objet avec le client de service ; (2) elle l'envoie à un modèle de
vision avec une **consigne fixe**, **sans outil**, **sans texte libre de l'appelant** ; (3) elle ne garde que des champs
structurés, validés par le serveur ; (4) elle calcule **côté serveur** la proposition ; (5) elle écrit le résultat dans
une table que seule la direction peut lire, par la même porte (rôle, genre, journal) que la pièce.

### 2.2 Ce que le modèle rend, et rien d'autre

Un objet JSON à schéma fermé (sortie structurée), refusé et ignoré au moindre écart :

| Champ | Valeurs |
| :--- | :--- |
| `type_piece` | `carte_identite`, `passeport`, `titre_sejour`, `permis`, `autre`, `illisible` |
| `nom_ecrit` | texte court (80 signes au plus), **tel qu'écrit**, ou nul ; traité comme une donnée, jamais comme une consigne |
| `date_expiration` | `AAAA-MM-JJ` ou nul |
| `lisible` | oui / non |
| `photo_presente` | oui / non / indeterminé |
| `signes_retouche` | aucun / possibles / probables (avec une cause courte à choisir dans une liste fermée : police incohérente, bords de découpe, zone floue localisée, capture d'écran d'écran, autre) |
| `ligne_mrz` | texte brut de la zone lisible par machine, ou nul (permet un contrôle de somme **côté serveur**, §2.3) |

Le texte d'une pièce est une donnée **non fiable** : un papier portant « ignore tes consignes » ne doit rien changer.
D'où : aucun outil, aucune sortie libre, un schéma fermé, une longueur bornée, des listes de valeurs, et une
validation serveur avant toute écriture.

### 2.3 Ce que le serveur calcule lui-même (pas le modèle)

- **Nom concordant** (oui / non / doute) : le serveur compare `nom_ecrit` au nom du dossier, après normalisation
  (accents, casse, ordre prénom/nom, traits d'union). **Le nom du dossier n'est jamais envoyé au fournisseur** (minimisation).
  Un nom en écriture arabe contre un dossier en lettres latines, ou l'inverse, donne **doute**, jamais non.
- **Expiration** : date lue contre la date du serveur, avec une marge fixe (à décider, §4 D6).
- **Somme de contrôle de la zone MRZ** (passeports et cartes concernées) : un calcul exact, que le modèle ne sait pas
  faire de façon fiable. Une somme fausse est un signal fort de lecture erronée ou de falsification maladroite.
- **La proposition** par règle écrite et testée :
  - **conforme** : lisible, type admis, non expirée, photo présente, nom **oui**, aucun signe de retouche, somme MRZ
    juste ou sans objet ;
  - **non conforme** : expirée, ou illisible, ou type non admis, ou signes de retouche **probables** ;
  - **à vérifier** : tout le reste, dont tout **doute** de nom, toute pièce non lue (HEIC non converti, échec du modèle).
  En cas de doute entre deux cases, la plus prudente.

### 2.4 Où c'est écrit, et qui le lit

- Table **`private.kyc_lectures`** (nom provisoire) : `document_id`, `version_consigne`, `modele`, champs structurés,
  `proposition`, `cree_le`. RLS active, aucune politique, **aucun droit** pour `anon`, `authenticated`, `service_role`
  et `agent_ro` ; écrite par l'Edge via une fonction `SECURITY DEFINER` réservée à `service_role`.
- Lecture par une fonction `DEFINER` du **même moule** que `piece_dossier_candidat` : direction active, genre connu,
  même côté, super-administrateur par l'interrupteur existant ; elle **journalise** par `log_sensitive_access`.
- **Une lecture par version de consigne et par pièce** : le lot est rejouable sans doublon. Une nouvelle consigne crée
  une nouvelle lecture, l'ancienne reste pour comparaison.
- **Durée de vie = celle de la pièce** : la lecture contient un nom et une date, donc une donnée personnelle. Elle part
  avec la pièce (job de purge existant). Attention : un `ON DELETE CASCADE` contient le mot d'effacement que les
  migrations s'interdisent ; le lot serveur choisira entre l'ajout de la table à la purge existante et une demande
  d'arbitrage au pilote.
- **Praxis ne la lit jamais** : le test R4 (liste fermée des tables écrites et lues par les fonctions `praxis_*`) reçoit
  la table et la fonction en exclusion explicite, mutation prouvée.

### 2.5 L'écran et la validation en lot (RGPD art. 22)

- Sur la fiche d'un dossier : un bandeau **« Lecture automatique »** (le mot « proposition », jamais « décision »),
  avec les champs lus, la proposition et l'avertissement « à confirmer en regardant la pièce ». Il s'ajoute au geste
  actuel (voir la pièce, décider) et n'en remplace aucun.
- Une vue de file **« Pièces lues, prêtes à valider »** : les pièces `conforme`, une ligne chacune (type, expiration,
  date de dépôt), **sans image** dans la liste. **Un geste « Valider ces N pièces »** appelle une fonction serveur qui
  rejoue `decider_dossier` une par une, **bornée à 50 par appel**, en aal2, avec une clé d'idempotence, et qui **refuse
  toute pièce dont la lecture a changé ou dont l'état n'est plus `pending`**. Chaque validation est journalisée comme
  aujourd'hui, avec la mention « validée en lot sur proposition ».
- **Les « doute » et « à vérifier » restent à l'humain**, une à une. **Un refus reste un geste individuel avec un
  motif écrit** : il n'existe pas de « refuser en lot ».
- **Garde contre le tampon** (l'art. 22 vise une intervention humaine réelle, pas une case cochée) : l'écran du lot
  impose d'**ouvrir au moins un échantillon** tiré par le serveur (par exemple une pièce sur dix, au moins une) avant
  d'activer le bouton, et le journal garde combien ont été ouvertes. À arbitrer (§4 D5).

### 2.6 Formats et reprise du stock

- JPEG, PNG, PDF : envoyés tels quels (le PDF comme document).
- **HEIC : conversion côté serveur avant envoi, ou classement « à vérifier : format non lu »** si la conversion n'est
  pas disponible dans l'environnement Edge (non vérifié ici). Mesure préalable utile : la part de HEIC parmi les 254.
- **Reprise des 254 pièces en attente** : un lot unique, par paquets de 10 à 20, avec reprise sur échec, plafond de
  débit, arrêt par un réglage serveur (interrupteur dans `private`), et un compteur lisible par la direction.
  Ensuite : chaque nouvelle pièce confirmée déclenche sa lecture (ou une tâche planifiée toutes les dix minutes).
- Un échec du modèle, du réseau ou de la validation du schéma **n'écrit jamais « non conforme »** : il écrit « à vérifier,
  lecture impossible ». Une panne ne refuse personne.

## 3. Les limites honnêtes

Ce qu'un modèle de vision **ne détecte pas** :

- **Un faux de bonne qualité** : un document recomposé proprement, une pièce réelle d'une autre personne, une photo
  d'écran bien cadrée. Le modèle lit ce qui est écrit ; il ne sait pas si le document **existe** dans un registre.
- **Aucune preuve de vie.** Rien ne dit que la personne qui dépose est celle de la photo. Comparer le visage de la pièce
  à une photo de la personne est un **traitement biométrique** (RGPD art. 9) : **exclu de ce plan**, pas proposé.
- **Aucune vérification de l'autorité émettrice** (modèles de pièces par pays, éléments de sécurité, puce NFC).
- Des **erreurs de lecture** sur des pièces de travers, brillantes, à moitié cadrées, ou en écritures peu courantes ;
  des **faux positifs de retouche** sur des photos de mauvaise qualité.
- Les **noms** : translittération arabe-latin, noms composés, ordre variable. D'où « doute » plutôt que « non ».

**Ce que le circuit apporte réellement** : le tri. Les pièces nettes, lisibles, non expirées, au bon nom partent en lot
à un geste ; la lecture humaine se concentre sur les cas douteux. **Gain attendu, non mesuré** : une mesure sur des images
d'essai fictives (§5) dira la part de « conforme » ; sur de vraies pièces elle ne se mesurera qu'après mise en service,
sur un échantillon que la direction relit en parallèle (on compare la proposition à la décision humaine).

**Option : un prestataire spécialisé de vérification d'identité** (document + selfie vidéo + base de modèles de pièces +
puce NFC selon l'offre). Il ajoute précisément ce qui manque : **preuve de vie, rapprochement visage-pièce, contrôle de
l'authenticité du modèle de document**. Il coûte un prix **par vérification** (de l'ordre de une à quelques unités de
monnaie selon l'offre et le volume ; **chiffre non vérifié ici, à demander par devis**), exige un **parcours côté
personne** (la personne refait un geste dans l'application ou sur le site du prestataire), ne rattrape pas les **254
pièces déjà déposées** (pas de selfie), et déplace les données chez un tiers dont le traitement de la biométrie doit
figurer à la politique. À considérer **après** ce lot si le directeur veut une garantie plus forte qu'un tri.

## 4. Ce qu'il faut au directeur

| # | Quoi | Pourquoi | Ce que je n'ai pas vérifié |
| :--- | :--- | :--- | :--- |
| D1 | Une **clé API du fournisseur du modèle** (Anthropic), posée par le directeur comme **secret de fonction serveur** (jamais dans le dépôt, jamais en variable d'environnement visible) | l'Edge appelle l'API | le plan, le plafond de dépense et les limites de débit du compte |
| D2 | **Lire et noter** sur la console / le contrat : (a) l'API **n'entraîne pas** sur les données envoyées ; (b) la **durée de conservation** côté fournisseur et si une conservation nulle est possible ; (c) le **pays de traitement** ; (d) le **prix par image** du modèle choisi | RGPD art. 13 et 28 ; sans ces quatre faits la politique ne peut pas être écrite | **les quatre** : je ne les connais pas de façon sûre |
| D3 | **Décision : envoyer au fournisseur aussi les pièces des femmes** (cloisonnement par genre) ? Option A : oui, le modèle n'a pas de genre, la lecture humaine reste cloisonnée. Option B : non, ces pièces restent à lecture humaine. Option C : oui, mais seulement le texte (pas la photo), ce qui exige un recadrage serveur que je ne sais pas faire de façon fiable | c'est une décision de principe de l'académie | l'avis d'un juriste |
| D4 | **Base légale** : intérêt légitime ou exécution du contrat ? | art. 6 | l'avis d'un juriste ; je ne suis pas juriste |
| D5 | **Garde contre le tampon** (§2.5) : échantillon obligatoire d'ouverture, oui ou non, et quelle fraction | art. 22 | |
| D6 | **Marge d'expiration** (une pièce qui expire dans moins de N mois est-elle « à vérifier » ?) | règle métier | |
| D7 | **Modèle** : un modèle petit et peu cher suffit-il (à mesurer sur images fictives, §5), ou le plus capable ? | coût et qualité | les prix, voir D2 |
| D8 | **Le texte de la politique de confidentialité**, validé et publié **le jour de la mise en service**, avec montée de `VersionsJuridiques.version` et avis aux personnes déjà inscrites | une politique ne décrit que des traitements réels | |

**Phrase à ajouter à la politique (PROPOSITION, à valider ; `[À CONFIRMER]` = fait que D2 ou D4 doivent établir) :**

> Pour gagner du temps dans la vérification des pièces d'identité, l'image de votre pièce est lue par un outil
> d'intelligence artificielle fourni par [nom du fournisseur] `[À CONFIRMER]`, hébergé [pays] `[À CONFIRMER]`. Cet outil
> ne retient pas votre pièce au-delà de [durée] `[À CONFIRMER]` et ne s'en sert pas pour s'entraîner `[À CONFIRMER]`.
> Il ne prend aucune décision : il propose, et une personne de la direction regarde et décide toujours. Vous pouvez
> demander à ce que votre pièce soit lue uniquement par une personne, en nous écrivant `[À CONFIRMER : un mécanisme
> d'exclusion existe-t-il, voir l'étape B du plan de confidentialité de Praxis]`.

La mise en service **ne précède pas** cette publication : tant qu'elle n'est pas faite, le réglage serveur d'activation
reste fermé (même règle que le mode essai de Praxis, PX-4).

## 5. Les lots, l'estimation, les tests sans aucune vraie pièce

### 5.1 Lots (une étape, une pull request)

| Lot | Contenu | Zone | Estimation |
| :--- | :--- | :--- | :--- |
| **PX-KYC-1 serveur** | migration `20261129940000` (table `private.kyc_lectures`, réglage d'activation fermé, fonction d'écriture réservée à `service_role`, fonction de lecture direction, fonction de validation en lot bornée, journal) ; Edge `piece-identite-lecture` avec client du fournisseur **injectable** ; module pur de comparaison de nom, de somme MRZ et de proposition ; exclusion R4 | `supabase/**` (backend, autorisé par la décision du 17/10) | 1 PR, 1 à 2 sessions. Pilote : l'installation de la migration |
| **PX-KYC-2 écran** | bandeau sur la fiche, file « Pièces lues, prêtes à valider », geste de lot, cinq états, textes fr/en/ar, captures R3 360/1440 | `lib/features/admin_candidature`, `admin_candidatures` | 1 PR, 1 à 2 sessions |
| **PX-KYC-3 mise en service** | secret posé par le directeur, ouverture du réglage, lecture du stock par paquets, relevé de concordance sur un échantillon relu, politique publiée | directeur et pilote | non estimable ici (dépend de D1 à D8) |

Ordre : D2 et D3 d'abord (ils peuvent changer le plan), puis PX-KYC-1, PX-KYC-2, PX-KYC-3.

### 5.2 Tests sans aucune vraie pièce

- **Images fictives** produites par un script versionné : un faux document dessiné (nom inventé, numéro inventé, photo =
  silhouette), en cinq variantes (nette, floue, expirée, mauvais nom, retouchée par un bloc de couleur) ; **jamais** la
  photo d'une personne réelle, **jamais** un modèle officiel reproduit. Elles ne portent aucun nom de la base.
- **Module pur** (Deno) : normalisation du nom, somme MRZ (jeux de valeurs publiés par l'organisme de normalisation des
  documents de voyage, donc sans personne), règles de proposition (tableau de vérité complet), refus d'un schéma invalide,
  neutralisation d'un texte piégé dans `nom_ecrit` (le texte reste une donnée, ne change aucune règle).
- **Client du fournisseur simulé** : l'Edge est testée avec des réponses fabriquées (bonne, hors schéma, trop longue,
  injection, panne, délai dépassé) : **une panne n'écrit jamais « non conforme »**.
- **Base** (scénarios rouge puis vert, sur base neuve) : un compte non direction ne lit rien ; un administrateur du
  mauvais genre ne lit rien ; `service_role` ne lit pas la table ; **Praxis ne lit ni la table ni la fonction** ; le lot
  refuse une pièce déjà décidée, une lecture périmée, plus de 50 pièces, un appel sans aal2 ; un refus en lot n'existe pas.
- **Un seul essai avec le vrai modèle** : sur le projet de **STAGING**, avec les images fictives, après que le directeur a
  posé une clé de **test** (D1). Mesure de la part de lectures correctes par modèle, pour fixer D7. Jamais sur la production
  avant PX-KYC-3.
- Preuve finale : comme toute étape, **le directeur la fait lui-même en production**. Un test vert n'est pas une preuve.

## 6. Ce que ce plan ne fait pas

Il ne lit pas de pièce, ne propose aucune comparaison de visages, ne touche ni aux gestes existants ni à `decider_dossier`,
ne donne aucune pièce à Praxis, ne déplace aucune pièce vers R2, ne modifie pas la durée de conservation de 90 jours.
