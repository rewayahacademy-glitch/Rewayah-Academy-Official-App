# PED-APRES-1 · Audit de l'étape 0 (spec §7), avant tout code

**Date :** 11 octobre 2026 · **Branche :** `claude/ped-apres-1`, créée depuis `origin/ccr-1b1bfa0b-m1kvkk` (HEAD `01ac4026`)
**Portée :** frontend seul. Aucune migration, RPC, RLS, `*_supabase.dart`, aucun push sur `main`, aucun déploiement.
**Statuts de preuve :** chaque ligne dit `spécifié` / `présent dans le code` / `testé localement`. Rien n'est `testé sur staging` ni `déployé`.

## 1. Carte fichier → route → écran → provider → modèle → contrat → tests

### TUT-PED-APR-01 · Détail de séance du tuteur

| Maillon | Réel (lu au HEAD) |
| :--- | :--- |
| Route | `Routes.tuteurSuivi` (liste) puis `/tuteur/seances/:seanceId?eleve=` (page de niveau 2, l'Historique reste actif dans la barre) |
| Écran | `lib/features/suivi_foyer/detail_seance_page.dart` (`DetailSeancePage`, 264 lignes) : titre = classe, deux cartes (« Séance », « Présence de … »), note de fuseau |
| Providers | `seancesDuSuiviProvider`, `presenceDuSuiviProvider`, `classesCourantesProvider`, `classeDesSeancesProvider`, `eleveSelectionneProvider` |
| Modèles | `Seance` (`core/planning/service_planning.dart`), `PresenceParticipant`, `LigneSuivi` / `VueSuiviFoyer` |
| Contrat résumé | `lib/core/capacites/port_resume_seance_famille.dart` : `Future<String?> resume({seanceId, eleveId})`, production = `ResumeSeanceFamilleIndisponible` (lève `CapaciteIndisponible('DB-CRS-12')`). **Aucun écran ne le lit** : `grep` montre qu'il n'est consommé que par les tests et `progression_classe_page` (progression, pas résumé) |
| Contrat progression | `port_progression_famille.dart` : `ProgressionEleve` (niveau humain, jalons), production = indisponible (`DB-CRS-11`) |
| Tests | `test/features/historique/historique_test.dart` (ouverture, annulée, non tenue, lien profond, desktop), `test/accessibilite/tuteur_k_echelle_texte_test.dart`, `test/capacites/ports_capacites_test.dart` |
| Liens aval | Classe du tuteur : `Routes.classeTuteurSousPage(classeId, 'travail' | 'progression')` (`routes.dart:342-358`) |

### ADM-PED-APR-02 · Inspecteur de classe

| Maillon | Réel |
| :--- | :--- |
| Route | Admin > Opérations > Classes (`GroupesPage`, sous-navigation `ongletsOperations`, onglet 1) |
| Écran | `lib/features/admin_groupes/groupes_page.dart` (1891 lignes). Sur bureau (≥ 336 + 600 + marge, texte < 200 %) : `_Inspecteur` (classe 336 px, `AppCard`) ; sinon la ligne ouvre `_FeuilleDetail` en `AppBottomSheet` |
| Contenu actuel de l'inspecteur | titre, pastille d'état, « Informations générales », liste des membres (`_FeuilleDetail`, `membresGroupeProvider`), menu d'actions (seuil, observation, fusion, clôturer) et « Ajouter » |
| Providers | `pageClassesAdminProvider`, `groupesProvider`, `membresGroupeProvider(groupeId)`, `serviceGroupesProvider` |
| Modèles | `ClasseListee`, `GroupeAdmin`, `MembreGroupe` (`core/admin/port_classes_admin.dart`, `service_groupes.dart`) |
| Précédent à imiter | `FeuilleObservationGroupe` (réglage d'observation par classe, déjà dans le menu de l'inspecteur) : même gabarit feuille + enregistrement |
| Contrat politique de partage | **Aucun.** Ni `grep partage`, ni port, ni modèle |
| Tests | `test/features/admin_groupes/classes_echelle_test.dart`, `test/features/classe_form_1_test.dart`, `test/features/filtres1_rangee_unique_test.dart` |

### ADM-PED-APR-03 · Lecture administrative d'un cahier

Recherche faite : `lesson_reports` n'est lu côté Flutter que par `service_enseignant.dart` (écriture `insert`, cahier K-45) et, pour le *manque* de rapport, par `service_qualite.dart` (`anomalies_qualite()`). Les écrans admin qui touchent aux séances (`admin_planning/ligne_seance_direction.dart`, `admin_pedagogie_qualite/qualite_page.dart`, `revue_groupe`, `controleur/*`) n'ouvrent **aucun cahier confirmé**. `QualitePage` ne liste que les rapports **manquants**, sa feuille de traitement n'affiche pas le contenu.

**Conclusion : il n'existe pas de point réel de lecture administrative d'un cahier confirmé.** Conformément à la spec (§3, §7 étape 3, arrêts obligatoires), voir la décision proposée au §6.

### K-45 · Cahier enseignant (GELÉ)

`lib/features/cahier/{cahier_page,vue_cahier,selecteur_reprise,makharij}.dart`, `core/enseignant/{service_enseignant,modeles_enseignant,depot_cahiers}.dart`, file hors ligne `core/cache/sync/file_rapports.dart`, route `Routes.cahierPour(seanceId)`. **Aucune modification dans ce lot** (contrôle : `git diff` ne doit toucher aucun de ces fichiers).

## 2. Statut prouvé par capacité

| # | Capacité | Statut | Preuve |
| :--- | :--- | :--- | :--- |
| 1 | Détail de séance : séance, présence, sort du cours (annulée / non tenue / à vérifier) | **EXISTE ET FONCTIONNE** | `detail_seance_page.dart`, `historique_test.dart` (annulée, non tenue, présence illisible) |
| 2 | Bloc « Compte rendu pédagogique » dans le détail | **ABSENT** | aucune occurrence dans l'écran ni dans `assets/i18n/fr.i18n.json` |
| 3 | Port résumé famille | **EXISTE MAIS NON RACCORDÉ** | `port_resume_seance_famille.dart` : 1 chaîne, production indisponible, jamais lu par un écran. Insuffisant seul (pas d'état partagé / désactivé / en attente / révoqué / corrigé, pas de champs structurés) |
| 4 | Adaptateur Codex du résumé | **NON VÉRIFIABLE** | `origin/codex/backend-f2-after-c` implémente `PortResumeSeanceFamille` à l'identique (RPC `resume_seance_famille`, texte publié). Non fusionné ; ne prouve ni publication auto, ni politique, ni révocation (spec §1). **Ne pas modifier la signature du port existant**, sinon l'adaptateur Codex ne compile plus |
| 5 | Liens « Voir le travail à préparer » / « Voir la progression » | **EXISTE MAIS NON RACCORDÉ** depuis le détail | routes `classeTuteurSousPage(...,'travail'|'progression')` présentes ; la progression familiale est une source indisponible (`DB-CRS-11`) |
| 6 | Politique de partage (classe, élève) | **ABSENT** | aucun port, aucun modèle, aucune clé i18n |
| 7 | Bloc de réglages de partage dans l'inspecteur | **ABSENT** | `_Inspecteur` ne contient que infos, membres, actions |
| 8 | Liste des élèves avec règle appliquée et visibilité | **ÉCART UX** | la liste des membres existe (`_FeuilleDetail`, `ListTile` + `MenuActions` « Retirer ») mais sans règle ni visibilité |
| 9 | Aperçu familial administratif et publication / révocation ciblée | **ABSENT** | pas de lecture admin d'un cahier confirmé (§1) |
| 10 | Historique des actions d'un compte rendu | **NON VÉRIFIABLE** | aucune source ; n'est affiché que si le port la fournit |
| 11 | Détection hors ligne | **EXISTE ET FONCTIONNE** | `horsLigneProvider` (`core/reseau/service_reseau.dart`), `EtatSansDonnees` |
| 12 | Vidage des projections au changement d'élève / foyer | **NON VÉRIFIABLE** pour ce bloc (n'existe pas) ; `eleveSelectionneProvider` existe |
| 13 | Interrupteur existant pour la politique d'observation par classe | **EXISTE ET FONCTIONNE** | `FeuilleObservationGroupe` : **à conserver**, ne pas confondre avec le partage pédagogique |
| 14 | Démonstration identifiée derrière les drapeaux de démo | **EXISTE** (mécanisme) | `Env.galerieActive`, `Env.playgroundActif` (`core/config/env.dart`), forcés à `false` en production |
| 15 | i18n en/ar | **ÉCART** | seuls `fr` et `ar` existent (`assets/i18n/fr.i18n.json`, `ar.i18n.json`) ; pas d'`en` : on tient fr et ar |

## 3. Écarts entre l'écran actuel et les planches

### Planche 01 (tuteur, mobile sombre) contre `DetailSeancePage`

À reprendre (hiérarchie et placement) :
- le bloc « Compte rendu pédagogique » **après** Séance et Présence, avant les liens et la barre ;
- ordre des rubriques : Ce qui a été travaillé, Appréciation, À renforcer, À préparer, Commentaire partagé ;
- le message neutre « Compte rendu pédagogique non disponible » quand le partage est désactivé.

À ignorer (spec §4, « Corrections obligatoires ») :
- valeurs de démonstration : Mariam, Al-Baqara 20-30, « Séance validée », 17h58, 1h01, F1, Groupe A, dates ;
- la barre basse dessinée (« Accueil, Mes enfants, Messages, Plus ») : on garde la barre réelle Accueil, Foyer, Historique, Compte ;
- « Points positifs » : **aucune source** dans le contrat (pas de champ « points positifs » partageable) ; ne pas l'inventer ;
- l'encart « Prochaine séance » et la mention « Voir la classe » : non requis par la spec, aucune source ;
- l'avatar et le menu « … » : le détail est en lecture seule, aucun bouton de modification ;
- la durée « réelle » : le détail actuel montre déjà durée prévue, arrivée, interruption ; on n'ajoute rien.

### Planche 02 (admin, réglage de partage, web) contre `_Inspecteur`

À reprendre : un groupe « Partage des comptes rendus pédagogiques » avec interrupteur de classe, aide fixe, action « Gérer les exceptions individuelles », liste des élèves (règle appliquée, visibilité, dernière modification), priorité en une ligne.

À ignorer :
- les « 12 élèves », « Niveau 1 », dates et auteurs fictifs, « Voir dans l'application » ;
- la navigation latérale dessinée (Tableau de bord, Élèves, Parents, Rapports, Paramètres) : c'est le shell réel qui reste ;
- le panneau « Aperçu côté famille » avec deux cartes comparées : décoratif, **pas dans le périmètre** (l'aperçu exact est ADM-PED-APR-03) ;
- « Dernière modification de la règle » en colonne : affichée seulement si le port la fournit ;
- le menu contextuel dessiné (⋮) : on utilise `MenuActions`.

### Planche 03 (admin, aperçu et publication manuelle, web) contre l'existant

À reprendre : aperçu exact en colonne principale, colonne « Diffusion vers la famille », état de publication, historique si la source existe.

À ignorer :
- **Publier et Révoquer actifs ensemble : interdit.** Un seul CTA cohérent avec l'état ;
- « Dernière mise à jour », noms, dates, « Niveau 1 », « Séance validée » fictifs ;
- le fil d'Ariane et le menu latéral dessinés : shell réel ;
- le bouton rouge plein « Révoquer l'accès » : une action destructive passe par `ConfirmDestructive` / `MenuActions`, pas par un second gros bouton plein (K-56) ;
- « Rapport consulté » dans l'historique : on n'invente pas une piste d'audit.

## 4. Décisions d'architecture (frontend seul)

1. **Le port existant `PortResumeSeanceFamille` n'est pas modifié** (compatibilité avec l'adaptateur Codex F2). Il reste le contrat du *texte publié* ; il n'est pas lu par le détail.
2. **Un seul nouveau port** : `lib/core/capacites/port_partage_pedagogique.dart`, qui porte les trois besoins du lot : lecture du compte rendu familial d'un (élève, séance), politique de partage (classe, élèves), publication / révocation ciblée. Implémentation de production = `CapaciteIndisponible`, aucun adaptateur Supabase. Démonstration identifiée, derrière `Env.galerieActive` ou `Env.playgroundActif`. Contrat écrit en fin de lot : `CONTRAT_PORTS_PED_APRES.md`.
3. **Zéro nouvelle destination globale, zéro nouvelle route.** TUT-01 complète la page existante. ADM-02 complète `_Inspecteur` **et** la feuille de détail mobile (même groupe de réglages, un seul widget). Les exceptions s'ouvrent en `AppBottomSheet`.
4. **Zéro saisie enseignante.** Aucun fichier de `lib/features/cahier/` ni de `lib/core/enseignant/` n'est touché.

## 5. Mini-plan

**Fichiers existants modifiés**
- `lib/features/suivi_foyer/detail_seance_page.dart` : bloc « Compte rendu pédagogique » + états.
- `lib/features/admin_groupes/groupes_page.dart` : insertion du groupe de réglages dans `_Inspecteur` et dans `_ouvrirDetail`.
- `assets/i18n/fr.i18n.json`, `assets/i18n/ar.i18n.json` (puis `lib/core/i18n/strings*.g.dart` régénérés), `tool/libelles_sources.json`.
- `lib/core/router/routes.dart` / `app_router.dart` : **aucun changement prévu**.

**Fichiers nouveaux, strictement nécessaires**
- `lib/core/capacites/port_partage_pedagogique.dart` (port, modèles, implémentation indisponible, démonstration, providers).
- `lib/features/suivi_foyer/bloc_compte_rendu.dart` (le bloc, partagé avec l'aperçu admin : une seule source de rendu).
- `lib/features/admin_groupes/reglage_partage.dart` (groupe de réglages, feuille des exceptions).
- `lib/features/admin_groupes/apercu_familial.dart` (feuille d'aperçu et de publication ciblée, composant de lecture + actions sous condition de port).
- Tests `test/features/ped_apres/*` (A01 à A22), `test/capacites/` pour le port.
- `CONTRAT_PORTS_PED_APRES.md`, `REGISTRE_FONCTIONS.md`, `DEPENDANCES_BACKEND.md` dans `docs/current/PED-APRES/`.

**Tests impactés** : `historique_test.dart`, `tuteur_k_echelle_texte_test.dart`, `classes_echelle_test.dart`, `ports_capacites_test.dart`.

**Contrats indisponibles** (donc états honnêtes, pas de succès simulé en production) : compte rendu famille structuré, politique de classe, exceptions élève, publication et révocation ciblées, historique d'actions.

## 6. Points à signaler à l'orchestrateur et au directeur (rien d'inventé)

1. **ADM-PED-APR-03 : aucun point de lecture administrative d'un cahier confirmé n'existe.** Proposition minimale, sans route ni module : la feuille d'aperçu et de publication s'ouvre depuis la **liste des élèves de l'inspecteur** (ADM-02), ligne d'un élève → « Voir les comptes rendus » → liste des séances de cet élève (fournie par le port) → feuille d'aperçu. C'est un **point d'entrée provisoire** ; à confirmer par le directeur. Si le directeur refuse, la feuille reste en composant de lecture non interactif, non atteignable.
2. **Le port résumé existant (`String?`) ne suffit pas** à rendre les états de la spec ; d'où le port unique du §4. Codex devra rapprocher `resume_seance_famille` (migration 0054) de ce contrat (voir `CONTRAT_PORTS_PED_APRES.md`).
3. **Pas de `en`** dans le projet : fr et ar seulement.
4. Les planches montrent « Points positifs » : aucune source dans le contrat ; **non rendu**.

## 7. Table anti-doublon

| Fonction | Fichier réel existant | Décision | Avant | Après (visé) |
| :--- | :--- | :--- | :--- | :--- |
| Détail de séance | `suivi_foyer/detail_seance_page.dart` | **Modifier sur place** | séance + présence | + bloc compte rendu |
| Historique (liste) | `suivi_foyer/suivi_foyer_page.dart` | **Conserver** | existe | inchangé |
| Travail à préparer, Progression | `classe_tuteur/{travail,progression}_classe_page.dart` | **Conserver**, liens depuis le détail | existent | inchangés |
| Cahier K-45 | `cahier/*`, `core/enseignant/*` | **Conserver, gelé** | existe | inchangé |
| Résumé famille (texte) | `capacites/port_resume_seance_famille.dart` | **Conserver tel quel** | port indisponible | inchangé |
| Progression famille | `capacites/port_progression_famille.dart` | **Conserver** | port indisponible | inchangé |
| Inspecteur de classe | `admin_groupes/groupes_page.dart` | **Modifier sur place** | infos + membres | + groupe de réglages |
| Réglage d'observation par classe | `admin_groupes/feuille_observation_groupe.dart` | **Conserver** | existe | inchangé |
| Qualité / Progression admin | `admin_pedagogie_*` | **Conserver** | existent | inchangés |
| Configuration générale | `admin_configuration_fonctionnalites/*` | **Conserver**, ne pas y poser l'exception élève | existe | inchangé |
| Politique de partage, exceptions, publication ciblée | (aucun) | **Créer le minimum** : un port + deux widgets | absent | port + groupe de réglages + feuille |
| Lecture admin d'un cahier confirmé | (aucun) | **Signaler** (§6.1) | absent | feuille atteinte depuis l'inspecteur, provisoire |
| Nouveau module « Rapports », nouvelle route, nouvel onglet | n/a | **Interdit, non créé** | n/a | n/a |
