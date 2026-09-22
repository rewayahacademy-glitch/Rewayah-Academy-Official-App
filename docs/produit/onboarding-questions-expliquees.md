# Les questions du parcours, expliquées

**À quoi sert ce document.** Chaque question posée à une famille est expliquée
ici : ce qu'elle demande vraiment, pourquoi elle est posée ainsi, ce qu'elle
change, et ce qu'elle **ne** change pas. Toute question qui peut prêter à
confusion a sa propre section.

Écrit le 22 septembre 2026, en même temps que le lot. Le parcours vit dans
`lib/features/parcours_offres/`, ses libellés dans `assets/i18n/fr.i18n.json`
sous la clé `parcours`.

---

## 0. La phrase d'accueil, et la promesse qu'elle tient

> « Quelques questions pour personnaliser votre parcours. Vous ne verrez ensuite
> que les horaires et options adaptés à votre situation. »

Cette phrase est un contrat. Elle promet deux choses, et le produit tient les
deux :

1. **« Quelques questions »** — il y en a six, une par écran, toutes en cartes
   tactiles. Aucune ne demande de taper au clavier.
2. **« Vous ne verrez ensuite que… »** — le filtrage est fait par le serveur
   (`offres_compatibles`), pas par l'écran. Une famille ne reçoit jamais le
   catalogue entier. Deux raisons : un filtre côté client se contourne, et un
   catalogue entier dirait à une famille quels autres créneaux existent pour
   d'autres publics.

**Ce que la phrase ne promet pas** : un cours à l'heure de votre choix. Le
parcours ne vend pas de sur-mesure. Voir la section 7.

---

## 1. « Qui va suivre les cours ? » — la question qui n'est pas posée

Elle **n'apparaît nulle part**, et c'est délibéré. On entre dans le parcours
depuis la carte d'un apprenant précis, à l'accueil famille. L'identifiant voyage
dans l'URL (`/tuteur/parcours/<eleveId>`).

La reposer serait redemander une information déjà connue, ce que la règle du
parcours interdit. Un adulte qui apprend pour lui-même est son propre tuteur
(ADR-009) : il voit sa propre carte, il n'a pas à se désigner.

**Corollaire** : un foyer qui a déjà répondu aux six questions et qui revient
changer d'horaire **n'y répond pas une seconde fois**. Le parcours s'ouvre
directement sur la liste des horaires ; le bouton « Retour » redescend vers les
questions, déjà remplies, pour qui veut corriger une réponse.

---

## 2. « Quel âge a {prénom} ? »

**Ce qui est demandé** : une tranche d'âge, choisie dans une liste fermée
(`cohortes_age`).

**Ce qui n'est pas demandé** : une date de naissance. Deux raisons.

- Sur un téléphone tenu d'une main, une réponse au doigt bat un sélecteur de
  date.
- Le produit ne stocke de date de naissance **nulle part**. En collecter une
  ici créerait une donnée sensible nouvelle pour un usage qui n'existe pas.

**Ce que la réponse change** :

| Ce qui est déduit | Par qui | Valeur actuelle |
| :--- | :--- | :--- |
| Le public (enfant / adulte) | le serveur, depuis `cohortes_age.type_public` | — |
| La capacité du groupe | `app_config` `groupe.capacite_*` | 5 enfants, 6 adultes |
| La durée d'une séance | `app_config` `seance.duree_minutes_*` | 60 min enfant, 90 min adulte |
| La pause centrale | `app_config` `seance.pause_minutes_*` | 6 min enfant, aucune adulte |
| `student_type` et `interface_mode` | le serveur | — |

**Ce que la réponse ne change pas** : `camera_policy`. ADR-012 confie ce réglage
au parent, dans un écran qui l'explique. La déduire d'une tranche d'âge
ouvrirait une caméra sans que personne l'ait demandé.

⚠️ **Le client ne calcule aucune de ces déductions.** Un client qui déciderait
qui est mineur pourrait se déclarer adulte autonome.

---

## 3. « Dans quelle langue le cours doit-il être donné ? »

**C'est la question la plus susceptible d'être mal comprise du parcours**, parce
que l'application pose déjà une question de langue ailleurs.

| | Langue de l'**interface** | Langue du **cours** |
| :--- | :--- | :--- |
| Où | Compte → Réglages | Ici |
| Ce que c'est | la langue des boutons et des textes de l'app | la langue que l'enseignant parlera en séance |
| Valeurs | français, arabe (ADR-015) | poular, français, english (`langues_cours`) |
| Modifiable | à tout moment, sans conséquence | c'est un critère **dur** de compatibilité de groupe |

**Les deux axes sont indépendants.** Une famille peut lire l'application en
français et suivre son cours en poular. C'est le sens d'ADR-029 : ADR-015 a
retiré le poular des **locales** de l'application, et cette décision tient ; le
poular revient ici comme langue d'**enseignement**, sur un axe séparé.

**Conséquence à assumer** : la langue du cours ne se change pas d'un tap une
fois le groupe formé. Un groupe est constitué d'élèves qui partagent exactement
la même langue d'enseignement ; en changer, c'est changer de groupe.

**Détail d'affichage** : le nom d'une langue est rendu par le serveur
(`langues_cours.nom_humain`) et n'est jamais traduit. « Pulaar » s'écrit
« Pulaar » quelle que soit la langue de l'interface — le nom d'une langue
s'écrit dans cette langue.

---

## 4. « Où vous trouvez-vous ? »

**Ce qui est demandé** : un lieu, dans une liste fermée de huit régions.

**Ce qui n'est jamais demandé** : une position GPS, une adresse, une ville
précise. Le parcours ne demande aucune permission de localisation.

**À quoi cela sert, et à rien d'autre** : afficher les horaires à votre heure
locale. Une offre publiée à 18:00 heure de Paris se lit 17:00 à Conakry. Sans
cette réponse, l'écran devrait choisir un fuseau au hasard, et se tromperait
pour tout le monde sauf une région.

**Comment la suggestion est calculée** : l'application regarde le décalage
horaire de votre appareil et **pré-coche** la région la plus proche. Vous
confirmez, ou vous changez. Si le foyer a déjà enregistré un lieu, c'est celui-là
qui est pré-coché — le contredire n'aurait pas de sens.

⚠️ **Limite connue, assumée** : la suggestion utilise le décalage d'hiver de
chaque région, sans base de fuseaux embarquée. Entre mars et octobre, elle peut
tomber sur la région voisine. Conséquence : un tap de plus, la liste étant
affichée en entier. Documenté dans `libelles_parcours.dart` avec sa voie de
montée (`flutter_timezone`, le jour où une autre fonction en aura besoin).

**Ce que la réponse change** : le fuseau du foyer (`households.timezone`), donc
l'heure à laquelle tous les horaires vous sont présentés, partout dans
l'application.

**Si vous déménagez** : l'horaire ne bouge pas pour l'académie, mais il ne tombe
plus à la même heure chez vous. L'accueil vous le dit explicitement — le taire
vous ferait manquer votre cours.

---

## 5. « Où en est {prénom} aujourd'hui ? » — le niveau auto-déclaré

**C'est la deuxième question la plus susceptible d'être mal comprise**, parce
qu'elle ressemble à une évaluation et n'en est pas une.

**Ce qu'elle est** : une auto-déclaration, en langage humain. Elle oriente les
premières propositions.

**Ce qu'elle n'est pas** : le niveau officiel de l'académie.

| | Niveau auto-déclaré | Niveau officiel (grade) |
| :--- | :--- | :--- |
| Colonne | `student_profiles.niveau_declare` | `student_profiles.level` |
| Qui l'écrit | la famille, ici | l'académie, après diagnostic |
| Le client peut-il l'écrire ? | **oui** | **non** — pas de `UPDATE` accordé |
| Visible comme un grade ? | jamais | oui, quand l'académie l'aura tranché |

`student_profiles.level` est **le niveau académique d'un élève**, et seulement
cela : il ne porte jamais le grade professionnel d'un enseignant. La forme sous
laquelle ce niveau s'affichera n'est pas arrêtée — `badges-et-grades.md` en
discute, mais c'est une **proposition non validée**, pas une spécification.

**Les deux colonnes sont distinctes en base**, ce qui rend la confusion
impossible plutôt que déconseillée. Aucune écriture du parcours ne peut toucher
`level`.

**Aucune réponse visible ne s'appelle `F1`, `F2` ni `F3`.** Ce sont des codes de
référentiel (`programme_niveaux.code_technique`), réservés à l'administration.
Les cinq réponses proposées sont des phrases :

- Nous commençons par les lettres
- Les lettres sont reconnues, la lecture demande de l'aide
- La lecture est possible, lentement
- Le Coran se lit déjà couramment
- Une partie est déjà mémorisée

**Se tromper n'a aucune conséquence.** Le diagnostic qui suit corrige, et c'est
lui qui fait foi.

---

## 6. « Que souhaitez-vous d'abord ? » — l'objectif

Quatre réponses : apprendre à lire, lire plus couramment, mémoriser, **je ne
sais pas encore**.

**« Je ne sais pas encore » est une réponse de la liste, pas un refus de
répondre.** Un parent qui découvre l'académie n'a pas à inventer un objectif
pour avancer. Elle s'enregistre comme les trois autres, et le parcours continue
normalement.

L'objectif oriente le travail de l'enseignant. Il n'engage pas la famille et se
change plus tard.

---

## 7. « Quels moments de la journée vous conviennent le mieux ? »

**C'est la question qu'il faut lire deux fois, parce qu'elle ne fait pas ce
qu'on croit.**

**Ce qu'elle fait** : elle **classe** les horaires que l'académie propose déjà.
Ceux qui tombent dans un moment coché remontent en tête.

**Ce qu'elle ne fait pas — les trois, et c'est délibéré** :

1. **Elle ne filtre pas.** Un horaire hors de vos moments descend, il ne
   disparaît pas. L'académie publie peu d'horaires ; en cacher un parce qu'il
   tombe à 14 h alors que vous avez coché « le soir » vous ferait rater un cours
   qui aurait pu convenir.
2. **Elle ne crée aucun horaire.** Cocher « le soir » ne fait pas ouvrir un
   créneau du soir.
3. **Elle n'est pas enregistrée.** Cette réponse ne quitte pas l'écran. Elle
   n'est envoyée à aucun serveur et ne crée aucune attente.

**Pourquoi cette lecture, et pas une autre.** L'étape « disponibilité générale »
de la spécification pouvait se lire de trois façons, et deux sont mauvaises :

| Lecture | Pourquoi elle est rejetée |
| :--- | :--- |
| Ne pas poser la question | Alors la « recommandation principale » de l'écran suivant n'en est pas une : ce serait la première ligne d'une liste, au hasard |
| L'utiliser pour **filtrer** | Cache des horaires ouverts ; l'académie en publie trop peu pour se le permettre |
| L'utiliser pour **promettre** un créneau | Viole l'interdiction du sur-mesure |
| **L'utiliser pour classer** ✅ | Ne fait aucun des trois |

**Répondre est facultatif.** Sans réponse, les horaires s'affichent dans l'ordre
publié par l'académie.

---

## 8. Le choix de l'horaire — ce que « choisir » veut dire ici

C'est l'écran le plus important du parcours, et le plus facile à mal formuler.

### Ce que la carte d'un horaire affiche

Les jours, l'heure **à votre heure locale**, la langue du cours, le rythme et la
durée.

### Ce qu'elle n'affiche pas, et ne pourra jamais afficher

- le nom d'un enseignant
- sa photo, son badge
- le nombre d'inscrits
- le nombre de places restantes
- un identifiant de groupe

**Ce ne sont pas des champs oubliés.** La table `offres_horaires` n'a pas ces
colonnes, la classe `OffreHoraire` ne les porte pas, et un test les interdit sur
les quatre chaînes que la carte peut rendre. À ce stade, **aucun groupe réel
n'est garanti** : les montrer serait une promesse que l'académie n'a pas faite.

### Ce qui se passe quand vous choisissez

| Ce qui arrive | Ce qui n'arrive PAS |
| :--- | :--- |
| Une **préférence** est enregistrée (`intentions_horaire`) | Aucune place n'est réservée |
| L'académie sait qu'une famille attend ce créneau | Aucun groupe n'est créé |
| Un diagnostic est marqué « à planifier » | Aucun enseignant n'est appelé |

L'écran le dit avec ces mots-là. **Il ne dira jamais « Votre classe est
réservée » tant qu'un groupe réel n'existe pas.**

### Les quatre états que vous verrez ensuite, à l'accueil

| État | Ce qu'il veut dire | Ce qui débloque la suite |
| :--- | :--- | :--- |
| **Préférence enregistrée** | Votre créneau est connu de l'académie | un échange avec un enseignant |
| **Rendez-vous prévu** | Le diagnostic est au calendrier | la tenue du rendez-vous |
| **Groupe en cours de constitution** | Vous n'êtes pas seul, mais le minimum n'est pas atteint | d'autres familles sur le même créneau |
| **Groupe confirmé** | Le groupe existe, votre place est réelle | rien, les séances commencent |

Le minimum de lancement vient d'`app_config`
(`groupe.minimum_lancement`, aujourd'hui **3**). Il est **configuré, versionné,
et n'est écrit dans aucun widget** : il change par décision d'exploitation, pas
par livraison.

Un cinquième état existe et prime sur tous : **« Cet horaire n'est plus
proposé »**. Il s'affiche si l'académie retire une offre avant qu'un groupe soit
constitué. Continuer à afficher « groupe en formation » sur une offre retirée
serait le mensonge le plus coûteux du parcours.

---

## 9. « Aucun de ces horaires ne me convient » — le repli

**Le parcours ne propose jamais de champ libre pour décrire l'horaire que vous
voudriez.** C'est l'interdiction du sur-mesure, et c'est une exception assumée à
ADR-013, qui impose partout ailleurs une carte « Autre » en saisie libre.

**Pourquoi cette exception** (documentée en ADR-030) : une saisie libre ici
inviterait à écrire un horaire souhaité. Écrire un souhait crée une attente, et
l'académie ne peut pas la tenir — elle ne vend pas de cours sur mesure. La règle
d'ADR-013 est bonne, mais elle suppose qu'une réponse libre est exploitable ;
ici, elle ne l'est pas.

Le mécanisme existait déjà dans le code : `ChoiceCardGroup.autoriserSaisieLibre`,
avec le commentaire « New scheduling choices use closed administrative proposals
and pass false ». Le parcours s'en sert.

**Ce que le bouton « Me prévenir si de nouveaux horaires ouvrent » fait** : une
ligne dans `matching_requests`, la table que l'académie dépouille déjà en
`ADM-06`. Un **signal de demande non satisfaite**, et rien de plus.

**Ce qu'il ne fait pas** :

- il ne crée pas de groupe
- il ne cherche pas d'enseignant
- il ne promet aucun horaire futur
- il n'enregistre **aucun horaire souhaité** — le détail envoyé au serveur porte
  le fuseau, la langue et la cohorte, jamais un créneau

Cette phrase est affichée **avant** le clic, pas après.

---

## 10. Où chaque réponse est écrite

| Question | Colonne ou table | Écrite par |
| :--- | :--- | :--- |
| Âge | `student_profiles.cohorte` | `enregistrer_profil_apprentissage` |
| Langue du cours | `student_profiles.langue_cours` | idem |
| Lieu | `households.timezone` | idem |
| Niveau déclaré | `student_profiles.niveau_declare` | idem |
| Objectif | `student_profiles.objectif` | idem |
| Moments de la journée | **nulle part** | — |
| Horaire retenu | `intentions_horaire` | `choisir_offre_horaire` |
| « Aucun ne convient » | `matching_requests` | `signaler_horaire_insatisfait` |

**Les six réponses partent ensemble, en un seul appel.** Une fiche à moitié
écrite serait considérée « personnalisée » par le produit, et l'accueil ferait
sauter la famille à l'étape suivante alors qu'elle n'a rien fini. Un test le
vérifie.

**Le client n'a le droit d'écrire que cinq colonnes** de `student_profiles`
(`langue_cours`, `cohorte`, `niveau_declare`, `objectif`, `onboarding_fait_le`).
`level`, `diagnostic_statut`, `student_type` et `riwaya` lui sont fermés au
niveau du `GRANT`, pas seulement de l'écran.

---

## 11. Références

- `lib/features/parcours_offres/` — le parcours
- `lib/core/offres/offre_horaire.dart` — le modèle, et `etapeParcours`
- `supabase/migrations/0043_offres_horaires_et_intentions.sql` — le socle serveur
- `docs/produit/badges-et-grades.md` — ⛔ **proposition non validée**, à ne pas
  implémenter ; consultable seulement pour la séparation auto-déclaration / grade
- ADR-029 (langue de cours ≠ locale), ADR-030 (exception à ADR-013),
  ADR-031 (l'offre vitrine)
