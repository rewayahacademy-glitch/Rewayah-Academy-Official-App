---
name: feedback_security_definer_ne_rejoue_pas_la_policy
description: "Une RPC security definer contourne la RLS de la table qu'elle lit : un garde d'appartenance n'est pas un garde de visibilite, il faut recopier la policy dans le corps"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 698e9d53-73de-4fe9-85ba-01151929bf7c
  modified: 2026-09-21T01:24:30.759Z
---

Une fonction `security definer` s'execute **en proprietaire** : la RLS des tables qu'elle lit ne
s'applique pas a sa requete, sauf `alter table ... force row level security` (que Rewayah ne pose
**nulle part** -- verifie : `Select-String "force row level security" supabase/migrations/*.sql` ne
rend aucune ligne). Ecrire un garde d'entree correct au debut de la fonction ne suffit donc pas :
**le garde dit QUI entre, la policy dit CE QU'IL VOIT.** Les deux sont des regles differentes, et
seule la premiere survit dans une fonction `security definer`.

Trouve le 21/09/2026 sur `public.ressources_du_groupe` (migration `0033`, deja en production) :
sa porte d'entree etait pourtant impeccable (exigence positive, `if not exists (...) then raise`,
cf. [[feedback_porte_sql_exigence_positive]]) et ne testait que l'**appartenance au groupe**.
Sa requete ne portait ensuite aucun predicat sur `library_resource.access_policy` et ne rejouait pas
`app_account_valid()`. Consequence : un eleve **reellement membre** recevait les ressources
`enseignant_seul` et `admin` de son groupe -- que la policy `library_resource_lecture` (`0032:151-178`)
reserve au seul `teacher_id` du groupe (resp. au role `admin`) -- et un compte **suspendu** dont la
ligne `groupe_membres` restait ouverte les recevait aussi. Corrige par `0035`, qui transcrit la policy
mot pour mot dans le corps.

**Why:** une RLS bien ecrite donne un faux sentiment de securite. Elle protege les lectures directes
PostgREST, et pas une seule des RPC `security definer` qui lisent la meme table -- or le projet en a
des dizaines. Le defaut ne se voit ni a la relecture de la fonction seule (sa porte a l'air juste),
ni a la relecture de la policy seule (elle est juste), mais **seulement en confrontant les deux**.
`get_advisors` ne le detecte pas, comme pour [[feedback_agent_ro_jamais_sur_rpc_ecriture]].

**How to apply:** devant toute fonction `security definer` qui rend des LIGNES d'une table protegee,
ouvrir la policy de cette table a cote et se poser deux questions separees : (1) qui a le droit
d'appeler ? (2) parmi ce qu'elle rend, qu'est-ce que cet appelant aurait vu en lecture directe ?
Si la reponse a (2) n'est pas transcrite dans le corps, il y a fuite. Recopier la policy **a
l'identique** plutot que d'en ecrire une variante : une troisieme regle pour la meme donnee est
exactement le mecanisme qui a produit ce defaut. Et ne jamais conclure qu'un garde d'appartenance
borne la visibilite -- voir aussi [[pisi_diagnostic_total_2026-08-05]] (« RLS borne les LIGNES,
pas les COLONNES ») et [[feedback_double_chemin_execute_supabase]].
