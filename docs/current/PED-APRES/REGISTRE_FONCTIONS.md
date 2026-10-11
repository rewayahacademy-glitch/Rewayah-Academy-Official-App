# PED-APRES-1 · Registre des fonctions (spec §9) : conservées, modifiées, absentes

Preuve : `git diff origin/ccr-1b1bfa0b-m1kvkk...claude/ped-apres-1 --stat` ; tests dans `test/features/ped_apres/`, `test/capacites/port_partage_pedagogique_test.dart` ; captures dans `docs/current/captures/PED-APRES-1/`.

| Fonction | Fichier | Avant | Après | Statut |
| :--- | :--- | :--- | :--- | :--- |
| Cahier K-45, dépôt, file hors ligne | `features/cahier/*`, `core/enseignant/*`, `core/cache/sync/file_rapports.dart` | existe | **inchangé** | CONSERVÉE (diff vide) |
| Historique, filtres, sélecteur d'élève | `features/suivi_foyer/suivi_foyer_page.dart`, `filtres_historique.dart` | existe | inchangés | CONSERVÉE |
| Détail de séance (séance, présence, sort du cours) | `features/suivi_foyer/detail_seance_page.dart` | 2 cartes | + bloc « Compte rendu pédagogique » sous condition (séance tenue) | MODIFIÉE |
| Travail à préparer, Progression | `features/classe_tuteur/*` | existent | inchangés, liens depuis le détail pour le même élève | CONSERVÉE |
| Port résumé famille (texte) | `core/capacites/port_resume_seance_famille.dart` | indisponible | inchangé (compatibilité adaptateur Codex F2) | CONSERVÉE |
| Port progression famille | `core/capacites/port_progression_famille.dart` | indisponible | inchangé | CONSERVÉE |
| Inspecteur de classe / feuille de détail mobile | `features/admin_groupes/groupes_page.dart` | infos + membres | + `GroupePartageClasse` au même endroit des deux | MODIFIÉE |
| Réglage d'observation par classe | `features/admin_groupes/feuille_observation_groupe.dart` | existe | inchangé | CONSERVÉE |
| Qualité, Progression admin, Configuration | `features/admin_pedagogie_*`, `admin_configuration_*` | existent | inchangés | CONSERVÉE |
| Port de partage pédagogique | `core/capacites/port_partage_pedagogique.dart` (+ démonstration) | absent | créé, production indisponible | NOUVELLE (frontend) |
| Rendu du compte rendu (tuteur et aperçu admin) | `features/suivi_foyer/bloc_compte_rendu.dart` | absent | créé, une seule source de rendu | NOUVELLE |
| Réglage de classe, exceptions, règle d'élève | `features/admin_groupes/reglage_partage.dart`, `partage_commun.dart` | absent | créés | NOUVELLE |
| Aperçu familial, liste des comptes rendus, publier / révoquer | `features/admin_groupes/apercu_familial.dart` | absent | créé, sous condition de port | NOUVELLE, entrée provisoire |
| Nouvelle destination globale, route, onglet, module « Rapports » | n/a | absent | **absent, voulu** | ABSENTE |
| Saisie enseignante supplémentaire | n/a | absent | **absente, voulue** | ABSENTE |
| Aperçu côté famille comparatif de la planche 02, « Points positifs », « Prochaine séance », « Réécouter » | n/a | absents | non implémentés (aucune source) | ABSENTE |
| Adaptateur Supabase, migration, RPC, RLS | n/a | absents | **non écrits** | ABSENTE (BLOQUÉ PAR CONTRAT) |

Fichiers hors lot modifiés : `assets/i18n/{fr,ar}.i18n.json` et `lib/core/i18n/strings*.g.dart` (régénérés), `tool/libelles_sources.json` (sources des 100 libellés).
