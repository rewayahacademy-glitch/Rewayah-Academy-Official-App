# Passation du pilote, 26/10/2026, 17:00 UTC

Écrite par la session pilote `session_01SXpeWERDnPagH6VS1knQHc` à la demande du directeur, qui
met fin à cette session après la PR B. La passation du 25/10
(`docs/orchestration/PASSATION-PILOTE-2026-10-25.md`) reste vraie pour les rôles, les règles et
les outils ; ce fichier ne redit que ce qui a changé et ce qui est en cours. Vérité d'abord : rien
de ce qui est écrit « prêt » ici n'est prouvé en production tant que le directeur ne l'a pas dit.

## 0. L'état vrai, en cinq phrases

1. K1, K2, K3 sont vrais en production ; K4 (une séance en visio) marche mais la salle livrée
   aujourd'hui (PR 61) ne satisfait pas le directeur : « c'est exactement comme avant » (§3).
2. La production est `main` = 7816597 (fusion de la PR 61 à 13:39 UTC, déploiement vert à 13:46).
3. La branche de travail `claude/admiring-brown-r6ai72` porte la PR B (salle téléphone et tablette)
   en cours de finition par le worker ; tête poussée 6240ed1, corrections de la tâche 17 à venir.
4. Le directeur a jugé la journée mauvaise : trois PR fusionnées (59, 60, 61), aucune ne lui a
   donné « quelque chose qui marche vraiment ». Il ne veut plus de nouveau périmètre : finir la
   PR B telle qu'elle était, et s'arrêter.
5. Le bandeau « nouvelle version » ne peut pas s'afficher tant que le workflow ne passe pas un
   numéro de build (§5, point 1) : sa ligne est sur une branche à part, pas sur `main`.

## 1. Les sessions

- **Pilote** : cette session, à archiver après la fusion de la PR B.
- **Worker salle** : `session_011CALX9teGtqrquq7vN8ZpH` (Opus 5.5, auto). Il rend compte par
  `send_message` à l'identifiant du pilote ; lui donner le nouvel identifiant dès le premier
  message. Il ne pousse que sur « pousse », jamais pendant qu'une PR de la branche a sa CI en
  cours. Il garde en local son dépôt sur la branche `salle-composition`, suivie par
  `claude/admiring-brown-r6ai72`. Ses tâches sont numérotées ; la dernière donnée est la 17, la
  18 a été annulée (ordre du directeur, 26/10, 16:45 UTC) : ne pas la reprendre sans son accord.
- Règle apprise ce jour : les tests `flutter test` se lancent au premier plan dans le tour, jamais
  en tâche de fond (le worker attend sinon une notification qui ne vient pas).

## 2. Ce qui a été fusionné aujourd'hui (26/10)

| PR | Contenu | Déployé | Vérifié par le directeur |
| :--- | :--- | :--- | :--- |
| 59 | Connexion (deux volets, animation de la porte), fiche de séance de l'enseignant lue par sa propre fiche | oui | connexion : oui, téléphone et ordinateur |
| 60 | Démarrage animé, contrôle de version (`version.json`, bandeau « Recharger »), annuaire de séance (noms, Sayyid/Sayyida, photo de l'enseignant), réglages réseau | oui | noms : oui ; bandeau : non (§5) ; latence : non résolue |
| 61 | Salle sur ordinateur : trois panneaux, barre sombre nommée, barre d'outils, dix couleurs, Rétablir, focus, 720p par couches | oui | testé sur iPad : refusé (§3) |

## 3. Ce que le directeur a vu en production (26/10, 18:50 heure locale) et les causes

- **Panneau Commandes impossible à fermer** : il n'a aucun bouton Fermer ; seul « Plus » le
  referme. La tuile Bibliothèque ne le remplace pas (défaut trouvé par la revue de la PR 61,
  corrigé en local par le worker, commit 6a19772, dans la PR B).
- **iPad en portrait (≈810-834 points) : ancienne composition**, avec la boîte Commandes flottante
  et l'ancien panneau d'outils. Le seuil est 840 : la PR B (téléphone et tablette) s'y applique.
- **iPad en paysage : les panneaux de 300 et 320 mangent la page** (≈340 points restent à 1024).
  Non traité ; demande du directeur : un seul panneau de côté à la fois et des panneaux plus
  étroits sous 1200 (annulé avec la tâche 18 ; à reprendre sur son ordre).
- **Coran : aucun moyen d'aller à une page** (seulement les flèches) et la croix ⊠ pour fermer le
  support n'est pas comprise. Non traité (tâche 18 annulée).
- **Tout reste après avoir quitté** : traits et marqueurs sont enregistrés dans la base pour la
  séance (`annotation_trait`, `annotation_marqueur`, adaptateur
  `lib/core/tc_outils/annotations_supabase.dart`) et rechargés au retour ; personne ne les efface
  quand l'enseignant quitte. Le directeur veut le comportement de Google Meet : revenir dans la
  séance repart propre. Non traité (tâche 18 annulée) ; décision à lui faire confirmer avant de
  coder : « Quitter par l'enseignant efface le tableau pour tous ».
- **Barre du bas inversée** (tuile Élèves à droite, Bibliothèque à gauche) : la maquette du
  directeur les plaçait ainsi, il a tranché le contraire (« la tuile du côté de son panneau »).
  Corrigé en local, commit 8a25811, dans la PR B.
- **Latence du son et de la vidéo** : relais TURN des deux appareils vers l'Allemagne depuis
  l'Arabie saoudite (Wi-Fi de l'université). Non résolu ; le directeur reporte les tests 4G et ne
  paie pas LiveKit avant le début des cours. Les élèves seront en Europe et en Amérique du Nord.

## 4. La PR B (branche `claude/admiring-brown-r6ai72`, à ouvrir par le directeur)

Contenu au moment de cette passation (commits au-dessus de `main`) :

- 8a25811 barre ordinateur : tuile Élèves à gauche, Bibliothèque à droite ;
- 6a19772 Bibliothèque demandée, les Commandes se ferment (revue PR 61) ;
- 973bfbd salle téléphone : capsule vidéo au toucher, tiroir des Commandes à trois onglets
  (Support, Outils, Séance), élèves en feuille avec les mêmes cartes que l'ordinateur ;
- 6240ed1 plan de la salle : ordre des tuiles ;
- tâche 17 (en cours) : onglet Séance sur une seule rangée, pastille du bouton Élèves au nombre
  d'élèves, capture avec Écrire retenu, **pilule du bas cachée quand le tiroir est ouvert** (la
  maquette du directeur ne montre pas de pilule sous le tiroir ; ma règle du plan était fausse).

Écarts assumés, écrits dans `docs/current/maquettes/salle/UX_REVIEW_COMPOSITION.md` (section PR B) :
pas de puce « Commandes » au-dessus de la pilule ; le tableau du téléphone vit dans l'onglet Outils
(trois touchers au lieu d'un : à soumettre au directeur) ; capsule absente sur une page illisible.

Lien pour ouvrir la PR :
`https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/compare/main...claude/admiring-brown-r6ai72?expand=1`

Titre proposé : « Salle téléphone et tablette : capsule au toucher, tiroir des Commandes, élèves en
feuille ; barre et Commandes de l'ordinateur corrigées ». Le corps dit d'abord les limites (§3,
rien de prouvé, couleurs franches perdues au rechargement, élèves en initiales), puis le contenu,
puis la chaîne locale. **Avant la fusion, le directeur teste l'adresse d'aperçu Vercel que le robot
écrit en commentaire de la PR** (staging, aucun effet sur la production) : c'est la règle demandée
le 26/10 pour ne plus découvrir les défauts en production.

## 5. Ce qui reste au directeur, dans l'ordre

1. **Numéro de build dans le workflow** (`.github/workflows/flutter-deploy.yml`, ligne 127, après
   `--release \`, ajouter `--build-number=${{ github.run_number }} \`). Il l'a collé sur la branche
   `rewayahacademy-glitch-patch-1` (commit a7d2453, correct), pas sur `main`. Deux voies : ouvrir
   une PR depuis cette branche et la fusionner, ou refaire l'édition sur `main` avec « Commit
   directly to the main branch ». Sans cette ligne, le bandeau « Recharger » ne s'affiche jamais.
2. **Actualiser depuis l'application** : il refuse tout bouton (« jamais de la vie »). Il attend le
   geste « tirer vers le bas » comme dans son application PISI. Flutter capte les gestes du
   navigateur : le geste doit être fait dans l'application (un tirage depuis le haut qui recharge
   l'adresse, `lib/core/agent/recharger_adresse.dart`). Non commencé.
3. **Lenteur au chargement** : non corrigée. Restent les trois polices arabes du paquet de départ
   (0,7 Mo, `pubspec.yaml`, à retirer par lui, puis chargement différé côté code) et la version de
   Flutter non épinglée dans le workflow. Audit : `docs/current/DEMARRAGE-2026-10-25.md`.
4. **Page à coller** (hors zones des agents), état au 26/10 : migration « séance en cours reste
   visible » (brouillon chez le worker, 0 DELETE/DROP/TRUNCATE) ; durée du jeton de salle
   (`video_config.token_ttl_seconds` 900 → durée de séance + 30 min) ; clé de photo des élèves
   exposée au roster lu par l'enseignant (`student_profiles.avatar_storage_key`) ; `vercel.json`
   pour l'ancien service worker ; lecture du tableau de bord LiveKit (région, relais). Chaque
   texte doit être donné par une page privée (`tool/page_migrations/generer.py`), jamais par un
   paragraphe de conversation : le directeur ne sait pas « où coller » sinon.
5. **Boucle 2** (`docs/current/BOUCLE-1_PLAN_2026-10-24.md` §suite, `PILOTAGE-BOUCLES-2026-10-24.md`) :
   import des inscrits actuels (essai à blanc), décision des prix, enseignants, bibliothèque des
   noms de Classes, test de connexion d'un enseignant réel.
6. **Entrée** (`docs/current/PARCOURS-ENTREE-2026-10-25.md` §4) : PR 3 (questionnaire avant
   compte, règle serveur « famille sans attente ») et PR 4 (élève et accords) ne sont pas commencées.

## 6. Décisions du directeur prises ce jour (26/10), à ne pas rediscuter

- Une tuile de la barre se place du côté du panneau qu'elle ouvre.
- Pas de bouton « Recharger l'application » ; le geste de tirage, oui.
- Tiroir ouvert sur téléphone : pas de pilule en dessous (sa maquette).
- Plus de nouveau périmètre dans la PR B : finir ce qui était en cours, basta.
- Le pilote actuel s'arrête après la PR B ; la suivante repart de cette passation.
- GitHub Actions : dépôt rendu public à contre-cœur (crédits épuisés jusqu'au 1er novembre),
  aucun paiement GitHub ; LiveKit payé seulement au début effectif des cours.

## 7. Erreurs du pilote à ne pas répéter

- Avoir dit « déployé » pour le bandeau de version sans dire qu'il était inerte sans la ligne du
  workflow ; une capacité qui dépend d'une action du directeur est un blocage à annoncer le jour
  même, en tête de message.
- Avoir laissé une règle de plan (« la pilule reste ») contredire la maquette du directeur.
- Avoir relu des captures sans voir la barre inversée ; relire une capture, c'est la comparer à
  la maquette tuile par tuile.
- Avoir ajouté six points de périmètre à la PR B après la colère du directeur, au lieu de finir ce
  qui était en cours : il a dû annuler lui-même.
- Avoir donné une édition de fichier à faire sur GitHub par un paragraphe : il a atterri sur une
  branche à part sans le savoir. Donner un lien, trois clics, et vérifier `main` ensuite.
- Captures et tests verts ne prouvent rien pour lui : proposer l'aperçu Vercel de la PR avant
  chaque fusion.
