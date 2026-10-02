# REVUE_CT-R : revue croisée de la vague Contrôleur (CT-R)

Rédigée le 02/10/2026 par une session indépendante, qui n'a écrit aucun code de cette vague. Revue en lecture seule : rien n'a été corrigé.

- **Code** : `C:\RA\controleur`, branche `ui/controleur-v1` @ `305a3f8`.
- **Diff de la vague** : `git diff 1108a4a..305a3f8`, de CT-1b à CT-12, 50 fichiers.
- **Références** :
  - `specs/08_controleur/00_DECISIONS_DIRECTEUR.md`, qui prime ;
  - `memoire/CONTROLEUR-2026-09-27.md` (C1 à C21), `CLASSE-ENTREE` (R1 à R21), `DESIGN-GOV` (contrats A à E), `STYLE-REFERENCE-CL4` (K-42) ;
  - consignes du 02/10 : K-53 à K-59 et D5 ;
  - `05_recette/CT/CT_RAPPORT.md` et `14_controleur/CT-BR.md`.

## Verrou

| Commande | Résultat |
|---|---|
| `dart analyze --fatal-infos lib test tool` | **No issues found!**, code 0 |
| `flutter test test/features/controleur test/features/controleur_recette` | **All tests passed!** +161, ~180 ignorés (captures sans `CAPTURE_DIR`), code 0 |

## Verdict

**PAS PRÊTE pour la fusion.**

**Bilan : 1 bloquant, 2 majeurs, 10 mineurs.**

- Le bloquant est le défaut CT-4 déjà signalé. **Il n'est pas corrigé.** Le compte rendu, sa transmission automatique et sa reprise restent rattachés à la mission **courante**, et non à la visite qui sort de la salle. Sur le flux que le directeur a déclaré obligatoire (C2), un rapport peut ainsi partir sur la mauvaise séance, ou ne pas partir du tout.
- Les deux majeurs sont courts à corriger.

## BLOQUANT

### B1. Le compte rendu n'est pas lié à la visite qui sort de la salle (C2, C1, C10 ; CT-4 non corrigé)

Ce que le code fait :

- **La sortie de salle ne transmet pas la visite.**
  - `lib/features/salle/salle_page.dart:322-328` : `_quitterControle` fait `go(widget.cheminCompteRenduControle)`, sans `seanceId` ni `extra`.
  - La page du compte rendu ne sait donc pas de quelle visite elle parle.
- **Le compte rendu lit la mission du moment.**
  - `lib/features/controleur/compte_rendu_controle_page.dart:96-108` : `initState` lit `missionControleProvider.future`, c'est-à-dire la mission que le serveur propose **maintenant**. Il ouvre `CompteRenduEnSuspens` à partir d'elle, puis lance `transmettreVisiteATerminer`.
  - Ligne 97 : si la mission est `null`, rien n'est transmis. Or c'est l'état normal une fois la séance finie (C1 : « après la fin, la mission n'est plus disponible »), ou quand le serveur propose déjà la mission suivante.
  - Si une nouvelle mission est arrivée, c'est **une visite jamais faite** qui est transmise à l'administration.
- **Le sous-titre suit la même mission.** `compte_rendu_controle_page.dart:151-157` affiche la Classe et l'heure de la mission courante.
- **Le contrat d'envoi n'identifie pas la visite.**
  - `lib/features/controleur/compte_rendu_controle.dart:116` : `envoyer(ChoixCompteRendu choix)`.
  - Ligne 120 : `envoyerObservation(ObservationControle observation)`.
  - Aucun des deux ne dit à quel rapport joindre la réponse. « Rien à signaler » ou une observation se joint donc au rapport que le serveur jugera courant.
- **La visite en attente peut être perdue.**
  - `compte_rendu_controle.dart:191-194` : `ouvrir` remplace en silence une visite « à terminer » par une autre dès que le `seanceId` diffère.
  - Le compte rendu commencé de la première visite disparaît du bloc « Compte rendu à terminer ».
- **La reprise rouvre la mission courante, pas la visite en attente.**
  - `lib/features/controleur/controle_page.dart:98-102` : « Reprendre le compte rendu » fait `go(Routes.controleurCompteRendu)`, sans identifiant.
  - `lib/features/controleur/historique_controleur_page.dart:129-131` : une ligne « À terminer » de l'Historique fait de même.
- **L'observation hérite du même défaut.**
  - `lib/features/controleur/observation_controle_page.dart:188-201` : l'envoi se fait sans identifiant de visite.
  - Lignes 239-242 : « Écrire à l'administration » prend l'`id` de la mission **courante**.
- **Pourquoi les tests ne voient rien** : la démonstration garde la même mission avant et après la salle. Le cas « Compte rendu, mission devenue indisponible » garde une mission non nulle. Aucun test ne fait changer la mission entre la sortie et le compte rendu, ni ne la passe à `null`.

**Correction attendue :**

1. **Faire porter la visite par l'adresse**, comme `?choix=` (revue CT-5), pour qu'elle survive à un rechargement de la PWA.
   - `Routes.controleurCompteRendu` accepte `?seance=<seanceId>`, et `Routes.controleurObservation` accepte `?seance=<seanceId>&choix=…`.
   - Dans `salle_page.dart:327`, passer `widget.seanceId`.
   - Dans `app_router.dart:1106-1121`, lire `etat.uri.queryParameters['seance']` et le donner à `CompteRenduControlePage(seanceId:)` et à `ObservationControlePage(seanceId:)`.
2. **Ne plus lire `missionControleProvider` dans le compte rendu ni dans l'observation.**
   - La visite, c'est-à-dire `seanceId`, Classe, début et `missionId`, vient de `CompteRenduEnSuspens`, retrouvé par `seanceId`.
   - Pour un `seanceId` inconnu, après rechargement ou en lien direct, afficher l'état générique « Cette mission n'est plus disponible. » avec « Revenir au contrôle » (C7). Jamais une autre mission.
   - Pour cela, la mission doit être copiée dans `CompteRenduEnSuspens` **au moment où l'on entre en salle** : `controle_page.dart:208-213`, `_commencer`.
3. **Changer le port.**
   - `envoyer(String seanceId, ChoixCompteRendu choix)`.
   - `envoyerObservation(String seanceId, ObservationControle observation)`.
   - Mettre à jour `EnvoiCompteRenduIndisponible`, le port de démonstration (`demo_controleur_page.dart:~190`) et `CT-BR.md` (BR-CT-10).
4. **Ne plus écraser une visite en attente.**
   - `CompteRenduATerminer` devient une liste ou une table indexée par `seanceId`, en mémoire seulement (C12).
   - `ouvrir` ajoute ; `terminer(seanceId)` retire.
   - Le bloc « Compte rendu à terminer » montre chaque visite en attente, ou la plus récente avec un lien vers l'Historique.
5. **Faire passer le `seanceId` dans les reprises.**
   - « Reprendre » (`controle_page.dart:98-102`) passe `visite.seanceId`.
   - L'Historique (`historique_controleur_page.dart:129-131`) passe le `seanceId` du rapport. Ajouter ce champ à `RapportControle` s'il manque.
6. **Prendre « Écrire à l'administration » sur la visite.** Après l'envoi (`compte_rendu_controle_page.dart:181-183` et `observation_controle_page.dart:239-242`), utiliser le `missionId` de la visite, jamais celui de `missionControleProvider`.
7. **Ajouter les tests manquants**, dans `test/features/controleur/compte_rendu_controleur_test.dart` :
   - Sortie de la séance A, puis `missionControleProvider` passe à la mission B. Attendu : `transmettreVisite('A')`, puis `envoyer('A', rienASignaler)`, et le sous-titre de A.
   - Même scénario avec une mission devenue `null`.
   - Deux visites en attente : aucune n'est perdue.

## MAJEURS

### M1. Les options du compte rendu et de l'observation n'ont ni ligne « quand / conséquence » ni phrase de contexte (K-58)

Ce que le code fait :

- `compte_rendu_controle_page.dart:230-246` : les trois cartes (« Rien à signaler », « Ajouter une observation », « Signaler un point important ») n'ont pas de `description`. Aucune phrase de contexte n'accompagne la question (lignes 216-224).
- `observation_controle_page.dart:336-341`, dans `_cartes` : les cartes Nature (3), Domaine (6) et Personne concernée (4) n'ont pas de `description`. Seule l'étape Nature d'un point important a une `explication`.
- Le composant sait déjà le faire : `OptionChoix.description` existe (`lib/core/widgets/choice_card_group.dart:43`). Le Complément de la même vague le fait correctement (`complement_rapport_page.dart:252-270`, voir la capture `ct8_complement_motif_*`). Les deux autres parcours divergent donc.

**Correction attendue :**

1. **Ajouter `description:` à chaque `OptionChoix`**, avec une clé `…Aide` par option dans `assets/i18n/fr.i18n.json`, au format du Complément : « Quand … · conséquence ». La carte reste entièrement cliquable (c'est déjà le cas de `ChoiceCardGroup`). Propositions, à faire valider (C16 : un libellé absent du document est une question au directeur) :
   - **Rien à signaler** : « Quand la séance s'est déroulée normalement · le compte rendu part en une action ; vous pourrez ajouter un complément. »
   - **Ajouter une observation** : « Quand vous voulez noter un fait · quatre questions courtes, texte facultatif. »
   - **Signaler un point important** : « Quand un fait demande l'attention de l'administration · votre texte sera demandé. »
   - **Point positif** : « Quand une pratique mérite d'être relevée · aucune suite n'est demandée. »
   - **À suivre** : « Quand un point devra être revu à une prochaine visite · l'administration le garde en vue. »
   - **Intervention de l'administration souhaitée** : « Quand l'administration doit agir · elle reçoit votre demande avec le rapport. »
   - **Domaines** : une ligne « Quand… » par domaine, sans conséquence inventée.
   - **Personne concernée** : par exemple, pour « Élève précis » : « Quand un seul élève est concerné · vous le choisissez dans la liste, prénom seulement. »
2. **Ajouter une phrase de contexte sous chaque question.**
   - Compte rendu : un `Text` doux entre la question et `ChoiceCardGroup`.
   - Observation : `explication` de `PageParcours`, sur chaque étape.
   - Exemple : « Votre réponse rejoint le rapport déjà transmis à l'administration. »
3. Inscrire les nouveaux libellés dans `14_controleur/LEXIQUE_CONTROLEUR.md`, avec le statut « proposé par un agent ».

### M2. En production, « Écrire à l'administration » depuis le détail de l'Historique ouvre la liste, pas le fil de la mission (C17, CTR-04 ; scénario 16)

Ce que le code fait :

- `historique_controleur_page.dart:164-166` : par défaut, `onEcrireAdmin` vaut `(String _) => GoRouter.of(context).go(Routes.controleurEchanges)`. Le `missionId` est **jeté**.
- `lib/core/router/app_router.dart:831` : la vraie route construit `const HistoriqueControleurPage()` sans surcharge.
- Le scénario 16 de la recette ne réussit qu'en démonstration, qui surcharge le rappel.
- Ailleurs, le compte rendu fait bien `Routes.controleurEcrireAdmin(id)`.
- Quand aucun fil n'existe encore pour cette mission, la liste ne permet pas d'écrire au sujet de cette visite.

**Correction attendue :**

- Par défaut : `(String id) => GoRouter.of(context).go(Routes.controleurEcrireAdmin(id))`.
- Test de widget **sans surcharge** : l'adresse obtenue contient `?mission=<missionId>`.

## MINEURS

| N° | Constat | Preuve | Correction attendue |
|---|---|---|---|
| m1 | Le message d'échec de « Rien à signaler » dit « Votre texte est gardé ici », alors que ce choix ne comporte aucun texte (K-59 : dire ce qui reste fiable, exactement). | `assets/i18n/fr.i18n.json:3226`, utilisé par `compte_rendu_controle_page.dart:308` | Clé dédiée `compteRendu.echecRien` : « L'envoi n'est pas confirmé : la connexion ou le serveur n'a pas répondu. Votre choix reste sélectionné ; réessayez dans un instant. Si le problème continue, écrivez à l'administration. » |
| m2 | Liste des élèves : le chargement, l'erreur et la liste vide se confondent (`.value ?? const []`). Le texte dit « réessayez dans un instant », mais aucune action ne le permet. | `observation_controle_page.dart:350-351, 379-387` ; `fr.i18n.json:3255` | Faire un `switch` sur l'`AsyncValue` : squelette pendant le chargement ; en cas d'erreur, le texte et « Réessayer » en secondaire (`ref.invalidate(rosterControleProvider)`) ; liste vide distincte. |
| m3 | Le Détail (CTR-06) et le Complément (CTR-03B) sont des états internes (`_ouvert`, `_enComplement`), pas des routes, et aucun `PopScope` n'est posé. Le retour système Android ou du navigateur quitte la branche au lieu de revenir à la liste ou au détail. | `historique_controleur_page.dart:101-167` | `PopScope(canPop: _ouvert == null, onPopInvokedWithResult: …)`, qui ferme d'abord le complément puis le détail. Mieux : des sous-routes `/controleur/historique/:rapportId` (et `/complement`). |
| m4 | Un complément n'affiche pas son auteur. C10 exige auteur, date, heure, rapport parent, contenu et motif facultatif. | `lib/features/controleur/historique_controleur.dart:41-47` (pas de champ `auteur`) ; `historique_controleur_page.dart:427-435` | Ajouter le champ `auteur` à `ComplementRapport` et l'afficher (« date, heure · auteur ») ; mettre à jour la démonstration et `CT-BR.md` (BR-CT-14). |
| m5 | Le parcours Complément s'affiche avec la barre de navigation, alors que C13 veut une tâche focalisée, sans navigation. Le compte rendu, lui, est bien hors coquille. | Captures `ct8_complement_*_390_light.png` (barre en bas) | Sortir le Complément de la coquille, comme `Routes.controleurCompteRendu` (route plein écran sous `GardeControle`). Sinon, poser la question au directeur (ci-dessous). |
| m6 | **Point connu, confirmé.** À 1440, l'en-tête de `PageParcours` est décalé : « Retour » se centre dans le premier tiers et « Étape 1 sur 3 » flotte au milieu. Cause : `Flexible` + `Spacer` + `Flexible` partagent la ligne en trois parts égales. | `lib/core/widgets/page_parcours.dart:88-107` ; capture `ct8_complement_motif_1440_light.png` | `Flexible(child: Align(alignment: AlignmentDirectional.centerStart, child: <Retour>))`, sans `Spacer`, puis `Expanded(child: Text(…, textAlign: TextAlign.end))` ; vérifier la galerie à 200 %. Le widget est partagé : tracer la correction pour HU-1 si elle n'est pas faite ici. |
| m7 | **Point connu, partiellement confirmé.** À 390, la question de l'étape 1 du Complément passe sous l'en-tête, coupée (« Pourquoi ajoutez-vous ce complément ? » à moitié masquée). L'étape 3 s'affiche correctement. C'est le contenu qui défile sous un en-tête opaque, sans séparation, probablement après le choix d'une carte. | Capture `ct8_complement_motif_390_light.png` ; `page_parcours.dart:133-144` | Pas de défilement automatique au choix d'une carte ; un trait ou une ombre sous l'en-tête dès que le contenu défile ; vérifier la marge haute du contenu de `PageShell` quand `entete` est fourni. |
| m8 | À l'ordinateur, le bouton de `PageParcours` occupe toute la largeur (Observation, Complément), alors que le compte rendu met son bouton dominant à droite, au bord de fin (K-42, K-56). Deux règles différentes dans le même parcours. | `page_parcours.dart:113-122` ; capture `ct8_complement_motif_1440_light.png` | Hors mobile : `Align(alignment: AlignmentDirectional.centerEnd, child: ActionPrincipale(pleineLargeur: false))`. Widget partagé : tracer pour HU-1. |
| m9 | **Point connu, infirmé comme défaut produit.** Les « chiffres brouillés » en RTL viennent du texte **français** forcé en RTL : un texte arabe réel s'ordonnerait correctement. Reste un vrai défaut : des valeurs sont composées dans le code (« date, heure »), donc l'ordre et la virgule ne sont pas traduisibles. La ligne ~584 (`'${faits.reconnexions}'`) est saine. | `historique_controleur_page.dart:363, 430` (concaténation `'${…}, ${…}'`) | Une clé i18n `controleur.historique.dateHeure` (« {date}, {heure} ») ; refaire la recette RTL avec les vraies chaînes `ar` à LG-1. |
| m10 | **Point connu, confirmé.** La coquille du contrôleur n'a aucun bandeau « hors ligne ». Mais aucun mécanisme de connectivité n'existe nulle part dans `lib/` (recherche sans résultat) : ce n'est pas propre à la vague. Les échecs d'envoi sont honnêtes (D5, K-59). | `app_router.dart:807-846` ; scénario 29 de `CT_RAPPORT.md` | Rien dans la vague ; à brancher à BR-1 avec le scénario 29, pour tous les rôles. |

**Note, sans défaut retenu.** La page de démonstration affiche « Admin-Contrôleur » et « Enseignant ou Admin passent en Contrôle » (`fr.i18n.json:3302, 3305-3306`). Cette page sert au directeur, pas au client, donc K-53 n'est pas violée. Pour être homogène, on peut écrire « Administration ». Le libellé « Administrateur » de `Compte > Espaces` n'est vu que par le personnel lui-même.

## Conformités vérifiées

- **C1 et C14** :
  - Aucun bouton grisé avant le direct : une ligne calme, « Le contrôle s'ouvrira dès que la séance sera en direct. » (`controle_page.dart:286-306`).
  - Mission indisponible : le message générique seul.
  - Un seul emplacement, sans écran de détail intermédiaire.
- **C2** : aucun interrupteur ni aucune case de partage. La notice tient en une ligne. La transmission est lancée sans geste, et son état est dit honnêtement : en cours, transmise seulement après la réponse du serveur, ou échec avec « Réessayer ». « Écrire à l'administration » n'est jamais une condition d'envoi. *Seul le rattachement à la visite est faux (B1).*
- **C5** : la salle est unique (`RoleSalle.controleur`). Elle n'offre que Son reçu, Agrandir et Quitter, sans commande interdite rendue, même grisée. La sortie se fait sans confirmation.
- **C4** : les faits sont en lecture seule et repliés par défaut. Le retard est écrit en mots (« 8 min de retard »), jamais porté par la couleur seule.
- **C10** : le rapport envoyé n'est pas modifiable ; le Complément laisse le parent intact.
- **C15** : aucune présélection, pas de compteur de caractères, des cartes et non des listes déroulantes. Le brouillon reste en mémoire seulement (C12).
- **C16** : les libellés du document sont repris. « Intervention de l'administration souhaitée » remplace le libellé du document, conformément à K-53.
- **K-53** : aucun « admin » visible côté client dans `controleur.*`. L'auteur des messages s'affiche « Administration ».
- **D5** : tous les échecs disent « n'est pas confirmé » ou « n'est pas confirmée », jamais « n'a pas été envoyé ».
- **K-59** : chaque échec donne la cause probable, la suite à donner et ce qui reste fiable (exception : m1).
- **K-54** : tous les boutons de la vague passent par `ActionPrincipale` partagé, y compris dans `FilDiscussion`.
- **K-55** : sections du Détail et carte « À terminer » séparées par l'écart ; la liste de l'Historique est une seule carte à séparateurs fins (`CarteLignes`).
- **K-56** : un seul bouton plein par écran : Commencer, Envoyer, Ajouter un complément. Les autres boutons sont secondaires ou tertiaires.
- **K-57** : choix par cartes, élève pris dans la liste de la Classe ; la saisie libre est réservée au texte.
- **C8** : la frontière des données est testée à trois largeurs ; prénoms seulement.
- **C9** : le bandeau permanent est le même pour tous les rôles.
- **C13** : quatre destinations, dans l'ordre.
- **C17** : un fil par mission, contexte épinglé, aucun onglet.
- **C18** : filtres Période, Classe et État, sans filtre Enseignant.
- **K-28** : fournisseurs neutres par défaut et démonstration fermée en production (recette 32, testée).
- **K-37** : aucun fichier de `lib/core/theme/` touché par la vague.
- **Coran** : aucun rendu du Coran.

## Questions au directeur

1. **Lignes « quand / conséquence » (K-58).** Celles du compte rendu et de l'observation (16 options) sont absentes du document 08 : peuvent-elles être rédigées par l'agent puis validées en un seul lot ? *Recommandation : oui, proposées dans `LEXIQUE_CONTROLEUR.md` et montrées en français.*
2. **Complément (m5).** Le Complément ajouté depuis l'Historique doit-il être une tâche plein écran, sans barre de navigation, comme le compte rendu ? *Recommandation : oui (C13).*
