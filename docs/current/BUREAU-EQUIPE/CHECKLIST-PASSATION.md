# Checklist du pilote « Bureau de l'équipe » (depuis la passation du 16/11/2026)

**Mise à jour : 16/11/2026, 19 h 55 UTC** · pilote : `session_0163KjrwwgbbL52RHBDSnDVm` (nuit du 16 au 17/11 ;
remplace `session_0163KjrvqR38dL9HhgktqAdg`, archivée)

Légende : ☐ à faire · ◐ en cours · ☑ fait (fusionné, installé, vérifié par le pilote ; « prouvé » seulement
par le directeur) · ⏸ attend le directeur

Agents (quatre au plus, l'agent de la messagerie compte) :
BE-DOSSIER `session_0163KjrwjpTfzQhFiSkkKCFu` (**bloqué**, voir §4) · BE-GESTES `session_0163KjrwBaUXiPyqrRVXnqkq`
(#550 à jour, puis écran « Débloquer le versement ») · BE-PIECE `session_0163KjruLibdrXxvtW8jdRoq` (écran du vrai
type de la pièce) · agent de la messagerie (sous le Pilote Messagerie `session_0163KjrvqyXGcbF9eGGztS24`).
BE-S1 et BE-LISTE : archivés (travail poussé). Plage de ce chantier : 202611294… (440000, 450000, 470000, 480000,
490000 pris ; 410000-430000 et 460000 libres).

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
| 6 | #547 LP-2 liste des enseignants (écran) | ◐ | 11 contrôles verts, « Tests Flutter lot 0 » encore en cours à 19:52 ; aucun changement de textes ni de routes sur `main` depuis sa base ; fusion dès que vert |
| 7 | #550 CLORE-COMPLEMENT-VRAI (écran) | ◐ | **en conflit avec `main`** ; confiée à BE-GESTES (fusion de `main`, slang deux fois) |
| 8 | DISPENSE-ECRAN | ⏸ | travail **non perdu** : commit local `6aa823c66` chez BE-DOSSIER, branche `claude/dispense-ecran` jamais poussée. BE-DOSSIER refuse de pousser sans l'accord du directeur lui-même (il dit que le directeur a refusé sa dernière poussée). Non archivé exprès : l'archiver détruirait ce commit. Voir §4 |
| 9 | DEBLOQUER-VERSEMENT-ECRAN | ◐ | BE-GESTES, après #550 |
| 10 | PIECE-TYPE-ECRAN (l'écran lit `genreFichier`) | ◐ | BE-PIECE |
| 11 | Vérification de trois gestes du menu | ☐ | intégrée à la carte des gestes (n° 13) : les trois gestes ne sont nommés nulle part dans les documents |
| 12 | #525 CAPTCHA-PLACE | ☐ | vérifier dans un navigateur, puis fusionner ou fermer avec la raison |
| 13 | **PREMIER TRAVAIL (§0 bis)** : `CARTE-GESTES-DIRECTION.md` | ◐ | lecture du code et de la base en cours ; présentée au directeur au réveil avant tout code qui en dépend |

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
| D-6 | Le courriel d'admission dit maintenant « nous vous écrirons dès que les moments seront ouverts », mais rien n'écrit aux candidats quand un créneau s'ouvre. Faut-il un lot « prévenir à l'ouverture » ? | oui, avant de rouvrir les entretiens (D-3) |
| D-7 | BE-DOSSIER attend votre mot pour pousser DISPENSE-ECRAN (commit local `6aa823c66`). Dites-lui « pousse » dans sa session (« BE-DOSSIER : le dossier en trois étages ») | le dire : la poussée ne touche qu'une branche, ni `main` ni la production |
| C | La carte des gestes (`CARTE-GESTES-DIRECTION.md`) | à lire en premier |
