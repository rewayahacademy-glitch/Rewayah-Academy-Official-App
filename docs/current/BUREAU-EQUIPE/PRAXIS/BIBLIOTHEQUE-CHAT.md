# La Bibliothèque par Praxis, en conversation : l'inventaire, ce qui est livré, ce qui reste (PX-BD-Bibliothèque)

- **Statut** : PR serveur, migration `20261129970000`. Demande du directeur (17/11, 14 h 05, relayée par le pilote) : « ce n'est PAS le
  directeur qui dépose un fichier. C'est Praxis qui RÉDIGE le support avec lui dans le chat, puis le DÉPOSE et le CONFIGURE
  entièrement […] c'est Claude qui a créé la Bibliothèque et l'a rendue très compliquée avec des formulaires qu'un humain ne peut pas
  comprendre ; il devra jouer ce rôle-là ».
- Sources lues : `LOT-DEPOT-SIMPLE.md` (13/11), `library_creer_brouillon`, `library_mettre_a_jour`, `library_retirer`, `library_depot_direct`,
  la fonction Edge `bibliotheque-upload`, le lecteur (`lib/features/tc_catalogue/rendu_ressource.dart`), la base rejouée en local.

## 0. Faux, bloqué ou non prouvé (en premier)

1. **`support_deposer` N'EST PAS dans cette PR.** Il doit PRODUIRE un document et l'écrire dans le coffre R2, ce qu'aucune fonction SQL
   ne sait faire : il passera par la fonction Edge du connecteur (`praxis-mcp`), qui n'a aujourd'hui aucun outil d'écriture de fichier.
   Le **format** du document est une décision (§3), et le premier choix évident, « le PDF, qui s'affiche déjà », **a un défaut grave pour
   cette académie** : voir §3.
2. **Rien n'est prouvé en production, ni même installé.** La migration exige celle du socle (#626) ; scénario rejoué sur Postgres 16 neuf.
3. Les quatre actes livrés **ne créent aucun support** : ils lisent, corrigent, rangent et retirent des supports qui existent déjà (2 en
   production au 17/11, compteur).
4. **La visibilité « publique » n'est pas offerte au chat** (un support lisible sans compte) : seulement `inscrits` (défaut),
   `groupe_assigne`, `enseignant_seul`. Décision de prudence du livreur, à confirmer ; elle se lève par une ligne dans l'adaptateur.
5. L'attribution à des Classes (`library_attribuer`) n'est pas ouverte : le chat n'a aucun moyen de lire les identifiants des Classes
   (aucune lecture de Classes dans le socle). À ajouter avec `support_deposer`.
6. Le niveau d'un acte est celui qu'a demandé le pilote : modifier et ranger en A (immédiat, tracé, 60 par heure), retirer en S (lot, code
   à six chiffres lu en aal2 dans l'application, 10 par heure). **Publier n'a pas d'acte** : à l'état actuel de la Bibliothèque, un
   support créé est publié par le dépôt direct.

## 1. Ce qui est livré (quatre actes, clé de chat seulement, sous l'identité de la direction émettrice)

| Acte | Niveau | Appelle (telle quelle) | Paramètres (tout le reste est refusé) |
| :--- | :-: | :--- | :--- |
| `support_lister` | A | lecture de `library_resource` | `recherche` (60), `rayon` (`cours` ou `plus_loin`), `retires` (booléen), `limite` (1 à 50). Rend, par support : id, titre, type, rayon, ordre, visibilité, étapes, tranches, **révision**, retiré, publié |
| `support_modifier` | A | `library_mettre_a_jour` | `id`, `revision` (obligatoires) ; facultatifs : `titre`, `titre_court`, `description`, `edition`, `organisme`, `conditions_attribution`, `visibilite`, `politique_hors_ligne`, `tranches`, `etapes`, `lecture_coran`, `ecole_priere`. Un champ absent ne change pas ; une chaîne vide le retire |
| `support_deplacer` | A | `library_mettre_a_jour` | `id`, `revision` ; facultatifs : `rayon`, `ordre` (0 à 100000), `etapes` (20 au plus) |
| `support_retirer` | S | `library_retirer` | `id`, `revision`, `motif` (3 à 500 signes). **Retirer = masquer** (`archived_at`) : la ligne reste, **jamais effacée** |

Une **révision périmée** ne change rien et rend la révision actuelle (`revision_changee`) : le modèle relit avant de recommencer. Un
support modifié à la main entre la préparation d'un retrait et sa confirmation n'est **pas** retiré (scénario 5f).

## 2. L'inventaire du formulaire actuel, champ par champ, et ce que devient chacun pour le chat

(`LOT-DEPOT-SIMPLE.md`, section « Chaque champ », complété par le relevé des fonctions.) « Défaut » = ce que le serveur remplit seul.

| Champ du formulaire | Fonction qui le porte | En chat | Défaut |
| :-- | :-- | :-- | :-- |
| Fichier (type lu dans le contenu) | dépôt R2 (`demander_upload_bibliotheque` puis `confirmer_upload_bibliotheque`, signature HMAC) | **`support_deposer` (à venir)** : le contenu est rédigé, pas un fichier | sans objet |
| Nom / titre (200) | `library_creer_brouillon`, `library_mettre_a_jour` | `titre` | nom du fichier ; ici : à fournir |
| Titre court (60) | idem | `titre_court` | les 60 premiers signes du titre |
| Description (4000) ; exigée pour un lien | idem | `description` | vide |
| Langue | `library_creer_brouillon` | **non modifiable après coup** (aucune clé « langue » dans `library_mettre_a_jour`) | arabe si le titre est arabe, sinon la langue de l'interface |
| Rayon | idem | `rayon` (`cours` = Documents des cours, `plus_loin` = Pour aller plus loin) | `cours` |
| Ordre d'affichage | idem | `ordre` | 0 |
| Tranches d'âge (quatre cases) | idem | `tranches` | les quatre (trois sans les 6 à 9 ans pour un lien) |
| Étapes du programme | idem | `etapes` | aucune |
| Lecture du Coran, école juridique | idem | `lecture_coran` (`hafs`, `warsh`, `qalun`, `shuba`), `ecole_priere` | aucune |
| Édition, organisme, conditions d'attribution | idem | `edition`, `organisme`, `conditions_attribution` | vides |
| Visibilité | `library_mettre_a_jour` | `visibilite` : `inscrits`, `groupe_assigne`, `enseignant_seul` | `inscrits` (dépôt direct, accord du 13/11) |
| Lecture hors ligne | idem | `politique_hors_ligne` (`jamais`, `sur_demande`, `automatique`) | `jamais` |
| Accès au fichier (lecture seule ou téléchargement) | `library_changer_acces` ; droits de la version | **non ouvert** (suit le dépôt) | lecture dans l'application seulement |
| Droit de diffuser (« Pour aller plus loin ») | `library_depot_direct(p_droit_tiers)` | **jamais donné par le modèle** (DB6) : affirmation du directeur, par le code | sans objet |
| Classes | `library_attribuer` | **non ouvert** (§0.5) | aucune |
| Vignette | `demander_vignette_bibliotheque`, `confirmer_vignette_bibliotheque` | **non ouvert** (un fichier image) ; se règle dans l'application | couverture selon le type |
| Source, titulaire, attribution, usages, revue des droits, publication | `library_depot_direct` | faits par le dépôt direct, côté serveur | « Rewayah Academy », application et classe |

## 3. `support_deposer` : le format, la décision qui manque

La Bibliothèque ouvre un document **dans l'onglet du navigateur par un lien signé** (`_RenduLecture`, `contentDisposition: 'inline'`) et n'accepte
au dépôt que **PDF, image (PNG, JPEG, WebP) et audio (MP3, M4A, OGG)** (`mimeAnnonceAutorise`, relevé dans la fonction Edge ; le type enregistré
`mime_annonce` n'a pas de contrainte de type côté base, à confirmer au moment du lot). Le type de ressource `structured_text` existe dans la base
et se rend par le même lien.

| Option | Ce que c'est | Pour | Contre |
| :-- | :-- | :-- | :-- |
| **A. PDF généré par le serveur** | La fonction Edge compose un PDF et le dépose comme n'importe quel PDF | Déjà accepté, déjà affiché, rien à changer côté lecteur | **L'écriture arabe n'est pas composée par les bibliothèques de PDF courantes** : pas de liaison des lettres, pas de sens de lecture mixte arabe/latin, **vocalisation (tashkîl) mal posée**. Une police arabe est dans le dépôt (`assets/fonts/NotoSansArabic`, `UthmanicHafs`), le moteur de composition manque. Pour un texte coranique, **un rendu faux n'est pas acceptable**. Aucune bibliothèque choisie ni essayée ici |
| **B. Page HTML** | La fonction Edge génère une page à partir du texte structuré (titres, listes, versets), enregistrée en `text/html` | Le navigateur compose l'arabe et la vocalisation correctement, sans moteur à ajouter ; fonctionne dans le lecteur actuel (même lien) | `text/html` n'est accepté nulle part : à ajouter à la liste de la fonction Edge (et à vérifier côté base) ; une page servie depuis le coffre est du **contenu exécutable** : n'engendrer que du texte échappé, sans script, avec une politique de contenu dans la page ; non essayé ici |
| **C. Texte rendu par l'application** | Le texte est gardé comme Markdown, l'application le compose avec ses polices (Uthmani pour le Coran) | La meilleure composition, hors ligne possible, aucun contenu exécutable | Un nouveau lecteur dans l'application (`lib/`), un type `text/markdown` à accepter ; le plus gros des trois |

**Recommandation du livreur : B** pour commencer (le plus petit changement qui compose l'arabe juste), **C** comme cible. **Refuser A** pour tout
texte arabe ou coranique ; A resterait possible pour du texte latin seul, mais deux formats pour un même outil se paient plus tard.
**À décider par le pilote et le directeur avant le lot `support_deposer`.**

Le lot lui-même, une fois le format décidé, comprendra : un outil `support_deposer` dans la fonction Edge (paramètres fermés : `titre`, `corps`
structuré, `langue`, et la configuration de la section 2, chaque champ avec sa valeur par défaut dite dans la description) ; la création du brouillon
et du dépôt par les mêmes fonctions que l'écran, sous l'identité de la direction ; un acte S (ou A, selon la décision du pilote) pour la publication ;
la lecture du résultat par `support_lister`.

## 4. Preuves locales

`scenarios_praxis_actes_bibliotheque.sql` (rouge avant la migration : fonctions absentes ; vert après), six mutations rouges sur les adaptateurs
(visibilité publique offerte, retrait sans révision attendue, lister qui montre les retirés, motif court accepté, retrait qui écrit à sec) ;
listes fermées de `scenarios_sec1_praxis.sql` étendues (appels qualifiés, couples adaptateur > fonction de la Bibliothèque).
**Non mutable** : le mode « à sec » d'un acte de niveau A (jamais appelé par `agir`).

## 5. `support_deposer` (PX-BD-SUPPORT, 17/11/2026, option C du pilote)

Format retenu : un texte **Markdown fermé** (titres `#` à `###`, paragraphes, listes à puces et numérotées, gras, italique, citation, séparateur), analysé par le même jeu de 43 vecteurs en TypeScript (serveur) et en Dart (lecteur de l'application). Tout le reste est refusé avec un code (HTML, lien, image, tableau, code, barre, imbrication, titre trop profond, caractère de contrôle ou de direction forcée).

Chemin : l'outil `support_deposer` analyse, puis passe par le pont (`praxis_agir`, clé de chat, identité de la direction) : `depot_support_preparer` crée le **brouillon** et l'intention de dépôt ; la fonction Edge écrit l'objet dans R2 à la clé finale rendue par la base ; `depot_support_confirmer` confirme avec la signature HMAC que la base reverifie. Le support reste un **brouillon réservé à la direction** : la direction le publie elle-même.

Limites déclarées : 9 000 signes par appel (la requête du connecteur passe de 16 à 32 Kio) ; 100 000 octets au plus en base ; les versets saisis par un modèle ne sont jamais publiés sans contrôle (dit dans la description de l'outil) ; le dépôt humain n'accepte toujours pas `text/markdown` (la fonction Edge `bibliotheque-upload` est inchangée).
