-- BANNISSEMENT-DATE-FINIE (14/11/2026) : un compte supprime ne porte plus jamais
-- `banned_until = 'infinity'`.
--
-- MESURE EN PRODUCTION (journaux auth du 14/11, 03:59, lecture seule) :
--   POST /otp -> 500 « error finding user: sql: Scan error on column index 1,
--   name "banned_until": unsupported Scan, storing driver.Value type string into
--   type *time.Time ». Le serveur Auth lit `auth.users` par pgx via database/sql :
--   `infinity` lui arrive comme une chaine et la recherche de CET utilisateur
--   plante (connexion, lien magique, code a usage unique). 7 comptes portaient
--   l'infini ; une adresse reinvitee dont le compte avait ete supprime ne
--   recevait jamais son lien de connexion.
--
-- CAUSE : nos fonctions de suppression ecrivaient 'infinity'::timestamptz :
--   * private.suppr_retirer      (20261108600000, redefinie par 20261108900000)
--   * private.cpt_anonymiser     (20261018150000, redefinie par 20261123943200)
--   (private.suppr_anonymiser et private.suppr_anonymiser_echus appellent
--   cpt_anonymiser : rien a changer chez elles.)
--   * public.direction_restaurer_comptes (20261108900000) ne teste pas
--     'infinity', mais RECOPIE `banni_avant` dans auth.users : un `banni_avant`
--     infini serait reecrit tel quel a la restauration.
--
-- CORRECTION :
--   a. les lignes existantes : banned_until = '2999-12-31 00:00:00+00' (date
--      finie, sans effet pratique : le compte reste banni 973 ans) ; AUCUN
--      DELETE ;
--   b. chaque fonction ci-dessus est reecrite PAR ANCRES (pg_get_functiondef +
--      replace) : on prend la derniere definition en base, on remplace un texte
--      exact, on compte les remplacements, et on s'arrete avec une erreur nette
--      s'il n'y en a pas exactement un ; deja corrigee, la fonction n'est pas
--      touchee (migration rejouable) ;
--   c. restauration : un `banni_avant` infini (ou une trace d'un ancien
--      bannissement infini) est reecrit en date finie, jamais en infini.
--
-- Le schema `auth` est celui de Supabase : la colonne est lue au catalogue,
-- comme dans les migrations d'origine (sur un Postgres nu elle n'existe pas).
-- Ni BEGIN ni COMMIT, ni DROP.

-- a. Les comptes deja bannis a l'infini -------------------------------------
DO $migration$
DECLARE
  v_n bigint;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns c
              WHERE c.table_schema = 'auth' AND c.table_name = 'users'
                AND c.column_name = 'banned_until') THEN
    EXECUTE $q$UPDATE auth.users SET banned_until = '2999-12-31 00:00:00+00'::timestamptz
                 WHERE banned_until = 'infinity'::timestamptz$q$;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    RAISE NOTICE 'bannissement_date_finie : % compte(s) ramene(s) a une date finie', v_n;
  END IF;
END
$migration$;

-- b. Les fonctions qui ecrivaient l'infini ----------------------------------
DO $migration$
DECLARE
  v_ancre constant text := '''''infinity''''::timestamptz';
  v_neuf  constant text := '''''2999-12-31 00:00:00+00''''::timestamptz';
  v_sig   text;
  v_def   text;
  v_n     integer;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'private.suppr_retirer(uuid,uuid,text,text)',
    'private.cpt_anonymiser(uuid)'
  ] LOOP
    v_def := pg_catalog.pg_get_functiondef(pg_catalog.to_regprocedure(v_sig));
    v_n := (pg_catalog.length(v_def)
            - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre);
    IF v_n = 1 THEN
      EXECUTE pg_catalog.replace(v_def, v_ancre, v_neuf);
    ELSIF v_n = 0 AND pg_catalog.strpos(v_def, v_neuf) > 0 THEN
      RAISE NOTICE 'bannissement_date_finie : % deja corrigee', v_sig;
    ELSE
      RAISE EXCEPTION 'bannissement_date_finie : % ancre(s) trouvee(s) dans % (1 attendue)', v_n, v_sig;
    END IF;
  END LOOP;
END
$migration$;

-- c. La restauration n'ecrit jamais l'infini ---------------------------------
DO $migration$
DECLARE
  v_sig    constant text := 'public.direction_restaurer_comptes(uuid[])';
  v_ancre  constant text := 'v_r.banni_avant, v_id);';
  v_neuf   constant text := 'CASE WHEN v_r.banni_avant = ''infinity''::timestamptz'
                         || ' THEN ''2999-12-31 00:00:00+00''::timestamptz ELSE v_r.banni_avant END, v_id);';
  v_def    text;
  v_n      integer;
BEGIN
  v_def := pg_catalog.pg_get_functiondef(pg_catalog.to_regprocedure(v_sig));
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre);
  IF v_n = 1 THEN
    EXECUTE pg_catalog.replace(v_def, v_ancre, v_neuf);
  ELSIF v_n = 0 AND pg_catalog.strpos(v_def, '2999-12-31 00:00:00+00') > 0 THEN
    RAISE NOTICE 'bannissement_date_finie : % deja corrigee', v_sig;
  ELSE
    RAISE EXCEPTION 'bannissement_date_finie : % ancre(s) trouvee(s) dans % (1 attendue)', v_n, v_sig;
  END IF;
END
$migration$;

-- d. Reinviter une adresse dont le compte a ete supprime ---------------------
-- Decision de l'architecte (14/11/2026) : une invitation d'EQUIPE (code
-- d'enseignant ou de comptable, type `equipe`) ou de CANDIDAT valide pour une
-- adresse dont le compte est banni PAR SUPPRESSION ne reste plus bloquee,
-- journalise dans audit_logs. Correctif du meme jour : lever le seul
-- bannissement laissait le profil retire, qui bloque l'inscription ; l'adresse
-- est donc liberee (voir plus bas) et le parcours normal cree un compte neuf.
-- Jamais pour `foyer`. Appelee par la fonction
-- Edge `invitation-compte` (service_role seul), qui reverifie ici le code :
-- valide, non utilise, non revoque, non remplace, non echu, de cette adresse.
-- « Banni par suppression » : le profil est retire (deleted_at) ou porte un
-- retrait non restaure dans private.retraits_comptes. Un compte banni pour une
-- autre raison n'est jamais leve ici. Un compte deja anonymise (adresse
-- `efface-...`) ne correspond a aucune adresse invitee. Rien n'est consomme.
CREATE OR REPLACE FUNCTION public.invitation_compte_lever_bannissement(p_type text, p_code text, p_email text)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_email text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_email, '')));
  v_valide boolean := false;
  v_user uuid;
  v_banni timestamptz;
BEGIN
  IF v_email = '' OR p_type IS NULL OR p_type NOT IN ('equipe', 'candidat') THEN
    RETURN false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns c
                  WHERE c.table_schema = 'auth' AND c.table_name = 'users'
                    AND c.column_name = 'banned_until') THEN
    RETURN false;
  END IF;

  IF p_type = 'candidat' THEN
    SELECT true INTO v_valide FROM app_private.codes_invitation_candidat c
     WHERE c.code_sha256 = app_private.empreinte_code_invitation(p_code)
       AND c.remplace_le IS NULL AND c.utilise_le IS NULL
       AND c.expire_le > pg_catalog.now() AND c.adresse = v_email;
  ELSE
    SELECT true INTO v_valide FROM public.invitations_enseignant i
     WHERE i.code = app_private.code_invitation_normalise(p_code)
       AND i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
       AND i.expire_le > pg_catalog.now();
    IF NOT coalesce(v_valide, false) THEN
      SELECT true INTO v_valide FROM public.invitations_comptable i
       WHERE i.code = app_private.code_invitation_normalise(p_code)
         AND i.email = v_email AND i.revoquee_le IS NULL AND i.utilisee_le IS NULL
         AND i.expire_le > pg_catalog.now();
    END IF;
  END IF;
  IF NOT coalesce(v_valide, false) THEN
    RETURN false;
  END IF;

  EXECUTE 'SELECT u.id, u.banned_until FROM auth.users u WHERE pg_catalog.lower(u.email) = $1 LIMIT 1'
     INTO v_user, v_banni USING v_email;
  IF v_user IS NULL OR v_banni IS NULL THEN
    RETURN false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_user AND p.deleted_at IS NOT NULL)
     AND NOT EXISTS (SELECT 1 FROM private.retraits_comptes r
                      WHERE r.profile_id = v_user AND r.restaure_le IS NULL) THEN
    RETURN false;
  END IF;

  -- Le profil retire (deleted_at, statut disabled) bloque l'inscription :
  -- `inscrire_enseignant_invite` exige une session SANS profil, et la ligne
  -- `profiles` ne se supprime pas. On ne rend donc pas l'ancien compte : on
  -- LIBERE L'ADRESSE. L'ancien compte garde son profil retire, reste banni
  -- (date finie) et passe sous une adresse `efface-...` (comme a
  -- l'anonymisation, `private.cpt_anonymiser`) ; sa restauration par la
  -- direction reste possible mais il n'a plus d'adresse de connexion. La
  -- fonction Edge cree ensuite un compte NEUF pour l'adresse invitee, sans
  -- profil : le parcours d'inscription habituel s'ouvre. Aucun DELETE.
  EXECUTE pg_catalog.format(
    'UPDATE auth.users SET email = %L, banned_until = %L::timestamptz WHERE id = %L',
    'efface-' || v_user::text || '@invalide.rewayah.invalid',
    '2999-12-31 00:00:00+00', v_user);
  IF pg_catalog.to_regclass('auth.identities') IS NOT NULL
     AND EXISTS (SELECT 1 FROM information_schema.columns c
                  WHERE c.table_schema = 'auth' AND c.table_name = 'identities'
                    AND c.column_name = 'provider_id') THEN
    -- Sinon l'ancienne identite (provider_id = l'adresse) ferait echouer la
    -- creation du compte neuf.
    EXECUTE pg_catalog.format(
      'UPDATE auth.identities SET provider_id = %L, identity_data = ''{}''::jsonb WHERE user_id = %L',
      'efface-' || v_user::text, v_user);
  END IF;
  PERFORM public.log_sensitive_access(
    'invitation_adresse_liberee', 'auth_users', v_user::text,
    pg_catalog.jsonb_build_object('type', p_type));
  RETURN true;
END;
$function$;
ALTER FUNCTION public.invitation_compte_lever_bannissement(text, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.invitation_compte_lever_bannissement(text, text, text)
  FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.invitation_compte_lever_bannissement(text, text, text) TO service_role;
COMMENT ON FUNCTION public.invitation_compte_lever_bannissement(text, text, text) IS
  'BANNISSEMENT-DATE-FINIE (14/11/2026) : libere l''adresse d''un compte supprime reinvite (equipe, candidat ; jamais foyer). service_role seul, via la fonction Edge invitation-compte.';
