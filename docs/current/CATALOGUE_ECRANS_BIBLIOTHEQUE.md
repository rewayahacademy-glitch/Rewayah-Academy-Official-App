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
