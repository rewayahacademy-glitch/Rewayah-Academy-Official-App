-- CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : quatre evenements entrent dans la
-- contrainte des evenements de notifications : « pause_repondue » (la reponse de la
-- direction a une demande de pause de la famille, acceptee ou refusee, avec son
-- motif), « fermeture_annoncee » (une fermeture de l'academie met des seances de
-- cote : une notification par classe), « fermeture_levee » (la fermeture est
-- retiree, ou une classe n'est plus couverte : les seances sont retablies, ou
-- abandonnees sur confirmation de la direction) et « fermeture_conflit » (la cloche
-- de nuit ne peut pas retablir une seance qui n'est plus sous une fermeture,
-- l'enseignant ayant pris un autre cours : la direction tranche). Dans
-- l'application du tuteur, de l'adulte autonome, de l'enseignant de la classe et de
-- la direction, par la chaine de notifications existante. Jamais a un mineur : le
-- destinataire d'un enfant est son tuteur. Ni courriel ni push.
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
-- n'envoie pas la notification, et une fermeture publiee ou retiree met les seances
-- de cote ou les retablit sans notification (avertissement dans le journal du
-- serveur). Compatible dans les deux ordres avec les autres fichiers qui elargissent
-- la meme contrainte (20261123961000 et les suivants) : la liste est LUE, rien n'est
-- retire.

DO $migration$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
  v_ajout text;
  v_relu integer;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'pause_repondue : la contrainte notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''pause_repondue''%' AND v_def LIKE '%''fermeture_annoncee''%'
     AND v_def LIKE '%''fermeture_levee''%' AND v_def LIKE '%''fermeture_conflit''%' THEN
    RAISE NOTICE 'evenements du lot 2 : deja dans la contrainte, rien a faire';
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
    RAISE EXCEPTION 'pause_repondue : liste des evenements illisible dans %', v_def;
  END IF;
  -- Les trois evenements du lot, dans leur ordre, ceux qui y sont deja ne sont pas redoubles.
  v_nouvelle := v_liste;
  FOREACH v_ajout IN ARRAY ARRAY['pause_repondue', 'fermeture_annoncee', 'fermeture_levee', 'fermeture_conflit'] LOOP
    IF NOT (v_ajout = ANY (v_nouvelle)) THEN
      v_nouvelle := v_nouvelle || v_ajout;
    END IF;
  END LOOP;

  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  -- Postflight : tout ce qui y etait y est encore, plus les nouveaux evenements ; le NOMBRE de valeurs
  -- relu dans la contrainte est exactement l'ancien nombre plus les valeurs ajoutees.
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  SELECT pg_catalog.count(*)::integer INTO v_relu
    FROM pg_catalog.regexp_matches(v_def, '''([a-z0-9_]+)''::text', 'g') AS r(m);
  IF v_relu = 0 THEN
    SELECT pg_catalog.cardinality(pg_catalog.string_to_array(m[1], ',')) INTO v_relu
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z0-9_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_relu IS DISTINCT FROM pg_catalog.cardinality(v_nouvelle) THEN
    RAISE EXCEPTION 'evenements du lot 2 : % valeurs relues au lieu de %', v_relu, pg_catalog.cardinality(v_nouvelle);
  END IF;
  IF v_def IS NULL OR v_def NOT LIKE '%''pause_repondue''%'
     OR v_def NOT LIKE '%''fermeture_annoncee''%' OR v_def NOT LIKE '%''fermeture_levee''%'
     OR v_def NOT LIKE '%''fermeture_conflit''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'pause_repondue : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$migration$;
