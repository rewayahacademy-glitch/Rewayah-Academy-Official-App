# Le moteur de suivi : ce que l'application fait seule pour chaque élève

Partie « moteur » de la charte de Rewayah Academy, rédigée le 12/11/2026 à la demande du directeur. Elle enseigne à l'application le document des scénarios (`SCENARIOS-ELEVES.md`, approuvé par le directeur le 12/11/2026) : pour chaque situation, le système reconnaît l'élève concerné et sait quoi faire, comment, quand et pour qui.

**Les marques.** **[DÉCIDÉ]** : décision du directeur, avec sa date ; les valeurs reprises du document des scénarios sont [DÉCIDÉ 12/11], puisqu'il l'a approuvé. **[ARBITRÉ]** : choix de l'architecte du 12/11/2026, avec sa raison. Tout chiffre est un **réglage** que la direction change sans toucher au reste (partie 6).

**La demande** [DÉCIDÉ 12/11] : « Le système doit reconnaître chaque situation, savoir quoi faire, comment, quand et à qui. Les humains ne doivent presque pas intervenir. Automatiquement, sans IA. »

---

## 1. En une page, pour le directeur

**Ce que le moteur fait seul.** Après chaque cours et chaque nuit, il regarde ce que l'application sait déjà : qui était là, où la classe s'est arrêtée, ce que l'enseignant a confirmé, les dates limites, les pauses, le calendrier. Il applique des règles écrites d'avance, toujours les mêmes : « si ceci est vrai, alors faire cela ». Il ne devine rien et n'écrit aucun texte : chaque message vient d'un modèle écrit ici, traduit, où l'application remplace seulement le prénom, la date ou la page.

Il ouvre « Rattraper ce cours » pour chaque absent, compte les absences et prévient la famille au bon moment. Il prépare les messages que l'enseignant n'a plus qu'à confirmer d'un geste. Il surveille les dates limites, rappelle les petits bilans et les examens, envoie à chaque famille un message court par semaine, et remonte à la direction ce que personne n'a fait à temps.

**Ce qu'il laisse aux humains.** Ce qu'eux seuls savent faire : corriger une récitation à l'oral, proposer et confirmer un passage d'étape, conduire un examen, tenir un bilan avec une famille, décider un changement de classe.

**Chaque alerte a une personne responsable, une action, un délai.** Le délai passé, elle monte d'un cran : du système à l'enseignant, puis à la direction.

**Trois exemples.**

*L'élève A, 8 ans, manque le cours du lundi.* Le cours a lieu. À la fin, l'application ouvre « Rattraper ce cours » sur l'accueil du tuteur et sur la carte de l'enfant : la page où la classe s'est arrêtée, la lecture enregistrée, le travail à préparer. Le tuteur reçoit un message le jour même, ou le lendemain à 8 h s'il est tard chez lui. Il fait le parcours avec l'enfant et appuie sur « J'ai rattrapé ce cours ». Mercredi, l'enseignant voit « a manqué le dernier cours » à côté du nom et lui fait lire deux lignes. Personne n'a rien saisi. Si rien n'est rattrapé, les points du cours passent « À renforcer » dans le travail à préparer.

*L'élève B, adulte, manque trois semaines sans prévenir.* À la deuxième absence, un message lui rappelle la règle. À la troisième, l'enseignant trouve un message déjà écrit, qu'il confirme d'un geste. À la quatrième, la direction a sept jours pour l'appeler. À la sixième de suite, l'alerte devient « absence longue » : la direction a trois jours et peut accorder une pause d'exception s'il est malade. Les cours manqués ne s'empilent pas : ils deviennent un seul plan de reprise de deux semaines, ouvert à son retour. Si la direction tarde, l'alerte passe en rouge sur son tableau de bord.

*L'élève C, 12 ans, avance plus vite que sa classe.* L'enseignant marque « prêt pour un petit bilan » dans sa confirmation habituelle, bien avant la durée prévue. Le moteur lui rappelle de tenir ce petit bilan dans les deux semaines, pendant un cours normal. La direction confirme « Étape validée » dans les sept jours. S'il existe une classe plus avancée qui lui convient, elle la propose au début du mois suivant ; sinon, son travail à préparer passe à l'étape suivante dans sa classe. Le tuteur reçoit le résultat. L'enfant voit sa nouvelle étape, jamais une comparaison.

---

## 2. Les faits que le moteur lit

Liste fermée. Le moteur ne lit rien d'autre et ne demande aucune saisie de plus à l'enseignant [DÉCIDÉ 14/10 et 12/11].

| N° | Fait | Qui le produit, et comment |
|---|---|---|
| 1 | Cours prévu | La direction, au calendrier de la Classe |
| 2 | Séance tenue, reportée, annulée ou sans enseignant | L'application, à la clôture |
| 3 | Présence : présent (le retard compte comme présent), absent, « Présence pas encore connue » | L'application, en salle |
| 4 | Page où la classe s'est arrêtée | L'enseignant, un geste après la séance |
| 5 | Confirmation : points « À renforcer », « prêt pour un petit bilan », suite (« Continuer », « Renforcer », « Suspendre le nouveau ») | L'enseignant, gestes existants |
| 6 | « Entendu » ou « À renforcer » sur la leçon manquée | L'enseignant, un geste au cours suivant [DÉCIDÉ 12/11] |
| 7 | Sourate validée | L'enseignant, geste existant |
| 8 | Étape, date d'entrée dans l'étape, durée prévue, date limite | L'application et la direction |
| 9 | Petit bilan ou examen planifié, tenu, résultat | L'enseignant et la direction |
| 10 | Travail à préparer donné, puis marqué fait ; « J'ai rattrapé ce cours » | L'enseignant (déjà) ; l'élève ou le tuteur |
| 11 | Pause d'un mois, pause d'exception, demande d'arrêt, arrêt | La famille ; la direction |
| 12 | Calendrier : fermetures, reprises, rencontres de récitation | La direction, une fois par an |
| 13 | Profil : naissance, Interface guidée, tuteur, fuseau, langue, entrée par entretien, nouveau converti | L'inscription |
| 14 | Classe et enseignant, changements | La direction |
| 15 | Message lu | L'application |
| 16 | Lecture enregistrée disponible pour une leçon | Le directeur, dans la Bibliothèque |

**Un fait inconnu n'est jamais un fait négatif** [ARBITRÉ : on ne punit pas une panne]. « Présence pas encore connue » n'est jamais une absence ; un travail n'est « non fait » qu'après son délai ; une confirmation absente ne veut dire ni « Acquis » ni « À renforcer ».

---

## 3. Les états

### 3.1 Les états d'un élève

Liste fermée : 20 états en six familles. Au plus un état par famille ; un élève peut en avoir un dans chaque famille à la fois.

| Famille | États, du plus léger au plus grave | Règle |
|---|---|---|
| Cadre | En pause · Arrêt | Sans eux, l'élève est actif. Ils **gèlent toutes les autres familles** |
| Présence | Régulier · Un cours à rattraper · Absences répétées, degré 1 · degré 2 · degré 3 · Absence longue | Le plus grave l'emporte |
| Reprise | En entrée · Retour | Le temps du plan de reprise |
| Travail et maîtrise | Travail non fait, répété · À soutenir · En avance | « Travail non fait » l'emporte sur « À soutenir » (la cause d'abord) ; « En avance » exclut les deux |
| Temps | Date limite proche · Date limite dépassée et plan de soutien | Aucun des deux : dans les temps |
| Évaluation | Prêt pour un petit bilan · Prêt pour l'examen · En attente de résultat · Nouvelle vérification à passer · Fin de niveau et orientation | Un cycle |

**Exclusions de plus.** « En avance » ne tient pas avec un état de la famille Temps ; « Absence longue » ne tient pas avec « En entrée » ; « Fin de niveau et orientation » éteint la famille Temps.

**Priorité quand plusieurs règles veulent parler le même jour** [ARBITRÉ : la plus grave passe, le reste attend le message de la semaine] : 1. pause, arrêt ; 2. date limite dépassée ; 3. absence longue, degré 3 ; 4. évaluation dont la date est fixée ; 5. degré 2 ; 6. date limite proche ; 7. degré 1 ; 8. un cours à rattraper ; 9. travail et maîtrise ; 10. le reste. Les tâches, elles, apparaissent toujours tout de suite.

**L'élève ne voit jamais le nom d'un état**, seulement ce qu'il a à faire : « Rattraper ce cours », « Travail à préparer », « Petit bilan au cours de mercredi ».

### 3.2 Les passages

« Fenêtre » : les 12 derniers cours prévus pour l'élève, séances tenues seulement ; les cours en pause, en fermeture, reportés ou sans enseignant ne comptent pas [DÉCIDÉ 12/11 ; ARBITRÉ : compter des cours, et non des jours, gèle seul les compteurs].

| De | Vers | Condition exacte |
|---|---|---|
| Régulier | Un cours à rattraper | Absent à une séance tenue |
| Un cours à rattraper | Régulier | Cours rattrapé ou cours suivant atteint, moins de 2 absences dans la fenêtre |
| Plus léger | Degré 1 | 2 absences dans la fenêtre |
| Degré 1 | Degré 2 | 3 absences, ou 2 cours de suite non rattrapés |
| Degré 2 | Degré 3 | 4 absences ou plus |
| Tout état de présence | Absence longue | 6 absences de suite |
| Degré 1, 2, 3 | Degré inférieur | Absences redescendues sous le seuil |
| Absence longue | Régulier, et Retour | Première présence |
| Actif | En pause | Pause commencée |
| En pause | Actif, et Retour | Fin de la pause |
| (aucun) | En entrée | Entrée dans une Classe |
| En entrée, Retour | (aucun) | Fin du plan : 4 semaines, 2 semaines |
| (aucun) | Travail non fait, répété | 3 semaines de suite à au moins 2 travaux sur 3 non marqués faits à temps |
| Travail non fait | (aucun) | Une semaine où tout est fait |
| (aucun) | À soutenir | Même point « À renforcer » sur 3 semaines (3 confirmations), élève présent, travail fait |
| À soutenir | (aucun) | Point sorti sur 2 confirmations de suite, ou décision de la direction |
| (aucun) | En avance | « Prêt pour un petit bilan » avant 75 % de la durée prévue |
| En avance | (aucun) | Résultat posé |
| (aucun) | Date limite proche | Étape non validée, au plus un quart du temps restant, aucun petit bilan prévu |
| Date limite proche | (aucun) | Petit bilan planifié, ou étape validée |
| (aucun) ou proche | Date limite dépassée et plan de soutien | Date limite passée, étape non validée |
| Date limite dépassée | (aucun) | Étape validée, ou changement de classe |
| (aucun) | Prêt pour un petit bilan | « Prêt pour un petit bilan » marqué (étapes 1 à 3) |
| (aucun) | Prêt pour l'examen | Examen de fin des bases proposé |
| Prêt | En attente de résultat | Évaluation tenue |
| En attente de résultat | (aucun) | « Étape validée » ou « Quelques points sont à renforcer » |
| En attente de résultat | Nouvelle vérification à passer | « Une nouvelle vérification est nécessaire », ou demande du tuteur |
| Nouvelle vérification | En attente de résultat | Vérification tenue |
| En attente (examen) | Fin de niveau et orientation | Examen : « Étape validée » |
| Fin de niveau | (aucun) | Orientation posée |
| Actif | Arrêt | Arrêt confirmé (le tuteur décide pour un mineur) |
| Arrêt | En entrée | Retour : nouvelle entrée |

### 3.3 Les états d'une Classe

| État | Condition exacte | Fin |
|---|---|---|
| Dans les temps | Aucun autre état | - |
| Écart qui se creuse | 40 % ou plus des présents avec un point « À renforcer » à la dernière confirmation | Sous 40 % sur 2 confirmations |
| Écart durable | Écart depuis 4 semaines | Écart refermé, ou répartition |
| Sans enseignant | Aucun enseignant à l'heure | Remplaçant entré, ou séance reportée |
| Séance non confirmée | Pas de confirmation 2 heures après | Confirmation |

### 3.4 Les états d'un enseignant

| État | Condition exacte |
|---|---|
| Séance non confirmée | Une séance sans confirmation après 24 heures |
| Confirmations en retard, répétées | 3 sur 4 semaines |
| Absent | Séance remplacée ou reportée |
| Absence prolongée | Plus de 14 jours sans tenir sa Classe [DÉCIDÉ 30/09] |

**Un indicateur seul ne sanctionne jamais un enseignant** [DÉCIDÉ 12/11] : il ouvre une conversation avec la direction. La règle de paie en vigueur n'est pas du ressort du moteur.

---

## 4. Le catalogue des règles

32 règles, même gabarit. **Conventions** :
- « Tuteur » vaut pour un mineur ; l'adulte reçoit lui-même [DÉCIDÉ 12/11], le même modèle au « vous » direct, écrit seulement s'il diffère.
- Canal : application, et push pour le tuteur et l'adulte (catégorie « suivi »). « + courriel » marque une trace [DÉCIDÉ 01/11].
- **Jamais le prénom d'un mineur dans un push** : il dit « votre enfant ». Un enfant n'a ni push, ni courriel, ni liste de notifications : seulement les cartes de son accueil, au tutoiement.
- Remontée « par défaut » : garde-fou 12.
- Variables : `{prénom}`, `{date}`, `{page}`, `{nombre}`, `{étape}`, `{date_limite}`, `{heure}`, `{mois}`, `{action}`.

### Règle 1 · Un cours à rattraper
- **Couvre** : 3.1, 3.16 (panne de l'élève), 4.b, 4.f.
- **Condition** : séance tenue, élève actif absent (jamais « Présence pas encore connue »). **Moment** : clôture de la séance.
- **Système** : crée « Rattraper ce cours » : la page, les lectures enregistrées du jour (3 écoutes, 5 répétitions), le travail à préparer, le bouton « J'ai rattrapé ce cours ». Sans enregistrement : « La lecture enregistrée de cette leçon n'est pas encore disponible. »
- **Messages, le jour même** : push : « Un cours à rattraper avant le prochain cours. » Tuteur : « {prénom} a manqué le cours du {date}. La classe s'est arrêtée page {page}. Faites « Rattraper ce cours » avec lui avant le prochain cours. » Enfant : « Tu as manqué le cours. Avec ton tuteur, écoute la leçon, répète-la, puis appuie sur « J'ai rattrapé ce cours ». »
- **Responsable** : aucun ; avant 10 ans, le tuteur confirme. **Remontée** : règles 3 et 4. **Clôture** : cours rattrapé, ou cours suivant.
- **Jamais** : un autre créneau, un cours refait ou remboursé, une phrase qui minimise l'absence.

### Règle 2 · Vérifier au cours suivant
- **Couvre** : 3.1, 4.b. **Condition** : présent au premier cours après une absence. **Moment** : ouverture de la séance.
- **Système** : « a manqué le dernier cours » à côté du nom ; geste « Entendu » ou « À renforcer » proposé.
- **Messages** : aucun. **Responsable** : l'enseignant, une minute, dans le tour normal. **Remontée** : aucune ; sans geste, rien n'est déduit. **Clôture** : confirmation.
- **Jamais** : arrêter la classe ; au-delà d'une minute, le reste devient travail à préparer.

### Règle 3 · Cours non rattrapé
- **Couvre** : 4.c. **Condition** : tâche encore ouverte au cours suivant, ou geste « À renforcer ». **Moment** : clôture du cours suivant.
- **Système** : ferme la tâche ; met les points dans le travail à préparer, « À renforcer » ; compte un non rattrapé de suite.
- **Messages** : dans le message de la semaine. **Responsable** : aucun. **Remontée** : 2 de suite : règle 5. **Clôture** : un cours rattrapé remet le compte à zéro.
- **Jamais** : reculer la date limite.

### Règle 4 · Absences répétées, degré 1
- **Couvre** : 3.2 ; profils 2.1, 2.6, 2.9. **Condition** : 2 absences dans la fenêtre. **Moment** : clôture de la séance.
- **Système** : envoie le nombre exact et la règle, le jour même.
- **Messages** : tuteur : « {prénom} a manqué {nombre} des 12 derniers cours. La classe avance sans attendre : chaque cours manqué se rattrape avant le suivant, avec « Rattraper ce cours ». » Adulte : « … Votre emploi du temps de révision vous y aide. »
- **Responsable** : le système. **Remontée** : règle 5. **Clôture** : sortie du degré ; même message pas avant 14 jours.
- **Jamais** : une série de jours qui punit, une sanction annoncée.

### Règle 5 · Absences répétées, degré 2
- **Couvre** : 3.2, 4.c. **Condition** : 3 absences dans la fenêtre, ou 2 cours de suite non rattrapés. **Moment** : clôture de la séance.
- **Système** : liste de l'enseignant : « Confirmer le message à la famille de {prénom} », un geste : « Envoyer ».
- **Messages** : tuteur : « {prénom} a manqué {nombre} des 12 derniers cours. Son enseignant vous demande de veiller à ce qu'il rattrape chaque cours avant le suivant. Nous comptons sur vous. » Adulte : « … Si votre semaine ne le permet plus, vous pouvez demander une pause d'un mois. »
- **Responsable** : l'enseignant, avant le cours suivant. **Remontée** : sans geste, le système envoie le message signé « l'équipe pédagogique » ; la direction le voit hors délai [ARBITRÉ : la famille ne pâtit pas d'un oubli]. **Clôture** : envoyé, ou sortie du degré.
- **Jamais** : un texte écrit à la main ; un reproche.

### Règle 6 · Absences répétées, degré 3
- **Couvre** : 3.2 ; profils 2.3, 2.6. **Condition** : 4 absences ou plus. **Moment** : clôture de la séance.
- **Système** : alerte direction « Échanger avec la famille de {prénom} », avec les dates et trois décisions : reprendre, demander une pause d'un mois, changer d'horaire au début du mois suivant.
- **Messages** : « Nous allons vous contacter dans les prochains jours au sujet de la régularité de {prénom}. »
- **Responsable** : la direction, 7 jours. **Remontée** : par défaut. **Clôture** : décision notée.
- **Jamais** : une sanction annoncée à l'enfant ; l'argent face à l'enfant.

### Règle 7 · Absence longue
- **Couvre** : 3.3. **Condition** : 6 absences de suite, sans pause. **Moment** : clôture de la séance.
- **Système** : remplace l'alerte du degré 3 ; regroupe les « Rattraper ce cours » ouverts en une tâche « Reprendre avec la classe » (règle 10) ; propose « Accorder une pause d'exception » (motif, date de fin, nom) ou « Rappeler la famille ».
- **Messages** : celui de la règle 6, s'il n'est pas parti.
- **Responsable** : la direction, 3 jours. **Remontée** : par défaut. **Clôture** : pause d'exception, ou présence.
- **Jamais** : une pause de quelques jours ; reculer la date limite sans pause.

### Règle 8 · Pause d'un mois
- **Couvre** : 3.3, 3.13 ; profil 2.6. **Condition** : demande 7 jours avant un mois civil entier, total de 2 mois sur 12 au plus. **Moment** : à la demande.
- **Système** : accepte ; recule la date limite d'un mois ; garde la place ; gèle les compteurs. Mois non facturé.
- **Messages** (+ courriel) : « La pause d'un mois de {prénom} est acceptée pour {mois}. Sa date limite recule d'autant. Sa place est gardée. »
- **Responsable** : aucun. **Remontée** : règle 9. **Clôture** : fin du mois.
- **Jamais** : une pause de quelques jours, ou en cours de mois hors pause d'exception.

### Règle 9 · Pauses répétées
- **Couvre** : 3.14. **Condition** : plus de 2 mois de pause sur 12. **Moment** : à la demande.
- **Système** : n'accepte pas seul ; direction : « Accepter, ou proposer un arrêt ».
- **Messages** : « Votre demande est transmise à la direction, qui vous répond sous 3 jours. »
- **Responsable** : la direction, 3 jours. **Remontée** : par défaut ; sans réponse, l'élève reste inscrit [ARBITRÉ : le silence ne décide pas]. **Clôture** : décision.
- **Jamais** : des pauses sans fin.

### Règle 10 · Retour de pause ou d'absence longue
- **Couvre** : 3.3, 3.13. **Condition** : fin de pause, ou présence après absence longue. **Moment** : reprise.
- **Système** : plan de reprise de 2 semaines dans l'emploi du temps de révision (leçons manquées, lectures enregistrées) ; « reprend après une pause » à côté du nom.
- **Messages** : « Bon retour à {prénom}. Un plan de reprise de deux semaines l'attend dans son emploi du temps de révision. » Enfant : « Bon retour ! Voici ce que la classe a appris. »
- **Responsable** : l'enseignant l'écoute dans son tour normal. **Remontée** : règles 14, 23. **Clôture** : 2 semaines.
- **Jamais** : un entretien de lecture imposé après un mois de pause.

### Règle 11 · Entrée d'un élève
- **Couvre** : entrée commune, 2.1 à 2.9, 3.17. **Condition** : inscription dans une Classe. **Moment** : à l'inscription.
- **Système** : pose l'étape (1 pour un débutant, sinon celle de la direction), la date limite depuis ce jour, la matière secondaire de l'âge. Classe lancée : plan d'entrée de 4 semaines avec les lectures enregistrées déjà vues. Élève qui dit lire, ou sans cours depuis 3 mois : direction, « Fixer l'entretien de lecture », 7 jours [ARBITRÉ : étape juste avant le premier mois]. Nouveau converti : direction, « Écrire un mot d'accueil », 3 jours.
- **Messages** : « {prénom} commence l'étape {étape}. Premier cours le {date}. Son emploi du temps de révision est prêt. » Adulte : « Vous commencez l'étape {étape}, à finir avant le {date_limite}… »
- **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : étape posée, tâches faites.
- **Jamais** : faire revenir la classe en arrière ; plus de 4 débutants par classe.

### Règle 12 · Premier mois : placement et nouvelles
- **Couvre** : 2.5, 2.8. **Condition** : 14 jours après un placement par entretien ; 1 mois après l'entrée d'un nouveau converti. **Moment** : chaque nuit.
- **Système** : enseignant : « Le placement de {prénom} convient-il ? » : « Convient » ou « Proposer un changement d'étape ». Direction : « Prendre des nouvelles de {prénom} », 7 jours.
- **Messages** : aucun. **Responsable** : l'enseignant, jusqu'à la fin de la 3ᵉ semaine ; la direction. **Remontée** : sans geste, le placement reste [ARBITRÉ : pas de corvée de plus]. **Clôture** : geste, ou délai.
- **Jamais** : changer l'étape sans la direction.

### Règle 13 · Travail non fait, répété
- **Couvre** : 3.4 ; profils 2.2, 2.3. **Condition** : 3 semaines de suite à au moins 2 travaux sur 3 non marqués faits avant le cours suivant. Tant que ce marquage n'existe pas (partie 8.2), une semaine compte quand le point du travail reste « À renforcer » à la confirmation suivante, comme le dit le document des scénarios ; la règle 14 s'ouvre alors aussi [ARBITRÉ : ne perdre aucun signal en attendant]. **Moment** : chaque nuit, fin de semaine.
- **Système** : une phrase dans chaque message de la semaine concerné ; à la 3ᵉ, direction : « Écrire à la famille de {prénom} », texte prêt, un geste.
- **Messages** : « Ces trois dernières semaines, le travail à préparer de {prénom} n'a pas été fait. Revoyez avec lui son emploi du temps de révision : quelques minutes chaque jour suffisent. »
- **Responsable** : la direction, 7 jours. **Remontée** : par défaut. **Clôture** : une semaine où tout est fait.
- **Jamais** : retarder la classe, punir devant les autres, une récompense matérielle.

### Règle 14 · À soutenir
- **Couvre** : 3.8, 3.9. **Condition** : même point « À renforcer » sur 3 semaines (3 confirmations), élève présent, travail fait (provisoirement, sans condition de travail : règle 13). **Moment** : à chaque confirmation.
- **Système** : enseignant : « {prénom} : ce point reste à renforcer depuis 3 semaines. Choisir la suite. » L'élève voit seulement le point dans son travail à préparer.
- **Messages** : aucun. **Responsable** : l'enseignant, 7 jours : « Renforcer », « Suspendre le nouveau », « Signaler à la direction ». **Remontée** : signalement, ou point encore là 2 semaines après : direction, « Entretien avec la famille », 14 jours. **Clôture** : point sorti, ou décision.
- **Jamais** : un mot qui juge ; une comparaison ; reculer la date limite.

### Règle 15 · Date limite proche
- **Couvre** : 3.5. **Condition** : étape non validée, au plus un quart du temps restant, aucun petit bilan prévu. **Moment** : chaque nuit.
- **Système** : renforce l'emploi du temps de révision ; enseignant : « {prénom} : date limite le {date_limite}. Proposer un petit bilan, ou confirmer le plan renforcé. »
- **Messages** : tuteur (seul porteur de la date de 6 à 9 ans) : « {prénom} doit finir son étape avant le {date_limite}. Son emploi du temps de révision est renforcé : suivez-le avec lui chaque jour. » Élève de 10 à 17 ans, carte : « À finir avant le {date_limite}. Ton emploi du temps de révision t'aide à y arriver. »
- **Responsable** : l'enseignant, 7 jours. **Remontée** : par défaut. **Clôture** : petit bilan planifié, ou étape validée.
- **Jamais** : l'étiquette « en retard » ; repousser la date.

### Règle 16 · Date limite dépassée et plan de soutien
- **Couvre** : 3.6, 3.9. **Condition** : date limite passée, étape non validée ; puis nouvelle date ferme passée. **Moment** : chaque nuit.
- **Système** : direction, le jour même : « Bilan avec la famille de {prénom} », 7 jours ; avis de l'enseignant en quelques lignes, 3 jours. Bilan noté : nouvelle date ferme (4 semaines), plan de soutien. Seconde date manquée : « Classe de son niveau réel » ; à défaut, son étape réelle et une nouvelle date limite dans sa classe.
- **Messages** (+ courriel) : « Comme convenu, le plan de soutien de {prénom} commence. Nouvelle date : {date}. Ce qu'il a validé reste acquis. » Enfant de 6 à 9 ans : rien.
- **Responsable** : la direction, 7 jours. **Remontée** : par défaut. **Clôture** : étape validée, ou changement de classe.
- **Jamais** : tout recommencer ; perdre un acquis ; montrer le bilan à un enfant de 6 à 9 ans.

### Règle 17 · En avance
- **Couvre** : 3.7, 3.8. **Condition** : « prêt pour un petit bilan » avant 75 % de la durée prévue. **Moment** : confirmation.
- **Système** : montre à l'enseignant les points « Acquis » puis « Stable » ; enchaîne la règle 18. Après « Étape validée », cherche une classe plus avancée (même âge, même genre, horaire possible, place libre) : direction, « Proposer le passage au début du mois suivant », 7 jours ; sinon, travail et lectures enregistrées de l'étape suivante dans sa classe.
- **Messages** : règle 19. **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : passage, ou étape suivante suivie.
- **Jamais** : le freiner, sauter une vérification, le donner en exemple.

### Règle 18 · Prêt pour un petit bilan
- **Couvre** : 3.5, 3.7, 3.8. **Condition** : « prêt pour un petit bilan » marqué (étapes 1 à 3). **Moment** : confirmation.
- **Système** : enseignant : « Petit bilan de {prénom}, pendant un cours normal », 14 jours. Carte de l'élève : « Petit bilan au cours du {date}. »
- **Messages** : la carte seulement. **Responsable** : l'enseignant, 14 jours. **Remontée** : par défaut. **Clôture** : bilan tenu.
- **Jamais** : un passage automatique.

### Règle 19 · Résultat d'une évaluation
- **Couvre** : 3.6, 3.7, 3.19, 3.21. **Condition** : petit bilan ou examen tenu. **Moment** : à la tenue, puis chaque nuit.
- **Système** : direction : « Confirmer le résultat », 7 jours. « Étape validée » : nouvelle étape et date limite ; « Quelques points sont à renforcer » : points dans le travail à préparer ; « Une nouvelle vérification est nécessaire » : règle 20.
- **Messages** : « Étape validée pour {prénom}. Il commence l'étape {étape}. » ou « Quelques points sont à renforcer pour {prénom}. Ils sont dans son travail à préparer. » Enfant : « Bravo, tu commences une nouvelle étape ! »
- **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : résultat annoncé.
- **Jamais** : un autre mot que les trois résultats ; une note brute.

### Règle 20 · Nouvelle vérification à passer
- **Couvre** : 3.16, 3.19. **Condition** : ce résultat, une demande du tuteur, ou une panne pendant l'évaluation. **Moment** : à l'événement.
- **Système** : direction : « Planifier la nouvelle vérification, par une autre personne que l'enseignant de la classe », 14 jours (panne : 7, la tentative ne compte pas) ; à une demande du tuteur, joint les points « À renforcer » et le critère.
- **Messages** (+ courriel) : « La nouvelle vérification de {prénom} aura lieu le {date}. »
- **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : vérification tenue.
- **Jamais** : un passage imposé par la famille ; un résultat pendant une panne.

### Règle 21 · Examen de fin des bases
- **Couvre** : 3.21. **Condition** : proposition de l'enseignant ; ou rien à 4 semaines de la date limite de l'étape 4. **Moment** : proposition ; chaque nuit.
- **Système** : rappel : « Proposer l'examen de fin des bases quand {prénom} est prêt, au plus tard le {date_limite}. » Proposé : direction, « Planifier l'examen », 14 jours, séance ouverte ou non à la famille.
- **Messages** (+ courriel) : « L'examen de fin des bases de {prénom} aura lieu le {date} à {heure}. »
- **Responsable** : l'enseignant, puis la direction. **Remontée** : date limite atteinte : règle 16. **Clôture** : examen tenu.
- **Jamais** : un examen sans proposition de l'enseignant.

### Règle 22 · Fin des bases et orientation
- **Couvre** : 3.21. **Condition** : examen, « Étape validée ». **Moment** : annonce.
- **Système** : prépare l'attestation des bases. Enfant aux acquis stables : « mémoriser le Coran » par défaut, « Demander lire tout le Coran » offert au tuteur. Adulte : son choix, sur conseil de l'enseignant (7 jours).
- **Messages** (+ courriel) : « {prénom} a terminé les bases. Son attestation est prête. Suite proposée : mémoriser le Coran ; vous pouvez demander lire tout le Coran. » Adulte : « … Choisissez la suite : lire tout le Coran ou le mémoriser. »
- **Responsable** : l'enseignant. **Remontée** : adulte sans choix à 14 jours : la direction l'appelle. **Clôture** : orientation posée.
- **Jamais** : « ijaza » sur une attestation.

### Règle 23 · Écart qui se creuse dans une Classe
- **Couvre** : 3.10. **Condition** : 40 % ou plus des présents avec un point « À renforcer » ; durable à 4 semaines. **Moment** : confirmation ; chaque nuit.
- **Système** : propose à l'enseignant une séance de consolidation et un travail ciblé ; à 4 semaines, direction : « Étudier une nouvelle répartition au début du mois suivant », 14 jours.
- **Messages** : aucun ; seuils jamais affichés. **Responsable** : l'enseignant avance avec la majorité ; la direction. **Remontée** : par défaut. **Clôture** : écart refermé, ou répartition.
- **Jamais** : arrêter la classe pour un élève ; un classement.

### Règle 24 · Séance non confirmée
- **Couvre** : 4.b. **Condition** : séance tenue sans confirmation. **Moment** : 2 heures, puis 24 heures après.
- **Système** : rappel « Confirmer la séance du {date} » ; à 24 heures, alerte direction. Sans page confirmée, « Rattraper ce cours » dit : « Page du dernier cours confirmé. »
- **Messages** : aucun aux familles. **Responsable** : l'enseignant ; la direction, 2 jours. **Remontée** : 3 retards sur 4 semaines : tableau de bord, pour une conversation. **Clôture** : confirmation.
- **Jamais** : une sanction tirée de ce seul indicateur.

### Règle 25 · Classe sans enseignant
- **Couvre** : 3.15. **Condition** : aucun enseignant à l'heure ; titulaire absent plus de 14 jours. **Moment** : à l'heure ; chaque nuit.
- **Système** : laisse agir le circuit de remplacement existant [DÉCIDÉ 07/11] ; **aucun** « Rattraper ce cours » pour une séance reportée. Personne à 30 minutes : « Séance reportée · Nouvelle date à venir », direction « Fixer la nouvelle date ». Plus de 14 jours : direction « Affecter un autre enseignant ».
- **Messages** : ceux du circuit existant. **Responsable** : la direction, 3 jours. **Remontée** : par défaut. **Clôture** : date fixée, enseignant affecté.
- **Jamais** : faire rattraper un cours que l'académie n'a pas donné.

### Règle 26 · Changement de classe, d'horaire ou d'enseignant
- **Couvre** : 3.6, 3.9, 3.10, 3.11, 3.17. **Condition** : décision de la direction. **Moment** : au changement.
- **Système** : garde étape, acquis, date limite et tâches ; le nouvel enseignant voit tout. Classe plus avancée : plan d'entrée de 4 semaines.
- **Messages** : « {prénom} rejoint sa nouvelle Classe le {date}. Son étape et ce qu'il a validé restent les mêmes. »
- **Responsable** : aucun. **Remontée** : aucune. **Clôture** : premier cours.
- **Jamais** : changer le contenu de l'étape, effacer un acquis.

### Règle 27 · Changement de tranche d'âge
- **Couvre** : 3.12 ; profils 2.1 à 2.3. **Condition** : 10, 14 ou 18 ans. **Moment** : chaque nuit.
- **Système** : la date limite en cours reste ; la nouvelle durée vaut à l'étape suivante. À 10 ans : Al-Fatiha si besoin, et « à finir avant le… » visible. À 18 ans : direction, « Passage en classe d'adultes à la fin de l'étape », 3 mois au plus.
- **Messages** : à 18 ans : « Vous recevez désormais vous-même les messages de votre suivi. »
- **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : passage fait.
- **Jamais** : raccourcir une date limite en cours ; changer le contenu.

### Règle 28 · Le tuteur qui ne suit pas
- **Couvre** : 3.18 ; profils 2.1, 2.7. **Condition** : 3 semaines sans message lu, cours rattrapé ni travail fait. **Moment** : chaque nuit.
- **Système** : direction, « Appeler le tuteur de {prénom} », 7 jours.
- **Messages** : aucun de plus. **Responsable** : la direction. **Remontée** : par défaut. **Clôture** : appel noté, ou le tuteur agit.
- **Jamais** : faire porter la faute à l'enfant ; parler d'argent.

### Règle 29 · Demande d'arrêt
- **Couvre** : 3.20. **Condition** : demande du tuteur ou de l'adulte. **Moment** : à la demande.
- **Système** : direction, « Écouter la raison et proposer : pause d'un mois, autre horaire, classe plus adaptée », 7 jours. Arrêt confirmé : tout gelé, acquis gardés, tâches fermées.
- **Messages** (+ courriel) : « Votre demande est bien reçue. La direction vous appelle dans les 7 jours. Ce que {prénom} a validé reste acquis. »
- **Responsable** : la direction ; pour un mineur, le tuteur décide. **Remontée** : par défaut. **Clôture** : arrêt, ou reprise.
- **Jamais** : culpabiliser ; l'argent face à l'enfant. L'argent suit la décision unique en préparation [DÉCIDÉ 07/11].

### Règle 30 · Fermeture qui approche et reprise
- **Couvre** : calendrier, 3.13. **Condition** : fermeture dans 7 jours ; reprise demain. **Moment** : chaque nuit.
- **Système** : gèle les compteurs ; recule les dates limites d'autant ; annonce dans le message de la semaine ; rappel la veille de la reprise.
- **Messages** : « L'académie ferme du {date} au {date}. Les dates limites reculent d'autant. Reprise le {date}. » Enfant : « L'école reprend le {date}. »
- **Responsable** : aucun. **Remontée** : aucune. **Clôture** : reprise.
- **Jamais** : une fermeture comptée comme absence.

### Règle 31 · Rencontre de récitation
- **Couvre** : calendrier. **Condition** : rencontre dans 14 jours, puis demain. **Moment** : chaque nuit.
- **Système** : invite chaque élève actif ; rappel la veille.
- **Messages** : « Rencontre de récitation le {date} à {heure}. {prénom} peut réciter ce qu'il a appris. » Enfant : « Bientôt la rencontre de récitation : tu pourras réciter ! »
- **Responsable** : aucun. **Remontée** : aucune. **Clôture** : rencontre passée.
- **Jamais** : en faire passer une étape.

### Règle 32 · Le message de la semaine
- **Couvre** : 3.4, 3.18 ; tous les profils. **Condition** : élève actif. **Moment** : samedi 10 h, heure du foyer [ARBITRÉ : moment calme avant la semaine].
- **Système** : un message par famille, une ligne par élève, une seule action : la plus haute de la priorité (partie 3.1), sinon « Suivre l'emploi du temps de révision ».
- **Messages** : « Cette semaine, {prénom} a suivi {nombre} cours sur 3. Étape : {étape}. À faire avant lundi : {action}. »
- **Responsable** : aucun. **Remontée** : aucune. **Clôture** : envoyé.
- **Jamais** : comparer deux élèves ; un parent et son enfant côte à côte ; un texte de pression.

---

## 5. Les garde-fous du moteur

1. **Une fois pour un même fait.** Chaque déclenchement porte la règle, l'élève et le fait cause. Le même fait ne redéclenche jamais la même règle, même si le calcul tourne deux fois.
2. **Plafond.** 3 messages pédagogiques par famille et par semaine au plus, plus le message de la semaine [DÉCIDÉ 12/11]. Hors plafond : le circuit des séances, une date d'examen ou de bilan fixée, un résultat. Au-delà, le message attend le message de la semaine ; la tâche est déjà dans la liste.
3. **Heures calmes** : 21 h à 8 h, heure du destinataire [ARBITRÉ : soir et nuit des familles]. « Le jour même » : avant 21 h, sinon le lendemain à 8 h.
4. **Priorité.** Une alerte ouverte par élève et par famille d'états ; la plus grave remplace l'autre et garde son historique.
5. **Fait manquant.** « Présence pas encore connue » ne compte jamais ; restée 48 heures, la séance apparaît au journal de la direction, qui peut corriger.
6. **Pannes.** Un calcul de nuit manqué reprend la nuit suivante, sans doubler un message. Une panne de l'académie ne crée aucune absence.
7. **Gel.** Pause, fermeture, séance reportée ou sans enseignant : compteurs immobiles ; dates limites reculées pour une pause ou une fermeture.
8. **Courriel** : seulement les traces marquées « + courriel » [DÉCIDÉ 01/11]. Jamais à un enfant.
9. **Mineurs** : ni push, ni courriel, ni liste de notifications ; le tuteur reçoit ; jamais d'argent face à l'enfant.
10. **Journal.** Tout s'écrit : date, règle, élève, fait, action, destinataire, message envoyé ou retenu et pourquoi. La direction le lit par élève, Classe ou règle.
11. **Suspension.** La direction suspend une règle pour un élève, avec motif, date de fin (90 jours au plus) et son nom [DÉCIDÉ 14/10, règle de stabilité 3].
12. **Remontée.** Hors délai, l'alerte d'un enseignant passe à la direction ; celle de la direction passe en rouge et entre dans le résumé du jour du directeur.

---

## 6. La table des réglages

Tous se changent par la direction, sauf ceux marqués « directeur » (valeurs du programme, par décision datée).

| Réglage | Défaut | Source |
|---|---|---|
| Fenêtre des absences | 12 derniers cours prévus | DÉCIDÉ 12/11 |
| Degrés 1, 2, 3 | 2, 3, 4 absences ; 2 non rattrapés de suite (degré 2) ; délais : cours suivant, 7 jours | DÉCIDÉ 12/11 |
| Absence longue | 6 absences de suite ; direction 3 jours | ARBITRÉ : deux semaines de cours ; délai DÉCIDÉ 12/11 |
| Rattraper ce cours | 3 écoutes, 5 répétitions ; une minute au cours suivant | DÉCIDÉ 12/11 |
| Plans de reprise | 2 semaines (retour), 4 (entrée) | DÉCIDÉ 12/11 |
| Pause | préavis 7 jours (directeur) ; plafond 2 mois sur 12 ; direction 3 jours | DÉCIDÉ 30/09 et 12/11 |
| Entretien de lecture | après 3 mois sans cours ; fixé sous 7 jours | DÉCIDÉ 12/11 ; délai ARBITRÉ |
| Placement, nouveau converti | 3 semaines, rappel à 14 jours ; nouvelles à 1 mois | DÉCIDÉ 12/11 ; rappel ARBITRÉ : avant la fin de la fenêtre |
| Travail non fait | 2 sur 3 par semaine, 3 semaines ; direction 7 jours | DÉCIDÉ 12/11 ; « 2 sur 3 » ARBITRÉ : plus souvent manqué que fait |
| À soutenir | 3 semaines, 3 confirmations ; direction 14 jours | DÉCIDÉ 12/11 |
| Date limite proche | dernier quart du temps ; enseignant 7 jours | DÉCIDÉ 12/11 |
| Date limite dépassée | nouvelle date 4 semaines (directeur) ; bilan sous 7 jours | DÉCIDÉ 14/10 et 12/11 |
| En avance | « prêt » avant 75 % de la durée prévue | ARBITRÉ : nettement avant le prévu |
| Évaluations | petit bilan sous 14 jours ; nouvelle vérification 14 (7 après panne) | DÉCIDÉ 12/11 |
| Résultat, examen, orientation | confirmation 7 jours ; rappel d'examen 4 semaines avant ; planification 14 jours ; choix d'un adulte 14 jours | ARBITRÉ : une semaine pour confirmer, deux pour planifier ou choisir |
| Écart de Classe | 40 % ; durable à 4 semaines ; avance à 4 enfants sur 5, 5 adultes sur 6 | DÉCIDÉ 14/10 et 12/11 |
| Séance non confirmée | rappel 2 h ; direction 24 h | ARBITRÉ : même soirée, puis lendemain |
| Titulaire absent | 14 jours (directeur) | DÉCIDÉ 30/09 |
| Tuteur qui ne suit pas | 3 semaines ; appel sous 7 jours | DÉCIDÉ 12/11 |
| Passage à 18 ans | fin de l'étape, 3 mois au plus | DÉCIDÉ 12/11 |
| Messages | 3 par semaine et par famille, plus le message de la semaine | DÉCIDÉ 12/11 |
| Message de la semaine ; heures calmes | samedi 10 h ; 21 h à 8 h, heure locale | ARBITRÉ : moments calmes des familles |
| Même message de degré | pas avant 14 jours | ARBITRÉ : ne pas harceler |
| Fermeture ; rencontre de récitation | 7 jours avant ; 14 jours et la veille | ARBITRÉ : le temps de s'organiser |
| Présence inconnue signalée | 48 heures | ARBITRÉ : le temps d'une correction |
| Suspension de règle | 90 jours au plus | ARBITRÉ : un trimestre, puis revoir |

---

## 7. Ce que voit chacun

**Une seule liste « à faire » par personne**, sur l'accueil ; pas d'écran par règle. Chaque ligne dit l'action, pour qui, pour quand.

| Personne | Où | Ce qu'elle voit |
|---|---|---|
| Enfant de 6 à 9 ans | Cartes de l'Interface guidée | « Rattraper ce cours », travail à préparer, petit bilan, sourates ; jamais de date limite, d'argent, de note, d'étiquette |
| Élève de 10 à 17 ans | Accueil, Suivi | Les mêmes cartes et « à finir avant le… » ; pas de liste de notifications |
| Élève adulte | Aujourd'hui | Sa liste, ses messages, son emploi du temps de révision |
| Tuteur | Accueil | Une liste groupée par enfant, les messages, le message de la semaine ; un parent élève a deux listes séparées |
| Enseignant | Aujourd'hui ; en salle, à côté des noms | Messages à confirmer, petits bilans, choix pour un élève à soutenir, séances à confirmer ; « a manqué le dernier cours », « reprend après une pause » |
| Direction | À faire ; tableau de bord | Alertes, journal, suspensions |

**Le tableau de bord de la direction** : cinq chiffres, chacun ouvre sa liste : alertes ouvertes ; alertes hors délai ; élèves avec un plan de soutien ; classes dont l'écart se creuse ; séances non confirmées. Plus le résumé du jour.

---

## 8. Pour les développeurs

### 8.1 Ce qui existe et se réutilise

| Besoin | Existant |
|---|---|
| Présence | `public.etat_presence`, enum `presence_state` (`absente`, `confirmation_en_attente`, `finalisee`), `session_presence_override`, seuils `app_config` |
| Séance tenue | `sessions.status` (`ended`, `teacher_absent`), `private.ses_cloturer_seances_echues` (cron `ses_cloture_auto`), `seance_reportee`, `seance_terminee` |
| Page | `classe_position_reprise`, `position_reprise_classe` |
| Confirmation | `lesson_reports` → `cahier_observations` (`a_renforcer`, `pret_bilan`) |
| Sourates | `sourates_validees` |
| Étape, date limite | `private.etape_eleve`, `suivi_pedagogique_eleve` (`dans_les_temps`, `au_dela_du_prevu`, `date_limite_depassee`) ; `rythme_classe` sans appelant |
| Évaluations | `evaluations`, `evaluation_publications`, `publier_evaluation` |
| Notifications | `public.notifications` (RLS destinataire), `private.notifier_classe`, `notifications_evenement_check`, `message_academie_eleve` (fermé aux mineurs) |
| Push | `push_sortants`, `private.push_evenements` (catégorie `suivi` prévue), `push_preferences`, `private.push_compte_autorise`, cron `push-envoi` |
| Courriel | `courriels_sortants`, `private.notification_courriel` (défaut : application), cron `courriels-envoi`, modèles en 5 langues |
| Réglages, fuseau | `app_config`, `app_config_int` ; `timezone_iana` |
| À émettre | `cahier_en_retard`, déclaré, jamais émis (règle 24) |

### 8.2 Ce qui manque

1. Pauses d'un mois et d'exception : aucune donnée (`pause_seances` est la courte pause en séance) ; `private.etape_eleve` ne recule donc pas la date limite, c'est le seul point à changer.
2. Calendrier de l'école.
3. « Travail marqué fait » et « J'ai rattrapé ce cours ». Le cahier écrit `travail_maison`, les écrans lisent `learning_assignment` que rien n'alimente : à réunir avant la règle 13.
4. Le geste « Entendu » ou « À renforcer ».
5. « Acquis » et « Stable » non stockés. Calcul [ARBITRÉ] : Acquis, point sorti de « À renforcer » sur 2 confirmations ; Stable, confirmé par un petit bilan.
6. Demande d'arrêt ; drapeaux « nouveau converti », « entrée par entretien ».
7. `notifier_classe` écrit des lignes `soi` pour un mineur qui ne peut pas les lire ; le moteur n'en écrit jamais.
8. Textes push en fr et ar seulement.

### 8.3 Architecture

- **Faits** : vues sur l'existant (`suivi_faits_presence_v`, `suivi_faits_confirmation_v`, `suivi_faits_travail_v`) ; tables pour ce qui manque (`pauses_eleve`, `calendrier_ecole`, `travail_fait`, `cours_rattrape`).
- **`suivi_etats_eleve`** `(eleve_id, famille, etat, depuis, fait_cle)`, unique `(eleve_id, famille)`.
- **`suivi_regles`** : catalogue, priorité, actif ; réglages `app_config` sous `suivi.*`.
- **`suivi_declenchements`** : journal, unique `(regle, eleve_id, fait_cle)`, `insert … on conflict do nothing` : l'idempotence est dans la base.
- **`suivi_taches`** : `responsable_role`, `responsable_id`, `action`, `echeance`, `cran`, `etat`, `remplace_par`.
- **`suivi_suspensions`** `(eleve_id, regle, motif, fin, par)`, 90 jours au plus.
- **Évaluation** : `private.suivi_evaluer_eleve(eleve_id, moment)`, `security definer`, `search_path = ''`, par déclencheurs différés (clôture de séance, `lesson_reports`, `sourates_validees`, pauses, évaluations) pour les seuls élèves concernés. Cron `suivi-nuit` (03:00 UTC) sur les élèves dont une date tombe ; cron horaire pour le message de la semaine et les messages retenus par les heures calmes.
- **Envoi** : `private.suivi_notifier(destinataire, gabarit, variables)` applique plafond, heures calmes, mineurs, puis écrit dans `notifications` (codes `suivi_*` ajoutés à la contrainte), push `suivi`, drapeau courriel par code. Gabarits côté serveur, aucune phrase dans Flutter.
- **Droits** : RLS positive. Élève et tuteur lisent leurs tâches, jamais `suivi_etats_eleve` ; l'enseignant, celles de ses Classes ; la direction, tout. Écriture : fonctions du moteur et `suivi_tache_agir`.
- **Performances** : calcul incrémental par élève, index `(eleve_id, debut)`, aucun balayage complet par séance.

### 8.4 Plan de tests : un scénario par règle

| Règle | Entrée → attendu |
|---|---|
| 1 | Absent, séance close → tâche, push sans prénom, rien pour l'enfant ; `confirmation_en_attente` → rien |
| 2 | Présent après absence → mention, geste proposé |
| 3 | Tâche ouverte au cours suivant → close, points « à renforcer », compte 1 |
| 4 | 2ᵉ absence, rejouée → un seul message |
| 5 | 3ᵉ absence sans geste → envoi au cours suivant, journal « hors délai » |
| 6 | 4ᵉ absence → alerte direction 7 jours |
| 7 | 6 de suite → degré 3 remplacé, tâches regroupées |
| 8 | Demande à J-8 → acceptée, date limite + 1 mois, courriel |
| 9 | 3ᵉ mois sur 12 → alerte, pas d'acceptation |
| 10 | Fin de pause → plan de 2 semaines |
| 11 | Classe lancée, élève qui dit lire → étape, plan de 4 semaines, tâche entretien |
| 12 | J+14 après placement → tâche, fermée seule à J+21 |
| 13 | 3 semaines à 1 sur 3 → tâche direction |
| 14 | Même point 3 semaines, travail fait → tâche enseignant, pas de règle 13 |
| 15 | 76 % du temps, enfant de 8 ans → tâche enseignant, carte sans date |
| 16 | Date passée → alerte ; après bilan, + 4 semaines |
| 17 | « Prêt » à 50 % → En avance, recherche de classe après validation |
| 18 | « Prêt » → tâche 14 jours |
| 19 | 8 jours sans résultat → rouge |
| 20 | Demande du tuteur → tâche, autre personne |
| 21 | Étape 4 à J-28 → rappel |
| 22 | Examen validé, enfant stable → orientation par défaut, attestation |
| 23 | 2 sur 5 « à renforcer » → consolidation, rien aux familles |
| 24 | H+2, H+24 → rappel, alerte, `cahier_en_retard` |
| 25 | Séance reportée → aucun « Rattraper ce cours » |
| 26 | Changement de Classe → étape et date identiques |
| 27 | 18 ans → alerte, messages à l'élève |
| 28 | 21 jours inactifs → tâche direction |
| 29 | Demande d'arrêt → tâche, courriel |
| 30 | Fermeture de 10 jours → compteurs gelés, date + 10 jours |
| 31 | J-14 → invitation |
| 32 | 4ᵉ message retenu → repris le samedi |
| Garde-fous | 23 h → part à 8 h ; règle suspendue → rien, journal « suspendue » |

---

## 9. Preuve de couverture

| Situation ou profil | Règles |
|---|---|
| Entrée et date limite communes | 11, 15, 16 |
| 2.1 Enfant de 6 à 9 ans | 1, 4, 15, 28, 32 |
| 2.2 Enfant de 10 à 13 ans | 13, 15, 27 |
| 2.3 Adolescent | 6, 13, 27, 29 |
| 2.4 Adulte débutant | 1, 4, 11, 22 |
| 2.5 Sait déjà lire | 11, 12 |
| 2.6 Adulte très occupé | 4, 5, 6, 8 |
| 2.7 Parent et enfant | 28, 32 |
| 2.8 Nouveau converti | 11, 12 |
| 2.9 Longue interruption | 4, 11 |
| 3.1 Absence isolée | 1, 2 |
| 3.2 Absences répétées | 4, 5, 6 |
| 3.3 Absence longue | 7, 8, 10 |
| 3.4 Travail non fait | 13, 32 |
| 3.5 Retard sur la date limite | 15, 18 |
| 3.6 Date limite dépassée | 16, 19 |
| 3.7 En avance | 17, 18, 19 |
| 3.8 Élève pressé | 14, 17 |
| 3.9 Grande difficulté | 14, 16, 26 |
| 3.10 Écart dans une Classe | 23, 26 |
| 3.11 Changement de classe | 26 |
| 3.12 Tranche d'âge | 27 |
| 3.13 Pause et retour | 8, 10, 30 |
| 3.14 Pauses répétées | 9 |
| 3.15 Enseignant absent | 25 |
| 3.16 Panne | 1, 20 ; garde-fous 5, 6 |
| 3.17 Classe déjà lancée | 11, 26 |
| 3.18 Tuteur qui ne suit pas | 28, 32 |
| 3.19 Passage imposé | 20 |
| 3.20 Arrêt | 29 |
| 3.21 Fin des bases | 21, 22 |
| 4.b Rattraper ce cours | 1, 2, 24 |
| 4.c Non rattrapé | 3, 5 |
| 4.f Sans lecture enregistrée | 1 |
| Calendrier | 30, 31 |
| Message hebdomadaire | 32 |
