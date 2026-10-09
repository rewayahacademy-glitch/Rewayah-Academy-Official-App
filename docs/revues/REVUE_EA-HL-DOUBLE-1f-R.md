<!-- verdict : REFUSEE -->
## Relecture adverse de EA-HL-DOUBLE-1f (branche `corrections/c2-hl-double-f`, commit cc3f3729)

**Verdict : REFUSÉE.** Ce qui a été livré est propre. La demande exigeait aussi de chercher **tous** les autres cas dans `fr.i18n.json` : au moins deux textes visibles affirment encore une indisponibilité côté service sur un échec de lecture ou de réseau. Ils sont du même type que ceux que l'étape a réécrits, et la garde étendue ne les détecte pas.

### Méthode
- J'ai travaillé dans un worktree jetable, détaché sur `origin/corrections/c2-hl-double-f`, puis je l'ai retiré. Je n'ai rien poussé.
- La base 5a52ff30 est bien contenue dans la branche. Le diff compte 29 fichiers.
- Aucun fichier interdit n'est touché : ni `supabase/`, ni `.github/`, ni `pubspec`, ni le thème, ni le Coran.
- Les deux commits se terminent par les deux lignes exactes demandées.

### Ce qui est rempli
- **Séances prochaines et passées.** `adulte.accueil.echec` et `adulte.historique.echec` utilisent déjà la formulation de 1e. Plus aucun « le serveur n'a pas répondu » dans le catalogue. Leur statut dans `tool/libelles_sources.json` est passé à « validé par délégation le 09/10 (DIR-REP-1) ».
- **Agent.**
  - `agent.indisponible` devient « L'ouverture n'a pas abouti ».
  - `agent.indisponibleDetail` devient « Il est possible que la demande ne soit pas parvenue jusqu'à Rewayah. Réessayez dans un instant. ».
  - Ni le réseau ni la connexion ne sont redits sous le bandeau.
- **Salle.** `refusReseau` et `refusReseauDetail` sont reformulés. « Vérifiez votre connexion » reste, ce qui est conforme à l'exception `PageImmersive` sans bandeau.
- **Bibliothèque.** Le message est réécrit et une invitation est ajoutée. Elle est branchée sur la surface et sur la fiche détail.
- **Documentation et fiches.** `docs/current/03` est aligné. Les 6 fiches de `libelles_sources.json` portent « validé par délégation le 09/10 » et « décidé par délégation le 09/10 ».

### Contrôles relancés
| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucun écart avec les fichiers générés commités |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_jetons` | 37 violations (limite ≤ 37) |
| `verifier_revue` | 1533, identique à la base |
| Tests ciblés (`core/reseau`, `agent_entree`, `salle`, bibliothèque) | +75 ~14, tous passés |
| 49 fichiers qui utilisent `hors_ligne_une_fois`, `salle_page`, la bibliothèque ou l'agent, plus `teaching_core/b` et `core/reseau` | +1125 ~561, tous passés |

- Tous les tests ont tourné avec `--concurrency=2`.
- J'ai aussi lancé `test/features`, `test/teaching_core` et `test/core` en une fois. Ce passage a été arrêté à la limite de 10 minutes, sans résultat : il n'apporte pas de preuve et ne compte pas dans le tableau.

### Mutations
1. **Anciens textes remis** (« La salle n'a pas répondu », « Service indisponible », « momentanément indisponible ») : 5 échecs, à savoir la garde du catalogue, l'agent ×2, la bibliothèque et la salle.
2. **Anciens `salle_page.dart`, `agent_entree_page.dart` et `surface_bibliotheque.dart` remis** : 7 échecs, à savoir 320 texte x2 LTR et RTL pour l'agent et la bibliothèque, l'état de panne de la bibliothèque, et l'encre de l'impasse en clair et en sombre.

Les tests ajoutés mordent donc bien sur le code livré.

### Captures ouvertes
- **Agent, 320 x2 RTL.** Aucun mot coupé. Le libellé « Jeton d'observation » est maintenant posé au-dessus du champ.
- **Agent, 390 sombre.** Correct, et seul le bandeau porte le wifi barré.
- **Bibliothèque, 320 x2.** L'indication de recherche tient sur 3 lignes, et le message et l'invitation sont complets.
- **Salle, 390 sombre et 320 x2 RTL.** L'impasse est lisible : l'encre du fond corrige bien le contraste.
- **Manques.** Aucune capture à 1440 px, aucune capture RTL en sombre. L'Interface guidée n'est pas pertinente pour ces écrans.

### Défauts qui motivent le refus
1. **`tc.observation.refus.indisponible`**, « L'observation n'est pas disponible pour le moment. »
   - Où il s'affiche : `entree_observation_page.dart`, `_indisponible()`, pour `MotifEchecObservation.reseau`, documenté « Le reseau ou le backend n'a pas repondu ». Il s'affiche aussi sur `AsyncValue.hasError`.
   - Situation : la page est sous `PageShell`, donc sous le bandeau, et un bouton propose de réessayer.
   - C'est exactement le cas de « Service indisponible » de l'agent : une cause côté service affirmée alors que c'est peut-être l'appareil qui est hors ligne.
2. **`classe.entree.indisponible`**, « L'information sur la séance est indisponible pour l'instant. »
   - Où il s'affiche : dans `fiche_groupe_page.dart:489`, pour toute erreur de lecture, hors ligne compris et sous le bandeau ; et via `emplacement_entree.dart` (`lectureEchouee`).
   - « indisponible pour l'instant » équivaut à « momentanément indisponible », que l'étape a retiré de la bibliothèque. Le compte rendu ne cite pas ce texte : il n'est ni réécrit ni justifié.
3. **La garde laisse passer les deux.** `motifCauseAffirmee` n'attrape ni « pas disponible pour le moment » ni « indisponible pour l'instant ». La demande d'étendre la garde à « indisponible quand il affirme une cause » n'est donc remplie que partiellement.

### Ce qu'il faut pour accepter
- Réécrire ces deux textes dans la formulation unique, en appliquant aux deux écrans la même règle qu'à 1e et 1f :
  - le titre dit ce qui n'a pas abouti, par exemple « L'observation n'a pas pu s'ouvrir » ou « La séance n'a pas pu être chargée » ;
  - la phrase reprend « Il est possible que la demande ne soit pas parvenue jusqu'à Rewayah. » ;
  - garder `capaciteAbsente` et `disponibilite.capacite`, qui sont des faits connus.
- Étendre `motifCauseAffirmee` aux formes « (in)disponible pour le moment / pour l'instant ». Exceptions nommées : les clés liées à `CapaciteIndisponible` (`dossiers.*`) et les capacités absentes.
- Ajouter un test par écran et une mutation de la garde.
- Ajouter les captures à 1440 px et en RTL sombre.

### Réserves annexes, sans effet sur le verdict
- **Antérieure.** L'entrée d'agent dit « Réessayez dans un instant » sans action pour réessayer. La clé `agent.reessayer` n'est utilisée nulle part.
- **Information.** `coran.indisponibleDetail` (« Dès que le réseau revient… ») redit le réseau. Ce texte appartient au périmètre du Coran, interdit ici ; il est signalé pour une étape dédiée.
