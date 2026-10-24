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
| 2026-10-24 | B1 K1 | **prouvé par le directeur** : connecté en enseignant, il arrive sur Aujourd'hui, Classes, Disponibilités, Profil (captures dans la conversation du pilote) | directeur |
| 2026-10-24 | B1 K2, contrôle avant création (lecture seule) | la séance du jour même est créée **si l'heure choisie est strictement après maintenant** (heures pleines seulement ; « samedi 14 h » créé à 13:20 heure de Paris donne une séance aujourd'hui à 14:00, porte à 13:40 ; « samedi 13 h » donne samedi prochain). Raison : `groupes_creneau_ancre` remplit `groupe_creneaux` à l'insertion, avant `tc_materialiser_apres_creation_groupe` (ordre alphabétique des déclencheurs AFTER) ; `instant_creneau_reference` rend la prochaine occurrence strictement après maintenant ; jours ISO (1 = lundi) côté base comme côté Flutter ; fuseau par défaut Europe/Paris. Vérifié sur le code SQL : le garde-fou refuse d'appeler `instant_creneau`, même en lecture | session de travail |
| 2026-10-24 | B1 défaut D1 (photo de profil de l'enseignant) | **cause certaine, dans le code** : `envoiPhotoPubliqueProvider` (`lib/features/profil_enseignant/photo_publique.dart`) vaut `_EnvoiNonBranche`, qui rend toujours une erreur (« photo publique : BR-1 ») ; `main.dart` ne le remplace pas, seule la démonstration le fait. La photo ne quitte jamais l'appareil : aucune trace dans les journaux Supabase entre 11:50 et 12:10 UTC. Côté serveur, existent déjà : le seau privé `photos_enseignants` (écriture par l'enseignant valide dans son dossier `<uid>/`, lecture par lui, la direction et ses classes) et la colonne `teacher_profiles.photo_storage_key`. Manque : un adaptateur d'envoi Flutter, et une façon pour l'enseignant d'enregistrer la clé, car `teacher_profiles` ne s'écrit que par la direction (une RPC, donc une migration). Correction après K4, dans la PR des reliquats B1 | session de travail |
| 2026-10-24 | B2.2, défaut D2 | aucun e-mail n'avertit l'enseignant que son compte est confirmé : inscrit en B2.2, pas avant | pilote |
| 2026-10-24 | B1 K2 | **prouvé par le directeur** : classe « Bilal classe », jeudi 29/10 19:00-20:00, « Préparer la séance » visible côté enseignant. La classe a été clôturée ensuite (11:51 UTC) pour les essais du samedi : sa vérification sur quatre semaines est sans objet | directeur |
| 2026-10-24 | B1 reliquat R1 | rattaché à B2.2 bis (c) : un sélecteur clair de jour et d'heure, plusieurs créneaux par classe | pilote |
| 2026-10-24 | B1 reliquat R2 | les corrections d'interface du Recrutement sont dans la PR 50, non fusionnée : à rappeler en Boucle 3 | pilote |
| 2026-10-24 | B1 reliquat R3, **priorité haute** (PR des reliquats B1) | sur téléphone, rien ne se rafraîchit : pas de tirer-pour-rafraîchir, les données restent en cache jusqu'à ce qu'on quitte l'application et qu'on efface les cookies. Correction : dans le composant de page commun, un tirer-pour-rafraîchir qui invalide les providers de l'écran, et un rechargement à chaque retour sur un onglet | pilote |
| 2026-10-24 | B1 défaut D3 (séances fantômes à la clôture) | **cause prouvée (lecture seule)** : `cloturer_groupe` met `ended_at` et ferme les membres mais laisse les séances futures en `planned` ; `sessions_no_teacher_overlap` refuse alors toute nouvelle classe du même enseignant au même instant (les `creer_groupe` du directeur en 400 depuis 12:00 UTC ; 12 séances fantômes jusqu'au 21/11 pour les trois classes closes). **Corrigé dans le code, pas en production** : migration `20261024150000_cloture_annule_seances.sql` (même UPDATE que R9 de `fusionner_classes`, plus rattrapage des classes closes ; aucune suppression), scénario `scenarios_cloture_annule_seances.sql` vert sur Postgres 16 local, rouge avec l'ancienne fonction. Reste : appliquer la migration (directeur) et inscrire le scénario dans `ci.yml` (zone interdite à l'agent). À vérifier : une classe close garde `etat = 'active'` | session de travail |
| 2026-10-24 | B1 K3, parcours tuteur (lecture seule, dépôt et production) | **bloqué, BR-1 sans date** : l'inscription (`inscrire_titulaire` → `private.creer_profil_inscription_interne`) crée foyer et profil tuteur en `pending_kyc` (vérifié en production) ; `creer_profil_enfant` refuse tant que le tuteur n'est ni `active` ni `provisional_active` ; seule `decider_dossier` (pièce approuvée) active un compte, et le tuteur n'a pas d'écran de dépôt (K-47, enfermé dans `/attente`). L'élève adulte reste un profil tuteur, jamais `student`, donc jamais proposé. Aucune demande d'horaire, aucun paiement, aucun matricule bloquant. Décision du directeur attendue : activation manuelle, import des inscriptions ou migration « le tuteur naît actif » | session de travail |
| 2026-10-24 | B1 D4, le tuteur naît actif (décision du pilote, déléguée par le directeur) | **codé, pas en production** : migration `20261024160000_tuteur_nait_actif.sql` (`private.creer_profil_inscription_interne` recréée à l'identique de la production, sauf le statut : `active` pour un tuteur, `pending_kyc` inchangé pour un enseignant ; rattrapage des tuteurs en attente, aucun en production). Vérifié avant d'écrire : `app_account_valid()` accepte `active` ; `guard_teacher_activation_signatures` ne vise que les enseignants ; `creer_profil_enfant` donne à l'enfant le statut du tuteur (donc actif, donc proposable) ; routeur Flutter : un tuteur actif quitte `/attente` pour `/tuteur` (`lib/core/router/redirection.dart`, cas `PorteAcces.actif`), et son compte sans enfant propose « Ajouter un enfant » (`lib/features/compte/compte_page.dart:511`, `AjouterEnfantPage`) : aucun enfermement. Scénario `scenarios_tuteur_nait_actif.sql` vert ; trois scénarios qui posaient l'ancienne règle ADR-014 mis à jour (`etape3`, `af_l1_11`, `l5`) ; les 15 scénarios de la CI verts sur Postgres 16 local | session de travail |
| 2026-10-24 | Boucle 2, défaut D5 (à corriger en B2, pas avant) | un adulte qui apprend pour lui-même reste un `guardian` avec un `student_profiles` sur lui-même, jamais `role = student` : il n'est jamais proposé par « Ajouter un élève » (qui filtre `role = student`), et l'écran « Créer mon profil élève » (`?pour=moi`) est déclaré indisponible | pilote |
| 2026-10-24 | B1 K3 | **prouvé par le directeur** : tuteur « Dyna Sow » inscrit actif (journal de la direction, 16:31 heure de Paris), enfant créé (16:32), ajouté à « Garçons, samedi 16 h » ; l'enseignant voit « 1 élève » sur la carte du jour. Cause du blocage précédent corrigée par D4 (tuteur né actif), appliquée en production par le directeur | directeur |
| 2026-10-24 | B1 reliquat R4 → Boucle 2 (passe d'ensemble, trop large pour la PR des reliquats B1) | écrans du tuteur en largeur ordinateur : cartes et textes qui se chevauchent, contenu coupé ; « et c'est comme ça partout » (directeur) | pilote |
| 2026-10-24 | B1 reliquat R5 → B2.2 bis, avec R1 | sélecteurs jugés datés (boutons ronds d'âge, radios) : à revoir avec le sélecteur de jours et d'heures | pilote |
| 2026-10-24 | B1 reliquat R6 → PR des reliquats B1 | tableau de bord de la direction : la tuile « Élèves sans enseignant » ne mène nulle part au clic ; la liste « Comptes » n'offre aucune action sur un compte (ni clic, ni menu) | pilote |
| 2026-10-24 | B1 reliquat R7 → PR des reliquats B1 | « Rejoindre la salle » proposé avant l'ouverture de la porte ; le refus du serveur (`autoriser_jeton_video`, code 23514, très probablement « salle pas encore ouverte ») remonte en 403 sans phrase (vu à 13:05 UTC pour une porte à 13:40). Afficher l'heure d'ouverture à la place | pilote |
| 2026-10-24 | B1 D6 (l'enfant rejoint la salle depuis l'appareil de son tuteur, décision du pilote) et D8 | **codé, poussé (09854d5), pas en production** : RPC `autoriser_jeton_video_eleve` (service_role seul ; foyer, inscription à la séance, rôle élève seul, `demande_par` journalisé) ; `quitter_salle` accepte l'enseignant de la séance (D8 : 403 « non inscrit a cette seance » à 13:57:48) ; `create-room-token` transmet `eleve_id` ; carte de séance du tuteur : « Rejoindre la salle avec {prénom} », sinon l'heure d'ouverture. Scénario SQL vert ; à faire par le directeur : migration `20261024170000`, déploiement de `create-room-token` | session de travail |
| 2026-10-24 | B1 D7 (code d'appairage refusé sur le web) | **cause prouvée par reproduction, corrigée (5f5f989), pas en production** : `driftDatabase` sans options web levait à l'ouverture ; l'écran en faisait le motif générique, aucune requête vers `session-enfant`. Après correction, la reproduction envoie bien la requête. Même défaut sur la file et l'envoi du cahier de l'enseignant (`depotRapportsProvider`), corrigé par la même ligne | session de travail |
| 2026-10-24 | B1 K4 côté enseignant | **vidéo vraie, prouvée par le directeur** (jeton 13:56:08, joined 13:56:11, left 13:57:49) ; la séance reste `planned` : rien ne fait avancer le statut en direct (ni jeton, ni webhook, ni écran) et la tâche `ses_cloture_auto` n'est pas planifiée en production (`cron.job` : seul `courriels-envoi`) | session de travail |
| 2026-10-24 | B1 D9 (page du Coran en salle) | **diagnostic** : `PageMadina15` (15 lignes) existe dans main mais n'est pas branchée dans `/salle` (`surface_page_fixe.dart`, `_Page`, ne montre qu'un titre) ; repli en texte continu quand UthmanicHafs ne charge pas (`vue_page_mushaf.dart:475`). Lot suivant, sur feu vert | session de travail |
| 2026-10-24 | B1 D10 (l'enseignant ne revient pas en salle après « Quitter ») | **cause non trouvée** ; aucune nouvelle demande de jeton après 13:56:08 (blocage dans l'application). Piste : le cahier, où l'enseignant est envoyé, cassé sur le web avant D7. En attente de la description du directeur | session de travail |
| 2026-10-24 | B1 reliquat R8 → PR des reliquats | la Journée ouvre la salle 10 min avant au lieu de 20 : `seuilOuvertureSalle` (`pre_vol.dart:24`) au lieu de `join_opens_at` | session de travail |
| 2026-10-24 | AVIS-UI | **codé, poussé (688e616)** : formulaire public d'avis recomposé selon les captures du directeur ; bouton d'envoi jamais grisé (K-56), au lieu de « désactivé », signalé au pilote | session de travail |
| 2026-10-24 | Tests préexistants rouges (hors de ces lots, non touchés) | `duree_insecable_4/5` (`file_moderation.dart:510`), `tb_recette/synchronisation_test` (« تم الحفظ »), `com_rc7_lot_l_arabe_test` (« مبرمج »), `dossiers_admin_test` ADM-02 « en production, ni refus ni piece » (rendu caduc par l'Étape 1) : rouges aussi sur le commit parent de D6 | session de travail |
| 2026-10-24 | B1 D10 (retour en salle après « Quitter », décision du pilote) | **codé, commit local, non poussé** (attente de la fusion de la première pull request) : lien « Retourner dans la salle » en haut de la fin de séance (CLV-10), qui relance l'entrée (pré-vol, jeton, salle ; le serveur seul dit si la séance est close) ; même lien en haut du cahier tant que la salle est ouverte (même calcul que la carte de la Journée, sans la base locale). La carte « Aujourd'hui » repropose déjà « Rejoindre la salle » : `cahiersEnFileProvider` lit la base locale sous un try. Tests : 4 nouveaux (lien CLV-10 ; cahier, base saine et en panne, mène à la salle avec son billet ; séance close sans lien) | session de travail |
| 2026-10-24 | B1 D9 (page du Coran en salle) | **codé, commit local, non poussé** : nouveau composant partagé `PageCoranSalle` (`pageMushafProvider` + `PageMadina15`, quinze lignes de l'édition de Médine, sur le parchemin) ; il remplace le texte continu du panneau de l'enseignant (`_Texte` supprimé) et, **nouveau**, s'affiche chez l'élève quand l'enseignant présente une page (avant : l'élève n'avait que la vidéo). Sans police UthmanicHafs ou sans mise en page Madina : un état visible, jamais le texte continu. Non touché : le lecteur `/eleve/coran` garde son repli en texte Tanzil (`vue_page_mushaf.dart:475`). Corrigé au passage : un « ; » sans espace insécable dans le nouveau texte. Tests : panneau, élève, état sans police ; 1902 verts, hors 2 préexistants | session de travail |
| 2026-10-24 | Tests préexistants rouges, suite | s'ajoute `dossiers_sans_piece_test` « en production, aucun verdict avant BR-1 » (rouge aussi sans ces lots, rendu caduc par l'Étape 1, comme ADM-02) | session de travail |
| 2026-10-24 | Suite D9 et AVIS-UI (décisions du pilote) | **poussé** : ADM-02 mis à jour (la production montre la pièce et ouvre le refus depuis l'Étape 1 ; aucun verdict sans geste) ; « Vous êtes » : « Parent ou tuteur » (fr, ar) et cartes en ligne compactes (marges 16/12, hauteur minimale de la cible tactile). **Non prouvé** : la hauteur réelle des cartes à 390 px ; la police des tests Flutter dessine chaque caractère en carré et fausse toute mesure de texte, il faut un navigateur | session de travail |
| 2026-10-24 | D11 (à poser) | `ses_cloture_auto` n'est pas planifiée en production : une séance ne passe jamais à `ended`, la paie ne se calcule pas. À poser par une migration avec la prochaine page de collage (`cron.schedule` idempotent, gardé par la présence de pg_cron) | pilote |
| 2026-10-24 | D9, captures avec les vraies polices (`docs/orchestration/captures/2026-10-24/`) | élève 390 portrait : page de 15 lignes lisible, petite ; élève 1366 : lisible ; **élève 390 paysage (844×390) : illisible**, la page n'a qu'environ 115 px de haut ; enseignant 390 portrait : page d'environ 180 px de large, à la limite ; **enseignant 390 paysage : on ne voit que le haut de la page**, la colonne défile ; enseignant 1366 : lisible. Avis à 390 : les deux cartes « Vous êtes » ont la même hauteur (78 px, libellés sur deux lignes). Captures faites en tests de widget avec les polices du dépôt chargées, pas dans un navigateur | session de travail |
| 2026-10-24 | D9, composition téléphone (feu vert du pilote) | **poussé** : `PageImmersive.lateraleEnPaysage` (téléphone couché : en-tête, bandeau et commandes dans une colonne latérale) ; `_CorpsDocument` : en paysage, la page sur toute la hauteur et la scène réduite à côté ; en portrait, la page sur toute la largeur moins les gouttières, à sa hauteur naturelle (la colonne défile, jamais la page). Seulement quand la page se compose vraiment (`pageCoranLisible`) : les états d'erreur gardent leur composition (SALLE-ERR-320-1). Captures rejouées : élève 390 portrait, élève paysage, enseignant 390 portrait, élève et enseignant 1366 **lisibles** ; **enseignant paysage encore trop petit** (titre, flèches et « Ouvrir le Coran » restent dans la colonne du panneau) | session de travail |
| 2026-10-24 | Essai K4 (15:52–16:18 UTC), retour du directeur | vrai : audio dans les deux sens, vidéo de l'enseignant chez l'élève, sorties et retours (`quitter_salle` 204). Faux : D13 décalage audio d'environ 0,5 s ; D14 caméra de l'élève jamais vue ; D15 image « 240p » ; D16 composition de la salle **rejetée** par le directeur (page du Coran plein écran, commandes en surimpression au toucher). Composition 1366 arrêtée, non poussée (git stash) | pilote |
| 2026-10-24 | Bouton « Rejoindre la salle avec {prénom} » non vu | il n'est que sur la page de la Classe (Accueil, carte de l'élève, « Voir la classe »), salle ouverte 10 min avant ou séance en direct ; présent dans `main` 94fd1bd. Proposé : le poser aussi sur la carte de l'Accueil | session de travail |
| 2026-10-24 | D16, maquettes | **aucune image de maquette de la salle de cours dans le dépôt** (ni `main`, ni PR 50, ni historique) ; seules images de salle citées : observation #20, #21, #24 (dossier maître du 14/10), fichiers absents. Spécification courte proposée au pilote ; deux points à trancher : invariant archivé « rien ne se ferme sur minuterie » et bandeau permanent (ADR-011) face à « aucune barre fixe » | session de travail |
| 2026-10-24 | D14, lecture seule | jetons de Hakim : `can_publish_video` faux à 15:52 et 15:59, vrai dès 16:06 (`camera_policy` passé à `allowed` entre les deux). Après 16:06 le bouton existait, caméra coupée à l'entrée ; publication non prouvée (le webhook ne journalise pas les pistes). Proposé : journaliser `track_published`, ligne « Ta caméra est coupée », nouveau jeton quand la politique change | session de travail |
| 2026-10-24 | D13, D15, lecture seule | serveur LiveKit Cloud (adresse dans un secret, région non lisible ici). Client : `adaptiveStream`, `dynacast`, audio et vidéo par défaut du SDK 2.12 (720p, VP8, simulcast). D13 : aucun tampon ajouté par le client, cause non prouvée (Bluetooth ou réseau d'un côté probables), mesure dans le tableau de bord LiveKit. D15 : `adaptiveStream` reçoit la couche des petites vignettes ; proposé 720p simulcast, environ 1,5 à 1,8 Go par heure pour un enseignant et 5 élèves | session de travail |
