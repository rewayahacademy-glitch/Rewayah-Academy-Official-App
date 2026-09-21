-- 0034 -- Le stockage R2 : autorisations, audit, et le gel qui doit rester possible
--
-- ============================================================
-- CE QUE CE FICHIER FAIT, ET CE QU'IL SE REFUSE A FAIRE
-- ============================================================
--
-- Quatre seaux Cloudflare R2 existent deja, sous juridiction europeenne, et
-- leur cycle complet a ete mesure au vert le 21 septembre 2026. Ce fichier ne
-- les cree pas, ne les nomme meme pas : un nom de seau est une valeur de
-- configuration du serveur, pas une donnee du schema. Il pose uniquement ce
-- dont la BASE a besoin pour que l'acces a ces objets soit autorise avant
-- d'etre signe.
--
-- Trois manques mesures dans le schema existant, et rien d'autre :
--
--   1. `session_recordings` existe depuis `0001` avec `object_key`,
--      `duration_seconds`, `size_bytes`, `codec`, `status` et `expires_at`,
--      mais AUCUN producteur ne l'alimente et aucune RPC ne la lit. Le webhook
--      LiveKit ignore `egress_ended`. Il manque donc l'entree des metadonnees.
--   2. L'ADR-002 prevoit une purge glissante a trente jours << sauf litige
--      ouvert qui gele la piece >>. L'enum `recording_status` ne connait que
--      `available`, `expired` et `revoked` : aucun etat ne dit << gelee >>, et
--      une purge ecrite sans cet etat rendrait le gel impossible apres coup.
--      C'est le point que la specification interdit explicitement de laisser
--      passer.
--   3. La lecture d'une piece d'identite et l'ecoute d'une archive n'ont aucune
--      porte serveur. L'apercu KYC d'aujourd'hui signe son URL DEPUIS LE CLIENT
--      avec la session de l'administrateur (`service_validation.dart`), ce qui
--      contredit le commentaire de `0004` annoncant une generation serveur.
--
-- Ce que ce fichier NE fait PAS, volontairement :
--
--   * il n'ajoute aucune table. `kyc_documents` et `session_recordings`
--     existent ; en creer des jumelles serait exactement la faute que la
--     specification interdit ;
--   * il ne cree RIEN pour la messagerie. Le domaine n'existe pas dans ce
--     depot -- zero table, zero ecran, zero route -- et la question 18 du
--     registre des decisions le dit non tranche. Inventer une table de
--     conversations pour justifier un seau serait inventer une decision ;
--   * il n'ecrit aucune purge. L'ADR-002 annonce `pg_cron` et l'ADR-006 une
--     regle de cycle de vie du seau : les deux se contredisent, et `pg_cron`
--     n'est installee nulle part. Ce fichier rend la purge POSSIBLE et sure ;
--     il ne choisit pas laquelle ;
--   * il ne migre aucun objet. Les dix-huit pieces deja deposees vivent dans le
--     seau Supabase `kyc` ; `storage_backend` les y laisse et permet a la
--     lecture serveur de servir les deux stockages pendant la bascule.
--
-- Rappels de doctrine appliques ici : porte ecrite en EXIGENCE POSITIVE
-- enveloppee de `coalesce` (`0029` -- un refus ecrit `<> 'admin'` ne se
-- declenche pas sur le NULL d'un appelant anonyme) ; `security definer` avec
-- `set search_path = ''` ; double `revoke`, `from public` ET `from anon`
-- (`0028` -- aucun des deux ne suffit seul) ; et jamais de `grant execute` a
-- `agent_ro` sur une fonction volatile ou d'ecriture.

-- ============================================================
-- 1. Le gel legal, et la coexistence des deux stockages
-- ============================================================

-- Pourquoi une colonne et non une valeur d'enum : PostgreSQL refuse d'utiliser
-- une valeur d'enum ajoutee dans la meme transaction (55P04), lecon de `0031`.
-- Un `legal_hold` en enum obligerait a scinder ce fichier en deux migrations
-- pour que la purge puisse le nommer. Une colonne est lisible tout de suite, et
-- elle dit mieux ce qu'elle est : un gel n'est pas un etat de l'archive, c'est
-- une contrainte POSEE SUR elle, qui coexiste avec `available` ou `expired`.
alter table public.session_recordings
  add column if not exists legal_hold_since timestamptz,
  add column if not exists egress_id text;

comment on column public.session_recordings.legal_hold_since is
  'ADR-002 : gel de conservation. Non nul = la piece est retenue pour un litige et AUCUNE purge ne doit la supprimer, meme expiree. Toute purge future doit tester cette colonne.';

-- Il n'y a deliberement PAS de colonne `legal_hold_reason`, et c'est la lecon
-- que ce depot paie cher depuis le debut : **la RLS borne les LIGNES, jamais
-- les COLONNES.** Les deux policies de `session_recordings` (0001) donnent le
-- `select` a l'enseignant de la seance et au foyer d'un participant, sur la
-- ligne ENTIERE. Un motif tel que << plainte de la famille X contre
-- l'enseignant Y >> serait donc lisible par l'enseignant mis en cause et par
-- les familles concernees, a la requete suivante.
--
-- Le motif vit donc dans `audit_logs`, qui est reserve a l'administration,
-- append-only et chaine par empreinte. La ligne, elle, ne porte que le FAIT du
-- gel : une date, que tout le monde peut voir sans dommage.

comment on column public.session_recordings.egress_id is
  'Identifiant d''Egress LiveKit. Porte l''idempotence de l''entree des metadonnees : un webhook peut arriver plusieurs fois (section 29 de la specification).';

-- Un Egress produit une archive et une seule. L'unicite est ce qui rend
-- l'ingestion idempotente sans condition ecrite dans la fonction : la base
-- tranche, pas l'appelant.
create unique index if not exists session_recordings_egress_id_key
  on public.session_recordings (egress_id)
  where egress_id is not null;

-- Lecture de la file des archives a purger, et surtout de celles qui ne le sont
-- pas. Partiel : seules les lignes vivantes interessent une purge.
create index if not exists session_recordings_expiration_idx
  on public.session_recordings (expires_at)
  where deleted_at is null and legal_hold_since is null;

-- La coexistence des deux stockages pendant la bascule. Defaut `supabase` :
-- toutes les lignes deja presentes designent un objet du seau Supabase `kyc`,
-- et un defaut qui mentirait sur dix-huit pieces existantes serait pire que pas
-- de colonne du tout.
alter table public.kyc_documents
  add column if not exists storage_backend text not null default 'supabase';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.kyc_documents'::regclass
      and conname = 'kyc_documents_storage_backend_check'
  ) then
    alter table public.kyc_documents
      add constraint kyc_documents_storage_backend_check
      check (storage_backend in ('supabase', 'r2'));
  end if;
end $$;

comment on column public.kyc_documents.storage_backend is
  'Ou vit l''objet designe par object_key : seau Supabase Storage << kyc >> (historique) ou seau R2 rewayah-identity-vault. Lu par la lecture serveur pour choisir qui signe l''URL.';

-- ============================================================
-- 2. Ouvrir une piece d'identite -- autorise, puis journalise
-- ============================================================

-- Une URL signee n'est PAS une autorisation : c'est le produit d'une
-- autorisation deja accordee. Cette fonction est cette autorisation.
--
-- Elle ne refait pas le cloisonnement par genre : elle le delegue a
-- `read_kyc_documents()`, qui le porte depuis `0001`, qui filtre sur le genre
-- du lecteur lu sur SON propre dossier, et qui journalise deja `kyc_read`.
-- Construire par-dessus plutot qu'a cote est ce que `dossiers_en_attente()`
-- fait deja ; deux implementations du meme filtre divergeraient le jour ou
-- l'une des deux serait corrigee.
--
-- Une seconde trace est ecrite ici, et elle n'est pas redondante :
-- `read_kyc_documents()` consigne QU'UNE liste a ete lue, celle-ci consigne
-- QUELLE piece a ete ouverte. C'est la trace que l'ADR-002 exige, et c'est la
-- seule qui designe une ligne.
create or replace function public.autoriser_lecture_piece_identite(p_document_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_piece public.kyc_documents;
begin
  -- Exigence POSITIVE : `app_role()` rend NULL pour un appelant anonyme, et un
  -- refus ecrit `<> 'admin'` ne se declencherait pas sur NULL (`0029`).
  if not coalesce(public.app_role() in ('admin', 'controller'), false) then
    raise exception 'lecture des pieces d''identite reservee a l''administration'
      using errcode = '42501';
  end if;

  -- Meme exigence que sur l'ecoute d'une archive : un compte suspendu ou
  -- expire garde son role dans son jeton jusqu'a expiration de celui-ci.
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte non valide' using errcode = '42501';
  end if;

  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  -- Le filtre de genre et le refus franc d'un lecteur sans genre connu vivent
  -- dans `read_kyc_documents()`. Une piece invisible pour ce lecteur ne
  -- remonte simplement pas.
  select k.* into v_piece
  from public.read_kyc_documents() k
  where k.id = p_document_id;

  if not found then
    -- Volontairement indistinct de << ce document n'existe pas >> : la
    -- difference renseignerait sur le contenu du coffre.
    raise exception 'piece introuvable ou hors de votre perimetre'
      using errcode = '42501';
  end if;

  if v_piece.deleted_at is not null then
    raise exception 'piece supprimee' using errcode = '42501';
  end if;

  -- `doc_type` n'entre PAS dans la trace. `audit_logs` est lisible par toute
  -- l'administration, genres confondus, alors que la piece elle-meme ne l'est
  -- pas : y inscrire la nature du document ferait du journal un contournement
  -- du cloisonnement pose par `0001`. Le `profile_id`, lui, y reste : il est
  -- deja visible de toute l'administration par `dossiers_en_attente()`, qui
  -- rend les profils en attente meme lorsque leur piece est `non_visible`.
  perform public.log_sensitive_access(
    'kyc_document_open',
    'kyc_documents',
    v_piece.id::text,
    jsonb_build_object(
      'profile_id', v_piece.profile_id,
      'storage_backend', v_piece.storage_backend,
      'status', v_piece.status
    )
  );

  -- `object_key` sort d'ici vers la couche de signature, jamais vers le client.
  return jsonb_build_object(
    'document_id', v_piece.id,
    'profile_id', v_piece.profile_id,
    'object_key', v_piece.object_key,
    'storage_backend', v_piece.storage_backend,
    'doc_type', v_piece.doc_type
  );
end;
$$;

comment on function public.autoriser_lecture_piece_identite(uuid) is
  'Autorise l''ouverture d''UNE piece d''identite, puis la journalise (ADR-002). Construite sur read_kyc_documents() pour ne pas dupliquer le cloisonnement par genre. Rend object_key a la couche serveur de signature, jamais au client.';

revoke all on function public.autoriser_lecture_piece_identite(uuid) from public;
revoke all on function public.autoriser_lecture_piece_identite(uuid) from anon;
grant execute on function public.autoriser_lecture_piece_identite(uuid) to authenticated;
grant execute on function public.autoriser_lecture_piece_identite(uuid) to service_role;
-- Pas de `grant` a `agent_ro` : la fonction ECRIT dans audit_logs, et un jeton
-- d'agent n'a aucun droit d'ecriture (regle posee par `0014`, que
-- `get_advisors` ne detecte pas).

-- ============================================================
-- 3. Deposer une piece d'identite dans le coffre R2
-- ============================================================

-- Le serveur fabrique la cle, le client ne la propose pas.
--
-- La ligne est creee AVANT l'envoi de l'objet, ce qui inverse l'ordre du depot
-- actuel (`service_dossier.dart` envoie puis insere). L'inversion est
-- deliberee : la cle doit exister avant d'etre signee, et un identifiant tire
-- par la base est le seul qui ne puisse pas etre choisi par l'appelant.
--
-- Mais une ligne creee avant l'envoi est une ligne qui peut n'avoir jamais
-- d'objet -- reseau coupe, application fermee, envoi refuse par R2. Laissee
-- `pending` et visible, elle entrerait dans `dossiers_en_attente()` et
-- l'administration ouvrirait un document qui n'existe pas.
--
-- ponytail: la reservation nait donc `deleted_at = now()`, c'est-a-dire
-- invisible pour TOUT le depot, dont `read_kyc_documents()` et
-- `dossiers_en_attente()` qui filtrent deja `deleted_at is null`. Aucune
-- fonction existante n'a eu besoin d'etre touchee. Plafond assume de ce
-- raccourci : une reservation jamais confirmee se lit ensuite comme une piece
-- supprimee, ce qui est exact du point de vue du produit mais ne distingue pas
-- << jamais arrivee >> de << retiree apres coup >>. Le jour ou cette nuance
-- comptera, la voie est une colonne `uploaded_at` et un filtre explicite dans
-- `dossiers_en_attente()`.
--
-- `gender` n'est pas fourni : le declencheur `completer_kyc_document()` de
-- `0004` l'ecrase par celui du profil concerne et echoue si ce genre est
-- inconnu. Le laisser arriver d'ici reviendrait a confier au deposant le choix
-- de qui pourra regarder sa piece.
-- La porte du depot, isolee et SANS EFFET DE BORD.
--
-- Elle vit a part parce que deux chemins doivent poser exactement la meme
-- question : la reservation d'une cle, et la confirmation du depot une fois
-- l'objet arrive. Ecrire la porte deux fois, c'est se donner rendez-vous le
-- jour ou l'une des deux sera corrigee.
--
-- Elle rejoue EXACTEMENT ce que les trois policies d'insertion de
-- `kyc_documents` autorisent, ni plus, ni moins :
--
--   `kyc_admin_all`         (0001) : l'administration, pour qui elle veut ;
--   `kyc_guardian_insert`   (0001) : un TUTEUR, pour une personne de son foyer ;
--   `kyc_staff_self_insert` (0004) : un ENSEIGNANT ou un CONTROLEUR, pour lui-meme.
--
-- Le role compte autant que la relation. Une porte qui se contenterait de
-- << pour soi, ou pour son foyer >> ouvrirait le depot aux ELEVES, que les
-- trois policies excluent : `profiles_household_required` (0004) donne un foyer
-- a tout eleve, donc son jeton porte un `household_id`, et il pourrait creer
-- une piece au nom de son tuteur -- puis, le coffre configure, obtenir une URL
-- de depot sous le prefixe de celui-ci. Le role est ce qui ferme cette porte.
create or replace function public.peut_deposer_piece_identite(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    public.app_account_valid()
    and p_profile_id is not null
    and (
      public.app_role() = 'admin'
      or (
        public.app_role() = 'guardian'
        and exists (
          select 1 from public.profiles p
          where p.id = p_profile_id
            and p.deleted_at is null
            and p.household_id is not null
            and p.household_id = public.app_household_id()
        )
      )
      or (
        public.app_role() in ('teacher', 'controller')
        and p_profile_id = auth.uid()
      )
    ),
    false
  );
$$;

comment on function public.peut_deposer_piece_identite(uuid) is
  'La porte du depot d''une piece d''identite, sans effet de bord. Rejoue exactement kyc_admin_all, kyc_guardian_insert et kyc_staff_self_insert. Un eleve n''y passe jamais.';

revoke all on function public.peut_deposer_piece_identite(uuid) from public;
revoke all on function public.peut_deposer_piece_identite(uuid) from anon;
grant execute on function public.peut_deposer_piece_identite(uuid) to authenticated;
grant execute on function public.peut_deposer_piece_identite(uuid) to service_role;
-- Lecture seule et sans ecriture : `agent_ro` peut l'evaluer sans danger.
grant execute on function public.peut_deposer_piece_identite(uuid) to agent_ro;

create or replace function public.preparer_depot_piece_identite(
  p_profile_id uuid,
  p_doc_type text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_document_id uuid := gen_random_uuid();
  v_cible uuid := coalesce(p_profile_id, auth.uid());
  v_cle text;
begin
  -- La cle de service contourne la RLS ; cette fonction est `security definer`
  -- et la contourne aussi. Elle rejoue donc la porte, qui vit a part pour que
  -- la confirmation pose exactement la meme question.
  if v_cible is null then
    raise exception 'authentification requise' using errcode = '42501';
  end if;

  if not public.peut_deposer_piece_identite(v_cible) then
    raise exception 'depot refuse pour ce profil' using errcode = '42501';
  end if;

  if p_doc_type is null or p_doc_type not in ('id_card', 'passport', 'residence_permit', 'other') then
    raise exception 'type de piece inconnu' using errcode = '22023';
  end if;

  -- La convention de `_shared/r2/cles.ts`, cote base, au caractere pres :
  -- identity/<profile_id>/<document_id>. Aucune donnee lisible, que des UUID.
  v_cle := 'identity/' || v_cible::text || '/' || v_document_id::text;

  insert into public.kyc_documents
    (id, profile_id, doc_type, object_key, storage_backend, status, deleted_at)
  values (v_document_id, v_cible, p_doc_type, v_cle, 'r2', 'pending', now());

  -- Meme raison qu'a la lecture : la nature du document n'entre pas dans un
  -- journal que toute l'administration lit.
  perform public.log_sensitive_access(
    'kyc_document_prepare',
    'kyc_documents',
    v_document_id::text,
    jsonb_build_object('profile_id', v_cible, 'storage_backend', 'r2')
  );

  return jsonb_build_object('document_id', v_document_id, 'object_key', v_cle);
end;
$$;

comment on function public.preparer_depot_piece_identite(uuid, text) is
  'Reserve une piece d''identite dans le coffre R2 : tire l''identifiant, fabrique la cle cote serveur (identity/<profile_id>/<document_id>) et cree la ligne pending. Le client ne propose jamais de cle.';

revoke all on function public.preparer_depot_piece_identite(uuid, text) from public;
revoke all on function public.preparer_depot_piece_identite(uuid, text) from anon;
grant execute on function public.preparer_depot_piece_identite(uuid, text) to authenticated;
grant execute on function public.preparer_depot_piece_identite(uuid, text) to service_role;

-- La piece n'entre dans la file de validation qu'une fois l'objet REELLEMENT
-- depose. Le point d'entree serveur interroge R2 par un HEAD avant d'appeler
-- cette fonction : << j'ai fini d'envoyer >> reste une affirmation du client
-- tant que personne n'est alle regarder.
--
-- Reservee a `service_role` : l'appelant est la fonction Edge qui vient de
-- faire cette verification, jamais le navigateur. Un compte qui pourrait
-- l'appeler directement rendrait le HEAD contournable, donc inutile.
create or replace function public.confirmer_depot_piece_identite(p_document_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_touche int;
  v_profil uuid;
begin
  if p_document_id is null then
    raise exception 'document non precise' using errcode = '22023';
  end if;

  -- Seule une reservation R2 encore non confirmee peut etre rendue visible.
  -- Les trois conditions comptent : `storage_backend = 'r2'` empeche de
  -- ressusciter une piece du stockage historique, `status = 'pending'` empeche
  -- de rouvrir un dossier deja tranche, et `deleted_at is not null` fait que la
  -- fonction est sans effet sur une piece deja vivante.
  update public.kyc_documents k
  set deleted_at = null
  where k.id = p_document_id
    and k.storage_backend = 'r2'
    and k.status = 'pending'
    and k.deleted_at is not null
  returning k.profile_id into v_profil;

  get diagnostics v_touche = row_count;
  if v_touche = 0 then
    raise exception 'aucune reservation a confirmer' using errcode = '42501';
  end if;

  perform public.log_sensitive_access(
    'kyc_document_confirm',
    'kyc_documents',
    p_document_id::text,
    jsonb_build_object('profile_id', v_profil, 'storage_backend', 'r2')
  );

  return true;
end;
$$;

comment on function public.confirmer_depot_piece_identite(uuid) is
  'Rend visible une piece d''identite reservee, une fois son objet verifie present dans rewayah-identity-vault. Reservee a service_role : c''est la fonction Edge qui a fait la verification.';

revoke all on function public.confirmer_depot_piece_identite(uuid) from public;
revoke all on function public.confirmer_depot_piece_identite(uuid) from anon;
revoke all on function public.confirmer_depot_piece_identite(uuid) from authenticated;
grant execute on function public.confirmer_depot_piece_identite(uuid) to service_role;

-- ============================================================
-- 4. Ecouter une archive de seance -- autorise, puis journalise
-- ============================================================

-- Les relations qui donnent le droit d'ecouter sont exactement celles que les
-- deux policies de `0001` expriment sur `session_recordings` : l'administration
-- et le controle d'une part, l'enseignant de la seance et le foyer d'un
-- participant d'autre part. Elles sont reprises ici parce qu'une policy borne
-- les LIGNES d'un `select`, et que cette fonction doit rendre un `object_key`
-- pour une ligne designee -- ce qui est une decision, pas une lecture.
create or replace function public.autoriser_ecoute_archive(p_recording_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_archive public.session_recordings;
  v_role public.app_role := public.app_role();
  v_foyers int;
begin
  if not coalesce(public.app_account_valid(), false) then
    raise exception 'compte non valide' using errcode = '42501';
  end if;

  if p_recording_id is null then
    raise exception 'archive non precisee' using errcode = '22023';
  end if;

  select r.* into v_archive
  from public.session_recordings r
  where r.id = p_recording_id;

  if not found or v_archive.deleted_at is not null then
    raise exception 'archive introuvable' using errcode = '42501';
  end if;

  -- Combien de foyers distincts ont un participant dans cette seance ?
  --
  -- La question n'est pas rhetorique. `session_in_household()` (0001) rend vrai
  -- des qu'UN SEUL participant appartient au foyer interroge. Elle a ete ecrite
  -- quand une seance comptait deux personnes (`max_participants_per_session`
  -- valait 2, `allow_multi_participant_sessions` valait false) : elle voulait
  -- alors dire << le foyer de l'eleve de ce cours >>. Depuis le pivot du 19
  -- septembre, `0017` porte le plafond a 7 et ouvre le multi-participant : une
  -- seance de groupe reunit cinq enfants de cinq foyers.
  --
  -- Appliquee telle quelle a une archive de groupe, cette relation donnerait a
  -- CHAQUE tuteur l'audio complet de la seance -- ou recitent aussi les enfants
  -- des quatre autres familles, qui n'ont consenti qu'a l'enregistrement de la
  -- leur. La policy `session_recordings_teacher_family` (0001) porte la meme
  -- forme, mais elle n'avait jamais servi : rien n'alimentait ni ne lisait
  -- cette table avant ce fichier. Ouvrir la lecture, c'est l'activer.
  --
  -- Tant que l'operateur n'a pas tranche ce que la famille peut reecouter d'une
  -- seance collective, la branche famille reste bornee aux seances d'un seul
  -- foyer. L'enseignant de la seance, l'administration et le controle gardent
  -- leur acces dans tous les cas.
  select count(distinct p.household_id) into v_foyers
  from public.session_participants sp
  join public.profiles p on p.id = sp.profile_id
  where sp.session_id = v_archive.session_id
    and sp.deleted_at is null
    and p.deleted_at is null
    and p.household_id is not null;

  -- Exigence POSITIVE : toute inconnue ferme. Un appelant sans role tombe ici,
  -- et non plus loin.
  if not coalesce(
    v_role in ('admin', 'controller')
    or public.session_belongs_to_teacher(v_archive.session_id, auth.uid())
    or (
      v_foyers <= 1
      and public.session_in_household(v_archive.session_id, public.app_household_id())
    ),
    false
  ) then
    raise exception 'ecoute refusee : aucune relation avec cette seance'
      using errcode = '42501';
  end if;

  -- L'etat de l'archive est une condition d'acces a part entiere : une piece
  -- revoquee ou expiree ne s'ecoute pas, meme par qui en avait le droit hier.
  -- Un gel de conservation, lui, garde la piece accessible a l'administration
  -- et au controle -- c'est sa raison d'etre.
  if v_archive.status = 'revoked' then
    raise exception 'archive revoquee' using errcode = '42501';
  end if;

  if v_archive.expires_at <= now() or v_archive.status = 'expired' then
    if not coalesce(
      v_archive.legal_hold_since is not null and v_role in ('admin', 'controller'),
      false
    ) then
      raise exception 'archive expiree' using errcode = '42501';
    end if;
  end if;

  perform public.log_sensitive_access(
    'recording_listen',
    'session_recordings',
    v_archive.id::text,
    jsonb_build_object(
      'session_id', v_archive.session_id,
      'legal_hold', v_archive.legal_hold_since is not null,
      'status', v_archive.status
    )
  );

  return jsonb_build_object(
    'recording_id', v_archive.id,
    'session_id', v_archive.session_id,
    'object_key', v_archive.object_key,
    'duration_seconds', v_archive.duration_seconds,
    'expires_at', v_archive.expires_at
  );
end;
$$;

comment on function public.autoriser_ecoute_archive(uuid) is
  'Autorise l''ecoute d''UNE archive de seance, puis la journalise (ADR-002 : chaque ecoute est ecrite dans audit_logs avec l''identite de l''auditeur). Rend object_key a la couche serveur de signature, jamais au client.';

revoke all on function public.autoriser_ecoute_archive(uuid) from public;
revoke all on function public.autoriser_ecoute_archive(uuid) from anon;
grant execute on function public.autoriser_ecoute_archive(uuid) to authenticated;
grant execute on function public.autoriser_ecoute_archive(uuid) to service_role;

-- ============================================================
-- 5. Entrer les metadonnees d'une archive produite par Egress
-- ============================================================

-- Le binaire ne passe ni par cette base ni par une fonction Edge : LiveKit
-- Egress depose directement dans le seau (ADR-002, ADR-006). Ce qui arrive ici
-- n'est qu'un constat -- session, cle, duree, taille, codec -- annonce par un
-- webhook dont la signature a deja ete verifiee.
--
-- `service_role` uniquement : l'appelant est le webhook, jamais une personne.
-- La cle d'objet est verifiee contre la convention AVANT d'arriver ici, par
-- `_shared/r2/cles.ts` : ce qu'un fournisseur renvoie reste une donnee recue.
--
-- La seance est resolue depuis le NOM DE SALLE, et non recue. C'est la seule
-- chose dont un evenement LiveKit dispose, `session_video_route.room_name`
-- etant unique depuis `0010` ; recevoir un `session_id` du webhook reviendrait
-- a laisser l'exterieur designer la seance a laquelle une archive s'attache.
create or replace function public.enregistrer_archive_seance(
  p_room_name text,
  p_egress_id text,
  p_object_key text,
  p_duration_seconds int,
  p_size_bytes bigint,
  p_codec text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_session_id uuid;
  v_retention int;
begin
  if p_room_name is null or p_object_key is null or p_egress_id is null then
    raise exception 'metadonnees d''archive incompletes' using errcode = '22023';
  end if;

  select r.session_id into v_session_id
  from public.session_video_route r
  where r.room_name = p_room_name;

  if v_session_id is null then
    raise exception 'salle inconnue' using errcode = '23503';
  end if;

  -- La duree de conservation est celle que l'exploitation a posee, lue au
  -- moment de l'entree. Trente jours est le defaut de l'ADR-002, pas une
  -- valeur ecrite en dur ici.
  v_retention := coalesce(
    (public.get_config('recording_retention_days', '30'::jsonb) #>> '{}')::int,
    30
  );

  -- Idempotence portee par l'index unique sur `egress_id`, et non par une
  -- condition ecrite ici : un webhook n'arrive ni une seule fois ni dans
  -- l'ordre (section 29 de la specification).
  insert into public.session_recordings (
    session_id, object_key, duration_seconds, size_bytes, codec, status, expires_at
  )
  values (
    v_session_id,
    p_object_key,
    greatest(coalesce(p_duration_seconds, 0), 0),
    greatest(coalesce(p_size_bytes, 0), 0),
    p_codec,
    'available',
    now() + make_interval(days => v_retention)
  )
  returning id into v_id;

  update public.session_recordings set egress_id = p_egress_id where id = v_id;

  return v_id;
exception
  when unique_violation then
    -- Doublon d'Egress : l'archive est deja entree. Rendre son identifiant
    -- plutot que d'echouer, pour que le webhook reponde 200 et n'appelle pas
    -- un renvoi qui ne serait pas moins doublon.
    select r.id into v_id
    from public.session_recordings r
    where r.egress_id = p_egress_id;
    return v_id;
end;
$$;

comment on function public.enregistrer_archive_seance(text, text, text, int, bigint, text) is
  'Entree des metadonnees d''une archive deposee par LiveKit Egress. Le binaire ne transite jamais par ici (ADR-002). La seance est resolue depuis room_name, jamais recue. Idempotente sur egress_id. Reservee a service_role : l''appelant est le webhook.';

revoke all on function public.enregistrer_archive_seance(text, text, text, int, bigint, text) from public;
revoke all on function public.enregistrer_archive_seance(text, text, text, int, bigint, text) from anon;
revoke all on function public.enregistrer_archive_seance(text, text, text, int, bigint, text) from authenticated;
grant execute on function public.enregistrer_archive_seance(text, text, text, int, bigint, text) to service_role;

-- ============================================================
-- 6. Poser et lever un gel de conservation
-- ============================================================

-- Sans ce chemin, le gel prevu par l'ADR-002 serait une colonne que rien ne
-- remplit. Reserve a l'administration : decider qu'un litige est ouvert n'est
-- pas une operation de consultation.
create or replace function public.geler_archive_seance(
  p_recording_id uuid,
  p_motif text,
  p_gel boolean default true
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_touche int;
begin
  if not coalesce(public.app_role() = 'admin', false) then
    raise exception 'gel de conservation reserve a l''administration'
      using errcode = '42501';
  end if;

  if p_recording_id is null then
    raise exception 'archive non precisee' using errcode = '22023';
  end if;

  -- `p_gel` a NULL doit ECHOUER, jamais degeler. Sans ce refus, `if p_gel and
  -- ...` ne se declenche pas (NULL and true vaut NULL, donc aucun motif n'est
  -- exige) et `case when p_gel then ... else null end` tombe dans le ELSE :
  -- une archive retenue pour un litige perdrait sa protection sur un argument
  -- omis, ce qu'un client qui serialise un booleen nullable produit sans le
  -- vouloir. C'est le meme renversement que `0029` a corrige ailleurs --
  -- l'inconnue doit fermer, pas ouvrir.
  if p_gel is null then
    raise exception 'sens du gel non precise' using errcode = '22023';
  end if;

  if p_gel and coalesce(btrim(p_motif), '') = '' then
    raise exception 'un gel de conservation exige un motif' using errcode = '22023';
  end if;

  update public.session_recordings r
  set legal_hold_since = case when p_gel then coalesce(r.legal_hold_since, now()) else null end
  where r.id = p_recording_id and r.deleted_at is null;

  get diagnostics v_touche = row_count;
  if v_touche = 0 then
    raise exception 'archive introuvable' using errcode = '42501';
  end if;

  -- Le motif entre ICI, et nulle part ailleurs : `audit_logs` est reserve a
  -- l'administration, quand la ligne d'archive est lisible par l'enseignant de
  -- la seance et par les familles.
  perform public.log_sensitive_access(
    case when p_gel then 'recording_legal_hold_set' else 'recording_legal_hold_lift' end,
    'session_recordings',
    p_recording_id::text,
    jsonb_build_object('gel', p_gel, 'motif', nullif(btrim(coalesce(p_motif, '')), ''))
  );

  return true;
end;
$$;

comment on function public.geler_archive_seance(uuid, text, boolean) is
  'Pose ou leve le gel de conservation d''une archive (ADR-002 : un litige ouvert gele la piece). Toute purge future doit tester legal_hold_since avant de supprimer quoi que ce soit.';

revoke all on function public.geler_archive_seance(uuid, text, boolean) from public;
revoke all on function public.geler_archive_seance(uuid, text, boolean) from anon;
grant execute on function public.geler_archive_seance(uuid, text, boolean) to authenticated;
grant execute on function public.geler_archive_seance(uuid, text, boolean) to service_role;

-- ============================================================
-- Fin de 0034. Verification de sortie : les objets de ce fichier existent.
-- ============================================================

do $$
begin
  if to_regprocedure('public.autoriser_lecture_piece_identite(uuid)') is null
     or to_regprocedure('public.peut_deposer_piece_identite(uuid)') is null
     or to_regprocedure('public.preparer_depot_piece_identite(uuid, text)') is null
     or to_regprocedure('public.confirmer_depot_piece_identite(uuid)') is null
     or to_regprocedure('public.autoriser_ecoute_archive(uuid)') is null
     or to_regprocedure('public.enregistrer_archive_seance(text, text, text, int, bigint, text)') is null
     or to_regprocedure('public.geler_archive_seance(uuid, text, boolean)') is null
     or not exists (
       select 1 from information_schema.columns
       where table_schema = 'public' and table_name = 'session_recordings'
         and column_name = 'legal_hold_since'
     )
     or not exists (
       select 1 from information_schema.columns
       where table_schema = 'public' and table_name = 'kyc_documents'
         and column_name = 'storage_backend'
     )
  then
    raise exception '0034 incomplete : verification de sortie echouee';
  end if;
end $$;
