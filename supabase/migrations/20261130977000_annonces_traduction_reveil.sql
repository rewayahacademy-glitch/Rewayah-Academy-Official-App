-- ANNONCES-TRADUCTION-REVEIL (21/11/2026) : la traduction automatique des annonces (ANNONCES-SERVEUR,
-- 20261130976000) tourne dans la fonction Edge `courriels-envoi`. Constat du pilote le 21/11 apres installation :
-- la tache `courriels-envoi` (lancee chaque minute par `tache-minute`) n'appelle la fonction que si un courriel
-- attend. Une annonce publiee quand aucun courriel n'attend restait donc non traduite jusqu'au prochain courriel.
--
-- LIVRE ICI : la commande de la tache `courriels-envoi` appelle aussi la fonction quand une traduction d'annonce
-- attend et que son heure est venue. Rien d'autre ne change (meme adresse, meme secret, meme corps). La commande
-- actuelle est controlee mot pour mot avant d'etre remplacee ; sinon, rien n'est modifie.
--
-- MOTS D'EFFACEMENT : ZERO. Sans BEGIN ni COMMIT de premier niveau. Aucune donnee de personne.

DO $reveil$
DECLARE
  v_job bigint;
  v_avant text;
  v_attendue text := $c$
      SELECT net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-courriels-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret')),
        body := '{}'::jsonb)
      WHERE EXISTS (SELECT 1 FROM public.courriels_sortants
                     WHERE statut IN ('en_attente', 'envoi') AND prochaine_tentative <= pg_catalog.now())
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url');
    $c$;
  v_nouvelle text := $c$
      SELECT net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url'),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'x-courriels-secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_secret')),
        body := '{}'::jsonb)
      WHERE (EXISTS (SELECT 1 FROM public.courriels_sortants
                      WHERE statut IN ('en_attente', 'envoi') AND prochaine_tentative <= pg_catalog.now())
             OR EXISTS (SELECT 1 FROM public.com_annonce_traductions
                         WHERE etat = 'a_faire' AND prochain_essai <= pg_catalog.now()
                           AND (reserve_le IS NULL OR reserve_le < pg_catalog.now() - interval '10 minutes')))
        AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'courriels_envoi_url');
    $c$;
BEGIN
  -- Base sans pg_cron (CI, poste local) : rien a faire.
  IF pg_catalog.to_regnamespace('cron') IS NULL THEN
    RAISE NOTICE 'ANNONCES-TRADUCTION-REVEIL : pg_cron absent, rien a faire';
    RETURN;
  END IF;
  IF pg_catalog.to_regclass('public.com_annonce_traductions') IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-TRADUCTION-REVEIL : installer d''abord 20261130976000 ; rien n''est modifie';
  END IF;
  EXECUTE 'SELECT jobid, command FROM cron.job WHERE jobname = $1' INTO v_job, v_avant USING 'courriels-envoi';
  IF v_job IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-TRADUCTION-REVEIL : tache courriels-envoi absente ; rien n''est modifie';
  END IF;
  IF v_avant = v_nouvelle THEN
    RETURN;  -- deja fait
  END IF;
  IF v_avant IS DISTINCT FROM v_attendue THEN
    RAISE EXCEPTION 'ANNONCES-TRADUCTION-REVEIL : la commande actuelle n''est pas celle attendue (md5 %) ; rien n''est modifie',
      pg_catalog.md5(coalesce(v_avant, ''));
  END IF;
  EXECUTE 'SELECT cron.alter_job(job_id := $1, command := $2)' USING v_job, v_nouvelle;
END
$reveil$;
