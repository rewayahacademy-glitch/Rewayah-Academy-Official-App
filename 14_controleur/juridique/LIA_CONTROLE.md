# Test de mise en balance de l'intérêt légitime (LIA) : visites de contrôle

**Statut.** Relecture juridique par un agent, 02/10/2026. Ce document complète `../DPIA_CONTROLEUR.md` (partie 4.1, point « à faire » n° 8). Il est signé avec la DPIA par le directeur. Il ne remplace pas l'avis d'un avocat britannique, conseillé avant la production, mais il tranche pour que le travail avance.

**Cadre.** UK GDPR art. 5, 6(1)(f), 13, 14 et 21 ; Data Protection Act 2018 ; guide de l'ICO « Legitimate interests » (méthode en trois tests : finalité, nécessité, mise en balance) ; guide de l'ICO « Employment practices and data protection: monitoring workers » (cité ICO-MW dans la DPIA) ; Children's Code de l'ICO (ICO-AADC). Le RGPD (UE) a le même article 6(1)(f) : ce test vaut aussi pour les personnes situées dans l'UE (voir `RGPD_UE.md`).

**Traitement visé.** Les visites de contrôle décrites dans la DPIA, partie 2.1 : un contrôleur approuvé entre sans annonce en temps réel dans une Classe en direct, voit et entend la séance, n'enregistre rien, puis envoie un compte rendu à l'administration. Deux groupes de personnes : **les enseignants** (personnes contrôlées) et **les élèves** (personnes vues et entendues pendant la visite, souvent mineures).

**Ce que ce test ne couvre pas.** La donnée religieuse (art. 9) : voir `ART9_RELIGION.md`. L'enregistrement audio des cours (texte A3 de `09_consentements/TEXTES_V2.md`) : il a besoin de son propre test, sur le même modèle. Le contrôle d'antécédents (KYC) des enseignants : s'il porte sur des condamnations, c'est l'art. 10 du UK GDPR et l'annexe 1 du DPA 2018 (voir la fin de ce document).

---

## 1. Test de la finalité : quel intérêt ?

| Intérêt | De qui | Légitime ? |
|---|---|---|
| Protéger des enfants qui sont seuls en ligne avec un adulte venu d'un autre pays, dont l'académie ne peut pas vérifier tout le passé. | Élèves, familles, académie | Oui. C'est l'intérêt le plus fort qui existe dans ce dossier. L'art. 6(1)(f) cite lui-même l'enfant comme personne à protéger en priorité. |
| Vérifier que le cours réel respecte les objectifs pédagogiques et de sécurité promis aux familles. | Familles, académie | Oui. Intérêt commercial et contractuel normal. |
| Garder une trace écrite (journal) pour prévenir les abus et pouvoir agir. | Académie, élèves | Oui. Il sert aussi l'enseignant accusé à tort (A3 version enseignant). |
| Aider l'enseignant à progresser (synthèse mensuelle). | Enseignant | Oui. |

**Finalités exclues** (déjà écrites dans la DPIA, partie 2.4) : pas de publication, pas de paie, pas de décision automatique, pas de note tirée de la vitesse des élèves, pas de réutilisation sans nouvelle analyse.

**Conclusion du test 1 : réussi.** Les intérêts sont réels, présents, précis et légaux.

## 2. Test de la nécessité : le contrôle est-il nécessaire ?

L'ICO demande si le traitement est **ciblé et proportionné**, et s'il existe un **moyen moins intrusif** d'atteindre le même but.

| Moyen moins intrusif | Atteint-il le but ? |
|---|---|
| Ne rien contrôler et faire confiance au KYC. | Non. Le directeur l'a constaté : les enseignants viennent de partout, et un contrôle d'antécédents ne couvre pas tout le passé ni le comportement futur. |
| Visites annoncées à l'avance. | Non. Une visite annoncée ne montre pas le cours réel (décision C1 du 27/09). |
| Relevés automatiques seulement (heures, présents, reconnexions). | Non. Ils ne disent rien de l'attitude de l'adulte envers l'enfant (doc 08 §1.1). |
| Enregistrement audio réécouté après coup. | En partie. Il sert après un signalement. Il ne montre pas l'image et il n'est réécouté que s'il y a déjà un doute. Le contrôle en direct est complémentaire. |
| Avis des familles. | En partie. Un enfant ne sait pas toujours reconnaître un comportement inadapté. |

Le traitement est déjà réduit au nécessaire : visites au hasard et non permanentes, pas d'enregistrement par le contrôleur, pas de micro, de caméra ni de chat pour lui, accès limité à la Classe attribuée, élèves en prénom et initiale, pas de recherche libre, pas d'export pour le contrôleur (DPIA, partie 4.3).

**Conclusion du test 2 : réussi.** Il n'existe pas de moyen raisonnable et moins intrusif qui protège autant les enfants.

## 3. Test de la mise en balance

### 3.1 Enseignants

| Élément | Analyse |
|---|---|
| Nature des données | Image, voix, manière d'enseigner, appréciation écrite. Données professionnelles, pas privées. La donnée religieuse est connue de toute façon par le métier (voir `ART9_RELIGION.md`). |
| Attentes raisonnables | Un enseignant d'enfants en ligne s'attend à être contrôlé, s'il est prévenu. Il l'est trois fois : clause au contrat signée à l'inscription (B5), politique de contrôle publiée (`POLITIQUE_CONTROLE_ENSEIGNANTS.md`), bandeau permanent dans la salle. Seul le **moment** de la visite n'est pas annoncé. Ce n'est donc pas une surveillance cachée au sens de l'ICO-MW. |
| Impact possible | Stress, rapport injuste, effet sur la carrière (R4, R14 de la DPIA). |
| Déséquilibre de pouvoir | Réel (doc 08 §14.3). C'est pourquoi la base n'est pas le consentement. |
| Garanties | Faits calculés et non ressaisis ; rapport jamais réécrit ; décision toujours prise par un humain (art. 22) ; synthèse mensuelle avec les points positifs ; contestation (B7) ; droit d'opposition (art. 21) ; conservation de 12 mois (B4) ; lecture du rapport brut par l'administration seulement (B13) ; aucune publication. |
| Identité du contrôleur cachée (B15) | Justifiée : elle protège le contrôleur contre les pressions. Elle ne prive pas l'enseignant de sa défense, car il reçoit les faits et le contenu de l'observation, et il peut contester. |

**Point de vigilance tranché.** La contestation B7 (une seule demande, 7 jours, motif écrit) est stricte. Elle reste acceptable **à deux conditions**, que la politique reprend : (1) le délai court à partir du jour où l'enseignant reçoit la synthèse, pas de la visite ; (2) la contestation ne remplace pas les droits de la loi. L'enseignant garde à tout moment son droit d'accès (art. 15), de rectification d'une donnée inexacte (art. 16) et d'opposition (art. 21), qu'aucune règle interne ne peut limiter.

### 3.2 Élèves

| Élément | Analyse |
|---|---|
| Nature des données | Prénom, initiale, image et voix en direct dans une salle où ils savent ne pas être seuls (B8). Parfois une observation qui nomme un élève. Ce sont des enfants : leurs intérêts pèsent plus (art. 6(1)(f), Children's Code standard 1). |
| Dans quel sens va le traitement ? | **Dans le sens de l'enfant.** La visite sert à le protéger. Le Children's Code (standard 1, intérêt supérieur de l'enfant) soutient donc le contrôle au lieu de s'y opposer. |
| Attentes raisonnables | Les parents sont informés à l'inscription (texte A3) et par `INFO_ELEVES_PARENTS.md`. L'enfant voit le bandeau permanent et reçoit une explication à son âge. |
| Impact possible | Faible : le contrôleur n'enregistre rien, ne parle pas, ne voit que la Classe attribuée. Le risque réel est la fuite (R1, R2), traité par la sécurité (MFA, capture bloquée, charte du contrôleur). |
| Écart avec le Children's Code, standard 11 (signe de surveillance) | Le signe est permanent, pas en temps réel (B12). **Je le juge défendable** : annoncer la visite en temps réel préviendrait aussi l'enseignant et rendrait le contrôle inutile. La protection de l'enfant est ici la « raison impérieuse » que le standard 7 admet. |

### 3.3 Conclusion de la mise en balance

**Les intérêts de l'académie et des enfants l'emportent**, pour les enseignants comme pour les élèves, **à condition** que les mesures de la partie 4 soient en place avant la première visite réelle.

## 4. Mesures obligatoires (conditions du résultat)

1. Clause au contrat enseignant et politique publiée avant la première visite réelle (`POLITIQUE_CONTROLE_ENSEIGNANTS.md`).
2. Information des parents et des enfants (`INFO_ELEVES_PARENTS.md`), dans la politique de confidentialité et à l'inscription.
3. Droit d'opposition (art. 21) écrit et traité sous un mois. Pour un enseignant : l'académie peut maintenir le contrôle pour des « motifs légitimes impérieux » (protection des enfants) ; s'il maintient son opposition, il n'est pas affecté à des Classes de mineurs. Pour une famille : on ne peut pas exclure un seul enfant d'une Classe de groupe ; on cherche une solution, sinon arrêt sans frais pour les cours non suivis (texte A3).
4. Toutes les mesures BR-1 de la DPIA, partie 6, en particulier R1 (MFA, retrait en un clic), R2 (capture bloquée, charte du contrôleur), R7 (12 mois), R8 (lecture limitée).
5. Aucune nouvelle finalité sans nouveau test.
6. Revue de ce test à chaque changement important, et au moins une fois par an.

## 5. Points où un professionnel humain reste préférable (sans bloquer)

- Le statut exact des enseignants (salariés, travailleurs indépendants, et pays) : il change le droit du travail local applicable à la clause de contrôle. Le droit des données est réglé ici ; le droit du travail de chaque pays ne l'est pas.
- Le contrôle d'antécédents (KYC) : s'il collecte des extraits de casier judiciaire, il faut une condition de l'art. 10 et de l'annexe 1 du DPA 2018 (paragraphe 18, protection des enfants, avec document de politique appropriée). À traiter dans le lot KYC, pas ici.

## 6. Décision

| | |
|---|---|
| Base légale retenue, enseignants | Intérêt légitime, UK GDPR art. 6(1)(f) |
| Base légale retenue, élèves | Intérêt légitime, UK GDPR art. 6(1)(f) |
| Consentement | Non retenu (pas libre pour l'enseignant ; inutile et trompeur pour l'élève, car on ne peut pas retirer un enfant d'une Classe de groupe) |
| Résultat | Test réussi, sous les conditions de la partie 4 |

Signature du directeur : ____________________  Date : ____________
