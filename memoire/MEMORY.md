# Memory Index — projet actif : Rewayah Academy (remis à plat le 23/09/2026)

> 🧊 **RÈGLES GELÉES DU DIRECTEUR, 26/09/2026, À LIRE AVANT TOUT LOT VISUEL OU TOUTE SPEC** : [DESIGN-GOV-2026-09-26](DESIGN-GOV-2026-09-26.md) (autorité, validation UX 2026 avec preuve `UX_REVIEW_<lot>.md`, contrats A à E espacements / boutons / composants / bureau / mouvement, skeletons, aucune marche arrière : harmonisation en une passe après tous les rôles). Immuable jusqu'à nouvelle décision datée du directeur.

> **DÉMARRER ICI.** Dépôt `D:\RA _APP\RA -OFFICIAL-APP`. Specs canoniques : `docs/current/00_LIRE_D_ABORD.md`
> puis `08` (gel fonctionnel, gate C0) et le document du domaine touché. Branche propre de PR :
> `c0/configuration-baseline-2026-09-23` (PR #2 en brouillon, non fusionnée) ; V0 isolé sur `v0/verite-produit`.
> **23/09 soir : le gel UI est levé** (`08` §5 bis) : travail UI autorisé sur branche dédiée, un écran à la fois,
> **uniquement sur ordre explicite du directeur** après transmission des visuels ; fusion et déploiement restent bloqués
> (CI, migrations, secrets). V0, V1, CORE24 toujours suspendus.
> **Pousser sur `main` déploie en production.** Aucune suppression de branche, worktree ou mémoire sans
> accord explicite sur la liste exacte. État complet → [[rewayah_remise_a_plat_2026-09-23]].
> ⛔ PISI et OfficialSays sont EN PAUSE : ne les rouvrir que si l'opérateur les nomme (`memory/archive/`).

## Rewayah Academy

- [Remise à plat 23/09 — état, décisions, validations en attente](rewayah_remise_a_plat_2026-09-23.md) — docs archivées, code dormant conservé, worktrees à retirer après accord, CORE24 non conforme.
- [Chantier frontend Tuteur V1 (24/09)](project_tuteur_frontend_v1_chantier.md) — multi-agents, branche locale `ui/tuteur-v1` ; reprise : `D:\RA _APP\pilotage-tuteur-v1\00_REPRISE.md`.
- Historique des lots du 5 au 22 septembre 2026 : `memory/archive/rewayah_2026-09/` (51 fichiers). Ne pas charger par défaut.

## Pièges techniques toujours vrais sur ce dépôt

- 🔐 [`agent_ro` jamais sur RPC d'écriture](feedback_agent_ro_jamais_sur_rpc_ecriture.md) · [EXECUTE par deux chemins](feedback_double_chemin_execute_supabase.md) · [porte SQL en exigence positive](feedback_porte_sql_exigence_positive.md) · [`security definer` ne rejoue pas la policy](feedback_security_definer_ne_rejoue_pas_la_policy.md) · [porte serveur confrontée à la policy](feedback_porte_serveur_doit_etre_confrontee_a_la_policy.md) · [RLS borne les lignes, pas les colonnes](feedback_rls_borne_les_lignes_pas_les_colonnes_motif_litige.md) · [liste de rôles masqués recopiée partout](feedback_une_liste_de_roles_masques_est_recopiee_partout.md)
- 🔑 [Hook de jeton qui rend `null` ferme tout](feedback_hook_jeton_null_ferme_tout_en_silence.md) · [Mesurer une RPC en prod sans laisser de ligne](feedback_mesurer_une_rpc_en_prod_sans_laisser_de_ligne.md) · [`creer_groupe` surchargée, appel à 6 args ambigu](feedback_creer_groupe_surchargee_appel_ambigu.md)
- 🚢 [Depuis le 24/09, pousser sur `main` déploie VRAIMENT (secrets présents, run #29 PASS) ; une PR vers `main` donne une URL d'aperçu Vercel](feedback_chaine_deploiement_reparee_le_21_09.md) · [Zero-config Vercel écrase la prod par un 404](feedback_vercel_zero_config_ecrase_la_production.md) · [`db push` tue le job Edge ; `--no-verify-jwt` ouvre tout](feedback_db_push_tue_le_job_et_les_fonctions_edge.md)
- 🎖️ [Badges : cinq niveaux, `level` réservé aux élèves](feedback_badges_cinq_niveaux_et_level_reserve_aux_eleves.md)

## Feedback de méthode

- [Brancher l'entrée, pas seulement la route](feedback_brancher_l_entree_pas_la_route.md) · [Vérifier un document officiel avant d'en produire un](feedback_verifier_document_officiel_avant_audit.md) · [Chiffrer l'écart avant le remède](feedback_chiffrer_avant_de_proposer.md) · [Vérifier l'expérience à 390×844 avec preuve](feedback_mobile_first_proof.md) · [Ne rien inventer](feedback_no_invent_best_apps.md)
- [Préciser la branche quand on rapporte un push](feedback_preciser_branche_push.md) · [Finir par un prompt de reprise vers `docs/current`](feedback_prompt_reprise_handoff.md) · [Modèle selon difficulté](feedback_sonnet_for_easy_tasks.md)
- Sur Rewayah, **aucun push automatique après build vert** : la consigne PISI « commit & push always » est archivée (`archive/pisi/`) et ne s'applique pas ici (`docs/current/00`, invariants).

## Archive (ne pas charger par défaut)

- `memory/archive/pisi/` (60 fichiers, PISI en pause) · `memory/archive/officialsays_et_autres/` (handoffs OfficialSays, Hermes, billing, source engine, tooling) · `memory/archive/rewayah_2026-09/` (lots Rewayah du 5 au 22/09).
