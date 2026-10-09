<!-- verdict : REFUSEE -->
# Relecture adverse : EA-HL-DOUBLE-1e (branche `corrections/c2-hl-double-e`, a1e9440d)

## Verdict : REFUSÉE

Le point (1) de la demande n'est rempli qu'en partie, et l'écart est prouvé : la Journée affiche un message faux quand ce sont les cahiers qui échouent. Les points (2) et (3) sont remplis et prouvés. La reprise demandée est courte (voir la fin du rapport).

Méthode : worktree jetable détaché sur `origin/corrections/c2-hl-double-e`, base de comparaison `origin/corrections/revue-directeur-2026-10` (6e2c91c4). J'ai retiré le worktree à la fin et je n'ai rien poussé.

## Ce que j'ai vérifié

| Contrôle | Résultat |
|---|---|
| `dart run slang` | aucun écart |
| `dart analyze --fatal-infos` | 0 problème |
| Tests ciblés (`test/core/reseau`, `journee_test`, `test/features/controleur`, `fiche_eleve_test`), `--concurrency=2` | +317, ~25 sautés, 0 échec |
| Autres appelants du motif `motifHorsLigne` / `expectHorsLigneUneFois`, élargi par cette étape (captures 1 et 1d, accueil adulte et élève, revue de dossier, alertes, appareils, bienvenue, créneaux, foyer, journee/, routeur, entree_explication) | +702, ~419, 0 échec |
| `verifier_revue` | 1549 violations, celles de la base moins une |
| `verifier_jetons` | sans nouvelle violation (aucun fichier `lib/` touché, hors i18n) |
| `page_shell.dart` | non touché |

### Mutations : tests relancés après chaque annulation

- **M1.** J'ai remis l'ancien `erreurPartielle`, avec « (connexion instable ou service momentanément indisponible) ». 4 tests échouent : les 2 gardes du catalogue et les 2 tests de la Journée en échec partiel, en ligne et hors ligne.
- **M2.** J'ai remis « Rewayah n'a pas répondu » dans `controleur.observation.echec`. La garde « une seule formulation » échoue.
- **M3.** J'ai ajouté « (connexion instable) » dans un texte ordinaire (`ficheEleve.camera.horsLigne`). La garde du catalogue échoue : il n'y a plus d'exception pour « connexion instable ».
- **M4.** J'ai remplacé `visiteEchec` par une formulation divergente (« Rewayah ne l'a peut-être pas reçue »). La garde de formulation unique échoue.

La garde est donc réelle et elle mord.

### Captures ouvertes

J'ai ouvert, en découpes, la Journée à 320 texte x2 en RTL et le compte rendu du contrôleur à 320 texte x2 en RTL. Les 12 PNG ont les bonnes dimensions : Journée en 390 clair et sombre, 1440, 320x2 LTR et RTL, et en ligne ; fiche élève et contrôleur à 390 et 320x2 LTR/RTL.

- Le bandeau est seul en haut, avec un seul « wifi barré ».
- Le texte réécrit ne coupe aucun mot.
- L'icône d'attente sous le bandeau est le sablier.

## Point (1) : Journée enseignant, rempli en partie (défaut majeur)

Ce qui est fait :
- `erreurPartielle` est réécrit sans redire le réseau, avec la cause probable non affirmée.
- La garde est étendue aux formes « connexion/réseau instable, faible… », « problème de connexion », « connexion ou service », sans exception hors de la salle et de la classe en direct, qui n'ont pas de bandeau.

Ce qui manque : la demande nomme `erreurPartielleCahiers` et `erreurPartielleTout`. Le rédacteur répond que ces clés n'existent pas sur la base, ce qui est exact. Mais :

- Sur cette base, `partielle` vaut vrai aussi quand **seuls les cahiers à terminer** échouent (`journee_page.dart` l. 240-241 : `retards.hasError`). Le texte unique affiché dit alors, à tort, que « les horaires de prière et vos pauses n'ont pas pu être chargés ».
- J'ai vérifié ce cas par un test-sonde, retiré ensuite. Texte rendu : « Les horaires de prière et vos pauses n'ont pas pu être chargés : la demande n'est peut-être pas parvenue jusqu'à Rewayah. Vos séances affichées sont à jour : elles n'en dépendent pas. »
- Les deux clés demandées existent sur `origin/corrections/c1-integ2`. Elles y ont été ajoutées par le commit 0a9092ac (LIB-LOT3-2, « message d'echec partiel exact (cahiers, prieres, tout) ») et portent encore « (connexion instable ou service momentanément indisponible) ». Le directeur visait donc ce découpage en trois messages, que la ligne c2 n'a pas encore.

Le texte réécrit par l'étape reste donc faux dans l'un de ses trois cas de déclenchement, et les deux textes nommés ne sont ni portés ni réécrits.

## Point (2) : docs/current/03, rempli

- La visionneuse de pièce est retirée des exceptions : le bandeau reste visible au-dessus d'elle, elle n'a plus de signal propre, et une pièce illisible dit « La pièce n'a pas pu être chargée. » sous le sablier.
- Le code concorde : dans `visionneuse_piece.dart`, `icone: nature == NatureEtat.horsLigne ? AppIcons.attente`, et la clé `horsLigne` contient bien ce texte.
- La règle « une seule formulation » est écrite, avec la mention « décidé par délégation le 05/10, DIR-REP-1 ».

## Point (3) : les 7 textes « Rewayah n'a pas répondu », rempli

- Les 7 clés suivent une seule formulation : « il/elle n'est peut-être pas parvenu(e) jusqu'à Rewayah ».
- « Rewayah n'a pas répondu » n'apparaît plus nulle part dans le catalogue.
- La source des libellés porte « validé par délégation le 05/10 (DIR-REP-1) ».
- Le catalogue `ar` ne contient pas ces clés (98 clés en tout), donc il n'y avait rien à traduire.

## Réserves mineures, sans effet sur le verdict

1. `adulte.accueil.echec` et `adulte.historique.echec` disent encore « le serveur n'a pas répondu ». C'est la même inexactitude K-59, hors des 7 textes demandés ; le rédacteur l'a signalé.
2. Dans `tool/libelles_sources.json`, une phrase copiée sur les 8 clés dit que « (connexion instable…) » a été remplacé, ce qui est faux pour les 7 clés du contrôleur et de la fiche élève. Elle accole aussi « à faire valider » et « validé par délégation ».
3. La permission `salle.reconnexion` dans la garde vise une clé employée nulle part dans `lib/`.
4. Défaut antérieur, hors étape : à 320 texte x2, `ChoiceCardGroup` coupe des mots (« nor malement », « obser vation », « administ ration »). Une étape dédiée est à prévoir.
5. Défaut antérieur : hors ligne, la carte de la prochaine séance de l'enseignant dit « Vous pourrez entrer dans la séance… » avec un bouton « Réessayer ». Il y a donc deux « Réessayer » sur la page.

## Ce qu'il faut pour accepter

- Dans `journee_page.dart`, choisir le message selon ce qui a échoué :
  - prières ou pauses seules : `erreurPartielle` ;
  - cahiers seuls : `erreurPartielleCahiers` ;
  - les deux : `erreurPartielleTout`.
- Rédiger ces deux textes sur le modèle demandé (« … n'ont pas pu être chargés : la demande n'est peut-être pas parvenue jusqu'à Rewayah. Vos séances affichées sont à jour… »), sans redire le réseau.
- Les déclarer dans `libelles_sources.json` avec « validé par délégation le 05/10 (DIR-REP-1) » et les ajouter à la liste de la garde de formulation unique.
- Ajouter un test pour chacun des 3 cas, en ligne et hors ligne, puis une contre-épreuve où l'on annule la sélection du message.
- Faire les captures du cas cahiers à 320 texte x2 en LTR et RTL.
- En profiter pour corriger la source des libellés (réserve 2) et retirer `salle.reconnexion` des permissions (réserve 3).
