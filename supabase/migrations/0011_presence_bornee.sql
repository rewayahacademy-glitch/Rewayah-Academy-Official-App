-- 0011 : N4, l'affichage de la presence. Ce que la vue derivee doit porter
-- pour qu'un ecran puisse la lire, et ce qu'elle doit refuser de montrer.
--
-- Perimetre fixe par docs/archive/2026-09-pre-remise-a-plat/architecture/etape-5-salle-coran-presence.md
-- sections 6.5 et 6.6, et par les invariants J3 et J7 de sa section 8.
--
-- Le calcul, lui, ne bouge pas. `etat_presence()` derive les quatorze etats
-- depuis 0007, et son quatorzieme -- `en_connexion` -- depuis 0010. Ce fichier
-- ne touche a aucune de ses branches : il ne change QUE la vue par laquelle un
-- ecran lit le resultat.
--
-- Trois choses changent, et la premiere est un defaut :
--
--   1. **`presence_seance_v` n'avait aucun filtre d'appelant.** Les trois vues
--      d'exposition de 0001 -- `session_peers_v`, `teacher_roster_v`,
--      `family_sessions_v` -- portent toutes un `where ... = auth.uid()` dans
--      leur corps, et ce n'est pas une precaution decorative : une vue
--      appartenant a `postgres` sans `security_invoker` s'execute avec les
--      droits de son proprietaire, donc **sans voir la RLS des tables qu'elle
--      lit**. `presence_seance_v` etait `grant select ... to authenticated`
--      sans aucune borne : tout compte authentifie y aurait lu la presence de
--      toutes les seances de la plateforme, celles d'enfants mineurs comprises.
--      Rien n'a fuite -- il n'existe aucune seance en base au 13 septembre 2026
--      -- et le defaut n'avait jamais ete exerce parce qu'aucun ecran ne lisait
--      la vue. C'est la lecon de N3 une seconde fois : **une vue sans ecran est
--      une vue non testee.**
--
--   2. **La vue porte desormais un prenom, pas seulement un `profile_id`.**
--      Un tableau de presence qui afficherait des UUID ne serait pas un tableau
--      de presence. Prenom et identifiant immuable, jamais de nom de famille
--      (ADR-008), exactement comme `session_peers_v` et `teacher_roster_v`.
--
--   3. **L'invisibilite du controleur s'arretait a la video.** L'ADR-011 veut
--      qu'une visite de controle ne soit perceptible ni par l'enseignant ni par
--      l'eleve : le jeton porte `hidden`, LiveKit masque la personne, et N3 la
--      retire meme de sa propre liste de participants pour que son ecran montre
--      exactement ce que montre celui de l'enseignant. Mais la presence, elle,
--      l'exposait : un enseignant lisant sa seance y aurait trouve une
--      quatrieme ligne, « masked_controller, presente », c'est-a-dire la
--      visite en toutes lettres. Un `masked_controller` n'est donc visible dans
--      cette vue que par l'administration -- pas meme par lui-meme, exactement
--      comme dans la liste de N3. La trace d'une observation se lit dans
--      `audit_logs`, ou l'ADR-011 l'ecrit deja, et pas ailleurs.
--
--   4. **La vue dit si un etat est consolide, jamais pourquoi.** La section 6.6
--      demande que l'enseignant distingue « ce qui est provisoire de ce qui est
--      finalise » ; la meme section interdit a l'eleve tout detail
--      administratif. `session_presence_override` porte un motif et un
--      decideur : ni l'un ni l'autre ne traverse cette vue. Un etat y est
--      provisoire ou consolide, et le motif d'une decision se lit dans le
--      journal d'audit (`ADM-04`), par qui a le droit de l'ouvrir.
--
-- Ce que ce fichier ne fait PAS, et ou cela vivra : le **geste** de correction
-- manuelle (`corrigee_manuel`) et le marquage `excusee`. La table et ses
-- policies existent depuis 0007, mais l'ecran qui les declenche demande une
-- confirmation, une entree de journal et un motif obligatoire -- c'est un lot,
-- pas une ligne. La section 6.5 le laisse d'ailleurs explicitement ouvert
-- (« mecanisme non concu ici »). N4 affiche la consolidation ; il ne la
-- prononce pas.

-- ============================================================
-- 1. La vue, bornee a ce que l'appelant a le droit de savoir
-- ============================================================

-- `drop` puis `create`, et non `create or replace` : une colonne s'ajoute en
-- fin de liste avec `replace`, jamais au milieu, et le prenom se lit a cote du
-- role. Les droits partent avec la vue ; ils sont reposes en section 2.
drop view if exists public.presence_seance_v;

create view public.presence_seance_v
with (security_barrier = true)
as
select
  sp.session_id,
  sp.profile_id,
  sp.role,
  -- Prenom et identifiant immuable, jamais le nom de famille (ADR-008).
  p.first_name   as prenom,
  p.immutable_id as identifiant_immuable,
  public.etat_presence(sp.session_id, sp.profile_id) as etat,
  -- Le contexte voyage AVEC l'etat (section 6.5) : la Bible interdit de
  -- reduire une presence a une seule couleur, et un ecran qui devrait
  -- redemander l'heure d'entree par une seconde requete finirait par
  -- l'afficher en retard sur l'etat.
  (select min(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id
      and e.event_type = 'joined')                   as entre_le,
  (select max(e.server_ts) from public.session_events e
    where e.session_id = sp.session_id
      and e.profile_id = sp.profile_id)              as derniere_trace_le,
  -- Provisoire contre finalise (section 6.6). Le booleen dit qu'une decision
  -- humaine a fige cet etat ; `decide_le` dit quand. Le motif et le decideur
  -- restent dans la table, et dans le journal.
  (o.etat is not null)                               as consolide,
  o.decide_le                                        as consolide_le,
  s.started_at,
  s.ended_at,
  s.status                                           as statut_seance
from public.session_participants sp
join public.sessions s on s.id = sp.session_id
join public.profiles p on p.id = sp.profile_id
left join public.session_presence_override o
       on o.session_id = sp.session_id
      and o.profile_id = sp.profile_id
where sp.deleted_at is null
  and s.deleted_at is null
  and p.deleted_at is null
  and (
    -- L'administration, et le controle qualite dont c'est le metier (ADR-011).
    public.app_role() in ('admin', 'controller')
    -- L'enseignant : les seances qu'il donne, et elles seules.
    or s.teacher_id = auth.uid()
    -- Le tuteur : les participants de son foyer. C'est ce qui permettra a
    -- `TUT-06` d'exister sans rouvrir cette vue.
    or (public.app_role() = 'guardian'
        and p.household_id = public.app_household_id())
    -- L'eleve : SA propre ligne, et rien d'autre. La section 6.6 est explicite
    -- -- « son propre etat ; aucun detail administratif, pas les etats des
    -- autres ». `session_peers_v` lui donne deja le prenom de ses pairs ; leur
    -- presence est une information de suivi, pas une information de salle.
    or sp.profile_id = auth.uid()
  )
  -- Une visite de controle ne laisse aucune ligne lisible (ADR-011, choix 3 de
  -- l'en-tete). Seule l'administration la voit ; le controleur lui-meme ne s'y
  -- lit pas, faute de quoi son ecran afficherait une personne de plus que celui
  -- de l'enseignant et le test visuel de l'invisibilite ne voudrait plus rien
  -- dire.
  and (sp.role <> 'masked_controller' or public.app_role() = 'admin');

comment on view public.presence_seance_v is
  'Presence par participant, derivee par etat_presence(). Bornee a l''appelant : '
  'admin voit tout, le controleur les seances sans les observateurs masques, '
  'l''enseignant ses seances, le tuteur son foyer, l''eleve sa seule ligne '
  '(etape 5 section 6.6, ADR-011).';

-- ============================================================
-- 2. Droits
-- ============================================================

-- Reposes a l'identique de 0007 : le `drop` de la section 1 les a emportes.
grant select on public.presence_seance_v to authenticated;
