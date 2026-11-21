-- PERSONNES-PERF, seconde migration (installable seule, sans 20261130968000) : deux lectures des pages « Personnes » du
-- bureau de la direction rendent la meme reponse en faisant moins de travail.
--
-- MESURE (production, lecture seule, 20/11/2026) :
--   * lister_candidatures (liste des candidatures, chaque page et chaque filtre) : 820 ms en moyenne depuis le 15/11
--     (1 229 appels, 18 215 blocs par appel), p95 de 4,2 s sur 24 h. Le compteur « bloquees » (compteursAlertes) calcule
--     TOUS les controles de salle 3 (paiement, quatre accords, questionnaire, entretien, evaluation, profil, restriction,
--     piece, complement) de chaque candidature en verifications (174 en production) pour n'en lire que deux :
--     paiement_compatible et profil_unique.
--   * comptes_admin_par_role (onglets Eleves, Familles, Enseignants, Direction de « Comptes ») : 557 ms en moyenne,
--     700 comptes d'un coup ; public.agent_identite_masquee() y est evaluee quatre fois par ligne (2 928 appels pour 732
--     comptes sur la base fictive, 40 % du temps).
--
-- CE QUI CHANGE :
--   1. private.perf_bloquee_salle3(c) : les deux controles lus par le compteur, et eux seuls, recopies a l'identique de
--      private.candidature_controles_salle3 (corps ed849b42..., controle par empreinte) : paiement_compatible faux ou
--      inconnu (private.paiement_etat <> 'compatible'), ou profil_unique en defaut (la meme cascade CASE). lister_candidatures
--      l'appelle a la place de candidature_controles_salle3 dans ce seul compteur ; le reste du corps (celui de
--      20261130930000, empreinte 8aa4dafe...) est recopie a l'identique. Une difference possible et une seule : si un des
--      SEPT autres controles levait une erreur, la liste echouait ; elle ne lit plus ces controles et n'echoue plus.
--   2. comptes_admin_par_role : (select public.agent_identite_masquee()) au lieu de public.agent_identite_masquee() aux
--      quatre endroits ; la sous-requete sans correlation est evaluee une fois par appel (la fonction est STABLE et ne
--      depend que du jeton de l'appelant). Corps installe (empreinte 34afbc25..., celui de 20261101100000) recopie a l'identique sinon.
-- Les deux fonctions gardent leur signature, leur volatilite (VOLATILE pour lister_candidatures, qui ecrit son journal
-- d'acces ; STABLE pour comptes_admin_par_role), SECURITY DEFINER, search_path vide, proprietaire et droits (EXECUTE a
-- authenticated seulement) : CREATE OR REPLACE les conserve, le controle final le verifie. La forme des reponses ne
-- change pas : prouve sur une base fictive a l'echelle (avant / apres identiques, supabase/tests/perf/).
-- MOTS D'EFFACEMENT : zero. Aucune donnee n'est ecrite. Rien n'est allume.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('public.lister_candidatures(jsonb,text,integer)', '8aa4dafe8707558107510d1dedb08313'),
      ('public.comptes_admin_par_role()', '34afbc25a0d5f33fa4f7d38431fa9d97'),
      ('private.candidature_controles_salle3(public.candidatures)', 'ed849b42ab0099c9622709b8cfd13753'),
      ('private.paiement_etat(uuid)', 'b788258e3abd65649615d9dbeec6f88d')) AS t(f, md5) LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % absente ; rien n''est modifie', v.f;
    END IF;
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
         WHERE p.oid = pg_catalog.to_regprocedure(v.f)) IS DISTINCT FROM v.md5 THEN
      IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                             WHERE p.oid = pg_catalog.to_regprocedure(v.f)), 'PERSONNES-PERF') > 0 THEN
        RAISE EXCEPTION 'PERSONNES-PERF : deja installe ; rien n''est modifie';
      END IF;
      RAISE EXCEPTION 'PERSONNES-PERF : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  IF pg_catalog.to_regprocedure('private.perf_bloquee_salle3(public.candidatures)') IS NOT NULL THEN
    RAISE EXCEPTION 'PERSONNES-PERF : private.perf_bloquee_salle3 existe deja ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Les deux controles de salle 3 lus par le compteur « bloquees », recopies de candidature_controles_salle3.
CREATE FUNCTION private.perf_bloquee_salle3(c public.candidatures)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_paiement text;
  v_unique text;
  v_p public.profiles;
BEGIN
  -- paiement_compatible : valeur = (paiement_etat = 'compatible'), lue par coalesce(valeur, false).
  v_paiement := private.paiement_etat(c.id);
  IF NOT coalesce(v_paiement = 'compatible', false) THEN
    RETURN true;
  END IF;
  -- profil_unique : valeur = (v_unique IS NULL), la meme cascade.
  SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = c.profile_id;
  v_unique := CASE
    WHEN v_p.id IS NULL OR v_p.deleted_at IS NOT NULL THEN 'compte_absent'
    WHEN v_p.role IS DISTINCT FROM 'teacher'::public.app_role THEN 'role'
    WHEN v_p.account_status IS DISTINCT FROM 'pending_kyc'::public.account_status THEN 'statut'
    WHEN v_p.gender IS NULL THEN 'genre_inconnu'
    WHEN NOT EXISTS (SELECT 1 FROM public.teacher_profiles tp
                      WHERE tp.profile_id = v_p.id AND tp.deleted_at IS NULL) THEN 'profil_enseignant_absent'
    WHEN EXISTS (SELECT 1 FROM public.candidatures o
                  WHERE o.profile_id = c.profile_id AND o.id <> c.id
                    AND o.type_code = c.type_code AND o.issue = 'en_cours') THEN 'autre_candidature'
  END;
  RETURN v_unique IS NOT NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.perf_bloquee_salle3(public.candidatures) FROM PUBLIC, anon, authenticated;

-- 2. La liste des candidatures (corps de 20261130930000, ce seul compteur change).
CREATE OR REPLACE FUNCTION public.lister_candidatures(p_filtre jsonb DEFAULT '{}'::jsonb, p_tri text DEFAULT 'activite'::text, p_page integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
  v_type text;
  v_etape text;
  v_etat text;
  v_issue text;
  v_pause boolean;
  v_paiement text;
  v_pays text;
  v_comp_domaine text;
  v_comp_codes text[];
  v_comp_niveau text;
  v_comp_dispo text;
  v_comp_accord boolean;
  v_comp boolean;
  v_recherche text;
  v_recherche_nom text;
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
  v_etapes jsonb;
  v_alertes jsonb;
BEGIN
  IF NOT coalesce((public.app_role() = 'admin' OR private.mission_porteuse()) AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.mission_acteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;

  -- Le filtre : un objet, des cles connues, des valeurs du bon type.
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre de candidatures invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['type', 'etape', 'etat', 'issue', 'enPause', 'paiement',
                            'paysResidence', 'recherche', 'competenceDomaine', 'genre',
                            'competenceNiveauMin', 'competenceDisponibilite', 'competenceAccord',
                            'ijaza', 'langueExplication', 'riwaya', 'public', 'jours',
                            'heureMin', 'heureMax', 'joursMin', 'pieceEnAttente', 'responsable',
                            'majorite', 'nouveau', 'dossierComplet', 'pilePraxis', 'etiquettePraxis']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'competenceAccord', 'pieceEnAttente', 'nouveau', 'dossierComplet') THEN 'boolean'
                WHEN e.key IN ('heureMin', 'heureMax', 'joursMin') THEN 'number'
                WHEN e.key = 'jours' THEN 'array' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;

  PERFORM private.be_filtre_valider(v_filtre);
  -- PE-LISTE-CANDIDATURES : dossier complet, pile et etiquette de Praxis.
  PERFORM private.pelc_filtre_valider(v_filtre);
  v_type := v_filtre ->> 'type';
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pause := (v_filtre ->> 'enPause')::boolean;
  v_paiement := v_filtre ->> 'paiement';
  v_pays := v_filtre ->> 'paysResidence';
  -- SALLE2-GENRE : male ou female seulement.
  IF v_filtre ->> 'genre' IS NOT NULL AND v_filtre ->> 'genre' NOT IN ('male', 'female') THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : genre' USING ERRCODE = '22023';
  END IF;
  v_comp_domaine := v_filtre ->> 'competenceDomaine';
  v_comp_niveau := v_filtre ->> 'competenceNiveauMin';
  v_comp_dispo := v_filtre ->> 'competenceDisponibilite';
  v_comp_accord := (v_filtre ->> 'competenceAccord')::boolean;
  v_comp := coalesce(v_comp_domaine, v_comp_niveau, v_comp_dispo) IS NOT NULL OR v_comp_accord IS NOT NULL;
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');

  -- CAND-L2A2 (D15) : l'etat paiement_non_disponible de L6 se filtre.
  IF (v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.candidature_types t WHERE t.code = v_type))
     OR (v_etape IS NOT NULL AND v_etape NOT IN
        ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_paiement IS NOT NULL AND v_paiement NOT IN
        ('inconnu', 'compatible', 'incompatible', 'a_verifier'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR (v_comp_domaine IS NOT NULL AND NOT (
           v_comp_domaine = ANY (private.competences_codes('familles'))
           OR EXISTS (SELECT 1 FROM public.competences_catalogue k WHERE k.code = v_comp_domaine)))
     OR (v_comp_niveau IS NOT NULL AND v_comp_niveau <> ALL (private.competences_codes('niveaux')))
     OR (v_comp_dispo IS NOT NULL AND v_comp_dispo <> ALL (private.competences_codes('disponibilites')))
     OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre de candidatures invalide' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('activite', 'recente', 'nom', 'ancienne') THEN
    RAISE EXCEPTION 'tri de candidatures invalide : activite, recente, nom ou ancienne' USING ERRCODE = '22023';
  END IF;
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page de candidatures invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;
  -- Une recherche faite seulement de signes ne rapproche aucun nom (C3).
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');
  -- Un code du catalogue ou une famille : les codes cherches, actifs ou non
  -- (une reponse ancienne reste cherchable, C12).
  IF v_comp_domaine IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(k.code), ARRAY[]::text[]) INTO v_comp_codes
      FROM public.competences_catalogue k
     WHERE k.code = v_comp_domaine OR k.famille = v_comp_domaine;
  END IF;

  -- La portee (genre ou exception super-admin) et les filtres, dans le WHERE.
  -- Le courriel cherche est le courriel valide seulement, jamais le brut (C9).
  WITH filtrees AS MATERIALIZED (
    SELECT c AS ligne,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN c.derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN c.recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN coalesce(c.nom_latin, c.nom_complet) END ASC,
             -- PE-LISTE-CANDIDATURES : celle qui attend depuis le plus longtemps d'abord.
             CASE WHEN p_tri = 'ancienne' THEN c.derniere_activite END ASC,
             c.id ASC) AS rang
    FROM public.candidatures c
    WHERE (v_super OR c.genre = v_genre) AND ((SELECT private.mission_est_direction())
                                                              OR private.mission_droit_dossier(c.id, 'lire'))
      AND (CASE WHEN v_type IS NULL THEN c.type_code NOT IN ('famille', 'eleve_adulte') ELSE c.type_code = v_type END)
      AND (v_etape IS NULL OR c.etape = v_etape)
      AND (v_etat IS NULL OR c.etat = v_etat)
      AND (v_issue IS NULL OR c.issue = v_issue)
      AND (v_pause IS NULL OR c.en_pause = v_pause)
      AND (v_paiement IS NULL OR c.paiement = v_paiement)
      AND (v_pays IS NULL OR c.pays_residence = v_pays)
      AND (v_filtre ->> 'genre' IS NULL OR c.genre::text = v_filtre ->> 'genre')
      AND (NOT (v_filtre ?| ARRAY['ijaza', 'langueExplication', 'riwaya', 'public', 'jours',
                                  'heureMin', 'heureMax', 'joursMin', 'pieceEnAttente', 'responsable', 'majorite', 'nouveau'])
           OR private.be_predicat(c, v_filtre, v_lecteur))
      AND (NOT (v_filtre ?| ARRAY['dossierComplet', 'pilePraxis', 'etiquettePraxis'])
           OR private.pelc_predicat(c, v_filtre))
      AND (NOT v_comp OR EXISTS (
             SELECT 1 FROM public.candidature_autres_competences a
              WHERE a.candidature_id = c.id
                AND (v_comp_accord IS NULL OR a.accord_contact = v_comp_accord)
                AND (v_comp_dispo IS NULL OR a.disponibilite = v_comp_dispo)
                AND ((v_comp_domaine IS NULL AND v_comp_niveau IS NULL) OR EXISTS (
                       SELECT 1 FROM pg_catalog.jsonb_each_text(a.domaines) d
                        WHERE (v_comp_domaine IS NULL OR d.key = ANY (v_comp_codes))
                          AND (v_comp_niveau IS NULL
                               OR private.competences_rang_niveau(d.value)
                                  >= private.competences_rang_niveau(v_comp_niveau))))))
      AND (v_recherche IS NULL
           OR c.reference = pg_catalog.upper(v_recherche)
           OR (((SELECT private.mission_est_direction()) OR private.mission_droit_dossier(c.id, 'voir_contact'))
                AND EXISTS (SELECT 1 FROM public.candidature_contacts k
                      WHERE k.candidature_id = c.id
                        AND k.courriel = pg_catalog.lower(v_recherche)))
           OR (v_recherche_nom IS NOT NULL
               AND (pg_catalog.strpos(private.cand_normaliser(c.nom_complet), v_recherche_nom) > 0
                    OR pg_catalog.strpos(private.cand_normaliser(c.nom_latin), v_recherche_nom) > 0)))
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.ligne).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(private.cand_ligne_json(f.ligne) ORDER BY f.rang)
                    FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50),
                  '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
  FROM filtrees f;

  -- Les compteurs : toute la portee, sans les autres filtres. CAND-L2A2
  -- (D15) : un complement en cours en salle 2 compte dans les informations
  -- manquantes, comme a_completer en salle 1.
  SELECT pg_catalog.jsonb_build_object(
           'recue', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'recue'),
           'invitee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'invitee'),
           'prequalification', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'prequalification'),
           'verifications', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'verifications'),
           'confirmee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'confirmee')),
         pg_catalog.jsonb_build_object(
           'informationsManquantes', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause
               AND (c.etat = 'a_completer'
                    OR CASE WHEN c.etape = 'verifications'
                            THEN pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
                            ELSE false END)),
           'confirmeesIndisponibles', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause AND c.etape = 'confirmee'
               AND private.cand_indisponible(c)),
           'entretiensEnRetard', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause
               AND ((c.etat = 'entretien_planifie'
                     AND EXISTS (
                       SELECT 1
                         FROM (SELECT e.session_id, e.issue
                                 FROM public.entretiens e
                                WHERE e.candidature_id = c.id
                                ORDER BY e.planifie_le DESC
                                LIMIT 1) d
                         JOIN public.sessions s ON s.id = d.session_id
                        WHERE (d.issue IS NULL OR d.issue = 'tenu')
                          AND s.ended_at < pg_catalog.now() - interval '24 hours'
                          AND NOT EXISTS (SELECT 1 FROM public.entretien_comptes_rendus r
                                           WHERE r.session_id = d.session_id)))
                    OR (c.etat = 'entretien_a_planifier'
                        AND coalesce(
                              (SELECT pg_catalog.max(ev.cree_le)
                                 FROM public.candidature_evenements ev
                                WHERE ev.candidature_id = c.id
                                  AND ev.etat_apres = 'entretien_a_planifier'),
                              c.derniere_activite)
                            < pg_catalog.now() - pg_catalog.make_interval(days => (
                                SELECT CASE WHEN pg_catalog.jsonb_typeof(a.value) = 'number'
                                                 AND (a.value #>> '{}')::numeric >= 0
                                            THEN pg_catalog.floor((a.value #>> '{}')::numeric)::integer
                                       END
                                  FROM public.app_config a
                                 WHERE a.key = 'cand_entretien_a_planifier_jours')))))::integer,
           'bloquees', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause
               AND (coalesce(c.restreinte, false)
                    -- PERSONNES-PERF : les deux seuls controles de salle 3 lus ici,
                    -- sans calculer les sept autres (meme valeur, 20261130968500).
                    OR CASE WHEN c.etape = 'verifications'
                            THEN private.perf_bloquee_salle3(c)
                            ELSE false END))::integer)
    INTO v_etapes, v_alertes
  FROM public.candidatures c
  WHERE (v_super OR c.genre = v_genre) AND ((SELECT private.mission_est_direction())
                                                              OR private.mission_droit_dossier(c.id, 'lire'));

  PERFORM public.log_sensitive_access('candidatures_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page,
      'recherche', v_recherche IS NOT NULL,
      'competences', v_comp));

  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'total', v_total,
    'page', p_page,
    'taillePage', 50,
    'compteursEtapes', v_etapes,
    'compteursAlertes', v_alertes,
    'compteurNouveaux', (SELECT pg_catalog.count(*)::integer FROM public.candidatures c
                         WHERE (v_super OR c.genre = v_genre) AND ((SELECT private.mission_est_direction())
                                                              OR private.mission_droit_dossier(c.id, 'lire')) AND c.issue = 'en_cours'
                           AND c.type_code NOT IN ('famille', 'eleve_adulte')
                           AND private.be_nouvelle(c)));
END;
$function$;

-- 3. Les comptes par role (corps installe, agent_identite_masquee evaluee une fois).
CREATE OR REPLACE FUNCTION public.comptes_admin_par_role()
 RETURNS TABLE(profile_id uuid, immutable_id text, prenom text, nom text, role public.app_role, etat_compte public.account_status, inscrit_le timestamp with time zone, acces_jusqu_au timestamp with time zone, foyer_id uuid, etat_piece text, contrats integer, a_enseignant boolean, enfants_du_foyer integer, teacher_country text, tranche_age text, classe_id uuid, classe_libelle text, classe_numero integer, classes_actives integer, tuteur_id uuid, tuteur_prenom text, tuteur_nom text, admission_a_traiter boolean, est_apprenant boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with numeros as materialized (
    select n.groupe_id, n.numero from app_private.classes_numerotees() n
  )
  select
    p.id,
    p.immutable_id,
    case when (select public.agent_identite_masquee()) then null else p.first_name end,
    case when (select public.agent_identite_masquee()) then null else p.last_name end,
    p.role,
    p.account_status,
    p.created_at,
    p.access_until,
    p.household_id,
    case
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'pending' and k.deleted_at is null
      ) then 'a_verifier'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'approved' and k.deleted_at is null
      ) then 'validee'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'rejected' and k.deleted_at is null
      ) then 'refusee'
      else 'aucune'
    end::text,
    (select count(*)::int from public.contract_acceptances c where c.profile_id = p.id),
    exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p.id and a.ended_at is null
    ),
    (select count(*)::int from public.profiles e
      where e.household_id = p.household_id
        and e.role = 'student' and e.deleted_at is null),
    case when p.role = 'teacher' then tp.country end,
    case when (p.role = 'student' or (p.role = 'guardian' and sp.student_type = 'autonomous')) then
      case sp.student_type when 'minor' then 'enfant' when 'autonomous' then 'adulte' end
    end,
    cl.groupe_id,
    cl.libelle,
    cl.numero,
    case when (p.role = 'student' or (p.role = 'guardian' and sp.student_type = 'autonomous')) then
      (select count(*)::int from public.groupe_membres m
         join public.groupes g on g.id = m.groupe_id
        where m.student_id = p.id and m.left_at is null and g.ended_at is null)
    end,
    tu.id,
    case when (select public.agent_identite_masquee()) then null else tu.first_name end,
    case when (select public.agent_identite_masquee()) then null else tu.last_name end,
    exists (
      select 1 from public.candidatures ca
      where ca.profile_id = p.id
        and ca.type_code in ('famille', 'eleve_adulte')
        and ca.issue = 'en_cours'
        and ca.etape = 'recue'
    ),
    coalesce((p.role = 'student' or (p.role = 'guardian' and sp.student_type = 'autonomous')), false)
  from public.profiles p
  left join public.teacher_profiles tp on tp.profile_id = p.id and tp.deleted_at is null
  left join public.student_profiles sp on sp.profile_id = p.id and sp.deleted_at is null
  left join lateral (
    select g.id as groupe_id, g.libelle, n.numero
      from public.groupe_membres m
      join public.groupes g on g.id = m.groupe_id
      left join numeros n on n.groupe_id = g.id
     where (p.role = 'student' or (p.role = 'guardian' and sp.student_type = 'autonomous'))
       and m.student_id = p.id and m.left_at is null and g.ended_at is null
     order by m.joined_at, g.id
     limit 1
  ) cl on true
  left join lateral (
    select t.id, t.first_name, t.last_name
      from public.profiles t
      left join public.households h on h.id = p.household_id
     where p.role = 'student'
       and t.household_id = p.household_id
       and t.role = 'guardian'
       and t.deleted_at is null
     order by (t.id = h.primary_guardian_id) desc, t.created_at, t.id
     limit 1
  ) tu on true
  where p.deleted_at is null
    and public.app_role() = 'admin'
    and public.app_account_valid()
    and not app_private.compte_candidat_hors_portee(p.id)
    and not exists (select 1 from private.comptes_officiels co where co.profile_id = p.id)
  order by
    case p.account_status
      when 'pending_kyc' then 0
      when 'provisional_active' then 1
      else 2
    end,
    p.created_at asc;
$function$;

-- Controle final.
DO $controle$
DECLARE
  v record;
  v_role text;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('public.lister_candidatures(jsonb,text,integer)', 'v', 'perf_bloquee_salle3(c)'),
      ('public.comptes_admin_par_role()', 's', '(select public.agent_identite_masquee())')) AS t(f, vol, marque) LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p
          WHERE p.oid = pg_catalog.to_regprocedure(v.f)
            AND p.provolatile = v.vol AND p.prosecdef AND p.proowner = 'postgres'::regrole
            AND p.proconfig = ARRAY['search_path=""']
            AND p.proacl::text = '{postgres=X/postgres,authenticated=X/postgres}'
            AND pg_catalog.strpos(p.prosrc, v.marque) > 0) THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % : volatilite, securite, proprietaire, search_path, droits ou corps inattendus', v.f;
    END IF;
    IF has_function_privilege('anon', v.f, 'EXECUTE') THEN
      RAISE EXCEPTION 'PERSONNES-PERF : anon peut executer %', v.f;
    END IF;
  END LOOP;
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = pg_catalog.to_regprocedure('public.lister_candidatures(jsonb,text,integer)')),
                       'candidature_controles_salle3') > 0 THEN
    RAISE EXCEPTION 'PERSONNES-PERF : lister_candidatures lit encore tous les controles de salle 3';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = pg_catalog.to_regprocedure('private.perf_bloquee_salle3(public.candidatures)')
                    AND p.provolatile = 's' AND NOT p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig = ARRAY['search_path=""'] AND p.proacl::text = '{postgres=X/postgres}') THEN
    RAISE EXCEPTION 'PERSONNES-PERF : private.perf_bloquee_salle3 inattendue';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF has_function_privilege(v_role, 'private.perf_bloquee_salle3(public.candidatures)', 'EXECUTE') THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % peut executer private.perf_bloquee_salle3', v_role;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = pg_catalog.to_regprocedure('private.candidature_controles_salle3(public.candidatures)'))
     IS DISTINCT FROM 'ed849b42ab0099c9622709b8cfd13753' THEN
    RAISE EXCEPTION 'PERSONNES-PERF : candidature_controles_salle3 ne doit pas changer';
  END IF;
END
$controle$;
