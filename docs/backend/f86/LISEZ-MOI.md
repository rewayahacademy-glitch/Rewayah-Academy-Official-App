# Manifeste F86 (candidat) - rejeu de codex/backend-canon-fixes @ 7e44fece

Produit par la session de lot BR-1 (relecteur non auteur), le 11/10/2026. **Rien ici n'est approuve.**

- `F86_MANIFESTE_CANDIDAT_canon-fixes_7e44fece.json` : 211 fonctions SECURITY DEFINER lues dans le catalogue reel
  d'un rejeu PG16 local (stub_auth + migrations de canon-fixes ; le bloc `m2_scan` de 0084 est retire en copie car 0084
  s'annule sur `ressources_du_groupe`). `approval_state` = `CANDIDATE_NOT_APPROVED`. Les `md5_functiondef` sont ceux du rejeu ;
  a recontroler en PG17 avant tout usage sur STAGING/PROD.
- Classification automatique : 55 `ROLE_POSITIVE_TEMPLATE` (garde positive null-safe reconnue), 3 `PINNED_FUNCTIONDEF_EXCEPTION`,
  153 `NO_GUARD_HELPER` (a justifier ou a reclasser par Codex). Aucune fonction n'a ete relue une par une pour ce fichier.
- `F86_VERIFICATION_PROBLEMES.txt` : sortie de `verify_allowlist.verify` si on forcait `APPROVED_ALLOWLIST` : 199 problemes.
  Deux familles : (1) 89 fonctions classees `NO_GUARD_HELPER` lisent le role ou le JWT (le gate l'interdit) ;
  (2) 86 fonctions ont un EXECUTE pour anon, agent_ro ou service_role (68 service_role, 43 agent_ro, 8 anon) alors que le gate l'interdit.
  La seconde famille est une divergence de conception (le modele agent_ro de 0014 expose volontairement des RPC en lecture) :
  a trancher (retirer les grants ou assouplir le gate pour agent_ro).
- `generer_manifeste_candidat.py` : generateur (python -I generer_manifeste_candidat.py <dossier de verify_allowlist.py> <catalogue.json> <sortie.json>).

Emplacement cible pour Codex : copier le JSON sous `docs/backend/` de sa branche (ce depot interdit a Claude d'ecrire dans `supabase/`).

## Mise a jour (decision DECISIONS-ORCH-2026-10-11-SOIR-F86-GRANTS, ligne 396)

`F86_MANIFESTE_CIBLE_apres_F86-ACL_canon-fixes_7e44fece.json` decrit l'etat CIBLE apres la migration F86-ACL de Codex :
service_role revoque partout ; agent_ro seulement sur les fonctions de lecture (champ `access_class` = `AGENT_RO_LECTURE`, 36 fonctions) ;
anon seulement sur les 5 helpers de claims (`HELPER_CLAIMS`). Les md5 sont ceux du rejeu ACTUEL (a recalculer apres la migration).
Le champ `access_class` est NOUVEAU : le gate (`verify_allowlist.py`, 3 classes) ne le connait pas, a ajouter par Codex.

`F86_ACTIONS_POUR_CODEX.json` liste ce que la migration doit faire :
- `revoke_service_role` : 68 fonctions ;
- `revoke_agent_ro_ecriture` : 1 (`agent_pre_request()`, volatile : elle ecrit set_config) ;
- `anon_a_justifier_ou_revoquer` : 3 (`agent_identite_masquee()`, `agent_pre_request()`, `profil_de_mon_foyer(text)`) ;
- `no_guard_non_admis_(volatile_ou_dml)` : 82 fonctions classees NO_GUARD_HELPER qui ne sont pas STABLE ou qui ecrivent : 24 sont des
  fonctions de TRIGGER en SECURITY DEFINER (interdit par la decision AL-F79) et 58 sont des RPC d'ecriture dont la premiere instruction
  n'est pas la garde positive canonique (`if not coalesce(public.app_account_valid() and public.app_role() ..., false)`).
Detection d'ecriture : motif `insert into | update .. set | delete from | truncate | set_config | nextval | log_sensitive_access` dans prosrc
(approximatif : a verifier fonction par fonction).
