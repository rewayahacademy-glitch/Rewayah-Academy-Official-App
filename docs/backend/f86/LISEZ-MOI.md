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
