# La fiche 0 de la salle (27/10/2026), relue contre `main` le 12/11/2026

## D'abord : ce qui est faux, manquant ou à décider

- **La fiche 0 n'est pas dans `main`.** Elle n'existe que sur la branche
  `claude/admiring-brown-r6ai72-fiche-0` (`d9c701667`, 27/10/2026), fichier
  `docs/current/maquettes/salle/FICHE-0-COMPORTEMENT-2026-10-27.md`. Elle a été écrite par le pilote
  avant les lots de la salle des 10 et 11 novembre, qui ont décidé autrement sur plusieurs lignes.
- **Je déconseille de la fusionner telle quelle** : quatre de ses lignes contredisent des décisions
  plus récentes du directeur (1, 11, 23, 27), et deux demandent une décision de droit (27, 30).
- **Trois points sont au directeur, et à lui seul** :
  1. **Ligne 11.** La fiche dit : « l'élève ne voit jamais la vidéo des autres élèves » (décision
     Q7, « décidée, jamais appliquée », motif : protection des mineurs). La salle d'aujourd'hui
     montre les visages de la classe en grille à l'élève aussi (`MODES-AFFICHAGE.md`, règle de
     l'ordre : « l'enseignant d'abord (chez l'élève), puis les élèves » ; D-028, D-031). Les deux
     ne peuvent pas être vrais ensemble. Je n'ai trouvé aucune décision datée qui annule Q7.
  2. **Ligne 27.** Enregistrer toutes les 30 s le réseau, le micro et la caméra de chacun, enfants
     compris : contraire à D-024 (rien n'est gardé pour un élève mineur sans l'accord de son
     parent ; `DROIT-RELEVE-QUALITE.md`). D-024 prime (garde-cap, 12/11).
  3. **Ligne 30.** Montrer au tuteur l'heure d'arrivée, de sortie et le réseau de l'enseignant :
     ce sont des données personnelles de l'enseignant. À lire dans les textes avant tout code. Je
     ne suis pas juriste et je ne tranche pas.
- **Limite de ce relevé.** Les lignes 25, 26 et 31 sont vérifiées dans le code cette nuit
  (fichier et ligne ci-dessous). Les autres sont rapportées à mon journal de la salle et à mes
  relevés du 11/11 ; je n'ai pas rouvert chaque écran cette nuit. Aucune ligne n'est « prouvée » :
  la preuve reste celle du directeur, en production.

## Légende

- **dans main** : la règle est tenue par le code de `main` (au sens « présent dans le code, testé
  localement »).
- **en partie** : une part est là, une part manque (dite).
- **remplacée** : une décision plus récente du directeur dit autre chose ; elle prime.
- **manque** : rien dans `main`.
- **à décider** : au directeur.

## A. L'enseignant quitte

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 1 | « Quitter » ouvre trois boutons : Terminer pour tous, Sortir, Annuler | **remplacée** : l'enseignant réduit la salle sans couper, ou quitte en connaissance de cause ; il n'existe pas de bouton « Terminer la séance pour tous » | D-010 (SORTIE-SALLE), `SORTIES-DE-LA-SALLE.md` |
| 2 | Terminer : chacun voit « La séance est terminée. » dans les 2 s | **en partie** : la fin vient du serveur (fin prévue et délai de grâce, ou départ de l'enseignant), pas d'un bouton ; l'élève voit « Séance terminée » et son heure | D-018 (FERMETURE-SALLE), D-035 |
| 3 | Sortir : la page se retire chez l'élève, scène d'attente | **en partie** : scène d'attente au départ de l'enseignant, micros des élèves fermés par le serveur ; je n'ai pas revérifié cette nuit que la page présentée se retire dans les 2 s | D-008, D-012, D-018 |
| 4 | Retour de l'enseignant : la page ne revient que s'il la présente de nouveau | non revérifié cette nuit | `SITUATIONS-DE-LA-SALLE.md` §4 |
| 5 | Limite : le serveur n'enregistre pas la fin | **caduque** : le serveur ferme la salle et dit pourquoi à qui revient | D-018, D-033 |

## B. Coupures de réseau

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 6 | L'enseignant perd le réseau : la page reste 120 s, bandeau | **en partie** : coupure dite à l'écran, reprise seule ; la durée exacte de 120 s et le texte du bandeau ne sont pas revérifiés | D-019 (SITUATIONS-GRAVES) |
| 7 | Retour dans les 120 s : page, tableau et traits rejoués | non revérifié cette nuit | `SITUATIONS-DE-LA-SALLE.md` §4 |
| 8 | L'élève perd le réseau : « Lien coupé », rejeu au retour | **en partie** : état du lien dit, reprise seule | D-017, D-019 |
| 9 | L'élève quitte et revient : même rejeu | **dans main** (« Retourner dans la salle ») | D-010 |

## C. La vignette et la scène

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 10 | La vignette de l'élève ne montre que l'enseignant, jamais un autre | **dans main** : jamais deux images de la même personne, la vignette est celle de l'enseignant | D-014, D-023, D-028 |
| 11 | L'élève ne voit jamais la vidéo des autres élèves | **tranchée le 12/11/2026, par le directeur** (D-040) : l'élève voit ses camarades dans la grille par leur photo et leur prénom ; la vidéo seulement de l'enseignant et de celui qui récite | `MODES-AFFICHAGE.md`, D-028, D-031, D-040 |
| 12 | L'enseignant voit ses élèves et leur état | **dans main** | D-017, D-030 |
| 13 | Le pointeur disparaît 2 s après le dernier mouvement | non revérifié cette nuit (le pointeur est redit toutes les 250 ms tant qu'il est posé) | D-014, `app_mouvement.dart` (`pointeurBattement`) |

## D. Tuteurs et visites

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 14 | Un tuteur en visite est invisible et muet | **dans main** (règle du serveur) | migration 0040 |
| 15 | Son enfant seul lit « Ton parent observe la séance. » | **dans main** (`salle.seance.tonParentObserve`, `votreParentObserve`) | textes de la salle |
| 16 | L'enseignant lit « Un parent observe. », et « {n} parents observent. » à plusieurs | **fait le 12/11 dans le lot PARENTS-PLURIEL** (D-036), sur la branche, pas encore dans `main` : « Un parent observe cette séance », « 2 parents observent cette séance », sans prénoms, en français et en arabe (`salle.seance.parentsObservent`). Non vérifié : la disparition de la ligne dans les 10 s après la dernière visite | `vue_seance.dart` (`texteNotice`), `depuis_salle.dart` |
| 17 | Le tuteur voit ce que voit son enfant, avec le temps de visite restant | non revérifié cette nuit ; D-026 note qu'il ne voit pas le support | D-026 |
| 18 | Contrôleur et direction invisibles, mention générale permanente | **dans main** (« Visite de contrôle possible. ») | `lib/CLAUDE.md`, ADR-011 |

## E. Enregistrement et états

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 19 | Aucun enregistrement, « Cours enregistré » n'apparaît nulle part | **dans main** | décision du 11/10 |
| 20 | « En ligne » dit l'état de sa propre connexion | **dans main**, un seul état (fin du doublon En ligne / En salle) | D-003 |

## F. Durées

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 21 | Les commandes se masquent après 3 s partout | **dans main** | `AppMouvement.masquageSalle` (3 s) |
| 22 | Les bandeaux durent tant que l'état dure, les avis 4 s | **en partie** : une seule place et quatre familles de messages ; les durées exactes ne sont pas revérifiées | D-007, `MESSAGES-DE-LA-SALLE.md` |
| 23 | Heure de fin dépassée : rien ne coupe la séance tout seul | **remplacée** : le chrono dit le dépassement, borné par un réglage de la direction, et le serveur ferme la salle après la fin prévue et son délai | D-003, D-018 |

## G. Preuve

| N° | La fiche dit | État au 12/11 | Où |
| --: | :-- | :-- | :-- |
| 24 | Chaque ligne est un test à deux appareils, puis le directeur | **en partie** : banc local à plusieurs participants (`tool/salle/`) ; pas un test par ligne de cette fiche | D-002 |

## H. Journal de présence et de qualité

| N° | La fiche dit | État au 12/11 | Où (vérifié cette nuit pour 25, 26, 31) |
| --: | :-- | :-- | :-- |
| 25 | Le serveur seul note arrivée, coupures, retours, sortie, à son heure | **dans main** : `enregistrer_webhook_livekit` écrit `session_events` avec l'heure du serveur ; une seule écriture de présence est confiée à l'utilisateur, dite comme telle | `supabase/migrations/0010_video_jeton_presence.sql` l. 403-458 et 469-481 ; `supabase/functions/livekit-webhook/index.ts` l. 106 |
| 26 | Retard et départ anticipé, même règle pour l'enseignant et chaque élève | **en partie** : le retard de l'élève existe (seuil de 5 minutes réglable, `etat_presence`, `retard_en_direct`) ; je n'ai trouvé ni « arrivée N min après le début » pour l'enseignant, ni le départ anticipé | `0010` l. 493-508 ; `20261122700000_lumiere_retard_eleve.sql` ; `lib/core/presence/retard_en_direct.dart` |
| 27 | Toutes les 30 s, réseau, micro et caméra de chacun au serveur | **remplacée par D-024** : envoi aux changements seulement (10 s au moins entre deux lignes), trois états de réseau, sans micro ni caméra, enseignant et élèves adultes seulement ; la migration `20261123700100` n'est pas installée | `lib/core/video/releve_qualite.dart` l. 48 ; `DROIT-RELEVE-QUALITE.md` |
| 28 | L'enseignant voit l'état de chacun en direct, l'élève le sien | **dans main** (non revérifié cette nuit) | D-017 |
| 29 | La direction lit la frise après la séance | **manque** : aucun écran de la direction pour le relevé | dette inscrite au registre |
| 30 | Le tuteur lit la frise de son enfant et le résumé de l'enseignant | **manque**, et **à décider** (données personnelles, voir en tête) | - |
| 31 | Une mesure manquante se lit « inconnu », jamais « absent » | **dans main** : « Présence pas encore connue » | `.claude/skills/mots-rewayah` (TXT-1) ; `lib/core/presence/vue_presence.dart` |
| 32 | Limite : 27, 29 et 30 demandent des migrations et des écrans | toujours vrai pour 29 et 30 | - |

## Ce que je propose

1. Ne pas fusionner la fiche 0. Ce relevé la remplace comme point d'entrée : il dit ce qui est tenu,
   ce qui a été décidé autrement, et ce qui manque.
2. Mettre devant le directeur, en une ligne chacun : la ligne 11 (les élèves se voient-ils entre
   eux ?), les lignes 29 et 30 (les écrans du journal
   de présence, et ce qu'un parent a le droit de lire sur un enseignant).
3. Aucun code pour 27, 29 et 30 avant sa décision (garde-cap, 12/11).
4. Revérifier sur le banc local, ligne par ligne, celles marquées « non revérifié cette nuit » (3,
   4, 6, 7, 13, 17, 22, 28), dans un passage à part.
