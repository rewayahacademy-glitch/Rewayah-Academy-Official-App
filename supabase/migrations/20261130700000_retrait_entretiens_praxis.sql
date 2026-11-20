-- RETRAIT-ENTRETIENS-PRAXIS (20/11/2026).
--
-- Ordre du directeur, 20/11/2026 : « Supprime tous les messages d'entretiens que praxis a envoyé. Pour tout le
-- monde, personne ne doit les voir. »
--
-- Inventaire fait en production le 20/11/2026 a 10:40 UTC (lecture seule) :
--   - 100 messages d'entretien ecrit, un par conversation de candidature, tous ecrits par le compte Praxis
--     (private.praxis_ouvertures, raison 'entretien_ecrit' ; aucune 'relance_entretien') ;
--   - 3 messages de Praxis envoyes ensuite dans ces memes conversations : ses remerciements pour les reponses
--     a l'entretien (lus un par un par le pilote) ;
--   - aucun coeur, aucune image sur ces 103 messages ;
--   - les 26 messages 'felicitations' (l'annonce de l'admission, dans les mots du directeur) ne sont PAS vises ;
--   - les reponses des candidats (4 messages, 3 conversations) ne sont PAS visees : ce sont leurs messages.
--
-- public.com_messages est en ajout seul (declencheur com_messages_ajout_seul, COM-BACK-1) et l'application n'a
-- aucun geste de suppression. Cette migration fait donc le retrait, UNE fois, dans UN bloc (tout ou rien) :
--   1. elle cree private.com_messages_retires, lisible par personne, et y range une copie des messages retires
--      (trace : on sait ce qui a ete retire, quand et pourquoi) ;
--   2. elle suspend le declencheur d'ajout seul, retire les messages, remet le declencheur ;
--   3. elle recalcule com_fils.dernier_message_le des conversations touchees (vide = NULL, comme toute
--      conversation sans message) ;
--   4. elle pose un signal de relecture (nature 'lecture' : aucun avis « Nouveau message ») a chaque personne
--      concernee, pour que les ecrans ouverts se relisent ;
--   5. elle controle : plus aucun message vise, declencheur actif, copie complete.
--
-- GARDE : le retrait n'a lieu que si les messages vises sont exactement 103 (l'inventaire) ; 0 message vise
-- (base de test, base deja traitee) : rien n'est retire, la migration passe ; tout autre nombre : erreur, rien
-- n'est retire. private.praxis_ouvertures n'est pas touchee : elle garde la trace que ces personnes ont ete
-- contactees (et empeche un nouvel entretien automatique).
--
-- Mots d'effacement : 1 DELETE (les 103 messages, sur ordre explicite du directeur), 0 DROP, 0 TRUNCATE.

CREATE TABLE private.com_messages_retires (
  id uuid PRIMARY KEY,
  fil_id uuid NOT NULL,
  auteur_id uuid NOT NULL,
  cle_idempotence uuid NOT NULL,
  texte text NOT NULL,
  envoye_le timestamptz NOT NULL,
  retire_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  motif text NOT NULL CHECK (pg_catalog.length(motif) BETWEEN 1 AND 500)
);
ALTER TABLE private.com_messages_retires ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.com_messages_retires FROM PUBLIC, anon, authenticated, service_role;
ALTER TABLE private.com_messages_retires OWNER TO postgres;
COMMENT ON TABLE private.com_messages_retires IS
  'RETRAIT-ENTRETIENS-PRAXIS (20/11/2026) : copie des messages retires de com_messages sur ordre du directeur. '
  'Aucune politique, aucun droit : personne ne la lit par l''application.';

DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON TABLE private.com_messages_retires FROM agent_ro';
  END IF;
END
$droits$;

DO $retrait$
DECLARE
  v_praxis uuid := private.praxis_profil();
  v_cibles uuid[];
  v_fils uuid[];
  v_n integer;
  v_compte integer;
  v_qui uuid;
  v_fil uuid;
BEGIN
  -- Les messages vises : (a) le message de chaque ouverture d'entretien ecrit ; (b) tout message du compte Praxis
  -- envoye ensuite dans la meme conversation.
  WITH entretiens AS (
    SELECT o.message_id, o.fil_id, m.envoye_le
      FROM private.praxis_ouvertures o
      JOIN public.com_messages m ON m.id = o.message_id
     WHERE o.raison IN ('entretien_ecrit', 'relance_entretien')
  ), cibles AS (
    SELECT e.message_id AS id, e.fil_id FROM entretiens e
    UNION
    SELECT m.id, m.fil_id
      FROM entretiens e
      JOIN public.com_messages m ON m.fil_id = e.fil_id AND m.auteur_id = v_praxis AND m.envoye_le > e.envoye_le
  )
  SELECT pg_catalog.array_agg(DISTINCT c.id), pg_catalog.array_agg(DISTINCT c.fil_id), pg_catalog.count(DISTINCT c.id)::integer
    INTO v_cibles, v_fils, v_n
    FROM cibles c;

  IF v_n = 0 THEN
    RAISE NOTICE 'RETRAIT-ENTRETIENS-PRAXIS : aucun message vise, rien a retirer';
    RETURN;
  END IF;
  IF v_n <> 103 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages vises, 103 attendus (inventaire du 20/11) : rien n''est retire', v_n;
  END IF;
  IF v_praxis IS NULL THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : compte Praxis introuvable : rien n''est retire';
  END IF;

  -- Tous ecrits par Praxis, et par lui seul.
  SELECT pg_catalog.count(*)::integer INTO v_compte FROM public.com_messages m
   WHERE m.id = ANY (v_cibles) AND m.auteur_id IS DISTINCT FROM v_praxis;
  IF v_compte <> 0 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages vises ne sont pas de Praxis : rien n''est retire', v_compte;
  END IF;
  -- Rien d'attache (coeur, image) : ces lignes bloqueraient le retrait.
  SELECT (SELECT pg_catalog.count(*) FROM public.com_message_coeurs k WHERE k.message_id = ANY (v_cibles))::integer
       + (SELECT pg_catalog.count(*) FROM public.com_message_images i WHERE i.message_id = ANY (v_cibles))::integer
    INTO v_compte;
  IF v_compte <> 0 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % coeurs ou images attaches aux messages vises : rien n''est retire', v_compte;
  END IF;

  -- 1. La copie.
  INSERT INTO private.com_messages_retires (id, fil_id, auteur_id, cle_idempotence, texte, envoye_le, motif)
  SELECT m.id, m.fil_id, m.auteur_id, m.cle_idempotence, m.texte, m.envoye_le,
         'Entretien ecrit envoye par Praxis, retire pour tout le monde sur ordre du directeur du 20/11/2026'
    FROM public.com_messages m
   WHERE m.id = ANY (v_cibles);
  GET DIAGNOSTICS v_compte = ROW_COUNT;
  IF v_compte <> v_n THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages copies pour % vises', v_compte, v_n;
  END IF;

  -- 2. Le retrait. La table est en ajout seul : son declencheur est suspendu le temps de cette instruction.
  ALTER TABLE public.com_messages DISABLE TRIGGER com_messages_ajout_seul;
  DELETE FROM public.com_messages m WHERE m.id = ANY (v_cibles);
  GET DIAGNOSTICS v_compte = ROW_COUNT;
  ALTER TABLE public.com_messages ENABLE TRIGGER com_messages_ajout_seul;
  IF v_compte <> v_n THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages retires pour % vises', v_compte, v_n;
  END IF;

  -- 3. La date du dernier message des conversations touchees.
  UPDATE public.com_fils f
     SET dernier_message_le = (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m WHERE m.fil_id = f.id)
   WHERE f.id = ANY (v_fils);

  -- 4. Un signal de relecture par personne concernee (une ligne par personne dans com_signaux).
  FOR v_qui, v_fil IN
    SELECT DISTINCT ON (q.qui) q.qui, x.fil
      FROM pg_catalog.unnest(v_fils) AS x(fil)
      CROSS JOIN LATERAL private.com_destinataires_signal(x.fil, NULL) AS q(qui)
     ORDER BY q.qui, x.fil
  LOOP
    PERFORM private.com_signal_poser(v_qui, v_fil, 'lecture');
  END LOOP;

  -- 5. Le controle.
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.id = ANY (v_cibles)) THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : des messages vises sont encore la';
  END IF;
  IF (SELECT t.tgenabled FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.com_messages'::pg_catalog.regclass AND t.tgname = 'com_messages_ajout_seul') IS DISTINCT FROM 'O' THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : le declencheur d''ajout seul n''est pas actif';
  END IF;
  IF (SELECT pg_catalog.count(*) FROM private.com_messages_retires) <> v_n THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : la copie ne compte pas % messages', v_n;
  END IF;
  IF EXISTS (SELECT 1 FROM public.com_fils f
              WHERE f.id = ANY (v_fils)
                AND f.dernier_message_le IS DISTINCT FROM
                    (SELECT pg_catalog.max(m.envoye_le) FROM public.com_messages m WHERE m.fil_id = f.id)) THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : date du dernier message fausse sur une conversation';
  END IF;
  RAISE NOTICE 'RETRAIT-ENTRETIENS-PRAXIS : % messages retires, % conversations touchees', v_n, pg_catalog.cardinality(v_fils);
END
$retrait$;

-- Hors du bloc : le declencheur d'ajout seul est actif, quoi qu'il se soit passe.
DO $final$
BEGIN
  IF (SELECT t.tgenabled FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.com_messages'::pg_catalog.regclass AND t.tgname = 'com_messages_ajout_seul') IS DISTINCT FROM 'O' THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : le declencheur d''ajout seul n''est pas actif';
  END IF;
END
$final$;
