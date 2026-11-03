-- SNT (03/11/2026) : seance non tenue a T+30, report et nouvelle date.
--
-- Decision du directeur du 03/11 (08 §5 bis), mot pour mot : « Mais arrive a
-- 30 min ce n'est plus la peine, la seance est repousse, l'academie devra la
-- rembourser. Mais si ca coincide que l'eleve aussi s'est absente lors de la
-- meme seance lui il paie toujours » puis « La seance est rattrape avec
-- l'enseignant apres, pas remboursee. Il n'y a pas de remboursement en argent
-- comptant sauf ce qui est decrit dans la politique tarifaire exige par la
-- loi ».
--
-- Fichier SANS mot d'effacement (B5) : le pilote l'installe. Additif (B6) :
-- un reglage, une table, trois fonctions nouvelles, quatre fonctions
-- retouchees par ancre (pg_temp.remplacer, B4), rien de retire, aucune
-- signature changee.
--
-- ORDRE D'INSTALLATION :
--   1. fonctions Edge courriels-envoi (modeles seance_reportee et
--      seance_reportee_direction) et create-room-token (motif seance_reportee) ;
--   2. 20261106500001_snt_evenement_notification.sql (fichier B5, colle par le
--      directeur) : l'evenement « seance_reportee » dans
--      notifications_evenement_check ;
--   3. ce fichier.
-- Sans l'etape 2, le passage de chaque minute leve une erreur par seance a
-- reporter (attrapee, comptee dans « erreurs ») et ne reporte rien : la
-- seance reste a la cloture automatique d'apres (ses_cloture_auto). L'ordre
-- 1-2-3 evite cette fenetre ; ce fichier verifie la contrainte en postflight.
--
-- 1. Reglage remplacement.seance_non_tenue_minutes = 30 (le directeur :
--    « arrive a 30 min »). Valide par private.reglages_remplacement_valider :
--    entier de 0 a 999, et ordre impose
--      avertissement (3) < perte (8) < debut_remplacant (11) < non_tenue (30),
--    tous comptes depuis le debut de la seance. Le postflight rejoue la
--    validation sur les valeurs en place.
-- 2. public.seances_reportees : une ligne par seance non tenue (session_id
--    unique), creee par le passage de chaque minute, close une seule fois par
--    la direction quand elle fixe la nouvelle date (seance_nouvelle_id
--    unique). RLS activee, aucune policy ni aucun droit client : lue par
--    lister_seances_reportees, ecrite par les seules fonctions DEFINER.
-- 3. private.remplacement_auto_passer, etape e (meme tache cron, chaque
--    minute) : a debut + seance_non_tenue, si ni le titulaire ni le remplacant
--    pris n'est entre (private.snt_enseignant_entre, qui lit
--    private.a3bis_premier_entre : un seul sens de « enseignant entre »),
--    sous le verrou de la seance (celui sous lequel autoriser_jeton_video emet
--    le jeton enseignant, A3-bis), revu apres le verrou :
--      - la seance passe en teacher_absent (guard_session_state_transition
--        l'admet depuis planned, preflight, et in_progress sans arrivee) ;
--      - une ligne seances_reportees (ON CONFLICT DO NOTHING : rejouer le
--        passage ne cree rien) ;
--      - la classe est prevenue par private.notifier_classe('seance_reportee'),
--        avec le remplacant pris s'il y en a un ;
--      - la direction recoit un e-mail par le chemin d'A3-bis (memes
--        destinataires que l'alerte remplacement_personne_en_salle,
--        courriel_enfiler, cle 'snt-report:<seance>:<destinataire>').
--    L'appel aux remplacants se ferme par le statut : prendre_remplacement et
--    se_declarer_pret_remplacement exigent planned, preflight ou in_progress.
-- 4. public.autoriser_jeton_video : apres le verrou, une seance reportee ne
--    s'ouvre plus (« seance reportee ») ; public.motif_refus_salle rend
--    'seance_reportee' a l'enseignant (titulaire ou remplacant) et a tout
--    participant ou tuteur qui y avait droit.
-- 5. public.fixer_nouvelle_date_seance(p_report, p_debut) : geste « Fixer la
--    nouvelle date » du planning de la direction. Garde des RPC de planning de
--    la direction (C1, creer_classe_creneaux_admin) : app_account_valid() et
--    app_role() = 'admin', sans aal2. Cree UNE seance de la meme classe, avec
--    le meme enseignant titulaire et la meme duree que la seance reportee, et
--    ses participants (membres actifs de la classe), par le meme INSERT que
--    public.materialiser_seances_groupe. Chevauchement de l'enseignant : le
--    refus de C1 (« chevauchement avec une séance existante », DETAIL JSON lu
--    par lib/core/admin/creation_classe_refusee.dart), et le 23P01 de
--    sessions_no_teacher_overlap rendu sous la meme forme. Puis la classe est
--    prevenue par notifier_classe('seance_deplacee') a la nouvelle date.
-- 6. public.lister_seances_reportees() : les seances reportees sans nouvelle
--    date, pour le planning de la direction (meme garde).
--
-- Argent : rien. Aucune ecriture dans tresorerie_mouvements, wallet_entries,
-- payouts. Une seance teacher_absent n'est jamais payee a l'enseignant :
--   - x217_sessions_cloture_tresorerie n'appelle remuneration_due_seance que
--     pour ended et tech_failure (20261012120101_x2_17_treasury_triggers.sql:400) ;
--   - private.pai_due_seance rend NULL hors ended et tech_failure
--     (20261102900000_presence_minutes.sql:258) ;
--   - le releve de paie ne lit que ended et tech_failure
--     (20261102900000_presence_minutes.sql:359).
-- La nouvelle seance est une seance normale : payee normalement a sa cloture.
-- Un eleve absent a la seance reportee reste membre de la classe : il est
-- dans la nouvelle seance, comme les autres ; rien n'est ecrit pour lui.
--
-- ses_cloturer_seances_echues ne relit pas une seance teacher_absent (son
-- filtre : planned, preflight, in_progress) : pas de second traitement, pas de
-- seconde notification.
--
-- Lecteurs (B1) : aucune colonne existante ne change de sens. Le statut
-- teacher_absent existait deja (cloture automatique) ; il est seulement pose
-- plus tot. Lecteurs du statut recenses : indicateurs_admin,
-- etat_presence, lister_incidents_seances (le comptent comme une absence de
-- l'enseignant, ce qu'il est), guard_session_state_transition,
-- ses_cloturer_seances_echues (l'ignore).
-- Mots d'effacement dans ce fichier : aucun.

BEGIN;

INSERT INTO public.app_config (key, value)
VALUES ('remplacement.seance_non_tenue_minutes', '30'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 1. La validation des reglages : la nouvelle cle, et son ordre.
-- ---------------------------------------------------------------------------
-- 1a. La cle est validee (entier de 0 a 999).
SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$                     'remplacement.seance_tardive_minutes') THEN
    RETURN NEW;
  END IF;$a$,
  $b$                     'remplacement.seance_tardive_minutes',
                     -- SNT (03/11/2026).
                     'remplacement.seance_non_tenue_minutes') THEN
    RETURN NEW;
  END IF;$b$, 1);

-- 1b. Sa valeur en vigueur, lue avec les trois autres.
SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$  v_objectif integer;
BEGIN$a$,
  $b$  v_objectif integer;
  v_non_tenue integer;
BEGIN$b$, 1);
SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$  CASE NEW.key
    WHEN 'remplacement.avertissement_minutes' THEN v_avert := v_n::integer;
    WHEN 'remplacement.perte_acces_minutes' THEN v_perte := v_n::integer;
    ELSE v_objectif := v_n::integer;
  END CASE;$a$,
  $b$  -- SNT : la seance non tenue, apres le remplacant dans la salle.
  SELECT (c.value #>> '{}')::integer INTO v_non_tenue
    FROM public.app_config c
   WHERE c.key = 'remplacement.seance_non_tenue_minutes'
     AND c.key <> NEW.key
     AND pg_catalog.jsonb_typeof(c.value) = 'number'
     AND (c.value #>> '{}') ~ '^[0-9]{1,3}$';
  CASE NEW.key
    WHEN 'remplacement.avertissement_minutes' THEN v_avert := v_n::integer;
    WHEN 'remplacement.perte_acces_minutes' THEN v_perte := v_n::integer;
    WHEN 'remplacement.debut_remplacant_minutes' THEN v_objectif := v_n::integer;
    ELSE v_non_tenue := v_n::integer;
  END CASE;$b$, 1);

-- 1c. L'ordre : le remplacant dans la salle avant la seance non tenue.
SELECT pg_temp.remplacer('private.reglages_remplacement_valider()',
  $a$  RETURN NEW;
END;$a$,
  $b$  IF v_objectif IS NOT NULL AND v_non_tenue IS NOT NULL AND v_objectif >= v_non_tenue THEN
    RAISE EXCEPTION 'delais de remplacement : le remplacant dans la salle doit venir avant la seance non tenue (objectif % min, seance non tenue % min, depuis le debut de la seance)', v_objectif, v_non_tenue
      USING ERRCODE = '22023';
  END IF;
  RETURN NEW;
END;$b$, 1);

-- ---------------------------------------------------------------------------
-- 2. Les seances reportees.
-- ---------------------------------------------------------------------------
CREATE TABLE public.seances_reportees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL UNIQUE REFERENCES public.sessions (id),
  groupe_id uuid NOT NULL REFERENCES public.groupes (id),
  enseignant_titulaire_id uuid NOT NULL REFERENCES public.profiles (id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  seance_nouvelle_id uuid UNIQUE REFERENCES public.sessions (id),
  fixee_le timestamptz,
  fixee_par uuid REFERENCES public.profiles (id),
  CONSTRAINT seances_reportees_fixee_check CHECK (
    (seance_nouvelle_id IS NULL) = (fixee_le IS NULL)
    AND (fixee_le IS NULL) = (fixee_par IS NULL))
);
CREATE INDEX seances_reportees_ouvertes_idx
  ON public.seances_reportees (cree_le) WHERE seance_nouvelle_id IS NULL;
ALTER TABLE public.seances_reportees ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.seances_reportees FROM PUBLIC, anon, authenticated, agent_ro;
COMMENT ON TABLE public.seances_reportees IS
  'SNT (03/11/2026) : une seance non tenue a T+remplacement.seance_non_tenue_minutes (personne entre), reportee ; la direction fixe une seule fois la nouvelle date (seance_nouvelle_id). Aucune policy : lue par lister_seances_reportees, ecrite par les fonctions DEFINER.';

-- Une ligne ne change qu'une fois : la pose de la nouvelle date.
CREATE FUNCTION private.seances_reportees_garde()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.session_id IS DISTINCT FROM OLD.session_id
     OR NEW.groupe_id IS DISTINCT FROM OLD.groupe_id
     OR NEW.enseignant_titulaire_id IS DISTINCT FROM OLD.enseignant_titulaire_id
     OR NEW.cree_le IS DISTINCT FROM OLD.cree_le
     OR OLD.seance_nouvelle_id IS NOT NULL THEN
    RAISE EXCEPTION 'seance reportee : seule la nouvelle date se pose, une seule fois'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.seances_reportees_garde()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
CREATE TRIGGER seances_reportees_garde
  BEFORE UPDATE ON public.seances_reportees
  FOR EACH ROW EXECUTE FUNCTION private.seances_reportees_garde();

-- ---------------------------------------------------------------------------
-- 3. « Un enseignant est entre » : un seul sens, celui d'A3-bis.
-- ---------------------------------------------------------------------------
-- Le titulaire ou le remplacant pris a recu un jeton enseignant
-- (private.a3bis_premier_entre, qui ferme deja la porte a l'autre). Sans
-- prise, tout jeton du titulaire compte ; apres une prise, ceux du titulaire
-- depuis la prise et tous ceux du remplacant. Un jeton precede toujours
-- l'evenement « joined » : une seance ou un enseignant a rejoint la salle
-- n'est jamais reportee.
CREATE FUNCTION private.snt_enseignant_entre(p_session_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT private.a3bis_premier_entre(
           s.id, s.teacher_id, x.enseignant_remplacant_id,
           coalesce(x.cree_le, '-infinity'::timestamptz)) IS NOT NULL
    FROM public.sessions s
    LEFT JOIN LATERAL (
      SELECT r.enseignant_remplacant_id, r.cree_le
        FROM public.remplacements_seance r
       WHERE r.session_id = s.id
         AND r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
       ORDER BY r.cree_le DESC, r.id DESC
       LIMIT 1) x ON true
   WHERE s.id = p_session_id;
$function$;
REVOKE ALL ON FUNCTION private.snt_enseignant_entre(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ---------------------------------------------------------------------------
-- 4. Le passage de chaque minute : etape e.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$  v_alertes integer := 0;
  v_dir record;
$a$,
  $b$  v_alertes integer := 0;
  v_dir record;
  -- SNT (03/11/2026).
  v_non_tenue integer := private.remplacement_reglage('remplacement.seance_non_tenue_minutes');
  v_reportees integer := 0;
  v_report uuid;
  v_remplacant uuid;
$b$, 1);

SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)',
  $a$  RETURN pg_catalog.jsonb_build_object(
    'alertes_direction', v_alertes,$a$,
  $b$  -- e. SNT (03/11/2026) : T + seance_non_tenue, ni le titulaire ni le
  --    remplacant pris n'est entre. La seance n'est pas tenue : elle passe en
  --    teacher_absent, elle est reportee (une ligne, une seule fois), la
  --    classe et la direction sont prevenues. Le verrou de la seance est celui
  --    sous lequel le jeton enseignant est emis ; « entre » est revu apres.
  FOR v_s IN
    SELECT s.id, s.teacher_id, s.groupe_id, s.started_at, g.libelle, g.timezone_iana,
           pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')) AS enseignant
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      LEFT JOIN public.profiles t ON t.id = s.teacher_id
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
       AND s.teacher_id IS NOT NULL
       AND s.started_at + pg_catalog.make_interval(mins => v_non_tenue) <= p_maintenant
       AND NOT EXISTS (SELECT 1 FROM public.seances_reportees x WHERE x.session_id = s.id)
     ORDER BY s.started_at, s.id
       FOR UPDATE OF s SKIP LOCKED
  LOOP
    BEGIN
      IF private.snt_enseignant_entre(v_s.id) THEN
        CONTINUE;
      END IF;
      UPDATE public.sessions SET status = 'teacher_absent'
       WHERE id = v_s.id AND status IN ('planned', 'preflight', 'in_progress');
      IF NOT FOUND THEN
        CONTINUE;
      END IF;
      v_report := NULL;
      INSERT INTO public.seances_reportees (session_id, groupe_id, enseignant_titulaire_id)
      VALUES (v_s.id, v_s.groupe_id, v_s.teacher_id)
      ON CONFLICT (session_id) DO NOTHING
      RETURNING id INTO v_report;
      IF v_report IS NULL THEN
        CONTINUE;
      END IF;
      SELECT r.enseignant_remplacant_id INTO v_remplacant
        FROM public.remplacements_seance r
       WHERE r.session_id = v_s.id
         AND r.evenement IN ('remplacement_pris', 'remplacement_designe_admin')
       ORDER BY r.cree_le DESC, r.id DESC
       LIMIT 1;
      PERFORM private.notifier_classe(
        v_s.groupe_id, 'seance_reportee',
        p_session := v_s.id, p_instant := v_s.started_at,
        p_enseignants := CASE WHEN v_remplacant IS NULL THEN NULL ELSE ARRAY[v_remplacant] END);
      -- La direction : le chemin de l'alerte d'A3-bis (etape d).
      FOR v_dir IN
        SELECT p.id, h.timezone
          FROM public.profiles p
          LEFT JOIN public.households h ON h.id = p.household_id
         WHERE p.role = 'admin' AND p.deleted_at IS NULL AND p.account_status = 'active'
           AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
      LOOP
        PERFORM public.courriel_enfiler(
          'classes', 'seance_reportee_direction',
          public.courriel_adresse_profil(v_dir.id), v_dir.id,
          pg_catalog.jsonb_build_object(
            'session_id', v_s.id,
            'classe', v_s.libelle,
            'enseignant', nullif(v_s.enseignant, ''),
            'minutes', v_non_tenue::text,
            'debut_local', pg_catalog.to_char(
              v_s.started_at AT TIME ZONE coalesce(v_dir.timezone, v_s.timezone_iana, 'UTC'),
              'YYYY-MM-DD"T"HH24:MI:SS')),
          'snt-report:' || v_s.id::text || ':' || v_dir.id::text);
      END LOOP;
      PERFORM public.log_sensitive_access('seance_reportee_auto', 'seances_reportees',
        v_report::text, pg_catalog.jsonb_build_object('session_id', v_s.id, 'automatique', true,
          'seance_non_tenue_minutes', v_non_tenue, 'remplacant_pris', v_remplacant IS NOT NULL));
      v_reportees := v_reportees + 1;
    EXCEPTION WHEN OTHERS THEN
      v_erreurs := v_erreurs + 1;
      RAISE WARNING 'report de la seance non tenue % impossible : %', v_s.id, SQLERRM;
    END;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'reportees', v_reportees,
    'alertes_direction', v_alertes,$b$, 1);

ALTER FUNCTION private.remplacement_auto_passer(timestamptz) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.remplacement_auto_passer(timestamptz)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.remplacement_auto_passer(timestamptz) IS
  'A3, A3-bis et SNT : chaque minute, pre-alerte, remplacement inutile, absence automatique SEULEMENT avec un remplacant pret et candidat (jamais pour une seance creee tard), alerte e-mail a la direction si personne n''est dans la salle, et a T+seance_non_tenue sans enseignant entre : teacher_absent, seance reportee, classe et direction prevenues. N''annule jamais. Reglages remplacement.*.';

-- ---------------------------------------------------------------------------
-- 5. La salle : une seance reportee ne s'ouvre plus, et le dit.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.autoriser_jeton_video(uuid,uuid,text,text)',
  $a$    perform 1 from public.sessions s where s.id = p_session_id for update;
  end if;
$a$,
  $b$    perform 1 from public.sessions s where s.id = p_session_id for update;
  end if;
  -- SNT (03/11/2026) : relu apres le verrou. Une seance reportee (personne
  -- n'est entre a T+seance_non_tenue) ne s'ouvre plus, pour personne.
  if exists (select 1 from public.sessions s
               join public.seances_reportees r on r.session_id = s.id
              where s.id = p_session_id and s.status = 'teacher_absent') then
    raise exception 'seance reportee' using errcode = 'check_violation';
  end if;
$b$, 1);

-- Le motif, a l'enseignant (titulaire ou remplacant), avant les motifs d'A3.
SELECT pg_temp.remplacer('public.motif_refus_salle(uuid,uuid,uuid)',
  $a$  -- A3-bis (03/11/2026) : apres une prise, le premier des deux enseignants$a$,
  $b$  -- SNT (03/11/2026) : la seance non tenue est reportee ; le titulaire et
  -- tout remplacant de cette seance le lisent.
  if p_eleve_id is null
     and v_seance.status = 'teacher_absent'
     and exists (select 1 from public.seances_reportees r where r.session_id = p_session_id)
     and (exists (select 1 from public.sessions s3
                   where s3.id = p_session_id and s3.teacher_id = p_profile_id)
          or exists (select 1 from public.remplacements_seance r3
                      where r3.session_id = p_session_id
                        and r3.enseignant_remplacant_id = p_profile_id)) then
    return jsonb_build_object(
      'motif', 'seance_reportee',
      'fin_utc', v_seance.ended_at,
      'ouverture_utc', null,
      'grace_minutes', v_grace
    );
  end if;

  -- A3-bis (03/11/2026) : apres une prise, le premier des deux enseignants$b$, 1);
-- Le motif, a tout participant ou tuteur qui y avait droit.
SELECT pg_temp.remplacer('public.motif_refus_salle(uuid,uuid,uuid)',
  $a$  if v_seance.status in ('canceled', 'canceled_late') then
    v_motif := 'annulee';$a$,
  $b$  if v_seance.status = 'teacher_absent'
     and exists (select 1 from public.seances_reportees r where r.session_id = p_session_id) then
    -- SNT (03/11/2026).
    v_motif := 'seance_reportee';
  elsif v_seance.status in ('canceled', 'canceled_late') then
    v_motif := 'annulee';$b$, 1);

-- ---------------------------------------------------------------------------
-- 6. La direction fixe la nouvelle date.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.fixer_nouvelle_date_seance(p_report uuid, p_debut timestamptz)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r public.seances_reportees%ROWTYPE;
  v_o public.sessions%ROWTYPE;
  v_g public.groupes%ROWTYPE;
  v_fin timestamptz;
  v_fenetre integer := public.app_config_int('join_window_minutes', 20);
  v_nom text;
  v_debut_autre timestamptz;
  v_fuseau text;
  v_nouvelle uuid;
BEGIN
  -- La garde des RPC de planning de la direction (C1,
  -- creer_classe_creneaux_admin) : compte valide et role admin du jeton.
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'NouvelleDateNonAutorisee' USING ERRCODE = '42501';
  END IF;
  IF p_report IS NULL OR p_debut IS NULL THEN
    RAISE EXCEPTION 'NouvelleDateInvalide' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_r FROM public.seances_reportees r WHERE r.id = p_report FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SeanceReporteeIntrouvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_r.seance_nouvelle_id IS NOT NULL THEN
    RAISE EXCEPTION 'NouvelleDateDejaFixee' USING ERRCODE = '23505';
  END IF;
  SELECT * INTO v_o FROM public.sessions s WHERE s.id = v_r.session_id;
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = v_r.groupe_id FOR UPDATE;
  IF NOT FOUND OR v_g.ended_at IS NOT NULL OR v_g.etat <> 'active' THEN
    RAISE EXCEPTION 'ClasseClose' USING ERRCODE = '22023';
  END IF;
  IF p_debut <= pg_catalog.now() THEN
    RAISE EXCEPTION 'NouvelleDateInvalide' USING ERRCODE = '22023',
      DETAIL = 'la nouvelle date doit etre a venir';
  END IF;
  -- La meme duree que la seance reportee.
  v_fin := p_debut + (v_o.ended_at - v_o.started_at);

  -- Le controle de chevauchement de C1 : le meme refus, la meme forme de
  -- DETAIL (lib/core/admin/creation_classe_refusee.dart).
  SELECT og.libelle, s.started_at, coalesce(og.timezone_iana, v_g.timezone_iana)
    INTO v_nom, v_debut_autre, v_fuseau
    FROM public.sessions s
    LEFT JOIN public.groupes og ON og.id = s.groupe_id
   WHERE s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND s.started_at < v_fin
     AND s.ended_at > p_debut
     AND (s.teacher_id = v_r.enseignant_titulaire_id
          OR private.c29_enseignant_effectif_session(s.id) = v_r.enseignant_titulaire_id)
   ORDER BY s.started_at
   LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante'
      USING DETAIL = 'cette date chevauche une seance a venir de cet enseignant '
        || pg_catalog.json_build_object(
             'classe', v_nom,
             'date', pg_catalog.to_char(v_debut_autre AT TIME ZONE v_fuseau, 'YYYY-MM-DD'),
             'jour', pg_catalog.date_part('isodow', v_debut_autre AT TIME ZONE v_fuseau)::integer,
             'heure', pg_catalog.date_part('hour', v_debut_autre AT TIME ZONE v_fuseau)::integer,
             'minute', pg_catalog.date_part('minute', v_debut_autre AT TIME ZONE v_fuseau)::integer,
             'fuseau', v_fuseau)::text;
  END IF;

  BEGIN
    -- Le meme INSERT que public.materialiser_seances_groupe.
    INSERT INTO public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
    VALUES
      (v_r.enseignant_titulaire_id, p_debut, v_fin,
       CASE v_g.type_public WHEN 'enfant' THEN 'child' ELSE 'standard' END,
       v_g.id, p_debut - pg_catalog.make_interval(mins => v_fenetre))
    RETURNING id INTO v_nouvelle;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante'
      USING DETAIL = 'cette date chevauche une seance a venir de cet enseignant '
        || pg_catalog.json_build_object('classe', NULL, 'fuseau', v_g.timezone_iana)::text;
  END;

  INSERT INTO public.session_participants (session_id, profile_id, role)
  SELECT v_nouvelle, m.student_id, 'student'
    FROM public.groupe_membres m
   WHERE m.groupe_id = v_g.id AND m.left_at IS NULL;

  UPDATE public.seances_reportees
     SET seance_nouvelle_id = v_nouvelle,
         fixee_le = pg_catalog.clock_timestamp(),
         fixee_par = auth.uid()
   WHERE id = v_r.id;

  PERFORM private.notifier_classe(
    v_g.id, 'seance_deplacee', p_session := v_nouvelle, p_instant := p_debut);
  PERFORM public.log_sensitive_access('seance_reportee_nouvelle_date', 'seances_reportees',
    v_r.id::text, pg_catalog.jsonb_build_object(
      'session_reportee', v_r.session_id, 'session_nouvelle', v_nouvelle,
      'debut', p_debut, 'enseignant', v_r.enseignant_titulaire_id));
  RETURN v_nouvelle;
END;
$function$;
REVOKE ALL ON FUNCTION public.fixer_nouvelle_date_seance(uuid, timestamptz) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.fixer_nouvelle_date_seance(uuid, timestamptz) TO authenticated;
COMMENT ON FUNCTION public.fixer_nouvelle_date_seance(uuid, timestamptz) IS
  'SNT (03/11/2026) : geste « Fixer la nouvelle date » de la direction. Cree une seance de la meme classe, meme enseignant titulaire, meme duree, refuse un chevauchement de l''enseignant (refus de C1), clot la seance reportee, previent la classe (seance_deplacee).';

CREATE FUNCTION public.lister_seances_reportees()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'SeancesReporteesNonAutorisees' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(l ORDER BY l.debut, l.id)
      FROM (
        SELECT r.id, r.session_id, r.groupe_id, g.libelle AS classe,
               s.started_at AS debut, s.ended_at AS fin, g.timezone_iana AS fuseau,
               pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')) AS enseignant,
               r.cree_le
          FROM public.seances_reportees r
          JOIN public.sessions s ON s.id = r.session_id
          JOIN public.groupes g ON g.id = r.groupe_id
          LEFT JOIN public.profiles t ON t.id = r.enseignant_titulaire_id
         WHERE r.seance_nouvelle_id IS NULL
           AND g.ended_at IS NULL
         ORDER BY s.started_at, r.id
         LIMIT 100) l), '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.lister_seances_reportees() FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.lister_seances_reportees() TO authenticated;
COMMENT ON FUNCTION public.lister_seances_reportees() IS
  'SNT (03/11/2026) : les seances reportees sans nouvelle date (100 au plus, les plus anciennes d''abord), pour le planning de la direction.';

-- L'e-mail de la classe suit la notification, comme seance_annulee.
INSERT INTO private.notification_courriel (evenement, portee, courriel)
VALUES ('seance_reportee', '*', true)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 7. Verifications.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_passer text := pg_catalog.pg_get_functiondef('private.remplacement_auto_passer(timestamptz)'::regprocedure);
  v_valider text := pg_catalog.pg_get_functiondef('private.reglages_remplacement_valider()'::regprocedure);
  v_jeton text := pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure);
  v_motif text := pg_catalog.pg_get_functiondef('public.motif_refus_salle(uuid,uuid,uuid)'::regprocedure);
  v_f pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.strpos(v_passer, 'snt-report:') = 0
     OR pg_catalog.strpos(v_passer, 'private.snt_enseignant_entre(v_s.id)') = 0
     OR pg_catalog.strpos(v_passer, '''reportees'', v_reportees') = 0
     -- Les etapes d'A3-bis sont toujours la.
     OR pg_catalog.strpos(v_passer, 'a3bis-alerte:') = 0
     OR pg_catalog.strpos(v_passer, 'IF v_pret IS NULL OR NOT private.remplacement_candidat(v_s.id, v_pret) THEN') = 0 THEN
    RAISE EXCEPTION 'SNT : remplacement_auto_passer incomplet';
  END IF;
  IF pg_catalog.strpos(v_valider, 'remplacement.seance_non_tenue_minutes') = 0
     OR pg_catalog.strpos(v_valider, 'v_objectif >= v_non_tenue') = 0
     OR pg_catalog.strpos(v_valider, 'remplacement.seance_tardive_minutes') = 0 THEN
    RAISE EXCEPTION 'SNT : la validation des reglages ignore la nouvelle cle';
  END IF;
  IF pg_catalog.strpos(v_jeton, 'seance reportee') = 0
     OR pg_catalog.strpos(v_jeton, 'a3bis_titulaire_peut_entrer') = 0
     -- Le controle SNT vient apres le verrou.
     OR pg_catalog.strpos(v_jeton, 'seance reportee') < pg_catalog.strpos(v_jeton, 'for update')
     OR pg_catalog.strpos(v_motif, 'seance_reportee') = 0
     OR pg_catalog.strpos(v_motif, 'titulaire_entre') = 0 THEN
    RAISE EXCEPTION 'SNT : porte de la salle incomplete';
  END IF;

  -- Les valeurs en place passent le nouveau validateur (3 < 8 < 11 < 30 en
  -- production le 03/11) : chaque cle est relue par lui, sans changer.
  UPDATE public.app_config SET value = value
   WHERE key IN ('remplacement.avertissement_minutes', 'remplacement.perte_acces_minutes',
                 'remplacement.debut_remplacant_minutes', 'remplacement.seance_non_tenue_minutes');
  IF NOT (private.remplacement_reglage('remplacement.debut_remplacant_minutes')
          < private.remplacement_reglage('remplacement.seance_non_tenue_minutes')) THEN
    RAISE EXCEPTION 'SNT : reglages incoherents';
  END IF;

  -- La contrainte des evenements connait « seance_reportee »
  -- (20261106500001, a installer avant ce fichier).
  IF pg_catalog.strpos(
       (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
         WHERE c.conrelid = 'public.notifications'::regclass
           AND c.conname = 'notifications_evenement_check'),
       '''seance_reportee''') = 0 THEN
    RAISE WARNING 'SNT : notifications_evenement_check ne connait pas seance_reportee ; installer 20261106500001';
  END IF;

  FOREACH v_f IN ARRAY ARRAY[
    'private.remplacement_auto_passer(timestamptz)'::pg_catalog.regprocedure,
    'private.snt_enseignant_entre(uuid)'::pg_catalog.regprocedure,
    'public.fixer_nouvelle_date_seance(uuid,timestamptz)'::pg_catalog.regprocedure,
    'public.lister_seances_reportees()'::pg_catalog.regprocedure,
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure,
    'public.motif_refus_salle(uuid,uuid,uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_f AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'SNT : % sans DEFINER ou search_path vide', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.fixer_nouvelle_date_seance(uuid,timestamptz)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.lister_seances_reportees()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.snt_enseignant_entre(uuid)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.remplacement_auto_passer(timestamptz)'::regprocedure, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.fixer_nouvelle_date_seance(uuid,timestamptz)'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.seances_reportees', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.seances_reportees', 'SELECT')
     OR pg_catalog.has_table_privilege('agent_ro', 'public.seances_reportees', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.seances_reportees'::regclass) THEN
    RAISE EXCEPTION 'SNT : droits ou RLS invalides';
  END IF;
END;
$postflight$;

COMMIT;
