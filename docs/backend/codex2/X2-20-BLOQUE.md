# X2-20 — BLOQUÉ, sources contractuelles absentes

## Base demandée

Branche créée depuis `claude/integ-c11bis-c20` à `fe253766bedc85686125ac1a58effa03a1065601`, confirmé par `git ls-remote` le 2026-10-12.

## Motif

La ligne Codex2!A115 cite comme sources obligatoires :

- `docs/current/PED-APRES/PED_APRES_SPEC_VERTICALE_V1.md` à partir de `01ac4026` ;
- `docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md` ;
- la migration `0054_seance_resumes_famille` et la PR #21 / `codex/backend-f2-after-c`.

Dans ce checkout, les deux fichiers PED-APRÈS sont absents. L'objet Git `01ac4026` n'est pas disponible. Le ref distant `codex/backend-f2-after-c` existe à `b6440e9fb284f197cf6743101dcf73dff2469787`, mais ne contient pas ces deux chemins. Le résumé de A115 ne remplace pas les règles temporelles, le tableau de vérité A01-A22 ni le contrat exact du port que la consigne demande de suivre.

## Action

Aucun schéma, RPC, RLS, adaptateur ou test n'a été inventé. X2-20 reste BLOQUÉ jusqu'à ce que les deux contrats soient présents dans le checkout ou fournis dans Codex2. Aucun accès à une base distante n'a été tenté.
