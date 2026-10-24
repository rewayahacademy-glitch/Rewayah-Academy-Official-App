# Pilotage des boucles : le but unique de la session de travail (24/10/2026)

Décision du directeur du 24/10/2026 : **il délègue le projet à 100 %.** Claude décide, calcule,
choisit pour les utilisateurs finaux, et rend compte. Le directeur ne fait que ce que le
garde-fou interdit aux agents : ouvrir une pull request vers `main`, la fusionner, annuler une
CI, et tester en production. Après les tests, ce qui ne lui plaît pas se change. Mais ça doit
marcher, de bonne foi.

Ce fichier est **le but** de la session de travail. Elle le relit à chaque tour et avance
jusqu'à ce que toutes les phrases des boucles soient vraies. Le pilote est la session
`session_018zqR7D4uVdaYUvrgoEHNPG` : on lui rend compte par `send_message`, jamais au
directeur par copier-coller.

## 1. Protocole de chaque tour

1. Lire ce fichier, puis `docs/current/BOUCLE-1_PLAN_2026-10-24.md`, puis seulement les
   fichiers nommés par l'étape en cours. Rien d'autre. Pas d'archives, pas de catalogues.
2. Regarder l'état réel : `git fetch`, la branche, la pull request si elle existe, la base de
   production en lecture seule (SELECT par l'outil Supabase).
3. Faire tout ce qui ne dépend pas du directeur. Vérifier en local avant tout push :
   `dart analyze --fatal-infos`, `flutter test` sur les dossiers touchés,
   `dart run tool/verifier_jetons.dart`, `dart run tool/verifier_revue.dart`.
4. Quand une action du directeur est requise, écrire **une seule fois** dans sa conversation,
   en trois lignes : quoi cliquer, le lien, ce qu'il doit répondre (« vrai » ou « faux » avec une
   capture). Puis envoyer au pilote un résumé de cinq lignes (étape, état, blocage, preuve, suite).
   Puis s'arrêter : ne pas relancer de travail, ne pas relancer la CI, ne pas relire le dépôt.
   Si le but se relance tout seul pendant une attente du directeur : vérifier l'état en trois
   appels au plus, et si rien n'a changé, se rendormir sans rien écrire.
5. Quand le directeur répond « faux » avec une capture : lire les journaux Supabase du jour
   (lecture seule), corriger dans la même branche, une pull request, et recommencer au 3.
6. Règles qui ne bougent jamais : une étape à la fois ; une pull request par étape ; aucun
   push vers `main` ; aucune écriture distante sur Supabase ; aucune annulation ou relance de
   CI ; aucun identifiant du projet de production dans une commande ; aucune session parallèle ;
   pas de nom de modèle dans les commits ; **vérité d'abord** (ce qui est faux, bloqué, inconnu
   ou non prouvé se dit en premier, en une phrase).
7. Les tâches mécaniques (lancer des tests et rapporter, grep, clé i18n dans les deux langues,
   description de pull request) passent à un petit modèle par l'outil Agent. Jamais un
   branchement, du SQL, une règle RLS, un diagnostic, un choix.

## 2. Décisions prises par Claude, par délégation du directeur (24/10/2026)

Elles valent jusqu'à ce que le directeur, après test, demande un changement.

- **Actif** : membre d'une classe non clôturée et présent à au moins une séance dans les
  quatorze derniers jours. Sinon inactif.
- **À jour de paiement** : une marque de paiement posée par la direction pour le mois civil en
  cours. Sinon en retard. **Une seule marque par élève et par mois, par la direction, sans
  double validation** : le directeur est seul, le circuit comptable à deux personnes attend.
- **Régulier** : présent à au moins quatre des cinq dernières séances planifiées de sa classe.
  **À surveiller** : deux absences de suite. **Ponctuel** : entré en salle au plus cinq minutes
  après l'heure.
- **Migration par vagues, Meet en secours** : vague 1, deux classes, une semaine ; vague 2, la
  moitié ; vague 3, tout. Tant qu'une classe reste sur Meet, l'enseignant marque les présences
  dans l'application (la correction de présence existe) : le tableau se remplit sans attendre
  que la vidéo tienne à l'échelle.
- **E-mail d'attente aux 568 candidats** : envoyé par la direction depuis l'application, dans
  les 48 heures qui suivent K1 vraie. Contenu : candidature reçue, première réponse sous trois
  semaines, personne n'a de compte à créer ni de pièce à envoyer avant d'y être invité.
- **Pull request 50 (module des candidatures)** : ne se fusionne pas avant la fin de la
  Boucle 2, et pas avant d'avoir vérifié qu'elle respecte les trois salles du directeur : tri
  sur la liste sans compte, puis compte et pièce pour les seuls retenus.
- **Écrans « indisponibles »** : à chaque boucle, un écran que la boucle ne branche pas
  disparaît du menu de la direction au lieu d'y rester mort.

## 3. Les boucles, dans l'ordre, avec leurs phrases

### Boucle 1 : une classe tourne
K1 à K4 du plan. Étape 1 codée sur la branche `claude/admiring-brown-r6ai72`, 276 tests
ciblés verts, non fusionnée. Attend : le directeur ouvre la pull request
(https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/compare/main...claude/admiring-brown-r6ai72?expand=1),
fusionne, teste K1. Puis K2 (aucun code prévu), K3 par l'import des élèves actuels, K4.

### Boucle 2 : la vraie académie dans l'application
- B2.1 Les élèves actuels sont importés depuis les deux CSV du classeur Google (essai à blanc,
  puis confirmation) ; chacun a son matricule et son foyer. Preuve : le directeur retrouve un
  élève qu'il connaît, avec son tuteur, dans Comptes.
- B2.2 Les enseignants actuels sont validés un par un par K1 et affectés à leurs classes réelles,
  jour et heure vrais. Preuve : l'enseignant voit sa classe et sa prochaine séance.
- B2.2 bis, **avant la vague 1** (décision du 24/10, besoin du directeur : la classe connaît son
  emploi du temps indéfiniment, la porte s'ouvre vingt minutes avant chaque occurrence, quel que
  soit le jour) : (a) **la cloche**, une tâche planifiée de nuit (pg_cron, comme `courriels-envoi`)
  qui prolonge toutes les classes actives pour qu'elles aient toujours quatre semaines de séances
  devant elles, en rejouant `materialiser_seances_groupe`, qui ignore les séances existantes, sur
  tous les créneaux de la classe ; (b) **le concierge**, au clic sur « Rejoindre », si la séance
  prévue par l'emploi du temps manque, elle est créée sur-le-champ, sans doublon sous deux clics
  simultanés ; (c) l'écran Classes de la direction gagne « ajouter un créneau » pour une classe à
  plusieurs jours par semaine. Les séances créées à l'avance restent la source des présences, de
  la paie, des annulations et des remplacements : rien d'autre ne change. Preuve : une classe
  créée aujourd'hui montre encore sa séance dans cinq semaines, et la porte s'ouvre vingt minutes
  avant.
- B2.3 Vague 1 : deux classes tiennent une semaine de séances dans l'application ; les autres
  restent sur Meet et l'enseignant y marque les présences. Preuve : le tableau de la direction
  montre, pour ces classes, qui est venu et qui a manqué, sans rien recalculer ailleurs.
- B2.4 Le tableau de la direction lit les définitions ci-dessus : actifs, à jour de paiement,
  réguliers, à surveiller, ponctuels, et quel enseignant enseigne à quel élève, avec l'emploi du
  temps. Preuve : le directeur compare avec son WhatsApp sur dix élèves et ne trouve pas d'écart.
- B2.5 Vagues 2 et 3. Preuve : plus aucune séance sur Meet, la paie à 47 % d'un mois se lit.

### Boucle 3 : les 568 candidats
- B3.1 E-mail d'attente (décision ci-dessus). Preuve : le directeur le reçoit sur une adresse test.
- B3.2 Vérifier la pull request 50 contre les trois salles ; corriger ce qui y manque ; fusionner.
- B3.3 Preuve : la direction voit les 568 dans une liste, trie, n'invite que les retenus à créer
  un compte, et seuls ceux-là déposent une pièce.

### Boucle 4 : le paiement en ligne
Quand le directeur ouvre aux nouveaux élèves, et pas avant. Stripe, puis : une famille paie dans
l'application et l'élève entre dans sa classe.

## 4. Journal du pilotage

| Date | Boucle, étape | État | Par qui |
|---|---|---|---|
| 2026-10-24 | B1 étape 1 | codé, tests verts, en attente d'ouverture de la pull request par le directeur | session de travail |
| 2026-10-24 | B1 étape 1 | aucune pull request ouverte à 05:05 UTC (49 et 51 fermées) ; on attend toujours que le directeur l'ouvre | session de travail |
| 2026-10-24 | B1 K2, préalables (lecture seule, production) | **aucun code à prévoir**. `creer_groupe` (8 arguments, celle qu'appelle `ServiceGroupesSupabase`, branché par défaut) exige un enseignant `active` ou `provisional_active`, `teacher_profiles.kyc_status = approved`, un genre compatible, un plafond horaire (40 h ici), sans exiger de disponibilités (`false`). `decider_dossier` approuvé passe le compte en `active` **et** `kyc_status` en `approved` : K1 vraie suffit. Le déclencheur `groupes_horaire_verifie_enseignant` (qui exige les disponibilités) ne joue qu'à la modification de l'horaire, pas à la création : l'enseignant de test n'a aucune disponibilité, ce n'est pas un blocage. `groupes_candidat_non_affectable` : il n'a aucune ligne de candidature, rien ne bloque. Séances : le déclencheur `tc_materialiser_apres_creation_groupe` les crée à l'insertion. 0 classe en production | session de travail |
| 2026-10-24 | B1 K3, préalables (lecture seule, production) | **aucun code à prévoir**. `ajouter_eleve_groupe`, `previsualiser_import_inscriptions`, `confirmer_import_inscriptions` présentes et ouvertes à `authenticated` ; `ImportInscriptionsSupabase` branché dans `main.dart` ; fonction Edge `creer-profil-enfant` active. Le déclencheur `tc_materialiser_apres_adhesion` matérialise à l'ajout d'un élève. En base : 1 admin, 1 enseignant, aucun tuteur ni élève | session de travail |
| 2026-10-24 | Boucle 2, risque repéré | **aucune tâche planifiée ne prolonge l'horizon des séances** (seul `courriels-envoi` est dans `cron.job`). Les séances ne se créent qu'à la création de la classe, au changement d'horaire, de l'enseignant ou de l'état, et à l'ajout d'un élève, sur quatre semaines. Sans rien de tout cela, une classe n'a plus de séance au bout de quatre semaines. Sans effet sur l'essai K2-K4 du jour ; à traiter avant B2.3 (une migration, donc sur ordre) | session de travail |
| 2026-10-24 | B2.2 bis | décidé : cloche de nuit (fenêtre glissante), concierge au clic, « ajouter un créneau » | pilote |
| 2026-10-24 | B1 K1 | PR 52 fusionnée ; Deploy Supabase et Flutter Web → Vercel réussis (10:47 UTC), app.rewayahacademy.com répond 200. Base de production à 10:52 UTC, lecture seule : pièce `approved`, `teacher_profiles.kyc_status` `approved`, compte `active`. **Côté serveur, la validation a eu lieu. Reste à prouver par le directeur : l'enseignant reconnecté arrive sur sa Journée** | session de travail |
