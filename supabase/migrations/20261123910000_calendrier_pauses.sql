-- CALENDRIER-ET-PAUSES (lot 2 de la charte, 12/11/2026). Migration 20261123910000.
-- Plan : docs/current/pedagogie/PLAN-DE-CONSTRUCTION.md, « Lot 2 » ;
-- valeurs : REGLAGES.md partie 2 ; fiche : docs/current/pedagogie/lots/LOT-2-CALENDRIER-ET-PAUSES.md.
--
-- Ce que fait ce fichier (additif ; AUCUN mot d'effacement) :
--   1. calendrier_ecole : fermetures, rencontres de recitation, dates d'evaluation,
--      autres dates ; saisies par la direction, jamais calculees ;
--   2. pauses_eleve : pause d'un mois (mois civil entier) et pause d'exception ;
--   3. private.recul_jours_calcule : LE SEUL endroit ou le recul de la date limite
--      est calcule (fermetures + pauses, sans double compte) ; il alimente
--      eleve_etape_en_cours.recul_jours, point d'accroche du lot 1, lu par
--      private.dates_etape (inchangee) ;
--   4. les gestes serveur de la direction, du tuteur et de l'eleve adulte ;
--   5. la generation des seances ne cree plus de seance un jour de fermeture
--      publiee (aucune seance existante n'est touchee) ;
--   6. les lectures propres « en pause » et « jour ferme » pour le moteur (lot 7).
--
-- Ce que ce fichier ne fait PAS : aucun argent (facturation, remboursement, prix,
-- mois non facture : reserve du directeur, A-HARMONISER-REGLES-ARGENT-ET-ARRET.md) ;
-- aucune annonce (lot 7). La notification de la reponse de la direction a une
-- demande de pause exige l'evenement « pause_repondue » : il entre dans la
-- contrainte des notifications par le fichier SEPARE 20261123911000 (il contient
-- le seul mot d'effacement du lot, que le directeur colle dans l'editeur SQL).
-- Sans lui, la decision est enregistree et la notification est simplement omise
-- (journal d'avertissement).
--
-- Depend du lot 1 (20261123900000) : eleve_etape_en_cours, private.dates_etape,
-- private.cohorte_effective, etape_eleve_lecture.
--
-- COLLAGE : ce fichier se colle EN UNE SEULE REQUETE dans l'editeur SQL. Il ne
-- contient ni BEGIN ni COMMIT : une requete de plusieurs instructions est une seule
-- transaction (implicite) pour Postgres, donc tout passe ou rien ne passe (prouve le
-- 13/11 : un echec en derniere ligne ne laisse aucun objet). Ne PAS le decouper en
-- plusieurs morceaux ni le rejouer ligne a ligne dans un client qui valide chaque
-- instruction. 20261123911000 se colle ensuite, lui aussi en une requete.
--
-- Regles de jour et de temps (revue du 13/11, arbitrees) :
--   - UN seul jour partout : le jour de l'academie, heure de La Mecque (Asia/Riyadh),
--     pour savoir si une seance tombe un jour de fermeture ;
--   - une fermeture ne touche QUE les seances non commencees a l'instant de sa
--     publication (debut posterieur a publie_le) : une seance en cours ou deja
--     commencee continue normalement ;
--   - le retrait (ou le raccourcissement) d'une fermeture est REFUSE tant qu'une
--     seance mise de cote ne peut pas etre retablie ; la direction lit les conflits et
--     libere l'enseignant ou confirme d'abandonner ces seances (geste trace).
-- ---------------------------------------------------------------------------
-- 0. Preflight : le lot 1 est installe
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.eleve_etape_en_cours') IS NULL
     OR pg_catalog.to_regprocedure('private.dates_etape(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.cohorte_effective(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.etape_eleve_lecture(uuid)') IS NULL THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : installer d''abord 20261123900000_socle_programme.sql (lot 1)';
  END IF;
  IF pg_catalog.to_regclass('public.calendrier_ecole') IS NOT NULL
     OR pg_catalog.to_regclass('public.pauses_eleve') IS NOT NULL THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : deja installe';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les reglages (REGLAGES.md, partie 2) : app_config, jamais des constantes
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  -- Pause : demandee au moins 7 jours avant le debut du mois (DECIDE 30/09).
  ('pause.preavis_jours', pg_catalog.to_jsonb(7)),
  -- Au plus 2 mois de pause sur 12 mois glissants sans accord particulier (ARBITRE).
  ('pause.max_mois_fenetre', pg_catalog.to_jsonb(2)),
  ('pause.fenetre_mois', pg_catalog.to_jsonb(12)),
  -- La direction repond sous 3 jours (ARBITRE).
  ('pause.delai_reponse_jours', pg_catalog.to_jsonb(3)),
  -- Fermeture du Ramadan : 20 jours au plus (DECIDE 30/09).
  ('calendrier.ramadan_jours_max', pg_catalog.to_jsonb(20)),
  -- Fermeture de l'Aid al-Adha : du 9 au 18 Dhu al-Hijja inclus = 10 jours (DECIDE 30/09).
  ('calendrier.aid_adha_jours_max', pg_catalog.to_jsonb(10)),
  -- Une pause d'exception dure 3 mois au plus ; au-dela, la direction accorde un nouveau geste
  -- (revue independante du 13/11 : jamais une pause sans fin).
  ('pause.exception_mois_max', pg_catalog.to_jsonb(3)),
  -- UN SEUL reglage cache la demande de pause de la famille : faux par defaut. Tant que le
  -- directeur n'a pas decide la regle d'argent (A-HARMONISER-REGLES-ARGENT-ET-ARRET.md), le
  -- tuteur et l'adulte ne voient ni le lien, ni la regle, ni les mois ; pause_demander refuse.
  -- Les pauses deja accordees, la pause d'exception et l'ecran de la direction ne changent pas.
  ('pause.demande_famille_ouverte', pg_catalog.to_jsonb(false))
ON CONFLICT (key) DO NOTHING;

-- Les bornes de ces reglages (la direction les change dans app_config).
CREATE FUNCTION private.calendrier_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  IF NEW.key NOT IN ('pause.preavis_jours', 'pause.max_mois_fenetre', 'pause.fenetre_mois',
                     'pause.delai_reponse_jours', 'calendrier.ramadan_jours_max',
                     'calendrier.aid_adha_jours_max', 'pause.exception_mois_max',
                     'pause.demande_famille_ouverte') THEN
    RETURN NEW;
  END IF;
  IF NEW.key = 'pause.demande_famille_ouverte' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'boolean' THEN
      RAISE EXCEPTION 'reglage % : vrai ou faux est attendu', NEW.key USING errcode = '22023';
    END IF;
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
     OR (NEW.value #>> '{}') !~ '^[0-9]{1,3}$' THEN
    RAISE EXCEPTION 'reglage % : un nombre entier est attendu', NEW.key USING errcode = '22023';
  END IF;
  v_n := (NEW.value #>> '{}')::integer;
  IF NOT (CASE NEW.key
            WHEN 'pause.preavis_jours' THEN v_n BETWEEN 0 AND 60
            WHEN 'pause.max_mois_fenetre' THEN v_n BETWEEN 0 AND 12
            WHEN 'pause.fenetre_mois' THEN v_n BETWEEN 1 AND 24
            WHEN 'pause.delai_reponse_jours' THEN v_n BETWEEN 1 AND 30
            WHEN 'calendrier.ramadan_jours_max' THEN v_n BETWEEN 1 AND 40
            WHEN 'calendrier.aid_adha_jours_max' THEN v_n BETWEEN 1 AND 20
            WHEN 'pause.exception_mois_max' THEN v_n BETWEEN 1 AND 12
          END) THEN
    RAISE EXCEPTION 'reglage % : valeur hors bornes', NEW.key USING errcode = '22023';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_calendrier_pauses
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_reglages_valider();

-- ---------------------------------------------------------------------------
-- 2. Le calendrier de l'academie
-- ---------------------------------------------------------------------------
CREATE TABLE public.calendrier_ecole (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('fermeture', 'rencontre', 'evaluation', 'autre')),
  -- Une fermeture porte sa categorie : le Ramadan et l'Aid ont chacun leur maximum.
  categorie text CHECK (categorie IN ('ramadan', 'aid_al_adha', 'autre')),
  titre text NOT NULL CHECK (pg_catalog.btrim(titre) <> '' AND pg_catalog.length(titre) <= 120),
  du date NOT NULL,
  au date NOT NULL,
  portee text NOT NULL DEFAULT 'ecole' CHECK (portee IN ('ecole', 'tranche', 'classe')),
  cohorte text REFERENCES public.cohortes_age(code),
  groupe_id uuid REFERENCES public.groupes(id),
  publie boolean NOT NULL DEFAULT false,
  publie_le timestamptz,
  cree_par uuid,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  maj_par uuid,
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT calendrier_ecole_dates CHECK (au >= du AND au - du <= 365),
  CONSTRAINT calendrier_ecole_portee_coherente CHECK (
       (portee = 'ecole' AND cohorte IS NULL AND groupe_id IS NULL)
    OR (portee = 'tranche' AND cohorte IS NOT NULL AND groupe_id IS NULL)
    OR (portee = 'classe' AND groupe_id IS NOT NULL AND cohorte IS NULL)),
  CONSTRAINT calendrier_ecole_categorie_coherente CHECK (
       (type = 'fermeture' AND categorie IS NOT NULL)
    OR (type <> 'fermeture' AND categorie IS NULL))
);

COMMENT ON TABLE public.calendrier_ecole IS
  'CALENDRIER-ET-PAUSES (12/11/2026) : l''annee de l''academie, saisie par la direction, jamais calculee '
  '(l''application ne calcule pas le calendrier lunaire). Type : fermeture, rencontre de recitation, '
  'date d''evaluation, autre. Portee : toute l''academie, une tranche d''age, une classe. Seules les '
  'lignes publiees agissent et se lisent. Aucune ecriture directe (fonctions calendrier_ecole_*).';

CREATE INDEX calendrier_ecole_publie_idx ON public.calendrier_ecole (au) WHERE publie;

ALTER TABLE public.calendrier_ecole ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.calendrier_ecole FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.calendrier_ecole TO authenticated;
CREATE POLICY calendrier_ecole_direction ON public.calendrier_ecole
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- Une fermeture du Ramadan ou de l'Aid ne depasse pas son maximum (reglage).
CREATE FUNCTION private.calendrier_ecole_valider()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_max integer;
  v_jour date := private.jour_academie();
BEGIN
  NEW.maj_le := pg_catalog.now();
  -- Revue du 13/11 (I1) : comme pause_annuler, une fermeture publiee deja commencee ou
  -- passee ne se retire pas, ne se raccourcit pas, ne se deplace pas ; une fermeture en
  -- cours peut seulement se prolonger (et son titre se corriger).
  IF TG_OP = 'UPDATE' AND OLD.publie AND OLD.type = 'fermeture' AND OLD.du <= v_jour THEN
    IF NEW.publie IS NOT TRUE OR NEW.type <> OLD.type OR NEW.categorie IS DISTINCT FROM OLD.categorie
       OR NEW.portee <> OLD.portee OR NEW.cohorte IS DISTINCT FROM OLD.cohorte
       OR NEW.groupe_id IS DISTINCT FROM OLD.groupe_id OR NEW.du <> OLD.du OR NEW.au < OLD.au
       OR (OLD.au < v_jour AND NEW.au <> OLD.au) THEN
      RAISE EXCEPTION 'calendrier_fermeture_commencee' USING errcode = '22023';
    END IF;
  END IF;
  IF NEW.type = 'fermeture' AND NEW.categorie IN ('ramadan', 'aid_al_adha') THEN
    v_max := public.app_config_int(
      CASE NEW.categorie WHEN 'ramadan' THEN 'calendrier.ramadan_jours_max'
                         ELSE 'calendrier.aid_adha_jours_max' END,
      CASE NEW.categorie WHEN 'ramadan' THEN 20 ELSE 10 END);
    IF (NEW.au - NEW.du + 1) > v_max THEN
      RAISE EXCEPTION 'calendrier_fermeture_trop_longue' USING errcode = '22023',
        detail = pg_catalog.format('%s jours au plus', v_max);
    END IF;
  END IF;
  -- La date de publication est celle de CHAQUE mise en ligne (pas seulement la premiere) :
  -- une fermeture retiree puis republiee ne touche que les seances posterieures a la
  -- republication.
  IF NEW.publie AND (TG_OP = 'INSERT' OR NOT OLD.publie OR NEW.publie_le IS NULL) THEN
    NEW.publie_le := pg_catalog.clock_timestamp();   -- l'instant reel, pas celui du debut de la transaction
  ELSIF TG_OP = 'UPDATE' AND NEW.publie THEN
    NEW.publie_le := OLD.publie_le;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER calendrier_ecole_valider
  BEFORE INSERT OR UPDATE ON public.calendrier_ecole
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_ecole_valider();

-- ---------------------------------------------------------------------------
-- 3. Les pauses d'un eleve
-- ---------------------------------------------------------------------------
-- Sans cle etrangere vers profiles, a dessein (comme eleve_etape_en_cours) : un
-- compte efface par le service d'authentification ne doit jamais etre bloque.
CREATE TABLE public.pauses_eleve (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  type text NOT NULL CHECK (type IN ('mois', 'exception')),
  debut date NOT NULL,
  fin date NOT NULL,
  statut text NOT NULL CHECK (statut IN ('demandee', 'acceptee', 'refusee', 'annulee')),
  -- Qui a accepte : le systeme (dans la regle) ou la direction (au-dela, ou exception).
  acceptation text CHECK (acceptation IN ('automatique', 'direction')),
  -- Motif de l'exception (maladie soudaine, interruption accordee) ; nul pour un mois.
  motif text CHECK (motif IS NULL OR pg_catalog.length(pg_catalog.btrim(motif)) BETWEEN 3 AND 500),
  motif_decision text CHECK (motif_decision IS NULL OR pg_catalog.length(pg_catalog.btrim(motif_decision)) BETWEEN 3 AND 500),
  demandee_par uuid,
  demandee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  repondre_avant date,
  decidee_par uuid,
  decidee_par_nom text,
  decidee_le timestamptz,
  -- « Terminer la pause d'exception a telle date » : la fin d'origine et la trace du geste.
  fin_initiale date,
  terminee_par uuid,
  terminee_par_nom text,
  terminee_le timestamptz,
  CONSTRAINT pauses_eleve_terminee_tracee CHECK (
    (terminee_le IS NULL) = (terminee_par IS NULL)
    AND (terminee_le IS NULL) = (fin_initiale IS NULL)),
  CONSTRAINT pauses_eleve_dates CHECK (fin >= debut AND fin - debut <= 365),
  CONSTRAINT pauses_eleve_mois_entier CHECK (
    type <> 'mois'
    OR (debut = pg_catalog.date_trunc('month', (debut)::timestamp)::date
        AND fin = (pg_catalog.date_trunc('month', (debut)::timestamp) + interval '1 month - 1 day')::date)),
  CONSTRAINT pauses_eleve_exception_motivee CHECK (
    type <> 'exception'
    OR (motif IS NOT NULL AND statut IN ('acceptee', 'annulee')
        AND decidee_par IS NOT NULL AND decidee_par_nom IS NOT NULL AND acceptation = 'direction')),
  CONSTRAINT pauses_eleve_acceptation_coherente CHECK (
    (statut = 'acceptee') = (acceptation IS NOT NULL) OR statut IN ('annulee'))
);

COMMENT ON TABLE public.pauses_eleve IS
  'CALENDRIER-ET-PAUSES (12/11/2026) : pause d''un mois (mois civil entier, demandee au moins 7 jours '
  'avant, 2 mois sur 12 mois glissants sans accord particulier) et pause d''exception (maladie soudaine, '
  'interruption temporaire accordee : motif, date de fin, nom de la direction). Pedagogie seulement : la '
  'date limite de l''etape recule de la duree de la pause ; la place est gardee. Rien d''argent. '
  'pause_seances est la pause de 5 minutes pendant une seance : sans rapport. '
  'Aucune ecriture directe (fonctions pause_*).';

-- Un seul mois de pause (demandee ou acceptee) par eleve et par mois.
CREATE UNIQUE INDEX pauses_eleve_un_mois_uniq ON public.pauses_eleve (student_id, debut)
  WHERE type = 'mois' AND statut IN ('demandee', 'acceptee');
CREATE INDEX pauses_eleve_eleve_idx ON public.pauses_eleve (student_id, debut DESC);
CREATE INDEX pauses_eleve_a_traiter_idx ON public.pauses_eleve (demandee_le) WHERE statut = 'demandee';

ALTER TABLE public.pauses_eleve ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.pauses_eleve FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON public.pauses_eleve TO authenticated;
CREATE POLICY pauses_eleve_direction ON public.pauses_eleve
  FOR SELECT TO authenticated
  USING (coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false));

-- ---------------------------------------------------------------------------
-- 4. Les faits : jour ferme, en pause
-- ---------------------------------------------------------------------------
-- Le recul deja ecoule ne diminue jamais (revue du 13/11, B1) : les jours comptes
-- jusqu'a aujourd'hui sont gardes avec le fait, et seuls les jours a venir restent
-- revocables (retrait d'une fermeture ou d'une pause avant son debut).
ALTER TABLE public.eleve_etape_en_cours
  ADD COLUMN recul_acquis_jours integer NOT NULL DEFAULT 0 CHECK (recul_acquis_jours >= 0),
  ADD COLUMN recul_ajustement_jours integer NOT NULL DEFAULT 0,
  ADD COLUMN recul_plancher_jours integer NOT NULL DEFAULT 0 CHECK (recul_plancher_jours >= 0);
COMMENT ON COLUMN public.eleve_etape_en_cours.recul_ajustement_jours IS
  'CALENDRIER-ET-PAUSES (13/11/2026) : decalage pose a chaque changement de classe pour que ce changement '
  'ne modifie JAMAIS la date limite (charte) : recul = calcule + ajustement. Derive, jamais saisi.';
COMMENT ON COLUMN public.eleve_etape_en_cours.recul_plancher_jours IS
  'CALENDRIER-ET-PAUSES (13/11/2026) : LA REGLE « un jour accorde reste accorde » (charte : la date limite '
  'n''avance JAMAIS). A chaque changement de classe, le recul d''avant devient un plancher : le recul ne descend '
  'plus sous lui, meme si la fermeture qui l''avait accorde est retiree ensuite. Consequence assumee (arbitrage '
  'de l''architecte, 13/11) : au changement de classe l''eleve peut GARDER les jours d''une fermeture future de la '
  'classe quittee, et ceux de sa nouvelle classe s''y ajoutent ; c''est favorable a l''eleve et sans danger. '
  'Repart de zero a chaque nouvelle etape. Derive, jamais saisi.';
COMMENT ON COLUMN public.eleve_etape_en_cours.recul_acquis_jours IS
  'CALENDRIER-ET-PAUSES : jours de fermeture et de pause deja ecoules (jusqu''au jour de l''academie) '
  'comptes dans recul_jours ; garde-fou : le recul d''une etape ne descend jamais sous cette valeur '
  '(regle de stabilite : une date limite ne peut pas avancer). Derive par le declencheur, jamais saisi.';

-- Les seances deja creees que la fermeture met de cote (rien n'est supprime : la
-- seance garde sa ligne, `deleted_at` la retire des listes et de tous les circuits ;
-- le retrait de la fermeture avant son debut la retablit).
CREATE TABLE public.seances_fermees (
  session_id uuid PRIMARY KEY REFERENCES public.sessions(id),
  fermeture_id uuid NOT NULL REFERENCES public.calendrier_ecole(id),
  masquee_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  retablie_le timestamptz,
  -- Une seance abandonnee (geste explicite de la direction a la levee de la fermeture :
  -- l'enseignant avait pris un autre cours a cette heure) reste de cote pour toujours ;
  -- elle ne se confond ni avec une seance mise de cote (a retablir) ni avec une seance
  -- supprimee par la direction : sa ligne ici dit laquelle des trois elle est.
  abandonnee_le timestamptz,
  abandonnee_par uuid,
  CONSTRAINT seances_fermees_un_seul_sort CHECK (retablie_le IS NULL OR abandonnee_le IS NULL),
  CONSTRAINT seances_fermees_abandon_complet CHECK ((abandonnee_le IS NULL) = (abandonnee_par IS NULL))
);
COMMENT ON TABLE public.seances_fermees IS
  'CALENDRIER-ET-PAUSES (13/11/2026) : les seances deja creees qu''une fermeture publiee met de cote '
  '(sessions.deleted_at pose, jamais de suppression) ; retablie_le quand la fermeture est retiree avant '
  'son debut. Aucun droit client.';
ALTER TABLE public.seances_fermees ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.seances_fermees FROM PUBLIC, anon, authenticated, service_role;

-- LE jour de reference du calendrier et des pauses : le jour de l'academie, heure de
-- La Mecque (decision du directeur relayee le 13/11, coherent avec l'horloge). Plus de
-- date UTC ni de fuseau du foyer pour decider « passe », « en cours », « 7 jours avant »,
-- « mois civil ». Seul endroit ou ce fuseau est ecrit.
CREATE FUNCTION private.jour_academie()
RETURNS date
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date;
$function$;

-- Le jour de l'academie d'un instant : l'unique regle de jour des fermetures, pour une
-- seance comme pour le recul (Toronto samedi 19 h est dimanche a La Mecque).
CREATE FUNCTION private.jour_academie_de(p_instant timestamptz)
RETURNS date
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (p_instant AT TIME ZONE 'Asia/Riyadh')::date;
$function$;

-- La tranche d'age FIGEE de l'etape de l'eleve : une seule source pour « qui est vise »
-- par une fermeture de tranche, pour la classe comme pour le recul.
CREATE FUNCTION private.cohorte_figee(p_student_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    (SELECT f.cohorte FROM public.eleve_etape_en_cours f WHERE f.student_id = p_student_id),
    private.cohorte_effective(p_student_id, NULL));
$function$;

-- Une fermeture vise-t-elle cette classe ? Academie : oui. Classe : la sienne.
-- Tranche : seulement si TOUS les membres actifs de la classe sont de cette tranche
-- figee (sinon la classe garde son cours : les autres eleves n'ont pas de fermeture ;
-- l'eleve de la tranche garde pourtant le recul et n'est compte absent a aucune seance
-- ce jour-la : private.eleve_en_fermeture).
CREATE FUNCTION private.fermeture_vise_classe(p_portee text, p_cohorte text, p_groupe_id uuid, p_classe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE p_portee
    WHEN 'ecole' THEN true
    WHEN 'classe' THEN p_groupe_id IS NOT DISTINCT FROM p_classe_id
    WHEN 'tranche' THEN
      EXISTS (SELECT 1 FROM public.groupe_membres m
               WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL)
      AND NOT EXISTS (SELECT 1 FROM public.groupe_membres m
                      WHERE m.groupe_id = p_classe_id AND m.left_at IS NULL
                        AND private.cohorte_figee(m.student_id) IS DISTINCT FROM p_cohorte)
    ELSE false END;
$function$;

-- Le fait « jour ferme » pour une classe : une fermeture publiee couvre ce jour.
CREATE FUNCTION private.jour_ferme_pour_classe(p_jour date, p_classe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.type = 'fermeture'
       AND p_jour BETWEEN ce.du AND ce.au
       AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, p_classe_id));
$function$;

-- Un creneau (debut d'une seance) tombe-t-il sous une fermeture publiee ? Deux conditions :
-- son jour de l'academie est couvert, ET il commence APRES la publication de la fermeture
-- (revue du 13/11, B-C : une seance en cours ou deja commencee a la publication continue
-- normalement). [p_groupe_id] nul : les seances sans classe, que seule une fermeture de
-- toute l'academie vise.
CREATE FUNCTION private.debut_ferme(p_debut timestamptz, p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_debut IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.type = 'fermeture'
       AND private.jour_academie_de(p_debut) BETWEEN ce.du AND ce.au
       AND p_debut > ce.publie_le
       AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, p_groupe_id));
$function$;

-- La seance d'une classe tombe sous une fermeture (voir debut_ferme).
CREATE FUNCTION private.session_en_fermeture(p_debut timestamptz, p_groupe_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_groupe_id IS NOT NULL AND private.debut_ferme(p_debut, p_groupe_id);
$function$;

-- Une fermeture couvre l'eleve ce jour-la : academie ; sa tranche figee ; une classe dont
-- il etait membre CE jour-la (entre avant ou ce jour, pas sorti avant). Pour le moteur
-- (lot 7) : un eleve vise n'est compte absent a aucune seance ce jour-la, meme dans une
-- classe mixte dont le cours a lieu.
CREATE FUNCTION private.eleve_en_fermeture(p_student_id uuid, p_jour date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.type = 'fermeture' AND p_jour BETWEEN ce.du AND ce.au
       AND (ce.portee = 'ecole'
            OR (ce.portee = 'tranche' AND ce.cohorte = private.cohorte_figee(p_student_id))
            OR (ce.portee = 'classe' AND EXISTS (
                  SELECT 1 FROM public.groupe_membres m
                   WHERE m.groupe_id = ce.groupe_id AND m.student_id = p_student_id
                     AND (m.joined_at AT TIME ZONE 'Asia/Riyadh')::date <= p_jour
                     AND (m.left_at IS NULL OR p_jour < (m.left_at AT TIME ZONE 'Asia/Riyadh')::date)))));
$function$;

-- Le fait « en pause » a une date (pause acceptee seulement). Pour le moteur
-- (lot 7) : un eleve en pause n'est compte absent a aucune seance.
CREATE FUNCTION private.eleve_en_pause(p_student_id uuid, p_jour date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.pauses_eleve p
     WHERE p.student_id = p_student_id AND p.statut = 'acceptee'
       AND p_jour BETWEEN p.debut AND p.fin);
$function$;

-- Ni cours attendu ni absence possible ce jour-la : en pause, ou une fermeture le couvre.
CREATE FUNCTION private.eleve_hors_cours(p_student_id uuid, p_jour date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT private.eleve_en_pause(p_student_id, p_jour) OR private.eleve_en_fermeture(p_student_id, p_jour);
$function$;

-- Le fait « en pause tel mois » : le mois civil entier est couvert par des pauses
-- acceptees. Lecture seule ; aucune facturation n'y est branchee (reserve du
-- directeur, A-HARMONISER-REGLES-ARGENT-ET-ARRET.md).
CREATE FUNCTION private.eleve_en_pause_mois(p_student_id uuid, p_mois date)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT p_mois IS NOT NULL AND NOT EXISTS (
    SELECT 1
      FROM pg_catalog.generate_series(0, (pg_catalog.date_trunc('month', (p_mois)::timestamp) + interval '1 month - 1 day')::date
                                         - pg_catalog.date_trunc('month', (p_mois)::timestamp)::date) g
     WHERE NOT private.eleve_en_pause(p_student_id, (pg_catalog.date_trunc('month', (p_mois)::timestamp)::date + g)));
$function$;

-- ---------------------------------------------------------------------------
-- 5. Le recul de la date limite : un seul endroit
-- ---------------------------------------------------------------------------
-- Jours fermes (fermetures publiees qui visent l'eleve) et jours de pause (pauses
-- acceptees), REUNIS en un seul ensemble de jours : une fermeture qui tombe pendant une
-- pause ne compte qu'une fois. Ne comptent que les jours de l'etape en cours, de
-- l'entree dans l'etape a la date limite reculee (un point fixe : chaque jour ajoute
-- peut en faire entrer un autre). Une fermeture de classe compte un jour si l'eleve
-- en etait membre CE jour-la (revue du 13/11, B1), pas s'il en est membre aujourd'hui.
-- Rend aussi les jours deja ecoules (jusqu'au jour de l'academie) : le declencheur ne
-- laisse jamais le recul descendre sous eux. Sans durees (tranche inconnue) : zero.
CREATE FUNCTION private.recul_jours_calcule(p_student_id uuid, p_entree date, p_niveau_id uuid, p_cohorte text)
RETURNS TABLE (recul integer, acquis integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_coh text;
  v_semaines integer;
  v_aujourdhui date := private.jour_academie();
  v_r integer := 0;
  v_n integer;
  v_ecoules integer := 0;
BEGIN
  IF p_student_id IS NULL OR p_entree IS NULL OR p_niveau_id IS NULL THEN
    RETURN QUERY SELECT 0, 0;
    RETURN;
  END IF;
  v_coh := coalesce(p_cohorte, private.cohorte_effective(p_student_id, NULL));
  SELECT (n.durees -> v_coh ->> 'limite')::integer INTO v_semaines
    FROM public.programme_niveaux n WHERE n.id = p_niveau_id;
  IF v_coh IS NULL OR v_semaines IS NULL THEN
    RETURN QUERY SELECT 0, 0;
    RETURN;
  END IF;

  FOR i IN 1 .. 400 LOOP
    SELECT pg_catalog.count(*)::integer, (pg_catalog.count(*) FILTER (WHERE j.d <= v_aujourdhui))::integer
      INTO v_n, v_ecoules
      FROM (
        SELECT (ce.du + g.n) AS d
          FROM public.calendrier_ecole ce
         CROSS JOIN LATERAL pg_catalog.generate_series(0, ce.au - ce.du) AS g(n)
         WHERE ce.publie AND ce.type = 'fermeture'
           AND (ce.portee = 'ecole'
                OR (ce.portee = 'tranche' AND ce.cohorte = v_coh)
                OR (ce.portee = 'classe' AND EXISTS (
                      SELECT 1 FROM public.groupe_membres m
                       WHERE m.groupe_id = ce.groupe_id AND m.student_id = p_student_id
                         AND (m.joined_at AT TIME ZONE 'Asia/Riyadh')::date <= (ce.du + g.n)
                         AND (m.left_at IS NULL OR (ce.du + g.n) < (m.left_at AT TIME ZONE 'Asia/Riyadh')::date))))
        UNION
        SELECT (p.debut + g.n) AS d
          FROM public.pauses_eleve p
         CROSS JOIN LATERAL pg_catalog.generate_series(0, p.fin - p.debut) AS g(n)
         WHERE p.student_id = p_student_id AND p.statut = 'acceptee'
      ) j
     WHERE j.d >= p_entree AND j.d <= p_entree + (v_semaines * 7 + v_r);
    EXIT WHEN v_n = v_r;
    v_r := v_n;
  END LOOP;
  RETURN QUERY SELECT v_r, v_ecoules;
END;
$function$;

COMMENT ON FUNCTION private.recul_jours_calcule(uuid, date, uuid, text) IS
  'CALENDRIER-ET-PAUSES : LE calcul du recul de la date limite de l''etape (jours de fermeture publiee '
  'et de pause acceptee reunis sans double compte, de l''entree dans l''etape a sa date limite reculee ; '
  'une fermeture de classe compte les jours ou l''eleve en etait membre) et des jours deja ecoules. '
  'Seul appelant : le declencheur eleve_etape_en_cours_recul.';

-- recul_jours n'est plus une valeur saisie : le declencheur la derive a chaque
-- ecriture du fait (creation, changement d'etape, recalcul force), sans jamais la
-- laisser descendre sous les jours deja ecoules de la meme etape.
CREATE FUNCTION private.eleve_etape_recul_deriver()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_recul integer;
  v_acquis integer;
BEGIN
  SELECT r.recul, r.acquis INTO v_recul, v_acquis
    FROM private.recul_jours_calcule(NEW.student_id, NEW.entree_etape_le, NEW.niveau_id, NEW.cohorte) r;
  IF TG_OP = 'UPDATE' AND OLD.entree_etape_le IS NOT DISTINCT FROM NEW.entree_etape_le THEN
    NEW.recul_acquis_jours := greatest(OLD.recul_acquis_jours, v_acquis);
  ELSE
    NEW.recul_acquis_jours := v_acquis;
    NEW.recul_ajustement_jours := 0;   -- nouvelle etape : on repart de ses propres jours
    NEW.recul_plancher_jours := 0;
  END IF;
  NEW.recul_jours := greatest(greatest(0, v_recul + NEW.recul_ajustement_jours),
                              NEW.recul_acquis_jours, NEW.recul_plancher_jours);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER eleve_etape_en_cours_recul
  BEFORE INSERT OR UPDATE ON public.eleve_etape_en_cours
  FOR EACH ROW EXECUTE FUNCTION private.eleve_etape_recul_deriver();

-- Un changement de classe ne change JAMAIS la date limite de l'eleve (charte, revue du
-- 13/11, I-B1) : le recul d'avant est fige par un ajustement qui absorbe la difference
-- entre l'ancien calcul et le nouveau, dans les deux sens. Les fermetures et pauses
-- publiees ensuite reculent la date normalement.
CREATE FUNCTION private.groupe_membres_recalculer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  f public.eleve_etape_en_cours%ROWTYPE;
  v_calcule integer;
BEGIN
  SELECT * INTO f FROM public.eleve_etape_en_cours x WHERE x.student_id = NEW.student_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  SELECT r.recul INTO v_calcule
    FROM private.recul_jours_calcule(f.student_id, f.entree_etape_le, f.niveau_id, f.cohorte) r;
  UPDATE public.eleve_etape_en_cours x
     SET recul_ajustement_jours = f.recul_ajustement_jours
                                  + (f.recul_jours - greatest(0, coalesce(v_calcule, 0) + f.recul_ajustement_jours)),
         recul_plancher_jours = greatest(f.recul_plancher_jours, f.recul_jours)
   WHERE x.student_id = NEW.student_id;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER groupe_membres_calendrier_recul
  AFTER INSERT OR UPDATE OF left_at, joined_at ON public.groupe_membres
  FOR EACH ROW EXECUTE FUNCTION private.groupe_membres_recalculer();

-- Un recalcul force, pour les eleves vises (le declencheur ci-dessus derive la valeur).
CREATE FUNCTION private.recul_recalculer_cible(p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
BEGIN
  UPDATE public.eleve_etape_en_cours f
     SET recul_jours = f.recul_jours
   WHERE p_portee = 'ecole'
      OR (p_portee = 'tranche'
          AND coalesce(f.cohorte, private.cohorte_effective(f.student_id, NULL)) = p_cohorte)
      OR (p_portee = 'classe'
          AND EXISTS (SELECT 1 FROM public.groupe_membres m
                       WHERE m.groupe_id = p_groupe_id AND m.student_id = f.student_id));
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$function$;

-- La notification d'une fermeture (revue du 13/11, arbitrage de l'architecte) : une seance ne disparait
-- jamais en silence de l'agenda de la famille. UNE notification dans l'application par (destinataire,
-- classe, fermeture) et par geste, qui liste les seances : au tuteur (portee foyer) et a l'eleve ADULTE
-- (portee soi), a l'enseignant de la classe aussi ; JAMAIS a un mineur (aucune notification, aucun
-- courriel, aucun push vers un profil mineur : le tuteur est le destinataire). Pas de courriel ni de push
-- dans ce lot (dette : lot 7). Un echec d'ecriture ne bloque jamais la fermeture (avertissement).
-- p_evenement : fermeture_annoncee (seances mises de cote) ou fermeture_levee (seances retablies, et
-- seances abandonnees quand la direction l'a confirme).
CREATE FUNCTION private.fermeture_notifier(
  p_fermeture uuid, p_groupe uuid, p_evenement text, p_retablies_ou_mises uuid[], p_abandonnees uuid[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ce public.calendrier_ecole%ROWTYPE;
  v_g public.groupes%ROWTYPE;
  v_premiere timestamptz;
  v_n integer := 0;
  v_tous uuid[] := coalesce(p_retablies_ou_mises, '{}') || coalesce(p_abandonnees, '{}');
BEGIN
  IF pg_catalog.cardinality(v_tous) = 0 THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_ce FROM public.calendrier_ecole c WHERE c.id = p_fermeture;
  SELECT * INTO v_g FROM public.groupes x WHERE x.id = p_groupe;
  IF v_ce.id IS NULL OR v_g.id IS NULL THEN
    RETURN 0;
  END IF;
  SELECT pg_catalog.min(s.started_at) INTO v_premiere FROM public.sessions s WHERE s.id = ANY (v_tous);
  BEGIN
    WITH membres AS (
      SELECT gm.student_id FROM public.groupe_membres gm
       WHERE gm.groupe_id = p_groupe AND gm.left_at IS NULL
    ),
    personnes AS (
      -- L'eleve ADULTE autonome, lui-meme (jamais un mineur).
      SELECT p.id AS destinataire, p.household_id AS foyer, 'soi'::text AS portee,
             CASE p.role WHEN 'guardian' THEN '/tuteur/classes/' || p_groupe::text || '/planning'
                         ELSE '/eleve' END AS destination,
             h.timezone AS fuseau, 1 AS rang, NULL::text AS prenom
        FROM membres m
        JOIN public.student_profiles sp ON sp.profile_id = m.student_id AND sp.student_type = 'autonomous'
        JOIN public.profiles p ON p.id = m.student_id AND p.deleted_at IS NULL AND p.role IN ('student', 'guardian')
        LEFT JOIN public.households h ON h.id = p.household_id
      UNION ALL
      -- Les tuteurs du foyer d'un MINEUR.
      SELECT t.id, p.household_id, 'foyer', '/tuteur/classes/' || p_groupe::text || '/planning',
             h.timezone, 2, p.first_name
        FROM membres m
        JOIN public.student_profiles sp ON sp.profile_id = m.student_id AND sp.student_type = 'minor'
        JOIN public.profiles p ON p.id = m.student_id AND p.deleted_at IS NULL
        JOIN public.households h ON h.id = p.household_id AND h.deleted_at IS NULL
        JOIN public.profiles t ON t.deleted_at IS NULL AND t.role = 'guardian'
                              AND (t.id = h.primary_guardian_id OR t.household_id = h.id)
      UNION ALL
      -- L'enseignant de la classe, et ceux des seances listees.
      SELECT x.id, NULL::uuid, 'classe', '/enseignant/classes',
             coalesce(tp.timezone_iana, v_g.timezone_iana), 3, NULL::text
        FROM (SELECT v_g.teacher_id AS id
              UNION
              SELECT s.teacher_id FROM public.sessions s WHERE s.id = ANY (v_tous)) x
        JOIN public.profiles pr ON pr.id = x.id AND pr.deleted_at IS NULL AND pr.role = 'teacher'
        LEFT JOIN public.teacher_profiles tp ON tp.profile_id = x.id
    ),
    destinataires AS (
      SELECT DISTINCT ON (destinataire) destinataire, foyer, portee, destination, fuseau
        FROM personnes ORDER BY destinataire, rang
    ),
    prenoms AS (
      SELECT x.destinataire, pg_catalog.jsonb_agg(DISTINCT x.prenom ORDER BY x.prenom) AS eleves
        FROM personnes x JOIN destinataires d ON d.destinataire = x.destinataire AND d.portee = x.portee
       WHERE x.portee = 'foyer' AND x.prenom IS NOT NULL AND pg_catalog.btrim(x.prenom) <> ''
       GROUP BY x.destinataire
    )
    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    SELECT d.destinataire, d.foyer, p_evenement,
           pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
             'groupe_id', p_groupe, 'fermeture_id', p_fermeture, 'portee', d.portee,
             'classe', nullif(pg_catalog.btrim(v_g.libelle), ''),
             'du', v_ce.du, 'au', v_ce.au,
             'nombre', pg_catalog.cardinality(v_tous),
             'retablies', CASE WHEN p_evenement = 'fermeture_levee' THEN pg_catalog.cardinality(coalesce(p_retablies_ou_mises, '{}')) END,
             'abandonnees', CASE WHEN p_evenement = 'fermeture_levee' THEN pg_catalog.cardinality(coalesce(p_abandonnees, '{}')) END,
             'premiere_jour', private.jour_academie_de(v_premiere),
             'premiere_heure', pg_catalog.to_char(v_premiere AT TIME ZONE 'Asia/Riyadh', 'HH24:MI'),
             'debut_local', pg_catalog.to_char(v_premiere AT TIME ZONE coalesce(d.fuseau, 'UTC'), 'YYYY-MM-DD"T"HH24:MI:SS'),
             'fuseau', coalesce(d.fuseau, 'UTC'),
             'eleves', pr.eleves)),
           d.destination
      FROM destinataires d
      LEFT JOIN prenoms pr ON pr.destinataire = d.destinataire
     WHERE NOT EXISTS (
       SELECT 1 FROM public.notifications n
        WHERE n.destinataire = d.destinataire AND n.evenement = p_evenement
          AND n.cree_le = pg_catalog.now()
          AND n.params ->> 'groupe_id' = p_groupe::text AND n.params ->> 'fermeture_id' = p_fermeture::text);
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fermeture : notification non posee (SQLSTATE %), la fermeture est enregistree', SQLSTATE;
  END;
  RETURN v_n;
END;
$function$;

-- Les seances deja creees qu'une fermeture publiee couvre sont mises de cote (deleted_at,
-- jamais supprimees) : elles n'entrent ni dans le remplacement automatique, ni dans la
-- cloture automatique, ni dans la paie, ni dans les absences, ni dans le jeton video. Seules
-- les seances NON COMMENCEES a la publication sont touchees (debut posterieur a publie_le et
-- a maintenant) : une seance en cours ou deja commencee continue normalement. Une
-- fermeture retiree ou raccourcie avant son debut retablit les seances de cote ; si l'une ne
-- peut pas l'etre (l'enseignant a pris un autre cours a cette heure), le retrait est REFUSE
-- (calendrier_retrait_conflits), sauf si la direction a confirme d'abandonner exactement ces
-- seances (reglage de transaction calendrier.abandon, pose par calendrier_ecole_retirer) :
-- elles portent alors abandonnee_le dans seances_fermees et une ligne du journal d'audit.
-- La classe n'est pas prevenue seance par seance (l'annonce de la fermeture est le lot 7) :
-- l'indicateur local coupe notifier_classe_seances.
CREATE FUNCTION private.fermeture_synchroniser(p_nuit boolean DEFAULT false)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  r record;
  v_n integer := 0;
  v_conflits uuid[] := '{}';
  v_abandon integer;
  v_retablies uuid[] := '{}';
  v_mises uuid[] := '{}';
  grp record;
BEGIN
  PERFORM pg_catalog.set_config('calendrier.fermeture', '1', true);
  -- 1. Retablir les seances mises de cote dont le jour n'est plus ferme.
  FOR r IN
    SELECT sf.session_id, s.started_at, s.groupe_id
      FROM public.seances_fermees sf
      JOIN public.sessions s ON s.id = sf.session_id
     WHERE sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL AND s.deleted_at IS NOT NULL
     ORDER BY s.started_at
       FOR UPDATE OF sf
  LOOP
    IF r.started_at > pg_catalog.now() AND NOT private.session_en_fermeture(r.started_at, r.groupe_id) THEN
      BEGIN
        UPDATE public.sessions SET deleted_at = NULL WHERE id = r.session_id;
        UPDATE public.seances_fermees SET retablie_le = pg_catalog.now() WHERE session_id = r.session_id;
        -- Un eleve entre dans la classe pendant la mise de cote est participant de la seance
        -- retablie (la generation ne passait pas sur les seances de cote).
        INSERT INTO public.session_participants (session_id, profile_id, role)
        SELECT r.session_id, m.student_id, 'student'
          FROM public.groupe_membres m
         WHERE m.groupe_id = r.groupe_id AND m.left_at IS NULL
        ON CONFLICT (session_id, profile_id) DO NOTHING;
        v_n := v_n + 1;
        v_retablies := v_retablies || r.session_id;
      EXCEPTION WHEN exclusion_violation THEN
        v_conflits := v_conflits || r.session_id;
      END;
    END IF;
  END LOOP;
  IF p_nuit AND pg_catalog.cardinality(v_conflits) > 0 THEN
    -- La cloche de nuit ne refuse rien et n'abandonne rien : une seance qui ne peut pas etre retablie reste de
    -- cote, la direction en est avertie (une notification par seance et par nuit au plus), un humain tranche.
    FOR r IN SELECT x FROM pg_catalog.unnest(v_conflits) AS x LOOP
      PERFORM private.fermeture_signaler_conflit(r.x);
    END LOOP;
    v_conflits := '{}';
  END IF;
  IF pg_catalog.cardinality(v_conflits) > 0 THEN
    v_abandon := NULLIF(pg_catalog.current_setting('calendrier.abandon', true), '')::integer;
    IF v_abandon IS DISTINCT FROM pg_catalog.cardinality(v_conflits) THEN
      RAISE EXCEPTION 'calendrier_retrait_conflits' USING errcode = '22023',
        detail = pg_catalog.cardinality(v_conflits)::text || ' seance(s) ne peuvent pas etre retablies';
    END IF;
    UPDATE public.seances_fermees
       SET abandonnee_le = pg_catalog.now(), abandonnee_par = auth.uid()
     WHERE session_id = ANY (v_conflits);
    FOR r IN SELECT x FROM pg_catalog.unnest(v_conflits) AS x LOOP
      PERFORM public.log_sensitive_access('seance_abandonnee_fermeture', 'sessions', r.x::text,
        pg_catalog.jsonb_build_object('motif', 'fermeture retiree, enseignant pris a cette heure'));
    END LOOP;
  END IF;
  -- 2. Mettre de cote les seances non commencees dont le jour est ferme pour leur classe.
  FOR r IN
    SELECT s.id, ce.id AS fermeture_id
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
      JOIN public.calendrier_ecole ce
        ON ce.publie AND ce.type = 'fermeture'
       AND private.jour_academie_de(s.started_at) BETWEEN ce.du AND ce.au
       AND s.started_at > ce.publie_le
       AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, g.id)
     WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
       AND s.started_at > pg_catalog.now()
     ORDER BY s.started_at, ce.id
  LOOP
    CONTINUE WHEN EXISTS (SELECT 1 FROM public.sessions x WHERE x.id = r.id AND x.deleted_at IS NOT NULL);
    UPDATE public.sessions SET deleted_at = pg_catalog.now() WHERE id = r.id;
    INSERT INTO public.seances_fermees (session_id, fermeture_id)
    VALUES (r.id, r.fermeture_id)
    ON CONFLICT (session_id) DO UPDATE
      SET fermeture_id = excluded.fermeture_id, masquee_le = pg_catalog.now(),
          retablie_le = NULL, abandonnee_le = NULL, abandonnee_par = NULL;
    v_n := v_n + 1;
    v_mises := v_mises || r.id;
  END LOOP;
  -- 3. Les familles, les adultes et les enseignants sont prevenus : une notification par classe et par
  -- fermeture, qui liste les seances (jamais un mineur).
  FOR grp IN
    SELECT sf.fermeture_id, s.groupe_id,
           pg_catalog.array_agg(s.id ORDER BY s.started_at) FILTER (WHERE s.id = ANY (v_retablies)) AS retablies,
           pg_catalog.array_agg(s.id ORDER BY s.started_at) FILTER (WHERE s.id = ANY (v_conflits)) AS abandonnees
      FROM public.seances_fermees sf JOIN public.sessions s ON s.id = sf.session_id
     WHERE s.id = ANY (v_retablies) OR s.id = ANY (v_conflits)
     GROUP BY sf.fermeture_id, s.groupe_id
  LOOP
    PERFORM private.fermeture_notifier(grp.fermeture_id, grp.groupe_id, 'fermeture_levee',
                                       grp.retablies, grp.abandonnees);
  END LOOP;
  FOR grp IN
    SELECT sf.fermeture_id, s.groupe_id, pg_catalog.array_agg(s.id ORDER BY s.started_at) AS ids
      FROM public.seances_fermees sf JOIN public.sessions s ON s.id = sf.session_id
     WHERE s.id = ANY (v_mises)
     GROUP BY sf.fermeture_id, s.groupe_id
  LOOP
    PERFORM private.fermeture_notifier(grp.fermeture_id, grp.groupe_id, 'fermeture_annoncee', grp.ids, '{}');
  END LOOP;
  RETURN v_n;
END;
$function$;

-- Garde generale : une seance de classe creee ou deplacee (creneau modifie, fusion de classes,
-- tout code futur) sur un jour de fermeture publiee est mise de cote tout de suite, comme celles
-- que la publication d'une fermeture trouve deja creees. Les sauts de classe et de date voulus
-- par la direction (nouvelle date d'une seance reportee) sont refuses plus haut, avec leur phrase.
-- La direction est avertie qu'une seance, qui n'est plus couverte par aucune fermeture, ne peut pas etre
-- retablie (l'enseignant a pris un autre cours a la meme heure) : une notification par administrateur actif,
-- par seance et par nuit au plus (le rejeu de la nuit ne redouble rien). Application seulement (ni courriel
-- ni push) ; un echec d'ecriture n'arrete jamais la cloche.
CREATE FUNCTION private.fermeture_signaler_conflit(p_session uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer := 0;
BEGIN
  BEGIN
    INSERT INTO public.notifications (destinataire, evenement, params, destination)
    SELECT a.id, 'fermeture_conflit',
           pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
             'portee', 'direction', 'session_id', s.id, 'groupe_id', s.groupe_id,
             'classe', nullif(pg_catalog.btrim(g.libelle), ''),
             'premiere_jour', private.jour_academie_de(s.started_at),
             'premiere_heure', pg_catalog.to_char(s.started_at AT TIME ZONE 'Asia/Riyadh', 'HH24:MI'),
             'enseignant', nullif(pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')), ''),
             'nuit', private.jour_academie()::text)),
           '/admin/operations/planning'
      FROM public.sessions s
      JOIN public.groupes g ON g.id = s.groupe_id
      LEFT JOIN public.profiles t ON t.id = s.teacher_id
      CROSS JOIN LATERAL (
        SELECT pr.id FROM public.profiles pr
         WHERE pr.role = 'admin' AND pr.account_status = 'active' AND pr.deleted_at IS NULL
           AND (pr.access_until IS NULL OR pr.access_until > pg_catalog.now())) a
     WHERE s.id = p_session
       AND NOT EXISTS (
         SELECT 1 FROM public.notifications n
          WHERE n.destinataire = a.id AND n.evenement = 'fermeture_conflit'
            AND n.params ->> 'session_id' = p_session::text
            AND n.params ->> 'nuit' = private.jour_academie()::text);
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'fermeture : conflit de la seance % non signale (SQLSTATE %)', p_session, SQLSTATE;
  END;
  RETURN v_n;
END;
$function$;

-- Le balayage de nuit (contre-lecture du 13/11, IMP-A) : une classe qui devient couverte par une fermeture de
-- TRANCHE apres la publication (un changement de membres) garde sinon une seance « planned » vivante un jour
-- ferme, que la famille verrait, jamais annoncee. Regle voulue : aucun cours affiche un jour ferme. Le
-- balayage met de cote les seances vivantes non commencees des jours fermes et les notifie par le meme
-- chemin (private.fermeture_notifier : jamais un mineur, une notification par destinataire, classe et
-- fermeture). Rejoue, il ne trouve plus rien : aucun doublon. Aucun declencheur sur groupe_membres (le cout
-- d'un recalcul a chaque changement de membre n'est pas prouve nul). Appele par la cloche de nuit.
-- LE CAS INVERSE (arbitrage de l'architecte : des eleves ne perdent jamais un cours un jour OUVERT) : la meme
-- cloche RETABLIT une seance de cote qui n'est plus couverte par AUCUNE fermeture, si le retablissement ne
-- trouve aucun conflit (meme simulation que le retrait : tentative en sous-transaction), et previent par
-- fermeture_levee ; sinon elle ne retablit pas et avertit la direction (fermeture_conflit). Une seance deja
-- passee n'est jamais retablie, rien n'est envoye.
CREATE FUNCTION private.fermeture_balayer()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT private.fermeture_synchroniser(true);
$function$;

CREATE FUNCTION private.seance_jour_ferme_garde()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fermeture uuid;
BEGIN
  SELECT ce.id INTO v_fermeture
    FROM public.groupes g
    JOIN public.calendrier_ecole ce
      ON ce.publie AND ce.type = 'fermeture'
     AND private.jour_academie_de(NEW.started_at) BETWEEN ce.du AND ce.au
     AND NEW.started_at > ce.publie_le
     AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, g.id)
   WHERE g.id = NEW.groupe_id AND g.ended_at IS NULL
   ORDER BY ce.du, ce.id
   LIMIT 1;
  IF v_fermeture IS NOT NULL THEN
    PERFORM pg_catalog.set_config('calendrier.fermeture', '1', true);
    UPDATE public.sessions SET deleted_at = pg_catalog.now() WHERE id = NEW.id;
    INSERT INTO public.seances_fermees (session_id, fermeture_id)
    VALUES (NEW.id, v_fermeture)
    ON CONFLICT (session_id) DO UPDATE
      SET fermeture_id = excluded.fermeture_id, masquee_le = pg_catalog.now(),
          retablie_le = NULL, abandonnee_le = NULL, abandonnee_par = NULL;
  END IF;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER sessions_jour_ferme_garde
  AFTER INSERT OR UPDATE OF started_at, groupe_id ON public.sessions
  FOR EACH ROW
  WHEN (NEW.groupe_id IS NOT NULL AND NEW.deleted_at IS NULL
        AND NEW.status IN ('planned', 'preflight')
        AND NEW.started_at > pg_catalog.now())
  EXECUTE FUNCTION private.seance_jour_ferme_garde();

CREATE FUNCTION private.calendrier_ecole_recalculer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.publie AND NEW.type = 'fermeture' THEN
      PERFORM private.recul_recalculer_cible(NEW.portee, NEW.cohorte, NEW.groupe_id);
    END IF;
  ELSE
    IF (OLD.publie AND OLD.type = 'fermeture') THEN
      PERFORM private.recul_recalculer_cible(OLD.portee, OLD.cohorte, OLD.groupe_id);
    END IF;
    IF (NEW.publie AND NEW.type = 'fermeture') THEN
      PERFORM private.recul_recalculer_cible(NEW.portee, NEW.cohorte, NEW.groupe_id);
    END IF;
  END IF;
  IF NEW.type = 'fermeture' OR (TG_OP = 'UPDATE' AND OLD.type = 'fermeture') THEN
    PERFORM private.fermeture_synchroniser();
  END IF;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER calendrier_ecole_recul
  AFTER INSERT OR UPDATE ON public.calendrier_ecole
  FOR EACH ROW EXECUTE FUNCTION private.calendrier_ecole_recalculer();

CREATE FUNCTION private.pauses_eleve_recalculer()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.eleve_etape_en_cours f
     SET recul_jours = f.recul_jours
   WHERE f.student_id = NEW.student_id;
  RETURN NULL;
END;
$function$;

CREATE TRIGGER pauses_eleve_recul
  AFTER INSERT OR UPDATE ON public.pauses_eleve
  FOR EACH ROW EXECUTE FUNCTION private.pauses_eleve_recalculer();

-- Les eleves deja presents : leur recul est calcule des l'installation (nul tant
-- qu'aucune fermeture ni pause n'est publiee).
UPDATE public.eleve_etape_en_cours SET recul_jours = recul_jours;

-- ---------------------------------------------------------------------------
-- 6. La generation des seances respecte les fermetures (minimum sur)
-- ---------------------------------------------------------------------------
-- Une fermeture publiee : materialiser_seances_groupe ne CREE plus de seance ce
-- jour-la. Aucune seance existante n'est supprimee, annulee ni deplacee (leur
-- sort est une decision de la direction : voir la fiche du lot). Remplacement
-- exact, compte et idempotent, comme 20261030100000 ; si le texte de la fonction
-- a change, la migration s'arrete et le dit.
CREATE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, p_apres) > 0 THEN
    RETURN;  -- deja remplace (rejeu)
  END IF;
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

SELECT pg_temp.remplacer('public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure,
  $a$      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$a$,
  $b$      -- CALENDRIER-ET-PAUSES (12/11/2026) : aucune seance n'est creee un jour de
      -- fermeture publiee ; les seances deja creees ne sont pas touchees.
      IF private.debut_ferme(v_debut, p_groupe_id) THEN
        CONTINUE;
      END IF;

      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$b$, 1);

-- Le concierge (seance_a_rejoindre) cree la seance du cours en cours quand une
-- personne de la classe appuie sur « Rejoindre » : jamais un jour de fermeture
-- publiee. Une seance deja creee est rendue telle quelle (inchange).
-- Une seance mise de cote par une fermeture n'est PAS une seance supprimee par la direction :
-- le materialiseur la voit comme existante (il ne la recree pas, et il en tient les
-- participants a jour) ; seule une seance abandonnee ou supprimee reste ecartee.
SELECT pg_temp.remplacer('public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure,
  $a$      SELECT s.id, s.deleted_at IS NOT NULL INTO v_session, v_supprimee$a$,
  $b$      SELECT s.id, (s.deleted_at IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM public.seances_fermees sf
                                     WHERE sf.session_id = s.id
                                       AND sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL))
        INTO v_session, v_supprimee$b$, 1);

SELECT pg_temp.remplacer('public.seance_a_rejoindre(uuid)'::pg_catalog.regprocedure,
  $a$    INSERT INTO public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$a$,
  $b$    -- CALENDRIER-ET-PAUSES (13/11/2026) : aucune seance n'est creee un jour de
    -- fermeture publiee.
    IF private.debut_ferme(v_debut, p_groupe_id) THEN
      CONTINUE;
    END IF;

    INSERT INTO public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)$b$, 1);

-- La mise de cote ou le retablissement d'une seance par une fermeture ne previent pas
-- la classe seance par seance (indicateur local pose par fermeture_synchroniser).
SELECT pg_temp.remplacer('private.notifier_classe_seances()'::pg_catalog.regprocedure,
  $a$  IF TG_OP = 'INSERT' THEN
    RETURN NULL;
  END IF;$a$,
  $b$  IF TG_OP = 'INSERT' THEN
    RETURN NULL;
  END IF;
  -- CALENDRIER-ET-PAUSES (13/11/2026) : une seance mise de cote (ou retablie) par une
  -- fermeture publiee ne previent pas la classe seance par seance.
  IF pg_catalog.current_setting('calendrier.fermeture', true) = '1' THEN
    RETURN NULL;
  END IF;$b$, 1);

-- Ceintures (revue du 13/11, B2) : trois circuits ignorent une seance dont le jour est
-- ferme pour sa classe, meme si elle n'a pas ete mise de cote. Aucune seance ne part au
-- remplacement automatique, ni a la cloture automatique, ni n'ouvre de jeton video.
SELECT pg_temp.remplacer('private.remplacement_auto_passer(timestamptz)'::pg_catalog.regprocedure,
  $a$WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')$a$,
  $b$WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight', 'in_progress')
       AND NOT private.session_en_fermeture(s.started_at, s.groupe_id)$b$, 4);
SELECT pg_temp.remplacer('private.ses_cloturer_seances_echues(timestamptz)'::pg_catalog.regprocedure,
  $a$     WHERE s.deleted_at IS NULL
       AND s.status IN ('planned', 'preflight', 'in_progress')$a$,
  $b$     WHERE s.deleted_at IS NULL
       AND NOT private.session_en_fermeture(s.started_at, s.groupe_id)
       AND s.status IN ('planned', 'preflight', 'in_progress')$b$, 1);
SELECT pg_temp.remplacer('public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure,
  $a$ where s.id = p_session_id and s.deleted_at is null;$a$,
  $b$ where s.id = p_session_id and s.deleted_at is null
     and not private.session_en_fermeture(s.started_at, s.groupe_id);$b$, 1);

-- La cloche de nuit (20261025000000) met aussi de cote les seances vivantes des jours fermes (IMP-A).
SELECT pg_temp.remplacer('private.materialiser_classes_actives()'::pg_catalog.regprocedure,
  $a$  RETURN v_n;
END;$a$,
  $b$  -- CALENDRIER-ET-PAUSES (13/11/2026) : balayage des jours fermes ; une erreur ne bloque jamais la cloche.
  BEGIN
    PERFORM private.fermeture_balayer();
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'la cloche : balayage des fermetures impossible (%, %)', SQLSTATE, SQLERRM;
  END;
  RETURN v_n;
END;$b$, 1);

-- Une entree de la file de remplacement ANTERIEURE a la mise de cote ne fait rien sur une seance mise de
-- cote (ni sur un jour de fermeture) : ni remplacant retenu, ni « pret ».
SELECT pg_temp.remplacer('private.remplacement_choisir(uuid)'::pg_catalog.regprocedure,
  $a$  IF NOT FOUND OR v_absence.evenement <> 'absence_declaree' THEN
    RETURN NULL;
  END IF;$a$,
  $b$  IF NOT FOUND OR v_absence.evenement <> 'absence_declaree' THEN
    RETURN NULL;
  END IF;
  -- CALENDRIER-ET-PAUSES (13/11/2026) : une seance mise de cote par une fermeture ne se remplace pas.
  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.id = v_absence.session_id
                AND (s.deleted_at IS NOT NULL OR private.session_en_fermeture(s.started_at, s.groupe_id))) THEN
    RETURN NULL;
  END IF;$b$, 1);
SELECT pg_temp.remplacer('private.remplacement_choisir_pret(uuid)'::pg_catalog.regprocedure,
  $a$  SELECT p.enseignant_id INTO v_deja FROM public.remplacements_preparation p
   WHERE p.session_id = p_session_id AND p.evenement = 'pret';$a$,
  $b$  -- CALENDRIER-ET-PAUSES (13/11/2026) : une seance mise de cote par une fermeture ne se remplace pas.
  IF EXISTS (SELECT 1 FROM public.sessions s
              WHERE s.id = p_session_id
                AND (s.deleted_at IS NOT NULL OR private.session_en_fermeture(s.started_at, s.groupe_id))) THEN
    RETURN NULL;
  END IF;
  SELECT p.enseignant_id INTO v_deja FROM public.remplacements_preparation p
   WHERE p.session_id = p_session_id AND p.evenement = 'pret';$b$, 1);

-- La nouvelle date d'une seance reportee, choisie par la direction : jamais un jour ferme
-- pour la classe (refus avec une phrase claire cote ecran).
SELECT pg_temp.remplacer('public.fixer_nouvelle_date_seance(uuid,timestamptz)'::pg_catalog.regprocedure,
  $a$  -- La meme duree que la seance reportee.
  v_fin := p_debut + (v_o.ended_at - v_o.started_at);$a$,
  $b$  -- CALENDRIER-ET-PAUSES (13/11/2026) : jamais une nouvelle date un jour de fermeture publiee.
  IF private.session_en_fermeture(p_debut, v_r.groupe_id) THEN
    RAISE EXCEPTION 'NouvelleDateFermee' USING ERRCODE = '22023',
      DETAIL = 'la classe est fermee ce jour-la';
  END IF;
  -- La meme duree que la seance reportee.
  v_fin := p_debut + (v_o.ended_at - v_o.started_at);$b$, 1);

-- L'ancien circuit des affectations individuelles ne cree rien un jour de fermeture de toute
-- l'academie (aucune classe : seule une fermeture de l'academie entiere le vise).
SELECT pg_temp.remplacer('public.materialiser_seances(uuid)'::pg_catalog.regprocedure,
  $a$    insert into public.sessions (teacher_id, started_at, ended_at, session_type)
    values (v_a.teacher_id, v_debut,$a$,
  $b$    -- CALENDRIER-ET-PAUSES (13/11/2026) : aucune seance un jour de fermeture de l'academie.
    if private.debut_ferme(v_debut, null) then
      continue;
    end if;

    insert into public.sessions (teacher_id, started_at, ended_at, session_type)
    values (v_a.teacher_id, v_debut,$b$, 1);

-- Les empreintes F86 des fonctions retouchees suivent leur nouveau corps.
DO $empreinte$
DECLARE
  v_f pg_catalog.regprocedure;
  v_com text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure,
    'public.seance_a_rejoindre(uuid)'::pg_catalog.regprocedure,
    'private.notifier_classe_seances()'::pg_catalog.regprocedure,
    'private.remplacement_auto_passer(timestamptz)'::pg_catalog.regprocedure,
    'private.ses_cloturer_seances_echues(timestamptz)'::pg_catalog.regprocedure,
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure,
    'public.fixer_nouvelle_date_seance(uuid,timestamptz)'::pg_catalog.regprocedure,
    'public.materialiser_seances(uuid)'::pg_catalog.regprocedure,
    'private.remplacement_choisir(uuid)'::pg_catalog.regprocedure,
    'private.remplacement_choisir_pret(uuid)'::pg_catalog.regprocedure,
    'private.materialiser_classes_actives()'::pg_catalog.regprocedure
  ] LOOP
    v_com := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_com ~ 'md5_functiondef=[0-9a-f]{32}' THEN
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f,
        pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9a-f]{32}',
          'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f))));
    END IF;
  END LOOP;
END
$empreinte$;

-- ---------------------------------------------------------------------------
-- 7. La lecture unique de l'etape montre le recul (lot 1, ajout d'une cle)
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.etape_eleve_lecture(uuid)'::pg_catalog.regprocedure,
  $a$      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_dates.date_limite END,$a$,
  $b$      'date_limite', CASE WHEN v_masque THEN NULL ELSE v_dates.date_limite END,
      'recul_jours', CASE WHEN v_masque THEN NULL ELSE f.recul_jours END,$b$, 1);

-- ---------------------------------------------------------------------------
-- 8. Le calendrier : gestes de la direction et lecture unique
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.calendrier_ecole_enregistrer(
  p_id uuid, p_type text, p_categorie text, p_titre text, p_du date, p_au date,
  p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_id uuid;
  v_categorie text;
  v_portee text := coalesce(p_portee, 'ecole');
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  IF p_type IS NULL OR p_type NOT IN ('fermeture', 'rencontre', 'evaluation', 'autre')
     OR p_titre IS NULL OR pg_catalog.btrim(p_titre) = '' OR pg_catalog.length(p_titre) > 120 THEN
    RAISE EXCEPTION 'calendrier_evenement_invalide' USING errcode = '22023';
  END IF;
  IF p_du IS NULL OR p_au IS NULL OR p_au < p_du OR p_au - p_du > 365 THEN
    RAISE EXCEPTION 'calendrier_dates_invalides' USING errcode = '22023';
  END IF;
  IF v_portee NOT IN ('ecole', 'tranche', 'classe')
     OR (v_portee = 'tranche' AND (p_cohorte IS NULL
         OR NOT EXISTS (SELECT 1 FROM public.cohortes_age a WHERE a.code = p_cohorte)))
     OR (v_portee = 'classe' AND (p_groupe_id IS NULL
         OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id))) THEN
    RAISE EXCEPTION 'calendrier_portee_invalide' USING errcode = '22023';
  END IF;
  v_categorie := CASE WHEN p_type = 'fermeture' THEN coalesce(p_categorie, 'autre') END;
  IF v_categorie IS NOT NULL AND v_categorie NOT IN ('ramadan', 'aid_al_adha', 'autre') THEN
    RAISE EXCEPTION 'calendrier_evenement_invalide' USING errcode = '22023';
  END IF;

  IF p_id IS NULL THEN
    INSERT INTO public.calendrier_ecole
      (type, categorie, titre, du, au, portee, cohorte, groupe_id, cree_par, maj_par)
    VALUES
      (p_type, v_categorie, pg_catalog.btrim(p_titre), p_du, p_au, v_portee,
       CASE WHEN v_portee = 'tranche' THEN p_cohorte END,
       CASE WHEN v_portee = 'classe' THEN p_groupe_id END, v_user, v_user)
    RETURNING id INTO v_id;
  ELSE
    -- Une fermeture PUBLIEE ne se deplace pas avant aujourd'hui (jour de l'academie) : une
    -- fermeture ne s'applique jamais en arriere (revue du 13/11, I-B1c).
    IF p_type = 'fermeture' AND p_du < private.jour_academie() AND EXISTS (
         SELECT 1 FROM public.calendrier_ecole c
          WHERE c.id = p_id AND c.publie AND c.du IS DISTINCT FROM p_du) THEN
      RAISE EXCEPTION 'calendrier_fermeture_passee' USING errcode = '22023';
    END IF;
    UPDATE public.calendrier_ecole
       SET type = p_type, categorie = v_categorie, titre = pg_catalog.btrim(p_titre),
           du = p_du, au = p_au, portee = v_portee,
           cohorte = CASE WHEN v_portee = 'tranche' THEN p_cohorte END,
           groupe_id = CASE WHEN v_portee = 'classe' THEN p_groupe_id END,
           maj_par = v_user
     WHERE id = p_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
    END IF;
  END IF;
  RETURN v_id;
END;
$function$;

CREATE FUNCTION public.calendrier_ecole_publier(p_id uuid, p_publie boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_ce public.calendrier_ecole%ROWTYPE;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  IF p_id IS NULL OR p_publie IS NULL THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  SELECT * INTO v_ce FROM public.calendrier_ecole c WHERE c.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  -- Une fermeture ne se publie pas pour une date deja passee (jour de l'academie) ; aujourd'hui
  -- reste permis (urgence : seules les seances non commencees sont touchees).
  IF p_publie AND NOT v_ce.publie AND v_ce.type = 'fermeture' AND v_ce.du < private.jour_academie() THEN
    RAISE EXCEPTION 'calendrier_fermeture_passee' USING errcode = '22023';
  END IF;
  -- Un retrait refuse (calendrier_retrait_conflits) est tout le geste annule, rien n'est modifie.
  UPDATE public.calendrier_ecole SET publie = p_publie, maj_par = v_user WHERE id = p_id;
END;
$function$;

-- Retirer une fermeture en confirmant d'abandonner exactement N seances qui ne peuvent pas
-- etre retablies (l'enseignant a pris un autre cours a leur heure). Sans confirmation, ou si
-- N n'est pas le bon nombre, rien ne change et l'erreur calendrier_retrait_conflits est
-- rendue (la direction lit alors calendrier_retrait_conflits). Geste trace au journal.
CREATE FUNCTION public.calendrier_ecole_retirer(p_id uuid, p_abandonner integer DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_ce public.calendrier_ecole%ROWTYPE;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  IF p_id IS NULL OR (p_abandonner IS NOT NULL AND p_abandonner < 1) THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  SELECT * INTO v_ce FROM public.calendrier_ecole c WHERE c.id = p_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  PERFORM pg_catalog.set_config('calendrier.abandon', coalesce(p_abandonner::text, ''), true);
  UPDATE public.calendrier_ecole SET publie = false, maj_par = v_user WHERE id = p_id;
  PERFORM pg_catalog.set_config('calendrier.abandon', '', true);
  IF p_abandonner IS NOT NULL THEN
    PERFORM public.log_sensitive_access('fermeture_retiree_abandon', 'calendrier_ecole', p_id::text,
      pg_catalog.jsonb_build_object('titre', v_ce.titre, 'seances_abandonnees', p_abandonner));
  END IF;
END;
$function$;

-- Les seances qui empechent de retirer cette fermeture : mises de cote par elle, que l'enseignant ne peut plus
-- donner parce qu'il a pris un autre cours a la meme heure, y compris un autre cours QUI EST LUI-MEME une
-- seance mise de cote par cette fermeture (deux seances de cote qui se chevauchent : la premiere se retablit,
-- la seconde non). La liste est exacte : le retablissement est SIMULE dans l'ordre exact de
-- fermeture_synchroniser, puis defait. Classe, jour, heure (heure de La Mecque), enseignant, l'autre cours.
-- (VOLATILE : elle met en jeu et defait ; aucune ecriture ne subsiste.)
CREATE FUNCTION public.calendrier_retrait_conflits(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  r record;
  v_liste jsonb := '[]'::jsonb;
  v_autre jsonb;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  BEGIN
    PERFORM pg_catalog.set_config('calendrier.fermeture', '1', true);
    FOR r IN
      SELECT s.id, s.started_at, s.ended_at, s.teacher_id, g.libelle AS classe,
             pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')) AS enseignant
        FROM public.seances_fermees sf
        JOIN public.sessions s ON s.id = sf.session_id
        JOIN public.groupes g ON g.id = s.groupe_id
        LEFT JOIN public.profiles t ON t.id = s.teacher_id
       WHERE sf.fermeture_id = p_id AND sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL
         AND s.deleted_at IS NOT NULL AND s.started_at > pg_catalog.now()
         AND s.status IN ('planned', 'preflight')
         -- Une seance que ce retrait ne retablirait pas (une autre fermeture la couvre) n'est pas simulee.
         AND NOT EXISTS (
           SELECT 1 FROM public.calendrier_ecole c2
            WHERE c2.id <> p_id AND c2.publie AND c2.type = 'fermeture'
              AND private.jour_academie_de(s.started_at) BETWEEN c2.du AND c2.au
              AND s.started_at > c2.publie_le
              AND private.fermeture_vise_classe(c2.portee, c2.cohorte, c2.groupe_id, s.groupe_id))
       ORDER BY s.started_at
    LOOP
      BEGIN
        UPDATE public.sessions SET deleted_at = NULL WHERE id = r.id;
      EXCEPTION WHEN exclusion_violation THEN
        SELECT pg_catalog.jsonb_build_object(
                 'classe', og.libelle,
                 'jour', private.jour_academie_de(o.started_at),
                 'heure', pg_catalog.to_char(o.started_at AT TIME ZONE 'Asia/Riyadh', 'HH24:MI'))
          INTO v_autre
          FROM public.sessions o
          LEFT JOIN public.groupes og ON og.id = o.groupe_id
         WHERE o.id <> r.id AND o.teacher_id = r.teacher_id AND o.deleted_at IS NULL
           AND o.status IN ('planned', 'preflight', 'in_progress')
           AND o.session_type IN ('standard', 'child')
           AND pg_catalog.tstzrange(o.started_at, o.ended_at, '[)')
               && pg_catalog.tstzrange(r.started_at, r.ended_at, '[)')
         ORDER BY o.started_at LIMIT 1;
        v_liste := v_liste || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'session_id', r.id, 'classe', r.classe,
          'jour', private.jour_academie_de(r.started_at),
          'heure', pg_catalog.to_char(r.started_at AT TIME ZONE 'Asia/Riyadh', 'HH24:MI'),
          'enseignant', r.enseignant, 'autre_cours', v_autre));
      END;
    END LOOP;
    RAISE EXCEPTION 'simulation' USING errcode = 'CP001';   -- defait tout ce qui a ete mis en jeu
  EXCEPTION WHEN SQLSTATE 'CP001' THEN
    NULL;
  END;
  RETURN pg_catalog.jsonb_build_object('nombre', pg_catalog.jsonb_array_length(v_liste), 'conflits', v_liste);
END;
$function$;

-- Les seances reellement concernees par une fermeture (publiee ou non) : celles qui sont
-- encore a venir, leur jour de l'academie dans ses dates, de la portee. Heure de La Mecque,
-- jamais une date a interpreter : la direction voit ce qui sera mis de cote AVANT de publier.
CREATE FUNCTION public.calendrier_seances_concernees(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_ce public.calendrier_ecole%ROWTYPE;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  SELECT * INTO v_ce FROM public.calendrier_ecole c WHERE c.id = p_id;
  IF NOT FOUND OR v_ce.type <> 'fermeture' THEN
    RAISE EXCEPTION 'calendrier_evenement_introuvable' USING errcode = '22023';
  END IF;
  RETURN (
    WITH c AS (
      SELECT s.id, s.started_at, g.libelle AS classe,
             pg_catalog.btrim(coalesce(t.first_name, '') || ' ' || coalesce(t.last_name, '')) AS enseignant,
             EXISTS (SELECT 1 FROM public.seances_fermees sf
                      WHERE sf.session_id = s.id AND sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL) AS deja_de_cote
        FROM public.sessions s
        JOIN public.groupes g ON g.id = s.groupe_id AND g.ended_at IS NULL
        LEFT JOIN public.profiles t ON t.id = s.teacher_id
       WHERE s.status IN ('planned', 'preflight')
         AND s.started_at > greatest(pg_catalog.now(), coalesce(v_ce.publie_le, pg_catalog.now()))
         AND private.jour_academie_de(s.started_at) BETWEEN v_ce.du AND v_ce.au
         AND private.fermeture_vise_classe(v_ce.portee, v_ce.cohorte, v_ce.groupe_id, g.id)
         AND (s.deleted_at IS NULL OR EXISTS (SELECT 1 FROM public.seances_fermees sf
                                                WHERE sf.session_id = s.id AND sf.fermeture_id = v_ce.id
                                                  AND sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL)))
    SELECT pg_catalog.jsonb_build_object(
             'total', (SELECT pg_catalog.count(*)::integer FROM c),
             'seances', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                'session_id', x.id, 'classe', x.classe, 'enseignant', x.enseignant,
                'jour', private.jour_academie_de(x.started_at),
                'heure', pg_catalog.to_char(x.started_at AT TIME ZONE 'Asia/Riyadh', 'HH24:MI'),
                'deja_de_cote', x.deja_de_cote) ORDER BY x.started_at)
                FROM (SELECT * FROM c ORDER BY started_at LIMIT 100) x), '[]'::jsonb)));
END;
$function$;

-- Combien d'eleves une portee vise (pour dire a la direction ce que sa saisie change).
CREATE FUNCTION private.calendrier_eleves_vises(p_portee text, p_cohorte text, p_groupe_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.count(*)::integer
    FROM public.eleve_etape_en_cours f
   WHERE p_portee = 'ecole'
      OR (p_portee = 'tranche'
          AND coalesce(f.cohorte, private.cohorte_effective(f.student_id, NULL)) = p_cohorte)
      OR (p_portee = 'classe'
          AND EXISTS (SELECT 1 FROM public.groupe_membres m
                       WHERE m.groupe_id = p_groupe_id AND m.student_id = f.student_id AND m.left_at IS NULL));
$function$;

-- La liste de la direction : tout le calendrier, publie ou non, avec ce que
-- chaque fermeture change (eleves vises, seances deja prevues ce jour-la).
CREATE FUNCTION public.calendrier_ecole_liste()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier reserve a la direction' USING errcode = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', ce.id, 'type', ce.type, 'categorie', ce.categorie, 'titre', ce.titre,
             'du', ce.du, 'au', ce.au, 'jours', ce.au - ce.du + 1,
             'portee', ce.portee, 'cohorte', ce.cohorte, 'groupe_id', ce.groupe_id,
             'groupe_libelle', g.libelle,
             'publie', ce.publie, 'publie_le', ce.publie_le,
             'eleves_vises', CASE WHEN ce.type = 'fermeture'
                                  THEN private.calendrier_eleves_vises(ce.portee, ce.cohorte, ce.groupe_id) END,
             'seances_deja_prevues', CASE WHEN ce.type = 'fermeture' THEN (
                SELECT pg_catalog.count(*)::integer
                  FROM public.sessions s
                  JOIN public.groupes sg ON sg.id = s.groupe_id AND sg.ended_at IS NULL
                 WHERE s.deleted_at IS NULL AND s.status IN ('planned', 'preflight')
                   AND s.started_at > greatest(pg_catalog.now(), coalesce(ce.publie_le, pg_catalog.now()))
                   AND private.jour_academie_de(s.started_at) BETWEEN ce.du AND ce.au
                   AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, sg.id)) END,
             'seances_neutralisees', CASE WHEN ce.type = 'fermeture' THEN (
                SELECT pg_catalog.count(*)::integer
                  FROM public.seances_fermees sf
                  JOIN public.sessions s ON s.id = sf.session_id
                  JOIN public.groupes sg ON sg.id = s.groupe_id
                 WHERE sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL
                   AND private.jour_academie_de(s.started_at) BETWEEN ce.du AND ce.au
                   AND private.fermeture_vise_classe(ce.portee, ce.cohorte, ce.groupe_id, sg.id)) END,
             'commencee', ce.du <= private.jour_academie(),
             'passee', ce.au < private.jour_academie())
           ORDER BY ce.du, ce.au, ce.titre)
      FROM public.calendrier_ecole ce
      LEFT JOIN public.groupes g ON g.id = ce.groupe_id), '[]'::jsonb);
END;
$function$;

-- LA lecture du calendrier, pour chacun : les evenements PUBLIES qui le
-- concernent, passes recents et a venir. Eleve : les siens. Tuteur : ceux de son
-- foyer (p_eleve_id pour un seul enfant). Enseignant : ceux de ses classes.
-- Direction : tous. Ni cohorte ni classe ne sont rendues a la famille.
CREATE FUNCTION public.calendrier_ecole_lecture(p_eleve_id uuid DEFAULT NULL, p_jours_passes integer DEFAULT 30)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_role public.app_role := public.app_role();
  v_eleves uuid[];
  v_cohortes text[];
  v_classes uuid[];
  v_detail boolean := false;
  v_aujourdhui date := private.jour_academie();
  v_depuis date := private.jour_academie() - greatest(0, least(coalesce(p_jours_passes, 30), 366));
  v_tous boolean := false;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
  END IF;

  IF v_role = 'admin' THEN
    v_tous := true;
    v_detail := true;
  ELSIF v_role = 'teacher' THEN
    IF p_eleve_id IS NOT NULL THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
    v_detail := true;
    SELECT coalesce(pg_catalog.array_agg(g.id), '{}') INTO v_classes
      FROM public.groupes g WHERE g.teacher_id = v_user AND g.ended_at IS NULL;
    SELECT coalesce(pg_catalog.array_agg(DISTINCT sp.cohorte), '{}') INTO v_cohortes
      FROM public.groupe_membres m
      JOIN public.student_profiles sp ON sp.profile_id = m.student_id
     WHERE m.groupe_id = ANY (v_classes) AND m.left_at IS NULL AND sp.cohorte IS NOT NULL;
  ELSIF v_role = 'student' THEN
    IF p_eleve_id IS NOT NULL AND p_eleve_id <> v_user THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
    v_eleves := ARRAY[v_user];
  ELSIF v_role = 'guardian' THEN
    SELECT coalesce(pg_catalog.array_agg(x.id), '{}') INTO v_eleves
      FROM (
        SELECT p.id FROM public.profiles p
          JOIN public.student_profiles sp ON sp.profile_id = p.id AND sp.deleted_at IS NULL
         WHERE p.role = 'student' AND p.deleted_at IS NULL
           AND p.household_id IS NOT NULL AND p.household_id = public.app_household_id()
        UNION
        SELECT sp.profile_id FROM public.student_profiles sp
         WHERE sp.profile_id = v_user AND sp.titulaire_profile_id = v_user AND sp.deleted_at IS NULL
      ) x
     WHERE p_eleve_id IS NULL OR x.id = p_eleve_id;
    IF p_eleve_id IS NOT NULL AND NOT (p_eleve_id = ANY (v_eleves)) THEN
      RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
    END IF;
  ELSE
    RAISE EXCEPTION 'calendrier refuse' USING errcode = '42501';
  END IF;

  IF v_eleves IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(DISTINCT private.cohorte_figee(e))
                    FILTER (WHERE private.cohorte_figee(e) IS NOT NULL), '{}')
      INTO v_cohortes FROM pg_catalog.unnest(v_eleves) AS e;
    SELECT coalesce(pg_catalog.array_agg(DISTINCT m.groupe_id), '{}') INTO v_classes
      FROM public.groupe_membres m
      JOIN public.groupes g ON g.id = m.groupe_id AND g.ended_at IS NULL
     WHERE m.student_id = ANY (v_eleves) AND m.left_at IS NULL;
  END IF;

  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(
             pg_catalog.jsonb_build_object(
               'id', ce.id, 'type', ce.type, 'categorie', ce.categorie, 'titre', ce.titre,
               'du', ce.du, 'au', ce.au, 'portee', ce.portee,
               'passe', ce.au < v_aujourdhui,
               'en_cours', v_aujourdhui BETWEEN ce.du AND ce.au)
             || CASE WHEN v_detail THEN pg_catalog.jsonb_build_object(
                  'cohorte', ce.cohorte, 'groupe_id', ce.groupe_id) ELSE '{}'::jsonb END
             ORDER BY ce.du, ce.au, ce.titre)
      FROM public.calendrier_ecole ce
     WHERE ce.publie AND ce.au >= v_depuis
       AND (v_tous
            OR ce.portee = 'ecole'
            OR (ce.portee = 'tranche' AND ce.cohorte = ANY (v_cohortes))
            OR (ce.portee = 'classe' AND ce.groupe_id = ANY (v_classes)))), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 9. La pause : portes, regles, gestes
-- ---------------------------------------------------------------------------
-- Qui demande pour qui : le tuteur du foyer pour un enfant ; l'eleve adulte
-- (autonome) pour lui-meme. Jamais un enfant. Exigence positive : un NULL ferme.
CREATE FUNCTION private.pause_famille_peut(p_eleve_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    p_eleve_id IS NOT NULL AND auth.uid() IS NOT NULL AND public.app_account_valid()
    AND (
      (public.app_role() = 'guardian'
       AND EXISTS (SELECT 1 FROM public.profiles p
                     JOIN public.student_profiles sp ON sp.profile_id = p.id
                    WHERE p.id = p_eleve_id AND p.role = 'student' AND p.deleted_at IS NULL
                      AND sp.deleted_at IS NULL AND sp.student_type = 'minor'
                      AND p.household_id IS NOT NULL AND p.household_id = public.app_household_id()))
      OR ((public.app_role() = 'student' OR public.app_role() = 'guardian')
          AND p_eleve_id = auth.uid()
          AND EXISTS (SELECT 1 FROM public.student_profiles sp
                       WHERE sp.profile_id = p_eleve_id AND sp.student_type = 'autonomous'
                         AND sp.deleted_at IS NULL))), false);
$function$;

-- Ce mois depasse-t-il le plafond (n mois sur m mois glissants, accord particulier
-- de la direction au-dela) ? On regarde chaque fenetre glissante qui contient ce
-- mois ; seules les pauses d'un mois acceptees comptent (une pause d'exception
-- ne compte pas : une maladie n'use pas le droit de la famille).
CREATE FUNCTION private.pause_depasse_plafond(p_eleve_id uuid, p_debut date)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fenetre integer := public.app_config_int('pause.fenetre_mois', 12);
  v_max integer := public.app_config_int('pause.max_mois_fenetre', 2);
  v_debut date;
  v_fin date;
  v_n integer;
BEGIN
  FOR k IN 0 .. v_fenetre - 1 LOOP
    v_debut := (p_debut - pg_catalog.make_interval(months => v_fenetre - 1 - k))::date;
    v_fin := (v_debut + pg_catalog.make_interval(months => v_fenetre))::date;
    SELECT pg_catalog.count(*)::integer INTO v_n
      FROM public.pauses_eleve p
     WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.statut = 'acceptee'
       AND p.debut >= v_debut AND p.debut < v_fin;
    IF v_n + 1 > v_max THEN
      RETURN true;
    END IF;
  END LOOP;
  RETURN false;
END;
$function$;

-- La demande de pause de la famille est-elle ouverte ? Faux par defaut (un seul reglage).
CREATE FUNCTION private.pause_demande_ouverte()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce((SELECT (c.value #>> '{}')::boolean FROM public.app_config c
                    WHERE c.key = 'pause.demande_famille_ouverte'), false);
$function$;

-- Le nom de la personne de la direction (copie au moment du geste).
CREATE FUNCTION private.nom_direction(p_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
    FROM public.profiles p WHERE p.id = p_id;
$function$;

-- La notification de la reponse de la direction (jamais a un mineur : le tuteur
-- est le destinataire d'un enfant ; l'adulte recoit la sienne). Un echec ne
-- bloque jamais la decision.
CREATE FUNCTION private.pause_notifier_reponse(p_pause_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.pauses_eleve%ROWTYPE;
  v_type public.student_type;
  v_foyer uuid;
  v_role public.app_role;
  v_prenom text;
  r record;
BEGIN
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id;
  IF NOT FOUND OR p.statut NOT IN ('acceptee', 'refusee') THEN
    RETURN;
  END IF;
  SELECT sp.student_type, pr.household_id, pr.role, pr.first_name
    INTO v_type, v_foyer, v_role, v_prenom
    FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
   WHERE sp.profile_id = p.student_id;
  IF v_type IS NULL THEN
    RETURN;
  END IF;
  FOR r IN
    SELECT x.id, x.destination FROM (
      SELECT pr.id, '/tuteur'::text AS destination
        FROM public.profiles pr
       WHERE v_type = 'minor' AND v_foyer IS NOT NULL AND pr.household_id = v_foyer
         AND pr.role = 'guardian' AND pr.deleted_at IS NULL
      UNION ALL
      SELECT pr.id, CASE pr.role WHEN 'guardian' THEN '/tuteur' ELSE '/eleve' END
        FROM public.profiles pr
       WHERE v_type = 'autonomous' AND pr.id = p.student_id AND pr.deleted_at IS NULL
         AND pr.role IN ('student', 'guardian')
    ) x
  LOOP
    BEGIN
      INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
      VALUES (r.id, v_foyer, 'pause_repondue',
              pg_catalog.jsonb_build_object(
                'decision', p.statut,
                'mois', pg_catalog.to_char(p.debut, 'YYYY-MM'),
                'prenom', CASE WHEN v_type = 'minor' THEN v_prenom END),
              r.destination);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'pause_repondue : notification non posee (SQLSTATE %), decision enregistree', SQLSTATE;
    END;
  END LOOP;
END;
$function$;

CREATE FUNCTION public.pause_demander(p_eleve_id uuid, p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_debut date;
  v_fin date;
  v_aujourdhui date;
  v_preavis integer := public.app_config_int('pause.preavis_jours', 7);
  v_delai integer := public.app_config_int('pause.delai_reponse_jours', 3);
  v_direction boolean;
  v_id uuid;
BEGIN
  IF NOT private.pause_famille_peut(p_eleve_id) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  IF NOT private.pause_demande_ouverte() THEN
    RAISE EXCEPTION 'pause_demande_fermee' USING errcode = '22023';
  END IF;
  IF p_mois IS NULL THEN
    RAISE EXCEPTION 'pause_mois_invalide' USING errcode = '22023';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('pause:' || p_eleve_id::text, 0));

  v_debut := pg_catalog.date_trunc('month', (p_mois)::timestamp)::date;
  v_fin := (pg_catalog.date_trunc('month', (p_mois)::timestamp) + interval '1 month - 1 day')::date;
  v_aujourdhui := private.jour_academie();
  IF v_debut - v_aujourdhui < v_preavis THEN
    RAISE EXCEPTION 'pause_preavis' USING errcode = '22023',
      detail = pg_catalog.format('%s jours avant le debut du mois', v_preavis);
  END IF;
  IF EXISTS (SELECT 1 FROM public.pauses_eleve p
              WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.debut = v_debut
                AND p.statut IN ('demandee', 'acceptee')) THEN
    RAISE EXCEPTION 'pause_deja_demandee' USING errcode = '23505';
  END IF;

  v_direction := private.pause_depasse_plafond(p_eleve_id, v_debut);
  INSERT INTO public.pauses_eleve
    (student_id, type, debut, fin, statut, acceptation, demandee_par, repondre_avant)
  VALUES
    (p_eleve_id, 'mois', v_debut, v_fin,
     CASE WHEN v_direction THEN 'demandee' ELSE 'acceptee' END,
     CASE WHEN v_direction THEN NULL ELSE 'automatique' END,
     v_user,
     CASE WHEN v_direction THEN v_aujourdhui + v_delai END)
  RETURNING id INTO v_id;

  RETURN pg_catalog.jsonb_build_object(
    'id', v_id, 'statut', CASE WHEN v_direction THEN 'demandee' ELSE 'acceptee' END,
    'debut', v_debut, 'fin', v_fin,
    'repondre_avant', CASE WHEN v_direction THEN v_aujourdhui + v_delai END);
END;
$function$;

CREATE FUNCTION public.pause_annuler(p_pause_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  p public.pauses_eleve%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id FOR UPDATE;
  IF NOT FOUND
     OR NOT (private.pause_famille_peut(p.student_id)
             OR coalesce(public.app_role() = 'admin', false)) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  IF p.statut NOT IN ('demandee', 'acceptee') OR p.debut <= private.jour_academie() THEN
    RAISE EXCEPTION 'pause_non_annulable' USING errcode = '22023';
  END IF;
  UPDATE public.pauses_eleve SET statut = 'annulee' WHERE id = p.id;
END;
$function$;

CREATE FUNCTION public.pause_decider(p_pause_id uuid, p_accepter boolean, p_motif text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  p public.pauses_eleve%ROWTYPE;
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING errcode = '42501';
  END IF;
  IF p_accepter IS NULL THEN
    RAISE EXCEPTION 'pause_decision_invalide' USING errcode = '22023';
  END IF;
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pause_introuvable' USING errcode = '22023';
  END IF;
  IF p.statut <> 'demandee' THEN
    RAISE EXCEPTION 'pause_deja_decidee' USING errcode = '22023';
  END IF;
  IF NOT p_accepter AND pg_catalog.length(v_motif) < 3 THEN
    RAISE EXCEPTION 'pause_motif_requis' USING errcode = '22023';
  END IF;
  IF p_accepter AND p.debut < private.jour_academie() THEN
    -- Le mois a commence sans reponse : l'eleve est reste inscrit, la pause n'est plus acceptable.
    RAISE EXCEPTION 'pause_debut_passe' USING errcode = '22023';
  END IF;
  UPDATE public.pauses_eleve
     SET statut = CASE WHEN p_accepter THEN 'acceptee' ELSE 'refusee' END,
         acceptation = CASE WHEN p_accepter THEN 'direction' END,
         motif_decision = CASE WHEN v_motif = '' THEN NULL ELSE v_motif END,
         decidee_par = v_user, decidee_par_nom = private.nom_direction(v_user),
         decidee_le = pg_catalog.now()
   WHERE id = p.id;
  PERFORM private.pause_notifier_reponse(p.id);
END;
$function$;

CREATE FUNCTION public.pause_exception_accorder(p_eleve_id uuid, p_debut date, p_fin date, p_motif text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_motif text := pg_catalog.btrim(coalesce(p_motif, ''));
  v_debut date;
  v_id uuid;
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING errcode = '42501';
  END IF;
  IF p_eleve_id IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.student_profiles sp JOIN public.profiles pr ON pr.id = sp.profile_id
        WHERE sp.profile_id = p_eleve_id AND sp.deleted_at IS NULL AND pr.deleted_at IS NULL) THEN
    RAISE EXCEPTION 'pause_eleve_introuvable' USING errcode = '22023';
  END IF;
  IF pg_catalog.length(v_motif) < 3 THEN
    RAISE EXCEPTION 'pause_motif_requis' USING errcode = '22023';
  END IF;
  v_debut := coalesce(p_debut, private.jour_academie());
  IF p_fin IS NULL OR p_fin < v_debut OR p_fin - v_debut > 365 THEN
    RAISE EXCEPTION 'pause_dates_invalides' USING errcode = '22023';
  END IF;
  -- Une exception a une duree au plus (reglage, 3 mois) ; au-dela, un nouveau geste.
  IF p_fin > (v_debut + pg_catalog.make_interval(months => public.app_config_int('pause.exception_mois_max', 3)))::date THEN
    RAISE EXCEPTION 'pause_exception_trop_longue' USING errcode = '22023';
  END IF;
  -- Sans preavis, mais jamais dans le passe : les absences deja survenues restent des absences.
  IF v_debut < private.jour_academie() THEN
    RAISE EXCEPTION 'pause_debut_passe' USING errcode = '22023';
  END IF;
  INSERT INTO public.pauses_eleve
    (student_id, type, debut, fin, statut, acceptation, motif, demandee_par,
     decidee_par, decidee_par_nom, decidee_le)
  VALUES
    (p_eleve_id, 'exception', v_debut, p_fin, 'acceptee', 'direction', v_motif, v_user,
     v_user, private.nom_direction(v_user), pg_catalog.now())
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$function$;

-- « Terminer la pause d'exception a telle date » : la direction raccourcit une pause
-- d'exception accordee (l'eleve revient plus tot). Jamais dans le passe ; la fin d'origine
-- et le geste sont gardes. Les jours deja ecoules restent comptes dans le recul.
CREATE FUNCTION public.pause_exception_terminer(p_pause_id uuid, p_fin date)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  p public.pauses_eleve%ROWTYPE;
  v_jour date := private.jour_academie();
BEGIN
  IF NOT coalesce(v_user IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'decision reservee a la direction' USING errcode = '42501';
  END IF;
  SELECT * INTO p FROM public.pauses_eleve WHERE id = p_pause_id FOR UPDATE;
  IF NOT FOUND OR p.type <> 'exception' THEN
    RAISE EXCEPTION 'pause_introuvable' USING errcode = '22023';
  END IF;
  IF p.statut <> 'acceptee' OR p.fin < v_jour THEN
    RAISE EXCEPTION 'pause_non_terminable' USING errcode = '22023';
  END IF;
  IF p_fin IS NULL OR p_fin < v_jour OR p_fin < p.debut OR p_fin >= p.fin THEN
    RAISE EXCEPTION 'pause_dates_invalides' USING errcode = '22023';
  END IF;
  UPDATE public.pauses_eleve
     SET fin_initiale = coalesce(fin_initiale, fin), fin = p_fin,
         terminee_par = v_user, terminee_par_nom = private.nom_direction(v_user),
         terminee_le = pg_catalog.now()
   WHERE id = p.id;
END;
$function$;

-- LA lecture des pauses d'un eleve (famille, direction) : la regle, les mois
-- proposes, les pauses et leur etat.
CREATE FUNCTION public.pauses_eleve_lecture(p_eleve_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin boolean := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  v_aujourdhui date;
  v_preavis integer := public.app_config_int('pause.preavis_jours', 7);
  v_premier date;
BEGIN
  IF NOT (v_admin OR private.pause_famille_peut(p_eleve_id)) THEN
    RAISE EXCEPTION 'pause refusee' USING errcode = '42501';
  END IF;
  v_aujourdhui := private.jour_academie();
  v_premier := (pg_catalog.date_trunc('month', (v_aujourdhui + v_preavis)::timestamp)::date);
  IF v_premier < v_aujourdhui + v_preavis THEN
    v_premier := (v_premier + interval '1 month')::date;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'eleve_id', p_eleve_id,
    'demande_ouverte', private.pause_demande_ouverte(),
    'prenom', (SELECT pr.first_name FROM public.profiles pr WHERE pr.id = p_eleve_id),
    'aujourdhui', v_aujourdhui,
    'regle', pg_catalog.jsonb_build_object(
      'preavis_jours', v_preavis,
      'plafond_mois', public.app_config_int('pause.max_mois_fenetre', 2),
      'fenetre_mois', public.app_config_int('pause.fenetre_mois', 12),
      'delai_reponse_jours', public.app_config_int('pause.delai_reponse_jours', 3),
      'exception_mois_max', public.app_config_int('pause.exception_mois_max', 3)),
    'mois_accordes', (
      SELECT pg_catalog.count(*)::integer FROM public.pauses_eleve p
       WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.statut = 'acceptee'
         AND p.debut >= (pg_catalog.date_trunc('month', (v_aujourdhui)::timestamp)
                         - pg_catalog.make_interval(months => public.app_config_int('pause.fenetre_mois', 12) - 1))::date),
    'mois_proposes', CASE WHEN NOT private.pause_demande_ouverte() THEN '[]'::jsonb ELSE (
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'mois', m.debut,
               'a_la_direction', private.pause_depasse_plafond(p_eleve_id, m.debut),
               'etat', (SELECT p.statut FROM public.pauses_eleve p
                         WHERE p.student_id = p_eleve_id AND p.type = 'mois' AND p.debut = m.debut
                           AND p.statut IN ('demandee', 'acceptee')))
             ORDER BY m.debut)
        FROM (SELECT (v_premier + pg_catalog.make_interval(months => k))::date AS debut
                FROM pg_catalog.generate_series(0, 11) k) m) END,
    'pauses', coalesce((
      SELECT pg_catalog.jsonb_agg(
               pg_catalog.jsonb_build_object(
                 'id', p.id, 'type', p.type, 'debut', p.debut, 'fin', p.fin, 'statut', p.statut,
                 'demandee_le', p.demandee_le, 'repondre_avant', p.repondre_avant,
                 'decidee_le', p.decidee_le, 'motif_decision', p.motif_decision,
                 'annulable', p.statut IN ('demandee', 'acceptee') AND p.debut > v_aujourdhui)
               || CASE WHEN v_admin THEN pg_catalog.jsonb_build_object(
                    'motif', p.motif, 'decidee_par_nom', p.decidee_par_nom,
                    'acceptation', p.acceptation, 'fin_initiale', p.fin_initiale,
                    'terminee_par_nom', p.terminee_par_nom,
                    'terminable', p.type = 'exception' AND p.statut = 'acceptee' AND p.fin >= v_aujourdhui)
                  ELSE '{}'::jsonb END
               ORDER BY p.debut DESC, p.demandee_le DESC)
        FROM (SELECT * FROM public.pauses_eleve x WHERE x.student_id = p_eleve_id
               ORDER BY x.debut DESC, x.demandee_le DESC LIMIT 24) p), '[]'::jsonb));
END;
$function$;

-- La file de la direction : les demandes a traiter (au-dela du plafond) et les
-- decisions recentes (pauses d'exception comprises).
CREATE FUNCTION public.pauses_a_traiter()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pauses reservees a la direction' USING errcode = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'regle', pg_catalog.jsonb_build_object(
      'exception_mois_max', public.app_config_int('pause.exception_mois_max', 3)),
    'a_traiter', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', p.id, 'eleve_id', p.student_id,
               'eleve_nom', pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')),
               'cohorte', sp.cohorte, 'debut', p.debut, 'fin', p.fin,
               'demandee_le', p.demandee_le, 'repondre_avant', p.repondre_avant,
               'en_retard', p.repondre_avant < private.jour_academie(),
               'mois_accordes', (
                 SELECT pg_catalog.count(*)::integer FROM public.pauses_eleve a
                  WHERE a.student_id = p.student_id AND a.type = 'mois' AND a.statut = 'acceptee'
                    AND a.debut >= (pg_catalog.date_trunc('month', (p.debut)::timestamp)
                                    - pg_catalog.make_interval(months => public.app_config_int('pause.fenetre_mois', 12) - 1))::date
                    AND a.debut < p.debut + interval '12 months'))
             ORDER BY p.repondre_avant, p.demandee_le)
        FROM public.pauses_eleve p
        JOIN public.profiles pr ON pr.id = p.student_id
        LEFT JOIN public.student_profiles sp ON sp.profile_id = p.student_id
       WHERE p.statut = 'demandee'), '[]'::jsonb),
    'recentes', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', r.id, 'eleve_id', r.student_id, 'eleve_nom', r.nom, 'type', r.type,
               'debut', r.debut, 'fin', r.fin, 'statut', r.statut, 'motif', r.motif,
               'motif_decision', r.motif_decision, 'decidee_par_nom', r.decidee_par_nom,
               'decidee_le', r.decidee_le, 'fin_initiale', r.fin_initiale,
               'terminee_par_nom', r.terminee_par_nom,
               'terminable', r.type = 'exception' AND r.statut = 'acceptee' AND r.fin >= private.jour_academie())
               ORDER BY r.decidee_le DESC)
        FROM (SELECT p.*, pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')) AS nom
                FROM public.pauses_eleve p JOIN public.profiles pr ON pr.id = p.student_id
               WHERE p.decidee_le IS NOT NULL
               ORDER BY p.decidee_le DESC LIMIT 20) r), '[]'::jsonb));
END;
$function$;

-- Choisir un eleve pour une pause d'exception : recherche par nom, 20 au plus.
CREATE FUNCTION public.pauses_eleves_recherche(p_q text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_q text := pg_catalog.btrim(coalesce(p_q, ''));
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'pauses reservees a la direction' USING errcode = '42501';
  END IF;
  IF pg_catalog.length(v_q) < 2 THEN
    RETURN '[]'::jsonb;
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', x.id, 'nom', x.nom, 'cohorte', x.cohorte, 'matricule', x.immutable_id) ORDER BY x.nom)
      FROM (SELECT pr.id, pr.immutable_id, sp.cohorte,
                   pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')) AS nom
              FROM public.profiles pr
              JOIN public.student_profiles sp ON sp.profile_id = pr.id AND sp.deleted_at IS NULL
             WHERE pr.deleted_at IS NULL
               AND (pr.first_name || ' ' || pr.last_name) ILIKE '%' || pg_catalog.replace(
                     pg_catalog.replace(pg_catalog.replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%'
             ORDER BY pr.first_name, pr.last_name LIMIT 20) x), '[]'::jsonb);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 10. La reponse a une demande de pause n'est ni un courriel ni un push (lot 7)
-- ---------------------------------------------------------------------------
INSERT INTO private.notification_courriel (evenement, portee, courriel, push)
VALUES ('pause_repondue', '*', false, false),
       ('fermeture_annoncee', '*', false, false),
       ('fermeture_levee', '*', false, false),
       ('fermeture_conflit', '*', false, false)
ON CONFLICT (evenement, portee) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 11. Droits (deux chemins : PUBLIC et anon)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION private.calendrier_reglages_valider() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_ecole_valider() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_vise_classe(text, text, uuid, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.jour_ferme_pour_classe(date, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_en_pause(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_en_pause_mois(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.recul_jours_calcule(uuid, date, uuid, text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_etape_recul_deriver() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.recul_recalculer_cible(text, text, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_ecole_recalculer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pauses_eleve_recalculer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.calendrier_eleves_vises(text, text, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_famille_peut(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.jour_academie() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_demande_ouverte() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.seance_jour_ferme_garde() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.cohorte_figee(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.session_en_fermeture(timestamptz, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.debut_ferme(timestamptz, uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.jour_academie_de(timestamptz) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_en_fermeture(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.eleve_hors_cours(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_synchroniser(boolean) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_balayer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_signaler_conflit(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.fermeture_notifier(uuid, uuid, text, uuid[], uuid[]) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.groupe_membres_recalculer() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_depasse_plafond(uuid, date) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.nom_direction(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.pause_notifier_reponse(uuid) FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.calendrier_ecole_enregistrer(uuid, text, text, text, date, date, text, text, uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_publier(uuid, boolean) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_retirer(uuid, integer) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_retrait_conflits(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_seances_concernees(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_liste() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.calendrier_ecole_lecture(uuid, integer) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_demander(uuid, date) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_annuler(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_decider(uuid, boolean, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_exception_accorder(uuid, date, date, text) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pause_exception_terminer(uuid, date) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_eleve_lecture(uuid) FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_a_traiter() FROM PUBLIC, anon, service_role;
REVOKE ALL ON FUNCTION public.pauses_eleves_recherche(text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_enregistrer(uuid, text, text, text, date, date, text, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_publier(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_retirer(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_retrait_conflits(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_seances_concernees(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_liste() TO authenticated;
GRANT EXECUTE ON FUNCTION public.calendrier_ecole_lecture(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_demander(uuid, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_annuler(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_decider(uuid, boolean, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_exception_accorder(uuid, date, date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_exception_terminer(uuid, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_eleve_lecture(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_a_traiter() TO authenticated;
GRANT EXECUTE ON FUNCTION public.pauses_eleves_recherche(text) TO authenticated;

DO $agent$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.calendrier_ecole FROM agent_ro';
    EXECUTE 'REVOKE ALL ON public.pauses_eleve FROM agent_ro';
    EXECUTE 'REVOKE ALL ON public.seances_fermees FROM agent_ro';
  END IF;
END
$agent$;

-- ---------------------------------------------------------------------------
-- 12. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.calendrier_ecole'::pg_catalog.regclass)
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.pauses_eleve'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : RLS absente sur une table neuve';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.calendrier_ecole', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.calendrier_ecole', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.pauses_eleve', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.pauses_eleve', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.calendrier_ecole', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.pauses_eleve', 'SELECT') THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : ecriture ou lecture directe ouverte sur une table neuve';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.pause_demander(uuid, date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.calendrier_ecole_lecture(uuid, integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.pause_decider(uuid, boolean, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.pause_exception_terminer(uuid, date)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.jour_academie()', 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.seances_fermees', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated', 'private.recul_jours_calcule(uuid, date, uuid, text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.eleve_en_pause(uuid, date)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.pause_demander(uuid, date)', 'EXECUTE') THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : droits des fonctions incorrects';
  END IF;
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.materialiser_seances_groupe(uuid)'::pg_catalog.regprocedure),
       'private.debut_ferme') = 0
     OR pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.seance_a_rejoindre(uuid)'::pg_catalog.regprocedure),
       'private.debut_ferme') = 0
     OR pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.etape_eleve_lecture(uuid)'::pg_catalog.regprocedure),
       '''recul_jours''') = 0 THEN
    RAISE EXCEPTION 'CALENDRIER-ET-PAUSES : un remplacement n''est pas passe';
  END IF;
END
$postflight$;
