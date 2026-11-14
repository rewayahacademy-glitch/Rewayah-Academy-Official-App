-- INCIDENT-CANDIDATS (14/11/2026) : environ 1700 candidats invites le jour meme.
-- Constats en production (lecture seule, logs 13:30-15:40 UTC) et correctifs :
--
--   1. PIECES D'IDENTITE INVISIBLES POUR LA DIRECTION. 8 pieces deposees le
--      14/11 (kyc_documents, statut pending), dont 7 de candidats en salle 1
--      (etape prequalification). `dossiers_en_attente()` (file ADM-02) ne
--      gardait que les candidatures en salle 2 en cours ou confirmees
--      (`private.candidature_permet_depot_piece`) : la migration 20261119100000
--      a ouvert le depot en salle 1 sans ouvrir la file. Desormais, un candidat
--      de salle 1 entre dans la file des que sa piece est deposee ET visible
--      par le lecteur (`read_kyc_documents()` : cloisonnement de genre et
--      journalisation inchanges). Un candidat de salle 1 sans piece n'y entre
--      toujours pas (pas de file de 1700 lignes vides). `decider_dossier`
--      decide deja la piece d'un candidat sans activer son compte (branche
--      « candidat avant salle 3 »). Le compteur ADM-01 (`indicateurs_admin`)
--      compte les memes personnes que la file (meme regle, meme genre).
--
--   2. RPC APPELEES PAR DES COMPTES CANDIDATS (403 en serie, sans effet pour
--      l'utilisateur mais qui saturent les journaux) :
--        - `mon_horloge()` (x105) : un compte non valide (pending_kyc) recoit
--          l'heure du serveur et celle de l'academie, sans son fuseau
--          (`moi` nul, l'ecran montre l'heure de l'appareil, comme avant) ;
--        - `mon_lieu_a_fournir()` (x80) : un compte non valide n'a pas de ville
--          a fournir (`requis` faux), ce que l'ecran faisait deja sur l'erreur ;
--        - `ma_preference_theme()` (x46) : une session sans profil (candidat
--          avant `inscrire_candidat`) recoit la valeur par defaut de la colonne
--          (`systeme`).
--      Aucune donnee d'un autre compte n'est rendue ; une session anonyme
--      reste refusee.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement. Rejouable :
-- CREATE OR REPLACE a signature identique, les droits EXECUTE sont conserves.

CREATE OR REPLACE FUNCTION public.dossiers_en_attente()
 RETURNS TABLE(profile_id uuid, immutable_id text, first_name text, last_name text, role public.app_role, account_status public.account_status, inscrit_le timestamp with time zone, document_id uuid, doc_type text, document_gender public.gender, object_key text, depose_le timestamp with time zone, etat_piece text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_en_attente integer;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'validation des dossiers reservee a l''administration';
  END IF;

  SELECT count(*) INTO v_en_attente
  FROM public.kyc_documents k
  WHERE k.status = 'pending' AND k.deleted_at IS NULL;

  IF v_en_attente = 0 THEN
    RETURN QUERY
      SELECT
        p.id, p.immutable_id, p.first_name, p.last_name, p.role,
        p.account_status, p.created_at,
        NULL::uuid, NULL::text, NULL::public.gender, NULL::text,
        NULL::timestamptz,
        'aucune'::text
      FROM public.profiles p
      WHERE p.deleted_at IS NULL
        AND p.account_status = 'pending_kyc'
        AND NOT app_private.compte_candidat_hors_portee(p.id)
        AND private.candidature_permet_depot_piece(p.id)
      ORDER BY p.created_at ASC;
    RETURN;
  END IF;

  RETURN QUERY
    WITH visibles AS (
      SELECT k.*
      FROM public.read_kyc_documents() k
      WHERE k.status = 'pending'
    )
    SELECT
      p.id, p.immutable_id, p.first_name, p.last_name, p.role,
      p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      CASE
        WHEN v.id IS NOT NULL THEN 'a_verifier'
        WHEN EXISTS (
          SELECT 1 FROM public.kyc_documents k2
          WHERE k2.profile_id = p.id
            AND k2.status = 'pending'
            AND k2.deleted_at IS NULL
        ) THEN 'non_visible'
        ELSE 'aucune'
      END::text
    FROM public.profiles p
    LEFT JOIN visibles v ON v.profile_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p.account_status = 'pending_kyc' OR v.id IS NOT NULL)
      AND NOT app_private.compte_candidat_hors_portee(p.id)
      -- INCIDENT-CANDIDATS : une piece deposee et visible fait entrer le
      -- candidat de salle 1 dans la file.
      AND (v.id IS NOT NULL OR private.candidature_permet_depot_piece(p.id))
    ORDER BY coalesce(v.created_at, p.created_at) ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.indicateurs_admin()
 RETURNS TABLE(dossiers_en_attente integer, foyers_sans_enseignant integer, rapports_manquants integer, incidents_24h integer, comptes_echus integer, demandes_en_attente integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    -- Des **personnes** en attente de validation, plus des documents deposes.
    -- L'ancien compte lisait `kyc_documents where status='pending'` et
    -- affichait donc zero pendant que trois enseignants attendaient.
    -- CAND-L1B : un compte candidat de l'autre cote, ou en salle d'examen,
    -- n'est pas compte.
    -- INCIDENT-CANDIDATS : sauf s'il a depose une piece visible du lecteur
    -- (la meme regle que la file `dossiers_en_attente`).
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'
        and not app_private.compte_candidat_hors_portee(p.id)
        and (private.candidature_permet_depot_piece(p.id)
             or exists (
               select 1 from public.kyc_documents k
                where k.profile_id = p.id
                  and k.status = 'pending'
                  and k.deleted_at is null
                  and (public.kyc_super_admin_exception_active()
                       or k.gender = (select r.gender from public.profiles r
                                       where r.id = auth.uid() and r.deleted_at is null))))),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$function$;

CREATE OR REPLACE FUNCTION public.mon_horloge()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_fuseau text;
  v_role text;
  v_foyer uuid;
  v_choisi boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'horloge non autorisee' USING ERRCODE = '42501';
  END IF;
  -- INCIDENT-CANDIDATS : un compte non valide (candidat pending_kyc) recoit
  -- l'heure du serveur et de l'academie, rien de son profil.
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RETURN pg_catalog.jsonb_build_object(
      'maintenant', pg_catalog.now(),
      'moi', NULL,
      'academie', private.fuseau_info(private.fuseau_academie()));
  END IF;
  -- Le meme ordre que public.mon_fuseau(), sans son repli sur Paris : un
  -- profil sans fuseau ne recoit pas une ville inventee.
  SELECT nullif(pg_catalog.btrim(h.timezone), '') INTO v_fuseau
    FROM public.households h
   WHERE h.id = public.app_household_id() AND h.deleted_at IS NULL;
  IF v_fuseau IS NULL THEN
    SELECT nullif(pg_catalog.btrim(tp.timezone_iana), '') INTO v_fuseau
      FROM public.teacher_profiles tp
     WHERE tp.profile_id = auth.uid() AND tp.deleted_at IS NULL;
  END IF;
  -- HORLOGE-ET-LIEU (partie B) : la ville a-t-elle ete CHOISIE ? Le fuseau par
  -- defaut (Paris) n'est pas un choix : sans ville choisie, l'ecran affiche l'heure
  -- de l'appareil et le dit.
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NOT NULL THEN
    SELECT EXISTS (SELECT 1 FROM public.lieux l
                    WHERE (v_role = 'guardian' AND l.foyer_id = v_foyer)
                       OR (v_role = 'teacher' AND l.profil_id = auth.uid()))
      INTO v_choisi;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'maintenant', pg_catalog.now(),
    'moi', private.fuseau_info(v_fuseau),
    'academie', private.fuseau_info(private.fuseau_academie()),
    'lieu_choisi', v_choisi);
END;
$function$;

CREATE OR REPLACE FUNCTION public.mon_lieu_a_fournir()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_role text;
  v_foyer uuid;
  v_max integer := public.app_config_int('lieu_reports_max', 3);
  v_pris integer;
  v_a_un boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'lieu non autorise' USING ERRCODE = '42501';
  END IF;
  -- INCIDENT-CANDIDATS : un compte non valide (candidat pending_kyc) n'a pas
  -- de ville a fournir.
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RETURN pg_catalog.jsonb_build_object('requis', false, 'reports_restants', 0, 'reports_max', v_max);
  END IF;
  SELECT p.p_role, p.p_foyer INTO v_role, v_foyer FROM private.proprietaire_lieu() p;
  IF v_role IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('requis', false, 'reports_restants', 0, 'reports_max', v_max);
  END IF;
  SELECT EXISTS (SELECT 1 FROM public.lieux l
                  WHERE (v_role = 'guardian' AND l.foyer_id = v_foyer)
                     OR (v_role = 'teacher' AND l.profil_id = auth.uid()))
    INTO v_a_un;
  IF v_a_un THEN
    RETURN pg_catalog.jsonb_build_object('requis', false, 'reports_restants', 0, 'reports_max', v_max);
  END IF;
  SELECT coalesce(pg_catalog.max(r.reports), 0) INTO v_pris
    FROM private.lieux_reports r WHERE r.profil_id = auth.uid();
  RETURN pg_catalog.jsonb_build_object(
    'requis', true, 'reports_restants', greatest(v_max - v_pris, 0), 'reports_max', v_max);
END;
$function$;

CREATE OR REPLACE FUNCTION public.ma_preference_theme()
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_theme text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'acces refuse' USING ERRCODE = '42501';
  END IF;
  SELECT p.preference_theme INTO v_theme
    FROM public.profiles p
   WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  IF NOT FOUND THEN
    -- INCIDENT-CANDIDATS : une session sans profil (candidat avant son
    -- inscription) recoit la valeur par defaut de la colonne.
    RETURN 'systeme';
  END IF;
  RETURN v_theme;
END;
$function$;
