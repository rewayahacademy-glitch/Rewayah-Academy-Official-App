-- MASQUER-ENTRETIENS-PRAXIS (20/11/2026).
--
-- Ordres du directeur, 20/11/2026 : les entretiens ecrits envoyes par Praxis ne doivent plus etre vus par
-- personne ; seuls ceux auxquels le destinataire n'a pas repondu sont concernes ; « c'est une question de
-- securite, il faut retirer ces messages vite ».
--
-- Pourquoi ce fichier : la migration 20261130700000 fait ce retrait par effacement des lignes. Le connecteur de
-- la base exige pour cela une confirmation a l'ecran du directeur, qui ne s'est jamais affichee chez lui (trois
-- essais, 20/11/2026). Elle n'est donc PAS installee en production. Ce fichier obtient le meme resultat pour
-- les personnes sans rien effacer : les messages restent dans public.com_messages (table en ajout seul,
-- inchangee), mais ils sont inscrits dans private.com_messages_masques, et la seule fonction qui sert les
-- messages a l'application (private.com_fil_json : liste des conversations, conversation ouverte, compte des
-- non lus) ne les rend plus. Reversible : retirer une ligne de private.com_messages_masques rend le message.
--
-- Ce qui est masque : le message de chaque ouverture d'entretien ecrit de Praxis (private.praxis_ouvertures,
-- raison 'entretien_ecrit' ou 'relance_entretien') auquel la personne de la conversation n'a ecrit aucun
-- message ensuite. Ce qui reste visible : un entretien auquel la personne a repondu, avec sa reponse et la
-- suite ; les annonces d'admission ; tout message d'une personne ou de la direction ; toute autre reponse de
-- Praxis.
--
-- Ce que fait le fichier, en un bloc (tout ou rien) :
--   1. cree private.com_messages_masques (lisible par personne) ;
--   2. sous verrou des conversations et des messages, y inscrit les messages vises ;
--   3. retouche private.com_fil_json par ancrage (deux endroits : le compte des non lus, la liste des
--      messages), apres controle de l'empreinte de la version en place ; aucun autre mot ne change ;
--   4. recalcule com_fils.dernier_message_le des conversations touchees sur les messages encore visibles ;
--   5. pose un signal de relecture (nature 'lecture' : aucun avis « Nouveau message ») a chaque personne ;
--   6. controle le resultat.
--
-- GARDES : plus de 97 messages vises, un message vise envoye apres l'inventaire (20/11/2026, 10:45 UTC), ou
-- qui n'est pas de Praxis : erreur, rien n'est change. Aucun message vise (base de test) : la table et la
-- retouche de la fonction sont installees, rien n'est masque.
--
-- Limite connue : les outils de Praxis lisent encore ces messages (il est a l'arret ; le lot PX-6 traite ce
-- point). FICHIER SANS EFFACEMENT. Sans BEGIN/COMMIT de premier niveau.

CREATE TABLE private.com_messages_masques (
  message_id uuid PRIMARY KEY,
  masque_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  motif text NOT NULL CHECK (pg_catalog.length(motif) BETWEEN 1 AND 500)
);
ALTER TABLE private.com_messages_masques ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.com_messages_masques FROM PUBLIC, anon, authenticated, service_role;
ALTER TABLE private.com_messages_masques OWNER TO postgres;
COMMENT ON TABLE private.com_messages_masques IS
  'MASQUER-ENTRETIENS-PRAXIS (20/11/2026) : messages que private.com_fil_json ne rend plus a personne, sur ordre '
  'du directeur. Aucune politique, aucun droit : personne ne la lit par l''application.';

DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON TABLE private.com_messages_masques FROM agent_ro';
  END IF;
END
$droits$;

DO $masquage$
DECLARE
  v_praxis uuid := private.praxis_profil();
  v_cibles uuid[];
  v_fils uuid[];
  v_n integer;
  v_compte integer;
  v_qui uuid;
  v_fil uuid;
  v_oid oid := 'private.com_fil_json(uuid, uuid, text, uuid)'::pg_catalog.regprocedure;
  v_def text;
  v_ancre_non_lus constant text := 'WHERE m.fil_id = f.id AND m.auteur_id <> p_moi AND NOT EXISTS (SELECT 1 FROM public.com_message_images ix';
  v_ancre_messages constant text := 'WHERE m.fil_id = f.id AND NOT EXISTS (SELECT 1 FROM public.com_message_images ix';
  v_filtre constant text := 'NOT EXISTS (SELECT 1 FROM private.com_messages_masques mk WHERE mk.message_id = m.id) AND ';
BEGIN
  -- Rien ne bouge entre la selection et le masquage : les envois verrouillent la conversation puis inserent le
  -- message, on prend donc com_fils d'abord, en mode exclusif, puis com_messages. Si un envoi en cours ne rend
  -- pas la main en 5 secondes, tout echoue sans rien changer.
  SET LOCAL lock_timeout = '5s';
  LOCK TABLE public.com_fils IN EXCLUSIVE MODE;
  LOCK TABLE public.com_messages IN SHARE ROW EXCLUSIVE MODE;

  -- 3 (d'abord, pour echouer avant toute ecriture si la fonction en place n'est pas celle attendue).
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v_oid)
       IS DISTINCT FROM '3002018f5fa3b207660bf515d959e92f' THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : private.com_fil_json n''est pas la version attendue (empreinte %) : rien n''est change',
      (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v_oid);
  END IF;
  v_def := pg_catalog.pg_get_functiondef(v_oid);
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre_non_lus, ''))) / pg_catalog.length(v_ancre_non_lus) <> 1
     OR (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre_messages, ''))) / pg_catalog.length(v_ancre_messages) <> 1 THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : ancres de private.com_fil_json introuvables ou repetees : rien n''est change';
  END IF;
  v_def := pg_catalog.replace(v_def, v_ancre_non_lus,
    'WHERE m.fil_id = f.id AND m.auteur_id <> p_moi AND ' || v_filtre || 'NOT EXISTS (SELECT 1 FROM public.com_message_images ix');
  v_def := pg_catalog.replace(v_def, v_ancre_messages,
    'WHERE m.fil_id = f.id AND ' || v_filtre || 'NOT EXISTS (SELECT 1 FROM public.com_message_images ix');
  EXECUTE v_def;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v_oid)
       IS DISTINCT FROM '74009ca16372e60e76b3745bf11abad0' THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : private.com_fil_json retouchee n''a pas l''empreinte attendue (%) : rien n''est change',
      (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v_oid);
  END IF;

  -- 2. Les messages vises : le message de chaque ouverture d'entretien ecrit auquel la personne de la
  -- conversation n'a pas repondu (aucun message d'elle apres l'entretien).
  SELECT pg_catalog.array_agg(DISTINCT e.message_id), pg_catalog.array_agg(DISTINCT e.fil_id),
         pg_catalog.count(DISTINCT e.message_id)::integer
    INTO v_cibles, v_fils, v_n
    FROM (SELECT o.message_id, o.fil_id, m.envoye_le
            FROM private.praxis_ouvertures o
            JOIN public.com_messages m ON m.id = o.message_id
           WHERE o.raison IN ('entretien_ecrit', 'relance_entretien')) e
   WHERE NOT EXISTS (SELECT 1 FROM public.com_messages r
                      WHERE r.fil_id = e.fil_id AND r.envoye_le > e.envoye_le
                        AND private.praxis_est_partie_a(r.auteur_id, r.fil_id));

  IF v_n = 0 THEN
    RAISE NOTICE 'MASQUER-ENTRETIENS : aucun message vise ; la fonction est retouchee, rien n''est masque';
    RETURN;
  END IF;
  IF v_n > 97 THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : % messages vises, 97 au plus attendus (inventaire du 20/11) : rien n''est change', v_n;
  END IF;
  IF v_praxis IS NULL THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : compte Praxis introuvable : rien n''est change';
  END IF;
  SELECT pg_catalog.count(*)::integer INTO v_compte FROM public.com_messages m
   WHERE m.id = ANY (v_cibles)
     AND (m.envoye_le > timestamptz '2026-11-20 10:45:00+00' OR m.auteur_id IS DISTINCT FROM v_praxis);
  IF v_compte <> 0 THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : % messages vises ne sont pas de Praxis ou datent d''apres l''inventaire : rien n''est change', v_compte;
  END IF;

  INSERT INTO private.com_messages_masques (message_id, motif)
  SELECT x.id, 'Entretien ecrit envoye par Praxis, reste sans reponse du destinataire, masque pour tout le monde sur ordre du directeur du 20/11/2026'
    FROM pg_catalog.unnest(v_cibles) AS x(id);
  GET DIAGNOSTICS v_compte = ROW_COUNT;
  IF v_compte <> v_n THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : % messages inscrits pour % vises', v_compte, v_n;
  END IF;

  -- 4. La date du dernier message des conversations touchees : celle du dernier message encore visible.
  UPDATE public.com_fils f
     SET dernier_message_le = (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m
                                WHERE m.fil_id = f.id
                                  AND NOT EXISTS (SELECT 1 FROM private.com_messages_masques mk WHERE mk.message_id = m.id))
   WHERE f.id = ANY (v_fils);

  -- 5. Un signal de relecture par personne concernee (une ligne par personne dans com_signaux).
  FOR v_qui, v_fil IN
    SELECT DISTINCT ON (q.qui) q.qui, x.fil
      FROM pg_catalog.unnest(v_fils) AS x(fil)
      CROSS JOIN LATERAL private.com_destinataires_signal(x.fil, NULL) AS q(qui)
     ORDER BY q.qui, x.fil
  LOOP
    PERFORM private.com_signal_poser(v_qui, v_fil, 'lecture');
  END LOOP;

  -- 6. Le controle.
  IF (SELECT pg_catalog.count(*) FROM private.com_messages_masques) <> v_n THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : la table des messages masques ne compte pas % lignes', v_n;
  END IF;
  IF EXISTS (SELECT 1 FROM private.com_messages_masques mk
              WHERE NOT EXISTS (SELECT 1 FROM public.com_messages m WHERE m.id = mk.message_id)) THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : un message masque n''existe pas';
  END IF;
  RAISE NOTICE 'MASQUER-ENTRETIENS : % messages masques, % conversations touchees', v_n, pg_catalog.cardinality(v_fils);
END
$masquage$;

-- Controle final, hors du bloc : la fonction retouchee garde ses attributs et ses droits, la table est fermee.
DO $final$
DECLARE
  v_oid oid := 'private.com_fil_json(uuid, uuid, text, uuid)'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND NOT p.prosecdef AND p.provolatile = 's'
                    AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole
                    AND pg_catalog.md5(p.prosrc) = '74009ca16372e60e76b3745bf11abad0') THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : private.com_fil_json n''a pas les attributs attendus';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : private.com_fil_json est devenue executable par un role de l''interface';
  END IF;
  IF pg_catalog.has_table_privilege('anon', 'private.com_messages_masques', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'private.com_messages_masques', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'private.com_messages_masques', 'SELECT')
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'private.com_messages_masques'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'MASQUER-ENTRETIENS : private.com_messages_masques n''est pas fermee';
  END IF;
END
$final$;
