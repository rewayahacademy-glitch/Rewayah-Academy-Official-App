---
name: feedback_mesurer_une_rpc_en_prod_sans_laisser_de_ligne
description: "Pour mesurer une RPC sur une base de production : un bloc DO atomique qui monte sa fixture, collecte le resultat dans une variable texte, puis leve une exception finale -- tout est annule, le resultat revient dans le message d'erreur"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 51210283-842a-4a2d-a542-88fd7d656af2
  modified: 2026-09-21T08:05:21.967Z
---

Relire une fonction SQL ne dit pas ce qu'elle REND. Mais l'appeler en production laisse des lignes :
fixtures, journal d'audit, jetons emis. D'ou le reflexe de s'en passer et de « relire attentivement »
-- c'est exactement comme cela qu'un defaut survit a trois revues.

**La parade : un seul bloc `DO`, qui se rejette lui-meme.**

```sql
do $$
declare v_out text := ''; v_res jsonb;
begin
  -- 1. monter la fixture (groupe, seance, participants...)
  -- 2. appeler REELLEMENT la fonction, pour chaque cas
  --    v_res := public.la_fonction(...);
  --    v_out := v_out || format('%s -> %s', cas, v_res->>'cle') || E'\n';
  -- 3. rendre la mesure PAR l'exception : elle annule tout le bloc
  raise exception 'MESURE %', v_out;
end $$;
```

**Pourquoi c'est sur, et pas « probablement sur ».** Un bloc `DO` est UNE instruction, donc atomique :
l'exception finale annule ses ecritures, fixture et journal d'audit compris. Il n'y a pas a se fier au
fait que l'outil ouvre ou non une transaction autour -- `begin`/`rollback` envoyes separement, eux,
dependent de ce que fait l'outil. Le message d'exception revient a l'appelant : c'est le canal de
sortie.

**Deux details qui font la difference :**
- Pour un cas qui doit ECHOUER, l'envelopper dans un `begin ... exception when others then` interne :
  cela cree une sous-transaction, donc l'echec n'emporte pas la mesure des autres cas.
- Pour une fonction qui lit `auth.uid()` ou `app_role()`, poser le contexte avec
  `perform set_config('request.jwt.claims', json_build_object('sub', <id>)::text, true)` -- le `true`
  le rend local a la transaction.

**Ce que cela a donne le 21/09** sur `autoriser_jeton_video` (Rewayah) : six roles mesures avant et
apres un changement d'une ligne, 30 cellules comparees, une seule qui bouge. Puis, sur la RPC de vie
privee, quatre appelants dont l'enfant d'un AUTRE foyer -- la seule facon de prouver qu'il ne recoit
rien. Zero ligne laissee en base.

**Et le corollaire :** MESURER AVANT AUSSI. Sans la mesure d'avant, « une seule case a bouge » n'est
qu'une affirmation. Voir [[feedback_chiffrer_avant_de_proposer]].
