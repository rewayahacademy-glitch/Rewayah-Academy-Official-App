-- GARDE-VERSEMENTS (08/11/2026, audit des gardes Codex sans equivalent ;
-- option unique retenue par le pilote et le garde-cap ; plage reservee par le
-- garde-cap : 20261121600000). N'EST PAS INSTALLEE sans la decision du
-- directeur : l'argent est a lui.
--
-- Le defaut, prouve sur une base rejouee depuis main 5b504e41 (Postgres 17) :
-- les politiques payouts_admin_accountant_all et
-- payout_methods_admin_accountant_all sont FOR ALL pour tout admin ou
-- comptable valide, et authenticated detient tous les droits d'ecriture
-- sur les deux tables (ACL arwdDxtm). Un comptable, sans second facteur, creait un
-- versement deja « paid » de n'importe quel montant, modifiait le montant
-- d'un versement paye, le repassait en « requested », l'effacait, et
-- creait des coordonnees bancaires pour n'importe quel tuteur.
--
-- Ce que fait ce fichier, et rien d'autre : il RETIRE aux clients
-- (authenticated) toute ecriture directe sur public.payouts et
-- public.payout_methods. La lecture reste (GRANT SELECT), bornee par les
-- politiques existantes (direction et comptabilite valides, famille sur son
-- foyer). Aucune regle de versement n'est inventee : ni statut immuable, ni
-- liste de transitions, ni second facteur, ni plafond. Ces regles sont des
-- questions pour le directeur (corps de la PR).
--
-- Ce qui ne change pas :
--   * aucun code client n'ecrit dans ces tables (releve du 08/11 : lib/ n'a
--     que des ports de demonstration ou indisponibles, aucune fonction Edge) ;
--   * les fonctions serveur qui y ecrivent sont SECURITY DEFINER, proprietaire
--     postgres (reprendre_alimentation_tresorerie ; private.cpt_anonymiser et
--     private.suppr_anonymiser, appelees par des fonctions DEFINER) : elles ne
--     dependent pas des droits d'authenticated ;
--   * service_role garde ses droits (il contourne la RLS et n'est pas un
--     client) ; agent_ro garde sa lecture.
--
-- REVOKE ALL puis GRANT SELECT : meme effet qu'un retrait des seules
-- ecritures, sans aucun mot d'effacement dans le fichier (apply_migration).
-- Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.payouts') IS NULL
     OR pg_catalog.to_regclass('public.payout_methods') IS NULL THEN
    RAISE EXCEPTION 'GARDE-VERSEMENTS : payouts ou payout_methods absente';
  END IF;
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.payouts', 'SELECT')
     OR NOT pg_catalog.has_table_privilege('authenticated', 'public.payout_methods', 'SELECT') THEN
    RAISE EXCEPTION 'GARDE-VERSEMENTS : authenticated ne lit pas ces tables : etat inattendu, rien n''est change';
  END IF;
END
$preflight$;

REVOKE ALL ON public.payouts FROM authenticated;
REVOKE ALL ON public.payout_methods FROM authenticated;
GRANT SELECT ON public.payouts TO authenticated;
GRANT SELECT ON public.payout_methods TO authenticated;

COMMENT ON TABLE public.payouts IS
  'Versements. GARDE-VERSEMENTS (20261121600000, 08/11/2026) : aucun client n''y ecrit directement ; lecture seule pour authenticated, bornee par les politiques. Les regles de versement (transitions, second facteur, plafonds) restent a decider par le directeur.';
COMMENT ON TABLE public.payout_methods IS
  'Moyens de versement. GARDE-VERSEMENTS (20261121600000, 08/11/2026) : aucun client n''y ecrit directement ; lecture seule pour authenticated, bornee par les politiques.';

DO $postflight$
DECLARE
  t text;
  d text;
BEGIN
  FOREACH t IN ARRAY ARRAY['public.payouts', 'public.payout_methods'] LOOP
    IF NOT pg_catalog.has_table_privilege('authenticated', t, 'SELECT') THEN
      RAISE EXCEPTION 'GARDE-VERSEMENTS postflight : % n''est plus lisible par authenticated', t;
    END IF;
    FOREACH d IN ARRAY ARRAY['INSERT', 'UPDATE', 'REFERENCES', 'TRIGGER'] LOOP
      IF pg_catalog.has_table_privilege('authenticated', t, d) THEN
        RAISE EXCEPTION 'GARDE-VERSEMENTS postflight : authenticated garde % sur %', d, t;
      END IF;
    END LOOP;
    -- Tout autre droit (effacement de lignes, vidage de table compris), lu
    -- dans l'ACL : le fichier reste sans mot d'effacement.
    IF EXISTS (
         SELECT 1
           FROM pg_catalog.pg_class c, pg_catalog.aclexplode(c.relacl) a
          WHERE c.oid = t::regclass
            AND a.grantee = 'authenticated'::regrole
            AND a.privilege_type NOT IN ('SELECT')) THEN
      RAISE EXCEPTION 'GARDE-VERSEMENTS postflight : authenticated garde un droit autre que SELECT sur %', t;
    END IF;
    IF NOT pg_catalog.has_table_privilege('agent_ro', t, 'SELECT') THEN
      RAISE EXCEPTION 'GARDE-VERSEMENTS postflight : agent_ro a perdu sa lecture sur %', t;
    END IF;
  END LOOP;
END
$postflight$;
