-- AUDIT-FAMILLE-4 (directeur, 22/11/2026) : « Me prevenir si de nouveaux horaires ouvrent » (R22, R32, L10).
--
-- LE PROBLEME : la carte d'offre propose ce bouton. Il ecrit une ligne matching_requests (kind
-- horaire_insatisfait : la langue et la cohorte de l'eleve dans rule_value) que RIEN ne lisait : la publication
-- d'une offre n'envoyait aucun avis. La promesse n'etait pas tenue.
--
-- CE QUE FAIT CE FICHIER : un declencheur sur offres_horaires. Quand une offre devient « publiee » (a l'insertion
-- ou en passant de brouillon a publiee), chaque demande en attente COMPATIBLE recoit UN avis, une seule fois :
--   * compatible = meme langue de cours (rule_value.langue = offre.langue_code) et meme public (la cohorte de la
--     demande est du type enfant ou adulte de l'offre) ; une demande sans langue ni cohorte lisible n'est jamais
--     reveillee (trop vague) ;
--   * seules les offres de l'administration reveillent (une offre nee du quota d'une famille reste a elle) ;
--   * l'avis = une notification au demandeur (evenement existant « annonce_direction », titre et debut dans la
--     langue de son compte : fr, en ou ar, sinon fr ; aucun nouvel evenement, donc aucune contrainte reecrite) ET un
--     courriel (categorie inscription, modele horaire_ouvert, ecrit en fr, en, ar) ;
--   * une seule fois par demande : la notification porte params.demande ; le courriel a la cle
--     horaire_ouvert:<demande>. La demande elle-meme n'est pas modifiee (la direction la decide ou non).
-- Une erreur de l'avis ne bloque JAMAIS la publication de l'offre (avertissement seulement).
--
-- MOTS D'EFFACEMENT : ZERO. Additif : une fonction privee neuve, un declencheur neuf. Aucune donnee ecrite a
-- l'installation. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.offres_horaires') IS NULL
     OR pg_catalog.to_regclass('public.matching_requests') IS NULL
     OR pg_catalog.to_regclass('public.cohortes_age') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-4 : offres_horaires, matching_requests, cohortes_age ou courriel_enfiler manque';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION private.offre_publiee_prevenir_familles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  r record;
  v_langue text;
  v_titre text;
  v_extrait text;
BEGIN
  IF NEW.etat IS DISTINCT FROM 'publiee' OR NEW.origine IS DISTINCT FROM 'administration' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.etat IS NOT DISTINCT FROM 'publiee' THEN
    RETURN NEW;
  END IF;
  FOR r IN
    SELECT mr.id, mr.requested_by, pr.household_id,
           CASE pr.langue_communication WHEN 'en' THEN 'en' WHEN 'ar' THEN 'ar' ELSE 'fr' END AS langue
      FROM public.matching_requests mr
      JOIN public.profiles pr ON pr.id = mr.requested_by
      LEFT JOIN public.cohortes_age ca ON ca.code = mr.rule_value ->> 'cohorte'
     WHERE mr.kind = 'horaire_insatisfait'
       AND mr.status = 'pending'
       AND pr.deleted_at IS NULL
       AND pr.account_status::text IN ('active', 'provisional_active')
       AND (mr.rule_value ->> 'langue' IS NOT NULL OR mr.rule_value ->> 'cohorte' IS NOT NULL)
       AND (mr.rule_value ->> 'langue' IS NULL OR mr.rule_value ->> 'langue' = NEW.langue_code)
       AND (mr.rule_value ->> 'cohorte' IS NULL OR ca.type_public = NEW.type_public)
       AND NOT EXISTS (SELECT 1 FROM public.notifications n
                        WHERE n.evenement = 'annonce_direction'
                          AND n.params ->> 'demande' = mr.id::text)
  LOOP
    BEGIN
      v_langue := r.langue;
      v_titre := CASE v_langue
        WHEN 'en' THEN 'A time has opened'
        WHEN 'ar' THEN 'فُتح موعد جديد'
        ELSE 'Un horaire s’est ouvert' END;
      v_extrait := CASE v_langue
        WHEN 'en' THEN 'A time matching your request is now open. Choose it in the app.'
        WHEN 'ar' THEN 'أصبح متاحًا موعد يناسب طلبك. اختره في التطبيق.'
        ELSE 'Un horaire correspondant à votre demande est ouvert. Choisissez-le dans l’application.' END;
      INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
      VALUES (r.requested_by, r.household_id, 'annonce_direction',
              pg_catalog.jsonb_build_object('titre', v_titre, 'extrait', v_extrait, 'demande', r.id::text),
              '/tuteur');
      PERFORM public.courriel_enfiler(
        'inscription', 'horaire_ouvert', public.courriel_adresse_profil(r.requested_by), r.requested_by,
        pg_catalog.jsonb_build_object('demande', r.id::text),
        'horaire_ouvert:' || r.id::text, 'auto', NULL);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'AUDIT-FAMILLE-4 : avis non pose pour une demande (%)', SQLSTATE;
    END;
  END LOOP;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'AUDIT-FAMILLE-4 : avis des familles non poses (%)', SQLSTATE;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.offre_publiee_prevenir_familles() FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.offre_publiee_prevenir_familles() FROM agent_ro';
  END IF;
END
$agent_ro$;
COMMENT ON FUNCTION private.offre_publiee_prevenir_familles() IS
  'AUDIT-FAMILLE-4 (22/11/2026) : a la publication d''une offre, un avis (notification et courriel horaire_ouvert), une seule fois, aux demandes « Me prevenir » compatibles (langue et public). Ne bloque jamais la publication.';

CREATE OR REPLACE TRIGGER offres_horaires_prevenir_familles
  AFTER INSERT OR UPDATE OF etat ON public.offres_horaires
  FOR EACH ROW EXECUTE FUNCTION private.offre_publiee_prevenir_familles();

DO $postflight$
BEGIN
  IF pg_catalog.has_function_privilege('authenticated', 'private.offre_publiee_prevenir_familles()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.offre_publiee_prevenir_familles()', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-4 : la fonction du declencheur est executable par un client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.offres_horaires'::pg_catalog.regclass
                    AND t.tgname = 'offres_horaires_prevenir_familles' AND NOT t.tgisinternal) THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-4 : declencheur absent';
  END IF;
END
$postflight$;
