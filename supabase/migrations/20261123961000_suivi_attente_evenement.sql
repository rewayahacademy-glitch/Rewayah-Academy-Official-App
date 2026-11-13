-- SUIVI-ATTENTE (lot 1, 13/11/2026) : l'evenement « tout_est_pret » entre dans la
-- contrainte des evenements de notifications. Quand l'etape 5 du suivi de
-- l'attente est atteinte (classe confirmee, enseignant affecte, eleve membre de la
-- classe, premier cours connu), le tuteur ou l'eleve adulte en est prevenu, dans
-- l'application et par courriel. Jamais a un enfant : le destinataire d'un mineur
-- est son tuteur (arbitrage de l'architecte, 13/11/2026).
--
-- FICHIER A MOT D'EFFACEMENT : une contrainte CHECK ne s'elargit pas, elle se
-- remplace (retrait puis ajout de la meme contrainte). Le serveur Supabase demande
-- alors une seconde confirmation que l'application n'affiche pas : le directeur
-- colle ce fichier dans l'editeur SQL, APRES 20261123960000. Un seul mot
-- d'effacement ; aucune donnee n'est supprimee. Sans BEGIN ni COMMIT de premier
-- niveau : un seul bloc, atomique par lui-meme.
--
-- Meme methode que 20261121000000 et que le lot « calendrier et pauses »
-- (20261123911000) : la liste est LUE dans la contrainte en place,
-- « tout_est_pret » y est ajoute s'il n'y est pas, rien d'autre n'est retire ni
-- ajoute. Les valeurs des autres lots, installes avant ou apres, ne sont donc
-- jamais ecrasees ; l'ordre d'installation n'a pas d'importance ; un rejeu ne
-- change rien. Pre-controle : si une ligne existante porte une valeur absente de
-- la nouvelle liste, le fichier s'arrete et ne change rien.
--
-- Tant que ce fichier n'est pas installe, 20261123962000 enregistre le fait et
-- n'envoie pas la notification (avertissement dans le journal du serveur) : un
-- evenement refuse par la contrainte n'empeche jamais l'ajout d'une seance ou d'un
-- eleve.

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
    RAISE EXCEPTION 'tout_est_pret : la contrainte notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''tout_est_pret''%' THEN
    RAISE NOTICE 'tout_est_pret : deja dans la contrainte, rien a faire';
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
    RAISE EXCEPTION 'tout_est_pret : liste des evenements illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['tout_est_pret'];

  -- Pre-controle : aucune ligne existante ne porte une valeur hors de la
  -- nouvelle liste (elle ne pourrait plus etre ecrite apres le remplacement).
  IF EXISTS (SELECT 1 FROM public.notifications n WHERE NOT (n.evenement = ANY (v_nouvelle))) THEN
    RAISE EXCEPTION 'tout_est_pret : une notification existante porte un evenement absent de la nouvelle liste, rien n''est change';
  END IF;

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
  IF v_def IS NULL OR v_def NOT LIKE '%''tout_est_pret''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'tout_est_pret : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$migration$;
