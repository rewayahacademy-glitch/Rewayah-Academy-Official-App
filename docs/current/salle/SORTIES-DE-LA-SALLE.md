# Sortir de la salle sans couper la séance (lot SORTIE-SALLE, 11/11/2026)

Demande du directeur (11/11/2026) : « permettre à l'enseignant de sortir sans couper », et gérer
« toutes les situations avant d'entrer à la salle et pendant et après la fin du cours et après
qu'on ait coupé, après qu'on ait pris une pause ».

**Ce qui n'est pas prouvé.** Tout ce qui suit est lu dans le code et vérifié par des tests
locaux. Rien n'a été essayé en production ni sur le banc. La question du navigateur à la
fermeture de l'onglet ne se teste pas en local (seule la logique d'armement l'est), et elle
n'existe pas sur Safari d'iPhone et d'iPad.

Les quatre rôles qui atteignent `/salle` : **celui qui conduit** (l'enseignant), **l'élève**
(interface guidée comprise, et l'adulte qui suit ses cours), **le tuteur** qui observe (il entre
par `push`), **le contrôleur**. « L'appel est tenu » veut dire : la salle l'a confié au
contrôleur de session (`controleurSessionProvider`), il continue hors de l'écran.

## 1. Avant (relevé du code au 11/11/2026)

| Façon de sortir | Ce qui se passait | L'appel continue ? | Prévenu avant ? | Revenir d'un appui ? | Ce que voient les autres | Défaut |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| Bouton Quitter (les 4 rôles, téléphone et ordinateur) | Question `confirmerQuitterSeance`, puis annonce au serveur et déconnexion (`salle_page.dart:834`, `_quitterAppel` l.514) | Non | Oui, mais la conséquence de l'enseignant disait seulement « Vous passerez ensuite au cahier » | Enseignant : « Retourner dans la salle » sur l'écran de fin ; élève : « Revenir » sur l'écran de sortie | Le départ est inscrit (`quitter_salle`) | **D1** : l'enseignant n'apprenait pas que ses élèves restaient sans lui (K-58). **D2** : aucun choix « garder la classe » proposé (`dock_seance.dart:73`) |
| Réduire la salle (garder l'appel) | N'existait que par la flèche Retour du navigateur ou du téléphone. Dans `/salle`, aucune commande visible : `TelephonePleinEcran` et `SalleOrdinateur` ne rendent jamais `onRetour` ; le chevron « Retour » n'existe que dans l'ancien en-tête (`chrome_seance.dart:176`), absent de `/salle` | Oui (si tenu) | Non : rien ne dit que la séance continue | Oui, barre « Séance toujours en direct », « Retourner dans la salle » | Rien ne change | **D3** : le geste qui garde la classe était invisible ; « Retour » ne disait pas que l'appel continue |
| Flèche Retour du navigateur | La page se démonte ; appel tenu : il continue (`salle_page.dart:537`), la barre apparaît partout | Oui si tenu ; sinon (préparation, entrée en cours, impasse) rien n'était encore ouvert | Non | Oui (barre) | Rien | Correct, mais personne ne le savait (D3) |
| Geste Retour d'Android (application installée) | La salle, entrée par `go`, est seule dans la pile : le retour fermait l'application | **Non** (application fermée) | Non | Non | « déconnecté » | **D4** : coupure par surprise. Le tuteur, entré par `push`, n'était pas touché |
| Aller sur un autre écran de l'application | `/salle` est hors coquille, sans menu : seul chemin, le retour | comme le retour | | | | |
| Fermer ou recharger l'onglet | L'onglet se ferme, l'appel tombe sans annonce ; au rechargement, le billet d'entrée (passé hors adresse, ADR-005) est perdu et le routeur renvoie ailleurs | **Non** | **Non** | Par le bouton de la séance (CTA-FIN-1), pas d'un appui | Une déconnexion, pas une sortie | **D5** : coupure par surprise, sans question |
| Fin prévue de la séance | Le chrono passe en dépassement ; rien ne ferme la salle (SEC-1 du constat) | Oui | Chrono, signal chez celui qui conduit | | | Hors de ce lot : SEC-1 |
| « Terminer la séance » | N'existe pas (jamais « Terminer pour tous », `dock_seance.dart`) | | | | | À décider (Q2) |
| Séance close par le serveur, retrait, lien perdu pour de bon | Le contrôleur de session libère le micro (`_fermerApresFin`), la barre disparaît | Non | Écran de fin | | | Rien |
| Pause | L'appel continue pendant la pause ; aucune sortie différente | Oui | Chrono | | | Rien |
| Contrôleur | Le bouton Quitter du dock pose la question, alors que CTR-02 dit « sans confirmation » | | | | | **D6**, à décider (Q3) |

## 2. Après (ce qui a changé)

1. **Deux gestes nommés, jamais confondus.** « Réduire la salle » (la séance continue, on entend
   toujours la classe, « Retourner dans la salle » ramène) et « Quitter la séance » (on sort de
   l'appel).
   - Ordinateur, barre de l'enseignant : une tuile **« Réduire »** juste avant Quitter
     (`BoutonAppel(nom:)`, donc `TuileCommandeSalle`), lue « Réduire la salle : la séance continue
     et vous entendez toujours la classe ».
   - Ordinateur et tablette, pilule de l'élève : le même bouton, icône seule, nom en infobulle.
   - **Téléphone : la pilule micro · caméra · quitter ne grossit pas** (fiche 1). Le geste y est
     proposé par la question de Quitter (point 2) et par le retour du téléphone (point 3). Le
     tiroir « Commandes » n'a plus d'onglet « Séance » et son fichier n'est pas dans ce lot (Q1).
   - Interface guidée : ni la commande ni le choix « Réduire » (un enfant seul ne doit pas laisser
     l'appel ouvert sans le voir) ; sa sortie reste la question simple. Voir Q4.
   - Le geste n'apparaît **que si l'appel est tenu** : `/salle` ne donne `onRetour` que dans ce
     cas (`salle_page.dart`, `_tenu ? _quitterLEcran : null`). Sinon, quitter l'écran couperait
     l'appel, et le geste n'est pas proposé (aucun bouton qui ne peut pas aboutir).
2. **La question de sortie dit la conséquence avant le choix (K-58).**
   - Celui qui conduit, appel tenu : « Si vous quittez, vos élèves restent dans la salle sans vous.
     Réduisez plutôt la salle : la classe continue de vous entendre, et vous revenez d'un appui
     sur « Retourner dans la salle ». » Trois actions : **Réduire la salle** (seul bouton plein,
     K-56), **Quitter et ouvrir le cahier de transmission** (alerte douce), **Rester**. Au clavier,
     l'ordre est Réduire, Rester, Quitter ; au pouce, Rester est en bas.
   - Celui qui conduit, appel non tenu : pas de « Réduire » ; « Si vous quittez, vos élèves
     restent dans la salle sans vous. Vous passerez ensuite au cahier de transmission. »
   - L'élève, appel tenu : « Vous sortez de l'appel. Vous pouvez revenir tant que la séance est
     ouverte. Pour entendre la classe sur un autre écran, réduisez plutôt la salle. » Sans appel
     tenu : la phrase d'avant, « Vous pourrez revenir si la séance est encore ouverte. »
3. **Le retour du téléphone ne coupe plus l'appel par surprise.** Quand la salle est seule dans la
   pile et que l'appel est tenu, le retour réduit la salle (même chemin que « Réduire »,
   `PopScope` dans `salle_page.dart`) au lieu de fermer l'application. Le retour du navigateur
   change d'adresse sans passer par là : la page se démonte et l'appel tenu continue, comme avant.
4. **Fermer ou recharger l'onglet** pendant un appel tenu : le navigateur pose **sa** question
   (`beforeunload`, `lib/core/video/garde_fermeture*.dart`, import conditionnel web / natif). La
   garde suit le contrôleur de session, pas l'écran : elle reste armée salle réduite, et tombe à
   la vraie sortie, à la fin par le serveur ou au lien perdu pour de bon.
5. **Après la sortie** : vérifié par lecture, non modifié. Enseignant : écran de fin (CLV-10)
   avec « Retourner dans la salle » tant que la séance n'est pas close, puis le cahier. Élève :
   « Vous avez quitté la séance » avec « Revenir ». Tuteur : retour à l'accueil de son rôle, d'où
   le bouton de la séance (CTA-FIN-1) ramène. Salle réduite : la barre « Séance toujours en direct »
   sur tous les écrans.

Tests : `test/features/salle_seance/sortie_salle_test.dart` (commande, question, garde, 320 et
1440, clair et sombre), `test/features/salle_test.dart` (groupe « Salle en groupe », deux tests
SORTIE-SALLE : retour du téléphone, Réduire puis vraie sortie). Le test du retour du téléphone
échoue sans le `PopScope` (vérifié). Captures : `docs/current/captures/E2E/sortie-salle/`.

## 3. À décider par le directeur

| # | Question | Recommandation |
| :-- | :-- | :-- |
| Q1 | Au téléphone, l'enseignant doit-il avoir « Réduire la salle » ailleurs que dans la question de Quitter ? | Oui : une ligne « Réduire la salle » dans le tiroir « Commandes » (onglet Outils), sans toucher la pilule. Petit lot dans `telephone_enseignant.dart` |
| Q2 | Faut-il un « Terminer la séance pour tous » chez celui qui conduit ? | Oui, mais avec la fermeture de la salle par le serveur (SEC-1) : sans elle, le bouton promettrait une fin que le serveur ne fait pas |
| Q3 | Le contrôleur passe par la même question (CTR-02 disait « sans confirmation ») | Garder la question : elle lui propose aussi de réduire la salle et ne coûte qu'un appui |
| Q4 | L'élève en interface guidée doit-il voir « Réduire la salle » ? | Non pour un enfant seul (appliqué ainsi dans ce lot, à confirmer) : il garde « Quitter » seul ; un retour du navigateur garde toujours l'appel et la barre |
| Q5 | Après un rechargement, faut-il revenir directement dans la salle ? | Non (ADR-005 : le billet ne passe pas par l'adresse). La question du navigateur suffit ; le bouton de la séance ramène |
| Q6 | iPhone et iPad (Safari) ne posent pas la question à la fermeture de l'onglet | Accepter et le dire dans l'aide : la barre « Séance toujours en direct » reste le filet |
