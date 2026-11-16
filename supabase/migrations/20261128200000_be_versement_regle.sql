-- BE-VERSEMENT (directeur, 16/11/2026) : un moyen de versement qui suit la regle se
-- valide seul. Ce fichier change la regle ; le recalcul des dossiers deja en cours est
-- dans 20261128200100_be_versement_recalcul.sql.
--
-- Ce fichier ne contient aucun mot d'effacement, ni BEGIN ni COMMIT seul sur une ligne :
-- l'enveloppe de la page ouvre la transaction.
--
-- La regle (private.paiement_etat, retouchee par ancre) :
-- * un moyen declare qui croise une ligne `confirme` du referentiel rend `compatible`, sans
--   geste, SAUF si la derniere decision de la direction sur ce moyen l'infirme (geste 25,
--   motif obligatoire) ;
-- * aucun moyen ne croise une ligne `confirme` (ligne `en_verification` ou `indisponible`) :
--   `incompatible`, comme avant ; la direction decide alors UNE fois par pays, en
--   confirmant ou en rendant indisponible la ligne, et le declencheur existant
--   (referentiel_paiement_effets) recalcule tous les candidats du pays ;
-- * tous les moyens croises sont infirmes : `incompatible`, comme avant.
-- `a_verifier` n'est donc plus rendu par le calcul. Le geste 24 (confirmer le moyen) reste au
-- serveur pour les donnees passees ; il n'est plus propose, parce que sa proposition
-- (lib/features/admin_candidature/gestes_proposes.dart) exige paiement = a_verifier.
--
-- Une seule ligne change : `ELSIF v_confirmes > 0 THEN` devient
-- `ELSIF v_infirmes < v_croises THEN` (au moins un moyen croise non infirme). Le reste du
-- calcul, les controles de la salle 2 et de la salle 3 (private.paiement_compatible) et la
-- table des decisions ne changent pas.
--
-- Lecteurs de private.paiement_etat (B1) : private.paiement_compatible, private.paiement_recalculer,
-- candidature_controles_salle3 et candidature_controles_dossier (lecture en direct) ; aucun ne
-- teste la valeur `a_verifier` du calcul. La valeur `a_verifier` de la colonne
-- candidatures.paiement reste admise (donnees passees) ; la liste de la direction la filtre
-- toujours.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'BE-VERSEMENT : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

DO $retouche$
DECLARE
  f regprocedure := 'private.paiement_etat(uuid)'::regprocedure;
  v_def text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef(f);
  IF pg_catalog.strpos(v_def, 'ELSIF v_infirmes < v_croises THEN') > 0 THEN
    RAISE NOTICE 'BE-VERSEMENT : regle deja posee, rien a faire';
    RETURN;
  END IF;
  v_def := pg_temp.remplacer(v_def, 'ELSIF v_confirmes > 0 THEN',
                             'ELSIF v_infirmes < v_croises THEN', 'paiement_etat.confirmes');
  EXECUTE v_def;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.paiement_etat(uuid)'::regprocedure),
                       'ELSIF v_infirmes < v_croises THEN') = 0 THEN
    RAISE EXCEPTION 'BE-VERSEMENT : retouche absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'private.paiement_etat(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.paiement_etat(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'BE-VERSEMENT : droits inattendus sur private.paiement_etat';
  END IF;
END;
$postflight$;
