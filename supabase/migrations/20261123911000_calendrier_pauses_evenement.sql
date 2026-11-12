-- CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : l'evenement « pause_repondue » entre
-- dans la contrainte des evenements de notifications. La reponse de la direction a
-- une demande de pause de la famille (acceptee ou refusee, avec son motif) arrive
-- ainsi dans l'application du tuteur ou de l'adulte, par la chaine de notifications
-- existante. Jamais a un mineur : le destinataire d'un enfant est son tuteur.
--
-- FICHIER A MOT D'EFFACEMENT (B5) : une contrainte CHECK ne s'elargit pas, elle se
-- remplace (retrait puis ajout de la meme contrainte). Le serveur Supabase demande
-- alors une seconde confirmation que l'application n'affiche pas : le directeur
-- colle ce fichier dans l'editeur SQL, APRES 20261123910000. Un seul mot
-- d'effacement ; aucune donnee n'est supprimee. Sans BEGIN ni COMMIT de premier
-- niveau : un seul bloc, atomique par lui-meme.
--
-- Comme 20261121000000 : la liste est LUE dans la contrainte en place,
-- « pause_repondue » y est ajoute s'il n'y est pas, rien d'autre n'est retire ni
-- ajoute ; l'ordre d'installation avec les autres lots n'a pas d'importance ; un
-- rejeu ne change rien.
--
-- Tant que ce fichier n'est pas installe, pause_decider enregistre la decision et
-- n'envoie pas la notification (avertissement dans le journal du serveur).

DO $migration$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'pause_repondue : la contrainte notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''pause_repondue''%' THEN
    RAISE NOTICE 'pause_repondue : deja dans la contrainte, rien a faire';
    RETURN;
  END IF;
  -- Les evenements de la contrainte en place, dans leur ordre. Selon le fichier
  -- qui l'a posee, pg_get_constraintdef rend la liste sous deux formes :
  -- ARRAY['x'::text, 'y'::text] ou '{x,y}'::text[]. Les deux sont lues.
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_liste
    FROM pg_catalog.regexp_matches(v_def, '''([a-z_]+)''::text', 'g')
         WITH ORDINALITY AS r(m, ord);
  IF v_liste IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_liste
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_liste IS NULL OR pg_catalog.cardinality(v_liste) < 10
     OR NOT ('demande_recue' = ANY (v_liste)) THEN
    RAISE EXCEPTION 'pause_repondue : liste des evenements illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['pause_repondue'];

  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  -- Postflight : tout ce qui y etait y est encore, plus le nouvel evenement.
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL OR v_def NOT LIKE '%''pause_repondue''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'pause_repondue : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$migration$;
