# Décision du directeur, 07/11/2026 : qui obtient un remplacement

Le remplacement est le cœur de l'application : l'académie doit toujours assurer les cours qu'elle a
promis. Le directeur l'a dit le 07/11 : « il accepte et dans une minute max il est déjà dans la
classe » ; « ce système doit être le meilleur au monde ».

Ce fichier est **la seule règle** du remplacement. Il remplace les éléments dispersés le même jour
(plan des salles §2 bis, filtre de langue retiré, préférence de genre).

## Les mots du directeur (07/11)

> « tu ne dois pas exiger les langues […] le remplacement, c'est temporaire, c'est juste une heure ou
> 1h30 maximum. »
>
> « privilégier une femme pour les classes femmes et un homme pour les classes hommes. J'ai dit
> privilégier, j'ai pas dit de filtrer […] la seule alerte […] doit partir chez les hommes et chez
> les femmes […] Vu que c'est temporaire, c'est acceptable. […] le système doit attendre au moins
> 5 à 10 secondes avant d'accepter quelqu'un […] il faudra inscrire cela dans les informations de
> l'application. »
>
> « étends un peu ce paramètre de genre aux langues : les langues qui correspondent aux élèves
> passent en premier, sinon c'est le disponible qui remporte. »

Ces mots fondent une **exception datée** à la séparation femmes-hommes, valable pour le remplacement
seulement (une séance). Les classes stables et le recrutement restent séparés.

## La règle, en une phrase

**Tout le monde est alerté. Parmi ceux qui acceptent dans les premières secondes, le serveur retient
le mieux placé selon une liste de préférences ; à égalité, le premier arrivé.**

## Le détail

1. **Une seule alerte, envoyée à toute l'équipe** : tout enseignant actif, pièce approuvée, sans filtre
   de genre ni de langue. Elle arrive en notification sur l'appareil, avec « J'accepte ».
2. **Les préférences, dans l'ordre** :
   1. **le genre** de la classe (femme pour une classe de femmes ou de filles, homme pour une classe
      d'hommes ou de garçons) ;
   2. **la langue** de la classe, parmi les langues d'explication de l'enseignant.
   Chaque personne qui accepte reçoit ainsi un rang : genre et langue (1), genre seul (2), langue
   seule (3), ni l'un ni l'autre (4).
3. **La fenêtre** : elle s'ouvre au premier « J'accepte ».
   - Si ce premier est **au rang 1**, il est retenu tout de suite : personne ne peut faire mieux.
   - Sinon, le serveur attend la fin de la fenêtre (8 s par défaut, réglable de 5 à 10). Il retient
     alors le meilleur rang reçu et, dans ce rang, le premier arrivé. Si un rang 1 arrive pendant la
     fenêtre, il est retenu aussitôt, sans attendre la fin.
4. **Le serveur tranche une seule fois**, sous verrou. Aucun écran ne choisit. Les autres reçoivent
   aussitôt : « Un autre enseignant a pris ce cours. Merci. »
5. **La minute reste la règle**, fenêtre comprise, de l'alerte à l'entrée en classe. Pendant la
   fenêtre, la personne voit « Vous êtes en tête, confirmation dans quelques secondes », avec un
   compte à rebours vivant (DECISION-FLUIDITE §2).
6. **Les réglages** se changent sans toucher au code (`app_config`) :
   - `remplacement.preferences` : la liste ordonnée des critères, `["genre", "langue"]` par défaut ;
     liste vide pour « le premier arrivé, sans préférence » ;
   - `remplacement.fenetre_priorite_secondes` : 8 par défaut, de 5 à 10.
   Tout nouveau critère s'ajoute à cette liste et à une seule fonction serveur. Il n'y a jamais de
   second circuit.
7. **L'information dans l'application** : dans l'alerte, la page des remplacements et l'accueil de
   l'équipe. Une phrase : « Priorité à un enseignant du même genre que la classe, puis qui parle sa
   langue ; sinon, le premier disponible, car un remplacement est temporaire. »

## Ce que le serveur fait aujourd'hui, et ce qui change

- Aujourd'hui, `remplacements_seance_notifier_enseignants` **filtre** sur le genre de la classe : il
  faut l'élargir à toute l'équipe.
- Il ne regarde pas la langue : c'est conforme, la langue n'est qu'une préférence.
- Le choix d'un remplaçant passe aujourd'hui par le premier qui accepte. Il passe désormais par la
  fonction unique de rang et de fenêtre.

## Proposition des pilotes, à valider par le directeur

Un troisième critère, placé avant le genre : **« connaît déjà cette classe »**, c'est-à-dire un
enseignant qui l'a déjà remplacée ou qui y a déjà enseigné. Pour les élèves, la continuité compte
plus que tout. Le critère tient dans la même liste de réglages. Il n'est **pas** activé tant que le
directeur ne l'a pas dit.

## Propositions des pilotes, suite (à valider par le directeur)

- **Si personne n'accepte** : relancer l'alerte avec un son plus insistant 2 minutes après la
  première, et prévenir la direction en même temps. Si personne n'a accepté 10 minutes avant
  l'heure, prévenir la famille avec un message honnête et la date du cours de rattrapage. Une classe
  ne reste jamais sans nouvelles.
- **Le « remplaçant prêt » existe déjà** : un enseignant peut se déclarer disponible à l'avance pour
  un créneau, et le serveur le prévient en premier (pré-alerte). Il faut l'afficher en clair dans
  l'accueil de l'équipe : c'est le meilleur moyen de tenir la minute.

## Dette d'harmonisation (garde-cap, 07/11 vers 21:50 UTC)

- **La pré-alerte « remplaçant prêt »** (`se_declarer_pret_remplacement`) retient encore le premier
  qui se déclare prêt, sans rang ni fenêtre. C'est un second circuit au sens de la règle ci-dessus.
  Il est gardé pour la livraison du 07/11 et passe à la fonction unique de rang lors de
  l'harmonisation globale du 08/11.
- **Le journal de pg_cron** (`cron.job_run_details`) grossit d'environ 17 000 lignes par jour avec
  la tâche des fenêtres (toutes les 5 s) : une purge est à prévoir lors de la même harmonisation.
