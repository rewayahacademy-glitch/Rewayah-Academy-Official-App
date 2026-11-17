-- PX-BD-BIBLIOTHEQUE (17/11/2026, migration 20261129970000_praxis_actes_bibliotheque.sql, socle 20261129960000) : les quatre actes de Praxis
-- en mode chat sur la Bibliotheque. Aucune personne reelle : des supports fictifs, des cles fictives.
-- Cas : 1 le catalogue (quatre actes, niveaux) ; 2 lister (filtres, bornes, revision, rien de plus) ; 3 modifier (parametres, visibilite
-- limitee, revision perimee, ecrit sous l'identite de la direction, trace) ; 4 deplacer ; 5 retirer = masquer, JAMAIS effacer, par lot et par code ;
-- 6 la cle de routine ne fait rien ; 7 les adaptateurs ne sont executables par personne, sans SQL dynamique.
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Annule tout a la fin. Aucun mot d'effacement.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p boolean, p_label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF p IS NOT TRUE THEN RAISE EXCEPTION 'PX-BD-BIB ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal2') RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', p_aal, 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;
CREATE FUNCTION pg_temp.appel(p_id uuid, p_role text, p_aal text, p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role, p_aal);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.srv(p_sql text) RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claims', '{"sentinelle":true}', true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  EXECUTE 'SET LOCAL ROLE service_role';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.vrai(boolean, text), pg_temp.appel(uuid, text, text, text), pg_temp.srv(text)
  TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.u(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b00000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid $$;
CREATE FUNCTION pg_temp.idem(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1b11111-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.s(p_n integer) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT ('b1bccccc-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(integer), pg_temp.idem(integer), pg_temp.s(integer) TO authenticated, anon, service_role;

-- u1 direction ; des supports fictifs s1 a s5.
INSERT INTO auth.users (id, email) VALUES (pg_temp.u(1), 'pxbib-1@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(1), 'BIB-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.u(1));
INSERT INTO public.library_resource (id, title, short_title, resource_type, language, category, level_scope, access_policy, offline_policy,
                                     capabilities, rayon, ordre, etapes, tranches)
SELECT pg_temp.s(i), 'Support fictif ' || i, 'Support ' || i, 'pdf', 'fr', 'essai', ARRAY[]::text[], 'inscrits', 'jamais',
       ARRAY[]::text[], 'cours', i * 10, ARRAY[]::text[], ARRAY['enfant_6_9', 'enfant_10_13', 'ado_14_17', 'adulte_18_plus']
  FROM generate_series(1, 5) i;
UPDATE public.library_resource SET title = 'Tajwid des bases' WHERE id = pg_temp.s(2);

CREATE FUNCTION pg_temp.cle(p_n integer, p_usage text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE j jsonb;
BEGIN
  j := pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', pg_catalog.format(
    'SELECT public.direction_praxis_emettre_cle(%L, %L, pg_catalog.now() + interval ''30 days'', %L::uuid)',
    'Cle d''essai ' || p_n, p_usage, pg_temp.idem(900 + p_n)));
  RETURN j ->> 'secret';
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.cle(integer, text) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.code_de(p_jeton text) RETURNS text LANGUAGE sql AS $$
  SELECT x ->> 'code' FROM pg_catalog.jsonb_array_elements(
    pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_confirmations()')) x WHERE x ->> 'id' = p_jeton $$;
GRANT EXECUTE ON FUNCTION pg_temp.code_de(text) TO authenticated, anon, service_role;
CREATE FUNCTION pg_temp.rev(p_n integer) RETURNS integer LANGUAGE sql AS $$ SELECT revision FROM public.library_resource WHERE id = pg_temp.s(p_n) $$;
-- Un acte A d'essai, au role service_role : rend le jsonb de la porte.
CREATE FUNCTION pg_temp.agir(p_cle text, p_acte text, p_params text, p_n integer) RETURNS jsonb LANGUAGE sql AS $$
  SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, %L, %L::jsonb, %L::uuid)', p_cle, p_acte, p_params, pg_temp.idem(p_n))) $$;
GRANT EXECUTE ON FUNCTION pg_temp.agir(text, text, text, integer), pg_temp.rev(integer) TO authenticated, anon, service_role;

SELECT pg_temp.cle(1, 'chat') AS k1 \gset
SELECT pg_temp.cle(2, 'routine') AS kr \gset
SELECT pg_temp.appel(pg_temp.u(1), 'admin', 'aal2', 'SELECT public.direction_praxis_regler(true, true, 100)');
UPDATE private.praxis_reglages SET donnees_reelles = true;

-- ===================================================================================================
-- 1. Le catalogue.
-- ===================================================================================================
SELECT pg_temp.vrai((SELECT pg_catalog.array_agg(acte || ':' || niveau ORDER BY acte) FROM private.praxis_actes)
                    = ARRAY['support_deplacer:A', 'support_lister:A', 'support_modifier:A', 'support_retirer:S'],
  '1a : le catalogue contient EXACTEMENT quatre actes (lister, modifier, deplacer en A ; retirer en S) : aucun acte « publier », aucun depot');
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_actes(%L)', :'k1')) -> 'actes' @> '[{"acte": "support_retirer", "niveau": "S"}]'::jsonb
                    AND pg_catalog.length(pg_temp.srv(pg_catalog.format('SELECT public.praxis_actes(%L)', :'k1'))::text) < 8000,
  '1b : la cle de chat voit les quatre actes avec leur description');

-- ===================================================================================================
-- 2. Lister.
-- ===================================================================================================
SELECT pg_temp.agir(:'k1', 'support_lister', '{}', 1) AS j \gset
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(:'j'::jsonb -> 'resultat' -> 'supports') = 5
                    AND :'j'::jsonb #>> '{resultat,supports,0,revision}' ~ '^[0-9]+$'
                    AND (SELECT pg_catalog.array_agg(k ORDER BY k) FROM pg_catalog.jsonb_object_keys(:'j'::jsonb #> '{resultat,supports,0}') k)
                        = ARRAY['etapes', 'id', 'ordre', 'publie', 'rayon', 'retire', 'revision', 'titre', 'tranches', 'type', 'visibilite'],
  '2a : lister rend cinq supports avec leur revision, et ces onze champs seulement');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.agir(:'k1', 'support_lister', '{"recherche": "tajwid"}', 2) -> 'resultat' -> 'supports') = 1,
  '2b : la recherche porte sur le titre (casse ignoree)');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.agir(:'k1', 'support_lister', '{"limite": 2}', 3) -> 'resultat' -> 'supports') = 2
                    AND pg_catalog.jsonb_array_length(pg_temp.agir(:'k1', 'support_lister', '{"rayon": "plus_loin"}', 4) -> 'resultat' -> 'supports') = 0,
  '2c : la limite et le rayon filtrent');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_lister', p, 20 + n) -> 'resultat' ->> 'erreur' = 'parametre',
  '2e : parametre refuse : ' || p)
  FROM (VALUES (1, '{"quoi": "x"}'), (2, '{"rayon": "autre"}'), (3, '{"limite": 0}'), (4, '{"limite": 51}'), (5, '{"limite": "5"}'),
               (6, '{"retires": "oui"}'), (7, '{"recherche": 12}'), (8, '{"recherche": "' || pg_catalog.repeat('x', 61) || '"}')) v(n, p);
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''support_lister'', ''{}''::jsonb, %L::uuid)', :'kr', pg_temp.idem(40)))
                    = '{"erreur": "chat_seulement"}'::jsonb, '2f : la cle de routine ne lit pas les supports');

-- ===================================================================================================
-- 3. Modifier.
-- ===================================================================================================
SELECT pg_temp.rev(1) AS r1 \gset
SELECT pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "titre": "Tajwid, niveau 1", "description": "Les neuf regles."}',
                    pg_temp.s(1), :'r1'), 50) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND (:'j'::jsonb #>> '{resultat,ok}')::boolean
                    AND (SELECT title = 'Tajwid, niveau 1' AND description = 'Les neuf regles.' FROM public.library_resource WHERE id = pg_temp.s(1)),
  '3a : la fiche est modifiee par la fonction de la direction');
SELECT pg_temp.vrai(pg_temp.rev(1) > :'r1'::int AND (:'j'::jsonb #>> '{resultat,revision}')::int = pg_temp.rev(1), '3b : la revision a avance et est rendue');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'library_resource_draft_updated' AND a.actor = pg_temp.u(1)
                              AND a.row_id = pg_temp.s(1)::text)
                    AND EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'praxis_acte' AND a.row_id = 'support_modifier'
                                  AND a.actor = pg_temp.u(1) AND a.payload ->> 'via' = 'praxis'),
  '3c : l''ecriture est tracee AU NOM de la direction, et la ligne « via Praxis » existe');
SELECT pg_temp.vrai(pg_catalog.current_setting('request.jwt.claims') = '{"sentinelle":true}', '3d : l''identite d''avant l''appel est rendue');
-- revision perimee
SELECT pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "titre": "Trop tard"}', pg_temp.s(1), :'r1'), 51) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb #>> '{resultat,erreur}' = 'revision_changee' AND (:'j'::jsonb #>> '{resultat,revision}')::int = pg_temp.rev(1)
                    AND (SELECT title FROM public.library_resource WHERE id = pg_temp.s(1)) = 'Tajwid, niveau 1',
  '3e : une revision perimee ne change rien et rend la revision actuelle');
-- vider un champ
SELECT pg_temp.rev(1) AS r1 \gset
SELECT pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "description": ""}', pg_temp.s(1), :'r1'), 52) AS j \gset
SELECT pg_temp.vrai((SELECT description IS NULL FROM public.library_resource WHERE id = pg_temp.s(1)), '3f : une chaine vide retire le champ');
-- visibilite : jamais publique, jamais « admin »
SELECT pg_temp.rev(1) AS r1 \gset
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "visibilite": "%s"}', pg_temp.s(1), :'r1', v), 60 + n)
                      -> 'resultat' ->> 'erreur' = 'parametre',
  '3g : la visibilite « ' || v || ' » n''est pas offerte au chat')
  FROM (VALUES (1, 'publique'), (2, 'admin'), (3, 'tous')) x(n, v);
SELECT pg_temp.vrai((pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "visibilite": "groupe_assigne"}', pg_temp.s(1), :'r1'), 64)
                      -> 'resultat' ->> 'ok')::boolean
                    AND (SELECT access_policy::text FROM public.library_resource WHERE id = pg_temp.s(1)) = 'groupe_assigne',
  '3h : groupe_assigne est offert');
SELECT pg_temp.rev(1) AS r1 \gset
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format(p, pg_temp.s(1), :'r1'), 70 + n) -> 'resultat' ->> 'erreur' = 'parametre',
  '3i : parametre refuse : ' || n)
  FROM (VALUES (1, '{"id": "%s", "revision": %s, "quoi": "x"}'), (2, '{"id": "%s", "revision": "%s"}'),
               (3, '{"id": "%s", "revision": %s, "tranches": []}'), (4, '{"id": "%s", "revision": %s, "tranches": ["senior"]}'),
               (5, '{"id": "%s", "revision": %s, "tranches": "adulte_18_plus"}'), (6, '{"id": "%s", "revision": %s, "etapes": ["a b"]}'),
               (7, '{"id": "%s", "revision": %s, "lecture_coran": "x"}'), (8, '{"id": "%s", "revision": %s, "politique_hors_ligne": "x"}'),
               (9, '{"id": "%s", "revision": %s, "titre": 5}'), (10, '{"id": "%s", "revision": %s, "titre": null}')) v(n, p);
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s}', pg_temp.s(1), :'r1'), 90) -> 'resultat' ->> 'erreur' = 'rien_a_changer',
  '3j : sans aucun champ a changer : rien_a_changer');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": 1, "titre": "x"}', pg_temp.idem(5)), 91) -> 'resultat' ->> 'erreur' = 'support_introuvable',
  '3k : un support inconnu est introuvable');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "pas-un-uuid", "revision": %s, "titre": "x"}', :'r1'), 92) -> 'resultat' ->> 'erreur' = 'parametre',
  '3l : un identifiant qui n''est pas un uuid est refuse');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "titre": ""}', pg_temp.s(1), :'r1'), 93) ->> 'erreur' = 'refuse',
  '3m : un titre vide est refuse par la fonction de la direction (cause fermee, rien ecrit)');
SELECT pg_temp.rev(1) AS r1 \gset
SELECT pg_temp.vrai((pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": %s, "tranches": ["adulte_18_plus"], "etapes": ["E1", "E2"], "lecture_coran": "hafs", "politique_hors_ligne": "sur_demande"}', pg_temp.s(1), :'r1'), 94)
                      -> 'resultat' ->> 'ok')::boolean
                    AND (SELECT tranches = ARRAY['adulte_18_plus'] AND etapes = ARRAY['E1', 'E2'] AND lecture_coran = 'hafs'
                                AND offline_policy::text = 'sur_demande' FROM public.library_resource WHERE id = pg_temp.s(1)),
  '3n : tranches, etapes, lecture et lecture hors ligne se reglent');

-- ===================================================================================================
-- 4. Deplacer.
-- ===================================================================================================
SELECT pg_temp.rev(3) AS r3 \gset
SELECT pg_temp.agir(:'k1', 'support_deplacer', pg_catalog.format('{"id": "%s", "revision": %s, "rayon": "plus_loin", "ordre": 7, "etapes": ["E3"]}', pg_temp.s(3), :'r3'), 100) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb #>> '{resultat,ok}')::boolean
                    AND (SELECT rayon = 'plus_loin' AND ordre = 7 AND etapes = ARRAY['E3'] FROM public.library_resource WHERE id = pg_temp.s(3)),
  '4a : le support change de rayon, d''ordre et d''etapes');
SELECT pg_temp.rev(3) AS r3 \gset
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_deplacer', pg_catalog.format(p, pg_temp.s(3), :'r3'), 110 + n) -> 'resultat' ->> 'erreur' = 'parametre',
  '4b : parametre refuse : ' || n)
  FROM (VALUES (1, '{"id": "%s", "revision": %s, "rayon": "zzz"}'), (2, '{"id": "%s", "revision": %s, "ordre": -1}'),
               (3, '{"id": "%s", "revision": %s, "ordre": 100001}'), (4, '{"id": "%s", "revision": %s, "ordre": "3"}'),
               (5, '{"id": "%s", "revision": %s, "titre": "x"}'), (6, '{"id": "%s", "revision": %s, "etapes": "E1"}')) v(n, p);
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_deplacer', pg_catalog.format('{"id": "%s", "revision": %s}', pg_temp.s(3), :'r3'), 120) -> 'resultat' ->> 'erreur' = 'rien_a_changer',
  '4c : sans rayon, ordre ni etapes : rien_a_changer');
SELECT pg_temp.vrai(pg_temp.agir(:'k1', 'support_deplacer', pg_catalog.format('{"id": "%s", "revision": 1, "ordre": 1}', pg_temp.s(3)), 121) -> 'resultat' ->> 'erreur' = 'revision_changee',
  '4d : une revision perimee ne deplace rien');

-- ===================================================================================================
-- 5. Retirer : masquer, jamais effacer, par lot et par code.
-- ===================================================================================================
SELECT pg_temp.agir(:'k1', 'support_retirer', pg_catalog.format('{"id": "%s", "revision": 1, "motif": "Doublon"}', pg_temp.s(4)), 130) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb = '{"erreur": "acte_sensible"}'::jsonb, '5a : retirer ne passe pas par agir : il se prepare');
SELECT pg_temp.rev(4) AS r4 \gset
SELECT pg_temp.rev(5) AS r5 \gset
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''support_retirer'', %L::jsonb)', :'k1',
  pg_catalog.format('[{"id": "%s", "revision": %s, "motif": "x"}]', pg_temp.s(4), :'r4'))) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb ->> 'erreur' = 'refuse' AND :'j'::jsonb ->> 'detail' = 'parametre', '5b : un motif de moins de trois signes est refuse a la preparation');
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''support_retirer'', %L::jsonb)', :'k1',
  pg_catalog.format('[{"id": "%s", "revision": %s, "motif": "Doublon du support 5"}, {"id": "%s", "revision": %s, "motif": "Remplace par une version plus recente"}]',
                    pg_temp.s(4), :'r4', pg_temp.s(5), :'r5'))) AS j \gset
SELECT :'j'::jsonb ->> 'jeton' AS jeton \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND :'j'::jsonb -> 'resume' ->> 0 LIKE 'Retirer « Support fictif 4 » (masque, jamais efface). Motif : Doublon du support 5'
                    AND :'j'::jsonb -> 'resume' ->> 1 LIKE 'Retirer « Support fictif 5 »%',
  '5c : le resume dit le titre, « masque, jamais efface » et le motif de chaque ligne');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.library_resource WHERE archived_at IS NOT NULL) = 0, '5d : la preparation n''a rien retire');
SELECT pg_temp.code_de(:'jeton') AS code \gset
-- Un autre humain modifie le support 5 entre la preparation et la confirmation : sa revision change.
UPDATE public.library_resource SET title = 'Support fictif 5 (retouche a la main)' WHERE id = pg_temp.s(5);
SELECT pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_confirmer(%L, %L::uuid, %L)', :'k1', :'jeton', :'code')) AS j \gset
SELECT pg_temp.vrai((:'j'::jsonb ->> 'ok')::boolean AND (:'j'::jsonb ->> 'nb')::int = 2
                    AND (SELECT archived_at IS NOT NULL FROM public.library_resource WHERE id = pg_temp.s(4))
                    AND :'j'::jsonb #>> '{resultats,0,resultat,ok}' = 'true',
  '5e : le bon code retire le premier support (masque)');
SELECT pg_temp.vrai(:'j'::jsonb #>> '{resultats,1,resultat,erreur}' = 'revision_changee'
                    AND (SELECT archived_at IS NULL FROM public.library_resource WHERE id = pg_temp.s(5)),
  '5f : un support modifie entre-temps n''est PAS retire (revision changee), l''autre ligne est faite');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.library_resource) = 5, '5g : aucun support n''a ete efface : cinq lignes, comme avant');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.audit_logs a WHERE a.action = 'library_withdrawn' AND a.actor = pg_temp.u(1)
                              AND a.row_id = pg_temp.s(4)::text AND a.payload ->> 'motif' = 'Doublon du support 5'),
  '5h : le retrait est trace au nom de la direction, avec son motif');
SELECT pg_temp.vrai(pg_catalog.jsonb_array_length(pg_temp.agir(:'k1', 'support_lister', '{}', 141) -> 'resultat' -> 'supports') = 4
                    AND pg_catalog.jsonb_array_length(pg_temp.agir(:'k1', 'support_lister', '{"retires": true}', 142) -> 'resultat' -> 'supports') = 1,
  '5i : lister montre quatre supports, et un retire avec « retires »');
SELECT pg_temp.agir(:'k1', 'support_modifier', pg_catalog.format('{"id": "%s", "revision": 1, "titre": "x"}', pg_temp.s(4)), 143) AS j \gset
SELECT pg_temp.vrai(:'j'::jsonb #>> '{resultat,erreur}' = 'support_introuvable', '5j : un support retire n''est plus modifiable par le chat');

-- ===================================================================================================
-- 6. La cle de routine ne fait rien.
-- ===================================================================================================
SELECT pg_temp.vrai(pg_temp.srv(pg_catalog.format('SELECT public.praxis_acte_preparer(%L, ''support_retirer'', ''[]''::jsonb)', :'kr')) = '{"erreur": "chat_seulement"}'::jsonb
                    AND pg_temp.srv(pg_catalog.format('SELECT public.praxis_agir(%L, ''support_modifier'', ''{}''::jsonb, %L::uuid)', :'kr', pg_temp.idem(150)))
                        = '{"erreur": "chat_seulement"}'::jsonb, '6a : la cle de routine ne prepare ni n''agit sur la Bibliotheque');

-- ===================================================================================================
-- 7. Les adaptateurs.
-- ===================================================================================================
SELECT pg_temp.vrai(NOT pg_catalog.has_function_privilege(r, p.oid, 'EXECUTE'),
  '7a : ' || p.proname || ' n''est executable par aucun role client (' || r || ')')
  FROM pg_catalog.pg_proc p, unnest(ARRAY['anon', 'authenticated', 'service_role', 'agent_ro']) r
 WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'praxis\_acte\_support\_%' ESCAPE '\';
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p WHERE p.pronamespace = 'private'::regnamespace
                      AND p.proname LIKE 'praxis\_acte\_support\_%' ESCAPE '\') = 4
                    AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p WHERE p.pronamespace = 'private'::regnamespace
                          AND p.proname LIKE 'praxis\_acte\_support\_%' ESCAPE '\' AND p.prosrc ~* 'EXECUTE\s') = 0,
  '7b : quatre adaptateurs, aucun SQL dynamique');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p WHERE p.pronamespace = 'private'::regnamespace
                      AND p.proname = 'praxis_executer_acte' AND p.prosrc ~ 'support_lister' AND p.prosrc ~ 'support_modifier'
                      AND p.prosrc ~ 'support_deplacer' AND p.prosrc ~ 'support_retirer' AND p.prosrc ~ 'ACTES-ANCRE') = 1,
  '7c : le pont a les quatre branches et garde son ancre pour les lots suivants');

ROLLBACK;
\o
SELECT 'PX-BD-BIBLIOTHEQUE : tous les scenarios sont verts' AS resultat;
