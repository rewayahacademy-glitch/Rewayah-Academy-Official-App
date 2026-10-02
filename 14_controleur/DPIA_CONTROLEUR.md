# DPIA du rôle Contrôleur (projet)

**Statut.** Projet, rédigé le 02/10/2026 par l'orchestrateur, à la demande du directeur (B6 : « à toi de le faire »). Il n'est pas valable tant que le directeur ne l'a pas signé (partie 7). L'avis d'un juriste est recommandé avant la production.

**Cadre.** UK GDPR, art. 35 ; Data Protection Act 2018 ; guide et modèle de DPIA de l'ICO ; Children's Code de l'ICO. Le RGPD (UE) s'applique en complément pour les élèves et enseignants de l'Union européenne.

**Sources internes.** Document du directeur `ressources/specs/08_controleur/08_CONTROLEUR_V1_UX_SECURITE.md` (cité « doc 08 ») ; `00_DECISIONS_DIRECTEUR.md` (27/09, C1 et C2) ; `14_controleur/BLOQUANTS_ET_IMPACTS.md` (B1 à B15 et décisions du 02/10) ; `14_controleur/CT-BR.md` (BR-CT-01 à 17) ; `14_controleur/UX_REVIEW_08_CONTROLEUR.md` (sources ICO).

**Sources ICO** (reprises de UX_REVIEW_08, aucune autre adresse n'est ajoutée) :

| Code | Source | Adresse |
|---|---|---|
| ICO-MW | Employment practices and data protection: monitoring workers | https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/employment/monitoring-workers/ |
| ICO-DPIA | DPIA obligatoire pour une surveillance à risque élevé (sous-page de ICO-MW) | même adresse que ICO-MW |
| ICO-AADC | Age appropriate design: a code of practice for online services (Children's Code) | https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/ |
| ICO-AADC-11 | Children's Code, standard 11 (contrôles parentaux) | https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/11-parental-controls/ |

Le guide général de l'ICO sur les DPIA et son modèle n'ont pas été relus en ligne pour ce projet : la structure suit les sept étapes demandées. **À faire** : relire le guide DPIA général de l'ICO et noter son adresse exacte.

**Lecture du document.** Chaque partie a deux colonnes de fait : « Démonstration » (ce que l'application fait déjà, sans serveur, données inventées) et « BR-1 » (ce qui reste à faire au branchement du serveur). « À faire » signale une information qui manque. Rien n'est inventé.

---

## 1. Besoin d'une DPIA

Une DPIA est obligatoire avant la mise en service. Raisons :

- **Surveillance de travailleurs.** Le contrôleur observe l'enseignant sans annonce en temps réel. L'ICO dit qu'une DPIA est obligatoire pour toute surveillance de travailleurs à risque élevé (ICO-MW, ICO-DPIA).
- **Enfants.** Beaucoup d'élèves sont mineurs. Le Children's Code, standard 2, demande une DPIA pour un service en ligne que des enfants utilisent (ICO-AADC).
- **Vidéo et son en direct.** Le contrôleur voit et entend la séance.
- **Évaluation de personnes.** Les rapports peuvent avoir un effet sur la carrière de l'enseignant (responsabilités, badges, promotions, doc 08 §12 et §14.2).
- **Données qui révèlent une religion.** Un cours de Coran révèle, au moins en partie, la conviction religieuse des participants. C'est une catégorie particulière de données (UK GDPR art. 9).
- **Accès depuis plusieurs pays.** Élèves, enseignants et contrôleurs sont dans des pays différents (doc 08 §14.8).

Le doc 08 §14.2 le dit déjà : aucune ouverture réelle du module sans DPIA.

| Démonstration | BR-1 |
|---|---|
| Le Contrôleur n'existe qu'en démonstration, avec des données inventées (C21). Aucune donnée réelle n'est traitée. | Signature de cette DPIA avant toute ouverture réelle. Révision de la DPIA à chaque changement important (nouveau pays, nouveau sous-traitant, enregistrement, usage pour la paie). |

---

## 2. Description du traitement

### 2.1 Nature : ce que l'on fait des données

1. **Attribution d'une mission.** Le serveur choisit une Classe en direct pour un contrôleur approuvé (BR-CT-03). La propre Classe du contrôleur est exclue (BR-CT-02, doc 08 §9.4).
2. **Observation.** Le contrôleur entre dans la salle en direct. Il voit le support, la vidéo de l'enseignant et les vignettes des élèves autorisées. Il entend le son s'il l'active. Il n'a ni micro, ni caméra, ni chat, ni annotation (doc 08 §8, UX_REVIEW n° 4). Il n'enregistre rien.
3. **Faits automatiques.** Le système calcule l'heure prévue, l'heure réelle, le retard, la durée, les reconnexions et les présents (doc 08 §1.1, BR-CT-04). Le contrôleur ne les ressaisit pas.
4. **Compte rendu.** À la sortie, la visite et ses faits sont transmis automatiquement à l'administration (C2, BR-CT-10). Le contrôleur ajoute « Rien à signaler » ou une observation : nature, domaine, personne concernée (enseignant, Classe, élève précis ou personne), texte libre (BR-CT-11).
5. **Compléments.** Le contrôleur peut ajouter un complément. Le rapport d'origine n'est jamais réécrit (BR-CT-17).
6. **Échanges.** Un fil par mission entre le contrôleur et l'administration (BR-CT-13).
7. **Mission non contrôlée.** Si la mission n'est pas faite, le serveur envoie un rapport « groupe non contrôlé » (BR-CT-15).
8. **Journal d'audit.** Attribution et retrait de l'accès, entrées, sorties, refus, rapports, lectures, exports (doc 08 §10, BR-CT-08).
9. **Synthèse mensuelle.** L'enseignant reçoit en fin de mois une synthèse : points positifs et points à suivre. Pas de nom de contrôleur, pas d'heure exacte de visite (doc 08 §3.4, B15).
10. **Usage par l'administration.** Lecture des rapports bruts, mesures à prendre, export si besoin (B13, B14).

**Hors champ de cette DPIA.** L'enregistrement du cours annoncé par le bandeau « Cours enregistré » relève de la Classe, pas du Contrôleur. Le contrôleur n'a pas accès aux enregistrements passés (doc 08 §8.2). **À faire** : vérifier qu'une DPIA de la Classe (visio, enregistrement) existe ou l'écrire.

### 2.2 Portée : quelles données, sur qui, combien, combien de temps

| Personnes | Données | Source |
|---|---|---|
| Enseignant observé | Nom d'affichage professionnel, photo, image et voix en direct, faits de séance, appréciation écrite du contrôleur, synthèse mensuelle | doc 08 §8.1, BR-CT-04, BR-CT-14 |
| Élèves (souvent mineurs) | Prénom, initiale du nom (liste des présents), identifiant pédagogique, vignette (initiales et prénom, UX_REVIEW question 11), image et voix en direct, éventuelle observation qui les nomme | doc 08 §8.1, BR-CT-05, BR-CT-12, BR-CT-16, CT-BR CT-7 suite |
| Contrôleur | Identité, capacité (dates, périmètre), connexions, actions au journal, rapports écrits, messages | doc 08 §9.2, §10 |
| Administration | Identité des lecteurs et auteurs de messages, actions au journal | doc 08 §10 |

Données interdites au contrôleur : courriel et téléphone des familles, adresse, identité légale complète d'un mineur, documents d'identité, paiements, appareils, notes administratives, rémunération, messages privés, exports, enregistrements passés (doc 08 §8.2).

Catégorie particulière : la conviction religieuse est déduite de la participation à un cours de Coran (art. 9). D'autres données sensibles peuvent être entendues par hasard (santé, famille) ; B8 les juge à faible risque (voir R6).

**Volume.** **À faire** : nombre de Classes, d'élèves, d'enseignants et de contrôleurs, nombre de visites par semaine (doc 08 §11.1 parle d'un minimum hebdomadaire par Classe, sans chiffre).

**Conservation (B4, choix de l'orchestrateur, à reprendre par le directeur).** Rapport brut : 12 mois après l'envoi, prolongé tant qu'un dossier ou une mesure est ouvert, puis supprimé. Synthèse sans nom d'élève : gardée plus longtemps (**à faire** : fixer la durée). Brouillon : effacé après l'envoi (B11). **À faire** : durée du journal d'audit, des fils d'échanges, d'un brouillon jamais envoyé, et de la capacité d'un contrôleur retiré.

**Lieux.** Données stockées chez Cloudflare, en Europe de l'Ouest (B9). Aucun élève ni enseignant au Royaume-Uni. **À faire** : pays des contrôleurs ; hébergeur et lieu du service vidéo en direct (le doc 08 §17 cite LiveKit ; lieu non connu ici).

### 2.3 Contexte

- **Responsable du traitement** : Rewayah Academy, LTD anglaise (Companies House). **À faire** : numéro de société, inscription et redevance auprès de l'ICO, contact confidentialité (doc 08 §14.1).
- **Relation avec les enseignants.** Les enseignants travaillent à distance, souvent seuls en ligne avec des enfants, dans d'autres pays. Ils signent à l'inscription un contrat qui annonce des visites de contrôle de temps en temps (B5). Il y a un déséquilibre de pouvoir entre l'académie et l'enseignant (doc 08 §14.3).
- **Relation avec les élèves.** Enfants et adultes ; les parents (tuteurs) inscrivent les enfants. Les participants savent qu'ils sont dans une salle avec d'autres personnes (B8).
- **Attentes raisonnables.** Un enseignant prévenu par contrat et par une politique publiée peut s'attendre à des visites non annoncées. Un enfant voit en permanence le bandeau « visite de contrôle possible » ; il ne sait pas quand un contrôleur est là (B12).
- **Points d'attention.** Personnes vulnérables (enfants) ; pays multiples ; nouveauté du dispositif (visite discrète en visio) ; doc 08 §14.1 : « cela ne doit pas devenir une surveillance secrète juridiquement non documentée ».
- **Droit applicable.** UK GDPR d'abord. Le RGPD peut aussi s'appliquer, car l'académie offre ses cours à des personnes dans l'UE (art. 3.2 du RGPD). **À faire, juriste** : faut-il un représentant dans l'UE (art. 27 du RGPD) ? Faut-il désigner un DPO (traitement à grande échelle de données religieuses ? art. 37) ?

### 2.4 Finalités

1. **Protéger les enfants.** Ne pas laisser un enseignant seul en ligne avec des enfants sans aucune surveillance (B5).
2. **Garantir la qualité promise.** Vérifier que le cours réel correspond à ce que l'académie promet (doc 08 §1.1).
3. **Permettre à l'administration d'agir.** Relever un problème et prendre les mesures nécessaires (B4).
4. **Aider l'enseignant à progresser.** Synthèse mensuelle avec les points positifs et les points à suivre (doc 08 §12).

Finalités exclues : la paie reste séparée ; aucune vitesse d'apprentissage d'élève ne sert de note à l'enseignant (doc 08 §12) ; toute autre réutilisation doit être documentée et validée (doc 08 §14.5). Aucune décision n'est prise automatiquement : un humain décide toujours (UK GDPR art. 22).

| Démonstration | BR-1 |
|---|---|
| Parcours complets simulés : mission, salle sans micro ni caméra, compte rendu, complément, échanges, historique. Commandes interdites non rendues (UX_REVIEW n° 4). Données inventées. Aucune écriture au journal. | Brancher BR-CT-01 à 17. Écrire au registre des traitements (art. 30) une ligne « Contrôle qualité et protection des enfants ». **À faire** : volumes, pays des contrôleurs, service vidéo, durées manquantes. |

---

## 3. Consultation

| Partie | État | Démonstration | BR-1 / à faire |
|---|---|---|---|
| Directeur | Consulté. Décisions du 27/09 (C1, C2) et du 02/10 (B1 à B15). | Décisions appliquées aux écrans. | Signature de la DPIA (partie 7). |
| Enseignants | Non consultés. L'ICO recommande de demander l'avis des personnes concernées ou de leurs représentants quand c'est possible (ICO-MW). | Rien. | **À faire** : présenter la politique de contrôle à quelques enseignants avant la production et noter leurs remarques. |
| Parents et élèves | Non consultés. | Bandeau permanent seulement. | **À faire** : tester le texte d'information enfant et parent avec quelques familles. |
| Contrôleurs | Non consultés. | Rien. | **À faire** : charte de confidentialité du contrôleur, relue avec eux. |
| DPO | Aucun DPO désigné. | Rien. | **À faire, juriste** : obligation de DPO (voir 2.3). |
| Juriste | Pas encore consulté. | Rien. | **Recommandé** avant la production : base légale, art. 9, transferts, droits d'accès. |
| Sous-traitants | Cloudflare (stockage). Service vidéo : **à faire**. | Rien. | **À faire** : contrat de sous-traitance (DPA) signé ; liste des sous-traitants ultérieurs. |
| Sécurité | Revue de frontière sécurité prévue (doc 08 §17 point 14). | Revues UX faites (UX_REVIEW_08). | **À faire** : test d'intrusion sur l'accès Contrôle avant production. |

---

## 4. Nécessité et proportionnalité

### 4.1 Base légale

- **Enseignants (B5).** Base proposée : **intérêt légitime** (art. 6.1.f), pour protéger les enfants et garantir la qualité. Pas le consentement : il n'est pas libre dans une relation de travail (doc 08 §14.3). Un **test de mise en balance (LIA)** est nécessaire.
  - *Intérêt* : protéger des enfants seuls en ligne avec un adulte ; tenir la promesse faite aux familles.
  - *Nécessité* : un contrôle annoncé à l'avance ne montre pas le cours réel (C1). Les faits automatiques ne mesurent pas la qualité ni l'attitude (doc 08 §1.1). Il n'existe pas de moyen moins intrusif qui atteigne le même but.
  - *Mise en balance* : l'enseignant est prévenu par contrat et par la politique ; le bandeau est permanent ; le contrôleur n'enregistre rien ; les visites sont « de temps en temps » ; la synthèse contient aussi les points positifs ; l'enseignant peut contester (B7). L'intérêt de protéger des enfants pèse lourd.
  - **À faire** : écrire la LIA complète sur une page séparée et la faire signer avec cette DPIA.
- **Élèves.** Les images et prénoms des élèves sont vus parce qu'ils sont dans la salle. Base proposée : intérêt légitime (protection des enfants, qualité du cours qu'ils reçoivent). **À faire, juriste** : confirmer.
- **Conviction religieuse (art. 9).** Elle découle du service lui-même, pas du contrôle. **À faire, juriste** : condition de l'art. 9.2 retenue pour toute l'académie (par exemple consentement explicite à l'inscription, ou autre condition) et vérifier qu'elle couvre le contrôle.

### 4.2 Le traitement atteint-il son but ?

Oui. La visite a lieu pendant le cours (C1), donc elle montre la réalité. Le rapport arrive toujours à l'administration (C2). Une mission non faite est signalée (BR-CT-15).

### 4.3 Minimisation

- Le contrôleur voit le minimum de doc 08 §8.1 ; la liste §8.2 est interdite.
- Élèves : prénom, initiale du nom, identifiant pédagogique ; vignettes en initiales. Pas de recherche libre d'élève (UX_REVIEW n° 7).
- Le contrôleur ne voit que sa mission, jamais la liste des salles en direct (doc 08 §3.3).
- Il n'écrit que ce qui concerne le cours (B8) ; ligne d'aide « Décrivez seulement ce que vous avez observé ».
- Le fil d'échanges est titré par Classe et date, jamais par un nom (UX_REVIEW n° 11).
- Les faits sont calculés, jamais ressaisis.

**Écart à corriger au BR-1** : CT-BR dit « prénom seul » pour le roster (BR-CT-05) et « prénom et initiale du nom » pour la liste des présents (CT-7 suite). Les deux sont des décisions du directeur ; garder l'initiale seulement là où elle sert à distinguer des homonymes.

### 4.4 Transparence

- Enseignants : contrat signé à l'inscription (B5) et politique de contrôle publiée. Elle doit dire, avant l'activation (doc 08 §14.1) : qu'il y a des visites non annoncées, pourquoi, qui observe, ce qui est vu, ce qui est écrit, ce qui n'est pas enregistré, la durée de conservation, qui lit, l'effet possible sur une décision, comment contester, le contact confidentialité.
- Élèves et parents : bandeau permanent « visite de contrôle possible », sans nom et sans annonce en temps réel (B12) ; politique de confidentialité. Le bandeau seul ne suffit pas (doc 08 §14.1).
- Pas de surveillance cachée : l'ICO juge la surveillance cachée justifiable seulement en circonstances exceptionnelles (ICO-MW). Ici la surveillance est **annoncée à l'avance** ; seul le moment n'est pas annoncé.

### 4.5 Droits des personnes

- **Accès.** Un enseignant ou un parent peut demander ses données, y compris un rapport. **À faire, juriste** : procédure de réponse ; masquage de l'identité du contrôleur (B15) en s'appuyant sur les exceptions du DPA 2018 pour les données d'un tiers.
- **Rectification et contestation (B7).** Une demande par rapport, dans les 7 jours qui suivent la publication de la synthèse mensuelle, avec un motif écrit, traitée par l'administration. Le rapport n'est pas réécrit ; la décision de l'administration y est ajoutée.
- **Opposition (art. 21).** Avec l'intérêt légitime, l'enseignant peut s'opposer ; l'académie peut refuser si ses motifs (protection des enfants) l'emportent. **À faire** : l'écrire dans la politique.
- **Effacement** à la fin de la durée de conservation (B4).

### 4.6 Sous-traitants et transferts (B9)

- L'académie est au Royaume-Uni ; les données sont chez Cloudflare en Europe de l'Ouest. Un envoi du Royaume-Uni vers l'EEE est couvert par les règlements d'adéquation britanniques.
- **À vérifier** : les sous-traitants ultérieurs de Cloudflare situés hors EEE, et le cadre utilisé (DPA de Cloudflare, UK Addendum aux clauses types de l'UE, ou IDTA de l'ICO).
- **À faire** : un contrôleur qui observe depuis un pays sans adéquation reçoit des données d'élèves. Lister les pays des contrôleurs ; prévoir le cadre de transfert ou limiter les contrôleurs à certains pays (doc 08 §14.8 : pas d'accès externe permanent sans cette revue).
- **À faire** : lieu et contrat du service vidéo en direct.

| Démonstration | BR-1 |
|---|---|
| Minimisation visible dans les écrans (roster, vignettes, titres de fils). Bandeau permanent en place. Contestation non construite (vague Enseignant). | LIA écrite. Politique de contrôle publiée. Clause au contrat enseignant (charte `09_consentements`). Écran de contestation (CT-IMP-EN-02) et file côté admin. Procédure d'accès. Cadre de transfert vérifié. |

---

## 5. Tableau des risques

Échelles de l'ICO. Probabilité : faible, possible, probable. Gravité : minime, importante, grave. Risque global : faible, moyen, élevé. Le risque est évalué **sans les mesures de la partie 6**.

| N° | Risque pour les personnes | Personnes | Probabilité | Gravité | Risque global |
|---|---|---|---|---|---|
| R1 | Un compte contrôleur est volé ou utilisé sans droit : un inconnu voit et entend des enfants en direct. | Élèves, enseignant | Possible | Grave | Élevé |
| R2 | Un contrôleur capte des images ou le son (capture, ou second appareil) et les diffuse. | Élèves, enseignant | Possible | Grave | Élevé |
| R3 | L'enseignant n'est pas assez prévenu : la visite devient une surveillance cachée, illégale et vécue comme une trahison. | Enseignant | Possible | Importante | Moyen |
| R4 | Un rapport injuste ou faux nuit à la carrière de l'enseignant, sans moyen réel de répondre. | Enseignant | Possible | Importante | Moyen |
| R5 | Le rapport contient trop de données sur un élève (nom complet, famille, comportement hors cours). | Élèves | Possible | Importante | Moyen |
| R6 | Des données sensibles sont captées ou écrites : religion (inhérente au cours), santé ou situation familiale entendue par hasard. | Élèves, enseignant | Possible | Importante | Moyen |
| R7 | Les rapports sont gardés trop longtemps et ressortent des années après. | Enseignant, élèves | Probable (sans règle) | Importante | Élevé |
| R8 | Un rapport brut est lu ou exporté par une personne qui n'en a pas besoin, ou fuit. | Enseignant, élèves | Possible | Importante | Moyen |
| R9 | Le brouillon reste sur un téléphone perdu, volé, sauvegardé ou partagé. | Enseignant, élèves | Possible | Importante | Moyen |
| R10 | Des données partent hors Royaume-Uni et EEE sans protection (sous-traitants, contrôleur à l'étranger, service vidéo). | Tous | Possible | Importante | Moyen |
| R11 | L'identité du contrôleur est révélée : pression ou représailles de l'enseignant. | Contrôleur | Possible | Importante | Moyen |
| R12 | Les enfants ne comprennent pas qu'un adulte peut regarder la séance. | Élèves | Probable | Importante | Élevé |
| R13 | Les rapports servent à autre chose (paie, sanction automatique, note liée à la vitesse des élèves). | Enseignant, élèves | Possible | Importante | Moyen |
| R14 | Le contrôle crée du stress et de la méfiance ; l'enseignant enseigne moins bien. | Enseignant, élèves | Possible | Minime | Faible |
| R15 | Une demande d'accès ou d'effacement n'est pas traitée, ou dévoile un tiers. | Tous | Possible | Importante | Moyen |
| R16 | Le journal d'audit contient trop de données personnelles, ou peut être modifié. | Tous | Possible | Importante | Moyen |
| R17 | Un enseignant-contrôleur observe un collègue proche ou sa propre Classe (conflit d'intérêt). | Enseignant | Possible | Importante | Moyen |

17 risques : 4 élevés (R1, R2, R7, R12), 12 moyens, 1 faible.

---

## 6. Mesures et risque résiduel

« Fait » : déjà dans l'application de démonstration. « BR-1 » : à faire au branchement serveur. Le risque résiduel suppose toutes les mesures BR-1 faites.

| N° | Mesures | Démonstration (fait) | BR-1 (à faire) | Effet | Risque résiduel |
|---|---|---|---|---|---|
| R1 | B1 contrôleur connecté et approuvé par l'administration ; B2 double vérification à la connexion ; B3 retrait en un clic, notification au contrôleur à l'attribution et au retrait ; refus par défaut (doc 08 §9.5) ; permission vérifiée à chaque requête ; journal. | Écran « accès retiré » qui remplace tout (CT-9, UX_REVIEW n° 17) ; refus par défaut simulé. | BR-CT-01 (capacité datée, bornée, révocable) ; MFA ; bouton admin (CT-IMP-AD-16) ; notifications ; revue périodique des accès (CT-IMP-AD-17) ; BR-CT-08. | Réduit | Faible |
| R2 | B10 capture bloquée en production ; filigrane (identité, heure) qui apparaît seulement quand une capture est tentée ; pas de téléchargement ni d'export pour le contrôleur ; charte de confidentialité signée par le contrôleur ; sanction prévue ; journal des entrées. | Commandes interdites non rendues (UX_REVIEW n° 4). Capture et filigrane non construits. | Blocage de capture (Android) et détection (iOS, et web à vérifier) ; filigrane à la tentative ; tentative notée au journal ; charte du contrôleur (**à faire**). Un second appareil qui filme l'écran ne peut pas être bloqué : le doc 08 §8.4 interdit de promettre « capture impossible ». | Réduit | Moyen |
| R3 | B5 contrat signé à l'inscription ; politique de contrôle publiée avant l'activation (doc 08 §14.1) ; bandeau permanent ; LIA. | Bandeau permanent identique pour tous (UX_REVIEW n° 18). | Clause au contrat ; politique publiée et lien dans l'espace enseignant ; LIA signée. | Réduit | Faible |
| R4 | Faits calculés, pas ressaisis ; rapport jamais réécrit, compléments datés (BR-CT-17) ; B7 contestation (une par rapport, 7 jours après la synthèse, motif écrit) ; décision prise par un humain ; synthèse avec les points positifs ; calibration et détection des contrôleurs qui valident tout (CT-IMP-AD-10, 11). | Faits automatiques, rapport non éditable, complément. | Écran de contestation (CT-IMP-EN-02) ; file admin ; calibration. La règle B7 est stricte (un seul essai, délai court) : un rapport injuste peut rester. | Réduit | Moyen |
| R5 | Roster autorisé, pas de recherche libre ; prénom, initiale, identifiant pédagogique ; ligne d'aide ; le serveur refuse un élève hors roster (BR-CT-11). | Roster sans champ de recherche ; vignettes en initiales. | BR-CT-05, 11, 12, 16 ; corriger l'écart prénom / initiale (4.3). | Réduit | Faible |
| R6 | B8 : les participants savent qu'ils ne sont pas en privé ; le contrôleur n'écrit que ce qui concerne le cours ; rien n'est enregistré par le contrôleur ; condition de l'art. 9 pour la religion. | Ligne d'aide en place. | Rappel dans la charte du contrôleur ; condition art. 9 choisie (**à faire, juriste**) ; l'administration supprime d'un rapport toute donnée sensible hors sujet (**à faire** : procédure). | Réduit | Faible |
| R7 | B4 : rapport brut 12 mois après l'envoi, prolongé tant qu'un dossier ou une mesure est ouvert, puis supprimé ; synthèse sans nom d'élève gardée plus longtemps. | Rien (pas de stockage). | Effacement programmé côté serveur ; durées manquantes à fixer (journal, fils, synthèse, brouillon non envoyé). | Réduit | Faible |
| R8 | B13 : seule l'administration lit un rapport brut (et le contrôleur auteur, le sien) ; B14 : seule l'administration exporte ; chaque lecture et export au journal ; accès au journal séparé de la gestion des droits (CT-IMP-AD-18). | Historique limité aux rapports du contrôleur. | BR-CT-14 ; règles d'accès côté serveur ; export tracé ; chiffrement au repos (**à vérifier** chez Cloudflare). | Réduit | Faible |
| R9 | B11 : le brouillon ne sort jamais de l'application ; stocké chiffré sur l'appareil, hors sauvegarde et hors partage ; effacé après l'envoi. | Brouillon en mémoire seulement (`compteRenduATerminerProvider`). | Stockage local chiffré ; exclusion des sauvegardes ; effacement après envoi et au retrait d'accès ; durée maximale d'un brouillon non envoyé (**à faire**). | Réduit | Faible |
| R10 | B9 : stockage en Europe de l'Ouest ; adéquation Royaume-Uni vers EEE ; vérification des sous-traitants hors EEE (DPA, UK Addendum ou IDTA). | Rien. | **À vérifier** : liste des sous-traitants de Cloudflare et cadre de transfert. **À faire** : pays des contrôleurs ; service vidéo. | Réduit si vérifié | Moyen jusqu'à vérification, puis faible |
| R11 | B15 : identité du contrôleur jamais révélée, même après la synthèse ; heures exactes internes à l'administration (doc 08 §3.4). | Aucun écran enseignant ne montre de contrôleur. | Synthèse sans nom ni heure ; masquage dans les réponses aux demandes d'accès (**à faire, juriste**). | Réduit | Faible |
| R12 | Bandeau permanent ; texte adapté aux enfants dans la politique de confidentialité ; information des parents à l'inscription. | Bandeau permanent. | **À faire** : explication courte pour les enfants, selon l'âge (Children's Code, standard 4) ; texte aux parents ; validation en français par le directeur, puis 5 langues (LG-1). | Réduit | Moyen |
| R13 | Finalités écrites (2.4) ; paie séparée ; pas de vitesse d'élève comme note ; pas de décision automatique ; toute nouvelle finalité validée (doc 08 §14.5). | Aucun écran ne fait ce lien. | Règle dans la politique ; contrôle à la vague Enseignant (CT-IMP-EN-04). | Réduit | Faible |
| R14 | Visites « de temps en temps » ; synthèse mensuelle avec les points positifs ; pas d'alerte en temps réel à l'enseignant ; aucun compteur « dernière visite » (doc 08 §11.2). | Aucune alerte à l'enseignant. | Fréquence raisonnable fixée dans la politique (**à faire**). | Réduit | Faible |
| R15 | Procédure écrite pour les demandes d'accès, de rectification, d'opposition et d'effacement ; délai d'un mois ; masquage des tiers. | Rien. | **À faire** : procédure et contact confidentialité. | Réduit | Faible |
| R16 | Journal séparé du rapport, non modifiable par le contrôleur (doc 08 §10) ; pas de données sensibles dans le journal (OWASP Logging, cité dans UX_REVIEW_08). | Rien (aucune écriture). | BR-CT-08 ; durée du journal (**à faire**). | Réduit | Faible |
| R17 | Propre Classe, séance de remplacement et mission où il participe exclues (doc 08 §9.4) ; conflits déclarés plus tard. | Exclusion de la propre Classe simulée (BR-CT-02). | Exclusions côté serveur ; déclaration des liens personnels (**à faire**, CT-IMP-AD-12). | Réduit | Faible |

**Bilan.** Avec toutes les mesures BR-1 faites : **aucun risque résiduel élevé**. Restent **moyens** : R2 (un second appareil peut filmer l'écran), R4 (contestation stricte), R10 (tant que les transferts ne sont pas vérifiés), R12 (tant que le texte pour les enfants n'existe pas). Tant que BR-1 n'est pas fait, R1, R2, R7 et R12 restent élevés : le Contrôleur ne doit pas sortir de la démonstration.

Si un risque résiduel élevé apparaît plus tard, l'ICO doit être consultée avant le traitement (UK GDPR art. 36).

### 6.1 Écarts avec le Children's Code (ICO-AADC)

| Standard | Exigence (résumé) | Situation | Écart |
|---|---|---|---|
| 2. DPIA | DPIA pour un service utilisé par des enfants. | Ce document. | Pas encore signé ; pas d'avis de juriste. |
| 4. Transparence | Information claire, adaptée à l'âge de l'enfant. | Bandeau permanent seulement. | **Écart** : pas de texte pour les enfants. À faire avant la production. |
| 7. Paramètres par défaut | Haut niveau de vie privée par défaut, sauf raison impérieuse. | L'observation ne peut pas être refusée par l'enfant. | **Écart assumé** : raison impérieuse = protection de l'enfant (B5). À justifier dans la LIA et l'information aux parents. Le reste est réglé au plus protecteur (initiales, pas de recherche, pas d'export pour le contrôleur). |
| 8. Minimisation | Collecter et garder le minimum. | Minimum de doc 08 §8.1 ; B4. | Écart léger : prénom seul ou prénom et initiale (4.3), à harmoniser. |
| 11. Signe de surveillance (par analogie ; le standard vise les parents) | Signe évident pour l'enfant quand il est surveillé. | Bandeau permanent « visite de contrôle possible », sans annonce en temps réel (B12). | **Écart assumé** par le directeur : le signe est permanent, pas en temps réel. À justifier par la protection de l'enfant (une visite annoncée ne montre pas le cours réel). |

### 6.2 Le RGPD en complément

Pour les élèves et enseignants de l'UE, les mêmes mesures répondent aux articles 5, 25, 32 et 35 du RGPD (cités par le doc 08 §18). **À faire, juriste** : représentant dans l'UE (art. 27) ; âge du consentement numérique selon le pays, si le consentement sert pour une autre partie du service.

---

## 7. Validation

| Point | Nom, date | Décision ou remarque |
|---|---|---|
| Mesures approuvées par | Directeur : **à signer** | |
| Risques résiduels approuvés par | Directeur : **à signer** | Aucun résiduel élevé si BR-1 est fait ; 4 moyens à accepter (R2, R4, R10, R12). |
| Avis du DPO | **À faire** (aucun DPO désigné) | |
| Avis d'un juriste britannique | **Recommandé avant la production** | Base légale et LIA, art. 9, transferts, demandes d'accès, représentant UE, DPO. |
| Avis des enseignants et des familles | **À faire** (partie 3) | |
| Date de revue | **À faire** : proposée à l'ouverture réelle, puis chaque année, ou à tout changement important. | |

Signature du directeur : ____________________  Date : ____________

---

## Liste des points « à faire »

1. Relire le guide DPIA général de l'ICO et noter son adresse.
2. DPIA de la Classe (visio, enregistrement « Cours enregistré »), si elle n'existe pas.
3. Volumes (Classes, élèves, enseignants, contrôleurs, visites).
4. Pays des contrôleurs ; cadre de transfert pour ceux hors Royaume-Uni et EEE.
5. Service vidéo en direct : hébergeur, lieu, contrat.
6. Cloudflare : DPA signé, liste des sous-traitants hors EEE, UK Addendum ou IDTA, chiffrement au repos.
7. Durées : journal d'audit, fils d'échanges, synthèse sans nom, brouillon non envoyé, capacité retirée.
8. LIA complète, signée.
9. Condition de l'art. 9 pour la religion (juriste).
10. Représentant UE (art. 27) et DPO (art. 37) (juriste).
11. Inscription et redevance ICO, numéro de société, contact confidentialité.
12. Politique de contrôle publiée ; clause au contrat enseignant.
13. Texte pour les enfants et texte pour les parents (Children's Code 4).
14. Charte de confidentialité du contrôleur.
15. Procédure des droits (accès, rectification, opposition, effacement) avec masquage du contrôleur.
16. Procédure pour retirer d'un rapport une donnée sensible hors sujet.
17. Fréquence des visites dans la politique.
18. Harmoniser prénom seul / prénom et initiale (roster et présents).
19. Consultation des enseignants, des familles et des contrôleurs.
20. Test d'intrusion de l'accès Contrôle.
21. Signature du directeur et avis d'un juriste.
