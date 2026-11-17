# Praxis, membre de l'équipe : la stratégie complète (directeur, 17/11/2026)

Écrit par le pilote le 17/11/2026, vers 13 h UTC, sur ordre du directeur, après le premier vrai passage de la routine
(12 h 19 UTC). **Ce fichier prévaut sur les documents Praxis plus anciens pour la priorité et le comportement** ; la
sécurité reste celle de `SECURITE-PRAXIS.md` et d'`agir-rewayah`.

## 0. La phrase du directeur, et ce qu'elle change

> « C'est pas un chatbot que je veux. C'est un membre, parce que je suis seul dans la direction. Et actuellement on est
> près de 600 candidats, alors qu'il y en a près de 1000 qui vont venir, en plus les étudiants après. »

Priorité n° 1 de l'équipe tant qu'elle n'est pas tenue : **Praxis fait le travail de bureau de la direction**, pas
seulement répondre. Répondre est la première brique, pas le but.

## 1. Ce qui est vrai le 17/11 à 13 h (et ce qui ne l'est pas)

- **Prouvé par le directeur** : la routine a lu une conversation de test et y a répondu (12 h 19 UTC) ; la clé
  « routine » passe par le secret réseau de l'environnement `praxis-routine`.
- **En place** : routine planifiée toutes les heures (minute 24), mode essai (2 conversations de test), 5 messages
  par heure, données réelles fermées.
- **Faux aujourd'hui** :
  1. la réponse de Praxis ne se distingue pas d'une réponse humaine de l'académie : ni nom, ni image sur la bulle ;
  2. Praxis dit « nous » ; le directeur veut « on » (§3) ;
  3. quand il ne sait pas, Praxis n'a **aucun moyen** de demander à l'équipe et de revenir vers la personne :
     l'outil n'existe pas ;
  4. la routine n'a pas le dépôt : elle tourne sur un résumé de ses consignes (prompt de la tâche), pas sur les
     compétences complètes ;
  5. une personne attend jusqu'à une heure ;
  6. aucun travail de bureau n'est branché au-delà des messages (préparer des décisions, relancer, rapporter).

## 2. L'identité dans la messagerie (décision du directeur, 17/11)

- Praxis répond **à travers le compte de l'académie** (la conversation reste « avec l'académie », logo de l'académie
  en tête), mais **chaque bulle qu'il écrit porte son propre profil** : son image et le nom « #Ra_Praxis ».
- **La mention « Assistant de l'académie · IA » se voit en touchant son profil** (détails du profil), pas sur la bulle.
- S'il est interrogé (« êtes-vous un robot ? »), il répond oui, simplement : il ne ment jamais sur sa nature.
- **Arbitrage du pilote (juriste par délégation)** : la règle du directeur est retenue. Risque à connaître : le droit
  européen sur l'IA (règlement 2024/1689, art. 50, applicable depuis le 02/08/2026) demande que la personne sache
  qu'elle parle à une IA, sauf si c'est évident. Le nom propre sur chaque bulle, le profil qui le dit, la politique
  de confidentialité et la réponse franche à la question forment la parade ; ils sont **obligatoires tous les quatre**
  avant que Praxis écrive à une personne réelle.

## 3. La voix : un membre de l'équipe (décision du directeur, 17/11)

- **« On »** pour l'académie : « on a fait ça », « on doit vérifier », « on a vérifié, voici ce qui en ressort ».
- **« Je »** pour ce qu'il fait lui-même : « je vais voir avec l'équipe et je reviens vers vous ».
- Quand il ne sait pas : il le dit, il demande à l'équipe (outil `demander_equipe`, §5, lot PX-SUIVI) et **il revient
  vers la personne** quand la réponse arrive : « on a vérifié : … ».
- Il agit comme un membre : il prend en charge, il suit, il relance, il rend compte. Jamais une promesse de niveau
  B, C ou D ; jamais un prix ou un fait inventé (inchangé).

## 4. Les deux façons de travailler, et ce qui les relie

| Mode | Qui déclenche | Comment | Pour quoi |
| :--- | :--- | :--- | :--- |
| **Autonome** | les événements, et l'horloge en secours | la tâche planifiée `trig_01BzuKA9RuwF76Z6AwPtDExs` dans l'environnement `praxis-routine` (clé « routine ») ; une session neuve par passage, voulu : un message piégé ne s'installe pas dans sa mémoire | répondre, relancer, trier, préparer, rendre compte, sans que le directeur ouvre quoi que ce soit |
| **À la demande (chat)** | le directeur | Praxis ajouté comme connecteur dans le chat Claude du directeur (clé « conversation ») | « traite ces dossiers », « prépare la réponse à X », « où en est le recrutement » : le directeur ordonne, Praxis exécute dans les limites du serveur |

Ce qui les relie : **la base**. Les deux modes lisent et écrivent les mêmes files (questions à l'équipe, propositions
à valider, journal). Une chose commencée en chat se termine en autonome, et l'inverse.

**Le réveil (lot PX-REVEIL)** : quand une personne écrit dans une conversation ouverte à Praxis, la base le note et
réveille la routine (au plus une fois toutes les 3 minutes, jamais pour un message de l'équipe ou de Praxis,
jamais pour une conversation d'enfant ou de paie) ; le passage horaire reste en secours.

**Vérifié le 17/11 vers 13 h 10 UTC (documentation officielle, `code.claude.com/docs/en/routines`, et
`platform.claude.com/docs/en/api/claude-code/routines-fire`, API marquée expérimentale)** : une tâche planifiée
accepte un déclencheur **API** en plus de l'horaire. Le directeur l'ajoute dans claude.ai/code/routines : la tâche,
menu, **Edit**, ligne **Trigger**, **+**, **API**, puis **Generate token** (montré une fois). L'appel est un
`POST https://api.anthropic.com/v1/claude_code/routines/<trig_…>/fire` avec `Authorization: Bearer <jeton>` et
`anthropic-version`. Limites : 30 déclenchements par heure et par tâche (API et « Run now » ensemble), 100 appels API
par heure et par compte ; aucune clé d'idempotence (un réessai crée une session de plus). Conséquences pour le lot :
- le jeton est rangé **côté serveur** par le directeur (secret de la fonction Edge ou coffre de la base), jamais vu par
  un agent, jamais dans le dépôt ;
- l'anti-rafale du serveur (une fois toutes les 3 minutes au plus, soit 20 par heure) tient sous la limite de 30 ;
- l'appel ne se réessaie pas en boucle : un échec est noté, le passage horaire rattrape ;
- le jeton se coupe d'un geste (**Delete token**) en cas de doute.

**Le dépôt (PX-DEPOT), vérifié au même moment** : dans le même dialogue **Edit**, **Advanced settings**, onglet
**General**, champ **Repository** : choisir le dépôt de l'académie, puis **Save changes**. Ensuite seulement, les
consignes de la tâche reviennent à « lis ROUTINE-PRAXIS.md et les compétences » au lieu du résumé.

## 5. Les lots, dans l'ordre (une PR chacun, un agent chacun)

| Rang | Lot | Ce qu'il fait, en clair | Zone | Qui |
| :-: | :--- | :--- | :--- | :--- |
| 1 | **PX-BULLE** | Sur chaque bulle de Praxis, son image et « #Ra_Praxis », dans les conversations avec l'académie ; « Assistant de l'académie · IA » dans les détails du profil au toucher | messagerie (`com_*`, accord du Pilote Messagerie) | à confier |
| 2 | **PX-VOIX** | « on », « je reviens vers vous », agir comme un membre : compétences `voix-directeur` et `agir-rewayah`, consignes de la routine | compétences, tâche planifiée | pilote (fait le 17/11) |
| 3 | **PX-SUIVI** | Praxis demande à l'équipe ce qu'il ne sait pas (`demander_equipe`), le directeur répond dans la section Praxis, Praxis revient vers la personne (`reponses_equipe`) ; la question reste visible tant qu'elle n'est pas répondue | serveur + écran | BE-PIECE |
| 4 | **PX-REVEIL** | Réveil par événement, passage horaire en secours (§4) | serveur | après vérification |
| 5 | **PX-DEPOT** | La routine lit les compétences complètes : rattacher le dépôt à la tâche (geste du directeur dans les réglages de la tâche) ou recopier les compétences dans ses consignes à chaque changement | réglage | pilote, avec le directeur |
| 6 | **PX-BUREAU-RECRUTEMENT** | Chaque matin : trier la file des candidats, relancer les dossiers incomplets (A), préparer en lot les décisions à valider d'un geste (B : complément, créneau), répondre aux candidats ; le point du matin au directeur | serveur (`lire`, `preparer`) + routine | après PX-SUIVI |
| 7 | PX-3, PX-4, PX-5 | Objectifs et check-listes, classes à créer, chiffres et risques (table `ACCES-PRAXIS.md`) | — | ensuite |

**Ouvrir aux vraies personnes** (données réelles) ne se fait qu'après PX-BULLE, la politique de confidentialité
publiée, et une journée de journal relue par le directeur.

## 6. Ce qu'on ne fait pas

- Pas de session unique « qui reste allumée » : une session qui garderait tout en mémoire serait la cible d'un
  message piégé ; le chat du directeur et la base tiennent la continuité.
- Aucun agent ne voit la clé ; aucun agent ne répond à la place de Praxis.
- Rien de niveau D, jamais.
