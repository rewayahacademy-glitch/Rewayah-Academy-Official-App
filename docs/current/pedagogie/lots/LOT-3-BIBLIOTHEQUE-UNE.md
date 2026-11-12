# Lot 3 · BIBLIOTHEQUE-UNE

Branche `claude/bibliotheque-une`. Agent du lot 3, sous l'autorité de l'architecte pédagogique, qui ouvre la pull request, fusionne et déploie. Écrit le 12/11/2026, mis à jour à la fin du lot (section « Ce qui est réellement fait »).

Demande du directeur (12/11/2026) : la bibliothèque est pour chaque profil élève, adulte ou enfant. Le Coran est **un document** de la bibliothèque, pas la bibliothèque. En haut, les documents fournis gratuitement par l'académie ; en bas, une autre partie pour les autres documents, vendus plus tard : on prépare la place, **sans vente**.

## Vérité d'abord

Ce qui est faux, bloqué, non testé ou non prouvé est dans la dernière section. Un test vert n'est pas une preuve de production : rien de ce lot n'est installé ni vu en production.

## Ce que j'ai réutilisé

| Existant | Usage |
|---|---|
| `library_resource`, `resource_version`, `download_asset`, `library_resource_groupe`, `library_version_rights` (0032, CAP-29) | un seul catalogue ; aucune table de documents créée |
| Circuit de la direction (`library_creer_brouillon`, `library_mettre_a_jour`, `library_controler_version`, `library_publier_version`, `library_attribuer`, `library_get_detail`) | étendu, pas doublé |
| `bibliotheque_catalogue_lecteur` (N4, 20261108200000) et `private.n4_manifeste` | **étendus à signature égale** : aucune lecture concurrente, aucune fonction à retirer au lot 10 |
| `autoriser_lecture_version` et la fonction Edge `bibliotheque-lecture` | la chaîne « document publié → droit vérifié → URL signée » existait côté serveur ; elle n'avait aucun appelant Flutter |
| Intention de dépôt en deux temps et confirmation signée (`bibliotheque-upload`, `library_upload_confirmation_secrets`) | repris tel quel pour la vignette |
| `description` de `library_resource` (20261016102100) | sert de description de carte : aucune colonne en double |
| `PortVersionsRessource`, `PortTelechargement.lienLecture`, `LecteurArtefact`, `OuvreurOnglet`, `RenduRessource` | branchés en production par trois adaptateurs Supabase |
| `SurfaceBibliotheque`, `CarteRessource`, `DetailRessourcePage`, formulaire `ImportPage` et fiche de la direction | étendus |
| Lecteur du Coran (`features/tc_mushaf`) | le Coran est une fiche du catalogue qui y mène (`Routes.eleveCoran`) |

## Ce que j'ai créé

**Serveur** (`supabase/migrations/20261123920000_bibliotheque_une_types.sql` puis `20261123921000_bibliotheque_une.sql`) :

- les types `audio`, `video`, `external_link` (fichier 1, seul, car une valeur d'enum ajoutée ne s'emploie pas dans sa transaction) ;
- `library_rayon` : les deux rayons **en donnée**, fr et ar (« Documents des cours » / وثائق الدروس, « Pour aller plus loin » / للتعمّق أكثر), lisibles de tout compte valide ;
- sur `library_resource` : `rayon`, `ordre`, `lien_externe` (https, hôte en nom de domaine, ni IP ni identifiants, validé par une contrainte), `vignette_cle`, `etapes` (tableau de **codes stables en texte**, aucune clé étrangère vers une version du programme) ;
- dépôt de vignette en deux temps (`demander_`, `lire_`, `confirmer_`, `annuler_vignette_bibliotheque`), avec la même confirmation signée que le fichier d'un document ;
- trois lectures du lecteur : `bibliotheque_rayons_lecteur()`, `bibliotheque_version_lecteur(uuid)` (version publiée courante et fichier décrit, **sans clé de stockage**), `bibliotheque_vignettes_autorisees(uuid[])` (clés à signer, pour la seule fonction Edge) ;
- le contrôle de publication (`app_private.library_controle_version`) tient compte d'un document donné par lien (pas de fichier à sonder ni d'empreinte), et d'une étape comme rattachement au programme ;
- le Coran, semé par `app_private.library_semer_coran()` (idempotente) : document du rayon des cours, publié, visible des inscrits.

**Fonctions Edge** : `bibliotheque-upload` (actions `demander_vignette`, `confirmer_vignette`, `annuler_vignette` ; image de 2 Mio au plus) ; `bibliotheque-lecture` (action `vignettes` : URL signées pour les seuls documents que l'appelant lit).

**Application** :

- `LibraryResource` : types audio, vidéo, lien externe ; description, lien, ordre, rayon (code), étapes, indicateur de vignette. `RayonBibliotheque`. `PortCatalogue.rayons()` et les filtres `rayon` et `etape`.
- `CatalogueSupabase` : lit tout le catalogue par pages de 200 (`decalage`), les rayons ; `VersionsSupabase`, `TelechargementSupabase` (version, URL de lecture, octets) et `VignettesSupabase` (appels regroupés, un seul par écran), branchés dans `lib/main.dart` ;
- fiche d'un document : un audio s'ouvre par l'URL signée (web) ; un lien externe ou une vidéo par lien s'affiche en petite carte (adresse https, phrase « s'ouvre sur un autre site », bouton seulement sur le web) ; sans lecteur, la phrase le dit, jamais un bouton qui ferait semblant ; le Coran propose « Ouvrir le mushaf » ;
- la vignette déposée se pose par-dessus la couverture par défaut du type ;
- direction : le formulaire existant porte type (audio, vidéo, lien externe), description, rayon (choisi parmi ceux du serveur), ordre, étapes (codes séparés par des virgules), adresse du lien, vignette ; la fiche les édite et retire la vignette ;
- textes : le mot « support » ne s'affiche plus dans `tc.bibliotheque.*` ni `admin.bibliotheque.*` (fr et ar : « document » / وثيقة).

## Mes choix

1. **Lecture du lecteur étendue en place** (même signature, mêmes réponses pour les anciens filtres) plutôt qu'une fonction sous un nouveau nom. Pagination : filtre `decalage`, page suivante = décalage + limite. La réponse reste un tableau.
2. **« Document »** n'est pas une valeur d'enum de plus : c'est la famille `pdf` + `structured_text` (+ `lesson`), exposée côté Flutter par `TypeRessource.estDocument`. Le filtre de l'élève (lot 5) groupe ainsi sans doubler une valeur.
3. **Aucune colonne de prix.** Le plan permettait « une colonne invisible » ; je n'en prépare aucune : le second rayon est une place, rien de plus. Le contrôle de sortie de la migration refuse toute colonne dont le nom évoque un prix, et le scénario refuse une clé `prix` en entrée.
4. **Vidéo : par lien seulement.** La fonction Edge charge le fichier entier en mémoire pour en vérifier l'empreinte et le type réel ; l'audio (100 Mio) est déjà à la limite, une vidéo ne tient pas. Un document `video` porte donc `lien_externe`. Si un dépôt de vidéo est voulu un jour, il faut un dépôt fractionné ou un autre hébergeur : décision à part.
5. **Étapes en texte libre pour l'instant.** Le code est saisi par la direction ; une liste fermée viendra des étapes du lot 1.
6. **Le Coran n'a pas de fichier** : sa version est publiée sans artefact, et la fiche ouvre le lecteur du Coran existant. Sa ligne de droits est un amorçage technique qui renvoie à « À propos de l'édition » du lecteur : la direction doit la confirmer, je n'affirme aucune licence.
7. **Rattachement à une classe** : le circuit existant (publication, puis attribution) est inchangé. Une version publiée passe de `admin` à `groupe_assigne` ; pour qu'un document de l'académie soit lu de tous les inscrits, la direction le met en visibilité « inscrits » depuis sa fiche.

## Écarts entre le plan et le code, et avec la demande

- Le plan (lot 3) parle de « Documents des cours » en haut et « Pour aller plus loin » en bas **sur l'écran de l'élève** ; la demande à l'agent réserve la planche (grille ou liste, filtres) au lot 5 et l'espace « Apprendre » au lot 4. `SurfaceBibliotheque` garde donc ses sections ; les rayons sont servis en donnée et prêts (`PortCatalogue.rayons()`, `LibraryResource.rayon`), pas encore mis en page.
- Le plan dit « retiré : l'étagère de la salle » : c'est dans la zone interdite (`salle_*`), laissée à l'architecte. Rien de la salle n'est touché ; elle lira `bibliotheque_catalogue_lecteur` quand l'architecte la branchera.
- Le plan dit que le **lien externe** s'affiche en carte au lot 4 ; la carte existe ici (fiche), le lecteur unique reste au lot 4.

## Ce qui est réellement fait et testé

Voir la fin du rapport à l'architecte ; les chiffres exacts de chaque vérification y sont, jamais ici (ils changent à chaque correction).

Tests ajoutés : `supabase/tests/scenarios_bibliotheque_une.sql` (droits par visibilité, types, lien externe, rayons, étapes, Coran, filtres, pagination, vignette signée, chaîne de lecture, droits d'exécution) ; `test/features/tc_catalogue/bibliotheque_une_test.dart` (par le routeur réel : les cinq états, les nouveaux types, aucun mot « support » en fr et en ar, fiche d'un lien, d'un audio, du Coran) ; `test/features/admin_pedagogie_bibliotheque/bibliotheque_une_admin_test.dart` ; `supabase/functions/_shared/r2/bibliotheque_upload_test.ts`.
Corrections de tests existants dues au lot : `scenarios_contrats_bibliotheque.sql` (« video » n'est plus un type inconnu), `scenarios_af_liste_blanche_volatiles.sql` (les quatre fonctions de vignette), `contrats_test.dart`, doubles de démonstration de la direction, fakes de `PortCatalogue`, aide de défilement de `fiche_test.dart`.

## Ce qui est faux, bloqué, non testé ou non prouvé

- **BLOQUANT pour tout dépôt de fichier et de vignette en production (relevé en lecture seule le 12/11/2026) : `private.library_upload_confirmation_secrets` est VIDE.** La confirmation d'un dépôt (celui d'un audio, d'un PDF, d'une image, et la vignette) vérifie une signature que seule la fonction Edge peut produire avec son secret `LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY` ; sans ligne en base portant le **même** secret (32 octets au moins), la base refuse chaque confirmation (`BibliothequeUploadConfirmationNonAutorisee`). C'est antérieur au lot (migration 20261012184000 : « jamais de vrai secret dans une migration »). Ce qu'il faut, par une personne habilitée et hors dépôt : poser le secret côté Edge **et** insérer la même valeur dans cette table. Tant que c'est fait, la direction peut déposer un **lien externe** ou une **vidéo par lien** (aucun dépôt), mais pas un audio ni une vignette. Je n'y ai pas touché.
- État de la production relevé le même jour : 0 document, 5 types (avant le lot), 1 compte direction actif (le Coran sera donc semé à l'installation), les sept fonctions que le lot remplace ou étend présentes.
- **Rien n'est prouvé en production.** Rien n'est installé ni déployé. Les fonctions Edge ne sont testées qu'au type (deno check) et sur leurs fonctions pures ; **ni R2, ni la signature d'URL, ni la confirmation signée de la vignette n'ont tourné de bout en bout** (aucun stockage ici).
- **Ouverture d'un lien et d'un audio : navigateur seulement.** L'application n'a pas de paquet pour ouvrir un lien hors navigateur (`url_launcher` n'est pas une dépendance directe, et `pubspec.yaml` est protégé par le garde-fou, que je n'ai pas contourné). Sur un appareil sans navigateur, la fiche montre l'adresse et le dit ; aucun bouton.
- **Lien externe et enfants** : aucune règle n'est décidée sur le fait qu'un compte enfant voie un lien vers un autre site. Le serveur applique la même visibilité qu'aux autres documents. À trancher par l'architecte.
- **`ressources_du_groupe`** (l'onglet de la classe) n'est pas étendue : ses cartes n'ont ni description, ni vignette, ni rayon tant que cette lecture n'est pas reprise.
- **Mot « support »** : il reste dans `recherche.*` (domaine « Supports » de la recherche, quatre libellés), `classe.*`, `enseignant.ficheGroupe`, `tc.realtime`, `tc.observation`, `com.*`, `accessibilite.apres`, `compte.tuteur.pageAide` (« Aide et support » : sens différent, à garder) : hors de la bibliothèque ou dans la zone d'une autre session ; non touchés.
- **Vignette remplacée ou retirée** : l'ancien objet reste dans R2 (aucune purge).
- **Arabe** : traduit sans relecture par un locuteur natif.
- **Captures** : voir le rapport.
