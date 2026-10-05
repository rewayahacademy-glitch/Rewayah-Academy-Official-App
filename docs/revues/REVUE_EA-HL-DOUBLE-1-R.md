# Revue adverse EA-HL-DOUBLE-1 : branche `corrections/c2-hl-double` (ec7b7aeb)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** La demande centrale est remplie et prouvée. Aucun défaut majeur ne ressort. Une réserve moyenne porte sur deux notes d'enseignant qui redisent encore l'absence de réseau.

J'ai relu dans un worktree jetable, détaché sur `origin/corrections/c2-hl-double` et retiré à la fin. Je n'ai rien poussé et rien modifié sur la branche. Comparaison faite avec 3df81930, le parent avant le lot.

## Ce qui est vérifié et tient

### Le bandeau seul dit « hors ligne »
Avant le lot, 13 endroits de `lib/features` et du routeur affichaient un bloc `EtatSysteme(horsLigne)` sous le bandeau, avec le titre par défaut « Vous êtes hors ligne ». Ces blocs ont été remplacés par `EtatSansDonnees`, dont le titre dit ce qui manque et dont la phrase est vide :
- Accueil, Historique, Ma classe et Mon espace adultes ;
- soldes et recharge ;
- Foyer : profils et titulaire ;
- fiche élève et porte d'ajout de profil ;
- appareils du foyer et d'un profil ;
- listes de la Journée ;
- page de démarrage du routeur ;
- observation.

Les dossiers admin (file, visionneuse) ont des titres réécrits sans « Vous êtes hors ligne ». La salle (`PageImmersive`) et le scanner (sans PageShell, avec son propre bandeau) restent à part, comme le prévoit la règle.

### Lecture du code
- Un bloc n'apparaît que si la page n'a rien à montrer : hors ligne, lecture en échec, aucune valeur déjà lue, et pas de `CapaciteIndisponible`.
- Une capacité absente reste dite « indisponible ».
- Il n'y a pas de régression sur le Foyer ni sur la fiche élève. Leur `profils` est reconstruit en `AsyncValue.error`, donc sans valeur, et le bloc continue d'apparaître comme sur la base.

### Règle écrite et périmètre
- La règle figure dans `docs/current/03_DESIGN_SYSTEM_ET_UX.md`, nouvelle section « États ». Elle est datée du 04/10/2026, déléguée par le directeur, K-42.
- Aucun fichier interdit n'est touché : `page_shell.dart`, `supabase/`, `.github/`, `pubspec`, le thème, le rendu du Coran.
- Les trois commits se terminent exactement par les deux lignes imposées, et aucun identifiant de modèle n'apparaît ailleurs.

### Mutations
- **Mutation 1** : je remets dans leur état d'avant le lot Accueil, Ma classe, Historique, Foyer, soldes et Journée. Huit tests échouent, dont « Accueil déjà lu puis relu en échec : il reste affiché », les deux routes réelles et les listes de la Journée.
- **Mutation 2** : je remets dans leur état d'avant le lot Mon espace, appareils, fiche élève, formulaire de profil, recharge, observation et routeur. Huit tests échouent, dont « un seul état, un seul Réessayer », « le bloc dit ce qui manque », le motif de l'observation et l'adresse qui mène à la page hors ligne.
- **Mutation 3** : je neutralise `lectureHorsLigne` et je retire `phrase: ''`. Un seul échec, le test unitaire de `lectureHorsLigne`. La phrase par défaut qui revient n'est détectée par aucun test (voir les réserves).

### Mesures
| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucune différence |
| `dart analyze --fatal-infos` | 0 problème |
| `verifier_jetons` | 39 violations, aucune dans un fichier modifié par le lot (exit 1, comme avant) |
| `verifier_revue` | 1575 violations, ce qui confirme le chiffre annoncé |
| Tests ciblés des dossiers touchés | +918, 67 sautés, 0 échec |
| `test/features`, `test/core`, `test/widgets`, `test/teaching_core` et le test de capture du lot (`--concurrency=2`) | +4757, 2150 sautés, 0 échec |

### Captures
J'ai ouvert les 13 PNG :
- Accueil sans données : 390 clair et sombre, 320 à 200 % en LTR et en RTL, 1440 ;
- Ma classe et Mon espace sans données ;
- Accueil et Ma classe avec données.

Chaque fois, le bandeau est seul, ou le bandeau est accompagné d'une carte qui dit ce qui manque, avec « Réessayer ». Aucun mot n'est coupé. Le RTL est cohérent : l'inversion de la ponctuation vient du français affiché en sens RTL, ce qui est attendu.

## Réserves, à traiter dans un lot suivant
1. **Moyen.** `creneaux_page.dart` (horsLigneGrille, horsLignePrise, horsLigneDemande) et `bienvenue_page.dart` (bienvenue.horsLigne) sont dans un PageShell. Leurs notes commencent par « Sans réseau, … » et redisent donc ce que dit le bandeau. Cela contredit la règle que le rédacteur a lui-même écrite (« ni bloc, ni carte, ni note »). Le compte rendu les présente comme « dictés par le directeur », mais ces textes viennent d'un commit d'agent du 20/09 (57e72110) et sont absents de `libelles_sources.json`. Seuls les deux textes du cahier sont attribués au directeur. Le garde-fou du catalogue laisse passer « sans réseau ».
2. **Mineur.** Retirer `phrase: ''` d'`EtatSansDonnees` ferait revenir « Vérifiez votre connexion. Ce qui est déjà affiché reste consultable. », qui répète le bandeau. Aucun test ne le verrait.
3. **Mineur.** Garder la dernière valeur lue (`lectureHorsLigne`) n'est prouvé que par un test unitaire. Aucun test de page ne la distingue.
4. **Mineur.** Il n'y a de captures que pour trois écrans adultes. Il manque :
   - les captures des autres écrans modifiés : Foyer, soldes, recharge, fiche élève, appareils, Journée, observation, routeur ;
   - l'Interface guidée ;
   - le sombre et le 1440 en dehors de l'Accueil.

## Statut
Présent dans le code et testé localement : ma revue le confirme. Rien n'est testé sur staging ni déployé. Aucune PR n'est ouverte et rien n'a été poussé sur `main`. Les 48 libellés nouveaux ou modifiés restent marqués « à faire valider par le directeur ».
