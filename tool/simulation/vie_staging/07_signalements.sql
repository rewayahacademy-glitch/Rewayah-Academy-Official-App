-- Signalements déposés par les enseignants, transmis ou non à la famille.
insert into public.student_concern (categorie, groupe_id, student_id, teacher_id, internal_details, family_summary, statut, cree_le, transmis_le, transmis_a)
select x.categorie::public.concern_category, x.groupe::uuid, x.eleve::uuid, x.enseignant::uuid, x.interne, x.famille,
  (case when x.famille is null then 'ouvert' else 'transmis' end)::public.concern_status, (x.jour || 'T19:30:00Z')::timestamptz,
  case when x.famille is not null then (x.jour || 'T21:00:00Z')::timestamptz end,
  (case when x.famille is not null then case x.type when 'enfant' then 'tuteur_du_mineur' else 'eleve_adulte' end end)::public.concern_target
from (values
  ('presence', 'e5500000-0000-4000-8000-000000000012', 'e5100000-0000-4000-8000-000000000013', 'e5200000-0000-4000-8000-000000000006', 'Absent a plusieurs seances ces dernieres semaines.', null::text, '2026-09-15', 'enfant'),
  ('presence', 'e5500000-0000-4000-8000-000000000017', 'e5100000-0000-4000-8000-000000000014', 'e5200000-0000-4000-8000-000000000009', 'Absent a plusieurs seances ces dernieres semaines.', 'Nous avons remarque plusieurs absences. Tout va bien ?', '2026-09-18', 'enfant'),
  ('presence', 'e5500000-0000-4000-8000-000000000017', 'e5100000-0000-4000-8000-000000000015', 'e5200000-0000-4000-8000-000000000009', 'Absent a plusieurs seances ces dernieres semaines.', null::text, '2026-09-21', 'enfant'),
  ('presence', 'e5500000-0000-4000-8000-000000000018', 'e5100000-0000-4000-8000-000000000017', 'e5200000-0000-4000-8000-000000000009', 'Absent a plusieurs seances ces dernieres semaines.', 'Nous avons remarque plusieurs absences. Tout va bien ?', '2026-09-24', 'enfant'),
  ('presence', 'e5500000-0000-4000-8000-000000000014', 'e5100000-0000-4000-8000-000000000018', 'e5200000-0000-4000-8000-000000000007', 'Absent a plusieurs seances ces dernieres semaines.', null::text, '2026-09-27', 'enfant'),
  ('changement', 'e5500000-0000-4000-8000-000000000018', 'e5100000-0000-4000-8000-000000000024', 'e5200000-0000-4000-8000-000000000009', 'Se plaint du creneau et demande une autre classe.', null::text, '2026-10-02', 'enfant'),
  ('changement', 'e5500000-0000-4000-8000-000000000020', 'e5100000-0000-4000-8000-000000000042', 'e5200000-0000-4000-8000-000000000010', 'Se plaint du creneau et demande une autre classe.', null::text, '2026-10-04', 'enfant'),
  ('changement', 'e5500000-0000-4000-8000-000000000007', 'e5100000-0000-4000-8000-000000000057', 'e5200000-0000-4000-8000-000000000004', 'Se plaint du creneau et demande une autre classe.', null::text, '2026-10-06', 'adulte')
) x(categorie, groupe, eleve, enseignant, interne, famille, jour, type);
-- Demandes d’un autre créneau, encore sans réponse.
insert into public.demandes_horaires_famille (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, etat, created_at, updated_at)
select d.eleve::uuid, 'adulte', 'francais', 'Europe/Paris', d.jours::smallint[], d.heures::smallint[], 'personnalisee', 'envoyee', d.jour::timestamptz, d.jour::timestamptz
from (values
  ('e5100000-0000-4000-8000-000000000046', '{6,7}', '{10,10}', '2026-10-10T09:00:00Z'),
  ('e5100000-0000-4000-8000-000000000047', '{1,3,5}', '{20,20,20}', '2026-10-11T09:00:00Z'),
  ('e5100000-0000-4000-8000-000000000051', '{2,4}', '{19,19}', '2026-10-12T09:00:00Z')
) d(eleve, jours, heures, jour);
