---
name: feedback_porte_serveur_doit_etre_confrontee_a_la_policy
description: "Une fonction serveur qui pretend rejouer une policy RLS doit etre EXECUTEE contre la population reelle, pas relue - sinon elle derive en plus strict et ferme la porte a ceux qu elle sert"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fdb00ca8-c853-4e97-b470-cf9ab4128757
  modified: 2026-09-21T04:45:36.470Z
---

Quand une fonction serveur double une policy RLS — parce qu'elle doit autoriser
avant de signer une URL, ou décider pour une ligne désignée — **la relire ligne à
ligne ne prouve rien.** Il faut l'exécuter sous l'identité de chaque population
concernée et comparer son verdict à celui de la policy.

Cas réel (Rewayah, 21/09/2026). `peut_deposer_piece_identite` porte en commentaire
« rejoue EXACTEMENT ce que les trois policies d'insertion autorisent, ni plus, ni
moins ». Elle avait été revue deux fois sous cet angle-là — le rôle, la relation,
le chemin d'escalade de l'élève — et ces trois points étaient justes. Mais elle
ouvrait par `public.app_account_valid()`, que les policies ne testent pas :

```sql
-- la porte
select coalesce(public.app_account_valid() and ... , false);
-- la policy qu'elle pretend rejouer
((profile_id = auth.uid()) AND (app_role() = ANY (ARRAY['teacher','controller'])))
```

`app_account_valid()` exige `account_status in ('active','provisional_active')`.
Mesuré en production : les quatre enseignants concernés sont `pending_kyc`, donc
la porte les refusait. Et comme **tout compte en cours d'inscription est
`pending_kyc`**, cette porte fermait le dépôt d'une pièce d'identité à exactement
la population dont c'est le seul motif d'exister.

**Why :** le biais n'était pas la permissivité, c'était la SÉVÉRITÉ. Toute la
doctrine du dépôt pousse à fermer (exigence positive, `coalesce(..., false)`,
l'inconnue ferme), et une condition de sécurité ajoutée en plus se lit comme un
durcissement vertueux. Une revue qui cherche des fuites ne la voit jamais : elle
ne fuit pas, elle sur-ferme. Le défaut n'apparaît qu'en confrontant le verdict de
la fonction à celui de la policy, sur de vraies lignes.

**How to apply :**
1. Une fonction qui dit « rejoue la policy X » se vérifie en **exécutant les deux**
   sur la même population, pas en les lisant côte à côte.
2. Énumérer les populations depuis la BASE (`select distinct role, account_status
   from profiles`), jamais depuis l'idée qu'on se fait des comptes existants.
3. Tester les deux sens : un refus attendu qui passe (fuite) **et** une
   acceptation attendue qui est refusée (sur-fermeture). La seconde ne remonte
   dans aucune revue de sécurité.
4. Se demander pour chaque condition ajoutée : *la policy la teste-t-elle ?* Si
   non, c'est soit un défaut de la policy, soit une divergence — les deux exigent
   une décision, aucune ne se règle en silence.
5. Méfiance particulière sur `app_account_valid()` et assimilés dans un chemin
   d'INSCRIPTION : un compte qui s'inscrit n'est pas encore valide, c'est la
   définition même de l'inscription.

Même famille que [[feedback_chiffrer_avant_de_proposer]] : la mesure, pas la
relecture. Lié : [[rewayah_r2_integration_2026-09-21]],
[[feedback_hook_jeton_null_ferme_tout_en_silence]],
[[feedback_porte_sql_exigence_positive]].
