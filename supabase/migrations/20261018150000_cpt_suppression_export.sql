-- CPT-SUPPR-EXPORT (18/10/2026) : depuis « Compte », une personne peut
-- (a) telecharger une copie de ses donnees et (b) demander la suppression de son
-- compte (droit d'acces, de portabilite et d'effacement).
--
-- Ce qui existait : seulement des delais de conservation (`app_config` :
-- `recording_retention_days`, `kyc_retention_days`) et la regle du matricule
-- (DECISION-IMMATRICULATION-2026-10-12 : jamais reattribue, meme apres un
-- effacement). Aucune porte d'export ni de suppression n'existait.
--
-- * `mes_donnees_export()` : la copie JSON de l'appelant (tuteur, enseignant,
--   eleve adulte) et, pour un tuteur, celle des eleves de son foyer. Colonnes
--   nommees une a une : jamais de secret (jeton d'appareil, empreinte, cle de
--   stockage, coordonnees bancaires, lien de paiement), jamais de note interne
--   de l'equipe (motifs, notes d'evaluation, motifs d'annulation).
-- * `demander_suppression_compte(motif)` : une demande tracee dans
--   `demandes_suppression_compte`, avec un delai de reflexion lu dans
--   `app_config` (`compte.suppression_delai_jours`, 14 jours par defaut, regle
--   par la direction dans Configuration > Conservation des donnees).
-- * `annuler_suppression_compte()` : la personne annule tant que la direction
--   n'a pas traite.
-- * `ma_situation_suppression()` : ce que l'ecran dit avant et apres la demande
--   (la demande en cours, un solde a regler, des seances a venir). Ces deux
--   points n'empechent pas la demande ; la direction les voit aussi.
-- * `demandes_suppression_lister()` : la direction lit les demandes.
-- * `traiter_demande_suppression(id)` : la direction, en double verification,
--   anonymise le profil une fois le delai ecoule : nom, courriel, telephone,
--   photo, genre, coordonnees de paiement, appareils sont effaces. Le matricule
--   et toutes les lignes financieres (factures, paiements, mouvements,
--   contrats signes) sont GARDES, jamais supprimes : obligation de conservation
--   comptable. Le traitement est refuse tant qu'une seance a venir existe
--   (a annuler ou reattribuer d'abord).
--
-- Hors perimetre (a decider avec le juriste) : la duree legale de conservation
-- des lignes financieres (gardees ici sans echeance), les messages deja envoyes
-- (gardes, leur auteur devient anonyme), les adresses de tiers invites par la
-- personne (effacees sur ses invitations).
BEGIN;

INSERT INTO public.app_config (key, value)
VALUES ('compte.suppression_delai_jours', '14'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE TABLE public.demandes_suppression_compte (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  role_au_depot text NOT NULL,
  motif text CHECK (motif IS NULL OR pg_catalog.char_length(motif) <= 500),
  delai_jours integer NOT NULL CHECK (delai_jours >= 0),
  demandee_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  echeance_le timestamptz NOT NULL,
  statut text NOT NULL DEFAULT 'en_attente'
    CHECK (statut IN ('en_attente', 'annulee', 'traitee')),
  annulee_le timestamptz,
  traitee_le timestamptz,
  traitee_par uuid REFERENCES public.profiles(id),
  CONSTRAINT demandes_suppression_compte_etat CHECK (
    (statut = 'annulee') = (annulee_le IS NOT NULL)
    AND (statut = 'traitee') = (traitee_le IS NOT NULL)
    AND (statut = 'traitee' OR traitee_par IS NULL)
    AND echeance_le >= demandee_le)
);
-- Une seule demande en cours par personne.
CREATE UNIQUE INDEX demandes_suppression_compte_une_en_cours
  ON public.demandes_suppression_compte (profile_id) WHERE statut = 'en_attente';
CREATE INDEX demandes_suppression_compte_statut
  ON public.demandes_suppression_compte (statut, demandee_le);
COMMENT ON TABLE public.demandes_suppression_compte IS
  'CPT-SUPPR-EXPORT: demande de suppression de compte, tracee. Ecrite par les seules fonctions DEFINER ; la personne lit la sienne.';

ALTER TABLE public.demandes_suppression_compte ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.demandes_suppression_compte FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT SELECT ON public.demandes_suppression_compte TO authenticated;
CREATE POLICY demandes_suppression_compte_lecture_personne ON public.demandes_suppression_compte
  FOR SELECT TO authenticated
  USING (profile_id = (SELECT auth.uid()));

-- Les personnes concernees : l'appelant et, pour un tuteur, les eleves de son foyer.
CREATE FUNCTION private.cpt_perimetre(p uuid)
RETURNS uuid[]
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.array_agg(s.id)
    FROM (
      SELECT p AS id
      UNION
      SELECT e.id
        FROM public.profiles me
        JOIN public.profiles e
          ON e.household_id = me.household_id AND e.role = 'student' AND e.id <> p
       WHERE me.id = p AND me.role = 'guardian' AND me.household_id IS NOT NULL
    ) s;
$function$;

-- Qui peut exporter ou demander : un tuteur, un enseignant, un eleve adulte
-- autonome, au compte valide. Jamais la direction, la comptabilite ni le controle.
CREATE FUNCTION private.cpt_admis(p uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT coalesce(p IS NOT NULL AND public.app_account_valid()
         AND EXISTS (
           SELECT 1 FROM public.profiles pr
            WHERE pr.id = p AND pr.deleted_at IS NULL
              AND (pr.role IN ('guardian', 'teacher')
                   OR (pr.role = 'student' AND EXISTS (
                         SELECT 1 FROM public.student_profiles sp
                          WHERE sp.profile_id = pr.id AND sp.student_type = 'autonomous')))), false);
$function$;

-- Ce que la personne doit savoir avant de partir : un solde a regler (factures
-- a financer, par devise) et des seances a venir.
CREATE FUNCTION private.cpt_situation(p uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[] := private.cpt_perimetre(p);
  v_role public.app_role;
  v_foyer uuid;
  v_dus jsonb;
  v_seances integer;
BEGIN
  SELECT pr.role, pr.household_id INTO v_role, v_foyer FROM public.profiles pr WHERE pr.id = p;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'devise', d.devise, 'total_mineur', d.total) ORDER BY d.devise), '[]'::jsonb)
    INTO v_dus
    FROM (
      SELECT f.devise, pg_catalog.sum(f.total_mineur)::bigint AS total
        FROM public.factures_mensuelles f
       WHERE f.statut = 'a_financer' AND f.total_mineur > 0
         AND (f.profile_id = ANY (coalesce(v_ids, ARRAY[]::uuid[]))
              OR (v_role = 'guardian' AND f.household_id = v_foyer))
       GROUP BY f.devise
    ) d;
  SELECT pg_catalog.count(*)::integer INTO v_seances
    FROM public.sessions s
   WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
     AND s.started_at > pg_catalog.clock_timestamp()
     AND (s.teacher_id = p
          OR s.groupe_id IN (SELECT gm.groupe_id FROM public.groupe_membres gm
                              WHERE gm.student_id = ANY (coalesce(v_ids, ARRAY[]::uuid[]))
                                AND gm.left_at IS NULL));
  RETURN pg_catalog.jsonb_build_object(
    'solde_du', pg_catalog.jsonb_array_length(v_dus) > 0,
    'montants_dus', v_dus,
    'seances_a_venir', v_seances);
END;
$function$;

CREATE FUNCTION private.cpt_demande_json(d public.demandes_suppression_compte)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', d.id,
    'statut', d.statut,
    'motif', d.motif,
    'delai_jours', d.delai_jours,
    'demandee_le', d.demandee_le,
    'echeance_le', d.echeance_le,
    'annulee_le', d.annulee_le,
    'traitee_le', d.traitee_le);
$function$;

-- (a) La copie des donnees.
CREATE FUNCTION public.mes_donnees_export()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_ids uuid[];
  v_role public.app_role;
  v_foyer uuid;
  v_res jsonb;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() IN ('guardian', 'teacher', 'student')
                  AND private.cpt_admis(v_uid), false) THEN
    RAISE EXCEPTION 'export reserve a la personne connectee, compte valide'
      USING ERRCODE = '42501';
  END IF;
  SELECT pr.role, pr.household_id INTO v_role, v_foyer FROM public.profiles pr WHERE pr.id = v_uid;
  v_ids := private.cpt_perimetre(v_uid);
  IF v_role <> 'guardian' THEN
    v_foyer := NULL;
  END IF;

  v_res := pg_catalog.jsonb_build_object(
    'format', 'rewayah-export-v1',
    'genere_le', pg_catalog.clock_timestamp(),
    'perimetre', CASE WHEN v_role = 'guardian' THEN 'personne_et_foyer' ELSE 'personne' END,
    'profil', (SELECT pg_catalog.jsonb_build_object(
                 'id', pr.id, 'matricule', pr.immutable_id, 'role', pr.role,
                 'prenom', pr.first_name, 'nom', pr.last_name, 'statut', pr.account_status,
                 'genre', pr.gender, 'cree_le', pr.created_at,
                 'courriel', (SELECT u.email FROM auth.users u WHERE u.id = pr.id))
                 FROM public.profiles pr WHERE pr.id = v_uid),
    'profil_eleve', (SELECT private.cpt_json_eleve(sp) FROM public.student_profiles sp
                      WHERE sp.profile_id = v_uid),
    'profil_enseignant', (SELECT pg_catalog.jsonb_build_object(
                 'pays', tp.country, 'langues', tp.languages,
                 'heures_hebdo_max', tp.weekly_hours_cap, 'fuseau', tp.timezone_iana,
                 'titre', tp.titre, 'cree_le', tp.created_at)
                 FROM public.teacher_profiles tp WHERE tp.profile_id = v_uid),
    'foyer', CASE WHEN v_foyer IS NULL THEN NULL ELSE (SELECT pg_catalog.jsonb_build_object(
                 'id', h.id, 'fuseau', h.timezone, 'statut', h.status,
                 'usage_inscription', h.usage_inscription,
                 'eleves', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                     'id', e.id, 'matricule', e.immutable_id, 'prenom', e.first_name,
                     'nom', e.last_name, 'statut', e.account_status, 'genre', e.gender,
                     'cree_le', e.created_at, 'profil_eleve', private.cpt_json_eleve(sp))
                     ORDER BY e.created_at)
                   FROM public.profiles e
                   LEFT JOIN public.student_profiles sp ON sp.profile_id = e.id
                  WHERE e.household_id = h.id AND e.role = 'student' AND e.id <> v_uid),
                  '[]'::jsonb))
                 FROM public.households h WHERE h.id = v_foyer) END,
    'contrats_acceptes', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', c.profile_id, 'type', c.contract_kind, 'version', c.version,
                 'accepte_le', c.accepted_at, 'signataire', c.signer_name)
                 ORDER BY c.accepted_at)
                 FROM public.contract_acceptances c WHERE c.profile_id = ANY (v_ids)), '[]'::jsonb),
    'classes', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', gm.student_id, 'classe_id', g.id,
                 'nom', coalesce(g.nom_cours, g.libelle), 'public', g.type_public,
                 'jour', g.weekday, 'heure_locale', g.hour_local, 'fuseau', g.timezone_iana,
                 'depuis', gm.joined_at, 'jusqu_au', gm.left_at)
                 ORDER BY gm.joined_at)
                 FROM public.groupe_membres gm JOIN public.groupes g ON g.id = gm.groupe_id
                WHERE gm.student_id = ANY (v_ids)), '[]'::jsonb),
    'classes_enseignees', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'classe_id', g.id, 'nom', coalesce(g.nom_cours, g.libelle),
                 'public', g.type_public, 'jour', g.weekday, 'heure_locale', g.hour_local,
                 'fuseau', g.timezone_iana, 'creee_le', g.created_at, 'terminee_le', g.ended_at)
                 ORDER BY g.created_at)
                 FROM public.groupes g WHERE g.teacher_id = v_uid), '[]'::jsonb),
    'seances', coalesce((SELECT pg_catalog.jsonb_agg(x.j ORDER BY x.debut DESC) FROM (
                 SELECT s.started_at AS debut, pg_catalog.jsonb_build_object(
                   'profil_id', sp.profile_id, 'seance_id', s.id, 'debut', s.started_at,
                   'fin', s.ended_at, 'statut', s.status, 'role', sp.role,
                   'entree', sp.entered_at, 'sortie', sp.exited_at) AS j
                   FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
                  WHERE sp.profile_id = ANY (v_ids) AND sp.deleted_at IS NULL AND s.deleted_at IS NULL
                  ORDER BY s.started_at DESC LIMIT 5000) x), '[]'::jsonb),
    'seances_enseignees', coalesce((SELECT pg_catalog.jsonb_agg(x.j ORDER BY x.debut DESC) FROM (
                 SELECT s.started_at AS debut, pg_catalog.jsonb_build_object(
                   'seance_id', s.id, 'classe_id', s.groupe_id, 'debut', s.started_at,
                   'fin', s.ended_at, 'statut', s.status) AS j
                   FROM public.sessions s WHERE s.teacher_id = v_uid AND s.deleted_at IS NULL
                  ORDER BY s.started_at DESC LIMIT 5000) x), '[]'::jsonb),
    'demandes_horaires', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', d.eleve_id, 'public', d.type_public, 'langue', d.langue_code,
                 'fuseau', d.fuseau_iana, 'jours', d.jours, 'heures_locales', d.heures_locales,
                 'etat', d.etat, 'cree_le', d.created_at) ORDER BY d.created_at)
                 FROM public.demandes_horaires_famille d WHERE d.eleve_id = ANY (v_ids)), '[]'::jsonb),
    'intentions_horaire', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', i.eleve_id, 'fuseau', i.fuseau_affiche, 'heure', i.heure_affichee,
                 'jours', i.jours_affiches, 'etat', i.etat, 'cree_le', i.created_at)
                 ORDER BY i.created_at)
                 FROM public.intentions_horaire i WHERE i.eleve_id = ANY (v_ids)), '[]'::jsonb),
    'demandes_creneau_personnalise', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', d.eleve_id, 'public', d.type_public, 'langue', d.langue_code,
                 'fuseau', d.fuseau_iana, 'jours', d.jours, 'heure_locale', d.heure_locale,
                 'etat', d.etat, 'cree_le', d.created_at) ORDER BY d.created_at)
                 FROM public.demandes_creneau_personnalise d WHERE d.eleve_id = ANY (v_ids)), '[]'::jsonb),
    'factures', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'id', f.id, 'profil_id', f.profile_id, 'mois', f.mois, 'devise', f.devise,
                 'total_mineur', f.total_mineur, 'statut', f.statut, 'lignes', f.lignes,
                 'emise_le', f.emise_le, 'financee_le', f.financee_le, 'annulee_le', f.annulee_le)
                 ORDER BY f.mois DESC, f.id)
                 FROM public.factures_mensuelles f
                WHERE f.profile_id = ANY (v_ids) OR (v_foyer IS NOT NULL AND f.household_id = v_foyer)),
                '[]'::jsonb),
    'paiements', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', x.profile_id, 'montant_mineur', x.montant_mineur,
                 'devise', x.devise, 'reference', x.reference, 'date', x.le) ORDER BY x.le DESC)
                 FROM (
                   SELECT ps.profile_id, ps.montant_mineur, ps.devise, ps.reference, ps.saisi_le AS le
                     FROM public.paiements_saisis ps WHERE ps.profile_id = ANY (v_ids)
                   UNION ALL
                   SELECT pso.profile_id, pso.montant_mineur, pso.devise, pso.reference, pso.soumis_le
                     FROM public.paiements_soumis pso WHERE pso.profile_id = ANY (v_ids)) x),
                '[]'::jsonb),
    'recharges', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'reference', r.reference, 'devise', r.devise, 'total_mineur', r.total_mineur,
                 'moyen', r.rail, 'etat', r.etat, 'cree_le', r.cree_le,
                 'confirme_le', r.confirme_le, 'termine_le', r.termine_le) ORDER BY r.cree_le)
                 FROM public.commandes_recharge r
                WHERE r.titulaire = v_uid OR (v_foyer IS NOT NULL AND r.household_id = v_foyer)),
                '[]'::jsonb),
    'engagements_prepaiement', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', e.profile_id, 'formule', e.formule, 'mois_debut', e.mois_debut,
                 'nb_mois', e.nb_mois, 'total_mineur', e.total_mineur, 'devise', e.devise,
                 'cree_le', e.cree_le) ORDER BY e.cree_le)
                 FROM public.engagements_prepaiement e WHERE e.profile_id = ANY (v_ids)), '[]'::jsonb),
    'bourses', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', b.profile_id, 'pour_mille', b.pour_mille, 'mois_debut', b.mois_debut,
                 'mois_fin', b.mois_fin, 'accordee_le', b.accordee_le, 'retiree_le', b.retiree_le)
                 ORDER BY b.accordee_le)
                 FROM public.bourses_eleves b WHERE b.profile_id = ANY (v_ids)), '[]'::jsonb),
    'messages_envoyes', coalesce((SELECT pg_catalog.jsonb_agg(x.j ORDER BY x.le) FROM (
                 SELECT m.envoye_le AS le, pg_catalog.jsonb_build_object(
                   'fil_id', m.fil_id, 'texte', m.texte, 'envoye_le', m.envoye_le) AS j
                   FROM public.com_messages m WHERE m.auteur_id = v_uid
                  ORDER BY m.envoye_le DESC LIMIT 5000) x), '[]'::jsonb),
    'appareils', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', dv.profile_id, 'plateforme', dv.platform, 'nom', dv.label,
                 'appaire_le', dv.paired_at, 'derniere_utilisation', dv.last_used_at,
                 'revoque_le', dv.revoked_at) ORDER BY dv.paired_at)
                 FROM public.devices dv WHERE dv.profile_id = ANY (v_ids) AND dv.deleted_at IS NULL),
                '[]'::jsonb),
    'appareils_notifications', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'plateforme', dt.platform, 'cree_le', dt.created_at) ORDER BY dt.created_at)
                 FROM public.device_tokens dt WHERE dt.profile_id = v_uid), '[]'::jsonb),
    'progression', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', ph.student_id, 'niveau_id', ph.niveau_id,
                 'mouvement', ph.type_mouvement, 'date', ph.created_at) ORDER BY ph.created_at)
                 FROM public.progression_historique ph WHERE ph.student_id = ANY (v_ids)), '[]'::jsonb),
    'resumes_de_seance', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', r.student_id, 'seance_id', r.session_id, 'texte', r.texte_famille,
                 'publie_le', r.publie_le) ORDER BY r.publie_le)
                 FROM public.seance_resumes r
                WHERE r.student_id = ANY (v_ids) AND r.publie_le IS NOT NULL AND r.revoque_le IS NULL),
                '[]'::jsonb),
    'position_de_lecture', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'profil_id', rp.student_profile_id, 'page', rp.page_mushaf, 'sourate', rp.sourate,
                 'verset', rp.verset, 'mis_a_jour_le', rp.updated_at))
                 FROM public.student_reading_position rp
                WHERE rp.student_profile_id = ANY (v_ids)), '[]'::jsonb),
    'disponibilites', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'jour', w.weekday, 'heure_locale', w.hour_local, 'fuseau', w.timezone_iana)
                 ORDER BY w.weekday, w.hour_local)
                 FROM public.weekly_availability w WHERE w.profile_id = v_uid), '[]'::jsonb),
    'reglage_priere', (SELECT pg_catalog.jsonb_build_object(
                 'methode', pz.method, 'ecole', pz.madhab, 'fuseau', pz.timezone_iana,
                 'pause_minutes', pz.pause_minutes, 'lieu', pz.place_label,
                 'mis_a_jour_le', pz.updated_at)
                 FROM public.prayer_settings pz WHERE pz.teacher_id = v_uid),
    'documents_identite', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'type', k.doc_type, 'statut', k.status, 'depose_le', k.created_at,
                 'purge_prevue_le', k.purge_at) ORDER BY k.created_at)
                 FROM public.kyc_documents k WHERE k.profile_id = v_uid AND k.deleted_at IS NULL),
                '[]'::jsonb),
    'moyens_de_paiement_recus', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'type', pm.kind, 'coordonnees_enregistrees', pm.details IS NOT NULL AND pm.details <> '{}'::jsonb,
                 'modifie_le', pm.last_modified_at) ORDER BY pm.created_at)
                 FROM public.payout_methods pm WHERE pm.profile_id = v_uid AND pm.deleted_at IS NULL),
                '[]'::jsonb),
    'demandes_suppression', coalesce((SELECT pg_catalog.jsonb_agg(private.cpt_demande_json(d)
                 ORDER BY d.demandee_le)
                 FROM public.demandes_suppression_compte d WHERE d.profile_id = v_uid), '[]'::jsonb));

  PERFORM public.log_sensitive_access('export_donnees_personnelles', 'profiles', v_uid::text,
    pg_catalog.jsonb_build_object('perimetre', v_res -> 'perimetre'));
  RETURN v_res;
END;
$function$;

-- Le profil d'eleve exporte (colonnes nommees : ni cle de stockage, ni lien interne).
CREATE FUNCTION private.cpt_json_eleve(sp public.student_profiles)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT CASE WHEN sp.profile_id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
    'type', sp.student_type, 'interface', sp.interface_mode, 'niveau', sp.level,
    'riwaya', sp.riwaya, 'camera', sp.camera_policy, 'langue_cours', sp.langue_cours,
    'cohorte', sp.cohorte, 'niveau_declare', sp.niveau_declare, 'objectif', sp.objectif,
    'diagnostic', sp.diagnostic_statut, 'accueil_fait_le', sp.onboarding_fait_le,
    'cree_le', sp.created_at) END;
$function$;

-- (b) La demande de suppression.
CREATE FUNCTION public.demander_suppression_compte(p_motif text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_motif text := nullif(pg_catalog.btrim(coalesce(p_motif, '')), '');
  v_delai integer;
  v_role public.app_role;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_d public.demandes_suppression_compte;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() IN ('guardian', 'teacher', 'student')
                  AND private.cpt_admis(v_uid), false) THEN
    RAISE EXCEPTION 'demande reservee a la personne connectee, compte valide'
      USING ERRCODE = '42501';
  END IF;
  IF v_motif IS NOT NULL AND pg_catalog.char_length(v_motif) > 500 THEN
    RAISE EXCEPTION 'motif trop long (500 caracteres au plus)' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cpt-suppression:' || v_uid::text, 0));
  SELECT d.* INTO v_d FROM public.demandes_suppression_compte d
   WHERE d.profile_id = v_uid AND d.statut = 'en_attente';
  IF NOT FOUND THEN
    v_delai := greatest(0, public.app_config_int('compte.suppression_delai_jours', 14));
    SELECT pr.role INTO v_role FROM public.profiles pr WHERE pr.id = v_uid;
    INSERT INTO public.demandes_suppression_compte
      (profile_id, role_au_depot, motif, delai_jours, demandee_le, echeance_le)
    VALUES (v_uid, v_role::text, v_motif, v_delai, v_maintenant,
            v_maintenant + pg_catalog.make_interval(days => v_delai))
    RETURNING * INTO v_d;
    PERFORM public.log_sensitive_access('suppression_compte_demandee', 'demandes_suppression_compte',
      v_d.id::text, pg_catalog.jsonb_build_object('delai_jours', v_delai));
  END IF;
  RETURN private.cpt_demande_json(v_d) || pg_catalog.jsonb_build_object('situation', private.cpt_situation(v_uid));
END;
$function$;

CREATE FUNCTION public.annuler_suppression_compte()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_d public.demandes_suppression_compte;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() IN ('guardian', 'teacher', 'student')
                  AND private.cpt_admis(v_uid), false) THEN
    RAISE EXCEPTION 'annulation reservee a la personne connectee, compte valide'
      USING ERRCODE = '42501';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cpt-suppression:' || v_uid::text, 0));
  UPDATE public.demandes_suppression_compte d
     SET statut = 'annulee', annulee_le = pg_catalog.clock_timestamp()
   WHERE d.profile_id = v_uid AND d.statut = 'en_attente'
  RETURNING d.* INTO v_d;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucune demande de suppression en cours' USING ERRCODE = 'P0002';
  END IF;
  PERFORM public.log_sensitive_access('suppression_compte_annulee', 'demandes_suppression_compte',
    v_d.id::text, '{}'::jsonb);
  RETURN private.cpt_demande_json(v_d);
END;
$function$;

-- Ce que l'ecran affiche : la demande en cours (ou la derniere) et la situation.
CREATE FUNCTION public.ma_situation_suppression()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_d public.demandes_suppression_compte;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() IN ('guardian', 'teacher', 'student')
                  AND private.cpt_admis(v_uid), false) THEN
    RAISE EXCEPTION 'lecture reservee a la personne connectee, compte valide'
      USING ERRCODE = '42501';
  END IF;
  SELECT d.* INTO v_d FROM public.demandes_suppression_compte d
   WHERE d.profile_id = v_uid AND d.statut = 'en_attente';
  RETURN pg_catalog.jsonb_build_object(
    'demande', CASE WHEN v_d.id IS NULL THEN NULL ELSE private.cpt_demande_json(v_d) END,
    'delai_jours', greatest(0, public.app_config_int('compte.suppression_delai_jours', 14)),
    'situation', private.cpt_situation(v_uid));
END;
$function$;

-- La direction lit les demandes (en attente d'abord).
CREATE FUNCTION public.demandes_suppression_lister()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'demandes de suppression reservees a la direction'
      USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((SELECT pg_catalog.jsonb_agg(x.j ORDER BY x.rang, x.le DESC) FROM (
    SELECT CASE d.statut WHEN 'en_attente' THEN 0 ELSE 1 END AS rang, d.demandee_le AS le,
           private.cpt_demande_json(d) || pg_catalog.jsonb_build_object(
             'profil_id', d.profile_id,
             'matricule', pr.immutable_id,
             'role', d.role_au_depot,
             'prenom', pr.first_name,
             'nom', pr.last_name,
             'delai_ecoule', d.statut = 'en_attente' AND d.echeance_le <= pg_catalog.clock_timestamp(),
             'eleves_du_foyer', (SELECT pg_catalog.count(*) FROM public.profiles e
                                  WHERE d.role_au_depot = 'guardian' AND pr.household_id IS NOT NULL
                                    AND e.household_id = pr.household_id AND e.role = 'student'),
             'situation', CASE WHEN d.statut = 'en_attente' THEN private.cpt_situation(d.profile_id) END) AS j
      FROM public.demandes_suppression_compte d
      JOIN public.profiles pr ON pr.id = d.profile_id
     ORDER BY CASE d.statut WHEN 'en_attente' THEN 0 ELSE 1 END, d.demandee_le DESC
     LIMIT 200) x), '[]'::jsonb);
END;
$function$;

-- L'anonymisation d'un profil. Garde : matricule, lignes financieres, contrats
-- signes, messages deja envoyes. Efface : nom, courriel, telephone, photo, genre,
-- coordonnees de paiement, appareils, lieu de priere, disponibilites.
CREATE FUNCTION private.cpt_anonymiser(p uuid)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_colonnes text[];
  v_sets text[] := ARRAY[]::text[];
BEGIN
  UPDATE public.profiles
     SET first_name = 'Compte', last_name = 'supprimé', gender = NULL,
         account_status = 'disabled', access_until = pg_catalog.clock_timestamp()
   WHERE id = p;
  UPDATE public.student_profiles
     SET avatar_storage_key = NULL, objectif = NULL
   WHERE profile_id = p;
  UPDATE public.teacher_profiles
     SET photo_storage_key = NULL, country = NULL, titre = NULL
   WHERE profile_id = p;
  DELETE FROM public.prayer_settings WHERE teacher_id = p;
  DELETE FROM public.weekly_availability WHERE profile_id = p;
  DELETE FROM public.device_tokens WHERE profile_id = p;
  UPDATE public.devices
     SET label = NULL, revoked_at = coalesce(revoked_at, pg_catalog.clock_timestamp())
   WHERE profile_id = p;
  -- La piece d'identite deposee part a la prochaine purge (`purge_at` echu).
  UPDATE public.kyc_documents
     SET purge_at = least(coalesce(purge_at, pg_catalog.clock_timestamp()), pg_catalog.clock_timestamp())
   WHERE profile_id = p AND deleted_at IS NULL;
  UPDATE public.payout_methods
     SET details = '{}'::jsonb, deleted_at = coalesce(deleted_at, pg_catalog.clock_timestamp())
   WHERE profile_id = p;
  -- Les adresses de tiers invites par la personne.
  UPDATE public.invitations_foyer
     SET email_invite = 'efface-' || id::text || '@invalide.rewayah.invalid'
   WHERE invite_par = p;

  -- Le compte de connexion : courriel, telephone, identite du fournisseur, sessions.
  -- Colonnes et tables lues au catalogue : le schema `auth` est celui de Supabase.
  SELECT pg_catalog.array_agg(c.column_name::text) INTO v_colonnes
    FROM information_schema.columns c
   WHERE c.table_schema = 'auth' AND c.table_name = 'users'
     AND c.column_name IN ('email', 'phone', 'raw_user_meta_data', 'banned_until');
  IF v_colonnes @> ARRAY['email'] THEN
    v_sets := v_sets || ARRAY['email = ' || pg_catalog.quote_literal('efface-' || p::text || '@invalide.rewayah.invalid')];
  END IF;
  IF v_colonnes @> ARRAY['phone'] THEN
    v_sets := v_sets || ARRAY['phone = NULL'];
  END IF;
  IF v_colonnes @> ARRAY['raw_user_meta_data'] THEN
    v_sets := v_sets || ARRAY['raw_user_meta_data = ''{}''::jsonb'];
  END IF;
  IF v_colonnes @> ARRAY['banned_until'] THEN
    v_sets := v_sets || ARRAY['banned_until = ''infinity''::timestamptz'];
  END IF;
  IF pg_catalog.cardinality(v_sets) > 0 THEN
    EXECUTE pg_catalog.format('UPDATE auth.users SET %s WHERE id = %L',
      pg_catalog.array_to_string(v_sets, ', '), p);
  END IF;
  IF pg_catalog.to_regclass('auth.identities') IS NOT NULL THEN
    EXECUTE pg_catalog.format('DELETE FROM auth.identities WHERE user_id = %L', p);
  END IF;
  IF pg_catalog.to_regclass('auth.sessions') IS NOT NULL THEN
    EXECUTE pg_catalog.format('DELETE FROM auth.sessions WHERE user_id = %L', p);
  END IF;
END;
$function$;

-- La direction traite la demande, double verification exigee.
CREATE FUNCTION public.traiter_demande_suppression(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_d public.demandes_suppression_compte;
  v_sit jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid() AND public.app_aal() = 'aal2', false) THEN
    RAISE EXCEPTION 'traitement reserve a la direction en double verification'
      USING ERRCODE = '42501';
  END IF;
  SELECT d.* INTO v_d FROM public.demandes_suppression_compte d WHERE d.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'demande introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_d.statut <> 'en_attente' THEN
    RAISE EXCEPTION 'demande deja % ', v_d.statut USING ERRCODE = '55000';
  END IF;
  IF v_d.echeance_le > pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'delai de reflexion en cours jusqu''au %', v_d.echeance_le
      USING ERRCODE = '55000';
  END IF;
  v_sit := private.cpt_situation(v_d.profile_id);
  IF (v_sit ->> 'seances_a_venir')::integer > 0 THEN
    RAISE EXCEPTION 'des seances a venir existent : les annuler ou les reattribuer d''abord'
      USING ERRCODE = '55000';
  END IF;

  PERFORM private.cpt_anonymiser(v_d.profile_id);
  UPDATE public.demandes_suppression_compte d
     SET statut = 'traitee', traitee_le = pg_catalog.clock_timestamp(),
         traitee_par = auth.uid(), motif = NULL
   WHERE d.id = p_id
  RETURNING d.* INTO v_d;
  PERFORM public.log_sensitive_access('compte_anonymise', 'demandes_suppression_compte',
    p_id::text, pg_catalog.jsonb_build_object('profil_id', v_d.profile_id));
  RETURN private.cpt_demande_json(v_d);
END;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.cpt_perimetre(uuid)'::regprocedure,
    'private.cpt_admis(uuid)'::regprocedure,
    'private.cpt_situation(uuid)'::regprocedure,
    'private.cpt_demande_json(public.demandes_suppression_compte)'::regprocedure,
    'private.cpt_json_eleve(public.student_profiles)'::regprocedure,
    'private.cpt_anonymiser(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role, agent_ro', v_oid);
  END LOOP;
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_donnees_export()'::regprocedure,
    'public.demander_suppression_compte(text)'::regprocedure,
    'public.annuler_suppression_compte()'::regprocedure,
    'public.ma_situation_suppression()'::regprocedure,
    'public.demandes_suppression_lister()'::regprocedure,
    'public.traiter_demande_suppression(uuid)'::regprocedure] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-18. CPT-SUPPR-EXPORT.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid::text LIKE 'traiter%' THEN 'ROLE_POSITIVE_ADMIN_AAL2'
           WHEN v_oid::text LIKE 'demandes_suppression_lister%' THEN 'ROLE_POSITIVE_ADMIN'
           ELSE 'ROLE_POSITIVE_SELF_ADMITTED' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.mes_donnees_export()'::regprocedure,
    'public.demander_suppression_compte(text)'::regprocedure,
    'public.annuler_suppression_compte()'::regprocedure,
    'public.ma_situation_suppression()'::regprocedure,
    'public.demandes_suppression_lister()'::regprocedure,
    'public.traiter_demande_suppression(uuid)'::regprocedure] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CPT-SUPPR-EXPORT : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'private' AND p.proname LIKE 'cpt\_%'
                AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
                  OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))) THEN
    RAISE EXCEPTION 'CPT-SUPPR-EXPORT : aide privee executable par un client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config WHERE key = 'compte.suppression_delai_jours') THEN
    RAISE EXCEPTION 'CPT-SUPPR-EXPORT : delai de reflexion absent de la configuration';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'public.demandes_suppression_compte', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.demandes_suppression_compte', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.demandes_suppression_compte', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.demandes_suppression_compte', 'DELETE') THEN
    RAISE EXCEPTION 'CPT-SUPPR-EXPORT : droits de table trop larges';
  END IF;
END;
$postflight$;

COMMIT;
