BEGIN;

ALTER TABLE public.notifications
  DROP CONSTRAINT notifications_evenement_check;
ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (
    'demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
    'remplacement_propose', 'remplacement_pris', 'demande_presentation',
    'controle_mission_attribuee', 'controle_mission_non_controlee'
  ));

COMMIT;
