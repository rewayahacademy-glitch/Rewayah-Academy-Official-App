# Lot 3 · BIBLIOTHEQUE-UNE

Branche `claude/bibliotheque-une`. Agent du lot 3, sous l'autorité de l'architecte pédagogique, qui ouvre la pull request, fusionne et déploie. Écrit le 12/11/2026, complété le même jour après les décisions D1 à D5 et les corrections C1 à C6 de l'architecte pédagogique.

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
- le Coran, semé par `app_private.library_semer_coran()` (idempotente) : document du rayon des cours, publié, visible des inscrits, lecture `hafs` ;
- **D1, tranches d'âge** : `library_resource.tranches` (6-9, 10-13, 14-17, adultes ; les quatre par défaut, le lien externe sans les 6-9 ans par défaut). Le filtre vit **dans la base** : la règle de lecture de `library_resource`, `private.n4_ressource_lisible`, `bibliotheque_catalogue_lecteur` (et son filtre `eleve`) et la chaîne de lecture d'un fichier (`autoriser_lecture_version`) lisent la même fonction `private.tranche_autorisee`. L'élève voit sa tranche (un mineur sans tranche : la plus jeune, par prudence) ; le tuteur voit ce que voit un enfant de son foyer, ou ce qui s'adresse aux adultes ; l'enseignant et la direction voient tout ce que leur visibilité permet ;
- **D2** : `lecture_coran` (`hafs`, `warsh`, `qalun`, `shuba`, le vocabulaire des candidatures) et `ecole_priere` (texte libre, 80 caractères au plus), facultatifs, filtrables côté direction (`lectureCoran`, `ecolePriere`), montrés sur la fiche quand ils sont remplis ;
- **D3** : `bibliotheque_etapes_publiees()` (direction seulement) lit les étapes du programme publié de la branche `claude/socle-programme` (`programme_niveaux.code_technique`, `nom_humain`, `cycle`, `ordre`, version `publiee`) **si ses tables existent** (`to_regclass`), sinon rend une liste vide. Les codes restent du texte en base ; la direction les coche, elle ne les tape plus. Sans programme publié : « Les étapes apparaîtront quand le programme sera publié » ;
- **C2** : `bibliotheque_depot_actif()` (direction seulement) dit si le secret de confirmation existe en base, jamais sa valeur.

**Fonctions Edge** : `bibliotheque-upload` (actions `demander_vignette`, `confirmer_vignette`, `annuler_vignette` ; image de 2 Mio au plus) ; `bibliotheque-lecture` (action `vignettes` : URL signées pour les seuls documents que l'appelant lit).

**Application** :

- `LibraryResource` : types audio, vidéo, lien externe ; description, lien, ordre, rayon (code), étapes, indicateur de vignette. `RayonBibliotheque`. `PortCatalogue.rayons()` et les filtres `rayon` et `etape`.
- `CatalogueSupabase` : lit tout le catalogue par pages de 200 (`decalage`), les rayons ; `VersionsSupabase`, `TelechargementSupabase` (version, URL de lecture, octets) et `VignettesSupabase` (appels regroupés, un seul par écran), branchés dans `lib/main.dart` ;
- fiche d'un document : un audio s'ouvre par l'URL signée (web) ; un lien externe ou une vidéo par lien s'affiche en petite carte (adresse https, phrase « s'ouvre sur un autre site », bouton seulement sur le web) ; sans lecteur, la phrase le dit, jamais un bouton qui ferait semblant ; le Coran propose « Ouvrir le mushaf » ;
- la vignette déposée se pose par-dessus la couverture par défaut du type ;
- direction : le formulaire existant porte type (audio, vidéo, lien externe), description, rayon (choisi parmi ceux du serveur), ordre, **tranches d'âge** (cases ; le lien externe décoche les 6-9 ans d'emblée et le dit), **étapes du programme publié** (cases), **lecture du Coran** (menu) et **école suivie** (texte court), adresse du lien, vignette ; la fiche les édite et retire la vignette ; le catalogue se filtre par lecture. Les mêmes champs (`classement_document.dart`) servent « Ajouter un document » et la fiche ;
- **D4** : pour une vidéo, le formulaire écrit « Pour une vidéo, collez son lien. » ;
- **C2** : tant que le secret n'est pas posé, l'écran « Ajouter un document » dit « Le dépôt de fichiers n'est pas encore activé. Vous pouvez déjà ajouter un document par son lien. », ne rend aucun bouton de fichier, de vignette ni de preuve, et le lien externe se poursuit normalement ; si le serveur répond 503 au dépôt, la même idée s'affiche (« rien n'a été envoyé ») au lieu d'un code ;
- l'ouverture d'un lien externe passe **toujours** par une feuille de confirmation (« Ce lien quitte l'application » : Ouvrir le lien / Rester dans l'application) ;
- la fiche d'un document montre « Lecture du Coran » et « École juridique suivie » quand elles sont remplies, rien sinon ;
- textes : le mot « support » ne s'affiche plus dans `tc.bibliotheque.*` ni `admin.bibliotheque.*` (fr et ar : « document » / وثيقة).

## Mes choix

1. **Lecture du lecteur étendue en place** (même signature, mêmes réponses pour les anciens filtres) plutôt qu'une fonction sous un nouveau nom. Pagination : filtre `decalage`, page suivante = décalage + limite. La réponse reste un tableau.
2. **« Document »** n'est pas une valeur d'enum de plus : c'est la famille `pdf` + `structured_text` (+ `lesson`), exposée côté Flutter par `TypeRessource.estDocument`. Le filtre de l'élève (lot 5) groupe ainsi sans doubler une valeur.
3. **Aucune colonne de prix.** Le plan permettait « une colonne invisible » ; je n'en prépare aucune : le second rayon est une place, rien de plus. Le contrôle de sortie de la migration refuse toute colonne dont le nom évoque un prix, et le scénario refuse une clé `prix` en entrée.
4. **Vidéo : par lien seulement.** La fonction Edge charge le fichier entier en mémoire pour en vérifier l'empreinte et le type réel ; l'audio (100 Mio) est déjà à la limite, une vidéo ne tient pas. Un document `video` porte donc `lien_externe`. Si un dépôt de vidéo est voulu un jour, il faut un dépôt fractionné ou un autre hébergeur : décision à part.
5. **Étapes : codes en texte, choisis et non tapés (D3).** Aucune clé étrangère vers une version du programme (le code est stable d'une version à l'autre) ; la direction coche dans la liste des étapes du programme publié. Une étape déjà rattachée mais absente de la liste reste visible et décochable : rien ne se perd en silence.
6. **Le Coran n'a pas de fichier** : sa version est publiée sans artefact, et la fiche ouvre le lecteur du Coran existant. Sa ligne de droits est un amorçage technique (C6) : voir « Le Coran et ses droits » plus bas.
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
- **Lien externe et enfants** : tranché par l'architecte (D1) et appliqué : les 6-9 ans sont exclus par défaut d'un lien externe, la direction doit les cocher explicitement, et l'ouverture demande toujours une confirmation. Non prouvé en production.
- **`ressources_du_groupe`** (l'onglet de la classe) n'est pas étendue : ses cartes n'ont ni description, ni vignette, ni rayon tant que cette lecture n'est pas reprise.
- **Mot « support »** : il reste dans 29 textes visibles, hors de la bibliothèque ou dans la zone d'une autre session (liste exacte dans « Mot support, liste exacte » plus bas) ; non touchés, comme demandé (D5).
- **Vignette remplacée ou retirée** : l'ancien objet reste dans R2 (aucune purge).
- **Arabe** : relu deux fois par moi, jamais par un locuteur natif ; les textes incertains sont signalés dans « Arabe : relecture ».
- **Captures** : voir le rapport.

## Installation et secret, en mots simples (C1)

Rien de ce qui suit n'a été fait par un agent : aucun secret n'a été posé, aucune fonction déployée, aucune migration installée.

**1. La fusion dans `main` déploie l'application ET les fonctions Edge, les migrations restent manuelles : les deux migrations doivent donc être installées AVANT la fusion (ordre imposé, revue I1).** Le fichier `.github/workflows/deploy.yml` a un travail « Edge Functions » : à chaque poussée sur `main` (et sur les étiquettes `v*`), il déploie **toutes** les fonctions du dossier `supabase/functions/` sur le projet de production, donc `bibliotheque-upload` et `bibliotheque-lecture` modifiées par ce lot, puis vérifie que chacune est en ligne. Il refuse de partir si le secret GitHub `SUPABASE_ACCESS_TOKEN` manque. **Je n'ai pas pu vérifier** que ce secret GitHub existe ni que ce travail a tourné avec succès récemment (je n'ai pas accès à GitHub Actions) : le fichier le dit, la preuve est à lire dans l'onglet Actions après la fusion. L'ouverture d'une fonction se règle par fonction dans `supabase/config.toml` : les deux fonctions du lot y sont déjà en `verify_jwt = true`, rien à changer.

**2. Les migrations ne partent pas toutes seules.** Dans `deploy.yml`, le travail « Migrations » ne se lance qu'à la main (`workflow_dispatch`, case « appliquer les migrations »), et la base de production enregistre des versions horodatées : c'est le pilote qui installe, comme pour les autres lots. Les deux fichiers de ce lot ne contiennent ni `DROP`, ni `DELETE`, ni `TRUNCATE` (compte : 0), donc l'outil d'installation ne demande pas de seconde confirmation.

**3. Le secret du dépôt de fichiers : à poser par le directeur, une seule fois, en deux endroits qui doivent porter la même valeur.**

- **Côté fonctions (Edge)** : Supabase, projet de production, Edge Functions, Secrets. Nom exact : `LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY`. Valeur : une longue chaîne aléatoire, 32 caractères au moins, sans espace au début ni à la fin (la fonction refuse sinon). C'est le même écran que pour les secrets des courriels (`docs/current/COURRIELS.md` §3).
- **Côté base** : Supabase, SQL Editor, une seule instruction, avec **la même valeur** à la place de `LA_MEME_VALEUR` : `insert into private.library_upload_confirmation_secrets (secret) values ('LA_MEME_VALEUR') on conflict (singleton) do update set secret = excluded.secret, changed_at = clock_timestamp();`. La table n'est lisible de personne (aucun droit pour l'application ni l'agent) ; la valeur ne s'écrit jamais dans un fichier du dépôt ni dans une conversation.

**Ordre imposé.** (a) le pilote installe `20261123920000_bibliotheque_une_types.sql`, puis `20261123921000_bibliotheque_une.sql` (après `20261123820000`, `830000` et `840000` de `main`) ; (b) la fusion dans `main` déploie l'application et les fonctions Edge ; (c) le directeur pose le secret des deux côtés ; (d) il ouvre « Ajouter un document » : la phrase « Le dépôt de fichiers n'est pas encore activé » doit avoir disparu. Si l'on fusionnait avant (a), l'application neuve appellerait des fonctions qui n'existent pas encore (lectures du lecteur, dépôt de vignette) : écrans en erreur. Si l'on pose le secret avant (b), rien ne casse : le dépôt reste refusé par l'ancienne version.

**L'autre sens : l'application de `main` (ancienne) contre la base migrée (lecture du code, aucun test ne le prouve).**
- Côté élève : `lib/core/tc_bibliotheque/library_resource.dart:198-203` (version de `main`) replie un type inconnu (`audio`, `video`, `external_link`) sur `lecon` au lieu de planter ; les clés ajoutées au manifeste sont ignorées. Un tel document apparaît donc comme une « leçon » sans lien (rendu des leçons, `rendu_ressource.dart:70-72`), pas comme une erreur. Le Coran (type déjà connu) s'affiche.
- Côté direction : `lib/core/admin/bibliotheque_admin_supabase.dart:503-505` lève `FormatException('Type de ressource inconnu.')` sur un type inconnu, et le catalogue de la direction (`supportCatalogueJson`, lignes 364 et 411) en dépend : **dès qu'un document audio, vidéo ou lien externe existe, l'ancien écran du catalogue de la direction tombe en erreur.** Aucun tel document ne peut exister avant le déploiement de la nouvelle application (seul son formulaire en crée), et le Coran semé est du type `quran`, connu : l'ancienne application ne casse donc pas dans la fenêtre entre l'installation des migrations et la fusion. Le risque réel est un retour en arrière de l'application après la création d'un document de ces types.

**Ce que l'écran sait et ne sait pas.** La phrase « pas encore activé » se lit dans la base (la ligne du secret existe-t-elle ?). Si la base l'a mais que la fonction n'a pas son secret, le dépôt est refusé par un 503 et l'écran dit alors « le dépôt de fichiers n'est pas encore activé : rien n'a été envoyé » au moment du dépôt, jamais un code brut. Dans les deux cas, le lien externe et la vidéo par lien marchent. **Aucun dépôt de fichier n'a tourné de bout en bout** : ni R2 ni la signature n'ont été essayés ici.

## Correctifs de la revue indépendante

**B1, protection des mineurs (corrigé).** `ressources_du_groupe` (l'onglet de la classe) était `SECURITY DEFINER`, rendait `r.*` et n'appliquait ni la tranche d'âge ni `n4_ressource_lisible` : avec les colonnes de ce lot, un enfant de 6 à 9 ans (ou son tuteur) d'une classe à laquelle la direction attribue un lien externe en recevait l'adresse et la clé de vignette. Corrigé dans `20261123921000` (section 7 ter), même signature, mêmes noms de colonnes : la liste est en plus bornée par `n4_ressource_lisible` (tranche, accès payé, politique), et les colonnes **ajoutées par ce lot** (lien externe, clé de vignette, rayon, ordre, étapes, tranches, lecture, école) sont rendues nulles ; la ligne garde ses colonnes d'origine. L'application de `main` lit les mêmes noms d'origine (`title`, `resource_type`, …) : elle ne perd rien. Scénarios (`5 ter`, rouge avec l'ancienne fonction, vérifié par mutation) : l'enfant de 6 à 9 ans ne reçoit ni le lien ni le document d'adultes, aucune adresse ni clé n'est rendue à personne, le tuteur adulte voit les documents d'adultes sans adresse, l'élève d'une autre classe est refusé.

**Autres lectures de `library_resource` qui contournaient la tranche** (recherche faite sur toutes les fonctions `SECURITY DEFINER` de la base de test, schémas `public`, `private`, `app_private`) :
- `rech_d1_rechercher_supports` (recherche) : **contournait la tranche** (copie de la règle de lecture sans elle) ; rendait titre, catégorie et identifiant, jamais l'adresse ni la clé. Corrigée par une ligne ancrée dans la même migration (le texte installé est lu, l'ancre doit s'y trouver une fois). Scénario : un enfant de 6 à 9 ans ne trouve plus le titre d'un document d'adultes ni du lien par défaut. **Non traité, hors lot : cette recherche n'applique pas non plus l'accès payé.**
- Conformes (passent par `n4_ressource_lisible`, donc tranche) : `bibliotheque_catalogue_lecteur`, `bibliotheque_recents_lecteur`, `bibliotheque_reprise_lecteur`, `bibliotheque_version_lecteur`, `bibliotheque_vignettes_autorisees` ; `autoriser_lecture_version` (garde de tranche ajoutée par ce lot).
- Réservées à la direction (porte positive `admin`, voient tout par nature) : `library_get_catalogue`, `library_get_catalogue_facettes`, `library_get_detail`, `library_creer_brouillon`, `library_mettre_a_jour`, `library_nouvelle_version`, `library_publier_version`, `library_retirer`, `library_attribuer`, `library_classes_attribuables`, `admin_library_review_rights`, `demander_upload_bibliotheque`, et les fonctions de ce lot (`bibliotheque_depot_actif`, `bibliotheque_etapes_publiees`, `library_mineurs_sans_cohorte`, vignettes).
- **Non vérifié** : `publier_etat_partage` (écriture de l'enseignant ou de la direction dans la salle) ne lit pas `library_resource` ; ce que la salle montre ensuite aux élèves est dans la zone salle, que je ne touche pas.
- Les lectures `SECURITY INVOKER` passent par la politique `library_resource_lecture`, qui porte la tranche.

**I3, le Coran reste ouvert (écrit).** Règle du 04/11/2026 (`20261104600000`) : l'accès payé ne ferme pas le Coran. L'exception est écrite pour le seul document de type Coran, dans la politique `library_resource_lecture` et dans `n4_ressource_lisible` (les deux restent identiques, vérifié par le scénario) : un compte suspendu pour impayé lit exactement le Coran et rien d'autre. **Le Coran est semé publié hors du contrôle de publication** (`library_publier_version` exige un fichier, son empreinte et une preuve de droits) : il n'a aucun fichier à sonder (le texte est dans le lecteur du Coran de l'application) et sa ligne de droits est un amorçage technique, voir plus bas.

**I4, mineur sans tranche (gardé, arbitré).** Un mineur sans tranche est traité comme un 6-9 ans (le plus strict). La direction dispose de `library_mineurs_sans_cohorte()` (nombre d'élèves mineurs sans tranche, sans les nommer, direction seulement, testé). **Dette nommée : aucun écran ne l'affiche encore** (il faut un emplacement décidé par l'architecte, pas une page de plus).

**I5, `bibliotheque_vignettes_autorisees`.** Elle ne rend les clés que des documents que l'appelant peut lire (porte, accès payé, tranche d'âge de `n4_ressource_lisible`). Le commentaire disait « l'application ne voit jamais une clé » : faux dans la lettre, puisque tout compte authentifié peut l'appeler directement ; corrigé. La clé est un chemin d'objet privé qui n'ouvre rien sans URL signée.

**I7, séparation de domaine de la signature.** Le message signé d'une vignette commence par `bibliotheque-vignette-v1` (base : `confirmer_vignette_bibliotheque` ; Edge : `signatureConfirmationUpload(…, DOMAINE_VIGNETTE)`) ; celui d'un fichier de document n'a pas de préfixe (sa fonction, `confirmer_upload_bibliotheque`, est déjà installée et couverte par ses propres scénarios : je ne la remplace pas). Les deux messages ne peuvent pas se confondre : une signature faite pour l'un est refusée par l'autre (scénario côté base, test Deno côté Edge). La comparaison garde le motif existant (égalité sur la valeur attendue recalculée par la base) ; je ne prétends rien sur son temps d'exécution.

**I8, objets orphelins dans R2 (dette nommée).** Aucune purge : un objet reste dans R2 quand une vignette est remplacée ou retirée, quand une confirmation est refusée après l'écriture de l'objet, et quand une intention expire. Cas à connaître : si le secret n'est pas le même des deux côtés (Edge et table de la base), l'objet est écrit dans R2, la base refuse la confirmation (`BibliothequeUploadConfirmationNonAutorisee`) et l'objet reste sans document. Rien ne le lit, mais il occupe de la place ; un balayage des clés `private/libraryupload/` plus anciennes que l'expiration des intentions est à écrire (lot à nommer).

**I9, arabe : « الرواية ».** Les trois textes de la lecture du Coran disent maintenant « الرواية » (titre du champ et du filtre, ligne de la fiche) et « لم تُحدَّد رواية » (aucune). **Le mot français reste à trancher par le directeur** : « Lecture du Coran » est le mot décidé ; les quatre valeurs (Hafs, Warsh, Qalun, Shuba) sont des riwayat, et les candidatures disent « riwaya ». Textes français concernés : `admin.bibliotheque.import.classement.lectureTitre`, `.lectureAucune` (« Aucune lecture précisée »), `tc.bibliotheque.detail.lecture`.

**Dépôt de fichiers sans réponse (I1).** Si la lecture de l'état du dépôt échoue, l'écran n'affiche plus les boutons de fichier : une phrase dit que l'état n'a pas pu être vérifié, et le lien externe reste possible (test `I1 : sans reponse sur le depot`).

## En trois lignes, pour le directeur : l'ordre et ce que l'on voit à chaque étape

1. **Les deux migrations d'abord** (le pilote : `20261123920000`, puis `20261123921000`). On ne voit encore rien de neuf dans l'application ; le Coran est semé comme document publié ; l'application de `main`, ancienne, marche comme avant.
2. **Puis la fusion** (elle déploie l'application et les fonctions Edge). La Bibliothèque montre les deux rayons, le Coran avec son titre arabe sur sa vignette, les liens, les audios et les vidéos ; « Ajouter un document » dit « Le dépôt de fichiers n'est pas encore activé » et ne propose ni fichier ni vignette, mais le lien externe et la vidéo par lien marchent.
3. **Enfin le secret, posé des deux côtés** (fonctions Edge et base, même valeur) : la phrase disparaît, les boutons de fichier et de vignette apparaissent. Si un seul côté est posé, le dépôt est refusé et l'écran le dit en mots simples, sans rien enregistrer.

## Coller les migrations dans l'éditeur SQL

- `20261123920000_bibliotheque_une_types.sql` : 18 lignes, 1 118 octets, trois `ALTER TYPE … ADD VALUE IF NOT EXISTS`. **Rejouable** (une valeur déjà là est ignorée). À exécuter **seul**, avant l'autre, et à valider avant de lancer la suite (une valeur d'enum ajoutée ne s'emploie pas dans la transaction qui l'ajoute).
- `20261123921000_bibliotheque_une.sql` : 1 850 lignes, 88 782 octets (46 caractères non ASCII, les deux titres arabes de rayon), se colle **en un seul bloc**, sans `BEGIN` ni `COMMIT` (aucun seul sur une ligne). Aucun mot `DROP`, `DELETE` ni `TRUNCATE` (compte en mots entiers : 0 ; trois occurrences en simple sous-chaîne, les noms de colonne `deleted_at` et `attisdropped`, qui ne sont pas des instructions). **Non rejouable** : `CREATE TABLE`, `CREATE FUNCTION` sans remplacement et `ADD COLUMN` échouent à la première instruction si les objets existent déjà. À ma connaissance, l'éditeur exécute un script en une seule transaction, donc un échec ne laisse rien ; **je n'ai pas pu le vérifier** (mes rejeux ont utilisé `psql`, qui n'est pas atomique). En cas d'échec, regarder l'état avant de relancer. La page de collage du directeur se fabrique par `tool/page_migrations/generer.py` (règle du 23/10/2026).

## Suites de la revue, 13/11/2026

**« Académie », jamais « école » pour Rewayah.** Aucun texte visible de ce lot n'employait « école » pour dire Rewayah (en arabe non plus). « École juridique » (le madhhab d'un document de prière) garde son sens, comme la charte le précise ; le message d'erreur dit désormais « le nom de l'école juridique » et non « l'école suivie ». Un commentaire de code disait « l'ordre de l'école » : corrigé en « l'académie ». Les commentaires SQL parlent de « l'école » de prière : sens juridique, inchangés.

**Arabe de contenu en police du Coran (`AppFontFamily.arabeMushaf`).** Nouveau repère unique `lib/core/tc_bibliotheque/contenu_arabe.dart` : un texte qui contient de l'arabe reçoit la police du Coran (les glyphes qu'elle n'a pas, lettres latines et chiffres, retombent sur la police des documents puis celle de l'interface) et le sens droite-gauche (le point final d'une description arabe se place du bon côté même dans une interface française). Ce que cela change :
- **lecteur** : la vignette du Coran porte son titre arabe « القرآن / الكريم » sur deux lignes, dans la police du Coran, à la place des initiales (une clé de texte, la même en français et en arabe) ; le titre et la description arabes d'un document, sur sa carte et sur sa fiche, sont dans cette police ; le texte français d'un autre document ne change pas ;
- **direction** : le titre arabe d'un document dans le catalogue de la direction ;
- **inchangé** : tout l'arabe d'interface (menus, boutons, libellés, titres de rayon) garde la police d'interface (test avec l'application en arabe) ; la page du Coran elle-même (le mushaf) n'est pas touchée.
- **Non fait, à dire** : le titre de la page (en-tête `PageShell`, composant partagé) et le champ de saisie d'un titre restent dans la police d'interface ; la valeur de « École juridique suivie » (texte libre) aussi ; une description arabe sans rien d'autre dans une interface arabe prend la police du Coran mais reste alignée comme le reste. Captures : `01`, `02`, `03`, `07`, `12`, `19`.

**La recherche et l'accès payé.** `rech_d1_rechercher_supports` vit dans une migration de `main` (celle de la recherche) mais ce lot la remplace déjà par une insertion ancrée : j'y ai ajouté l'accès payé, avec l'exception du Coran. Un élève suspendu pour impayé ne trouve plus rien dans les documents, sauf le Coran (scénario). Les autres domaines de la recherche (classes, personnes) ne sont pas touchés.

## Le Coran et ses droits (C6)

« Droits du Coran = amorçage technique » veut dire : pour que le Coran soit un document publié comme les autres, la base devait avoir une ligne de droits ; je l'ai remplie d'une phrase qui renvoie à « À propos de l'édition » dans le lecteur du Coran, **sans nommer de licence ni d'éditeur**. Ce n'est pas une preuve juridique : la direction doit confirmer, depuis la fiche du Coran, que la source et le titulaire des droits du texte et de la police affichés sont bien ceux de cette page, ou corriger la ligne.

Le semis est sûr et rejouable : `app_private.library_semer_coran()` ne crée rien si un document de type Coran existe déjà (elle rend son identifiant), ne fait rien et le dit s'il n'y a aucun compte direction actif (elle se rappelle ensuite), n'écrit aucun fichier, n'efface rien (zéro `DROP`, `DELETE`, `TRUNCATE`) et n'est exécutable que par la base (droits retirés à tous les rôles). Rejouée, elle laisse un seul Coran, une seule version publiée et une seule ligne de droits (scénario `scenarios_bibliotheque_une.sql`).

## Corrections de tests existants (C4)

Aucune garde de sécurité n'a été relâchée ; chaque test existant touché l'a été pour une raison précise :

- `supabase/tests/scenarios_contrats_bibliotheque.sql` : le test « type inconnu refusé » employait `"video"` comme exemple de type inconnu. `video` devient un type valide (c'est le but du lot) ; l'exemple devient `"hologramme"`. La garde (un type hors liste est refusé avec `22023`) est inchangée et reste vérifiée.
- `test/teaching_core/b/contrats_test.dart` : même exemple (`depuisSql('video')` rendait `null`) ; `hologramme` rend toujours `null`, et trois lignes vérifient que `video`, `audio` et `external_link` sont lus.
- `supabase/tests/scenarios_af_liste_blanche_volatiles.sql` : ce test impose que toute fonction exécutable par `authenticated` et marquée volatile soit nommée dans une liste blanche avec sa raison. J'y ai **ajouté quatre noms** (les fonctions de vignette), avec leur justification en commentaire. Le contrôle reste entier : toute autre fonction volatile non nommée le fait toujours échouer.
- Le contrôle B18 (« garde négative résiduelle dans une fonction SECURITY DEFINER ») était rouge sur ma première version : c'est **ma fonction** que j'ai corrigée (la permission de classe s'écrit `IS NOT TRUE` sur une valeur jamais nulle), pas le test.
- `test/i18n/ar_domaines_test.dart` : huit mots latins admis ajoutés (`https`, `MP3`, `MP`, `M4A`, `OGG`, `PNG`, `JPEG`, `WebP`, formats et protocole que l'arabe garde tels quels) ; le contrôle (aucun autre mot latin dans l'arabe) est inchangé.
- Aides de test : `fiche_test.dart` (le défilement vise la vraie page, pas le premier défilement venu, conforme à la décision du 01/11/2026), `support_classe.dart` (un double de port reçoit la méthode `rayons()` ajoutée à l'interface), doubles de démonstration de la direction (nouveaux champs). Aucune attente n'a été supprimée.

## Mot « support », liste exacte (D5)

Textes visibles qui contiennent encore « support » ou « supports » (fr), 29 au total, non touchés : `accessibilite.apres.revoirSupport`, `.revoirSupportDetail`, `.revoirSupportDetailVous` ; `recrutement.talents.c.conception_programmes.libelle`, `.description` ; `compte.tuteur.pageAide.titre` (« Aide et support », autre sens) ; `classe.pageRessources.aucuneDetail`, `classe.cartes.typesDetail.lien`, `classe.cartes.modeles.lien` ; `enseignant.ficheGroupe.supportPrevu`, `.supportsTitre` ; `controleur.observation.pedagogieAide` ; `tc.realtime.transport.partage_indisponible`, `tc.realtime.etat.restauration_impossible` ; `tc.observation.visite.supportIndisponible` ; `tc.parcours.plage.ressource` ; `com.communaute.demo.f.memorisationTexte`, `com.studio.sections.support`, `com.studio.demo.f.messageSupports`, `com.annonces.demo.f.adminStudioDecision`, `.adminStudioAssigne`, `.adminStudioContexte` ; `recherche.initial.phrase`, `recherche.domaines.supports`, `recherche.guide.titre`, `recherche.guide.initial.titre`, `.initial.phrase`, `recherche.guide.limite`, `recherche.entree.supports`.

`ressources_du_groupe` (l'onglet de la classe) est laissé au lot 5.

Les valeurs de `tc.bibliotheque.actif.*` que j'ai changées (le mot « support » devient « document » ; en arabe, « مادة » devient « وثيقة ») :

| Clé | Avant (fr) | Après (fr) |
|---|---|---|
| `aucun` | Aucun support présenté | Aucun document présenté |
| `aucunDetail` | Quand votre enseignant présentera un support, il apparaîtra ici sans rien faire de votre part. | Quand votre enseignant présentera un document, il apparaîtra ici sans rien faire de votre part. |
| `erreur` | Le support présenté n'a pas pu être chargé. Réessayez. | Le document présenté n'a pas pu être chargé. Réessayez. |
| `indisponible` | Le suivi du support présenté s'ouvrira au branchement serveur. | Le suivi du document présenté s'ouvrira au branchement serveur. |
| `indisponibleTitre` | Support présenté pas encore ouvert | Document présenté pas encore ouvert |
| `ouvrirFiche` | Ouvrir la fiche du support | Ouvrir la fiche du document |
| `retireDetail` | Votre enseignant a retiré ce support de la séance. Il n'est plus accessible. | Votre enseignant a retiré ce document de la séance. Il n'est plus accessible. |
| `sansDonnees` | le support présenté | le document présenté |
| `titre` | Support présenté | Document présenté |

Arabe, avant puis après : `titre` « المادة المعروضة » puis « الوثيقة المعروضة » ; `aucun` « لا توجد مادة معروضة » puis « لا توجد وثيقة معروضة » ; `ouvrirFiche` « فتح بطاقة المادة » puis « فتح بطاقة الوثيقة » ; même remplacement de « مادة » par « وثيقة » dans `aucunDetail`, `erreur`, `indisponible`, `indisponibleTitre`, `retireDetail`, `sansDonnees`.

## Arabe : relecture (C5)

Seconde relecture de tous les textes arabes du lot (sens, accord, sens d'écriture). Une correction : `ecoleLibelle` devient « المذهب الفقهي المتّبع (للصلاة والوضوء؛ اختياري) » (la liste « الصلاة، الوضوء » n'était pas une construction naturelle). Textes **incertains**, à faire relire par une personne arabophone :

1. « الرواية » pour « Lecture du Coran » (tranché par l'architecte, revue I9 : les quatre valeurs sont des **روايات**, et le reste de l'application dit « رواية حفص ») : le mot français, lui, reste à trancher par le directeur (voir plus haut).
2. « حدِّد » pour « Cochez » (cases à cocher) : correct et courant, mais « ضع علامة على » est plus explicite ; je garde « حدِّد » par concision.
3. « أكاديمية رواية » (nom de l'académie dans la feuille de confirmation d'un lien) : le reste de l'application dit « رواية » seul ; vérifier la graphie voulue du nom.
4. « المذهب الفقهي » pour « école juridique » : terme standard, à confirmer qu'il convient au public visé.
5. L'accord des phrases (« الفصول المسندة إليها الوثيقة », « فئة عمرية واحدة ») et le sens d'écriture (320 px, texte ×2, sens inversé) sont relus et testés ; les chiffres 6 et 9 sont écrits en chiffres occidentaux, comme ailleurs dans l'application.
