# Angles morts : ce que la charte ne couvre pas encore

> **Registre tenu par l'architecte pédagogique (12/11/2026). Chaque ligne est un sujet que la charte ne couvre pas encore. Aucune n'est une question posée au directeur : l'architecte arbitre ce qu'il peut, et dit ce qui dépend d'un contenu ou d'une personne.**

Le 12/11/2026, le directeur a demandé : « qu'est-ce qu'on n'a pas ajouté à ton chantier, qui est lié, qui aura un impact sur le programme et les activités de l'académie, et qu'on a omis dans ces recherches ? À toi de voir. » Ce registre est la réponse écrite.

Chaque fiche a le même gabarit : le sujet, pourquoi il pèse, ce qui existe déjà, la position de l'architecte, la suite. Les fiches sont classées en trois groupes.

- **A.** À traiter maintenant, parce que la charte ne peut pas fonctionner sans.
- **B.** À traiter avant d'ouvrir à de nouvelles familles.
- **C.** À traiter quand l'école grandit.

« Ce qui existe déjà » a été contrôlé dans le dépôt le 12/11/2026. Quand ce n'est pas le cas, c'est écrit « non vérifié ».

---

## Groupe A. À traiter maintenant

### A1. Qui est « la direction » ?

- **Le sujet.** La charte et le moteur donnent à « la direction » des dizaines de gestes avec des délais, et il n'y a aujourd'hui qu'un directeur et une enseignante.
- **Pourquoi il pèse.** Confirmer une étape en 7 jours, faire un bilan avec une famille, mener un entretien de lecture, accepter une pause, appeler un tuteur, assister à un petit bilan sur dix, faire passer un examen par un évaluateur autre que l'enseignant : tout cela tombe sur la même personne. Le directeur veut une école qui tourne sans lui. Si une seule personne tient tout, les délais du moteur seront dépassés dès que la charge monte.
- **Ce qui existe déjà.** La charte nomme des rôles (enseignant titulaire, direction, contrôleur, remplaçant), mais aucun rôle séparé de responsable pédagogique ou d'évaluateur n'est prévu dans le plan, et aucune mesure de charge n'existe.
- **Position de l'architecte.** Nommer des rôles humains distincts : responsable pédagogique, évaluateur, direction générale. Permettre de déléguer chaque type de tâche à une personne. Mesurer la charge (tâches ouvertes par semaine) et l'afficher. Tant qu'une seule personne tient tout, le moteur regroupe ses tâches en un résumé par jour.
- **Suite.** Lot « RÔLES-ET-CHARGE », avant le lot du moteur (lot 7).

### A2. Les messages arrivent-ils vraiment ?

- **Le sujet.** Tout le système vivant repose sur des messages reçus, et la réception n'est prouvée sur aucun vrai téléphone.
- **Pourquoi il pèse.** Les rappels, « Rattraper ce cours » et les seuils d'absences n'ont d'effet que si le tuteur les lit. Les familles vivent sur WhatsApp, et l'application n'est pas dans les magasins d'applications. Un message non reçu ressemble, pour le moteur, à une famille qui ne répond pas.
- **Ce qui existe déjà.** La décision du 01/11/2026 (`DECISION-PUSH-2026-11-01.md`) choisit le push web, avec des clés serveur posées, et les courriels sortants existent (`courriels_sortants`). Cette décision note qu'au 01/11 rien du push n'existait dans le code. La réception sur iPhone et Android n'est pas prouvée. Non vérifié depuis.
- **Position de l'architecte.** Avant le lot du moteur, prouver la réception sur un vrai téléphone, iPhone et Android. Garder le courriel comme filet pour tout message qui demande un geste. Ne jamais supposer qu'un message non lu a été reçu. Le moteur sait si un message a été ouvert et le dit à la direction.
- **Suite.** Lot « RÉCEPTION-PROUVÉE », avant le lot 7.

### A3. La lecture du Coran enseignée : Hafs ou Warsh ?

- **Le sujet.** Le programme dit Hafs, alors que beaucoup de familles d'Afrique de l'Ouest et du Maghreb lisent Warsh.
- **Pourquoi il pèse.** La lecture change le Mushaf affiché, les enregistrements du directeur, la correction et l'examen. Sans prévoir ce choix dans les données, une classe Warsh obligerait à tout recoder.
- **Ce qui existe déjà.** Le tronc commun est Hafs, décidé le 29/09 (`REGISTRE-RECONCILIATION-2026-10-14.md`). Le module des candidatures connaît déjà les lectures : `lib/features/candidature/question_etape.dart` propose hafs, warsh, qalun, shuba, et la table des entretiens garde les lectures observées (migration `20261108000001_v1a_entretiens.sql`). Ce vocabulaire est donc réutilisable. Rien de tel n'existe côté classe ni bibliothèque.
- **Position de l'architecte.** L'école enseigne une lecture par classe, Hafs par défaut comme décidé. La lecture devient une propriété de la classe et de chaque document de la bibliothèque, pour qu'une classe Warsh soit possible sans rien recoder. Rien n'est ouvert en Warsh tant que le directeur n'a pas fourni le Mushaf et les enregistrements. On réutilise la liste des lectures des candidatures.
- **Suite.** Champ prévu dans le lot de la bibliothèque (lot 3). Contenu attendu du directeur.

### A4. L'école juridique des paroles de la prière et des ablutions

- **Le sujet.** Les gestes et certaines paroles de la prière et des ablutions diffèrent selon les écoles, par exemple la position des mains.
- **Pourquoi il pèse.** Le programme enseigne la prière et les ablutions aux enfants, et les familles y sont sensibles. Un document qui ne dit pas quelle voie il suit peut heurter une famille, ou contredire ce que le père enseigne à la maison.
- **Ce qui existe déjà.** Le directeur a décidé que l'enseignant montre la prière en pratique sans fiqh détaillé (13/10). **Fermé le 13/11/2026** : le directeur a décidé que les paroles de la prière et les ablutions sont publiques et connues, sans question d'école juridique pour des débutants, avec pour référence ce qui est enseigné en Arabie saoudite ; les spécialisations sont pour les avancés.
- **Position de l'architecte.** Le texte est écrit dans `CONTENU-PRIERE-ET-ABLUTIONS.md`, qui dit en tête la référence suivie. L'école le dit aussi aux familles, à l'inscription.
- **Suite.** Relecture du directeur (`CONTENUS-ATTENDUS.md`, n° 3). Plus de champ « école suivie » à prévoir pour les bases.

### A5. L'argent et le programme se touchent

- **Le sujet.** Trois points relient l'argent au programme : la pause et l'arrêt temporaire, l'accès suspendu pour impayé, et la paie de l'enseignant versée par élève présent.
- **Pourquoi il pèse.** Une pause d'un mois et un « arrêt temporaire » sont réservés par le directeur, et leurs effets sur la date limite doivent être les mêmes partout. Un accès suspendu pour impayé ne doit pas pénaliser l'élève sur son parcours. Un enseignant payé par élève présent perd de l'argent quand un élève est absent ou en pause, ce qui peut le pousser à ne pas signaler, ou à garder un élève qui devrait changer de classe.
- **Ce qui existe déjà.** La charte fixe déjà « pas de paie pour un élève absent » (DÉCIDÉ 06/11) et la paie d'une séance qui attend le point de fin de séance, qui confirme la partie vue (DÉCIDÉ 05/11). Le lot 2 traite l'interruption temporaire comme une pause pour la pédagogie seulement. En revanche, la mémoire finance (`07_MEMOIRE_PEDAGOGIE_FINANCE.md`) vise un professeur « non pénalisé par le faible remplissage commercial » : les deux textes ne disent pas la même chose pour l'absence d'un élève et doivent être harmonisés.
- **Position de l'architecte.** Pendant un accès suspendu pour impayé, la date limite de l'élève ne court pas : elle recule, et l'enfant ne voit jamais la raison. Aucun indicateur pédagogique ne dépend d'un geste dont l'enseignant tire un gain. La présence vient de l'application, jamais de lui. Ce risque est signalé à la direction comme un point à surveiller.
- **Suite.** À traiter avec le lot d'harmonisation de l'argent du directeur.

### A6. La langue des familles

- **Le sujet.** Les cours se donnent en poular, français et anglais, mais les textes du programme et les messages du moteur n'existent qu'en français, et en partie en arabe.
- **Pourquoi il pèse.** Un parent qui lit mal le français ne comprendra pas « date limite » ni « plan de soutien ». Un moteur qui envoie un message incompris produit le même effet qu'un message jamais envoyé.
- **Ce qui existe déjà.** L'application a des fichiers de traduction générés (`lib/core/i18n/`), au moins en français et en arabe. Les textes du programme et les gabarits du moteur n'y sont pas encore. Le nombre exact de langues de l'application n'a pas été recompté.
- **Position de l'architecte.** Chaque texte du programme et chaque gabarit de message est traduisible dès sa création. Priorité au français, à l'arabe et à l'anglais. Le poular est une langue de cours, à l'oral.
- **Suite.** Lot « LANGUES », déjà en attente d'un ordre du directeur. Le moteur ne part pas dans une langue où ses messages n'existent pas.

---

## Groupe B. À traiter avant d'ouvrir à de nouvelles familles

### B1. La protection de l'enfance, au-delà des données

- **Le sujet.** Une école qui met des adultes en visio avec des enfants doit avoir une politique de protection écrite, au-delà de la protection des données.
- **Pourquoi il pèse.** Il faut une règle sur tout contact hors du cours, un moyen simple pour un enfant ou un parent de signaler un comportement, une personne qui reçoit ces signalements, la vérification des enseignants à l'embauche, et la règle de la caméra (enfants, classes de femmes). Sans cela, une famille qui voit un problème n'a nulle part où aller.
- **Ce qui existe déjà.** La charte, partie 12, pose des règles de données et de messages : aucun message privé entre un enseignant et un enfant hors d'un cadre visible du tuteur, aucun chat ouvert pour un mineur, aucun courriel ni push à un enfant. Elle ne contient ni circuit de signalement, ni vérification à l'embauche, ni règle de caméra.
- **Position de l'architecte.** Écrire la politique de protection en une page, la faire lire à chaque enseignant, garder le droit d'observation du tuteur. Aucune conversation privée enseignant-enfant.
- **Suite.** Document « PROTECTION-DE-L-ENFANCE », puis lot.

### B2. Le cadre légal

- **Le sujet.** Consentement du parent pour les données d'un mineur, conditions d'utilisation, suppression et export des données, durée de conservation, mention pour les enregistrements de la voix du directeur.
- **Pourquoi il pèse.** L'école garde des résultats, des attestations et des observations sur des enfants. Sans durée écrite ni consentement, elle ne peut pas ouvrir au public.
- **Ce qui existe déjà.** Le registre de réconciliation du 14/10 dit que la suppression de compte, l'export des données et l'acceptation des conditions sont obligatoires avant d'ouvrir au public, et que rien de tout cela n'existait. Le consentement d'observation y est noté « absent ». Non revérifié depuis. La mémoire pédagogie et finance note aussi que l'activation d'enregistrement audio et la conservation étaient contradictoires dans d'anciens documents.
- **Position de l'architecte.** La charte s'y soumet. Aucune donnée d'évaluation n'est gardée sans durée écrite.
- **Suite.** Lot légal, avant toute ouverture à de nouvelles familles.

### B3. La formation des enseignants à la charte

- **Le sujet.** La charte demande à l'enseignant une façon de corriger, une échelle à trois états et des gestes précis, qu'un enseignant recruté ne connaît pas.
- **Pourquoi il pèse.** Si deux enseignants jugent différemment la même récitation, les résultats ne veulent plus rien dire et les familles le voient.
- **Ce qui existe déjà.** La charte et la grille commune d'`EVALUATIONS.md` existent. Aucun parcours d'accueil de l'enseignant n'est prévu dans les treize lots.
- **Position de l'architecte.** Un parcours d'accueil dans l'application : la charte en version courte, la grille d'évaluation, des exemples. Puis un essai observé, puis un accompagnement individuel. Deux enseignants doivent juger pareil la même récitation.
- **Suite.** Lot « ACCUEIL-ENSEIGNANT ».

### B4. Composer les classes

- **Le sujet.** Les scénarios supposent qu'il existe une « classe de son niveau réel » ou une « classe plus avancée », ce qui est faux avec deux classes.
- **Pourquoi il pèse.** Il faut aussi respecter l'âge, le genre, la langue du cours, et maintenant le lieu et les heures de prière. Placer un élève au mauvais endroit casse la promesse de rythme.
- **Ce qui existe déjà.** Une décision sur les classes simultanées existe (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) et la production compte 3 classes, aucune avec un niveau. Aucun écran de placement n'a été trouvé. Non vérifié plus avant.
- **Position de l'architecte.** Le système dit à la direction, pour chaque élève à placer, les classes possibles et pourquoi les autres ne le sont pas. Quand aucune classe ne convient, liste d'attente annoncée honnêtement, jamais de promesse.
- **Suite.** Lot « PLACEMENT ».

### B5. La connexion et l'électricité des enseignants

- **Le sujet.** Un enseignant en Afrique de l'Ouest peut subir des coupures de courant et de réseau.
- **Pourquoi il pèse.** C'est la première cause probable de cours non assurés, donc de retard sur le programme, et le moteur ne doit pas le lire comme une faute de l'élève.
- **Ce qui existe déjà.** Le titulaire qui n'entre pas à temps perd l'accès à cette séance et reste titulaire (DÉCIDÉ 31/10), et le remplaçant existe dans la charte. Aucune mesure des coupures par enseignant, ni téléchargement hors ligne des documents, n'a été trouvée.
- **Position de l'architecte.** Mesurer les coupures par enseignant sans le sanctionner, prévoir le remplaçant, et permettre de télécharger à l'avance les documents du cours.
- **Suite.** Indicateur dans le lot du moteur (lots 7 et 9). Téléchargement hors ligne dans le lot du lecteur (lot 4).

### B6. Les élèves aux besoins particuliers

- **Le sujet.** Difficulté d'élocution, dyslexie, malentendance, adulte âgé, adulte qui ne lit pas l'alphabet latin : des dates limites fermes peuvent les blesser.
- **Pourquoi il pèse.** Un retard normal pour eux déclencherait des rappels, un plan de soutien et un message à la famille qui n'ont pas de sens.
- **Ce qui existe déjà.** `REGLAGES.md` prévoit déjà la suspension d'une règle pour un élève : une exception motivée, avec motif, date de fin et nom, 90 jours au plus, accordée par la direction. Elle suspend une règle, elle n'allonge pas les dates.
- **Position de l'architecte.** Une exception motivée, avec nom et date de fin (règle de stabilité déjà décidée), accordée par la direction, qui allonge les dates sans étiquette visible. Le réglage par élève complète la suspension de règle déjà prévue.
- **Suite.** Réglage par élève dans le lot du suivi (lot 6).

### B7. Les bilans avec les familles : où et comment

- **Le sujet.** La charte prévoit des bilans avec la famille, mais ni le lieu, ni la prise de rendez-vous, ni la trace.
- **Pourquoi il pèse.** Sans lieu ni trace, chaque bilan se fait comme il vient, par appel ou par message, et personne ne peut vérifier qu'il a eu lieu.
- **Ce qui existe déjà.** Les bilans sont cités dans la charte et le moteur. Aucune salle de bilan ni prise de rendez-vous n'est prévue dans les treize lots.
- **Position de l'architecte.** Le bilan se tient dans une salle de l'application, sur rendez-vous proposé par le système, et laisse une trace courte lue par la famille.
- **Suite.** Lot après les évaluations (après le lot 8).

---

## Groupe C. À traiter quand l'école grandit

### C1. La vie de l'école en dehors des cours

- **Le sujet.** Rencontres de récitation, Ramadan, fin du Coran d'un élève, communauté.
- **Pourquoi il pèse.** Sans vie commune, l'école reste une suite de cours, et les élèves n'ont aucune raison de rester ensemble.
- **Ce qui existe déjà.** Le lot 2 prévoit les rencontres de récitation dans le calendrier. Leur format n'est pas écrit.
- **Position de l'architecte.** La rencontre de récitation est le premier rendez-vous commun à organiser. Rien de compétitif.
- **Suite.** À traiter quand l'école aura 30 élèves, après le calendrier (lot 2).

### C2. Ce que l'école n'enseigne pas

- **Le sujet.** Des familles demanderont du fiqh, de l'arabe, de l'histoire.
- **Pourquoi il pèse.** Sans réponse claire, chaque demande devient une négociation, et l'école se dilue.
- **Ce qui existe déjà.** Le référentiel dit que l'école ne crée pas un institut de fiqh ou de sciences islamiques générales (`07_MEMOIRE_PEDAGOGIE_FINANCE.md`). Aucun texte n'existe pour les familles.
- **Position de l'architecte.** Le dire clairement aux familles. La bibliothèque peut orienter vers des documents, sans cours.
- **Suite.** Texte pour les familles, à écrire avec les contenus de l'inscription.

### C3. Réviser le programme

- **Le sujet.** Qui propose un changement du programme, à quel rythme, sur quelles mesures.
- **Pourquoi il pèse.** Sans règle, le programme change au gré des demandes, et les élèves en cours de parcours perdent leurs repères.
- **Ce qui existe déjà.** `EVALUATIONS.md` parle de publication d'une version. Aucune règle de révision n'est écrite. Non vérifié plus avant.
- **Position de l'architecte.** Une revue par an, à partir des indicateurs et des retours des enseignants et des familles. Une version publiée ne se modifie pas : on en publie une nouvelle.
- **Suite.** Règle à écrire dans la charte, à traiter quand l'école aura 30 élèves.

### C4. L'école qui tourne sans son directeur doit se surveiller elle-même

- **Le sujet.** Si le calcul de nuit du moteur s'arrête, plus aucun rappel ne part, et personne ne le voit.
- **Pourquoi il pèse.** Le directeur veut une école qui tourne sans lui. Une panne silencieuse du moteur ressemble à une école calme, jusqu'au jour où une famille se plaint.
- **Ce qui existe déjà.** Le lot 9 prévoit un journal et un tableau de bord à cinq chiffres. Aucun témoin « le moteur a tourné » n'est prévu.
- **Position de l'architecte.** Un témoin quotidien « le moteur a tourné », une alerte au directeur s'il ne tourne pas, et une page d'état lisible.
- **Suite.** Dans le lot du moteur (lot 7).

### C5. Les illustrations de la prière et des ablutions

- **Le sujet.** Les illustrations sont décidées par IA puis validées par le directeur, et la représentation de personnes est sensible pour certaines familles.
- **Pourquoi il pèse.** Une image mal reçue peut faire fuir une famille, et elle est difficile à retirer une fois diffusée.
- **Ce qui existe déjà.** Les illustrations validées par le directeur font partie du contenu n° 3 de `CONTENUS-ATTENDUS.md` (DÉCIDÉ 14/10).
- **Position de l'architecte.** Le directeur valide chaque image. Prévoir des silhouettes sobres.
- **Suite.** Contenu attendu du directeur.

### C6. Après les bases

- **Le sujet.** Le programme d'après les bases reste une proposition, et les premiers élèves y arriveront dans 4 à 12 mois.
- **Pourquoi il pèse.** Sans programme validé, les premiers élèves qui finissent les bases n'ont nulle part où aller.
- **Ce qui existe déjà.** `EVALUATIONS.md` contient l'après-bases, marqué PROPOSÉ, réservé à la validation du directeur et de ses associés détenteurs d'ijaza.
- **Position de l'architecte.** Il doit être validé par le directeur et ses associés avant que le premier élève finisse les bases. Le moteur prévient la direction 8 semaines avant.
- **Suite.** Règle dans le moteur (lot 9).

---

## Tableau récapitulatif

| Sujet | Groupe | Suite |
|---|---|---|
| A1. Qui est « la direction » ? | A | Lot « RÔLES-ET-CHARGE », avant le lot 7 |
| A2. Les messages arrivent-ils vraiment ? | A | Lot « RÉCEPTION-PROUVÉE », avant le lot 7 |
| A3. Hafs ou Warsh | A | Champ dans le lot 3 ; contenu attendu du directeur |
| A4. École suivie pour la prière et les ablutions | A | Fermé le 13/11/2026 (référence : Arabie saoudite) ; relecture du directeur |
| A5. L'argent et le programme | A | Avec le lot d'harmonisation de l'argent |
| A6. La langue des familles | A | Lot « LANGUES », en attente d'un ordre du directeur |
| B1. Protection de l'enfance | B | Document « PROTECTION-DE-L-ENFANCE », puis lot |
| B2. Cadre légal | B | Lot légal, avant toute ouverture |
| B3. Formation des enseignants | B | Lot « ACCUEIL-ENSEIGNANT » |
| B4. Composer les classes | B | Lot « PLACEMENT » |
| B5. Connexion et électricité | B | Lots 7 et 9 (indicateur), lot 4 (hors ligne) |
| B6. Besoins particuliers | B | Lot 6 (réglage par élève) |
| B7. Bilans avec les familles | B | Lot après le lot 8 |
| C1. Vie de l'école hors cours | C | Après le calendrier, à 30 élèves |
| C2. Ce que l'école n'enseigne pas | C | Texte pour les familles |
| C3. Réviser le programme | C | Règle à écrire dans la charte, à 30 élèves |
| C4. L'école se surveille elle-même | C | Lot 7 |
| C5. Illustrations | C | Contenu attendu du directeur |
| C6. Après les bases | C | Règle dans le lot 9 |

Ce registre se complète à chaque fois qu'un sujet nouveau apparaît.
