# PX-BRAS-DROIT : Praxis fait, en conversation, ce que le directeur fait en cliquant (étude et plan, phase 1)

- **Statut : ÉTUDE ET PLAN. Aucun code, aucune migration.** Écrit par BE-DOSSIER le 17/11/2026, sur ordre du pilote
  (demande du directeur, 17/11 : « Praxis, en mode chat, fait à ma demande tout ce que je fais en cliquant : déposer
  et configurer un document de la Bibliothèque, régler ce qui est réglable, publier, lire relevés de notes, relevés
  financiers et factures, préparer et appliquer les gestes de recrutement ; jamais de décision sensible sans moi »).
- Sources lues : `ACCES-PRAXIS.md` (21 domaines), `SECURITE-PRAXIS.md` (R1 à R15), le connecteur
  (`supabase/functions/_shared/praxis/outils.ts`, `mcp.ts`, `praxis-mcp`), la base rejouée en local (signatures des
  fonctions), `LOT-DEPOT-SIMPLE.md`. **Rien d'autre.** Aucune ligne de personne lue ; une seule requête de production, des
  compteurs (§9).

## 0. Faux, bloqué ou non prouvé (en premier)

1. **La demande, telle quelle, contredit cinq règles écrites** de `SECURITE-PRAXIS.md` (R3, R4, R5, R6, R12). Le plan ne
   les contourne pas : le §2 dit, règle par règle, ce que la demande exige et la décision datée qu'il faut au directeur.
   **Tant que ces décisions ne sont pas écrites, les outils concernés restent à construire en version bornée** (colonne
   « sans décision » du §5).
2. **« Confirmation explicite dans le chat » n'est pas vérifiable par le serveur.** Le chat est un modèle ; le serveur
   voit un appel d'outil, jamais une personne qui dit oui. Un modèle qui lit un document piégé peut enchaîner
   `preparer` puis `confirmer` sans que le directeur ait rien dit. **Le seul oui que le serveur peut prouver est celui
   donné dans l'application, en aal2.** D'où le code de confirmation hors bande (§4), proposé pour toute action sensible.
3. **Déposer un FICHIER depuis le chat n'est pas faisable de façon fiable** : un outil MCP reçoit du texte, pas le
   fichier que le directeur a joint à la conversation, et un PDF ou un audio en base64 dépasse ce qu'un outil peut
   porter. Le plan propose un lien de dépôt à usage unique (§5.1). **Non vérifié** : si le chat du directeur peut envoyer
   lui-même un fichier vers une URL signée (dépend de son environnement) ; à essayer sur STAGING avant de promettre.
4. **Rien n'est prouvé en production.** Tout ceci est lu dans le dépôt. Une clé Praxis existe en production (compteur,
   §9) : je ne sais ni son usage (chat ou routine), ni son état, ni qui s'en sert, et je ne l'ai pas lu.
5. **Certaines lectures demandées n'existent pas pour la direction** : il n'y a aucune fonction qui lit les factures
   d'un mois pour la direction (la table `factures_mensuelles` n'a que l'émission, `emettre_factures_mois`) ni un
   relevé de notes d'ensemble (`lire_resultats_evaluations` ne lit qu'UN élève). Elles sont à écrire (§5.5).
6. **Le jeu d'outils de chat doit rester fermé à la routine.** Aujourd'hui la séparation chat/routine est portée par la
   colonne `usage` de la clé (`chat` ou `routine`) ; il n'existe aucun outil réservé au chat. C'est un ajout (§3.3).

## 1. L'existant, ce qui sert tout de suite

| Quoi | Où | Ce que ça apporte au plan |
| :--- | :--- | :--- |
| Onze outils MCP : `etat`, `boite`, `fil`, `ecrire`, `annoncer`, `calendrier_lire`, `calendrier_ajouter`, `lire`, `preparer`, `rendre_compte`, `terminer` | `outils.ts` | Chacun appelle UNE fonction `praxis_*` (R1, R2) ; un registre à ajouter, pas à refaire |
| Clés `chat` et `routine`, émises par la direction en aal2, empreinte seule, 90 jours au plus, révocables | `private.praxis_cles` (`usage IN ('chat','routine')`), `direction_praxis_emettre_cle` | La clé « conversation » du directeur existe déjà comme notion |
| Niveau B : `praxis_preparer` écrit une PROPOSITION (72 h, 50 ouvertes), la direction la valide DANS L'APPLICATION par `direction_praxis_valider` sous SON identité | `20261129840000_praxis_preparer.sql` | Le modèle « Praxis propose, un humain valide » est installé ; seul l'endroit de la validation change (§4) |
| `praxis_lire` : vues fermées `candidatures` et `demandes`, sans contact, pièce, photo, ni montant | idem | Le gabarit des lectures masquées |
| Gestes de candidature servis par le serveur (clé `gestes`), 34 gestes au moteur, droits par mission (#565) | `private.candidature_gestes_regles`, `accorder_mission` | La liste des gestes de recrutement et leur contrôle existent |
| Interrupteurs : `praxis.actif`, `praxis.autonome`, `donnees_reelles`, mode essai, plafonds | `direction_praxis_regler*` | Tout nouvel outil de chat se range sous ces freins |
| Le journal à ajout seul de chaque appel | `private.praxis_journal` | À étendre, pas à recréer |

## 2. Les règles qui s'opposent, une par une (décisions datées du directeur à écrire)

| Règle | Ce que la demande exige | Option proposée | Décision à écrire |
| :--- | :--- | :--- | :--- |
| **R3** Praxis n'a aucun jeton de personne ; `auth.uid()` ne vaut jamais son identifiant | Appliquer « comme le directeur » : publier, régler, valider des gestes. Toutes les fonctions existantes décident à partir de `auth.uid()` | **Mécanisme à deux voies (§3)** : les lectures par vues masquées (aucune identité) ; les actions par un pont borné qui exécute UNE fonction d'une liste fermée sous l'identité du directeur qui a émis la clé, et rien d'autre. **Praxis garde son compte et n'obtient toujours aucun jeton** | « En mode chat, Praxis peut exécuter, à ma demande, une liste fermée d'actes sous mon identité, tracés `via Praxis` » |
| **R4** Le niveau D n'existe pas : refuser une personne, supprimer, bouger de l'argent, changer un droit ou un rôle, lire une pièce, modifier le garde-fou | « Appliquer » des gestes sensibles | **Le niveau D reste exclu** (liste §5.7). Le niveau S (sensible) n'est PAS le niveau D : il prévient une personne, publie ou engage l'académie, et passe par la confirmation hors bande | « Le niveau D reste interdit à Praxis, même en chat » ; ou la liste précise de ce qui en sort |
| **R5** Aucun outil ne rend un montant, un moyen de paiement, un contact, une pièce | Lire relevés financiers et factures | **Trois paliers** : (1) totaux et comptes par mois, sans personne ; (2) par personne en prénom seul et montant, **réservé à la clé de chat** ; (3) coordonnées de versement et moyens de paiement : **jamais**, ni en chat | Choisir le palier 1 ou 2 pour le chat ; le palier 3 reste interdit |
| **R6** Données d'enfants : compteurs seulement ; aucun fil ni public avec un mineur | Lire les relevés de notes ; annoncer | Notes : agrégats par étape et par classe, **jamais par élève mineur** ; par élève adulte seulement si le directeur le décide. Annonces : publics sans mineurs (inchangé) | Notes par élève : oui ou non, et pour quels âges |
| **R12** Il ne signe jamais au nom d'une personne | Les actes exécutés sous l'identité du directeur | Un acte exécuté par le pont est **l'acte du directeur** (comme s'il avait cliqué), tracé « demandé à Praxis, clé n° … ». Un MESSAGE ou une annonce restent écrits par Praxis, signés Praxis | Confirmer cette séparation |

## 3. Le mécanisme (le choix technique que le pilote tranche)

### 3.1 Lectures : des vues masquées, sans identité

Même chemin qu'aujourd'hui : `praxis_lire(vue, filtre)`, liste de vues fermée côté serveur, chaque vue appelle une
fonction existante et ne rend que des champs choisis. **Aucune identité de personne n'est utilisée.** Nouvelles vues au §5.

### 3.2 Actions : deux voies possibles, une recommandée

- **Voie A, le pont borné (recommandée).** Une fonction privée `private.praxis_agir(clé, geste, paramètres)` :
  vérifie la clé (chat, active, non expirée, interrupteurs), vérifie que `geste` est dans une **table fermée**
  (`private.praxis_actes` : nom, fonction appelée, schéma des paramètres, niveau, plafond), fixe pour la durée de la
  transaction l'identité du directeur qui a émis la clé (ses revendications `sub`, `role`, `aal`), appelle la fonction
  existante, remet l'identité d'origine. **Une seule logique pour les humains et pour Praxis, aucune copie.**
  - Avantage : chaque nouvel outil est une LIGNE de table et un test, pas une réécriture.
  - **Risque réel** : c'est une primitive d'usurpation d'identité dans la base. Elle n'est sûre que si (a) elle n'est
    appelable que par `service_role` depuis les fonctions `praxis_*`, jamais par un client ; (b) la table des actes est
    fermée et ne s'écrit que par migration ; (c) l'`aal` n'est « aal2 » que pour une action confirmée par le code (§4).
    **Elle exige la relecture du pilote contre `SECURITE-PRAXIS.md` (R15) et un scénario d'attaque par acte.**
- **Voie B, des fonctions internes (`private.*_interne`) avec l'auteur en paramètre**, comme `ACCES-PRAXIS.md` §2.3 le
  voulait. Plus pure, **beaucoup plus longue** : une extraction par fonction (la Bibliothèque en compte une dizaine,
  `decider_dossier`, `com_annonce_*`, les réglages écrivent aujourd'hui dans une table sans fonction), chacune avec le
  risque de diverger de la version humaine.

**Recommandation : la voie A pour les actions de la liste du §5, la voie B seulement si le pilote refuse tout
changement d'identité dans la base.** Le coût de la voie B n'est pas estimé ici.

### 3.3 Le chat seulement

- Table `private.praxis_actes` : colonne `modes` (`chat` seul, pour tous les actes de ce plan).
- `praxis_porte` rend déjà `usage` de la clé : chaque nouvelle fonction refuse `routine` avec la cause `chat_seulement`
  **avant tout appel**. Le registre Deno de `outils.ts` reçoit un champ `usage` et la liste des outils servie par `mcp.ts`
  est filtrée par l'usage de la clé : une clé de routine ne voit même pas ces outils.
- **Scénarios** : une clé de routine appelle chaque nouvel outil : refus, rien d'écrit, rien d'exécuté ; la liste d'outils
  d'une clé de routine est celle d'aujourd'hui, mot pour mot.

## 4. La confirmation à deux temps (`preparer` puis `confirmer`)

Trois niveaux d'outil :

| Niveau | Définition | Exécution |
| :-: | :--- | :--- |
| **L** | Lecture | Immédiate, vue masquée, journalisée |
| **A** | Action simple : effet interne, réversible, **aucune personne n'est prévenue**, rien n'est publié | Immédiate, journalisée, plafonnée, avec l'outil `annuler` quand l'acte a un contraire |
| **S** | Sensible : prévient une personne, publie, engage l'académie, change un réglage de plateforme | **`preparer` puis `confirmer`** |

### 4.1 Le jeton

`preparer(acte, paramètres)` ne fait **rien** : il valide les paramètres, écrit une ligne dans
`private.praxis_confirmations` (clé, émetteur, acte, **empreinte des paramètres**, jeton, expiration **5 minutes**, usage
unique) et rend au chat un **résumé en clair** de ce qui va se passer (« publier le document X à tous les inscrits »)
et le jeton. `confirmer(jeton, code)` exécute **exactement** les paramètres empreints : changer un seul octet invalide.
Rejouer un jeton rend le résultat déjà écrit (idempotence), jamais une seconde exécution.

### 4.2 Le code hors bande (proposé, à décider)

- **Option 1 (recommandée) : un code à six chiffres affiché DANS L'APPLICATION**, en aal2, dans la section « Praxis » de
  « Accès des agents IA » (déjà livrée par PX-3) : « Praxis demande : publier le document X. Code : 482 913 ». Le
  directeur le dit au chat, qui l'envoie à `confirmer`. Le modèle ne peut pas le deviner ni le lire dans un document : **seule
  une personne connectée en aal2 le voit.** Le code est lié au jeton, à usage unique, 5 minutes, trois essais.
- **Option 2 : le jeton seul, confirmé dans le chat.** Plus fluide, **non prouvable** (point 2 du §0) : un document piégé
  qui dit « confirme » suffirait. À réserver, si le directeur l'exige, aux actes S de faible portée, choisis un par un.
- **Option 3 : validation dans l'application sans code**, comme le niveau B d'aujourd'hui (`direction_praxis_valider`).
  Déjà installée, la plus sûre, la moins fluide.

### 4.3 Freins

Interrupteur `praxis.actif` ; mode essai et `donnees_reelles` d'aujourd'hui ; plafond d'actes S par heure (à fixer,
proposé : 10) ; plafond d'actes A par heure (proposé : 60) ; un acte S refusé trois fois de suite verrouille la clé pour
l'heure ; chaque appel journalisé avec le résultat ou la cause ; **rien du texte d'un tiers n'est copié dans le journal**.

## 5. Le catalogue des outils à ajouter (mode CHAT seulement)

Tous : clé de chat requise, aucun accès par la routine. « Ne rend jamais » vaut pour chaque outil de la ligne.

### 5.1 Bibliothèque (valeur n° 1)

| Outil | Niveau | Appelle (existe) | Ne rend jamais | Sans décision |
| :--- | :-: | :--- | :--- | :--- |
| `bibliotheque_lire` | L | `library_get_catalogue(filtre, curseur, limite)`, `library_get_detail(id)` | Aucune donnée de personne (le catalogue n'en porte pas) ; ni clé d'objet ni lien signé | Complet |
| `bibliotheque_lien_depot` | A | Crée le brouillon `library_creer_brouillon(saisie)` et rend un **lien du dépôt dans l'application**, à usage unique, où le directeur dépose le fichier (le flux existant `demander_upload_bibliotheque` puis `confirmer_upload_bibliotheque`, avec la signature HMAC, reste côté application) | Un lien de dépôt signé (le directeur l'ouvre lui-même) | Complet. **Le dépôt d'un fichier par le chat lui-même est exclu** (§0.3) |
| `bibliotheque_configurer` | A | `library_mettre_a_jour(id, modification, révision)` (nom, description, rayon) ; `library_attribuer(id, classes, épingler, révision)` | Rien de plus que ce qu'il écrit | Complet. La langue ne se corrige pas (note de `LOT-DEPOT-SIMPLE.md`) |
| `bibliotheque_acces` | S | `library_changer_acces(id, acces, révision)` (lecture seule ou téléchargement) | | Complet |
| `bibliotheque_publier` | S | `library_depot_direct(id, révision, clé, accès, **droit_tiers**, public)` ou `library_publier_version(id, version, révision, clé)` | | **`droit_tiers` n'est JAMAIS donné par le modèle** : c'est l'affirmation légale « l'académie a le droit de diffuser ». Le résumé de `preparer` la porte en toutes lettres et le code hors bande vaut accord personnel |
| `bibliotheque_retirer` | S | `library_retirer(id, motif, révision)` | | Complet |

**Production** : 2 documents seulement (§9) : l'outil n'a presque rien à lire aujourd'hui, mais c'est la première
valeur pour le directeur (« je ne vais jamais utiliser l'écran » : `LOT-DEPOT-SIMPLE.md`).

### 5.2 Recrutement (valeur n° 2)

Aujourd'hui : `lire('candidatures')` et `preparer` pour trois gestes (`demander_complement`, `planifier_entretien`,
`admettre_verifications`). Le chat ajoute l'**application** des gestes, sur la liste que le serveur sert déjà (clé `gestes`
de `capacites_candidatures()`, gestes du moteur de `private.candidature_gestes_regles`).

| Geste du moteur | Niveau en chat | Pourquoi |
| :--- | :-: | :--- |
| `definir_responsable`, `mettre_en_pause`, `lever_pause`, `noter_indisponibilite`, `lever_indisponibilite`, `rattacher` | **A** | Internes, réversibles, personne n'est prévenu |
| `planifier_entretien`, `deplacer_entretien`, `refaire_entretien`, `demander_complement`, `annuler_complement`, `annuler_admission`, `rouvrir`, `lever_restriction`, `inviter`, `consigner_prevenu` | **S** | Une personne est prévenue (courriel, notification) |
| `admettre_verifications`, `accepter_admission`, `preciser_admission`, `rouvrir_admission`, `consigner_entretien_tenu`, `consigner_entretien_non_tenu`, `dispenser_entretien` | **S** | Elles font avancer le dossier d'une personne |
| `valider_piece`, `demander_verification_piece`, `piece_a_corriger` | **Exclu (D)** | Elles décident sur une **pièce d'identité**, que Praxis ne lit jamais (R4). Le directeur la regarde et décide dans l'application |
| `refuser`, `retirer`, `restreindre` | **Exclu (D)** | Refuser, retirer ou restreindre une personne (R4) |
| `debloquer_versement`, `confirmer_moyen_paiement`, `infirmer_moyen_paiement`, `demander_verification_versement` | **Exclu (D)** | Argent et moyens de paiement (R4, R5) |
| `enregistrer_reponses`, `envoyer_reponses` | Hors sujet | Gestes du candidat lui-même |

Outils : `candidature_lire` (étend `lire('candidatures')`, **jamais** contact, pièce, photo, notes d'entretien, motif de
refus) ; `candidature_agir` (acte A) ; `candidature_preparer` puis `candidature_confirmer` (acte S). L'acte passe par la
même fonction que l'écran (`public.<geste>_candidat`), donc par le **moteur** : idempotence, version attendue, règles
d'étape, périmètre de genre de la direction qui a émis la clé. **Un acte hors du genre du directeur est refusé par le
moteur comme pour lui.**

### 5.3 Régler ce qui est réglable

Les réglages sont aujourd'hui des lignes de `app_config` (110 en production) écrites par l'écran
(`service_configuration.dart`, listes `clesRegles`, `clesFonctionnalites`, `clesObservation`, `clesPause`, `clesPriere`,
`clesRemplacement*`, `clesSorties`, `clesConservationDonnees`), **sans fonction de réglage générale** : l'écran écrit la
table directement sous la politique `app_config_admin_update`.

| Outil | Niveau | Appelle | Ne rend ni n'écrit jamais |
| :--- | :-: | :--- | :--- |
| `reglages_lire` | L | **À écrire** : `praxis_regler_lire(cles)`, liste blanche des clés de ces dix listes | Toute clé hors liste ; les secrets |
| `reglage_preparer` / `reglage_confirmer` | S | **À écrire** : `praxis_regler_ecrire(cle, valeur)` sous le pont, liste blanche, **bornes par clé** (le serveur d'aujourd'hui borne certaines valeurs par un `CHECK`, pas toutes : relevé à faire clé par clé avant la construction) | `kyc_exception_super_admin` (gardé par postgres seul, SEC-GARDE-5), `kyc_retention_days` et `recording_retention_days` (durées promises aux personnes), les clés `praxis.*` (R4 : « modifier le garde-fou, ses propres réglages »), les tarifs |

### 5.4 Publier

| Outil | Niveau | Appelle | Note |
| :--- | :-: | :--- | :--- |
| `annoncer` (existe) | S en chat | `praxis_annoncer` : publics SANS mineurs, 2 par jour | En chat, passe par `preparer`/`confirmer` ; **un public avec des enfants reste interdit** (R6) sauf décision du directeur |
| `calendrier_publier` | S | `calendrier_ecole_publier(id, publié)` | Rend visible une date aux familles |
| `politique_publier` | **Exclu en vague 1** | `publier_politique_commerciale(politique)` | Touche aux prix : demande la décision du directeur sur l'argent (§2, R4) ; à ne pas construire avant |
| `offre_publier` | À relever | Les offres publiées par l'administration (`DECISION-OFFRES-GROUPES`) : la fonction exacte n'est pas relevée ici | À préciser avant tout lot |

### 5.5 Lire relevés de notes, relevés financiers et factures

| Outil | Niveau | Appelle | Ce que le chat reçoit | Ne rend jamais |
| :--- | :-: | :--- | :--- | :--- |
| `notes_lire` | L | **À écrire** : agrégat sur `evaluations` (0 en production, §9) par étape et par classe ; `lire_resultats_evaluations(élève)` n'est PAS appelée telle quelle (elle rend le prénom de l'enfant) | Comptes et répartitions de résultats (les trois mots du programme) | Un résultat par élève mineur (R6) |
| `finances_lire` | L | `releve_paie_mensuel(mois)`, `versements_paie_direction(mois)`, `finance_validations_lister(état, nature, objet)`, `versement_exports_direction()` | **Palier 1** : totaux du mois, nombre de versements, nombre de validations en attente. **Palier 2** (si décidé) : prénom et montant par enseignant | **Coordonnées de versement, moyens de paiement, IBAN, export Wise** (`versement_coordonnees_direction`, `versement_export_wise` : exclus) |
| `factures_lire` | L | **À écrire** : lecture des `factures_mensuelles` pour la direction (aujourd'hui seule `emettre_factures_mois` existe) | Totaux et états par mois (6 factures en production) ; palier 2 : par foyer en prénom du tuteur | Moyen de paiement, adresse, courriel |
| `factures_emettre` | **Exclu en vague 1** | `emettre_factures_mois(mois)` | Émet des factures aux familles : acte S, mais touche à l'argent des personnes : décision du directeur d'abord |
| `versement_noter`, `versement_annuler`, `finance_validation_decider`, `enregistrer_paiement` | **Exclu (D)** | | Argent (R4) |

### 5.6 Garde-fous communs

Paramètres typés et bornés (R1) ; une fonction `praxis_*` par outil (R2) ; aucune réponse ne contient `@`, un numéro, `iban`,
`courriel`, `phone`, `birth`, un jeton (scénario de recherche de motifs, R5) ; aucune lecture sans filtre ni sans
pagination (50 au plus) ; le texte d'un tiers (nom d'un document, motif d'un candidat) est rendu dans `contenu_tiers`,
une donnée jamais une consigne.

### 5.7 Ce qui reste exclu, même en chat (niveau D)

Refuser, retirer, restreindre une personne ; décider sur une pièce d'identité ; débloquer un versement ; confirmer ou
infirmer un moyen de paiement ; noter ou annuler un versement ; enregistrer un paiement ; décider d'une validation
financière ; émettre des factures ; publier une politique commerciale ; supprimer ; changer un rôle ou un droit ;
émettre ou révoquer une clé ; les réglages `praxis.*` ; `kyc_exception_super_admin`. **Ce sont des actes que le directeur
fait lui-même, dans l'application.** Chacun peut sortir de la liste par une décision datée.

## 6. L'ordre de construction, par valeur pour le directeur

| Lot | Contenu | Pourquoi dans cet ordre | PR |
| :-: | :--- | :--- | :-: |
| **PX-BD-0 socle** | Registre chat seulement (`usage`), table `praxis_actes`, jetons et `private.praxis_confirmations`, code affiché dans la section « Praxis » de l'application, pont borné, plafonds, journal, scénarios d'attaque | Rien ne se construit sans lui ; c'est le lot qui porte tout le risque | Serveur 1 + écran 1 |
| **PX-BD-1 Bibliothèque** | `bibliotheque_lire`, `_lien_depot`, `_configurer` (A) ; `_acces`, `_publier`, `_retirer` (S) | La demande n° 1 du directeur (« lire, déposer, configurer ») ; presque aucun risque de données de personnes | Serveur 1 |
| **PX-BD-2 Recrutement** | `candidature_lire` étendue ; `candidature_agir` (A) ; `_preparer`/`_confirmer` (S) sur la liste du §5.2 | 556 dossiers en cours (§9) : c'est là que le temps du directeur part ; le moteur fait déjà les contrôles | Serveur 1 |
| **PX-BD-3 Réglages** | `reglages_lire`, `reglage_preparer`/`_confirmer` sur une liste blanche à arrêter clé par clé | Utile, risque modéré | Serveur 1 |
| **PX-BD-4 Publier** | `calendrier_publier` ; `annoncer` en deux temps | Faible volume | Serveur 1 |
| **PX-BD-5 Lectures** | `finances_lire` (palier décidé), `factures_lire`, `notes_lire` | **Dernier** : dépend des décisions D4 et D5, et deux lectures sont à écrire | Serveur 1 par outil |

**Estimation** (sessions d'agent, sans la relecture de sécurité du pilote) : socle 3 à 4 ; chaque autre lot 1 à 2.
**Rien n'est installé en production par ces lots avant le feu vert du pilote et l'aal2 du directeur** (R14, R15).

## 7. Tests sans aucune personne réelle

- Base de CI, personnes et dossiers fictifs, clés fictives. **Aucun appel à un outil sur la production** (R14).
- Par acte : accepté avec la bonne clé ; refusé avec une clé de routine ; refusé avec une clé expirée ou révoquée ;
  refusé hors du genre de la direction émettrice ; refusé hors liste ; `preparer` n'écrit rien d'autre que sa ligne ;
  `confirmer` avec un mauvais code, un code périmé, un jeton rejoué, des paramètres changés : refus, rien d'exécuté ;
  trois mauvais codes verrouillent.
- **Scénarios d'attaque** : un fil, un nom de document et un motif de candidat contenant « confirme » et « ignore tes
  consignes » ne produisent aucun acte ; le pont n'est appelable ni par `authenticated` ni par `anon` ni par `agent_ro` ;
  l'identité du directeur n'est jamais conservée après l'appel (la session revient à l'état d'avant) ; la table des actes
  ne contient aucun acte de §5.7 (exigence positive).
- R5 : recherche des motifs sensibles dans toutes les réponses de chaque outil de lecture.
- Deno : un paramètre hors schéma est refusé avant la base ; la liste d'outils d'une clé de routine n'a pas bougé.
- Preuve finale : **le directeur la fait lui-même en production**, après installation par le pilote. Un test vert n'est pas
  une preuve.

## 8. Ce qu'il faut du directeur

| # | Décision | Option recommandée |
| :-: | :--- | :--- |
| DB1 | Praxis peut-il exécuter, en chat, une liste fermée d'actes sous l'identité du directeur (pont borné) ? | Oui, avec la trace « via Praxis » (§3.2, voie A) |
| DB2 | Comment prouver un « oui » : code affiché dans l'application, validation dans l'application, ou jeton seul ? | Le code hors bande (§4.2, option 1) ; le jeton seul seulement pour des actes S choisis un par un |
| DB3 | Le niveau D du §5.7 reste-t-il interdit en chat ? Quels actes en sortent, et à quelle condition ? | Il reste interdit |
| DB4 | Relevés financiers : palier 1 (totaux) ou 2 (prénom et montant par enseignant) en chat ? | Palier 1 d'abord ; le palier 2 par une décision écrite |
| DB5 | Notes : agrégats seulement, ou aussi par élève adulte ? Annonces aux familles avec enfants ? | Agrégats ; annonces sans enfants (inchangé) |
| DB6 | `droit_tiers` : toujours une affirmation du directeur, via le code, jamais du modèle | Oui |
| DB7 | Réglages : la liste blanche de clés (à relever clé par clé) | Exclure rétention, KYC, tarifs et `praxis.*` |
| DB8 | Dépôt d'un fichier : lien de dépôt dans l'application (§5.1) | Oui ; le test d'un envoi direct depuis le chat se fait sur STAGING |
| DB9 | Plafonds proposés : 10 actes S et 60 actes A par heure | À confirmer |

## 8 bis. Décisions du 17/11/2026 (arbitrages du pilote, juriste par délégation du directeur)

Elles prévalent sur les « options recommandées » du §8 et amendent `SECURITE-PRAXIS.md` pour le seul mode chat.

| # | Décision |
| :-: | :--- |
| DB1 | **OUI** au pont borné `private.praxis_agir` : `service_role` seul, table d'actes fermée par migration, trace « via Praxis », clé de chat seulement. Relecture R15 par le pilote avant toute installation |
| DB2 | La preuve du oui est le **code à six chiffres** affiché dans la section Praxis de l'application (aal2), 5 minutes, usage unique, **valable pour un LOT préparé entier** (un code pour « appliquer ces 40 relances »), pas un code par geste |
| DB3 | La liste D du §5.7 est acceptée telle quelle |
| DB4 | Finance : **en mode chat seulement**, lecture des totaux ET des factures et relevés tels que la direction les voit déjà (c'est le directeur qui lit par Praxis), journalisée ; **jamais en routine** (amende R5 pour le chat, palier 2 du §5.5) |
| DB5 | Notes : chat seulement, ce que la direction voit déjà, journalisé |
| DB6 | `droit_tiers` est toujours une affirmation personnelle du directeur (jamais du modèle) |
| DB7 | Réglages : liste blanche fermée par migration, `praxis.*` exclus |
| DB8 | Dépôt par lien dans l'application d'abord ; l'envoi direct par le chat à essayer ensuite |
| DB9 | Plafonds : 10 actes S et 60 actes A par heure |

Feu vert : **PX-BD-0 (socle)** puis **PX-BD-Bibliothèque**, une PR par lot ; migration `20261129960000` attribuée ;
la connexion du chat du directeur (en-tête fixe ou OAuth) est un lot à part, traité par le pilote : le socle fonctionne
avec une clé « conversation » existante.

## 9. Mesures en production (compteurs, une requête, aucune ligne de personne, 17/11/2026)

| Quoi | Compteur |
| :--- | ---: |
| Documents de la Bibliothèque | **2** |
| Factures mensuelles | **6** |
| Versements de paie | **0** |
| Évaluations | **0** |
| Candidatures en cours | **556** |
| Réglages (`app_config`) | **110** |
| Clés Praxis | **1** (usage et état non lus) |

Lecture : la Bibliothèque et les relevés ont presque rien à lire aujourd'hui ; le recrutement a 556 dossiers en cours.
**C'est la valeur du recrutement qui justifie le socle, pas la Bibliothèque.** Le directeur choisit.

## 10. Ce que ce plan ne fait pas

Il n'écrit aucune fonction, ne crée aucune clé, n'appelle aucun outil sur la production, ne modifie ni `SECURITE-PRAXIS.md`
ni `ACCES-PRAXIS.md` (ils prévalent tant qu'une décision datée du directeur ne les amende pas), ne donne aucun accès à
une pièce d'identité, et ne touche à aucun acte du §5.7.
