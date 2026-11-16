# Checklist du pilote « Bureau de l'équipe » (depuis la passation du 16/11/2026)

**Mise à jour : 16/11/2026, 19 h 50 UTC** · pilote : `session_0163KjrvqR38dL9HhgktqAdg` (nuit du 16 au 17/11 ;
remplace `session_0163KjrudJVgfH6zMjadp2bb`)

Légende : ☐ à faire · ◐ en cours · ☑ fait (fusionné, installé, vérifié par le pilote ; « prouvé » seulement
par le directeur) · ⏸ attend le directeur

Agents (quatre au plus, l'agent de la messagerie compte) :
BE-S1 serveur `session_0163Kjryj2PkaDsLakEwZ79y` · BE-DOSSIER écrans `session_0163KjrwjpTfzQhFiSkkKCFu` ·
BE-LISTE `session_0163Kjry77PvmcyfT5dDZ7Kn` · Pilote Messagerie `session_0163Kjrx8uX1pRbk4RhE7Yuz` (fusionne
lui-même, plage 202611295…). Plage de ce chantier : 202611294… (440000 à #557, 480000 à #553, 490000 à #555).

## 0. Pour le directeur au réveil

(rempli au matin : dix lignes au plus)

## 1. En cours

| # | Lot | État | Preuve / prochaine action |
| :-: | :--- | :-: | :--- |
| 1 | #549 COMPLEMENT-EN-COURS (serveur) | ☑ | fusionnée et installée par le pilote précédent (19:18 UTC) |
| 2 | #550 CLORE-COMPLEMENT-VRAI (écran) | ◐ | BE-DOSSIER ; fusion dès CI verte |
| 3 | #548 DISPENSE-ENTRETIEN (serveur, 20261129470000) | ☑ | fusionnée (2fd2423) ; **installée 19:39 UTC** par ce pilote ; texte installé identique au fichier de `main` (md5 5d6eafc6…) ; vérifié : table avec RLS, règle du geste, CHECK étendu, `anon` sans droit, `authenticated` exécute, capacité `dispenserEntretien` |
| 4 | #547 LP-2 liste des enseignants (écran) | ◐ | BE-LISTE ; fusion dès CI verte |
| 5 | #557 COURRIEL-ENTRETIEN (priorité 1 ; migration 20261129440000 ; sa fusion redéploie `courriels-envoi` et `push-envoi`) | ◐ | BE-S1 ; relecture, fusion, installation, vérification du déploiement ; aucun renvoi de courriel sans accord |
| 6 | #553 MOBILE-MONEY-GH-KE (20261129480000) | ◐ | après #557 ; NOTICE attendu « 4 lignes écrites, 5 candidatures examinées, 0 ramenée » ; `tgenabled = 'O'` après |
| 7 | #555 PIECE-TYPE (20261129490000) | ◐ | après #553 |
| 8 | DISPENSE-ECRAN (à refaire : travail non poussé perdu), DEBLOQUER-VERSEMENT-ECRAN, vérification de 3 gestes du menu, écran du type de la pièce | ☐ | BE-DOSSIER après #550 |
| 9 | #525 CAPTCHA-PLACE | ☐ | vérifier dans un navigateur, puis fusionner ou fermer avec la raison |
| 10 | **PREMIER TRAVAIL (§0 bis)** : `CARTE-GESTES-DIRECTION.md` | ◐ | lue dans le code et la base ; présentée au directeur au réveil avant tout code qui en dépend |

## 2. Gros lots (dans l'ordre ; une étape ne commence que quand la précédente est livrée)

| # | Lot | État | Prochaine action |
| :-: | :--- | :-: | :--- |
| G0 | Lots issus de la carte des gestes | ⏸ | après décision du directeur sur la carte |
| G1 | Vague 2 « La mission » : BE-2a serveur (sensible) | ☐ | cahier écrit par le pilote avant tout code, scénarios de refus obligatoires |
| G2 | BE-2b écran « Équipe », BE-2c confier / « Mes dossiers », BE-2d suspendre / rétablir | ☐ | cahiers après BE-2a |
| G3 | Étape E : parcourir « confirmée → première classe » avec un compte de test | ☐ | chaque trou devient un lot |
| G4 | Listes LP-3 à LP-7 | ☐ | avec `RAPPORT-EXPERIENCE` |
| G5 | Vague 4 Studio | ☐ | après G1 et la messagerie |
| G6 | Secrétaire IA « Praxis » (SEC-0 à SEC-5), puis vague 5 | ☐ | |

## 3. Corrections non bloquantes demandées par le directeur

| # | Demande (date) | État | Où elle ira |
| :-: | :--- | :-: | :--- |
| — | (aucune depuis la passation) | | |

## 4. Pour le directeur au réveil (décisions et faits)

| N° | Question | Recommandation |
| :-: | :--- | :--- |
| D-1 | Franc CFA : ouvrir « virement SWIFT en dollars » pour BJ, BF, ML, NE, TG ; CI et SN à la même règle ? | oui pour les deux |
| D-2 | Algérie, Guinée, Liberia (7 candidats) | à vérifier sur les pages publiques de wise.com, puis proposer |
| D-3 | Rouvrir les entretiens : qui interviewe, et quand ? | dépend de la vague 2 |
| D-4 | « Demander une précision » pendant qu'un dossier est « à compléter » | à présenter avec BE-1e |
| D-5 | Un candidat dispensé d'entretien reçoit-il un message ? Une dispense s'annule-t-elle ? | message : oui, court ; annulation : non |
| C | La carte des gestes (`CARTE-GESTES-DIRECTION.md`) | à lire en premier |
