# Décision du directeur : admission de tous les entrants (27/10/2026)

Source : messages du directeur du 27/10/2026 (après-midi), en réponse à l'architecture
proposée par le pilote. Demande la plus récente : elle prévaut sur la décision D4 du
24/10/2026 (« le tuteur naît actif », migration `20261024160000_tuteur_nait_actif.sql`),
qu'elle annule, et sur la phrase « rien à repenser » du plan Boucle 1 pour ce qui touche
l'entrée dans l'application. Le reste du plan Boucle 1 continue.

## 1. Ce que le directeur a décidé

- Personne n'entre dans l'application sans décision de la direction : ni famille, ni élève
  adulte, ni enseignant, ni membre du personnel. Des robots et des concurrents sont déjà
  entrés pour regarder l'intérieur.
- La direction travaille dans des **listes séparées par population**, jamais une seule
  liste mélangée. Les gestes sont simples : accepter, refuser avec garde-fou, contacter,
  demander des précisions. Chaque geste envoie un e-mail à la personne.
- Les enseignants s'inscrivent depuis le site public, sans invitation, et n'entrent qu'après
  confirmation de la direction, pièce d'identité comprise. Les liens Google Forms seront
  fermés quelques jours après la preuve en production.
- L'ensemble doit tenir la montée en charge des prochaines semaines et des prochaines
  années sans ajouter de travail à la direction.

## 2. Les six règles

1. **Un compte n'est pas une admission.** S'inscrire crée un compte confiné à une seule
   page : « Votre demande est en cours ». Rien d'autre n'est visible avant la décision.
   Le code le fait déjà pour les enseignants (état `pending_kyc`, porte
   `PorteAcces.attente`, routes `/attente`). La même porte vaut pour tous les rôles.
2. **Un seul dossier d'admission par personne et par population.** La table
   `candidatures` en production porte déjà la référence, l'étape, l'état, l'issue, la
   pause, la source, le responsable et le journal. On n'ajoute pas de seconde table : on
   ajoute des lignes dans `candidature_types` (`famille`, `eleve_adulte`, `personnel`, à
   côté d'`enseignant`). Le parcours diffère par population : une salle pour une famille,
   les trois salles déjà spécifiées pour un enseignant (`docs/current/CANDIDATURES/`).
3. **Une file par population, quatre gestes, chaque geste côté serveur.** Un geste est une
   règle serveur avec motif, auteur et journal, jamais un simple clic côté application.
   Refuser demande une confirmation avec le motif écrit et reste annulable pendant sept
   jours. Les règles existent en production pour les enseignants (`decider_dossier`,
   `refuser_candidat`, `demander_complement_candidat`, `mettre_en_pause_candidat`,
   `lister_candidatures`) : on les ouvre aux autres populations, on n'en réécrit pas.
4. **Un e-mail à chaque changement d'état**, par la file de courriels en place (demande
   reçue, précisions demandées, acceptée, refusée). La personne n'a jamais à revenir voir.
5. **Les robots restent dehors avant même le dossier** : adresse e-mail confirmée
   obligatoire (réglage Supabase `enable_confirmations`, aujourd'hui éteint), plafond
   d'inscriptions par heure avec réponse neutre (clé `candidatures.inscriptions_par_heure`
   déjà en production), aucune information sur l'académie avant admission. Un captcha
   seulement si cela ne suffit pas, sur décision datée.
6. **Après admission, chacun atterrit dans son espace** selon son rôle : la redirection le
   fait déjà.

## 3. Les listes de la direction, séparées

| Liste | Qui | Tri par défaut | Particularités |
|---|---|---|---|
| Familles | tuteur qui inscrit un ou plusieurs élèves | la plus ancienne d'abord | acceptation en un geste, acceptation groupée possible ; aucune pièce d'identité |
| Élèves adultes | 18 ans et plus, pour eux-mêmes | la plus ancienne d'abord | mêmes gestes que les familles |
| Enseignants | candidats | par salle, puis la plus ancienne | les trois salles de la spécification ; pièce d'identité dans la deuxième |
| Personnel | comptable, contrôleur, futur membre de la direction | la plus ancienne d'abord | toujours sur invitation ; jamais depuis le site public |

- Une même table et un même journal dessous, des vues séparées dessus. Chaque liste a son
  compteur « à traiter », ses filtres, sa recherche par nom, e-mail et référence.
- Chaque liste peut être confiée à un membre du personnel, par population : la capacité
  `candidatures.decider` se donne par type de population. La direction délègue sans
  perdre le journal.
- Le même nom affiché partout : « Demandes », jamais « candidatures » ni « inscrits » à
  l'écran pour les familles (compétence `mots-rewayah`).

## 4. Les gestes et leurs e-mails

| Geste | Garde-fou | E-mail envoyé |
|---|---|---|
| Accepter | aucun ; annulable pendant sept jours | « Votre demande est acceptée », avec le bouton d'entrée |
| Refuser | confirmation avec motif écrit ; annulable pendant sept jours ; la personne ne voit pas le motif interne | « Nous ne pouvons pas donner suite », avec le motif court choisi pour elle |
| Contacter | aucun | message libre de la direction, depuis l'adresse de la direction |
| Demander des précisions | aucun ; la demande passe en « à compléter » | « Il nous manque une information », avec le lien vers sa page d'attente |

Un geste sur une demande déjà tranchée par quelqu'un d'autre est refusé par le serveur
(« déjà traitée par … ») : deux personnes de la direction peuvent travailler en même temps.

## 5. Tenir des semaines, puis des années

- Aucune ligne n'est effacée : refusée, retirée ou acceptée, la demande reste dans le
  journal. Une personne refusée peut redemander après trente jours ; la nouvelle demande
  montre l'ancienne à la direction.
- Listes paginées par curseur, index par (population, étape, issue, date de réception),
  comme la décision du 10/10 sur la montée en charge l'impose déjà pour les classes.
- Les e-mails partent par la file, jamais dans la transaction du geste : mille demandes
  ne ralentissent pas la direction.
- Règles automatiques, chacune activable par une clé `app_config`, aucune activée au
  départ : acceptation automatique d'une famille après son premier paiement ; rappel à
  sept jours puis clôture à trente jours d'une demande « à compléter » sans réponse ;
  regroupement par e-mail des demandes en double.
- Une nouvelle population future (par exemple un partenaire) se traduit par une ligne de
  `candidature_types` et une vue, jamais par une table ni un parcours de plus.
- L'import des inscrits actuels et des réponses Google Forms continue par le lot L3 déjà
  en production (`inscrire_import`, rapprochement), dans les mêmes listes.
- Un tableau de bord minimal par semaine : reçues, acceptées, refusées, délai moyen de
  décision, par population.

## 6. Ce qui ne change pas

- La spécification des trois salles des enseignants et ses lots L4 et L5 à écrire.
- La règle « une candidature ne crée jamais un compte actif ».
- Les capacités nommées au §8.1 de la spécification des candidatures ; on y ajoute
  seulement le type de population en paramètre.
- Les inscriptions restent fermées en production jusqu'à la preuve des lots B et C.

## 7. Les lots, un par pull request, après le lot 2 de la fiche Fraîcheur

| Lot | Contenu | Preuve attendue du directeur |
|---|---|---|
| A | Cette décision ; ligne au journal du `08` | lue et fusionnée |
| B | Serveur : une famille et un élève adulte naissent en attente avec leur demande ; types `famille`, `eleve_adulte`, `personnel` ; page d'attente avec un vrai contenu ; confirmation d'e-mail allumée | il s'inscrit comme famille test, voit la page d'attente, ne voit rien d'autre, reçoit l'e-mail « demande reçue » |
| C | Listes séparées de la direction, quatre gestes, e-mails | il accepte la famille test et elle entre ; il refuse une autre et voit la confirmation |
| D | Entrée enseignant depuis le site : écrans portés depuis les PR 45 et 50, lien sur le site public, clé `candidatures.inscription_publique_ouverte` à `true`. La salle d'examen est la première salle du dossier (`docs/current/CANDIDATURES/`), avant toute admission : elle ne donne accès à rien d'autre, comme la page d'attente (règles 1 et 2.1), et l'enseignant n'entre dans l'application qu'après la décision de la direction, pièces comprises | un enseignant test s'inscrit depuis le site sans invitation, remplit la salle d'examen, ne voit rien d'autre, et n'entre qu'après la décision de la direction |
| E | Reste des écrans des PR 45 et 50, par morceaux ; règles automatiques, une par PR, sur décision | lot par lot |

Les inscriptions rouvrent après la preuve de B et C. Les Google Forms ferment après la
preuve de D.

## 8. Prouvé par le directeur

| Lot | Date | Constat |
|---|---|---|
| A | | |
| B | | |
| C | | |
| D | | |
