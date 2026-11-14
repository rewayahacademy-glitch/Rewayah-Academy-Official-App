-- INVITATION-CODE-ACCUEIL (14/11/2026) : une personne connectee SANS profil qui a
-- une invitation d'enseignant en attente pour SON adresse est menee a
-- l'inscription avec le code retrouve par le serveur, quel que soit son chemin
-- de connexion (lien du courriel, Google, « Retrouver mon acces »). Avant, le
-- code ne vivait que dans la memoire de l'appareil, posee par le lien du
-- courriel : un autre chemin laissait la personne devant un ecran de code vide.
--
-- `mon_invitation_accueil` rend deja le role de l'invitation de la session
-- (adresse confirmee, aucun profil). Elle rend maintenant aussi `code` pour le
-- role `enseignant` : le code de SA propre invitation, jamais celui d'une autre
-- adresse (la fonction ne lit que l'adresse de la session, auth.uid()).
-- Reecriture PAR ANCRE (pg_get_functiondef + replace, un seul remplacement
-- exige, rejouable).
DO $migration$
DECLARE
  v_sig    constant text := 'public.mon_invitation_accueil()';
  v_ancre  constant text := '''invite'', ''role'', ''enseignant'');';
  v_neuf   constant text := '''invite'', ''role'', ''enseignant'', ''code'', ('
    || 'SELECT i2.code FROM public.invitations_enseignant i2'
    || ' WHERE i2.email = v_email AND i2.revoquee_le IS NULL AND i2.utilisee_le IS NULL'
    || ' AND i2.expire_le > pg_catalog.now() ORDER BY i2.cree_le DESC LIMIT 1));';
  v_def    text;
  v_n      integer;
BEGIN
  v_def := pg_catalog.pg_get_functiondef(pg_catalog.to_regprocedure(v_sig));
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, ''))) / pg_catalog.length(v_ancre);
  IF v_n = 1 THEN
    EXECUTE pg_catalog.replace(v_def, v_ancre, v_neuf);
  ELSIF v_n = 0 AND pg_catalog.strpos(v_def, 'i2.code') > 0 THEN
    RAISE NOTICE 'invitation_code_accueil : % deja corrigee', v_sig;
  ELSE
    RAISE EXCEPTION 'invitation_code_accueil : % ancre(s) trouvee(s) dans % (1 attendue)', v_n, v_sig;
  END IF;
END
$migration$;
