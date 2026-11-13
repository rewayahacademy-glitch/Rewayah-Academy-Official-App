# LOT DEPOT-SIMPLE : ajouter un document, le strict nécessaire (13/11/2026)

Demande du directeur (13/11/2026), relayée par l'architecte pédagogique : « immense, je ne vais
jamais l'utiliser… ça doit rester le strict nécessaire… si l'app ne sait pas distinguer si un
document est un PDF ou audio alors ton app est nulle », puis : « aucune couleur pour indiquer si ça
a marché ou non, aucun message clair, "Fichier vérifié" ? c'est quoi ça ? », et : « auteur,
relecteur, etc., tout ça n'est pas très important et pas facile à traiter pour un humain ».

Branches : `claude/depot-nom-libre` (temps 1, PR #458 : tout nom de fichier passe, une phrase vraie
par cause) puis `claude/depot-simple` (temps 2 : ce lot).

## D'abord : ce qui est faux, bloqué ou non prouvé

- **Rien n'est prouvé en production.** Tout vient de tests locaux, d'un Postgres local et de
  captures prises sur le double de démonstration. La preuve est celle du directeur, après fusion.
- **La migration `20261124700000_depot_direct_direction.sql` doit être installée AVANT la fusion.**
  Sans elle, « Enregistrer le document » échoue (la fonction `library_depot_direct` n'existe pas) et
  l'écran dit que le document n'a pas pu être enregistré. Elle ne contient aucune suppression : elle
  peut passer par `apply_migration`.
- **La règle d'origine du seau (CORS) n'a jamais été vue par le lot.** La fonction la demande au
  seau (une requête `OPTIONS`, comme le navigateur) et nomme le réglage s'il manque ; ce contrôle
  est testé sur un seau simulé, pas sur Cloudflare.
- **Le scénario SQL du lot n'est pas dans la CI.** `.github/` est interdit aux agents : le pilote
  ajoute `supabase/tests/scenarios_depot_direct.sql` à `ci.yml`. Il est vert en local.
- **La langue d'un document ne se corrige pas après coup** : elle est déduite du nom (arabe si le
  nom est en arabe, sinon la langue de l'interface) et `library_mettre_a_jour` n'a pas de clé
  « langue ». La corriger demande une migration, qui n'est pas de ce lot.
- **L'accès (lecture seule ou téléchargement) d'un document déjà publié ne se change pas** sans
  créer une nouvelle version : il est porté par les droits de la version.
- **Le nom et la description d'un document publié ne se changent pas depuis sa fiche** : la règle
  d'avant ce lot (« version publiée et figée », CAP-29) n'a pas été touchée. Comme le dépôt direct
  publie aussitôt, corriger un nom demande aujourd'hui une nouvelle version, donc de redéposer le
  fichier. Le serveur, lui, accepte déjà la correction (`library_mettre_a_jour` ne demande qu'un
  document non retiré) : lever la règle à l'écran est une décision à prendre, pas un travail lourd.
  La vignette, elle, se change à tout moment.
- **DETTE POUR LE DIRECTEUR : tant que le paiement n'existe pas, un document de « Pour aller plus
  loin » est lisible par tout inscrit.** Aucun prix ni paiement n'est dans ce lot.
- **« Seulement certaines classes » n'est pas dans « Plus de réglages »** du formulaire : ce choix
  se fait toujours par l'écran d'attribution existant de la fiche, après l'enregistrement.
- **Un fichier téléchargé s'appelle `document.pdf`** (le nom du fichier du client n'est plus gardé
  nulle part côté serveur). Donner au téléchargement le nom saisi reste à faire.
- **Trois types déposables seulement** : PDF, audio (MP3, M4A, OGG), image (PNG, JPEG, WebP). Le
  « texte structuré » et la « leçon » (JSON) de l'ancien formulaire n'ont jamais pu se déposer (le
  serveur les refusait) : ils ne sont plus proposés. Une vidéo se donne par son lien.

## Décisions (architecte pédagogique, 13/11/2026, sur les mots du directeur)

1. **Un fichier et un nom suffisent, de bout en bout.** Le dépôt direct de la direction remplit
   côté serveur les droits restés vides, approuve la revue (trace : acteur, date, « dépôt direct de
   la direction »), ouvre le document aux inscrits et le publie. « Document enregistré. Il est
   visible dans la bibliothèque. » est vrai.
2. **Rayon « Documents des cours »** : source = le nom du document, titulaire et attribution =
   « Rewayah Academy », usages application et classe, niveau = tous.
3. **Rayon « Pour aller plus loin »** (document d'un tiers) : une seule case obligatoire,
   « L'académie a le droit de diffuser ce document », gardée avec l'acteur et la date. Le serveur
   refuse sans elle.
4. **Seule la direction** fait un dépôt direct (`app_role() = 'admin'`, comme tous les dépôts de la
   bibliothèque). Le contrôle de publication classique est inchangé pour tout le reste.
5. **Vocabulaire** : les rayons gardent les titres semés par le serveur. Jamais « Support », jamais
   « Autres ». Aucun prix, aucun paiement.
6. **K-56 tenu** : un bouton qui ne peut pas aboutir n'est pas rendu, une phrase dit ce qui manque.
7. **Visibilité (accord de l'architecte, 13/11/2026)** : le dépôt direct rend le document visible
   de **tous les inscrits**, filtré par tranche d'âge, pour les DEUX rayons. Le défaut d'avant
   (`groupe_assigne`) ne le montrait à personne tant qu'aucune classe n'était choisie.

## Ce que la personne fait

1. Choisir un fichier. Le type se lit dans le contenu (`lireFichier`, mêmes signatures que le
   serveur), le nom est prérempli (sans extension, sans « -1 »), l'envoi part aussitôt.
   « Ajouter un lien à la place » reste possible.
2. Corriger le nom s'il le faut. Description facultative.
3. Accès : « Lire dans l'application seulement » (défaut) ou « Téléchargement permis ».
4. Rayon : « Documents des cours » (défaut) ou « Pour aller plus loin » (une case à cocher).
5. Vignette : facultative, jamais bloquante ; sa miniature s'affiche ; elle se remplace et se retire
   ici et depuis la fiche, même une fois le document publié.
6. « Enregistrer le document ».

Chaque dépôt a trois états visibles, jamais par la couleur seule (`BandeauAttention`, annoncé aux
lecteurs d'écran) : en cours (barre, pourcentage, phrase), réussi (coche, ton de succès, « Fichier
ajouté » ou « Vignette ajoutée », type et taille), échoué (alerte, ton d'alerte, la phrase vraie,
« Réessayer »).

## Chaque champ : où il était, ce qu'il devient, sa valeur par défaut

| Champ | Avant | Maintenant | Valeur par défaut |
| :-- | :-- | :-- | :-- |
| Type | menu obligatoire | lu dans le fichier, jamais demandé | sans objet |
| Langue | menu obligatoire | déduite du nom, dite dans « Plus de réglages » | arabe si le nom est en arabe, sinon la langue de l'interface |
| Catégorie (texte libre) | champ obligatoire à l'écran | retirée | vide (le rayon range le document) |
| Niveau | menu | retiré | aucun ; « tous » pour le contrôle de publication |
| Titre | champ obligatoire | « Nom », prérempli | le nom du fichier |
| Description | champ | facultative (exigée pour un lien externe : contrainte `library_resource_lien_description`, migration 20261123921000) | vide |
| Rayon | menu | deux cartes | « Documents des cours » |
| Ordre d'affichage | champ | fiche, « Plus de réglages » | 0 |
| Tranches d'âge | quatre cases visibles | « Plus de réglages » | les quatre (trois, sans les 6 à 9 ans, pour un lien) |
| Étapes du programme | cases visibles | « Plus de réglages » | aucune |
| Lecture du Coran, école juridique | visibles | « Plus de réglages » | aucune |
| Source d'origine, titulaire, attribution | trois champs, bloquants à la publication | « Plus de réglages », sous « Source du document » | le serveur les remplit au dépôt direct |
| Usages autorisés (quatre cases) | cases, deux bloquantes | le choix « Accès au fichier » | application et classe ; téléchargement si choisi ; lecture sans internet : non |
| Preuve d'autorisation (fichier) | dépôt, bloquant à la publication | « Plus de réglages », facultative | la déclaration du dépôt direct |
| Revue des droits, puis publication | deux écrans de plus | faites par « Enregistrer le document » | approuvée et tracée |
| Vignette | dépôt au milieu du formulaire | facultative, après le fichier, et sur la fiche | couverture selon le type |
| Fiche : titre court, édition, organisme, conditions d'attribution, ordre, tranches, étapes, lecture, école | tous visibles | « Plus de réglages », replié | titre court = les 60 premiers signes du titre ; le reste vide |

Aucun de ces champs, vide, n'est montré aux familles, aux élèves ni aux enseignants : la fiche du
lecteur (`lib/features/tc_catalogue/detail_ressource_page.dart`) n'affiche la catégorie, l'édition,
la lecture, l'école et les niveaux que s'ils sont renseignés.

## Les réglages de production dont dépend le dépôt (vérifiés dans le code)

L'écran demande ces réglages à la fonction à l'ouverture (action `reglages`, direction seulement) et
**nomme celui qui manque**, jamais sa valeur. Un échec en cours de dépôt le nomme aussi.

| Où | Réglage (nom seulement) | Lu par |
| :-- | :-- | :-- |
| Supabase, Edge Functions, Secrets | `R2_APP_PRIVATE_ACCOUNT_ID`, `R2_APP_PRIVATE_ACCESS_KEY_ID`, `R2_APP_PRIVATE_SECRET_ACCESS_KEY`, `R2_APP_PRIVATE_ENDPOINT` | `_shared/r2/domaines.ts` |
| idem | `R2_APP_PRIVATE_BUCKET_NAME` (le seau du dépôt temporaire) | `_shared/r2/domaines.ts` |
| idem | `R2_BUCKET_SUPPORTS` (le seau des documents) | `_shared/r2/domaines.ts` |
| idem | `LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY` (32 caractères au moins, sans espace autour) | `bibliotheque-upload/index.ts` |
| idem (fournis par Supabase) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `_shared/r2/client_appelant.ts` |
| Base, table `private.library_upload_confirmation_secrets` | une ligne, la **même** valeur que `LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY` | `confirmer_upload_bibliotheque`, `bibliotheque_depot_actif` |
| Cloudflare, seau du dépôt temporaire, CORS Policy | origine de l'application, méthode `PUT`, en-tête `content-type` | le navigateur (envoi direct du fichier) |
| GitHub, secret d'Actions | `SUPABASE_ACCESS_TOKEN` | `deploy.yml` (déploie les fonctions à la fusion) |

Non vérifié par le lot : si la lecture d'un document dans le navigateur demande aussi une règle
d'origine (méthode `GET`) sur le seau des documents.

## Ordre d'installation

1. Installer `20261124700000_depot_direct_direction.sql` (aucune suppression).
2. Fusionner : `deploy.yml` déploie `bibliotheque-upload` (action `reglages`, réglage nommé dans les
   refus) et l'application.
3. Preuve du directeur : ajouter un PDF au nom arabe avec seulement le fichier et le nom ; le voir
   dans la bibliothèque d'un élève ; ajouter puis remplacer une vignette.

Entre l'étape 1 et l'étape 2, rien ne change pour l'application en place. Si l'application nouvelle
tourne contre l'ancienne fonction, la lecture des réglages échoue et l'écran retombe sur la lecture
de la base (`bibliotheque_depot_actif`).

## Preuves locales

- Tests : `test/features/admin_pedagogie_bibliotheque/import_test.dart`,
  `bibliotheque_une_admin_test.dart`, `test/core/admin/`.
- Fonctions : `deno test supabase/functions/_shared/r2/`.
- Base : `supabase/tests/scenarios_depot_direct.sql` (publication directe des deux rayons, refus sans
  la déclaration, refus hors direction, sans fichier, révision périmée, idempotence, mutation rouge).
- Captures : `docs/current/captures/E2E/depot-simple/` (32, par
  `test/capture/capture_depot_simple_test.dart`).
- Revue UX : `docs/current/UX_REVIEW_DEPOT-SIMPLE.md`.
