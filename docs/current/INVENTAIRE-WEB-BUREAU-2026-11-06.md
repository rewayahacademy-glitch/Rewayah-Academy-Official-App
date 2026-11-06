# Inventaire WEB-BUREAU (06/11/2026)

Lot PLAN-LOTS §7 rang 22 n, étape 1 : l'inventaire, **sans code applicatif**, à valider par le
garde-cap avant le premier changement. Lu sur `origin/main` (7b3a3f05, 06/11 vers 17:00 UTC).
Définition proposée en regard : `DEFINITION-PAGE-ORDINATEUR-2026-11-06.md`.

## 0. Ce qui est faux, inconnu ou non prouvé (en premier)

- **Les colonnes « indice de bureau » ci-dessous sont lues dans le code, pas mesurées.** Un écran
  qui cite `AppGabarit` peut quand même étirer ses cartes. Seule la mesure à 1440 (liste
  `WEB-BUREAU/liste-avant/rapport.json`, robot, et le futur garde-fou) fait foi pour B1, B2, B3 et
  B5. B4, B6 et B7 (largeur de lecture, tête, pied) ne sont pas encore mesurés : le garde-fou les
  mesurera dans les tests Flutter, une fois la définition validée.
- **La pile locale a peu de données** (un foyer, un élève, une classe). Les captures « avant » à
  1440 montrent donc moins d'étirement que la capture du directeur (Foyer à 1366, avec de vraies
  données). Elles ne remplacent pas sa capture.
- **La barre latérale de la famille n'est pas dans l'arbre d'accessibilité du web** (constat du lot
  FIL-ARIANE, déjà noté « ECART onglet absent » par les anciens robots). Le robot la détecte sur la
  capture (`tool/e2e/barre_laterale.py`). Cause non trouvée.
- **Une page poussée (`push`) ne change pas l'adresse du navigateur** (go_router par défaut) : la
  Bibliothèque ouverte depuis le Compte garde `#/tuteur/compte` ; un rechargement ramène au Compte.

- **Verdicts du garde-cap reçus le 06/11 (17:09 UTC)** : `/avis/:jeton` devient une exception
  permanente ; `/tc/mushaf` une exception temporaire, à fermer par une redirection vers
  `/eleve/coran` ; la barre latérale absente de l'arbre d'accessibilité et l'adresse inchangée après
  un `push` entrent dans ce lot. La fiche Finances en arabe et la ligne Bibliothèque de l'enseignant
  vont en 22 b.
- **La cause écrite du problème du directeur** est dans la Bible (`08-catalogue-ecrans.md` §6) : la
  présentation de bureau de `TUT-01`, `ENS-02`, `ADM-01` et `TUT-05` y est notée « non
  implémentée, reportée », et ce report n'a jamais été repris (voir la définition, §2).

## 1. Chiffres, par rôle (229 chemins de production, `app_router.dart` et listes dépliées)

| Rôle | Chemins | Dans une coquille | Hors coquille | Redirection seule | Indice de bureau dans le code | dont table `DataCollection` | dont `EspaceTravailAdaptatif` | Aucun indice |
|---|---|---|---|---|---|---|---|---|
| Entrée (sans rôle) | 29 | 0 | 26 | 3 | 11 | 0 | 0 | 15 |
| Partagé (`/compte`, `/tc`, `/recherche`, `/salle`) | 17 | 10 | 7 | 0 | 15 | 0 | 0 | 2 |
| Élève | 13 | 13 | 0 | 0 | 9 | 1 | 0 | 4 |
| Famille | 60 | 53 | 0 | 7 | 45 | 0 | 2 | 8 |
| Enseignant | 19 | 13 | 6 | 0 | 13 | 1 | 5 | 6 |
| Contrôle | 7 | 4 | 3 | 0 | 7 | 0 | 0 | 0 |
| Direction | 69 | 55 | 0 | 14 | 32 | 19 | 6 | 23 |
| Comptabilité | 15 | 15 | 0 | 0 | 12 | 11 | 0 | 3 |

« Coquille » : une `StatefulShellRoute` de rôle, `_CoquilleSecondaire` (`/compte`, `/recherche`)
ou `_CoquilleAdmin` (direction). « Indice de bureau » : l'écran ou son dossier cite `AppGabarit`
(`Gabarit.desktop`, `estLarge`), une table `DataCollection` ou `EspaceTravailAdaptatif`. Liste
complète, ligne par ligne : `captures/E2E/WEB-BUREAU/routes-statique.json`.

## 2. Routes de rôle hors de toute coquille (16) : sur ordinateur, ni barre latérale ni sortie garantie

| Route | Rôle | Écran | Source |
|---|---|---|---|
| `/enseignant/bienvenue` | enseignant | `BienvenueEnseignantPage` | `lib/core/router/app_router.dart:1551` |
| `/enseignant/contrat` | enseignant | `ContratPage` | `lib/core/router/app_router.dart:1558` |
| `/enseignant/seance/:seanceId/cahier` | enseignant | `CahierPage` | `lib/core/router/app_router.dart:1562` |
| `/enseignant/groupe/:groupeId` | enseignant | `FicheGroupePage` | `lib/core/router/app_router.dart:1567` |
| `/enseignant/groupe/:groupeId/revue` | enseignant | `RevueGroupePage` | `lib/core/router/app_router.dart:1575` |
| `/enseignant/groupe/:groupeId/annonce` | enseignant | `PublierAnnonceClassePage` | `lib/core/router/app_router.dart:1582` |
| `/controleur/mfa` | controle | `MfaControleurPage` | `lib/core/router/app_router.dart:1596` |
| `/tc/groupes` | partage | `MesGroupesPage` | `lib/features/tc_mes_groupes/routes_tc_a.dart:36` |
| `/tc/groupes/:groupeId` | partage | `EspaceGroupePage` | `lib/features/tc_mes_groupes/routes_tc_a.dart:45` |
| `/tc/bibliotheque` | partage | `BibliothequePage` | `lib/features/tc_catalogue/routes_tc_b.dart:78` |
| `/tc/bibliotheque/:resourceId` | partage | `DetailRessourcePage` | `lib/features/tc_catalogue/routes_tc_b.dart:83` |
| `/tc/mushaf` | partage | `MushafPage` | `lib/features/tc_mushaf/routes_tc_c.dart:26` |
| `/tc/observation/:seanceId` | partage | `EntreeObservationPage` | `lib/features/tc_observation_ui/routes_tc_g.dart:38` |
| `/salle` | partage | `PorteeOutilsSalle` | `lib/core/router/app_router.dart:2762` |
| `/controleur/compte-rendu` | controle | `CompteRenduControlePage` | `lib/core/router/app_router.dart:2806` |
| `/controleur/compte-rendu/observation` | controle | `ObservationControlePage` | `lib/core/router/app_router.dart:2818` |

Les 26 pages d'entrée (questionnaire, connexion, inscription, attente, juridique, avis) sont aussi
hors coquille : elles n'ont pas de rôle, c'est voulu (exception écrite de la définition, §3).

## 3. Écrans de rôle sans aucun indice de bureau dans le code (46)

| Route | Rôle | Écran | Fichier |
|---|---|---|---|
| `/recherche` | partage | `PageRecherche` | `lib/features/recherche/page_recherche.dart` |
| `/compte/paiements-recus` | partage | `RecevoirPaiementsPage` | `lib/features/paiements_recus/recevoir_paiements_page.dart` |
| `/eleve` | eleve | `?` | `?` |
| `/eleve/adulte/demandes` | eleve | `SuiviFamillePage` | `lib/features/suivi_famille/suivi_famille_page.dart` |
| `/eleve/adulte/demandes/:demandeId` | eleve | `FriseDemandePage` | `lib/features/suivi_famille/suivi_famille_page.dart` |
| `/eleve/adulte/classe` | eleve | `MaClasseAdultePage` | `lib/features/ma_classe_adulte/ma_classe_adulte_page.dart` |
| `/tuteur/inscription-reprise` | famille | `AccueilInscritsPage` | `lib/features/accueil_inscrits/accueil_inscrits_page.dart` |
| `/tuteur/presentation` | famille | `DemandesPresentationPage` | `lib/features/presentation_tuteur/demandes_presentation_page.dart` |
| `/tuteur/demandes` | famille | `?` | `?` |
| `/tuteur/demandes/:demandeId` | famille | `FriseDemandePage` | `lib/features/suivi_famille/suivi_famille_page.dart` |
| `/tuteur/demandes/:demandeId/changement` | famille | `ChangementClassePage` | `lib/features/suivi_demandes/changement_classe_page.dart` |
| `/tuteur/foyer/inviter` | famille | `?` | `?` |
| `/tuteur/parcours/:eleveId` | famille | `ParcoursOffresPage` | `lib/features/parcours_offres/parcours_offres_page.dart` |
| `/tuteur/compte/consentements` | famille | `ConsentementObservationPage` | `lib/features/consentements/consentement_observation_page.dart` |
| `/enseignant/journee` | enseignant | `JourneePage` | `lib/features/journee/journee_page.dart` |
| `/enseignant/journee/a-terminer` | enseignant | `ListeATerminerPage` | `lib/features/journee/journee_page.dart` |
| `/enseignant/journee/remplacements` | enseignant | `RemplacementsPage` | `lib/features/remplacements/remplacements_page.dart` |
| `/enseignant/journee/alertes` | enseignant | `ListeAlertesPage` | `lib/features/journee/journee_page.dart` |
| `/enseignant/classes` | enseignant | `MesClassesPage` | `lib/features/enseignant_classes/mes_classes_page.dart` |
| `/enseignant/groupe/:groupeId/revue` | enseignant | `RevueGroupePage` | `lib/features/revue_groupe/revue_groupe_page.dart` |
| `/admin` | direction | `TableauDeBordPage` | `lib/features/admin_tableau/tableau_de_bord_page.dart` |
| `/admin/alertes` | direction | `AlertesPage` | `lib/features/alertes/alertes_page.dart` |
| `/admin/operations/planning` | direction | `PlanningPage` | `lib/features/admin_planning/planning_page.dart` |
| `/admin/operations/demandes` | direction | `DemandesPage` | `lib/features/admin_demandes/demandes_page.dart` |
| `/admin/operations/offres` | direction | `AdminOffresPage` | `lib/features/admin_offres/admin_offres_page.dart` |
| `/admin/operations/avis` | direction | `AvisAdminPage` | `lib/features/admin_avis/avis_page.dart` |
| `/admin/operations/courriels` | direction | `CourrielsAdminPage` | `lib/features/admin_courriels/courriels_page.dart` |
| `/admin/personnes/demandes` | direction | `AdmissionsPage` | `lib/features/admin_admissions/admissions_page.dart` |
| `/admin/personnes/suppressions` | direction | `SuppressionsPage` | `lib/features/admin_suppressions/suppressions_page.dart` |
| `/admin/personnes/reprises` | direction | `ReprisesPage` | `lib/features/admin_reprises/reprises_page.dart` |
| `/admin/personnes/import` | direction | `ImportInscriptionsPage` | `lib/features/admin_import_inscriptions/import_inscriptions_page.dart` |
| `/admin/personnes/invitations` | direction | `InvitationsPage` | `lib/features/admin_invitations/invitations_page.dart` |
| `/admin/pedagogie/diagnostics` | direction | `DiagnosticsPage` | `lib/features/admin_pedagogie_diagnostics/diagnostics_page.dart` |
| `/admin/pedagogie/bibliotheque/nouveau` | direction | `ImportPage` | `lib/features/admin_pedagogie_bibliotheque/import/import_page.dart` |
| `/admin/pedagogie/bibliotheque/:supportId/publication` | direction | `PublicationPage` | `lib/features/admin_pedagogie_bibliotheque/publication/publication_page.dart` |
| `/admin/pedagogie/bibliotheque/:supportId/attribution` | direction | `AttributionSupportPage` | `lib/features/admin_pedagogie_bibliotheque/attribution/attribution_page.dart` |
| `/admin/finance/paie/obligation/:obligationId` | direction | `direction` | `?` |
| `/admin/configuration/regles` | direction | `ReglesPage` | `lib/features/admin_configuration_regles/regles_page.dart` |
| `/admin/configuration/fonctionnalites` | direction | `FonctionnalitesPage` | `lib/features/admin_configuration_fonctionnalites/fonctionnalites_page.dart` |
| `/admin/configuration/conservation-donnees` | direction | `ConservationDonneesPage` | `lib/features/admin_configuration_conservation_donnees/conservation_donnees_page.dart` |
| `/admin/configuration/politique-revue-kyc` | direction | `PolitiqueRevueKycPage` | `lib/features/admin_configuration_politique_kyc/politique_revue_kyc_page.dart` |
| `/admin/configuration/protection-enfants` | direction | `ProtectionEnfantsPage` | `lib/features/admin_configuration_protection_enfants/protection_enfants_page.dart` |
| `/admin/securite-audit/tirages` | direction | `TiragePage` | `lib/features/admin_tirage/tirage_page.dart` |
| `/comptable/tresorerie` | comptabilite | `TresoreriePage` | `lib/features/comptable/tresorerie/tresorerie_page.dart` |
| `/comptable/tresorerie/paiements-familles` | comptabilite | `PaiementsFamillesPage` | `lib/features/comptable/paiements_familles/paiements_familles_page.dart` |
| `/comptable/tresorerie/rapports` | comptabilite | `RapportsPage` | `lib/features/comptable/graphiques/rapports_page.dart` |

## 4. Ce qui existe et sert le bureau

- `AppGabarit` : trois gabarits, ordinateur à 1200, `ClasseLargeur` (compacte, moyenne, étendue,
  large, venue du lot R1). Seul endroit qui compare une largeur.
- `AppPage` : largeurs de contenu (1200), gestion (1440), lecture (800), réglages (760), formulaire
  (640), dialogue (560).
- `NavShell` (barre basse, rail, barre latérale), `AdminShell` (barre latérale et tiroir),
  `_CoquilleSecondaire` (`/compte`).
- `PageShell` : gouttière par gabarit, largeur bornée à 1200, `listeBureau` (largeur de gestion,
  adopté par 6 écrans), `teteAvecLaListe`.
- `EspaceTravailAdaptatif` : une, deux ou trois colonnes ; **branché sur 4 écrans seulement**
  (`com_messages/messages_page.dart`, `com_communaute/communaute_page.dart`,
  `com_studio/studio_page.dart`, `com_annonces/file_moderation.dart`).
- `DataCollection` : table au bureau, cartes au téléphone (direction 19, comptabilité 11).
- `ColonnesFiche` (fiche de l'élève) : deux colonnes à 1200, une pile en dessous. Une copie locale
  de ce que fait l'espace adaptatif, à rapprocher.
- **Brique déjà écrite, non livrée seule** (branche `claude/fil-ariane`, 068508462) : `FilAriane`
  (généralise `FilArianeFiche`), `NavigationDeCoquille`, le disque retour garanti au téléphone, et
  le robot `tool/e2e/fil_ariane.mjs` (lit l'arbre des routes, joue chaque route à 1440 et 390).

## 5. Codé et non branché, branches et maquettes

- `INVENTAIRE-NON-BRANCHE-2026-10-31.md` et `tool/branchement_tolere.txt` : **rien qui concerne le
  bureau** (moteurs de recherche, démonstrations, séance en arrière-plan).
- Branche archivée `archive/pc-2026-10-13/codex/r2-adaptive-shell` (Codex, 14/09/2026, aucune base
  commune avec main) : une coquille adaptative sur `NavigationBar`, `NavigationRail` et
  `NavigationDrawer` de Material. **À écarter** : `NavShell` porte déjà les trois formes, et
  `ClasseLargeur` (lot R1) est déjà dans `AppGabarit`.
- Maquettes du directeur dans le dépôt : connexion (deux volets à l'ordinateur) et salle (trois
  panneaux, 26/10). Aucune maquette de bureau pour les autres écrans : la définition s'appuie sur
  les standards publics et sur ces deux compositions.

## 6. Ce que l'inventaire propose de corriger, dans les composants partagés seulement (après arbitrage)

1. **Coquille sur toute route de rôle** : les 16 routes du §2 entrent dans la coquille de leur rôle
   (`_CoquilleSecondaire` existe déjà pour `/compte` ; l'étendre à `/tc/*`, aux pages poussées de
   l'enseignant et du contrôle). La salle et la porte MFA restent des exceptions écrites.
2. **Le chemin cliquable** : la brique `FilAriane`, telle quelle.
3. **`PageShell`, mise en page de bureau** : largeur de lecture pour les pages de texte, colonnes par
   `EspaceTravailAdaptatif` pour les pages « liste et détail » (B8), cartes et boutons bornés (B5)
   dans `AppCard` et `ActionPrincipale`, tête et pied compacts (B6, B7).
4. **La page de paiement** dans ce même cadre (sortie en haut et Échap, deux colonnes comme la
   connexion). Link hors lot (rang 22 o), `_shared/stripe.ts` non touché.
5. **Le garde-fou permanent** : un test Flutter qui rend chaque route (`cheminsDeclares`, déjà
   exposé par `app_router.dart` pour les tests) à 1440 avec le routeur réel et des services factices
   (`test/router/support_routeur.dart`), et vérifie B1 à B7 ; liste d'exceptions qui ne peut que
   rétrécir. Il tourne dans la suite Flutter déjà jouée en CI : **aucun changement de
   `.github/workflows/ci.yml`**.
