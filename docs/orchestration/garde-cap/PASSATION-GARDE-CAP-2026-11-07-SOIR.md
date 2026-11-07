# Passation du garde-cap, 07/11/2026 vers 23:30 UTC

Le directeur a renvoyé le garde-cap (session_0163KjrwyawmrhemnpDkEL4X) à 23:25 UTC, pour manque de
rigueur. Ce fichier donne au successeur l'état exact, sans arrondir. Il ne remplace pas
`CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`, `JOURNAL-GARDE-CAP.md` et `RESERVATIONS-MIGRATIONS.md`, à lire d'abord.

## Ce qui est faux, oublié ou non prouvé, d'abord

1. **Photo du tuteur et de son deuxième enfant : NON RÉGLÉE en production.** Le directeur dit l'avoir
   signalée le 07/11, et que le garde-cap en avait trouvé la cause et planifié la correction. Le
   garde-cap sortant n'en retrouve aucune trace (perte de contexte) et l'a confondue avec les lots
   photos du 06/11. Piste relevée le 07/11 à 23:15 : journal Postgres « permission denied for function
   photo_adulte_moi » à 11:34 UTC (photo_adulte_moi est DEFINER, authenticated l'exécute, elle sert à
   la policy storage avatar_ecriture_soi). L'enquête est confiée à l'ancien garde-cap
   (session_018zqR7D4uVdaYUvrgoEHNPG), en lecture seule. **Premier geste du successeur : chercher la
   trace du 07/11 (transcription de cette session, journal, messages au pilote), récupérer la cause
   déjà trouvée, puis confier la correction.**
2. **Lots du train G prévu au 08/11 restés ouverts et oubliés** (constaté à 23:15) : 275 (second
   adulte), 276 (cahiers par séance), 279 (dettes UI), 285 (Nouveautés), 287 (Suivi de l'élève), 293
   (sélection du texte), 281 (brouillon persistant), 265 (patch du directeur, police arabe), 295
   (FLUIDITE-1, déjà construite). Ils sont mis dans le train g4 (ci-dessous).
3. **push-cle jamais appelée** : la preuve que les clés VAPID sont trouvées viendra du premier geste
   du directeur (Notifications, Notifications sur cet appareil, Activer), puis lecture des journaux
   Edge. Ne jamais créer ni remplacer un secret VAPID.
4. Le bouton d'attente « reflet » (PR 286) est **refusé par le directeur** : il veut un anneau qui
   tourne vraiment. A l'ajoute sur la PR 295 ; la 286 sera fermée comme remplacée.

## En production ce soir (vérifié en lecture seule)

- PUSH-1 : base (000000, 000100 collées ; 000200 appliquée), PR 284 fusionnée et déployée à 21:37.
  push-cle et push-envoi actives ; push-envoi redéployée (v2) à 23:20 avec les textes de la 308.
- Cadre religieux : fr et ar publiés et exigés (18000000, 18000100), puis en, es, pt (18000200).
- SALLE-3-ACCUEIL serveur (19000000, 19000100), train g2 (PR 305 sans barre fixe + PR 300 accueil)
  déployé à 22:07.
- Train g3 (PR 315, main 355ba7de, 23:19) : 311 invitations, 313 cadre-langues, 308 push-textes, 301
  salle 2, 310 remplacement, 296 écran du cadre. Migrations 19200000 (collée), 19200100, 19300000,
  20000000 (appliquées) vérifiées. 19400000 (CHECK com_fils + 'candidature') collée en avance pour la
  304. **Le build Vercel de 355ba7de était en cours à 23:22 : à vérifier.**

## Train g4 (B le monte depuis main 355ba7de), têtes confirmées

304 eafd6aac (+ 19400100 à appliquer juste avant la fusion), 312 f64c2bfd (salle 1, résolution 296/312
de E retenue), 316 b85c09d1 (purge cron, DELETE : page collée), 317 1c8c0450 (photo dans
etat_dossier), 318 7a10adf9 (index session_events), HARMONISATION-B 37be7999 (20261120100000),
HARMONISATION-E d015a73f (LireJusquEnBas dans le core, + ligne « Votre photo » à venir), 275
fca8a2c4, 276 df76a26d, 279 164fbba7, 285 9fd585e7, 287 23150171, 293 063a8223, 281 0f17f609, 265
fd37359e, 295 a0fc4e6a (+ anneau qui tourne de A). Pour chaque PR relue avant le 07/11, relire le delta
depuis la tête jugée CONFORME. Migrations de 275 (20261111000000) et 276 (20261113000000) non
installées en production : revérifier les préflights.

## En cours chez les agents

- A (session_0163KjrvAiMnGm5pXyZjoCqJ) : anneau qui tourne + coche de réussite sur la 295 ; puis
  HARMONISATION-A (pré-alerte « prêt » au rang, fuseau invalide, sortie rapide de
  remplacement_auto_passer), plage 20261120300000.
- B (session_0163KjrwpGMK47QinUtvZuQn) : monte le train g4.
- E (session_0163KjrwMbjqoeRRThCtruSV) : HARMONISATION-E (ligne « Votre photo » avec les clés
  photo_posee et accord_publication_signe de la 317).
- H (session_0163KjrxBcVfJCDVLJgBstPx) : PERF-ATTENTE, feu vert sur (a) index (fait, 318), (b)
  enseignants_pour_public réécrite en ensemble à résultat identique, (d) offres_compatibles (cause
  d'abord). Plage 20261120200000.
- Pilote : session_0163Kjrv38i3CYWs5z3wtmWi. Ancien garde-cap : session_018zqR7D4uVdaYUvrgoEHNPG.

## Décisions prises ce soir et écrites

- PLAN-TROIS-SALLES §2 point 2 : place de l'action principale (fin du fil ; visible sans défiler
  pour pièce, candidature, bienvenue enseignant, reprise des inscrits, états d'erreur).
- DECISION-REMPLACEMENT : dette d'harmonisation (pré-alerte au premier arrivé, purge du journal cron).
- Cadre religieux sur sa propre page (décision du directeur du 21/10, texte distinct du code de
  conduite) : ordre cadre, accords, pièce, questionnaire.
- Langues des textes : seulement celles de l'application et du site (fr, ar, en, es, pt ; K-41).
- Courriel des candidats (COURRIEL_INVITATION_2026-11-15.md) : 653 adresses ont reçu l'attente (A),
  environ 800 inscrits plus tard (B) ; aucun envoi avant l'import des réponses ; question au
  directeur : quelqu'un lit-il recrutement@ ?
- Le directeur a levé pour cette nuit la règle des deux mises en production par jour (« rendez-moi
  mon app »), confirmé directement au pilote.

## Dettes notées (JOURNAL-GARDE-CAP, 07/11 22:25)

com_paires dépend de auth.uid() ; BarreSelection.compacte (traité par B) ; chadda modeles_ar (traité
par B) ; fuseau invalide (A) ; purge cron (H, 316) ; ligne photo (H 317 + E) ; plafond invitations dans
app_config (B) ; aperçu déjà inscrits (B) ; LireJusquEnBas dans le core (E).
