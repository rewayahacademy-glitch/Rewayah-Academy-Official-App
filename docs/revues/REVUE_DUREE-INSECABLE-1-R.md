## DUREE-INSECABLE-1 : relecture adverse indépendante

**Ma décision : je l'accepte avec des réserves (aucune n'est majeure).**

- Branche : `origin/corrections/c2-duree` @ `f05278fa`.
- Base : `3df81930`.
- J'ai travaillé en lecture seule dans un worktree jetable, retiré à la fin. Je n'ai rien poussé.

### 1. Ce qui était demandé et ce qui est livré

**Durées insécables**
- La fonction `LibellesGroupe.insecable` (`lib/core/tc_groupe/libelles_tc_groupe.dart`) est le seul endroit qui rend une durée insécable.
- Elle remplace par U+00A0 deux espaces : celle qui suit un nombre, et celle entre l'unité et les minutes.
- Elle s'applique à `dureeLisible`, `compteARebours`, `tempsRestant`, `dansMinutes` et `dansHeures`, au compte à rebours élève et famille, au minuteur enseignant, à TimelineRow, à l'en-tête de la classe live, à l'historique, à la visite d'observation et au contrôleur.
- La phrase reste sécable avant la durée : « Cours dans / 3 h 28 ».

**Sélecteur de profils**
- Le passage à la ligne se fait seulement quand la rangée déborderait (LayoutBuilder et mesure de la rangée sur une ligne).
- À 320 x2, « Aucune / séance » passe à la ligne au lieu d'être rogné.
- À 390 et à 1440, l'état reste sur une ligne.

**Mesure TexteSansCoupure**
- Elle ne coupe plus les mots aux espaces insécables.

**Ordre en RTL**
- `ancreSens` (U+200E) est posée sur les valeurs affichées seules : `dureeSeule` et `heureEtVille`.

**Fichiers interdits**
- `accueil_accessibilite.dart` n'est pas touché.
- Rien n'a été modifié dans `supabase/`, `.github/`, `pubspec.yaml`, le thème ou le rendu du Coran.

### 2. Contre-épreuves (mutations)

Chaque mutation a été faite sur le code, testée, puis annulée.

| Mutation | Résultat |
|---|---|
| `insecable` renvoie le texte tel quel | 21 échecs : formatage, autres formateurs, vraies polices LTR/RTL, Accueil Accessibilité et CarteSession à 320 x2, accueil famille à 320 x2 LTR/RTL |
| Sélecteur jamais en mode compact | 2 échecs (accueil famille, 320 x2, LTR/RTL) |
| Sélecteur toujours en mode compact | 4 échecs (390 et 1440, LTR/RTL) : la non-régression est bien gardée |
| `ancreSens` sans marque | 6 échecs (3 tests bidi, 3 tests de la Session Card) |
| TexteSansCoupure découpé sur `\s+` | 3 échecs |

Tous les tests mordent.

### 3. Contrôles

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | 0 problème |
| `tool/verifier_revue.dart` | 1606 violations, identique à la base selon le rédacteur |
| `tool/verifier_jetons.dart` | 39 violations, aucune ajoutée par les lignes modifiées (la seule sur un fichier touché, `carte_session.dart:400` `ontap-nu`, existait déjà) |
| Tests ciblés (accessibilité, accueil famille et élève, historique, classe tuteur, `teaching_core/a`, `tc_horloge`) | 429 verts |
| Suite complète, `--concurrency=2`, tous les dossiers de `test/` sauf capture, fixtures et support | code de sortie 0, aucun échec |

### 4. Captures ouvertes

- **avant_famille_320x2_ltr** : on voit bien « Cours dans 3 h / 28 » et « Aucune séan » rogné.
- **apres_famille_320x2_ltr et rtl** : « Cours dans / 3 h 28 », « Dans / 3 h 28 » et « Aucune / séance » sont entiers.
- **avant_accessibilite_320x2_rtl** : on voit « min 45 », « Paris 18:00 » et « dans 3 h / 28 ».
- **apres_accessibilite_320x2_ltr et rtl** : « 45 min », « 18:00 Paris » et « 3 h 28 » sont sur une ligne et dans le bon ordre.
- **apres_famille_390x1_sombre_rtl** : sélecteur sur une ligne, « Ajouter » visible, mode sombre correct.
- **apres_famille_1440x1_ltr** : sélecteur sur une ligne, aucune régression.

À 320 x2, le bord de l'écran laisse voir l'amorce de l'item « Ajouter ». Ce n'est pas un rognage de texte : c'est l'indice que la rangée défile horizontalement, et ce comportement existait déjà.

### 5. Réserves (mineures)

1. **Durées encore sécables hors périmètre.** Elles ne passent toujours pas par `insecable` : cahier, créneaux, historique du contrôleur, compte rendu de contrôle, minutes restantes de la salle, indicateur d'observation, post-cours, `ligne_presence`, `page_parcours`. Ces écrans ne sont pas cités dans la demande. C'est à traiter dans un lot de suite pour que la règle « une durée ne se scinde jamais » soit vraie partout.
2. **Ancre RTL incomplète.** `dureeLisible` s'affiche encore seule, sans ancre, dans `detail_seance_page`, `detail_observations_page` et `carte_groupe`. Le défaut (« min 45 ») n'existe qu'avec du français en RTL.
3. **Pas de capture dédiée à CarteSession.** Elle est couverte par un test à 320 x2 en LTR et RTL.
4. **Ponctuation inversée en RTL** (« .charge »). Le défaut existait déjà et le rédacteur le signale.

### 6. Statut de preuve

- Spécifié : oui.
- Présent dans le code : oui.
- Testé localement : oui.
- Testé sur staging : non.
- Déployé : non.
- Aucun besoin serveur.
