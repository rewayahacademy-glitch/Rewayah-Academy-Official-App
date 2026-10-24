# Boucle 1 : la première classe qui tourne, plan du 24/10/2026

Décisions du directeur du 24/10/2026. Elles prévalent sur tout le reste de `docs/current/`
tant que les quatre phrases du KPI ne sont pas vraies.

1. **Une seule boucle, dans l'ordre** : la direction valide l'enseignant, crée une classe, y met
   un élève et son tuteur, la séance se tient en vidéo avec la page de Coran.
2. **La preuve se fait en production, par le directeur, après fusion.** Risque accepté : personne
   d'autre n'utilise l'application. Les étapes moins urgentes se prouveront autrement, au cas par cas.
3. **Vérité d'abord** : règle dans `CLAUDE.md`. Interdiction formelle de tromper le directeur pour
   ne pas le froisser.
4. **Rien d'autre** : aucun nouvel écran, aucune nouvelle règle, aucun lot hors boucle, aucune
   session parallèle, aucune remise à plat d'architecture.

## 1. Le KPI : quatre phrases, vraies ou fausses, vérifiées par le directeur

| # | Phrase à rendre vraie en production | Test |
|---|---|---|
| K1 | La direction ouvre le dossier de l'enseignant en attente, voit sa pièce, coche les trois vérifications, clique « Valider ». L'enseignant, à sa connexion suivante, arrive sur sa Journée et plus sur le portail d'attente. | 5 min |
| K2 | La direction crée une classe avec cet enseignant, un jour, une heure, un public. La classe est « active » ; l'enseignant la voit dans « Mes classes » avec sa prochaine séance. | 5 min |
| K3 | Un tuteur et son élève ont un compte ; la direction met l'élève dans la classe. Le tuteur connecté voit la classe et l'heure de la prochaine séance. | 10 min |
| K4 | À l'heure, l'enseignant clique « Rejoindre la salle », l'élève aussi. Chacun voit et entend l'autre. L'enseignant affiche une page du Coran, l'élève la voit. | 15 min |

Tant qu'une phrase est fausse, l'étape n'est pas « faite », quels que soient les tests verts.
Un test vert dit qu'une pièce marche seule avec de fausses données. Il ne dit rien du parcours.

## 2. Ce qui existe déjà : la boucle est câblée côté serveur, pas côté application

Lu le 24/10/2026 dans la base de production et dans le code de `main`.

| Étape | Écran | Fonction serveur | En production | Branchée dans l'app |
|---|---|---|---|---|
| K1 pièce visible | Dossiers, revue | fonction `piece-identite-acces` | oui | **non** : `apercu` nul |
| K1 décision | Dossiers, revue | `decider_dossier` | oui | **non** : `deciderExistant` nul, conséquence figée à « indéterminée » |
| K1 file des dossiers | Dossiers | `dossiers_en_attente`, renvoie l'état du compte | oui | oui |
| K1 activation | serveur | déclencheur : contrat, avis d'enregistrement et code de conduite à la version requise | oui | sans objet |
| K2 création | Classes, « Créer une classe » | `creer_groupe`, exige un enseignant actif | oui | oui |
| K2 séances | serveur | `materialiser_seances_groupe`, horizon de 4 semaines | oui | sans objet |
| K3 comptes | Inscription, ou « Importer les inscriptions » | `creer-profil-enfant`, `confirmer_import_inscriptions` | oui | oui |
| K3 élève dans la classe | Classes, détail, « Ajouter un élève » | `ajouter_eleve_groupe` | oui | oui |
| K4 entrée en salle | Journée, Accueil élève | fonction `create-room-token`, fenêtre de 20 min avant l'heure | oui | oui, jamais essayée en production |
| K4 page de Coran | Salle | support actif, fonction `bibliotheque-lecture` | oui | oui, jamais essayée en production |

Conclusion d'architecte : **rien à repenser**. Il manque un fil à l'étape 1, puis des essais réels
aux étapes 2 à 4. Une remise à plat serait la troisième depuis septembre et laisserait le même
fil débranché.

État vérifié du compte enseignant de test du directeur, en production, le 24/10 : compte
`pending_kyc`, pièce `pending` au format jpg, contrat, avis d'enregistrement et code de conduite
signés aux versions requises. La seule chose qui empêche sa validation est le fil manquant.

## 3. Les étapes, une à la fois

Chaque étape suit la même suite : Claude code, Claude prouve en local, une pull request, le
directeur fusionne, l'application se déploie en dix minutes, le directeur fait le test et répond
« vrai » ou « faux » avec une capture.

### Étape 1 : la direction valide l'enseignant (K1)

Ce que Claude change, et rien d'autre :

- `lib/core/capacites/revue_dossiers_depuis_validation.dart` : `surchargeRevueDossiersProduction`
  reçoit `apercu`, `deciderExistant` et `relire` depuis `serviceValidationProvider` et
  `dossiersEnAttenteProvider`, comme le commentaire du fichier le prévoit depuis le 27/09. La
  conséquence se calcule depuis l'état du compte (`pending_kyc` : activation possible ; `active`
  ou `provisional_active` : documentaire seule) au lieu d'être figée à « indéterminée ».
- Les tests de ce fichier, mis à jour pour le nouveau branchement.

Ce que Claude prouve avant de pousser : `dart analyze --fatal-infos`, `flutter test` sur
`test/core/capacites` et `test/features/admin_dossiers`, `dart run tool/verifier_jetons.dart`,
`dart run tool/verifier_revue.dart`.

Ce que le directeur fait, après la fusion et dix minutes de déploiement :

1. Ouvrir https://app.rewayahacademy.com et se connecter en direction.
2. Menu Dossiers, ouvrir l'enseignant en attente.
3. La photo de la pièce s'affiche. Sinon : faux, capture.
4. Cocher les trois vérifications, cliquer « Valider », lire le message.
5. Se déconnecter, se connecter avec le compte enseignant.
6. Il arrive sur sa Journée : vrai. Il retombe sur le portail d'attente : faux, capture.

Ce que Claude vérifie en même temps, en lecture seule dans la base : la pièce passe `approved`,
le compte passe `active`.

Si faux : le directeur envoie la capture et la phrase affichée. Claude lit les journaux Supabase,
corrige dans une nouvelle pull request de l'étape 1, rien d'autre.

### Étape 2 : la direction crée la classe (K2)

Aucun code prévu. Le directeur :

1. Menu Classes, « Créer une classe ».
2. Choisir le public, le genre de la classe, l'enseignant validé à l'étape 1, un jour et une heure
   **dans l'heure qui vient** pour que l'étape 4 soit testable le jour même, le nombre de places,
   un nom.
3. « Créer ». La classe apparaît « active » avec l'enseignant : vrai.
4. Se connecter en enseignant : « Mes classes » montre la classe et la prochaine séance : vrai.

Refus possibles, dits par le serveur dans la feuille : enseignant non actif, genre incompatible,
plafond de classes atteint, chevauchement d'horaire. Si le message n'explique pas le refus, c'est
un défaut de l'étape 2 : une pull request, une seule.

### Étape 3 : un élève et son tuteur dans la classe (K3)

Comptes : le directeur s'inscrit comme tuteur avec une autre adresse e-mail et crée son élève.
Variante : « Importer les inscriptions » avec les deux CSV du classeur Google, essai à blanc puis
confirmation.

Puis, en direction : Classes, la classe, « Ajouter un élève », choisir l'élève. Le tuteur
connecté voit la classe et la prochaine séance : vrai.

### Étape 4 : la séance (K4)

Vingt minutes avant l'heure de la séance :

1. Enseignant : Journée, « Rejoindre la salle ».
2. Élève : Accueil, « Rejoindre ».
3. Vidéo et son dans les deux sens : vrai.
4. Enseignant : afficher une page du Coran ; l'élève la voit : vrai.

C'est l'étape la moins connue : aucune séance n'a jamais été ouverte en production. Les clés
LiveKit des fonctions de production ne sont pas lisibles par Claude ; le premier essai le dira.
Chaque panne devient une pull request de l'étape 4, dans l'ordre où elle apparaît.

## 4. Règles de travail pendant la boucle

**Lecture.** Un agent lit ce fichier, puis seulement les fichiers nommés dans l'étape en cours.
Il ne relit ni `docs/current/`, ni les archives, ni les catalogues d'écrans. S'il lui manque un
fait, il le lit dans le code ou dans la base, en lecture seule, et le note ici.

**Un seul agent, une étape, une pull request.** Aucune session parallèle. La session
« Recrutement » et sa pull request 50 attendent la fin de l'étape 2 : elle touche l'entrée des
enseignants et ajouterait des inconnues aux étapes 1 et 4. Le directeur reste libre de la
fusionner avant ; toute panne de l'étape 1 devra alors d'abord être attribuée.

**Coût.** Une pull request déclenche environ 25 minutes d'actions GitHub, une fusion environ 10.
Aucun agent ne relance, n'annule ni ne redéclenche la CI. Pas de boucle « relance-toi encore ».

**Petits modèles.** Les tâches mécaniques passent à Sonnet ou Haiku par l'outil Agent : lancer
une suite de tests et rapporter les échecs mot pour mot, inventorier par grep, ajouter une clé
i18n dans les deux langues, rédiger la description d'une pull request. Jamais : un branchement,
du SQL, une règle RLS, un diagnostic, un choix.

**Vocabulaire des bilans.** « codé », « test local vert », « fusionné », « déployé », « prouvé
par le directeur ». Seul le dernier vaut « fait ».

## 5. Après la boucle : les boucles suivantes, dans l'ordre des peines du directeur

Précision du directeur du 24/10/2026 : ces besoins sont réels et actuels. L'académie existe
depuis 2024, 600 candidats enseignants sont inscrits, les familles ne peuvent pas être
encaissées, et tout passe encore par WhatsApp, Messenger, Meet, Drive et Docs, tenus par une
seule personne. **Rien n'est supprimé.** Tout se livre dans cet ordre, une boucle à la fois,
chacune avec ses phrases vraies ou fausses, prouvées par le directeur en production avant
d'ouvrir la suivante. Une surface large à 80 % ne soulage aucune peine ; une boucle à 100 % en
soulage une.

| Boucle | Peine qu'elle soulage | État réel le 24/10 | Ce qu'il faudra prouver |
|---|---|---|---|
| 1 | aucune classe ne tourne dans l'application | tout existe, un fil manque | K1 à K4 |
| 2 | « on ne peut pas faire payer les familles » | fonctions `recharge-payer` et `stripe-webhook` déployées ; le branchement de production dit encore « la recharge reste indisponible : aucun prestataire de paiement réel » (`lib/main.dart`) | une famille paie une classe, l'élève y entre, le reçu est visible par la famille et la direction |
| 3 | « on ne recrute plus d'enseignants », 600 candidats en attente | module des candidatures en pull request 50 ; paie à 47 % en base | la direction choisit un candidat dans la file, il devient enseignant actif, sa paie d'une séance se calcule |
| 4 | suivi et contrôle hors WhatsApp | observation, contrôleur, cahier, messages, avis : présents dans le code, jamais prouvés | une séance observée, un cahier déposé, un avis publié |
| 5 | comptabilité et inscrits actuels | comptable présent dans le code ; import CSV déployé | les inscrits actuels importés, un mois de paie clos |

Entre deux boucles : retirer des menus les capacités encore « indisponibles » de la boucle qui
vient, pour que la direction ne voie jamais un écran mort. Après K4, et dans la Boucle 3 :
alléger le portail d'attente des enseignants (choisir d'abord, identifier les retenus ensuite) et
permettre une classe sans enseignant depuis l'écran Classes.

## 6. Journal

| Date | Étape | État | Preuve |
|---|---|---|---|
| 2026-10-24 | Plan | écrit | ce fichier |
| 2026-10-24 | Plan §5 | précisé : ordre des boucles 2 à 5 selon les peines du directeur ; le paiement passe en Boucle 2 | ce fichier |
| 2026-10-24 | Étape 1 (K1) | codé, test local vert (276 tests ciblés, analyse et vérificateurs CI sans défaut) ; non fusionné | branche `claude/admiring-brown-r6ai72` |
