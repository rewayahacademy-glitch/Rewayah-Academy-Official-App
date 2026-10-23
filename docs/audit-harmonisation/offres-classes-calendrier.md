# Registre de conformité - Offres, demandes, Classes stables, simultanéité et calendrier

- SHA audité : 4a7aa2b (branche claude/nice-darwin-hael93, commit du 22/09/2026)
- Date de l'audit : 14/10/2026
- Auditeur : agent d'audit en lecture seule (Claude Sonnet 5.5), aucun fichier du dépôt modifié hors ce registre
- Domaine : OFR, offres, demandes, Classes stables, simultanéité (K-65) et calendrier
- Devoir de regard appliqué : lettre F (calendrier et orchestration) et lettre B (fiabilité fonctionnelle), avec des constats de la lettre A (sécurité) quand ils sont apparus

Conventions de lecture. Toutes les preuves sont des lectures du dépôt à HEAD 4a7aa2b, sauf mention "hors HEAD". Aucun test n'a été exécuté (Flutter, Dart et Postgres absents de l'environnement) : un test cité est "lu, non exécuté". Abréviations de sources :

- Maître : REWAYAH_DOCUMENT_MAITRE_ULTIME_AUDIT_CONFORMITE_2026-10-14.md, numéros de ligne du fichier fourni.
- Mission : prompt de mission d'harmonisation globale du 14/10/2026.
- D0910 : docs/current/DECISION-OFFRES-GROUPES-2026-10-09.md, lue sur la branche ccr-1b1bfa0b-m1kvkk, absente de HEAD.
- K65 : docs/current/DECISION-CLASSES-SIMULTANEES-2026-10-10.md, lue sur la branche ccr-1b1bfa0b-m1kvkk, absente de HEAD. R1 à R20 sont ses règles numérotées.
- ccr : branche ccr-1b1bfa0b-m1kvkk (base des PR Codex), non fusionnée dans HEAD.

## 1. Périmètre, sources lues, sources introuvables

### 1.1 Périmètre

Offres vitrines, intentions et demandes, constitution des Classes (groupes), simultanéité de Classes parallèles, occurrences de séances, fuseaux horaires, exceptions de calendrier, restes du matching individuel. Écrans de départ de la mission : parcours_offres, creneaux, disponibilites, inscription, fiche_groupe, journee, presence_correction, admin_groupes, admin_attribution, admin_demandes. Migrations relues : 0001 (état des séances), 0005, 0006, 0008, 0017, 0019, 0025, 0033, 0043, ainsi que 0012 et 0024 pour les consommateurs de statuts.

Le HEAD audité est un instantané du 22/09/2026. La branche ccr contient des dossiers que la Mission et le Maître citent comme écrans à réemployer (admin_regroupements, suivi_demandes, classe_tuteur, enseignant_classes, remplacements, admin_planning) et un dossier docs/current : ils n'existent pas à HEAD. Un statut ABSENT dans ce registre signifie "absent à HEAD 4a7aa2b", jamais "absent du produit".

### 1.2 Sources lues

À HEAD (par plages) :

- CLAUDE.md racine, lib/CLAUDE.md, supabase/CLAUDE.md (reçus en contexte).
- docs/PROGRESS.md lignes 1 à 80 (section DÉMARRER ICI, datée de mi-septembre, sans mention des offres) et grep ciblé.
- docs/HANDOFF.md : lignes 1 à 140, 2620 à 2700, grep ciblé (ADM-05, ENS-06, G-02, notifications). Jamais lu en entier.
- docs/architecture/decisions.md : ADR-009, ADR-028 à ADR-031 (lignes 1526 à 1790) et registre des questions ouvertes (lignes 1790 à 1847).
- docs/design/08-catalogue-ecrans.md : table des écrans (lignes 40 à 80), fiche ENS-06 (lignes 1538 à 1560), recherche des mentions parcours_offres, ADM-09. docs/design/README.md : grep seulement, non lu en détail.
- Code : lib/core/offres, lib/core/matching, lib/core/planning, lib/core/admin/service_groupes.dart, lib/core/router, lib/core/tc_groupe/port_groupes.dart, lib/features/{parcours_offres, creneaux, disponibilites, inscription, fiche_groupe, journee, presence_correction, admin_groupes, admin_attribution, admin_demandes, accueil_famille}.
- SQL : migrations citées ci-dessus, supabase/tests (liste et grep), .github/workflows/ci.yml (grep).
- Tests Dart : noms et assertions de test/parcours/parcours_offres_test.dart, test/features/{creneaux, fiche_groupe, journee, attribution_admin, demandes_admin, disponibilites}_test.dart (noms seulement pour les cinq derniers).
- FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md et FABLE_ONBOARDING_CLASSES_REPORT.md (grep et sections 4 à 7).

Hors HEAD (via get_file_contents, lecture seule) : docs/current/DECISION-OFFRES-GROUPES-2026-10-09.md, docs/current/DECISION-CLASSES-SIMULTANEES-2026-10-10.md, docs/current/00_LIRE_D_ABORD.md, docs/current/UX_REVIEW_OFFRES-ADM-1.md, docs/current/UX_REVIEW_REMPL-1.md, supabase/migrations/0045 (ccr), liste des migrations et des dossiers lib/features de ccr, PR #29 (migrations 0049, 0050, 0055), PR #21 (liste des fichiers et patchs de 0070, 0075, 0083, mots-clés), PR #13 (liste des fichiers).

Maître : lignes 69 à 104, 179 à 207, 779 à 1065. Mission : lignes 146 à 380.

### 1.3 Sources introuvables ou non lues

- Introuvables à HEAD : docs/current/ (toute la gouvernance 00_LIRE_D_ABORD, COHABITATION.md), DECISION-OFFRES-GROUPES, DECISION-CLASSES-SIMULTANEES. Lues sur ccr uniquement.
- Citées par le Maître et non retrouvées : REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md (le dépôt porte docs/design/00-bible-frontend-v2.md, non lu), REWAYAH_SPECIFICATIONS_FINALES_LOTS_RESTANTS_2026-10-12.md, RECH-01 et RECH-02, spécifications PED, matrice QA du 12/10. Leur contenu n'est ni deviné ni remplacé.
- Présents sur ccr, nom vu et contenu non lu : UX_REVIEW_OFFRES-FAM-1.md, UX_REVIEW_CLASSE-FORM-1.md, UX_REVIEW_DISPO-1.md, lib/features/admin_regroupements, suivi_demandes, classe_tuteur, enseignant_classes, remplacements.
- Non lus : PR #35, #34, #32, #31, #30, #28, #27, #26, #25, #24, #23, #22, #20, #17, #10, #8, #7 (hors domaine ou documentaires). PR #13 : liste des fichiers seulement.

## 2. Registre par exigence

Priorités : P0 sécurité ou parcours critique, P1 complétude, P2 finition, "-" si conforme.

| ID | Exigence et source | Rôle et parcours | Route, composant, contrat | Statut | Preuve (chemin:ligne, SHA 4a7aa2b) | Écart minimal | Priorité | Responsable | Tâche existante |
|---|---|---|---|---|---|---|---|---|---|
| AUD-OFR-001 | Une offre vitrine ne montre ni enseignant, ni photo, ni nombre d'inscrits, ni places restantes (Maître l.183 ; D0910 section 2) | Famille, choix d'horaire | Accueil famille puis /tuteur/parcours/:eleveId, ParcoursOffresPage, RPC offres_compatibles, table offres_horaires | CONFORME_PROUVÉ | `supabase/migrations/0043_offres_horaires_et_intentions.sql`:319-347 (table sans colonne enseignant ni compteur), :682-761 (RPC sans ces colonnes) ; `lib/core/offres/offre_horaire.dart`:318-345 ; chaîne `lib/features/accueil_famille/accueil_famille_page.dart`:236, `lib/features/parcours_offres/bloc_parcours.dart`:147-150, `lib/core/router/app_router.dart`:294-298 ; test lu non exécuté `test/parcours/parcours_offres_test.dart`:241-291 | Aucun sur la règle. Réserve de déploiement : 0043 non appliquée en production (message du commit 4a7aa2b), aucun scénario SQL | - | - | - |
| AUD-OFR-002 | Seule l'administration crée, publie et retire une offre ; aucune écriture famille dans la vitrine (Maître l.183 ; D0910 section 1) | Admin | RPC creer_offre_horaire, publier_offre_horaire, retirer_offre_horaire ; policy offres_horaires_admin | CONFORME_PROUVÉ | `0043`:356-376 (RLS activée, écriture réservée à l'admin, révocations anon et public), :1066-1067, :1116-1117, :1145-1146 (gardes positives avec coalesce), :1318-1331 (grants) | Aucun. Réserve : non exécuté, pas de scénario. La publication automatique par quota de la PR #29 (migration 0049) contredirait D0910 ; elle est remplacée par 0050 dans la même PR | - | - | - |
| AUD-OFR-003 | Écran d'administration des offres : créer en brouillon, publier, retirer avec motif, lire le vivier (D0910 section 1 et 3 ; Maître l.185) | Admin, Opérations | Aucune route ; RPC offres_admin, pool_offre, creer_offre_horaire, publier_offre_horaire, retirer_offre_horaire | PRÉSENT_MAIS_NON_RACCORDÉ | `0043`:998-1209 (RPC) ; aucun appel à ces six noms dans `lib/` (liste des RPC appelées relue) ; `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md`:232 ("Écran d'administration des offres : lot suivant, les RPC suffisent") | Sans offre publiée la vitrine reste vide pour toutes les familles (état vide honnête `parcours_offres_page.dart`:560-577). Le seul chemin à HEAD est le SQL manuel. Le contrat tient l'écran pour non bloquant, ce qui contredit D0910 | P0 | frontend, contrat partagé | FABLE_BACKEND_CONTRACT section 6 ; OFFRES-ADM-1 (ccr, hors HEAD) ; aucune dans PROGRESS.md ni HANDOFF.md |
| AUD-OFR-004 | Migration 0043 appliquée en production et numérotation continue (0039 à 0042 absentes de HEAD) | Opérateur | supabase/migrations | BLOQUÉ_DÉPENDANCE | Message du commit 4a7aa2b ("la migration 0043 n'est PAS appliquee en production") ; `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md`:228 ; liste de supabase/migrations : 0038 puis 0043 (0039 à 0042 présentes sur ccr, absentes de HEAD) | Tant que 0043 n'est pas appliquée, le bloc parcours reste invisible (dégradation voulue) et aucune intention ne peut naître. Vérifier la continuité avec l'historique distant avant tout db push | P0 | gouvernance (opérateur) | FABLE_BACKEND_CONTRACT section 6 |
| AUD-OFR-005 | Filtrage de compatibilité côté serveur : langue exacte, public de la cohorte, offre publiée, niveau (Maître l.184 et 188 ; K65 section 1) | Famille | RPC offres_compatibles ; ServiceOffresSupabase.offresCompatibles | CONFORME_PARTIEL | `0043`:682-761 ; `lib/core/offres/service_offres.dart`:158-172 | Manquent : le genre (élément de la clé de regroupement K65), un lien entre langue offerte et enseignant réellement disponible, comparaison niveau uuid contre texte libre `student_profiles.level` (:757) | P1 | backend | K65 section 1 ; CLASSE-FORM-1 (ccr) |
| AUD-OFR-006 | Le client ne reçoit jamais le catalogue entier (ADR-031, contrat 0043) | Tout rôle connecté | Policy offres_horaires_vitrine, grant select | CONTRADICTOIRE | `0043`:361-366 (select pour tout authenticated si état publiée), :373 (grant select sur toutes les colonnes, dont created_by et publiee_par) ; docstring `service_offres.dart`:34-38 | Tout compte connecté peut lire les offres publiées de tous les publics et les identifiants des administrateurs qui les ont créées. Faible sensibilité, mais la garantie écrite est fausse | P2 | backend | PR #29 migration 0049 restreint les colonnes accordées (hors HEAD) |
| AUD-OFR-007 | Demande hors offre (créneau personnalisé) avec jours et heure explicites ; aucune demande sans jour ni heure (Maître l.184 ; D0910 section 2) | Famille | Aucune RPC ni écran à HEAD | ABSENT | Liste des RPC de `lib/core` : aucune demande personnalisée ; ADR-030 (`docs/architecture/decisions.md`:1666-1715) l'interdit ; PR #29 migration 0050 (demander_creneau_personnalise, heures parallèles aux jours, garde positive) et `lib/core/offres/port_demandes_horaires.dart` (hors HEAD) | Livrer le formulaire de demande complète après amendement d'ADR-030 | P1 | frontend, backend | PR #29, PR #21 (0049, 0050) |
| AUD-OFR-008 | Aucune demande ne part sans jour ni heure : le repli "Me prévenir si de nouveaux horaires ouvrent" n'en porte aucun | Famille | RPC signaler_horaire_insatisfait ; bouton du repli | CONTRADICTOIRE | `0043`:880-918 ; `lib/core/offres/service_offres.dart`:191-212 (détail sans horaire, voulu) ; `lib/features/parcours_offres/parcours_offres_page.dart`:183-209, :645-695 ; D0910 section 2 | La décision du 09/10 est postérieure à ADR-030 (22/09) et prévaut : remplacer le signal par la demande complète (AUD-OFR-007) | P1 | frontend, backend | PR #29 |
| AUD-OFR-009 | Le signal horaire_insatisfait se traite dans ADM-06 (ADR-030) | Admin | decider_demande ; DemandesPage | PRÉSENT_MAIS_NON_RACCORDÉ | `0043`:920-924 (kind élargi) ; `0005_dashboards_affectation_regles.sql`:1243-1301 (toute demande acceptée hors réaffectation passe par poser_regle avec rule_value converti en entier, :1289 ; la valeur du signal est un objet jsonb) ; `lib/core/domain/enums.dart`:278-303 (SorteDemande sans cette sorte) ; `lib/features/admin_demandes/demandes_page.dart`:705-721 (repli sur un libellé de règle) | Accepter le signal lèverait une erreur de conversion (déduit de la lecture, non exécuté) ; refuser l'enregistre comme refus. Aucun état "vu" | P1 | backend, frontend | ADM-06 (catalogue 08) |
| AUD-OFR-010 | Un second appui sur le repli est sans effet visible faux | Famille | matching_requests_pending_uidx | CONFORME_PARTIEL | `0005`:924-925 (une demande en attente par élève et sorte) ; `0043`:880-918 (unique_violation non attrapée) ; `parcours_offres_page.dart`:183-209 (message générique `parcours.erreur`), :68 (drapeau local non relu au retour) | La protection anti-doublon est réelle ; le message d'échec du doublon est trompeur. `p_detail` jsonb n'est ni borné ni validé | P2 | frontend, backend | Aucune tâche existante trouvée |
| AUD-OFR-011 | Un choix d'offre enregistre une intention, jamais une place réservée ; les libellés le disent (Maître l.184 et 196 ; ADR-031) | Famille | RPC choisir_offre_horaire ; table intentions_horaire ; clés parcours.* | CONFORME_PROUVÉ | `0043`:382-441 (aucune policy d'insertion famille), :769-821 ; `assets/i18n/fr.i18n.json` clés parcours.offresRaison, parcours.momentsRaison, parcours.refusEffet ; tests lus non exécutés `test/parcours/parcours_offres_test.dart`:342-380, :405-421 | Aucun. Réserve : dépend de l'application de 0043 | - | - | - |
| AUD-OFR-012 | Le serveur rejoue la compatibilité au choix : un client ne peut pas poster une offre incompatible, retirée ou brouillon | Famille | RPC choisir_offre_horaire | CONFORME_PROUVÉ | `0043`:780-791 (appel à offres_compatibles puis refus si absente) ; :1290 (la RPC de publication de groupe revérifie l'intention vivante) | Aucun. Non exécuté | - | - | - |
| AUD-OFR-013 | Une seule intention vivante par élève ; double appui et deux demandes simultanées (Maître l.204) | Famille | Index intentions_une_vivante_par_eleve | CONFORME_PROUVÉ | `0043`:413-414, :800-806 (violation convertie en message) ; client `parcours_offres_page.dart`:152-181 et :526-530 (bouton inerte pendant l'envoi) | Aucun sur l'unicité (portée par un index, donc atomique). Pas de scénario SQL de concurrence | - | - | - |
| AUD-OFR-014 | Changer d'avis, ou changer d'horaire après le retrait d'une offre : renoncer puis choisir | Famille | RPC renoncer_intention_horaire ; ServiceOffres.renoncer ; carte "Changer d'horaire" | PRÉSENT_MAIS_NON_RACCORDÉ | `0043`:830-860 ; `service_offres.dart`:76, :186-191 ; aucun appelant dans `lib/features` ni `lib/core` ; la clé i18n parcours.renoncerMotif n'est employée par aucun code ; `_choisir` (`parcours_offres_page.dart`:152-181) n'appelle pas renoncer ; index unique `0043`:413-414 | Après le retrait d'une offre, l'intention reste vivante : choisir une autre offre échoue sur l'index et l'écran affiche l'erreur générique. Les états sans bouton (diagnostic requis, en formation) n'offrent aucun changement. Parcours impossible à terminer | P0 | frontend (renoncer puis choisir, ou RPC atomique) | Aucune tâche existante trouvée ; `lib/core/router/routes.dart`:82-89 annonce pourtant la reprise "longtemps après l'inscription" |
| AUD-OFR-015 | L'état "offre retirée" ne doit pas effacer ce qui est acquis (Maître l.196) | Famille | v_parcours_onboarding.offre_indisponible ; etapeParcours | CONTRADICTOIRE | `0043`:966-969 (calculé sans regarder l'état de l'intention) ; `offre_horaire.dart`:580-598 (offreIndisponible testé avant affectee) ; ADR-031 ("cet état prime sur tous les autres") ; texte `fr.i18n.json` parcours.etatOffreIndisponibleDetail | Retirer une offre dont le groupe tourne affiche à ses familles "retiré avant qu'un groupe soit constitué". Décision tranchée, risque nouveau (situation 2) | P1 | frontend, backend | Aucune tâche existante trouvée |
| AUD-OFR-016 | États de la demande : Offre publiée, Intention reçue, En constitution, Classe créée ou enseignant recherché, Enseignant confirmé, Classe confirmée, Séances visibles ; À préciser, Offre retirée, Demande annulée, Incompatible, Liste d'attente, Erreur temporaire (Maître l.196) | Famille | etapeParcours (7 états), BlocParcours | CONFORME_PARTIEL | `offre_horaire.dart`:556-598 ; `lib/features/parcours_offres/libelles_parcours.dart`:243-282 ; `bloc_parcours.dart`:87-100 (une action par carte) | Présents : à personnaliser, horaire à choisir, offre indisponible, diagnostic requis, rendez-vous prévu, en formation, groupe confirmé. Absents : enseignant recherché, enseignant confirmé, séances visibles, liste d'attente, demande annulée, incompatible, à préciser | P1 | frontend, backend | OFFRES-FAM-1 (ccr, contenu non lu) ; PR #21 migration 0076 |
| AUD-OFR-017 | Suivi daté jusqu'à la première séance, sans rang ni autres familles (Maître l.186 ; K65 R20) | Famille | suivi_demandes ; RPC mes_demandes_horaires | ABSENT | Aucun dossier suivi_demandes ni RPC à HEAD ; PR #29 migration 0050 (mes_demandes_horaires), PR #21 migration 0076 ; ccr lib/features/suivi_demandes (hors HEAD) | Ni date de première séance, ni barre d'étapes | P1 | frontend, backend | PR #21 ; OFFRES-FAM-1 (ccr) |
| AUD-OFR-018 | Les notifications suivent des événements réels (Maître l.186 ; D0910 section 4) | Famille | Textes "Nous vous préviendrons" ; device_tokens | PRÉSENT_MAIS_NON_RACCORDÉ | `assets/i18n/fr.i18n.json`:1023 (parcours.refusEnregistre), :1036 (parcours.etatGroupeEnFormationDetail) ; aucune table notifications dans supabase/migrations ; `0001_fondations.sql`:348 (device_tokens sans producteur ni consommateur) ; `docs/HANDOFF.md`:2637-2639 (canal push non livré) | Deux écrans promettent un avertissement sans canal. PR #21 (0063, 0066, 0078) le crée hors HEAD | P1 | backend, frontend (textes) | HANDOFF.md section 10.3 ; PR #21 |
| AUD-OFR-019 | L'étape "diagnostic" a un producteur (rendez-vous, fait) | Famille, Admin | student_profiles.diagnostic_statut ; intentions_horaire.etat | PRÉSENT_MAIS_NON_RACCORDÉ | `0043`:242, :275 (valeurs planifie et fait), :808-812 (seule écriture : non_requis vers a_planifier) ; aucune autre écriture dans supabase/migrations ; `offre_horaire.dart`:580-601 (fait et non_requis rendent "diagnostic requis") ; `fr.i18n.json` parcours.etatDiagnosticRequisDetail ("L'académie vous proposera un rendez-vous") | Promesse de rendez-vous sans mécanisme ; un diagnostic fait s'afficherait "à faire" ; aucun lien avec les diagnostics de 0021. Place du diagnostic dans la chaîne d'entrée à valider (contenu académique) | P1 | backend, contenu académique | Aucune tâche existante trouvée |
| AUD-OFR-020 | Le niveau officiel, le statut de diagnostic et le type d'élève ne sont pas écrits par le client | Famille | GRANT UPDATE par colonnes sur student_profiles | CONFORME_PROUVÉ | `0005`:562-565 (revoke update puis grant sur trois colonnes), `0043`:289-290 (grant nominatif sans level, diagnostic_statut, student_type) ; `0043`:280-287 | Aucun sur ces trois colonnes. Voir AUD-OFR-021 pour les colonnes accordées | - | - | - |
| AUD-OFR-021 | Le serveur décide du type d'élève et du mode d'interface depuis la tranche d'âge ; le client ne peut pas se déclarer adulte (commentaire `0043`:90-92) | Famille, Élève | RPC enregistrer_profil_apprentissage ; GRANT UPDATE | CONTRADICTOIRE | `0043`:585-655 (dérivation dans la RPC) mais :289-290 accorde UPDATE direct sur cohorte, langue_cours, niveau_declare, objectif ; `0005`:535-560 (policy student_profiles_family_update sans test du rôle guardian) ; `0038_hook_jeton_foyer_absent.sql` (tuteur et élève portent household_id) ; aucun trigger de cohérence cohorte et student_type | Un appel direct peut changer cohorte sans passer par la RPC, et offres_compatibles lit cohorte. Protection des mineurs. Non démontré en exécution | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-022 | Cohortes d'âge 6-9, 10-13, 14-17, 18+ (Maître l.188) | Famille | cohortes_age | À_ARBITRER | `0043`:95-118 (5-7, 8-10, 11-14, 15-17, 18 et plus) ; `docs/architecture/decisions.md` registre question 5 (seuil 8) ; commentaire `0043`:108-110 ("valait 10") | Trois coupures différentes ; la table se corrige par update sans migration | P1 | gouvernance | Aucune tâche existante trouvée |
| AUD-OFR-023 | Langues offertes selon publication réelle (Maître l.188 ; ADR-029) | Famille, Admin | langues_cours | CONFORME_PARTIEL | `0043`:67-90 (actif, ordre ; trois langues actives par défaut) ; `test/parcours/parcours_offres_test.dart`:523-545 (langue du cours distincte de la locale) | Aucun lien entre langue active et disponibilité d'un enseignant qui la parle | P2 | gouvernance, backend | ADR-029 |
| AUD-OFR-024 | Le fuseau par défaut du foyer ne vaut pas déclaration de la famille | Famille | households.timezone ; _pageLieu ; fuseauSuggere | CONTRADICTOIRE | `0001_fondations.sql`:65 (timezone not null default 'Europe/Paris') ; `parcours_offres_page.dart`:82-88, :324-350 ; `libelles_parcours.dart`:166-176 (le fuseau connu du foyer gagne sur l'horloge) ; test lu `parcours_offres_test.dart`:163-171 (cas Conakry seulement, aucun cas du défaut) | Une famille d'Amérique du Nord qui appuie sur Continuer garde Paris, avec la légende "Proposé d'après l'heure de votre appareil" (:346-350) fausse. Les heures s'affichent en heure de Paris | P1 | frontend, backend | Aucune tâche existante trouvée |
| AUD-OFR-025 | Le fuseau s'affiche en clair, pas par identifiant IANA | Famille | ScheduleOption.timeZone | CONFORME_PARTIEL | `parcours_offres_page.dart`:620-624 ; `fr.i18n.json` parcours.offreFuseau ("Heure affichée pour {fuseau}") | La valeur rendue est l'identifiant (Europe/Paris) ; le libellé de lieu existe déjà dans fuseauxProposes (`libelles_parcours.dart`:115-163) | P2 | frontend | OFFRES-ADM-1 (ccr) pose le principe côté admin |
| AUD-OFR-026 | Conversion de l'horaire d'une offre vers le fuseau de la famille, changement d'heure inclus (Maître l.204) | Famille | RPC offres_compatibles ; instant_creneau | IMPLÉMENTÉ_NON_PROUVÉ | `0043`:688-757 (conversion par instant_creneau puis at time zone, jours et heures en tableaux parallèles) ; `0005`:510-521 et `0006`:23-33 ; le client ne convertit rien (`offre_horaire.dart`:318-345) | Aucun scénario de bascule Europe ou États-Unis ; non exécuté | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-027 | Détection d'un décalage d'heure après le choix, fuseau ou heure d'été | Famille | v_parcours_onboarding.fuseau_change | CONFORME_PARTIEL | `0043`:388-392 (heure_affichee conservée pour pouvoir dire "vous aviez vu 18:00"), :966-970 (seul fuseau_change est calculé) ; `bloc_parcours.dart`:122-146 | Le décalage dû à l'heure d'été n'est ni calculé ni affiché | P2 | backend, frontend | Aucune tâche existante trouvée |
| AUD-OFR-028 | Capacités, durées, pause, minimum et séances par semaine lues dans la configuration, jamais en dur (Maître l.187, 917) | Famille, Admin | RPC regles_academie ; ReglesAcademie | CONFORME_PARTIEL | `0043`:531-565 ; `offre_horaire.dart`:236-246 (défauts 5, 6, 3, 3, 60, 90, 6, 0 recopiés dans le client) ; `parcours_offres_page.dart`:602 (zéro séance affichée si les règles manquent) | Remplacer les défauts du client par un état "règles indisponibles" | P2 | frontend | Aucune tâche existante trouvée |
| AUD-OFR-029 | Pause de séance de 5 minutes (Maître l.187) | Famille | app_config seance.pause_minutes_enfant | À_ARBITRER | `0043`:538 (valeur 6), `offre_horaire.dart`:245, ADR-031 (pause 6 et 0) ; aucune implémentation de la pause en séance (sessions ne porte que prayer_pause_minutes) | Valeur de référence à confirmer par la direction ; la pause n'est qu'annoncée à la famille | P2 | gouvernance | Aucune tâche existante trouvée |
| AUD-OFR-030 | Regroupement automatique des demandes semblables et bouton "Créer la classe" avec intégration atomique et idempotente (Maître l.185 et 192 ; D0910 section 3 ; K65 R3 et R8) | Admin | Aucun écran ; RPC regroupements_demandes_horaires_admin, creer_classe_depuis_regroupement (PR #29) | ABSENT | Aucun dossier admin_regroupements à HEAD ; `0043`:1171-1316 (pool_offre et publication sur liste d'élèves fournie par l'appelant) ; `docs/architecture/decisions.md`:1776-1783 (dispatch "déclenché à la main") ; PR #29 migrations 0050 et 0055 (clé d'idempotence, verrous consultatifs, FOR UPDATE), PR #21 0070, 0077, 0079 (hors HEAD) | Aucune voie utilisable par l'administration à HEAD pour passer des intentions à une Classe | P0 | frontend, backend | OFFRES-ADM-1 (ccr) ; F1 (PR #29, PR #13) ; F2 (PR #21) |
| AUD-OFR-031 | Publication manuelle d'un groupe depuis une offre : minimum, capacité, intention vivante, créneaux de tous les jours | Admin | RPC publier_groupe_depuis_offre | CONFORME_PARTIEL | `0043`:1214-1316 (minimum :1246, capacité :1249, intention vivante :1288-1293, créneaux :1280-1285, ajout par ajouter_eleve_groupe :1295) | Manquent : idempotence par clé, verrou par offre ou par clé de regroupement, contrôle du public de l'élève contre l'offre, disponibilité de l'enseignant, genre. Un élève dont le compte n'est pas actif annule toute la publication (`0019`:134-175) | P1 | backend | K65 R2, R3, R8 ; PR #29 migration 0055 |
| AUD-OFR-032 | Classe créée sans enseignant (enseignant recherché), puis enseignant confirmé (Maître l.196 ; K65 R7) | Admin | groupes.teacher_id | ABSENT | `0017`:23 (teacher_id not null) ; `0043`:7-14 (choix assumé de ne pas relâcher la colonne) ; `0019`:48-57 (creer_groupe exige un enseignant valide) ; PR #29 migration 0055 (teacher_id nullable, état en_attente_enseignant, affecter_enseignant_classe), PR #21 migration 0071 | Pas d'état intermédiaire : la Classe n'existe qu'avec son enseignant | P1 | backend | C-12 (PR #29) |
| AUD-OFR-033 | Proposition d'enseignant : genre, créneaux libres sans chevauchement réel, charge, à confirmer par l'administration (D0910 section 3 ; K65 R12) | Admin | RPC enseignants_pour_classe | ABSENT | À HEAD seule enseignants_pour(uuid) du 1-à-1 (`0008_attribution_manuelle.sql`:134-200) ; PR #21 migrations 0082 et 0083 (hors HEAD) | Aucune proposition pour une Classe | P1 | backend, frontend | CLASSE-FORM-1 (ccr) ; C-07 (PR #21 migration 0083) |
| AUD-OFR-034 | Un enseignant n'est pas affecté à une Classe hors de ses disponibilités sans motif tracé (ADR-021) | Admin | creer_groupe ; publier_groupe_depuis_offre | ABSENT | `0019`:40-93 et `0033_tc_vues_rpc.sql`:564-640 : aucune lecture de weekly_availability ; `docs/architecture/decisions.md`:911 (ADR-021 exige un motif pour le 1-à-1) ; seule garde : sessions_no_teacher_overlap | Traitement différent entre le 1-à-1 et le groupe | P1 | backend | ADR-021 ; PR #21 migrations 0082, 0083 |
| AUD-OFR-035 | Création manuelle d'une Classe, écran ADM-09 | Admin | /admin/operations/groupes, GroupesPage, ServiceGroupesSupabase.creer | CONFORME_PARTIEL | Route `app_router.dart`:404-409 ; états chargement, contenu, vide, erreur `lib/features/admin_groupes/groupes_page.dart`:49-91 ; l'enseignant se saisit comme identifiant brut (:449), jour et heure en texte libre avec repli silencieux sur lundi et 0 h (:419-420), fuseau figé (:421) ; aucun test dédié (aucun fichier test/features/groupes*) | Remplacer la saisie brute par une sélection guidée ; ajouter genre, langue ; fiche ADM-09 absente du catalogue (ligne :79 seulement) | P1 | frontend | CLASSE-FORM-1 (ccr) ; aucune tâche à HEAD |
| AUD-OFR-036 | Appels creer_groupe et modifier_groupe sans ambiguïté de surcharge | Admin | rpc creer_groupe (6 paramètres nommés), modifier_groupe (5) | IMPLÉMENTÉ_NON_PROUVÉ | `lib/core/admin/service_groupes.dart`:255-264, :273-281 ; `0019`:40-47 et `0033`:564-574 (deux signatures acceptant les mêmes noms, la seconde avec valeurs par défaut) ; `0043`:1255-1263 (commentaire : appel à six arguments ambigu, corrigé pour l'appel interne seulement) ; ccr migration 0045 "disambiguate creer_groupe overloads" absente de HEAD | Risque de régression : l'appel du client peut être refusé pour ambiguïté dès que 0033 est appliquée. Non exécuté | P0 | backend | 0045 (ccr, hors HEAD) |
| AUD-OFR-037 | Le fuseau de la Classe s'affiche tel que stocké | Admin | groupes_admin ; GroupeAdmin.depuisJson | CONTRADICTOIRE | `service_groupes.dart`:67-71 (Europe/Paris recodé en dur) ; `0019`:241-276 (groupes_admin ne rend pas timezone_iana) ; `0043`:1264-1272 (une Classe publiée depuis une offre reçoit le fuseau de l'offre) ; `lib/core/tc_groupe/demonstration_groupes.dart`:25-27 (le code confirme le manque) | Une Classe de Toronto s'affiche à l'heure de Paris dans l'écran d'administration | P1 | backend, frontend | docs/teaching-core/TC_CONTRACT_REQUEST_A.md section 2 |
| AUD-OFR-038 | Trois séances par semaine annoncées par l'offre = trois occurrences hebdomadaires (Maître l.187) | Famille, Enseignant | materialiser_seances_groupe | CONTRADICTOIRE | `0033`:315-372 (boucle sur l'ancre weekday et hour_local seule, :343) ; groupe_creneaux n'est lu par aucun objet de HEAD (grep sur supabase et lib) ; `0043`:1280-1285 les crée sans conséquence | Une Classe publiée depuis une offre n'a qu'une séance par semaine. PR #29 migration 0055 réécrit la fonction en itérant groupe_creneaux | P1 | backend | F1 (PR #29 migration 0055) |
| AUD-OFR-039 | Durée effective de la Classe (60 ou 90 minutes) portée par la Classe (Maître l.187) | Famille, Enseignant | sessions.ended_at | CONTRADICTOIRE | `0033`:338 (session_duration_minutes global, 60) ; offres_horaires.duree_minutes (`0043`:326) non recopiée sur groupes (:1264-1278) ; la vitrine annonce 90 minutes aux adultes (:713-724) | Séance adulte matérialisée à 60 minutes. La PR #29 migration 0055 garde la durée globale | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-040 | Aucune occurrence créée dans le passé à la création de la Classe | Enseignant, Famille | instant_creneau décalage 0 | IMPLÉMENTÉ_NON_PROUVÉ | `0033`:341-359 (aucune garde sur v_debut) contre la version 1-à-1 `0005`:979-981 qui saute le passé ; `0005`:510-521 (semaine courante ancrée en UTC) ; PR #21 migration 0075 vise la prochaine occurrence | Une Classe créée le jeudi pour un lundi crée une séance planned passée avec participants ; aucun balayage ne la clôt (AUD-OFR-045) | P1 | backend | PR #21 migration 0075 |
| AUD-OFR-041 | Prolongation du calendrier au-delà de l'horizon de quatre semaines | Enseignant, Famille | matching_horizon_weeks | ABSENT | `0033`:296-306 (limite connue, aucun ordonnanceur) ; aucun pg_cron ni tâche planifiée dans supabase/migrations, supabase/functions, .github | Une Classe stable cesse d'avoir des séances après quatre semaines sans nouvelle adhésion. `phaseEnfant` (`accueil_famille_page.dart`:73-93) affiche alors "en recherche d'enseignant" à un enfant en Classe, car affecte vient des affectations 1-à-1 | P1 | backend | Limite documentée ; aucune tâche existante trouvée |
| AUD-OFR-042 | Changement d'horaire ou de fuseau d'une Classe sans occurrences orphelines | Admin | modifier_groupe ; trigger tc_materialiser_apres_creation_groupe | IMPLÉMENTÉ_NON_PROUVÉ | `0019`:95-131 ; `0033`:397-400 (re-matérialisation sur update) ; materialiser_seances_groupe n'annule ni ne supprime les occurrences de l'ancien créneau (:315-372) | Les séances futures de l'ancien créneau restent planifiées avec leurs participants | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-043 | Exceptions de calendrier (annulation, report, congé, remplacement) explicites, tracées, sans changer le contrat de Classe (Maître l.915) | Admin, Enseignant | Aucune RPC | ABSENT | Seul le statut canceled est écrit, par decider_demande pour une réaffectation 1-à-1 (`0005`:1272-1285) ; aucune RPC d'annulation, de report, de congé ni de remplacement (grep supabase et lib) ; PR #21 : aucune migration correspondante dans les patchs lus (patchs GitHub possiblement tronqués) ; ccr REMPL-1 (écran, port) | Modéliser chaque exception comme objet distinct (motif, auteur, horodatage) ; règles d'annulation tardive à fixer par la direction | P1 | backend, contrat partagé, gouvernance | REMPL-1, DISPO-1 (ccr) |
| AUD-OFR-044 | Remplaçant libre à l'instant exact ; genre souple choisi par l'admin et tracé ; sinon séance annulée (K65 R12) | Admin, Enseignant | Aucune RPC | ABSENT | Voir AUD-OFR-043 ; `docs/current/UX_REVIEW_REMPL-1.md` (ccr) décrit le besoin serveur (acceptation atomique premier arrivé) | Aucun producteur serveur | P1 | backend | REMPL-1 (ccr) |
| AUD-OFR-045 | Cycle de vie des états de séance : preflight, in_progress, ended, teacher_absent, student_absent, tech_failure, canceled_late | Enseignant, Admin | Machine à états sessions | ABSENT | `0001_fondations.sql`:880-898 (garde de transition) ; aucun update public.sessions hors decider_demande dans supabase/migrations, supabase/functions et lib ; consommateurs : `0025_role_enseignant.sql`:376-420 (rapports en attente), `0024_qualite_pedagogique.sql`:123-137 (rapport manquant), `0005`:1345-1349 (incidents 24 h) | Sans producteur dans le dépôt, ces consommateurs restent vides ; non démontré hors dépôt (opération manuelle). Recherche complète menée | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-046 | Absence réelle et incident technique ne se confondent pas (Maître l.932-933) | Admin | indicateurs_admin.incidents_24h | CONFORME_PARTIEL | Enum distinct `0001`:42-45 ; transitions `0001`:894-896 ; compteur `0005`:1345-1349 additionne tech_failure, teacher_absent et student_absent | Le compteur fusionne les trois ; sans producteur (AUD-OFR-045) la distinction n'a pas de donnée | P2 | backend | Aucune tâche existante trouvée |
| AUD-OFR-047 | Liste d'attente ordonnée, sans rang visible (Maître l.196 et 918 ; K65 R11) | Famille, Admin | Aucune table, aucun écran | ABSENT | Aucune occurrence de liste d'attente dans supabase/migrations hors le commentaire `0043`:871 ; le signal horaire_insatisfait n'est ni ordonné par clé ni rattaché à une Classe pleine | Aucune file | P1 | backend, frontend | Aucune tâche existante trouvée (PR #21 : rien dans les patchs lus) |
| AUD-OFR-048 | Fusion et transfert de Classe atomiques, tracés, notifiés (K65 R9 et R10) | Admin | Aucune RPC | ABSENT | Seules ajouter_eleve_groupe et retirer_eleve_groupe existent (`0019`:134-207) : retirer puis ajouter n'est pas atomique et n'agit ni sur les occurrences ni sur la notification | Aucun | P1 | backend | Aucune tâche existante trouvée |
| AUD-OFR-049 | Fratries séparées autant que possible ; regroupement forcé tracé (K65 R4) | Admin | Règle de composition | ABSENT | Aucun traitement du foyer dans pool_offre ni publier_groupe_depuis_offre (`0043`:1171-1316) | Aucune règle | P2 | backend | Aucune tâche existante trouvée |
| AUD-OFR-050 | Le genre fait partie de la clé de regroupement et de la proposition d'enseignant (K65 section 1 et R12) | Admin | groupes, offres | ABSENT | Aucune occurrence de genre_public dans supabase et lib à HEAD ; présent dans PR #21 migration 0083 | Ni les offres ni les Classes ne portent le genre | P1 | backend | PR #21 ; CLASSE-FORM-1 (ccr) |
| AUD-OFR-051 | Cloisonnement par Classe, jamais par horaire ; test négatif entre deux Classes au même horaire (Maître l.192 ; K65 R13) | Famille, Élève, Enseignant | Policies groupes_lecture et groupe_membres_lecture | CONFORME_PARTIEL | `0019`:308-336 (lecture par appartenance, foyer ou enseignant du groupe) ; `0001`:1000-1010 (séances par participation) | Le test négatif exigé par K65 est absent : aucun scénario SQL ne touche groupes (grep supabase/tests) | P1 | backend | K65 section 3 |
| AUD-OFR-052 | Plafond de participants d'une séance de Classe appliqué côté serveur | Enseignant, Famille | guard_session_participant_cap | CONTRADICTOIRE | `0033`:1470-1500 (plafond ignoré quand allow_multi_participant_sessions vaut true) ; `0017`:430-436 (clé posée à true, maximum 7) ; `docs/architecture/decisions.md`:1565-1578 (ADR-028 renvoie au lot G-02) ; scénario `supabase/tests/scenarios_ctr01.sql`:187-209 (C2) ne couvre que le cas multi fermé | Une septième ligne session_participants n'est refusée par aucun garde | P1 | backend | Lot G-02 (ADR-028) |
| AUD-OFR-053 | Plafond de membres d'une Classe tranché en base, atomique sous concurrence (Maître l.192 et 918) | Admin | guard_groupe_membre_cap | CONFORME_PARTIEL | `0017`:99-134 (compte puis insère, sans verrou de la ligne groupes ni verrou consultatif) ; contrainte seuil_max entre 1 et 6 (:28) | Deux ajouts concurrents au même groupe peuvent dépasser le seuil (déduit de la lecture, non exécuté) ; aucun scénario SQL de groupe | P1 | backend | K65 R8 ; PR #29 migration 0055 (FOR UPDATE dans la matérialisation seulement) |
| AUD-OFR-054 | Un élève n'a qu'une appartenance de Classe active | Admin | Index groupe_membres_actif_uidx | CONFORME_PROUVÉ | `0017`:79-80 ; vérification explicite `0019`:134-175 | Aucun. Pas de scénario SQL de groupe | - | - | - |
| AUD-OFR-055 | Aucune unicité d'horaire sur les Classes : l'identité d'une Classe est son id (Maître l.192 ; K65 R1) | Admin | Table groupes | CONFORME_PROUVÉ | `0017`:22-47 (clé primaire seule, index non unique) ; `0043`:448-466 (unicité de groupe_creneaux limitée à un groupe) ; aucun index unique sur public.groupes dans supabase/migrations (grep) | Aucun. Pas de scénario "30 Classes au même horaire" | - | - | - |
| AUD-OFR-056 | Un enseignant n'a jamais deux séances actives qui se chevauchent, sans refuser une Classe parce qu'une autre existe au même horaire (K65 R6) | Admin, Enseignant | Contrainte sessions_no_teacher_overlap | CONFORME_PROUVÉ | `0005`:638-646 (EXCLUDE par enseignant sur les séances planned, preflight, in_progress non supprimées) ; scénario lu non exécuté `supabase/tests/scenarios_etape4.sql`:582-611 (S7a) | Aucun sur la règle | - | - | - |
| AUD-OFR-057 | Un élève n'est jamais inscrit à deux séances qui se chevauchent (K65 R5) | Admin | guard_session_overlap | CONFORME_PARTIEL | `0033`:1501-1530 ; scénario lu non exécuté `supabase/tests/scenarios_ctr01.sql`:233-257 (C3) | Contrôle par lecture puis insertion sans verrou ; pas de contrôle au transfert (inexistant) | P2 | backend | Aucune tâche existante trouvée |
| AUD-OFR-058 | Les erreurs serveur sont dites en clair à l'administration | Admin | _message dans GroupesPage | CONFORME_PARTIEL | `lib/features/admin_groupes/groupes_page.dart`:259-267, :427-431 | Une violation d'exclusion ou une ambiguïté de surcharge remonte telle quelle dans la feuille de création | P2 | frontend | Aucune tâche existante trouvée |
| AUD-OFR-059 | Aucun matching individuel enseignant-élève dans le parcours courant ; l'enseignant prend des Classes proposées (Maître l.185 et 914 ; 00_LIRE_D_ABORD ccr) | Enseignant | /enseignant/creneaux, onglet Élèves, prendre_eleve | CONTRADICTOIRE | `lib/features/creneaux/creneaux_page.dart`:59-68, :392-420, :561 ; `lib/core/matching/service_matching.dart`:194-216 ; `lib/core/router/app_router.dart`:317-322 (onglet de la barre enseignant) ; `docs/design/08-catalogue-ecrans.md`:1556 (action principale "Prendre un eleve") ; `docs/PROGRESS.md`:76-78 (consigne de ne rien réécrire des services de matching) ; 24 tests lus `test/features/creneaux_test.dart` attestent le comportement 1-à-1 | Aucune Classe à prendre ; la source active du dépôt (catalogue, PROGRESS) contredit le Maître | P1 | frontend, gouvernance | Lot G-02 (ADR-028, retrait de teacher_student_assignments) |
| AUD-OFR-060 | Attribution individuelle par l'administration | Admin | /admin/operations/attributions, attribuer_eleve | CONTRADICTOIRE | `lib/core/matching/service_attribution.dart`:230-262 ; `0008`:219-304 (affectation 1-à-1 et séances sans groupe) ; `app_router.dart`:411-415 ; `08-catalogue-ecrans.md`:76 ; ADR-021 | Écran fonctionnel mais sans lien avec les Classes ; même arbitrage que AUD-OFR-059 | P1 | gouvernance, backend | Lot G-02 ; ADR-021 |
| AUD-OFR-061 | La famille choisit parmi les horaires proposés et ne pose pas librement ses horaires (Maître l.913 ; D0910 section 2) | Famille | Onglet Disponibilités, DisponibilitesPage, weekly_availability ; ChildCard "Poser un horaire" | CONTRADICTOIRE | `lib/core/widgets/nav_shell.dart`:85-89 ; `app_router.dart`:252-254 ; `accueil_famille_page.dart`:353 ; `lib/core/planning/service_planning.dart`:271-290 (insertion directe) ; RLS `0005`:463-469 | Deux entrées pour la même intention (voir les horaires vitrines, poser un horaire) et deux sources (intentions_horaire, weekly_availability) | P1 | frontend, gouvernance | DISPO-1 (ccr, contenu non lu) |
| AUD-OFR-062 | Un élève membre d'une Classe n'est plus compté ni proposé comme sans enseignant | Admin, Enseignant, Famille | eleves_en_attente_v, eleves_sans_enseignant, indicateurs_admin, phaseEnfant | CONTRADICTOIRE | `0005`:1401-1431 et :1330-1340 ; `0008`:55-120 ; aucun de ces objets ne lit groupe_membres (grep) ; `accueil_famille_page.dart`:73-93 | Un élève en Classe reste proposé aux enseignants (prendre_eleve) et compté dans "Foyers sans enseignant" (ADM-01 vers ADM-05). Double source de vérité | P1 | backend | Lot G-02 (ADR-028) |
| AUD-OFR-063 | Marketplace de Classes pour l'enseignant : réservation d'une Classe compatible dans les limites de l'administration (Maître l.81, 185 et 200) | Enseignant | enseignant_classes | ABSENT | Aucun dossier enseignant_classes à HEAD (liste lib/features) ; présent sur ccr (hors HEAD, non lu) | Aucune surface de prise de Classe | P1 | frontend, backend | ccr lib/features/enseignant_classes |
| AUD-OFR-064 | Disponibilités de l'enseignant et états de l'écran ENS-06 | Enseignant | GrilleSemaine, weekly_availability | CONFORME_PARTIEL | Tests lus non exécutés `test/features/creneaux_test.dart`:496-565, :622-760 (chargement, erreur, vide, hors ligne, sauvegarde, conflit) ; `creneaux_page.dart`:252-300 | Les disponibilités ne servent qu'au 1-à-1 ; la création de Classe ne les lit pas (AUD-OFR-034) | P2 | frontend, backend | Aucune tâche existante trouvée |
| AUD-OFR-065 | Un enseignant ne crée pas de séance sans confirmation de l'administration (Maître l.185) | Enseignant | Policy sessions_teacher_insert | CONTRADICTOIRE | `0001`:996-999 (insertion permise si teacher_id = auth.uid() et compte valide) | Un enseignant peut créer des séances orphelines et occuper son calendrier (EXCLUDE). Impact limité : aucun participant | P2 | backend | Aucune tâche existante trouvée |
| AUD-OFR-066 | "Mes groupes" de la famille et de l'élève alimenté par la donnée réelle | Famille, Élève | Accueil famille, Routes.tcGroupes, MesGroupesPage, portGroupesProvider | PRÉSENT_MAIS_NON_RACCORDÉ | `accueil_famille_page.dart`:462-468 ; `lib/core/tc_groupe/port_groupes.dart`:34-39 (défaut GroupesDemonstrationLocale) ; aucune surcharge dans `lib/main.dart`:106-130 ni `lib/app.dart` (grep : surcharges dans les tests seulement) ; `lib/core/tc_groupe/demonstration_groupes.dart`:41-150 (six Classes fictives, enseignants fictifs) ; aucune mention "démonstration" dans lib/features/tc_mes_groupes | En production une famille voit six groupes inventés (Al-Fatiha, An-Nour, Al-Ihsan, Al-Baqara, Al-Hikma, Ar-Rahma) | P0 | frontend, contrat partagé | docs/teaching-core/TC_CONTRACT_REQUEST_A.md sections 1 à 6 |
| AUD-OFR-067 | Horloge de séance de Classe Live alimentée par la donnée réelle | Élève, Enseignant | portHorlogeSeanceProvider ; RPC horloge_seance | PRÉSENT_MAIS_NON_RACCORDÉ | `lib/core/tc_horloge/port_horloge_seance.dart`:55 (défaut HorlogeSeanceDemonstration) ; RPC `0033`:~470-486 sans appel Dart (grep horloge_seance) | À confirmer avec le domaine Classe Live ; signalé ici car c'est une occurrence de séance | P1 | frontend | Domaine Classe Live |
| AUD-OFR-068 | Fiche d'une Classe pour son enseignant : lecture seule, sans nom de famille, limitée à ses Classes | Enseignant | Journée, Routes.groupePour, FicheGroupePage, mes_groupes_v, mon_groupe_detail | CONFORME_PROUVÉ | `lib/features/journee/journee_page.dart`:487 ; `app_router.dart`:358-361 ; `0025_role_enseignant.sql`:102-118 (vue filtrée g.teacher_id = auth.uid()), :133-160 (mon_groupe_detail : enseignant du groupe, compte valide, jamais de nom de famille) ; tests lus non exécutés `test/features/fiche_groupe_test.dart`:91-245 (chargement, contenu, vide, erreur, groupe d'un autre) | Aucun sur la règle. La fiche ne montre que l'ancre (un créneau) : `lib/core/enseignant/modeles_enseignant.dart`:222-240 | - | - | - |
| AUD-OFR-069 | Journée de l'enseignant : occurrences de Classe, séances annulées écartées, heures de l'appareil | Enseignant | JourneePage, seancesEnseignantProvider | CONFORME_PARTIEL | `journee_page.dart`:43-48, :215-300 ; `lib/core/planning/journee.dart`:70-150 ; tests lus (28) `test/features/journee_test.dart` | États de séance sans producteur (AUD-OFR-045) ; date illisible remplacée par DateTime.now() (`service_planning.dart`:93-99) | P2 | frontend | Aucune tâche existante trouvée |
| AUD-OFR-070 | Surveillance administrative des changements d'heure (transitions de fuseau à venir) | Admin | RPC transitions_fuseau_a_venir | PRÉSENT_MAIS_NON_RACCORDÉ | `0033`:499-553 ; aucun appelant (grep lib, test) ; heure_avant et heure_apres sont calculées dans le fuseau de la Classe sur une heure murale constante, donc toujours égales | Écran absent et sortie sans information utile | P2 | backend, frontend | Contrat A section 1.10 (commentaire `0033`:488-492) |
| AUD-OFR-071 | Correction de présence rattachée au cahier | Enseignant | PresenceCorrectionPanneau, cahier | CONFORME_PARTIEL | `lib/features/cahier/cahier_page.dart`:573-600 (capacités passées en constantes true, :592-595), :723-731 (l'adaptateur consigne dans le brouillon, sans mutation immédiate) ; tests lus `test/features/presence_correction_test.dart` | Les capacités ne viennent pas d'une autorisation serveur ; la garde réelle est celle du dépôt du cahier (domaine cahier) | P2 | frontend, backend | Aucune tâche existante trouvée |
| AUD-OFR-072 | Les règles de 0043 sont exercées par des scénarios SQL | Tous | supabase/tests, CI | IMPLÉMENTÉ_NON_PROUVÉ | Aucune occurrence de offres_horaires, groupe_creneaux ou intentions_horaire dans supabase/tests et .github ; `.github/workflows/ci.yml`:36-39 applique toutes les migrations mais aucun scénario ne les exerce ; tests Dart sur faux (`test/parcours/faux_service_offres.dart`) | Compatibilité, minimum, capacité, ancre, gardes et RLS non exécutés | P1 | backend | PR #29 (scénarios offres, hors HEAD) |
| AUD-OFR-073 | Aucun écran sans fiche au catalogue (CLAUDE.md racine, ADR-018) | Gouvernance | docs/design/08-catalogue-ecrans.md | ABSENT | Aucune occurrence de parcours_offres ni ParcoursOffres dans le catalogue ; ADM-09 n'a qu'une ligne de table (:79), sans fiche | La fiche du parcours d'offres et celle d'ADM-09 manquent ; zone K-64 selon D0910 section 5 | P2 | gouvernance | Aucune tâche existante trouvée |
| AUD-OFR-074 | Accès au parcours d'offres pour une famille en vérification d'identité | Famille | PorteAcces.attente ; compte_en_parcours | CONTRADICTOIRE | `0043`:154-195 (la porte du parcours ouvre pending_kyc) ; `lib/core/router/redirection.dart`:57-65 (attente confine à /attente) ; `lib/core/session/session_state.dart`:169 ; `lib/core/router/routes.dart`:82-89 | La population visée par la migration ne peut pas atteindre le parcours ; cohérent avec le Maître l.77 (contrôles avant catalogue), pas avec l'intention de 0043 | P2 | gouvernance | Aucune tâche existante trouvée |
| AUD-OFR-075 | Entrée de l'adulte autonome sans faux tuteur ni foyer fictif (Maître l.79 et 922) | Adulte | InscriptionPage ; peut_decrire_apprenant | CONTRADICTOIRE | `lib/features/inscription/inscription_page.dart`:37-45 (eleveAdulte mappé sur le rôle guardian, "son propre tuteur") ; ADR-009 (`decisions.md`:267-275) ; `0043`:197-228 | Hors domaine OFR (identité), signalé car l'offre adulte en dépend ; ne pas trancher ici | P1 | gouvernance | Aucune tâche existante trouvée |
| AUD-OFR-076 | Le second adulte du foyer n'agit sur le choix d'horaire que par délégation explicite (Maître l.924) | Famille | peut_decrire_apprenant | ABSENT | `0043`:197-228 (tout guardian du foyer décrit, choisit et renonce pour tous les élèves du foyer) ; aucune notion de délégation à HEAD | Pas de délégation | P1 | backend | Aucune tâche existante trouvée (domaine identité) |
| AUD-OFR-077 | Pagination serveur et filtres des listes admin ; volumétrie 500, 1 000, 10 000 (Maître l.204 ; K65 R17) | Admin | groupes_admin, offres_admin, pool_offre | ABSENT | `0019`:241-276 (aucune limite), `0043`:998-1044 et :1171-1212 ; `groupes_page.dart`:49-91 (liste complète en mémoire) ; aucun plan SQL ni jeu synthétique dans le dépôt | Aucun | P2 | backend, frontend | K65 section 3 |
| AUD-OFR-078 | Tableau par horaire : nombre de Classes, remplissage, demandes en attente, enseignants libres (K65 R19) | Admin | offres_admin | ABSENT | `0043`:998-1044 donne le vivier et le caractère lançable par offre, pas les Classes parallèles ni les enseignants libres | Aucun | P2 | backend, frontend | Aucune tâche existante trouvée |
| AUD-OFR-079 | Salle par séance et rafales de jetons et de rappels (K65 R14 et R15) | Visio | create-room-token | NON_APPLICABLE_JUSTIFIÉ | Domaine visio et notifications audité séparément ; aucune preuve lue ici | Renvoi | - | - | - |

## 3. Contradictions entre sources ou entre source et code

| ID | Source A | Source B | Périmètre | Décision la plus récente applicable | Statut | Conséquence |
|---|---|---|---|---|---|---|
| CTR-OFR-01 | Catalogue 08 fiche ENS-06 (action principale "Prendre un élève", `08-catalogue-ecrans.md`:1556), ADR-017, `docs/PROGRESS.md`:76-78, code `creneaux_page.dart` | Maître l.185, l.914 ; 00_LIRE_D_ABORD (ccr) "L'ancien matching individuel est remplacé" | Marketplace enseignant, entrée en Classe | Maître et 00_LIRE_D_ABORD (23/09), puis D0910 (09/10) | Ouvert | Le produit garde deux modèles d'entrée en cours (1-à-1 et Classe) ; le catalogue et PROGRESS.md ordonnent de conserver l'ancien |
| CTR-OFR-02 | TUT-04 : la famille pose librement ses horaires (onglet tuteur, `nav_shell.dart`:85-89) | D0910 section 2 ; Maître l.913 | Famille | D0910 | Ouvert | Deux entrées et deux sources pour la même intention |
| CTR-OFR-03 | ADR-030 (pas de demande hors offre) et ADR-031 (dispatch manuel, étape diagnostic), 22/09 | D0910 (09/10) : demande personnalisée discrète, regroupement automatique, bouton Créer la classe, proposition d'enseignant | Offres et demandes | D0910, qui se déclare prioritaire sur 0043 et 0049 | Obsolète pour la part contredite, ADR non amendés à HEAD | Le code et les textes de HEAD appliquent encore ADR-030 et ADR-031 |
| CTR-OFR-04 | Maître l.188 : cohortes 6-9, 10-13, 14-17, 18+ | `0043`:95-118 (5-7, 8-10, 11-14, 15-17, 18+) ; decisions.md question 5 (seuil 8) ; commentaire 0043 (seuil 10) | Cohortes d'âge | Aucune ne tranche | À arbitrer (direction) | Compatibilité et mode d'interface dépendent de la coupure |
| CTR-OFR-05 | Maître l.187 : 5 minutes de pause | `0043`:538 et ADR-031 : 6 minutes | Pause de séance | Maître (référence du 09/10), valeur configurable | À arbitrer (direction) | Texte annoncé aux familles ("dont 6 min de pause") ; aucune pause implémentée |
| CTR-OFR-06 | 00_LIRE_D_ABORD (ccr) : capacités 4/45 et 5/90 contre 5/60 et 6/90, ne pas présumer de défaut | D0910 section 2 (5 enfants, 6 adultes lus dans app_config) ; code : littéraux 5 et 6 (`0019`:72-73, `0033`:607-608), contrainte seuil_max au plus 6 (`0017`:28), défauts client | Capacité de Classe | D0910 pour la capacité ; Maître pour 60 et 90 | Résolu pour la décision, ouvert pour le code | Une capacité configurée au-delà de 6 est refusée par la contrainte |
| CTR-OFR-07 | `docs/HANDOFF.md`:2672 ("groupes/cohortes" renvoyés en V1) ; `docs/design/README.md`:172 ; decisions.md questions 20 et 33 "ouvertes" | ADR-028 (19 et 20/09) : le cours en groupe est la norme | Pivot groupe | ADR-028 | Obsolète | Documents de reprise périmés à HEAD |
| CTR-OFR-08 | ADR-028 : multi ouvert, maximum 7 en production | `0033`:1470-1500 sans plafond quand multi ouvert ; `scenarios_ctr01.sql` C2 valide le cas fermé | Plafond de participants | ADR-028 (assigne le correctif au lot G-02) | Ouvert | Le test et la production divergent |
| CTR-OFR-09 | `0043`:154-195 : un foyer pending_kyc doit pouvoir décrire et choisir | `redirection.dart`:57-65 : pending_kyc confiné à /attente ; Maître l.77 : contrôles d'identité avant le catalogue | Accès au parcours | Maître pour l'ordre de la chaîne | Ouvert | La porte serveur ouverte n'est jamais utilisée par l'interface |
| CTR-OFR-10 | ADR-031 et contrat : le client ne reçoit jamais le catalogue entier | `0043`:361-366 et :373 : lecture directe par tout compte connecté | Confidentialité de la vitrine | Règle de sécurité (écrite) | Ouvert | Garantie fausse, sensibilité faible |
| CTR-OFR-11 | Maître l.79 et l.922 : adulte autonome sans faux foyer | ADR-009, `inscription_page.dart`:37-45 : foyer d'une personne, tuteur de lui-même | Identité de l'adulte | Maître (consolidation des décisions de direction) | Ouvert, hors domaine OFR | Le parcours d'offre adulte repose sur le modèle contesté |
| CTR-OFR-12 | La vitrine annonce trois séances, 90 minutes pour un adulte, une pause (`offres_compatibles`, `fr.i18n.json` parcours.offreRecurrencePause) | `materialiser_seances_groupe` : une séance, 60 minutes, aucune pause | Promesse et occurrences | Maître l.187 (consommer la durée de la Classe) | Ouvert | Promesse non tenue au premier cours |
| CTR-OFR-13 | D0910 section 2 et `lib/CLAUDE.md` : un bouton qui ne peut pas aboutir n'est pas grisé | `PageParcours` : onAction nul rend un bouton inerte (`parcours_offres_page.dart`:261 et suivants ; `action_principale.dart`:94) | Parcours de personnalisation | D0910 (zone K-64) | Ouvert | Finition, sans effet métier |
| CTR-OFR-14 | `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md`:232 : écran d'administration des offres non bloquant | D0910 section 3 : l'administration reçoit les regroupements et crée les Classes par un écran | Outillage admin | D0910 | Ouvert | Sans écran, la chaîne famille vers Classe ne s'exécute pas |

## 4. Devoir de regard - contre-propositions

Aucune contre-proposition ne remplace une décision métier. Elles distinguent trois situations : (1) décision tranchée, implémentation défectueuse ; (2) décision tranchée, risque nouveau ; (3) contradiction entre sources actives.

### CP-OFR-01 Matérialisation des occurrences : créneaux, durée, passé, horizon, changement d'horaire

1. Identifiant : CP-OFR-01.
2. Source : AUD-OFR-038, 039, 040, 041, 042 ; CTR-OFR-12.
3. Constat : `0033`:315-372 ne lit que l'ancre, utilise la durée globale de 60 minutes, crée des occurrences passées et n'annule rien lors d'un changement d'horaire ; aucun ordonnanceur ne prolonge l'horizon de quatre semaines.
4. Risque : calendrier et confiance des familles (séances manquantes, durée fausse, "en recherche d'enseignant" affiché à tort).
5. Gravité et priorité : haute, P1. Situation 1.
6. Règle actuelle : Maître l.187 et 188 (consommer la durée effective de la Classe, compatibilité durant toutes les occurrences) ; ADR-031 (trois séances).
7. Contre-proposition : une fonction de matérialisation unique qui itère groupe_creneaux, lit une durée portée par la Classe (copie de offres_horaires.duree_minutes à la publication, ou lecture via groupes.offre_id), ignore les instants passés, annule ou signale les occurrences futures d'un ancien créneau, et est rappelée par une tâche planifiée sur l'horizon.
8. Options : durée stockée sur groupes (simple, historisée) ou lue sur l'offre (une seule source, mais offre retirable). Planificateur pg_cron ou fonction Edge planifiée.
9. Conséquences : corrige la promesse vitrine ; coût d'une migration et d'un job ; compatible avec la PR #29 migration 0055 (itération des créneaux) et la PR #21 migration 0075 (prochaine occurrence), qui ne traitent pas la durée.
10. Périmètre technique : backend, contrat partagé (durée de Classe).
11. Dépendances : PR #29, PR #21, AUD-OFR-045.
12. Critères d'acceptation : une Classe de trois créneaux produit trois occurrences par semaine sur l'horizon ; une Classe adulte produit 90 minutes ; aucune occurrence antérieure à l'instant de création ; un changement d'horaire ne laisse aucune occurrence active à l'ancien créneau ; l'horizon reste de quatre semaines sans intervention.
13. Tests et preuves : scénario SQL avec horloge simulée, bascule d'heure Europe et États-Unis, rejeu idempotent ; plan d'exécution pour 1 000 Classes.
14. Décision requise : validation technique ; durée de Classe à confirmer par la direction (voir CP-OFR-13).

### CP-OFR-02 Retirer les données de démonstration de "Mes groupes" en production

1. Identifiant : CP-OFR-02.
2. Source : AUD-OFR-066, 067.
3. Constat : `port_groupes.dart`:34-39 retourne par défaut six Classes fictives, atteintes depuis l'accueil famille (`accueil_famille_page.dart`:462-468), sans surcharge dans main.dart ni app.dart.
4. Risque : une famille lit des Classes et des enseignants inventés ; fiabilité et confiance institutionnelle.
5. Gravité et priorité : haute, P0. Situation 1.
6. Règle actuelle : Maître section 25.2 (PRÉSENT_MAIS_NON_RACCORDÉ) ; CLAUDE.md racine (états loading, content, empty, error, offline réels).
7. Contre-proposition : en build de production, le port par défaut est un port "indisponible" qui rend l'état erreur ou vide honnête ; le double de démonstration n'est branché que par la galerie et les tests ; brancher ensuite un adaptateur réel sur les lectures de la section 2 de TC_CONTRACT_REQUEST_A.md.
8. Options : masquer l'entrée "Mes groupes" tant que l'adaptateur réel manque (capacité serveur).
9. Conséquences : la famille voit un état indisponible plutôt qu'un faux contenu ; aucune migration nécessaire pour la mesure de confinement.
10. Périmètre technique : frontend (confinement), contrat partagé (lecture réelle).
11. Dépendances : TC_CONTRACT_REQUEST_A.md sections 1 à 6.
12. Critères d'acceptation : un build release sans surcharge ne contient aucun nom de Classe fictif ; l'écran affiche loading, empty, error et offline réels.
13. Tests et preuves : test qui échoue si le provider de production renvoie GroupesDemonstrationLocale ; capture du build réel.
14. Décision requise : aucune pour le confinement.

### CP-OFR-03 Chaîne administrateur de la demande à la Classe

1. Identifiant : CP-OFR-03.
2. Source : AUD-OFR-003, 004, 030, 031, 032, 033, 034, 035 ; CTR-OFR-03, CTR-OFR-14.
3. Constat : à HEAD le seul chemin est un appel SQL manuel de publier_groupe_depuis_offre ; les écrans admin_regroupements et la proposition d'enseignant n'existent que sur ccr, et le backend de regroupement que dans les PR #29 et #21.
4. Risque : la chaîne famille vers Classe ne s'exécute pas ; parcours critique.
5. Gravité et priorité : critique, P0. Situation 1.
6. Règle actuelle : D0910 sections 1 et 3 ; Maître l.185.
7. Contre-proposition : réemployer l'existant. Livrer d'abord les écrans d'offres et de regroupements sur les RPC de 0043 puis de la PR #29, créer la Classe sans enseignant (C-12), proposer l'enseignant (PR #21 0082), confirmer. Ne pas créer de second service : ServiceOffresSupabase reste le seul point d'appel.
8. Options : fusionner d'abord la PR #29 seule (regroupements privés, C-12) puis la PR #21.
9. Conséquences : fait passer AUD-OFR-030 à 035 ; coût : revue de sécurité des RPC et tests de concurrence ; risque résiduel : dépendance entre PR Codex.
10. Périmètre technique : frontend, backend, contrat partagé.
11. Dépendances : PR #29, PR #21, AUD-OFR-004, AUD-OFR-036.
12. Critères d'acceptation : une administratrice publie une offre, voit un regroupement prêt, crée la Classe, confirme l'enseignant ; deux administrateurs simultanés obtiennent une seule Classe ; chaque famille voit l'étape franchie.
13. Tests et preuves : scénarios SQL concurrents, tests widget à 320 px, texte à 200 % et RTL, capture sur staging.
14. Décision requise : arbitrage du directeur sur l'ordre de fusion des PR et sur le statut "non bloquant" du contrat FABLE.

### CP-OFR-04 Un seul modèle d'entrée en cours : traiter le matching individuel hérité

1. Identifiant : CP-OFR-04.
2. Source : AUD-OFR-059, 060, 061, 062, 063, 064 ; CTR-OFR-01, CTR-OFR-02.
3. Constat : ENS-06, ADM-05 et TUT-04 restent actifs, routés et testés ; eleves_en_attente_v, eleves_sans_enseignant et indicateurs_admin ignorent les membres de Classe.
4. Risque : double source de vérité ; un élève de Classe peut être pris en 1-à-1 par un second enseignant ; compteurs faux ; incohérence entre rôles.
5. Gravité et priorité : haute, P1. Situation 3 (catalogue et PROGRESS contre Maître).
6. Règle actuelle : Maître l.914 ("ne pas réintroduire") ; ADR-028 renvoie la suppression de teacher_student_assignments au lot G-02.
7. Contre-proposition : sans supprimer le code, (a) exclure les membres actifs d'une Classe des trois objets ci-dessus, (b) piloter l'onglet Élèves d'ENS-06 et l'entrée "Poser un horaire" par une capacité serveur désactivée par défaut, (c) retirer EXECUTE sur prendre_eleve et attribuer_eleve une fois le lot G-02 validé, (d) mettre à jour le catalogue et PROGRESS.md.
8. Options : requalifier ENS-06 en marketplace de Classes (ccr enseignant_classes) plutôt que de retirer l'onglet.
9. Conséquences : réversible par configuration ; préserve les tests existants ; coût : migration de vues et arbitrage produit.
10. Périmètre technique : backend, frontend, gouvernance.
11. Dépendances : lot G-02, AUD-OFR-063.
12. Critères d'acceptation : un élève membre d'une Classe n'apparaît ni dans le feed enseignant, ni dans la file ADM-05, ni dans "Foyers sans enseignant" ; aucune affectation 1-à-1 ne peut être créée sans la capacité.
13. Tests et preuves : scénarios SQL sur les trois objets ; tests des écrans avec capacité désactivée.
14. Décision requise : arbitrage du directeur (sort d'ENS-06, ADM-05, TUT-04).

### CP-OFR-05 Changement d'avis et offre retirée

1. Identifiant : CP-OFR-05.
2. Source : AUD-OFR-014, 015, 016.
3. Constat : renoncer_intention_horaire n'est appelée par aucun écran ; après retrait d'offre le choix suivant échoue sur l'index unique ; l'état "offre retirée" écrase "groupe confirmé".
4. Risque : parcours impossible à terminer ; message faux à une famille déjà en Classe.
5. Gravité et priorité : haute, P0 pour le blocage, P1 pour le message. Situations 1 et 2.
6. Règle actuelle : ADR-031 (offre retirée prime) ; Maître l.196 (dire ce qui est acquis).
7. Contre-proposition : une RPC atomique "changer_intention_horaire" (renonce et choisit dans une transaction, motif automatique) appelée par l'écran ; calculer offre_indisponible seulement si l'intention n'est pas affectée ; proposer "Changer d'horaire" pour tous les états non affectés.
8. Options : appeler renoncer puis choisir côté client (deux appels, risque d'état intermédiaire).
9. Conséquences : supprime le cul-de-sac ; amende ADR-031 sur la priorité ; migration légère.
10. Périmètre technique : frontend, backend.
11. Dépendances : AUD-OFR-004.
12. Critères d'acceptation : après retrait d'une offre une famille choisit une autre offre en un parcours ; une famille en Classe ne voit jamais "offre retirée".
13. Tests et preuves : scénario SQL de retrait puis rechoix ; test Dart de etapeParcours avec intention affectée et offre retirée.
14. Décision requise : validation du directeur pour l'amendement de la priorité d'ADR-031.

### CP-OFR-06 Fuseau déclaré et affichage

1. Identifiant : CP-OFR-06.
2. Source : AUD-OFR-024, 025, 026, 027.
3. Constat : le fuseau par défaut du foyer (Paris) est lu comme déclaré ; la légende "d'après l'heure de votre appareil" devient fausse ; l'identifiant IANA est montré ; la dérive d'heure d'été n'est pas signalée.
4. Risque : une famille manque son cours par erreur de fuseau.
5. Gravité et priorité : haute, P1. Situation 1.
6. Règle actuelle : Maître l.1059 (fuseaux, dates, devise) et l.204 (DST).
7. Contre-proposition : ajouter un indicateur "fuseau confirmé" (colonne ou lecture de onboarding_fait_le) ; tant qu'il manque, ne pas présélectionner le défaut et proposer la suggestion d'appareil ; afficher le lieu choisi ; calculer en vue la dérive d'heure entre heure_affichee et l'heure actuelle de l'offre.
8. Options : retirer le défaut de households.timezone après migration des données.
9. Conséquences : une étape de confirmation de plus ; plus de légende fausse.
10. Périmètre technique : frontend, backend.
11. Dépendances : aucune.
12. Critères d'acceptation : un foyer sans confirmation voit le fuseau de l'appareil proposé et non coché par défaut ; la bascule d'heure d'été déclenche un message avant le premier cours.
13. Tests et preuves : test Dart du cas "défaut de la base" ; scénario SQL de dérive pour Paris et Toronto.
14. Décision requise : aucune.

### CP-OFR-07 Concurrence : capacité, idempotence, verrous

1. Identifiant : CP-OFR-07.
2. Source : AUD-OFR-031, 053, 057 ; K65 R8.
3. Constat : guard_groupe_membre_cap compte puis insère sans verrou ; publier_groupe_depuis_offre n'a ni clé d'idempotence ni verrou ; guard_session_overlap lit puis insère.
4. Risque : dépassement de capacité sous deux administrateurs simultanés ; doublons.
5. Gravité et priorité : moyenne, P1 (vraisemblance faible tant que l'écriture est réservée à l'administration). Situation 1.
6. Règle actuelle : Maître l.192 et 918 ; K65 R8.
7. Contre-proposition : verrou de ligne (select for update sur groupes) dans le déclencheur de capacité ; verrou consultatif par offre ou par clé de regroupement et clé d'idempotence dans publier_groupe_depuis_offre ; même méthode que la PR #29 migration 0055.
8. Options : contrainte différée avec compteur matérialisé sur groupes.
9. Conséquences : sérialise les écritures d'une même Classe ; léger coût de verrou.
10. Périmètre technique : backend.
11. Dépendances : PR #29.
12. Critères d'acceptation : deux sessions SQL concurrentes sur la dernière place donnent un succès et un refus clair ; un rejeu de la publication avec la même clé ne crée rien.
13. Tests et preuves : scénario à deux sessions (dblink ou deux connexions psql) ; mesure des attentes de verrou.
14. Décision requise : aucune.

### CP-OFR-08 Cycle de vie des occurrences et exceptions de calendrier

1. Identifiant : CP-OFR-08.
2. Source : AUD-OFR-043, 044, 045, 046 ; Maître l.915 et 932-933.
3. Constat : les états de séance existent mais aucun code du dépôt ne les produit ; aucune RPC d'annulation, report, congé ou remplacement ; incidents_24h additionne absences et pannes.
4. Risque : consommateurs (cahiers en retard, qualité, paie) toujours vides ; confusion absence et incident technique ; conséquences financières et pédagogiques non tracées.
5. Gravité et priorité : haute, P1. Situation 1.
6. Règle actuelle : Maître l.915, 932, 933 ; K65 R12.
7. Contre-proposition : un module d'exceptions avec RPC dédiées (annuler, reporter, remplacer, mettre en congé), table d'événements avec motif, auteur et horodatage, producteur serveur des transitions de statut à partir des événements de salle, et compteurs séparés pour absence réelle et incident technique.
8. Options : reprendre le port et l'écran REMPL-1 de ccr comme interface.
9. Conséquences : active les consommateurs existants ; coût élevé ; interactions avec la paie à cadrer.
10. Périmètre technique : backend, contrat partagé, gouvernance.
11. Dépendances : PR #21 (notifications), domaine présence.
12. Critères d'acceptation : chaque exception laisse une trace ; une panne réseau ne crée jamais une absence ; une séance terminée apparaît dans les rapports en attente.
13. Tests et preuves : scénarios SQL des transitions ; tests de non-confusion absence et incident.
14. Décision requise : arbitrage du directeur sur les règles d'annulation tardive et leurs effets financiers ; je ne les fixe pas.

### CP-OFR-09 Protection des mineurs : cohorte et public de l'offre

1. Identifiant : CP-OFR-09.
2. Source : AUD-OFR-021, 031.
3. Constat : cohorte, langue_cours, niveau_declare et objectif sont modifiables par UPDATE direct ; offres_compatibles lit cohorte ; publier_groupe_depuis_offre ne revérifie pas le public de l'élève ; pool_offre n'expose pas la tranche.
4. Risque : un mineur placé dans un groupe d'adultes ; sécurité des personnes.
5. Gravité et priorité : moyenne, P1 (vraisemblance faible, impact élevé). Situation 2.
6. Règle actuelle : 0043 (le serveur décide qui est mineur) ; Maître section 28.2.
7. Contre-proposition : retirer ces colonnes du GRANT UPDATE et ne laisser que la RPC ; vérifier à la publication que type_public de la cohorte de chaque élève égale celui de l'offre ; ajouter la tranche d'âge au vivier présenté à l'administration (pas de date de naissance).
8. Options : trigger de cohérence cohorte et student_type en complément.
9. Conséquences : l'écriture directe d'un tuteur échoue ; aucun impact sur l'écran actuel qui passe par la RPC.
10. Périmètre technique : backend.
11. Dépendances : AUD-OFR-004.
12. Critères d'acceptation : un UPDATE direct de cohorte est refusé ; la publication refuse un élève d'un autre public.
13. Tests et preuves : scénarios SQL en rôle guardian et en rôle student.
14. Décision requise : aucune.

### CP-OFR-10 Promesses de notification et de rendez-vous de diagnostic

1. Identifiant : CP-OFR-10.
2. Source : AUD-OFR-018, 019.
3. Constat : deux textes promettent un avertissement sans canal ; le texte de diagnostic promet un rendez-vous sans producteur ; un diagnostic fait s'afficherait comme à faire.
4. Risque : faux succès, déception des familles, atteinte à la crédibilité.
5. Gravité et priorité : haute, P1. Situation 1.
6. Règle actuelle : Maître l.186 ; Mission section B (faux succès).
7. Contre-proposition : reformuler sans promesse tant que le canal n'existe pas ("L'académie vous contactera") ou conditionner la phrase à une capacité serveur "notifications actives" ; relier ou retirer l'étape diagnostic ; corriger etapeParcours pour le statut fait.
8. Options : livrer d'abord le canal de la PR #21 (0063, 0066, 0078).
9. Conséquences : textes honnêtes immédiatement ; coût faible.
10. Périmètre technique : frontend (textes), backend (producteur), contenu académique (place du diagnostic).
11. Dépendances : PR #21 ; avis de l'autorité pédagogique.
12. Critères d'acceptation : aucun texte ne promet un avertissement non émis ; l'état "diagnostic fait" ne dit plus "à faire".
13. Tests et preuves : tests de libellés ; test etapeParcours pour StatutDiagnostic.fait.
14. Décision requise : validation compétente de l'équipe pédagogique pour le rôle du diagnostic.

### CP-OFR-11 Désambiguïsation des surcharges creer_groupe et modifier_groupe

1. Identifiant : CP-OFR-11.
2. Source : AUD-OFR-036 ; ccr migration 0045.
3. Constat : le client envoie six et cinq paramètres nommés ; deux signatures par fonction les acceptent depuis 0033 ; la correction 0045 n'est pas à HEAD.
4. Risque : création et modification de Classe refusées (régression possible de 0033).
5. Gravité et priorité : haute, P0 (non démontré en exécution). Situation 1.
6. Règle actuelle : supabase/CLAUDE.md ; contrat de signatures de 0045.
7. Contre-proposition : intégrer 0045 avant toute application de 0033 en production, et ajouter un scénario qui appelle les deux fonctions avec les paramètres exacts du client.
8. Options : faire passer le client aux huit paramètres.
9. Conséquences : aucune sur les appels internes (déjà nommés dans 0043).
10. Périmètre technique : backend.
11. Dépendances : continuité de numérotation (AUD-OFR-004).
12. Critères d'acceptation : appels à six et cinq paramètres résolus sans ambiguïté sur staging.
13. Tests et preuves : scénario SQL et appel PostgREST de recette.
14. Décision requise : aucune.

### CP-OFR-12 Plafond de participation et tests négatifs de cloisonnement

1. Identifiant : CP-OFR-12.
2. Source : AUD-OFR-051, 052 ; CTR-OFR-08.
3. Constat : guard_session_participant_cap ne plafonne plus quand le multi est ouvert ; aucun scénario ne vérifie qu'une Classe ne lit pas une autre au même horaire.
4. Risque : dépassement de participants, fuite entre Classes non détectée.
5. Gravité et priorité : moyenne, P1. Situation 1 (G-02 déjà assigné).
6. Règle actuelle : ADR-028 ; K65 R13.
7. Contre-proposition : plafonner sur le seuil du groupe de la séance, y compris quand le multi est ouvert ; ajouter les scénarios négatifs R13.
8. Options : aucune utile.
9. Conséquences : aucune sur les flux légitimes.
10. Périmètre technique : backend.
11. Dépendances : lot G-02.
12. Critères d'acceptation : la septième insertion est refusée ; un élève de la Classe 3 ne lit rien de la Classe 4.
13. Tests et preuves : scénarios SQL.
14. Décision requise : aucune.

### CP-OFR-13 Valeurs de référence : pause, cohortes, capacités littérales

1. Identifiant : CP-OFR-13.
2. Source : AUD-OFR-022, 028, 029 ; CTR-OFR-04, 05, 06.
3. Constat : trois coupures d'âge, pause 5 contre 6, capacités 5 et 6 écrites en littéral dans deux fonctions et dans le client, contrainte au plus 6.
4. Risque : règles divergentes selon l'écran ; blocage si la direction change la capacité.
5. Gravité et priorité : basse à moyenne, P1 pour les cohortes, P2 pour le reste. Situation 3.
6. Règle actuelle : Maître l.187, 188, 917 ; D0910 section 2.
7. Contre-proposition : la direction fixe cohortes, pause, capacités et durées ; mise à jour par update de app_config et cohortes_age ; creer_groupe lit app_config ; la contrainte seuil_max est alignée sur la capacité maximale décidée ; le client n'a plus de défaut.
8. Options : conserver deux valeurs selon la catégorie de Classe, comme l'autorise Maître l.917.
9. Conséquences : une seule source de vérité.
10. Périmètre technique : gouvernance, backend, frontend.
11. Dépendances : décision de la direction.
12. Critères d'acceptation : aucune valeur de capacité, de durée ou de pause dans le code ; l'écran affiche la valeur configurée.
13. Tests et preuves : tests de lecture de configuration ; grep sur les littéraux.
14. Décision requise : arbitrage du directeur.

### CP-OFR-14 Durcissement de lecture et de création

1. Identifiant : CP-OFR-14.
2. Source : AUD-OFR-006, 065 ; alertes de sécurité S2, S3, S4.
3. Constat : offres publiées lisibles en direct avec created_by et publiee_par ; eleves_en_attente_v filtre sur le rôle du jeton sans app_account_valid ; sessions_teacher_insert.
4. Risque : exposition limitée de données d'enfants à un jeton d'enseignant devenu non valide ; séances orphelines.
5. Gravité et priorité : basse à moyenne, P2 (P1 pour la vue d'élèves en attente). Situation 2.
6. Règle actuelle : supabase/CLAUDE.md ; Maître l.185.
7. Contre-proposition : accorder seulement les colonnes d'affichage sur offres_horaires ; ajouter app_account_valid à la vue ; supprimer la policy d'insertion enseignante sur sessions si aucun écran ne l'emploie.
8. Options : supprimer la vue lorsque le matching individuel est retiré (CP-OFR-04).
9. Conséquences : aucune pour les flux actuels.
10. Périmètre technique : backend.
11. Dépendances : CP-OFR-04.
12. Critères d'acceptation : un enseignant suspendu reçoit zéro ligne ; la vitrine n'expose plus d'identifiant d'administrateur.
13. Tests et preuves : scénarios SQL avec jeton valide et compte suspendu.
14. Décision requise : aucune.

### CP-OFR-15 Création de Classe par l'administration : saisie guidée

1. Identifiant : CP-OFR-15.
2. Source : AUD-OFR-035, 037, 058.
3. Constat : enseignant saisi par identifiant brut, jour et heure en texte libre avec repli silencieux, fuseau figé, erreurs brutes, aucun test.
4. Risque : Classe créée au mauvais horaire sans erreur ; confusion de fuseau.
5. Gravité et priorité : haute, P1. Situation 1.
6. Règle actuelle : lib/CLAUDE.md (ChoiceCardGroup, états complets) ; Maître l.1059.
7. Contre-proposition : sélection de l'enseignant dans une liste, jour et heure par choix, fuseau choisi et affiché, validation avant envoi sans repli silencieux, messages d'erreur traduits ; réemployer CLASSE-FORM-1 de ccr.
8. Options : retirer la création manuelle quand l'écran de regroupements existe.
9. Conséquences : réduit les erreurs de saisie.
10. Périmètre technique : frontend.
11. Dépendances : AUD-OFR-036, 037.
12. Critères d'acceptation : une heure invalide est refusée avec une phrase ; le fuseau de la Classe est visible dans la liste.
13. Tests et preuves : tests widget (états, 320 px, texte à 200 %, RTL).
14. Décision requise : aucune.

### CP-OFR-16 Gouvernance documentaire

1. Identifiant : CP-OFR-16.
2. Source : AUD-OFR-073 ; CTR-OFR-03, 07.
3. Constat : le catalogue ignore le parcours d'offres et la fiche ADM-09 ; ADR-030 et ADR-031 sont contredits par la décision du 09/10 sans amendement ; PROGRESS.md et HANDOFF.md ne mentionnent ni 0043 ni les offres.
4. Risque : la prochaine session suit des sources périmées.
5. Gravité et priorité : basse, P2. Situation 3.
6. Règle actuelle : CLAUDE.md racine (aucun écran sans fiche).
7. Contre-proposition : inscrire les fiches manquantes, amender ADR-030 et ADR-031 en renvoyant à D0910, et rapatrier docs/current dans la branche d'intégration.
8. Options : un seul ADR de réconciliation.
9. Conséquences : une source d'autorité claire.
10. Périmètre technique : gouvernance.
11. Dépendances : décision d'intégration de la branche ccr.
12. Critères d'acceptation : chaque écran routé du domaine a une fiche ; les ADR citent la décision active.
13. Tests et preuves : relecture croisée catalogue et routeur.
14. Décision requise : arbitrage du directeur sur la branche de référence.

### CP-OFR-17 Volumétrie

1. Identifiant : CP-OFR-17.
2. Source : AUD-OFR-077, 078.
3. Constat : listes d'administration sans limite ni filtre serveur ; aucun jeu synthétique ni plan SQL.
4. Risque : lenteur et blocage aux volumes visés par la direction.
5. Gravité et priorité : moyenne, P2. Situation 1.
6. Règle actuelle : K65 R17, Maître l.204.
7. Contre-proposition : pagination par curseur et filtres (horaire, catégorie, enseignant, remplissage, état), index sur groupe_id, état des demandes, début des séances ; recette de 500, 1 000 et 10 000 élèves.
8. Options : vues matérialisées pour les compteurs.
9. Conséquences : coût de migration et de tests.
10. Périmètre technique : backend, frontend.
11. Dépendances : CP-OFR-03.
12. Critères d'acceptation : temps et plans consignés ; aucune requête non bornée.
13. Tests et preuves : jeu synthétique, EXPLAIN, mesures de verrous.
14. Décision requise : aucune.

## 5. États d'écran et applicabilité

Sources : lecture du code et des noms de tests, sans exécution. "Banner" désigne la bannière hors ligne de PageShell (`lib/core/widgets/page_shell.dart`:119).

| Écran | Chargement | Contenu | Vide | Erreur | Hors ligne | Session expirée | Accès refusé | Reprise |
|---|---|---|---|---|---|---|---|---|
| Parcours d'offres (`parcours_offres_page.dart`) | Présent (squelettes :224, :281, :319, :492) | Présent | Présent (`_pageAucuneOffre` :560-578) | Présent (phrase sous le bouton, générique) | Absent : PageParcours n'a pas de bannière, l'échec d'écriture hors ligne donne l'erreur générique | Non applicable à l'écran, redirection globale (`redirection.dart`:36-44) | Non applicable, redirection vers la racine du rôle (:119-120), sans message | Présent (reprend aux horaires si le profil est rempli, :228-233 ; réponses relues) |
| Bloc parcours de l'accueil (`bloc_parcours.dart`) | Muet voulu (:46-48) | Présent | Se retire quand tout est confirmé (:57) | Muet voulu (test lu :445-457) : écart à la règle des cinq états | Muet | Non applicable | Non applicable | Non applicable |
| Mes groupes (famille, élève) | Non lu | Données de démonstration (AUD-OFR-066) | Non lu | Non lu | Non lu | Non applicable | Non lu | Non lu |
| ENS-06 Créneaux (`creneaux_page.dart`) | Présent | Présent | Présent | Présent avec relecture | Présent (prise non rendue) | Non applicable | Non applicable | Non applicable |
| TUT-04 Disponibilités (`disponibilites_page.dart`) | Absent (aucun squelette) | Présent | Présent | Présent (texte) | Banner | Non applicable | Non applicable | Non applicable |
| ADM-09 Groupes (`groupes_page.dart`) | Présent (:89) | Présent | Présent (:149) | Présent (:83) | Banner seulement | Non applicable | Non applicable | Non applicable (feuille perdue si fermée) |
| ADM-05 Attribution | Présent | Présent | Présent | Présent | Banner | Non applicable | Non applicable | Non applicable |
| ADM-06 Demandes | Présent | Présent | Présent | Présent | Présent | Non applicable | Non applicable | Non applicable |
| ENS-07 Fiche de Classe | Présent (test :91) | Présent (:112) | Présent (:151) | Présent (:174) | Banner | Non applicable | Présent : groupe d'un autre, sans erreur (test :197) | Non applicable |
| ENS-02 Journée | Présent (:168, :201-209) | Présent | Présent (:391) | Présent (:287-295) | Présent (:407, :469) | Non applicable | Non applicable | Présent (bouton de salle selon fenêtre) |
| Inscription (TUT-00c) | Hors domaine | Hors domaine | Hors domaine | Hors domaine | Hors domaine | Hors domaine | Hors domaine | Hors domaine |

Applicabilité : "session expirée" et "accès refusé" sont traités par le routeur unique (déconnecté vers connexion, rôle étranger vers la racine du rôle) et non par chaque écran. Le serveur reste la barrière (RLS, gardes positives).

## 6. Non vérifié et limites de la preuve

- Aucun test exécuté (Flutter, Dart et Postgres absents). Les tests Dart et les scénarios SQL cités sont lus, jamais joués.
- Aucune base consultée : l'état réel de production et de staging (migrations appliquées, valeurs de app_config comme allow_multi_participant_sessions, contenu de la vitrine) n'est pas connu. Le message du commit 4a7aa2b dit 0043 non appliquée en production.
- Les comportements de concurrence (capacité, doublons) et de résolution de surcharge PostgREST sont déduits de la lecture du SQL et de la migration 0045 de ccr, non exécutés.
- La branche ccr contient des écrans et des documents que cet audit n'a pas relus au niveau du code (admin_regroupements, suivi_demandes, classe_tuteur, enseignant_classes, remplacements, admin_planning). Tout statut ABSENT est limité à HEAD.
- Les patchs de la PR #21 lus par mots-clés peuvent être tronqués ; l'absence d'annulation, de remplacement, de liste d'attente, de fusion et de transfert dans cette PR n'est donc pas prouvée de façon définitive.
- Les PR #13, #17 et les PR documentaires ou de sécurité d'identité n'ont pas été lues en détail ; les PR #30, #28, #20 et #10 (identité agent) n'ont pas été croisées avec les masquages de pool_offre et de groupes_admin.
- Non lus : docs/design/00-bible-frontend-v2.md, README de design en détail, UX_REVIEW_OFFRES-FAM-1, CLASSE-FORM-1, DISPO-1, l'écran MesGroupesPage et ses tests, et les sources du Maître absentes du dépôt.
- Le contenu du jeton de l'enfant (rôle student avec household_id) est déduit de 0038 ; l'exploitation de AUD-OFR-021 par une session enfant n'est pas démontrée.
- Aucune règle religieuse ou scientifique n'a été modifiée ni tranchée. Points à faire valider : place du diagnostic de niveau dans la chaîne d'entrée (AUD-OFR-019), cohortes d'âge (AUD-OFR-022), durée et pause de séance (AUD-OFR-029).
