-- CLASSES-DUREE, suite (23/10/2026) : CONTROLE EN LECTURE SEULE, a lancer AVANT la
-- migration 20261023000000_classes_duree_bout_en_bout.sql, dans l'editeur SQL.
-- Il ecrit RIEN. Il dit si la migration va S'ARRETER :
--   * aucune ligne rendue : aucun rallongement ne chevauche une autre seance, la
--     migration passera (a la ligne de l'alignement) ;
--   * une ligne par chevauchement : la seance a rallonger (id, Classe, debut en UTC,
--     enseignant), l'autre seance qui la gene, et pourquoi (meme enseignant,
--     enseignant effectif, eleve commun). Deplacer ou annuler l'une des deux, puis
--     relancer ce controle jusqu'a ce qu'il ne rende plus rien.
-- Il refait la meme recherche que app_private.aligner_seances_a_venir_sur_la_classe
-- (la migration ne s'arrete que dans ces cas). Il suppose la migration
-- 20261022000400 appliquee (app_private.duree_seance_minutes).
WITH r AS MATERIALIZED (
  SELECT s.id AS seance_id, g.id AS classe_id, s.teacher_id AS enseignant_id,
         s.started_at AS debut, s.ended_at AS fin_actuelle,
         s.started_at + make_interval(mins => app_private.duree_seance_minutes(g.offre_id, g.type_public)) AS fin_nouvelle
    FROM public.sessions s
    JOIN public.groupes g ON g.id = s.groupe_id
   WHERE s.deleted_at IS NULL AND s.status = 'planned' AND s.started_at > now()
     AND g.ended_at IS NULL
     AND s.ended_at <> s.started_at + make_interval(mins => app_private.duree_seance_minutes(g.offre_id, g.type_public))
)
SELECT c.seance_id AS seance_a_rallonger, c.classe_id, c.debut AT TIME ZONE 'UTC' AS debut_utc,
       c.enseignant_id, o.id AS autre_seance,
       CASE WHEN o.teacher_id = c.enseignant_id THEN 'meme enseignant'
            WHEN private.c29_enseignant_effectif_session(o.id) = private.c29_enseignant_effectif_session(c.seance_id) THEN 'enseignant effectif (remplacant)'
            ELSE 'eleve commun' END AS pourquoi
  FROM r c
  JOIN public.sessions o
    ON o.id <> c.seance_id AND o.deleted_at IS NULL
   AND o.status IN ('planned', 'preflight', 'in_progress')
   AND o.started_at < c.fin_nouvelle
  LEFT JOIN r ro ON ro.seance_id = o.id
 WHERE c.fin_nouvelle > c.fin_actuelle
   AND coalesce(ro.fin_nouvelle, o.ended_at) > c.debut
   AND tstzrange(o.started_at, coalesce(ro.fin_nouvelle, o.ended_at), '[)') && tstzrange(c.debut, c.fin_nouvelle, '[)')
   AND (o.teacher_id = c.enseignant_id
        OR private.c29_enseignant_effectif_session(o.id) = private.c29_enseignant_effectif_session(c.seance_id)
        OR EXISTS (SELECT 1 FROM public.session_participants a
                     JOIN public.session_participants b ON b.profile_id = a.profile_id
                    WHERE a.session_id = c.seance_id AND b.session_id = o.id
                      AND a.deleted_at IS NULL AND b.deleted_at IS NULL
                      AND a.role IN ('teacher', 'student') AND b.role IN ('teacher', 'student')))
 ORDER BY c.debut, c.seance_id, o.id;
