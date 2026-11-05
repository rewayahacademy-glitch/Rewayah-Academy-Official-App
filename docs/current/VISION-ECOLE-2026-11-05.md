# Pourquoi l'application existe : une vraie école dans une application

Le directeur l'a dit le 05/11/2026, et il a dû le réexpliquer de nombreuses fois avant cette date. Ce fichier existe pour qu'il n'ait plus jamais à le refaire. Il est lu « avant tout » depuis `CLAUDE.md`. Toute session, tout agent et toute fiche partent de lui. Seule une décision datée du directeur le modifie.

## 1. Pourquoi ne pas rester sur Google Meet

L'académie existe depuis trois ans. Elle enseignait sur Google Meet. Meet coûte moins cher et ne demande aucune technique. En quittant Meet, le directeur a engagé beaucoup d'argent, de temps et d'effort, et pris tous les risques.

La raison : avec Meet, l'académie ne peut pas brancher **son système éducatif**. Suivre, analyser et mesurer y demande des dizaines d'outils, y compris l'IA. Tout y est manuel, parce que rien n'est relié.

## 2. La vision

**Une école réelle, dans une application.** Elle a deux faces.

- **Les parties visibles :**
  - les classes intégrées (la salle de cours) ;
  - la bibliothèque, avec toutes les ressources de l'académie, qu'on demande aujourd'hui au directeur une par une sur WhatsApp ;
  - le paiement ;
  - le suivi de présence, pour les personnes concernées ;
  - la communication.
- **Les systèmes qui gouvernent ces parties, comme dans une école physique :**
  - le programme ;
  - le suivi de chaque élève et de chaque classe ;
  - les évaluations ;
  - le remplacement ;
  - les règles de l'académie.

Tout est relié : ce qui se passe dans une partie nourrit les autres sans saisie en double.

## 3. La priorité n° 1 : le suivi pédagogique

Le suivi pédagogique est la priorité n° 1. Le directeur le nomme comme l'une des trois raisons de la création de l'application (05/11), et comme le socle de l'application. Il a été débattu pendant des jours entre le directeur, ChatGPT et Claude.

Le programme est écrit. Ses règles, ses étapes, ses durées et ses dates limites sont dans la compétence `.claude/skills/programme-rewayah` et dans `docs/current/REGISTRE-RECONCILIATION-2026-10-14.md`. Pour chaque élève et chaque classe, l'application doit savoir et montrer, à tout moment :

1. **Où il en est**, son niveau actuel : l'étape, et l'endroit exact où la classe s'est arrêtée.
2. **Où il va** : les objectifs à court et à moyen terme, et la date limite.
3. **Comment on le mesure** : les évaluations et les examens, et quand une classe ou un élève a besoin d'un examen.
4. **À quelle vitesse il avance**, comparée à la durée prévue.
5. **Ce qui le freine** : les difficultés, les points à renforcer, les absences.

Ces données servent cinq usages :
- **le remplaçant** sait tout de suite où continuer avec les élèves quand il remplace le titulaire ;
- **la direction** comprend et mesure les indicateurs de chaque classe et de chaque élève ;
- **les familles** savent où en est leur enfant, où il va et à quel rythme ;
- **l'élève**, dans la promesse de rigueur de l'académie, connaît son étape et sa date limite ;
- **l'enseignant** suit sa classe sans travail en plus.

## 4. Ce que cela impose à tout lot

- **Une donnée saisie doit servir.** Si la direction, la famille, le remplaçant ou l'enseignant ne s'en sert pas, on ne la demande pas.
- **L'enseignant ne fait pas de corvée.** Ce que l'application sait déjà (présence, durée, programme, séance précédente), elle le remplit elle-même. L'enseignant confirme ou corrige, en quelques secondes.
- **Le programme est la colonne vertébrale.** Le suivi, les évaluations, le remplacement, la bibliothèque et ce que voient les familles se rattachent aux étapes du programme, pas à du texte libre.
- **On critique la vision du directeur quand elle peut être meilleure** (consigne V2 de `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`). Le 05/11, il a constaté que Claude avait accepté sans rien dire sa vision du cahier, alors que c'est le point le plus important.

## 5. Le cahier de l'enseignant, état au 05/11/2026

**Pourquoi le directeur l'a voulu :**
- d'abord, pour que le remplaçant sache automatiquement où continuer ;
- ensuite, pour mesurer l'avancement sur le programme : où en est la classe par rapport aux objectifs, et si elle a besoin d'un examen.

**Son verdict :** le cahier actuel est une pure corvée pour l'enseignant, et ses données servent peu à la direction. Il demande une étude : comment font les références du marché, comment soulager l'enseignant, et comment permettre aux familles, à la direction et à l'enseignant de suivre l'avancement (le point de départ, la vitesse, les difficultés).

L'étude est lancée le 05/11 (voir `docs/current/RELEVES-2026-11-02/PLAN-LOTS.md` §7, rang 22 d). Aucune modification du cahier n'est faite avant ses conclusions.
