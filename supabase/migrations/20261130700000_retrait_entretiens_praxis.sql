-- RETRAIT-ENTRETIENS-PRAXIS (20/11/2026).
--
-- Ordres du directeur, 20/11/2026 :
--   « Supprime tous les messages d'entretiens que praxis a envoyé. Pour tout le monde, personne ne doit les voir. »
--   puis, apres l'inventaire : « Pour la suppression, tu supprimes tous les messages qui n'ont pas encore été
--   répondus par les destinataires. »
--
-- Ce qui est retire : le message d'entretien ecrit de chaque ouverture de Praxis (private.praxis_ouvertures,
-- raison 'entretien_ecrit' ou 'relance_entretien') auquel le destinataire n'a PAS repondu, c'est-a-dire quand
-- la personne de la conversation n'y a ecrit aucun message apres l'entretien.
-- Ce qui reste : un entretien auquel la personne a repondu (avec sa reponse et la suite de l'echange) ; les
-- annonces d'admission de Praxis (raison 'felicitations') ; tout message d'une personne ou de la direction ;
-- toute autre reponse de Praxis.
--
-- Inventaire fait en production le 20/11/2026 (lecture seule) : 100 entretiens ecrits, un par conversation de
-- candidature, tous ecrits par le compte Praxis ; 3 ont recu une reponse ; aucun coeur, aucune image.
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
--   5. elle controle : plus aucun message vise, declencheur actif, copie complete, dates justes.
--
-- GARDES : aucun message vise (base de test, base deja traitee) : rien n'est retire, la migration passe. Plus
-- de 97 messages vises (l'inventaire en compte 97 sans reponse ; ce nombre ne peut que baisser) : erreur, rien
-- n'est retire. Un message vise envoye apres l'inventaire (20/11/2026, 10:45 UTC), qui n'est pas de Praxis, qui
-- porte un coeur ou une image, ou dont la conversation a recu un message de la personne apres lui : erreur,
-- rien n'est retire. Les tables des conversations et des messages sont verrouillees le temps du bloc (une
-- fraction de seconde) : aucune reponse ne peut arriver entre la selection et le retrait. private.praxis_ouvertures n'est pas touchee : elle garde la
-- trace que ces personnes ont ete contactees (et empeche un nouvel entretien automatique).
--
-- Mots d'effacement : 1 DELETE (sur ordre explicite du directeur), 0 DROP, 0 TRUNCATE.

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
  -- Rien ne bouge entre la selection et le retrait (relecture adverse du 20/11 : sans ces verrous, une reponse
  -- arrivee pendant l'execution n'etait pas vue et son entretien etait retire quand meme). Les envois verrouillent
  -- la conversation puis inserent le message : on prend donc com_fils d'abord, en mode exclusif, puis
  -- com_messages. Si un envoi en cours ne rend pas la main en 5 secondes, la migration echoue sans rien changer.
  SET LOCAL lock_timeout = '5s';
  LOCK TABLE public.com_fils IN EXCLUSIVE MODE;
  LOCK TABLE public.com_messages IN SHARE ROW EXCLUSIVE MODE;

  -- Les messages vises : le message de chaque ouverture d'entretien ecrit auquel la personne de la conversation
  -- n'a pas repondu (aucun message d'elle apres l'entretien).
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
    RAISE NOTICE 'RETRAIT-ENTRETIENS-PRAXIS : aucun message vise, rien a retirer';
    RETURN;
  END IF;
  IF v_n > 97 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages vises, 97 au plus attendus (inventaire du 20/11) : rien n''est retire', v_n;
  END IF;
  -- Aucun entretien envoye apres l'inventaire : il n'aurait ete vu par personne avant son retrait.
  SELECT pg_catalog.count(*)::integer INTO v_compte FROM public.com_messages m
   WHERE m.id = ANY (v_cibles) AND m.envoye_le > timestamptz '2026-11-20 10:45:00+00';
  IF v_compte <> 0 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages vises ont ete envoyes apres l''inventaire : rien n''est retire', v_compte;
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
  -- Aucun n'a recu de reponse de la personne (relu apres la selection : la regle du directeur).
  SELECT pg_catalog.count(*)::integer INTO v_compte
    FROM public.com_messages m
   WHERE m.id = ANY (v_cibles)
     AND EXISTS (SELECT 1 FROM public.com_messages r
                  WHERE r.fil_id = m.fil_id AND r.envoye_le > m.envoye_le
                    AND private.praxis_est_partie_a(r.auteur_id, r.fil_id));
  IF v_compte <> 0 THEN
    RAISE EXCEPTION 'RETRAIT-ENTRETIENS-PRAXIS : % messages vises ont recu une reponse : rien n''est retire', v_compte;
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
         'Entretien ecrit envoye par Praxis, reste sans reponse du destinataire, retire pour tout le monde sur ordre du directeur du 20/11/2026'
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
