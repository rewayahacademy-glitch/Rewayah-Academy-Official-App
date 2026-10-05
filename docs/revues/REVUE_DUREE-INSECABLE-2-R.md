## DUREE-INSECABLE-2 : relecture adverse indépendante

**Ma décision : je l'accepte avec des réserves. Aucune n'est majeure.**

- Branche : `origin/corrections/c2-duree-2` @ `4b63b62f`.
- Base : `origin/corrections/revue-directeur-2026-10` @ `29a4fc83`.
- J'ai travaillé en lecture seule dans le worktree jetable `rv-DUREE-INSECABLE-2-7`, avec un second worktree sur la base pour comparer. J'ai retiré les deux à la fin. Je n'ai rien poussé.

### 1. La demande est-elle remplie ?

**Réserve 1 : faire passer toutes les durées de la liste par `insecable`.** C'est fait. J'ai relu le diff sur les 10 sites :

| Site | Comment la durée est traitée |
|---|---|
| Cahier : `duree` et `dureeEtInterruption` | `valeurSeule` |
| Créneaux : `duree` | `valeurSeule` |
| Historique du contrôleur : `h.duree`, aux 2 appels | `valeurSeule` |
| Compte rendu : `debutRetard` | `valeurSeule` |
| Salle de séance : `minutesRestantes` | `valeurSeule` |
| Indicateur d'observation : `annonce.restant` | `valeurSeule` |
| Post-cours : `dureeReelle` | `insecable` |
| LignePresence : entrée, retard, silence, attente | `insecable`, et `valeurSeule` pour le retard |
| PageParcours : `tempsRestant` | `insecable` |
| filtres_historique : retard | `insecable` |

`valeurSeule` vaut `ancreSens(insecable(texte))`, donc `insecable` reste le seul endroit qui rend une durée insécable. `ancreSens` ne touche pas un libellé qui commence par une lettre ou qui contient de l'arabe.

**Réserve 2 : ancre de sens sur les durées isolées.** C'est fait :
- `detail_seance_page` (durée prévue, interruption) et `detail_observations_page` (durée totale, durée d'une visite) passent maintenant par `dureeSeule`, qui applique `ancreSens(dureeLisible)`.
- `carte_groupe` passe par `LibellesGroupe.dureeSeule`. Le libellé y est « Durée {valeur} » : il commence par un mot, donc l'ancre n'a pas d'effet là. Elle ne fait pas de mal non plus. Voir le défaut 2.

**Réserve 3 : captures avant/après de la CarteSession.** Elles sont livrées. J'ai ouvert les PNG :

| Sens | Avant | Après |
|---|---|---|
| RTL | « Paris 18:00 », « min 45 » | « 18:00 Paris », « 45 min » |
| LTR | identique à l'après (même md5) | sur une ligne |

- Dans tous les cas, « Cours dans / 3 h 28 » ne se coupe qu'avant la durée, jamais au milieu.
- Le script de capture est archivé (`.txt`), identique au fichier de test.

**Réserve 4 : ponctuation française inversée en RTL.** Elle n'est pas traitée. C'est un défaut antérieur au lot, et le rédacteur l'annonce.

### 2. Contre-épreuves (mutations)

Chaque mutation a été appliquée, testée sur `test/accessibilite/duree_insecable_2_test.dart`, puis annulée.

| Mutation | Résultat |
|---|---|
| M2 : post-cours nu | 1 échec |
| M3 : créneaux nu | 1 échec |
| M5 : entrée de LignePresence nue | 2 échecs |
| M6 : retard de filtres_historique nu | 1 échec |
| M7 : PageParcours nu | 1 échec |
| M8 : historique du contrôleur nu, appel de la ligne | 1 échec |
| **M1 : silence de LignePresence nu** | **0 échec** |
| **M4 : attente de LignePresence nue** | **0 échec** |
| **M9 : `LibellesGroupe.dureeSeule` sans ancre** | **0 échec** |

Pourquoi M1 et M4 survivent : la garde de source accepte tout appel qui a un `insecable(` ou un `valeurSeule(` dans les 400 caractères qui le précèdent. Dans LignePresence, l'enveloppe de l'appel voisin suffit à la satisfaire. Le code livré est correct ; c'est la garde qui est trop lâche.

### 3. Contrôles

- `dart analyze --fatal-infos` : aucun problème.
- `tool/verifier_revue.dart` : 1573 violations, autant que sur la base. Aucune régression.
- `tool/verifier_jetons.dart` : même sortie que celle annoncée par le rédacteur.
- Tests ciblés : les 7 fichiers alignés, plus `duree_insecable_test` et `duree_insecable_2_test`, soit 171 tests, tous verts.
- Suite par dossier, avec `--concurrency=2`, 0 échec partout :

| Dossier | Tests passés |
|---|---|
| accessibilite | 350 |
| core | 670 |
| widgets | 287 |
| teaching_core | 1335 |
| features | 2791 |
| presence | 20 |

- Les 7 tests existants modifiés n'ont été alignés que sur les nouvelles chaînes (U+00A0 et U+200E). Aucune assertion n'a été affaiblie.
- Périmètre respecté : rien dans `supabase/`, `.github/`, `pubspec.yaml`, le thème ou le rendu du Coran. Aucun libellé i18n créé.

### 4. Réserves (toutes mineures)

1. **Garde de source trop lâche.** Les mutations M1 et M4 survivent. Il faudrait :
   - vérifier chaque appel séparément (enveloppe immédiate plutôt qu'une fenêtre de 400 caractères) ;
   - ajouter des assertions de valeur pour le silence et l'attente.
2. **Ancre sans test et sans effet dans carte_groupe.** L'ancre de `LibellesGroupe.dureeSeule` n'est gardée par aucun test (M9 survit). Dans carte_groupe, le libellé « Durée {valeur} » commence par un mot, donc l'ancre n'y change rien.
3. **Durées encore sécables hors de la liste des défauts :**
   - cooldown du rappel discret (`fiche_seance`, `classe_live_page`) ;
   - `uniteSecondes` des réglages d'observation ;
   - `demandeMinutes`, `uniteMinutes`, `comment.visites`.
4. **Captures incomplètes.** Elles n'existent qu'à 320 x2, sur fond clair. Il n'y en a ni à 390, ni à 1440, ni en sombre. La ponctuation française reste inversée en RTL (réserve 4, défaut antérieur).

### 5. Statut de preuve

| Étape | Statut |
|---|---|
| Spécifié | oui |
| Présent dans le code | oui |
| Testé localement | oui (refait ici) |
| Testé sur staging | non |
| Déployé | non |
