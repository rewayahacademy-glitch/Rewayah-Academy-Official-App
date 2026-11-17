# Checklist du pilote « Bureau de l'équipe » (depuis la passation du 16/11/2026)

**Mise à jour : 17/11/2026, 8 h 00 UTC** · pilote : `session_0163KjrwwgbbL52RHBDSnDVm` (nuit du 16 au 17/11 ;
remplace `session_0163KjrvqR38dL9HhgktqAdg`, archivée)

Légende : ☐ à faire · ◐ en cours · ☑ fait (fusionné, installé, vérifié par le pilote ; « prouvé » seulement
par le directeur) · ⏸ attend le directeur

Agents (quatre au plus, l'agent de la messagerie compte) :
BE-DOSSIER `session_0163KjrwjpTfzQhFiSkkKCFu` (**bloqué**, voir §4) · BE-GESTES `session_0163KjrwBaUXiPyqrRVXnqkq`
(#550 à jour, puis écran « Débloquer le versement ») · BE-PIECE `session_0163KjruLibdrXxvtW8jdRoq` (écran du vrai
type de la pièce) · agent de la messagerie (sous le Pilote Messagerie `session_0163KjrvqyXGcbF9eGGztS24`).
BE-S1 et BE-LISTE : archivés (travail poussé). Plage de ce chantier : 202611294… (440000, 450000, 470000, 480000,
490000 pris ; 410000-430000 et 460000 libres).

## LA LIGNE (directeur, 16/11 au soir : « c'est toi qui dois empêcher les dispersions » ; amendée le 17/11, nuit)

Directeur, 17/11, nuit : « J'ai levé tous les blocages […] pour que tu agisses, pour que je puisse dormir. […] J'ai pas
dit d'arrêter ce qui restait des autres lots déjà commencés […] tu peux les travailler tout en déléguant, tout en
commençant Praxis […] tu peux confier ces petits lots à des sessions Sonnet. » **Le pilote ne demande plus rien au
directeur, pas même un « pousse » : D-7 est levé.** Praxis reste prioritaire ; les lots de la carte avancent en
parallèle, un agent par lot, quatre agents au plus.

| Chantier | Agent | Lots, dans l'ordre | Migrations |
| :--- | :--- | :--- | :--- |
| Praxis | BE-PIECE | PX-1 installé (☑) ; dette R4 indirecte, annuaire agent_ro, puis PX-2 | 202611296… |
| Carte, lot 2 | BE-GESTES | #568 ☑ fusionnée, puis GESTES-DU-SERVEUR (#573 serveur, puis écran) | 20261129740000 (renumérotée : 630000 était pris par Praxis) |
| Carte, lots 5 et 8 | BE-DOSSIER | DISPENSE-ECRAN (#575 ☑ fusionnée), ENTRETIEN-SUIT-LE-DOSSIER (#576), REFAIRE-ENTRETIEN (#579, #580) | 20261129460000, 20261129750000, 20261129700000 |
| Carte, lots 6, 4 et 7 | BE-SALLE (Sonnet, créé le 16/11 à 23 h 18 UTC, `session_0163KjrugbgqtWp3ag4RYXr3`) | PIECE-SUR-LA-FICHE (+ capacité deciderPiece), COMPLEMENT-SALLE-EXAMEN, APRES-CONFIRMEE | 20261129720000, 20261129710000, 20261129730000 |
| Carte, lot 3 | BE-DOSSIER | DEPLACER-ENTRETIEN | 20261129760000 |
| Vague 2 | après la carte | BE-2a-2 (associé), BE-2b (écran Équipe), BE-2c, BE-2d | à réserver |
| Studio | après | — | — |

**Numéros attribués par le pilote seulement** (deux collisions la nuit du 16 au 17/11). Plage **2026112970… à 2026112976…** réservée au Pilote Équipe pour la carte (en plus de 202611294…).

**Dette de sécurité (16/11, BE-PIECE)** : un compte `controller` sans capacité lit par l'API les séances, participants, enregistrements, affectations et disponibilités des familles. Aucun compte de ce rôle en production (vérifié 20 h 45) : à resserrer avant d'en créer un. Scénario `scenarios_cand_l2a2_gestes_direction.sql` rouge sur `main` (confirmé par BE-PIECE sur une copie de `main`). Les scénarios ACCUEIL-SEPARE, BE-2a et Praxis ne sont pas dans `ci.yml` (garde-fou : `.github` interdit aux agents).

**Gelé, sans agent ni travail** : #525, l'étape E, LP-3 à LP-7, BE-COLONNES, BE-1e, BE-1f, l'étape D.

## 00. PRIORITÉS (recadrage du directeur, 17/11 à 8 h : « Praxis opérationnel ce soir à 100 % »)

| Rang | Ce que c'est, en clair | Qui | État |
| :-: | :--- | :--- | :-: |
| 1 | **Praxis répond tout seul** aux messages, sans que le directeur ouvre son chat (mode autonome, étape 15) | BE-PIECE | ◐ arbitré à 8 h 15 : une tâche planifiée par heure, 24 h sur 24, dans un environnement dédié qui seul porte la clé « routine » (saisie par le directeur, jamais vue d'un agent) ; « pouls » visible (migration 900000) ; plafond 30 envois/heure ; tir à blanc en mode essai avant de dire « opérationnel » |
| 2 | **Praxis répond aussi aux candidats** (leurs conversations lui sont fermées aujourd'hui) | BE-GESTES, migration 910000 | ◐ après #606 |
| 3 | **Le profil de Praxis** : son image (fond violet, outils noirs) et la mention IA discrète, surtout dans le détail du profil | agent de la messagerie `session_0163Kjry6zThXGyFJhJk9NHn` (migration 520000 : le client apprend qu'un compte est officiel) | ◐ lancé à 8 h 10 |
| 4 | **La politique de confidentialité** dit qu'un assistant lit les messages : texte arbitré par le pilote (`TEXTES-VALIDES/POLITIQUE-CONFIDENTIALITE-PRAXIS.md`), purge du journal à 12 mois, puis intégration | pilote ☑ texte ; purge : #607 (BE-DOSSIER, migration 920000, un DELETE borné arbitré par le pilote) ; intégration : BE-SALLE après #525 | ◐ |
| 5 | **L'essai à blanc** : le directeur branche Praxis et lui fait répondre à un seul fil de test (`PRAXIS/ESSAI-A-BLANC.md`, écrit par BE-PIECE) | directeur | ⏸ prêt |
| 6 | **La case anti-robot Cloudflare** sous le bouton d'inscription et de connexion (#525, en retard depuis le 16/11) | BE-SALLE | ◐ relancé à 8 h 25 |
| 7 | **Inscription d'un associé invité** par un code (#604) | pilote (mise à jour après #606) ; BE-DOSSIER en pause (plafond de 4 agents) | ◐ bloquée par #606 |
| 8 | **Un test de la facturation qui casse selon l'heure** (bloque la vérification automatique de toutes les PR le lundi et le mardi matin) | BE-GESTES (#606) | ◐ |
| Dette | **Un test de la prière casse tous les lundis** (`scenarios_priere_serveur.sql` l. 1851, collision avec une séance générée le jeudi à 19 h) ; hors `ci.yml`, ne bloque personne. Relevé par BE-GESTES le 17/11 | — | ☐ |
| Après | Praxis fixe des objectifs et des check-lists (PX-3), propose des classes (PX-4), fait des rapports (PX-5) | — | ☐ |

## 0. Pour le directeur au réveil

Résumé de la nuit du 16 au 17/11 (pilote, 6 h UTC). Rien ne vous est demandé.
1. **Rien de prouvé par vous** : tout ce qui suit est fusionné, installé et vérifié en base par le pilote, jamais joué par une vraie personne.
2. **Migrations installées** : 650000, 710000, 720000, 730000, 760000, 460000 et 750000, 770000 et 780000, 790000, 800000, 810000, 830000, 840000 (PX-2), 860000, 870000, 880000. Chacune : fichier de `main` identique à la copie relue, ancres et empreintes vérifiées avant et après.
3. **Carte des gestes de la direction** : pièce sur la fiche, complément en Salle d'examen, déplacer un entretien, l'entretien suit le dossier, restreindre / demander une vérification / lever (lots 2 à 8 livrés côté serveur).
4. **Sécurité resserrée** : contrôleur et comptable ne lisent plus séances ni affectations ; personne n'écrit plus les portefeuilles ; coordonnées de versement fermées à la direction et à la comptabilité ; journal de Praxis plafonné.
5. **Praxis** : PX-2 installé, **toujours éteint** (actif, autonome et données réelles faux ; 0 clé, 0 proposition). Vous seul l'allumez.
6. **Associé et écran Équipe** : rôle `associe`, invitations, missions ; écran Équipe en ligne. 0 associé, 0 mission. Courriel d'invitation **non lancé** (aucun texte validé).
7. **Un incident du pilote, corrigé** : une ligne vide perdue en recopiant une fonction (780000) ; remplacée par le texte exact quelques minutes après ; aucun effet sur les données.
8. **Dettes ouvertes** : un scénario SQL de `ci.yml` dépend de l'heure (rouge entre ~6 h 50 et 9 h UTC, correctif en cours) ; aucun message à une personne restreinte ; pages de l'associé décidées par la coque, pas par le serveur ; scénarios SQL hors `ci.yml` ; date limite d'étape d'un élève décalée d'un jour (non corrigée, touche le programme).
9. **En cours** : #604 (écran d'inscription de l'associé). Fusionnées au matin : #602 (scénarios rouges), #595 (écran PX-2, Praxis toujours éteint), #605 (registre).
10. Détail ligne par ligne : §1 ci-dessous.

## 1. En cours

| # | Lot | État | Preuve / prochaine action |
| :-: | :--- | :-: | :--- |
| 1 | #549 COMPLEMENT-EN-COURS (serveur, 450000) | ☑ | installée 19:18 UTC (pilote précédent) |
| 2 | #548 DISPENSE-ENTRETIEN (serveur, 470000) | ☑ | installée 19:39 UTC (pilote précédent) |
| 3 | #557 COURRIEL-ENTRETIEN (440000) | ☑ | fusionnée 19:48 (092f3c2) ; **installée 19:48 UTC** (version 20261116194834) ; fichier de `main` identique à la copie relue, 0 mot d'effacement ; vérifié : `admettre_salle_verification` porte `creneauxOuverts`, fonction privée fermée à `authenticated` et `anon` ; déploiement Supabase (fonctions courriels-envoi, push-envoi) run 539 vert. Fait : **aucun moment d'entretien ouvert en ce moment**, donc les prochains courriels disent « nous vous écrirons ». Promesse non exécutée à ce jour : ouvrir un créneau n'écrit à personne (voir D-6). Aucun des 6 courriels du 16/11 n'a été renvoyé |
| 4 | #553 MOBILE-MONEY-GH-KE (480000) | ☑ | fusionnée 19:49 (35a2b4a) ; **installée 19:49 UTC** (20261116194944) ; avant : 5 candidatures GH/KE, 1 en « paiement non disponible », déclencheur `O` ; après : 4 lignes confirmées, 4 opérateurs, journal = 5 examinées (4 GH, 1 KE), 0 ramenée, déclencheur `O`. Une candidature GH/KE reste « paiement non disponible » (son moyen ne croise toujours pas) |
| 5 | #555 PIECE-TYPE (490000) | ☑ | fusionnée 19:50 (bce8334) ; **installée 19:50 UTC** (20261116195029) ; `piece_dossier_candidat` rend `typeContenu` et `genreFichier` ; `anon` sans droit |
| 6 | #547 LP-2 liste des enseignants (écran) | ☑ | **fusionnée le 16/11 à 23 h 09 UTC** (la ligne disait « bloquée » : périmée, corrigée le 17/11 à 8 h). Non prouvé par usage ; gestes d'affectation non affichés (aucun écran d'affectation) |
| 7 | #550 CLORE-COMPLEMENT-VRAI (écran) | ☑ | **fusionnée le 16/11 à 22 h 26 UTC** (ligne périmée, corrigée). Vérifié le 17/11 : la liste rend `complementEnCours` (`cand_ligne_json`) ; le menu suit désormais la clé `gestes` du serveur (GESTES-DU-SERVEUR), donc aucune régression même si `lire_candidature` ne rend pas ce champ |
| 8 | DISPENSE-ECRAN | ☑ | livré par #575 (fusionnée, voir tableau de LA LIGNE) ; la ligne « commit local non poussé » est périmée |
| 9 | DEBLOQUER-VERSEMENT-ECRAN | ☑ | **déjà livré par #568** (65b5ed592, 17/11) : geste au dossier et au menu d'une ligne, feuille avec motif, phrases des refus d'accueil (relevé de BE-GESTES le 17/11 à 6 h 09, lu dans `main`). Ligne du registre corrigée en PR docs. Non prouvé par usage |
| 9 ter | BE-2a-1 MISSION serveur (migration 20261129420000, à installer APRÈS 410000) | ◐ | **CI rouge 21:11** (garde AF-LB : fonctions nouvelles hors liste blanche ; correctif chez BE-PIECE). PR #565 (BE-PIECE). **Relue par le pilote, avis favorable** : tables RLS sans droit API ; fonctions privées fermées ; portes de mission réservées à la direction en double authentification (aal2) ; dans les 13 portes ouvertes, la vérification par dossier (`candidature_geste_ouvrir`) précède toute écriture (mesuré en production) ; pièce d'identité hors mission ; lectures bornées par `lire` et `voir_contact`. Attend : fusion de `main` par BE-PIECE, CI verte, puis fusion et installation (après 410000, faite) |
| 9 bis | ACCUEIL-SEPARE serveur (migration 20261129410000) | ☑ | #564 fusionnée 21:05 (b0f913b), après fusion de `main` par le pilote (conflit REGISTRE-LOTS) et CI verte ; **installée 21:06 UTC** (20261116210608) ; fichier de `main` identique à la copie relue, 0 mot d'effacement ; vérifié : contrôles `piece_validee` et `complement_clos` présents, plus d'approbation de la pièce dans « Accueillir », `anon` sans droit ; 0 dossier en `decision_en_attente`. Phrases écran : chez BE-GESTES |
| 10 | PIECE-TYPE-ECRAN (l'écran lit `genreFichier`) | ☑ | #563 fusionnée 20:36 UTC (dd61742) ; CI verte (13 contrôles) ; écran seul ; déploiement automatique ; non prouvé : réponse réelle lue seulement en simulation ; 2 pièces sur 338 sans type s'affichent « Fichier » |
| 11 | Vérification de trois gestes du menu | ☑ | faite dans la carte (n° 13) pour tous les gestes du menu ; les trois gestes n'étaient nommés nulle part |
| 12 | #525 CAPTCHA-PLACE | ☐ | aucun aperçu Vercel dans la PR, base du matin ; à vérifier dans un navigateur après mise à jour, ou fermer |
| 13 | **PREMIER TRAVAIL (§0 bis)** : `CARTE-GESTES-DIRECTION.md` | ☑ | écrite (14 trous, 8 lots, questions Q1 à Q5) ; deux faits clés revérifiés en base par le pilote ; arbitrée par le pilote le 16/11 à 20 h 10 (le directeur : « ne me demande plus rien ») |
| 14 | #587 DETTE-CONTROLLER (800000) | ☑ | fusionnée (63bd7a61) ; **installée** le 17/11 ; vérifié : 4 politiques passent par `controleur_voit_session`, 6 exclusions du contrôleur, `mes_seances_v` security_barrier, `anon` sans EXECUTE, 0 compte contrôleur. La dette « controller » ci-dessus est fermée |
| 15 | #588 PX-4 MODE ESSAI serveur (650000) | ☑ | fusionnée (5a41b9b9) ; relue : 5 fonctions remplacées, diff = la seule restriction d'essai, 0 mot d'effacement, empreintes de prod vérifiées avant ; **installée** le 17/11 ; après : 7 empreintes md5 = fichier, `essai_fils` vide, Praxis toujours éteint (actif et autonome faux), droits conformes |
| 16 | #589 PX-4 écran (sélecteur de conversations) | ☑ | **fusionnée** (be78d689) le 17/11 vers 2 h 55 UTC, CI entièrement verte, avis favorable du Pilote Messagerie ; déploiement automatique ; non prouvé par usage (CI d'abord rouge sur 1 test du lot 3, corrigée par BE-PIECE) |
| 25 | #576 ENTRETIEN-SUIT-LE-DOSSIER (460000 + 750000) | ☑ | **fusionnée (0caf124e) ; 460000 puis 750000 installées** le 17/11 vers 3 h 20 UTC ; vérifié : déclencheur `candidatures_entretien_suit` actif, CHECK des notifications à 62 valeurs (`entretien_annule`, `annonce_direction` gardée), notification aux intervieweurs en place, fonctions privées fermées ; rattrapage : 0 ligne. Non prouvé par usage (aucun entretien ouvert) |
| 19 | Dette : 5 scénarios SQL rouges sur `main` | ◐ | #593 (BE-GESTES, sans migration) : 4 tests périmés ou fragiles corrigés ; cand_l2a2 : geste 24 `confirmer_moyen_paiement` = **code mort** (arbitrage du pilote : `paiement_etat` ne rend jamais `a_verifier` ; les 3 dossiers dont la colonne dit `a_verifier` sont tous retirés) ; ménage à faire plus tard ; à jour sur `main` (9d1df51a4), CI à relire. Scénarios : `cadre_publication`, `calendrier_pauses`, `cand_l2a1`, `cand_l2a2`, `cand_l3` (signalés par BE-GESTES, 17/11) ; hors `ci.yml`, donc personne ne les voit échouer ; à confier après DETTE-COMPTABLE |
| 17 | #578 COMPLEMENT-SALLE-EXAMEN (710000) | ☑ | fusionnée (6a0f5f6e) après fusion de `main` par BE-SALLE ; ancres revérifiées juste avant ; **installée** le 17/11 vers 2 h 30 UTC ; vérifié : 3 règles neuves (37 au total), CHECK à 8 valeurs, porte `annuler_complement_candidat` DEFINER, `anon` sans droit, capacités `annulerComplement` et `modifierComplement`. Suivent #574, #583 |
| 18 | #591 DETTE-COMPTABLE (810000) | ☑ | fusionnée (091fcf6c) ; **installée** ; vérifié : `sessions_read_privileged` = `controleur_voit_session` seul, `assignments_privileged_read` = admin seul. 1 compte comptable réel : aucun de ses écrans ne lit ces tables (lecture du code), non prouvé par usage |
| 21 | #590 PX-2 serveur (840000) | ☑ | **fusionnée (f6423337) et installée** le 17/11 vers 2 h 45 UTC, après rejeu local par le pilote (539 migrations, 9 scénarios verts, mutation rouge) ; préflight passé ; les 14 fonctions = empreintes du fichier, owner postgres, `anon` nulle part ; Praxis éteint, `donnees_reelles` faux, 0 proposition ; aucune erreur Postgres après. Écran PX-2 confié à BE-PIECE (#595). Avant : relecture indépendante R15 faite (17/11, 2 h UTC) : BLOQUANT (numéro, réglé) + 5 défauts (côté non vérifié pour écarter/valider, expiration après verrou, mode essai non appliqué à lire/preparer, `donneesReelles` absent de l'état, R4 en union au lieu de couples) + 6 faibles ; tous renvoyés à BE-PIECE avec scénarios. Dette arbitrée : toute direction valide en aal2 peut ouvrir `donnees_reelles` (même schéma que `actif`) |
| 24 | `scenarios_gestes_du_serveur` rouge sur `main` depuis #578 | ☑ | l'ancienne assertion « aucun complément en paiement non disponible » est périmée par T7 (variante 4) ; correction dans #574 (BE-SALLE) |
| 23 | Défaut serveur probable : date limite d'étape d'un élève | ☐ | trouvé par BE-GESTES (#593) : entre 21 h et minuit UTC, `etape_eleve_lecture` rend une date limite d'un jour trop tôt (2027-02-20 au lieu de jour de l'académie + 90 = 2027-02-21) ; piste non prouvée : `now()::date` en UTC au lieu de l'heure de Riyad. Touche le programme (lire `REPRISE-PROGRAMME-PEDAGOGIQUE.md` avant) : à instruire, non corrigé |
| 22 | #594 DETTE-COMPTABLE-2 (830000) | ☑ | **fusionnée (f42d6930) et installée** le 17/11 vers 3 h 05 UTC ; vérifié : `authenticated` = SELECT seul sur `wallets`, insertion au grand livre = admin seul, lectures des familles inchangées. CORRECTION-PAR-ECRITURE-INVERSE (850000) **reportée** par le pilote : l'inverse d'une écriture dépend de son type et d'une règle de trésorerie qui relève de HARMONISER-ARGENT ; analyse de BE-GESTES à écrire dans `DETTE-CORRECTION-GRAND-LIVRE.md`. Relue : la comptabilité ne peut plus forger un crédit au grand livre ni écrire `wallets` ; la direction n'écrit plus `wallets`. **Deux dettes gardées par décision datée** : insertion directe de la direction dans `wallet_entries` (L1-06, 16/10 : à remplacer par une fonction de correction avec motif, aal2, journal) ; lecture de `payout_methods` par direction et comptabilité (08/11 : aucun lecteur connu) |
| 26 | #601 DETTE-PAYOUT-METHODS (880000) | ☑ | fusionnée (482a5ac9) ; empreintes de politique vérifiées avant (3827…, 4a2b…) ; **installée** le 17/11 vers 4 h 40 UTC ; vérifié : `payout_methods_admin_accountant_all` USING false / WITH CHECK false, lecture famille inchangée (même empreinte), 0 ligne dans la table. La dette « lecture de `payout_methods` » de la ligne 22 est fermée. Inventaire : #600 (docs) |
| 27 | #598 AUDIT-JOURNAL-PRAXIS (docs) | ☑ | fusionnée (1f4a74cd), documents seuls |
| 28 | #585 BE-2a-2 ASSOCIÉ (770000 + 780000) | ☑ | fusionnée (dfb89718) ; relue en entier ; seul mot d'effacement = réécriture du CHECK `profiles_household_required` ; **770000 puis 780000 installées** le 17/11 vers 4 h 50 UTC ; vérifié : valeur `associe`, 6 fonctions = empreintes du fichier, DEFINER/INVOKER attendus, `anon` et `service_role` sans droit, `invitations_associe` RLS + 1 politique, `accorder_mission` sans `controller`, bibliothèque `inscrits` fermée à l'associé (post-vol), 0 profil associé. **Incident du pilote, corrigé** : ma recopie de `inscrire_associe_invite` avait perdu une ligne vide (empreinte 566f…) ; remplacée aussitôt par `CREATE OR REPLACE` au texte exact du fichier (même signature, droits et commentaire conservés), empreinte = ffa0c133 comme le dépôt. Non prouvé par usage : `scenarios_be2a2_associe.sql` hors `ci.yml` (preuve locale de BE-DOSSIER) ; aucun écran ni courriel (courriel non lancé : aucun texte validé) |
| 29 | #603 BE-2b lectures (790000) puis #592 écran Équipe | ☑ | **#603 fusionnée (cf655614) ; 790000 installée** le 17/11 vers 5 h 12 UTC ; vérifié : `lister_personnes_mission` et `lister_gestes_mission` DEFINER = empreintes du fichier, `anon` et `agent_ro` sans droit, `lister_attributions` porte nom, rôle et côté (comptes officiels exclus). **#592 fusionnée (b44078df)** le 17/11 vers 5 h 45 UTC, CI verte (13 contrôles), relue par le pilote (11 RPC = signatures de production, aucune page ne lit le rôle, aucun défilement en cadre), Pilote Messagerie prévenu, sans objection. **Dette** : les pages ouvertes de l'associé sont décidées par la coque (navigation par rôle), pas par une capacité du serveur. Non prouvé par usage : 0 associé, 0 mission en production. Suite : écran d'inscription de l'associé (BE-DOSSIER) ; courriel d'invitation non lancé (aucun texte validé) |
| 31 | #600 inventaire payout_methods (docs) | ☑ | fusionnée (e0a29653) |
| 33 | #595 PX-2 écran + #605 registre | ☑ | #595 **fusionnée (fbe159d3)** le 17/11 vers 6 h 40 UTC, après retrait à la demande du pilote d'un reformatage hors périmètre (179 → 45 fichiers) ; relue : 4 RPC = signatures de production, clé d'idempotence stable, états erreur et hors ligne, double vérification, interrupteur « données réelles » avec avertissement ; Pilote Messagerie sans objection. Praxis toujours éteint. Non prouvé : « Valider » jamais joué (0 proposition). #605 fusionnée (34adceb2) : DEBLOQUER-VERSEMENT-ECRAN livré par #568 |
| 34 | #604 inscription de l'associé (écran) | ◐ | relue ; corrigée deux fois par BE-DOSSIER (conflit, « hors ligne » restreint aux erreurs réseau, un seul bouton plein, texte hors ligne) ; tests Flutter tous verts sur 6e1151aa0. **Bloquée par un rouge qui n'est pas le sien** : « Migrations applicables » (scénario `fac_f_relances_suspension` ligne 265 dépendant de l'heure, rouge pour toute PR entre ~6 h 50 et 9 h UTC). Correctif confié à BE-GESTES (DETTE-SCENARIO-HORLOGE). Non prouvé contre le vrai serveur |
| 32 | #602 DETTE-SCENARIOS-ROUGES-2 (sans migration) | ☑ | fusionnée (5d973b5a) le 17/11 vers 6 h 07 UTC ; relue : `rls_tables_private (b)` admet une fonction INVOKER exécutable par aucun rôle client (vérifié en production : une seule, `candidature_geste_deplacer_entretien`) ; `be2a2 t7` ignore une politique `false` ; 154 scénarios rejoués en local par BE-GESTES, 0 échec ; mutations rouges. Non prouvé par la CI (scénarios hors `ci.yml`). 890000 libéré |
| 30 | #583 APRÈS-CONFIRMÉE (730000) | ☑ | **fusionnée (a08e1225) ; installée** le 17/11 vers 5 h 08 UTC ; ancres revérifiées juste avant ; vérifié : 2 règles `demander_verification_*`, `restreindre_candidat` et `lever_restriction_candidat` DEFINER = empreintes du fichier, `anon` et `service_role` sans droit, capacité `demanderVerification`. Non prouvé par usage ; dette : aucun message à la personne restreinte (aucun texte). Suivent #600 (docs) et #602 (DETTE-SCENARIOS-ROUGES-2, sans migration ; 890000 libéré) |
| 20 | Numéros attribués le 17/11, 2 h UTC | — | 850000 réservé (correction du grand livre, reportée) ; 860000 PRAXIS-PLAFOND-REFUS (#597) ; 870000 PRAXIS-PLAFOND-GLOBAL (#599) ; 880000 DETTE-PAYOUT-METHODS (#601) ; 890000 réservé (DETTE-SCENARIOS-ROUGES-2 si vrai défaut) ; 810000 DETTE-COMPTABLE ; 820000 DETTE-SCENARIOS-ROUGES (si défaut serveur) ; 830000 DETTE-COMPTABLE-2 (versements) ; **840000 PX-2** (#590 ; BE-PIECE avait pris 810000 de lui-même : troisième collision, corrigée) ; 660000 libéré |

| 26 | #574 PIECE-SUR-LA-FICHE (720000) | ☑ | **fusionnée (72ae3cc4) et installée** le 17/11 vers 3 h 40 UTC ; vérifié : capacité `deciderPiece` (une fois), droits inchangés ; corrige aussi `scenarios_gestes_du_serveur` |
| 27 | #593 DETTE-SCENARIOS-ROUGES | ☑ | **fusionnée (532b28db)** : 5 scénarios verts, geste 24 prouvé absent (code mort) |
| 28 | #597 PRAXIS-PLAFOND-REFUS (860000) | ☑ | **fusionnée (adcbe70c) et installée** ; vérifié : empreinte = fichier, service_role seul, index présent. Suite : #599 plafond global (870000) |
| 29 | #582 DEPLACER-ENTRETIEN (760000) | ☑ | **fusionnée (b9893b02) et installée** le 17/11 vers 4 h UTC ; vérifié : 3 fonctions = empreintes du fichier, règle 48, capacité `deplacerEntretien`, `planifier_entretien` passe par `entretien_controles_planification` (même comportement), porte DEFINER sans `anon`. #581 en conflit i18n après elle → BE-DOSSIER |
| 30 | #599 PRAXIS-PLAFOND-GLOBAL (870000) | ☑ | **fusionnée (f8fba8bf) et installée** ; vérifié : 3 empreintes = fichier, index, plafond 600, Praxis éteint, porte de réglage fermée à `anon` |
| 31 | #596 docs (correction du grand livre) | ☑ | fusionnée (cfab596c) |
| 32 | Envoi de message après PX-1 (610000, extraction com_envoyer_message) | ☑ | **prouvé en production** par le Pilote Messagerie (17/11, 4 h 15 UTC) : 3 messages réels en 200, une ligne chacun ; `com_annonce_envoyer` pas encore servi (non prouvé) ; double appel client absorbé par l'idempotence (chez le Pilote Messagerie) |
| 33 | #581 REFAIRE-ENTRETIEN écran | ☑ | **fusionnée (56ab5eea)**, sans migration ; les trois lots de la carte de BE-DOSSIER sont dans `main` |
| 34 | Audit de #585 (rôle `associe`) | ☑ | fait par le pilote le 17/11 vers 4 h 25 UTC (schéma seul) : 206 politiques, aucune par exclusion de rôle ; politiques « tout compte valide » = données de référence. **Un point exigé** : un associé lirait les documents de bibliothèque `inscrits` (library_resource_lecture, tranche_autorisee ELSE true, autoriser_lecture_version, n4_ressource_lisible) → correction demandée dans 780000 avant toute installation |

## 2. Gros lots (dans l'ordre ; une étape ne commence que quand la précédente est livrée)

| # | Lot | État | Prochaine action |
| :-: | :--- | :-: | :--- |
| G0 | Lots issus de la carte des gestes | ◐ | arbitrés par le pilote (carte §4.3, consigne 22) ; lot 1 ACCUEIL-SEPARE (serveur) confié à BE-PIECE, son écran ira à BE-GESTES |
| G1 | Vague 2 « La mission » : BE-2a serveur (sensible) | ◐ | **cahier écrit** (`CAHIER-BE-2A-MISSION.md`) ; code confié à BE-PIECE après son écran et ACCUEIL-SEPARE (le lancement d'un agent serveur dédié a été refusé par le contrôle des permissions) |
| G2 | BE-2b écran « Équipe », BE-2c confier / « Mes dossiers », BE-2d suspendre / rétablir | ◐ | cahiers écrits : `CAHIER-BE-2A-2-ASSOCIE.md` (serveur, chez BE-PIECE après #565) et `CAHIER-BE-2B-EQUIPE.md` (écran, chez BE-GESTES après sa file) ; BE-2c et BE-2d ensuite |
| G3 | Étape E : parcourir « confirmée → première classe » avec un compte de test | ☐ | chaque trou devient un lot |
| G4 | Listes LP-3 à LP-7 | ☐ | avec `RAPPORT-EXPERIENCE` |
| G5 | Vague 4 Studio | ☐ | après G1 et la messagerie |
| G6 | Secrétaire IA « Praxis » (SEC-0 à SEC-5), puis vague 5 | ☐ | |

## 3. Corrections non bloquantes demandées par le directeur

| # | Demande (date) | État | Où elle ira |
| :-: | :--- | :-: | :--- |
| — | (aucune depuis la passation) | | |

## 4. Décisions (arbitrées par le pilote depuis le 16/11 à 20 h 10, consigne 22 ; le directeur peut les reprendre)

| N° | Question | Recommandation |
| :-: | :--- | :--- |
| D-1 | Franc CFA : ouvrir « virement SWIFT en dollars » pour BJ, BF, ML, NE, TG ; CI et SN à la même règle ? | oui pour les deux |
| D-2 | Algérie, Guinée, Liberia (7 candidats) | à vérifier sur les pages publiques de wise.com, puis proposer |
| D-3 | Rouvrir les entretiens : qui interviewe, et quand ? | dépend de la vague 2 |
| D-4 | « Demander une précision » pendant qu'un dossier est « à compléter » | à présenter avec BE-1e |
| D-5 | Un candidat dispensé d'entretien reçoit-il un message ? Une dispense s'annule-t-elle ? | message : oui, court ; annulation : non |
| D-6 | Le courriel d'admission dit maintenant « nous vous écrirons dès que les moments seront ouverts », mais rien n'écrit aux candidats quand un créneau s'ouvre. Faut-il un lot « prévenir à l'ouverture » ? | oui, avant de rouvrir les entretiens (D-3) |
| D-7 | ~~BE-DOSSIER attend votre mot pour pousser DISPENSE-ECRAN~~ **Levé le 17/11 (nuit) : le directeur ne doit jamais être attendu pour une poussée de branche ; le pilote a donné l'ordre de pousser.** Faute du pilote : ce n'était pas un blocage du directeur | fait |
| C | La carte des gestes (`CARTE-GESTES-DIRECTION.md`) | à lire en premier |
