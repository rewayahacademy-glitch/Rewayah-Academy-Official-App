# TEACHING_CORE_EXISTING_MAPPING.md

> Synthèse des huit cartographies du dépôt réel, arrêtée sur `TEACHING_BASELINE_SHA = 550e605`.
> Tous les chemins ci-dessous ont été **vérifiés dans `D:\RA_TC\0`**. Aucun n'est supposé.
> Marquage : **[P]** = fichier PROTECTED (voir `TEACHING_CORE_PROTECTED_FILES.md`).

---

## Sommaire

1. Groupes, sessions, planning, fuseaux
2. Bibliothèque, ressources, cache offline
3. Coran : corpus, structure, rendu
4. LiveKit, salle, session persistante
5. Présence et fenêtre de connexion
6. Roster enseignant et confidentialité PII
7. Tuteur, Admin, Contrôleur, audit
8. Socle partagé
9. **DOUBLONS À NE PAS CRÉER**
10. **MODÈLE DE DONNÉES EXISTANT**

---

## 1. Groupes, sessions, planning, fuseaux horaires

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `supabase/migrations/0017_groupes_pedagogiques.sql` | Crée `groupes` + `groupe_membres`, le déclencheur de plafond, les 5 RPC d'écriture et les 2 RPC de lecture. Ouvre la visio multi-participants (`max_participants_per_session=7`). **Source d'autorité du modèle de Groupe.** |
| `supabase/migrations/0019_groupes_durcissement.sql` | **Version courante** des 7 fonctions : `app_account_valid()`, revoke `agent_ro` sur les écritures, policies rejouées. C'est cette version des signatures qu'il faut lire, pas celle de 0017. |
| `supabase/migrations/0005_dashboards_affectation_regles.sql` | `mon_fuseau()`, `instant_creneau()`, `materialiser_seances()`, vues `mes_seances_v` / `mes_affectations_v`, `weekly_availability`. |
| `supabase/migrations/0006_rattrapage_semaine_utc_et_foyer.sql` | **Version courante** de `instant_creneau()` : ancre `date_trunc('week')` en UTC. Le bug corrigé (7 jours d'écart entre Paris et Conakry) est exactement le piège qu'un recodage réintroduirait. |
| `lib/core/planning/service_planning.dart` | `Creneau` (jour ISO, heure locale, **fuseau IANA**), `Seance` (avec `duree`, `enCoursA()`, `avantDebut()`), `Affectation`, interface `ServicePlanning`, providers `monFuseauProvider` / `seancesProvider` / `affectationsProvider`. **Le modèle de séance côté client.** |
| `lib/core/planning/journee.dart` | `construireJournee()`, `prochainCours()` (en cours prioritaire, sinon prochain à venir, annulées écartées), `seanceAnnuleeDuJour()`. `prochainCours()` **est déjà** la fonction « prochaine séance » de la Session Card. |
| `lib/features/disponibilites/grille_semaine.dart` | Composant `GrilleSemaine` : grille 7 jours × heures, plage par défaut 6h-21h élargie, haptique, libellés sémantiques. Partagé littéralement par TUT-04 et ENS-06. |
| `lib/core/admin/service_groupes.dart` | `GroupeAdmin`, `MembreGroupe`, `TypePublicGroupe`, `ServiceGroupes`, `groupesProvider`, `membresGroupeProvider`. |
| `lib/core/controle/service_controle.dart` | `plafondPlanningGlobal = 200`, `graceApresFin = 15 min`, lecture de `mes_seances_v`. Précédent explicite : « la lecture ne passe par aucune vue neuve ». |

### Ce qui manque

- **Aucun lien Groupe → Session.** `sessions` n'a pas de `groupe_id`, aucune table de jonction.
- **Aucune matérialisation d'occurrences pour un groupe.** `materialiser_seances(p_assignment_id)` lit `teacher_student_assignments`.
- **Le fuseau de groupe est un faux existant.** `groupes.timezone_iana` est créée avec `default 'Europe/Paris'` mais **aucune RPC ne l'écrit**, `groupes_admin()` ne la retourne pas, et `GroupeAdmin.depuisJson` la recode **en dur** à `'Europe/Paris'` (~ligne 69). Trois maillons à corriger.
- Aucun `join_opens_at` persisté, aucune horloge serveur exposée, aucune alerte DST, aucune route Espace Groupe côté élève/tuteur/enseignant, aucun `Admin > Opérations > Planning`.
- Aucune conversion IANA possible côté client : ni `timezone`, ni `tz`, ni `flutter_timezone`, ni `intl` dans `pubspec.yaml`.
- Aucune vue ni RPC rendant une séance **agrégée par groupe** : `mes_seances_v` est mono-élève, un groupe de 5 y produit 5 lignes.
- `recurrence_rules` et `availability_slots` (0001) existent avec RLS mais ont **zéro usage** dans `lib/`. Ce sont des vestiges, pas un moteur de récurrence.

---

## 2. Bibliothèque, ressources, cache offline, téléchargement

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `lib/core/cache/media/cache_media.dart` | Interface `CacheMedia` + `CacheMediaFichiers` sur `flutter_cache_manager`, et `PurgePhotos`. **Abstraction de cache fichier déjà posée.** |
| `lib/core/cache/sync/file_rapports.dart` | `RapportEnAttente`, interface `DepotRapports`, `FileRapports` avec clé d'idempotence uuid et compteur de tentatives. **Patron « file d'attente idempotente + rejeu au retour du réseau » directement transposable.** |
| `lib/core/appairage/profils_locaux.dart` | `baseLocaleProvider` (ligne 100) et `ProfilsLocauxDrift` (ligne 53). **Le modèle exact à copier** pour un dépôt Drift : interface, implémentation, faux mémoire. |
| `lib/core/dossier/selecteur_fichier.dart` | Interface `SelecteurFichier` + `SelecteurFichierNatif` sur `file_picker`, `extensionsAcceptees` incluant déjà `'pdf'`. |
| `lib/core/appairage/service_avatar.dart` | Upload (ligne 140) et `urlSignee(cleAvatar)` (ligne 148). **Seul exemple d'URL signée du dépôt** — leçon déjà inscrite : on persiste la CLÉ, jamais l'URL signée qui expire. |
| `lib/core/reseau/service_reseau.dart` + `lib/core/widgets/offline_banner.dart` | `horsLigneProvider` et le bandeau unique. Commentaires normatifs : « une seule source pour tout le produit », « un seul composant, calibré une fois, jamais réécrit par écran ». |
| `lib/core/admin/service_programme.dart` | `StatutVersionProgramme` (brouillon / publiée / archivée), `VersionProgramme`. **Le patron `ResourceVersion` déjà écrit**, appliqué au curriculum. |
| `supabase/migrations/0020_programme_pedagogique.sql` | `programme_versions` / `programme_niveaux` : publication irréversible imposée en base, clonage par `creer_version_programme()`. |
| `docs/produit/bibliotheque-contenu.md` | **Cahier des charges opérateur déjà écrit** pour ce domaine. Non protégé. À confronter à la spec avant d'en rédiger un nouveau. |

### Ce qui manque

- Aucune notion de ressource générique : ni `LibraryResource`, ni enum de type, ni table. Tout le contenu est codé en dur autour du Coran.
- Aucun champ du manifeste §6.4 n'existe nulle part, ni aucune des dix `capabilities`.
- Aucune table de ressource / version / artefact en base (`0001` à `0024` vérifiées).
- Aucun bucket Storage pour supports ou couvertures. Seuls `kyc` et `avatars` (0004, lignes 992-1060).
- Aucun renderer PDF ni Markdown dans `pubspec.yaml`. `PDFResource` et `StructuredTextResource` sont des manques **totaux** côté rendu.
- Aucune couverture de ressource, aucun générateur de couverture, aucun champ `cover_asset`.
- Aucun état offline **par ressource**. `CacheMediaFichiers` tient ses clés dans un `Set` **en mémoire** : rien ne survit à un redémarrage. La table Drift `PagesMushafConsultees` est **générée mais morte** — aucun code de `lib/` ne l'écrit ni ne la lit.
- `FilePicker.saveFile()` est disponible dans la dépendance mais **n'est appelé nulle part**.
- Aucune assignation de ressource à un groupe.
- `PreferencesLocales` est **explicitement en mémoire seulement** (y compris `economieDonnees` et `lectureGrande`).

---

## 3. Coran : corpus, structure, rendu actuel

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `supabase/migrations/0007_coran_structure_position_presence.sql` | `mushaf`, `sourate`, `juz`, `page_mushaf`, `verset`, `student_reading_position`, RLS complète. Index `verset_page_idx (mushaf_id, page_numero, ligne)` **déjà prévu pour un rendu par ligne**. |
| `supabase/migrations/0013_corpus_coranique.sql` | Import Tanzil Uthmani v1.1 (CC-BY 3.0, 1,49 Mo). Bloc `do $$` final qui **fait échouer la migration** si le compte n'est pas 114 / 30 / 604 / 6236, plus contrôle sourate par sourate et « aucune page vide ». |
| `lib/core/coran/vue_lecteur.dart` | **NON protégé.** Fonction pure `VueLecteur.depuis()` : 4 états (`chargement` / `lecture` / `corpusAbsent` / `indisponible`), découpage en `SectionSourate`, bornes de navigation, décision de reprise. La brique la plus réutilisable du domaine. |
| `lib/core/widgets/rosace_verset.dart` | **NON protégé.** Rosace dessinée + `enChiffresArabes(int)`. Résout déjà le piège U+06DD (glyphe absent = carré vide). |
| `lib/core/widgets/page_immersive.dart` | **NON protégé.** `RegistreImmersif.lecture`. Écrite pour le Coran : « le Coran ne se traite jamais comme une carte entourée de contrôles ». |
| `lib/core/coran/service_coran.dart` **[P]** | `codeMushafReference = 'madina-hafs-604'`, `pagesMushafMedine = 604`, `Sourate`, `VersetCoran`, `PageCoran`, `PositionLecture`, `ServiceCoran`, providers. **Lecture et adaptation seulement.** |
| `lib/features/coran/coran_page.dart` | Écran ELV-04 actuel. À conserver comme leçons : enregistrement différé de position (3 s), « ne rien écrire tant que l'élève n'a pas navigué », bandeau qui **propose** la reprise sans téléporter, attribution de licence dans le flux. |
| `docs/architecture/etape-5-salle-coran-presence.md` | **NON protégé.** Spécification d'origine. §3.1 fixe Hafs / Mushaf Al-Madinah / 604 pages / 15 lignes. Lignes 89-93 : police glyphe-par-page **question ouverte**. Ligne 146 : état partagé de séance décrit, jamais codé. |

### Ce qui manque

Voir `TEACHING_CORE_BASELINE.md` §6.1 pour les trois bloquants. En complément :

- Aucune notion de `pageSide` / `spread` / double page. Le rendu actuel est un `PageView.builder` page unique RTL sans aucun breakpoint.
- Aucun mode verset reflowable distinct. Un seul rendu, zoom = multiplicateur de `fontSize` (`26 * zoom`, borné 0.8-2.4 à l'écran alors que la base et `PositionLecture` bornent 0.5-4.0).
- Aucune navigation par sourate, par juz ni par ayah. Aucune recherche : **zéro index texte** dans `supabase/migrations` (pas de `tsvector`, pas de `pg_trgm`, pas de colonne normalisée sans diacritiques).
- Aucune position de groupe / état partagé : zéro occurrence de `shared_content`, `etat_partage`, `session_shared`, `page_partagee` dans tout le worktree.
- Aucun pont Coran ↔ Classe Live : `salle_page.dart` documente explicitement qu'aucun document n'est partagé.
- Aucun golden test Coran dans la baseline. `test/coran/` ne contient que `vue_lecteur_test.dart`.

---

## 4. LiveKit, salle, vidéo, session persistante

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `lib/core/video/video_session_provider.dart` **[P]** | Contrat abstrait sans SDK : `VideoSessionProvider`, `CapacitesSalle`, `AccesSalle`, `EtatSalle` (6), `QualiteLien` (5), `ParticipantSalle`. **Le contrat à étendre par adapter, jamais à dupliquer.** |
| `lib/core/video/livekit_session_provider.dart` **[P]** | Seule implémentation. `adaptiveStream` + `dynacast`, 16 `RoomEvent`, dégradation automatique de la caméra sur qualité médiocre puis restauration. `moteurSalleProvider` = Provider **racine** (ligne 418). Invariant déjà codé ligne ~124 : **rien ne publie à l'entrée**, pour les 4 rôles. |
| `lib/core/video/service_video.dart` | **NON protégé.** `acces(seanceId)` → fonction Edge ; `observerEnControle` → rpc `rejoindre_observation` ; `assisterEnTuteur` → rpc `assister_seance` ; `annoncerSortie` → rpc `quitter_salle`. `MotifRefusSalle`, `EchecSalle`. **Point d'extension Dart privilégié.** |
| `lib/core/video/pre_vol.dart` **[P]** | `ServicePreVolLiveKit`, `ResultatPreVol`, règle `peutEntrer = micro présent et permission accordée`. **Le preflight de la spec §9.5 existe déjà.** |
| `lib/core/router/billet_salle.dart` | **NON protégé.** `BilletSalle {sessionId, emisA}` passé par `GoRouterState.extra`, jamais par l'URL (ADR-005). Toute entrée en Classe Live passe par là. |
| `lib/core/router/redirection.dart` | **NON protégé.** `deciderRedirection()` refuse `/salle` sans billet présentable (ligne 93). |
| `supabase/functions/create-room-token/index.ts` | Vérifie la config **avant** l'auth, lit le `profile_id` dans le JWT (jamais dans le corps), délègue **toute** décision à `autoriser_jeton_video`. Aucune capacité décidée en TypeScript. |
| `supabase/functions/_shared/livekit.ts` | Seul fichier autorisé à importer `livekit-server-sdk`. `signerJeton()` pose `metadata = {"role": ...}` (ligne 86) et **`canPublishData` déjà accordé à l'enseignant** (ligne 103). |
| `docs/parallel-reports/02-livekit-audit.md` | Audit du 14/09/2026, 308 lignes. **À relire avant de produire un troisième audit LiveKit.** Verdict : code cohérent, salle LiveKit réelle **non prouvée**, Egress/R2 inexistant. |
| `test/features/salle_test.dart` **[P]** | 25 cas avec faux moteur / faux service vidéo / faux pré-vol injectés par override (lignes 72-74). **Le patron exact à reproduire** pour tester une Classe Live sans SDK. |

### Ce qui manque

- Zéro canal de données Flutter (voir BASELINE §6.7). Aucune séparation *reliable* / *lossy*.
- Session persistante : voir BASELINE §6.8. Aucune barre compacte « Cours en cours ». Aucun `WidgetsBindingObserver`, aucun `AppLifecycleState` dans le domaine vidéo.
- Aucun `SharedContentState` persisté : un late joiner ne peut récupérer l'état que par les messages realtime, ce que la spec interdit (ligne 1200).
- Layout **vidéo-dominant** (`salle_page.dart:530-581`), pas support-dominant. Aucun concept de support actif, aucun Teaching Dock, aucun port d'insertion.
- `VueSalle._dominant()` et `voitLesParticipants` sont pensés pour une séance à 2 (ADR-004) : inadaptés à un groupe de 5/6.
- Aucune action de roster enseignant, aucun nudge ciblé.
- Egress / enregistrement : `session_recordings` est une table de métadonnées **sans producteur**. Aucun `startEgress`, aucune config R2.

---

## 5. Présence, attendance, fenêtre de connexion

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `lib/core/presence/service_presence.dart` | **NON protégé.** `EtatPresence` (14 + `inconnu`), `PresenceParticipant`, `presenceSeanceProvider` (`Timer.periodic` annulable, `cadencePresence = 20 s`). Invariant **J3** : erreur → `null` → `inconnu`, jamais `absente`. |
| `lib/core/presence/vue_presence.dart` | **NON protégé.** `VuePresence.depuis(ligne, maintenant)`, `tableauDePresence()`, `maPresence()`. **C'est ici que se joue le risque T-20** (voir BASELINE §6.4). |
| `lib/core/widgets/ligne_presence.dart` | **NON protégé.** `LignePresence.libelle(EtatPresence)` et `.contexte(VuePresence)` en statiques. Porte **J7** (jamais une couleur seule) et J3 par construction. |
| `lib/features/presence_correction/` | **NON protégé.** `PresenceCorrectionAdaptateur` (interface), page complète avec motif obligatoire, garde hors-ligne, `Semantics liveRegion`. **L'écran est écrit, l'adaptateur serveur n'existe pas**, la page n'est enregistrée dans aucune route. |
| `supabase/tests/scenarios_n4.sql` | Harnais SQL de la présence, à rejouer avant toute retouche de `etat_presence()`. |
| `supabase/migrations/0011_presence_bornee.sql` | Contient la leçon : une vue sans `security_invoker` ni filtre d'appelant expose **toute** la plateforme. |
| `supabase/migrations/0014_acces_agent.sql` | **Définition courante** de `presence_seance_v` (lignes 979-1020). Piège : qui lit seulement 0011 croit connaître la vue et se trompe. |

### Ce qui manque

Voir BASELINE §6.3 et §6.4. En complément :

- Aucune consolidation de fin de séance : `confirmation_en_attente` est rendu quand la séance est close mais **rien** ne le fait passer à `finalisee`.
- Aucun lien présence ↔ groupe.
- Pas de distinction entre passage en arrière-plan et vraie déconnexion. `session_events.source` prévoit pourtant la valeur `'network'`, mais **rien ne l'émet**.
- Aucun écran d'administration des trois seuils `app_config` de présence.

---

## 6. Roster enseignant, projection pédagogique, confidentialité PII

### Le constat de sécurité, vérifié

**Aucune PII famille ne fuit aujourd'hui vers l'enseignant, et c'est démontrable.**

- Les tables `profiles` / `student_profiles` n'ont **ni téléphone, ni email, ni adresse, ni date de naissance** (grep sur toutes les migrations hors 0013 : zéro occurrence). La seule PII de `profiles` est `last_name` + `household_id`.
- La RLS de `profiles` (0001:704-715) n'accorde **aucune policy select à l'enseignant** : admin, soi-même, et foyer pour guardian/accountant/controller.
- L'enseignant n'atteint donc les personnes que par des vues `security_barrier` **sans** `security_invoker` (exécutées en owner, auto-bornées par `where s.teacher_id = auth.uid()`) : `teacher_roster_v`, `mes_seances_v`, `mes_affectations_v`, `eleves_en_attente_v`, `presence_seance_v`, `session_peers_v`. **Toutes ne portent que `first_name` + `immutable_id`.**
- Les RPC qui rendent `student_nom` (`groupe_detail`, `progression_admin`, `evaluations_admin`, diagnostics, qualité) sont **toutes gardées par `app_role() = 'admin'` dans leur corps**.
- `wallets` / `payouts` (0001:1100-1142) : admin/comptable et lecture foyer. **Aucune branche enseignant.**

### Existe et est réutilisable

| Chemin | Rôle |
|---|---|
| `teacher_roster_v` (vue) | `session_id`, `student_id`, `first_name`, `immutable_id`, `level`, `riwaya`. **`last_name` a été RETIRÉ volontairement en 0005** (défaut 3.8, ADR-008). **Aucun consommateur Dart aujourd'hui** : la seule trace dans `lib/` est un commentaire de `lib/core/widgets/avatar_tile.dart:19`. |
| `lib/core/suivi/service_suivi.dart` | **NON protégé.** `seances()` sur `mes_seances_v`, `presences()` sur `presence_seance_v`, plafond 200, tri explicite, `null` (indisponible) jamais liste vide trompeuse. Sa doc annonce déjà que le même service sert un autre rôle sans une ligne de plus. |
| `lib/features/suivi_foyer/vue_suivi_foyer.dart` | **NON protégé.** `SortDuCours` (annulé / nonTenu / tenu), `LigneSuivi`. Règle métier déjà tranchée : **le sort du cours prime sur l'état de la personne**. |
| `lib/core/matching/service_matching.dart` | **NON protégé.** `EleveEnAttente` lu depuis `eleves_en_attente_v` : seul endroit où du code enseignant lit déjà `level` et `interface_mode`. |
| `lib/core/profil/service_profil_enseignant.dart` | **NON protégé.** `ProfilEnseignant`, contrat en lecture seule, sans finance. |

### Ce qui manque

- `teacher_roster_v` n'a **aucun consommateur Dart**.
- L'enseignant n'a **aucun droit de lecture** sur `student_reading_position` (policies 0007:351-370 : élève, foyer guardian/admin, admin). `resume_points` est donc inatteignable sans migration.
- `curriculum_path`, `current_unit`, `active_goals`, `current_assignments` n'ont **aucune projection enseignant** : tout le domaine Pédagogie (0020-0024) est admin-only.
- `lesson_reports.content` est un `jsonb` libre, **sans** séparation `internal_details` / `family_summary`, et **n'est lisible que par son auteur** (0001:1074) : un enseignant ne peut pas reprendre le suivi d'un prédécesseur.
- `groupe_membres` ne porte que `student_id` : l'enseignant lit ses membres (0019:323) mais **ne peut pas les nommer**, la jointure vers `profiles` étant fermée par la RLS.
- **Aucune colonne photo/avatar sur `teacher_profiles`** (0001:90-98), alors que la spec rend la photo enseignant obligatoire. `student_profiles` a `avatar_storage_key`, `teacher_profiles` n'a rien.
- `groupes` n'a **pas de colonne couleur** d'identification.
- Aucune table `LearningAssignment`, `SessionFeedback` ni `StudentConcern`.
- L'enseignant n'a que **trois routes** dans la baseline : `/enseignant/journee`, `/enseignant/creneaux`, `/enseignant/profil`.

> Constat factuel pré-existant, hors mission : la policy `lesson_reports_teacher_write` (0001:1064-1069)
> ne vérifie pas que `session_id` appartient à l'enseignant, seulement `author_profile_id = auth.uid()`.
> **Ne pas corriger** en phase parallèle. À signaler dans `TC_CONTRACT_REQUEST_H.md`.

---

## 7. Tuteur observateur, Admin, Contrôleur, audit

### Existe et est réutilisable — beaucoup plus que prévu

| Chemin | Rôle |
|---|---|
| `supabase/migrations/0012_observation_controleur.sql` | **Cœur du domaine.** `rejoindre_observation(p_session_id)` (contrôleur seul, fenêtre `started_at`..`ended_at+15min`, insert idempotent, audit `controller_observation_started`) et sa jumelle `assister_seance(p_session_id)` (tuteur, borné au foyer, rôle `guardian_observer`, **pas** d'écriture audit — choix assumé). `est_observateur_masque()`. Exemption des deux rôles dans `guard_session_participant_cap()` **et** `guard_session_overlap()`. Invisibilité fermée sur **quatre** surfaces. |
| `supabase/migrations/0009_journal_audit.sql` | `journal_audit()` en keyset sur `(created_at, id)`, `journal_audit_filtres()`, `verifier_chaine_audit()`. Réservé `admin`. |
| `lib/core/journal/service_journal.dart` + `lib/features/admin_journal/journal_page.dart` | **NON protégés.** ADM-04. Le vocabulaire des filtres vient de la base : **un nouveau type d'événement d'observation apparaîtra automatiquement**, sans toucher au Dart. |
| `lib/features/controleur/planning_page.dart` + `vue_planning.dart` | **NON protégés.** CTR-01 : bandeau permanent « visite journalisée », trois états calculés sur les **heures** et non sur `sessions.status`, colonnes heure locale **et** UTC, bouton Observer uniquement sur une ligne en cours. |
| `lib/core/agent/session_agent.dart` | **NON protégé.** `PorteurSessionAgent` : jeton en mémoire seule, **aucune prolongation possible côté client**, rafraîchissement forcé par la base avec 60 s de marge. **Le patron exact du budget d'observation tuteur.** |
| `supabase/migrations/0014_acces_agent.sql` | `jetons_agent` : **seul exemple existant** de durée plafonnée par contrainte `CHECK` et de compteur d'usage côté serveur. Modèle de référence pour « privilège accordé à la REQUÊTE, pas au COMPTE ». |
| `lib/features/accueil_famille/accueil_famille_page.dart` | **NON protégé.** `_assister(seanceId)` (~ligne 178) : seul point d'entrée du tuteur observateur aujourd'hui. |

### Ce qui manque

Voir BASELINE §6.6. En complément :

- Aucune entrée **Admin** dans une séance, aucun choix visible/incognito, aucune identité institutionnelle « Administration Rewayah ».
- Aucune annonce enseignant « Tuteur d'Amina observe », aucun indicateur de temps restant, aucun compte à rebours côté tuteur.
- Aucun module `Réglages > Classe & observation` : `ongletsConfiguration()` note explicitement que « Classe en ligne » reste à construire.
- Aucune vue admin agrégeant les visites (date, nombre, durée exacte, `policy_version`).

---

## 8. Socle partagé — router, thème, DI, auth, i18n, widgets

### Points structurants à connaître avant d'écrire

**Routage.** Un seul `GoRouter`, dans `lib/core/router/app_router.dart` (765 lignes), chemins en constantes
dans `lib/core/router/routes.dart` (276 lignes), gardes dans la fonction **pure**
`lib/core/router/redirection.dart` (117 lignes). `tool/verifier_jetons.dart` (lignes 261-268) fait échouer
la CI si un second fichier de `lib/` construit un `GoRouter`, **et** si `app_router.dart` n'en construit
plus aucun. Les deux premiers fichiers sont **[P]**.

**Injection de dépendances.** Il n'existe **aucun** composition root et **aucun** provider central de
`SupabaseClient`, et c'est délibéré. Le pattern réel, répété dans 31 fichiers :

```
abstract class ServiceX { ... }
class ServiceXSupabase implements ServiceX { ServiceXSupabase(this._client); ... }
final Provider<ServiceX> serviceXProvider =
    Provider<ServiceX>((ref) => ServiceXSupabase(Supabase.instance.client));
```

déclaré **dans le même fichier que le service**. `lib/main.dart` ne pose aucun override sauf pour la
session agent. **Ne pas introduire de root DI** : ce serait un doublon architectural qui obligerait à
toucher les 31 fichiers existants.

**i18n — le point de collision n°1.** Le pipeline slang est **mono-fichier** : `slang.yaml` n'active
**pas** `namespaces` (vérifié). Source unique `assets/i18n/fr.i18n.json` (68 Ko, 617 clés, 34 espaces de
noms racine) → sortie unique `lib/core/i18n/strings_fr.g.dart` (244 Ko, **versionnée**). Les trois fichiers
sont déjà modifiés par le chantier enseignant. `build.yaml` désactive le builder slang : l'ordre imposé
est `dart run slang` **puis** `dart run build_runner build --delete-conflicting-outputs`, et la CI refuse
tout diff après régénération. → **Mécanisme d'évitement imposé : décision D-03.**

**Thème et design system.** Dix fichiers sous `lib/core/theme/`, `AppIcons` (~46 icônes, fichier unique),
38 widgets partagés sous `lib/core/widgets/`. `lib/CLAUDE.md` cite dix composants déclarés **points
d'entrée uniques** : `Pressable`, `BentoTile`, `AvatarTile`, `AudioLabel`, `PermanentNotice`, `PinPad`,
`EmptyState`, `OfflineBanner`, `ChoiceCardGroup`, `ActionPrincipale`.

**Responsive.** `lib/core/theme/app_gabarit.dart` : `ChromeNavigation` / `Gabarit` / `ClasseLargeur`,
seuils **600 / 840 / 1200**, `largeurRail = 80`, `largeurBarreLaterale = 256`, `AppGabarit.de(context)`.
**Seul mécanisme responsive du produit.**

**Navigation.** `lib/core/widgets/nav_shell.dart` **[P]** : trois formes (barre basse < 600, rail 600-1199,
barre latérale ≥ 1200) alimentées par **une seule liste**, avec un **plafond dur de 4 destinations tenu par
assertion**. L'enseignant en a déjà 4. Ajouter une destination Teaching Core à la barre enseignant exige un
**arbitrage produit**, pas un patch.

**Session et permissions.** `lib/core/session/session_state.dart` : un widget lit une **capacité**, jamais
un rôle. `peutVoirDirection` est câblé **en dur à `false`** avec un commentaire explicite : ni `AppRole`
(plat, 6 valeurs) ni le JWT ne portent de permission plus fine. **Toute capacité Teaching Core qui ne
serait pas un rôle entier n'a aujourd'hui aucun support.**

**Arabe.** `assets/i18n/ar.i18n.json` fait **974 octets** et ne contient qu'un espace de noms (`eleve`).
`fallback_strategy: base_locale` fait qu'une clé absente retombe sur le français **sans erreur** :
l'arabe n'est pas traduit, il est absent et invisible.

**Vocabulaire.** Le socle entier nomme « enfant » le concept que la spec veut appeler « Interface guidée » :
`InterfaceMode.enfant` (valeur SQL `'child'`), `AppMetriques.estEnfant`, `AppTypography.enfant`,
`AppTypography.facteurEnfant`, `AppTouchTarget.enfant`. → **Arbitrage : décision D-07.**

---

## 9. DOUBLONS À NE PAS CRÉER

> Chaque ligne est un risque remonté par une cartographie. **La colonne « Consigne » est impérative.**
> Un agent qui crée l'un de ces doublons sera BLOCKER au contrôle pré-merge.

### 9.1 Groupes, planning et temps

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| Un modèle de Groupe (entité, membres, capacité, enseignant assigné) | `supabase/migrations/0017` + `0019` ; `lib/core/admin/service_groupes.dart` | **ÉTENDRE, jamais recréer.** Ajouter des colonnes (fuseau exposé, couleur, niveau) et des RPC de lecture par rôle — via CONTRACT_REQUEST. Réutiliser `GroupeAdmin` comme base du `GroupSummaryVM` admin. |
| Le plafond de membres (5 enfants / 6 adultes) | `groupes.seuil_max` + trigger `guard_groupe_membre_cap()` + cohérence dans `modifier_groupe()` | **Ne jamais réimplémenter un plafond côté Dart.** `GroupSummaryVM` lit `nombreMembres` / `seuilMax`. La spec est explicite : « ne jamais hardcoder 5 ». |
| Le créneau hebdomadaire récurrent (jour ISO + heure locale + fuseau IANA) | `Creneau` dans `service_planning.dart` ; colonnes `weekday`/`hour_local`/`timezone_iana` sur `groupes`, `teacher_student_assignments`, `weekly_availability` | **Réutiliser `Creneau`.** Ne pas introduire une seconde représentation (ni RRULE, ni cron, ni `recurrence_rules` qui est un vestige mort). |
| La conversion motif IANA → occurrence absolue en UTC | `public.instant_creneau()` (0005, corrigée 0006) | **Appeler la fonction existante.** La recoder rejouerait le bug de 0006 : semaine ancrée dans le fuseau de la ligne = 7 jours d'écart entre Paris et Conakry. |
| Le fuseau de l'utilisateur | `public.mon_fuseau()` + `monFuseauProvider` | **Réutiliser.** N'ajouter que le fuseau de **référence du groupe**, qui lui manque réellement. |
| Le countdown avant la séance | `Seance.avantDebut()` ; `_compteARebours()` + `Timer.periodic(1 min)` dans `accueil_eleve_page.dart` ; second `Timer.periodic(1 min)` dans `journee_page.dart` **[P]** | Il y a **déjà deux** implémentations. `SessionClockVM` doit les **UNIFIER**, pas devenir la troisième. Le côté `journee_page.dart` est PROTECTED : à négocier avec Agent Z. |
| La fenêtre d'ouverture de la salle | `autoriser_jeton_video()` −10/+15 ; `seuilOuvertureSalle` ; `graceApresFin` | **Ne pas poser une quatrième constante.** Toute valeur cliente doit rester alignée sur la base, sinon on propose un bouton que le serveur refuse. |
| La grille hebdomadaire 7 jours × heures | `lib/features/disponibilites/grille_semaine.dart` | **Réutiliser le composant.** Ne pas redessiner une grille. |
| Un écran de planning listant les séances | `lib/features/controleur/planning_page.dart` + `vue_planning.dart` + `service_controle.dart` | Ne pas dupliquer CTR-01. Réutiliser `service_controle` / `mes_seances_v`. |
| La machine d'états d'une séance | `etatAccueilEleve()` côté élève ; `EtatLignePlanning` côté contrôle | Deux machines coexistent déjà pour deux besoins. La machine d'états UX de la spec §5.1 se pose **une fois** et se fait consommer par les deux. |

### 9.2 Bibliothèque, cache et versions

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| Une abstraction de cache de fichiers | `lib/core/cache/media/cache_media.dart` | **Étendre `CacheMedia`**, pas créer un `ServiceTelechargement` parallèle. Il manque seulement une méthode d'obtention et une **persistance des clés** (aujourd'hui un `Set` en mémoire). |
| Une file d'attente offline idempotente avec rejeu | `lib/core/cache/sync/file_rapports.dart` | Reprendre le patron tel quel. **Ne pas réinventer un second mécanisme de retry.** |
| Un index local « page consultée → clé de cache » | Table Drift `PagesMushafConsultees` | Elle existe, est générée, et est **MORTE** : aucun code de `lib/` ne l'écrit ni ne la lit. Et son modèle (page-image) est incompatible avec un corpus structuré. **Ne pas construire dessus sans la redéfinir, ne pas en créer une cinquième à côté** — `AppDatabase` exige une justification de spec pour toute table supplémentaire. |
| Un versionnement de contenu immuable (`ResourceVersion`) | `programme_versions` / `programme_niveaux` (0020) + `StatutVersionProgramme` | **Calquer**, ne pas inventer un second vocabulaire de statuts. Le triplet brouillon/publiée/archivée, la publication irréversible en base et la RPC de clonage sont déjà écrits et testés. |
| Un sélecteur de fichier et un « Enregistrer une copie » | `lib/core/dossier/selecteur_fichier.dart` (`file_picker 12.2.0` expose déjà `saveFile()` et `getDirectoryPath()`) | **Ajouter une méthode à CETTE interface.** Aucune nouvelle dépendance n'est requise pour la règle §6.5. N'ajouter ni `share_plus` ni `path_provider`. |
| Un état / bandeau hors ligne | `service_reseau.dart` + `offline_banner.dart` | La Bibliothèque **lit `horsLigneProvider`** et n'ouvre jamais son propre abonnement `Connectivity`. L'état **par ressource** (téléchargé / en cache / à télécharger) est autre chose et n'existe pas. |
| Un point d'entrée Drift / provider de base locale | `baseLocaleProvider` (`profils_locaux.dart:100`) | Existe et est déjà surchargé dans les tests. **Ne pas en créer un second.** |
| Un upload / une URL signée Storage | `service_avatar.dart` (upload 140, `urlSignee` 148) ; `service_dossier.dart` (upload 142) | Réutiliser le patron. **On persiste la CLÉ, jamais l'URL signée**, qui expire. |
| Un cahier des charges de bibliothèque de contenu | `docs/produit/bibliotheque-contenu.md` | **Le confronter à la spec avant d'en rédiger un nouveau.** |

### 9.3 Coran

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| Un modèle de données Coran (sourate / ayah / page) | `0007` + `0013`, peuplés et vérifiés (114/30/604/6236) | **Interdire toute nouvelle table de corpus.** Le Teaching Core **DOIT** lire l'existant. Si `verset.ligne` doit être peuplé, c'est un CONTRACT_REQUEST, pas une migration. |
| Un second service de lecture du Coran | `lib/core/coran/service_coran.dart` **[P]** | **ÉTENDRE via adaptateur**, jamais dupliquer. Le fichier est PROTECTED : rédiger `TC_CONTRACT_REQUEST_C.md` et attendre. |
| De nouvelles constantes 604 / code d'édition | `codeMushafReference = 'madina-hafs-604'`, `pagesMushafMedine = 604` | Réutiliser. **Ne jamais coder un uuid de mushaf en dur** : l'id est généré par la base et diffère par environnement. |
| Une machine à états d'affichage du lecteur | `lib/core/coran/vue_lecteur.dart` (`EtatLecteur`, `VueLecteur.depuis`) | **Réutiliser, il n'est PAS protégé.** Il distingue déjà `indisponible` (réseau/refus) de `corpusAbsent` (migration manquante), et gère « deux sourates sur une même page ». Le moteur Mushaf se pose **au-dessus**. |
| Un widget de numéro de verset | `lib/core/widgets/rosace_verset.dart` | **Réutiliser tel quel.** Redessiner referait le piège du carré vide (U+06DD absent de certaines polices). |
| Une route / entrée de navigation vers le Coran | `Routes.eleveCoran = '/eleve/coran'`, montée dans `app_router.dart`, atteinte depuis `_BlocCoran` de `accueil_eleve_page.dart` | **Ne pas créer de seconde route.** |
| Une sauvegarde de position de lecture | `student_reading_position` + `PositionLecture` + bandeau `_BandeReprise` | Réutiliser. **Ne surtout pas ajouter une écriture de position pilotée par l'enseignant** : aucune policy ne l'autorise, c'est l'invariant J2. La position de **GROUPE** est autre chose et sera un stockage distinct. |
| Une coque d'écran immersif pour la lecture | `lib/core/widgets/page_immersive.dart` | Réutiliser : écrite pour le Coran, porte déjà « contenu avant chrome ». |

### 9.4 LiveKit, salle, présence

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| Un second provider / moteur WebRTC ou LiveKit | `video_session_provider.dart` + `livekit_session_provider.dart` + `moteurSalleProvider` | **Interdit** par la spec (lignes 684, 1203, 1539) et par ADR-001. Le Teaching Core construit des **ADAPTERS au-dessus** de `VideoSessionProvider`, jamais une seconde `Room`. |
| Un système de présence / roster concurrent | `presence_seance_v` + `service_presence.dart` + `ligne_presence.dart` + la fusion inscrits/connectés déjà écrite dans `salle_page.dart:760` | Réutiliser `presenceSeanceProvider`. **Ne jamais bâtir un roster sur la seule liste LiveKit** : qui n'est jamais arrivé n'a aucune piste, et c'est justement de lui que l'enseignant doit savoir quelque chose. |
| Un pré-vol / preflight matériel | `lib/core/video/pre_vol.dart` | Existe et est injectable par override. **Au plus, ajouter un écran qui l'affiche.** |
| Une mesure maison de la qualité réseau | `QualiteLien` + `Stream<QualiteLien>` + `_degrader()` + `VueSalle.lienADire` | L'état réseau du header **lit ce flux**. Aucune mesure de bande passante maison. |
| Une politique micro/caméra OFF à l'entrée | `livekit_session_provider.dart` lignes 113-125 ; `canPublishSources` côté serveur | Spec §9.3 **déjà satisfaite**. Ne pas re-coder un mute UI : ce serait un second endroit qui pourrait diverger. |
| Une émission de jeton, un calcul de capacités, un rôle de salle | `autoriser_jeton_video` + `create-room-token` + `signerJeton` + `CapacitesSalle` + `RoleSalle` | **Aucune capacité ne se calcule côté client ni en TypeScript.** Le Teaching Core lit `acces.capacites` et n'invente rien. |
| Une machine d'états d'entrée en salle | `lib/features/salle/vue_salle.dart` **[P]** (`PhaseSalle` 6, `CauseImpasse` 4, 23 cas de test) | Réutiliser `VueSalle` comme source de vérité d'état. Un écran Classe Live différent peut la **consommer** sans la recopier. |
| Une route de salle paramétrée ou partageable | `billet_salle.dart` + `redirection.dart:93` + `Routes.salle` | ADR-005 : **aucune URL de salle mémorisable.** |
| Une sortie volontaire distincte d'une déconnexion | `quitter_salle` (`source='user_action'`), appelée **AVANT** `_moteur.quitter()` (`salle_page.dart:195`), dédupliquée côté webhook (fenêtre 30 s) | **L'ordre annonce-puis-déconnexion est porteur d'information** : le recopier à l'identique dans tout nouveau bouton Quitter. |
| Un nouvel audit LiveKit | `docs/parallel-reports/02-livekit-audit.md` | Relire ce document **avant** d'en produire un troisième. |
| Une notion de metadata participant | `_shared/livekit.ts:86` `metadata={role}`, décodée par `_roleDe()` ligne 225 | Elle existe et **ne contient aucune PII**. Un champ supplémentaire touche le core **et** la fonction Edge : CONTRACT_REQUEST. |
| Une machine à états de présence / un nouveau service de présence | `etat_presence()` + `presence_state` (14) + `service_presence.dart` | Interdit par la spec (ligne 1204) **et** par l'invariant J4 du dépôt : 14 états, **ni un de plus**. |
| Un widget / une pastille d'état de présence | `ligne_presence.dart` | Un widget concurrent recasserait **J3 et J7** et ferait diverger les libellés. |
| Un écran de correction / d'excuse de présence | `lib/features/presence_correction/` + policies `spo_ecriture` (0007) | **NE PAS recréer.** Ce qui manque est uniquement l'implémentation de `PresenceCorrectionAdaptateur` et la RPC derrière. |
| Une boucle de rafraîchissement de présence | `presenceSeanceProvider` (`Timer.periodic` 20 s, annulable) | Réutiliser. Le commentaire du fichier documente un échec mesuré : une boucle `async*` + `Future.delayed` continuerait à tourner après la sortie de salle. |
| Un calcul de durée passée en salle | `VuePresence.depuis` (`RepereTemps`) + `LignePresence.contexte()` | **Étendre cette fonction pure**, pas en écrire une seconde. C'est exactement là qu'il faudra borner la durée à `max(entreLe, debutSeance)`. |

### 9.5 Roster, projection, observation, audit

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| `TeacherStudentProjection` côté serveur | Vue `teacher_roster_v` (0001:650, recréée 0005:705, 0014:868) | **NE PAS créer une vue neuve.** Elle porte déjà `first_name`, `immutable_id` (= `academy_id`), `level`, `riwaya` et est bornée à `teacher_id = auth.uid()`. Il faut lui **brancher enfin un service Dart**. |
| Une RPC de roster de groupe pour l'enseignant | `groupe_detail()` — **admin-only, rend `student_nom`** | **Ne jamais l'ouvrir à l'enseignant.** Créer la variante enseignant **sur le modèle de `teacher_roster_v`** : prénom + `immutable_id` + `level` + `riwaya`, jamais de nom. |
| Un cahier / des notes de séance | `lesson_reports` + `makharij_findings` (0001:221 et :233) | **Ne pas créer une table de notes.** Ce qui manque est (a) la séparation `internal_details` / `family_summary` dans `content`, (b) l'élargissement de la lecture au-delà du seul auteur. ⚠ Le chantier enseignant crée déjà `lib/features/cahier/` — **coordination obligatoire**. |
| Un historique de présence pour la fiche élève | `ServiceSuivi` + `VueSuiviFoyer` | Réutiliser tels quels. Reprendre **`SortDuCours`** : un cours non tenu ne doit pas s'afficher comme un élève absent. |
| Un flag « interface guidée » sur l'élève | `interface_mode` (`'child'`/`'standard'`) + `InterfaceMode` | **Ne pas ajouter de colonne.** C'est un changement de **libellé**, pas un nouveau champ (décision D-07). |
| Un mécanisme de masquage d'identité | `agent_identite_masquee()` appliqué colonne par colonne dans les 8 vues (0014:828-1039) ; `est_observateur_masque()` (0012:231) | Réutiliser **exactement** ce motif : le masquage se fait **dans la vue**, jamais dans Flutter. La spec l'exige (§3). ⚠ Dette nommée par 0016 : le motif est dupliqué à la main — **une surface oubliée est une fuite avec une bannière devant**. |
| Une nouvelle RPC d'entrée en observation | `rejoindre_observation()` et `assister_seance()` (0012) | **ÉTENDRE ces deux fonctions, jamais en créer une troisième.** Deux portes qui refuseraient des séances différentes finiraient par se contredire — c'est écrit dans l'en-tête de 0012. |
| Une nouvelle table de journal d'observation | `audit_logs` chaînée + `log_sensitive_access()` | **Distinguer deux besoins.** L'AUDIT (qui, quand, identité) va dans `audit_logs` — déjà chaîné, déjà lisible par ADM-04. La MESURE DU QUOTA (`visit_number`, `duration_seconds`, `policy_version`) a besoin d'une table dédiée requêtable : c'est `GuardianSessionVisit`, et lui n'existe pas. **Ne pas fabriquer un second journal chaîné.** |
| Un écran admin de consultation des visites | ADM-04 (`journal_page.dart` + `service_journal.dart`) | Ajouter les types d'événement **en base** : ils apparaissent automatiquement dans les filtres. Un écran « historique des observations » séparé serait un second journal. |
| Un système de configuration / politique parallèle | `app_config` + `rule_overrides` + `regle_brute()` / `regle_effective()` | Les défauts Académie appartiennent à `app_config`. La surcharge **par groupe** n'a aucun équivalent : c'est la vraie nouveauté, et elle doit être lue par une **fonction unique** analogue à `regle_effective`, jamais recalculée à l'écran. |
| Un neuvième domaine admin | `lib/core/admin/admin_domaine.dart` — **gel d'architecture à 8 domaines, déclaré règle absolue** | Livrer le module de politique comme un **onglet** de `ongletsConfiguration()` (« Classe & observation »), jamais comme un domaine. Et ne pas l'ajouter à la liste avant qu'il ait une route réelle. |
| Une exemption de plafond pour les observateurs | 0012 sections 1 et 2 | **Déjà fait.** Si un rôle d'observation ADMIN est ajouté, il faut l'ajouter à **ces deux listes** — sinon l'admin sera refusé par un déclencheur écrit pour tout autre chose. |
| Un porteur de session bornée côté client | `lib/core/agent/session_agent.dart` | Copier ce patron pour le budget tuteur. Mais la spec §11.4 est catégorique : **la borne est SERVEUR**. Un compte à rebours Dart est un affichage, jamais l'application de la limite. |
| Un système de jetons pour l'observation de classe | `jetons_agent` (0014) | **Ne pas confondre** : `jetons_agent` sert aux AGENTS IA, pas à l'observation de classe. Ne ni l'étendre ni l'imiter pour le tuteur. En revanche ses **règles** sont le bon modèle. |

### 9.6 Socle partagé

| Ne jamais recréer | Existe déjà dans | Consigne |
|---|---|---|
| Un second `GoRouter` ou un routeur par feature | `app_router.dart`, règle appliquée par `tool/verifier_jetons.dart:261-268` | **Interdit.** Un agent expose `List<RouteBase> routesTc<X>()` dans son namespace — une **fonction qui retourne des routes**, jamais un `GoRouter`. Agent Z l'appelle. Voir décision D-04. |
| Un provider central de `SupabaseClient` / un composition root | Aucun, délibérément — 31 fichiers suivent le même pattern local | **Suivre le pattern à la lettre.** Ne pas introduire de root DI. |
| Un système de libellés local (constantes, map de chaînes) | slang | Interdit par `lib/CLAUDE.md` (aucune chaîne visible en dur). Voir le mécanisme imposé : décision D-03. |
| Une seconde coque de page ou un `Scaffold` nu | `page_shell.dart`, `page_parcours.dart`, `page_immersive.dart` | `PageImmersive` **est déjà** la coque plein cadre de la salle : la Classe Live la réutilise. |
| Une seconde barre de navigation | `nav_shell.dart` **[P]** (plafond 4, assertion) / `admin_shell.dart` (8 domaines) | Réutiliser. **Le plafond de 4 est un arbitrage produit, pas un patch.** |
| Une icône déclarée hors du catalogue | `lib/core/icons/app_icons.dart` (~46 icônes) | Refusé par la CI. Icônes déjà présentes et utiles : `coran`, `cahier`, `cours`, `pause`, `micro`/`microCoupe`, `camera`/`cameraCoupee`, `pedagogie`, `controleQualite`, `qr`, `appareil`, `suivi`, `chevron`, `ajouter`. Voir décision D-05. |
| De nouveaux jetons de design | `app_palette`, `app_radius`, `app_spacing`, `app_elevation`, `app_mouvement`, `app_typography` | Refusé par la CI et le thème global est READ-ONLY. **Composer avec l'existant.** Si un jeton manque vraiment : CONTRACT_REQUEST vers Agent Z. |
| Des faux / mocks dupliqués | `test/support/harnais.dart` **[P]** (~25 faux, 40,5 Ko) | Fichier PROTECTED et partagé. Chaque agent écrit ses faux dans `test/teaching_core/<agent>/faux/`. Voir décision D-06. |
| Un nouvel enum d'état de séance, de politique caméra ou de mode d'interface | `lib/core/domain/enums.dart` (525 lignes) | Réutiliser. Chaque enum porte sa `valeurSql` et un `depuisSql()` qui rend `null` sur valeur inconnue : le contrat avec la base est littéral et vérifiable. Un miroir parallèle ferait diverger le client et le SQL **en silence**. |
| Une seconde liste/tableau, pastille d'état, état vide, squelette | `data_collection.dart`, `status_pill.dart`, `empty_state.dart`, `skeleton.dart`, `section_header.dart`, `filter_pill.dart`, `menu_filtre.dart`, `menu_actions.dart`, `setting_row.dart`, `signal_row.dart`, `timeline_row.dart`, `stat_tile.dart`, `bento_tile.dart`, `schedule_option.dart`, `selecteur_niveau.dart`, `avatar_tile.dart`, `child_card.dart`, `marque_page.dart`, `app_card.dart`, `local_feedback.dart` | **38 widgets partagés existent.** Chaque agent **liste `lib/core/widgets/` avant** de créer un composant, et cite dans son rapport celui qu'il a réutilisé ou la raison pour laquelle aucun ne convenait. |
| Un catalogue de galerie par feature | `lib/features/_dev/galerie/catalogue_galerie.dart` (48,5 Ko) | **Fichier unique = point de collision.** Aucun agent n'y touche en phase parallèle ; l'inscription des composants se fait en un lot par Agent Z. |

---

## 10. MODÈLE DE DONNÉES EXISTANT

> Toutes ces tables, vues et fonctions sont **déjà en base**. Aucune n'est à recréer.
> `[admin]` = accès réservé à `app_role() = 'admin'` dans le corps de la fonction.

### 10.1 Groupes et planning

| Objet | Migration | Colonnes / signature clés | Note |
|---|---|---|---|
| `public.groupes` | 0017, durcie 0019 | `id`, `teacher_id`, `type_public` (enfant\|adulte), `seuil_max` smallint 1..6, `libelle`, `weekday` 1..7 ISO, `hour_local` 0..23, `timezone_iana` default `'Europe/Paris'`, `created_at`, `ended_at`, `ended_by`, `end_reason` | RLS active, **aucune policy d'écriture** : seules les RPC écrivent. `timezone_iana` **n'est jamais écrite ni exposée**. Pas de couleur, photo, niveau, capacité d'observation ni politique. |
| `public.groupe_membres` | 0017, durcie 0019 | `id`, `groupe_id`, `student_id`, `joined_at`, `left_at`, `left_by`, `left_reason` | Index unique partiel `groupe_membres_actif_uidx` : **un élève n'a qu'un seul groupe actif**. Plafond appliqué par le trigger. |
| `public.sessions` | 0001 (+ `prayer_pause_minutes` en 0005) | `id`, `teacher_id`, `started_at`, `ended_at`, `status`, `room`, `session_type` (`'standard'`\|`'child'`), `credit_amount_minor`, `currency`, `deleted_at` | **AUCUN `groupe_id`. AUCUN `join_opens_at`.** |
| `public.teacher_student_assignments` | 0005 | `teacher_id`, `student_id`, `weekday`, `hour_local`, `timezone_iana`, `ended_at`… | Modèle 1-à-1 d'avant le pivot. 0017 déclare explicitement que **les deux modèles coexistent** en attendant un lot dédié avec audit RLS. C'est **lui** qui alimente les sessions. |
| `public.weekly_availability` | 0005 | `profile_id`, `weekday`, `hour_local`, `timezone_iana`, unique `(profile_id, weekday, hour_local)` | Une seule table pour tuteur **et** enseignant, volontairement (ADR-017). |
| `public.recurrence_rules` / `public.availability_slots` | 0001 | — | **Vestiges. Zéro usage dans `lib/`.** Ne pas les prendre pour un moteur de récurrence existant. |
| `public.mon_fuseau()` | 0005 | → `text` : `coalesce(households.timezone, teacher_profiles.timezone_iana, 'Europe/Paris')` | Le fuseau de l'**utilisateur**. Aucun équivalent pour un **groupe**. |
| `public.instant_creneau(weekday, hour, tz, offset)` | 0005, **corrigée 0006** | → `timestamptz` | **LE** convertisseur motif IANA → instant UTC. Déjà correct sur les changements d'heure. |
| `public.materialiser_seances(p_assignment_id uuid)` | 0005 | → `int` ; horizon `matching_horizon_weeks` (4) ; insert `sessions` + `session_participants` | **Le seul matérialisateur.** Signature basée sur une affectation 1-à-1. `grant execute` limité à `service_role`. |
| `public.mes_seances_v` | 0005, **redéfinie 0014** | `session_id`, `started_at`, `ended_at`, `status`, `session_type`, `prayer_pause_minutes`, `student_id`/`first_name`/`immutable_id`, `teacher_id`/… | Vue **unique** partagée par TUT-01, ELV-02, ENS-02, CTR-01. `security_barrier`. **Une ligne PAR ÉLÈVE** : un groupe de 5 y apparaît 5 fois. |
| `public.mes_affectations_v` | 0005, redéfinie 0014 | `id`, `teacher_id`, `student_id`, `weekday`, `hour_local`, `timezone_iana`… | Aucune vue équivalente pour l'appartenance à un groupe. |
| `groupes_admin()` / `groupe_detail(uuid)` | 0017, **courante 0019** | voir migration | `[admin]` + `app_account_valid()`. **Ne retournent NI `timezone_iana` NI prochaine occurrence.** `groupe_detail` rend `student_nom`. |
| `progression_admin()` | 0022 | expose `groupe_id` et `groupe_libelle` via left join | **Précédent de jointure élève → groupe déjà en place.** |

### 10.2 Coran

| Objet | Migration | Note |
|---|---|---|
| `mushaf` | 0007:32 | `code` unique, `riwaya` default `'hafs'`, `nombre_pages`. Une seule ligne attendue : `'madina-hafs-604'`. Le code Dart résout l'édition **par CODE, jamais par uuid** (il diffère par environnement). |
| `sourate` | 0007:44 | `numero` 1-114, `nom_arabe`, `nom_translittere`, `lieu_revelation`, `nombre_versets`. Référentiel non versionné. |
| `juz` | 0007:52 | `numero` 1-30, `sourate_depart`, `verset_depart`. **Ne porte ni page ni borne de fin.** |
| `page_mushaf` | 0007:58 | PK `(mushaf_id, numero)`, `juz_numero`. La pagination canonique. |
| `verset` | 0007:69 | `id`, `mushaf_id`, `sourate_numero`, `numero`, `texte`, `page_numero` **NOT NULL**, **`ligne` NULLABLE** ; unique `(mushaf_id, sourate_numero, numero)` ; index `verset_page_idx (mushaf_id, page_numero, ligne)` | **`ligne` est NULL sur les 6236 lignes.** Aucun identifiant de fichier (invariant J6). Granularité = le verset ; **la table `mot` n'existe pas**. |
| `student_reading_position` | 0007:98 | PK `(student_profile_id, mushaf_id)`, `page_mushaf`, `sourate`, `verset`, `zoom_level` 0.5-4.0 | **Aucune policy n'autorise un enseignant à l'écrire** (invariant J2). Commentaire normatif : « une page tournée par l'enseignant pour toute la classe ne doit jamais l'écrire ». |

### 10.3 Vidéo, salle, présence

| Objet | Migration | Note |
|---|---|---|
| `video_config` | 0010 | `active_provider`, `canary_*`, `ws_url_override`, `token_ttl_seconds` (900). RLS **sans policy** = service_role seul. |
| `session_video_route` | 0010 | Fige fournisseur + URL + salle à la **première** émission. `room_name = 'r_' + sha256(session_id)` tronqué : opaque, sans PII. Seule table reliant une room LiveKit à une séance. |
| `video_token_grants` | 0010 | Append-only : `role`, `can_publish`, `can_publish_video`, `can_publish_data`, `hidden`, `emis_le`, `expire_le`. Rend l'état `en_connexion` dérivable. **La trace la plus proche d'un « intervalle borné » existant.** |
| `livekit_webhook_deliveries` | 0010 | `event_id` PK = idempotence. |
| `session_participants` | 0001 (policies 0012) | PK `(session_id, profile_id)`, `role`, `entered_at`, `exited_at`, index unique un seul `teacher` | **`entered_at` / `exited_at` ne sont JAMAIS écrites** (2 occurrences dans le dépôt : leur déclaration). |
| `session_events` | 0001:195 | `event_type` (joined/left/track_*/record_*), `server_ts`, `source` (`livekit_webhook`\|`user_action`\|`network`\|`server`) | **Ni `duration_seconds`, ni `visit_number`, ni `policy_version`.** Un intervalle ne s'y exprime que comme deux lignes à recoller. `'network'` n'est **jamais émis**. |
| `session_recordings` | 0001 | Métadonnées seules, **aucun producteur Egress**. |
| `autoriser_jeton_video(...)` | 0010 | → jsonb `{ws_url, room_name, provider, identity, role, ttl_seconds, expire_le, capabilities{...}}` | **Cœur du contrôle d'accès.** Lit le rôle dans `session_participants` (jamais en paramètre). Fenêtre **EN DUR** : `started_at - 10 min` / `ended_at + 15 min`. `can_publish_data = (role='teacher')`. `hidden = (role='masked_controller')`. Caméra élève selon `camera_policy` (défaut `forbidden`). Journalise via `log_sensitive_access`. |
| `quitter_salle(uuid)` | 0010 | `session_events(event_type='left', source='user_action')`. **Seule écriture de présence confiée au client.** |
| `enregistrer_webhook_livekit(...)` | 0010 | Idempotence par `on conflict do nothing`. Ne double pas un départ déjà écrit par `user_action` dans les 30 s. |
| `etat_presence(uuid, uuid)` | 0007, **réécrite 0010** | → `presence_state` (14 valeurs) | État **instantané**, jamais une durée. Rend `presente` dès le premier `joined`, **sans comparer à `started_at`**. |
| `session_presence_override` | 0007 | Décisions humaines : `excusee`, `corrigee_manuel`, `finalisee` | Policies d'écriture (enseignant de la séance ou admin) **existent depuis 0007** ; **aucune RPC n'a été écrite** pour les utiliser. |
| `presence_seance_v` | 0007, 0011, **courante 0014:979** | `session_id`, `profile_id`, `role`, `prenom`, `identifiant_immuable`, `etat`, `entre_le`, `derniere_trace_le`, `consolide`, `started_at`, `ended_at`, `statut_seance` | `security_barrier`, bornée par appelant, masque le `masked_controller` sauf admin. **LA source du roster.** |
| `session_peers_v` | 0001:632, courante 0014:1022 | `session_id`, `peer_id`, `first_name`, `immutable_id` | Plus proche parent d'un `TeacherStudentProjection` mais **sans `level`, `curriculum_path`, `academy_id`**. |
| `app_config` (présence) | 0007, 0010 | `presence.seuil_retard_secondes`=300, `presence.fenetre_reconnexion_secondes`=120, `presence.fenetre_connexion_secondes`=90, `recording_retention_days`=30 | **La fenêtre d'OUVERTURE de salle n'y est PAS.** |
| enums | 0001/0007/0010 | `video_provider`, `participant_role` (**4 valeurs**), `camera_policy`, `presence_state` (14), `session_event_type` | Un rôle Teaching Core supplémentaire exigerait une migration. |

### 10.4 Roster, pédagogie, audit, agents

| Objet | Migration | Note |
|---|---|---|
| `profiles` | 0001:71 | `id`, `immutable_id`, `role`, `household_id`, `first_name`, `last_name`, `account_status`, `access_until` | **Aucun téléphone, email, adresse ni date de naissance dans tout le dépôt.** Policies 0001:704-715 : **pas de branche enseignant**. |
| `student_profiles` | 0001:100 | `student_type`, `interface_mode`, `level`, `riwaya`, `camera_policy`, `avatar_storage_key` | Policies admin + foyer. Pas de branche enseignant : c'est `teacher_roster_v` qui livre `level` et `riwaya`. |
| `teacher_profiles` | 0001:90 | `country`, `languages[]`, `weekly_hours_cap`, `kyc_status` | Lisible **par soi seulement**. **AUCUNE colonne photo/avatar.** |
| `teacher_roster_v` | 0001:650, 0005:705, **0014:868** | `session_id`, `student_id`, `first_name`, `immutable_id`, `level`, `riwaya` | Bornée `teacher_id = auth.uid()`. Indexée par **SÉANCE**, pas par groupe. |
| `eleves_en_attente_v` | 0005:1401, 0014:946 | + `interface_mode`, `weekday`, `hour_local`, `timezone_iana`, `depuis` | Réservée `app_role() = 'teacher'`. **Seule vue enseignant portant `level` ET `interface_mode`.** |
| `lesson_reports` / `makharij_findings` | 0001:221 / :233 | `session_id`, `idempotency_key` unique, `content` jsonb, `author_profile_id` | Lecture **auteur seul** (0001:1074). |
| `programme_versions` / `programme_niveaux` | 0020 | `statut` (brouillon/publiee/archivee), `numero_version` unique, contrainte de publication complète ; `code_technique` + `nom_humain` + `cycle` + `ordre` | **Le patron `ResourceVersion` déjà en base.** Règle UX inscrite en commentaire SQL : le `code_technique` n'est **jamais** exposé comme titre. |
| `progression_historique`, `progression_exceptions`, `evaluations`, `controles_qualite` | 0021-0024 | — | **Tout le domaine Pédagogie est ADMIN-ONLY.** 0022:5-12 **interdit** d'étendre `rule_overrides`/`matching_requests` avec des clés pédagogiques. |
| `audit_logs` (+ `audit_logs_default`) | 0001:303 | `actor`, `actor_role`, `action`, `table_name`, `row_id`, `payload` jsonb, `prev_hash`, `hash` ; partitionnée par range | Append-only, chaînée sha256, `log_sensitive_access()` prend un `LOCK TABLE share row exclusive`. Fermée à `agent_ro`. Le `payload` peut accueillir des champs **sans migration** — mais rien n'y serait alors requêtable ni contraint. |
| `journal_audit` / `journal_audit_filtres` / `verifier_chaine_audit` | 0009, 0016 | `[admin]`, keyset, limites 200 / 5000 | La consultation du journal n'est **volontairement pas** journalisée. |
| `jetons_agent` + `agent_ro` + `agent_pre_request()` | 0014 | `expire_le <= cree_le + 24h`, `remises`, `revoque_le` | **Seul exemple de durée plafonnée et de compteur d'usage côté serveur.** `agent_pre_request()` doit rester appelable par `anon`, `authenticated` **et** `agent_ro` (invariant I5). |
| `agent_identite_masquee()` | 0014:238 | → boolean | Motif de masquage **colonne par colonne à l'intérieur d'une vue**. |
| `rejoindre_observation(uuid)` / `assister_seance(uuid)` | 0012:299 / :398 | `volatile security definer`, execute `authenticated` | **Aucune des deux ne consulte un quota, une politique de groupe ou un budget de temps.** `rejoindre_observation` journalise, `assister_seance` non. |
| `est_observateur_masque(uuid, uuid)` | 0012:231 | `security definer, stable` | **Pont indispensable** : une policy interrogeant `session_participants` en direct ne verrait que ce que voit l'appelant. |
| `rule_overrides` + `regle_brute()` / `regle_effective()` | 0005 | Politique **PAR PROFIL uniquement** | Aucun scope groupe, **aucun `policy_version`** nulle part dans le dépôt. |
| `storage.buckets` | 0004:997 | `'kyc'` et `'avatars'` **uniquement** | Le bloc est défensif (`if to_regclass('storage.buckets') is null then …`) : c'est le patron à reprendre. |

### 10.5 ABSENTES — à ne pas supposer existantes

Aucune de ces tables n'existe dans `0001` à `0024` (inventaire complet vérifié) :

`library_resource`, `resource_version`, `download_asset`, `resource_cover`, `resource_assignment`,
`annotation_layer`, `shared_content_state`, `content_position`, `attendance_records`,
`guardian_observation_policy`, `guardian_session_visit`, `session_feedback`, `student_concern`,
`learning_assignment`, ainsi que toute table d'état de téléchargement, tout bucket de supports,
tout index de recherche plein texte, et **toute colonne `groupe_id` sur `sessions`**.
