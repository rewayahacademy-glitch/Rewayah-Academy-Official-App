# DPIA de la Classe en visio, avec enregistrement audio (signée le 02/10/2026)

> **Statut mis à jour le 04/10/2026.** Le directeur a écrit « je signe » le 02/10/2026 (`SIGNATURES_2026-10-02.md:8`). La pièce est donc **adoptée** (signée), et non plus à l'état de projet. Le texte ci-dessous n'a pas été modifié (K-26) : les mentions « projet », « à signer » ou « à valider » qui y restent sont celles d'avant la signature.

**Statut.** Projet rédigé par un agent juriste le 02/10/2026 (lot JUR-SUITE-1). Il répond au point « à faire » n° 2 de `../DPIA_CONTROLEUR.md`. Il n'est pas valable tant que le directeur ne l'a pas signé (partie 9). Il ne remplace pas un avocat britannique ; il tranche pour que le travail avance.

**Cadre.** UK GDPR art. 5, 6, 9, 21, 25, 32, 35 ; Data Protection Act 2018 ; guide et modèle de DPIA de l'ICO (mêmes sept étapes que la DPIA du Contrôleur) ; guide de l'ICO « Employment practices and data protection: monitoring workers » (ICO-MW) ; Children's Code de l'ICO (ICO-AADC). Le RGPD (UE) s'applique en complément (`RGPD_UE.md`). Les adresses ICO sont celles de `../DPIA_CONTROLEUR.md` ; aucune autre n'est ajoutée.

**Décisions du directeur prises en compte (24/09, `03_DECISIONS_COORDINATEUR.md` §1 bis-2).** L'enregistrement audio est **réel**, dans un espace de stockage dédié chez **Cloudflare R2**. Le bandeau permanent de la salle reste mot pour mot : « Cours enregistré, visite de contrôle possible. »

**Ce que cette DPIA couvre.** La Classe en direct (visio), l'enregistrement audio de chaque cours, son écoute et sa suppression. **Ce qu'elle ne couvre pas** : la visite de contrôle (`../DPIA_CONTROLEUR.md`) ; les visites des parents (texte A4) sont citées seulement là où elles touchent la Classe.

**Lecture.** « Démonstration » = ce que l'application fait déjà, sans serveur. « BR-1 » = ce qui reste à faire au branchement. « À faire » = une information qui manque. Rien n'est inventé.

---

## 1. Besoin d'une DPIA

Obligatoire, pour quatre raisons cumulées :

- **Enfants** : beaucoup d'élèves sont mineurs (Children's Code, standard 2).
- **Enregistrement systématique** de tous les cours : c'est une surveillance systématique des enseignants (ICO-MW) et des élèves.
- **Donnée religieuse** : la récitation du Coran révèle une conviction religieuse (art. 9 ; `ART9_RELIGION.md`).
- **Personnes dans plusieurs pays**, et un service vidéo dont le lieu n'est pas encore connu.

## 2. Description du traitement

### 2.1 Nature

1. **Classe en direct.** Enseignant et élèves se retrouvent en visio. Micro et caméra fermés à l'entrée. La caméra d'un enfant ne s'ouvre qu'avec l'accord du tuteur (texte A2) ; elle est coupée par défaut à tout âge.
2. **Enregistrement.** Le son de chaque cours est enregistré. **Pas l'image.** Le fichier est déposé dans un espace Cloudflare R2 dédié.
3. **Bandeau.** Pendant tout le cours, la salle affiche « Cours enregistré, visite de contrôle possible. »
4. **Écoute.** Un enregistrement n'est écouté que pour une raison précise (signalement, plainte, doute de sécurité, contestation d'un enseignant), par une personne de l'académie chargée de la qualité ou de la protection. Chaque écoute est inscrite au journal (qui, quand, pourquoi). Le contrôleur n'a pas accès aux enregistrements passés (doc 08 §8.2).
5. **Suppression.** Effacement automatique après 30 jours (`recording_retention_days` = 30). En cas de signalement, l'enregistrement est **gelé** jusqu'à la fin de l'examen.
6. **Usages exclus.** Pas de transcription automatique, pas de reconnaissance de la voix, pas d'analyse par intelligence artificielle, pas de note de l'enseignant tirée de l'enregistrement, pas de publication, pas de marketing, pas d'entraînement d'un modèle. **Je tranche** : ces exclusions sont fermes ; les lever demande une nouvelle DPIA.

### 2.2 Portée

| Personnes | Données |
|---|---|
| Élèves (souvent mineurs) | Prénom, image si caméra autorisée (non enregistrée), voix en direct et **enregistrée**, présence |
| Enseignant | Nom d'affichage, image (non enregistrée), voix en direct et **enregistrée** |
| Personnes du foyer | Voix entendue par hasard en arrière-plan (enregistrée) |
| Équipe qui écoute | Identité, date, motif de chaque écoute (journal) |

**Volume.** **À faire** (même point que la DPIA du Contrôleur) : nombre de Classes et de cours par semaine.

**Lieux.** Enregistrements chez Cloudflare R2, Europe de l'Ouest (B9). Service vidéo en direct : **à faire** (le doc 08 §17 cite LiveKit ; hébergeur et lieu non connus).

### 2.3 Contexte

Cours de Coran à distance, souvent un adulte seul avec des enfants, dans un autre pays. Les familles s'attendent à ce que le cours soit privé vis-à-vis de l'extérieur, mais elles sont prévenues qu'il est enregistré (A3, bandeau). Les enfants récitent ; ils peuvent faire des erreurs, parler de leur vie, être entendus avec leur famille.

### 2.4 Finalités

1. Protéger les enfants : pouvoir vérifier ce qui s'est passé après un signalement.
2. Protéger les enseignants : preuve en cas de plainte infondée (texte E1).
3. Traiter une contestation ou une réclamation sur un cours précis.

## 3. Consultation

| Partie | État |
|---|---|
| Directeur | Consulté : décisions du 24/09 (enregistrement réel, R2, bandeau). Signature à venir. |
| Familles, enseignants | Non consultés. **À faire** : même petit test que pour le Contrôleur (textes A3 et E1). |
| Cloudflare (R2), service vidéo | **À faire** : contrat de sous-traitance (DPA) ; liste des sous-traitants ultérieurs. |
| Juriste | Cette relecture par agent. Avocat humain recommandé avant production, sans bloquer. |

## 4. Nécessité et proportionnalité

- **Base légale de l'enregistrement** : intérêt légitime, art. 6(1)(f), pour les élèves comme pour les enseignants. Test de mise en balance en partie 8 : **réussi sous conditions**.
- **Pourquoi pas le consentement** : on ne peut pas enregistrer un cours de groupe en retirant la voix d'un seul enfant ; un consentement qu'on ne peut pas refuser sans quitter le cours ne serait pas libre. L'enseignant est en situation de dépendance (ICO-MW).
- **Donnée religieuse** : couverte par le consentement explicite A0 (art. 9(2)(a)). A0 doit citer l'équipe qui peut écouter un enregistrement : c'est déjà « l'équipe de l'académie » ; la correction de `CORRECTIONS_A0_A3.md` ajoute les personnes chargées du contrôle.
- **Voix et biométrie** : une voix enregistrée n'est pas une donnée biométrique au sens de l'art. 9 **tant qu'on ne s'en sert pas pour identifier une personne par un traitement technique**. D'où l'exclusion ferme de la reconnaissance vocale (2.1 point 6).
- **Minimisation** : son seulement, pas d'image ; 30 jours ; écoute seulement avec un motif ; pas d'accès du contrôleur aux enregistrements passés.
- **Transparence** : A3 à l'inscription, E1 au contrat enseignant, bandeau permanent, politique de confidentialité, `INFO_ELEVES_PARENTS.md`.
- **Droits** :
  - *Opposition (art. 21)* : bouton « Je m'oppose » de A3. Réponse sous un mois. On ne peut pas retirer un enfant de l'enregistrement d'un cours de groupe. Un cours non enregistré n'est pas proposé, car il supprimerait la protection. **Je tranche** : l'académie écoute la demande, explique la mesure, et si la famille maintient son opposition, elle peut arrêter sans frais pour les cours non suivis, comme A3 le dit. C'est honnête et conforme : la protection des enfants est un motif légitime impérieux (art. 21(1)).
  - *Accès (art. 15)* : un parent peut demander l'enregistrement d'un cours de son enfant. Il contient la voix d'autres enfants : l'académie donne un extrait limité à son enfant si c'est faisable, sinon une description écrite, et refuse pour le reste (DPA 2018 annexe 2, partie 3, para. 16, données d'un tiers). Après 30 jours, l'enregistrement n'existe plus : on le dit.
  - *Qui a écouté* : la personne peut savoir **si** un enregistrement a été écouté et **pourquoi**, pas le nom de la personne qui a écouté (para. 16 ; cohérent avec B15). D'où la correction de A3.

## 5. Tableau des risques (sans mesures)

| N° | Risque pour les personnes | Personnes | Probabilité | Gravité | Global |
|---|---|---|---|---|---|
| C1 | Un enregistrement fuit : espace R2 mal réglé (public), lien partagé, compte de l'équipe volé. Des voix d'enfants qui récitent le Coran circulent en ligne. | Élèves, enseignant | Possible | Grave | Élevé |
| C2 | Une famille filme ou enregistre le cours et le diffuse (autres enfants). | Élèves | Probable | Importante | Élevé |
| C3 | Un inconnu entre dans la salle (compte volé, lien partagé). | Élèves | Possible | Grave | Élevé |
| C4 | Les enregistrements ne sont pas effacés après 30 jours (purge en panne). | Tous | Possible | Importante | Moyen |
| C5 | Une personne de l'équipe écoute par curiosité, sans motif. | Élèves, enseignant | Possible | Importante | Moyen |
| C6 | L'enregistrement capte la vie du foyer (dispute, santé, autre personne). | Élèves, foyer | Probable | Minime | Moyen |
| C7 | Enregistrement réutilisé (IA, note de l'enseignant, publicité). | Tous | Possible | Importante | Moyen |
| C8 | Les enfants et les parents ne comprennent pas que tout est enregistré. | Élèves | Possible | Importante | Moyen |
| C9 | Données hors Royaume-Uni et EEE sans protection (service vidéo, sous-traitants). | Tous | Possible | Importante | Moyen |
| C10 | Une réponse d'accès dévoile la voix d'autres enfants ou le nom de qui a écouté. | Élèves, équipe | Possible | Importante | Moyen |
| C11 | La caméra d'un enfant s'ouvre sans accord du tuteur. | Élèves | Faible | Importante | Faible |
| C12 | Un signalement arrive après l'effacement : la preuve manque. | Élèves, enseignant | Possible | Importante | Moyen |

12 risques : 3 élevés (C1, C2, C3), 8 moyens, 1 faible. C2 est élevé parce qu'il est probable.

## 6. Mesures et risque résiduel

| N° | Mesures | Démonstration | BR-1 | Résiduel |
|---|---|---|---|---|
| C1 | Espace R2 **privé**, jamais public ; lecture par liens signés de courte durée (quelques minutes), créés par le serveur après vérification du rôle ; pas de téléchargement, écoute dans l'outil seulement ; MFA pour l'équipe ; chiffrement en transit et au repos ; journal de chaque écoute. | Rien (pas d'enregistrement en démonstration). | Tout. **À vérifier** : chiffrement au repos R2, réglage « non public » testé. | Faible |
| C2 | A1 interdit aux familles de filmer ; rappel dans A2 ; suspension du compte ; l'application bloque la capture quand le système le permet. On ne peut pas l'empêcher sur tous les appareils : on ne le promet pas. | Texte A1 et A2 en projet. | Blocage de capture côté élève (même technique que B10) ; procédure de suspension. | Moyen (accepté) |
| C3 | Entrée seulement par compte inscrit à la Classe ; pas de lien d'invitation public ; liste des présents visible par l'enseignant ; l'enseignant peut retirer un participant. | Salle avec présents. | Jetons vidéo émis par le serveur pour chaque séance et chaque personne. | Faible |
| C4 | Effacement automatique côté serveur à `expires_at` ; règle de cycle de vie sur l'espace R2 comme filet de sécurité (35 jours) ; contrôle mensuel. | Table `session_recordings` prévue (`expires_at`, statut, `deleted_at`) selon `09_consentements/INVENTAIRE.md`. | Tâche d'effacement ; règle R2 ; alerte si un fichier dépasse 35 jours. | Faible |
| C5 | Écoute seulement avec un motif choisi dans une liste (signalement, plainte, contestation, sécurité) et un numéro de dossier ; rôle limité ; journal ; revue trimestrielle des écoutes par la direction. | Rien. | Écran d'écoute avec motif obligatoire ; journal. | Faible |
| C6 | A1 demande qu'un adulte reste à portée de voix, pas qu'il parle ; micro fermé à l'entrée ; 30 jours ; écoute rare ; l'écoutant ignore ce qui est hors sujet et ne l'écrit nulle part. | Micro fermé à l'entrée. | Règle écrite pour l'équipe. | Faible |
| C7 | Usages exclus (2.1 point 6) écrits dans la politique et au registre ; aucune intégration d'outil d'analyse. | Rien. | Revue de code au BR-1 : aucun appel d'analyse. | Faible |
| C8 | Bandeau permanent ; A3 ; E1 ; textes enfants (`INFO_ELEVES_PARENTS.md`) qui doivent dire « ta voix est enregistrée » ; lien « En savoir plus » sur le bandeau. | Bandeau. | **À faire** : vérifier que E-1 et E-2 parlent bien de l'enregistrement, sinon les compléter. | Faible |
| C9 | R2 en Europe de l'Ouest (adéquation Royaume-Uni vers EEE) ; DPA Cloudflare ; service vidéo à choisir dans le Royaume-Uni, l'EEE ou un pays adéquat, ou avec un cadre de transfert. | Rien. | **À faire** : lieu du service vidéo et contrats. | Moyen jusqu'à vérification, puis faible |
| C10 | Procédure d'accès : extrait limité, données des tiers masquées, nom de l'écoutant jamais donné (para. 16). | Rien. | Procédure écrite (avec celle du Contrôleur). | Faible |
| C11 | Caméra coupée par défaut ; ouverture seulement si A2 accepté (et âge de décision). | Caméra absente si interdite. | Vérification côté serveur du jeton vidéo. | Faible |
| C12 | Bouton « Signaler » dans la salle qui **gèle** l'enregistrement (écart E16) ; une famille a 30 jours pour signaler ; le gel suspend la purge. | Rien (E16 ouvert). | Bouton, statut `gele`, purge suspendue. | Faible si E16 est fait, sinon moyen |

**Bilan.** Avec toutes les mesures BR-1 : aucun risque résiduel élevé. Restent moyens : **C2** (une famille peut filmer avec un autre appareil ; on ne peut pas l'empêcher, on l'interdit et on sanctionne) et **C9** jusqu'à vérification. Tant que BR-1 n'est pas fait, **aucun vrai cours ne doit être enregistré**.

## 7. Children's Code : écarts

| Standard | Situation | Écart |
|---|---|---|
| 1. Intérêt supérieur | L'enregistrement sert d'abord à protéger l'enfant. | Aucun. |
| 4. Transparence | Bandeau, A3, textes enfants. | Vérifier que les textes enfants disent que la voix est enregistrée (C8). |
| 7. Paramètres par défaut | L'enregistrement est actif par défaut et ne peut pas être coupé par l'enfant. | **Écart assumé** : raison impérieuse = protection de l'enfant. Le reste est réglé au plus protecteur (caméra coupée, image non enregistrée, 30 jours). |
| 8. Minimisation | Son seulement, 30 jours. | Aucun. |
| 11. Signe de surveillance | Bandeau permanent pendant tout le cours. | Aucun : ici l'enregistrement est continu, donc le signe permanent est exact. |

## 8. Test de mise en balance (LIA) de l'enregistrement audio

**Test 1, finalité.** Protéger les enfants (pouvoir vérifier après un signalement) ; protéger l'enseignant contre une plainte infondée ; traiter une réclamation. Intérêts réels, précis, légaux. **Réussi.**

**Test 2, nécessité.**

| Moyen moins intrusif | Suffit-il ? |
|---|---|
| Ne pas enregistrer | Non. Après un signalement, il ne resterait que la parole de l'enfant contre celle de l'adulte. |
| Enregistrer seulement sur demande | Non. On ne peut pas enregistrer après coup un incident qui vient d'avoir lieu. |
| Contrôle en direct seulement | Non. Il est rare et ponctuel ; il ne couvre pas le cours où l'incident arrive. Les deux sont complémentaires. |
| Enregistrer l'image aussi | Plus intrusif. Écarté : le son suffit pour la plupart des signalements. |
| Garder plus longtemps | Plus intrusif. 30 jours laissent à une famille le temps de remarquer et de signaler, avec le gel en cas de signalement. |

Le traitement est déjà réduit au nécessaire. **Réussi.**

**Test 3, mise en balance.**

| Élément | Analyse |
|---|---|
| Nature des données | Voix d'enfants, récitation religieuse (art. 9, couvert par A0), parfois bruit du foyer. Données sensibles : leur poids est élevé. |
| Attentes raisonnables | Les familles et les enseignants sont prévenus avant le premier cours (A3, E1), et le bandeau le rappelle en permanence. Un cours en ligne avec des enfants enregistré pour leur sécurité est aujourd'hui une pratique attendue. |
| Impact possible | Faible si les mesures C1 et C4 tiennent : personne n'écoute sans motif, tout est effacé en 30 jours. Grave en cas de fuite : d'où le risque C1 traité en priorité. |
| Dans quel sens pour l'enfant | Dans son sens : l'enregistrement le protège (Children's Code, standard 1). |
| Enseignants | Surveillance systématique, mais annoncée, limitée au son, non utilisée pour noter ni pour la paie, et qui les protège aussi. Pas de surveillance cachée (ICO-MW). |
| Garanties | Partie 6 ; droit d'opposition ; aucune décision automatique ; usages exclus. |

**Conclusion.** Les intérêts de protection l'emportent, **à condition** que soient en place avant le premier vrai cours enregistré : (1) espace R2 privé et liens signés courts (C1) ; (2) effacement automatique à 30 jours et filet R2 (C4) ; (3) motif obligatoire et journal pour chaque écoute (C5) ; (4) textes A3 corrigés et E1 signés ; (5) gel en cas de signalement (C12) ou, à défaut, une adresse de signalement qui permet de geler à la main. **Test réussi sous ces conditions.** Revue chaque année, ou à tout changement (image, durée, IA).

## 9. Validation

| Point | Nom, date | Remarque |
|---|---|---|
| Mesures et LIA approuvées | Directeur : **signé le 02/10/2026** | |
| Risques résiduels acceptés | Directeur : **signé le 02/10/2026** | 2 moyens : C2 (capture par une famille), C9 (jusqu'à vérification) |
| Avis d'un avocat britannique | Recommandé, sans bloquer | Accès aux enregistrements contenant d'autres enfants ; transferts du service vidéo |
| Revue | À l'ouverture réelle, puis chaque année | |

Signature du directeur : « je signe » (02/10/2026, voir `SIGNATURES_2026-10-02.md:8`)

## Ce qui reste à faire

1. Volumes (Classes, cours par semaine).
2. Service vidéo : hébergeur, lieu, contrat.
3. Cloudflare : DPA, sous-traitants hors EEE, chiffrement au repos R2, espace non public testé.
4. Bouton « Signaler » et gel (E16).
5. Vérifier que les textes enfants (E-1, E-2) disent que la voix est enregistrée.
6. Appliquer, après validation du directeur, les corrections A0 et A3 (`CORRECTIONS_A0_A3.md`), à LG-1 pour les langues.
