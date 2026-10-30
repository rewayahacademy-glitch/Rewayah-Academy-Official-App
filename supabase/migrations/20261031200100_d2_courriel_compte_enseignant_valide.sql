-- D2 (RELIQUATS-B1-B2, ordre du directeur du 30/10/2026) : l'enseignant
-- recoit un e-mail quand son compte est valide.
--
-- `decider_dossier` (20261017100500) passe le compte de `pending_kyc` a
-- `active` quand la direction approuve la piece ; rien ne l'en avertissait.
-- Un declencheur APRES la mise a jour de `profiles` enfile le modele
-- `compte_enseignant_valide` dans la file `courriels_sortants` (categorie
-- `recrutement`, essentielle), ecrit en francais et en arabe, traduit a
-- l'envoi vers les autres langues comme `attente_candidat`.
--
-- Un declencheur plutot qu'un remplacement de `decider_dossier` : la fonction
-- de la decision, son empreinte (F86) et ses controles restent intacts.
-- Il ne part que pour un compte `teacher`, au seul passage `pending_kyc` ->
-- `active`, une seule fois par compte (cle d'idempotence). Les enseignants
-- deja actifs ne recoivent rien. Sans adresse, rien ne part et la decision
-- n'est pas empechee.
--
-- Ni DELETE, ni DROP, ni TRUNCATE.

begin;

create function private.courriel_compte_enseignant_valide()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_adresse text := public.courriel_adresse_profil(new.id);
begin
  if v_adresse is null then
    return null;
  end if;
  perform public.courriel_enfiler(
    'recrutement', 'compte_enseignant_valide', v_adresse, new.id,
    '{}'::jsonb, 'compte_enseignant_valide:' || new.id::text, 'auto', auth.uid());
  return null;
end;
$function$;

comment on function private.courriel_compte_enseignant_valide() is
  'D2 (30/10/2026) : enfile l''e-mail « Votre compte enseignant est valide » '
  'au passage d''un compte teacher de pending_kyc a active (decider_dossier).';

revoke all on function private.courriel_compte_enseignant_valide() from public, anon, authenticated;

create trigger profiles_courriel_compte_enseignant_valide
  after update of account_status on public.profiles
  for each row
  when (old.account_status = 'pending_kyc'
        and new.account_status = 'active'
        and new.role = 'teacher')
  execute function private.courriel_compte_enseignant_valide();

commit;
