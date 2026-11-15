-- A DECIDER PAR LE PILOTE (ANNONCES-SIMPLES, 14/11/2026). CE N'EST PAS UNE
-- MIGRATION DU DEPOT : le lot a pour regle « aucun DROP », et une contrainte
-- CHECK ne s'elargit qu'en la remplacant (retrait puis ajout). Ce fichier est
-- donc range hors de supabase/migrations/.
--
-- Effet : l'evenement « annonce_direction » entre dans la contrainte des
-- notifications. Sans lui, une annonce de la direction arrive dans le fil
-- d'annonces de chaque destinataire (et par courriel si la direction le
-- demande), mais AUCUNE notification n'apparait sous la cloche des adultes :
-- `com_annonce_envois.notifiees` reste a 0. Aucune notification n'est jamais
-- posee pour un mineur (la migration 20261126900000 l'exclut).
--
-- Si le pilote l'accepte : le deplacer dans supabase/migrations/ sous ce nom,
-- le coller dans l'editeur SQL APRES 20261126900000 (un mot d'effacement : la
-- seconde confirmation du serveur), puis les annonces suivantes notifient.
-- Les annonces deja distribuees ne sont pas renotifiees.
--
-- Meme methode que 20261123961000 (lecture de la liste en place, ajout d'une
-- seule valeur, pre-controle, postflight). Sans BEGIN ni COMMIT de premier
-- niveau. Rejouable.

DO $migration$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
  v_apres integer;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'annonce_direction : la contrainte notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''annonce_direction''%' THEN
    RAISE NOTICE 'annonce_direction : deja dans la contrainte, rien a faire';
    RETURN;
  END IF;
  -- Les evenements de la contrainte en place, dans leur ordre. Selon le fichier
  -- qui l'a posee, pg_get_constraintdef rend la liste sous deux formes :
  -- ARRAY['x'::text, 'y'::text] ou '{x,y}'::text[]. Les deux sont lues.
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_liste
    FROM pg_catalog.regexp_matches(v_def, '''([a-z0-9_]+)''::text', 'g')
         WITH ORDINALITY AS r(m, ord);
  IF v_liste IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_liste
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z0-9_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_liste IS NULL OR pg_catalog.cardinality(v_liste) < 10
     OR NOT ('demande_recue' = ANY (v_liste)) THEN
    RAISE EXCEPTION 'annonce_direction : liste des evenements illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['annonce_direction'];

  -- Pre-controle : aucune ligne existante ne porte une valeur hors de la
  -- nouvelle liste (elle ne pourrait plus etre ecrite apres le remplacement).
  IF EXISTS (SELECT 1 FROM public.notifications n WHERE NOT (n.evenement = ANY (v_nouvelle))) THEN
    RAISE EXCEPTION 'annonce_direction : une notification existante porte un evenement absent de la nouvelle liste, rien n''est change';
  END IF;

  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  -- Postflight : la contrainte relue porte UNE valeur de plus qu'avant (le
  -- nombre, pas la liste relue) et le nouvel evenement.
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.count(*) INTO v_apres
    FROM pg_catalog.regexp_matches(v_def, '''([a-z0-9_]+)''::text', 'g') AS r(m);
  IF v_apres = 0 THEN
    SELECT pg_catalog.cardinality(pg_catalog.string_to_array(m[1], ',')) INTO v_apres
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z0-9_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_def IS NULL OR v_def NOT LIKE '%''annonce_direction''%'
     OR v_apres IS DISTINCT FROM pg_catalog.cardinality(v_liste) + 1 THEN
    RAISE EXCEPTION 'annonce_direction : la contrainte doit porter % valeurs (une de plus), elle en porte % : %',
      pg_catalog.cardinality(v_liste) + 1, v_apres, v_def;
  END IF;
END
$migration$;
