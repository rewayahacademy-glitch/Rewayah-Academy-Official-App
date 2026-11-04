-- GARDE-PROFIL (04/11/2026) : la garde des colonnes de `profiles` s'etend.
--
-- Releve du 04/11 (banc local, jeton reel d'un enfant, PATCH REST) : la
-- politique `profiles_self_update` (UPDATE de sa propre ligne, droit UPDATE
-- de table pour authenticated) laissait un eleve mineur reecrire first_name,
-- last_name, langue_communication, created_at et updated_at de sa propre
-- ligne. Aucun ecran ne le fait ; un appel direct a l'API suffisait.
--
-- Decision du pilote (04/11/2026), avec garde-cap :
--   * pour tout non-admin (hors service_role et postgres), deleted_at,
--     created_at et immutable_id deviennent immuables, quel que soit le role ;
--   * sur sa propre ligne (`NEW.id = auth.uid()`), un appelant qui n'est pas
--     adulte ne change ni first_name ni last_name. L'age est lu au serveur, par
--     `public.photo_adulte_moi()` (PHOTOS-1) : compte valide, puis
--     `private.photo_adulte(auth.uid())`, la meme regle que `poser_ma_photo`.
--     Elle est appelee, jamais recopiee ;
--   * langue_communication reste hors de la garde : l'ecran officiel
--     (`ma_langue_communication_regler`) permet a l'eleve de la choisir ;
--   * la politique `profiles_self_update` n'est pas touchee : la garde par
--     declencheur est plus etroite et casse moins. Aucun retrait de droit de
--     colonne (le droit UPDATE est donne sur la table entiere).
--
-- Pourquoi `photo_adulte_moi()` et non `private.photo_adulte` : ce
-- declencheur n'est pas SECURITY DEFINER (son test `current_user` en
-- depend), il s'execute donc sous le role de l'appelant, qui n'a ni USAGE sur
-- le schema `private` ni EXECUTE sur `private.photo_adulte`.
-- Consequence acceptee (pilote, 04/11) : un adulte au compte non valide
-- (pending_kyc, disabled, acces echu) est lui aussi bloque sur ses noms en
-- ecriture directe. Aucun ecran ne fait cette ecriture directe.
--
-- Les chemins officiels passent toujours : ils s'executent en postgres
-- (fonctions SECURITY DEFINER, cron) ou sont reserves a la direction :
-- direction_supprimer_comptes, direction_restaurer_comptes,
-- tuteur_supprimer_profil_enfant, traiter_demande_suppression et
-- l'anonymisation (private.cpt_anonymiser), ma_langue_communication_regler,
-- et la direction en ecriture directe (profiles_admin_all). Les creations
-- (INSERT) ne passent pas par ce declencheur (BEFORE UPDATE).
--
-- Le corps reprend la version en production (md5 de prosrc
-- 3b32b937a6d3e4525cc02850e93ad7be, controle par le preflight) et y ajoute
-- les deux regles. Le premier message d'erreur est garde mot pour mot.
-- Aucune instruction d'effacement ; pas de transaction de premier niveau.

-- ---------------------------------------------------------------------------
-- 1. Preflight : la fonction remplacee est bien celle que l'on a lue
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.guard_profile_privileged_columns()'::regprocedure;
  IF v_md5 IS NULL THEN
    RAISE EXCEPTION 'GARDE-PROFIL : public.guard_profile_privileged_columns() absente';
  END IF;
  -- La version de production, ou celle de ce fichier (rejeu).
  IF v_md5 <> '3b32b937a6d3e4525cc02850e93ad7be'
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                      WHERE p.oid = 'public.guard_profile_privileged_columns()'::regprocedure
                        AND p.prosrc LIKE '%GARDE-PROFIL%') THEN
    RAISE EXCEPTION 'GARDE-PROFIL : corps inattendu (md5 %), relire la production avant d''ecrire', v_md5;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.profiles'::regclass
                    AND t.tgname = 'profiles_privileged_columns_guard'
                    AND NOT t.tgisinternal) THEN
    RAISE EXCEPTION 'GARDE-PROFIL : declencheur profiles_privileged_columns_guard absent';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.photo_adulte_moi()'::regprocedure AND p.prosecdef)
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.photo_adulte_moi()', 'EXECUTE') THEN
    RAISE EXCEPTION 'GARDE-PROFIL : public.photo_adulte_moi() absente, non SECURITY DEFINER ou fermee a authenticated';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. La garde, etendue
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_profile_privileged_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin')
     and not coalesce(
       public.app_role() = 'admin' and public.app_account_valid(),
       false
     )
  then
    if old.role is distinct from new.role
       or old.household_id is distinct from new.household_id
       or old.account_status is distinct from new.account_status
       or old.access_until is distinct from new.access_until
       or old.gender is distinct from new.gender
    then
      raise exception 'seul un admin modifie rôle, foyer, statut, accès ou genre'
        using errcode = 'insufficient_privilege';
    end if;
    -- GARDE-PROFIL (04/11/2026) : pour tous les roles, hors direction.
    if old.deleted_at is distinct from new.deleted_at
       or old.created_at is distinct from new.created_at
       or old.immutable_id is distinct from new.immutable_id
    then
      raise exception 'seule la direction retire un compte, ou change sa date de creation ou son matricule'
        using errcode = 'insufficient_privilege';
    end if;
    -- GARDE-PROFIL : sur sa propre ligne, qui n'est pas adulte (regle du
    -- serveur, photo_adulte_moi) ne change pas ses noms.
    if new.id = auth.uid()
       and (old.first_name is distinct from new.first_name
            or old.last_name is distinct from new.last_name)
       and not coalesce(public.photo_adulte_moi(), false)
    then
      raise exception 'le nom d''un eleve mineur se change par l''academie'
        using errcode = 'insufficient_privilege';
    end if;
  end if;
  return new;
end;
$function$;

ALTER FUNCTION public.guard_profile_privileged_columns() OWNER TO postgres;

COMMENT ON FUNCTION public.guard_profile_privileged_columns() IS
  'GARDE-PROFIL (04/11/2026) : hors service_role, postgres et direction, refuse le changement de role, foyer, statut, acces, genre (avant), de deleted_at, created_at, immutable_id (tous roles), et de first_name ou last_name sur sa propre ligne pour qui n''est pas adulte (public.photo_adulte_moi()). langue_communication reste libre (ecran ma_langue_communication_regler).';

-- ---------------------------------------------------------------------------
-- 3. Postflight : la garde est en place, telle qu'ecrite
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = 'public.guard_profile_privileged_columns()'::regprocedure
                    AND NOT p.prosecdef
                    AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""']
                    AND p.prosrc LIKE '%old.deleted_at is distinct from new.deleted_at%'
                    AND p.prosrc LIKE '%old.created_at is distinct from new.created_at%'
                    AND p.prosrc LIKE '%public.photo_adulte_moi()%'
                    AND p.prosrc LIKE '%seul un admin modifie rôle, foyer, statut, accès ou genre%') THEN
    RAISE EXCEPTION 'GARDE-PROFIL : la garde n''a pas la forme attendue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.profiles'::regclass
                    AND t.tgname = 'profiles_privileged_columns_guard'
                    AND t.tgfoid = 'public.guard_profile_privileged_columns()'::regprocedure
                    AND t.tgenabled <> 'D') THEN
    RAISE EXCEPTION 'GARDE-PROFIL : le declencheur ne porte pas la garde, ou il est desactive';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.photo_adulte_moi()', 'EXECUTE') THEN
    RAISE EXCEPTION 'GARDE-PROFIL : public.photo_adulte_moi() ouverte a anon';
  END IF;
END;
$postflight$;
