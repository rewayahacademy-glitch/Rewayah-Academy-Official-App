# MA-PROGRESSION : fiche de l'étape 1 (08/11/2026, agent A)

**Non vérifié d'abord.**
- Lecture du dépôt seulement, sur `main` c6948b77a. Rien n'a été lu sur la base de production : une fonction trouvée dans `supabase/migrations` n'est pas forcément installée.
- Aucun code n'est écrit avant le feu vert du pilote.
- Les chiffres de durée viennent du programme en base (`programme_niveaux.durees`), jamais de l'écran.

**Demande du directeur (08/11, consignée telle quelle par le pilote)** : « où il était, où il est, où il doit être (objectif du programme selon son niveau, ex. débutant jusqu'à Az-Zalzalah), quoi faire (heures de révision par semaine, répétitions estimées, supports), combien de temps (réglage de l'administration) ; interface moderne, interactive, sérieuse, visuels de progression ».

**Pour qui** : l'élève (adulte, ou en Interface guidée) et sa famille. Chacun ne voit que sa partie (compétence `programme-rewayah` §1).

**Règle du garde-cap** : on ne crée aucun programme. Tout se lit en base (`programme_niveaux`, migration `20261110600000_cahier_c2_programme_donnees.sql`), jamais de texte écrit à la main dans l'écran.

## Les six points

| # | Point | Ce qui existe en base | Ce qui existe dans le code | Ce qui manque |
|---|---|---|---|---|
| 1 | **Où il était** | `progression_historique` (`0021:19`) : chaque changement d'étape, avec son type et sa date. Lecture réservée à la direction (`0021:44`). `progression_famille` rend les étapes franchies que l'enseignant a partagées (`jalons`, `20261018190000:281`) | `ProgressionClassePage`, côté tuteur (`classe_tuteur/progression_classe_page.dart`), lit `progression_famille` | Une lecture élève et famille de son propre historique d'étapes, avec les dates |
| 2 | **Où il est** | `etapes_eleves_classe` (`20261110600000:493`) : l'étape en cours, depuis quand, la cohorte. `position_reprise_classe` : la page où la Classe s'est arrêtée. Les deux sont gardées par CAHIER-C1 (direction et enseignant) | La salle (PR 376, fusionnée) et la fiche de la Classe, côté enseignant. Ma classe de l'adulte : niveau et dernière étape partagée (PR 380, non fusionnée) | La branche élève et famille de ces deux lectures : **H** (pilote, 08/11) |
| 3 | **Où il doit être** | `programme_niveaux` : `nom_humain`, `cycle`, `ordre`, `objectifs` (3 à 5), `plage_support`. La version publiée seulement. L'objectif du niveau, c'est la dernière étape du `cycle` en cours, par exemple « Les sourates courtes » pour les bases | Lecture par la direction (`programme_contenu_admin`) et par l'enseignant (`etapes_eleves_classe`). Aucune lecture élève ni famille | Une lecture élève et famille : les étapes de son cycle dans l'ordre, la sienne marquée, avec ses objectifs. Lecture seule, version publiée |
| 4 | **Quoi faire** | Le travail donné : `learning_assignment` (`tc_outils/assignations_supabase.dart`) et le travail à venir (`portTravailAVenirProvider`, `main.dart:815`). Les supports : `plage_support`, et la Bibliothèque | Le travail à préparer est déjà montré à la famille et à l'élève | **Heures de révision par semaine** et **répétitions estimées** : rien en base, ni réglage ni donnée. C'est une règle neuve à décider (directeur) avant tout calcul. Emploi du temps de révision (`programme-rewayah` §6) : non construit |
| 5 | **Combien de temps** | `programme_niveaux.durees` : par cohorte, `{prevue, limite}` en semaines, réglées par la direction (`modifier_contenu_niveau`). `etapes_eleves_classe` en tire déjà `date_limite` (début de l'étape + limite) | Côté enseignant seulement | La même date limite et la durée prévue, lues par l'élève et sa famille (voir 2). Le rythme (`rythme_classe`, PR 373, non installée) : branche élève et famille par H |
| 6 | **Visuels de progression** | Les étapes ordonnées (`ordre`) et leurs dates suffisent à une frise. Aucun pourcentage n'existe en base | Aucun composant de frise d'étapes. `BlocProgression` existe (tuteur) | Le dessin : il attend les références visuelles du directeur. Sans pourcentage inventé, la frise suit les étapes réelles |

## La lecture serveur à créer (une seule, proposée)

- **`ma_progression(p_student_id uuid)`**, `STABLE`, `SECURITY DEFINER`, `search_path` vide, `EXECUTE` pour `authenticated` seulement.
- **Porte** : l'élève lui-même (`auth.uid()`, y compris l'adulte titulaire de soi, rôle `guardian`), ou un tuteur du même foyer. Elle reprend la garde de `progression_famille` (`20261018190000:301-302`), sans rien élargir.
- **Ce qu'elle rend**, tout tiré de la version publiée :
  - l'étape en cours, le cycle et ses étapes dans l'ordre (nom, objectifs) ;
  - « depuis », la durée prévue et la date limite de sa cohorte ;
  - les étapes déjà franchies, avec leur date ;
  - la page de reprise de sa Classe.
- **Elle ne rend pas** : le motif d'un changement d'étape (texte de la direction), le nom de celui qui a décidé, ni rien d'un autre élève.
- **Répartition** : H fait la branche élève et famille de `position_reprise_classe` et de `rythme_classe` (pilote). `ma_progression` peut les appeler, ou H peut les intégrer : **à trancher par le pilote**, pour éviter deux lectures concurrentes.

## Ce que cette étape ne fait pas

- Aucun écran, aucune migration, aucun texte d'interface.
- Les heures de révision et les répétitions estimées attendent une règle du directeur : sans elle, aucun nombre ne sera affiché.
- La PR 380 reste ouverte. Elle sera absorbée par le lot et ne sera pas fusionnée seule.
