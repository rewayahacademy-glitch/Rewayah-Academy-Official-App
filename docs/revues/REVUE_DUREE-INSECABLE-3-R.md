<!-- verdict : REFUSEE -->
# Relecture adverse de DUREE-INSECABLE-3 (branche corrections/c2-duree-3, commit 3ab9e169)

**Verdict : REFUSEE.** La garde appel par appel, l'insécabilité des durées restantes, le test des valeurs de LignePresence et les captures sont faits et prouvés. Une consigne n'est pas entièrement remplie : « ancre de sens seulement là où la valeur commence le libellé (sinon la retirer) ». Deux écrans glissent encore une durée ancrée au milieu d'un libellé, et le test de l'ancre ne peut pas les voir. La correction est petite et ciblée.

Contexte : worktree jetable détaché sur origin/corrections/c2-duree-3, retiré à la fin. Base : origin/corrections/revue-directeur-2026-10 (4207c357), qui est bien l'ancêtre commun. Je n'ai rien poussé.

## 1. Ce qui est rempli (vérifié)

### Garde appel par appel (test/support/garde_durees.dart)
- La liste des libellés se déduit de fr.i18n.json : **86 clés**. J'ai relancé le contrôle, il trouve **87 appels** dans lib/, tous enveloppés :
  - 54 par LibellesGroupe.insecable ;
  - 26 par LibellesGroupe.valeurSeule ;
  - 7 par insecable.
- Les alias (final h = t.controleur.historique) sont suivis.
- Clés sans appel dans lib/ :
  - creneaux.attendDepuis/prendre, priere.*, dossiers.inscritDepuis, enseignant.journee.rapport*, tc.classe.observation.restant : aucun appel trouvé ;
  - tuteur.accueil.depuisMinutes : appelée seulement dans _dev/galerie, exclu à juste titre.

  Aucun libellé à unité n'échappe donc à la garde.
- J'ai cherché les tear-offs (une clé passée sans parenthèses) : il n'y en a aucun.

### Contre-épreuves (mutations), toutes restaurées

| Mutation | Résultat |
|---|---|
| M1 : silence nu (ligne_presence) | échec (valeur rendue + garde) |
| M4 : attente nue | échec |
| M9 : dureeSeule dans dureeCarte | échec (test carte de groupe) |
| M17 : ancre dans dureeEnPhrase (dernière séance) | échec |
| M13 : règles nues (uniteMinutesRegle) | échec |
| M14 : consentement nu | échec |
| Cooldown nu (fiche_seance) | échec (garde) |
| uniteSecondes nue (module_reglages_observation) | échec (garde) |
| Alias historique nu | échec (garde) |
| Retard nu (LignePresence) | échec (garde) |
| estInsecable neutralisé (toujours vrai) | échec (test des alias) |
| t.tc.groupe.carte.duree(valeur: dureeSeule(...)) direct | échec (contrôle de source de l'ancre) |
| **valeurSeule glissé dans h.meta (alias)** | **les 12 tests passent : trou** |

### Durées restantes
Toutes les clés citées par la relecture précédente sont couvertes, et la garde le prouve :
- cooldown dans fiche_seance et classe_live_page ;
- uniteSecondes ;
- demandeMinutes ;
- uniteMinutes et uniteSemaines ;
- consentement.comment.visites.

Les paramètres déjà mis en forme ({duree}, {reste}, {temps}) proviennent de dureeLisible, de dureeVisiteLisible (désormais insécable) ou de mm:ss. Ils sont corrects.

Les tests existants alignés sur la nouvelle valeur (13 fichiers) l'ont été sans affaiblir les assertions : la valeur attendue passe par insecable ou porte U+00A0.

### Captures (docs/current/captures/DUREE-INSECABLE-3/)
- 18 PNG : 390 et 1440 px, texte x1 et x2, clair et sombre, LTR et RTL, plus 320 px texte x2 en sombre. Aucun doublon md5.
- J'en ai ouvert quatre : 320x2 sombre RTL, 390x2 clair RTL, 1440x2 sombre LTR, 1440x1 clair RTL.
  - « 45 min », « 18:00 Paris » et « 3 h 28 » restent insécables et gardent leur ordre en RTL.
  - Aucun mot n'est coupé.
- Le script est archivé en .txt, et une copie se trouve dans test/capture/, qui saute sans capture.
- La ponctuation inversée en RTL est un défaut antérieur, signalé.

### Contrôles

| Contrôle | Résultat |
|---|---|
| dart analyze --fatal-infos | aucun problème |
| verifier_revue | 1568, identique à la base, que j'ai mesurée moi-même |
| verifier_jetons | 39 |
| flutter test test/features, --concurrency=2 | +2827 ~2126, tout passe |
| flutter test test/core | +670 |
| flutter test test/widgets | +291 |
| flutter test test/teaching_core | +1353 ~102 |
| flutter test test/accessibilite | +362 |

## 2. Ce qui n'est pas rempli

1. **Planning de classe du tuteur** (lib/features/classe_tuteur/planning_classe_page.dart:274-283). affichage.duree vaut dureeSeule, donc porte l'ancre. Il est inséré dans « {heure} · {duree} » et dans « {heure} ({fuseau}) · {duree} ».
   - Preuve, par un test jetable : on obtient `31 38 3a 30 30 20 b7 20 200e 34 35 …`, soit « 18:00 · ‎45 min ».
   - C'est exactement le défaut que le rédacteur a corrigé pour la dernière séance avec dateEtDuree.
   - Le libellé commence par l'heure : l'ancre doit envelopper la ligne entière (ancreSens), et la durée doit venir de dureeEnPhrase.
2. **Historique du contrôleur** (lib/features/controleur/historique_controleur_page.dart:334-350). `duree = valeurSeule(h.duree(...))` est ensuite inséré dans h.meta « {heure} · {duree} » et dans le libellé sémantique h.ligne.
   - Preuve : le résultat contient U+200E, et le texte rendu est « 18:00 · ‎12 min observées ».
   - Correction attendue : insecable pour la valeur dans la phrase, et ancreSens sur meta, qui commence par l'heure.
3. **Test de l'ancre incomplet.** Le contrôle « aucune durée ancrée glissée » ne regarde que les enveloppes en `t.` et LibellesGroupe.duree. Il ne suit ni les alias, ni les variables, ni les champs, comme l'a montré la mutation MancreAlias. Il faudrait le faire suivre les alias, comme la garde d'insécabilité le fait déjà. Il faudrait aussi ajouter un test sur la valeur rendue du planning et de la méta de l'historique (pas de U+200E au milieu).

## 3. Observations hors périmètre strict
- « {taille} Mo » (photo trop lourde) est une unité qui n'est pas sécurisée. Ce n'est pas une durée, je le note seulement.
- `invitation.dureeConservation` est une chaîne venue du serveur, insérée telle quelle dans un libellé. Aucun appelant ne la fournit aujourd'hui.

## Statut
Testé localement seulement, sur la branche. Rien sur staging, rien déployé.