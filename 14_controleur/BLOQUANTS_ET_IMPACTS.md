# Contrôleur : bloquants avant la mise en service et impacts sur les autres rôles

Créé en CT-10 (02/10/2026). Sources : document 08 (`08_CONTROLEUR_V1_UX_SECURITE.md`) §3.4, §12, §13, §15 ; décisions du directeur du 27/09 (`00_DECISIONS_DIRECTEUR.md`, qui priment : C1 la visite a lieu pendant le cours, C2 le rapport part automatiquement à l'administration). Couverture serveur : `CT-BR.md` (BR-CT-01 à 19). Revue UX : `UX_REVIEW_08_CONTROLEUR.md`.

Cadre juridique : l'académie est une LTD anglaise, donc le droit du Royaume-Uni passe d'abord (UK GDPR, Data Protection Act 2018, ICO, Children's Code). Le RGPD européen reste un complément. Rien ici ne tranche un point légal : la démonstration ne fait que simuler (C21).

## 1. Bloquants avant la mise en service (doc §15)

Le document demande de ne pas les résoudre dans l'écran, mais de les marquer au tableau. Tant qu'ils sont ouverts, le Contrôleur reste une démonstration.

| N° | Bloquant | Pourquoi (règle, loi) | Qui décide | Déjà couvert par |
|---|---|---|---|---|
| B1 | Niveau de connexion exigé pour une observation privilégiée (§15.1). | Un contrôleur voit des élèves et un enseignant : accès à protéger plus fort qu'un compte ordinaire (UK GDPR, sécurité du traitement, art. 32). | Directeur, avec avis juriste ; serveur BR-1 pour l'application. | Rien |
| B2 | Double vérification (MFA / step-up) pour le Contrôleur (§15.2). | Même raison que B1 : compte à privilèges, risque de vol d'accès. | Directeur ; serveur BR-1. | Rien |
| B3 | Procédure exacte de retrait immédiat d'un accès Contrôleur (§15.3). | Un accès à privilèges doit pouvoir être coupé tout de suite (UK GDPR, sécurité). | Directeur (qui, comment, en combien de temps) ; serveur BR-1. | BR-CT-01 (révocation immédiate côté serveur) ; la procédure humaine : rien |
| B4 | Durée exacte de conservation des rapports (§15.4, §14.6). | Principe de limitation de la conservation (UK GDPR art. 5). | Directeur et juriste ; serveur BR-1. | Rien |
| B5 | Base légale du suivi des enseignants (§15.5, §14.3). | Tout traitement de données personnelles exige une base légale ; la surveillance de collaborateurs est encadrée par l'ICO. | Juriste, puis directeur. | Rien |
| B6 | Analyse d'impact sur la protection des données, DPIA (§15.6, §14.2). | Obligatoire avant un traitement à risque élevé, surtout avec des enfants (UK GDPR art. 35, ICO, Children's Code). | Juriste, puis directeur. | Rien |
| B7 | Politique de contestation d'un rapport par l'enseignant (§15.7). | Droits des personnes : accès, rectification, contestation (UK GDPR) ; équité envers l'enseignant. | Directeur et juriste. | Rien (BR-CT-17 ajoute des compléments sans réécrire le rapport, mais ne traite pas la contestation) |
| B8 | Traitement des données sensibles captées par hasard dans la vidéo ou l'audio (§15.8). | Minimisation et catégories particulières de données (UK GDPR art. 5 et 9) ; enfants. | Juriste et directeur ; serveur BR-1. | Rien |
| B9 | Transferts de données hors Royaume-Uni (§15.9, §14.8). | Transferts internationaux encadrés (UK GDPR chap. V, accord de transfert ICO). | Juriste ; directeur pour le choix des hébergeurs ; serveur BR-1. | Rien |
| B10 | Politique de capture d'écran et de filigrane (watermark) (§15.10, §8.4). | Limiter les fuites d'images d'élèves ; le filigrane est seulement proposé au doc §8.4. | Directeur (question 10 de la revue UX). | Rien (non construit en CT-3) |
| B11 | Un brouillon de compte rendu peut-il rester sur l'appareil ? (§15.11, §8.3). | Le document veut « pas de cache durable » : une donnée gardée sur le téléphone est un risque (UK GDPR, sécurité). | Directeur ; serveur BR-1. | En démonstration, le brouillon n'est qu'en mémoire (`compteRenduATerminerProvider`, CT-4) ; la vraie règle : rien |
| B12 | Information légale à donner aux élèves, parents et enseignants (§15.12, §14.1). | Transparence : surveillance non annoncée seulement si justifiée et prévenue à l'avance (ICO) ; Children's Code. | Juriste, puis directeur. | Le bandeau permanent « Cours enregistré, visite de contrôle possible » existe (revue UX, ligne 18) mais n'est pas une preuve de conformité ; le texte légal : rien |
| B13 | Qui peut lire un rapport brut (§15.13). | Accès limité au nécessaire (UK GDPR art. 5, 25). | Directeur et juriste ; serveur BR-1. | BR-CT-14 (seuls le contrôleur auteur et l'administration lisent) ; le cas des autres : rien |
| B14 | Qui peut exporter un rapport (§15.14). | Un export sort la donnée du circuit protégé. | Directeur ; serveur BR-1. | Rien |
| B15 | Qui peut connaître l'identité du Contrôleur après la publication mensuelle (§15.15, §3.4). | Équilibre entre protection du contrôleur et droit de réponse de l'enseignant. | Directeur et juriste. | Rien |

Note : BR-CT-08 (journal d'audit) est prévu côté serveur mais ne répond à aucun de ces points seul ; il aidera pour B3, B13 et B14.

### 1 bis. Décisions du directeur (02/10/2026, commentaires sur la planche CT)

Le directeur a répondu point par point. Il a confié le reste à l'orchestrateur : « le reste tu te débrouilles pour le bien de l'académie et de ses élèves ». Les choix marqués *orchestrateur* peuvent être repris par lui à tout moment. Ces points ne bloquent plus le Contrôleur : ils sont à appliquer au branchement (BR-1). Seule la DPIA (B6) reste à signer.

| N° | Décision | Ce qu'il faudra faire (BR-1, sauf mention) |
|---|---|---|
| B1 | Pour observer, le contrôleur doit être **connecté et approuvé par l'administration**. | Le serveur refuse l'entrée si la capacité Contrôle n'est pas approuvée (BR-CT-01). |
| B2 | Double vérification à la connexion : **oui**. | MFA pour tout compte qui a la capacité Contrôle. |
| B3 | **Un clic** de l'administration pour donner ou retirer l'accès ; le contrôleur reçoit une **notification** dans les deux cas. | Bouton côté admin (CT-IMP-AD-16) ; notification au contrôleur ; écran « accès retiré » déjà fait (CT-9). |
| B4 | Garder assez longtemps pour revoir et prendre les mesures. *Orchestrateur* : rapport brut **12 mois** après l'envoi, prolongé tant qu'un dossier ou une mesure est ouvert, puis supprimé ; synthèse sans nom d'élève gardée plus longtemps. | Effacement programmé côté serveur. |
| B5 | Les enseignants signent à l'inscription un **contrat qui annonce les visites de contrôle**. *Orchestrateur* : base légale = intérêt légitime (protection des enfants), avec test de mise en balance ; pas le consentement. | Clause au contrat enseignant (charte 09_consentements) ; politique de contrôle publiée. |
| B6 | Le directeur confie la DPIA à l'orchestrateur. | `DPIA_CONTROLEUR.md` (projet) ; signature du directeur ; avis d'un juriste conseillé avant la production. |
| B7 | L'enseignant peut contester, **mais pas trop facilement**. *Orchestrateur* : une demande par rapport, dans les 7 jours suivant la publication de la synthèse mensuelle, avec un motif écrit ; traitée par l'administration ; pas de bouton mis en avant. | Écran dans la vague Enseignant (CT-IMP-EN-02) ; file côté admin. |
| B8 | Les participants savent qu'ils ne sont pas en privé : risque faible. | Le contrôleur n'écrit que ce qui concerne le cours (ligne d'aide « Décrivez seulement ce que vous avez observé » déjà en place). |
| B9 | Aucun élève ni enseignant au Royaume-Uni ; données chez **Cloudflare, Europe de l'Ouest**. | Royaume-Uni vers EEE couvert par l'adéquation britannique ; vérifier les sous-traitants Cloudflare hors EEE (DPA, UK Addendum). |
| B10 | Capture bloquée : **oui**. Le filigrane **n'apparaît que lorsqu'une capture est tentée**, jamais en permanence. | Blocage de capture (Android) et détection (iOS) ; filigrane affiché à la tentative. |
| B11 | Le brouillon **ne sort jamais de l'application**. | Stockage local chiffré, hors sauvegarde et hors partage, effacé après l'envoi. |
| B12 | Élèves, parents et enseignants voient **le minimum possible**. | Bandeau permanent actuel, sans nom ni annonce en temps réel ; rien de plus. |
| B13 | Lecture d'un rapport brut : **l'administration** (et le contrôleur auteur, pour son propre rapport). | BR-CT-14 déjà conforme. |
| B14 | Export : **l'administration seulement**. | Export tracé au journal d'audit (BR-CT-08). |
| B15 | Identité du contrôleur après la synthèse mensuelle : **jamais révélée**. | La synthèse enseignant n'affiche aucun nom de contrôleur. |

### 1 ter. Bloquant technique du branchement (BR-1)

| N° | Bloquant | Pourquoi | Ce qu'il faudra faire (BR-1) |
|---|---|---|---|
| BR-CT-19 | « Commencer le contrôle » n'inscrit pas la visite : `observerEnControle` (RPC `rejoindre_observation`) n'est appelé nulle part ; le chemin par défaut va à `/salle` avec le billet seul (CTRL-BR-OBS-1, 04/10). | Sans inscription, le jeton de salle du contrôleur est refusé en réel et le passage n'est pas journalisé (BR-CT-08, B3, B13). | Appeler `observerEnControle` avant `/salle` ; n'entrer qu'en cas de succès ; un refus reste sur CTR-01 avec un message K-59. Détail : `CT-BR.md`, BR-CT-19. |

## 2. Ce que le Contrôleur change pour les autres rôles

### 2.1 Enseignant (doc §12 et §3.4)

Règle du document : ne pas reconstruire le rôle Enseignant maintenant ; l'ajouter plus tard sous le nom « ENS - Qualité et parcours professionnel ». Le rôle Enseignant a déjà sa vague (EN-0 fait ; reprise par `12_enseignant/00_REPRISE.md`) : rien de ceci n'y est construit.

| Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|
| Synthèse mensuelle des observations publiables : éléments positifs, points à suivre (§12). | Un écran enseignant de synthèse, publié à la fin du mois seulement (§3.4). | Vague Enseignant (à faire), puis BR-1 pour les données |
| Réponses et échanges autorisés avec le contrôle (§12). | Définir ce que l'enseignant peut répondre, et à qui. | Vague Enseignant (à faire) ; décision du directeur |
| Historique qualité, badges et responsabilités, éligibilité à certaines promotions (§12). | Écran d'historique qualité ; règles de badges et de promotion à fixer. | Vague Enseignant (à faire) ; décision du directeur |
| Aucune vitesse brute d'apprentissage des élèves comme score de l'enseignant (§12) ; la paie reste un domaine séparé. | Règle à respecter dans tout écran de synthèse. | Vague Enseignant (à faire) |
| Pas de notification immédiate « vous venez d'être observé » ; dates et heures exactes internes à l'administration (§3.4). | Ne jamais envoyer d'alerte à l'enseignant ; ne pas afficher l'heure exacte du contrôle. | Vague Enseignant (à faire) ; serveur BR-1 |

### 2.2 Administration (doc §13)

Rien à construire maintenant ; à enregistrer au registre de l'Administration finale. Le rôle admin est conçu en dernier (décision F2). Côté serveur, BR-CT-01, 07, 08, 10, 14 préparent une partie des points 1, 6, 8, 9, mais aucun écran admin n'existe.

| N° §13 | Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|---|
| 1 | Attribuer et retirer la capacité Contrôleur. | Écran de gestion des droits. | AD-X (rôle admin, conçu en dernier, décision F2) ; BR-1 (BR-CT-01) |
| 2 | Définir le périmètre d'un contrôleur. | Choix des classes ou groupes contrôlables. | AD-X ; BR-1 |
| 3 | Contrôleur externe permanent. | Procédure et compte spécifiques. | AD-X ; décision du directeur |
| 4 | Rotation et couverture des classes. | Vue de ce qui a été contrôlé et de ce qui ne l'a pas été. | AD-X ; BR-1 (BR-CT-03, 15) |
| 5 | Voir les missions réalisées en temps réel. | Tableau de suivi en direct. | AD-X ; BR-1 |
| 6 | File de rapports. | Liste des rapports reçus automatiquement (C2). | AD-X ; BR-1 (BR-CT-10, 14) |
| 7 | Signalements urgents. | Alerte pour « Intervention Admin souhaitée » et points importants. | AD-X ; BR-1 |
| 8 | Canal de discussion avec le Contrôleur. | Côté admin des fils (le contrôleur a déjà son écran Échanges). | AD-X ; BR-1 (BR-CT-07, 13) |
| 9 | Historique immuable. | Journal non modifiable des visites et rapports. | AD-X ; BR-1 (BR-CT-08, 17) |
| 10 | Détecter les contrôleurs qui valident mécaniquement tout. | Indicateurs de qualité des contrôles. | AD-X ; décision du directeur |
| 11 | Calibration entre contrôleurs. | Méthode de comparaison. | AD-X ; décision du directeur |
| 12 | Gestion des conflits d'intérêt. | Règles (ex. propre Classe exclue, déjà simulée par BR-CT-02). | AD-X ; BR-1 |
| 13 | Synthèse mensuelle de l'enseignant. | Validation et publication côté admin. | AD-X, avec la vague Enseignant (à faire) |
| 14 | Publier ou non un signal qualité aux familles. | Décision et réglage. | AD-X ; décision du directeur |
| 15 | Contrôleur ou évaluateur invité. | Compte temporaire borné. | AD-X ; BR-1 |
| 16 | Retrait immédiat d'un accès privilégié. | Bouton et procédure (lié à B3). | AD-X ; BR-1 |
| 17 | Revue périodique des privilèges. | Rappel et liste à revoir. | AD-X ; BR-1 |
| 18 | Accès au journal d'audit séparé de la gestion des droits. | Deux rôles distincts. | AD-X ; BR-1 |

### 2.3 Tuteur (doc §3.4)

| Impact | Ce qu'il faudra faire | Vague / étape |
|---|---|---|
| Pas de rapport RH brut montré à la famille (§3.4, décision). | Aucun écran tuteur n'affiche un rapport de contrôle. À vérifier à l'harmonisation. | HU-1 |
| Proposition : afficher seulement un signal du type « Suivi qualité Rewayah effectué ce mois-ci », si la Direction juge cela utile (§3.4, non décidé ; recoupe §13 point 14). | Attendre la décision ; si oui, une ligne non sensible dans l'espace Tuteur, alimentée par le serveur. | Décision du directeur, puis HU-1 et BR-1 |

## 3. Lignes à ajouter au tableau

Format : `ID | titre court | vague | attend (directeur / BR-1 / AD-X / rien) | note`

```
CT-BLQ-01 | Niveau de connexion pour observation privilégiée | Contrôleur (production) | directeur | doc 08 §15.1 ; non couvert ; avis juriste
CT-BLQ-02 | MFA / step-up du Contrôleur | Contrôleur (production) | BR-1 | doc 08 §15.2 ; non couvert
CT-BLQ-03 | Procédure de retrait immédiat d'un accès | Contrôleur (production) | directeur | doc 08 §15.3 ; BR-CT-01 couvre la technique, pas la procédure
CT-BLQ-04 | Durée de conservation des rapports | Contrôleur (production) | directeur | doc 08 §15.4 et §14.6 ; UK GDPR art. 5 ; avis juriste
CT-BLQ-05 | Base légale du suivi des enseignants | Contrôleur (production) | directeur | doc 08 §15.5 et §14.3 ; juriste UK ; ICO
CT-BLQ-06 | DPIA du contrôle | Contrôleur (production) | directeur | doc 08 §15.6 et §14.2 ; obligatoire avant production ; enfants (Children's Code)
CT-BLQ-07 | Contestation d'un rapport par l'enseignant | Contrôleur (production) | directeur | doc 08 §15.7 ; BR-CT-17 ne la traite pas
CT-BLQ-08 | Données sensibles captées par hasard (vidéo, audio) | Contrôleur (production) | directeur | doc 08 §15.8 ; juriste ; serveur BR-1
CT-BLQ-09 | Transferts hors Royaume-Uni | Contrôleur (production) | directeur | doc 08 §15.9 et §14.8 ; juriste ; choix des hébergeurs
CT-BLQ-10 | Capture d'écran et filigrane | Contrôleur (production) | directeur | doc 08 §15.10 et §8.4 ; question 10 de la revue UX ; non construit
CT-BLQ-11 | Brouillon de compte rendu sur l'appareil | Contrôleur (production) | directeur | doc 08 §15.11 et §8.3 ; en démonstration en mémoire seulement
CT-BLQ-12 | Information légale élèves, parents, enseignants | Contrôleur (production) | directeur | doc 08 §15.12 et §14.1 ; le bandeau permanent n'est pas une preuve de conformité
CT-BLQ-13 | Qui lit un rapport brut | Contrôleur (production) | directeur | doc 08 §15.13 ; BR-CT-14 couvre auteur et administration seulement
CT-BLQ-14 | Qui peut exporter un rapport | Contrôleur (production) | directeur | doc 08 §15.14 ; non couvert
CT-BLQ-15 | Identité du Contrôleur après publication mensuelle | Contrôleur (production) | directeur | doc 08 §15.15 et §3.4 ; avis juriste
CT-BLQ-19 | Inscrire la visite (observerEnControle) avant /salle | Contrôleur (production) | BR-1 | BR-CT-19 ; CTRL-BR-OBS-1 ; sans elle, jeton refusé en réel et passage non journalisé
CT-IMP-EN-01 | Synthèse mensuelle de l'enseignant | Enseignant (à faire) | BR-1 | doc 08 §12 et §3.4 ; publication différée en fin de mois ; positifs et points à suivre
CT-IMP-EN-02 | Réponses et échanges autorisés de l'enseignant | Enseignant (à faire) | directeur | doc 08 §12 ; périmètre des réponses à décider
CT-IMP-EN-03 | Historique qualité, badges, promotions | Enseignant (à faire) | directeur | doc 08 §12 ; règles de badge et d'éligibilité à fixer
CT-IMP-EN-04 | Aucune vitesse d'élève comme score d'enseignant | Enseignant (à faire) | rien | doc 08 §12 ; règle à respecter ; la paie reste séparée
CT-IMP-EN-05 | Pas d'alerte immédiate à l'enseignant observé | Enseignant (à faire) | BR-1 | doc 08 §3.4 ; dates et heures exactes internes à l'administration
CT-IMP-AD-01 | Attribuer et retirer la capacité Contrôleur | Admin | AD-X | doc 08 §13.1 ; BR-CT-01 côté serveur
CT-IMP-AD-02 | Définir le périmètre du contrôleur | Admin | AD-X | doc 08 §13.2
CT-IMP-AD-03 | Contrôleur externe permanent | Admin | directeur | doc 08 §13.3 ; puis AD-X
CT-IMP-AD-04 | Rotation et couverture des classes | Admin | AD-X | doc 08 §13.4 ; BR-CT-03 et 15
CT-IMP-AD-05 | Missions réalisées en temps réel | Admin | AD-X | doc 08 §13.5
CT-IMP-AD-06 | File de rapports reçus | Admin | AD-X | doc 08 §13.6 ; transmission automatique (C2) ; BR-CT-10 et 14
CT-IMP-AD-07 | Signalements urgents | Admin | AD-X | doc 08 §13.7
CT-IMP-AD-08 | Canal de discussion avec le Contrôleur (côté admin) | Admin | AD-X | doc 08 §13.8 ; BR-CT-07 et 13
CT-IMP-AD-09 | Historique immuable | Admin | AD-X | doc 08 §13.9 ; BR-CT-08 et 17
CT-IMP-AD-10 | Détection des contrôleurs qui valident tout | Admin | directeur | doc 08 §13.10 ; puis AD-X
CT-IMP-AD-11 | Calibration entre contrôleurs | Admin | directeur | doc 08 §13.11 ; puis AD-X
CT-IMP-AD-12 | Conflits d'intérêt | Admin | AD-X | doc 08 §13.12 ; BR-CT-02 simule l'exclusion de sa propre Classe
CT-IMP-AD-13 | Validation de la synthèse mensuelle enseignant | Admin | AD-X | doc 08 §13.13 ; lié à CT-IMP-EN-01
CT-IMP-AD-14 | Publier ou non un signal qualité aux familles | Admin | directeur | doc 08 §13.14 ; lié à CT-IMP-TU-02
CT-IMP-AD-15 | Contrôleur ou évaluateur invité | Admin | AD-X | doc 08 §13.15
CT-IMP-AD-16 | Retrait immédiat d'un accès privilégié | Admin | AD-X | doc 08 §13.16 ; lié à CT-BLQ-03
CT-IMP-AD-17 | Revue périodique des privilèges | Admin | AD-X | doc 08 §13.17
CT-IMP-AD-18 | Journal d'audit séparé de la gestion des droits | Admin | AD-X | doc 08 §13.18 ; BR-CT-08
CT-IMP-TU-01 | Aucun rapport de contrôle brut côté famille | Tuteur | rien | doc 08 §3.4 ; à vérifier à l'harmonisation HU-1
CT-IMP-TU-02 | Signal « Suivi qualité effectué ce mois-ci » | Tuteur | directeur | doc 08 §3.4 (proposition, non décidée) ; si oui, HU-1 et BR-1
```
