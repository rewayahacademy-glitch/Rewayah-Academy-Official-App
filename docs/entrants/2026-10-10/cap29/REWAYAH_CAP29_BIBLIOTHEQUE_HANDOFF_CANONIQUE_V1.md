# REWAYAH · CAP-29 · Bibliothèque : administration, publication et raccordement

**Document canonique unique à transmettre à Claude Code**  
**Date : 8 octobre 2026 · Version canonique 1.1 (même document) · Statut : high-fi proposées à validation visuelle, contrat CAP-29 prêt à transmettre sous gardes STAGING et sécurité**  
**Périmètre expressément autorisé : frontend Flutter + backend Supabase/PostgreSQL/Edge Functions + intégration R2, uniquement pour CAP-29.**  
**Le directeur ne doit recevoir ni demande d'audit, ni liste de questions déjà résolues. L'exécutant vérifie et implémente.**

> **Décision définitive du directeur du 08/10/2026 :** les supports sont stockés dans **Cloudflare R2**. Les secrets R2 existent **déjà dans le projet Supabase PRODUCTION**. Ne pas demander leurs valeurs, ne pas créer de bucket, ne pas les imprimer, ne pas choisir Supabase Storage pour les nouveaux fichiers. Utiliser l'infrastructure R2 du dépôt. La configuration et l'accessibilité de STAGING sont **à vérifier**, jamais à présumer. Aucune intervention sur la production sans feu vert explicite.

## 0. Mandat et résultat attendu

Livrer le circuit **administrateur dépose une ressource → prouve ses droits → vérifie le rendu → publie une version immuable → attribue à une classe → l'enseignant et les élèves autorisés la consultent / l'enseignant la présente en direct → accès retiré dès qu'une ressource devient indisponible**, sur téléphone, tablette et desktop/Web.

La bibliothèque **est unique** : pas de bibliothèque Admin bis côté consommateur, pas de catalogue isolé pour la classe, pas de nouveau moteur PDF pour chaque rôle. L'administration gère les publications ; enseignants, élèves et tuteurs utilisent leurs surfaces préexistantes selon leurs droits. La sélection de support en salle ne coupe jamais LiveKit et ne constitue **jamais** une diffusion vidéo d'écran. Le moteur Coran (Ḥafṣ ʿan ʿĀṣim) reste la source canonique : pas de texte coranique recomposé approximativement, pas d'altération par annotation.

**Définition du « fini »** : fichiers/permissions présents en branche livrée, parcours atteignable depuis l'UI, migration testée sur base **neuve** et sur **STAGING isolé**, envoi/lecture R2 fonctionnels, tests d'abus et de régression au vert, QA responsive/light/dark/clavier/RTL, recette E2E démontrée, sans écriture en production sans autorisation.

**Précaution de vérité** : les constats ci-dessous proviennent de la lecture de `main` au 08/10/2026, dont le dernier commit visible était `4a7aa2befe35` du 22/09/2026. Ils ne prouvent pas le statut de branches locales ou de la base distante. La documentation historique peut être périmée. Les cibles numériques de performance sont **à mesurer**, pas présentées comme déjà atteintes.

## 1. Sources de référence et arbitrages de préséance

1. Décisions explicites récentes du directeur : stockage R2, secrets en production, frontend/backend coordonnés pour CAP-29, implémentation sans audit séparé ; titre DM Sans, autres textes latins Plus Jakarta Sans, arabe existant, high-fi et tokens gelés ; ne pas créer de nouvelle destination principale ; une fonction = un endroit.
2. `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md` ; `03_DESIGN_SYSTEM_ET_UX.md` ; composants et tokens du dépôt ; high-fi validées **quand elles existent**.
3. `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1(2).docx` §6 Bibliothèque universelle, manifeste, éditions, PDF ; `01_PRODUIT_ET_PARCOURS.md` ; `06_SPEC_FONCTIONNELLE_MVP.md` ; référentiel académique si les niveaux/catégories l'exigent.
4. Dans le dépôt : `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`, `TC_AGENT_B_REPORT.md`, `docs/design/08-catalogue-ecrans.md`, `docs/produit/bibliotheque-contenu.md`, `docs/architecture/decisions.md`, les ADR réellement actifs, `docs/HANDOFF.md` et `docs/PROGRESS.md` (lire leurs **sections récentes utiles**, car les anciens paragraphes reflètent des étapes passées).
5. Source de vérité sur l'implémentation = fichiers en cours + migrations effectivement appliquées et tests prouvés. Une phrase historique « absent » ne prime jamais sur un fichier plus récent.

### 1.1 Contradictions identifiées et décisions CAP-29

| Sujet | Constat | Arbitrage obligatoire |
|---|---|---|
| Storage supports | Migration `0030` crée un bucket Supabase Storage `supports` et `0032` ses policies ; infra R2 ultérieure existe | **R2 uniquement** pour nouveaux artefacts/couvertures ; pas de double écriture ; laisser les anciens objets/SQL en place tant que leur dépendance n'est pas évaluée ; aucune suppression opportuniste |
| R2 et secrets | `_shared/r2/domaines.ts` connaît quatre domaines, dont `priveApplicatif`, avec secrets correspondants | **Réutiliser `priveApplicatif`** et `R2_APP_PRIVATE_*` déjà configurés en prod ; pas de nouveau domaine ni nouveau bucket ; signer via `_shared/r2/signature.ts` |
| Contrat de bibliothèque ancien | Documents Agent B indiquent « aucune table » (avant `0032`) | **Obsolète** : tables et policies existent dans `0032`, lecture par groupe `0033`, correctif `0035` ; ne pas recréer |
| Publication | SQL `resource_version` conserve les statuts brouillon/publiee/archivee ; absence de workflow Admin prouvé | **Conserver ce triplet SQL**. La revue des droits a ses propres états ; ajouter un service admin transactionnel et UI dédiée |
| Navigation Admin | Huit domaines fixes, `Pédagogie` a 5 fonctions ; pas de fonction bibliothèque | Bibliothèque = **6e fonction de Pédagogie**, non 9e domaine, non nouvel onglet global ; dans `SousNavigationDomaine` en conformité avec le schéma d'architecture |
| Fonts | `lib/core/theme/app_typography.dart` lu sur `main` utilise encore Bricolage Grotesque / Instrument Sans | Directive produit plus récente = **DM Sans pour titres**, **Plus Jakarta Sans pour le reste latin** ; vérifier les décisions et assets déjà intégrés dans la branche de travail avant de modifier les foundations, aucune surcharge locale bricolée |
| Coran | Ancienne spec suggère typographie/API/page différentes ; rendu exact discuté ailleurs | **Ne pas rouvrir ni modifier le moteur Coran ici.** Reprendre le renderer validé, signaler toute dépendance bloquante, ne pas afficher un faux Mushaf |
| Lecture en classe | Le picker existe, mais le branchement réel n'est pas prouvé | Réutiliser `ClassLibraryPicker` et le contrat de partage existant ; n'écrire aucun second canal vidéo ou contrôleur de session |
| Recherche | RECH-03 V3 est canonique | La recherche bibliothèque reste **recherche de son domaine** ; ne pas créer de seconde recherche transverse, réutiliser son contrat sécurisé lorsque le module sera intégré |

## 2. État précis de `main` lu avant le handoff

**Présent :**
- `lib/core/tc_bibliotheque/{library_resource,resource_version,port_catalogue,port_versions_ressource,recherche_catalogue,donnees_catalogue,catalogue_local}.dart` ; les contrats métier et doubles locaux sont présents.
- `lib/features/tc_catalogue/{surface_bibliotheque,bibliotheque_page,detail_ressource_page,class_library_picker}.dart` ; mêmes ports et même surface de bibliothèque hors et en classe.
- `supabase/migrations/0030_tc_socle.sql` crée historiquement Supabase Storage `supports` ; `0032_tc_catalogue.sql` crée `library_resource`, `resource_version`, `download_asset`, `library_resource_groupe`, `library_reading_position` et autres objets ; `0033_tc_vues_rpc.sql` crée `ressources_du_groupe`, repris/corrigé par `0035_ressources_du_groupe_rejoue_visibilite.sql`.
- `_shared/r2/{domaines,cles,signature,client_appelant}.ts` existe ; `priveApplicatif` cible le domaine R2 privé applicatif ; `cleDe('priveApplicatif','supports', UUID)` respecte la convention `private/supports/<uuid>`.
- `lib/features/admin_pedagogie_programmes/programmes_page.dart` et `lib/core/admin/service_programme.dart` sont un patron d'interface et de versionnage **à réutiliser sans les copier**.

**Écart confirmé dans `main` :** `portCatalogueProvider` dans `lib/core/tc_bibliotheque/donnees_catalogue.dart` renvoie encore `CatalogueLocal()` vide et `portVersionsRessourceProvider` renvoie `VersionsLocales()`. `DetailRessourcePage` indique qu'aucun renderer réel du contenu n'est disponible. Le dossier `lib/features/` ne contient aucun `admin_bibliotheque`, et l'Admin `Pédagogie` n'a pas de destination correspondante. Dans `0032` et `0033`, aucun RPC complet de publication de ressource n'a été identifié ; les versions sont des tables et un contrat, pas un workflow.

**Statut inconnu** : contenu des worktrees et branches non fusionnés ; application de `0035` (un mémo daté du 21/09 indiquait « non appliquée »), présence du contenu et des configurations R2 sur STAGING ; performances ; contenu réel déjà chargé ; capacité de lecture des PDFs sur les plateformes.

**Garde P0** : ne pas appeler « réalisé » un contrat Dart présent mais dépendant d'un double local, ni « sécurisé » un schéma écrit dans un fichier sans preuve de migration et test d'acteur.

## 3. Localisation UX et inventaire d'écrans

### 3.1 Navigation

**Admin desktop :** sidebar existante → **Pédagogie** → sous-navigation existante → **Bibliothèque**. L'onglet se place logiquement après `Programmes` et avant `Qualité` (proposition ordonnée, à ajuster uniquement si registre des écrans impose autrement). Les cinq onglets existants restent. **Aucun neuvième domaine.** L'entrée doit être discoverable depuis Pédagogie, pas une route seule. Sur mobile, onglets Pédagogie accessibles horizontalement ou via le pattern déjà validé, sans mini-sidebar desktop.

**Hors classe :** bibliothèque existante depuis l'Espace Classe/ressources, par capacités tuteur/élève/enseignant appropriées ; réutiliser la route déjà définie et réparer les gardes/entrées manquantes ; ne pas ajouter d'onglet principal enseignant. **Dans la classe :** enseignant ouvre Bibliothèque dans le Teaching Dock → picker en sheet mobile / panneau tablette et desktop → choisit → support actif natif synchronisé → salle continue ; l'élève suit automatiquement sans « Suivre l'enseignant ».

### 3.2 CAP-29-A : Catalogue Admin (`/admin/pedagogie/bibliotheque` **route proposée, non existante**)

But : administrer le cycle de vie de tous les supports. Desktop large : bandeau de titre + action `Ajouter un support` ; recherche et filtres compactés ; table/liste principale (couverture unique, nom, type, langue, catégorie/niveau, dernière version, droits, visibilité, dernière modification). Filtres : Tous, Brouillons, À vérifier, Publiés, Retirés, Droits expirés ; types PDF, leçon, texte structuré, image, Coran ; niveau, langue. Les indicateurs n'apparaissent que s'ils sont calculés du vrai catalogue. Tri par pertinence/date/titre stable. Ligne → détail contextuel ; sélection clavier/focus visible. Pas de bouton publier depuis la liste sans validation des prérequis. Pagination serveur / curseur si volume.

États : chargement skeleton, catalogue vide « Aucun support », recherche vide « Aucun résultat », erreur avec réessai, absence d'autorisation, hors ligne sans actions impossibles, pagination partielle, conflit édition concurrente, droits échus. Ne jamais afficher un nombre global qui révèle une ressource à un rôle non autorisé.

### 3.3 CAP-29-B : Fiche et préparation d'un support (`/admin/pedagogie/bibliotheque/:id`)

Structure desktop **deux colonnes** : principale (aperçu fidèle, description/édition, format, metadata) ; latérale (workflow, version, droits, périmètre, historique, actions). Sous mobile une seule colonne avec sections repliables ; **bouton d'action primaire accessible en bas** sans doublon. Champs : titre, titre court, type, langue, catégorie, niveau/programme, édition, couverture, source d'origine, organisme/auteur/éditeur, année si connue, preuve d'autorisation, conditions d'attribution, contraintes de téléchargement/hors ligne, portée des classes (si applicable), description pédagogique.

Actions par statut : brouillon → modifier, déposer/remplacer fichier, vérifier, prévisualiser, soumettre à contrôle, publier ; publiée → consulter version immuable, créer **une nouvelle version brouillon**, changer uniquement les attributs éditoriaux explicitement autorisés, retirer du catalogue selon droit ; retirée → voir audit, restaurer uniquement après nouvelle vérification, pas de raccourci « republier tel quel » si droits invalides.

La fiche utilise le vocabulaire **Brouillon / Publié / Archivé** pour `resource_version` ; `À contrôler / Approuvé / Refusé / Expiré` sont des **statuts de revue juridique**, jamais de nouvelles valeurs bricolées de cet enum. Une ressource sans version publiée peut être visible à l'admin, pas à l'élève.

### 3.4 CAP-29-C : Ajouter / importer

Parcours concis en **3 sections sur la même page ou wizard adaptatif sans étapes artificielles** : 1) ressource (titre, type, catégorie/niveau, langue), 2) fichier/source (import PDF/image ou contenu structuré, source canonique Coran prévalidée ; couverture), 3) droits et accès. Le dépôt utilise une URL PUT R2 présignée *uniquement après création d'une intention d'upload serveur liée à un brouillon*. Barre de progression, annulation, reprise si stratégie serveur supportée, erreur taille/type/réseau, vérification de hash et format côté serveur, état `en attente de confirmation` si upload terminé mais confirmation non acquittée.

**Types / formats :** `QuranResource` canonique sans nouvelle source coranique autonome non validée ; `StructuredTextResource` en blocs sûrs structurés ; `LessonResource` blocs pédagogiques ; `PDFResource` document natif ; `ImageResource` image. Le PDF n'est pas le format primaire du texte coranique. Ne promettre ni EPUB ni audio viewer tant que renderer correspondant n'est pas réellement intégré. Si upload multiple n'est pas codé, pas de faux bouton « import en masse ».

### 3.5 CAP-29-D : Vérifier et publier

La prévisualisation **doit rendre le vrai contenu** dans le renderer cible et les métadonnées de source/licence. Panneau de contrôle : source confirmée, titulaire du droit connu ou justification juridique, preuve vérifiée, usage dans app permis, affichage en classe permis, téléchargement/offline séparément permis, date d'expiration et attribution, fichier sain, rendu testé, langue/niveau, version et empreinte. Liste des blocages visibles ; CTA `Publier la version` seulement si tous les critères requis sont validés sur serveur. Confirmation **récapitulative** avec portée et effet sur les classes. La publication est atomique (état + pointeur courant + audit + visibilité), jamais demi-publiée.

### 3.6 CAP-29-E : Attribuer et retirer

Action `Associer aux classes` sur fiche publiée → sélecteur de classes réellement autorisées, possibilité d'épingler, liste des classes déjà servies ; mise à jour idempotente de `library_resource_groupe`. Le parent ne peut ni publier ni affecter arbitrairement. L'enseignant peut sélectionner/presenter les supports visibles ; attribution persistante par l'enseignant seulement si le droit métier serveur préexistant l'autorise explicitement, sinon réservée à l'admin.

`Retirer` demande motif et confirmation non ambiguë : stop nouvelles URL signées, retrait des listes et recherches, statut visible dans l'audit ; préserver les traces de séance et l'intégrité référentielle. **Le retrait d'un fichier n'est pas la suppression physique immédiate** d'un artefact lié à l'historique pédagogique ; purge gouvernée par conservation et droits, pas l'interface.

### 3.7 High-fi ciblées (mise à jour du même pack le 08/10)

Le pack contient désormais **quatre maquettes high-fi statiques** et leur HTML/CSS de référence, ainsi qu'une planche d'ensemble. Elles remplacent les quatre anciens croquis conceptuels **à l'intérieur de CAP-29**, sans créer de deuxième spécification.

| ID | PNG haute résolution (source de la composition visuelle) | Placement et intention |
|---|---|---|
| CAP29-M01 | `CAP29-M01-HIFI-CATALOGUE-DESKTOP.png` (1600×900) | Admin → Pédagogie → Bibliothèque ; recherche locale, filtres, table, droits, états et pagination |
| CAP29-M02 | `CAP29-M02-HIFI-FICHE-DESKTOP.png` (1600×900) | Fiche de brouillon ; preview structurelle, droits distincts de la publication, versions, historique et actions |
| CAP29-M03 | `CAP29-M03-HIFI-PUBLICATION-DESKTOP.png` (1600×900) | Revue bloquante ; checklist serveur, preuves, raison du blocage, publication désactivée |
| CAP29-M04 | `CAP29-M04-HIFI-IMPORT-MOBILE.png` (430×970) | Import en cours ; informations de brouillon, dépôt R2, progression, bouton suite bloqué, retour atteignable en bas |

**Statut : propositions high-fi à valider par le directeur**, pas captures Flutter existantes ni approbation implicite du code. Les textes de contenu, numéros de version, dates et résultats montrés sont des **données synthétiques**. Les contrôles représentés ne sont pas des tests réels ni des preuves de licence. Les PNG servent de référence d'emplacement/hierarchie ; les HTML/CSS permettent de relire espacements et zones, mais **ne sont pas du code à copier dans Flutter**. Les high-fi plus anciennes réellement approuvées pour les éléments communs (chrome, identité visuelle et navigation) priment sur tout conflit ; ne pas refaire ces éléments.

**Règle de validation :** toute divergence avérée avec un layout déjà figé est corrigée dans l'implémentation en faveur du layout validé, non traitée comme une permission de refondre le système. La version mobile ne prescrit aucun nouvel onglet principal : elle montre le contexte Pédagogie, le formulaire et ses actions ; son conteneur de navigation réel doit être celui de l'AdminShell adaptatif déjà validé. La barre supérieure globale de recherche est le point d'entrée RECH-03, **pas une seconde recherche métier**.

## 4. Règles métier et autorisations de lecture/écriture

### 4.1 Matrice des capacités

| Acteur | Catalogue visible | Fiche & lecture | Import/modification | Publication et retrait | Affectation à classe |
|---|---|---|---|---|---|
| Administrateur habilité | Toutes versions (y compris brouillons) | Détails complets + audit | Oui | Oui, capacité dédiée positive | Oui |
| Agent administratif sans capacité dédiée | Seulement ressources explicitement autorisées | Selon sa projection | Non | Non | Non |
| Enseignant attaché à un groupe | Ressources publiées autorisées | Oui sur ressources permises / préparées | Non | Non | Seulement si capacité serveur préexistante, sinon non |
| Élève adulte | Publiées accessibles selon politique/groupe | Lecture / téléchargement selon droits | Non | Non | Non |
| Élève enfant (Interface guidée) | Même permission serveur, présentation adaptée | Lecture guidée du seul contenu autorisé | Non | Non | Non |
| Tuteur | Publiées accessibles à ses enfants/groupes selon relation | Seulement projection autorisée | Non | Non | Non |
| Contrôleur / comptable / agent IA RO | Pas de privilège automatique sur le catalogue | Par capacité spécifique démontrée uniquement | Non | Non | Non |
| Anonyme | **Aucun droit ajouté dans CAP-29** | Aucun nouvel accès par R2 | Non | Non | Non |

Le nom SQL `access_policy='publique'` ne suffit pas à conclure que `anon` peut lire ; la policy historique est `to authenticated`. **Aucun accès anonyme introduit** sans décision produit et audit légal séparé. Le client peut *afficher* la politique mais ne peut jamais la faire respecter.

### 4.2 Invariants

1. **Objet** : aucune ressource/version/association d'un autre périmètre n'est visible, même en connaissant son UUID.
2. **Champ** : aucun titre de brouillon, nom interne de fichier, note de licence, contact privé ni clé R2 ne fuite via API de lecture générale, recherche, suggestions, compteurs ou erreurs.
3. **Action** : droit de voir ≠ droit de modifier ≠ droit de publier ≠ droit de télécharger ≠ droit de présenter dans la classe.
4. **Version** : une version publiée est immuable (binaire, type, hash et règles de diffusion acquises au moment de publication). Toute évolution de contenu = **nouvelle version**. Une référence de séance passée reste versionnée.
5. **Références** : `current_version_id` doit appartenir à **la même** `library_resource`, être publiée, et ne changer qu'au commit transactionnel autorisé ; refus cross-resource ; pas de publication simultanée concurrente incohérente.
6. **R2** : aucune URL présignée brute persistée dans la DB, le cache durable, les logs ou l'analytics ; clés opaques UUID, valides sous `private/supports/<uuid>` ; accès fraîchement autorisé pour **chaque nouvelle signature**.
7. **Retrait** : plus de nouvelle signature après changement de droit/retrait ; une URL déjà émise reste valable jusqu'à son expiration (limite technique explicitée), donc durée de vie courte, **au maximum 60 secondes** pour la lecture sensible. Les téléchargements déjà copiés ne sont pas effaçables à distance : notifier et bloquer la réutilisation dans l'app au prochain contrôle de droits ; pas de promesse de DRM absolu.
8. **LiveKit** : pas de déconnexion ni duplication de room lors de l'ouverture/fermeture du sélecteur ; publication native du pointeur et de la position à travers le mécanisme autorisé existant ; seul le professeur contrôle le support présenté.
9. **Audit** : qui a importé, vérifié, validé, publié, affecté, changé politique ou retiré ; quand ; quel objet/version ; motif ; IP brute / URL signée / contenus sensibles exclus.
10. **Compatibilité** : rendre l'échec de lecture ou refus explicite, jamais 404 indistinct du 500 en surface utilisateur ; appliquer format/RTL/lecteur d'écran.

### 4.3 Droits d'auteur et provenance, obligatoires avant publication

Mettre en place un enregistrement **non public** de provenance et licence lié à la version : `source_title`, `source_url` si valable, `rights_holder` ou origine institutionnelle, `licence_kind`/référence contractuelle sans inventer une licence, `proof_asset_id` (artefact privé R2), `authorized_uses` (`in_app`, `in_class`, `download`, `offline`, éventuellement `public_distribution` si explicitement autorisé), `attribution_text` obligatoire quand requis, `valid_from`/`valid_until` si applicables, `checked_by`, `checked_at`, `review_status` (`a_verifier`, `approuve`, `refuse`, `expire`), commentaire d'audit interne. Valeurs inconnues bloquent la publication : on ne présume pas le domaine public. Les droits de diffusion sont **indépendants** des permissions de consultation de l'app.

Support acquis de source officielle ≠ automatiquement libre de redistribution. Pour le Mushaf et les œuvres de tiers, vérifier les droits propres aux pages, fontes, traductions, audios et images ; **pas de copie par défaut depuis un site tiers**. Ajouter une attribution exacte quand exigée ; ne pas inventer de mention légale. Les preuves d'autorisation doivent rester internes, accessibles aux seuls agents autorisés.

## 5. Contrat backend Supabase, sans recréer l'existant

### 5.1 Modèle minimal de données à ajuster après vérification

**Réutiliser sans duplication** les tables existantes :

- `public.library_resource` : manifeste, type, politique, édition, current_version_id, archived_at ; ajouter seulement les colonnes indispensables absentes ; vérifier/sécuriser RLS, filtre publié pour non-admin.
- `public.resource_version` : `brouillon|publiee|archivee`, empreinte, published_at/by ; CHECK/FK composées ou triggers pour `current_version_id` du même parent, immuabilité réelle et reprise de version.
- `public.download_asset` : format, clé R2 **sans URL signée**, taille, empreinte, version ; ne pas le confondre avec un canal générique d'upload.
- `public.library_resource_groupe` : affectation, épinglage, auteur ; capacité serveur positive, audit.
- `public.library_reading_position` : reprise individuelle et indépendante du partage de classe.

**Extension minimale proposée** : une table admin-only `library_resource_rights` (droits/version, revue, preuve) et, seulement si `download_asset` ne peut pas modéliser sans ambiguïté le fichier source natif, une table `library_source_asset` (version, hash, MIME réel, taille, clé de stockage R2, scan_status). Préférer une extension d'un schéma déjà dédié s'il remplit exactement le contrat ; **pas de tables redondantes**, pas de migration arbitraire. `library_resource_rights` ne doit pas devenir une projection lisible par élève ou enseignant. Les preuves légales binaires utilisent le même domaine R2 applicatif mais sous famille `libraryproof` (clé opaque `private/libraryproof/<uuid>`), et droits d'accès **distincts** de la lecture des supports.

Définir une vraie chaîne **intention → dépôt provisoire → confirmation → contrôle → publication** qui n'autorise aucun objet R2 non validé à apparaître au catalogue. Pour le dépôt provisoire, créer une clé sous une famille `libraryupload` autorisée par `cleDe`, puis référencer/convertir en objet final contrôlé sans réutilisation de clé entre versions. Le modèle exact d'object-copy côté R2 dépend des primitives présentes ; jamais déplacer par écrasement incontrôlé. Assurer nettoyage des uploads abandonnés et idempotence.

### 5.2 RPC et Edge Functions (contrat proposé, noms à adapter aux conventions existantes)

| Opération | Entrée métier | Sortie attendue | Garde et effet |
|---|---|---|---|
| `admin_library_create_draft` | métadonnées validées | `resource_id`, `draft_version_id` | admin CAP publication, objet brouillon, journal |
| `admin_library_request_upload` | `draft_version_id`, purpose, MIME, taille, checksum annoncé | `upload_id`, URL PUT courte, en-têtes signés, expiration | capacité import, propriétaire/version brouillon, MIME et taille bornés, clé générée serveur, R2 `priveApplicatif` |
| `admin_library_confirm_upload` | `upload_id`, idempotency_key | état vérifié, hash, erreur typée | serveur vérifie objet, contenu et intégrité ; ne croit pas le client ; idempotent |
| `admin_library_update_draft` | draft/version/fields/expected_revision | version/révision | brouillon seulement, verrou optimiste, audit |
| `admin_library_review_rights` | version, preuve, usages autorisés, résultats de contrôle | état de revue | capacité de validation, source et preuve vérifiables |
| `admin_library_preview` | version/id | contenu signé pour aperçu ou rendu sûr | admin autorisé, brouillon permis seulement dans contexte admin |
| `admin_library_publish` | draft_version_id, expected_revision, idempotency_key | resource, published version | transaction atomique : droits valides, artefacts sains, renderer valide, hash, version figée, pointeur, journal |
| `admin_library_assign_groups` | `resource_id`, groupes autorisés, pin, expected_revision | associations confirmées | publié + admin autorisé ; membership/groupe réel ; idempotence |
| `admin_library_withdraw` | resource_id, reason, revision | withdrawn_at, audit ref | stop accès, pas de delete historique ; révocation autorisation |
| `library_get_catalogue`, `library_get_detail` | filtres bornés, curseur, resource_id | projection minimale autorisée | RLS + objets publiés ; jamais table brute pour rôles externes |
| `library_request_download` | resource_version_id, asset_id, intended_use | URL GET courte / refus typé | relation et droit d'usage **revalidés** à chaque appel ; URL ≤60 s |

Ces noms sont **proposés**, pas des RPC réputées existantes. En pratique, adopter le style du dépôt (fonctions Postgres pour transaction/autorisation et Edge Functions pour signature R2) et éviter la duplication de logique. Les Edge Functions doivent appeler des RPC avec **JWT authentifié de l'acteur** via `appelantR2`, pas faire confiance à un `profile_id` fourni dans le JSON ; ne jamais prendre un `object_key`, nom de bucket ou chemin de fichier du client pour décider du fichier à signer. Les appels sensibles écrivent leur audit **dans la transaction d'autorisation** avant de signer.

### 5.3 R2 : réutilisation de l'infrastructure réellement présente

`supabase/functions/_shared/r2/domaines.ts` : `DomaineStockage` inclut `priveApplicatif`, associé au trousseau **existant** `R2_APP_PRIVATE_*` et au seau privé applicatif. `cles.ts` : `cleDe('priveApplicatif', 'supports', assetUuid)` → `private/supports/<uuid>` ; `cleDe('priveApplicatif', 'libraryupload', uploadUuid)` → `private/libraryupload/<uuid>` ; `cleDe('priveApplicatif', 'libraryproof', proofUuid)` → `private/libraryproof/<uuid>`. `signature.ts` est le **seul signataire** ; `signerDepot`, `signerLecture`, `objetExiste` sont déjà présents. `client_appelant.ts` identifie l'acteur.

**À faire :** implémenter les endpoints métier dédiés autour de cette infrastructure, durcir autorisations et contrôles serveur, tests des signatures et clés, capacité de vérifier le contenu réel après upload. **À ne pas faire :** 5e bucket, 5e jeu de secrets, seconde lib AWS S3 dans Flutter, URL permanente publique, écriture directe du client dans Supabase Storage `supports`, lecture directe R2 depuis un autre rôle, reconfiguration des secrets de production.

**Important :** `R2_APP_PRIVATE_*` existent en PRODUCTION selon le directeur, mais la capacité d'y lire/écrire au moment du déploiement n'a pas été testée dans cet audit. Sur STAGING, utiliser une configuration isolée autorisée ou des doubles R2 pour les tests sans exposer/toucher les objets de production ; **ne jamais utiliser des clés de production par défaut pour des fixtures de tests**. Demander autorisation avant tout test réel production ; ne pas retarder le code pour ce simple contrôle.

**Upload robuste :** listes MIME/type autorisés centralisées ; contrôle extension **et en-tête MIME et signature magique** ; plafonds documentés et configurables selon format, pas de réutilisation abusive de `TAILLE_MAXIMALE_PIECE_OCTETS` réservé aux pièces d'identité ; hachage SHA-256 calculé ou attesté serveur de bout en bout, tests ETag multipart ; nettoyage EXIF pour images de tiers lorsque pertinent ; traiter PDF actif / liens malveillants / contenu HTML ou SVG potentiellement exécutable ; bloquer publication tant que scan/sanitation n'est pas établi ; validation structurelle JSON pour leçons ; vérifier copyright et attribution. Éviter le scan antivirus fictif : si la solution d'analyse n'est pas réellement intégrée, état bloqué et rapport technique explicite. Protection contre replay/idempotence et concurrence de deux administrateurs.

### 5.4 Correctifs RLS à examiner avant exposition

- `0032` : `library_resource_lecture` est `to authenticated` mais sa clause n'exclut pas explicitement `current_version_id IS NULL` pour tout non-admin ; un manifeste brouillon peut donc apparaître selon sa `access_policy`. Ajouter projection et policy compatibles pour interdire tout brouillon hors admin.
- `0032` : les policies `download_asset_lecture`/`resource_version_lecture` doivent suivre **l'état de retrait**, la version courante/politique du parent et le droit explicite de téléchargement, pas seulement `statut='publiee'` ; vérifier les anciens liens et la consultation contrôlée des versions historiques.
- `0033` : vérifier effet réel de `0035` pour `ressources_du_groupe` : `SECURITY DEFINER` ne doit pas neutraliser les prédicats de confidentialité de `library_resource`.
- `0032` : vérifier contrainte publication immuable, cohérence `current_version_id` / `resource_id`, et éventuels droits d'écriture directs. Si absente, imposer en DB ; pas seulement un bool Dart.
- `0030/0032` : les policies Supabase Storage `supports` restent dans les migrations historiques : ne pas en faire le circuit actif ni les rouvrir ; un durcissement de l'ancien bucket ne remplace pas la protection R2.
- `admin_library_*` : jamais de grant à `anon` / `agent_ro` pour RPC d'écriture ; `SECURITY DEFINER` avec `search_path=''`, objets qualifiés ; vérification positive du compte non suspendu, capacité de publication, session du signataire, traçabilité.

**Tests négatifs obligatoires :** ID guess d'un brouillon, objet d'un autre groupe/foyer, version historique non autorisée, lien retiré, acteur suspendu, tuteur d'un autre enfant, enseignant d'une autre classe, `agent_ro`, comptable, anon, spoof JWT/profile_id, upload détourné par nom de clé, dépassement taille, MIME mensonger, hash erroné, contrôle de version concurrent, publication sans licence, droits expirés, URL pré-signée expirée, annulation en upload, fuite dans trace ou messages d'erreur.

## 6. Contrat Flutter et lecture réelle des contenus

### 6.1 Câblage

- Brancher `PortCatalogue`, `PortVersionsRessource`, `PortTelechargement` sur services **Supabase/R2 réels** via l'injection existante ; laisser `CatalogueLocal` / `VersionsLocales` aux tests/preview uniquement. Réutiliser `donneesCatalogueProvider` et `detailRessourceProvider`, sans nouvelle bibliothèque parallèle.
- Fournir état réseau, chargement, erreur avec retry, refus / absent distincts, publication/retrait en temps réel ou invalidation ciblée et cache réconcilié.
- Ne pas faire de `SELECT *`, requêtes filtrées intégralement côté client, téléchargement systématique de tout le catalogue ou recherche `ILIKE '%...%'` non bornée. Faire filtrage et pagination autorisés côté serveur conformément à RECH-03 ; la recherche intégrée au domaine tient sa place dans `SurfaceBibliotheque`.
- Conserver couvertures persistantes, distinctes et accessibles via clés opaques + URL éphémère ; un fallback déterministe est permis uniquement lorsqu'aucune couverture réelle autorisée n'existe.

### 6.2 Renderers

**Rendu natif par type :** `quran` → moteur Coran canonique **inchangé** (Hafs et mise en page vérifiée), `structured_text` et `lesson` → sections/blocs structurés avec typographie et anchors validés, `pdf` → vrai viewer PDF responsive avec zoom/pagination/clavier/tactile et contrôle du poids web, `image` → zoom/pan avec alt text quand possible. Les annotations vivent dans `annotation_layer`/marqueurs distincts de la source immuable. Toute position `ContentPosition` doit pouvoir se restaurer si le renderer prend en charge le type.

Le choix du viewer PDF doit être motivé par licences, compatibilité Web/PWA et coût bundle, avant ajout. `pdfrx` figure comme piste dans `TC_CONTRACT_REQUEST_B.md`, **pas comme dépendance adoptée**. Tester au moins Android, iOS, navigateur web mobile/desktop. S'il n'existe pas de renderer fiable pour un type, il ne peut pas être **publié comme lisible** sans état explicite ni être annoncé « pleinement implémenté ».

### 6.3 En classe : intégration avec la salle existante

- L'enseignant ouvre la **même** bibliothèque via `ClassLibraryPicker`, sélectionne un `resource_id`, une `resource_version_id` **publiée autorisée**, et une `ContentPosition`. L'hôte publie l'état via le contrat existant `publier_etat_partage`/service du Teaching Core, avec nonce/sequence/reconnexion selon mécanisme actuel.
- La page élève reçoit et affiche la ressource sur son renderer local ; un paquet n'est que l'identifiant et position, **pas le binaire du support ni un flux vidéo**. Contrôle d'accès **côté élève** lors de la résolution de la version. Si un support n'est pas autorisé, état explicite, aucune fuite de titre.
- La sélection par l'enseignant a autorité pendant présentation ; ne pas proposer « Suivre l'enseignant ». Les préférences de zoom et d'accessibilité restent locales ; le support et le focus commun restent sous contrôle enseignant. Roster et compteur n'occupent pas la zone dominante du support.
- Déconnexion/réconnexion LiveKit ne doit pas supprimer la position partagée ; `ClassLibraryPicker` ne touche pas à la room et n'importe jamais `core/video`; conserver les tests existants contre `disconnect`.

### 6.4 Cache / hors ligne

Réutiliser `PortEtatOffline`, `CacheMedia` et Drift existants ; un objet en cache est lié à **resource_version_id + hash + autorisation**, et ne peut pas être affiché à un autre profil après changement de compte. Cache persistant après redémarrage seulement si effectivement testé ; sinon l'UI ne marque pas « Téléchargé ». Suivre droit licence : in_app ≠ download ≠ offline. Effacer ou verrouiller le cache application après retrait/expiration et au prochain contact serveur (limite physique du hors-ligne expliquée). Le Coran local suit ses propres règles documentaires, pas les PDF génériques.

## 7. Accessibilité, UI, états et responsive

- **Design** : Material 3/Cupertino selon projet, respect de `PageShell`, `SousNavigationDomaine`, `ActionPrincipale`, `MenuActions`, `EmptyState`, `AppBottomSheet`, `Pressable`, `AppPalette`, `AppSpacing`, `AppRadius` existants ; zero nouvel HEX dans widgets ; DM Sans titres et Plus Jakarta Sans textes du produit dès que le thème global validé les expose, arabe distinct ; clair/sombre.
- **Desktop vrai** : sidebar Admin actuelle, filtres non envahissants, table dynamique à en-tête stable et panneau de détail contextuel ; max-width raisonnable pour lecture/édition, vrai hover/focus/clavier ; largeur variable sans débordement.
- **Tablette** : catalogue et panneau à largeur adaptée ; pas de dialogue minuscule pour un processus long.
- **Mobile** : catalogue liste, détail en page, import en séquence lisible, formulaire avec clavier, focus et CTA accessibles, 48 dp min ; pas de table desktop compressée.
- **Langues** : toute chaîne via i18n existant, FR/EN/Poular selon portée produit, arabe RTL sur contenu sans inverser la logique métier ; pas de code technique sur UI (UUID caché sauf copie admin explicite).
- **États exhaustifs** pour liste, détail, upload, revue, publication, téléchargement : `loading`, `content`, `empty`, `filtered_empty`, `error`, `offline`, `forbidden`, `expired`, `uploading`, `verifying`, `blocked`, `conflict`, `published`, `withdrawn`, `cancelled`, `partial`. Les actions impossibles sont désactivées **avec raison visible**, pas des CTA morts. Les confirmations destructives et annulations affichent l'effet réel ; notification de succès seulement après réponse serveur.
- **Texte 200 %**, clavier, lecteur d'écran, ordre de focus, RTL, contrastes WCAG 2.2, mouvement réduit ; pas de couleur seule pour distinguer un droit refusé ou version expirée.

### 7.1 Contrat visuel des quatre high-fi (à contrôler lors du handoff Claude)

**Fondations.** Palette actuelle : surface claire, fond très légèrement lavande/gris, texte anthracite ; violet uniquement sur navigation active, CTA et progression. Pas de nouveau code couleur en Flutter. Tokens réels `AppPalette`, `AppSpacing`, `AppRadius`, `AppTypography` ; titres DM Sans, contenu/labels Plus Jakarta Sans, arabes via la famille existante du produit. En l'absence d'asset correspondant dans la branche réelle, résoudre au niveau du thème global selon directives déjà tranchées, jamais en surchargeant localement CAP-29. Le mode sombre reprend les tokens dark existants, sans inversion artificielle de l'image PNG.

**M01 · Catalogue desktop (repères précis).** Conserver la sidebar Admin existante, `Pédagogie` sélectionnée, puis **sixième sous-fonction** `Bibliothèque` entre `Programmes` et `Qualité`, sans créer de 9e domaine. Titre et CTA en ligne. Une alerte discrète rappelle qu'un brouillon ne donne aucun accès. Toolbar avec recherche *locale au catalogue* (nom, édition, catégorie autorisés), filtres Type/Niveau/Langue/Droits et segments Tous/Brouillons/À vérifier/Publiés/Retirés/Droits expirés. Liste/table à lignes scannables ; couverture non générique, titre + sous-type ; catégorie, version, **état de publication**, **état de revue des droits séparé**, date, action contextuelle. Cliquer sur une ligne ouvre M02. N'exposer compteurs et catégories que dans l'espace Admin autorisé ; aucune valeur factice en production. En mobile, passer à des cartes/list-items sémantiques, **jamais** afficher la table compacte.

**M02 · Fiche et versions.** Desktop à 2 colonnes : (1) aperçu du vrai rendu et métadonnées/description ; (2) cycle de publication, droits, historique et actions bornées. La maquette montre un exemple graphique **non académique**, non un contenu réel : un écran fonctionnel doit afficher le PDF/blocs authentiques depuis le renderer prévu, pas un faux document. Le brouillon reste modifiable ; une version `publiee` n'est pas éditable, seulement dérivable en nouveau brouillon. Une carte de droits `À vérifier` n'est pas un statut de version. Afficher précisément les usages in_app / in_class / download / offline, sans les confondre. Le changement de version réinitialise la vérification juridique requise. Mobile empile les sections dans l'ordre aperçu → détails → droits/versions → actions, avec une unique action principale.

**M03 · Contrôle de publication.** Écran d'étape (informations → fichier R2 → vérifications → publication) sans état ambigu : chaque prérequis **validé par le serveur**, chaque échec avec explication actionable. Dans l'état représenté, licence/preuve insuffisantes, bouton `Publier cette version` indisponible avec raison textuelle visible ; `Compléter les droits` mène à la fonction unique de revue. **Le texte « 2 points bloquants » est une illustration** : l'état réel doit être issu de validations serveur, sans compteur codé en dur. Après succès serveur seulement : toast, version immuable et audit, éventuelle visibilité selon politiques. Aucun moyen de publier à partir de la grille M01 en contournant l'étape.

**M04 · Import sur mobile.** 3 sections logiques : détails → source R2 → droits et accès. L'image fige **l'état `uploading`**, au milieu de la section 2 : fichier nommé, avancement mesuré, annulation possible, suite désactivée tant que le serveur n'a pas confirmé le fichier. Le titre/type/langue saisis précédemment restent visibles sans ressaisie inutile ; l'action `Choisir un autre fichier` doit être grisée ou désactivée si un upload ne permet pas le remplacement concurrent. Deux actions accessibles en bas : Retour, puis Poursuivre quand l'état permet effectivement la transition. Respecter les insets du clavier, zone tactile >=48 dp, flux écran lecteur vocal. Après fin de transfert, états `verifying` puis `ready_for_rights`; jamais `published` à cette étape.

**Responsive / QA de fidélité.** Desktop référence 1600×1000 mais largeur fluide (pas de centre artificiellement étroit) ; tablette à 768–1024 : panneaux empilés ou maître/détail selon espace réel, sidebar condensée selon AdminShell ; téléphone 390–430 : un seul axe de lecture, sections non recadrées, touches confortables. Capturer Flutter sur au moins 390×844, 768×1024 et 1440×900 pour comparaison visuelle. Pour chaque vue tester `loading`, `empty`/`filtered_empty`, `error`, `offline`, `forbidden`, `uploading`, `verifying`, `blocked`, `published`, `withdrawn` selon pertinence. Contrôler dark, RTL, clavier, focus 200 %, pas de boutons fantômes. **Une image high-fi statique n'est pas une preuve de ces états.**

## 8. Scénarios de recette E2E (preuves et verdict par cas)

| ID | Parcours/attaque | Critère PASS |
|---|---|---|
| CAP29-01 | Admin ouvre Pédagogie → Bibliothèque depuis sidebar | atteignable au clic réel, jamais route orpheline |
| CAP29-02 | Catalogue vide → nouveau support | état vide utile, brouillon créé sans publication |
| CAP29-03 | Import PDF/image autorisé sur R2 privé | clé opaque R2, upload signé expirant, contrôles taille/MIME/hash, contenu bien présent |
| CAP29-04 | Document corrompu / type trompeur / malveillant | publication refusée et expliquée, aucune lecture publique |
| CAP29-05 | Import sans preuve ou licence incertaine | bloqué à la revue, ne passe pas Publié |
| CAP29-06 | Droits validés, prévisualisation fidèle | renderer montre le binaire ou les blocs réels ; aucune fausse capture |
| CAP29-07 | Publier v1 puis créer v2 | v1 immuable, v2 brouillon séparée, bascule atomique après publication v2 |
| CAP29-08 | Deux admins publient concurremment | une seule mise à jour cohérente ; conflit explicite/idempotence |
| CAP29-09 | Affecter au groupe A, pas B | seulement groupe A voit le support selon politiques, aucun titre/URL pour B |
| CAP29-10 | Enseignant choisit support dans la salle | salle reste connectée ; élève autorisé reçoit contenu natif/position et reprend après reconnexion |
| CAP29-11 | Tuteur/enfant d'autre foyer cherche UUID | pas d'existence, titre, statut, miniature, nombre ou URL fuite |
| CAP29-12 | Retirer support publié en cours d'utilisation | nouvelle signature refusée immédiatement ; délai de vie d'une URL existante documenté et borné |
| CAP29-13 | Licence arrive à expiration | consultation/distribution refusées ou dégradées selon droits exacts, sans republier silencieusement |
| CAP29-14 | Mobile/tablet/desktop, clair/sombre, grand texte/RTL | aucune perte d'action, pas d'overflow, contrôle clavier et lecteur d'écran |
| CAP29-15 | Redémarrage hors ligne, changement compte | cache persistant seulement si vrai et autorisé ; aucune fuite entre profils |
| CAP29-16 | Échec réseau à chaque étape du dépôt | upload résilient, pas de version publiée incomplète ni état éternel |
| CAP29-17 | Accès admin non autorisé, agent_ro, comptable, anon | aucune RPC écriture, aucun URL signé, refus positif |
| CAP29-18 | STAGING migration + R2 isolé + schéma neuf | tests SQL/RLS/R2 et CI complets, prod inchangée |
| CAP29-19 | Retrait ou révision d'une version référencée par une séance passée | aucune FK cassée, trace historique conservée, droit de nouvelle consultation respecté |
| CAP29-20 | Recherche/filtre de grand catalogue | pas de scan tout-client, pagination bornée, p95/p99 mesurés sur STAGING |

**Performance visée** (non constatée) : budget SQL p95 ≤150 ms, endpoint de recherche p95 ≤400 ms, premier résultat utilisateur p95 ≤1 s sur réseau de référence, timeout client 3 s, pagination et index pertinents ; pour bibliothèque, mesurer séparément `list`, `detail`, émission de signature, rendu premier PDF/ressource et reprise réseau faible. Aucune fausse revendication de SLO tenue sans compte rendu d'essai sur volume de données représentatif.

## 9. Plan d'exécution pour Claude, sans aller-retour au directeur

### Étape CAP29-0 : **constat de l'existant intégré**, PAS d'audit séparé

Avant son premier changement, Claude vérifie rapidement HEAD/worktrees/branches concurrentes, tests/ports, lignes pertinentes des migrations `0030`, `0032`, `0033`, `0035`, services R2, états d'upload et toutes les maquettes validées et docs canoniques déjà présentes. **S'il possède déjà une réponse récente et sourcée dans son handoff/repos**, il n'écrit pas un deuxième audit : il vérifie seulement que la preuve pointe vers le HEAD courant et **enchaîne immédiatement le code**. **S'il ne possède pas cette preuve**, il fait une lecture ciblée en interne (pas de rapport bloquant au directeur), conserve les résultats dans son journal de réalisation, et continue. Toute différence sur branche active devient un écart local, pas une demande automatique de nouvelle instruction.

La vérification des secrets est **par noms et fonctionnement** : jamais de valeurs. En cas de doute sur STAGING, continuer code/tests doubles et **bloquer uniquement les essais réels**, sans reconfigurer PROD ni demander au directeur de rappeler qu'il a déjà défini R2.

### Étape CAP29-1 : sécurité et base d'une publication réelle

Comparer l'existant aux invariants §4 et §5 ; créer une migration **nouvelle, unique, ordonnée** de droits/provenance et contraintes de version/liaison manquantes ; réutiliser les tables `0032` sans toucher aux migrations déjà appliquées. Ajouter RPC admin à capacités positives + tests négatifs. Ne pas surcharger le domaine `programme_versions` qui modélise le curriculum, ni multiplier les tables. Rejouer sur Postgres nu, puis STAGING seulement quand environnement vérifié. Check CI et `agent_ro`.

### Étape CAP29-2 : intégration R2 et ingestion

Réutiliser `priveApplicatif` / `cles.ts` / `signature.ts` / `client_appelant.ts` ; implémenter upload intent/PUT confirm, serveur vérifie fichier, sources et droits, échoués idempotents, dépôt provisoire, interdiction de leakage, signed GET de consultation. Staging en R2 isolé ou mocks stricts ; ne pas créer bucket ou changer prod. Couvrir CAP29-03/04/05/16/17.

### Étape CAP29-3 : UI Admin Pédagogie

Ajouter fiche `CAP-29` au `docs/design/08-catalogue-ecrans.md` **avant** le code écran ; enregistrer route dans routeur unique et sous-nav Pédagogie ; page catalogue, formulaire/import, détail, contrôle/publication, affectation/retrait ; composer à partir des composants actuels et des **quatre high-fi CAP29-M01..M04 du pack**, selon le contrat d'interactions §7.1. Ne pas copier le HTML dans Flutter. Aucun nouvel item dans la sidebar principale, aucun panneau surchargé. États, responsive et accessibilité complets.

### Étape CAP29-4 : branchement des consommateurs existants

Brancher les ports du catalogue au serveur réel, garder les doubles pour tests, rendre les types réellement publiables, vérifier télécharger/cache. Relier groupe et Teaching Dock, préserver LiveKit ; les lecteurs Coran sont réutilisés, non redessinés. Les droits sont recontrôlés à la résolution de chaque artefact et après changements.

### Étape CAP29-5 : QA et livraison

Run `dart run slang`, `dart run build_runner build --delete-conflicting-outputs`, `dart analyze --fatal-infos`, `flutter test`, `dart run tool/verifier_jetons.dart` ; tests SQL sur Postgres neuf, tests RLS acteurs, Edge R2, integration PWA/Web et mobile, tests de sécurité référencés, capture du vrai Flutter (4 viewports représentatifs) à comparer aux références high-fi et à la Bible, tests clavier/RTL/200%. Publier un seul **rapport de clôture concis** avec commit/branche, PASS/BLOCKED/INCONNU, captures et scénarios réellement exécutés ; signaler les blocages concrets, sans maquiller les tests non exécutés. Demander feu vert explicite **uniquement** pour les opérations de production.

**Parallélisme sécurisé :** si d'autres agents travaillent dans le dépôt, identifier ownership et worktrees, créer une branche de travail unique CAP-29, éviter les modifications simultanées du routeur/theme/migrations par deux agents, fusion séquencée sous la responsabilité de Claude. Aucun reset/force push/merge prod/auto-déploiement involontaire.

## 10. Prompt opérationnel à coller dans Claude Code

> **Mission unique : IMPLÉMENTER CAP-29 DE BOUT EN BOUT.** Tu reçois `REWAYAH_CAP29_BIBLIOTHEQUE_HANDOFF_CANONIQUE_V1.md` (même fichier canonique, révision 1.1) et les **quatre maquettes high-fi CAP29-M01..M04** associées. C'est le **seul document actif CAP-29**. Applique intégralement les exigences métier, frontend, Supabase et R2 qu'il contient, en réutilisant le code réel.
>
> **Directive du directeur :** fichiers exclusivement dans **Cloudflare R2**, configuration/secrets déjà présents sur Supabase production ; **aucun nouveau bucket, aucune demande de clés, aucune migration de stockage Supabase pour les nouveaux supports, aucune modification production sans autorisation**.
>
> **Audit conditionnel et interne :** regarde HEAD, changements non fusionnés, migrations/catalogue/R2, documentation et tests avant d'écrire. Si tu as déjà un état prouvé à jour, passe directement à l'implémentation. Sinon complète cette vérification en interne ; **ne renvoie pas un audit autonome et n'attends pas une réponse de l'opérateur**. N'affirme jamais que STAGING ou PROD a été testé sans preuve.
>
> **Livraison :** catalogue Admin dans Pédagogie ; dépôt sécurisé R2 ; source/licence vérifiée ; versions immuables ; publication atomique ; associations de classes ; retrait ; ports Flutter réels ; renderers ; réutilisation du picker classe LiveKit ; cache contrôlé ; UI mobile/tablette/desktop/light/dark/RTL ; toutes les recettes §8. Pas de fonctionnalité doublonnée ni d'écran mort.
>
> **Ordre :** sécurité base → ingestion R2 → Admin UX → branchement lecteurs → tests/intégration. Travailler sur une branche et respecter les agents concurrents. Réutiliser les modèles, routes, design tokens et composants existants. N'ajouter une migration que pour un besoin prouvé absent. Ne pas modifier aveuglément les anciennes migrations.
>
> **Stop uniquement si** : accès STAGING impossible pour test réel, exigence légale sans preuve, risque de fuite de données, besoin de production, ou conflit structurel insoluble. Dans ce cas coder et tester tout ce qui reste faisable sans risque, présenter un blocage précis à la fin, pas une liste de questions spéculatives.
>
> **État final attendu** : démonstration depuis navigation réelle du rôle Admin jusqu'à un support effectivement visible dans la bibliothèque de l'élève et présentable en classe, avec preuves de droits, tests de refus, signature R2, logs sûrs, captures Flutter et bilan PASS/BLOCKED/INCONNU. **Commence maintenant.**

## 11. Carte des preuves et liens de code consultés

- `main` : `lib/core/tc_bibliotheque/donnees_catalogue.dart` : providers encore locaux ; `catalogue_local.dart` : doubles/test.
- `main` : `lib/features/tc_catalogue/detail_ressource_page.dart` : aucun renderer contenu natif ; `class_library_picker.dart` : sélection sans déconnexion LiveKit.
- `main` : `lib/core/admin/admin_domaine.dart`, `lib/features/admin_pedagogie_programmes/programmes_page.dart` : domaine et sous-navigation Admin, modèle de versionnement.
- `main` : `supabase/migrations/0030_tc_socle.sql`, `0032_tc_catalogue.sql`, `0033_tc_vues_rpc.sql`, `0035_ressources_du_groupe_rejoue_visibilite.sql` : fondations et correctifs.
- `main` : `supabase/functions/_shared/r2/{domaines,cles,signature,client_appelant}.ts` : domaine `priveApplicatif`, `R2_APP_PRIVATE_*`, construction de clés et signatures, identification de l'appelant.
- `main` : `docs/teaching-core/TC_CONTRACT_REQUEST_B.md`, `TC_AGENT_B_REPORT.md`, `docs/design/08-catalogue-ecrans.md`.
- `main` : `supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md`, note **historique** datée 21/09, non une preuve d'état le 08/10.

**État de ce document :** handoff consolidé incluant quatre high-fi **à validation visuelle**, **pas du code livré ni une certification de sécurité/performance**. Aucune modification GitHub, Supabase ou R2 n'a été faite au titre de ce document.
