-- GESTES-DU-SERVEUR (pilote, 16/11/2026, CARTE-GESTES-DIRECTION.md §3 T5, T10, T14 et §4) : l'ecran recalcule lui-meme
-- les gestes permis d'une candidature avec sa propre copie des regles (gestes_proposes.dart) ; chaque regle neuve du
-- serveur doit y etre recopiee a la main, et chaque oubli donne un geste manquant ou propose a tort (T5 « Clore le
-- complement », T10 la dispense). Le serveur calcule deja ces gestes pour la liste des enseignants (private.lp_gestes).
-- Ce lot les rend pour CHAQUE ligne de candidature : une cle `gestes` de plus dans private.cand_ligne_json (donc la
-- liste, les voisins et le dossier), calculee par le moteur.
--
-- Source : private.candidature_gestes_regles par private.candidature_regle (etape, etat, issue, pause, condition), comme
-- private.lp_gestes ; ET le droit unique du cahier BE-2a (private.mission_droit) : la direction garde son cote (ou
-- l'exception super-admin, ou les types sans genre), un porteur de mission ne recoit que les gestes COCHES de sa mission,
-- dans son perimetre (cote, langues, etapes, dossiers) ; quiconque n'est ni l'un ni l'autre ne recoit rien. Un geste
-- liste est donc un geste que la porte publique ne refusera ni par la regle ni par le droit. Il peut encore etre refuse
-- par un controle (versement compatible, accords signes...) : ces controles restent dits par le refus du serveur, jamais
-- devines (K-56).
--
-- Une entree PROPRE : `clore_complement` (le geste de cloture du complement n'est pas une regle a lui : c'est la
-- variante 2 de demander_complement, en Salle de verification ; il n'a de sens que si un complement est en cours, la
-- meme condition que le refus `aucun_complement`). Elle est rendue quand cette variante est permise, que le droit de
-- demander un complement est acquis et qu'un complement court.
--
-- Les noms rendus sont ceux du moteur (snake_case), comme private.lp_gestes. Certains n'ont pas encore de fonction
-- publique ni d'ecran (restreindre, lever_restriction, noter/lever_indisponibilite, annuler_admission,
-- rouvrir_admission, accepter_admission, preciser_admission, piece_a_corriger, dispenser_entretien ici sans ecran) : ils
-- sont listes parce que la regle et le droit les permettent ; l'ecran ne montre que ceux qu'il sait faire.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : une aide neuve et une cle de plus, retouchee
-- par ancrage (une ancre trouvee une seule fois, sinon la migration echoue). Sans BEGIN/COMMIT de premier niveau.
-- L'aide ne porte pas le prefixe cand_ (neuf aides cand_ exactement sont attendues par les scenarios de CAND-L1).
-- Doit suivre 20261129420000 (private.mission_droit) et 20261129450000 (complementEnCours dans cand_ligne_json) : numero 20261129630000 et non 20261129430000, que le pilote avait reserve, parce que la retouche ancre sur la cle de 20261129450000 et que la CI rejoue les fichiers dans l ordre de leur nom.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'GESTES-DU-SERVEUR : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- 1. L'aide : les gestes de la direction que la regle ET le droit permettent, pour la session, sur cette ligne.
CREATE FUNCTION private.gestes_de_la_ligne(c public.candidatures)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(x.geste ORDER BY x.geste), '[]'::jsonb)
    FROM (
      SELECT g.geste
        FROM (SELECT DISTINCT r.geste
                FROM private.candidature_gestes_regles r
               WHERE 'direction' = ANY (r.auteurs)) g
       WHERE (private.candidature_regle(c, g.geste, 'direction', NULL, false)).geste IS NOT NULL
         AND private.mission_droit(c.id, g.geste)
      UNION ALL
      SELECT 'clore_complement'
       WHERE (private.candidature_regle(c, 'demander_complement', 'direction', 2::smallint, false)).geste IS NOT NULL
         AND pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
         AND private.mission_droit(c.id, 'demander_complement')
    ) x;
$function$;
ALTER FUNCTION private.gestes_de_la_ligne(public.candidatures) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.gestes_de_la_ligne(public.candidatures)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- 2. La cle `gestes` dans la ligne, par ancrage.
DO $retouche$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''gestes''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '''complementEnCours'', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0);',
      '''complementEnCours'', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0,
    ''gestes'', private.gestes_de_la_ligne(c));',
      'ligne.gestes');
    EXECUTE v_def;
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure),
                       '''gestes''') = 0 THEN
    RAISE EXCEPTION 'GESTES-DU-SERVEUR : retouche absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'private.gestes_de_la_ligne(public.candidatures)', 'EXECUTE') THEN
    RAISE EXCEPTION 'GESTES-DU-SERVEUR : droits d''execution trop larges sur l''aide';
  END IF;
END
$postflight$;
