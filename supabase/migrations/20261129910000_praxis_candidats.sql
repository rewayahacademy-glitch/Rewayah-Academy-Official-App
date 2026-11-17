-- PRAXIS-CANDIDATS (directeur, 17/11/2026 : « les candidats sont des centaines ») : Praxis lit et ecrit les conversations de CANDIDATURE
-- entre un candidat enseignant et l'academie, jusqu'ici fermees (type_ferme). Retouche par ancrage de trois fonctions, signatures inchangees :
--   private.praxis_types_fil()  : + 'candidature'
--   private.praxis_fil_refus    : candidature vivante (en_cours, hors pause, etape <> confirmee, type enseignant, partie A = le candidat),
--                                 cote = genre de la candidature ; mineur, essai, donnees reelles, hors_academie inchanges
--   public.praxis_ecrire        : le test fil_ferme (com_paires, qui lit auth.uid()) ne s'applique plus aux candidatures
-- Rien d'autre : ni piece d'identite, ni paiement, ni note d'entretien (Praxis ne lit que les messages du fil). La reprise par l'equipe
-- (repris_par_equipe) passe par praxis_est_equipe, independant du type.  Additive : aucune suppression.
DO $pre$
BEGIN
  IF md5((SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'private.praxis_types_fil()'::regprocedure)) <> 'ba5a360ccf4f1f351a559042784ab94b'
     OR md5((SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'private.praxis_fil_refus(uuid,gender[])'::regprocedure)) <> '1b94e16d61a3b447ad51193776a6b4c0'
     OR md5((SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.praxis_ecrire(text,uuid,text,uuid)'::regprocedure)) <> '0ac48bc2843ef72796de19e6de7c49a3' THEN
    RAISE EXCEPTION 'PRAXIS-CANDIDATS : empreinte inattendue (une des trois fonctions a change) ; rien n''est applique';
  END IF;
END
$pre$;

CREATE OR REPLACE FUNCTION private.praxis_types_fil()
 RETURNS text[]
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT ARRAY['classe', 'eleve', 'dossier', 'remplacement', 'candidature']::text[];
$function$;

CREATE OR REPLACE FUNCTION private.praxis_fil_refus(p_fil uuid, p_cotes gender[])
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  f public.com_fils%ROWTYPE;
BEGIN
  -- MODE ESSAI (PX-4) : quand le directeur a nomme des conversations d'essai, TOUT autre fil, existant ou non, est refuse avant meme
  -- d'etre lu (aucune fuite d'existence). Vide = pas de mode essai.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) > 0
     AND NOT coalesce(p_fil = ANY (private.praxis_essai()), false) THEN
    RETURN 'hors_essai';
  END IF;
  -- PX-2 : sans liste d'essai, Praxis ne lit un fil reel que si le directeur a ouvert les donnees reelles (apres la publication de la
  -- politique de confidentialite). Faux a l'installation.
  IF coalesce(pg_catalog.cardinality(private.praxis_essai()), 0) = 0
     AND NOT coalesce((SELECT r.donnees_reelles FROM private.praxis_reglages r), false) THEN
    RETURN 'donnees_reelles_fermees';
  END IF;
  SELECT x.* INTO f FROM public.com_fils x WHERE x.id = p_fil;
  IF NOT FOUND THEN RETURN 'fil_inconnu'; END IF;
  IF f.partie_b_nature IS DISTINCT FROM 'equipe' THEN RETURN 'hors_academie'; END IF;
  IF NOT (f.type_objet = ANY (private.praxis_types_fil()))
     OR (f.type_objet = 'dossier' AND f.partie_a_nature IS DISTINCT FROM 'foyer') THEN
    RETURN 'type_ferme';
  END IF;
  -- PRAXIS-CANDIDATS (17/11/2026) : un fil de candidature n'est ouvert que s'il porte sur une candidature d'enseignant VIVANTE (en cours,
  -- hors pause, avant la confirmation) dont la partie A est bien le candidat. Meme regle que private.com_paires, sans auth.uid().
  -- Sinon : type_ferme (aucune fuite d'existence).
  IF f.type_objet = 'candidature' AND NOT EXISTS (
       SELECT 1 FROM public.candidatures cd
        WHERE cd.id = f.objet_id AND cd.type_code = 'enseignant' AND cd.profile_id IS NOT NULL
          AND f.partie_a_nature = 'profil' AND f.partie_a_id = cd.profile_id
          AND cd.issue = 'en_cours' AND NOT cd.en_pause AND cd.etape <> 'confirmee') THEN
    RETURN 'type_ferme';
  END IF;
  IF f.partie_a_nature = 'profil' AND private.com_est_mineur(f.partie_a_id) THEN RETURN 'mineur'; END IF;
  IF f.partie_a_nature = 'foyer' AND EXISTS (
       SELECT 1 FROM public.profiles g
        WHERE g.household_id = f.partie_a_id AND g.role = 'guardian'::public.app_role AND g.deleted_at IS NULL
          AND private.com_est_mineur(g.id)) THEN
    RETURN 'mineur';
  END IF;
  IF EXISTS (SELECT 1 FROM public.com_messages m WHERE m.fil_id = f.id AND private.com_est_mineur(m.auteur_id)) THEN
    RETURN 'mineur';
  END IF;
  IF NOT private.praxis_fil_dans_cotes(f.id, p_cotes) THEN RETURN 'cote'; END IF;
  -- Le cote d'une candidature est le genre de la CANDIDATURE (SECRETAIRE-IA §11), en plus du genre du profil du candidat.
  IF f.type_objet = 'candidature' AND NOT coalesce((SELECT cd.genre = ANY (p_cotes) FROM public.candidatures cd WHERE cd.id = f.objet_id), false) THEN
    RETURN 'cote';
  END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.praxis_ecrire(p_cle text, p_fil uuid, p_texte text, p_cle_idempotence uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_debut timestamptz := pg_catalog.clock_timestamp();
  v_p record;
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_refus text;
  v_f public.com_fils%ROWTYPE;
  v_praxis uuid := private.praxis_profil();
  v_existant record;
  v_derniere_praxis timestamptz;
  v_derniere_autre timestamptz;
  v_plafond integer;
  v_r jsonb;
BEGIN
  SELECT * INTO v_p FROM private.praxis_porte(p_cle);
  IF v_p.cause IS NOT NULL THEN
    IF v_p.cle_id IS NOT NULL THEN
      PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_p.cause_interne, p_fil, NULL, NULL, v_debut);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', v_p.cause);
  END IF;
  IF p_fil IS NULL OR p_cle_idempotence IS NULL OR v_texte = '' THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'parametre', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'parametre');
  END IF;
  IF pg_catalog.length(v_texte) > 1500 THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'longueur', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'longueur');
  END IF;
  -- Le verrou du fil (comme la porte humaine), puis le verrou des envois de Praxis (les plafonds se lisent au journal).
  SELECT f.* INTO v_f FROM public.com_fils f WHERE f.id = p_fil FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'fil_inconnu', p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', 'fil_inconnu');
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('praxis-envois', 0));
  -- Rejeu : le meme message, rien d'ecrit.
  SELECT m.id, m.envoye_le INTO v_existant FROM public.com_messages m
   WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis AND m.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'rejoue', p_fil, ARRAY[v_existant.id], NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_existant.id, 'envoye_le', v_existant.envoye_le, 'rejoue', true);
  END IF;
  v_refus := private.praxis_fil_refus(p_fil, v_p.cotes);
  -- PRAXIS-CANDIDATS : private.com_paires lit auth.uid() (la session humaine) et ne peut pas servir pour un fil de candidature ; la regle
  -- equivalente est dans private.praxis_fil_refus (candidature vivante, partie A = le candidat, cote). Les autres types gardent le test.
  IF v_refus IS NULL AND v_f.type_objet <> 'candidature' AND NOT EXISTS (
       SELECT 1 FROM private.com_paires(v_f.type_objet, v_f.objet_id) q
        WHERE q.a_nature = v_f.partie_a_nature AND q.a_id = v_f.partie_a_id
          AND q.b_nature = v_f.partie_b_nature AND q.b_id IS NOT DISTINCT FROM v_f.partie_b_id) THEN
    v_refus := 'fil_ferme';
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_praxis FROM public.com_messages m
     WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis;
    IF v_derniere_praxis IS NOT NULL AND EXISTS (
         SELECT 1 FROM public.com_messages m
          WHERE m.fil_id = p_fil AND private.praxis_est_equipe(m.auteur_id, p_fil)
            AND m.envoye_le > v_derniere_praxis) THEN
      v_refus := 'repris_par_equipe';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    SELECT pg_catalog.max(m.envoye_le) INTO v_derniere_autre FROM public.com_messages m
     WHERE m.fil_id = p_fil AND private.praxis_est_partie_a(m.auteur_id, p_fil);
    IF (SELECT pg_catalog.count(*) FROM public.com_messages m
         WHERE m.fil_id = p_fil AND m.auteur_id = v_praxis
           AND m.envoye_le > coalesce(v_derniere_autre, '-infinity'::timestamptz)) >= 3 THEN
      v_refus := 'plafond_fil';
    END IF;
  END IF;
  IF v_refus IS NULL THEN
    SELECT r.envois_par_heure INTO v_plafond FROM private.praxis_reglages r;
    IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
         WHERE j.outil = 'ecrire' AND j.issue = 'ok'
           AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') >= v_plafond THEN
      v_refus := 'plafond';
    END IF;
  END IF;
  IF v_refus IS NOT NULL THEN
    PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', v_refus, p_fil, NULL, NULL, v_debut);
    RETURN pg_catalog.jsonb_build_object('erreur', v_refus);
  END IF;
  -- Tous les controles sont faits : l'interne n'a plus a rejouer le test humain (p_controle_humain = faux).
  v_r := private.com_envoyer_message_interne(v_praxis, 'accountant', NULL, p_fil, v_texte, p_cle_idempotence, false);
  PERFORM private.praxis_noter(v_p.cle_id, v_p.emise_par, 'ecrire', 'ok', p_fil, ARRAY[(v_r ->> 'id')::uuid], v_texte,
                               v_debut);
  RETURN pg_catalog.jsonb_build_object('ok', true, 'id', v_r -> 'id', 'envoye_le', v_r -> 'envoye_le');
END;
$function$;

DO $post$
BEGIN
  IF NOT ('candidature' = ANY (private.praxis_types_fil())) THEN RAISE EXCEPTION 'PRAXIS-CANDIDATS : types_fil sans candidature'; END IF;
  IF (SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'private.praxis_fil_refus(uuid,gender[])'::regprocedure) NOT LIKE '%PRAXIS-CANDIDATS%'
     OR (SELECT p.prosrc FROM pg_proc p WHERE p.oid = 'public.praxis_ecrire(text,uuid,text,uuid)'::regprocedure) NOT LIKE '%PRAXIS-CANDIDATS%' THEN
    RAISE EXCEPTION 'PRAXIS-CANDIDATS : retouche absente';
  END IF;
  IF NOT (SELECT p.prosecdef FROM pg_proc p WHERE p.oid = 'public.praxis_ecrire(text,uuid,text,uuid)'::regprocedure) THEN
    RAISE EXCEPTION 'PRAXIS-CANDIDATS : praxis_ecrire a perdu SECURITY DEFINER';
  END IF;
END
$post$;
