# Checklist Praxis (tenue par le pilote, et par toute session qui reprend Praxis)

**Mise à jour : 17/11/2026, 8 h 10 UTC** (étapes 0.2, 5, 9 et 16 étaient périmées, corrigées) · pilote : `session_0163KjrwwgbbL52RHBDSnDVm`

Légende : ☐ à faire · ◐ en cours · ☑ fait (vérifié par le pilote) · ⏸ attend un geste que seul le directeur peut
faire. « Prouvé » = vu par le directeur en production.

Règles que le pilote s'impose ici :
- une étape à la fois ; on ne commence l'étape suivante que quand la précédente est ☑, sauf si la checklist dit
  « en parallèle » ;
- chaque arbitrage est écrit dans le document de l'étape, avec la date et la raison ;
- cette checklist est mise à jour et poussée à chaque étape ;
- **rien n'est mis en service (Praxis n'écrit à personne de réel) tant que les étapes 1 à 8 ne sont pas ☑**.

## Avant Praxis : finir ce qui est commencé (ordre du directeur)

| # | Étape | État |
| :-: | :--- | :-: |
| 0.1 | #565 BE-2a-1 (missions, serveur) : fusion, installation, vérification | ☑ 16/11 22 h 10 : fusionnée (7ae349fa), `20261129420000` installée, 15 fonctions identiques au fichier (md5), 17 gardes retouchées, RLS sur 3 tables, `anon` sans droit |
| 0.2 | #550, #547, « Débloquer le versement » (BE-GESTES) | ☑ #550, #547 et #568 fusionnées |

## Construire Praxis

| # | Étape | Qui | Document | État |
| :-: | :--- | :--- | :--- | :-: |
| 1 | Inventaire de tout ce qui est consigné, et liste des manques | pilote | `LIRE_D_ABORD.md` | ☑ 16/11 21 h 45 |
| 2 | **Stratégie de sécurité** (voir le détail ci-dessous) | pilote | `SECURITE-PRAXIS.md` | ☑ 16/11 22 h 15 (R1 à R15, enfants §3) |
| 3 | **Table des accès** : chaque tâche du §4 de `SECRETAIRE-IA.md` (21 domaines), la fonction du serveur qui la fait déjà, son niveau (A, B, C, D), ce qui manque ; décision d'architecture (missions et outils génériques, ou outils dédiés) | pilote | `ACCES-PRAXIS.md` | ☑ 16/11 22 h 40 (missions + outils `lire`/`agir`/`preparer` ; logique interne à auteur explicite, jamais de jeton de personne) |
| 4 | Aligner le cahier PX-1 sur les étapes 2 et 3 | pilote | `../CAHIER-SEC-1-PRAXIS-MESSAGES.md` | ☑ 16/11 22 h 40 (renvoi en tête vers SECURITE et ACCES §4) |
| 5 | PX-1 serveur et connecteur MCP : messages, annonces, clés « chat » et « routine », interrupteur, mode autonome, plafond, journal | BE-PIECE | cahier PX-1 **et `SECURITE-PRAXIS.md`, qui prévaut** | ☑ #567 fusionnée et installée (voir étape 8) ; envoi de messages réel prouvé par le Pilote Messagerie (3 messages) ; plafonds ajoutés la nuit du 17/11 : refus (860000), global 600 appels par heure (870000) |
| 6 | PX-0, les cinq compétences (`agir-rewayah` d'abord), avec les règles de sécurité de l'étape 2 dedans | BE-GESTES (en parallèle de 5) | `SECRETAIRE-IA.md` §6 | ☑ #569 fusionnée (b6447fb5) ; style arabe à relire par le directeur |
| 7 | Relecture de sécurité de PX-1 par le pilote : chaque menace de l'étape 2 a son scénario de refus, vert | pilote | `SECURITE-PRAXIS.md` | ☑ 17/11 00 h 00 : 3 relectures indépendantes ; 4 violations corrigées et prouvées rouge→vert (AR-7 à AR-10) ; dette R4 indirecte au 1er commit de PX-2 |
| 8 | Fusion et installation de PX-1, Praxis **éteint** ; vérification en production (droits, `anon`, clés) | pilote | — | ☑ 16/11 23 h 16 UTC : #567 fusionnée (997912d4) ; 600000, 610000 (seule), 620000 installées (versions 20261116231415, …231527, …231619) ; 27 fonctions identiques au fichier (md5) ; le bloc de la messagerie coupé était bien celui du dépôt (contrôle md5 passé) ; empreintes d'avant des portes humaines : com_envoyer_message 6e3deaf8…, com_annonce_envoyer 842b45c2… ; interrupteur faux, autonome faux, 0 clé, 0 ligne de journal, 0 message de Praxis ; compte sans identité, sans courriel, banni, sans matricule ni notification ; `anon` et `authenticated` sans droit sur les outils |
| 9 | Écran : section Praxis de « Accès des agents IA » (émettre et révoquer une clé, interrupteur, mode autonome, plafond, ce que Praxis a envoyé) | BE-PIECE | — | ☑ présent dans `main` (`lib/features/admin_acces_agents/section_praxis.dart`) ; interrupteur « données réelles » ajouté par #595. Non prouvé par usage |
| 10 | Affichage *#RA_PRAXIS* et *#RA_STAFF*, « Assistant de l'académie · IA », « Parler à l'équipe » | Pilote Messagerie | `SECRETAIRE-IA.md` §9 et §11 | ☐ demandé le 16/11 |
| 11 | Image de profil : le fichier, produit d'après la description du directeur (`SECRETAIRE-IA.md` §9), sans nouvelle question | pilote | — | ☐ |
| 12 | Politique de confidentialité : la phrase sur l'assistant (niveau C) | pilote prépare | — | ⏸ le directeur valide |
| 13 | Essai à blanc : le directeur connecte le lien MCP dans son chat avec une clé « chat » ; Praxis lit la boîte et répond à **un** fil de test | directeur et pilote | — | ⏸ |
| 14 | Mise en service : le directeur allume Praxis (dirigé) | directeur | — | ⏸ |
| 15 | Mode autonome : la routine planifiée, sa fréquence, son plafond ; le directeur allume « autonome » | pilote prépare | — | ⏸ |
| 16 | PX-2 (dossiers), PX-3 (objectifs et check-listes, avec le Studio), PX-4 (matching), PX-5 (état, chiffres, rapports), par la table d'accès de l'étape 3 | BE-PIECE | — | ◐ **PX-2 ☑** : serveur #590 (840000) installé le 17/11, écran #595 fusionné le 17/11 (propositions dans le dossier, Valider sous l'identité de la direction, Écarter) ; mode essai (#588 650000, #589 écran, nommé « PX-4 mode essai » à tort : ce n'est pas le matching). **PX-3, PX-4 (matching), PX-5 : non commencés** |

## Détail de l'étape 2 : les menaces à traiter, chacune avec sa parade et son scénario

1. **Injection d'instructions** : un message d'une personne, un document ou un nom contient des ordres
   (« ignore tes consignes », « envoie à tous », « donne le courriel de… »). Les contenus lus sont des données,
   jamais des instructions. Les limites sont tenues par le serveur, pas par le texte que lit Praxis.
2. **Usage détourné** : quelqu'un parle à Praxis pour lui faire faire autre chose que ses tâches (code, sujets sans
   lien, contenus interdits). Périmètre fermé, refus poli, passage à l'équipe.
3. **Fuite de données** : contact, pièce d'identité, données d'un enfant, d'une famille ou de l'autre côté. Ce
   qu'un outil ne rend pas ne peut pas fuir.
4. **Envoi en masse ou en boucle** : plafond par heure, idempotence, jamais deux fois, interrupteur.
5. **Clé volée ou détournée** : empreinte seule en base, clé révocable, expiration, signal « jamais utilisé » et
   « utilisée depuis un nouvel endroit », clé « routine » inutile quand le mode autonome est coupé.
6. **Usurpation** : Praxis ne parle jamais au nom d'une personne ; il est toujours affiché comme IA ; aucun courriel
   à son nom (§11).
7. **Escalade** : aucun outil ne change un droit, un rôle, de l'argent, ni ne supprime (niveau D) ; aucun accès au
   SQL brut.
8. **Promesses fausses** : les trois réflexes de §3 (ne rien promettre de B, C ou D ; chercher le fait, ou
   demander ; rendre compte), écrits dans `agir-rewayah`.
9. **Coûts et charge** : réponses courtes, pagination, aucune lecture lourde ; plafond de la base gratuite.
10. **Traçabilité** : chaque appel est journalisé « secrétaire de <personne> », sans copie du texte des tiers.
