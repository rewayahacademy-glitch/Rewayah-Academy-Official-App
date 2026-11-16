-- IMAGES-MESSAGERIE (16/11/2026), partie serveur, 3/5 : l'expiration a 90 jours.
--
-- Une tache pg_cron, UNE FOIS PAR JOUR la nuit (jamais chaque minute), appelle la
-- fonction Edge `message-images-purge`. Celle-ci lit un lot de 200 images a
-- retirer, supprime leurs objets R2 (image et miniature), puis marque les lignes
-- « supprimee » (supprimee_le = maintenant). La ligne reste : l'ecran dit
-- « Image retiree apres 90 jours ». Un lot qui reste plein est suivi d'un autre,
-- dans la meme invocation, jusqu'a vider ce qui est du.
--
-- Ce que la purge retire : toute image non supprimee dont expire_le est passe, et
-- tout depot jamais confirme depuis plus d'un jour (il peut avoir laisse des
-- objets). Le serveur lit deja une image expiree comme « supprimee » avant le
-- passage de la tache (message_images_a_signer, lecture du fil).
--
-- Meme porte que push-envoi : secret COURRIELS_ENVOI_SECRET (en-tete
-- x-courriels-secret), URL lue au coffre (courriels_envoi_url). AUCUN secret
-- nouveau. Sans pg_cron, pg_net ou coffre (CI, Postgres nu) : rien n'est
-- planifie, aucune erreur.
--
-- FICHIER SANS MOT D'EFFACEMENT, sans BEGIN ni COMMIT de premier niveau.
-- S'installe apres 20261128200100.

CREATE OR REPLACE FUNCTION public.message_images_purge_lire(p_lot integer DEFAULT 200)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', x.id, 'cle_r2', x.cle_r2, 'cle_miniature', x.cle_miniature)
           ORDER BY x.expire_le, x.id), '[]'::jsonb)
  FROM (
    SELECT i.id, i.cle_r2, i.cle_miniature, i.expire_le
      FROM public.com_message_images i
     WHERE i.etat <> 'supprimee'
       AND (i.expire_le <= pg_catalog.clock_timestamp()
            OR (i.etat = 'en_attente'
                AND i.cree_le < pg_catalog.clock_timestamp() - interval '1 day'))
     ORDER BY i.expire_le, i.id
     LIMIT greatest(1, least(coalesce(p_lot, 200), 200))
  ) x;
$function$;

CREATE OR REPLACE FUNCTION public.message_images_purge_marquer(p_ids uuid[])
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.com_message_images i
     SET etat = 'supprimee', supprimee_le = pg_catalog.clock_timestamp()
   WHERE i.id = ANY (coalesce(p_ids, ARRAY[]::uuid[])) AND i.etat <> 'supprimee';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- Reservees au role de service (la fonction Edge de purge) : aucun client.
DO $acl$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.message_images_purge_lire(integer)',
    'public.message_images_purge_marquer(uuid[])'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', f);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', f);
    END IF;
  END LOOP;
END
$acl$;

-- La tache de nuit (03:41 UTC, une fois par jour). cron.schedule remplace une
-- tache du meme nom.
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_net')
     AND EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'vault') THEN
    PERFORM cron.schedule('message-images-purge', '41 3 * * *', $cron$
      SELECT net.http_post(
        url := pg_catalog.replace(
          (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url'),
          '/courriels-envoi', '/message-images-purge'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-courriels-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret')),
        body := '{}'::jsonb)
      WHERE EXISTS (SELECT 1 FROM public.com_message_images i
                     WHERE i.etat <> 'supprimee'
                       AND (i.expire_le <= pg_catalog.clock_timestamp()
                            OR (i.etat = 'en_attente'
                                AND i.cree_le < pg_catalog.clock_timestamp() - interval '1 day')))
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url')
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret');
    $cron$);
  ELSE
    RAISE NOTICE 'IMAGES-MESSAGERIE : pg_cron, pg_net ou le coffre est absent, rien n''est planifie';
  END IF;
END
$planification$;
