-- CAND-ALERTES-2B (pilote, 11/11/2026) : les deux compteurs d'alerte que
-- public.lister_candidatures rendait NULL depuis CAND-L1 (C5) se calculent
-- enfin. La signature publique ne change pas : (jsonb, text, integer) ->
-- jsonb, memes cles. DEFINER, search_path vide, proprietaire et droits
-- inchanges (CREATE OR REPLACE garde l'ACL).
--
-- Definitions (SPEC_CONSOLIDEE_CANDIDATURES §0.3 et « entretiens en retard » ;
-- REVUE_CRITIQUE §10.2), toujours sur une candidature en cours (issue
-- en_cours) et hors pause : une pause n'entre dans aucune des quatre alertes.
--
-- * bloquees : sous restriction (restreinte), a toute etape ; ou en salle 2
--   (etape verifications) avec paiement_compatible ou profil_unique faux,
--   lus dans private.candidature_controles_salle3 (une seule source des
--   controles). entretien_conclu, evaluation_validee, accords_signes et
--   profil_renseigne n'y entrent pas : en salle 2, ils sont faux par simple
--   progression, ce n'est pas un blocage ;
-- * entretiensEnRetard : en entretien_planifie, la seance du dernier
--   entretien a fini depuis plus de 24 h, sans compte rendu et sans
--   consignation annulee ou manquee ; ou en entretien_a_planifier depuis
--   plus de N jours (dernier evenement qui l'y a fait entrer, a defaut la
--   derniere activite), N lu dans app_config
--   (cand_entretien_a_planifier_jours, pose ici a 7 s'il n'existe pas ;
--   valeur provisoire du pilote du 11/11/2026, que le directeur change sans
--   migration). Une
--   valeur illisible ou negative compte comme absente : le second cas ne
--   compte alors rien, jamais un 0 invente sur le premier.
--
-- Methode (celle de 20261029120000) : remplacement de texte verifie dans le
-- corps en place ; le bloc refuse de continuer s'il ne trouve pas le texte
-- attendu tel quel. Rejouable : un corps deja modifie est laisse tel quel.
-- L'empreinte md5 gardee dans le commentaire (F86) suit le nouveau corps.
-- Aucune ligne ni aucun objet supprime.

BEGIN;

INSERT INTO public.app_config (key, value)
VALUES ('cand_entretien_a_planifier_jours', '7'::jsonb)
ON CONFLICT (key) DO NOTHING;

DO $do$
DECLARE
  v_f constant pg_catalog.regprocedure :=
    'public.lister_candidatures(jsonb,text,integer)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_avant text := '''entretiensEnRetard'', NULL::integer,
           ''bloquees'', NULL::integer)';
  v_apres text := '''entretiensEnRetard'', pg_catalog.count(*) FILTER (
             WHERE c.issue = ''en_cours'' AND NOT c.en_pause
               AND ((c.etat = ''entretien_planifie''
                     AND EXISTS (
                       SELECT 1
                         FROM (SELECT e.session_id, e.issue
                                 FROM public.entretiens e
                                WHERE e.candidature_id = c.id
                                ORDER BY e.planifie_le DESC
                                LIMIT 1) d
                         JOIN public.sessions s ON s.id = d.session_id
                        WHERE (d.issue IS NULL OR d.issue = ''tenu'')
                          AND s.ended_at < pg_catalog.now() - interval ''24 hours''
                          AND NOT EXISTS (SELECT 1 FROM public.entretien_comptes_rendus r
                                           WHERE r.session_id = d.session_id)))
                    OR (c.etat = ''entretien_a_planifier''
                        AND coalesce(
                              (SELECT pg_catalog.max(ev.cree_le)
                                 FROM public.candidature_evenements ev
                                WHERE ev.candidature_id = c.id
                                  AND ev.etat_apres = ''entretien_a_planifier''),
                              c.derniere_activite)
                            < pg_catalog.now() - pg_catalog.make_interval(days => (
                                SELECT CASE WHEN pg_catalog.jsonb_typeof(a.value) = ''number''
                                                 AND (a.value #>> ''{}'')::numeric >= 0
                                            THEN pg_catalog.floor((a.value #>> ''{}'')::numeric)::integer
                                       END
                                  FROM public.app_config a
                                 WHERE a.key = ''cand_entretien_a_planifier_jours'')))))::integer,
           ''bloquees'', pg_catalog.count(*) FILTER (
             WHERE c.issue = ''en_cours'' AND NOT c.en_pause
               AND (coalesce(c.restreinte, false)
                    OR CASE WHEN c.etape = ''verifications''
                            THEN EXISTS (
                              SELECT 1
                                FROM pg_catalog.jsonb_array_elements(
                                       private.candidature_controles_salle3(c)) AS k(e)
                               WHERE k.e ->> ''nom'' IN (''paiement_compatible'', ''profil_unique'')
                                 AND NOT coalesce((k.e ->> ''valeur'')::boolean, false))
                            ELSE false END))::integer)';
BEGIN
  IF pg_catalog.strpos(v_def, v_apres) > 0 THEN
    RAISE NOTICE 'lister_candidatures : compteurs deja calcules, rien a faire';
    RETURN;
  END IF;
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'lister_candidatures : les compteurs bloquees et entretiensEnRetard ont change, migration a revoir';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);
  EXECUTE pg_catalog.format(
    'COMMENT ON FUNCTION public.lister_candidatures(jsonb,text,integer) IS %L',
    pg_catalog.regexp_replace(
      pg_catalog.obj_description(v_f, 'pg_proc'),
      'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
END;
$do$;

COMMIT;
