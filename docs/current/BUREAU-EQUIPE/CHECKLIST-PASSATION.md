# Checklist du pilote « Bureau de l'équipe » (depuis la passation du 16/11/2026)

**Mise à jour : 16/11/2026, 19 h 20 UTC** · pilote : `session_0163KjrudJVgfH6zMjadp2bb`

Légende : ☐ à faire · ◐ en cours · ☑ fait (fusionné, installé, vérifié par le pilote ; « prouvé » seulement
par le directeur) · ⏸ attend le directeur

Agents (quatre au plus, l'agent de la messagerie compte) :
BE-S1 serveur `session_0163Kjryj2PkaDsLakEwZ79y` · BE-DOSSIER écrans `session_0163KjrwjpTfzQhFiSkkKCFu` ·
BE-LISTE `session_0163Kjry77PvmcyfT5dDZ7Kn` · messagerie `session_0163KjryPfZgaNMo9E82VTQx` (fusionne lui-même,
plage 202611295…). Plage de ce chantier : 202611294… (prochain numéro libre : 20261129480000).

## 1. En cours (reprise)

| # | Lot | État | Preuve / prochaine action |
| :-: | :--- | :-: | :--- |
| 1 | #549 COMPLEMENT-EN-COURS (serveur) | ☑ | fusionnée 19:14 UTC (83c7871) ; `complement_en_cours` installée ; vérifié en base : clé présente sur 512/512 lignes, vraie pour 54 |
| 2 | #550 CLORE-COMPLEMENT-VRAI (écran) | ◐ | CI complète jamais lancée ; BE-DOSSIER fusionne `main` et repousse ; fusion quand verte |
| 3 | #548 DISPENSE-ENTRETIEN (serveur, **20261129470000**, pas 460000) | ◐ | CI en cours sur d26057a ; fusion puis installation (réécriture d'un CHECK : exception admise) ; puis prévenir BE-DOSSIER |
| 4 | #547 LP-2 liste des enseignants (écran) | ◐ | nouveau commit 03caeb3, CI à attendre ; fusion |
| 5 | COURRIEL-ENTRETIEN (priorité 1) : le courriel promet un créneau qui n'existe pas | ◐ | BE-S1 ; PR, fusion, déploiement de la fonction de courriel ; aucun renvoi sans accord |
| 6 | MOBILE-MONEY-GH-KE | ☐ | BE-S1 après n° 5 ; compte avant/après, rattrapage |
| 7 | PIECE-TYPE (type réel de la pièce, clés R2 sans extension) | ☐ | BE-S1 après n° 6 |
| 8 | DISPENSE-ECRAN, DEBLOQUER-VERSEMENT-ECRAN, relecture de 3 gestes du menu | ☐ | BE-DOSSIER après #550 et l'installation de #548 |
| 9 | #525 CAPTCHA-PLACE | ☐ | vérifier dans un navigateur (Playwright) puis fusionner, ou fermer avec la raison |
| 10 | NOUVEAU-FILS, messagerie | ◐ | pilote messagerie (rien à faire ici) |
| 11 | Décisions D-1 à D-5 présentées au directeur | ◐ | un seul message, avec recommandation |

## 2. Gros lots (dans l'ordre ; une étape ne commence que quand la précédente est livrée)

| # | Lot | État | Prochaine action |
| :-: | :--- | :-: | :--- |
| G1 | Vague 2 « La mission » : BE-2a serveur (sensible) | ◐ | cahier écrit par le pilote avant tout code, scénarios de refus obligatoires |
| G2 | BE-2b écran « Équipe », BE-2c confier / « Mes dossiers », BE-2d suspendre / rétablir | ☐ | cahiers après BE-2a |
| G3 | Étape E : parcourir « confirmée → première classe » avec un compte de test | ☐ | chaque trou devient un lot |
| G4 | Listes LP-3 à LP-7 | ☐ | avec `RAPPORT-EXPERIENCE` |
| G5 | Vague 4 Studio | ☐ | après G1 et la messagerie |
| G6 | Secrétaire IA « Praxis » (SEC-0 à SEC-5), puis vague 5 | ☐ | |

## 3. Corrections non bloquantes demandées par le directeur

| # | Demande (date) | État | Où elle ira |
| :-: | :--- | :-: | :--- |
| — | (aucune depuis la passation) | | |
