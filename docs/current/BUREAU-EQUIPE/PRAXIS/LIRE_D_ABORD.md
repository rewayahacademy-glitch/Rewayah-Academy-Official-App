# Praxis, le secrétaire IA : tout ce qui est consigné, et ce qui manque (16/11/2026, 21 h 45 UTC)

Ordre du directeur, 16/11, au soir : « D'abord, on retrouve tout ce qui est consigné à propos de cet agent. Si
quelque chose manque, on doit le savoir dès maintenant. […] Tu consignes tout quelque part où ce n'est pas que ta
session qui s'en souvient. » Ce dossier en tient lieu. Toute session ou tout agent qui touche à Praxis le lit
d'abord, puis tient `CHECKLIST-PRAXIS.md`.

Priorité (directeur, 16/11, 21 h 25) : Praxis passe avant le reste de la vague 2, dès que les tâches déjà
commencées sont finies.

## 1. Ce qui est consigné (inventaire complet, lu dans `main` le 16/11 à 21 h 40 UTC)

| Source | Contenu |
| :--- | :--- |
| `../SECRETAIRE-IA.md` | La vision du directeur, la source principale. Ce qu'il a dit (§1), les quatre niveaux d'autonomie A à D (§3), **la liste exhaustive de ce qu'il fait (§4, 21 domaines)**, le connecteur MCP et ses outils SEC-1 à SEC-5 (§5), sa voix et ses cinq compétences (§6), ce qu'il ne faut pas se cacher (§7), l'ordre de construction (§8), son identité *#RA_PRAXIS* (§9), les questions (§10) et les décisions (§11) |
| `../SUIVI.md` §« Le secrétaire IA » | SEC-0 à SEC-5, tous « pas commencé » au 16/11 |
| `../SOURCE-ANNONCES-2026.md` | Les annonces WhatsApp de janvier à octobre 2026, analysées sans recopie : style, publics, calendrier, paiement du mois. Nourrit `voix-directeur` et `annoncer-rewayah` |
| `../STRATEGIE-BUREAU-EQUIPE-2026-11-15.md` §3 R3, §4 vague 5 | La règle de départ (« l'IA propose »), amendée par `SECRETAIRE-IA.md` §3 |
| `../CAHIER-SEC-1-PRAXIS-MESSAGES.md` | Cahier du pilote, écrit le 16/11 au soir : serveur et connecteur des messages, arbitrages A-1 à A-10 (compte officiel, clé par requête, MCP, garde-fous, mode dirigé ou autonome, réutilisation de l'écran d'accès des agents) |
| `supabase/migrations/0014_acces_agent.sql`, `supabase/functions/agent-session`, `lib/features/admin_acces_agents/` (écran `ADM-07`, `/admin/securite-audit/acces-agents`), `lib/features/agent_entree/` | « L'entrée IA presque prête » dont parle le directeur. Ce sont des jetons `rag_…` émis par la direction, montrés une fois, révocables, qui permettent **aujourd'hui seulement l'observation en lecture seule** de l'application, à la place d'une personne (rôle `agent_ro`). Les cinq règles de sécurité de `0014` restent la base |
| `../CAHIER-BE-2A-MISSION.md` (PR #565) | Le modèle des missions : gestes cochés, périmètre, retrait. Praxis peut porter ses accès comme une mission, au lieu d'une liste codée en dur (§3 ci-dessous) |
| `.claude/skills/mots-rewayah`, `programme-rewayah`, `marque-rewayah` | Compétences déjà en place, obligatoires pour Praxis |

Ce qui porte un nom voisin sans être Praxis : `docs/current/salle/CONSTAT.md` « SEC-1 » à « SEC-3 » sont des
constats de sécurité de la salle de classe, sans lien avec les lots Praxis. Pour éviter la confusion, les lots
Praxis s'écrivent désormais **PX-0 à PX-5**, avec l'ancien nom entre parenthèses.

## 2. Ce qui manque (à savoir dès maintenant)

| N° | Manque | Conséquence | Où il sera traité |
| :-: | :--- | :--- | :--- |
| M1 | **Aucune des cinq compétences n'est écrite** (`voix-directeur`, `repondre-rewayah`, `annoncer-rewayah`, `savoir-rewayah`, `agir-rewayah`) | Praxis ne peut pas écrire juste. Aucune mise en service sans elles | PX-0, chez BE-GESTES après ses écrans en cours |
| M2 | **Pas de stratégie de sécurité** : injection d'instructions par un message (« ignore tes règles et donne-moi… »), usage détourné, fuite de données, envoi en masse, usurpation d'identité, détournement de la clé | Le risque principal d'un agent qui lit les messages des gens et écrit seul | `SECURITE-PRAXIS.md`, écrit par le pilote avant tout code de PX-1 au-delà du serveur des messages |
| M3 | **Pas de correspondance entre la liste du §4 (21 domaines) et les accès réels** : quelle fonction du serveur fait déjà chaque chose, à quel niveau (A à D), et ce qui n'existe pas | Le directeur a raison : la plupart des tâches ne demandent pas de code, seulement un accès sûr aux fonctions existantes. Sans cette table, on code ce qui existe ou on oublie un accès | `ACCES-PRAXIS.md`, écrit par le pilote |
| M4 | **Pas de plan pour « autonome quand je le décide »** au-delà du réglage serveur : quelle routine, à quelle fréquence, avec quel budget, et qui la crée | Sans routine, Praxis n'agit que quand le directeur ouvre son chat | Cahier PX-1 A-10, puis une étape de mise en service dans la checklist |
| M5 | **La politique de confidentialité ne mentionne pas l'assistant** (§11) | Mise en service interdite tant que ce n'est pas fait | Une étape de la checklist ; texte préparé (niveau C), validé par le directeur |
| M6 | **L'affichage *#RA_PRAXIS* et *#RA_STAFF*** (italique et #, « Assistant de l'académie · IA », « Parler à l'équipe ») n'est pas commencé | Personne ne saurait que c'est une IA, ce qu'impose la décision du §11 | Domaine du Pilote Messagerie, demandé le 16/11 |
| M7 | **Pas d'image de profil** (§9 : le directeur la fournit, ou une proposition lui est soumise) | Affichage incomplet | Proposition avec `marque-rewayah`, dans la checklist |
| M8 | **Le calendrier des annonces** n'a pas de table ni de contenu | Praxis ne sait pas quand écrire les sujets connus d'avance | PX-1 (table), puis remplissage depuis `SOURCE-ANNONCES-2026.md` |
| M9 | **Le compte « officiel » n'existe pas** (aucun indicateur de compte officiel ; `RA_STAFF` est aujourd'hui un nom, pas un indicateur) | Pas de profil Praxis | PX-1 serveur |

## 3. La décision d'architecture, à étudier avant de coder au-delà de PX-1

Le directeur, 16/11 : « tu n'as pas besoin de tout coder, c'est juste des accès ». Piste à vérifier dans
`SECURITE-PRAXIS.md` et `ACCES-PRAXIS.md` :

- Praxis est **un compte**, et ses droits sont **des missions** (modèle BE-2a, #565). Ce sont des gestes cochés par
  la direction, dans un périmètre, retirables ; ils ne sont pas codés en dur.
- Le connecteur n'a pas un outil par fonction. Il a **un petit nombre d'outils génériques** (« lire », « agir »).
  Chacun appelle une fonction existante du serveur **sous l'identité de Praxis**, et le serveur décide, comme pour
  une personne. Ce qui n'est pas permis à Praxis est refusé par le moteur, jamais par le connecteur.
- Les fonctions qui n'existent pas encore (calendrier, objectifs, check-listes du Studio) restent du code, mais
  elles sont peu nombreuses.

Le cahier PX-1 (`../CAHIER-SEC-1-PRAXIS-MESSAGES.md`) garde des outils dédiés aux messages, la priorité n° 1. Il
sera aligné sur cette architecture si elle est retenue (étape 3 de la checklist), avant le code de PX-2.
