# Réconciliation du tableau (10/10/2026)

Étapes « a_faire » et « en_cours » de la collection `etapes` comparées à
`origin/ccr-1b1bfa0b-m1kvkk` (1e3c8378). Exclues, car confiées ailleurs : les
étapes de la liste de l'orchestrateur, les `ECHELLE-*`, `TB-RC`, et les
étapes FIN/CPT/AR. La collection ne contient aucun sous-élément d'étape ;
`CARTES-PERSO-1`, `COM-MSG-2`, `COM-ANN-2` et `COM-CAPT` n'y sont pas des
fiches (seulement CARTES-PERSO-1b et 1c, « fait ») : leur code est livré.
Chaque fiche touchée porte un champ `reconciliation` (une ligne).

## Changement d'état

| Id | Ancien → nouveau | Preuve |
| :--- | :--- | :--- |
| CLAVIER-ENTREE-1 | en_cours → fait | ccr 858dcc66 (commit 81849c2b : `pressable.dart`, `langue_demarrage.dart`, `main.dart`, `web/index.html`). Testé localement : `pressable_clavier_test` et `langue_demarrage_test`, 52 verts. |

## Inchangé, avec la raison écrite dans la fiche

| Id | État | Ce qui manque | Dépend de |
| :--- | :--- | :--- | :--- |
| BACK-FRONT-CTRL-MISSION-1 | a_faire | Ports du contrôleur toujours en démo | Serveur (B-12) |
| BR-1 | a_faire | Branchement en une fois | Directeur, fin des écrans |
| CONTRASTE-SUPPORT-1 | a_faire | Couleurs du support partagé | TH-2 / HU-1 |
| CORAN-320-FOND-1 | a_faire | Réserves de CORAN-320-1b (aucun commit CORAN-320-FOND dans ccr ni sur une branche distante) | Rien (vraiment ouvert) |
| DASH-ADM-INC | a_faire | Journal filtré par adresse | BR-1 ou directeur |
| DASH-ADM-PLANNING | a_faire | Page Planning | Directeur (après les visuels) |
| DOC-08-NON-POUSSE | a_faire | Deux commits sur le poste A | Directeur, poste A |
| EA-ROLE-1 | a_faire | Capacité « élève autonome » dans l'accueil et la salle | EA-ROLE-BR (gelée 04/10) |
| EA-ROLE-BR | a_faire | Capacité servie avec la session | Serveur, gel du directeur |
| HU-1 | a_faire | Harmonisation UI | Fin des visuels |
| KYC-LECTURE-1 | a_faire | ccr: la migration 0004 autorise encore `controller` ; la migration de Codex est sur `codex/backend-sec-prod*`, pas dans ccr. Écran : fait (BACK-FRONT-KYC-DIR-1, `claude/back-front` 8801eadd) | Serveur (BR-1 / SEC-PROD) |
| LG-1 | a_faire | Langues | Fin des rôles |
| LIVE-CHRONO-01 | a_faire | Aucun chrono discret d'en-tête dans la salle | Passe Classe Live ou HU-1 |
| LIVE-PAUSE-01 | a_faire | Aucun code | BR-1, décision F3 |
| LOGO-1 | a_faire | Aucun asset de logo | Logo du directeur |
| PAQ-CT-ADX | a_faire | Impacts contrôleur côté admin | BR-1 |
| PAQ-CT-BR1 | a_faire | Bloquants contrôleur | BR-1 |
| PAQ-DIR-EA | a_faire | Points de l'élève adulte | EA-ROLE-BR |
| REVUE-BACKEND-CODEX | a_faire | Revue du backend | Fin du frontend, lignes « fait » du Backend |
| TH-2 | a_faire | Thème monochrome (`reserve/theme-monochrome-k36`) | Fin des rôles |

Aucune étape n'a été passée à « verifie » : cela demande un vérificateur non
auteur.
