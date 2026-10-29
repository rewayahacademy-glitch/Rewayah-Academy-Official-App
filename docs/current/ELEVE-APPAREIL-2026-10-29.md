# Appareil de l'élève : « l'élève ne voit rien », constat du 29/10/2026

Branche `claude/admiring-brown-r6ai72-eleve-appareil`, depuis `origin/main` (0278546). **Aucun code changé : la cause n'est pas trouvée.**

## Ce qui est bloqué ou inconnu (à lire d'abord)

1. La source citée par le pilote, `docs/orchestration/PASSATION-SALLE-2026-10-25.md` « Étape 2 », n'existe pas : ce fichier (49 lignes) ne parle que des lots 1 et 2 de la salle, sur `main` comme sur toutes les branches `claude/*` poussées. Je n'ai donc pas le constat du directeur : ce qu'il voit à l'écran, sur quel appareil, avec quel navigateur, à quelle heure.
2. Je n'ai pas pu reproduire : aucun compte de staging (ni tuteur pour créer un code, ni appareil d'élève), et la production est en lecture seule.

## Ce qui est prouvé, en production, en lecture seule

Élève concerné : le seul profil élève qui a des codes d'appairage (`f7a96be7-…`, rôle `student`, compte `active`).

| Point | Résultat |
| :-- | :-- |
| Dernier appairage | code créé le 27/10 à 16:15:24, consommé à 16:15:37, appareil utilisé à 16:15:57 : la session s'est ouverte |
| Classe au moment de l'appairage | rejointe le 27/10 à 16:14:40 (`2d5878ce`), fermée le 28/10 à 18:33 « Classe créée par erreur » |
| Classe aujourd'hui | `96cd399b`, rejointe le 28/10 à 18:35, 4 séances planifiées, la prochaine le 04/11 à 18:00 UTC, l'élève inscrit à chacune |
| Lecture de l'accueil, simulée avec le jeton de l'élève (transaction en lecture seule annulée) | `mes_seances_v` : 46 séances ; `groupe_membres` ouvert : 1 ; `mes_groupes_famille_v` : 1 ; `student_profiles` : 1 |
| Crochet du jeton (`custom_access_token_hook`) | pose bien `role` et `household_id` pour un élève |

Conclusion : **le serveur sert à l'élève sa classe et ses séances.** Le défaut, s'il existe encore, est côté application (parcours après le code personnel, routage, Interface guidée) ou dans un moment précis qui n'est pas dans ces lectures.

## Une anomalie trouvée en chemin (pas la cause, à décider)

L'élève reçoit aussi **36 séances annulées de 9 classes fermées** (les séances futures d'une classe fermée gardent l'élève dans `session_participants`). L'accueil standard les écarte (`prochainCours` ignore les annulées), donc l'écran n'en souffre pas aujourd'hui ; mais une séance annulée d'une classe fermée, le jour même, s'afficherait « Annulée » (`seanceAnnuleeDuJour`). Correction côté serveur (fermeture de classe : retirer l'élève des séances futures, ou filtrer la vue sur les appartenances ouvertes) : zone `supabase/` interdite aux agents, à décider par le directeur.

## Ce qu'il faut pour avancer

L'un des deux :

- le constat du directeur : une capture de l'écran de l'élève et les gestes faits juste avant (scanner ou code tapé, code personnel choisi ou non) ;
- ou un compte tuteur de staging et l'adresse d'aperçu, pour rejouer l'appairage dans un navigateur.
