# Checklist du pilote « Bureau de l'équipe » (depuis la passation du 16/11/2026)

**Mise à jour : 16/11/2026, 21 h 47 UTC** · pilote : `session_0163KjrwwgbbL52RHBDSnDVm` (nuit du 16 au 17/11 ;
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

## 0. Pour le directeur au réveil

(rempli au matin : dix lignes au plus)

## 1. En cours

| # | Lot | État | Preuve / prochaine action |
| :-: | :--- | :-: | :--- |
| 1 | #549 COMPLEMENT-EN-COURS (serveur, 450000) | ☑ | installée 19:18 UTC (pilote précédent) |
| 2 | #548 DISPENSE-ENTRETIEN (serveur, 470000) | ☑ | installée 19:39 UTC (pilote précédent) |
| 3 | #557 COURRIEL-ENTRETIEN (440000) | ☑ | fusionnée 19:48 (092f3c2) ; **installée 19:48 UTC** (version 20261116194834) ; fichier de `main` identique à la copie relue, 0 mot d'effacement ; vérifié : `admettre_salle_verification` porte `creneauxOuverts`, fonction privée fermée à `authenticated` et `anon` ; déploiement Supabase (fonctions courriels-envoi, push-envoi) run 539 vert. Fait : **aucun moment d'entretien ouvert en ce moment**, donc les prochains courriels disent « nous vous écrirons ». Promesse non exécutée à ce jour : ouvrir un créneau n'écrit à personne (voir D-6). Aucun des 6 courriels du 16/11 n'a été renvoyé |
| 4 | #553 MOBILE-MONEY-GH-KE (480000) | ☑ | fusionnée 19:49 (35a2b4a) ; **installée 19:49 UTC** (20261116194944) ; avant : 5 candidatures GH/KE, 1 en « paiement non disponible », déclencheur `O` ; après : 4 lignes confirmées, 4 opérateurs, journal = 5 examinées (4 GH, 1 KE), 0 ramenée, déclencheur `O`. Une candidature GH/KE reste « paiement non disponible » (son moyen ne croise toujours pas) |
| 5 | #555 PIECE-TYPE (490000) | ☑ | fusionnée 19:50 (bce8334) ; **installée 19:50 UTC** (20261116195029) ; `piece_dossier_candidat` rend `typeContenu` et `genreFichier` ; `anon` sans droit |
| 6 | #547 LP-2 liste des enseignants (écran) | ◐ | **bloquée** : le lot 0 des tests ne finit jamais (`garde_ancres` boucle sur `EntreeFiltre(libelle)` depuis 19:49) ; confiée à BE-GESTES après #550 |
| 7 | #550 CLORE-COMPLEMENT-VRAI (écran) | ◐ | **en conflit avec `main`** ; confiée à BE-GESTES (fusion de `main`, slang deux fois) |
| 8 | DISPENSE-ECRAN | ⏸ | travail **non perdu** : commit local `6aa823c66` chez BE-DOSSIER, branche `claude/dispense-ecran` jamais poussée. BE-DOSSIER refuse de pousser sans l'accord du directeur lui-même (il dit que le directeur a refusé sa dernière poussée). Non archivé exprès : l'archiver détruirait ce commit. Voir §4 |
| 9 | DEBLOQUER-VERSEMENT-ECRAN | ◐ | BE-GESTES, après #550 et #547 ; même PR : phrases des deux nouveaux refus d'« Accueillir » |
| 9 ter | BE-2a-1 MISSION serveur (migration 20261129420000, à installer APRÈS 410000) | ◐ | **CI rouge 21:11** (garde AF-LB : fonctions nouvelles hors liste blanche ; correctif chez BE-PIECE). PR #565 (BE-PIECE). **Relue par le pilote, avis favorable** : tables RLS sans droit API ; fonctions privées fermées ; portes de mission réservées à la direction en double authentification (aal2) ; dans les 13 portes ouvertes, la vérification par dossier (`candidature_geste_ouvrir`) précède toute écriture (mesuré en production) ; pièce d'identité hors mission ; lectures bornées par `lire` et `voir_contact`. Attend : fusion de `main` par BE-PIECE, CI verte, puis fusion et installation (après 410000, faite) |
| 9 bis | ACCUEIL-SEPARE serveur (migration 20261129410000) | ☑ | #564 fusionnée 21:05 (b0f913b), après fusion de `main` par le pilote (conflit REGISTRE-LOTS) et CI verte ; **installée 21:06 UTC** (20261116210608) ; fichier de `main` identique à la copie relue, 0 mot d'effacement ; vérifié : contrôles `piece_validee` et `complement_clos` présents, plus d'approbation de la pièce dans « Accueillir », `anon` sans droit ; 0 dossier en `decision_en_attente`. Phrases écran : chez BE-GESTES |
| 10 | PIECE-TYPE-ECRAN (l'écran lit `genreFichier`) | ☑ | #563 fusionnée 20:36 UTC (dd61742) ; CI verte (13 contrôles) ; écran seul ; déploiement automatique ; non prouvé : réponse réelle lue seulement en simulation ; 2 pièces sur 338 sans type s'affichent « Fichier » |
| 11 | Vérification de trois gestes du menu | ☑ | faite dans la carte (n° 13) pour tous les gestes du menu ; les trois gestes n'étaient nommés nulle part |
| 12 | #525 CAPTCHA-PLACE | ☐ | aucun aperçu Vercel dans la PR, base du matin ; à vérifier dans un navigateur après mise à jour, ou fermer |
| 13 | **PREMIER TRAVAIL (§0 bis)** : `CARTE-GESTES-DIRECTION.md` | ☑ | écrite (14 trous, 8 lots, questions Q1 à Q5) ; deux faits clés revérifiés en base par le pilote ; arbitrée par le pilote le 16/11 à 20 h 10 (le directeur : « ne me demande plus rien ») |
| 14 | #587 DETTE-CONTROLLER (800000) | ☑ | fusionnée (63bd7a61) ; **installée** le 17/11 ; vérifié : 4 politiques passent par `controleur_voit_session`, 6 exclusions du contrôleur, `mes_seances_v` security_barrier, `anon` sans EXECUTE, 0 compte contrôleur. La dette « controller » ci-dessus est fermée |
| 15 | #588 PX-4 MODE ESSAI serveur (650000) | ☑ | fusionnée (5a41b9b9) ; relue : 5 fonctions remplacées, diff = la seule restriction d'essai, 0 mot d'effacement, empreintes de prod vérifiées avant ; **installée** le 17/11 ; après : 7 empreintes md5 = fichier, `essai_fils` vide, Praxis toujours éteint (actif et autonome faux), droits conformes |
| 16 | #589 PX-4 écran (sélecteur de conversations) | ◐ | CI rouge (1 test, lot 3) renvoyée à BE-PIECE ; touche `com_messages/liste_fils.dart` : **avis favorable du Pilote Messagerie** (déplacement pur de LigneFil), à condition d'une CI verte avec `messagerie_couleurs_test`, `nouveau_fils_test` et `verifier_conversations` |
| 19 | Dette : 5 scénarios SQL rouges sur `main` | ◐ | #593 (BE-GESTES, sans migration) : 4 tests périmés ou fragiles corrigés ; cand_l2a2 : geste 24 `confirmer_moyen_paiement` = **code mort** (arbitrage du pilote : `paiement_etat` ne rend jamais `a_verifier` ; les 3 dossiers dont la colonne dit `a_verifier` sont tous retirés) ; ménage à faire plus tard. Détail initial : | `cadre_publication`, `calendrier_pauses`, `cand_l2a1`, `cand_l2a2`, `cand_l3` (signalés par BE-GESTES, 17/11) ; hors `ci.yml`, donc personne ne les voit échouer ; à confier après DETTE-COMPTABLE |
| 17 | #578 COMPLEMENT-SALLE-EXAMEN (710000) | ☑ | fusionnée (6a0f5f6e) après fusion de `main` par BE-SALLE ; ancres revérifiées juste avant ; **installée** le 17/11 vers 2 h 30 UTC ; vérifié : 3 règles neuves (37 au total), CHECK à 8 valeurs, porte `annuler_complement_candidat` DEFINER, `anon` sans droit, capacités `annulerComplement` et `modifierComplement`. Suivent #574, #583 |
| 18 | #591 DETTE-COMPTABLE (810000) | ☑ | fusionnée (091fcf6c) ; **installée** ; vérifié : `sessions_read_privileged` = `controleur_voit_session` seul, `assignments_privileged_read` = admin seul. 1 compte comptable réel : aucun de ses écrans ne lit ces tables (lecture du code), non prouvé par usage |
| 21 | #590 PX-2 serveur (840000) | ◐ | relecture indépendante R15 faite (17/11, 2 h UTC) : BLOQUANT (numéro, réglé) + 5 défauts (côté non vérifié pour écarter/valider, expiration après verrou, mode essai non appliqué à lire/preparer, `donneesReelles` absent de l'état, R4 en union au lieu de couples) + 6 faibles ; tous renvoyés à BE-PIECE avec scénarios. Dette arbitrée : toute direction valide en aal2 peut ouvrir `donnees_reelles` (même schéma que `actif`) |
| 23 | Défaut serveur probable : date limite d'étape d'un élève | ☐ | trouvé par BE-GESTES (#593) : entre 21 h et minuit UTC, `etape_eleve_lecture` rend une date limite d'un jour trop tôt (2027-02-20 au lieu de jour de l'académie + 90 = 2027-02-21) ; piste non prouvée : `now()::date` en UTC au lieu de l'heure de Riyad. Touche le programme (lire `REPRISE-PROGRAMME-PEDAGOGIQUE.md` avant) : à instruire, non corrigé |
| 22 | #594 DETTE-COMPTABLE-2 (830000) | ◐ | BE-GESTES ; relue, avis favorable : la comptabilité ne peut plus forger un crédit au grand livre ni écrire `wallets` ; la direction n'écrit plus `wallets`. **Deux dettes gardées par décision datée** : insertion directe de la direction dans `wallet_entries` (L1-06, 16/10 : à remplacer par une fonction de correction avec motif, aal2, journal) ; lecture de `payout_methods` par direction et comptabilité (08/11 : aucun lecteur connu) |
| 20 | Numéros attribués le 17/11, 2 h UTC | — | 810000 DETTE-COMPTABLE ; 820000 DETTE-SCENARIOS-ROUGES (si défaut serveur) ; 830000 DETTE-COMPTABLE-2 (versements) ; **840000 PX-2** (#590 ; BE-PIECE avait pris 810000 de lui-même : troisième collision, corrigée) ; 660000 libéré |

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
