# Plan des trois salles du candidat enseignant (07/11/2026)

Statut : **plan proposé par le garde-cap, en attente de l'accord du directeur**. Rien n'est lancé
avant cet accord, sauf deux lots déjà en cours qui en font partie : CADRE-ECRAN et la correction de
la pièce proposée trop tôt.

Sources : la consigne du directeur du 07/11 (citée ci-dessous) ; la reconstitution de l'ancien
garde-cap (DECISION-CANDIDATURES-2026-10-21, SPEC_CONSOLIDEE, CATALOGUE_ECRANS_RECRUTEMENT, 08 §5 bis,
PLAN-LOTS) ; l'inventaire du code (origin/main 3fc0c1efd) ; la production lue en lecture seule
le 07/11.

## 0. Ce qui est vrai aujourd'hui

- **Personne n'est encore entré dans une salle en production.** On compte 0 candidature
  enseignant, 0 réponse de formulaire importée, 0 inscrit du 12/10 importé et 0 entretien. Le lien
  public est fermé. L'écran « en cours de vérification » vu en salle 3 vient des captures locales du
  03/11.
- **Échéance réelle** : le courriel d'attente envoyé à environ 650 adresses du 25 au 29/10 promet
  « d'ici trois semaines, vous recevrez un courriel personnel ». L'échéance tombe vers le **15-19/11**.
- **Le serveur est en grande partie prêt.** Les écrans manquent :
  - Salle 2 : 5 tables et 15 fonctions d'entretien en production. Seul le côté direction est branché
    (planifier, participants, issue). Le candidat n'a aucun écran, et personne ne peut rejoindre la
    visio ni écrire le compte rendu.
  - Passage en salle 3 : `valider_piece_candidat` en production (compte activé, langues et
    disponibilités recopiées). Aucun geste dans l'application ne l'appelle.
  - Salle 3 : quand le compte est activé, l'application ouvre déjà l'espace enseignant
    (`/enseignant/journee`). Mais rien n'y dit « vous êtes de l'équipe ». La page
    `BienvenueEnseignantPage` existe et n'est reliée à rien.
  - Remplacements : le serveur propose déjà les remplacements à tout enseignant actif, pièce
    approuvée, du bon genre, **avec ou sans classe**. La langue de la classe n'est pas vérifiée.
- **Aucun passage n'envoie de notification ni de courriel**, sauf le courriel d'activation du compte
  enseignant.

## 1. Les trois salles, telles que le directeur les veut (07/11)

> « quelqu'un qui s'est inscrit via le site ou le formulaire, ou qui va recevoir le lien via son
> e-mail (les personnes déjà inscrites), ces personnes vont arriver sur la première salle, c'est là
> qu'ils vont voir les infos qu'ils ont déjà remplies avant cela, et accepter tous les contrats,
> télécharger les photos (sauf ce qui est exclu comme les infos bancaires), donc ils font tout ici ;
> l'académie fait passer ceux qui sont en règle à la deuxième salle qui va permettre l'interview via
> une visio […] la deuxième montre tout ce qui est rendez-vous, interview, et celui qui est en règle
> l'académie sélectionne son nom pour passer à la 3ème salle ; et là il aura tout (car c'est désormais
> un membre à part entière, mais qui peut ou ne pas encore avoir une classe […]) il peut tout faire
> sauf enseigner […] se connecter comme il veut, envoyer des messages (après il y aura la communauté
> entre les enseignants et le personnel). »
>
> « la salle 3 c'est l'app actuelle de l'enseignant »
>
> « l'accueil doit lui montrer ce qui lui reste à configurer comme ses infos de banque. et les
> alertes de remplacement doivent être puissantes et en temps réel »

| Salle | Le candidat y voit et y fait | La direction y fait | Il reçoit (application + courriel, et notification sur l'appareil dès PUSH-1) |
| :--- | :--- | :--- | :--- |
| **1. « Votre candidature »** | Ce qu'il a déjà rempli (pré-rempli), le questionnaire, **tous** les accords (cadre religieux, contrat, avis d'enregistrement), la pièce d'identité, la photo. Pas la banque. Un seul bouton « Envoyer ma candidature ». | Liste et fiche ; « Admettre en salle 2 » | À l'entrée : « Bienvenue, voici ce qu'il reste ». À l'admission : « Vous êtes retenu pour un entretien ». |
| **2. « Faisons connaissance »** | Les créneaux ouverts ; il réserve ; il voit sa date ; **« Rejoindre l'entretien »** ouvre la visio existante (`/salle`, mode entretien, rien d'enregistré) | Ouvre des créneaux, invite 2 ou 3 intervieweurs, rejoint, écrit le compte rendu, puis **« Accueillir dans l'équipe »** | Créneau réservé ; rappel la veille et 15 minutes avant ; résultat. |
| **3. « Bienvenue dans l'équipe »** = **l'application de l'enseignant** | Son espace enseignant, comme l'enseignant actuel, avec zéro classe au départ. En tête : **ce qui reste à configurer** (coordonnées de versement, disponibilités, photo publique), puis les **alertes de remplacement** en temps réel avec « J'accepte », ses messages et son profil. | Affecte une classe ou un remplacement | « Bienvenue dans l'équipe » ; chaque offre de remplacement en temps réel. |

Les noms « Salle d'examen / de vérification / des prêts » restent côté direction. Le candidat lit
les trois noms ci-dessus (décision du 02/11, non appliquée à ce jour).

## 2. Ce que le garde-cap a tranché (ni argent, ni sécurité, ni données personnelles, ni droit)

1. **Les accords et la pièce passent en salle 1**, comme le directeur l'a dit le 07/11. La question
   CAND-S04, restée ouverte depuis le 21/10, est ainsi close. C'est un changement serveur :
   l'étape autorisée pour le dépôt de la pièce et pour chaque accord.
2. **Plus aucune barre d'actions collée en bas, nulle part.** Les boutons « Retirer ma
   candidature » et « Se déconnecter » reviennent dans le fil de la page, et la tête de page défile
   avec le contenu. La règle DEFILEMENT est étendue au bas de l'écran. Le changement se fait dans le
   composant `PageShell` (une seule fois), avec des captures avant/après des écrans touchés.
3. **Remplacements** : voir la règle unique, `DECISION-REMPLACEMENT-2026-11-07.md`.
4. **Accueil des déjà-inscrits : un lien personnel, plutôt que le lien public seul** (proposition du
   garde-cap). Chaque personne importée reçoit par courriel un lien personnel, une invitation à code
   (qui existe déjà). Elle arrive en salle 1 déjà reconnue, avec ses réponses pré-remplies. Il n'y a
   pas de rapprochement par numéro, et elle ne peut pas s'inscrire deux fois. Les personnes sans
   adresse reçoivent le même lien par un autre canal. Le lien public reste pour les nouveaux.

## 2 bis. Le remplacement, cœur de l'application (directeur, 07/11)

**Règle unique : `DECISION-REMPLACEMENT-2026-11-07.md`** (alerte à toute l'équipe, rang par genre puis
langue, fenêtre de 5 à 10 s). Ce paragraphe ne garde que les exigences de rapidité et de rappel.

> « il faudra être extrêmement rigoureux sur les actions qui passent lorsque quelqu'un clique sur
> "j'accepte", il doit directement aller à l'essentiel si le système le retient, car le temps est très
> limité ; pas trop de formalités ; il accepte et dans une minute max il est déjà dans la classe. et il
> faudra écrire ce rappel encore et encore dans tous les endroits où c'est nécessaire, peut-être même
> des rappels tous les quelques jours pour que les gens soient attentifs aux alertes, car c'est le
> noyau du programme et de l'app (l'académie doit toujours assurer les cours qu'elle a promis) donc ce
> système doit être le meilleur au monde. »

Exigences, chacune vérifiée à la recette :

1. **Une minute au plus, de la notification à la salle de classe.** Le parcours tient en trois
   gestes : toucher la notification, « J'accepte », « Entrer en classe ». Rien d'autre ne s'ouvre :
   pas de formulaire, pas de confirmation, pas de page intermédiaire. Si le serveur le retient, la
   page suivante est déjà la porte de la classe, avec ce qu'il faut pour commencer (élèves, page où
   la classe s'est arrêtée). Si un autre a été plus rapide, il le sait en une phrase.
2. **Le serveur tranche une seule fois, sans course.** Le premier « J'accepte » reçu gagne, et les
   autres reçoivent aussitôt « déjà pris ». Le temps entre la notification et l'entrée en classe est
   mesuré et journalisé ; c'est la mesure de réussite du lot.
3. **Le rappel partout où il compte** : la carte « Bienvenue dans l'équipe », la page Journée d'un
   enseignant sans classe, les réglages des notifications (alertes de remplacement activées sur cet
   appareil, oui ou non), et le courriel de bienvenue.
4. **Un rappel régulier**, tous les quelques jours, pour tout enseignant qui peut remplacer : « Les
   alertes de remplacement sont-elles actives sur votre téléphone ? ». Ce rappel devient urgent si
   aucun appareil n'est abonné. La fréquence est un réglage, pas une valeur dans le code.
5. **Le meilleur système au monde** se prouve par une recette chronométrée : deux enseignants, une
   offre, deux « J'accepte » à la même seconde. Un seul entre en classe, en moins d'une minute.

## 3. Ce qui revient au directeur

Rien de plus que la lecture du courriel promis pour le 15-19/11, écrit par le garde-cap. Le directeur a
corrigé le 07/11 : l'ouverture du lien public est décidée par le garde-cap. Elle se fait le jour où la
salle 1 est utilisable de bout en bout en production, c'est-à-dire le cadre installé et le lot 4
livré. Les formulaires des inscrits sont dans le Google Drive déjà utilisé pour les envois de fin
octobre ; l'ancien garde-cap sait où.

## 4. Les lots, dans l'ordre (4 agents au plus, sans arrêter les trains en cours)

| Ordre | Lot | Contenu | Zone |
| :---: | :--- | :--- | :--- |
| en cours | CADRE-ECRAN + CADRE (2 migrations) | Le cadre religieux validé, publié et accepté en salle 1 | dossier/, supabase |
| en cours | PIECE-AVANT-ENVOI (H) | Ne plus proposer la pièce trop tôt ; dire la vraie cause | dossier/ |
| 1 | **SALLE-3-ACCUEIL** | Passage en salle 3 : geste direction « Accueillir dans l'équipe » (`valider_piece_candidat`), puis courriel et notification « Bienvenue dans l'équipe ». Dans l'espace enseignant sans classe : carte « Bienvenue dans l'équipe » avec ce qui reste à configurer (versement, disponibilités, photo) ; `/attente` ne retient plus un compte confirmé. | admin_candidature, journee, attente |
| 2 | **SANS-BARRE-FIXE** | `PageShell.actions` dans le fil de la page, tête qui défile ; captures avant/après | core/widgets |
| 3 | **SALLE-2-ENTRETIEN** | Candidat : créneaux, réservation, date, « Rejoindre l'entretien » (`/salle` autorisée au candidat pour sa seule séance). Direction : ouvrir les créneaux, rejoindre, écrire le compte rendu. Notifications et courriels à chaque étape. | candidature, salle, admin_candidature |
| 4 | **SALLE-1-TOUT-ICI** | Accords et pièce autorisés en salle 1 (serveur) ; page unique « Votre candidature » qui montre le pré-rempli et ce qui reste ; noms des salles côté candidat ; courriel et notification « retenu pour un entretien ». | supabase, dossier, candidature, i18n |
| 5 | **REMPLACEMENT-TEMPS-REEL** | Après PUSH-1 en production : notification sur l'appareil à chaque offre, avec « J'accepte » ; alerte à toute l'équipe ; rang par genre puis langue, fenêtre de 5 à 10 s : règle unique dans `DECISION-REMPLACEMENT-2026-11-07.md` | supabase, journee |
| 6 | **MESSAGES-CANDIDAT** | Fil « candidature » entre le candidat et la direction ; fil « académie » pour un enseignant sans classe | supabase, messages |
| 7 | **INVITATIONS-PERSONNELLES** + courriel du 15-19/11 | Import des formulaires ; lien personnel à chaque personne importée ; envoi du courriel promis | admin_import, courriels |

Le but est que tout le parcours, salles 1 à 3, soit utilisable avant le **15/11**, pour la première
vague promise. Chaque lot suit les règles habituelles : relecture du garde-cap, migrations relues
deux fois, quota P5, captures, et la preuve du directeur en production.

## 5. Le vivier : la salle 3 garde tout le monde (directeur, 07/11)

> « on veut mettre à profit des centaines de personnes candidats déjà inscrits, près de 1500… si on
> veut que la plupart reste avec nous toujours prêts pour le cas où on a de nouveaux élèves, nouvelles
> classes on les affecte directement sans avoir besoin de reprendre toute la chaîne de recrutement. […]
> n'oublie pas que le début d'envoi des alertes est déjà codé, faut pas inventer donc. »

- **Toute personne qui réussit l'entretien reste en salle 3**, comme enseignant actif avec zéro classe,
  aussi longtemps qu'elle le veut. C'est le vivier.
- **Le vivier sert sans rien recoder :**
  - la proposition d'enseignants pour une nouvelle classe (`enseignants_pour_public`) liste déjà les
    enseignants actifs avec leurs disponibilités ;
  - les alertes de remplacement existent déjà : `remplacements_seance_notifier_enseignants`,
    `offres_remplacement`, la pré-alerte « remplaçant prêt », la page Journée. Le lot 5 les **modifie**
    (envoi à toute l'équipe, rang, fenêtre), il n'en crée pas d'autres.
- **Proposition des pilotes, pour garder le vivier vivant** (à valider par le directeur) :
  1. une fois par mois, une question « Toujours disponible ? » à laquelle on répond en un geste, avec
     la mise à jour des disponibilités. Sans réponse, la personne passe « en pause » : elle n'est pas
     retirée, mais elle ne reçoit plus d'alertes jusqu'à son retour ;
  2. les entretiens sont le goulot d'étranglement, 2 ou 3 intervieweurs pour environ 1 500 personnes.
     On les fait passer d'abord selon le besoin réel : genre, langues et fuseau horaire qui
     correspondent aux classes demandées et aux trous des remplacements. Le classement se fait dans la
     liste de la direction, et la direction garde la main sur l'ordre.
