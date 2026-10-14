# Catalogue des écrans : Bibliothèque d'administration (CAP-29)

Fiche écran écrite **avant** le code (spec CAP-29, §9 étape CAP29-3). Le
catalogue historique `docs/design/08-catalogue-ecrans.md` n'existe plus dans
le dépôt depuis la remise à plat ; les fiches vivent dans `docs/current/`.

Source : `REWAYAH_CAP29_BIBLIOTHEQUE_HANDOFF_CANONIQUE_V1.md` (branche
`docs/specs-entrantes-2026-10-10`) et ses quatre maquettes M01 à M04.

## CAP-29 : place dans la navigation

| Élément | Décision |
| :--- | :--- |
| Domaine | **Pédagogie** (aucun neuvième domaine, aucun onglet principal) |
| Sous-navigation | 6ᵉ fonction « Bibliothèque », après Programmes, avant Qualité |
| Routes | `/admin/pedagogie/bibliotheque` (catalogue), `/admin/pedagogie/bibliotheque/:id` (fiche) |
| Port | `PortBibliothequeAdmin` (`lib/core/admin/port_bibliotheque_admin.dart`), nul en production |
| Double | `lib/features/demo/bibliotheque_admin_demo.dart` : 240 supports, tous types et états |
| Écrans | `lib/features/admin_pedagogie_bibliotheque/{catalogue,fiche,import,publication,attribution}/` |

## Écrans

| Id | Écran | Contenu | Maquette |
| :--- | :--- | :--- | :--- |
| CAP29-A | Catalogue | Recherche locale, segments Tous / Brouillons / À vérifier / Publiés / Retirés / Droits expirés, filtres type, niveau, langue, table (bureau) ou cartes (téléphone), pagination à curseur, aucun total | M01 |
| CAP29-B | Fiche d'un support | Deux colonnes (aperçu, édition, métadonnées ‖ workflow, versions, droits, historique, actions) ; une colonne repliable sur téléphone | M02 |
| CAP29-C | Ajouter / importer | Trois sections (ressource, fichier, droits), dépôt par intention, progression, annulation, erreurs | M04 |
| CAP29-D | Vérifier et publier | Criteres rendus par le serveur, blocages listés, « Publier la version » actif avec la phrase du blocage (jamais grisé), confirmation récapitulative | M03 |
| CAP29-E | Attribuer / retirer | Sélecteur de classes paginé, épinglage, retrait avec motif et confirmation | n/a |
| CAP29-F | Lecture classe, tuteur, élève | Branche la bibliothèque existante (`lib/features/tc_catalogue/`) sur le port réel, renderers par type | n/a |

## Règles de l'écran

- **Trois vocabulaires, jamais mélangés** : version (Brouillon / Publié /
  Archivé), revue des droits (À vérifier / Approuvé / Refusé / Expiré),
  retrait (fait distinct).
- **Un widget lit une capacité**, jamais un rôle : `CapacitesBibliotheque` et
  `CapacitesSupport` sont rendues par le serveur.
- **Aucun bouton grisé** : un geste impossible est soit non rendu, soit actif
  avec la phrase qui explique (la maquette M03 montre un bouton désactivé :
  elle n'est pas copiée).
- **Aucun total, aucun compteur codé en dur** ; aucune URL signée, clé R2 ni nom
  de fichier interne côté client.
- **États** : chargement, contenu, vide, vide filtré, erreur, hors ligne,
  non autorisé, indisponible (port absent), conflit d'édition, droits échus.
- Aucune couleur nouvelle ; tokens de thème seulement ; 320 px, texte ×2, RTL.

## Constat de l'existant (CAP29-0, sur ccr 744dac49, 10/10/2026)

- `lib/core/tc_bibliotheque/` : modèles `LibraryResource`, `ResourceVersion`
  (brouillon / publiée / archivée), ports `PortCatalogue`,
  `PortVersionsRessource`, doubles locaux ; `portCatalogueProvider` rend encore
  `CatalogueLocal()` (aucun adaptateur réel).
- `lib/features/tc_catalogue/` : bibliothèque de classe et picker existants.
- Migrations `0030`, `0032`, `0033`, `0035` présentes dans le dépôt ; aucune
  RPC `admin_library_*` ; `0034_r2_stockage.sql` présente.
- `supabase/functions/_shared/r2/` : domaine `priveApplicatif`
  (`R2_APP_PRIVATE_*`) présent ; `cles.ts` ne connaît pas encore les familles
  `libraryupload` ni `libraryproof` (à ajouter par CAP29-BACK-2).
- Aucune branche distante CAP-29 / bibliothèque d'administration.
- Statut inconnu, non testé ici : application de `0035` sur STAGING, contenu
  des secrets R2 sur STAGING, performance.

## Rapport de clôture CAP-29 (lot BIBLIOTHEQUE, branche `claude/bibliotheque`, 11/10/2026)

Statuts distingués : `spécifié` / `présent dans le code` / `testé localement` /
`testé sur staging` / `déployé`. **Rien n'est testé sur staging ni déployé.**
Tout ce qui est « testé localement » l'est sur le double de démonstration
(`BibliothequeAdminDemo`) ; le provider réel du port est `null` jusqu'à
CAP29-BACK-1 (Codex).

### Écrans livrés (présents dans le code, testés localement)

| Fiche | Écran | Preuve locale |
| :--- | :--- | :--- |
| CAP29-0 | Onglet, routes, ports, double de démo | `socle_test` (10) |
| CAP29-A | Catalogue : recherche, segments, filtres, curseur sans total | `catalogue_test` (13) |
| CAP29-B | Fiche : édition d'un brouillon, versions, droits, périmètre, historique | `fiche_test` (17) |
| CAP29-C | Import : dépôt par intention, progression, annulation, preuve | `import_test` (12) |
| CAP29-D | Vérifier et publier : contrôle serveur, blocages, confirmation | `publication_test` (14) |
| CAP29-E | Attribuer (classes paginées, épinglage) et retirer (motif, confirmation, trace) | `attribution_test` (13) |
| CAP29-F | Rendu par type côté classe (image rendue ; Coran jamais rendu ici ; PDF, texte, leçon : « aucun lecteur » dit tel quel) ; l'enseignant entre dans `/tc/bibliotheque` | `rendu_ressource_test` (10), `redirection_test` |
| CAP29-G | `PortSupportActif` (activer, suivre, capacités) + double ; `SupportActifClasse` (la classe suit sans bouton) ; `PresentationPort` (rappel `PresenterSupport` de la bibliothèque de la salle, activation à l'appel, clé reprise) | `support_actif_test` (21) |
| CAP29-H | Arabe complet `admin.bibliotheque.*` et `tc.bibliotheque.rendu.*` (265 clés), arabe 320 px ×2 RTL des cinq écrans, captures 4 cadrages | `arabe_test` (5), `capture_bibliotheque_admin_test` (20 captures, `CAPTURE_DIR`) |

### Les 20 scénarios CAP29-01 à 20

| # | Statut | Ce qui est vrai |
| :--- | :--- | :--- |
| 01 | testé localement | l'onglet Bibliothèque est atteint au clic depuis Pédagogie ; capacité de lecture requise |
| 02 | testé localement | catalogue vide utile ; brouillon créé sans publication |
| 03 | BLOCKED | clé R2, URL signée expirante, hash : serveur (CAP29-BACK) ; le client dépose par intention et ne garde aucune URL |
| 04 | BLOCKED (serveur) / testé localement (client) | refus taille/type rendu et expliqué ; l'analyse du fichier est côté serveur |
| 05 | testé localement | sans preuve, la publication est bloquée et expliquée |
| 06 | INCONNU | l'aperçu est honnête (aucun lecteur PDF) ; seule l'image est rendue ; le test de rendu est un critère rendu par le serveur |
| 07 | testé localement (client) / BLOCKED (bascule atomique serveur) | v2 en brouillon séparée ; v1 figée |
| 08 | testé localement (client) / BLOCKED (serveur) | conflit de révision dit ; clé d'idempotence par tentative |
| 09 | BLOCKED | l'attribution est testée côté écran ; l'isolation entre classes est une RLS serveur |
| 10 | testé localement (port + double) / BLOCKED (serveur) | `PortSupportActif` : la classe suit sans geste, le « Presenter » de la bibliotheque de la salle ne part qu'avec la capacite ; la synchronisation reelle (BR-1), la reprise apres reconnexion et LiveKit restent au serveur ; branchement dans `/salle` non fait (provider reel `null`) |
| 11 | BLOCKED | non-fuite entre foyers : serveur |
| 12 | BLOCKED (serveur) / testé localement (écran de retrait) | motif obligatoire, confirmation, trace d'audit ; durée de vie d'une URL existante non documentée côté client |
| 13 | testé localement (affichage) / BLOCKED (refus serveur) | droits expirés visibles, filtre dédié |
| 14 | testé localement (320 px ×2, LTR, RTL, arabe, sombre 390, Tab + Entrée sur l'attribution, noms de boutons et champs en sémantique, captures clair 320/390/768/1440) | passage lecteur d'écran réel (TalkBack, VoiceOver) : INCONNU |
| 15 | INCONNU | cache hors ligne persistant : non exercé |
| 16 | testé localement (double) | l'échec de dépôt à chaque phase ne publie rien ; jamais d'état éternel |
| 17 | BLOCKED (serveur) / testé localement (écran non autorisé) | aucune action sans capacité |
| 18 | BLOCKED | staging, R2 isolé, SQL/RLS : CAP29-BACK |
| 19 | BLOCKED | FK et historique : serveur |
| 20 | BLOCKED | p95/p99 sur staging ; le client pagine à curseur et ne scanne pas tout |

### Écarts à connaître

- Ports : `facettes`, `revoirDroits` et `FinaliteUpload` : ligne Contrats C-30 bis publiée le 11/10. `PortSupportActif` (CAP29-G) : ligne Contrats C-34.
- Salle : `PresentationPort.pourSeance()` n'est pas encore appelé par `/salle` (les fichiers de la salle n'ont pas été modifiés) ; le rappel est prêt pour `onPresenter` des `ActionsSeance`.
- Aperçu : sans lecteur PDF, texte structuré ni leçon dans `pubspec.yaml` ; le rendu réel attend ces lecteurs.
- Captures : clair seulement ; pas de comparaison pixel aux maquettes M01 à M04 (aucune référence versionnée dans le dépôt) ; défaut corrigé grâce aux captures : mots coupés dans les pastilles et la visibilité du tableau du catalogue à 1440 px.
- Arabe : traduction écrite sans relecture par un locuteur natif.
- Vérificateur non auteur : à faire.
