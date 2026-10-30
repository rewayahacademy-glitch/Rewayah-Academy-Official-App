# Fiche courte : admission, lot C (listes de la direction, gestes, e-mails), 30/10/2026

Décision : `DECISION-ADMISSION-2026-10-27.md`, §3, §4 et §7 (lot C). Branche `claude/admission-c`, partie de `claude/admiring-brown-r6ai72-admission-b` (`cd3979e45`) en supposant B fusionné tel quel (consigne du pilote du 30/10). Migrations numérotées `2026103014xxxx`. Écrite avant de construire, parce que des règles manquent (§3).

## 1. Ce qui existe déjà (lu dans le code et la base de test locale)

- Le moteur des gestes des candidatures (`private.candidature_geste_ouvrir`, `_appliquer`, `_conclure`) et sa table de règles `private.candidature_gestes_regles`, sans notion de population : une règle vaut pour toute demande dont l'étape, l'état et l'issue correspondent.
- **Refuser** (`refuser_candidat`) est déjà permis depuis `recue`, donc pour une famille ; motif interne et modèle de message exigés.
- **Annuler un refus** : `rouvrir_candidat` (de `refusee` à `en_cours`) existe ; il n'a pas de délai.
- **La liste** : `lister_candidatures(p_filtre, …)` accepte déjà un type ; depuis le lot B, sans type, elle ne montre pas les familles.
- **Le moteur borne chaque geste au genre** du membre de la direction (règle des enseignants, CAND-Q07 : la pièce d'identité est relue par une personne du même genre).

## 2. Ce que je construis (sauf réponse contraire)

1. **Deux listes** dans l'administration, « Demandes des familles » et « Demandes des élèves adultes », séparées de celle des enseignants : la plus ancienne d'abord, compteur « à traiter », recherche par nom, e-mail et référence, pagination. Chaque ligne : nom, référence, date, et ce que la demande porte (prénoms, âges, niveaux, langue, moments).
2. **Accepter** (nouveau geste, règle de `recue` vers `confirmee`, familles et élèves adultes seulement) : dans une transaction, la demande passe à `confirmee`, le compte devient actif, chaque enfant de la demande reçoit son profil élève (comme `creer_profil_enfant`, cohorte d'après l'âge, réponses rangées), puis l'e-mail « Votre demande est acceptée » part par la file. La personne entre dans son espace à la prochaine ouverture.
3. **Refuser** : le geste existant, avec un motif interne et un modèle de message court pour la famille (« Nous ne pouvons pas donner suite », motif court choisi pour elle) ; e-mail par la file.
4. **Demander des précisions** : variante de la règle existante depuis `recue` (la demande passe « à compléter ») ; e-mail « Il nous manque une information », avec le lien vers sa page d'attente, qui dit ce qui manque.
5. **Contacter** : un message libre de la direction, envoyé par la file (aucun changement d'état), tracé au journal de la demande.
6. **Annuler pendant sept jours** : un refus s'annule par `rouvrir_candidat`, borné à sept jours pour les familles et les élèves adultes ; une acceptation s'annule de même (voir Q2).

## 3. Ce qui manque, à trancher

| # | Question | Ma proposition |
|---|---|---|
| Q1 | La règle « un geste seulement sur une demande du même genre que le membre de la direction » (enseignants) vaut-elle pour les familles ? | Non : aucune pièce d'identité n'est relue ; tout membre actif de la direction traite toute famille. |
| Q2 | Annuler une acceptation dans les sept jours : que deviennent le compte et les profils des enfants déjà créés ? | Le compte repasse en attente, les profils d'enfants sont retirés de la vue (jamais effacés) ; refusé si un enfant est déjà inscrit dans une classe. |
| Q3 | « Contacter » : le message part de quelle adresse, et la réponse va où ? | De `inscriptions@`, réponse à la même adresse (comme les autres e-mails d'admission). |
| Q4 | Acceptation groupée (« possible », §3) et redemande après trente jours (§5) : dans ce lot ? | Non : lot E, une règle par PR. |
| Q5 | La délégation d'une liste à un membre du personnel (capacité par population) : dans ce lot ? | Non : lot E. |

## 4. Réponses (pilote, par délégation du directeur, 30/10/2026)

- **Q1** Non : la règle du genre ne vaut pas pour les familles ni les élèves adultes (aucune pièce d'identité n'est relue).
- **Q2** Proposition acceptée telle quelle.
- **Q3** Aucune adresse nouvelle : l'expéditeur et l'adresse de réponse déjà configurés du système d'e-mails (catégorie `inscription`, `inscriptions@`, migration `20261023170000_courriels_adresses.sql`).
- **Q4, Q5** Lot E. La preuve de C reste celle du §7 : accepter une famille test, en refuser une autre.
- **Règle nouvelle** : aucune migration n'exécute `DROP`, `DELETE` ni `TRUNCATE` à l'application. Une fonction dont la signature change est renommée, passée dans `private`, `SECURITY INVOKER`, sans droits.

## 5. Écarts en construisant (30/10)

- **Les profils des enfants ne naissent pas dans la transaction de l'acceptation** (§2, point 2). Un profil d'élève exige un utilisateur d'authentification, que seule la fonction Edge `creer-profil-enfant` sait créer (clé de service) ; la base ne le peut pas. L'acceptation rend le compte actif ; l'application du tuteur crée les profils à sa première ouverture de l'Accueil, par cette fonction, puis lie chaque profil à son enfant de la demande (`lier_apprenant_profil`, qui range genre, niveau, objectif et langue). La création n'étant pas idempotente, le serveur propose un « profil probable » (même prénom dans le foyer, lié à aucun enfant) pour qu'une réponse perdue ne fasse pas de doublon.
- **Sans `DROP`, aucune contrainte n'est élargie** : une demande « à compléter » passe à l'étape `prequalification` avec l'état `a_completer`, paire que `candidatures_etat_coherent` admet déjà ; les gestes ont leurs règles propres (`accepter_admission`, `preciser_admission`, `rouvrir_admission`, `annuler_admission`) au lieu de nouvelles conditions ; les délais de sept jours sont vérifiés dans les fonctions.
- **Q2** : annuler une acceptation remet la demande à `recue`, le compte en attente (`pending_kyc`), les profils des enfants liés en `disabled` (jamais effacés) ; refusé si un enfant est dans une classe (`groupe_membres` sans date de sortie) ou si l'acceptation a plus de sept jours. Une nouvelle acceptation rend leurs profils aux enfants. Aucun e-mail n'est envoyé.
